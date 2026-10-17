"""Lobby transport codec: the tconnd/`tgcpapi` session on port 17500.

Same crypto as the version RPC (AES-128-CBC, IV 00..0f, `tsf4g` padding, key
sent in the ACK) but a different outer frame and a different inner RPC encoding.
See docs/11-lobby-transport.md.

Frame (little-endian header, big-endian lengths):
    magic   0x33 0x66
    const   00 0a 00 0a
    cmd     u16 BE   (0x1001 SYN, 0x1002 ACK, 0x2001 AUTHREQ, 0x2002 AUTHRSP,
                      0x6002 BINGO, 0x4013 DATA, 0x5001/0x5002 STOP)
    dir     u32 LE   (0 = c2s, 1 = s2c)
    seq     u32 LE   (per-direction, from 1)
    ctoff   u8       offset from frame start where the ciphertext begins
    ctlen   u32 BE
    prefix  ctoff-21 bytes   (0 normally; 4 for DATA; the key TLV for ACK)
    cipher  ctlen bytes

Handshake, from libgcloud log strings (gcloud_tgcpapi_start_connection):
    c2s SYN -> s2c ACK(key) -> c2s AUTHREQ -> s2c AUTHRSP -> s2c BINGO
then DATA frames carry the lobby RPCs, STOP ends the session.

Inner RPC encoding ("tdr compact"): a 0x78 marker, then a flat sequence of
typed values; a map opens with 0x07 and is a run of string-keyed entries.
    0x03 len bytes   string
    0x02 <varint>    LEB128 unsigned
    0x04 <u8>        1-byte int
See tdr_parse. This decoder is good enough to read method names and string
args; exotic numeric types are kept as raw bytes.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tgcp import aes_cbc, pad, unpad  # noqa: E402  (shared crypto)

MAGIC = b"\x33\x66"
CONST = b"\x00\x0a\x00\x0a"
SYN, ACK = 0x1001, 0x1002
AUTHREQ, AUTHRSP = 0x2001, 0x2002
BINGO = 0x6002
DATA = 0x4013
STOP_C, STOP_S = 0x5001, 0x5002
BASE_OFF = 21                      # magic..ctlen with no extra prefix


class Frame:
    __slots__ = ("cmd", "dir", "seq", "prefix", "cipher")

    def __init__(self, cmd, direction, seq, prefix, cipher):
        self.cmd, self.dir, self.seq = cmd, direction, seq
        self.prefix, self.cipher = prefix, cipher      # prefix: bytes after ctlen

    def __repr__(self):
        return (f"Frame(cmd={self.cmd:#06x} dir={self.dir} seq={self.seq} "
                f"prefix={self.prefix.hex()} ct={len(self.cipher)})")

    def encode(self):
        ctoff = BASE_OFF + len(self.prefix)
        head = (MAGIC + CONST + struct.pack(">H", self.cmd)
                + struct.pack("<II", self.dir, self.seq)
                + bytes([ctoff]) + struct.pack(">I", len(self.cipher)))
        return head + self.prefix + self.cipher

    def plain(self, key):
        return unpad(aes_cbc(key, self.cipher)) if self.cipher else b""


def parse_frame(b, i=0):
    """Parse one frame at b[i:]; return (Frame, next_i) or None if incomplete."""
    if len(b) < i + 21:
        return None
    if b[i:i + 2] != MAGIC:
        raise ValueError(f"no 0x3366 at {i:#x}")
    cmd = struct.unpack(">H", b[i + 6:i + 8])[0]
    direction, seq = struct.unpack("<II", b[i + 8:i + 16])
    ctoff = b[i + 16]
    ctlen = struct.unpack(">I", b[i + 17:i + 21])[0]
    end = i + ctoff + ctlen
    if len(b) < end or ctoff < BASE_OFF:
        return None
    prefix = b[i + 21:i + ctoff]
    return Frame(cmd, direction, seq, prefix, b[i + ctoff:end]), end


def frames(b):
    i = 0
    while i < len(b):
        r = parse_frame(b, i)
        if r is None:
            raise ValueError(f"truncated frame at {i:#x}")
        f, i = r
        yield f


def ack_key(ack_frame):
    """The 16-byte session key the server puts in the ACK prefix.

    Prefix layout: 0x02, 0x10 (=len 16), the 16-byte key, then an 8-byte
    trailer (00 00 00 04 00 00 00 00 00).
    """
    p = ack_frame.prefix
    if p[1] != 0x10:
        raise ValueError(f"unexpected ACK prefix {p.hex()}")
    return p[2:18]


def data_frame(direction, seq, key, payload, sub=b"\x00\x00\x00\x00"):
    """Build a DATA frame carrying an encrypted RPC payload."""
    return Frame(DATA, direction, seq, sub, aes_cbc(key, pad(payload), encrypt=True))


# --- handshake bodies -------------------------------------------------------
# Exact layouts from recon/tgcp/lobby_s2c.bin. Lengths are u16 big-endian and
# count the NUL where the field is NUL-terminated; getting either wrong makes
# the client fail with "tdr unpack failed" (ret -18) and drop the connection.

def authrsp_body(openid, token):
    """AUTHRSP: echoes the client's openid (NUL-terminated) and auth token."""
    return (b"\x20\x01\x03\x00\x00"
            + struct.pack(">H", len(openid) + 1) + openid + b"\x00"
            + b"\x00" * 8
            + b"\xff\xff" + struct.pack(">H", len(token)) + token
            + b"\x00" * 14)


def bingo_body(session):
    """BINGO: a server-chosen session token, not NUL-counted."""
    return b"\x00" + session + b"\x00" * 11 + b"\x04\x00"


def ack_prefix(key):
    return b"\x02\x10" + key + b"\x00\x00\x00\x04\x00\x00\x00\x00\x00"


# --- inner RPC ("tdr compact") ---------------------------------------------

MAP_BEGIN = 0x07
MAP_END = 0x08
# 0x09..0x1f appear as single bytes carrying a small integer (seen as the
# values of startup_type, device_type, Sex, Memory, Density). The exact base is
# not pinned down, so these are decoded as ("small", raw) and never emitted —
# numbers we send use the 0x02 varint form, which is proven by
# test_encoder_reproduces_capture.
SMALL_INT_LO, SMALL_INT_HI = 0x09, 0x1F


def _uvarint(b, i):
    v = s = 0
    while True:
        c = b[i]
        i += 1
        v |= (c & 0x7F) << s
        s += 7
        if not c & 0x80:
            return v, i


def tdr_parse(b, i=0, end=None):
    """Parse a run of typed values into a list of Python values.

    Strings -> bytes, 0x02 varints -> int, 0x04 -> int, 0x07 map -> ("map",
    [(key, value)...]); anything unrecognised stops parsing and the remainder
    is returned as ("raw", bytes). Lossy by design: used to read, not re-emit.
    """
    if end is None:
        end = len(b)
    out = []
    while i < end:
        t = b[i]
        i += 1
        if t == 0x03:
            n = b[i]
            out.append(b[i + 1:i + 1 + n])
            i += 1 + n
        elif t == 0x02:
            v, i = _uvarint(b, i)
            out.append(v)
        elif t == 0x04:
            out.append(b[i])
            i += 1
        elif t == MAP_BEGIN:
            m, i = _tdr_map(b, i, end)
            out.append(dict(m))
        elif t == MAP_END:
            break
        elif SMALL_INT_LO <= t <= SMALL_INT_HI:
            out.append(("small", t))
        else:
            out.append(("raw", b[i - 1:end]))
            break
    return out


def _tdr_map(b, i, end):
    """Parse `0x07 (key value)* 0x08`."""
    pairs = []
    while i < end and b[i] != MAP_END:
        if b[i] != 0x03:                    # keys are always strings
            break
        n = b[i + 1]
        key = b[i + 2:i + 2 + n]
        i += 2 + n
        if i >= end:
            break
        vals = tdr_parse(b, i, end)         # value is the next single element
        pairs.append((key, vals[0] if vals else None))
        i = _skip_one(b, i, end)
    return pairs, i + 1 if i < end else i


def _skip_one(b, i, end):
    t = b[i]
    i += 1
    if t == 0x03:
        return i + 1 + b[i]
    if t == 0x02:
        _, i = _uvarint(b, i)
        return i
    if t == 0x04:
        return i + 1
    if SMALL_INT_LO <= t <= SMALL_INT_HI:
        return i
    if t == MAP_BEGIN:
        _, i = _tdr_map(b, i, end)
        return i
    return end


def tdr_string(t, s):
    return bytes([0x03, len(s)]) + (s.encode() if isinstance(s, str) else s)


def tdr_reply(method, code, detail):
    """Build a minimal RPC reply body: 0x78, result name, 0x02 code, detail."""
    return encode_pkg(method, code, detail)


def tdr_encode_value(v):
    """Encode one value in the tdr-compact form the client's dispatcher reads.

    str/bytes -> 0x03 len data   (1-byte length; no sample of a >255-byte
    string exists in the captures, so long strings are unsupported)
    int        -> 0x02 LEB128
    bool       -> 0x04 u8
    dict       -> 0x07 then string-keyed entries
    """
    if isinstance(v, (str, bytes)):
        b = v.encode() if isinstance(v, str) else v
        if len(b) > 255:
            raise ValueError("long-string encoding unknown (no sample)")
        return bytes([0x03, len(b)]) + b
    if isinstance(v, bool):
        return bytes([0x04, 1 if v else 0])
    if isinstance(v, int):
        return b"\x02" + _enc_varint(v)
    if isinstance(v, tuple) and v and v[0] == "small":
        # a value we decoded as a single-byte small int: re-emit it verbatim so
        # it means to the client exactly what the client sent
        return bytes([v[1]])
    if isinstance(v, dict):
        out = bytearray([MAP_BEGIN])
        for k, val in v.items():
            out += tdr_encode_value(k)
            out += tdr_encode_value(val)
        out.append(MAP_END)
        return bytes(out)
    raise TypeError(f"cannot encode {type(v).__name__}")


def encode_pkg(method, *args):
    """Build a DATA payload: 0x78, the method name, then its arguments.

    Mirrors NetUtil.SendPkg / NetUtil.DispatchPacket(msg, ...) in
    client/client_entry.lua: the first value is the message name and the rest
    are passed straight to the registered s2c handler.
    """
    out = bytearray(b"\x78")
    out += tdr_encode_value(method)
    for a in args:
        out += tdr_encode_value(a)
    return bytes(out)


def _enc_varint(v):
    out = bytearray()
    while True:
        c = v & 0x7F
        v >>= 7
        out.append(c | (0x80 if v else 0))
        if not v:
            return bytes(out)


def rpc_method(payload):
    """First string in a DATA payload = the RPC method name."""
    i = payload.index(0x78) + 1
    vals = tdr_parse(payload, i)
    return vals[0] if vals else None

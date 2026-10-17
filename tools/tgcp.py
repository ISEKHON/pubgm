"""TGcp codec: GCloud's TCP RPC transport, as used by the version/update check.

Layers, outermost first (recovered from recon/tgcp/*.bin, see docs/09-tgcp-protocol.md):

  frame     c2s only: b"Cf" prefix.  Then a TDR TLV struct (below) holding
            {1: head, 2: body-union}, then head[9] bytes of ciphertext.
  TDR TLV   0xAA, u32be total_len (incl. these 5 bytes), fields...
            field = varint tag, value; tag = (id << 4) | type
            type 0 varint | 1 u8 | 2 u16be | 3 u32be | 4 u64be | 5 u32be len + bytes
  cipher    AES-128-CBC, IV = 00 01 .. 0f, key = 16 bytes the server sends in
            plaintext in its 0x1002 ACK.  Padding: filler, b"tsf4g", pad length byte.
  payload   control cmds: another TDR TLV struct.
            0x4013 DATA:  Thrift binary message (non-stock header, see th_message).

CLI:
  python -I tools/tgcp.py <stream.bin>...            dump plaintext framing
  python -I tools/tgcp.py --decrypt <c2s> <s2c>      decrypt a captured session
"""
import os
import sys

# head[4] command ids (names are ours; meaning inferred from the captured flow)
SYN, ACK = 0x1001, 0x1002
AUTH_REQ, AUTH_RSP = 0x2001, 0x2002
DATA = 0x4013
CLOSE = 0x5001
SESSION = 0x6002          # s2c, sent right after AUTH_RSP
MAGIC = 0x4366            # head[1]; also the "Cf" c2s prefix
CF = b"Cf"

FIXED = {1: 1, 2: 2, 3: 4, 4: 8}


# --- TDR TLV ----------------------------------------------------------------
# A decoded struct is a list of (id, type, value). value is an int, bytes, or
# (for type 5 holding a nested struct) another list.

def varint(b, i):
    v = s = 0
    while True:
        c = b[i]
        i += 1
        v |= (c & 0x7F) << s
        s += 7
        if not c & 0x80:
            return v, i


def enc_varint(v):
    out = bytearray()
    while True:
        c = v & 0x7F
        v >>= 7
        out.append(c | (0x80 if v else 0))
        if not v:
            return bytes(out)


def parse_fields(b, i, end):
    out = []
    while i < end:
        tag, i = varint(b, i)
        fid, typ = tag >> 4, tag & 0xF
        if typ == 0:
            v, i = varint(b, i)
        elif typ in FIXED:
            n = FIXED[typ]
            v = int.from_bytes(b[i:i + n], "big")
            i += n
        elif typ == 5:
            n = int.from_bytes(b[i:i + 4], "big")
            raw = b[i + 4:i + 4 + n]
            i += 4 + n
            v = try_nested(raw)
        else:
            raise ValueError(f"unknown TLV type {typ} at {i:#x}")
        out.append((fid, typ, v))
    if i != end:
        raise ValueError(f"TLV overrun {i:#x} != {end:#x}")
    return out


def try_nested(raw):
    """Nested struct if it parses cleanly, else raw bytes.

    Ambiguous by construction (TDR TLV does not mark strings vs structs), so a
    short string can mis-parse as a struct. Round-trip encoding is unaffected
    because both forms re-encode to the same bytes.
    """
    if raw and raw[0] != 0xAA and not all(32 <= c < 127 for c in raw):
        try:
            return parse_fields(raw, 0, len(raw))
        except (ValueError, IndexError):
            pass
    return raw


def enc_fields(fields):
    out = bytearray()
    for fid, typ, v in fields:
        out += enc_varint((fid << 4) | typ)
        if typ == 0:
            out += enc_varint(v)
        elif typ in FIXED:
            out += v.to_bytes(FIXED[typ], "big")
        elif typ == 5:
            raw = enc_fields(v) if isinstance(v, list) else bytes(v)
            out += len(raw).to_bytes(4, "big") + raw
        else:
            raise ValueError(f"unknown TLV type {typ}")
    return bytes(out)


def parse_struct(b):
    """0xAA-prefixed TLV struct -> fields."""
    if b[0] != 0xAA:
        raise ValueError("TLV struct must start with 0xAA")
    return parse_fields(b, 5, int.from_bytes(b[1:5], "big"))


def enc_struct(fields):
    raw = enc_fields(fields)
    return b"\xaa" + (len(raw) + 5).to_bytes(4, "big") + raw


def get(fields, fid):
    for f, _, v in fields:
        if f == fid:
            return v
    raise KeyError(fid)


# --- frames -----------------------------------------------------------------

def split_frame(b, i=0):
    """Parse one frame at b[i:]. Returns (fields, ciphertext, next_i), or None
    if b does not yet hold a whole frame."""
    if b[i:i + 2] == CF:
        i += 2
    if len(b) < i + 5:
        return None
    if b[i] != 0xAA:
        raise ValueError(f"no 0xAA at {i:#x}")
    n = int.from_bytes(b[i + 1:i + 5], "big")
    if len(b) < i + n:
        return None
    fields = parse_fields(b, i + 5, i + n)
    blen = get(get(fields, 1), 9)
    if len(b) < i + n + blen:
        return None
    return fields, b[i + n:i + n + blen], i + n + blen


def frames(b):
    i = 0
    while i < len(b):
        start = i
        fields, ct, i = split_frame(b, i)
        yield start, fields, ct


def head_fields(cmd, session, seq, s2c, body_len):
    return [(1, 0, MAGIC), (2, 0, 0), (3, 0, 1), (4, 0, cmd), (5, 0, session),
            (6, 1, 1 if s2c else 0), (7, 0, seq), (8, 0, 0), (9, 0, body_len)]


def build_frame(cmd, session, seq, s2c, btype, bval, ciphertext=b""):
    """(btype, bval): the plaintext body-union member, field 2 -> cmd."""
    tlv = enc_struct([(1, 5, head_fields(cmd, session, seq, s2c, len(ciphertext))),
                      (2, 5, [(cmd, btype, bval)])])
    return (b"" if s2c else CF) + tlv + ciphertext


# --- crypto -----------------------------------------------------------------

IV = bytes(range(16))
PAD_TAG = b"tsf4g"


def aes_cbc(key, data, encrypt=False):
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    c = Cipher(algorithms.AES(key), modes.CBC(IV))
    op = c.encryptor() if encrypt else c.decryptor()
    return op.update(data) + op.finalize()


def pad(p, filler=None):
    n = 16 - len(p) % 16
    if n < 6:
        n += 16
    if filler is None:
        filler = os.urandom(n - 6)
    return p + filler + PAD_TAG + bytes([n])


def unpad(p):
    n = p[-1]
    if n < 6 or p[-6:-1] != PAD_TAG:
        raise ValueError(f"bad tsf4g padding: {p[-8:].hex()}")
    return p[:-n]


def encrypt(key, p):
    return aes_cbc(key, pad(p), encrypt=True)


def decrypt(key, c):
    return unpad(aes_cbc(key, c))


def session_key(ack_fields):
    """16-byte AES key from the server's ACK frame, body field 3 -> 2 -> 2."""
    body = get(get(ack_fields, 2), ACK)
    return get(get(get(body, 3), 2), 2)


# --- Thrift binary protocol -------------------------------------------------
# A decoded struct is a list of (id, ttype, value). Containers keep their
# element types so they re-encode exactly: list/set -> (etype, [items]),
# map -> (ktype, vtype, [(k, v)]).

T_BOOL, T_BYTE, T_DOUBLE, T_I16, T_I32, T_I64 = 2, 3, 4, 6, 8, 10
T_STRING, T_STRUCT, T_MAP, T_SET, T_LIST = 11, 12, 13, 14, 15
TT = {2: "bool", 3: "byte", 4: "double", 6: "i16", 8: "i32", 10: "i64",
      11: "string", 12: "struct", 13: "map", 14: "set", 15: "list"}
INT_W = {T_BOOL: 1, T_BYTE: 1, T_I16: 2, T_I32: 4, T_I64: 8}
CALL, REPLY = 1, 2


def th_val(b, i, t):
    if t in INT_W:
        n = INT_W[t]
        return int.from_bytes(b[i:i + n], "big", signed=t not in (T_BOOL, T_BYTE)), i + n
    if t == T_DOUBLE:
        return b[i:i + 8], i + 8
    if t == T_STRING:
        n = int.from_bytes(b[i:i + 4], "big")
        return b[i + 4:i + 4 + n], i + 4 + n
    if t == T_STRUCT:
        return th_struct(b, i)
    if t in (T_SET, T_LIST):
        et, n = b[i], int.from_bytes(b[i + 1:i + 5], "big")
        i += 5
        out = []
        for _ in range(n):
            v, i = th_val(b, i, et)
            out.append(v)
        return (et, out), i
    if t == T_MAP:
        kt, vt, n = b[i], b[i + 1], int.from_bytes(b[i + 2:i + 6], "big")
        i += 6
        out = []
        for _ in range(n):
            k, i = th_val(b, i, kt)
            v, i = th_val(b, i, vt)
            out.append((k, v))
        return (kt, vt, out), i
    raise ValueError(f"thrift type {t} at {i:#x}")


def th_struct(b, i=0):
    out = []
    while b[i] != 0:
        t, fid = b[i], int.from_bytes(b[i + 1:i + 3], "big")
        v, i = th_val(b, i + 3, t)
        out.append((fid, t, v))
    return out, i + 1


def th_enc_val(t, v):
    if t in INT_W:
        return v.to_bytes(INT_W[t], "big", signed=t not in (T_BOOL, T_BYTE))
    if t == T_DOUBLE:
        return bytes(v)
    if t == T_STRING:
        v = v.encode() if isinstance(v, str) else v
        return len(v).to_bytes(4, "big") + v
    if t == T_STRUCT:
        return th_enc_struct(v)
    if t in (T_SET, T_LIST):
        et, items = v
        return bytes([et]) + len(items).to_bytes(4, "big") + b"".join(
            th_enc_val(et, e) for e in items)
    if t == T_MAP:
        kt, vt, items = v
        return bytes([kt, vt]) + len(items).to_bytes(4, "big") + b"".join(
            th_enc_val(kt, k) + th_enc_val(vt, x) for k, x in items)
    raise ValueError(f"thrift type {t}")


def th_enc_struct(fields):
    return b"".join(bytes([t]) + fid.to_bytes(2, "big") + th_enc_val(t, v)
                    for fid, t, v in fields) + b"\x00"


def th_message(b):
    """Decode a DATA payload. Returns dict(prefix, name, type, seq, args, rest).

    Differs from stock TBinaryProtocol in two places:
      - c2s payloads start with an extra u32 (seen: 3), s2c ones do not;
      - the message type byte is followed by *two* u32 (seen 0,0 for
        QueryAddrSvr and 0,1 for VersionUpdate); replies echo the request's.
    """
    i = 0
    prefix = None
    n = int.from_bytes(b[0:4], "big")
    if not (0 < n < 256 and all(32 <= c < 127 for c in b[4:4 + n])):
        prefix, i = int.from_bytes(b[0:4], "big"), 4
        n = int.from_bytes(b[i:i + 4], "big")
    name = b[i + 4:i + 4 + n].decode()
    i += 4 + n
    mtype = b[i]
    seq = (int.from_bytes(b[i + 1:i + 5], "big"), int.from_bytes(b[i + 5:i + 9], "big"))
    args, i = th_struct(b, i + 9)
    return {"prefix": prefix, "name": name, "type": mtype, "seq": seq,
            "args": args, "rest": b[i:]}


def th_enc_message(name, mtype, seq, args, prefix=None):
    out = b"" if prefix is None else prefix.to_bytes(4, "big")
    out += len(name).to_bytes(4, "big") + name.encode() + bytes([mtype])
    out += seq[0].to_bytes(4, "big") + seq[1].to_bytes(4, "big")
    return out + th_enc_struct(args)


def th_get(fields, *path):
    v = fields
    for fid in path:
        v = next(x for f, _, x in v if f == fid)
    return v


def th_set(fields, fid, t, v):
    """Return a copy of fields with fid replaced (or appended)."""
    out = [(f, tt, x) for f, tt, x in fields if f != fid]
    out.append((fid, t, v))
    return sorted(out, key=lambda e: e[0])


def ver_str(v):
    """GCloud packs a.b.c.d as four u16 in an i64."""
    return ".".join(str((v >> s) & 0xFFFF) for s in (48, 32, 16, 0))


# --- pretty printing --------------------------------------------------------

def show(fields, ind="  "):
    for fid, typ, v in fields:
        name = f"{fid:#x}" if fid > 0xFF else str(fid)
        if isinstance(v, list):
            print(f"{ind}[{name}] struct")
            show(v, ind + "  ")
        elif isinstance(v, bytes):
            txt = v.decode("ascii") if all(32 <= c < 127 for c in v) else v.hex()
            print(f"{ind}[{name}] bytes({len(v)}) {txt}")
        else:
            print(f"{ind}[{name}] t{typ} = {v} ({v:#x})")


def th_show(fields, ind):
    for fid, t, v in fields:
        tn = TT[t]
        if t == T_STRUCT:
            print(f"{ind}{fid}: struct")
            th_show(v, ind + "  ")
        elif t in (T_LIST, T_SET):
            et, items = v
            print(f"{ind}{fid}: {tn}<{TT[et]}>[{len(items)}]")
            for e in items:
                if et == T_STRUCT:
                    print(f"{ind}  -")
                    th_show(e, ind + "    ")
                else:
                    print(f"{ind}  - {e!r}")
        elif t == T_STRING:
            s = v.decode() if all(32 <= c < 127 for c in v) else v.hex()
            print(f"{ind}{fid}: string {s!r}")
        elif t == T_I64 and v > 0xFFFFFFFF:
            print(f"{ind}{fid}: i64 {v:#x}  (version {ver_str(v)})")
        else:
            print(f"{ind}{fid}: {tn} {v!r}")


def decrypt_session(c2s, s2c):
    """Yield (direction, cmd, head, fields, plaintext) for a captured pair."""
    s = list(frames(s2c))
    key = session_key(s[0][1])
    for d, fr in (("c2s", list(frames(c2s))), ("s2c", s)):
        for _, fields, ct in fr:
            head = dict((f, v) for f, _, v in get(fields, 1))
            yield d, head[4], head, fields, (decrypt(key, ct) if ct else b"")


def dump_plain(p):
    if p[0] == 0xAA:
        show(parse_struct(p), "    ")
        return
    m = th_message(p)
    print(f"    thrift {m['name']} type={m['type']} seq={m['seq']} prefix={m['prefix']}")
    th_show(m["args"], "      ")
    if m["rest"]:
        print(f"    rest({len(m['rest'])}) {m['rest'].hex()}")


def main():
    if sys.argv[1] == "--decrypt":
        with open(sys.argv[2], "rb") as f:
            c2s = f.read()
        with open(sys.argv[3], "rb") as f:
            s2c = f.read()
        for d, cmd, head, _, p in decrypt_session(c2s, s2c):
            print(f"-- {d} cmd {cmd:#06x} seq {head[7]} session {head[5]:#x} plain({len(p)})")
            if p:
                dump_plain(p)
        return
    for path in sys.argv[1:]:
        with open(path, "rb") as f:
            data = f.read()
        print(f"##### {path} ({len(data)} bytes)")
        for off, fields, ct in frames(data):
            print(f"-- frame @ {off:#x}")
            show(fields)
            if ct:
                print(f"  ciphertext({len(ct)})")


if __name__ == "__main__":
    main()

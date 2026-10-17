"""Synthetic UE4-style handshake client, to smoke-test the server.

Independent implementation of the LSB-first bit packing, so agreement with the
C server is a real cross-check rather than self-consistency.
"""
import socket, struct, sys

COOKIE = 20
BITS = 195

class W:
    def __init__(self): self.b = bytearray(); self.n = 0
    def bit(self, v):
        if self.n % 8 == 0: self.b.append(0)
        if v: self.b[self.n // 8] |= 1 << (self.n % 8)
        self.n += 1
    def bits(self, val, cnt):
        for i in range(cnt): self.bit((val >> i) & 1)
    def byts(self, d):
        for x in d: self.bits(x, 8)

class R:
    def __init__(self, data):
        last = data[-1]
        top = 7
        while not (last >> top) & 1: top -= 1
        self.d = data; self.n = (len(data) - 1) * 8 + top; self.p = 0
    def bit(self):
        v = (self.d[self.p // 8] >> (self.p % 8)) & 1; self.p += 1; return v
    def bits(self, c):
        return sum(self.bit() << i for i in range(c))
    def byts(self, c):
        return bytes(self.bits(8) for _ in range(c))

def enc(hs, restart, sid, ts, cookie):
    w = W(); w.bit(hs); w.bit(restart); w.bit(sid)
    w.bits(struct.unpack("<I", struct.pack("<f", ts))[0], 32)
    w.byts(cookie)
    assert w.n == BITS, w.n
    w.bit(1)                     # UE4 termination bit
    return bytes(w.b)

def dec(data):
    r = R(data)
    hs, restart, sid = r.bit(), r.bit(), r.bit()
    ts = struct.unpack("<f", struct.pack("<I", r.bits(32)))[0]
    return hs, restart, sid, ts, r.byts(COOKIE), r.n

port = int(sys.argv[1]) if len(sys.argv) > 1 else 7777
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(5)

pkt = enc(1, 0, 0, 0.0, b"\x00" * COOKIE)
print(f"-> initial handshake, {len(pkt)} bytes ({BITS}+1 bits)")
s.sendto(pkt, ("127.0.0.1", port))
rep, _ = s.recvfrom(2048)
hs, rs, sid, ts, ck, nb = dec(rep)
print(f"<- challenge {len(rep)}B payload_bits={nb} hs={hs} restart={rs} sid={sid} ts={ts:.6f}")
print(f"   cookie={ck.hex()}")
assert nb == BITS, f"payload bits {nb} != {BITS}"
assert hs == 1 and ck != b"\x00" * COOKIE, "challenge malformed"

resp = enc(1, 0, sid, ts, ck)
print("-> challenge response (echo timestamp+cookie)")
s.sendto(resp, ("127.0.0.1", port))
rep2, _ = s.recvfrom(2048)
hs2, _, sid2, ts2, ck2, nb2 = dec(rep2)
print(f"<- ack {len(rep2)}B payload_bits={nb2} sid={sid2} ts={ts2:.6f}")
assert ck2 == ck and abs(ts2 - ts) < 1e-6, "ack did not echo the cookie"

# A forged cookie must be refused (no reply).
bad = bytearray(ck); bad[0] ^= 0xFF
s.sendto(enc(1, 0, sid, ts, bytes(bad)), ("127.0.0.1", port))
try:
    s.settimeout(1.5); s.recvfrom(2048)
    print("FAIL: forged cookie was answered"); sys.exit(1)
except socket.timeout:
    print("OK: forged cookie ignored (no reply)")

print("SMOKE TEST PASSED: full handshake round-trip + forgery rejected")

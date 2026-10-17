"""Round-trip tests for tools/lobby.py against the captured lobby handshake.

    python -I tools/test_lobby.py

Needs recon/tgcp/lobby_{c2s,s2c}.bin (gitignored).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lobby as L  # noqa: E402

CAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "recon", "tgcp")
checks = 0


def check(cond, what):
    global checks
    checks += 1
    if not cond:
        raise AssertionError(what)


def load(name):
    with open(os.path.join(CAP, name), "rb") as f:
        return f.read()


def test_frame_roundtrip():
    for name in ("lobby_c2s.bin", "lobby_s2c.bin"):
        data = load(name)
        rebuilt = b"".join(f.encode() for f in L.frames(data))
        check(rebuilt == data, f"{name} byte-exact frame round-trip")


def test_decrypt_and_rpc():
    s2c = list(L.frames(load("lobby_s2c.bin")))
    c2s = list(L.frames(load("lobby_c2s.bin")))
    key = L.ack_key(next(f for f in s2c if f.cmd == L.ACK))
    check(key == b"YkYPJqDyimCbgCQz", f"ACK key: {key}")

    login = next(f for f in c2s if f.cmd == L.DATA)
    p = login.plain(key)
    check(L.rpc_method(p) == b"login", "c2s DATA method is login")
    m = dict(L.tdr_parse(p, p.index(0x78) + 1)[2][1])   # the property map
    check(m[b"DeviceId"] == b"61a8792717ec0528", "DeviceId parsed")
    check(m[b"ClientVersion"] == 1, "ClientVersion parsed")
    check(m[b"NetWork"] == b"Wifi", "NetWork parsed")

    reply = next(f for f in s2c if f.cmd == L.DATA)
    rp = reply.plain(key)
    check(L.rpc_method(rp) == b"login_failed", "s2c DATA method is login_failed")
    check(b"version_error" in rp, "reply carries version_error detail")

    # the AES-carrying frames all unpad cleanly under the ACK key
    aes_cmds = {L.AUTHREQ, L.AUTHRSP, L.BINGO, L.DATA, L.STOP_C}
    n = 0
    for f in c2s + s2c:
        if f.cmd in aes_cmds and f.cipher:
            f.plain(key)
            n += 1
    check(n >= 5, f"AES frames unpad (got {n})")


def test_handshake_bodies_match_capture():
    """Our builders must reproduce the real server's bytes exactly: a wrong
    length or a missing NUL makes the client report 'tdr unpack failed'."""
    s2c = list(L.frames(load("lobby_s2c.bin")))
    key = L.ack_key(next(f for f in s2c if f.cmd == L.ACK))
    arsp = next(f for f in s2c if f.cmd == L.AUTHRSP).plain(key)
    bingo = next(f for f in s2c if f.cmd == L.BINGO).plain(key)

    openid, token = b"188039022634206504", b"0526f464fd59fe45e47592e632fe4aaf"
    check(L.authrsp_body(openid, token) == arsp, "authrsp_body reproduces capture")
    check(L.bingo_body(b"1~J7IsgwyhSyn3iN24A") == bingo, "bingo_body reproduces capture")
    check(L.ack_prefix(key) == next(f for f in s2c if f.cmd == L.ACK).prefix,
          "ack_prefix reproduces capture")
    check(len(L.authrsp_body(openid, token)) == 84, "authrsp length 84")
    check(len(L.bingo_body(b"1~J7IsgwyhSyn3iN24A")) == 33, "bingo length 33")


def test_build_reply():
    key = b"YkYPJqDyimCbgCQz"
    body = L.tdr_reply("login_failed", 0x7de080 & 0x7f, "version_error")  # shape only
    f = L.data_frame(1, 4, key, body)
    g, _ = L.parse_frame(f.encode())
    check(g.plain(key) == body, "built DATA frame decrypts to its payload")
    check(L.rpc_method(g.plain(key)) == b"login_failed", "built reply method")


if __name__ == "__main__":
    if not os.path.exists(os.path.join(CAP, "lobby_c2s.bin")):
        print("captures missing: skipped")
    else:
        test_frame_roundtrip()
        test_decrypt_and_rpc()
        test_handshake_bodies_match_capture()
        test_build_reply()
    print(f"ok: {checks} checks passed")

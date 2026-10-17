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
    m = L.tdr_parse(p, p.index(0x78) + 1)[2]   # the property map
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


def test_encoder_reproduces_capture():
    """encode_pkg must rebuild the real server's login_failed payload exactly."""
    s2c = list(L.frames(load("lobby_s2c.bin")))
    key = L.ack_key(next(f for f in s2c if f.cmd == L.ACK))
    want = next(f for f in s2c if f.cmd == L.DATA).plain(key)

    vals = L.tdr_parse(want, want.index(0x78) + 1)
    conn_idx, reason = vals[1], vals[2]
    check(vals[0] == b"login_failed", "decoded method")
    got = L.encode_pkg("login_failed", conn_idx, reason)
    check(got == want, f"encode_pkg round-trip\n got {got.hex()}\nwant {want.hex()}")

    # the packet we actually want to send takes no arguments
    pcr = L.encode_pkg("please_create_role")
    check(pcr == b"\x78\x03\x12please_create_role", f"please_create_role: {pcr.hex()}")
    check(L.rpc_method(pcr) == b"please_create_role", "method reads back")


def test_login_args_match_lua_signature():
    """logic_login.lua sends login(ver, device_info, startup_type, ext_info, ...).
    The decoder must see that structure, which only works if maps are
    terminated by 0x08 and consumed exactly."""
    s2c = list(L.frames(load("lobby_s2c.bin")))
    c2s = list(L.frames(load("lobby_c2s.bin")))
    key = L.ack_key(next(f for f in s2c if f.cmd == L.ACK))
    p = next(f for f in c2s if f.cmd == L.DATA).plain(key)
    vals = L.tdr_parse(p, p.index(0x78) + 1)
    check(vals[0] == b"login", "arg0 method")
    check(vals[1] == b"0.3.2.3212", "arg1 version")
    check(isinstance(vals[2], dict) and len(vals[2]) == 15,
          f"arg2 device_info map, got {type(vals[2])}")
    check(vals[2][b"DeviceId"] == b"61a8792717ec0528", "device map content")
    check(isinstance(vals[4], dict) and b"relogin" in vals[4],
          f"arg4 ext_info{{relogin}}, got {vals[4]!r}")


def test_map_roundtrip():
    for d in ({}, {"a": 1}, {"name": "SEKHON", "level": 1, "depot": {"items": {}}}):
        enc = L.tdr_encode_value(d)
        check(enc[0] == L.MAP_BEGIN and enc[-1] == L.MAP_END,
              f"map framed by 07..08: {enc.hex()}")
        def as_bytes(x):
            if isinstance(x, str):
                return x.encode()
            if isinstance(x, dict):
                return {as_bytes(k): as_bytes(v) for k, v in x.items()}
            return x

        back = L.tdr_parse(enc)[0]
        check(back == as_bytes(d), f"map round-trip {d} -> {back}")


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
        test_encoder_reproduces_capture()
        test_login_args_match_lua_signature()
        test_map_roundtrip()
        test_build_reply()
    print(f"ok: {checks} checks passed")

"""Round-trip tests for tools/tgcp.py against the captured sessions.

    python -I tools/test_tgcp.py

Every layer is re-encoded from its decoded form and compared byte-for-byte
with the capture, so a pass means the encoder produces exactly what the real
client and server put on the wire. Needs recon/tgcp/*.bin (gitignored).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tgcp as T  # noqa: E402

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


def test_session(port):
    c2s, s2c = load(f"c2s_{port}.bin"), load(f"s2c_{port}.bin")
    key = T.session_key(next(T.frames(s2c))[1])
    check(len(key) == 16, "key length")

    for stream, is_s2c in ((c2s, False), (s2c, True)):
        rebuilt = b""
        for _, fields, ct in T.frames(stream):
            head = T.get(fields, 1)
            h = dict((f, v) for f, _, v in head)
            # head layout, including per-field wire types
            check(T.head_fields(h[4], h[5], h[7], is_s2c, len(ct)) == head,
                  f"{port} head layout cmd {h[4]:#x}")
            rebuilt += (b"" if is_s2c else T.CF) + T.enc_struct(fields) + ct

            if not ct:
                continue
            raw = T.aes_cbc(key, ct)
            p = T.unpad(raw)
            n = raw[-1]
            check(T.pad(p, filler=raw[len(p):len(raw) - 6]) == raw,
                  f"{port} padding rule, len {len(p)} -> pad {n}")
            check(T.encrypt(key, p)[:0] == b"" and len(T.encrypt(key, p)) == len(ct),
                  f"{port} encrypted length")
            if p[0] == 0xAA:
                check(T.enc_struct(T.parse_struct(p)) == p, f"{port} inner TLV {h[4]:#x}")
            else:
                m = T.th_message(p)
                check(m["rest"] == b"", f"{port} thrift trailing bytes")
                again = T.th_enc_message(m["name"], m["type"], m["seq"], m["args"], m["prefix"])
                check(again == p, f"{port} thrift {m['name']} type {m['type']}")
        check(rebuilt == stream, f"{port} {'s2c' if is_s2c else 'c2s'} whole stream")


def test_crypto_roundtrip():
    key = b"0123456789abcdef"
    for n in range(0, 80):
        p = bytes(range(n % 256)) * 1 if n else b""
        check(T.decrypt(key, T.encrypt(key, p)) == p, f"crypto round trip len {n}")


def test_varint():
    for v in (0, 1, 127, 128, 0x4366, 0x1001, 2**32 - 1, 2**63):
        check(T.varint(T.enc_varint(v), 0) == (v, len(T.enc_varint(v))), f"varint {v}")
    check(T.enc_varint(0x4366) == bytes.fromhex("e68601"), "varint vector 0x4366")


def test_version_packing():
    check(T.ver_str(0x0003_0002_0C8C) == "0.3.2.3212", "version 0.3.2.3212")
    check(T.ver_str(0x0003_0003_0D54) == "0.3.3.3412", "version 0.3.3.3412")


async def replay_client(port, c2s_capture):
    """Replay the real client's frames, re-encrypted under the key our server
    hands out. Returns the decrypted server frames as (cmd, plaintext)."""
    import asyncio
    reader, writer = await asyncio.open_connection("127.0.0.1", port)
    client = list(T.frames(c2s_capture))
    got, buf, key = [], b"", None

    async def read_frames(count):
        nonlocal buf
        out = []
        while len(out) < count:
            r = T.split_frame(buf)
            if r is None:
                chunk = await asyncio.wait_for(reader.read(65536), 5)
                check(chunk != b"", "server closed early")
                buf += chunk
                continue
            fields, ct, n = r
            buf = buf[n:]
            head = dict((f, v) for f, _, v in T.get(fields, 1))
            check(head[6] == 1 and head[1] == T.MAGIC, "s2c head flags")
            out.append((head[4], fields, ct))
        return out

    # SYN goes out verbatim (it is plaintext); ACK carries the new key.
    writer.write(T.CF + T.enc_struct(client[0][1]))
    (cmd, fields, ct), = await read_frames(1)
    check(cmd == T.ACK, "ACK after SYN")
    key = T.session_key(fields)
    got.append((cmd, T.decrypt(key, ct)))
    return reader, writer, client, key, got, read_frames


def test_server_e2e():
    import asyncio
    import tgcp_server as S

    c2s, s2c = load("c2s_8086.bin"), load("s2c_8086.bin")
    real_key = T.session_key(next(T.frames(s2c))[1])
    orig_plain = [T.decrypt(real_key, ct) if ct else b"" for _, _, ct in T.frames(c2s)]

    async def run():
        cfg = S.parse_args(["--bind", "127.0.0.1", "--ports", "0", "--advertise", "10.9.8.7"])
        ready = asyncio.get_running_loop().create_future()
        srv = asyncio.ensure_future(S.serve(cfg, ready))
        port = (await ready)[0]
        reader, writer, client, key, got, read_frames = await replay_client(port, c2s)
        check(len(key) == 16 and key != real_key, "fresh 16-byte session key")

        for i, (_, fields, ct) in enumerate(client[1:], start=1):
            head = dict((f, v) for f, _, v in T.get(fields, 1))
            cmd = head[4]
            body = T.get(T.get(fields, 2), cmd)
            btype = next(t for f, t, _ in T.get(fields, 2) if f == cmd)
            new_ct = T.encrypt(key, orig_plain[i]) if ct else b""
            writer.write(T.build_frame(cmd, head[5], head[7], False, btype, body, new_ct))
            await writer.drain()
            want = {T.AUTH_REQ: 2, T.DATA: 1}.get(cmd, 0)
            for rcmd, _, rct in await read_frames(want):
                got.append((rcmd, T.decrypt(key, rct) if rct else b""))

        cmds = [c for c, _ in got]
        check(cmds == [T.ACK, T.AUTH_RSP, T.SESSION, T.DATA], f"reply sequence {cmds}")
        for c, p in got[:3]:
            check(T.get(T.parse_struct(p), c) is not None, f"inner TLV of {c:#x}")
        m = T.th_message(got[3][1])
        check(m["name"] == "VersionUpdate:ReqUpdateVersion" and m["type"] == T.REPLY,
              "thrift reply header")
        check(m["seq"] == (0, 1), "reply echoes request seq pair")
        res = T.th_get(m["args"], 0)
        check(T.th_get(res, 1) == 0, "result 0")
        check(T.th_get(res, 3, 2) == 0, "update_type == kUpdateTypeNot")
        check(T.ver_str(T.th_get(res, 3, 1, 1)) == "0.3.2.3212", "latest == client version")
        req_comm = T.th_get(T.th_message(orig_plain[2])["args"], 1, 1)
        check(T.th_get(res, 2) == req_comm, "comm_info echoed")
        writer.close()

        # address service on the same server
        a2s = load("c2s_8085.bin")
        a_s2c = load("s2c_8085.bin")
        a_key = T.session_key(next(T.frames(a_s2c))[1])
        a_plain = [T.decrypt(a_key, ct) if ct else b"" for _, _, ct in T.frames(a2s)]
        reader, writer, client, key, got, read_frames = await replay_client(port, a2s)
        for i in (1, 2):
            _, fields, _ = client[i]
            head = dict((f, v) for f, _, v in T.get(fields, 1))
            cmd = head[4]
            body = T.get(T.get(fields, 2), cmd)
            btype = next(t for f, t, _ in T.get(fields, 2) if f == cmd)
            writer.write(T.build_frame(cmd, head[5], head[7], False, btype, body,
                                       T.encrypt(key, a_plain[i])))
            for rcmd, _, rct in await read_frames(2 if cmd == T.AUTH_REQ else 1):
                got.append((rcmd, T.decrypt(key, rct)))
        m = T.th_message(got[-1][1])
        addrs = T.th_get(m["args"], 0, 3)[1]
        check(addrs == [[(1, T.T_STRING, b"10.9.8.7"), (2, T.T_I32, port)]],
              f"QueryAddrInfo advertises our address: {addrs}")
        writer.close()
        srv.cancel()

    asyncio.run(run())


if __name__ == "__main__":
    test_varint()
    test_version_packing()
    test_crypto_roundtrip()
    if os.path.exists(os.path.join(CAP, "c2s_8085.bin")):
        test_session("8085")
        test_session("8086")
        test_server_e2e()
    else:
        print("captures missing: skipped session round-trips")
    print(f"ok: {checks} checks passed")

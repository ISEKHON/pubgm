"""Local TGcp server: answers GCloud's address and version RPCs so the client
concludes it is up to date.  See docs/09-tgcp-protocol.md.

    python -I tools/tgcp_server.py [--advertise 10.0.2.2] [--ports 8085,8086]
                                   [--update-type 0]

Session (server view):   SYN -> ACK(key in clear)   AUTH_REQ -> AUTH_RSP + SESSION
                         DATA(thrift call) -> DATA(thrift reply)   CLOSE
Every frame is logged decoded, so this is also the bring-up instrument.
"""
import argparse
import asyncio
import os
import secrets
import string
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tgcp as T  # noqa: E402

UPDATE_TYPES = {0: "kUpdateTypeNot", 1: "kUpdateTypeOptional", 2: "kUpdateTypeForce"}

# Values copied from the captured QueryAddrSvr session where meaning is unknown.
ACK_MAXLEN = 1024           # ACK body [5] and SESSION [3]: 1024 (8085) / 512 (8086)
SESSION_F3 = 0x232802208000
SESSION_F4 = 1


def log(peer, msg):
    print(f"[{peer}] {msg}", flush=True)


class Session:
    def __init__(self, cfg, reader, writer):
        self.cfg, self.reader, self.writer = cfg, reader, writer
        self.peer = "%s:%d" % writer.get_extra_info("peername")[:2]
        self.sid = secrets.randbits(31)
        alnum = string.ascii_letters + string.digits
        self.key = "".join(secrets.choice(alnum) for _ in range(16)).encode()
        self.seq = 0
        self.syn = None

    def send(self, cmd, btype, bval, plain=b""):
        self.seq += 1
        ct = T.encrypt(self.key, plain) if plain else b""
        self.writer.write(T.build_frame(cmd, self.sid, self.seq, True, btype, bval, ct))
        log(self.peer, f">> {cmd:#06x} seq {self.seq} plain {len(plain)}")

    async def run(self):
        log(self.peer, "connected")
        buf = b""
        try:
            while True:
                chunk = await self.reader.read(65536)
                if not chunk:
                    break
                buf += chunk
                while True:
                    r = T.split_frame(buf)
                    if r is None:
                        break
                    fields, ct, n = r
                    buf = buf[n:]
                    if not self.on_frame(fields, ct):
                        return
                await self.writer.drain()
        except (ValueError, IndexError, KeyError) as e:
            log(self.peer, f"!! protocol error: {e!r}; buffered {buf[:64].hex()}")
        finally:
            self.writer.close()
            log(self.peer, "closed")

    def on_frame(self, fields, ct):
        head = dict((f, v) for f, _, v in T.get(fields, 1))
        cmd = head[4]
        body = T.get(T.get(fields, 2), cmd)
        plain = T.decrypt(self.key, ct) if ct else b""
        log(self.peer, f"<< {cmd:#06x} seq {head[7]} plain {len(plain)}")

        if cmd == T.SYN:
            self.syn = body
            svc = T.get(T.get(T.get(body, 14), 4), 1)
            log(self.peer, f"   SYN service={svc!r} game={T.get(body, 4)} "
                           f"enc={T.get(body, 13)}")
            ack = [(1, 1, 3), (2, 1, 2), (3, 5, [(2, 5, [(1, 1, 16), (2, 5, self.key)])]),
                   (4, 1, 1), (5, 0, ACK_MAXLEN), (6, 0, 0)]
            self.send(T.ACK, 5, ack, T.enc_struct([(T.ACK, 5, [(1, 1, 0)])]))
        elif cmd == T.AUTH_REQ:
            self.send(T.AUTH_RSP, 1, 0, T.enc_struct([(T.AUTH_RSP, 5, [
                (1, 5, T.get(self.syn, 7)), (2, 0, 0), (3, 5, b""), (4, 5, b"")])]))
            svc = T.get(T.get(T.get(self.syn, 14), 4), 1)
            self.send(T.SESSION, 1, 0, T.enc_struct([(T.SESSION, 5, [
                (1, 5, [(1, 0, secrets.randbits(31)),
                        (2, 5, secrets.token_hex(8).upper().encode()),
                        (3, 0, SESSION_F3), (4, 0, SESSION_F4), (5, 1, 0), (6, 5, svc)]),
                (2, 1, 1), (3, 0, ACK_MAXLEN)])]))
        elif cmd == T.DATA:
            m = T.th_message(plain)
            log(self.peer, f"   RPC {m['name']} type={m['type']} seq={m['seq']}")
            reply = self.dispatch(m)
            if reply is None:
                log(self.peer, f"!! no handler for {m['name']}; args:")
                T.th_show(m["args"], "      ")
                return True
            p = T.th_enc_message(m["name"], T.REPLY, m["seq"], reply)
            self.send(T.DATA, 5, [(1, 1, 0), (2, 1, 0), (3, 1, 0), (4, 5, [(0, 1, 0)])], p)
        elif cmd == T.CLOSE:
            return False
        else:
            log(self.peer, f"!! unhandled cmd {cmd:#x}")
            T.show(fields, "      ")
        return True

    def dispatch(self, m):
        name = m["name"]
        if name == "QueryAddrSvr:QueryAddrInfo":
            host, port = self.cfg.advertise.encode(), self.cfg.ports[-1]
            log(self.peer, f"   -> address {host.decode()}:{port}")
            return [(0, T.T_STRUCT, [
                (1, T.T_I32, 0), (2, T.T_STRING, b""),
                (3, T.T_LIST, (T.T_STRUCT, [[(1, T.T_STRING, host), (2, T.T_I32, port)]]))])]
        if name == "VersionUpdate:ReqUpdateVersion":
            comm = T.th_get(m["args"], 1, 1)
            ver = T.th_get(comm, 5)
            ut = self.cfg.update_type
            log(self.peer, f"   client version {T.ver_str(ver)} -> latest {T.ver_str(ver)}, "
                           f"update_type {ut} ({UPDATE_TYPES.get(ut, '?')})")
            pkg = [(1, T.T_I64, ver), (2, T.T_STRING, b""), (3, T.T_STRING, b""),
                   (4, T.T_STRING, b""), (5, T.T_STRING, b""), (6, T.T_STRING, b""),
                   (7, T.T_STRUCT, [(1, T.T_BYTE, 0), (2, T.T_BYTE, 0), (3, T.T_BYTE, 0)]),
                   (8, T.T_BOOL, 0)] + [(i, T.T_STRING, b"") for i in range(9, 13)]
            return [(0, T.T_STRUCT, [
                (1, T.T_I32, 0),
                (2, T.T_STRUCT, comm),
                (3, T.T_STRUCT, [(1, T.T_STRUCT, pkg), (2, T.T_I32, ut)]),
                (4, T.T_STRING, b"2.50.21"),
                (5, T.T_I32, 118),
                (7, T.T_STRUCT, [(1, T.T_BYTE, 0), (2, T.T_BYTE, 0), (3, T.T_BYTE, 0)])])]
        return None


async def serve(cfg, ready=None):
    async def handler(r, w):
        await Session(cfg, r, w).run()
    servers = [await asyncio.start_server(handler, cfg.bind, p) for p in cfg.ports]
    cfg.ports = [s.sockets[0].getsockname()[1] for s in servers]   # resolves port 0
    print(f"TGcp server on {cfg.bind} ports {cfg.ports}, advertising {cfg.advertise}, "
          f"update_type {cfg.update_type}", flush=True)
    if ready:
        ready.set_result(cfg.ports)
    await asyncio.gather(*(s.serve_forever() for s in servers))


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--ports", default="8085,8086",
                    help="listen ports; the last one is advertised by QueryAddrSvr")
    ap.add_argument("--advertise", default="10.0.2.2",
                    help="address the client should use for the version service "
                         "(10.0.2.2 = emulator host)")
    ap.add_argument("--update-type", type=int, default=0, choices=sorted(UPDATE_TYPES))
    a = ap.parse_args(argv)
    a.ports = [int(p) for p in a.ports.split(",")]
    return a


if __name__ == "__main__":
    try:
        asyncio.run(serve(parse_args()))
    except KeyboardInterrupt:
        pass

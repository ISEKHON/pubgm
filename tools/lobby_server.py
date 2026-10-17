"""Local lobby server + bring-up instrument for the :17500 tconnd transport.

    python -I tools/lobby_server.py [--port 17500] [--login-reply FILE]

Completes the tconnd handshake (SYN->ACK, AUTHREQ->AUTHRSP+BINGO) with a session
key we choose, then logs every DATA RPC decoded and answers `login`. The login
reply schema is unknown (it lives in encrypted Lua), so this is an oracle: send
a guess, watch the client's next request or error, refine. --login-reply loads a
raw reply payload from a file to iterate without editing code.

Nothing here touches the official servers; it only answers our own client.
"""
import argparse
import asyncio
import os
import secrets
import string
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lobby as L  # noqa: E402


def rnd(n):
    return "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(n))


def log(peer, msg):
    print(f"[{peer}] {msg}", flush=True)


class Session:
    def __init__(self, cfg, reader, writer):
        self.cfg, self.reader, self.writer = cfg, reader, writer
        self.peer = "%s:%d" % writer.get_extra_info("peername")[:2]
        self.key = rnd(16).encode()
        self.openid = b""
        self.token = b""
        self.sseq = 0

    def send(self, frame):
        self.sseq += 1
        frame.seq = self.sseq
        frame.dir = 1
        self.writer.write(frame.encode())
        log(self.peer, f">> {frame.cmd:#06x} seq {self.sseq} ct {len(frame.cipher)}")

    # --- handshake frame builders (shapes from recon/tgcp/lobby_s2c.bin) ---

    def _enc(self, cmd, body):
        return L.Frame(cmd, 1, 0, b"", L.aes_cbc(self.key, L.pad(body), encrypt=True))

    def ack(self):
        return L.Frame(L.ACK, 1, 0, L.ack_prefix(self.key),
                       L.aes_cbc(self.key, L.pad(b"\x00"), encrypt=True))

    def authrsp(self):
        return self._enc(L.AUTHRSP, L.authrsp_body(self.openid, self.token))

    def bingo(self):
        return self._enc(L.BINGO, L.bingo_body(rnd(19).encode()))

    def login_reply(self, req_payload):
        if self.cfg.login_reply:
            with open(self.cfg.login_reply, "rb") as f:
                return f.read()
        # Default guess: mirror the captured reply shape but report success.
        # result method "login", code 0, empty detail. Expected to be wrong;
        # the point is to read the client's reaction.
        return L.tdr_reply("login", 0, "")

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
                    r = L.parse_frame(buf)
                    if r is None:
                        break
                    frame, n = r
                    buf = buf[n:]
                    self.on_frame(frame)
                await self.writer.drain()
        except (ValueError, IndexError) as e:
            log(self.peer, f"!! {e!r}; buffered {buf[:48].hex()}")
        finally:
            self.writer.close()
            log(self.peer, "closed")

    def on_frame(self, f):
        log(self.peer, f"<< {f.cmd:#06x} seq {f.seq} ct {len(f.cipher)}")
        if f.cmd == L.SYN:
            # openid is the long digit run in the SYN prefix
            p = f.prefix
            digits = bytes(ch for ch in p if 0x30 <= ch <= 0x39)
            self.openid = digits[-18:] if len(digits) >= 18 else digits
            log(self.peer, f"   SYN openid={self.openid.decode(errors='replace')}")
            self.send(self.ack())
        elif f.cmd == L.AUTHREQ:
            p = f.plain(self.key)
            i = p.find(b"\x20", 4)                 # the 0x20 length byte before the token
            self.token = p[i + 1:i + 33] if i != -1 else b""
            log(self.peer, f"   AUTHREQ token={self.token.decode(errors='replace')}")
            self.send(self.authrsp())
            self.send(self.bingo())
        elif f.cmd == L.DATA:
            p = f.plain(self.key)
            method = L.rpc_method(p)
            log(self.peer, f"   DATA method={method!r}")
            self._dump_rpc(p)
            reply = self.login_reply(p)
            log(self.peer, f"   -> reply {reply[:64]!r}")
            self.send(L.data_frame(1, 0, self.key, reply))
        elif f.cmd in (L.STOP_C,):
            log(self.peer, "   client STOP")
        else:
            log(self.peer, f"   unhandled {f.cmd:#06x} prefix={f.prefix.hex()}")

    def _dump_rpc(self, p):
        try:
            vals = L.tdr_parse(p, p.index(0x78) + 1)
        except (ValueError, IndexError):
            return
        for v in vals:
            if isinstance(v, tuple) and v[0] == "map":
                for k, val in v[1]:
                    log(self.peer, f"      {k.decode(errors='replace')} = {val!r}")
            else:
                log(self.peer, f"      arg {v!r}")


async def serve(cfg, ready=None):
    async def handler(r, w):
        await Session(cfg, r, w).run()
    srv = await asyncio.start_server(handler, cfg.bind, cfg.port)
    port = srv.sockets[0].getsockname()[1]
    print(f"lobby server on {cfg.bind}:{port}", flush=True)
    if ready:
        ready.set_result(port)
    async with srv:
        await srv.serve_forever()


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=17500)
    ap.add_argument("--login-reply", help="file with a raw login reply payload")
    return ap.parse_args(argv)


if __name__ == "__main__":
    try:
        asyncio.run(serve(parse_args()))
    except KeyboardInterrupt:
        pass

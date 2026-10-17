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
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lobby as L  # noqa: E402


# request -> (reply name, reply args). Handler signatures, from the Lua:
#   DataMgr.InitHashList(ret, hashlist)      DataMgr.InitActivityGroupDataList(dataList)
#   ActivitySystem.InitActivityList(table)   DataMgr.InitShopLimitTemplate(template, hash)
#   DataMgr.InitShopLimitRoleData(buyInfo)
CONTENT_REPLIES = {
    b"bulletin_get_hashlist_req": ("bulletin_get_hashlist_res", ("ok", {})),
    b"get_act_gather_list_req": ("get_act_gather_list_res", ({},)),
    b"get_activity_list_req": ("get_activity_list_res", ({},)),
    b"get_direct_buy_list_req": ("get_direct_buy_list_res", ({}, "")),
    b"get_direct_buy_info_req": ("get_direct_buy_info_res", ({},)),
}


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
        self.role_name = b""
        self.avatar = {"gamegender": 1, "headid": 0, "hairid": 0}
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

    @staticmethod
    def _rpc_args(p):
        try:
            return L.tdr_parse(p, p.index(0x78) + 1)[1:]
        except (ValueError, IndexError):
            return []

    def dispatch(self, method, args, payload):
        """Return the packets to send in response. Handlers and their argument
        lists come from the game's own Lua (see docs/12):

            s2c["heart_beat"]          NetUtil.OnHeartBeatRsp(key, now)
            s2c["please_create_role"]  LobbySystem.on_please_create_role()
            s2c["create_role_respond"] LobbySystem.on_create_role_respond(ret)
            s2c["sync_base_info"]      LobbySystem.on_sync_base_info(roleData)

        There is no login_success: per the comment in logic_login.lua, success
        is signalled by simply continuing to the next packet.
        """
        if self.cfg.login_reply and method == b"login":
            with open(self.cfg.login_reply, "rb") as f:
                return [f.read()]
        if method == b"heart_beat":
            # echo the client's timestamp, then our clock in whole seconds
            key = args[0] if args else 0
            return [L.encode_pkg("heart_beat", key, int(time.time()))]
        if method == b"login":
            # a fresh Guest account has no character yet
            return [L.encode_pkg("please_create_role")]
        if method == b"create_role_request":
            # bp_createrole.lua: SendPriorityPkg(true, "create_role_respond",
            #   "create_role_request", Name, Sex, HeadId, HairID, DeviceOSInfo)
            name = args[0] if args else b"Player"
            self.role_name = name
            # args: Name, Sex, HeadId, HairID, DeviceOSInfo -- echo the look
            # back so the character the player built is the one the lobby shows
            # pass the decoded values straight back: each re-encodes in the
            # same form the client used, so the ids mean what the client meant
            self.avatar = {
                "gamegender": args[1] if len(args) > 1 else 1,
                "headid": args[2] if len(args) > 2 else 0,
                "hairid": args[3] if len(args) > 3 else 0,
            }
            log(self.peer, f"   avatar={self.avatar}")
            return [L.encode_pkg("create_role_respond", "ok"),
                    L.encode_pkg("sync_base_info", self.role_data(name))]
        # Lobby content requests. Signatures from the s2c handlers in the
        # game's Lua; empty collections are enough to let the UI finish init.
        if method in CONTENT_REPLIES:
            name, args_out = CONTENT_REPLIES[method]
            return [L.encode_pkg(name, *args_out)]
        log(self.peer, f"   (no handler for {method!r})")
        return []

    def role_data(self, name):
        """Minimal roleData for LobbySystem.on_sync_base_info.

        Field names are taken straight from the roleDataTb table in
        logic_lobby.lua. wxsubscribe/qqsubscribe must be present as tables with
        a setflag, or the client logs "服务端没有下发...字段" and may fault.
        """
        # avatar MUST be a table: data_mgr.lua reads avatar.gamegender /
        # .headid / .hairid directly, and indexing a number aborts the rest of
        # on_sync_base_info -- which leaves the lobby scene loaded but its UI
        # never built (a blank screen with the background visible).
        return {
            "name": name, "level": 1, "openid": self.openid,
            "uid": 10001, "exp": 0, "gold": 0,
            "avatar": self.avatar,
            "depot": {"items": {}},
            "rolewear": {}, "parachute": "", "signature": "",
            "pic_url": "", "rela_sex": 0,
            "segment_info": {}, "login_reward": {},
            "last_login_reward_remind": 0,
            # task / activeness / week_signup / share_award are deliberately
            # OMITTED. Each is nil-guarded in data_mgr.lua with a harmless
            # `sandbox.LogError(...)` else-branch, so leaving them out skips
            # that init entirely. Supplying them instead runs code that
            # dereferences sub-fields (pairs(task.list), #week_signup.list) and
            # calls UI updaters (ShareAwardMgr -> RoleInfoUI/LevelUpUI) during
            # early init -- any of which aborts InitRoleData, and with it
            # LocalEnterLobby(), leaving the lobby scene up with no UI.
            "cur_avatar_box_id": 0, "qq_vip": 0, "xy_red_point": 0,
            "anchor": 0, "svr_time": int(time.time()),
            "wxsubscribe": {"setflag": 0}, "qqsubscribe": {"setflag": 0},
        }

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
            args = self._rpc_args(p)
            if method != b"heart_beat":
                log(self.peer, f"   RPC {method!r}")
                self._dump_rpc(p)
            for reply in self.dispatch(method, args, p):
                log(self.peer, f"   -> {L.rpc_method(reply)!r}")
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
            if isinstance(v, dict):
                for k, val in v.items():
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

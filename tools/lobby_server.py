"""Lobby server for PUBG Mobile 0.3.2 -- the :17500 tconnd transport.

    python -I tools/lobby_server.py [--port 17500] [--db pubgm.db]
                                    [--starting-gold N]

Completes the tconnd handshake (SYN->ACK, AUTHREQ->AUTHRSP+BINGO) with a session
key we choose, then serves the lobby RPCs. Accounts, characters and inventory
persist in SQLite (store.py), so players keep their character across restarts
and several people get distinct identities. Manage them with tools/admin.py.

Taking the client from login to the full lobby UI needs two non-obvious things;
both are documented in docs/14-lobby-reached.md and enforced in store.py:
  * there is no `login_success` -- success is signalled by simply sending the
    next packet (`please_create_role`, or `sync_base_info` for a returning
    player);
  * parts of roleData must be OMITTED rather than sent empty, because they are
    nil-guarded and their non-nil paths dereference sub-fields.

Every DATA RPC is logged decoded, so this doubles as the bring-up instrument.
Nothing here touches the official services; it only answers our own client.
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
from store import Store  # noqa: E402


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
    def __init__(self, cfg, reader, writer, db):
        self.cfg, self.reader, self.writer, self.db = cfg, reader, writer, db
        self.peer = "%s:%d" % writer.get_extra_info("peername")[:2]
        self.key = rnd(16).encode()
        self.openid = b""
        self.uid = None
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
            # The client's openid is self-asserted and unverifiable, so on a
            # public server admission control is the only gate. See
            # docs/16-hosting.md.
            ok, why = self.db.may_login(self.openid, self.cfg.registration)
            if not ok:
                log(self.peer, f"   REJECTED ({why}) openid="
                               f"{self.openid.decode('ascii', 'replace')}")
                if why == "not_invited":
                    log(self.peer, "   to admit: python -I tools/admin.py invite "
                                   f"{self.openid.decode('ascii', 'replace')}")
                return [L.encode_pkg("login_failed", 0, why)]
            self.db.touch_account(self.openid)
            ch = self.db.get_character_by_openid(self.openid)
            if ch is None:
                return [L.encode_pkg("please_create_role")]
            log(self.peer, f"   returning player {ch['name']} (uid {ch['uid']})")
            self.uid = ch["uid"]
            return [L.encode_pkg("sync_base_info", self.db.role_data(ch))]
        if method == b"create_role_request":
            # bp_createrole.lua: SendPriorityPkg(true, "create_role_respond",
            #   "create_role_request", Name, Sex, HeadId, HairID, DeviceOSInfo)
            name = args[0] if args else b"Player"
            if self.db.get_character_by_name(name):
                # the client shows this string in the create-role UI
                return [L.encode_pkg("create_role_respond", "name_exist")]
            ch = self.db.create_character(
                self.openid, name,
                gamegender=args[1] if len(args) > 1 else 1,
                headid=args[2] if len(args) > 2 else 0,
                hairid=args[3] if len(args) > 3 else 0,
                gold=self.cfg.starting_gold)
            self.uid = ch["uid"]
            log(self.peer, f"   created {ch['name']} uid={ch['uid']}")
            return [L.encode_pkg("create_role_respond", "ok"),
                    L.encode_pkg("sync_base_info", self.db.role_data(ch))]
        # Team / room state. The client asks for all of this before a match is
        # valid; signatures from logic_teamup.lua and logic_lobby.lua.
        if method == b"query_myid_request":
            # on_query_myid_respond(myuserid) -- it then asks for team info
            return [L.encode_pkg("query_myid_respond", str(self.uid or 0))]
        if method == b"room_info_request":
            # on_sync_room_info(room, members): room == nil takes the clean
            # "not in a room" path, so send the packet with no arguments.
            return [L.encode_pkg("sync_room_info")]
        if method == b"team_info_request":
            # on_team_info_sync(teamid, teaminfo). teamid 0 means solo, and the
            # client rebuilds the structure itself via CreateTeamInfoSingle --
            # but CompareMemBer() then walks teaminfo.members, so `members`
            # must be a table rather than absent (same nil-trap as docs/14).
            return [L.encode_pkg("team_info_sync", 0,
                                 {"fill": 1, "members": {}, "team_type": 0})]
        if method == b"get_mode_shield_req":
            # on_mode_shield_rsp(mode_shields): {mode_id: {is_shield,
            # open_begin, open_end}}. Empty = nothing is time-locked.
            return [L.encode_pkg("get_mode_shield_rsp", {})]
        if method == b"team_change_type_request":
            return [L.encode_pkg("team_change_type_respond", "ok")]
        if method == b"query_match_zone_list":
            # sync_match_zone_list_rsp sorts/iterates this and SaveZoneListInfo
            # reads zone_id / tpingsvr_ip / tpingsvr_port (port is a STRING --
            # see the commented-out test data in logic_teamup.lua). With an
            # empty list the client has no zone and falls back to pinging a
            # hardcoded address, so advertise our own.
            return [L.encode_pkg("sync_match_zone_list", {
                "1": {"zone_id": 1,
                      "tpingsvr_ip": self.cfg.match_ip,
                      "tpingsvr_port": str(self.cfg.ping_port)},
            })]
        if method == b"query_gm_request":
            # the client's built-in GM channel; gated on the account flag
            row = self.db.db.execute("SELECT is_admin FROM account WHERE openid=?",
                                     (self.openid.decode("ascii", "replace"),)).fetchone()
            is_gm = bool(row and row["is_admin"])
            log(self.peer, f"   GM channel -> {is_gm}")
            return [L.encode_pkg("query_gm_respond", 1 if is_gm else 0)]
        if method == b"on_match_req":
            return self.start_match(args)
        if method == b"on_match_cancel_req":
            return [L.encode_pkg("on_match_cancel_res", "ok")]
        if method == b"giveup_enter_game":
            log(self.peer, "   player declined the battle invite")
            return []
        # Lobby content requests. Signatures from the s2c handlers in the
        # game's Lua; empty collections are enough to let the UI finish init.
        if method in CONTENT_REPLIES:
            name, args_out = CONTENT_REPLIES[method]
            return [L.encode_pkg(name, *args_out)]
        log(self.peer, f"   (no handler for {method!r})")
        return []

    def start_match(self, args):
        """Hand the player off to the UE4 game server.

        The chain, all from the game's own Lua (docs/17-match-handoff.md):

            c2s on_match_req(roomMode, autoFill)
            s2c on_match_res(msg, waitTime, reason, surplustime)
            s2c on_match_success(msg, team_info)        -> shows loading
            s2c re_enter_game(ip, port, key, packet_key,
                              game_id, res, team_info)  -> NetUtil.EnterBattle

        `res` must be "ok" or the client shows an error and returns to the
        lobby. `key`, `packet_key` and `game_id` are opaque to the client: it
        carries them to the game server untouched. Since we run that server
        too, they are ours to define -- the same property that made the UE4
        handshake cookie our own choice (docs/04).
        """
        mode = args[0] if args else None
        # Argument types are not guessable from the Lua (it only concatenates
        # them); they come from disassembling the native binding at 0x00b1ccd8:
        #   ip  checklstring | port checknumber | key  checknumber
        #   name checklstring | packet_key checklstring | game_id checkinteger
        # `key` as a hex string makes luaL_checknumber raise, DispatchPacket's
        # xpcall swallows it, and EnterBattle silently never connects.
        game_id = secrets.randbits(31)
        key = secrets.randbits(31)
        packet_key = secrets.token_hex(8)
        ip, port = self.cfg.match_ip, self.cfg.match_port
        self.db.record_match(self.uid, game_id, key, packet_key)
        log(self.peer, f"   match: mode={mode!r} -> {ip}:{port} "
                       f"game_id={game_id} key={key}")
        # team_info is only used for voice chat, and in both handlers the voice
        # call happens *after* the part we need, so an empty table cannot block
        # the handoff even if it is the wrong shape.
        team_info = {}
        # `enter_game` (RoomSystem.on_enter_game, "正式进入游戏") is the packet
        # for *entering* a match: 5 args, no res/team_info, and it calls
        # EnterBattle straight away with no dialog. `re_enter_game` is the
        # reconnect path -- it prompts, and did not connect.
        #
        # A real server allocates a DS between "match found" and "enter game",
        # so enter_game arrives seconds later. Sent back-to-back it can land
        # while the client is still switching out of the lobby, so delay it.
        self.send_later(self.cfg.match_delay,
                        L.encode_pkg("enter_game", ip, port, key,
                                     packet_key, game_id))
        return [
            L.encode_pkg("on_match_res", "ok", 0),
            L.encode_pkg("on_match_success", "ok", team_info),
        ]

    def send_later(self, delay, payload):
        """Send a DATA packet after `delay` seconds, if still connected."""
        async def go():
            await asyncio.sleep(delay)
            if self.writer.is_closing():
                return
            log(self.peer, f"   (delayed {delay}s) -> {L.rpc_method(payload)!r}")
            self.send(L.data_frame(1, 0, self.key, payload))
            await self.writer.drain()
        asyncio.ensure_future(go())


# roleData now lives in store.py:Store.role_data, built from the database.
# The shape rules that make the lobby open at all are documented there and in
# docs/14-lobby-reached.md -- read them before changing the payload.

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
    db = Store(cfg.db)
    print(f"store: {os.path.abspath(cfg.db)} "
          f"({len(db.list_characters())} characters)", flush=True)

    async def handler(r, w):
        await Session(cfg, r, w, db).run()
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
    ap.add_argument("--db", default=os.environ.get("PUBGM_DB", "pubgm.db"),
                    help="SQLite file holding accounts and characters")
    ap.add_argument("--starting-gold", type=int, default=0,
                    help="currency granted to a newly created character")
    ap.add_argument("--registration", default="invite",
                    choices=("open", "invite", "closed"),
                    help="who may create an account (default: invite). Use"
                         " 'open' only on a trusted LAN.")
    ap.add_argument("--match-ip", default="127.0.0.1",
                    help="address of the UE4 game server handed to clients")
    ap.add_argument("--match-port", type=int, default=7777,
                    help="port of the UE4 game server (server/)")
    ap.add_argument("--ping-port", type=int, default=17000,
                    help="UDP ping server port advertised in the zone list")
    ap.add_argument("--match-delay", type=float, default=3.0,
                    help="seconds between on_match_success and enter_game")
    ap.add_argument("--login-reply", help="file with a raw login reply payload")
    return ap.parse_args(argv)


if __name__ == "__main__":
    try:
        asyncio.run(serve(parse_args()))
    except KeyboardInterrupt:
        pass

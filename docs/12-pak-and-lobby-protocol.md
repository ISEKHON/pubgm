# 12 — The pak opens, and the lobby protocol is source

**Status: the pak is fully readable and the entire lobby protocol is recovered
as readable Lua source.** This removes the Phase 4a blocker and most of the
guesswork from Phase 5.

Two findings, either of which would have been the headline on its own:

1. The pak is **not AES-encrypted**. Every entry is XORed with the single byte
   `0x79`.
2. The game ships its **Lua logic as plain source** inside the pak, including
   `logic_login.lua` and `logic_lobby.lua` — with the protocol documented in
   developer comments.

## 1. The pak "encryption" is XOR 0x79 — [CONFIRMED]

[05-obb-and-login.md](05-obb-and-login.md) recorded that all 28,041 entries are
flagged encrypted and concluded the contents were unreachable without an AES
key. That conclusion was wrong.

How it was spotted: the inline `FPakEntry` header at each entry's offset is
**plaintext**, and the payload that follows it was visibly non-random —
repeating `0x59`, `0x10`, `0x0c`. AES output has no such structure. A
single-byte XOR search over `Engine/Config/Base.ini` (33 bytes) produced, at key
`0x79`:

```
; Base.ini is required to exist
```

which is that file's exact stock UE4 contents. The same key inflates every
zlib-compressed entry cleanly, so it is the key for the whole pak.

### Entry layout

```
entry_offset ->  Offset        int64   (0 for the inline copy)
                 Size          int64   (compressed/stored size)
                 UncompressedSize int64
                 CompressionMethod int32  (0 = store, 1 = zlib)
                 Hash          20 bytes
                 [ nblocks int32, then nblocks * (start,end) int64 pairs ]   if compressed
                 bEncrypted    uint8
                 CompressionBlockSize uint32
                 payload ...   XOR 0x79, then zlib per block if compressed
```

Compression block offsets are **absolute within the pak**, not relative.

### Tooling

`tools/pak_tool.py` gained three commands, all reading the pak in place inside
the XAPK (nothing is unpacked):

```bash
python -I tools/pak_tool.py                                  # summary + filelist
python -I tools/pak_tool.py --cat  'ShadowTrackerExtra/Config/DefaultEngine.ini'
python -I tools/pak_tool.py --extract 'ShadowTrackerExtra/Content/lua/*' extracted/lua
python -I tools/pak_tool.py --grep 'needle1,needle2' '<name glob>'   # scans contents
```

## 2. Net driver config — [CONFIRMED]

From `ShadowTrackerExtra/Config/DefaultEngine.ini`, now readable:

```ini
NetDriverDefinitions=(DefName="GameNetDriver",
    DriverClassName="/Script/Basic.UAENetDriver",
    DriverClassNameFallback="/Script/Basic.UAENetDriver")

[/Script/Basic.UAENetDriver]
NetConnectionClassName=/Script/Basic.UAENetConnection
bNoTimeouts=True
InitialConnectTimeout=60.0
NetServerMaxTickRate=18
```

Stock `IpNetDriver` is explicitly removed (`-NetDriverDefinitions=`) in favour of
Tencent's `UAENetDriver`. **There is no `PacketHandler` / handshake component
override anywhere in the config**, which supports the `[STOCK]` assumption in
[01-protocol.md](01-protocol.md) that the StatelessConnect handshake is engine
default. `NetServerMaxTickRate=18` and `bNoTimeouts=True` are directly useful
for the Phase 6 server.

The ini also confirms `GameId 1375135419` / `GameKey b5eede99...` matching the
GCloud config seen at runtime, and `VersionInfo=0.3.2`.

## 3. The lobby protocol, from source — [CONFIRMED]

`extracted/lua/.../Content/lua/` holds 191 `.lua` files. Earlier recon only saw
`LuaCSV/*` (data tables) and missed the logic tree:

```
client/client_entry.lua              NetUtil: SendPkg, packet dispatch, heartbeats
client/logic/login/logic_login.lua   LoginSystem
client/logic/login/logic_lobby.lua   LobbySystem
client/logic/login/logic_room.lua    rooms/matchmaking
Server/PacketCallbacks.lua, Server/Server.lua
... ~40 more logic modules (friend, mail, rank, shop, team, chat, ...)
```

**207 distinct `s2c[...]` handlers** are registered across the tree — that is
the complete server→client surface, with each handler's parameter list visible.

### The login exchange

Request, from `LoginSystem.reqLoginLobby`:

```lua
NetUtil.SendPkg("login", ver, DeviceOSInfo.InfoList, startup_type, ext_info,
                device_type, channelID, registerchannelID, currentTime,
                language, timezone)
```

This matches byte-for-byte what our lobby server decoded live from the real
client (`docs/11`), including the `DeviceOSInfo.InfoList` map and
`ext_info = {relogin = ...}`.

The developers documented the reply contract in a comment at the end of
`logic_login.lua`:

> 连接后,客户端发送: `c2s.login(ver)` … 如果登录异常,会返回消息:
> `s2c.login_failed(reason)` … 也可能会返回 `s2c.redirect(url)`,
> 客户端应该断开连接,到指定的url重连登录. **成功则继续往下.**

*(After connecting the client sends `c2s.login(ver)`. On an abnormal login the
server returns `s2c.login_failed(reason)`; it may instead return
`s2c.redirect(url)`, on which the client should disconnect and reconnect to that
url. **On success, it simply continues.**)*

So **there is no `login_success` packet** — which is why guessing one in
[11-lobby-transport.md](11-lobby-transport.md) produced no reaction. Success is
signalled by the server moving on to the next packet.

### What actually completes the login

`LobbySystem.on_sync_base_info` is the handler that calls
`NetUtil.StopCheckLoginRsp()` and sets `LoginSystem.isInLobby = true`:

```lua
s2c["please_create_role"]  = LobbySystem.on_please_create_role
s2c["create_role_respond"] = LobbySystem.on_create_role_respond   -- (ret)
s2c["sync_base_info"]      = LobbySystem.on_sync_base_info        -- (roleData)
```

For an account with no character — which a fresh Guest login is — the expected
sequence is:

```
c2s login(...)
s2c please_create_role          -> client shows the create-character UI
c2s create_role(...)
s2c create_role_respond("ok")
s2c sync_base_info(roleData)    -> StopCheckLoginRsp, isInLobby = true
```

`please_create_role` is a far smaller packet to produce than a full `roleData`,
so it is the cheapest next milestone: it should visibly move the client off the
login screen into character creation.

`roleData` is fully enumerated in `on_sync_base_info` (name, level, openid, uid,
exp, gold, avatar, depot.items, rolewear, parachute, signature, pic_url,
rela_sex, segment_info, login_reward, activeness, task, week_signup,
share_award, cur_avatar_box_id, qq_vip, xy_red_point, svr_time, and the
`wxsubscribe`/`qqsubscribe` sub-tables the client logs an error about if
missing). Every field name and its use is readable, so this is now
transcription rather than reverse engineering.

### Where the lobby addresses came from

Hardcoded in `logic_login.lua`, answering the open question in `docs/10`:

```lua
LoginSystem.direct_login_server_list = {
  addr = {"tcp://lobby.igamecj.com:17500", "tcp://49.51.43.31:17500"}, ... }
```

The comment above `connectGateway` notes the newer flow skips the gateway and
dials the lobby URL directly, which is what the capture showed.

## Next

1. **Encode `please_create_role`** in `tools/lobby_server.py` and send it after
   `login`. Confirm the client leaves the login screen. This is the next
   observable milestone and it is small.
2. Implement `create_role` → `create_role_respond("ok")` → `sync_base_info`.
3. Pin down `NetUtil.SendPkg`'s encoder in `client_entry.lua` against the
   "tdr compact" decoder in `tools/lobby.py`, so replies are encoded from a
   verified spec rather than inferred from one captured example.

The remaining work on the lobby is now **writing** a known protocol, not
discovering one.

## Caveat

The extracted Lua and configs are game content: they stay in `extracted/`,
which is gitignored, and are not redistributed. Everything here is reproducible
from one's own copy with the commands above.

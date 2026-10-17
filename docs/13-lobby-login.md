# 13 — Login, character creation, and entering the lobby

**Status: the real client logs in, creates a character, and enters the lobby
scene against `tools/lobby_server.py`. The lobby UI does not yet render.**

This is the furthest the project has reached. Everything below was observed on
the user's own device against our own server; the official services were not
involved beyond the already-captured samples.

## What works end to end

```
<< SYN      openid=188039022634206504
>> ACK      (session key we choose)
<< AUTHREQ  token=0526f464...
>> AUTHRSP  >> BINGO
<< login(0.3.2.3212, device_info, startup_type, ext_info, ...)
>> please_create_role                 -> client shows the character creator
<< create_role_request(Name, Sex, HeadId, HairID, DeviceOSInfo)
>> create_role_respond("ok")
>> sync_base_info(roleData)           -> StopCheckLoginRsp, isInLobby = true
<< get_act_gather_list_req / get_activity_list_req / bulletin_get_hashlist_req
   / get_direct_buy_list_req / get_direct_buy_info_req
>> (empty replies for each)
<< heart_beat(t)   >> heart_beat(t, now)     ... steady state
```

**Observed:** the character-creation screen rendered fully — 3D character, face
and hair pickers, gender toggle, a server-assigned name, Create button. After
Create, the client entered the lobby scene (its background and ember particles
are on screen) and settled into a stable heartbeat loop with no retries and no
error dialog.

**Not yet working:** the lobby UI itself never draws. The screen stays on the
lobby background.

## Protocol details learned

### The packet encoder is now pinned down

`NetUtil.SendPkg(...)` / `NetUtil.DispatchPacket(msg, ...)` in
`client_entry.lua` confirm the payload is simply the message name followed by
its arguments. `tools/lobby.py:encode_pkg` reproduces the real server's
`login_failed` payload byte-for-byte (`test_encoder_reproduces_capture`).

Value encoding ("tdr compact"):

| tag | meaning |
|---|---|
| `0x02 <LEB128>` | integer |
| `0x03 <len> <bytes>` | string (1-byte length; no >255 sample exists) |
| `0x04 <u8>` | 1-byte integer |
| `0x07 ... 0x08` | **map: begin and end** |
| `0x09`–`0x1f` | a small integer as a single byte; base not pinned down |

**The `0x08` map terminator was the single most costly omission.** Without it
the client's decoder runs off the end of the packet and silently ignores the
message — no error, no reaction. `sync_base_info` was being dropped for this
reason alone. Values decoded as small ints are re-emitted verbatim rather than
re-encoded, so ids mean to the client exactly what the client sent.

### roleData must be shaped, not just present

`data_mgr.lua:InitRoleData` dereferences nested fields directly:

```lua
DataMgr.roleData.gender    = roleDataTb.avatar.gamegender
DataMgr.avatarData.headid  = roleDataTb.avatar.headid
DataMgr.avatarData.hairid  = roleDataTb.avatar.hairid
for k,v in pairs(roleDataTb.rolewear) do ... end
```

So `avatar` must be a **table** with `gamegender`/`headid`/`hairid`. Sending it
as a number throws "attempt to index a number", which `DispatchPacket`'s
`xpcall` swallows — the handler aborts midway, leaving the scene loaded and the
UI half-built. `wxsubscribe`/`qqsubscribe` must be tables carrying `setflag`,
and the client logs a specific complaint when they are missing.

The server echoes the client's own `Sex`/`HeadId`/`HairID` from
`create_role_request` back into `avatar`, so the character the player built is
the one the lobby is told about.

### Heartbeats are mandatory

`client_entry.lua` sends `heart_beat(curTime)` on a timer and disconnects if the
reply does not arrive. The server answers `heart_beat(key, now)` echoing the
client's timestamp plus server time in whole seconds.

## The open problem: no Lua log

The remaining UI failure needs the Lua traceback, and **UE4 file logging is
currently disabled on this device**. The game logged normally to
`Saved/Logs/ShadowTrackerExtra-*.log` (channel `LogNula: LuaLog:`) until
2026-10-17 14:08, when an in-game **Repair** ran
`delete Saved Directory` and reset every generated ini in
`Saved/Config/Android/` to 1 byte. No log file has been created since, and
`force-stop` kills the process before UE4 flushes anyway.

**Next step, and it is the cheapest one:** restore logging by clearing the app's
data (or reinstalling), which recreates a healthy `Saved/` tree. With
`LuaLog` back, the UI failure becomes a one-line diagnosis instead of guesswork.
Exit the game through its own UI rather than `force-stop` so the log flushes.

Candidates for the UI failure, in order, once logs are back:
1. Another nested `roleData` field dereferenced during `LobbyUI.Init()` —
   `segment_info`, `login_reward`, `task`, `activeness` and `week_signup` are
   currently sent as empty maps and may need real sub-fields.
2. A missing follow-up packet the lobby waits on (`sync_my_plat_name`,
   `query_gm_respond`, `get_activity_display_res` are all registered).
3. `LobbySystem.Enter()` posts `EVENTID_ENTERLOBBY`; whatever subscribes to it
   may need state the server has not supplied.

## Tooling

| tool | role |
|---|---|
| `tools/lobby.py` | transport + `encode_pkg`/`tdr_parse` for the RPC payloads |
| `tools/lobby_server.py` | the lobby server and bring-up instrument; logs every RPC decoded, `--login-reply FILE` to iterate |
| `tools/test_lobby.py` | **32 checks**, incl. byte-exact round-trips of the captured handshake and `login_failed` payload |

`tools/tgcp_server.py` must run alongside it (ports 8085/8086) to clear the
update gate, with both `download.2.1375135419.igame.gcloudcs.com` and
`lobby.igamecj.com` redirected to the host. The device was reverted after
testing.

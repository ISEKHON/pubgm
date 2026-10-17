# 17 — The match handoff: `EnterBattle`

How the lobby sends a player into a match, and what the game server has to
accept when they arrive. This is the bridge between the lobby work (`docs/11`
–`14`) and the UE4 server written back in Phases 2–3 (`server/`, `docs/04`).

Everything here is read from the game's own Lua, recovered in `docs/12`.

## The chain

```
c2s  on_match_req(roomMode, autoFill)                    -- player taps Start
s2c  on_match_res(msg, waitTime, reason, surplustime)    -- "ok" + queue time
s2c  on_match_success(msg, team_info)                    -- "ok" -> loading screen
s2c  re_enter_game(ip, port, key, packet_key,
                   game_id, res, team_info)
       -> NetUtil.EnterBattle(ip, port, key, nickName, packet_key, game_id)
       -> Client.EnterBattle(...)                        -- native, UE4 connect
```

`NetUtil.EnterBattle` is a thin wrapper; the work happens in the native
`Client.EnterBattle(GameFrontendHUD, ip, port, key, name, packet_key, game_id)`.

### `re_enter_game` behaviour — [CONFIRMED from source]

`NetUtil.OnReEnterGameNotify` in `client_entry.lua`:

- `res` must be **`"ok"`**. Anything else shows an error box and returns to the
  lobby; `"version_mismatch"` gets its own message.
- If the DS state is already `Connecting`, it returns early and does nothing —
  the server is expected to pull the player in instead.
- If the player is already `fighting` and the DS is `Online` or
  `RecoverableLost`, it does nothing; otherwise it silently re-enters.
- Otherwise it shows a **"re-enter battle?" confirmation dialog**
  (`CommonMessageBoxUI:ShowPanel(2, ...)`). OK calls `EnterBattle`; Cancel sends
  `giveup_enter_game`.

That dialog makes `re_enter_game` a usable bring-up lever on its own: push it at
a client sitting in the lobby, tap OK, and it will try to connect to whatever
address you named — no matchmaking needed.

`game_id` is stashed in the global `g_game_id` for the end-of-match logic.

## The important property: the tokens are ours

`key`, `packet_key` and `game_id` are **opaque to the client**. It receives them
from the lobby and carries them to the game server without interpreting them.

Since we run both ends, we define them. This is the same realisation that made
the UE4 handshake cookie our own choice (`docs/04`): the client is a courier,
not a validator. `tools/lobby_server.py` issues random values and records them
in the `match_ticket` table so the game server can check an arriving player
against a ticket the lobby actually handed out, rather than trusting the client.

## `packet_key` is not UE4 packet encryption — [CONFIRMED]

The obvious worry was that `packet_key` keys a UE4 `PacketHandler` encryption
component, which would invalidate the stock-handshake assumption behind
`server/`. It does not. The handler components present in `libUE4.so` are:

```
StatelessConnectHandlerComponent.cpp
ReliabilityHandlerComponent
PacketHandler.cpp / HandlerComponentFactory.h
```

There is **no** `EncryptionComponent` or `AESHandlerComponent` anywhere in the
binary, and `DefaultEngine.ini` has no `PacketHandlerComponents` override
(`docs/12`). So the UE4 link runs the stock component chain and is not
encrypted. `packet_key` is an application-level token — most likely presented to
the DS for admission — not transport crypto.

This confirms the design `server/` was already built to: stock UE4 4.18
StatelessConnect, 195-bit handshake packets, 20-byte cookie.

## What the client does on arrival

`PendingNetGame.cpp`, `ClientTravel` and `ClientTravelInternal` are all in the
binary, so `Client.EnterBattle` drives an ordinary UE4 client travel to
`ip:port`. That means the server sees the standard sequence:

1. StatelessConnect handshake over UDP (`server/src/handshake.c` — written and
   passing its tests against a synthetic client)
2. `NMT_Hello` with the network version — ours must match or the client logs
   both numbers and disconnects (`recon/network-version.md`; first value to try
   is `0xF6035FB3`)
3. `NMT_Login` carrying the URL options — this is where `key` / `packet_key` /
   the player name are expected to appear
4. `NMT_Welcome`, then the map load and `NMT_Join`

Note the NMT numbering is **not stock**: `Join = 9`, not 7
(`recon/control-messages.md`).

## Implemented

`tools/lobby_server.py` now answers the whole chain:

```bash
python -I run_server.py --public-ip <IP> --match-ip <IP> --match-port 7777
```

- `on_match_req` → `on_match_res("ok", 0)` + `on_match_success("ok", {})` +
  `re_enter_game(...)` pointing at `--match-ip:--match-port`
- `on_match_cancel_req` → `on_match_cancel_res("ok")`
- `giveup_enter_game` → logged (the player declined the dialog)
- every issued ticket is written to `match_ticket`

`team_info` is sent as an empty table. In both handlers the voice-chat call that
consumes it happens **after** the part we need (`ShowMatchSuccess`, and
`EnterBattle` respectively), so even if its shape is wrong it cannot block the
handoff — it would at worst drop voice. Worth confirming once a match connects.

## Open questions

- **URL option names.** Exactly how `key`, `packet_key` and the player name are
  encoded into the travel URL is not yet confirmed. The server will see them in
  `NMT_Login`'s options string; the fastest way to learn the names is to let a
  real client connect to `server/` and log the raw string. That is the next
  experiment, and it needs no new analysis.
- **`roomMode` / `autoFill`.** `on_match_req` carries the mode the player chose;
  currently ignored. Needed once more than one game mode matters.
- **DS state machine.** `Client.GetUnrealNetworkStatus` returns
  `Connecting` / `Online` / `RecoverableLost`; the re-entry logic branches on it.
  Relevant for reconnect handling, not for a first connection.

## Bring-up result (2026-10-17) — [CONFIRMED]

First live attempt against `server/build/pubgm_server.exe` on UDP 7777.

**What works:** the entire lobby side.

```
RPC on_match_req
match: mode=... -> 10.0.2.2:7777 game_id=2036574341 key=69c4d1c875fc5b5b
-> on_match_res   -> on_match_success   -> re_enter_game
```

The client accepted all three, showed "match found", displayed the
**re-enter battle?** dialog described above, and on OK moved to the battle
**Loading** screen. Persistence was confirmed in the same run: a relaunch logged
the player straight back in as a returning character (`returning player SEKHON
(uid 10001)`) with no create-role step.

**What does not work:** the client never connects.

| probe | result |
|---|---|
| packets on our UDP 7777 | **none** |
| `tcpdump -i any udp` on the device | only QUIC to Google; **nothing toward any game server** |
| UDP sockets in the game process | **none** (`/proc/<pid>/net/udp` holds only mdnsd's) |
| open fds over 100 s | flat at 21 — nothing opening |
| logcat for map/travel/net | nothing; only SDK noise |

So `Client.EnterBattle` is called but **no UE4 net driver is created at all**.
This is not a handshake problem — the client never gets as far as sending a
packet, so none of `server/`'s layout assumptions have been tested yet.

### Ruled out

- **Wrong port from varint encoding.** Type `0x02` is a plain LEB128, not
  zigzag: the login packet's `ScreenWidth`/`ScreenHight` decode to 2068/948,
  which are the device's real reported dimensions. A mis-encoded port would
  also still have produced *some* UDP, and there is none.
- **UE4 packet encryption.** Already ruled out above; irrelevant here anyway.

### Second session: `enter_game`, team state, and network proof

Three things were established after the first attempt.

**1. `enter_game` is the right packet, not `re_enter_game`.**

```lua
-- logic_room.lua, "正式进入游戏" (formally enter the game)
s2c["enter_game"] = RoomSystem.on_enter_game(ip, port, key, packet_key, game_id)
```

Five arguments, no `res`/`team_info`, and it calls `NetUtil.EnterBattle`
immediately with **no confirmation dialog**. `re_enter_game` is the reconnect
path. The server now sends `enter_game`.

**2. The team/room RPCs are answered.** All from the Lua signatures:

| c2s | s2c sent |
|---|---|
| `query_myid_request` | `query_myid_respond(uid)` |
| `team_info_request` | `team_info_sync(0, {fill, members:{}, team_type})` |
| `get_mode_shield_req` | `get_mode_shield_rsp({})` |
| `query_match_zone_list` | `sync_match_zone_list({})` |
| `team_change_type_request` | `team_change_type_respond("ok")` |
| `query_gm_request` | `query_gm_respond(is_admin)` — the GM channel |

`teamid = 0` means solo and the client rebuilds the structure itself via
`CreateTeamInfoSingle`, but `CompareMemBer()` then walks `teaminfo.members`, so
`members` must be a table — the same nil-trap as `docs/14`.

**3. The network path is proven good.** A hand-injected datagram from the
device reached the server and decoded exactly as designed:

```
adb shell "echo HELLOUDP | toybox nc -u -w 2 10.0.2.2 7777"

[0] from 127.0.0.1:52880
  rx (9 bytes): 48 45 4c 4c 4f 55 44 50 0a
  payload bits = 67 (expected 195 for a handshake)
```

So UDP device→host:7777 works, and the listener receives and reports correctly.
**The game simply never sends.** This also rules out any BlueStacks
TCP-only-NAT theory.

### The native signature, from disassembly — [CONFIRMED]

Black-box guessing was exhausted, so the binding was located statically. The
method is reusable for any `Client.*` call:

1. Find the binding name string in the binary (**note:** `recon/strings.txt` is
   stale and does **not** contain it — search the `.so` directly):
   `EnterBattle` is at `0x342d919`, in a run of `Client.*` names
   (`ShutdownUnrealNetwork`, `GetUnrealNetworkStatus`, `ReturnToLobby`,
   `OnBattleResult`, `EnterBattle`, `SetPlayerBaseInfo`, `InitLoginAccount`,
   `ConnectToURL`, `SetGameSrvID`, `SetGameStatusMap`, …).
2. Search for the little-endian **pointer** to that string. The Lua binding
   table is `{name_ptr, func_ptr}` pairs, found at `0x3651904`:

   ```
   0342d90a -> 00b1a574   OnBattleResult
   0342d919 -> 00b1ccd8   EnterBattle
   0342d925 -> 00b1d8d4   SetPlayerBaseInfo
   ```
3. Disassemble the function and read its `luaL_check*` calls in order.

`Client.EnterBattle` at **`0x00b1ccd8`**:

| arg | field | native check | type |
|---:|---|---|---|
| 1 | HUD | `lua_touserdata` | userdata |
| 2 | `ip` | `luaL_checklstring` | **string** |
| 3 | `port` | `luaL_checknumber` | **number** |
| 4 | `key` | `luaL_checknumber` | **number** |
| 5 | `name` | `luaL_checklstring` | **string** |
| 6 | `packet_key` | `luaL_checklstring` | **string** |
| 7 | `game_id` | `luaL_checkinteger` | **integer** |

**`key` must be a number.** We had been sending a 16-char hex string, which
makes `luaL_checknumber` raise a Lua error; `DispatchPacket`'s `xpcall`
swallows it, so `EnterBattle` aborts with no message and no socket — exactly
the observed symptom. `packet_key`, by contrast, *is* a string.

This also explains why every black-box permutation failed identically: the call
never got past argument checking.

### Also ruled out

- `re_enter_game` vs `enter_game` — both tried; neither connects.
- `port` / `game_id` as **numbers** and as **strings** — both tried, identical
  result. The Lua only concatenates them, so the script layer cannot reveal
  which the native binding wants, but neither form produces a socket.
- Missing team/room state for the five RPCs above — now answered, no change.

### After the fix: the client finally sends UDP — to a ping server

With `key` as a number the behaviour changed for the first time:

- the battle loading bar reaches ~80% instead of stalling around 45%
- UDP sockets appear in the network namespace (3 rows → 7-8) where the process
  previously had **none**
- `tcpdump` now shows real UDP traffic from the game, **two-way**:

```
10.0.2.15:35908 -> 49.51.180.215:17000     (x5)
49.51.180.215:17000 -> 10.0.2.15:59557     (x2)
```

Port **17000** matches the `setUDPPingServerAddress` binding: these are
**zone latency pings**, not the game connection. The address is a leftover
hardcoded one, reached because `query_match_zone_list` was answered with an
**empty** list — so the client has no zone of ours to ping and cannot complete
zone selection.

The server now advertises a zone pointing at our own address:

```lua
-- SaveZoneListInfo reads exactly these, and the commented-out test data in
-- logic_teamup.lua shows tpingsvr_port is a STRING
{ zone_id = 1, tpingsvr_ip = <match ip>, tpingsvr_port = "17000" }
```

**Not yet verified**, and it implies the next piece of work: a **UDP ping
responder on 17000**, since advertising a zone whose ping never answers may
leave the client just as stuck. That is a small service — the probes are
visible in the capture above and can be answered by echoing.

### Candidates, cheapest first

1. **Get the Lua log back.** This has been the recurring handicap: every
   diagnosis so far has been by inference because UE4 file logging is dead on
   this device (`docs/13`). `Client.EnterBattle` almost certainly logs or
   errors on the native side, and one line of `LogNula` would end this.
   Worth real effort: find why `Saved/Logs` is never written (it worked once,
   at 14:05 on 2026-10-17), or run the client on a device/emulator where it is.
2. **`room_info_request`** is the last unanswered RPC in this path, and
   `RoomSystem` is the very module that owns `on_enter_game`. If the room
   object must exist before `EnterBattle` is meaningful, this is the gap.
   `s2c["sync_room_info"]` / `s2c["room_info_notify"]` are the replies.
3. **A precondition inside `Client.EnterBattle`** — game status, HUD state, or
   TSS/anti-cheat being initialised. Note the project does not modify or bypass
   anti-cheat; if TSS must simply be *running* that is fine, but defeating it
   is out of scope and would end this line of work.
4. **`ip` as `"host:port"`** in one argument, with `port` ignored.

(1) and (2) need no new reverse engineering. (3) is where this could stop.

## Next step

Point `--match-ip/--match-port` at `server/build/pubgm_server.exe`, tap Start,
accept the dialog, and read what arrives. `server/src/main.c` is already built
as the instrument: it logs every datagram's raw hex, exact payload bit count and
a field-by-field decode, and complains loudly rather than dropping anything it
cannot parse (`docs/04`). The first datagram tells us whether the handshake
budget and field order are right; the `NMT_Login` that follows gives us the
option names for free.

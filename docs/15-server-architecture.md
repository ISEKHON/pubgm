# 15 — Server architecture: full control, and playing as a group

The prototype in `tools/lobby_server.py` proved the protocol. It is not yet a
server: it holds no state, knows one player, and forgets everything on
disconnect. This document is the design for the real thing — a server with the
control a developer or admin would have, that a small group can actually play
on.

Nothing here requires new protocol discovery. The lobby protocol is already
recovered as source (`docs/12`), so this is engineering, not reverse
engineering.

## Goals

1. **Full control** — accounts, characters, inventory, currency, progression and
   match settings all owned by the server and changeable at will.
2. **A group can play** — several people, on their own devices, against one
   server, without each of them needing a rooted device.
3. **Honest state** — the server is the source of truth; the client is never
   patched.

## Current shortcomings

| problem | consequence |
|---|---|
| state lives in a `Session` object | log out and your character is gone |
| `roleData` is hardcoded | everyone is the same player, uid 10001 |
| no account model | `openid` is accepted blindly |
| one connection assumed | no friends, teams, chat or matchmaking |
| no admin surface | changing anything means editing Python and restarting |
| hosts redirect needs root | every player must root their device |

## Target shape

```
                   ┌────────────────────────┐
   players ───────▶│  gateway (TCP 17500)   │  tconnd transport, per-connection
                   │  tools/lobby_server    │  sessions, heartbeats
                   └───────────┬────────────┘
                               │ dispatch by RPC name
                   ┌───────────▼────────────┐
                   │   services             │  login, role, inventory, friends,
                   │                        │  mail, shop, team, matchmaking, GM
                   └───────────┬────────────┘
                               │
                   ┌───────────▼────────────┐      ┌──────────────────┐
                   │   store (SQLite)       │◀────▶│  admin CLI / web │
                   │  accounts, characters, │      │  grant, set, ban │
                   │  inventory, progress   │      └──────────────────┘
                   └───────────┬────────────┘
                               │ hands out match address
                   ┌───────────▼────────────┐
                   │  game server (UE4/C)   │  server/ -- handshake, replication
                   └────────────────────────┘
```

### 1. Persistence — SQLite

One file, no daemon, trivially backed up. Schema, first cut:

```sql
CREATE TABLE account   (openid TEXT PRIMARY KEY, created_at INT, banned INT DEFAULT 0,
                        is_admin INT DEFAULT 0);
CREATE TABLE character (uid INTEGER PRIMARY KEY, openid TEXT, name TEXT UNIQUE,
                        level INT, exp INT, gold INT,
                        gamegender INT, headid INT, hairid INT,
                        created_at INT);
CREATE TABLE item      (ins_id INTEGER PRIMARY KEY, uid INT, res_id INT,
                        count INT, is_new INT, expire_ts INT);
CREATE TABLE kv        (uid INT, key TEXT, value TEXT, PRIMARY KEY (uid, key));
```

`roleData` is then built from the database instead of a literal, and
`create_role_request` inserts a row rather than echoing back what it was sent.

**Carry the `roleData` rules from [14](docs/14-lobby-reached.md) forward:**
`avatar` must be a table; `task` / `activeness` / `week_signup` / `share_award`
must be **omitted** until each is modelled properly, because their non-nil paths
dereference sub-fields and silently abort the client's init.

### 2. Services, split by RPC

`lobby_server.py` grows a dispatch table keyed by RPC name, one module per
domain, each reading and writing the store. The RPC surface the client asks for
on entering the lobby is already enumerated in [14](docs/14-lobby-reached.md);
the handler signatures are readable in the extracted Lua, so each is
transcription.

Priority order, by what unlocks play:

1. `login`, `create_role_request`, `sync_base_info` — **done**, needs persisting
2. `query_myid_request`, inventory / `depot` — identity and items
3. friends, mail, chat — social, and cheap
4. `query_match_zone_list`, `room_info_request`, team RPCs — **the path to a match**
5. `query_gm_request` — the admin channel (below)

### 3. Admin control

The client has a **GM channel built in** (`query_gm_request`, with
`query_gm_respond` registered in `logic_lobby.lua`). That is the intended
in-game admin hook and is worth wiring up once the store exists.

Two surfaces, cheapest first:

- **CLI against the store** — `admin.py grant <name> <res_id> <count>`,
  `set-level`, `set-gold`, `ban`, `unban`, `list-players`. Works offline, no
  protocol needed, immediate.
- **Live commands** — push changes to a connected client by sending the same
  `s2c` packets the real server would (`sync_base_info` to refresh, inventory
  notifies, `kickout` to disconnect, `notify_*` for messages). The client already
  has handlers for all of these; nothing new is needed on its side.

An admin flag on the account gates both.

### 4. Letting a group play — without rooting every device

The hosts bind-mount needs root. **It is not the only option, and not the best
one for a group.** The client resolves `lobby.igamecj.com` and
`download.2.1375135419.igame.gcloudcs.com` by normal DNS, so:

> **Run a small DNS server on the host that answers those two names with the
> server's LAN IP, and forwards everything else upstream. Then each player only
> sets their device's DNS to your machine — no root.**

`dnsmasq`, CoreDNS, or ~40 lines of Python with `dnslib` all do this. On Android,
a static DNS can be set per Wi-Fi network in the device's network settings.

Caveats to handle:
- The client also has a hardcoded fallback **IP** (`49.51.43.31:17500`), which
  DNS cannot redirect. It is only used if the first address fails, so a healthy
  primary avoids it. A LAN firewall/NAT rule can catch it if needed.
- Some SDK components use DNS-over-TLS to `8.8.8.8` and will bypass a LAN DNS.
  That affects telemetry, not the lobby path, which has been observed to honour
  `/etc/hosts` and ordinary DNS.

### 5. Packaging for friends

The goal is that a player does three things: install the game, set DNS, play.

- Ship a single `run-server` entry point that starts the version gate, the DNS
  responder and the lobby together, reading one `config.toml` (bind address,
  LAN IP to advertise, database path, admin accounts).
- Document the device-side DNS step with screenshots.
- Do **not** redistribute the APK/OBB. Players bring their own copy; the
  repository stays clean of game content.

## Build order

| step | outcome |
|---|---|
| 1. SQLite store + build `roleData` from it | characters persist across restarts |
| 2. Account identity from `openid`, real `uid` | several people, distinct characters |
| 3. `admin.py` CLI | grant items, set level/currency, ban |
| 4. DNS responder + `config.toml` + one entry point | friends join without rooting |
| 5. Inventory / depot RPCs | items visible and usable in the UI |
| 6. Team + matchmaking RPCs | a squad can form |
| 7. Hand out a match address; bring up `server/` | an actual match |

Steps 1–4 make it a server a group can use; 5–7 make matches happen. Step 7 is
where the UE4 work from Phases 2–3 (`server/`, `docs/01`, `docs/04`) finally
gets exercised — that code already passes its handshake tests against a
synthetic client.

## Open questions

- **Match handoff.** `NetUtil.EnterBattle(ip, port, key, name, packet_key, game_id)`
  in `client_entry.lua` is how the client is told where to play. Its parameters
  (notably `packet_key`) need confirming before the game server can be addressed.
- **The 2^64 rank readout** ([14](docs/14-lobby-reached.md)) — a signedness bug
  in some numeric field, to fix when rank/segment data is modelled.
- **Anti-cheat.** TenProtect is present in the client and is out of scope: not
  analysed, not modified, not bypassed. If it interferes with a private match,
  that is where this project stops.

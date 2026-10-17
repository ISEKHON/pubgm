# 14 — The lobby, reached

**Status: done.** The real PUBG Mobile 0.3.2 client reaches the full lobby UI
against our own server — Start button, Squad / Auto Matching, Crew / Rank /
Inventory / Supplies, the character model, currency, Missions and Events.

No client patching. Everything is driven by `tools/tgcp_server.py` (update gate)
and `tools/lobby_server.py` (lobby), with two hostnames redirected to the host.

## The fix that finished it

After `sync_base_info` was accepted, the client entered the lobby *scene* but
its UI never built. The cause was in `data_mgr.lua:InitRoleData`, and it is the
opposite of what you would guess:

**Sending empty tables is worse than sending nothing.** Several fields are
guarded only against `nil`, with a harmless `sandbox.LogError(...)` else-branch:

```lua
if task == nil then sandbox.LogError("task can't be nil") return end
...
for taskId, data in pairs(task.list) do            -- task = {}  -> pairs(nil) -> error

if week_signup ~= nil then
    for i = 1, #week_signup.list do                -- week_signup = {} -> #nil -> error

if roleDataTb.share_award ~= nil then
    ... ShareAwardMgr.OnShareAwardInfoUpdate()     -- calls RoleInfoUI/LevelUpUI during early init
```

An empty table is **not nil**, so the guard passes and the body runs against
missing sub-fields. The error is swallowed by `DispatchPacket`'s `xpcall`, so
`InitRoleData` aborts silently — and with it the rest of `on_sync_base_info`,
including `LocalEnterLobby()`. The scene loads; the UI never does.

**Omitting `task`, `activeness`, `week_signup` and `share_award` entirely** lets
each guard take its safe no-op branch. The lobby then builds.

Rules of thumb for `roleData`, both learned the hard way:

| field | rule |
|---|---|
| `avatar` | must be a **table** (`gamegender`, `headid`, `hairid`) — `data_mgr` indexes it directly |
| `task`, `activeness`, `week_signup`, `share_award` | **omit** — nil-guarded, and the non-nil path dereferences sub-fields |
| `depot` | `{items: {}}` — iterated with `pairs`, so empty is fine |
| `wxsubscribe`, `qqsubscribe` | tables with `setflag` |
| `pic_url`, `signature`, `parachute` | strings — they get concatenated into log lines |

## Diagnosing without logs

UE4 file logging is dead on this device and `UE4CommandLine.txt` is not
honoured, so there was no Lua traceback to read. The technique that replaced it:

**use the client's own requests as progress markers.** The Lua sends specific
packets at known points, so which ones arrive says how far init got:

| marker | meaning |
|---|---|
| `get_activity_list_req`, `get_act_gather_list_req`, `bulletin_get_hashlist_req`, `get_direct_buy_*` | `DataMgr.ResetData()` ran — `InitRoleData` **started** |
| `query_gm_request`, `query_match_zone_list`, `room_info_request`, `get_all_friendlist_req`, `get_share_info_request` | these come **after** `LocalEnterLobby()` — init **completed** |

Going from 8 distinct RPCs to 23 was the signal that the lobby had opened,
before the screenshot confirmed it.

## Known cosmetic bug

The rank/score readout shows `-18,446,744,071,562,067,968` — a 2^64 wrap, so
some numeric field is being read as signed where we send it unsigned (or is
absent and reading as garbage). Likely `exp`, `segment_info` or a rank field.
Harmless for now; fix when the rank/segment data is modelled properly.

## Observed lobby RPC surface

The client asks for all of this on entering the lobby. Each is an opportunity
for the server to supply real data:

```
query_myid_request        query_gm_request          query_match_zone_list
room_info_request         get_all_friendlist_req    get_addfriend_reqlist_req
get_black_list_req        get_friend_misc_info_req  get_recent_teammate_req
get_all_offmsg_req        on_query_mail_summary     get_share_info_request
get_activity_display_req  get_active_cycle_roll     get_free_flow_req
```

`query_gm_request` is notable: the client has a **GM (game master) channel**
built in, which is the natural hook for the admin tooling in
[15-server-architecture.md](15-server-architecture.md).

# 03 — Project plan

Last updated 2026-10-17.

## Goal

A private server that the original PUBG Mobile 0.3.2 client can connect to, for personal
preservation and learning. The client already contains the gameplay; the server implements
the UE4 4.18 network protocol so the client has something to talk to.

Related docs: [00-recon.md](00-recon.md) (what the binary is), [01-protocol.md](01-protocol.md)
(protocol spec with confidence tags), [02-tooling.md](02-tooling.md) (how to reproduce).

## Scope

In scope:
- Studying the network protocol from the open-source UE4 4.18 engine and this binary.
- A server written in C under `server/`.
- Documentation of everything learned.

Out of scope:
- Rebuilding the game's C++ gameplay logic.
- Redistributing game assets, the APK or the OBB.
- Client-side protection libraries (`libtersafe.so`, `libxguardian.so`, `libtpnsSecurity.so`).
  Nothing here targets them or anyone else's installation.
- Public hosting. This is a private, own-use setup.

## Repository layout

```
pubgm/
  docs/        00-recon, 01-protocol, 02-tooling, 03-plan (this file)
  recon/       analysis outputs (symbols.txt, strings.txt, per-function notes)
  server/
    include/   headers (bitstream, packet, handshake, channel)
    src/       implementation
    tests/     unit tests against known-good byte sequences
  extracted/   unpacked artifacts (gitignored, untrusted data)
```

## Runtime environment

Rooted MSI App Player (Android 11, x86 + Houdini ARM translation) with the game installed and
running; see [`../recon/runtime-notes.md`](../recon/runtime-notes.md). Live memory reads work.
Frida/ARM hooking is **not** practical under Houdini. The client cannot reach dead official
servers, so **no handshake can be captured until our own server exists** — the handshake field
order therefore gets settled during Phase 3 bring-up, not before.

## Phases

Each phase has an exit criterion. A phase is not done until its criterion is met.

### Phase 0 — Recon (done)
- Identified UE4 4.18.1 Tencent fork, project `Survive`, ARMv7 Thumb-2.
- Found surviving `.dynsym` (28,480 symbols) and named `FNetworkVersion` data symbols.
- Mapped net stack by string anchors, found `UAENetConnection`.
- Exit: [00-recon.md](00-recon.md) written. **Met.**

### Phase 1 — Protocol map (in progress)
Static work, using radare2 targeted scans (see 02-tooling §7):
1. Locate `FNetworkVersion::GetLocalNetworkVersion` via refs to the `NetworkVersion.cpp`
   anchor. Recover the checksum inputs.
2. Locate `StatelessConnectHandlerComponent` functions via refs to their anchor. Compare
   against stock 4.18 and record differences.
3. Locate `PacketHandler` setup and record the component chain order.
4. Locate `UAENetConnection` functions and list what they override.
5. Confirm `NMT_*` control message numbering against stock 4.18.

Per-function notes go in `recon/functions/<name>.md` (address, disassembly excerpt, pseudo-C,
conclusion). 

Exit: every [UNKNOWN] in 01-protocol.md §2–§5 is either resolved or has a concrete reason
it needs runtime evidence.

### Phase 2 — Bitstream and packet core (C)
Can start in parallel with Phase 1, since this layer is stock UE4:
- `bitstream.c`: LSB-first bit reader/writer matching `FBitReader`/`FBitWriter`, including
  the termination bit.
- `packet.c`: packet framing, bunch header parsing, partial bunch reassembly.
- Unit tests in `server/tests/` built from byte sequences produced by the stock 4.18 rules.
Exit: tests pass for round-tripping bunches of every flag combination.

### Phase 3 — UDP server and handshake
- UDP listener, per-address connection table.
- Stateless connect handshake per the layout recovered in Phase 1.
Exit: the real client advances past the connect step (observed in its log or a capture).

### Phase 4 — Session / login stub
- Local replacement for the online login so the client reaches the point where it connects
  to a game server address we control.
Exit: client connects to our server address instead of an external one.

### Phase 5 — Control channel
- Hello → Login → Welcome → Join with the correct network version.
Exit: client accepts Welcome and starts loading the map.

### Phase 6 — Minimal replication
- Replicate GameState, PlayerController, PlayerState and a Pawn.
Exit: client spawns and can stand in the world.

### Phase 7 — Gameplay replication
- Movement, then additional actors, then a second client.
Exit: two clients see each other move.

## Testing approach

- **Unit tests** for every encoder/decoder, using fixed byte vectors.
- **Comparison against the original**: where a behaviour can be observed from the real client
  (logs, captures from one's own device), record the observed bytes as test vectors and check
  the server's output matches.
- Every protocol claim in 01-protocol.md keeps its confidence tag until a test or observation
  confirms it.

## Risks

| risk | effect | mitigation |
|---|---|---|
| Static analysis of a 62 MB stripped binary is slow | Phase 1 drags | targeted `/r` scans, not whole-binary analysis |
| Some values only exist at runtime | Phase 1 cannot finish statically | collect runtime evidence from own device/emulator (armeabi-v7a needed) |
| Tencent changed stock behaviour silently | server built on wrong assumptions | confidence tags, verify each before relying on it |
| Per-class replication layouts are many | Phase 6–7 are long | start with the four classes needed to spawn |

## Status

| phase | state |
|---|---|
| 0 Recon | done |
| 1 Protocol map | **largely done.** Handshake stock-shaped, 195-bit budget confirmed. NMT numbering confirmed twice, **diverges from stock** (`Join`=9). Protocol versions confirmed at runtime (2,0,2,0). Open: handshake field order (defer to Phase 3 bring-up), NMT 7/8/11/14/18, version word provenance |
| 2 Bitstream + bunch framing | done and tested |
| 3 UDP + handshake | **done.** Handshake works end to end vs a synthetic client (`docs/04-server.md`); 25-byte datagrams match the 195-bit constant. Field order still unverified against the real client |
| 4 Session / login stub | **done.** Update gate cleared (`docs/09`); lobby transport solved (`docs/11`); pak opened and the whole lobby protocol recovered as Lua source (`docs/12`). The real client now **logs in, creates a character and enters the lobby scene** against `tools/lobby_server.py` (`docs/13`) |
| 5 Lobby | **done** (`docs/14-lobby-reached.md`). The real client reaches the **full lobby UI** — Start, Squad/Auto Matching, Crew, Rank, Inventory, Supplies, Missions, Events. Fix: `task`/`activeness`/`week_signup`/`share_award` must be **omitted**, not sent empty — they are nil-guarded and their non-nil paths dereference sub-fields, silently aborting the client's init |
| 6 Real server | **next.** Scope changed from "reach the lobby" to "a server a group can play on, with admin control" — see `docs/15-server-architecture.md`. Order: SQLite store → account identity → admin CLI → LAN DNS (so players need no root) → inventory → team/matchmaking |
| 7 Match handoff | **done** (`docs/17-match-handoff.md`). The whole chain is implemented: `on_match_req` → `on_match_res` → `on_match_success` → `re_enter_game` → `EnterBattle`. Confirmed `packet_key` is **not** UE4 packet encryption (no `EncryptionComponent` in the binary), so `server/`'s stock-handshake design stands. `key`/`packet_key`/`game_id` are opaque to the client, so we define them; tickets are recorded in `match_ticket` |
| 8 Match bring-up | **in progress** (`docs/17`). Root cause of the silent failure found by **disassembling the native binding** (`Client.EnterBattle` @ `0x00b1ccd8`): `key` is `luaL_checknumber`, and we were sending a hex string, so the call raised and was swallowed by `xpcall`. With a numeric key the client now opens UDP sockets and pings a zone server — real progress. Open: it pings a hardcoded zone because `query_match_zone_list` was empty; a zone pointing at us is now advertised, and a **UDP ping responder on 17000** is likely needed next |
| 4a Pak decryption | **done** (`docs/12-pak-and-lobby-protocol.md`). The pak is XOR 0x79, not AES. `tools/pak_tool.py` extracts any entry. The game's Lua ships as **plain source**: 191 files including `logic_login.lua`/`logic_lobby.lua`, with 207 `s2c` handlers and the login contract in developer comments. Net driver config also recovered (`UAENetDriver`, no PacketHandler override — supports the [STOCK] handshake assumption) |

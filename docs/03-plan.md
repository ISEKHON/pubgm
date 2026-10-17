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
| 4 Session / login stub | **in progress. Update gate cleared** (2026-10-17): TGcp decoded (TDR TLV + AES-128-CBC with in-clear key + Thrift), `tools/tgcp_server.py` answers `kUpdateTypeNot`, real client reaches the login screen (`docs/09-tgcp-protocol.md`). Guest login boundary mapped (`docs/10-login-boundary.md`). **Lobby transport solved** (`docs/11-lobby-transport.md`): same crypto as the version RPC, different frame; `tools/lobby_server.py` completes the handshake and the real client sends its `login` RPC to us. Open: the login *reply* schema (Lua, in encrypted paks) |
| 4a Pak decryption | **done** (`docs/12-pak-and-lobby-protocol.md`). The pak is XOR 0x79, not AES. `tools/pak_tool.py` extracts any entry. The game's Lua ships as **plain source**: 191 files including `logic_login.lua`/`logic_lobby.lua`, with 207 `s2c` handlers and the login contract in developer comments. Net driver config also recovered (`UAENetDriver`, no PacketHandler override — supports the [STOCK] handshake assumption) |

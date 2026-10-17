# 01 — Network protocol spec

Target: PUBG Mobile 0.3.2 client (`libUE4.so`, UE4 **4.18.1** Tencent fork, project `Survive`).

This document is the server's specification. Everything is tagged with a confidence level,
because the whole project depends on not building on a guess:

| tag | meaning |
|---|---|
| **[CONFIRMED]** | Observed directly in this binary (see [00-recon.md](00-recon.md)) |
| **[STOCK]** | Known behaviour of open-source UE4 4.18. Highly likely but **not yet verified against this binary** |
| **[UNKNOWN]** | Must be recovered before it can be implemented |

> The single most valuable property of this target: it is **UE4 4.18**, whose networking is
> open source. Most of the protocol is therefore readable from Epic's engine source rather
> than reconstructed from ARM. Binary work is only needed for Tencent's deviations.

---

## 1. Layering

```
          ┌─────────────────────────────────────────────┐
  app     │ Actor replication / RPCs (FRepLayout)       │  §6
          ├─────────────────────────────────────────────┤
  channel │ Channels: Control(0), Actor, Voice; Bunches │  §5
          ├─────────────────────────────────────────────┤
  conn    │ UNetConnection ← UAENetConnection (Tencent) │  §4
          ├─────────────────────────────────────────────┤
  handler │ PacketHandler chain:                        │  §3
          │   StatelessConnectHandlerComponent          │
          │   + custom Tencent encryption [UNKNOWN]     │
          ├─────────────────────────────────────────────┤
  xport   │ UDP (UIpNetDriver / UIpConnection)          │  §2
          └─────────────────────────────────────────────┘
```

All layers **[CONFIRMED]** present by string anchor except the encryption component, whose
existence is inferred from crypto string density and whose identity is **[UNKNOWN]**.

---

## 2. Transport **[CONFIRMED present]**

- **UDP**, via `UIpNetDriver` / `UIpConnection` (`IpConnection.cpp` @ 0x034d4a27).
- Default UE4 server port is 7777 **[STOCK]**; the client's actual target port for this build
  is **[UNKNOWN]** and must come from a capture or from the login/matchmaking response.
- Max packet size: UE4 4.18 default `MAX_PACKET_SIZE` is 1024 bytes **[STOCK]**. Tencent may
  have raised it; **verify**.

### Bit packing **[STOCK]**
UE4 serialises with `FBitWriter`/`FBitReader`: **LSB-first within each byte**, little-endian.
Any server implementation must reproduce this exactly. A trailing "termination bit" marks the
end of real payload inside the final byte, so packet length alone does not give payload length.

---

## 3. PacketHandler chain

`PacketHandler.cpp` @ 0x0345c9b5 **[CONFIRMED]**.

**[STOCK]** mechanics: every outgoing packet passes through an ordered list of
`HandlerComponent`s; incoming packets traverse the list in reverse. Components may add bits,
and the chain reserves leading bits for its own framing.

### 3.1 Stateless connect handshake **[CONFIRMED present / [STOCK] mechanics]**

`StatelessConnectHandlerComponent.cpp` @ 0x034627a1.

Purpose: prove the client's source address is real before allocating any connection state, so
a spoofed-source flood cannot exhaust server memory. The server therefore keeps **no
per-client state** until the handshake completes — hence "stateless".

**[STOCK]** flow:

```
 client                                                   server
   │  ── initial handshake packet (zeroed cookie) ──────►   │
   │                                     generates Cookie = │
   │                                 HMAC(Secret[SecretId],  │
   │                                  Timestamp ‖ ClientAddr)│
   │  ◄──────── challenge: Timestamp + Cookie ───────────    │
   │  ── response: echoes Timestamp + Cookie ───────────►    │
   │                        server recomputes HMAC and       │
   │                        compares; no stored state needed │
   │  ◄──────── connection accepted → UNetConnection ────    │
```

The server rotates a small ring of secrets on a timer, so a cookie is only valid for a bounded
window. A `bRestartHandshake` path exists for re-handshaking an existing connection.

**[STOCK]** reference constants from UE4 4.18 — *treat as hypotheses to verify, not as truth*:
`SECRET_BYTE_SIZE` 64, `SECRET_COUNT` 2, `COOKIE_BYTE_SIZE` 20 (SHA1-sized),
`SECRET_UPDATE_TIME` 15 s (+/- 5 s variance).

#### [CONFIRMED] the handshake is stock-shaped, and we know where it lives

Located via UTF-32 log strings — full map in [`recon/net-anchors.md`](../recon/net-anchors.md):

| function (named by its own log string) | code site |
|---|---|
| `NotifyHandshakeBegin` | 0x01df8e34 |
| **`SendConnectChallenge`** | 0x01df914c |
| **`SendChallengeResponse`** | 0x01df960c |
| **`SendChallengeAck`** | 0x01df9934 |
| **`ReceivedConnectChallenge`** | 0x01df9e68 |
| **`ReceivedChallengeAck`** | 0x01df9fd0 |

The component is registered in the chain via the config string
`Engine.EngineHandlerComponentFactory(StatelessConnectHandlerComponent)` @ 0x03314b08.
The log format strings expose the field set — `ClientAddress`, `Timestamp`, `Cookie`,
`InCookie` — which matches stock UE4 4.18's cookie challenge/response exactly. This is
strong evidence Tencent did **not** redesign the handshake.

#### [CONFIRMED] constants — full analysis in [`recon/handshake.md`](../recon/handshake.md)

| value | stock 4.18 name | evidence |
|---|---|---|
| 20 bytes | `COOKIE_BYTE_SIZE` | `mov r2, 0x14` + 20-byte copy @0x01df90b4 |
| 4 bytes (float32) | `Timestamp` | `vldr s16` / `vcvt.f64.f32` @0x01df90f4 |
| 64 bytes | `SECRET_BYTE_SIZE` | `0x40`, 5 occurrences |
| **195 bits** | **`HANDSHAKE_PACKET_SIZE_BITS`** | **`0xc3`, 4 occurrences** |

#### Packet layout — [HIGH CONFIDENCE INFERENCE]

| field | bits |
|---|---:|
| `bHandshakePacket` | 1 |
| `bRestartHandshake` | 1 |
| `SecretId` | 1 |
| `Timestamp` (float32) | 32 |
| `Cookie` (20 bytes) | 160 |
| **total** | **195** |

`1 + 1 + 1 + 32 + 160 = 195 = 0xc3`. The budget is **exactly** consumed, so there is **no room
for a Tencent-added magic, version tag or extra field** — had the packet been altered, 195
would not fit. Three independently confirmed sizes plus the confirmed total make this tight.

**[UNKNOWN] — still required:**
- The *order* of those five fields on the wire. Sizes and total are confirmed; the ordering
  above is taken from stock 4.18 and the bit-write sequence was not traced. Right total with
  wrong order still fails, so this is not settled — confirm from a capture.
- The digest primitive for the cookie (20 bytes implies SHA-1, but the call was not identified).

### 3.2 Encryption component **[UNKNOWN]**

Evidence it exists: `AES` ×230, `RSA` ×366, `Encrypt` ×141, `Decrypt` ×59 in `libUE4.so`.
Evidence it is custom: **no** `AESHandlerComponent`, `BlockEncryptionHandlerComponent` or
`XORDelta` strings — stock UE4's crypto components are absent by name.

Open questions: where it sits in the chain (before/after handshake), the cipher and mode, how
the session key is established (RSA-wrapped? derived from login? fixed?), and whether it covers
the handshake packets or only post-connection traffic.

**This is the hard gate for the whole project.** Everything above §3 is unreachable until it
is understood. boringssl in the binary is for HTTPS/TLS to the login and CDN endpoints and is
very likely unrelated.

---

## 4. Connection layer

- Stock `UNetConnection` **[CONFIRMED present]** (`NetConnection.cpp` @ 0x03462513).
- **`UAENetConnection`** **[CONFIRMED present]** (`UAENetConnection.cpp` @ 0x0342a7c9) — a
  Tencent subclass in project `Survive`, module prefix `UAE`. Its overrides vs stock are
  **[UNKNOWN]** and are the prime suspect for custom crypto or protocol changes.

### Network version gate **[CONFIRMED]** — full analysis in [`recon/network-version.md`](../recon/network-version.md)

`FNetworkVersion::GetLocalNetworkVersion()` returns a lazily-cached CRC that both peers
compare; a mismatch closes the connection immediately with no useful client-side error.

| field | value |
|---|---:|
| `EngineNetworkProtocolVersion` | **2** |
| `GameNetworkProtocolVersion` | **0** |
| `EngineCompatibleNetworkProtocolVersion` | **2** |
| `GameCompatibleNetworkProtocolVersion` | **0** |

No longer provisional. The six statics are one struct reached via base **0x392FED0**, and
**no store to base+8 or base+0xc exists anywhere** — the only writes are the cached flag
(base+0) and `CachedNetworkChecksum` (base+4). The single reference site outside the unit
(0x006bfb6c) is a static initialiser operating on base+0x18 and beyond, past the version
fields. *Residual caveat:* only accesses via this exact base were enumerated.

**`EngineNetworkProtocolVersion = 2` is a Tencent pin**, not a stock 4.18 value (stock
initialises from its engine network version history, which is well above 2 by that release).
A server must present 2.

Functions: `GetEngineNetworkProtocolVersion` 0x00cfd928, `GetGameNetworkProtocolVersion`
0x00cfd93c, `GetLocalNetworkVersion` 0x00cfd950, `IsNetworkCompatible` 0x00cfdca8.

**[UNKNOWN]** the exact CRC recipe in the compute path (it makes vtable calls, mixing in
project version and possibly project name). Easiest resolution is to read the client's own
`NMT_Hello` word off the wire rather than re-deriving it.

> Bring-up tip: if the client logs `NotifyControlMessage: Client connecting with invalid
> version. LocalNetworkVersion: %i, RemoteNetworkVersion: %i` (string 0x0338327c, site
> 0x020d0b28), the server's version word is wrong — and that line reports both numbers.

---

## 5. Channels and bunches **[CONFIRMED present / [STOCK] mechanics]**

`DataChannel.cpp` @ 0x03460a78.

**[STOCK]**: a packet carries one or more *bunches*. Each bunch is addressed to a channel
index; channel 0 is always the **control channel**. Bunches carry flags for
reliable/open/close/partial, and large payloads are split into partial bunches and reassembled.
`CVarNetPartialBunchReliableThreshold` is a named symbol in this binary, confirming the
partial-bunch machinery is present.

### Control channel messages **[STOCK]**

After the handshake, connection setup is a conversation of `NMT_*` control messages. The
canonical early sequence is:

| direction | message | purpose |
|---|---|---|
| C → S | `Hello` | announces engine/network version |
| S → C | `Upgrade` *or* `Challenge` | version refused, or a challenge to answer |
| C → S | `Login` | challenge response + join URL / options |
| S → C | `Welcome` | accepted: map/game-mode to load |
| C → S | `Join` | client has loaded, ready to spawn |
| S → C | *(actor replication begins)* | §6 |
| S → C | `Failure` | rejection at any point |

**[CONFIRMED]** all nineteen control-message **names** are present as UTF-32 strings, and one
function at `0x007c7ac0`–`0x007c7ba4` references every one of them — the
`FNetControlMessageInfo` name registration. Present: Hello, Welcome, Upgrade, Challenge,
Login, Netspeed, Failure, Join, JoinSplit, Skip, Abort, PCSwap, ActorChannelFailure,
DebugText, BeaconAssignGUID, SecurityViolation, BeaconWelcome, BeaconJoin, BeaconNetGUIDAck.
Absent (so likely not built, or inlined elsewhere): `GameSpecific`, `EncryptionAck`,
`NetGUIDAssign`. Full table in [`recon/net-anchors.md`](../recon/net-anchors.md).

### [CONFIRMED] the numbering is NOT stock — full table in [`recon/control-messages.md`](../recon/control-messages.md)

The name table is a `const TCHAR*` array in `.bss` at **0x3d01980**, populated by the function
at `0x007c7a00`–`0x007c7bf8`. Reading the store offset of each name pointer (index = offset/4)
gives the real `NMT_*` values. Stride 4 is confirmed twice over: indices 0–6 come out
contiguous and stock-matching, and the four `Beacon*` entries land exactly on 25–28 across a
large gap.

| | |
|---|---|
| Stock-matching | `Hello` 0, `Welcome` 1, `Upgrade` 2, `Challenge` 3, `Netspeed` 4, `Login` 5, `Failure` 6, `BeaconWelcome` 25, `BeaconJoin` 26, `BeaconAssignGUID` 27, `BeaconNetGUIDAck` 28 |
| **Diverging** | **`Join` 9** (stock 7), **`JoinSplit` 10** (8), **`Skip` 12** (9), **`Abort` 13** (10), **`PCSwap` 15** (11), **`ActorChannelFailure` 16** (12), **`DebugText` 17** (13), **`SecurityViolation` 19** (15) |
| Unassigned | 7, 8, 11, 14, 18, 20–24 |

So the connection-critical messages (`Hello`, `Challenge`, `Login`, `Welcome`, `Failure`) are
all at stock values, but **`Join` — needed to finish the login flow — is 9, not 7.** The shift
is *not* uniform (+2, then +3, then +4), so a single-offset correction would be wrong.

**Confirmed a second time, from the consumer side.** The dispatch switch in
`UWorld::NotifyControlMessage` (prologue 0x020cf744) biases by 4 (`sub r0, r7, 4`), bounds at
13, and indexes a jump table at **0x020cf898** where `target = entry + 0x020cf898`. Its
non-default cases are {4, 5, 9, 10, 15, 17}, which under the recovered table are exactly
`Netspeed, Login, Join, JoinSplit, PCSwap, DebugText` — precisely the set this function is
meant to handle. Under stock numbering the same set would be
`Netspeed, Login, Skip, Abort, SecurityViolation, EncryptionAck`, which is incoherent here and
would omit `Join` altogether. Independently, the `Join request: %s` log site (0x020cfd80) falls
strictly inside case 9's body `[0x020cfd28, 0x020cfdc4)`.

So **`Join = 9` is settled**, and a server using stock numbering could never complete a login.

**[UNKNOWN]** what occupies 7, 8, 11, 14, 18; nothing names them. A reading consistent with
every offset is that Tencent inserted four messages at 7/8/11/14 and left
`NetGUIDAssign`/`GameSpecific`/`EncryptionAck` unnamed at 18/20/21 — inference, not established.

`NMT_Hello` (0) is handled on an earlier path, not via this table — see the version-mismatch
log at string 0x0338327c / code site 0x020d0b28, which is also where the provisional
`FNetworkVersion` values (§4) should be resolved.

---

## 6. Replication **[CONFIRMED present / [STOCK] mechanics]**

- `FRepLayout`-driven property replication over actor channels; `PackageMap` (`LogNetPackageMap`
  is a named symbol) maps object references to network GUIDs.
- To make a client spawn into a world the server must replicate at minimum: `GameState`,
  `PlayerController`, `PlayerState`, and a `Pawn`.
- Each replicated class's **property order and types** (`FRepLayout`) are **[UNKNOWN]** and
  must be recovered per class. This is the laborious but tractable bulk of later phases.

---

## 7. Implementation order

Strictly gated — each step is unreachable until the previous is understood:

1. **Network version** — confirm the checksum recipe and values (§4). Cheapest, and a wrong
   value blocks everything with no useful error.
2. **Handshake bit layout** — recover exactly (§3.1).
3. **Encryption** — the hard gate (§3.2).
4. **Control channel** — confirm `NMT_*` numbering, implement Hello→Welcome→Join (§5).
5. **Minimal replication** — spawn a pawn (§6).

## 8. Recommended next action

Static analysis of a 62 MB stripped Thumb-2 binary is slow and cannot reveal runtime-derived
keys. A **packet capture of the real client connecting** (emulator or device, project is 32-bit
so the emulator must support armeabi-v7a) would anchor §3.1, §4 and §5 against real bytes in a
fraction of the time, and is the only practical way to resolve §3.2's key establishment.
Recommend running capture and static analysis in parallel, with capture leading.

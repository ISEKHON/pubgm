# Networking anchors in libUE4.so

Recovered with `tools/find_str_refs.py` (ARM-mode PC-relative resolver).
All addresses are vaddr, which equals the file offset for `.text` and `.rodata`
in this binary.

Reproduce:

```bash
python -I tools/find_str_refs.py extracted/apk/lib/armeabi-v7a/libUE4.so <hex-addr>...
```

## Important: strings are UTF-32LE

`TCHAR` is 4-byte `wchar_t` on this Android build, so every engine string is
**UTF-32LE**. An ASCII string scan finds only narrow `__FILE__` paths, which in
this shipping build are **dead data** - no code references them at all (four
separate reference-resolution strategies found zero refs to them). Use
`recon/strings_utf32.txt`, not `recon/strings.txt`, for engine strings.

## StatelessConnectHandlerComponent — handshake

The component lives around `0x01df8b00`-`0x01dfa900`. Log strings name the
functions, confirming the handshake is **stock-shaped** for UE4 4.18:

| code site | string at target | implies function |
|---|---|---|
| 0x01df8b04 | `StatelessConnectHandlerComponent` | ctor / component name |
| 0x01df8c88 | `---NotifyHandshakeBegin Mode not Client` | `NotifyHandshakeBegin` |
| 0x01df8e34 | `---NotifyHandshakeBegin Timestamp: %f` | `NotifyHandshakeBegin` |
| 0x01df8ec0 | `Tried to send handshake connect packet without a server connection.` | `NotifyHandshakeBegin` |
| **0x01df914c** | `SendConnectChallenge. ClientAddress: %s, Timestamp: %f, Cookie...` | **`SendConnectChallenge`** |
| 0x01df9538 | `Tried to send handshake response packet without a server connection.` | `SendChallengeResponse` |
| **0x01df960c** | `SendChallengeResponse. Timestamp: %f, Cookie: %s` | **`SendChallengeResponse`** |
| **0x01df9934** | `SendChallengeAck. ClientAddress: %s, InCookie: %s` | **`SendChallengeAck`** |
| **0x01df9e68** | `Incoming: ReceivedConnectChallenge.` | **`ReceivedConnectChallenge`** |
| **0x01df9fd0** | `Incoming: ReceivedChallengeAck.` | **`ReceivedChallengeAck`** |
| 0x01dfa7bc | `Initial handshake packet timeout - resending.` | resend timer |
| 0x01dfa8f8 | `Challenge response packet timeout - resending.` | resend timer |

The log fields (`ClientAddress`, `Timestamp`, `Cookie`, `InCookie`) match stock
UE4 4.18's cookie challenge/response. This is strong evidence Tencent did not
redesign the handshake.

**Still unknown:** the exact bit layout of the handshake packet. Recover it by
disassembling the `Send*` functions above - they call `BuildHandshakePacket`.

Registration string (confirms the component is in the PacketHandler chain):
`Engine.EngineHandlerComponentFactory(StatelessConnectHandlerComponent)` @ 0x03314b08.

## Control-message name table

One function at `0x007c7ac0`-`0x007c7ba4` references every control-message name,
i.e. the `FNetControlMessageInfo` name registration.

Order **by code address**:

| # | code site | name |
|---:|---|---|
| 1 | 0x007c7ac0 | Hello |
| 2 | 0x007c7ad0 | Welcome |
| 3 | 0x007c7ae0 | Upgrade |
| 4 | 0x007c7ae8 | Challenge |
| 5 | 0x007c7b00 | Login |
| 6 | 0x007c7b10 | Netspeed |
| 7 | 0x007c7b24 | Failure |
| 8 | 0x007c7b2c | Join |
| 9 | 0x007c7b38 | JoinSplit |
| 10 | 0x007c7b48 | Skip |
| 11 | 0x007c7b54 | Abort |
| 12 | 0x007c7b60 | PCSwap |
| 13 | 0x007c7b6c | ActorChannelFailure |
| 14 | 0x007c7b7c | DebugText |
| 15 | 0x007c7b84 | BeaconAssignGUID |
| 16 | 0x007c7b94 | SecurityViolation |
| 17 | 0x007c7b9c | BeaconWelcome |
| 18 | 0x007c7ba0 | BeaconJoin |
| 19 | 0x007c7ba4 | BeaconNetGUIDAck |

> **Do not read these as enum values.** This is the order the compiler scheduled
> the address computations, which need not match argument order. Two positions
> deviate from stock UE4 4.18 (which has Netspeed=4 before Login=5, and
> NetGUIDAssign at 14): here Login precedes Netspeed, and `BeaconAssignGUID`
> appears at position 15. Both are most likely instruction scheduling, not a
> genuine reordering - but **the numbering is not yet established.**
>
> To get the real indices, disassemble `0x007c7ac0`+ and read the index each
> name pointer is stored at. Until then the `NMT_*` numbering stays [UNKNOWN].

Absent from this function (so likely absent from the build or inlined
elsewhere): `GameSpecific`, `EncryptionAck`, `NetGUIDAssign`.

## Encryption

| string | addr | code sites |
|---|---|---|
| `Encryption failure` | 0x033834e4 | — |
| `Encryption ack failure` | 0x034e1e98 | — |
| `Connection encryption state failure` | 0x034e1ef8 | 0x01e8d5fc, 0x01e8d658 |

The `0x01e8d5xx` region is a separate cluster from the handshake. The presence of
"Encryption ack" wording suggests an `EncryptionAck`-style control message path.
Session-key establishment remains **[UNKNOWN]** and is not statically
recoverable - keys exist only at runtime.

## Other useful anchors found

CVar/registration strings near the channel code: `net.ProcessQueuedBunchesMillisecondLimit`,
`net.InstantReplayProcessQueuedBunchesMillisecondLimit`, `net.PartialBunchReliableThreshold`,
`net.RelinkMappedReferences`, `net.ListNetGUIDs`, `net.ListActorChannels`.
These confirm the partial-bunch and NetGUID machinery modelled in `server/src/packet.c`.

# FNetworkVersion — the connection version gate

**Headline: the protocol version values are confirmed, and
`EngineNetworkProtocolVersion = 2` is a Tencent pin, not a stock value.**
A server must present matching values or the client refuses the connection
outright, with no useful error.

## The statics are one struct accessed via a base register

All six `FNetworkVersion` statics are adjacent, so the compiler materialises
**one base address, 0x392FED0**, and reaches the rest by offset. This is why an
xref query for the individual addresses returns zero hits and only the base has
references — a trap worth remembering for any other adjacent statics.

| offset from base | vaddr | symbol |
|---|---|---|
| +0x00 | 0x392FED0 | `bHasCachedNetworkChecksum` (byte) |
| +0x04 | 0x392FED4 | `CachedNetworkChecksum` |
| +0x08 | 0x392FED8 | `EngineNetworkProtocolVersion` |
| +0x0c | 0x392FEDC | `GameNetworkProtocolVersion` |
| +0x10 | 0x392FEE0 | `EngineCompatibleNetworkProtocolVersion` |
| +0x14 | 0x392FEE4 | `GameCompatibleNetworkProtocolVersion` |

Note `vaddr = paddr + 0x1000` for this `.data` region; read file bytes at the paddr.

## Functions recovered

Unit spans `0x00cfd900`–`0x00cfdd80`.

| address | function | evidence |
|---|---|---|
| 0x00cfd910 | `GetProjectVersion` (length) | base 0x3B97F40, `bfc r0,31,1` (FString `ArrayNum`) |
| **0x00cfd928** | **`GetEngineNetworkProtocolVersion`** | `ldr r0,[base, 8]; bx lr` |
| **0x00cfd93c** | **`GetGameNetworkProtocolVersion`** | `ldr r0,[base, 0xc]; bx lr` |
| **0x00cfd950** | **`GetLocalNetworkVersion`** | reads cached flag, lazily computes, caches |
| **0x00cfdca8** | **`IsNetworkCompatible`** | called from the `NMT_Hello` handler |

`GetLocalNetworkVersion` is a lazily-cached CRC:

```
0x00cfd960   ldrb r1, [pc, r1]      ; byte at base+0  = bHasCachedNetworkChecksum
0x00cfd964   cmp r1, 0
0x00cfd968   beq 0xcfd97c           ; not cached -> compute
0x00cfd974   ldr r4, [r0, 4]        ; cached -> return CachedNetworkChecksum
...
0x00cfd9fc   str r4, [r1, 4]        ; compute path stores into base+4 only
```

## Values — [CONFIRMED]

Read as link-time initialisers from `.data`, and confirmed not to be overwritten:

| field | value |
|---|---:|
| `EngineNetworkProtocolVersion` | **2** |
| `GameNetworkProtocolVersion` | **0** |
| `EngineCompatibleNetworkProtocolVersion` | **2** |
| `GameCompatibleNetworkProtocolVersion` | **0** |
| `CachedNetworkChecksum` | 0 (computed at runtime) |
| `bHasCachedNetworkChecksum` | 0 |

### Why these are now confirmed rather than provisional

The earlier worry was that `.init_array` constructors might overwrite the statics
at load, making the file values meaningless. Two checks retire that:

1. **No store to base+8 or base+0xc exists anywhere in the unit.** The only
   writes are to base+0 (cached flag) and base+4 (`CachedNetworkChecksum`).
2. **The one reference site outside the unit** (0x006bfb6c) is a static
   initialiser — `__cxa_atexit` appears immediately before it — and it uses the
   same base 0x392FED0 but operates on **base+0x18 and beyond** (FString
   constructors), i.e. past the version fields entirely.

**Caveat retired — confirmed at runtime.** A live read of this struct in the
running client (twice, in two processes with different ASLR bases) returns
exactly `2, 0, 2, 0` for the four version fields. See
[`runtime-notes.md`](runtime-notes.md). The `.init_array` worry is settled.

### `EngineNetworkProtocolVersion = 2` is a deliberate pin

Stock UE4 4.18 initialises this from the latest entry of its engine network
version history, which is well above 2 by that release. A value of 2 is
therefore **not** what a stock 4.18 build would carry — Tencent pinned it. Any
server must present 2, not the stock value.

This matters because the gate is all-or-nothing: `IsNetworkCompatible` is called
from the `NMT_Hello` handler and a mismatch closes the connection immediately.

## Where the check happens

In `UWorld::NotifyControlMessage`'s `NMT_Hello` path (not in the jump table —
see `recon/control-messages.md`):

```
0x020d0a94   ldr r4, [sp, 0x1a0]    ; LocalNetworkVersion
0x020d0a98   ldr r1, [sp, 0x44c]    ; RemoteNetworkVersion, 4 bytes from the bunch
0x020d0aa0   bl  0xcfdca8           ; IsNetworkCompatible(local, remote)
0x020d0aa4   cmp r0, 0
0x020d0aa8   beq 0x020d0adc         ; incompatible -> mismatch log, then close
```

Failure logs `NotifyControlMessage: Client connecting with invalid version.
LocalNetworkVersion: %i, RemoteNetworkVersion: %i` (string 0x0338327c, site
0x020d0b28). **This is the single most useful log line for bringing up a
server** — if the client prints it, the server's version word is wrong, and the
log reports both numbers.

## Still open

- **The 32-bit version word itself.** The recipe is known: format string
  `%s %s, NetCL: %d, EngineNetVer: %d, GameNetVer: %d` (UTF-32 @ file offset
  `0x031092b8`, referenced once from `0x00cfdac0` inside `GetLocalNetworkVersion`),
  fed to `FCrc::StrCrc32`. `ProjectVersion` is confirmed live as `"1.0.0.0"`.
  But a live read of `CachedNetworkChecksum` gives **0xF6035FB3**, which an
  exhaustive search (NetCL 0..4.3M x 7 project-name candidates) could **not**
  reproduce from that recipe — suggesting Tencent overrides the computation.
  Treat `0xF6035FB3` as the first value to try; the client's mismatch log reports
  the correct one. Details and caveats in [`runtime-notes.md`](runtime-notes.md).
- Whether `IsNetworkCompatible` compares the plain or the "Compatible" pair.

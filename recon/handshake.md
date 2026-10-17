# StatelessConnect handshake

**Headline: the handshake is stock UE4 4.18, and the packet is 195 bits with no
room for a Tencent addition.** This is the best possible result for the project —
the open-source 4.18 implementation is a usable spec here.

Code region: `0x01df8b00`–`0x01dfa900`.
Raw evidence: `recon/disasm/handshake-0x01df8b00.asm` (1900 instructions).

Reproduce:

```bash
F=extracted/apk/lib/armeabi-v7a/libUE4.so
radare2 -e scr.color=false -qc "e asm.arch=arm; e asm.bits=32; s 0x01df8b00; pd 1900" "$F"
```

## Functions — [CONFIRMED]

Each is named by its own log format string (see `recon/net-anchors.md`):

| function | log site |
|---|---|
| `NotifyHandshakeBegin` | 0x01df8e34 |
| `SendConnectChallenge` | 0x01df914c |
| `SendChallengeResponse` | 0x01df960c |
| `SendChallengeAck` | 0x01df9934 |
| `ReceivedConnectChallenge` | 0x01df9e68 |
| `ReceivedChallengeAck` | 0x01df9fd0 |

This is exactly stock UE4 4.18's function set. Registered into the PacketHandler
chain via `Engine.EngineHandlerComponentFactory(StatelessConnectHandlerComponent)`
@ 0x03314b08.

## Constants — [CONFIRMED]

Immediate-frequency sweep over the region:

| value | occurrences | stock 4.18 name |
|---|---:|---|
| `0x14` = 20 | 10 | `COOKIE_BYTE_SIZE` |
| `0x40` = 64 | 5 | `SECRET_BYTE_SIZE` |
| **`0xc3` = 195** | 4 | **`HANDSHAKE_PACKET_SIZE_BITS`** |
| `0x3f800000` | 2 | float `1.0f` |

Direct corroboration in `SendConnectChallenge`:

```
0x01df90ac   add r0, sp, 0x48
0x01df90b0   sub r1, fp, 0x38
0x01df90b4   mov r2, 0x14          ; 20-byte cookie copy
0x01df90c0   bl  0xd37344
...
0x01df90f4   vldr s16, [sp, 0x44]  ; Timestamp is a 4-byte float
0x01df912c   vcvt.f64.f32 d16, s16 ; widened only for the %f log
```

So: **cookie = 20 bytes (SHA1-sized), timestamp = float32, secret = 64 bytes.**
All three match stock 4.18 exactly.

## Packet layout — [HIGH CONFIDENCE INFERENCE]

The 195-bit budget is fully accounted for by the stock field set, with nothing
left over:

| field | bits |
|---|---:|
| `bHandshakePacket` | 1 |
| `bRestartHandshake` | 1 |
| `SecretId` | 1 |
| `Timestamp` (float32) | 32 |
| `Cookie` (20 bytes) | 160 |
| **total** | **195** |

`1 + 1 + 1 + 32 + 160 = 195 = 0xc3`, and 195 appears as an immediate in this
region four times.

**Why this is strong:** the arithmetic is tight. Three independently confirmed
sizes (20-byte cookie, 32-bit float timestamp, 64-byte secret) combine with the
confirmed 195-bit total to leave **exactly zero spare bits**. There is therefore
no room for a Tencent-added magic number, version tag or extra field in the
handshake packet. Had Tencent altered the packet, 195 would not fit.

Stock also defines `RESTART_HANDSHAKE_PACKET_SIZE_BITS = 2`
(`bHandshakePacket` + `bRestartHandshake` only), consistent with the above.

**What is still not established:** the *order* of the five fields on the wire.
The sizes and the total are confirmed; the ordering above is taken from stock
4.18. The bit-level write sequence was not traced instruction by instruction, so
a client capture (or disassembling `BuildHandshakePacket`'s bit writes) is needed
to be certain. Getting the order wrong while the total is right would still fail,
so do not treat the ordering as settled.

Also unestablished: the digest primitive used to build the cookie. A 20-byte
cookie implies SHA-1, consistent with stock, but the call was not identified.

## Flow (stock 4.18, consistent with the function set above)

```
 client                                                   server
   │  ── handshake packet, zeroed cookie ───────────────►   │
   │                    SendConnectChallenge:               │
   │                    Cookie = HMAC(Secret[SecretId],      │
   │                                  Timestamp, ClientAddr) │
   │  ◄──── challenge: Timestamp + Cookie ──────────────     │
   │  ── SendChallengeResponse: echo Timestamp+Cookie ──►    │
   │               ReceivedChallengeAck: recompute &         │
   │               compare; no stored state required         │
   │  ◄──── SendChallengeAck → UNetConnection created ──     │
```

The server keeps no per-client state until the cookie verifies, which is the
point of the design: a spoofed source address cannot cause an allocation.

## Consequence for the server

Phase 3 can implement this directly from the open-source 4.18 component, using
the confirmed constants (20 / 64 / 195). The remaining risks are field order
(above) and the separate encryption component, which is **not** part of this
195-bit packet and whose session keys exist only at runtime.

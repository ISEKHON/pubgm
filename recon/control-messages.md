# Control-message numbering (`NMT_*`)

**Headline: the numbering diverges from stock UE4 4.18 from index 7 onward.
`Join` is 9 here, not 7.** A server built on stock numbering would fail, and
would fail silently — the client would simply reject or misread messages.

## How this was recovered

The name table is a `const TCHAR*` array in `.bss` at **0x3d01980**
(`.bss` addr 0x3b09880, size 0x257250), populated at runtime by the function
around `0x007c7a00`–`0x007c7bf8`.

The base is computed at:

```
0x007c7ae4   ldr r4, [0x007c8484]     ; literal 0x3539e84
0x007c7af4   add r4, pc, r4           ; r4 = 0x3539e84 + 0x007c7af4 + 8 = 0x3d01980
```

Each name is then stored at a fixed byte offset from `r4`. Index = offset / 4.

Two independent facts confirm stride 4 and that the offsets really are the
`NMT_*` values:
1. Indices 0–6 come out contiguous and match stock UE4 4.18 exactly.
2. The four `Beacon*` entries land on 25, 26, 27, 28 — matching stock exactly,
   across a large gap, which a wrong stride could not reproduce.

Reproduce:

```bash
F=extracted/apk/lib/armeabi-v7a/libUE4.so
radare2 -e scr.color=false -qc "e asm.arch=arm; e asm.bits=32; s 0x007c7a00; pd 230" "$F" \
  | grep -E "str|stm|vst|add (r4|ip)"
```

Only stores between `add r4, pc, r4` (0x007c7af4) and the *next* `add r4, pc, r1`
(0x007c7bf8) belong to this table; after that `r4` is re-based to a different array.

## Recovered table — [CONFIRMED]

| index | offset | name | store site | stock 4.18 | match |
|---:|---|---|---|---:|:--:|
| 0 | 0x00 | `Hello` | vst1 @0x007c7b18 | 0 | yes |
| 1 | 0x04 | `Welcome` | vst1 @0x007c7b18 | 1 | yes |
| 2 | 0x08 | `Upgrade` | vst1 @0x007c7b18 | 2 | yes |
| 3 | 0x0c | `Challenge` | vst1 @0x007c7b18 | 3 | yes |
| 4 | 0x10 | `Netspeed` | 0x007c7b1c | 4 | yes |
| 5 | 0x14 | `Login` | 0x007c7b20 | 5 | yes |
| 6 | 0x18 | `Failure` | 0x007c7b28 | 6 | yes |
| **7** | — | *unassigned* | — | `Join` | **no** |
| **8** | — | *unassigned* | — | `JoinSplit` | **no** |
| **9** | 0x24 | `Join` | 0x007c7b34 | `Skip` | **no** |
| **10** | 0x28 | `JoinSplit` | 0x007c7b44 | `Abort` | **no** |
| **11** | — | *unassigned* | — | `PCSwap` | **no** |
| **12** | 0x30 | `Skip` | 0x007c7b50 | `ActorChannelFailure` | **no** |
| **13** | 0x34 | `Abort` | 0x007c7b5c | `DebugText` | **no** |
| **14** | — | *unassigned* | — | `NetGUIDAssign` | **no** |
| **15** | 0x3c | `PCSwap` | 0x007c7b68 | `SecurityViolation` | **no** |
| **16** | 0x40 | `ActorChannelFailure` | 0x007c7b78 | `GameSpecific` | **no** |
| **17** | 0x44 | `DebugText` | 0x007c7b90 | `EncryptionAck` | **no** |
| **18** | — | *unassigned* | — | — | — |
| **19** | 0x4c | `SecurityViolation` | 0x007c7b98 | — | **no** |
| 20–24 | — | *unassigned* | — | unused in stock too | — |
| 25 | 0x64 | `BeaconWelcome` | stm @0x007c7ba8 | 25 | yes |
| 26 | 0x68 | `BeaconJoin` | stm @0x007c7ba8 | 26 | yes |
| 27 | 0x6c | `BeaconAssignGUID` | stm @0x007c7ba8 | 27 | yes |
| 28 | 0x70 | `BeaconNetGUIDAck` | stm @0x007c7ba8 | 28 | yes |

The vectorised stores need care: `vst1.32 {d16,d17},[r2]!` writes four pointers
at once (offsets 0x00–0x0c), and the lanes are filled out of order by `vmov.32`
earlier in the function. The `stm ip,{r1,r2,r3,r7}` at 0x007c7ba8 likewise writes
four pointers at 0x64–0x70, and `r3` there was loaded far earlier (0x007c7b84),
which is why `BeaconAssignGUID` appears out of sequence in a naive
code-address-ordered listing.

## What occupies 7, 8, 11, 14, 18 — [HYPOTHESIS, not confirmed]

Nothing in this function names them. One reading fits all the offsets: four
Tencent messages were inserted at **7, 8, 11, 14**, displacing the stock ones:

| stock | shift | here |
|---|---:|---:|
| `Join` 7 | +2 | 9 |
| `JoinSplit` 8 | +2 | 10 |
| `Skip` 9 | +3 | 12 |
| `Abort` 10 | +3 | 13 |
| `PCSwap` 11 | +4 | 15 |
| `ActorChannelFailure` 12 | +4 | 16 |
| `DebugText` 13 | +4 | 17 |
| `SecurityViolation` 15 | +4 | 19 |

Under this reading the three stock names absent here land on the remaining
gaps — `NetGUIDAssign` → 18, `GameSpecific` → 20, `EncryptionAck` → 21 — with
their names simply never registered. The shift is **not uniform** (+2, then +3,
then +4), which is why a single-offset guess would be wrong.

This reconstruction is consistent with every observed offset, but it is
inference. **The 19 confirmed index→name pairs above are the hard data; the
contents of 7, 8, 11, 14, 18 are not established.**

## Consumer-side confirmation — [CONFIRMED]

The numbering above was read from the *producer* side (name registration). It is
now independently confirmed from the *consumer* side: the dispatch switch in
`UWorld::NotifyControlMessage`.

Dispatch head (function prologue at 0x020cf744):

```
0x020cf868   mov r0, sl            ; Connection
0x020cf86c   mov r1, r7            ; r7 = MessageType parameter
0x020cf870   bl  0x1dd18c8         ; FNetControlMessageInfo::IsRegistered(MessageType)
0x020cf874   cmp r0, 0
0x020cf878   beq 0x020cf920        ; unregistered -> error path
0x020cf87c   sub r0, r7, 4         ; bias: switch covers MessageType 4..17
0x020cf880   cmp r0, 0xd
0x020cf884   bhi 0x020cfc10        ; out of range -> default
0x020cf888   add r1, pc, 8         ; r1 = 0x020cf898  (table base)
0x020cf88c   lsl r0, r0, 2
0x020cf890   ldr r0, [r0, r1]      ; offset from table
0x020cf894   add pc, r0, r1        ; target = offset + 0x020cf898
```

Jump table at **0x020cf898**, 14 entries, `target = entry + 0x020cf898`:

| MessageType | entry | handler | recovered name |
|---:|---|---|---|
| 4 | 0x038 | 0x020cf8d0 | `Netspeed` |
| 5 | 0x3dc | 0x020cfc74 | `Login` |
| 6, 7, 8 | 0x1360 | 0x020d0bf8 | *default* |
| **9** | 0x490 | **0x020cfd28** | **`Join`** |
| 10 | 0x52c | 0x020cfdc4 | `JoinSplit` |
| 11, 12, 13, 14 | 0x1360 | 0x020d0bf8 | *default* |
| 15 | 0x990 | 0x020d0228 | `PCSwap` |
| 16 | 0x1360 | 0x020d0bf8 | *default* |
| 17 | 0x9e0 | 0x020d0278 | `DebugText` |

### Two independent proofs that the recovered numbering is right

**1. Log-site containment.** The `Join request: %s` log site is at 0x020cfd80,
which falls strictly inside case 9's body `[0x020cfd28, 0x020cfdc4)`. So
MessageType 9 *is* `Join`.

**2. The handled set is only coherent under the recovered numbering.** The
non-default cases are {4, 5, 9, 10, 15, 17}. Mapped through each table:

| | set of names |
|---|---|
| **Recovered** | **`Netspeed`, `Login`, `Join`, `JoinSplit`, `PCSwap`, `DebugText`** |
| Stock 4.18 | `Netspeed`, `Login`, `Skip`, `Abort`, `SecurityViolation`, `EncryptionAck` |

The recovered set is exactly what `UWorld::NotifyControlMessage` is supposed to
handle. The stock mapping is incoherent for this function — it would handle
`SecurityViolation` and `EncryptionAck` here while omitting `Join`, `JoinSplit`,
`PCSwap` and `DebugText` entirely, and the server could never process a join.

`Abort` (13) and `Skip` (12) routing to default is consistent: they are no-ops in
stock too.

**Conclusion: the numbering is settled.** `Join = 9`. A server using stock
numbering would send/expect the wrong type byte and the login flow would never
complete.

## Still open

- What occupies 7, 8, 11, 14, 18 (the hypothesis above is unverified).
- `NMT_Hello` (0) is not in this jump table; it is handled on an earlier path —
  note the `cmp r7, 0x12` / `cmp r7, 0x11` / `cmp r7, 6` chain at
  0x020cf788-0x020cf79c, and the version-mismatch log
  `NotifyControlMessage: Client connecting with invalid version. LocalNetworkVersion: %i, RemoteNetworkVersion: %i`
  (string 0x0338327c, code site 0x020d0b28). That site is the place to resolve
  the still-provisional `FNetworkVersion` values.

# Runtime analysis — MSI App Player

Live-process findings from the user's own emulator running their own copy.
Complements the static work; see `recon/network-version.md`.

## Environment

| | |
|---|---|
| Emulator | MSI App Player (BlueStacks-based; host process `HD-Player`) |
| Android | **11** |
| Host ABI | x86; `ro.product.cpu.abilist = x86,armeabi-v7a,armeabi` |
| ARM support | **`ro.dalvik.vm.isa.arm = x86` → ARM runs under Houdini translation** |
| Root | **yes, via `su`** (`su -c id` → uid=0). `adb root` reports success but `id` stays uid 2000 |
| ADB | `adb connect 127.0.0.1:5555`; also appears as `emulator-5554` |
| `tcpdump` | present at `/system/bin/tcpdump` |
| Also present | `od`, `xxd`, `hexdump`, `dd`, `busybox` |

Game: `com.tencent.ig` **0.3.2** (versionCode 3212), `primaryCpuAbi=armeabi-v7a`, uid **10128**.
So the emulator runs exactly the ARM `libUE4.so` analysed statically.

### Houdini consequence
Because ARM code is translated to x86, **Frida/native hooking of `libUE4.so` ARM addresses is
not practical here**. Runtime work is limited to memory reads, logcat and packet capture.
Plan accordingly: do not budget time for ARM function hooks on this emulator.

### adb quirks worth knowing
The shell is intermittently unavailable: direct binaries (`getprop`, `dumpsys`) succeed while
shell-requiring commands return `error: closed`, and `adb root` restarts adbd and drops the
connection (reconnect with `adb connect 127.0.0.1:5555`). If port 5555 stops LISTENING, the
emulator's ADB toggle has switched off.

## Reading live memory

`libUE4.so` is **ASLR-relocated** — the base differs every launch (observed `0x03060000`,
then `0xade89000`). Always resolve it from `/proc/<pid>/maps`:

```bash
ADB=.../adb; D="-s emulator-5554"
PID=$("$ADB" $D shell pidof com.tencent.ig | tr -d '\r' | awk '{print $1}')
BASE=$("$ADB" $D shell "su -c 'grep -m1 libUE4 /proc/$PID/maps'" | tr -d '\r' | cut -d- -f1)
T=$(( 0x$BASE + 0x0392FED0 ))          # runtime addr = load_base + link vaddr
"$ADB" $D shell "su -c 'dd if=/proc/$PID/mem bs=1 skip=$T count=24 2>/dev/null | xxd'"
```

Note `runtime = load_base + link_vaddr`, using the **vaddr** (not the paddr). For this
binary's `.data`, `vaddr = paddr + 0x1000`; the UTF-32 string table in
`recon/strings_utf32.txt` lists **file offsets**, so add 0x1000 before using one as a vaddr
in `.data`.

## FNetworkVersion at runtime — [CONFIRMED]

Read at link vaddr `0x0392FED0`, twice, in two processes with different ASLR bases:

```
00000000: 0000 0000 b35f 03f6 0200 0000 0000 0000
00000010: 0200 0000 0000 0000
```

| offset | field | value |
|---|---|---|
| +0x00 | `bHasCachedNetworkChecksum` | **0** |
| +0x04 | `CachedNetworkChecksum` | **0xF6035FB3** |
| +0x08 | `EngineNetworkProtocolVersion` | **2** |
| +0x0c | `GameNetworkProtocolVersion` | **0** |
| +0x10 | `EngineCompatibleNetworkProtocolVersion` | **2** |
| +0x14 | `GameCompatibleNetworkProtocolVersion` | **0** |

**The four protocol versions are now confirmed at runtime**, matching the static `.data` read
exactly. This definitively retires the earlier worry that `.init_array` might overwrite them.

Also read live: `FNetworkVersion::ProjectVersion` (FString at link vaddr `0x03b97eb0`) =
ptr `0x9b1fd020`, len 8 → **`"1.0.0.0"`** (7 chars + null).

## CachedNetworkChecksum = 0xF6035FB3 — [STRONG CANDIDATE, provenance unconfirmed]

What is established:
- **Deterministic**: identical across a force-stop/restart with a different ASLR base, so it
  is not a stale pointer or uninitialised garbage (either would move).
- **Written at runtime**: the file initialiser at that offset is `0`.
- It sits at exactly the `CachedNetworkChecksum` offset, and the neighbouring fields read
  their expected values, so the address mapping is certainly right.

What does **not** add up, and why this is not yet fact:
1. **`bHasCachedNetworkChecksum` is 0.** By stock logic the cache is then invalid and
   `GetLocalNetworkVersion` would recompute, ignoring this value.
2. **It is not reproducible from the stock recipe.** The format string
   `%s %s, NetCL: %d, EngineNetVer: %d, GameNetVer: %d` (UTF-32 @ file offset `0x031092b8`,
   referenced once from `0x00cfdac0`, inside `GetLocalNetworkVersion`) implies
   `FCrc::StrCrc32` over `"<ProjectName> 1.0.0.0, NetCL: <n>, EngineNetVer: 2, GameNetVer: 0"`.
   An exhaustive search over `NetCL` 0..4,299,999 for seven project-name candidates
   (`ShadowTrackerExtra`, `Survive`, `ShadowTracker`, `TslGame`, `UAEGame`, `Client`,
   `ShadowTrackerExtraMobile`) produced **no match**. The CRC implementation was
   self-tested by exact forward/backward round-trip, so the search itself is sound.

The most economical reading: Tencent does not compute the network version by the stock
recipe (UE4 provides a `GetLocalNetworkVersionOverride` delegate for exactly this), so the
word cannot be re-derived from engine inputs and must be taken from the client.

**How to settle it at zero cost during bring-up:** send this value; if it is wrong the
client logs *both* numbers —
`NotifyControlMessage: Client connecting with invalid version. LocalNetworkVersion: %i, RemoteNetworkVersion: %i`
(UTF-32 @ `0x0338327c`, site `0x020d0b28`) — handing over the correct one directly. Treat
`0xF6035FB3` as the first value to try, not as settled truth.

## Network behaviour

The game process (uid 10128) holds **no UDP sockets**, and no game-server traffic was
observed. Expected: 0.3.2 is a 2018 beta whose official servers are long dead, so the client
cannot pass login and therefore never requests a game-server address or emits a handshake.

**Consequence for the project:** a handshake cannot be captured passively. The client must be
given a server to talk to first, which means the handshake field order (the last open item in
`recon/handshake.md`) is resolved *during* Phase 3 bring-up rather than before it. Build the
server with the stock field order, point the client at it, and capture what arrives.

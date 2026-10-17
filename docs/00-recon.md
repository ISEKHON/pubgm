# 00 — Recon: artifact identification

Status: **Phase 1 in progress.** Last updated 2026-10-17.

Goal of the project: a private server the original PUBG Mobile 0.3.2 client connects to and
becomes playable against. We implement the **network protocol**; we do not reconstruct the
game's C++ gameplay logic (that already ships inside the client).

See also: [01-protocol.md](01-protocol.md) (protocol spec), [02-tooling.md](02-tooling.md)
(how to reproduce every command here).

---

## 1. Artifact

| | |
|---|---|
| Source file | `pubg-mobile-0-3-2.xapk` (728,033,621 bytes) |
| SHA-256 (libUE4.so) | `1e184aea192bc8beec237137c1b05b5f51bab45b71fbccd1ed2bc55b6d3b0d3b` |
| Package | `com.tencent.ig` |
| Contents | `com.tencent.ig.apk` (32.6 MB) + `Android/obb/com.tencent.ig/main.3212.com.tencent.ig.obb` (695 MB) |
| OBB version tag | `3212` |

### Native libraries (armeabi-v7a only — 32-bit, no arm64 slice)

| lib | size | role |
|---|---:|---|
| `libUE4.so` | 61.9 MB | Unreal Engine 4.18.1 + all game code |
| `libgcloud.so` | 3.45 MB | Tencent GCloud online services |
| `libGCloudVoice.so` | 2.79 MB | voice chat |
| `libtersafe.so` | 1.96 MB | TenProtect client protection |
| `libgnustl_shared.so` | 0.71 MB | GNU STL |
| `libabase.so` | 0.58 MB | Tencent base utils |
| `libcubehawk.so` | 0.45 MB | — |
| `libTDataMaster.so` | 0.24 MB | telemetry |
| `libtprt.so` | 0.15 MB | runtime |
| `libBugly.so` | 0.14 MB | crash reporting |
| `libIMSDK.so` | 0.10 MB | messaging |
| `libxguardian.so`, `libtpnsSecurity.so` | 0.03 MB each | protection / push security |

Java layer: `classes.dex` (7.87 MB) + `classes2.dex` (1.09 MB), `resources.arsc` (0.99 MB).

---

## 2. `libUE4.so` identification — **confirmed**

| property | value |
|---|---|
| Engine | **Unreal Engine 4.18.1**, Tencent "iGame" fork |
| Engine build tag | `++UE4+Release-4.18` |
| Engine build path | `D:\shuzhilu-PC8_9407\iGame\BetaTest_FB\UE4181\Engine\Source\...` |
| **Game project name** | **`Survive`** (`.../BetaTest_FB/Survive/Source/...`) |
| Game module prefix | `UAE` (e.g. `UAENetConnection`, `UAEVersion`, `LogUAEGameMode`) |
| Architecture | ARMv7, ELF32, little-endian, PIC. **Predominantly ARM mode**: 18,279 ARM vs 5,219 Thumb defined `STT_FUNC` (radare2's `bits 16` is misleading) |
| Compiler | Android clang 3.8.256229 (LLVM 3.8) → ~2016-2017 |
| Linker | GNU gold |
| `.text` | 0x0065ce90, size 0x28538e2 (~42.3 MB) |
| `.rodata` | 0x03038160, size 0x585608 (~5.8 MB) |

The `BetaTest_FB` path segment and project name `Survive` place this as an early beta build,
consistent with version 0.3.2.

### Notable absences
- **No `OodleNetwork`** → predates Oodle packet compression. The PacketHandler chain is simpler.
- No `arm64-v8a` → 32-bit only, so a 32-bit-aware debugger/emulator is required for runtime work.
- No protobuf strings in `libUE4.so`.
- boringssl **is** present, but for HTTPS/TLS (login & CDN), *not* game-packet crypto.

---

## 3. Symbol availability — **the key tooling finding**

`radare2` reports `stripped: true`, which is true only of `.symtab`. **`.dynsym` survives:**

| table | location | size | count |
|---|---|---:|---:|
| `.dynsym` | 0x00039de8 | 0x6f3f0 (456 KB) | **28,480 symbols** |
| `.dynstr` | 0x000a91d8 | 0x15b37b (1.4 MB) | mangled C++ names |
| exports | — | — | 21,108 |
| imports | — | — | 649 |

**Caveat, important:** the exported symbols are overwhelmingly *statically-linked third-party*
code (ICU, zlib, etc.) plus engine globals and CVars. UE4's own engine classes were built with
hidden visibility and are **not** named. Measured counts in `.dynsym`:

| class | symbols |
|---|---:|
| `UNetConnection` | 0 |
| `UControlChannel` | 0 |
| `PacketHandler` | 0 |
| `HandlerComponent` | 0 |
| `StatelessConnectHandlerComponent` | 0 |
| `FRepLayout` | 0 |
| `FNetworkVersion` | **7** (data members) |
| `UAEVersion` | 6 (data members) |

So: the net *code* must still be located by anchor-and-xref, but several net *data* symbols
are named and directly readable. That is a meaningful shortcut.

### Named network data symbols recovered

| symbol | vaddr | paddr | size |
|---|---|---|---:|
| `FNetworkVersion::bHasCachedNetworkChecksum` | 0x0392fed0 | 0x0392eed0 | 1 |
| `FNetworkVersion::CachedNetworkChecksum` | 0x0392fed4 | 0x0392eed4 | 4 |
| `FNetworkVersion::EngineNetworkProtocolVersion` | 0x0392fed8 | 0x0392eed8 | 4 |
| `FNetworkVersion::GameNetworkProtocolVersion` | 0x0392fedc | 0x0392eedc | 4 |
| `FNetworkVersion::EngineCompatibleNetworkProtocolVersion` | 0x0392fee0 | 0x0392eee0 | 4 |
| `FNetworkVersion::GameCompatibleNetworkProtocolVersion` | 0x0392fee4 | 0x0392eee4 | 4 |
| `FNetworkVersion::ProjectVersion` (FString) | 0x03b97eb0 | — | 12 |

Note `vaddr = paddr + 0x1000` for this `.data` region.

Also named: `GIpNetDriverLongFramePrintoutThresholdSecs`, `GIpNetDriverMaxDesiredTimeSliceBeforeAlarmSecs`,
`CVarNetPartialBunchReliableThreshold`, `NetDriverExecRegistration`, `ListOpenActorChannelsCommand`,
`LogNetPackageMap`, `LogUAEGameMode`, and `UAEVersion::{AppSection,ResSection,RootSection,FirstGaming,AppversionFile,VersionIniFile}`.

### Network protocol version values — **[CONFIRMED]**

| field | value |
|---:|---:|
| `EngineNetworkProtocolVersion` | **2** (a Tencent pin, not stock) |
| `GameNetworkProtocolVersion` | **0** |
| `EngineCompatibleNetworkProtocolVersion` | **2** |
| `GameCompatibleNetworkProtocolVersion` | **0** |

No longer provisional. The six statics form one struct reached via base `0x392FED0`; no store
to base+8 or base+0xc exists anywhere, so the link-time values stand. See
[`../recon/network-version.md`](../recon/network-version.md).

---|---:|
| `EngineNetworkProtocolVersion` | **2** |
| `GameNetworkProtocolVersion` | **0** |
| `EngineCompatibleNetworkProtocolVersion` | **2** |
| `GameCompatibleNetworkProtocolVersion` | **0** |
| `CachedNetworkChecksum` | 0 (computed lazily at runtime) |
| `bHasCachedNetworkChecksum` | 0 |

> **Do not trust these yet.** They are static initializers in the file image. UE4 can overwrite
> such statics from `.init_array` constructors during load, and `CachedNetworkChecksum` is
> explicitly computed on first use. `EngineNetworkProtocolVersion = 2` is also *lower* than
> stock UE4 4.18 would normally carry, which is either a genuine Tencent pin or evidence of
> runtime initialisation. **Confirm by reading these addresses in a live process, or by
> decompiling `FNetworkVersion::GetLocalNetworkVersion`.** This matters because the handshake
> rejects a version-checksum mismatch outright.

---

## 4. Networking architecture (from string anchors)

All of these source paths are present, confirming a stock-shaped UE4 net stack plus a Tencent
subclass:

| component | string vaddr | meaning |
|---|---|---|
| `PacketHandler.cpp` | 0x0345c9b5 | PacketHandler component chain |
| `StatelessConnectHandlerComponent.cpp` | 0x034627a1 | cookie challenge/response handshake |
| `NetConnection.cpp` | 0x03462513 | stock `UNetConnection` |
| **`UAENetConnection.cpp`** | **0x0342a7c9** | **Tencent's own NetConnection subclass** |
| `DataChannel.cpp` | 0x03460a78 | control channel + bunches |
| `IpConnection.cpp` | 0x034d4a27 | UDP transport |
| `NetworkVersion.cpp` | 0x03435f4d | version checksum |

`UAENetConnection` (project `Survive`, module prefix `UAE`) is the primary Tencent deviation to
characterise — it is the most likely home of custom encryption and any protocol changes.

Crypto-ish string counts in `libUE4.so`: `AES` 230, `RSA` 366, `Encrypt` 141, `Decrypt` 59.
No `AESHandlerComponent` / `BlockEncryptionHandlerComponent` / `XORDelta` strings, so the
encryption component is **custom, name stripped**.

---

## 5. Open questions for Phase 1

1. Confirm the four `FNetworkVersion` protocol values at runtime.
2. Decompile `FNetworkVersion::GetLocalNetworkVersion` → exact checksum inputs.
3. Identify the PacketHandler component chain order and whether a Tencent encryption
   component sits in it.
4. Determine whether `StatelessConnectHandlerComponent`'s bit layout matches stock 4.18.
5. Characterise `UAENetConnection`'s overrides vs stock `UNetConnection`.

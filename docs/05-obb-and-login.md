# 05 — OBB contents and the login problem

> **Corrected by [12-pak-and-lobby-protocol.md](12-pak-and-lobby-protocol.md).**
> The claim below that "no content can be read without the pak AES key" is
> wrong. The entries are not AES-encrypted at all — they are XORed with the
> single byte `0x79`. The whole pak, including the Lua game logic, is readable
> with `tools/pak_tool.py`. Route **A** below is therefore done.

Covers the 695 MB OBB asset pack and Phase 4 (getting the client to talk to our
server). **Phase 4 is currently blocked** — see the honest assessment at the end.

## OBB structure

`Android/obb/com.tencent.ig/main.3212.com.tencent.ig.obb` is a **ZIP**, stored
uncompressed, with 8 entries:

| size | entry |
|---:|---|
| 692.1 MB | `ShadowTrackerExtra/Content/Paks/ShadowTrackerExtra-Android_ETC2.pak` |
| 1.7 MB | `ShadowTrackerExtra/Content/Movies/LightSpeed.mp4` |
| 1.0 MB | `ShadowTrackerExtra/Content/Movies/PUBG_CG.mp4` |
| 0.5 MB | `ShadowTrackerExtra/Content/Movies/PUBG_SID.MP4` |
| — | 4 directory entries |

This **confirms the project name is `ShadowTrackerExtra`** (the build path in
`libUE4.so` says `Survive`, which is the source tree, not the project name).

Because the OBB is stored uncompressed inside the XAPK *and* the pak is stored
uncompressed inside the OBB, both are addressable by absolute offset — nothing
needs extracting. `tools/pak_tool.py` does this; the pak begins at offset
35,881,784 in the XAPK.

## The pak — Tencent deviations

```
$ python -I tools/pak_tool.py
  magic        0x20171216 (TENCENT-CUSTOM)
  version      4
  encr. index  0
  index        offset=687093225 size=5053602
  mount point  '../../../'
  entries      28041
  encrypted entries 28041, compressed entries 27515
```

Two deviations from stock UE4:

1. **The footer magic is `0x20171216`, not `0x5A6F12E1`.** It reads as a date
   (2017-12-16). Stock UE4 pak tools check the magic and will reject this file
   outright. The rest of the footer is standard pak v4, including the UE4 4.16+
   1-byte encrypted-index flag, so the footer is **45** bytes, not 44. The
   arithmetic confirms it: `index_offset + index_size + 45 == file_size` exactly.
2. **Every single entry's data is encrypted** (28,041 of 28,041). Stock UE4
   normally encrypts selectively, if at all.

The **index itself is plaintext**, so the complete file list is recovered and
saved to `recon/pak-filelist.txt` (offset, size, uncompressed size, compression
method, encrypted flag, name).

### What is in there

| extension | count | note |
|---|---:|---|
| uexp / uasset / ubulk | 24,275 | cooked assets |
| res | 2,680 | mostly ICU locale data |
| umap | 268 | levels |
| png | 214 | |
| **lua** | **191** | `Content/lua/LuaCSV/*` — gameplay data tables |
| **ini** | **48** | engine + game config |
| csv | 48 | |

The interesting ones for this project, all **encrypted**:

- `ShadowTrackerExtra/Config/DefaultEngine.ini` — net driver, replication config
- `ShadowTrackerExtra/Config/DefaultGame.ini` — `ProjectVersion` (confirmed
  `"1.0.0.0"` at runtime already), game settings
- `ShadowTrackerExtra/Config/DefaultUAE.ini` — Tencent's own config section
- `Content/lua/LuaCSV/*.lua` — data tables, useful much later for Phase 6+

So the file list is known. ~~No content can be read without the pak AES key.~~
**Superseded: the payload is XOR 0x79, not AES — see docs/12.**

## Login endpoints

From the DEX (unencrypted), filtering out SDK/telemetry noise:

| endpoint | role |
|---|---|
| `cloud.gsdk.proximabeta.com:18081/?cmdid=` | Tencent GSDK, **international** (ProximaBeta publishes PUBGM globally) |
| `cloud.gsdk.qq.com:18081/?cmdid=` | GSDK, China |
| `gsdk.qq.com:60000/?cmdid=` | GSDK |

Supporting infrastructure also present: Bugly crash reporting, MTA/Beacon
analytics, TBS webview, `dldir1.qq.com/gamesafe/...` (TenProtect updates),
`down.qq.com/tfgame/ug/version` (version check), `qos.game.qq.com:8080`.

`libUE4.so` itself contains no game-server endpoint — only engine/third-party
URLs (Epic, Microsoft translator) and Tencent telemetry. The game server address
is therefore handed to the client **at runtime by the GSDK/login backend**, which
has been dead since ~2018.

## Attempted shortcut: UE4's own command line — [FAILED]

UE4's console/travel machinery is all present as UTF-32 strings: `OPEN`,
`TRAVEL`, `SERVERTRAVEL`, `RECONNECT`, `DISCONNECT`, `EXEC`, `UConsole`, and
`-LogCmds="..."` ("applies a list of console commands at boot time"). UE4 also
treats the first non-option command-line argument as a URL to `Browse` to, and
on Android reads its command line from a file — `UE4CommandLine.txt` and
`ue4commandline.txt` both appear in the binary, alongside
`Final commandline: %s` and a Tencent debug string
`devindzhang---FEngineLoop: ParseCommandline() end`.

If honoured, that would point the client at our server with **no patching at
all**. It was tested:

- Planted `10.0.2.2:7777 -PUBGMTESTMARKER ...` at three candidate paths:
  `<ExternalFilesDir>/UE4CommandLine.txt`,
  `<ExternalFilesDir>/UE4Game/ShadowTrackerExtra/UE4CommandLine.txt`, and
  `/sdcard/UE4Game/ShadowTrackerExtra/UE4CommandLine.txt`.
- Host confirmed reachable from the emulator: `ping 10.0.2.2` → 0% loss, 0.19 ms.
- Server listening on UDP 7777; game force-stopped and relaunched.

**Result: no datagram ever reached the server.** Logcat captured 1,768 lines and
the game clearly restarted (`SplashActivity` → `GameActivity`), but there were
**no UE4-tagged log lines at all** — `Final commandline` never printed. That is
consistent with UE4 logging being compiled out of this shipping build, the same
reason the `__FILE__` strings are dead data (see `recon/net-anchors.md`).

So the test is **inconclusive about whether the file was read**, but decisive
about the outcome: the client did not connect. Either the file is read from a
path not tried, or PUBGM's `UAEGameEngine` startup ignores a startup URL and
goes straight to its own login flow. Test artifacts were removed afterwards.

## Honest assessment: Phase 4 is the real blocker

This is harder than the handshake was. Three routes, in order of attractiveness:

**A. Recover the pak AES key, then read `DefaultEngine.ini` / `DefaultUAE.ini`.**
Pure static analysis of files already in hand. The key is near-certainly in
`libUE4.so` (which has 230 `AES` and 366 `RSA` string hits). Reading those
configs would show how the net driver and server address are configured and
whether any direct-connect or offline path exists. Best next step: cheap,
self-contained, and informative even if it does not unblock on its own.

**B. Stub the GSDK login backend.** Redirect `cloud.gsdk.proximabeta.com` to a
local service and implement enough of the `?cmdid=` protocol to return a fake
login success plus a game-server address. The protocol is proprietary and
undocumented, so this is a large, open-ended reverse-engineering effort on the
DEX and `libgcloud.so`. It is the "correct" solution and also the most work.

**C. Patch the client to connect directly.** Smallest change in principle —
force the connect path to our address. But it means modifying `libUE4.so` in the
installed app, which collides with TenProtect integrity checking. Only sane for
one's own local copy, and it stops being preservation work the moment it is
shared.

Recommendation: **A**, then reassess. Do not start **B** before **A** says
whether a simpler path exists.

# 09 — TGcp protocol, decoded; the update gate, cleared

**Status: done.** The real 0.3.2 client, pointed at `tools/tgcp_server.py`,
concludes it is up to date and shows the login screen (Guest / Facebook). No
client modification. This supersedes the cost assessment in
[08-tgcp-version-rpc.md](08-tgcp-version-rpc.md), which expected a long
reverse-engineering job. The protocol turned out to be fully recoverable from
the four captured flows plus the Thrift names left in `libgcloud.so`.

Tools: `tools/tgcp.py` (codec + dumper), `tools/tgcp_server.py` (server),
`tools/test_tgcp.py` (187 checks).

## Layers — [CONFIRMED]

Outermost first. Every layer is confirmed by **byte-exact re-encoding** of both
captured sessions (`test_session`) and by the real client accepting our output.

### 1. Frame
```
c2s:  "Cf"  <TDR TLV struct {1: head, 2: body-union}>  <head[9] bytes ciphertext>
s2c:        <TDR TLV struct {1: head, 2: body-union}>  <head[9] bytes ciphertext>
```

### 2. TDR TLV (Tencent Data Representation, TLV mode)
```
struct = 0xAA, u32be total_len (includes these 5 bytes), field...
field  = varint tag, value        tag = (id << 4) | type
type 0 varint   1 u8   2 u16be   3 u32be   4 u64be   5 u32be len + bytes
```
Type 5 carries nested structs, strings and unions alike. Nested structs
inside a type-5 field have **no** 0xAA header. A union is a struct whose only
field id is the selector, e.g. body `{0x1001: ...}`.

### 3. Head (field 1)
| id | type | meaning | values seen |
|---:|---|---|---|
| 1 | varint | magic | `0x4366` ("Cf") |
| 2 | varint | ? | 0 |
| 3 | varint | version | 1 |
| 4 | varint | **command** | see below |
| 5 | varint | session id (server-assigned) | 0 from client before ACK |
| 6 | u8 | direction | 0 c2s, 1 s2c |
| 7 | varint | per-direction sequence, from 1 | |
| 8 | varint | ? | 0 |
| 9 | varint | ciphertext length that follows the TLV | |

### 4. Commands and session flow
| cmd | dir | plaintext body | encrypted payload |
|---|---|---|---|
| `0x1001` SYN | c2s | game id, enc method (13 = 4), **service name** (14→4→1), client info incl. device GUID (7) | — |
| `0x1002` ACK | s2c | `{1:3, 2:2, 3:{2:{1:16, 2:<16-byte key>}}, 4:1, 5:1024, 6:0}` | TLV `{0x1002:{1:0}}` |
| `0x2001` AUTH_REQ | c2s | `0` | TLV: 40-hex digest (2), echo of session id (4) |
| `0x2002` AUTH_RSP | s2c | `0` | TLV: echo of SYN field 7, then 0, "", "" |
| `0x6002` SESSION | s2c | `0` | TLV: ids, service name, 1, 1024 |
| `0x4013` DATA | both | routing info | **Thrift RPC** |
| `0x5001` CLOSE | c2s | `0` | TLV `{0x5001:{1:0}}` |

The client's AUTH digest is **not checked**: our server ignores it and the
client proceeds anyway. Unknown numeric fields in ACK/SESSION are copied from
the capture (`tgcp_server.py` top-of-file constants).

### 5. Encryption
- **AES-128-CBC**, IV = `00 01 02 … 0f` (fixed).
- **Key = the 16 bytes the server sends in clear in the ACK.** There is no key
  exchange, so whoever runs the server chooses the key. This is what made
  the protocol tractable: a capture of a real session is fully decryptable.
- Padding: `filler, "tsf4g", n`, where `n` = total pad length, so the result is
  a multiple of 16 and `n >= 6` (`n = 16 - len%16`, plus 16 if that is < 6).

### 6. RPC payload: Thrift binary, with two quirks
Stock `TBinaryProtocol` (non-strict), except:
- c2s payloads begin with an extra `u32` (seen: `3`); s2c payloads do not.
- after the message-type byte come **two** `u32` instead of one seqid (seen
  `0,0` QueryAddrSvr, `0,1` VersionUpdate); replies echo the request's pair.

## The two RPCs

Schema names come from Thrift-generated strings in `libgcloud.so`
(`0x2c9449`–`0x2c9790`).

**`QueryAddrSvr:QueryAddrInfo`** (port 8085). Args `{1:{1: game id 1375135419,
2: 2, 3: "download"}}`. The reply is a list of `{host, port}` for the version
service. Real servers returned `119.28.109.187:8086` etc. We return our own address.

**`VersionUpdate:ReqUpdateVersion`** (port 8086).
```
ReqVersionUpdate { 1 comm_info { …, 5 apk_version: i64, 7 device uuid }, 2 "" }
ResVersionUpdate { 1 result: i32
                   2 comm_info (echo)
                   3 VersionUpdateInfo { 1 package_info: VersionPackageInfo
                                           { 1 version, 2 name, 3 description,
                                             4 http_url, 5 md5sum, … }
                                         2 update_type }
                   4 "2.50.21"   5 118   7 {0,0,0} }
enum update_type  { kUpdateTypeNot=0, kUpdateTypeOptional=1, kUpdateTypeForce=2 }
```
Versions are packed as four u16 in an i64: `0x0003_0002_0C8C` = 0.3.2.3212.

The real server answered `update_type = 2` (Force) with version 0.3.3.3412. **That
one field was the whole gate.** The enum values 0/1/2 are inferred from
declaration order, and confirmed in practice: 2 gave `isforceupdating[1]`, 0
gives the result below.

## Live result (2026-10-17 13:40)

The setup was the hosts bind-mount from [07](07-update-gate.md), with
`download.2.1375135419.igame.gcloudcs.com → 10.0.2.2`, and
`tools/tgcp_server.py` running on the host.

The client ran two complete sessions, with `m_update_type` 20 (apk) and then
21 (resources), each one QueryAddrSvr followed by VersionUpdate:
```
GcloudDolphinVersionAction  get new version
Handle new version isappupdating[1],isdiffupdating[0] isforceupdating[0]   <- stage 20
GcloudDolphinVersionAction  not need src update
Handle new version isappupdating[0],isdiffupdating[0] isforceupdating[0]   <- stage 21
iMSDK  eventName : loading_completed
```
→ **login screen**. (Before: `isappupdating[1] isdiffupdating[1] isforceupdating[1]`
and the forced-update dialog.)

`isappupdating[1]` at stage 20 is a residual worth checking if anything
downstream misbehaves. It may want `package_info` fields filled differently, or
`--update-type` left at 0 while the version is set lower. It did not block.

## Reproduce
```bash
python -I tools/test_tgcp.py                       # 187 checks, needs recon/tgcp/*.bin
python -I tools/tgcp_server.py                     # 0.0.0.0:8085,8086, advertises 10.0.2.2

ADB=adb; D="-s emulator-5554"; export MSYS_NO_PATHCONV=1
$ADB $D shell "su -c 'cp /system/etc/hosts /data/local/tmp/hosts.tgcp; \
  echo \"10.0.2.2 download.2.1375135419.igame.gcloudcs.com\" >> /data/local/tmp/hosts.tgcp; \
  chmod 644 /data/local/tmp/hosts.tgcp; mount -o bind /data/local/tmp/hosts.tgcp /system/etc/hosts'"
$ADB $D shell 'am force-stop com.tencent.ig'
$ADB $D shell 'monkey -p com.tencent.ig -c android.intent.category.LAUNCHER 1'
# revert:  su -c 'umount /system/etc/hosts'   (also gone after reboot)
```
Decode any new capture: `python -I tools/tgcp.py --decrypt c2s.bin s2c.bin`.

The device was reverted after the test.

## Next

Phase 4 continues **past** the gate: login (Guest), then whatever service
hands out the game-server address. The next capture should be a cold start with
the version host redirected and tapping **Guest**, to see which endpoints login
needs. If they also speak TGcp, `tgcp.py`/`tgcp_server.py` already cover the
transport, and only new Thrift handlers are needed.

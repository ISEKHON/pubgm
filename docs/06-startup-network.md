# 06 — Startup network behaviour and the update gate

**Headline: parts of Tencent's 2018 backend are still alive, and the thing
blocking the client is a plain-HTTP version check — not the login.**

Evidence: full packet capture of a cold start, `tcpdump -i any` on the rooted
emulator, analysed with `tools/pcap_http.py` (there is no tshark on this host).

## The observed gate

The client never reaches a login screen. It shows:

> A new version is available. Please update before continuing. Update now?
> (Tap cancel to exit game)

with "Verifying installation package" underneath. Installed build is
**0.3.2.3212**.

## Startup request sequence (cold start, 70 s capture)

| # | endpoint | purpose |
|---|---|---|
| 1 | `cdn.wetest.qq.com/cube/com/apmcc/APM_IG` | APM config |
| 2 | `android.bugly.qq.com/rqd/async` (POST) | crash/telemetry; carries `appVer: 0.3.2.3212` |
| 3 | **`cloud.gsdk.proximabeta.com:18081/?cmdid=3&appid=1106545419`** | **Tencent GSDK** |
| 4-9 | `down.qq.com/iedsafe/Client/android/{8999,2139}/config{2,3}.xml` | TenProtect config |
| 10 | **`file.igamecj.com/.../0.3.3.3412/..._apkupdate.json`** | **the update gate** |

Only one DNS query was observed (`time.android.com`); everything else resolved
over DNS-over-TLS to `8.8.8.8:853`, so hostnames above come from HTTP `Host`
headers.

### What is still alive (2026)

| host | status |
|---|---|
| `cloud.gsdk.proximabeta.com:18081` → 119.28.229.113 | **200**, `Server: swoole-http-server` |
| `file.igamecj.com` (TencentCOS CDN) | **200**, object Last-Modified 2018-03-29 |
| `down.qq.com/iedsafe/...` | **200**, returns TenProtect `tss_base.dat` config XML |
| `android.bugly.qq.com`, `cdn.wetest.qq.com` | **200** |

This was a surprise. The assumption in `recon/runtime-notes.md` that "official
servers are long dead" is **only partly true**: the *matchmaking/game* servers
are gone, but the CDN and several SDK endpoints still answer.

## The update gate in detail

Request (plain HTTP, port 80, no TLS):

```
GET /1375135419/20/apkupdate/0.3.3.3412/1375135419_20_0.3.3.3412_20180329172255_apkupdate.json
Host: file.igamecj.com
```

Response is a small JSON describing an update package: an `AllChannelsFull`
object with `md5`, `name`, `size` (744,325,245) and a `url` pointing back at
`file.igamecj.com`, for version **0.3.3.3412**.

The client compares that against its own 0.3.2.3212, concludes it is outdated,
and blocks. Two properties make this attackable:

1. **Plain HTTP.** No TLS, no certificate pinning to defeat — just DNS/hosts
   redirection plus a local HTTP server.
2. **The target version is in the request path.** The client already knew
   `0.3.3.3412` *before* issuing this request, so some earlier step supplied it.

### Where does 0.3.3.3412 come from?

Not from any plaintext response in the capture. The most likely source is the
GSDK reply (step 3), whose body is **base64 and encrypted**:

```
HTTP/1.1 200 OK
Server: swoole-http-server
Transfer-Encoding: chunked

IFZN+M9zmYZCPey5gqwQM5Bw3KbvZ9gCJJcsr/A21OvHP3tCuaLyYl88IHiIifOXyG9a...
```

~512 bytes of base64 after decoding. Unresolved: the cipher and key. This is
the same wall as the pak encryption and likely shares machinery.

## Plan to get past the gate

Ordered cheapest first. **None of this is implemented yet.**

**G1 — Redirect `file.igamecj.com` to a local stub.** With root, add a line to
`/system/etc/hosts` pointing it at `10.0.2.2` (host is reachable, 0.19 ms) and
serve either a 404 or a crafted JSON advertising 0.3.2.3212. If the client only
prompts after successfully fetching the JSON, this alone may clear the popup.
Cheapest possible test and reversible.

**G2 — If the version comes from GSDK, stub that too.** Needs the GSDK response
format, which is encrypted. Harder; depends on G1's outcome.

**G3 — Patch the version comparison in the client.** Last resort; collides with
TenProtect and stops being preservation work the moment it is shared.

> Note the TenProtect config fetches (steps 4-9) succeed and return a live
> config. Those are the anti-cheat's own update channel. Leave them alone — the
> goal is to get a client *we own* to talk to a server *we own*, not to interfere
> with protection machinery.

## Reproduce

```bash
ADB="$ANDROID_SDK/platform-tools/adb"; D="-s emulator-5554"
$ADB $D shell "su -c 'nohup tcpdump -i any -s 0 -w /sdcard/cap.pcap &'"
$ADB $D shell 'am force-stop com.tencent.ig'
$ADB $D shell 'monkey -p com.tencent.ig -c android.intent.category.LAUNCHER 1'
sleep 70
$ADB $D shell "su -c 'pkill tcpdump'"
MSYS_NO_PATHCONV=1 $ADB $D pull /sdcard/cap.pcap 'C:\path\cap.pcap'
python -I tools/pcap_http.py cap.pcap outdir/
```

Git Bash rewrites `/sdcard/...` into a Windows path; `MSYS_NO_PATHCONV=1` is
required for the remote path, and the local path must be Windows-style.

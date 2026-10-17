# 07 — The update gate (Phase 4 blocker)

**Status: cleared — see [09-tgcp-protocol.md](09-tgcp-protocol.md).** A local
TGcp server answering `update_type = kUpdateTypeNot` gets the client to the
login screen. The text below is the history that led there.

~~Fully mapped, not yet bypassed.~~ The client cannot reach login
because GCloud's update check fails closed. This documents exactly how it
works, what was tried, and the only route that can actually satisfy it.

## The chain

Traced from GCloud's own plaintext logs at
`/sdcard/Android/data/com.tencent.ig/cache/GCloud/GCloud_*.log`, which are
remarkably verbose — they carry source filenames and line numbers.

```
version_mgr_imp.cpp:27        Using apollo[GCloud1.1.2.169014]
GcloudDolphinVersionAction:133  start init rpc:download.2.1375135419.igame.gcloudcs.com
GcloudDolphinVersionAction:149  connected start to get new version
GcloudDolphinVersionAction:194  get new version
report_data_collector.cpp:43    report key Game Dst Version, value 0.3.3.3412
ApkUpdateAction.cpp:509         download http://file.igamecj.com/.../apkupdate.json
ApkUpdateAction.cpp:895         download full apk (744 MB)
app_callback_event_version.cpp:27  isappupdating[1] isdiffupdating[1] isforceupdating[1]
```

**The decisive fact:** the "latest version" 0.3.3.3412 comes from an RPC to
**`download.2.1375135419.igame.gcloudcs.com`**, *not* from the HTTP endpoints.
By the time the client fetches `apkupdate.json` it has already decided to
update — that fetch only supplies the download package.

`isforceupdating[1]` — it is a forced update, so there is no "skip" path.

## GCloud configuration (from the log)

Constructed **in-process** and handed to `version_mgr_imp::Init`, so it is *not*
an editable file on disk:

| key | value |
|---|---|
| `m_server_url_list` | `["download.2.1375135419.igame.gcloudcs.com"]` |
| `m_cur_app_version_str` | `0.3.2.3212` |
| `gcloud_service_id` | 20 |
| `m_update_type` | 20 |
| `m_u32GcloudGameId` | 1375135419 |
| `m_strGcloudGameKey` | `b5eede99675aec279ec215c7bad83abb` |
| `apollo_path` | `.../Saved/UpdateInfo/` (contains only empty logs — no cacheable response) |

## Experiments run

Redirection works: a bind-mount over `/system/etc/hosts` (the image cannot
remount `/system` rw — `mount: '/dev/sda1'->'/system': I/O error`) plus a local
stub on the host at 10.0.2.2:80. `tools/stub_server.py` logs and answers.

| # | what was served | result |
|---|---|---|
| 1 | `apkupdate.json` → **404** | `Internet error. Error code: 689045908`, client retries in a tight loop (50+ requests) |
| 2 | `apkupdate.json` → **valid JSON** (size 0, empty url) | `Installation failed. Error code: 691011591` — client *advanced to the install stage*, only 6 requests |
| 3 | version RPC host **blackholed** to 127.0.0.1 | `Internet error. Error code: 154140712`, stuck at "Checking updates..." |

**Conclusion: the gate is fail-closed.** Every way of breaking the pipeline
yields a different blocking error; none falls through to "you are up to date".
Experiment 2 is the most informative — feeding a *valid* response moved the
client further along the update path rather than past it, confirming the
decision is made upstream of that endpoint.

## What would actually work

**Satisfy the version RPC.** Point `download.2.1375135419.igame.gcloudcs.com`
at a local service that answers "latest = 0.3.2.3212", so GCloud concludes no
update is needed and proceeds to login. Everything needed to start is now known:
the host, the component (`GcloudDolphinVersionAction`), the game id and key, and
`gcloud_service_id`/`m_update_type` = 20.

Unknown: the wire protocol. It is **not** plain HTTP — it never appeared in the
port-80 capture. Next step is to capture traffic to that host (note it resolves
to a real IP; capture before blackholing) and to examine `libgcloud.so`, where
the `GcloudDolphinVersionAction` symbols should be recoverable the same way the
UE4 ones were.

Rejected alternatives:
- *Breaking* any step — proven fail-closed above.
- Patching the comparison in `libgcloud.so` — collides with TenProtect, and
  stops being preservation work the moment it is shared.

## Reverting

The hosts change is a bind-mount, so it does not survive a reboot and is undone
with `umount /system/etc/hosts`. The original is also backed up at
`/data/local/tmp/hosts.bak`. This was reverted after testing; the device is back
to its original state.

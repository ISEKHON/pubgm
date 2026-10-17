# 10 — What login needs (the next wall)

> **Partly superseded by [11-lobby-transport.md](11-lobby-transport.md).** The
> transport comparison below was wrong on one key point: the `:17500` lobby does
> **not** use a separate in-band-keyed crypto layer. It reuses the version RPC's
> AES-128-CBC + `tsf4g` scheme with the key sent in clear in the ACK, so no DH
> had to be reversed. Only the outer framing differs. The client now completes
> the handshake against our own server and sends its `login` RPC.

**Status: mapped.** With the update gate cleared (`docs/09-tgcp-protocol.md`),
the client reaches the login screen and, on **Guest**, tries to log in. It now
stops at the **lobby/game server**, which is the Phase 5 control-channel target.

Evidence: cold-start capture `login.pcap` (gitignored), tapping Guest, with the
version host redirected to our `tgcp_server.py`. GCloud log + `tools/pcap_tcp.py`.
Lobby handshake sample saved at `recon/tgcp/lobby_{c2s,s2c}.bin`.

## The sequence after Guest

1. **MSDK/iMSDK** resolves a Guest `openId` (`188039022634206504`) locally and
   reports telemetry — this part succeeds offline.
2. GCloud re-runs the **version check** twice more (`m_update_type` 22 then 23;
   the value escalates per stage). Both pass against our server:
   `not need program update` → `not need src update` → `isforceupdating[0]`.
3. The client dials the **lobby**:
   ```
   gcpapi.t.cpp:204 Start url:tcp://lobby.igamecj.com:17500(101.32.112.114)
   gcpapi.t.cpp:204 Start url:tcp://49.51.43.31:17500
   ```
4. Both fail, and the UI shows **`Server is busy; please try again later.
   Error code:version_error`**:
   - `101.32.112.114:17500` — TCP connects, then the **server ends the
     session**: `tgcpapi_on_sstop_session iReason:0x7`,
     `tgcpapi_peek ... recv_and_decrypt_pkg iRet:-11`,
     `Game server close the connection`.
   - `49.51.43.31:17500` — `Connect timeout` after 10 s.

So the version pipeline is fully satisfied; the block is now the **game login
service**, which the client cannot reach (one lobby IP rejects the old client's
session, the other is unreachable). This is expected: it is a live 2018 service,
not something to lean on. The fix is a lobby server we run.

## The lobby transport is NOT the version transport

Port 17500 uses a different codec from the version RPC. From
`recon/tgcp/lobby_{c2s,s2c}.bin` (one real handshake, captured before the
server closed it):

| | version RPC (8085/8086) | lobby (17500) |
|---|---|---|
| framing | `0xAA` TDR-TLV struct | frames begin **`33 66`** then `00 0a 00 0a`, a 2-byte command, flags, u32 length |
| commands seen | 0x1001/2001/4013/5001 | same ids `0x1001/0x2001/0x4013/0x5001` + `0x50xx` |
| crypto | AES-128-CBC, **key sent in clear** in ACK | encrypted, **no in-clear key** (`recv_and_decrypt_pkg`), Tencent `tgcpapi`/tconnd session layer |
| library path | `GcloudDolphin*`, `TGcp.cpp` | `tgcpapi*.cpp`, `gcpapi.t.cpp`, `Connector+Update.cpp` |

`tools/tgcp.py` does not parse the 17500 framing; it is a separate protocol
(`tgcpapi` / tconnd). The readable tail of the server's first frame carries a
tconnd route id (`...4.1.5.1089`), consistent with the `TconndId:4.1.5.1089`
in the log. The payloads are 16-byte-block sized, so the `tsf4g` AES scheme is
plausible here too, but the key is established in-band rather than handed over.

## What this means for the plan

Phase 4's deliverable — *get the client to the point where it connects to a
server address we control* — is **one redirect away**: `lobby.igamecj.com` and
the IP `49.51.43.31` are what Guest login dials. Pointing those at our own
listener is the same hosts-bind-mount trick already used for the version host.

Phase 5 then has two parts, in order:
1. **Reverse the `tgcpapi`/tconnd session layer** (port 17500 framing + its key
   agreement) enough to accept a session and read the login RPC. This is the
   `tgcp.py` work over again for a second, in-band-keyed transport. The symbols
   needed (`tgcpapi_*`, `Connector+Update`) are present in `libgcloud.so`.
2. **Answer the login RPC**, then hand back a **game-server address** (this is
   where the UE4 handshake server from Phases 2–3 finally gets exercised).

### Next concrete step
Redirect the lobby hosts/IP to `10.0.2.2`, stand up a bare TCP listener on
17500 that logs bytes, and capture a *complete* client-side handshake (the real
server cut ours off at the first frame). With both directions of a full
handshake in hand, decode the 17500 framing the same way the version RPC was
decoded. Keep the official lobby **out of it** — capture only our own client
against our own listener; do not poke the live service.

## Reproduce
Same setup as `docs/09`, then tap Guest. Extract streams:
```bash
python -I tools/pcap_tcp.py login.pcap outdir/ 17500   # writes per-stream .bin
```
`pcap_tcp.py` reassembles TCP by sequence number and de-dups the doubled
segments `tcpdump -i any` records. The device was reverted after the test.

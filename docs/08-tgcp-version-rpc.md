# 08 — TGcp: the version RPC

> **Superseded by [09-tgcp-protocol.md](09-tgcp-protocol.md).** The protocol was
> fully decoded from these captures, and the gate is cleared. Two corrections to
> the notes below: the payload is TDR TLV + AES + Thrift, **not protobuf**, and
> the tokens are 16 bytes (`SBZPjiNS3KD9p83Y`; the trailing `A` was the next tag).
> The "large project" assessment turned out wrong: the AES key travels in clear.

The update gate (`docs/07-update-gate.md`) is decided by an RPC that is **not
HTTP**. This documents its transport and framing, and assesses the cost of
satisfying it.

Evidence: `recon/tgcp/version-rpc.pcap` (gitignored) + GCloud's own logs.

## Transport — [CONFIRMED]

From `GCloud_*.log`:

```
address_service.cpp:423  new connector tcp://119.28.123.95:8085
TGcp.cpp:238             CTGcp::SetRouteInfo name:QueryAddrSvr
TGcp.cpp:275             Start url:tcp://119.28.123.95:8085
TGcp.cpp:486             Connect success!
```

| property | value |
|---|---|
| protocol | **TGcp** (Tencent GCloud proprietary), raw TCP — not HTTP |
| step 1 | `QueryAddrSvr` address/directory service, `119.28.123.95:8085` |
| step 2 | version service, `119.28.109.187:8086` |
| retries | `m_retry_count = 5` |
| DNS name | `download.2.1375135419.igame.gcloudcs.com` |

**Useful hook:** when that name is blackholed to 127.0.0.1, GCloud dutifully
retries `tcp://127.0.0.1:8085` (1,236 attempts in one log). So a local listener
on **port 8085** is enough to receive the traffic — no proxy needed.

## Framing — [PARTIAL]

Four flows captured, both directions. Shape:

- **Client→server** begins `43 66` ("Cf") then `aa 00 00 00`, a length byte,
  then the payload.
- **Server→client** begins `aa 00 00 00`, a length byte, then the payload.

Payloads look like **protobuf**: repeating `<tag><varint>` pairs
(`10 e6 86 01  20 00  30 01  40 81 20  50 00 ...`), i.e. fields 2, 4, 6, 8, 10
as varints. Both directions carry a client GUID
(`49DA439B-...`) and the server returns short session tokens
(`GI8pptp3DsitBdfwA`, `SBZPjiNS3KD9p83YA`). Readable fragments `Query…` and
`Versi…` match the `QueryAddrSvr` / version method names from the log.

Not established: the exact header fields, the protobuf schema, whether the
tokens are nonce-bound, and any checksum/encryption over the payload.

## Can the symbols help? — No

`libgcloud.so` is stripped where it matters:

| | libUE4.so | libgcloud.so |
|---|---:|---:|
| symbols | 28,480 | **1,388** |
| TGcp | — | **0** |
| protobuf | — | **0** |
| dolphin | — | 13 (factory/interface only: `CreateDolphin`, `GCloudDolphinInterface`) |

Only the plugin boundary is exported. The protocol implementation is unnamed
ARM code, so the trick that made `libUE4.so` tractable does **not** transfer.

## Assessment

To clear the gate the server must answer "latest = 0.3.2.3212". That needs a
working TGcp implementation, which means reversing framing + schema from
stripped ARM. **This is a large project in its own right** — comparable to or
bigger than all the UE4 protocol work done so far — and it gates everything
above it.

Replaying the captured response does not help: it is precisely the response
that reports 0.3.3.3412, so replaying reproduces the gate.

### Options

| option | cost | notes |
|---|---|---|
| **Reverse TGcp and serve a "no update" reply** | **high** | The clean solution. Hook point (127.0.0.1:8085) and wire samples already in hand |
| Patch the version comparison in `libgcloud.so` | medium | Collides with TenProtect; only defensible for one's own local copy, and not shareable |
| Target a build without a live forced-update check | unknown | Worth a look before committing to either of the above |

**The honest summary:** the networking work (Phases 2-3) is done and tested, but
it cannot be exercised against the real client until this gate is solved, and
solving it properly is a major undertaking. Phase 4 is where this project's
real cost sits — not in the UE4 protocol, which turned out to be largely stock.

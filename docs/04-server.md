# 04 — The server

Current state: **the StatelessConnect handshake works end to end** against a
synthetic client. Nothing above the handshake exists yet.

## Build and run

```powershell
powershell -File server\build.ps1        # builds + runs all test suites, then the server
server\build\pubgm_server.exe 7777       # listen on UDP 7777
```

Requires MSVC build tools; the script locates `vcvars64.bat` itself. Everything
compiles at `/W4 /WX` (warnings are errors).

## Layout

| file | role |
|---|---|
| `include/bitstream.h`, `src/bitstream.c` | LSB-first bit reader/writer matching `FBitWriter`/`FBitReader`, incl. the termination bit |
| `include/packet.h`, `src/packet.c` | bunch header codec + partial-bunch reassembly |
| `include/sha1.h`, `src/sha1.c` | SHA-1 and HMAC-SHA1, for the cookie |
| `include/handshake.h`, `src/handshake.c` | StatelessConnect handshake + server state machine |
| `src/main.c` | UDP listener; also the diagnostic instrument (see below) |
| `tests/` | four suites: bitstream, packet, sha1, handshake |
| `../tools/hs_client.py` | synthetic handshake client for smoke-testing |

## Tests

All four suites pass. What they do and do **not** establish:

- **sha1**: known-answer tests — FIPS 180-1 vectors (incl. the 1,000,000-byte
  case), byte-at-a-time streaming equivalence, and RFC 2202 HMAC vectors
  including the longer-than-block-size key path. This primitive is genuinely verified.
- **bitstream**: hand-computed byte vectors, so the bit *order* is pinned down.
- **packet** / **handshake**: deliberately assert **no** byte vectors for wire
  layout, because the field order is `[STOCK]`/unverified — a vector would only
  enshrine the current guess as a passing test. They assert instead: the
  confirmed 195-bit budget, codec symmetry, conditional-field widths, and every
  rejection path. Passing means the machinery is self-consistent; it does **not**
  mean the layout matches the real client.

Cross-check: `tools/hs_client.py` re-implements the LSB-first packing
independently in Python and agrees with the C server, so the bit convention is
not merely self-consistent.

## Handshake: what is confirmed vs assumed

Confirmed from `libUE4.so` (see `recon/handshake.md`): cookie **20** bytes,
secret **64** bytes, packet **195** bits. On the wire a datagram is 25 bytes
(195 payload bits + 1 UE4 termination bit = 196 → 25 bytes), which the smoke
test reproduces exactly.

Assumed (`[STOCK]`, from open-source UE4 4.18) and still unverified:

| field | bits |
|---|---:|
| `bHandshakePacket` | 1 |
| `bRestartHandshake` | 1 |
| `SecretId` | 1 |
| `Timestamp` (float32) | 32 |
| `Cookie` | 160 |

The order lives in exactly one place — `hs_encode()`/`hs_decode()` in
`src/handshake.c` — so correcting it is a one-place change.

### The cookie does not need to match Tencent

Worth stating plainly, because it removes what looked like a hard problem: the
server both **generates and verifies** the cookie, and the client only echoes it
back. So its construction is ours to choose. We use
`HMAC-SHA1(secret[id], timestamp || client_address)`, which is 20 bytes by
construction. Only the *packet layout* has to match the client.

The cookie is address-bound and time-bound, so it cannot be replayed from a
different source address or after `HS_MAX_COOKIE_AGE`; both are tested. And no
per-client state is allocated until it verifies — the point of "stateless
connect" is that a spoofed source address cannot make the server allocate
anything.

## Bring-up procedure — how to settle the field order

`src/main.c` is built to be the instrument. For every datagram it logs the raw
hex, the exact payload bit count, and a field-by-field decode; a packet that
fails to decode is logged loudly rather than dropped.

1. Start the server. Point the client at the host IP and port.
2. Read the first datagram's log:
   - **`payload bits = 195`** → the budget is right, so only the order is in
     question. Compare the decoded fields against expectation: the client's
     first packet should be `bHandshakePacket=1`, `bRestartHandshake=0`,
     `Timestamp=0`, cookie all zero. If `Timestamp` is wild or the cookie is
     non-zero, the order is wrong — permute it in `hs_encode`/`hs_decode`.
   - **Any other bit count** → it is not a handshake packet; capture and
     re-analyse before assuming anything.
3. Once the client accepts the challenge and replies, the order is confirmed.
   Then add byte-vector tests from the captured bytes and retag the layout
   `[CONFIRMED]` in `docs/01-protocol.md`.

> Reminder from `recon/runtime-notes.md`: the client cannot reach dead official
> servers, so it must be *given* our address — it will not stumble onto a
> handshake by itself. Reaching that point is Phase 4 (login/session stub).

## Next

- **Phase 4** — login/session stub, so the client is handed our server address.
  This is the actual blocker for everything above. Progress: the update gate is
  cleared (`docs/09-tgcp-protocol.md`) and the lobby transport is solved
  (`docs/11-lobby-transport.md`); the client now reaches our lobby server and
  sends its `login` RPC. The remaining unknown is the login reply schema.
> **Update:** the lobby now hands clients to this server. `docs/17-match-handoff.md`
> confirms the link is **not** packet-encrypted (no `EncryptionComponent` in the
> binary), so the stock StatelessConnect design below stands. Point the lobby at
> this server with `run_server.py --match-ip <IP> --match-port 7777`, tap Start
> in-game, accept the "re-enter battle?" dialog, and read the first datagram —
> `src/main.c` is already the instrument for exactly that.

- **Phase 5** — control channel. Note the numbering is **not stock**:
  `Join = 9`, not 7 (`recon/control-messages.md`), and the version word must
  match (first value to try: `0xF6035FB3`, see `recon/network-version.md`).

# 11 — The lobby transport (port 17500), solved

**Status: transport done. The client completes the full handshake against our
own server and sends its `login` RPC.** What remains is the *content* of the
login reply, which is application-level and lives in the game's encrypted Lua.

This supersedes the guess in [10-login-boundary.md](10-login-boundary.md) that
the lobby would need a separate, in-band-keyed crypto layer reversed from
stripped ARM. It does not: the lobby reuses the version RPC's crypto exactly.

Tools: `tools/lobby.py` (codec), `tools/lobby_server.py` (server + instrument),
`tools/test_lobby.py` (17 checks). Sample: `recon/tgcp/lobby_{c2s,s2c}.bin`.

## The headline

The lobby on `:17500` uses the **same AES-128-CBC + `tsf4g` padding as the
version RPC, with the 16-byte key sent in clear in the server's ACK**. Only the
outer frame differs. Once that was spotted, the whole captured session
decrypted, including the client's login request and the server's reply.

## Frame format — [CONFIRMED]

Byte-exact round-trip against both capture directions (`test_frame_roundtrip`).

```
magic   33 66
const   00 0a 00 0a
cmd     u16 BE
dir     u32 LE     0 = c2s, 1 = s2c
seq     u32 LE     per-direction, from 1
ctoff   u8         offset from frame start where the ciphertext begins
ctlen   u32 BE
prefix  ctoff-21 bytes   (empty normally; 4 for DATA; the key TLV for ACK)
cipher  ctlen bytes
```

| cmd | name | encrypted? |
|---|---|---|
| `0x1001` | SYN | no — plaintext prefix carries the openid |
| `0x1002` | ACK | prefix carries the **session key**; cipher is `\x00` |
| `0x2001` | AUTHREQ | yes |
| `0x2002` | AUTHRSP | yes |
| `0x6002` | BINGO | yes |
| `0x4013` | DATA | yes — carries the RPCs |
| `0x5001`/`0x5002` | STOP | c2s encrypted; s2c plaintext (carries the reason) |

Handshake order, confirmed by the `gcloud_tgcpapi_start_connection` log strings
in `libgcloud.so`: `SYN → ACK → AUTHREQ → AUTHRSP → BINGO`, then DATA.

## Handshake bodies — [CONFIRMED], and the trap

These are fixed-shape TDR buffers. **Lengths are u16 big-endian and count the
NUL where the field is NUL-terminated.** Getting a length or a NUL wrong makes
the client reject the frame with

```
tgcpapi_update ... ret:-18, tdr unpack failed
Connect Error:203 ... retry count:10 > 10
```

and it retries ten times, then shows *"server error, login again"*. That was
the first run's failure: an openid length of 18 instead of 19, and no NUL.

```
AUTHRSP (84 bytes)             BINGO (33 bytes)
  20 01 03 00 00                 00
  u16be len(openid)+1            session token, 19 bytes
  openid + NUL                   00 * 11
  00 * 8                         04 00
  ff ff
  u16be len(token)
  token (32, no NUL)
  00 * 14

ACK prefix: 02 10 <16-byte key> 00 00 00 04 00 00 00 00 00
```

`test_handshake_bodies_match_capture` asserts our builders reproduce the real
server's bytes exactly, given the captured openid/token — the regression that
would otherwise cost another bring-up cycle to rediscover.

**The session key is ours to choose.** The server generates it and sends it in
the ACK; the client just uses it. Same property as the version RPC's cookie.

## The login RPC — [CONFIRMED request, UNKNOWN reply]

DATA payloads use a compact tagged encoding ("tdr compact"): a `0x78` marker,
then typed values; `0x03 len bytes` = string, `0x02 <LEB128>` = varint,
`0x04 <u8>` = byte, `0x07` opens a string-keyed map. `tools/lobby.py:tdr_parse`
reads enough of it to pull method names and arguments.

Request, as our server decoded it live from the real client:

```
method  login
arg     0.3.2.3212
map     DeviceId=61a8792717ec0528  DeviceName=SM-S908E  NetWork=Wifi
        ClientVersion=1  ScreenWidth=2068  ScreenHight=948  SystemSoftware=11
        GLVersion=OpenGL ES 3.2 (...)  GLRender=...  TelecomOper=NULL
        vClientIP=10.0.2.15  CpuHardware=14  relogin=...  <timestamp>  en
```

The reply shape is known only from the failure case:

```
78  03 0c "login_failed"  02 <code>  03 0d "version_error"
```

i.e. `0x78`, a result-name string, a code varint, then a detail string. **The
success schema is not known.** `login`/`login_failed` do not appear in
`libUE4.so` at all — the lobby logic is Lua inside the encrypted paks — so it
cannot be read statically, and no successful login can be captured.

> **Superseded by [13-lobby-login.md](13-lobby-login.md)** for everything past
> the transport: the client now completes login, creates a character and enters
> the lobby scene against `tools/lobby_server.py`.

## Where it stands

Last run, with `tools/lobby_server.py` answering:

```
<< 0x1001 SYN   openid=188039022634206504
>> 0x1002 ACK   (our key)
<< 0x2001 AUTHREQ token=0526f464fd59fe45e47592e632fe4aaf
>> 0x2002 AUTHRSP   >> 0x6002 BINGO
<< 0x4013 DATA  method=login          <-- the client got this far
>> 0x4013 DATA  (our guessed reply)
```

One connection, no retries, **no `tdr unpack failed`, no error dialog** — the
transport is accepted. The client then returns to the login screen rather than
advancing, because our reply is not a login result it recognises.

## Next

> **Answered by [12-pak-and-lobby-protocol.md](12-pak-and-lobby-protocol.md).**
> There is no `login_success` packet — that is why the guess below drew no
> reaction. The developers' own comment in `logic_login.lua` says success is
> signalled by simply continuing; the packet that completes login is
> `sync_base_info(roleData)`, preceded by `please_create_role` for an account
> with no character. The whole lobby protocol is readable Lua source.

~~Reverse the login **reply** schema.~~ The client is the oracle: each guess either
advances it (a new RPC arrives, which our server logs decoded) or is ignored.
Use `--login-reply FILE` to iterate without editing code.

Option 1 below was taken and worked: the paks are XOR 0x79, and the Lua is
plain source. See docs/12.

After login succeeds, the lobby will ask for player data and eventually a
**game-server address** — that is where the UE4 handshake server from Phases
2–3 finally gets exercised (`BattleServerIP`/`BattleServerPort` are in
`libUE4.so`).

## Reproduce

```bash
python -I tools/test_lobby.py                 # 17 checks, needs recon/tgcp/lobby_*.bin
python -I tools/tgcp_server.py                # version gate, 8085/8086
python -I tools/lobby_server.py                # lobby, 17500

# hosts bind-mount (both hosts), then cold start and tap Guest:
#   10.0.2.2 download.2.1375135419.igame.gcloudcs.com
#   10.0.2.2 lobby.igamecj.com
# revert:  su -c 'umount /system/etc/hosts'
```

Decode a capture: `python -I tools/pcap_tcp.py cap.pcap outdir/ 17500`, then
read the frames with `lobby.frames()`. The device was reverted after testing.

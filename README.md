# pubgm-private-server

A private, self-hosted server for **PUBG Mobile 0.3.2 (2018 beta)**, built for
preservation and for playing with a small group of friends on a LAN or a server
you control.

The 0.3.2 client is a 2018 beta whose official backend has been gone for years.
This project reimplements enough of that backend for an unmodified client to
boot, log in, create a character and reach the lobby — and, in progress, to play
a match.

**Current state:** the real client reaches the **full lobby UI** — Start, Squad /
Auto Matching, Crew, Rank, Inventory, Supplies, Missions, Events — driven
entirely by the servers in this repo. No client patching, no modified APK.

![status](https://img.shields.io/badge/login-working-brightgreen)
![status](https://img.shields.io/badge/lobby-working-brightgreen)
![status](https://img.shields.io/badge/match-in%20progress-orange)

---

## What this repo does and does not contain

**Contains:** our own server code, protocol decoders, analysis tooling and
written findings.

**Does not contain, and never will:** the game client, the APK, the OBB, the
`.pak`, or anything extracted from them (assets, Lua, configs). Those are
Tencent's copyrighted content. You must supply your own legally obtained copy of
the game; the tools here read it **in place** from your own file.

`.gitignore` is set up to keep game content out of the repository. Please keep
it that way in any contribution.

---

## Quick start

### Requirements

- Python 3.10+ with `cryptography` (`pip install cryptography`)
- Your own copy of the PUBG Mobile 0.3.2 APK/XAPK + OBB
- An Android device or emulator with **root** (for the hosts redirect)
- Optional, for the UE4 game server: MSVC build tools (Windows)

### 1. Run the server

One command starts the update gate, the lobby and the DNS responder:

```bash
# emulator on this same machine
python -I run_server.py --lan-ip 10.0.2.2 --no-dns

# real devices on your network (port 53 needs admin/sudo)
python -I run_server.py --lan-ip 192.168.1.50
```

`--lan-ip` is the address *players' devices* use to reach this machine.

### 2. Point the client at it

**Option A — DNS (no root, best for a group).** Leave the DNS responder on and
set each device's Wi-Fi DNS to this machine's LAN IP. Nothing else to do.

**Option B — hosts file (needs root, fine for one emulator).**

```bash
adb shell "su -c 'cp /system/etc/hosts /data/local/tmp/hosts.pm
  printf \"10.0.2.2 download.2.1375135419.igame.gcloudcs.com\n10.0.2.2 lobby.igamecj.com\n\" \
    >> /data/local/tmp/hosts.pm
  mount -o bind /data/local/tmp/hosts.pm /system/etc/hosts'"
```

`10.0.2.2` is the emulator's route to its host. Undo with
`su -c 'umount /system/etc/hosts'`; it also does not survive a reboot.

### 3. Launch and play

Start the game, tap **Guest**, create a character. You land in the lobby.
Characters persist in `pubgm.db`.

### 4. Hosting it on the internet

```bash
python -I run_server.py --public-ip <VPS_IP> --public --registration invite
```

`--public` makes the DNS responder authoritative-only (so it is not an open
resolver) and warns about unsafe settings. Because the client's `openid` is
self-asserted and unverifiable, the server is **invite-only by default**: a new
player is refused once, their openid appears in the log, and you admit them with
`tools/admin.py invite <openid>`.

Full deployment — firewall, systemd unit, backups, device setup, and the VPN
alternative — is in [docs/16-hosting.md](docs/16-hosting.md).

### 5. Admin control

```bash
python -I tools/admin.py players                     # who exists
python -I tools/admin.py show  Alice
python -I tools/admin.py set   Alice --level 30 --gold 999999
python -I tools/admin.py grant Alice 401753 --count 1
python -I tools/admin.py ban   Alice   /   unban Alice
python -I tools/admin.py invite <openid> --note "Ravi"
python -I tools/admin.py invites
```

---

## How it works

The client talks to three different protocols, all now decoded:

| layer | port | protocol | status |
|---|---|---|---|
| Version / update gate | 8085, 8086 | TGcp: TDR-TLV + AES-128-CBC + Thrift | done |
| Lobby | 17500 | tconnd: `0x3366` frames + AES-128-CBC + "tdr compact" RPC | done |
| Match (UE4) | UDP 7777 | UE4 4.18 `UAENetDriver` / StatelessConnect | handoff done, bring-up next |

Two findings made this tractable, and both were the opposite of what was
expected:

1. **Both TCP protocols send the AES session key in clear** in the server's
   first reply. There is no key exchange to break. A single captured session
   decrypts completely.
2. **The game's `.pak` is not AES-encrypted** — every entry is XORed with the
   single byte `0x79`. Inside it, the game's **Lua ships as readable source**,
   including `logic_login.lua` and `logic_lobby.lua`, with the login contract
   written out in the developers' own comments. The lobby protocol did not have
   to be guessed; it was read.

---

## Repository layout

```
docs/      numbered findings, in the order they were discovered
tools/     protocol codecs, servers and analysis tooling (Python)
server/    UE4 game-server core (C): bitstream, packet framing, handshake
recon/     analysis outputs (large artifacts gitignored)
```

### Tools

| tool | purpose |
|---|---|
| `run_server.py` | **start everything** — update gate, lobby, DNS |
| `tools/admin.py` | admin CLI: players, items, level, currency, bans |
| `tools/store.py` | SQLite store; builds the `roleData` the lobby needs |
| `tools/dns_server.py` | DNS responder so players need no root |
| `tools/tgcp.py` | version-RPC codec; `--decrypt c2s.bin s2c.bin` dumps a session |
| `tools/tgcp_server.py` | answers the version/address RPCs ("no update") |
| `tools/lobby.py` | lobby transport codec + RPC encode/decode |
| `tools/lobby_server.py` | the lobby server, and the bring-up instrument |
| `tools/pak_tool.py` | reads the `.pak` in place: `--cat`, `--extract`, `--grep` |
| `tools/pcap_tcp.py` | extracts TCP streams from a pcap, per direction |
| `tools/test_*.py` | round-trip suites (219 checks) |

Run the suites with `python -I tools/test_tgcp.py` and
`python -I tools/test_lobby.py`. They re-encode captured sessions and compare
byte-for-byte, so a pass means the encoders produce exactly what the real client
and server put on the wire.

---

## Documentation

The `docs/` directory is a running log of findings, written as they were
established. Claims carry confidence tags (`[CONFIRMED]`, `[STOCK]`,
`[UNKNOWN]`), and later documents correct earlier ones rather than quietly
rewriting them — several early conclusions turned out to be wrong, and the
corrections are part of the record.

Start here:

| doc | subject |
|---|---|
| [00-recon](docs/00-recon.md) | what the binary is |
| [01-protocol](docs/01-protocol.md) | UE4 net protocol spec |
| [02-tooling](docs/02-tooling.md) | how to reproduce every result |
| [03-plan](docs/03-plan.md) | phases and current status |
| [09-tgcp-protocol](docs/09-tgcp-protocol.md) | the version RPC, decoded |
| [11-lobby-transport](docs/11-lobby-transport.md) | the `:17500` transport |
| [12-pak-and-lobby-protocol](docs/12-pak-and-lobby-protocol.md) | the pak XOR, and the Lua |
| [13-lobby-login](docs/13-lobby-login.md) | login and character creation |
| [14-lobby-reached](docs/14-lobby-reached.md) | reaching the lobby |
| [15-server-architecture](docs/15-server-architecture.md) | the real server design |
| [16-hosting](docs/16-hosting.md) | hosting it on a VPS, safely |
| [17-match-handoff](docs/17-match-handoff.md) | `EnterBattle` — lobby → game server |

---

## Roadmap

- [x] Clear the forced-update gate
- [x] Decode the lobby transport
- [x] Open the `.pak`, recover the lobby protocol
- [x] Login, character creation, enter the lobby
- [x] Persistent accounts and inventory ([15](docs/15-server-architecture.md))
- [x] Admin CLI — players, items, level, currency, bans, invites
- [x] Match handoff: `on_match_req` → `re_enter_game` → `EnterBattle` ([17](docs/17-match-handoff.md))
- [ ] UE4 game server bring-up: handshake → `NMT_Login` → `NMT_Welcome`
- [ ] Replication: GameState, PlayerController, a Pawn
- [ ] Two clients in one match

---

## Legal and scope

This is a preservation and learning project for a dead 2018 build, intended for
private use with a copy of the game you already own.

- No game assets are redistributed here.
- Nothing in this repo targets, interferes with, or interoperates with Tencent's
  live services or any current version of the game.
- Anti-cheat and client protection libraries are explicitly **out of scope** and
  are not analysed or modified.
- `PUBG` and `PUBG MOBILE` are trademarks of their respective owners. This
  project is unaffiliated with and unendorsed by Tencent, KRAFTON or PUBG Corp.

## Contributing

Keep game content out of commits, keep the confidence tags honest, and add a
test vector whenever you pin down a wire format.

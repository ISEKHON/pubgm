# 16 — Hosting the server on the internet

How to run this on a VPS so a group can play from anywhere, and what changes
once the port is reachable by strangers rather than just your living room.

## What a player actually needs

Three things resolve/connect to your server:

| what | port | protocol |
|---|---|---|
| version / update gate | 8085, 8086 | TCP |
| lobby | 17500 | TCP |
| DNS (only if you use the DNS method) | 53 | UDP |

The client finds the lobby by resolving `lobby.igamecj.com`, so every player's
device has to be told that name points at your server. Two ways:

**A. DNS.** Player sets their device's DNS to your server's IP. No root. This is
the only approach that scales to friends who are not technical.

**B. hosts file.** Needs root on the device. Fine for your own emulator,
impractical for a group.

**C. VPN (recommended for a small group).** Run WireGuard on the VPS, hand each
friend a config. Inside the tunnel you control DNS entirely, nothing game-
related is exposed to the internet, and admission is controlled by who holds a
key rather than by an allowlist. More setup, much less exposure.

## The security problem you inherit

**The client's `openid` is self-asserted.** It comes from the local guest login
and the server cannot verify it. On a LAN that is irrelevant. On the internet it
means anyone who finds port 17500 can claim any identity and create a character.

So the server defaults to **invite-only**:

```bash
python -I run_server.py --public-ip <VPS_IP> --public --registration invite
```

| mode | who gets in |
|---|---|
| `open` | anybody — trusted LAN only |
| `invite` | existing accounts, plus openids you allow-listed (**default**) |
| `closed` | existing accounts only; no new characters |

Admitting someone is two steps, because you need their openid and it is printed
when they are refused:

```
[1.2.3.4:51234]    REJECTED (not_invited) openid=188039022634206504
[1.2.3.4:51234]    to admit: python -I tools/admin.py invite 188039022634206504
```

```bash
python -I tools/admin.py invite 188039022634206504 --note "Ravi"
```

No restart needed. `admin.py invites` lists them, `uninvite` revokes an unused
one, `ban` stops an account that already exists.

### Do not run an open DNS resolver

The DNS responder forwards unknown queries upstream, which is exactly what an
attacker wants for amplification. `--public` switches it to
**authoritative-only**: it answers the game's two names and returns `REFUSED`
for everything else.

Consequence: a player using your server for DNS gets *only* the game names from
it, so their device needs a second, normal DNS entry for everything else.
Android's static-DNS fields take two servers — put yours first and `1.1.1.1`
second.

## Deploying on a VPS

Any 1 GB box is plenty; the server is idle most of the time and the database is
a single SQLite file.

```bash
sudo apt update && sudo apt install -y python3 python3-pip git
pip3 install --user cryptography

git clone <your repo> /opt/pubgm && cd /opt/pubgm
sudo useradd --system --home /opt/pubgm --shell /usr/sbin/nologin pubgm
sudo chown -R pubgm:pubgm /opt/pubgm
```

### Firewall — open only what is needed

```bash
sudo ufw default deny incoming
sudo ufw allow 22/tcp
sudo ufw allow 8085,8086,17500/tcp
sudo ufw allow 53/udp          # only if using the DNS method
sudo ufw enable
```

Better still, restrict the game ports to your friends' addresses if they are
static:

```bash
sudo ufw allow from <friend-ip> to any port 17500 proto tcp
```

### Binding port 53 without running as root

```bash
sudo setcap 'cap_net_bind_service=+ep' "$(readlink -f "$(which python3)")"
```

This grants that interpreter the capability permanently — scope it to a
virtualenv's python if you would rather not grant it system-wide. If you use
the VPN approach you do not need this at all.

### systemd unit

`/etc/systemd/system/pubgm.service`:

```ini
[Unit]
Description=PUBG Mobile 0.3.2 private server
After=network-online.target

[Service]
Type=simple
User=pubgm
WorkingDirectory=/opt/pubgm
Environment=PUBGM_DB=/opt/pubgm/pubgm.db
ExecStart=/usr/bin/python3 -I run_server.py \
    --public-ip %i --public --registration invite
Restart=on-failure
RestartSec=5

# hardening -- the server needs almost nothing
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/pubgm
ProtectKernelTunables=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6
MemoryMax=512M

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now pubgm@<VPS_IP>.service
journalctl -u pubgm@<VPS_IP> -f
```

(Using a templated unit means the public IP lives in the instance name. A plain
unit with the IP written into `ExecStart` is equally fine.)

### Backups

Everything mutable is one file. SQLite's own backup command is safe while the
server is running:

```bash
sqlite3 /opt/pubgm/pubgm.db ".backup '/opt/pubgm/backup-$(date +%F).db'"
```

A daily cron job keeping a week of these is enough. Copying the file with `cp`
while the server is writing can produce a torn snapshot — use `.backup`.

## Device setup for a player

1. Install their own copy of the game.
2. Wi-Fi settings → modify network → IP settings **Static** (or the Private DNS
   field off plus static DNS), DNS 1 = your server IP, DNS 2 = `1.1.1.1`.
3. Launch, tap **Guest**, create a character.

If they are refused, send you the openid from the server log and get invited.

## Things to be aware of

- **The hardcoded fallback IP.** The client carries `49.51.43.31:17500` as a
  secondary lobby address. DNS cannot redirect a literal IP. It is only tried
  when the primary fails, so a healthy server avoids it; if you ever need to
  catch it, a NAT rule on the player's network is the only lever, and a VPN
  makes the problem disappear.
- **Some SDK traffic uses DNS-over-TLS to 8.8.8.8** and ignores your resolver.
  That is telemetry, not the lobby path, and does not affect play.
- **Scope.** This is a private server for a dead 2018 build, for people you
  know. Keep it invite-only and unadvertised. Anti-cheat is out of scope and is
  not analysed or modified; if TenProtect interferes with a private match, that
  is where this project stops.
- **Do not redistribute the game.** The repo stays free of APK/OBB/pak content;
  each player supplies their own copy.

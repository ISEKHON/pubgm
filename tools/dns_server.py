"""Tiny DNS responder so players can join without rooting their device.

The client finds the lobby by ordinary DNS, so instead of bind-mounting
/etc/hosts on every phone (which needs root), point each device's DNS at the
machine running this. It answers the game's hostnames with your server's
address and forwards everything else upstream, so normal internet keeps working.

    python -I tools/dns_server.py --answer 192.168.1.50
    python -I tools/dns_server.py --answer 10.0.2.2 --upstream 1.1.1.1

Then on the device: Wi-Fi settings -> modify network -> IP settings Static (or
"Private DNS" off + a static DNS), DNS = this machine's LAN IP.

Needs privileges to bind port 53 (Linux/macOS: sudo; Windows: run elevated, and
make sure no other resolver already holds the port).

Caveat: the client also carries a hardcoded fallback *IP* for the lobby, which
DNS cannot redirect. It is only tried when the primary name fails, so a healthy
server avoids it. See docs/15-server-architecture.md.
"""
import argparse
import socket
import struct
import sys

# Names the game resolves that we want pointed at our own server.
HOSTS = (
    "lobby.igamecj.com",
    "download.2.1375135419.igame.gcloudcs.com",
)

TYPE_A, TYPE_AAAA = 1, 28
CLASS_IN = 1


def parse_question(msg):
    """Return (qname_lower, qtype, end_offset) for the first question."""
    i = 12                                   # skip the 12-byte header
    labels = []
    while True:
        n = msg[i]
        if n == 0:
            i += 1
            break
        if n & 0xC0:                         # compression pointer in a question
            raise ValueError("compressed qname")
        labels.append(msg[i + 1:i + 1 + n].decode("ascii", "replace"))
        i += 1 + n
    qtype, _qclass = struct.unpack(">HH", msg[i:i + 4])
    return ".".join(labels).lower(), qtype, i + 4


def build_answer(msg, qend, ip, ttl):
    """Response echoing the question plus one A record (or no answer at all)."""
    tid = msg[:2]
    flags = b"\x81\x80"                      # response, recursion desired+available
    counts = struct.pack(">HHHH", 1, 1 if ip else 0, 0, 0)
    out = tid + flags + counts + msg[12:qend]
    if ip:
        out += (b"\xc0\x0c"                  # pointer back to the question name
                + struct.pack(">HHIH", TYPE_A, CLASS_IN, ttl, 4)
                + socket.inet_aton(ip))
    return out


def build_refused(msg, qend):
    """REFUSED, so an exposed server is not a usable open resolver."""
    return msg[:2] + b"\x81\x85" + struct.pack(">HHHH", 1, 0, 0, 0) + msg[12:qend]


def forward(msg, upstream, timeout):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.settimeout(timeout)
        s.sendto(msg, (upstream, 53))
        return s.recvfrom(4096)[0]


def serve(cfg):
    overrides = {h.lower() for h in cfg.host}
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.bind((cfg.bind, cfg.port))
    except PermissionError:
        raise SystemExit(f"cannot bind port {cfg.port}: run with privileges") from None
    except OSError as e:
        raise SystemExit(f"cannot bind {cfg.bind}:{cfg.port}: {e}") from None

    print(f"DNS on {cfg.bind}:{cfg.port} -> {cfg.answer} for:", flush=True)
    for h in sorted(overrides):
        print(f"    {h}", flush=True)
    if cfg.authoritative_only:
        print("everything else: REFUSED (not an open resolver)", flush=True)
    else:
        print(f"forwarding everything else to {cfg.upstream}", flush=True)
        print("  ! do not expose this to the internet without "
              "--authoritative-only", flush=True)

    while True:
        try:
            msg, peer = sock.recvfrom(4096)
            if len(msg) < 13:
                continue
            try:
                qname, qtype, qend = parse_question(msg)
            except (ValueError, IndexError):
                continue

            if qname in overrides:
                # Answer A; for AAAA reply with no answer so the client falls
                # back to IPv4 instead of waiting for a timeout.
                ip = cfg.answer if qtype == TYPE_A else None
                sock.sendto(build_answer(msg, qend, ip, cfg.ttl), peer)
                print(f"  {qname} [{qtype}] -> {ip or 'no-answer'}  ({peer[0]})",
                      flush=True)
                continue

            if cfg.authoritative_only:
                # Reachable from the internet: answer only our own names and
                # refuse the rest, rather than resolving for strangers.
                sock.sendto(build_refused(msg, qend), peer)
                continue
            try:
                sock.sendto(forward(msg, cfg.upstream, cfg.timeout), peer)
            except (socket.timeout, OSError):
                pass                          # drop; the client will retry
        except KeyboardInterrupt:
            print("\nstopped")
            return
        except Exception as e:                # never let one bad packet kill it
            print(f"  ! {e!r}", file=sys.stderr, flush=True)


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--answer", required=True,
                    help="IP to return for the game hosts (this machine's LAN IP)")
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=53)
    ap.add_argument("--upstream", default="1.1.1.1", help="forward other queries here")
    ap.add_argument("--ttl", type=int, default=60)
    ap.add_argument("--timeout", type=float, default=3.0)
    ap.add_argument("--host", action="append", default=list(HOSTS),
                    help="extra hostname to override (repeatable)")
    ap.add_argument("--authoritative-only", action="store_true",
                    help="REFUSE anything that is not one of our hostnames,"
                         " instead of forwarding. Use this whenever the port is"
                         " reachable from the internet, so the server is not an"
                         " open resolver.")
    return ap.parse_args(argv)


if __name__ == "__main__":
    serve(parse_args())

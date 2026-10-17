"""Start the whole private server: update gate, lobby, and optionally DNS.

    python -I run_server.py --lan-ip 192.168.1.50
    python -I run_server.py --lan-ip 10.0.2.2 --no-dns        # emulator + hosts file
    python -I run_server.py --lan-ip 192.168.1.50 --starting-gold 10000

--lan-ip is the address *players' devices* use to reach this machine. For an
Android emulator on the same box that is 10.0.2.2; for real devices on your
network it is this machine's LAN IP.

With DNS enabled (the default) players only have to set their device's DNS to
this machine -- no root needed. Port 53 needs privileges, so either run
elevated or pass --no-dns and use the /etc/hosts bind-mount instead.

See README.md and docs/15-server-architecture.md.
"""
import argparse
import asyncio
import os
import sys
import threading

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "tools"))
import dns_server      # noqa: E402
import lobby_server    # noqa: E402
import tgcp_server     # noqa: E402


class Cfg(argparse.Namespace):
    """argparse-compatible holder so the sub-servers keep their own CLIs."""


def start_dns(a):
    cfg = Cfg(answer=a.public_ip, bind=a.bind, port=a.dns_port,
              upstream=a.dns_upstream, ttl=60, timeout=3.0,
              host=list(dns_server.HOSTS),
              authoritative_only=a.public)
    t = threading.Thread(target=dns_server.serve, args=(cfg,), daemon=True)
    t.start()
    return t


async def main_async(a):
    version = Cfg(bind=a.bind, ports=[8085, 8086], advertise=a.public_ip,
                  update_type=0)
    lobby = Cfg(bind=a.bind, port=a.lobby_port, db=a.db,
                starting_gold=a.starting_gold, login_reply=None,
                registration=a.registration,
                match_ip=a.match_ip or a.public_ip, match_port=a.match_port,
                match_delay=a.match_delay, ping_port=a.ping_port)
    print("=" * 64)
    print(f"  players reach this machine at : {a.public_ip}")
    print(f"  database                      : {os.path.abspath(a.db)}")
    print(f"  registration                  : {a.registration}")
    print(f"  DNS                           : "
          f"{'off (use /etc/hosts)' if a.no_dns else 'port %d%s' % (a.dns_port, ' [authoritative-only]' if a.public else '')}")
    if a.public and a.registration == "open":
        print("  ! WARNING: --public with open registration lets anyone who")
        print("  ! finds this port create a character. Use --registration invite.")
    print("=" * 64, flush=True)
    await asyncio.gather(tgcp_server.serve(version), lobby_server.serve(lobby))


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--public-ip", "--lan-ip", dest="public_ip", required=True,
                    help="address players' devices use to reach this machine:"
                         " 10.0.2.2 for a local emulator, your LAN IP on a"
                         " home network, or the VPS's public IP when hosted")
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--db", default=os.environ.get("PUBGM_DB", "pubgm.db"))
    ap.add_argument("--starting-gold", type=int, default=0)
    ap.add_argument("--lobby-port", type=int, default=17500)
    ap.add_argument("--registration", default="invite",
                    choices=("open", "invite", "closed"),
                    help="who may create an account (default: invite)")
    ap.add_argument("--public", action="store_true",
                    help="this server is reachable from the internet: makes DNS"
                         " authoritative-only and warns about unsafe settings")
    ap.add_argument("--match-ip", default=None,
                    help="address of the UE4 game server handed to clients"
                         " (default: same as --public-ip)")
    ap.add_argument("--match-port", type=int, default=7777)
    ap.add_argument("--ping-port", type=int, default=17000)
    ap.add_argument("--match-delay", type=float, default=3.0,
                    help="seconds between on_match_success and enter_game")
    ap.add_argument("--no-dns", action="store_true",
                    help="do not run the DNS responder")
    ap.add_argument("--dns-port", type=int, default=53)
    ap.add_argument("--dns-upstream", default="1.1.1.1")
    return ap.parse_args(argv)


if __name__ == "__main__":
    args = parse_args()
    if not args.no_dns:
        try:
            start_dns(args)
        except SystemExit as e:
            print(f"DNS not started: {e}\n"
                  f"continuing without it; use the /etc/hosts redirect instead",
                  flush=True)
    try:
        asyncio.run(main_async(args))
    except KeyboardInterrupt:
        print("\nstopped")

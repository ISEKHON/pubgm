"""UDP latency-ping responder for zone selection (the `tpingsvr`).

Before a match the client pings each zone from `sync_match_zone_list` to pick
the closest one. Advertise a zone whose `tpingsvr_ip`/`tpingsvr_port` point
here (see tools/lobby_server.py) or the client falls back to a hardcoded
address and the zone never resolves.

    python -I tools/ping_server.py [--port 17000]

Protocol, read off a capture of the real service (docs/17-match-handoff.md):

    client -> server   <seq u32 LE> 0x41          (5 bytes,  'A')
    server -> client   <seq u32 LE> 0x42 00000000 (8 bytes,  'B')

The sequence number is echoed so the client can match the reply to its probe
and derive a round-trip time; the trailing four bytes were zero in every
observed reply.
"""
import argparse
import socket
import struct

REQ_TAG, RSP_TAG = 0x41, 0x42


def serve(cfg, ready=None):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((cfg.bind, cfg.port))
    print(f"ping server on {cfg.bind}:{cfg.port}", flush=True)
    if ready:
        ready.set_result(cfg.port)
    seen = 0
    while True:
        try:
            msg, peer = sock.recvfrom(512)
        except OSError:
            continue
        if len(msg) < 5 or msg[4] != REQ_TAG:
            print(f"  ? {peer[0]}:{peer[1]} unexpected {msg[:16].hex()}", flush=True)
            continue
        seq = struct.unpack_from("<I", msg, 0)[0]
        sock.sendto(struct.pack("<IBI", seq, RSP_TAG, 0), peer)
        seen += 1
        if seen <= 5 or seen % 50 == 0:
            print(f"  ping #{seen} seq={seq} from {peer[0]}:{peer[1]}", flush=True)


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=17000)
    return ap.parse_args(argv)


if __name__ == "__main__":
    try:
        serve(parse_args())
    except KeyboardInterrupt:
        print("\nstopped")

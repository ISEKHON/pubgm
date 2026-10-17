"""Extract TCP streams from a pcap, one file per direction.

    python -I tools/pcap_tcp.py cap.pcap outdir/ [port ...]

Lists every TCP connection (with payload byte counts); for connections on the
given ports writes <outdir>/<n>_<client>_<server>_{c2s,s2c}.bin, reassembled by
sequence number. `tcpdump -i any` sees each segment more than once (lo + the
real interface), so duplicates are dropped by sequence number.
"""
import collections
import os
import socket
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pcap_http import packets, strip_link  # noqa: E402


def segments(path):
    for link, raw in packets(path):
        ip, eth = strip_link(link, raw)
        if eth != 0x0800 or len(ip) < 20 or ip[9] != 6:
            continue
        ihl = (ip[0] & 0xF) * 4
        tot = struct.unpack(">H", ip[2:4])[0]
        tcp = ip[ihl:tot]
        if len(tcp) < 20:
            continue
        sp, dp, seq = struct.unpack(">HHI", tcp[:8])
        flags = tcp[13]
        body = tcp[(tcp[12] >> 4) * 4:]
        yield (socket.inet_ntoa(ip[12:16]), sp, socket.inet_ntoa(ip[16:20]), dp,
               seq, flags, body)


def main():
    path, outdir = sys.argv[1], sys.argv[2]
    ports = {int(p) for p in sys.argv[3:]}
    conns = collections.OrderedDict()      # canonical (client, server) -> info
    for src, sp, dst, dp, seq, flags, body in segments(path):
        a, b = (src, sp), (dst, dp)
        if flags & 0x12 == 0x02:           # SYN without ACK: a is the client
            conns.setdefault((a, b), {"c2s": {}, "s2c": {}})
        if (a, b) in conns:
            d = conns[(a, b)]["c2s"]
        elif (b, a) in conns:
            d = conns[(b, a)]["s2c"]
        else:                              # started before the capture
            conns.setdefault((a, b), {"c2s": {}, "s2c": {}})
            d = conns[(a, b)]["c2s"]
        if body:
            d.setdefault(seq, body)

    os.makedirs(outdir, exist_ok=True)
    for n, ((c, s), info) in enumerate(conns.items()):
        data = {}
        for k in ("c2s", "s2c"):
            segs = sorted(info[k].items())
            out, nxt = bytearray(), None
            for seq, body in segs:
                if nxt is not None and seq < nxt:          # overlap/retransmit
                    body = body[nxt - seq:]
                out += body
                nxt = seq + len(body) if nxt is None or seq >= nxt else nxt + len(body)
            data[k] = bytes(out)
        print(f"{n:3} {c[0]}:{c[1]} -> {s[0]}:{s[1]}  c2s {len(data['c2s'])}  "
              f"s2c {len(data['s2c'])}")
        if s[1] in ports or c[1] in ports:
            base = os.path.join(outdir, f"{n}_{c[1]}_{s[0]}_{s[1]}")
            for k in ("c2s", "s2c"):
                with open(f"{base}_{k}.bin", "wb") as f:
                    f.write(data[k])


if __name__ == "__main__":
    main()

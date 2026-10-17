"""Summarise a pcap: DNS queries, HTTP requests/responses, and endpoints.

Written because there is no tshark on this host. Handles LINUX_SLL /
LINUX_SLL2 (what `tcpdump -i any` produces on Android).
"""
import collections
import socket
import struct
import sys


def packets(path):
    f = open(path, 'rb')
    gh = f.read(24)
    magic, = struct.unpack('<I', gh[:4])
    if magic == 0xa1b2c3d4:
        end = '<'
    elif magic == 0xd4c3b2a1:
        end = '>'
    else:
        raise SystemExit(f'not a pcap (magic {magic:#x})')
    link, = struct.unpack(end + 'I', gh[20:24])
    while True:
        ph = f.read(16)
        if len(ph) < 16:
            return
        _s, _u, incl, _orig = struct.unpack(end + 'IIII', ph)
        data = f.read(incl)
        if len(data) < incl:
            return
        yield link, data


def strip_link(link, d):
    if link == 113:                      # LINUX_SLL
        return d[16:], struct.unpack('>H', d[14:16])[0]
    if link == 276:                      # LINUX_SLL2
        return d[20:], struct.unpack('>H', d[0:2])[0]
    if link == 1:                        # Ethernet
        return d[14:], struct.unpack('>H', d[12:14])[0]
    if link == 101:                      # RAW IP
        return d, 0x0800
    return d, 0x0800


def dns_name(b, p):
    out = []
    hops = 0
    while p < len(b):
        n = b[p]
        if n == 0:
            break
        if n & 0xC0 == 0xC0:             # compression pointer
            if hops > 5:
                break
            p = ((n & 0x3F) << 8) | b[p + 1]
            hops += 1
            continue
        out.append(b[p + 1:p + 1 + n].decode('ascii', 'replace'))
        p += 1 + n
    return '.'.join(out)


def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass
    path = sys.argv[1]
    dns = collections.Counter()
    http = []
    endpoints = collections.Counter()
    streams = collections.defaultdict(bytes)

    for link, raw in packets(path):
        ip, eth = strip_link(link, raw)
        if eth != 0x0800 or len(ip) < 20:
            continue
        ihl = (ip[0] & 0xF) * 4
        proto = ip[9]
        src = socket.inet_ntoa(ip[12:16])
        dst = socket.inet_ntoa(ip[16:20])
        pl = ip[ihl:]
        if proto == 17 and len(pl) >= 8:                      # UDP
            sp, dp = struct.unpack('>HH', pl[:4])
            body = pl[8:]
            if dp == 53 and len(body) > 12:
                dns[dns_name(body, 12)] += 1
            else:
                endpoints[f'UDP {dst}:{dp}'] += 1
        elif proto == 6 and len(pl) >= 20:                    # TCP
            sp, dp = struct.unpack('>HH', pl[:4])
            off = (pl[12] >> 4) * 4
            body = pl[off:]
            endpoints[f'TCP {dst}:{dp}'] += 1
            if not body:
                continue
            key = (src, sp, dst, dp)
            streams[key] = (streams[key] + body)[:8192]

    # pull request lines + Host headers out of reassembled-ish streams
    for (src, sp, dst, dp), b in streams.items():
        if not (b[:4] in (b'GET ', b'POST', b'HEAD', b'PUT ') or b[:5] == b'HTTP/'):
            continue
        try:
            head = b.split(b'\r\n\r\n', 1)[0].decode('latin-1')
        except Exception:
            continue
        lines = head.split('\r\n')
        first = lines[0]
        host = next((l.split(':', 1)[1].strip() for l in lines
                     if l.lower().startswith('host:')), '')
        http.append((dst if dp != 0 else src, dp, first, host, b))

    print(f'=== DNS queries ({len(dns)} unique) ===')
    for n, c in dns.most_common(40):
        print(f'  {c:4}  {n}')

    print(f'\n=== HTTP messages ({len(http)}) ===')
    for dst, dp, first, host, b in http:
        print(f'  -> {host or dst}:{dp}  {first}')

    print('\n=== top endpoints ===')
    for e, c in endpoints.most_common(25):
        print(f'  {c:5}  {e}')

    # dump any HTTP bodies that look like version/update payloads
    print('\n=== bodies mentioning version/update ===')
    for dst, dp, first, host, b in http:
        low = b.lower()
        if b'version' in low or b'update' in low:
            txt = b.decode('latin-1')[:900]
            print(f'  --- {host} {first} ---')
            print('   ', txt.replace('\r\n', '\n    ')[:900])


if __name__ == '__main__':
    main()

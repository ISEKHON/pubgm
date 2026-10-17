"""Read the PUBG Mobile 0.3.2 UE4 .pak inside the OBB, in place.

Nothing is extracted: the OBB sits uncompressed inside the XAPK and the .pak
sits uncompressed inside the OBB, so both can be addressed by absolute offset.

Tencent deviations from stock UE4 pak v4:

1. The footer magic is 0x20171216 (a date) instead of UE4's 0x5A6F12E1, so
   stock UE4 pak tools reject the file. The rest of the footer is standard,
   including the 4.16+ 1-byte encrypted-index flag, making the footer 45 bytes:
       bEncryptedIndex(1) Magic(4) Version(4) IndexOffset(8) IndexSize(8) Hash(20)
2. Every entry is flagged encrypted, but the payload is **not** AES: it is a
   single-byte XOR with 0x79. Stock UE4 would use AES-256; Tencent replaced it.
   Confirmed because Engine/Config/Base.ini decodes to its exact known stock
   contents, and compressed entries inflate cleanly after the XOR.

Each entry begins with a plaintext inline FPakEntry header (Offset, Size,
UncompressedSize, CompressionMethod, Hash[20], [blocks], bEncrypted,
CompressionBlockSize), followed by the XORed payload. Compression method 1 is
zlib, with absolute block offsets listed in the header.

    python -I tools/pak_tool.py                       # summary + write filelist
    python -I tools/pak_tool.py --cat <name>          # print one file
    python -I tools/pak_tool.py --extract <glob> <outdir>
"""
import fnmatch
import io
import os
import struct
import sys
import zipfile
import zlib

XOR_KEY = 0x79

PAK_MAGIC_TENCENT = 0x20171216
PAK_MAGIC_STOCK = 0x5A6F12E1
FOOTER = 45


class Window(io.RawIOBase):
    """A seekable read-only view onto part of a file."""
    def __init__(self, f, off, size):
        self.f, self.off, self.size, self.p = f, off, size, 0
    def readable(self): return True
    def seekable(self): return True
    def seek(self, o, w=0):
        self.p = o if w == 0 else (self.p + o if w == 1 else self.size + o)
        return self.p
    def tell(self): return self.p
    def readinto(self, b):
        self.f.seek(self.off + self.p)
        n = min(len(b), self.size - self.p)
        d = self.f.read(n)
        b[:len(d)] = d
        self.p += len(d)
        return len(d)


def locate_pak(xapk_path):
    """Return (file, absolute_offset, size) for the .pak inside the OBB."""
    f = open(xapk_path, 'rb')
    z = zipfile.ZipFile(xapk_path)
    oi = [x for x in z.infolist() if x.filename.lower().endswith('.obb')][0]
    if oi.compress_type != 0:
        raise SystemExit('OBB is compressed; in-place addressing not possible')
    f.seek(oi.header_offset)
    lh = f.read(30)
    nlen, elen = struct.unpack('<HH', lh[26:30])
    obb_off = oi.header_offset + 30 + nlen + elen

    oz = zipfile.ZipFile(io.BufferedReader(Window(f, obb_off, oi.file_size)))
    pi = [x for x in oz.infolist() if x.filename.endswith('.pak')][0]
    if pi.compress_type != 0:
        raise SystemExit('pak is compressed inside the OBB')
    f.seek(obb_off + pi.header_offset)
    plh = f.read(30)
    pn, pe = struct.unpack('<HH', plh[26:30])
    return f, obb_off + pi.header_offset + 30 + pn + pe, pi.file_size, pi.filename


def read_footer(f, pak_off, pak_size):
    f.seek(pak_off + pak_size - FOOTER)
    d = f.read(FOOTER)
    enc = d[0]
    magic, ver, ioff, isize = struct.unpack('<IIqq', d[1:25])
    return {'encrypted_index': enc, 'magic': magic, 'version': ver,
            'index_offset': ioff, 'index_size': isize, 'index_hash': d[25:45].hex()}


def read_fstring(b, p):
    (n,) = struct.unpack_from('<i', b, p)
    p += 4
    if n == 0:
        return '', p
    if n < 0:                       # UTF-16
        n = -n
        s = b[p:p + n * 2].decode('utf-16-le', 'replace').rstrip('\0')
        return s, p + n * 2
    s = b[p:p + n].decode('utf-8', 'replace').rstrip('\0')
    return s, p + n


def parse_index(idx, version):
    mount, p = read_fstring(idx, 0)
    (count,) = struct.unpack_from('<i', idx, p)
    p += 4
    entries = []
    for _ in range(count):
        name, p = read_fstring(idx, p)
        off, size, usize, method = struct.unpack_from('<qqqi', idx, p)
        p += 28
        p += 20                                     # sha1
        if method != 0:
            (nblocks,) = struct.unpack_from('<i', idx, p)
            p += 4 + nblocks * 16
        enc, blocksize = struct.unpack_from('<BI', idx, p)
        p += 5
        entries.append({'name': name, 'offset': off, 'size': size,
                        'usize': usize, 'method': method, 'encrypted': enc,
                        'blocksize': blocksize})
    return mount, entries


def read_inline_header(f, pak_off, entry_off):
    """Parse the plaintext FPakEntry header stored at the entry's offset.

    Returns a dict including `hdr`, the header's size, so the payload begins at
    entry_off + hdr. Block offsets are absolute within the pak.
    """
    f.seek(pak_off + entry_off)
    d = f.read(64)
    off, size, usize, method = struct.unpack('<qqqi', d[:28])
    if method != 0:
        # header grows by 16 bytes per compression block; re-read enough
        (nb,) = struct.unpack_from('<i', d, 48)
        f.seek(pak_off + entry_off)
        d = f.read(53 + 4 + nb * 16 + 8)
    p = 28 + 20                                  # skip the 20-byte hash
    blocks = []
    if method != 0:
        (nb,) = struct.unpack_from('<i', d, p)
        p += 4
        for _ in range(nb):
            s, e = struct.unpack_from('<qq', d, p)
            p += 16
            blocks.append((s, e))
    enc = d[p]
    p += 1
    (bs,) = struct.unpack_from('<I', d, p)
    p += 4
    return {'hdr': p, 'offset': off, 'size': size, 'usize': usize,
            'method': method, 'encrypted': enc, 'blocks': blocks, 'blocksize': bs}


def unxor(b):
    return bytes(x ^ XOR_KEY for x in b)


def extract_entry(f, pak_off, entry_off):
    """Return the decrypted, decompressed contents of one pak entry."""
    m = read_inline_header(f, pak_off, entry_off)
    if m['method'] == 0:
        f.seek(pak_off + entry_off + m['hdr'])
        data = f.read(m['size'])
        if m['encrypted']:
            data = unxor(data)
        return data[:m['usize']]
    out = b''
    for s, e in m['blocks']:
        f.seek(pak_off + s)
        raw = f.read(e - s)
        if m['encrypted']:
            raw = unxor(raw)
        out += zlib.decompress(raw)
    return out[:m['usize']]


def load_index(f, pak_off, pak_size):
    ft = read_footer(f, pak_off, pak_size)
    f.seek(pak_off + ft['index_offset'])
    idx = f.read(ft['index_size'])
    return parse_index(idx, ft['version'])


def cmd_cat(xapk, name):
    f, off, size, _ = locate_pak(xapk)
    _, entries = load_index(f, off, size)
    hits = [e for e in entries if e['name'] == name or e['name'].endswith('/' + name)]
    if not hits:
        hits = [e for e in entries if fnmatch.fnmatch(e['name'], name)]
    if not hits:
        raise SystemExit(f'no entry matching {name!r}')
    for e in hits[:5]:
        data = extract_entry(f, off, e['offset'])
        sys.stdout.write(f'===== {e["name"]} ({len(data)} bytes)\n')
        sys.stdout.write(data.decode('utf-8', 'replace'))
        sys.stdout.write('\n')


def cmd_extract(xapk, pattern, outdir):
    f, off, size, _ = locate_pak(xapk)
    _, entries = load_index(f, off, size)
    hits = [e for e in entries if fnmatch.fnmatch(e['name'], pattern)]
    print(f'{len(hits)} entries match {pattern!r}')
    n = 0
    for e in hits:
        dest = os.path.join(outdir, e['name'].replace('\\', '/'))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        try:
            data = extract_entry(f, off, e['offset'])
        except (zlib.error, struct.error) as ex:
            print(f'  FAIL {e["name"]}: {ex!r}')
            continue
        with open(dest, 'wb') as o:
            o.write(data)
        n += 1
    print(f'wrote {n} files to {outdir}')


def cmd_grep(xapk, needles, name_glob='*'):
    """Scan every matching entry's decrypted contents for any of `needles`.

    Reports `file: needle` per hit. Decompresses as it goes, so a full pass over
    all 28k entries takes a few minutes.
    """
    f, off, size, _ = locate_pak(xapk)
    _, entries = load_index(f, off, size)
    pats = [n.encode() if isinstance(n, str) else n for n in needles]
    # also look for UTF-16LE, which is how UE4 stores many asset strings
    pats += [p.decode('latin-1').encode('utf-16-le') for p in list(pats)]
    todo = [e for e in entries if fnmatch.fnmatch(e['name'], name_glob)]
    print(f'scanning {len(todo)} entries for {len(needles)} needles', flush=True)
    hits = 0
    for i, e in enumerate(todo):
        if i % 2000 == 0:
            print(f'  ... {i}/{len(todo)}', flush=True)
        try:
            data = extract_entry(f, off, e['offset'])
        except (zlib.error, struct.error, MemoryError):
            continue
        for p in pats:
            if p in data:
                try:
                    shown = p.decode('utf-16-le')
                except UnicodeDecodeError:
                    shown = p.decode('latin-1')
                print(f'HIT {e["name"]}  <- {shown!r}'.encode(
                    sys.stdout.encoding or 'utf-8', 'replace').decode(
                    sys.stdout.encoding or 'utf-8', 'replace'), flush=True)
                hits += 1
                break
    print(f'done, {hits} files matched')


def main():  # noqa: C901
    if len(sys.argv) > 1 and sys.argv[1] == '--grep':
        glob = sys.argv[3] if len(sys.argv) > 3 else '*'
        return cmd_grep('pubg-mobile-0-3-2.xapk', sys.argv[2].split(','), glob)
    if len(sys.argv) > 1 and sys.argv[1] == '--cat':
        return cmd_cat('pubg-mobile-0-3-2.xapk', sys.argv[2])
    if len(sys.argv) > 1 and sys.argv[1] == '--extract':
        return cmd_extract('pubg-mobile-0-3-2.xapk', sys.argv[2], sys.argv[3])
    xapk = sys.argv[1] if len(sys.argv) > 1 else 'pubg-mobile-0-3-2.xapk'
    f, off, size, name = locate_pak(xapk)
    print(f'pak: {name}')
    print(f'  abs offset {off} size {size}')
    ft = read_footer(f, off, size)
    print(f'  magic        {ft["magic"]:#010x} '
          f'({"TENCENT-CUSTOM" if ft["magic"] == PAK_MAGIC_TENCENT else "stock" if ft["magic"] == PAK_MAGIC_STOCK else "UNKNOWN"})')
    print(f'  version      {ft["version"]}')
    print(f'  encr. index  {ft["encrypted_index"]}')
    print(f'  index        offset={ft["index_offset"]} size={ft["index_size"]}')
    print(f'  consistency  index_end + 45 == size: '
          f'{ft["index_offset"] + ft["index_size"] + FOOTER == size}')

    if ft['encrypted_index']:
        print('  INDEX IS ENCRYPTED - need the AES key before the file list is readable')
        return
    f.seek(off + ft['index_offset'])
    idx = f.read(ft['index_size'])
    mount, entries = parse_index(idx, ft['version'])
    print(f'  mount point  {mount!r}')
    print(f'  entries      {len(entries)}')
    nenc = sum(1 for e in entries if e['encrypted'])
    ncomp = sum(1 for e in entries if e['method'])
    print(f'  encrypted entries {nenc}, compressed entries {ncomp}')
    import collections
    ext = collections.Counter(e['name'].rsplit('.', 1)[-1].lower() for e in entries)
    print('  by extension:', dict(ext.most_common(12)))
    with open('recon/pak-filelist.txt', 'w', encoding='utf-8') as o:
        for e in sorted(entries, key=lambda x: x['name']):
            o.write(f"{e['offset']}\t{e['size']}\t{e['usize']}\t"
                    f"m{e['method']}\te{e['encrypted']}\t{e['name']}\n")
    print('  wrote recon/pak-filelist.txt')


if __name__ == '__main__':
    main()

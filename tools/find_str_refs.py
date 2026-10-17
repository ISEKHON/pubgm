"""Resolve PC-relative .rodata/.data references in libUE4.so (ARM32 PIC).

Investigation history - four hypotheses, three falsified
-------------------------------------------------------
This file records what did NOT work, because each dead end cost real time.

1. radare2 `/r <addr>`: must decode all 42 MB of .text; did not finish in 10
   minutes. Abandoned.
2. Thumb literal-pool form, scanned by inverting W = S - A - 4: ZERO hits on
   six strings known to be present.
3. Thumb movw/movt immediate pairs: only 144 such sites in the whole binary.
4. Absolute pointers fixed up by R_ARM_RELATIVE: zero occurrences of any
   target address as a 4-byte word, despite 568k relocations existing.

Root cause: the binary is predominantly **ARM mode**, not Thumb. Measured from
.dynsym (Thumb functions carry an odd st_value): 18,279 ARM vs 5,219 Thumb
defined STT_FUNC symbols. radare2 reports `bits 16`, which is misleading.
In ARM mode PC reads as instruction_address + 8, not + 4, and the encodings
differ entirely - so every Thumb-only scan above was structurally incapable of
finding these references.

The actual pattern, confirmed by disassembling JNI_OnLoad at 0x0088f180:

    ldr Rm, [pc, #imm]      ; literal word W, from a pool later in the function
    add Rd, pc, Rm          ; Rd = W + (add_addr + 8)

so  W = Target - (add_addr + 8).

Method: one linear pass over .text. Track the most recent `ldr Rt,[pc,#imm]`
per register; on each `add Rd, pc, Rm`, pair it with the last ldr of Rm, read
the literal, and compute the target. Register-tracking can mis-pair across a
basic-block boundary, so pairs are only accepted within PROXIMITY bytes; treat
single-site results as provisional and confirm by disassembling the site.

Usage:
    python -I tools/find_str_refs.py <elf>                   # summary
    python -I tools/find_str_refs.py <elf> <hex> [<hex>...]  # sites for targets
"""

import struct
import sys
from collections import defaultdict

PROXIMITY = 256   # max bytes between the ldr and its add


def read_sections(data):
    if data[:4] != b"\x7fELF" or data[4] != 1:
        raise SystemExit("not a 32-bit ELF")
    e_shoff, = struct.unpack_from("<I", data, 0x20)
    e_shentsize, e_shnum, e_shstrndx = struct.unpack_from("<HHH", data, 0x2E)
    if not e_shoff or not e_shnum:
        raise SystemExit("no section table")

    def shdr(i):
        return struct.unpack_from("<IIIIIIIIII", data, e_shoff + i * e_shentsize)

    hdrs = [shdr(i) for i in range(e_shnum)]
    stroff = hdrs[e_shstrndx][4]
    out = {}
    for x in hdrs:
        end = data.index(b"\0", stroff + x[0])
        out[data[stroff + x[0]:end].decode("ascii", "replace")] = \
            {"addr": x[3], "off": x[4], "size": x[5]}
    return out


def scan(blob, text_addr):
    """Return {target_addr: [add_site, ...]} for ARM PC-relative loads."""
    n = len(blob) // 4
    words = struct.unpack_from("<%dI" % n, blob, 0)
    last_ldr = {}                       # reg -> (addr, literal_addr)
    refs = defaultdict(list)
    blen = len(blob)

    for i in range(n):
        w = words[i]
        a = text_addr + (i << 2)
        # LDR Rt, [PC, #+/-imm12]  (mask leaves cond and U free)
        if (w & 0x0F7F0000) == 0x051F0000:
            rt = (w >> 12) & 0xF
            imm = w & 0xFFF
            u = (w >> 23) & 1
            lit = (a + 8 + imm) if u else (a + 8 - imm)
            last_ldr[rt] = (a, lit)
            continue
        # ADD Rd, PC, Rm  (no shift)
        if (w & 0x0FFF0FF0) == 0x008F0000:
            rm = w & 0xF
            e = last_ldr.get(rm)
            if not e:
                continue
            a_ldr, lit = e
            if not (0 < a - a_ldr <= PROXIMITY):
                continue
            li = lit - text_addr
            if li < 0 or li + 4 > blen:
                continue
            W, = struct.unpack_from("<I", blob, li)
            refs[(W + a + 8) & 0xFFFFFFFF].append(a)
    return refs


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    path = sys.argv[1]
    targets = [int(x, 16) for x in sys.argv[2:]]

    data = open(path, "rb").read()
    secs = read_sections(data)
    text = secs[".text"]
    blob = data[text["off"]:text["off"] + text["size"]]

    refs = scan(blob, text["addr"])

    def where(addr):
        for name, s in secs.items():
            if s["addr"] and s["addr"] <= addr < s["addr"] + s["size"]:
                return name
        return "?"

    total = sum(len(v) for v in refs.values())
    print("# .text addr=%#x size=%#x" % (text["addr"], text["size"]))
    print("# resolved references: %d to %d distinct targets" % (total, len(refs)))
    bysec = defaultdict(int)
    for t in refs:
        bysec[where(t)] += 1
    print("# distinct targets by section: %s" % dict(bysec))

    for t in targets:
        sites = sorted(refs.get(t, []))
        print("\n=== refs to %#x (%s) : %d site(s) ===" % (t, where(t), len(sites)))
        for a in sites[:40]:
            print("  add @ %#010x" % a)
        if len(sites) > 40:
            print("  ... %d more" % (len(sites) - 40))


if __name__ == "__main__":
    main()

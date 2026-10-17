# 02 — Tooling

How to reproduce every finding in [00-recon.md](00-recon.md). All paths are from this repo root
(`C:\Users\Jagdeep\Documents\pubgm`). Commands are written for the **Bash** shell (Git Bash),
not PowerShell.

---

## 1. Environment

| tool | status | path |
|---|---|---|
| radare2 6.1.0 | **working — primary tool** | `/c/radare2/bin/radare2` |
| Python 3.12 | working | `/c/Users/Jagdeep/AppData/Local/Programs/Python/Python312/python` |
| Java (JDK 24) | present | `C:\Program Files\Java\jdk-24` |
| Ghidra | **not installed** | fallback for heavy decompilation |
| IDA | not installed | — |

### REA MCP tools: unavailable for this target

Every REA analysis backend refuses this binary on this host. Recorded so it is not retried:

| backend | why it fails |
|---|---|
| ghidra | `GHIDRA_INSTALL_DIR` unset **and** REA's Windows Ghidra provider accepts only PE and raw 6502 — it **rejects ARM ELF outright**, so installing Ghidra would *not* enable REA |
| ida | `REA_IDA_MCP_CONFIG` unset; no IDA present |
| hopper | macOS only |
| rizin | fails with `ERR_REA_WINDOWS_NATIVE` |
| pwntools-elf | `inspect_binary_layout` supports Linux x64 only |

Consequence: **use radare2 directly via Bash.** If heavy decompilation becomes necessary,
install Ghidra and drive `analyzeHeadless` **directly** — bypassing REA, which cannot route
ARM ELF on Windows regardless.

---

## 2. Unpacking

The XAPK is a plain ZIP: `com.tencent.ig.apk` + the OBB.

```bash
cd /c/Users/Jagdeep/Documents/pubgm
python -c "
import zipfile
zipfile.ZipFile('pubg-mobile-0-3-2.xapk').extract('com.tencent.ig.apk','extracted')"

python -c "
import zipfile
z=zipfile.ZipFile('extracted/com.tencent.ig.apk')
for f in ['lib/armeabi-v7a/libUE4.so',
          'lib/armeabi-v7a/libtersafe.so',
          'lib/armeabi-v7a/libabase.so']:
    z.extract(f,'extracted/apk')"
```

Extracted artifacts live under `extracted/` and are treated as **untrusted data** — never run
an interpreter or build tool from inside that directory; always pass paths as arguments.

Primary target: `extracted/apk/lib/armeabi-v7a/libUE4.so`
(SHA-256 `1e184aea192bc8beec237137c1b05b5f51bab45b71fbccd1ed2bc55b6d3b0d3b`).

---

## 3. Identification

```bash
F=extracted/apk/lib/armeabi-v7a/libUE4.so
radare2 -qc "iI" "$F"    # arch, bits, compiler, stripped, pic
radare2 -qc "iS" "$F"    # sections: .dynsym/.dynstr/.text/.rodata
radare2 -qc "is~?" "$F"  # symbol count  -> 28480
radare2 -qc "iE~?" "$F"  # export count  -> 21108
```

## 4. Symbol table

`stripped: true` refers only to `.symtab`; **`.dynsym` survives with 28,480 symbols.**

```bash
radare2 -e scr.color=false -qc "is" "$F" > recon/symbols.txt
grep "NetworkVersion" recon/symbols.txt
grep -E "NetDriver|UAE|ActorChannel|PackageMap|Bunch" recon/symbols.txt
```

Caveat: exports are mostly statically-linked third-party code. UE4's own engine classes are
hidden-visibility and **unnamed** (`UNetConnection`, `PacketHandler`, `FRepLayout` → 0 hits).

## 5. Strings

radare2's `izz` **fails on this binary** — it returns only ~5 strings out of a 62 MB file. Do
not rely on it. Extract with Python instead:

```bash
python -I - "$F" recon/strings.txt <<'PY'
import sys,re
data=open(sys.argv[1],'rb').read()
rx=re.compile(rb'[\x20-\x7e]{5,}')
with open(sys.argv[2],'w',encoding='utf-8') as o:
    for m in rx.finditer(data):
        o.write(f'{m.start():08x} {m.group().decode("ascii")}\n')
PY
```

Yields **94,026** strings. The leading hex column is the file offset, which for this binary's
`.rodata` **equals the vaddr** (verify per-section: for the `.data` symbols,
`vaddr = paddr + 0x1000`).

> **These ASCII strings are mostly useless as anchors.** `TCHAR` on this Android build is
> 4-byte `wchar_t`, so all engine strings are **UTF-32LE** and an ASCII scan cannot see them.
> What the ASCII scan *does* find — the narrow `__FILE__` source paths — turns out to be
> **dead data**: four independent reference-resolution strategies found **zero** code
> references to any of them, because logging is stripped in this shipping build. Do not spend
> time on `.cpp` path anchors.

### 5a. UTF-32 strings — use these instead

```bash
PYTHONIOENCODING=utf-8 python -I - "$F" recon/strings_utf32.txt <<'PY'
import sys,re
d=open(sys.argv[1],'rb').read()
rx=re.compile(rb'(?:[\x20-\x7e]\x00\x00\x00){4,}')
with open(sys.argv[2],'w',encoding='utf-8') as o:
    for m in rx.finditer(d):
        o.write(f'{m.start():08x} {m.group()[::4].decode("ascii")}\n')
PY
```

Yields **31,244** strings, including every networking string that matters
(`Hello`, `Welcome`, `Challenge`, `Login`, `Join`, `SendConnectChallenge`,
`StatelessConnectHandlerComponent`, …). On Windows set `PYTHONIOENCODING=utf-8` or printing
non-ASCII raises `UnicodeEncodeError` under the cp1252 console codec.

Results are catalogued in [`recon/net-anchors.md`](../recon/net-anchors.md).

## 5b. Instruction set: the binary is mostly ARM, not Thumb

radare2 reports `bits 16`, which is **misleading**. Measured from `.dynsym` (Thumb functions
carry an odd `st_value`; undefined imports with `st_value == 0` must be excluded or they
skew the count):

| mode | defined `STT_FUNC` |
|---|---:|
| ARM (even) | **18,279** |
| Thumb (odd) | 5,219 |

This matters for every disassembly and xref decision. Disassemble with an explicit mode:

```bash
radare2 -qc "e asm.arch=arm; e asm.bits=32; s 0x0088f180; pd 36" "$F"
```

In ARM mode `PC` reads as *instruction address + 8* (not +4 as in Thumb).

## 6. Reading data values

Read static initialisers straight from the file image at a symbol's **paddr**:

```bash
python -I - "$F" <<'PY'
import sys
d=open(sys.argv[1],'rb').read()
for n,off in [('EngineNetworkProtocolVersion',0x0392eed8),
              ('GameNetworkProtocolVersion',  0x0392eedc)]:
    print(n, int.from_bytes(d[off:off+4],'little'))
PY
```

Caveat: these are **link-time** values. UE4 may overwrite statics from `.init_array` at load,
so anything read this way is provisional until confirmed in a live process.

---

## 7. What does *not* work — do not repeat

### Whole-binary radare2 analysis is not viable
```bash
# DON'T: ran ~7 min, reached 1.6 GB RSS, then hung indefinitely on project save
radare2 -qc "aa; aap; aar; Ps proj" "$F"
```
`aa`/`aap`/`aar` complete, but `Ps` (project save) hangs on a binary this size and had to be
killed. Two lessons:
1. **Never put the queries after the project save** — dump results first.
2. Prefer **targeted** analysis over whole-binary analysis.

### radare2 `/r` is also not viable
`/r <addr>` must decode all 42 MB of `.text`; it did not finish in 10 minutes and was killed.

### Use `tools/find_str_refs.py` instead

```bash
python -I tools/find_str_refs.py "$F"                   # summary
python -I tools/find_str_refs.py "$F" 033250b0 032d1058  # sites for given targets
```

Runs in ~2 s and resolves **276,577 references to 123,054 distinct targets**. The tool's
docstring records the three *falsified* hypotheses that preceded it, so they are not retried:

| hypothesis | result |
|---|---|
| Thumb literal pool, inverting `W = S - A - 4` | 0 hits on six strings known present |
| Thumb `movw`/`movt` immediate pairs | only 144 sites in the entire binary |
| Absolute pointers fixed by `R_ARM_RELATIVE` | 0 occurrences, despite 568k relocations |

The working model, confirmed by disassembling `JNI_OnLoad` at `0x0088f180`:

```
ldr Rm, [pc, #imm]      ; literal word W
add Rd, pc, Rm          ; Rd = W + (add_addr + 8)
```

so `W = Target - (add_addr + 8)`. The scan tracks the most recent `ldr Rt,[pc,#imm]` per
register and pairs it with the next `add Rd, pc, Rm`.

**Caveat:** register tracking can mis-pair across a basic-block boundary, so pairs are only
accepted within 256 bytes. Treat a single-site result as provisional and confirm it by
disassembling the site:

```bash
radare2 -qc "e asm.arch=arm; e asm.bits=32; s 0x01df914c; pd 40" "$F"
```

---

## 8. Runtime work (not yet started)

The project is **armeabi-v7a only**, so any emulator or device used for runtime analysis must
support 32-bit ARM. Runtime evidence is required to resolve:
- the real `FNetworkVersion` values (§6 caveat),
- the handshake bit layout,
- session-key establishment for the encryption component — which **cannot** be recovered from
  static analysis alone.

A packet capture of the client connecting is the highest-value next step; see
[01-protocol.md](01-protocol.md) §8.

## 9. Network tooling (TGcp / lobby)

Added while clearing the update gate and the lobby transport. All run with
`python -I` (the project treats extracted artifacts as untrusted input).

| tool | purpose |
|---|---|
| `tools/tgcp.py` | codec for the version RPC transport (TDR TLV + AES + Thrift). `--decrypt c2s.bin s2c.bin` dumps a captured session |
| `tools/tgcp_server.py` | answers the version/address RPCs so the client sees "no update" (`docs/09`) |
| `tools/lobby.py` | codec for the `:17500` lobby transport — same crypto, different frame (`docs/11`) |
| `tools/lobby_server.py` | completes the lobby handshake and logs every RPC decoded; the bring-up instrument. `--login-reply FILE` to iterate on replies |
| `tools/pak_tool.py` | reads the .pak in place inside the XAPK. `--cat`, `--extract <glob> <dir>`, `--grep <needles> [glob]`. Entries are **XOR 0x79**, not AES (`docs/12`) |
| `tools/pcap_tcp.py` | extracts TCP streams from a pcap, per direction, reassembled by sequence number; de-dups the doubled segments `tcpdump -i any` records |
| `tools/test_tgcp.py`, `tools/test_lobby.py` | round-trip suites; they re-encode the captures and compare byte-for-byte |

**The one lesson worth repeating:** both transports send the AES session key in
clear in the server's ACK. Check for that before assuming a key exchange needs
reversing — it is what turned two "large projects" into afternoons.

Second lesson: these TDR buffers use u16 big-endian lengths that **count the
NUL**. An off-by-one there surfaces only as `tdr unpack failed` (ret -18) from
the client, which looks like a crypto problem and is not. Tests that reproduce
captured bytes exactly are the cheapest guard.

#!/usr/bin/env python3
"""Print the structure of a Git index file (format version 2 or 3, SHA-1 repository).

    python3 read-index.py .git/index            header, entries, extensions, checksum
    python3 read-index.py --stat .git/index     also the cached stat data of every entry

The layout is documented in gitformat-index(5): git help gitformat-index
"""
import hashlib
import struct
import sys

show_stat = "--stat" in sys.argv[1:]
path = [a for a in sys.argv[1:] if a != "--stat"][0]
data = open(path, "rb").read()

signature, version, count = struct.unpack(">4sII", data[:12])
print(f"header     signature={signature.decode()} version={version} entries={count}")
if version not in (2, 3):
    sys.exit("this reader understands index versions 2 and 3 only")

pos = 12
for _ in range(count):
    start = pos
    ctime, ctime_ns, mtime, mtime_ns, dev, ino, mode, uid, gid, size = struct.unpack(">10I", data[pos:pos + 40])
    oid = data[pos + 40:pos + 60].hex()
    (flags,) = struct.unpack(">H", data[pos + 60:pos + 62])
    pos += 62
    extended = 0
    if flags & 0x4000:  # the "extended" bit: sixteen more flag bits follow (version 3)
        (extended,) = struct.unpack(">H", data[pos:pos + 2])
        pos += 2
    end = data.index(b"\0", pos)
    name = data[pos:end].decode()
    pos = start + ((end - start) // 8 + 1) * 8  # NUL padding to a multiple of eight bytes
    bits = [label for mask, word, label in ((0x8000, flags, "assume-valid"),
            (0x4000, extended, "skip-worktree"), (0x2000, extended, "intent-to-add")) if word & mask]
    print(f"entry      {mode:06o} {oid} stage={(flags >> 12) & 3} size={size:<5} {name}"
          + (f"  [{', '.join(bits)}]" if bits else ""))
    if show_stat:
        print(f"           ctime={ctime}.{ctime_ns:09d} mtime={mtime}.{mtime_ns:09d} "
              f"dev={dev} ino={ino} uid={uid} gid={gid}")

while pos < len(data) - 20:
    ext, length = struct.unpack(">4sI", data[pos:pos + 8])
    print(f"extension  {ext.decode()} ({length} bytes)")
    pos += 8 + length

stored = data[-20:]
if stored == bytes(20):
    print("checksum   not computed (index.skipHash)")
else:
    print("checksum  ", "valid" if hashlib.sha1(data[:-20]).digest() == stored else "MISMATCH")

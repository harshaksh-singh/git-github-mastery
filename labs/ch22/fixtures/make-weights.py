#!/usr/bin/env python3
"""Write a deterministic stand-in for a binary model file.

    make-weights.py <path> <seed> <bytes>

The content is a SHA-256 hash chain started from the seed, so it is the same on every machine and
it does not compress, which is how real model weights behave. Used by labs/ch22/fixtures/fixtures.sh.
"""
import hashlib
import pathlib
import sys

path, seed, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
out = bytearray()
block = hashlib.sha256(seed.encode("utf-8")).digest()
while len(out) < size:
    out += block
    block = hashlib.sha256(block).digest()
target = pathlib.Path(path)
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(bytes(out[:size]))

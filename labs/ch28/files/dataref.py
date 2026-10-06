#!/usr/bin/env python3
"""Version a data file by reference. Standard library only.

Git tracks a small pointer file (<data file>.ref); the bytes live in a content-addressed
store outside the repository. The store is a directory here; in production it is a bucket.

    python3 tools/dataref.py add FILE        copy FILE into the store, write FILE.ref
    python3 tools/dataref.py checkout        make every FILE match its committed FILE.ref
    python3 tools/dataref.py verify          exit 1 if a FILE is missing or differs from its pointer
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys

STORE = os.environ.get("DATAREF_STORE", "../datastore")


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def stored(digest):
    return os.path.join(STORE, "sha256", digest[:2], digest[2:])


def pointers():
    out = subprocess.run(["git", "ls-files", "-z", "--", "*.ref"], check=True, capture_output=True).stdout
    return [p for p in out.decode().split("\0") if p]


def add(path):
    digest = sha256(path)
    target = stored(digest)
    if not os.path.exists(target):
        os.makedirs(os.path.dirname(target), exist_ok=True)
        shutil.copyfile(path, target)
    pointer = {"path": os.path.basename(path), "sha256": digest, "size": os.path.getsize(path)}
    with open(path + ".ref", "w", encoding="utf-8") as handle:
        handle.write(json.dumps(pointer, indent=2, sort_keys=True) + "\n")
    print("stored %s as sha256:%s (%d bytes)" % (path, digest[:12], pointer["size"]))
    print("commit the pointer: git add %s.ref" % path)


def state(ref):
    with open(ref, encoding="utf-8") as handle:
        pointer = json.load(handle)
    path = ref[:-len(".ref")]
    if not os.path.exists(path):
        return path, pointer, "missing"
    return path, pointer, "ok" if sha256(path) == pointer["sha256"] else "differs"


def checkout():
    for ref in pointers():
        path, pointer, status = state(ref)
        if status == "ok":
            print("up to date  %s" % path)
            continue
        source = stored(pointer["sha256"])
        if not os.path.exists(source):
            print("NOT IN STORE %s sha256:%s" % (path, pointer["sha256"][:12]))
            return 1
        shutil.copyfile(source, path)
        print("restored    %s from sha256:%s" % (path, pointer["sha256"][:12]))
    return 0


def verify():
    bad = 0
    for ref in pointers():
        path, pointer, status = state(ref)
        print("%-8s %s  (pointer sha256:%s)" % (status, path, pointer["sha256"][:12]))
        bad += status != "ok"
    return 1 if bad else 0


def main(argv):
    if argv[:1] == ["add"] and len(argv) == 2:
        add(argv[1])
        return 0
    if argv == ["checkout"]:
        return checkout()
    if argv == ["verify"]:
        return verify()
    sys.stderr.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

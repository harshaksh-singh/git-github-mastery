#!/usr/bin/env python3
"""Repository checks that run identically in a local hook and in CI. Standard library only.

    python3 tools/checks.py --staged           check what the next commit would contain (hook)
    python3 tools/checks.py --range A..B       check every file version the commits in A..B add (CI)
    python3 tools/checks.py --tree REV         check every file in the snapshot of REV (CI)

Rules: no file larger than 500 kB, no notebook with outputs, no .env file, no private key,
no model weights. Each rule reads blobs from Git, never from the working tree, so it judges
exactly what is (or would be) in history.
"""
import json
import re
import subprocess
import sys

MAX_BYTES = 500_000
WEIGHTS = (".pt", ".pth", ".ckpt", ".safetensors", ".onnx", ".gguf", ".bin")
PRIVATE_KEY = re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----")


def git(*args):
    return subprocess.run(("git",) + args, check=True, capture_output=True).stdout


def problems(path, blob):
    found = []
    name = path.rsplit("/", 1)[-1]
    if len(blob) > MAX_BYTES:
        found.append("larger than %d bytes (%d)" % (MAX_BYTES, len(blob)))
    if name == ".env" or name.startswith(".env."):
        found.append("environment file")
    if path.endswith(WEIGHTS):
        found.append("model weights belong in the model store")
    if PRIVATE_KEY.search(blob):
        found.append("contains a private key")
    if path.endswith(".ipynb"):
        try:
            cells = json.loads(blob).get("cells", [])
        except ValueError:
            found.append("notebook is not valid JSON")
        else:
            if any(c.get("outputs") or c.get("execution_count") for c in cells if c.get("cell_type") == "code"):
                found.append("notebook has outputs")
    return found


def staged():
    names = git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR").decode().split("\0")
    return [("index", n, git("cat-file", "blob", ":" + n)) for n in names if n]


def in_range(spec):
    out = []
    for commit in git("rev-list", "--reverse", spec).decode().split():
        names = git("diff-tree", "--no-commit-id", "--name-only", "-r", "-z", "-m", "--root",
                    "--diff-filter=ACMR", commit).decode().split("\0")
        for name in sorted(set(n for n in names if n)):
            out.append((commit[:7], name, git("cat-file", "blob", commit + ":" + name)))
    return out


def in_tree(rev):
    names = git("ls-tree", "-r", "--name-only", "-z", rev).decode().split("\0")
    return [(rev, n, git("cat-file", "blob", rev + ":" + n)) for n in names if n]


def main(argv):
    if argv == ["--staged"]:
        items = staged()
    elif len(argv) == 2 and argv[0] == "--range":
        items = in_range(argv[1])
    elif len(argv) == 2 and argv[0] == "--tree":
        items = in_tree(argv[1])
    else:
        sys.stderr.write(__doc__)
        return 2
    failed = 0
    for where, path, blob in items:
        for problem in problems(path, blob):
            print("%s %s: %s" % (where, path, problem))
            failed += 1
    print("checks: %d file version(s) examined, %d problem(s)" % (len(items), failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

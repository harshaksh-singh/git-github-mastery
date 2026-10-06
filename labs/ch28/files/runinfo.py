#!/usr/bin/env python3
"""Record which code produced a result: the commit and whether the tree matched it.

Standard library only. Import git_state() from a training or evaluation script, or run
    python3 tools/runinfo.py [--require-clean]
to print the record as JSON.
"""
import hashlib
import json
import subprocess
import sys


def _git(*args):
    return subprocess.run(("git",) + args, check=True, capture_output=True).stdout


def git_state():
    """Return a dict that identifies the code state of the current repository."""
    commit = _git("rev-parse", "HEAD").decode().strip()
    # Porcelain v1 with NUL separators: stable across Git versions and safe for odd file names.
    status = [e for e in _git("status", "--porcelain=v1", "-z", "--untracked-files=all").decode().split("\0") if e]
    tracked = [e for e in status if not e.startswith("??")]
    untracked = [e[3:] for e in status if e.startswith("??")]
    diff = _git("diff", "HEAD", "--binary") if tracked else b""
    return {
        "commit": commit,
        "describe": _git("describe", "--always", "--dirty", "--tags").decode().strip(),
        "dirty": bool(tracked),
        "changed": tracked,
        "untracked": untracked,
        "diff_sha256": hashlib.sha256(diff).hexdigest() if diff else None,
    }


def file_sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def main(argv):
    state = git_state()
    if "--require-clean" in argv and (state["dirty"] or state["untracked"]):
        sys.stderr.write("refusing to run: the working tree does not match commit %s\n" % state["commit"][:7])
        for entry in state["changed"]:
            sys.stderr.write("  changed:   %s\n" % entry)
        for path in state["untracked"]:
            sys.stderr.write("  untracked: %s\n" % path)
        return 1
    print(json.dumps(state, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

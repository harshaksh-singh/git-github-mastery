#!/usr/bin/env python3
"""Strip outputs from Jupyter notebooks. Standard library only.

As a Git clean filter:   python3 tools/nbstrip.py            (notebook on stdin, cleaned on stdout)
As a check for CI:       python3 tools/nbstrip.py --verify FILE...   (exit 1 if a file is not clean)
"""
import json
import sys

DROP_CELL_METADATA = ("collapsed", "scrolled", "execution")


def strip(nb):
    """Remove everything that running the notebook adds. Returns the same object."""
    for cell in nb.get("cells", []):
        if cell.get("cell_type") == "code":
            cell["outputs"] = []
            cell["execution_count"] = None
        for key in DROP_CELL_METADATA:
            cell.get("metadata", {}).pop(key, None)
    nb.get("metadata", {}).pop("widgets", None)
    return nb


def dump(nb):
    # The layout Jupyter itself writes: one-space indent, keys in file order, final newline.
    return json.dumps(nb, indent=1, ensure_ascii=False) + "\n"


def main(argv):
    if argv[:1] == ["--verify"]:
        dirty = []
        for path in argv[1:]:
            with open(path, encoding="utf-8") as handle:
                text = handle.read()
            if dump(strip(json.loads(text))) != text:
                dirty.append(path)
        for path in dirty:
            print("not stripped: " + path)
        return 1 if dirty else 0
    sys.stdout.write(dump(strip(json.load(sys.stdin))))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

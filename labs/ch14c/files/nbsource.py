#!/usr/bin/env python3
"""textconv for notebooks: print only the source of each cell."""
import json
import sys

nb = json.load(open(sys.argv[1], encoding="utf-8"))
for n, cell in enumerate(nb["cells"], 1):
    print(f"# cell {n} ({cell['cell_type']})")
    print("".join(cell["source"]))

#!/usr/bin/env python3
"""clean filter for notebooks: drop outputs and execution counts (stdin to stdout)."""
import json
import sys

nb = json.load(sys.stdin)
for cell in nb["cells"]:
    if cell["cell_type"] == "code":
        cell["outputs"] = []
        cell["execution_count"] = None
json.dump(nb, sys.stdout, indent=1, sort_keys=True)
sys.stdout.write("\n")

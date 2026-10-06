#!/usr/bin/env python3
"""Evaluate the keyword baseline on the ticket data set and record what produced the result.

    python3 evals/run_eval.py RUN_NAME [--allow-dirty]

Writes runs/RUN_NAME/metrics.json and runs/RUN_NAME/run.json. Standard library only.
"""
import csv
import hashlib
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from runinfo import file_sha256, git_state  # noqa: E402
from docqa.classify import classify  # noqa: E402

CONFIG = "configs/eval.json"
LOCK = "requirements.lock"


def main(argv):
    name = argv[0]
    state = git_state()
    if state["dirty"] and "--allow-dirty" not in argv:
        sys.stderr.write("refusing a tracked run from a dirty tree: %s\n" % ", ".join(state["changed"]))
        return 1
    with open(CONFIG, encoding="utf-8") as handle:
        config = json.load(handle)
    with open(config["data"], newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    correct = sum(classify(row["text"], config["keywords"], config["default"]) == row["label"] for row in rows)
    metrics = {"accuracy": round(correct / len(rows), 4), "examples": len(rows)}
    out = os.path.join("runs", name)
    os.makedirs(out, exist_ok=True)
    record = {
        "code": state,
        "config_sha256": hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest(),
        "data": {"path": config["data"], "sha256": file_sha256(config["data"])},
        "lock_sha256": file_sha256(LOCK),
        "metrics": metrics,
        "resolved_config": config,
    }
    if state["dirty"]:
        with open(os.path.join(out, "uncommitted.patch"), "wb") as handle:
            handle.write(subprocess.run(["git", "diff", "HEAD", "--binary"], check=True, capture_output=True).stdout)
    for filename, payload in (("metrics.json", metrics), ("run.json", record)):
        with open(os.path.join(out, filename), "w", encoding="utf-8") as handle:
            handle.write(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    print("run %s: accuracy %.4f on %d examples (commit %s%s)" % (
        name, metrics["accuracy"], metrics["examples"], state["commit"][:7], ", dirty" if state["dirty"] else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

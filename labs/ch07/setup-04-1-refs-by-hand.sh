#!/usr/bin/env bash
# Hands-on setup for Lab 4.1 (refs by hand).
# Creates $GIT_MASTERY_LABS/hands-on/m04-1/evalkit with three commits on main.
# Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m04-1

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf 'def run_batch(examples, metric):\n    return [metric(e.pred, e.gold) for e in examples]\n' > evalkit/runner.py
quiet 'git add . && git commit -m "Add batch runner"'

printf 'Lab 4.1 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m04-1\n'
printf 'Then:                cd evalkit\n'

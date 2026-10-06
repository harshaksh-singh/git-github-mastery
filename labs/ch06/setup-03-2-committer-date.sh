#!/usr/bin/env bash
# Hands-on setup for Lab 3.2 (change only the committer date and watch the ID change).
# Creates $GIT_MASTERY_LABS/hands-on/m03-2/evalkit with two commits and a clean working tree.
# Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m03-2

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
quiet 'git commit -am "Add F1 metric"'

printf 'Lab 3.2 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m03-2\n'
printf 'Then:                cd evalkit\n'

#!/usr/bin/env bash
# Hands-on setup for Lab 3.1 (amend a commit and find the old one).
# Creates $GIT_MASTERY_LABS/hands-on/m03-1/evalkit with two commits. The second commit has a
# typo in its message and forgot the test file, which is still untracked in the working tree.
# Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m03-1

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit tests
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
printf 'from evalkit.metrics import f1\n\n\ndef test_f1_empty():\n    assert f1("", "") == 0.0\n' > tests/test_metrics.py
quiet 'git add evalkit/metrics.py && git commit -m "Add F1 metrc"'

printf 'Lab 3.1 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m03-1\n'
printf 'Then:                cd evalkit\n'

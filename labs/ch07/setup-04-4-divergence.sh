#!/usr/bin/env bash
# Hands-on setup for Lab 4.4 (counting divergence).
# Creates $GIT_MASTERY_LABS/hands-on/m04-4/evalkit with main and three branches:
#   feature/rouge     diverged from main
#   docs/quickstart   strictly ahead of main (main can fast-forward to it)
#   fix/strip         already contained in main
# Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m04-4

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred == gold)\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
quiet 'git switch -c feature/rouge'
printf 'def rouge_l(pred, gold):\n    raise NotImplementedError\n' > evalkit/rouge.py
quiet 'git add . && git commit -m "Add ROUGE-L metric"'
printf 'def lcs(a, b):\n    return 0\n\n\ndef rouge_l(pred, gold):\n    return lcs(pred.split(), gold.split())\n' > evalkit/rouge.py
quiet 'git commit -am "ROUGE-L: tokenize on whitespace"'
printf 'def test_rouge_l_identical():\n    pass\n' > test_rouge.py
quiet 'git add . && git commit -m "ROUGE-L: add tests"'
quiet 'git switch -c fix/strip main'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git commit -am "Exact match: strip whitespace"'
quiet 'git switch main'
quiet 'git merge --ff-only fix/strip'
printf 'name: ci\n' > ci.yaml
quiet 'git add . && git commit -m "Add CI workflow"'
quiet 'git switch -c docs/quickstart'
printf '\n## Quickstart\n\npython -m evalkit run examples.jsonl\n' >> README.md
quiet 'git commit -am "Add quickstart to README"'
quiet 'git switch main'

printf 'Lab 4.4 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m04-4\n'
printf 'Then:                cd evalkit\n'

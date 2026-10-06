#!/usr/bin/env bash
# Lab 4.4 replay: count how far branches have diverged, test ancestry, predict which merges can
# fast-forward, and see three ways a divergence count goes wrong.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 lab-04-4-divergence

# --- same steps as setup-04-4-divergence.sh
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
# --- end of setup

snip 01-graph
run 'git log --oneline --graph --all'

snip 02-diverged
run 'git merge-base main feature/rouge'
run 'git rev-list --left-right --count main...feature/rouge'
run 'git log --oneline main..feature/rouge'
run 'git log --oneline feature/rouge..main'

snip 03-ancestry
run 'git merge-base --is-ancestor main feature/rouge; echo "exit status: $?"'
run 'git merge-base --is-ancestor main docs/quickstart; echo "exit status: $?"'
run 'git merge-base --is-ancestor fix/strip main; echo "exit status: $?"'

snip 04-table
run "git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads"

snip 05-failure
run 'git rev-list --left-right --count main..feature/rouge'
run 'git rev-list --count main...feature/rouge'
run 'git rev-list --left-right --count feature/rouge...main'

snip 06-recovery
run 'git rev-list --left-right --count main...feature/rouge'
run "git for-each-ref --format='%(ahead-behind:main)' refs/heads/feature/rouge"
run 'git rev-list --count main..feature/rouge'
run 'git rev-list --count feature/rouge..main'

snip 07-verify
run_rc 'git merge --ff-only feature/rouge'
run 'git merge --ff-only docs/quickstart'
run "git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads"

lab_end

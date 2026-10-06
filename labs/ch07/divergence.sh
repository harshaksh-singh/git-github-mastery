#!/usr/bin/env bash
# Chapter 7, section 7.8: divergence and ancestry. Merge base, two-dot and three-dot ranges,
# ahead and behind counts, and the ancestor test that decides whether a fast-forward is possible.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 divergence

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

quiet 'git switch main'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git commit -am "Exact match: strip whitespace"'
printf 'name: ci\n' > ci.yaml
quiet 'git add . && git commit -m "Add CI workflow"'

snip 01-graph
run 'git log --oneline --graph --all'

snip 02-merge-base
run 'git merge-base main feature/rouge'
run 'git log --oneline main..feature/rouge'
run 'git log --oneline feature/rouge..main'

snip 03-count
run 'git rev-list --left-right --count main...feature/rouge'
run 'git log --oneline --left-right main...feature/rouge'
run "git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads"

snip 04-ancestor
run_rc 'git merge-base --is-ancestor main feature/rouge'
run_rc 'git merge-base --is-ancestor main~2 feature/rouge'
run_rc 'git merge-base --is-ancestor main~2 main'

snip 05-diff-dots
run 'git diff --stat main...feature/rouge'
run 'git diff --stat main..feature/rouge'

lab_end

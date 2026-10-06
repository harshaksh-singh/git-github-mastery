#!/usr/bin/env bash
# Chapter 6, section 6.13 (what can go wrong): amending a commit that has already been pushed.
# The amended commit is a sibling of the pushed one, so the branch and its upstream diverge
# and a plain push is rejected. The remote is a bare repository on disk; no network is used.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 amend-pushed

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred == gold)\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git commit -am "Exact match: strp whitespace"'
quiet 'git push -u origin main'

snip 01-diverged
run 'git status -sb'
run 'git commit --amend -m "Exact match: strip whitespace"'
run 'git status -sb'
run 'git log --oneline --graph --all'

snip 02-push-rejected
run_rc 'git push'

lab_end

#!/usr/bin/env bash
# Chapter 6, section 6.10: atomic commits. Two unrelated changes sit in the working tree.
# Committed separately, each can be reverted, cherry-picked and bisected on its own.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 atomic

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf 'tokenizers==0.20.3\npyyaml==6.0.2\n' > requirements.txt
printf 'def f1(pred, gold):\n    p, g = pred.split(), gold.split()\n    common = len(set(p) & set(g))\n    precision, recall = common / len(p), common / len(g)\n    return 2 * precision * recall / (precision + recall)\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add F1 metric"'
printf 'tokenizers==0.21.0\npyyaml==6.0.2\n' > requirements.txt
printf 'def f1(pred, gold):\n    p, g = pred.split(), gold.split()\n    common = len(set(p) & set(g))\n    if common == 0:\n        return 0.0\n    precision, recall = common / len(p), common / len(g)\n    return 2 * precision * recall / (precision + recall)\n' > evalkit/metrics.py

snip 01-two-commits
run 'git status --short'
run 'git add evalkit/metrics.py'
run 'git commit -q -m "Return 0.0 from F1 when no tokens overlap"'
run 'git add requirements.txt'
run 'git commit -q -m "Bump tokenizers to 0.21.0"'
run 'git log --oneline --stat -2'

snip 02-revert-one
note 'The new tokenizers release breaks the nightly run. Undo that change only.'
run 'git revert --no-edit HEAD'
run 'cat requirements.txt'
run 'grep -n "common == 0" evalkit/metrics.py'

lab_end

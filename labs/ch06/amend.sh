#!/usr/bin/env bash
# Chapter 6, section 6.7: "git commit --amend" does not edit a commit. It creates a new one
# with the same parent, moves the branch to it, and leaves the old one in the object database,
# reachable only through the reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 amend

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit tests
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
printf 'from evalkit.metrics import f1\n\n\ndef test_f1_empty():\n    assert f1("", "") == 0.0\n' > tests/test_metrics.py

snip 01-mistake
run 'git add evalkit/metrics.py'
run 'git commit -m "Add F1 metrc"'
run 'git status --short'
run 'git log --oneline'

snip 02-amend
run 'git add tests/test_metrics.py'
run 'git commit --amend -m "Add F1 metric"'
run 'git log --oneline'

snip 03-two-objects
run 'git reflog'
run "git cat-file -p 'HEAD@{1}'"
run 'git cat-file -p HEAD'

snip 04-reachability
run "git branch --contains 'HEAD@{1}'"
run 'git log --oneline --all'
run 'git fsck --no-reflogs'

snip 05-keep-it
run "git branch before-amend 'HEAD@{1}'"
run 'git log --oneline --graph --all'

lab_end

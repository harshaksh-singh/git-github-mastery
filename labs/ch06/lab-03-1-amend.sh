#!/usr/bin/env bash
# Lab 3.1 replay: amend a commit, find the old commit through the reflog, then break things
# with an amend that swallows staged work and recover with the reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 lab-03-1-amend

# --- same steps as setup-03-1-amend.sh
quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit tests
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
printf 'from evalkit.metrics import f1\n\n\ndef test_f1_empty():\n    assert f1("", "") == 0.0\n' > tests/test_metrics.py
quiet 'git add evalkit/metrics.py && git commit -m "Add F1 metrc"'
# --- end of setup

snip 01-start
run 'git log --oneline'
run 'git status --short'
run 'git rev-parse HEAD'

snip 02-amend
run 'git add tests/test_metrics.py'
run 'git commit --amend -m "Add F1 metric"'
run 'git log --oneline'
run 'git rev-parse HEAD'

snip 03-find-old
run 'git reflog'
run "git cat-file -p 'HEAD@{1}'"
run 'git cat-file -p HEAD'

snip 04-only-the-reflog
run "git branch --contains 'HEAD@{1}'"
run 'git fsck --no-reflogs'

snip 05-failure
run "printf 'def bleu(pred, gold, max_n=4):\n    raise NotImplementedError\n' > evalkit/bleu.py"
run 'git add evalkit/bleu.py'
run "printf '\n\ndef test_f1_whitespace():\n    assert f1(\" \", \" \") == 0.0\n' >> tests/test_metrics.py"
run 'git add tests/test_metrics.py'
run 'git commit --amend --no-edit'
run "git show --stat --format='%h %s' HEAD"

snip 06-recovery
run 'git reflog -3'
run "git reset --soft 'HEAD@{1}'"
run 'git status --short'
run 'git restore --staged evalkit/bleu.py'
run 'git commit --amend --no-edit'
run "git show --stat --format='%h %s' HEAD"
run 'git status --short'

snip 07-verify
run 'git log --oneline'
run 'git reflog'
run 'git fsck --no-reflogs'

lab_end

#!/usr/bin/env bash
# Chapter 6, section 6.6: parents. A root commit has none, an ordinary commit has one,
# a merge commit has two or more. HEAD^1, HEAD^2 and HEAD~n navigate them.
# Also the "git log basics" of section 6.12.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 parents

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit tests
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf 'from evalkit.metrics import exact_match\n\n\ndef test_exact_match():\n    assert exact_match(" yes ", "yes") == 1.0\n' > tests/test_metrics.py
quiet 'git add . && git commit -m "Test exact match"'

quiet 'git switch -c feature/f1'
as asha
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
quiet 'git commit -am "Add F1 metric"'
printf '\n\ndef test_f1_empty():\n    assert f1("", "") == 0.0\n' >> tests/test_metrics.py
quiet 'git commit -am "Test F1 on empty strings"'
as you
quiet 'git switch main'
printf '\nRun the tests with: python -m pytest\n' >> README.md
quiet 'git commit -am "Document how to run the tests"'

snip 01-root
run "git log --format='%h  parents: [%p]  %s'"
run 'git rev-list --max-parents=0 HEAD'

snip 02-merge
run 'git merge --no-ff feature/f1'
run 'git cat-file -p HEAD'
run 'git log -1 --format=fuller'

snip 03-navigate
run 'git log --oneline --graph'
run "git log -1 --format='%h %s' 'HEAD^1'"
run "git log -1 --format='%h %s' 'HEAD^2'"
run "git log -1 --format='%h %s' 'HEAD~2'"
run "git log -1 --format='%h %s' 'HEAD^2~1'"
run_rc "git rev-parse --verify --quiet 'HEAD^3'"

snip 04-two-diffs
run "git diff --stat 'HEAD^1' HEAD"
run "git diff --stat 'HEAD^2' HEAD"
run 'git log --oneline --first-parent'

snip 05-log-basics
run 'git log --oneline -3'
run 'git log -1 --stat feature/f1'
run "git log --format='%h %ad %an: %s' --date=short --no-merges -3"
run 'git log --oneline -- README.md'

lab_end

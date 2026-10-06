#!/usr/bin/env bash
# Chapter 6, section 6.8: a commit whose tree equals its parent's tree. Git refuses it by
# default and creates it with --allow-empty.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 empty-commit

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'

snip 01-allow-empty
run_rc 'git commit -m "Re-run the nightly evaluation"'
run 'git commit --allow-empty -m "Re-run the nightly evaluation"'
run "git rev-parse 'HEAD^{tree}' 'HEAD~1^{tree}'"
run 'git show --stat --format=fuller HEAD'

lab_end

#!/usr/bin/env bash
# Chapter 7, section 7.3: HEAD is a symbolic ref. Read it four ways, look at an unborn branch,
# and move HEAD alone with plumbing to see what "git switch" does beyond moving HEAD.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 head-symref

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
quiet 'git switch -c feature/retry-backoff'
printf 'import time\n\n\ndef backoff(attempt):\n    time.sleep(2 ** attempt)\n' > evalkit/retry.py
quiet 'git add . && git commit -m "Add backoff helper"'
quiet 'git switch main'

snip 01-read
run 'cat .git/HEAD'
run 'git symbolic-ref HEAD'
run 'git symbolic-ref --short HEAD'
run 'git branch --show-current'
run 'git rev-parse --abbrev-ref HEAD'
run 'git rev-parse HEAD'

snip 02-unborn
run 'git init -q ../scratch'
run 'cat ../scratch/.git/HEAD'
run_rc 'git -C ../scratch rev-parse --verify HEAD'
run 'git -C ../scratch branch'
run 'git -C ../scratch status'
run_rc 'git -C ../scratch branch feature'

snip 03-head-only
run 'git symbolic-ref HEAD refs/heads/feature/retry-backoff'
run 'git status'
run 'git symbolic-ref HEAD refs/heads/main'
run 'git status --short'

lab_end

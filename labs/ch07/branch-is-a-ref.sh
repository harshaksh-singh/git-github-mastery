#!/usr/bin/env bash
# Chapter 7, section 7.2: a branch is a ref. Create one with porcelain, read what was written,
# create one with plumbing, write one by hand, and see why plumbing is the only reliable reader
# once refs are packed.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 branch-is-a-ref

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf 'def run_batch(examples, metric):\n    return [metric(e.pred, e.gold) for e in examples]\n' > evalkit/runner.py
quiet 'git add . && git commit -m "Add batch runner"'

snip 01-porcelain
run 'git log --oneline'
run 'git branch feature/retry-backoff'
run 'git branch -v'

snip 02-what-was-written
run 'cat .git/refs/heads/feature/retry-backoff'
run 'git rev-parse feature/retry-backoff'
run 'git for-each-ref refs/heads'
run 'git reflog show feature/retry-backoff'

snip 03-plumbing
run 'git update-ref refs/heads/hotfix/judge-timeout HEAD~1'
run 'git branch -v'
run_rc 'git update-ref refs/heads/typo 1234567890123456789012345678901234567890'
run_rc "git update-ref refs/heads/not-a-commit 'HEAD^{tree}'"

snip 04-by-hand
run 'git rev-parse HEAD~2 > .git/refs/heads/by-hand'
run 'git branch -v'
run 'git reflog show by-hand'
run 'git update-ref -d refs/heads/by-hand'
run 'git branch --list by-hand'

snip 05-packed
run 'git pack-refs --all'
run_rc 'cat .git/refs/heads/main'
run 'cat .git/packed-refs'
run 'git rev-parse main'

lab_end

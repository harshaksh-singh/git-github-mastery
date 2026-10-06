#!/usr/bin/env bash
# Lab 4.1 replay: read, create, move and delete a branch with plumbing only, compare with
# porcelain, then corrupt a ref file by hand and repair it from its reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 lab-04-1-refs-by-hand

# --- same steps as setup-04-1-refs-by-hand.sh
quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf 'def run_batch(examples, metric):\n    return [metric(e.pred, e.gold) for e in examples]\n' > evalkit/runner.py
quiet 'git add . && git commit -m "Add batch runner"'
# --- end of setup

snip 01-read
run 'git log --oneline'
run 'cat .git/HEAD'
run 'git symbolic-ref HEAD'
run 'cat .git/refs/heads/main'
run 'git rev-parse HEAD'

snip 02-create
run 'git update-ref refs/heads/exp/prompt-v2 HEAD~1'
run 'git branch -v'
run 'cat .git/refs/heads/exp/prompt-v2'

snip 03-compare-and-swap
run "git update-ref -m 'lab: advance to the tip of main' refs/heads/exp/prompt-v2 HEAD HEAD~1"
run_rc "git update-ref -m 'lab: a second writer with stale information' refs/heads/exp/prompt-v2 HEAD~2 HEAD~1"
run 'git branch -v'

snip 04-porcelain
run 'git branch -f exp/prompt-v2 HEAD~2'
run 'git reflog show exp/prompt-v2'

snip 05-head-only
run 'git symbolic-ref HEAD refs/heads/exp/prompt-v2'
run 'git status --short'
run 'git symbolic-ref HEAD refs/heads/main'
run 'git status --short'

snip 06-delete
run 'git update-ref -d refs/heads/exp/prompt-v2'
run 'git branch -v'
run 'ls .git/logs/refs/heads'

snip 07-failure
run 'git branch exp/prompt-v2 HEAD~1'
run "git update-ref -m 'lab: advance to the tip of main' refs/heads/exp/prompt-v2 HEAD"
run "echo 'oops' > .git/refs/heads/exp/prompt-v2"
run 'git branch -v'
run_rc 'git log --oneline --all'
run_rc 'git refs verify'

snip 08-recovery
run_rc 'git update-ref refs/heads/exp/prompt-v2 HEAD'
run 'cat .git/logs/refs/heads/exp/prompt-v2'
run "good=\$(awk 'END {print \$2}' .git/logs/refs/heads/exp/prompt-v2); echo \"\$good\""
run 'rm .git/refs/heads/exp/prompt-v2'
run "git update-ref -m 'lab: restore after corruption' refs/heads/exp/prompt-v2 \"\$good\""

snip 09-verify
run 'git branch -v'
run 'git reflog show exp/prompt-v2'
run_rc 'git refs verify'
run 'git log --oneline --all'

lab_end

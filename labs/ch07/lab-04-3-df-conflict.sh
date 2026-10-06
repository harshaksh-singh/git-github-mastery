#!/usr/bin/env bash
# Lab 4.3 replay: a branch named "feature" blocks every branch named "feature/<something>".
# First locally, then in the form that reaches production: a stale remote-tracking ref makes
# "git fetch" fail until it is pruned. The remote is a bare repository on disk.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 lab-04-3-df-conflict

# --- same steps as setup-04-3-df-conflict.sh
quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
quiet 'git push -u origin main'
quiet 'git branch feature'
quiet 'git push origin feature'
quiet 'git clone ../origin.git ../asha-evalkit'
as asha
quiet 'git -C ../asha-evalkit push origin --delete feature'
quiet 'git -C ../asha-evalkit switch -c feature/login'
printf 'def login(user):\n    raise NotImplementedError\n' > ../asha-evalkit/login.py
quiet 'git -C ../asha-evalkit add . && git -C ../asha-evalkit commit -m "Start login flow"'
quiet 'git -C ../asha-evalkit push origin feature/login'
as you
# --- end of setup

snip 01-local-conflict
run 'git branch'
run_rc 'git switch -c feature/eval-cache'
run 'ls .git/refs/heads'

snip 02-local-fix
run 'git branch -m feature feature/base'
run 'git switch -c feature/eval-cache'
run 'git branch'
run 'git switch main'

snip 03-fetch-fails
run 'git branch -r'
run_rc 'git fetch'
run 'git branch -r'

snip 04-recovery
run 'git remote prune origin --dry-run'
run 'git fetch --prune'
run 'git branch -r'

snip 05-verify
run_rc 'git fetch'
run "git for-each-ref --format='%(refname)'"

lab_end

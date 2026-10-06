#!/usr/bin/env bash
# Hands-on setup for Lab 29.3: a repository with a sound CI workflow on main and the branch
# feature/coverage-comment, whose diff you review. Constructed for the exercise.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m29-3
review_repo
git -C "$LAB_DIR/inventory-api" rev-parse --verify -q refs/heads/feature/coverage-comment > /dev/null || { echo 'fixture: branch missing' >&2; exit 1; }

printf 'Lab 29.3 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m29-3\n'
printf 'First command of the lab:  cd inventory-api && git branch -a\n'

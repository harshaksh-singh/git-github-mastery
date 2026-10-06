#!/usr/bin/env bash
# Lab 6.1 replay: predict fast-forward, merge commit or "Already up to date" before merging.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-1-ff-or-three-way

quiet 'm06_1_fixture'

snip 01-graph
run 'git log --oneline --graph --all'

snip 02-evidence
for b in fix/typo feature/batch-size feature/judge-prompt; do
  note "---- $b"
  run_rc "git merge-base --is-ancestor main $b"
  run_rc "git merge-base --is-ancestor $b main"
  run "git rev-list --left-right --count main...$b"
done

snip 03-merges
run 'git merge fix/typo'
run_rc 'git merge --ff-only feature/judge-prompt'
run 'git merge feature/batch-size'
run 'git merge feature/judge-prompt'

snip 04-checkpoint
run 'git log --oneline --graph'
run 'git cat-file -p HEAD'

# ---- Failure scenario: an unfinished branch is fast-forwarded into main by mistake.
snip 05-failure
run 'git switch -q -c wip/streaming'
run 'printf "def stream(samples):\n    raise NotImplementedError\n" > evalkit/streaming.py'
run 'git add evalkit/streaming.py'
run 'git commit -q -m "WIP: streaming judge client"'
run 'git switch -q main'
run 'git merge wip/streaming'
run 'git log --oneline -2'

snip 06-recovery
run 'git reflog -2'
run 'git rev-parse --short ORIG_HEAD'
run 'git reset --merge ORIG_HEAD'
run 'git log --oneline -1'

snip 07-verification
run 'git status --short --branch'
run 'git branch --contains wip/streaming'
run_rc 'git merge-base --is-ancestor wip/streaming main'
run 'git ls-files evalkit'

lab_end

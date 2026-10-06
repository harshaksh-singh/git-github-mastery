#!/usr/bin/env bash
# Fast-forward versus true (three-way) merge: what each one writes. Chapter 8, sections 8.3 and 8.4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 ff-or-true-merge

quiet 'ek_base'
quiet 'git switch -c feature/batch-size'
as asha
quiet 'ek_set batch_size 32 && ek_commit "Raise batch size to 32"'
as you
quiet 'git switch main'

snip 01-before
run 'git log --oneline --graph --all'
run_rc 'git merge-base --is-ancestor main feature/batch-size'
run 'git rev-list --count --all'

snip 02-fast-forward
run 'git merge feature/batch-size'
run 'git log --oneline --graph --all'
run 'git rev-list --count --all'
run 'git reflog -2'
run 'cat .git/ORIG_HEAD'

# Now make the two branches diverge: one commit on each side of the fork.
quiet 'git switch -c feature/timeout'
as ravi
quiet 'ek_set timeout_s 60 && ek_commit "Raise timeout to 60 seconds"'
as you
quiet 'git switch main'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'

snip 03-diverged
run 'git log --oneline --graph --all'
run_rc 'git merge-base --is-ancestor main feature/timeout'
run 'git merge-base main feature/timeout'
run 'git rev-list --left-right --count main...feature/timeout'

snip 04-true-merge
run 'git merge feature/timeout'
run 'git log --oneline --graph --all'
run 'git rev-list --count --all'

snip 05-merge-commit
run 'git cat-file -p HEAD'
run 'git reflog -1'
run 'cat config/eval.yaml'

snip 06-up-to-date
run 'git merge feature/timeout'
run 'git merge feature/batch-size'

lab_end

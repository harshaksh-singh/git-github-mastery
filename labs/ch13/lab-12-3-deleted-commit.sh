#!/usr/bin/env bash
# Lab 12.3 replay: a commit disappeared from the middle of a branch during an interactive
# rebase, and work continued. Found through the branch reflog and "git cherry", restored with
# cherry-pick. Failure: "git commit --amend" swallows the previous commit. Recovery:
# "git reset --soft" to the reflog entry before the amend, then a commit of its own.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-3-deleted-commit
fx_12_3
lost=$(git -C embedder log -g --format='%h' --grep-reflog='commit: Add request timeout' feature/batching)

snip 01-symptom
run 'cd embedder'
run 'git log --oneline main..feature/batching'
run 'cat client.yaml'
run 'git log --oneline --all -- client.yaml'

snip 02-evidence
run 'git reflog show feature/batching'

snip 03-compare
note 'Anchor the tip from before the rebase, then ask what the rebase left out:'
run "git branch rescue/before-rebase 'feature/batching@{2}'"
run 'git log --oneline main..rescue/before-rebase'
run 'git cherry -v feature/batching rescue/before-rebase'

snip 04-recover
run "git show --stat --format='%h %s' $lost"
run "git cherry-pick $lost"
run 'cat client.yaml'

snip 05-verification
run 'git log --oneline main..feature/batching'
run 'git cherry -v feature/batching rescue/before-rebase'
run 'git status -s'
run 'git branch -D rescue/before-rebase'

snip 06-failure
note 'A typo fix that was meant to be a commit of its own:'
run "printf 'Embedding client. Requests are sent in batches of 32.\n' > README.md"
run 'git commit -a --amend -m "Fix typo in README"'
run 'git log --oneline -3'
run 'git show --stat --format=%s HEAD'

snip 07-recovery
run 'git reflog -2'
run "git reset --soft 'HEAD@{1}'"
run 'git status -s'
run 'git diff --cached'
run 'git commit -m "Fix typo in README"'

snip 08-after
run 'git log --oneline -4'
run 'git show --stat --format=%s HEAD~1'

lab_end

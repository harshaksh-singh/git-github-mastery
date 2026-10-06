#!/usr/bin/env bash
# Chapter 2, section "Refs and HEAD": a branch is a name for one commit ID, HEAD says which
# branch is current, a commit moves the current branch and not HEAD, and HEAD can also hold
# a commit ID directly.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 refs-head

quiet 'git init tokenizer'
cd tokenizer || exit 1
quiet "printf 'lowercase\n' > rules.txt && git add rules.txt && git commit -m 'Add lowercase rule'"

snip 01-files
run 'cat .git/HEAD'
run 'cat .git/refs/heads/main'
run 'git rev-parse HEAD main'
run 'git symbolic-ref HEAD'

snip 02-new-branch
run 'git cat-file --batch-all-objects --batch-check'
run 'git branch feature/unicode'
run 'cat .git/refs/heads/feature/unicode'
run 'git cat-file --batch-all-objects --batch-check'
run 'git for-each-ref'

snip 03-commit-moves-branch
run 'git switch feature/unicode'
run 'cat .git/HEAD'
run "printf 'lowercase\nnormalize NFC\n' > rules.txt"
run 'git commit -am "Normalize to NFC"'
run 'cat .git/HEAD'
run 'git for-each-ref'
run 'git log --graph --decorate --oneline --all'

snip 04-checkout-equivalent
note 'Older scripts switch branches with git checkout. Same effect.'
run 'git checkout main'
run 'cat .git/HEAD'

snip 05-detached
note 'The second form of HEAD: a commit ID instead of a branch name.'
run 'git switch --detach feature/unicode'
run 'cat .git/HEAD'
run_rc 'git symbolic-ref HEAD'
run 'git switch main'
run 'cat .git/HEAD'

lab_end

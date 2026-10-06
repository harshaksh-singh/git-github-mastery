#!/usr/bin/env bash
# Chapter 2, section "What can go wrong": git update-ref takes the ref name literally.
# A short name creates a stray ref at the top of .git. Commands that resolve the name "main"
# then find the stray ref first, and git update-ref -d refuses to delete it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 update-ref-trap

quiet 'git init tokenizer'
cd tokenizer || exit 1
quiet "printf 'lowercase\n' > rules.txt && git add rules.txt && git commit -m 'Add lowercase rule'"
quiet "printf 'lowercase\nnormalize NFC\n' > rules.txt && git commit -am 'Normalize to NFC'"
old=$(git rev-parse HEAD~1)

snip 01-stray-ref
note 'Intent: point the branch main at the first commit. Mistake: the short name.'
run 'git log --oneline'
run "git update-ref main $old"
run 'git branch -vv'
run 'git rev-parse main'
run 'git rev-parse refs/heads/main'

snip 02-find-and-remove
run 'git for-each-ref'
run "find .git -maxdepth 1 -type f | sort"
run 'cat .git/main'
run_rc 'git update-ref -d main'
run 'rm .git/main'
run 'git rev-parse main'

lab_end

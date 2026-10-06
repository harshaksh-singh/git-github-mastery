#!/usr/bin/env bash
# Chapter 2, section "The three trees": one file with three different contents at the same
# time, in HEAD, in the index and in the working tree.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 three-trees

quiet 'git init tokenizer'
cd tokenizer || exit 1
quiet "printf 'lowercase\n' > rules.txt && git add rules.txt && git commit -m 'Add lowercase rule'"

snip 01-three-versions
run "printf 'lowercase\nstrip accents\n' > rules.txt"
run 'git add rules.txt'
run "printf 'lowercase\nstrip accents\ncollapse whitespace\n' > rules.txt"
run 'git show HEAD:rules.txt'
run 'git show :rules.txt'
run 'cat rules.txt'

snip 02-status
run 'git status'

snip 03-two-diffs
run 'git diff --cached'
run 'git diff'

lab_end

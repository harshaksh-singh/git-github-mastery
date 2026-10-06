#!/usr/bin/env bash
# git restore --ours / --theirs / --merge on a conflicted path, and the git checkout equivalents.
# Chapter 8, section 8.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 restore-sides

quiet 'ek_creative_judge'
quiet 'git merge feature/creative-judge'

snip 01-ours
run 'git status --short'
run "grep -n -e '<<<' -e temperature -e '>>>' -e seed config/eval.yaml"
run 'git restore --ours config/eval.yaml'
run 'grep -n -e temperature -e seed config/eval.yaml'
run 'git status --short'

snip 02-theirs
run 'git restore --theirs config/eval.yaml'
run 'grep -n -e temperature -e seed config/eval.yaml'
run 'git status --short'

snip 03-merge
run 'git restore --merge config/eval.yaml'
run "grep -n -e '<<<' -e temperature -e '>>>' -e seed config/eval.yaml"

snip 04-checkout
run 'git checkout --ours config/eval.yaml'
run 'git checkout --theirs config/eval.yaml'
run 'git checkout --merge config/eval.yaml'
run 'git status --short'

snip 05-unresolve
note 'Take their whole file, stage it, then change your mind.'
run 'git restore --theirs config/eval.yaml'
run 'git add config/eval.yaml'
run 'git status --short'
run 'git ls-files -s config/eval.yaml'
run 'git restore --merge config/eval.yaml'
run 'git status --short'
run 'git ls-files -s config/eval.yaml'
quiet 'git merge --abort'

lab_end

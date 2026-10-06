#!/usr/bin/env bash
# Exercise 21.3 (Module 21): two stacked branches, what each pull request would list, and what
# happens to the upper one when the lower one is squash-merged. The "squash merge" is plain
# Git in the maintainer's clone; GitHub does not publish the commands it runs.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x21-stack-predict
make_server
new_clone you
new_clone asha
enter you
hidden 'git switch -c feature/overlap'
split_v2
commit_all 'Add overlap parameter'
split_v3
commit_all 'Reject an overlap that is not smaller than the size'
hidden 'git push -u origin feature/overlap'
hidden 'git switch -c feature/overlap-tests'
test_v2
commit_all 'Test that overlap repeats characters'
hidden 'git push -u origin feature/overlap-tests'
enter asha
config_v2
commit_all 'Double the default chunk size'
hidden 'git push origin main'
enter you
hidden 'git fetch'

snip 01-graph
run 'git log --graph --oneline --all'

snip 02-ranges
run 'git log --oneline origin/main..feature/overlap-tests'
run 'git log --oneline feature/overlap..feature/overlap-tests'
run 'git diff --stat origin/main...feature/overlap-tests'
run 'git diff --stat origin/main..feature/overlap-tests'

server_squash_merge feature/overlap 'Add overlap to the splitter (#11)'
hidden 'git push origin --delete feature/overlap'
enter you
snip 03-after-squash
run 'git fetch --prune'
run 'git log --oneline -2 origin/main'
run 'git merge-base origin/main feature/overlap-tests'
run 'git log --oneline origin/main..feature/overlap-tests'
run 'git diff --stat origin/main...feature/overlap-tests'
run_rc 'git merge-tree --write-tree --name-only origin/main feature/overlap-tests'

snip 04-repair
run 'git rebase --onto origin/main feature/overlap feature/overlap-tests'
run 'git log --oneline origin/main..feature/overlap-tests'
run 'git diff --stat origin/main...feature/overlap-tests'
run 'git push --force-with-lease'

lab_end

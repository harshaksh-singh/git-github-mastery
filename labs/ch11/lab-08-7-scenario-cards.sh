#!/usr/bin/env bash
# Lab 8.7 replay: the model solution for each of the six scenario cards, then a failure on
# card 1 (the wrong reset mode) and its recovery through ORIG_HEAD.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-7-scenario-cards
fx_08_7
bad=$(git -C card-2 rev-parse --short HEAD~1)

snip 01-card-1
run 'cd card-1'
run 'git status -sb'
run 'git log --oneline'
run 'git reset --soft @{u}'
run 'git status -s'
run 'git commit -m "Add F1 metric with a test"'
run 'git log --oneline'

snip 02-card-2
run 'cd ../card-2'
run 'git log --oneline'
run "git branch -r --contains $bad"
run "git revert --no-edit $bad"
run 'cat gen.yaml'
run 'git push'

snip 03-card-3
run 'cd ../card-3'
run 'git status -sb'
run 'git show --stat --format="%h %s" HEAD'
run 'git rm --cached outputs/predictions.jsonl'
run "printf 'outputs/\n' > .gitignore"
run 'git add .gitignore'
run 'git commit --amend --no-edit'
run 'git show --stat --format="%h %s" HEAD'
run 'git status -s --ignored'

snip 04-card-4
run 'cd ../card-4'
run 'git log --oneline'
run 'git restore --source=HEAD~2 prompts/system.txt'
run 'git status -s'
run 'git commit -am "Restore the original system prompt"'
run 'git diff --stat HEAD~3 HEAD'

snip 05-card-5
run 'cd ../card-5'
run 'git status -s'
run 'git log --oneline --graph -4'
run 'git reset --merge ORIG_HEAD'
run 'git log --oneline --graph -3'
run 'git status -s'

snip 06-card-6
run 'cd ../card-6'
run 'git status -s --ignored'
run 'git restore --staged --worktree .'
run 'git clean -n -d'
run 'git clean -f -d'
run 'git status -s --ignored'

snip 07-failure
run 'cd ../card-1'
run 'git log --oneline'
run 'git reset --hard HEAD~1'
run 'git status -s'
run 'ls'

snip 08-recovery
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline'
run 'ls'

snip 09-verification
run 'git status -sb'
run 'git diff --stat @{u} HEAD'

lab_end

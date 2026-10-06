#!/usr/bin/env bash
# Lab 7.4 replay: when --force-with-lease protects a teammate's commit, when it does
# not (after a fetch you did not look at), the two stronger forms, and bringing the
# overwritten commit back. Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-4-force-with-lease
scenario_07_4

snip 01-rewrite
run 'cd you/support-bot'
run 'git log --oneline --decorate -2'
run 'git branch backup/prompt-cache'
run 'git commit --amend -m "Add cache TTL"'
run 'git status -sb'
run_rc 'git push'

as asha
snip 02-asha-pushes
run 'cd ../../asha/support-bot'
run 'git push'
as you
run 'cd ../../you/support-bot'

snip 03-lease-holds
run_rc 'git push --force-with-lease'
run 'git rev-parse --short origin/feature/prompt-cache'
run 'git ls-remote origin feature/prompt-cache'

snip 04-background-fetch
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --graph --decorate --all -5'

snip 05-guards
run_rc 'git push --force-with-lease --force-if-includes'
run_rc 'git push --force-with-lease=feature/prompt-cache:backup/prompt-cache'

snip 06-checkpoint
run 'git ls-remote origin feature/prompt-cache'
run 'git rev-parse origin/feature/prompt-cache'

snip 07-failure
run 'git push --force-with-lease'
run 'git ls-remote origin feature/prompt-cache'
run 'git -C ../../server/support-bot.git log --oneline feature/prompt-cache -3'

snip 08-recovery-find
run 'git reflog show origin/feature/prompt-cache'
run 'git log --oneline -1 origin/feature/prompt-cache@{1}'

snip 09-recovery-restore
run 'git cherry-pick origin/feature/prompt-cache@{1}'
run 'git push'
run 'git log --oneline --decorate -3'

as asha
snip 10-asha-realigns
run 'cd ../../asha/support-bot'
run 'git fetch'
run 'git status -sb'
run 'git pull --rebase'
run 'git status -sb'
run 'git log --oneline --decorate -3'

snip 11-verification
run 'git rev-parse feature/prompt-cache'
run 'git -C ../../you/support-bot rev-parse feature/prompt-cache'
run 'git ls-remote origin feature/prompt-cache'
run 'ls tests'

lab_end

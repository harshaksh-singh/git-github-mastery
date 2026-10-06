#!/usr/bin/env bash
# Lab 7.3 replay: the fatal error of git pull on diverged branches and the three
# configurations that answer it; conflicting settings from two scopes as the failure.
# Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-3-diverged-pull
scenario_07_3

snip 01-fatal
run 'cd you/support-bot'
run 'git status -sb'
run_rc 'git pull'
run 'git status -sb'

snip 02-ff-only
run 'git config set pull.ff only'
run_rc 'git pull'
run 'git config unset pull.ff'

snip 03-merge
run 'git config set pull.rebase false'
run 'git pull'
run 'git log --oneline --graph --decorate -5'

snip 04-back
run 'git reset --hard ORIG_HEAD'
run 'git status -sb'

snip 05-rebase
run 'git config set pull.rebase true'
run 'git pull'
run 'git log --oneline --graph --decorate -4'
run 'git push'

snip 06-checkpoint
run 'git config get --show-origin --show-scope pull.rebase'
run 'git status -sb'

snip 07-failure-setup
run 'git config set --global pull.ff only'
as asha
run 'cd ../../asha/support-bot'
run 'git pull --rebase'
run 'git push'
as you
run 'cd ../../you/support-bot'
run "printf '\n## Development\n\nRun pytest before you push.\n' >> README.md"
run 'git commit -am "Document the test command"'

snip 08-failure
run_rc 'git pull'
run 'git config list --show-origin --show-scope | grep -F pull.'

snip 09-recovery
run 'git pull --rebase'
run 'git config unset --global pull.ff'
run 'git push'

snip 10-verification
run 'git config list --show-origin --show-scope | grep -F pull.'
run 'git status -sb'
run 'git log --oneline --graph --decorate -5'

lab_end

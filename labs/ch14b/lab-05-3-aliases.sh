#!/usr/bin/env bash
# Lab 5.3 replay: aliases. Five aliases defined and run, the expansion made visible, an
# alias that hides a trap, and a shell alias that breaks on its first argument.
# Lab manual: lab-manual/m05-configuration.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-05-3-aliases
scenario_05_3
as config

snip 01-define
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run 'cd ~/work/inference-gateway'
run "git config set --global alias.st 'status -sb'"
run "git config set --global alias.lg 'log --graph --decorate --oneline --all'"
run "git config set --global alias.last 'log -1 --stat HEAD'"
run "git config set --global alias.unstage 'restore --staged --'"
run "git config set --global alias.amend 'commit --amend --no-edit'"
run 'git config get --all --show-names --regexp "^alias\."'

snip 02-read-only
run 'git st'
run 'git lg'
run 'git last'

snip 03-unstage-amend
run "printf 'burst: 20\n' >> config/limits.yaml"
run "printf 'scratch\n' > notes.txt"
run 'git add .'
run 'git st'
run 'git unstage notes.txt'
run 'git st'
run 'git amend'
run 'git reflog -2'

snip 04-expansion
run "GIT_TRACE=1 git st 2>&1 | grep -E -o '(alias expansion|built-in): .*'"
run "GIT_TRACE=1 git lg -2 2>&1 | grep -E -o '(alias expansion|built-in): .*'"

snip 05-last-trap
run 'git last --format="%h %s" feature/fallback-route'
run "GIT_TRACE=1 git last --format='%h %s' feature/fallback-route 2>&1 | grep -E -o 'built-in: .*'"
run "git config set --global alias.last 'log -1 --stat'"
run 'git last --format="%h %s" feature/fallback-route'

snip 06-failure
run "git config set --global alias.tracked '!git ls-tree -r --name-only \$1 | head -2'"
run_rc 'git tracked HEAD'
run "GIT_TRACE=1 git tracked HEAD 2>&1 | grep -o 'start_command: .*'"

snip 07-recovery
run "git config set --global alias.tracked '!f() { git ls-tree -r --name-only \"\${1:-HEAD}\" | head -2; }; f'"
run 'git tracked'
run 'git tracked feature/fallback-route'
run 'cd gateway'
run 'git tracked'
run "git config set --global alias.top '!pwd'"
run 'git top'
run 'cd ..'

snip 08-verify
run 'git config get --all --show-names --show-origin --regexp "^alias\."'
run 'git st'

lab_end

#!/usr/bin/env bash
# Lab 5.1 replay: scopes and origins. Where every value comes from, which one wins, what
# the environment overrides, and a configuration file that stops every command.
# Lab manual: lab-manual/m05-configuration.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-05-1-scopes-origins
scenario_05_1
# In the lab shell the identity comes from configuration; the replay does the same.
as config

snip 01-enter
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run 'cd ~/work/inference-gateway'
run 'git config list --show-scope --show-origin'

snip 02-two-scopes
run 'git config set --global pull.rebase true'
run 'git config set pull.rebase false'
run 'git config get pull.rebase'
run 'git config get --all --show-scope --show-origin pull.rebase'

snip 03-command-scope
run 'git -c pull.rebase=merges config get --show-scope --show-origin pull.rebase'
run 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git config get --all --show-scope pull.rebase'

snip 04-system-stand-in
run "printf '[pull]\n\tff = only\n\trebase = interactive\n' > ~/etc-gitconfig"
run 'GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --all --show-scope --show-origin --regexp "^pull\."'
run 'GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --show-scope pull.rebase'

snip 05-worktree-scope
run 'git config set extensions.worktreeConfig true'
run 'git config set --worktree core.sparseCheckout true'
run 'git config list --show-scope --show-origin | tail -4'

snip 06-environment
run 'git var GIT_AUTHOR_IDENT'
run 'GIT_AUTHOR_NAME="Night Shift" git var GIT_AUTHOR_IDENT'
run 'GIT_AUTHOR_NAME="Night Shift" git -c user.name="Day Shift" var GIT_AUTHOR_IDENT'
run 'git config set --global core.editor "code --wait"'
run '(unset GIT_EDITOR; git var GIT_EDITOR)'
run '(unset GIT_EDITOR; EDITOR=nano git var GIT_EDITOR)'
run 'GIT_EDITOR=vim git var GIT_EDITOR'

snip 07-failure
run "printf '[alias\n\tst = status -sb\n' >> .git/config"
run_rc 'git status'
run_rc 'git config list --global'
run_rc 'git config edit'

snip 08-recovery
run 'tail -3 .git/config'
run "sed -i.bak -e '/^\[alias\$/,\$d' .git/config"
run 'git status -sb'
run 'diff .git/config.bak .git/config'
run 'rm .git/config.bak'

snip 09-verify
run 'git config list --show-scope --show-origin'
run 'git config get --show-scope --show-origin pull.rebase'

lab_end

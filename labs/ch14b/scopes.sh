#!/usr/bin/env bash
# Chapter 14B, section 14B.2: configuration scopes, their files, and which value wins.
# The system scope is switched off in the lab (GIT_CONFIG_NOSYSTEM=1) and is explained
# from the manual; the machine's real system file is never read.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b scopes
sandbox_home
make_gateway "$HOME/work/inference-gateway"

snip 01-list
run 'git config list --show-scope --show-origin'

snip 02-files
run 'cat ~/.gitconfig'
run 'cat .git/config'

snip 03-two-scopes
run 'git config set --global pull.rebase true'
run 'git config set pull.rebase false'
run 'git config get pull.rebase'
run 'git config get --all --show-scope --show-origin pull.rebase'

snip 04-command-scope
run 'git -c pull.rebase=merges config get --show-scope --show-origin pull.rebase'
run 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git config get --show-scope --show-origin pull.rebase'
run 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git -c pull.rebase=merges config get --all --show-scope pull.rebase'

snip 05-worktree-scope
run 'git config set --worktree core.sparseCheckout true'
run 'git config list --local --show-scope --show-origin'
run 'git config set extensions.worktreeConfig true'
run 'git config set --worktree core.sparseCheckout true'
run 'cat .git/config.worktree'
run 'git config get --all --show-scope --show-origin core.sparseCheckout'

snip 06-xdg
note 'A second global file in the XDG location. Without GIT_CONFIG_GLOBAL, Git reads it and then ~/.gitconfig.'
run 'mkdir -p ~/.config/git'
run "printf '[pull]\n\trebase = merges\n[core]\n\tabbrev = 12\n' > ~/.config/git/config"
run 'env -u GIT_CONFIG_GLOBAL git config get --all --show-scope --show-origin pull.rebase'
run 'env -u GIT_CONFIG_GLOBAL git config get --show-scope --show-origin core.abbrev'
run 'git config get --all --show-scope --show-origin pull.rebase'

snip 07-system
note 'A stand-in for the system file, inside the sandbox. The real one is never read.'
run "printf '[pull]\n\tff = only\n\trebase = interactive\n' > ~/etc-gitconfig"
run 'GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git var GIT_CONFIG_SYSTEM'
run 'GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --all --show-scope --show-origin --regexp "^pull\."'
run 'GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --show-scope pull.rebase'
run_rc 'git var GIT_CONFIG_SYSTEM'
run 'git var GIT_CONFIG_GLOBAL'

snip 08-outside
run 'cd ~'
run 'git config list --show-scope'
run_rc 'git config set pull.ff only'
run_rc 'git config list --local'

snip 09-environment
run 'cd ~/work/inference-gateway'
run 'git config set core.editor "code --wait"'
run 'git var GIT_EDITOR'
run '(unset GIT_EDITOR; git var GIT_EDITOR)'
run '(unset GIT_EDITOR; EDITOR=nano git var GIT_EDITOR)'
run '(unset GIT_EDITOR; git config unset core.editor; EDITOR=nano git var GIT_EDITOR)'
run 'git var GIT_AUTHOR_IDENT'
run 'git -c user.name="Set With -c" var GIT_AUTHOR_IDENT'
run '(unset GIT_AUTHOR_NAME; git -c user.name="Set With -c" var GIT_AUTHOR_IDENT)'

lab_end

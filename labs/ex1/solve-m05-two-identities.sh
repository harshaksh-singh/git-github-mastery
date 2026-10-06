#!/usr/bin/env bash
# Replay of Exercise 5.9 (Level 4, two work repositories with two wrong addresses): diagnosis and
# repair as real transcripts for solutions/exercises-m01-m05.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m05-two-identities
exercise_load m05-two-identities
as config        # as in the lab shell after the first step: configuration decides the identity

snip 01-first-step
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run "git -C ~/work/billing-llm log --format='%h %ae | %ce | %s'"
run "git -C ~/work/invoice-ocr log --format='%h %ae | %ce | %s'"

snip 02-evidence
run 'git -C ~/work/billing-llm config get --all --show-scope --show-origin user.email'
run 'git -C ~/work/invoice-ocr config get --all --show-scope --show-origin user.email'
run 'git -C ~/oss/dotfiles config get --all --show-scope --show-origin user.email'

snip 03-include
run 'git config get --global --all --show-names --regexp "^includeif"'
run 'ls -a ~ | grep gitconfig'
run 'git -C ~/work/billing-llm rev-parse --absolute-git-dir'

snip 04-repair-config
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run 'git -C ~/work/billing-llm config get --all --show-scope --show-origin user.email'
run 'git -C ~/work/invoice-ocr config unset user.email'
run 'git -C ~/work/invoice-ocr config get --all --show-scope --show-origin user.email'
run 'git -C ~/oss/dotfiles config get user.email'

snip 05-repair-commits
run 'cd ~/work/billing-llm'
run 'git var GIT_AUTHOR_IDENT'
run 'git commit -q --amend --no-edit --reset-author'
run "git log --format='%h %ae | %ce | %s'"
run 'cd ~/work/invoice-ocr'
run 'git commit -q --amend --no-edit --reset-author'
run "git log --format='%h %ae | %ce | %s'"

snip 06-check
run 'cd "$HOME/.."'
show_check
exercise_done

#!/usr/bin/env bash
# Lab 5.4 replay: a configuration built one decision at a time, each line with its reason,
# three of the decisions tested, and a misspelled key that Git accepts without a word.
# The values are one defensible set, not the answer: the lab manual has the worksheet.
# Lab manual: lab-manual/m05-configuration.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-05-4-deliberate-config
scenario_05_4
as config

snip 01-start
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run 'cat ~/.gitconfig'

snip 02-decisions
run 'git config set --global --comment "refuse to guess an identity" user.useConfigOnly true'
run 'git config set --global --comment "never integrate by accident" pull.ff only'
run 'git config set --global --comment "first push sets the upstream" push.autoSetupRemote true'
run 'git config set --global --comment "forget branches deleted on the server" fetch.prune true'
run 'git config set --global --comment "show the common ancestor in conflicts" merge.conflictStyle zdiff3'
run 'git config set --global --comment "fixup! commits find their place" rebase.autoSquash true'
run 'git config set --global --comment "stacked branches move together" rebase.updateRefs true'
run 'git config set --global --comment "remember conflict resolutions" rerere.enabled true'
run 'git config set --global --comment "moved code reads as a move" diff.algorithm histogram'
run 'git config set --global diff.colorMoved default'
run 'git config set --global --comment "show the suggestion, run nothing" help.autocorrect prompt'
run 'git config set --global core.excludesFile "~/.config/git/ignore"'

snip 03-the-file
run 'cat ~/.gitconfig'

snip 04-test-push
run 'cd you/inference-gateway'
run 'git switch -q -c feature/token-budget'
run "printf 'daily_token_budget: 2000000\n' >> config/limits.yaml"
run 'git commit -q -am "Add daily token budget"'
run 'git push'
run 'git status -sb'

snip 05-test-pull
note 'Make main diverge: one commit on the server that you do not have, one local commit.'
run 'git switch -q main'
run 'git clone -q ../../server/inference-gateway.git ../../other'
run 'git -C ../../other commit -q --allow-empty -m "Server-side change"'
run 'git -C ../../other push -q'
run 'git commit -q --allow-empty -m "Local change"'
run_rc 'git pull'
run 'git status -sb'

snip 06-test-ignore
run 'mkdir -p ~/.config/git'
run "printf '.DS_Store\n.idea/\n*.swp\n' > ~/.config/git/ignore"
run 'touch .DS_Store'
run 'git status --short'
run 'git check-ignore -v .DS_Store'

snip 07-failure
run 'git config set --global pull.rebsae true'
run_rc 'git config get pull.rebase'
run 'git config list --global --name-only | sort -u > ~/mine.txt'
run "git help --config | tr 'A-Z' 'a-z' | sort -u > ~/known.txt"
run 'comm -23 ~/mine.txt ~/known.txt'

snip 08-recovery
run 'git config unset --global pull.rebsae'
run 'git config set --global --comment "linear local history; revisit per team" pull.rebase true'
run 'git config list --global --name-only | sort -u > ~/mine.txt'
run_rc 'comm -23 ~/mine.txt ~/known.txt'

snip 09-verify
run 'git config list --global --show-origin | cut -f2'
run 'cat ~/.gitconfig'

lab_end

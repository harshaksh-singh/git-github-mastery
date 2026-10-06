#!/usr/bin/env bash
# Chapter 14B, section 14B.3: the git config subcommands (Git 2.46 or later) beside the
# legacy flags, value types, multi-valued keys, exit statuses, and a broken file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b config-commands
sandbox_home
make_gateway "$HOME/work/inference-gateway"

snip 01-set-get-unset
run 'git config set merge.conflictStyle zdiff3'
run 'git config get merge.conflictStyle'
run 'git config get merge.conflictstyle'
run_rc 'git config get merge.conflictStyl'
run 'git config get --default merge merge.conflictStyl'
run 'git config unset merge.conflictStyle'
run_rc 'git config unset merge.conflictStyle'

snip 02-legacy
note 'The same four operations with the flags that older scripts and tutorials use.'
run 'git config merge.conflictStyle zdiff3'
run 'git config merge.conflictStyle'
run 'git config --get merge.conflictStyle'
run 'git config --list --local | tail -1'
run 'git config --unset merge.conflictStyle'

snip 03-file-syntax
run 'git config set --comment "decided 2026-09-07, see docs/git-setup.md" rebase.autoSquash true'
run 'git config set branch.release/1.2.description "Maintenance line for 1.2"'
run 'git config set credential.https://git.corp.example.username lab.user'
run 'tail -6 .git/config'
run 'git config list --local --name-only | tail -3'
run 'git config get --url=https://git.corp.example/platform/inference-gateway.git credential.username'
run_rc 'git config get --url=https://code.other.example/evalkit.git credential.username'

snip 04-types
run 'git config set core.bigFileThreshold 2g'
run 'git config get core.bigFileThreshold'
run 'git config get --type=int core.bigFileThreshold'
run 'git config set --global core.excludesFile "~/.config/git/ignore"'
run 'git config get core.excludesFile'
run 'git config get --type=path core.excludesFile'
run "printf '[rerere]\n\tenabled\n[fetch]\n\tprune = yes\n' >> .git/config"
run 'git config get --type=bool rerere.enabled'
run 'git config get --type=bool fetch.prune'
run 'git config get fetch.prune'
run_rc 'git config set --type=bool fetch.prune sometimes'
run_rc 'git config get --type=bool core.bigFileThreshold'

snip 05-multi-valued
run 'git config set --append remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"'
run 'git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"'
run 'git config get remote.origin.fetch'
run 'git config get --all remote.origin.fetch'
run_rc 'git config set remote.origin.fetch "+refs/tags/*:refs/tags/*"'
run_rc 'git config unset remote.origin.fetch'
run 'git config unset --value="refs/pull" remote.origin.fetch'
run 'git config get --all remote.origin.fetch'

snip 06-search
run 'git config get --all --show-names --regexp "^rebase\."'
run 'git help --config | grep "^rebase\."'

snip 07-sections
run 'git config rename-section rerere reuse-recorded'
run 'git config get --all --show-names --regexp "^reuse"'
run 'git config remove-section reuse-recorded'
run_rc 'git config get --all --show-names --regexp "^reuse"'

snip 08-edit
note 'Which file would each scope open? An "editor" that only prints its argument tells you.'
run 'GIT_EDITOR="echo would edit:" git config edit'
run 'GIT_EDITOR="echo would edit:" git config edit --global'
run 'GIT_EDITOR="echo would edit:" git config edit --worktree'

snip 09-unknown-key
run 'git config set --global pull.rebsae true'
run 'git config get pull.rebsae'
run_rc 'git config get pull.rebase'
run_rc 'git config set --global pull_rebase true'
run 'git config unset --global pull.rebsae'

snip 10-broken-file
run "printf '[alias\n\tst = status -sb\n' >> .git/config"
run_rc 'git status'
run_rc 'git config list --local'
run_rc 'git config list --global'
run_rc 'git config edit'
note 'Git cannot repair it. A text tool on the named line can. Here: delete the two appended lines.'
run "sed -i.bak -e '/^\[alias\$/,\$d' .git/config && rm .git/config.bak"
run 'git status -sb'

lab_end

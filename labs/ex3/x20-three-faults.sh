#!/usr/bin/env bash
# Exercise 20.6 (Module 20), model solution: three planted faults in one home directory,
# found without connecting anywhere. The hands-on twin is setup-x20-6-three-faults.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x20-three-faults
scenario_x20_faults
SHOW="grep -E '^(hostname|user|port|identityfile|identitiesonly) '"

snip 01-first-step
run 'export HOME="$PWD/home" GIT_CONFIG_GLOBAL="$PWD/home/.gitconfig"'
as config
run 'cd ~/work/chunker'
run 'git remote -v'
run 'git remote get-url origin'
run 'git config get --show-origin --all user.email'
run "git log -1 --format='%an <%ae>  %s'"
note 'The URL is not rewritten, so ssh would be started for github.com. What would it use?'
run "ssh -T -F ~/.ssh/config -G github.com | $SHOW"

snip 02-fault-1
run "git config list --global | grep -i includeif"
run 'cat ~/.gitconfig-work'
note 'The pattern has no trailing slash, so it matches only a repository whose .git is ~/work itself.'
run "git config unset --global 'includeIf.gitdir:~/work.path'"
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run 'git config get --show-origin --all user.email'
run 'git remote get-url origin'

snip 03-fault-2
run "ssh -T -F ~/.ssh/config -G github-work | $SHOW"
run 'head -4 ~/.ssh/config'
note 'First value obtained wins: "User deploy" and the CI key come from the Host github* block on top.'
run "{ sed '1,5d' ~/.ssh/config; printf '\n'; sed -n '1,4p' ~/.ssh/config; } > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config && chmod 600 ~/.ssh/config"
run "ssh -T -F ~/.ssh/config -G github-work | $SHOW"

snip 04-fault-3
run 'ls ~/.ssh'
note 'The alias names id_ed25519_work. The key on disk is id_ed25519_northwind.'
run "sed 's/id_ed25519_work/id_ed25519_northwind/' ~/.ssh/config > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config && chmod 600 ~/.ssh/config"

snip 05-verify
run "ssh -T -F ~/.ssh/config -G github-work | $SHOW"
run "ssh -T -F ~/.ssh/config -G github.com | $SHOW"
run 'git remote get-url origin'
run 'git config get user.email'

lab_end

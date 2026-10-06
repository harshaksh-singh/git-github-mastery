#!/usr/bin/env bash
# Lab 20.4 replay, Part A (local rehearsal): two GitHub identities on one machine. An ssh
# host alias per account, includeIf by directory for the commit identity and the URL
# rewrite, and the evidence that each repository would use the right account.
# Failure scenario: a work repository cloned outside ~/work/. Nothing connects.
# Lab manual: lab-manual/m20-authentication-ssh.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 lab-20-4-two-identities
scenario_20_4
as config

snip 01-enter
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"'
run 'cd ~'

snip 02-ssh-config
run "printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_personal\n  IdentitiesOnly yes\n\nHost github-work\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_work\n  IdentitiesOnly yes\n' > ~/.ssh/config"
run "ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|identityfile) '"
run "ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|identityfile) '"

snip 03-git-config
run 'git config set --global user.email lab-user@personal.example'
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run "printf '[user]\n\temail = lab.user@acme-pay.example\n[url \"git@github-work:\"]\n\tinsteadOf = git@github.com:\n' > ~/.gitconfig-work"

snip 04-personal
run 'cd ~/personal/notes-app'
run 'git config get --show-origin user.email'
run 'git remote get-url origin'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1'

snip 05-work
run 'cd ~/work/billing-api'
run 'git config get --show-origin user.email'
run 'git remote get-url origin'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1'

snip 06-failure
note 'A second work repository, created in the wrong place:'
run 'mkdir -p ~/Downloads && cd ~/Downloads'
run 'git init -q ledger-export && cd ledger-export'
run 'git remote add origin git@github.com:acme-pay/ledger-export.git'
run 'git config get --show-origin user.email'
run 'git remote get-url origin'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1'

snip 07-recovery
run "git config set --global 'includeIf.hasconfig:remote.*.url:git@github.com:acme-pay/**.path' '~/.gitconfig-work'"
run 'git config get --show-origin user.email'
run 'git remote get-url origin'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1'

snip 08-verification
run 'cd ~/personal/notes-app && git config get user.email && git remote get-url origin'
run 'cd ~/work/billing-api && git config get user.email && git remote get-url origin'
run 'cd ~/Downloads/ledger-export && git config get user.email && git remote get-url origin'

lab_end

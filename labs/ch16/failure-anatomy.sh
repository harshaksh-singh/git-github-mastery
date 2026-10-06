#!/usr/bin/env bash
# Chapter 16, section 16.15: who writes which line of an error. Four failures that end in
# the same sentence from Git, each with a different first line from a different program.
# The only connection attempted is to port 1 of this machine (127.0.0.1), where nothing
# listens; it is refused at once and nothing leaves the computer. The ssh options make sure
# that no key, agent or known_hosts file outside the sandbox is involved.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 failure-anatomy
sandbox_home
make_ssh_standin
printf '#!/bin/sh\nexit 255\n' > "$HOME/lab-bin/silent-ssh"; chmod +x "$HOME/lab-bin/silent-ssh"
cat > "$HOME/.ssh/config-offline" <<CFG
Host *
  IdentityFile none
  IdentitiesOnly yes
  IdentityAgent none
  UserKnownHostsFile $HOME/.ssh/known_hosts
  GlobalKnownHostsFile /dev/null
  BatchMode yes
  ConnectTimeout 5
CFG

snip 01-no-ssh-agent
run_rc 'ssh-add -l'

snip 02-refused
note 'Nothing listens on port 1 of this machine, so the connection is refused at once.'
run_rc 'ssh -T -F ~/.ssh/config-offline -p 1 git@127.0.0.1'
run_rc "GIT_SSH_COMMAND='ssh -F ~/.ssh/config-offline' git ls-remote ssh://git@127.0.0.1:1/acme-pay/billing-api.git"

snip 03-standin
run_rc 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote git@github.com:acme-pay/billing-api.git'

snip 04-silent
note '~/lab-bin/silent-ssh exits with status 255 and prints nothing.'
run_rc 'GIT_SSH_COMMAND=~/lab-bin/silent-ssh git ls-remote git@github.com:acme-pay/billing-api.git'

snip 05-local-path
run_rc 'git ls-remote ~/no-such-repository.git'

snip 06-no-program
run_rc 'GIT_SSH_COMMAND=~/lab-bin/no-such-ssh git ls-remote git@github.com:acme-pay/billing-api.git'

lab_end

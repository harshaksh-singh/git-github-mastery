#!/usr/bin/env bash
# Chapter 16, section 16.9: ~/.ssh/config and host aliases, read back with "ssh -G", which
# prints the configuration ssh would use for a host and exits without connecting.
# ssh does not use $HOME to find its files, so every command names the sandbox file with -F.
# "-T" keeps ssh from mentioning a terminal when the transcript is recorded.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 ssh-config
sandbox_home
write_ssh_config
make_ssh_standin
SHOW="grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '"

snip 01-config
run 'cat ~/.ssh/config'

snip 02-github
run "ssh -T -F ~/.ssh/config -G github.com | $SHOW"

snip 03-alias
run "ssh -T -F ~/.ssh/config -G github-work | $SHOW"

snip 04-port-443
run "ssh -T -F ~/.ssh/config -G github-443 | $SHOW"

snip 05-user-in-url
note 'A user written in the command or in the URL beats "User git" in the file:'
run "ssh -T -F ~/.ssh/config -G asha-rao@github.com | grep -E '^(hostname|user) '"

snip 06-order
note 'The same file with the defaults moved to the top, and a default user added to them:'
hidden "{ printf 'Host *\n  User deploy\n  IdentityFile ~/.ssh/id_rsa_old\n\n'; sed '/^# Defaults/,\$d' ~/.ssh/config; } > ~/.ssh/config-defaults-first"
run 'head -4 ~/.ssh/config-defaults-first'
run "ssh -T -F ~/.ssh/config-defaults-first -G github.com | $SHOW"

snip 07-what-git-runs
note '~/lab-bin/fake-ssh prints the arguments Git gives to ssh and exits. No connection is made.'
run 'cd ~ && git init -q work/billing-api && cd work/billing-api'
run 'git remote add origin git@github-work:acme-pay/billing-api.git'
run_rc 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin'

lab_end

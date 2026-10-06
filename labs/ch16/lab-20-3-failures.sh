#!/usr/bin/env bash
# Lab 20.3 replay, Part A (local rehearsal): the evidence behind three authentication
# failures, collected without a network. Which user and host Git hands to ssh; which keys a
# command line would offer; a stale host key recognised by its fingerprint; a wrong HTTPS
# credential sent without touching the stored one. Failure scenario: the token-in-URL "fix".
# Nothing connects: fake-ssh prints its arguments, "ssh -G" prints configuration.
# Lab manual: lab-manual/m20-authentication-ssh.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 lab-20-3-failures
scenario_20_3
export GIT_ALLOW_PROTOCOL=file:ssh     # the replay can never open an HTTPS connection

snip 01-enter
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"'
run 'export GIT_TERMINAL_PROMPT=0'
run 'cd ~/work/billing-api'

snip 02-who-connects
run 'git remote get-url origin'
run_rc 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin'

snip 03-wrong-user
run 'git remote set-url origin ssh://lab-user@github.com/acme-pay/billing-api.git'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin 2>&1 | head -1'
run "ssh -T -F none -G lab-user@github.com | grep '^user '"
run 'git remote set-url origin git@github.com:acme-pay/billing-api.git'

snip 04-no-key-offered
run "ssh -T -F none -o IdentityAgent=none -o IdentityFile=none -G git@github.com | grep -E '^(user|hostname|identityagent|identityfile) '"

snip 05-host-key-good
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep ED25519'

snip 06-host-key-stale
run "printf 'github.com %s\n' \"\$(cut -d' ' -f1,2 ~/stale-host-key.pub)\" > ~/.ssh/known_hosts-stale"
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts-stale'
run "ssh -T -F none -o UserKnownHostsFile=\"\$HOME/.ssh/known_hosts-stale\" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes -G git@github.com | grep -E '^(userknownhostsfile|globalknownhostsfile|stricthostkeychecking) '"

snip 07-host-key-repair
run 'ssh-keygen -R github.com -f ~/.ssh/known_hosts-stale'
run 'cat ~/github-known-hosts.txt >> ~/.ssh/known_hosts-stale'
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts-stale | grep ED25519'

snip 08-wrong-credential
run "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"
run "printf 'protocol=https\nhost=github.com\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test \"\$1\" = get && printf \"username=lab-user\\npassword=not-a-token\\n\"; }; f' credential fill"
run "printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=not-a-token\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test \"\$1\" = get && printf \"username=lab-user\\npassword=not-a-token\\n\"; }; f' credential reject"

snip 09-checkpoint
run 'cat ~/helper.log'
run 'cat ~/.labstore-credentials'

snip 10-failure
note 'The tempting fix for any HTTPS failure. The token is fake.'
run "git remote set-url origin https://lab-user:$FAKE_TOKEN@github.com/acme-pay/billing-api.git"
run 'git remote -v'
run 'grep -c FAKE-TOKEN .git/config'

snip 11-recovery
run 'git remote set-url origin https://github.com/acme-pay/billing-api.git'
run 'git config set --global transfer.credentialsInUrl die'
run "git remote set-url origin https://lab-user:$FAKE_TOKEN@github.com/acme-pay/billing-api.git"
run_rc 'git fetch origin'
run 'git config set remote.origin.url git@github.com:acme-pay/billing-api.git'

snip 12-verification
run 'git remote -v'
run_rc 'grep -c FAKE-TOKEN .git/config'
run 'git config get --show-scope transfer.credentialsInUrl'

lab_end

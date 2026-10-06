#!/usr/bin/env bash
# Lab 20.1 replay, Part A (local rehearsal): an SSH key pair, a config file, the effective
# configuration read back with "ssh -G", and GitHub's published host keys checked by
# fingerprint. Failure scenario: a "Host *" block placed first.
# VOLATILE: a fresh throwaway key is generated inside the sandbox on every run.
# No agent, no keychain, no real ~/.ssh, no connection. Lab manual: lab-manual/m20-authentication-ssh.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 lab-20-1-ssh-setup --volatile
scenario_20_1
unset SSH_AUTH_SOCK SSH_AGENT_PID

snip 01-enter
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"'
run 'cd ~'

snip 02-key
run "ssh-keygen -q -t ed25519 -N '' -C 'rehearsal key, never uploaded' -f ~/.ssh/id_ed25519_rehearsal"
run "cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_rehearsal id_ed25519_rehearsal.pub && cd ~"
run 'cat ~/.ssh/id_ed25519_rehearsal.pub'
run 'ssh-keygen -l -f ~/.ssh/id_ed25519_rehearsal.pub'

snip 03-config
run "printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_rehearsal\n  IdentitiesOnly yes\n\nHost *\n  AddKeysToAgent yes\n' > ~/.ssh/config"
run 'chmod 600 ~/.ssh/config'
run "ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '"

snip 04-host-keys
run 'cp ~/github-known-hosts.txt ~/.ssh/known_hosts'
run 'ssh-keygen -l -f ~/.ssh/known_hosts'

snip 05-checkpoint
run "ssh -T -F ~/.ssh/config -G git@github.com | grep -E '^(hostname|user|port) '"
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep -c SHA256'

snip 06-failure
run "printf 'Host *\n  User %s\n  IdentityFile ~/.ssh/id_rsa\n\n' labuser | cat - ~/.ssh/config > ~/.ssh/config-broken"
run "ssh -T -F ~/.ssh/config-broken -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '"

snip 07-recovery
run "sed '1,4d' ~/.ssh/config-broken > ~/.ssh/config-fixed"
run 'diff ~/.ssh/config ~/.ssh/config-fixed && echo identical'
run "ssh -T -F ~/.ssh/config-fixed -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '"

snip 08-verification
run_rc 'ssh-add -l'
run "ssh -T -F ~/.ssh/config -G github.com | grep -E '^(user|identityfile) '"

lab_end

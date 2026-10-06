#!/usr/bin/env bash
# Chapter 16, section 16.10: known_hosts and host key verification, without connecting.
# The three known_hosts lines are the ones GitHub publishes on its "GitHub's SSH key
# fingerprints" documentation page (copied on 2 October 2026 into github-known-hosts.txt).
# ssh-keygen computes their fingerprints locally; they must equal the published fingerprints.
# stale-host-key.pub is a public key generated once for this course (its private half was
# deleted); it plays an outdated or forged entry, with a fingerprint that is the same on every run.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 known-hosts
sandbox_home
cp "$LAB_SCRIPT_DIR/github-known-hosts.txt" "$HOME/github-known-hosts.txt"
cp "$LAB_SCRIPT_DIR/stale-host-key.pub" "$HOME/stale-host-key.pub"

snip 01-published-lines
run 'cut -c1-78 ~/github-known-hosts.txt'

snip 02-fingerprints
run 'ssh-keygen -l -f ~/github-known-hosts.txt'

snip 03-find
run 'cp ~/github-known-hosts.txt ~/.ssh/known_hosts'
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts'
run_rc 'ssh-keygen -l -F ssh.github.com -f ~/.ssh/known_hosts'

snip 04-stale
note 'A different key filed under the name github.com: what a stale or forged entry looks like.'
note 'stale-host-key.pub is a throwaway public key made for this course.'
run "printf 'github.com %s\n' \"\$(cut -d' ' -f1,2 ~/stale-host-key.pub)\" > ~/.ssh/known_hosts"
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts'
run 'ssh-keygen -l -f ~/github-known-hosts.txt | grep ED25519'

snip 05-remove
note 'The repair: remove the lines for the host, then add the published ones.'
run 'ssh-keygen -R github.com -f ~/.ssh/known_hosts'
run_rc 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts'
run 'cat ~/github-known-hosts.txt >> ~/.ssh/known_hosts'
run 'ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep -c SHA256'

lab_end

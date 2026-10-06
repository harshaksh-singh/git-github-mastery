#!/usr/bin/env bash
# Chapter 16, section 16.8: an SSH key pair. Generate, look at both halves, fingerprint,
# add a passphrase, and see that a wrong passphrase cannot open the private key.
# VOLATILE: a fresh key pair is generated inside the sandbox on every run, so the key and its
# fingerprints differ each time. No agent, no keychain, nothing under the real ~/.ssh.
# The passphrase is passed on the command line only because a transcript cannot type; on your
# machine ssh-keygen asks for it, and it never appears in a command or in shell history.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 ssh-keys --volatile
sandbox_home

snip 01-generate
run "ssh-keygen -q -t ed25519 -N '' -C 'you@example.com laptop 2026' -f ~/.ssh/id_ed25519_personal"
run "cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_personal id_ed25519_personal.pub && cd ~"

snip 02-public-half
run 'cat ~/.ssh/id_ed25519_personal.pub'
run 'ssh-keygen -l -f ~/.ssh/id_ed25519_personal.pub'
run 'ssh-keygen -l -E md5 -f ~/.ssh/id_ed25519_personal.pub'

snip 03-private-half
run 'head -1 ~/.ssh/id_ed25519_personal'
run 'ssh-keygen -y -f ~/.ssh/id_ed25519_personal'

snip 04-passphrase
run "ssh-keygen -p -q -P '' -N 'lab passphrase, not a real one' -f ~/.ssh/id_ed25519_personal"
run_rc "ssh-keygen -y -P 'a wrong guess' -f ~/.ssh/id_ed25519_personal"
run "ssh-keygen -y -P 'lab passphrase, not a real one' -f ~/.ssh/id_ed25519_personal | cut -c1-40"

lab_end

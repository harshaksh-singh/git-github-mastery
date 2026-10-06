#!/usr/bin/env bash
# Chapter 14B, section 14B.15: the three signing backends. Git hands the payload to an
# external program chosen by gpg.format. Here a stand-in program takes the place of gpg,
# gpgsm and ssh-keygen, prints the arguments Git passes, and fails; no real signing
# program runs, so no agent starts and no key is needed.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b signing-backends
sandbox_home
no_agent
make_gateway "$HOME/work/inference-gateway"
mkdir -p "$HOME/lab-bin"
printf '#!/bin/sh\n# Stand-in for a signing program: show the arguments, sign nothing.\necho "signing program called with: $*" | sed "s|/[^ ]*/\\.git_signing_buffer_tmp[A-Za-z0-9]*|<file with the payload>|" >&2\nexit 1\n' > "$HOME/lab-bin/show-args"
chmod +x "$HOME/lab-bin/show-args"

snip 01-stand-in
run 'cat ~/lab-bin/show-args'
run_rc 'git config get gpg.format'

snip 02-openpgp
run_rc 'git -c gpg.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with OpenPGP"'

snip 03-x509
run_rc 'git -c gpg.format=x509 -c gpg.x509.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with X.509"'

snip 04-ssh
run_rc 'git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with SSH"'
run_rc 'git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args -c user.signingKey=~/keys/signing_key.pub commit -S --allow-empty -m "Signed with SSH"'

snip 05-bad-format
run_rc 'git -c gpg.format=pgp commit -S --allow-empty -m "Signed with?"'
run 'git log --oneline -1'

lab_end

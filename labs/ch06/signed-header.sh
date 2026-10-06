#!/usr/bin/env bash
# Chapter 6, section 6.11: where a signature lives inside a commit object (the gpgsig header).
# VOLATILE: the demo creates a fresh SSH key inside the sandbox, so the signature and the
# commit ID differ on every run. Nothing outside the sandbox is read or written: no agent,
# no ~/.ssh, no real Git configuration. Signing itself is the subject of chapter 14B.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 signed-header --volatile

quiet 'git init evalkit'
cd evalkit || exit 1
printf '# evalkit\n' > README.md
quiet 'git add . && git commit -m "Add README"'
quiet "ssh-keygen -q -t ed25519 -N '' -C 'lab signing key' -f '$LAB_DIR/home/lab_signing_key' < /dev/null"
quiet 'git config set gpg.format ssh'
quiet "git config set user.signingKey '$LAB_DIR/home/lab_signing_key'"
printf 'Small evaluation harness for LLM outputs.\n' >> README.md
quiet 'git add README.md'

snip 01-gpgsig
run 'git commit -q -S -m "Describe the project"'
run 'git cat-file -p HEAD'

lab_end

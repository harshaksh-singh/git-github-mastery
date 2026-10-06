#!/usr/bin/env bash
# Chapter 14B, sections 14B.16 and 14B.17: SSH signing end to end.
# VOLATILE: the demo generates a fresh key pair inside the sandbox, so the key, every
# signature and every signed object ID differ on each run. Nothing outside the sandbox is
# read or written: no agent, no ~/.ssh (HOME is the sandbox home), no real Git configuration.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b ssh-signing --volatile
sandbox_home
no_agent
make_gateway "$HOME/work/inference-gateway"

snip 01-key
run 'mkdir ~/keys'
run "ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_key"
run 'ls ~/keys'
run 'cat ~/keys/signing_key.pub'
run 'ssh-keygen -l -f ~/keys/signing_key.pub'

snip 02-configure
run 'git config set --global gpg.format ssh'
run 'git config set --global user.signingKey ~/keys/signing_key.pub'
run 'git config get --all --show-names --regexp "^(gpg|user\.signingkey)"'

snip 03-sign-a-commit
run "printf 'burst: 20\n' >> config/limits.yaml"
run 'git commit -q -S -am "Allow short bursts"'
run 'git cat-file -p HEAD'

snip 04-verify-without-trust
run_rc 'git verify-commit HEAD'
run 'git log -1 --show-signature --format="%h %s"'
run "git log -1 --format='%h  %G?  %s'"

snip 05-allowed-signers
run "printf 'you@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 ~/keys/signing_key.pub)\" > ~/allowed_signers"
run 'cat ~/allowed_signers'
run 'git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers'
run_rc 'git verify-commit HEAD'
run 'git log -2 --show-signature --format="%h %an: %s"'

snip 06-placeholders
run "git log -2 --format='%h  %G?  signer=%GS  trust=%GT  %s'"
run "git log -1 --format='%GK'"

snip 07-sign-by-default
run 'git config set --global commit.gpgSign true'
run 'git config set --global tag.gpgSign true'
run "printf 'retry_after_seconds: 2\n' >> config/limits.yaml"
run 'git commit -q -am "Tell clients when to retry"'
run 'git commit -q --no-gpg-sign --allow-empty -m "Trigger the nightly evaluation"'
run "git log -4 --format='%h  %G?  %GS  %s'"

snip 08-signed-tag
run 'git tag -m "inference-gateway 1.0.0" v1.0.0 HEAD~1'
run 'git cat-file -p v1.0.0'
run_rc 'git verify-tag v1.0.0'
run 'git tag -v v1.0.0'

snip 09-mechanism
note 'Git does no cryptography itself. The programs it starts to sign and to verify:'
run "GIT_TRACE=1 git commit -q --allow-empty -m 'Re-run the nightly evaluation' 2>&1 | grep -o 'run_command: ssh-keygen -Y [a-z-]* -n git'"
run "GIT_TRACE=1 git verify-commit HEAD 2>&1 | grep -o 'run_command: ssh-keygen -Y [a-z-]*'"
run 'git verify-commit --raw HEAD'

snip 10-key-problems
note 'Three ways the key can be unusable, and what Git says.'
run 'mv ~/keys/signing_key ~/keys/signing_key.away'
run_rc 'git commit -q --allow-empty -m "Sign without the private key"'
run 'mv ~/keys/signing_key.away ~/keys/signing_key'
run_rc 'git -c user.signingKey=~/keys/no_such_key.pub commit -q --allow-empty -m "Sign with a wrong path"'
run_rc 'git -c user.signingKey="key::$(cut -d" " -f1,2 ~/keys/signing_key.pub)" commit -q --allow-empty -m "Sign with a literal key and no agent"'

lab_end

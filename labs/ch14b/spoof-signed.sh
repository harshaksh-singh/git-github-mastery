#!/usr/bin/env bash
# Chapter 14B, section 14B.19: the same forgery in a repository whose team signs. What a
# signature adds, and the check that Git does not make for you: signer against author.
# VOLATILE: fresh keys inside the sandbox on every run. No agent, no ~/.ssh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b spoof-signed --volatile
sandbox_home
no_agent
make_signing_key you  'you@example.com signing key'
make_signing_key asha 'asha@example.com signing key'
allow_signer you@example.com you
allow_signer asha@example.com asha
hidden 'git config set --global gpg.format ssh'
hidden 'git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers'
make_gateway "$HOME/work/inference-gateway"
# Asha's genuine, signed commit (made with her key; in real life, on her machine).
as asha
tick; mkdir -p gateway; printf 'def healthy():\n    return True\n' > gateway/health.py
hidden 'git add gateway/health.py && git -c user.signingKey=~/keys/asha.pub commit -S -m "Add health endpoint"'
as config
hidden 'git config set --global user.signingKey ~/keys/you.pub'

snip 01-allowed-signers
run "cut -c1-60 ~/allowed_signers"
run "git log -1 --format='%h  %G?  author=%ae  signer=%GS  %s'"

snip 02-unsigned-forgery
run "printf 'requests_per_minute: 6000\n' > config/limits.yaml"
run 'git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit"'
run "git log -2 --format='%h  %G?  author=%ae  signer=%GS  %s'"

snip 03-signed-forgery
note 'You cannot sign as Asha: you do not have her private key. You can sign with your own.'
run "printf 'requests_per_minute: 60000\n' > config/limits.yaml"
run 'git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -S -am "Raise the rate limit again"'
run_rc 'git verify-commit HEAD'
run "git log -3 --format='%h  %G?  author=%ae  signer=%GS  %s'"

snip 04-policy-check
note 'Git verified a signature. It did not compare the signer with the author. A policy check does:'
run "git log -3 --format='%h %G? %ae %GS' | awk '{ ok = (\$2 == \"G\" && \$3 == \$4) ? \"ok  \" : \"FAIL\"; print ok, \$0 }'"

snip 05-merge-verify
run 'git switch -q -c integration main~2'
run_rc 'git merge --verify-signatures --ff-only main~1'
note 'The option looks at one commit only: the tip of what is being merged.'
run_rc 'git merge --verify-signatures --ff-only main'
run "git log -3 --format='%h  %G?  author=%ae  signer=%GS'"

lab_end

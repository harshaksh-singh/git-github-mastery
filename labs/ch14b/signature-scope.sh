#!/usr/bin/env bash
# Chapter 14B, section 14B.18: what a signature covers, what it does not cover, and how
# signatures are lost. Also key lifetimes and revocation in the allowed-signers model.
# VOLATILE: fresh keys inside the sandbox on every run. No agent, no ~/.ssh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b signature-scope --volatile
sandbox_home
no_agent
make_gateway "$HOME/work/inference-gateway"
make_signing_key you_2026 'you@example.com signing key 2026'
make_signing_key stranger 'unknown key'
allow_signer you@example.com you_2026
hidden 'git config set --global gpg.format ssh'
hidden 'git config set --global user.signingKey ~/keys/you_2026.pub'
hidden 'git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers'
hidden 'git config set --global commit.gpgSign true'
tick; printf 'burst: 20\n' >> config/limits.yaml
hidden 'git commit -am "Allow short bursts"'
hidden 'git tag -s -m "inference-gateway 1.0.0" v1.0.0'

snip 01-tamper
run "git log -1 --format='%h  %G?  %GS  %s'"
note 'Write a second commit object: same headers, same signature, one word of the message changed.'
run "git cat-file commit HEAD | sed 's/short bursts/unlimited bursts/' | git hash-object -t commit -w --stdin > ../forged-id"
run 'git cat-file -p "$(cat ../forged-id)" | tail -1'
run_rc 'git verify-commit "$(cat ../forged-id)"'
run "git log -1 --format='%G?  %s' \"\$(cat ../forged-id)\""

snip 02-refs-are-not-signed
note 'The signature is inside the object. Which refs point at the object is not part of it.'
run 'git branch hotfix/anything HEAD'
run "git log -1 --format='%G?  %D' hotfix/anything"
run 'git update-ref refs/tags/v9.9.9 "$(git rev-parse v1.0.0)"'
run_rc 'git verify-tag v9.9.9'
run 'git cat-file -p v9.9.9 | sed -n 1,3p'
run 'git tag -d v9.9.9'

snip 03-rewrites-drop-signatures
run 'git commit -q --allow-empty -m "Trigger the nightly evaluation"'
run "git log -2 --format='%h  %G?  %s'"
run 'git commit -q --amend --allow-empty --no-gpg-sign -m "Trigger the nightly evaluation run"'
run "git log -2 --format='%h  %G?  %s'"
run 'git rebase -q --no-gpg-sign --force-rebase HEAD~2'
run "git log -2 --format='%h  %G?  %s'"
run 'git rebase -q --gpg-sign --force-rebase HEAD~2'
run "git log -2 --format='%h  %G?  %s'"

snip 04-unknown-key
run 'git -c user.signingKey=~/keys/stranger.pub commit -q --allow-empty -m "Bump the model default"'
run_rc 'git verify-commit HEAD'
run "git log -1 --format='%h  %G?  signer=%GS  trust=%GT  %s'"

snip 05-key-lifetime
note 'The lab clock says 7 September 2026. Give the key a validity window that ended on 31 August.'
run "printf 'you@example.com namespaces=\"git\",valid-before=\"20260831\" %s\n' \"\$(cut -d' ' -f1,2 ~/keys/you_2026.pub)\" > ~/allowed_signers"
run_rc 'git verify-commit HEAD~1'
note 'The verify time is the committer date, and the committer date is whatever the committer says.'
run "GIT_COMMITTER_DATE='2026-08-30T12:00:00+05:30' git commit -q --allow-empty -m 'Rotate the staging credentials'"
run_rc 'git verify-commit HEAD'
run "git log -1 --format='%h  %G?  committed %cs  %s'"

snip 06-revocation
run "cut -d' ' -f1,2 ~/keys/you_2026.pub > ~/revoked_keys"
run 'git config set --global gpg.ssh.revocationFile ~/revoked_keys'
run_rc 'git verify-commit HEAD'
run "git log -1 --format='%h  %G?  %s'"

lab_end

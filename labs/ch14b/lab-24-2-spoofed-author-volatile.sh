#!/usr/bin/env bash
# Lab 24.2 replay, volatile part: the same forgery in a repository whose team signs.
# An unsigned forgery, a forgery signed with your own key, the policy check that compares
# signer and author, and what git merge --verify-signatures does and does not look at.
# VOLATILE: fresh key pairs are generated inside the sandbox on every run. No agent,
# no real ~/.ssh, no real configuration.
# Lab manual: lab-manual/m24-signing-local.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-24-2-spoofed-author-volatile --volatile
scenario_24_2
as config
# The state the deterministic part ends in: two forged commits, pushed.
cd you/inference-gateway || exit 1
tick; printf 'requests_per_minute: 6000\n' > config/limits.yaml
hidden 'git commit -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"'
tick; printf 'requests_per_minute: 60000\n' > config/limits.yaml
hidden 'git -c user.name="Asha Rao" -c user.email=asha@example.com commit -am "Raise the rate limit again"'
hidden 'git push'
hidden 'git -C ../../asha/inference-gateway pull'
cd ../.. || exit 1

snip 01-keys
run 'unset SSH_AUTH_SOCK'
run 'mkdir keys'
run "ssh-keygen -q -t ed25519 -N '' -C 'you@example.com' -f keys/you"
run "ssh-keygen -q -t ed25519 -N '' -C 'asha@example.com' -f keys/asha"
run "printf 'you@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 keys/you.pub)\" > allowed_signers"
run "printf 'asha@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 keys/asha.pub)\" >> allowed_signers"
run 'cut -d" " -f1-3 allowed_signers'

snip 02-team-signs
note 'Shared signing settings in one file that each clone includes; the key is per person.'
run "printf '[gpg]\n\tformat = ssh\n[gpg \"ssh\"]\n\tallowedSignersFile = %s/allowed_signers\n[commit]\n\tgpgSign = true\n' \"\$PWD\" > team-signing.inc"
run 'for p in you asha; do git -C $p/inference-gateway config set include.path "$PWD/team-signing.inc"; git -C $p/inference-gateway config set user.signingKey "$PWD/keys/$p.pub"; done'
run 'cd asha/inference-gateway'
run "printf 'def ready():\n    return True\n' > gateway/ready.py"
run 'git add gateway/ready.py'
run 'git commit -q -m "Add readiness endpoint"'
run 'git push -q'
run "git log -1 --format='%h  %G?  author=%ae  signer=%GS  %s'"

snip 03-failure
note 'Back in your clone. You still cannot sign as Asha, but you can sign as yourself.'
run 'cd ../../you/inference-gateway'
run 'git pull -q'
run "printf 'requests_per_minute: 600000\n' > config/limits.yaml"
run 'git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Remove the rate limit in practice"'
run_rc 'git verify-commit HEAD'
run "git log -4 --format='%h  %G?  author=%ae  signer=%GS  %s'"

snip 04-policy-check
run "git log -4 --format='%h %G? %ae %GS' | awk '{ ok = (\$2 == \"G\" && \$3 == \$4) ? \"ok  \" : \"FAIL\"; print ok, \$0 }'"

snip 05-merge-verify
run 'git switch -q -c integration HEAD~3'
run_rc 'git merge --verify-signatures --ff-only main~2'
run_rc 'git merge --verify-signatures --ff-only main'
run "git log -4 --format='%h  %G?  author=%ae  signer=%GS'"

snip 06-recovery
note 'Published history stays. The forged changes are undone by commits that say so, signed by you.'
run 'git switch -q main'
run 'git branch -q -D integration'
run 'git revert --no-edit HEAD HEAD~2 HEAD~3'
run 'cat config/limits.yaml'
run 'git push -q'

snip 07-verify
run "git log -7 --format='%h %G? %ae %GS' | awk '{ ok = (\$2 == \"G\" && \$3 == \$4) ? \"ok  \" : \"FAIL\"; print ok, \$0 }'"
run "git log -3 --format='%h  %an  %s'"

lab_end

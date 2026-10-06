#!/usr/bin/env bash
# Lab 13.1 replay, volatile part: the third kind of tag, a signed one.
# VOLATILE: a fresh key pair is generated inside the sandbox, so the key, the signature and
# the tag object ID differ on each run. No agent, no ~/.ssh, no real configuration.
# Lab manual: lab-manual/m13-tags-versions.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-13-1-three-tags-volatile --volatile
scenario_13_1
as config
no_agent
cd inference-gateway || exit 1
# The state after steps 1 to 3 of the lab.
hidden 'git tag staging-ok'
hidden 'git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."'

snip 01-key
run 'unset SSH_AUTH_SOCK'
run 'mkdir ../keys'
run "ssh-keygen -q -t ed25519 -N '' -C 'release signing key (lab)' -f ../keys/release_key"
run 'git config set gpg.format ssh'
run 'git config set user.signingKey "$PWD/../keys/release_key.pub"'

snip 02-signed-tag
run 'git tag -s v0.9.0 -m "inference-gateway 0.9.0 (preview)" HEAD~1'
run 'git cat-file -t v0.9.0'
run 'git cat-file -p v0.9.0'

snip 03-verify
run_rc 'git verify-tag v0.9.0'
run "printf 'release@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 ../keys/release_key.pub)\" > ../allowed_signers"
run 'git config set gpg.ssh.allowedSignersFile "$PWD/../allowed_signers"'
run_rc 'git verify-tag v0.9.0'
run_rc 'git verify-tag v1.0.0'

snip 04-three-kinds
run 'for t in staging-ok v1.0.0 v0.9.0; do printf "%-11s %-7s signature blocks: " $t $(git cat-file -t $t); git cat-file -p $t | grep -c "BEGIN SSH SIGNATURE"; done'
run 'git tag -v v0.9.0'

lab_end

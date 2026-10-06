#!/usr/bin/env bash
# Lab 24.1 replay: SSH signing end to end, locally. Key, configuration, a signed commit,
# verification with an allowed-signers file, signing by default, a signed tag, and a key
# rotation that makes last year's history look unsigned until it is done properly.
# VOLATILE: fresh key pairs are generated inside the sandbox on every run, so keys,
# signatures and object IDs differ each time. No agent, no real ~/.ssh, no real configuration.
# Lab manual: lab-manual/m24-signing-local.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-24-1-ssh-signing --volatile
scenario_24_1
as config

snip 01-enter
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run 'unset SSH_AUTH_SOCK'
run 'mkdir ~/keys'
run "ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_2026"
run 'ssh-keygen -l -f ~/keys/signing_2026.pub'

snip 02-configure-and-sign
run 'git config set --global gpg.format ssh'
run 'git config set --global user.signingKey ~/keys/signing_2026.pub'
run 'cd ~/work/inference-gateway'
run "printf 'burst: 20\n' >> config/limits.yaml"
run 'git commit -q -S -am "Allow short bursts"'
run 'git cat-file -p HEAD'

snip 03-verify-fails
run_rc 'git verify-commit HEAD'
run "git log -1 --format='%h  %G?  %s'"

snip 04-allowed-signers
run "printf 'you@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 ~/keys/signing_2026.pub)\" > ~/allowed_signers"
run 'git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers'
run_rc 'git verify-commit HEAD'
run "git log -2 --format='%h  %G?  %GS  %s'"

snip 05-default-and-tag
run 'git config set --global commit.gpgSign true'
run 'git config set --global tag.gpgSign true'
run "printf 'retry_after_seconds: 2\n' >> config/limits.yaml"
run 'git commit -q -am "Tell clients when to retry"'
run 'git tag -m "inference-gateway 1.0.0" v1.0.0'
run 'git cat-file -p v1.0.0'
run_rc 'git verify-tag v1.0.0'
run "git log -3 --format='%h  %G?  %GS  %s'"

snip 06-failure
note 'New year, new key. The old line in allowed_signers is replaced by the new one.'
run "ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2027' -f ~/keys/signing_2027"
run 'git config set --global user.signingKey ~/keys/signing_2027.pub'
run "printf 'you@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 ~/keys/signing_2027.pub)\" > ~/allowed_signers"
run 'git commit -q --allow-empty -m "Trigger the nightly evaluation"'
run "git log -4 --format='%h  %G?  %GS  %s'"
run_rc 'git verify-tag v1.0.0'

snip 07-recovery
note 'A rotation adds a key. The old key stays listed, or everything it signed stops verifying.'
run "printf 'you@example.com namespaces=\"git\" %s\n' \"\$(cut -d' ' -f1,2 ~/keys/signing_2026.pub)\" >> ~/allowed_signers"
run 'cut -d" " -f1-3 ~/allowed_signers'
run "git log -4 --format='%h  %G?  %GS  %GK'"
run_rc 'git verify-tag v1.0.0'

snip 08-verify
run 'git config get --global --all --show-names --regexp "^(gpg|commit\.gpgsign|tag\.gpgsign|user\.signingkey)"'
run "git log --format='%G?' | sort | uniq -c | sed 's/^ *//'"
run "git cat-file -p HEAD | grep -c 'BEGIN SSH SIGNATURE'"

lab_end

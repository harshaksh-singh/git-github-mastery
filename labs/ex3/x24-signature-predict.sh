#!/usr/bin/env bash
# Exercise 24.2 (Module 24): five commits with five different identity claims, what Git
# reports for each, and what a merge with --verify-signatures and a rebase do to them.
# VOLATILE: fresh keys inside the sandbox on every run, so IDs and signatures differ.
# No agent, no ~/.ssh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x24-signature-predict --volatile
sandbox_home
make_signing_key you  'you@example.com signing key'
make_signing_key asha 'asha@example.com signing key'
make_signing_key ravi 'ravi@example.com signing key'
allow_signer you@example.com you
allow_signer asha@example.com asha
hidden 'git config set --global gpg.format ssh'
hidden 'git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers'
hidden 'git config set --global user.signingKey ~/keys/you.pub'
hidden 'git init ~/work/chunker'
cd "$HOME/work/chunker" || exit 1
split_v1; commit_all 'Add fixed-size splitter'
hidden 'git switch -c feature/retry'
FMT="--format='%G?  author=%ae  signer=%GS  %s'"

snip 01-setup
note 'allowed_signers lists two principals:'
run "cut -d' ' -f1 ~/allowed_signers"
note 'Five commits on feature/retry, oldest first:'
run "printf 'retries: 3\n' > retry.yaml && git add retry.yaml && git commit -q -S -m 'c1 add retry config'"
run "printf 'retries: 4\n' > retry.yaml && git commit -q -am 'c2 raise retries'"
as ravi
run "printf 'retries: 5\n' > retry.yaml && git -c user.signingKey=~/keys/ravi.pub commit -q -S -am 'c3 raise retries again (Ravi, his key)'"
as you
run "printf 'retries: 6\n' > retry.yaml && git commit -q -S --author='Asha Rao <asha@example.com>' -am 'c4 written by you, author field says Asha'"
as asha
run "printf 'retries: 2\n' > retry.yaml && git -c user.signingKey=~/keys/asha.pub commit -q -S -am 'c5 lower retries (Asha, her key)'"
as you

snip 02-states
run "git log --reverse $FMT main..feature/retry"

snip 03-verify-commit
run 'git verify-commit feature/retry~2 2>&1 | cut -c1-36'
run_rc 'git verify-commit feature/retry~2 > /dev/null 2>&1'
run_rc 'git verify-commit feature/retry~1 > /dev/null 2>&1'
run_rc 'git verify-commit feature/retry~3 > /dev/null 2>&1'

snip 04-merge
run 'git switch -q -c integration main'
run_rc 'git merge --verify-signatures --no-ff -m "Merge feature/retry" feature/retry > /dev/null 2>&1'
run "git log --format='%G?  %s' -6"

snip 05-rebase
note 'main gains one commit, then you rebase feature/retry onto it: first plainly, then with -S.'
run "git switch -q main && printf '# chunker\\n' > README.md && git add README.md && git commit -q -S -m 'Add README'"
run 'git switch -q feature/retry'
run 'git rebase -q main'
run "git log --reverse $FMT main..feature/retry"
run 'git rebase -q --force-rebase -S main'
run "git log --reverse $FMT main..feature/retry"

lab_end

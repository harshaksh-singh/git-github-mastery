#!/usr/bin/env bash
# Lab 24.3 replay, local part: three unsigned commits with different author and committer
# claims, and what Git records for each. What GitHub displays for them is described from
# documentation in the lab manual; signing itself is Lab 24.1 (Chapter 14B).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21b lab-24-3-verification-states
quiet 'git init signing-states'

snip 01-three-commits
run 'cd signing-states'
run "printf 'states\n' > notes.md && git add notes.md"
run "git commit -q -m 'A: my commit, unsigned'"
run "printf 'author claim\n' >> notes.md"
run "git commit -q -a --author='Asha Rao <asha@example.com>' -m 'B: author is a claim; committer is me'"
run "printf 'both claims\n' >> notes.md"
run "GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -a --author='Asha Rao <asha@example.com>' -m 'C: author and committer are claims'"

snip 02-what-git-recorded
run "git log --reverse --format='%h %s%n        author=%ae committer=%ce signature=%G?'"

snip 03-no-signature-header
run 'git cat-file -p HEAD | sed -n "1,4p"'
run_rc 'git verify-commit HEAD'

snip 04-failure
note 'Failure scenario: signing is switched on before a key is configured.'
run 'git config set gpg.format ssh'
run 'git config set commit.gpgSign true'
run "printf 'signed?\n' >> notes.md"
run_rc "git commit -a -m 'D: first signed commit' 2>&1"
run 'git log --oneline -1'
run 'git status -s'

snip 05-recovery
run 'git config get --show-origin commit.gpgSign'
run_rc 'git config get user.signingKey'
note 'Nothing was committed and the change is still in the working tree. Until the key exists:'
run 'git config unset commit.gpgSign'
run "git commit -q -a -m 'D: unsigned until the signing key is configured'"
run "git log --format='%h %G? %s' -1"
lab_end

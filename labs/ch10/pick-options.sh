#!/usr/bin/env bash
# Chapter 10, section 10.4: -e opens the editor on the message (with -x, the "cherry picked from" line is
# already in it), -n applies the change to the index and the working tree without committing.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-options
fx_gateway_fix

snip 01-edit
run_add_paragraph 'Backported to 1.4 because customers on 1.4.0 hit the error path.' 'git cherry-pick -e -x main~1'
run 'git log -1 --format=%B'

snip 02-no-commit
quiet 'git reset --hard HEAD~1'
run 'git cherry-pick -n main~1'
run 'git status --short'
run_rc 'git rev-parse --verify --quiet CHERRY_PICK_HEAD'

snip 03-no-commit-author
run 'git commit -m "Reject empty prompts (1.4 variant)"'
run 'git log -1 --format="author %an, committer %cn"'
run 'git log -1 --format="author %an, committer %cn" main~1'
lab_end

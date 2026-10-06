#!/usr/bin/env bash
# Lab 42.3 replay: send a branch as patch files and apply it in a repository that cannot fetch
# from yours. Failure: the maintainer's branch has moved and "git am" stops because the patch
# does not apply. Recovery: abort, apply again with a three-way merge, resolve, and continue.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d lab-42-3-format-patch-am
fx_42_3

snip 01-format-patch
run 'cd fork'
run 'git log --oneline origin/main..fix/casefold'
run 'git format-patch -o ../outbox origin/main'

snip 02-read
run "sed -n '1,8p' ../outbox/0001-tok-casefold-the-input-before-splitting.patch"
run 'git apply --stat ../outbox/*.patch'

snip 03-am
as ravi
run 'cd ../upstream'
run_rc 'git apply --check ../outbox/0001-tok-casefold-the-input-before-splitting.patch'
run 'git switch -q -c review/casefold'
run 'git am ../outbox/*.patch'
run "git log --format='%h author: %an, committer: %cn | %s'"

snip 04-compare
run "git rev-parse 'review/casefold^{tree}'"
run "git -C ../fork rev-parse 'fix/casefold^{tree}'"
run 'git rev-parse --short review/casefold'
run 'git -C ../fork rev-parse --short fix/casefold'

snip 05-failure
note 'Before the series is applied to main, the maintainer commits a change to the same line:'
run 'git switch -q main'
run "printf 'def tokenize(text):\n    return text.strip().split()\n' > tok.py"
run 'git commit -q -am "tok: strip the input"'
run_rc 'git -c advice.mergeConflict=false am ../outbox/*.patch'

snip 06-state
run 'git status'
run 'git am --show-current-patch=diff | tail -n 9'

snip 07-recovery
run 'git am --abort'
run 'git status -sb'
run_rc 'git -c advice.mergeConflict=false am -3 ../outbox/*.patch'
run 'cat tok.py'

snip 08-continue
run "printf 'def tokenize(text):\n    return text.strip().casefold().split()\n' > tok.py"
run 'git add tok.py'
run 'git am --continue'

snip 09-verification
run "git log --format='%h author: %an, committer: %cn | %s' -3"
run 'cat tok.py'
run 'git status -sb'

lab_end

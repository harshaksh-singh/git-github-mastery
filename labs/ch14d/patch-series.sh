#!/usr/bin/env bash
# Chapter 14D, section 14D.11: the patch-based workflow of the Git project in miniature.
# A contributor turns a branch into a patch series with a cover letter, the maintainer applies it
# with "git am", the contributor sends a second version, and "git range-diff" shows what changed
# between the versions.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d patch-series
fx_patch_repos

snip 01-format-patch
as asha
run 'cd contributor'
run "git log --format='%h %an | %s' origin/main..casefold"
run 'git format-patch --cover-letter --base=origin/main -o ../outbox/v1 origin/main'

snip 02-patch-file
run 'cat ../outbox/v1/0001-tok-lowercase-the-input-before-splitting.patch'

snip 03-cover-letter
run "sed -n '/^Subject/,\$p' ../outbox/v1/0000-cover-letter.patch"

snip 04-am
as ravi
note 'The maintainer, in a repository that has never seen the branch:'
run 'cd ../upstream'
run 'git switch -q -c review/casefold'
run 'git am ../outbox/v1/0001-*.patch ../outbox/v1/0002-*.patch'
run "git log --format='%h author: %an, committer: %cn | %s' -2"
run 'git log -1 --format=%B'

snip 05-same-change-new-id
note 'The applied commits have new IDs and the same content as the originals:'
run "git rev-parse 'HEAD^{tree}'"
run "git -C ../contributor rev-parse 'casefold^{tree}'"
run 'git show HEAD~1 | git patch-id --stable | cut -d" " -f1'
run 'git -C ../contributor show casefold~1 | git patch-id --stable | cut -d" " -f1'

snip 06-v2
as asha
note 'Review asked for casefold() instead of lower(). The contributor keeps v1 and rewrites the branch:'
run 'cd ../contributor'
run 'git branch casefold-v1'
quiet "printf 'def tokenize(text):\n    return text.casefold().split()\n' > tok.py && git add tok.py && git commit --fixup=HEAD~1"
quiet 'GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main'
run 'git range-diff origin/main casefold-v1 casefold'

snip 07-v2-series
run 'git format-patch -v2 --cover-letter --range-diff=casefold-v1 --base=origin/main -o ../outbox/v2 origin/main'
run "sed -n '/^Range-diff/,/^-- /p' ../outbox/v2/v2-0000-cover-letter.patch"

lab_end

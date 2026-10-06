#!/usr/bin/env bash
# Chapter 10, sections 10.2 and 10.3: a cherry-pick is a three-way merge whose base is the parent of the
# picked commit. The same change fails as a patch, succeeds as a cherry-pick, and "git merge-tree" with
# that base predicts the resulting tree exactly. Then: the new commit object next to the original.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-three-way
fx_gateway_fix

snip 01-before
run 'git log --graph --decorate --all --format="%h %an: %s%d"'

snip 02-the-change
run 'git show --format="%h %s" main~1'

snip 03-as-a-patch
note 'On release/1.4 the line MAX_RETRIES = 2 reads MAX_RETRIES = 3. Try the change as a plain patch:'
run_rc 'git format-patch -1 --stdout main~1 | git apply --check'

snip 04-predict
note 'A three-way merge with the parent of the picked commit as the base:'
run 'git merge-tree --write-tree --merge-base=main~2 HEAD main~1'

snip 05-pick
run 'git cherry-pick main~1'
run 'git rev-parse HEAD^{tree}'
run 'cat src/client.py'

snip 06-objects
note 'The original commit on main ...'
run 'git cat-file -p main~1'
note '... and the commit that the cherry-pick created.'
run 'git cat-file -p HEAD'

snip 07-after
run 'git log --graph --decorate --all --format="%h %an: %s%d"'
run 'git reflog -1'
lab_end

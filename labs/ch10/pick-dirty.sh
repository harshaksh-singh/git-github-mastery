#!/usr/bin/env bash
# Chapter 10, section 10.2: what cherry-pick demands of the working tree and the index. An unstaged
# edit in a file the pick does not touch is tolerated; an unstaged edit in a file it must write is
# refused; any staged change is refused. Nothing is lost in the two refusals.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-dirty
fx_gateway_fix

snip 01-unrelated-edit
note 'An uncommitted edit in VERSION. The picked commit changes only src/client.py.'
quiet "printf '1.4.1-rc1\n' > VERSION"
run 'git status --short'
run 'git cherry-pick main~1'
run 'git status --short'

snip 02-edit-in-the-way
quiet 'git reset --hard HEAD~1'
note 'Now the uncommitted edit is in the file that the picked commit changes.'
quiet "printf '# checked by ops\n' >> src/client.py"
run 'git status --short'
run_rc 'git cherry-pick main~1'
run 'git status --short'

snip 03-staged-change
quiet 'git restore src/client.py'
note 'A staged change, in a file the picked commit does not touch.'
quiet "printf '1.4.1-rc1\n' > VERSION"
run 'git add VERSION'
run_rc 'git cherry-pick main~1'
run 'git status --short'
lab_end

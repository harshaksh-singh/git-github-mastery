#!/usr/bin/env bash
# modify/delete: one branch edits a file that the other branch deletes. Chapter 8, section 8.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-modify-delete

quiet 'ek_base'
quiet 'mkdir scripts && printf "#!/bin/sh\npython -m evalkit --config config/eval.yaml\n" > scripts/legacy_eval.sh'
quiet 'ek_commit "Add the legacy eval script"'
quiet 'git switch -c cleanup/remove-legacy'
as ravi
quiet 'git rm -q scripts/legacy_eval.sh && ek_commit "Remove the legacy eval script"'
as you
quiet 'git switch main'
quiet 'printf "echo \"eval finished\"\n" >> scripts/legacy_eval.sh && ek_commit "Print a line when the legacy eval finishes"'

snip 01-merge
run_rc 'git merge cleanup/remove-legacy'
run 'git status'

snip 02-stages
run 'git status --short'
run 'git ls-files -u'
run 'ls scripts'

snip 03-restore-vs-checkout
note 'Stage 3 does not exist for this path. The two commands react differently:'
run_rc 'git checkout --theirs scripts/legacy_eval.sh'
run_rc 'git restore --theirs scripts/legacy_eval.sh'
run_rc 'test -f scripts/legacy_eval.sh'
run 'git status --short'
run 'git restore --ours scripts/legacy_eval.sh'
run_rc 'test -f scripts/legacy_eval.sh'
run_rc 'git restore --merge scripts/legacy_eval.sh'

# The mirror image: stand on the branch that deleted the file and merge the branch that edited it.
quiet 'git merge --abort && git switch cleanup/remove-legacy'

snip 04-deleted-by-us
run_rc 'git merge main'
run 'git status --short'
run 'git ls-files -u'
note 'Decision on this branch: keep the edited file.'
run 'git add scripts/legacy_eval.sh'
run 'git status --short'

quiet 'git merge --abort && git switch main && git merge cleanup/remove-legacy'

snip 05-resolve-delete
note 'Back on main, same conflict as in the first snippet. Decision: the deletion wins.'
run 'git rm scripts/legacy_eval.sh'
run 'git status --short'
run 'git merge --continue'
run 'git ls-files'

lab_end

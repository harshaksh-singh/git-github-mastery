#!/usr/bin/env bash
# Lab 37.5, failure scenario and recovery: after the rewrite, a teammate with a stale branch
# merges instead of rebasing and pushes. The removed commits are back on the server.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-37-5-committed-secret
incident_load 03-committed-secret
# The rewrite of the solution, without transcript: Ravi edits the adding commit and force-pushes.
cd ravi || exit 1
as ravi
add=$(git log --diff-filter=A --format=%h -- .env)
rm=$(git log --diff-filter=D --format=%h -- .env)
mv .env ../ravi-local.env
tick
GIT_SEQUENCE_EDITOR="sed -i.bak -e 's/^pick $add /edit $add /' -e 's/^pick $rm /drop $rm /'" git rebase -i main > /dev/null 2>&1
quiet "git rm --cached .env && printf '.env\n' >> .gitignore && git add .gitignore && git commit --amend --no-edit && git rebase --continue"
quiet 'git push --force-with-lease'
as you
cd "$LAB_DIR" || exit 1

snip 01-failure
note "Ravi's branch has been rewritten and force-pushed. Asha has not been told what to do."
run 'cd asha'
run 'git fetch'
note 'The tempting move: bring in the latest state of the branch mine is built on.'
run "git merge -m 'Merge the updated email-digest branch' origin/feature/email-digest"
run 'git push'
run 'git log --oneline --graph feature/digest-template -8'
note 'Is the file back in the history of a branch on the server?'
run "git log --format='%h %s' origin/feature/digest-template -- .env"
run "git branch -r --contains $add"

snip 02-recovery
note 'Back to the tip before the merge, then transplant, then force with a lease:'
run "git reset --keep 'feature/digest-template@{1}'"
run "git rebase --onto origin/feature/email-digest 'origin/feature/email-digest@{1}'"
run 'git push --force-with-lease --force-if-includes'
run "git log --format='%h %s' origin/feature/digest-template -- .env"
run_rc "git branch -r --contains $add"
lab_end

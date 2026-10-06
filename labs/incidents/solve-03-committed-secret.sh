#!/usr/bin/env bash
# Replay of incident 3 (a committed secret): scope, rewrite, publication and clean-up as real
# transcripts for Chapter 30 and solutions/incident-03-committed-secret.md. The secret is a
# dummy string. Rotation, the first step of the real response, cannot be replayed.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-03-committed-secret
incident_load 03-committed-secret

snip 01-find
run 'cd you'
run 'git fetch'
note 'Every commit, on any branch, that added or removed the file:'
run "git log --all --format='%h %an: %s' -- .env"

snip 02-scope
add=$(git log --all --diff-filter=A --format=%h -- .env)
rm=$(git log --all --diff-filter=D --format=%h -- .env)
note 'Which branches on the server can reach the commit that added it?'
run "git branch -r --contains $add"
note 'In how many snapshots is the file present?'
run "git grep -c SMTP_PASSWORD \$(git rev-list --all) -- .env"
note 'Since when has it been on the server? The pushing clone recorded it:'
run "git -C ../ravi reflog show --date=iso origin/feature/email-digest"
note 'Is the branch "clean now"? The tip has no .env. The history under the tip has:'
run_rc 'git cat-file -e origin/feature/email-digest:.env'
run "git show $add:.env"

snip 03-rewrite
run 'cd ../ravi'
run 'git status -sb'
note 'The rebase will check out the commit that contains .env. Git refuses to overwrite an'
note 'untracked file of the same name, so the local copy is moved out of the repository first.'
run 'mv .env ../ravi-local.env'
run_todo "s/^pick $add /edit $add /; s/^pick $rm /drop $rm /" 'git rebase -i main'

snip 04-amend
run 'git rm --cached .env'
run "printf '.env\n' >> .gitignore"
run 'git add .gitignore'
run 'git commit --amend --no-edit'
run 'git rebase --continue'

snip 05-check-rewrite
run "git log --oneline main..feature/email-digest"
run "git log --oneline feature/email-digest -- .env"
run "git range-diff 'feature/email-digest@{u}'...feature/email-digest"
run 'git status -sb --ignored'

snip 06-publish
run 'git push --force-with-lease --force-if-includes'

snip 07-dependent-branch
run 'cd ../asha'
run 'git fetch'
run "git rebase --onto origin/feature/email-digest 'origin/feature/email-digest@{1}' feature/digest-template"
run 'git log --oneline main..feature/digest-template'
run 'git push --force-with-lease --force-if-includes'

snip 08-server-still-has-it
run 'cd ../you'
note 'No ref on the server reaches the old commits now. The objects are still there:'
run "git -C ../server.git cat-file -t $add"
run "git -C ../server.git show $add:.env"

snip 09-server-prune
note 'You are the administrator of this server. On GitHub this step is a request to GitHub Support.'
run 'git -C ../server.git gc --prune=now'
run_rc "git -C ../server.git cat-file -t $add"

snip 10-clones
run 'git fetch'
run "git cat-file -t $add"
note 'Every clone that ever fetched the branch keeps the objects through its reflogs.'
run 'for c in you ravi asha; do git -C ../$c reflog expire --expire=now --all && git -C ../$c gc --prune=now; done'
run_rc "git cat-file -t $add"

snip 11-verify
run "git log --all --oneline -- .env"
run 'git log --oneline --graph --all'
run 'cd ..'
show_check
incident_done

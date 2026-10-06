#!/usr/bin/env bash
# Chapter 21B, sections 21B.16 to 21B.18: the mechanics of a whole-history rewrite, shown with
# git filter-branch because it ships with Git. filter-branch is NOT the recommended tool
# (its own manual says so); git-filter-repo is. The mechanics shown here are the same for both:
# every descendant commit gets a new ID, tags must be rewritten too, the old objects remain
# until pruned, and the server keeps them after the force push.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b rewrite-mechanics
fx_ragdesk

snip 01-fresh-mirror-clone
run 'git clone -q --mirror server.git cleanup.git'
run 'cd cleanup.git'
run 'git for-each-ref --format="%(objectname:short) %(objecttype) %(refname)"'
run 'git log --oneline main'
run 'first=$(git log --format=%h --diff-filter=A main -- .env); echo $first'
quiet 'git log --format=%h main > ../before.txt'

snip 02-branches-only
note 'First attempt: rewrite the branches and forget the tags.'
run "FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' -- --branches > ../filter-1.log 2>&1"
run "grep -v 'seconds passed' ../filter-1.log"
run "git grep -l DUMMY-KEY \$(git rev-list --branches) | wc -l"
run "git grep -l DUMMY-KEY \$(git rev-list --all) | cut -c1-9,41-"
run 'git tag --contains $first'

snip 03-all-refs
note 'Second attempt: every ref, and --tag-name-filter cat so that tags follow their commits.'
run "FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter-2.log 2>&1"
run "grep -v 'seconds passed' ../filter-2.log"

snip 04-new-ids
quiet 'git log --format=%h main > ../after.txt'
note 'old ID, new ID, subject (newest first)'
run "paste ../before.txt ../after.txt | while read o n; do printf '%s  %s  %s\n' \$o \$n \"\$(git log -1 --format=%s \$n)\"; done"

snip 05-old-objects-remain
run 'git for-each-ref --format="%(objectname:short) %(refname)" refs/original'
run 'git cat-file -t $first'
run 'git show $first:.env'

snip 06-prune
run 'git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin'
run 'git reflog expire --expire=now --all'
run 'git gc -q --prune=now'
run_rc 'git cat-file -t $first'
run "git grep -l DUMMY-KEY \$(git rev-list --all) | wc -l"
run 'git fsck --no-progress'

snip 07-force-push
run 'git push --force --mirror origin 2>&1'

snip 08-server-keeps-old-objects
run 'cd ..'
run 'git -C server.git log --oneline -1 main'
run "git -C server.git grep -l DUMMY-KEY \$(git -C server.git rev-list --all) | wc -l"
note 'No ref on the server reaches the old commits any more, and they are still there:'
run 'git -C server.git cat-file -t $first'
run 'git -C server.git show $first:.env'
run 'git -C server.git fsck --no-progress --unreachable | grep commit'

snip 09-stale-clone
run 'cd asha'
run 'git log --oneline -3'
run 'git pull --no-rebase 2>&1'
run 'git log --oneline --graph -6'
run 'git push 2>&1'

snip 10-secret-is-back
run 'cd ..'
run "git -C server.git log --oneline -3 main"
run "git -C server.git grep -l DUMMY-KEY \$(git -C server.git rev-list --all) | wc -l"
run "git -C server.git log --oneline -S'DUMMY-KEY' main"
lab_end

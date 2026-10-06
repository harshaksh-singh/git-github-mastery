#!/usr/bin/env bash
# Chapter 21B, section 21B.18: three ways a stale clone can meet a rewritten history.
# "git pull --rebase" as the first contact replays only the local commit; "git fetch" followed
# by "git rebase origin/main" tries to replay the old history; "--onto" with the old base is
# the form that always says what you mean. The rewrite itself uses git filter-branch only
# because it ships with Git; it is not the recommended tool.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b stale-clone-rebase
fx_ragdesk
# A third stale clone with the same local commit as Asha's, for the third variant.
quiet 'cp -R asha asha2 && git -C asha2 status'
quiet 'cp -R asha asha3 && git -C asha3 status'
quiet 'git clone --mirror server.git cleanup.git'
cd cleanup.git || exit 1
quiet "FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all"
quiet 'git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin'
quiet 'git push --force --mirror origin'
cd "$LAB_DIR" || exit 1

snip 01-pull-rebase-first-contact
run 'cd asha'
run 'git log --oneline -2'
run 'git pull -q --rebase 2>&1'
run 'git log --oneline -3'
run 'git grep -l DUMMY-KEY $(git rev-list HEAD) | wc -l'
run 'cd ..'

snip 02-fetch-then-rebase
run 'cd asha2'
run 'git fetch -q 2>&1'
run 'git rebase origin/main 2>&1 | grep -E "^(CONFLICT|error|Could not)"'
run 'git status -sb | head -1'
run 'git rebase --abort'
run 'cd ..'

snip 03-onto-old-base
run 'cd asha3'
run 'git fetch -q 2>&1'
run 'old=$(git reflog show main --format=%h | tail -1); echo $old'
run 'git rebase -q --onto origin/main $old 2>&1'
run 'git log --oneline -3'
run 'git grep -l DUMMY-KEY $(git rev-list HEAD) | wc -l'
lab_end

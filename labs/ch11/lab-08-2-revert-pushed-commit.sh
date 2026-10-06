#!/usr/bin/env bash
# Lab 8.2 replay: revert a commit that is already on origin/main, push the revert, and watch a
# teammate receive it as an ordinary fast-forward. Failure: trying to erase the commit with
# reset and being rejected by the server. Recovery: reset to the upstream branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-2-revert-pushed-commit
fx_08_2
cd you || exit 1
bad=$(git rev-parse --short HEAD~1)
bad_full=$(git rev-parse HEAD~1)
first=$(git rev-parse --short HEAD~2)
cd "$LAB_DIR" || exit 1

snip 01-investigate
run 'cd you'
run 'git status -sb'
run 'git log --format="%h %an: %s"'
run "git show --stat --format='%h %s' $bad"
run "git branch -r --contains $bad"

snip 02-revert
LAB_MSG="Revert \"Raise batch size to 512\"

This reverts commit $bad_full.

Batch 512 exhausts memory on the 16 GB feature workers."
run_msg "$LAB_MSG" "git revert --edit $bad"
run 'git show -s --format=%B HEAD'
run 'cat store.yaml'

snip 03-push
run 'git status -sb'
run 'git push'
run 'git status -sb'

snip 04-teammate
run 'cd ../asha'
run 'git pull'
run 'git log --format="%h %an: %s"'
run 'cat store.yaml'

snip 05-failure
run 'cd ../you'
run "git reset --hard $first"
run 'git log --oneline'
run_rc 'git push'
run 'git status -sb'

snip 06-recovery
run 'git reset --hard @{u}'
run 'git status -sb'
run 'git log --oneline'

snip 07-verification
run "git diff --stat $first HEAD -- store.yaml"
run 'git rev-parse HEAD origin/main'
run 'git -C ../asha rev-parse HEAD'

lab_end

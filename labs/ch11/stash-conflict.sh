#!/usr/bin/env bash
# Chapter 11, section 11.11: a "git stash pop" that conflicts. The stash entry is kept, the
# conflict is an ordinary three-stage conflict, and there are two ways out: resolve and drop,
# or back out and use "git stash branch". Ends with a dropped entry brought back by its ID.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 stash-conflict

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'timeout_s: 30\nretries: 2\ncache: on\n' > serve.yaml && git add serve.yaml && git commit -m 'Add serving config'"
quiet "printf 'timeout_s: 10\nretries: 2\ncache: on\n' > serve.yaml"

snip 01-stash-then-hotfix
run 'git status -s'
run 'git stash push -m "wip: try a 10s timeout"'
run "printf 'timeout_s: 20\nretries: 2\ncache: on\n' > serve.yaml"
run 'git commit -am "Hotfix: lower timeout to 20s"'

snip 02-pop-conflict
run_rc 'git stash pop'

snip 03-conflict-state
run 'git status -s'
run 'cat serve.yaml'
run 'git stash list'

cd "$LAB_DIR" || exit 1
cp -R ranker ranker-branch
git -C ranker-branch status > /dev/null 2>&1
cd "$LAB_DIR/ranker" || exit 1
stash_id=$(git rev-parse --short 'stash@{0}')

snip 04-resolve-and-drop
run "printf 'timeout_s: 10\nretries: 2\ncache: on\n' > serve.yaml"
run 'git restore --staged serve.yaml'
run 'git status -s'
run 'git stash list'
run 'git stash drop'
run 'git stash list'

cd "$LAB_DIR/ranker-branch" || exit 1
snip 05-back-out-and-branch
run 'git reset --merge'
run 'git status -s'
run 'git stash branch try-10s-timeout'
run 'git log --oneline --decorate --all'
run 'git stash list'

# A dropped entry is still an object for a while. Its ID was printed by "git stash drop".
cd "$LAB_DIR/ranker" || exit 1

snip 06-dropped-entry-by-id
run "git stash show $stash_id"
run "git stash store -m 'recovered: try a 10s timeout' $stash_id"
run 'git stash list'

lab_end

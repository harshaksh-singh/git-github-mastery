#!/usr/bin/env bash
# Chapter 26, section 26.10: what a shallow clone is inside .git, which questions it cannot
# answer, and how to deepen it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 shallow-limits
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git clone --depth 1 "file://$PWD/server/orbit.git" ci'
cd ci || exit 1
quiet 'git config set maintenance.auto false'

snip 01-inside
run 'git rev-parse --is-shallow-repository'
run 'cat .git/shallow'
note 'The commit object is unchanged and still names its parent. Git has been told to stop there:'
run 'git cat-file -p HEAD | sed -n 1,2p'
run "git log --format='%h parents:[%p] %s'"
run_rc 'git cat-file -t HEAD~1'
run 'git config get --all remote.origin.fetch'

snip 02-wrong-answers
note 'Questions about history get short or wrong answers, without a warning:'
run 'git rev-list --count HEAD'
run 'git log --oneline -- services/ranker | wc -l'
run 'git blame -s services/gateway/routes.py | sed -n 1,3p'
run 'git shortlog -sn HEAD'
run_rc "git describe --match 'gateway/v*'"
note 'A commit-graph cannot be written while the history is cut off. Git says nothing:'
run_rc 'git commit-graph write --reachable'
run_rc 'ls .git/objects/info'

snip 03-deepen
run 'git fetch --deepen=5'
run 'git rev-list --count HEAD'
run 'cat .git/shallow'
run 'git log --oneline -- services/ranker | wc -l'

snip 04-unshallow
run 'git fetch --unshallow'
run 'git rev-parse --is-shallow-repository'
run_rc 'ls .git/shallow'
run 'git rev-list --count HEAD'
run "git describe --match 'gateway/v*'"
note 'The refspec is still the narrow one that --depth implied (Chapter 12, section 12.12):'
run 'git config get --all remote.origin.fetch'
run 'git branch -r'

lab_end

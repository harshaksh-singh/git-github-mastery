#!/usr/bin/env bash
# Chapter 26, section 26.6: the commit-graph file. What it contains, how to write and verify it,
# and what the changed-path filters save, shown as counted work (no timings).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 commit-graph
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
cd orbit || exit 1
quiet 'git config set maintenance.auto false'

snip 01-without
note 'No commit-graph yet. A path-limited log has to compare trees commit by commit:'
run_rc 'ls .git/objects/info'
run 'git rev-list --count main'
run 'git log --oneline -- services/ranker | wc -l'
note 'Git reports statistics about changed-path filters through trace2. Without a file there are none:'
run "GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'"

snip 02-write
run 'git commit-graph write --reachable --changed-paths'
run 'ls .git/objects/info'
run_rc 'git commit-graph verify'
note 'The file starts with the signature CGPH and a table of chunks:'
run 'xxd -l 96 .git/objects/info/commit-graph'

snip 03-with
note 'The same question again. One filter per commit was consulted:'
run "GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'"
run 'git log --oneline -- services/ranker | wc -l'
note 'A path that few commits touch:'
run "GIT_TRACE2_PERF=1 git log --oneline -- libs/schemas 2>&1 >/dev/null | sed -n 's/.*statistics://p'"
run 'git log --oneline -- libs/schemas'

snip 04-stale-and-split
note 'A commit-graph is a snapshot. New commits are not in it until it is written again:'
run "printf '\\nSee docs/runbooks for the on-call procedures.\\n' >> README.md"
run "git commit -q -am 'readme: point to the runbooks'"
run_rc 'git commit-graph verify'
note 'Maintenance adds a small file on top instead of rewriting the large one:'
run 'git commit-graph write --reachable --changed-paths --split'
run "find .git/objects/info -type f | sed 's/[0-9a-f]\\{40\\}/ID/' | sort"
run 'wc -l < .git/objects/info/commit-graphs/commit-graph-chain'
run_rc 'git commit-graph verify'

snip 05-switched-off
note 'A replacement object changes what the history is, so Git stops trusting the file:'
run 'git replace --graft HEAD HEAD~2'
run "GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'"
run 'git replace -d HEAD'
run "GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'"
note 'The switch that bypasses the file for one command:'
run "GIT_TRACE2_PERF=1 git -c core.commitGraph=false log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'"

lab_end

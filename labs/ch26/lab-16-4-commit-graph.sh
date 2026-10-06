#!/usr/bin/env bash
# Lab 16.4 replay: write and verify a commit-graph, count what the changed-path filters save,
# and recover from a damaged commit-graph file.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 lab-16-4-commit-graph
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-16-4-commit-graph.sh" || exit 1
cd orbit || exit 1

snip 01-before
run 'git rev-list --count HEAD'
run_rc 'ls .git/objects/info/commit-graph'
run 'git log --oneline -- docs | wc -l'
run "GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | grep -c 'statistics:'"

snip 02-write
run 'git commit-graph write --reachable --changed-paths'
run_rc 'git commit-graph verify'
run 'xxd -l 64 .git/objects/info/commit-graph'

snip 03-after
run "GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | sed -n 's/.*statistics://p'"
run "GIT_TRACE2_PERF=1 git log --oneline -- tools/ci/affected.py 2>&1 >/dev/null | sed -n 's/.*statistics://p'"
run 'git log --oneline -- tools/ci/affected.py'

snip 04-checkpoint
note 'Checkpoint: the answers are the same with and without the file.'
run 'git log --oneline -- docs | wc -l'
run 'git -c core.commitGraph=false log --oneline -- docs | wc -l'
run 'git merge-base main feature/rerank-cache'
run 'git -c core.commitGraph=false merge-base main feature/rerank-cache'

snip 05-failure
note 'Failure scenario: one damaged byte in the commit data chunk (it starts at 0xbdc = 3036).'
run 'chmod u+w .git/objects/info/commit-graph'
run "python3 -c \"import sys; f = open(sys.argv[1], 'r+b'); f.seek(3059); b = f.read(1); f.seek(3059); f.write(bytes([b[0] ^ 255])); f.close()\" .git/objects/info/commit-graph"
run_rc 'git rev-list --count HEAD'
run 'git log --oneline 2>/dev/null | wc -l'
run_rc 'git log --oneline -3'

snip 06-diagnosis
note 'Is the history damaged, or only the file that describes it? Bypass the file:'
run 'git -c core.commitGraph=false rev-list --count HEAD'
run_rc 'git commit-graph verify'
run_rc 'git fsck'
note 'With the file bypassed, the object database checks out clean:'
run_rc 'git -c core.commitGraph=false fsck'

snip 07-recovery
note 'The commit-graph is derived data. Delete it and write it again from the objects:'
run 'rm .git/objects/info/commit-graph'
run 'git rev-list --count HEAD'
run 'git commit-graph write --reachable --changed-paths'

snip 08-verification
run_rc 'git commit-graph verify'
run_rc 'git fsck'
run 'git rev-list --count HEAD'
run "GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | sed -n 's/.*statistics://p'"

lab_end

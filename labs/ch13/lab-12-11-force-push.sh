#!/usr/bin/env bash
# Lab 12.11 replay: a teammate force-pushed over two commits. Seen from your clone: the
# forced update, the old server value in the reflog of origin/main, what was lost, and a
# repair that needs no second force. Failure: "git reset --hard origin/main" throws your
# copy of the lost commits off the branch. Recovery: the same reflog, or the reflog of main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-11-force-push
fx_12_11

snip 01-before-fetch
run 'cd askdocs'
run 'git status -sb'
run 'git log --oneline'

snip 02-fetch
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --graph main origin/main'

snip 03-evidence
run 'git reflog show origin/main'
run "git log --format='%h %an: %s' origin/main..'origin/main@{1}'"
run "git log --format='%h %an: %s' 'origin/main@{1}'..origin/main"

snip 04-server-has-no-record
note 'The server is a bare repository. It kept no record of the value that was overwritten:'
run 'ls ../server.git'
run 'git -C ../server.git reflog list'
run_rc 'git -C ../server.git config get core.logAllRefUpdates'
note 'A teammate who has not fetched still has the value from her last contact with the server:'
run 'git -C ../asha log --oneline -1 origin/main'

snip 05-repair
run "git merge -m 'Merge origin/main: restore commits removed by a force push' origin/main"
run 'git push'

snip 06-verification
run 'git log --oneline --graph'
run 'git status -sb'
run "git log --oneline 'origin/main@{2}'..origin/main"

snip 07-failure
run 'cd ../incident/askdocs'
run 'git fetch'
run 'git status -sb'
note 'A common reaction: make the local branch match the server.'
run 'git reset --hard origin/main'
run 'git log --oneline'
run 'ls'

snip 08-recovery-read
run 'git reflog show main -2'
run 'git reflog show origin/main -2'
run "git rev-parse 'main@{1}' 'origin/main@{1}'"

snip 09-recovery
run "git branch rescue/before-force-push 'origin/main@{1}'"
run 'git log --oneline rescue/before-force-push'
run "git merge -m 'Merge the commits removed by a force push' rescue/before-force-push"
run 'git push'

snip 10-after
run 'git log --oneline --graph'
run 'git status -sb'
run 'ls'
run 'git branch -d rescue/before-force-push'

lab_end

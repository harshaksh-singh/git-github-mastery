#!/usr/bin/env bash
# Chapter 14D, section 14D.7: the experimental "git replay" as a server-side tool. In a bare
# repository: print the ref update of a cherry-pick without making it, make it, and revert it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d replay
fx_gateway_server
cd server.git || exit 1

snip 01-bare
run 'git rev-parse --is-bare-repository'
run 'git log --oneline --graph --all'

snip 02-print
note 'Put the two commits of fix/timeout on top of main, and only say which ref would move:'
run_rc 'git replay --ref-action=print --advance=main main..fix/timeout'
run 'git log --oneline -1 main'

snip 03-advance
run_rc 'git replay --advance=main main..fix/timeout'
run 'git log --oneline --graph --all'
run "git log -2 --format='%h author: %an, committer: %cn | %s' main"

snip 04-revert
note 'Since Git 2.54 the same machinery reverts:'
run_rc 'git replay --revert=main main~1..main'
run 'git log -1 --format=%B main'
note 'A bare repository keeps no reflog unless it is configured to, so this prints nothing:'
run 'git reflog show main'

lab_end

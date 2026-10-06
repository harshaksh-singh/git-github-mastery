#!/usr/bin/env bash
# Replay of Exercise 7.10 (Level 5, the hotfix that was pushed and is not on the server):
# diagnosis and repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m07-hotfix-not-deployed
exercise_load m07-hotfix-not-deployed

snip 01-server
note 'The server first: it is the only place whose state the release job saw.'
run 'git -C server.git log --oneline release/2.4'
snip 02-ravi
run 'cd ravi'
run 'git status -sb'
run 'git log --graph --oneline release/2.4 origin/release/2.4'

snip 03-reflog
note 'Who moved the remote-tracking branch, and how? Its reflog names the operation.'
run 'git reflog show origin/release/2.4'
note 'Did Asha rewrite anything? Her commit is a child of the commit both of them started from.'
run 'git log --format="%h %an: %s (parent %p)" -2 origin/release/2.4'

snip 04-where
run 'git remote -v'
run 'git config list --local --show-origin | grep remote.origin'
hot=$(git log --format=%h -1 release/2.4)
run "git ls-remote ../old-server.git release/2.4 | cut -c1-7,41-"
run "git ls-remote origin release/2.4 | cut -c1-7,41-"

snip 05-fix-remote
run 'git remote set-url --delete --push origin ../old-server.git'
run 'git remote -v'

snip 06-integrate
note 'The hotfix never reached the server, so it is still private there: replay it on top.'
run 'git rebase origin/release/2.4'
run 'git log --graph --oneline release/2.4'
run 'git push'
run 'git status -sb'

snip 07-verify
run "git ls-remote origin release/2.4 | cut -c1-7,41-"
run 'git -C ../server.git log --oneline release/2.4'
run 'git -C ../server.git show release/2.4:gateway/embed.py'

snip 08-check
run 'cd ..'
show_check
exercise_done

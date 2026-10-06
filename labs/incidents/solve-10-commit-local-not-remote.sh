#!/usr/bin/env bash
# Replay of incident 10 (a commit that exists locally but not in the team repository): the
# three places a commit can be, the remote the push went to, and the repair. Transcripts for
# Chapter 30 and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-10-commit-local-not-remote
incident_load 10-commit-local-not-remote

snip 01-ravi-is-right
run 'cd ravi'
run 'git status -sb'
run 'git log --oneline -2'
run 'git branch -r --contains HEAD'

snip 02-which-server
run 'git remote -v'
run 'git branch -vv'
run 'git reflog show origin/main'
note 'Ask each server directly, without relying on any remote-tracking ref:'
run 'git ls-remote origin main'
run 'git ls-remote upstream main'

snip 03-team-repository
run 'git fetch upstream'
run 'git log --oneline --graph main upstream/main'
run "git log --format='%h %an: %s' main..upstream/main"

snip 04-publish
run 'git switch -c fix/nan-aggregation'
run 'git rebase upstream/main'
run 'git push -u upstream fix/nan-aggregation'
note 'What the pull request into main of the team repository would show:'
run 'git log --oneline upstream/main..upstream/fix/nan-aggregation'
run 'git diff --stat upstream/main...upstream/fix/nan-aggregation'

snip 05-land
note 'The merge of the pull request, simulated as a fast-forward of main on the server:'
run 'git push upstream fix/nan-aggregation:main'

snip 06-repair-clone
run 'git switch main'
run 'git branch --set-upstream-to=upstream/main main'
run 'git status -sb'
note 'Is anything on my main that the team repository lacks? "-" means it has an equivalent.'
run 'git cherry -v upstream/main main'
run 'git reset --keep upstream/main'
run 'git config set remote.pushDefault upstream'
run 'git branch -vv'

snip 07-verify
run 'git ls-remote upstream'
run 'git log --oneline upstream/main'
run 'git branch -d fix/nan-aggregation'
run 'cd ..'
show_check
incident_done

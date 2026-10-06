#!/usr/bin/env bash
# Replay of incident 2 (a force push that landed on main): diagnosis and recovery as real
# transcripts for Chapter 30 and solutions/incident-02-force-push-wrong-branch.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-02-force-push-wrong-branch
incident_load 02-force-push-wrong-branch

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git log --oneline -3'
note 'The status is a statement about the last contact with the server. Ask the server:'
run 'git ls-remote origin'

snip 02-fetch
run 'git fetch'
run 'git status -sb'
run 'git reflog show origin/main'

snip 03-what-changed
note 'What the server lost:'
run "git log --format='%h %an: %s' origin/main..'origin/main@{1}'"
note 'What the server gained:'
run "git log --format='%h %an: %s' 'origin/main@{1}'..origin/main"
note 'Is my copy of the old value the newest one? Compare with Ravi, who has not fetched:'
run 'git -C ../ravi rev-parse --short origin/main'
run_rc "git merge-base --is-ancestor $(git -C ../ravi rev-parse --short origin/main) 'origin/main@{1}'"

snip 04-cause
note 'Why did a push from feature/dedupe move main? Look at the clone that pushed.'
run 'git -C ../asha branch -vv'
run 'git -C ../asha config get --show-origin push.default'
run 'git -C ../asha reflog show origin/main'

snip 05-preserve
run "git branch rescue/main-before-force 'origin/main@{1}'"
note "Asha's two commits exist on the server only as the tip of main. Give them their own branch first:"
run 'git push origin origin/main:refs/heads/feature/dedupe'

snip 06-restore
bad=$(git rev-parse --short origin/main)
run "git push --force-with-lease=main:$bad origin rescue/main-before-force:main"
run 'git status -sb'

snip 07-fix-cause
run 'cd ../asha'
run 'git fetch'
run 'git branch --set-upstream-to=origin/feature/dedupe feature/dedupe'
run 'git config unset push.default'
run 'git status -sb'
run 'git branch -vv'

snip 08-verify
run 'cd ../you'
run 'git ls-remote origin'
run 'git log --oneline --graph origin/main origin/feature/dedupe'
run 'git branch -d rescue/main-before-force'
run 'cd ..'
show_check
incident_done

#!/usr/bin/env bash
# Replay of incident 5 (a shared branch was rebased, then merged back with its old self):
# diagnosis and recovery as real transcripts for Chapter 30 (also the eleven-step scenario of
# section 30.16) and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-05-rebased-shared-branch
incident_load 05-rebased-shared-branch
B=feature/online-serving

snip 01-state
run 'cd you'
run 'git status -sb'
run 'git fetch'
run 'git log --oneline --graph origin/main feature/online-serving'

snip 02-pull-request-view
note 'What a pull request into main lists: the commits, then the changed files.'
run 'git log --oneline origin/main..origin/feature/online-serving'
run 'git diff --stat origin/main...origin/feature/online-serving'

snip 03-refs
run "git for-each-ref --format='%(refname:short) %(objectname:short) %(upstream:track)' refs/heads refs/remotes/origin/main refs/remotes/origin/feature"
run 'git ls-remote origin'

snip 04-reflog
run 'git reflog show feature/online-serving'
run 'git reflog show origin/feature/online-serving'
run 'git config get pull.rebase'

snip 05-old-state
old=$(git rev-parse --short 'feature/online-serving@{3}')
new=$(git rev-parse --short 'origin/feature/online-serving@{1}')
mine=$(git rev-parse --short 'feature/online-serving@{1}')
note 'The shared tip before the rebase, the rebased tip, and my tip before the pull:'
run "git rev-parse 'feature/online-serving@{3}' 'origin/feature/online-serving@{1}' 'feature/online-serving@{1}'"
run 'git show --no-patch --format="%h parents: %p" feature/online-serving'

snip 06-what-changed
note 'Are the two copies the same changes? Compare the old series with the rebased series:'
run "git range-diff origin/main~1..$old origin/main..$new"
run "git log -3 --format='%h  author %ad  committer %cd  %s' --date=format:%H:%M $old"
run "git log -3 --format='%h  author %ad  committer %cd  %s' --date=format:%H:%M $new"

snip 07-preserve
run 'git branch rescue/merged-state feature/online-serving'
run "git branch rescue/my-work $mine"

snip 08-rebuild
note 'Back to my tip from before the pull (a local move), then replay only my two commits'
note 'onto the rebased tip.'
run "git reset --keep $mine"
run "git rebase --onto $new $old"
run 'git log --oneline --graph origin/main~1..feature/online-serving'

snip 09-check-result
run "git range-diff $old..rescue/my-work $new..feature/online-serving"
run 'git diff --stat rescue/merged-state feature/online-serving'

snip 10-publish
bad=$(git rev-parse --short origin/feature/online-serving)
run "git push --force-with-lease=feature/online-serving:$bad origin feature/online-serving"
run 'git log --oneline origin/main..origin/feature/online-serving'
run 'git diff --stat origin/main...origin/feature/online-serving'

snip 11-teammate
run 'cd ../asha'
run 'git fetch'
run 'git status -sb'
run 'git pull --ff-only'

snip 12-prevent
run 'cd ../you'
run 'git config set pull.rebase true'
run 'git branch -D rescue/merged-state rescue/my-work'
run 'cd ..'
show_check
incident_done

#!/usr/bin/env bash
# Replay of incident 6 (a pull request that suddenly shows 500 unrelated changes), simulated
# with plain Git: the commit list and the three-dot diff a pull request would show, the
# hypotheses, and the repair. Transcripts for Chapter 30 and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-06-pr-500-changes
incident_load 06-pr-500-changes
PR=origin/feature/snippet-highlight

snip 01-pull-request-view
run 'cd you'
run 'git fetch'
note 'The commit list of the pull request, and the size of its diff:'
run "git log --format='%h %an: %s' origin/main..$PR"
run "git diff --shortstat origin/main...$PR"
run "git diff --dirstat=files,5 origin/main...$PR"

snip 02-hypotheses
note 'Hypothesis 1: main was rewritten or moved. Its history in my clone:'
run 'git reflog show origin/main'
run "git merge-base origin/main $PR"
run 'git rev-parse origin/main'
note 'Hypothesis 2: the branch was force-pushed. The pushing clone recorded its pushes:'
run 'git -C ../ravi reflog show origin/feature/snippet-highlight'

snip 03-merge
note 'Hypothesis 3: another branch was merged into the head branch.'
run "git log --merges --format='%h %an: %s%n        parents: %p' origin/main..$PR"
run "git log --oneline --graph origin/main..$PR"

snip 04-attribution
m=$(git log --merges --format=%h origin/main..$PR)
note 'What the merge alone brought in, and what the branch looks like without its second parent:'
run "git diff --shortstat $m^1 $m"
run "git log --oneline --first-parent origin/main..$PR"
run "git branch -r --contains $m^2"
run 'git -C ../ravi reflog -4'

snip 05-rebuild
run 'cd ../ravi'
run 'git status -sb'
run 'git branch rescue/with-develop'
run "git rebase --onto $m^1 $m"
run 'git log --oneline --graph main..feature/snippet-highlight'

snip 06-check-result
run "git range-diff $m..rescue/with-develop $m^1..feature/snippet-highlight"
run 'git diff --shortstat main...feature/snippet-highlight'
run_rc 'git merge-base --is-ancestor origin/develop feature/snippet-highlight'

snip 07-publish
run 'git push --force-with-lease --force-if-includes'

snip 08-verify
run 'cd ../you'
run 'git fetch'
run "git log --format='%h %an: %s' origin/main..$PR"
run "git diff --stat origin/main...$PR"
run 'git -C ../ravi branch -D rescue/with-develop'
run 'cd ..'
show_check
incident_done

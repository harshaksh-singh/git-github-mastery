#!/usr/bin/env bash
# Lab 34.1 replay: the evidence-gathering part of the Level 8 design review. The design itself
# is written by the learner; this script only measures the repository the review is about.
# Lab manual: lab-manual/m34-practices-design-review.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 lab-34-1-design-review-evidence
fx_lab_34_1

snip 01-branches
run "git for-each-ref --sort=committerdate --format='%(committerdate:short) %(ahead-behind:main) %(refname:short)' refs/heads"
run 'git branch --no-merged main'

snip 02-releases
run "git for-each-ref --sort=creatordate --format='%(creatordate:short) %(refname:short) %(*objectname:short)' refs/tags"
run 'git log --oneline --graph --decorate --simplify-by-decoration --all'

snip 03-fix-direction
note 'Is there a fix on a release branch that main never received?'
run 'git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.0'
run 'git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.1'

snip 04-integration
run 'git rev-list --count --merges main'
run 'git rev-list --count --no-merges main'
run 'git log --format="%ad %s" --date=short --first-parent main'
run 'git rev-list --count main..develop'
run 'git log -1 --format="%ad" --date=short "$(git merge-base main develop)"'

snip 05-history-content
note 'The largest blobs anywhere in history, and where they were:'
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '\$1 == \"blob\"' | sort -k2 -n -r | head -3"
run 'git log --all --format="%h %ad %s" --date=short --diff-filter=A -- .env models'
run 'git ls-files'

snip 06-people-and-messages
run 'git shortlog -sn --all --no-merges'
run 'git log --all --no-merges --format=%s | awk "length(\$0) < 12" | sort | uniq -c'
run 'git log --format="%G?" main | sort | uniq -c'

snip 07-squash-trap
note 'Failure scenario: you report feature/calibration as unmerged, abandoned work.'
run 'git branch --no-merged main'
run_rc 'git merge-base --is-ancestor feature/calibration main'
run 'git cherry -v main feature/calibration'
run 'git log --oneline -1 --format="%h %ad %s" --date=short main -- score/calibrate.py'

snip 08-content-check
note 'Recovery: the checks above compare commits. Compare content instead.'
run 'git merge-tree --write-tree main feature/calibration'
run 'git rev-parse "main^{tree}"'
note 'Merging the branch would produce exactly the tree main already has: nothing is left to merge.'

snip 09-verify
note 'The same test on every unmerged branch separates finished work from open work:'
run 'for b in $(git branch --no-merged main --format="%(refname:short)"); do if [ "$(git merge-tree --write-tree main "$b")" = "$(git rev-parse "main^{tree}")" ]; then echo "content already on main: $b"; else echo "open work:               $b"; fi; done'
run 'git diff --stat main...feature/big-refactor'
lab_end

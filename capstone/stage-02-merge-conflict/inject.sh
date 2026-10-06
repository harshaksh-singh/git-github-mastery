#!/usr/bin/env bash
# Stage 2: a merge conflict between two feature branches. Applies the incident on top of the
# state that the solution of stage 1 leaves.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 2 "$@"

# Tuesday 15 September. The tech lead merges Kabir's pull request. Yours now conflicts.
cap_as nandini
cap_pr 'merge feature/tenant-weights --squash'

# Kabir "helps": he merges main into your branch in his clone. Where the two branches differ in
# router/scoring.py and tests/test_scoring.py he takes the version of main for the whole file,
# and he pushes the result to your branch.
cap_go kabir
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git branch -D feature/tenant-weights'
quiet 'git fetch --prune'
quiet 'git switch feature/low-confidence-penalty' || cap_fail 'the branch feature/low-confidence-penalty is not on the server'
quiet 'git merge --no-commit origin/main'
quiet 'git checkout origin/main -- router/scoring.py tests/test_scoring.py'
quiet 'git commit --no-edit'
quiet 'git push'
quiet 'git switch main'

cap_inject_end 2

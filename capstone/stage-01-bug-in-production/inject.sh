#!/usr/bin/env bash
# Stage 1: a bug reaches production. Applies the incident on top of the company repository.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 1 "$@"

# Monday 14 September. v1.3.0 has been in production since 09:00. The fault itself is already in
# the history that setup.sh built. What happens this morning: the engineer on call acts on a
# guess and opens a pull request that reverts the newest change of the release.
cap_go tanvi
quiet 'git pull --ff-only'
quiet 'git switch -c fix/revert-embed-weight'
suspect=$(git log -1 --format=%H --grep='(#11)$' main)
quiet "git revert --no-edit $suspect"
quiet 'git push -u origin fix/revert-embed-weight'
cap_pr 'open fix/revert-embed-weight'
quiet 'git switch main'

cap_inject_end 1

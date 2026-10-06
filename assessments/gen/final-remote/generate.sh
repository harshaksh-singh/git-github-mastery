#!/usr/bin/env bash
# Final test, practical lab "remote" (section 8): the project "intentmap".
# Builds origin.git (the team's repository), staging.git (the demo environment deploys from it)
# and the clones you/ and asha/. Your branch was pushed, and your colleague cannot fetch it.
# Read TASK.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final remote
final_begin remote

final_server origin.git
final_server staging.git
final_clone you origin.git
cd you || exit 1
printf 'book_flight: [destination, date]\ncancel_booking: [booking_id]\n' > intents.yaml
_c 'Add the intent map'
printf 'def slots(intent, intents):\n    return intents[intent]\n' > slots.py
_c 'Add slot lookup'
quiet 'git push -u origin main'
# Three weeks ago: a second remote for the demo environment, and a setting to make deploys short.
quiet 'git remote add staging ../staging.git'
quiet 'git push staging main'
quiet 'git config set remote.pushDefault staging'
final_note staging_main "$(git rev-parse HEAD)"
cd "$LAB_DIR" || exit 1
final_clone asha origin.git

# Today: a feature branch, two commits, and "git push".
cd you || exit 1
quiet 'git switch -c feature/slot-carryover'
printf 'def carry_over(previous, current):\n    merged = dict(previous)\n    merged.update(current)\n    return merged\n' > carryover.py
_c 'Carry slots over between turns'
printf 'def carry_over(previous, current):\n    merged = dict(previous)\n    merged.update({k: v for k, v in current.items() if v is not None})\n    return merged\n' > carryover.py
_c 'Do not overwrite a slot with an empty value'
quiet 'git push'
final_note tip "$(git rev-parse HEAD)"
final_note origin_main "$(git -C ../origin.git rev-parse refs/heads/main)"

final_end
final_ready

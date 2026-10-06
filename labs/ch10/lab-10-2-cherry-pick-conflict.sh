#!/usr/bin/env bash
# Lab 10.2 replay: a cherry-pick that conflicts because the picked commit edits a line that differs on
# the maintenance branch. Read the three stages, resolve by hand, continue. The failure scenario takes
# "theirs" wholesale and imports an unrelated change from main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 lab-10-2-cherry-pick-conflict
fx_gateway_conflict

snip 01-start
run 'git log --graph --decorate --all --format="%h %an: %s%d"'
run 'git show --format="%h %s" main~1'

snip 02-conflict
run_rc 'git cherry-pick -x main~1'

snip 03-stages
run 'git status --short'
run 'git show :1:src/client.py | tail -1'
run 'git show :2:src/client.py | tail -1'
run 'git show :3:src/client.py | tail -1'

snip 04-resolve
note 'Edit src/client.py: keep /v1/generate, add retries=MAX_RETRIES, delete the marker lines.'
put src/client.py <<'PYEOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
PYEOF
run 'git add src/client.py'
run 'git cherry-pick --continue'
run 'git show --format="%h %s%n%b" HEAD'

snip 05-failure
run 'git reset --hard HEAD~1'
run_rc 'git cherry-pick -x main~1'
note 'This time the conflict is "resolved" by taking the whole file from the picked commit:'
run 'git restore --theirs src/client.py'
run 'git add src/client.py'
run 'git cherry-pick --continue'

snip 06-diagnose
note 'What the original commit changed, and what the backport changed:'
run 'git show --format= main~1 | grep "^[-+] "'
run 'git show --format= HEAD | grep "^[-+] "'

snip 07-recovery
run 'git reset --hard HEAD~1'
quiet 'git cherry-pick -x main~1'
put src/client.py <<'PYEOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
PYEOF
note 'git cherry-pick -x main~1 again, the file edited by hand as in the first attempt, then:'
run 'git add src/client.py'
run 'git cherry-pick --continue'

snip 08-verification
run 'git show --format= HEAD | grep "^[-+] "'
run 'git grep -n "generate" release/1.4 -- src'
run 'git status --short --branch'
lab_end

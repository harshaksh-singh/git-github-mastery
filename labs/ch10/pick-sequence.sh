#!/usr/bin/env bash
# Chapter 10, sections 10.5 and 10.6: picking a range, the sequencer state in .git/sequencer,
# CHERRY_PICK_HEAD, and the four ways out of a stopped sequence: --abort, --skip, --quit, --continue.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-sequence
fx_gateway_conflict

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-range-stops
run_rc 'git cherry-pick main~3..main'

snip 03-state
run 'git log --oneline --decorate -2'
run 'git rev-parse --short CHERRY_PICK_HEAD'
run 'ls .git/sequencer'
run 'cat .git/sequencer/todo'
run 'cat .git/sequencer/head'

snip 04-status
run 'git status'

snip 05-abort
run 'git cherry-pick --abort'
run 'git log --oneline --decorate -2'
run 'git status --short --branch'

snip 06-skip
quiet 'git cherry-pick main~3..main'
run 'git cherry-pick --skip'
run 'git log --oneline --decorate -3'

snip 07-quit
quiet 'git reset --hard HEAD~2'
quiet 'git cherry-pick main~3..main'
run 'git cherry-pick --quit'
run 'git status --short --branch'
run 'git log --oneline --decorate -2'
run_rc 'git cherry-pick --continue'

snip 08-continue
quiet 'git reset --hard HEAD~1'
quiet 'git cherry-pick main~3..main'
note 'Resolve in an editor: keep the v1 endpoint and add the retries argument. Then:'
put src/client.py <<'PYEOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
PYEOF
run 'git add src/client.py'
run 'git cherry-pick --continue'
run 'git log --oneline --decorate -4'
lab_end

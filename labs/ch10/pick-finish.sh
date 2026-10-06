#!/usr/bin/env bash
# Chapter 10, section 10.7: three ways to finish a cherry-pick after resolving its conflict, and what
# each one records. "git cherry-pick --continue" is the one that keeps the prepared message clean;
# "git commit --no-edit" keeps Git's comment lines; "git commit -m" throws the prepared message away,
# including the line that -x added.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-finish
fx_gateway_conflict

resolve() {
  put src/client.py <<'PYEOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
PYEOF
  git add src/client.py
}

snip 01-prepared-message
quiet 'git cherry-pick -x main~1'
note 'git cherry-pick -x main~1 has stopped with a conflict. Git has already prepared the message:'
run 'cat .git/MERGE_MSG'
run 'git rev-parse --short CHERRY_PICK_HEAD'

snip 02-continue
resolve
note 'The conflict is resolved and staged. First way: --continue.'
run 'git cherry-pick --continue'
run 'git log -1 --format="author %an, committer %cn%n%n%B"'

snip 03-commit-no-edit
quiet 'git reset --hard HEAD~1'
quiet 'git cherry-pick -x main~1'
resolve
note 'The same stop, resolved the same way. Second way: git commit --no-edit.'
run 'git commit --no-edit'
run 'git log -1 --format="author %an, committer %cn%n%n%B"'

snip 04-commit-m
quiet 'git reset --hard HEAD~1'
quiet 'git cherry-pick -x main~1'
resolve
note 'Third way: git commit with a message of your own.'
run 'git commit -m "Retry failed generate calls (1.4)"'
run 'git log -1 --format="author %an, committer %cn%n%n%B"'
run_rc 'git rev-parse --verify --quiet CHERRY_PICK_HEAD'
lab_end

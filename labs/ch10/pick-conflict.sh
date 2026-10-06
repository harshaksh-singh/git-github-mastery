#!/usr/bin/env bash
# Chapter 10, section 10.7: a conflict in a cherry-pick. Stage 1 is the parent of the picked commit,
# a version that never existed on the branch you are on. Shown with the diff3 conflict style, which
# labels the base.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-conflict
fx_gateway_conflict
git config set merge.conflictStyle diff3

snip 01-conflict
run 'git config get merge.conflictStyle'
run_rc 'git cherry-pick -x main~1'

snip 02-markers
run 'cat src/client.py'

snip 03-stages
run 'git ls-files -u'
run 'git show :1:src/client.py | tail -1'
run 'git show :2:src/client.py | tail -1'
run 'git show :3:src/client.py | tail -1'

snip 04-where-stage-1-comes-from
note 'The merge base of the two branches has the v1 line ...'
run 'git show $(git merge-base HEAD main~1):src/client.py | tail -1'
note '... but stage 1 is the parent of the picked commit, which already has v2.'
run 'git show main~2:src/client.py | tail -1'

snip 05-resolve
note 'Resolve in an editor: the release keeps the v1 endpoint and gains the retries argument.'
put src/client.py <<'PYEOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
PYEOF
run 'git add src/client.py'
run 'git cherry-pick --continue'

snip 06-result
run 'git log -1 --format=fuller'
run 'git show --format= HEAD'
lab_end

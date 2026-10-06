#!/usr/bin/env bash
# Chapter 27, sections 27.14 to 27.16: three practices shown with their reasons.
# Inspect a branch before merging it; small commits make a revert precise where a giant
# commit does not; commit-message conventions are data that Git can query.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 practices
fx_base
hidden 'git switch -c feature/fallback main'
fallback_v1
commit_all 'feat(router): add fallback table'
put gateway/router.py <<'PY'
from gateway.fallback import fallback

MODELS = {"chat": "sonnet-large", "embed": "embed-small"}


def route(request, healthy=True):
    model = MODELS[request["task"]]
    return model if healthy else fallback(model)
PY
commit_all 'feat(router): fall back when the primary model is unhealthy'
put gateway/limits.py <<'PY'
LIMITS = {"default": 600}


def allowed(tenant, used):
    return used < LIMITS.get(tenant, LIMITS["default"])
PY
commit_all 'chore: raise default limit for load test'
hidden 'git switch main'
printf '# promptgate\n\nGateway between product teams and LLM providers.\n\nRun the tests with `python3 -m unittest`.\n' > README.md
commit_all 'docs: say how to run the tests'

snip 01-inspect
note 'Before merging feature/fallback: which commits would arrive, and what do they change?'
run 'git log --oneline main..feature/fallback'
run 'git diff --stat main...feature/fallback'
note 'Would it merge cleanly? Ask without touching the working tree, the index or any ref:'
run_rc 'git merge-tree --write-tree --name-only main feature/fallback'

snip 02-merge
run 'git merge --no-ff -m "Merge pull request #51 from feature/fallback" feature/fallback'
run 'git log --oneline --graph -6'

bad=$(git rev-parse --short 'HEAD^2')
snip 03-revert-one
note 'The load-test limit reached production. Because it is a commit of its own, it can be'
note 'undone alone, and the fallback feature stays:'
run "git revert --no-edit $bad"
run 'git show --stat --format="%h %s" HEAD'
run 'grep default gateway/limits.py'

hidden 'git reset --hard HEAD^'
snip 04-revert-squashed
note 'The same branch as one squashed commit (rebuilt here from the same content):'
hidden 'git reset --hard HEAD^'
hidden 'git merge --squash feature/fallback'
hidden 'git commit -m "Add model fallback (#51)"'
run 'git show --stat --format="%h %s" HEAD'
note 'Reverting it removes the feature together with the mistake:'
run 'git revert --no-edit HEAD'
run 'git show --stat --format="%h %s" HEAD'

snip 05-messages-as-data
run 'git log --format="%h %s" v1.3.0..HEAD'
note 'With a convention, the history answers questions:'
run 'git log --oneline --grep="^feat" v1.3.0..feature/fallback'
run 'git log --format="%s" v1.3.0..feature/fallback | sed "s/[(:].*//" | sort | uniq -c'
run 'git shortlog -sn v1.3.0..feature/fallback'
lab_end

#!/usr/bin/env bash
# The same conflict presented in the merge, diff3 and zdiff3 styles. Chapter 8, section 8.9.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-styles

quiet 'ek_base'
quiet 'git switch -c feature/case-insensitive'
as asha
cat > evalkit/metrics.py <<'PY'
def exact_match(pred, gold):
    if pred is None:
        return 0.0
    return float(pred.lower() == gold.lower())


def accuracy(scores):
    return sum(scores) / len(scores)
PY
quiet 'ek_commit "Guard against missing predictions and ignore case"'
as you
quiet 'git switch main'
cat > evalkit/metrics.py <<'PY'
def exact_match(pred, gold):
    if pred is None:
        return 0.0
    return float(pred.strip() == gold.strip())


def accuracy(scores):
    return sum(scores) / len(scores)
PY
quiet 'ek_commit "Guard against missing predictions and strip whitespace"'

snip 01-merge-style
note 'The function as both branches found it (the merge base):'
run 'git show main~1:evalkit/metrics.py | head -2'
run_rc 'git merge feature/case-insensitive'
run 'head -9 evalkit/metrics.py'

snip 02-diff3
run 'git checkout --conflict=diff3 evalkit/metrics.py'
run 'head -13 evalkit/metrics.py'

snip 03-zdiff3
run 'git restore --conflict=zdiff3 evalkit/metrics.py'
run 'head -11 evalkit/metrics.py'

snip 04-config
run 'git merge --abort'
run 'git config set merge.conflictStyle zdiff3'
run 'git config get --show-origin merge.conflictStyle'
run_rc 'git merge feature/case-insensitive'
run 'head -11 evalkit/metrics.py'
quiet 'git merge --abort'

lab_end

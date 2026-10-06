#!/usr/bin/env bash
# Lab 9.3 replay: answer review comments with fixup commits and fold them in with --autosquash.
# The failure scenario is a fixup that conflicts because a later commit changed the neighbouring lines.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-3-autosquash-fixups
fx_metrics_clean

snip 01-start
run 'git log --oneline --decorate'

snip 02-first-fixup
note 'Edit eval/metrics.py: compare pred.strip() with gold.strip().'
put eval/metrics.py <<'PYEOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
PYEOF
run 'git commit -a --fixup=HEAD~2'

snip 03-second-fixup
note 'Edit eval/f1.py: lower-case both strings before splitting.'
put eval/f1.py <<'PYEOF'
def f1(pred, gold):
    p, g = set(pred.lower().split()), set(gold.lower().split())
    overlap = len(p & g)
    return 2 * overlap / (len(p) + len(g)) if overlap else 0.0
PYEOF
run 'git commit -a --fixup=HEAD~1'
run 'git log --oneline --decorate'

snip 04-autosquash
run_todo '' 'git rebase -i --autosquash main'

snip 05-result
run 'git log --oneline --decorate'
run 'git diff --stat ORIG_HEAD HEAD'
run 'git show --stat --format="%h %s" HEAD~2'

snip 06-failure
note 'Edit tests/test_metrics.py: the exact_match test should use " Paris " with spaces.'
put tests/test_metrics.py <<'PYEOF'
from eval.metrics import exact_match
from eval.f1 import f1

def test_exact_match():
    assert exact_match(" Paris ", "Paris")

def test_f1_identical():
    assert f1("the cat", "the cat") == 1.0
PYEOF
run 'git commit -a --fixup=HEAD~1'
run_rc 'git rebase --autosquash main'

snip 07-diagnose
run 'git status --short'
run 'git diff'

snip 08-recovery
run 'git rebase --abort'
run 'git status --short --branch'
run 'git log --oneline --decorate -2'
note 'Keep the change as a commit of its own instead of forcing it into the older commit.'
run 'git commit --amend -m "Test exact_match with surrounding whitespace"'

snip 09-verification
run 'git log --oneline --decorate'
run "git log --oneline --grep='^fixup!' main..HEAD"
run 'git status --short --branch'
lab_end

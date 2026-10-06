#!/usr/bin/env bash
# Chapter 9, section 9.7: fixup!, squash! and amend! commits created with "git commit --fixup/--squash",
# and how --autosquash turns them into todo commands.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 autosquash
fx_metrics_clean

snip 01-before
run 'git log --oneline --decorate'

snip 02-fixup-commit
note 'Review comment 1: exact_match must ignore surrounding whitespace. That belongs in the first commit.'
put eval/metrics.py <<'PYEOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
PYEOF
run 'git diff'
run 'git commit -a --fixup=HEAD~2'

snip 03-squash-commit
note 'Review comment 2: cover disjoint answers in the F1 test. That belongs in the last commit, with a note.'
printf '\ndef test_f1_disjoint():\n    assert f1("the cat", "a dog") == 0.0\n' >> tests/test_metrics.py
run 'git commit -a --squash=HEAD~1 -m "Also covers the zero-overlap case."'

snip 04-amend-commit
note 'Review comment 3: the message of "Test exact_match" should say what is tested. Only the message changes.'
run_msg 'amend! Test exact_match

Test exact_match on identical strings' 'git commit --fixup=reword:HEAD~3'

snip 05-log
run 'git log --oneline --decorate'

snip 06-autosquash
LAB_MSG='Add token-level F1 metric

Tested on identical and on disjoint answers.' run_todo '' 'git rebase -i --autosquash main'

snip 07-after
run 'git log --oneline --decorate'
run 'git log -1 --format=%B'
run 'git diff --stat ORIG_HEAD HEAD'

snip 08-non-interactive
note 'One more fix, this time without opening the todo list at all.'
put eval/f1.py <<'PYEOF'
def f1(pred, gold):
    p, g = set(pred.lower().split()), set(gold.lower().split())
    overlap = len(p & g)
    return 2 * overlap / (len(p) + len(g)) if overlap else 0.0
PYEOF
run 'git commit -a --fixup=HEAD'
run 'git rebase --autosquash main'
run 'git log --oneline --decorate'

snip 09-config
run 'git config set rebase.autoSquash true'
run 'git config get rebase.autoSquash'
lab_end

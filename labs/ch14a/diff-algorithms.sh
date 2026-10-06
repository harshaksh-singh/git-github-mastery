#!/usr/bin/env bash
# Chapter 14A, section 14A.6: the same two snapshots, two diff algorithms, two different patches.
# Two similar functions change places in one file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a diff-algorithms
fx_scorekit || exit 1

cat > scorekit/overlap.py <<'PY'
def token_precision(pred, ref):
    overlap = len(set(pred) & set(ref))
    if not pred:
        return 0.0
    return overlap / len(pred)


def token_recall(pred, ref):
    overlap = len(set(pred) & set(ref))
    if not ref:
        return 0.0
    return overlap / len(ref)
PY
quiet 'git add scorekit/overlap.py && git commit -m "Add token precision and recall helpers"'
cat > scorekit/overlap.py <<'PY'
def token_recall(pred, ref):
    overlap = len(set(pred) & set(ref))
    if not ref:
        return 0.0
    return overlap / len(ref)


def token_precision(pred, ref):
    overlap = len(set(pred) & set(ref))
    if not pred:
        return 0.0
    return overlap / len(pred)
PY

snip 01-myers
note 'The two functions of scorekit/overlap.py were swapped. Nothing else changed.'
run 'git diff --diff-algorithm=myers'

snip 02-histogram
run 'git diff --diff-algorithm=histogram'

snip 03-counts
run 'git diff --shortstat --diff-algorithm=myers'
run 'git diff --shortstat --diff-algorithm=histogram'
run 'git diff --shortstat --patience'

snip 04-config
run 'git config set diff.algorithm histogram'
run 'git diff --shortstat'
lab_end

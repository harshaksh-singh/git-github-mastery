#!/usr/bin/env bash
# Chapter 9, section 9.5: --keep-base tidies a branch in place. The commits are rewritten on top of the
# merge base they already have, so cleaning up is not mixed with catching up to main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 keep-base
fx_metrics_clean
put eval/metrics.py <<'PYEOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
PYEOF
tick; git commit -q -a --fixup=HEAD~2
git switch -q main
put README.md <<'MDEOF'
# ragkit

Retrieval-augmented answering service.
MDEOF
commit_all "Add README"
git switch -q feat/metrics

snip 01-before
run 'git log --oneline --graph --decorate --all'
run 'git merge-base main feat/metrics'

snip 02-keep-base
run 'git rebase --autosquash --keep-base main'

snip 03-after
run 'git log --oneline --graph --decorate --all'
run 'git merge-base main feat/metrics'
lab_end

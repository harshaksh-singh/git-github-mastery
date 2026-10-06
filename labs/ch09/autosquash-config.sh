#!/usr/bin/env bash
# Chapter 9, section 9.7: rebase.autoSquash=true turns on --autosquash for interactive rebases only.
# A plain "git rebase main" leaves the fixup! commit where it is; -i, or an explicit --autosquash,
# folds it in.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 autosquash-config
fx_metrics_clean
put eval/metrics.py <<'PYEOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
PYEOF
tick; git commit -q -a --fixup=HEAD~2

snip 01-config-and-plain-rebase
run 'git config set rebase.autoSquash true'
run 'git log --oneline --decorate'
run 'git rebase main'
run 'git log --oneline --decorate -1'

snip 02-interactive-honours-it
run_todo '' 'git rebase -i main'
run 'git log --oneline --decorate'
lab_end

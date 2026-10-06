#!/usr/bin/env bash
# Renames in a merge: rename against edit (clean), rename against rename, rename against delete,
# and a rename that falls below the similarity threshold. Chapter 8, section 8.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-rename

# ---- rename against edit
quiet 'ek_base rename-edit'
quiet 'git switch -c refactor/scoring-module'
as ravi
quiet 'git mv evalkit/metrics.py evalkit/scoring.py && ek_commit "Rename the metrics module to scoring"'
as you
quiet 'git switch main'
quiet "sed -e 's/pred == gold/pred.strip() == gold.strip()/' evalkit/metrics.py > m && mv m evalkit/metrics.py"
quiet 'ek_commit "Strip whitespace before comparing"'

snip 01-rename-edit
run 'git log --oneline --graph --all'
run 'git merge refactor/scoring-module'
run 'git ls-files evalkit'
run 'head -2 evalkit/scoring.py'

# ---- rename against rename
quiet 'cd "$LAB_DIR" && ek_base rename-rename'
quiet 'git switch -c refactor/scorers'
as ravi
quiet 'git mv evalkit/metrics.py evalkit/scorers.py && ek_commit "Rename the metrics module to scorers"'
as you
quiet 'git switch main'
quiet 'git mv evalkit/metrics.py evalkit/scoring.py && ek_commit "Rename the metrics module to scoring"'

snip 02-rename-rename
run_rc 'git merge refactor/scorers'
run 'git status --short'
run 'git ls-files -u'
run 'ls evalkit'

snip 03-rename-rename-resolve
note 'Decision: the module is called scoring. All three paths need an answer.'
run 'git add evalkit/scoring.py'
run 'git rm evalkit/scorers.py'
run 'git rm evalkit/metrics.py'
run 'git status --short'
run 'git merge --continue'
run 'git ls-files evalkit'

# ---- rename against delete
quiet 'cd "$LAB_DIR" && ek_base rename-delete'
quiet 'git switch -c cleanup/drop-metrics'
as ravi
quiet 'git rm -q evalkit/metrics.py && ek_commit "Remove the metrics module"'
as you
quiet 'git switch main'
quiet 'git mv evalkit/metrics.py evalkit/scoring.py && ek_commit "Rename the metrics module to scoring"'

snip 04-rename-delete
run_rc 'git merge cleanup/drop-metrics'
run 'git status --short'
run 'git ls-files -u'
quiet 'git merge --abort'

# ---- a rename that Git does not recognise
quiet 'cd "$LAB_DIR" && ek_base rename-rewrite'
quiet 'ek_metrics_with_f1 && ek_commit "Add token F1"'
quiet 'git switch -c refactor/score-objects'
as ravi
quiet 'git mv evalkit/metrics.py evalkit/scoring.py && ek_scoring_rewrite && ek_commit "Move metrics to scoring and return Score objects"'
as you
quiet 'git switch main'
quiet "sed -e 's/pred == gold/pred.strip() == gold.strip()/' evalkit/metrics.py > m && mv m evalkit/metrics.py"
quiet 'ek_commit "Strip whitespace before comparing"'

snip 05-below-threshold
run 'git diff --summary main...refactor/score-objects'
run 'git diff --summary --find-renames=30% main...refactor/score-objects'
run_rc 'git merge refactor/score-objects'
run 'git status --short'

snip 06-find-renames
run 'git merge --abort'
run_rc 'git merge -X find-renames=30% refactor/score-objects'
run 'git status --short'
run "grep -n -B1 -A5 '<<<<<<<' evalkit/scoring.py"
quiet 'git merge --abort'

lab_end

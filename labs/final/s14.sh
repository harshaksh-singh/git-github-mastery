#!/usr/bin/env bash
# Final test, section 14 (AI/ML workflows): prediction item P1 (a clean filter that strips
# outputs) and interpretation item I1 (a run from a dirty working tree).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s14

# ---- P1: a clean filter, and the clone that does not have it
snip p1-setup
run 'git init -q churn-analysis'
run 'cd churn-analysis'
note 'A toy notebook format: lines that start with IN: are code, lines that start with OUT: are outputs.'
run "git config set filter.dropout.clean \"sed '/^OUT:/d'\""
run "printf '*.nb filter=dropout\n' > .gitattributes"
run "printf 'IN: df.describe()\nOUT: count 100\nIN: plot(df)\nOUT: <figure 1>\n' > analysis.nb"
run 'git add . && git commit -q -m "Add the churn analysis"'
note 'The notebook is run again. Only the outputs change.'
run "printf 'IN: df.describe()\nOUT: count 250\nIN: plot(df)\nOUT: <figure 7>\n' > analysis.nb"
run 'git clone -q . ../churn-clone'
snip p1-answer
run 'git show HEAD:analysis.nb'
run 'git status --short'
run 'cat ../churn-clone/analysis.nb'
run_rc 'git -C ../churn-clone config get filter.dropout.clean'
run 'git -C ../churn-clone check-attr filter analysis.nb'
note 'A colleague runs the notebook in the clone and stages it:'
run "printf 'IN: df.describe()\nOUT: count 250\nIN: plot(df)\nOUT: <figure 7>\n' > ../churn-clone/analysis.nb"
run 'git -C ../churn-clone add analysis.nb && git -C ../churn-clone diff --cached'
cd "$LAB_DIR"

# ---- I1: the commit ID of a run that was started from a dirty tree
quiet 'git init -q adapter-train'
cd adapter-train || exit 1
printf 'LR = 1e-4\nEPOCHS = 3\n\ndef train(data):\n    return fit(data, LR, EPOCHS)\n' > train.py
printf 'runs/\n' > .gitignore
quiet 'git add . && git commit -q -m "Add the adapter training script"'
quiet 'git tag -a v0.3.0 -m "Baseline"'
printf 'LR = 3e-4\nEPOCHS = 3\n\ndef train(data):\n    return fit(data, LR, EPOCHS)\n' > train.py
mkdir runs
printf '{"commit": "%s", "eval_f1": 0.871}\n' "$(git rev-parse --short HEAD)" > runs/run-0042.json
snip i1-transcript
run 'cat runs/run-0042.json'
run 'git rev-parse --short HEAD'
run 'git status --short'
run 'git describe --dirty'
run 'git diff'
lab_end

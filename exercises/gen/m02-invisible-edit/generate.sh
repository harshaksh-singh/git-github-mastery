#!/usr/bin/env bash
# Exercise 2.9 (Level 4): "Git does not see my edits".
# Builds the repository annotator/. Read SYMPTOMS.md, not this file, before you start: the script
# is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m02-invisible-edit
ex_begin m02-invisible-edit

quiet 'git init annotator'
cd annotator || exit 1
quiet 'git config set user.name "Asha Rao" && git config set user.email asha@example.com'
as asha
mkdir -p annotator configs
printf 'def agreement(votes):\n    top = max(set(votes), key=votes.count)\n    return votes.count(top) / len(votes)\n' > annotator/agreement.py
printf 'agreement_threshold: 0.8\nmin_annotators: 2\n' > configs/eval.yaml
printf 'cache_dir: /tmp/annotator-cache\n' > configs/local.yaml
_c 'Add inter-annotator agreement'
printf '# annotator\n\nScores how often annotators agree on a label.\n' > README.md
_c 'Add README'

# Months ago, following a blog post: "make Git ignore my local tweaks".
quiet 'git update-index --skip-worktree configs/eval.yaml configs/local.yaml'
quiet 'git update-index --assume-unchanged annotator/agreement.py'

# This week's real work, which Git now does not report. (The new eval.yaml has another size than
# the committed one on purpose: an edit of the same size made in the same second as the commit
# could stay invisible even after the bit is cleared, and the exercise must be reproducible.)
printf 'agreement_threshold: 0.90\nmin_annotators: 2\n' > configs/eval.yaml
printf 'def agreement(votes):\n    if not votes:\n        return 0.0\n    top = max(set(votes), key=votes.count)\n    return votes.count(top) / len(votes)\n' > annotator/agreement.py
printf 'cache_dir: /Users/asha/.cache/annotator\n' > configs/local.yaml

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"

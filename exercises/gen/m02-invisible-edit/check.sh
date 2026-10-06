#!/usr/bin/env bash
# Read-only verification of Exercise 2.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m02-invisible-edit "${1:-}"
R=annotator
expect 'the committed configs/eval.yaml has the threshold 0.90' sh -c "git -C $R show HEAD:configs/eval.yaml | grep -q 'agreement_threshold: 0.90'"
expect 'the committed agreement.py guards the empty vote list' sh -c "git -C $R show HEAD:annotator/agreement.py | grep -q 'if not votes'"
expect 'the committed configs/local.yaml still has the shared default' sh -c "git -C $R show HEAD:configs/local.yaml | grep -q '/tmp/annotator-cache'"
expect 'the laptop path is still in the working copy of configs/local.yaml' grep -q '/Users/asha/.cache/annotator' $R/configs/local.yaml
flags=$(git -C $R ls-files -v -- annotator configs/eval.yaml README.md | grep -v '^H ' | tr '\n' ' ')
if [ -z "$flags" ]; then ok 'no assume-unchanged or skip-worktree bit is left on the shared files'; else bad "bits still set: $flags"; fi
expect_eq 'the working copy of eval.yaml equals the committed one' "$(git -C $R hash-object configs/eval.yaml)" "$(git -C $R rev-parse -q --verify HEAD:configs/eval.yaml)"
expect_eq 'the working copy of agreement.py equals the committed one' "$(git -C $R hash-object annotator/agreement.py)" "$(git -C $R rev-parse -q --verify HEAD:annotator/agreement.py)"
expect 'the two original commits are still the base of the history' git -C $R merge-base --is-ancestor "$(git -C $R rev-list --max-parents=0 HEAD | tail -1)" HEAD
check_end

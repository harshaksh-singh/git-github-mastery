#!/usr/bin/env bash
# Chapter 14D, section 14D.6: the experimental "git history" on Git 2.55: reword, fixup and
# split, what they do to descendant branches, and where they stop (merges, conflicts, hooks).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d history
fx_history_repo
cd evalkit || exit 1

snip 01-help
run_rc 'git history -h'

snip 02-reword
run 'git log --oneline --graph --all'
run_msg 'Add exact-match metric' 'git history reword HEAD~3'
run 'git log --oneline --graph --all'

snip 03-reflogs
run 'git reflog -1'
run 'git reflog show -1 release/0.1'
run 'git reflog show -1 topic/judge'
run 'git status -sb'

snip 04-dry-run
note 'A dry run writes the new objects and prints the ref updates instead of making them:'
run_msg 'Add F1 metric and its test' 'git history reword --dry-run HEAD~2'
run 'git log --oneline -3'

snip 05-fixup
note 'A staged change is folded into an older commit, and its descendants are replayed:'
run "printf 'from metrics import f1\n\n\ndef test_f1():\n    assert f1(1, 0, 0) == 1.0\n    assert f1(0, 1, 1) == 0.0\n' > test_metrics.py"
run 'git add test_metrics.py'
run_rc 'git history fixup HEAD~2'
run 'git status -s'
run "git log --oneline --stat --format='%h %s' -3"

snip 06-split
printf 'Add F1 metric\n----\nTest the F1 metric\n' > "$LAB_DIR/messages"
note 'Answers typed at the two prompts: y (move this hunk into the new, earlier commit), then n.'
LAB_MSG_QUEUE="$LAB_DIR/messages" run_msg '' "printf 'y\nn\n' | git history split HEAD~2"

snip 07-after-split
run "git log --stat --format='%h %s' -4"

snip 08-no-hooks
note 'A commit-msg hook that refuses every message does not stop it: git history runs no hooks.'
run "printf '#!/bin/sh\necho \"commit-msg: refused\" >&2\nexit 1\n' > .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg"
run_rc 'git commit --allow-empty -m "probe"'
run_msg 'Add dev requirements' 'git history reword HEAD'
run 'git log --oneline -1'
quiet 'rm .git/hooks/commit-msg'

snip 09-limits
note 'A fixup that would conflict is refused, and nothing changes:'
run "printf 'def exact(pred, gold):\n    return pred.strip() == gold.strip()\n\n\ndef f1(tp, fp, fn):\n    return 2 * tp / (2 * tp + fp + fn)\n' > metrics.py && git add metrics.py"
run_rc 'git history fixup HEAD~4'
run 'git status -s'
quiet 'git restore --staged --worktree metrics.py'
note 'History with a merge commit above the target is refused as well:'
quiet 'git merge --no-ff -m "Merge topic/judge" topic/judge'
run 'git log --oneline --graph -4'
run_rc 'git history reword HEAD~2'

lab_end

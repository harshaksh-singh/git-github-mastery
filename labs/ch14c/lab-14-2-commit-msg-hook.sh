#!/usr/bin/env bash
# Lab 14.2 replay: install a commit-msg hook that enforces a subject format, watch it refuse and
# accept, test it without committing through "git hook run", and bypass it. Failure: the hook
# also refuses the messages that Git writes itself, so a merge stops half-way and a fixup commit
# cannot be made. Recovery: install the corrected hook and conclude the merge.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c lab-14-2-commit-msg-hook
fx_14_2

snip 01-install
run 'cd evalkit'
run 'git log --oneline --graph --all'
run 'cat ../hooks/commit-msg'
run 'cp ../hooks/commit-msg .git/hooks/commit-msg'
run 'chmod +x .git/hooks/commit-msg'

snip 02-refuse-and-accept
run "printf 'def exact(pred, gold):\n    return pred.strip() == gold.strip()\n' > metrics.py"
run_rc 'git commit -am "updated scorer"'
run 'git status -s'
run 'git log --oneline -1'
run_rc 'git commit -am "fix(metrics): ignore surrounding whitespace"'

snip 03-length
run_rc 'git commit --allow-empty -m "chore: rerun the full evaluation suite after the whitespace fix landed on main"'

snip 04-test-without-committing
run "printf 'wip\n' > ../msg.txt"
run_rc 'git hook run commit-msg -- ../msg.txt'
run "printf 'test(metrics): cover empty input\n\nThe scorer crashed on an empty prediction.\n' > ../msg.txt"
run_rc 'git hook run commit-msg -- ../msg.txt'

snip 05-bypass
run 'git commit --allow-empty --no-verify -m "wip"'
run 'chmod -x .git/hooks/commit-msg'
run 'git commit --allow-empty -m "another wip"'
run 'chmod +x .git/hooks/commit-msg'
run 'git log --oneline -3'

snip 06-who-runs-it
note 'git revert writes its own subject. On Git 2.55 it does not run the commit-msg hook:'
run 'git revert --no-edit HEAD~2'
run 'git log --oneline -1'

snip 07-failure
run_rc 'git commit --allow-empty --fixup=HEAD~1'
run_rc 'git merge feat/f1'
run 'git status'
run 'git log --oneline -1'

snip 08-recovery
run 'diff ../hooks/commit-msg ../hooks/commit-msg.v2'
run 'cp ../hooks/commit-msg.v2 .git/hooks/commit-msg'
run 'git commit --no-edit'

snip 09-verification
run 'git log --oneline --graph -4'
run "printf 'fixup! feat(metrics): add F1\n' > ../msg.txt"
run_rc 'git hook run commit-msg -- ../msg.txt'
run "printf 'quick fix\n' > ../msg.txt"
run_rc 'git hook run commit-msg -- ../msg.txt'

lab_end

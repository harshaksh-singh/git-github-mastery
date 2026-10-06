#!/usr/bin/env bash
# Replay of Exercise 9.10 (Level 5, "rebased onto main, no functional change"): diagnosis and
# repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m09-vanished-guard
exercise_load m09-vanished-guard

snip 01-now
run 'cd you'
run 'git log --oneline origin/main..origin/feat/abuse-filter'
run 'git show origin/feat/abuse-filter:api/moderate.py'

snip 02-old-tip
note 'Your clone had the branch before the forced push and fetched it after. One reflog line, two IDs.'
run 'git reflog show origin/feat/abuse-filter'
run "awk '{print \"old \" substr(\$1,1,7) \"  new \" substr(\$2,1,7)}' .git/logs/refs/remotes/origin/feat/abuse-filter"
run "git log --oneline 'origin/feat/abuse-filter@{1}' -5"

snip 03-range-diff
run "git range-diff origin/main 'origin/feat/abuse-filter@{1}' origin/feat/abuse-filter"

snip 04-other-clones
note "Asha has not fetched: her remote-tracking branch is still the old tip."
run 'git -C ../asha log --oneline -1 origin/feat/abuse-filter'
note "Ravi's own reflog: the rebase picked three commits. No pick of the empty-message commit follows."
run 'git -C ../ravi reflog -8'

snip 05-not-main
note 'Did the commit on main remove the check? It never had it.'
run 'git log --oneline -S"message.strip()" --all'
run 'git show --format="%h %an: %s" origin/main -- api/moderate.py'

snip 06-pick
lost=$(git log --format=%h -1 --grep='Reject empty messages' 'origin/feat/abuse-filter@{1}')
run 'git switch feat/abuse-filter'
run_rc "git cherry-pick -x $lost"
run 'git diff'

snip 07-resolve
run "printf 'from filters import abuse\n\ndef moderate(message):\n    if len(message) > 10000:\n        return {\"allowed\": False, \"reason\": \"too long\"}\n    if not message.strip():\n        return {\"allowed\": False, \"reason\": \"empty\"}\n    score = abuse.score(message)\n    return {\"allowed\": score < 0.8}\n' > api/moderate.py"
run 'git add api/moderate.py'
run 'git cherry-pick --continue'
run 'git log --oneline origin/main..HEAD'

snip 08-publish
run 'git push'
run "git range-diff origin/main 'origin/feat/abuse-filter@{2}' origin/feat/abuse-filter"

snip 09-check
run 'cd ..'
show_check
exercise_done

#!/usr/bin/env bash
# Replay of incident 9 (a merge conflict resolved with "ours" for the whole file): why the usual
# commands do not see the loss, how the merge is audited, and the forward fix. Transcripts for
# Chapter 30 and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-09-misunderstood-conflict
incident_load 09-misunderstood-conflict

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'cat limiter/bucket.py'

snip 02-commits-are-there
run "git log --format='%h %an: %s' --author=Asha main"
cap=$(git log --format=%h --grep='Cap the bucket' main)
half=$(git log --format=%h --grep='Halve the default' main)
run_rc "git merge-base --is-ancestor $half main"
run_rc "git log --oneline --grep='^Revert' main"

snip 03-log-hides-them
note 'The command Asha ran, and the same command without history simplification:'
run 'git log --oneline -- limiter/bucket.py'
run 'git log --oneline --full-history -- limiter/bucket.py'

snip 04-graph
run 'git log --oneline --graph'

snip 05-audit
m=$(git log --merges --format=%h --grep='remote-tracking' main)
note 'What did the person who made this merge change, compared with what Git would have produced?'
run "git show --remerge-diff --format='%h %an: %s' $m"

snip 06-confirm
note 'The file in the merge result, compared with each parent:'
run "git diff --stat $m^1 $m -- limiter/bucket.py"
run "git diff --stat $m^2 $m -- limiter/bucket.py"
run "git -C ../ravi reflog -4 --format='%h %gs'"

snip 07-fix
run 'git switch -c fix/restore-overload-fix'
note '(edit limiter/bucket.py: DEFAULT_RATE = 50, and the min(BURST, ...) cap in refill)'
quiet "sed -i.bak -e 's/^DEFAULT_RATE = 100\$/DEFAULT_RATE = 50/' -e 's/bucket.tokens = bucket.tokens + (now - bucket.ts) \\* rate/bucket.tokens = min(BURST, bucket.tokens + (now - bucket.ts) * rate)/' limiter/bucket.py && rm limiter/bucket.py.bak"
run 'git diff'
run "git commit -a -m 'Restore the burst cap and the lowered default rate' -m 'Merge $m resolved a conflict in limiter/bucket.py by keeping one side of the whole file, which discarded $cap and $half.'"

snip 08-verify
note "Against Asha's version the file must differ only by Ravi's rename and lookup:"
run "git diff $half fix/restore-overload-fix -- limiter/bucket.py"

snip 09-land
run 'git push -u origin fix/restore-overload-fix'
note 'After review (a pull request on GitHub):'
run 'git switch main'
run 'git merge --ff-only fix/restore-overload-fix'
run 'git push'
run 'git log --oneline -3'
run 'cd ..'
show_check
incident_done

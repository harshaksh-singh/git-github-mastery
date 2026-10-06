#!/usr/bin/env bash
# Gate 4, hands-on variant B (latency-probe): the model diagnosis and recovery as real
# transcripts for answer-keys/gate-4-recovery.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g4-b
gate_load gate-4-recovery/variant-b
as config

snip 01-observe
run 'cd asha'
run 'git status -sb'
run 'sh tools/p95.sh'
run 'git log --oneline v1.0.0..main'

snip 02-test-the-claim
run 'git log --oneline -- probe/config.py'
run 'git log --oneline --follow -- probe/config.py'
run "git log --oneline -G'TIMEOUT_MS' v1.0.0..main"
run "git grep -n 'TIMEOUT_MS' v1.0.0 main -- probe"

snip 03-bisect
run 'git bisect start main v1.0.0'
run "git bisect run sh -c 'test \"\$(sh tools/p95.sh)\" = 250'"

snip 04-culprit
run 'git bisect log'
run 'git tag culprit refs/bisect/bad'
run 'git bisect reset'
run 'git show --format="%h %an: %s" culprit'

snip 05-revert
run 'git revert --no-edit culprit'
run 'sh tools/p95.sh'
run 'git show --stat --format="%s%n%n%b" HEAD'
run 'git status -sb'

snip 06-spike-search
run_rc 'git reflog | grep -c histogram'
run 'cat .git/FETCH_HEAD'
run 'git fsck'
spike=$(git fsck 2>/dev/null | awk '/dangling commit/ {print $3}')
run "git log --format='%h %an: %s' main..${spike:0:7}"

snip 07-spike-restore
run "git branch spike/histogram ${spike:0:7}"
run 'git log --oneline --graph -4 spike/histogram'
run 'git fsck'
run 'cd ..'
show_check
gate_done

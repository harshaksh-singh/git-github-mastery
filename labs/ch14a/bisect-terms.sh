#!/usr/bin/env bash
# Chapter 14A, section 14A.22: bisect for a change that is not a breakage (custom terms), replay a
# saved bisect log, and restrict the search to the first-parent line.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a bisect-terms
fx_scorekit || exit 1
sk_ids

snip 01-terms
note "Since which commit does the runner work again without --limit? $ID_LIMIT is known to crash."
run 'git bisect start --term-old broken --term-new fixed'
run 'git bisect fixed main'
run "git bisect broken $ID_LIMIT"
run 'git bisect terms'

snip 02-run
note 'For bisect run, exit status 0 means the OLD state. grep exits 0 when it finds the crash.'
run "git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'"

snip 03-save-log
run 'git bisect log > ../bisect.log'
run 'cat ../bisect.log'
run 'git bisect reset'

snip 04-replay
run 'git bisect replay ../bisect.log'
run 'git bisect reset'

snip 05-good-bad-mixed
run 'git bisect start --term-old broken --term-new fixed'
run 'git bisect bad main 2>&1 | head -n 2'
run 'git bisect reset'

snip 06-first-parent
run 'git rev-list --count v0.1.0..main'
run 'git rev-list --count --first-parent v0.1.0..main'
run 'git bisect start --first-parent main v0.1.0'
run 'git bisect reset'

snip 07-wrong-way-round
run_rc 'git bisect start v0.1.0 main'
run 'git bisect reset'
lab_end

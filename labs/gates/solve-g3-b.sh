#!/usr/bin/env bash
# Gate 3, hands-on variant B (quota-svc): the model diagnosis and repair as real transcripts
# for answer-keys/gate-3-merge-and-rebase.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g3-b
gate_load gate-3-merge-and-rebase/variant-b
as config
f1=$(cat .gate/f1); f2=$(cat .gate/f2); f3=$(cat .gate/f3)

snip 01-observe
run 'cd asha'
run 'git status -sb'
run 'git log --oneline origin/release/2.1..HEAD'
run 'git log -1 --oneline CHERRY_PICK_HEAD'
run 'cat .git/sequencer/todo'

snip 02-range
run 'git log --oneline --reverse origin/release/2.1..main'
note 'What the range that Asha typed selects: the left end is excluded.'
run "git log --oneline --reverse ${f1:0:7}..${f3:0:7}"

snip 03-stages
run 'git ls-files -u'
note 'Stage 2, "ours": the branch being built, release/2.1. Stage 3, "theirs": the picked commit.'
run 'git show :1:quota/window.py | head -2'
run 'git show :2:quota/window.py | head -2'
run 'git show :3:quota/window.py | head -2'

snip 04-abort
run 'git cherry-pick --abort'
run 'git status -sb'
run 'git log --oneline origin/release/2.1..HEAD'

snip 05-pick
run "git cherry-pick -x ${f1:0:7} ${f2:0:7} ${f3:0:7}"
run 'git status -sb'

snip 06-resolve
printf 'WINDOW_S = 60\nDAY_S = 86400\n\ndef window_start(now):\n    return min(now - (now %% WINDOW_S), now - (now %% DAY_S) + DAY_S - WINDOW_S)\n' > quota/window.py
note 'quota/window.py edited by hand to the agreed file'
run 'git add quota/window.py'
run 'git cherry-pick --continue'

snip 07-verify
run "git log --format='%h %s%n  %b' origin/release/2.1..release/2.1"
run 'git cherry -v release/2.1 main'
run 'git diff --stat origin/release/2.1 release/2.1'
run 'git status -sb'
run 'cd ..'
show_check
gate_done

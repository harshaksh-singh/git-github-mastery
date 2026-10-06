#!/usr/bin/env bash
# Lab 35.3 replay: a backport that stopped half-way, with a hand-made conflict resolution that
# exists only in the working tree. Evidence is preserved in four layers, then the backport is
# finished. Failure scenario, rehearsed in a copy: git cherry-pick --abort. Recovery: the first
# pick from the rescue branch, the resolution from the evidence copy.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 lab-35-3-preserve-then-fix
fx_35_3

snip 01-handover
run 'cat guardrail.HANDOVER.txt'
run 'cd guardrail'
run 'git status'

snip 02-diagnose
run 'git log --graph --decorate --oneline --all'
run 'cat .git/CHERRY_PICK_HEAD'
run 'cat .git/sequencer/todo'
run 'git ls-files -u'
run 'git diff'

snip 03-preserve
run 'mkdir ../evidence'
run '{ git status; git log --graph --decorate --oneline --all; git reflog; git diff; } > ../evidence/state.txt 2>&1'
run 'git branch rescue/backport-partial HEAD'
run 'cp -Rp . ../evidence/guardrail-copy'
run 'cp -Rp . ../rehearsal'
run 'git bundle create ../evidence/guardrail.bundle --all'
run 'git bundle verify ../evidence/guardrail.bundle'

snip 04-fix
run 'cat guard.yaml'
run 'git add guard.yaml'
run 'git -c core.editor=true cherry-pick --continue'

snip 05-verify
run 'git status'
run 'git log --oneline -4'
run 'git show HEAD~1:guard.yaml'
run 'git cherry -v release/1.4 main'
run 'ls .git | grep -c -E "CHERRY_PICK_HEAD|sequencer"'

snip 06-failure
run 'cd ../rehearsal'
run 'git status | head -2'
run 'git cherry-pick --abort'
run 'git status'
run 'git log --oneline -2'
run 'cat guard.yaml'

snip 07-recovery
run 'git merge --ff-only rescue/backport-partial'
run_rc 'git cherry-pick -x main~1 main'
run 'cp ../evidence/guardrail-copy/guard.yaml guard.yaml'
run 'git add guard.yaml'
run 'git -c core.editor=true cherry-pick --continue'

snip 08-verification
run 'git log --oneline -4'
run "git rev-parse 'HEAD^{tree}'"
run "git -C ../guardrail rev-parse 'HEAD^{tree}'"
run 'git status -sb'

lab_end

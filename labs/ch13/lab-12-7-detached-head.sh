#!/usr/bin/env bash
# Lab 12.7 replay: two lines of work were committed in detached HEAD and left behind. Find
# their tips with "git fsck --no-reflogs", inspect them, and give each a branch. Failure:
# only the tip commit of a line is cherry-picked. Recovery: abort and pick the whole range.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-7-detached-head
fx_12_7
hot=$(git -C modelserver log -g --format='%h' --grep-reflog='commit: Hotfix: reject empty prompts')
exp=$(git -C modelserver log -g --format='%h' --grep-reflog='commit: Experiment: disable response cache')

snip 01-symptom
run 'cd modelserver'
run 'git status -sb'
run 'git log --oneline --graph --all'
run 'git branch --contains v1.2.0'

snip 02-reflog
run 'git reflog'

snip 03-fsck
run 'git fsck --no-reflogs'
run "git log --oneline --graph $hot $exp --not --all"

snip 04-inspect
run "git show --stat --format='%h %ad %s' --date=format:'%a %H:%M' $hot"
run "git show --stat --format='%h %ad %s' --date=format:'%a %H:%M' $exp"

snip 05-anchor
run "git branch hotfix/1.2.1 $hot"
run "git branch exp/no-response-cache $exp"
run 'git log --oneline --graph --all'

snip 06-verification
run 'git fsck --no-reflogs'
run 'git log --oneline v1.2.0..hotfix/1.2.1'

snip 07-failure
note 'The hotfixes are needed on main as well. Copying "the hotfix", that is, the newest commit:'
run_rc "git cherry-pick $hot"
run 'git status -s'

snip 08-recovery
run 'git cherry-pick --abort'
run 'git status -s'
run 'git cherry-pick v1.2.0..hotfix/1.2.1'

snip 09-after
run 'git log --oneline -3'
run 'cat validate.py'
run 'git status -sb'

lab_end

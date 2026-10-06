#!/usr/bin/env bash
# Lab 12.8 replay: "git reset --hard" over uncommitted work. What was staged at any time comes
# back from dangling blobs through "git fsck --lost-found"; what was never staged does not
# exist. Failure: "git stash clear" removes two entries. Recovery: the recipe from the
# git-stash manual, with the reason its --grep=WIP misses one of them.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-8-overwritten-changes
fx_12_8
# Blob IDs depend only on content; the stash commits were created by the fixture.
sweep=$(printf 'lr: [1e-5, 3e-5]\nwarmup_ratio: [0.0, 0.1]\n' | git hash-object --stdin)
staged=$(printf 'lr: 3e-5\nepochs: 5\n' | git hash-object --stdin | cut -c1-7)
never=$(printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' | git hash-object --stdin | cut -c1-7)
lora=$(git -C finetune-incident rev-parse --short 'stash@{0}')
wip=$(git -C finetune-incident rev-parse --short 'stash@{1}')

snip 01-start
run 'cd finetune'
run 'git status -s'
run 'git diff --cached --stat'
run 'git diff --stat'

snip 02-disaster
run 'git reset --hard'
run 'git status -s'
run 'ls'
run 'cat train.yaml'

snip 03-find
run 'git fsck --lost-found'
run 'ls .git/lost-found/other'

snip 04-identify
run 'grep -c "" .git/lost-found/other/*'
run 'grep -l warmup_ratio .git/lost-found/other/*'
run 'grep -l epochs .git/lost-found/other/*'

snip 05-restore
run "cp .git/lost-found/other/$sweep sweep.yaml"
run "git cat-file -p $staged > train.yaml"
run 'cat sweep.yaml train.yaml'
run 'git add sweep.yaml train.yaml'
run 'git status -s'

snip 06-never-staged
note 'The line that was typed after the last "git add". This is the ID its file would have had:'
run "printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' | git hash-object --stdin"
run_rc "git cat-file -t $never"

snip 07-failure
run 'cd ../finetune-incident'
run 'git stash list'
run 'git stash clear'
run 'git stash list'

snip 08-recovery-recipe
note 'The recipe from the git-stash manual:'
run "git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --grep=WIP --format='%h %s'"
note 'Without --grep=WIP:'
run "git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'"

snip 09-recovery-apply
run "git stash store -m 'recovered: grad clip' $wip"
run "git stash store -m 'recovered: lora rank 16 trial' $lora"
run 'git stash list'
run "git stash show -p 'stash@{0}'"

snip 10-verification
run 'git fsck --unreachable'
run 'git stash list'
run 'git status -s'

lab_end

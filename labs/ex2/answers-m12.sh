#!/usr/bin/env bash
# Model answers for exercises 12.1 to 12.8 (Module 12, recovery) as real transcripts on the
# practice repositories built by exercises/gen/m12-labelhub/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m12
ex_load m12-labelhub

# ---------------------------------------------------------------- 12.1
cd ex-12-1 || exit 1
snip 12-1-reflog
run 'git log --oneline'
run 'git reflog'
run 'git reflog show main'
snip 12-1-on-disk
run 'tail -2 .git/logs/HEAD'
snip 12-1-rescue
run "git branch rescue 'HEAD@{2}'"
run 'git log --oneline main..rescue'
run 'git diff --stat main...rescue'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.2
cd ex-12-2 || exit 1
snip 12-2-backup
run 'git log --oneline main..HEAD'
run 'git branch backup/pre-squash'
run "git reset --soft main && git commit -q -m 'Add guidelines'"
run 'git log --oneline main..HEAD'
run 'git rev-parse --short ORIG_HEAD'
run 'git rev-parse --short backup/pre-squash'
run 'git diff --stat backup/pre-squash HEAD'
snip 12-2-restore
run 'git reset --hard backup/pre-squash'
run 'git log --oneline main..HEAD'
run 'git rev-parse --short ORIG_HEAD'
run 'git branch -d backup/pre-squash'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.3
cd ex-12-3 || exit 1
snip 12-3-fsck
run 'git fsck'
run 'git fsck --no-reflogs'
run 'git fsck --unreachable --no-reflogs | sort'
snip 12-3-identify
run 'git fsck --lost-found'
run 'ls .git/lost-found/commit .git/lost-found/other'
for c in $(ls .git/lost-found/commit); do
  run "git show -s --format='%h %p | %s' ${c:0:7}"
done
b=$(ls .git/lost-found/other)
run "git cat-file -p ${b:0:7}"
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.4
cd ex-12-4 || exit 1
snip 12-4-setup
run 'git init -q reflog-lab && cd reflog-lab'
run 'echo one > f.txt && git add f.txt && git commit -q -m A'
run 'echo two >> f.txt && git commit -q -am B'
run "git commit -q --amend -m 'B, reworded'"
run 'git reset --soft HEAD~1'
run 'git commit -q -m C'
run 'git switch -q -c topic'
snip 12-4-answer
run 'git reflog'
run 'git reflog show main'
run 'git reflog show topic'
run 'git rev-list --count HEAD'
run "git cat-file --batch-check --batch-all-objects | grep -c ' commit '"
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.5
cd ex-12-5 || exit 1
snip 12-5-one-file
run 'git reflog -3'
run "git diff --stat 'HEAD@{1}' HEAD"
run "git restore --source='HEAD@{1}' -- schema/labels.yaml"
run 'git status -sb'
run 'tail -5 schema/labels.yaml'
run 'git reflog -1'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.6
cd ex-12-6 || exit 1
snip 12-6-commands
run 'git log --oneline'
run 'git reset --hard HEAD~2'
run "echo 'E readme' > readme.txt && git add readme.txt && git commit -q -m 'E readme'"
run "git branch rescue 'main@{2}'"
snip 12-6-graph-1
run 'git log --graph --oneline --all'
snip 12-6-graph-2
run 'git rebase rescue'
run 'git log --graph --oneline --all'
run 'git reflog -3'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.7
cd ex-12-7/work || exit 1
snip 12-7-diagnose
run 'git status -sb'
run_rc 'git push'
run 'git reflog -3'
run 'git log --graph --oneline --all'
run 'git diff --stat origin/main HEAD'
snip 12-7-fix
run 'git reset --soft origin/main'
run 'git status -sb'
run "git commit -m 'Add schema validation script'"
run 'git log --graph --oneline --all'
run 'git push'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.8
cd ex-12-8 || exit 1
snip 12-8-diagnose
run_rc 'git clone backup.bundle restored'
run 'git bundle list-heads backup.bundle'
run 'sed -n 1,2p backup.bundle'
snip 12-8-restore
run 'git clone -q server.git restored && cd restored'
run 'git bundle verify ../backup.bundle'
run "git fetch ../backup.bundle 'refs/heads/*:refs/heads/*'"
run 'git log --graph --oneline --all'
lab_end

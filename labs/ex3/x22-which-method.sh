#!/usr/bin/env bash
# Exercise 22.2 (Module 22): one pull request merged three ways in three copies of the
# maintainer's clone, shown as three anonymous histories X, Y and Z. The local commands stand
# in for the three merge buttons; on GitHub the committer of what lands is GitHub, not Asha.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x22-which-method
make_server
new_clone you
new_clone asha
enter you
hidden 'git switch -c feature/overlap'
split_v2
commit_all 'Add overlap parameter'
test_v2
commit_all 'Test that overlap repeats characters'
split_v3
commit_all 'Reject an overlap that is not smaller than the size'
hidden 'git push -u origin feature/overlap'
HEAD_ID=$(git rev-parse --short HEAD)
enter asha
config_v2
commit_all 'Double the default chunk size'
hidden 'git push origin main'
hidden 'git fetch'
cd "$LAB_DIR" || exit 1
cp -R asha/chunker X && cp -R asha/chunker Y && cp -R asha/chunker Z || exit 1
as asha
( cd X && tick && git switch -q -c pr origin/feature/overlap && git rebase -q --force-rebase main && git switch -q main && git merge -q --ff-only pr && git branch -q -D pr ) > /dev/null 2>&1 || exit 1
tick
( cd Y && git merge -q --squash origin/feature/overlap && git commit -q -m 'Add overlap to the splitter (#12)' ) > /dev/null 2>&1 || exit 1
tick
( cd Z && git merge -q --no-ff -m 'Merge pull request #12 from feature/overlap' origin/feature/overlap ) > /dev/null 2>&1 || exit 1
as you
FMT="--format='%h | %an | %cn | %s'"

snip 01-pull-request
note 'The pull request: feature/overlap into main. Its head commit and its commits:'
run "git -C you/chunker log --format='%h | %an | %s' main..feature/overlap"

snip 02-history-x
run "git -C X log --graph $FMT -5 main"
snip 03-history-y
run "git -C Y log --graph $FMT -5 main"
snip 04-history-z
run "git -C Z log --graph $FMT -6 main"

snip 05-ancestry
for r in X Y Z; do
  run_rc "git -C $r merge-base --is-ancestor $HEAD_ID main"
done
run 'git -C X rev-parse main^{tree} && git -C Y rev-parse main^{tree} && git -C Z rev-parse main^{tree}'

snip 06-audit
SQ=$(git -C Y rev-parse --short main)
note 'History Y: was the approved head commit what landed? Rebuild the test merge and compare trees.'
run "git -C Y merge-tree --write-tree $SQ~1 $HEAD_ID"
run "git -C Y rev-parse $SQ^{tree}"
run "git -C Y diff --stat $HEAD_ID $SQ"

snip 07-revert
as asha
run 'git -C X revert --no-edit main~3..main'
run 'git -C Y revert --no-edit main'
run 'git -C Z revert --no-edit -m 1 main'
run 'git -C X rev-parse main^{tree} && git -C Y rev-parse main^{tree} && git -C Z rev-parse main^{tree}'
run 'git -C X rev-parse main~3^{tree}'

lab_end

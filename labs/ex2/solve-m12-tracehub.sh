#!/usr/bin/env bash
# Model solution of exercise 12.12 (Level 5): a clone damaged by a power loss in the middle of a
# commit. Four things are broken; each error hides the next one. Nothing is deleted before it is
# understood, and the lost commit is rebuilt bit for bit.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m12-tracehub
ex_load m12-tracehub
cd you || exit 1

snip 01-symptoms
run_rc 'git status'
run_rc 'git log --oneline -3'
run_rc 'git branch -vv'

snip 01-first-look
run 'cat .git/HEAD'
run 'git log --oneline -2 main'

snip 02-copy-first
run 'cp -R ../you ../you.before-repair'

snip 03-the-branch-file
run 'wc -c < .git/refs/heads/feature/sampling'
run 'tail -2 .git/logs/refs/heads/feature/sampling'
old=$(tail -1 .git/logs/refs/heads/feature/sampling | cut -d' ' -f1)
new=$(tail -1 .git/logs/refs/heads/feature/sampling | cut -d' ' -f2)
ts=$(tail -1 .git/logs/refs/heads/feature/sampling | awk -F'\t' '{print $1}' | awk '{print $(NF-1), $NF}')
run_rc "git cat-file -t ${new:0:7}"
run "git cat-file -t ${old:0:7}"

snip 04-repair-the-ref
run_rc "git update-ref refs/heads/feature/sampling ${old:0:7}"
run 'mv .git/refs/heads/feature/sampling ../branch-file.damaged'
run "git update-ref -m 'repair: last readable commit from the reflog' refs/heads/feature/sampling ${old:0:7}"
run 'git log --oneline -3'

snip 05-repair-the-index
run 'wc -c < .git/index'
run 'mv .git/index ../index.damaged'
run 'git reset'
run 'git status -sb'

snip 06-fsck
run_rc 'git fsck'

snip 07-refetch
blob=$(git fsck 2>/dev/null | awk '$1=="missing" && $2=="blob"{print $3}')
bpath=".git/objects/${blob:0:2}/${blob:2}"
run "git rev-list --objects --all | grep ^${blob:0:7}"
run "git ls-tree -r main~2 | grep ${blob:0:7}"
run "mv $bpath ../blob.damaged"
run 'git fetch --refetch origin'
run "git cat-file -t ${blob:0:7}"

snip 08-the-lost-commit
cpath=".git/objects/${new:0:2}/${new:2}"
run "mv $cpath ../commit.damaged"
run 'git add -A'
run 'git write-tree'
tree=$(git write-tree)
run 'git fsck 2>/dev/null | grep dangling'

snip 09-rebuild-the-commit
run "GIT_AUTHOR_DATE='$ts' GIT_COMMITTER_DATE='$ts' git commit-tree ${tree:0:7} -p ${old:0:7} -m 'Sample traces by tenant'"
run "git reset --soft ${new:0:7}"
run 'git status -sb'

snip 10-verify
run_rc 'git fsck'
run 'git log --graph --oneline --all'
run 'git reflog -4'
run 'cd ..'
show_check
ex_done

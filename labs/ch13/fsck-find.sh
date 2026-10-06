#!/usr/bin/env bash
# Chapter 13, section 13.6: git fsck as a search tool. Dangling against unreachable, the
# effect of --no-reflogs, a triage listing of lost tips, --lost-found, and anchoring a found
# commit with a branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 fsck-find
fx_searchsvc
cd searchsvc || exit 1
quiet 'git switch -c exp/hybrid'
quiet "printf 'def dense(q, d):\n    return dot(embed(q), embed(d))\n' > dense.py && git add . && git commit -m 'Add dense scorer'"
quiet "printf 'alpha: 0.7\n' > hybrid.yaml && git add . && git commit -m 'Add hybrid weights'"
quiet "printf 'alpha: 0.6\n' > hybrid.yaml && git commit -am 'Tune alpha to 0.6'"
quiet 'git switch main'
quiet "printf 'alpha: [0.5, 0.6, 0.7]\n' > sweep.yaml && git add sweep.yaml && git reset --hard"
tip=$(git rev-parse --short exp/hybrid)

snip 01-with-reflogs
run 'git branch -D exp/hybrid'
run 'git fsck'

snip 02-no-reflogs
run 'git fsck --no-reflogs'
run 'git fsck --no-reflogs --unreachable'

snip 03-triage
run "git fsck --no-reflogs | awk '/dangling commit/ {print \$3}' | xargs git log --no-walk --date=iso --format='%h  %cd  %an  %s'"
run "git log --oneline $tip --not --all"

snip 04-lost-found
run 'git fsck --no-reflogs --lost-found'
run 'find .git/lost-found -type f | sort'
run 'cat .git/lost-found/other/*'

snip 05-anchor
run "git branch rescue/hybrid $tip"
run 'git fsck --no-reflogs'
run 'git log --oneline main..rescue/hybrid'

lab_end

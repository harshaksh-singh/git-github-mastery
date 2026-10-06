#!/usr/bin/env bash
# Chapter 11, section 11.5: why "git reset --hard" is dangerous. Three kinds of work go in:
# committed, staged but never committed, and never staged. The demo proves what survives:
# the commit (through the reflog), the staged content (only as a dangling blob), and nothing
# of the never-staged edit. A second repository shows an untracked file being overwritten.
#
# Note on "git fsck": Git 2.55 ignores reflog entries whose timestamp is later than the moment
# fsck starts. The lab clock is pinned, so this demo only runs fsck at points where no object
# depends on a reflog entry for reachability. Its output is then the same on any date.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 reset-hard-proofs

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && git add rank.py && git commit -m 'Add BM25 ranker'"
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"
quiet "printf 'def score(q, d):\n    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)\n' > rank.py && git commit -am 'Blend dense scores into ranker'"

snip 01-three-kinds-of-work
run 'git log --oneline'
run "printf 'alpha: [0.5, 0.7, 0.9]\n' > sweep.yaml"
run 'git add sweep.yaml'
run "printf 'recall@10: 0.78\n' > metrics.txt"
run "printf 'try alpha=0.9 next\n' > notes.txt"
run 'git status -s'

snip 02-reset-hard
run 'git reset --hard HEAD~1'
run 'git log --oneline'
run 'git status -s'
run 'ls'
run 'cat metrics.txt'

snip 03-committed-work
run 'git reflog -2'
run 'git reset --hard HEAD@{1}'
run 'git log --oneline'
run 'git status -s'

snip 04-staged-work
run 'git fsck --lost-found'
run 'git cat-file -p acc57c7'
run 'ls .git/lost-found/other'
run 'git cat-file -p acc57c7 > sweep.yaml'
run 'git status -s'

snip 05-never-staged-work
note 'The staged file: its content was hashed by "git add", so the object exists.'
run "printf 'alpha: [0.5, 0.7, 0.9]\n' | git hash-object --stdin"
run 'git cat-file -t acc57c7b481e66cf03ec96980cc21fadcadc8a5b'
note 'The never-staged edit: this is the ID it would have had. No such object was ever written.'
run "printf 'recall@10: 0.78\n' | git hash-object --stdin"
run_rc 'git cat-file -t b812359d6f71b2a9857c24b3c631b8ea58213fcd'

# ---------------------------------------------------------------- untracked file overwritten
cd "$LAB_DIR" || exit 1
quiet 'git init tuner'
cd tuner || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && git add rank.py && git commit -m 'Add BM25 ranker'"
quiet "printf 'alpha: 0.7\n' > sweep.yaml && git add sweep.yaml && git commit -m 'Add sweep config'"
quiet "git rm --cached sweep.yaml && git commit -m 'Stop tracking sweep config'"
quiet "printf 'alpha: 0.9   # two days of tuning\n' > sweep.yaml"

snip 06-untracked-overwritten
run 'git log --oneline'
run 'git status -s'
run 'cat sweep.yaml'
run_rc 'git reset --keep HEAD~1'
run 'git reset --hard HEAD~1'
run 'cat sweep.yaml'

lab_end

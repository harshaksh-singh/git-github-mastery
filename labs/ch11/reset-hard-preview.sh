#!/usr/bin/env bash
# Chapter 11, section 11.5: what to look at before "git reset --hard", and the two-command
# safety net that turns everything at risk into objects with a name: a stash entry for the
# uncommitted work (staged, unstaged and untracked) and a branch for the commits.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 reset-hard-preview

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && git add rank.py && git commit -m 'Add BM25 ranker'"
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"
quiet "printf 'def score(q, d):\n    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)\n' > rank.py && git commit -am 'Blend dense scores into ranker'"
quiet "printf 'alpha: [0.5, 0.7, 0.9]\n' > sweep.yaml && git add sweep.yaml"
quiet "printf 'recall@10: 0.78\n' > metrics.txt"
quiet "printf 'try alpha=0.9 next\n' > notes.txt"

snip 01-preview
note 'Commits that will leave the branch (they stay in the reflog):'
run 'git log --oneline HEAD~2..HEAD'
note 'Uncommitted work (a hard reset destroys the first two lines and keeps the third):'
run 'git status -s'
note 'Tracked content that differs from the last commit:'
run 'git diff HEAD --stat'

snip 02-safety-net
run 'git stash push -u -m "before reset to HEAD~2"'
run 'git branch backup/before-reset'
run 'git status -s'
run 'git reset --hard HEAD~2'
run 'git log --oneline'

snip 03-nothing-was-lost
run 'git log --oneline backup/before-reset'
run 'git stash list'
run 'git stash show --include-untracked'

lab_end

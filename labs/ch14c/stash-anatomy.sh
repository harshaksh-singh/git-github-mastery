#!/usr/bin/env bash
# Chapter 14C, section 14C.2: what a stash entry is made of. The stash commit and its two or
# three parents, the trees each of them records, refs/stash and its reflog, "git stash show"
# against the plain diffs, "git stash create" and "store", what "drop" does to the reflog, and
# "git stash export" and "import".
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c stash-anatomy

quiet 'git init evalkit'
cd evalkit || exit 1
quiet "printf 'def score(pred, gold):\n    return pred == gold\n' > score.py && printf 'threshold: 0.5\n' > config.yaml && git add . && git commit -m 'Add scorer and config'"
quiet "printf 'def score(pred, gold):\n    return pred.strip() == gold.strip()\n' > score.py && git add score.py"
quiet "printf 'threshold: 0.7\n' > config.yaml"
quiet "printf 'try threshold 0.6 as well\n' > notes.md"

snip 01-push
run 'git status -s'
run 'git stash push -u -m "wip: strip whitespace"'
run 'git status -s'
run 'git stash list'

snip 02-graph
note 'Each line: commit, [its parents], subject.'
run "git log --graph --format='%h [%p] %s' 'stash@{0}'"

snip 03-commit-object
run "git show -s --format=raw 'stash@{0}'"

snip 04-trees
note 'H, the commit that was HEAD:'
run "git ls-tree -r 'stash@{0}^1'"
note 'I, the index as it was (second parent):'
run "git ls-tree -r 'stash@{0}^2'"
note 'W, the tracked files as they were on disk (the stash commit itself):'
run "git ls-tree -r 'stash@{0}'"
note 'U, the untracked files (third parent, only with -u or -a):'
run "git ls-tree -r 'stash@{0}^3'"

snip 05-show
note 'What "git stash show -p" prints is the difference between H and W:'
run "git stash show -p"
note 'The staged part is H against I, the unstaged part is I against W:'
run "git diff --stat 'stash@{0}^1' 'stash@{0}^2'"
run "git diff --stat 'stash@{0}^2' 'stash@{0}'"
run "git stash show --only-untracked"

snip 06-ref-and-reflog
run "printf 'threshold: 0.9\n' > config.yaml"
run 'git stash push -m "wip: threshold 0.9"'
run 'git stash list'
run 'cat .git/refs/stash'
run 'cat .git/logs/refs/stash'
run "git rev-parse 'stash@{0}' 'stash@{1}'"

snip 07-create-store
run "printf 'threshold: 0.8\n' > config.yaml"
note '"create" builds the commits and prints the ID. No ref is written and the files stay as they are.'
run 'git stash create "wip: threshold 0.8"'
created=$(git rev-parse --short "$(git fsck --unreachable 2>/dev/null | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format=%H | head -n 1)")
run 'git stash list'
run 'git status -s'
note '"store" puts an existing stash commit on the list:'
run "git stash store -m 'stored by hand' $created"
run 'git stash list'
quiet 'git restore config.yaml'

snip 08-drop
run "git stash drop 'stash@{1}'"
dropped=$(git fsck --unreachable 2>/dev/null | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format=%h | head -n 1)
run 'git stash list'
run 'cat .git/logs/refs/stash'
note 'The dropped commit still exists as an unreachable object:'
run "git cat-file -t $dropped"

snip 09-export
run 'git stash export --to-ref refs/stashes/laptop'
run "git log --graph --format='%h %s' refs/stashes/laptop"

snip 10-import
run 'git clone -q . ../evalkit-desktop'
run 'cd ../evalkit-desktop'
run 'git stash list'
run 'git fetch -q origin refs/stashes/laptop'
run 'git stash import FETCH_HEAD'
run 'git stash list'

lab_end

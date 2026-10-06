#!/usr/bin/env bash
# "git diff", "git diff --cached" and "git diff HEAD" are three different comparisons
# between three trees. Chapter 5, section 5.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 three-diffs

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
cat > src/retriever.py <<'PY'
TOP_K = 5
MIN_SCORE = 0.2


def retrieve(query, index):
    hits = index.search(query, TOP_K)
    return [h for h in hits if h.score >= MIN_SCORE]
PY
quiet 'git add . && git commit -m "Add retriever"'

# Stage one edit, leave a second edit unstaged.
sed -e 's/TOP_K = 5/TOP_K = 8/' src/retriever.py > t && mv t src/retriever.py
git add src/retriever.py
sed -e 's/MIN_SCORE = 0.2/MIN_SCORE = 0.35/' src/retriever.py > t && mv t src/retriever.py

snip 01-state
note 'TOP_K was changed to 8 and staged. MIN_SCORE was then changed to 0.35 and not staged.'
run 'git status --short'

snip 02-diff
note 'Index against working tree: what you could still stage.'
run 'git diff'

snip 03-diff-cached
note 'HEAD against index: what the next commit will change. --staged is a synonym.'
run 'git diff --cached'

snip 04-diff-head
note 'HEAD against working tree: everything since the last commit, staged or not.'
run 'git diff HEAD'

snip 05-cancel-out
note 'Put the content of HEAD back into the working tree only. The index still has TOP_K = 8.'
run 'git restore --source=HEAD src/retriever.py'
run 'git status --short'
run 'git diff HEAD'
run 'git diff --cached --stat'
run 'git diff --stat'
note 'The files on disk match HEAD, yet a commit made now would set TOP_K to 8.'

lab_end

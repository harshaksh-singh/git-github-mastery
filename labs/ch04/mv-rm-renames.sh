#!/usr/bin/env bash
# "git mv" and "git rm" as index operations, and the proof that Git does not record renames:
# a rename is detected at display time by comparing two snapshots. Chapter 4, sections 4.8 and 4.9.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 mv-rm-renames

git init -q support-bot
cd support-bot || exit 1
mkdir -p src docs
cat > src/retriever.py <<'PY'
TOP_K = 5


def score(query_vec, doc_vec):
    return sum(q * d for q, d in zip(query_vec, doc_vec))


def retrieve(query_vec, index):
    scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
    scored.sort(reverse=True)
    return scored[:TOP_K]
PY
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'Old design notes.\n' > docs/old-notes.md
printf 'Runbook.\n' > docs/runbook.md
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-git-mv
run 'git ls-files --stage src'
run 'git mv src/retriever.py src/search.py'
run 'git status --short'
run 'git ls-files --stage src'
note 'Same blob ID, new path. The tree that this index would produce:'
run 'git write-tree'

snip 02-same-as-manual
note 'Undo, then do the same rename with plain shell commands.'
run 'git restore --staged --worktree --source=HEAD .'
run 'git status --short'
run 'mv src/retriever.py src/search.py'
run 'git status --short'
run 'git add -A src'
run 'git status --short'
run 'git write-tree'

snip 03-commit-has-no-rename
run 'git commit -m "Rename retriever module to search"'
run 'git cat-file -p HEAD'
run 'git ls-tree -r HEAD'

snip 04-detected-on-demand
note 'The rename is computed when two snapshots are compared.'
run 'git diff --name-status HEAD~1 HEAD'
run 'git diff --name-status --no-renames HEAD~1 HEAD'

snip 05-rename-and-edit
note 'Rename and edit in one commit: similarity drops below 100.'
quiet 'git mv src/search.py src/vector_search.py'
quiet "sed -e 's/TOP_K = 5/TOP_K = 8/' src/vector_search.py > t && mv t src/vector_search.py && git add src/vector_search.py"
quiet 'git commit -m "Rename search module and raise TOP_K"'
run 'git diff --name-status HEAD~1 HEAD'
run 'git diff --name-status -M98% HEAD~1 HEAD'

snip 06-follow
run 'git log --oneline -- src/vector_search.py'
run 'git log --oneline --follow -- src/vector_search.py'

snip 07-git-rm
run 'git rm docs/old-notes.md'
run 'git status --short'
run 'ls docs'
note 'git rm refuses to delete content that exists nowhere else.'
run "echo 'Escalation contacts.' >> docs/runbook.md"
run_rc 'git rm docs/runbook.md'
run 'git rm --cached docs/runbook.md'
run 'git status --short'

lab_end

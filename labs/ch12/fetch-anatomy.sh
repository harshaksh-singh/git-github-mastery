#!/usr/bin/env bash
# git fetch: which refs move and which do not, FETCH_HEAD, and why "up to date" in
# git status only describes your last fetch. Chapter 12, section 12.4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 fetch-anatomy

# Hidden setup: you and Asha both clone; then Asha publishes a commit on main,
# a new branch and an annotated tag. You have not fetched since.
make_server
new_clone you
new_clone asha
enter asha
commit_file app/retriever.py 'def retrieve(query, top_k):\n    return search(query)[:top_k]\n' 'Implement retrieval'
hidden 'git push'
hidden 'git tag -a v0.1.0 -m "First internal release"'
hidden 'git push origin v0.1.0'
hidden 'git switch -c feature/reranker'
commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
hidden 'git push -u origin feature/reranker'
hidden 'git switch main'
enter you

snip 01-stale-status
run 'git status'
run 'git show-ref --abbrev'

snip 02-ls-remote
run 'git ls-remote origin'

snip 03-fetch
run 'git fetch'
run 'cat .git/FETCH_HEAD'

snip 04-after
run 'git show-ref --abbrev'
run 'git status'

snip 05-graph
run 'git log --oneline --graph --decorate --all'
run 'git log --oneline main..origin/main'

snip 06-reflog
run 'git reflog show origin/main'
run 'git reflog show main'

snip 07-integrate
run 'git merge --ff-only origin/main'
run 'git status -sb'

# Asha publishes one more commit on main.
enter asha
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you

snip 08-fetch-one-branch
run 'git fetch origin main'
run 'cat .git/FETCH_HEAD'
run 'git status -sb'

snip 09-fetch-url
run 'git fetch ../../server/support-bot.git feature/reranker'
run 'cat .git/FETCH_HEAD'
run 'git log --oneline -1 FETCH_HEAD'

snip 10-quiet-fetch
run 'git fetch'
run 'git fetch --verbose'

lab_end

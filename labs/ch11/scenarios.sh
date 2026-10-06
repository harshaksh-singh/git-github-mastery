#!/usr/bin/env bash
# Chapter 11, section 11.13: the seven worked "undo" scenarios, run against a bare repository
# that plays the server (origin), so that "pushed" and "unpushed" are real states.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 scenarios

quiet 'git init --bare server.git'
quiet 'git clone server.git ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'timeout_s: 30\nretries: 2\n' > serve.yaml && git add . && git commit -m 'Add BM25 ranker and serving config'"
# A feature branch that starts here and is merged in scenarios 6 and 7.
quiet 'git switch -c feature/reranker'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs, key=lambda d: cross_encoder(q, d), reverse=True)\n' > rerank.py && git add rerank.py && git commit -m 'Add cross-encoder reranker'"
quiet 'git switch main'
quiet "printf 'timeout_s: 30\nretries: 0\n' > serve.yaml && git commit -am 'Disable retries'"
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"
quiet 'git push -u origin main'
bad=$(git rev-parse --short HEAD~1)

# ---- scenario 1: the last commit is local only
quiet "printf 'def score(q, d):\n    return with_backoff(bm25, q, d)\n' > rank.py && git commit -am 'WIP: retry with backoff, untested'"

snip s1-undo-last-unpushed-commit
run 'git status -sb'
run 'git branch -r --contains HEAD'
run 'git reset --soft HEAD~1'
run 'git status -sb'
run 'git log --oneline -1'

# ---- scenario 3: a file that should not be in the last (unpushed) commit
quiet "printf 'SERVICE_TOKEN=local-dev-only\n' > .env && git add . && git commit -m 'Retry BM25 scoring with backoff'"

snip s3-remove-file-from-last-commit
run 'git show --stat --format="%h %s" HEAD'
run 'git rm --cached .env'
run 'git commit --amend --no-edit'
run 'git show --stat --format="%h %s" HEAD'
run 'git status -s'

quiet "printf '.env\n' > .gitignore && git add .gitignore && git commit -m 'Ignore local .env files'"
quiet 'git push'

# ---- scenario 2: a bad commit that is already on origin/main
snip s2-pushed-bad-commit
run 'git log --oneline'
run "git branch -r --contains $bad"
run "git revert --no-edit $bad"
run 'git status -sb'
run 'git push'

# ---- scenarios 4 and 5: unstage, then discard
quiet "printf 'def score(q, d):\n    return with_backoff(bm25, q, d, tries=5)\n' > rank.py && git add rank.py"
quiet "printf 'timeout_s: 3\nretries: 2\n' > serve.yaml"
quiet "printf 'scratch\n' > probe_output.txt"

snip s4-unstage
run 'git status -s'
run 'git restore --staged rank.py'
run 'git status -s'

snip s5-discard-local-changes
run 'git restore rank.py serve.yaml'
run 'git status -s'
run 'git clean -n'
run 'git clean -f'
run 'git status -s'

# ---- scenario 6: a merge that exists only locally, with an unrelated edit in progress
quiet "printf 'recall@10: 0.74\n' > metrics.txt"

snip s6-undo-unpushed-merge
run 'git merge feature/reranker'
run 'git status -sb'
run 'git reset --merge ORIG_HEAD'
run 'git status -sb'
run 'git log --oneline -1'

# ---- scenario 7: the same merge, but pushed
quiet 'git stash push && git merge feature/reranker && git push'

snip s7-undo-pushed-merge
run 'git log --oneline --graph -4'
run 'git branch -r --contains HEAD'
run 'git revert --no-edit -m 1 HEAD'
run 'git push'
run 'ls'

lab_end

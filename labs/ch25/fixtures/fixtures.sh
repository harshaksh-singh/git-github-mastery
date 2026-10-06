#!/usr/bin/env bash
# labs/ch25/fixtures/fixtures.sh
# Hidden setup shared by the Chapter 25 demos, the Lab 14.1 replay and its hands-on setup script.
# Source it after lab-env.sh:   . "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
# Every fx_* function expects the current directory to be the sandbox ($LAB_DIR), builds its
# repositories with the pinned lab clock and leaves you inside your clone, rag-api.
#
# The project is "rag-api", a retrieval-augmented question-answering service.
#   remotes/rag-api.git   the shared repository
#   rag-api/              your clone; main is the release line
#   feature/rerank        your topic branch, three commits, based on an older main

put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }
commit_all() { tick; git add -A > /dev/null 2>&1 && git commit -q -m "$1" > /dev/null 2>&1; }

handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

_retriever_v1() {
  put app/retriever.py <<'PY'
TOP_K = 5


def retrieve(index, query):
    hits = index.search(query, limit=TOP_K)
    return [h.text for h in hits]
PY
}

_retriever_main() {          # main raises TOP_K and filters short hits
  put app/retriever.py <<'PY'
TOP_K = 8


def retrieve(index, query):
    hits = index.search(query, limit=TOP_K)
    return [h.text for h in hits if len(h.text) > 20]
PY
}

_retriever_feature() {       # the feature branch reranks the hits
  put app/retriever.py <<'PY'
from app.rerank import rerank

TOP_K = 5


def retrieve(index, query):
    hits = index.search(query, limit=TOP_K)
    return [h.text for h in rerank(query, hits)]
PY
}

_checks() {
  put scripts/check.sh <<'SH'
#!/bin/sh
# Stands in for the test suite: the API must not pass an empty question to the retriever.
if grep -q 'if not question' app/api.py; then
  echo "checks passed"
else
  echo "checks failed: app/api.py accepts an empty question"
  exit 1
fi
SH
  chmod +x scripts/check.sh
}

# fx_ragapi: the shared repository and your clone, on main, in sync, with the tag v1.3.0.
fx_ragapi() {
  mkdir -p remotes
  quiet 'git init --bare remotes/rag-api.git'
  quiet 'git clone remotes/rag-api.git rag-api'
  cd rag-api || return 1
  put app/api.py <<'PY'
from app.retriever import retrieve


def ask(index, question):
    passages = retrieve(index, question)
    return {"question": question, "passages": passages}
PY
  _retriever_v1
  put README.md <<'MD'
# rag-api

Retrieval-augmented question answering.
MD
  put .gitignore <<'TXT'
.venv/
__pycache__/
TXT
  commit_all 'Add question endpoint and retriever'
  _checks
  commit_all 'Add check script'
  tick; git tag -a v1.3.0 -m 'rag-api 1.3.0' > /dev/null 2>&1
  quiet 'git push -u origin main --tags'
}

# fx_ragapi_feature: fx_ragapi, then feature/rerank with three commits, then two more commits on
# main, one of which touches the same lines of app/retriever.py as the feature. You end on main.
fx_ragapi_feature() {
  fx_ragapi
  quiet 'git switch -c feature/rerank'
  put app/rerank.py <<'PY'
def rerank(query, hits):
    words = set(query.lower().split())
    return sorted(hits, key=lambda h: -len(words & set(h.text.lower().split())))
PY
  commit_all 'Add keyword-overlap reranker'
  _retriever_feature
  commit_all 'Rerank retrieved passages'
  put docs/rerank.md <<'MD'
# Reranking

Passages are ordered by the number of words they share with the question.
MD
  commit_all 'Document reranking'
  quiet 'git switch main'
  _retriever_main
  commit_all 'Retrieve eight passages and drop short ones'
  put docs/deploy.md <<'MD'
# Deploying

Tag a release on main; the pipeline builds the image.
MD
  commit_all 'Document deployment'
  quiet 'git push origin main'
}

# fx_ragapi_rebase_stopped: fx_ragapi_feature, then you start rebasing feature/rerank onto main and
# the rebase stops at a conflict in app/retriever.py. This is the starting point of Lab 14.1.
fx_ragapi_rebase_stopped() {
  fx_ragapi_feature
  quiet 'git switch feature/rerank'
  quiet 'git rebase main'
}

# fx_ragapi_review: fx_ragapi_feature, then Asha pushes a branch feature/citations for review from a
# clone of her own (asha-rag-api). Your clone has not fetched it yet. You end in rag-api, on main.
fx_ragapi_review() {
  fx_ragapi_feature
  cd "$LAB_DIR" || return 1
  quiet 'git clone remotes/rag-api.git asha-rag-api'
  cd asha-rag-api || return 1
  as asha
  quiet 'git switch -c feature/citations'
  put app/api.py <<'PY'
from app.retriever import retrieve


def ask(index, question):
    passages = retrieve(index, question)
    cited = [{"n": i + 1, "text": p} for i, p in enumerate(passages)]
    return {"question": question, "passages": cited}
PY
  commit_all 'Number the passages so answers can cite them'
  quiet 'git push -u origin feature/citations'
  as you
  cd "$LAB_DIR/rag-api" || return 1
}

# hotfix_edit: the hotfix itself, written into app/api.py of the current directory.
hotfix_edit() {
  put app/api.py <<'PY'
from app.retriever import retrieve


def ask(index, question):
    if not question or not question.strip():
        raise ValueError("question must not be empty")
    passages = retrieve(index, question)
    return {"question": question, "passages": passages}
PY
}

# resolve_retriever: the resolution of the rebase conflict in app/retriever.py: main's settings
# (eight passages, short ones dropped) combined with the feature's reranking.
resolve_retriever() {
  put app/retriever.py <<'PY'
from app.rerank import rerank

TOP_K = 8


def retrieve(index, query):
    hits = index.search(query, limit=TOP_K)
    hits = [h for h in hits if len(h.text) > 20]
    return [h.text for h in rerank(query, hits)]
PY
}

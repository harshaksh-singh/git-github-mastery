# labs/ex2/m18-fixture.bash — the monorepo used by the Module 18 exercises.
# Sourced by exercises/gen/m18-*/generate.sh after gen-lib.bash. Never run.
#
# m18_server builds server.git in the current directory: the monorepo "searchstack" with two
# services, one library and documentation; the annotated tags v0.1.0 and v0.2.0; the branches
# main and release/0.2; and a merge commit at the tip of main. The server allows partial clones
# (uploadpack.allowFilter). Every call starts from the same minute of the lab clock, so all
# copies of the server have identical commit IDs. Local clones must use a file:// URL: with a plain path, Git copies
# or links the object files and ignores --depth and --filter (Chapter 26, section 26.13).
m18_server() {
  _lab_clock=$LAB_EPOCH_BASE; tick              # every copy of the server gets the same commit IDs
  quiet 'git init --bare server.git'
  quiet 'git -C server.git config set uploadpack.allowFilter true'
  quiet 'git clone server.git seed'
  (
    cd seed || exit 1
    put services/retriever/retrieve.py <<'F'
"""Fetches candidate passages from the vector index."""

TOP_K = 50


def retrieve(index, query):
    return index.search(query, limit=TOP_K)
F
    put libs/tokenize/tokenize.py <<'F'
"""Whitespace tokenizer shared by all services."""


def tokenize(text):
    return text.lower().split()
F
    put README.md <<'F'
# searchstack

Retrieval and reranking services, and the libraries they share.
F
    _c 'Add retriever service and tokenizer library'
    put docs/architecture.md <<'F'
# Architecture

Query -> retriever -> reranker -> answer.
F
    _c 'Describe the architecture'
    quiet "git tag -a v0.1.0 -m 'searchstack 0.1.0'"
    put services/reranker/rerank.py <<'F'
"""Reorders candidates with a cross-encoder."""

KEEP = 5


def rerank(scorer, query, passages):
    return sorted(passages, key=lambda p: scorer(query, p), reverse=True)[:KEEP]
F
    _c 'Add reranker service'
    as asha
    put libs/tokenize/tokenize.py <<'F'
"""Whitespace tokenizer shared by all services."""

import re

_WORD = re.compile(r"\w+")


def tokenize(text):
    return _WORD.findall(text.lower())
F
    _c 'Tokenize on word characters'
    as you
    put docs/runbook.md <<'F'
# Runbook

Restart order: retriever first, then reranker.
F
    _c 'Add runbook'
    quiet "git tag -a v0.2.0 -m 'searchstack 0.2.0'"
    quiet 'git branch release/0.2'
    as ravi
    quiet 'git switch -c feature/keep-ten'
    sed -e 's/KEEP = 5/KEEP = 10/' services/reranker/rerank.py > r.tmp && mv r.tmp services/reranker/rerank.py
    _c 'Keep ten passages after reranking'
    printf '\nThe reranker keeps ten passages.\n' >> docs/architecture.md
    _c 'Document the new reranker cut-off'
    as you
    quiet 'git switch main'
    sed -e 's/TOP_K = 50/TOP_K = 80/' services/retriever/retrieve.py > r.tmp && mv r.tmp services/retriever/retrieve.py
    _c 'Retrieve 80 candidates'
    quiet "git merge --no-ff feature/keep-ten -m \"Merge branch 'feature/keep-ten'\""
    quiet 'git switch release/0.2'
    printf '\nOn 0.2.x restart both services together.\n' >> docs/runbook.md
    _c 'Correct the restart order for 0.2'
    quiet 'git switch main'
    quiet 'git push origin main release/0.2 v0.1.0 v0.2.0'
  )
  _lab_clock=$((_lab_clock + 1200)); tick       # the subshell's ticks are lost; move past them
  rm -rf seed
  as you
}

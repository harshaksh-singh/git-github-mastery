#!/usr/bin/env bash
# labs/ch14a/fixtures/retriever.sh
# The small repository of Lab 10.4 (range notation). Source it after lab-env.sh:
#     . "$LAB_SCRIPT_DIR/fixtures/retriever.sh"
#
# "retriever" is a document retrieval service. main and feat/rerank have diverged:
#
#                 F---G---H      feat/rerank   (Asha)
#                /
#       A---B---C---D---E        main          (HEAD -> main)
#
#   A Add retriever skeleton            D Raise top_k to 10                 (config.yaml)
#   B Add BM25 scoring                  E Add request timeout               (config.yaml)
#   C Add top_k setting                 F Add reranker module               (rerank.py)
#                                       G Call the reranker from the retriever   (retriever.py)
#                                       H Add rerank_top_n setting          (config.yaml)
#
# The commits were made in the order A B C F D G E H, so the two sides interleave by date.

rt_put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }
rt_commit() { tick; git add -A > /dev/null 2>&1 && git commit -q -m "$1" > /dev/null 2>&1; }
rt_sed() { sed -e "$1" "$2" > "$2.rt-new" && mv "$2.rt-new" "$2"; }

rt_handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

fx_retriever() {
  git init -q retriever && cd retriever || return 1
  rt_put retriever.py <<'EOF'
def retrieve(query, index):
    return index.search(query)
EOF
  rt_put config.yaml <<'EOF'
index: docs-v1
embedding_model: e5-small
log_level: info
EOF
  rt_commit "Add retriever skeleton"
  rt_put retriever.py <<'EOF'
def bm25(query, doc):
    return sum(doc.count(term) for term in query.split())


def retrieve(query, index):
    docs = index.search(query)
    return sorted(docs, key=lambda d: bm25(query, d), reverse=True)
EOF
  rt_commit "Add BM25 scoring"
  rt_sed 's/^log_level: info$/top_k: 5\
&/' config.yaml
  rt_commit "Add top_k setting"

  as asha
  git switch -q -c feat/rerank
  rt_put rerank.py <<'EOF'
def rerank(query, docs, top_n=3):
    return docs[:top_n]
EOF
  rt_commit "Add reranker module"

  as you
  git switch -q main
  rt_sed 's/^top_k: 5$/top_k: 10/' config.yaml
  rt_commit "Raise top_k to 10"

  as asha
  git switch -q feat/rerank
  rt_put retriever.py <<'EOF'
from rerank import rerank


def bm25(query, doc):
    return sum(doc.count(term) for term in query.split())


def retrieve(query, index):
    docs = index.search(query)
    ranked = sorted(docs, key=lambda d: bm25(query, d), reverse=True)
    return rerank(query, ranked)
EOF
  rt_commit "Call the reranker from the retriever"

  as you
  git switch -q main
  printf 'timeout_s: 5\n' >> config.yaml
  rt_commit "Add request timeout"

  as asha
  git switch -q feat/rerank
  rt_sed 's/^index: docs-v1$/&\
rerank_top_n: 3/' config.yaml
  rt_commit "Add rerank_top_n setting"

  as you
  git switch -q main
}

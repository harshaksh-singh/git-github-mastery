#!/usr/bin/env bash
# labs/ch09/fixtures/fixtures.sh
# Hidden setup shared by the Chapter 9 demos, the Module 9 lab replays and the hands-on setup scripts.
# Source it after lab-env.sh. Every fx_* function expects the current directory to be the sandbox
# ($LAB_DIR), builds its repository with the pinned lab clock, and leaves you inside that repository.
# Because the replay and the hands-on setup call the same function, both start from identical commit IDs.
#
# The example project is "ragkit", a small retrieval-augmented answering service:
#   app/      request path (retriever, reranker)      eval/   offline metrics
#   ingest/   document loading and chunking            config/ model settings

# put <path>: write standard input to <path>, creating parent directories.
put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }

# commit_all "<message>": stage everything and commit it without output; advances the lab clock.
commit_all() { tick; git add -A > /dev/null 2>&1 && git commit -q -m "$1" > /dev/null 2>&1; }

# handson_ready <repo-dir>...: closing message of a setup-*.sh script.
handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

# ---------------------------------------------------------------- base project
fx_ragkit_init() {
  git init -q ragkit && cd ragkit || return 1
  put app/retriever.py <<'EOF'
TOP_K = 5

def retrieve(query):
    return search(query, TOP_K)
EOF
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 512
EOF
  commit_all "Add retriever and model config"
}

# ---------------------------------------------------------------- feat/rerank, no conflict with main
# main:        A---F---G          F "Add README", G "Upgrade model to small-v2"
# feat/rerank:  \--B---C---D      three commits that touch other lines than F and G
fx_rerank_clean() {
  fx_ragkit_init || return 1
  git switch -q -c feat/rerank
  put app/rerank.py <<'EOF'
def rerank(docs):
    return sorted(docs, key=score, reverse=True)
EOF
  commit_all "Add reranker skeleton"
  put app/retriever.py <<'EOF'
TOP_K = 5

def retrieve(query):
    return rerank(search(query, TOP_K))
EOF
  commit_all "Call reranker from retriever"
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 512
rerank: true
EOF
  commit_all "Enable reranking in config"
  git switch -q main
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  put config/model.yaml <<'EOF'
model: small-v2
temperature: 0.2
max_tokens: 512
EOF
  commit_all "Upgrade model to small-v2"
}

# ---------------------------------------------------------------- feat/rerank, one commit conflicts with main
# main changes TOP_K to 8; the second commit of feat/rerank changes the same line to 20.
fx_rerank_conflict() {
  fx_ragkit_init || return 1
  git switch -q -c feat/rerank
  put app/rerank.py <<'EOF'
def rerank(docs):
    return sorted(docs, key=score, reverse=True)
EOF
  commit_all "Add reranker skeleton"
  put app/retriever.py <<'EOF'
TOP_K = 20

def retrieve(query):
    return rerank(search(query, TOP_K))
EOF
  commit_all "Fetch 20 candidates for the reranker"
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 512
rerank: true
EOF
  commit_all "Enable reranking in config"
  git switch -q main
  put app/retriever.py <<'EOF'
TOP_K = 8

def retrieve(query):
    return search(query, TOP_K)
EOF
  commit_all "Raise TOP_K to 8 after recall regression"
  git switch -q feat/rerank
}

# ---------------------------------------------------------------- feat/rerank for the range-diff demo
# Like fx_rerank_conflict, but the conflicting commit is larger, so that "git range-diff" can still
# pair the old and the new version of it after the conflict has been resolved.
fx_rerank_review() {
  fx_ragkit_init || return 1
  git switch -q -c feat/rerank
  put app/rerank.py <<'EOF'
def rerank(docs):
    return sorted(docs, key=score, reverse=True)
EOF
  commit_all "Add reranker skeleton"
  put app/retriever.py <<'EOF'
TOP_K = 20

def retrieve(query):
    return rerank(search(query, TOP_K))
EOF
  put app/rerank.py <<'EOF'
MIN_SCORE = 0.35

def rerank(docs):
    ranked = sorted(docs, key=score, reverse=True)
    return [d for d in ranked if score(d) >= MIN_SCORE]
EOF
  commit_all "Fetch 20 candidates and filter weak matches"
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 512
rerank: true
EOF
  commit_all "Enable reranking in config"
  git switch -q main
  put app/retriever.py <<'EOF'
TOP_K = 8

def retrieve(query):
    return search(query, TOP_K)
EOF
  commit_all "Raise TOP_K to 8 after recall regression"
  git switch -q feat/rerank
}

# ---------------------------------------------------------------- lint script used by "exec" demos
_fx_check_script() {
  put scripts/check.sh <<'EOF'
#!/bin/sh
# Project lint: fail when a debug print is left in the code.
if grep -rn 'print("DEBUG' app eval 2>/dev/null; then
  echo "check failed: remove the debug print"
  exit 1
fi
echo "check passed"
EOF
  commit_all "Add lint script"
}

# ---------------------------------------------------------------- feat/metrics, six messy commits
fx_metrics_messy() {
  fx_ragkit_init || return 1
  _fx_check_script
  git switch -q -c feat/metrics
  put eval/metrics.py <<'EOF'
def exact_match(pred, gold):
    return pred == gold
EOF
  commit_all "Add exact_match metric"
  put eval/metrics.py <<'EOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
EOF
  commit_all "wip"
  put tests/test_metrics.py <<'EOF'
from eval.metrics import exact_match

def test_exact_match():
    assert exact_match("Paris", "Paris")
EOF
  commit_all "add test"
  put eval/metrics.py <<'EOF'
def exact_match(pred, gold):
    print("DEBUG", pred, gold)
    return pred.strip() == gold.strip()
EOF
  commit_all "debug print"
  put eval/f1.py <<'EOF'
def f1(pred, gold):
    p, g = set(pred.split()), set(gold.split())
    overlap = len(p & g)
    return 2 * overlap / (len(p) + len(g)) if overlap else 0.0
EOF
  commit_all "Add token-level F1 metirc"
  put tests/test_metrics.py <<'EOF'
from eval.metrics import exact_match

def test_exact_match():
    assert exact_match("Paris", "Paris")
    assert exact_match(" Paris ", "Paris")
EOF
  commit_all "fix test"
}

# ---------------------------------------------------------------- feat/metrics, a debug line left inside a good commit
fx_metrics_leftover() {
  fx_ragkit_init || return 1
  _fx_check_script
  git switch -q -c feat/metrics
  put eval/metrics.py <<'EOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
EOF
  commit_all "Add exact_match metric"
  put eval/f1.py <<'EOF'
def f1(pred, gold):
    p, g = set(pred.split()), set(gold.split())
    print("DEBUG", p, g)
    overlap = len(p & g)
    return 2 * overlap / (len(p) + len(g)) if overlap else 0.0
EOF
  commit_all "Add token-level F1 metric"
  put tests/test_metrics.py <<'EOF'
from eval.metrics import exact_match
from eval.f1 import f1

def test_exact_match():
    assert exact_match(" Paris ", "Paris")

def test_f1_identical():
    assert f1("the cat", "the cat") == 1.0
EOF
  commit_all "Test both metrics"
}

# ---------------------------------------------------------------- feat/metrics, one commit mixes two concerns
fx_metrics_mixed() {
  fx_ragkit_init || return 1
  git switch -q -c feat/metrics
  put eval/metrics.py <<'EOF'
def exact_match(pred, gold):
    return pred.strip() == gold.strip()
EOF
  commit_all "Add exact_match metric"
  put eval/f1.py <<'EOF'
def f1(pred, gold):
    p, g = set(pred.split()), set(gold.split())
    overlap = len(p & g)
    return 2 * overlap / (len(p) + len(g)) if overlap else 0.0
EOF
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 1024
EOF
  commit_all "Add F1 metric and raise max_tokens"
  put tests/test_metrics.py <<'EOF'
from eval.metrics import exact_match
from eval.f1 import f1

def test_exact_match():
    assert exact_match(" Paris ", "Paris")

def test_f1_identical():
    assert f1("the cat", "the cat") == 1.0
EOF
  commit_all "Test both metrics"
}

# ---------------------------------------------------------------- feat/metrics, three clean commits awaiting review fixes
fx_metrics_clean() {
  fx_ragkit_init || return 1
  git switch -q -c feat/metrics
  put eval/metrics.py <<'EOF'
def exact_match(pred, gold):
    return pred == gold
EOF
  commit_all "Add exact_match metric"
  put tests/test_metrics.py <<'EOF'
from eval.metrics import exact_match

def test_exact_match():
    assert exact_match("Paris", "Paris")
EOF
  commit_all "Test exact_match"
  put eval/f1.py <<'EOF'
def f1(pred, gold):
    p, g = set(pred.split()), set(gold.split())
    overlap = len(p & g)
    return 2 * overlap / (len(p) + len(g)) if overlap else 0.0
EOF
  put tests/test_metrics.py <<'EOF'
from eval.metrics import exact_match
from eval.f1 import f1

def test_exact_match():
    assert exact_match("Paris", "Paris")

def test_f1_identical():
    assert f1("the cat", "the cat") == 1.0
EOF
  commit_all "Add token-level F1 metric"
}

# ---------------------------------------------------------------- ingest stack: three branches, one on top of the other
# main:                 A---R                    R "Add README"
# feat/ingest-loader:    \--L1--L2
# feat/ingest-cleaner:            \--C1
# feat/ingest-chunker:                \--K1--K2
_fx_ingest_loader() {
  git switch -q -c feat/ingest-loader
  put ingest/loader.py <<'EOF'
def load(path):
    return open(path).read()
EOF
  commit_all "Add document loader"
  put ingest/loader.py <<'EOF'
def load(path):
    with open(path) as f:
        return f.read()
EOF
  commit_all "Close files after loading"
}

fx_ingest_stack() {
  fx_ragkit_init || return 1
  _fx_ingest_loader
  git switch -q -c feat/ingest-cleaner
  put ingest/cleaner.py <<'EOF'
def clean(text):
    return " ".join(text.split())
EOF
  commit_all "Add text cleaner"
  git switch -q -c feat/ingest-chunker
  put ingest/chunker.py <<'EOF'
def chunk(text):
    return [text[i:i + 800] for i in range(0, len(text), 800)]
EOF
  commit_all "Add chunker"
  put ingest/chunker.py <<'EOF'
def chunk(text, size=800):
    return [text[i:i + size] for i in range(0, len(text), size)]
EOF
  commit_all "Make chunk size configurable"
  git switch -q main
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  git switch -q feat/ingest-chunker
}

# ---------------------------------------------------------------- stacked branch whose parent was squash-merged
# feat/ingest-loader (L1, L2) was merged into main as ONE new commit S, with a review change
# (an explicit encoding). feat/ingest-cleaner still sits on top of the old L2.
fx_ingest_squashed() {
  fx_ragkit_init || return 1
  _fx_ingest_loader
  git switch -q -c feat/ingest-cleaner
  put ingest/cleaner.py <<'EOF'
def clean(text):
    return text.strip()
EOF
  commit_all "Add text cleaner"
  put ingest/cleaner.py <<'EOF'
def clean(text):
    return " ".join(text.split())
EOF
  commit_all "Collapse repeated whitespace"
  git switch -q main
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  git merge -q --squash feat/ingest-loader > /dev/null 2>&1
  put ingest/loader.py <<'EOF'
def load(path):
    with open(path, encoding="utf-8") as f:
        return f.read()
EOF
  commit_all "Add document loader (#41)"
  git switch -q feat/ingest-cleaner
}

# ---------------------------------------------------------------- a fix cut from main that must ship from release/1.4
fx_fix_on_main() {
  fx_ragkit_init || return 1
  git branch release/1.4
  put app/async_client.py <<'EOF'
async def search_async(query, k):
    return await backend.search(query, k)
EOF
  commit_all "Start 2.0: add async search client"
  put config/model.yaml <<'EOF'
model: large-v3
temperature: 0.2
max_tokens: 512
EOF
  commit_all "Switch default model to large-v3 for 2.0"
  git switch -q -c fix/timeout
  put app/retriever.py <<'EOF'
TOP_K = 5
TIMEOUT_S = 3

def retrieve(query):
    return search(query, TOP_K, timeout=TIMEOUT_S)
EOF
  commit_all "Add a timeout to search calls"
  put app/retriever.py <<'EOF'
TOP_K = 5
TIMEOUT_S = 3

def retrieve(query):
    try:
        return search(query, TOP_K, timeout=TIMEOUT_S)
    except TimeoutError:
        return []
EOF
  commit_all "Return no documents when search times out"
}

# ---------------------------------------------------------------- a fix branch cut from a colleague's experiment (Lab 9.2)
# main:                A---R---L                 L "Add licence", made after the experiment started
# exp/hybrid-search:        \--X1--X2            Asha's unmerged experiment
# fix/empty-query:                  \--F1--F2    your fix, cut from the experiment by mistake
fx_wrong_base() {
  fx_ragkit_init || return 1
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  git switch -q -c exp/hybrid-search
  as asha
  put app/bm25.py <<'EOF'
def bm25_search(query, k):
    return keyword_index.top(query, k)
EOF
  commit_all "Experiment: BM25 fallback"
  put app/blend.py <<'EOF'
def blend(vector_hits, keyword_hits, alpha=0.7):
    return merge_scores(vector_hits, keyword_hits, alpha)
EOF
  commit_all "Experiment: blend BM25 and vector scores"
  as you
  git switch -q -c fix/empty-query
  put app/retriever.py <<'EOF'
TOP_K = 5

def retrieve(query):
    if not query.strip():
        return []
    return search(query, TOP_K)
EOF
  commit_all "Reject empty queries"
  put tests/test_retriever.py <<'EOF'
from app.retriever import retrieve

def test_empty_query_returns_nothing():
    assert retrieve("   ") == []
EOF
  commit_all "Test empty-query handling"
  git switch -q main
  put LICENSE <<'EOF'
Apache-2.0
EOF
  commit_all "Add licence"
  git switch -q fix/empty-query
}

# ---------------------------------------------------------------- feat/rerank with two experiment commits in the middle
fx_rerank_experiments() {
  fx_ragkit_init || return 1
  git switch -q -c feat/rerank
  put app/rerank.py <<'EOF'
def rerank(docs):
    return sorted(docs, key=score, reverse=True)
EOF
  commit_all "Add reranker skeleton"
  put app/cross_encoder.py <<'EOF'
def cross_score(query, doc):
    return model.predict([(query, doc)])[0]
EOF
  commit_all "Experiment: cross-encoder scoring"
  put app/cross_encoder.py <<'EOF'
CACHE = {}

def cross_score(query, doc):
    key = (query, doc)
    if key not in CACHE:
        CACHE[key] = model.predict([key])[0]
    return CACHE[key]
EOF
  commit_all "Experiment: cache cross-encoder scores"
  put app/retriever.py <<'EOF'
TOP_K = 5

def retrieve(query):
    return rerank(search(query, TOP_K))
EOF
  commit_all "Call reranker from retriever"
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 512
rerank: true
EOF
  commit_all "Enable reranking in config"
}

# ---------------------------------------------------------------- feat/ingest containing a merge of a side branch
fx_ingest_with_merge() {
  fx_ragkit_init || return 1
  git switch -q -c feat/ingest
  put ingest/loader.py <<'EOF'
def load(path):
    with open(path) as f:
        return f.read()
EOF
  commit_all "Add document loader"
  git switch -q -c feat/ingest-cleaner
  put ingest/cleaner.py <<'EOF'
def clean(text):
    return " ".join(text.split())
EOF
  commit_all "Add text cleaner"
  git switch -q feat/ingest
  put ingest/chunker.py <<'EOF'
def chunk(text, size=800):
    return [text[i:i + size] for i in range(0, len(text), size)]
EOF
  commit_all "Add chunker"
  tick
  git merge -q --no-ff -m "Merge branch 'feat/ingest-cleaner' into feat/ingest" feat/ingest-cleaner > /dev/null 2>&1
  put ingest/pipeline.py <<'EOF'
def run(path):
    return chunk(clean(load(path)))
EOF
  commit_all "Wire loader, cleaner and chunker together"
  git switch -q main
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  git switch -q feat/ingest
}

# ---------------------------------------------------------------- feat/ingest whose middle commit is already on main
# $1 = "picked":   main received the middle commit by cherry-pick (same patch, new ID)
# $1 = "squashed": main received the first two commits as one squashed commit (different patch)
fx_ingest_partly_upstream() {
  fx_ragkit_init || return 1
  put config/settings.yaml <<'EOF'
download_retries: 0
EOF
  commit_all "Add ingest settings"
  git switch -q -c feat/ingest
  put ingest/loader.py <<'EOF'
def load(path):
    with open(path) as f:
        return f.read()
EOF
  commit_all "Add document loader"
  put config/settings.yaml <<'EOF'
download_retries: 3
EOF
  commit_all "Retry flaky downloads three times"
  put ingest/chunker.py <<'EOF'
def chunk(text, size=800):
    return [text[i:i + size] for i in range(0, len(text), size)]
EOF
  commit_all "Add chunker"
  git switch -q main
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  tick
  case "$1" in
    picked)   git cherry-pick feat/ingest~1 > /dev/null 2>&1 ;;
    squashed) git merge -q --squash feat/ingest~1 > /dev/null 2>&1
              git commit -q -m "Add document loader with download retries (#52)" > /dev/null 2>&1 ;;
  esac
  git switch -q feat/ingest
}

# ---------------------------------------------------------------- a bare "server" and two clones
# Layout inside the sandbox:   server.git   you/   asha/
# Remote URLs are relative (../server.git), so no machine-specific path ends up in a commit message.
_fx_clone() {      # _fx_clone <dir> [<user name> <user email>]
  git clone -q server.git "$1" > /dev/null 2>&1
  git -C "$1" remote set-url origin ../server.git
  if [ -n "${2:-}" ]; then
    git -C "$1" config set user.name "$2"
    git -C "$1" config set user.email "$3"
  fi
}

fx_server_init() {
  git init -q --bare server.git
  _fx_clone you
  cd you || return 1
  put app/retriever.py <<'EOF'
TOP_K = 5

def retrieve(query):
    return search(query, TOP_K)
EOF
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 512
EOF
  commit_all "Add retriever and model config"
  git push -q -u origin main > /dev/null 2>&1
  cd ..
}

# Shared branch feat/ingest: you pushed two commits, Asha has one more commit that she has not pushed,
# and main moved on. You are left in you/ on feat/ingest.
fx_shared_branch() {
  fx_server_init || return 1
  cd you || return 1
  git switch -q -c feat/ingest
  put ingest/loader.py <<'EOF'
def load(path):
    with open(path) as f:
        return f.read()
EOF
  commit_all "Add document loader"
  put ingest/cleaner.py <<'EOF'
def clean(text):
    return " ".join(text.split())
EOF
  commit_all "Add text cleaner"
  git push -q -u origin feat/ingest > /dev/null 2>&1
  cd ..
  _fx_clone asha "Asha Rao" asha@example.com
  cd asha || return 1
  as asha
  git switch -q feat/ingest > /dev/null 2>&1
  put ingest/chunker.py <<'EOF'
def chunk(text, size=800):
    return [text[i:i + size] for i in range(0, len(text), size)]
EOF
  commit_all "Add chunker"
  [ "${1:-}" = "asha-pushed" ] && git push -q > /dev/null 2>&1
  cd ../you || return 1
  as you
  git switch -q main
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  git push -q origin main > /dev/null 2>&1
  git switch -q feat/ingest
  as config
}

# Diverged main: you have one unpushed commit on main, Asha pushed one commit to main.
fx_diverged_main() {
  fx_server_init || return 1
  _fx_clone asha "Asha Rao" asha@example.com
  cd asha || return 1
  as asha
  put README.md <<'EOF'
# ragkit

Retrieval-augmented answering service.
EOF
  commit_all "Add README"
  git push -q > /dev/null 2>&1
  cd ../you || return 1
  as you
  put config/model.yaml <<'EOF'
model: small-v1
temperature: 0.2
max_tokens: 1024
EOF
  commit_all "Raise max_tokens to 1024 for long answers"
  as config
}

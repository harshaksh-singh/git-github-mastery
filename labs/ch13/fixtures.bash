# labs/ch13/fixtures.bash — starting states for the Module 12 disaster labs (Lab 12.1 to 12.12)
# and for the demos of Chapter 13.
#
# This file is sourced, never run. Each function builds one lab's starting state inside the
# current sandbox ($LAB_DIR) and returns with the current directory set back to $LAB_DIR.
# The hands-on setup script (setup-12-k-*.sh) and the replay script (lab-12-k-*.sh) of a lab
# call the same function at the same point of the lab clock, so every commit that the fixture
# creates has the same ID in your hands-on sandbox as in the book.

# Commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m '$1'"; }

# Copy a repository and refresh the cached stat data that the copy invalidated.
_fx_copy() {   # _fx_copy <source-dir> <target-dir>
  cp -R "$1" "$2" && git -C "$2" status > /dev/null 2>&1
}

# Clone the bare server.git of the sandbox and store the URL as a relative path, so that
# transcripts print "../server.git" in the replay and in the hands-on sandbox alike.
_fx_clone() {  # _fx_clone <directory> [<person>]
  quiet "git clone server.git $1"
  quiet "git -C $1 remote set-url origin ../server.git"
  case "${2:-}" in
    asha) quiet "git -C $1 config set user.name 'Asha Rao' && git -C $1 config set user.email asha@example.com" ;;
    ravi) quiet "git -C $1 config set user.name 'Ravi Menon' && git -C $1 config set user.email ravi@example.com" ;;
  esac
}

# ------------------------------------------------------------------ Lab 12.1
# retriever: six commits on main, the last one a throwaway. retriever-incident: the same
# repository after "git reset --hard HEAD~3" and one new commit on the shortened branch.
fx_12_1() {
  quiet 'git init retriever'
  cd retriever || return 1
  printf 'def search(query, k):\n    return bm25.top(query, k)\n' > retriever.py
  _c 'Add BM25 retriever'
  printf 'top_k: 5\n' > config.yaml
  _c 'Add retrieval config'
  printf 'def recall_at_k(hits, gold, k):\n    return len(set(hits[:k]) & set(gold)) / len(gold)\n' > eval.py
  _c 'Add recall@k evaluation'
  printf 'top_k: 10\n' > config.yaml
  _c 'Raise top_k to 10'
  printf 'def search(query, k):\n    return bm25.top(normalise(query), k)\n' > retriever.py
  _c 'Normalise queries before search'
  printf 'def search(query, k):\n    print("DEBUG", query)\n    return bm25.top(normalise(query), k)\n' > retriever.py
  _c 'WIP: debug prints'
  cd "$LAB_DIR" || return 1
  _fx_copy retriever retriever-incident
  cd retriever-incident || return 1
  quiet 'git reset --hard HEAD~3'
  printf '\ndef mrr(hits, gold):\n    return next((1 / (i + 1) for i, h in enumerate(hits) if h in gold), 0)\n' >> eval.py
  _c 'Add MRR metric'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.2
# server.git and your clone "reranker". Locally: main and the unmerged branch
# feature/cross-encoder (three commits). On the server a teammate's branch exp/hard-negatives
# existed, you fetched it (never checked it out), and then she deleted it on the server.
# Her clone is gone: the only copy of those two commits is in your object database.
fx_12_2() {
  quiet 'git init --bare server.git'
  _fx_clone reranker
  cd reranker || return 1
  printf 'def run(query):\n    return generate(retrieve(query))\n' > pipeline.py
  _c 'Add retrieval pipeline'
  printf 'retrieve_top_k: 100\n' > pipeline.yaml
  _c 'Add pipeline config'
  quiet 'git push -u origin main'
  cd "$LAB_DIR" || return 1
  _fx_clone asha asha
  cd asha || return 1
  as asha
  quiet 'git switch -c exp/hard-negatives'
  printf 'def mine(clicks):\n    return [c.doc for c in clicks if c.rank > 10 and not c.clicked]\n' > negatives.py
  _c 'Mine hard negatives from click logs'
  printf 'def mine(clicks):\n    return sorted({c.doc for c in clicks if c.rank > 10 and not c.clicked})\n' > negatives.py
  _c 'Deduplicate mined negatives'
  quiet 'git push -u origin exp/hard-negatives'
  as you
  cd "$LAB_DIR/reranker" || return 1
  quiet 'git fetch'
  quiet 'git switch -c feature/cross-encoder'
  printf 'def rerank(query, docs):\n    return sorted(docs, key=lambda d: cross_encoder(query, d), reverse=True)\n' > rerank.py
  _c 'Add cross-encoder reranker'
  printf 'retrieve_top_k: 100\nrerank_top_n: 50\n' > pipeline.yaml
  _c 'Rerank the top 50 candidates'
  printf 'def rerank(query, docs):\n    return sorted(docs, key=lambda d: cached_score(query, d), reverse=True)\n' > rerank.py
  _c 'Cache reranker scores'
  quiet 'git switch main'
  printf 'Stages: retrieve, rerank, generate.\n' > README.md
  _c 'Document the pipeline stages'
  cd "$LAB_DIR/asha" || return 1
  as asha
  quiet 'git switch main && git push origin --delete exp/hard-negatives'
  as you
  cd "$LAB_DIR" || return 1
  rm -rf asha
}

# ------------------------------------------------------------------ Lab 12.3
# embedder: feature/batching had four commits. A careless interactive rebase deleted the
# second line of the todo list, which dropped "Add request timeout". One more commit was made
# afterwards, so the branch cannot be moved back without losing new work.
fx_12_3() {
  quiet 'git init embedder'
  cd embedder || return 1
  printf 'def embed(texts):\n    return [call_api(t) for t in texts]\n' > client.py
  _c 'Add embedding client'
  printf 'model: embed-small-v2\n' > client.yaml
  _c 'Add client config'
  quiet 'git switch -c feature/batching'
  printf 'def embed(texts, batch_size=32):\n    return [v for b in batches(texts, batch_size) for v in call_api(b)]\n' > client.py
  _c 'Batch embedding requests'
  printf 'model: embed-small-v2\ntimeout_s: 10\n' > client.yaml
  _c 'Add request timeout'
  printf '@retry(on=RateLimited, attempts=5)\ndef embed(texts, batch_size=32):\n    return [v for b in batches(texts, batch_size) for v in call_api(b)]\n' > client.py
  _c 'Retry on rate limit'
  printf '@retry(on=RateLimited, attempts=5)\ndef embed(texts, batch_size=32):\n    log.info("batches of %%d", batch_size)\n    return [v for b in batches(texts, batch_size) for v in call_api(b)]\n' > client.py
  _c 'Log batch sizes'
  quiet "GIT_SEQUENCE_EDITOR='sed -i.bak -e 2d' git rebase -i main"
  printf 'Embedding client. Requests are sent in batchs of 32.\n' > README.md
  _c 'Document batching in the README'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.4
# evalharness: hotfix/judge-timeout was cut from release/1.4 and then rebased onto main by
# habit. A third commit was added after the rebase. evalharness-incident is a copy.
fx_12_4() {
  quiet 'git init evalharness'
  cd evalharness || return 1
  printf 'def run(cases):\n    return [judge(c) for c in cases]\n' > runner.py
  _c 'Add eval runner'
  printf 'def judge(case):\n    return llm(PROMPT, case)\n' > judge.py
  _c 'Add judge prompt'
  quiet 'git branch release/1.4'
  printf 'def judge(case):\n    return llm(PROMPT, case, response_format="json")\n' > judge.py
  _c 'Switch judge to JSON mode'
  printf 'def faithfulness(answer, context):\n    return judge({"answer": answer, "context": context})\n' > metrics.py
  _c 'Add faithfulness metric'
  quiet 'git switch release/1.4'
  printf 'judge-model==2026.06\n' > requirements.txt
  _c 'Pin judge model for 1.4'
  quiet 'git switch -c hotfix/judge-timeout'
  printf 'def run(cases):\n    return [judge(c, timeout_s=30) for c in cases]\n' > runner.py
  _c 'Add judge timeout'
  printf 'def run(cases):\n    return [with_retry(judge, c, timeout_s=30) for c in cases]\n' > runner.py
  _c 'Retry judge on timeout'
  quiet 'git rebase main'
  printf 'def run(cases):\n    return [timed(with_retry, judge, c, timeout_s=30) for c in cases]\n' > runner.py
  _c 'Log judge latency'
  cd "$LAB_DIR" || return 1
  _fx_copy evalharness evalharness-incident
}

# ------------------------------------------------------------------ Lab 12.5
# promptstore: main, the finished branch feature/citations and the unfinished experiment
# exp/few-shot (three commits). promptstore-incident: exp/few-shot has already been merged
# into main by mistake, as a fast-forward.
fx_12_5() {
  quiet 'git init promptstore'
  cd promptstore || return 1
  printf 'You answer questions about our product documentation.\nIf the answer is not in the context, say that you do not know.\n' > system.txt
  _c 'Add system prompt'
  printf 'def load(name):\n    return open(name + ".txt").read()\n' > loader.py
  _c 'Add prompt loader'
  quiet 'git switch -c feature/citations'
  printf 'You answer questions about our product documentation.\nIf the answer is not in the context, say that you do not know.\nCite the source document for every claim.\n' > system.txt
  _c 'Require citations in answers'
  quiet 'git switch -c exp/few-shot main'
  printf 'Q: How do I rotate an API key?\nA: Open Settings, then Keys, then Rotate.\n' > examples.txt
  _c 'Try few-shot examples'
  printf 'Q: How do I rotate an API key?\nA: Open Settings, then Keys, then Rotate. The old key stays valid for one hour.\nQ: What is the rate limit?\nA: 60 requests per minute for each key.\n' > examples.txt
  _c 'WIP: longer examples'
  printf 'You answer questions about our product documentation.\n' > system.txt
  _c 'WIP: drop the refusal rule'
  quiet 'git switch main'
  cd "$LAB_DIR" || return 1
  _fx_copy promptstore promptstore-incident
  cd promptstore-incident || return 1
  quiet 'git merge exp/few-shot'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.6
# server.git and your clone "ingest". The branch feature/pdf-tables exists, but the last two
# commits were made on main by mistake and are not pushed. ingest-incident is a copy.
fx_12_6() {
  quiet 'git init --bare server.git'
  _fx_clone ingest
  cd ingest || return 1
  printf 'def load(path):\n    return parse(open(path, "rb").read())\n' > loader.py
  _c 'Add document loader'
  printf 'def chunk(text, size=800):\n    return [text[i:i + size] for i in range(0, len(text), size)]\n' > chunker.py
  _c 'Add chunker'
  quiet 'git push -u origin main'
  quiet 'git switch -c feature/pdf-tables'
  printf 'def tables(page):\n    return [to_rows(t) for t in page.find_tables()]\n' > tables.py
  _c 'Parse PDF tables'
  quiet 'git switch main'
  printf 'def chunk(text, size=800):\n    return [text[i:i + size] for i in range(0, len(text), size)]\n\ndef chunk_rows(rows, size=20):\n    return [rows[i:i + size] for i in range(0, len(rows), size)]\n' > chunker.py
  _c 'Keep table rows together when chunking'
  mkdir -p fixtures
  printf '{"rows": [["region", "latency_ms"], ["ap-south-1", "41"]]}\n' > fixtures/table.json
  _c 'Add a table fixture for tests'
  cd "$LAB_DIR" || return 1
  _fx_copy ingest ingest-incident
}

# ------------------------------------------------------------------ Lab 12.7
# modelserver: two sessions of work were done in detached HEAD and left behind. Session A:
# two hotfix commits on top of the tag v1.2.0. Session B: one experiment on an older commit.
# No branch and no tag points at either line.
fx_12_7() {
  quiet 'git init modelserver'
  cd modelserver || return 1
  printf 'def generate(req):\n    return model.complete(req.prompt, max_tokens=req.max_tokens)\n' > server.py
  _c 'Add inference endpoint'
  printf 'max_tokens: 8192\n' > limits.yaml
  _c 'Add request limits'
  quiet 'git tag v1.2.0'
  printf 'def stream(req):\n    yield from model.stream(req.prompt)\n' > stream.py
  _c 'Add streaming endpoint'
  quiet 'git checkout v1.2.0'
  printf 'def validate(req):\n    if req.max_tokens > 4096:\n        raise TooLarge()\n' > validate.py
  _c 'Hotfix: cap max_tokens at 4096'
  printf 'def validate(req):\n    if req.max_tokens > 4096:\n        raise TooLarge()\n    if not req.prompt.strip():\n        raise EmptyPrompt()\n' > validate.py
  _c 'Hotfix: reject empty prompts'
  quiet 'git switch main'
  printf 'def observe(seconds):\n    LATENCY.observe(seconds)\n' > metrics.py
  _c 'Export latency metrics'
  quiet 'git checkout HEAD~1'
  printf 'response_cache: off\n' > cache.yaml
  _c 'Experiment: disable response cache'
  quiet 'git switch main'
  printf 'Endpoints: /generate and /stream.\n' > README.md
  _c 'Document the endpoints'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.8
# finetune: uncommitted work in three states (staged twice, staged then edited, untracked).
# finetune-incident: a clean working tree and two stash entries.
fx_12_8() {
  quiet 'git init finetune'
  cd finetune || return 1
  printf 'def train(cfg):\n    return Trainer(cfg).fit()\n' > train.py
  _c 'Add training script'
  printf 'lr: 3e-5\nepochs: 3\n' > train.yaml
  _c 'Add training config'
  cd "$LAB_DIR" || return 1
  _fx_copy finetune finetune-incident
  cd finetune || return 1
  printf 'lr: [1e-5, 3e-5]\n' > sweep.yaml
  quiet 'git add sweep.yaml'
  printf 'lr: [1e-5, 3e-5]\nwarmup_ratio: [0.0, 0.1]\n' > sweep.yaml
  quiet 'git add sweep.yaml'
  printf 'lr: 3e-5\nepochs: 5\n' > train.yaml
  quiet 'git add train.yaml'
  printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' > train.yaml
  printf 'Sweep plan: 2 x 2 grid, 3 seeds each.\n' > notes.md
  cd "$LAB_DIR/finetune-incident" || return 1
  printf 'lr: 3e-5\nepochs: 3\ngrad_clip: 1.0\n' > train.yaml
  quiet 'git stash push'
  printf 'lr: 3e-5\nepochs: 3\nlora_rank: 16\n' > train.yaml
  quiet 'git stash push -m "lora: rank 16 trial"'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.9
# apigw: main has a bug fix followed by a feature that arrived through a fast-forward merge
# (which left ORIG_HEAD behind). You are on release/2.1, which has one commit of its own.
# apigw-incident: the feature has already been cherry-picked onto release/2.1 by mistake.
fx_12_9() {
  quiet 'git init apigw'
  cd apigw || return 1
  printf 'def allow(tenant, now):\n    window = now // 60\n    return count(tenant, window) <= LIMIT\n' > limiter.py
  _c 'Add rate limiter'
  printf 'def route(req):\n    return handlers[req.path](req)\n' > router.py
  _c 'Add request router'
  quiet 'git branch release/2.1'
  printf 'def allow(tenant, now):\n    window = now // 60\n    return count(tenant, window) < LIMIT\n' > limiter.py
  _c 'Fix off-by-one in rate limit window'
  quiet 'git switch -c feature/quotas'
  printf 'def route(req):\n    check_quota(req.tenant)\n    return handlers[req.path](req)\n' > router.py
  printf 'default_quota: 100000\n' > quotas.yaml
  _c 'Add per-tenant quotas'
  quiet 'git switch main'
  quiet 'git merge feature/quotas'
  quiet 'git branch -d feature/quotas'
  quiet 'git switch release/2.1'
  printf 'httpx==0.28.1\n' > requirements.txt
  _c 'Pin dependencies for 2.1'
  cd "$LAB_DIR" || return 1
  _fx_copy apigw apigw-incident
  cd apigw-incident || return 1
  quiet 'git cherry-pick -x main'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.10
# server.git and your clone "docsearch". Two things are wrong with its remote-tracking refs:
# a helper script set origin/main to your local main by hand, and a crash left an empty file
# where origin/feature/hybrid-search should be. The server has one commit you have not seen.
fx_12_10() {
  quiet 'git init --bare server.git'
  _fx_clone docsearch
  cd docsearch || return 1
  printf 'def add(doc):\n    for term in tokenize(doc.text):\n        postings[term].append(doc.id)\n' > index.py
  _c 'Add inverted index'
  printf 'def parse(q):\n    return q.lower().split()\n' > query.py
  _c 'Add query parser'
  quiet 'git push -u origin main'
  quiet 'git switch -c feature/hybrid-search'
  printf 'def score(q, d, alpha=0.7):\n    return alpha * bm25(q, d) + (1 - alpha) * dense(q, d)\n' > hybrid.py
  _c 'Combine BM25 and dense scores'
  quiet 'git push -u origin feature/hybrid-search'
  quiet 'git switch main'
  cd "$LAB_DIR" || return 1
  _fx_clone asha asha
  cd asha || return 1
  as asha
  printf 'SYNONYMS = {"k8s": "kubernetes", "db": "database"}\n' > synonyms.py
  _c 'Add synonym expansion'
  quiet 'git push'
  as you
  cd "$LAB_DIR/docsearch" || return 1
  printf 'def parse(q):\n    return PHRASE.findall(q.lower())\n' > query.py
  _c 'Add phrase queries'
  printf 'def cached(q):\n    return CACHE.get(q)\n' > cache.py
  _c 'Add query cache'
  quiet 'git update-ref refs/remotes/origin/main HEAD'
  : > .git/refs/remotes/origin/feature/hybrid-search
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 12.11
# server.git with three clones: yours ("askdocs"), asha and ravi. Asha and you pushed one
# commit each. Ravi, whose clone was two commits behind, then pushed with --force. You have
# not fetched since. The directory "incident" holds a second, independent copy of the server
# and of your clone for the failure scenario.
fx_12_11() {
  quiet 'git init --bare server.git'
  _fx_clone askdocs
  cd askdocs || return 1
  printf 'def answer(question):\n    return generate(question, retrieve(question))\n' > app.py
  _c 'Add question answering endpoint'
  printf 'model: chat-large\ntop_k: 8\n' > settings.yaml
  _c 'Add settings'
  quiet 'git push -u origin main'
  cd "$LAB_DIR" || return 1
  _fx_clone asha asha
  _fx_clone ravi ravi
  cd asha || return 1
  as asha
  printf 'def cached_answer(question):\n    return CACHE.get(question) or answer(question)\n' > cache.py
  _c 'Add answer cache'
  quiet 'git push'
  as you
  cd "$LAB_DIR/askdocs" || return 1
  quiet 'git pull'
  printf 'def record(hit):\n    CACHE_HITS.inc() if hit else CACHE_MISSES.inc()\n' > cache_metrics.py
  _c 'Add cache metrics'
  quiet 'git push'
  cd "$LAB_DIR/ravi" || return 1
  as ravi
  printf 'llm_model: chat-large\nretrieval_top_k: 8\n' > settings.yaml
  _c 'Rename settings keys'
  quiet 'git push --force'
  as you
  cd "$LAB_DIR" || return 1
  mkdir incident
  cp -R server.git incident/server.git
  _fx_copy askdocs incident/askdocs
}

# ------------------------------------------------------------------ Lab 12.12
# featurestore: the commit "Add online store TTL" was removed from main with a hard reset, and
# a staged file was thrown away with it. featurestore-backup.bundle was written while that
# commit was still the tip of main. teammate is a clone made after the reset.
# featurestore-damaged is a copy for the failure scenario.
fx_12_12() {
  quiet 'git init featurestore'
  cd featurestore || return 1
  printf 'def get(entity, features):\n    return online.read(entity, features)\n' > store.py
  _c 'Add feature store client'
  printf 'user_clicks_7d: int\nuser_country: string\n' > schema.yaml
  _c 'Add feature schema'
  printf 'online_ttl_hours: 48\n' > ttl.yaml
  _c 'Add online store TTL'
  quiet 'git bundle create ../featurestore-backup.bundle --all'
  printf 'offline_path: s3://features/offline\n' > offline.yaml
  quiet 'git add offline.yaml'
  quiet 'git reset --hard HEAD~1'
  cd "$LAB_DIR" || return 1
  quiet 'git clone --no-local featurestore teammate'
  _fx_copy featurestore featurestore-damaged
}

# ------------------------------------------------------------------ Chapter demos
# searchsvc: three commits on main, used by the demos of sections 13.3 to 13.6.
fx_searchsvc() {
  quiet 'git init searchsvc'
  cd searchsvc || return 1
  printf 'top_k: 5\n' > retriever.yaml
  _c 'Add retriever config'
  printf 'def embed(texts):\n    return model.encode(texts)\n' > embed.py
  _c 'Add embedding client'
  printf 'top_k: 10\n' > retriever.yaml
  _c 'Raise top_k to 10'
  cd "$LAB_DIR" || return 1
}

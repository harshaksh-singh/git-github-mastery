# labs/ch11/fixtures.bash — starting states for the Module 8 labs (Lab 8.1 to Lab 8.7).
#
# This file is sourced, never run. Each function builds one lab's starting state inside the
# current sandbox ($LAB_DIR) and returns with the current directory set back to $LAB_DIR.
# The hands-on setup script (setup-08-k-*.sh) and the replay script (lab-08-k-*.sh) of a lab
# call the same function at the same point of the lab clock, so the commits that the fixture
# creates have the same IDs in your hands-on sandbox as in the book.

# Copy a repository and refresh the cached stat data that the copy invalidated.
_fx_copy() {   # _fx_copy <source-dir> <target-dir>
  cp -R "$1" "$2" && git -C "$2" status > /dev/null 2>&1
}

# ------------------------------------------------------------------ Lab 8.1
# promptlab: one file whose HEAD, index and working-tree versions all differ, plus one copy
# of the repository per reset mode.
fx_08_1() {
  quiet 'git init promptlab'
  cd promptlab || return 1
  quiet "printf 'v1: Answer briefly.\n' > prompt.txt && git add prompt.txt && git commit -m 'Add system prompt (v1)'"
  quiet "printf 'v2: Answer briefly. Cite the source.\n' > prompt.txt && git commit -am 'Require a citation (v2)'"
  quiet "printf 'v3: Answer briefly. Cite the source. Refuse when unsure.\n' > prompt.txt && git commit -am 'Refuse when unsure (v3)'"
  quiet "printf 'v4: staged, never committed\n' > prompt.txt && git add prompt.txt"
  quiet "printf 'v5: only in the working tree\n' > prompt.txt"
  cd "$LAB_DIR" || return 1
  local m
  for m in soft mixed hard keep merge; do
    _fx_copy promptlab "promptlab-$m"
  done
}

# ------------------------------------------------------------------ Lab 8.2
# server.git (bare, plays origin), your clone "you" and a teammate's clone "asha".
# origin/main holds three commits; the second one is the bad one. Both clones are up to date.
fx_08_2() {
  quiet 'git init --bare server.git'
  quiet 'git clone server.git you'
  cd you || return 1
  quiet "printf 'def fetch(keys):\n    return store.get(keys)\n' > client.py && printf 'batch_size: 128\ntimeout_s: 10\n' > store.yaml && git add . && git commit -m 'Add feature-store client'"
  quiet "printf 'batch_size: 512\ntimeout_s: 10\n' > store.yaml && git commit -am 'Raise batch size to 512'"
  quiet 'git push -u origin main'
  cd "$LAB_DIR" || return 1
  quiet 'git clone server.git asha'
  cd asha || return 1
  quiet 'git config set user.name "Asha Rao" && git config set user.email asha@example.com'
  as asha
  quiet "printf 'def fetch(keys):\n    return with_retry(store.get, keys)\n' > client.py && git commit -am 'Add retry to feature fetch'"
  quiet 'git push'
  as you
  cd "$LAB_DIR/you" || return 1
  quiet 'git pull'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 8.3
# pipeline: main and an unmerged branch feature/dedup (two commits). main has one commit of
# its own, so merging the branch creates a real merge commit.
fx_08_3() {
  quiet 'git init pipeline'
  cd pipeline || return 1
  quiet "printf 'def run(rows):\n    return [clean(r) for r in rows]\n' > pipeline.py && printf 'columns: [id, text, label]\n' > schema.yaml && git add . && git commit -m 'Add ingestion pipeline'"
  quiet 'git switch -c feature/dedup'
  quiet "printf 'def drop_near_duplicates(rows, threshold=0.80):\n    return [r for r in rows if not seen(r, threshold)]\n' > dedup.py && git add dedup.py && git commit -m 'Add near-duplicate filter'"
  quiet "printf 'from dedup import drop_near_duplicates\n\ndef run(rows):\n    return [clean(r) for r in drop_near_duplicates(rows)]\n' > pipeline.py && git commit -am 'Run the filter in the pipeline'"
  quiet 'git switch main'
  quiet "printf 'Input rows need the columns listed in schema.yaml.\n' > README.md && git add README.md && git commit -m 'Document the input schema'"
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 8.4
# evalsuite: rubric.yaml differs in HEAD, the index and the working tree; five copies for the
# five restore commands; evalsuite-bulk for the failure scenario; scorer for "restore -p".
fx_08_4() {
  quiet 'git init evalsuite'
  cd evalsuite || return 1
  quiet "printf 'pass_mark: 0.60\n' > rubric.yaml && git add rubric.yaml && git commit -m 'Add grading rubric'"
  quiet "printf 'pass_mark: 0.70\n' > rubric.yaml && printf 'You are a strict grader. Reply PASS or FAIL.\n' > judge.txt && git add . && git commit -m 'Add judge prompt, raise pass mark to 0.70'"
  quiet "printf 'pass_mark: 0.80\n' > rubric.yaml && printf '{\"id\": 1, \"input\": \"2+2\", \"expected\": \"4\"}\n' > cases.jsonl && git add . && git commit -m 'Add test cases, raise pass mark to 0.80'"
  cd "$LAB_DIR" || return 1
  _fx_copy evalsuite evalsuite-bulk
  quiet "printf 'You are a strict grader. Reply PASS or FAIL, then one sentence of reasoning.\n' > evalsuite-bulk/judge.txt"
  cd evalsuite || return 1
  quiet "printf 'pass_mark: 0.85\n' > rubric.yaml && git add rubric.yaml"
  quiet "printf 'pass_mark: 0.90\n' > rubric.yaml"
  cd "$LAB_DIR" || return 1
  local n
  for n in 1 2 3 4 5; do
    _fx_copy evalsuite "evalsuite-$n"
  done

  quiet 'git init scorer'
  cd scorer || return 1
  cat > score.py <<'PY'
import json


def load(path):
    with open(path) as f:
        return [json.loads(line) for line in f]


def normalize(text):
    return text.strip()


def exact_match(pred, gold):
    return normalize(pred) == normalize(gold)


def accuracy(rows):
    hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
    return hits / len(rows)


if __name__ == "__main__":
    print(accuracy(load("preds.jsonl")))
PY
  quiet "git add score.py && git commit -m 'Add exact-match scorer'"
  cat > score.py <<'PY'
import json


def load(path):
    print("DEBUG loading", path)
    with open(path) as f:
        return [json.loads(line) for line in f]


def normalize(text):
    return text.strip()


def exact_match(pred, gold):
    return normalize(pred) == normalize(gold)


def accuracy(rows):
    hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
    return hits / max(len(rows), 1)


if __name__ == "__main__":
    print(accuracy(load("preds.jsonl")))
PY
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 8.5
# trainer: a committed skeleton plus untracked files worth keeping (a notebook, results),
# untracked junk, ignored files (some regenerable, some not), and a nested repository.
fx_08_5() {
  quiet 'git init trainer'
  cd trainer || return 1
  quiet "printf 'import torch\n' > train.py && printf 'lr: 3e-4\n' > config.yaml && printf '__pycache__/\n*.log\n.env\ndata/cache/\ncheckpoints/\n' > .gitignore && printf 'TRACKING_TOKEN=\nDATA_ROOT=\n' > .env.example && git add . && git commit -m 'Add trainer skeleton'"
  quiet 'mkdir -p __pycache__ data/cache checkpoints notebooks results third_party/tokenizer'
  quiet "printf 'bytecode\n' > __pycache__/train.cpython-312.pyc && printf 'epoch 1 loss 0.42\n' > run.log && printf 'shard\n' > data/cache/shard-000.bin"
  quiet "printf 'TRACKING_TOKEN=local-dev-only\nDATA_ROOT=/data/corpus\n' > .env && printf 'weights after 500 steps\n' > checkpoints/step-500.pt"
  quiet "printf '{\"cells\": [\"loss curve analysis\"]}\n' > notebooks/analysis.ipynb && printf '{\"run\": 17, \"loss\": 0.42}\n' > results/run-17.json && printf 'tmp\n' > tmp_debug.txt"
  quiet "git init third_party/tokenizer && printf 'vendored tokenizer\n' > third_party/tokenizer/README.md"
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 8.6
# gateway: work in progress in three forms (staged, unstaged, untracked).
# gateway-incident: the same work already stashed, and a hotfix committed on the same line,
# so that "git stash pop" conflicts.
fx_08_6() {
  quiet 'git init gateway'
  cd gateway || return 1
  quiet "printf 'def route(request):\n    return upstream(request.model)\n' > router.py && printf 'requests_per_minute: 60\nburst: 10\n' > limits.yaml && git add . && git commit -m 'Add request router and rate limits'"
  quiet "printf 'def route(request):\n    return upstream(request.model, tenant=request.tenant)\n' > router.py && git add router.py"
  quiet "printf 'requests_per_minute: 120\nburst: 10\nper_tenant: true\n' > limits.yaml"
  quiet "printf 'Per-tenant limits: decide the default quota.\n' > notes.md"
  cd "$LAB_DIR" || return 1
  _fx_copy gateway gateway-incident
  cd gateway-incident || return 1
  quiet 'git stash push -u -m "wip: per-tenant limits"'
  quiet "printf 'requests_per_minute: 30\nburst: 10\n' > limits.yaml && git commit -am 'Hotfix: throttle to 30 rpm during the incident'"
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 8.7
# Six scenario cards, one repository each. Cards 1 to 3 have a bare repository next to them
# that plays origin, so "pushed" and "not pushed" can be checked instead of assumed.
fx_08_7() {
  # Card 1: three noisy local commits on top of what is pushed.
  quiet 'git init --bare card-1-origin.git && git clone card-1-origin.git card-1'
  cd card-1 || return 1
  quiet "printf 'def accuracy(pred, gold):\n    return sum(p == g for p, g in zip(pred, gold)) / len(gold)\n' > metrics.py && git add . && git commit -m 'Add metrics module' && git push -u origin main"
  quiet "printf 'def accuracy(pred, gold):\n    return sum(p == g for p, g in zip(pred, gold)) / len(gold)\n\ndef f1(tp, fp, fn):\n    return 2 * tp / (2 * tp + fp + fn)\n' > metrics.py && git commit -am 'wip'"
  quiet "printf 'from metrics import f1\n\ndef test_f1():\n    assert f1(1, 0, 0) == 1.0\n' > test_metrics.py && git add . && git commit -m 'wip 2'"
  quiet "printf 'from metrics import f1\n\ndef test_f1_perfect():\n    assert f1(1, 0, 0) == 1.0\n' > test_metrics.py && git commit -am 'fix typo'"
  cd "$LAB_DIR" || return 1

  # Card 2: a bad commit in the middle of pushed history.
  quiet 'git init --bare card-2-origin.git && git clone card-2-origin.git card-2'
  cd card-2 || return 1
  quiet "printf 'temperature: 0.2\ntop_p: 0.95\nstop: []\nmax_tokens: 512\n' > gen.yaml && git add . && git commit -m 'Add generation config'"
  quiet "printf 'temperature: 1.5\ntop_p: 0.95\nstop: []\nmax_tokens: 512\n' > gen.yaml && git commit -am 'Set temperature to 1.5'"
  quiet "printf 'temperature: 1.5\ntop_p: 0.95\nstop: []\nmax_tokens: 1024\n' > gen.yaml && git commit -am 'Raise max_tokens to 1024'"
  quiet 'git push -u origin main'
  cd "$LAB_DIR" || return 1

  # Card 3: a generated file slipped into the last, unpushed commit.
  quiet 'git init --bare card-3-origin.git && git clone card-3-origin.git card-3'
  cd card-3 || return 1
  quiet "printf 'def infer(batch):\n    return [model(x) for x in batch]\n' > infer.py && git add . && git commit -m 'Add batch inference script' && git push -u origin main"
  quiet "mkdir outputs && printf '{\"id\": 1, \"output\": \"...\"}\n{\"id\": 2, \"output\": \"...\"}\n' > outputs/predictions.jsonl"
  quiet "printf 'def infer(batch):\n    outputs = [model(x) for x in batch]\n    log_token_counts(outputs)\n    return outputs\n' > infer.py && git add . && git commit -m 'Log token counts per request'"
  cd "$LAB_DIR" || return 1

  # Card 4: one file has to go back to an old version; history must stay.
  quiet 'git init card-4'
  cd card-4 || return 1
  quiet "mkdir prompts && printf 'You are a helpful assistant.\n' > prompts/system.txt && printf 'tools: [search]\n' > tools.yaml && git add . && git commit -m 'Add system prompt and tool list'"
  quiet "printf 'You are a concise assistant. Answer in two sentences.\n' > prompts/system.txt && printf 'tools: [search, calculator]\n' > tools.yaml && git commit -am 'Tighten the system prompt, add calculator tool'"
  quiet "printf 'You are a concise assistant. Answer in two sentences. Refuse legal questions.\n' > prompts/system.txt && printf 'Prompts live in prompts/.\n' > README.md && git add . && git commit -m 'Add refusal rule and a README'"
  cd "$LAB_DIR" || return 1

  # Card 5: a local merge that should not have happened, plus an edit worth keeping.
  quiet 'git init card-5'
  cd card-5 || return 1
  quiet "printf 'def retrieve(query):\n    return index.search(embed(query))\n' > retrieve.py && printf 'Open questions for the retrieval service.\n' > notes.md && git add . && git commit -m 'Add retrieval service'"
  quiet 'git switch -c feature/cache'
  quiet "printf 'def cached_embed(text):\n    return disk_cache.get_or_compute(text, embed)\n' > cache.py && git add . && git commit -m 'Cache embeddings on disk'"
  quiet 'git switch main'
  quiet "printf 'embedding_model: text-embed-v3\n' > models.yaml && git add . && git commit -m 'Pin the embedding model version'"
  quiet 'git merge feature/cache'
  quiet "printf 'Open questions for the retrieval service.\n- Does the cache need a size limit?\n' > notes.md"
  cd "$LAB_DIR" || return 1

  # Card 6: staged, unstaged and untracked experiments, and an ignored .env to keep.
  quiet 'git init card-6'
  cd card-6 || return 1
  quiet "printf 'def step(state):\n    return plan(state)\n' > agent.py && printf 'TOOLS = [\"search\"]\n' > tools.py && printf '.env\n' > .gitignore && git add . && git commit -m 'Add agent loop'"
  quiet "printf 'def step(state):\n    return plan(reflect(state))\n' > agent.py && git add agent.py"
  quiet "printf 'TOOLS = [\"search\", \"shell\"]\n' > tools.py"
  quiet "mkdir scratch && printf 'trace 1\n' > scratch/trace.txt && printf 'debug\n' > debug.txt && printf 'MODEL_ENDPOINT=http://localhost:8080\n' > .env"
  cd "$LAB_DIR" || return 1
}

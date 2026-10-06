# labs/ch24/fixture-orbit.bash — the monorepo "orbit" used by Chapters 24 and 26 and by the
# labs of Module 18 and Labs 16.3 and 16.4.
#
# This file is sourced, never run. Demos, lab replays and hands-on setup scripts call the same
# functions at the same point of the lab clock, so every commit has the same ID in your hands-on
# sandbox as in the book.
#
#   orbit_build            builds ./orbit: one repository holding three services, two libraries,
#                          two pipelines, documentation and tooling of a small ML platform.
#                          94 commits on main, a feature branch of two commits that forked one commit
#                          before the tip of main, five annotated per-project tags.
#   orbit_pack             packs ./orbit once (one pack, a commit-graph, packed refs).
#   orbit_server           builds ./server/orbit.git, a bare copy that plays the part of the
#                          hosting server, and allows partial-clone filters on it.
#
# Automatic maintenance is switched off for every command of the fixture (GIT_CONFIG_COUNT), so
# that no background process repacks the repository while it is being built, and the one pack
# that orbit_server writes is computed on a single thread, so that it does not depend on the
# number of processor cores. Both are environment settings of the fixture only; they leave
# nothing in the repository configuration.

_orbit_env_on() {
  export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=maintenance.auto GIT_CONFIG_VALUE_0=false \
         GIT_CONFIG_KEY_1=pack.threads GIT_CONFIG_VALUE_1=1
}
_orbit_env_off() { unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1; }

# _oc <person> <message>: stage everything and commit as that person, with one tick of the clock.
_oc() {
  as "$1"
  tick
  git add -A > /dev/null 2>&1 && git commit -q -m "$2" > /dev/null 2>&1
}

orbit_build() {
  _orbit_env_on
  tick
  git init -q orbit || return 1
  cd orbit || return 1

  # ---------------------------------------------------------------- the tree
  mkdir -p .github services/gateway/tests services/ranker/tests services/ingest/tests \
           libs/schemas/v1 libs/tokenizer pipelines/training pipelines/eval \
           docs/runbooks tools/ci
  printf '# orbit\n\nOne repository for the search platform: three services, two shared libraries,\nthe training and evaluation pipelines, and their documentation.\n' > README.md
  printf '[project]\nname = "orbit"\nversion = "0.0.0"\nrequires-python = ">=3.11"\n' > pyproject.toml
  printf '__pycache__/\n.venv/\n*.pyc\nbuild/\n' > .gitignore
  cat > .github/CODEOWNERS <<'OWN'
# Last matching pattern wins.
*                      @orbit/platform
/services/gateway/     @orbit/gateway
/services/ranker/      @orbit/ranking
/services/ingest/      @orbit/data
/libs/                 @orbit/platform
/pipelines/            @orbit/ml
/docs/                 @orbit/docs
OWN
  _oc you 'Bootstrap the orbit monorepo'

  printf 'from libs.schemas.events import SearchRequest\n\n\ndef create_app():\n    return {"name": "gateway", "routes": []}\n' > services/gateway/app.py
  printf 'ROUTES = [\n    ("GET", "/healthz"),\n]\n' > services/gateway/routes.py
  printf 'timeout_ms: 800\nupstream: ranker\n' > services/gateway/config.yaml
  printf 'from services.gateway.routes import ROUTES\n\n\ndef test_healthz_is_routed():\n    assert ("GET", "/healthz") in ROUTES\n' > services/gateway/tests/test_routes.py
  _oc asha 'gateway: add the service skeleton'

  printf 'from libs.tokenizer.tokenizer import tokenize\n\n\ndef score(query, document):\n    q = set(tokenize(query))\n    d = set(tokenize(document))\n    return len(q & d) / max(len(q), 1)\n' > services/ranker/model.py
  printf 'FEATURES = [\n    "bm25",\n]\n' > services/ranker/features.py
  printf 'top_k: 10\nmodel: overlap-v1\n' > services/ranker/config.yaml
  printf 'from services.ranker.model import score\n\n\ndef test_identical_text_scores_one():\n    assert score("reset password", "reset password") == 1\n' > services/ranker/tests/test_model.py
  _oc ravi 'ranker: add the overlap scorer'

  printf 'from libs.schemas.events import DocumentIndexed\n\n\ndef handle(batch):\n    return [DocumentIndexed(doc_id=d["id"]) for d in batch]\n' > services/ingest/worker.py
  printf 'BATCH_SIZE = 200\n' > services/ingest/settings.py
  printf 'from services.ingest.worker import handle\n\n\ndef test_empty_batch():\n    assert handle([]) == []\n' > services/ingest/tests/test_worker.py
  _oc you 'ingest: add the indexing worker'

  printf 'from dataclasses import dataclass\n\n\n@dataclass\nclass SearchRequest:\n    query: str\n    top_k: int = 10\n\n\n@dataclass\nclass DocumentIndexed:\n    doc_id: str\n' > libs/schemas/events.py
  printf 'SCHEMA_VERSION = 1\n' > libs/schemas/__init__.py
  local _n
  for _n in search_request document_indexed click feedback session; do
    printf '{\n  "title": "%s",\n  "version": 1,\n  "type": "object"\n}\n' "$_n" > "libs/schemas/v1/$_n.json"
  done
  _oc asha 'schemas: add the event types and their JSON schemas'

  printf 'import re\n\n_WORD = re.compile(r"[a-z0-9]+")\n\n\ndef tokenize(text):\n    return _WORD.findall(text.lower())\n' > libs/tokenizer/tokenizer.py
  # A vocabulary of 1500 entries, one per line (deterministic content).
  local _i=1
  while [ "$_i" -le 1500 ]; do
    printf 'tok%04d %d\n' "$_i" $((_i * 37 % 9973))
    _i=$((_i + 1))
  done > libs/tokenizer/vocab.txt
  _oc ravi 'tokenizer: add the tokenizer and its vocabulary'

  printf 'import yaml\n\n\ndef main(path="pipelines/training/config.yaml"):\n    cfg = yaml.safe_load(open(path))\n    return cfg["epochs"]\n' > pipelines/training/train.py
  printf 'epochs: 3\nlearning_rate: 0.0003\nbatch_size: 32\n' > pipelines/training/config.yaml
  _oc you 'training: add the training entry point'

  printf 'import json\n\n\ndef load(path="pipelines/eval/cases.jsonl"):\n    return [json.loads(line) for line in open(path)]\n' > pipelines/eval/run_eval.py
  # 400 evaluation cases, one JSON document per line.
  _i=1
  while [ "$_i" -le 400 ]; do
    printf '{"id": %d, "query": "how do I reset the password for account %d", "gold": ["doc-%d"], "min_recall": 0.80}\n' \
      "$_i" "$_i" $((_i * 13 % 997))
    _i=$((_i + 1))
  done > pipelines/eval/cases.jsonl
  _oc asha 'eval: add the evaluation runner and 400 cases'

  printf '# Architecture\n\nRequests enter through the gateway, which calls the ranker. The ingest service\nfeeds the index. All three share the event schemas in libs/schemas.\n' > docs/architecture.md
  for _n in gateway-latency ranker-rollback ingest-backlog; do
    printf '# Runbook: %s\n\n1. Check the dashboard.\n2. Page the owning team.\n' "$_n" > "docs/runbooks/$_n.md"
  done
  printf 'import subprocess\nimport sys\n\n\ndef changed_projects(base):\n    out = subprocess.run(["git", "diff", "--name-only", base + "...HEAD"], capture_output=True, text=True, check=True)\n    return sorted({"/".join(p.split("/")[:2]) for p in out.stdout.splitlines() if "/" in p})\n\n\nif __name__ == "__main__":\n    print("\\n".join(changed_projects(sys.argv[1])))\n' > tools/ci/affected.py
  _oc ravi 'docs, tools: add the architecture notes, runbooks and the affected-projects script'

  # ---------------------------------------------------------------- twelve rounds of daily work
  # Each round: one commit per area. Tags mark releases of single projects.
  local _r=1 _line _who
  while [ "$_r" -le 12 ]; do
    printf 'ROUTES = [\n    ("GET", "/healthz"),\n' > services/gateway/routes.py
    _i=1
    while [ "$_i" -le "$_r" ]; do
      printf '    ("POST", "/v1/search/%d"),\n' "$_i" >> services/gateway/routes.py
      _i=$((_i + 1))
    done
    printf ']\n' >> services/gateway/routes.py
    _oc asha "gateway: add search route $_r"

    printf 'FEATURES = [\n    "bm25",\n' > services/ranker/features.py
    _i=1
    while [ "$_i" -le "$_r" ]; do
      printf '    "signal_%02d",\n' "$_i" >> services/ranker/features.py
      _i=$((_i + 1))
    done
    printf ']\n' >> services/ranker/features.py
    _oc ravi "ranker: add ranking signal $_r"

    printf 'BATCH_SIZE = %d\n' $((200 + _r * 50)) > services/ingest/settings.py
    _oc you "ingest: raise the batch size to $((200 + _r * 50))"

    _line=$((_r * 31))
    sed -e "${_line}s/0.80/0.85/" pipelines/eval/cases.jsonl > pipelines/eval/cases.tmp && mv pipelines/eval/cases.tmp pipelines/eval/cases.jsonl
    _oc asha "eval: tighten case $_line to recall 0.85"

    _line=$((_r * 113))
    sed -e "${_line}s/\$/ merged/" libs/tokenizer/vocab.txt > libs/tokenizer/vocab.tmp && mv libs/tokenizer/vocab.tmp libs/tokenizer/vocab.txt
    _oc ravi "tokenizer: mark vocabulary entry $_line as merged"

    printf 'epochs: %d\nlearning_rate: 0.0003\nbatch_size: 32\n' $((3 + _r)) > pipelines/training/config.yaml
    _oc you "training: train for $((3 + _r)) epochs"

    printf '\n## Change %d\n\nSee the pull request for the reasoning.\n' "$_r" >> docs/architecture.md
    _oc asha "docs: record architecture change $_r"

    case "$_r" in
      3) as asha; tick; git tag -a gateway/v1.0.0 -m 'gateway 1.0.0' HEAD~6 ;;
      6) as ravi; tick; git tag -a ranker/v0.9.0 -m 'ranker 0.9.0' HEAD~5 ;;
      9) as asha; tick; git tag -a gateway/v1.1.0 -m 'gateway 1.1.0' HEAD~6 ;;
      2) as you; tick; git tag -a schemas/v1.0.0 -m 'schemas 1.0.0' HEAD ;;
    esac
    _r=$((_r + 1))
  done

  # A feature branch that touches one service: two commits, forked from main here.
  git switch -q -c feature/rerank-cache
  printf 'from libs.tokenizer.tokenizer import tokenize\n\n_CACHE = {}\n\n\ndef score(query, document):\n    key = (query, document)\n    if key not in _CACHE:\n        q = set(tokenize(query))\n        d = set(tokenize(document))\n        _CACHE[key] = len(q & d) / max(len(q), 1)\n    return _CACHE[key]\n' > services/ranker/model.py
  _oc ravi 'ranker: cache scores per query and document'
  printf 'top_k: 10\nmodel: overlap-v1\ncache_size: 4096\n' > services/ranker/config.yaml
  _oc ravi 'ranker: make the cache size configurable'
  git switch -q main

  # Meanwhile on main: one change that crosses project boundaries in a single commit.
  printf 'from dataclasses import dataclass\n\n\n@dataclass\nclass SearchRequest:\n    query: str\n    top_k: int = 10\n    tenant: str = "default"\n\n\n@dataclass\nclass DocumentIndexed:\n    doc_id: str\n' > libs/schemas/events.py
  printf 'from libs.schemas.events import SearchRequest\n\n\ndef create_app():\n    return {"name": "gateway", "routes": [], "tenant_header": "X-Tenant"}\n' > services/gateway/app.py
  printf 'from libs.schemas.events import DocumentIndexed\n\n\ndef handle(batch, tenant="default"):\n    return [DocumentIndexed(doc_id=d["id"]) for d in batch]\n' > services/ingest/worker.py
  _oc you 'schemas, gateway, ingest: add the tenant field in one change'
  as you; tick; git tag -a schemas/v1.1.0 -m 'schemas 1.1.0' HEAD

  as you
  cd .. || return 1
  _orbit_env_off
}

# orbit_pack: run maintenance once in ./orbit, so that later commands have no reason to start a
# background maintenance process in the middle of a demo.
orbit_pack() {
  _orbit_env_on
  tick
  git -C orbit maintenance run --quiet > /dev/null 2>&1
  _orbit_env_off
}

# orbit_server: a bare copy of ./orbit in ./server/orbit.git that accepts partial-clone filters
# and has been packed once, as a hosting server would have done.
orbit_server() {
  _orbit_env_on
  tick
  mkdir -p server
  git clone -q --bare orbit server/orbit.git > /dev/null 2>&1 || return 1
  git -C server/orbit.git remote remove origin
  git -C server/orbit.git config set uploadpack.allowFilter true
  git -C server/orbit.git gc --quiet > /dev/null 2>&1
  _orbit_env_off
}

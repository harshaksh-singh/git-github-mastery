# labs/ch21b/fixture.bash — starting states for Chapter 21B and the labs of Modules 30 and 31.
#
# This file is sourced, never run. Each function builds its state inside the current sandbox
# ($LAB_DIR) and returns with the current directory set back to $LAB_DIR. Setup scripts and
# replay scripts call the same function at the same point of the lab clock, so the commits
# have the same IDs in the hands-on sandbox as in the book.
#
# Every "secret" below is a dummy, spelled so that no scanner pattern matches it.

FX_KEY='DUMMY-KEY-not-a-real-secret-12345'
FX_TOKEN='DUMMY-TOKEN-not-a-real-secret-67890'

_c() { quiet "git add -A && git commit -m '$1'"; }

_fx_clone() {  # _fx_clone <directory> [<person>]
  quiet "git clone server.git $1"
  quiet "git -C $1 remote set-url origin ../server.git"
  case "${2:-}" in
    asha) quiet "git -C $1 config set user.name 'Asha Rao' && git -C $1 config set user.email asha@example.com" ;;
    ravi) quiet "git -C $1 config set user.name 'Ravi Menon' && git -C $1 config set user.email ravi@example.com" ;;
  esac
}

# A stand-in for the provider that issued the key: a list of active keys and a small script
# to query, revoke and issue. It lets the labs practise "revoke first" without a real service.
_fx_provider() {
  mkdir -p provider
  printf '%s\n' "$FX_KEY" > provider/active-keys.txt
  cat > provider/keyctl <<'KEYCTL'
#!/bin/sh
# Stand-in for a provider console. Usage: keyctl status KEY | revoke KEY | issue
db="$(dirname "$0")/active-keys.txt"
case "$1" in
  status) if grep -qxF "$2" "$db"; then echo "ACTIVE   $2"; else echo "REVOKED  $2"; fi ;;
  revoke) grep -vxF "$2" "$db" > "$db.tmp"; mv "$db.tmp" "$db"; echo "revoked  $2" ;;
  issue)  echo "DUMMY-KEY-rotated-not-a-real-secret-2" >> "$db"; echo "issued   DUMMY-KEY-rotated-not-a-real-secret-2" ;;
  *) echo "usage: keyctl status KEY | revoke KEY | issue" >&2; exit 2 ;;
esac
KEYCTL
  chmod +x provider/keyctl
}

# kit/: the two hooks used in the prevention steps. A lab copies them into place.
_fx_kit() {
  mkdir -p kit
  cat > kit/pre-commit <<'HOOK'
#!/bin/sh
# Client-side guard: refuse a commit whose staged additions match a secret pattern.
if git diff --cached -U0 | grep -E '^\+.*DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' > /dev/null; then
  echo "pre-commit: a staged line matches a secret pattern; commit refused" >&2
  exit 1
fi
HOOK
  cat > kit/pre-receive <<'HOOK'
#!/bin/sh
# Server-side guard: refuse a push if any commit it introduces contains a secret pattern.
pattern='DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
while read old new ref; do
  case "$new" in *[!0]*) ;; *) continue ;; esac          # a deletion: nothing to scan
  for c in $(git rev-list "$new" --not --all); do
    if git grep -q -E "$pattern" "$c"; then
      echo "push declined: $ref: commit $(git rev-parse --short "$c") contains a secret pattern"
      exit 1
    fi
  done
done
HOOK
  chmod +x kit/pre-commit kit/pre-receive
}

# ragdesk: a retrieval-augmented helpdesk service.
#   server.git   the bare "server"
#   ragdesk      your clone
#   asha         a teammate's clone with one unpushed commit (a stale clone)
#   ravi         a second teammate's clone without local work (another stale clone)
#   provider/    the stand-in for the key's issuer
# History of main (oldest first): retriever, prompt, LLM client, evaluation [tag v0.1.0],
# staging settings (the commit that sweeps in .env with the dummy key), retry [tag v0.2.0],
# timeout, README. The secret commit therefore has three commits after it.
# Branch feature/streaming (Asha, pushed) forks after the timeout commit.
fx_ragdesk() {
  quiet 'git init --bare server.git'
  _fx_clone ragdesk
  cd ragdesk || return 1
  printf 'def search(query, k):\n    return bm25.top(query, k)\n' > retriever.py
  _c 'Add BM25 retriever'
  mkdir -p prompts
  printf 'Answer the customer using only the passages below.\n\n{passages}\n\nQuestion: {question}\n' > prompts/answer.txt
  _c 'Add answer prompt template'
  printf 'import os\n\ndef complete(prompt):\n    key = os.environ["LLM_API_KEY"]\n    return post("/v1/complete", key, prompt)\n' > llm_client.py
  _c 'Add LLM client'
  printf 'def exact_match(pred, gold):\n    return pred.strip() == gold.strip()\n' > eval.py
  _c 'Add evaluation harness'
  quiet "git tag -a v0.1.0 -m 'ragdesk 0.1.0'"
  # The mistake: .env was meant to stay local, and "git add -A" swept it in.
  printf 'env: staging\nindex: helpdesk-staging\ntop_k: 5\n' > settings.yaml
  printf 'LLM_API_KEY=%s\nLLM_BASE_URL=https://llm.example.com\n' "$FX_KEY" > .env
  _c 'Add staging settings'
  printf 'import os\n\ndef complete(prompt, retries=3):\n    key = os.environ["LLM_API_KEY"]\n    for attempt in range(retries):\n        try:\n            return post("/v1/complete", key, prompt)\n        except TransientError:\n            backoff(attempt)\n' > llm_client.py
  _c 'Add retry with backoff'
  quiet "git tag -a v0.2.0 -m 'ragdesk 0.2.0'"
  printf 'env: staging\nindex: helpdesk-staging\ntop_k: 5\ntimeout_s: 20\n' > settings.yaml
  _c 'Add request timeout'
  as asha
  quiet 'git switch -c feature/streaming'
  printf 'def stream(prompt):\n    for chunk in post_stream("/v1/complete", prompt):\n        yield chunk\n' > streaming.py
  _c 'Add streaming responses'
  quiet 'git switch main'
  as you
  printf '# ragdesk\n\nRetrieval-augmented answers for the helpdesk.\n\nCopy .env.example to .env and fill in your key.\n' > README.md
  _c 'Document setup in README'
  quiet 'git push origin main feature/streaming --tags'
  quiet 'git branch -D feature/streaming'
  quiet 'git branch --set-upstream-to=origin/main main'
  cd "$LAB_DIR" || return 1
  _fx_clone asha asha
  cd asha || return 1
  as asha
  printf 'def exact_match(pred, gold):\n    return pred.strip() == gold.strip()\n\ndef contains(pred, gold):\n    return gold.strip() in pred\n' > eval.py
  _c 'Add contains metric'
  as you
  cd "$LAB_DIR" || return 1
  _fx_clone ravi ravi
  _fx_provider
  _fx_kit
}

# Adds a second leak for the history-scan lab: a branch on the server, forked from v0.1.0,
# whose notebook output captured a bearer token. Nothing on main mentions it.
fx_ragdesk_notebook() {
  cd ragdesk || return 1
  as ravi
  quiet 'git switch -c exp/rerank v0.1.0'
  mkdir -p notebooks
  printf '{\n "cells": [\n  {\n   "cell_type": "code",\n   "source": ["resp = client.rerank(query, passages)\\n", "resp.request.headers"],\n   "outputs": [\n    {"text": ["{\\"Authorization\\": \\"Bearer %s\\"}"]}\n   ]\n  }\n ]\n}\n' "$FX_TOKEN" > notebooks/rerank-debug.ipynb
  _c 'Add rerank debugging notebook'
  quiet 'git push origin exp/rerank'
  quiet 'git switch main'
  quiet 'git branch -D exp/rerank'
  as you
  cd "$LAB_DIR" || return 1
}

# Adds a leak that exists only in your clone: a commit that was amended before it was pushed.
# No ref reaches the first version; the reflog does.
fx_ragdesk_amended() {
  cd ragdesk || return 1
  printf 'HEADERS = {"X-Api-Key": "DUMMY-KEY-not-a-real-secret-24680"}\n\ndef test_health():\n    assert get("/health", HEADERS).status == 200\n' > smoke_test.py
  _c 'Add smoke test'
  printf 'import os\nHEADERS = {"X-Api-Key": os.environ["SMOKE_KEY"]}\n\ndef test_health():\n    assert get("/health", HEADERS).status == 200\n' > smoke_test.py
  quiet 'git commit -a --amend --no-edit'
  cd "$LAB_DIR" || return 1
}

# triage: a ticket router with a bare server and the hook kit, for the push-time check
# (the local analogue of push protection).
fx_triage() {
  quiet 'git init --bare server.git'
  _fx_clone triage
  _fx_kit
  cd triage || return 1
  printf 'def route(ticket):\n    return "billing" if "invoice" in ticket else "general"\n' > router.py
  _c 'Add ticket router'
  quiet 'git push -u origin main'
  cd "$LAB_DIR" || return 1
}

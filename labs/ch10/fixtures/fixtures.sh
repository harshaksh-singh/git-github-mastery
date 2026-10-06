#!/usr/bin/env bash
# labs/ch10/fixtures/fixtures.sh
# Hidden setup shared by the Chapter 10 demos, the Module 10 lab replays (10.1 to 10.3) and the hands-on
# setup scripts. Source it after lab-env.sh. Every fx_* function expects the current directory to be the
# sandbox ($LAB_DIR), builds its repository with the pinned lab clock, and leaves you inside it, so the
# replay and the hands-on setup start from identical commit IDs.
#
# The example project is "gateway", a small service that forwards prompts to a model API.
# main is the development line (1.5); release/1.4 is the maintenance line that customers run.

put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }
commit_all() { tick; git add -A > /dev/null 2>&1 && git commit -q -m "$1" > /dev/null 2>&1; }

# run_add_paragraph '<paragraph>' '<git command that opens the message editor>'
# Plays the part of a person who keeps the message that Git proposes and adds one paragraph after the
# subject line. The transcript shows the message as the editor opened it and as it was saved.
run_add_paragraph() {
  tick
  printf '$ %s\n' "$2"
  LAB_PARAGRAPH="$1" GIT_EDITOR="sh '$COURSE_ROOT/labs/ch10/fixtures/add-paragraph-editor.sh'" eval "$2"
}

handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

_client_v1() {          # the client as first released
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
}

_smoke_script() {
  put scripts/smoke.sh <<'EOF'
#!/bin/sh
# Smoke test: client.py must not call a helper that this branch does not define.
if grep -q 'log_event(' src/client.py && ! grep -rq 'def log_event' src; then
  echo "smoke test failed: client.py calls log_event, which this branch does not define"
  exit 1
fi
echo "smoke test passed"
EOF
}

fx_gateway_init() {
  git init -q gateway && cd gateway || return 1
  _client_v1
  _smoke_script
  put VERSION <<'EOF'
1.4.0
EOF
  commit_all "Add model client"
  git branch release/1.4
  put VERSION <<'EOF'
1.5.0-dev
EOF
  commit_all "Start 1.5 development"
}

# A commit that exists only on the maintenance line.
#   _release_tweak retries   changes line 2, which lies inside the context of the fix's hunk
#   _release_tweak timeout   changes line 1, which lies outside it
_release_tweak() {
  git switch -q release/1.4
  case "$1" in
    retries)
      put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 3

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
      commit_all "Allow three retries on the 1.4 line" ;;
    timeout)
      put src/client.py <<'EOF'
TIMEOUT_S = 60
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
      commit_all "Raise the timeout to 60 seconds on the 1.4 line" ;;
  esac
}

# ---------------------------------------------------------------- a self-contained fix on main
# main:         A---B---C---D---E      D (by Asha) "Reject empty prompts before calling the model"
# release/1.4:   \--R                  R changes a line two lines above the place D edits
fx_gateway_fix() {      # fx_gateway_fix [retries|timeout]   which release-only commit to create
  fx_gateway_init || return 1
  put src/stream.py <<'EOF'
def stream(prompt):
    return post("/v1/stream", prompt)
EOF
  commit_all "Add streaming client"
  as asha
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Reject empty prompts before calling the model"
  as you
  put README.md <<'EOF'
# gateway

Forwards prompts to the model API. Streaming is available from 1.5.
EOF
  commit_all "Document the streaming client"
  _release_tweak "${1:-retries}"
}

# ---------------------------------------------------------------- a fix whose line differs on the release
# main:         A---B---V---S---F---T
#   V "Move to the v2 generate endpoint"      (main only: 1.4 customers stay on v1)
#   S "Add streaming client"
#   F "Retry failed generate calls"           (by Asha; edits the line that V changed)
#   T "Apply the timeout to streaming calls"
# release/1.4:   A
fx_gateway_conflict() {
  fx_gateway_init || return 1
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Move to the v2 generate endpoint"
  put src/stream.py <<'EOF'
def stream(prompt):
    return post("/v2/stream", prompt)
EOF
  commit_all "Add streaming client"
  as asha
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
EOF
  commit_all "Retry failed generate calls"
  as you
  put src/stream.py <<'EOF'
def stream(prompt):
    return post("/v2/stream", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Apply the timeout to streaming calls"
  git switch -q release/1.4
}

# ---------------------------------------------------------------- a merge commit on main
fx_gateway_merge() {
  fx_gateway_init || return 1
  git switch -q -c feat/limits
  put src/limits.py <<'EOF'
RATE_LIMIT_PER_MIN = 60
EOF
  commit_all "Add a per-minute rate limit"
  put src/limits.py <<'EOF'
RATE_LIMIT_PER_MIN = 60
BURST = 10
EOF
  commit_all "Allow short bursts above the rate limit"
  git switch -q main
  put README.md <<'EOF'
# gateway

Forwards prompts to the model API.
EOF
  commit_all "Add README"
  tick
  git merge -q --no-ff -m "Merge branch 'feat/limits'" feat/limits > /dev/null 2>&1
  git switch -q release/1.4
}

# ---------------------------------------------------------------- Lab 10.1: a fix and a tempting follow-up
# main:         A---B---C---D---E
#   C "Add structured event logger"                       (main only)
#   D "Reject empty prompts before calling the model"     (by Asha; self-contained)
#   E "Log rejected prompts"                              (by Asha; needs C and D)
# release/1.4:   \--R
fx_gateway_backport() {
  fx_gateway_init || return 1
  put src/events.py <<'EOF'
def log_event(name, **fields):
    emit({"event": name, **fields})
EOF
  commit_all "Add structured event logger"
  as asha
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Reject empty prompts before calling the model"
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        log_event("empty_prompt")
        raise ValueError("empty prompt")
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Log rejected prompts"
  as you
  _release_tweak retries
  git switch -q main
}

# ---------------------------------------------------------------- Lab 10.3: which fixes are already backported?
# main:         A---B---D---V---F---G---H
#   D "Reject empty prompts before calling the model"   backported as-is with -x
#   V "Move to the v2 generate endpoint"                main only
#   F "Retry failed generate calls"                     backported with -x, conflict resolved by hand
#   G "Back off when the API answers 429"               NOT backported
#   H "Add streaming client"                            a feature, not for the release
# release/1.4:   \--R---D'--F'                         R changes only line 1 of client.py
fx_gateway_duplicates() {
  fx_gateway_init || return 1
  as asha
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Reject empty prompts before calling the model"
  as you
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
EOF
  commit_all "Move to the v2 generate endpoint"
  as asha
  put src/client.py <<'EOF'
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
EOF
  commit_all "Retry failed generate calls"
  put src/backoff.py <<'EOF'
def backoff_seconds(attempt):
    return min(30, 2 ** attempt)
EOF
  commit_all "Back off when the API answers 429"
  as you
  put src/stream.py <<'EOF'
def stream(prompt):
    return post("/v2/stream", prompt)
EOF
  commit_all "Add streaming client"
  _release_tweak timeout
  tick
  git cherry-pick -x main~4 > /dev/null 2>&1
  tick
  git cherry-pick -x main~2 > /dev/null 2>&1
  put src/client.py <<'EOF'
TIMEOUT_S = 60
MAX_RETRIES = 2

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
EOF
  git add src/client.py
  GIT_EDITOR=true git cherry-pick --continue > /dev/null 2>&1
}

# labs/ch29/fixtures.bash — starting states for the demos of Chapter 29 and the labs of Module 35.
#
# This file is sourced, never run. Each function builds one state inside the current sandbox
# ($LAB_DIR) and returns with the current directory set back to $LAB_DIR. A hands-on setup
# script and the replay script of the same lab call the same function at the same point of the
# lab clock, so the commit IDs in your hands-on sandbox are the ones printed in the book.

# Commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m '$1'"; }

# Clone the bare server.git of the sandbox and store the URL as a relative path, so that
# transcripts print "../server.git" in the replay and in the hands-on sandbox alike.
_fx_clone() {  # _fx_clone <directory> [<bare-repository>]
  quiet "git clone ${2:-server.git} $1"
  quiet "git -C $1 remote set-url origin ../${2:-server.git}"
}

# ------------------------------------------------------------------ Case 1 (sections 29.3, 29.7)
# scoring-api: a published branch feature/latency-budget (three commits, pushed). A rebase onto
# main stopped at a conflict in the first commit. The conflict was resolved and committed, the
# rebase was never continued, and two more commits were made on the detached HEAD.
fx_case_rebase() {
  quiet 'git init --bare server.git'
  quiet 'git init scoring-api'
  cd scoring-api || return 1
  quiet 'git remote add origin ../server.git'
  mkdir -p app config
  printf 'def score(features, model):\n    return model.predict(features)\n' > app/score.py
  printf 'workers: 2\ntimeout_s: 30\n' > config/service.yaml
  printf '# scoring-api\n\nScores feature vectors with the ranking model.\n' > README.md
  _c 'Add scoring service skeleton'
  printf 'FIELDS = ["user_id", "item_id", "features"]\n' > app/schema.py
  _c 'Add request schema'
  quiet 'git push -u origin main'
  quiet 'git switch -c feature/latency-budget'
  printf 'workers: 2\nlatency_budget_ms: 200\ntimeout_s: 30\n' > config/service.yaml
  _c 'Add latency budget to config'
  printf 'def score(features, model, budget_ms):\n    with deadline(budget_ms):\n        return model.predict(features)\n' > app/score.py
  _c 'Enforce latency budget in scorer'
  printf '# scoring-api\n\nScores feature vectors with the ranking model.\n\nEvery request has a latency budget (config/service.yaml).\n' > README.md
  _c 'Document latency budget'
  quiet 'git push -u origin feature/latency-budget'
  # A teammate changes the same lines of the config on main.
  quiet 'git switch main'
  as asha
  printf 'workers: 8\ntimeout_s: 30\n' > config/service.yaml
  _c 'Raise worker count to 8'
  as you
  quiet 'git push origin main'
  # The rebase that was never finished.
  quiet 'git switch feature/latency-budget'
  quiet 'git rebase main'
  printf 'workers: 8\nlatency_budget_ms: 200\ntimeout_s: 30\n' > config/service.yaml
  quiet 'git add config/service.yaml'
  quiet 'git commit --no-edit'
  # Work continued on the detached HEAD of the stopped rebase.
  printf 'def p95(samples):\n    ordered = sorted(samples)\n    return ordered[int(0.95 * (len(ordered) - 1))]\n' > app/metrics.py
  _c 'Add p95 latency metric'
  printf 'import logging\n\nlog = logging.getLogger("scoring")\n\n\ndef budget_exceeded(request_id, ms):\n    log.warning("budget exceeded: %%s took %%d ms", request_id, ms)\n' > app/audit.py
  _c 'Log budget violations'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Case 2 (sections 29.4, 29.5)
# embed-jobs: your branch feature/batch-size was created from origin/main, so its upstream is
# origin/main. A teammate pushed a branch of the same name to the server.
fx_case_upstream() {
  quiet 'git init --bare server.git'
  quiet 'git init seed'
  cd seed || return 1
  mkdir -p jobs
  printf 'def embed(texts, model):\n    return [model.encode(t) for t in texts]\n' > jobs/embed.py
  printf 'model: e5-base\n' > jobs/config.yaml
  _c 'Add embedding job'
  printf 'model: e5-base\noutput: s3://vectors/daily\n' > jobs/config.yaml
  _c 'Write vectors to the daily bucket'
  quiet 'git push ../server.git main'
  cd "$LAB_DIR" || return 1
  rm -rf seed
  _fx_clone embed-jobs
  _fx_clone asha-embed-jobs
  # You: a new branch started from the remote-tracking branch.
  cd embed-jobs || return 1
  quiet 'git switch -c feature/batch-size origin/main'
  printf 'def embed(texts, model, batch_size):\n    out = []\n    for i in range(0, len(texts), batch_size):\n        out.extend(model.encode(texts[i:i + batch_size]))\n    return out\n' > jobs/embed.py
  _c 'Embed in batches'
  printf 'import sys\n\nBATCH = int(sys.argv[1]) if len(sys.argv) > 1 else 64\n' > jobs/cli.py
  _c 'Read batch size from the command line'
  cd "$LAB_DIR" || return 1
  # Asha: the same branch name, pushed first.
  cd asha-embed-jobs || return 1
  as asha
  quiet 'git switch -c feature/batch-size'
  printf 'model: e5-base\noutput: s3://vectors/daily\nbatch_size: 64\n' > jobs/config.yaml
  _c 'Add batch_size to the job config'
  quiet 'git push -u origin feature/batch-size'
  as you
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ operations in progress
# A repository with a main branch and a branch that conflicts with it, used to stop each
# operation half-way. fx_ops_base <directory>
fx_ops_base() {
  quiet "git init $1"
  cd "$1" || return 1
  printf 'threshold: 0.50\nmax_tokens: 256\n' > guard.yaml
  printf 'def check(text):\n    return len(text) < 256\n' > guard.py
  _c 'Add output guard'
  printf 'def check(text):\n    return len(text.split()) < 256\n' > guard.py
  _c 'Count tokens, not characters'
  quiet 'git switch -c feature/strict-guard'
  printf 'threshold: 0.80\nmax_tokens: 256\n' > guard.yaml
  _c 'Raise guard threshold to 0.80'
  printf 'BLOCKLIST = ["password", "api_key"]\n' > blocklist.py
  _c 'Add blocklist'
  printf 'threshold: 0.80\nmax_tokens: 128\n' > guard.yaml
  _c 'Lower max_tokens to 128'
  quiet 'git switch main'
  printf 'threshold: 0.65\nmax_tokens: 256\n' > guard.yaml
  _c 'Raise guard threshold to 0.65'
  printf '# output-guard\n' > README.md
  _c 'Add README'
  cd "$LAB_DIR" || return 1
}

# fx_op <directory> <merge|rebase|cherry-pick|revert|bisect>: build the base and stop there.
fx_op() {
  fx_ops_base "$1"
  cd "$1" || return 1
  case "$2" in
    merge)       quiet 'git merge feature/strict-guard' ;;
    rebase)      quiet 'git switch feature/strict-guard'; quiet 'git rebase main' ;;
    cherry-pick) quiet 'git cherry-pick main~2..feature/strict-guard' ;;
    revert)      quiet 'git switch feature/strict-guard'; quiet 'git revert --no-edit HEAD~2' ;;
    bisect)      quiet 'git switch feature/strict-guard'; quiet 'git bisect start HEAD main~3'; quiet 'git bisect good' ;;
  esac
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 35.1
# Three repositories, each with a symptom card (SYMPTOM.txt beside the repository).
fx_35_1() {
  # --- annotator: commits on a detached HEAD, and a forgotten stash
  quiet 'git init annotator'
  cd annotator || return 1
  printf 'LABELS = ["relevant", "irrelevant"]\n' > labels.py
  _c 'Add label set'
  printf 'def export(rows):\n    return [r.to_json() for r in rows]\n' > export.py
  _c 'Add JSON export'
  quiet 'git tag -a v0.2.0 -m "Release 0.2.0"'
  printf 'LABELS = ["relevant", "partially_relevant", "irrelevant"]\n' > labels.py
  _c 'Add partially_relevant label'
  printf 'def export(rows):\n    return [r.to_json() for r in rows if r.done]\n' > export.py
  quiet 'git stash push -m "export only finished rows"'
  quiet 'git checkout v0.2.0'
  printf 'def agreement(a, b):\n    return sum(x == y for x, y in zip(a, b)) / len(a)\n' > agreement.py
  _c 'Add inter-annotator agreement'
  printf 'def kappa(a, b):\n    raise NotImplementedError\n' >> agreement.py
  _c 'Add kappa stub'
  cd "$LAB_DIR" || return 1
  printf 'Reported by the developer:\n"I made two commits this morning. git log on main does not show them,\nand a change to export.py that I was working on last week is gone too."\n' > annotator.SYMPTOM.txt

  # --- batch-infer: diverged from the server, a staged change, a tracked file that is ignored
  quiet 'git init --bare batch-server.git'
  quiet 'git init seed'
  cd seed || return 1
  printf 'def run(batch, model):\n    return [model(x) for x in batch]\n' > infer.py
  printf '.env\n__pycache__/\n' > .gitignore
  printf 'MODEL_ENDPOINT=http://localhost:8080\n' > .env
  quiet 'git add -f .env'
  _c 'Add batch inference job'
  quiet 'git push ../batch-server.git main'
  cd "$LAB_DIR" || return 1
  rm -rf seed
  _fx_clone batch-infer batch-server.git
  _fx_clone ravi-batch-infer batch-server.git
  cd ravi-batch-infer || return 1
  as ravi
  printf 'def run(batch, model, retries=2):\n    return [model(x) for x in batch]\n' > infer.py
  _c 'Add retries parameter'
  printf 'RETRYABLE = (TimeoutError, ConnectionError)\n' > errors.py
  _c 'List retryable errors'
  quiet 'git push origin main'
  as you
  cd "$LAB_DIR" || return 1
  rm -rf ravi-batch-infer
  cd batch-infer || return 1
  printf 'def chunks(seq, n):\n    for i in range(0, len(seq), n):\n        yield seq[i:i + n]\n' > chunks.py
  _c 'Add chunk helper'
  printf 'def chunks(seq, n):\n    """Yield lists of at most n items."""\n    for i in range(0, len(seq), n):\n        yield seq[i:i + n]\n' > chunks.py
  quiet 'git add chunks.py'
  printf 'MODEL_ENDPOINT=http://10.0.4.17:8080\n' > .env
  cd "$LAB_DIR" || return 1
  printf 'Reported by the developer:\n"git push is rejected. Also .env shows as modified every day,\nalthough it is in .gitignore."\n' > batch-infer.SYMPTOM.txt

  # --- prompt-router: an ignored new file, a branch without upstream, a wrong identity
  quiet 'git init --bare router-server.git'
  quiet 'git init seed'
  cd seed || return 1
  mkdir -p router
  printf 'ROUTES = {"faq": "small", "code": "large"}\n' > router/routes.py
  _c 'Add prompt routes'
  quiet 'git push ../router-server.git main'
  cd "$LAB_DIR" || return 1
  rm -rf seed
  _fx_clone prompt-router router-server.git
  cd prompt-router || return 1
  printf '*_keys.py\n' >> .git/info/exclude
  quiet 'git config set user.email lab.user@personal.example'
  quiet 'git switch -c feature/router-cache'
  as config
  printf 'CACHE = {}\n\n\ndef route(prompt, kind):\n    key = cache_key(prompt, kind)\n    return CACHE.setdefault(key, ROUTES[kind])\n' > router/cache.py
  _c 'Cache routing decisions'
  quiet 'git push origin feature/router-cache'
  printf 'import hashlib\n\n\ndef cache_key(prompt, kind):\n    return hashlib.sha256((kind + prompt).encode()).hexdigest()\n' > router/cache_keys.py
  as you
  cd "$LAB_DIR" || return 1
  printf 'Reported by the developer:\n"CI on my branch fails with ModuleNotFoundError: router.cache_keys.\nThe file is on my machine and git status says the working tree is clean.\nAlso my commit is not linked to my account on GitHub."\n' > prompt-router.SYMPTOM.txt
}

# ------------------------------------------------------------------ Lab 35.2
# Five repositories named case-1 ... case-5. The names do not reveal the operation.
fx_35_2() {
  fx_op case-1 revert
  fx_op case-2 bisect
  fx_op case-3 merge
  fx_op case-4 cherry-pick
  fx_op case-5 rebase
}

# ------------------------------------------------------------------ Lab 35.3
# guardrail: a backport of three commits to release/1.4 that stopped at the second one. The
# first pick is committed; the conflict of the second one was resolved by hand in the working
# tree and not staged yet. A handover note describes what the previous engineer did.
fx_35_3() {
  quiet 'git init guardrail'
  cd guardrail || return 1
  printf 'threshold: 0.50\nmax_tokens: 256\n' > guard.yaml
  printf 'def check(text):\n    return len(text) < 256\n' > guard.py
  _c 'Add output guard'
  quiet 'git branch release/1.4'
  printf 'threshold: 0.65\nmax_tokens: 256\n' > guard.yaml
  _c 'Raise guard threshold to 0.65'
  printf 'BLOCKLIST = ["password", "api_key"]\n' > blocklist.py
  _c 'Add blocklist'
  printf 'threshold: 0.65\nmax_tokens: 128\n' > guard.yaml
  _c 'Lower max_tokens to 128'
  printf 'BLOCKLIST = ["password", "api_key", "secret"]\n' > blocklist.py
  _c 'Block the word secret'
  quiet 'git switch release/1.4'
  printf 'threshold: 0.50\nmax_tokens: 512\n' > guard.yaml
  _c 'Allow 512 tokens on the 1.4 line'
  quiet 'git cherry-pick -x main~2 main~1 main'
  printf 'threshold: 0.50\nmax_tokens: 128\n' > guard.yaml
  cd "$LAB_DIR" || return 1
  printf 'Handover note:\n"Backporting the blocklist and the token limit to release/1.4 for tonight.\nGot a conflict in guard.yaml. On 1.4 the threshold must stay 0.50; the limit\nbecomes 128. I fixed the file by hand and then had to leave. Please finish."\n' > guardrail.HANDOVER.txt
}

# labs/ch27/fixture.bash - shared fixture for the Chapter 27 demos and the labs of Modules 32 and 34.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo: the file
# name does not end in .sh, so the build and verify tools skip it.
#
# The project is "promptgate", a small gateway that sits between product teams and LLM providers:
# it routes a request to a model, enforces per-tenant limits and streams the answer back.
# Every function leaves the current directory where its comment says. Nothing here talks to a
# network or to GitHub; a "pull request merge" is imitated with "git merge --no-ff".

# hidden '<command line>': a setup step that the transcript does not show. A failing hidden
# step stops the script, because a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# put <path>: write standard input to the file, creating its directory.
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1" || { printf 'fixture: put failed: %s\n' "$1" >&2; exit 1; }
}

# commit_all <message>: stage everything and commit, silently. Advances the clock by one minute.
commit_all() {
  tick
  { git add -A && git commit -q -m "$1"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_all failed: %s\n' "$1" >&2; exit 1; }
}

require_ref() {
  git -C "$1" rev-parse --verify --quiet "$2" > /dev/null ||
    { printf 'fixture: expected ref %s in %s\n' "$2" "$1" >&2; exit 1; }
}

# ---------------------------------------------------------------- file versions
router_v1() {
  put gateway/router.py <<'PY'
MODELS = {"chat": "sonnet-large", "embed": "embed-small"}


def route(request):
    return MODELS[request["task"]]
PY
}

limits_v1() {
  put gateway/limits.py <<'PY'
LIMITS = {"default": 60}


def allowed(tenant, used):
    return used < LIMITS.get(tenant, LIMITS["default"])
PY
}

# The bug that the hotfix repairs: a tenant with a limit of 0 (suspended) is treated as unlimited.
limits_buggy() {
  put gateway/limits.py <<'PY'
LIMITS = {"default": 60}


def allowed(tenant, used):
    limit = LIMITS.get(tenant) or LIMITS["default"]
    return used < limit
PY
}

limits_fixed() {
  put gateway/limits.py <<'PY'
LIMITS = {"default": 60}


def allowed(tenant, used):
    limit = LIMITS.get(tenant, LIMITS["default"])
    return used < limit
PY
}

stream_v1() {
  put gateway/stream.py <<'PY'
def stream(chunks):
    for chunk in chunks:
        yield chunk
PY
}

fallback_v1() {
  put gateway/fallback.py <<'PY'
FALLBACK = {"sonnet-large": "haiku-small"}


def fallback(model):
    return FALLBACK.get(model, model)
PY
}

batch_v1() {
  put gateway/batch.py <<'PY'
def submit(requests):
    return [{"id": i, "status": "queued"} for i, _ in enumerate(requests)]
PY
}

# ---------------------------------------------------------------- starting states
# fx_base: repository "promptgate" with release v1.3.0 on main. Leaves you inside it.
fx_base() {
  hidden 'git init promptgate'
  cd promptgate || exit 1
  router_v1
  printf '1.3.0\n' > VERSION
  printf '# promptgate\n\nGateway between product teams and LLM providers.\n' > README.md
  commit_all 'Add gateway skeleton'
  limits_v1
  commit_all 'Add per-tenant rate limits'
  hidden 'git tag -a v1.3.0 -m "promptgate 1.3.0"'
}

# fx_two_features <integration branch>: two feature branches, each merged with --no-ff the way
# a pull request merge would be. The second one carries the bug in limits.py.
fx_two_features() {
  hidden "git switch -c feature/streaming $1"
  stream_v1
  commit_all 'Stream tokens to the client'
  hidden "git switch -c feature/tenant-limits $1"
  limits_buggy
  commit_all 'Read tenant limits with a default'
  hidden "git switch $1"
  hidden 'git merge --no-ff -m "Merge pull request #41 from feature/streaming" feature/streaming'
  hidden 'git merge --no-ff -m "Merge pull request #42 from feature/tenant-limits" feature/tenant-limits'
  hidden 'git branch -d feature/streaming feature/tenant-limits'
}

# fx_batch_feature <integration branch>: the feature that lands after the release was cut.
fx_batch_feature() {
  hidden "git switch -c feature/batch-api $1"
  batch_v1
  commit_all 'Add batch endpoint'
  hidden "git switch $1"
  hidden 'git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api'
  hidden 'git branch -d feature/batch-api'
}

# fx_ready_to_release: v1.3.0 plus the two merged features on main. Leaves you inside promptgate.
fx_ready_to_release() {
  fx_base
  fx_two_features main
}

# fx_diverged: main and release/1.4 after release v1.4.0, with the batch feature on main only.
# The starting state of the fix-direction demo. Leaves you inside promptgate.
fx_diverged() {
  fx_ready_to_release
  hidden 'git branch release/1.4 main'
  hidden 'git tag -a v1.4.0 -m "promptgate 1.4.0" release/1.4'
  fx_batch_feature main
}

# fx_lab_32_1: two identical copies of the ready-to-release repository, one per strategy, each
# with the batch feature waiting on a branch. Leaves you in $LAB_DIR.
fx_lab_32_1() {
  fx_ready_to_release
  hidden 'git switch -c feature/batch-api main'
  batch_v1
  commit_all 'Add batch endpoint'
  hidden 'git switch main'
  cd "$LAB_DIR" || exit 1
  hidden 'mkdir github-flow release-branch'
  hidden 'cp -R promptgate github-flow/promptgate'
  hidden 'mv promptgate release-branch/promptgate'
}

# fx_fork: an upstream repository maintained by Asha, your fork of it, and your clone of the fork.
#   $LAB_DIR/upstream/promptgate.git   bare; plays the upstream repository on the platform
#   $LAB_DIR/fork/promptgate.git       bare; plays your fork (a server-side copy that you own)
#   $LAB_DIR/asha/promptgate           the maintainer's clone of upstream
# Leaves you in $LAB_DIR. Your own clone is made in the transcript.
fx_fork() {
  hidden 'mkdir upstream fork asha'
  hidden 'git init --bare upstream/promptgate.git'
  hidden 'git clone upstream/promptgate.git asha/promptgate'
  cd asha/promptgate || exit 1
  hidden 'git remote set-url origin ../../upstream/promptgate.git'
  hidden 'git config set user.name "Asha Rao" && git config set user.email asha@example.com'
  as asha
  router_v1
  limits_buggy
  printf '# promptgate\n\nGateway between product teams and LLM providers.\n' > README.md
  put CONTRIBUTING.md <<'MD'
# Contributing

1. Open an issue before a large change.
2. One logical change per pull request, with a test.
3. Branch from `main`; we squash on merge.
MD
  commit_all 'Add gateway with tenant limits'
  hidden 'git push -u origin main'
  as you
  cd "$LAB_DIR" || exit 1
  hidden 'git clone --bare upstream/promptgate.git fork/promptgate.git'
}

# asha_lands <file> <message>: the maintainer merges somebody else's work into upstream main.
asha_lands() {
  ( cd "$LAB_DIR/asha/promptgate" || exit 1
    as asha
    hidden 'git pull -q --ff-only'
    case "$1" in
      stream) stream_v1 ;;
      fallback) fallback_v1 ;;
    esac
    commit_all "$2"
    hidden 'git push origin main' ) || exit 1
  tick; tick; tick
}

# ---------------------------------------------------------------- Lab 34.1
# commit_on <date> <message>: commit everything with an explicit author and committer date, so
# that the repository of the design review has branches of different ages.
commit_on() {
  tick
  { git add -A && GIT_AUTHOR_DATE="$1 +0530" GIT_COMMITTER_DATE="$1 +0530" git commit -q -m "$2"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_on failed: %s\n' "$2" >&2; exit 1; }
}
merge_on() {   # merge_on <date> <message> <branch> [--squash]
  tick
  if [ "${4:-}" = "--squash" ]; then
    { git merge --squash "$3" && GIT_AUTHOR_DATE="$1 +0530" GIT_COMMITTER_DATE="$1 +0530" git commit -q -m "$2"; } > /dev/null 2>&1 ||
      { printf 'fixture: merge_on failed: %s\n' "$2" >&2; exit 1; }
  else
    GIT_AUTHOR_DATE="$1 +0530" GIT_COMMITTER_DATE="$1 +0530" git merge -q --no-ff -m "$2" "$3" > /dev/null 2>&1 ||
      { printf 'fixture: merge_on failed: %s\n' "$2" >&2; exit 1; }
  fi
}
tag_on() {     # tag_on <date> <tag> <commit>
  tick
  GIT_COMMITTER_DATE="$1 +0530" git tag -a "$2" -m "riskscore ${2#v}" "$3" > /dev/null 2>&1 ||
    { printf 'fixture: tag_on failed: %s\n' "$2" >&2; exit 1; }
}

# fx_lab_34_1: "riskscore", the repository of the company in the design review. It has the
# habits the review must find: a long-lived develop branch, release branches with a fix that
# never reached main, a squash-merged branch that was never deleted, a stale refactoring
# branch, a model checkpoint and an environment file in history. Leaves you inside riskscore.
fx_lab_34_1() {
  hidden 'git init riskscore'
  cd riskscore || exit 1
  as ravi
  put score/model.py <<'PY'
WEIGHTS = {"late_payments": 0.6, "utilisation": 0.4}


def score(features):
    return sum(WEIGHTS[k] * features[k] for k in WEIGHTS)
PY
  printf '# riskscore\n\nCredit-risk scoring service.\n' > README.md
  commit_on '2026-03-02 10:00:00' 'initial'
  printf 'DB_PASSWORD=dev-only-not-a-real-secret\nMODEL_BUCKET=s3://example-models\n' > .env
  commit_on '2026-03-03 11:00:00' 'wip'
  hidden 'git rm -q .env'
  printf '.env\n' > .gitignore
  commit_on '2026-03-04 09:30:00' 'remove env file'
  hidden 'mkdir -p models'
  python3 -c "import sys; sys.stdout.buffer.write(bytes(range(256)) * 8192)" > models/risk-v1.ckpt
  commit_on '2026-03-10 15:00:00' 'add model'
  hidden 'git rm -q models/risk-v1.ckpt'
  printf '.env\nmodels/\n' > .gitignore
  commit_on '2026-03-12 12:00:00' 'model moved to bucket'
  tag_on '2026-03-20 17:00:00' v2.0.0 HEAD
  hidden 'git branch release/2.0 v2.0.0'
  hidden 'git branch develop main'

  as asha
  hidden 'git switch develop'
  put score/features.py <<'PY'
def utilisation(balance, limit):
    return balance / limit
PY
  commit_on '2026-04-06 10:00:00' 'Add utilisation feature'
  put score/explain.py <<'PY'
def top_factor(contributions):
    return max(contributions, key=contributions.get)
PY
  commit_on '2026-04-20 16:00:00' 'Add explanation of the top factor'
  hidden 'git switch main'
  merge_on '2026-05-04 11:00:00' 'Merge develop for 2.1' develop
  tag_on '2026-05-04 18:00:00' v2.1.0 HEAD
  hidden 'git branch release/2.1 v2.1.0'

  # a fix that exists only on release/2.0
  as ravi
  hidden 'git switch release/2.0'
  put score/model.py <<'PY'
WEIGHTS = {"late_payments": 0.6, "utilisation": 0.4}


def score(features):
    return sum(WEIGHTS[k] * features.get(k, 0.0) for k in WEIGHTS)
PY
  commit_on '2026-05-18 09:00:00' 'fix'
  tag_on '2026-05-18 12:00:00' v2.0.1 HEAD

  # a branch that was squash-merged and never deleted
  as you
  hidden 'git switch -c feature/calibration main'
  put score/calibrate.py <<'PY'
def calibrate(p, slope=1.0, intercept=0.0):
    return min(1.0, max(0.0, slope * p + intercept))
PY
  commit_on '2026-06-01 10:00:00' 'Add calibration'
  put score/calibrate.py <<'PY'
def calibrate(p, slope=1.0, intercept=0.0):
    """Clamp a linearly recalibrated probability to [0, 1]."""
    return min(1.0, max(0.0, slope * p + intercept))
PY
  commit_on '2026-06-02 10:00:00' 'Document calibration'
  hidden 'git switch main'
  merge_on '2026-06-03 14:00:00' 'Add calibration (#88)' feature/calibration --squash

  # a stale refactoring branch
  as asha
  hidden 'git switch -c feature/big-refactor v2.1.0'
  local i
  for i in 1 2 3 4 5 6 7 8 9; do
    printf '# refactoring step %s\n' "$i" >> score/model.py
    commit_on "2026-05-1$i 10:00:00" "refactor step $i"
  done

  # develop keeps moving and is not merged
  hidden 'git switch develop'
  hidden 'git merge -q --ff-only v2.1.0'
  for i in 1 2 3 4 5; do
    printf 'def feature_%s(x):\n    return x\n' "$i" >> score/features.py
    commit_on "2026-07-0$i 10:00:00" "Add feature $i for the Q3 model"
  done
  put score/explain.py <<'PY'
def top_factor(contributions):
    return sorted(contributions, key=contributions.get, reverse=True)[0]
PY
  commit_on '2026-08-17 10:00:00' 'Rework explanation ordering'
  hidden 'git switch main'
  as ravi
  printf '# riskscore\n\nCredit-risk scoring service.\n\nSee docs/ for the runbook.\n' > README.md
  commit_on '2026-08-24 10:00:00' 'Update README.md'
  as you
}

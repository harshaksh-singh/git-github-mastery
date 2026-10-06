# labs/ch17/fixture.bash - shared fixture for the Chapter 17 demos and the Module 21 and 22 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo:
# the file name does not end in .sh, so the build and verify tools skip it.
#
# The project is "ticket-router", a small service that sends support tickets to a queue.
# The topology every script builds (all on disk inside the sandbox, no network):
#
#   $LAB_DIR/server/ticket-router.git    a bare repository that plays the shared repository on the platform
#   $LAB_DIR/you/ticket-router           your clone (you are the contributor)
#   $LAB_DIR/asha/ticket-router          the clone of Asha, the maintainer who merges
#   $LAB_DIR/ravi/ticket-router          the clone of Ravi, a teammate
#
# Clones store the server URL as a relative path, so that commit IDs do not depend on where
# the sandbox lives ("git pull" writes the URL into the merge message it creates).
#
# Nothing here talks to GitHub. Where a script imitates something the platform does (a ref
# under refs/pull/, a test merge, a merge button), the chapter says which documented behavior
# is being imitated, and that the commands are plain Git chosen by the author, not GitHub's.

SERVER_URL=../../server/ticket-router.git

# hidden '<command line>'
# A setup step that the transcript does not show. A failing hidden step stops the script:
# a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# put <path>
# Write standard input to the file, creating its directory.
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1" || { printf 'fixture: put failed: %s\n' "$1" >&2; exit 1; }
}

# commit_all <message>
# Stage everything and commit, silently. Advances the clock by one minute.
commit_all() {
  tick
  { git add -A && git commit -q -m "$1"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_all failed: %s\n' "$1" >&2; exit 1; }
}

# ---------------------------------------------------------------- file versions
classify_v1() {
  put router/classify.py <<'PY'
QUEUES = ["billing", "technical", "general"]


def classify(ticket):
    text = ticket["subject"].lower()
    if "invoice" in text or "refund" in text:
        return "billing"
    if "error" in text or "crash" in text:
        return "technical"
    return "general"
PY
}

# The feature: tickets with high priority go to their own queue. Version 2 has a wrong queue name.
classify_v2() {
  put router/classify.py <<'PY'
from router.priority import priority

QUEUES = ["billing", "technical", "general", "escalation"]


def classify(ticket):
    text = ticket["subject"].lower()
    if priority(ticket) == "high":
        return "escalation"
    if "invoice" in text or "refund" in text:
        return "billing"
    if "error" in text or "crash" in text:
        return "technical"
    return "general"
PY
}

classify_v3() {
  put router/classify.py <<'PY'
from router.priority import priority

QUEUES = ["billing", "technical", "general", "escalations"]


def classify(ticket):
    text = ticket["subject"].lower()
    if priority(ticket) == "high":
        return "escalations"
    if "invoice" in text or "refund" in text:
        return "billing"
    if "error" in text or "crash" in text:
        return "technical"
    return "general"
PY
}

priority_v1() {
  put router/priority.py <<'PY'
URGENT_WORDS = ["outage", "down", "urgent"]


def priority(ticket):
    text = ticket["subject"].lower()
    return "high" if any(word in text for word in URGENT_WORDS) else "normal"
PY
}

# ---------------------------------------------------------------- repositories
# make_server
# Create the bare shared repository with four commits on main, written by Asha.
# Ends in $LAB_DIR with your identity active.
make_server() {
  as asha
  hidden "git init --bare '$LAB_DIR/server/ticket-router.git'"
  hidden "git clone '$LAB_DIR/server/ticket-router.git' '$LAB_DIR/.seed'"
  cd "$LAB_DIR/.seed" || exit 1
  printf '# ticket-router\n\nSends each support ticket to the queue that can answer it.\n' | put README.md
  commit_all 'Add README'
  classify_v1
  commit_all 'Add keyword classifier'
  printf 'model: router-small-v1\nconfidence_threshold: 0.6\nfallback_queue: general\n' | put config/routing.yaml
  commit_all 'Add routing config'
  put tests/test_classify.py <<'PY'
from router.classify import classify


def test_refund_goes_to_billing():
    assert classify({"subject": "Refund please"}) == "billing"
PY
  commit_all 'Add classifier test'
  hidden 'git push origin main'
  cd "$LAB_DIR" || exit 1
  rm -rf "$LAB_DIR/.seed"
  as you
}

# new_clone <person> [<server directory name>]
# Clone the server into $LAB_DIR/<person>/ticket-router and store the relative server URL.
# Teammates also get user.name and user.email in the clone's own configuration, so that
# commits you type by hand inside their clone (labs/shell) carry their name.
new_clone() {
  local dir="$LAB_DIR/$1/ticket-router"
  hidden "git clone '$LAB_DIR/server/ticket-router.git' '$dir'"
  git -C "$dir" remote set-url origin "$SERVER_URL" || exit 1
  case "$1" in
    asha) git -C "$dir" config set user.name 'Asha Rao';   git -C "$dir" config set user.email asha@example.com ;;
    ravi) git -C "$dir" config set user.name 'Ravi Menon'; git -C "$dir" config set user.email ravi@example.com ;;
  esac
}

# enter <person>
# Become that person and move into their clone, without printing anything.
enter() {
  as "$1"
  cd "$LAB_DIR/$1/ticket-router" || exit 1
}

# require_ref <repository> <ref>
# Used by setup scripts as a final sanity check.
require_ref() {
  git -C "$1" rev-parse --verify --quiet "$2" > /dev/null ||
    { printf 'fixture: expected ref %s in %s\n' "$2" "$1" >&2; exit 1; }
}

# ---------------------------------------------------------------- common starting states
# feature_priority_routing
# In your clone: the branch feature/priority-routing with three commits, pushed to the server.
# The third commit repairs the second, the way review fixes do. Leaves you on that branch.
feature_priority_routing() {
  enter you
  hidden 'git switch -c feature/priority-routing'
  priority_v1
  commit_all 'Add priority scoring'
  classify_v2
  commit_all 'Route high-priority tickets to escalation'
  classify_v3
  commit_all 'Fix the name of the escalations queue'
  hidden 'git push -u origin feature/priority-routing'
}

# main_moves_on
# Asha publishes one commit on main that does not touch the files of the feature.
main_moves_on() {
  enter asha
  hidden 'git pull --ff-only'
  printf 'model: router-small-v1\nconfidence_threshold: 0.7\nfallback_queue: general\n' | put config/routing.yaml
  commit_all 'Raise the confidence threshold to 0.7'
  hidden 'git push origin main'
}

# scenario_pr
# The state most demos start from: server, three clones, your pushed feature branch,
# and one newer commit on main. Ends in your clone, on the feature branch, with nothing fetched
# since the push.
scenario_pr() {
  make_server
  new_clone you
  new_clone asha
  new_clone ravi
  feature_priority_routing
  main_moves_on
  enter you
}

# server_open_pr <number> <head branch>
# Imitates, with plain Git, the part of "open a pull request" that is Git data: a ref
# refs/pull/<number>/head on the server that names the head commit.
server_open_pr() {
  git -C "$LAB_DIR/server/ticket-router.git" update-ref "refs/pull/$1/head" "refs/heads/$2" ||
    { printf 'fixture: server_open_pr failed\n' >&2; exit 1; }
}

# ---------------------------------------------------------------- three copies for the merge methods
# make_method_copies
# Called after scenario_pr. Builds three independent copies of the whole situation, one per
# merge method, so that the same pull request can be merged three ways and compared:
#
#   $LAB_DIR/<method>/server.git     the shared repository
#   $LAB_DIR/<method>/asha           the maintainer's clone (she presses the merge button)
#   $LAB_DIR/<method>/you            your clone, with the feature branch as you wrote it
#
# for <method> in merge, squash, rebase. All copies start with identical objects and refs.
make_method_copies() {
  local m
  for m in merge squash rebase; do
    mkdir -p "$LAB_DIR/$m"
    hidden "git clone --bare '$LAB_DIR/server/ticket-router.git' '$LAB_DIR/$m/server.git'"
    hidden "git clone '$LAB_DIR/$m/server.git' '$LAB_DIR/$m/asha'"
    git -C "$LAB_DIR/$m/asha" remote set-url origin ../server.git || exit 1
    git -C "$LAB_DIR/$m/asha" config set user.name 'Asha Rao'
    git -C "$LAB_DIR/$m/asha" config set user.email asha@example.com
    hidden "git clone '$LAB_DIR/$m/server.git' '$LAB_DIR/$m/you'"
    git -C "$LAB_DIR/$m/you" remote set-url origin ../server.git || exit 1
    hidden "git -C '$LAB_DIR/$m/you' switch feature/priority-routing"
    hidden "git -C '$LAB_DIR/$m/you' switch main"
  done
}

# priority_v2: the follow-up change, one more urgent word.
priority_v2() {
  put router/priority.py <<'PY'
URGENT_WORDS = ["outage", "down", "urgent", "data loss"]


def priority(ticket):
    text = ticket["subject"].lower()
    return "high" if any(word in text for word in URGENT_WORDS) else "normal"
PY
}

# squash_merge_pr1
# Asha squash-merges feature/priority-routing into main and pushes. The head branch stays on
# the server (nobody deleted it). Ends in Asha's clone.
squash_merge_pr1() {
  enter asha
  hidden 'git fetch'
  hidden 'git merge --squash origin/feature/priority-routing'
  hidden 'git commit -m "Route high-priority tickets to an escalations queue (#1)"'
  hidden 'git push origin main'
}

# scenario_squash_reuse
# Pull request 1 was squash-merged and its branch was kept. You are in your clone, on the old
# branch, and have fetched. This is the starting state of the squash-then-reuse demo and of Lab 21.3.
scenario_squash_reuse() {
  scenario_pr
  squash_merge_pr1
  enter you
  hidden 'git fetch'
}

# classify_empty_subject: a bug fix on top of classify_v1 (a ticket without a subject).
classify_empty_subject() {
  put router/classify.py <<'PY'
QUEUES = ["billing", "technical", "general"]


def classify(ticket):
    text = ticket.get("subject", "").lower()
    if "invoice" in text or "refund" in text:
        return "billing"
    if "error" in text or "crash" in text:
        return "technical"
    return "general"
PY
}

# scenario_wrong_base [<person>]
# The server has main and release/1.0. The release branch was cut two commits ago and carries
# one commit of its own. <person> (default: ravi) created fix/empty-subject from the current
# main, with one commit, and pushed it. The fix is meant for release/1.0.
# Ends in that person's clone on the fix branch.
# Starting state of the wrong-base demo (ravi) and of Lab 21.2 (you).
scenario_wrong_base() {
  local who="${1:-ravi}"
  make_server
  new_clone asha
  enter asha
  hidden 'git switch -c release/1.0'
  printf '1.0.0\n' | put VERSION
  commit_all 'Set version 1.0.0'
  hidden 'git push -u origin release/1.0'
  hidden 'git switch main'
  printf 'model: router-small-v1\nconfidence_threshold: 0.7\nfallback_queue: general\n' | put config/routing.yaml
  commit_all 'Raise the confidence threshold to 0.7'
  printf '# ticket-router\n\nSends each support ticket to the queue that can answer it.\n\nRun the tests with pytest.\n' | put README.md
  commit_all 'Describe how to run the tests'
  hidden 'git push origin main'
  new_clone "$who"
  enter "$who"
  hidden 'git switch -c fix/empty-subject'
  classify_empty_subject
  commit_all 'Accept tickets without a subject'
  hidden 'git push -u origin fix/empty-subject'
}

# priority_sla: the second layer of a stack; it changes the file that the first layer added.
priority_sla() {
  put router/priority.py <<'PY'
URGENT_WORDS = ["outage", "down", "urgent"]
SLA_MINUTES = {"high": 30, "normal": 480}


def priority(ticket):
    text = ticket["subject"].lower()
    return "high" if any(word in text for word in URGENT_WORDS) else "normal"


def sla_minutes(ticket):
    return SLA_MINUTES[priority(ticket)]
PY
}

# scenario_stack
# Two dependent branches in your clone, both pushed:
#   main <- feature/priority-routing (three commits) <- feature/sla-timers (two commits)
# Ends in your clone on feature/sla-timers.
scenario_stack() {
  make_server
  new_clone you
  new_clone asha
  feature_priority_routing
  hidden 'git switch -c feature/sla-timers'
  priority_sla
  commit_all 'Add SLA minutes per priority'
  printf 'model: router-small-v1\nconfidence_threshold: 0.6\nfallback_queue: general\nsla_alert_after_minutes: 25\n' | put config/routing.yaml
  commit_all 'Alert before the SLA of a high-priority ticket expires'
  hidden 'git push -u origin feature/sla-timers'
}

# scenario_fork
# The fork-and-pull model on disk:
#   $LAB_DIR/server/ticket-router.git        upstream, the shared repository (Asha maintains it)
#   $LAB_DIR/forks/you/ticket-router.git     your fork: a server-side copy that you may push to
#   $LAB_DIR/you/ticket-router               your clone of your fork; remotes origin (fork) and upstream
#   $LAB_DIR/asha/ticket-router              Asha's clone of upstream
# After you forked, upstream gained one commit, so your fork's main is one commit behind.
# Ends in your clone on main.
scenario_fork() {
  make_server
  hidden "git clone --bare '$LAB_DIR/server/ticket-router.git' '$LAB_DIR/forks/you/ticket-router.git'"
  hidden "git clone '$LAB_DIR/forks/you/ticket-router.git' '$LAB_DIR/you/ticket-router'"
  git -C "$LAB_DIR/you/ticket-router" remote set-url origin ../../forks/you/ticket-router.git || exit 1
  git -C "$LAB_DIR/you/ticket-router" remote add upstream ../../server/ticket-router.git || exit 1
  new_clone asha
  main_moves_on
  enter you
}

# scenario_conflict
# Ravi's branch fix/threshold sets the confidence threshold to 0.65. After he pushed, Asha set it
# to 0.7 on main. A pull request from fix/threshold into main therefore conflicts.
# Ends in Ravi's clone on fix/threshold, with main fetched.
scenario_conflict() {
  make_server
  new_clone asha
  new_clone ravi
  enter ravi
  hidden 'git switch -c fix/threshold'
  printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' | put config/routing.yaml
  commit_all 'Lower the confidence threshold to 0.65'
  printf '# ticket-router\n\nSends each support ticket to the queue that can answer it.\n\nThe threshold is tuned on the March ticket sample.\n' | put README.md
  commit_all 'Document how the threshold was tuned'
  hidden 'git push -u origin fix/threshold'
  main_moves_on
  enter ravi
  hidden 'git fetch'
}

# scenario_three_methods
# Starting state of Lab 22.1: the pull request situation, copied three times (see make_method_copies).
# Ends in $LAB_DIR.
scenario_three_methods() {
  scenario_pr
  make_method_copies
  cd "$LAB_DIR" || exit 1
  as you
}

# scenario_release
# Starting state of Lab 22.2: the server and your clone, nothing tagged yet. Ends in your clone.
scenario_release() {
  make_server
  new_clone you
  new_clone asha
  enter you
}

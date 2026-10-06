# labs/ch05/m02-setups.inc - starting repositories for the Module 2 labs.
# Sourced by the hands-on setup scripts (setup-02-*.sh) and by the replay scripts
# (lab-02-*.sh), so that both start from exactly the same commits.
# Each function expects to be called right after sandbox_begin or lab_begin and leaves
# the current directory unchanged (the sandbox root).

# Lab 2.1: one repository, one commit, one single-line settings file.
m02_1_setup() {
  git init -q support-bot
  ( cd support-bot || exit 1
    mkdir -p config
    printf 'top_k: 5\n' > config/settings.yaml
    printf '# Support bot\n\nRoutes support tickets to an LLM with retrieval.\n' > README.md
    git add . ) || return 1
  tick
  git -C support-bot commit -q -m "Add settings and README"
}

# Lab 2.2: an evaluation script with three unrelated edits waiting in the working tree.
m02_2_setup() {
  git init -q support-bot
  mkdir -p support-bot/src
  cat > support-bot/src/evaluate.py <<'PY'
"""Offline evaluation for the support bot."""
import json

THRESHOLD = 0.5


def load_cases(path):
    with open(path) as handle:
        return [json.loads(line) for line in handle]


def is_correct(case, prediction):
    return prediction == case["expected"]


def accuracy(cases, predictions):
    correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
    return correct / len(cases)


def report(cases, predictions):
    score = accuracy(cases, predictions)
    status = "PASS" if score >= THRESHOLD else "FAIL"
    return f"{status} accuracy={score:.3f}"
PY
  git -C support-bot add .
  tick
  git -C support-bot commit -q -m "Add offline evaluation script"
  # The three edits: a threshold change, a bug fix, and a debug line.
  cat > support-bot/src/evaluate.py <<'PY'
"""Offline evaluation for the support bot."""
import json

THRESHOLD = 0.8


def load_cases(path):
    with open(path) as handle:
        return [json.loads(line) for line in handle]


def is_correct(case, prediction):
    return prediction.strip().lower() == case["expected"].strip().lower()


def accuracy(cases, predictions):
    print("DEBUG predictions:", predictions)
    correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
    return correct / len(cases)


def report(cases, predictions):
    score = accuracy(cases, predictions)
    status = "PASS" if score >= THRESHOLD else "FAIL"
    return f"{status} accuracy={score:.3f}"
PY
}

# Lab 2.4: one repository with one commit, and an empty directory for the "no commits yet" case.
m02_4_setup() {
  git init -q support-bot
  ( cd support-bot || exit 1
    mkdir -p src
    printf 'TOP_K = 5\n' > src/retriever.py
    printf '# Support bot\n' > README.md
    git add . ) || return 1
  tick
  git -C support-bot commit -q -m "Add retriever and README"
}

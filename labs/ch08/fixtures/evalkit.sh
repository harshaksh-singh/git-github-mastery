#!/usr/bin/env bash
# Shared fixtures for the Chapter 8 demos and the Module 6 labs.
#
# This file is sourced by the scripts in labs/ch08/. It is not a demo, which is why it lives in a
# subdirectory: tools/build-demos.sh and labs/verify-all.sh only run the scripts directly inside labs/ch08/.
#
# The sample project is "evalkit", a small evaluation harness for LLM outputs:
#   config/eval.yaml     run configuration (model, temperature, batch size, ...)
#   prompts/judge.txt    the prompt given to the judge model
#   evalkit/metrics.py   scoring functions
#
# Every helper that commits calls ek_commit, which advances the lab clock by one minute first.
# Replay scripts and hands-on setup scripts call the same helpers in the same order, so the commits
# they create have identical IDs.

# ek_commit MESSAGE: stage everything and commit, one minute after the previous commit.
ek_commit() {
  tick
  git add -A && git commit -q -m "$1"
}

# ek_set KEY VALUE: change one "key: value" line of config/eval.yaml.
ek_set() {
  sed -e "s/^$1: .*/$1: $2/" config/eval.yaml > config/eval.yaml.new &&
    mv config/eval.yaml.new config/eval.yaml
}

# ek_files: write the three base files into the current directory (no commit).
ek_files() {
  mkdir -p config prompts evalkit
  cat > config/eval.yaml <<'YAML'
model: judge-large-v2
temperature: 0.2
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 7
YAML
  cat > prompts/judge.txt <<'TXT'
You are a strict grader.
Answer with PASS or FAIL.
TXT
  cat > evalkit/metrics.py <<'PY'
def exact_match(pred, gold):
    return float(pred == gold)


def accuracy(scores):
    return sum(scores) / len(scores)
PY
}

# ek_base [DIR]: create a repository (default name: evalkit) with the base files in one commit,
# and enter it. The current branch is main.
ek_base() {
  local dir="${1:-evalkit}"
  git init -q "$dir" && cd "$dir" || return 1
  ek_files
  ek_commit 'Add eval config, judge prompt and metrics'
}

# ek_creative_judge: the standard conflict scenario used by several demos.
#   feature/creative-judge (Asha): temperature 0.2 -> 0.7 and seed 7 -> 1234 in one commit,
#                                  then one more line in the judge prompt
#   main (you):                    temperature 0.2 -> 0.0
# Leaves you on main. Merging feature/creative-judge conflicts on the temperature line only.
ek_creative_judge() {
  ek_base "${1:-evalkit}" || return 1
  git switch -q -c feature/creative-judge
  as asha
  ek_set temperature 0.7 && ek_set seed 1234 && ek_commit 'Raise temperature and reseed for judge diversity'
  printf 'Explain your verdict in one sentence.\n' >> prompts/judge.txt
  ek_commit 'Ask the judge for a rationale'
  as you
  git switch -q main
  ek_set temperature 0.0 && ek_commit 'Use temperature 0 for reproducible evals'
}

# ek_resolve_dropping PATTERN FILE: resolve a conflict the way a person would in an editor:
# remove the marker lines and every line matching PATTERN (the side that is not kept).
ek_resolve_dropping() {
  grep -v -e '^<<<<<<<' -e '^|||||||' -e '^=======' -e '^>>>>>>>' -e "$1" "$2" > "$2.resolved" &&
    mv "$2.resolved" "$2"
}

# ek_replace_conflict FILE TEXT: replace every conflict block in FILE (from the <<<<<<< line to the
# >>>>>>> line) by TEXT. TEXT may contain \n for a line break. Again this stands in for an editor.
ek_replace_conflict() {
  awk -v text="$2" '
    /^<<<<<<< / { skipping = 1; print text; next }
    /^>>>>>>> / { skipping = 0; next }
    !skipping   { print }
  ' "$1" > "$1.resolved" && mv "$1.resolved" "$1"
}

# ek_metrics_with_f1: replace evalkit/metrics.py by a longer version that also has a token F1.
# Used where rename detection matters: similarity is measured on file content.
ek_metrics_with_f1() {
  cat > evalkit/metrics.py <<'PY'
def exact_match(pred, gold):
    return float(pred == gold)


def accuracy(scores):
    return sum(scores) / len(scores)


def f1(pred_tokens, gold_tokens):
    common = set(pred_tokens) & set(gold_tokens)
    if not common:
        return 0.0
    precision = len(common) / len(pred_tokens)
    recall = len(common) / len(gold_tokens)
    return 2 * precision * recall / (precision + recall)
PY
}

# ek_scoring_rewrite: write evalkit/scoring.py, a rewrite of the longer metrics module that
# returns Score objects. It shares 39% of its content with ek_metrics_with_f1's file, which is
# below Git's default rename threshold of 50%.
ek_scoring_rewrite() {
  mkdir -p evalkit
  cat > evalkit/scoring.py <<'PY'
"""Scoring functions for evalkit."""
from dataclasses import dataclass


@dataclass
class Score:
    name: str
    value: float


def exact_match(pred, gold):
    return Score("exact_match", float(pred == gold))


def accuracy(scores):
    values = [s.value for s in scores]
    return Score("accuracy", sum(values) / len(values))


def f1(pred_tokens, gold_tokens):
    common = set(pred_tokens) & set(gold_tokens)
    if not common:
        return Score("f1", 0.0)
    precision = len(common) / len(pred_tokens)
    recall = len(common) / len(gold_tokens)
    return Score("f1", 2 * precision * recall / (precision + recall))
PY
}

# ek_check_imports: add ci/check_imports.sh, a stand-in for a test suite. It fails when a module
# imports a name from evalkit.metrics that evalkit/metrics.py does not define. A shell script is
# used instead of real tests so that the transcript does not depend on a Python installation.
ek_check_imports() {
  mkdir -p ci
  cat > ci/check_imports.sh <<'SH'
#!/bin/sh
# Every name imported from evalkit.metrics must be defined in evalkit/metrics.py.
status=0
for file in evalkit/*.py; do
  names=$(sed -n 's/^from evalkit.metrics import //p' "$file" | tr -d ',')
  for name in $names; do
    if ! grep -q "^def $name(" evalkit/metrics.py; then
      echo "FAIL $file imports $name, which evalkit/metrics.py does not define"
      status=1
    fi
  done
done
[ "$status" -eq 0 ] && echo "OK every import from evalkit.metrics resolves"
exit "$status"
SH
}

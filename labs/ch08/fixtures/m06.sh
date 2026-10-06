#!/usr/bin/env bash
# Fixtures for the Module 6 labs (lab manual: lab-manual/m06-merge.md).
#
# Each m06_<k>_fixture function builds the starting repository of Lab 6.<k> in ./evalkit and leaves
# you inside it, on main. The replay script labs/ch08/lab-06-<k>-*.sh and the hands-on setup script
# labs/ch08/setup-06-<k>-*.sh call the same function, so the commits you start from by hand have the
# same IDs as the ones printed in the lab manual.
#
# This file is sourced after fixtures/evalkit.sh. It is not a demo.

# m06_setup_done K: the closing message of a hands-on setup script.
m06_setup_done() {
  printf 'Lab 6.%s is ready in %s\n' "$1" "$LAB_DIR/evalkit"
  printf 'Next:  labs/shell m06-%s   and then   cd evalkit\n' "$1"
}

# ---------------------------------------------------------------- Lab 6.1
# main            : base, README, wording fix (fast-forwarded from fix/typo), seed pin
# fix/typo        : already contained in main
# feature/batch-size   : two commits ahead of main, nothing missing
# feature/judge-prompt : forked before the wording fix, one commit of its own
m06_1_fixture() {
  ek_base || return 1
  printf '# evalkit\n\nEvaluation harness for LLM outputs.\n' > README.md
  ek_commit 'Add a README'
  git branch feature/judge-prompt
  git switch -q -c fix/typo
  as ravi
  printf '# evalkit\n\nAn evaluation harness for LLM outputs.\n' > README.md
  ek_commit 'Fix the README wording'
  as you
  git switch -q main
  git merge -q fix/typo
  ek_set seed 42 && ek_commit 'Pin the eval seed to 42'
  git switch -q -c feature/batch-size
  as asha
  ek_set batch_size 32 && ek_commit 'Raise batch size to 32'
  ek_set timeout_s 60 && ek_commit 'Raise timeout to 60 seconds'
  git switch -q feature/judge-prompt
  printf 'Explain your verdict in one sentence.\n' >> prompts/judge.txt
  ek_commit 'Ask the judge for a rationale'
  as you
  git switch -q main
}

# ---------------------------------------------------------------- Lab 6.2
# main (you)                    : exact_match strips whitespace; the judge must answer in one word
# feature/case-insensitive (Asha): exact_match ignores case; adds a test that documents the intent
# feature/judge-wording (Ravi)  : the judge may also answer UNSURE (used in the failure scenario)
m06_2_fixture() {
  ek_base || return 1
  git switch -q -c feature/case-insensitive
  as asha
  sed -e 's/pred == gold/pred.lower() == gold.lower()/' evalkit/metrics.py > m && mv m evalkit/metrics.py
  ek_commit 'Compare answers case-insensitively'
  mkdir -p tests
  cat > tests/test_metrics.py <<'PY'
from evalkit.metrics import exact_match


def test_case_is_ignored():
    assert exact_match("Paris", "paris") == 1.0
PY
  ek_commit 'Test that exact_match ignores case'
  git switch -q -c feature/judge-wording main
  as ravi
  sed -e 's/Answer with PASS or FAIL\./Answer with PASS, FAIL or UNSURE./' prompts/judge.txt > j && mv j prompts/judge.txt
  ek_commit 'Let the judge answer UNSURE'
  as you
  git switch -q main
  sed -e 's/pred == gold/pred.strip() == gold.strip()/' evalkit/metrics.py > m && mv m evalkit/metrics.py
  ek_commit 'Ignore surrounding whitespace when comparing'
  sed -e 's/Answer with PASS or FAIL\./Answer with exactly one word: PASS or FAIL./' prompts/judge.txt > j && mv j prompts/judge.txt
  ek_commit 'Demand a one-word verdict'
}

# ---------------------------------------------------------------- Lab 6.3
# main (you)                    : exact_match strips whitespace (edit in evalkit/metrics.py)
# refactor/scoring-module (Ravi): pure rename, evalkit/metrics.py -> evalkit/scoring.py
# refactor/score-objects (Ravi) : the same move plus a rewrite; only 39% of the content survives
m06_3_fixture() {
  ek_base || return 1
  ek_metrics_with_f1 && ek_commit 'Add token F1'
  git switch -q -c refactor/scoring-module
  as ravi
  git mv evalkit/metrics.py evalkit/scoring.py && ek_commit 'Rename the metrics module to scoring'
  git switch -q -c refactor/score-objects main
  git mv evalkit/metrics.py evalkit/scoring.py && ek_scoring_rewrite
  ek_commit 'Move metrics to scoring and return Score objects'
  as you
  git switch -q main
  sed -e 's/pred == gold/pred.strip() == gold.strip()/' evalkit/metrics.py > m && mv m evalkit/metrics.py
  ek_commit 'Ignore surrounding whitespace when comparing'
}

# ---------------------------------------------------------------- Lab 6.4
# main (you)                  : the legacy script gets --seed 7
# cleanup/remove-legacy (Ravi): deletes the legacy script and adds a make target instead
m06_4_fixture() {
  ek_base || return 1
  mkdir -p scripts
  printf '#!/bin/sh\npython -m evalkit --config config/eval.yaml\n' > scripts/legacy_eval.sh
  ek_commit 'Add the legacy eval script'
  git switch -q -c cleanup/remove-legacy
  as ravi
  git rm -q scripts/legacy_eval.sh
  printf 'eval:\n\tpython -m evalkit run --config config/eval.yaml\n' > Makefile
  ek_commit 'Replace the legacy eval script by a make target'
  as you
  git switch -q main
  printf '#!/bin/sh\npython -m evalkit --config config/eval.yaml --seed 7\n' > scripts/legacy_eval.sh
  ek_commit 'Run legacy evals with a fixed seed'
}

# ---------------------------------------------------------------- Lab 6.5
# main                          : two migrations and a check that migration numbers are unique
# feature/prompt-versions (Asha): adds migrations/0003_add_prompt_version.sql
# feature/latency (Ravi)        : adds migrations/0003_add_latency_ms.sql
m06_5_fixture() {
  ek_base || return 1
  mkdir -p migrations ci
  printf 'CREATE TABLE runs (id INTEGER PRIMARY KEY, model TEXT NOT NULL);\n' > migrations/0001_create_runs.sql
  printf 'CREATE TABLE scores (run_id INTEGER NOT NULL, metric TEXT NOT NULL, value REAL NOT NULL);\n' > migrations/0002_create_scores.sql
  cat > ci/check_migrations.sh <<'SH'
#!/bin/sh
# Stand-in for the migration tool: the number before the first underscore must be unique.
dupes=$(ls migrations | cut -d_ -f1 | sort | uniq -d)
if [ -n "$dupes" ]; then
  for number in $dupes; do
    echo "FAIL migration number $number is used by:" $(ls migrations | grep "^${number}_")
  done
  exit 1
fi
echo "OK $(ls migrations | wc -l | tr -d ' ') migrations, every number is unique"
SH
  ek_commit 'Add migrations and the migration-number check'
  git switch -q -c feature/prompt-versions
  as asha
  printf 'ALTER TABLE runs ADD COLUMN prompt_version TEXT;\n' > migrations/0003_add_prompt_version.sql
  ek_commit 'Record the prompt version of every run'
  git switch -q -c feature/latency main
  as ravi
  printf 'ALTER TABLE scores ADD COLUMN latency_ms INTEGER;\n' > migrations/0003_add_latency_ms.sql
  ek_commit 'Record judge latency per score'
  as you
  git switch -q main
}

# ---------------------------------------------------------------- Lab 6.6
# A main branch with four merges made by three people. One is clean and honest, one resolves a
# conflict honestly, one lost work through a whole-file "--theirs", one carries a smuggled change.
# Two documentation branches are left unmerged for the failure scenario (an octopus merge).
m06_6_fixture() {
  ek_base || return 1
  # Merge 1 (Asha): clean and honest.
  git switch -q -c topic/readme
  as ravi
  printf '# evalkit\n\nEvaluation harness for LLM outputs.\n' > README.md
  ek_commit 'Add a README'
  as you
  git switch -q main
  printf 'pyyaml>=6.0\n' > requirements.txt
  ek_commit 'Add requirements'
  as asha
  tick; git merge -q topic/readme
  # Merge 2 (you): a conflict in exact_match, resolved by combining both sides.
  git switch -q -c feature/case-insensitive
  sed -e 's/pred == gold/pred.lower() == gold.lower()/' evalkit/metrics.py > m && mv m evalkit/metrics.py
  ek_commit 'Compare answers case-insensitively'
  as you
  git switch -q main
  sed -e 's/pred == gold/pred.strip() == gold.strip()/' evalkit/metrics.py > m && mv m evalkit/metrics.py
  ek_commit 'Ignore surrounding whitespace when comparing'
  git merge -q feature/case-insensitive > /dev/null 2>&1
  ek_replace_conflict evalkit/metrics.py '    return float(pred.strip().lower() == gold.strip().lower())'
  ek_commit "Merge branch 'feature/case-insensitive'"
  # Merge 3 (Asha): a conflict on temperature, "resolved" with a whole-file --theirs.
  git switch -q -c feature/creative-judge
  as asha
  ek_set temperature 0.7 && ek_commit 'Raise temperature for judge diversity'
  as ravi
  git switch -q main
  ek_set temperature 0.0 && ek_commit 'Use temperature 0 for reproducible evals'
  ek_set retries 3 && ek_commit 'Retry the judge three times'
  as asha
  git merge -q feature/creative-judge > /dev/null 2>&1
  git checkout -q --theirs config/eval.yaml
  ek_commit "Merge branch 'feature/creative-judge'"
  # Merge 4 (Ravi): no conflict, plus a change that belongs to no branch.
  git switch -q -c topic/max-tokens
  ek_set max_tokens 1024 && ek_commit 'Allow 1024 output tokens'
  as you
  git switch -q main
  printf 'httpx>=0.27\n' >> requirements.txt
  ek_commit 'Add httpx for the judge client'
  as ravi
  git merge -q --no-commit topic/max-tokens > /dev/null 2>&1
  ek_set timeout_s 300
  ek_commit "Merge branch 'topic/max-tokens'"
  # Two small branches for the octopus merge of the failure scenario.
  as asha
  git switch -q -c docs/contributing main
  printf '# Contributing\n\nOpen a pull request against main.\n' > CONTRIBUTING.md
  ek_commit 'Add contributing notes'
  git switch -q -c docs/changelog main
  printf '# Changelog\n\n## Unreleased\n' > CHANGELOG.md
  ek_commit 'Start a changelog'
  as you
  git switch -q main
  printf '\nRun: python -m evalkit\n' >> README.md
  ek_commit 'Document how to run'
}

# ---------------------------------------------------------------- Lab 6.7
# main (you)                   : parse_verdict returns None for an unparseable verdict instead of raising
# feature/unsure-verdict (Asha): parse_verdict scores UNSURE as 0.5, and the prompt allows UNSURE
# feature/short-errors (Ravi)  : truncates the verdict in the error message (used in the failure scenario)
m06_7_fixture() {
  ek_base || return 1
  cat > evalkit/judge.py <<'PY'
def parse_verdict(text):
    text = text.strip().upper()
    if text.startswith("PASS"):
        return 1.0
    if text.startswith("FAIL"):
        return 0.0
    raise ValueError(f"unparseable verdict: {text!r}")
PY
  ek_commit 'Add the verdict parser'
  git switch -q -c feature/unsure-verdict
  as asha
  cat > evalkit/judge.py <<'PY'
def parse_verdict(text):
    text = text.strip().upper()
    if text.startswith("PASS"):
        return 1.0
    if text.startswith("FAIL"):
        return 0.0
    if text.startswith("UNSURE"):
        return 0.5
    raise ValueError(f"unparseable verdict: {text!r}")
PY
  ek_commit 'Score UNSURE verdicts as 0.5'
  sed -e 's/Answer with PASS or FAIL\./Answer with PASS, FAIL or UNSURE./' prompts/judge.txt > j && mv j prompts/judge.txt
  ek_commit 'Let the judge answer UNSURE'
  git switch -q -c feature/short-errors main
  as ravi
  sed -e 's/{text!r}/{text[:40]!r}/' evalkit/judge.py > j && mv j evalkit/judge.py
  ek_commit 'Truncate long verdicts in the error message'
  as you
  git switch -q main
  sed -e 's/    raise ValueError.*/    return None/' evalkit/judge.py > j && mv j evalkit/judge.py
  ek_commit 'Return None for unparseable verdicts instead of raising'
}

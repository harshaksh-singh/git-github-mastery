#!/usr/bin/env bash
# Exercise 11.9 (Level 4): a regression hidden inside a stretch of commits that cannot be tested.
# Builds the project "judgekit" in judgekit/. Read SYMPTOMS.md, not this file, before you start:
# the script is the answer to "which commit".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m11-judgekit

quiet 'git init judgekit'
cd judgekit || exit 1

printf '__pycache__/\n' > .gitignore
put README.md <<'F'
# judgekit

Measures how often an LLM judge agrees with human labels.

    python3 -B check_agreement.py
F
put judgekit/__init__.py <<'F'
"""judgekit: agreement between an LLM judge and human graders."""
F
put judgekit/parse.py <<'F'
"""Turn the judge's free-text output into a verdict."""


def parse_verdict(text):
    words = text.strip().split()
    first = words[0].rstrip(":.,") if words else ""
    return "pass" if first == "PASS" else "fail"
F
put judgekit/agree.py <<'F'
"""Agreement between judge verdicts and human labels."""

from judgekit.parse import parse_verdict


def agreement(rows):
    hits = sum(1 for human, output in rows if parse_verdict(output) == human)
    return hits / len(rows)
F
put data/golden.tsv <<'F'
pass	PASS: matches the reference
pass	PASS. Same entity, different wording
fail	FAIL: wrong year
fail	FAIL: hallucinated citation
pass	pass: correct
fail	PARTIALLY CORRECT: misses the second cause
fail	PARTIALLY CORRECT: right city, wrong country
fail	PARTIALLY CORRECT: unit is missing
pass	PASS: exact
fail	FAIL: refuses to answer
F
put check_agreement.py <<'F'
"""Print the judge's agreement with the human labels of the golden set."""

from judgekit.agree import agreement

rows = [line.rstrip("\n").split("\t") for line in open("data/golden.tsv")]
print("agreement %.2f" % agreement(rows))
F
_c 'Add judge agreement check with a golden set'
quiet "git tag -a v1.0.0 -m 'judgekit 1.0.0'"

as asha
put judgekit/client.py <<'F'
"""Client for the judge model."""


def ask(prompt, model="judge-large"):
    raise NotImplementedError("wired up in deployment")
F
_c 'Add judge client stub'
as ravi
printf '\nThe golden set lives in `data/golden.tsv`: human label, tab, judge output.\n' >> README.md
_c 'Describe the golden set format'
as you
put judgekit/prompts.py <<'F'
"""Prompt templates for the judge."""

GRADE = "Grade the answer against the reference. Start with PASS or FAIL.\n\nReference: {ref}\nAnswer: {ans}\n"
F
_c 'Add the grading prompt template'

as asha
quiet 'git mv judgekit/parse.py judgekit/verdict.py'
_c 'Move verdict parsing into judgekit/verdict.py'
as ravi
sed -e 's/return "pass" if first == "PASS" else "fail"/return "pass" if first.upper() == "PASS" else "fail"/' judgekit/verdict.py > v.tmp && mv v.tmp judgekit/verdict.py
_c 'Accept lowercase verdicts'
as asha
put judgekit/verdict.py <<'F'
"""Turn the judge's free-text output into a verdict."""


def parse_verdict(text):
    if text.strip().upper().startswith("PARTIALLY CORRECT"):
        return "pass"
    words = text.strip().split()
    first = words[0].rstrip(":.,") if words else ""
    return "pass" if first.upper() == "PASS" else "fail"
F
_c "Treat 'partially correct' as a pass"
as ravi
put judgekit/client.py <<'F'
"""Client for the judge model."""


def ask(prompt, model="judge-large", timeout=30):
    raise NotImplementedError("wired up in deployment")
F
_c 'Add timeout option to the judge client'
as you
sed -e 's/from judgekit.parse import/from judgekit.verdict import/' judgekit/agree.py > a.tmp && mv a.tmp judgekit/agree.py
_c 'Fix import after the verdict module move'

as ravi
quiet 'git switch -c feat/rubric'
put judgekit/rubric.py <<'F'
"""Rubric text shown to the judge."""

RUBRIC = ["Is the answer factually consistent with the reference?", "Does it answer the question that was asked?"]
F
_c 'Add a two-point rubric'
put judgekit/prompts.py <<'F'
"""Prompt templates for the judge."""

GRADE = "Grade the answer against the reference. Start with PASS or FAIL.\n\nReference: {ref}\nAnswer: {ans}\n"
GRADE_WITH_RUBRIC = "{rubric}\n\n" + GRADE
F
_c 'Add a prompt that carries the rubric'
as you
quiet 'git switch main'
printf '\nExit status of the check is always 0; read the number.\n' >> README.md
_c 'Say that the check always exits with 0'
quiet "git merge --no-ff feat/rubric -m \"Merge branch 'feat/rubric'\""
quiet 'git branch -d feat/rubric'
as asha
put judgekit/client.py <<'F'
"""Client for the judge model."""


def ask(prompt, model="judge-large", timeout=30, retries=2):
    raise NotImplementedError("wired up in deployment")
F
_c 'Add retries option to the judge client'
as you
quiet "git tag -a v1.1.0 -m 'judgekit 1.1.0'"

ex_end judgekit

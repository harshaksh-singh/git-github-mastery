# labs/ch28/fixture.bash - shared fixture for the Chapter 28 demos and the Module 33 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo: the file
# name does not end in .sh, so the build and verify tools skip it.
#
# The project is "docqa", a small service that classifies support tickets and answers them from
# documentation. Everything is standard-library Python: nothing is installed, and nothing talks
# to a network. The Python tools live in labs/ch28/files/ and are copied into each sandbox:
#   nbstrip.py   a notebook clean filter and CI check      (what nbstripout does, in 40 lines)
#   runinfo.py   records commit ID and dirty state         (what a tracker should record)
#   dataref.py   versions a data file by reference         (the idea behind DVC and Git LFS)
#   checks.py    repository checks for a hook and for CI   (what the pre-commit framework runs)
#   run_eval.py  a deterministic evaluation that writes a run record
#   make_notebook.py  writes the notebook as Jupyter would save it after run N

KIT="$LAB_SCRIPT_DIR/files"
# Keep Python from writing __pycache__ directories, so that every listing is the same everywhere.
export PYTHONDONTWRITEBYTECODE=1

hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

put() {
  mkdir -p "$(dirname "$1")" && cat > "$1" || { printf 'fixture: put failed: %s\n' "$1" >&2; exit 1; }
}

commit_all() {
  tick
  { git add -A && git commit -q -m "$1"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_all failed: %s\n' "$1" >&2; exit 1; }
}

require_ref() {
  git -C "$1" rev-parse --verify --quiet "$2" > /dev/null ||
    { printf 'fixture: expected ref %s in %s\n' "$2" "$1" >&2; exit 1; }
}

# ---------------------------------------------------------------- data versions
tickets_v1() {
  put "${1:-data/raw/tickets.csv}" <<'CSV'
text,label
"I was charged twice for my invoice",billing
"Please refund the annual plan",billing
"The app shows an error on login",technical
"Upload fails with a timeout",technical
"How do I invite a teammate?",general
"Where can I download my invoice?",billing
"The export job will crash every night",technical
"Can I change the workspace name?",general
"My card was declined",billing
"The dashboard is slow since Monday",technical
CSV
}

tickets_v2() {
  tickets_v1 "${1:-data/raw/tickets.csv}"
  cat >> "${1:-data/raw/tickets.csv}" <<'CSV'
"I need a receipt for last month",billing
"Sync stopped working after the update",technical
"Do you offer a student discount?",billing
"What are your support hours?",general
CSV
}

# ---------------------------------------------------------------- project files
ignore_file() {
  put .gitignore <<'IGN'
# Python (a subset of GitHub's Python template)
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.ruff_cache/
build/
dist/
*.egg-info/

# Secrets and machine-local settings
.env
.env.*
!.env.example

# Data is versioned by reference: only pointers and the README are tracked
/data/**
!/data/**/
!/data/**/*.ref
!/data/README.md

# Model weights live in the model store, whatever directory they land in
/models/**
!/models/README.md
!/models/*.ref
*.pt
*.pth
*.ckpt
*.safetensors
*.onnx
*.gguf

# Experiment trackers and run outputs
/runs/
wandb/
mlruns/
mlflow.db
outputs/
multirun/

# Notebook autosave copies
.ipynb_checkpoints/
IGN
}

attributes_file() {
  put .gitattributes <<'ATTR'
# Line endings: normalize text to LF in the repository on every platform
* text=auto
*.sh text eol=lf

# Notebooks enter the repository without outputs (driver: tools/nbstrip.py, see README)
*.ipynb filter=nbstrip

# Pointer files must never be converted or merged line by line
*.ref text eol=lf merge=binary
ATTR
}

package_files() {
  put pyproject.toml <<'TOML'
[project]
name = "docqa"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = []
TOML
  put requirements.lock <<'LOCK'
# Lock file. This lab project has no third-party dependencies, so the list is empty.
# In a real project this file is uv.lock (or an equivalent with hashes) and is committed.
LOCK
  put src/docqa/__init__.py <<'PY'
"""docqa: classify support tickets and answer them from documentation."""
PY
  put src/docqa/classify.py <<'PY'
def classify(text, keywords, default):
    """Return the first label whose keyword occurs in the text."""
    text = text.lower()
    for label, words in keywords.items():
        if any(word in text for word in words):
            return label
    return default
PY
  put tests/test_classify.py <<'PY'
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from docqa.classify import classify  # noqa: E402

KEYWORDS = {"billing": ["invoice"], "technical": ["error"]}


class ClassifyTest(unittest.TestCase):
    def test_keyword(self):
        self.assertEqual(classify("Invoice missing", KEYWORDS, "general"), "billing")

    def test_default(self):
        self.assertEqual(classify("Hello", KEYWORDS, "general"), "general")


if __name__ == "__main__":
    unittest.main()
PY
  put README.md <<'MD'
# docqa

Classifies support tickets and answers them from documentation.

## After cloning

Git does not activate filters or hooks from a clone. Run once:

    git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
    git config set filter.nbstrip.smudge cat
    git config set filter.nbstrip.required true
    git config set core.hooksPath hooks
    python3 tools/dataref.py checkout

## Layout

    src/docqa/   importable package      tests/     unit tests
    configs/     evaluation settings     prompts/   prompt templates, versioned like code
    evals/       evaluation entry point  notebooks/ exploration, committed without outputs
    data/        pointers only           models/    pointers only
    tools/       repository tooling      hooks/     shared Git hooks
    ci/          what CI runs            runs/      local run outputs, ignored
MD
}

checks_files() {
  mkdir -p tools hooks ci
  cp "$KIT/checks.py" tools/checks.py
  put hooks/pre-commit <<'SH'
#!/bin/sh
# Shared pre-commit hook. Enable it once per clone: git config set core.hooksPath hooks
exec python3 tools/checks.py --staged
SH
  put ci/check.sh <<'SH'
#!/bin/sh
# Everything CI runs, runnable locally: sh ci/check.sh <base>
# <base> is the commit the branch started from (default: origin/main).
status=0
# 1. Every file version the branch adds, including ones a later commit removed again.
python3 tools/checks.py --range "${1:-origin/main}..HEAD" || status=1
# 2. The whole snapshot that would be merged.
python3 tools/checks.py --tree HEAD || status=1
if python3 -m unittest discover -s tests > /dev/null 2>&1; then echo "tests: ok"; else echo "tests: FAILED"; status=1; fi
exit $status
SH
  chmod +x hooks/pre-commit ci/check.sh
}

notebook_files() {
  mkdir -p tools notebooks
  cp "$KIT/nbstrip.py" tools/nbstrip.py
  python3 "$KIT/make_notebook.py" "${1:-1}" > notebooks/01-error-analysis.ipynb
}

data_files() {
  mkdir -p tools
  cp "$KIT/dataref.py" tools/dataref.py
  put data/README.md <<'MD'
# Data

The files in this directory are not in Git. Each `<file>.ref` is a pointer with the SHA-256
and size of the data file it stands for; the bytes are in the data store.

    python3 tools/dataref.py checkout     # fetch the versions this commit points at
    python3 tools/dataref.py verify       # compare what is on disk with the pointers
    python3 tools/dataref.py add FILE     # record a new version, then commit FILE.ref
MD
}

eval_files() {
  mkdir -p tools evals
  cp "$KIT/runinfo.py" tools/runinfo.py
  cp "$KIT/run_eval.py" evals/run_eval.py
  put configs/eval.json <<'JSON'
{
  "data": "data/raw/tickets.csv",
  "default": "general",
  "keywords": {
    "billing": ["invoice", "refund", "charged"],
    "technical": ["error", "crash", "timeout"]
  }
}
JSON
  put prompts/answer.v1.txt <<'TXT'
You answer support tickets for the product team.
Use only the documentation excerpts below. If they do not contain the answer, say so.

Ticket: {ticket}
Excerpts: {excerpts}
TXT
}

serving_files() {
  put Dockerfile <<'DOCKER'
# Serving image. Not built in this lab.
# Pass a base image pinned by digest:  --build-arg BASE_IMAGE=<name>@sha256:<digest>
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
WORKDIR /app
COPY requirements.lock pyproject.toml ./
COPY src ./src
COPY configs ./configs
COPY prompts ./prompts
# Weights are fetched by pinned reference at build or start time, never copied from Git.
# A token, if one is needed, comes from a secret mount, not from ARG or ENV:
#   RUN --mount=type=secret,id=model_token python3 -m docqa.fetch_model
CMD ["python3", "-m", "docqa"]
DOCKER
  put .dockerignore <<'IGN'
.git
.env
data
runs
notebooks
IGN
  put models/README.md <<'MD'
# Models

Weights are not in Git. `<file>.ref` pointers record the SHA-256 of each weights file;
`python3 tools/dataref.py checkout` fetches them from the store.
MD
}

# nbfilter_config: the three settings a clone needs for the notebook filter.
nbfilter_config() {
  hidden 'git config set filter.nbstrip.clean "python3 tools/nbstrip.py"'
  hidden 'git config set filter.nbstrip.smudge cat'
  hidden 'git config set filter.nbstrip.required true'
}

# fx_kit: the finished tree of the project as plain files in ./kit (no repository), for the
# hands-on Lab 33.1, plus the data store directory. Leaves you in $LAB_DIR.
fx_kit() {
  mkdir -p kit datastore
  ( cd kit || exit 1
    ignore_file; attributes_file; package_files; checks_files; notebook_files 1
    data_files; tickets_v1; eval_files; serving_files
    python3 -c "import sys; sys.stdout.buffer.write(bytes(range(256)) * 256)" > models/embedder.bin ) || exit 1
}

# fx_docqa [stage]: the docqa repository built commit by commit, with a data store beside it.
# stage is the number of the last commit to make (default 7, the finished project):
#   1 ignore rules and attributes   2 package, lock file, tests   3 checks, hook, CI entry point
#   4 notebook filter and notebook  5 data by reference           6 evaluation and run record
#   7 serving files and model pointer, tag v0.1.0
# Leaves you inside docqa.
fx_docqa() {
  local stage="${1:-7}"
  hidden 'mkdir datastore'
  hidden 'git init docqa'
  cd docqa || exit 1
  ignore_file; attributes_file
  commit_all 'Add ignore rules and attributes before any content'
  [ "$stage" -ge 2 ] || return 0
  package_files
  commit_all 'Add package skeleton, lock file and tests'
  [ "$stage" -ge 3 ] || return 0
  checks_files
  commit_all 'Add repository checks, shared hook and CI entry point'
  hidden 'git config set core.hooksPath hooks'
  [ "$stage" -ge 4 ] || return 0
  notebook_files 1
  nbfilter_config
  commit_all 'Add notebook filter and the error-analysis notebook'
  [ "$stage" -ge 5 ] || return 0
  data_files
  tickets_v1
  hidden 'python3 tools/dataref.py add data/raw/tickets.csv'
  commit_all 'Version the ticket data set by reference'
  [ "$stage" -ge 6 ] || return 0
  eval_files
  commit_all 'Add evaluation config, prompt and run recorder'
  [ "$stage" -ge 7 ] || return 0
  serving_files
  python3 -c "import sys; sys.stdout.buffer.write(bytes(range(256)) * 256)" > models/embedder.bin
  hidden 'python3 tools/dataref.py add models/embedder.bin'
  commit_all 'Add serving image definition and model pointer'
  hidden 'git tag -a v0.1.0 -m "docqa 0.1.0"'
}

# ---------------------------------------------------------------- lab starting states
# fx_lab_33_2: docqa with tooling and evaluation committed, and the ticket data set on disk
# but not yet versioned. Leaves you inside docqa.
fx_lab_33_2() {
  fx_docqa 4
  data_files
  eval_files
  commit_all 'Add data-by-reference tool, evaluation config and run recorder'
  tickets_v1
}

# fx_lab_33_3: the finished project, two recorded runs in ../tracker (one from a clean tree at
# v0.1.0 and one from a dirty tree), and a history that has moved on since: new data, new
# keywords. Leaves you inside docqa.
fx_lab_33_3() {
  fx_docqa 7
  hidden 'mkdir ../tracker'
  hidden 'python3 evals/run_eval.py baseline'
  hidden "sed -i.bak 's/\"charged\"/\"charged\", \"card\"/' configs/eval.json && rm configs/eval.json.bak"
  hidden 'python3 evals/run_eval.py tuned --allow-dirty'
  hidden 'git restore configs/eval.json'
  hidden 'mv runs/baseline runs/tuned ../tracker/ && rmdir runs'
  tickets_v2
  hidden 'python3 tools/dataref.py add data/raw/tickets.csv'
  commit_all 'Add four labelled tickets to the data set'
  hidden "sed -i.bak 's/\"timeout\"/\"timeout\", \"slow\", \"sync\"/' configs/eval.json && rm configs/eval.json.bak"
  commit_all 'Add slow and sync as technical keywords'
}

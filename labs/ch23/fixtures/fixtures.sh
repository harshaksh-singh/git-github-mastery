#!/usr/bin/env bash
# labs/ch23/fixtures/fixtures.sh
# Hidden setup shared by the Chapter 23 demos, the Module 15 lab replays (15.1 and 15.2) and their
# hands-on setup scripts. Source it after lab-env.sh:   . "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
# Every fx_* function expects the current directory to be the sandbox ($LAB_DIR) and leaves you there,
# unless its comment says otherwise. All commits use the pinned lab clock, so replays and hands-on
# sandboxes start from identical commit IDs.
#
# The cast:
#   remotes/textsplit.git   shared repository of "textsplit", a small text-chunking library (Asha maintains it)
#   remotes/doc-qa.git      shared repository of "doc-qa", a document question-answering service (your team)
#   asha-textsplit/         Asha's clone of the library
#   doc-qa/                 your clone of the service
#   ravi-doc-qa/            Ravi's clone of the service (created by fx_ravi_clone)
#
# The submodule URL recorded in .gitmodules is the relative URL ../textsplit.git. A relative URL is
# resolved against the superproject's own remote, so .gitmodules does not contain a machine-specific
# path and the commit IDs stay identical on every machine.

# Local path remotes use Git's "file" transport. Since Git 2.38.1 the submodule machinery refuses that
# transport unless protocol.file.allow says otherwise (Chapter 23, section 23.4). The demos pass this
# option on the command line of each command that needs it; hidden setup uses the same option.
FILE_OK='-c protocol.file.allow=always'

put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }
commit_all() { tick; git add -A > /dev/null 2>&1 && git commit -q -m "$1" > /dev/null 2>&1; }

handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

_splitter_v1() {
  put splitter.py <<'PY'
def split(text, size=200):
    """Cut text into pieces of at most `size` characters."""
    return [text[i:i + size] for i in range(0, len(text), size)]
PY
}

_splitter_v2() {
  put splitter.py <<'PY'
def split(text, size=200, overlap=0):
    """Cut text into pieces of at most `size` characters; neighbours share `overlap` characters."""
    step = size - overlap
    return [text[i:i + size] for i in range(0, len(text), step)]
PY
}

_splitter_v3() {
  put splitter.py <<'PY'
def split(text, size=200, overlap=0):
    """Cut text into pieces of at most `size` characters; neighbours share `overlap` characters."""
    if overlap >= size:
        raise ValueError("overlap must be smaller than size")
    step = size - overlap
    return [text[i:i + size] for i in range(0, len(text), step)]
PY
}

# fx_textsplit: the library. remotes/textsplit.git with two commits and the tag v0.1.0 on the first;
# asha-textsplit is Asha's clone, on main, in sync with the remote.
fx_textsplit() {
  mkdir -p remotes
  quiet 'git init --bare remotes/textsplit.git'
  quiet 'git clone remotes/textsplit.git asha-textsplit'
  cd asha-textsplit || return 1
  as asha
  _splitter_v1
  put README.md <<'MD'
# textsplit

Split long documents into chunks for retrieval.
MD
  commit_all 'Add fixed-size splitter'
  tick; git tag -a v0.1.0 -m 'textsplit 0.1.0' > /dev/null 2>&1
  _splitter_v2
  commit_all 'Add overlap between neighbouring chunks'
  quiet 'git push origin main --tags'
  as you
  cd "$LAB_DIR" || return 1
}

# fx_textsplit_release: Asha publishes one more commit (input validation) and tags it v0.2.0.
fx_textsplit_release() {
  cd "$LAB_DIR/asha-textsplit" || return 1
  as asha
  _splitter_v3
  commit_all 'Reject an overlap that is not smaller than the chunk size'
  tick; git tag -a v0.2.0 -m 'textsplit 0.2.0' > /dev/null 2>&1
  quiet 'git push origin main --tags'
  as you
  cd "$LAB_DIR" || return 1
}

# fx_docqa: the service without any dependency yet. remotes/doc-qa.git and your clone doc-qa, in sync.
fx_docqa() {
  mkdir -p remotes
  quiet 'git init --bare remotes/doc-qa.git'
  quiet 'git clone remotes/doc-qa.git doc-qa'
  cd doc-qa || return 1
  put ingest.py <<'PY'
from pathlib import Path


def load(path):
    return Path(path).read_text(encoding="utf-8")
PY
  put README.md <<'MD'
# doc-qa

Answers questions about a set of documents.
MD
  commit_all 'Add document loader'
  put answer.py <<'PY'
def answer(question, chunks):
    return max(chunks, key=lambda c: sum(w in c for w in question.split()))
PY
  commit_all 'Add keyword answerer'
  quiet 'git push -u origin main'
  cd "$LAB_DIR" || return 1
}

# fx_docqa_submodule: fx_textsplit + fx_docqa, then textsplit is added to doc-qa as a submodule at
# vendor/textsplit, committed and pushed. Leaves you in the sandbox.
fx_docqa_submodule() {
  fx_textsplit
  fx_docqa
  cd doc-qa || return 1
  quiet "git $FILE_OK submodule add ../textsplit.git vendor/textsplit"
  put ingest.py <<'PY'
from pathlib import Path

from vendor.textsplit.splitter import split


def load(path):
    return Path(path).read_text(encoding="utf-8")


def chunks(path):
    return split(load(path), size=400, overlap=40)
PY
  commit_all 'Vendor textsplit as a submodule and chunk documents'
  quiet 'git push origin main'
  cd "$LAB_DIR" || return 1
}

# fx_ravi_clone: Ravi's clone of doc-qa with the submodule initialised and checked out.
fx_ravi_clone() {
  quiet "git $FILE_OK clone --recurse-submodules remotes/doc-qa.git ravi-doc-qa"
}

# fx_docqa_subtree_start: fx_textsplit + fx_docqa only. The subtree demos add the library themselves.
fx_docqa_subtree_start() {
  fx_textsplit
  fx_docqa
}

# lib_commit_line_splitter: inside a checkout of textsplit (current directory), add a line splitter
# and commit it. The identity is whoever is active.
lib_add_line_splitter() {
  printf '\n\ndef split_lines(text):\n    """One chunk per non-empty line."""\n    return [line for line in text.splitlines() if line.strip()]\n' >> splitter.py
}

# fx_textsplit_tokens_branch: Asha publishes a second line of development, feature/tokens, that
# branches off before the 0.2.0 release. Call it before fx_textsplit_release for a real fork.
fx_textsplit_tokens_branch() {
  cd "$LAB_DIR/asha-textsplit" || return 1
  as asha
  quiet 'git switch -c feature/tokens'
  printf '\n\ndef split_tokens(text):\n    """One chunk per whitespace-separated token."""\n    return text.split()\n' >> splitter.py
  commit_all 'Add token splitter'
  quiet 'git push origin feature/tokens'
  quiet 'git switch main'
  as you
  cd "$LAB_DIR" || return 1
}

# fx_textsplit_merge_tokens: Asha merges feature/tokens into main and publishes the merge.
fx_textsplit_merge_tokens() {
  cd "$LAB_DIR/asha-textsplit" || return 1
  as asha
  tick; git merge -q --no-ff -m 'Merge feature/tokens' feature/tokens > /dev/null 2>&1
  quiet 'git push origin main'
  as you
  cd "$LAB_DIR" || return 1
}

# fx_textsplit_release_prepared: Asha has the 0.2.0 commit and tag in her clone but has not pushed
# them. A lab then "plays Asha" with:  git -C ../asha-textsplit push origin main --tags
fx_textsplit_release_prepared() {
  cd "$LAB_DIR/asha-textsplit" || return 1
  as asha
  _splitter_v3
  commit_all 'Reject an overlap that is not smaller than the chunk size'
  tick; git tag -a v0.2.0 -m 'textsplit 0.2.0' > /dev/null 2>&1
  as you
  cd "$LAB_DIR" || return 1
}

# lib_add_paragraph_splitter: inside a directory that holds splitter.py, add a paragraph splitter.
lib_add_paragraph_splitter() {
  printf '\n\ndef split_paragraphs(text):\n    """One chunk per paragraph."""\n    return [p for p in text.split("\\n\\n") if p.strip()]\n' >> splitter.py
}

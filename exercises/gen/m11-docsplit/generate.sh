#!/usr/bin/env bash
# Practice repository for the Module 11 exercises 11.1 to 11.8 (history investigation).
# Builds the project "docsplit" in the directory docsplit/: a library that cuts documents into
# chunks for a retrieval pipeline. Three authors, three tags, one merged feature branch, one merge
# whose resolution threw a change away, and one unmerged branch with a cherry-picked commit.
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m11-docsplit

quiet 'git init docsplit'
cd docsplit || exit 1

# ---- Monday
put README.md <<'F'
# docsplit

Cuts documents into chunks for retrieval.
F
put docsplit/__init__.py <<'F'
"""docsplit: document chunking for retrieval pipelines."""
F
_c 'Add project skeleton'

put docsplit/split.py <<'F'
"""Splitters."""


def split_paragraphs(text):
    parts = text.split("\n\n")
    return [p.strip() for p in parts[1:] if p.strip()]
F
_c 'Add paragraph splitter'

as asha
put docsplit/config.py <<'F'
"""Chunking defaults."""

CHUNK_SIZE = 400
OVERLAP = 40
MIN_CHARS = 20
F
put configs/legacy.yaml <<'F'
# Read by the old batch job only.
chunk_size: 400
overlap: 40
F
_c 'Add chunk configuration'

as ravi
put docsplit/split.py <<'F'
"""Splitters."""

from docsplit.config import CHUNK_SIZE, OVERLAP


def split_paragraphs(text):
    parts = text.split("\n\n")
    return [p.strip() for p in parts[1:] if p.strip()]


def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
    step = size - overlap
    chunks = []
    for start in range(0, len(tokens) - size + 1, step):
        chunks.append(tokens[start:start + size])
    return chunks
F
_c 'Add sliding window over tokens'

as you
put docsplit/clean.py <<'F'
"""Text cleaning."""


def clean(text):
    while "  " in text:
        text = text.replace("  ", " ")
    return text.strip()
F
_c 'Add whitespace cleaner'
quiet "git tag -a v0.1.0 -m 'docsplit 0.1.0'"

# ---- Tuesday
skip_ticks 1380
as asha
put docsplit/config.py <<'F'
"""Chunking defaults."""

CHUNK_SIZE = 512
OVERLAP = 40
MIN_CHARS = 20
F
_c 'Raise chunk size to 512'

as ravi
quiet 'git switch -c feat/sentence-split'
put docsplit/sentences.py <<'F'
"""Sentence splitting."""


def split_sentences(text):
    return [s.strip() for s in text.split(". ") if s.strip()]
F
_c 'Add sentence splitter'
put docsplit/sentences.py <<'F'
"""Sentence splitting."""

ABBREVIATIONS = ("e.g.", "i.e.", "Dr.", "No.")


def split_sentences(text):
    for abbr in ABBREVIATIONS:
        text = text.replace(abbr + " ", abbr.replace(".", "\0") + " ")
    return [s.replace("\0", ".").strip() for s in text.split(". ") if s.strip()]
F
_c 'Handle abbreviations in the sentence splitter'

as you
quiet 'git switch main'
put docsplit/split.py <<'F'
"""Splitters."""

from docsplit.config import CHUNK_SIZE, OVERLAP


def split_paragraphs(text):
    parts = text.split("\n\n")
    return [p.strip() for p in parts[1:] if p.strip()]


def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
    step = size - overlap
    chunks = []
    for start in range(0, len(tokens), step):
        chunks.append(tokens[start:start + size])
        if start + size >= len(tokens):
            break
    return chunks
F
quiet "git add -A && git commit -m 'Keep the tail in the last window' -m 'A document shorter than one window produced no chunk at all, and the last tokens of every longer document were dropped. The final window may now be shorter than size.'"
quiet "git merge --no-ff feat/sentence-split -m \"Merge branch 'feat/sentence-split'\""
quiet 'git branch -d feat/sentence-split'

as asha
put docsplit/config.py <<'F'
"""Chunking defaults."""

MIN_CHARS = 20
OVERLAP = 40
CHUNK_SIZE = 512
F
_c 'Sort the configuration constants'
as you
quiet "git tag -a v0.2.0 -m 'docsplit 0.2.0'"

# ---- Wednesday
skip_ticks 1380
as ravi
put docsplit/config.py <<'F'
"""Chunking defaults."""

MIN_CHARS = 20
OVERLAP = 32
CHUNK_SIZE = 512
F
_c 'Reduce overlap to 32'
put docsplit/split.py <<'F'
"""Splitters."""

from docsplit.config import CHUNK_SIZE, OVERLAP


def split_paragraphs(text):
    parts = text.split("\n\n")
    return [p.strip() for p in parts[1:] if p.strip()]


def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
    step = size - overlap
    return [tokens[start:start + size] for start in range(0, len(tokens) - size + 1, step)]
F
_c 'Simplify the window loop'

as asha
quiet 'git switch -c fix/clean-tabs'
put docsplit/clean.py <<'F'
"""Text cleaning."""


def clean(text):
    text = text.replace("\t", " ")
    while "  " in text:
        text = text.replace("  ", " ")
    return text.strip()
F
_c 'Collapse tabs in the cleaner'

as you
quiet 'git switch main'
put docsplit/clean.py <<'F'
"""Text cleaning."""

import re

_SPACES = re.compile(" +")


def clean(text):
    return _SPACES.sub(" ", text).strip()
F
_c 'Rewrite the cleaner with one regular expression'
quiet 'git rm -q configs/legacy.yaml'
_c 'Drop the legacy YAML configuration'

as ravi
quiet 'git switch -c feat/markdown'
put docsplit/markdown.py <<'F'
"""Markdown-aware splitting."""


def split_headings(text):
    sections, current = [], []
    for line in text.splitlines():
        if line.startswith("#") and current:
            sections.append("\n".join(current))
            current = []
        current.append(line)
    if current:
        sections.append("\n".join(current))
    return sections
F
_c 'Add Markdown heading splitter'
put README.md <<'F'
# docsplit

Cuts documents into chunks for retrieval.

Markdown files are split at headings first, see `docsplit/markdown.py`.
F
_c 'Document the Markdown splitter'
sed -e 's/parts\[1:\]/parts/' docsplit/split.py > split.tmp && mv split.tmp docsplit/split.py
_c 'Fix off-by-one in paragraph splitter'
fix=$(git rev-parse HEAD)

# ---- Thursday
skip_ticks 1380
as you
quiet 'git switch main'
quiet "git cherry-pick $fix"

as asha
put docsplit/window.py <<'F'
"""Sliding windows over a token list."""

from docsplit.config import CHUNK_SIZE, OVERLAP


def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
    step = size - overlap
    return [tokens[start:start + size] for start in range(0, len(tokens) - size + 1, step)]
F
put docsplit/split.py <<'F'
"""Splitters."""


def split_paragraphs(text):
    parts = text.split("\n\n")
    return [p.strip() for p in parts if p.strip()]
F
_c 'Move window into its own module'

as you
quiet 'git merge fix/clean-tabs'                     # conflict in docsplit/clean.py
quiet 'git checkout --ours docsplit/clean.py && git add docsplit/clean.py'
quiet "git commit -m \"Merge branch 'fix/clean-tabs'\""
quiet 'git branch -d fix/clean-tabs'

as asha
put README.md <<'F'
# docsplit

Cuts documents into chunks for retrieval.

The defaults are 512 tokens per chunk with an overlap of 32, see `docsplit/config.py`.
F
_c 'Document chunk sizes in the README'
as you
quiet "git tag -a v0.3.0 -m 'docsplit 0.3.0'"

put docsplit/__main__.py <<'F'
"""Command line: python3 -m docsplit FILE"""

import sys

from docsplit.split import split_paragraphs

for paragraph in split_paragraphs(open(sys.argv[1]).read()):
    print(paragraph)
    print("---")
F
_c 'Add a command-line entry point'

ex_end docsplit

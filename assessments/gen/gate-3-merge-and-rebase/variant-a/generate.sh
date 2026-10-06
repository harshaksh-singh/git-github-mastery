#!/usr/bin/env bash
# Gate 3 (Merge and rebase), hands-on part, variant A: the project "chunker".
# Builds server.git, asha/ and you/. In you/ a rebase of feature/overlap onto main has stopped
# at a conflict; the branch also carries a fixup commit and a fix that a release branch needs.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g3-a
gate_begin g3-a

gate_server
gate_clone you
cd you || exit 1
mkdir -p chunker tests
cat > chunker/split.py <<'PY'
def split(text, size=200):
    """Split text into chunks of at most size characters."""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + size])
        start += size
    return chunks
PY
_c 'Add fixed-size splitter'
printf 'def window_end(start, size, total):\n    return min(start + size + 1, total)\n' > chunker/window.py
_c 'Add window helper'
quiet 'git push -u origin main'
quiet 'git branch release/1.2'
quiet 'git push -u origin release/1.2'

quiet 'git switch -c feature/overlap main'
cat > chunker/split.py <<'PY'
def split(text, size=200, overlap=0):
    """Split text into chunks of at most size characters."""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + size])
        start += size - overlap
    return chunks
PY
_c 'Add overlap to the splitter'
printf 'def window_end(start, size, total):\n    return min(start + size, total)\n' > chunker/window.py
_c 'Fix off-by-one in window end'
printf 'from chunker.split import split\n\ndef test_overlap_repeats_the_tail():\n    assert split("abcdef", 4, overlap=2) == ["abcd", "cdef", "ef"]\n' > tests/test_split.py
quiet 'git add -A && git commit -m "fixup! Add overlap to the splitter"'
cd "$LAB_DIR" || exit 1

# Asha renames the parameter on main.
gate_clone asha
cd asha || exit 1
as asha
cat > chunker/split.py <<'PY'
def split(text, max_len=512):
    """Split text into chunks of at most max_len characters."""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + max_len])
        start += max_len
    return chunks
PY
_c 'Rename size to max_len and raise the default'
printf '# chunker\n\nSplits documents into chunks for the retriever.\n' > README.md
_c 'Add README'
quiet 'git push origin main'
gate_note main "$(git rev-parse main)"
gate_note release "$(git rev-parse origin/release/1.2)"

# You update main and start the rebase. It stops at the first commit.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'
quiet 'git switch main'
quiet 'git merge --ff-only origin/main'
quiet 'git switch feature/overlap'
quiet 'git rebase main'

gate_end
gate_ready

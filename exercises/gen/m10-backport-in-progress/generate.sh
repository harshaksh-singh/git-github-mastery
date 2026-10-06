#!/usr/bin/env bash
# Exercise 10.9 (Level 4): a backport that stopped at its second commit.
# Builds the repository vocab-service/ in the middle of a cherry-pick of three commits.
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m10-backport-in-progress
ex_begin m10-backport-in-progress

quiet 'git init vocab-service'
cd vocab-service || exit 1
mkdir -p svc
printf 'def tokenize(text):\n    return text.split()\n' > svc/tokenize.py
printf 'MAX_INPUT = 4096\n' > svc/limits.py
_c 'Add tokenizer service'

# The 3.2 release line, with one release-only change.
quiet 'git switch -c release/3.2'
printf 'MAX_INPUT = 2048\n' > svc/limits.py
_c 'Lower the input limit for the 3.2 line'
ex_note release_base "$(git rev-parse HEAD)"

# main: features and security fixes, interleaved.
quiet 'git switch main'
printf 'def stream(text):\n    for token in text.split():\n        yield token\n' > svc/stream.py
_c 'Add streaming endpoint'
printf 'def tokenize(text):\n    if "\\x00" in text:\n        raise ValueError("NUL byte in input")\n    return text.split()\n' > svc/tokenize.py
_c 'Security: reject NUL bytes in the input'
printf 'def batch(texts):\n    return [t.split() for t in texts]\n' > svc/batch.py
_c 'Add batch endpoint'
printf 'MAX_INPUT = 4096\n\ndef check(text):\n    if len(text) > MAX_INPUT:\n        raise ValueError("input too long")\n' > svc/limits.py
_c 'Security: cap the input length before tokenizing'
printf 'def tokenize(text):\n    if "\\x00" in text:\n        raise ValueError("NUL byte in input")\n    text = "".join(ch for ch in text if ch.isprintable() or ch.isspace())\n    return text.split()\n' > svc/tokenize.py
_c 'Security: strip control characters'

# Ravi starts the backport of the three security fixes and has to leave at the first conflict.
as ravi
quiet 'git switch release/3.2'
s1=$(git log --format=%H -1 --grep='reject NUL bytes' main)
s2=$(git log --format=%H -1 --grep='cap the input length' main)
s3=$(git log --format=%H -1 --grep='strip control characters' main)
quiet "git cherry-pick -x $s1 $s2 $s3"

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"

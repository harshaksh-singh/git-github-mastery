#!/usr/bin/env bash
# Final test, practical lab "recovery" (section 7): the project "chunkstore".
# Builds one repository in which a branch and a stash entry were deleted and every reflog was
# emptied afterwards. Read TASK.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final recovery
final_begin recovery

quiet 'git init chunkstore'
cd chunkstore || exit 1
mkdir -p config
printf 'def chunks(text, size, overlap):\n    step = size - overlap\n    return [text[i:i + size] for i in range(0, len(text), step)]\n' > chunker.py
printf 'size: 512\noverlap: 64\n' > config/chunking.yaml
_c 'Add the fixed-size chunker'
printf 'def store(chunk, index):\n    index.add(chunk.id, chunk.vector)\n' > store.py
_c 'Add the chunk store'
printf '# chunkstore\n\nSplits documents into chunks and stores them.\n' > README.md
_c 'Add README'
final_note main "$(git rev-parse HEAD)"

quiet 'git switch -c spike/semantic-overlap'
printf 'def sentences(text):\n    return [s.strip() for s in text.split(".") if s.strip()]\n' > sentences.py
_c 'Split text into sentences'
printf 'def overlap_by_sentence(sents, n):\n    return [sents[max(i - n, 0):i + 1] for i in range(len(sents))]\n' > semantic.py
_c 'Overlap chunks by whole sentences'
printf 'def overlap_by_sentence(sents, n):\n    if n < 0:\n        raise ValueError("n must not be negative")\n    return [sents[max(i - n, 0):i + 1] for i in range(len(sents))]\n' > semantic.py
_c 'Reject a negative sentence overlap'
final_note spike "$(git rev-parse HEAD)"

quiet 'git switch main'
printf 'size: 512\noverlap: 128\nmin_chunk: 32\n' > config/chunking.yaml
quiet 'git stash push -m "overlap 128 with a minimum chunk"'
# The "cleanup" at the end of the week.
quiet 'git stash drop'
quiet 'git branch -D spike/semantic-overlap'
quiet 'git reflog expire --expire=now --all'

final_end
final_ready

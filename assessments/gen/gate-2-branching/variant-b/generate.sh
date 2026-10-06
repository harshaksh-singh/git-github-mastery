#!/usr/bin/env bash
# Gate 2 (Branching), hands-on part, variant B (retake): the project "ingestd".
# Builds server.git and the clones you/ and asha/. In you/: a fetch that fails on a name
# conflict between refs, and work committed on a detached HEAD.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g2-b
gate_begin g2-b

gate_server
gate_clone you
cd you || exit 1
mkdir -p ingestd
printf 'def read_events(stream):\n    for line in stream:\n        yield line.rstrip("\\n")\n' > ingestd/reader.py
_c 'Add event reader'
printf 'def write_batch(sink, events):\n    sink.write("\\n".join(events))\n' > ingestd/writer.py
_c 'Add batch writer'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1

gate_clone asha
cd asha || exit 1
as asha
quiet 'git switch -c hotfix'
printf 'def write_batch(sink, events):\n    if events:\n        sink.write("\\n".join(events))\n' > ingestd/writer.py
_c 'Do not write empty batches'
quiet 'git push -u origin hotfix'
quiet 'git switch -c feature/dedupe-window main'
printf 'WINDOW_S = 300\n' > ingestd/dedupe.py
_c 'Add dedupe window setting'
quiet 'git push -u origin feature/dedupe-window'

cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'
# You start working on Asha's branch by checking out the remote-tracking branch.
quiet 'git checkout origin/feature/dedupe-window'
printf 'WINDOW_S = 300\n\ndef seen_recently(cache, key, now):\n    t = cache.get(key)\n    return t is not None and now - t < WINDOW_S\n' > ingestd/dedupe.py
_c 'Add seen_recently'
printf 'from ingestd.dedupe import seen_recently\n\ndef test_unknown_key_is_new():\n    assert not seen_recently({}, "k", 1000)\n' > test_dedupe.py
_c 'Test seen_recently on an unknown key'
gate_note yours "$(git rev-parse HEAD)"

# Asha: the hotfix lands, the branch "hotfix" is deleted and replaced by a namespace; one more
# commit goes to the shared feature branch.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git switch main'
quiet 'git merge --ff-only hotfix'
quiet 'git push origin main'
quiet 'git push origin --delete hotfix'
quiet 'git branch -d hotfix'
quiet 'git switch -c hotfix/retry-storm main'
printf 'MAX_RETRIES = 3\n' > ingestd/retry.py
_c 'Cap retries at three'
quiet 'git push -u origin hotfix/retry-storm'
quiet 'git switch feature/dedupe-window'
printf '# ingestd\n\nDuplicate events inside the dedupe window are dropped.\n' > README.md
_c 'Document the dedupe window'
quiet 'git push'
gate_note asha "$(git rev-parse feature/dedupe-window)"
gate_note main "$(git rev-parse main)"

gate_end
gate_ready

#!/usr/bin/env bash
# Exercise 7.9 (Level 4): a clone that has not talked to the server for a week.
# Builds server.git and the clones you/ and asha/ of the project "embed-cache". Read SYMPTOMS.md,
# not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m07-stale-clone
ex_begin m07-stale-clone

ex_server
ex_clone asha
cd asha || exit 1
as asha
mkdir -p cache
printf 'TTL_SECONDS = 3600\n' > cache/store.py
_c 'Add embedding cache'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
ex_clone you

# You, last week: one branch that was pushed and reviewed ...
cd you || exit 1
as you
quiet 'git switch -c feature/lru'
printf 'MAX_ENTRIES = 1000\n\ndef evict(entries):\n    return entries[-MAX_ENTRIES:]\n' > cache/lru.py
_c 'Add LRU eviction'
quiet 'git push -u origin feature/lru'
# ... and one that was started from origin/main, which made origin/main its upstream.
quiet 'git switch -c feature/tokenizer origin/main'
printf 'def key(text):\n    return text.strip()\n' > cache/keys.py
_c 'Add cache key function'
printf 'import unicodedata\n\ndef key(text):\n    return unicodedata.normalize("NFC", text.strip())\n' > cache/keys.py
_c 'Normalize unicode in cache keys'
quiet 'git push origin feature/tokenizer'
printf 'import unicodedata\n\ndef key(text):\n    return unicodedata.normalize("NFC", text.strip()).lower()\n' > cache/keys.py
_c 'Lowercase cache keys'
ex_note tokenizer_tip "$(git rev-parse HEAD)"
quiet 'git switch main'

# Asha, during the week: merges feature/lru, deletes it on the server, adds a commit.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git fetch'
quiet 'git merge --ff-only origin/feature/lru'
printf 'MAX_ENTRIES = 10000\n\ndef evict(entries):\n    return entries[-MAX_ENTRIES:]\n' > cache/lru.py
_c 'Evict at 10,000 entries'
quiet 'git push'
quiet 'git push origin --delete feature/lru'
ex_note server_main "$(git rev-parse HEAD)"

# You, today, without fetching first.
cd "$LAB_DIR/you" || exit 1
as you
printf 'TTL_SECONDS = 86400\n' > cache/store.py
_c 'Cache embeddings for 24 hours'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"

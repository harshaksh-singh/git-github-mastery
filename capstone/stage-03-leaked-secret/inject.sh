#!/usr/bin/env bash
# Stage 3: a secret in pushed history. Applies the incident on top of the state that the
# solution of stage 2 leaves. The "secret" is a dummy string made for this course.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 3 "$@"

# Wednesday 16 September. Kabir starts the embedding client. His first commit contains the
# environment file of the staging deployment.
cap_go kabir
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c feature/embedding-client'
mkdir -p deploy
cat > router/embed_client.py <<'F'
"""Client of the embedding service."""
import json
import os
import urllib.request


def embed(text):
    request = urllib.request.Request(
        os.environ["EMBED_API_URL"] + "/embed",
        data=json.dumps({"text": text}).encode(),
        headers={"Authorization": "Bearer " + os.environ["EMBED_API_TOKEN"]},
    )
    timeout = float(os.environ.get("EMBED_TIMEOUT_SECONDS", "2"))
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)["vector"]
F
printf 'EMBED_API_URL=https://embeddings.staging.tessaly.example/v1\nEMBED_API_TOKEN=capstone-dummy-token-not-a-real-secret\nEMBED_TIMEOUT_SECONDS=2\n' > deploy/staging.env
_cp 'Add the embedding service client' router/embed_client.py deploy/staging.env
cat > router/embed_cache.py <<'F'
"""A small in-process cache in front of the embedding service."""
import hashlib

from router.embed_client import embed

_cache = {}


def embed_cached(text):
    key = hashlib.sha256(text.encode()).hexdigest()
    if key not in _cache:
        _cache[key] = embed(text)
    return _cache[key]
F
_cp 'Cache embeddings by message hash' router/embed_cache.py
quiet 'git push -u origin feature/embedding-client'
cap_pr 'open feature/embedding-client'

# Tanvi builds on his branch and marks what she deployed to staging with a tag.
cap_go tanvi
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c feature/embedding-latency-log origin/feature/embedding-client'
cat > router/embed_log.py <<'F'
"""Log how long each call to the embedding service takes."""
import logging
import time

from router.embed_client import embed

log = logging.getLogger("intent-router.embed")


def embed_timed(text):
    start = time.monotonic()
    try:
        return embed(text)
    finally:
        log.info("embed took %.0f ms", (time.monotonic() - start) * 1000)
F
_cp 'Log the latency of embedding calls' router/embed_log.py
quiet 'git push -u origin feature/embedding-latency-log'
quiet 'git tag staging/2026-09-16 origin/feature/embedding-client'
quiet 'git push origin staging/2026-09-16'
quiet 'git switch main'

# The tech lead fetches to look at the pull request.
cap_go nandini
quiet 'git fetch'

# Kabir notices the file, deletes it in a new commit, keeps working, and pushes.
cap_go kabir
quiet 'git rm deploy/staging.env'
quiet "git commit -m 'Remove the staging env file'"
quiet "sed -i.bak -e 's|^    with urllib.request.urlopen(request, timeout=timeout) as response:|    for attempt in (1, 2):\\
        try:\\
            with urllib.request.urlopen(request, timeout=timeout) as response:\\
                return json.load(response)[\"vector\"]\\
        except TimeoutError:\\
            if attempt == 2:\\
                raise|' -e '/^        return json.load(response)\\[\"vector\"\\]\$/d' router/embed_client.py && rm router/embed_client.py.bak"
_cp 'Retry the embedding call once on timeout' router/embed_client.py
quiet 'git push'

cap_inject_end 3

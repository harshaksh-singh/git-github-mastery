#!/usr/bin/env bash
# Exercise 17.9 (Level 4): a clone that Git no longer recognizes as a repository.
# Builds server.git and your clone you/ of the project "ingestd", then damages three files of
# you/.git the way an interrupted file-level backup can. Read SYMPTOMS.md, not this file: the
# script is the answer to "what is broken".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m17-ingestd

ex_server
ex_clone you
cd you || exit 1
put src/ingest.py <<'F'
"""Reads documents and hands them to the indexer."""

BATCH = 100


def batches(docs):
    for start in range(0, len(docs), BATCH):
        yield docs[start:start + BATCH]
F
printf '# ingestd\n\nIngests documents into the search index.\n' > README.md
_c 'Add batching ingester'
printf 'max_batch: 100\nworkers: 4\n' > config.yaml
_c 'Add configuration'
quiet 'git push -u origin main'
quiet 'git switch -c feature/batching'
sed -e 's/BATCH = 100/BATCH = 250/' src/ingest.py > i.tmp && mv i.tmp src/ingest.py
_c 'Use batches of 250 documents'
quiet 'git push -u origin feature/batching'
printf 'max_batch: 250\nworkers: 4\n' > config.yaml
_c 'Match the configured batch size'
printf '\nBatches hold 250 documents.\n' >> README.md          # an edit that is not committed yet

# ---- the damage
: > .git/HEAD                                                   # HEAD: created again, never filled
: > .git/index.lock                                             # a lock that nobody will release
awk '/^\[remote "origin"\]/ { print; print "\turl = ../ser"; exit } { print }' .git/config > c.tmp && mv c.tmp .git/config

ex_end you

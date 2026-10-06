#!/usr/bin/env bash
# Chapter 26, sections 26.11 and 26.12: a blobless partial clone from the inside. The promisor
# remote, the objects that are missing on purpose, how they arrive on demand, and git backfill.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 partial-clone
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git clone --filter=blob:none "file://$PWD/server/orbit.git" dev'
cd dev || exit 1
quiet 'git config set maintenance.auto false'

snip 01-promisor
run 'git config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"'
note 'Two packs arrived: commits and trees at clone time, then the blobs of the checkout.'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
note 'Objects that the history refers to and this repository does not hold:'
run "git rev-list --objects --all --missing=print | grep -c '^?'"
note 'Git does not call that damage:'
run_rc 'git fsck'

snip 02-on-demand
note 'A command that needs an old version of a file fetches it, without being asked:'
run "GIT_TRACE=1 git show HEAD~20:services/ranker/features.py 2>&1 >/dev/null | sed -n 's/.*trace: run_command: git //p' | grep -v -e '^pack-objects' -e '^index-pack' -e '^maintenance'"
run 'ls .git/objects/pack/*.pack | wc -l'
note 'Commands that only read commits and trees fetch nothing:'
run 'git log --oneline -- services/ranker | wc -l'
run 'git diff --name-status HEAD~10 HEAD -- services | wc -l'
run 'ls .git/objects/pack/*.pack | wc -l'
note 'Counting changed lines needs file contents. Git asks for all of them in one request:'
run "GIT_TRACE=1 git diff --stat HEAD~10 HEAD -- services 2>&1 | grep -c 'run_command: git .*fetch'"
run 'ls .git/objects/pack/*.pack | wc -l'

snip 03-one-by-one
note 'A patch needs both versions of the file for every commit shown: one request per commit.'
run "GIT_TRACE=1 git log -p --format=%s -- services/ingest/settings.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'"
note 'Blame walks one version at a time as well:'
run "GIT_TRACE=1 git blame pipelines/training/config.yaml 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'"
run 'ls .git/objects/pack/*.pack | wc -l'
run "git rev-list --objects --all --missing=print | grep -c '^?'"

snip 04-backfill
note 'git backfill (experimental) asks for the missing blobs of the current branch in batches:'
run "GIT_TRACE=1 git backfill 2>&1 | grep -c 'run_command: git .*fetch'"
run "git rev-list --objects --all --missing=print | grep -c '^?'"
note 'What is still missing belongs to another branch:'
run "git rev-list --objects HEAD --missing=print | grep -c '^?'"
run 'ls .git/objects/pack/*.pack | wc -l'

snip 05-consolidate
note 'Many small packs are the price of on-demand fetching. Maintenance merges them:'
run 'git maintenance run'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'

snip 06-offline
note 'A second blobless clone, and the server becomes unreachable:'
run 'cd ..'
run 'git clone -q --filter=blob:none "file://$PWD/server/orbit.git" laptop'
run 'mv server server-offline'
run 'cd laptop'
note 'What is local still works:'
run 'git log --oneline -2'
run 'git status --short --branch'
note 'What needs a missing blob does not:'
run_rc 'git show HEAD~20:services/ranker/features.py'
run_rc 'git switch feature/rerank-cache'
run 'git status --short --branch'
run 'mv ../server-offline ../server'
run 'git switch feature/rerank-cache'

lab_end

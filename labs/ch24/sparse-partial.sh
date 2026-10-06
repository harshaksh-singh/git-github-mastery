#!/usr/bin/env bash
# Chapter 24, section 24.7: what "scalar clone" assembles, built by hand from its parts: a
# blobless partial clone, a cone-mode sparse checkout, and maintenance run in the foreground.
# scalar itself is not run: on this machine it starts a file-system monitor daemon (see the text).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 sparse-partial
. "$LAB_SCRIPT_DIR/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1

snip 01-clone
run 'git clone --filter=blob:none --sparse "file://$PWD/server/orbit.git" orbit-dev/src'
run 'cd orbit-dev/src'
run 'ls -A'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run 'git status | sed -n 4p'

snip 02-config
note 'What makes it partial is in .git/config; what makes it sparse is in .git/config.worktree:'
run 'git config list --local --show-origin | grep -i -e promisor -e partialclone -e worktreeconfig'
run 'git config list --worktree --show-origin'

snip 03-widen
note 'Widening the cone downloads the blobs of those directories, and only those:'
run 'git sparse-checkout set services/ranker libs/tokenizer'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run "git rev-list --objects --all --missing=print | grep -c '^?'"
run 'git status | sed -n 4p'

snip 04-history-in-cone
note 'History of the cone, fetched in one batch instead of one request per commit:'
run 'git backfill --sparse'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run 'git log -p --format=%s -1 -- services/ranker/features.py | sed -n 1,12p'

snip 05-settings
note 'A few of the settings that scalar would write, set by hand (the manual lists them all):'
run 'git config set commitGraph.changedPaths true'
run 'git config set status.aheadBehind false'
run 'git config set fetch.showForcedUpdates false'
run 'git config set advice.fetchShowForcedUpdates false'
run 'git config set log.excludeDecoration "refs/prefetch/*"'
run 'git config set maintenance.auto false'
run 'git config set maintenance.strategy incremental'

snip 06-maintenance
note 'What the scheduler would run every hour, run once in the foreground:'
run 'GIT_TRACE="$PWD/../maintenance.log" git maintenance run --task=prefetch --task=commit-graph'
run "sed -n 's/.*trace: run_command: git //p' ../maintenance.log | grep -v -e '^maintenance' -e '^pack-objects' -e '^index-pack'"
run "git for-each-ref --format='%(refname)' refs/prefetch"
note 'The prefetched refs do not move your remote-tracking branches and stay out of the log:'
run 'git log --oneline --decorate -1'

lab_end

#!/usr/bin/env bash
# Lab 18.4 replay: build by hand what "scalar clone" assembles (a blobless partial clone, a
# cone-mode sparse checkout, settings for a large repository, maintenance tasks in the
# foreground), then lose the connection to the server and recover.
# "scalar clone" itself is not run: on Git 2.55.0 for macOS it starts a file-system monitor
# daemon, and by default it installs a maintenance schedule. The lab text explains both.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 lab-18-4-scalar-by-hand
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-18-4-scalar-by-hand.sh" || exit 1

snip 01-clone
run 'git clone --filter=blob:none --sparse "file://$PWD/server/orbit.git" orbit-dev/src'
run 'cd orbit-dev/src'
run 'ls -A'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run 'git status'

snip 02-cone
run 'git sparse-checkout set services/ranker libs/tokenizer'
run "find . -path ./.git -prune -o -type f -print | sort"
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run "git rev-list --objects --all --missing=print | grep -c '^?'"

snip 03-settings
note 'Settings from the list in "git help scalar", written by hand:'
run 'git config set commitGraph.changedPaths true'
run 'git config set fetch.showForcedUpdates false'
run 'git config set advice.fetchShowForcedUpdates false'
run 'git config set fetch.unpackLimit 1'
run 'git config set status.aheadBehind false'
run 'git config set log.excludeDecoration "refs/prefetch/*"'
run 'git config set index.version 4'
run 'git update-index --index-version 4'
run 'git update-index --show-index-version'
note 'What "git maintenance register" would set in this repository:'
run 'git config set maintenance.auto false'
run 'git config set maintenance.strategy incremental'

snip 04-maintenance
note 'The hourly tasks of the incremental strategy, once, in the foreground:'
run 'GIT_TRACE="$PWD/../maintenance.log" git maintenance run --quiet --task=prefetch --task=commit-graph'
run "sed -n 's/.*trace: run_command: git //p' ../maintenance.log | grep -e '^fetch' -e '^commit-graph'"
run "git for-each-ref --format='%(refname)' refs/prefetch"
run "find .git/objects/info -type f | sed 's/[0-9a-f]\\{40\\}/ID/' | sort"

snip 05-checkpoint
note 'Checkpoint: the history of the cone without one request per commit.'
run 'git backfill --sparse'
run "GIT_TRACE=1 git log -p --format=%s -- services/ranker/features.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'"
run "GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'"

snip 06-failure
note 'Failure scenario: the server cannot be reached, and you need one more directory.'
run 'mv ../../server ../../server-offline'
run_rc 'git sparse-checkout add services/gateway'
run 'git sparse-checkout list'
run_rc 'ls services'
run 'git status --short --branch'

snip 07-still-works
note 'Everything inside what you already hold keeps working without the server:'
run 'git log --oneline -2 -- services/ranker'
run 'git blame -s -L 1,3 services/ranker/features.py'
run "printf 'top_k: 20\\nmodel: overlap-v1\\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'"
run 'git log --oneline -1'

snip 08-recovery
run 'mv ../../server-offline ../../server'
run 'git sparse-checkout add services/gateway'
run 'git sparse-checkout list'
run 'ls services/gateway'

snip 09-verification
run 'git status'
run 'git ls-files -t | cut -c1 | sort | uniq -c'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run_rc 'git fsck'
run_rc 'git commit-graph verify'

lab_end

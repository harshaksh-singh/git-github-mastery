#!/usr/bin/env bash
# Chapter 24, section 24.6: the sparse index. Directories outside the cone become one index
# entry each, and a command that cannot work with such entries expands the index again.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 sparse-index
. "$LAB_SCRIPT_DIR/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git clone "file://$PWD/server/orbit.git" dev'
cd dev || exit 1
quiet 'git config set maintenance.auto false'
quiet 'git sparse-checkout set services/ranker'

snip 01-full-index
note 'A sparse checkout with an ordinary index: 33 entries for 7 files on disk.'
run 'git ls-files --sparse | wc -l'
run 'git ls-files -t | cut -c1 | sort | uniq -c'

snip 02-enable
run 'git sparse-checkout set --sparse-index services/ranker'
run 'cat .git/config.worktree'
run 'git ls-files --sparse | wc -l'

snip 03-entries
note 'A whole directory outside the cone is now a single entry that names a tree object:'
run 'git ls-files --sparse --stage'

snip 04-same-tree
note 'The entry for docs/ holds exactly the ID of the docs tree in HEAD:'
run 'git rev-parse HEAD:docs'
run 'git ls-files --sparse --stage docs/'
run 'git status'

snip 05-counted
run "GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '\$4 ~ /data/ {gsub(/[ .]/, \"\", \$NF); gsub(/ /, \"\", \$(NF-1)); print \$(NF-1), \$NF}' | grep -e read/cache_nr -e sum_lstat"

snip 06-expand
note 'A command that asks for every path expands the index in memory, and says so:'
run 'git ls-files | wc -l'
note 'The file on disk stays sparse:'
run 'git ls-files --sparse | wc -l'

snip 07-back
run 'git sparse-checkout set --no-sparse-index services/ranker'
run 'git ls-files --sparse | wc -l'
run 'git config get index.sparse'

lab_end

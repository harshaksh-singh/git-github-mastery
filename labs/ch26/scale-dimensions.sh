#!/usr/bin/env bash
# Chapter 26, section 26.2: measure a repository along the dimensions that make Git slow, and
# count the work one "git status" does. Counts only: no timings are printed.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 scale-dimensions
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
cd orbit || exit 1

snip 01-dimensions
note 'History: how many commits, and how many objects of each type?'
run 'git rev-list --count --all'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
note 'Working tree: how many tracked files does every status have to consider?'
run 'git ls-files | wc -l'
note 'Refs: how many names does every fetch have to advertise and compare?'
run 'git for-each-ref | wc -l'
note 'Storage: loose objects and packs.'
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'

snip 02-largest
note 'The largest blob of each path in the whole history, five largest paths first:'
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep '^blob' | sort -k2 -n -r | awk '!seen[\$3]++' | head -5"
note 'How many versions of the largest file does the history hold?'
run 'git log --oneline -- pipelines/eval/cases.jsonl | wc -l'

snip 03-status-work
note 'What one "git status" does, in counted work. GIT_TRACE2_PERF prints a table; the awk'
note 'program keeps the rows that carry a counter and drops the columns that carry times.'
run "GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '\$4 ~ /data/ {gsub(/[ .]/, \"\", \$NF); gsub(/ /, \"\", \$(NF-1)); print \$(NF-1), \$NF}' | grep -e read/cache_nr -e sum_lstat -e visited"

snip 04-fsmonitor-off
note 'Neither accelerator of the working-tree scan is on by default:'
run_rc 'git config get core.fsmonitor'
run_rc 'git config get core.untrackedCache'
note 'Asking for the status of the daemon does not start one:'
run_rc 'git fsmonitor--daemon status'
run 'git version --build-options | grep feature'

lab_end

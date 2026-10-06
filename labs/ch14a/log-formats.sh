#!/usr/bin/env bash
# Chapter 14A, section 14A.15: pretty formats, trailers, and git shortlog.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-formats
fx_scorekit || exit 1
sk_ids

snip 01-format
run "git log -4 --format='%h %ad %<(10,trunc)%an %s' --date=short"
run "git log -3 --format='%h %ar%x09%s'"

snip 02-fuller
run "git log -1 --format=fuller $ID_SQUASH"

snip 03-trailers
run "git log -1 --format='%h %s%n  author: %an%n  with:   %(trailers:key=Co-authored-by,valueonly,separator=%x2C )' $ID_SQUASH"

snip 04-shortlog
run 'git shortlog -sn HEAD'
run 'git shortlog -sn --no-merges --group=author --group=trailer:co-authored-by HEAD'

snip 05-shortlog-release
run 'git shortlog --no-merges v0.1.0..v0.2.0'

snip 06-shortlog-stdin
note 'Without a revision, and with standard input that is not a terminal, shortlog reads a log from standard input:'
run 'git shortlog -sn < /dev/null'
run 'git log v0.2.0..main | git shortlog -sn'
lab_end

#!/usr/bin/env bash
# Lab 17.1 replay, volatile part: the cached stat data of the index entries.
# VOLATILE: timestamps, device and inode numbers and the user ID come from the real filesystem,
# so the numbers differ on every run. labs/verify-all.sh only checks that this script runs.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 lab-17-1-index-stat-volatile --volatile
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-17-1-index.sh" || exit 1

snip 01-debug
run 'git ls-files --debug'

snip 02-compare
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" --stat .git/index | grep -A1 config.toml'
run "stat -f 'ctime=%c mtime=%m dev=%d ino=%i uid=%u gid=%g size=%z' config.toml"

lab_end

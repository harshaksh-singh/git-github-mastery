#!/usr/bin/env bash
# Chapter 3, section 3.12: the cached stat data of index entries, raw.
# VOLATILE: timestamps, device and inode numbers and the user ID come from the real filesystem,
# so this output is different on every run and on every machine.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 index-debug --volatile
build_inference_service

snip 01-debug
run 'git ls-files --debug config.toml run.sh'
note 'The same numbers, asked from the filesystem (BSD stat, as on macOS):'
run "stat -f 'ctime=%c mtime=%m dev=%d ino=%i uid=%u gid=%g size=%z' config.toml"

lab_end

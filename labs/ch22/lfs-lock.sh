#!/usr/bin/env bash
# What cannot be run against a file remote: file locking needs the LFS server API.
# Chapter 22, section 22.6.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-lock
fx_transcriber_lfs

snip 01-lock-needs-a-server
run_rc 'git lfs lock models/acoustic.onnx'
lab_end

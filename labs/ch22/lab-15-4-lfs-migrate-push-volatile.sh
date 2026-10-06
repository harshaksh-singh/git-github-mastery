#!/usr/bin/env bash
# Lab 15.4 replay, part 2: after the migration, the push that sends pointers to Git and objects to
# the LFS store.
#
# Volatile: the line "Uploading LFS objects: ..." is sometimes absent with git-lfs 3.7.1 and a file
# remote (see lfs-push-volatile.sh).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lab-15-4-lfs-migrate-push-volatile --volatile
fx_transcriber_lab154_done

snip 01-push
run 'git lfs status'
run 'git push origin main experiment/quantized'

snip 02-remote
run 'git -C ../remotes/transcriber.git rev-list --objects --all | git -C ../remotes/transcriber.git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx'
run 'find ../remotes/transcriber.git/lfs/objects -type f | wc -l'
lab_end

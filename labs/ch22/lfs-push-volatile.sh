#!/usr/bin/env bash
# Pushing with LFS to a local bare repository reached through a file path: the endpoint the client
# derives, what the pre-push hook uploads, and where the bytes land on the remote.
# Chapter 22, section 22.6.
#
# Volatile: with git-lfs 3.7.1 and a file remote the line "Uploading LFS objects: ..." is printed by
# a progress meter that occasionally reports nothing (about one push in ten in our runs). Everything
# else in this demo is deterministic.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-push-volatile --volatile
fx_transcriber_lfs
quiet 'weights models/acoustic.onnx acoustic-v2 1250000'
commit_all 'Retrain acoustic model on noisy audio (v2)'

snip 01-endpoint
run 'git remote get-url origin'
run 'git lfs env | grep -e ^Endpoint -e Transfers'

snip 02-push
run 'git lfs status'
run 'git push origin main'

snip 03-remote-store
note 'The remote Git repository received a pointer blob:'
run 'git -C ../remotes/transcriber.git cat-file -s main:models/acoustic.onnx'
note 'The bytes are in the LFS store beside it, one file per version, named by SHA-256:'
run 'find ../remotes/transcriber.git/lfs/objects -type f | sort'

lab_end

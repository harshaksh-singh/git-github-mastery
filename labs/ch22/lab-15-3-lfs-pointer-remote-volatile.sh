#!/usr/bin/env bash
# Lab 15.3 replay, part 2: push to the shared repository, look at what each side stored, and clone
# as a machine without the LFS filter.
#
# Volatile: the line "Uploading LFS objects: ..." is sometimes absent with git-lfs 3.7.1 and a file
# remote (see lfs-push-volatile.sh).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lab-15-3-lfs-pointer-remote-volatile --volatile
fx_transcriber_lab153_done

snip 01-push
run 'git lfs status'
run 'git push origin main'

snip 02-two-stores
run 'git -C ../remotes/transcriber.git cat-file -p main:models/acoustic.onnx'
run 'find ../remotes/transcriber.git/lfs/objects -type f | sort'

snip 03-clone-without-filter
run 'git clone ../remotes/transcriber.git ../ravi-transcriber'
run 'cd ../ravi-transcriber'
run 'cat models/acoustic.onnx'
run 'wc -c models/acoustic.onnx samples/hello.wav'
run 'git status --short --branch'

snip 04-get-content
run 'git lfs install --local'
run 'git lfs pull'
run 'wc -c models/acoustic.onnx samples/hello.wav'
run 'git lfs ls-files'
lab_end

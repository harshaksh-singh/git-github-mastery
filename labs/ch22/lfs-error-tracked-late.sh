#!/usr/bin/env bash
# Common error 1: the file was committed before the pattern was tracked. "git lfs track" changes
# .gitattributes; it does not convert what is already in the index or in history.
# Chapter 22, section 22.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-error-tracked-late
fx_transcriber_lfs
quiet 'weights samples/hello.wav hello 48000'

snip 01-added-first
run 'git add samples/hello.wav'
run 'git commit -m "Add a sample recording"'
run 'git lfs track "*.wav"'
run 'git add .gitattributes'
run 'git commit -m "Track WAV files with Git LFS"'

snip 02-symptom
run 'git lfs ls-files'
run 'git cat-file -s HEAD:samples/hello.wav'
run 'git status --short'
run_rc 'git lfs fsck --pointers'

snip 03-fix-forward
note 'Nothing was pushed with the plain blob as its only form, and a new commit is acceptable:'
run 'git add --renormalize samples/hello.wav'
run 'git diff --cached --stat'
run 'git commit -m "Store the sample recording in Git LFS"'
run 'git lfs ls-files'
run 'git status --short'

snip 04-history-still-has-it
run 'git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep wav'
lab_end

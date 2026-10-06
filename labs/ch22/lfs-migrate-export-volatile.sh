#!/usr/bin/env bash
# git lfs migrate export: the reverse of import, again a rewrite of the unpushed commits.
# Chapter 22, section 22.9.
#
# Volatile: export ends by pruning the local LFS store, and when the prune removes more than one
# object git-lfs 3.7.1 prints the name of only one of them, not always the same one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-migrate-export-volatile --volatile
fx_transcriber_plain
quiet 'git lfs install --local'
quiet 'git lfs migrate import --include="*.onnx" --yes'
quiet 'git lfs checkout'

snip 01-before
run 'git log --oneline'
run 'git lfs ls-files'

snip 02-export
run 'git lfs migrate export --include="*.onnx"'

snip 03-after
run 'git log --oneline'
run 'cat .gitattributes'
run 'git lfs ls-files'
run 'git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx'
run 'find .git/lfs/objects -type f | wc -l'
lab_end

#!/usr/bin/env bash
# The local LFS store grows with every version you check out. status, ls-files --all, fetch --all,
# prune and fsck. Chapter 22, section 22.8.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-prune
fx_transcriber_lfs_v2

snip 01-store
run 'git lfs ls-files --all --size'
run 'find .git/lfs/objects -type f | sort'

snip 02-prune
run 'git lfs prune --dry-run --verbose'
run 'git lfs prune --verify-remote'
run 'find .git/lfs/objects -type f | sort'

snip 03-fetch-again
note 'The pruned version is still on the remote. Anything that needs it downloads it again:'
run 'git lfs fetch --all'
run 'find .git/lfs/objects -type f | sort'
run 'git lfs fsck'

snip 04-unpushed-is-kept
quiet 'weights models/acoustic.onnx acoustic-v3 1300000'
quiet 'git commit -qam "Retrain acoustic model with accents (v3)"'
quiet 'weights models/acoustic.onnx acoustic-v4 1350000'
quiet 'git commit -qam "Retrain acoustic model with far-field audio (v4)"'
note 'Two more versions, committed and not pushed. v3 is no longer checked out:'
run 'git status --short --branch'
run 'find .git/lfs/objects -type f | sort'
run 'git lfs prune'
run 'find .git/lfs/objects -type f | sort'
lab_end

#!/usr/bin/env bash
# What a clone receives without the LFS filter (pointer files), how fetch, checkout and pull fill
# them in, how the smudge filter downloads on demand, and GIT_LFS_SKIP_SMUDGE.
# Chapter 22, section 22.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-clone
fx_transcriber_lfs_v2
cd ..

snip 01-clone-without-client
note 'The lab configuration has no LFS filter, like a machine where git-lfs was never set up:'
run_rc 'git config get filter.lfs.smudge'
run 'git clone remotes/transcriber.git ravi-transcriber'
run 'cd ravi-transcriber'
run 'cat models/acoustic.onnx'
run 'git status --short --branch'

snip 02-what-is-missing
run 'git lfs ls-files'
run 'git lfs pull'
run 'find .git/lfs -type f'

snip 03-install-fetch-checkout
run 'git lfs install --local'
run 'git lfs fetch'
run 'find .git/lfs/objects -type f'
run 'wc -c models/acoustic.onnx'
run 'git lfs checkout'
run 'wc -c models/acoustic.onnx'
run 'git lfs ls-files'
run 'git status --short'

snip 04-smudge-on-demand
note 'With the filter configured, a checkout that needs another version downloads it:'
run 'git switch --detach HEAD~1'
run 'git lfs ls-files --size'
run 'find .git/lfs/objects -type f | sort'
run 'git switch -'

snip 05-skip-smudge
run 'GIT_LFS_SKIP_SMUDGE=1 git switch --detach HEAD~1'
run 'cat models/acoustic.onnx'
run 'git lfs ls-files'
run 'git status --short'
note 'git lfs pull replaces the pointers of the current commit with content:'
run 'git lfs pull'
run 'git lfs ls-files'
run 'git switch -'
lab_end

#!/usr/bin/env bash
# Common error 3: someone without the LFS filter commits a new version of a tracked file. Git stores
# the raw bytes; clones that do have the filter then see a file that "should have been a pointer"
# and that is modified immediately after checkout. Chapter 22, section 22.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-error-not-pointer
fx_transcriber_lfs
cd ..
quiet 'git clone remotes/transcriber.git asha-transcriber'
quiet 'git -C asha-transcriber lfs install --local'
quiet 'git -C asha-transcriber lfs pull'
quiet 'git clone remotes/transcriber.git ci-transcriber'

snip 01-commit-without-filter
run 'cd ci-transcriber'
as ravi
run_rc 'git config get filter.lfs.clean'
run 'cat .gitattributes'
quiet 'weights models/acoustic.onnx acoustic-v2 1250000'
run 'git commit -am "Retrain acoustic model on noisy audio (v2)"'
run 'git cat-file -s HEAD:models/acoustic.onnx'
run 'git push origin main'
as you

snip 02-symptom
run 'cd ../asha-transcriber'
as asha
run 'git pull'
run 'git status'

snip 03-diagnose
run 'git lfs ls-files'
run_rc 'git lfs fsck --pointers'
run 'git diff --stat'

snip 04-fix
run 'git add --renormalize models/acoustic.onnx'
run 'git commit -m "Store acoustic model v2 as an LFS pointer"'
run 'git lfs ls-files --size'
run 'git status --short'
as you
lab_end

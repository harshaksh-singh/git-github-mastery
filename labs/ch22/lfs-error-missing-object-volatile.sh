#!/usr/bin/env bash
# Common error 2: the pointer reached the remote, the object did not (here: a push with --no-verify,
# which skips the pre-push hook). The teammate's fetch and smudge fail. Chapter 22, section 22.10.
#
# Volatile: git-lfs writes an error log whose file name contains the wall-clock time, and prints
# that name.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-error-missing-object-volatile --volatile
fx_transcriber_lfs
quiet 'weights models/acoustic.onnx acoustic-v2 1250000'
commit_all 'Retrain acoustic model on noisy audio (v2)'
quiet 'git push --no-verify origin main'
cd ..
quiet 'git clone remotes/transcriber.git asha-transcriber'
cd asha-transcriber
as asha
quiet 'git lfs install --local'

snip 01-pull-fails
run_rc 'git lfs pull'
run 'git lfs ls-files'

snip 02-smudge-fails
note 'The same failure through the smudge filter, when a checkout needs the file:'
run 'rm models/acoustic.onnx'
run_rc 'git restore models/acoustic.onnx'
run 'git status --short'

snip 03-diagnose
run 'git cat-file -p HEAD:models/acoustic.onnx'
run 'find ../remotes/transcriber.git/lfs/objects -type f | sort'
as you

snip 04-fix
note 'Whoever still has the object uploads it:'
run 'cd ../transcriber'
note 'A plain "git lfs push origin main" sends nothing: the commit is already on origin/main,'
note 'so the client assumes its objects are too. --all sends every object the branch references.'
run 'git lfs push origin main'
run 'find ../remotes/transcriber.git/lfs/objects -type f | wc -l'
run 'git lfs push --all origin main'
run 'find ../remotes/transcriber.git/lfs/objects -type f | wc -l'
run 'cd ../asha-transcriber'
as asha
run 'git lfs pull'
run 'git lfs ls-files'
run 'git status --short'
as you
lab_end

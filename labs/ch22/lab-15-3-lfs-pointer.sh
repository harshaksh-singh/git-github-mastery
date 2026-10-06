#!/usr/bin/env bash
# Lab 15.3 replay, part 1: track a model with Git LFS, commit it, and inspect the pointer, the local
# store, and the clean and smudge filters by hand. Failure scenario: a second binary is committed
# before its pattern is tracked. Recovery by rewriting the unpushed commits with git lfs migrate.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lab-15-3-lfs-pointer
fx_transcriber_new_model

snip 01-start
run 'git status --short'
run 'wc -c models/acoustic.onnx samples/hello.wav'
run 'shasum -a 256 models/acoustic.onnx'

snip 02-install-track
run 'git lfs install --local'
run 'git lfs track "*.onnx"'
run 'cat .gitattributes'

snip 03-commit
run 'git add .gitattributes models/acoustic.onnx'
run 'git commit -m "Add acoustic model v1, tracked with Git LFS"'

snip 04-pointer
run 'git cat-file -p HEAD:models/acoustic.onnx'
run 'git cat-file -s HEAD:models/acoustic.onnx'
run 'wc -c models/acoustic.onnx'
run 'find .git/lfs/objects -type f'
run 'git lfs ls-files'

snip 05-filters-by-hand
note 'The clean filter, run by hand: content in, pointer out.'
run 'git lfs clean < models/acoustic.onnx'
note 'The smudge filter, run by hand: pointer in, content out.'
run 'git cat-file -p HEAD:models/acoustic.onnx | git lfs smudge | shasum -a 256'

snip 06-failure
run 'git add samples/hello.wav'
run 'git commit -m "Add a sample recording"'
note 'Too late, you remember that recordings should be in LFS as well:'
run 'git lfs track "*.wav"'
run 'git add .gitattributes'
run 'git commit -m "Track WAV files with Git LFS"'
run 'git lfs ls-files'
run 'git cat-file -s HEAD:samples/hello.wav'
run 'git status --short'

snip 07-recovery
note 'Nothing has been pushed, so the two commits can be rewritten.'
run 'git log --oneline'
run 'git lfs migrate import --include="*.wav" --yes'
run 'git log --oneline'
run 'git show HEAD~2:.gitattributes'
run 'git lfs checkout'

snip 08-verification
run 'git lfs ls-files'
run 'git status --short --branch'
run 'git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep -e onnx -e wav'
run 'wc -c models/acoustic.onnx samples/hello.wav'
run 'git lfs fsck'
lab_end

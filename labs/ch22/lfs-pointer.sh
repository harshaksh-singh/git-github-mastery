#!/usr/bin/env bash
# What "git lfs install --local" and "git lfs track" write, and what a commit of a tracked file
# contains: a pointer blob in Git, the real bytes in .git/lfs/objects. Chapter 22, sections 22.3 to 22.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-pointer
fx_transcriber_code

snip 01-install
run 'git lfs version'
run 'git lfs install --local'
run 'git config list --local | grep -e ^filter -e ^lfs | sort'
run 'ls .git/hooks | grep -v sample'

snip 02-track
run 'git lfs track "*.onnx"'
run 'cat .gitattributes'
run 'git lfs track'
run 'git check-attr filter diff merge text -- models/acoustic.onnx'
run 'git check-attr filter -- models/vocab.txt'

snip 03-commit
quiet 'weights models/acoustic.onnx acoustic-v1 1200000'
run 'wc -c models/acoustic.onnx'
run 'shasum -a 256 models/acoustic.onnx'
run 'git add .gitattributes models/acoustic.onnx'
run 'git commit -m "Add acoustic model v1, tracked with Git LFS"'

snip 04-pointer
note 'What Git stored for the path:'
run 'git cat-file -p HEAD:models/acoustic.onnx'
run 'git cat-file -s HEAD:models/acoustic.onnx'
note 'What is in the working tree:'
run 'wc -c models/acoustic.onnx'

snip 05-local-store
run 'find .git/lfs/objects -type f'
run 'git lfs ls-files'
run 'git lfs ls-files --long --size'
run 'git lfs pointer --file=models/acoustic.onnx'

snip 06-new-version
quiet 'weights models/acoustic.onnx acoustic-v2 1250000'
run 'git status --short'
run 'git diff'
run 'git lfs status'

snip 07-hook
run 'cat .git/hooks/pre-push'
run 'cat .git/hooks/post-checkout'
lab_end

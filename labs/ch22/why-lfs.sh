#!/usr/bin/env bash
# Why LFS exists: a binary that changes is stored whole for every version, every clone receives every
# version, and deleting the file later removes nothing from history. Chapter 22, section 22.2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 why-lfs
fx_transcriber_plain

snip 01-three-versions
run 'git log --oneline'
run 'wc -c models/acoustic.onnx'
note 'Every blob that any commit reaches, with its size in bytes:'
run 'git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob'

snip 02-clone-gets-all
run 'git push origin main'
run 'cd ..'
run 'git clone remotes/transcriber.git ravi-transcriber'
run 'cd ravi-transcriber'
note 'One model file in the working tree, three in the repository:'
run 'ls models'
run 'git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"'

snip 03-delete-does-not-help
run 'git rm --quiet models/acoustic.onnx'
run 'git commit -m "Remove the model from the repository"'
run 'git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx'
lab_end

#!/usr/bin/env bash
# Lab 15.4 replay, part 1: three versions of a model were committed as ordinary blobs and never
# pushed. Measure, migrate the current branch, inspect. Failure scenario: a second local branch was
# not migrated, and --everything, used to catch it, also rewrites the commit that is already on the
# remote. Recovery through the branch reflogs, then a migration that names the branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lab-15-4-lfs-migrate
fx_transcriber_plain_branch

snip 01-start
run 'git log --graph --oneline --decorate --all'
run 'git status --short --branch'

snip 02-measure
note 'What a push of main would have to send:'
run 'git rev-list --objects origin/main..main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob'
run 'git lfs migrate info'

snip 03-import
run 'git lfs install --local'
run 'git lfs migrate import --include="*.onnx"'
run 'git log --oneline --decorate main'

snip 04-inspect
run 'cat .gitattributes'
run 'git rev-list --objects origin/main..main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob'
run 'git cat-file -p main:models/acoustic.onnx'

snip 05-working-tree
run 'wc -c models/acoustic.onnx'
run 'git lfs checkout'
run 'wc -c models/acoustic.onnx'
run 'git lfs ls-files --size'
run 'git status --short --branch'

snip 06-failure
note 'The other branch was not part of the migration:'
run 'git rev-list --objects origin/main..experiment/quantized | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx'
note 'A flag that promises to catch everything looks like the answer:'
run 'git lfs migrate import --include="*.onnx" --everything'
run 'git status --short --branch'

snip 07-diagnose
run 'git log --graph --oneline --decorate --all'
run 'git show --stat --format="%h %s" $(git rev-list --max-parents=0 main)'

snip 08-recovery
run 'git reflog main -3'
run 'git reflog experiment/quantized -2'
run 'git reset --hard "main@{1}"'
run 'git branch -f experiment/quantized "experiment/quantized@{1}"'
run 'git lfs migrate import --include="*.onnx" experiment/quantized'

snip 09-verification
run 'git log --graph --oneline --decorate --all'
run 'git status --short --branch'
run 'git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx'
note 'git lfs checkout   (prints a progress line only if a file still held a pointer)'
quiet 'git lfs checkout'
run 'git lfs ls-files --size'
run 'wc -c models/acoustic.onnx'
run 'git lfs fsck'
lab_end

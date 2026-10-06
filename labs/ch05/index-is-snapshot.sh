#!/usr/bin/env bash
# The index is a complete snapshot of the proposed next commit, not a list of changes:
# written out as a tree it equals HEAD's tree when nothing is staged, and it becomes the
# tree of the next commit. Chapter 5, section 5.2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 index-is-snapshot

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf '# Support bot\n' > README.md
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-flat-list
note 'The index: one line per file, with mode, blob ID, stage number and full path.'
run 'git ls-files --stage'
note 'The tree of HEAD: the same files, arranged as nested tree objects.'
run 'git ls-tree HEAD'
run 'git ls-tree -r HEAD'

snip 02-file-header
note 'The index is one binary file. Its first 12 bytes: signature, format version, number of entries.'
run 'head -c 12 .git/index | hexdump -C'
run 'git update-index --show-index-version'
run 'git ls-files | wc -l'

snip 03-index-equals-head
note 'Write the index out as a tree object. With nothing staged it is the tree HEAD already has.'
run 'git write-tree'
run 'git rev-parse HEAD^{tree}'

snip 04-stage-one-file
run "echo 'temperature: 0.2' >> config/settings.yaml"
run 'git add config/settings.yaml'
run 'git ls-files --stage'
note 'One entry has a new blob ID. Every other entry is untouched. The tree this index describes:'
run 'git write-tree'

snip 05-commit-takes-that-tree
run 'git commit -m "Set sampling temperature"'
run 'git rev-parse HEAD^{tree}'
run 'git status'

lab_end

#!/usr/bin/env bash
# Chapter 3, section 3.4: blob, tree, commit and annotated tag objects in full.
# One small repository whose top-level tree uses all five entry modes.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 object-types
build_inference_service

snip 01-tree-modes
run 'ls -F'
run 'git ls-tree HEAD'
note 'A symbolic link is a blob whose content is the target path:'
run 'git cat-file -p HEAD:current-model; echo'

snip 02-tree-raw
run 'git cat-file -p HEAD:src'
note 'The same tree as stored: mode, space, name, NUL, then the ID as 20 raw bytes.'
run 'git cat-file tree HEAD:src | xxd'

snip 03-commit
run 'git log --graph --oneline'
note 'A merge commit: one tree, two parent headers.'
run 'git cat-file -p HEAD'
note 'A root commit has no parent header at all:'
run 'git cat-file -p HEAD~2'

snip 04-commit-id
note 'A commit ID is the hash of "commit <size>", a NUL byte, and exactly the text above.'
run 'git cat-file -s HEAD'
run "(printf 'commit %s\\0' \"\$(git cat-file -s HEAD)\"; git cat-file commit HEAD) | shasum"
run 'git rev-parse HEAD'

snip 05-tag
run 'git cat-file -t v1.0.0'
run 'git cat-file -t v1.0.0-rc1'
run 'git cat-file -p v1.0.0'
note 'The ref holds the ID of the tag object; ^{} peels it to the commit it tags.'
run 'git rev-parse v1.0.0 "v1.0.0^{}" HEAD'

snip 06-encoding
note 'An optional header: the encoding of the message when it is not UTF-8.'
run "printf 'max_tokens = 256\\n' >> config.toml"
run 'git -c i18n.commitEncoding=ISO-8859-1 commit -q -am "Add token limit"'
run 'git cat-file -p HEAD'

lab_end

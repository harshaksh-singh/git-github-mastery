#!/usr/bin/env bash
# What "git add" writes: a blob in the object database and an entry in the index.
# The content is captured at the moment of the add, not at the moment of the commit.
# Chapter 5, section 5.3.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 add-writes

git init -q support-bot
cd support-bot || exit 1
mkdir -p config
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add settings"'

snip 01-before-add
run 'git cat-file --batch-all-objects --batch-check'
run "echo 'max_tokens: 512' >> config/settings.yaml"
note 'hash-object computes the ID this content would get. It writes nothing.'
run 'git hash-object config/settings.yaml'
run_rc 'git cat-file -t e4eb0e6'

snip 02-add
run 'git add config/settings.yaml'
run 'git cat-file --batch-all-objects --batch-check'
run 'git ls-files --stage'
run 'git cat-file -p e4eb0e6'

snip 03-add-is-a-snapshot
note 'Edit the file again after the add. The index keeps what it was given.'
run "echo 'debug: true' >> config/settings.yaml"
run 'git status --short'
run 'git show :config/settings.yaml'
run 'git commit -m "Limit response length"'
run 'git show HEAD:config/settings.yaml'
run 'git status --short'

snip 04-same-content-same-blob
note 'Adding content that the object database already holds creates no new object.'
run 'git cat-file --batch-all-objects --batch-check | grep -c blob'
run 'git show HEAD:config/settings.yaml > config/settings.staging.yaml'
run 'git add config/settings.staging.yaml'
run 'git ls-files --stage'
run 'git cat-file --batch-all-objects --batch-check | grep -c blob'

lab_end

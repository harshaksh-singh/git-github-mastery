#!/usr/bin/env bash
# Line endings in brief: Git stores the bytes it is given unless an attribute or a
# configuration value tells it to convert them. Chapter 4, section 4.13.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 line-endings

git init -q support-bot
cd support-bot || exit 1
mkdir -p scripts
printf 'fastapi\nnumpy\nuvicorn\n' > requirements.txt
printf '@echo off\r\necho deploying\r\n' > scripts/deploy.bat
quiet 'git add . && git commit -m "Add requirements and Windows deploy script"'

snip 01-eol
note 'i/ is the content in the index, w/ the content in the working tree, attr/ the attribute in force.'
run 'git ls-files --eol'

snip 02-whole-file-diff
note 'An editor on another platform saves requirements.txt with CRLF line endings.'
printf 'fastapi\r\nnumpy\r\nuvicorn\r\n' > requirements.txt
run 'git ls-files --eol requirements.txt'
run 'git diff --stat'
run 'git diff --stat --ignore-cr-at-eol'

lab_end

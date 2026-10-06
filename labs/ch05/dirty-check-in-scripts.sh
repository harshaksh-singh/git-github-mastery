#!/usr/bin/env bash
# A script that asks plumbing whether the working tree is clean must refresh the index first:
# after a copy every file has new stat data, and plumbing reports stat mismatches as changes.
# Chapter 5, section 5.14.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 dirty-check-in-scripts

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-false-positive
note 'A release script asks plumbing: does anything differ from HEAD? Exit status 0 means no.'
run_rc 'git diff-index --quiet HEAD'
note 'Copy the repository, as a build context or a restored CI cache does. No file content changes.'
run 'cp -R ../support-bot ../build-copy'
run 'cd ../build-copy'
run_rc 'git diff-index --quiet HEAD'
run 'git diff-files --name-status'

snip 02-refresh-first
note 'Refresh: re-read the files whose stat data differ, and store the new stat data when the content matches.'
run 'git update-index -q --refresh'
run_rc 'git diff-index --quiet HEAD'
run 'git diff-files --name-status'

lab_end

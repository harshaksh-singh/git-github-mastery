#!/usr/bin/env bash
# Chapter 15, section 15.14: before a push, find the largest files in history. A file that
# was deleted in a later commit is still an object that the push must send, and the
# platform's per-file limits apply to it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 large-objects
make_registry "$LAB_DIR/prompt-registry"
mkdir -p models
head -c 3145728 /dev/zero | tr '\0' 'w' > models/intent-classifier.bin
commit_paths 'Add trained intent classifier' models
hidden 'git rm -q models/intent-classifier.bin'
hidden 'git commit -q -m "Move the classifier out of Git"'

snip 01-gone
run 'git log --oneline -3'
run 'git ls-files | grep -c classifier'

snip 02-still-in-history
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '\$1 == \"blob\"' | sort -k2,2nr | head -3"

snip 03-which-commit
run 'git log --oneline --diff-filter=A -- models/intent-classifier.bin'

lab_end

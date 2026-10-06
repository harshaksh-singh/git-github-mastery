#!/usr/bin/env bash
# Chapter 2, section "The four object types": one repository that contains a blob, a tree,
# a commit and an annotated tag, each read with git cat-file.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 object-types

quiet 'git init ranker'
cd ranker || exit 1
mkdir -p src scripts
printf '# ranker\n' > README.md
printf 'def rerank(docs):\n    return sorted(docs, key=len)\n' > src/rerank.py
printf '#!/bin/sh\npython -m pytest -q\n' > scripts/test.sh
chmod +x scripts/test.sh
quiet 'git add . && git commit -m "Add reranker with test script"'
quiet 'git tag -a v0.1.0 -m "First internal release"'

snip 01-inventory
run 'git cat-file --batch-all-objects --batch-check'

snip 02-commit
run 'git cat-file -t HEAD'
run 'git cat-file -p HEAD'

snip 03-tree
run "git cat-file -p 'HEAD^{tree}'"
run 'git cat-file -p HEAD:scripts'
run 'git ls-tree -r HEAD'

snip 04-blob
run 'git cat-file -t HEAD:src/rerank.py'
run 'git cat-file -p HEAD:src/rerank.py'

snip 05-tag
run 'git cat-file -t v0.1.0'
run 'git cat-file -p v0.1.0'

lab_end

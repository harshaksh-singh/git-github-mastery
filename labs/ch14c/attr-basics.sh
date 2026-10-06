#!/usr/bin/env bash
# Chapter 14C, section 14C.4: the syntax of .gitattributes, the four states of an attribute,
# "git check-attr", precedence between attribute files, the "binary" macro, and export-ignore.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c attr-basics

quiet 'git init trainer'
cd trainer || exit 1
quiet 'mkdir -p src scripts data docs'
quiet "printf 'import torch\n' > src/train.py && printf '#!/bin/sh\npython src/train.py\n' > scripts/run.sh && printf 'id,label\n1,spam\n' > data/labels.csv && printf 'id,label\n' > labels.csv && printf 'weights\n' > data/encoder.bin && printf '# Design notes\n' > docs/design.md"
cat > .gitattributes <<'ATTR'
# pattern     attributes
*             text=auto
*.sh          text eol=lf
*.csv         text eol=crlf
*.bin         binary
CHANGELOG.md  merge=union
docs          export-ignore
.gitattributes export-ignore
ATTR
quiet "printf '# Vendor exports: keep every byte as delivered.\n*.csv  -text\n' > data/.gitattributes"
quiet "git add . && git commit -m 'Add trainer skeleton with attributes'"

snip 01-files
run 'cat .gitattributes'
run 'cat data/.gitattributes'

snip 02-check-attr
run 'git check-attr -a -- src/train.py scripts/run.sh data/encoder.bin'
note 'Ask for named attributes to see the unspecified state as well:'
run 'git check-attr text eol merge -- src/train.py'

snip 03-precedence
note 'The same pattern, one file at the top and one below data/:'
run 'git check-attr text eol -- labels.csv data/labels.csv'
note '.git/info/attributes is not versioned and beats every .gitattributes file:'
run "printf 'data/labels.csv text eol=lf\n' > .git/info/attributes"
run 'git check-attr text eol -- data/labels.csv'
run 'rm .git/info/attributes'

snip 04-export-ignore
run 'git ls-files'
run 'git archive --format=tar HEAD | tar -tf -'

lab_end

#!/usr/bin/env bash
# Chapter 14C, section 14C.5: line endings. What core.autocrlf does and does not do, then the
# fix for everyone: "* text=auto" in .gitattributes, "git add --renormalize ." and eol=.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c attr-eol

quiet 'git init ingest'
cd ingest || exit 1
# A teammate on Windows committed two files with CRLF line endings; run.sh came from a Mac.
quiet "printf 'def load(path):\r\n    return open(path)\r\n' > loader.py && printf 'id,text\r\n1,hello\r\n' > sample.csv && printf '#!/bin/sh\npython loader.py\n' > run.sh && git add . && git commit -m 'Add loader'"

snip 01-before
run 'git ls-files --eol'

snip 02-autocrlf
note 'A personal setting converts what YOU add from now on:'
run "printf 'def clean(row):\r\n    return row.strip()\r\n' > clean.py"
run 'git -c core.autocrlf=input add clean.py'
run 'git ls-files --eol clean.py loader.py'
note 'It does not touch a file that is already stored with CRLF, and a teammate without the setting'
note 'still commits CRLF:'
run "printf 'def split(row):\r\n    return row.split()\r\n' > split.py"
run 'git add split.py'
run 'git ls-files --eol split.py'
quiet "git commit -m 'Add clean and split helpers'"

snip 03-attributes
run "printf '* text=auto\n*.sh text eol=lf\n*.csv text eol=crlf\n' > .gitattributes"
run 'git status -s'
run 'git add --renormalize .'
run 'git status -s'
run 'git diff --cached --stat'

snip 04-after
run 'git add .gitattributes'
run 'git commit -q -m "Normalize line endings with .gitattributes"'
run 'git ls-files --eol'

snip 05-fresh-checkout
note 'The index now holds LF. Files on disk keep their old endings until they are written again:'
run 'rm loader.py sample.csv split.py'
run 'git restore .'
run 'git ls-files --eol'

lab_end

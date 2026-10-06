#!/usr/bin/env bash
# Chapter 3, section 3.3: the loose object format.
# Writes one blob, inflates the file with Python's zlib, and reproduces the object ID with shasum.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 loose-object

snip 01-write
run 'git init inference-service'
run 'cd inference-service'
run "printf 'retry_limit = 3\\n' > config.toml"
note 'Compute the ID only. Nothing is stored yet:'
run 'git hash-object config.toml'
run 'find .git/objects -type f'
note 'Now store it (-w). One file appears, named after the ID:'
run 'git hash-object -w config.toml'
run 'find .git/objects -type f'

snip 02-inflate
note 'The file is a zlib stream. Inflate it:'
run "python3 -c \"import sys, zlib; print(zlib.decompress(open(sys.argv[1], 'rb').read()))\" .git/objects/f7/84b58423ef67be5af8d1cfdfd9bea5eaa26bae"
run 'wc -c < config.toml'
note 'Hash the same bytes yourself: header, NUL, content.'
run "printf 'blob 16\\0retry_limit = 3\\n' | shasum"

snip 03-read-back
run 'git cat-file -t f784b584'
run 'git cat-file -s f784b584'
run 'git cat-file -p f784b584'
note 'The ID depends on content only: another name, another directory, same ID.'
run 'mkdir -p deploy && cp config.toml deploy/production.toml'
run 'git hash-object deploy/production.toml'
run "printf 'retry_limit = 3\\n' | git hash-object --stdin"
note 'One changed byte gives an unrelated ID:'
run "printf 'retry_limit = 4\\n' | git hash-object --stdin"

snip 04-status
note 'An object in the database is not a tracked file. The index is still empty:'
run 'git status --short'
run 'git ls-files --stage'
run 'git add config.toml'
run 'git ls-files --stage'
run 'find .git/objects -type f'

lab_end

#!/usr/bin/env bash
# add/add: both branches create the same path with different content. Chapter 8, section 8.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-add-add

quiet 'ek_base'
quiet 'git switch -c feature/disk-cache'
as ravi
quiet 'printf "import json\n\n\ndef load(path):\n    with open(path) as f:\n        return json.load(f)\n" > evalkit/cache.py'
quiet 'ek_commit "Add a JSON disk cache for judge responses"'
as you
quiet 'git switch main'
quiet 'printf "_CACHE = {}\n\n\ndef load(key):\n    return _CACHE.get(key)\n" > evalkit/cache.py'
quiet 'ek_commit "Add an in-memory cache for judge responses"'

snip 01-merge
run_rc 'git merge feature/disk-cache'
run 'git status --short'
run 'git ls-files -u'
run_rc 'git show :1:evalkit/cache.py'

snip 02-file
run 'cat evalkit/cache.py'
quiet 'git merge --abort'

lab_end

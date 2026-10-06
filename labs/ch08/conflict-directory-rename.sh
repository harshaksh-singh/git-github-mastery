#!/usr/bin/env bash
# A directory renamed on one branch, a file added to the old directory on the other: the
# "file location" conflict and merge.directoryRenames. Chapter 8, section 8.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-directory-rename

quiet 'ek_base'
quiet 'printf "\"\"\"evalkit package.\"\"\"\n" > evalkit/__init__.py'
quiet 'printf "def summarize(rows):\n    return {\"n\": len(rows)}\n" > evalkit/report.py'
quiet 'ek_commit "Add the package marker and the report module"'
quiet 'git switch -c feature/cache'
as asha
quiet 'printf "_CACHE = {}\n\n\ndef load(key):\n    return _CACHE.get(key)\n" > evalkit/cache.py'
quiet 'ek_commit "Add an in-memory cache for judge responses"'
as you
quiet 'git switch main'
quiet 'mkdir src && git mv evalkit src/evalkit && ek_commit "Move the package under src/"'

snip 01-merge
run 'git diff --name-status feature/cache...main'
run 'git diff --name-status main...feature/cache'
run_rc 'git merge feature/cache'
run 'git status --short'
run 'git ls-files -u'
run 'ls src/evalkit'

snip 02-resolve
note 'Git has already written the file where it suggests. Accepting the suggestion is one command:'
run 'git add src/evalkit/cache.py'
run 'git status --short'
run 'git merge --continue'
run 'git ls-files src'

snip 03-config
quiet 'git reset --hard ORIG_HEAD'
note 'The same merge with merge.directoryRenames=true does not stop:'
run 'git -c merge.directoryRenames=true merge feature/cache'
quiet 'git reset --hard ORIG_HEAD'
note 'With merge.directoryRenames=false the new file stays in the old directory, without a word:'
run 'git -c merge.directoryRenames=false merge feature/cache'
run 'git ls-files evalkit src'

lab_end

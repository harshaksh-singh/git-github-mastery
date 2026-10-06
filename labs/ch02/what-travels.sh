#!/usr/bin/env bash
# Chapter 2, section "The mental map of Git versus GitHub": what a push and a clone transfer
# (objects and refs) and what never leaves a clone (the index, reflogs, configuration, refs that
# were not pushed). A bare repository on disk plays the Git layer of the server.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 what-travels

quiet 'git init --bare hub.git'
quiet 'git init laptop'
cd laptop || exit 1
quiet "printf 'lowercase\n' > rules.txt && git add rules.txt && git commit -m 'Add lowercase rule'"
quiet 'git branch wip/unicode'
quiet "git config set alias.st 'status --short --branch'"
quiet "printf 'lowercase\nstrip accents\n' > rules.txt && git add rules.txt"
quiet 'git remote add origin ../hub.git'

snip 01-laptop
note 'Your clone: one commit, a second branch, one staged change, one alias in .git/config.'
run 'git st'
run 'git push -u origin main'
run 'git for-each-ref'
run 'git cat-file --batch-all-objects --batch-check'

snip 02-server
run 'cd ../hub.git'
run "find . -type f -not -path './hooks/*' | sort"
run 'git for-each-ref'
run 'git cat-file --batch-all-objects --batch-check'
run_rc 'git status'

snip 03-clone
run 'cd ..'
run 'git clone -q hub.git colleague'
run 'cd colleague'
run 'git for-each-ref'
run 'git reflog'
run_rc 'git st'

lab_end

#!/usr/bin/env bash
# Chapter 7, section 7.15 (dangerous edge cases): branch names on a case-insensitive file system.
# With the files ref backend a loose ref is a file, so on the default macOS volume format
# "MAIN" finds the file "main". HEAD then names a branch that is not in any listing.
#
# This demo assumes the default macOS volume format (APFS, case-insensitive), like the
# case-insensitive demo of chapter 4. On a case-sensitive volume "git switch MAIN" fails instead.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 case-trap

quiet 'git init evalkit'
cd evalkit || exit 1
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'

snip 01-wrong-case
run 'git config get core.ignoreCase'
run 'git switch MAIN'
run 'cat .git/HEAD'
run 'git branch'
run 'git status'

snip 02-commit
run "printf '\nRun the tests with: python -m pytest\n' >> README.md"
run 'git commit -am "Document how to run the tests"'
run 'git log --oneline --decorate'
run "git for-each-ref --format='%(objectname:short) %(refname)' refs/heads"

snip 03-fix
run 'git switch main'
run 'git branch'
run 'git log --oneline --decorate -1'

snip 04-two-names
run_rc 'git branch Main'
run 'git pack-refs --all'
run 'git branch Main'
run "git for-each-ref --format='%(objectname:short) %(refname)' refs/heads"

lab_end

#!/usr/bin/env bash
# Chapter 20B, section 20B.11: a file-name case mismatch that works on a Mac and fails on a
# Linux runner. Needs the default case-insensitive macOS volume to show the laptop side.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b case-clash
make_warehouse

snip 01-works-here
note 'Git recorded the name with a capital T. The loader asks for a lower-case name.'
run 'git config get core.ignorecase'
run 'git ls-files configs'
run 'cat configs/thresholds.yaml'

snip 02-what-linux-sees
note 'Git itself compares names byte by byte, as a case-sensitive filesystem does:'
run_rc 'git cat-file -e HEAD:configs/thresholds.yaml'
run_rc 'git cat-file -e HEAD:configs/Thresholds.yaml'

snip 03-fix
note 'The fix is a rename that Git records, not a change on the laptop only:'
run 'git mv configs/Thresholds.yaml configs/thresholds.yaml'
run 'git status --short'
run 'git commit -q -m "Rename the thresholds file to lower case"'
run 'git ls-files configs'

snip 04-two-names
note 'The other half of the problem: a commit made on Linux that holds both spellings.'
quiet 'blob=$(git rev-parse HEAD:README.md)'
quiet 'git update-index --add --cacheinfo 100644,$blob,Readme.md'
quiet 'git commit -q -m "Add Readme.md (made on a case-sensitive machine)"'
run 'git ls-files | grep -i readme'
run 'cd ..'
run 'git clone --quiet warehouse-api second-clone'
run 'ls second-clone | grep -i readme'
lab_end

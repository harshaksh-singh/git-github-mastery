#!/usr/bin/env bash
# Chapter 28, section 28.6: a data set versioned by reference. Git tracks a pointer file with a
# checksum; the bytes live in a content-addressed store outside the repository. This is the
# mechanism behind DVC and Git LFS, reduced to a standard-library script.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 data-pointer
fx_docqa 4
data_files
tickets_v1
hidden 'git add tools/dataref.py data/README.md && git commit -m "Add the data-by-reference tool"'

snip 01-add
run 'wc -l < data/raw/tickets.csv'
run 'git status --short --ignored data'
run 'python3 tools/dataref.py add data/raw/tickets.csv'
run 'cat data/raw/tickets.csv.ref'
run 'git status --short data'
run 'git add data/raw/tickets.csv.ref && git commit -q -m "Version the ticket data set by reference"'

snip 02-new-version
note 'Four labelled tickets arrive. The data file changes; Git sees nothing until the pointer changes:'
tickets_v2
run 'git status --short'
run_rc 'python3 tools/dataref.py verify'
run 'python3 tools/dataref.py add data/raw/tickets.csv'
run 'git diff'
run 'git commit -q -am "Add four labelled tickets to the data set"'

snip 03-store
run 'find ../datastore -type f | sort'
run 'git log --oneline -- data/raw/tickets.csv.ref'

snip 04-time-travel
note 'Going back is two steps: Git moves the pointer, the tool moves the bytes.'
run 'git switch -q --detach HEAD~1'
run_rc 'python3 tools/dataref.py verify'
run 'python3 tools/dataref.py checkout'
run 'wc -l < data/raw/tickets.csv'
run 'git switch -q main && python3 tools/dataref.py checkout'

snip 05-clone
run 'git clone -q . ../docqa-ravi && cd ../docqa-ravi'
run 'ls data/raw'
run 'python3 tools/dataref.py checkout'
run 'python3 tools/dataref.py verify'

snip 06-store-is-the-risk
note 'The pointer is only as good as the store behind it:'
run 'rm -r ../datastore/sha256 && rm data/raw/tickets.csv'
run_rc 'python3 tools/dataref.py checkout'
lab_end

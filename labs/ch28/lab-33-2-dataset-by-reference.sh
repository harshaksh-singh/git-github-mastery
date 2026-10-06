#!/usr/bin/env bash
# Lab 33.2 replay: version a data set by reference, move between its versions, restore it in a
# clone, and catch a data file that was edited without being recorded.
# Lab manual: lab-manual/m33-ai-ml-workflows.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 lab-33-2-dataset-by-reference
fx_lab_33_2

snip 01-start
run 'git status --short --ignored'
run 'git check-ignore -v data/raw/tickets.csv'
run 'wc -l < data/raw/tickets.csv'

snip 02-add
run 'python3 tools/dataref.py add data/raw/tickets.csv'
run 'cat data/raw/tickets.csv.ref'
run 'git add data/raw/tickets.csv.ref'
run 'git commit -q -m "Version the ticket data set by reference"'
run 'python3 evals/run_eval.py v1'

snip 03-new-version
run "printf '\"I need a receipt for last month\",billing\n\"Sync stopped working after the update\",technical\n' >> data/raw/tickets.csv"
run 'git status --short'
run_rc 'python3 tools/dataref.py verify'
run 'python3 tools/dataref.py add data/raw/tickets.csv'
run 'git diff --stat'
run 'git commit -q -am "Add two labelled tickets to the data set"'
run 'python3 evals/run_eval.py v2'

snip 04-back
run 'git switch -q --detach HEAD~1'
run 'python3 tools/dataref.py checkout'
run 'python3 evals/run_eval.py v1-again'
run 'cmp runs/v1/metrics.json runs/v1-again/metrics.json && echo same metrics'
run 'git switch -q main && python3 tools/dataref.py checkout'

snip 05-clone
run 'git clone -q . ../docqa-ravi'
run 'ls ../docqa-ravi/data/raw'
run '(cd ../docqa-ravi && python3 tools/dataref.py checkout && python3 tools/dataref.py verify)'

snip 06-failure
note 'Failure scenario: a label is corrected directly in the data file, and nothing is recorded.'
run "sed -i.bak 's/\"My card was declined\",billing/\"My card was declined\",general/' data/raw/tickets.csv && rm data/raw/tickets.csv.bak"
run 'git status --short'
run 'python3 evals/run_eval.py after-edit'
run 'grep -h -e "\"commit\"" -e "\"dirty\"" -e accuracy runs/v2/run.json runs/after-edit/run.json'

snip 07-diagnose
run_rc 'python3 tools/dataref.py verify'
run 'grep -h -A2 "\"data\"" runs/v2/run.json runs/after-edit/run.json | grep sha256'
run 'grep sha256 data/raw/tickets.csv.ref'

snip 08-recovery
note 'The correction is wanted, so record it as a new version (to discard it: dataref.py checkout).'
run 'python3 tools/dataref.py add data/raw/tickets.csv'
run 'git commit -q -am "Relabel the declined-card ticket as general"'

snip 09-verify
run 'python3 tools/dataref.py verify'
run 'git log --oneline -- data/raw/tickets.csv.ref'
run 'find ../datastore -type f | wc -l'
lab_end

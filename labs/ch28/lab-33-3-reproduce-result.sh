#!/usr/bin/env bash
# Lab 33.3 replay: reproduce a past result from its recorded identifiers (commit, data
# checksum, configuration), then a result that was produced from a dirty tree.
# Lab manual: lab-manual/m33-ai-ml-workflows.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 lab-33-3-reproduce-result
fx_lab_33_3

snip 01-today
run 'git log --oneline --decorate -4'
run 'python3 evals/run_eval.py today'
run 'cat ../tracker/baseline/metrics.json'

snip 02-read-record
run 'grep -e "\"commit\"" -e "\"dirty\"" -e "\"describe\"" ../tracker/baseline/run.json'
run 'grep -A2 "\"data\"" ../tracker/baseline/run.json'

snip 03-worktree
note 'Check the recorded commit out beside your work, without disturbing it:'
run "commit=\$(python3 -c \"import json; print(json.load(open('../tracker/baseline/run.json'))['code']['commit'])\")"
run 'git worktree add --detach ../repro "$commit"'
run 'cd ../repro'
run 'python3 tools/dataref.py checkout'
run 'grep sha256 data/raw/tickets.csv.ref'

snip 04-rerun
run 'python3 evals/run_eval.py repro'
run 'diff runs/repro/run.json ../tracker/baseline/run.json && echo "identical record"'

snip 05-failure
note 'Failure scenario: the result everybody quotes is "tuned", accuracy 0.9.'
run 'cat ../tracker/tuned/metrics.json'
run 'grep -e "\"commit\"" -e "\"dirty\"" -e "\"diff_sha256\"" ../tracker/tuned/run.json'
note 'Same commit as the baseline. Rerunning that commit gives the baseline number, not 0.9:'
run 'cat runs/repro/metrics.json'

snip 06-recovery
note 'The record says the tree was dirty, and the run saved the uncommitted change:'
run 'cat ../tracker/tuned/uncommitted.patch'
run 'git apply ../tracker/tuned/uncommitted.patch'
run 'git diff HEAD --binary | shasum -a 256'
run 'python3 evals/run_eval.py repro-tuned --allow-dirty'

snip 07-verify
run 'diff runs/repro-tuned/run.json ../tracker/tuned/run.json && echo "identical record"'
note 'Make the result citable: commit the change, so that one commit ID identifies it.'
run 'git switch -q -c experiment/card-keyword'
run 'git commit -q -am "Treat card as a billing keyword"'
run 'python3 evals/run_eval.py card-keyword'
run 'cd ../docqa && git worktree list'
lab_end

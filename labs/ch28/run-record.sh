#!/usr/bin/env bash
# Chapter 28, section 28.7: the commit ID alone does not identify what ran. A standard-library
# function records the commit and the dirty state; two runs from the same commit with different
# code are told apart; a tracked run from a dirty tree is refused.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 run-record
fx_docqa 7

snip 01-function
run "sed -n '19,34p' tools/runinfo.py"

snip 02-clean
run 'python3 tools/runinfo.py'

snip 03-run
run 'python3 evals/run_eval.py baseline'
run 'cat runs/baseline/run.json'

snip 04-dirty
note 'Try an idea without committing it: one more billing keyword.'
run "sed -i.bak 's/\"charged\"/\"charged\", \"card\"/' configs/eval.json && rm configs/eval.json.bak"
run 'git status --short'
run_rc 'python3 evals/run_eval.py tuned'
run 'python3 evals/run_eval.py tuned --allow-dirty'

snip 05-same-commit
note 'Two results, one commit ID. Only the dirty flag and the diff hash tell them apart:'
run 'grep -h -e "\"commit\"" -e "\"dirty\"" -e "\"diff_sha256\"" -e "\"accuracy\"" runs/baseline/run.json runs/tuned/run.json'
run 'ls runs/tuned'
run 'git diff HEAD --binary | shasum -a 256'

snip 06-untracked
hidden 'git restore configs/eval.json'
note 'An untracked file is not in "git diff", and it can still change what runs:'
run "printf 'KEYWORD_OVERRIDES = {}\n' > src/docqa/local_settings.py"
run 'git status --short'
run 'python3 tools/runinfo.py | grep -e dirty -e untracked -A1'
run_rc 'python3 tools/runinfo.py --require-clean'
lab_end

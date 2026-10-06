#!/usr/bin/env bash
# Chapter 28, section 28.12: a professional AI project repository. What is tracked, what is
# on disk but ignored, and the order in which the history was built.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 project-skeleton
fx_docqa 7
hidden 'python3 evals/run_eval.py baseline'

snip 01-tracked
run 'git ls-files'

snip 02-history
run 'git log --oneline --decorate'

snip 03-ignored
note 'On disk but deliberately not in Git:'
run 'git status --short --ignored'
run 'git check-ignore -v data/raw/tickets.csv models/embedder.bin runs/baseline/run.json'

snip 04-pointers
run 'cat data/raw/tickets.csv.ref'
run 'cat models/embedder.bin.ref'
run 'find ../datastore -type f | sort'

snip 05-attributes
run 'cat .gitattributes'
run 'git check-attr -a notebooks/01-error-analysis.ipynb data/raw/tickets.csv.ref'

snip 06-ignore-file
run 'cat .gitignore'

snip 07-clone-setup
note 'What a clone has, and what it does not have:'
run 'git clone -q . ../docqa-asha && cd ../docqa-asha'
run_rc 'git config get filter.nbstrip.clean'
run_rc 'git config get core.hooksPath'
run_rc 'python3 tools/dataref.py verify'
lab_end

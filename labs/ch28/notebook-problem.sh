#!/usr/bin/env bash
# Chapter 28, section 28.3: why a notebook is a bad citizen in Git. It is JSON that stores code,
# outputs and counters together: a rerun changes the file without changing the code, outputs
# carry data and credentials into history, and a line-based merge can leave invalid JSON.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 notebook-problem
hidden 'git init analysis'
cd analysis || exit 1
NB=notebooks/01-error-analysis.ipynb
mkdir -p notebooks
python3 "$KIT/make_notebook.py" 1 > $NB
commit_all 'Add error-analysis notebook'

snip 01-anatomy
note 'One code cell of the committed notebook: source, outputs and a counter in one object.'
run "sed -n '10,29p' $NB"

snip 02-rerun
note 'Run all cells again without editing any code (simulated: the file Jupyter would save):'
python3 "$KIT/make_notebook.py" 2 > $NB
run 'git diff --stat'
run "git diff | grep '^[-+] ' | cut -c1-76"

snip 03-secret
quiet 'git commit -am "Rerun error analysis"'
note 'The first cell printed a credential. It is now in two commits:'
run 'git grep -n "sk-demo" $(git rev-list HEAD) -- notebooks | cut -c1-110'
run "wc -c < $NB"
run "python3 -c \"import json,sys; nb=json.load(open(sys.argv[1])); print(sum(len(json.dumps(c['outputs'])) for c in nb['cells'] if c['cell_type']=='code'), 'bytes of outputs')\" $NB"

snip 04-merge
note 'Two people rerun the same notebook on two branches:'
quiet 'git switch -c asha/rerun'
python3 "$KIT/make_notebook.py" 3 > $NB
quiet 'git commit -am "Rerun after the data fix"'
quiet 'git switch main'
python3 "$KIT/make_notebook.py" 4 > $NB
quiet 'git commit -am "Rerun with the new prompt"'
run_rc 'git merge asha/rerun'
run "grep -c '^<<<<<<<' $NB"
run_rc "python3 -m json.tool $NB > /dev/null"
lab_end

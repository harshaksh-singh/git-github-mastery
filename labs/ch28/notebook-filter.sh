#!/usr/bin/env bash
# Chapter 28, section 28.4: a clean filter that strips notebook outputs, written with the Python
# standard library to show how nbstripout works; what "required" changes; why a clone does not
# have the filter; and the --verify form that CI runs.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 notebook-filter
fx_docqa 3
NB=notebooks/01-error-analysis.ipynb
mkdir -p notebooks tools
cp "$KIT/nbstrip.py" tools/nbstrip.py
python3 "$KIT/make_notebook.py" 1 > $NB

snip 01-the-filter
run "sed -n '10,31p' tools/nbstrip.py"

snip 02-configure
run 'git check-attr filter -- notebooks/01-error-analysis.ipynb'
run 'git config set filter.nbstrip.clean "python3 tools/nbstrip.py"'
run 'git config set filter.nbstrip.smudge cat'
run 'git config set filter.nbstrip.required true'

snip 03-add
run 'git add tools/nbstrip.py notebooks'
run 'git commit -q -m "Add notebook filter and the error-analysis notebook"'
note 'The file on disk still has its outputs. The blob in the repository does not:'
run "grep -c output_type $NB"
run "git cat-file -p HEAD:$NB | grep -c output_type"
run "git cat-file -p HEAD:$NB | sed -n '10,20p'"
run "wc -c < $NB"
run "git cat-file -s HEAD:$NB"

snip 04-rerun
note 'Rerun the notebook (simulated). The file changes; what Git would store does not:'
python3 "$KIT/make_notebook.py" 2 > $NB
run "grep -c 'not-a-real-key-0002' $NB"
run 'git status --short'
run 'git diff --stat'

snip 05-real-change
note 'A change to the code of a cell is still a change:'
run "sed -i.bak 's/plot_confusion(errors)/plot_confusion(errors, normalize=True)/' $NB && rm $NB.bak"
run 'git status --short'
run 'git diff'
quiet 'git commit -am "Normalize the confusion matrix"'

snip 06-required
note 'required = true: a filter that cannot run stops the operation instead of passing content through.'
run 'git config set filter.nbstrip.clean nbstrip-not-installed'
python3 "$KIT/make_notebook.py" 3 | sed 's/plot_confusion(errors)/plot_confusion(errors, normalize=False)/' > $NB
run_rc "git add $NB"
run 'git status --short'
note 'The same with required unset: the outputs go in, with only a warning.'
run 'git config unset filter.nbstrip.required'
run_rc "git add $NB"
run "git cat-file -p :$NB | grep -c output_type"
hidden "git restore --staged $NB && git restore $NB"
hidden 'git config set filter.nbstrip.clean "python3 tools/nbstrip.py" && git config set filter.nbstrip.required true'

hidden 'git init --bare ../server.git && git remote add origin ../server.git && git push -u origin main'
snip 07-clone
note 'A clone gets the attribute and the script, not the configuration:'
run 'git clone -q ../server.git ../docqa-asha && cd ../docqa-asha'
run 'git check-attr filter -- notebooks/01-error-analysis.ipynb'
run_rc 'git config get filter.nbstrip.clean'
note 'Asha reruns the notebook and commits. Nothing strips it and nothing warns her:'
python3 "$KIT/make_notebook.py" 5 | sed 's/plot_confusion(errors)/plot_confusion(errors, normalize=True)/' > $NB
run 'git commit -q -am "Rerun error analysis" && git push -q'
run "git cat-file -p HEAD:$NB | grep -c output_type"

snip 08-verify-in-ci
note 'What CI runs on a fresh checkout of each commit:'
run_rc 'python3 tools/nbstrip.py --verify $(git ls-files "*.ipynb")'
run 'git switch -q --detach HEAD~1'
run_rc 'python3 tools/nbstrip.py --verify $(git ls-files "*.ipynb")'
lab_end

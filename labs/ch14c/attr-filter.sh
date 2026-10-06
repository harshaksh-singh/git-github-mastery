#!/usr/bin/env bash
# Chapter 14C, section 14C.8: clean and smudge filters. A clean filter that keeps notebook
# outputs out of the repository, "git add --renormalize" for notebooks committed before the
# filter existed, and what a clone knows about the filter: the attribute, not the driver.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c attr-filter

quiet 'git init --bare server.git'
quiet 'git clone server.git analysis'
cd analysis || exit 1
quiet 'mkdir tools'
quiet "cp '$LAB_SCRIPT_DIR/files/nbstrip.py' tools/nbstrip.py && cp '$LAB_SCRIPT_DIR/files/eda-run1.ipynb' eda.ipynb"
quiet "git add . && git commit -m 'Add error-analysis notebook' && git push -u origin main"

snip 01-before
note 'The notebook was committed with its outputs:'
run 'grep -c output_type eda.ipynb'
run 'git cat-file -p HEAD:eda.ipynb | grep -c output_type'

snip 02-define
run 'cat tools/nbstrip.py'
run "printf '*.ipynb filter=nbstrip\n' > .gitattributes"
run "git config set filter.nbstrip.clean 'python3 tools/nbstrip.py'"
run 'git config set filter.nbstrip.smudge cat'

snip 03-renormalize
run 'git status -s'
run 'git add --renormalize .'
run 'git status -s'
run 'git add .gitattributes && git commit -q -m "Strip notebook outputs on the way into the repository"'
run 'git cat-file -p HEAD:eda.ipynb | grep -c output_type'
run 'grep -c output_type eda.ipynb'

snip 04-rerun
note 'Run the notebook again (simulated with sed): a new execution count, the same source.'
run "sed 's/\"execution_count\": 7/\"execution_count\": 8/' eda.ipynb > eda.tmp && mv eda.tmp eda.ipynb"
run 'grep execution_count eda.ipynb'
run 'git status -s'
run 'git diff --stat'

quiet 'git push'
quiet "cp '$LAB_SCRIPT_DIR/files/eda-run2.ipynb' ../executed.ipynb"

snip 05-clone
run 'cd ..'
run 'git clone -q server.git analysis-asha'
run 'cd analysis-asha'
run 'git check-attr filter -- eda.ipynb'
run_rc 'git config get filter.nbstrip.clean'
note 'Asha runs the notebook (simulated by copying an executed copy over it) and commits.'
note 'Nothing strips her outputs, and nothing warns her:'
run 'cp ../executed.ipynb eda.ipynb'
run 'git commit -q -am "Rerun error analysis"'
run 'git cat-file -p HEAD:eda.ipynb | grep -c output_type'

lab_end

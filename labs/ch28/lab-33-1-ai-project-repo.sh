#!/usr/bin/env bash
# Lab 33.1 replay: build a professional AI project repository from an empty folder, in the
# order that keeps mistakes out of history; then commit a notebook from a clone that has no
# filter, detect it with the CI entry point, and repair the unpushed commit.
# Lab manual: lab-manual/m33-ai-ml-workflows.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 lab-33-1-ai-project-repo
fx_kit

snip 01-rules-first
run 'git init -q docqa && cd docqa'
run 'cp ../kit/.gitignore ../kit/.gitattributes .'
run 'git add . && git commit -q -m "Add ignore rules and attributes before any content"'

snip 02-package
run 'cp -R ../kit/pyproject.toml ../kit/requirements.lock ../kit/README.md ../kit/src ../kit/tests .'
run 'python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'git add . && git commit -q -m "Add package skeleton, lock file and tests"'

snip 03-checks
run 'mkdir tools && cp ../kit/tools/checks.py tools/ && cp -R ../kit/hooks ../kit/ci .'
run 'git config set core.hooksPath hooks'
run 'git add . && git commit -q -m "Add repository checks, shared hook and CI entry point"'

snip 04-notebook
run 'cp ../kit/tools/nbstrip.py tools/'
run 'git config set filter.nbstrip.clean "python3 tools/nbstrip.py"'
run 'git config set filter.nbstrip.smudge cat'
run 'git config set filter.nbstrip.required true'
run 'cp -R ../kit/notebooks .'
run 'git add . && git commit -q -m "Add notebook filter and the error-analysis notebook"'
run 'grep -c output_type notebooks/01-error-analysis.ipynb'
run 'git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type'

snip 05-data
run 'cp ../kit/tools/dataref.py tools/ && cp -R ../kit/data .'
run 'git status --short'
run 'python3 tools/dataref.py add data/raw/tickets.csv'
run 'git status --short'
run 'git add . && git commit -q -m "Version the ticket data set by reference"'

snip 06-eval
run 'cp ../kit/tools/runinfo.py tools/ && cp -R ../kit/evals ../kit/configs ../kit/prompts .'
run 'git add . && git commit -q -m "Add evaluation config, prompt and run recorder"'
run 'python3 evals/run_eval.py baseline'

snip 07-serving
run 'cp -R ../kit/Dockerfile ../kit/.dockerignore ../kit/models .'
run 'python3 tools/dataref.py add models/embedder.bin'
run 'git add . && git commit -q -m "Add serving image definition and model pointer"'
run 'git tag -a v0.1.0 -m "docqa 0.1.0"'

snip 08-result
run 'git log --oneline --decorate'
run 'git status --short --ignored'
run 'git ls-files | wc -l'
run 'sh ci/check.sh "$(git rev-list --max-parents=0 HEAD)"'

snip 09-failure
note 'Failure scenario: you clone the project on another machine and skip the README.'
run 'git clone -q . ../docqa-laptop && cd ../docqa-laptop'
run 'cp ../kit/notebooks/01-error-analysis.ipynb notebooks/02-prompt-comparison.ipynb'
run 'git add notebooks && git commit -q -m "Add prompt comparison notebook"'
run 'git grep -c "sk-demo" HEAD -- notebooks'
run_rc 'sh ci/check.sh origin/main'

snip 10-recovery
note 'The commit is not pushed. Configure the clone as the README says, then re-clean and amend:'
run 'git config set filter.nbstrip.clean "python3 tools/nbstrip.py"'
run 'git config set filter.nbstrip.smudge cat'
run 'git config set filter.nbstrip.required true'
run 'git config set core.hooksPath hooks'
run 'git add --renormalize notebooks'
run 'git status --short'
run 'git commit -q --amend --no-edit'

snip 11-verify
run_rc 'git grep -c "sk-demo" HEAD -- notebooks'
run_rc 'sh ci/check.sh origin/main'
note 'The first version of the commit is still in this clone, reachable from the reflog:'
run 'git grep -c "sk-demo" "HEAD@{1}" -- notebooks'
lab_end

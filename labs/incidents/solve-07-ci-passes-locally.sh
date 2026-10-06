#!/usr/bin/env bash
# Replay of incident 7 (CI passes locally, fails on GitHub Actions). The workflow cannot be run
# here. The replay shows what plain Git can show: the clone the runner makes by default (one
# commit, no tags) and what "git describe" says in it, the file-name case mismatch that waits
# behind the first failure, and the fix. Transcripts for Chapter 30 and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-07-ci-passes-locally
incident_load 07-ci-passes-locally

snip 01-local
run 'cd you'
run 'git log --oneline --decorate -5'
run 'cat scripts/version.sh'
run_rc 'bash scripts/version.sh'

snip 02-workflow
run "grep -n -A1 'actions/checkout' .github/workflows/ci.yml"
run "git log --oneline -- scripts/version.sh .github/workflows/ci.yml"

snip 03-runner-clone
note 'What the checkout step does by default, reproduced with Git: depth 1 and no tags.'
run 'git clone --quiet --depth 1 --no-tags "file://$PWD/../server.git" ../runner-checkout'
run 'cd ../runner-checkout'
run 'git rev-parse --is-shallow-repository'
run 'git rev-list --count HEAD'
run 'git tag --list'
run_rc 'bash scripts/version.sh'

snip 04-remedy-proof
note 'What "fetch-depth: 0" changes: all history and the tags.'
run 'git fetch --quiet --unshallow --tags'
run 'git rev-list --count HEAD'
run 'git tag --list'
run_rc 'bash scripts/version.sh'

snip 05-second-failure
run 'cd ../you'
note 'Would the tests pass on Linux once the version step is fixed? Names as Git stores them:'
run 'git ls-files templates'
run "grep -n 'tmpl' reports/render.py"
run "git log --oneline -S'Summary.md.tmpl' -- reports/render.py"

snip 06-fix
run 'git switch -c fix/ci-checkout'
note '(edit .github/workflows/ci.yml: add "with: fetch-depth: 0" to the checkout step)'
note '(edit reports/render.py: spell the template name as it is tracked)'
quiet "sed -i.bak -e 's|# v7.0.1\$|# v7.0.1\\
        with:\\
          fetch-depth: 0|' .github/workflows/ci.yml && rm .github/workflows/ci.yml.bak"
quiet "sed -i.bak -e 's/Summary.md.tmpl/summary.md.tmpl/' reports/render.py && rm reports/render.py.bak"
run 'git diff'

snip 07-publish
run "git commit -a -m 'Fetch full history and tags in CI; fix template name case'"
run 'git push -u origin fix/ci-checkout'
run 'cd ..'
quiet 'rm -rf runner-checkout'
show_check
incident_done

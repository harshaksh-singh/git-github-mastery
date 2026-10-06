#!/usr/bin/env bash
# Chapter 15, section 15.13: the professional repository layout as tracked files, the issue
# form that GitHub renders, and the check that a local secret file is ignored.
# The Dockerfile in this layout was not built here (nothing is downloaded while authoring).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 repo-layout
make_registry "$LAB_DIR/prompt-registry"
add_professional_extras
commit_paths 'Add license, code owners, release script, config and Dockerfile' LICENSE .github/CODEOWNERS scripts configs Dockerfile

snip 01-tracked-files
run 'git ls-files'

snip 02-issue-form
run 'cat .github/ISSUE_TEMPLATE/1-bug.yml'

snip 03-chooser-and-pr-template
run 'cat .github/ISSUE_TEMPLATE/config.yml'
run 'cat .github/pull_request_template.md'

snip 04-ignored-secret
run "printf 'LLM_API_KEY=FAKE-KEY-for-the-lab\n' > .env"
run 'git status --short'
run 'git check-ignore -v .env'

snip 05-tests
run 'python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'git status --short'

lab_end

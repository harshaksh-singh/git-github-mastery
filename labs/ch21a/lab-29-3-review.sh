#!/usr/bin/env bash
# Lab 29.3 replay: the pull request diff to review (constructed for the exercise), produced by Git.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21a lab-29-3-review
. "$LAB_SCRIPT_DIR/fixture.bash"
review_repo

snip 01-overview
run 'git log --oneline --format="%h %an: %s" main..feature/coverage-comment'
run 'git diff --stat main...feature/coverage-comment'

snip 02-diff-ci
run 'git diff main...feature/coverage-comment -- .github/workflows/ci.yml'

snip 03-diff-release
run 'git diff main...feature/coverage-comment -- .github/workflows/release.yml'

snip 04-added-lines
note 'The branch versions of both files, searched for the patterns of the checklist.'
run 'git grep -n -E "pull_request_target|allow-unsafe|self-hosted|\| bash|@v[0-9]|secrets\.|write" feature/coverage-comment -- .github/workflows'

snip 05-wrong-base
note 'Two dots compare the tips. After main moves, the same command shows changes the author never made.'
quiet 'printf "\nRuns on GitHub Actions.\n" >> README.md && git commit -am "Describe CI in the README"'
run 'git diff --stat main..feature/coverage-comment'
note 'Three dots compare the branch with the merge base, as the pull request page does.'
run 'git diff --stat main...feature/coverage-comment'

lab_end

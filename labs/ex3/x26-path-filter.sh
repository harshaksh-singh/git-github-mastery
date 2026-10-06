#!/usr/bin/env bash
# Exercise 26.4 (Module 26): predict a path filter with the two diffs that GitHub Actions
# documents: three dots for a pull request, two dots between old and new tip for a push.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x26-path-filter
make_server
new_clone you
new_clone asha
enter you
hidden 'git switch -c docs/chunk-sizes'
split_v2
commit_all 'Try an overlap parameter'
split_v1
commit_all 'Take the overlap parameter out again'
printf '# Chunk sizes\n\nUse 200 characters for chat logs.\n' | put docs/chunk-sizes.md
commit_all 'Document chunk sizes'
hidden 'git push -u origin docs/chunk-sizes'
enter asha
config_v2
commit_all 'Double the default chunk size'
hidden 'git push origin main'
enter you
hidden 'git fetch'

snip 01-setup
run 'git log --oneline --stat --format="%h %s" origin/main..docs/chunk-sizes'
run 'git log --oneline -1 --stat --format="%h %s" origin/main'

snip 02-pull-request
run 'git diff --name-only origin/main...docs/chunk-sizes'
run 'git diff --name-only origin/main..docs/chunk-sizes'

snip 03-push
note 'The first commit is on the server. You push the second and third together: old tip, new tip.'
run "git diff --name-only docs/chunk-sizes~2..docs/chunk-sizes"
note 'Instead: the first two commits are on the server. You push the third alone.'
run "git diff --name-only docs/chunk-sizes~1..docs/chunk-sizes"

lab_end

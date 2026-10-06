#!/usr/bin/env bash
# Final test, section 11 (GitHub Actions): interpretation item I1, a local simulation of what a
# job has after a checkout of one commit. Nothing here talks to GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s11

quiet 'git init -q tariffs'
cd tariffs || exit 1
quiet 'git commit -q --allow-empty -m "Add the tariff table"'
quiet 'git commit -q --allow-empty -m "Add peak tariffs"'
quiet 'git tag -a v1.4.0 -m "Release 1.4.0"'
quiet 'git commit -q --allow-empty -m "Add weekend tariffs"'
quiet 'git commit -q --allow-empty -m "Round to two decimals"'
cd "$LAB_DIR" || exit 1
snip i1-transcript
note 'On the laptop:'
run 'git -C tariffs describe'
note 'What the job has: one commit, fetched the way a default checkout step fetches it.'
run 'git clone -q --depth 1 --no-tags "file://$PWD/tariffs" job'
run 'cd job'
run 'git rev-parse --is-shallow-repository'
run 'git rev-list --count HEAD'
run 'git tag --list'
run_rc 'git describe'
run 'git describe --always'
snip i1-answer
run 'git fetch -q --unshallow --tags'
run 'git rev-list --count HEAD'
run 'git describe'
lab_end

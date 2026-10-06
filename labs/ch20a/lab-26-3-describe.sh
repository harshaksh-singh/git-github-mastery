#!/usr/bin/env bash
# Replay of the local steps of Lab 26.3: what `git describe --tags --always` prints in your
# full clone, in a clone like the default checkout, and in one like `fetch-depth: 0`.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a lab-26-3-describe
scenario_base
cd "$LAB_DIR/you/inventory-api" || exit 1

snip 01-predict
run 'git tag --list -n1'
run 'git describe --tags --always'
note 'A clone like the default checkout (one commit, no tags):'
run 'git clone --quiet --depth 1 --no-tags "file://$PWD" ../default-checkout'
run 'git -C ../default-checkout describe --tags --always'
note 'A clone like fetch-depth: 0 (all history, all tags):'
run 'git clone --quiet "file://$PWD" ../full-checkout'
run 'git -C ../full-checkout describe --tags --always'

snip 02-tagged-commit
note 'On the tagged commit itself the description is the tag name:'
run 'git describe --tags --always v0.1.0'
run 'git cat-file -t v0.1.0'
run 'git rev-parse v0.1.0 "v0.1.0^{commit}"'
lab_end

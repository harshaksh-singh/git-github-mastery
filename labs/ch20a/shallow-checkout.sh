#!/usr/bin/env bash
# What the default actions/checkout leaves on a runner, reproduced with plain Git: one commit,
# no tags. Then why `git describe` fails there, and the two repairs. Chapter 20A, section 20A.8.
# The runner's own Git commands are not published as an interface; these are the author's
# equivalents for the documented defaults fetch-depth: 1 and fetch-tags: false.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a shallow-checkout
scenario_base
cd "$LAB_DIR" || exit 1
HUB="file://$LAB_DIR/hub/inventory-api.git"

snip 01-full-clone
note 'Your clone: three commits, one annotated tag.'
run 'cd you/inventory-api'
run 'git log --oneline --decorate'
run 'git describe --tags'
run 'cd ../..'

snip 02-runner-clone
note 'HUB is a file:// URL of the bare repository that plays GitHub.'
note 'fetch-depth: 1 and fetch-tags: false, as a clone:'
run 'git clone --depth 1 --no-tags "$HUB" runner'
run 'cd runner'
run 'git log --oneline --decorate'
run 'git rev-parse --is-shallow-repository'
run 'cat .git/shallow'
run 'git tag --list'
run 'git rev-list --count HEAD'

snip 03-describe-fails
run_rc 'git describe --tags'
run_rc 'git describe --tags --always'
note 'History questions get wrong answers, not errors:'
run 'git log --oneline -- java-service/pom.xml'
run_rc 'git merge-base HEAD origin/main~1'

snip 04-tags-are-not-enough
note 'fetch-tags: true with depth 1: the tag arrives, its commit is not an ancestor we have.'
run 'git fetch --depth 1 origin "refs/tags/*:refs/tags/*"'
run 'git tag --list'
run_rc 'git describe --tags'

snip 05-full-history
note 'fetch-depth: 0, as a repair of this clone:'
run 'git fetch --unshallow --tags'
run 'git rev-parse --is-shallow-repository'
run 'git rev-list --count HEAD'
run 'git describe --tags'
run 'git log --oneline -- java-service/pom.xml'
lab_end

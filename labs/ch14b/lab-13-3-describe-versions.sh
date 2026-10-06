#!/usr/bin/env bash
# Lab 13.3 replay: git describe as a version string, a release branch with a backported
# fix and a patch release, and the shallow clone in which describe has nothing to go on.
# Lab manual: lab-manual/m13-tags-versions.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-13-3-describe-versions
scenario_13_3
as config

snip 01-describe
run 'cd inference-gateway'
run 'git log --oneline --decorate'
run 'git describe'
run 'git describe --tags'
run 'git describe --long v1.2.0'
run 'git describe --abbrev=0'
run 'git log --oneline "$(git describe --abbrev=0)..HEAD"'

snip 02-dirty
run "printf '# local hack\n' >> gateway/batch.py"
run 'git describe --dirty'
run 'git restore gateway/batch.py'
run 'git describe --dirty'

snip 03-release-branch
run 'git switch -c release/1.2 v1.2.0'
run 'git cherry-pick -x main~1'
run 'git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"'
run 'git log --graph --oneline --decorate --all'

snip 04-two-lines
run 'git describe release/1.2'
run 'git describe main'
run 'git tag --merged main'
run 'git cherry -v release/1.2 main'

snip 05-next-minor
run 'git switch -q main'
run 'git tag -a v1.3.0-rc.1 -m "inference-gateway 1.3.0, release candidate 1"'
run 'git commit -q --allow-empty -m "Update changelog for 1.3.0"'
run 'git tag -a v1.3.0 -m "inference-gateway 1.3.0"'
run 'git tag --list "v*" --sort=version:refname'
run 'git -c versionsort.suffix=-rc tag --list "v*" --sort=version:refname'
run 'git commit -q --allow-empty -m "Start 1.4 development"'
run 'git describe'

snip 06-failure
note 'A build machine checks the project out the cheap way: one commit, no tags.'
run 'cd ..'
run 'git clone -q --depth 1 "file://$PWD/inference-gateway" build'
run 'cd build'
run 'git log --oneline'
run 'git tag'
run_rc 'git describe'
run 'git describe --always'

snip 07-recovery
run 'git rev-parse --is-shallow-repository'
run 'git fetch -q --unshallow'
run 'git rev-parse --is-shallow-repository'
run 'git describe'

snip 08-verify
run 'git tag --list "v*" --sort=version:refname'
run 'git branch -r'
run 'git -C ../inference-gateway describe release/1.2'

lab_end

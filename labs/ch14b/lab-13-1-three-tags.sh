#!/usr/bin/env bash
# Lab 13.1 replay, deterministic part: a lightweight and an annotated tag at the object
# level, then an annotated tag on the wrong commit and its repair before anyone has seen it.
# The signed tag is in lab-13-1-three-tags-volatile.sh.
# Lab manual: lab-manual/m13-tags-versions.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-13-1-three-tags
scenario_13_1
as config

snip 01-lightweight
run 'cd inference-gateway'
run 'git log --oneline'
run 'git tag staging-ok'
run 'cat .git/refs/tags/staging-ok'
run 'git cat-file -t staging-ok'

snip 02-annotated
run 'git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."'
run 'cat .git/refs/tags/v1.0.0'
run 'git cat-file -t v1.0.0'
run 'git cat-file -p v1.0.0'

snip 03-peel
run "git rev-parse v1.0.0 'v1.0.0^{commit}' 'v1.0.0^{tree}'"
run 'git show-ref --tags --dereference'
run "git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) -> %(*objecttype) %(*objectname:short)'"
run 'git describe'
run 'git describe --tags'

# In the hands-on lab, step 4 creates the signed tag v0.9.0 here (replayed with real keys in
# lab-13-1-three-tags-volatile.sh). An annotated tag of the same name stands in for it, so
# that the listings below show the same tag names as your sandbox.
hidden 'git tag -a v0.9.0 -m "inference-gateway 0.9.0 (preview)" HEAD~1'

snip 04-failure
note 'The next release is tagged in a hurry, one commit too far: the tip is unfinished work.'
run "printf 'burst: 20\n' >> config/limits.yaml"
run 'git commit -q -am "Allow short bursts"'
run "printf 'experimental: true\n' >> config/limits.yaml"
run 'git commit -q -am "WIP: experiment flag"'
run 'git tag -a v1.1.0 -m "inference-gateway 1.1.0"'
run 'git log --oneline --decorate -3'

snip 05-recovery
note 'The tag was never pushed, so it may be replaced. Note the old tag object ID first.'
run 'git rev-parse --short v1.1.0'
run_rc 'git tag -a v1.1.0 -m "inference-gateway 1.1.0" HEAD~1'
run 'git tag -f -a v1.1.0 -m "inference-gateway 1.1.0" HEAD~1'
run 'git log --oneline --decorate -3'

snip 06-verify
run 'git tag -n1'
run "git rev-parse --short 'v1.1.0^{commit}' && git rev-parse --short HEAD~1"
run 'git fsck --no-reflogs'
run_rc 'git reflog show refs/tags/v1.1.0'

lab_end

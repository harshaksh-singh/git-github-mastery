#!/usr/bin/env bash
# Chapter 14B, section 14B.14: a release branch on the Git side. Branch from the tag, fix on
# main first, copy the fix to the release branch, tag the patch release, and see what
# git describe and git tag --merged say on each line.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b release-branch
make_gateway "$LAB_DIR/inference-gateway"
hidden 'git tag -a v1.2.0 -m "inference-gateway 1.2.0"'
commit_file gateway/stream.py 'def stream(chunks):\n    yield from chunks\n' 'Add streaming responses'
commit_file config/limits.yaml 'requests_per_minute: 60\nmax_tokens: 4096\n' 'Fix max_tokens limit'
commit_file gateway/batch.py 'def batch(prompts):\n    return list(prompts)\n' 'Add batch endpoint'

snip 01-branch-from-tag
run 'git log --oneline --decorate'
run 'git switch -c release/1.2 v1.2.0'

snip 02-backport
run 'git cherry-pick -x main~1'
run 'git log -1 --format=%B'
run 'git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"'

snip 03-two-lines
run 'git log --graph --oneline --decorate --all'
run 'git describe release/1.2'
run 'git describe main'

snip 04-what-contains-the-fix
run 'git tag --contains main~1'
run 'git tag --contains release/1.2'
run 'git tag --merged main'
run 'git cherry -v release/1.2 main'

snip 05-next-minor
run 'git switch -q main'
run 'git tag -a v1.3.0 -m "inference-gateway 1.3.0"'
run 'git tag --sort=version:refname'
run 'git describe main'
run 'git log --oneline v1.2.1..v1.3.0'
run 'git log --oneline --cherry-pick --right-only v1.2.1...v1.3.0'

lab_end

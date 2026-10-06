#!/usr/bin/env bash
# Chapter 14B, section 14B.10: tags travel only when asked. Pushing one tag, following
# tags, what a colleague's fetch brings, and deleting a tag here, there and in other clones.
# The mechanics of fetch and push are Chapter 12; this demo is about the tag namespace.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b tag-push
make_server_and_clones you asha
enter you

snip 01-not-pushed
run 'git tag -a v1.0.0 -m "inference-gateway 1.0.0"'
run "printf 'burst: 20\n' >> config/limits.yaml"
run 'git commit -q -am "Allow short bursts"'
run 'git push'
run 'git ls-remote --tags origin'

snip 02-push-one
run 'git push origin v1.0.0'
run 'git ls-remote --tags origin'

snip 03-follow-tags
run 'git tag -a v1.0.1 -m "inference-gateway 1.0.1"'
run 'git tag canary-ok'
run "printf 'retry_after_seconds: 2\n' >> config/limits.yaml"
run 'git commit -q -am "Tell clients when to retry"'
run 'git tag wip-retry-header'
run 'git push --follow-tags'
run 'git ls-remote --tags origin'

snip 04-colleague-fetches
as asha
run 'cd ../../asha/inference-gateway'
run 'git fetch'
run 'git tag'

snip 05-delete
as you
run 'cd ../../you/inference-gateway'
run 'git tag -d canary-ok'
run 'git push origin --delete v1.0.1'
run 'git ls-remote --tags origin'
run 'git tag'

snip 06-other-clones-keep-it
as asha
run 'cd ../../asha/inference-gateway'
run 'git tag bisect-good-2026-09-07 HEAD~1'
run 'git fetch --prune'
run 'git tag'
run 'git fetch --prune --prune-tags'
run 'git tag'

lab_end

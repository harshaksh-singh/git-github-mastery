#!/usr/bin/env bash
# Lab 18.3 replay: a bundle round trip between a connected site and an isolated one. A full
# bundle out, an incremental bundle out, work done at the isolated site and sent back, and an
# incremental bundle that arrives after the one before it was lost.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 lab-18-3-bundle-round-trip
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-18-3-bundles.sh" || exit 1

snip 01-full-bundle
run 'mkdir transfer'
run 'cd orbit'
run 'git bundle create ../transfer/orbit-full.bundle --all'
run 'git bundle verify ../transfer/orbit-full.bundle | tail -2'
note 'Remember what the other site now has (the manual of git bundle uses a tag for this):'
run 'git tag lastbundle/site-b main'
run 'cd ..'

snip 02-site-b
run 'git clone transfer/orbit-full.bundle site-b'
run 'git -C site-b log --oneline -1'
run 'git -C site-b branch -a'
run 'git -C site-b tag -l | wc -l'

snip 03-update-out
note 'Work continues at the connected site:'
run 'cd orbit'
run "printf 'timeout_ms: 600\\nupstream: ranker\\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 600 ms'"
run "git tag -a gateway/v1.2.0 -m 'gateway 1.2.0'"
run 'git bundle create ../transfer/orbit-update-1.bundle lastbundle/site-b..main gateway/v1.2.0'
run 'git bundle verify ../transfer/orbit-update-1.bundle'
run 'git tag -f lastbundle/site-b main'
run 'cd ..'

snip 04-update-in
run 'cd site-b'
run_rc 'git bundle verify --quiet ../transfer/orbit-update-1.bundle'
run "git fetch ../transfer/orbit-update-1.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'"
run 'git merge --ff-only origin/main'

snip 05-way-back
note 'Work at the isolated site, sent back the same way:'
run "printf 'top_k: 20\\nmodel: overlap-v1\\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'"
run 'git bundle create ../transfer/site-b-1.bundle origin/main..main'
run 'git bundle list-heads ../transfer/site-b-1.bundle'
run 'cd ../orbit'
run 'git fetch ../transfer/site-b-1.bundle main:refs/remotes/site-b/main'
run 'git merge --ff-only site-b/main'
run 'git log --oneline -3'

snip 06-failure
note 'Failure scenario: two more updates are cut, and only the second one reaches the site.'
run "printf 'BATCH_SIZE = 1000\\n' > services/ingest/settings.py && git commit -q -am 'ingest: raise the batch size to 1000'"
run 'git bundle create ../transfer/orbit-update-2.bundle lastbundle/site-b..main && git tag -f lastbundle/site-b main'
run "printf 'epochs: 20\\nlearning_rate: 0.0003\\nbatch_size: 32\\n' > pipelines/training/config.yaml && git commit -q -am 'training: train for 20 epochs'"
run 'git bundle create ../transfer/orbit-update-3.bundle lastbundle/site-b..main && git tag -f lastbundle/site-b main'
run 'rm ../transfer/orbit-update-2.bundle'
run 'cd ../site-b'
run_rc 'git bundle verify ../transfer/orbit-update-3.bundle'
run_rc "git fetch ../transfer/orbit-update-3.bundle 'refs/heads/*:refs/remotes/origin/*'"

snip 07-recovery
note 'The site reports what it has:'
run 'git rev-parse main'
_have=$(git rev-parse main)
note 'The connected site cuts a bundle from exactly there:'
run 'cd ../orbit'
run "git bundle create ../transfer/orbit-catchup.bundle $_have..main"
run 'git bundle verify ../transfer/orbit-catchup.bundle 2>&1 | grep -A1 requires'
run 'cd ../site-b'
run_rc 'git bundle verify --quiet ../transfer/orbit-catchup.bundle'
run "git fetch ../transfer/orbit-catchup.bundle 'refs/heads/*:refs/remotes/origin/*'"
run 'git merge --ff-only origin/main'

snip 08-verification
run 'git -C ../orbit rev-parse main'
run 'git rev-parse main origin/main'
run 'git log --oneline -5'
run 'git tag -l | wc -l'
run_rc 'git fsck'

lab_end

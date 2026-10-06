#!/usr/bin/env bash
# Chapter 26, section 26.14: bundles beyond the basics of Chapters 12 and 13. An incremental
# bundle and its prerequisite, the header of the file, and a clone seeded from a bundle.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 bundles
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
cd orbit || exit 1
quiet 'git config set maintenance.auto false'

snip 01-full-and-incremental
run 'git bundle create ../orbit-full.bundle --all'
run 'git bundle verify ../orbit-full.bundle | tail -2'
note 'Two more commits and a release tag, then a bundle of only what is new since the last one:'
quiet "printf 'timeout_ms: 600\nupstream: ranker\n' > services/gateway/config.yaml && git commit -am 'gateway: lower the upstream timeout to 600 ms'"
quiet "printf 'timeout_ms: 600\nupstream: ranker\nretries: 2\n' > services/gateway/config.yaml && git commit -am 'gateway: retry the upstream twice'"
quiet "git tag -a gateway/v1.2.0 -m 'gateway 1.2.0'"
run 'git log --oneline schemas/v1.1.0..main'
run 'git bundle create ../orbit-update.bundle schemas/v1.1.0..main gateway/v1.2.0'
run 'git bundle verify ../orbit-update.bundle'

snip 02-header
note 'A bundle is a short text header followed by a pack. The header of the incremental bundle:'
run 'head -n 4 ../orbit-update.bundle'
run 'head -n 2 ../orbit-full.bundle | cut -c1-70'

snip 03-prerequisite
run 'cd ..'
note 'A repository that was cloned from the full bundle has the prerequisite commit:'
run 'git clone -q orbit-full.bundle site-b'
run_rc 'git -C site-b bundle verify --quiet ../orbit-update.bundle'
run "git -C site-b fetch ../orbit-update.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'"
run 'git -C site-b merge --ff-only origin/main'
note 'An empty repository does not:'
run 'git init -q empty'
run_rc 'git -C empty bundle verify ../orbit-update.bundle'
run_rc 'git clone orbit-update.bundle from-update'

snip 04-bundle-uri
note 'A clone that takes the bulk from a bundle and only the rest from the server:'
quiet 'git -C orbit push ../server/orbit.git main gateway/v1.2.0'
run 'GIT_TRACE_PACKET="$PWD/seeded.trace" git clone -q --bundle-uri="$PWD/orbit-full.bundle" "file://$PWD/server/orbit.git" seeded'
run "git -C seeded for-each-ref --format='%(refname)' | sed 's,^\\(refs/[a-z]*\\)/.*,\\1,' | sort | uniq -c"
note 'The request to the server offers what the bundle brought:'
run "sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^have'"
run "sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^want'"
run 'git -C seeded log --oneline -3'

lab_end

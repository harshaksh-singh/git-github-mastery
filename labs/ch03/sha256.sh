#!/usr/bin/env bash
# Chapter 3, section 3.14: SHA-1 with collision detection versus SHA-256.
# A SHA-256 repository next to a SHA-1 repository: same content, different IDs, and no way to
# exchange objects between the two formats.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 sha256

snip 01-build
note 'What this Git was built with:'
run "git version --build-options | grep -e SHA -e default"

snip 02-init
run 'git init --quiet sha1-repo'
run 'git init --quiet --object-format=sha256 sha256-repo'
run 'cat sha256-repo/.git/config'
run 'git -C sha1-repo rev-parse --show-object-format'
run 'git -C sha256-repo rev-parse --show-object-format'

snip 03-ids
note 'The same sixteen bytes, hashed by each repository:'
run "printf 'retry_limit = 3\\n' > sha1-repo/config.toml"
run 'cp sha1-repo/config.toml sha256-repo/config.toml'
run 'git -C sha1-repo hash-object config.toml'
run 'git -C sha256-repo hash-object config.toml'
note 'The object format is the same; only the hash function differs:'
run "printf 'blob 16\\0retry_limit = 3\\n' | shasum -a 256"
quiet 'git -C sha1-repo add config.toml && git -C sha1-repo commit -m "Add service configuration"'
quiet 'git -C sha256-repo add config.toml && git -C sha256-repo commit -m "Add service configuration"'
run 'git -C sha256-repo log --oneline'
run 'git -C sha256-repo cat-file -p HEAD'
run 'cat sha256-repo/.git/refs/heads/main'

snip 04-no-interop
note 'The two formats cannot exchange objects, in either direction:'
run_rc 'git -C sha1-repo fetch ../sha256-repo main'
run_rc 'git -C sha1-repo push ../sha256-repo main:refs/heads/from-sha1'
run_rc 'git -C sha256-repo push ../sha1-repo main:refs/heads/from-sha256'
note 'A clone adopts the format of what it clones:'
run 'git clone --quiet sha256-repo sha256-clone'
run 'git -C sha256-clone rev-parse --show-object-format'

snip 05-forty-hex
note 'A check that assumes forty hexadecimal digits accepts one repository and rejects the other:'
run "git -C sha1-repo rev-parse HEAD | grep -E -c '^[0-9a-f]{40}\$'"
run "git -C sha256-repo rev-parse HEAD | grep -E -c '^[0-9a-f]{40}\$'"

lab_end

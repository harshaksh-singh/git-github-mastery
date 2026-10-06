#!/usr/bin/env bash
# Lab 42.1 replay: create a repository with the planned Git 3.0 formats (SHA-256 object IDs,
# reftable ref storage), convert an existing history to SHA-256, and migrate an existing
# repository to reftable. Failure: a script that reads .git/refs/heads/main and expects forty
# hexadecimal digits breaks in two different ways. Recovery: ask Git instead of reading files.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d lab-42-1-sha256-reftable
fx_42_1

snip 01-today
run 'cd inference'
run 'git repo info --all'
run 'git log --oneline --graph --all'
run 'cat ../scripts/release-id.sh'
run_rc 'sh ../scripts/release-id.sh'

snip 02-future
run 'cd ..'
run 'git init --object-format=sha256 --ref-format=reftable future'
run 'cd future'
run 'git repo info --all'
run 'ls .git'
run 'cat .git/HEAD'
run "printf 'def predict(batch):\n    return model(batch)\n' > serve.py && git add serve.py"
run 'git commit -q -m "Add inference service"'
run 'git log --format="%H %s"'
run 'git refs list'

snip 03-convert
note 'Object formats cannot be mixed, so history moves as a stream and every object gets a new name:'
run 'cd ..'
run_rc 'git -C future fetch -q ../inference main'
run 'git init -q --object-format=sha256 inference-sha256'
run 'git -C inference fast-export --all | git -C inference-sha256 fast-import --quiet'
run 'git -C inference log --oneline --all'
run 'git -C inference-sha256 log --oneline --all'
run 'git -C inference-sha256 repo info object.format references.format'

snip 04-migrate
note 'The ref format of an existing repository can be changed in place:'
run 'cd inference'
run 'git for-each-ref'
run 'git refs migrate --ref-format=reftable'
run 'git repo info references.format'
run 'git for-each-ref'

snip 05-failure
note 'The release script has not changed. Two repositories, two different failures:'
run_rc 'sh ../scripts/release-id.sh'
run 'cd ../inference-sha256'
run_rc 'sh ../scripts/release-id.sh'

snip 06-recovery
run 'cat ../scripts/release-id.v2.sh'
run_rc 'sh ../scripts/release-id.v2.sh'
run 'cd ../inference'
run_rc 'sh ../scripts/release-id.v2.sh'
run 'cd ../future'
run_rc 'sh ../scripts/release-id.v2.sh'

snip 07-verification
run 'cd ..'
run 'for r in inference inference-sha256 future; do echo "$r: $(git -C $r rev-parse --show-object-format --show-ref-format | tr "\n" " ")"; done'
run 'git -C inference refs verify'
run 'git -C inference refs migrate --ref-format=files'
run 'git -C inference repo info references.format'

lab_end

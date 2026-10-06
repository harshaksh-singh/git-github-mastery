#!/usr/bin/env bash
# Replay of the local steps of Lab 26.4: a cache key that contains a hash of the lock file
# changes exactly when the lock file changes. A small stand-in lock file is used; SHA-256 is
# computed with shasum to make the idea visible (hashFiles has its own way of combining files,
# so its value is not the one printed here).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a lab-26-4-cache-key
scenario_base
cd "$LAB_DIR/you/inventory-api" || exit 1
printf 'version = 1\n\n[[package]]\nname = "pytest"\nversion = "8.4.0"\n' | put uv.lock
hidden 'git add uv.lock && git commit -m "Add uv.lock"'

snip 01-key
run 'cat uv.lock'
run 'shasum -a 256 uv.lock | cut -c1-16'
note 'A commit that does not touch the lock file: same hash, same key, cache hit.'
run 'echo "Run the linter with: uv run ruff check ." >> README.md'
run 'git commit --quiet -am "Document the linter"'
run 'git diff --stat HEAD~1 -- uv.lock'
run 'shasum -a 256 uv.lock | cut -c1-16'

snip 02-key-changes
note 'A dependency update: new hash, new key, cache miss, and a new cache saved after the job.'
run "sed -i.bak 's/8.4.0/8.4.1/' uv.lock && rm uv.lock.bak"
run 'git commit --quiet -am "Update pytest in the lock file"'
run 'git diff --stat HEAD~1 -- uv.lock'
run 'shasum -a 256 uv.lock | cut -c1-16'
lab_end

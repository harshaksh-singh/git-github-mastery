#!/usr/bin/env bash
# How a YAML parser reads a workflow file: scalars that are not strings, anchors and aliases,
# block scalars. The parser here is PyYAML (YAML 1.1), the same one that parse-checks the course
# workflows. GitHub uses its own parser: the chapter says which results carry over.
# Chapter 20A, section 20A.3.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch20a yaml-reading

show='import sys, yaml, json; print(json.dumps(yaml.safe_load(open(sys.argv[1])), indent=2, default=str))'
export show

quiet "printf 'python: [3.9, 3.10, \"3.10\", 3.11]\nversion: 1.0\nenabled: yes\ncountry: NO\ntag: v1.0\n' > scalars.yml"
snip 01-scalars
run 'cat scalars.yml'
run 'python3 -c "$show" scalars.yml'

cat > on-key.yml <<'Y'
name: Tests
on:
  push:
    branches: [main]
  pull_request:
jobs: {}
Y
snip 02-on-key
run 'cat on-key.yml'
run 'python3 -c "$show" on-key.yml'

cat > anchors.yml <<'Y'
jobs:
  test:
    env: &common_env
      PYTHONPATH: src
      CI_PROFILE: fast
    steps: &setup
      - uses: actions/checkout@SHA
  lint:
    env: *common_env
    steps: *setup
Y
snip 03-anchors
run 'cat anchors.yml'
run 'python3 -c "$show" anchors.yml'

cat > blocks.yml <<'Y'
literal: |
  uv sync --locked
  uv run pytest
folded: >
  uv sync --locked
  uv run pytest
Y
snip 04-block-scalars
run 'cat blocks.yml'
run 'python3 -c "$show" blocks.yml'

printf 'jobs:\n  test:\n    steps:\n      - name: Test\n\trun: pytest\n' > tab.yml
snip 05-tab
run_rc 'python3 -c "$show" tab.yml 2>&1 | tail -3'
lab_end

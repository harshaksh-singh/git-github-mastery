#!/usr/bin/env bash
# Lab 18.2 replay: cone-mode sparse-checkout. Narrow a clone, read the definition and the
# index, widen it, and clean up after work that landed outside the cone.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 lab-18-2-sparse-checkout
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-18-2-sparse.sh" || exit 1

snip 01-clone
run 'git clone "file://$PWD/server/orbit.git" dev'
run 'cd dev'
run 'git ls-files | wc -l'
run 'ls'

snip 02-narrow
run 'git sparse-checkout set services/gateway libs/schemas'
run 'git sparse-checkout list'
run 'ls -A'
run 'ls services libs'
run 'git status'

snip 03-inside
run 'cat .git/info/sparse-checkout'
run 'git config list --worktree'
run 'git ls-files -t | cut -c1 | sort | uniq -c'
run 'git ls-files -t libs'

snip 04-checkpoint
note 'Predict the directories and the percentage before you run the next two commands.'
run 'git sparse-checkout add docs/runbooks'
run 'find . -path ./.git -prune -o -type d -print | sort'
run 'git status | sed -n 4p'

snip 05-work
note 'Ordinary work inside the cone needs nothing special:'
run "printf 'timeout_ms: 600\\nupstream: ranker\\n' > services/gateway/config.yaml"
run "git commit -q -am 'gateway: lower the upstream timeout to 600 ms'"
run 'git log --oneline -1'
run 'git show --stat --format= HEAD'

snip 06-failure
note 'Failure scenario: a tool writes into a directory that is outside the cone.'
run 'mkdir -p pipelines/eval'
run "printf 'recall@10 = 0.83\\n' > pipelines/eval/results.tmp"
run "printf 'import json\\n\\n\\ndef summarize(path):\\n    return len([json.loads(line) for line in open(path)])\\n' > pipelines/eval/summarize.py"
run 'git status --short'
run_rc 'git add pipelines/eval/summarize.py'
run_rc 'git commit -m "eval: add a summary helper"'

snip 07-recovery
note 'The helper is wanted: stage it with --sparse and commit it.'
run 'git add --sparse pipelines/eval/summarize.py'
run "git commit -q -m 'eval: add a summary helper'"
run 'git status --short'
note 'The committed file is still on disk outside the cone. Reapply the definition:'
run 'git sparse-checkout reapply'
run 'find pipelines -type f'
note 'What is left is the scratch file. The cleanup would delete it with its directory:'
run 'git sparse-checkout clean --dry-run'
note 'It is not garbage, so move it out first, then clean:'
run 'mv pipelines/eval/results.tmp ../results.tmp'
run 'git sparse-checkout clean -f'
run_rc 'ls pipelines'

snip 08-verification
run 'git status'
run 'git sparse-checkout list'
run 'git ls-files -t pipelines/eval'
run 'git show --stat --format=%s HEAD'
run 'cat ../results.tmp'
run_rc 'git fsck'

snip 09-disable
run 'git sparse-checkout disable'
run 'ls'
run 'git ls-files -t | cut -c1 | sort | uniq -c'

lab_end

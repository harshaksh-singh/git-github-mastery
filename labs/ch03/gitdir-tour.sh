#!/usr/bin/env bash
# Chapter 3, section 3.2: the .git directory file by file.
# Shows what "git init" creates and which files the first commit adds.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 gitdir-tour

snip 01-init
run 'git init inference-service'
run 'cd inference-service'
note 'Everything Git knows about this repository, minus the 14 sample hooks:'
run "find .git -not -name '*.sample' | sort"

snip 02-init-contents
run 'cat .git/HEAD'
run 'cat .git/config'
run 'cat .git/description'
run 'cat .git/info/exclude'
run 'ls .git/hooks | wc -l'

snip 03-first-commit
quiet "mkdir -p src"
quiet "printf 'retry_limit = 3\ntimeout_s = 30\n' > config.toml"
quiet "printf 'def predict(text):\n    return len(text)\n' > src/server.py"
run 'git add config.toml src/server.py'
run 'git commit -m "Add inference service skeleton"'
note 'What the first commit added to .git:'
run "find .git -type f -not -name '*.sample' | sort"

snip 04-new-files
run 'cat .git/refs/heads/main'
run 'cat .git/COMMIT_EDITMSG'
run 'cat .git/logs/HEAD'
run 'git count-objects'

lab_end

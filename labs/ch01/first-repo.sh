#!/usr/bin/env bash
# Chapter 1, section "A guided first repository": init, add, commit, status and log,
# with a look inside .git after every step to see which files appear.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch01 first-repo

snip 01-init
run 'git init rag-eval'
run 'cd rag-eval'
run 'ls -1F .git'
run 'cat .git/HEAD'
run 'git status'

snip 02-untracked
run "echo '# rag-eval' > README.md"
run 'mkdir configs'
run "printf 'model: small-v2\ntimeout_s: 60\n' > configs/eval.yaml"
run "find .git -type f -not -path '.git/hooks/*' | sort"
run 'git status'

snip 03-add
run 'git add README.md configs/eval.yaml'
run "find .git -type f -not -path '.git/hooks/*' | sort"
run 'git ls-files --stage'
run 'git status'

snip 04-commit
run 'git commit -m "Add README and evaluation config"'
run "find .git -type f -not -path '.git/hooks/*' | sort"

snip 05-after-commit
run 'cat .git/HEAD'
run 'cat .git/refs/heads/main'
run 'git log'
run 'git status'

snip 06-second-commit
run "echo 'top_k: 5' >> configs/eval.yaml"
run 'git status'
run 'git diff'
run 'git add configs/eval.yaml'
run 'git commit -m "Add top_k to evaluation config"'
run 'git log --oneline'

snip 07-ref-moved
run 'cat .git/HEAD'
run 'cat .git/refs/heads/main'
run 'cat .git/logs/HEAD'
run "find .git/objects -type f | wc -l"

# Used by Chapter 2, section 2.2: open the three objects that the first commit created.
snip 08-open-objects
first=$(git rev-parse --short HEAD~1)
run "git cat-file -t $first"
run "git cat-file -p $first"
run "git cat-file -p '$first^{tree}'"
run "git cat-file -p $first:configs"
run "git cat-file -p $first:configs/eval.yaml"

lab_end

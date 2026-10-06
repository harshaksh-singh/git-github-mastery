#!/usr/bin/env bash
# Gate 1 (Fundamentals), prediction part. The pN-setup snippets are printed in the gate file,
# the pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g1-predict

# ---- P1: content addressing, at the level of trees
snip p1-setup
run 'git init -q regionconf'
run 'cd regionconf'
run 'mkdir eu us'
run "printf 'timeout_s: 30\n' > default.yaml"
run 'cp default.yaml eu/service.yaml'
run 'cp default.yaml us/service.yaml'
run 'git add .'
run 'git commit -q -m "Add per-region configuration"'
snip p1-answer
run 'git count-objects | cut -d, -f1'
run 'git ls-tree HEAD'
run 'git ls-tree -r HEAD'
run "git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectname)'"
cd "$LAB_DIR"

# ---- P2: git commit <path> and the index
snip p2-setup
run 'git init -q ratelimit'
run 'cd ratelimit'
run "printf 'ROUTES = 2\n' > router.py"
run "printf 'LIMIT = 10\n' > limits.py"
run 'git add .'
run 'git commit -q -m "Add router and limits"'
run "printf 'ROUTES = 3\n' > router.py"
run 'git add router.py'
run "printf 'LIMIT = 20\n' > limits.py"
run "printf 'ask Ravi about burst\n' > notes.txt"
run 'git commit -q -m "Raise the limit" limits.py'
snip p2-answer
run 'git show --stat --format=%s HEAD'
run 'git status --short'
run 'git diff --cached --stat'
cd "$LAB_DIR"

# ---- P3: a commit on a detached HEAD
snip p3-setup
run 'git init -q batcher'
run 'cd batcher'
run 'git commit -q --allow-empty -m "Add batcher"'
run 'git commit -q --allow-empty -m "Add padding"'
run 'git commit -q --allow-empty -m "Add truncation"'
run 'git switch -q --detach HEAD~1'
run 'git commit -q --allow-empty -m "Try dynamic padding"'
snip p3-answer-a
run_rc 'git symbolic-ref HEAD'
run 'git status -sb'
run 'git log --oneline --all'
snip p3-setup-b
run 'git switch -q main'
snip p3-answer-b
run 'git log --oneline --all'
run 'git reflog -2'
run "git cat-file -t 'HEAD@{1}'"
run "git branch --contains 'HEAD@{1}'"
cd "$LAB_DIR"

# ---- P4: where the identity of a commit comes from
as config
snip p4-setup
run 'git init -q whoami'
run 'cd whoami'
run 'git config set --global user.email global@example.com'
run 'git config set user.email local@example.com'
run 'export GIT_AUTHOR_EMAIL=env@example.com'
run 'git -c user.email=flag@example.com commit -q --allow-empty -m "Whose commit is this"'
snip p4-answer
run "git log -1 --format='author    %ae%ncommitter %ce'"
run 'git config get --show-scope --show-origin user.email'
run 'git config get --all --show-scope user.email'
unset GIT_AUTHOR_EMAIL
lab_end

#!/usr/bin/env bash
# Chapter 14C, section 14C.9: which hook runs when, with which arguments and which standard
# input. One tracing script is installed under every hook name, in a clone and in the bare
# repository that plays the server.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c hook-tour

quiet 'git init --bare server.git'
quiet 'git init gateway'
cd gateway || exit 1
quiet 'git remote add origin ../server.git'

snip 01-samples
run 'ls .git/hooks'

snip 02-install
quiet "cp '$LAB_SCRIPT_DIR/files/trace-hook' .git/hooks/pre-commit"
run 'cat .git/hooks/pre-commit'
note 'The same script under every client-side name of interest, and four names on the server:'
run 'cd .git/hooks && for h in prepare-commit-msg commit-msg post-commit pre-merge-commit post-merge post-checkout pre-rebase post-rewrite pre-push; do cp pre-commit $h; done; cd ../..'
run 'for h in pre-receive update post-receive post-update; do cp .git/hooks/pre-commit ../server.git/hooks/$h; done'
run 'chmod +x .git/hooks/* ../server.git/hooks/*'

snip 03-commit
run "printf 'def route(request):\n    return upstream(request)\n' > router.py && git add router.py"
run 'git commit -m "Add router"'

snip 04-amend
run 'git commit --amend -m "Add request router"'

snip 05-checkout
run 'git switch -c feature/timeouts'
quiet "printf 'timeout_s: 10\n' > limits.yaml && git add limits.yaml && git commit -m 'Add timeout setting'"
run 'git switch main'
note 'Restoring a file from a commit is a "file checkout": the last argument is 0.'
run 'git restore --source=feature/timeouts limits.yaml'
quiet 'rm limits.yaml'

snip 06-merge
quiet "printf '# gateway\n' > README.md && git add README.md && git commit -m 'Add README'"
run 'git merge feature/timeouts'

snip 07-rebase
quiet 'git switch -c feature/retries HEAD~1'
quiet "printf 'retries: 2\n' > retry.yaml && git add retry.yaml && git commit -m 'Add retry setting'"
run 'git rebase main'

snip 08-push
quiet 'git switch main'
run 'git push origin main'

snip 09-no-verify
run 'git commit --no-verify --allow-empty -m "Skip the checks"'

lab_end

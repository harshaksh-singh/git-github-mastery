#!/usr/bin/env bash
# Chapter 14C, section 14C.10: a worked pre-rebase hook that refuses to rebase commits which are
# already on a remote, and "git rebase --no-verify", which skips it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c hook-pre-rebase

quiet 'git init --bare server.git'
quiet 'git clone server.git svc'
cd svc || exit 1
quiet "printf 'app = FastAPI()\n' > app.py && git add . && git commit -m 'Add service skeleton' && git push -u origin main"
quiet 'git switch -c feature/shared'
quiet "printf 'def health():\n    return \"ok\"\n' > health.py && git add . && git commit -m 'Add health endpoint' && git push -u origin feature/shared"
quiet 'git switch -c feature/local main'
quiet "printf 'def version():\n    return \"0.1\"\n' > version.py && git add . && git commit -m 'Add version endpoint'"
quiet 'git switch main'
quiet "printf '# svc\n' > README.md && git add . && git commit -m 'Add README' && git push"
quiet "cp '$LAB_SCRIPT_DIR/files/pre-rebase' .git/hooks/pre-rebase && chmod +x .git/hooks/pre-rebase"

snip 01-hook
run 'cat .git/hooks/pre-rebase'
run 'git log --oneline --graph --all'

snip 02-local-branch
run 'git switch -q feature/local'
run_rc 'git rebase main'

snip 03-published-branch
run 'git switch -q feature/shared'
run_rc 'git rebase main'
run 'git status -sb'

snip 04-no-verify
run_rc 'git rebase --no-verify main'
run 'git status -sb'

lab_end

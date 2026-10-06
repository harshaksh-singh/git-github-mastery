#!/usr/bin/env bash
# Chapter 14C, section 14C.10: worked post-checkout and post-merge hooks. Both report that the
# dependency lock file changed; neither can stop the command that triggered it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c hook-deps

quiet 'git init --bare server.git'
quiet 'git clone server.git svc'
cd svc || exit 1
quiet "printf 'fastapi==0.115.0\n' > requirements.lock && printf 'app = FastAPI()\n' > app.py && git add . && git commit -m 'Add service skeleton' && git push -u origin main"
quiet 'git switch -c feature/tracing'
quiet "printf 'fastapi==0.115.0\nopentelemetry-sdk==1.27.0\n' > requirements.lock && git commit -am 'Add tracing dependency'"
quiet 'git switch main'
# A teammate pushes a dependency upgrade.
cd "$LAB_DIR" || exit 1
quiet 'git clone server.git asha'
as asha
quiet "cd asha && printf 'fastapi==0.116.1\n' > requirements.lock && git commit -am 'Upgrade fastapi' && git push"
as you
cd "$LAB_DIR/svc" || exit 1
quiet "cp '$LAB_SCRIPT_DIR/files/post-checkout' '$LAB_SCRIPT_DIR/files/post-merge' .git/hooks/ && chmod +x .git/hooks/post-checkout .git/hooks/post-merge"

snip 01-hooks
run 'cat .git/hooks/post-checkout'
run 'cat .git/hooks/post-merge'

snip 02-checkout
run 'git switch feature/tracing'
run 'git switch main'
note 'A file checkout calls the hook with flag 0, and the hook stays silent:'
run 'git restore --source=feature/tracing app.py'

snip 03-pull
run 'git pull'

snip 04-exit-status
note 'post-checkout cannot undo the switch, but its exit status becomes the exit status of the command:'
run "printf '#!/bin/sh\nexit 3\n' > .git/hooks/post-checkout"
run_rc 'git switch feature/tracing'
run 'git status -sb'

lab_end

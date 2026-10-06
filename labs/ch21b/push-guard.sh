#!/usr/bin/env bash
# Chapter 21B, section 21B.12: what a push-time secret check does, reproduced with a plain Git
# pre-receive hook on a bare "server". This is the local analogue of GitHub push protection,
# not GitHub's implementation. Also: a client-side pre-commit hook and its bypass.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b push-guard
fx_triage

snip 01-install-server-hook
run 'cat kit/pre-receive'
run 'cp kit/pre-receive server.git/hooks/pre-receive'

snip 02-push-blocked
run 'cd triage'
run "printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env"
run "git add -A && git commit -q -m 'Add local settings'"
run_rc 'git push 2>&1'

snip 03-deleting-does-not-unblock
run "git rm -q .env && git commit -q -m 'Remove .env'"
run 'git log --oneline origin/main..main'
run_rc 'git push 2>&1'

snip 04-rewrite-unpushed-commits
note 'Nothing was pushed, so the two commits can be replaced. This is the cheap moment.'
run 'git reset -q --soft origin/main'
run 'git status -s'
run "printf '.env\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore .env'"
run_rc 'git push 2>&1'
run 'git -C ../server.git log --oneline main'

snip 05-client-hook
run 'cat ../kit/pre-commit'
run 'cp ../kit/pre-commit .git/hooks/pre-commit'
run "printf 'token: DUMMY-TOKEN-not-a-real-secret-67890\n' > debug.yaml"
run 'git add debug.yaml'
run_rc "git commit -m 'Add debug settings'"

snip 06-client-hook-bypassed
run_rc "git commit -q --no-verify -m 'Add debug settings'"
run 'git log --oneline -1'
note 'The client hook is advice. The server hook is enforcement:'
run_rc 'git push 2>&1'
lab_end

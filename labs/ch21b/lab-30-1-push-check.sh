#!/usr/bin/env bash
# Lab 30.1 replay, local part: what a push-time secret check catches and what it does not,
# with a pre-receive hook on a bare "server". The GitHub part of the lab (push protection on
# the practice repository) cannot be replayed here and is described from documentation.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b lab-30-1-push-check
fx_triage

snip 01-install
run 'cat kit/pre-receive'
run 'cp kit/pre-receive server.git/hooks/pre-receive'
run 'cd triage'

snip 02-blocked
run "printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env"
run "git add .env && git commit -q -m 'Add local settings'"
run "printf 'def priority(ticket):\n    return 1 if \"outage\" in ticket else 3\n' > priority.py"
run "git add priority.py && git commit -q -m 'Add ticket priority'"
run 'git log --oneline origin/main..main'
run_rc 'git push 2>&1'
run 'git status -sb'

snip 03-fix-earlier-commit
note 'The secret is in an earlier unpushed commit. Edit that commit; keep the later one.'
run_todo '1s/^pick/edit/' 'git rebase -i origin/main'
run 'git rm -q --cached .env'
run "printf '.env\n' > .gitignore && git add .gitignore"
run 'git commit -q --amend --no-edit'
run 'git rebase --continue 2>&1'

snip 04-push-accepted
run 'git log --oneline origin/main..main'
run 'git grep -c DUMMY-KEY $(git rev-list origin/main..main) || echo "no commit to be pushed contains the key"'
run_rc 'git push 2>&1'

snip 05-not-covered
note 'What the check cannot see: a secret whose shape is not in its pattern list.'
run "printf 'db_password: correct-horse-battery-staple\n' > database.yaml"
run "git add database.yaml && git commit -q -m 'Add database settings'"
run_rc 'git push 2>&1'

snip 06-failure
note 'Failure scenario: the block is answered by deleting the file in a new commit.'
run "printf 'token: DUMMY-TOKEN-not-a-real-secret-67890\n' > debug.yaml"
run "git add debug.yaml && git commit -q -m 'Add debug settings'"
run 'git push 2>&1 | head -1'
run "git rm -q debug.yaml && git commit -q -m 'Remove debug settings'"
run 'git push 2>&1 | head -1'
run 'git log --oneline origin/main..main'

snip 07-recovery
run 'git reset -q --hard origin/main'
run 'git log --oneline -3'
run 'git status -sb'
run_rc 'git push 2>&1'

snip 08-verification
run 'cd ..'
run 'git -C server.git log --oneline main'
run "git -C server.git grep -l -E 'DUMMY-(KEY|TOKEN)' \$(git -C server.git rev-list --all) | wc -l"
run 'git -C server.git grep -n password main'
lab_end

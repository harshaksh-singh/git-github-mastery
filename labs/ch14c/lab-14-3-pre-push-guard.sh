#!/usr/bin/env bash
# Lab 14.3 replay: a pre-push hook that guards main against deletion, rewrites and unfinished
# commits. Failure: a teammate's clone has no hook, and --no-verify skips yours, so a WIP commit
# reaches main anyway. Recovery: the same rule as a pre-receive hook on the server, which no
# client can skip.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c lab-14-3-pre-push-guard
fx_14_3

snip 01-install
run 'cd gateway'
run 'git log --oneline --graph --all'
run 'cat ../hooks/pre-push'
run 'cp ../hooks/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push'

snip 02-feature-branch
note 'A WIP commit on a feature branch is not the business of this hook:'
run 'git push -u origin feature/limits'

snip 03-main-refused
run 'git switch -q main'
run 'git merge -q --ff-only feature/limits'
run_rc 'git push origin main'
run 'git status -sb'

snip 04-finish-and-push
run 'git commit -q --amend -m "Add per-tenant limits"'
run 'git log --oneline -3'
run_rc 'git push origin main'

snip 05-delete-and-rewrite
run_rc 'git push origin --delete main'
run 'git reset -q --hard HEAD~1'
run_rc 'git push --force origin main'
run 'git reset -q --hard origin/main'

snip 06-failure
note 'Asha works in her own clone. It has no pre-push hook: hooks are not cloned.'
as asha
run 'cd ../asha'
run 'git pull -q'
run 'ls .git/hooks | grep -v sample'
run "printf 'def route(request):\n    return upstream(request.model, timeout=10)\n' > router.py"
run 'git commit -q -am "WIP: timeout, value to be tuned"'
run_rc 'git push origin main'
note 'And in your clone the guard is one option away from being skipped:'
as you
run 'cd ../gateway'
run 'git pull -q'
run 'git commit -q --allow-empty -m "WIP: placeholder"'
run_rc 'git push --no-verify origin main'
run 'git log --oneline -3 origin/main'

snip 07-recovery-server
note 'Enforce the rule where every push arrives: in the repository that plays the server.'
run 'cat ../hooks/pre-receive'
run 'cp ../hooks/pre-receive ../server.git/hooks/pre-receive && chmod +x ../server.git/hooks/pre-receive'

snip 08-recovery-test
run 'git commit -q --allow-empty -m "WIP: another placeholder"'
run_rc 'git push --no-verify origin main'
run 'git reset -q --hard origin/main'
as asha
run 'cd ../asha'
run 'git pull -q'
run 'git commit -q --allow-empty -m "fixup! Add per-tenant limits"'
run_rc 'git push origin main'
run 'git reset -q --hard origin/main'

snip 09-verification
run "printf '# gateway\n' > README.md && git add README.md && git commit -q -m 'Add README'"
run_rc 'git push origin main'
run_rc 'git push origin --delete main'
run 'git -C ../server.git log --oneline -5 main'

lab_end

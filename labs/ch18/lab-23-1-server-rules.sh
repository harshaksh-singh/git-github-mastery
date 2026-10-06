#!/usr/bin/env bash
# Lab 23.1 replay (local rehearsal): protect main of a bare server with a hook that imitates a
# ruleset, watch each rule reject a push, and meet a second protection layer.
# Lab manual: lab-manual/m23-governance.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 lab-23-1-server-rules
scenario_rules

snip 01-observe
note 'Hooks installed on the server (files that are not samples), and the built-in setting:'
run 'ls server/ticket-router.git/hooks | grep -vc sample'
run_rc 'git -C server/ticket-router.git config get receive.denyNonFastForwards'
run 'cd you/ticket-router'
run 'git log --oneline -2 origin/main'

snip 02-unprotected
note 'No rules yet. A force push that drops the newest commit of main is accepted:'
run 'git push --force origin main~1:main'
run 'git ls-remote origin main'
note 'Put it back (a fast-forward):'
run 'git push origin main'

snip 03-activate
run 'cp ../../rules/pre-receive ../../server/ticket-router.git/hooks/pre-receive'
run 'chmod +x ../../server/ticket-router.git/hooks/pre-receive'

snip 04-rules-reject
run_rc 'git push --force origin main~1:main'
run_rc 'git push origin --delete main'
run 'git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing'
run_rc 'git push origin main'
run 'git reset -q --hard origin/main'

snip 05-allowed
run 'git merge -q --squash feature/priority-routing'
run 'git commit -q -m "Route high-priority tickets to an escalations queue (#1)"'
run 'git push origin main'

snip 06-checkpoint
run 'git ls-remote origin'
run 'git log --oneline -2 origin/main'

snip 07-failure
note 'An older protection, of another kind, is also switched on for this server:'
run 'git -C ../../server/ticket-router.git config set receive.denyNonFastForwards true'
note 'Somebody wants the squash commit gone and disables the ruleset to force-push:'
run 'chmod -x ../../server/ticket-router.git/hooks/pre-receive'
run_rc 'git push --force origin main~1:main'

snip 08-diagnose
note 'Two layers. Which ones are in force?'
run 'test -x ../../server/ticket-router.git/hooks/pre-receive && echo "hook: active" || echo "hook: disabled"'
run 'git -C ../../server/ticket-router.git config get --show-origin receive.denyNonFastForwards'

snip 09-recovery
note 'Put the ruleset back, and undo the change the way a protected branch allows: forward.'
run 'chmod +x ../../server/ticket-router.git/hooks/pre-receive'
run 'git revert --no-edit HEAD'
run 'git push origin main'

snip 10-verification
run 'git log --oneline -3 origin/main'
run 'test -x ../../server/ticket-router.git/hooks/pre-receive && echo "hook: active" || echo "hook: disabled"'
run_rc 'git push --force origin main~1:main'
run 'git status -sb'

lab_end

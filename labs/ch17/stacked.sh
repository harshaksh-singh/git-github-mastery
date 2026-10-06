#!/usr/bin/env bash
# Dependent branches (a stack) in plain Git: what each pull request shows for each choice of
# base, what "a linear history between the branches" means, how a stack loses it and gets it
# back, what happens when the bottom layer is squash-merged, and an indirect merge.
# Chapter 17, sections 17.13 and 17.14.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 stacked
scenario_stack

snip 01-stack
run 'git log --oneline --graph --decorate-refs=refs/heads feature/sla-timers'

snip 02-base-decides
note 'The upper pull request against main lists both layers:'
run 'git log --oneline origin/main..feature/sla-timers'
note 'Against the branch below it, it lists its own layer:'
run 'git log --oneline feature/priority-routing..feature/sla-timers'
run 'git diff --stat feature/priority-routing...feature/sla-timers'

snip 03-linear
note 'Linear stack: the lower branch is an ancestor of the upper one.'
run_rc 'git merge-base --is-ancestor feature/priority-routing feature/sla-timers'

snip 04-review-fix-below
note 'A review fix lands on the lower branch:'
run 'git switch -q feature/priority-routing'
run "printf '\n\ndef test_outage_goes_to_escalations():\n    assert classify({\"subject\": \"Outage in EU\"}) == \"escalations\"\n' >> tests/test_classify.py"
run 'git commit -q -am "Test the escalations route"'
run 'git log --oneline --graph --decorate-refs=refs/heads feature/priority-routing feature/sla-timers -4'
run_rc 'git merge-base --is-ancestor feature/priority-routing feature/sla-timers'

snip 05-restack
note 'Restore the linear history: replay the upper layer on the new tip of the lower one.'
run 'git rebase feature/priority-routing feature/sla-timers'
run_rc 'git merge-base --is-ancestor feature/priority-routing feature/sla-timers'
run 'git log --oneline feature/priority-routing..feature/sla-timers'
run 'git push -q origin feature/priority-routing'
run 'git push -q --force-with-lease origin feature/sla-timers'

cd "$LAB_DIR" || exit 1
cp -R server server-indirect
cp -R asha asha-indirect
git -C asha-indirect/ticket-router remote set-url origin ../../server-indirect/ticket-router.git

# The bottom layer is squash-merged by Asha; she deletes its branch on the server.
enter asha
hidden 'git fetch'
hidden 'git merge --squash origin/feature/priority-routing'
hidden 'git commit -m "Route high-priority tickets to an escalations queue (#1)"'
hidden 'git push origin main'
hidden 'git push origin --delete feature/priority-routing'
enter you

snip 06-bottom-squashed
note 'The lower pull request was squash-merged and its branch deleted. The upper one now targets main:'
run 'git fetch --prune'
run 'git log --oneline origin/main..feature/sla-timers'
run_rc 'git merge-tree --write-tree --name-only origin/main feature/sla-timers'

snip 07-restack-on-main
note 'Only the upper layer is new. Transplant it: everything after the old lower branch, onto main.'
run 'git rebase --onto origin/main feature/priority-routing feature/sla-timers'
run 'git log --oneline origin/main..feature/sla-timers'
run_rc 'git merge-tree --write-tree origin/main feature/sla-timers'

as asha
snip 08-indirect-merge
note 'In a copy where nothing was merged yet. Asha merges the UPPER pull request into main:'
run 'cd ../../asha-indirect/ticket-router'
run 'git fetch -q'
run 'git merge -q --no-ff -m "Merge pull request #2 from feature/sla-timers" origin/feature/sla-timers'
run 'git push -q origin main'
note 'Is the head of the LOWER pull request now reachable from main?'
run_rc 'git merge-base --is-ancestor origin/feature/priority-routing main'
run 'git log --oneline main..origin/feature/priority-routing'

lab_end

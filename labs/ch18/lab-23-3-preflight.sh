#!/usr/bin/env bash
# Lab 23.3 replay (the Git half): three open branches, each blocked for a different reason that
# plain Git can already see. Diagnose them before opening the merge box, repair your own branch,
# and meet the stale local main. Lab manual: lab-manual/m23-governance.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 lab-23-3-preflight
scenario_three_blocks

snip 01-observe
run 'cat preflight.sh'
run 'cd you/ticket-router'
run 'git fetch'

snip 02-preflight
run 'sh ../../preflight.sh feature/priority-routing'
run 'sh ../../preflight.sh fix/threshold'
run 'sh ../../preflight.sh docs/queues'

snip 03-details
run 'git merge-tree --write-tree --name-only origin/main origin/fix/threshold'
run 'git log --oneline --graph origin/main..origin/docs/queues'

snip 04-failure
note 'Repairing your own branch. The habit: merge main.'
run 'git switch -q feature/priority-routing'
run 'git merge main'
run 'git push'
run 'sh ../../preflight.sh feature/priority-routing'

snip 05-diagnose
run 'git rev-parse main origin/main'
run 'git branch -vv'

snip 06-recovery
run 'git merge origin/main'
run 'git push'

snip 07-verification
run 'sh ../../preflight.sh feature/priority-routing'
run 'git status -sb'

lab_end

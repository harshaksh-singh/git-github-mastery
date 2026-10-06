#!/usr/bin/env bash
# Replay of the local part of Lab 27.4: what is waiting between staging and production, and
# which ref a run would carry into a deployment branch rule.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-27-4-promotion
make_warehouse
scenario_deployed

snip 01-waiting
run 'git for-each-ref --format="%(refname) %(objectname:short)" refs/deployed'
note 'What an approval of the production job would release:'
run 'git log --oneline refs/deployed/production..refs/deployed/staging'

snip 02-failure
note 'An urgent fix on a branch. The rule on production says: selected branches, main.'
run 'git switch --quiet hotfix/lead-days'
run 'git symbolic-ref HEAD'
run_rc 'test "$(git symbolic-ref HEAD)" = refs/heads/main'
run_rc 'git merge-base --is-ancestor HEAD main'

snip 03-recovery
note 'The fix reaches production the way everything else does: through main.'
run 'git switch --quiet main'
run 'git merge --quiet --no-ff -m "Merge hotfix/lead-days" hotfix/lead-days'
run 'git symbolic-ref HEAD'
run_rc 'git merge-base --is-ancestor hotfix/lead-days main'
run 'git log --oneline refs/deployed/production..main'
lab_end

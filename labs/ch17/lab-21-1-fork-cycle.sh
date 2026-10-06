#!/usr/bin/env bash
# Lab 21.1 replay (local rehearsal): a full fork and pull request cycle with bare repositories.
# The steps that are GitHub objects (opening the pull request, pressing merge) are imitated
# with plain Git and marked by a comment. Lab manual: lab-manual/m21-pull-requests-forks.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 lab-21-1-fork-cycle
scenario_fork
cd "$LAB_DIR" || exit 1

snip 01-where-you-are
run 'cd you/ticket-router'
run 'git remote -v'
run 'git branch -vv'

snip 02-fetch-upstream
run 'git fetch upstream'
run 'git rev-list --left-right --count upstream/main...origin/main'

snip 03-branch-commit-push
run 'git switch -c docs/queues --no-track upstream/main'
run "printf '\n## Queues\n\nbilling, technical, general\n' >> README.md"
run 'git commit -am "List the queues in the README"'
run 'git push -u origin docs/queues'

snip 04-predict-the-pr
run 'git log --oneline upstream/main..docs/queues'
run 'git diff --stat upstream/main...docs/queues'

snip 05-open-pr
note 'On GitHub: gh pr create. Here the upstream repository takes the head commit under refs/pull/:'
run 'git -C ../../server/ticket-router.git fetch ../../forks/you/ticket-router.git docs/queues:refs/pull/1/head'
run 'git ls-remote upstream'

as asha
snip 06-maintainer
note 'Asha, the maintainer of upstream:'
run 'cd ../../asha/ticket-router'
run 'git fetch origin pull/1/head:pr-1'
run 'git log --oneline main..pr-1'
note 'On GitHub: gh pr merge --merge. In plain Git:'
run 'git merge --no-ff -m "Merge pull request #1 from you/docs/queues" pr-1'
run 'git push origin main'

as you
snip 07-sync
run 'cd ../../you/ticket-router'
run 'git switch main'
run 'git fetch upstream'
run 'git merge --ff-only upstream/main'
run 'git push origin main'
run 'git branch -d docs/queues'
run 'git push origin --delete docs/queues'

snip 08-checkpoint
run 'git rev-list --left-right --count upstream/main...origin/main'
run 'git log --oneline --graph -4'

snip 09-failure
note 'The mistake: a commit made directly on main of the fork, and pushed.'
run "printf '\nSee CONTRIBUTING.md before you open a pull request.\n' >> README.md"
run 'git commit -q -am "Point to the contributing guide"'
run 'git push -q origin main'
as asha
note 'Meanwhile upstream moves (Asha):'
run "git -C ../../asha/ticket-router commit -q --allow-empty -m 'Start the 1.1 cycle'"
run 'git -C ../../asha/ticket-router push -q origin main'
as you
run 'git fetch upstream'
run_rc 'git merge --ff-only upstream/main'
run 'git rev-list --left-right --count upstream/main...origin/main'

snip 10-recovery
note 'Keep the commit on a branch of its own, then put main back on the upstream history.'
run 'git switch -c docs/contributing-pointer'
run 'git branch -f --no-track main upstream/main'
run 'git push --force-with-lease origin main'
run 'git push -u origin docs/contributing-pointer'

snip 11-verification
run 'git rev-list --left-right --count upstream/main...origin/main'
run 'git log --oneline upstream/main..docs/contributing-pointer'
run 'git branch -vv'

lab_end

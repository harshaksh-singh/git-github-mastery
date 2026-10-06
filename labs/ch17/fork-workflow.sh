#!/usr/bin/env bash
# The fork workflow end to end with bare repositories: upstream, your fork, your clone, a branch,
# the pull request ref that appears in upstream, a maintainer who checks it out and pushes a
# commit to your branch, the merge, and bringing fork and clone back in sync.
# Builds on Chapter 12, section 12.10. Chapter 17, section 17.15.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 fork-workflow
scenario_fork

snip 01-remotes
note 'Your clone of your fork. origin is the fork, upstream is the shared repository.'
run 'git remote -v'
run 'git fetch upstream'
note 'Commits only upstream has (left) and only your fork has (right):'
run 'git rev-list --left-right --count upstream/main...origin/main'

snip 02-branch-from-upstream
note 'Start from the current upstream, not from the stale main of the fork:'
run 'git switch -c fix/empty-subject --no-track upstream/main'
classify_empty_subject
run 'git commit -q -am "Accept tickets without a subject"'
run 'git push -u origin fix/empty-subject'

cd "$LAB_DIR/server/ticket-router.git" || exit 1
git config set receive.hideRefs refs/pull
snip 03-pr-ref-upstream
note 'In the upstream repository. Opening pull request 7 from you:fix/empty-subject, as Git data:'
run 'git fetch -q ../../forks/you/ticket-router.git fix/empty-subject:refs/pull/7/head'
run 'git for-each-ref --format="%(objectname:short) %(refname)"'
note 'The commit is now stored in upstream, on no branch of upstream:'
run 'git cat-file -t refs/pull/7/head'
run 'git branch --contains refs/pull/7/head'

enter asha
snip 04-maintainer-checks-out
note 'Asha, a maintainer of upstream, takes the pull request into her clone:'
run 'git fetch origin pull/7/head:pr-7'
run 'git switch -q pr-7'
run 'git log --oneline main..pr-7'

snip 05-maintainer-edits
note 'She adds a test and pushes it to YOUR branch in YOUR fork (you allowed maintainer edits):'
run "printf '\n\ndef test_ticket_without_subject():\n    assert classify({}) == \"general\"\n' >> tests/test_classify.py"
run 'git commit -q -am "Test a ticket without a subject"'
run 'git push ../../forks/you/ticket-router.git pr-7:fix/empty-subject'
# The platform moves the pull request ref when the head branch moves.
hidden "git -C '$LAB_DIR/server/ticket-router.git' fetch ../../forks/you/ticket-router.git +fix/empty-subject:refs/pull/7/head"

enter you
snip 06-you-pull
note 'You. Your branch in the fork moved without you:'
run 'git pull'
run 'git log --format="%h %an: %s" upstream/main..fix/empty-subject'

enter asha
snip 07-merge
note 'Asha merges pull request 7 with a merge commit and publishes main:'
run 'git switch -q main'
run 'git fetch -q origin pull/7/head'
run 'git merge -q --no-ff -m "Merge pull request #7 from you/fix/empty-subject" FETCH_HEAD'
run 'git push -q origin main'
run 'git log --oneline --graph -4'

enter you
snip 08-sync
note 'You. Bring your clone and your fork up to date with upstream:'
run 'git switch -q main'
run 'git fetch upstream'
run 'git merge --ff-only upstream/main'
run 'git push origin main'
run 'git rev-list --left-right --count upstream/main...origin/main'

snip 09-clean-up
run 'git branch -d fix/empty-subject'
run 'git push origin --delete fix/empty-subject'
run 'git branch -a'

lab_end

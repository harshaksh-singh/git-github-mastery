#!/usr/bin/env bash
# The forms of a forced push side by side: --force-with-lease=<ref> for one ref,
# --force-with-lease=<ref>: (the ref must not exist yet), and plain --force, which
# overwrites a commit that your clone has never seen. Chapter 12, section 12.8.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lease-forms

# Hidden setup: you published two branches. Asha added a commit to docs/runbook and
# pushed it. You then reworded the tip commit of both branches without fetching.
make_server
new_clone you
new_clone asha
enter you
hidden 'git switch -c feature/prompt-cache'
commit_file app/cache.py 'CACHE = {}\n' 'Add prompt cache'
hidden 'git push -u origin feature/prompt-cache'
hidden 'git switch -c docs/runbook main'
commit_file docs/runbook.md '# Runbook\n' 'Start the runbook'
hidden 'git push -u origin docs/runbook'
enter asha
hidden 'git fetch'
hidden 'git switch docs/runbook'
commit_file docs/runbook.md '# Runbook\n\n## Paging\n\nPage the on-call engineer first.\n' 'Add paging section'
hidden 'git push'
asha_tip=$(git rev-parse --short HEAD)
asha_full=$(git rev-parse HEAD)
enter you
hidden 'git commit --amend -m "Start the on-call runbook"'
hidden 'git switch feature/prompt-cache'
hidden 'git commit --amend -m "Add prompt cache module"'

snip 01-one-ref
note 'Both branches were reworded locally. Asha has pushed to docs/runbook; you have not fetched.'
run 'git branch -vv'
run 'git config set advice.pushUpdateRejected false'
run_rc 'git push --force-with-lease=feature/prompt-cache origin feature/prompt-cache docs/runbook'
run 'git ls-remote --branches origin'

snip 02-must-not-exist
run 'git push --force-with-lease=release/1.0: origin main:refs/heads/release/1.0'
run_rc 'git push --force-with-lease=release/1.0: origin feature/prompt-cache:refs/heads/release/1.0'

snip 03-plain-force
note 'What your clone believes the server has, and what the server reports during a dry run:'
run 'git rev-parse --short origin/docs/runbook'
run 'git push --dry-run --force origin docs/runbook'
run_rc "git cat-file -t $asha_tip"
run 'git push --force origin docs/runbook'
run 'git reflog show origin/docs/runbook'

snip 04-where-it-survives
note 'The overwritten commit still exists: on the server, unreachable, and in the clone of Asha.'
run 'git -C ../../server/support-bot.git fsck --unreachable --no-reflogs | grep commit'
run 'git -C ../../asha/support-bot log --oneline -2 docs/runbook'

snip 05-fetch-by-id
note 'Asking the server for the overwritten commit by its object ID:'
run_rc "git fetch origin $asha_tip"
run_rc "git -c protocol.version=0 fetch origin $asha_full"
run "git fetch origin $asha_full"
run 'git log --oneline -2 FETCH_HEAD'

lab_end

#!/usr/bin/env bash
# Lab 8.6 replay: stash work in progress (staged, unstaged and untracked), commit a hotfix on
# the same line, pop the stash into a conflict, resolve it and drop the entry. Failure: the
# conflicted state is thrown away and the stash dropped. Recovery: find the dropped entry,
# store it again and apply it with "git stash branch".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-6-stash-pop-conflict
fx_08_6
# The ID of the stash entry that the failure scenario drops (it is printed by "git stash drop").
incident_stash=$(git -C gateway-incident rev-parse --short 'stash@{0}')

snip 01-stash
run 'cd gateway'
run 'git status -s'
run 'git stash push -u -m "wip: per-tenant limits"'
run 'git status -s'
run 'git stash list'
run 'git stash show --include-untracked'

snip 02-hotfix
run "printf 'requests_per_minute: 30\nburst: 10\n' > limits.yaml"
run 'git commit -am "Hotfix: throttle to 30 rpm during the incident"'

snip 03-pop-conflict
run_rc 'git stash pop'

snip 04-conflict-state
run 'git status -s'
run 'cat limits.yaml'
run 'git stash list'

snip 05-resolve-and-drop
run "printf 'requests_per_minute: 30\nburst: 10\nper_tenant: true\n' > limits.yaml"
run 'git add limits.yaml'
run 'git status -s'
run 'git stash drop'
run 'git stash list'

snip 06-failure
run 'cd ../gateway-incident'
run 'git stash list'
run_rc 'git stash pop'
run 'git reset --hard'
run 'git stash drop'
run 'git stash list'
run 'git status -s'

snip 07-recovery-find
run "git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'"

snip 08-recovery-store
run "git stash store -m 'recovered: per-tenant limits' $incident_stash"
run 'git stash list'
run "git show 'stash@{0}^3:notes.md'"
run 'cat notes.md'
run 'rm notes.md'

snip 09-recovery-apply
run 'git stash branch wip/per-tenant-limits'

snip 10-verification
run 'git status -s'
run 'git log --oneline --decorate --all'
run 'git stash list'

lab_end

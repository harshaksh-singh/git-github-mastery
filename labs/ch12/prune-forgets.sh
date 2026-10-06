#!/usr/bin/env bash
# Pruning is forgetting: when a branch is deleted on the server, your remote-tracking ref
# may be the last name its commits have in your clone. "git fetch --prune" removes that
# name and its reflog. Chapter 12, section 12.16.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 prune-forgets

# Hidden setup: Asha published spike/hybrid-search with two commits. You cloned, so you
# have origin/spike/hybrid-search but no local branch for it. Then Asha deleted the
# branch on the server and, a week later, her own clone.
make_server
new_clone asha
enter asha
hidden 'git switch -c spike/hybrid-search'
commit_file app/hybrid.py 'def hybrid_search(query):\n    return []\n' 'Try hybrid search'
commit_file app/hybrid.py 'def hybrid_search(query):\n    return [query]\n' 'Return the query as a stub result'
hidden 'git push -u origin spike/hybrid-search'
new_clone you
enter asha
hidden 'git push origin --delete spike/hybrid-search'
enter you

snip 01-last-name
note 'Asha has deleted spike/hybrid-search on the server. Your clone has not fetched since.'
run 'git branch -a --contains origin/spike/hybrid-search'
run 'git log --oneline -2 origin/spike/hybrid-search'
run 'git fetch --prune'
run 'git reflog show origin/spike/hybrid-search 2>&1 | head -1'
run 'git fsck --unreachable | grep commit'

snip 02-rescue
run 'git fsck --lost-found | grep commit'
lost=$(git fsck --lost-found 2>/dev/null | awk '/dangling commit/ {print substr($3, 1, 7)}')
run "git branch rescue/hybrid-search $lost"
run 'git log --oneline -2 rescue/hybrid-search'

lab_end

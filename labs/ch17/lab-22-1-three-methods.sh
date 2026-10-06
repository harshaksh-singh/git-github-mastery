#!/usr/bin/env bash
# Lab 22.1 replay: the same pull request merged three ways in three copies of a repository,
# then compared: graph, commit IDs, author and committer, tree, ancestry, and what the
# contributor sees afterwards. Lab manual: lab-manual/m22-merge-methods-releases.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 lab-22-1-three-methods
scenario_three_methods
as asha

snip 01-observe
run 'ls'
run 'git -C merge/asha log --oneline --graph main origin/feature/priority-routing'

snip 02-merge-commit
run 'cd merge/asha'
run 'git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing'
run 'git push origin main'

snip 03-squash
run 'cd ../../squash/asha'
run 'git merge --squash origin/feature/priority-routing'
run 'git commit -m "Route high-priority tickets to an escalations queue (#1)"'
run 'git push origin main'

snip 04-rebase
run 'cd ../../rebase/asha'
run 'git switch -c pr-1 origin/feature/priority-routing'
run 'git rebase main'
run 'git switch main'
run 'git merge --ff-only pr-1'
run 'git push origin main'
run 'cd ../..'

snip 05-compare-graphs
run 'for m in merge squash rebase; do echo "== $m"; git -C $m/asha log --graph --format="%h %an / %cn: %s" -5 main; done'

snip 06-compare-trees
run 'for m in merge squash rebase; do git -C $m/asha rev-parse main^{tree}; done'
run 'for m in merge squash rebase; do echo "$m: $(git -C $m/asha rev-list --count main) commits, $(git -C $m/asha rev-list --count --merges main) merge"; done'

snip 07-ancestry
run 'for m in merge squash rebase; do git -C $m/asha merge-base --is-ancestor origin/feature/priority-routing main; echo "$m: exit status $?"; done'

as you
snip 08-contributor
note 'You, the contributor. Copy 1, merge commit:'
run 'git -C merge/you pull -q --ff-only'
run 'git -C merge/you branch -d feature/priority-routing'
note 'Copy 3, rebase. First ask whether the patches of the branch are on main:'
run 'git -C rebase/you pull -q --ff-only'
run 'git -C rebase/you cherry -v main feature/priority-routing'
run 'git -C rebase/you branch -d feature/priority-routing'

as asha
snip 09-contributor-squash
note 'Copy 2, squash. Asha deletes the head branch on the server, as the platform offers after a merge:'
run 'git -C squash/asha push origin --delete feature/priority-routing'
as you
run 'git -C squash/you pull -q --ff-only --prune'
run 'git -C squash/you branch -vv'
run_rc 'git -C squash/you branch -d feature/priority-routing'

snip 10-checkpoint
note 'Would merging the branch change main at all? Compare the merged tree with the tree of main:'
run 'git -C squash/you merge-tree --write-tree main feature/priority-routing'
run 'git -C squash/you rev-parse main^{tree}'
run 'git -C squash/you branch -D feature/priority-routing'

snip 11-failure
note 'Undo the pull request in the merge-commit copy, the way you would undo any commit:'
run 'cd merge/you'
run_rc 'git revert --no-edit HEAD'

snip 12-recovery
run 'git show -s --format="%h parents: %p" HEAD'
run 'git revert --no-edit -m 1 HEAD'
note 'The tree is back to what it was before the merge:'
run_rc 'git diff --quiet HEAD~2 HEAD'

snip 13-verification
run 'git log --oneline -3'
run 'git status -sb'
run 'git branch'

lab_end

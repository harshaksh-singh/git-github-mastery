#!/usr/bin/env bash
# The three merge methods of a pull request, reproduced with plain Git in three copies of the
# same repository: git merge --no-ff, git merge --squash, and git rebase followed by a
# fast-forward. Compares graphs, commit IDs, authors, committers and trees.
# Chapter 17, sections 17.8 and 17.9.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 merge-methods
scenario_pr
make_method_copies
cd "$LAB_DIR" || exit 1
as asha

snip 01-before
note 'The same starting point in all three copies. Asha is the maintainer.'
run 'cd merge/asha'
run 'git log --graph --format="%h %an: %s" main origin/feature/priority-routing'

snip 02-merge-commit
note 'Method 1, "Create a merge commit":'
run 'git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing'
run 'git push -q origin main'
run 'git log --graph --format="%h %an / %cn: %s" -6'

snip 03-squash
note 'Method 2, "Squash and merge":'
run 'cd ../../squash/asha'
run 'git merge --squash origin/feature/priority-routing'
run 'git commit -q -m "Route high-priority tickets to an escalations queue (#1)"'
run 'git push -q origin main'
run 'git log --graph --format="%h %an / %cn: %s" -3'
run 'git show --stat --format="%h parents: %p" HEAD'

snip 04-rebase
note 'Method 3, "Rebase and merge":'
run 'cd ../../rebase/asha'
run 'git switch -q -c pr-1 origin/feature/priority-routing'
run 'git rebase main'
run 'git switch -q main'
run 'git merge --ff-only pr-1'
run 'git push -q origin main'
run 'git log --graph --format="%h %an / %cn: %s" -5'

snip 05-what-main-gained
cd "$LAB_DIR" || exit 1
note 'The feature commits as you wrote them:'
run 'git -C merge/you log --format="%h author=%an committer=%cn %s" main..feature/priority-routing'
note 'What main gained in each copy (main@{1} is where main was before):'
run 'git -C merge/asha log --format="%h author=%an committer=%cn %s" main@{1}..main'
run 'git -C squash/asha log --format="%h author=%an committer=%cn %s" main@{1}..main'
run 'git -C rebase/asha log --format="%h author=%an committer=%cn %s" main@{1}..main'

snip 06-same-tree
note 'Three histories, one result: the tree of main is identical.'
run 'git -C merge/asha rev-parse main^{tree}'
run 'git -C squash/asha rev-parse main^{tree}'
run 'git -C rebase/asha rev-parse main^{tree}'

snip 07-first-parent
note 'What "git log --first-parent" shows on main:'
run 'git -C merge/asha log --first-parent --oneline -3 main'
run 'git -C squash/asha log --first-parent --oneline -3 main'
run 'git -C rebase/asha log --first-parent --oneline -5 main'

snip 08-ancestry
note 'Is your original head commit an ancestor of main?'
run_rc 'git -C merge/asha merge-base --is-ancestor origin/feature/priority-routing main'
run_rc 'git -C squash/asha merge-base --is-ancestor origin/feature/priority-routing main'
run_rc 'git -C rebase/asha merge-base --is-ancestor origin/feature/priority-routing main'

snip 09-untested-states
note 'The second feature commit used the queue name "escalation"; the third one fixed it.'
note 'Which commits on main contain the wrong name?'
run 'for c in $(git -C merge/asha rev-list main@{1}..main); do git -C merge/asha grep -c "\"escalation\"" $c -- router/classify.py; done'
run 'for c in $(git -C squash/asha rev-list main@{1}..main); do git -C squash/asha grep -c "\"escalation\"" $c -- router/classify.py; done'
run 'for c in $(git -C rebase/asha rev-list main@{1}..main); do git -C rebase/asha grep -c "\"escalation\"" $c -- router/classify.py; done'

snip 10-blame
note 'Who does blame name for the new lines of classify.py?'
run 'git -C merge/asha blame -s -L 1,3 router/classify.py'
run 'git -C squash/asha blame -s -L 1,3 router/classify.py'
run 'git -C rebase/asha blame -s -L 1,3 router/classify.py'

# The maintainer deletes the head branch on the server, as the platform offers after a merge.
for m in merge squash rebase; do
  hidden "git -C '$LAB_DIR/$m/asha' push origin --delete feature/priority-routing"
done
as you

snip 11-you-update-merge
note 'You, the contributor, after the merge. Copy 1 (merge commit):'
run 'cd merge/you'
run 'git pull --ff-only --prune'
run 'git branch -vv'
run_rc 'git branch -d feature/priority-routing'

snip 12-you-update-squash
note 'Copy 2 (squash):'
run 'cd ../../squash/you'
run 'git pull -q --ff-only --prune'
run 'git branch -vv'
run_rc 'git branch -d feature/priority-routing'

snip 13-you-update-rebase
note 'Copy 3 (rebase):'
run 'cd ../../rebase/you'
run 'git pull -q --ff-only --prune'
run_rc 'git branch -d feature/priority-routing'
run 'git branch --no-merged main'

snip 14-safe-to-delete
note 'Rebase copy: every commit of the branch has an equivalent patch on main ("-"):'
run 'git cherry -v main feature/priority-routing'
note 'Squash copy: no single commit on main matches a commit of the branch ("+"):'
run 'cd ../../squash/you'
run 'git cherry -v main feature/priority-routing'
note 'A test that works for both: would merging the branch change main at all?'
run 'git merge-tree --write-tree main feature/priority-routing'
run 'git rev-parse main^{tree}'
run 'git branch -D feature/priority-routing'

snip 15-revert-merge
note 'Undoing the pull request on main. Copy 1: one revert, and you must name the mainline.'
run 'cd ../../merge/you'
run 'git revert --no-edit -m 1 HEAD'
run 'git log --oneline -2'

snip 16-revert-squash
note 'Copy 2: one ordinary revert.'
run 'cd ../../squash/you'
run 'git revert --no-edit HEAD'
run 'git log --oneline -2'

snip 17-revert-rebase
note 'Copy 3: one revert per commit, and you must know where the pull request began.'
run 'cd ../../rebase/you'
run 'git revert --no-edit HEAD~3..HEAD'
run 'git log --oneline -4'

lab_end

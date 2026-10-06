# Module 36 lab answers: incident drills, local and history

> Read these after you have written your own answers. The full worked solution of each incident is in `solutions/incident-NN-<slug>.md`; the answers below are short and point there.

## Lab 36.1 (incident 1, [solution](incident-01-hard-reset.md))

1. The reflog of the branch (or of HEAD) contains no `pull` line: `git reflog | grep -c pull` prints 0. The line that does explain the move is `feature/escalation-rules@{1}: reset: moving to origin/main`.
2. `git add` stored the content as a blob. The file name was kept in the index entry, and the reset removed that entry. A dangling blob has content and no name, so you choose the path when you write it back.
3. The new file was staged, so its content reached the object database. The edit to `rules/routing.yaml` was never staged or committed; it existed only in the working tree, which `git reset --hard` overwrote. Git has no object for it.
4. After the second reset the branch (and HEAD) points at `0322a16`, the old tip. `git branch <name>` without an ID creates the branch at HEAD.
5. `git restore rules/routing.yaml` discards the edit to that one file. `git stash` parks it. Neither moves the branch.

## Lab 36.2 (incident 8, [solution](incident-08-branch-disappeared.md))

1. `git branch -d` checks reachability: the branch tip must be an ancestor of its upstream or of HEAD. A squash merge puts the content into `main` as a new commit; the branch's own commits are not ancestors of `main`, and here one commit was not merged at all.
2. `git cherry` compares commits one by one by patch ID. A squashed commit has the combined patch and equals none of its parts, so every part looks unmerged. `git diff --stat main <commit>` compares trees: it is empty for the third commit and shows one file for the fourth.
3. It recreates the head branch as the server last had it: the three pushed commits. It cannot bring back the fourth commit, which was never pushed.
4. `fetch.prune=true` removes remote-tracking refs whose branch is gone on the server. It is not a mistake; it keeps `git branch -r` truthful. It does mean that the remote-tracking ref is not a backup of a deleted branch.
5. With default settings the HEAD reflog entry of a commit that is no longer reachable from any ref expires after 30 days (`gc.reflogExpireUnreachable`), and the object is deleted about two weeks later once maintenance runs. The lab configuration switches the expiry off.

## Lab 36.3 (incident 10, [solution](incident-10-commit-local-not-remote.md))

1. `git ls-remote upstream main` (or `git remote -v` followed by a look at which remote `origin` is). `ls-remote` asks the server itself; every other signal he quoted reads local refs.
2. `(fetch first)` means the server's branch names a commit the clone does not have at all, so Git cannot even test ancestry. `(non-fast-forward)` is printed when the clone has the server's commit and it is not an ancestor of what is being pushed. Ravi's clone had not fetched `ebd3afc`.
3. `git pull --rebase` without an upstream on the command line uses the fork point from the reflog of `origin/main`. The commit `ebd3afc` is in that reflog ("update by push"), so it counted as old upstream history and was not replayed. `ORIG_HEAD` and the reflog of `main` still named it.
4. It sets the remote that a push uses when none is given on the command line. It does not change where `git pull` and `git fetch` get changes from, and it does not change a branch's upstream.
5. For example: "For every fix promised for this release, `git merge-base --is-ancestor <commit> origin/main` exits 0 in a fresh clone of the team repository."

## Lab 36.4 (incident 9, [solution](incident-09-misunderstood-conflict.md))

1. With a path, `git log` simplifies history: at a merge whose version of the path equals one parent, it follows only that parent. The merge `d7497e2` took the file unchanged from its first parent, so the side with Asha's commits is pruned. `--full-history` shows them.
2. The second hunk, in `refill`. There was no conflict there: the mechanical merge had Asha's `min(BURST, ...)` line, and the recorded merge replaces it. A human who resolves only the conflict does not touch a cleanly merged hunk; replacing the whole file does.
3. In `git merge origin/main` on a feature branch, ours is the feature branch (HEAD) and theirs is `main`. In `git rebase origin/main`, ours is the commit being built on, which starts as `origin/main`, and theirs is your own commit being replayed.
4. `-m 1` computes the change from the first parent to the merge and inverts it. For this merge that change is empty, because the merge result equals its first parent. That emptiness is the defect.
5. Any one of: a regression test for the cap, which would have failed on the branch; a review of the merge commit with `git show --remerge-diff`; resolving with `zdiff3` markers so that both sides' changes are visible.

## Lab 36.5 (incident 5, [solution](incident-05-rebased-shared-branch.md))

1. The commit list is `main..head`: all commits reachable from the head and not from `main`, nine with both series. The file view is `main...head`: the diff from the merge base to the head. Two copies of a change produce the same tree as one, so the diff is unchanged.
2. A lease protects the server's branch from being overwritten if it changed since the pusher last saw it. It knows nothing about unpublished commits in a teammate's clone that are based on the commits being replaced.
3. `<old>` is the upstream limit: commits after it, up to the branch tip, are replayed. `<new>` is the commit they are replayed onto.
4. `git diff --stat rescue/merged-state feature/online-serving` prints nothing: the trees are identical. `git range-diff` pairs the two replayed commits with `=`.
5. `pull.rebase=true`: `git pull --rebase` finds the old fork point in the reflog of the remote-tracking branch and replays only your own commits onto the rewritten upstream. `pull.ff=only` also prevents it, by stopping instead of merging.

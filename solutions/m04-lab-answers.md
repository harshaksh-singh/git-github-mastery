# Module 4 lab answers: Refs, branches, HEAD, and detached HEAD

Answers to the Questions in [lab-manual/m04-refs-branches-head.md](../lab-manual/m04-refs-branches-head.md). Read them after you have written your own.

## Lab 4.1: Refs by hand

1. **Reflog messages come from the command that performs the update, not from the ref store.** `git branch` and `git switch` pass a message that describes what they did (`branch: Created from main`, `checkout: moving from A to B`); `git update-ref` passes whatever you give with `-m`, and nothing when you give nothing. The ref store only records the old ID, the new ID, the identity, the time and that message. Reading a reflog therefore tells you which porcelain command moved a ref, which is useful in a diagnosis.

2. **With three arguments, `git update-ref` writes `<new>` only if the ref currently holds `<old>`**; otherwise it fails and changes nothing. It protects against the lost update: two processes read the ref, both compute a new value from what they read, and the second write silently overwrites the first. With the check, the second writer learns that its information is stale. Without it, a fetch and a user command, or two hooks, could each move the same branch and one of the moves would vanish without a trace other than the reflog.

3. **It compared the commit that HEAD names with the index.** After the symbolic-ref change HEAD resolved to `6eab4a9`, whose tree has only `README.md`, while the index still held the three files of `main`. `git status` reports index entries that are not in HEAD's tree as staged additions, hence two `A` lines. The working tree did not change because `git symbolic-ref` writes one file, `.git/HEAD`; only `git switch` and `git checkout` update the index and working tree to match the new HEAD.

4. **Blocked: every operation that must resolve all refs.** `git log --all` died; `git fsck`, `git gc`, `git pack-refs` and a push or fetch that enumerates refs would also have to deal with a ref that names no object, and `git update-ref` refused to write that ref at all. **Continued:** work that names other refs explicitly. `git log main`, commits on `main`, and `git branch -v` (which warned and listed the rest) do not need the broken ref. The rule of thumb: a broken ref is an outage for anything that iterates over refs, and the diagnosis is `git refs verify`.

5. **`git update-ref` validated that the ID names an existing object, took the lock that every ref update uses, and appended a line to the branch's reflog.** `echo` would have written bytes into a file with no check (a typo would have produced the same corruption again), no lock against a concurrent writer, and no reflog entry, so the restore itself would have left no trace. Deleting the broken file first was necessary because `git update-ref` refuses to resolve a broken ref even in order to overwrite it.

## Lab 4.2: Detached HEAD rescue

1. **Because a commit needs a parent, not a branch.** `git commit` takes the parent from whatever HEAD resolves to, and HEAD can resolve to a commit directly. Git gains three things: you can inspect and test any historical commit, including building and committing experiments on it, without inventing a branch name first; `git bisect` and `git rebase` can check out arbitrary commits as part of their algorithms; and a clone or a CI job can stand on a tag or a merge commit that no branch names. The cost is that such commits are held only by HEAD and the reflog until you name them.

2. **`.git/logs/HEAD`, the reflog of HEAD.** Every movement of HEAD, including each commit made in detached state, appended a line with the new ID. `git reflog` (which is `git reflog show HEAD`) reads it, and `git log -g` walks it like a history. The reflog of `main` knew nothing about the experiments, because `main` never moved.

3. **Yes, a tag would also have made the commit reachable**; the manual lists `git tag <name>` as the third way to keep a detached commit. The differences: a tag is not expected to move, so you could not continue the experiment with further commits on it in the normal way; a lightweight tag has no reflog, so `git tag -d` later would leave no trace; and `git push --tags` or `--follow-tags` would publish it. A branch is the right container for work that continues; a tag is a label for a point you want to keep.

4. Newest first, immediately after the detour:

   ```text
   HEAD@{0}  2daf400  checkout: moving from b01a3f1... to main
   HEAD@{1}  b01a3f1  checkout: moving from main to v0.1.0
   HEAD@{2}  2daf400  checkout: moving from 5ff0417... to main
   HEAD@{3}  5ff0417  commit: Experiment: threshold 0.9          <- the one to rescue
   HEAD@{4}  b05f89a  commit: Experiment: stricter judge threshold
   HEAD@{5}  b01a3f1  checkout: moving from main to v0.1.0
   HEAD@{6}  2daf400  commit: Add batch runner
   ```

   `HEAD@{1}` was the tag's commit, because the detour added two movements on top. The recovery found the right entry by message with `--grep-reflog`, which does not depend on counting.

5. **For 30 days by default, assuming maintenance runs.** Reflog entries that are not reachable from the current tip of the ref expire after `gc.reflogExpireUnreachable`, 30 days by default; the experiment commits are unreachable from `main`, which HEAD now names. Entries that are reachable expire after `gc.reflogExpire`, 90 days. Once the entries are gone, the commit objects are unreachable and are pruned when they are older than `gc.pruneExpire`, two weeks by default. The sandbox configuration of the replays sets the two reflog keys to `never`; the lab shell uses the defaults, but nothing in the lab ran `git gc`.

## Lab 4.3: The `feature` versus `feature/x` conflict

1. **Because a remote-tracking ref is your repository's record of the last fetch, not a live view of the server.** `origin/feature` was written when the branch still existed on the server and stays until a fetch updates or prunes it. Nothing on the server can change a file in your `.git`; only your own `git fetch` (or `git remote prune`) does.

2. **Both messages come from the same rule, enforced at the moment a ref is written.** When you create a local branch, Git tries to take the lock for the new ref and reports the conflict as `cannot lock ref`, naming the ref that stands in the way. During a fetch, each remote-tracking ref is updated separately; the one that cannot be written is reported as `unable to update local ref`, and Git adds the hint about `git remote prune origin` because stale remote-tracking refs are the common cause. The fetch also continued with the refs that could be updated, which is why `origin/HEAD` appeared.

3. **No.** Pruning removes remote-tracking refs that the server no longer has; a local branch `feature` under `refs/heads/` is not affected by it, and a fetch into `refs/remotes/origin/feature/login` would not conflict with it anyway. For your own `feature`, the fix is what step 2 did: rename it under the namespace with `git branch -m feature feature/<name>`, or delete it after `git log --oneline main..feature` shows that nothing on it is unmerged.

4. **`fetch.prune=true`**, which makes every fetch behave as if `--prune` were given (`remote.<name>.prune` does the same for one remote). The risk is that a branch deleted on the server by mistake disappears from every clone's remote-tracking refs at the next fetch; the local branches that tracked it remain and show `[gone]`, but a branch that nobody had checked out locally is then recoverable only from the server's own safety nets or from the reflog of whoever pushed it.

5. **On the server:** `refs/heads/feature` was deleted. **In Asha's clone:** her remote-tracking ref `origin/feature` was removed at the same time, because a push updates the pusher's remote-tracking refs to match what it did on the server. **In your clone:** nothing changed. Your `refs/remotes/origin/feature` and your local `feature` stayed exactly as they were until your next fetch, which is the whole cause of the failure scenario.

## Lab 4.4: Counting divergence

1. **A merge base of two commits is an ancestor of both that is not itself an ancestor of another ancestor of both.** It is the point from which both histories can be reached by following children, and the point where a merge starts comparing. There can be more than one when the two histories were already merged into each other in both directions earlier, the criss-cross case: two commits can each be reachable from both tips without either being an ancestor of the other. Chapter 8, section 8.5, shows such a history.

2. `main..feature/rouge` answers "what does the feature have that `main` lacks": three commits. `feature/rouge..main` answers "what does `main` have that the feature lacks": two commits. `main...feature/rouge` is the union of the two sets, the symmetric difference, and `--left-right` labels each commit with the side it came from. The merge base itself is in none of the three sets.

3. **A fast-forward moves a ref to a commit that already contains everything the ref had.** If `main` is an ancestor of X, every commit reachable from `main` is reachable from X, so pointing `main` at X loses nothing and adds X's new commits; no merge commit is needed. If `main` is not an ancestor of X, `main` has commits that X lacks, and moving the ref would drop them, so `--ff-only` refuses. On success, `.git/refs/heads/main` receives X's ID, the reflogs of `main` and HEAD gain a line, and the index and working tree are updated to X's tree. No object is created.

4. **`git rev-list --left-right --count main...<branch>` and `git for-each-ref --format='%(ahead-behind:main)' refs/heads/<branch>`.** Both count from the merge base of the two tips: "ahead" is the number of commits reachable from the branch but not from the base branch, "behind" the reverse. The pull request's base branch plays the role of `main`, and the numbers change whenever either branch moves, because the merge base and the two sets change with them.

5. **The fast-forward moved `main` to `618b77f`, the tip of `docs/quickstart`.** `feature/rouge` was not touched: its tip, its commits and its reflog are unchanged, and it is still 3 ahead. The second number counts commits on `main` that the feature lacks, and `main` now has one more of them, so 2 became 3. Divergence is a property of the pair of branches, so moving either side changes it.

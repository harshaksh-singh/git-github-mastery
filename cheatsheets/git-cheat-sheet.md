# Git cheat sheet

> **Baseline.** Git 2.55.0. 🟢 SAFE reads state or only adds objects · 🟡 CAUTION moves refs or rewrites local history, recoverable through the reflog · 🔴 DANGEROUS can destroy uncommitted work, remote history, or the safety net itself (Chapter 1, section 1.8). Every command is taught in the textbook; the number in brackets is the section. Full forms: [Git command reference](../reference/git-command-reference.md). The five answers for every 🟡 and 🔴 command: [command safety](../reference/command-safety.md). When something is already lost: [emergency recovery](emergency-recovery-one-page.md).

## Before anything else: look

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git status -sb` | Branch, upstream, ahead and behind, changed paths (4.4) | `git status -sb` | 🟢 | Reading "clean" as "equal to the commit": ignored files are not shown | `git status --ignored` |
| `git log --oneline --graph --decorate --all` | Every ref as a graph (14A.9) | `git log --oneline --graph --decorate --all -20` | 🟢 | Forgetting `--all`: the walk starts at HEAD only | Not needed |
| `git diff`, `git diff --cached` | Index against working tree; HEAD against index (5.4) | `git diff --cached` | 🟢 | Committing without reading the staged diff | Not needed |
| `git reflog` | Every commit HEAD was on, and the command that moved it (13.3) | `git reflog -10` | 🟢 | Expecting one in a fresh clone or on CI | The clone where the work was done |
| `git remote -v`, `git branch -vv` | Where pushes go; which upstream each branch has (12.2, 12.5) | `git branch -vv` | 🟢 | Trusting `origin/<branch>` without fetching: it is a cache | `git fetch` |

## Daily use

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git init` | Creates `.git` (1.9) | `git init shop` | 🟢 | Running it in the wrong directory | Remove the stray `.git` if it holds nothing |
| `git clone` | New repository with `origin`, remote-tracking refs and one checked-out branch (12.3) | `git clone <url>` | 🟢 | `--depth 1` where history is needed | `git fetch --unshallow` |
| `git add <path>` | Stores content as a blob and points the index entry at it (5.3) | `git add src/router.py` | 🟢 | Editing after `git add`: the commit lacks the edit | `git add` again |
| `git add -p` | Stages hunk by hunk (5.5) | `git add -p` | 🟢 | Following it with `git commit -a` | `git reset HEAD~1` 🟡 while private, stage again |
| `git commit -m` | New commit from the index; moves the current branch (6.3) | `git commit -m "Add rate limits"` | 🟢 | A missing file: it was never staged | A further commit |
| `git commit --amend` | Replaces the tip commit with a new one (6.7) | `git commit --amend --no-edit` | 🟡 | Amending a commit that is already pushed | `git reset --soft 'HEAD@{1}'` |
| `git restore --staged <path>` | Unstages: index entry copied from HEAD (5.9) | `git restore --staged notes.txt` | 🟡 | Using `git rm --cached`, which stages a deletion | `git add <path>` |
| `git restore <path>` | Overwrites the file from the index (4.7) | `git restore -p src/router.py` | 🔴 | Not reading `git diff -- <path>` first | None for content never staged |
| `git rm --cached <path>` | Stops tracking; the file stays on disk (4.6) | `git rm --cached .env` | 🟡 | Forgetting that the commit deletes the file for everyone who pulls | `git restore --staged <path>` before committing |
| `git mv <a> <b>` | Renames the file and its index entry (4.8) | `git mv old.py new.py` | 🟢 | Renaming and editing in one commit: history of the file stops at the rename | Rename and edit in separate commits |
| `git stash push -u` | Parks index and working tree as commits under `refs/stash` (11.11) | `git stash push -u -m "wip retry"` | 🟡 | Leaving long-lived work in the stash | `git stash pop --index` |
| `git stash pop` | Applies the newest entry and drops it (11.11) | `git stash pop --index` | 🟡 | Popping onto local edits: conflict, entry kept | `git reset --merge`, then `git stash branch <name>` |
| `git switch <branch>` | Moves HEAD, index and working tree; refuses to lose edits (7.6) | `git switch -c feature/streaming` | 🟢 | Committing on a detached HEAD and leaving | `git branch <name> <id>` from `git reflog` |
| `git config get`, `list` | Reads configuration with its origin (14B.3; Git 2.46 or later) | `git config list --show-origin --show-scope` | 🟢 | Looking in one scope only | Not needed |
| `git config set` | Writes one configuration file (14B.3; Git 2.46 or later) | `git config set --global pull.ff only` | 🟡 | A mistyped key is stored and ignored | `git config unset` |

## History

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git log <A>..<B>` | Commits reachable from B and not from A (14A.8) | `git log --oneline origin/main..HEAD` | 🟢 | Confusing it with `git diff A..B`, which compares two tips | Not needed |
| `git log <A>...<B> --left-right` | Commits on either side and not both (14A.14) | `git log --oneline --left-right main...feature/x` | 🟢 | Reading three dots in `log` like three dots in `diff` | Not needed |
| `git diff <A>...<B>` | Merge base against B: what a branch adds (14A.2) | `git diff --stat main...feature/x` | 🟢 | Two dots for review | Not needed |
| `git show <commit>` | One commit with its diff; a file at a revision (3.5) | `git show HEAD~1:config/limits.yaml` | 🟢 | Reading a merge's combined diff as the whole merge | `git show --remerge-diff <merge>` |
| `git log -S<string>` | Commits that changed the number of occurrences (14A.11) | `git log -S'PASS_MARK' --oneline` | 🟢 | Taking the hit for the cause without reading the patch | Check with `-G` and `git show` |
| `git log -L` | History of a range of lines or a function (14A.12) | `git log -L :score:scoring/metrics.py` | 🟢 | Anchoring on line numbers | A `/regex/` or `:funcname` range |
| `git log --follow -- <path>` | History of one file across renames (14A.10) | `git log --follow --oneline -- src/app.py` | 🟢 | Expecting it to survive a rename plus rewrite | Read on under the old path |
| `git blame` | The commit that last changed each line (14A.16) | `git blame -w -C -L 10,30 <file>` | 🟢 | Stopping at a formatting commit | `--ignore-rev`, `--ignore-revs-file` |
| `git shortlog -sn <rev>` | Commit counts per author (14A.15) | `git shortlog -sn --no-merges HEAD` | 🟢 | Omitting the revision in a script: it reads standard input | Pass the revision |
| `git describe` | Version string from the nearest tag (14B.12) | `git describe --tags --dirty` | 🟢 | Shallow clone without tags | `git fetch --unshallow --tags` |
| `git range-diff` | Compares two versions of a commit series (9.14) | `git range-diff main ORIG_HEAD HEAD` | 🟢 | Pushing a rebase without it | Not needed |

## Branches and integration

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git branch <name> [<start>]` | Adds one ref (7.5) | `git branch rescue/before-rebase` | 🟢 | Branching on an unborn branch | Make the first commit |
| `git branch -d` | Deletes a merged branch and its reflog (7.5) | `git branch -d feature/x` | 🟡 | Reading the refusal after a squash merge as a bug | `git branch <name> <id>` from the `was <id>` line |
| `git branch -D` | Deletes with no merge check (7.5) | `git branch -D feature/x` | 🔴 | Deleting the only name of unmerged commits | HEAD reflog, while the objects exist |
| `git merge <other>` | Fast-forward or three-way merge into the current branch (8.3, 8.4) | `git merge --no-ff feature/x` | 🟡 | Whole-file `--ours` or `--theirs` in a conflict | `git reset --merge ORIG_HEAD`; pushed: `git revert -m 1` |
| `git merge --abort` | Back to the state before the merge (8.10) | `git merge --abort` | 🔴 | Losing resolutions and edits staged during the merge | `git fsck` for staged content |
| `git merge-tree --write-tree` | A test merge without touching anything (8.17) | `git merge-tree --write-tree --name-only HEAD feature/x` | 🟢 | The deprecated three-argument form | Not needed |
| `git rebase <upstream>` | Re-creates your commits on top of the upstream; new IDs (9.2) | `git rebase origin/main` | 🟡 | Rebasing a branch others push to | `git reset --hard <branch>@{1}` 🔴 |
| `git rebase -i` | Reorder, squash, edit, drop commits (9.6) | `git rebase -i --autosquash origin/main` | 🟡 | Deleting a line: the commit is dropped silently | Same reset; `rebase.missingCommitsCheck=error` |
| `git rebase --onto <new> <old>` | Replays only the commits after `<old>` (9.5) | `git rebase --onto main feature/base` | 🟡 | The wrong boundary: conflicts in files you never changed | `git rebase --abort` |
| `git rebase --continue`, `--abort` | Go on after resolving; or give up (9.11) | `git rebase --continue` | 🟡 | `--amend` at a conflict stop; forgetting that "ours" is the new base | Reflog of the branch |
| `git cherry-pick -x <commit>` | Copies one change as a new commit (10.2) | `git cherry-pick -x <id>` | 🟡 | No `-x` on a backport | `git cherry-pick --abort`; pushed: `git revert` |
| `git tag -a <name>` | Annotated tag: a tag object plus a ref (14B.8) | `git tag -a v1.0.0 -m "1.0.0"` | 🟢 | Moving it after publishing | `git tag -d <name>` while unpublished |
| `git worktree add` | A second working tree on the same repository (25.2) | `git worktree add ../hotfix release/1.2` | 🟢 | Removing it with `rm -rf` | `git worktree prune` |

## Remotes

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git fetch` | Updates remote-tracking refs; never your branches (12.4) | `git fetch origin` | 🟢 | Believing it changed your branch | Not needed |
| `git fetch --prune` | Also deletes stale remote-tracking refs and their reflogs (12.11) | `git fetch --prune` | 🟡 | Pruning the last name of commits you still need | `git fsck --lost-found`, then `git branch <name> <id>` |
| `git pull --ff-only` | Fetch, then fast-forward or stop (12.6) | `git pull --ff-only` | 🟡 | Plain `git pull` on diverged branches without a setting: fatal | `git reset --hard ORIG_HEAD` 🔴, at once |
| `git pull --rebase` | Fetch, then re-create your unpushed commits (9.13) | `git pull --rebase` | 🟡 | After someone's forced push it can drop commits | `git reset --hard <branch>@{1}` 🔴 |
| `git push -u origin <branch>` | Publishes the branch and sets its upstream (12.5) | `git push -u origin feature/x` | 🟡 | `Everything up-to-date` while the commit is on another branch | Push the branch that holds it |
| `git push --dry-run` | Shows `<source> -> <destination>` without sending (12.7) | `git push --dry-run` | 🟢 | Skipping it before a push that matters | Not needed |
| `git push --force-with-lease --force-if-includes` | Replaces the server's branch only if it is what you last integrated (12.8) | `git push --force-with-lease --force-if-includes` | 🔴 | Using it on a branch others push to | The old tip from your reflog, pushed back |
| `git push --force` | Replaces the server's branch unconditionally (12.8) | none: use the guarded form | 🔴 | Answering "non-fast-forward" with it | A clone that still has the old tip |
| `git push origin --delete <branch>` | Deletes a ref on the server (12.7) | `git push origin --delete feature/x` | 🔴 | Deleting a branch with unmerged commits | `git push origin <id>:refs/heads/<name>` |
| `git push origin <tag>` | Publishes one tag (14B.10) | `git push origin v1.0.0` | 🟡 | `--tags`, which publishes every local tag | None that is clean |
| `git ls-remote` | What the server has now (12.4) | `git ls-remote --tags origin` | 🟢 | Deciding from stale remote-tracking refs | Not needed |
| `git remote set-url` | Changes where a remote points (12.2) | `git remote set-url origin <url>` | 🟡 | A token inside the URL | Set the previous URL; revoke the token |
| `git submodule update --init --recursive` | Checks out the recorded submodule commits (23.3) | `git submodule update --init --recursive` | 🟡 | Work on the detached HEAD vanishes at the next update | `git -C <path> branch <name> <id>` |

## Undo

| Situation | Command | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| Unstage a file | `git restore --staged <path>` (5.9) | `git restore --staged notes.txt` | 🟡 | `git reset --hard` instead | `git add <path>` |
| Discard edits to a file | `git restore <path>` (4.7) | `git restore -p config.yaml` | 🔴 | No `git diff` first | None unless staged once |
| Get one file from another commit | `git restore --source=<commit> <path>` (11.3) | `git restore --source=HEAD~2 -- config.yaml` | 🔴 | A `.` as the path: deletes files the commit lacks | `git restore .` for the index versions |
| Fix the last commit, unpushed | `git commit --amend` (11.7) | `git commit --amend` | 🟡 | Unrelated staged changes are swallowed | `git reset --soft 'HEAD@{1}'` |
| Take back commits, keep the changes | `git reset --soft <commit>` or `git reset <commit>` (11.4) | `git reset --soft HEAD~1` | 🟡 | Doing it to pushed commits | `git reset --soft ORIG_HEAD`, at once |
| Move the branch, keep local edits safe | `git reset --keep <commit>` (11.6) | `git reset --keep origin/main` | 🟡 | Reaching for `--hard` | `ORIG_HEAD`, the reflog |
| Throw away commits and edits | `git reset --hard <commit>` (11.5) | `git reset --hard origin/main` | 🔴 | Uncommitted work in the tree | Commits: reflog. Staged: `git fsck --lost-found`. Unstaged: none |
| Undo a pushed commit | `git revert <commit>` (11.8) | `git revert --no-edit <id>` | 🟡 | Resetting and force-pushing instead | Revert the revert |
| Undo a pushed merge | `git revert -m 1 <merge>` (11.9) | `git revert -m 1 <id>` | 🟡 | Merging the same branch again later: its changes are missing | Revert the revert, then merge |
| Remove untracked files | `git clean -n`, then `git clean -f` (4.14) | `git clean -n -d` | 🔴 | `-x` in a repository with ignored data | None through Git |
| Leave a merge, rebase or pick | `--abort` (29.6) | `git rebase --abort` | 🟡 (merge: 🔴) | Aborting before anchoring new commits | HEAD reflog |

## Recovery

| Situation | Command | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| Name a state before touching anything | `git branch rescue/<what> <id>` (13.7) | `git branch rescue/before-fix` | 🟢 | A second fix before the anchor | `git branch -D` when done |
| Find where a branch was | `git reflog show <branch>` (13.3) | `git reflog show main` | 🟢 | Using `ORIG_HEAD` later than the next command | The branch reflog |
| Commits lost by reset, amend or rebase | `git reset --keep <id>` or `git cherry-pick <range>` (13.8) | `git reset --keep 'main@{1}'` | 🟡 | `--hard` during recovery | `ORIG_HEAD` |
| A deleted branch | `git branch <name> <id>` (13.8) | `git branch feature/x <id>` | 🟢 | Looking for the deleted branch's reflog | HEAD reflog; `git fsck --no-reflogs` |
| Staged content that was overwritten | `git fsck --lost-found` (13.9) | `git fsck --lost-found` | 🟢 | Running `git gc --prune=now` first | `git cat-file -p <id> > <path>` |
| A dropped stash | `git stash store -m <message> <id>` (13.9) | `git fsck --unreachable` to find the ID | 🟢 | `git stash clear` | While the objects exist |
| A teammate force-pushed | `git reflog show origin/<branch>` (13.10) | `git branch rescue/server-before origin/main@{1}` | 🟢 | Pulling first | Push the old tip back, with a lease |
| A backup that can travel | `git bundle create <file> --all` (13.14) | `git bundle verify repo.bundle` | 🟢 | Expecting reflogs or uncommitted files in it | `cp -Rp` of the repository for those |
| The point of no return | `git reflog expire --expire=now --all`, `git gc --prune=now` (13.13) | none: only at the end of a secret clean-up | 🔴 | Running them as "maintenance" | None |

## Debugging

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git bisect start`, `good`, `bad` | Binary search for the commit that changed a property (14A.20) | `git bisect start HEAD v1.2.0` | 🟡 | A dirty tree; a verdict on a commit that does not build | `git bisect reset` |
| `git bisect run <command>` | Lets a script give the verdicts; exit 125 skips (14A.21) | `git bisect run ./test.sh` | 🟡 | A script that fails for other reasons than the bug | `git bisect log`, edit, `git bisect replay` |
| `git check-ignore -v` | The pattern that ignores a path (4.5) | `git check-ignore -v build/out.log` | 🟢 | Asking about a tracked file | `--no-index` |
| `git ls-files --stage` | The index, entry by entry; stages 1 to 3 in a conflict (5.11) | `git ls-files -u` | 🟢 | Missing the lower-case tag of `-v` for assume-unchanged | `git update-index --no-assume-unchanged` |
| `git rev-parse` | A name as an object ID; facts about the repository (3.6) | `git rev-parse --abbrev-ref HEAD` | 🟢 | Reading `.git` files in scripts | Not needed |
| `git cat-file -p`, `-t` | Content and type of any object (3.5) | `git cat-file -p HEAD` | 🟢 | Assuming 40-digit IDs | Not needed |
| `git config list --show-origin --show-scope` | Every setting and the file it comes from (14B.2) | `git config get --show-origin user.email` | 🟢 | Forgetting includes and environment variables | `git var GIT_AUTHOR_IDENT` |
| `GIT_TRACE=1 git <command>` | What Git actually ran (14B.7) | `GIT_TRACE=1 git st` | 🟢 | Pasting a trace that holds credentials | Not needed |
| `git diff --check` | Conflict markers and whitespace errors (14A.6) | `git diff --cached --check` | 🟢 | Committing a merge without it | A new commit that removes the markers |
| `git fsck` | Integrity of the object database (3.8) | `git fsck` | 🟢 | Reading `dangling` as damage | Not needed |

## Advanced

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git commit --fixup=<commit>` with `git rebase --autosquash` | A correction that finds its target at the next rebase (9.7) | `git commit --fixup=<id>` | 🟢, then 🟡 | Forgetting the rebase before merging | Fold it in, or drop it |
| `git rebase --update-refs` | Moves every local branch in the range: stacks stay stacked (9.9; Git 2.38 or later) | `git rebase --update-refs main` | 🟡 | It moves branches you did not name | Each branch from its reflog |
| `git rerere` | Replays recorded conflict resolutions (14C.3) | `git rerere diff` | 🟢, 🟡 for `forget` | A wrong resolution is replayed too | `git rerere forget <path>`, `git restore --merge <path>` 🔴 |
| `git add --renormalize .` | Restages every file under the current attributes (14C.5) | `git add --renormalize .` | 🟡 | Mixing it with other changes | `git restore --staged .` |
| `git hook list <event>` | Which hooks would run, and from which scope (14C.11) | `git hook list --show-scope pre-commit` | 🟢 | Treating hooks as enforcement | Enforce on the server |
| `git sparse-checkout set` | Limits the working tree to a cone of directories (24.4) | `git sparse-checkout set services/gateway` | 🟡 | Ignored files in directories that leave the cone are deleted | None for those files |
| `git clone --filter=blob:none` | A blobless partial clone: full history, blobs on demand (26.12) | `git clone --filter=blob:none <url>` | 🟢 | Going offline without `git backfill` | Reconnect |
| `git maintenance run` | Packs, commit-graph, multi-pack-index (26.3) | `git maintenance run --task=commit-graph` | 🟡 | Running `git gc` beside it | None for expired reflog entries |
| `git gc --prune=now` | Deletes all unreachable objects at once (13.13) | none: see Recovery | 🔴 | "It fixes a slow repository" | None in this repository |
| `git worktree remove` | Deletes a clean working tree and its HEAD reflog (25.6) | `git worktree remove ../hotfix` | 🟡 (🔴 with `--force`) | Detached commits made there lose their name | `git fsck --lost-found` |
| `git lfs track`, `git lfs migrate info` | Which paths become pointers; what a migration would rewrite (22.4, 22.9) | `git lfs migrate info --above=1mb` | 🟢 | Tracking after the file is in history | `git lfs migrate import` on unpushed commits 🟡 |
| `git history reword` | Rewrites one commit and moves descendant branches (14D.6; experimental, Git 2.54 or later) | `git history reword --dry-run HEAD~2` | 🟡 | Using it on published commits | Each branch from its reflog |
| `git update-ref <ref> <new> [<old>]` | Writes one ref and nothing else (7.2) | `git update-ref refs/backup/main <id>` | 🟡 (🔴 with `-d`) | Moving the current branch with it | `git update-ref <ref> "<ref>@{1}"` |

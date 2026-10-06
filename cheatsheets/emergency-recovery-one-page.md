# Emergency recovery: one page

Git 2.55.0. 🟢 reads or only adds · 🟡 moves refs, recoverable through the reflog · 🔴 can destroy work or the safety net. Every command was run in this book's labs. Details: [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md).

**Stop.** No `git gc`, `git prune`, `git clean`, `git stash clear`, `git fetch --prune`, re-clone or second fix until the lost state has a name.

## Look (always first)

| Command | | Shows |
|---|---|---|
| `git status -sb` | 🟢 | branch, upstream, ahead and behind, operation in progress |
| `git reflog show <branch>` | 🟢 | every value the branch had, and the command that set it |
| `git reflog` | 🟢 | every commit HEAD was on (survives branch deletion) |
| `git reflog show origin/<branch>` | 🟢 | the server's values as this clone saw them; `@{1}` is the one before the last change |
| `git ls-remote origin` | 🟢 | what the server holds now |
| `git fsck --lost-found` | 🟢 | dangling commits and blobs; copies in `.git/lost-found/` |

## Anchor (before anything moves)

| Command | | |
|---|---|---|
| `git branch rescue/<what> <ID>` | 🟢 | a named commit cannot expire |

## Recover

| Disaster | Command | |
|---|---|---|
| Reset, amend or rebase took commits away | `git reset --keep rescue/<what>` | 🟡 |
| The same, but new commits were made since | `git cherry-pick <branch>..rescue/<what>` | 🟡 |
| Branch deleted (`Deleted branch x (was <ID>)`) | `git branch <name> <ID>` | 🟢 |
| Rebase in progress, going wrong | `git rebase --abort` | 🟡 |
| Merge in progress, going wrong | `git merge --abort` (discards the resolutions made so far) | 🔴 |
| Bad merge committed, not pushed | `git reset --keep ORIG_HEAD` | 🟡 |
| Bad commit on a shared branch | `git revert --no-edit <ID>` | 🟡 |
| Bad merge on a shared branch | `git revert -m 1 <merge>` (a later re-merge then brings nothing) | 🟡 |
| Staged file overwritten | `git cat-file -p <blob ID> > <path>` | 🟡 |
| Stash dropped | `git stash store -m 'recovered' <ID>` | 🟢 |
| Server branch force-pushed: keep the newcomers | `git push origin origin/<branch>:refs/heads/<new-name>` | 🟢 |
| Server branch force-pushed: restore | `git push --force-with-lease=<branch>:<bad ID> origin rescue/<what>:<branch>` | 🔴 |
| Server branch deleted | `git push origin <name>` | 🟢 |
| My clone after the server was restored | `git cherry -v origin/<branch> <branch>`, then `git reset --keep origin/<branch>` | 🟢 🟡 |
| Corrupt index | `mv .git/index .git/index.corrupt && git reset` | 🟡 |
| Missing or corrupt objects | `git fetch --refetch origin` | 🟡 |
| Secret committed | **Rotate the credential first.** Then the playbook, page 11 | |

## Verify

| Command | | Proves |
|---|---|---|
| `git range-diff <base> <old> <new>` | 🟢 | `=` on every line: the same commits came back |
| `git diff --stat <old> <new>` | 🟢 | no output: identical content |
| `git merge-base --is-ancestor <ID> <branch>` | 🟢 | exit 0: the commit is on the branch |
| `git ls-remote origin <branch>` | 🟢 | the server has the ID you intended |

## Never in an emergency

| Command | | Why |
|---|---|---|
| `git reset --hard` | 🔴 | destroys uncommitted changes; use `--keep` |
| `git push --force` | 🔴 | no condition; use `--force-with-lease=<branch>:<ID>` |
| `git reflog expire --expire=now --all`, `git gc --prune=now` | 🔴 | deletes the safety net itself |
| `git clean -f -d` | 🔴 | deletes untracked files; no undo |

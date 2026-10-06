# Command safety: every 🟡 and 🔴 command of the book

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. This file is compiled from the "Command safety" tables and the inline risk labels of Chapters 1 to 30. It adds nothing to them. The section number in the last column is where the textbook answers the questions in full.

## 1. How to read this file

The three labels are defined in Chapter 1, section 1.8, and they describe the worst case:

| Label | Meaning | Examples from 1.8 |
|---|---|---|
| 🟢 SAFE | Reads state or only adds objects. Nothing is lost | `git status`, `git log`, `git fetch`, `git reflog`, `git commit` |
| 🟡 CAUTION | Moves refs or rewrites local history. Recoverable through the reflog if you know how | `git reset --soft`, `git rebase`, `git commit --amend` |
| 🔴 DANGEROUS | Can destroy uncommitted work, remote history, or the safety net itself | `git reset --hard`, `git clean -fd`, `git push --force` and its conditional forms `--force-with-lease` and `--force-if-includes`, `git reflog expire --expire=now --all`, `git gc --prune=now` |

Before any 🔴 command the book answers five questions: what it changes, what it can destroy, how to preview it, how to recover, when it is appropriate. The tables below give those five answers for every 🔴 and every 🟡 command. 🟢 commands are not listed here; they are in the [Git command reference](git-command-reference.md).

Three rules follow from the tables and are worth knowing before you read them:

1. **The preview is always a 🟢 command.** Run it, read every line, then decide.
2. **"Reflog" in the Recover column means a local reflog.** A fresh clone and a CI runner have none (Chapter 13, section 13.16), tags and remote-tracking refs have none by default (Chapter 7, section 7.11), and the lab configuration switches reflog expiry off while real repositories expire entries after 90 days, or 30 days when unreachable (Chapter 13, section 13.4).
3. **Content that was never staged and never committed is in no object.** No reflog and no `git fsck` returns it (Chapter 13, section 13.12). That is the common reason for a 🔴 label.

Earlier drafts of the chapters labelled a few commands in two ways. One label per command has since been chosen, and section 12 records every decision and its reason.

## 2. Working tree and index

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git restore <path>`, `git restore -p <path>`, `git checkout -- <path>` | 🔴 | Working tree files, from the index | Every unstaged change in the named paths, without confirmation | `git diff -- <path>` | None for content that was never staged; `git fsck` for content that was | After you have read the diff and decided the changes are worthless; `-p` to discard hunk by hunk | 4.7, 11.3 |
| `git restore --source=<commit> [--staged] [--worktree] <path>` | 🔴 | Files (and index entries) from a commit; deletes tracked paths the commit lacks | Unstaged edits in those paths | `git status --short -- <path>`; `git diff <commit> -- <path>` | None for unstaged edits | Bringing back a deleted file, where no file of that name exists; name the paths you mean | 4.7, 11.3, 14A.13 |
| `git restore <path>` on a file with the assume-unchanged bit | 🔴 | Overwrites the hidden edit without warning | The edit the bit was hiding | Clear the bit, then `git diff` | None | Never as a way to keep local edits: the bits are not an ignore mechanism | 5.12 |
| `git restore <notebook>`, `git switch` across a notebook change, with a clean filter that strips outputs | 🔴 for local outputs | Rewrites the file from the stripped blob | Notebook outputs, which were never in Git | `git status`; copy the file first | None; rerun the notebook | When the working copy holds nothing that exists only there | 28.18 |
| `git clean -f [-d] [-X or -x]` | 🔴 | Deletes untracked files; with `-d` untracked directories; with `-x` or `-X` ignored files | Files Git has no copy of: `.env`, downloaded datasets, model checkpoints, virtual environments | The same options with `-n` in place of `-f` | None through Git | To prove a build from a pristine tree or reset a CI workspace; prefer `-X` to `-x`, pass a pathspec, protect files with `-e` | 4.14, 11.10 |
| `git switch --discard-changes`, `git checkout -f` | 🔴 | Index and working tree, to the target | Uncommitted edits in the files it touches | `git status`, `git diff` | None for content that was never staged | Only when you have decided to throw the edits away | 7.15 |
| `git switch <branch>` when an ignored file is tracked on that branch | 🔴 | Overwrites the ignored file | The ignored file's content | `git ls-tree -r --name-only <branch>` compared with `git status --ignored` | None; prevent with `--no-overwrite-ignore` | Not a choice: know the case before switching | 4.17 |
| `git rm -f <path>` | 🔴 | As `git rm`, without the check | Uncommitted changes in the file | `git diff HEAD -- <path>` | None for unstaged content | Only after reading that diff | 4.8 |
| `git rm <path>` | 🟡 | Deletes the file and its index entry; refuses if the content is not in HEAD | Nothing: the content is in HEAD | `git rm -n <path>` | `git restore --staged --worktree <path>` | Removing a tracked file from the project | 4.8 |
| `git rm --cached <path>` | 🟡 | Removes the index entry; the file on disk stays | The next commit deletes the path for everyone who pulls | `git rm --cached -n <path>`; `git status` | `git restore --staged <path>` before committing | A file that was tracked by mistake; announce the commit with the restore command | 4.6, 5.9, 21B.10, 28.9 |
| `git restore --staged <path>`, `git reset [--] <path>` | 🟡 | Index entries, copied from HEAD | The name of a staged version that differed from the file | `git diff --cached -- <path>` | `git add <path>`; `git fsck --lost-found` for a staged version that differed from the file | Unstaging | 5.9, 11.3 |
| `git update-index --add --cacheinfo <mode>,<id>,<path>` | 🟡 | One index entry | Nothing | `git ls-files --stage` | `git restore --staged <path>` | Building a commit by hand to learn the plumbing | 2.6 |
| `git update-index --assume-unchanged`, `--skip-worktree` | 🟡 | A flag bit that hides later edits from `git status` | Nothing at once; sets up the 🔴 row above | `git ls-files -v` | The `--no-` forms | Not as an ignore mechanism | 5.12 |
| `git add --renormalize .` | 🟡 | Stages every tracked file whose stored form changes under the current attributes and filters | Nothing | `git ls-files --eol`; `git status` before committing | `git restore --staged .` before committing | One renormalizing commit when attributes or filters change | 14C.5, 20B.18, 28.18 |
| `git apply <patch>` | 🟡 | Working tree files (and the index with `--index`) | Nothing that the reverse patch does not restore | `git apply --check`, `git apply --stat` | `git apply -R` | Applying a diff that is not a commit | 14D.11, 28.18 |
| `rm .git/index.lock` | 🟡 | Removes a lock; unsafe while a Git process is writing | A write in progress | `pgrep -fl git` | None needed for a stale lock | Only when no Git process is running | 5.15 |
| `rm .git/index`, then `git reset` | 🔴 | Discards staging state, flag bits and conflict stages; outside Git's locking | What was staged and not committed loses its index entry | `git diff --cached`; move the file aside instead of deleting it | `git fsck` for blobs that were staged; move the file back | "index file corrupt", "index file smaller than expected" | 5.15, 13.18 |

## 3. Stash

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git stash push [-u]` | 🟡 | Records index and working tree as commits that only `refs/stash` reaches, then resets both to HEAD; with `-u` also removes untracked files | Nothing while the entry exists | `git status -s` | `git stash pop --index` | Parking work for minutes; a branch is better for work that must survive | 11.11, 14C.2 |
| `git stash apply`, `git stash pop`, `git stash branch <name>` | 🟡 | Merges an entry into the files; can conflict | Nothing: the entry is kept after a conflict | `git stash show -p` | `git reset --merge` backs out; then `git stash branch <name>` | Pop soon; clear local edits before popping | 11.11 |
| `git stash drop`, `git stash clear` | 🔴 | Deletes one line, or all lines, of the log of `refs/stash` | The stashed changes, once the unreachable commits are pruned | `git stash show -p 'stash@{n}'` | `git stash store <id>` while the objects exist; without the ID, the `git fsck --unreachable` recipe of Lab 8.6 | `drop` after `git stash show -p`; `clear` is almost never appropriate | 11.11, 14C.15 |

## 4. Commits, branches and refs

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git commit --amend` (with or without `--no-edit`, `--only`, `--reset-author`) | 🟡 | Replaces the tip commit with a new one that has a new ID | Nothing locally; a published commit that others have is not replaced for them | `git diff --cached`, `git log -1` | `git reset --soft 'HEAD@{1}'` | Unpublished commits only | 6.7, 11.7 |
| `git commit --no-verify` | 🟡 | As `git commit`, without the `pre-commit` and `commit-msg` hooks | Nothing; the checks did not run | Run the hook's checks by hand | Amend, or a further commit; the server may still refuse | When a hook is wrong and you have run its checks yourself | 6.15, 14C.11, 28.18 |
| `git branch -m <name>` | 🟡 | Renames the ref, its reflog and its configuration section | Nothing | `git branch -vv` | Rename it back | Before the first push | 7.5 |
| `git branch -f <name> <commit>`, `git switch -C` | 🟡 | Moves a ref; the old value stays in the reflog | Nothing while the reflog entry lives | `git branch -vv`, `git rev-parse <ref>` | `git branch -f <ref> <ref>@{1}` | Putting a branch where you have decided it belongs | 7.5 |
| `git branch -d <name>` | 🟡 | Deletes the ref and its reflog after a merge check against the upstream or HEAD | The branch reflog | `git branch --merged`, `git branch -vv` | `git branch <name> <id>` from the `was <id>` output or from `git reflog` | Merged branches | 7.5, 27.21 |
| `git branch -D <name>` | 🔴 | Deletes the ref and its reflog with no merge check | The only name of unmerged commits | `git log --oneline main..<branch>`; `git diff main <branch>` | `git branch <name> <id>` while the objects exist; the HEAD reflog if the commits were checked out | After the diff against the target is empty (a squash-merged branch) | 7.5, 13.8, 17.9, 30.23 |
| `git tag -f <name>`, `git tag -d <name>` | 🟡 | Moves or deletes a local tag; tags have no reflog by default | The only record of where the tag pointed | `git rev-parse <tag>`, and write the ID down | `git tag <name> <old-id>` from the `was <id>` output; `git fsck` lists a dangling tag object | Unpublished tags | 7.11, 14B.21 |
| `git update-ref <ref> <new> [<old>]` | 🟡 | One ref and its reflog, and nothing else: not the index, not the working tree | Nothing while the reflog entry lives | `git rev-parse <ref>`; pass `<old>` so that a surprise stops the command | `git update-ref <ref> "<ref>@{1}"` | Scripts; full names that begin with `refs/` | 2.6, 3.17, 7.2 |
| `git update-ref -d <ref>` | 🔴 | Deletes the ref and its reflog, even for the current branch | The only name that leads to those commits | `git rev-parse <ref>`; write the ID down | `git update-ref <ref> <id>`; without the ID, `git fsck --no-reflogs` lists the commits as dangling while they exist | Scripts that remove refs they created themselves | 2.14 |
| `git symbolic-ref HEAD <ref>` | 🟡 | Which branch is current, without touching the index or the working tree | Nothing | `git symbolic-ref HEAD` | `git symbolic-ref HEAD <previous>`; `git reflog` | Repairs and demonstrations; porcelain otherwise | 3.17, 7.3 |
| Writing a file under `.git/refs/` by hand | 🔴 | A ref without validation, locking or reflog | A typo produces a broken ref that `git log --all` refuses to read | Use `git update-ref` instead | `git update-ref` after deleting the broken file (Lab 4.1) | Never | 7.15 |
| `rm` of a file under `.git/refs` | 🔴 | Removes a ref outside Git's locking | The ref's value | Move the file aside instead of deleting it | Move it back | An empty or unreadable ref file that `git update-ref -d` cannot delete | 13.11, 13.18 |
| Deleting or editing files under `.git/objects` | 🔴 | The object database | One object can be part of every snapshot in the history | None | Write the same content back, or copy the object from another clone (Lab 1.2) | Never | 2.14 |
| `rm -rf .git` | 🔴 | Deletes the repository and leaves the working tree files | Every commit that was never pushed, every local branch, stash and reflog | `git log --oneline --all`, `git branch -vv` | None through Git; another clone or a disk backup | A repository created by mistake that holds no commit you need | 1.14 |

## 5. Reset

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git reset --soft <commit>` | 🟡 | The branch ref | Nothing | `git log --oneline <commit>..HEAD` | The same mode with `ORIG_HEAD`, or the reflog | Regrouping private commits; `git reset --soft @{u}` after a rejected push of an amend | 11.4, 21B.23 |
| `git reset [--mixed] <commit>` | 🟡 | The branch ref and the index | Nothing in files; staged versions lose their index entry | As above, and `git diff --cached` | As above | While the commits are private | 11.4 |
| `git reset --keep <commit>` | 🟡 | The branch ref, the index, files that differ between the two commits; refuses when it would overwrite a local change | Nothing | `git log --oneline <commit>..HEAD` | `ORIG_HEAD`, the branch reflog | The reset to use during recovery, in place of `--hard` | 11.6, 13.7, 30.23 |
| `git reset --merge [<commit>]` | 🔴 | As `--keep` for unstaged changes; discards staged changes | Staged changes | `git diff --cached` | Commits: reflog. Staged content: `git fsck --lost-found` | Backing out of a merge, a pop or a pick that left the index unmerged | 8.21, 11.6 |
| `git reset --hard <commit>`, `git reset --hard ORIG_HEAD` | 🔴 | The branch ref, the index, and every tracked file that differs from the target | Every uncommitted change to tracked files, and untracked files that are in the target's way | `git status -s`, `git diff HEAD --stat`, `git log --oneline <commit>..HEAD` | Commits: reflog. Staged content: `git fsck --lost-found`. Unstaged: none | When the working tree is known to be disposable; `git stash push -u` first when unsure; `ORIG_HEAD` only as the very next command | 9.16, 11.5, 13.7 |

## 6. Merge, rebase, cherry-pick, revert, bisect

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git merge <other>` (fast-forward or true merge), `--no-ff`, `--ff-only` | 🟡 | Moves the current branch; rewrites index and working tree | Nothing permanently | `git merge-tree --write-tree --name-only HEAD <other>`; `git diff HEAD...<other>`; `git log HEAD..<other>` | Before pushing: `git reset --merge ORIG_HEAD` or `git reset --keep ORIG_HEAD` (check it first, or take the commit from the reflog). After pushing: `git revert -m 1` | From a clean tree | 8.3, 8.4, 8.12, 27.21 |
| `git merge -X ours`, `-X theirs`, `-X ignore-space-change` | 🟡 | As above, and silently drops one side of every conflicting hunk | The dropped side's changes, in the result | Merge without the option first | As above; audit with `--remerge-diff` | Only when one side's hunks are the decision | 8.6 |
| `git merge -s ours <other>` | 🟡 | Records `<other>` as merged and takes none of its content | Nothing in objects; the branch counts as merged while its changes are missing | `git diff HEAD...<other>` shows what is discarded | As for `git merge` | Deliberately superseding a branch | 8.6 |
| `git merge --squash <other>`, `git merge --no-ff --no-commit <other>` | 🟡 | Index and working tree; no commit | Nothing | As for `git merge` | `git reset --merge` | Reviewing or editing the result before committing | 8.12 |
| `git merge --continue`, `git commit` during a merge | 🟡 | Creates the merge commit and moves the branch | Nothing | `git diff --cached --check`; run the tests | `git reset --merge ORIG_HEAD` before pushing | After every conflict is resolved and checked | 8.10 |
| `git merge --quit` | 🟡 | Deletes the merge state only | Nothing in files; no command resumes the merge | `git status` | `git reset --merge` | Rarely | 8.10 |
| `git merge --abort`, `git reset --merge` | 🔴 | Resets index and working tree to HEAD; deletes the merge state | Every resolution made so far, and any uncommitted edit that was staged during the merge | `git status`, `git diff --cached --stat` | Staged content survives as unreferenced objects that `git fsck` lists (Lab 6.7); unstaged resolution edits are gone | The merge was a mistake or needs a different approach | 8.10, 8.21 |
| `git restore --ours\|--theirs\|--merge <path>`, and the `git checkout` forms | 🔴 | Overwrites the working tree file with one side, or with a fresh marker version | Your hand edits to that file, which exist nowhere else until you `git add` them | `git diff --ours`, `git diff --theirs`, `git diff <path>` | `git restore --merge <path>` brings back the starting point, not your edits | The whole file from one side is the decision; a resolution, yours or rerere's, is wrong | 8.10, 8.21, 14C.15 |
| `git rebase <upstream>`, `--onto`, `-i`, `--autosquash`, `--keep-base`, `--rebase-merges` | 🟡 | New commits; the branch ref, at the end | Nothing permanently | `git log --oneline <upstream>..HEAD` lists what will be replayed | `git reset --hard <branch>@{1}`, or `git reset --keep ORIG_HEAD`; a backup ref | Your own unpublished commits; ask before rebasing a branch others push to | 9.2, 9.5, 9.6 |
| `git rebase --update-refs` | 🟡 | Also every local branch inside the range | Nothing permanently | With `-i`, the `update-ref` lines | Each branch from its own reflog | Stacked branches | 9.9 |
| `git rebase --root` | 🟡 | Every commit of the branch | Nothing locally | `git log --oneline` | Reflog; for a published repository there is no clean recovery | Unpublished repositories | 9.23 |
| `git rebase --continue` | 🟡 | Commits the index as the copy, runs on | Nothing | `git status`, `git diff --cached` | Reflog, after the rebase | After `git add` of the resolution; never `--amend` at a conflict stop | 9.11 |
| `git rebase --skip` | 🟡 | Omits the stopped commit | Nothing: the original is in the old history | `git rebase --show-current-patch` | Redo | A commit that is already upstream | 9.11 |
| `git rebase --abort` | 🟡 | Index and working tree back to the old tip | Resolution work in progress; commits made inside the rebase leave the branch | `git status`, `git diff`, `git log <branch>..HEAD` | Commits: the HEAD reflog or a rescue ref. Uncommitted edits: none | After anchoring new commits with a branch | 9.11, 29.3 |
| `git rebase --quit` | 🟡 | Removes the state directory; HEAD stays detached | Nothing | `git status` | `git switch <branch>` | Rarely; leave with `--abort` | 9.11 |
| `git pull --rebase` | 🟡 | Fetches; re-creates your unpushed commits on the fetched upstream | Nothing permanently; after someone's forced push it can drop commits | `git fetch`, then `git log --oneline @{u}..HEAD` | `git reset --hard <branch>@{1}` | Unpushed local commits; look before integrating after a forced update | 9.13, 12.6 |
| `git pull --ff-only`, `git pull --no-rebase` | 🟡 | Fetch, then moves the branch forward or creates a merge commit; working tree | Nothing permanently | `git fetch`; `git log ..@{u}`; `git log --oneline --graph HEAD @{u}` | `git reset --hard ORIG_HEAD` (itself 🔴); the reflog | Not in automation: a job that pulls can create merge commits nobody reviewed | 12.6, 12.16 |
| `git cherry-pick <commit>`, with or without `-x`, `-e`, `-m` | 🟡 | Adds commits to the current branch; updates index and working tree; refuses to overwrite local changes | Nothing | `git show <commit>`; `git merge-tree --write-tree --merge-base=<commit>^ HEAD <commit>`; `git cherry -v` | `git reset --keep ORIG_HEAD` or the branch reflog; `git revert` if already pushed | Backports (`-x` always), and recovery of single commits | 10.2, 10.4, 13.7 |
| `git cherry-pick -n <commit>` | 🟡 | Index and working tree; no commit, no in-progress state | Nothing | `git show <commit>` | `git restore --staged --worktree <paths>` | Combining several changes into one commit | 10.4 |
| `git cherry-pick --skip`, `--abort`, `--quit` | 🟡 | `--skip` discards the stopped pick; `--abort` returns branch, index and working tree to the state before the sequence; `--quit` removes the sequencer state only | Resolution work in progress | `git status` | Completed copies are in the reflog; resolution work is gone | An interrupted sequence | 10.6 |
| `git revert <commit>`, `git revert -m 1 <merge>` | 🟡 | Adds one commit that applies the inverse change | Nothing now; after `-m 1` a later merge of the same branch is silently empty | `git show <commit>`; `git show --stat <merge>` | Revert the revert; before pushing, `git reset --keep HEAD~1` | The undo for published history; `-m 1` only when the merged branch will never be merged again as it is, or with the re-merge procedure in the message | 10.11, 11.8, 11.9, 30.23 |
| `git revert -n <commit>` | 🟡 | Index and files | Nothing | `git show <commit>` | `git revert --abort` | Several reverts in one commit | 11.16 |
| `git merge --abort`, `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort`, `git bisect reset` as "leave" commands | 🟡 (merge: 🔴, above) | End the operation; reset index and working tree to the starting commit | Uncommitted edits made during the operation | `git status`, `git diff`, `git log <branch>..HEAD` | Commits: the HEAD reflog or a rescue ref. Uncommitted edits: none | After the PRESERVE step of the troubleshooting method | 29.6, 29.14 |
| `git bisect start`, `good`, `bad`, `skip`, `run`, `replay` | 🟡 | Detaches HEAD and checks out other commits; writes `refs/bisect/*` and `BISECT_*` | Nothing | `git status` must be clean; `git rev-list --count <good>..<bad>` | `git bisect reset` | Finding the commit that changed a property | 14A.20 |
| `git bisect reset` | 🟡 | Checks out the starting branch; deletes the bisect state | The session, unless you saved it | `git bisect log > file` to keep the session | `git bisect replay file` | At the end of a session | 14A.22 |
| `git history reword`, `fixup`, `split` (experimental; `reword` and `split` since Git 2.54, `fixup` since 2.55) | 🟡 | New commits; every descendant local branch moves | Nothing locally | `--dry-run`; `git branch -r --contains <commit>` first | Each branch's reflog | Local cleanup only | 14D.6 |
| `git replay --onto`, `--advance`, `--revert` (experimental; since Git 2.44, updates refs itself since 2.53, `--revert` since 2.54) | 🟡 | New commits; refs move in one transaction | Nothing where a reflog exists | `--ref-action=print` | Reflog, where one exists; none by default in a bare repository | Rebase and cherry-pick without a working tree | 14D.7 |
| `git am` | 🟡 | New commits on the current branch | Nothing | `git apply --check` | `git am --abort` while it is stopped; afterwards the reflog of the branch | The patch-based workflow | 14D.11 |

## 7. Remotes, pushes and tags

> **Git, not GitHub.** The rows in this section describe what Git does against any server. On GitHub, rulesets and branch protection can reject a push that Git would perform (Chapter 18), and a default bare Git server keeps no reflog (Chapter 12, section 12.8).

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git push`, `git push -u`, `git push --follow-tags` | 🟡 | Refs on the server (fast-forward or new), your remote-tracking refs; starts whatever listens for pushes | Nothing; published commits are not taken back quietly once others have fetched | `git push --dry-run`; `git log @{u}..` | A revert commit and another push; moving the ref back needs a force | After reading `<source> -> <destination>` in the dry run | 1.12, 12.7 |
| `git push origin <tag>`, `git push --tags` | 🟡 | Creates tags on the server; on GitHub starts every workflow with a matching tag filter | Nothing in Git; a published name cannot be taken back cleanly | `git push --dry-run`; `git ls-remote --tags origin` | None that is clean: others may have fetched; deleting the tag does not unpublish what a workflow built | Push single tags or `--follow-tags`, not `--tags` | 14B.10, 20A.18 |
| `git push <remote> --delete <ref>`, `git push <remote> :<ref>` | 🔴 | Deletes a ref on the server, and your remote-tracking ref | The only name the branch's commits have there; a bare server keeps no record of the deletion | `git ls-remote <remote>`; `git log --oneline origin/<branch> --not origin/main` | From any clone that has the commit: `git push <remote> <id>:refs/heads/<name>` | Branches that are merged, or abandoned by agreement | 12.7, 27.21 |
| `git push --force`, `git push -f`, `git push <remote> +<ref>` | 🔴 | Sets the server's ref with no check, and your remote-tracking ref | Every commit on the server's branch that is not in your history, including commits you have never seen | `git fetch`, then `git log --oneline HEAD..origin/<branch>`; `git push --dry-run --force` | The old tip from any clone that had it (a teammate's branch, the reflog of anybody's remote-tracking ref), or the server's unreachable object until it is collected; push it back | None for the plain form: use a guarded form. Not in an incident | 9.17, 12.8, 30.23 |
| `git push --force-with-lease` alone | 🔴 | The server's ref, if it equals your remote-tracking ref; the check passes wrongly after a background fetch | As `--force`, when the remote-tracking ref was updated without your looking | `--dry-run`; `git log HEAD..origin/<branch>` | Only from a clone that has the commits | None: add `--force-if-includes` or an explicit value | 9.17, 9.23 |
| `git push --force-with-lease --force-if-includes`, `git push --force-with-lease=<ref>:<expect>` | 🔴 | The server's ref, only if it still has the value you rebased from or named | Commits on the server that only the server and stale clones have; with these forms everything removed is something your clone has | `--dry-run`; `git log <local>..<expect>` lists what will leave the branch | The old tip is in your own reflogs; a clone's reflog of `origin/<ref>`; on GitHub the Activity view (Chapter 13, section 13.15) | A branch that only you use, such as your own pull request branch after a rebase; restoring a known good value in an incident; tell teammates before the push | 9.17, 12.8, 27.3, 30.23 |
| `git push --mirror`, `git push --prune`, `git push --force --mirror origin` | 🔴 | Creates, forces and deletes server refs to match yours; from an ordinary clone `--mirror` would also publish your remote-tracking refs | Branches and tags that exist only on the remote | `git push --dry-run --force --mirror origin` | From other clones, ref by ref; on GitHub, the instruments of Chapter 13 | Once, after a freeze, at the end of a verified rewrite, from a `--mirror` clone | 12.16, 21B.17 |
| `git push --force origin <tag>` | 🔴 | Replaces a published tag | The meaning of a release name for everyone who fetches later; a workflow that names the tag runs different code | `git ls-remote --tags origin` | Force the old tag object back from a clone that has it | Putting a tag back at its published position; a name that is meant to move should be a branch | 14B.11, 21A.7 |
| `git push origin --delete <tag>` | 🔴 | Deletes a published tag | The only published name of a release commit, and the tag under a GitHub release | `git ls-remote --tags origin` | Push it again from a clone that kept it | A tag pushed by mistake minutes ago, announced | 14B.10 |
| `git fetch --prune`, `git remote prune <remote>` | 🟡 | Deletes stale remote-tracking refs and their reflogs | The reflog that recorded the server's earlier values | `git remote prune --dry-run <remote>` | `git fsck --lost-found`, then `git branch <name> <id>`, before garbage collection | Routine; not while a lost remote state still has no name | 7.13, 12.11, 13.18 |
| `git fetch --tags --force` | 🟡 | Replaces local tags with the server's | Your local value of a moved tag | `git ls-remote --tags`; `git fetch --tags --dry-run`; note `git rev-parse <tag>` first | Re-create from that ID; the old tag objects stay, dangling, until pruned | After confirming the server is right | 12.4, 14B.11 |
| `git fetch --prune --prune-tags` | 🔴 | Deletes every local tag the remote lacks | Private lightweight tags, which have no reflog and no object to find them by | Add `--dry-run` | Annotated tags: `git fsck`; lightweight: only the IDs in the command's output | A mirror or a CI cache that must equal the server | 14B.10 |
| `git remote set-url`, `set-head`, `set-branches`, `rename`; `git branch -u`; `git config set push.default` | 🟡 | Where later fetches, pulls and pushes go | Nothing | `git remote -v`; `git config list --local` | Set the previous value | Deliberate changes of topology | 12.2, 12.5, 12.10 |
| `git remote remove <name>` | 🟡 | The remote, its remote-tracking refs and reflogs, upstream settings | The reflogs of the remote-tracking refs | `git branch -r`, `git branch -vv` | Add and fetch again; the reflogs are lost | A remote you no longer use | 12.10 |

## 8. Reflogs, the object database and maintenance

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git gc`, `git maintenance run --task=gc` | 🟡 | Packs objects and refs; expires reflog entries by the configured periods; deletes unreachable objects older than two weeks | What was past the retention periods | `git fsck --unreachable`; `git reflog expire --dry-run --all`; `git count-objects -v`; `git prune -n` | Within the periods nothing is lost; beyond them, another clone or a backup | Rarely by hand: maintenance is automatic (geometric strategy by default since Git 2.54) | 3.17, 13.13, 26.3 |
| `git maintenance run` | 🟡 | Packs, `packed-refs`, commit-graph, multi-pack-index; expires reflog entries by the configured periods | Expired reflog entries | `git maintenance is-needed` (Git 2.53 or later); `GIT_TRACE=1` | None for expired reflog entries | Hundreds of packs or thousands of loose objects | 26.3 |
| `git maintenance start`, `git maintenance register` | 🟡 | Global configuration and the system scheduler | Nothing | `git help maintenance` | `git maintenance stop`, `git maintenance unregister` | A deliberate choice on your own machine; never in the labs | 26.3 |
| `git gc --prune=now`, `git prune` | 🔴 | Deletes unreachable objects at once, with no grace period | Everything that only the grace period was keeping: dropped stashes, staged blobs, commits whose reflog entries are gone | `git fsck --unreachable`; `git prune -n` | None in this repository; another clone or a backup | The purge after a deliberate history rewrite, with no other process using the repository | 3.17, 13.13, 26.5 |
| `git repack -a -d` | 🔴 | Rewrites packs; drops the unreachable objects of the packs it replaces | Unreachable objects in those packs | `git fsck --unreachable`; `git count-objects -v` | Another clone or a backup only | After a deliberate history rewrite in a repository you have copied first | 3.17 |
| `git repack --geometric=2 -d` | 🟡 | Rewrites packs | Nothing reachable | `git count-objects -v` | Not needed for reachable objects | What automatic maintenance does for you | 26.4 |
| `git reflog expire`, `git reflog delete <ref>@{<n>}`, `git reflog drop <ref>` (`drop`: Git 2.50 or later) | 🔴 | Remove reflog entries | The record of where a ref used to point | `--dry-run --verbose` | `git fsck`, until a prune | Almost never by hand | 13.4, 13.18 |
| `git reflog expire --expire=now --all`, usually followed by `git gc --prune=now` | 🔴 | Empties every reflog, the stash list included; then deletes every unreachable object | Every recovery path in that clone: every commit, stash and staged blob that only a reflog, or nothing at all, was keeping | `git reflog expire --dry-run --expire=now --all`; `git fsck --unreachable --no-reflogs` lists what would go | None locally | The final step of a secret clean-up, in a cleanup clone, after rotation; in a stale clone after its owner has saved their work | 3.17, 13.13, 21B.17, 30.23 |
| `git refs migrate --ref-format=<format>` (Git 2.46 or later) | 🟡 | The ref storage format; values are kept | Nothing | `--dry-run` | Migrate back, or restore the copy of `.git` you made first | A clone that hits a case-insensitive ref conflict; throwaway repositories | 3.13, 14D.5 |
| `git filter-repo ...`, `git filter-branch ...` | 🔴 | Every affected commit and all descendants, on every rewritten ref | Signatures; with a wrong path argument, files you meant to keep | git-filter-repo `--dry-run`; run in a fresh clone | The untouched server and other clones, until you push | Data that stays harmful after rotation; for an unpushed mistake on a private branch a rebase is the smaller tool | 21B.17 |

## 9. Configuration, hooks and recorded resolutions

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git config set`, `unset`, `edit` (Git 2.46 or later), in any scope | 🟡 | One configuration file, which has no history | The previous value | `git config get --show-origin <key>`; `git config list --show-origin --show-scope` | Set the old value again; keep the global file under version control | Deliberate settings; the scope that should own the key | 14B.3 |
| `git config set --global init.default*`, `git config set --global safe.bareRepository explicit` | 🟡 | The behavior of later commands: new repositories; Git commands inside bare repositories then need `--git-dir` or `GIT_DIR` | Nothing | `git config list --show-origin` | Unset the keys | `init.defaultBranch` and `safe.bareRepository` now; the object and ref formats per repository, not globally | 14D.4, 21B.23 |
| `git config set --global --append safe.directory <dir>` | 🟡 | Makes Git trust that directory's configuration and hooks | Nothing; removes a protection | Read `<dir>/.git/config` and `<dir>/.git/hooks` first | `git config unset --global --value=<dir> safe.directory` | A directory whose contents you have read | 21B.23 |
| `git config set core.hooksPath`, `hook.<name>.*`, `filter.*`, `diff.*`, `merge.*` | 🟡 | Which programs Git runs on your machine | Nothing | `git hook list --show-scope <event>`; `git config list --show-origin` | Unset the keys | Programs you have read | 14C.11, 14C.12, 28.18 |
| `git hook run <event>`; `--no-verify` | 🟡 | Runs the local checks; skips them | Nothing | `git hook list <event>` | The server may still refuse | Testing a hook; a hook that is wrong | 14C.11 |
| `git rerere forget <path>`, `git rerere clear`, `git rerere gc` | 🟡 | Deletes recorded resolutions | The recorded resolution | `git rerere diff`; `ls .git/rr-cache` | Resolve again | A recorded resolution that is wrong | 14C.3 |
| `git lfs install` without `--local` | 🟡 | The filter keys go into your global configuration; hooks in the current repository | Nothing | `git config list --show-origin` | `git lfs uninstall` | In this book it is always run with `--local` (🟢) | 22.3 |

## 10. Submodules, subtrees, LFS, sparse-checkout, worktrees

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `git submodule update` (default checkout) | 🟡 | Moves the submodule's HEAD (detached) and its files; refuses to overwrite local edits to files it must change | Nothing; commits made on the detached HEAD lose their name | `git submodule status`; `git -C <path> status` | The submodule's reflog: `git -C <path> reflog`; `git -C <path> branch <name> <id>` | After every pull that moved a gitlink | 23.3, 23.5 |
| `git submodule update --remote` | 🟡 | As above, to the tip of the remote-tracking branch; the superproject then shows a modified gitlink | Nothing | `git -C <path> fetch && git -C <path> log --oneline HEAD..origin/HEAD` | `git submodule update` returns to the recorded commit | Moving the pointer on purpose, in a dedicated branch | 23.6 |
| `git submodule update --force`, `git submodule deinit --force` | 🔴 | Overwrites modified tracked files in the submodule | Uncommitted changes inside the submodule | `git submodule foreach 'git status --short'` | None for uncommitted edits | To get back to exactly the recorded state | 23.9, 23.16 |
| `git submodule deinit <path>` | 🟡 | Empties the working directory; removes the section from `.git/config`; refuses if there are local modifications unless `--force` | Nothing | `git -C <path> status` | `git submodule update --init` | A submodule you do not need locally | 23.11 |
| `git rm <submodule path>` | 🟡 | Removes the gitlink, the `.gitmodules` section and the working directory | Nothing | `git status` | `git restore --staged --worktree .gitmodules <path>`, then `git submodule update --init` | Removing the submodule from the project | 23.11 |
| Deleting `.git/modules/<name>` | 🔴 | Deletes a repository | Commits in the submodule that were never pushed | `git -C <path> status`; `git -C <path> reflog` | None | Removing a submodule completely from your clone, after checking for unpushed commits | 23.11, 23.16 |
| `git push --recurse-submodules=on-demand` | 🟡 | Pushes in the submodules, then the superproject | As for any push | `git submodule foreach 'git status --short --branch'` | As for any push | When the superproject commit needs submodule commits that are not published | 23.8 |
| `git subtree add`, `git subtree pull` | 🟡 | New commits on the current branch (a merge); needs a clean working tree | Nothing | `git ls-remote <repository> <ref>` | `git reset --hard ORIG_HEAD` if not pushed (🔴 for uncommitted work); `git revert -m 1` if pushed | Vendoring a dependency's files into your own history | 23.13 |
| `git subtree push` | 🟡 | Creates or updates a branch in the library's repository | Nothing in yours | `git subtree split` first and inspect the result | Delete or reset that branch in the library's repository | Sending changes back upstream | 23.13 |
| `git lfs push`, and `git push` with the pre-push hook | 🟡 | Uploads LFS objects; on GitHub they are billed and cannot be deleted by you | Nothing | `git lfs push --dry-run <remote> <ref>`; `git lfs status` | None on GitHub short of deleting the repository (22.11) | After deciding what belongs in LFS | 22.6 |
| `git lfs prune` | 🟡 | Deletes local LFS objects that are pushed and not needed | Nothing while the remote has the objects | `--dry-run --verbose`; `--verify-remote` | `git lfs fetch`, if the remote has them | Reclaiming disk space | 22.8 |
| `git lfs migrate import`, `export` (default scope or named branches) | 🟡 | Rewrites unpushed commits; the working tree is left with pointers after import | Nothing locally | `git lfs migrate info` with the same options | Branch reflogs: `git reset --hard <branch>@{1}` | Unpushed commits that contain large files | 22.9 |
| `git lfs migrate import --everything`, then a forced push | 🔴 | Rewrites published history | Nothing locally; breaks every other clone | `git lfs migrate info --everything`; rehearse in a fresh clone | Before the push: reflogs. After: the old history from another clone | A coordinated rewrite | 22.9, 22.13 |
| `git sparse-checkout set`, `add`, `init --cone` (`init` is deprecated: `set` does everything) | 🟡 | Working tree, skip-worktree bits, pattern file, `config.worktree`; deletes ignored files in directories that leave the cone | Ignored files in directories that leave the cone, such as a local `.env` or a downloaded evaluation set | `git status --short --ignored` | `set` again or `disable`; ignored files are gone | After checking for ignored files you cannot regenerate | 24.4, 24.5 |
| `git sparse-checkout reapply`, `disable` | 🟡 | Removes, or writes, tracked files | Nothing tracked | `git ls-files -t` | `set` or `add` | After conflicts outside the cone | 24.4 |
| `git sparse-checkout set --sparse-index` | 🟡 | Rewrites the index in a form some tools cannot read | Nothing | Test the tools first | `--no-sparse-index` | Very large repositories | 24.6 |
| `git sparse-checkout clean -f` (Git 2.52 or later) | 🔴 | Deletes directories outside the cone that hold untracked files | Untracked files there, which were never in Git | `--dry-run`, `--verbose` | None | After reading the preview and moving away what you need | 24.5 |
| `scalar clone` | 🟡 | A clone, and also global configuration, a scheduler unless `--no-maintenance`, a monitor daemon | Nothing | `git help scalar` | `scalar unregister` or `scalar delete`; `git fsmonitor--daemon stop` | A deliberate choice on your own machine | 24.7 |
| `git worktree move` | 🟡 | The directory and both pointers | Nothing | `git worktree list` | Move it back | Reorganising directories | 25.6 |
| `git worktree remove` | 🟡 | Deletes a clean working tree and its entry, including its HEAD reflog | The HEAD reflog of that worktree; the name of detached commits made there | `git -C <path> status --short`; `git -C <path> log --oneline -3` | `git worktree add` again; detached commits via `git fsck --lost-found` | A finished task; create a branch before removing | 25.6 |
| `git worktree remove --force` | 🔴 | As above, and deletes uncommitted and untracked files | Files that were never committed | `git -C <path> status --short --ignored` | None for files that were never committed | Only after looking | 25.6, 25.9 |
| `git worktree prune` | 🟡 | Deletes entries whose working tree is missing, including their HEAD reflogs | Those HEAD reflogs | `git worktree prune --dry-run --verbose` | `git worktree add` again; a moved tree: `git worktree repair` before pruning | After a working tree was deleted with `rm -rf` | 25.6 |
| `git worktree add --force` for a branch that is already checked out | 🔴 | Two indexes on one ref | The consistency of the stale worktree: staged changes nobody made | None; do not use | `git reset --hard` in the stale worktree after saving its work | Never | 25.4, 25.9 |
| `python3 tools/dataref.py checkout` (and `dvc checkout`) | 🔴 for unrecorded data edits | Overwrites data files with the versions the pointers name | Unrecorded edits to data files | `python3 tools/dataref.py verify` | None for unrecorded edits; record them first with `add` | After `verify` reports "ok" | 28.18 |

## 11. GitHub: the GitHub CLI, authentication, rules and Actions

> **GitHub, not Git.** Every 🔴 command here changes GitHub objects that no clone contains (Chapter 15, section 15.22). The preview is always a read with the same tool. Flags were checked with `gh <command> --help` of version 2.88.1; nothing was run against GitHub. The full command tables are in the [GitHub CLI cheat sheet](../cheatsheets/github-cli-cheat-sheet.md).

| Command | Label | What it changes | What it can destroy | Preview | Recover | When appropriate | Section |
|---|---|---|---|---|---|---|---|
| `gh repo create --source=. --push` | 🟡 | A repository on GitHub, a remote, a push | Nothing; what reached a public repository is published | `git log`, `git status`; check `--public` or `--private` | `gh repo delete` | After reading what the push will publish | 15.22 |
| `gh issue create`, `gh pr create`, `gh label create`, `gh release create --verify-tag --draft` | 🟡 | GitHub objects that notify people; `gh pr create` may push the branch | Nothing; notifications are not recalled | `gh pr create --dry-run`; `--draft` | Close or delete; `gh pr close` | Ordinary collaboration | 15.22, 17.21 |
| `gh repo edit` (features, merge methods), `gh repo fork`, `gh repo sync` | 🟡 | Settings; a new repository; a fast-forward | Nothing | `gh repo view --json`; `git log HEAD..upstream/main` | Set the previous value; delete the fork | Deliberate changes | 15.22 |
| `gh repo sync --force` | 🔴 | Hard reset of the destination branch | Commits on the destination branch that the source lacks | `git log upstream/main..origin/main` after a fetch; `git rev-list --left-right --count upstream/main...origin/main` | Push the old commits back from a clone that still has them | A fork branch that holds nothing of its own | 15.7, 17.21, 27.21 |
| `gh api` with `POST`, `PATCH`, `PUT`, `DELETE` | 🔴 | Whatever the endpoint says, with all your permissions | Depends on the endpoint | The `GET` first | Depends on the endpoint; often none | After the `GET`, with the saved JSON at hand | 15.22 |
| `gh release create TAG` without `--verify-tag` | 🔴 | May create a tag on the default branch and start tag workflows | Nothing existing; publishes a version name | `git ls-remote --tags origin TAG` | Delete release and tag; consumers may have fetched it | Use `--verify-tag` | 15.22 |
| `gh release delete --cleanup-tag`, `git push origin --delete TAG` | 🔴 | A published version's name | The release and its tag | `gh release view TAG` | Re-create from the recorded commit ID | A release published by mistake | 15.22 |
| `gh repo edit --visibility`, `gh repo delete`, `gh repo rename`, `gh repo archive` | 🔴 | Visibility with its side effects; the repository, its URL, its writability | The side effects of a visibility change cannot be undone | Section 15.5; ask who depends on the URL | Visibility can be changed back, its side effects cannot; restore within 90 days unless the fork network is not empty | Planned, announced changes | 15.5, 15.22 |
| `gh pr update-branch`, `gh pr edit --base`, `gh pr merge` | 🟡 | Move the head branch, change the base, or write to the base branch; can dismiss approvals | Nothing | `gh pr view`, `gh pr checks --required` | Change the base back; `gh pr revert` | The normal end of a reviewed pull request | 17.21 |
| `gh pr merge --admin`, a bypass merge | 🔴 | Writes to a protected branch without the required reviews or checks | Nothing in Git; the control | `gh pr checks --required` | `gh pr revert`; record why | A planned migration or a declared emergency, by a named person, with the reason written down where the audit will find it | 17.16, 18.21 |
| `gh api --method POST repos/ORG/REPO/rulesets --input file.json` | 🔴 | Creates a ruleset; if Active, it binds everyone at once, you included | Nothing | Create it with `"enforcement": "disabled"`, then `gh ruleset check` | Set `enforcement` to `disabled`, or delete the ruleset | Rules as reviewed JSON | 18.21 |
| `gh api --method PUT .../rulesets/ID` | 🔴 | Replaces settings of a ruleset | The previous settings | `gh api .../rulesets/ID` first and keep the JSON | PUT the saved JSON back | Changing a rule | 18.21 |
| `gh api --method DELETE .../rulesets/ID` | 🔴 | Removes the protection for every ref it targeted, immediately | Nothing directly; it makes force pushes and deletions possible | Save the JSON first | Re-create from the saved JSON; ruleset history exists only on Enterprise | A planned migration or a declared emergency | 18.21 |
| `git push --force` to a shared base branch, or to a branch whose protection was just removed | 🔴 | Removes commits from the remote branch; corrupts open pull requests | Commits others pushed | `git log <branch>..origin/<branch>` and the reverse | Chapter 13; Chapter 30 | Not appropriate | 17.21, 18.21 |
| Editing `CODEOWNERS` in a pull request | 🟡 | Who is requested, and under a rule who can block, from the next merge on | Nothing | The errors endpoint with `ref` | Revert the commit | With review by the current owners | 19.14 |
| Removing the owner of `/.github/` | 🔴 | Lets any writer change reviewers and workflows without owner review | No data; removes a control | Review the diff of the file | Restore the line; audit what merged in between | Never without a replacement owner | 19.14 |
| `gh workflow run <file> --ref <branch>` | 🟡 | Starts a run, which uses minutes and may deploy if the workflow deploys | Nothing in Git | Read the workflow file at that ref: `gh workflow view --yaml` | `gh run cancel <run-id>`; deploy the previous commit | A `workflow_dispatch` workflow you have read | 20A.18, 20B.18 |
| `gh run rerun <run-id>`, `--failed` | 🟡 | Starts a new attempt on the original commit | Nothing | `gh run view RUN_ID --json headSha` and compare with `main` | Cancel the attempt; start a new run from the current commit | A flaky failure, not a stale commit | 20A.18, 20B.18 |
| `gh run cancel` | 🟡 | Stops a run, possibly mid-deployment | The consistency of a half-finished deployment | `gh run view` | Re-run; check the target's state by hand | A run that should not finish | 20B.18 |
| `gh secret set`, `gh variable set` | 🟡 | Overwrites the stored value | The old secret value, which cannot be read back | `gh secret list --env NAME` | Set the previous value again from your secret store | Rotation | 20B.18 |
| `gh api -X PUT .../environments/NAME` | 🔴 | Replaces the environment's protection settings with the body sent | The previous settings | `gh api .../environments/NAME` | Send the previous configuration again | Environment rules as code | 20B.18 |
| `gh cache delete --all` | 🟡 | Removes every cache of the repository | Nothing permanent | `gh cache list` | Caches are rebuilt by the next runs, slowly | A poisoned or oversized cache | 20B.18 |
| `git tag -f -a v1`, then `git push --force origin v1` | 🟡, then 🔴 | Moves a local tag; replaces a published tag that workflows may name | What `uses: ...@v1` meant yesterday | `git rev-parse 'v1^{commit}'`; `git ls-remote --tags origin v1` | Re-create the tag at the old commit; push the old tag object back, if you still have it | The reason to pin actions by full commit ID: see [the action pins](../workflows/ACTION_PINS.md) | 21A.7 |
| Pushing a change under `.github/workflows/` | 🟡 | Git: an ordinary commit. GitHub Actions: the next matching event runs the new file with the repository's token and secrets | Nothing in Git | Review the diff with section 21A.19 | Revert the commit; rotate any secret the changed workflow could read | After review by the owner of `/.github/` | 21A.22 |
| `ssh-keygen -t ed25519 -f NEW` | 🟡 | Creates two files; overwrites an existing key only after asking | An overwritten private key | `ls ~/.ssh` | None for an overwritten private key | A new key under a new file name | 16.23 |
| `ssh-add`, `ssh-add --apple-use-keychain` | 🟡 | The agent's key list; a keychain entry | Nothing | `ssh-add -l` | `ssh-add -d` | Loading the key you mean | 16.23 |
| `ssh-keygen -R HOST` | 🟡 | Removes a host's lines from `known_hosts`, keeping a `.old` copy | Nothing | `ssh-keygen -F HOST` | The `.old` file | After comparing the published fingerprint | 16.11, 16.23 |
| `StrictHostKeyChecking no`, or deleting `known_hosts` wholesale | 🔴 | Removes the host key check | The protection against a wrong host | None | Install the published lines instead | Never; on a CI runner install the published lines | 16.11 |
| `git config set --global credential...`, `gh auth setup-git`, `gh auth login`, `gh auth switch` | 🟡 | Which credential answers, for every repository | Nothing | `git config get --show-origin --all credential.helper` | Set the previous value; `git config unset` | Deliberate changes of identity | 16.23 |
| `git credential reject`, `git credential-osxkeychain erase` | 🟡 | Deletes a stored credential | The stored credential | `git credential fill` shows what is stored | Log in again | A stale or wrong stored credential | 16.23 |
| `gh auth token`, `gh auth status --show-token` | 🔴 | Prints a live token to the terminal and its scrollback | The secrecy of the token | Ask whether you need the value at all | Revoke the token | Rarely; never in a shared or recorded terminal | 16.23 |
| `gh ssh-key delete`, deleting a token or a deploy key in the web interface | 🔴 | Every machine and job that used it stops | Access for those machines and jobs | List where it is used | Create and distribute a new one | Rotation, with the list of users at hand | 16.23 |
| Writing a token into a URL, a file or a command line | 🔴 | Publishes the secret to logs, history and backups | The secrecy of the token | None | Revoke it; cleaning is not enough | Never | 16.23 |

For the response to a leaked secret, the order of the steps matters more than any single command: see the [security cheat sheet](../cheatsheets/security-cheat-sheet.md) and Chapter 21B. For recovery after any 🔴 command, see the [emergency recovery page](../cheatsheets/emergency-recovery-one-page.md) and the [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md).

## 12. Where chapters label the same command differently

Earlier drafts of the chapters labelled fifteen commands in two ways, because each chapter judged the worst case in its own context. The editorial pass of 6 October 2026 chose one label per command from the definitions in section 1, and the chapters, this file, the command reference, the cheat sheets and the playbooks now agree. The table records each decision. Git behavior named in the last column was checked on Git 2.55.0; the `gh` rows were checked against `gh <command> --help` of 2.88.1 and not run against GitHub.

One test settled most rows: a command is 🟢 only if no ref moves and nothing is lost. A command that adds commits to the current branch through the merge machinery moves that branch and rewrites index and working tree, which is the reason `git merge` is 🟡 in 8.21; a command that overwrites a setting loses the previous value, because a configuration file keeps no history.

| Command | Label now | Sections changed (label before) | Reason |
|---|---|---|---|
| `git cherry-pick <commit>`, `git cherry-pick --continue` | 🟡 | 2.10, 2.15, 10.2, 10.14, 27.9, 27.21 (🟢) | It moves the current branch and rewrites index and working tree, as `git merge` does; it adds commits and removes none |
| `git revert <commit>`, `git revert -m 1 <merge>` | 🟡 | 10.11, 10.14, 11.8, 11.16, 27.15, 27.21 (🟢) | As above; and after `-m 1` a later merge of the same branch is silently empty |
| `git merge --abort` | 🔴 | 29.14, the two playbooks, the emergency page (🟡) | It discards every resolution made so far and every edit staged during the merge, and the manual warns that uncommitted changes present when the merge started cannot always be reconstructed. `git rebase --abort`, `git cherry-pick --abort` and `git revert --abort` stay 🟡 in their own rows |
| `git push --force-with-lease --force-if-includes` | 🔴 | 1.8 (🟡, as an example) | Every forced push replaces history on a remote, where you have no reflog (9.17, 12.8). The conditions make it the right form of a 🔴 command, not a 🟡 one |
| `git push --force-with-lease` | 🔴 | 17.21 (🟡) | As above; alone, the check passes wrongly after a background fetch |
| `git update-ref -d <ref>` | 🔴 | 3.17 (🟡) | It deletes the ref together with its reflog, which is the safety net for that ref |
| `git repack -a -d` | 🔴 | 26.18 (🟡) | It drops the unreachable objects of the packs it replaces, at once and without the two-week grace period. `git repack --geometric=2 -d` stays 🟡 |
| `rm .git/index`, then `git reset` | 🔴 | 5.18 (🟡) | It removes the index outside Git's locking and discards the record of what was staged, the flag bits and the conflict stages; no reflog holds them. Moving the file aside first (`mv .git/index .git/index.corrupt`, 13.11) is 🟡, because the file can be moved back |
| `git config set <key>`, `unset`, `edit`, in any scope | 🟡 | 14A.17, 14A.27 (`blame.ignoreRevsFile`, `diff.algorithm`, `blame.markIgnoredLines`), 14D.4 (`init.default*`), 21B.23 (`safe.bareRepository`) (🟢) | It rewrites a file that keeps no history, and it changes the behavior of later commands. This is the label of 1.15 and 14B.21 |
| `git lfs checkout` | 🟢 | 22.7 (🟡) | It replaces unmodified pointer files with their content from the local store and never overwrites a modified file: no ref moves and nothing is lost. `git lfs pull` is `fetch` plus `checkout` and carries the same label (22.14). The row this file had for the command is removed, because 🟢 commands are not listed here |
| `git subtree add` | 🟡 | 23.13 (🟢) | It creates a merge on the current branch |
| `gh pr create` | 🟡 | 17.2, 17.21 (🟢) | It may push the branch, and it creates a GitHub object that notifies people |
| `gh api` with `POST`, `PATCH`, `PUT` or `DELETE`, including the ruleset calls of 18.21 and the environment call of 20B.18 | 🔴 | 18.21 (`POST` and `PUT` on rulesets), 20B.18 (`PUT` on an environment) (🟡) | The call does whatever the endpoint and the body say, with all your permissions (15.22). A `PUT` replaces settings that exist nowhere else unless you saved the JSON first; the `POST` that creates a ruleset destroys nothing and keeps the label of the command, with that stated in its row |

Three labels of the [GitHub CLI cheat sheet](../cheatsheets/github-cli-cheat-sheet.md) that no chapter table carried were confirmed in the same pass:

| Command | Label | Reason |
|---|---|---|
| `gh ssh-key add` | 🟡 | It attaches a credential to your account that can act as you until it is deleted; `gh ssh-key delete` undoes it (16.8) |
| `gh repo set-default <repository>` | 🟡 | It records a setting in the clone that decides which repository later `gh` commands act on; `--view` is 🟢 and `--unset` undoes it (15.16) |
| `gh api graphql` | 🟢 with a `query`, 🔴 with a `mutation` | A GraphQL `query` only reads, although the request is sent as a `POST`; a `mutation` writes, and falls under the rule of 15.22 |

## 13. Chapter files

The section numbers in the tables point into these files.

| Sections | File |
|---|---|
| 1.x | [Chapter 1: Fundamentals](../textbook/ch01-fundamentals.md) |
| 2.x | [Chapter 2: The Mental Model](../textbook/ch02-mental-model.md) |
| 3.x | [Chapter 3: Git Internals](../textbook/ch03-git-internals.md) |
| 4.x | [Chapter 4: The Working Tree](../textbook/ch04-working-tree.md) |
| 5.x | [Chapter 5: The Index](../textbook/ch05-index.md) |
| 6.x | [Chapter 6: Commits](../textbook/ch06-commits.md) |
| 7.x | [Chapter 7: Branches](../textbook/ch07-branches.md) |
| 8.x | [Chapter 8: Merge](../textbook/ch08-merge.md) |
| 9.x | [Chapter 9: Rebase](../textbook/ch09-rebase.md) |
| 10.x | [Chapter 10: Cherry-pick](../textbook/ch10-cherry-pick.md) |
| 11.x | [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md) |
| 12.x | [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md) |
| 13.x | [Chapter 13: Recovery](../textbook/ch13-recovery.md) |
| 14A.x | [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md) |
| 14B.x | [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md) |
| 14C.x | [Chapter 14C: Stash Internals, Rerere, Attributes, Hooks](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| 14D.x | [Chapter 14D: The Frontier](../textbook/ch14d-frontier.md) |
| 15.x | [Chapter 15: GitHub](../textbook/ch15-github.md) |
| 16.x | [Chapter 16: Authentication](../textbook/ch16-authentication.md) |
| 17.x | [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md) |
| 18.x | [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md) |
| 19.x | [Chapter 19: CODEOWNERS](../textbook/ch19-codeowners.md) |
| 20A.x | [Chapter 20A: GitHub Actions Fundamentals](../textbook/ch20a-actions-fundamentals.md) |
| 20B.x | [Chapter 20B: GitHub Actions: delivery, runners, cost and debugging](../textbook/ch20b-actions-delivery-debugging.md) |
| 21A.x | [Chapter 21A: GitHub Actions security](../textbook/ch21a-actions-security.md) |
| 21B.x | [Chapter 21B: Repository security, identity, the Git client, and secret-leak response](../textbook/ch21b-repository-security-incident-response.md) |
| 22.x | [Chapter 22: Git LFS](../textbook/ch22-git-lfs.md) |
| 23.x | [Chapter 23: Submodules and Subtrees](../textbook/ch23-submodules.md) |
| 24.x | [Chapter 24: Monorepos](../textbook/ch24-monorepos.md) |
| 25.x | [Chapter 25: Worktrees](../textbook/ch25-worktrees.md) |
| 26.x | [Chapter 26: Performance](../textbook/ch26-performance.md) |
| 27.x | [Chapter 27: Open source and team workflows](../textbook/ch27-open-source-team-workflows.md) |
| 28.x | [Chapter 28: AI/ML workflows](../textbook/ch28-ai-ml-workflows.md) |
| 29.x | [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md) |
| 30.x | [Chapter 30: Incident Response](../textbook/ch30-incident-response.md) |

# Disaster-recovery playbook

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. One page per disaster. Every command on these pages was run in this course's labs (Chapters 11, 12, 13 and 30) or checked against the Git 2.55.0 manual. GitHub-side steps are described from GitHub's documentation and were not run. This playbook is for the moment after something went wrong; for a symptom you cannot yet name, start with the [troubleshooting playbook](troubleshooting-playbook.md).

## How to use a page

Every page has the same seven parts.

| Part | What it gives you |
|---|---|
| **Trigger** | How you recognise that you are in this disaster and not a similar one |
| **First move** | The one thing to do before anything else. It never destroys anything |
| **Evidence to preserve** | What to name, copy or write down before a ref moves |
| **Recovery commands** | The lowest-risk route, with risk labels: 🟢 reads or only adds; 🟡 moves refs, recoverable through the reflog; 🔴 can destroy work or the safety net |
| **Verification** | The command whose output proves that the recovery worked |
| **What not to do** | The reflex that turns this disaster into a worse one |
| **Point of no return** | The event after which this route no longer works |

Four rules apply to every page.

1. **Stop first.** Until you have read the page: no `git gc`, no `git prune`, no `git clean`, no `git stash clear`, no `git fetch --prune`, no re-clone, no second "fix".
2. **Name before you move.** `git branch rescue/<what> <commit ID>` costs nothing and stops expiry.
3. **Add before you rewind.** Prefer a new branch, a cherry-pick, a merge or a revert to a reset; prefer `git reset --keep` to `git reset --hard`.
4. **Force only with an explicit lease.** `git push --force-with-lease=<branch>:<expected ID>`, with the ID you examined.

Default retention, on which the points of no return rest: a reflog entry lasts 90 days, 30 if its commit is no longer reachable from the tip; an unreachable object is deleted two weeks later, once maintenance runs; deleting a branch deletes its reflog at once ([Chapter 13: Recovery](../textbook/ch13-recovery.md), section 13.4).

## Before the first command: three decisions

**Whose clone has the evidence?** A server keeps no reflog. The old value of a server-side branch is in the reflogs of the clones that fetched or pushed it, and each clone knows only what it saw. Ask each colleague to paste the output of these three commands before they fetch, pull, prune or re-clone:

```bash
git status -sb                         # 🟢 where their branch stands against their last view of the server
git rev-parse origin/<branch>          # 🟢 the server's value as they last saw it
git reflog show origin/<branch> -5     # 🟢 the last five values, with the operation that recorded each
```

When several clones offer a candidate for "the last good commit", the newest one is the one that has all the others as ancestors: `git merge-base --is-ancestor <candidate A> <candidate B>` exits 0 when A is contained in B.

**Revert, restore or rewrite?** For a shared branch on the server:

| Situation | Choose | Why |
|---|---|---|
| Wrong commits were added; history before them is intact | **Revert** (page 6) | No forced update; every clone fast-forwards; undoable |
| The branch was replaced and good commits were lost; nobody built on the replacement | **Restore** with an explicit lease (pages 7, 9) | The lost commits and their recorded IDs come back |
| The branch was replaced and people built on the replacement | **Restore, then carry their commits over** (page 9), or keep the new history and re-apply what was lost | Decide by which commit IDs are recorded elsewhere (deployments, tags, tickets) |
| Content must not exist in history at all (a secret, personal data) | **Rewrite**, after containment (page 11) | The only case where a rewrite of shared history is the goal |
| A topic branch with one author is in a bad state | **Rebuild** it and push with a lease (pages 4, 5, 10) | The author is the only consumer |

**What does the team hear, and when?** Three messages. Templates:

```text
FREEZE   (within minutes, before the cause is known)
  Do not pull, push, reset or prune <branch> of <repository> until further notice. If you fetched it in
  the last <N> hours, do not clean up or re-clone. I am investigating and will update at <time>.

INSTRUCTIONS   (after the recovery is verified)
  <branch> is restored; its tip is <ID>. In your clone:
    git fetch
    git cherry -v origin/<branch> <branch>
  If every line starts with "-" (or there is no output):  git reset --keep origin/<branch>
  If any line starts with "+": stop and send me the output.

ALL CLEAR   (with the four-part summary)
  What happened / root cause and layer / what was done and how it was verified / prevention.
```

## The pages

| # | Disaster | # | Disaster |
|---|---|---|---|
| 1 | Commits vanished after a reset, an amend or a rebase | 9 | A production or release branch was rewritten |
| 2 | Uncommitted work was overwritten | 10 | A shared branch carries every commit twice |
| 3 | A local branch was deleted | 11 | A secret was committed |
| 4 | A rebase went wrong | 12 | A stash was dropped or cleared |
| 5 | A merge went wrong | 13 | The repository is damaged |
| 6 | Wrong commits are on a shared branch | 14 | "It is pushed", and the server does not have it |
| 7 | A shared branch was force-pushed | 15 | The default branch's CI turned red |
| 8 | A branch was deleted on the server | 16 | A release tag was moved or deleted |

---

## 1. Commits vanished after a reset, an amend or a rebase

**Trigger.** `git log` no longer shows commits you made. The last commands included `git reset`, `git commit --amend`, `git rebase` or `git pull --rebase`.

**First move.** `git reflog show <branch>` 🟢. Find the line below the operation that moved the branch.

**Evidence to preserve.** The terminal scrollback (`HEAD is now at ...` prints an ID). The old tip: `git branch rescue/before <branch>@{n}` 🟢. If you made commits after the accident, also `git branch rescue/after <branch>`.

**Recovery commands.**

```bash
git log --oneline <branch>..rescue/before          # 🟢 what is missing
git reset --keep rescue/before                     # 🟡 nothing new was committed since: move the branch back
git cherry-pick <branch>..rescue/before            # 🟡 commits were made since: add the lost ones on top instead
```

Directly after a reset or a rebase, and before any other command that writes it, `ORIG_HEAD` holds the old tip: `git reset --keep ORIG_HEAD`. An amend does not write `ORIG_HEAD`; use the reflog.

**Verification.** `git range-diff <base> rescue/before <branch>` shows `=` for every recovered commit, or `git diff --stat rescue/before <branch>` shows only what you expect.

**What not to do.** `git reset --hard` again "to try something". Guessing with `HEAD~n`. Deleting the rescue branch before verifying.

**Point of no return.** The reflog entry expires (30 days by default for unreachable commits) and maintenance then deletes the objects; or someone runs `git reflog expire --expire=now --all` with `git gc --prune=now`.

---

## 2. Uncommitted work was overwritten

**Trigger.** Edits are gone after `git reset --hard`, `git restore`, `git checkout -- <file>`, `git stash drop` or `git clean`.

**First move.** Classify each lost change: was it ever staged with `git add` (or stashed), or only saved in the editor?

**Evidence to preserve.** Do not run `git gc`. Do not save over files in the editor: its undo buffer may be the only copy.

**Recovery commands.**

```bash
git fsck --lost-found                 # 🟢 staged, never committed: writes dangling blobs to .git/lost-found/other/
git cat-file -p <blob ID>             # 🟢 read a candidate
git cat-file -p <blob ID> > <path>    # 🟡 write it back under its path (overwrites that path)
```

A blob has no file name: identify it by content. For a dropped stash, see page 12. For work that was never staged, Git has nothing: use the editor's local history, an IDE's history, or a machine backup.

**Verification.** `git status -s` and `git diff` show the content back in the working tree. Then commit it.

**What not to do.** Promise that Git can recover unstaged edits. Run `git clean` to "tidy up" while searching.

**Point of no return.** For unstaged edits: the moment of overwriting. For staged blobs: two weeks after they became unreachable, once maintenance runs.

---

## 3. A local branch was deleted

**Trigger.** `git branch -D <name>` (or `-d`) was run, and commits that were only on that branch are needed.

**First move.** Read the scrollback: Git printed `Deleted branch <name> (was <ID>).` That ID is the whole recovery.

**Evidence to preserve.** The ID. Without scrollback: `git reflog` 🟢 (the HEAD reflog survives; look for `checkout: moving from <name>`), or `git fsck --no-reflogs --lost-found` 🟢 for tips that were never checked out.

**Recovery commands.**

```bash
git branch <name> <ID>                         # 🟢 the branch is back; its old reflog is not
git log --oneline main..<name>                 # 🟢 what it holds beyond main
git diff --stat main <name>                    # 🟢 what content it holds beyond main (reliable after a squash merge)
```

If the branch was squash-merged and you only need what came after the merge, do not restore the old name. Anchor it as `rescue/<name>`, create a new branch from `main`, and `git cherry-pick` the unmerged commits (Chapter 30, incident 8).

**Verification.** `git log --oneline <name>` shows the expected tip.

**What not to do.** Re-clone "to get a clean state": the commits may exist only in this clone.

**Point of no return.** The HEAD reflog entry expires, or the tip was never checked out and maintenance deletes the objects after the two-week grace period.

---

## 4. A rebase went wrong

**Trigger.** During a rebase: conflicts you cannot resolve, or the todo list was edited wrongly. After a rebase: commits are missing, duplicated or changed.

**First move.** `git status` 🟢. It says whether a rebase is still in progress.

**Evidence to preserve.** In progress: nothing is lost yet; the branch has not moved. Finished: `git branch rescue/pre-rebase <branch>@{n}` 🟢, where `n` is the reflog entry before `rebase (start)`, or `ORIG_HEAD` if nothing ran since.

**Recovery commands.**

```bash
git rebase --abort                                  # 🟡 in progress: back to the state before the rebase
git cherry -v <branch> rescue/pre-rebase            # 🟢 finished: "+" marks commits the rebased branch lacks
git reset --keep rescue/pre-rebase                  # 🟡 undo the whole rebase
git cherry-pick <ID>                                # 🟡 or keep the rebase and add back one dropped commit
```

**Verification.** `git range-diff <base> rescue/pre-rebase <branch>`: every commit paired, none marked `<` unless you meant to drop it.

**What not to do.** `git rebase --abort` after new commits were made inside the stopped rebase without anchoring them first. `git commit --amend` at a conflict stop where `git rebase --continue` was needed. A force push before the range-diff.

**Point of no return.** As page 1. If the rebased branch was already pushed and others fetched it, see page 10.

---

## 5. A merge went wrong

**Trigger.** A merge stopped with conflicts you do not want to resolve now; or a completed merge is wrong (wrong branch, bad resolution); or a merged fix has vanished from a file.

**First move.** `git status` 🟢, then decide which of three cases applies: in progress, committed locally, or pushed.

**Evidence to preserve.** For a completed merge: its ID, and `git show --remerge-diff <merge>` 🟢, which shows what the resolver changed relative to Git's own result.

**Recovery commands.**

```bash
git merge --abort                              # 🔴 in progress: back to the state before the merge; resolutions made so far are discarded
git reset --keep ORIG_HEAD                     # 🟡 committed, not pushed, nothing since: remove the merge
git revert -m 1 <merge>                        # 🟡 pushed to a shared branch: a new commit that undoes it
```

After `git revert -m 1`, a later merge of the same branch brings nothing until the revert is itself reverted ([Chapter 11](../textbook/ch11-reset-revert-restore.md), section 11.9). If only part of a resolution was wrong, add one commit that restores the lost lines instead (Chapter 30, incident 9). To take a mistaken merge out of an unmerged topic branch, rebuild the branch: `git rebase --onto <merge>^1 <merge>` 🟡.

**Verification.** `git diff <the parent you expect to match> HEAD`, and for a restored resolution `git diff <other side's commit> HEAD -- <file>` shows only the intended differences.

**What not to do.** `git checkout --ours <file>` or `--theirs` to "get past" a conflict: it takes one side of the whole file, including hunks that had merged cleanly. Reset a shared branch to remove a pushed merge.

**Point of no return.** None for the content: both parents remain in history. The cost of a late repair grows with every commit built on the bad merge.

---

## 6. Wrong commits are on a shared branch

**Trigger.** A commit that should not be there is on `main` or another shared branch on the server, and others may have fetched it.

**First move.** Tell the team which commit is being undone. Then `git fetch` 🟢 and `git log --oneline origin/<branch> -5` 🟢.

**Evidence to preserve.** The IDs of the bad commits and whether anything was built on top of them.

**Recovery commands.**

```bash
git switch <branch> && git pull --ff-only          # 🟡 be exactly at the server's tip
git revert --no-edit <ID>                          # 🟡 one commit
git revert --no-edit <oldest>^..<newest>           # 🟡 a consecutive range, newest first
git push                                           # an ordinary fast-forward push
```

A revert keeps history intact and every clone can fast-forward. Removing the commits with a forced push is justified only when they must not stay in history at all and nobody built on them (page 7 has the command).

**Verification.** `git diff <last good commit> origin/<branch>` is empty, or shows only later legitimate work.

**What not to do.** `git reset --hard` plus `git push --force` on a shared branch as a routine undo: every teammate's clone diverges, and one ordinary pull puts the commits back.

**Point of no return.** None. A revert can itself be reverted.

---

## 7. A shared branch was force-pushed

**Trigger.** `git fetch` prints `+ ...  (forced update)` for a shared branch; `git status -sb` says `ahead N, behind M` although you made no commits; commits are missing on the server.

**First move.** Message the team: nobody pulls, pushes, resets or prunes that branch. Then `git fetch` 🟢 (it records both values in your reflog) and `git reflog show origin/<branch>` 🟢.

**Evidence to preserve.**

```bash
git branch rescue/before-force 'origin/<branch>@{1}'              # 🟢 the server's value before the event, as you knew it
git log --format='%h %an: %s' origin/<branch>..rescue/before-force    # 🟢 what the server lost
git log --format='%h %an: %s' rescue/before-force..origin/<branch>    # 🟢 what it gained
```

Ask every teammate for `git rev-parse origin/<branch>` from a clone that has **not** fetched, and take the newest: `git merge-base --is-ancestor <theirs> <yours>` 🟢.

**Recovery commands.**

```bash
git push origin origin/<branch>:refs/heads/<new-name>                             # 🟢 keep the forced-in commits on their own branch
git push --force-with-lease=<branch>:<bad ID> origin rescue/before-force:<branch>   # 🔴 restore: only if the server still has <bad ID>
git merge origin/<branch>                                                         # 🟡 instead: if the forced-in commits are legitimate, merge both lines
```

**GitHub.** If no clone has the old value: the repository's [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository) lists force pushes; a `PushEvent` in the [Events API](https://docs.github.com/en/rest/activity/events) has the `before` ID (last 300 events, 30 days); `gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=<ID>` creates a branch there ([references API](https://docs.github.com/en/rest/git/refs#create-a-reference)). This combination is an inference from documented endpoints, and GitHub publishes no retention period for unreachable commits.

**Verification.** `git ls-remote origin <branch>` 🟢 prints the restored ID.

**What not to do.** `git reset --hard origin/<branch>` in your clone: it throws your copy of the lost commits off the branch. A bare `git push --force` to restore. `git pull` before you know what happened; in particular `git pull --rebase`, which treats commits you had pushed and the force push removed as old upstream history and silently leaves them off your branch (they stay in `ORIG_HEAD` and the reflog).

**Point of no return.** Every clone that had the old commits has pruned them or been re-cloned, and the host no longer has them.

---

## 8. A branch was deleted on the server

**Trigger.** A branch is missing from `git ls-remote origin`; `git status` says the upstream is `gone`; a fetch with pruning removed `origin/<name>`.

**First move.** Do not fetch with `--prune` in any other clone. Check whether it was deleted because its pull request was merged: `git log --oneline -5 origin/main` 🟢.

**Evidence to preserve.** The tip, from whichever exists: a local branch `<name>`; `origin/<name>` in a clone that has not pruned; the HEAD reflog; `git fsck --no-reflogs --lost-found` 🟢.

**Recovery commands.**

```bash
git push origin <name>                                 # 🟢 you have the local branch: publish it again
git push origin origin/<name>:refs/heads/<name>        # 🟢 you have only the remote-tracking ref (not pruned yet)
git branch <name> <ID> && git push -u origin <name>    # 🟢 you have only the ID
```

**GitHub.** A closed pull request offers **Restore branch** for its head branch ([docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request)). It restores what the server had, not commits that were never pushed.

**Verification.** `git ls-remote origin <name>` 🟢.

**What not to do.** Push a squash-merged branch back and open a new pull request from it: the merged commits reappear in the pull request. Assume "merged" means every local commit is in `main`: compare with `git diff main <tip>`.

**Point of no return.** All clones have pruned and collected the commits, no pull request exists for the branch, and the host has dropped them.

---

## 9. A production or release branch was rewritten

**Trigger.** A deployment tool reports that the deployed commit is not an ancestor of the branch; everyone's clone shows the branch as diverged; a tag is no longer on the branch.

**First move.** Freeze: no deployments from, and no pushes or resets of, that branch. Say so in the channel.

**Evidence to preserve.**

```bash
git fetch                                                              # 🟢
git rev-parse <branch> 'origin/<branch>@{1}' '<deploy-tag>^{commit}'   # 🟢 independent witnesses of the old tip
git branch --no-track rescue/rewritten origin/<branch>                 # 🟢 name the rewritten state too
git diff --stat <old tip> origin/<branch>                              # 🟢 "same code" is a claim about trees: test it
git log --format='%h %an, committed by %cn: %s' <old tip>..origin/<branch>   # 🟢 the committer shows who rewrote
```

**Recovery commands.**

```bash
git switch <branch>                                                  # your copy is still the old history
git cherry-pick <ID>                                                 # 🟡 each legitimate commit shipped on top of the rewrite
git push --force-with-lease=<branch>:<rewritten ID> origin <branch>    # 🔴 restore, conditional on the server's current value
git cherry -v origin/<branch> <branch>                               # 🟢 in every other clone: "+" lines are work the server lacks
git reset --keep origin/<branch>                                     # 🟡 in every other clone, once only expected "+" lines remain
```

**Verification.** `git merge-base --is-ancestor <deploy-tag> origin/<branch>` 🟢 exits 0. `git diff --stat rescue/rewritten origin/<branch>` shows only the differences you intend.

**What not to do.** Advise "reset to the server" before you know which history is right. Deploy from the rewritten branch because "the tests pass". Recreate or move the deployment tag to make the check pass.

**Point of no return.** New work has been built on the rewritten history by many people and deployed: then keep the new history, re-apply what was dropped as new commits, and record the old and new IDs side by side.

---

## 10. A shared branch carries every commit twice

**Trigger.** A pull request lists commits twice with different IDs and a merge commit titled `Merge branch '<branch>' of <remote> into <branch>`; someone rebased the branch and someone else pulled with a merge.

**First move.** Ask both people to stop pushing the branch. `git log --oneline --graph origin/<base>..origin/<branch>` 🟢.

**Evidence to preserve.**

```bash
git reflog show <branch> ; git reflog show origin/<branch>        # 🟢 in the clone that pulled: find three IDs
#   <old>  the shared tip before the rebase      <new>  the rebased tip      <mine>  the local tip before the pull
git range-diff <base-before>..<old> <base>..<new>                 # 🟢 "=" lines: the same changes under new IDs
git branch rescue/merged <branch> ; git branch rescue/mine <mine> # 🟢
```

**Recovery commands.**

```bash
git reset --keep <mine>                                       # 🟡 back to the tip before the pull
git rebase --onto <new> <old>                                 # 🟡 replay only the unpublished commits onto the rebased tip
git diff --stat rescue/merged <branch>                        # 🟢 must print nothing: same content, clean history
git push --force-with-lease=<branch>:<merged ID> origin <branch>   # 🔴 conditional on the server's current value
```

The person who rebased then runs `git pull --ff-only`.

**Verification.** `git log --oneline origin/<base>..origin/<branch>` lists each subject once and no merge.

**What not to do.** Force the old series back (it undoes the teammate's rebase). Merge the pull request as it is. Fix it in two clones at once.

**Point of no return.** The duplicated history is merged into the base branch with a merge commit. From then on it is history; do not rewrite the base to tidy it.

---

## 11. A secret was committed

**Trigger.** A credential, key or password is in a commit that was pushed, or a scanner alert says so.

**First move.** **Revoke or rotate the credential at its issuer.** Not a Git command. Everything else on this page comes after.

**Evidence to preserve.**

```bash
git log --all --format='%h %an %ad: %s' -- <path>         # 🟢 the commits that added and removed the file
git branch -a --contains <adding commit>                  # 🟢 every branch that reaches it
git reflog show --date=iso origin/<branch>                # 🟢 in the pushing clone: the time of the first push
```

Write down: what the secret can reach, the exposure window, who could read the repository, and what the issuer's logs show.

**Recovery commands.** Remove the secret from current code and add the ignore rule. Rewrite history only if the data stays harmful after rotation or the affected history is small and unmerged.

```bash
git rebase -i <base>                                # 🟡 short unmerged branch: "edit" the adding commit, "drop" the deleting one
git rm --cached <path> && git commit --amend --no-edit && git rebase --continue
git push --force-with-lease --force-if-includes     # 🔴 publish the rewritten branch
git rebase --onto origin/<branch> 'origin/<branch>@{1}' <dependent-branch>   # 🟡 every branch built on the old commits
```

For a whole repository the documented tool is git-filter-repo 2.47 or later with `--sensitive-data-removal`, in a fresh clone, followed by a force push of all refs ([GitHub: removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository); [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), section 21B.16). It is not installed in this course's environment. On GitHub, removal of the old objects is a request to Support. In each clone: re-clone, or 🔴 `git reflog expire --expire=now --all && git gc --prune=now`.

**Verification.** At the issuer: the old credential is rejected. In Git: `git log --all --oneline -- <path>` prints nothing and `git cat-file -t <adding commit>` fails in every repository.

**What not to do.** Start with Git. Believe that deleting the file, force-pushing or making the repository private removes the secret. Merge or pull an old branch after the rewrite. Stay quiet.

**Point of no return.** The first push. From then on assume the secret was copied; only rotation ends the exposure.

---

## 12. A stash was dropped or cleared

**Trigger.** `git stash drop`, `git stash pop` followed by a lost working tree, or `git stash clear`, and the content is needed.

**First move.** Scrollback: `Dropped refs/stash@{0} (<ID>)` prints the ID. Do not run `git gc`.

**Evidence to preserve.** The ID, or the candidates from the manual's recipe:

```bash
git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'    # 🟢
```

A stash entry is a merge commit; its subject starts with `WIP on` or `On <branch>:`.

**Recovery commands.**

```bash
git stash show -p <ID>                          # 🟢 inspect a candidate
git stash store -m 'recovered: <what>' <ID>     # 🟢 put it back on the stash list
git stash list                                  # 🟢
```

**Verification.** `git stash show -p 'stash@{0}'` 🟢 shows the expected changes.

**What not to do.** `git stash pop` the recovered entry onto a dirty working tree; use `git stash apply` on a clean one, or `git stash branch <name>`.

**Point of no return.** Maintenance deletes the unreachable commit, by default two weeks after it became unreachable.

---

## 13. The repository is damaged

**Trigger.** Git reports `fatal: bad object`, `error: object file ... is empty`, `index file corrupt`, or `git fsck` reports missing or corrupt objects, typically after a crash, a full disk or a file-sync tool touching `.git`.

**First move.** Stop writing to the repository and copy it whole: `cp -R <repo> <repo>.damaged`. Work on the original only after the copy exists.

**Evidence to preserve.** The copy. The output of `git fsck` 🟢. Uncommitted files in the working tree: copy them elsewhere.

**Recovery commands.**

```bash
mv .git/index .git/index.corrupt && git reset        # 🟡 corrupt index only: rebuild it from HEAD (staged-only changes are lost)
git fetch --refetch origin                           # 🟡 missing or corrupt objects that the server has: download everything again
git fsck                                             # 🟢 repeat until clean
```

Objects that exist only locally (unpushed commits) cannot come from the server. Take them from another clone or a bundle, or accept the loss and recover file contents from the working tree. If only the working tree matters: clone afresh, then copy the uncommitted files over.

**Verification.** `git fsck` 🟢 prints no error; `git status` and `git log --oneline -5` work.

**What not to do.** `git gc` or `git prune` on a damaged repository. Delete `.git` before unpushed branches have been compared with the server (`git branch -vv` in the copy).

**Point of no return.** An object that existed in one place only is overwritten or deleted. A weekly `git bundle create <file> --all` of important repositories moves this point ([Chapter 13](../textbook/ch13-recovery.md), section 13.14).

---

## 14. "It is pushed", and the server does not have it

**Trigger.** A commit is in someone's `git log`; `git status` says up to date; the team repository, the pull request or the release lacks it.

**First move.** Ask the server, not the clone: `git ls-remote <remote> <branch>` 🟢.

**Evidence to preserve.** Nothing is at risk. Collect four answers:

```bash
git branch -a --contains <ID>      # 🟢 which local and remote-tracking branches have it
git remote -v                      # 🟢 which repositories this clone talks to
git branch -vv                     # 🟢 which upstream each branch follows
git status -sb                     # 🟢 ahead N means not pushed
```

**Recovery commands.** By cause:

```bash
git push -u origin <branch>                              # 🟢 never pushed, or pushed under another name
git switch -c <name> && git push -u origin <name>        # 🟢 made in detached HEAD
git fetch <team-remote> && git rebase <team-remote>/main # 🟡 pushed to a fork: put it on top of the team's main,
git push -u <team-remote> <branch>                       #    then publish it where the team looks
git branch --set-upstream-to=<team-remote>/main main     # 🟢 and fix the upstream for next time
```

A rejected push (`! [rejected] ... (fetch first)` or `(non-fast-forward)`) means the server has commits you lack: fetch, integrate, push again ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.7).

**Verification.** `git ls-remote <remote> <branch>` 🟢, and `git merge-base --is-ancestor <ID> <remote>/<branch>` 🟢 after a fetch.

**What not to do.** Trust `git status` as proof of a push. Force the push because it was rejected.

**Point of no return.** None, as long as the clone with the commit exists.

---

## 15. The default branch's CI turned red

**Trigger.** A workflow that was green fails on the default branch or on every pull request; "it passes on my machine".

**First move.** Find where green turns red, and whether a commit or the outside world changed: `gh run list --workflow <file> --branch main --limit 20` and `git log --oneline -- .github/workflows`.

**Evidence to preserve.** The run ID, its event and commit: `gh run view <run-id> --json event,headBranch,headSha,workflowName`. The failed step's log: `gh run view <run-id> --log-failed`. Logs and artifacts expire; copy what the postmortem will need.

**Recovery commands.** Investigate in this order and stop at the first finding: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency ([Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), section 20B.11). Common findings and their documented remedies:

| Finding | Remedy |
|---|---|
| A tool needs history or tags; the checkout fetched one commit | `fetch-depth: 0` on `actions/checkout` |
| The job tested the pull request's merge ref, which includes new base commits | Update the branch from the base and reproduce locally |
| A file name differs in case between code and repository | Make them match; check with `git ls-files` |
| A secret is empty (fork, Dependabot, renamed secret) | A fork-safe job design; never `pull_request_target` as a shortcut |
| A moved `-latest` runner label or a moved action tag | Pin the label; pin actions by commit SHA |

Reproduce a shallow, tagless checkout locally with `git clone --depth 1 --no-tags <url>` 🟢. If the cause is a recent commit and the fix is not at hand, `git revert --no-edit <ID>` 🟡 through a pull request restores green.

**Verification.** A green run on the fix branch, then on the default branch: `gh run list --workflow <file> --branch main --limit 1`.

**What not to do.** Merge over a red required check with administrator rights. Re-run until it passes. Disable the check.

**Point of no return.** None for the repository. Every day of red hides the next defect behind the first.

---

## 16. A release tag was moved or deleted

**Trigger.** A release tag names another commit than it did (`git ls-remote --tags origin` disagrees with a clone, or a rebuild of the "same" version differs), or the tag is missing on the server.

**First move.** Do not run `git fetch --tags --force` anywhere yet: a clone that still has the original tag is the evidence and the backup. A plain `git fetch` never replaces an existing local tag; it reports `(would clobber existing tag)` only when tags are fetched explicitly ([Chapter 14B](../textbook/ch14b-config-tags-signing.md)).

**Evidence to preserve.**

```bash
git ls-remote --tags origin               # 🟢 the server: the tag object, and with ^{} the commit it names
git rev-parse '<tag>^{commit}'            # 🟢 this clone's idea of the tag
git tag --contains <commit>               # 🟢 which tags reach a given commit
```

Collect the second line from several clones and from the release or deployment record.

**Recovery commands.**

```bash
git push origin <tag>                     # 🟢 the tag was deleted on the server: publish it again from a clone that has it
git push --force origin <tag>             # 🔴 the tag was moved: put the original back, from a clone that still has the original
git fetch --tags --force                  # 🟡 afterwards, in every clone that picked up the moved tag
```

**GitHub.** A release is a GitHub object on top of a Git tag. With immutable releases the tag and assets are locked and the tag name cannot be reused ([immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)); a tag ruleset can restrict tag updates and deletions ([Chapter 18](../textbook/ch18-branch-protection.md), section 18.12).

**Verification.** `git ls-remote --tags origin` 🟢 shows the original commit on the `^{}` line, and it equals the deployment record.

**What not to do.** "Fix" a wrong release by moving its tag: publish a new version instead. Run `git fetch --tags --force` in the last clone that has the original before the server is repaired.

**Point of no return.** No clone and no record holds the original tag object or the commit ID it named. Artifacts built from the moved tag in the meantime stay wrong until rebuilt.

---

## After any recovery

1. Verify with the command on the page, and with the check the affected system runs.
2. Tell the team what to do with their clones, as commands.
3. Send the four-part summary: what happened, root cause with its layer, what was done and how it was verified, prevention ([Chapter 30](../textbook/ch30-incident-response.md), section 30.15).
4. Delete rescue branches only after step 1.
5. Write the postmortem within days and turn the root cause into the strongest control available (Chapter 30, sections 30.19 and 30.20).

# Incident 8: a branch appears to have disappeared — solution

> Read this only after your own attempt at [`incidents/08-branch-disappeared`](../incidents/08-branch-disappeared/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-08-branch-disappeared.sh`. In the sandbox, Ravi's clone plays GitHub's merge button. Layers: the squash merge and the deletion of the head branch are GitHub; pruning and the local deletion are Git.

## 1. Symptoms

`feature/prompt-versioning` is on neither the server nor Asha's laptop. She finds none of her commit messages in `git log main`. She is sure everything was pushed. She needs the variable validation, her last commit. Ravi merged her pull request "with the green button" and deleted nothing.

## 2. Evidence

<!-- snippet: incidents/solve-08-branch-disappeared/01-observe -->
```text
$ cd asha
$ git status -sb
## main...origin/main
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
$ git ls-remote origin
1a7ca10d4574f2b74570b1c78760a98c51498ce5	HEAD
1a7ca10d4574f2b74570b1c78760a98c51498ce5	refs/heads/main
```
<!-- /snippet -->

The branch exists nowhere as a ref: not locally, not as a remote-tracking branch, not on the server.

<!-- snippet: incidents/solve-08-branch-disappeared/02-reflog -->
```text
# The branch reflog went with the branch. The HEAD reflog is still here:
$ git reflog show feature/prompt-versioning
fatal: ambiguous argument 'feature/prompt-versioning': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog --format='%h %gd %gs'
1a7ca10 HEAD@{0} pull: Fast-forward
c8dbea7 HEAD@{1} checkout: moving from feature/prompt-versioning to main
70df7f7 HEAD@{2} commit: Validate prompt variables before save
ceaa8bc HEAD@{3} commit: Add version history
a93889a HEAD@{4} commit: Load a prompt by version
c12fb6d HEAD@{5} commit: Store every save as a new version
c8dbea7 HEAD@{6} checkout: moving from main to feature/prompt-versioning
c8dbea7 HEAD@{7} clone: from $LAB/incidents/solve-08-branch-disappeared/server.git
```
<!-- /snippet -->

The reflog of a branch is deleted with the branch. The reflog of HEAD is separate and survives: it shows four commits made on the branch and then `checkout: moving from feature/prompt-versioning to main`.

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | The branch was renamed | A similar branch on the server | None |
| 2 | Somebody deleted it by mistake and the work is lost | Is the work in `main` under another form? | It is |
| 3 | The pull request was merged and the head branch deleted after the merge | The tip of `main`: author, committer, content | Confirmed |
| 4 | Everything had been pushed | Compare the last local commit with what `main` contains | False for one commit |

## 4. Diagnostic commands

<!-- snippet: incidents/solve-08-branch-disappeared/03-why-gone -->
```text
$ git config get --show-origin fetch.prune
file:.git/config	true
# What is on main now, and who put it there?
$ git log -2 --format='%h author %an, committer %cn: %s' main
1a7ca10 author Asha Rao, committer Ravi Menon: Add prompt versioning (#42)
c8dbea7 author Lab User, committer Lab User: Add README
$ git show --stat --format=%s main
Add prompt versioning (#42)

 registry/history.py | 2 ++
 registry/store.py   | 8 +++++---
 2 files changed, 7 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

The newest commit on `main`, "Add prompt versioning (#42)", has Asha as author and Ravi as committer and changes the two files of her branch. That is the shape of a squash merge: one new commit with the combined change, the pull request number in the subject. Her three commit messages are not in `main` because a squash merge does not keep them, which is why her search found nothing. `fetch.prune = true` in her clone explains the second disappearance: when the server's branch was deleted, her next fetch removed `origin/feature/prompt-versioning`.

> **GitHub, not Git.** A repository setting deletes head branches automatically after a pull request is merged ([automatic deletion of branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches)), and a closed pull request offers **Restore branch** for its head branch ([deleting and restoring branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request)). Restore recreates the branch as the server last saw it. It cannot contain a commit that was never pushed. GitHub Support is not needed for any of this.

<!-- snippet: incidents/solve-08-branch-disappeared/04-classify -->
```text
# The last commit made on the lost branch, from the HEAD reflog:
$ git log --oneline main..70df7f7
70df7f7 Validate prompt variables before save
ceaa8bc Add version history
a93889a Load a prompt by version
c12fb6d Store every save as a new version
# Patch IDs cannot see through a squash: every commit looks unmerged.
$ git cherry -v main 70df7f7
+ c12fb6d8347452b8124fe1d59b2f25c589155a6f Store every save as a new version
+ a93889ae2c557817889f98a9629eb7560ad5a984 Load a prompt by version
+ ceaa8bc13e03ca5676baa71d4401845ee3002318 Add version history
+ 70df7f70daac6ced8a343ab10d9509c1e363cf17 Validate prompt variables before save
# Trees can. What does the old tip have that main does not?
$ git diff --stat main 70df7f7
 registry/validate.py | 9 +++++++++
 1 file changed, 9 insertions(+)
$ git diff --stat main 70df7f7~1
```
<!-- /snippet -->

This snippet answers "which work is safe, and where". Four commits were on the branch. `git cherry` reports all four as missing from `main` (`+`), and that is misleading: it compares commits one by one, and a squashed commit equals none of its parts. The tree comparison is the reliable instrument. `main` and the third commit (`70df7f7~1`) have identical trees: the first three commits are in `main` completely. Between `main` and the fourth commit the only difference is `registry/validate.py`. That commit was made after the merge and never pushed.

## 5. Root cause

```text
Observed behavior : a branch is gone from the server and the clone; one commit of work is in no branch
Git state         : main holds a squash of three commits; the fourth was local only; the local branch was deleted with -D
Mechanism         : the server deleted the head branch after the merge; fetch.prune removed the remote-tracking ref;
                    "git branch -d" refused (squashed commits are not ancestors of main), so -D was used
Root cause        : work continued on a branch after its pull request was merged, and the branch was force-deleted without checking what was unmerged
Why Git does this : "merged" for git branch -d means "reachable"; a squash makes the content reachable under a new commit only
Correct fix       : anchor the last commit from the HEAD reflog; cherry-pick the one unmerged commit onto a new branch from main
Prevention        : start follow-up work on a new branch from the updated main; before -D, run "git diff main <branch>"
```

The refusal of `git branch -d` was the last safety check, and it fired correctly. `-D` overrode it.

## 6. Safe recovery

<!-- snippet: incidents/solve-08-branch-disappeared/05-anchor -->
```text
$ git branch rescue/prompt-versioning 70df7f7
$ git branch -vv
* main                     1a7ca10 [origin/main] Add prompt versioning (#42)
  rescue/prompt-versioning 70df7f7 Validate prompt variables before save
```
<!-- /snippet -->

The anchor gets a `rescue/` name on purpose. Recreating `feature/prompt-versioning` and pushing it would publish three commits whose content is already in `main` under another ID. A pull request from it would list four commits and could conflict with the squash: the reused-branch problem of [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), section 17.12.

<!-- snippet: incidents/solve-08-branch-disappeared/06-recover -->
```text
$ git switch -c feature/prompt-validation main
Switched to a new branch 'feature/prompt-validation'
$ git cherry-pick rescue/prompt-versioning
[feature/prompt-validation 499c20c] Validate prompt variables before save
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:26:00 2026 +0530
 1 file changed, 9 insertions(+)
 create mode 100644 registry/validate.py
$ git push -u origin feature/prompt-validation
To ../server.git
 * [new branch]      feature/prompt-validation -> feature/prompt-validation
branch 'feature/prompt-validation' set up to track 'origin/feature/prompt-validation'.
```
<!-- /snippet -->

A new branch from the current `main` and one cherry-pick: the commit that is new, and nothing that is already merged.

## 7. Verification

<!-- snippet: incidents/solve-08-branch-disappeared/07-verify -->
```text
# What a pull request for the new branch would show:
$ git log --oneline origin/main..origin/feature/prompt-validation
499c20c Validate prompt variables before save
$ git diff --stat origin/main...origin/feature/prompt-validation
 registry/validate.py | 9 +++++++++
 1 file changed, 9 insertions(+)
$ git diff --stat rescue/prompt-versioning feature/prompt-validation
$ git branch -D rescue/prompt-versioning
Deleted branch rescue/prompt-versioning (was 70df7f7).
$ cd ..
$ incidents/08-branch-disappeared/check.sh
Checking incident 08-branch-disappeared
  ok    the server has the branch feature/prompt-validation
  ok    the branch has "Validate prompt variables before save"
  ok    the branch is based on the current main
  ok    a pull request for the branch would list one commit
  ok    a pull request for the branch would change registry/validate.py only
  ok    registry/validate.py has the content of the lost commit
  ok    main on the server still ends with the squash merge
  ok    the merged branch was not pushed again
PASS: the recovery of incident 08-branch-disappeared is complete.
[exit status: 0]
```
<!-- /snippet -->

The pull request for the new branch would show one commit and one file. The tree of the new branch equals the tree of the old tip (`git diff --stat` prints nothing): nothing of the lost branch is missing. The rescue branch can go.

## 8. Prevention

- After a pull request is merged: `git switch main && git pull`, then a **new** branch for the next piece of work.
- Before `git branch -D`: `git log main..<branch>` and `git diff main <branch>`. An empty diff means the content is merged, whatever the log says.
- Read "everything is pushed" from `git status -sb` (`ahead N`) or `git log @{upstream}..`, not from memory.

## 9. Communication

To Asha: "Nothing was deleted by mistake. Ravi's merge was a squash: your first three commits are in `main` as one commit, 'Add prompt versioning (#42)'. GitHub then removed the merged branch, and your fetch pruned its local trace. Your validation commit was made after the merge and was never pushed; it survived only in your reflog. It is now on `feature/prompt-validation`, based on current `main`, pushed."

To the CTO: nothing, unless asked. If asked: "No work was lost. One unpushed commit was recovered from the developer's machine. The disappearance was the platform's normal clean-up after a merge."

## 10. Postmortem

- **Severity:** low. One unpushed commit at risk, recovered.
- **What nearly went wrong:** a re-created clone would have had no copy at all, and in a clone with default settings the reflog entry of an unreachable commit expires after 30 days ([Chapter 13: Recovery](../textbook/ch13-recovery.md), section 13.4).
- **Why it made sense:** a "gone" branch that GitHub calls merged looks safe to delete; the difference between "merged" and "squash-merged plus one more commit" is invisible in `git branch -vv`.
- **Actions:** the merge notification in the team channel names the merge method; the handbook gains the two-command check before `-D`.

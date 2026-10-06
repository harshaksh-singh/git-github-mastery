# V188: A developer rebases a shared branch, and senior standard 1: the branch was rebased and force-pushed and the pull request is broken

- **Part.** 9, Production debugging and incident response
- **Module.** 36, with Module 38
- **Planned minutes.** 26
- **Prerequisites.** V059, V125, V187
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.9 and 30.16
- **Demo scripts.** `labs/incidents/solve-05-rebased-shared-branch.sh` (snippets `01-state` to `12-prevent`), `labs/incidents/lab-38-3-lease.sh` (snippets `01-lease-refuses`, `02-failure`, `03-recovery`)

## HOOK

**[ON SCREEN]** "Every commit is in the pull request twice."

A reviewer opens a pull request that had five commits yesterday. A commit is one saved snapshot of the project, and a pull request is GitHub's proposal to merge a branch of commits. Today it lists nine. Three subjects appear twice, and a merge commit that nobody intended joins them. A merge commit is a commit that joins two lines of work. A second reviewer opens the same pull request, looks at the changed files, and sees nothing wrong: the same three files as before.

Both reviewers are describing the same pull request accurately. How can both be right? Hold that question. Somebody rebased, that is, copied commits onto a new base. Somebody pulled, somebody pushed, and no command printed an error at any point. Now a branch that two people share has to be rebuilt, in front of reviewers, without losing anybody's work.

A first question, before the cause is named. Is this a display problem on the page, or the real content of the repository? Which read-only checks would tell you? Say them out loud.

**[PAUSE]**

Ask the repository and not the page: `git ls-remote` for what the server holds, and a local log of the branch. If they list nine commits too, the page isn't the problem.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a debrief of Incident 5, [`incidents/05-rebased-shared-branch`](../../incidents/05-rebased-shared-branch/SYMPTOMS.md). You must have generated it and attempted it, with a command log. Have you? If you haven't, stop the video now.

**[PAUSE]**

The cause is named in the next section.

This incident is also the first of three scenarios that define what the course calls the senior standard. The standard isn't a harder command. It's a complete response in eleven steps, carried out in order, under time pressure, with other people's clones involved. In video 59 you learned what a rebased shared branch does to its users, and in video 125 why a pull request can show unexpected commits. Today you do the whole response: from inspecting the state to preventing a repeat.

Watch for one property above all: steps 1 to 6 change nothing.

## LEARNING OBJECTIVES

After this video you can:

1. Recognize a pull request in which every commit appears twice.
2. Reconstruct from refs and reflogs who rewrote what and when.
3. Preserve every clone's state before rebuilding.
4. Rebuild the branch so that each change is present once and nobody's work is lost.
5. Carry out the eleven steps of the senior standard, from inspecting state to preventing recurrence.

## CONCEPT

**What happened, as a mechanism.** Commits that another person had built on were rewritten, and that person's `git pull`, configured to merge, joined both versions. A rewritten shared branch met a clone that still had the originals. The merge made both series reachable from one tip, the newest commit of the branch, and the push published it.

**Why the two reviewers disagree.** The commit list of a pull request is `main..head`, the commits the head branch has and `main` lacks: nine entries. The file view is the diff `main...head`, what changed since the two split: the same three files as before, because two copies of one change are one change in a tree. The commit list and the file view answer different questions. So both reviewers were right.

**What is not at fault.** `--force-with-lease` isn't at fault. It's a forced push that succeeds only if the server's branch is still where you expect it, so it protects the server's commits, not the unpublished commits in a teammate's clone. And the rebase itself lost nothing and changed nothing in content. The damage is entirely the merge that made both series reachable. Layer: Git.

**The senior standard: eleven steps.**

1. Inspect the state.
2. Inspect refs.
3. Inspect the reflog.
4. Identify the old branch state.
5. Understand what changed.
6. Preserve recoverable references.
7. Determine the safest recovery.
8. Restore the correct history.
9. Update the pull request safely.
10. Explain what happened.
11. Prevent recurrence.

Steps 1 to 5 are the read-only phase of the method. Step 6 is the preserve phase. Steps 7 to 9 are the change phase, and steps 10 and 11 are the part that isn't Git.

**The options at step 7.**

**[ON SCREEN]** The table of section 30.16.

| Option | Result | Verdict |
|---|---|---|
| Leave it; merge the pull request as it is | Duplicates and a pointless merge enter `main` (unless squashed) | Rejected: history that misleads `bisect` and `blame` |
| Force the old series back | Undoes Asha's rebase; the branch conflicts with `main` again; her clone diverges | Rejected: destroys a teammate's work |
| Keep the rebased series, replay only your two commits onto it | Five commits, once each; Asha's clone can fast-forward | Chosen |

**The lease at step 9.** The restoring push is itself a forced push. It names the value you examined: `--force-with-lease=<branch>:<expected-id>`. If a teammate pushed after your fetch, the push is refused and you look again. A bare `--force` would overwrite their work. Tell the teammates before the push, not after.

**GitHub, not Git.** After a forced push to a head branch, review comments attached to replaced commits are shown as outdated, and an approval is dismissed if the rule "dismiss stale pull request approvals" is on and the diff changed. Here the diff is identical, and the commit list is what changed. Confirm on GitHub with `gh pr view <number> --json commits,changedFiles` and `gh pr diff <number> --name-only`. Those commands are shown without output. Nothing was captured from GitHub for this course.

**Prevention.** `git config set pull.rebase true`: when an upstream, the branch you pull from, was rewritten, `git pull --rebase` finds the old fork point in the reflog of the remote-tracking branch and replays only your commits. The reflog is Git's local record of where a ref has been, and the remote-tracking branch is your clone's record of the server's branch. `pull.ff only` is stricter: the pull stops and you decide. And an agreement: whoever rewrites a shared branch announces it first, with the old tip and the command teammates need.

**Severity.** SEV 3: a pull request is unreviewable, and there's no wrong content on a protected branch.

## MENTAL MODEL

A picture helps. Think of two editions of the same three chapters. Asha reprinted the chapters on new paper: same text, new page numbers. That's the rebase. You still had the old printing on your desk with two chapters of your own stapled behind it. Then you bound both printings into one book. The book now contains chapters one to three twice, and a reader who counts chapters is confused, while a reader who reads the text finds nothing changed.

The repair isn't to throw away the new printing, which would undo Asha's work, and not to publish the double book. It is to take your two chapters out and staple them behind the new printing.

Where the picture breaks: with paper you would know which pages are yours. In Git you have to find the boundary, and it has a precise name: the old shared tip. Everything after it on your side is yours. That boundary is what `git rebase --onto <new-tip> <old-shared-tip>` takes as its arguments.

And a rule for the whole standard: every commit that matters gets identified by name in step 4, before anything moves. If you can't write down three IDs, the old shared tip, the rebased tip and your tip before the pull, you aren't ready for step 7.

## DIAGRAM

**[DIAGRAM]** A new drawing: the eleven steps as a numbered column, each with the command that performs it and the evidence it produces. Build it during the demo, one row per step.

```text
  step                                  command                                    evidence it produces
  ------------------------------------  -----------------------------------------  ----------------------------------
   1 inspect the state                  git status -sb; git log main..head;        9 commits listed, 3 files changed
                                        git diff --stat main...head
   2 inspect refs                       git for-each-ref; git ls-remote origin     local, tracking and server agree
   3 inspect the reflog                 git reflog show <branch>;                  "pull: Merge made"; "forced-update"
                                        git reflog show origin/<branch>
   4 identify the old branch state      read three IDs from the reflogs            old shared tip, rebased tip, my tip
   5 understand what changed            git range-diff <old series> <new series>   three "=" pairs: same changes
   ---------------------------- nothing has changed up to here ----------------------------------------------
   6 preserve recoverable references    git branch rescue/...                      two anchors
   7 determine the safest recovery      a table of options                         one option chosen, with reasons
   8 restore the correct history        git reset --keep; git rebase --onto        5 commits, once each, no merge
   9 update the pull request safely     git push --force-with-lease=<ref>:<id>     forced update from the examined ID
  10 explain what happened              three sentences, no blame                  a message to the team
  11 prevent recurrence                 git config set pull.rebase true;           a setting and an agreement
                                        an agreement about rewrites
```

Draw the line under step 5 last and heavily.

## LIVE TERMINAL DEMO

From here on the screen shows the solution. Is your own command log beside you?

**[PAUSE]**

Then compare as we go.

**[TERMINAL]** Replay `labs/run incidents/solve-05-rebased-shared-branch`. We are in our own clone. Steps 1 to 5 are 🟢 SAFE; the one `git fetch` adds objects and moves remote-tracking refs.

**Step 1: inspect the state.**

```bash
git status -sb
git fetch
git log --oneline --graph origin/main feature/online-serving
```

<!-- snippet: incidents/solve-05-rebased-shared-branch/01-state -->
```text
$ cd you
$ git status -sb
## feature/online-serving...origin/feature/online-serving
$ git fetch
$ git log --oneline --graph origin/main feature/online-serving
*   6e7ebbd Merge branch 'feature/online-serving' of ../server into feature/online-serving
|\  
| * d4fd03c Add cache warm-up job
| * 5e57ed9 Decode online values
| * c8d1712 Add online lookup
| * 8131d29 Lower the TTL to 15 minutes
* | 57b5972 Decode batched values
* | af1f6de Add batched online lookup
* | 4967e71 Add cache warm-up job
* | 8f79c42 Decode online values
* | be7fb7a Add online lookup
|/  
* 65cb28c Add store config
* c587823 Add feature lookup
```
<!-- /snippet -->

`git status -sb` says the branch equals its remote-tracking branch: locally nothing looks wrong. The graph shows two columns that carry the same three subjects, joined by a merge at the top.

```bash
git log --oneline origin/main..origin/feature/online-serving
git diff --stat origin/main...origin/feature/online-serving
```

<!-- snippet: incidents/solve-05-rebased-shared-branch/02-pull-request-view -->
```text
# What a pull request into main lists: the commits, then the changed files.
$ git log --oneline origin/main..origin/feature/online-serving
6e7ebbd Merge branch 'feature/online-serving' of ../server into feature/online-serving
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
57b5972 Decode batched values
af1f6de Add batched online lookup
4967e71 Add cache warm-up job
8f79c42 Decode online values
be7fb7a Add online lookup
$ git diff --stat origin/main...origin/feature/online-serving
 store/batch.py  | 3 +++
 store/online.py | 3 +++
 store/warm.py   | 4 ++++
 3 files changed, 10 insertions(+)
```
<!-- /snippet -->

What the pull request lists: nine commits, three subjects twice. What it shows as changed: three files.

**Step 2: inspect refs.**

<!-- snippet: incidents/solve-05-rebased-shared-branch/03-refs -->
```text
$ git for-each-ref --format='%(refname:short) %(objectname:short) %(upstream:track)' refs/heads refs/remotes/origin/main refs/remotes/origin/feature
feature/online-serving 6e7ebbd 
main 65cb28c [behind 1]
origin/feature/online-serving 6e7ebbd 
origin/main 8131d29 
$ git ls-remote origin
8131d29e293dd17ca3be1161eced7adcc6957306	HEAD
6e7ebbd1d701fdf401d45d0ca24538f9d0e7a3d9	refs/heads/feature/online-serving
8131d29e293dd17ca3be1161eced7adcc6957306	refs/heads/main
```
<!-- /snippet -->

The local branch, the remote-tracking branch and the server agree on `6e7ebbd`. So this isn't a stale view or a display problem on the platform: the nine commits are what the repository contains.

**Step 3: inspect the reflog.** Two reflogs, read together from the bottom up. Predict what kind of entry you'll find at the top of each. Say it out loud.

**[PAUSE]**

```bash
git reflog show feature/online-serving
git reflog show origin/feature/online-serving
git config get pull.rebase
```

<!-- snippet: incidents/solve-05-rebased-shared-branch/04-reflog -->
```text
$ git reflog show feature/online-serving
6e7ebbd feature/online-serving@{0}: pull: Merge made by the 'ort' strategy.
57b5972 feature/online-serving@{1}: commit: Decode batched values
af1f6de feature/online-serving@{2}: commit: Add batched online lookup
4967e71 feature/online-serving@{3}: pull: Fast-forward
8f79c42 feature/online-serving@{4}: commit: Decode online values
be7fb7a feature/online-serving@{5}: commit: Add online lookup
65cb28c feature/online-serving@{6}: branch: Created from HEAD
$ git reflog show origin/feature/online-serving
6e7ebbd refs/remotes/origin/feature/online-serving@{0}: update by push
d4fd03c refs/remotes/origin/feature/online-serving@{1}: pull: forced-update
4967e71 refs/remotes/origin/feature/online-serving@{2}: pull: fast-forward
8f79c42 refs/remotes/origin/feature/online-serving@{3}: update by push
$ git config get pull.rebase
false
```
<!-- /snippet -->

Your branch: a fast-forward to the shared tip, two commits of your own, then "pull: Merge made by the 'ort' strategy". The remote-tracking branch: "pull: forced-update". The server's branch was replaced, and your pull, configured with `pull.rebase=false`, merged the replacement with what you had.

**[ANIMATION]** graph: c587823-65cb28c-8131d29 origin/main; 65cb28c main; 65cb28c-be7fb7a-8f79c42-4967e71-af1f6de-57b5972-6e7ebbd feature/online-serving origin/feature/online-serving; 8131d29-c8d1712-5e57ed9-d4fd03c; d4fd03c-6e7ebbd; HEAD=feature/online-serving => c587823-65cb28c-8131d29 origin/main; 65cb28c main; 65cb28c-be7fb7a-8f79c42-4967e71-af1f6de-57b5972-6e7ebbd rescue/merged-state origin/feature/online-serving; 57b5972 rescue/my-work; 8131d29-c8d1712-5e57ed9-d4fd03c-021ec35-5e4c03f feature/online-serving; d4fd03c-6e7ebbd; HEAD=feature/online-serving title=Two_series,_one_tip

**[ANIMATION]** step: state-1

**Step 4: identify the old branch state.** Three commits, by name. The shared tip before the rebase: `4967e71`. The rebased tip: `d4fd03c`. Your tip before the pull: `57b5972`.

<!-- snippet: incidents/solve-05-rebased-shared-branch/05-old-state -->
```text
# The shared tip before the rebase, the rebased tip, and my tip before the pull:
$ git rev-parse 'feature/online-serving@{3}' 'origin/feature/online-serving@{1}' 'feature/online-serving@{1}'
4967e71e446d83bc9c71b6ecb2b7fd6914bb6553
d4fd03c5eb1dd32cb4d5a9ce2910c768cc9093a7
57b597270111c4042d1fc8182815e4bcded25138
$ git show --no-patch --format="%h parents: %p" feature/online-serving
6e7ebbd parents: 57b5972 d4fd03c
```
<!-- /snippet -->

The merge commit confirms two of them as its parents.

**Step 5: understand what changed.** Are the two copies the same changes?

```bash
git range-diff origin/main~1..4967e71 origin/main..d4fd03c
```

<!-- snippet: incidents/solve-05-rebased-shared-branch/06-what-changed -->
```text
# Are the two copies the same changes? Compare the old series with the rebased series:
$ git range-diff origin/main~1..4967e71 origin/main..d4fd03c
1:  be7fb7a = 1:  c8d1712 Add online lookup
2:  8f79c42 = 2:  5e57ed9 Decode online values
3:  4967e71 = 3:  d4fd03c Add cache warm-up job
$ git log -3 --format='%h  author %ad  committer %cd  %s' --date=format:%H:%M 4967e71
4967e71  author 10:20  committer 10:20  Add cache warm-up job
8f79c42  author 10:11  committer 10:11  Decode online values
be7fb7a  author 10:10  committer 10:10  Add online lookup
$ git log -3 --format='%h  author %ad  committer %cd  %s' --date=format:%H:%M d4fd03c
d4fd03c  author 10:20  committer 10:29  Add cache warm-up job
5e57ed9  author 10:11  committer 10:29  Decode online values
c8d1712  author 10:10  committer 10:29  Add online lookup
```
<!-- /snippet -->

Three lines with an equals sign: the same changes under new IDs. The dates agree with that: a rebase keeps the author date and sets a new committer date. Nothing was lost by the rebase.

Here is the line in the diagram. Before we cross it, try it now, on paper. Thirty seconds. Write down the three IDs from memory: the old shared tip, the rebased tip, and your tip before the pull.

**[PAUSE]**

`4967e71`, `d4fd03c` and `57b5972`. Up to here nothing has changed in any repository except remote-tracking refs. You know what happened, by whom, in which order, and you have three IDs.

**Step 6: preserve.** 🟢 SAFE.

<!-- snippet: incidents/solve-05-rebased-shared-branch/07-preserve -->
```text
$ git branch rescue/merged-state feature/online-serving
$ git branch rescue/my-work 57b5972
```
<!-- /snippet -->

Two anchors. One makes the current, merged state restorable and comparable. The other holds the only commits that exist in one clone alone: yours.

**Step 7** is the options table from the concept section. Chosen: keep the rebased series, replay only your two commits onto it.

**Step 8: restore the correct history.** 🟡 CAUTION: `git reset --keep` moves the local branch and refuses to overwrite local changes. And `git rebase --onto` replaces your two commits with new ones.

```bash
git reset --keep 57b5972
git rebase --onto d4fd03c 4967e71
git log --oneline --graph origin/main~1..feature/online-serving
```

Quick quiz. After these two commands, what shape does the branch have? A, two columns joined by a merge, as before. B, one straight line. Your answer?

**[PAUSE]**

<!-- snippet: incidents/solve-05-rebased-shared-branch/08-rebuild -->
```text
# Back to my tip from before the pull (a local move), then replay only my two commits
# onto the rebased tip.
$ git reset --keep 57b5972
$ git rebase --onto d4fd03c 4967e71
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/online-serving.
$ git log --oneline --graph origin/main~1..feature/online-serving
* 5e4c03f Decode batched values
* 021ec35 Add batched online lookup
* d4fd03c Add cache warm-up job
* 5e57ed9 Decode online values
* c8d1712 Add online lookup
* 8131d29 Lower the TTL to 15 minutes
```
<!-- /snippet -->

**[ANIMATION]** step: state-2

B. A straight line: Asha's three rebased commits and your two on top, `021ec35` and `5e4c03f`.

Before publishing, two proofs.

<!-- snippet: incidents/solve-05-rebased-shared-branch/09-check-result -->
```text
$ git range-diff 4967e71..rescue/my-work d4fd03c..feature/online-serving
1:  af1f6de = 1:  021ec35 Add batched online lookup
2:  57b5972 = 2:  5e4c03f Decode batched values
$ git diff --stat rescue/merged-state feature/online-serving
```
<!-- /snippet -->

The range-diff pairs both of your commits with an equals sign. And the diff between the preserved merged state and the rebuilt branch prints nothing. The repair changed history and no content.

**Step 9: update the pull request safely.** 🔴 DANGEROUS: a forced push. The five answers. What it changes: the server's branch, to a commit that doesn't descend from the old one. What it can destroy: commits a teammate pushed after your fetch. Preview: `git fetch`, then compare the server's value with the one you examined. Recovery: another clone's copy, or the old ID from the push output. When appropriate: here, with an explicit expected value, after telling the teammates.

```bash
git push --force-with-lease=feature/online-serving:6e7ebbd origin feature/online-serving
git log --oneline origin/main..origin/feature/online-serving
git diff --stat origin/main...origin/feature/online-serving
```

<!-- snippet: incidents/solve-05-rebased-shared-branch/10-publish -->
```text
$ git push --force-with-lease=feature/online-serving:6e7ebbd origin feature/online-serving
To ../server.git
 + 6e7ebbd...5e4c03f feature/online-serving -> feature/online-serving (forced update)
$ git log --oneline origin/main..origin/feature/online-serving
5e4c03f Decode batched values
021ec35 Add batched online lookup
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
$ git diff --stat origin/main...origin/feature/online-serving
 store/batch.py  | 3 +++
 store/online.py | 3 +++
 store/warm.py   | 4 ++++
 3 files changed, 10 insertions(+)
```
<!-- /snippet -->

The lease names `6e7ebbd`, the value you examined in step 2. The pull request view now: five commits, the same three files.

**The teammate.** Asha's clone stood at the rebased tip, of which the new tip is a descendant.

<!-- snippet: incidents/solve-05-rebased-shared-branch/11-teammate -->
```text
$ cd ../asha
$ git fetch
From ../server
   d4fd03c..5e4c03f  feature/online-serving -> origin/feature/online-serving
$ git status -sb
## feature/online-serving...origin/feature/online-serving [behind 2]
$ git pull --ff-only
Updating d4fd03c..5e4c03f
Fast-forward
 store/batch.py | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 store/batch.py
```
<!-- /snippet -->

For her, `git pull --ff-only` is the whole repair.

**Step 10: explain.** Three sentences, no blame, in the textbook's wording: "Asha rebased the shared branch onto `main` while I had two unpushed commits on the old version. My `git pull` merged the old and the rebased commits, and I pushed the result, so the pull request listed both. I rebuilt the branch as the rebased commits plus mine; no content changed, and reviews of the diff stay valid."

**Step 11: prevent.**

<!-- snippet: incidents/solve-05-rebased-shared-branch/12-prevent -->
```text
$ cd ../you
$ git config set pull.rebase true
$ git branch -D rescue/merged-state rescue/my-work
Deleted branch rescue/merged-state (was 6e7ebbd).
Deleted branch rescue/my-work (was 57b5972).
$ cd ..
$ incidents/05-rebased-shared-branch/check.sh
Checking incident 05-rebased-shared-branch
  ok    the server still has the branch
  ok    "Add online lookup" is on the branch exactly once
  ok    "Decode online values" is on the branch exactly once
  ok    "Add cache warm-up job" is on the branch exactly once
  ok    "Add batched online lookup" is on the branch exactly once
  ok    "Decode batched values" is on the branch exactly once
  ok    the branch has five commits that main does not have
  ok    the branch contains no merge commit
  ok    the branch is based on the current main
  ok    store/batch.py decodes values
  ok    store/warm.py is on the branch
  ok    the branch in you/ equals the branch on the server
  ok    the branch in asha/ equals the branch on the server
PASS: the recovery of incident 05-rebased-shared-branch is complete.
[exit status: 0]
```
<!-- /snippet -->

The setting, the cleanup of the anchors after verification, and the check: each subject exactly once, five commits, no merge commit, both clones equal to the server.

**[TERMINAL]** Now the standard against the clock. Replay `labs/run incidents/lab-38-3-lease`. The same repair, with one difference: while you were rebuilding, Asha updated, committed and pushed.

**The lease refuses.**

<!-- snippet: incidents/lab-38-3-lease/01-lease-refuses -->
```text
# Meanwhile Asha updates her clone, commits and pushes:
$ cd asha
$ git pull -q --ff-only
$ git commit -q -m 'Report how many entries were warmed'
$ git push -q
# Step 9 in your clone, with the ID you examined:
$ cd ../you
$ git push --force-with-lease=feature/online-serving:6e7ebbd origin feature/online-serving
To ../server.git
 ! [rejected]        feature/online-serving -> feature/online-serving (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

"Stale info". The server's branch is no longer at the ID you examined. The lease did its job: it turned a silent overwrite into a refusal.

**The tempting move.** The lease is "in the way". 🔴 DANGEROUS: a bare `git push --force` sets the server's ref with no check.

<!-- snippet: incidents/lab-38-3-lease/02-failure -->
```text
# The tempting move: the lease is "in the way".
$ git push --force origin feature/online-serving
To ../server.git
 + cfee272...5366874 feature/online-serving -> feature/online-serving (forced update)
$ git log --oneline origin/main..origin/feature/online-serving
5366874 Decode batched values
7debded Add batched online lookup
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
```
<!-- /snippet -->

The push succeeds. Count the commits on the server's branch: five. Asha's new commit isn't among them.

**The recovery, in her clone.**

<!-- snippet: incidents/lab-38-3-lease/03-recovery -->
```text
# Her commit is no longer on the server. Her clone has it, and the standard instruction finds it:
$ cd ../asha
$ git fetch
From ../server
 + cfee272...5366874 feature/online-serving -> origin/feature/online-serving  (forced update)
$ git cherry -v origin/feature/online-serving feature/online-serving
+ be7fb7a56b83749158f537ff0bee349541ce09b5 Add online lookup
+ 8f79c4202b0823ed1b04cf7745b70954e9fcd554 Decode online values
+ 4967e71e446d83bc9c71b6ecb2b7fd6914bb6553 Add cache warm-up job
- af1f6de0a8d4796085edf1d3742e08f2132dbade Add batched online lookup
- 57b597270111c4042d1fc8182815e4bcded25138 Decode batched values
+ cfee272e6dafec360ef02e4e803b4c153eaf711a Report how many entries were warmed
$ git branch rescue/mine
$ git reset --keep origin/feature/online-serving
$ git cherry-pick rescue/mine
[feature/online-serving 37646e5] Report how many entries were warmed
 Date: Mon Sep 7 10:38:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 store/warm_metrics.py
$ git push
To ../server.git
   5366874..37646e5  feature/online-serving -> feature/online-serving
$ git log --oneline origin/main..origin/feature/online-serving
37646e5 Report how many entries were warmed
5366874 Decode batched values
7debded Add batched online lookup
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
$ git branch -D rescue/mine
Deleted branch rescue/mine (was cfee272).
```
<!-- /snippet -->

Her fetch reports a forced update. `git cherry` lists what her branch has that the server's lacks. The line that matters is the last one with a plus sign: `cfee272`, her commit. She anchors it, moves her branch to the server's with `--keep`, picks the one commit, and pushes: an ordinary fast-forward. Six commits on the server.

The lesson: when a lease refuses, the correct reaction is step 2 again. Fetch, look at what arrived, and rebuild on top of it. The refusal was information.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Calling it a display problem on GitHub.** Root cause: the commit list and the file view answer different questions; `git ls-remote` and a local log show that the nine commits are real.
2. **Blaming the lease or the rebase.** Root cause: the lease protects the server's commits, not unpublished commits in a teammate's clone, and the rebase changed no content; the merge pull joined the two series.
3. **Forcing the old series back.** Root cause: it undoes the teammate's rebase and makes her clone diverge, when only two commits needed to move.
4. **Rebasing onto the new tip without `--onto` and the old shared tip.** Root cause: without the boundary, Git treats the old copies of the shared commits as yours and replays them too.
5. **Replacing a refused lease with `--force`.** Root cause: the refusal means the server's branch moved after you examined it, and a bare force overwrites whatever moved it.

## PRODUCTION EXAMPLE

Now, out of the lab. Two engineers share a branch for an online feature store. One rebases it onto `main` on Wednesday evening and pushes with a lease. The other starts Thursday with `git pull` and `git push`, as always. At ten, a reviewer asks why the pull request has nine commits.

The second engineer leads the repair, by the eleven steps, and posts in the pull request before the forced push: "This branch will be force-pushed once in the next ten minutes; the diff will not change; do not push to it until I confirm." He reads the two reflogs, writes down three IDs, proves with `git range-diff` that the two series are the same changes, anchors two refs, rebuilds, proves that no content changed, and pushes with the lease naming the ID he examined.

His explanation is three sentences without blame, and the reviewers keep their review, because the diff is identical. The prevention has two parts. A setting, `pull.rebase true`, in the team's recommended configuration. And an agreement in the contribution guide: whoever rewrites a shared branch announces it first, with the old tip and the command teammates need.

## PRACTICE EXERCISE

Your turn. Do Lab 36.5, "A developer rebases a shared branch (incident 5)", in [`lab-manual/m36-incident-drills-local.md`](../../lab-manual/m36-incident-drills-local.md), from a freshly generated sandbox and with the eleven steps written down the side of your page.

Before step 4, predict where each of the three IDs will be found: which reflog, which entry. Before step 8, predict the commit count and the shape of the graph afterwards. Before step 9, write down the exact ID your lease will name and why. Type the recovery by hand.

The challenge is Lab 38.3, "Senior standard 1, against the clock: the rebased and force-pushed branch", in [`lab-manual/m38-communication-postmortems.md`](../../lab-manual/m38-communication-postmortems.md). Time it.

## INTERVIEW QUESTION

**[ON SCREEN]** Q378: "A pull request shows the same changed files as yesterday and three times as many commits. What happened, and which two comparisons explain why the views differ?"

**[PAUSE]**

Answer out loud. A strong answer names the mechanism in one sentence: which two series of commits became reachable from one tip, and through which ordinary command. It then names the two comparisons a pull request page makes, one over commits and one over content, in range notation, and explains why duplicated changes inflate one and not the other. It adds the evidence that would confirm the story on the developer's machine, and it doesn't blame the tool that was used correctly. If you finish with the repair in one sentence and the prevention in one more, you have answered at the senior standard.

## RECAP

Let's land this.

- A rewritten shared branch plus a merge pull in a clone that still has the originals makes every shared commit appear twice.
- The commit list is `main..head` and the file view is `main...head`; duplicates change the first and not the second.
- The senior standard is eleven steps, and the first six change nothing: state, refs, reflog, old state, what changed, preserve.
- The rebuild keeps the rebased series and replays only the unpublished commits with `git rebase --onto <rebased-tip> <old-shared-tip>`.
- The restoring push names the examined ID in its lease; a refused lease means look again, not force.

## HOMEWORK

Read sections 30.9 and 30.16. Then generate Incident 2, [`incidents/02-force-push-wrong-branch`](../../incidents/02-force-push-wrong-branch/SYMPTOMS.md), and Incident 4, [`incidents/04-production-history-rewritten`](../../incidents/04-production-history-rewritten/SYMPTOMS.md), and attempt both before the next video.

You've now carried a complete response through eleven steps, and the first six changed nothing. Practise it by hand, with the steps down the side of your page. Next time, two more reports: "The top commit on `main` says WIP", and "The deployed commit is not an ancestor of `production`". Until then, look at the state first and type second. See you in the next one.

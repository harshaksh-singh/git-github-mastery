# Incident 5: a shared branch was rebased — solution

> Read this only after your own attempt at [`incidents/05-rebased-shared-branch`](../incidents/05-rebased-shared-branch/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-05-rebased-shared-branch.sh`. Layers: everything that went wrong is Git; the pull request only displays it. Chapter 30, section 30.16 walks through this incident in the eleven steps of the senior standard.

## 1. Symptoms

The pull request for `feature/online-serving` lists nine commits where it had three (five with yours). Asha's commits appear twice. There is a merge commit "of ../server into feature/online-serving". The changed files look the same as before. Asha rebased and force-pushed with a lease yesterday; you pulled and pushed in the evening without an error.

## 2. Evidence

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

The two outputs explain why the reviewers disagree. The commit list is `main..head`: every commit reachable from the head and not from `main`, which is nine. The file view is `main...head`: the diff from the merge base to the head, which contains each change once, because two copies of the same change are one change in a tree ([Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), section 17.3).

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

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | GitHub displays stale data | `git ls-remote` and `git log main..head` locally | The nine commits are in the repository |
| 2 | Somebody reverted or undid the rebase | The reflog of `origin/feature/online-serving` | No: the rebased commits are all still there |
| 3 | The old series was merged back into the rebased series | A merge commit whose parents are the two series | Confirmed |

## 4. Diagnostic commands

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

Read the two reflogs together, bottom to top. Your branch fast-forwarded to `4967e71` (the shared tip), you made two commits, and then `pull: Merge made by the 'ort' strategy`. The remote-tracking branch shows why a merge was needed: `pull: forced-update` to `d4fd03c`. Asha's rebase had replaced the commits your work stood on. `pull.rebase` is `false`, so `git pull` merged the two histories.

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

`git range-diff` pairs the old series with the rebased one: three `=` lines, the same three changes under different IDs. The dates confirm it. A rebase keeps the author date and sets a new committer date ([Chapter 9: Rebase](../textbook/ch09-rebase.md), section 9.3): the copies were all committed at 10:29.

## 5. Root cause

```text
Observed behavior : every shared commit appears twice in the pull request, joined by a merge commit
Git state         : the server's branch was replaced by rebased copies while one clone held two unpublished commits on the originals
Mechanism         : "git pull" with pull.rebase=false merged the rebased series with the old one; both sets of commits became reachable
Root cause        : commits that another person had built on were rewritten, and the consumer integrated with a merge
Why Git does this : a rebased commit is a different object; Git compares IDs, so it cannot know that two commits are "the same change"
Correct fix       : keep the rebased series, replay only the two unpublished commits onto it, publish with an explicit lease
Prevention        : agree before rewriting a shared branch; pull.rebase=true (or pull.ff=only); announce the rewrite with the recovery command
```

`--force-with-lease` did its job and is not the cause. It protects the server from an overwrite of commits the pusher has not seen. It knows nothing about commits that exist only in a teammate's clone.

## 6. Safe recovery

Three states are worth a name before anything moves: the merged tip (so that the current state can be compared and restored), and your own tip from before the pull.

<!-- snippet: incidents/solve-05-rebased-shared-branch/07-preserve -->
```text
$ git branch rescue/merged-state feature/online-serving
$ git branch rescue/my-work 57b5972
```
<!-- /snippet -->

The target is the rebased series plus your two commits, each once. `git reset --keep` returns your branch to its value before the pull, which is a local move. `git rebase --onto <new base> <old base>` then replays what lies after the old base: exactly your two commits.

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

<!-- snippet: incidents/solve-05-rebased-shared-branch/09-check-result -->
```text
$ git range-diff 4967e71..rescue/my-work d4fd03c..feature/online-serving
1:  af1f6de = 1:  021ec35 Add batched online lookup
2:  57b5972 = 2:  5e4c03f Decode batched values
$ git diff --stat rescue/merged-state feature/online-serving
```
<!-- /snippet -->

Two proofs before publishing. The range-diff pairs your two commits with their copies (`=`). And the tree of the rebuilt branch is identical to the tree of the merged state: `git diff --stat` prints nothing. The rebuild changed history and no content.

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

The lease names `6e7ebbd`, the merged tip. If Asha had pushed in the meantime, the push would be refused.

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

Asha's clone was at the rebased tip, and the rebuilt branch descends from it. For her the repair is a fast-forward: no reset, no rebase.

## 7. Verification

The pull request view in snippet 10 lists five commits and the same three files. The check script confirms each subject exactly once, no merge commit, and both clones equal to the server.

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

## 8. Prevention

- A branch that more than one person commits to is rebased only by agreement, at a moment when everyone has pushed.
- `git config set pull.rebase true`: when the upstream was rewritten, `git pull --rebase` uses the reflog of the remote-tracking branch to find the old fork point and replays only your own commits ([Chapter 9](../textbook/ch09-rebase.md), sections 9.13 and 9.15). `pull.ff only` is the stricter choice: the pull stops and you decide.
- The person who rewrites announces it with the command teammates need: `git fetch && git rebase --onto origin/<branch> <old tip> <my branch>`.
- **GitHub:** the pull request's "Update branch" button merges or rebases the base into the head on the server; after using it, everyone else must fetch before committing ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.7).

## 9. Communication

To Asha: "Nobody undid your rebase. My `git pull` merged your rebased commits with the old ones I still had, and I pushed the result. I rebuilt the branch as your three commits plus my two and force-pushed with a lease. `git pull --ff-only` brings you up to date; you lose nothing."

To the reviewers: "The pull request is back to five commits. The changed files never differed; reviews of the diff stay valid. Review comments attached to the removed commits may show as outdated."

To the CTO, if the pull request was blocking a release: "A history mix-up on one feature branch duplicated commits in a pull request for [duration]. No code changed and nothing was lost; `main` was not involved. We are changing a pull default so that the same sequence stops instead of merging."

## 10. Postmortem

- **Severity:** low. One topic branch, no content change, reviewers delayed.
- **What went well:** the tree comparison proved that content was intact before and after.
- **What went badly:** a `git pull` that reported no error produced a nine-commit history, and the result was pushed without reading `git log --graph`.
- **Actions:** `pull.rebase true` in the team's setup script; a rule of thumb in the handbook: after any pull that prints "Merge made", look at the graph before pushing.

# Incident 9: a misunderstood merge conflict — solution

> Read this only after your own attempt at [`incidents/09-misunderstood-conflict`](../incidents/09-misunderstood-conflict/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-09-misunderstood-conflict.sh`. Layer: Git. GitHub merged what it was given.

## 1. Symptoms

Two reviewed fixes by Asha (a cap at `BURST`, a lower default rate) are absent from `limiter/bucket.py` on `main`. Her commits are in `git log main`. There is no revert commit. `git log -- limiter/bucket.py` does not list her commits. Ravi resolved a conflict in that file and "kept ours".

## 2. Evidence

<!-- snippet: incidents/solve-09-misunderstood-conflict/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ cat limiter/bucket.py
DEFAULT_RATE = 100
BURST = 200


def allow(key, now):
    bucket = buckets.get(key)
    refill(bucket, now, rate_for(key))
    return bucket.take(1)


def refill(bucket, now, rate):
    bucket.tokens = bucket.tokens + (now - bucket.ts) * rate
    bucket.ts = now
```
<!-- /snippet -->

No `min(BURST, ...)`, and the rate is 100.

<!-- snippet: incidents/solve-09-misunderstood-conflict/02-commits-are-there -->
```text
$ git log --format='%h %an: %s' --author=Asha main
8a11540 Asha Rao: Halve the default rate after the overload
bfd1f07 Asha Rao: Cap the bucket at BURST tokens
$ git merge-base --is-ancestor 8a11540 main
[exit status: 0]
$ git log --oneline --grep='^Revert' main
[exit status: 0]
```
<!-- /snippet -->

Both commits are ancestors of `main` (exit status 0) and no commit subject starts with "Revert". So the commits are in the history and their effect is not in the file. Only one kind of commit can do that without leaving a diff of its own in the usual views: a merge.

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | The repository is corrupt | `git fsck` would report it; the file is readable and consistent | No sign of it |
| 2 | Someone reverted the commits | A revert commit, or a later commit touching those lines | None |
| 3 | A later ordinary commit overwrote the lines | `git log --full-history -p -- limiter/bucket.py` | No ordinary commit after hers touches the file |
| 4 | A merge resolution discarded her side | Compare a merge with what Git would have produced | Confirmed |

## 4. Diagnostic commands

<!-- snippet: incidents/solve-09-misunderstood-conflict/03-log-hides-them -->
```text
# The command Asha ran, and the same command without history simplification:
$ git log --oneline -- limiter/bucket.py
f8435ea Look up the rate per tenant
d40b668 Add token bucket limiter
$ git log --oneline --full-history -- limiter/bucket.py
fb67f49 Merge pull request #17 from feature/per-tenant-limits
d7497e2 Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits
8a11540 Halve the default rate after the overload
bfd1f07 Cap the bucket at BURST tokens
f8435ea Look up the rate per tenant
d40b668 Add token bucket limiter
```
<!-- /snippet -->

This is the command that misled Asha. With a path, `git log` simplifies history: at a merge whose result for that path is identical to one parent, it follows only that parent, because the other side "contributed nothing" to the file as it is now. Her commits are on the side that was thrown away, so the default view hides exactly the commits whose loss you are investigating. `--full-history` switches the simplification off ([Chapter 14A: History Investigation](../textbook/ch14a-history-investigation.md), section 14A.9).

<!-- snippet: incidents/solve-09-misunderstood-conflict/04-graph -->
```text
$ git log --oneline --graph
* fc1898f Add limiter metrics
*   fb67f49 Merge pull request #17 from feature/per-tenant-limits
|\  
| *   d7497e2 Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits
| |\  
| |/  
|/|   
* | 8a11540 Halve the default rate after the overload
* | bfd1f07 Cap the bucket at BURST tokens
| * f8435ea Look up the rate per tenant
|/  
* 6ac34e3 Add README
* d40b668 Add token bucket limiter
```
<!-- /snippet -->

Two merges. `fb67f49` is the pull request. `d7497e2` is Ravi bringing `main` into his branch, the one with the conflict.

<!-- snippet: incidents/solve-09-misunderstood-conflict/05-audit -->
```text
# What did the person who made this merge change, compared with what Git would have produced?
$ git show --remerge-diff --format='%h %an: %s' d7497e2
d7497e2 Ravi Menon: Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits

diff --git a/limiter/bucket.py b/limiter/bucket.py
remerge CONFLICT (content): Merge conflict in limiter/bucket.py
index ebfcaa2..771c807 100644
--- a/limiter/bucket.py
+++ b/limiter/bucket.py
@@ -1,8 +1,4 @@
-<<<<<<< f8435ea (Look up the rate per tenant)
 DEFAULT_RATE = 100
-=======
-RATE = 50
->>>>>>> 8a11540 (Halve the default rate after the overload)
 BURST = 200
 
 
@@ -13,5 +9,5 @@ def allow(key, now):
 
 
 def refill(bucket, now, rate):
-    bucket.tokens = min(BURST, bucket.tokens + (now - bucket.ts) * rate)
+    bucket.tokens = bucket.tokens + (now - bucket.ts) * rate
     bucket.ts = now
```
<!-- /snippet -->

`git show --remerge-diff` re-runs the merge in memory and shows the difference between that mechanical result and the commit that was recorded: what the human did. Read it as a diff from "what Git produced" to "what was committed".

- In the conflict hunk the human removed the markers and Asha's `RATE = 50`, keeping `DEFAULT_RATE = 100`. That was a real conflict, and the choice was wrong but visible.
- In the second hunk there was **no conflict**. Git had merged Asha's `min(BURST, ...)` cleanly. The human's commit replaces it with the old line. A resolution that touches a hunk Git had already merged is the signature of taking one side of the whole file.

<!-- snippet: incidents/solve-09-misunderstood-conflict/06-confirm -->
```text
# The file in the merge result, compared with each parent:
$ git diff --stat d7497e2^1 d7497e2 -- limiter/bucket.py
$ git diff --stat d7497e2^2 d7497e2 -- limiter/bucket.py
 limiter/bucket.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git -C ../ravi reflog -4 --format='%h %gs'
fb67f49 merge feature/per-tenant-limits: Merge made by the 'ort' strategy.
8a11540 pull: Fast-forward
6ac34e3 checkout: moving from feature/per-tenant-limits to main
d7497e2 commit (merge): Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits
```
<!-- /snippet -->

The file in the merge is identical to the first parent, and Ravi's reflog shows the merge commit. `git checkout --ours limiter/bucket.py` replaces the whole file with the version of the current branch, non-conflicting hunks included.

## 5. Root cause

```text
Observed behavior : two merged fixes are in the history of main and not in the file
Git state         : merge d7497e2 records, for limiter/bucket.py, exactly the content of its first parent
Mechanism         : "git checkout --ours <file>" during a merge writes the current branch's whole file; the merge commit then
                    declares that version to be the combination of both sides
Root cause        : "ours" was read as "the team's version (main)". In a merge, "ours" is the branch you are on: here the feature branch
Why Git does this : a merge commit's tree is whatever you commit; Git does not verify that a resolution keeps both sides' changes
Correct fix       : a new commit on main that restores the two changes, adapted to the renamed constant
Prevention        : resolve hunks, not files; review merges with --remerge-diff; a test that pins the behavior
```

"Ours" and "theirs" are positions, not ownership: in `git merge X`, ours is HEAD and theirs is `X`; in a rebase they are swapped ([Chapter 8: Merge](../textbook/ch08-merge.md), sections 8.8 and 8.15; [Chapter 9: Rebase](../textbook/ch09-rebase.md), section 9.11).

## 6. Safe recovery

`main` is shared and two merges plus a later commit sit on top of the faulty resolution. Rewriting `main` to redo the merge would replace four published commits. Reverting the merge would remove Ravi's feature. The lowest-risk fix adds one commit.

<!-- snippet: incidents/solve-09-misunderstood-conflict/07-fix -->
```text
$ git switch -c fix/restore-overload-fix
Switched to a new branch 'fix/restore-overload-fix'
# (edit limiter/bucket.py: DEFAULT_RATE = 50, and the min(BURST, ...) cap in refill)
$ git diff
diff --git a/limiter/bucket.py b/limiter/bucket.py
index 771c807..6eeda30 100644
--- a/limiter/bucket.py
+++ b/limiter/bucket.py
@@ -1,4 +1,4 @@
-DEFAULT_RATE = 100
+DEFAULT_RATE = 50
 BURST = 200
 
 
@@ -9,5 +9,5 @@ def allow(key, now):
 
 
 def refill(bucket, now, rate):
-    bucket.tokens = bucket.tokens + (now - bucket.ts) * rate
+    bucket.tokens = min(BURST, bucket.tokens + (now - bucket.ts) * rate)
     bucket.ts = now
$ git commit -a -m 'Restore the burst cap and the lowered default rate' -m 'Merge d7497e2 resolved a conflict in limiter/bucket.py by keeping one side of the whole file, which discarded bfd1f07 and 8a11540.'
[fix/restore-overload-fix ea9eb30] Restore the burst cap and the lowered default rate
 1 file changed, 2 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

The resolution Ravi should have made: keep his rename and lookup, take Asha's value (`DEFAULT_RATE = 50`) and her cap. The commit message names the merge and the two commits, so that `git log --grep` finds the connection later.

## 7. Verification

<!-- snippet: incidents/solve-09-misunderstood-conflict/08-verify -->
```text
# Against Asha's version the file must differ only by Ravi's rename and lookup:
$ git diff 8a11540 fix/restore-overload-fix -- limiter/bucket.py
diff --git a/limiter/bucket.py b/limiter/bucket.py
index 49ded53..6eeda30 100644
--- a/limiter/bucket.py
+++ b/limiter/bucket.py
@@ -1,10 +1,10 @@
-RATE = 50
+DEFAULT_RATE = 50
 BURST = 200
 
 
 def allow(key, now):
     bucket = buckets.get(key)
-    refill(bucket, now, RATE)
+    refill(bucket, now, rate_for(key))
     return bucket.take(1)
 
 
```
<!-- /snippet -->

Against Asha's last version, the fixed file differs only by Ravi's two intended changes. That is the definition of a correct resolution: each side's diff is fully present.

<!-- snippet: incidents/solve-09-misunderstood-conflict/09-land -->
```text
$ git push -u origin fix/restore-overload-fix
To ../server.git
 * [new branch]      fix/restore-overload-fix -> fix/restore-overload-fix
branch 'fix/restore-overload-fix' set up to track 'origin/fix/restore-overload-fix'.
# After review (a pull request on GitHub):
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git merge --ff-only fix/restore-overload-fix
Updating fc1898f..ea9eb30
Fast-forward
 limiter/bucket.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git push
To ../server.git
   fc1898f..ea9eb30  main -> main
$ git log --oneline -3
ea9eb30 Restore the burst cap and the lowered default rate
fc1898f Add limiter metrics
fb67f49 Merge pull request #17 from feature/per-tenant-limits
$ cd ..
$ incidents/09-misunderstood-conflict/check.sh
Checking incident 09-misunderstood-conflict
  ok    bucket.py on main caps the bucket at BURST
  ok    bucket.py on main has the lowered default rate under its new name
  ok    bucket.py on main still looks up the rate per tenant
  ok    bucket.py on main has no leftover "RATE = 50" or "DEFAULT_RATE = 100"
  ok    bucket.py on main has no conflict markers
  ok    limiter/tenants.py is still on main
  ok    main still has "Cap the bucket at BURST tokens" (history was not rewritten)
  ok    main still has "Halve the default rate after the overload" (history was not rewritten)
  ok    main still has "Look up the rate per tenant" (history was not rewritten)
  ok    main still has "Merge pull request #17 from feature/per-tenant-limits" (history was not rewritten)
  ok    main still has "Add limiter metrics" (history was not rewritten)
  ok    the faulty merge is still in the history of main
PASS: the recovery of incident 09-misunderstood-conflict is complete.
[exit status: 0]
```
<!-- /snippet -->

The history of `main` is intact, including the faulty merge: an incident record needs it.

## 8. Prevention

- Resolve conflicts hunk by hunk in the file. `--ours` and `--theirs` for a path are for the case where one side's entire file is right, and that is rare.
- `git config set merge.conflictStyle zdiff3` shows the common ancestor in each conflict, which makes "what did each side change" readable ([Chapter 8](../textbook/ch08-merge.md), section 8.9).
- Review a merge commit with `git show --remerge-diff <merge>` before pushing it. An empty output means the merge is exactly what Git computed.
- A test for the cap would have failed on Ravi's branch. Green tests on the branch proved only that nothing tested the fix.
- **GitHub:** the pull request diff `main...feature` could not show the loss, because after the bad merge the feature branch and the merge base agreed on those lines.

## 9. Communication

To Asha and Ravi together: "The repository is fine and nobody reverted anything. When `main` was merged into the per-tenant branch, the conflict in `bucket.py` was resolved by taking the branch's whole file. That dropped both of Asha's changes, one of which had not even conflicted. `git log -- <file>` hides commits on a side that a merge discarded; `--full-history` shows them. The fix is one commit on `main`, reviewed by both of you."

To the CTO: "Last night's overload was the same defect as last week's. The fix had been merged and was removed afterwards by an incorrect conflict resolution on another branch; review could not see it because the removal was inside a merge commit. It is restored. We are adding a regression test for the cap and a review step for merge commits."

## 10. Postmortem

- **Severity:** high. A production fix was silently undone and the incident recurred.
- **Detection:** by the outage, not by any control.
- **Why it made sense:** "keep ours" sounds like "keep the team's code"; the branch's tests passed; the pull request looked normal.
- **Actions:** regression test (owner: Asha); `--remerge-diff` in the review checklist for any pull request that contains a merge from the base; `zdiff3` in the team configuration; a short session on what ours and theirs mean in merge and in rebase.

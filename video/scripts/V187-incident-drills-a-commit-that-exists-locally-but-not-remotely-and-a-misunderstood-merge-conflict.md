# V187: Incident drills: a commit that exists locally but not remotely, and a misunderstood merge conflict

- **Part.** 9, Production debugging and incident response
- **Module.** 36
- **Planned minutes.** 24
- **Prerequisites.** V037, V044, V186
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.13 and 30.14
- **Demo scripts.** `labs/incidents/solve-10-commit-local-not-remote.sh` (snippets `01-ravi-is-right` to `07-verify`), `labs/incidents/solve-09-misunderstood-conflict.sh` (snippets `01-observe` to `09-land`)

## HOOK

**[ON SCREEN]** Two disputes. "It is pushed. GitHub must be caching." And: "My fix is in the log and not in the file."

In both, two competent people disagree about a fact, and each has output on the screen that supports them. A commit is one saved snapshot of the project, and a push sends commits to a server. A release candidate lacks a fix that its author can show in `git log`, with a status that says up to date and a push that printed `main -> main`. And two reviewed, merged fixes are missing from a file, while their commits are in the history of `main`, the team's shared branch, and nobody reverted anything, that is, nobody added a commit that undoes them.

A dispute like this doesn't end when one person wins. It ends when you produce evidence that both parties accept.

Quick quiz, before any cause is named. The author of the first fix has three things on his screen: the commit in `git log`, a status that says up to date, and a push that printed `main -> main`. Which one proves that the fix is on the team's server? A, the log. B, the status. C, the push line. Or D, none of them. Your answer?

**[PAUSE]**

Keep your answer. It's settled as soon as the cause is on the table.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a debrief of Incident 10, [`incidents/10-commit-local-not-remote`](../../incidents/10-commit-local-not-remote/SYMPTOMS.md), and Incident 9, [`incidents/09-misunderstood-conflict`](../../incidents/09-misunderstood-conflict/SYMPTOMS.md). You must have generated and attempted both. Have you? If you haven't, stop the video here and do that first.

**[PAUSE]**

The causes are named in the next section.

Both incidents rest on mechanisms you learned long ago. From video 44: a remote name is a local alias, and `git ls-remote` asks a server directly. A remote is a name in your clone that stands for another repository. From video 37: a merge can be clean for Git and wrong for humans, and `--remerge-diff` shows what the person who made the merge changed.

What the drills add is the human shape of the problem. In Incident 10 the developer is right about everything he says. In Incident 9 the developer who lost her fixes searched correctly, with a command whose default view hides exactly the commits under investigation.

## LEARNING OBJECTIVES

After this video you can:

1. Give the states that produce "Everything up-to-date" while the commit is not on the server.
2. Prove which server and which ref a push went to.
3. Explain how a fix can be in `git log` and not in the file.
4. Show what a merge resolution discarded with `--remerge-diff` and `--full-history`.
5. Repair both with additive changes.

## CONCEPT

**Incident 10: "on the server" has a hidden parameter.** Which server. Everything Ravi said is confirmed in his clone. The commit is in his log. `git status` says up to date with `origin/main`. The push printed `main -> main`.

The textbook's hypotheses are also the general list of states that produce "it is pushed" or "Everything up-to-date" while the commit isn't where the team looks. It was never pushed, and `git status -sb` would show `ahead`. It was pushed to another branch. It was made in detached HEAD, as in video 180. `origin` isn't the repository the team means. Or the platform shows stale data.

**The root cause.** `origin` in this clone is Ravi's old fork, his personal copy of the repository on the server, and `main` follows `origin/main`. A remote name is a local alias. Every local signal was true about the fork. Layer: Git configuration.

**What counts as proof of a push.** First, the quiz from the opening: D, none of the three. Proof is the `To <url>` line of the push output, `git ls-remote`, or the commit's page in the team repository. Never `git status`: it compares with a remote-tracking ref, which is this clone's memory of whatever `origin` means here.

**[ANIMATION]** graph: 6e16f60-133c159-f3bb790 main origin/main; 133c159-ebd3afc upstream/main; HEAD=main => 6e16f60-133c159-f3bb790 origin/main; 133c159-ebd3afc-d676c20 main upstream/main; HEAD=main title=The_fix_goes_on_top_of_the_team's_main

**[ANIMATION]** step: state-1

**The recovery is additive.** The team repository has moved on, so the fix goes on top of its `main`, on a branch, as a pull request requires. A pull request is GitHub's proposal to merge a branch.

**[ANIMATION]** step: state-2

Then the clone is repaired so that it can't happen again: `main` follows the team repository.

**[ANIMATION]** end

**Incident 9: a commit can be in the history while its effect is not in the file.** `git merge-base --is-ancestor <her commit> main` exits 0, and no subject starts with "Revert". The commits are in the history and their effect isn't in the file. Only a merge can do that without a diff of its own in the usual views.

**Why her own search found nothing.** With a path, `git log` simplifies history: at a merge whose result for the path equals one parent, it follows only that parent. Her commits are on the discarded side, so the default view hides exactly the commits under investigation. `--full-history` switches the simplification off.

**The audit of a merge.** `git show --remerge-diff` re-runs the merge and shows what the human changed relative to Git's mechanical result. A hunk is one block of changed lines. A resolution that changes a hunk Git had already merged cleanly is the signature of taking one side of the whole file.

**The root cause.** `git checkout --ours limiter/bucket.py`. "Ours" was read as "the team's version". In `git merge X`, ours is the branch you're on, here the feature branch. In a rebase the roles are swapped. Layer: Git. GitHub merged what it was given.

**The recovery is additive here too.** `main` is shared and four commits sit on the faulty merge, so nothing is rewritten and nothing is reverted: a revert of the merge would remove Ravi's feature. One new commit restores both changes, adapted to his rename, and its message names the merge and the two lost commits.

**How you know the result is right.** A correct resolution contains each side's diff completely. So compare the fixed file with Asha's last version: the only differences must be Ravi's two intended changes.

**Severity.** Incident 10 is SEV 3: a team was blocked, no wrong content on a protected branch. Incident 9 is SEV 2: a merged fix was silently lost on the shared default branch.

## MENTAL MODEL

A picture helps. For Incident 10, picture the word "origin" as a label on a speed-dial button. Everyone on the team has a button with that label. Nothing guarantees that the buttons dial the same number. Ravi pressed "origin" and the call went through. The person he reached confirmed everything. It wasn't the office.

Where the picture breaks: a phone tells you nothing about who answered, and Git does. The push output begins with a line that says `To` and a URL. It was on Ravi's screen. Nobody reads that line.

Try it now. Thirty seconds, read-only. In any clone you have, run `git remote -v`, and read out the URL beside each name.

**[PAUSE]**

That URL is the number your button dials. If you can say whose repository it is, good. If you can't, you've found Ravi's situation in your own clone, before it cost you a release.

For Incident 9, picture a merge commit as a form with two columns, one per parent, and a third column for the result. For most lines the result column is filled in by Git. Where both sides changed the same lines, a human fills it in. `--remerge-diff` shows you only the cells where the human's entry differs from what Git would have written. In this incident a human overwrote a cell that Git had already filled in correctly.

And one sentence for both: the tools told the truth. `git status` told the truth about the fork. `git log -- <file>` told the truth about the simplified history. The question each person asked wasn't the question they needed answered.

## DIAGRAM

**[DIAGRAM]** Incident 10: two remotes and one clone. Draw the clone at the bottom with its one branch, then the two servers above it, and the arrow for the push. IDs are from the transcript.

```text
     origin = ../ravi-fork.git                     upstream = ../server.git  (the team repository)
   +----------------------------+                +----------------------------------+
   | main  f3bb790  (the fix)   |                | main  ebd3afc  (no fix; one newer |
   +----------------------------+                |                commit by a mate) |
              ^                                  +----------------------------------+
              | git push   ("main -> main")                     ^
              |                                                 |  where Asha is looking
   +-----------------------------------------------------------------------------+
   | ravi's clone:   main f3bb790   [origin/main]     status: up to date          |
   +-----------------------------------------------------------------------------+
```

Every local signal points at the left box. The release is built from the right box.

**[DIAGRAM]** Incident 9: a merge commit with a discarded side. Draw `main` with Asha's two fixes, the feature branch with Ravi's commit, the merge of `main` into the feature branch, and then the pull request merge.

```text
                 f8435ea-----------------d7497e2        feature/per-tenant-limits
                /  (Ravi: rate per       /  ^   \
               /    tenant)             /   |    \
   ---6ac34e3---bfd1f07---8a11540------+----|-----fb67f49---fc1898f   main
               (Asha: cap) (Asha: halve     |     (merge of the pull request)
                            the rate)       |
                                            +-- resolved with "ours" for the whole file:
                                                the file equals f8435ea's side;
                                                the changes of bfd1f07 and 8a11540 are discarded
```

Both of Asha's commits are ancestors of `main`: follow the lines. And the file at `d7497e2` equals its first parent's version. Ancestry kept, content discarded.

## LIVE TERMINAL DEMO

From here on the screen shows the solutions. Is your own command log beside you?

**[PAUSE]**

Then compare as we go.

**[TERMINAL]** Replay `labs/run incidents/solve-10-commit-local-not-remote`. We sit at Ravi's clone. Everything until the publish step is 🟢 SAFE.

**Ravi is right.**

```bash
git status -sb
git log --oneline -2
git branch -r --contains HEAD
```

<!-- snippet: incidents/solve-10-commit-local-not-remote/01-ravi-is-right -->
```text
$ cd ravi
$ git status -sb
## main...origin/main
$ git log --oneline -2
f3bb790 Guard against NaN in score aggregation
133c159 Add accuracy panel
$ git branch -r --contains HEAD
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

Up to date with `origin/main`. The fix `f3bb790` is the tip. And `origin/main` contains it. Say that to Ravi first: everything you told us is confirmed.

**Which server?** Predict what `git remote -v` will show. Say it out loud.

**[PAUSE]**

```bash
git remote -v
git branch -vv
git reflog show origin/main
git ls-remote origin main
git ls-remote upstream main
```

<!-- snippet: incidents/solve-10-commit-local-not-remote/02-which-server -->
```text
$ git remote -v
origin	../ravi-fork.git (fetch)
origin	../ravi-fork.git (push)
upstream	../server.git (fetch)
upstream	../server.git (push)
$ git branch -vv
* main f3bb790 [origin/main] Guard against NaN in score aggregation
$ git reflog show origin/main
f3bb790 refs/remotes/origin/main@{0}: update by push
# Ask each server directly, without relying on any remote-tracking ref:
$ git ls-remote origin main
f3bb79056b4293f31ae8479851be75b1f71339a6	refs/heads/main
$ git ls-remote upstream main
ebd3afc65730975fcbd60abdc9302003fe8e5843	refs/heads/main
```
<!-- /snippet -->

Two remotes. `origin` is a fork. `upstream` is the server the team uses. `git ls-remote` asks each server directly and bypasses every remote-tracking ref: the fork has `f3bb790`, the team repository has `ebd3afc`. Both people were right, about different repositories.

**The team repository has moved on.**

<!-- snippet: incidents/solve-10-commit-local-not-remote/03-team-repository -->
```text
$ git fetch upstream
From ../server
   133c159..ebd3afc  main       -> upstream/main
$ git log --oneline --graph main upstream/main
* f3bb790 Guard against NaN in score aggregation
| * ebd3afc Show p95 latency on the dashboard
|/  
* 133c159 Add accuracy panel
* 6e16f60 Add score aggregation
$ git log --format='%h %an: %s' main..upstream/main
ebd3afc Lab User: Show p95 latency on the dashboard
```
<!-- /snippet -->

One commit by a colleague that Ravi's `main` lacks. So his fix can't be pushed to the team's `main` as it is, and it shouldn't go there without a pull request anyway.

**Publish.** 🟡 CAUTION: `git rebase` replaces one unpublished commit with a new one. The push creates a new branch.

```bash
git switch -c fix/nan-aggregation
git rebase upstream/main
git push -u upstream fix/nan-aggregation
git log --oneline upstream/main..upstream/fix/nan-aggregation
git diff --stat upstream/main...upstream/fix/nan-aggregation
```

<!-- snippet: incidents/solve-10-commit-local-not-remote/04-publish -->
```text
$ git switch -c fix/nan-aggregation
Switched to a new branch 'fix/nan-aggregation'
$ git rebase upstream/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/fix/nan-aggregation.
$ git push -u upstream fix/nan-aggregation
To ../server.git
 * [new branch]      fix/nan-aggregation -> fix/nan-aggregation
branch 'fix/nan-aggregation' set up to track 'upstream/fix/nan-aggregation'.
# What the pull request into main of the team repository would show:
$ git log --oneline upstream/main..upstream/fix/nan-aggregation
d676c20 Guard against NaN in score aggregation
$ git diff --stat upstream/main...upstream/fix/nan-aggregation
 dashboard/aggregate.py | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

The fix is now `d676c20`, on top of the team's `main`, on a branch in the team repository. The last two commands are what the pull request would show: one commit, one file. The merge of the pull request is simulated in the lab as a fast-forward on the server.

<!-- snippet: incidents/solve-10-commit-local-not-remote/05-land -->
```text
# The merge of the pull request, simulated as a fast-forward of main on the server:
$ git push upstream fix/nan-aggregation:main
To ../server.git
   ebd3afc..d676c20  fix/nan-aggregation -> main
```
<!-- /snippet -->

**Repair the clone.** The cause is still in place: `main` follows the fork. 🟡 CAUTION: `git reset --keep` moves the branch and refuses if a file with local changes would be overwritten. Before it, one check: is anything on this `main` that the team repository lacks?

```bash
git switch main
git branch --set-upstream-to=upstream/main main
git status -sb
git cherry -v upstream/main main
git reset --keep upstream/main
git config set remote.pushDefault upstream
git branch -vv
```

<!-- snippet: incidents/solve-10-commit-local-not-remote/06-repair-clone -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git branch --set-upstream-to=upstream/main main
branch 'main' set up to track 'upstream/main'.
$ git status -sb
## main...upstream/main [ahead 1, behind 2]
# Is anything on my main that the team repository lacks? "-" means it has an equivalent.
$ git cherry -v upstream/main main
- f3bb79056b4293f31ae8479851be75b1f71339a6 Guard against NaN in score aggregation
$ git reset --keep upstream/main
$ git config set remote.pushDefault upstream
$ git branch -vv
  fix/nan-aggregation d676c20 [upstream/fix/nan-aggregation] Guard against NaN in score aggregation
* main                d676c20 [upstream/main] Guard against NaN in score aggregation
```
<!-- /snippet -->

After the upstream change, the status tells the truth at once: ahead 1, behind 2. `git cherry` marks the old commit with a minus sign: the team repository has an equivalent. Only then is the branch moved.

**Verify.**

<!-- snippet: incidents/solve-10-commit-local-not-remote/07-verify -->
```text
$ git ls-remote upstream
d676c206fb0baceaeede6d7fc44a7f94379d26b1	HEAD
d676c206fb0baceaeede6d7fc44a7f94379d26b1	refs/heads/fix/nan-aggregation
d676c206fb0baceaeede6d7fc44a7f94379d26b1	refs/heads/main
$ git log --oneline upstream/main
d676c20 Guard against NaN in score aggregation
ebd3afc Show p95 latency on the dashboard
133c159 Add accuracy panel
6e16f60 Add score aggregation
$ git branch -d fix/nan-aggregation
Deleted branch fix/nan-aggregation (was d676c20).
$ cd ..
$ incidents/10-commit-local-not-remote/check.sh
Checking incident 10-commit-local-not-remote
  ok    main of the team repository has "Add score aggregation" exactly once
  ok    main of the team repository has "Add accuracy panel" exactly once
  ok    main of the team repository has "Show p95 latency on the dashboard" exactly once
  ok    main of the team repository has "Guard against NaN in score aggregation" exactly once
  ok    dashboard/aggregate.py on main filters NaN
  ok    dashboard/panels.py on main still shows p95 latency
  ok    in ravi/, main follows upstream/main (the team repository)
  ok    main in ravi/ equals main of the team repository
PASS: the recovery of incident 10-commit-local-not-remote is complete.
[exit status: 0]
```
<!-- /snippet -->

`git ls-remote upstream`, asked of the server itself, and the check passes: each commit exactly once on the team's `main`, and in Ravi's clone `main` follows the team repository.

**[TERMINAL]** Replay `labs/run incidents/solve-09-misunderstood-conflict`. We sit at our own clone.

**Observe.**

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

The file on `main`: a default rate of 100 and no cap in `refill`. Asha's two fixes lowered the rate and capped the bucket.

**The commits are there.**

```bash
git log --format='%h %an: %s' --author=Asha main
git merge-base --is-ancestor 8a11540 main
git log --oneline --grep='^Revert' main
```

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

Both commits are on `main`, the ancestry test exits 0, and there's no revert. Corruption, a revert and "never merged" are ruled out by three lines.

**Why her search found nothing.** Predict how many commits each command lists. Say it out loud.

**[PAUSE]**

```bash
git log --oneline -- limiter/bucket.py
git log --oneline --full-history -- limiter/bucket.py
```

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

Two commits against six. The default view follows only the parent whose version of the file the merge kept. With `--full-history`, her two commits and two merges appear.

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

**[ANIMATION]** graph: d40b668-6ac34e3-bfd1f07-8a11540-fb67f49-fc1898f main origin/main; 6ac34e3-f8435ea-d7497e2; 8a11540-d7497e2; d7497e2-fb67f49; HEAD=main title=A_merge_before_the_merge

The graph shows the merge of `origin/main` into the feature branch, `d7497e2`, before the pull request was merged. That's the candidate.

**The audit.**

```bash
git show --remerge-diff --format='%h %an: %s' d7497e2
```

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

Read the two hunks before I do. Which of them had no conflict at all? Say it out loud.

**[PAUSE]**

The second. Two hunks. The first was a real conflict, resolved for one side: the rate. The second had no conflict. Git had merged the cap cleanly, and the recorded merge removes it. That second hunk is the signature of taking one side of the whole file.

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

Confirmation: the file in the merge equals its first parent's version exactly, and differs from the second parent's. And the reflog in Ravi's clone shows the merge commit being made there.

**The fix: one forward commit.** 🟢 SAFE: a commit on a new branch.

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

Both changes are restored, the rate under Ravi's new name. Read the commit message: it names the merge and the two commits whose changes were discarded. A future reader of `git blame`, which shows the commit behind each line, will find the story.

**Verify.** Predict: compared with Asha's last version, how should the fixed file differ?

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

Only by Ravi's rename and his per-tenant lookup. Each side's change is present completely.

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

The fix lands through review, `main` is fast-forwarded, and the check passes. Read the lower half of the check: history wasn't rewritten, and the faulty merge is still in the history of `main`.

**The messages.** To Ravi and Asha, Incident 10: every command Ravi quoted told the truth about another repository. Incident 9, to both: the repository is intact, nobody reverted anything, and why `git log -- <file>` hid it. To the CTO: the outage recurred because a merged fix was removed inside a merge commit, where review couldn't see it.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Taking `git status` as proof of a push.** Root cause: it compares with a remote-tracking ref, which records this clone's last contact with whatever its remote name points at.
2. **Assuming `origin` means the same repository in every clone.** Root cause: a remote name is a local alias chosen at clone time or later.
3. **Searching for lost changes with `git log -- <path>` alone.** Root cause: history simplification follows only the parent whose version a merge kept, which hides the discarded side.
4. **Reading "ours" as "the team's version".** Root cause: in a merge, ours is the branch you are on; resolving a whole file for one side also discards the other side's cleanly merged hunks.
5. **Reverting the faulty merge on a shared branch.** Root cause: the revert removes the whole feature that the merge brought in, when one forward commit restores what was lost.

## PRODUCTION EXAMPLE

Now, out of the lab. A rate limiter on an inference gateway was tuned after an overload: the default rate halved, the bucket capped. Three weeks later the same overload happens again. The on-call engineer finds both fixes in the history of `main` and neither in the file.

He doesn't look for a culprit. He runs the path-limited log, sees that it lists too little, adds `--full-history`, and finds a merge of `main` into a feature branch in the list. `git show --remerge-diff` on that merge shows a hunk that had no conflict and was changed anyway. The colleague who made the merge remembers it: a conflict in one line, and "I kept ours, because ours is what the team has."

The repair is one commit with a message that names the merge. The summary for the CTO names the layer and the reason review missed it: after the bad merge, the branch and the merge base, the common starting point of the two sides, agreed on those lines, so the pull request diff couldn't show the loss. The control is a regression test for the cap, which would have failed on the feature branch, and a line in the review guide: a merge commit on a pull request branch is reviewed with `--remerge-diff` before it's pushed.

## PRACTICE EXERCISE

Your turn. Do Lab 36.3, "A commit exists locally but not remotely (incident 10)", in [`lab-manual/m36-incident-drills-local.md`](../../lab-manual/m36-incident-drills-local.md), from a freshly generated sandbox.

Before you run anything, write down three states that would produce the reported symptom, and for each the one read-only command that would separate it from the others. Before you repair Ravi's clone, predict what `git status -sb` will print immediately after the upstream is changed. Type the recovery by hand.

The challenge is Lab 36.4, "A merge conflict is misunderstood (incident 9)", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q402: "`git push` prints "Everything up-to-date" and the commit is not on the server. Give three states that produce this and the command that separates them."

**[PAUSE]**

Answer out loud. A strong answer gives three states that differ in kind, for example one about HEAD, one about which branch, one about which repository, and not three variations of one. For each state it explains, in terms of refs, why the message is true. And it gives one command per state whose output distinguishes it from the other two, preferring commands that ask the server directly over commands that read the clone's memory of it. Close with what you accept as proof that a commit is on the team's server.

## RECAP

Let's land this.

- "It is pushed" has a hidden parameter: which server and which ref; `git remote -v` and `git ls-remote` settle it.
- Proof of a push is the `To <url>` line, `git ls-remote`, or the commit's page in the team repository, never `git status`.
- A commit can be an ancestor of `main` while its change is absent, when a merge resolution discarded its side.
- `git log --full-history -- <path>` shows what simplification hides, and `git show --remerge-diff <merge>` shows what the resolver changed.
- Both repairs only add: a branch and a pull request in one case, one forward commit in the other.

## HOMEWORK

Read sections 30.13 and 30.14. Then generate Incident 5, [`incidents/05-rebased-shared-branch`](../../incidents/05-rebased-shared-branch/SYMPTOMS.md), and attempt it before the next video. It's the first of the three scenarios that define the senior standard, so keep a command log and time yourself.

Two disputes ended without a winner, because you produced evidence that both sides could accept. Practise the first one by hand before you go on. Next time, a new report: "Every commit is in the pull request twice". Until then, look at the state first and type second. See you in the next one.

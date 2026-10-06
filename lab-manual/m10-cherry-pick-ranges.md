# Module 10 labs: Cherry-pick

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" below is real output from a replay script in `labs/ch10/`.

These three labs belong to [Chapter 10, Cherry-pick](../textbook/ch10-cherry-pick.md). Lab 10.4, on range notation, is in [m10-range-notation.md](m10-range-notation.md). The general rules for labs are in the [lab manual README](README.md).

## How the labs of this module work

Each lab has a setup script and a replay script:

```bash
bash labs/ch10/setup-10-1-backport-fix.sh        # builds the starting repository for Lab 10.1
labs/shell m10-1                                 # opens the isolated lab shell in that sandbox
cd gateway                                       # the setup script prints this line for you
```

```bash
labs/run ch10/lab-10-1-backport-fix              # replays the whole lab and prints the transcript
```

The project is `gateway`, a small service that forwards prompts to a model API. `main` is the development line and `release/1.4` the maintenance line. The starting commits have the IDs printed here, because the setup script pins the clock. Commits that you create get other IDs. When a command opens your editor on a commit message, save and close it unless the lab says otherwise.

## Lab 10.1: Backport a fix with `-x`

### Objective

Copy a fix from `main` to the maintenance branch so that the copy records its origin, verify the result on the maintenance branch, then backport a second commit that applies cleanly and breaks the branch, and find out why.

### Prerequisites

Chapter 10, sections 10.2, 10.3 and 10.9.

### Setup

```bash
bash labs/ch10/setup-10-1-backport-fix.sh
labs/shell m10-1
cd gateway
```

You are on `main`. `scripts/smoke.sh` stands in for the test suite of whatever branch is checked out.

### Commands

```bash
git log --graph --decorate --all --format="%h %an: %s%d"
sh scripts/smoke.sh
git show --stat --format="%h %an: %s" main~1
```

`main~1` is Asha's fix. Before you copy it, write down who will be the author and who the committer of the copy, and whether its ID will equal `e2a9939`.

```bash
git switch release/1.4
git cherry-pick -x main~1
git log -1 --format=fuller
sh scripts/smoke.sh
```

### Expected output

<!-- snippet: ch10/lab-10-1-backport-fix/01-start -->
```text
$ git log --graph --decorate --all --format="%h %an: %s%d"
* 3056255 Lab User: Allow three retries on the 1.4 line (release/1.4)
| * 1301e05 Asha Rao: Log rejected prompts (HEAD -> main)
| * e2a9939 Asha Rao: Reject empty prompts before calling the model
| * 577852f Lab User: Add structured event logger
| * 6db3c0c Lab User: Start 1.5 development
|/  
* 93787ec Lab User: Add model client
$ sh scripts/smoke.sh
smoke test passed
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-1-backport-fix/02-inspect-fix -->
```text
$ git show --stat --format="%h %an: %s" main~1
e2a9939 Asha Rao: Reject empty prompts before calling the model

 src/client.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-1-backport-fix/03-backport -->
```text
$ git switch release/1.4
Switched to branch 'release/1.4'
$ git cherry-pick -x main~1
Auto-merging src/client.py
[release/1.4 b34c31f] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-1-backport-fix/04-result -->
```text
$ git log -1 --format=fuller
commit b34c31f3557de401a3aaa104c7fc1b6c2ead60e4
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:12:00 2026 +0530

    Reject empty prompts before calling the model
    
    (cherry picked from commit e2a99394ca2cb40134f2126036cbda0260e5a6e4)
$ sh scripts/smoke.sh
smoke test passed
```
<!-- /snippet -->

### What happened internally

Git ran a three-way merge with the parent of `e2a9939` as the base, `release/1.4` as "ours" and `e2a9939` as "theirs". The release branch differs from that base in one line (`MAX_RETRIES`), the fix differs in two other lines, so the merge was clean: `Auto-merging src/client.py`. Git then created a new commit with the release tip as its parent, Asha as author with her original date, and you as committer with the current time. `-x` appended the line that names the original. The branch ref advanced by one commit. Nothing links the two commits in the graph.

### Checkpoint

`git log -1 --format=fuller` shows two different names and two different dates, and a last line that starts with `(cherry picked from commit e2a9939`. `sh scripts/smoke.sh` passes on `release/1.4`.

### Failure scenario

The next commit on `main` is a small follow-up by the same author. It looks harmless, so you backport it too:

```bash
git show --format="%h %s" main
git cherry-pick -x main
sh scripts/smoke.sh
git log --oneline -1 -S"def log_event" main
git branch --contains $(git log --format=%h -1 -S"def log_event" main)
```

<!-- snippet: ch10/lab-10-1-backport-fix/05-failure -->
```text
# The follow-up commit on main looks harmless, so it is backported too:
$ git show --format="%h %s" main
1301e05 Log rejected prompts

diff --git a/src/client.py b/src/client.py
index d2b1af9..37286eb 100644
--- a/src/client.py
+++ b/src/client.py
@@ -3,5 +3,6 @@ MAX_RETRIES = 2
 
 def call_model(prompt):
     if not prompt.strip():
+        log_event("empty_prompt")
         raise ValueError("empty prompt")
     return post("/v1/generate", prompt, timeout=TIMEOUT_S)
$ git cherry-pick -x main
Auto-merging src/client.py
[release/1.4 257719a] Log rejected prompts
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-1-backport-fix/06-diagnose -->
```text
$ sh scripts/smoke.sh
smoke test failed: client.py calls log_event, which this branch does not define
$ git log --oneline -1 -S"def log_event" main
577852f Add structured event logger
$ git branch --contains $(git log --format=%h -1 -S"def log_event" main)
  main
```
<!-- /snippet -->

No conflict, and the branch is broken. `git log -S` finds the commit that introduced `log_event`, and `git branch --contains` shows that only `main` has it.

### Recovery

The bad backport has not been pushed, so it can be removed. `HEAD@{1}` is where HEAD was before it:

```bash
git reflog -2
git reset --hard HEAD@{1}
```

<!-- snippet: ch10/lab-10-1-backport-fix/07-recovery -->
```text
# The bad backport has not been pushed, so it can be removed. HEAD@{1} is where HEAD was before it.
$ git reflog -2
257719a HEAD@{0}: cherry-pick: Log rejected prompts
b34c31f HEAD@{1}: cherry-pick: Reject empty prompts before calling the model
$ git reset --hard HEAD@{1}
HEAD is now at b34c31f Reject empty prompts before calling the model
```
<!-- /snippet -->

🔴 `git reset --hard` is acceptable here because the working tree is clean and the commit exists only in your clone. On a branch that others have pulled, you would use `git revert` ([Chapter 11](../textbook/ch11-reset-revert-restore.md)).

### Verification

```bash
sh scripts/smoke.sh
git log --oneline --decorate -3
git log --format="%h %s%n  %b" -1
```

<!-- snippet: ch10/lab-10-1-backport-fix/08-verification -->
```text
$ sh scripts/smoke.sh
smoke test passed
$ git log --oneline --decorate -3
b34c31f (HEAD -> release/1.4) Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
93787ec Add model client
$ git log --format="%h %s%n  %b" -1
b34c31f Reject empty prompts before calling the model
  (cherry picked from commit e2a99394ca2cb40134f2126036cbda0260e5a6e4)
```
<!-- /snippet -->

### Questions

1. Who is the author and who is the committer of the backported commit, and why do the two dates differ?
2. The second cherry-pick applied without a conflict and broke the branch. Using base, "ours" and "theirs", explain why Git had nothing to report.
3. What would you do instead of `git reset --hard HEAD@{1}` if the bad backport had already been pushed to the shared release branch?
4. Give two correct ways to bring "Log rejected prompts" to the release branch, and say which you would propose for a maintenance release.
5. A month from now someone asks whether `release/1.4` contains Asha's fix `e2a9939`. Which command answers correctly, and which familiar command gives a misleading answer?

## Lab 10.2: A cherry-pick conflict

### Objective

Resolve a cherry-pick conflict by reading the three stages, then resolve it by taking "theirs" wholesale and find the unrelated change that this imports.

### Prerequisites

Chapter 10, sections 10.2 and 10.7. Chapter 8 for index stages.

### Setup

```bash
bash labs/ch10/setup-10-2-cherry-pick-conflict.sh
labs/shell m10-2
cd gateway
```

You are on `release/1.4`. On `main`, an earlier commit moved the client to the `/v2/generate` endpoint; customers on 1.4 stay on v1. Asha's later fix adds retries to the same line.

### Commands

```bash
git log --graph --decorate --all --format="%h %an: %s%d"
git show --format="%h %s" main~1
git cherry-pick -x main~1
```

The pick stops. Before you look at the stages, write down what the last line of the file will be in stage 1, stage 2 and stage 3.

```bash
git status --short
git show :1:src/client.py | tail -1
git show :2:src/client.py | tail -1
git show :3:src/client.py | tail -1
```

Resolve by hand: in `src/client.py` keep `/v1/generate`, add `, retries=MAX_RETRIES` before the closing parenthesis, and delete the marker lines. Then:

```bash
git add src/client.py
git cherry-pick --continue
git show --format="%h %s%n%b" HEAD
```

### Expected output

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/01-start -->
```text
$ git log --graph --decorate --all --format="%h %an: %s%d"
* c3a7a9f Lab User: Apply the timeout to streaming calls (main)
* ebcee16 Asha Rao: Retry failed generate calls
* 08f4771 Lab User: Add streaming client
* 1a6b393 Lab User: Move to the v2 generate endpoint
* 6db3c0c Lab User: Start 1.5 development
* 93787ec Lab User: Add model client (HEAD -> release/1.4)
$ git show --format="%h %s" main~1
ebcee16 Retry failed generate calls

diff --git a/src/client.py b/src/client.py
index c1997a3..e4a1d5a 100644
--- a/src/client.py
+++ b/src/client.py
@@ -2,4 +2,4 @@ TIMEOUT_S = 30
 MAX_RETRIES = 2
 
 def call_model(prompt):
-    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
+    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/02-conflict -->
```text
$ git cherry-pick -x main~1
Auto-merging src/client.py
CONFLICT (content): Merge conflict in src/client.py
error: could not apply ebcee16... Retry failed generate calls
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/03-stages -->
```text
$ git status --short
UU src/client.py
$ git show :1:src/client.py | tail -1
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
$ git show :2:src/client.py | tail -1
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
$ git show :3:src/client.py | tail -1
    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/04-resolve -->
```text
# Edit src/client.py: keep /v1/generate, add retries=MAX_RETRIES, delete the marker lines.
$ git add src/client.py
$ git cherry-pick --continue
[release/1.4 4644f88] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --format="%h %s%n%b" HEAD
4644f88 Retry failed generate calls
(cherry picked from commit ebcee168893f1604f1fcaa96b382049f9d46fd23)


diff --git a/src/client.py b/src/client.py
index bf888b0..32a510e 100644
--- a/src/client.py
+++ b/src/client.py
@@ -2,4 +2,4 @@ TIMEOUT_S = 30
 MAX_RETRIES = 2
 
 def call_model(prompt):
-    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
+    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
```
<!-- /snippet -->

### What happened internally

The base of the merge is the parent of the picked commit, and on `main` that parent already calls `/v2/generate`. Relative to that base, your branch changed the line (it says `/v1/`), and the picked commit changed the same line (it adds the argument). Two different changes to one line are a conflict. Stage 1 holds the base, stage 2 your version, stage 3 the picked commit's version, and `CHERRY_PICK_HEAD` names the commit. The change you were asked to carry over is the difference between stage 1 and stage 3: one added argument. Your resolution applied exactly that to your line, and `--continue` committed it with Asha as author and the `-x` line in the message.

### Checkpoint

`git show HEAD` shows a one-line change from `/v1/generate` without retries to `/v1/generate` with retries, and a message that ends with the `(cherry picked from commit ebcee16...)` line.

### Failure scenario

Undo the backport and do it again, this time reasoning "theirs is the fix, so take theirs":

```bash
git reset --hard HEAD~1
git cherry-pick -x main~1
git restore --theirs src/client.py
git add src/client.py
git cherry-pick --continue
git show --format= main~1 | grep "^[-+] "
git show --format= HEAD | grep "^[-+] "
```

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/05-failure -->
```text
$ git reset --hard HEAD~1
HEAD is now at 93787ec Add model client
$ git cherry-pick -x main~1
Auto-merging src/client.py
CONFLICT (content): Merge conflict in src/client.py
error: could not apply ebcee16... Retry failed generate calls
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
# This time the conflict is "resolved" by taking the whole file from the picked commit:
$ git restore --theirs src/client.py
$ git add src/client.py
$ git cherry-pick --continue
[release/1.4 1fc5624] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/06-diagnose -->
```text
# What the original commit changed, and what the backport changed:
$ git show --format= main~1 | grep "^[-+] "
-    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
+    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
$ git show --format= HEAD | grep "^[-+] "
-    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
+    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
```
<!-- /snippet -->

Compare the two pairs of lines. The original commit changed one thing. The backport changed two: it added the retries and it moved the release to the v2 endpoint.

### Recovery

```bash
git reset --hard HEAD~1
git cherry-pick -x main~1
```

Edit `src/client.py` by hand as in the first attempt, then:

```bash
git add src/client.py
git cherry-pick --continue
```

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/07-recovery -->
```text
$ git reset --hard HEAD~1
HEAD is now at 93787ec Add model client
# git cherry-pick -x main~1 again, the file edited by hand as in the first attempt, then:
$ git add src/client.py
$ git cherry-pick --continue
[release/1.4 0006249] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

### Verification

```bash
git show --format= HEAD | grep "^[-+] "
git grep -n "generate" release/1.4 -- src
git status --short --branch
```

<!-- snippet: ch10/lab-10-2-cherry-pick-conflict/08-verification -->
```text
$ git show --format= HEAD | grep "^[-+] "
-    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
+    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
$ git grep -n "generate" release/1.4 -- src
release/1.4:src/client.py:5:    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
$ git status --short --branch
## release/1.4
```
<!-- /snippet -->

### Questions

1. Stage 1 shows `/v2/generate`, a line that `release/1.4` never contained. Where does it come from?
2. State the change that the original commit made, in the form "from ... to ...". What must a correct resolution therefore do to your line?
3. "Theirs" is the fix you want. Why is `git restore --theirs` wrong all the same?
4. How would `merge.conflictStyle=diff3` or `zdiff3` have changed what you saw in the file?
5. After the wrong resolution, which single command shows a reviewer how the backport differs from the original commit?

## Lab 10.3: Detect duplicates with `git cherry`

### Objective

Find out which fixes from `main` are already on the maintenance branch, using patch comparison and the recorded `-x` lines, and see how trusting patch comparison alone leads to a second backport of the same fix.

### Prerequisites

Chapter 10, sections 10.9 and 10.10. Labs 10.1 and 10.2.

### Setup

```bash
bash labs/ch10/setup-10-3-detect-duplicates.sh
labs/shell m10-3
cd gateway
```

You are on `release/1.4`. Asha fixed three things on `main`. Some of them have been backported by colleagues; you have to find out which.

### Commands

```bash
git log --graph --decorate --all --format="%h %an: %s%d"
git cherry -v release/1.4 main
git log --oneline --left-right --cherry-mark release/1.4...main
```

From these two outputs alone, write down which of Asha's three fixes you believe are on the release. Then look at what the release commits say about themselves:

```bash
git log --format="%h %s%n   %b" main..release/1.4
git log --oneline --author=Asha main
```

One fix is missing. Backport it:

```bash
git cherry-pick -x main~1
```

### Expected output

<!-- snippet: ch10/lab-10-3-detect-duplicates/01-start -->
```text
$ git log --graph --decorate --all --format="%h %an: %s%d"
* 330cbeb Asha Rao: Retry failed generate calls (HEAD -> release/1.4)
* d35a082 Asha Rao: Reject empty prompts before calling the model
* 81dbaba Lab User: Raise the timeout to 60 seconds on the 1.4 line
| * 14ff33e Lab User: Add streaming client (main)
| * 014bb2e Asha Rao: Back off when the API answers 429
| * ff3b930 Asha Rao: Retry failed generate calls
| * f944fc7 Lab User: Move to the v2 generate endpoint
| * a19dd2e Asha Rao: Reject empty prompts before calling the model
| * 6db3c0c Lab User: Start 1.5 development
|/  
* 93787ec Lab User: Add model client
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-3-detect-duplicates/02-cherry -->
```text
$ git cherry -v release/1.4 main
+ 6db3c0c6eace6d80b965fbca258fd96d13ad0e76 Start 1.5 development
- a19dd2ed62611720e1d7ce674e1346f4e9d9f692 Reject empty prompts before calling the model
+ f944fc7baea69d17a301c976b7c8bdc8bbda4a89 Move to the v2 generate endpoint
+ ff3b93081861a6c650e2c945dd9d565fe02d5a6b Retry failed generate calls
+ 014bb2efa1f5270f51dd29823235eacbcff771fd Back off when the API answers 429
+ 14ff33e64904e49143a2b7e480df2980c91ebf28 Add streaming client
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-3-detect-duplicates/03-cherry-mark -->
```text
$ git log --oneline --left-right --cherry-mark release/1.4...main
< 330cbeb Retry failed generate calls
= d35a082 Reject empty prompts before calling the model
< 81dbaba Raise the timeout to 60 seconds on the 1.4 line
> 14ff33e Add streaming client
> 014bb2e Back off when the API answers 429
> ff3b930 Retry failed generate calls
> f944fc7 Move to the v2 generate endpoint
= a19dd2e Reject empty prompts before calling the model
> 6db3c0c Start 1.5 development
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-3-detect-duplicates/04-trailers -->
```text
$ git log --format="%h %s%n   %b" main..release/1.4
330cbeb Retry failed generate calls
   (cherry picked from commit ff3b93081861a6c650e2c945dd9d565fe02d5a6b)

d35a082 Reject empty prompts before calling the model
   (cherry picked from commit a19dd2ed62611720e1d7ce674e1346f4e9d9f692)

81dbaba Raise the timeout to 60 seconds on the 1.4 line
   
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-3-detect-duplicates/05-missing -->
```text
# Asha fixed three things on main. Two are on the release under other IDs. The third is missing:
$ git log --oneline --author=Asha main
014bb2e Back off when the API answers 429
ff3b930 Retry failed generate calls
a19dd2e Reject empty prompts before calling the model
$ git cherry-pick -x main~1
[release/1.4 3420397] Back off when the API answers 429
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 src/backoff.py
```
<!-- /snippet -->

### What happened internally

`git cherry` computed a patch ID for every commit on each side and marked with `-` the commits of `main` whose patch ID also occurs on the release: one commit, "Reject empty prompts". `--cherry-mark` shows the same pair as two `=` lines. "Retry failed generate calls" is marked `+` and `>`, although the release has a commit with that subject: that backport hit a conflict and was resolved by hand, so its diff is not the diff of the original, and the patch IDs differ. The `-x` lines tell the true story: two commits on the release name their originals. Comparing them with Asha's three commits leaves one fix, "Back off when the API answers 429", and that is what you picked.

### Checkpoint

You can state, with the evidence for each: two of Asha's fixes were on the release before you started, one exact copy and one adapted copy; the third is there now, under a new ID, with an `-x` line.

### Failure scenario

A colleague reads the `+` in front of "Retry failed generate calls" as "not backported yet" and picks it:

```bash
git cherry-pick -x main~2
git status --short
git log --oneline --grep="cherry picked from commit $(git rev-parse main~2)" release/1.4
```

<!-- snippet: ch10/lab-10-3-detect-duplicates/06-failure -->
```text
# A colleague reads the "+" in front of "Retry failed generate calls" as "not backported yet":
$ git cherry-pick -x main~2
Auto-merging src/client.py
CONFLICT (content): Merge conflict in src/client.py
error: could not apply ff3b930... Retry failed generate calls
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch10/lab-10-3-detect-duplicates/07-diagnose -->
```text
$ git status --short
UU src/client.py
$ git log --oneline --grep="cherry picked from commit $(git rev-parse main~2)" release/1.4
330cbeb Retry failed generate calls
```
<!-- /snippet -->

The pick conflicts with the earlier backport of the same change. The search for the recorded line finds that backport at once.

### Recovery

```bash
git cherry-pick --abort
git status --short --branch
```

<!-- snippet: ch10/lab-10-3-detect-duplicates/08-recovery -->
```text
$ git cherry-pick --abort
$ git status --short --branch
## release/1.4
```
<!-- /snippet -->

### Verification

```bash
git log --oneline --decorate -4
git cherry -v release/1.4 main
```

<!-- snippet: ch10/lab-10-3-detect-duplicates/09-verification -->
```text
$ git log --oneline --decorate -4
3420397 (HEAD -> release/1.4) Back off when the API answers 429
330cbeb Retry failed generate calls
d35a082 Reject empty prompts before calling the model
81dbaba Raise the timeout to 60 seconds on the 1.4 line
$ git cherry -v release/1.4 main
+ 6db3c0c6eace6d80b965fbca258fd96d13ad0e76 Start 1.5 development
- a19dd2ed62611720e1d7ce674e1346f4e9d9f692 Reject empty prompts before calling the model
+ f944fc7baea69d17a301c976b7c8bdc8bbda4a89 Move to the v2 generate endpoint
+ ff3b93081861a6c650e2c945dd9d565fe02d5a6b Retry failed generate calls
- 014bb2efa1f5270f51dd29823235eacbcff771fd Back off when the API answers 429
+ 14ff33e64904e49143a2b7e480df2980c91ebf28 Add streaming client
```
<!-- /snippet -->

"Back off when the API answers 429" now shows `-`: your backport is an exact copy. "Retry failed generate calls" still shows `+`, and will forever. The list from `git cherry` is a starting point for the question "what is missing", never the answer.

### Questions

1. What exactly does `git cherry -v release/1.4 main` compare, and what do `+` and `-` mean?
2. "Retry failed generate calls" is on the release as `330cbeb`, yet `git cherry` marks the original with `+`. Why?
3. Write down the procedure you would give a teammate for answering "which fixes from `main` are still missing on the release", using both kinds of evidence.
4. If the colleague had resolved the conflict in the failure scenario so that the file ended up as it already was, what would `git cherry-pick --continue` have done?
5. Why does `--cherry-mark` need the three-dot form `release/1.4...main`?

# Module 2 labs: Working tree, index, and HEAD

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the replay scripts in `labs/ch05/` and `labs/ch04/`. Read [Chapter 4](../textbook/ch04-working-tree.md) and [Chapter 5](../textbook/ch05-index.md) first; each lab names the sections it relies on.

## How to run these labs

Every lab starts from a prepared directory of the sample project `support-bot`. From the course root:

```bash
bash labs/ch05/setup-02-1-three-trees.sh    # builds the starting point for Lab 2.1
labs/shell m02-1                            # opens the isolated lab shell in that sandbox
cd support-bot
```

Run the setup script again to start a lab over: it replaces the sandbox. The setup scripts pin the clock and the identity, so the commits you start from have the IDs printed here. Commits that you create by hand get the real time and therefore other IDs; compare messages, parents and trees, not IDs. Blob IDs are different: a blob ID depends only on content, so the blob IDs printed in this manual are the ones you will see in your own sandbox.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from the replay script. Where this manual asks you to edit a file in your editor, the script made the same edit with a command.
- `git add -p` asks its questions interactively. The answers that the scripts gave are printed after each prompt, and the notes list them in order.

To see a lab exactly as printed, replay it: `labs/run ch05/lab-02-1-three-trees`. Answers to the questions are in [solutions/m02-lab-answers.md](../solutions/m02-lab-answers.md). Write your own first.

## Lab 2.1: The three-trees prediction table

### Objective

Predict the content of the working tree, the index and HEAD for one file after each of seven commands, verify each prediction, and recover content that none of the three trees holds any more.

### Prerequisites

Chapter 5, sections 5.2 to 5.4 and 5.9. Chapter 4, section 4.7 for `git restore`.

### Setup

```bash
bash labs/ch05/setup-02-1-three-trees.sh
labs/shell m02-1
cd support-bot
```

The repository has one commit, "Add settings and README". `config/settings.yaml` contains the single line `top_k: 5`.

### Commands

Define a helper that prints the three versions of the file, and check the starting state:

```bash
git log --oneline
show3() { echo "working tree: $(cat config/settings.yaml)"; echo "index:        $(git show :config/settings.yaml)"; echo "HEAD:         $(git show HEAD:config/settings.yaml)"; }
show3
```

Fill in the table before you run anything. Each cell is the `top_k` value in that tree after the step.

| Step | Command | Working tree | Index | HEAD |
|---|---|---|---|---|
| 1 | `echo 'top_k: 8' > config/settings.yaml` | | | |
| 2 | `git add config/settings.yaml` | | | |
| 3 | `echo 'top_k: 12' > config/settings.yaml` | | | |
| 4 | `git commit -m "Raise top_k to 8"` | | | |
| 5 | `git restore config/settings.yaml` | | | |
| 6 | `echo 'top_k: 20' > config/settings.yaml` and `git add config/settings.yaml` | | | |
| 7 | `git restore --staged config/settings.yaml` | | | |

Then run the steps one at a time, with `show3` after each. After steps 3, 5 and 7, also run `git status --short`.

### Expected output

<!-- snippet: ch05/lab-02-1-three-trees/01-start -->
```text
$ git log --oneline
ef9d1fe Add settings and README
$ show3() { echo "working tree: $(cat config/settings.yaml)"; echo "index:        $(git show :config/settings.yaml)"; echo "HEAD:         $(git show HEAD:config/settings.yaml)"; }
$ show3
working tree: top_k: 5
index:        top_k: 5
HEAD:         top_k: 5
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-1-three-trees/02-steps-1-to-3 -->
```text
# Step 1
$ echo 'top_k: 8' > config/settings.yaml
$ show3
working tree: top_k: 8
index:        top_k: 5
HEAD:         top_k: 5
# Step 2
$ git add config/settings.yaml
$ show3
working tree: top_k: 8
index:        top_k: 8
HEAD:         top_k: 5
# Step 3
$ echo 'top_k: 12' > config/settings.yaml
$ show3
working tree: top_k: 12
index:        top_k: 8
HEAD:         top_k: 5
$ git status --short
MM config/settings.yaml
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-1-three-trees/03-steps-4-to-5 -->
```text
# Step 4
$ git commit -m "Raise top_k to 8"
[main 896acac] Raise top_k to 8
 1 file changed, 1 insertion(+), 1 deletion(-)
$ show3
working tree: top_k: 12
index:        top_k: 8
HEAD:         top_k: 8
# Step 5
$ git restore config/settings.yaml
$ show3
working tree: top_k: 8
index:        top_k: 8
HEAD:         top_k: 8
$ git status --short
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-1-three-trees/04-steps-6-to-7 -->
```text
# Step 6
$ echo 'top_k: 20' > config/settings.yaml
$ git add config/settings.yaml
$ show3
working tree: top_k: 20
index:        top_k: 20
HEAD:         top_k: 8
# Step 7
$ git restore --staged config/settings.yaml
$ show3
working tree: top_k: 20
index:        top_k: 8
HEAD:         top_k: 8
$ git status --short
 M config/settings.yaml
```
<!-- /snippet -->

### What happened internally

Each step changed exactly one tree. Steps 1, 3 and 6 wrote the file: only the working tree moved. Step 2 and the add in step 6 wrote a blob into the object database and pointed the index entry at it: `git ls-files --stage` would have shown a new blob ID, and nothing else in `.git` changed. Step 4 wrote tree and commit objects from the index and moved `main`: HEAD caught up with the index, and the working tree's `12` was not part of it, because it had never been added. Step 5 copied the index version over the working tree file, so `12` was gone and no object had ever held it. Step 7 copied HEAD's entry back into the index; the blob with `20` stayed in the object database, now referenced by nothing.

### Checkpoint

The three comparisons of Chapter 5, section 5.4 must agree with your final row:

```bash
git diff
git diff --cached
git diff HEAD
```

<!-- snippet: ch05/lab-02-1-three-trees/05-checkpoint -->
```text
$ git diff
diff --git a/config/settings.yaml b/config/settings.yaml
index 434fcdb..cbda4f9 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1 +1 @@
-top_k: 8
+top_k: 20
$ git diff --cached
$ git diff HEAD
diff --git a/config/settings.yaml b/config/settings.yaml
index 434fcdb..cbda4f9 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1 +1 @@
-top_k: 8
+top_k: 20
```
<!-- /snippet -->

`git diff --cached` prints nothing because the index equals HEAD; the other two print the same hunk because the working tree is the only tree that differs.

### Failure scenario

Discard the working tree copy. The value `20` is now in none of the three trees:

```bash
git restore config/settings.yaml
show3
git status --short
```

<!-- snippet: ch05/lab-02-1-three-trees/06-failure -->
```text
# Failure scenario: discard the working tree copy. 20 is now in none of the three trees.
$ git restore config/settings.yaml
$ show3
working tree: top_k: 8
index:        top_k: 8
HEAD:         top_k: 8
$ git status --short
```
<!-- /snippet -->

### Recovery

Step 6 ran `git add` on that content, so a blob holds it. No ref and no index entry points at the blob, which is what `git fsck` calls dangling:

```bash
git fsck
git cat-file -p cbda4f9
git cat-file -p cbda4f9 > config/settings.yaml
```

<!-- snippet: ch05/lab-02-1-three-trees/07-recovery -->
```text
# Step 6 ran "git add" on that content, so a blob holds it. No ref or index entry points to it.
$ git fsck
dangling blob cbda4f97eda01409c580efa9f05fd9f04a6472b3
$ git cat-file -p cbda4f9
top_k: 20
$ git cat-file -p cbda4f9 > config/settings.yaml
```
<!-- /snippet -->

The blob ID is the same in your sandbox, because it is computed from the content `top_k: 20` alone. Had the lab asked you to recover the `12` of step 3 instead, nothing could have been done: that value was never added, so no object ever held it.

### Verification

```bash
show3
git status --short
git diff
```

<!-- snippet: ch05/lab-02-1-three-trees/08-verification -->
```text
$ show3
working tree: top_k: 20
index:        top_k: 8
HEAD:         top_k: 8
$ git status --short
 M config/settings.yaml
$ git diff
diff --git a/config/settings.yaml b/config/settings.yaml
index 434fcdb..cbda4f9 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1 +1 @@
-top_k: 8
+top_k: 20
```
<!-- /snippet -->

### Questions

1. After step 3 the file showed `MM`. Which two comparisons produced the two letters, and what would `git commit` have recorded at that moment?
2. Why could `top_k: 20` be recovered while `top_k: 12`, discarded in step 5, could not?
3. After step 7, `git diff --cached` printed nothing while `git diff` and `git diff HEAD` printed the same hunk. Explain why those two are identical here, and describe a state in which `git diff HEAD` is empty while `git diff --cached` is not.
4. Your commit IDs differ from the ones in this manual, yet `git fsck` printed the same blob ID, `cbda4f9`. Why?
5. With default settings, how long does a dangling blob like this one survive, which setting decides it, and does the lab configuration change it?

## Lab 2.2: Partial staging

### Objective

Turn one file that holds three unrelated edits into two commits and discard the third edit without ever committing it. Then make the classic mistake, `git commit -a` after careful partial staging, and repair it.

### Prerequisites

Chapter 5, sections 5.4, 5.5 and 5.10. Chapter 4, section 4.7 for `git restore`.

### Setup

```bash
bash labs/ch05/setup-02-2-partial-staging.sh
labs/shell m02-2
cd support-bot
```

The repository has one commit, "Add offline evaluation script". `src/evaluate.py` holds three uncommitted edits: the pass threshold rises from 0.5 to 0.8 (a policy change), `is_correct` now compares answers without case or surrounding whitespace (a bug fix), and `accuracy` prints a debug line (never to be committed).

### Commands

Look at the three edits, then stage the bug fix alone. The hunk selector will offer two hunks; split the second one. Answer `n`, `s`, `y`, `n`:

```bash
git status --short
git diff
git add -p src/evaluate.py
git status --short
git diff --cached
git commit -m "Compare answers without case or surrounding space"
git diff --stat
```

Second pass, for the threshold. Answer `y`, `n`. Then discard what is left:

```bash
git add -p src/evaluate.py
git commit -m "Raise the pass threshold to 0.8"
git diff
git restore src/evaluate.py
git status --short
git log --oneline
```

### Expected output

<!-- snippet: ch05/lab-02-2-partial-staging/01-start -->
```text
$ git status --short
 M src/evaluate.py
$ git diff
diff --git a/src/evaluate.py b/src/evaluate.py
index e7e92e7..5f28fc9 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -1,7 +1,7 @@
 """Offline evaluation for the support bot."""
 import json
 
-THRESHOLD = 0.5
+THRESHOLD = 0.8
 
 
 def load_cases(path):
@@ -10,10 +10,11 @@ def load_cases(path):
 
 
 def is_correct(case, prediction):
-    return prediction == case["expected"]
+    return prediction.strip().lower() == case["expected"].strip().lower()
 
 
 def accuracy(cases, predictions):
+    print("DEBUG predictions:", predictions)
     correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
     return correct / len(cases)
 
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-2-partial-staging/02-first-pass -->
```text
# Answers: n (threshold), s (split), y (the fix), n (debug line).
$ git add -p src/evaluate.py
diff --git a/src/evaluate.py b/src/evaluate.py
index e7e92e7..5f28fc9 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -1,7 +1,7 @@
 """Offline evaluation for the support bot."""
 import json
 
-THRESHOLD = 0.5
+THRESHOLD = 0.8
 
 
 def load_cases(path):
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? n
@@ -10,10 +10,11 @@ def load_cases(path):
 
 
 def is_correct(case, prediction):
-    return prediction == case["expected"]
+    return prediction.strip().lower() == case["expected"].strip().lower()
 
 
 def accuracy(cases, predictions):
+    print("DEBUG predictions:", predictions)
     correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
     return correct / len(cases)
 
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,s,e,p,P,?]? s
Split into 2 hunks.
@@ -10,7 +10,7 @@ def load_cases(path):
 
 
 def is_correct(case, prediction):
-    return prediction == case["expected"]
+    return prediction.strip().lower() == case["expected"].strip().lower()
 
 
 def accuracy(cases, predictions):
(2/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -14,6 +14,7 @@
 
 
 def accuracy(cases, predictions):
+    print("DEBUG predictions:", predictions)
     correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
     return correct / len(cases)
 
(3/3) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-2-partial-staging/03-check-before-commit -->
```text
$ git status --short
MM src/evaluate.py
$ git diff --cached
diff --git a/src/evaluate.py b/src/evaluate.py
index e7e92e7..9dfbf7e 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -10,7 +10,7 @@ def load_cases(path):
 
 
 def is_correct(case, prediction):
-    return prediction == case["expected"]
+    return prediction.strip().lower() == case["expected"].strip().lower()
 
 
 def accuracy(cases, predictions):
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-2-partial-staging/04-first-commit -->
```text
$ git commit -m "Compare answers without case or surrounding space"
[main e878c0f] Compare answers without case or surrounding space
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat
 src/evaluate.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-2-partial-staging/05-second-pass -->
```text
# Answers: y (threshold), n (debug line).
$ git add -p src/evaluate.py
diff --git a/src/evaluate.py b/src/evaluate.py
index 9dfbf7e..5f28fc9 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -1,7 +1,7 @@
 """Offline evaluation for the support bot."""
 import json
 
-THRESHOLD = 0.5
+THRESHOLD = 0.8
 
 
 def load_cases(path):
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -14,6 +14,7 @@ def is_correct(case, prediction):
 
 
 def accuracy(cases, predictions):
+    print("DEBUG predictions:", predictions)
     correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
     return correct / len(cases)
 
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n

$ git commit -m "Raise the pass threshold to 0.8"
[main 8c8c524] Raise the pass threshold to 0.8
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-2-partial-staging/06-discard-the-rest -->
```text
$ git diff
diff --git a/src/evaluate.py b/src/evaluate.py
index e45771f..5f28fc9 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -14,6 +14,7 @@ def is_correct(case, prediction):
 
 
 def accuracy(cases, predictions):
+    print("DEBUG predictions:", predictions)
     correct = sum(1 for case, pred in zip(cases, predictions) if is_correct(case, pred))
     return correct / len(cases)
 
$ git restore src/evaluate.py
$ git status --short
$ git log --oneline
8c8c524 Raise the pass threshold to 0.8
e878c0f Compare answers without case or surrounding space
face513 Add offline evaluation script
```
<!-- /snippet -->

### What happened internally

`git add -p` compared the index (equal to HEAD, blob `e7e92e7`) with the working tree (`5f28fc9`) and cut the difference into hunks: the threshold change in one, the fix and the debug line in another, because only three unchanged lines separate them, fewer than the three lines of context that a diff shows around each change. `s` split that hunk; it changed the questions, not the index. Your `y` made Git build a new blob, `9dfbf7e`, from HEAD's version plus the accepted hunk, and point the index entry at it. That content had never existed on disk. The first commit recorded it; `git diff --stat` then showed 2 insertions and 1 deletion still waiting in the working tree. The second pass repeated the process for the threshold. `git restore` finally copied the index version over the file, which removed the debug line; nothing in `.git` had ever held that line.

### Checkpoint

Three commits, a clean working tree, and no debug line anywhere in HEAD:

```bash
git log --oneline
git status --short
git grep -n DEBUG HEAD; echo $?
```

The log must show the three messages printed above (your IDs differ), `git status --short` must print nothing, and `git grep` must print nothing and exit with status 1.

### Failure scenario

Two new edits: a docstring worth committing and a debug line that is not. In your editor, change line 1 of `src/evaluate.py` to `"""Offline evaluation for the support bot (exact-match accuracy)."""` and insert the line `    print("DEBUG score:", score)` directly after `    score = accuracy(cases, predictions)` in `report`. Check with `git diff`, which must match the first transcript below. Then stage only the docstring (answers `y`, `n`) and commit with `-a`:

```bash
git diff
git add -p src/evaluate.py
git commit -a -m "Name the metric in the module docstring"
git show --stat --format=%s HEAD
git grep -n DEBUG HEAD
```

<!-- snippet: ch05/lab-02-2-partial-staging/07-failure-setup -->
```text
# Failure scenario. Two new edits: a docstring worth committing and a debug line that is not.
$ git diff
diff --git a/src/evaluate.py b/src/evaluate.py
index e45771f..6a26020 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -1,4 +1,4 @@
-"""Offline evaluation for the support bot."""
+"""Offline evaluation for the support bot (exact-match accuracy)."""
 import json
 
 THRESHOLD = 0.8
@@ -20,5 +20,6 @@ def accuracy(cases, predictions):
 
 def report(cases, predictions):
     score = accuracy(cases, predictions)
+    print("DEBUG score:", score)
     status = "PASS" if score >= THRESHOLD else "FAIL"
     return f"{status} accuracy={score:.3f}"
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-2-partial-staging/08-failure -->
```text
# Stage only the docstring (answers: y, n) ...
$ git add -p src/evaluate.py
diff --git a/src/evaluate.py b/src/evaluate.py
index e45771f..6a26020 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -1,4 +1,4 @@
-"""Offline evaluation for the support bot."""
+"""Offline evaluation for the support bot (exact-match accuracy)."""
 import json
 
 THRESHOLD = 0.8
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -20,5 +20,6 @@ def accuracy(cases, predictions):
 
 def report(cases, predictions):
     score = accuracy(cases, predictions)
+    print("DEBUG score:", score)
     status = "PASS" if score >= THRESHOLD else "FAIL"
     return f"{status} accuracy={score:.3f}"
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n

# ... and then commit with -a, which stages every tracked change again.
$ git commit -a -m "Name the metric in the module docstring"
[main b62f1b4] Name the metric in the module docstring
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git show --stat --format=%s HEAD
Name the metric in the module docstring

 src/evaluate.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git grep -n DEBUG HEAD
HEAD:src/evaluate.py:23:    print("DEBUG score:", score)
```
<!-- /snippet -->

`-a` staged every change to every tracked file before committing. The hunk you had left out went in with the one you had chosen, and the commit contains the debug line.

### Recovery

The commit is local, so the lowest-risk fix is to move the branch back by one commit. 🟡 `git reset HEAD~1` moves `main` and rewrites the index from the previous commit; the working tree keeps both edits. Stage the docstring again (answers `y`, `n`) and commit without `-a`:

```bash
git reset HEAD~1
git status --short
git add -p src/evaluate.py
git diff --cached --stat
git commit -m "Name the metric in the module docstring"
git restore src/evaluate.py
```

<!-- snippet: ch05/lab-02-2-partial-staging/09-recovery -->
```text
# The commit is local. Move the branch back one commit; the working tree keeps both edits.
$ git reset HEAD~1
Unstaged changes after reset:
M	src/evaluate.py
$ git status --short
 M src/evaluate.py
$ git add -p src/evaluate.py
diff --git a/src/evaluate.py b/src/evaluate.py
index e45771f..6a26020 100644
--- a/src/evaluate.py
+++ b/src/evaluate.py
@@ -1,4 +1,4 @@
-"""Offline evaluation for the support bot."""
+"""Offline evaluation for the support bot (exact-match accuracy)."""
 import json
 
 THRESHOLD = 0.8
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -20,5 +20,6 @@ def accuracy(cases, predictions):
 
 def report(cases, predictions):
     score = accuracy(cases, predictions)
+    print("DEBUG score:", score)
     status = "PASS" if score >= THRESHOLD else "FAIL"
     return f"{status} accuracy={score:.3f}"
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n

$ git diff --cached --stat
 src/evaluate.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git commit -m "Name the metric in the module docstring"
[main f522633] Name the metric in the module docstring
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git restore src/evaluate.py
```
<!-- /snippet -->

Had the wrong commit been pushed, you would not move the branch. You would commit a correction on top instead (Chapter 11, Reset, Revert, Restore).

### Verification

```bash
git status --short
git show --stat --format=%s HEAD
git grep -n DEBUG HEAD; echo $?
git log --oneline
```

<!-- snippet: ch05/lab-02-2-partial-staging/10-verification -->
```text
$ git status --short
$ git show --stat --format=%s HEAD
Name the metric in the module docstring

 src/evaluate.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git grep -n DEBUG HEAD
[exit status: 1]
$ git log --oneline
f522633 Name the metric in the module docstring
8c8c524 Raise the pass threshold to 0.8
e878c0f Compare answers without case or surrounding space
face513 Add offline evaluation script
```
<!-- /snippet -->

### Questions

1. The file held three edits, yet the first `git add -p` offered two hunks. Why did the fix and the debug line share a hunk, and what did the answer `s` change in the index?
2. After the first commit, `git diff --stat` reported 2 insertions and 1 deletion. Which edits were those, and which two trees did the command compare?
3. The blob `9dfbf7e` was in the index after the first pass. Had that content ever existed as a file on disk? Where did Git get it?
4. In the failure scenario the commit reported 2 insertions and 1 deletion instead of 1 and 1. State exactly what `-a` did to the index before the commit was written.
5. What did `git reset HEAD~1` change among working tree, index, HEAD and the branch ref? Why was it the right tool here, and when would it be the wrong one?
6. After `git restore src/evaluate.py` the debug lines were gone. Could `git fsck` have recovered them, as in Lab 2.1? Why or why not?

## Lab 2.3: The `.gitignore` trap and its fix

### Objective

Commit a secret and a bytecode cache by mistake with the first `git add .`, add the ignore rule too late, diagnose why the rule has no effect, fix it with `git rm --cached`, and see what the fix does to a teammate who pulls it. This lab uses Chapter 4 only.

### Prerequisites

Chapter 4, sections 4.3, 4.5 and 4.6. Chapter 4, section 4.7 for `git restore --source`.

### Setup

```bash
bash labs/ch04/setup-02-3-gitignore-trap.sh
labs/shell m02-3
cd support-bot
```

The directory holds a small project and no repository yet: `src/app.py`, `requirements.txt`, a `.env` with an API key, and a compiled file under `src/__pycache__/`.

### Commands

Make the mistake, then add the rule one commit too late. The teammate clones at that point, and you edit your `.env`:

```bash
git init
git add .
git commit -m "Add service skeleton"
git ls-files
printf '.env\n__pycache__/\n' > .gitignore
git add .gitignore
git commit -m "Add ignore rules"
git clone -q . ../asha-clone
echo 'LLM_API_KEY=lab-secret-0002' > .env
git status --short
```

Diagnose, then fix:

```bash
git check-ignore -v .env; echo $?
git check-ignore -v --no-index .env; echo $?
git ls-files --cached --ignored --exclude-standard
git rm --cached .env
git rm -r --cached src/__pycache__
git status --short --ignored
git commit -m "Stop tracking the environment file and bytecode caches"
```

### Expected output

<!-- snippet: ch04/lab-02-3-gitignore-trap/01-the-mistake -->
```text
$ git init
Initialized empty Git repository in $LAB/ch04/lab-02-3-gitignore-trap/support-bot/.git/
$ git add .
$ git commit -m "Add service skeleton"
[main (root-commit) aa3b3a3] Add service skeleton
 4 files changed, 10 insertions(+)
 create mode 100644 .env
 create mode 100644 requirements.txt
 create mode 100644 src/__pycache__/app.cpython-314.pyc
 create mode 100644 src/app.py
$ git ls-files
.env
requirements.txt
src/__pycache__/app.cpython-314.pyc
src/app.py
```
<!-- /snippet -->

<!-- snippet: ch04/lab-02-3-gitignore-trap/02-rule-added-too-late -->
```text
$ printf '.env\n__pycache__/\n' > .gitignore
$ git add .gitignore
$ git commit -m "Add ignore rules"
[main ec7fe5d] Add ignore rules
 1 file changed, 2 insertions(+)
 create mode 100644 .gitignore
# A teammate clones at this point.
$ git clone -q . ../asha-clone
$ echo 'LLM_API_KEY=lab-secret-0002' > .env
$ git status --short
 M .env
```
<!-- /snippet -->

<!-- snippet: ch04/lab-02-3-gitignore-trap/03-diagnose -->
```text
$ git check-ignore -v .env
[exit status: 1]
$ git check-ignore -v --no-index .env
.gitignore:1:.env	.env
[exit status: 0]
$ git ls-files --cached --ignored --exclude-standard
.env
src/__pycache__/app.cpython-314.pyc
```
<!-- /snippet -->

<!-- snippet: ch04/lab-02-3-gitignore-trap/04-fix -->
```text
$ git rm --cached .env
rm '.env'
$ git rm -r --cached src/__pycache__
rm 'src/__pycache__/app.cpython-314.pyc'
$ git status --short --ignored
D  .env
D  src/__pycache__/app.cpython-314.pyc
!! .env
!! src/__pycache__/
$ git commit -m "Stop tracking the environment file and bytecode caches"
[main c47d432] Stop tracking the environment file and bytecode caches
 2 files changed, 2 deletions(-)
 delete mode 100644 .env
 delete mode 100644 src/__pycache__/app.cpython-314.pyc
```
<!-- /snippet -->

### What happened internally

The first `git add .` gave every file an index entry, and the first commit recorded all four. Ignore patterns are consulted only for paths without an index entry, so the rule added in the second commit changed nothing for `.env`: `git check-ignore` found no applicable rule for a tracked path and exited with 1, while `--no-index`, which leaves the index out of the question, showed that the pattern itself is right. `git ls-files --cached --ignored --exclude-standard` listed the two tracked paths that an ignore rule matches. `git rm --cached` removed their index entries and left the files on disk, which is why status showed each path twice, as a staged deletion (`D `) and as an ignored file (`!!`). The third commit has a tree without those paths. The earlier commits still have them.

### Checkpoint

```bash
git ls-files
cat .env
echo 'LLM_API_KEY=lab-secret-0003' > .env
git status --short
git check-ignore -v .env src/__pycache__/app.cpython-314.pyc
```

<!-- snippet: ch04/lab-02-3-gitignore-trap/05-checkpoint -->
```text
$ git ls-files
.gitignore
requirements.txt
src/app.py
$ cat .env
LLM_API_KEY=lab-secret-0002
$ echo 'LLM_API_KEY=lab-secret-0003' > .env
$ git status --short
$ git check-ignore -v .env src/__pycache__/app.cpython-314.pyc
.gitignore:1:.env	.env
.gitignore:2:__pycache__/	src/__pycache__/app.cpython-314.pyc
```
<!-- /snippet -->

Your `.env` kept its content, a further edit no longer shows up, and `check-ignore` now names the rule for both paths.

### Failure scenario

The fix is a deletion commit, and Git applies deletions to working trees. Asha, who cloned while `.env` was tracked, pulls it:

```bash
cd ../asha-clone
ls -A . src
git pull
ls -A . src
```

<!-- snippet: ch04/lab-02-3-gitignore-trap/06-failure -->
```text
# Failure scenario: the teammate pulls your fix.
$ cd ../asha-clone
$ ls -A . src
.:
.env
.git
.gitignore
requirements.txt
src

src:
__pycache__
app.py
$ git pull
From $LAB/ch04/lab-02-3-gitignore-trap/support-bot/.
   ec7fe5d..c47d432  main       -> origin/main
Updating ec7fe5d..c47d432
Fast-forward
 .env                                | 1 -
 src/__pycache__/app.cpython-314.pyc | 1 -
 2 files changed, 2 deletions(-)
 delete mode 100644 .env
 delete mode 100644 src/__pycache__/app.cpython-314.pyc
$ ls -A . src
.:
.git
.gitignore
requirements.txt
src

src:
app.py
```
<!-- /snippet -->

Her `.env` is gone. From Git's point of view the path was tracked in her HEAD, unmodified, and absent from the new commit, so it was removed like any other deleted file.

### Recovery

The file was tracked one commit ago, so that commit still has its content:

```bash
git restore --source=HEAD~1 .env
cat .env
git status --short --ignored
```

<!-- snippet: ch04/lab-02-3-gitignore-trap/07-recovery -->
```text
# The file was tracked one commit ago, so that commit still has its content.
$ git restore --source=HEAD~1 .env
$ cat .env
LLM_API_KEY=lab-secret-0001
$ git status --short --ignored
!! .env
```
<!-- /snippet -->

She gets the value from the commit, which is the old key, not whatever she had in the file. The path is now untracked and ignored in her clone too.

### Verification

```bash
git ls-files
git ls-files --cached --ignored --exclude-standard
git status
git log --oneline -- .env
git show HEAD~2:.env
```

<!-- snippet: ch04/lab-02-3-gitignore-trap/08-verification -->
```text
$ git ls-files
.gitignore
requirements.txt
src/app.py
$ git ls-files --cached --ignored --exclude-standard
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
# One thing the fix did not do: the secret is still in history, in every clone.
$ git log --oneline -- .env
c47d432 Stop tracking the environment file and bytecode caches
aa3b3a3 Add service skeleton
$ git show HEAD~2:.env
LLM_API_KEY=lab-secret-0001
```
<!-- /snippet -->

The detector prints nothing, and the last command shows what the fix did not do: the secret is still in history, in every clone.

### Questions

1. `git check-ignore -v .env` printed nothing and exited with 1, while `--no-index` found the rule and exited with 0. What does each result tell you about the path?
2. Between `git rm --cached` and the commit, `git status --short --ignored` showed `.env` twice. Derive both lines from the two comparisons and the untracked scan of Chapter 4, section 4.4.
3. Why did Asha's pull delete her `.env` without a warning, and under which condition would the pull have refused instead?
4. After the fix, `git show HEAD~2:.env` still prints the key. In production, what do you do first, and what did the `git rm --cached` commit achieve and not achieve?
5. Which single command would you run in CI to catch this class of mistake, and what is its output in a healthy repository?
6. The rule `__pycache__/` ends with a slash. What would change if it were written as `__pycache__`?

## Lab 2.4: Unstage three ways and compare the results

### Objective

Run `git restore --staged`, `git reset <path>` and `git rm --cached` on the same staged state and compare the index after each; repeat in a repository that has no commit; then repair a commit that deleted a file because the wrong one of the three was used.

### Prerequisites

Chapter 5, sections 5.2 and 5.9. Chapter 4, section 4.6 for what `git rm --cached` is meant for.

### Setup

```bash
bash labs/ch05/setup-02-4-unstage-three-ways.sh
labs/shell m02-4
cd support-bot
```

The repository has one commit, "Add retriever and README". `src/retriever.py` contains `TOP_K = 5`.

### Commands

Define a helper that puts the repository into the same staged state before each experiment: a staged modification of a tracked file and a staged new file.

```bash
git log --oneline
git ls-files --stage
stage_both() { echo 'TOP_K = 8' > src/retriever.py; echo 'SYSTEM = "support"' > src/prompts.py; git add src; }
stage_both
git status --short
git ls-files --stage
```

Predict `git status --short` and the entries of `git ls-files --stage` after each experiment before you run it.

| Experiment | Command | `src/retriever.py` (in HEAD) | `src/prompts.py` (not in HEAD) |
|---|---|---|---|
| A | `git restore --staged src/retriever.py src/prompts.py` | | |
| B | `stage_both`, then `git reset src/retriever.py src/prompts.py` | | |
| C | `stage_both`, then `git rm --cached src/retriever.py src/prompts.py` | | |

```bash
git restore --staged src/retriever.py src/prompts.py
git status --short
git ls-files --stage
stage_both
git reset src/retriever.py src/prompts.py
git status --short
git ls-files --stage
stage_both
git rm --cached src/retriever.py src/prompts.py
git status --short
git ls-files --stage
git restore --staged src/retriever.py
git status --short
```

Experiment D, the same three commands in a repository that has no commit:

```bash
git init -q ../fresh && cd ../fresh
echo 'TOP_K = 5' > retriever.py && git add retriever.py
git restore --staged retriever.py; echo $?
git reset retriever.py; echo $?
git add retriever.py
git rm --cached retriever.py; echo $?
git status --short
cd ../support-bot
```

### Expected output

<!-- snippet: ch05/lab-02-4-unstage-three-ways/01-start -->
```text
$ git log --oneline
2a0f42b Add retriever and README
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
# One helper puts the repository into the same staged state before each experiment.
$ stage_both() { echo 'TOP_K = 8' > src/retriever.py; echo 'SYSTEM = "support"' > src/prompts.py; git add src; }
$ stage_both
$ git status --short
A  src/prompts.py
M  src/retriever.py
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
100644 27a811273c0a19b885bf2d435e667639e409d3dc 0	src/prompts.py
100644 5fac60c5a32ec062dcb2163acd05c4c1c20dda0c 0	src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-4-unstage-three-ways/02-restore-staged -->
```text
# Experiment A
$ git restore --staged src/retriever.py src/prompts.py
$ git status --short
 M src/retriever.py
?? src/prompts.py
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-4-unstage-three-ways/03-reset -->
```text
# Experiment B
$ stage_both
$ git reset src/retriever.py src/prompts.py
Unstaged changes after reset:
M	src/retriever.py
$ git status --short
 M src/retriever.py
?? src/prompts.py
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-4-unstage-three-ways/04-rm-cached -->
```text
# Experiment C
$ stage_both
$ git rm --cached src/retriever.py src/prompts.py
rm 'src/prompts.py'
rm 'src/retriever.py'
$ git status --short
D  src/retriever.py
?? src/
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
# Put the entry for the tracked file back before moving on.
$ git restore --staged src/retriever.py
$ git status --short
 M src/retriever.py
?? src/prompts.py
```
<!-- /snippet -->

<!-- snippet: ch05/lab-02-4-unstage-three-ways/05-no-commits-yet -->
```text
# Experiment D: the same three commands in a repository that has no commit.
$ git init -q ../fresh && cd ../fresh
$ echo 'TOP_K = 5' > retriever.py && git add retriever.py
$ git restore --staged retriever.py
fatal: could not resolve 'HEAD'
[exit status: 128]
$ git reset retriever.py
[exit status: 0]
$ git add retriever.py
$ git rm --cached retriever.py
rm 'retriever.py'
[exit status: 0]
$ git status --short
?? retriever.py
$ cd ../support-bot
```
<!-- /snippet -->

### What happened internally

Experiments A and B did the same thing to the index: for each path they copied HEAD's entry, and where HEAD has no entry they removed the one that was there. The index was identical afterwards, down to the blob `1e0b1ad` for `src/retriever.py`; `git reset` only added a report of what is left unstaged. Experiment C deleted both entries without consulting HEAD. For the new file that is the same result; for the tracked file the index now lacks a path that HEAD has, which the next commit would record as a deletion. In Experiment D there is no HEAD to copy from: `git restore --staged` fails, `git reset <path>` has a rule for that case and removes the entry, and `git rm --cached` removes it as always, which is why `git status` suggests exactly that command before the first commit.

### Checkpoint

After Experiment C and its repair, the index is back to HEAD's entries while the working tree keeps both edits:

```bash
git status --short
git ls-files --stage
```

`git status --short` must print ` M src/retriever.py` and `?? src/prompts.py`, and `git ls-files --stage` must list only `README.md` and `src/retriever.py` with the blob IDs of the first transcript.

### Failure scenario

You want to commit the new prompts file and keep the `TOP_K` edit for later. You stage both, then "unstage" the tracked file with the wrong command:

```bash
git add src
git status --short
git rm --cached src/retriever.py
git commit -m "Add system prompt"
git ls-files
git status --short
```

<!-- snippet: ch05/lab-02-4-unstage-three-ways/06-failure -->
```text
# Failure scenario. You want to commit the new prompts file and keep the TOP_K edit for later.
$ git add src
$ git status --short
A  src/prompts.py
M  src/retriever.py
# The wrong unstage command for a file that HEAD has:
$ git rm --cached src/retriever.py
rm 'src/retriever.py'
$ git commit -m "Add system prompt"
[main 401eb62] Add system prompt
 2 files changed, 1 insertion(+), 1 deletion(-)
 create mode 100644 src/prompts.py
 delete mode 100644 src/retriever.py
$ git ls-files
README.md
src/prompts.py
$ git status --short
?? src/retriever.py
```
<!-- /snippet -->

The commit deleted `src/retriever.py` from the project. The file is still on your disk, as an untracked file.

### Recovery

Copy the entry back into the index from the commit before the mistake. The working tree is not touched, so your edit survives:

```bash
git restore --source=HEAD~1 --staged src/retriever.py
git status --short
git commit -m "Restore src/retriever.py, removed from the index by mistake"
```

<!-- snippet: ch05/lab-02-4-unstage-three-ways/07-recovery -->
```text
# Copy the entry back into the index from the commit before the mistake. The working tree is not touched.
$ git restore --source=HEAD~1 --staged src/retriever.py
$ git status --short
AM src/retriever.py
$ git commit -m "Restore src/retriever.py, removed from the index by mistake"
[main 46134ed] Restore src/retriever.py, removed from the index by mistake
 1 file changed, 1 insertion(+)
 create mode 100644 src/retriever.py
```
<!-- /snippet -->

### Verification

```bash
git ls-files
git log --oneline --name-status
git diff HEAD~2 HEAD -- src/retriever.py
git status --short
```

<!-- snippet: ch05/lab-02-4-unstage-three-ways/08-verification -->
```text
$ git ls-files
README.md
src/prompts.py
src/retriever.py
$ git log --oneline --name-status
46134ed Restore src/retriever.py, removed from the index by mistake
A	src/retriever.py
401eb62 Add system prompt
A	src/prompts.py
D	src/retriever.py
2a0f42b Add retriever and README
A	README.md
A	src/retriever.py
# The file in HEAD is byte-for-byte what it was before the mistake: this prints nothing.
$ git diff HEAD~2 HEAD -- src/retriever.py
# The edit you wanted to keep for later is still waiting, unstaged.
$ git status --short
 M src/retriever.py
```
<!-- /snippet -->

The file in HEAD is byte for byte what it was before the mistake, so the `diff` prints nothing, and the edit you wanted to keep is still waiting, unstaged.

### Questions

1. Experiments A and B produced identical indexes. Name one visible difference between the two commands in this lab, and one situation in which only one of them works.
2. In Experiment C, `git rm --cached` turned a staged modification into a staged deletion. Explain that from the definition of "unstage" in Chapter 5, section 5.9.
3. In Experiment D, `git status` suggested `git rm --cached` to unstage. Why is the suggestion right there and wrong in Experiment C?
4. The failure commit reported "1 insertion(+), 1 deletion(-)" and "delete mode 100644 src/retriever.py" although the file was on disk the whole time. Which comparison produced the deletion?
5. After the recovery command, status showed `AM` for `src/retriever.py`. Explain both letters, and why `git diff HEAD~2 HEAD -- src/retriever.py` printed nothing.
6. A teammate pulled the failure commit before you pushed the repair. What happened to her copy of `src/retriever.py`, and what happens when she pulls the repair?

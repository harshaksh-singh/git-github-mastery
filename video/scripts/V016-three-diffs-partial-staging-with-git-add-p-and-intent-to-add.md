# V016: Three diffs, partial staging with git add -p, and intent to add

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 26
- **Prerequisites.** V015
- **Textbook sections.** [Chapter 5: The Index](../../textbook/ch05-index.md), sections 5.4 to 5.6
- **Demo scripts.** `labs/ch05/three-diffs.sh`, `labs/ch05/add-patch.sh`, `labs/ch05/add-patch-edit.sh`, `labs/ch05/intent-to-add.sh`

## HOOK

**[ON SCREEN]** A diff with three unrelated edits in one file.

It's the end of a debugging session. One file holds three edits: a tuning change you were trying, the bug fix you found, and a debug print you forgot to remove. The fix has to go out now, on its own, so that it can be reviewed and, if necessary, reverted on its own.

You can do that. Git lets you stage one of the three edits, which means marking it for the next commit, and commit it. And the commit you make will contain a version of the file that has never existed on your disk, and that nobody has ever run.

**[PAUSE]**

That's the trade at the centre of this video. Partial staging gives you clean commits from a messy working tree, the folder of files you edit. The price is a snapshot in the index that was never tested. You'll learn the technique, and the check that removes the risk. And that file nobody has ever run? You'll meet it by its ID.

## INTRODUCTION

**[ANIMATION]** trees: file=src/retriever.py steps=setup,edit,add,commit title=Three_places,_three_comparisons

**[ANIMATION]** step: setup

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Three topics today, all consequences of the last video's one idea: the index is a full snapshot that sits between HEAD and the working tree. The index is Git's proposal for the next commit, and HEAD is the last commit you made.

First: three places for a version of a file give three pairwise comparisons, and `git diff` performs a different one depending on its arguments. Second: `git add -p`, which stages part of a file. Third: `git add -N`, intent to add, which makes a new file visible to the commands that would otherwise overlook it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Say which two trees each of `git diff`, `git diff --cached` and `git diff HEAD` compares.
2. Stage part of a file with `git add -p`, including a hunk that cannot be split.
3. Explain the risk of a partially staged commit, and the check that removes it.
4. Make an untracked file visible to `git diff` with `git add -N`.

## CONCEPT

**Three diffs.**

**[ON SCREEN]** The table of section 5.4.

`git diff` compares the index with the working tree. It answers: what could I still stage?

`git diff --cached`, synonym `--staged`, compares HEAD with the index. It answers: what will the next commit change?

`git diff HEAD` compares HEAD with the working tree. It answers: what changed since the last commit, staged or not?

**[ANIMATION]** step: edit

Quick quiz, with the picture. You've edited the file and not staged it. Which diff is empty: `git diff`, `git diff --cached`, or `git diff HEAD`? Say your answer.

**[PAUSE]**

`git diff --cached`. It compares HEAD with the index, and those two boxes still agree.

**[ANIMATION]** step: add

Now you stage the edit. This time the empty one is `git diff`, because the index and the working tree agree again.

**[ANIMATION]** end

Two of them can cancel out. If the working tree equals HEAD and the index differs from both, `git diff HEAD` is empty, while each of the other two shows a change, in opposite directions. So an empty `git diff HEAD` proves nothing about the next commit. And none of the three shows a file that has no index entry.

**[ANIMATION]** step: commit

The rule for practice: make `git diff --cached` the last command before `git commit`. It's the review of what you're about to record.

**Partial staging.** In one sentence: `git add -p` walks through the difference between the index and the working tree one hunk at a time, and stages only the hunks you accept, so one edited file can feed several commits and leave a remainder that is never committed. It is 🟢 SAFE.

A hunk is a block of changed lines with its context, as in `git diff`. Git asks about each hunk, and you answer with a letter.

**[ON SCREEN]** The answer table of section 5.5.

`y` and `n`: stage this hunk, or leave it. `s`: split the hunk. It's offered only when unchanged lines separate the changes in it. `e`: open the hunk in your editor, and stage the edited version. `a` and `d`: stage, or leave, this hunk and all later hunks of the file. `q`: stop. Hunks already accepted are staged. The remaining letters move between hunks, search, print the hunk again, and print the help.

The same selector runs in the other direction in `git restore -p`, `git restore --staged -p` and `git reset -p`.

**Inside `.git`.** One new blob and one changed index entry. A blob is the object that holds one file's content. This one is HEAD's version plus the hunks you accepted: content that has never existed as a file.

**The risk, and the check.** After a partial add, three versions of the file exist. HEAD has none of your edits. The working tree has all of them, and is what you ran. The index has the accepted hunks alone, and that version has never run anywhere. Before you commit it, copy the staged snapshot out of the index and test that. `git checkout-index --all --prefix=<dir>/` 🟢 SAFE writes every index entry as a file below the directory you name. The trailing slash matters.

**Editing a hunk.** When changed lines touch each other, they form one hunk, and `s` is not offered. The answer `e` opens the hunk as a patch, a text of added and removed lines. Deleting a `+` line keeps that addition out of the index. Replacing the `-` of a removed line with a space keeps that removal out. Git then recounts the hunk header and applies the patch to the index. The textbook's section on dangerous edge cases has a warning in its heading that you should remember: a hunk edit can stage content that exists nowhere.

**Intent to add.** In one sentence: `git add -N <path>` gives a new file an index entry without staging its content, so that commands which compare the index with the working tree stop overlooking the file. It is 🟢 SAFE. The manual: "Record only the fact that the path will be added later. An entry for the path is placed in the index with no content".

Why is it needed? A new file is invisible to `git diff`, because there's no entry to compare it with. The hunk selector reads the same comparison as `git diff`, so it has the same blind spot, and the same cure.

Inside `.git`, the entry carries an intent-to-add flag. Index format version 2 has no room for it, so Git writes the index as version 3 while such an entry exists, and as version 2 again after the real add.

**When not to.** Partial staging is the wrong tool when you can't test the result and have no CI behind you, no server that tests every commit: the commit is by construction untested. And `e` is the wrong tool when `s` would do, because an edited hunk is the one place where you can stage lines that are in neither HEAD nor your file.

## MENTAL MODEL

The textbook's analogy for `git add -p`: marking, on a manuscript full of your own edits, the blocks that go to the printer today. It breaks where it matters most: the printer receives a page that never lay on your desk in that form, and nobody has read that page as a whole.

**[ANIMATION]** step: add

For the three diffs, picture a triangle. Three corners: HEAD, index, working tree. Three sides: three diffs. If you know two sides, you don't automatically know the third, because two changes can cancel.

## DIAGRAM

Now the same three corners, with real values.

**[DIAGRAM]** The diagram of section 5.4: three boxes and three labelled arrows.

```text
        HEAD                       index                    working tree
      bd144df                    399da0e                      5853020
   +------------+             +------------+             +--------------+
   | TOP_K = 5  |  git diff   | TOP_K = 8  |             | TOP_K = 8    |
   | MIN = 0.2  |  --cached   | MIN = 0.2  |  git diff   | MIN = 0.35   |
   +------------+ <---------> +------------+ <---------> +--------------+
          ^                                                      ^
          +---------------------- git diff HEAD -----------------+
```

Three boxes with the blob ID of each version above it. `TOP_K` was changed and staged, so it differs between HEAD and the index. `MIN_SCORE` was changed and not staged, so it differs between the index and the working tree. The short arrows are `git diff --cached` and `git diff`. The long arrow underneath is `git diff HEAD`, which spans both.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch05/three-diffs.sh`.

```bash
labs/run ch05/three-diffs
```

<!-- snippet: ch05/three-diffs/01-state -->
```text
# TOP_K was changed to 8 and staged. MIN_SCORE was then changed to 0.35 and not staged.
$ git status --short
MM src/retriever.py
```
<!-- /snippet -->

The state: `MM`. Before each of the next three snippets, say which lines the diff will show. Start with plain `git diff`. Say it out loud.

**[PAUSE]**

<!-- snippet: ch05/three-diffs/02-diff -->
```text
# Index against working tree: what you could still stage.
$ git diff
diff --git a/src/retriever.py b/src/retriever.py
index 399da0e..5853020 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,5 +1,5 @@
 TOP_K = 8
-MIN_SCORE = 0.2
+MIN_SCORE = 0.35
 
 
 def retrieve(query, index):
```
<!-- /snippet -->

<!-- snippet: ch05/three-diffs/03-diff-cached -->
```text
# HEAD against index: what the next commit will change. --staged is a synonym.
$ git diff --cached
diff --git a/src/retriever.py b/src/retriever.py
index bd144df..399da0e 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,4 +1,4 @@
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
```
<!-- /snippet -->

<!-- snippet: ch05/three-diffs/04-diff-head -->
```text
# HEAD against working tree: everything since the last commit, staged or not.
$ git diff HEAD
diff --git a/src/retriever.py b/src/retriever.py
index bd144df..5853020 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,5 +1,5 @@
-TOP_K = 5
-MIN_SCORE = 0.2
+TOP_K = 8
+MIN_SCORE = 0.35
 
 
 def retrieve(query, index):
```
<!-- /snippet -->

Read the `index` line of each diff: `399da0e..5853020`, then `bd144df..399da0e`, then `bd144df..5853020`. `bd144df` is the blob in HEAD. `399da0e` is the staged blob. `5853020` is the ID that the working-tree content would get. No object with that ID exists until you add the file. Each command compares two of the three.

Now the script puts HEAD's content back into the working tree only. Predict the output of `git diff HEAD`. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch05/three-diffs/05-cancel-out -->
```text
# Put the content of HEAD back into the working tree only. The index still has TOP_K = 8.
$ git restore --source=HEAD src/retriever.py
$ git status --short
MM src/retriever.py
$ git diff HEAD
$ git diff --cached --stat
 src/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat
 src/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# The files on disk match HEAD, yet a commit made now would set TOP_K to 8.
```
<!-- /snippet -->

Nothing. `git diff HEAD` is empty, because the files on disk equal HEAD. The other two comparisons each show one changed line, in opposite directions, and a commit made now would set `TOP_K` to 8.

**[TERMINAL]** Caption bar: `labs/ch05/add-patch.sh`.

```bash
labs/run ch05/add-patch
```

<!-- snippet: ch05/add-patch/01-the-diff -->
```text
$ git diff --stat
 src/retriever.py | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)
$ git diff
diff --git a/src/retriever.py b/src/retriever.py
index 177cb37..e548d1b 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,12 +1,14 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
@@ -18,4 +20,5 @@ def retrieve(query_vec, index):
     query_vec = normalize(query_vec)
     scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
     scored.sort(reverse=True)
+    print("DEBUG scored:", scored)
     return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
```
<!-- /snippet -->

The file from the hook, with its three edits. A tuning change, `TOP_K`.

A bug fix, the guard for a zero vector. And a debug print.

<!-- snippet: ch05/add-patch/02-help -->
```text
# Answer "?" to see what each letter does, then "q" to leave without staging anything.
$ git add -p
diff --git a/src/retriever.py b/src/retriever.py
index 177cb37..e548d1b 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,12 +1,14 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? ?
y - stage this hunk
n - do not stage this hunk
q - quit; do not stage this hunk or any of the remaining ones
a - stage this hunk and all later hunks in the file
d - do not stage this hunk or any of the later hunks in the file
j - go to the next undecided hunk, roll over at the bottom
J - go to the next hunk, roll over at the bottom
k - go to the previous undecided hunk, roll over at the top
K - go to the previous hunk, roll over at the top
g - select a hunk to go to
/ - search for a hunk matching the given regex
s - split the current hunk into smaller hunks
e - manually edit the current hunk
p - print the current hunk
P - print the current hunk using the pager
? - print help
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? q
```
<!-- /snippet -->

Answering `?` prints what each letter does, and `q` leaves without staging anything.

Now the real pass. The fix must become a commit of its own. Try it now, on paper, thirty seconds: write the letters you would answer, hunk by hunk. Pause me, and write your answer.

**[PAUSE]**

<!-- snippet: ch05/add-patch/03-split-and-choose -->
```text
# Answers: s (split), n (TOP_K: not in this commit), y (the fix), n (the debug print).
$ git add -p
diff --git a/src/retriever.py b/src/retriever.py
index 177cb37..e548d1b 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,12 +1,14 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? s
Split into 2 hunks.
@@ -1,9 +1,9 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
(1/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? n
@@ -5,8 +5,10 @@
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
(2/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -18,4 +20,5 @@ def retrieve(query_vec, index):
     query_vec = normalize(query_vec)
     scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
     scored.sort(reverse=True)
+    print("DEBUG scored:", scored)
     return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
(3/3) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n
```
<!-- /snippet -->

Git first offered two hunks, because the `TOP_K` line and the guard were close enough to share context. `s` split the first one: the counter went from one of two to one of three. The answers were no, yes, no. If you forgot the split, that's normal. Almost everyone does the first time.

<!-- snippet: ch05/add-patch/04-result -->
```text
$ git status --short
MM src/retriever.py
$ git diff --cached
diff --git a/src/retriever.py b/src/retriever.py
index 177cb37..a7cba42 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -7,6 +7,8 @@ MIN_SCORE = 0.2
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
```
<!-- /snippet -->

`MM`, and `git diff --cached` shows the guard alone. The staged blob is `a7cba42`. HEAD's blob is `177cb37`, with none of the three edits. The working tree would be `e548d1b`, with all three. The middle one has never run anywhere. That's the file from the hook, and now you know its ID.

<!-- snippet: ch05/add-patch/05-export-the-proposed-commit -->
```text
# The staged snapshot has never existed as files. Export it to test it.
$ git checkout-index --all --prefix=../staged-snapshot/
$ diff ../staged-snapshot/src/retriever.py src/retriever.py
4c4
< TOP_K = 5
---
> TOP_K = 8
22a23
>     print("DEBUG scored:", scored)
```
<!-- /snippet -->

This is the point of the whole segment. `git checkout-index --all --prefix=../staged-snapshot/` 🟢 SAFE exports the staged snapshot as files. The `diff` confirms that the export lacks the two lines you left out. Run your tests in that directory. Then you've tested what you're about to commit, and not what happens to be on your disk.

<!-- snippet: ch05/add-patch/06-commit-and-continue -->
```text
$ git commit -m "Return zero vectors unchanged from normalize"
[main 600582d] Return zero vectors unchanged from normalize
 1 file changed, 2 insertions(+)
# Second pass: y (TOP_K), n (the debug print).
$ git add -p
diff --git a/src/retriever.py b/src/retriever.py
index a7cba42..e548d1b 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,7 +1,7 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -20,4 +20,5 @@ def retrieve(query_vec, index):
     query_vec = normalize(query_vec)
     scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
     scored.sort(reverse=True)
+    print("DEBUG scored:", scored)
     return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n

$ git commit -m "Raise TOP_K to 8"
[main 1d34c0f] Raise TOP_K to 8
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff
diff --git a/src/retriever.py b/src/retriever.py
index 11a965e..e548d1b 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -20,4 +20,5 @@ def retrieve(query_vec, index):
     query_vec = normalize(query_vec)
     scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
     scored.sort(reverse=True)
+    print("DEBUG scored:", scored)
     return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
```
<!-- /snippet -->

Commit the fix, then a second pass: yes to `TOP_K`, no to the debug print. Two commits, each doing one thing, and a remainder that is never committed.

**[TERMINAL]** Caption bar: `labs/ch05/add-patch-edit.sh`.

```bash
labs/run ch05/add-patch-edit
```

<!-- snippet: ch05/add-patch-edit/01-cannot-split -->
```text
# The changed lines touch each other, so the prompt offers no "s". Typing it anyway:
$ git add -p
diff --git a/config/settings.yaml b/config/settings.yaml
index bfcfe5c..d56fa8e 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? s
Sorry, cannot split this hunk
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? q
```
<!-- /snippet -->

Here the changed lines touch each other, so the prompt offers no `s`, and typing it anyway doesn't help.

<!-- snippet: ch05/add-patch-edit/02-edit -->
```text
# Answer "e". In the editor, delete the line "+debug: true", then save and close.
$ git add -p
diff --git a/config/settings.yaml b/config/settings.yaml
index bfcfe5c..d56fa8e 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? e
--- the hunk file as Git opened it in the editor ---
# Manual hunk edit mode -- see bottom for a quick guide.
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
# ---
# To remove '-' lines, make them ' ' lines (context).
# To remove '+' lines, delete them.
# Lines starting with # will be removed.
# If the patch applies cleanly, the edited hunk will immediately be marked for staging.
# If it does not apply cleanly, you will be given an opportunity to
# edit again.  If all lines of the hunk are removed, then the edit is
# aborted and the hunk is left unchanged.
--- the hunk as saved (comment lines left out) ---
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
 max_tokens: 512
```
<!-- /snippet -->

The answer `e` opens the hunk as a patch, with Git's own instructions below it. In the editor, the line `+debug: true` is deleted.

<!-- snippet: ch05/add-patch-edit/03-result -->
```text
$ git status --short
MM config/settings.yaml
$ git diff --cached
diff --git a/config/settings.yaml b/config/settings.yaml
index bfcfe5c..50f69e6 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,4 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
 max_tokens: 512
$ git diff
diff --git a/config/settings.yaml b/config/settings.yaml
index 50f69e6..d56fa8e 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,5 @@
 model: small-v1
 top_k: 8
 temperature: 0.2
+debug: true
 max_tokens: 512
```
<!-- /snippet -->

Staged: the two settings. Not staged: the debug line.

**[TERMINAL]** Caption bar: `labs/ch05/intent-to-add.sh`.

```bash
labs/run ch05/intent-to-add
```

A new file exists. Predict what `git diff` shows for it. Make your prediction.

<!-- snippet: ch05/intent-to-add/01-untracked-is-invisible-to-diff -->
```text
$ git status --short
?? src/prompts.py
$ git diff
# A new file does not appear in "git diff": there is no index entry to compare it with.
```
<!-- /snippet -->

Nothing: there's no index entry to compare it with.

<!-- snippet: ch05/intent-to-add/02-add-n -->
```text
$ git add -N src/prompts.py
$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	new file:   src/prompts.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git ls-files --stage
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	src/prompts.py
```
<!-- /snippet -->

After `git add -N` 🟢 SAFE, status lists the path as a new file under "Changes not staged for commit", and its entry holds `e69de29`, the ID of the empty blob.

<!-- snippet: ch05/intent-to-add/03-now-diff-sees-it -->
```text
$ git diff
diff --git a/src/prompts.py b/src/prompts.py
new file mode 100644
index 0000000..bdcb5f9
--- /dev/null
+++ b/src/prompts.py
@@ -0,0 +1,2 @@
+SYSTEM = "You are a support assistant."
+MAX_TURNS = 6
$ git diff --cached
# Nothing is staged: the entry is a placeholder, and "git commit" has nothing to record.
$ git commit -m "Add prompts"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	new file:   src/prompts.py

no changes added to commit (use "git add" and/or "git commit -a")
[exit status: 1]
```
<!-- /snippet -->

`git diff` shows the whole file as an addition, `git diff --cached` shows nothing, and `git commit` refuses: nothing is staged.

<!-- snippet: ch05/intent-to-add/04-index-version -->
```text
# The intent-to-add flag lives in an extended flags field, which needs index version 3.
$ git update-index --show-index-version
3
$ git add src/prompts.py
$ git ls-files --stage
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 bdcb5f9f68e5c6e542c2b7455388bef666386e93 0	src/prompts.py
$ git update-index --show-index-version
2
```
<!-- /snippet -->

And the index version: 3 while the intent-to-add entry exists, 2 again after the real add.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Reading an empty `git diff HEAD` as "the next commit changes nothing".** Root cause: two differences cancelled; the working tree equals HEAD while the index differs from both.
2. **Committing a partially staged file without testing it.** Root cause: the tests ran against the working tree, and the index holds a version that never existed as a file.
3. **Looking for `s` on a hunk that cannot be split.** Root cause: split is offered only when unchanged lines separate the changes; touching lines are one hunk and need `e`.
4. **A new file is missing from the commit although the diff "looked complete".** Root cause: an untracked file has no index entry, so no diff shows it; `git add -N` when you create it.
5. **Trusting an edited hunk without reading `git diff --cached`.** Root cause: a hunk edit can stage content that exists nowhere, neither in HEAD nor in the file.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook's classic "works on my machine" commit lacks a new file. The code runs locally because the file is on disk. `git diff` looked complete. `git commit -a` skipped the file, for a reason the next video explains. And CI fails with a missing module. `git add -N` when you create a file puts it into every later `git diff`, `git add -p` and `git commit -a`.

And the reason partial staging is worth its price: a commit that does one thing can be reviewed, reverted, cherry-picked and bisected on its own. Later parts of the course teach each of those. Debugging sessions don't produce changes in that shape. Partial staging sorts one messy working tree into such commits. CI is the backstop, and the export is the local check.

## PRACTICE EXERCISE

Your turn. Do Lab 2.2, "Partial staging", in [`lab-manual/m02-working-tree-index-head.md`](../../lab-manual/m02-working-tree-index-head.md).

Before each pass of `git add -p`, write down the answers you intend to give, hunk by hunk. Before each commit, predict the output of `git diff --cached` and of `git diff`, and check both.

## INTERVIEW QUESTION

Q51: "You staged half of a file with `git add -p`, using `e` where `s` was not offered. Why is that commit riskier than a normal one, what can `e` get wrong, and how do you test what you are about to commit?"

**[PAUSE]**

Answer out loud. A strong answer counts the versions of the file that exist after the partial add and says which one was run. It explains what an edited hunk can produce that a split can't. And it ends with a concrete procedure for testing the staged snapshot, with the backstop behind it.

## RECAP

**[ANIMATION]** trees: file=src/retriever.py steps=setup,edit,add,commit title=Three_places,_three_diffs

Let's land this. You should now be able to say, in your own words: `git diff` compares the index with the working tree, `git diff --cached` compares HEAD with the index, and `git diff HEAD` compares HEAD with the working tree. Two of them can cancel.

**[ANIMATION]** end

`git add -p` stages chosen hunks. I split with `s` when there's context between changes, and edit with `e` when there isn't. A partially staged commit records a tree that never existed in my working tree, so I export it with `git checkout-index` and test that. And `git add -N` gives a new file an entry with no content, so that diffs and the hunk selector can see it.

## HOMEWORK

- Read sections 5.4 to 5.6 of [Chapter 5](../../textbook/ch05-index.md).
- Do Exercise 2.3, Level 1, "three diffs, three comparisons", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
- Challenge: Exercise 2.8, Level 3, "the commit that took more than was staged", in the same file.

Today you sorted one messy file into clean commits, and you know how to test a snapshot that never existed on disk. Do the partial staging lab before the next video. Next time: staging deletions and renames, the scope of `git add`, and unstaging three ways. Until then, look at the state first and type second. See you in the next one.

# Module 9 labs: Rebase

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" below is real output from a replay script in `labs/ch09/`.

These seven labs belong to [Chapter 9, Rebase](../textbook/ch09-rebase.md). Read the chapter sections named under "Prerequisites" first. The general rules for labs are in the [lab manual README](README.md).

## How the labs of this module work

Each lab has a setup script and a replay script.

```bash
bash labs/ch09/setup-09-1-clean-up-branch.sh     # builds the starting repository for Lab 9.1
labs/shell m09-1                                 # opens the isolated lab shell in that sandbox
cd ragkit                                        # the setup script prints this line for you
```

```bash
labs/run ch09/lab-09-1-clean-up-branch           # replays the whole lab and prints the transcript
```

Three things to know before you start:

- **The starting commits have the IDs printed in this manual**, because the setup script pins the clock. Commits that you create by hand get other IDs, because your clock is real. Compare shapes and subjects, not IDs.
- **Interactive rebases open your editor.** In the transcripts a script plays your part: the block "as Git opened it" is what your editor shows (plus a comment block), and the block "as saved" is what you should have when you save and close. If you have never chosen an editor, Git starts `vi`: press `i` to edit, then `Esc`, `:wq`, `Enter` to save and quit. `git config set --global core.editor nano` inside the lab shell chooses another one and touches only the lab configuration.
- **Predict first.** Each lab asks you to write something down before a command runs. Do it on paper. The labs are about the difference between what you expected and what Git did.

## Lab 9.1: Clean up a messy branch

### Objective

Turn six work-in-progress commits into three reviewable ones with a single interactive rebase, prove that the content changed only where you intended, then lose a commit through a slip in the editor, find out, and get it back.

### Prerequisites

Chapter 9, sections 9.4, 9.6 and 9.16. You can read `git log --oneline` and you can save a file in your editor.

### Setup

```bash
bash labs/ch09/setup-09-1-clean-up-branch.sh
labs/shell m09-1
cd ragkit
```

### Commands

Look at the branch and decide, on paper, which commits belong together:

```bash
git log --oneline --decorate
```

Start the rebase and edit the list so that it reads as below. Change the first word of each line and move the line of "fix test" up; leave the IDs alone.

```bash
git rebase -i main
```

```text
pick   d33e9b2 # Add exact_match metric
fixup  a1056e1 # wip
reword cdb5f2f # add test
fixup  8313de0 # fix test                     (moved up from the last line)
drop   25dc48e # debug print
reword 031999d # Add token-level F1 metirc
```

Git opens the editor twice more, once for each `reword`. Type `Test exact_match, including surrounding whitespace` the first time and `Add token-level F1 metric` the second time. Then inspect the result:

```bash
git log --oneline --decorate
git reflog -8
git diff ORIG_HEAD HEAD
sh scripts/check.sh
```

### Expected output

<!-- snippet: ch09/lab-09-1-clean-up-branch/01-start -->
```text
$ git log --oneline --decorate
8313de0 (HEAD -> feat/metrics) fix test
031999d Add token-level F1 metirc
25dc48e debug print
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-1-clean-up-branch/02-rebase -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
fixup a1056e1 # wip
reword cdb5f2f # add test
fixup 8313de0 # fix test
drop 25dc48e # debug print
reword 031999d # Add token-level F1 metirc
Rebasing (2/6)
Rebasing (3/6)
[detached HEAD 0a6fabe] Test exact_match, including surrounding whitespace
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 4 insertions(+)
 create mode 100644 tests/test_metrics.py
Rebasing (4/6)
Rebasing (5/6)
Rebasing (6/6)
[detached HEAD 9b8b761] Add token-level F1 metric
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-1-clean-up-branch/03-result -->
```text
$ git log --oneline --decorate
9b8b761 (HEAD -> feat/metrics) Add token-level F1 metric
fa94a04 Test exact_match, including surrounding whitespace
24db527 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-1-clean-up-branch/03a-reflog -->
```text
$ git reflog -8
9b8b761 HEAD@{0}: rebase (finish): returning to refs/heads/feat/metrics
9b8b761 HEAD@{1}: rebase (reword): Add token-level F1 metric
3ecb656 HEAD@{2}: rebase (reword): Add token-level F1 metirc
fa94a04 HEAD@{3}: rebase (fixup): Test exact_match, including surrounding whitespace
0a6fabe HEAD@{4}: rebase (reword): Test exact_match, including surrounding whitespace
6f5c1b6 HEAD@{5}: rebase (reword): add test
24db527 HEAD@{6}: rebase (fixup): Add exact_match metric
d33e9b2 HEAD@{7}: rebase (start): checkout main
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-1-clean-up-branch/04-verify -->
```text
$ git diff ORIG_HEAD HEAD
diff --git a/eval/metrics.py b/eval/metrics.py
index ae2191a..652e0e2 100644
--- a/eval/metrics.py
+++ b/eval/metrics.py
@@ -1,3 +1,2 @@
 def exact_match(pred, gold):
-    print("DEBUG", pred, gold)
     return pred.strip() == gold.strip()
$ sh scripts/check.sh
check passed
```
<!-- /snippet -->

### What happened internally

Git wrote your six lines into `.git/rebase-merge/` and executed them in order on a detached HEAD. The reflog lists the steps, newest first. The start entry names `d33e9b2`, not the tip of `main`: line 1 would have recreated a commit that already sits on `main`, so Git began at that commit, which is why progress starts at `(2/6)`. The first `fixup` made `24db527`, the first commit plus the "wip" change. Each `reword` appears twice, once for the replay with the old message (`6f5c1b6`, `3ecb656`) and once for the commit with your new message (`0a6fabe`, `9b8b761`). The `fixup` after the first reword replaced `0a6fabe` with `fa94a04`. `drop` left no entry, because nothing was replayed. Six commits were created and three of them are in the branch; the others stay in the object database, reachable only through this reflog. When the list was empty, Git moved `feat/metrics` to the last commit and attached HEAD to it. `ORIG_HEAD` kept the old tip, `8313de0`. The diff against it is the audit: one line gone, the debug print, and nothing else changed, although every commit of the branch was rewritten, folded or dropped.

### Checkpoint

Before you continue, all three must be true: `git log --oneline main..HEAD` shows three commits with the subjects above; `git diff ORIG_HEAD HEAD` shows exactly one deleted line; `sh scripts/check.sh` prints `check passed`. If the diff shows more, compare your saved list with the one in the expected output.

### Failure scenario

Run a second interactive rebase and delete the third line, the F1 commit, as if your finger had slipped (`dd` in `vi`). Save and close.

```bash
git rebase -i main
git log --oneline --decorate
git diff --stat ORIG_HEAD HEAD
git range-diff main ORIG_HEAD HEAD
```

<!-- snippet: ch09/lab-09-1-clean-up-branch/05-failure -->
```text
# A second interactive rebase. The line of the F1 commit is deleted by accident.
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 24db527 # Add exact_match metric
pick fa94a04 # Test exact_match, including surrounding whitespace
pick 9b8b761 # Add token-level F1 metric
--- todo list as saved ---
pick 24db527 # Add exact_match metric
pick fa94a04 # Test exact_match, including surrounding whitespace
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
fa94a04 (HEAD -> feat/metrics) Test exact_match, including surrounding whitespace
24db527 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-1-clean-up-branch/06-diagnose -->
```text
$ git diff --stat ORIG_HEAD HEAD
 eval/f1.py | 4 ----
 1 file changed, 4 deletions(-)
$ git range-diff main ORIG_HEAD HEAD
1:  24db527 = 1:  24db527 Add exact_match metric
2:  fa94a04 = 2:  fa94a04 Test exact_match, including surrounding whitespace
3:  9b8b761 < -:  ------- Add token-level F1 metric
```
<!-- /snippet -->

No warning, no error. A commit and a file are gone, and only the two diagnosis commands say so.

### Recovery

```bash
git reset --hard ORIG_HEAD
git log --oneline --decorate
git config set rebase.missingCommitsCheck error
git rebase -i main            # delete the third line again
git rebase --abort
```

<!-- snippet: ch09/lab-09-1-clean-up-branch/07-recovery -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at 9b8b761 Add token-level F1 metric
$ git log --oneline --decorate
9b8b761 (HEAD -> feat/metrics) Add token-level F1 metric
fa94a04 Test exact_match, including surrounding whitespace
24db527 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-1-clean-up-branch/08-prevention -->
```text
$ git config set rebase.missingCommitsCheck error
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 24db527 # Add exact_match metric
pick fa94a04 # Test exact_match, including surrounding whitespace
pick 9b8b761 # Add token-level F1 metric
--- todo list as saved ---
pick 24db527 # Add exact_match metric
pick fa94a04 # Test exact_match, including surrounding whitespace
Warning: some commits may have been dropped accidentally.
Dropped commits (newer to older):
 - 9b8b761 # Add token-level F1 metric
To avoid this message, use "drop" to explicitly remove a commit.

Use 'git config rebase.missingCommitsCheck' to change the level of warnings.
The possible behaviours are: ignore, warn, error.

You can fix this with 'git rebase --edit-todo' and then run 'git rebase --continue'.
Or you can abort the rebase with 'git rebase --abort'.
$ git rebase --abort
```
<!-- /snippet -->

🔴 `git reset --hard` overwrites the working tree; it is safe here because `git status` was clean. With the check set to `error`, the same slip stops the rebase before anything is executed and names the missing commit.

### Verification

```bash
git status --short --branch
git log --oneline main..HEAD
sh scripts/check.sh
```

<!-- snippet: ch09/lab-09-1-clean-up-branch/09-verification -->
```text
$ git status --short --branch
## feat/metrics
$ git log --oneline main..HEAD
9b8b761 Add token-level F1 metric
fa94a04 Test exact_match, including surrounding whitespace
24db527 Add exact_match metric
$ sh scripts/check.sh
check passed
```
<!-- /snippet -->

### Questions

1. Why did the first rebase report `Rebasing (2/6)` as its first step and never `(1/6)`?
2. The transcript shows `[detached HEAD 0a6fabe] Test exact_match, including surrounding whitespace`, but the final log lists `fa94a04` under that subject. Explain both IDs.
3. Every commit of the branch was rewritten, folded or dropped, yet `git diff ORIG_HEAD HEAD` shows one line. What does that diff prove, and what would it have shown if you had also lost a commit?
4. In the failure scenario, which other handles besides `ORIG_HEAD` name the lost tip? When can you not trust `ORIG_HEAD`?
5. With `rebase.missingCommitsCheck=error`, how do you remove a commit on purpose?

## Lab 9.2: Transplant a branch with `--onto`

### Objective

Move only your own commits from a colleague's unmerged experiment onto `main`, see what the short form of the command does instead, and repair that without going back first.

### Prerequisites

Chapter 9, section 9.5. Lab 9.1, for `ORIG_HEAD`.

### Setup

```bash
bash labs/ch09/setup-09-2-transplant-onto.sh
labs/shell m09-2
cd ragkit
```

You are on `fix/empty-query`. By mistake you cut it from Asha's branch `exp/hybrid-search`, not from `main`.

### Commands

```bash
git log --graph --decorate --all --format="%h %an: %s%d"
git log --oneline main..fix/empty-query
git log --oneline exp/hybrid-search..fix/empty-query
```

Before the next command, write down how many commits it will replay and which commit they will sit on.

```bash
git rebase --onto main exp/hybrid-search fix/empty-query
git log --oneline --graph --decorate --all
git diff --stat main...fix/empty-query
```

### Expected output

<!-- snippet: ch09/lab-09-2-transplant-onto/01-start -->
```text
$ git log --graph --decorate --all --format="%h %an: %s%d"
* eec3bdd Lab User: Add licence (main)
| * 5e851ce Lab User: Test empty-query handling (HEAD -> fix/empty-query)
| * 8bd89c8 Lab User: Reject empty queries
| * 840de86 Asha Rao: Experiment: blend BM25 and vector scores (exp/hybrid-search)
| * a68bfe2 Asha Rao: Experiment: BM25 fallback
|/  
* a8e7dbb Lab User: Add README
* 8afc6bd Lab User: Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-2-transplant-onto/02-which-commits -->
```text
$ git log --oneline main..fix/empty-query
5e851ce Test empty-query handling
8bd89c8 Reject empty queries
840de86 Experiment: blend BM25 and vector scores
a68bfe2 Experiment: BM25 fallback
$ git log --oneline exp/hybrid-search..fix/empty-query
5e851ce Test empty-query handling
8bd89c8 Reject empty queries
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-2-transplant-onto/03-onto -->
```text
$ git rebase --onto main exp/hybrid-search fix/empty-query
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/empty-query.
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-2-transplant-onto/04-result -->
```text
$ git log --oneline --graph --decorate --all
* 1a0bb61 (HEAD -> fix/empty-query) Test empty-query handling
* 56667eb Reject empty queries
* eec3bdd (main) Add licence
| * 840de86 (exp/hybrid-search) Experiment: blend BM25 and vector scores
| * a68bfe2 Experiment: BM25 fallback
|/  
* a8e7dbb Add README
* 8afc6bd Add retriever and model config
$ git diff --stat main...fix/empty-query
 app/retriever.py        | 2 ++
 tests/test_retriever.py | 4 ++++
 2 files changed, 6 insertions(+)
```
<!-- /snippet -->

### What happened internally

The three names answered three questions. `fix/empty-query` is the branch that was rewritten. `exp/hybrid-search` is the boundary: the commits replayed are `exp/hybrid-search..fix/empty-query`, the two that the second `git log` printed. `main` is where the copies were built. Asha's two commits were not replayed and her branch ref was not touched. The three-dot diff compares your branch with its merge base with `main`, which is now `main` itself, so it lists what your branch adds: two files.

### Checkpoint

The graph shows `fix/empty-query` directly on top of `main`, and `exp/hybrid-search` where it was. `git diff --stat main...fix/empty-query` lists `app/retriever.py` and `tests/test_retriever.py` and nothing else.

### Failure scenario

Go back to the start and use the form most people type first:

```bash
git reset --hard ORIG_HEAD
git rebase main
git log --oneline --graph --decorate --all
git log --format="%h author %an, committer %cn: %s" main..HEAD
git diff --stat main...HEAD
```

<!-- snippet: ch09/lab-09-2-transplant-onto/05-failure -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at 5e851ce Test empty-query handling
# The tempting short form. It replays everything that is not on main, the experiment included.
$ git rebase main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/fix/empty-query.
$ git log --oneline --graph --decorate --all
* c3214f8 (HEAD -> fix/empty-query) Test empty-query handling
* ddd5e71 Reject empty queries
* 1090745 Experiment: blend BM25 and vector scores
* 18e4489 Experiment: BM25 fallback
* eec3bdd (main) Add licence
| * 840de86 (exp/hybrid-search) Experiment: blend BM25 and vector scores
| * a68bfe2 Experiment: BM25 fallback
|/  
* a8e7dbb Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-2-transplant-onto/06-diagnose -->
```text
$ git log --format="%h author %an, committer %cn: %s" main..HEAD
c3214f8 author Lab User, committer Lab User: Test empty-query handling
ddd5e71 author Lab User, committer Lab User: Reject empty queries
1090745 author Asha Rao, committer Lab User: Experiment: blend BM25 and vector scores
18e4489 author Asha Rao, committer Lab User: Experiment: BM25 fallback
$ git diff --stat main...HEAD
 app/blend.py            | 2 ++
 app/bm25.py             | 2 ++
 app/retriever.py        | 2 ++
 tests/test_retriever.py | 4 ++++
 4 files changed, 10 insertions(+)
```
<!-- /snippet -->

Four commits were replayed. Your branch now carries copies of Asha's unreviewed experiment, with her as author and you as committer, and a pull request from it would add four files.

### Recovery

You do not have to undo anything. Name the boundary by counting: the last two commits are yours.

```bash
git rebase --onto main HEAD~2
git log --oneline --graph --decorate --all
```

<!-- snippet: ch09/lab-09-2-transplant-onto/07-recovery -->
```text
# No need to go back first: name the range by counting. HEAD~2 is the last commit that is not yours.
$ git rebase --onto main HEAD~2
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/empty-query.
$ git log --oneline --graph --decorate --all
* de69db4 (HEAD -> fix/empty-query) Test empty-query handling
* 982da17 Reject empty queries
* eec3bdd (main) Add licence
| * 840de86 (exp/hybrid-search) Experiment: blend BM25 and vector scores
| * a68bfe2 Experiment: BM25 fallback
|/  
* a8e7dbb Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

### Verification

```bash
git log --format="%h %an: %s" main..fix/empty-query
git diff --stat main...fix/empty-query
git status --short --branch
```

<!-- snippet: ch09/lab-09-2-transplant-onto/08-verification -->
```text
$ git log --format="%h %an: %s" main..fix/empty-query
de69db4 Lab User: Test empty-query handling
982da17 Lab User: Reject empty queries
$ git diff --stat main...fix/empty-query
 app/retriever.py        | 2 ++
 tests/test_retriever.py | 4 ++++
 2 files changed, 6 insertions(+)
$ git status --short --branch
## fix/empty-query
```
<!-- /snippet -->

### Questions

1. In `git rebase --onto main exp/hybrid-search fix/empty-query`, what is the role of each of the three names? Which of them may be left out when you are already on the branch?
2. After the failure, the experiment commits on your branch read "author Asha Rao, committer Lab User". Explain both halves.
3. The recovery used `HEAD~2` as the boundary. Why was that correct? What would `git rebase --onto main HEAD~3` have produced?
4. Git replayed Asha's commits without asking. Which fact about branches explains why Git could not know they were not yours?
5. Asha later deletes `exp/hybrid-search`. What happens to your transplanted branch?

## Lab 9.3: Autosquash fixups

### Objective

Answer review comments with fixup commits, fold them into the commits they belong to with `--autosquash`, and handle a fixup that does not fold cleanly.

### Prerequisites

Chapter 9, sections 9.6 and 9.7.

### Setup

```bash
bash labs/ch09/setup-09-3-autosquash-fixups.sh
labs/shell m09-3
cd ragkit
```

`feat/metrics` has three clean commits and is under review.

### Commands

Review comment 1: `exact_match` must ignore surrounding whitespace. In `eval/metrics.py`, change the return line to `return pred.strip() == gold.strip()`. That belongs to the first commit of the branch:

```bash
git log --oneline --decorate
git commit -a --fixup=HEAD~2
```

Review comment 2: F1 should be case-insensitive. In `eval/f1.py`, change the first line of the function body to `p, g = set(pred.lower().split()), set(gold.lower().split())`. That belongs to the F1 commit, which is now `HEAD~1`:

```bash
git commit -a --fixup=HEAD~1
git log --oneline --decorate
```

Write down the order in which the five commits will appear in the list. Then:

```bash
git rebase -i --autosquash main          # read the list, save it unchanged
git log --oneline --decorate
git diff --stat ORIG_HEAD HEAD
git show --stat --format="%h %s" HEAD~2
```

### Expected output

<!-- snippet: ch09/lab-09-3-autosquash-fixups/01-start -->
```text
$ git log --oneline --decorate
a25e84c (HEAD -> feat/metrics) Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-3-autosquash-fixups/02-first-fixup -->
```text
# Edit eval/metrics.py: compare pred.strip() with gold.strip().
$ git commit -a --fixup=HEAD~2
[feat/metrics a6320f4] fixup! Add exact_match metric
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-3-autosquash-fixups/03-second-fixup -->
```text
# Edit eval/f1.py: lower-case both strings before splitting.
$ git commit -a --fixup=HEAD~1
[feat/metrics a4130ba] fixup! Add token-level F1 metric
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --decorate
a4130ba (HEAD -> feat/metrics) fixup! Add token-level F1 metric
a6320f4 fixup! Add exact_match metric
a25e84c Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-3-autosquash-fixups/04-autosquash -->
```text
$ git rebase -i --autosquash main
--- todo list as Git opened it (comment lines removed) ---
pick 143e55a # Add exact_match metric
fixup a6320f4 # fixup! Add exact_match metric
pick 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
fixup a4130ba # fixup! Add token-level F1 metric
--- todo list as saved ---
pick 143e55a # Add exact_match metric
fixup a6320f4 # fixup! Add exact_match metric
pick 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
fixup a4130ba # fixup! Add token-level F1 metric
Rebasing (2/5)
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-3-autosquash-fixups/05-result -->
```text
$ git log --oneline --decorate
ea6bf96 (HEAD -> feat/metrics) Add token-level F1 metric
2b30819 Test exact_match
fa4c85b Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git diff --stat ORIG_HEAD HEAD
$ git show --stat --format="%h %s" HEAD~2
fa4c85b Add exact_match metric

 eval/metrics.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

### What happened internally

`git commit --fixup=<commit>` made an ordinary commit whose subject is `fixup!` followed by the subject of the target. `--autosquash` read those subjects, moved each fixup commit directly below its target and changed its instruction from `pick` to `fixup`. The rebase then melded each pair. `git diff --stat ORIG_HEAD HEAD` prints nothing because the tree at the tip is the same before and after: the same content, cut into three commits and no longer into five.

### Checkpoint

Three commits on top of `main`, none with a subject that starts with `fixup!`, and an empty `git diff --stat ORIG_HEAD HEAD`.

### Failure scenario

Review comment 3: the `exact_match` test should use a value with spaces. In `tests/test_metrics.py`, change `exact_match("Paris", "Paris")` to `exact_match(" Paris ", "Paris")`. It belongs to "Test exact_match", now `HEAD~1`:

```bash
git commit -a --fixup=HEAD~1
git rebase --autosquash main
git status --short
git diff
```

<!-- snippet: ch09/lab-09-3-autosquash-fixups/06-failure -->
```text
# Edit tests/test_metrics.py: the exact_match test should use " Paris " with spaces.
$ git commit -a --fixup=HEAD~1
[feat/metrics 19c5748] fixup! Test exact_match
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git rebase --autosquash main
Rebasing (3/4)
Auto-merging tests/test_metrics.py
CONFLICT (content): Merge conflict in tests/test_metrics.py
error: could not apply 19c5748... fixup! Test exact_match
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 19c5748... # fixup! Test exact_match
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-3-autosquash-fixups/07-diagnose -->
```text
$ git status --short
UU tests/test_metrics.py
$ git diff
diff --cc tests/test_metrics.py
index 128858d,c94c902..0000000
--- a/tests/test_metrics.py
+++ b/tests/test_metrics.py
@@@ -1,4 -1,8 +1,11 @@@
  from eval.metrics import exact_match
 -from eval.f1 import f1
  
  def test_exact_match():
++<<<<<<< HEAD
 +    assert exact_match("Paris", "Paris")
++=======
+     assert exact_match(" Paris ", "Paris")
+ 
+ def test_f1_identical():
+     assert f1("the cat", "the cat") == 1.0
++>>>>>>> 19c5748 (fixup! Test exact_match)
```
<!-- /snippet -->

A one-line change, and the rebase stops with a conflict.

### Recovery

```bash
git rebase --abort
git status --short --branch
git log --oneline --decorate -2
git commit --amend -m "Test exact_match with surrounding whitespace"
```

<!-- snippet: ch09/lab-09-3-autosquash-fixups/08-recovery -->
```text
$ git rebase --abort
$ git status --short --branch
## feat/metrics
$ git log --oneline --decorate -2
19c5748 (HEAD -> feat/metrics) fixup! Test exact_match
ea6bf96 Add token-level F1 metric
# Keep the change as a commit of its own instead of forcing it into the older commit.
$ git commit --amend -m "Test exact_match with surrounding whitespace"
[feat/metrics 772b620] Test exact_match with surrounding whitespace
 Date: Mon Sep 7 10:14:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The change stays, as a commit of its own with an honest subject. That is a legitimate outcome: not every correction has to disappear into an older commit.

### Verification

```bash
git log --oneline --decorate
git log --oneline --grep='^fixup!' main..HEAD
git status --short --branch
```

<!-- snippet: ch09/lab-09-3-autosquash-fixups/09-verification -->
```text
$ git log --oneline --decorate
772b620 (HEAD -> feat/metrics) Test exact_match with surrounding whitespace
ea6bf96 Add token-level F1 metric
2b30819 Test exact_match
fa4c85b Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git log --oneline --grep='^fixup!' main..HEAD
$ git status --short --branch
## feat/metrics
```
<!-- /snippet -->

The second command prints nothing: no unfolded fixup is left. That one line is a usable CI check. The pattern is in single quotes on purpose: in an interactive shell, an exclamation mark inside double quotes can trigger history expansion.

### Questions

1. By what does `--autosquash` connect a fixup commit to its target? What did `--fixup=HEAD~2` contribute to that?
2. `git diff --stat ORIG_HEAD HEAD` printed nothing after the autosquash. What does that prove, and what does it not prove?
3. Why did the third fixup conflict, although it changes a single line that only one earlier commit had written?
4. Name two other ways to recover from the failure, besides keeping the change as its own commit.
5. A colleague sets `rebase.autoSquash=true`, runs `git rebase main`, and pushes. The `fixup!` commits are still there. Why?

## Lab 9.4: A conflict in a rebase, and who is "ours"

### Objective

Read a rebase conflict through the three index stages, resolve it correctly, then resolve it with the wrong side on purpose and watch a commit disappear without an error.

### Prerequisites

Chapter 9, sections 9.4 and 9.11. Chapter 8 for conflict markers and stages.

### Setup

```bash
bash labs/ch09/setup-09-4-conflict-ours-theirs.sh
labs/shell m09-4
cd ragkit
```

`main` changed `TOP_K` from 5 to 8. The second commit of `feat/rerank` changes the same line to 20.

### Commands

```bash
git log --oneline --graph --decorate --all
git rebase main
```

The rebase stops. Before you look, write down which value (5, 8 or 20) you expect in stage 1, stage 2 and stage 3.

```bash
git diff
git ls-files -u
git show :1:app/retriever.py | head -1
git show :2:app/retriever.py | head -1
git show :3:app/retriever.py | head -1
git log --oneline -1 HEAD
git log --oneline -1 REBASE_HEAD
```

Resolve by hand: open `app/retriever.py`, keep `TOP_K = 20`, delete the three marker lines. Then:

```bash
git add app/retriever.py
git rebase --continue          # the editor opens on the commit message: save and close
git log --oneline --graph --decorate --all
```

### Expected output

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/01-start -->
```text
$ git log --oneline --graph --decorate --all
* 439e4c6 (main) Raise TOP_K to 8 after recall regression
| * ad106e3 (HEAD -> feat/rerank) Enable reranking in config
| * 569e6c9 Fetch 20 candidates for the reranker
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/02-conflict -->
```text
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
error: could not apply 569e6c9... Fetch 20 candidates for the reranker
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 569e6c9... # Fetch 20 candidates for the reranker
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/03-read -->
```text
$ git diff
diff --cc app/retriever.py
index ef8c468,e67ee8b..0000000
--- a/app/retriever.py
+++ b/app/retriever.py
@@@ -1,4 -1,4 +1,8 @@@
++<<<<<<< HEAD
 +TOP_K = 8
++=======
+ TOP_K = 20
++>>>>>>> 569e6c9 (Fetch 20 candidates for the reranker)
  
  def retrieve(query):
-     return search(query, TOP_K)
+     return rerank(search(query, TOP_K))
$ git ls-files -u
100644 35e331a734226399bf019e7226f303fcb01eeabb 1	app/retriever.py
100644 ef8c46811d15d96c680eb865313544b9f5680026 2	app/retriever.py
100644 e67ee8b37c4aa0f84cbd0a310f0a7cc7f7c02f00 3	app/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/04-stages -->
```text
$ git show :1:app/retriever.py | head -1
TOP_K = 5
$ git show :2:app/retriever.py | head -1
TOP_K = 8
$ git show :3:app/retriever.py | head -1
TOP_K = 20
$ git log --oneline -1 HEAD
1c9f69a Add reranker skeleton
$ git log --oneline -1 REBASE_HEAD
569e6c9 Fetch 20 candidates for the reranker
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/05-resolve -->
```text
# Edit app/retriever.py: keep TOP_K = 20 and delete the three marker lines.
$ git add app/retriever.py
$ git rebase --continue
[detached HEAD b43f09f] Fetch 20 candidates for the reranker
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --graph --decorate --all
* 8341651 (HEAD -> feat/rerank) Enable reranking in config
* b43f09f Fetch 20 candidates for the reranker
* 1c9f69a Add reranker skeleton
* 439e4c6 (main) Raise TOP_K to 8 after recall regression
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

### What happened internally

The rebase detached HEAD at `main` and replayed "Add reranker skeleton" as `1c9f69a`. Replaying the second commit is a three-way merge into HEAD. Its base, stage 1, is the parent of your commit, where the line said 5. Stage 2, "ours", is HEAD: the tip of `main` plus the one copy, where the line says 8. Stage 3, "theirs", is `REBASE_HEAD`, your commit, where it says 20. Both sides changed the same line, so Git wrote markers and stopped. The second hunk of the combined diff, the `return` line, merged without help: only your side had changed it. `git rebase --continue` committed your staged resolution as the copy of the stopped commit and replayed the third commit.

### Checkpoint

`git log` shows three commits on top of `main`, the middle one being "Fetch 20 candidates for the reranker", and `head -1 app/retriever.py` prints `TOP_K = 20`.

### Failure scenario

Go back and repeat the rebase. This time you reason "I want my version, so: ours".

```bash
git reset --hard ORIG_HEAD
git rebase main
git restore --ours app/retriever.py
git add app/retriever.py
git rebase --continue
git log --oneline main..HEAD
head -1 app/retriever.py
git range-diff main ORIG_HEAD HEAD
```

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/06-failure -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at ad106e3 Enable reranking in config
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
error: could not apply 569e6c9... Fetch 20 candidates for the reranker
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 569e6c9... # Fetch 20 candidates for the reranker
[exit status: 1]
# You want "your" version, so you ask for ours:
$ git restore --ours app/retriever.py
$ git add app/retriever.py
$ git rebase --continue
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/07-diagnose -->
```text
$ git log --oneline main..HEAD
176e323 Enable reranking in config
c36f186 Add reranker skeleton
$ head -1 app/retriever.py
TOP_K = 8
$ git range-diff main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  c36f186 Add reranker skeleton
2:  569e6c9 < -:  ------- Fetch 20 candidates for the reranker
3:  ad106e3 = 2:  176e323 Enable reranking in config
```
<!-- /snippet -->

The rebase reported success. The branch has two commits, the value is 8, and the range-diff marks your commit with `<`: present before, absent now.

### Recovery

```bash
git reset --hard ORIG_HEAD
git rebase -X theirs main
```

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/08-recovery -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at ad106e3 Enable reranking in config
$ git rebase -X theirs main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

`-X theirs` tells the merge machinery in advance to take the side of the commit being replayed in every conflicting hunk. Here that is what you want; it is not a habit to form.

### Verification

```bash
git log --oneline main..HEAD
head -1 app/retriever.py
git diff --stat ORIG_HEAD HEAD
git status --short --branch
```

<!-- snippet: ch09/lab-09-4-conflict-ours-theirs/09-verification -->
```text
$ git log --oneline main..HEAD
be9f6fe Enable reranking in config
5f66ec6 Fetch 20 candidates for the reranker
9fe50cb Add reranker skeleton
$ head -1 app/retriever.py
TOP_K = 20
$ git diff --stat ORIG_HEAD HEAD
$ git status --short --branch
## feat/rerank
```
<!-- /snippet -->

Three commits, the value 20, and an empty diff against the branch as it was before the rebase: `main` changed nothing but the line your branch overrides.

### Questions

1. For each of the three stages, name the commit its content came from and say why that commit plays that role.
2. Why did `git rebase --continue` print no warning when your commit vanished?
3. How would the same conflict have looked if you had run `git merge main` on `feat/rerank`? Which side would `--ours` have been?
4. The recovery used `-X theirs`. Describe a branch on which that option would silently produce a wrong result.
5. Twice in this lab `git reset --hard ORIG_HEAD` returned the branch to `ad106e3`. Which command had written `ORIG_HEAD` each time, and what did each reset itself do to `ORIG_HEAD`?

## Lab 9.5: Break a branch on purpose and recover it

### Objective

Wreck a branch with a careless interactive rebase, recover it with `ORIG_HEAD`, wreck it again in a way that makes `ORIG_HEAD` useless, and recover it through the reflog of the branch.

### Prerequisites

Chapter 9, sections 9.4 and 9.16. Labs 9.1 and 9.4.

### Setup

```bash
bash labs/ch09/setup-09-5-break-and-recover.sh
labs/shell m09-5
cd ragkit
```

### Commands

Record the starting point. Write the ID down; it is your proof of recovery later.

```bash
git log --oneline --graph --decorate --all
git rev-parse HEAD
```

Now the careless rebase. In the list, change the first line to `drop` and the third to `squash`. When the editor opens for the combined message, replace everything with `wip`.

```bash
git rebase -i main
git log --oneline --decorate main..HEAD
ls app
```

Undo it the quick way:

```bash
git rev-parse ORIG_HEAD
git reset --hard ORIG_HEAD
git log --oneline --decorate main~2..HEAD
```

### Expected output

<!-- snippet: ch09/lab-09-5-break-and-recover/01-start -->
```text
$ git log --oneline --graph --decorate --all
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
| * bd62876 (HEAD -> feat/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
$ git rev-parse HEAD
bd62876fcabf99cc7a75923bcadd8e4c67fe8dd7
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-5-break-and-recover/02-break -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 5ee19f0 # Add reranker skeleton
pick af65a92 # Call reranker from retriever
pick bd62876 # Enable reranking in config
--- todo list as saved ---
drop 5ee19f0 # Add reranker skeleton
pick af65a92 # Call reranker from retriever
squash bd62876 # Enable reranking in config
Rebasing (2/3)
Rebasing (3/3)
[detached HEAD 106957d] wip
 Date: Mon Sep 7 10:04:00 2026 +0530
 2 files changed, 2 insertions(+), 1 deletion(-)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --decorate main..HEAD
106957d (HEAD -> feat/rerank) wip
$ ls app
retriever.py
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-5-break-and-recover/03-orig-head -->
```text
$ git rev-parse ORIG_HEAD
bd62876fcabf99cc7a75923bcadd8e4c67fe8dd7
$ git reset --hard ORIG_HEAD
HEAD is now at bd62876 Enable reranking in config
$ git log --oneline --decorate main~2..HEAD
bd62876 (HEAD -> feat/rerank) Enable reranking in config
af65a92 Call reranker from retriever
5ee19f0 Add reranker skeleton
```
<!-- /snippet -->

### What happened internally

The rebase did what the list said: it left out the commit that adds `app/rerank.py` and melded the other two into one commit with the message "wip". Three commits became one, and a file disappeared from the working tree. None of the original commits was deleted. The branch ref moved to the new commit, `ORIG_HEAD` kept the old tip, and the reflog of the branch gained one line. `git reset --hard ORIG_HEAD` moved the branch back and rewrote the working tree from the old tip.

### Checkpoint

`git rev-parse HEAD` prints the ID you wrote down, and `ls app` lists `rerank.py` again.

### Failure scenario

Repeat the same careless rebase (same two edits, same message). Then, without having noticed the damage, remove "one more commit", and only then reach for the usual remedy:

```bash
git rebase -i main
git reset --hard HEAD~1
git reset --hard ORIG_HEAD
git log --oneline --decorate main..HEAD
```

<!-- snippet: ch09/lab-09-5-break-and-recover/04-failure -->
```text
# The same careless rebase has been run again. Then you tidy up "one more thing":
$ git reset --hard HEAD~1
HEAD is now at 82f1fbb Upgrade model to small-v2
# Now you notice that the branch is ruined and reach for the usual remedy:
$ git reset --hard ORIG_HEAD
HEAD is now at 7793ccb wip
$ git log --oneline --decorate main..HEAD
7793ccb (HEAD -> feat/rerank) wip
```
<!-- /snippet -->

`ORIG_HEAD` took you to the "wip" commit, not to your three commits. The remedy that worked five minutes ago now restores the damage.

### Recovery

```bash
git reflog show feat/rerank
```

<!-- snippet: ch09/lab-09-5-break-and-recover/05-reflog -->
```text
$ git reflog show feat/rerank
7793ccb feat/rerank@{0}: reset: moving to ORIG_HEAD
82f1fbb feat/rerank@{1}: reset: moving to HEAD~1
7793ccb feat/rerank@{2}: rebase (finish): refs/heads/feat/rerank onto 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
bd62876 feat/rerank@{3}: reset: moving to ORIG_HEAD
106957d feat/rerank@{4}: rebase (finish): refs/heads/feat/rerank onto 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
bd62876 feat/rerank@{5}: commit: Enable reranking in config
af65a92 feat/rerank@{6}: commit: Call reranker from retriever
5ee19f0 feat/rerank@{7}: commit: Add reranker skeleton
8afc6bd feat/rerank@{8}: branch: Created from HEAD
```
<!-- /snippet -->

Find the newest line whose ID is the one you wrote down. In the replay it is `feat/rerank@{3}`; if you typed extra commands, your number differs, so go by the ID. Anchor it with a branch, check it, and only then move the real branch:

```bash
git branch rescue/rerank "feat/rerank@{3}"
git log --oneline rescue/rerank -3
git diff --stat rescue/rerank bd62876
git reset --hard rescue/rerank
```

<!-- snippet: ch09/lab-09-5-break-and-recover/06-recovery -->
```text
$ git branch rescue/rerank feat/rerank@{3}
$ git log --oneline rescue/rerank -3
bd62876 Enable reranking in config
af65a92 Call reranker from retriever
5ee19f0 Add reranker skeleton
$ git diff --stat rescue/rerank bd62876
$ git reset --hard rescue/rerank
HEAD is now at bd62876 Enable reranking in config
```
<!-- /snippet -->

### Verification

```bash
git rev-parse HEAD
git log --oneline --graph --decorate --all
git branch -d rescue/rerank
```

<!-- snippet: ch09/lab-09-5-break-and-recover/07-verification -->
```text
$ git rev-parse HEAD
bd62876fcabf99cc7a75923bcadd8e4c67fe8dd7
$ git log --oneline --graph --decorate --all
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
| * bd62876 (HEAD -> feat/rerank, rescue/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
$ git branch -d rescue/rerank
Deleted branch rescue/rerank (was bd62876).
```
<!-- /snippet -->

The ID equals the one from the first step: the branch is not similar to what it was, it is what it was.

### Questions

1. After the first careless rebase, through which names were the three original commits still reachable?
2. In the failure scenario, why did `git reset --hard ORIG_HEAD` land on "wip"? Which command had written `ORIG_HEAD` last?
3. The branch reflog has one line per rebase and the HEAD reflog has one line per step. Which do you read first in an incident, and why?
4. For how long would this recovery have stayed possible with default settings? Name one command that would have ended the possibility sooner.
5. You had the ID on paper and could have typed `git reset --hard bd62876` at once. What is the argument for creating `rescue/rerank` first?

## Lab 9.6: Rebase a shared branch and watch a teammate's history duplicate

### Objective

Rebase and force-push a branch that a teammate has built on, see in her clone what that does, let her make the natural mistake, and repair her history.

### Prerequisites

Chapter 9, sections 9.15 and 9.17. Chapter 12 for fetch and remote-tracking branches.

### Setup

```bash
bash labs/ch09/setup-09-6-shared-branch-duplicates.sh
labs/shell m09-6
cd you
```

The sandbox holds a bare repository `server.git` and two clones. In `you/` you are yourself. In `asha/` Git is configured with Asha's identity, and she has one unpushed commit on `feat/ingest`.

### Commands

In your clone:

```bash
git log --oneline --graph --decorate --all
git rebase main
git push --force-with-lease --force-if-includes
```

Before you switch to Asha's clone, write down what `git status` will say there after a fetch: how many commits ahead, how many behind?

```bash
cd ../asha
git fetch
git status --short --branch
git log --oneline --graph --decorate --all
```

### Expected output

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/01-you-rebase -->
```text
$ git log --oneline --graph --decorate --all
* 589d18b (origin/main, main) Add README
| * dc5df93 (HEAD -> feat/ingest, origin/feat/ingest) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
$ git push --force-with-lease --force-if-includes
To ../server.git
 + dc5df93...8aca274 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/02-asha-sees -->
```text
$ cd ../asha
$ git fetch
From ../server
 + dc5df93...8aca274 feat/ingest -> origin/feat/ingest  (forced update)
   8afc6bd..589d18b  main        -> origin/main
$ git status --short --branch
## feat/ingest...origin/feat/ingest [ahead 3, behind 3]
$ git log --oneline --graph --decorate --all
* 8aca274 (origin/feat/ingest) Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
| * c60bc13 (HEAD -> feat/ingest) Add chunker
| * dc5df93 Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

### What happened internally

Your rebase created copies of "Add document loader" and "Add text cleaner" on top of the new `main` and moved your branch to them. The forced push replaced the server's branch ref; the `+` and the three dots in `+ dc5df93...8aca274` mark a non-fast-forward update. Asha's fetch moved her remote-tracking branch `origin/feat/ingest` to the copies and reported the forced update. Her local branch did not move. It still holds the two original commits and her own, three commits that the new upstream does not have, while the new upstream has three commits (README and the two copies) that she does not have. Hence `ahead 3, behind 3`.

### Checkpoint

In `asha/`, `git status --short --branch` shows `[ahead 3, behind 3]`, and the graph shows two lines that both contain a commit named "Add text cleaner". (Your copies have other IDs than `8aca274`, because you rebased with a real clock.)

### Failure scenario

Still in `asha/`. She does what the status hint and habit suggest:

```bash
git pull --no-rebase
git log --oneline --graph --decorate
git log --format=%s origin/main..HEAD | sort | uniq -d
git cherry -v origin/feat/ingest ORIG_HEAD
```

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/03-failure -->
```text
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 README.md | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
$ git log --oneline --graph --decorate
*   511cfd1 (HEAD -> feat/ingest) Merge branch 'feat/ingest' of ../server into feat/ingest
|\  
| * 8aca274 (origin/feat/ingest) Add text cleaner
| * 0fbfd81 Add document loader
| * 589d18b (origin/main, origin/HEAD) Add README
* | c60bc13 Add chunker
* | dc5df93 Add text cleaner
* | 1279adf Add document loader
|/  
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/04-diagnose -->
```text
$ git log --format=%s origin/main..HEAD | sort | uniq -d
Add document loader
Add text cleaner
$ git cherry -v origin/feat/ingest ORIG_HEAD
- 1279adfb1a9ebc0eec2b0b03c3efc00dedc5d03e Add document loader
- dc5df9356273e7c0c2807ce808c378782ea2525a Add text cleaner
+ c60bc13f871297055fb1d2e19bd6a39f7a4f1f62 Add chunker
```
<!-- /snippet -->

The merge succeeded and the history contains two commits twice. The third command lists every subject that occurs more than once. The fourth compares her pre-merge branch (`ORIG_HEAD`) with the new upstream by patch ID: `-` marks the two commits that upstream already has in another form, `+` the one commit that is hers alone.

### Recovery

Undo the merge, then replay only her own commit onto the new upstream. The boundary is the old upstream tip, `dc5df93`:

```bash
git reset --hard ORIG_HEAD
git rebase --onto origin/feat/ingest dc5df93
git log --oneline --graph --decorate
git push
cd ../you
git pull --ff-only
```

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/05-recovery -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at c60bc13 Add chunker
$ git rebase --onto origin/feat/ingest dc5df93
Rebasing (1/1)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate
* 82659ee (HEAD -> feat/ingest) Add chunker
* 8aca274 (origin/feat/ingest) Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/06-publish -->
```text
$ git push
To ../server.git
   8aca274..82659ee  feat/ingest -> feat/ingest
$ cd ../you
$ git pull --ff-only
From ../server
   8aca274..82659ee  feat/ingest -> origin/feat/ingest
Updating 8aca274..82659ee
Fast-forward
 ingest/chunker.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 ingest/chunker.py
```
<!-- /snippet -->

Her push is an ordinary fast-forward: her branch now extends the server's branch. No force was needed on her side.

### Verification

In `you/`:

```bash
git log --oneline --graph --decorate --all
git log --format=%s origin/main..HEAD | sort | uniq -d
git -C ../asha rev-parse --short HEAD
git rev-parse --short HEAD
```

<!-- snippet: ch09/lab-09-6-shared-branch-duplicates/07-verification -->
```text
$ git log --oneline --graph --decorate --all
* 82659ee (HEAD -> feat/ingest, origin/feat/ingest) Add chunker
* 8aca274 Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD, main) Add README
* 8afc6bd Add retriever and model config
$ git log --format=%s origin/main..HEAD | sort | uniq -d
$ git -C ../asha rev-parse --short HEAD
82659ee
$ git rev-parse --short HEAD
82659ee
```
<!-- /snippet -->

One line of history, no duplicated subject, and both clones on the same commit.

### Questions

1. Asha made one commit. Why did her clone report `ahead 3, behind 3`?
2. Her merge duplicated history. Did it duplicate content? Point to the line of the transcript that tells you.
3. Explain each line of the `git cherry -v origin/feat/ingest ORIG_HEAD` output, and say why this is the information the repair needs.
4. Why is `dc5df93` the right boundary for her rebase? Give two ways to find that commit without having seen it in a transcript.
5. Suppose she had pushed the merge instead of repairing. What would the server's branch contain, and what would you get on your next pull?
6. What should you have done before the rebase, and what should you send her after it?

## Lab 9.7: `--update-refs` on stacked branches

### Objective

Apply a review fix to the bottom branch of a three-branch stack from the top branch, move all three branches with one rebase, then undo that rebase and discover that the undo is per branch.

### Prerequisites

Chapter 9, sections 9.7, 9.9 and 9.16. Lab 9.3.

### Setup

```bash
bash labs/ch09/setup-09-7-update-refs-stack.sh
labs/shell m09-7
cd ragkit
```

You are on `feat/ingest-chunker`, the top of the stack.

### Commands

```bash
git log --oneline --graph --decorate --all
git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/feat
```

Review comment on the bottom branch: open the file with an explicit encoding. In `ingest/loader.py`, change `open(path)` to `open(path, encoding="utf-8")`. The commit it belongs to is three commits below the tip:

```bash
git commit -a --fixup=HEAD~3
```

Write down how many lines the list will have and where the lines that are not commits will stand. Then run the rebase, read the list, and save it unchanged:

```bash
git rebase -i --autosquash --update-refs main
git log --oneline --graph --decorate --all
git show --stat --format="%h %s" feat/ingest-loader
```

### Expected output

<!-- snippet: ch09/lab-09-7-update-refs-stack/01-start -->
```text
$ git log --oneline --graph --decorate --all
* 9cfa98f (main) Add README
| * e86ad55 (HEAD -> feat/ingest-chunker) Make chunk size configurable
| * f3f4739 Add chunker
| * b10b821 (feat/ingest-cleaner) Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
$ git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/feat
e86ad55 feat/ingest-chunker
b10b821 feat/ingest-cleaner
7fea52c feat/ingest-loader
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-7-update-refs-stack/02-fixup -->
```text
# Review comment on the bottom branch: open the file with an explicit encoding. Edit ingest/loader.py.
$ git commit -a --fixup=HEAD~3
[feat/ingest-chunker e9dcf7b] fixup! Close files after loading
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-7-update-refs-stack/03-rebase -->
```text
$ git rebase -i --autosquash --update-refs main
--- todo list as Git opened it (comment lines removed) ---
pick 531d3da # Add document loader
pick 7fea52c # Close files after loading
fixup e9dcf7b # fixup! Close files after loading
update-ref refs/heads/feat/ingest-loader
pick b10b821 # Add text cleaner
update-ref refs/heads/feat/ingest-cleaner
pick f3f4739 # Add chunker
pick e86ad55 # Make chunk size configurable
--- todo list as saved ---
pick 531d3da # Add document loader
pick 7fea52c # Close files after loading
fixup e9dcf7b # fixup! Close files after loading
update-ref refs/heads/feat/ingest-loader
pick b10b821 # Add text cleaner
update-ref refs/heads/feat/ingest-cleaner
pick f3f4739 # Add chunker
pick e86ad55 # Make chunk size configurable
Rebasing (1/8)
Rebasing (2/8)
Rebasing (3/8)
Rebasing (4/8)
Rebasing (5/8)
Rebasing (6/8)
Rebasing (7/8)
Rebasing (8/8)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
Updated the following refs with --update-refs:
	refs/heads/feat/ingest-cleaner
	refs/heads/feat/ingest-loader
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-7-update-refs-stack/04-result -->
```text
$ git log --oneline --graph --decorate --all
* e230553 (HEAD -> feat/ingest-chunker) Make chunk size configurable
* b53aa5a Add chunker
* 3f4aed0 (feat/ingest-cleaner) Add text cleaner
* 82d1b15 (feat/ingest-loader) Close files after loading
* 94deb80 Add document loader
* 9cfa98f (main) Add README
* 8afc6bd Add retriever and model config
$ git show --stat --format="%h %s" feat/ingest-loader
82d1b15 Close files after loading

 ingest/loader.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

### What happened internally

Two options shaped the list. `--autosquash` moved the fixup commit below "Close files after loading" and marked it `fixup`. `--update-refs` found two other branches pointing at commits in the range and added an `update-ref` line after each of those commits. The line for `feat/ingest-loader` stands after the fixup, so that branch ends up on the corrected commit. During the run only HEAD moved. At the end Git updated `feat/ingest-chunker` as usual and then the two other branches, writing "rewritten during rebase" into their reflogs.

### Checkpoint

The graph is one line with three branch labels on it, and `git show --stat feat/ingest-loader` shows a commit whose change to `ingest/loader.py` includes the encoding.

### Failure scenario

You decide the rebase was premature and undo it the way you undid the others:

```bash
git reset --hard ORIG_HEAD
git log --oneline --graph --decorate --all
git reflog show feat/ingest-loader -2
git reflog show feat/ingest-cleaner -2
```

<!-- snippet: ch09/lab-09-7-update-refs-stack/05-failure -->
```text
# You decide the rebase was premature and undo it the usual way:
$ git reset --hard ORIG_HEAD
HEAD is now at e9dcf7b fixup! Close files after loading
$ git log --oneline --graph --decorate --all
* 3f4aed0 (feat/ingest-cleaner) Add text cleaner
* 82d1b15 (feat/ingest-loader) Close files after loading
* 94deb80 Add document loader
* 9cfa98f (main) Add README
| * e9dcf7b (HEAD -> feat/ingest-chunker) fixup! Close files after loading
| * e86ad55 Make chunk size configurable
| * f3f4739 Add chunker
| * b10b821 Add text cleaner
| * 7fea52c Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/lab-09-7-update-refs-stack/06-diagnose -->
```text
$ git reflog show feat/ingest-loader -2
82d1b15 feat/ingest-loader@{0}: rewritten during rebase
7fea52c feat/ingest-loader@{1}: commit: Close files after loading
$ git reflog show feat/ingest-cleaner -2
3f4aed0 feat/ingest-cleaner@{0}: rewritten during rebase
b10b821 feat/ingest-cleaner@{1}: commit: Add text cleaner
```
<!-- /snippet -->

Only the branch you are on came back. The two lower branches still point at the rewritten commits, on a line of history that your top branch no longer shares. The stack is torn in two.

### Recovery

Each branch has its own reflog, and entry 1 of each is its position before the rebase:

```bash
git branch -f feat/ingest-loader "feat/ingest-loader@{1}"
git branch -f feat/ingest-cleaner "feat/ingest-cleaner@{1}"
```

<!-- snippet: ch09/lab-09-7-update-refs-stack/07-recovery -->
```text
$ git branch -f feat/ingest-loader "feat/ingest-loader@{1}"
$ git branch -f feat/ingest-cleaner "feat/ingest-cleaner@{1}"
```
<!-- /snippet -->

### Verification

```bash
git log --oneline --graph --decorate --all
git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/feat
```

<!-- snippet: ch09/lab-09-7-update-refs-stack/08-verification -->
```text
$ git log --oneline --graph --decorate --all
* e9dcf7b (HEAD -> feat/ingest-chunker) fixup! Close files after loading
* e86ad55 Make chunk size configurable
* f3f4739 Add chunker
* b10b821 (feat/ingest-cleaner) Add text cleaner
* 7fea52c (feat/ingest-loader) Close files after loading
* 531d3da Add document loader
| * 9cfa98f (main) Add README
|/  
* 8afc6bd Add retriever and model config
$ git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/feat
e9dcf7b feat/ingest-chunker
b10b821 feat/ingest-cleaner
7fea52c feat/ingest-loader
```
<!-- /snippet -->

The two lower branches are back on `7fea52c` and `b10b821`, the IDs of the first step. The top branch is one commit further than at the start: it holds the fixup commit, not yet folded.

### Questions

1. Where exactly did Git place the two `update-ref` lines, and why does the position of the first one matter for the fixup?
2. The fixup was committed on the top branch. After the rebase, which branches contain the corrected code?
3. Why did `git reset --hard ORIG_HEAD` restore one branch out of three?
4. Suppose `feat/ingest-loader` had been checked out in a second worktree during the rebase. What would `--update-refs` have done with it, and what would `git branch -f` say?
5. After a successful rebase of the stack, what has to be pushed? Write the command.

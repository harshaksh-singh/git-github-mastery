# Module 6 labs: Divergence and merge

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the replay scripts in `labs/ch08/`. Read [Chapter 8](../textbook/ch08-merge.md) first; each lab names the sections it relies on.

## How to run these labs

Every lab starts from a prepared repository of the sample project `evalkit`. From the course root:

```bash
bash labs/ch08/setup-06-1-ff-or-three-way.sh    # builds the starting repository for Lab 6.1
labs/shell m06-1                                # opens the isolated lab shell in that sandbox
cd evalkit
```

The setup script pins the clock and the identities, so the commits you start from have the IDs printed in this manual. Commits that you create by hand get the real time and therefore other IDs. Compare messages, parents and trees, not IDs.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command to see its exit status.
- Lines that start with `#` are notes from the replay script. Where a note says "In your editor", the script made the same edit that you make by hand.
- `git merge --continue` opens your editor with the prepared merge message. Save and close it, or run `git commit --no-edit` instead. Merges without conflict do not open an editor in the lab shell, because the lab environment sets `GIT_MERGE_AUTOEDIT=no`. In your own shell they do.

To see a lab exactly as printed, replay it: `labs/run ch08/lab-06-1-ff-or-three-way`. Answers to the questions are in [solutions/m06-lab-answers.md](../solutions/m06-lab-answers.md). Write your own first.

## Lab 6.1: Predict fast-forward or three-way

### Objective

Predict, from ancestry alone, whether a merge will report "Already up to date.", fast-forward, or create a merge commit. Then undo an accidental fast-forward.

### Prerequisites

Chapter 8, sections 8.2 to 8.4. Chapter 7 for `git merge-base --is-ancestor` and `git rev-list --left-right --count`.

### Setup

```bash
bash labs/ch08/setup-06-1-ff-or-three-way.sh
labs/shell m06-1
cd evalkit
```

You are on `main`. There are three other branches: `fix/typo`, `feature/batch-size` and `feature/judge-prompt`.

### Commands

Look at the graph and fill in the table before you run any merge.

```bash
git log --oneline --graph --all
```

| Branch | Is `main` an ancestor of it? | Is it an ancestor of `main`? | Your prediction for `git merge <branch>` |
|---|---|---|---|
| `fix/typo` | | | |
| `feature/batch-size` | | | |
| `feature/judge-prompt` | | | |

Collect the evidence for each branch (shown for `fix/typo`; repeat for the other two):

```bash
git merge-base --is-ancestor main fix/typo; echo $?
git merge-base --is-ancestor fix/typo main; echo $?
git rev-list --left-right --count main...fix/typo
```

Now merge, in this order:

```bash
git merge fix/typo
git merge --ff-only feature/judge-prompt
git merge feature/batch-size
git merge feature/judge-prompt
```

### Expected output

<!-- snippet: ch08/lab-06-1-ff-or-three-way/01-graph -->
```text
$ git log --oneline --graph --all
* 9661eea Ask the judge for a rationale
| * d1065a4 Raise timeout to 60 seconds
| * 9de7e85 Raise batch size to 32
| * 7d4c459 Pin the eval seed to 42
| * a69ead8 Fix the README wording
|/  
* d43f93e Add a README
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-1-ff-or-three-way/02-evidence -->
```text
# ---- fix/typo
$ git merge-base --is-ancestor main fix/typo
[exit status: 1]
$ git merge-base --is-ancestor fix/typo main
[exit status: 0]
$ git rev-list --left-right --count main...fix/typo
1	0
# ---- feature/batch-size
$ git merge-base --is-ancestor main feature/batch-size
[exit status: 0]
$ git merge-base --is-ancestor feature/batch-size main
[exit status: 1]
$ git rev-list --left-right --count main...feature/batch-size
0	2
# ---- feature/judge-prompt
$ git merge-base --is-ancestor main feature/judge-prompt
[exit status: 1]
$ git merge-base --is-ancestor feature/judge-prompt main
[exit status: 1]
$ git rev-list --left-right --count main...feature/judge-prompt
2	1
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-1-ff-or-three-way/03-merges -->
```text
$ git merge fix/typo
Already up to date.
$ git merge --ff-only feature/judge-prompt
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
$ git merge feature/batch-size
Updating 7d4c459..d1065a4
Fast-forward
 config/eval.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git merge feature/judge-prompt
Merge made by the 'ort' strategy.
 prompts/judge.txt | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

### What happened internally

Two ancestor tests decide everything:

| `main` is an ancestor of the branch | The branch is an ancestor of `main` | Result of `git merge <branch>` |
|---|---|---|
| no | yes | "Already up to date.": nothing moves |
| yes | no | fast-forward: the ref `refs/heads/main` moves, no object is created |
| no | no | true merge: a new commit with two parents |

`fix/typo` is behind `main`, so nothing moved. `git merge --ff-only feature/judge-prompt` found commits on both sides (the counts were 2 and 1), refused with exit status 128 and moved nothing. `feature/batch-size` was strictly ahead: "Updating 7d4c459..d1065a4" is the old and the new value of the `main` ref, and `ORIG_HEAD` now holds `7d4c459`. After that fast-forward, `feature/judge-prompt` had diverged from `main` by four commits against one, and the merge created a commit.

### Checkpoint

```bash
git log --oneline --graph
git cat-file -p HEAD
```

<!-- snippet: ch08/lab-06-1-ff-or-three-way/04-checkpoint -->
```text
$ git log --oneline --graph
*   c77b781 Merge branch 'feature/judge-prompt'
|\  
| * 9661eea Ask the judge for a rationale
* | d1065a4 Raise timeout to 60 seconds
* | 9de7e85 Raise batch size to 32
* | 7d4c459 Pin the eval seed to 42
* | a69ead8 Fix the README wording
|/  
* d43f93e Add a README
* 6ae3c51 Add eval config, judge prompt and metrics
$ git cat-file -p HEAD
tree 389ce9e5444fce42af5340cbf333c7f8dc61b535
parent d1065a4956a57de6490d7c97abfc8b6b3d876611
parent 9661eea21f2da05e3384ab51dcf65c59a26bf207
author Lab User <you@example.com> 1788756780 +0530
committer Lab User <you@example.com> 1788756780 +0530

Merge branch 'feature/judge-prompt'
```
<!-- /snippet -->

Your merge commit has another ID, because its timestamp is yours. Its two `parent` lines and its `tree` line must be identical to the ones above: the first parent is `d1065a4`, the tip of `main` after the fast-forward, and the second is `9661eea`.

### Failure scenario

An unfinished branch is merged into `main` by mistake, and the merge fast-forwards:

```bash
git switch -c wip/streaming
printf "def stream(samples):\n    raise NotImplementedError\n" > evalkit/streaming.py
git add evalkit/streaming.py
git commit -m "WIP: streaming judge client"
git switch main
git merge wip/streaming
git log --oneline -2
```

<!-- snippet: ch08/lab-06-1-ff-or-three-way/05-failure -->
```text
$ git switch -q -c wip/streaming
$ printf "def stream(samples):\n    raise NotImplementedError\n" > evalkit/streaming.py
$ git add evalkit/streaming.py
$ git commit -q -m "WIP: streaming judge client"
$ git switch -q main
$ git merge wip/streaming
Updating c77b781..849fa3d
Fast-forward
 evalkit/streaming.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 evalkit/streaming.py
$ git log --oneline -2
849fa3d WIP: streaming judge client
c77b781 Merge branch 'feature/judge-prompt'
```
<!-- /snippet -->

`main` now ends in a work-in-progress commit, and the history shows no merge. It looks as if the commit had been made on `main` directly.

### Recovery

Nothing was pushed, so the lowest-risk fix is to move `main` back. `ORIG_HEAD` and the reflog both recorded the previous tip:

```bash
git reflog -2
git rev-parse --short ORIG_HEAD
git reset --merge ORIG_HEAD
git log --oneline -1
```

<!-- snippet: ch08/lab-06-1-ff-or-three-way/06-recovery -->
```text
$ git reflog -2
849fa3d HEAD@{0}: merge wip/streaming: Fast-forward
c77b781 HEAD@{1}: checkout: moving from wip/streaming to main
$ git rev-parse --short ORIG_HEAD
c77b781
$ git reset --merge ORIG_HEAD
$ git log --oneline -1
c77b781 Merge branch 'feature/judge-prompt'
```
<!-- /snippet -->

`git reset --merge` 🔴 moves the branch and removes the files that the fast-forward brought. It keeps unstaged edits and discards staged ones, so look at `git status` first. Read `ORIG_HEAD` before you use it: every later `git merge` call overwrites it, and then the reflog is the place to find the commit. If the fast-forward had already been pushed, you would not move the branch: you would revert the commit instead (Chapter 11).

### Verification

```bash
git status --short --branch
git branch --contains wip/streaming
git merge-base --is-ancestor wip/streaming main; echo $?
git ls-files evalkit
```

<!-- snippet: ch08/lab-06-1-ff-or-three-way/07-verification -->
```text
$ git status --short --branch
## main
$ git branch --contains wip/streaming
  wip/streaming
$ git merge-base --is-ancestor wip/streaming main
[exit status: 1]
$ git ls-files evalkit
evalkit/metrics.py
```
<!-- /snippet -->

The work-in-progress commit is reachable only from its own branch, and `evalkit/streaming.py` is no longer tracked on `main`.

### Questions

1. State the rule that predicts the three outcomes from the two `--is-ancestor` tests. What does it mean when both tests succeed?
2. How many objects did `git merge feature/batch-size` add to the repository? Name a command that proves it.
3. `git merge --ff-only feature/judge-prompt` failed. What exactly did it change in the working tree, the index and `.git`?
4. In the failure scenario, why was there no merge commit to revert? Which two records let you undo the fast-forward, and which of them is overwritten first?
5. Which option or setting would have turned the accidental integration of `wip/streaming` into a visible merge commit? Would `--ff-only` have prevented the accident?

## Lab 6.2: An edit-against-edit conflict, resolved by reading the stages

### Objective

Resolve a content conflict by reading what each side did to the common ancestor, not by guessing from the marker block. Catch a file that was staged with its markers.

### Prerequisites

Chapter 8, sections 8.7, 8.8 and 8.10.

### Setup

```bash
bash labs/ch08/setup-06-2-edit-edit-conflict.sh
labs/shell m06-2
cd evalkit
```

On `main` you made `exact_match` ignore surrounding whitespace and tightened the judge prompt. Asha's `feature/case-insensitive` makes `exact_match` ignore case and adds a test. Ravi's `feature/judge-wording` is used in the failure scenario.

### Commands

```bash
git log --oneline --graph --all
git merge feature/case-insensitive
git status --short
git ls-files -u
head -9 evalkit/metrics.py
```

Before you touch the file, read both intents:

```bash
git diff -U0 :1:evalkit/metrics.py :2:evalkit/metrics.py
git diff -U0 :1:evalkit/metrics.py :3:evalkit/metrics.py
git log --oneline --left-right --merge
```

Now edit `evalkit/metrics.py`. Replace the five lines from `<<<<<<< HEAD` to `>>>>>>> feature/case-insensitive` by one line that does both:

```text
    return float(pred.strip().lower() == gold.strip().lower())
```

```bash
head -2 evalkit/metrics.py
git diff
git add evalkit/metrics.py
git ls-files -s evalkit/metrics.py
git diff --cached --check; echo $?
git merge --continue
```

### Expected output

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/01-merge -->
```text
$ git log --oneline --graph --all
* cb32493 Demand a one-word verdict
* c0d110b Ignore surrounding whitespace when comparing
| * 9d90135 Let the judge answer UNSURE
|/  
| * f941818 Test that exact_match ignores case
| * 9743d83 Compare answers case-insensitively
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge feature/case-insensitive
Auto-merging evalkit/metrics.py
CONFLICT (content): Merge conflict in evalkit/metrics.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU evalkit/metrics.py
A  tests/test_metrics.py
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/02-stages -->
```text
$ git ls-files -u
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 1	evalkit/metrics.py
100644 493c4651aca2c275c46a25b1f8367e6bef1bf55d 2	evalkit/metrics.py
100644 ef41cb474aaad97a576de322e4236281b55585a3 3	evalkit/metrics.py
$ head -9 evalkit/metrics.py
def exact_match(pred, gold):
<<<<<<< HEAD
    return float(pred.strip() == gold.strip())
=======
    return float(pred.lower() == gold.lower())
>>>>>>> feature/case-insensitive


def accuracy(scores):
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/03-intent -->
```text
# stage 1 to stage 2: what OUR side did to the common ancestor
$ git diff -U0 :1:evalkit/metrics.py :2:evalkit/metrics.py
diff --git a/evalkit/metrics.py b/evalkit/metrics.py
index 9bbcd7a..493c465 100644
--- a/evalkit/metrics.py
+++ b/evalkit/metrics.py
@@ -2 +2 @@ def exact_match(pred, gold):
-    return float(pred == gold)
+    return float(pred.strip() == gold.strip())
# stage 1 to stage 3: what THEIR side did to it
$ git diff -U0 :1:evalkit/metrics.py :3:evalkit/metrics.py
diff --git a/evalkit/metrics.py b/evalkit/metrics.py
index 9bbcd7a..ef41cb4 100644
--- a/evalkit/metrics.py
+++ b/evalkit/metrics.py
@@ -2 +2 @@ def exact_match(pred, gold):
-    return float(pred == gold)
+    return float(pred.lower() == gold.lower())
$ git log --oneline --left-right --merge
< c0d110b Ignore surrounding whitespace when comparing
> 9743d83 Compare answers case-insensitively
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/04-resolve -->
```text
# In your editor: replace the whole conflict block by one line that does both.
$ head -2 evalkit/metrics.py
def exact_match(pred, gold):
    return float(pred.strip().lower() == gold.strip().lower())
$ git diff
diff --cc evalkit/metrics.py
index 493c465,ef41cb4..0000000
--- a/evalkit/metrics.py
+++ b/evalkit/metrics.py
@@@ -1,5 -1,5 +1,5 @@@
  def exact_match(pred, gold):
-     return float(pred.strip() == gold.strip())
 -    return float(pred.lower() == gold.lower())
++    return float(pred.strip().lower() == gold.strip().lower())
  
  
  def accuracy(scores):
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/05-conclude -->
```text
$ git add evalkit/metrics.py
$ git ls-files -s evalkit/metrics.py
100644 e82e9adbafb1fb88643f76b875b427e90b2f1850 0	evalkit/metrics.py
$ git diff --cached --check
[exit status: 0]
$ git merge --continue
[main 503ffdb] Merge branch 'feature/case-insensitive'
```
<!-- /snippet -->

### What happened internally

The merge base is `6ae3c51`. Both sides changed line 2 of `evalkit/metrics.py`, so the file-level merge had one region changed by both and stopped. The index received the three versions of the file as stages 1 (base, `9bbcd7a`), 2 (ours, `493c465`) and 3 (theirs, `ef41cb4`). `tests/test_metrics.py` exists only on Asha's side, so it was added and staged without a question.

The two stage diffs show that each side added one normalization to the same expression. Neither side removed anything, so the correct result applies both. In the combined `git diff`, the line with a `-` in the first column is ours, the line with a `-` in the second column is theirs, and the `++` line is new text that neither parent has. `git add` then replaced the three stages by one stage 0 entry holding a blob that existed nowhere before, `e82e9ad`.

### Checkpoint

```bash
git log --oneline --graph -5
git show --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/06-checkpoint -->
```text
$ git log --oneline --graph -5
*   503ffdb Merge branch 'feature/case-insensitive'
|\  
| * f941818 Test that exact_match ignores case
| * 9743d83 Compare answers case-insensitively
* | cb32493 Demand a one-word verdict
* | c0d110b Ignore surrounding whitespace when comparing
|/  
$ git show --format="%h %s" HEAD
503ffdb Merge branch 'feature/case-insensitive'

diff --cc evalkit/metrics.py
index 493c465,ef41cb4..e82e9ad
--- a/evalkit/metrics.py
+++ b/evalkit/metrics.py
@@@ -1,5 -1,5 +1,5 @@@
  def exact_match(pred, gold):
-     return float(pred.strip() == gold.strip())
 -    return float(pred.lower() == gold.lower())
++    return float(pred.strip().lower() == gold.strip().lower())
  
  
  def accuracy(scores):
```
<!-- /snippet -->

The merge commit must show the `++` line. If `git show` prints no diff, your resolution is identical to one of the two sides.

### Failure scenario

Merge Ravi's branch, and "resolve" the conflict with the reflex that `git add` marks a file as resolved:

```bash
git merge feature/judge-wording
cat prompts/judge.txt
git add prompts/judge.txt
git status --short
git diff --cached --check; echo $?
```

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/07-failure -->
```text
$ git merge feature/judge-wording
Auto-merging prompts/judge.txt
CONFLICT (content): Merge conflict in prompts/judge.txt
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat prompts/judge.txt
You are a strict grader.
<<<<<<< HEAD
Answer with exactly one word: PASS or FAIL.
=======
Answer with PASS, FAIL or UNSURE.
>>>>>>> feature/judge-wording
# Reflex: "git add marks it as resolved". Nothing was edited.
$ git add prompts/judge.txt
$ git status --short
M  prompts/judge.txt
$ git diff --cached --check
prompts/judge.txt:2: leftover conflict marker
prompts/judge.txt:4: leftover conflict marker
prompts/judge.txt:6: leftover conflict marker
[exit status: 2]
```
<!-- /snippet -->

`git status` shows a staged modification and no conflict. The markers are in the index. `git merge --continue` would commit them, and the judge model would receive `<<<<<<< HEAD` as part of its prompt.

### Recovery

```bash
git restore --merge prompts/judge.txt
git status --short
```

Edit `prompts/judge.txt` so that its second line keeps both intents and no marker line remains:

```text
Answer with exactly one word: PASS, FAIL or UNSURE.
```

```bash
cat prompts/judge.txt
git add prompts/judge.txt
git diff --cached --check; echo $?
git merge --continue
```

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/08-recovery -->
```text
$ git restore --merge prompts/judge.txt
$ git status --short
UU prompts/judge.txt
# In your editor: one line that keeps both intents, and no marker lines.
$ cat prompts/judge.txt
You are a strict grader.
Answer with exactly one word: PASS, FAIL or UNSURE.
$ git add prompts/judge.txt
$ git diff --cached --check
[exit status: 0]
$ git merge --continue
[main 10d2971] Merge branch 'feature/judge-wording'
```
<!-- /snippet -->

`git restore --merge` put the path back into the unmerged state. The index had kept the three stages when `git add` replaced them.

### Verification

```bash
git grep -n -E '^(<<<<<<<|=======|>>>>>>>)'; echo $?
git log --oneline --graph -4
git status --short --branch
```

<!-- snippet: ch08/lab-06-2-edit-edit-conflict/09-verification -->
```text
$ git grep -n -E '^(<<<<<<<|=======|>>>>>>>)'
[exit status: 1]
$ git log --oneline --graph -4
*   10d2971 Merge branch 'feature/judge-wording'
|\  
| * 9d90135 Let the judge answer UNSURE
* |   503ffdb Merge branch 'feature/case-insensitive'
|\ \  
| * | f941818 Test that exact_match ignores case
$ git status --short --branch
## main
```
<!-- /snippet -->

`git grep` exits with status 1, which means no tracked file contains a marker line.

### Questions

1. Match each blob ID of `git ls-files -u` to a commit: in which commit's tree does each of the three blobs appear?
2. Why was `tests/test_metrics.py` already staged when the merge stopped?
3. `git show` on the merge commit prints the resolution with `++`. What would it print if you had kept our line unchanged, and why?
4. In the failure scenario, which command revealed the problem, and what would `git merge --continue` have done without it?
5. Does the merged `exact_match` satisfy the test that Asha added? Explain why Git could not have told you.

## Lab 6.3: Rename against edit

### Objective

See a rename on one branch and an edit on the other merge without conflict, then diagnose the case where the same move is reported as a deletion.

### Prerequisites

Chapter 8, section 8.11. Chapter 4, section 4.9, on why Git does not record renames.

### Setup

```bash
bash labs/ch08/setup-06-3-rename-edit.sh
labs/shell m06-3
cd evalkit
```

On `main` you edited `evalkit/metrics.py`. Ravi has two refactoring branches. `refactor/scoring-module` only renames the file to `evalkit/scoring.py`. `refactor/score-objects` makes the same move and rewrites most of the file.

### Commands

Predict first: will the edit that you made to `metrics.py` survive a merge with a branch on which that file no longer exists?

```bash
git log --oneline --graph --all
git diff --name-status main...refactor/scoring-module
git diff --name-status refactor/scoring-module...main
git merge refactor/scoring-module
git ls-files evalkit
head -2 evalkit/scoring.py
```

### Expected output

<!-- snippet: ch08/lab-06-3-rename-edit/01-before -->
```text
$ git log --oneline --graph --all
* 1c21386 Ignore surrounding whitespace when comparing
| * 1d22db5 Move metrics to scoring and return Score objects
|/  
| * b82626f Rename the metrics module to scoring
|/  
* 0c0a1e6 Add token F1
* 6ae3c51 Add eval config, judge prompt and metrics
$ git diff --name-status main...refactor/scoring-module
R100	evalkit/metrics.py	evalkit/scoring.py
$ git diff --name-status refactor/scoring-module...main
M	evalkit/metrics.py
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-3-rename-edit/02-merge -->
```text
$ git merge refactor/scoring-module
Merge made by the 'ort' strategy.
 evalkit/{metrics.py => scoring.py} | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename evalkit/{metrics.py => scoring.py} (100%)
$ git ls-files evalkit
evalkit/scoring.py
$ head -2 evalkit/scoring.py
def exact_match(pred, gold):
    return float(pred.strip() == gold.strip())
```
<!-- /snippet -->

### What happened internally

`R100` means that Git paired the deleted path with the added path because their content is 100% identical. That pairing is computed during the merge from the three snapshots. With the rename detected, the three-way merge for this file had the base content, your edited content under the old name, and Ravi's unchanged content under the new name: only your side changed the content and only his side changed the name, so the result is your content under his name.

Nothing about the rename is stored:

```bash
git ls-tree -r --abbrev=7 HEAD evalkit
git log --oneline -- evalkit/scoring.py
git log --oneline --follow -- evalkit/scoring.py
```

<!-- snippet: ch08/lab-06-3-rename-edit/03-internals -->
```text
# The merge commit records a tree, not a rename:
$ git ls-tree -r --abbrev=7 HEAD evalkit
100644 blob 70452b7	evalkit/scoring.py
$ git log --oneline -- evalkit/scoring.py
1323729 Merge branch 'refactor/scoring-module'
b82626f Rename the metrics module to scoring
$ git log --oneline --follow -- evalkit/scoring.py
b82626f Rename the metrics module to scoring
0c0a1e6 Add token F1
6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

The tree of the merge commit holds one entry, `evalkit/scoring.py`. Look closely at the two logs. Neither lists your commit "Ignore surrounding whitespace when comparing", although its change is in the file. The first log stops at the rename because the path did not exist before it. The second follows the rename, but as run here on Git 2.55 it lists only the side of the merge on which the rename happened. Your edit was made on the other side, under the old name. `git log --oneline -- evalkit/metrics.py evalkit/scoring.py` lists all five commits. The Git 2.56 release notes announce better handling of non-linear history in `git log --follow` (not run here).

### Checkpoint

`git ls-files evalkit` prints only `evalkit/scoring.py`, and its second line contains `pred.strip() == gold.strip()`. If `evalkit/metrics.py` still exists, you are not on the merge commit.

### Failure scenario

Repeat the merge with the branch that moved the file and rewrote it. Start from the commit that `main` pointed to before the first merge:

```bash
git switch -c try/score-objects main^1
git merge refactor/score-objects
git status --short
```

<!-- snippet: ch08/lab-06-3-rename-edit/04-failure -->
```text
$ git switch -q -c try/score-objects main^1
$ git merge refactor/score-objects
CONFLICT (modify/delete): evalkit/metrics.py deleted in refactor/score-objects and modified in HEAD.  Version HEAD of evalkit/metrics.py left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UD evalkit/metrics.py
A  evalkit/scoring.py
```
<!-- /snippet -->

Git reports that the file was deleted. Nobody decided to delete the module. And `evalkit/scoring.py` is staged as a new file that does not contain your edit.

### Recovery

Diagnose before you choose a resolution. Ask Git how similar the two files are:

```bash
git diff --summary try/score-objects...refactor/score-objects
git diff --summary --find-renames=30% try/score-objects...refactor/score-objects
```

<!-- snippet: ch08/lab-06-3-rename-edit/05-diagnosis -->
```text
$ git diff --summary try/score-objects...refactor/score-objects
 delete mode 100644 evalkit/metrics.py
 create mode 100644 evalkit/scoring.py
$ git diff --summary --find-renames=30% try/score-objects...refactor/score-objects
 rename evalkit/{metrics.py => scoring.py} (39%)
```
<!-- /snippet -->

The content is 39% similar, below the default threshold of 50%. Abort and merge again with a threshold that recognizes the move:

```bash
git merge --abort
git merge -X find-renames=30% refactor/score-objects
git status --short
grep -n -A4 '<<<<<<<' evalkit/scoring.py
```

<!-- snippet: ch08/lab-06-3-rename-edit/06-recovery -->
```text
$ git merge --abort
$ git merge -X find-renames=30% refactor/score-objects
Auto-merging evalkit/scoring.py
CONFLICT (content): Merge conflict in evalkit/scoring.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
D  evalkit/metrics.py
UU evalkit/scoring.py
$ grep -n -A4 '<<<<<<<' evalkit/scoring.py
12:<<<<<<< HEAD:evalkit/metrics.py
13-    return float(pred.strip() == gold.strip())
14-=======
15-    return Score("exact_match", float(pred == gold))
16->>>>>>> refactor/score-objects:evalkit/scoring.py
```
<!-- /snippet -->

Now the conflict is where it belongs: one line in the new file, with your version labelled `HEAD:evalkit/metrics.py`. Edit `evalkit/scoring.py` and replace the conflict block by a line that returns a `Score` and strips whitespace:

```text
    return Score("exact_match", float(pred.strip() == gold.strip()))
```

```bash
sed -n '11,12p' evalkit/scoring.py
git add evalkit/scoring.py
git merge --continue
```

<!-- snippet: ch08/lab-06-3-rename-edit/07-resolve -->
```text
# In your editor: one line that returns a Score AND strips whitespace.
$ sed -n '11,12p' evalkit/scoring.py
def exact_match(pred, gold):
    return Score("exact_match", float(pred.strip() == gold.strip()))
$ git add evalkit/scoring.py
$ git merge --continue
[try/score-objects 4590972] Merge branch 'refactor/score-objects' into try/score-objects
```
<!-- /snippet -->

### Verification

```bash
git ls-files evalkit
git grep -n "strip()" -- evalkit
git log --oneline --graph -3
git switch main
```

<!-- snippet: ch08/lab-06-3-rename-edit/08-verification -->
```text
$ git ls-files evalkit
evalkit/scoring.py
$ git grep -n "strip()" -- evalkit
evalkit/scoring.py:12:    return Score("exact_match", float(pred.strip() == gold.strip()))
$ git log --oneline --graph -3
*   4590972 Merge branch 'refactor/score-objects' into try/score-objects
|\  
| * 1d22db5 Move metrics to scoring and return Score objects
* | 1c21386 Ignore surrounding whitespace when comparing
|/  
$ git switch -q main
```
<!-- /snippet -->

One module, under the new name, containing both the `Score` objects and your whitespace fix. The merge message ends with "into try/score-objects" because you were not on `main`. Git leaves the destination out only for branches matched by `merge.suppressDest`: the manual names `master` as the default, and the transcripts of this module show the same for `main`.

### Questions

1. Where in the merge commit is the rename recorded?
2. The pure rename merged cleanly and the rewrite produced `CONFLICT (modify/delete)`. Which number decided between the two outcomes, and where does its default come from?
3. With `-X find-renames=30%` the conflict labels contain paths. Why?
4. What would have been lost if you had resolved the modify/delete conflict with `git rm evalkit/metrics.py` and continued?
5. Why does `git log --follow -- evalkit/scoring.py` not list your commit on Git 2.55, and which command lists it?

## Lab 6.4: Modify against delete

### Objective

Resolve a conflict in which one side edited a file and the other deleted it, by finding out why the file was deleted and where the edit belongs now.

### Prerequisites

Chapter 8, sections 8.10 and 8.11.

### Setup

```bash
bash labs/ch08/setup-06-4-modify-delete.sh
labs/shell m06-4
cd evalkit
```

On `main` you added `--seed 7` to `scripts/legacy_eval.sh`. Ravi's `cleanup/remove-legacy` deletes that script and adds a `Makefile` target in its place.

### Commands

```bash
git log --oneline --graph --all
git merge cleanup/remove-legacy
git status --short
git ls-files -u
git show :3:scripts/legacy_eval.sh
git diff -U0 :1:scripts/legacy_eval.sh :2:scripts/legacy_eval.sh
```

The `git show :3:...` command fails on purpose: see for yourself that there is no "their version". Then find out why their side deleted the file:

```bash
git log --oneline --left-right --merge
git show --stat --format="%h %an: %s" cleanup/remove-legacy
cat Makefile
```

Decide: the script stays deleted, and your `--seed 7` moves to the make target. Edit `Makefile` so that its second line ends with `--seed 7`, then:

```bash
git rm scripts/legacy_eval.sh
cat Makefile
git add Makefile
git status --short
git merge --continue
```

When the editor opens, add two lines to the message that record the decision.

### Expected output

<!-- snippet: ch08/lab-06-4-modify-delete/01-merge -->
```text
$ git log --oneline --graph --all
* 26a999d Run legacy evals with a fixed seed
| * a0c92e6 Replace the legacy eval script by a make target
|/  
* 865fafa Add the legacy eval script
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge cleanup/remove-legacy
CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in cleanup/remove-legacy and modified in HEAD.  Version HEAD of scripts/legacy_eval.sh left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
A  Makefile
UD scripts/legacy_eval.sh
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-4-modify-delete/02-stages -->
```text
$ git ls-files -u
100644 4a41a25aa3c40cf94e023b2f4e69974e8d1b0e5f 1	scripts/legacy_eval.sh
100644 901cabd2b3b6ddb79a99a86cc70b4f69a0c1d86b 2	scripts/legacy_eval.sh
$ git show :3:scripts/legacy_eval.sh
fatal: path 'scripts/legacy_eval.sh' is in the index, but not at stage 3
hint: Did you mean ':1:scripts/legacy_eval.sh'?
[exit status: 128]
# What our side changed in the file that their side deleted:
$ git diff -U0 :1:scripts/legacy_eval.sh :2:scripts/legacy_eval.sh
diff --git a/scripts/legacy_eval.sh b/scripts/legacy_eval.sh
index 4a41a25..901cabd 100644
--- a/scripts/legacy_eval.sh
+++ b/scripts/legacy_eval.sh
@@ -2 +2 @@
-python -m evalkit --config config/eval.yaml
+python -m evalkit --config config/eval.yaml --seed 7
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-4-modify-delete/03-why-deleted -->
```text
$ git log --oneline --left-right --merge
< 26a999d Run legacy evals with a fixed seed
> a0c92e6 Replace the legacy eval script by a make target
$ git show --stat --format="%h %an: %s" cleanup/remove-legacy
a0c92e6 Ravi Menon: Replace the legacy eval script by a make target

 Makefile               | 2 ++
 scripts/legacy_eval.sh | 2 --
 2 files changed, 2 insertions(+), 2 deletions(-)
$ cat Makefile
eval:
	python -m evalkit run --config config/eval.yaml
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-4-modify-delete/04-resolve -->
```text
# Decision: the script stays deleted, and our --seed 7 moves to the make target.
$ git rm scripts/legacy_eval.sh
rm 'scripts/legacy_eval.sh'
$ cat Makefile
eval:
	python -m evalkit run --config config/eval.yaml --seed 7
$ git add Makefile
$ git status --short
A  Makefile
D  scripts/legacy_eval.sh
$ git merge --continue
[main b5776ec] Merge branch 'cleanup/remove-legacy'
```
<!-- /snippet -->

### What happened internally

The rule table of section 8.4 has no automatic answer for "base X, ours Y, theirs absent". Git left your version in the working tree, recorded stage 1 (base) and stage 2 (ours), and recorded no stage 3 because their version is no file. `UD` reads "unmerged, deleted by them". The `Makefile` exists only on their side, so it was added and staged.

`git rm` resolved the path by removing every stage: the deletion stands. The edit to `Makefile` is new content that neither branch contains. That makes this merge, strictly, an evil merge in the sense of section 8.15. It is the right resolution, and the merge message says what was done.

### Checkpoint

```bash
git ls-files
git show --remerge-diff --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-4-modify-delete/05-checkpoint -->
```text
$ git ls-files
Makefile
config/eval.yaml
evalkit/metrics.py
prompts/judge.txt
$ git show --remerge-diff --format="%h %s" HEAD
b5776ec Merge branch 'cleanup/remove-legacy'

diff --git a/Makefile b/Makefile
index 4140e3b..ff98960 100644
--- a/Makefile
+++ b/Makefile
@@ -1,2 +1,2 @@
 eval:
-	python -m evalkit run --config config/eval.yaml
+	python -m evalkit run --config config/eval.yaml --seed 7
diff --git a/scripts/legacy_eval.sh b/scripts/legacy_eval.sh
deleted file mode 100644
remerge CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in a0c92e6 (Replace the legacy eval script by a make target) and modified in 26a999d (Run legacy evals with a fixed seed).  Version 26a999d (Run legacy evals with a fixed seed) of scripts/legacy_eval.sh left in tree.
index 901cabd..0000000
--- a/scripts/legacy_eval.sh
+++ /dev/null
@@ -1,2 +0,0 @@
-#!/bin/sh
-python -m evalkit --config config/eval.yaml --seed 7
```
<!-- /snippet -->

The remerge diff shows both decisions: the `--seed 7` that you carried into `Makefile`, and the modify/delete conflict that you resolved by deletion.

### Failure scenario

The reflex resolution. Start again from the commit before the merge and "resolve" with `git add`:

```bash
git switch -c try/blind-add main^1
git merge cleanup/remove-legacy
git add scripts/legacy_eval.sh
git merge --continue
git ls-files Makefile scripts
grep -n evalkit Makefile scripts/legacy_eval.sh
```

<!-- snippet: ch08/lab-06-4-modify-delete/06-failure -->
```text
$ git switch -q -c try/blind-add main^1
$ git merge cleanup/remove-legacy
CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in cleanup/remove-legacy and modified in HEAD.  Version HEAD of scripts/legacy_eval.sh left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git add scripts/legacy_eval.sh
$ git merge --continue
[try/blind-add 7babc85] Merge branch 'cleanup/remove-legacy' into try/blind-add
$ git ls-files Makefile scripts
Makefile
scripts/legacy_eval.sh
$ grep -n evalkit Makefile scripts/legacy_eval.sh
Makefile:2:	python -m evalkit run --config config/eval.yaml
scripts/legacy_eval.sh:2:python -m evalkit --config config/eval.yaml --seed 7
```
<!-- /snippet -->

The merge succeeded and the repository is wrong. It has two ways to run an evaluation: the make target without a seed, and the legacy script that the cleanup meant to remove.

### Recovery

Treat the bad merge as already shared. The repair is a new commit: remove the script and edit `Makefile` so that the target ends with `--seed 7`.

```bash
git rm -q scripts/legacy_eval.sh
git diff --stat
git commit -a -m "Remove the legacy script again and carry --seed 7 to the make target"
```

<!-- snippet: ch08/lab-06-4-modify-delete/07-recovery -->
```text
# This merge is treated as already shared, so the repair is a new commit.
$ git rm -q scripts/legacy_eval.sh
$ git diff --stat
 Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git commit -q -a -m "Remove the legacy script again and carry --seed 7 to the make target"
```
<!-- /snippet -->

### Verification

```bash
git rev-parse main^{tree} try/blind-add^{tree}
git diff --stat main try/blind-add
git log --oneline --graph -3 try/blind-add
git switch main
```

<!-- snippet: ch08/lab-06-4-modify-delete/08-verification -->
```text
# Two different histories, one identical tree:
$ git rev-parse main^{tree} try/blind-add^{tree}
6e3df23602cceb38bafc875299047b3874e9d200
6e3df23602cceb38bafc875299047b3874e9d200
$ git diff --stat main try/blind-add
$ git log --oneline --graph -3 try/blind-add
* ff2c988 Remove the legacy script again and carry --seed 7 to the make target
*   7babc85 Merge branch 'cleanup/remove-legacy' into try/blind-add
|\  
| * a0c92e6 Replace the legacy eval script by a make target
$ git switch -q main
```
<!-- /snippet -->

Two histories, one tree. The content is repaired. The history of `try/blind-add` keeps the wrong merge and its correction.

### Questions

1. Which stages exist for a path that is "deleted by them", and why is there no stage 3?
2. `git add <path>` and `git rm <path>` both end the conflict. What does each one record in the index?
3. The correct resolution changed `Makefile`, a file without a conflict. How does that change appear in `git show --remerge-diff`, and how would it appear in `git log -p`?
4. In the failure scenario the merge completed without error. Which evidence shows that it was wrong?
5. `main` and `try/blind-add` end with the same tree. Give one reason to prefer each history.

## Lab 6.5: A clean merge that breaks the build

### Objective

Reproduce a merge that has no conflict and a failing check, prove that both parents pass, and repair it in a way that reviewers can see.

### Prerequisites

Chapter 8, sections 8.4, 8.15 and 8.16.

### Setup

```bash
bash labs/ch08/setup-06-5-clean-merge-broken-build.sh
labs/shell m06-5
cd evalkit
```

`ci/check_migrations.sh` stands in for a migration tool: it fails when two files in `migrations/` share a number. Asha's `feature/prompt-versions` and Ravi's `feature/latency` each add one migration.

### Commands

Run the check on each branch, then merge both into `main` and run it again:

```bash
git log --oneline --graph --all
git switch --detach feature/prompt-versions && sh ci/check_migrations.sh
git switch --detach feature/latency && sh ci/check_migrations.sh
git switch main
git merge feature/prompt-versions
git merge feature/latency
sh ci/check_migrations.sh; echo $?
git ls-files migrations
```

### Expected output

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/01-green-branches -->
```text
$ git log --oneline --graph --all
* ea05ada Record judge latency per score
| * 77a3560 Record the prompt version of every run
|/  
* 5ab45cf Add migrations and the migration-number check
* 6ae3c51 Add eval config, judge prompt and metrics
$ git switch -q --detach feature/prompt-versions && sh ci/check_migrations.sh
OK 3 migrations, every number is unique
$ git switch -q --detach feature/latency && sh ci/check_migrations.sh
OK 3 migrations, every number is unique
$ git switch -q main
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/02-merges -->
```text
$ git merge feature/prompt-versions
Updating 5ab45cf..77a3560
Fast-forward
 migrations/0003_add_prompt_version.sql | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 migrations/0003_add_prompt_version.sql
$ git merge feature/latency
Merge made by the 'ort' strategy.
 migrations/0003_add_latency_ms.sql | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 migrations/0003_add_latency_ms.sql
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/03-red -->
```text
$ sh ci/check_migrations.sh
FAIL migration number 0003 is used by: 0003_add_latency_ms.sql 0003_add_prompt_version.sql
[exit status: 1]
$ git ls-files migrations
migrations/0001_create_runs.sql
migrations/0002_create_scores.sql
migrations/0003_add_latency_ms.sql
migrations/0003_add_prompt_version.sql
```
<!-- /snippet -->

### What happened internally

```bash
git diff --name-status main^1 main
git diff --name-status main^2 main
git show --remerge-diff --format="%h %s" main
```

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/04-diagnosis -->
```text
# What each parent contributed to the merge result:
$ git diff --name-status main^1 main
A	migrations/0003_add_latency_ms.sql
$ git diff --name-status main^2 main
A	migrations/0003_add_prompt_version.sql
$ git show --remerge-diff --format="%h %s" main
4456707 Merge branch 'feature/latency'
```
<!-- /snippet -->

Each side added one path that neither the base nor the other side has. A path added on one side only is taken as it is. No file-level merge ran, so there was nothing that could conflict. The remerge diff is empty: the merge commit is exactly what Git computes on its own. The defect is not in the merge. It is in a rule that lives in the migration tool, "numbers are unique", and Git has no knowledge of that rule.

### Checkpoint

The check fails and names the two files that share the number 0003, and `git ls-files migrations` lists four files. On each parent (`git switch --detach main^1`, then `main^2`) the same check passes.

### Failure scenario

The tempting repair is to fold the fix into the merge commit, so that the red commit disappears:

```bash
git mv migrations/0003_add_latency_ms.sql migrations/0004_add_latency_ms.sql
git commit --amend --no-edit
sh ci/check_migrations.sh
git log -1 -p --format="%h %s"
git show --remerge-diff --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/05-failure -->
```text
$ git mv migrations/0003_add_latency_ms.sql migrations/0004_add_latency_ms.sql
$ git commit -q --amend --no-edit
$ sh ci/check_migrations.sh
OK 4 migrations, every number is unique
$ git log -1 -p --format="%h %s"
69e79ab Merge branch 'feature/latency'
$ git show --remerge-diff --format="%h %s" HEAD
69e79ab Merge branch 'feature/latency'

diff --git a/migrations/0003_add_latency_ms.sql b/migrations/0004_add_latency_ms.sql
similarity index 100%
rename from migrations/0003_add_latency_ms.sql
rename to migrations/0004_add_latency_ms.sql
```
<!-- /snippet -->

The check is green, and `git log -p` shows nothing for the commit. The renumbering is invisible to anyone who reviews history in the usual way. Only the remerge diff reveals it. You have made an evil merge.

### Recovery

The original merge commit is still in the reflog. Go back to it and make the repair a normal commit:

```bash
git reflog -2
git reset --keep HEAD@{1}
git log --oneline -1
git mv migrations/0003_add_latency_ms.sql migrations/0004_add_latency_ms.sql
git commit -m "Renumber the latency migration to 0004"
```

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/06-recovery -->
```text
$ git reflog -2
69e79ab HEAD@{0}: commit (amend): Merge branch 'feature/latency'
4456707 HEAD@{1}: merge feature/latency: Merge made by the 'ort' strategy.
$ git reset --keep HEAD@{1}
$ git log --oneline -1
4456707 Merge branch 'feature/latency'
$ git mv migrations/0003_add_latency_ms.sql migrations/0004_add_latency_ms.sql
$ git commit -q -m "Renumber the latency migration to 0004"
```
<!-- /snippet -->

`git reset --keep` 🟡 moves the branch and refuses if that would overwrite uncommitted changes. It is appropriate here because the amended commit was never pushed.

### Verification

```bash
sh ci/check_migrations.sh
git log --oneline --graph -4
git show --stat --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-5-clean-merge-broken-build/07-verification -->
```text
$ sh ci/check_migrations.sh
OK 4 migrations, every number is unique
$ git log --oneline --graph -4
* f135b98 Renumber the latency migration to 0004
*   4456707 Merge branch 'feature/latency'
|\  
| * ea05ada Record judge latency per score
* | 77a3560 Record the prompt version of every run
|/  
$ git show --stat --format="%h %s" HEAD
f135b98 Renumber the latency migration to 0004

 migrations/{0003_add_latency_ms.sql => 0004_add_latency_ms.sql} | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
```
<!-- /snippet -->

### Questions

1. Name the row of the rule table in section 8.4 that applied to each of the two new migration files.
2. `git show --remerge-diff main` printed nothing for the original merge. What does that tell you about where the defect is?
3. Compare the amended merge with the follow-up commit. What does a reviewer who runs `git log -p` see in each case? Which history keeps every commit on the first-parent line green?
4. The amended merge commit and the original have different IDs. Why, and where was the original still recorded?
5. Which process control would have caught this failure before `main` turned red?

## Lab 6.6: Audit merges with `--remerge-diff`

### Objective

Audit four merge commits made by three people and classify each one: untouched, honestly resolved, work lost, or change smuggled in. Then meet the blind spot of the tool and work around it.

### Prerequisites

Chapter 8, sections 8.13 to 8.17.

### Setup

```bash
bash labs/ch08/setup-06-6-audit-remerge-diff.sh
labs/shell m06-6
cd evalkit
```

`main` contains four merges. Nobody told you which of them had conflicts or what was done about them.

### Commands

```bash
git log --merges --format="%h %<(10)%an %s"
git log --merges -p --format="%h %s"
git log --merges --remerge-diff --format="== %h %an: %s"
```

Classify the four merges from that last output before you read on. Then investigate the one that changed `retries`:

```bash
git log --format='%h %an: %s' -S'retries: 3' --full-history -- config/eval.yaml
git diff -U0 60a4fbe^1 60a4fbe -- config/eval.yaml
git log --oneline -- config/eval.yaml
git log --oneline --full-history -- config/eval.yaml
```

### Expected output

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/01-merges -->
```text
$ git log --merges --format="%h %<(10)%an %s"
859b0e3 Ravi Menon Merge branch 'topic/max-tokens'
60a4fbe Asha Rao   Merge branch 'feature/creative-judge'
c3e4310 Lab User   Merge branch 'feature/case-insensitive'
67a4d6c Asha Rao   Merge branch 'topic/readme'
# git log -p prints no diff for any of them:
$ git log --merges -p --format="%h %s"
859b0e3 Merge branch 'topic/max-tokens'
60a4fbe Merge branch 'feature/creative-judge'
c3e4310 Merge branch 'feature/case-insensitive'
67a4d6c Merge branch 'topic/readme'
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/02-remerge-diff -->
```text
$ git log --merges --remerge-diff --format="== %h %an: %s"
== 859b0e3 Ravi Menon: Merge branch 'topic/max-tokens'

diff --git a/config/eval.yaml b/config/eval.yaml
index 99069a9..a4440eb 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2,6 +2,6 @@ model: judge-large-v2
 temperature: 0.7
 max_tokens: 1024
 batch_size: 16
-timeout_s: 30
+timeout_s: 300
 retries: 2
 seed: 7
== 60a4fbe Asha Rao: Merge branch 'feature/creative-judge'

diff --git a/config/eval.yaml b/config/eval.yaml
remerge CONFLICT (content): Merge conflict in config/eval.yaml
index ee4fced..3e21100 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -1,11 +1,7 @@
 model: judge-large-v2
-<<<<<<< 2d08f73 (Retry the judge three times)
-temperature: 0.0
-=======
 temperature: 0.7
->>>>>>> 8797299 (Raise temperature for judge diversity)
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
-retries: 3
+retries: 2
 seed: 7
== c3e4310 Lab User: Merge branch 'feature/case-insensitive'

diff --git a/evalkit/metrics.py b/evalkit/metrics.py
remerge CONFLICT (content): Merge conflict in evalkit/metrics.py
index 08825c7..e82e9ad 100644
--- a/evalkit/metrics.py
+++ b/evalkit/metrics.py
@@ -1,9 +1,5 @@
 def exact_match(pred, gold):
-<<<<<<< 9e511e8 (Ignore surrounding whitespace when comparing)
-    return float(pred.strip() == gold.strip())
-=======
-    return float(pred.lower() == gold.lower())
->>>>>>> c45f9f1 (Compare answers case-insensitively)
+    return float(pred.strip().lower() == gold.strip().lower())
 
 
 def accuracy(scores):
== 67a4d6c Asha Rao: Merge branch 'topic/readme'
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/03-lost-work -->
```text
# Who wrote the line that the creative-judge merge removed, and what did the merge do to it?
$ git log --format='%h %an: %s' -S'retries: 3' --full-history -- config/eval.yaml
2d08f73 Ravi Menon: Retry the judge three times
$ git diff -U0 60a4fbe^1 60a4fbe -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index 8fa379d..3e21100 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.0
+temperature: 0.7
@@ -6 +6 @@ timeout_s: 30
-retries: 3
+retries: 2
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/04-hidden-from-log -->
```text
# A path-limited log follows only the parent whose file the merge kept:
$ git log --oneline -- config/eval.yaml
859b0e3 Merge branch 'topic/max-tokens'
bd90dd6 Allow 1024 output tokens
8797299 Raise temperature for judge diversity
6ae3c51 Add eval config, judge prompt and metrics
$ git log --oneline --full-history -- config/eval.yaml
859b0e3 Merge branch 'topic/max-tokens'
bd90dd6 Allow 1024 output tokens
60a4fbe Merge branch 'feature/creative-judge'
2d08f73 Retry the judge three times
95c50b4 Use temperature 0 for reproducible evals
8797299 Raise temperature for judge diversity
6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

### What happened internally

For each merge Git repeated the merge of the two parents into a temporary tree and printed the difference between that tree and the recorded one.

| Merge | Remerge diff | Verdict |
|---|---|---|
| `67a4d6c` `topic/readme` | empty | exactly what Git computes: nothing to audit |
| `c3e4310` `feature/case-insensitive` | conflict block removed, one new line added | an honest resolution that combines both sides |
| `60a4fbe` `feature/creative-judge` | conflict block resolved to 0.7, and `retries: 3` became `retries: 2` far from any marker | work lost: the whole file was taken from their side |
| `859b0e3` `topic/max-tokens` | no conflict, and `timeout_s` changed from 30 to 300 | a change that belongs to neither branch |

The third merge is the incident of section 8.1. `git log -S'retries: 3'` finds the commit that introduced the line, by Ravi. The diff between the merge and its first parent shows the merge removing it. That is the signature of a whole-file `--theirs`, which throws away every change that `main` had made to that file, conflicting or not.

The last two commands show why nobody noticed. A log that is limited to a path simplifies history: when a merge leaves the file identical to one parent, the log follows only that parent. Here the merged file is identical to their side, so the default log hides the `main` side, which is exactly the side whose work was lost. `--full-history` shows it.

### Checkpoint

You can name, with commit IDs, who wrote `retries: 3` (`2d08f73`), which merge removed it (`60a4fbe`) and who made that merge. If your classification of the four merges differs from the table, read the remerge diff of that merge again.

### Failure scenario

Make a merge that the audit tool cannot check. Merge two documentation branches at once and slip in an unrelated change before committing:

```bash
git merge --no-commit docs/contributing docs/changelog
sed -e 's/^seed: .*/seed: 99/' config/eval.yaml > c && mv c config/eval.yaml
git add config/eval.yaml
git commit --no-edit
git show --remerge-diff --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/05-failure -->
```text
$ git merge --no-commit docs/contributing docs/changelog
Trying simple merge with docs/contributing
Trying simple merge with docs/changelog
Automatic merge went well; stopped before committing as requested
# Before committing, change something that neither branch touches:
$ sed -e 's/^seed: .*/seed: 99/' config/eval.yaml > c && mv c config/eval.yaml
$ git add config/eval.yaml
$ git commit -q --no-edit
$ git show --remerge-diff --format="%h %s" HEAD
edf9076 Merge branches 'docs/contributing' and 'docs/changelog'
diff: warning: Skipping remerge-diff for octopus merges.
```
<!-- /snippet -->

The remerge diff is skipped for a merge with more than two parents. The smuggled seed is invisible to the command that you would normally trust.

### Recovery

Two ways to audit the octopus merge. The combined diff works for any number of parents:

```bash
git show --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/06-recovery -->
```text
# The combined diff still works for any number of parents:
$ git show --format="%h %s" HEAD
edf9076 Merge branches 'docs/contributing' and 'docs/changelog'

diff --cc config/eval.yaml
index a4440eb,a4440eb,a4440eb..2b15cec
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@@@ -4,4 -4,4 -4,4 +4,4 @@@@ max_tokens: 102
   batch_size: 16
   timeout_s: 300
   retries: 2
---seed: 7
+++seed: 99
```
<!-- /snippet -->

Three `-` columns and three `+` columns: the line differs from all three parents, so it came from none of them. The second way repeats the merge mechanically, two heads at a time, with `git merge-tree`, and compares the result with the recorded tree:

```bash
step1=$(git merge-tree --write-tree HEAD^1 HEAD^2)
tmp=$(git commit-tree $step1 -p HEAD^1 -p HEAD^2 -m "temporary: first two heads")
step2=$(git merge-tree --write-tree $tmp HEAD^3)
git diff $step2 HEAD
```

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/07-recovery-plumbing -->
```text
# Or redo the merge mechanically, two heads at a time, and compare trees:
$ step1=$(git merge-tree --write-tree HEAD^1 HEAD^2)
$ tmp=$(git commit-tree $step1 -p HEAD^1 -p HEAD^2 -m "temporary: first two heads")
$ step2=$(git merge-tree --write-tree $tmp HEAD^3)
$ git diff $step2 HEAD
diff --git a/config/eval.yaml b/config/eval.yaml
index a4440eb..2b15cec 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -4,4 +4,4 @@ max_tokens: 1024
 batch_size: 16
 timeout_s: 300
 retries: 2
-seed: 7
+seed: 99
```
<!-- /snippet -->

### Verification

```bash
git log -1 --format="%h parents: %p"
git diff --stat $step2 HEAD
git status --short --branch
```

<!-- snippet: ch08/lab-06-6-audit-remerge-diff/08-verification -->
```text
$ git log -1 --format="%h parents: %p"
edf9076 parents: ea40063 da52f26 c29f2b7
$ git diff --stat $step2 HEAD
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short --branch
## main
```
<!-- /snippet -->

One line in one file separates the recorded merge from the mechanical one. The plumbing commands created objects and moved no ref, so the status is clean.

### Questions

1. For each of the four merges, say which evidence in the remerge diff supports the verdict in the table.
2. Asha's merge shows `-retries: 3` and `+retries: 2` with no marker next to them. What does that tell you about how the conflict was resolved?
3. Why did `git log --oneline -- config/eval.yaml` not list Ravi's commit "Retry the judge three times", and which option brought it back?
4. Why does `--remerge-diff` skip the octopus merge, and what do the two alternatives rely on?
5. What would you change in the team's process so that a change like `timeout_s: 300` is seen in review?

## Lab 6.7: Abort and retry with `zdiff3`

### Objective

Recognize a conflict that the default style cannot explain, abort the merge cleanly, retry with the base visible, and resolve it correctly. Then lose an uncommitted edit through an abort and get it back.

### Prerequisites

Chapter 8, sections 8.9, 8.10 and 8.19.

### Setup

```bash
bash labs/ch08/setup-06-7-abort-retry-zdiff3.sh
labs/shell m06-7
cd evalkit
```

`evalkit/judge.py` turns the judge model's answer into a score. On `main` you changed it to return `None` for an answer it cannot parse. Asha's `feature/unsure-verdict` teaches it a third verdict. Ravi's `feature/short-errors` is used in the failure scenario.

### Commands

```bash
git log --oneline --graph --all
git merge feature/unsure-verdict
git status --short
cat evalkit/judge.py
```

Stop and answer from the marker block alone: which side wrote the `raise` line? If you cannot tell, do not guess. Go back to the starting state and verify that you are there:

```bash
git merge --abort
git status --short --branch
ls .git | grep -E 'MERGE|ORIG_HEAD'
git rev-parse HEAD ORIG_HEAD
git reflog -1
```

Turn on the style that shows the base, and merge again:

```bash
git config set merge.conflictStyle zdiff3
git config get --show-origin merge.conflictStyle
git merge feature/unsure-verdict
cat evalkit/judge.py
git ls-files -u
git diff -U0 :1:evalkit/judge.py :2:evalkit/judge.py
git diff -U0 :1:evalkit/judge.py :3:evalkit/judge.py
```

Edit `evalkit/judge.py`. Replace the whole block from `<<<<<<< HEAD` to `>>>>>>> feature/unsure-verdict` by their new branch followed by your return value:

```text
    if text.startswith("UNSURE"):
        return 0.5
    return None
```

```bash
cat evalkit/judge.py
git add evalkit/judge.py
git diff --cached --check; echo $?
git merge --continue
```

### Expected output

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/01-merge -->
```text
$ git log --oneline --graph --all
* 3463938 Return None for unparseable verdicts instead of raising
| * c2a34d6 Truncate long verdicts in the error message
|/  
| * 3e28b8d Let the judge answer UNSURE
| * 32be383 Score UNSURE verdicts as 0.5
|/  
* 630e488 Add the verdict parser
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge feature/unsure-verdict
Auto-merging evalkit/judge.py
CONFLICT (content): Merge conflict in evalkit/judge.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU evalkit/judge.py
M  prompts/judge.txt
$ cat evalkit/judge.py
def parse_verdict(text):
    text = text.strip().upper()
    if text.startswith("PASS"):
        return 1.0
    if text.startswith("FAIL"):
        return 0.0
<<<<<<< HEAD
    return None
=======
    if text.startswith("UNSURE"):
        return 0.5
    raise ValueError(f"unparseable verdict: {text!r}")
>>>>>>> feature/unsure-verdict
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/02-abort -->
```text
$ git merge --abort
$ git status --short --branch
## main
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
$ git rev-parse HEAD ORIG_HEAD
3463938531636116b9b39136837bfa9a96534d50
3463938531636116b9b39136837bfa9a96534d50
$ git reflog -1
3463938 HEAD@{0}: reset: moving to HEAD
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/03-retry -->
```text
$ git config set merge.conflictStyle zdiff3
$ git config get --show-origin merge.conflictStyle
file:.git/config	zdiff3
$ git merge feature/unsure-verdict
Auto-merging evalkit/judge.py
CONFLICT (content): Merge conflict in evalkit/judge.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat evalkit/judge.py
def parse_verdict(text):
    text = text.strip().upper()
    if text.startswith("PASS"):
        return 1.0
    if text.startswith("FAIL"):
        return 0.0
<<<<<<< HEAD
    return None
||||||| 630e488
    raise ValueError(f"unparseable verdict: {text!r}")
=======
    if text.startswith("UNSURE"):
        return 0.5
    raise ValueError(f"unparseable verdict: {text!r}")
>>>>>>> feature/unsure-verdict
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/04-intent -->
```text
$ git ls-files -u
100644 394922b0b98e3521c88fe15dac858c7b8b899e74 1	evalkit/judge.py
100644 00a9111f22d1ff7959db2711d5a5e9655989a46a 2	evalkit/judge.py
100644 f06146116a851275b8927f7412222284f79f5852 3	evalkit/judge.py
# stage 1 to stage 2: what OUR side did to the common ancestor
$ git diff -U0 :1:evalkit/judge.py :2:evalkit/judge.py
diff --git a/evalkit/judge.py b/evalkit/judge.py
index 394922b..00a9111 100644
--- a/evalkit/judge.py
+++ b/evalkit/judge.py
@@ -7 +7 @@ def parse_verdict(text):
-    raise ValueError(f"unparseable verdict: {text!r}")
+    return None
# stage 1 to stage 3: what THEIR side did to it
$ git diff -U0 :1:evalkit/judge.py :3:evalkit/judge.py
diff --git a/evalkit/judge.py b/evalkit/judge.py
index 394922b..f061461 100644
--- a/evalkit/judge.py
+++ b/evalkit/judge.py
@@ -6,0 +7,2 @@ def parse_verdict(text):
+    if text.startswith("UNSURE"):
+        return 0.5
```
<!-- /snippet -->

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/05-resolve -->
```text
# In your editor: keep their UNSURE branch and our "return None". Delete the markers and the base section.
$ cat evalkit/judge.py
def parse_verdict(text):
    text = text.strip().upper()
    if text.startswith("PASS"):
        return 1.0
    if text.startswith("FAIL"):
        return 0.0
    if text.startswith("UNSURE"):
        return 0.5
    return None
$ git add evalkit/judge.py
$ git diff --cached --check
[exit status: 0]
$ git merge --continue
[main e85ca7e] Merge branch 'feature/unsure-verdict'
```
<!-- /snippet -->

### What happened internally

In the default style the block shows `return None` against three lines that end in `raise`. It reads as if their side had added the `raise`. The base section of the second attempt proves otherwise: the `raise` line was there all along (`||||||| 630e488` is the merge base). Our side replaced it, and their side inserted two lines above it. The two stage diffs say the same without markers. The correct result keeps their insertion and our replacement. Keeping "all of theirs" would have brought the `raise` back and undone your commit.

The abort was `git reset --merge`: the reflog entry reads `reset: moving to HEAD`, HEAD and `ORIG_HEAD` are the same commit, and the `MERGE_*` files are gone. The change to `prompts/judge.txt` that had merged cleanly was removed as well, because it was a staged merge result. The second attempt recomputed everything. The stage blobs are the same in both attempts. `merge.conflictStyle` changed only the text that was written into the working tree file.

Aborting was not required to see the base. `git restore --conflict=zdiff3 evalkit/judge.py` rewrites one conflicted file from the stages and leaves every other resolution alone (section 8.9). An abort is the right tool when you want to start the whole merge again.

### Checkpoint

```bash
git log --oneline --graph -5
git show --remerge-diff --format="%h %s" HEAD
```

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/06-checkpoint -->
```text
$ git log --oneline --graph -5
*   e85ca7e Merge branch 'feature/unsure-verdict'
|\  
| * 3e28b8d Let the judge answer UNSURE
| * 32be383 Score UNSURE verdicts as 0.5
* | 3463938 Return None for unparseable verdicts instead of raising
|/  
* 630e488 Add the verdict parser
$ git show --remerge-diff --format="%h %s" HEAD
e85ca7e Merge branch 'feature/unsure-verdict'

diff --git a/evalkit/judge.py b/evalkit/judge.py
remerge CONFLICT (content): Merge conflict in evalkit/judge.py
index 9ea0ffb..a0ae5ce 100644
--- a/evalkit/judge.py
+++ b/evalkit/judge.py
@@ -4,12 +4,6 @@ def parse_verdict(text):
         return 1.0
     if text.startswith("FAIL"):
         return 0.0
-<<<<<<< 3463938 (Return None for unparseable verdicts instead of raising)
-    return None
-||||||| 630e488
-    raise ValueError(f"unparseable verdict: {text!r}")
-=======
     if text.startswith("UNSURE"):
         return 0.5
-    raise ValueError(f"unparseable verdict: {text!r}")
->>>>>>> 3e28b8d (Let the judge answer UNSURE)
+    return None
```
<!-- /snippet -->

The remerge diff must show the marker lines, the base section and the `raise` line removed, and `return None` added below the `UNSURE` branch.

### Failure scenario

You are trying out a new line in the judge prompt and have not committed it. Ravi asks you to merge his branch. You merge, resolve, and stage everything with the usual reflex. Then the merge is called off.

```bash
echo "Think step by step before you answer." >> prompts/judge.txt
git status --short
git merge feature/short-errors
```

Edit `evalkit/judge.py`: keep the three lines of our side and delete the rest of the block, markers included. Then:

```bash
git add -A
git status --short
git merge --abort
git status --short --branch
tail -1 prompts/judge.txt
```

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/07-failure -->
```text
$ echo "Think step by step before you answer." >> prompts/judge.txt
$ git status --short
 M prompts/judge.txt
$ git merge feature/short-errors
Auto-merging evalkit/judge.py
CONFLICT (content): Merge conflict in evalkit/judge.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# In your editor: keep our three lines, delete the rest of the conflict block. Then the reflex:
$ git add -A
$ git status --short
M  prompts/judge.txt
# Ravi tells you the branch is not ready. You abort.
$ git merge --abort
$ git status --short --branch
## main
$ tail -1 prompts/judge.txt
Answer with PASS, FAIL or UNSURE.
```
<!-- /snippet -->

The working tree is clean and the prompt line is gone. It was never committed. `git add -A` staged it together with the resolution, and the abort reset every staged path to HEAD. (`evalkit/judge.py` was not listed after `git add -A` because your resolution equals the version in HEAD.)

### Recovery

The stash list is empty, because you never stashed anything. But `git merge` did: when a true merge starts on a tree with local changes, it first writes a stash-shaped commit as a safety copy. Nothing refers to that commit, so `git fsck` reports it as dangling. Copy its ID from the output:

```bash
git stash list
git fsck | grep commit
git show -s --format='%h %s' <id>
git diff --stat <id>^1 <id>
git restore --source=<id> -- prompts/judge.txt
git status --short
tail -1 prompts/judge.txt
```

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/08-recovery -->
```text
$ git stash list
$ git fsck | grep commit
dangling commit 4b38fd07c46873e8f5217419355560899f37d893
$ git show -s --format='%h %s' 4b38fd0
4b38fd0 WIP on main: e85ca7e Merge branch 'feature/unsure-verdict'
$ git diff --stat 4b38fd0^1 4b38fd0
 prompts/judge.txt | 1 +
 1 file changed, 1 insertion(+)
$ git restore --source=4b38fd0 -- prompts/judge.txt
$ git status --short
 M prompts/judge.txt
$ tail -1 prompts/judge.txt
Think step by step before you answer.
```
<!-- /snippet -->

The message "WIP on main" is the one that `git stash` writes. Its first parent is the commit you were on, and the diff against that parent is your lost edit. `git restore --source` copied the file out of that commit into the working tree. `git stash apply <id>` would also work. Do not wait with this: an unreferenced commit lasts only until Git prunes unreachable objects (Chapter 13).

### Verification

The last two commands of the recovery showed the edit back in the working tree as an unstaged change. Now verify the prevention. Repeat the same sequence with the edit protected:

```bash
git merge --autostash feature/short-errors
```

Edit `evalkit/judge.py` as before, then:

```bash
git add -A
git status --short
git merge --abort
git status --short
tail -1 prompts/judge.txt
```

<!-- snippet: ch08/lab-06-7-abort-retry-zdiff3/09-verification -->
```text
# The same reflex, this time with the edit protected by --autostash:
$ git merge --autostash feature/short-errors
Created autostash: 46482ab
Auto-merging evalkit/judge.py
CONFLICT (content): Merge conflict in evalkit/judge.py
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
[exit status: 1]
$ git add -A
$ git status --short
$ git merge --abort
Applied autostash.
$ git status --short
 M prompts/judge.txt
$ tail -1 prompts/judge.txt
Think step by step before you answer.
```
<!-- /snippet -->

With `--autostash` the edit was out of the working tree during the merge, so `git add -A` could not stage it, and the abort put it back ("Applied autostash."). The hint about `git stash pop` in the conflict message is misleading: the abort, like `--continue`, applies the stash for you (section 8.19).

### Questions

1. From the default-style block alone, which side seemed to have written the `raise` line? What did the base section prove, and how did that change the resolution?
2. After `git merge --abort`, what did the reflog record, and why did the cleanly merged change to `prompts/judge.txt` disappear too?
3. The stage blobs were identical in both attempts. What does `merge.conflictStyle` change, and how could you have seen the base without aborting?
4. Section 8.19 says that uncommitted work in paths that the merge does not touch survives an abort. Why did the prompt edit not survive in the failure scenario?
5. Where did the commit "WIP on main" come from, why was it not in `git stash list`, and how long can you rely on it?
6. How did `--autostash` change the outcome of the same sequence, and what did the hint about `git stash pop` get wrong?

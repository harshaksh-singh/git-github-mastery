# Module 10 labs: Range notation

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" below is real output from the replay script `labs/ch14a/lab-10-4-range-notation.sh`.

This file holds Lab 10.4. Labs 10.1 to 10.3, on cherry-pick, are in [m10-cherry-pick-ranges.md](m10-cherry-pick-ranges.md). The lab belongs to [Chapter 14A, History investigation](../textbook/ch14a-history-investigation.md), sections 14A.2 and 14A.8. The general rules for labs are in the [lab manual README](README.md).

```bash
bash labs/ch14a/setup-10-4-range-notation.sh     # builds the starting repository
labs/shell m10-4                                 # opens the isolated lab shell in that sandbox
labs/run ch14a/lab-10-4-range-notation           # or: replay the whole lab and print the transcript
```

## Lab 10.4: Predict two-dot and three-dot output for `git log` and for `git diff`

### Objective

Predict, from a drawn graph and before running anything, which commits `A..B` and `A...B` select for `git log` and which two snapshots they compare for `git diff`. Then see what a two-endpoint diff does when it is applied as "the feature patch".

### Prerequisites

Chapter 14A, sections 14A.2 and 14A.8. Chapter 7, section 7.8 (merge base).

### Setup

```bash
bash labs/ch14a/setup-10-4-range-notation.sh
labs/shell m10-4
cd retriever
```

`retriever` is a small document retrieval service. You are on `main`. Asha's branch `feat/rerank` forked from `main` three commits ago, and `main` has moved on since:

```text
                F---G---H      feat/rerank
               /
      A---B---C---D---E        main   (HEAD -> main)

  C  Add top_k setting             (config.yaml: top_k: 5)
  D  Raise top_k to 10             (config.yaml)
  E  Add request timeout           (config.yaml: timeout_s: 5)
  F  Add reranker module           (new file rerank.py)
  G  Call the reranker from the retriever   (retriever.py)
  H  Add rerank_top_n setting      (config.yaml: one new line)
```

The commits were made in the order F, D, G, E, H.

### Commands

Fill in this table on paper first. For the log rows write commit letters; for the diff rows write which two commits are compared and which files will appear.

| Command | Your prediction |
|---|---|
| `git log --oneline main..feat/rerank` | |
| `git log --oneline feat/rerank..main` | |
| `git log --oneline main...feat/rerank` | |
| `git diff --stat main..feat/rerank` | |
| `git diff --stat main...feat/rerank` | |
| `git diff --stat feat/rerank...main` | |

Then run them:

```bash
git log --graph --oneline --all
cat config.yaml
git log --oneline main..feat/rerank
git log --oneline feat/rerank..main
git log --oneline main...feat/rerank
git log --oneline --left-right main...feat/rerank
git diff --stat main..feat/rerank
git diff main..feat/rerank -- config.yaml
git diff --stat main...feat/rerank
git diff main...feat/rerank -- config.yaml
git merge-base main feat/rerank
git diff --stat $(git merge-base main feat/rerank) feat/rerank
git diff --stat feat/rerank...main
```

Second round. Bring a copy of the branch up to date with `main`, predict the same six answers for the copy, and check:

```bash
git switch --quiet -c feat/rerank-updated feat/rerank
git merge --no-edit main
git log --oneline main..feat/rerank-updated
git log --oneline feat/rerank-updated..main
git diff --stat main..feat/rerank-updated
git diff --stat main...feat/rerank-updated
git switch --quiet main
```

### Expected output

<!-- snippet: ch14a/lab-10-4-range-notation/01-graph -->
```text
$ git log --graph --oneline --all
* 8cfda6e Add rerank_top_n setting
* b262eba Call the reranker from the retriever
* 9a40ef3 Add reranker module
| * 4685016 Add request timeout
| * 7b164dc Raise top_k to 10
|/  
* b18f163 Add top_k setting
* e6aa85b Add BM25 scoring
* ec3b0f0 Add retriever skeleton
$ cat config.yaml
index: docs-v1
embedding_model: e5-small
top_k: 10
log_level: info
timeout_s: 5
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-10-4-range-notation/02-log-two-dots -->
```text
$ git log --oneline main..feat/rerank
8cfda6e Add rerank_top_n setting
b262eba Call the reranker from the retriever
9a40ef3 Add reranker module
$ git log --oneline feat/rerank..main
4685016 Add request timeout
7b164dc Raise top_k to 10
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-10-4-range-notation/03-log-three-dots -->
```text
$ git log --oneline main...feat/rerank
8cfda6e Add rerank_top_n setting
4685016 Add request timeout
b262eba Call the reranker from the retriever
7b164dc Raise top_k to 10
9a40ef3 Add reranker module
$ git log --oneline --left-right main...feat/rerank
> 8cfda6e Add rerank_top_n setting
< 4685016 Add request timeout
> b262eba Call the reranker from the retriever
< 7b164dc Raise top_k to 10
> 9a40ef3 Add reranker module
```
<!-- /snippet -->

The three-dot log interleaves the two sides by commit date. Without `--left-right` you cannot tell which commit belongs to which side.

<!-- snippet: ch14a/lab-10-4-range-notation/04-diff-two-dots -->
```text
$ git diff --stat main..feat/rerank
 config.yaml  | 4 ++--
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 9 insertions(+), 3 deletions(-)
$ git diff main..feat/rerank -- config.yaml
diff --git a/config.yaml b/config.yaml
index 78286b2..1ad345d 100644
--- a/config.yaml
+++ b/config.yaml
@@ -1,5 +1,5 @@
 index: docs-v1
+rerank_top_n: 3
 embedding_model: e5-small
-top_k: 10
+top_k: 5
 log_level: info
-timeout_s: 5
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-10-4-range-notation/05-diff-three-dots -->
```text
$ git diff --stat main...feat/rerank
 config.yaml  | 1 +
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 8 insertions(+), 1 deletion(-)
$ git diff main...feat/rerank -- config.yaml
diff --git a/config.yaml b/config.yaml
index 910f443..1ad345d 100644
--- a/config.yaml
+++ b/config.yaml
@@ -1,4 +1,5 @@
 index: docs-v1
+rerank_top_n: 3
 embedding_model: e5-small
 top_k: 5
 log_level: info
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-10-4-range-notation/06-merge-base -->
```text
$ git merge-base main feat/rerank
b18f16329cb49daa9f44a22d114a09553ca39321
$ git diff --stat $(git merge-base main feat/rerank) feat/rerank
 config.yaml  | 1 +
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 8 insertions(+), 1 deletion(-)
$ git diff --stat feat/rerank...main
 config.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

After the merge of `main` into the copy of the branch:

<!-- snippet: ch14a/lab-10-4-range-notation/07-after-update -->
```text
# Bring the branch up to date with main, on a copy of the branch, and ask again.
$ git switch --quiet -c feat/rerank-updated feat/rerank
$ git merge --no-edit main
Auto-merging config.yaml
Merge made by the 'ort' strategy.
 config.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git log --oneline main..feat/rerank-updated
f7041a7 Merge branch 'main' into feat/rerank-updated
8cfda6e Add rerank_top_n setting
b262eba Call the reranker from the retriever
9a40ef3 Add reranker module
$ git log --oneline feat/rerank-updated..main
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-10-4-range-notation/08-after-update-diff -->
```text
$ git diff --stat main..feat/rerank-updated
 config.yaml  | 1 +
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 8 insertions(+), 1 deletion(-)
$ git diff --stat main...feat/rerank-updated
 config.yaml  | 1 +
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 8 insertions(+), 1 deletion(-)
$ git switch --quiet main
```
<!-- /snippet -->

### What happened internally

For `git log`, the dots are set operations on reachability. `main..feat/rerank` is everything reachable from H minus everything reachable from E: F, G and H. `feat/rerank..main` is D and E. `main...feat/rerank` is the union of the two. Nothing was read but commit objects and their parent links.

For `git diff`, the same text selects two trees. `main..feat/rerank` compares the tree of E with the tree of H. Going from E to H, `top_k` changes from 10 back to 5 and `timeout_s` disappears, because H was built on C and never saw D and E. `main...feat/rerank` compares the tree of the merge base C with the tree of H, and shows what F, G and H did: one new line in `config.yaml`, one new file, one changed file.

After `git merge main` on the copy of the branch, the merge base of `main` and the copy is E itself, the tip of `main`. A three-dot diff from E and a two-endpoint diff from E are the same comparison, so the two commands agree, and `feat/rerank-updated..main` is empty.

### Checkpoint

Your six predictions matched, or you can say for each miss which rule you applied wrongly. You can state in one sentence why the two-dot and three-dot diffs differ before the merge and agree after it.

### Failure scenario

A colleague wants the feature on `main` as a single commit and does not want a merge. They take "the diff between main and the branch" and apply it:

```bash
git diff main..feat/rerank | git apply --index
git commit -q -m "Add reranker (applied as a patch)"
git show --stat --format="%h %s" HEAD
git diff HEAD~1 HEAD -- config.yaml
git log --oneline -3 -- config.yaml
```

<!-- snippet: ch14a/lab-10-4-range-notation/09-failure -->
```text
# A colleague ships the feature as a patch: "the diff between main and the branch".
$ git diff main..feat/rerank | git apply --index
$ git commit -q -m "Add reranker (applied as a patch)"
$ git show --stat --format="%h %s" HEAD
94f3d23 Add reranker (applied as a patch)

 config.yaml  | 4 ++--
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 9 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-10-4-range-notation/10-diagnose -->
```text
$ git diff HEAD~1 HEAD -- config.yaml
diff --git a/config.yaml b/config.yaml
index 78286b2..1ad345d 100644
--- a/config.yaml
+++ b/config.yaml
@@ -1,5 +1,5 @@
 index: docs-v1
+rerank_top_n: 3
 embedding_model: e5-small
-top_k: 10
+top_k: 5
 log_level: info
-timeout_s: 5
$ git log --oneline -3 -- config.yaml
94f3d23 Add reranker (applied as a patch)
4685016 Add request timeout
7b164dc Raise top_k to 10
```
<!-- /snippet -->

The patch applied without an error, and the commit quietly undid two commits of `main`: `top_k` is 5 again and the request timeout is gone. Nothing warned, because a two-endpoint diff from `main` always applies cleanly to `main`: it is, by construction, the edit that turns the tree of `main` into the tree of the branch.

### Recovery

The commit has not been pushed and the working tree is clean, so the branch can step back one commit. 🔴 `git reset --hard` discards uncommitted changes in tracked files; check `git status` first. On a shared branch you would use `git revert` instead ([Chapter 11](../textbook/ch11-reset-revert-restore.md)).

```bash
git status --short
git reset --hard HEAD~1
git diff main...feat/rerank | git apply --index
```

<!-- snippet: ch14a/lab-10-4-range-notation/11-recovery -->
```text
# The commit is unpushed and the working tree is clean, so the branch can step back one commit.
$ git reset --hard HEAD~1
HEAD is now at 4685016 Add request timeout
# The three-dot diff is the right patch, but it was made against the merge base, not against main:
$ git diff main...feat/rerank | git apply --index
error: patch failed: config.yaml:1
error: config.yaml: patch does not apply
[exit status: 1]
```
<!-- /snippet -->

The three-dot diff is the right patch, and it does not apply. It was computed against the merge base, where `top_k` was 5; on `main` that context line reads 10. A patch made against one snapshot can be combined with a different snapshot only by a three-way merge, which `git apply --3way` performs using the blob IDs recorded in the patch:

```bash
git diff main...feat/rerank | git apply --3way
git status --short
git commit -q -m "Add reranker (applied as a patch)"
```

<!-- snippet: ch14a/lab-10-4-range-notation/12-recovery-3way -->
```text
$ git diff main...feat/rerank | git apply --3way
Applied patch to 'config.yaml' cleanly.
Falling back to direct application...
Applied patch to 'retriever.py' cleanly.
$ git status --short
M  config.yaml
A  rerank.py
M  retriever.py
$ git commit -q -m "Add reranker (applied as a patch)"
```
<!-- /snippet -->

`git merge --squash feat/rerank` followed by `git commit` does the same three-way merge in one step and is the usual tool ([Chapter 8](../textbook/ch08-merge.md)).

### Verification

```bash
git show --stat --format="%h %s" HEAD
cat config.yaml
git diff --stat HEAD feat/rerank-updated
```

<!-- snippet: ch14a/lab-10-4-range-notation/13-verification -->
```text
$ git show --stat --format="%h %s" HEAD
ce0aca7 Add reranker (applied as a patch)

 config.yaml  | 1 +
 rerank.py    | 2 ++
 retriever.py | 6 +++++-
 3 files changed, 8 insertions(+), 1 deletion(-)
$ cat config.yaml
index: docs-v1
rerank_top_n: 3
embedding_model: e5-small
top_k: 10
log_level: info
timeout_s: 5
$ git diff --stat HEAD feat/rerank-updated
```
<!-- /snippet -->

The new commit adds one line to `config.yaml` and keeps `top_k: 10` and `timeout_s: 5`. The last command prints nothing: the tree of `main` now equals the tree of the branch that was brought up to date by a merge. Your commit ID differs from the one printed here, because your commit was made at a different time.

### Questions

1. For `git log`, write `A...B` using only `^`, plain revisions and `git merge-base`. Which commits does it contain when A is an ancestor of B?
2. `git diff main..feat/rerank` showed `top_k: 10` being replaced by `top_k: 5`. No commit on `feat/rerank` contains that edit. Where does it come from?
3. Why did the two-endpoint diff apply to `main` without any conflict, and why does that make it more dangerous than a patch that fails?
4. After `git merge main` on the branch, `git diff main..branch` and `git diff main...branch` print the same thing. State the condition, in terms of the merge base, under which the two forms always agree.
5. A pull request on GitHub is five commits behind its base branch. Which of the two diffs does its "Files changed" tab correspond to, and what would a reviewer see differently if it showed the other one?
6. `git log --oneline main...feat/rerank` printed the commits of both sides mixed together. Which option separates them, and which further option shows the commit where the two sides meet?

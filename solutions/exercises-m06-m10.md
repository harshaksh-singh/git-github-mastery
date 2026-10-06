# Solutions to the exercises of Modules 6 to 10

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the scripts in `labs/ex1/`: `ex-m06.sh` to `ex-m10.sh` for Levels 1 to 3 and `solve-mNN-<name>.sh` for the generated exercises. The questions are in [exercises/m06-m10-integration.md](../exercises/m06-m10-integration.md). Read a solution only after you have written your own answer.

## How to read these solutions

The parts of each solution and the differences between the transcripts and your terminal are described at the top of [the solutions for Modules 1 to 5](exercises-m01-m05.md). In short: `$LAB` is the lab root; commits you create have other IDs than the ones printed here, while commits that a generator created have the same; `[exit status: N]` and lines starting with `#` come from the scripts; `labs/run ex1/<script>` replays a model run.

Where a transcript shows `--- todo list as Git opened it ---` and `--- todo list as saved ---`, a script played the editor. You make the same change by hand in your editor.

A Level 5 solution ends with a **claims** table: every statement from the report, the verdict, and the evidence.

---

## Module 6: Merge

### Solution 6.1: a fast-forward, then a merge commit

**Solution.**

<!-- snippet: ex1/ex-m06/e01-ff -->
```text
$ git init -q retriever
$ cd retriever
$ printf 'def search(query):\n    return []\n' > search.py
$ git add search.py
$ git commit -q -m "Add search stub"
$ git switch -q -c feature/bm25
$ printf 'K1 = 1.2\nB = 0.75\n' > bm25.py
$ git add bm25.py
$ git commit -q -m "Add BM25 parameters"
$ git switch -q main
$ git merge feature/bm25
Updating 5d5fa50..6664d7c
Fast-forward
 bm25.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 bm25.py
$ git log --graph --oneline
* 6664d7c Add BM25 parameters
* 5d5fa50 Add search stub
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m06/e01-no-ff -->
```text
$ git switch -q -c feature/dense
$ printf 'DIM = 768\n' > dense.py
$ git add dense.py
$ git commit -q -m "Add dense retriever settings"
$ git switch -q main
$ git merge --no-ff -m "Merge feature/dense" feature/dense
Merge made by the 'ort' strategy.
 dense.py | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 dense.py
$ git log --graph --oneline
*   71be7f1 Merge feature/dense
|\  
| * 187e004 Add dense retriever settings
|/  
* 6664d7c Add BM25 parameters
* 5d5fa50 Add search stub
$ git cat-file -p HEAD
tree 0a3e4d2127a569156df1843d34b76f78fc79cda2
parent 6664d7cd8437a8646f6ebe21b0c6cc62450b1459
parent 187e004c67d2f5b9e853fa39eb31ac4f1043767a
author Lab User <you@example.com> 1788756540 +0530
committer Lab User <you@example.com> 1788756540 +0530

Merge feature/dense
```
<!-- /snippet -->

| | First merge | Second merge (`--no-ff`) |
|---|---|---|
| New commit | none | one merge commit with two `parent` lines |
| Ref that moved | `main`, from the old tip to the tip of `feature/bm25` | `main`, to the new merge commit |
| Graph afterwards | a straight line | a bubble: the feature's commit on a side line, joined by the merge |

In both cases `main` had no commit that the feature lacked, so a fast-forward was possible. `--no-ff` bought a record: the history shows that a feature was integrated, where it started and where it ended, and the merge commit is one handle for the whole feature. To take the feature out later: in the first history `git revert` must name every commit of the feature; in the second, `git revert -m 1 <merge>` undoes it as a unit.

**Reasoning.** A fast-forward is not a merge of content. It moves a ref forward along existing commits. A merge commit is needed only when both sides have commits the other lacks, or when you ask for one.

**Common mistakes.** Saying "Git merged the files" about a fast-forward: no file-level merge happened. Believing `--no-ff` changes the resulting content. Forgetting that after a fast-forward nothing in history says that `feature/bm25` ever existed as a branch.

**Expert approach.** Choose per branch type, and write it down as team policy: `--ff-only` to update a local `main` from the server (a surprise divergence stops you), `--no-ff` to integrate a feature as one revertable unit.

**Reference.** Chapter 8, sections 8.3, 8.12 and 8.13.

### Solution 6.2: the merge base and the rule table

**Solution.**

<!-- snippet: ex1/ex-m06/e02-base -->
```text
$ git init -q rules
$ cd rules
$ printf 'top_k: 5\nmetric: cosine\nrerank: false\n' > search.yaml
$ git add search.yaml
$ git commit -q -m "Add search settings"
$ git switch -q -c feature/rerank
$ printf 'top_k: 5\nmetric: cosine\nrerank: true\n' > search.yaml
$ git commit -q -am "Switch reranking on"
$ git switch -q main
$ printf 'top_k: 10\nmetric: cosine\nrerank: false\n' > search.yaml
$ git commit -q -am "Return ten hits"
$ git merge-base main feature/rerank
8ab69aa9e4989eb1c391da66fd2f0d6c516f13d6
$ git show "$(git merge-base main feature/rerank)":search.yaml
top_k: 5
metric: cosine
rerank: false
```
<!-- /snippet -->

| Line | Base | Ours (`main`) | Theirs (`feature/rerank`) | Result | Rule applied |
|---|---|---|---|---|---|
| 1 | `top_k: 5` | `top_k: 10` | `top_k: 5` | `top_k: 10` | only ours changed: take ours |
| 2 | `metric: cosine` | `metric: cosine` | `metric: cosine` | `metric: cosine` | nobody changed: keep |
| 3 | `rerank: false` | `rerank: false` | `rerank: true` | `rerank: true` | only theirs changed: take theirs |

<!-- snippet: ex1/ex-m06/e02-merge -->
```text
$ git merge -m "Merge feature/rerank" feature/rerank
Auto-merging search.yaml
Merge made by the 'ort' strategy.
 search.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat search.yaml
top_k: 10
metric: cosine
rerank: true
$ git log --graph --oneline
*   e6f47cd Merge feature/rerank
|\  
| * 4da0cd6 Switch reranking on
* | c6c4770 Return ten hits
|/  
* 8ab69aa Add search settings
```
<!-- /snippet -->

Git needed the version at the merge base, "Add search settings", which neither tip contains any more. Without it, lines 1 and 3 would be two unexplained differences and Git could not tell a change from a leftover.

**Reasoning.** A merge has three inputs. For each region, the base decides who changed it. A two-way comparison of the tips can say that they differ and never who is right.

**Common mistakes.** Describing a merge as "combining the two tips". Believing Git replays the commits of the branch: it looks at three trees only, however many commits lie between them. Expecting a conflict whenever both sides changed the same file.

**Expert approach.** Before a merge that worries you, look at what each side did since the base: `git diff main...feature` shows the feature's side (three dots: from the merge base), `git diff feature...main` shows yours.

**Reference.** Chapter 8, sections 8.2 and 8.4.

### Solution 6.3: one conflict, step by step

**Solution.**

<!-- snippet: ex1/ex-m06/e03-conflict -->
```text
$ git init -q conflict
$ cd conflict
$ printf 'model: small\n' > model.yaml
$ git add model.yaml
$ git commit -q -m "Add model setting"
$ git switch -q -c exp/large
$ printf 'model: large\n' > model.yaml
$ git commit -q -am "Use the large model"
$ git switch -q main
$ printf 'model: medium\n' > model.yaml
$ git commit -q -am "Use the medium model"
$ git merge exp/large
Auto-merging model.yaml
CONFLICT (content): Merge conflict in model.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   model.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m06/e03-look -->
```text
$ cat model.yaml
<<<<<<< HEAD
model: medium
=======
model: large
>>>>>>> exp/large
$ git ls-files -u
100644 4a39d8538882331686b4e2834520d5947bd75a6b 1	model.yaml
100644 76f6d2aa10a6952dbacb67560e88624d17cd9fa6 2	model.yaml
100644 51dad65991f3c078d2e9dff77520be24231a592d 3	model.yaml
$ ls .git | grep MERGE
AUTO_MERGE
MERGE_HEAD
MERGE_MODE
MERGE_MSG
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m06/e03-resolve -->
```text
$ printf 'model: large\n' > model.yaml
$ git add model.yaml
$ git status --short
M  model.yaml
$ git merge --continue
[main 5f8ca3e] Merge branch 'exp/large'
$ git log --graph --oneline
*   5f8ca3e Merge branch 'exp/large'
|\  
| * 3923e4b Use the large model
* | 6e8923e Use the medium model
|/  
* 8e6a8f2 Add model setting
```
<!-- /snippet -->

While the merge is stopped:

- **Working tree:** `model.yaml` contains both candidates between markers. `HEAD` labels your side, `exp/large` theirs.
- **Index:** three entries for the one path. Stage 1 is the base version (`small`), stage 2 is ours (`medium`), stage 3 is theirs (`large`).
- **`.git`:** `MERGE_HEAD` holds the commit being merged, `MERGE_MSG` the proposed message, `MERGE_MODE` the options, `AUTO_MERGE` a tree with the automatic result including markers.

`git add model.yaml` replaces the three staged versions by one entry at stage 0 with the file's current content. An index without higher stages is what "resolved" means to Git; `git merge --continue` then creates the commit with two parents. `git merge --abort` would have restored index and working tree to the state before the merge and removed the `MERGE_*` files.

**Reasoning.** Both sides changed the same line differently, so no rule of the table applies. Git stops, hands you all three versions, and waits for one.

**Common mistakes.** Picking a side by deleting markers without reading both changes. Running `git add` on a file that still contains markers: Git accepts it (Exercise 6.8). Believing the working tree file is the only place where the versions are: `git show :1:model.yaml`, `:2:` and `:3:` print each one cleanly.

**Expert approach.** Resolve by intent, not by side: read what each commit wanted, then write the line that satisfies both or decide which requirement wins, and say so in the merge message.

**Reference.** Chapter 8, sections 8.7, 8.8 and 8.10.

### Solution 6.4: two merges

**Solution.**

<!-- snippet: ex1/ex-m06/e04-answer -->
```text
$ git log --graph --oneline
*   b8fb7e4 M2
|\  
| * 93906f7 F
* |   7ae7617 M1
|\ \  
| |/  
|/|   
| * 48ee3b0 D
| * 0894508 C
* | c915e73 E
|/  
* d10c29a B
* 60d5352 A
$ git log --first-parent --oneline
b8fb7e4 M2
7ae7617 M1
c915e73 E
d10c29a B
60d5352 A
$ git show -s --format="%s: parents %p" HEAD HEAD~1
M2: parents 7ae7617 93906f7
M1: parents c915e73 48ee3b0
```
<!-- /snippet -->

```text
          C---D                  f1
         /     \
A---B---E-------M1---M2          main      (HEAD -> main)
         \          /
          F--------/             f2
```

`M1` has the parents `E` (first) and `D` (second). `M2` has the parents `M1` (first) and `F` (second). The first-parent history is `M2`, `M1`, `E`, `B`, `A`: what happened on `main`, with each feature reduced to its merge.

The second merge needed no `--no-ff`: when `f2` was merged, `main` already had `M1`, which `f2` lacks, and `f2` had `F`, which `main` lacks. A fast-forward was impossible, so Git created a merge commit.

**Reasoning.** In the `--graph` drawing, the leftmost line out of a merge is its first parent. `f1` forked from `B` and `f2` from `E`, which is why the two side lines leave the main line at different points and cross in the drawing.

**Common mistakes.** Drawing `f2` as starting from `B`. Swapping the parents of a merge. Reading the vertical order of `git log` as strictly chronological across branches.

**Expert approach.** `git log --first-parent --oneline main` is the release manager's view. It is only trustworthy when everything reaches `main` by merge into `main`, never by merging `main` the other way and fast-forwarding back.

**Reference.** Chapter 8, sections 8.3 and 8.13.

### Solution 6.5: what a squash leaves behind

**Solution.**

<!-- snippet: ex1/ex-m06/e05-setup -->
```text
$ git init -q squash
$ cd squash
$ printf 'v1\n' > core.txt
$ git add core.txt
$ git commit -q -m "Add core"
$ git switch -q -c feature/x
$ printf 'one\n' > x1.txt
$ git add x1.txt
$ git commit -q -m "Add x1"
$ printf 'two\n' > x2.txt
$ git add x2.txt
$ git commit -q -m "Add x2"
$ git switch -q main
$ git merge --squash feature/x
Updating 725cf14..36500d5
Fast-forward
Squash commit -- not updating HEAD
 x1.txt | 1 +
 x2.txt | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 x1.txt
 create mode 100644 x2.txt
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m06/e05-answer-a -->
```text
$ git status --short
A  x1.txt
A  x2.txt
$ git log --oneline
725cf14 Add core
$ ls .git | grep -E "MERGE|SQUASH"
SQUASH_MSG
```
<!-- /snippet -->

After `git merge --squash`: both files are staged, `main` has no new commit, and there is no `MERGE_HEAD`, only a draft message in `SQUASH_MSG`. Git even reports that a fast-forward would have been possible and that it is "not updating HEAD".

<!-- snippet: ex1/ex-m06/e05-answer-b -->
```text
$ git commit -q -m "Add x (squashed)"
$ git log --graph --oneline --all
* b65224e Add x (squashed)
| * 36500d5 Add x2
| * ac950cc Add x1
|/  
* 725cf14 Add core
$ git show -s --format="parents: %p" HEAD
parents: 725cf14
$ git branch --merged main
* main
$ git branch -d feature/x
error: the branch 'feature/x' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/x'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

After the commit: one new commit with **one** parent. `feature/x` is not listed by `git branch --merged main`, and `git branch -d` refuses it as "not fully merged".

A squash transfers content and no ancestry. The files of the branch are in `main`; its commits are not ancestors of `main`.

**Reasoning.** What makes a commit a merge is its second parent. `--squash` computes the merge result and deliberately does not record where it came from. Every later question that Git answers through parent links (is it merged, what is the merge base, what is new on the branch) is answered as if the squash had never happened.

**Common mistakes.** Expecting `git branch -d` to work after a squash: this branch has no upstream, so `-d` compares with HEAD (with an upstream that still contains the branch it would delete with a warning). Continuing to work on the squashed branch and merging it again: the merge base has not moved, so the second merge re-examines everything (Exercise 6.10). Running `git merge --abort` to back out of a squash: there is no `MERGE_HEAD`; the way back is `git reset --merge`.

**Expert approach.** One squash per branch, then delete the branch with `-D`, deliberately, and start the next piece of work from the updated `main`.

> **GitHub, not Git.** "Squash and merge" on a pull request has the same consequence for ancestry, but it runs on GitHub's servers and is not the local command (Chapter 17).

**Reference.** Chapter 8, section 8.12.

### Solution 6.6: which of three changes conflicts?

**Solution.**

<!-- snippet: ex1/ex-m06/e06-answer -->
```text
$ git merge topic
Auto-merging params.yaml
CONFLICT (content): Merge conflict in params.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat params.yaml
<<<<<<< HEAD
a: 10
b: 2
=======
a: 1
b: 20
>>>>>>> topic
c: 3
d: 40
e: 5
f: 60
$ git diff
diff --cc params.yaml
index 3f99a93,77d449c..0000000
--- a/params.yaml
+++ b/params.yaml
@@@ -1,5 -1,5 +1,10 @@@
++<<<<<<< HEAD
 +a: 10
 +b: 2
++=======
+ a: 1
+ b: 20
++>>>>>>> topic
  c: 3
  d: 40
  e: 5
```
<!-- /snippet -->

- Lines `a` and `b` conflict, as one region. `main` changed `a`, `topic` changed `b`. No line was changed by both, and still Git stops: the two changes touch **adjacent** lines, and Git merges regions of change, not single lines.
- Line `d` is clean: both sides made the identical change, which counts as agreement.
- Line `f` is clean: only `topic` changed it, with unchanged lines between it and every other change.

**Reasoning.** The file-level merge aligns the three versions and groups changed lines into hunks. Two hunks from different sides merge cleanly when at least one unchanged line separates them. When they touch, Git cannot know whether the combination makes sense and asks you.

**Common mistakes.** The rule "a conflict needs the same line changed twice": too narrow. The rule "the same file changed twice conflicts": too broad. Expecting a conflict on `d`.

**Expert approach.** Adjacent-line conflicts are common in lists that everybody appends to: dependency lists, changelogs, registries. Reduce them structurally: one entry per line, sorted, or a `union` merge driver for files where keeping both sides is always right (Chapter 14C, section 14C.7).

**Reference.** Chapter 8, section 8.7.

### Solution 6.7: "Already up to date", and the change is not there

**Solution.**

<!-- snippet: ex1/ex-m06/e07-diagnosis -->
```text
$ git log --merges --format='%h %an: %s (parents %p)'
63bb1dc Asha Rao: Merge feature/bm25-tuning (parents f8c6f49 aae44c8)
$ git diff --stat 63bb1dc^1 63bb1dc
$ git diff --stat 63bb1dc^2 63bb1dc
 README.md      | 2 ++
 ranker/bm25.py | 4 ++--
 2 files changed, 4 insertions(+), 2 deletions(-)
$ git show --remerge-diff --format='%h %s' 63bb1dc
63bb1dc Merge feature/bm25-tuning

diff --git a/ranker/bm25.py b/ranker/bm25.py
index a1b5cc3..538f76c 100644
--- a/ranker/bm25.py
+++ b/ranker/bm25.py
@@ -1,2 +1,2 @@
-K1 = 1.6
-B = 0.6
+K1 = 1.2
+B = 0.75
```
<!-- /snippet -->

1. "Already up to date" and `--merged` are statements about **ancestry**: the tip of `feature/bm25-tuning` is reachable from `main`, through the second parent of the merge commit. Neither statement looks at file content.
2. The merge commit `63bb1dc` records the feature as a parent and records a tree that is identical to its first parent's: `git diff --stat` between first parent and merge is empty. Ancestry says "integrated", the tree says "nothing taken". Such a merge is produced by `git merge -s ours` (the strategy that ignores the other side entirely) or by resolving every conflict in favor of your side. `git show --remerge-diff` is the audit: it repeats the merge mechanically and shows how the recorded result differs from it. Here it shows the two tuning values being put back to the old ones.
3. Since `main` is shared, the merge stays. The content must arrive as new commits:

<!-- snippet: ex1/ex-m06/e07-fix -->
```text
# The merge recorded ancestry without content, so the content has to arrive as new commits.
$ git cherry-pick -x 63bb1dc^1..63bb1dc^2
[main 110cddc] Raise k1 after the grid search
 Date: Mon Sep 7 11:55:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[main c0abc04] Lower b for short documents
 Date: Mon Sep 7 11:56:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show main:ranker/bm25.py
K1 = 1.6
B = 0.6
$ git log --graph --oneline
* c0abc04 Lower b for short documents
* 110cddc Raise k1 after the grid search
* 9c1ef62 Name the owner
*   63bb1dc Merge feature/bm25-tuning
|\  
| * aae44c8 Lower b for short documents
| * 0d08506 Raise k1 after the grid search
* | f8c6f49 Describe the project
|/  
* cc99c71 Add BM25 parameters
```
<!-- /snippet -->

The range `63bb1dc^1..63bb1dc^2` is "what the feature had that the first parent lacked", and `-x` records where each copy came from (Chapter 10). The simpler alternative, `git restore --source=feature/bm25-tuning -- ranker/bm25.py` and a commit, is correct only while `main` has not changed those files since: it copies whole files and would silently undo later work on `main`.

**Reasoning.**

```text
Observed behavior : the branch counts as merged; its changes are not in main.
Git state         : a merge commit whose second parent is the feature and whose tree equals
                    its first parent's tree.
Mechanism         : every later merge finds the feature tip already among main's ancestors.
Root cause        : the merge was made with a strategy or resolution that discarded one side
                    (-s ours where -X ours, or a real resolution, was meant).
Why Git does this : a merge commit is trusted as the record of a decision. Git does not
                    re-examine recorded merges.
Correct fix       : reapply the lost changes as new commits; do not rewrite shared history.
Prevention        : audit merges with --remerge-diff; never use -s ours to silence a conflict.
```

**Common mistakes.** Merging again, or deleting and recreating the branch, and expecting a different answer. Reverting the merge commit: its diff against the first parent is empty, so the revert changes nothing. Confusing `-s ours` (discard their side entirely) with `-X ours` (prefer ours in conflicting hunks only).

**Expert approach.** Whenever "merged" and "present" disagree, look at merge commits on the first-parent line with `git log --merges --remerge-diff --first-parent`. It lists every hand-made decision in the history.

**Reference.** Chapter 8, sections 8.6, 8.16 and 8.19; Chapter 10, section 10.5.

### Solution 6.8: conflict markers in `main`

**Solution.**

<!-- snippet: ex1/ex-m06/e08-diagnosis -->
```text
# A plain pickaxe walk shows no diff for merge commits, so it cannot name one.
$ git log --oneline -S'<<<<<<<' -- prompts/support.txt
$ git log --oneline -m -S'<<<<<<<' -- prompts/support.txt
6a1ebab (from 30afaba) Merge branch 'feature/tone'
6a1ebab (from 000d763) Merge branch 'feature/tone'
$ git show -s --format='%h %an <%ae>%n%s' 6a1ebab
6a1ebab Ravi Menon <ravi@example.com>
Merge branch 'feature/tone'
$ git show --remerge-diff --format='remerge-diff of %h:' 6a1ebab
remerge-diff of 6a1ebab:

diff --git a/prompts/support.txt b/prompts/support.txt
remerge CONFLICT (content): Merge conflict in prompts/support.txt
index e1dee01..e42a7e2 100644
--- a/prompts/support.txt
+++ b/prompts/support.txt
@@ -1,7 +1,7 @@
-<<<<<<< 30afaba (Name the company)
+<<<<<<< HEAD
 You are a support assistant for Acme.
 =======
 You are a friendly support assistant.
->>>>>>> 000d763 (Make the assistant friendly)
+>>>>>>> feature/tone
 Answer in two sentences.
 Cite the knowledge base article.
$ git diff --check 6a1ebab^1 6a1ebab
prompts/support.txt:1: leftover conflict marker
prompts/support.txt:3: leftover conflict marker
prompts/support.txt:5: leftover conflict marker
```
<!-- /snippet -->

1. The markers were introduced by the merge commit `6a1ebab`. A plain `git log -S` prints nothing because `git log` computes no diff for merge commits by default, and the pickaxe searches diffs. With `-m` each merge is compared with each of its parents, and the merge appears, once per parent.
2. Git lets a merge be concluded when the index has no unmerged entries. It does not read the file. Ravi ran `git add` on the file as Git had written it, markers included, and committed. The remerge diff shows it: the recorded result differs from the mechanical one only in the marker labels. `git diff --check` reports `leftover conflict marker` for each of the three lines.
3. Fix forward with a new commit that contains the real resolution:

<!-- snippet: ex1/ex-m06/e08-fix -->
```text
$ printf 'You are a friendly support assistant for Acme.\nAnswer in two sentences.\nCite the knowledge base article.\n' > prompts/support.txt
$ git commit -q -am "Resolve the conflict that was committed with its markers"
$ git grep -n -e '^<<<<<<<' -e '^=======' -e '^>>>>>>>' -- prompts
[exit status: 1]
$ git log --graph --oneline -3
* 4bac5ba Resolve the conflict that was committed with its markers
* 64dec7f Add request timeout
*   6a1ebab Merge branch 'feature/tone'
|\  
```
<!-- /snippet -->

Controls: locally, a pre-commit hook that runs `git diff --cached --check` (the file `pre-commit.sample` that Git puts into `.git/hooks` ends with the plumbing form of that check, `git diff-index --check --cached`); in CI, a job that runs `git diff --check <base>...HEAD` or greps for marker lines. The first is a convenience that can be bypassed, the second is the control.

**Reasoning.** `git add` during a merge means "this path is resolved" and nothing more. Git cannot know what a correct resolution is; it knows only that you declared one.

**Common mistakes.** Rewriting `main` to remove the bad merge. Blaming the author of the last commit on the file. Searching with `git blame`, which attributes the marker lines to the merge commit and is the quickest pointer here, but shows neither what the resolution should have been nor what was discarded.

**Expert approach.** After resolving, run `git diff --cached --check` and the tests before `git merge --continue`, every time. In review, a merge commit whose remerge diff is empty or consists of marker lines deserves a question.

**Reference.** Chapter 8, sections 8.10 and 8.16; Chapter 14A, sections 14A.6 and 14A.11; Chapter 14C, sections 14C.9 and 14C.13.

### Solution 6.9: a merge that somebody else left half done

**Solution.**

<!-- snippet: ex1/solve-m06-half-merged/01-state -->
```text
$ cd hybrid-search
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add/rm <file>..." as appropriate to mark resolution)
	deleted by us:   configs/legacy_weights.yaml
	both modified:   search/retrieve.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git log --oneline --graph main feature/rerank
* 64e6734 Replace legacy_weights.yaml by weights.yaml with a top-level key
* 6ed32e0 Rename top_k to limit and return ten hits by default
| * 6e75bc0 Raise the BM25 weight to 0.5 after the offline evaluation
| * 264021b Add optional reranking to retrieve()
|/  
* b872784 Add hybrid retrieval
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-half-merged/02-both-sides -->
```text
$ git log --oneline --stat MERGE_HEAD..HEAD
64e6734 Replace legacy_weights.yaml by weights.yaml with a top-level key
 configs/legacy_weights.yaml | 2 --
 configs/weights.yaml        | 3 +++
 2 files changed, 3 insertions(+), 2 deletions(-)
6ed32e0 Rename top_k to limit and return ten hits by default
 search/retrieve.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git log --oneline --stat HEAD..MERGE_HEAD
6e75bc0 Raise the BM25 weight to 0.5 after the offline evaluation
 configs/legacy_weights.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
264021b Add optional reranking to retrieve()
 search/retrieve.py | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
$ git ls-files -u
100644 58b99d4f7d2b2ef13a98af707a9a3eeffbab1bf2 1	configs/legacy_weights.yaml
100644 861e05857dcd4776ebf088b333697a1e5adf16c2 3	configs/legacy_weights.yaml
100644 295bffc4103e68d7233a29bb86735db3d18ea765 1	search/retrieve.py
100644 d8f13a1c3d6520f789092fe92e0b60e87e4110bb 2	search/retrieve.py
100644 c90f517fefab8c08bd3a9e0e1a6a23b2f89f3491 3	search/retrieve.py
```
<!-- /snippet -->

Two conflicts of two types: `search/retrieve.py` is a content conflict (three stages), and `configs/legacy_weights.yaml` is a modify/delete conflict (stages 1 and 3 only: we have no version).

What each side intended:

| Side | Commit | Intent |
|---|---|---|
| `main` | Rename `top_k` to `limit` and return ten hits by default | a new parameter name and a new default |
| `main` | Replace `legacy_weights.yaml` by `weights.yaml` with a top-level key | a new file name and a new structure |
| feature | Add optional reranking to `retrieve()` | a new parameter and a new step |
| feature | Raise the BM25 weight to 0.5 after the offline evaluation | a new value, in the old file |

<!-- snippet: ex1/solve-m06-half-merged/03-conflict-1 -->
```text
$ git diff search/retrieve.py
diff --cc search/retrieve.py
index d8f13a1,c90f517..0000000
--- a/search/retrieve.py
+++ b/search/retrieve.py
@@@ -1,3 -1,5 +1,10 @@@
++<<<<<<< HEAD
 +def retrieve(query, limit=10):
 +    hits = index.search(query, limit)
++=======
+ def retrieve(query, top_k=5, rerank=False):
+     hits = index.search(query, top_k)
+     if rerank:
+         hits = reranker.sort(query, hits)
++>>>>>>> feature/rerank
      return hits
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-half-merged/04-resolve-1 -->
```text
$ printf 'def retrieve(query, limit=10, rerank=False):\n    hits = index.search(query, limit)\n    if rerank:\n        hits = reranker.sort(query, hits)\n    return hits\n' > search/retrieve.py
$ git add search/retrieve.py
```
<!-- /snippet -->

The resolution keeps `limit=10` from `main`, adds `rerank=False` and the reranking step from the feature, and uses `limit` in the search call. Taking either side whole would lose the rename or the feature.

<!-- snippet: ex1/solve-m06-half-merged/05-conflict-2 -->
```text
# Three versions of the weights: the base, theirs (stage 3, under the old name), ours (renamed).
$ git show :1:configs/legacy_weights.yaml
bm25_weight: 0.3
dense_weight: 0.7
$ git show :3:configs/legacy_weights.yaml
bm25_weight: 0.5
dense_weight: 0.7
$ git show HEAD:configs/weights.yaml
weights:
  bm25_weight: 0.3
  dense_weight: 0.7
$ ls configs
legacy_weights.yaml
weights.yaml
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-half-merged/06-resolve-2 -->
```text
$ git rm -q configs/legacy_weights.yaml
$ printf 'weights:\n  bm25_weight: 0.5\n  dense_weight: 0.7\n' > configs/weights.yaml
$ git add configs/weights.yaml
$ git status --short
M  configs/weights.yaml
M  search/retrieve.py
$ git diff --cached --check
[exit status: 0]
```
<!-- /snippet -->

Git reports the second conflict as "deleted by us" and leaves their version of the old file in the working tree. It did not connect the old file with `configs/weights.yaml`, because the content was restructured too much to count as a rename. So the feature's change, 0.3 to 0.5, has no place to land by itself. The resolution keeps the deletion and carries the value into the new file **by hand**.

<!-- snippet: ex1/solve-m06-half-merged/07-commit -->
```text
$ git commit
[main f86664c] Merge feature/rerank: optional reranking in retrieve()
$ git log --graph --oneline
*   f86664c Merge feature/rerank: optional reranking in retrieve()
|\  
| * 6e75bc0 Raise the BM25 weight to 0.5 after the offline evaluation
| * 264021b Add optional reranking to retrieve()
* | 64e6734 Replace legacy_weights.yaml by weights.yaml with a top-level key
* | 6ed32e0 Rename top_k to limit and return ten hits by default
|/  
* b872784 Add hybrid retrieval
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-half-merged/08-audit -->
```text
$ git show --remerge-diff --format="%h %s" HEAD
f86664c Merge feature/rerank: optional reranking in retrieve()

diff --git a/configs/legacy_weights.yaml b/configs/legacy_weights.yaml
deleted file mode 100644
remerge CONFLICT (modify/delete): configs/legacy_weights.yaml deleted in 64e6734 (Replace legacy_weights.yaml by weights.yaml with a top-level key) and modified in 6e75bc0 (Raise the BM25 weight to 0.5 after the offline evaluation).  Version 6e75bc0 (Raise the BM25 weight to 0.5 after the offline evaluation) of configs/legacy_weights.yaml left in tree.
index 861e058..0000000
--- a/configs/legacy_weights.yaml
+++ /dev/null
@@ -1,2 +0,0 @@
-bm25_weight: 0.5
-dense_weight: 0.7
diff --git a/configs/weights.yaml b/configs/weights.yaml
index d7215f3..b672da9 100644
--- a/configs/weights.yaml
+++ b/configs/weights.yaml
@@ -1,3 +1,3 @@
 weights:
-  bm25_weight: 0.3
+  bm25_weight: 0.5
   dense_weight: 0.7
diff --git a/search/retrieve.py b/search/retrieve.py
remerge CONFLICT (content): Merge conflict in search/retrieve.py
index 5b6c649..1366020 100644
--- a/search/retrieve.py
+++ b/search/retrieve.py
@@ -1,10 +1,5 @@
-<<<<<<< 64e6734 (Replace legacy_weights.yaml by weights.yaml with a top-level key)
-def retrieve(query, limit=10):
+def retrieve(query, limit=10, rerank=False):
     hits = index.search(query, limit)
-=======
-def retrieve(query, top_k=5, rerank=False):
-    hits = index.search(query, top_k)
     if rerank:
         hits = reranker.sort(query, hits)
->>>>>>> 6e75bc0 (Raise the BM25 weight to 0.5 after the offline evaluation)
     return hits
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-half-merged/09-check -->
```text
$ cd ..
$ exercises/gen/m06-half-merged/check.sh
Checking exercise m06-half-merged
  ok    no merge is in progress any more
  ok    the first parent of main is the commit Ravi started from
  ok    the second parent of main is feature/rerank
  ok    retrieve() has the renamed parameter with its default and the rerank option
  ok    the search call uses limit
  ok    the reranking step is there
  ok    no top_k is left in retrieve.py
  ok    configs/legacy_weights.yaml stays removed
  ok    configs/weights.yaml keeps the top-level key
  ok    the BM25 weight of the feature (0.5) arrived in configs/weights.yaml
  ok    no conflict marker is committed
  ok    the merge message mentions the hand-made change (weights)
  ok    working tree and index are clean
PASS: exercise m06-half-merged is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.** The line `bm25_weight: 0.5` in `configs/weights.yaml` exists in neither parent: `main` has 0.3 there and the feature has no such file. A merge result that contains something neither side contains is what the book calls an evil merge when it is undocumented. Here it is necessary, so it is documented in the merge message, and the remerge diff shows it to any later reader as the one change outside a conflict region.

**Common mistakes.** Resolving the modify/delete conflict with `git rm` and stopping: clean, quick, and the evaluated weight is lost without a trace. Resolving it with `git add`: the dead file is back and nothing reads it. Leaving `top_k` in the call inside the function. Running `git merge --abort` and starting over is legitimate, since Ravi resolved nothing; `git merge --quit` is not, it would leave the half-merged files and forget the merge.

**Expert approach.** Read both sides' commits before reading the conflict (`git log --stat MERGE_HEAD..HEAD` and the reverse). For a deleted-by-us file, always ask where its content went. Finish with `git show --remerge-diff HEAD` and paste its summary into the pull request.

**Reference.** Chapter 8, sections 8.8, 8.10, 8.11, 8.15 and 8.16.

### Solution 6.10: the weekly sync that conflicts more every week

**Solution.** Reproduce the symptom, then back out:

<!-- snippet: ex1/solve-m06-weekly-sync/01-reproduce -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git merge --squash develop
Auto-merging sampler/config.py
CONFLICT (content): Merge conflict in sampler/config.py
Auto-merging sampler/sample.py
Squash commit -- not updating HEAD
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git diff
diff --cc sampler/config.py
index d043352,5e8d35c..0000000
--- a/sampler/config.py
+++ b/sampler/config.py
@@@ -1,4 -1,5 +1,11 @@@
  TEMPERATURE = 0.9
++<<<<<<< HEAD
 +TOP_P = 0.95
 +MAX_RETRIES = 2
 +MAX_TOKENS = 512
++=======
+ TOP_P = 0.9
+ MAX_RETRIES = 2
+ MAX_TOKENS = 512
+ SEED = 0
++>>>>>>> develop
$ git reset --merge
$ git status --short
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-weekly-sync/02-graph -->
```text
$ git log --graph --oneline --all
* 68ab086 Add a seeded random generator for reproducible runs
* ff1acee Lower the nucleus threshold to 0.9
* 5415495 Add a default output length
* cc2da95 Raise the default temperature to 0.9
* 864fdb8 Add nucleus sampling threshold
* c104ce5 Raise the default temperature to 0.8
| * e8a2031 Sync develop into main (week 37)
| * 14aadf8 Clamp the temperature to the range the model accepts
| * 8454cc3 Sync develop into main (week 36)
|/  
* d1a8f7e Add sampler
$ git log --oneline main..develop
68ab086 Add a seeded random generator for reproducible runs
ff1acee Lower the nucleus threshold to 0.9
5415495 Add a default output length
cc2da95 Raise the default temperature to 0.9
864fdb8 Add nucleus sampling threshold
c104ce5 Raise the default temperature to 0.8
$ git show -s --format="%h %s" "$(git merge-base main develop)"
d1a8f7e Add sampler
```
<!-- /snippet -->

The graph is the diagnosis. `main` and `develop` are two lines that separated at "Add sampler" and never met again. The merge base is still that first commit, and `main..develop` lists every commit of `develop`, as Ravi noticed.

<!-- snippet: ex1/solve-m06-weekly-sync/03-hypotheses -->
```text
# Hypothesis "the hotfix": which files did the only direct commit on main touch?
$ git log --oneline --no-merges --stat --author=Ravi main
14aadf8 Clamp the temperature to the range the model accepts
 sampler/sample.py | 1 +
 1 file changed, 1 insertion(+)
# Hypothesis "the syncs left no ancestry": how many parents do the sync commits have?
$ git log --format="%h parents: %p | %s" --grep=Sync main
e8a2031 parents: 14aadf8 | Sync develop into main (week 37)
8454cc3 parents: d1a8f7e | Sync develop into main (week 36)
```
<!-- /snippet -->

The hotfix touched `sampler/sample.py` only. The sync commits have one parent each: they are ordinary commits that happen to contain `develop`'s content.

**Reasoning.** The root cause, in the book's frame:

```text
Observed behavior : the weekly squash of develop into main conflicts in lines that main
                    never edited on its own, and the conflict region grows.
Git state         : merge base of main and develop = the commit where develop was created.
                    The sync commits on main have one parent.
Mechanism         : each sync is a three-way merge against that old base. To Git, main
                    "changed" every line that an earlier squash brought in, and develop changed
                    them too. Wherever develop has since edited such a line again, or a line
                    next to it, both sides differ from the base in different ways: a conflict.
Root cause        : syncing a long-lived branch by squash. A squash transfers content without
                    ancestry, so the merge base never advances.
Why Git does this : the merge base is computed from parent links, and a squash writes none.
Correct fix       : record the missing ancestry once, then sync by real merges.
Prevention        : never squash between two branches that both live on.
```

Which state of `develop` does `main` already contain? Compare each commit of `develop` with `main`:

<!-- snippet: ex1/solve-m06-weekly-sync/04-find-synced -->
```text
# Which develop commit does main already contain? Compare each one with main.
$ for c in $(git rev-list develop); do printf "%s  " "$(git log -1 --format="%h %s" $c)"; git diff --shortstat $c main | grep . || echo " identical"; done
68ab086 Add a seeded random generator for reproducible runs   2 files changed, 2 insertions(+), 6 deletions(-)
ff1acee Lower the nucleus threshold to 0.9   2 files changed, 2 insertions(+), 1 deletion(-)
5415495 Add a default output length   1 file changed, 1 insertion(+)
cc2da95 Raise the default temperature to 0.9   2 files changed, 2 insertions(+)
864fdb8 Add nucleus sampling threshold   2 files changed, 3 insertions(+), 1 deletion(-)
c104ce5 Raise the default temperature to 0.8   2 files changed, 4 insertions(+), 1 deletion(-)
d1a8f7e Add sampler   2 files changed, 4 insertions(+), 1 deletion(-)
$ git diff --stat 5415495 main
 sampler/sample.py | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

`main` differs from the commit "Add a default output length" by one line in `sampler/sample.py`: the hotfix. So `main` is that state of `develop` plus the hotfix, and everything up to that commit is content `main` already has.

<!-- snippet: ex1/solve-m06-weekly-sync/05-record -->
```text
$ git merge -s ours -m 'Record that main contains develop up to 5415495 (squash syncs of weeks 36 and 37)' 5415495
Merge made by the 'ours' strategy.
$ git diff --stat HEAD~1 HEAD
$ git show -s --format="%h %s" "$(git merge-base main develop)"
5415495 Add a default output length
$ git log --oneline main..develop
68ab086 Add a seeded random generator for reproducible runs
ff1acee Lower the nucleus threshold to 0.9
```
<!-- /snippet -->

`git merge -s ours <commit>` creates a merge commit whose tree is exactly `main`'s tree and whose second parent is the named commit. It changes no file (the diff against the previous `main` is empty) and states a fact that was verified a moment ago: `main` contains `develop` up to here. The merge base moves forward, and `main..develop` shrinks to this week's two commits.

<!-- snippet: ex1/solve-m06-weekly-sync/06-sync -->
```text
$ git merge -m "Sync develop into main (week 38)" develop
Auto-merging sampler/sample.py
Merge made by the 'ort' strategy.
 sampler/config.py | 3 ++-
 sampler/sample.py | 4 ++++
 2 files changed, 6 insertions(+), 1 deletion(-)
$ git log --graph --oneline -8
*   ac86f2b Sync develop into main (week 38)
|\  
| * 68ab086 Add a seeded random generator for reproducible runs
| * ff1acee Lower the nucleus threshold to 0.9
* | afe5848 Record that main contains develop up to 5415495 (squash syncs of weeks 36 and 37)
|\| 
| * 5415495 Add a default output length
| * cc2da95 Raise the default temperature to 0.9
| * 864fdb8 Add nucleus sampling threshold
| * c104ce5 Raise the default temperature to 0.8
$ git diff --stat develop main
 sampler/sample.py | 1 +
 1 file changed, 1 insertion(+)
$ cat sampler/config.py
TEMPERATURE = 0.9
TOP_P = 0.9
MAX_RETRIES = 2
MAX_TOKENS = 512
SEED = 0
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-weekly-sync/07-publish -->
```text
$ git push origin main
To ../server.git
   e8a2031..ac86f2b  main -> main
$ git log --oneline main..develop
$ git merge-base --is-ancestor develop main && echo "develop is contained in main"
develop is contained in main
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m06-weekly-sync/08-check -->
```text
$ cd ..
$ exercises/gen/m06-weekly-sync/check.sh
Checking exercise m06-weekly-sync
  ok    main on the server still contains its old history
  ok    develop on the server was not rewritten or moved
  ok    develop is an ancestor of main on the server: the next sync starts from here
  ok    sampler/config.py on main equals the one on develop
  ok    main still has the hotfix (the clamp)
  ok    main has the seeded generator of this week
  ok    no conflict marker is committed
  ok    your local main is what the server has
  ok    no merge is left in progress in your clone
  ok    your working tree is clean
PASS: exercise m06-weekly-sync is solved.
[exit status: 0]
```
<!-- /snippet -->

This week's merge is clean, `main` equals `develop` plus the hotfix, and `develop` is an ancestor of `main`. Next Friday's `git merge develop` will look at next week's commits only.

**Claims.**

| Claim | Verdict | Evidence |
|---|---|---|
| "Conflicts in lines nobody ever edited on `main`" | True, and the key symptom | the only non-sync commit on `main` touches another file |
| "It is Ravi's hotfix" | False | `git log --stat --author=Ravi main`: one line in `sampler/sample.py`; the conflicts are in `config.py` |
| "Revert the hotfix, sync, put it back" | Would not help | the base would still be the first commit |
| "Switch on rerere" | Beside the point | rerere replays a recorded resolution of the **same** conflict; here the conflict changes every week because `develop` moves on |
| "`main..develop` lists everything, as if the syncs never happened" | True, and the diagnosis | one-parent sync commits; merge base at "Add sampler" |

**Common mistakes.** Doing this week's squash and resolving by taking `develop`'s file, as in week 37: it works until the week in which `main` has a change of its own in that file, and then silently deletes it. Using `git merge -s ours develop` (the tip): that would declare this week's commits merged without taking their content, the fault of Exercise 6.7. Using `-s ours` without first proving, with `git diff`, that `main` contains the named state. Resolving one big real merge by hand is acceptable and passes the check; it costs more and has the same end state.

**Expert approach.** State the cause in one sentence a CTO can repeat: "we copied content between the branches without recording that we had, so Git re-litigates the whole history every week". Then change the runbook: on `main`, `git merge --no-ff develop`; hotfixes go to `main` and are merged back into `develop` the same day. If a linear `main` is a requirement, the answer is a different branching model, not a weekly squash.

**Reference.** Chapter 8, sections 8.2, 8.6, 8.12 (the root-cause box on squashing twice) and 8.19; Chapter 14C, section 14C.3 for what rerere records.

---

## Module 7: Remotes

### Solution 7.1: what a clone writes down about its remote

**Solution.**

<!-- snippet: ex1/ex-m07/e01-clone -->
```text
$ git init -q --bare server.git
$ git clone server.git you
Cloning into 'you'...
warning: You appear to have cloned an empty repository.
done.
$ cd you
$ printf 'TTL_SECONDS = 3600\n' > cache.py
$ git add cache.py
$ git commit -q -m "Add embedding cache settings"
$ git push -u origin main
To $LAB/ex1/ex-m07/m07-ex1/server.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m07/e01-config -->
```text
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
[remote "origin"]
	url = $LAB/ex1/ex-m07/m07-ex1/server.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
	remote = origin
	merge = refs/heads/main
$ git remote -v
origin	$LAB/ex1/ex-m07/m07-ex1/server.git (fetch)
origin	$LAB/ex1/ex-m07/m07-ex1/server.git (push)
$ git branch -vv
* main b87b199 [origin/main] Add embedding cache settings
$ git for-each-ref
b87b1996f46d3fe675ad1563a0dbbd9286236695 commit	refs/heads/main
b87b1996f46d3fe675ad1563a0dbbd9286236695 commit	refs/remotes/origin/main
```
<!-- /snippet -->

| Line | What it is | Written by | Read by |
|---|---|---|---|
| `[remote "origin"]` `url = ...` | where the other repository is | `git clone` | `fetch`, `pull`, `push`, `ls-remote` |
| `fetch = +refs/heads/*:refs/remotes/origin/*` | the fetch refspec | `git clone` | `git fetch` (and `pull`) |
| `[branch "main"]` `remote = origin` | the upstream's remote | `git push -u` | `status`, `pull`, `push`, `@{u}` |
| `merge = refs/heads/main` | the upstream's branch name **on the remote** | `git push -u` | the same |

The refspec says: take every branch of the remote (`refs/heads/*`, left side) and store it locally under `refs/remotes/origin/` with the same name (right side). The `+` allows the local remote-tracking ref to be updated even when that is not a fast-forward, which is what lets your clone follow a branch that was rewritten on the server.

Your commit moved `refs/heads/main`. The push moved the branch on the server and, because it succeeded, `refs/remotes/origin/main` in your clone.

**Reasoning.** A remote is three pieces of configuration: a name, a URL, a refspec. A remote-tracking branch is a local ref that records where a branch of the remote was when you last talked to it. The clone was made from an empty repository, so the `[branch "main"]` section appeared only with `git push -u`.

**Common mistakes.** Thinking `origin/main` is a live view of the server. Thinking `origin` is special: it is the default name `git clone` picks. Reading `merge = refs/heads/main` as a local ref: it names the branch in the remote's namespace.

**Expert approach.** When remote behavior surprises you, read these two sections first. Most "Git pushes to the wrong place" reports are a URL, a refspec or an upstream that says something other than the person assumes.

**Reference.** Chapter 12, sections 12.2, 12.3 and 12.5.

### Solution 7.2: fetch first, look, then integrate

**Solution.**

<!-- snippet: ex1/ex-m07/e02-teammate -->
```text
$ cd ..
$ git clone -q server.git asha
$ git -C asha commit -q --allow-empty -m "Asha: add eviction policy"
$ git -C asha push -q
$ cd you
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m07/e02-fetch -->
```text
$ git status -sb
## main...origin/main
$ git fetch
From $LAB/ex1/ex-m07/m07-ex1/server
   b87b199..9fa0195  main       -> origin/main
$ git status -sb
## main...origin/main [behind 1]
$ git log --oneline main..origin/main
9fa0195 Asha: add eviction policy
$ git merge --ff-only origin/main
Updating b87b199..9fa0195
Fast-forward
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

The first `git status -sb` compares the local `main` with the local ref `origin/main`. It contacts nobody. `origin/main` was last updated by your push, before Asha pushed, so "nothing to do" is true of your clone's knowledge and false of the server.

`git fetch` moved `refs/remotes/origin/main` and nothing else: not your branch, not the index, not the working tree. `git merge --ff-only origin/main` then moved `main`, and would have refused if `main` had commits of its own.

**Reasoning.** `git pull` is `git fetch` followed at once by an integration step. Splitting the two lets you look at `main..origin/main` in between and choose: fast-forward, merge, rebase, or nothing yet.

**Common mistakes.** Reading "up to date" as a statement about the server. Believing that `git fetch` can disturb your work: it only adds objects and moves remote-tracking refs. Pulling into a dirty working tree to "see what is new".

**Expert approach.** Fetch often, it is safe. Decide the integration deliberately. `git pull --ff-only` as the default for `main` gives the same guarantee in one command.

**Reference.** Chapter 12, sections 12.4 and 12.6.

### Solution 7.3: publish a branch, then delete it on the server

**Solution.**

<!-- snippet: ex1/ex-m07/e03-publish -->
```text
$ git switch -q -c feature/ttl
$ git commit -q --allow-empty -m "Make the TTL configurable"
$ git push -u origin feature/ttl
To $LAB/ex1/ex-m07/m07-ex1/server.git
 * [new branch]      feature/ttl -> feature/ttl
branch 'feature/ttl' set up to track 'origin/feature/ttl'.
$ git config get branch.feature/ttl.remote
origin
$ git config get branch.feature/ttl.merge
refs/heads/feature/ttl
$ git branch -vv
* feature/ttl 396ed76 [origin/feature/ttl] Make the TTL configurable
  main        9fa0195 [origin/main] Asha: add eviction policy
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m07/e03-delete -->
```text
$ git push origin --delete feature/ttl
To $LAB/ex1/ex-m07/m07-ex1/server.git
 - [deleted]         feature/ttl
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git branch -vv
* feature/ttl 396ed76 [origin/feature/ttl: gone] Make the TTL configurable
  main        9fa0195 [origin/main] Asha: add eviction policy
$ git ls-remote --heads origin
9fa0195d6bace4654e756589e6dfe76afb5a432b	refs/heads/main
```
<!-- /snippet -->

`-u` wrote the two `branch.feature/ttl.*` settings into `.git/config`: the upstream. After `git push origin --delete`:

- the branch on the server is gone (`git ls-remote` lists `main` only);
- the remote-tracking branch `origin/feature/ttl` is gone too, because the deleting push was made from this clone;
- the local branch `feature/ttl` still exists, with its commit. `gone` in `git branch -vv` says that its configured upstream no longer exists.

The commit is safe as long as the local branch exists.

**Reasoning.** Three refs with similar names in two repositories: the server's branch, your picture of it, and your own branch. Deleting one never deletes the others automatically, except that a push updates your picture of what it changed.

**Common mistakes.** Expecting `git branch -d` to delete the branch on the server, or the reverse. Reading `gone` as "my commits are gone". Expecting a teammate's clone to lose `origin/feature/ttl` at the same moment: theirs stays until they fetch with `--prune`.

**Expert approach.** Clean up in a fixed order after a merge: delete on the server, `git fetch --prune`, then delete local branches whose upstream is gone and which are merged. `fetch.prune=true` removes the middle step.

**Reference.** Chapter 12, sections 12.5, 12.7 and 12.11.

### Solution 7.4: what the clone knows before and after a fetch

**Solution.**

<!-- snippet: ex1/ex-m07/e04-answer-before -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To ../server.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m07/e04-answer-after -->
```text
$ git fetch -q
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git push
To ../server.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

Before the fetch: `[ahead 1]` and a rejection with `(fetch first)`. After the fetch: `[ahead 1, behind 1]` and a rejection with `(non-fast-forward)`.

**Reasoning.** The server refuses for the same reason both times: accepting your `main` would drop `B`. What differs is what your clone knows. Before the fetch your Git does not have the server's commit, so it can say only that "the remote contains work that you do not have locally". After the fetch your Git has `B`, can see for itself that your branch does not contain it, and reports that "the tip of your current branch is behind its remote counterpart".

**Common mistakes.** Treating the two messages as two different problems. Reading `[ahead 1]` as proof that a push will succeed. Answering either rejection with `--force`, which would delete Asha's commit from the server.

**Expert approach.** The parenthesis tells you the next step. `(fetch first)`: fetch and look. `(non-fast-forward)`: you have the commits, now integrate, by merge or by rebase according to the team's rule, and push again.

**Reference.** Chapter 12, sections 12.4 and 12.7.

### Solution 7.5: the same pull, by merge and by rebase

**Solution.**

<!-- snippet: ex1/ex-m07/e05-setup -->
```text
$ cd ..
$ cp -R you you-rebase
$ git -C you pull --no-rebase -q
$ git -C you-rebase pull --rebase -q
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m07/e05-answer -->
```text
$ git -C you log --graph --oneline
*   ac2634c Merge branch 'main' of ../server
|\  
| * 35256b6 Asha: B
* | 9f57d04 You: C
|/  
* eaa778c A
$ git -C you-rebase log --graph --oneline
* 09772cf You: C
* 35256b6 Asha: B
* eaa778c A
$ git -C you status -sb
## main...origin/main [ahead 2]
$ git -C you-rebase status -sb
## main...origin/main [ahead 1]
```
<!-- /snippet -->

```text
merge:    A---B-------M      main                rebase:   A---B---C'      main
           \         /
            C-------/
```

| | `pull --no-rebase` | `pull --rebase` |
|---|---|---|
| New objects | one merge commit | one commit, a copy of `C` on top of `B` |
| Your commit `C` | kept, same ID | replaced by a copy with a new ID |
| `git status -sb` | `[ahead 2]`: `C` and the merge | `[ahead 1]`: the copy |
| Next push sends | `C` and the merge commit | the copy of `C` |

**Reasoning.** Both start with the same fetch. The merge joins the two tips and keeps both histories as they happened. The rebase replays your commit on the fetched tip, so history reads as if you had started after Asha. Because `C` was never pushed, replacing it is harmless.

**Common mistakes.** Counting `[ahead 2]` as two pieces of work. Using `--rebase` on a branch whose commits others already have. Leaving the choice to whichever default a machine has: since Git 2.34 a diverged `git pull` without configuration stops with an error and asks you to choose.

**Expert approach.** Set `pull.rebase` or `pull.ff` deliberately (Chapter 14B, section 14B.5) and know the consequence for the shape of `main`. The remote URL was made relative in the setup for a reason: the merge message contains it, the message is part of the commit, and an absolute path would have given the merge commit a different ID on every machine.

**Reference.** Chapter 12, section 12.6; Chapter 9, section 9.13.

### Solution 7.6: which refs does a fetch move?

**Solution.**

<!-- snippet: ex1/ex-m07/e06-before -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/a
  origin/feature/b
  origin/main
$ git ls-remote origin
e3c8afe0cd125fff86bf18a3b4892e596026efe0	HEAD
1cf724f7372246f75a9ab3a9b8ee65d342900473	refs/heads/feature/b
6b4bfb3de07fb9208c0b183caca8db9d9383e2f4	refs/heads/feature/c
e3c8afe0cd125fff86bf18a3b4892e596026efe0	refs/heads/main
e3c8afe0cd125fff86bf18a3b4892e596026efe0	refs/tags/v1.0
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m07/e06-answer -->
```text
$ git fetch
From $LAB/ex1/ex-m07/m07-ex6/server
   cb7f705..e3c8afe  main       -> origin/main
 + efbc562...1cf724f feature/b  -> origin/feature/b  (forced update)
 * [new branch]      feature/c  -> origin/feature/c
 * [new tag]         v1.0       -> v1.0
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/a
  origin/feature/b
  origin/feature/c
  origin/main
$ git tag
v1.0
```
<!-- /snippet -->

1. Four lines. `main`: an ordinary fast-forward, shown as `old..new`. `feature/b`: a line that starts with `+` and ends with `(forced update)`, shown with three dots; the remote-tracking branch was moved to a commit that does not descend from its old value. `feature/c` and `v1.0`: lines that start with `*`, new refs.
2. `origin/feature/a` is **still listed**. A plain fetch updates and adds; it does not delete remote-tracking branches whose branch is gone on the server.
3. `git fetch --prune` removes it:

<!-- snippet: ex1/ex-m07/e06-prune -->
```text
$ git fetch --prune
From $LAB/ex1/ex-m07/m07-ex6/server
 - [deleted]         (none)     -> origin/feature/a
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/b
  origin/feature/c
  origin/main
```
<!-- /snippet -->

The `+` at the start of the fetch refspec (`+refs/heads/*:refs/remotes/origin/*`) is what allowed the non-fast-forward update of `origin/feature/b`.

**Reasoning.** A fetch makes your remote-tracking refs equal to the remote's branches, as far as the refspec reaches, with one exception: deletions, unless you ask for pruning. The tag arrived without being asked for because it points at a commit that was fetched anyway; that is the default tag-following behavior.

**Common mistakes.** Missing the `+` line in a long fetch output: it is the only notice you get that somebody rewrote a branch. Trusting `git branch -r` as a list of what exists on the server. Believing a fetch can rewrite your local `feature/b`: it moved `origin/feature/b` only.

**Expert approach.** Treat `(forced update)` as an event worth ten seconds: whose branch, was it expected, do I have work based on the old tip? The old tip is in the reflog of the remote-tracking branch (Exercise 9.10). `git ls-remote origin` is the way to see the server's refs without changing anything locally.

**Reference.** Chapter 12, sections 12.4, 12.11 and 12.12.

### Solution 7.7: the branch that this clone cannot see

**Solution.**

<!-- snippet: ex1/ex-m07/e07-diagnosis -->
```text
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
```
<!-- /snippet -->

1. The fetch refspec, printed by `git config get --all remote.origin.fetch`. It names one branch, `main`, where an ordinary clone has the wildcard. The fetch did exactly what it was told: it asked for `main`, found nothing new, and printed nothing.
2. `git clone --single-branch`. `--depth <n>` implies it, which is why CI checkouts are often of this kind.
3. For the one branch: `git remote set-branches --add origin feature/eviction`, then fetch. To make the clone ordinary:

<!-- snippet: ex1/ex-m07/e07-fix -->
```text
$ git remote set-branches origin '*'
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
$ git fetch
From $LAB/ex1/ex-m07/m07-ex7/server
 * [new branch]      feature/eviction -> origin/feature/eviction
$ git switch feature/eviction
Switched to a new branch 'feature/eviction'
branch 'feature/eviction' set up to track 'origin/feature/eviction'.
```
<!-- /snippet -->

**Reasoning.** `git ls-remote` asks the server and ignores the refspec, so it sees the branch. `git fetch` obeys the refspec. `git switch feature/eviction` looks for a local branch or a unique remote-tracking branch of that name, finds neither, and reports an invalid reference.

**Common mistakes.** Concluding that the branch does not exist or that permissions are wrong. Cloning again in full when one configuration line is the difference. Running `git fetch origin feature/eviction` and stopping there: it brings the commits into `FETCH_HEAD` and creates no remote-tracking branch, so the next fetch is blind again.

**Expert approach.** In CI, know how the checkout was made before debugging what is "missing": single branch, shallow, and detached are the usual three. The symptom "works on my machine, the branch is not found in CI" is this refspec in most cases.

**Reference.** Chapter 12, sections 12.3, 12.12 and 12.15.

### Solution 7.8: a push that the other side refuses

**Solution.**

<!-- snippet: ex1/ex-m07/e08-diagnosis -->
```text
$ git -C ../staging-box rev-parse --is-bare-repository
false
$ git -C ../staging-box branch --show-current
main
$ git -C ../staging-box config get receive.denyCurrentBranch
[exit status: 1]
# A branch that is not checked out there is accepted:
$ git push origin main:refs/heads/incoming/deploy-2
To $LAB/ex1/ex-m07/m07-ex8/staging-box
 * [new branch]      main -> incoming/deploy-2
```
<!-- /snippet -->

1. The remote is a **non-bare** repository: it has a working tree, and `main` is checked out there. `git rev-parse --is-bare-repository` on that side says `false`.
2. A push updates refs and adds objects. It does not touch the receiving repository's index or working tree. If the push moved `refs/heads/main` under a checked-out `main`, the files on the staging machine would still be the old ones while HEAD named the new commit: `git status` there would show the whole deployment as staged changes to undo it, and the next commit made there would revert what was pushed.
3. `receive.denyCurrentBranch`: `refuse` (the default, what happened here), `warn` and `ignore` (accept and leave the working tree stale), `updateInstead` (accept and update the working tree, only if it is clean). The config query printed nothing with status 1: the variable is unset, so the default applies. A branch that is not checked out is accepted, as the last command shows.

Two sound designs: push to a **bare** repository and let a deployment step check the files out elsewhere; or set `updateInstead` on a repository whose working tree nobody edits by hand. `ignore` is neither: it produces exactly the inconsistent state of point 2.

**Reasoning.** A bare repository exists to be pushed to: it has no working tree that could become inconsistent. A repository with a working tree is somebody's workplace, and Git protects it.

**Common mistakes.** Setting `ignore` because the message offers it. Force-pushing: force is about ancestry, not about this protection. Editing files by hand on the staging machine and then wondering why `updateInstead` refuses.

**Expert approach.** Deployment by push belongs to a bare repository plus an explicit checkout or, better, to a pipeline that builds an artifact from a commit ID. A working tree on a server is state that nobody reviews.

**Reference.** Chapter 12, sections 12.3 and 12.9.

### Solution 7.9: a clone that has not talked to the server for a week

**Solution.**

<!-- snippet: ex1/solve-m07-stale-clone/01-symptoms -->
```text
$ cd you
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To ../server.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git branch -vv
  feature/lru       ead4df9 [origin/feature/lru] Add LRU eviction
  feature/tokenizer 09097f4 [origin/main: ahead 3] Lowercase cache keys
* main              b8be5fa [origin/main: ahead 1] Cache embeddings for 24 hours
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m07-stale-clone/02-server -->
```text
# What the clone believes, and what the server says when asked.
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/remotes
d0cc28d refs/remotes/origin/HEAD
ead4df9 refs/remotes/origin/feature/lru
ca32ab0 refs/remotes/origin/feature/tokenizer
d0cc28d refs/remotes/origin/main
$ git ls-remote --heads origin | cut -c1-7,41-
ca32ab0	refs/heads/feature/tokenizer
33ea4bf	refs/heads/main
```
<!-- /snippet -->

| | The clone believes | The server has | Revealed by |
|---|---|---|---|
| `main` | `origin/main` at "Add embedding cache" | two commits more | `git ls-remote` against `git for-each-ref refs/remotes` |
| `feature/lru` | exists on the server | deleted | the same |
| `feature/tokenizer` | upstream is `origin/main` | a branch `feature/tokenizer` exists, one commit behind the local one | `git branch -vv` |

<!-- snippet: ex1/solve-m07-stale-clone/03-fetch -->
```text
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/feature/lru
   d0cc28d..33ea4bf  main       -> origin/main
$ git status -sb
## main...origin/main [ahead 1, behind 2]
$ git branch -vv
  feature/lru       ead4df9 [origin/feature/lru: gone] Add LRU eviction
  feature/tokenizer 09097f4 [origin/main: ahead 3, behind 2] Lowercase cache keys
* main              b8be5fa [origin/main: ahead 1, behind 2] Cache embeddings for 24 hours
$ git log --graph --oneline main origin/main
* b8be5fa Cache embeddings for 24 hours
| * 33ea4bf Evict at 10,000 entries
| * ead4df9 Add LRU eviction
|/  
* d0cc28d Add embedding cache
```
<!-- /snippet -->

**Symptom 1.** `main` had diverged from the server; the clone did not know until it fetched. The team wants a linear `main`, and the local commit is unpublished, so it is replayed on top:

<!-- snippet: ex1/solve-m07-stale-clone/04-main -->
```text
$ git rebase origin/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --graph --oneline main
* d5d0aa2 Cache embeddings for 24 hours
* 33ea4bf Evict at 10,000 entries
* ead4df9 Add LRU eviction
* d0cc28d Add embedding cache
$ git push
To ../server.git
   33ea4bf..d5d0aa2  main -> main
```
<!-- /snippet -->

**Symptom 2.** `feature/tokenizer` was created with `git switch -c feature/tokenizer origin/main`. Starting a branch from a remote-tracking branch makes that branch its upstream (`branch.autoSetupMerge`, default `true`). So status compared with `origin/main`, pull would have merged `main`, and push, under `push.default=simple`, refused because the upstream's name differs from the branch's name:

<!-- snippet: ex1/solve-m07-stale-clone/05-tokenizer -->
```text
$ git switch -q feature/tokenizer
$ git push
fatal: The upstream branch of your current branch does not match
the name of your current branch.  To push to the upstream branch
on the remote, use

    git push origin HEAD:main

To push to the branch of the same name on the remote, use

    git push origin HEAD

To choose either option permanently, see push.default in 'git help config'.

To avoid automatically configuring an upstream branch when its name
won't match the local branch, see option 'simple' of branch.autoSetupMerge
in 'git help config'.

[exit status: 128]
$ git log --oneline origin/feature/tokenizer..feature/tokenizer
09097f4 Lowercase cache keys
$ git branch --set-upstream-to=origin/feature/tokenizer
branch 'feature/tokenizer' set up to track 'origin/feature/tokenizer'.
$ git status -sb
## feature/tokenizer...origin/feature/tokenizer [ahead 1]
$ git push
To ../server.git
   ca32ab0..09097f4  feature/tokenizer -> feature/tokenizer
```
<!-- /snippet -->

The earlier push of two commits had worked because it named the branch explicitly (`git push origin feature/tokenizer`) and had not used `-u`.

**Symptom 3.** `git fetch --prune` removed `origin/feature/lru`. The local branch then shows `gone`, and its commit is contained in `main`, so `git branch -d` agrees to delete it:

<!-- snippet: ex1/solve-m07-stale-clone/06-gone -->
```text
$ git switch -q main
$ git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads
feature/lru [gone]
feature/tokenizer 
main 
$ git branch -d feature/lru
Deleted branch feature/lru (was ead4df9).
$ git branch -vv
  feature/tokenizer 09097f4 [origin/feature/tokenizer] Lowercase cache keys
* main              d5d0aa2 [origin/main] Cache embeddings for 24 hours
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m07-stale-clone/07-check -->
```text
$ cd ..
$ exercises/gen/m07-stale-clone/check.sh
Checking exercise m07-stale-clone
  ok    main on the server still contains what Asha pushed
  ok    the TTL commit is on the server main exactly once
  ok    no merge commit was added to main
  ok    the server main has the 24-hour TTL
  ok    your local main is what the server has
  ok    feature/tokenizer on the server has all three commits, unchanged
  ok    your local feature/tokenizer is unchanged
  ok    feature/tokenizer follows the remote origin
  ok    feature/tokenizer follows the branch of the same name
  ok    the stale remote-tracking branch origin/feature/lru is pruned
  ok    the local branch feature/lru is deleted
  ok    nothing is left in progress
  ok    your working tree is clean
PASS: exercise m07-stale-clone is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.** All three symptoms have one root: the clone's picture of the server was a week old, and one branch had the wrong upstream from its first minute. Nothing was broken on the server.

**Common mistakes.** `git pull` on `main` with default settings on a diverged branch: either the error of Git 2.34 and later, or, with `pull.rebase=false`, a merge commit that the team's rule forbids. Following the first suggestion of the fatal message, `git push origin HEAD:main`, which would have pushed the feature into `main`. Deleting `feature/lru` with `-D` before checking that its work is in `main`. Forgetting `--prune`.

**Expert approach.** After any absence: `git fetch --prune`, then `git branch -vv`, and read every bracket. Create feature branches from a remote-tracking branch with `--no-track`, or set `branch.autoSetupMerge=simple`, which the fatal message itself recommends, and publish with `git push -u`.

**Reference.** Chapter 12, sections 12.4 to 12.7 and 12.11; Chapter 9, section 9.13.

### Solution 7.10: the hotfix that was pushed and is not on the server

**Solution.** Start with the server, the only place whose state the release job saw:

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/01-server -->
```text
# The server first: it is the only place whose state the release job saw.
$ git -C server.git log --oneline release/2.4
44167a5 Prepare changelog for 2.4.1
5770f2a Release 2.4.0
d5588e3 Add embedding gateway
```
<!-- /snippet -->

The hotfix is not there, and Asha's commit sits directly on "Release 2.4.0".

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/02-ravi -->
```text
$ cd ravi
$ git status -sb
## release/2.4...origin/release/2.4 [ahead 1, behind 1]
$ git log --graph --oneline release/2.4 origin/release/2.4
* 44167a5 Prepare changelog for 2.4.1
| * a924154 Split embedding requests into batches of 96
|/  
* 5770f2a Release 2.4.0
* d5588e3 Add embedding gateway
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/03-reflog -->
```text
# Who moved the remote-tracking branch, and how? Its reflog names the operation.
$ git reflog show origin/release/2.4
44167a5 refs/remotes/origin/release/2.4@{0}: fetch: forced-update
a924154 refs/remotes/origin/release/2.4@{1}: update by push
# Did Asha rewrite anything? Her commit is a child of the commit both of them started from.
$ git log --format="%h %an: %s (parent %p)" -2 origin/release/2.4
44167a5 Asha Rao: Prepare changelog for 2.4.1 (parent 5770f2a)
5770f2a Asha Rao: Release 2.4.0 (parent d5588e3)
```
<!-- /snippet -->

The reflog of Ravi's remote-tracking branch has two entries. The older one, `update by push`, set it to the hotfix: Ravi's Git recorded that his push succeeded. The newer one, `fetch: forced-update`, set it to Asha's commit. Asha's commit has "Release 2.4.0" as its parent: it rewrites nothing. So the "forced update" is a statement about Ravi's local ref, which moved from a commit the server never had to the commit the server has.

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/04-where -->
```text
$ git remote -v
origin	../server.git (fetch)
origin	../old-server.git (push)
$ git config list --local --show-origin | grep remote.origin
file:.git/config	remote.origin.url=../server.git
file:.git/config	remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
file:.git/config	remote.origin.pushurl=../old-server.git
file:.git/config	branch.main.remote=origin
file:.git/config	branch.release/2.4.remote=origin
$ git ls-remote ../old-server.git release/2.4 | cut -c1-7,41-
a924154	refs/heads/release/2.4
$ git ls-remote origin release/2.4 | cut -c1-7,41-
44167a5	refs/heads/release/2.4
```
<!-- /snippet -->

The remote `origin` has two URLs: it fetches from `../server.git` and pushes to `../old-server.git`. The hotfix is on the old host.

**Reasoning.** The root cause, in the book's frame:

```text
Observed behavior : a push reports success; the commit is not on the server; a later fetch
                    reports "(forced update)".
Git state         : remote.origin.url = server.git, remote.origin.pushurl = old-server.git.
                    The hotfix is on old-server.git. origin/release/2.4 in Ravi's clone was set
                    to the hotfix by the push and back to the server's value by the fetch.
Mechanism         : a remote may have a separate push URL. After a successful push Git updates
                    the remote-tracking ref of that remote, on the assumption that the fetch URL
                    and the push URL are the same repository. Here they are not, so the ref
                    described a state that the fetch URL never had. The next fetch corrected it,
                    and since the correction was not a fast-forward it printed "forced update".
Root cause        : the migration script changed remote.origin.url and left an old
                    remote.origin.pushurl in place.
Why Git does this : pushurl exists for one repository reachable by two addresses. Git cannot
                    verify that two URLs lead to the same repository.
Correct fix       : remove the push URL; integrate the hotfix on top of the server's branch; push.
Prevention        : a migration check that compares git remote get-url with
                    git remote get-url --push, in every clone.
```

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/05-fix-remote -->
```text
$ git remote set-url --delete --push origin ../old-server.git
$ git remote -v
origin	../server.git (fetch)
origin	../server.git (push)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/06-integrate -->
```text
# The hotfix never reached the server, so it is still private there: replay it on top.
$ git rebase origin/release/2.4
Rebasing (1/1)
Successfully rebased and updated refs/heads/release/2.4.
$ git log --graph --oneline release/2.4
* 51fb785 Split embedding requests into batches of 96
* 44167a5 Prepare changelog for 2.4.1
* 5770f2a Release 2.4.0
* d5588e3 Add embedding gateway
$ git push
To ../server.git
   44167a5..51fb785  release/2.4 -> release/2.4
$ git status -sb
## release/2.4...origin/release/2.4
```
<!-- /snippet -->

The hotfix never reached the real server, so on that server it is unpublished and may be replayed on top of Asha's commit. The push is an ordinary fast-forward. Nothing is forced.

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/07-verify -->
```text
$ git ls-remote origin release/2.4 | cut -c1-7,41-
51fb785	refs/heads/release/2.4
$ git -C ../server.git log --oneline release/2.4
51fb785 Split embedding requests into batches of 96
44167a5 Prepare changelog for 2.4.1
5770f2a Release 2.4.0
d5588e3 Add embedding gateway
$ git -C ../server.git show release/2.4:gateway/embed.py
BATCH = 96

def embed(texts):
    out = []
    for i in range(0, len(texts), BATCH):
        out.extend(client.embed(texts[i:i + BATCH]))
    return out
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m07-hotfix-not-deployed/08-check -->
```text
$ cd ..
$ exercises/gen/m07-hotfix-not-deployed/check.sh
Checking exercise m07-hotfix-not-deployed
  ok    Asha's changelog commit is still in release/2.4 on the server
  ok    the hotfix is on the server release branch exactly once
  ok    the released code batches the requests
  ok    the changelog entry for 2.4.1 is still there
  ok    Ravi's clone pushes to the repository it fetches from
  ok    Ravi's fetch URL is still the company server
  ok    Ravi's local release/2.4 is what the server has
  ok    nothing further was pushed to the old host
  ok    nothing is left in progress in Ravi's clone
  ok    Ravi's working tree is clean
PASS: exercise m07-hotfix-not-deployed is solved.
[exit status: 0]
```
<!-- /snippet -->

**Claims.**

| Claim | Verdict | Evidence |
|---|---|---|
| Ravi: "It was pushed, the push printed `release/2.4 -> release/2.4`" | True, and to the wrong repository | `git ls-remote ../old-server.git` has the hotfix; `git remote -v` |
| Ravi: "`git status` said up to date with `origin/release/2.4`" | True of his local ref | reflog entry `update by push` |
| Ravi: "Somebody force-pushed the release branch" | False | Asha's commit is a child of the commit both started from; the "forced update" moved Ravi's remote-tracking ref only |
| Asha: "I pulled and there was no new commit" | True | the server never had the hotfix |
| Asha: "My push was a plain push, accepted without complaint" | True | a fast-forward on the server |
| The changelog for 2.4.1 | Wrong when it was written | the release was built without the batching |

**Common mistakes.** Believing the output of `git push` without looking at the `To` line, which names the repository. Hunting for a forced push on the server. "Restoring" the hotfix with `git push --force-with-lease`: the lease would even have passed, since Ravi's remote-tracking ref had been fetched a moment before, and Asha's commit would have been removed. Merging where the release line is kept linear. Fixing the branch and leaving the push URL in place for next time.

**Expert approach.** When a clone and a server disagree, ask the server directly (`git ls-remote`) and then explain the clone, never the reverse. The reflog of a remote-tracking branch names the operation behind each change (`update by push`, `fetch`, `fetch: forced-update`), which settles "who moved it" without any server log. Then tell the two people involved, in one message, that neither did anything wrong: the configuration did.

**Reference.** Chapter 12, sections 12.2, 12.7, 12.10 and 12.14; Chapter 13, section 13.10.

---

## Module 8: Undo

### Solution 8.1: take a commit back and make it again

**Solution.**

<!-- snippet: ex1/ex-m08/e01-soft -->
```text
$ git init -q eval-runner
$ cd eval-runner
$ printf 'def run(case):\n    return case.execute()\n' > runner.py
$ git add runner.py
$ git commit -q -m "Add runner"
$ printf 'def run(case):\n    return case.execute(timeout=30)\n' > runner.py
$ git commit -q -am "wip"
$ git reset --soft HEAD~1
$ git status --short
M  runner.py
$ git diff --cached --stat
 runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline
9bb4186 Add runner
$ git commit -q -m "Give every case a 30 second timeout"
$ git log --oneline
8beff14 Give every case a 30 second timeout
9bb4186 Add runner
$ git reflog -4
8beff14 HEAD@{0}: commit: Give every case a 30 second timeout
9bb4186 HEAD@{1}: reset: moving to HEAD~1
94fa44a HEAD@{2}: commit: wip
9bb4186 HEAD@{3}: commit (initial): Add runner
```
<!-- /snippet -->

Right after `git reset --soft HEAD~1`:

| Place | Holds |
|---|---|
| HEAD | still `ref: refs/heads/main` |
| branch `main` | the first commit, "Add runner" |
| index | the content of the commit `wip` (so the change shows as staged, `M `) |
| working tree | unchanged |

The commit `wip` is unreachable from `main` and still in the object database: the reflog line `HEAD@{2}: commit: wip` names it. `git commit --amend -m "Give every case a 30 second timeout"` would have produced the same final history in one step: an amend is a soft reset to the parent followed by a new commit.

**Reasoning.** `--soft` moves one thing, the branch ref. Because the index keeps the tree of the abandoned commit, a plain `git commit` re-creates its content under a new message and a new ID.

**Common mistakes.** Using 🔴 `--hard` to "undo the commit", which also discards the change. Believing the old commit is destroyed. Doing this to a commit that is already pushed (Exercise 8.7).

**Expert approach.** Pick the reset mode by asking where the change should end up: staged (`--soft`), in the working tree unstaged (`--mixed`), or nowhere (`--hard`, after a look at `git status`).

**Reference.** Chapter 11, sections 11.4 and 11.7.

### Solution 8.2: revert a commit that is not the last one

**Solution.**

<!-- snippet: ex1/ex-m08/e02-revert -->
```text
$ printf 'retries: 5\n' > retry.yaml
$ git add retry.yaml
$ git commit -q -m "Retry five times"
$ printf '# eval-runner\n' > README.md
$ git add README.md
$ git commit -q -m "Add README"
$ git revert --no-edit HEAD~1
[main f699194] Revert "Retry five times"
 Date: Mon Sep 7 10:22:00 2026 +0530
 1 file changed, 1 deletion(-)
 delete mode 100644 retry.yaml
$ git log --oneline
f699194 Revert "Retry five times"
6c72732 Add README
bc6d3cc Retry five times
8beff14 Give every case a 30 second timeout
9bb4186 Add runner
$ git show --stat --format="%s%n%n%b" HEAD
Revert "Retry five times"

This reverts commit bc6d3ccd58f5cd43fccc94cd0ab484d066f85f12.


 retry.yaml | 1 -
 1 file changed, 1 deletion(-)
$ ls
README.md
runner.py
```
<!-- /snippet -->

Four commits before, five after. The new commit applies the inverse of "Retry five times": it deletes `retry.yaml`. Its message records the title of the reverted commit and, in the body, its full ID. "Add README" is untouched.

**Reasoning.** A revert is a three-way merge in which the reverted commit is the base, its parent is "theirs" and HEAD is "ours": Git applies the change that leads from the commit back to its parent onto the current state. That works without help when later commits did not touch the same lines. Here the later commit added a different file. Had "Add README" edited `retry.yaml`, the revert would have stopped with a conflict.

**Common mistakes.** Expecting the reverted commit to disappear from the log. Expecting a revert to restore the whole project to the state before that commit: it undoes one commit's change and leaves everything later in place. Reverting the wrong direction of a range (Exercise 8.5).

**Expert approach.** A revert is the undo for shared history because it only adds a commit: everyone can pull it. Keep the generated message and add the reason and the ticket; the line "This reverts commit ..." is what tools and people search for (Exercise 8.10 shows what happens when it is removed).

**Reference.** Chapter 11, section 11.8.

### Solution 8.3: park an edit and bring it back

**Solution.**

<!-- snippet: ex1/ex-m08/e03-stash -->
```text
$ printf 'def run(case):\n    return case.execute(timeout=60)\n' > runner.py
$ git stash push -m "try a longer timeout"
Saved working directory and index state On main: try a longer timeout
$ git status --short
$ git stash list
stash@{0}: On main: try a longer timeout
$ git stash show -p
diff --git a/runner.py b/runner.py
index bdbd7b2..031b6a0 100644
--- a/runner.py
+++ b/runner.py
@@ -1,2 +1,2 @@
 def run(case):
-    return case.execute(timeout=30)
+    return case.execute(timeout=60)
$ git stash apply
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   runner.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git stash list
stash@{0}: On main: try a longer timeout
$ git stash drop
Dropped refs/stash@{0} (95c99ab8bcfcaac88e71e77cf820c282038f3654)
$ git status --short
 M runner.py
```
<!-- /snippet -->

While the working tree was clean, the edit was a commit that only `refs/stash` reaches. `git stash apply` brought the change back and **kept** the stash entry, as the second `git stash list` shows; `git stash pop` is `apply` followed by `drop`, when the apply succeeds. After the final `drop` nothing is lost: the edit is in the working tree.

Had you dropped before applying, the edit would have existed only as an unreachable commit, whose ID `git stash drop` prints. From that ID it can be recovered until garbage collection prunes unreachable objects, two weeks after their creation by default.

**Reasoning.** A stash is not a separate storage area. It is commits and one ref, with the stash list being that ref's reflog. Everything known about commits, reachability and expiry applies.

**Common mistakes.** Using the stash as long-term storage: entries have no branch, no review and vague names. Popping onto a different branch and being surprised by a conflict (after which the entry is kept). Forgetting that untracked files are not stashed without `-u`.

**Expert approach.** Always `push -m "<why>"`. If a stash is older than a day, turn it into a branch: `git stash branch <name>`.

**Reference.** Chapter 11, section 11.11; Chapter 14C, section 14C.2; Chapter 13, sections 13.4 and 13.9.

### Solution 8.4: `reset --keep`, twice

**Solution.** Part A:

<!-- snippet: ex1/ex-m08/e04-answer-a -->
```text
$ git reset --keep HEAD~1
[exit status: 0]
$ git status --short
 M b.txt
$ cat a.txt b.txt
a1
b2
$ git log --oneline
dded5a7 Base
```
<!-- /snippet -->

The reset succeeds. The branch moves back to "Base", `a.txt` returns to `a1`, and the uncommitted edit in `b.txt` is carried across untouched.

Part B:

<!-- snippet: ex1/ex-m08/e04-setup-b -->
```text
$ git reset -q --keep ORIG_HEAD
$ git log --oneline
f5c8fe6 Change a
dded5a7 Base
$ printf 'a3\n' > a.txt
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m08/e04-answer-b -->
```text
$ git reset --keep HEAD~1
error: Entry 'a.txt' not uptodate. Cannot merge.
fatal: Could not reset index file to revision 'HEAD~1'.
[exit status: 128]
$ git status --short
 M a.txt
 M b.txt
$ cat a.txt b.txt
a3
b2
$ git log --oneline
f5c8fe6 Change a
dded5a7 Base
```
<!-- /snippet -->

The reset is refused with status 128 and nothing changes: the branch still names "Change a", and both uncommitted edits are intact. `git reset --hard HEAD~1` would have moved the branch and overwritten both files without a word: `a3` and `b2` would be gone, and since neither was ever staged, no object would hold them.

**Reasoning.** `--keep` updates only the files that differ between the old and the new commit. If one of those files has a local modification, updating it would destroy the modification, so Git aborts before changing anything. It is the same rule that `git switch` applies (Exercise 4.7).

**Common mistakes.** Predicting that Part A fails because the tree is dirty. Reading the refusal in Part B as a malfunction and reaching for `--hard`. Assuming `--keep` preserves staged state: the index is reset, a staged change comes out unstaged.

**Expert approach.** Make `--keep` the reflex for "move this branch back" and reserve `--hard` for "and I have checked that nothing uncommitted matters". `ORIG_HEAD`, used in the setup of Part B, is the one-step way back after any reset.

**Reference.** Chapter 11, sections 11.5 and 11.6; Chapter 13, section 13.5.

### Solution 8.5: revert a range

**Solution.**

<!-- snippet: ex1/ex-m08/e05-setup -->
```text
$ git init -q revert-range
$ cd revert-range
$ printf 'a\n' > a.txt && git add a.txt && git commit -q -m 'Add a'
$ printf 'b\n' > b.txt && git add b.txt && git commit -q -m 'Add b'
$ printf 'c\n' > c.txt && git add c.txt && git commit -q -m 'Add c'
$ printf 'd\n' > d.txt && git add d.txt && git commit -q -m 'Add d'
$ git revert --no-edit HEAD~2..HEAD
[main b1ef7b1] Revert "Add d"
 Date: Mon Sep 7 11:01:00 2026 +0530
 1 file changed, 1 deletion(-)
 delete mode 100644 d.txt
[main 8cf6c7a] Revert "Add c"
 Date: Mon Sep 7 11:01:00 2026 +0530
 1 file changed, 1 deletion(-)
 delete mode 100644 c.txt
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m08/e05-answer -->
```text
$ git log --oneline
8cf6c7a Revert "Add c"
b1ef7b1 Revert "Add d"
5cf424a Add d
25b1a7d Add c
3c958a8 Add b
b90c5c4 Add a
$ ls
a.txt
b.txt
$ git diff --quiet HEAD~4 HEAD
[exit status: 0]
$ git rev-list --count HEAD
6
```
<!-- /snippet -->

Two new commits: `Revert "Add d"` first, then `Revert "Add c"` on top. The range `HEAD~2..HEAD` excludes its left end, so it means "Add c" and "Add d". `ls` shows `a.txt` and `b.txt`. Six commits in total. `git diff --quiet HEAD~4 HEAD` exits with 0: the tree is again the tree of "Add b".

**Reasoning.** Git reverts the newest commit of a range first. When commits build on each other, only that order applies cleanly: the inverse of the later change must come off before the inverse of the earlier one fits.

**Common mistakes.** Expecting one revert commit for the range: that needs `-n` and a commit of your own. Counting three reverted commits because the range has two dots and three names come to mind. Expecting the four original commits to be gone.

**Expert approach.** For "take the last N changes out of a shared branch", decide between N revert commits (each can be re-applied on its own later) and `git revert -n <range>` followed by one commit with a message that lists what was reverted and why. Either way, verify with `git diff <commit before the range> HEAD`.

**Reference.** Chapter 11, section 11.8.

### Solution 8.6: after a hard reset

**Solution.**

<!-- snippet: ex1/ex-m08/e06-answer -->
```text
$ git log --graph --oneline --all
* 1934a49 D
| * 9d73205 C
| * e1e0e71 B
|/  
* 1963bca A
$ git show -s --format=%s ORIG_HEAD
C
$ git reflog
1934a49 HEAD@{0}: commit: D
1963bca HEAD@{1}: reset: moving to HEAD~2
9d73205 HEAD@{2}: commit: C
e1e0e71 HEAD@{3}: commit: B
1963bca HEAD@{4}: commit (initial): A
```
<!-- /snippet -->

```text
      B---C        backup
     /
    A---D          main      (HEAD -> main)
```

`ORIG_HEAD` names `C`, the commit `main` pointed at before the reset. The commit `D` did not change it: `git commit` does not write `ORIG_HEAD`.

Without `backup`:

<!-- snippet: ex1/ex-m08/e06-without-backup -->
```text
$ git branch -q -D backup
$ git log --graph --oneline --all
* 1934a49 D
* 1963bca A
$ git show -s --format=%s ORIG_HEAD
C
$ git show -s --format=%s "main@{2}"
C
```
<!-- /snippet -->

The graph shows `A` and `D` only. `B` and `C` are not gone: they are in the object database, unreachable from any ref. `C` can still be named as `ORIG_HEAD` (until the next reset, merge, rebase or other command that writes that file) and as `main@{2}` or `HEAD@{2}` in the reflogs, for 30 days by default because no branch reaches it any more. `B` is reachable from `C`.

**Reasoning.** 🔴 `git reset --hard` moved the branch ref and overwrote index and working tree. It deleted no object. What it took away is the name, and names can be given back: `git branch rescue ORIG_HEAD`.

**Common mistakes.** Drawing `D` after `C`. Believing `--all` shows everything in the repository: it shows what refs reach. Relying on `ORIG_HEAD` hours later, after other commands have overwritten it.

**Expert approach.** The one-line habit before any history surgery, `git branch backup/<what>`, turns recovery from reflog archaeology into one command. Delete the backup when you are sure.

**Reference.** Chapter 11, sections 11.4 and 11.5; Chapter 13, sections 13.3 to 13.5 and 13.14.

### Solution 8.7: the commit that came back

**Solution.**

<!-- snippet: ex1/ex-m08/e07-diagnosis -->
```text
$ git reflog -4
714b287 HEAD@{0}: pull: Fast-forward
9a037bf HEAD@{1}: reset: moving to HEAD~1
714b287 HEAD@{2}: commit: Debug: let everything pass
9a037bf HEAD@{3}: commit (initial): Add pass mark
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

1. The reset moved the local `main` back by one commit. `origin/main` and the server still name the debugging commit. So the local branch is strictly **behind**: it has nothing the server lacks. The push was rejected as a non-fast-forward, because accepting it would mean moving the server's `main` backwards and dropping a commit.
2. `git pull` fetched nothing new and then integrated `origin/main` into `main`. Being strictly behind, `main` was fast-forwarded to `origin/main`: the reflog says `pull: Fast-forward`. Git did what a pull means. The commit had never left the server.
3. The commit is public, so the undo is a new commit:

<!-- snippet: ex1/ex-m08/e07-fix -->
```text
$ git revert --no-edit HEAD
[main 5ab1536] Revert "Debug: let everything pass"
 Date: Mon Sep 7 11:33:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To $LAB/ex1/ex-m08/m08-ex7/server.git
   714b287..5ab1536  main -> main
$ git log --oneline
5ab1536 Revert "Debug: let everything pass"
714b287 Debug: let everything pass
9a037bf Add pass mark
$ cat threshold.py
PASS_MARK = 0.7
```
<!-- /snippet -->

To make the reset stick the author would have had to rewrite the server's branch with 🔴 `git push --force-with-lease`. Every teammate who had pulled would then hold a commit that the server no longer has; their next pull or push would bring it back or diverge. That is the right call only when the commit must not exist in history at all (a secret, for example), and then it is an announced, coordinated operation, not a one-person fix.

**Reasoning.** `reset` edits your branch. It says nothing to the server. Whether a commit is "undone" for the team is decided by what the shared branch contains.

**Common mistakes.** Treating local history as the history. Following the pull hint without asking what it will merge. Forcing the push on a shared branch to win the argument with the server.

**Expert approach.** Ask the deciding question first: private or shared? `git status -sb` and `git log origin/main..main` answer it in two commands. Shared means revert.

**Reference.** Chapter 11, sections 11.2, 11.8 and 11.13; Chapter 12, section 12.7.

### Solution 8.8: what a hard reset took and what it left

**Solution.**

<!-- snippet: ex1/ex-m08/e08-setup -->
```text
$ git init -q lost
$ cd lost
$ printf 'def run(case):\n    return case.execute()\n' > runner.py
$ git add runner.py
$ git commit -q -m "Add runner"
$ mkdir eval
$ printf 'def f1(p, r):\n    return 2 * p * r / (p + r)\n' > eval/metrics.py
$ git add eval/metrics.py
$ printf 'ask Asha about macro F1\n' > notes.txt
$ printf 'def run(case):\n    return case.execute(timeout=30)\n' > runner.py
$ git status --short
A  eval/metrics.py
 M runner.py
?? notes.txt
$ git reset --hard
HEAD is now at 4344883 Add runner
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m08/e08-observed -->
```text
$ git status --short
?? notes.txt
$ ls
notes.txt
runner.py
$ cat runner.py
def run(case):
    return case.execute()
```
<!-- /snippet -->

1. `--hard` makes the index and the working tree equal to HEAD, for every path that is in the index or in HEAD.
   - `eval/metrics.py` (new, staged): it was in the index and not in HEAD, so it was removed from the index and from the working tree.
   - `runner.py` (tracked, edited, not staged): overwritten with the committed version.
   - `notes.txt` (never staged): unknown to the index and to HEAD, therefore untouched.
2. The staged file can be recovered. `git add` had written its content as a blob, and the reset removed the index entry, not the object:

<!-- snippet: ex1/ex-m08/e08-recover -->
```text
$ git fsck
dangling blob f2a905afa363fbf7e1e566647303d8a16ba8bc4d
$ git cat-file -p f2a905a
def f1(p, r):
    return 2 * p * r / (p + r)
$ mkdir -p eval && git cat-file -p f2a905a > eval/metrics.py
$ git status --short
?? eval/
?? notes.txt
```
<!-- /snippet -->

`git fsck` reports the blob as dangling; its content is the file. The name is lost (a blob has none), so you recognize it by content. With default settings the chance lasts until garbage collection prunes unreachable objects that are older than two weeks. The edit to `runner.py` cannot be recovered from Git: it was never staged, so it was never an object.

3. `git reset --keep` would have refused (the edited `runner.py` would have to be overwritten). `git stash` would have saved both tracked changes. `git status --short` shows in advance exactly what `--hard` is about to discard: every line that does not start with `??`.

**Reasoning.** Git can only give back what it was given. Committed work: reflog. Staged work: a dangling blob. Unstaged edits to tracked files: nothing. Untracked files are not touched by `reset` at all (their enemy is `git clean`).

**Common mistakes.** Believing that untracked files are deleted by `git reset --hard`. Believing that "new files" are safe: a new file that was staged is tracked from the index's point of view. Giving up on the staged file. Running `git gc --prune=now` "to clean up" before looking.

**Expert approach.** Before 🔴 `--hard`: read `git status --short`. After an accident: stop, do not run maintenance commands, and search with `git fsck --lost-found`, which also writes the dangling blobs out as files.

**Reference.** Chapter 11, section 11.5; Chapter 13, sections 13.6, 13.9 and 13.12.

### Solution 8.9: one bad commit that is public, one mixed commit that is not

**Solution.**

<!-- snippet: ex1/solve-m08-undo-mix/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main [ahead 1]
$ git log --oneline --stat
ac3b28e Update config and try new parser
 configs/grader.yaml | 2 +-
 grader/parser.py    | 6 +++++-
 2 files changed, 6 insertions(+), 2 deletions(-)
841a8da Add rubric loader
 grader/rubric.py | 2 ++
 1 file changed, 2 insertions(+)
9113c34 Lower the pass mark to 0.5
 grader/threshold.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
2f02d5f Add grader
 configs/grader.yaml | 1 +
 grader/parser.py    | 2 ++
 grader/threshold.py | 1 +
 3 files changed, 4 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-undo-mix/02-private -->
```text
# Which commits are private? Only what the server does not have.
$ git fetch
$ git log --oneline origin/main..main
ac3b28e Update config and try new parser
$ git log --oneline -S"PASS_MARK = 0.5" -- grader/threshold.py
9113c34 Lower the pass mark to 0.5
```
<!-- /snippet -->

`origin/main..main` holds one commit, the mixed one: private. The commit that lowered the pass mark is below `origin/main`: shared.

| Problem | Chosen | Rejected, and why |
|---|---|---|
| Mixed commit, private | `git reset HEAD~1` (mixed), then stage and commit the part that ships | `--soft`: both files would stay staged, one more step. 🔴 `--hard`: would destroy the experiment. `git revert`: would leave the mixed commit in history and remove the experiment from the working tree. |
| Bad commit, shared | `git revert <commit>` | `git reset` or an interactive rebase: both rewrite commits the server and three colleagues have. |

<!-- snippet: ex1/solve-m08-undo-mix/03-split -->
```text
# The mixed commit is private: take it back, keep its changes in the working tree.
$ git reset HEAD~1
Unstaged changes after reset:
M	configs/grader.yaml
M	grader/parser.py
$ git status --short
 M configs/grader.yaml
 M grader/parser.py
$ git add configs/grader.yaml
$ git commit -m "Raise the grader timeout to 60 seconds"
[main 7ab6008] Raise the grader timeout to 60 seconds
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short
 M grader/parser.py
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-undo-mix/04-revert -->
```text
# The bad commit is public: a new commit that applies its inverse.
$ git revert --no-edit 9113c34
[main 507a8f2] Revert "Lower the pass mark to 0.5"
 Date: Mon Sep 7 10:22:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short
 M grader/parser.py
$ git log --oneline
507a8f2 Revert "Lower the pass mark to 0.5"
7ab6008 Raise the grader timeout to 60 seconds
841a8da Add rubric loader
9113c34 Lower the pass mark to 0.5
2f02d5f Add grader
$ cat grader/threshold.py
PASS_MARK = 0.7
```
<!-- /snippet -->

The revert ran with an uncommitted change in the working tree. That is allowed because the index was clean and the revert does not touch `grader/parser.py`.

<!-- snippet: ex1/solve-m08-undo-mix/05-push -->
```text
$ git push
To ../server.git
   841a8da..507a8f2  main -> main
$ git status -sb
## main...origin/main
 M grader/parser.py
$ git diff --stat
 grader/parser.py | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-undo-mix/06-check -->
```text
$ cd ..
$ exercises/gen/m08-undo-mix/check.sh
Checking exercise m08-undo-mix
  ok    main on the server still contains every commit it had
  ok    the commit that lowered the pass mark is still in history
  ok    the pass mark on the server is 0.7
  ok    the timeout on the server is 60 seconds
  ok    the timeout change has its own commit with the requested title
  ok    that commit changes configs/grader.yaml and nothing else
  ok    the parser on the server is the original one
  ok    the mixed commit is on no branch of your clone
  ok    your local main is what the server has
  ok    the experiment is still in your working tree
  ok    the experiment is an unstaged modification, and the only change
PASS: exercise m08-undo-mix is solved.
[exit status: 0]
```
<!-- /snippet -->

State after each step:

| Step | Working tree | Index | HEAD | `main` | Server |
|---|---|---|---|---|---|
| `git reset HEAD~1` | both edits kept | reset to "Add rubric loader" | unchanged (names `main`) | back one commit | unchanged |
| `git add` + `git commit` | parser edit kept | config change committed | unchanged | new commit, timeout only | unchanged |
| `git revert` | parser edit kept; `threshold.py` back to 0.7 | matches the new commit | unchanged | one more commit | unchanged |
| `git push` | unchanged | unchanged | unchanged | unchanged | `main` fast-forwarded by two commits |

**Reasoning.** One repository, two kinds of history, two tools. The only question that chooses between `reset` and `revert` is whether anyone else can have the commit.

**Common mistakes.** Reverting the mixed commit. Resetting below `origin/main` to "remove" the bad commit (Exercise 8.7 shows how that ends). Committing with `git commit -a` after the reset, which re-creates the mixed commit. Stashing the experiment and forgetting to pop it.

**Expert approach.** Find the boundary with `git log origin/main..main` before choosing a tool, and say it aloud: "below this line I only add commits". Then verify on the server's side with `git ls-remote` or `git status -sb`, not from memory.

**Reference.** Chapter 11, sections 11.2, 11.4, 11.8, 11.12 and 11.13.

### Solution 8.10: a feature that was merged twice and is half missing

**Solution.**

<!-- snippet: ex1/solve-m08-missing-half/01-observe -->
```text
$ cd you
$ git ls-tree -r --name-only main
docs/batch-eval.md
runner/limits.py
runner/run.py
settings.yaml
$ git ls-tree -r --name-only origin/feature/batch-eval
docs/batch-eval.md
runner/batch.py
runner/limits.py
runner/parallel.py
runner/run.py
settings.yaml
$ git branch -r --merged origin/main
  origin/HEAD -> origin/main
  origin/feature/batch-eval
  origin/main
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-missing-half/02-graph -->
```text
$ git log --graph --oneline main
*   700132a Merge pull request #47 from feature/batch-eval
|\  
| * 15e554d Document batch evaluation
| * 7020281 Limit parallelism to four workers
* | 3462b9c Fix nightly: back out flaky batching
* | c3a1ce6 Raise the default timeout to 45 seconds
* | 0a1b5e5 Merge pull request #41 from feature/batch-eval
|\| 
| * e2b2766 Run batches in parallel
| * f4f8af2 Add batch splitter
|/  
* 8b53e29 Add evaluation runner
```
<!-- /snippet -->

The branch was merged twice. Between the two merges, on the first-parent line of `main`, sits Ravi's commit "Fix nightly: back out flaky batching". Find the commit that deleted the files without relying on a keyword:

<!-- snippet: ex1/solve-m08-missing-half/03-who-deleted -->
```text
# Which commit on the first-parent line of main deleted the file?
$ git log --first-parent --diff-filter=D --format="%h %an: %s" --name-status main -- runner
3462b9c Ravi Menon: Fix nightly: back out flaky batching

D	runner/batch.py
D	runner/parallel.py
$ git show --stat --format=fuller 3462b9c
commit 3462b9caf6d1731c7a352a4879167f0580987fd9
Author:     Ravi Menon <ravi@example.com>
AuthorDate: Mon Sep 7 10:18:00 2026 +0530
Commit:     Ravi Menon <ravi@example.com>
CommitDate: Mon Sep 7 10:19:00 2026 +0530

    Fix nightly: back out flaky batching

 runner/batch.py    | 2 --
 runner/parallel.py | 5 -----
 2 files changed, 7 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-missing-half/04-prove -->
```text
# A revert of a merge applies the inverse of the diff from the first parent of the merge.
$ git diff --stat 0a1b5e5^1 0a1b5e5
 runner/batch.py    | 2 ++
 runner/parallel.py | 5 +++++
 2 files changed, 7 insertions(+)
$ git diff --stat 3462b9c^ 3462b9c
 runner/batch.py    | 2 --
 runner/parallel.py | 5 -----
 2 files changed, 7 deletions(-)
# After it, runner/ is exactly what it was before pull request #41 was merged:
$ git diff --quiet 0a1b5e5^1 3462b9c -- runner
[exit status: 0]
```
<!-- /snippet -->

The commit removes exactly what the first merge added, and after it `runner/` is identical to its state before pull request #41: it is a revert of that merge (`git revert -m 1`), with its generated message replaced.

<!-- snippet: ex1/solve-m08-missing-half/05-why-clean -->
```text
$ git show -s --format='%h merged %p' 700132a
700132a merged 3462b9c 15e554d
$ git log --oneline 700132a^1..700132a^2
15e554d Document batch evaluation
7020281 Limit parallelism to four workers
$ git merge-base 700132a^1 700132a^2 | cut -c1-7
e2b2766
$ git merge origin/feature/batch-eval
Already up to date.
```
<!-- /snippet -->

**Reasoning.** The root cause, in the book's frame:

```text
Observed behavior : the second merge of a branch is clean and brings only its two newest
                    commits. The branch counts as merged. Two of its files are not in main.
Git state         : main contains merge #41, then a commit that reverts it, then merge #47.
Mechanism         : the revert removed the content of #41 and left its ancestry. For merge #47
                    the merge base was therefore the old tip of the feature, "Run batches in
                    parallel". Seen from that base, the feature added two files, and main had
                    deleted two other files that the feature had not touched since: no overlap,
                    no conflict, and the deletions stand. A third merge finds the feature tip
                    already among main's ancestors: "Already up to date".
Root cause        : a merge was reverted, and the branch was merged again without first
                    reverting the revert.
Why Git does this : a revert is an ordinary commit, a decision made on main. A later merge
                    respects main's decisions; it does not reopen changes that both sides
                    already have in their history.
Correct fix       : revert the revert.
Prevention        : the revert commit's message must say that it reverts a merge and how the
                    branch has to be brought back.
```

<!-- snippet: ex1/solve-m08-missing-half/06-repair -->
```text
$ git revert --no-edit 3462b9c
[main 843571e] Revert "Fix nightly: back out flaky batching"
 Date: Mon Sep 7 10:45:00 2026 +0530
 2 files changed, 7 insertions(+)
 create mode 100644 runner/batch.py
 create mode 100644 runner/parallel.py
$ git ls-tree -r --name-only main
docs/batch-eval.md
runner/batch.py
runner/limits.py
runner/parallel.py
runner/run.py
settings.yaml
$ git diff --stat origin/feature/batch-eval main
 settings.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-missing-half/07-publish -->
```text
$ git push
To ../server.git
   700132a..843571e  main -> main
$ git log --graph --oneline -4
* 843571e Revert "Fix nightly: back out flaky batching"
*   700132a Merge pull request #47 from feature/batch-eval
|\  
| * 15e554d Document batch evaluation
| * 7020281 Limit parallelism to four workers
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m08-missing-half/08-check -->
```text
$ cd ..
$ exercises/gen/m08-missing-half/check.sh
Checking exercise m08-missing-half
  ok    main on the server still contains every commit it had
  ok    runner/batch.py on main is the version of the feature branch
  ok    runner/parallel.py on main is the version of the feature branch
  ok    runner/limits.py on main is the version of the feature branch
  ok    docs/batch-eval.md on main is the version of the feature branch
  ok    the 45-second timeout of main is kept
  ok    the feature branch on the server was not moved
  ok    your local main is what the server has
  ok    nothing is left in progress in your clone
  ok    your working tree is clean
PASS: exercise m08-missing-half is solved.
[exit status: 0]
```
<!-- /snippet -->

After the repair `main` differs from the feature branch in `settings.yaml` only, which is `main`'s own later change.

**Claims.**

| Claim | Verdict | Evidence |
|---|---|---|
| Asha: "merged without a single conflict" | True, and explained by the merge base | `git merge-base` of the two parents of #47 |
| Asha: "Git says the branch is merged" | True: ancestry | `git branch -r --merged origin/main` |
| Asha: "Git lost half of my branch in a clean merge" | False | the files were removed by a commit on `main` before the second merge |
| Asha: "open a new pull request with the same branch?" | Would change nothing | `git merge` answers "Already up to date" |
| Ravi: "I fixed a flaky nightly once, that is all" | True, and it is the cause | that commit deletes the two files; it is the revert of #41 |
| Ravi: "nothing was resolved wrongly by hand" | True | neither merge had a conflict |
| "No commit has Revert in its title" | True, and why the search failed | the generated message was replaced |

The sentence that should have been in the message: "This reverts the merge of pull request #41 (feature/batch-eval). Before that branch is merged again, revert this commit first."

**Common mistakes.** Searching the log for "Revert" and concluding that nothing was reverted. Running `git log -- runner/batch.py` without `--first-parent` or `--full-history` and misreading the simplified history. Cherry-picking the two old commits: it produces the right files (and passes the check) but hides the story and duplicates commits; reverting the revert states what happened. Rewriting `main` to drop the revert.

**Expert approach.** When content is missing and ancestry says merged, list what happened to the path on the first-parent line: `git log --first-parent --diff-filter=D --name-status main -- <path>`. Identify commits by what they do, never by their titles.

> **GitHub, not Git.** The Revert button of a merged pull request creates a pull request with such a revert commit (Chapter 11, section 11.9). The re-merge problem is the same; the button keeps the generated title, which is one reason not to edit it away.

**Reference.** Chapter 11, sections 11.9 and 11.14; Chapter 14A, sections 14A.9 and 14A.13.

---

## Module 9: Rebase

### Solution 9.1: a plain rebase, before and after

**Solution.**

<!-- snippet: ex1/ex-m09/e01-rebase -->
```text
$ git switch -q feat/pii
$ git log --graph --oneline --all
* db70116 Add README
| * 2e834fd Treat an at-sign as PII
| * 403c006 Add PII rule
|/  
* d661561 Add rule engine
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/pii.
$ git log --graph --oneline --all
* cea8eed Treat an at-sign as PII
* 5514391 Add PII rule
* db70116 Add README
* d661561 Add rule engine
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m09/e01-compare -->
```text
$ git log --oneline ORIG_HEAD -2
2e834fd Treat an at-sign as PII
403c006 Add PII rule
$ git range-diff main ORIG_HEAD HEAD
1:  403c006 = 1:  5514391 Add PII rule
2:  2e834fd = 2:  cea8eed Treat an at-sign as PII
```
<!-- /snippet -->

Before: `feat/pii` forks from "Add rule engine" and `main` has one commit of its own. After: one line, with two **new** commits on top of "Add README". Their titles are the old ones, their IDs are not.

| Field | In the copies |
|---|---|
| tree | new: the old content plus `README.md` |
| parent | new: the tip of `main`, and the first copy |
| author, author date | kept |
| committer date | new: the time of the rebase |
| message | kept |

The two old commits are still in the object database, reachable through `ORIG_HEAD` and the reflogs, and from no branch. Each `git range-diff` line pairs an old commit with its copy; the `=` asserts that the two make the same change.

**Reasoning.** A rebase does not move commits. It replays each one as a new commit on a new base and then points the branch at the last copy. A commit's ID covers its parent, so a commit with another parent is another commit, even when its diff is identical.

**Common mistakes.** Saying the branch was "moved". Expecting the old IDs to survive because "nothing changed". Rebasing commits that others already have: for them the old commits are still the branch.

**Expert approach.** After every rebase, run `git range-diff <base> ORIG_HEAD HEAD`. Lines with `=` are what you want; `!` means a commit's change differs from before and deserves a look; `<` means a commit is gone.

**Reference.** Chapter 9, sections 9.2, 9.3 and 9.14.

### Solution 9.2: fold a fix into the commit it belongs to

**Solution.**

<!-- snippet: ex1/ex-m09/e02-fixup -->
```text
$ printf 'def has_pii(text):\n    return "@" in text or "+" in text\n' > pii.py
$ git commit -q -am "fix: phone numbers too"
$ git log --oneline main..HEAD
8c1387d fix: phone numbers too
cea8eed Treat an at-sign as PII
5514391 Add PII rule
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 5514391 # Add PII rule
pick cea8eed # Treat an at-sign as PII
pick 8c1387d # fix: phone numbers too
--- todo list as saved ---
pick 5514391 # Add PII rule
pick cea8eed # Treat an at-sign as PII
fixup 8c1387d # fix: phone numbers too
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/pii.
$ git log --oneline main..HEAD
3c2b373 Treat an at-sign as PII
5514391 Add PII rule
$ git show --stat --format=%s HEAD
Treat an at-sign as PII

 pii.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The third commit's change was melted into the second, and its message was thrown away. `fixup` and `squash` both combine a commit with the one before it; `squash` opens the editor with both messages so that you can write a combined one, `fixup` keeps the earlier message silently.

"Add PII rule" kept its ID: its parent, its tree and everything else are unchanged, and the base of the rebase is where it already sat, so Git did not need to re-create it. "Treat an at-sign as PII" has a new ID because its tree now includes the fix.

**Reasoning.** The todo list is a program. Every line from the first changed one downwards produces new commits; lines above it are reused as they are.

**Common mistakes.** Using `squash` and leaving "fix: phone numbers too" in the combined message. Putting `fixup` on the first line, where there is no earlier commit to fold into. Doing this to commits that are already in a reviewed pull request without telling the reviewers.

**Expert approach.** Let Git write the todo list: commit the fix with `git commit --fixup=<commit>` and rebase with `--autosquash`. The fix then finds its target by itself, also when it belongs five commits down.

**Reference.** Chapter 9, sections 9.6 and 9.7.

### Solution 9.3: a conflict, a look around, and the way back

**Solution.**

<!-- snippet: ex1/ex-m09/e03-conflict -->
```text
$ git rebase main
Rebasing (1/1)
Auto-merging limits.yaml
CONFLICT (content): Merge conflict in limits.yaml
error: could not apply 2eb85d8... Allow 500 characters
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 2eb85d8... # Allow 500 characters
[exit status: 1]
$ git status
interactive rebase in progress; onto 486f28d
Last command done (1 command done):
   pick 2eb85d8 # Allow 500 characters
No commands remaining.
You are currently rebasing branch 'feat/longer' on '486f28d'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   limits.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m09/e03-state -->
```text
$ git branch --show-current
$ git log --oneline -1
486f28d Allow 200 characters
$ ls .git/rebase-merge | sort | head -8
author-script
done
drop_redundant_commits
end
git-rebase-todo
git-rebase-todo.backup
head-name
interactive
$ cat .git/rebase-merge/head-name
refs/heads/feat/longer
$ cat limits.yaml
<<<<<<< HEAD
max_len: 200
=======
max_len: 500
>>>>>>> 2eb85d8 (Allow 500 characters)
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m09/e03-abort -->
```text
$ git rebase --abort
$ git status -sb
## feat/longer
$ git log --oneline -1
2eb85d8 Allow 500 characters
$ cat limits.yaml
max_len: 500
```
<!-- /snippet -->

While the rebase is stopped, HEAD is detached on the tip of `main` ("Allow 200 characters"), which is why `git branch --show-current` prints nothing. The branch being rebased is recorded in `.git/rebase-merge/head-name`; the ref `feat/longer` itself has not been touched and still names the original commit.

In the conflicted file the side labelled `HEAD` is **`main`'s** change (200), and the other side, labelled with the commit being replayed, is **your** change (500). In a merge started from `feat/longer`, `HEAD` would be your branch and the incoming side would be `main`. During a rebase "ours" is the new base and "theirs" is your own commit.

`git rebase --abort` checked out the original branch again and removed the state directory: same commit, same file, as if the rebase had never started.

**Reasoning.** The rebase builds the new history on a detached HEAD, starting from the upstream. Your commits are applied to it one by one, so from Git's point of view the upstream is the current side and your commit is the one coming in.

**Common mistakes.** Running `git checkout --ours` (or `git restore --ours`) to keep "my" version and thereby keeping `main`'s. Panicking at "HEAD detached" in the middle of a rebase. Using `git rebase --skip` to get past a conflict (Exercise 9.10 is that story).

**Expert approach.** In a stopped rebase read `git status` before anything else: it names the branch, the commit being applied, and the three ways on. Refer to the sides by commit, not by "ours" and "theirs".

**Reference.** Chapter 9, sections 9.4 and 9.11.

### Solution 9.4: the old commits and the new ones

**Solution.**

<!-- snippet: ex1/ex-m09/e04-answer -->
```text
$ git log --graph --oneline --all
* 1c3a0ad D
* 68c47e5 C
* f31c701 E
| * c2afc6e D
| * 3e4ad63 C
|/  
* b72a376 B
* 7eeff05 A
$ git branch --show-current
topic
$ git reflog show topic
1c3a0ad topic@{0}: rebase (finish): refs/heads/topic onto f31c7011e08ae3633ea7bf2c83f8285ae44bc8ab
c2afc6e topic@{1}: commit: D
3e4ad63 topic@{2}: commit: C
b72a376 topic@{3}: branch: Created from HEAD
```
<!-- /snippet -->

```text
            C---D            before          (the originals)
           /
  A---B---E---C'---D'        topic           (HEAD -> topic; the copies)
          ^
          main
```

1. `C` and `D` appear twice. The lower pair, on the side line, are the originals, kept visible by the branch `before`. The upper pair are the copies.
2. `topic`. The two-argument form `git rebase <upstream> <branch>` switches to `<branch>` first.
3. Without `before`, the original `C` and `D` would be missing from the picture. They would still be reachable through the reflog of `topic` (the entry before `rebase (finish)`), the reflog of HEAD, and `ORIG_HEAD`.

**Reasoning.** The rebase created two new commits and moved one ref. The originals did not change and were not deleted; whether you see them depends only on whether a ref still reaches them.

**Common mistakes.** Drawing `C` and `D` once. Expecting to be on `main` after the command. Believing the rebase "took" the commits away from the side line.

**Expert approach.** `git branch before <branch>` before a rebase is a free undo and a free comparison: `git range-diff main before topic` afterwards, then delete it.

**Reference.** Chapter 9, sections 9.2, 9.5 and 9.16.

### Solution 9.5: a commit that `main` already has

**Solution.**

<!-- snippet: ex1/ex-m09/e05-answer -->
```text
$ git rebase main
warning: skipped previously applied commit a26a726
hint: use --reapply-cherry-picks to include skipped commits
hint: Disable this message with "git config set advice.skippedCherryPicks false"
Rebasing (1/1)
Successfully rebased and updated refs/heads/feat/x.
$ git log --oneline main..feat/x
fc65a64 Add feature x
$ git log --graph --oneline --all
* fc65a64 Add feature x
* 976ecde Update core
* 31ad8cb Fix tokenizer crash
* 3d0a691 Add core
```
<!-- /snippet -->

One commit is replayed ("Add feature x"). For the other Git prints `warning: skipped previously applied commit` with its abbreviated ID, and a hint about `--reapply-cherry-picks`. Afterwards `main..feat/x` holds a single commit.

**Reasoning.** Before replaying, the rebase compares the commits of `main..feat/x` with the commits of `feat/x..main` by **patch ID**, a hash of each commit's diff with line numbers ignored. "Fix tokenizer crash" on the branch and its cherry-picked copy on `main` have different commit IDs and the same patch ID, so the branch's commit is left out.

**Common mistakes.** Predicting two replayed commits and a conflict or an empty commit. Believing Git matches by title or by commit ID. Relying on this for squash merges: a squash combines several diffs into one, its patch ID matches none of the originals, and nothing is skipped (Exercise 9.9).

**Expert approach.** Read the warning: it lists exactly what was dropped. If a "previously applied" commit must stay on the branch as its own commit, `--reapply-cherry-picks` keeps it.

**Reference.** Chapter 9, sections 9.3 and 9.12.

### Solution 9.6: a merge inside the branch

**Solution.** The starting state:

<!-- snippet: ex1/ex-m09/e06-setup -->
```text
$ git init -q flatten
$ cd flatten
$ git commit -q --allow-empty -m A
$ git switch -q -c topic
$ git commit -q --allow-empty -m B
$ git switch -q -c side
$ git commit -q --allow-empty -m C
$ git switch -q topic
$ git commit -q --allow-empty -m D
$ git merge -q --no-ff -m M side
$ git switch -q main
$ git commit -q --allow-empty -m E
$ git switch -q topic
$ git log --graph --oneline topic main
* 38f3230 E
| *   f71c916 M
| |\  
| | * 5fa85b1 C
| * | ba11d31 D
| |/  
| * a1d2b5c B
|/  
* 0d3add2 A
```
<!-- /snippet -->

After a plain rebase:

<!-- snippet: ex1/ex-m09/e06-answer-flat -->
```text
$ git rebase -q main
$ git log --graph --oneline topic main
* b1a1ebb C
* c869b4d D
* 6e8a8f6 B
* 38f3230 E
* 0d3add2 A
```
<!-- /snippet -->

The merge commit `M` is gone. The branch is a straight line on top of `E`, in the order `B`, `D`, `C`: the commits of the first-parent line, then the commit that came in through the merge.

With `--rebase-merges`:

<!-- snippet: ex1/ex-m09/e06-answer-merges -->
```text
$ git reset -q --hard ORIG_HEAD
$ git rebase -q --rebase-merges main
$ git log --graph --oneline topic main
*   6898eda M
|\  
| * 6e5e733 C
* | 57d8990 D
|/  
* fda1a73 B
* 38f3230 E
* 0d3add2 A
```
<!-- /snippet -->

The shape is preserved: `C` on a side line, joined to `D` by a merge `M`. It is not the same `M`: every commit of the branch, the merge included, is a new commit with a new ID.

**Reasoning.** By default a rebase takes the non-merge commits of the range and replays them as a list. A merge commit has no diff of its own to replay, so it is dropped, and if it carried a hand-made conflict resolution, that resolution is lost and the conflict comes back. `--rebase-merges` records the branch structure in the todo list and re-creates the merges.

**Common mistakes.** Expecting the default to keep merges. Expecting the linear order to be chronological. Reaching for `--preserve-merges` from old tutorials: the option was removed.

**Expert approach.** Know which of your branches contain merges before you rebase them, and check that `pull.rebase` is not flattening them silently: `git pull --rebase=merges` exists for that case.

**Reference.** Chapter 9, sections 9.10 and 9.13.

### Solution 9.7: a rebase that stopped at an `exec` line

**Solution.**

<!-- snippet: ex1/ex-m09/e07-where -->
```text
$ git log --oneline main..HEAD
10f9a70 Add rule three
57443ae Add rule two
$ git log --oneline main..feat/more-rules
e46595f Add rule four
b75b4a9 Add rule three
8246d35 Add rule two
$ cat .git/rebase-merge/git-rebase-todo | grep -v "^#" | grep .
pick e46595fe0aabcebf05fecdd3a4413bf7cfe2413e # Add rule four
exec sh ./check.sh
```
<!-- /snippet -->

1. Two commits have been rewritten: the copies of "Add rule two" and "Add rule three" are the two commits in `main..HEAD`. HEAD is detached on the copy of "Add rule three", the commit that fails the check. Still to run: `pick` "Add rule four" and its `exec`. The working tree is clean. The branch `feat/more-rules` still names the three original commits.
2. `--continue` goes on with the next instruction; the failed `exec` is not repeated. `--skip` is meant for a commit that stopped with a conflict; there is none to skip here. `--abort` returns to the original branch as it was. `--edit-todo` opens the list of remaining instructions.
3. Repair the commit Git stopped on, then continue:

<!-- snippet: ex1/ex-m09/e07-fix -->
```text
$ printf 'rule one\nrule two\nrule three\n' > rules.txt
$ git commit -q -a --amend --no-edit
$ git rebase --continue
Rebasing (5/6)
Auto-merging rules.txt
CONFLICT (content): Merge conflict in rules.txt
error: could not apply e46595f... Add rule four
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply e46595f... # Add rule four
[exit status: 1]
```
<!-- /snippet -->

The next commit conflicts. It was written on top of the faulty line, and the line is now different:

<!-- snippet: ex1/ex-m09/e07-finish -->
```text
# The next commit was written on top of the old rule three, so it conflicts with the repair.
$ git diff
diff --cc rules.txt
index b4c60bf,3ff2549..0000000
--- a/rules.txt
+++ b/rules.txt
@@@ -1,3 -1,4 +1,8 @@@
  rule one
  rule two
++<<<<<<< HEAD
 +rule three
++=======
+ rule three BUG
+ rule four
++>>>>>>> e46595f (Add rule four)
$ printf 'rule one\nrule two\nrule three\nrule four\n' > rules.txt
$ git add rules.txt
$ git rebase --continue
[detached HEAD afcab9e] Add rule four
 1 file changed, 1 insertion(+)
Rebasing (6/6)
Executing: sh ./check.sh
check passed
Successfully rebased and updated refs/heads/feat/more-rules.
$ git log --oneline main..feat/more-rules
afcab9e Add rule four
b56d063 Add rule three
57443ae Add rule two
$ cat rules.txt
rule one
rule two
rule three
rule four
```
<!-- /snippet -->

**Reasoning.** `git status` said "You are currently editing a commit": after a failed `exec` the rebase is paused **between** instructions, with HEAD on the last commit it created. `git commit --amend` there replaces that commit, exactly like the `edit` instruction. Every later commit is then replayed onto the repaired one, and a commit that touched the lines next to the repair has to be reconciled once.

**Common mistakes.** Running `--continue` without fixing anything: the rebase finishes, and the faulty commit stays in the branch, because the failed check is not run again. Fixing the file and continuing without committing: `--continue` refuses, and when the fix is staged it tells you to run `git commit --amend` if the change belongs to the previous commit. Adding a new commit "fix rule three" on the detached HEAD, which leaves a commit that fails the check in the history.

**Expert approach.** `git rebase --exec '<test command>' <base>` is how to prove that every commit of a branch passes, not only the last one, which is what makes the branch safe for `git bisect` later. When it stops, the commit under HEAD is the culprit.

**Reference.** Chapter 9, sections 9.4 and 9.6.

### Solution 9.8: the same conflict at every commit

**Solution.**

<!-- snippet: ex1/ex-m09/e08-count -->
```text
$ git rebase --abort
$ git log --oneline main..HEAD
bdd3f2a Settle on batch size 64
eef9d95 Try batch size 32
313ea24 Try batch size 16
$ git merge-tree --write-tree --name-only main HEAD | tail -n +2
train.yaml

Auto-merging train.yaml
CONFLICT (content): Merge conflict in train.yaml
```
<!-- /snippet -->

1. A rebase replays each commit separately, and each replay is a three-way merge of its own. All three commits change the line that `main` also changed, so each one conflicts. A merge compares three snapshots, base and two tips, whatever lies in between: one conflict. `git merge-tree --write-tree --name-only main HEAD` computes that merge without touching the working tree and reports one conflicted file.
2. Rerere would not help. It recognizes a conflict by its content, the two sides with the markers normalized. Here every conflict has a different incoming side (16, then 32, then 64), so each one is new to it.
3. The linear way: squash the three steps into one commit **where they are**, then rebase that one commit.

<!-- snippet: ex1/ex-m09/e08-squash-first -->
```text
# Squash the three steps on their old base first; then one commit meets main once.
$ git rebase -i --keep-base main
--- todo list as Git opened it (comment lines removed) ---
pick 313ea24 # Try batch size 16
pick eef9d95 # Try batch size 32
pick bdd3f2a # Settle on batch size 64
--- todo list as saved ---
pick 313ea24 # Try batch size 16
squash eef9d95 # Try batch size 32
squash bdd3f2a # Settle on batch size 64
Rebasing (2/3)
Rebasing (3/3)
[detached HEAD 88c5d99] Raise the batch size to 64
 Date: Mon Sep 7 12:04:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/feat/bigger-batches.
$ git log --oneline main..HEAD
88c5d99 Raise the batch size to 64
$ git rebase main
Rebasing (1/1)
Auto-merging train.yaml
CONFLICT (content): Merge conflict in train.yaml
error: could not apply 88c5d99... Raise the batch size to 64
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 88c5d99... # Raise the batch size to 64
[exit status: 1]
$ printf 'batch_size: 64  # needs the 48 GB cards\n' > train.yaml
$ git add train.yaml
$ git rebase --continue
[detached HEAD 5016d28] Raise the batch size to 64
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/feat/bigger-batches.
$ git log --graph --oneline --all
* 5016d28 Raise the batch size to 64
* ff0029f Explain the batch size
* 844d663 Add training config
```
<!-- /snippet -->

`git rebase -i --keep-base main` rewrites the branch on its current merge base: it lets you tidy without moving, so no conflict with `main` can arise in that step. The following `git rebase main` then conflicts once. The non-linear way is `git merge main` on the branch, or merging the branch into `main`: also one conflict, and the three steps stay in history.

**Reasoning.** The number of conflicts in a rebase depends on how many commits touch the contested lines; in a merge it depends only on the end states. Commits that are intermediate steps of one change ("try 16", "try 32") carry no value into `main` and cost a conflict each.

**Common mistakes.** Resolving all three by hand and making a different small mistake each time. Using `--skip` on the "unimportant" intermediate commits, which drops their other changes too. Squashing with `git rebase -i main`, which moves the branch first and runs into the conflicts it was meant to avoid.

**Expert approach.** Clean first, move second: `--keep-base` for the tidying, a plain rebase for the move, `git range-diff` after each. Which of merge and rebase to use is a team convention; the cost model above is what the convention should be based on.

**Reference.** Chapter 9, sections 9.5, 9.11 and 9.18; Chapter 8, section 8.17; Chapter 14C, section 14C.3.

### Solution 9.9: the morning rebase that replays somebody else's commits

**Solution.**

<!-- snippet: ex1/solve-m09-stacked-after-squash/01-state -->
```text
$ cd policy-engine
$ git status
interactive rebase in progress; onto 1dc809f
Last command done (1 command done):
   pick 5ed15be # Add PII rule skeleton
Next commands to do (4 remaining commands):
   pick 67b222c # Detect email addresses
   pick dab8d79 # Detect phone numbers
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feat/pii-redaction' on '1dc809f'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both added:      rules/pii.py

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m09-stacked-after-squash/02-todo -->
```text
$ cat .git/rebase-merge/done | grep -v "^#"
pick 5ed15be19f3710d4f7ea85f84f956fabffd1a89d # Add PII rule skeleton
$ cat .git/rebase-merge/git-rebase-todo | grep -v "^#" | grep .
pick 67b222c2ad1e977f755aabf70b9045a00073a03c # Detect email addresses
pick dab8d79111137311645bc75819aa51f842676643 # Detect phone numbers
pick 444ae3edd42356e8679ee96914ac7cf51733a6ba # Add redaction of matched spans
pick 58d61f249a5cb72a0d307c86625e3b9db811c796 # Redact email addresses in the audit log
$ cat .git/rebase-merge/head-name
refs/heads/feat/pii-redaction
```
<!-- /snippet -->

The stopped state says it all: one instruction done, four to go, five in total, and the first three are Asha's. Nothing of yours has been applied yet, so aborting loses nothing:

<!-- snippet: ex1/solve-m09-stacked-after-squash/03-abort -->
```text
$ git rebase --abort
$ git status -sb
## feat/pii-redaction
$ git log --graph --format="%h %an: %s" --all
* 1dc809f Asha Rao: Add PII rules (#12)
| * 58d61f2 Lab User: Redact email addresses in the audit log
| * 444ae3e Lab User: Add redaction of matched spans
| * dab8d79 Asha Rao: Detect phone numbers
| * 67b222c Asha Rao: Detect email addresses
| * 5ed15be Asha Rao: Add PII rule skeleton
|/  
* 2b4e028 Lab User: Add policy engine
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m09-stacked-after-squash/04-why -->
```text
$ git log --format="%h %an: %s" main..feat/pii-redaction
58d61f2 Lab User: Redact email addresses in the audit log
444ae3e Lab User: Add redaction of matched spans
dab8d79 Asha Rao: Detect phone numbers
67b222c Asha Rao: Detect email addresses
5ed15be Asha Rao: Add PII rule skeleton
$ git show --stat --format="%h %s (parents: %p)" main
1dc809f Add PII rules (#12) (parents: 2b4e028)

 rules/pii.py | 9 +++++++++
 1 file changed, 9 insertions(+)
# Is the squash commit recognized as a copy of the three commits? Compare patch IDs.
$ git cherry -v main feat/pii-redaction
+ 5ed15be19f3710d4f7ea85f84f956fabffd1a89d Add PII rule skeleton
+ 67b222c2ad1e977f755aabf70b9045a00073a03c Detect email addresses
+ dab8d79111137311645bc75819aa51f842676643 Detect phone numbers
+ 444ae3edd42356e8679ee96914ac7cf51733a6ba Add redaction of matched spans
+ 58d61f249a5cb72a0d307c86625e3b9db811c796 Redact email addresses in the audit log
```
<!-- /snippet -->

**Reasoning.**

```text
Observed behavior : "git rebase main" wants to replay five commits and conflicts in a file
                    you never edited.
Git state         : your branch = three commits of the old parent branch + your two.
                    main = one squash commit with the parent branch's content, slightly changed.
Mechanism         : "git rebase main" replays main..HEAD. The three old commits are not
                    ancestors of main (a squash records no ancestry), so they are in the range.
                    Their patch IDs match nothing on main (the squash is one combined diff, and
                    it was edited in review), so they are not skipped either. The first of them
                    adds a file that main already has with other content: "both added".
Root cause        : the branch was stacked on a branch that was squash-merged.
Why Git does this : a range is defined by reachability, and Git has no record that the squash
                    commit stands for those three commits.
Correct fix       : name the boundary yourself: git rebase --onto main <last commit of the
                    old parent branch>.
Prevention        : after a parent branch is squash-merged, restack its children with --onto
                    at once; or merge stacks bottom-up without squashing.
```

`git cherry -v main feat/pii-redaction` confirms it: all five commits carry a `+`, "no equivalent on `main`".

<!-- snippet: ex1/solve-m09-stacked-after-squash/05-onto -->
```text
# Replay only what is yours: everything after the last commit of the old parent branch.
$ git rebase --onto main dab8d79 feat/pii-redaction
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/pii-redaction.
$ git log --graph --format="%h %an: %s" --all
* 8efb589 Lab User: Redact email addresses in the audit log
* 1fe2672 Lab User: Add redaction of matched spans
* 1dc809f Asha Rao: Add PII rules (#12)
* 2b4e028 Lab User: Add policy engine
```
<!-- /snippet -->

The three arguments: `--onto main` is where the copies are built; `dab8d79` ("Detect phone numbers", Asha's last commit) is the boundary, excluded; `feat/pii-redaction` is the branch to rewrite. The replayed range is "after the boundary up to the branch tip": your two commits.

<!-- snippet: ex1/solve-m09-stacked-after-squash/06-verify -->
```text
$ git range-diff ORIG_HEAD~2..ORIG_HEAD main..HEAD
1:  444ae3e = 1:  1fe2672 Add redaction of matched spans
2:  58d61f2 = 2:  8efb589 Redact email addresses in the audit log
$ git diff --stat main HEAD
 audit_log.py | 5 +++++
 redact.py    | 4 ++++
 2 files changed, 9 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m09-stacked-after-squash/07-check -->
```text
$ cd ..
$ exercises/gen/m09-stacked-after-squash/check.sh
Checking exercise m09-stacked-after-squash
  ok    no rebase is in progress
  ok    HEAD is on feat/pii-redaction
  ok    main did not move
  ok    the branch starts at the tip of main
  ok    the branch has your two commits and nothing else, in order
  ok    redact.py is as you wrote it
  ok    audit_log.py is as you wrote it
  ok    rules/ and engine.py are exactly what main has
  ok    working tree and index are clean
PASS: exercise m09-stacked-after-squash is solved.
[exit status: 0]
```
<!-- /snippet -->

Both lines of the range-diff carry `=`: your two commits arrived with unchanged diffs.

**Common mistakes.** Resolving the conflicts of Asha's three commits one after the other: at best it ends with empty commits, at worst with her pre-review code reintroduced under your name. `git rebase --skip` three times: it happens to give the right result here and teaches a dangerous reflex. Picking the boundary by counting (`HEAD~2`) without looking: correct today, wrong the day you add a third commit. Starting over with a new branch and cherry-picks: valid, more typing, same result.

**Expert approach.** Stacked branches need the boundary written down, because the parent branch name disappears when it is merged. Before a parent is squash-merged, note its tip (`git rev-parse feat/pii-rules`) or tag it locally; `git rebase --onto main <that tip> <child>` is then mechanical.

> **GitHub, not Git.** "Squash and merge" is a platform merge method. The textbook quotes GitHub's own warning about continuing work on a branch after it was squash-merged (Chapter 9, section 9.5).

**Reference.** Chapter 9, sections 9.4, 9.5 (case 1), 9.12 and 9.14.

### Solution 9.10: "rebased onto main, no functional change"

**Solution.** The current state of the branch on the server:

<!-- snippet: ex1/solve-m09-vanished-guard/01-now -->
```text
$ cd you
$ git log --oneline origin/main..origin/feat/abuse-filter
22eca13 Add tests for the abuse filter
456bef4 Score messages against the word list
424b774 Add abuse word list
$ git show origin/feat/abuse-filter:api/moderate.py
from filters import abuse

def moderate(message):
    if len(message) > 10000:
        return {"allowed": False, "reason": "too long"}
    score = abuse.score(message)
    return {"allowed": score < 0.8}
```
<!-- /snippet -->

Three commits, and `moderate()` has no check for empty messages. Was there ever one? The server cannot say: it has only the current tip. Your clone can.

<!-- snippet: ex1/solve-m09-vanished-guard/02-old-tip -->
```text
# Your clone had the branch before the forced push and fetched it after. One reflog line, two IDs.
$ git reflog show origin/feat/abuse-filter
22eca13 refs/remotes/origin/feat/abuse-filter@{0}: fetch: forced-update
$ awk '{print "old " substr($1,1,7) "  new " substr($2,1,7)}' .git/logs/refs/remotes/origin/feat/abuse-filter
old 6043b88  new 22eca13
$ git log --oneline 'origin/feat/abuse-filter@{1}' -5
6043b88 Add tests for the abuse filter
daf6ae4 Reject empty messages before scoring
15dcf51 Score messages against the word list
2877869 Add abuse word list
aa364e0 Add moderation endpoint
```
<!-- /snippet -->

The reflog of your remote-tracking branch has a single line, written by this morning's fetch, and every reflog line stores two IDs: the value before and the value after. `origin/feat/abuse-filter@{1}` reads the "before" side, the old tip. It had **four** commits, and one of them is "Reject empty messages before scoring".

<!-- snippet: ex1/solve-m09-vanished-guard/03-range-diff -->
```text
$ git range-diff origin/main 'origin/feat/abuse-filter@{1}' origin/feat/abuse-filter
1:  2877869 = 1:  424b774 Add abuse word list
2:  15dcf51 = 2:  456bef4 Score messages against the word list
3:  daf6ae4 < -:  ------- Reject empty messages before scoring
4:  6043b88 = 3:  22eca13 Add tests for the abuse filter
```
<!-- /snippet -->

The line with `<` and no partner is the proof: a commit of the old series has no counterpart in the new one. The other three are `=`, unchanged.

<!-- snippet: ex1/solve-m09-vanished-guard/04-other-clones -->
```text
# Asha has not fetched: her remote-tracking branch is still the old tip.
$ git -C ../asha log --oneline -1 origin/feat/abuse-filter
6043b88 Add tests for the abuse filter
# Ravi's own reflog: the rebase picked three commits. No pick of the empty-message commit follows.
$ git -C ../ravi reflog -8
22eca13 HEAD@{0}: rebase (finish): returning to refs/heads/feat/abuse-filter
22eca13 HEAD@{1}: rebase (pick): Add tests for the abuse filter
456bef4 HEAD@{2}: rebase (pick): Score messages against the word list
424b774 HEAD@{3}: rebase (pick): Add abuse word list
5758157 HEAD@{4}: rebase (start): checkout origin/main
6043b88 HEAD@{5}: commit: Add tests for the abuse filter
daf6ae4 HEAD@{6}: commit: Reject empty messages before scoring
15dcf51 HEAD@{7}: commit: Score messages against the word list
```
<!-- /snippet -->

- **Asha's clone** has not fetched, so its `origin/feat/abuse-filter` is still the old tip, a second independent copy of the evidence.
- **Ravi's clone** has the old commits in its reflogs. His HEAD reflog shows the rebase: start, three picks, finish. The branch had four commits. No pick of "Reject empty messages before scoring" follows the second one.
- **The server** is a bare repository without reflogs and holds only the new tip.

<!-- snippet: ex1/solve-m09-vanished-guard/05-not-main -->
```text
# Did the commit on main remove the check? It never had it.
$ git log --oneline -S"message.strip()" --all
$ git show --format="%h %an: %s" origin/main -- api/moderate.py
5758157 Asha Rao: Reject messages longer than 10,000 characters

diff --git a/api/moderate.py b/api/moderate.py
index 48b458a..ad5e95e 100644
--- a/api/moderate.py
+++ b/api/moderate.py
@@ -1,5 +1,7 @@
 from filters import abuse
 
 def moderate(message):
+    if len(message) > 10000:
+        return {"allowed": False, "reason": "too long"}
     score = abuse.score(message)
     return {"allowed": score < 0.8}
```
<!-- /snippet -->

The commit on `main` added the length check and removed nothing. The text `message.strip()` exists in no commit that any ref of this clone reaches.

**Reasoning.** The root cause, in the book's frame:

```text
Observed behavior : after a rebase and a forced push, a reviewed change is not in the branch.
Git state         : old tip: four commits. New tip: three. The missing one edits the same
                    place in api/moderate.py as a new commit on main.
Mechanism         : the rebase stopped with a conflict at that commit. The hint offers three
                    ways on; "git rebase --skip" drops the commit being applied and continues.
                    The remaining commit applied cleanly, so the rebase "succeeded".
                    --force-with-lease then replaced the branch on the server: the lease
                    protects against overwriting other people's pushes, not against publishing
                    a rewrite that lost something.
Root cause        : a conflict was skipped instead of resolved, and the rewritten series was
                    published without being compared with the old one.
Why Git does this : --skip is a legitimate instruction ("this commit is not wanted").
                    Git cannot know that it was a misunderstanding.
Correct fix       : bring the commit back on top of the current branch; resolve the conflict
                    it had; push as a fast-forward.
Prevention        : git range-diff before every forced push; reviewers compare the old and
                    the new series after a force-push.
```

`--skip` is the most probable command. The evidence is indirect: no pick of that commit in Ravi's reflog, a conflict that Ravi remembers, and the fact that applying the commit to the new base conflicts, as the next step shows. Removing the line from an interactive todo list would leave the same traces.

**Repair.** The branch has review comments on its current commits, so it is not rewritten again. The lost commit is added on top:

<!-- snippet: ex1/solve-m09-vanished-guard/06-pick -->
```text
$ git switch feat/abuse-filter
Switched to a new branch 'feat/abuse-filter'
branch 'feat/abuse-filter' set up to track 'origin/feat/abuse-filter'.
$ git cherry-pick -x daf6ae4
Auto-merging api/moderate.py
CONFLICT (content): Merge conflict in api/moderate.py
error: could not apply daf6ae4... Reject empty messages before scoring
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ git diff
diff --cc api/moderate.py
index ad5e95e,9b65229..0000000
--- a/api/moderate.py
+++ b/api/moderate.py
@@@ -1,7 -1,7 +1,12 @@@
  from filters import abuse
  
  def moderate(message):
++<<<<<<< HEAD
 +    if len(message) > 10000:
 +        return {"allowed": False, "reason": "too long"}
++=======
+     if not message.strip():
+         return {"allowed": False, "reason": "empty"}
++>>>>>>> daf6ae4 (Reject empty messages before scoring)
      score = abuse.score(message)
      return {"allowed": score < 0.8}
```
<!-- /snippet -->

This is the conflict Ravi faced. Both sides inserted a check at the top of the function. The resolution keeps both, the cheap length check first:

<!-- snippet: ex1/solve-m09-vanished-guard/07-resolve -->
```text
$ printf 'from filters import abuse\n\ndef moderate(message):\n    if len(message) > 10000:\n        return {"allowed": False, "reason": "too long"}\n    if not message.strip():\n        return {"allowed": False, "reason": "empty"}\n    score = abuse.score(message)\n    return {"allowed": score < 0.8}\n' > api/moderate.py
$ git add api/moderate.py
$ git cherry-pick --continue
[feat/abuse-filter 7b6f2f2] Reject empty messages before scoring
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git log --oneline origin/main..HEAD
7b6f2f2 Reject empty messages before scoring
22eca13 Add tests for the abuse filter
456bef4 Score messages against the word list
424b774 Add abuse word list
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m09-vanished-guard/08-publish -->
```text
$ git push
To ../server.git
   22eca13..7b6f2f2  feat/abuse-filter -> feat/abuse-filter
$ git range-diff origin/main 'origin/feat/abuse-filter@{2}' origin/feat/abuse-filter
1:  2877869 = 1:  424b774 Add abuse word list
2:  15dcf51 = 2:  456bef4 Score messages against the word list
3:  daf6ae4 < -:  ------- Reject empty messages before scoring
4:  6043b88 = 3:  22eca13 Add tests for the abuse filter
-:  ------- > 4:  7b6f2f2 Reject empty messages before scoring
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m09-vanished-guard/09-check -->
```text
$ cd ..
$ exercises/gen/m09-vanished-guard/check.sh
Checking exercise m09-vanished-guard
  ok    the branch on the server was not rewritten again
  ok    the lost change is on the branch exactly once
  ok    the endpoint rejects empty messages
  ok    the endpoint still rejects messages that are too long
  ok    the scoring call is still there, once
  ok    no conflict marker is committed
  ok    the branch still contains the current main
  ok    your local branch is what the server has
  ok    nothing is left in progress in your clone
  ok    your working tree is clean
PASS: exercise m09-vanished-guard is solved.
[exit status: 0]
```
<!-- /snippet -->

The push is a fast-forward. The final range-diff tells the story honestly: commit 3 of the old series disappeared and a commit with the same title was added at the end.

**Claims.**

| Claim | Verdict | Evidence |
|---|---|---|
| Asha: "there was a check for empty messages" | True | the old tip in your reflog and in her stale `origin/feat/abuse-filter` |
| PR description: "no functional change" | False | `git range-diff`: one commit `<` |
| Ravi: "a rebase replays every commit, it cannot lose one" | False | it replays every commit of the todo list unless one is skipped or dropped |
| Ravi: "Git told me how to get past the conflict and I did" | True, and the cause | the hint lists `--skip` next to resolving |
| Ravi: "look at what went into `main`" | False lead | that commit only adds lines; pickaxe finds the check in no reachable commit |
| Ravi: "pushed with `--force-with-lease` as the handbook says" | True, and no protection here | the lease checks the remote's old value, not the content of the rewrite |

**Common mistakes.** Rebasing or resetting the branch back to the old tip and force-pushing again: the review comments are attached to the current commits, and a second rewrite doubles the confusion. Re-typing the check from memory instead of recovering the reviewed commit. Looking for a "skip" entry in the reflog and concluding nothing happened when there is none. Fetching in Asha's clone before recording her old remote-tracking value, which destroys one copy of the evidence (her reflog would still have it, as yours did).

**Expert approach.** Evidence first, in the order of how quickly it is lost: remote-tracking reflogs and unfetched clones before anything else. Anchor the old tip (`git branch rescue/abuse-filter-old 'origin/feat/abuse-filter@{1}'`) before repairing. For prevention, run `git range-diff main ORIG_HEAD HEAD` right after every rebase, before `git push --force-with-lease --force-if-includes`, and ask reviewers to compare the old and the new series of a force-pushed pull request before they approve again.

**Reference.** Chapter 9, sections 9.11, 9.14, 9.16 and 9.17; Chapter 13, sections 13.3 and 13.10; Chapter 10, section 10.7.

---

## Module 10: Cherry-pick and ranges

### Solution 10.1: one commit, copied to another branch

**Solution.**

<!-- snippet: ex1/ex-m10/e01-pick -->
```text
$ git switch -q release/1.0
$ git cherry-pick main
[release/1.0 a24776d] Return an empty list for empty input
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --graph --oneline --all
* a24776d Return an empty list for empty input
| * b8057dd Return an empty list for empty input
| * fde97d3 Add vocabulary file
|/  
* 7504b97 Add whitespace tokenizer
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m10/e01-compare -->
```text
$ git log -1 --format='%h  author %an %ad  |  committer %cd' --date=format:%H:%M main
b8057dd  author Lab User 10:12  |  committer 10:12
$ git log -1 --format='%h  author %an %ad  |  committer %cd' --date=format:%H:%M release/1.0
a24776d  author Lab User 10:12  |  committer 10:14
$ git range-diff main^! release/1.0^!
1:  b8057dd = 1:  a24776d Return an empty list for empty input
$ ls
tokenizer.py
```
<!-- /snippet -->

The two commits share the message, the author and the author date. They differ in parent, tree, committer date, and therefore ID. `release/1.0` has no `vocab.txt`, because a cherry-pick transfers the **change** of one commit, not the state it was made in: the change of "Return an empty list for empty input" touches `tokenizer.py` only.

The `=` in the range-diff asserts that the two commits make the same change. The merge base that Git used for this cherry-pick is the **parent of the picked commit** ("Add vocabulary file"): base is that parent, theirs is the picked commit, ours is the release branch.

**Reasoning.** A cherry-pick is a three-way merge with an unusual base. The difference between base and theirs is exactly the picked commit's diff, and that is what gets merged into your branch. Whatever else the base contains, such as the vocabulary file, is on both sides of that comparison and cancels out.

**Common mistakes.** Saying the commit was "moved" or is now "on both branches": there are two commits. Expecting the picked commit to bring its ancestors along. Expecting `git branch --contains <original>` to list the release branch afterwards (Exercise 10.10).

**Expert approach.** Add `-x` whenever the copy goes to a branch that others see. The original ID in the message is the only durable link between the two commits.

**Reference.** Chapter 10, sections 10.2 and 10.3.

### Solution 10.2: names for commits

**Solution.**

<!-- snippet: ex1/ex-m10/e02-graph -->
```text
$ git log --graph --oneline
* 0a9caa4 Add d
*   7edd1f8 Merge side
|\  
| * f2ba147 Add s2
| * a958118 Add s1
* | 65ccec9 Add c
|/  
* dd77deb Add b
* 889001c Add a
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m10/e02-selectors -->
```text
$ git show -s --format=%s HEAD~1
Merge side
$ git show -s --format=%s HEAD~2
Add c
$ git show -s --format=%s 'HEAD~1^2'
Add s2
$ git show -s --format=%s 'HEAD~1^2~1'
Add s1
$ git show -s --format=%s 'HEAD^^^'
Add b
$ git show -s --format=%s ':/Add s'
Add s2
$ git show -s --format=%s 'main@{1}'
Merge side
$ git cat-file -t 'HEAD^{tree}'
tree
$ git cat-file -p HEAD~1:s2.txt
s2
```
<!-- /snippet -->

| Expression | Names | How to read it |
|---|---|---|
| `HEAD~1` | Merge side | one step along the first parent |
| `HEAD~2` | Add c | two steps along first parents: the merge, then its first parent |
| `HEAD~1^2` | Add s2 | the second parent of the merge: the tip of `side` |
| `HEAD~1^2~1` | Add s1 | from there one step back |
| `HEAD^^^` | Add b | three times "first parent", the same as `HEAD~3` |
| `:/Add s` | Add s2 | the youngest commit, reachable from any ref, whose message matches |
| `main@{1}` | Merge side | where `main` pointed one move ago, from the reflog |

`HEAD^{tree}` names a tree object, the snapshot of the commit. `HEAD~1:s2.txt` names a blob, the file as it is in that commit. `main@{1}` reads the reflog: in a fresh clone the reflog starts at the clone, so the expression is an error or names something else.

**Reasoning.** `~` always follows first parents. `^n` picks a parent, and only merges have more than one. The two can be chained, read from left to right. `:/text` and `@{n}` are searches, not paths through the graph: one searches messages, the other the local reflog.

**Common mistakes.** Reading `HEAD~2` as "Add s2" because it is two lines down in the log output. Using `:/text` in scripts: the match depends on which commits exist today. Using `@{n}` in instructions for other people: their reflog differs from yours.

**Expert approach.** For anything that will be read later or run elsewhere, resolve the expression to an ID with `git rev-parse` and quote the ID.

**Reference.** Chapter 14A, section 14A.7; Chapter 3, section 3.6.

### Solution 10.3: two commits picked as one

**Solution.**

<!-- snippet: ex1/ex-m10/e03-no-commit -->
```text
$ git switch -q main
$ printf 'LOWERCASE = False\n' > options.py
$ git add options.py
$ git commit -q -m "Add lowercase option"
$ printf '# tokenlab\n\nSet LOWERCASE in options.py to fold case.\n' > README.md
$ git add README.md
$ git commit -q -m "Document the lowercase option"
$ git switch -q release/1.0
$ git cherry-pick -n main~1 main
$ git status --short
A  README.md
A  options.py
$ git log --oneline -1
a24776d Return an empty list for empty input
$ git commit -q -m "Backport the lowercase option and its documentation"
$ git show --stat --format="%h %s" HEAD
fd496e3 Backport the lowercase option and its documentation

 README.md  | 3 +++
 options.py | 1 +
 2 files changed, 4 insertions(+)
```
<!-- /snippet -->

With `-n` (`--no-commit`) each pick is applied to the index and the working tree, and no commit is made: the branch does not move, and both changes end up staged together. One `git commit` then records them as a single new commit.

What is lost: the one-to-one correspondence with the commits on `main`. There are no per-commit messages, no `(cherry picked from commit ...)` lines, and `git cherry` cannot pair the combined commit with either original, because its diff equals neither. That is acceptable when the release branch needs "this behavior" and nobody will ever ask "is commit X in the release?", for example for a small feature and its documentation.

**Reasoning.** `-n` turns cherry-pick into "apply this change here and let me decide what to commit". It is the tool for combining, trimming or adapting changes.

**Common mistakes.** Using `-n` for backports that must be traceable. Forgetting that with `-n` the author of the new commit is you, not the original author. Running it on a dirty index, which mixes your staged work into the result.

**Expert approach.** State the origin by hand in the message when you combine picks, with the IDs resolved by `git rev-parse`. Traceability that tools cannot derive must be recorded by a person.

**Reference.** Chapter 10, sections 10.4 and 10.10.

### Solution 10.4: ranges on a history with a merge

**Solution.**

<!-- snippet: ex1/ex-m10/e04-graph -->
```text
$ git log --graph --oneline --all
* 5997040 G
| * 5cd55d7 F
| *   5f8824f M
| |\  
| |/  
|/|   
* | 61109c7 E
| * 4cfb474 D
| * acce390 C
|/  
* 8e2ba71 B
* 3a5cdc7 A
```
<!-- /snippet -->

```text
          C---D---M---F        topic
         /       /
A---B---E-------/---G          main       (HEAD -> main)
```

<!-- snippet: ex1/ex-m10/e04-answer -->
```text
$ git log --oneline main..topic
5cd55d7 F
5f8824f M
4cfb474 D
acce390 C
$ git log --oneline topic..main
5997040 G
$ git log --oneline --left-right main...topic
< 5997040 G
> 5cd55d7 F
> 5f8824f M
> 4cfb474 D
> acce390 C
$ git rev-list --left-right --count main...topic
1	4
$ git log --oneline --no-merges topic ^main
5cd55d7 F
4cfb474 D
acce390 C
$ git log --oneline "topic~1^!"
5f8824f M
```
<!-- /snippet -->

`E` appears in **none** of the six outputs. It is reachable from `topic` through `M`, and it is also reachable from `main`, so every range that subtracts `main` removes it, and the symmetric difference removes it because both sides have it.

- `main..topic`: the commits reachable from `topic` and not reachable from `main`: `F`, `M`, `D`, `C`.
- `topic ^main` is the same set written another way; `--no-merges` then hides `M`.
- `topic~1^!`: the commits reachable from `topic~1` (that is `M`) and not reachable from any parent of `M`: `M` alone.
- `main...topic` is the symmetric difference: reachable from either tip and not from both. `--left-right` marks the side each commit belongs to, and `--count` gives `1` and `4`.

**Reasoning.** A range is set arithmetic on reachability. It is not "the commits between two points in time", and merging `main` into `topic` does not add `main`'s commits to `main..topic`.

**Common mistakes.** Listing `E` under `main..topic` because "it was merged into topic". Confusing the meaning of two and three dots between `git log` and `git diff`: for `git diff`, `A...B` compares the merge base with `B`, and `A..B` compares the two tips. Reading `--count` output in the wrong order: left number for the left name.

**Expert approach.** "What would this pull request add?" is `git log main..topic`. "How far have the two diverged?" is `git rev-list --left-right --count main...topic`. Say the range as a sentence before trusting it.

**Reference.** Chapter 14A, sections 14A.2, 14A.8 and 14A.14.

### Solution 10.5: which commits does a range pick?

**Solution.**

<!-- snippet: ex1/ex-m10/e05-setup -->
```text
$ git init -q pick-range
$ cd pick-range
$ printf 'base\n' > base.txt && git add . && git commit -q -m 'Base'
$ git branch release
$ printf 'a\n' > a.txt && git add . && git commit -q -m 'Add a'
$ printf 'b\n' > b.txt && git add . && git commit -q -m 'Add b'
$ printf 'c\n' > c.txt && git add . && git commit -q -m 'Add c'
$ printf 'd\n' > d.txt && git add . && git commit -q -m 'Add d'
$ git switch -q release
$ git cherry-pick main~3..main~1
[release 36e9f5a] Add b
 Date: Mon Sep 7 11:19:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 b.txt
[release 505513f] Add c
 Date: Mon Sep 7 11:20:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 c.txt
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m10/e05-answer -->
```text
$ git log --oneline
505513f Add c
36e9f5a Add b
f6c06b0 Base
$ ls
b.txt
base.txt
c.txt
$ git cherry -v release main
+ ff3f22372a7edd2c51c39b5565c2d44aaed9f241 Add a
- f0d994bcbb0489378482fc7b24b7835ee3774f36 Add b
- 97770cbe97433ad8b602cea81ba44220b1807add Add c
+ 6df8e31a1dd7b98ac0b3abd4b92f84797ca5c640 Add d
```
<!-- /snippet -->

`main~3..main~1` is "reachable from `main~1` (Add c) and not from `main~3` (Add a)": `Add b` and `Add c`. They were applied oldest first. `git cherry -v release main` marks them with `-` (an equivalent change is already on `release`) and marks `Add a` and `Add d` with `+` (not there).

To include `Add a`, the range must start at its parent: `main~4..main~1`, or `main~3^..main~1`.

**Reasoning.** The left end of a two-dot range is excluded, for `git cherry-pick` as for `git log`. Before applying, cherry-pick puts the range into the order in which the commits were made, so that each change finds the context it was written against.

**Common mistakes.** The off-by-one at the left end is the classic backport error: the first commit of the series is silently missing. Naming single commits in the wrong order on the command line: listed individually, they are applied in the order given. Reading the `-` of `git cherry` as "missing": minus means "nothing to do, already there".

**Expert approach.** Preview the range with the same expression before picking: `git log --oneline --reverse main~3..main~1`. After picking, `git cherry -v <release> <main>` is the receipt.

**Reference.** Chapter 10, sections 10.5 and 10.10; Chapter 14A, section 14A.8.

### Solution 10.6: backport, then merge the release back

**Solution.**

<!-- snippet: ex1/ex-m10/e06-before-merge -->
```text
$ git log --oneline --left-right --cherry-mark main...release/2.1
= a14fd8c D: fix two
= c7edd2a C: fix one
= 3fb4082 D: fix two
= 975274d C: fix one
< 0ad8175 B: feature
```
<!-- /snippet -->

1. The two fixes on `main` and their two copies on the release branch are marked `=`: the same change on both sides. `B: feature` is marked `<`: only on the left side, `main`.

<!-- snippet: ex1/ex-m10/e06-answer -->
```text
$ git merge -m "Merge release/2.1 into main" release/2.1
Merge made by the 'ort' strategy.
$ git log --graph --oneline --all
*   f373104 Merge release/2.1 into main
|\  
| * a14fd8c D: fix two
| * c7edd2a C: fix one
* | 3fb4082 D: fix two
* | 975274d C: fix one
* | 0ad8175 B: feature
|/  
* ea47f82 A
$ git log --oneline main | grep -c fix
4
$ git log -1 --format=%B release/2.1
D: fix two

(cherry picked from commit 3fb40824d18db83adbba6325930ec2ae3256785b)
```
<!-- /snippet -->

```text
          C'---D'-----.          release/2.1
         /             \
A-------B---C---D-------M        main       (HEAD -> main)
```

2. No conflict. Both sides made the same changes relative to the base `A`, and identical changes merge cleanly.
3. Four. `C` and `D` are in `main` twice, as the originals and as the copies that came in through the merge. That is not a defect, it is what happened: the change was made once and applied in two places. The line `(cherry picked from commit ...)` in each copy tells a reader which original it corresponds to, so the duplicates explain themselves.

**Reasoning.** A merge compares trees, not commits, so duplicated commits with equal effect cost nothing at merge time. They do cost attention in `git log`, where `--cherry-mark` or `--cherry-pick` can mark or hide the pairs.

**Common mistakes.** Expecting a conflict "because the same lines were changed on both sides": they were changed identically. Expecting Git to deduplicate the commits. Backporting without `-x` and then being unable to say which of two same-titled commits is the original.

**Expert approach.** Decide the direction of flow for fixes and keep to it. Either fix on `main` and cherry-pick to release branches, or fix on the release branch and merge it forward into `main`. Mixing both produces histories in which every fix appears three times.

**Reference.** Chapter 10, sections 10.9 and 10.10; Chapter 14A, section 14A.14.

### Solution 10.7: "The previous cherry-pick is now empty"

**Solution.**

<!-- snippet: ex1/ex-m10/e07-diagnosis -->
```text
$ git diff --quiet HEAD
[exit status: 0]
$ git show --format="%h %an: %s" HEAD
17e90fb Ravi Menon: Hotfix: timeouts on long documents

diff --git a/client.yaml b/client.yaml
index ff33e07..939cc8d 100644
--- a/client.yaml
+++ b/client.yaml
@@ -1 +1 @@
-timeout_s: 30
+timeout_s: 120
$ git show --format="%h %an: %s" CHERRY_PICK_HEAD
abec983 Lab User: Raise the timeout for long documents

diff --git a/client.yaml b/client.yaml
index ff33e07..939cc8d 100644
--- a/client.yaml
+++ b/client.yaml
@@ -1 +1 @@
-timeout_s: 30
+timeout_s: 120
$ git cherry -v release/4.0 main
+ 67d8555b524867a3f286fc09d7a1579c3b5a6546 Add retries
- abec9835a570abc1312f6d2f75e322a7a436983d Raise the timeout for long documents
```
<!-- /snippet -->

1. The three-way merge has the picked commit's parent as base (timeout 30), the picked commit as theirs (timeout 120) and the release branch as ours (timeout 120, from Ravi's hotfix). Theirs and ours made the same change, so the result equals ours. There is nothing to commit: `git diff --quiet HEAD` exits with 0.
2. The three ways on:
   - `git cherry-pick --skip`: abandon this commit and continue with the rest of the sequence. Nothing is added to the branch.
   - `git commit --allow-empty`: record an empty commit that carries the message and the `-x` line. The history then says "this fix is here", at the price of a commit without a diff.
   - `git cherry-pick --abort`: return to the state before the command.

   Here `--skip` is right: the change is present, and an empty commit would add noise.

<!-- snippet: ex1/ex-m10/e07-exit -->
```text
$ git cherry-pick --skip
$ git status -sb
## release/4.0
$ git log --oneline -2
17e90fb Hotfix: timeouts on long documents
4616cc6 Add client settings
```
<!-- /snippet -->

   The option that decides in advance is `--empty=drop` (or `keep`, or the default `stop`), available since Git 2.45.
3. `git cherry -v release/4.0 main` marks the commit with `-`. It compares **patch IDs**, hashes of the diffs with line numbers ignored. Ravi's hand-made hotfix and the commit on `main` have different IDs, authors and messages and the same diff.

**Reasoning.** "Empty" is not an error. It is Git reporting that the requested change would change nothing. It stops by default because an empty result can also mean that a conflict resolution removed the whole change by accident.

**Common mistakes.** Treating the stop as a failure and aborting. Committing the empty commit by reflex, or skipping by reflex in the case where the emptiness came from a wrong resolution. Assuming that because one commit was already applied, the whole backport is done.

**Expert approach.** Before a backport, list what is missing: `git cherry -v <release> <main>`. A hotfix made by hand on a release branch should carry a note of the commit it corresponds to, or be replaced by a proper pick afterwards, because only an identical diff is recognized.

**Reference.** Chapter 10, sections 10.6, 10.8 and 10.10.

### Solution 10.8: a clean pick that does not work

**Solution.**

<!-- snippet: ex1/ex-m10/e08-diagnosis -->
```text
$ git grep -n normalize
tok.py:1:from text import normalize
tok.py:4:    return normalize(text).split()
$ git log --oneline -S'def normalize' main
123a9fc Add normalize() helper
$ git cherry -v release/1.0 main
+ 123a9fc6bf6616ae0786dfb16176a29bf7794787 Add normalize() helper
+ 72926539c32f8f3ba0c03562be09a29b4740d6e7 Add README
- 67364a7cdf810e661b20cf03723526b7558a0504 Normalize the text before tokenizing
$ git log --oneline --stat release/1.0..main -- text.py
123a9fc Add normalize() helper
 text.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

1. A cherry-pick guarantees that the picked commit's diff was applied without textual overlap. The diff of "Normalize the text before tokenizing" touches `tok.py` only, and the release branch had not changed that file: a clean merge. Git cannot know that the new line imports a function from a file that exists on `main` and not on the release branch. That is a dependency in meaning, not in text.
2. Three searches:
   - the pickaxe for the definition: `git log -S'def normalize' main` names the commit that introduced it;
   - `git cherry -v release/1.0 main` lists the commits of `main` without an equivalent on the release branch (`+`): the prerequisite is among them;
   - `git log --stat release/1.0..main -- text.py` shows the history of the missing file.
3. The pick is private, so remove it and pick again in the order of `main`:

<!-- snippet: ex1/ex-m10/e08-fix -->
```text
# The pick is private: take it back, then pick both commits in the order main has them.
$ git reset -q --hard HEAD~1
$ git cherry-pick -x 123a9fc main > /dev/null
$ git log --oneline
6d67e0c Normalize the text before tokenizing
902b66b Add normalize() helper
b1ed5dd Add tokenizer
$ ls
text.py
tok.py
```
<!-- /snippet -->

The rule: a commit is safe to backport alone only if everything it uses is already on the target branch. Git checks text; you check dependencies, by reading the diff for new names and by building and testing the target branch after the pick.

**Reasoning.** Cherry-picking takes a commit out of the context it was tested in. The longer the distance between the branches, the more likely it is that something the commit relies on was added in between.

**Common mistakes.** Trusting "applied cleanly" as "works". Adding a commit on the release branch that copies the function by hand: the release then carries code with no link to its origin, and the later backport of the real commit conflicts or duplicates. Picking the prerequisite **after** the dependent commit: it works at the tip, and every commit in between is broken, which poisons a later `git bisect`.

**Expert approach.** For every backport: read `git show <commit>` for identifiers it introduces or uses, search their origin with `-S`, and run the release branch's tests before pushing. If the prerequisites are many, the honest answer may be "this fix cannot be backported as it is; it needs a release-specific patch".

**Reference.** Chapter 10, sections 10.12 and 10.13; Chapter 14A, section 14A.11.

### Solution 10.9: a backport that stopped at its second commit

**Solution.**

<!-- snippet: ex1/solve-m10-backport-in-progress/01-state -->
```text
$ cd vocab-service
$ git status
On branch release/3.2
You are currently cherry-picking commit f320562.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   svc/limits.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git log --oneline -3
7f777e0 Security: reject NUL bytes in the input
c688061 Lower the input limit for the 3.2 line
d412808 Add tokenizer service
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m10-backport-in-progress/02-sequencer -->
```text
$ git log -1 --format="%h %s" CHERRY_PICK_HEAD
f320562 Security: cap the input length before tokenizing
$ cat .git/sequencer/todo
pick f320562 Security: cap the input length before tokenizing
pick babcf54 Security: strip control characters
$ git log --format="%h %s" release/3.2..main
babcf54 Security: strip control characters
f320562 Security: cap the input length before tokenizing
752bdb8 Add batch endpoint
d53c2e1 Security: reject NUL bytes in the input
5da2b9f Add streaming endpoint
```
<!-- /snippet -->

The first security fix is applied (it is the tip of the branch). `CHERRY_PICK_HEAD` names the commit being applied, "Security: cap the input length before tokenizing". `.git/sequencer/todo` lists what is still queued: the current commit and the third fix. The two feature commits of `main` are not in the list.

<!-- snippet: ex1/solve-m10-backport-in-progress/03-conflict -->
```text
$ git diff
diff --cc svc/limits.py
index 834df64,7feb6a4..0000000
--- a/svc/limits.py
+++ b/svc/limits.py
@@@ -1,1 -1,5 +1,9 @@@
++<<<<<<< HEAD
 +MAX_INPUT = 2048
++=======
+ MAX_INPUT = 4096
+ 
+ def check(text):
+     if len(text) > MAX_INPUT:
+         raise ValueError("input too long")
++>>>>>>> f320562 (Security: cap the input length before tokenizing)
$ git show :1:svc/limits.py
MAX_INPUT = 4096
```
<!-- /snippet -->

Three versions of `svc/limits.py`: the base (the picked commit's parent on `main`) has the limit 4096; ours, the release branch, lowered it to 2048 on purpose; theirs keeps 4096 and adds the `check()` function below. The release changed line 1, the fix added lines right after line 1: adjacent changes, hence a conflict. The resolution takes the release's limit and the fix's function:

<!-- snippet: ex1/solve-m10-backport-in-progress/04-resolve -->
```text
$ printf 'MAX_INPUT = 2048\n\ndef check(text):\n    if len(text) > MAX_INPUT:\n        raise ValueError("input too long")\n' > svc/limits.py
$ git add svc/limits.py
$ git cherry-pick --continue
[release/3.2 c3c598b] Security: cap the input length before tokenizing
 Date: Mon Sep 7 10:10:00 2026 +0530
 1 file changed, 4 insertions(+)
[release/3.2 ff7c404] Security: strip control characters
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

`git cherry-pick --continue` committed the resolved pick and went on with the queued third one, which applied cleanly.

<!-- snippet: ex1/solve-m10-backport-in-progress/05-verify -->
```text
$ git status -sb
## release/3.2
$ git log --format="%h %s%n   %b" -3
ff7c404 Security: strip control characters
   (cherry picked from commit babcf549f565b8cb814674f069310c089c909582)

c3c598b Security: cap the input length before tokenizing
   (cherry picked from commit f3205625ac27eaa653d55c38c201fd7cd5fec833)

7f777e0 Security: reject NUL bytes in the input
   (cherry picked from commit d53c2e1c341656a9991997916869a63c04be3da8)

$ git cherry -v release/3.2 main
+ 5da2b9ff58263e533203a7bd9eb685e5a205faf5 Add streaming endpoint
- d53c2e1c341656a9991997916869a63c04be3da8 Security: reject NUL bytes in the input
+ 752bdb8e678fb47b329915438f5946ee2454f848 Add batch endpoint
+ f3205625ac27eaa653d55c38c201fd7cd5fec833 Security: cap the input length before tokenizing
- babcf549f565b8cb814674f069310c089c909582 Security: strip control characters
$ git diff --stat main release/3.2
 svc/batch.py  | 2 --
 svc/limits.py | 2 +-
 svc/stream.py | 3 ---
 3 files changed, 1 insertion(+), 6 deletions(-)
$ cat svc/limits.py
MAX_INPUT = 2048

def check(text):
    if len(text) > MAX_INPUT:
        raise ValueError("input too long")
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m10-backport-in-progress/06-check -->
```text
$ cd ..
$ exercises/gen/m10-backport-in-progress/check.sh
Checking exercise m10-backport-in-progress
  ok    no cherry-pick is in progress
  ok    the release line still starts from its own history
  ok    exactly the three security fixes were added, in the order of main
  ok    "Security: reject NUL bytes in the input" records the commit of main it came from
  ok    "Security: cap the input length before tokenizing" records the commit of main it came from
  ok    "Security: strip control characters" records the commit of main it came from
  ok    the release keeps its own input limit
  ok    the length check arrived
  ok    the limit of main did not arrive
  ok    svc/tokenize.py has both fixes: it equals the file on main
  ok    the streaming endpoint was not backported
  ok    the batch endpoint was not backported
  ok    no conflict marker is committed
  ok    working tree and index are clean
PASS: exercise m10-backport-in-progress is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.** Proof that no feature arrived: `git diff --stat main release/3.2` shows the two feature files as missing on the release side and one differing line in `limits.py`, the release's own limit.

`git cherry -v release/3.2 main` marks the first and the third fix with `-` and the second with `+`, although all three were backported. The second pick was **adapted** during conflict resolution, so its diff differs from the original's and the patch IDs no longer match. Tools that detect backports by patch ID (`git cherry`, `--cherry-mark`, the skipping in `git rebase`) cannot see it. The `(cherry picked from commit ...)` line written by `-x` is the record that still holds.

**Common mistakes.** Resolving by taking "theirs", which silently raises the release's limit to 4096, or "ours", which drops the security fix and can leave an empty pick. Running `git cherry-pick --abort`: it rolls the branch back to before the **whole** sequence, including the first, finished pick. Running `git cherry-pick --skip` on the conflicted commit. Finishing with `git commit` and forgetting `--continue`, which leaves the third fix unapplied and the sequencer state in place.

**Expert approach.** In a stopped sequence, read the state before acting: `git status`, `CHERRY_PICK_HEAD`, `.git/sequencer/todo`. After the backport, verify three things: the list of commits (`git log <old tip>..`), the trailers, and the diff against `main` restricted to what must differ.

**Reference.** Chapter 10, sections 10.4, 10.6, 10.7, 10.9 and 10.10.

### Solution 10.10: "the fix is in the release" and "the fix was never backported"

**Solution.** Both commands, as quoted:

<!-- snippet: ex1/solve-m10-half-backport/01-claims -->
```text
$ cd you
# Asha's command: which branches contain the commit that the ticket names?
$ git branch -r --contains 2e48b86
  origin/HEAD -> origin/main
  origin/main
# Ravi's command: is there a commit on the release line that mentions the ticket?
$ git log --oneline origin/release/2.x --grep=ROUTE-231
396f09a Fix model selection for prompts over the context window
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m10-half-backport/02-graph -->
```text
$ git log --graph --oneline origin/main origin/release/2.x
* aaa789f Release 2.3.1
* 396f09a Fix model selection for prompts over the context window
| * 099c8d3 Route prompts of exactly the limit to the large model
| * d6232a7 Add cost-aware routing
| * 2e48b86 Fix model selection for prompts over the context window
|/  
* 862da9a Add prompt router
```
<!-- /snippet -->

`git branch --contains` asks about **ancestry**: is this commit object reachable from the branch? A cherry-picked copy is another object, so the release branch is not listed although it has the change. `git log --grep` asks about **text in messages**: a commit that mentions the ticket exists on the release branch. Neither command asks what the code does.

The comparison that settles it works on changes:

<!-- snippet: ex1/solve-m10-half-backport/03-equivalence -->
```text
# Which commits of main have a copy with the same change on the release line?
$ git cherry -v origin/release/2.x origin/main
- 2e48b8695b8913e89a9c7a9ff7e4df93cd75047c Fix model selection for prompts over the context window
+ d6232a7fe82cf15decb91295a6af46ff04f45e9a Add cost-aware routing
+ 099c8d32491e933b8c5ae2e03608a222624d560e Route prompts of exactly the limit to the large model
$ git log --oneline --left-right --cherry-mark origin/release/2.x...origin/main
< aaa789f Release 2.3.1
= 396f09a Fix model selection for prompts over the context window
> 099c8d3 Route prompts of exactly the limit to the large model
> d6232a7 Add cost-aware routing
= 2e48b86 Fix model selection for prompts over the context window
```
<!-- /snippet -->

Of the three commits `main` has and the release lacks by ancestry, one has an equivalent on the release branch (`-`, and `=` in the second listing): the fix named in the ticket. Two have none (`+`): the feature, which must not be backported, and "Route prompts of exactly the limit to the large model".

<!-- snippet: ex1/solve-m10-half-backport/04-content -->
```text
$ git diff origin/release/2.x origin/main -- router/select.py
diff --git a/router/select.py b/router/select.py
index 6a3cdaa..8d45c6a 100644
--- a/router/select.py
+++ b/router/select.py
@@ -1,6 +1,6 @@
 LIMIT = 8192
 
 def select(tokens):
-    if tokens > LIMIT:
+    if tokens >= LIMIT:
         return "large"
     return "small"
$ git log --oneline origin/release/2.x..origin/main -- router/select.py
099c8d3 Route prompts of exactly the limit to the large model
2e48b86 Fix model selection for prompts over the context window
```
<!-- /snippet -->

One character: the release compares with `>`, `main` with `>=`. A prompt of exactly 8192 tokens is the customer's case.

**Reasoning.** The root cause, in the book's frame:

```text
Observed behavior : the release line has "the fix" and still shows the bug at the boundary.
Git state         : main fixed the bug in two commits. Only the first mentions the ticket.
                    The release line has a copy of the first, made without -x.
Mechanism         : the backport was chosen by ticket reference. The follow-up commit has no
                    reference, so it was invisible to that selection.
Root cause        : a fix that spans two commits was backported by one of them; nothing
                    compared the routing code of the two branches afterwards.
Why Git does this : Git records commits, not which commits belong to one "fix".
Correct fix       : backport the follow-up with -x, verify by comparing the file on both
                    branches, release 2.3.2.
Prevention        : ticket references in every commit of a fix; a release checklist step that
                    runs git cherry -v <release> <main> for the files of the fix.
```

<!-- snippet: ex1/solve-m10-half-backport/05-backport -->
```text
$ git switch release/2.x
Switched to a new branch 'release/2.x'
branch 'release/2.x' set up to track 'origin/release/2.x'.
$ git cherry-pick -x 099c8d3
[release/2.x fcbfa33] Route prompts of exactly the limit to the large model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format=%B
Route prompts of exactly the limit to the large model

The small model needs room for at least one output token.

(cherry picked from commit 099c8d32491e933b8c5ae2e03608a222624d560e)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m10-half-backport/06-verify -->
```text
$ git diff --quiet HEAD origin/main -- router/select.py
[exit status: 0]
$ git diff --stat HEAD origin/main
 CHANGELOG.md   | 4 ----
 router/cost.py | 3 +++
 2 files changed, 3 insertions(+), 4 deletions(-)
$ git cherry -v HEAD origin/main
- 2e48b8695b8913e89a9c7a9ff7e4df93cd75047c Fix model selection for prompts over the context window
+ d6232a7fe82cf15decb91295a6af46ff04f45e9a Add cost-aware routing
- 099c8d32491e933b8c5ae2e03608a222624d560e Route prompts of exactly the limit to the large model
```
<!-- /snippet -->

The routing code of the two branches is now identical, and what still differs is what must differ: the feature and the changelog.

<!-- snippet: ex1/solve-m10-half-backport/07-publish -->
```text
$ git push
To ../server.git
   aaa789f..fcbfa33  release/2.x -> release/2.x
$ git log --oneline -4 origin/release/2.x
fcbfa33 Route prompts of exactly the limit to the large model
aaa789f Release 2.3.1
396f09a Fix model selection for prompts over the context window
862da9a Add prompt router
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m10-half-backport/08-check -->
```text
$ cd ..
$ exercises/gen/m10-half-backport/check.sh
Checking exercise m10-half-backport
  ok    release/2.x on the server still contains the released history
  ok    the routing code of the release equals the routing code of main
  ok    the follow-up fix is on the release line exactly once
  ok    the backport records the commit of main it came from
  ok    cost-aware routing was not backported
  ok    no merge was made into the release line
  ok    your local release/2.x is what the server has
  ok    nothing is left in progress in your clone
  ok    your working tree is clean
PASS: exercise m10-half-backport is solved.
[exit status: 0]
```
<!-- /snippet -->

**Claims.**

| Claim | Verdict | Evidence |
|---|---|---|
| Asha: "`--contains` lists only `main`, so the fix never reached the release" | The output is true, the conclusion false | `git cherry` marks that commit `-`: an equivalent change is on the release |
| Asha: "the changelog of 2.3.1 is wrong" | Half true | the ticket's first commit is there; the behavior it promises is incomplete |
| Ravi: "`--grep=ROUTE-231` finds it, the release has the fix" | The output is true, the conclusion false | the release lacks the follow-up; `git diff` of `router/select.py` |
| Ravi: "the customer must be on an older build" | False | the released code has `>`; the customer's input is the boundary case |
| Support: "works on a build of `main`" | True | `main` has `>=` |

Two process rules. For commit messages: every commit that belongs to a fix carries the ticket reference, the follow-up included (a `Ticket:` trailer makes it searchable). For the release checklist: backports are made with `-x`, and before a release is cut, `git cherry -v <release> <main>` and a `git diff <release> <main> -- <paths of the fix>` are read by a second person.

**Common mistakes.** Stopping at whichever of the two commands confirms your first belief. Cherry-picking the ticket's commit again "to be sure": it stops as empty (Exercise 10.7). Merging `main` into the release branch to get the fix, which brings the feature along. Picking the follow-up without `-x`, repeating the gap that made the first backport hard to trace.

**Expert approach.** There are three different questions, and each has its own command: is this **commit** in the branch (`--contains`, ancestry), is this **change** in the branch (`git cherry`, patch ID), does the branch **behave** as intended (compare the files, run the test). In a dispute, name which question each side has answered. Then add the missing regression test for the boundary value to both branches.

**Reference.** Chapter 10, sections 10.3, 10.9 and 10.10; Chapter 14A, sections 14A.2 and 14A.14.

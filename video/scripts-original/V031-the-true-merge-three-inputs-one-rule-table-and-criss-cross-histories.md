# V031: The true merge: three inputs, one rule table, and criss-cross histories

- **Part.** 2: Integration and collaboration mechanics
- **Module.** 6
- **Planned minutes.** 24
- **Prerequisites.** V030
- **Textbook sections.** [Chapter 8: Merge](../../textbook/ch08-merge.md), sections 8.4 and 8.5
- **Demo scripts.** `labs/ch08/three-way-rules.sh`, `labs/ch08/merge-base.sh` (snippets `03-crisscross` to `06-diff3-nested`)

## HOOK

**[ON SCREEN]** "The same conflict keeps coming back."

A release manager reports: "The same conflict keeps coming back." Every time `main` and the release branch are merged, the judge temperature in the evaluation configuration conflicts. They resolve it. Next week it conflicts again. And when they open the base version of the file to see what both sides started from, the base version itself contains conflict markers.

**[PAUSE]**

Nothing is corrupt. The two branches have each merged the other, and they resolved the same conflict in opposite ways. The history now has two equally good common ancestors, and Git has to reconcile those first. To follow that, you need the rule by which every true merge is computed: three inputs, one table, and nothing else.

## INTRODUCTION

In the last video, a merge either moved a ref or reported that there was nothing to do. Now both sides have commits that the other lacks, and Git has to produce a new snapshot.

The first half of this video is the rule table: for one path, given the base version, our version and their version, what is the result? You will check a real merge against the table, path by path. The second half is the criss-cross history: what happens when there is more than one merge base, and what the default strategy does about it.

## LEARNING OBJECTIVES

After this video you can:

1. State the three-way rule for one path as a table of base, ours and theirs.
2. Say which rows of the table are decided without reading file content.
3. Explain why a change made on both sides and reverted on one comes back.
4. Explain how two commits can have more than one merge base, and what the default strategy does then.

## CONCEPT

**The true merge.** In one sentence: when both sides have commits that the other lacks, Git combines the two tips against their merge base, path by path and then line by line, and records the result as a commit with two parents.

**Three trees.** Call them base, ours and theirs. Ours is the commit HEAD points to. Theirs is the commit named on the command line. For every path, Git compares three blob IDs.

**The rule table.** X, Y and Z stand for different contents.

**[ON SCREEN]** The table of section 8.4, one row at a time.

Base X, ours X, theirs X: the result is X. Nobody changed it.

Base X, ours Y, theirs X: the result is Y. Only ours changed it.

Base X, ours X, theirs Y: the result is Y. Only theirs changed it.

Base X, ours Y, theirs Y: the result is Y. Both made the same change.

Base X, ours Y, theirs Z: merge the content of the three files. This is the only row that reads file content.

Absent in base and ours, Y in theirs: Y. Added by theirs.

X in base and ours, absent in theirs: absent. Deleted by theirs, untouched by ours.

X in base, Y in ours, absent in theirs: a conflict, called modify/delete.

Absent in base, Y in ours, Z in theirs: a conflict, called add/add.

The table is not an interpretation. The manual of `git read-tree`, Git's original three-way merge plumbing, states the first rows in words such as "stage 2 and 3 are the same; take one or the other". Stages 1, 2 and 3 are base, ours and theirs.

**Two consequences.** First, most paths are settled without reading a file. Equal content has an equal blob ID, as you know from V007, so comparing three IDs is enough.

Second, the rows mention three snapshots and nothing else. The commits between the base and each tip do not take part. A change that both sides made is taken once, and silently. And a change that one side made and later undid counts as "that side did nothing".

Follow that last sentence to its end, because it is objective three. Both branches contain a change. One branch then reverts it. At merge time, that branch's tip equals the base for those lines: row "X, X, Y" or "X, Y, X". The other side changed it; this side "did nothing". The result takes the change. The revert has no vote, because the merge never looks at the commits in between. The change comes back.

**Inside `.git`.** A clean true merge writes a blob for every file merged by content, the trees above those blobs, and one commit object with two `parent` lines. Then it does what any commit does: the current branch ref moves to the new commit, and the reflogs gain a line. `ORIG_HEAD` holds the previous tip. `git merge` is 🟡 CAUTION.

**Criss-cross histories.** In one sentence: when two branches have each merged the other, they can have two best common ancestors, and Git then merges those ancestors with each other first, and uses the result as the base.

Precisely. `git merge-base --all` prints every merge base. Without `--all` you get one, and the manual says "it is unspecified which best one is output". The default strategy handles the case as the manual describes: "When there is more than one common ancestor that can be used for 3-way merge, it creates a merged tree of the common ancestors and uses that as the reference tree for the 3-way merge". That merged tree is called the virtual merge base.

Inside `.git`: the virtual merge base is computed during the merge and never becomes a commit. Its only visible trace is stage 1 of a conflicted path.

**Why Git does this.** Either base alone would silently reapply one side's old decision. A base that matches neither tip returns the question to a human.

**When to avoid the situation.** The textbook's prevention: between long-lived branches, merge in one direction only. Keep other branches short enough that they never merge each other.

## MENTAL MODEL

The textbook's analogy: the editor-in-chief has three copies on the desk: Monday's, yours and theirs. If only one of you changed a page, take that version. If both made the same change, take it once. If both changed it differently, open the page and compare paragraphs.

The analogy breaks where it matters most: the editor-in-chief reads for meaning. Git compares text.

For the criss-cross: two Monday copies, each containing a decision that one editor made and the other rejected. Before the editor-in-chief can compare Friday's copies, the two Monday copies have to be reconciled into one. The analogy breaks when they cannot be: Git then keeps the disagreement inside the base, as conflict markers.

And the sentence to carry out of this video: Git does not replay the branch. It looks at three endpoints.

## DIAGRAM

**[DIAGRAM]** The diagram of section 8.4.

```text
                      67feed7----------.          feature/timeout
                     /                  \
  6ae3c51---23db174---017bef5-----------6b10077   main   (HEAD -> main)
               ^
               merge base
```

The merge from the last video. Base `23db174`, ours `017bef5`, theirs `67feed7`, and the result `6b10077` with two parents. Circle the three inputs. Everything the merge knows is in those three trees.

**[DIAGRAM]** The diagram of section 8.5.

```text
  36749ac---5d28836---bd573ed   main   (HEAD -> main)
        \          \ /
         \          X
          \        / \
           2725147---4f30da1    release/1.0

  merge bases of main and release/1.0: 5d28836 and 2725147
```

Two lines, and a cross between them: each branch has merged the other. Follow the parents back from the two tips. `5d28836` is reachable from both. So is `2725147`. Neither is an ancestor of the other. Two best common ancestors: two merge bases.

**[DIAGRAM]** The root-cause box of section 8.5, one line at a time, after the demo.

```text
Observed behavior : The base version of a conflicted file (git show :1:path, or the middle
                    section in diff3 style) contains conflict markers labelled
                    "Temporary merge branch 1" and "Temporary merge branch 2".
Git state         : git merge-base --all prints two commits; neither is an ancestor of the other.
Mechanism         : The ort strategy first merges the two merge bases with each other. That inner
                    merge conflicts, and its result, markers included, becomes the base.
Root cause        : A criss-cross. Each branch merged the other, and the two merges resolved the
                    same conflict in opposite ways.
Why Git does this : Either base alone would silently reapply one side's old decision, as the
                    two-answer transcript shows. A base that matches neither tip returns the
                    question to a human.
Correct fix       : Resolve it as an ordinary conflict. Read the inner block as the two earlier
                    decisions and the outer sides as the two current values.
Prevention        : Between long-lived branches, merge in one direction only. Keep other
                    branches short enough that they never merge each other.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch08/three-way-rules.sh`. Split layout with the rule table.

```bash
labs/run ch08/three-way-rules
```

Three listings: the tree of the base, of ours, and of theirs, with abbreviated blob IDs.

<!-- snippet: ch08/three-way-rules/01-three-inputs -->
```text
$ git merge-base main feature/rouge
e650b75915a1645cdb222c495fa22e6273eab187
# base (the merge base, tagged "base" by the demo):
$ git ls-tree -r --abbrev=7 base
100644 blob af7f9b5	README.md
100644 blob c5b3327	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob cfe0ef0	prompts/judge.txt
100644 blob 3aecde9	requirements.txt
100644 blob 4a41a25	scripts/legacy_eval.sh
# ours (main):
$ git ls-tree -r --abbrev=7 main
100644 blob aa477a1	README.md
100644 blob 0e8b97c	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob 38cb437	prompts/judge.txt
100644 blob 3aecde9	requirements.txt
100644 blob 4a41a25	scripts/legacy_eval.sh
# theirs (feature/rouge):
$ git ls-tree -r --abbrev=7 feature/rouge
100644 blob af7f9b5	README.md
100644 blob caf8b0d	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob fe0b96e	evalkit/rouge.py
100644 blob 38cb437	prompts/judge.txt
100644 blob 4a7b8a2	requirements.txt
```
<!-- /snippet -->

Stop the recording here and do the work. For each path, compare the three IDs and find its row in the table. Write down the result you expect: which blob ID, or "absent", or "content merge". Seven paths.

**[PAUSE]**

`git merge` 🟡 CAUTION.

<!-- snippet: ch08/three-way-rules/02-merge -->
```text
$ git merge feature/rouge
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml       | 2 +-
 evalkit/rouge.py       | 2 ++
 requirements.txt       | 1 +
 scripts/legacy_eval.sh | 2 --
 4 files changed, 4 insertions(+), 3 deletions(-)
 create mode 100644 evalkit/rouge.py
 delete mode 100644 scripts/legacy_eval.sh
```
<!-- /snippet -->

One line says "Auto-merging": one path needed a content merge.

<!-- snippet: ch08/three-way-rules/03-result -->
```text
# result (the tree of the merge commit):
$ git ls-tree -r --abbrev=7 HEAD
100644 blob aa477a1	README.md
100644 blob cef358f	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob fe0b96e	evalkit/rouge.py
100644 blob 38cb437	prompts/judge.txt
100644 blob 4a7b8a2	requirements.txt
```
<!-- /snippet -->

Read the result against the table. `README.md` is `af7f9b5` in base and theirs, and `aa477a1` in ours: only ours changed it, and the result is `aa477a1`. `requirements.txt` changed only in theirs: the result is `4a7b8a2`. `prompts/judge.txt` is `38cb437` on both sides, because Asha and you added the same line independently: taken once, no message. `scripts/legacy_eval.sh` is unchanged in ours and missing in theirs: deleted. `evalkit/rouge.py` exists only in theirs: added. `evalkit/metrics.py`: nobody changed it. Only `config/eval.yaml` has three different IDs, and its result, `cef358f`, is a new blob.

Six of seven paths were decided by comparing IDs. No file was read for them.

<!-- snippet: ch08/three-way-rules/04-content-merge -->
```text
# What ours changed since the base (HEAD^1 is the first parent of the merge):
$ git diff -U0 base HEAD^1 -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..0e8b97c 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.2
+temperature: 0.0
# What theirs changed since the base (HEAD^2 is the second parent):
$ git diff -U0 base HEAD^2 -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..caf8b0d 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -5 +5 @@ batch_size: 16
-timeout_s: 30
+timeout_s: 60
# The merged file carries both changes:
$ git diff -U0 base HEAD -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..cef358f 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.2
+temperature: 0.0
@@ -5 +5 @@ batch_size: 16
-timeout_s: 30
+timeout_s: 60
```
<!-- /snippet -->

The seventh. What ours changed since the base, what theirs changed since the base, and the merged file with both changes. How Git decides whether two such changes can both be applied is the next video.

**[TERMINAL]** Caption bar: `labs/ch08/merge-base.sh`, snippet `03-crisscross`.

```bash
labs/run ch08/merge-base
```

`main` and `release/1.0` disagreed about the judge temperature. Asha merged `main` into the release branch and kept 0.7. At the same time you merged the release branch into `main` and kept 0.0.

<!-- snippet: ch08/merge-base/03-crisscross -->
```text
$ git log --oneline --graph --all
*   bd573ed Merge release/1.0 into main, keep temperature 0.0
|\  
| | * 4f30da1 Merge main into release/1.0, keep temperature 0.7
| |/| 
| |/  
|/|   
* | 5d28836 Use temperature 0 for reproducible evals
| * 2725147 Raise temperature for the 1.0 judge
|/  
* 36749ac Add eval config, judge prompt and metrics
$ git merge-base main release/1.0
272514788670fe9d71d00daeca408d3494e15041
$ git merge-base --all main release/1.0
272514788670fe9d71d00daeca408d3494e15041
5d288362f8c011ad12da5920c8cc763443e61c5d
```
<!-- /snippet -->

`git merge-base --all` prints two commits: `2725147`, her commit, and `5d28836`, yours.

What would happen if Git picked one? `git merge-tree` 🟢 SAFE can be told which base to use; it writes objects and moves no ref. Predict the temperature for each choice of base.

**[PAUSE]**

<!-- snippet: ch08/merge-base/04-three-answers -->
```text
# Merge with only the first candidate as the base:
$ tree=$(git merge-tree --write-tree --merge-base=release/1.0~1 main release/1.0)
$ git show $tree:config/eval.yaml | grep temperature
temperature: 0.0
# Merge with only the second candidate as the base:
$ tree=$(git merge-tree --write-tree --merge-base=main~1 main release/1.0)
$ git show $tree:config/eval.yaml | grep temperature
temperature: 0.7
```
<!-- /snippet -->

Two silent, opposite answers. Against her commit as base, the release tip "did nothing" to the temperature, and your side wins: 0.0. Against your commit as base, her side wins: 0.7. Neither would show a conflict, and nobody would have decided either. That is the rule table doing exactly what it says, with the wrong Monday copy.

The real merge does better.

<!-- snippet: ch08/merge-base/05-virtual-base -->
```text
$ git merge release/1.0
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git ls-files -u
100644 eeb99652ab2e2dc7f9c07b8a0db026159a245750 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 3e21100524f1361d04738d41f1012b9221082155 3	config/eval.yaml
$ git show :1:config/eval.yaml
model: judge-large-v2
<<<<<<<<< Temporary merge branch 1
temperature: 0.0
=========
temperature: 0.7
>>>>>>>>> Temporary merge branch 2
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 7
```
<!-- /snippet -->

A conflict. `git ls-files -u` lists three entries for the path: stages 1, 2 and 3. And stage 1, the base version, contains conflict markers, labelled "Temporary merge branch 1" and "2". That file is the virtual merge base: the result of merging the two base commits with each other. Because both tips differ from it, the outer merge conflicts, and the decision comes back to you.

<!-- snippet: ch08/merge-base/06-diff3-nested -->
```text
$ git merge --abort
$ git -c merge.conflictStyle=diff3 merge release/1.0
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat config/eval.yaml
model: judge-large-v2
<<<<<<< HEAD
temperature: 0.0
||||||| merged common ancestors
<<<<<<<<< Temporary merge branch 1
temperature: 0.0
||||||||| 36749ac
temperature: 0.2
=========
temperature: 0.7
>>>>>>>>> Temporary merge branch 2
=======
temperature: 0.7
>>>>>>> release/1.0
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 7
```
<!-- /snippet -->

The script aborts the merge and repeats it with the `diff3` conflict style, which shows the nesting in one view. `git merge --abort` is 🔴 DANGEROUS, so the five questions. What it changes: it resets the index and the working tree to HEAD, and deletes the merge state. What it can destroy: every resolution made so far, and any uncommitted edit that was staged during the merge. How to preview: `git status` and `git diff --cached --stat`. How to recover: staged content survives as unreferenced objects that `git fsck` lists; unstaged resolution edits are gone. When it is appropriate: when the merge was a mistake or needs a different approach, as here, where nothing has been resolved yet.

Read the nested block: the inner markers are nine characters long, the outer ones seven. The inner block is the two earlier decisions. The outer sides are the two current values.

**[DIAGRAM]** Show the root-cause box.

## COMMON MISTAKES

1. **Expecting Git to "replay" the branch's commits.** Root cause: a merge is computed from three snapshots; the commits between the base and each tip do not take part.
2. **A reverted change comes back after a merge.** Root cause: the side that made and undid the change counts as having done nothing, and the other side still has the change.
3. **Not noticing that both sides made the same change.** Root cause: identical changes are taken once and silently; the merge prints no message for that row.
4. **The base version of a conflicted file contains conflict markers.** Root cause: a criss-cross history with two merge bases; `ort` merged them into a virtual base, markers included.
5. **Trusting `git merge-base` without `--all` in a tangled history.** Root cause: it prints one merge base, and which best one is output is unspecified.

## PRODUCTION EXAMPLE

The usual producers of a criss-cross, according to the textbook, are a release branch and `main` that merge each other "to stay in sync", and two developers who each pull the other's feature branch. The reported symptom is "the same conflict keeps coming back". Run `git merge-base --all` before theorizing.

And a consequence of the true merge for every team with CI: the tree of a merge commit is a snapshot that neither author wrote, and that no test has run on. Both parents can be green while the merge is red, so CI has to run on the merge result.

**[ON SCREEN]** Lower third: **GitHub Actions**. For a `pull_request` event, GitHub Actions checks out a merge of the pull request's head into the current base by default, so the tests run against the merged result and not against the head branch alone. That merge is computed on GitHub's servers. This is described from GitHub's documentation, not run here.

## PRACTICE EXERCISE

Do Exercise 6.2, Level 1, "the merge base and the rule table", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Draw the three trees, base, ours and theirs, before you run the merge. For each path, name the row of the table and the expected result. Only then merge and compare.

## INTERVIEW QUESTION

Q125: "What happens during a three-way merge?"

Answer aloud. The question is open on purpose. A strong answer names the three inputs and how the third is found, gives the per-path rule and says which rows need no file content, says what is written when the merge succeeds, and states what the merge does not look at. If you have time left, mention what happens when there is more than one merge base.

## RECAP

You should now be able to say: a true merge combines three trees: the merge base, ours and theirs. For each path: unchanged on one side takes the other side; changed identically takes that change once; changed differently needs a content merge; and modify/delete or add/add is a conflict. Most paths are decided by comparing blob IDs. The merge does not look at the commits in between, so a change reverted on one side comes back from the other. When two branches have merged each other, there can be two merge bases; `ort` merges them into a virtual base, and if that inner merge conflicts, the markers appear in stage 1.

## HOMEWORK

- Read sections 8.4 and 8.5 of [Chapter 8](../../textbook/ch08-merge.md).
- Draw the three trees for Exercise 6.2 before you run it, if you have not done so in the practice exercise.
- Challenge: Exercise 6.6, Level 2, "which of three changes conflicts?", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

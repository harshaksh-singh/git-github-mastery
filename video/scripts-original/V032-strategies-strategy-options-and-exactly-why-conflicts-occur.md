# V032: Strategies, strategy options, and exactly why conflicts occur

- **Part.** 2: Integration and collaboration mechanics
- **Module.** 6
- **Planned minutes.** 22
- **Prerequisites.** V031
- **Textbook sections.** [Chapter 8: Merge](../../textbook/ch08-merge.md), sections 8.6 and 8.7
- **Demo scripts.** `labs/ch08/strategy-options.sh`, `labs/ch08/why-conflicts.sh`

## HOOK

**[ON SCREEN]** `git merge -s ours` and `git merge -X ours`, one above the other.

A merge is red. An engineer searches for a way to "take our side", finds two commands that differ by one letter, and uses the first one that makes the conflict disappear.

One of those commands merges everything the other branch did, except the hunks that conflict. The other throws away everything the other branch did, all of it, and records the branch as merged, so that Git will never offer those changes again.

**[PAUSE]**

Both end with a green merge and no message that anything was dropped. If you cannot say which is which, you should not type either. This video separates them, and then answers the question underneath: under exactly which condition do two edits conflict at all?

## INTRODUCTION

You know the rule table. One of its rows said "merge the content of the three files". This video opens that row.

First, the vocabulary. A merge strategy is the algorithm. A strategy option adjusts one strategy. Then three ways of "taking a side", compared by content and by ancestry. Then the exact condition for a content conflict, shown on five pairs of edits. You will predict each of the five before you see it.

## LEARNING OBJECTIVES

After this video you can:

1. Distinguish a merge strategy from a strategy option.
2. Compare `-X ours`, `-X theirs` and `-s ours` by content and by ancestry.
3. State the exact condition under which two edits to one file conflict.
4. Predict for a pair of edits whether they conflict.

## CONCEPT

**Strategies and options.** In one sentence: a merge strategy is the algorithm that turns the inputs into a result tree, selected with `-s`; a strategy option, passed with `-X`, adjusts how one strategy behaves.

**The strategies the Git 2.55 manual lists.**

**[ON SCREEN]** The strategy table of section 8.6.

`ort`: in the manual's words, "the default merge strategy when pulling or merging one branch". It is a three-way merge; it builds a virtual base when there are several merge bases; it detects renames; and it defaults to the histogram diff algorithm. You meet it in every ordinary merge, and also under rebase, cherry-pick and revert.

`recursive`: "now a synonym for `ort`". You meet it in old scripts and old tutorials.

`resolve`: three-way; "does not handle renames". Legacy.

`octopus`: for more than two heads; it "refuses to do a complex merge that needs manual resolution".

`ours`: the result tree "is always that of the current branch head, effectively ignoring all changes from all other branches".

`subtree`: "a modified `ort` strategy" that shifts one tree to match a subdirectory of the other.

**The options `ort` accepts with `-X`.** `ours` and `theirs`: which side wins a conflicting hunk. The whitespace options, among them `ignore-space-change`. The rename options. And `diff-algorithm`, `renormalize` and `subtree`.

**`-X ours` is not `-s ours`.**

**[ON SCREEN]** The comparison table of section 8.6.

What it is: `-X ours` is an option of the `ort` strategy. `-s ours` is a different strategy.

Their non-conflicting changes: with `-X ours`, merged. With `-s ours`, discarded.

Conflicting hunks: with `-X ours`, your side, without a conflict being reported. With `-s ours`, not applicable.

The tree of the merge commit: with `-X ours`, a real merge result. With `-s ours`, identical to the first parent's tree.

Legitimate use: for `-X ours`, rare: mechanical conflicts where one side is known to be right. For `-s ours`: to declare a branch obsolete, so that it never merges again.

By ancestry, the two are the same: in both cases their commits become ancestors of your branch, and `git branch --merged` lists their branch. By content, they are opposite ends.

There is no `-s theirs`.

All three forms carry the label 🟡 CAUTION in the textbook's table: `-X ours`, `-X theirs` and `-X ignore-space-change` move the current branch like any merge, and silently drop one side of every conflicting hunk; `-s ours` records the other branch as merged and takes none of its content. The preview for the `-X` forms is to merge without the option first; for `-s ours`, `git diff HEAD...<other>` shows what is discarded.

**Whitespace options.** With a whitespace option, the manual says, "if their version only introduces whitespace changes to a line, our version is used". So the option does not merge whitespace changes. It discards them wherever they meet a line that our side kept or changed.

**Exactly why conflicts occur.** In one sentence: a content conflict occurs when both sides changed the same lines of a file, or lines with no unchanged line between them, and did not make the identical change.

Precisely. For a path in the "X, Y, Z" row, Git merges the three file contents. It finds what ours changed relative to the base, and what theirs changed relative to the base, each as a set of hunks: runs of base lines that were replaced, removed or inserted into. Hunks that do not touch are both applied. Hunks that cover the same base lines with the same replacement are applied once. Everything else is a conflict. The manual's wording: "When both sides made changes to the same area, however, Git cannot randomly pick one side over the other".

The unit is the line. A one-word change in a long line conflicts with any other change to that line. And the test is adjacency: one unchanged line between two edits is enough to keep them apart.

**What Git never does.** It never conflicts on meaning. Two changes that are textually far apart and logically incompatible merge without a word.

**When not to use the options.** The textbook is direct: `-X ours` and `-X theirs` turn "Git stopped and asked" into "Git chose and said nothing". They are defensible where one side is correct by construction, as with a regenerated lock file. They are indefensible as a way to make a red merge green.

## MENTAL MODEL

The textbook's analogy for conflicts: two people mark up the same printed page. Marks in different paragraphs can both be typed in. Marks in the same sentence need a conversation.

The analogy breaks at the boundary: Git's unit is the line, and its test is adjacency, not whether the two edits have anything to do with each other. Two unrelated edits on neighbouring lines conflict. Two contradictory edits ten lines apart do not.

For the options, think of a meeting. A normal merge is a meeting where disagreements are put on the table. `-X ours` is a meeting where, on every point of disagreement, your position is adopted without discussion; everything else the other side proposed is accepted. `-s ours` is signing the minutes "meeting held, all proposals considered" without reading a single proposal.

## DIAGRAM

**[DIAGRAM]** A file drawn as numbered lines, with the two sides' changed regions. This is the picture of section 8.7.

```text
  base lines         1    2    3    4    5
  ours changes            #
  theirs changes                         #    far apart: both applied
  theirs changes               #              touches ours: one region, conflict
  theirs changes                    #         one unchanged line between: both applied
```

Five base lines. Ours changes line 2. Three possibilities for theirs. Line 5: far apart, both applied. Line 3: it touches ours; no unchanged line lies between them; one region, changed by both: conflict. Line 4: line 3 is unchanged on both sides, and that one line is enough: both applied.

**[DIAGRAM]** The root-cause box of section 8.7.

```text
Observed behavior : A conflict, although the two branches changed different lines.
Git state         : Ours changed line 2 of the file, theirs changed line 3.
Mechanism         : The merge works on hunks. Two hunks with no unchanged line between them
                    form one region, and that region was changed by both sides.
Root cause        : Adjacency. One unchanged line between the edits (the last transcript)
                    is enough to keep them apart.
Why Git does this : It needs a boundary between "independent" and "the same area", and an
                    unchanged line is the only evidence of independence that text offers.
Correct fix       : Take the changed line from each side: temperature 0.0 and max_tokens 1024.
Prevention        : None needed. Recognize the pattern and resolve it in seconds. Do not reach
                    for -X ours, which would drop their line.
```

**[DIAGRAM]** The root-cause box of section 8.6, after the whitespace demo.

```text
Observed behavior : After git merge -X ignore-space-change, the formatting branch counts as
                    merged, but the file is not reformatted.
Git state         : The merge commit's tree is identical to its first parent's tree.
Mechanism         : With a whitespace option, "if their version only introduces whitespace
                    changes to a line, our version is used" (git-merge manual).
Root cause        : The option does not merge whitespace changes. It discards them
                    wherever they meet a line that our side kept or changed.
Why Git does this : A line cannot carry their indentation and our text at the same time
                    without Git inventing a third version.
Correct fix       : Run the formatter again on the merge result and commit.
Prevention        : Land formatting-only changes when no other branch is open on those files,
                    or have every branch run the same formatter before merging.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch08/strategy-options.sh`.

```bash
labs/run ch08/strategy-options
```

You changed the temperature. Asha changed the temperature and the seed, and added a prompt line.

<!-- snippet: ch08/strategy-options/01-what-differs -->
```text
# ours changed temperature; theirs changed temperature AND seed, and added a prompt line.
$ git diff --stat main...feature/creative-judge
 config/eval.yaml  | 4 ++--
 prompts/judge.txt | 1 +
 2 files changed, 3 insertions(+), 2 deletions(-)
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 7
```
<!-- /snippet -->

Three things to watch after each merge: the temperature, the seed, and the last line of the prompt. Predict all three for `-X ours` 🟡 CAUTION.

<!-- snippet: ch08/strategy-options/02-x-ours -->
```text
$ git merge -X ours feature/creative-judge
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 1234
$ tail -1 prompts/judge.txt
Explain your verdict in one sentence.
```
<!-- /snippet -->

A real three-way merge in which only the conflicting hunk is decided in your favour: the temperature stays 0.0. Her seed and her prompt line arrive.

<!-- snippet: ch08/strategy-options/03-x-theirs -->
```text
$ git merge -X theirs feature/creative-judge
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml  | 4 ++--
 prompts/judge.txt | 1 +
 2 files changed, 3 insertions(+), 2 deletions(-)
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.7
7:seed: 1234
```
<!-- /snippet -->

`-X theirs` 🟡 CAUTION is the mirror image.

Now `-s ours` 🟡 CAUTION. Predict the same three things, and one more: will `git branch --merged` list her branch?

**[PAUSE]**

<!-- snippet: ch08/strategy-options/04-s-ours -->
```text
$ git merge -s ours feature/creative-judge
Merge made by the 'ours' strategy.
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 7
$ tail -1 prompts/judge.txt
Answer with PASS or FAIL.
# The tree of the merge commit is the tree of its first parent:
$ git rev-parse HEAD^{tree} HEAD^1^{tree}
3dfab55ba26e160c0bf7d8f7533173a3d264618f
3dfab55ba26e160c0bf7d8f7533173a3d264618f
# Yet the history says the branch is merged:
$ git branch --merged
  feature/creative-judge
* main
```
<!-- /snippet -->

"Merge made by the 'ours' strategy." No seed change, no prompt line, and the tree of the merge commit is identical to the tree of its first parent. Yet `git branch --merged` lists her branch, because her commits are now ancestors of `main`. The merge recorded ancestry and discarded content.

<!-- snippet: ch08/strategy-options/05-no-s-theirs -->
```text
$ git merge -s theirs feature/creative-judge
Could not find merge strategy 'theirs'.
Available strategies are: octopus ours recursive resolve subtree.
[exit status: 1]
```
<!-- /snippet -->

There is no `-s theirs`. The list of "available strategies" lacks `ort`, because it enumerates helper programs on disk, and `ort` is built into `git merge` itself.

<!-- snippet: ch08/strategy-options/06-recursive -->
```text
$ git merge -s recursive -X ours feature/creative-judge
Auto-merging config/eval.yaml
Merge made by the 'recursive' strategy.
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

And `recursive` still works as a name.

Whitespace. A formatter re-indents a YAML list on one branch, while you rename a metric on `main`.

<!-- snippet: ch08/strategy-options/07-whitespace-conflict -->
```text
$ git merge chore/yaml-format
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat config/eval.yaml
model: judge-large-v2
metrics:
<<<<<<< HEAD
  - exact_match
  - token_f1
=======
    - exact_match
    - f1
>>>>>>> chore/yaml-format
seed: 7
$ git merge --abort
```
<!-- /snippet -->

A conflict. Now with `-X ignore-space-change` 🟡 CAUTION. Predict what the merged file looks like: reformatted or not?

<!-- snippet: ch08/strategy-options/08-ignore-space-change -->
```text
$ git merge -X ignore-space-change chore/yaml-format
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
$ cat config/eval.yaml
model: judge-large-v2
metrics:
  - exact_match
  - token_f1
seed: 7
```
<!-- /snippet -->

The conflict is gone, and so is the reformatting. The merged file has your two-space indentation, and the merge printed no diffstat, because its tree equals your tree.

**[DIAGRAM]** Show the root-cause box of section 8.6.

**[TERMINAL]** Caption bar: `labs/ch08/why-conflicts.sh`.

```bash
labs/run ch08/why-conflicts
```

`git merge-file` 🟢 SAFE with `-p` runs the file-level merge on three ordinary files, with no repository involved, and prints the result. Its exit status is the number of conflicts. Five pairs of edits. For each: conflict, or no conflict?

One. Ours and theirs change lines in different regions.

<!-- snippet: ch08/why-conflicts/01-different-regions -->
```text
$ cat base.yaml
model: judge-large-v2
temperature: 0.2
max_tokens: 512
batch_size: 16
timeout_s: 30
$ sed 's/temperature: 0.2/temperature: 0.0/' base.yaml > ours.yaml
$ sed 's/timeout_s: 30/timeout_s: 60/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 16
timeout_s: 60
[exit status: 0]
```
<!-- /snippet -->

No conflict: both applied.

Two. The same line, different values.

<!-- snippet: ch08/why-conflicts/02-same-line -->
```text
$ sed 's/temperature: 0.2/temperature: 0.7/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
<<<<<<< ours.yaml
temperature: 0.0
=======
temperature: 0.7
>>>>>>> theirs.yaml
max_tokens: 512
batch_size: 16
timeout_s: 30
[exit status: 1]
```
<!-- /snippet -->

A conflict.

Three. The same line, the same value.

<!-- snippet: ch08/why-conflicts/03-same-change -->
```text
$ sed 's/temperature: 0.2/temperature: 0.0/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 16
timeout_s: 30
[exit status: 0]
```
<!-- /snippet -->

None: applied once, exit status 0.

Four, the one that surprises people. Ours changes line 2, theirs changes line 3.

**[PAUSE]**

<!-- snippet: ch08/why-conflicts/04-adjacent-lines -->
```text
# ours changes line 2, theirs changes line 3: no unchanged line between them.
$ sed 's/max_tokens: 512/max_tokens: 1024/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
<<<<<<< ours.yaml
temperature: 0.0
max_tokens: 512
=======
temperature: 0.2
max_tokens: 1024
>>>>>>> theirs.yaml
batch_size: 16
timeout_s: 30
[exit status: 1]
```
<!-- /snippet -->

A conflict, although the two sides changed different lines. No unchanged line lies between them.

Five. Ours changes line 2, theirs changes line 4.

<!-- snippet: ch08/why-conflicts/05-one-line-apart -->
```text
# ours changes line 2, theirs changes line 4: line 3 is unchanged on both sides.
$ sed 's/batch_size: 16/batch_size: 32/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 32
timeout_s: 30
[exit status: 0]
```
<!-- /snippet -->

No conflict. Line 3 is unchanged on both sides, and that is enough.

**[DIAGRAM]** Show the root-cause box of section 8.7.

## COMMON MISTAKES

1. **Using `-s ours` where `-X ours` was meant.** Root cause: one letter; `-s ours` is a different strategy that takes none of the other side's content and still records the merge.
2. **Using `-X ours` or `-X theirs` to make a red merge green.** Root cause: the option decides every conflicting hunk silently, including the ones a human should have decided.
3. **Expecting `-X ignore-space-change` to merge a reformatting.** Root cause: where their change is whitespace only, our version of the line is used, so the reformatting is discarded.
4. **Being surprised by a conflict on "different lines".** Root cause: adjacency; two hunks with no unchanged line between them form one region.
5. **Assuming a clean merge is a correct merge.** Root cause: Git compares lines of text and never conflicts on meaning.

## PRODUCTION EXAMPLE

Some files conflict far more often than others, and the textbook names two kinds that every AI/ML team knows. A Jupyter notebook stores outputs and an execution counter next to the code, so two people who only ran the same notebook have changed the same lines, and a conflicted merge can leave a file that is no longer valid JSON. And append-only files: changelogs, migration lists, dependency lists. Every branch inserts after the same last line, which is the same region.

For the options, the defensible case: a regenerated lock file, where one side is correct by construction. And a reassurance from the textbook: the audit command you will meet in V037 still shows the choice, because it repeats the merge without your options.

## PRACTICE EXERCISE

Do Exercise 6.6, Level 2, "which of three changes conflicts?", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

For each pair of edits, mark the changed base lines of both sides on paper, as in the diagram, and decide from overlap or contact before you run the merge. Write the prediction down first.

## INTERVIEW QUESTION

Q127: "Two branches changed different lines of one file and the merge still conflicted. Give the exact condition under which that happens."

Answer aloud. A strong answer states the condition in terms of hunks and unchanged lines, gives the smallest example of each side of the boundary, and explains why Git draws the boundary there. Say what you would do about such a conflict, and what you would not do.

## RECAP

You should now be able to say: a strategy is the merge algorithm, chosen with `-s`; a strategy option, given with `-X`, adjusts it. `ort` is the default, and `recursive` is now a synonym. `-X ours` and `-X theirs` do a real merge and decide only the conflicting hunks; `-s ours` discards the other side's content entirely and still records the merge; there is no `-s theirs`. A whitespace option uses our version of a line where theirs changed only whitespace. And two edits conflict when they change the same base lines, or lines with no unchanged line between them, unless the changes are identical.

## HOMEWORK

- Read sections 8.6 and 8.7 of [Chapter 8](../../textbook/ch08-merge.md).
- Challenge: Exercise 6.10, Level 5, "the weekly sync that conflicts more every week", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

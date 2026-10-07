# V037: Clean for Git, wrong for humans: auditing a merge, and git merge-tree

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 6, Divergence and merge
- **Planned minutes:** 26
- **Prerequisites:** V036
- **Textbook sections:** [Chapter 8](../../textbook/ch08-merge.md), sections 8.15, 8.16, 8.17 and 8.18
- **Demo scripts:** `labs/ch08/clean-but-wrong.sh`, `labs/ch08/audit-merge.sh`, `labs/ch08/merge-tree.sh`, and as pointers `labs/ch08/revert-one-side.sh` and `labs/ch08/revert-merge-preview.sh`

## HOOK

**[ON SCREEN]** Three questions, one after the other.

Three questions a CTO can ask after an ordinary release week.

One. "Both pull requests were green. `main` is red. The two branches did not touch a single file in common. How?"

Two. "Ravi's retry setting disappeared from the config in a merge commit. `git log -p` shows no diff for that commit. Who removed the line, and how do we prove it?"

Three. "We reverted the bad merge on Friday. On Monday we merged the repaired branch, the merge was clean, and half of the feature is missing. Where did it go?"

None of the three needs a bug in Git. Each follows from what a merge is. This video answers the first two and shows you the mechanism of the third. Keep count. We'll tick them off as we go.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A merge joins another branch's history into yours. This is the last video of the merge module, and it's about the merges that did not stop. A conflict is Git asking for help. A clean merge is Git not asking, and that's the more dangerous case, because nobody looks.

Three parts. First, why "no conflicts" is not "correct", with a merge of two green branches, branches whose checks pass, that fails its check. Second, how to audit a merge commit after the fact. A merge commit is a commit with more than one parent. It stores a tree, one complete snapshot of the files, and no diff, so the default log shows you nothing. Third, `git merge-tree`, which computes a merge without a working tree, that is, without files on disk. That's how you dry-run a merge, and it's how stock Git exposes the strategy to a server.

At the end there are three pointers to later chapters: rerere, reverting a merge, and an option that Git 2.56 adds.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Explain why two green branches can merge without conflict into a broken result.
- Show what a merge resolution changed with `--remerge-diff`.
- Say what `git show` displays for a merge commit and what it hides.
- Compute a merge without a working tree with `git merge-tree`.
- Name the follow-up topics: rerere, reverting a merge, and `git add --resolved` in Git 2.56.

## CONCEPT

Start with the one sentence from section 8.15. A merge without conflicts means that no two text changes overlapped. It says nothing about whether the result builds, passes its tests or makes sense.

Recall the idea from the start of the chapter. A merge is computed from exactly three snapshots, and Git compares lines of text in them. It doesn't know what the lines mean. So there is a class of conflict that Git cannot see by construction: one change depends on another, and the dependency lives outside the text of any one file. The textbook calls these semantic conflicts.

**[ANIMATION]** graph: 68c652c-d1c3cff refactor/mean-score; 68c652c-5008877 feature/leaderboard; d1c3cff-M main; 5008877-M; HEAD=main => + pass:d1c3cff; pass:5008877; mark:not_tested:M; name:tested => + fail:M; name:red title=Two_green_branches,_one_untested_merge id=green dx=430

**[ANIMATION]** step: state-1

Ravi renames a function. Asha, from the same starting commit, adds a new module that calls the old name. Different files, no overlap, clean merge, broken program. Today's demo is that story: `d1c3cff` is the rename, `5008877` is the new caller, and `M` is their merge.

**[ANIMATION]** say: The_quiet_variant:_nothing_fails,_and_the_scores_shift

There is a quiet variant, and it is worse than the loud one. If one branch renames a configuration key and another adds code that reads the old key with a default, nothing fails. An evaluation run uses the default, the scores shift, and the merge that caused it shows no conflict and no red check.

**[ANIMATION]** end

A second way a clean merge surprises people: a change that was made on both sides and reverted on one. You will see it return without a word, and the rule table explains it.

**[ANIMATION]** cards: question=An_evil_merge:_changes_that_appear_in_no_parent cards=a_resolution:that_also_changes_something_outside_the_conflict|an_edit:between_git_merge_--no-commit_and_the_commit|git_commit_--amend:on_a_merge at_1=42 at_2=58 at_3=72

**[ANIMATION]** step: 3

Then the term "evil merge". The glossary definition is: an evil merge is a merge that introduces changes that do not appear in any parent. It happens through a resolution that also changes something outside the conflict, through an edit between `git merge --no-commit` and the commit, or through `git commit --amend` on a merge. The name is harsher than the practice. Fixing a semantic conflict inside the merge commit is such a change, and it keeps every mainline commit green. `git bisect`, the search for the commit that changed something, needs that. The cost is visibility.

**[ANIMATION]** end

Which brings you to auditing. A merge commit stores a tree and no diff, so "what did this merge do" has to be computed, and Git offers three computations that answer three different questions.

**[ON SCREEN]** The table of section 8.16.

```text
View               Command                              Shows                               Blind to
-----------------  -----------------------------------  ----------------------------------  ------------------------------
default log        git log -p                           no diff at all for merge commits    everything a merge did
first-parent diff  git show --first-parent M            everything the merge brought to     which part is branch content
                   git diff M^1 M                       the mainline                        and which is hand-made
combined diff      git show M  (the --cc format)        lines that differ from every        resolutions that took one
                                                        parent                              side unchanged
remerge diff       git show --remerge-diff M            difference between a mechanical     octopus merges, which it
                   git log --merges --remerge-diff      re-merge and the recorded result    skips
```

The remerge diff is the one to remember. Git repeats the merge into a temporary tree, conflict markers included, and diffs that tree against the recorded one. Read it as "what a human did after Git stopped".

**[ANIMATION]** stores: boxes=*object_database:all_that_merge-tree_uses|everything_else:not_touched rows=1:A:the_same_strategy_as_git_merge|1:B:no_index@dim|1:B:no_working_tree@dim|1:B:no_ref_update@dim|2:A:writes_the_resulting_tree@hl|2:A:prints_the_tree_ID|3:A:exit_status_0:_clean@ok|3:A:exit_status_1:_conflict@bad title=git_merge-tree_--write-tree at_1=25 at_2=80

**[ANIMATION]** step: 3

Finally `git merge-tree --write-tree`. It performs a real merge with the same strategy as `git merge`, using only the object database, Git's store of all objects: no index, no working tree and no ref update. It prints the ID of the resulting tree. Its exit status is 0 for a clean merge and 1 for a conflict. It creates objects and changes nothing else, so it works in a bare repository, where `git merge` cannot run. A bare repository is one with no working tree, like the one on a server.

## MENTAL MODEL

**[ON SCREEN]** "Git checks one property: the overlap of changed lines."

A picture helps. The textbook's analogy: a spell-checker passes two paragraphs that contradict each other, because every word is spelled correctly. A clean merge is a document that passed the spell-checker.

Where it breaks: only in degree. Git checks even less than a spell-checker does. It checks one property, the overlap of changed lines. It has no parser, no type checker and no test runner, for any language.

Try it now. Thirty seconds, on paper. Draw two branch tips and the merge commit that joins them. Tick every commit whose tree somebody tested. Which one has no tick? Say it out loud.

**[PAUSE]**

**[ANIMATION]** step: green.tested

The merge has no tick. So the model for the rest of your career: a merge commit is a new tree that nobody has tested. Each parent was tested. The merge result was not, unless you arranged for it. And a merge commit is a change in its own right, which deserves a review, with a tool that can show it.

## DIAGRAM

**[ANIMATION]** step: green.red

**[DIAGRAM]** New diagram. Draw the base, the two branches, mark each tip as passing, then close the merge and mark it as failing.

```text
              d1c3cff   refactor/mean-score     check: pass
             /       \
  68c652c---+         M   main                  check: FAIL
             \       /
              5008877   feature/leaderboard     check: pass

  tested: each parent's tree          not tested: the tree of M
  paths changed:  metrics.py, report.py   |   leaderboard.py      (nothing in common)
```

Here's your drawing with today's commits. Each tip passes its check, and `M` fails.

**[DIAGRAM]** Then the root-cause box of section 8.15, one line at a time, after the `no-path-in-common` snippet.

```text
Observed behavior : Two green branches, a merge without conflict, a red merge commit.
Git state         : The sides changed disjoint paths: metrics.py and report.py on one,
                    leaderboard.py on the other.
Mechanism         : By the rule table, a path changed on one side only is taken as it is.
                    No file-level merge ran. There was nothing for Git to compare.
Root cause        : The dependency between the two changes, a renamed function and a new
                    caller of the old name, lives in the Python import system, not in the
                    text of any one file.
Why Git does this : Git merges snapshots of text. It has no parser, no type checker and no
                    test runner, for any language.
Correct fix       : Update the caller, in a commit on top of the merge (below) or inside the
                    merge commit (see "Evil merges").
Prevention        : Test the merge result before it reaches main: CI on the pull request's
                    merge commit, plus a rule that the branch is up to date with main, or a
                    merge queue (Chapter 18).
```

And the root-cause box for the first question. It comes back in the demo.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch08/clean-but-wrong`. A shell script, `ci/check_imports.sh`, stands in for the test suite: it fails when a module imports a name that `metrics.py` does not define.

**Part 1: clean and wrong.** Two branches from the same commit. `git merge` 🟡 CAUTION, twice.

<!-- snippet: ch08/clean-but-wrong/01-both-merge-cleanly -->
```text
$ git log --oneline --graph --all
* 5008877 Add a leaderboard ranked by accuracy
| * d1c3cff Rename accuracy() to mean_score()
|/  
* 68c652c Add the report module and the import check
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge -q refactor/mean-score
$ git merge feature/leaderboard
Merge made by the 'ort' strategy.
 evalkit/leaderboard.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 evalkit/leaderboard.py
```
<!-- /snippet -->

Both merge without a conflict. Predict the result of the check. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch08/clean-but-wrong/02-check-fails -->
```text
$ sh ci/check_imports.sh
FAIL evalkit/leaderboard.py imports accuracy, which evalkit/metrics.py does not define
[exit status: 1]
```
<!-- /snippet -->

It fails: the leaderboard imports `accuracy`, which `metrics.py` no longer defines. Now the same check on each parent of the merge commit.

<!-- snippet: ch08/clean-but-wrong/03-parents-pass -->
```text
# The same check on each parent of the merge commit:
$ git switch -q --detach main^1 && sh ci/check_imports.sh
OK every import from evalkit.metrics resolves
$ git switch -q --detach main^2 && sh ci/check_imports.sh
OK every import from evalkit.metrics resolves
$ git switch -q main
```
<!-- /snippet -->

Both parents pass. The merge fails. List what each side changed since the merge base.

<!-- snippet: ch08/clean-but-wrong/04-no-path-in-common -->
```text
# Paths each side changed since the merge base:
$ git diff --name-only main^2...main^1
evalkit/metrics.py
evalkit/report.py
$ git diff --name-only main^1...main^2
evalkit/leaderboard.py
```
<!-- /snippet -->

No path in common. By the rule table, a path changed on one side only is taken as it is. No file-level merge ran. There was nothing for Git to compare.

**[DIAGRAM]** Show the root-cause box.

That's question one, answered. The repair is a normal, reviewable commit on top of the merge.

<!-- snippet: ch08/clean-but-wrong/05-fix -->
```text
# The repair is a normal, reviewable commit on top of the merge.
$ git diff --stat
 evalkit/leaderboard.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git commit -q -a -m "Use mean_score() in the leaderboard"
$ sh ci/check_imports.sh
OK every import from evalkit.metrics resolves
```
<!-- /snippet -->

**Part 2: changed on both sides, reverted on one.** `labs/run ch08/revert-one-side`, as a pointer. A fix, `max_tokens` 2048, was applied to `main` and to a branch. `main` then reverted it, for a good reason.

<!-- snippet: ch08/revert-one-side/01-history -->
```text
$ git log --oneline --graph --all
* a2a0277 Revert "Allow long answers: max_tokens 2048"
* 523ed40 Allow long answers: max_tokens 2048
| * 4fac9ee Ask for full sentences
| * c8e320d Allow long answers: max_tokens 2048
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ grep max_tokens config/eval.yaml
max_tokens: 512
```
<!-- /snippet -->

`main` says 512. Predict the value after merging the branch.

**[PAUSE]**

<!-- snippet: ch08/revert-one-side/02-merge -->
```text
$ git merge feature/long-answers
Merge made by the 'ort' strategy.
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ grep max_tokens config/eval.yaml
max_tokens: 2048
```
<!-- /snippet -->

The value is 2048. The reverted change is back, without a conflict and without a message.

<!-- snippet: ch08/revert-one-side/03-three-inputs -->
```text
# base, ours, theirs, result:
$ git show $(git merge-base HEAD^1 HEAD^2):config/eval.yaml | grep max_tokens
max_tokens: 512
$ git show HEAD^1:config/eval.yaml | grep max_tokens
max_tokens: 512
$ git show HEAD^2:config/eval.yaml | grep max_tokens
max_tokens: 2048
$ git show HEAD:config/eval.yaml | grep max_tokens
max_tokens: 2048
```
<!-- /snippet -->

**[ANIMATION]** merge: three-way feature/long-answers into main common=6ae3c51 main_only=523ed40,a2a0277 feature_only=c8e320d,4fac9ee title=The_three_inputs_of_that_merge steps=setup,merge-base say_merge_base=Base_512,_ours_512,_theirs_2048

Base 512, ours 512, theirs 2048: the row "only theirs changed it". The apply-then-revert pair on `main` cancels out, and the merge never sees it. On screen, the merge base is `6ae3c51` and the two tips are `a2a0277` and `4fac9ee`. Nothing in the rule looks at `523ed40`. The manual describes this behavior and admits that some people find it confusing. If the revert must win, say so in the tree that the merge will see: revert the change on the branch too before merging.

**Part 3: auditing.** `labs/run ch08/audit-merge`. The history has three merges. One conflict resolved by keeping our temperature. One clean merge in which somebody also set `retries` to 0, a line that neither branch touched. And one honest clean merge. All commands in this part are 🟢 SAFE: they read.

```bash
git log -1 -p --format='%h %s' fc83756
```

Predict what `git log -p` prints for a merge commit.

**[PAUSE]**

<!-- snippet: ch08/audit-merge/01-log-p-is-blind -->
```text
$ git log --oneline --first-parent -5
9a6385a Merge branch 'topic/max-tokens'
fc83756 Merge branch 'topic/docs'
8353ff1 Add requirements
70bae5f Merge branch 'feature/creative-judge'
5397d5f Use temperature 0 for reproducible evals
# By default git log shows no diff for a merge commit, with -p or with --stat:
$ git log -1 -p --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'
$ git log -1 --stat --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'
```
<!-- /snippet -->

The subject line and nothing else, with `-p` and with `--stat`. By default `git log` shows no diff for a merge commit. That is the "no diff" of the CTO's second question.

`git show` uses the dense combined format for merges. Quick quiz. `70bae5f` is the merge with the hand-resolved conflict. Will `git show` print that resolution? A, yes. B, no. Your answer?

**[PAUSE]**

<!-- snippet: ch08/audit-merge/02-show-combined -->
```text
# git show uses the dense combined format (--cc) for merges.
$ git show --format='%h %s' 70bae5f
70bae5f Merge branch 'feature/creative-judge'

$ git show --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'

diff --cc config/eval.yaml
index 1642b99,1642b99..29fd375
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@@ -3,5 -3,5 +3,5 @@@ temperature: 0.
  max_tokens: 512
  batch_size: 16
  timeout_s: 30
--retries: 2
++retries: 0
  seed: 1234
```
<!-- /snippet -->

It's B. For `70bae5f`, the merge with the hand-resolved conflict, `git show` prints nothing. If you said yes, that's the natural guess. The dense combined format omits hunks where the result equals one of the parents, and that resolution took our side exactly. For `fc83756` it shows the smuggled line, with two minus signs and two plus signs, because the result differs from both parents.

Now the remerge diff.

```bash
git log --merges --remerge-diff --format='== %h %s'
```

<!-- snippet: ch08/audit-merge/03-remerge-diff -->
```text
$ git log --merges --remerge-diff --format='== %h %s'
== 9a6385a Merge branch 'topic/max-tokens'
== fc83756 Merge branch 'topic/docs'

diff --git a/config/eval.yaml b/config/eval.yaml
index 1642b99..29fd375 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -3,5 +3,5 @@ temperature: 0.0
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
-retries: 2
+retries: 0
 seed: 1234
== 70bae5f Merge branch 'feature/creative-judge'

diff --git a/config/eval.yaml b/config/eval.yaml
remerge CONFLICT (content): Merge conflict in config/eval.yaml
index 2c6727a..1642b99 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -1,9 +1,5 @@
 model: judge-large-v2
-<<<<<<< 5397d5f (Use temperature 0 for reproducible evals)
 temperature: 0.0
-=======
-temperature: 0.7
->>>>>>> 45a7a67 (Ask the judge for a rationale)
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
```
<!-- /snippet -->

Three merges, three readings. `9a6385a`: no output, so the merge is exactly what Git computes on its own. `70bae5f`: removed marker lines with one candidate kept. That's a resolution, and you can see which side won. `fc83756`: a change with no markers nearby. It came from neither branch. This is the view that answers the second question.

The first-parent view answers the other question, "what did `main` receive".

<!-- snippet: ch08/audit-merge/04-first-parent -->
```text
# Everything a merge brought to main, as one ordinary diff against its first parent:
$ git show --first-parent --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'

diff --git a/README.md b/README.md
new file mode 100644
index 0000000..e8fdfb1
--- /dev/null
+++ b/README.md
@@ -0,0 +1 @@
+# evalkit
diff --git a/config/eval.yaml b/config/eval.yaml
index 1642b99..29fd375 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -3,5 +3,5 @@ temperature: 0.0
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
-retries: 2
+retries: 0
 seed: 1234
```
<!-- /snippet -->

The README from the branch and the `retries` line, as one ordinary diff. This view cannot tell you which part is branch content and which is hand-made. The remerge diff can.

Two limits from the textbook. The remerge diff repeats the merge with default settings, so a merge made with `-X ours` or `-s ours` shows up as a diff, however clean it looked when it was made. And it needs Git 2.36 or later, handles two-parent merges only, and its output format is declared "subject to change" by the manual. Read it. Don't parse it.

**Part 4: `git merge-tree`.** `labs/run ch08/merge-tree`. A bare clone stands in for a server.

<!-- snippet: ch08/merge-tree/01-bare -->
```text
$ git clone -q --bare evalkit server.git
$ cd server.git
$ git rev-parse --is-bare-repository
true
$ git log --oneline --graph --all
* 7c974a2 Add a README
| * 5397d5f Use temperature 0 for reproducible evals
|/  
| * 45a7a67 Ask the judge for a rationale
| * 640bfe1 Raise temperature and reseed for judge diversity
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge docs/readme
fatal: this operation must be run in a work tree
[exit status: 128]
```
<!-- /snippet -->

`git merge` refuses: this operation must be run in a work tree. `git merge-tree --write-tree` 🟢 SAFE: it adds unreferenced objects and nothing else.

<!-- snippet: ch08/merge-tree/02-clean -->
```text
$ git merge-tree --write-tree main docs/readme
0c05f61e275e97d119913a164e7312d48cd50d66
[exit status: 0]
$ tree=$(git merge-tree --write-tree main docs/readme)
$ git ls-tree -r --abbrev=7 $tree
100644 blob af7f9b5	README.md
100644 blob 0e8b97c	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob cfe0ef0	prompts/judge.txt
```
<!-- /snippet -->

One line of output, a tree ID, and exit status 0. A tree is not a commit. Two more plumbing commands, the low-level kind that do one operation each, turn it into a merge and publish it.

<!-- snippet: ch08/merge-tree/03-commit -->
```text
$ commit=$(git commit-tree $tree -p main -p docs/readme -m "Merge branch 'docs/readme'")
$ git update-ref refs/heads/main $commit
$ git log --oneline --graph -4 main
*   40fb5aa Merge branch 'docs/readme'
|\  
| * 7c974a2 Add a README
* | 5397d5f Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

**[ANIMATION]** graph: 6ae3c51-5397d5f main; ^6ae3c51-7c974a2 docs/readme; 6ae3c51-640bfe1-45a7a67 feature/creative-judge; HEAD=main => 6ae3c51-5397d5f-40fb5aa main; 6ae3c51-7c974a2 docs/readme; 7c974a2-40fb5aa; 6ae3c51-640bfe1-45a7a67 feature/creative-judge; HEAD=main title=A_merge_without_a_working_tree dx=260

**[ANIMATION]** step: state-2

A merge commit with two parents, `40fb5aa`, made without a working tree. Now a conflicting pair, `main` and `feature/creative-judge`. Predict the exit status, and whether a tree is written.

**[PAUSE]**

<!-- snippet: ch08/merge-tree/04-conflict -->
```text
$ git merge-tree --write-tree main feature/creative-judge
9615415b8675a4fb67a61eb8a37e816decd78066
100644 c5b33275d88c041381cff59f23d3cd88b9f22c98 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 3	config/eval.yaml

Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
[exit status: 1]
```
<!-- /snippet -->

Exit status 1, the three stage entries that `git merge` would have put into the index, and the messages. The tree is still written.

<!-- snippet: ch08/merge-tree/05-conflict-tree -->
```text
$ tree=$(git merge-tree --write-tree main feature/creative-judge | head -1)
$ git show $tree:config/eval.yaml | head -6
model: judge-large-v2
<<<<<<< main
temperature: 0.0
=======
temperature: 0.7
>>>>>>> feature/creative-judge
```
<!-- /snippet -->

It contains the file with markers, labelled with the names from the command line.

<!-- snippet: ch08/merge-tree/06-quiet -->
```text
# A yes/no answer for a "can this be merged?" indicator:
$ git merge-tree --quiet main feature/creative-judge
[exit status: 1]
$ git merge-tree --write-tree --name-only --no-messages main feature/creative-judge
9615415b8675a4fb67a61eb8a37e816decd78066
config/eval.yaml
[exit status: 1]
```
<!-- /snippet -->

`--quiet` gives a yes or no through the exit status. `--name-only` lists the conflicted files. Decide by the exit status, as the manual warns, not by whether the list of conflicted files is empty.

**Part 5: a pointer to the third question.** `labs/run ch08/revert-merge-preview`. `git revert` 🟡 refuses a merge commit until you say which parent is the mainline. A revert adds a new commit whose change is the opposite of an earlier one.

<!-- snippet: ch08/revert-merge-preview/01-revert -->
```text
$ git log --oneline --graph
*   821b8ff Merge branch 'feature/rationale'
|\  
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
* | c089834 Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git revert --no-edit HEAD
error: commit 821b8ff2e4e35c648578cd9e11514117ae0fd1b9 is a merge but no -m option was given.
fatal: revert failed
[exit status: 128]
$ git revert --no-edit -m 1 HEAD
[main 504ae98] Revert "Merge branch 'feature/rationale'"
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 deletions(-)
$ cat prompts/judge.txt
You are a strict grader.
Answer with PASS or FAIL.
```
<!-- /snippet -->

**[ANIMATION]** graph: 6ae3c51-c089834-821b8ff main; ^6ae3c51-5aec6e0-58a5e60 feature/rationale; 58a5e60-821b8ff; HEAD=main => 6ae3c51-c089834-821b8ff-504ae98 main; 6ae3c51-5aec6e0-58a5e60-b752dc4 feature/rationale; 58a5e60-821b8ff; HEAD=main => + 504ae98-?second_merge main; b752dc4-?second_merge; note:58a5e60:the_merge_base title=Content_undone,_ancestry_kept id=revert dx=260

**[ANIMATION]** step: state-1

`-m 1` creates a commit that undoes the difference between the merge and its first parent. It undoes content. It cannot undo ancestry.

**[ANIMATION]** step: state-2

That commit is `504ae98`. Now Asha adds one more commit, `b752dc4`, and the branch is merged again. Predict what arrives. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch08/revert-merge-preview/02-remerge -->
```text
$ git log --oneline main..feature/rationale
b752dc4 Give the judge 60 seconds for longer answers
$ git merge feature/rationale
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# The timeout arrived. The two prompt lines of the first merge did not come back:
$ grep timeout_s config/eval.yaml
timeout_s: 60
$ cat prompts/judge.txt
You are a strict grader.
Answer with PASS or FAIL.
$ git branch --merged
  feature/rationale
* main
```
<!-- /snippet -->

Only the new commit arrived. The timeout is 60, and the two prompt lines of the first merge did not come back.

**[ANIMATION]** step: revert.state-3

The graph says why. Their commits, `5aec6e0` and `58a5e60`, are ancestors of `main` already, and the merge base is past them. That is the third question. The repair is in Chapter 11, and it has its own video.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Treating "merged without conflicts" as "tested".** Root cause: Git merges snapshots of text and checks only the overlap of changed lines; each parent was tested, the merge tree was not.
2. **Reading `git log -p` and concluding that a merge changed nothing.** Root cause: by default `git log` shows no diff at all for merge commits.
3. **Trusting an empty `git show` on a merge.** Root cause: the dense combined format omits hunks where the result equals one parent, so a resolution that took one side unchanged is invisible.
4. **Expecting a revert on `main` to win over the same change on an unmerged branch.** Root cause: the apply-then-revert pair cancels out between base and ours, so the rule table sees "only theirs changed it".
5. **Deciding "can this be merged" from the list of conflicted files.** Root cause: the manual tells you to decide by the exit status of `git merge-tree`, not by whether that list is empty.

## PRODUCTION EXAMPLE

**[ON SCREEN]** `git log --merges --remerge-diff --first-parent <last-release>..main`

Now, out of the lab. An LLM evaluation team prepares a release. Scores on the regression suite moved slightly and nobody can say why. Every pull request since the last release was green.

**[ANIMATION]** cards: question=One_command_over_every_merge_since_the_last_release cards=most_merges:print_nothing|one_merge:a_resolution_in_the_evaluation_config|one_merge:a_change_with_no_markers_nearby marks=3:ring at_1=42 at_2=50 at_3=58

The release engineer runs one command: `git log --merges --remerge-diff --first-parent` over the range from the last release to `main`. It lists every hand-made change in every merge since the last release. Most merges print nothing. One prints a resolution in the evaluation config, and one prints a change with no markers nearby. That is where the review starts. Lab 6.6 uses the same command to find a merge where a whole-file `--theirs` deleted a teammate's retry setting.

**[ANIMATION]** step: green.red

The prevention is in the root-cause box: test the merge result before it reaches `main`.

**[ON SCREEN]** Layer label: GitHub.

Across the layer boundary: a server has no working tree to merge in. GitHub's engineering blog lists "It can't check out the repository" among its requirements for a merge implementation, and its changelog states that when GitHub creates merge commits, to test whether a pull request can be merged cleanly or to actually merge it, it uses the `merge-ort` strategy. Neither page says which command GitHub runs. `git merge-tree` is how stock Git exposes the same strategy without a working tree. This is described from GitHub's publications and was not run here. One documented consequence: workflows will not run on `pull_request` activity if the pull request has a merge conflict.

**[ANIMATION]** cards: cards=rerere:reuse_recorded_resolution,_Chapter_14C|reverting_a_merge:Chapter_11|git_add_--resolved:added_in_Git_2.56,_not_run_here title=Three_pointers at_1=5 at_2=45 at_3=55

And the three pointers. rerere, "reuse recorded resolution", remembers how you resolved a conflict and replays the resolution when the identical conflict appears again. It's off until you set `rerere.enabled`, and Chapter 14C covers it. Reverting a merge is Chapter 11. And `git add --resolved` was added in Git 2.56, not run here: according to the 2.56 documentation it stages unmerged paths where no conflict markers remain in the working tree, and any path with leftover markers causes the command to refuse to stage any files.

## PRACTICE EXERCISE

Your turn. Do Lab 6.5, "A clean merge that breaks the build", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md).

Predict first:

- Will either merge stop? On what do you base that?
- Which paths did each side change since the merge base? Write the two lists before you run the command.
- On which of the three commits, the two parents and the merge, does the check pass?

The challenge is Incident 9, [`incidents/09-misunderstood-conflict`](../../incidents/09-misunderstood-conflict/SYMPTOMS.md). Read the symptoms file only, and work from the repository.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q122: "Why can Git merge two files incorrectly from a human perspective?"

**[PAUSE]**

Answer out loud first. A strong answer starts from what a merge takes as input and what single property it checks, and it says what Git does not have. It gives at least one concrete example where the two changes are in different files, and ideally the quiet kind where nothing fails. It then moves from cause to control: where in the delivery process the merged result gets tested, and how a merge can be audited afterwards. Stop there. Don't turn it into a list of commands.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: green.red

A merge without conflicts means only that no two text changes overlapped. Two green branches can produce a red merge when one change depends on the other through something Git does not read, so the merge result itself has to be tested.

**[ANIMATION]** step: revert.state-3

`git log -p` shows nothing for a merge, `git show` hides resolutions that took one side unchanged, and `--remerge-diff` shows what a human did after Git stopped. `git merge-tree --write-tree` computes a merge from the object database alone and reports the outcome through its exit status. Reverting a merge undoes content and not ancestry, which is why a later merge of the same branch brings only the new commits.

## HOMEWORK

Read sections 8.15 to 8.21 of [Chapter 8](../../textbook/ch08-merge.md), and do the Practice section 8.23, including Lab 6.6, "Audit merges with `--remerge-diff`", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md).

That's the merge module, complete. You can explain a clean merge that's wrong, audit a merge commit, and compute a merge without a working tree. Do Lab 6.5 while this is fresh. Next time we leave your machine: remotes, and `git clone`. Until then, look at the state first and type second. See you in the next one.

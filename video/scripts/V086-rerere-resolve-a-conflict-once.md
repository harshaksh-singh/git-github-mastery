# V086: Rerere: resolve a conflict once

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 24
- **Prerequisites.** V057, V085
- **Textbook sections.** [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), section 14C.3
- **Demo scripts.** `labs/ch14c/rerere-merge.sh`, `labs/ch14c/rerere-rebase.sh`, `labs/ch14c/rerere-wrong.sh`, `labs/ch14c/rerere-lock.sh`, `labs/ch14c/rerere-lock-race.sh`

## HOOK

**[ON SCREEN]** "The team switched on rerere because one conflict came back at every rebase. Last week a wrong value reached `main` without anyone typing it. How?"

The team did something reasonable. A long-lived branch conflicted with `main` on the same two lines of a configuration file, at every rebase. A conflict is Git stopping because both sides changed the same lines. Resolving the same one by hand for the tenth time is how mistakes are made. Rerere removes that work.

Then one day somebody resolved that conflict in a hurry, and wrongly. From that moment Git wrote the wrong answer into the file at every later rebase, with the same calm output it prints for a right answer. With one extra setting it also staged it. A wrong value was one `git rebase --continue` away from being a commit, and nobody typed it.

Rerere replays a recorded resolution whenever the same conflict text appears, a wrong one as faithfully as a right one.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You know conflicts from the merge module, and you know that in a rebase the sides are swapped. Today you add a feature that sits beside conflict resolution and is entirely local: it lives in `.git/rr-cache`, which is never pushed, fetched or cloned.

**[ANIMATION]** graph: d9ec3c5-96196ef main; d9ec3c5-c9ca15a-62e40dc feature/rerank; HEAD=feature/rerank => 62e40dc-047a898 feature/rerank; 96196ef-047a898; 96196ef main; HEAD=feature/rerank => 62e40dc feature/rerank; 96196ef main; HEAD=feature/rerank; reflog:047a898 => 96196ef-cad2174 main; 62e40dc-cad2174; 62e40dc feature/rerank; HEAD=main; reflog:047a898 title=A_test_merge,_thrown_away,_then_the_real_merge

**[ANIMATION]** step: state-2

You'll watch one resolution being recorded in a throw-away test merge.

**[ANIMATION]** step: state-4

Then the test merge is thrown away, and the record is replayed in the real merge, in the opposite direction. And replayed again in a rebase.

**[ANIMATION]** end

Then the wrong-resolution case and its repair. And last, a failure that the authors of this course ran into while writing the chapter: a lock race between rerere and automatic maintenance on Git 2.55.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- say what rerere records and at which moment;
- show a recorded resolution being replayed in a later merge and in a rebase;
- forget a wrong recorded resolution and record a correct one;
- explain why a replayed resolution still has to be reviewed and tested;
- explain the lock failure on Git 2.55 and the setting that prevents it.

## CONCEPT

In one sentence: with `rerere.enabled` set, Git records the text of every conflict together with what you made of it, and when a conflict with the same text appears again, in any merge, rebase, cherry-pick, revert or `git am -3`, it writes your earlier resolution into the file instead of the conflict markers.

"Rerere" stands for "reuse recorded resolution". The commands that can stop on a conflict call `git rerere` for you, so you rarely type it. It works in two moments.

**[ANIMATION]** stores: id=rr title=Two_moments,_two_files boxes=retrieval.yaml:the_file_in_your_working_tree|*.git/rr-cache/<id>/:local,_never_pushed rows=1:A:<<<<<<<_a_conflict_>>>>>>>@bad|1:B:preimage|2:A:your_resolution@ok|2:B:postimage|3:A:the_same_conflict_again:_the_same_<id>@bad|4:A:your_resolution,_index_still_unmerged@ok arrows=1:A1>B1:normalize,_hash|2:A2>B2:|3:A3>B1:|4:B2>A4:3-way_merge at_1=10

**[ANIMATION]** step: 1

Moment one: when a conflict appears. Git normalizes the conflict in each file. Labels are stripped from the markers, the two sides are sorted, and the base part of `diff3` output is removed.

**[ANIMATION]** hash: differs=byte steps=one,same left=in_the_test_merge right=in_the_real_merge lines=top__k:_20,rerank:_false,=======,top__k:_50,rerank:_true ids=ec4b299,ec4b299 fn=hash title=The_normalized_conflict_names_the_record same=Same_conflict_text,_same_ID:_the_record_is_found_again

**[ANIMATION]** step: one

It hashes the conflict hunks and uses the hash as the name of a directory in `.git/rr-cache`. If there is no recorded resolution there, it stores the normalized conflict as `preimage` and prints "Recorded preimage".

**[ANIMATION]** step: rr.4

If there is one, it merges the old conflict, the old resolution and the new conflict, and when that merge is clean it writes the result into your file and prints "Resolved ... using previous resolution".

**[ANIMATION]** say: Moment_two:_the_resolved_file_is_stored_as_postimage

Moment two: when you conclude. At the commit, or at `git rebase --continue`, Git stores the resolved file as `postimage` and prints "Recorded resolution".

**[ANIMATION]** step: hash.same

The normalization is why one record serves both directions of a merge, and a merge as well as a rebase. The name depends on the two competing texts. It doesn't depend on branch names, on who is "ours", or on the path.

**[ANIMATION]** trees: file=retrieval.yaml steps=setup,edit,add chips=conflict_markers,stages_1_2_3,the_last_commit versions=conflict_markers,recorded_resolution,another_edit ref=main commits=96196ef,cad2174 title=A_replay_writes_the_file_only say_setup=A_conflict:_markers_in_the_file,_three_stages_in_the_index say_edit=rerere_writes_the_recorded_resolution_into_the_file._Nothing_else. say_add=You_review,_then_git_add._Only_now_is_the_index_resolved.

**[ANIMATION]** step: add

One property decides how safe the feature is. Rerere leaves the index alone. A replayed file stays unmerged, with three versions still in the index, until you `git add` it, unless `rerere.autoUpdate` is true.

**[ANIMATION]** step: rr.4

**[ANIMATION]** say: MERGE__RR_maps_the_conflicted_paths_to_conflict_IDs

Inside the dot git folder: `rr-cache/<conflict-id>/preimage` and `postimage`. A file `MERGE_RR`, which maps the conflicted paths of the operation in progress to conflict IDs. And, briefly, `MERGE_RR.lock`. `git rerere gc` prunes unresolved records after 15 days and resolved ones after 60.

**[ANIMATION]** end

When to use it: for people who rebase long branches or rebuild integration branches. When not: don't turn on `rerere.autoUpdate` unless tests run before every `--continue`. The stop with `UU` is the only review a replay gets. And know the limits: records are per clone, they expire, and a conflict whose text has changed is a new conflict.

## MENTAL MODEL

**[ANIMATION]** step: rr.4

**[ANIMATION]** say: Left_page:_the_preimage._Right_page:_the_postimage

The textbook's analogy: a notebook next to the merge desk, each page with a conflict on the left and your answer on the right. When the same left side turns up, Git copies the right side into the file.

**[ANIMATION]** say: It_matches_text,_not_intent,_and_it_never_asks

The analogy breaks where the danger is. The notebook matches text, not intent, and it never asks before it copies.

**[ANIMATION]** step: hash.same

**[ANIMATION]** say: A_canonical_form:_the_same_page,_whichever_branch_you_are_on

Two refinements. The left side of each page is written in a canonical form: no branch labels, the two sides in sorted order. That is why the same page matches whichever branch you happen to be on. And the notebook is yours alone. A colleague's clone has a different notebook, or none.

## DIAGRAM

Try it now, on paper. Write the two moments, and next to each, the file rerere writes. Pause me for thirty seconds and write your answer.

**[PAUSE]**

**[DIAGRAM]** The picture of section 14C.3. Three columns, built left to right.

```text
   conflict appears              you resolve and commit        the same conflict again
   file: <<<<<<< ... >>>>>>>     file: your resolution         file: <<<<<<< ... >>>>>>>
          | normalize, hash             |                             | normalize, hash: same <id>
          v                             v                             v
   rr-cache/<id>/preimage        rr-cache/<id>/postimage       3-way merge of preimage, postimage, new conflict
                                                                      |
                                                                      v
                                                               file: your resolution (index still unmerged)
```

Column one writes the left page, the preimage. Column two writes the right page, the postimage. Column three finds the same page by its hash and copies the answer into the file. Read the last line of column three twice: the file is resolved, and the index is still unmerged.

**[DIAGRAM]** The store as pairs, with one merge writing a pair and a later rebase reading it.

```text
   .git/rr-cache/                                (local: never pushed, fetched or cloned)
     ec4b299.../   preimage  ->  postimage
          ^   written by: test merge of main into feature/rerank
          |
          +-- read by:    real merge of feature/rerank into main    (sides the other way round)
          +-- read by:    rebase of feature/rerank onto main        (sides swapped)
```

One record, written in the test merge and read in the real merge. In a moment you'll see a rebase read it too.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14c/rerere-merge`. `feature/rerank` is a long-lived branch. It and `main` changed the same two lines of `retrieval.yaml`. You want to test the branch against the newest `main` today and merge it for real next week, without a test merge in its history.

**[ON SCREEN]** 🟡 CAUTION: `git config set rerere.enabled true` writes one key into `.git/config` and changes what later conflict stops do. The form needs Git 2.46 or later. The lab repositories also set `maintenance.rerere-gc.auto=0`; you will see why at the end.

```bash
git config set rerere.enabled true
git switch -q feature/rerank
git merge main
```

<!-- snippet: ch14c/rerere-merge/01-first-conflict -->
```text
$ git log --oneline --graph --all
* 96196ef Raise top_k to 20
| * 62e40dc Add reranker module
| * c9ca15a Enable reranking over the top 50 candidates
|/  
* d9ec3c5 Add retrieval config
$ git config set rerere.enabled true
$ git switch -q feature/rerank
$ git merge main
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
Recorded preimage for 'retrieval.yaml'
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

An ordinary conflict, plus one new line: "Recorded preimage for 'retrieval.yaml'". Look at what was recorded.

```bash
ls .git/rr-cache
cat .git/rr-cache/*/preimage
```

<!-- snippet: ch14c/rerere-merge/02-recorded -->
```text
$ ls .git/rr-cache
ec4b2990356a9f0ab0af396e6ce888496e91b4c7
$ cat .git/rr-cache/*/preimage
model: bge-small
<<<<<<<
top_k: 20
rerank: false
=======
top_k: 50
rerank: true
>>>>>>>
$ cat retrieval.yaml
model: bge-small
<<<<<<< HEAD
top_k: 50
rerank: true
=======
top_k: 20
rerank: false
>>>>>>> main
$ git rerere status
retrieval.yaml
```
<!-- /snippet -->

The directory name is the conflict ID. The preimage has bare markers and the two sides in sorted order, `top_k: 20` first, although your file shows HEAD first. Resolve as usual.

```bash
printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
git rerere diff
```

<!-- snippet: ch14c/rerere-merge/03-resolve -->
```text
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
$ git rerere diff
--- a/retrieval.yaml
+++ b/retrieval.yaml
@@ -1,8 +1,3 @@
 model: bge-small
-<<<<<<<
-top_k: 20
-rerank: false
-=======
 top_k: 50
 rerank: true
->>>>>>>
$ git commit -am "Test merge of main"
Recorded resolution for 'retrieval.yaml'.
[feature/rerank 047a898] Test merge of main
$ ls .git/rr-cache/*
postimage
preimage
$ cat .git/rr-cache/*/postimage
model: bge-small
top_k: 50
rerank: true
```
<!-- /snippet -->

`git rerere diff` compares the recorded conflict with your file. The commit at the end of the snippet prints "Recorded resolution". The test merge has done its job. Remove it.

**[ON SCREEN]** 🔴 DANGEROUS: `git reset --hard`. It moves the branch and overwrites the index and working tree; uncommitted changes to tracked files are destroyed. Preview with `git status`. The dropped merge commit stays in the reflog. It is appropriate here: the working tree is clean and the merge was made to be thrown away.

```bash
git reset --hard HEAD^
ls .git/rr-cache/*
```

<!-- snippet: ch14c/rerere-merge/04-throw-away -->
```text
# The test merge served its purpose. Remove it; the recorded resolution stays.
$ git reset --hard HEAD^
HEAD is now at 62e40dc Add reranker module
$ ls .git/rr-cache/*
postimage
preimage
```
<!-- /snippet -->

The merge is gone. The record stays, with both halves. A week later the branch is merged into `main`, in the opposite direction from the test. Predict the exit status. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git switch -q main
git merge feature/rerank
```

<!-- snippet: ch14c/rerere-merge/05-real-merge -->
```text
$ git switch -q main
$ git merge feature/rerank
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
Resolved 'retrieval.yaml' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

**[PAUSE]** Read this output with care. The merge still reports CONFLICT. It still says "Automatic merge failed". It still exits with status 1. Only one line, "Resolved 'retrieval.yaml' using previous resolution.", tells you that the file no longer contains markers.

```bash
git status -s
cat retrieval.yaml
git rerere remaining
git ls-files -u
```

<!-- snippet: ch14c/rerere-merge/06-state -->
```text
$ git status -s
A  rerank.py
UU retrieval.yaml
$ cat retrieval.yaml
model: bge-small
top_k: 50
rerank: true
$ git rerere remaining
$ git ls-files -u
100644 fa370c130d79ca732a1fe0c9a0f8d556609b92b9 1	retrieval.yaml
100644 7ac2dd090cea0e852d25ee65af7e485b7a90e698 2	retrieval.yaml
100644 820d682527a387ff7594053d7bb1a01c230cf715 3	retrieval.yaml
```
<!-- /snippet -->

The file holds your resolution. `git status` says `UU`, and the index still has three stages, because rerere wrote the file and nothing else. `git rerere remaining` prints nothing: no path is left to resolve by hand. This stop is your review point. Read the file, run the tests, then stage and conclude.

```bash
git add retrieval.yaml
git commit --no-edit
git log --oneline --graph
```

<!-- snippet: ch14c/rerere-merge/07-finish -->
```text
$ git add retrieval.yaml
$ git commit --no-edit
[main cad2174] Merge branch 'feature/rerank'
$ git log --oneline --graph
*   cad2174 Merge branch 'feature/rerank'
|\  
| * 62e40dc Add reranker module
| * c9ca15a Enable reranking over the top 50 candidates
* | 96196ef Raise top_k to 20
|/  
* d9ec3c5 Add retrieval config
```
<!-- /snippet -->

**[TERMINAL]** Replay `labs/run ch14c/rerere-rebase`. The same record, made in a merge, serves a rebase of the branch onto `main`.

```bash
git switch -q feature/rerank
git rebase main
```

<!-- snippet: ch14c/rerere-rebase/01-rebase -->
```text
$ git switch -q feature/rerank
$ git rebase main
Rebasing (1/2)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply c9ca15a... Enable reranking over the top 50 candidates
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Resolved 'retrieval.yaml' using previous resolution.
Could not apply c9ca15a... # Enable reranking over the top 50 candidates
[exit status: 1]
```
<!-- /snippet -->

The rebase stops as usual. In a rebase the sides are swapped, and the normalization makes that irrelevant.

```bash
git status -s
cat retrieval.yaml
git add retrieval.yaml
git rebase --continue
```

<!-- snippet: ch14c/rerere-rebase/02-continue -->
```text
$ git status -s
UU retrieval.yaml
$ cat retrieval.yaml
model: bge-small
top_k: 50
rerank: true
$ git add retrieval.yaml
$ git rebase --continue
[detached HEAD 74fea46] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/rerank.
$ git log --oneline --graph --all
* 4dd76a7 Add reranker module
* 74fea46 Enable reranking over the top 50 candidates
* 96196ef Raise top_k to 20
* d9ec3c5 Add retrieval config
```
<!-- /snippet -->

`UU`, and a file without markers. You add it and continue. Now with `rerere.autoUpdate`. Quick quiz, two options. With auto-update on, the rebase still stops. Or it runs straight through. Say it out loud.

**[PAUSE]**

```bash
git config set rerere.autoUpdate true
git -c advice.mergeConflict=false rebase main
git status -s
```

<!-- snippet: ch14c/rerere-rebase/03-autoupdate -->
```text
$ git config set rerere.autoUpdate true
$ git -c advice.mergeConflict=false rebase main
Rebasing (1/2)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply c9ca15a... Enable reranking over the top 50 candidates
Staged 'retrieval.yaml' using previous resolution.
Could not apply c9ca15a... # Enable reranking over the top 50 candidates
[exit status: 1]
$ git status -s
M  retrieval.yaml
$ git rebase --continue
[detached HEAD f0e118a] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/rerank.
```
<!-- /snippet -->

It still stops. "Staged 'retrieval.yaml' using previous resolution." Only `git rebase --continue` is left to do. Nothing forces you to look at the file.

**[TERMINAL]** Replay `labs/run ch14c/rerere-wrong`. Suppose the test merge had been resolved in a hurry: `top_k` kept at 20 from `main`, `rerank: true` from the branch. Each line is valid, and together they starve the reranker of candidates. Git cannot know that.

```bash
cat .git/rr-cache/*/postimage
git merge feature/rerank
```

<!-- snippet: ch14c/rerere-wrong/01-replayed -->
```text
$ cat .git/rr-cache/*/postimage
model: bge-small
top_k: 20
rerank: true
$ git merge feature/rerank
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
Resolved 'retrieval.yaml' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat retrieval.yaml
model: bge-small
top_k: 20
rerank: true
```
<!-- /snippet -->

Apart from the file content, the output is identical to the correct case. That's how a wrong value reaches `main` without anyone typing it. The correction has three steps: make rerere forget, bring the conflict back, resolve again.

**[ON SCREEN]** 🟡 CAUTION: `git rerere forget <path>` deletes the recorded resolution for the conflict in that path. 🔴 DANGEROUS: `git restore --merge <path>`. What it changes: it overwrites the file with the conflict rebuilt from the index. What it can destroy: your edits to that file. Preview: `git diff <path>`. Recovery: none for those edits. Appropriate: when the content of the file is the wrong replay, which you do not want. Older scripts write this as `git checkout --merge <path>`.

```bash
git rerere forget retrieval.yaml
ls .git/rr-cache/*
git restore --merge retrieval.yaml
cat retrieval.yaml
```

<!-- snippet: ch14c/rerere-wrong/02-forget -->
```text
$ git rerere forget retrieval.yaml
Updated preimage for 'retrieval.yaml'
Forgot resolution for 'retrieval.yaml'
$ ls .git/rr-cache/*
preimage
thisimage
$ git restore --merge retrieval.yaml
$ cat retrieval.yaml
model: bge-small
<<<<<<< ours
top_k: 20
rerank: false
=======
top_k: 50
rerank: true
>>>>>>> theirs
```
<!-- /snippet -->

"Forgot resolution". The postimage is gone, and the markers are back in the file.

```bash
printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
git add retrieval.yaml
git commit --no-edit
cat .git/rr-cache/*/postimage
```

<!-- snippet: ch14c/rerere-wrong/03-record-again -->
```text
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
$ git add retrieval.yaml
$ git commit --no-edit
Recorded resolution for 'retrieval.yaml'.
[main f22692f] Merge branch 'feature/rerank'
$ cat .git/rr-cache/*/postimage
model: bge-small
top_k: 50
rerank: true
```
<!-- /snippet -->

"Recorded resolution", and the postimage now has `top_k: 50`. If the wrong merge is already committed and not pushed: undo it first, merge again, and then forget. If it is pushed: fix forward with a new commit and still forget, or the next rebase brings the mistake back.

**[TERMINAL]** The last part. While the chapter was written, replays of the rebase transcripts failed now and then with a message that has nothing to do with conflicts.

**[ON SCREEN]** The root-cause box of section 14C.3.

```text
Observed behavior : "git rebase --continue" with rerere enabled sometimes ends at the next conflicting commit with
                    "fatal: Unable to create '.../.git/MERGE_RR.lock': File exists." (exit status 128).
Git state         : the rebase is stopped at that commit with conflict markers; rerere has neither recorded the
                    conflict nor replayed a resolution for it.
Mechanism         : each commit of a rebase starts "git maintenance run --auto" in the background. Since Git 2.54
                    its default strategy includes the task rerere-gc, which runs whenever rr-cache has an entry
                    (maintenance.rerere-gc.auto defaults to 1) and takes MERGE_RR.lock while it works.
Root cause        : the background task and the next step of the rebase want the same lock at the same moment.
Why Git does this : the lock protects MERGE_RR from two writers; pruning rr-cache became a maintenance task.
Correct fix       : nothing is damaged. Run "git rerere", resolve, "git add", "git rebase --continue".
Prevention        : "git config set maintenance.rerere-gc.auto 0" where you rebase with rerere, and an occasional
                    "git rerere gc" by hand.
```

Replay `labs/run ch14c/rerere-lock`. It produces the failure on demand: an `exec` line of the rebase creates the lock file after each replayed commit, as a stand-in for the background task.

<!-- snippet: ch14c/rerere-lock/01-locked -->
```text
# Stand-in for the background task: after each replayed commit, hold the lock that rerere needs.
$ git -c advice.mergeConflict=false rebase -x 'touch .git/MERGE_RR.lock' main
Rebasing (1/6)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply 4c042d7... Enable reranking over the top 50 candidates
Recorded preimage for 'retrieval.yaml'
Could not apply 4c042d7... # Enable reranking over the top 50 candidates
[exit status: 1]
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml && git add retrieval.yaml
$ git -c advice.mergeConflict=false rebase --continue
Recorded resolution for 'retrieval.yaml'.
[detached HEAD 4f7e530] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/6)
Executing: touch .git/MERGE_RR.lock
Rebasing (3/6)
Auto-merging scoring.py
CONFLICT (content): Merge conflict in scoring.py
error: could not apply 27f7ed2... Blend dense scores into the ranking
fatal: Unable to create '$LAB/ch14c/rerere-lock/ranker/.git/MERGE_RR.lock': File exists.

Another git process seems to be running in this repository, or the lock file may be stale
[exit status: 128]
```
<!-- /snippet -->

```bash
git status -s
rm .git/MERGE_RR.lock
git rerere status
git rerere
git rerere status
```

<!-- snippet: ch14c/rerere-lock/02-recover -->
```text
$ git status -s
UU scoring.py
# The real background task removes its lock when it ends. Remove the stand-in by hand:
$ rm .git/MERGE_RR.lock
# rerere never saw this conflict. Run it yourself:
$ git rerere status
$ git rerere
Recorded preimage for 'scoring.py'
$ git rerere status
scoring.py
```
<!-- /snippet -->

After the failure `git rerere status` prints nothing: rerere never saw this conflict, so a resolution made now would not be recorded. One manual `git rerere` repairs that: "Recorded preimage". Removing the lock file by hand is right here only because the stand-in created it. The real background task removes its own lock when it ends.

How often does the real race occur? Replay `labs/run ch14c/rerere-lock-race`. It runs the same rebase twenty times per configuration.

<!-- snippet: ch14c/rerere-lock-race/01-counts -->
```text
# Twenty rebases with two conflicting commits each, per configuration (labs/ch14c/rerere-lock-race.sh):
default: MERGE_RR.lock failures in 20 rebases: 1
no-rerere-gc: MERGE_RR.lock failures in 20 rebases: 0
```
<!-- /snippet -->

**[ON SCREEN]** "This snippet is volatile." The first number depends on timing: it varied between 1 and 10 in the runs made for the chapter, and it will differ on your machine. The second was always 0.

**[ON SCREEN]** "Unverified." Say the caveat as the textbook does. The race was observed on Git 2.55.0 on macOS only. No manual or release note read for this course describes it, and Git 2.56 was not tested. The mechanism is inferred from the maintenance configuration and the measurement you have on screen.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Reading "CONFLICT" and exit status 1 as "rerere did not work".** Root cause: a replay writes the file and leaves the index unmerged, so the operation still stops; the line "Resolved ... using previous resolution" is the only sign.
2. **Turning on `rerere.autoUpdate` to save a step.** Root cause: it stages the replayed file, which removes the `UU` stop that is the only review a replay gets.
3. **Fixing a wrong replay in the file and committing, without `git rerere forget`.** Root cause: the wrong postimage is still recorded for that conflict text and will be replayed at the next occurrence.
4. **Expecting a colleague's clone to replay your resolutions.** Root cause: `rr-cache` is local and is not pushed, fetched or cloned.
5. **Treating the `MERGE_RR.lock` failure as corruption.** Root cause: a background `rerere-gc` task and the rebase wanted the same lock; nothing is damaged, and `maintenance.rerere-gc.auto=0` prevents it.

## PRODUCTION EXAMPLE

Now, out of the lab. A retrieval team keeps a reranking branch alive for six weeks. It conflicts with `main` on the same configuration lines at every weekly rebase. The branch owner enables rerere in her clone, sets `maintenance.rerere-gc.auto` to 0 there, and leaves `rerere.autoUpdate` off.

**[ANIMATION]** step: rr.4

**[ANIMATION]** say: A_wrong_postimage_is_replayed_as_faithfully_as_a_right_one

In week three she resolves the conflict carelessly, keeping the old candidate count. In week four the rebase stops, prints "using previous resolution", and shows `UU`. Because she treats that stop as a review point, she reads the file, sees the old count next to the enabled reranker, and runs the evaluation, which confirms the regression. She makes rerere forget the path, restores the conflict, resolves it correctly, and continues. The wrong value never became a commit. With auto-update on, and without the evaluation step, it would have.

## PRACTICE EXERCISE

Your turn. Do Lab 14.5, "Rerere, resolve once", in [`lab-manual/m14-hooks-rerere-attributes.md`](../../lab-manual/m14-hooks-rerere-attributes.md).

Before the second merge, predict three things: the exit status, the output of `git status -s`, and whether the file contains markers. The lab's failure scenario is a wrong resolution with auto-update in a rebase. Before you repair it, write down the order of the three correction steps and what each one changes on disk.

The challenge is Exercise 14.8, Level 3, "A resolution that nobody typed", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q129: "What does rerere record, and when? Why does a resolution recorded in a merge also serve a rebase in the other direction?"

Answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** replay: rr

A strong answer names the two files and the two moments at which they are written, and says what keys the record. It explains the normalization concretely, what is stripped and what is sorted, and derives the direction-independence from it. It states what rerere does and doesn't touch when it replays, and what the setting that changes this costs. And it shows awareness of the risk: what happens to a wrong resolution, and the procedure to replace it.

## RECAP

Let's land this. You should now be able to say:

- Rerere stores a normalized conflict as a preimage when the conflict appears and my resolution as a postimage when I conclude, keyed by the conflict text.
- Because labels are stripped and the sides sorted, one record serves both merge directions and a rebase.
- A replay writes the file only; the operation still stops with `UU`, and that stop is my review.
- A wrong record is replaced by `git rerere forget`, `git restore --merge`, and a new resolution.
- On Git 2.55 a background `rerere-gc` task can collide with a rebase over `MERGE_RR.lock`; this was observed, not documented, and `maintenance.rerere-gc.auto=0` avoids it.

## HOMEWORK

Read section 14C.3 of [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md).

Today you watched Git reuse your own resolution, and you know to review every replay. Do the rerere lab before the next video, and read the file at each stop. Next time: the dot gitattributes file, per-path settings that travel, and line endings. Until then, look at the state first and type second. See you in the next one.

# V034: The resolution workflow: abort, continue, quit, and restoring one side

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 6, Divergence and merge
- **Planned minutes:** 24
- **Prerequisites:** V033
- **Textbook sections:** [Chapter 8](../../textbook/ch08-merge.md), sections 8.10 and 8.19 (with the labels of section 8.21)
- **Demo scripts:** `labs/ch08/pre-merge-checks.sh`, `labs/ch08/abort-continue-quit.sh`, `labs/ch08/autostash-continue.sh`, `labs/ch08/restore-sides.sh`

## HOOK

**[ON SCREEN]** A single line of terminal text: `git merge --abort`.

An engineer on your team is in the middle of a conflicted merge. It's going badly, so they run `git merge --abort`. The manual says that this returns you to the state before the merge. The merge is gone, as promised. So is an edit to a prompt file that they made an hour before the merge started and never committed.

Nobody typed a wrong command. The safety net has a hole, and the hole has an exact shape. By the end of this video you can say what that shape is, and you can leave any stopped merge in a state you can name. Keep that lost edit in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A merge joins another branch's history into yours, and a conflict is a place where Git can't decide what a file should say. In the previous video you took a conflict apart. The marker file in the working tree, which is your files on disk. Stages 1, 2 and 3 in the index, which is Git's draft of the next commit. And the `MERGE_*` files in the dot git folder. This video is about what you do next.

There are four parts. First, the checks Git makes before a merge is allowed to start, because half of the questions people ask about merges are about a merge that never began. Second, the five steps from "conflict" to "merge commit". Third, the whole-file shortcuts, `--ours` and `--theirs`, and what they discard without telling you. Fourth, the three exits: `--continue`, `--abort` and `--quit`, and what each one leaves behind.

The project is still `evalkit`, the evaluation harness for LLM outputs. You are on `main`. A branch, remember, is a name that points at one commit and moves forward when you commit. Asha's branch is `feature/creative-judge`. Everything on screen is Git. GitHub does not appear in this video.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives as a list.

After this video you can:

- Run the checks that tell whether a merge can start.
- Resolve a conflict path by path and conclude the merge.
- Take one side of a path and explain what else that discards.
- Choose between `--abort`, `--continue` and `--quit`, and state what each leaves behind.
- Bring back the conflicted state of a path that was resolved wrongly.

## CONCEPT

**[ANIMATION]** trees: file=config/eval.yaml steps=setup,edit,add,commit chips=marker_blocks,stages_1_2_3,the_last_commit versions=marker_blocks,the_result,another_edit ref=main commits=5397d5f merge=on id=steps title=A_stopped_merge,_in_three_places say_edit=Step_3:_write_the_result._Only_the_working_tree_changes. say_add=Step_4:_mark_it_resolved._git_add_replaces_stages_1_to_3_with_one_stage_0_entry say_commit=Step_5:_conclude._The_new_commit_has_two_parents cmd_commit=git_merge_--continue

**[ANIMATION]** step: setup

Start with why a workflow is needed at all. A stopped merge is not an error state. It's a merge that Git has done as far as the three-way rule allows, and it's now waiting for a decision that only a person can make. Git has saved everything it knows: the three versions of each conflicted path as index stages, and the commit being merged in `MERGE_HEAD`. A commit, remember, is one saved snapshot of the whole project. Your job is to turn each unmerged path into one stage 0 entry and then record a commit with two parents.

The textbook gives that job five steps.

**[ON SCREEN]** The five steps, appearing one at a time.

**[ANIMATION]** say: Step_1:_see_what_is_open._git_status_lists_the_unmerged_paths

Step 1, see what is open. `git status` lists the unmerged paths. `git diff --name-only --diff-filter=U` lists only those.

**[ANIMATION]** say: Step_2:_learn_both_intents,_before_you_edit_anything

Step 2, learn both intents. The textbook's sentence is worth repeating: resolving a conflict is an investigation, not an editing chore. The stage diffs from the last video tell you what changed. `git log --merge` tells you why, because it lists the commits from either side that touch a conflicted path. If the intent is still unclear, ask the author.

**[ANIMATION]** step: edit

Step 3, write the result. Edit the file until it says what the merged project should say, and delete the marker lines. The answer may be one side, both sides, or new text.

**[ANIMATION]** step: add

Step 4, mark it resolved. `git add` on an unmerged path replaces stages 1 to 3 with one stage 0 entry. That's all it does. It doesn't check your work. It stages whatever is in the file, markers included.

**[ANIMATION]** step: commit

Step 5, conclude. `git merge --continue` checks that a merge is in progress and then runs `git commit`. Plain `git commit` does the same job.

**[ANIMATION]** end

Try it now. Thirty seconds, on paper: write the five steps from memory, one verb each. Then say them out loud.

**[PAUSE]**

Here they are: see, learn, write, mark, conclude.

**[ANIMATION]** graph: 6ae3c51-5397d5f main; 6ae3c51-640bfe1-45a7a67 feature/creative-judge MERGE_HEAD; HEAD=main => 6ae3c51-5397d5f-cdacf6e main; 6ae3c51-640bfe1-45a7a67 feature/creative-judge; HEAD=main title=A_stopped_merge id=stopped

Now the internals, because the exits only make sense from the inside. Here are today's commits. `main` has `5397d5f`, Asha's branch has `640bfe1` and `45a7a67`, and both grow from `6ae3c51`.

**[ANIMATION]** step: state-1

While a merge is open, `.git` holds `MERGE_HEAD`, `MERGE_MODE`, `MERGE_MSG` and `AUTO_MERGE`. `MERGE_HEAD` names the commit being merged, and it's the reason the commit you make will have a second parent. Remove that file and the same files, staged the same way, produce a commit with one parent. Hold on to that sentence. It explains `--quit`.

**[ANIMATION]** cards: question=A_merge_does_not_start_when cards=local_changes_overlap:with_files_the_merge_may_need_to_update|the_index_differs_from_HEAD:even_in_a_file_the_merge_does_not_touch at_2=55

When does the workflow not apply? When the merge never started. Git protects uncommitted work by refusing to begin, and the manual gives two rules. Git stops when local changes overlap with files that the merge may need to update. And it aborts if there are any changes registered in the index relative to the HEAD commit. HEAD is Git's name for where you are now. So under the second rule, a staged change blocks the merge even in a file the merge doesn't touch.

**[ANIMATION]** walk: id=abort columns=staged_path,why_it_is_staged,git_merge_--abort rows=config/eval.yaml:your_resolution:reset|prompts/judge.txt:merged_by_Git:reset|an_older_edit_of_yours:you_staged_it_during_the_merge:reset marks=3.3:bad title=git_merge_--abort_is_git_reset_--merge mono=off at_1=35 at_2=50 at_3=70

And the failure mode this video is named for: `git merge --abort` is defined by the manual as `git reset --merge` while `MERGE_HEAD` exists. It resets every staged path. It can't tell a merge result from an edit of yours that predates the merge and that you staged in the meantime.

## MENTAL MODEL

**[ON SCREEN]** Three words: resolve, stage, conclude. Below them: three exits.

**[ANIMATION]** walk: id=exits columns=after,--continue,--abort,--quit rows=working_tree:unchanged:as_before_the_merge:unchanged,_markers_stay|index:unchanged:reset_to_HEAD:unchanged,_still_unmerged|MERGE__*:removed:removed:removed|also_in_.git:commit,_two_parents:reflog_says_"reset":nothing_else|branch:moves:unchanged:unchanged,_next_commit_1_parent title=Three_exits_from_a_stopped_merge mono=off marks=5.2:ok at_1=45 at_2=62 at_3=78

**[ANIMATION]** step: 3

A picture helps. Think of a stopped merge as a form that Git has filled in as far as it could and handed back to you. The fields it couldn't fill are the unmerged paths. `git add` is you signing one field. `--continue` is handing the form in. `--abort` is tearing the form up and going back to where you stood. `--quit` is throwing away the cover sheet that says "this is a merge", while leaving every half-filled field on your desk.

**[ANIMATION]** say: --abort_resets_every_staged_path,_also_an_older_edit_you_staged_during_the_merge

Where the picture breaks: tearing up a paper form can't damage anything that was on your desk before. `--abort` can. It resets the index and the working tree for every staged path, and an older edit of yours that you staged during the merge looks, to Git, exactly like a field of the form.

**[ANIMATION]** cards: cards=--ours:the_whole_of_stage_2|--theirs:the_whole_of_stage_3|the_unit_is_a_file:not_a_hunk title=The_whole-file_shortcuts at_1=30 at_2=45 at_3=75

The second model is for the shortcuts. `--ours` and `--theirs` do not mean "our side of the conflict". They mean "the whole of stage 2" and "the whole of stage 3". A file is the unit, not a hunk, and a hunk is one block of changed lines.

## DIAGRAM

**[ANIMATION]** step: exits.4

**[DIAGRAM]** Build this from left to right. First the box "merge stops". Then one exit at a time, and for each exit fill its strip: working tree, index, `.git`.

```text
                         merge stops
        working tree: markers | index: stages 1,2,3 | .git: MERGE_HEAD ...
                               |
        +----------------------+----------------------+
        |                      |                      |
   --continue               --abort                --quit
   (all paths staged)   (= git reset --merge)   (forget the merge)
        |                      |                      |
  WT    unchanged         as before the merge     unchanged (markers stay)
  INDEX unchanged         reset to HEAD           unchanged (still unmerged)
  .git  merge commit,     MERGE_* removed,        MERGE_* removed,
        two parents;      reflog: "reset:         nothing else
        MERGE_* removed   moving to HEAD"
        |                      |                      |
  branch moves            branch unchanged        branch unchanged;
                                                  next commit has ONE parent
```

Quick quiz, from the picture. Which exit moves the branch? A, continue. B, abort. C, quit. Your answer?

**[PAUSE]**

**[ANIMATION]** step: exits.5

Read the bottom row. It's A: only `--continue` moves the branch. `--abort` and `--quit` both delete the merge state, and they differ in everything else. One cleans the index and the files. The other leaves them exactly as they are.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch08/pre-merge-checks`, then the three other scripts in the order below. The caption bar shows the script and the snippet name.

**Part 1: before the merge starts.** Into the lab. You are on `main` in `evalkit`. You append one comment line to `evalkit/metrics.py` and stage it. Asha's branch doesn't touch that file.

```bash
echo "# scoring helpers" >> evalkit/metrics.py
git add evalkit/metrics.py
git merge feature/creative-judge
```

Predict: the merge does not touch `metrics.py`. Does it start? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch08/pre-merge-checks/01-staged-change -->
```text
# A staged change in a file the merge does not even touch:
$ echo "# scoring helpers" >> evalkit/metrics.py
$ git add evalkit/metrics.py
$ git merge feature/creative-judge
error: Your local changes to the following files would be overwritten by merge:
  evalkit/metrics.py
Merge with strategy ort failed.
[exit status: 2]
```
<!-- /snippet -->

It does not. If you said yes, you're in good company: the message points the wrong way. Look at the exit status, 2, and at the message. It names the file and says it would be overwritten, which is not true of this file. The real reason is the manual's second rule: any change registered in the index relative to HEAD stops the merge. The message doesn't say so.

An untracked file that the merge would create is protected in the same way. Untracked means the file has no entry in the index. The branch adds `NOTES.md`, and you have your own untracked `NOTES.md`.

<!-- snippet: ch08/pre-merge-checks/04-untracked-file -->
```text
# The branch adds NOTES.md. You have an untracked file with the same name:
$ echo "my scratch notes" > NOTES.md
$ git merge feature/creative-judge
error: The following untracked working tree files would be overwritten by merge:
	NOTES.md
Please move or remove them before you merge.
Aborting
Merge with strategy ort failed.
[exit status: 2]
```
<!-- /snippet -->

One more refusal, which is not about your working tree at all. The merge base is the best common ancestor of two commits. Two commits with no common ancestor have no merge base.

<!-- snippet: ch08/pre-merge-checks/05-unrelated-histories -->
```text
$ git merge-base main imported/prompt-library
[exit status: 1]
$ git merge imported/prompt-library
fatal: refusing to merge unrelated histories
[exit status: 128]
```
<!-- /snippet -->

`git merge-base` prints nothing and exits with 1, and the merge is refused.

**Part 2: during the merge.** Now a merge that does start and stops on the conflict in `config/eval.yaml`. Suppose you edit nothing and run `git add` on the conflicted file. Predict what `git status --short` shows for it. Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/pre-merge-checks/02-leftover-markers -->
```text
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# Nothing was edited. git add accepts the file anyway:
$ git add config/eval.yaml
$ git status --short
M  config/eval.yaml
M  prompts/judge.txt
$ git diff --cached --check
config/eval.yaml:2: leftover conflict marker
config/eval.yaml:4: leftover conflict marker
config/eval.yaml:6: leftover conflict marker
[exit status: 2]
```
<!-- /snippet -->

`M`, staged, as if resolved. `git add` 🟢 is labelled SAFE because it only collapses stages into stage 0 and adds a blob, which is Git's stored copy of one file's content. But it accepted a file full of markers. The last command is your guard: `git diff --cached --check` reports the leftover conflict markers by line and exits with 2. Run it before you conclude, every time.

While a merge is open, a second merge and a partial commit are both refused.

<!-- snippet: ch08/pre-merge-checks/03-merge-in-progress -->
```text
$ git merge feature/creative-judge
fatal: You have not concluded your merge (MERGE_HEAD exists).
Please, commit your changes before you merge.
[exit status: 128]
$ git commit -m "Resolve config" config/eval.yaml
fatal: cannot do a partial commit during a merge.
[exit status: 128]
```
<!-- /snippet -->

**Part 3: the whole-file shortcuts.** `labs/run ch08/restore-sides`. The merge is stopped again. Look at the first `grep`: the conflict is on the temperature line, and line 11 says `seed: 1234`. That seed is Asha's change, in the same file, and it didn't conflict.

`git restore --ours` 🔴 is labelled DANGEROUS, so the five answers come first. What it changes: the working tree file only. What it can destroy: your hand edits to that file, which exist nowhere else until you `git add` them. How to preview: `git diff --ours` or `git diff --theirs`. How to recover: `git restore --merge` on the path brings back the starting point, not your edits. When it is appropriate: when the whole file from one side is the decision, or to restart a botched resolution.

```bash
git restore --ours config/eval.yaml
```

Predict the seed after this command. Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/restore-sides/01-ours -->
```text
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
$ grep -n -e '<<<' -e temperature -e '>>>' -e seed config/eval.yaml
2:<<<<<<< HEAD
3:temperature: 0.0
5:temperature: 0.7
6:>>>>>>> feature/creative-judge
11:seed: 1234
$ git restore --ours config/eval.yaml
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 7
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
```
<!-- /snippet -->

The seed is 7 again. Asha's non-conflicting change is gone from the working tree, and if you stage this file, it's gone from the merge. Also look at the last status: the path is still `UU`, because the index was not touched.

`--theirs` is the mirror image.

<!-- snippet: ch08/restore-sides/02-theirs -->
```text
$ git restore --theirs config/eval.yaml
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.7
7:seed: 1234
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
```
<!-- /snippet -->

And `git restore --merge` 🔴 rebuilds the marker version from the stages. It's the undo for both shortcuts and for a botched edit.

<!-- snippet: ch08/restore-sides/03-merge -->
```text
$ git restore --merge config/eval.yaml
$ grep -n -e '<<<' -e temperature -e '>>>' -e seed config/eval.yaml
2:<<<<<<< ours
3:temperature: 0.0
5:temperature: 0.7
6:>>>>>>> theirs
11:seed: 1234
```
<!-- /snippet -->

Notice the marker labels: `ours` and `theirs`, not `HEAD` and the branch name. The file was rebuilt from the index, not by the original merge.

Older scripts use `git checkout` for the same three operations. You will read this form. You don't need to write it.

<!-- snippet: ch08/restore-sides/04-checkout -->
```text
$ git checkout --ours config/eval.yaml
Updated 1 path from the index
$ git checkout --theirs config/eval.yaml
Updated 1 path from the index
$ git checkout --merge config/eval.yaml
Recreated 1 merge conflict
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
```
<!-- /snippet -->

`--merge` also works after `git add`. Take their whole file, stage it, then change your mind.

<!-- snippet: ch08/restore-sides/05-unresolve -->
```text
# Take their whole file, stage it, then change your mind.
$ git restore --theirs config/eval.yaml
$ git add config/eval.yaml
$ git status --short
M  config/eval.yaml
M  prompts/judge.txt
$ git ls-files -s config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 0	config/eval.yaml
$ git restore --merge config/eval.yaml
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
$ git ls-files -s config/eval.yaml
100644 c5b33275d88c041381cff59f23d3cd88b9f22c98 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 3	config/eval.yaml
```
<!-- /snippet -->

After the `git add` there's one stage 0 entry. After `git restore --merge` there are three entries again, stages 1, 2 and 3. The index keeps a record of the stages that the resolution replaced.

**Part 4: the three exits.** `labs/run ch08/abort-continue-quit`.

`git merge --continue` 🟡 CAUTION: it creates the merge commit and moves the branch. Run it too early and it refuses.

<!-- snippet: ch08/abort-continue-quit/01-continue-too-early -->
```text
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --continue
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
U	config/eval.yaml
[exit status: 128]
```
<!-- /snippet -->

`git merge --abort` 🔴 DANGEROUS. The five answers. It changes the index, the working tree and the merge state. It destroys every resolution made so far, and any uncommitted edit that was staged during the merge. Preview with `git status` and `git diff --cached --stat`. Recovery: staged content survives as unreferenced objects that `git fsck` lists, and unstaged resolution edits are gone. Appropriate when the merge was a mistake or needs a different approach.

The reflog is Git's local list of the values HEAD has had. Predict what it will say after the abort. Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/abort-continue-quit/02-abort -->
```text
$ git merge --abort
$ git status --short --branch
## main
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
$ git reflog -2
5397d5f HEAD@{0}: reset: moving to HEAD
5397d5f HEAD@{1}: commit: Use temperature 0 for reproducible evals
```
<!-- /snippet -->

`reset: moving to HEAD`. The abort is a reset, and the reflog says so. The `MERGE_*` files are gone, and `ORIG_HEAD` stays.

Outside a merge, both commands tell you that `MERGE_HEAD` is missing.

<!-- snippet: ch08/abort-continue-quit/03-nothing-in-progress -->
```text
$ git merge --abort
fatal: There is no merge to abort (MERGE_HEAD missing).
[exit status: 128]
$ git merge --continue
fatal: There is no merge in progress (MERGE_HEAD missing).
[exit status: 128]
```
<!-- /snippet -->

Now the odd one. `git merge --quit` 🟡 CAUTION deletes the merge state only.

<!-- snippet: ch08/abort-continue-quit/04-quit -->
```text
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --quit
[exit status: 0]
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   prompts/judge.txt

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   config/eval.yaml
```
<!-- /snippet -->

No `MERGE_*` file is left, and `git status` no longer says "you are still merging". But the unmerged path is still there and the staged change is still there. Predict: you resolve, add and commit now. How many parents does the commit have? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch08/abort-continue-quit/05-after-quit -->
```text
# The merge is forgotten, the half-merged files are not. A commit made now has ONE parent:
$ git add config/eval.yaml
$ git commit -q -m "Resolve temperature conflict"
$ git log --oneline --graph --all
* cdacf6e Resolve temperature conflict
* 5397d5f Use temperature 0 for reproducible evals
| * 45a7a67 Ask the judge for a rationale
| * 640bfe1 Raise temperature and reseed for judge diversity
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git branch --no-merged
  feature/creative-judge
```
<!-- /snippet -->

One. No `MERGE_HEAD`, so no second parent. The graph shows `cdacf6e` on top of `5397d5f` and Asha's two commits off to the side.

**[ANIMATION]** step: stopped.state-2

Here it is as a picture. `MERGE_HEAD` is gone, and `cdacf6e` has one line into it. No line joins Asha's commits to it. Her content is in `main`, her commits are not ancestors of it, and `git branch --no-merged` still lists her branch. The way back after `--quit` is `git reset --merge`, because `--abort` has nothing to find.

<!-- snippet: ch08/abort-continue-quit/06-quit-cleanup -->
```text
# The clean way back after --quit: reset the index and the files the merge touched.
$ git merge --quit
$ git merge --abort
fatal: There is no merge to abort (MERGE_HEAD missing).
[exit status: 128]
$ git reset --merge
$ git status --short --branch
## main
```
<!-- /snippet -->

**Part 5: uncommitted work and `--autostash`.** Work in paths the merge does not touch is allowed and survives both the merge and an abort.

<!-- snippet: ch08/abort-continue-quit/07-dirty-tree -->
```text
# An uncommitted edit in a file the merge does not touch survives merge and abort.
$ echo "# evalkit" > NOTES.md
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
?? NOTES.md
$ git merge --abort
$ git status --short
?? NOTES.md
```
<!-- /snippet -->

An unstaged edit in a file the merge does touch stops the merge, unless you let Git stash it. To stash is to park uncommitted work as a commit, to be applied again later. `merge.autoStash` makes that the default.

<!-- snippet: ch08/abort-continue-quit/08-autostash -->
```text
# An uncommitted edit in a file the merge DOES touch stops the merge before it starts...
$ echo "Be concise." >> prompts/judge.txt
$ git merge feature/creative-judge
error: Your local changes to the following files would be overwritten by merge:
	prompts/judge.txt
Please commit your changes or stash them before you merge.
Aborting
Merge with strategy ort failed.
[exit status: 2]
# ...unless Git stashes it for you.
$ git merge --autostash feature/creative-judge
Created autostash: 02ed132
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
[exit status: 1]
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
AUTO_MERGE
MERGE_AUTOSTASH
MERGE_HEAD
MERGE_MODE
MERGE_MSG
ORIG_HEAD
$ git merge --abort
Applied autostash.
$ git status --short
 M prompts/judge.txt
```
<!-- /snippet -->

Look at `MERGE_AUTOSTASH` in the listing, and at "Applied autostash." after the abort. Then read the hint Git printed: "apply stashed changes with `git stash pop`". `labs/run ch08/autostash-continue` tests that hint.

<!-- snippet: ch08/autostash-continue/01-stopped -->
```text
# An uncommitted edit in a file that the merge also changes (on another line):
$ sed -e 's/strict grader/strict but fair grader/' prompts/judge.txt > j && mv j prompts/judge.txt
$ git status --short
 M prompts/judge.txt
$ git merge --autostash feature/creative-judge
Created autostash: 1b5e0ea
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
[exit status: 1]
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
# The hint says "git stash pop". The stash list is empty:
$ git stash list
$ git stash pop
No stash entries found.
[exit status: 1]
$ git log -1 --format="%h %s" MERGE_AUTOSTASH
1b5e0ea On main: autostash
```
<!-- /snippet -->

The stash list is empty, and `git stash pop` finds nothing. The autostash is a stash-shaped commit that `.git/MERGE_AUTOSTASH` points to. It's not an entry in the stash list.

<!-- snippet: ch08/autostash-continue/02-concluded -->
```text
# Resolve the conflict as in section 8.10, then conclude the merge:
$ git add config/eval.yaml
$ git merge --continue
[main 29f236b] Merge branch 'feature/creative-judge'
Applied autostash.
$ git status --short
 M prompts/judge.txt
$ cat prompts/judge.txt
You are a strict but fair grader.
Answer with PASS or FAIL.
Explain your verdict in one sentence.
$ git stash list
```
<!-- /snippet -->

`git merge --continue` applied it for you. According to the textbook, the autostash reaches the stash list after `git merge --quit` or `git reset --merge`, per the manual, or when applying it conflicts, which was seen in the sandbox. Only then is `git stash pop` the right command.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause in one line.

1. **Staging a file that still contains markers.** Root cause: `git add` records whatever is in the file and performs no check; `git diff --cached --check` is the check.
2. **Taking `--theirs` to "accept their side of the conflict".** Root cause: `--ours` and `--theirs` write the whole of stage 2 or stage 3, so the other side's non-conflicting changes in that file are discarded too.
3. **Using `--quit` to get out of a merge and then committing.** Root cause: without `MERGE_HEAD` the commit has one parent, so the content is in but the branch still counts as unmerged.
4. **Running `git add -A` during a merge, then aborting.** Root cause: `--abort` is `git reset --merge`, which resets every staged path and cannot tell a merge result from your own older edit.
5. **Running `git stash pop` because the hint said so.** Root cause: the autostash lives in `.git/MERGE_AUTOSTASH`, not in the stash list, and `--continue` or `--abort` applies it.

## PRODUCTION EXAMPLE

**[ON SCREEN]** The merge commit message from the textbook's resolution.

Now, out of the lab. Your evaluation team has a release requirement: scores must be reproducible. Asha's branch raises the judge temperature to 0.7 for diversity and changes the seed. `main` set the temperature to 0.0. The merge stops on the temperature line.

**[ANIMATION]** walk: columns=what,main,Asha,the_merge rows=temperature:0.0:0.7:0.0|seed:7:1234:1234|rationale_line:-:added:kept marks=1.4:hl,2.4:hl,3.4:hl title=The_resolution last=the_merge at_1=30 at_2=42 at_3=50

The engineer who resolves it reads `git log --merge`, and sees the two commits that touched the line and their reasons. They keep 0.0. They keep Asha's new seed and her extra prompt line. They run the tests and `git diff --cached --check`. And they write two sentences in the merge message: temperature stays at 0.0 because reproducible scores are a release requirement, and the seed and the rationale line are taken as they are.

**[ANIMATION]** end

That message matters more than it looks. The textbook's point is that the merge commit message is the only place where a resolution can explain itself. One sentence there answers the question that somebody will ask in six months.

## PRACTICE EXERCISE

Your turn. Do Lab 6.7, "Abort and retry with `zdiff3`", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md). Type it by hand in the lab shell. Your commit IDs will differ from the transcript where you create commits yourself.

Before you start, write down three predictions:

- After `git merge --abort`, which of your uncommitted edits are still there: the one you never staged, the one you staged before the merge, the one you staged during it?
- What will `git reflog -1` show after the abort?
- If an edit is lost, where could a copy of it still exist, and which command would list it?

The lab reproduces the loss from the hook and recovers the edit. That's the lost prompt edit from the start, found again. Don't open the answers before your own attempt.

When that is done, the challenge is Exercise 6.9, "a merge that somebody else left half done", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question, in full.

Q136: "`git merge --abort` is supposed to return you to the state before the merge. An engineer ran it during a conflicted merge and lost an uncommitted edit that predated the merge. How did the safety net fail, can the edit be recovered, and what do you tell the team?"

**[PAUSE]**

Answer it out loud before you open the answers file. A strong answer has three parts, in the order of the question. It names the mechanism: what `--abort` is defined as, and what that command can't distinguish. It gives a recovery path with the conditions under which it works and the point at which it stops working, without promising more than the mechanism gives. And it ends with a habit the team can adopt tomorrow, stated as a rule and not as a warning.

## RECAP

Let's land this. You should now be able to say these sentences without notes.

**[ANIMATION]** replay: steps

**[ANIMATION]** step: steps.commit

A merge does not start if anything is staged, or if an unstaged or untracked file overlaps with what the merge would write. Resolution is five steps: see what is open, learn both intents, write the result, `git add`, and conclude. `--ours` and `--theirs` take a whole file from stage 2 or stage 3, and `git restore --merge` brings the conflicted state back, even after `git add`.

**[ANIMATION]** step: exits.5

`--continue` records a two-parent commit, `--abort` is `git reset --merge` and returns to HEAD, and `--quit` forgets the merge while leaving the half-merged files. An abort can lose an older edit that was staged during the merge.

## HOMEWORK

Read section 8.10 of [Chapter 8](../../textbook/ch08-merge.md).

Repeat Lab 6.2, "An edit-against-edit conflict, resolved by reading the stages", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md). Then resolve the same conflict a second time by taking one side of the file, and write a list of what you lost by doing so.

Today you walked a stopped merge to each of its three exits, and you can name the state each one leaves behind. Do the lab while this is fresh. Next time: conflict types beyond content. Until then, look at the state first and type second. See you in the next one.

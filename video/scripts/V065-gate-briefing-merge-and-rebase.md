# V065: Gate briefing: Merge and rebase

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 10, Cherry-pick and ranges (briefing before Gate 3)
- **Planned minutes:** 10
- **Prerequisites:** V051, V060, V064
- **Textbook sections:** [Chapter 8](../../textbook/ch08-merge.md), section 8.4; [Chapter 9](../../textbook/ch09-rebase.md), sections 9.4 and 9.11; [Chapter 10](../../textbook/ch10-cherry-pick.md), section 10.7; [Chapter 11](../../textbook/ch11-reset-revert-restore.md), section 11.12; gate rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts:** `labs/ch09/rebase-conflict.sh` and `labs/ch10/pick-conflict.sh` (warm-up only)

## HOOK

**[ON SCREEN]** An empty table: four rows (merge, rebase step, cherry-pick, revert), three columns (base, ours, theirs).

**[ANIMATION]** walk: columns=operation,base,ours,theirs rows=merge:?:?:?|rebase_step:?:?:?|cherry-pick:?:?:?|revert:?:?:? mono=off title=Twelve_empty_cells id=empty at_1=0 at_2=4 at_3=8 at_4=12

**[ANIMATION]** step: 4

Twelve empty cells. If you can fill them from memory, with the reason for each, you can explain every conflict you've seen in the last thirty videos, and most of Gate 3.

If you can't, the gate will find the empty cell. This briefing fills the table with you once, and then tells you how the gate is run. Try it now, on paper. Thirty seconds: draw the table, and fill in the cells you're sure of.

**[PAUSE]**

**[ANIMATION]** end

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a gate briefing. It shows no gate item, and the gate file is not opened on screen. A gate that has been read is a gate that has been taken.

Gate 3 comes after Module 10. It covers the four modules you have now finished: merge, undo, rebase, cherry-pick and ranges. A merge joins two histories, a rebase and a cherry-pick copy commits, and a revert adds a commit that undoes one. They looked like four topics. They are one mechanism, the three-way merge, which combines two versions against a common base, used with four different choices of inputs, plus one question about history: private or shared.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this briefing you can:

- State what Gate 3 covers and its threshold of 90.
- Prepare the prediction part by naming base, ours and theirs for merge, rebase, cherry-pick and revert.
- Run the hands-on part by first reading which operation is in progress.
- Use the undo decision tree under time pressure.

## CONCEPT

**[ON SCREEN]** The Gate 3 row of the table in `assessments/README.md`.

Gate 3, Merge and rebase. Pass at 90. Taken after Module 10. It covers the three-way merge, conflicts and stages, undo choices, rebase, cherry-pick and range notation.

**[ANIMATION]** walk: columns=part,points,at_least rows=Concepts:30:21|Prediction:20:14|Hands-on_diagnosis:30:21|Oral_interview:20:14|Gate_3:100:90_overall marks=5.3:hl mono=off title=Gate_3:_one_hundred_points_in_four_parts id=form

The form is the one you know from Gates 1 and 2. One hundred points in four parts: Concepts 30, Prediction 20, Hands-on diagnosis 30, Oral interview 20. The pass rule is the threshold overall and at least 70 percent in every part: 21, 14, 21 and 14. A total above the threshold with one part below 70 percent is a miss.

**[ANIMATION]** end

Two things are particular to this gate.

First, the hands-on repository is in the middle of something. A merge, a rebase, a cherry-pick or a revert has been started and not finished, and the report that comes with it is incomplete and partly wrong. Your first job is not to fix. It's to read which operation is in progress, and where it stopped.

Second, the scoring of the path. The hands-on points are split between the end state, the safety of the path, and the explanation. The assessments file says it directly: a correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail the safety row. In this block you learned a safer alternative for each of those. The gate checks whether you reach for it.

One table carries most of the gate: for each of merge, rebase step, cherry-pick and revert, which commit is the base, which is ours, which is theirs.

## MENTAL MODEL

**[ON SCREEN]** "Ours is HEAD. Always. The question is what HEAD is at that moment."

There is one rule behind the whole table.

**[ANIMATION]** trees: file=app/retriever.py steps=setup subs=the_file_with_marker_blocks,three_entries_for_the_path,where_you_are chips=upper_half,stage_2,ours commits=1c9f69a,1c9f69a title=Ours_is_always_HEAD say_setup=The_upper_half_of_the_markers,_stage_2,_HEAD:_three_names_for_ours

"Ours" is HEAD, Git's name for where you are. It's stage 2. It's the upper half of the markers. That never changes.

What changes between the four operations is what HEAD is when the merge runs, and which commit plays the base.

In a merge, HEAD is your branch. In a rebase, HEAD is the upstream plus the copies made so far, because step 2 of a rebase detached HEAD there. In a cherry-pick and in a revert, HEAD is your branch again.

**[ANIMATION]** walk: columns=operation,ours_=_HEAD_is,base_is rows=merge:your_branch:the_merge_base_of_the_two_tips|rebase_step:the_upstream_plus_the_copies_so_far:the_parent_of_the_applied_commit|cherry-pick:your_branch:the_parent_of_the_applied_commit|revert:your_branch:the_commit_being_reverted mono=off title=Two_sentences_behind_the_table id=cells

**[ANIMATION]** step: 4

And the base: for a merge, the merge base of the two tips. For a rebase step and a cherry-pick, the parent of the commit being applied. For a revert, the commit being reverted itself, with its parent as theirs, so that the change runs backwards.

If you forget a cell in the exam room, don't guess. Derive it from those two sentences.

**[ANIMATION]** end

Quick quiz, three options. In a stopped rebase, "theirs" is: option one, the upstream. Option two, your own commit. Option three, the merge base. Say it out loud.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** New diagram. The four-row table, filled in live, one row at a time. For each row, say the reason aloud before writing the cells.

```text
Operation                 base (stage 1)                    ours (stage 2) = HEAD                     theirs (stage 3)
------------------------  --------------------------------  ----------------------------------------  ----------------------------------
git merge <other>         merge base of HEAD and <other>    your branch                               <other>
rebase, one step          parent of your commit             upstream plus the copies made so far      your commit being replayed
                                                                                                      (REBASE_HEAD)
git cherry-pick C         parent of C                       your branch                               C (CHERRY_PICK_HEAD)
git revert C              C itself                          your branch                               parent of C

ours is always HEAD.   A rebase is the row where HEAD is not your branch.   A revert is a cherry-pick with base and theirs exchanged.
```

Option two: in a rebase, theirs is your own commit, because ours, HEAD, is the upstream side. Now check your paper against the table.

## LIVE TERMINAL DEMO

**[TERMINAL]** Warm-up only. Two replays you have seen; watch them as an examiner would.

`labs/run ch09/rebase-conflict`: a rebase stopped at a conflict.

<!-- snippet: ch09/rebase-conflict/03-who-is-who -->
```text
# Stage 2, "ours", is HEAD: the upstream commits plus what has been replayed so far.
$ git log --oneline -2 HEAD
1c9f69a Add reranker skeleton
439e4c6 Raise TOP_K to 8 after recall regression
# Stage 3, "theirs", is the commit being replayed: your own work.
$ git log --oneline -1 REBASE_HEAD
569e6c9 Fetch 20 candidates for the reranker
```
<!-- /snippet -->

**[ANIMATION]** graph: 439e4c6-1c9f69a; 569e6c9 REBASE_HEAD; HEAD=1c9f69a; role:1c9f69a:ours; role:569e6c9:theirs title=Row_two:_one_step_of_a_rebase

**[ANIMATION]** step: state-1

Stage 2, "ours", is HEAD: the upstream commits plus what has been replayed so far. Stage 3, "theirs", is the commit being replayed: your own work. That's row two of the table. Now the same two branches as a merge, run from your branch. Predict whose value is on top, under `HEAD`: yours, or `main`'s? I'll wait.

**[PAUSE]**

<!-- snippet: ch09/rebase-conflict/04-as-a-merge -->
```text
# The same two branches integrated with a merge instead (run from feat/rerank):
$ git merge main
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat app/retriever.py
<<<<<<< HEAD
TOP_K = 20
=======
TOP_K = 8
>>>>>>> main

def retrieve(query):
    return rerank(search(query, TOP_K))
$ git show :2:app/retriever.py | head -1
TOP_K = 20
$ git show :3:app/retriever.py | head -1
TOP_K = 8
$ git merge --abort
```
<!-- /snippet -->

Yours. The same two branches as a merge, run from your branch: the same two values in opposite positions. That's row one.

`labs/run ch10/pick-conflict`: a cherry-pick stopped at a conflict.

<!-- snippet: ch10/pick-conflict/04-where-stage-1-comes-from -->
```text
# The merge base of the two branches has the v1 line ...
$ git show $(git merge-base HEAD main~1):src/client.py | tail -1
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
# ... but stage 1 is the parent of the picked commit, which already has v2.
$ git show main~2:src/client.py | tail -1
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
```
<!-- /snippet -->

The merge base of the two branches has one version of the line. Stage 1 has another, because stage 1 is the parent of the picked commit. That's the base cell of row three.

**[ON SCREEN]** The opening routine for the hands-on part.

For Part 3, after the generator has printed the sandbox path and you have opened the lab shell and read `SYMPTOMS.md`, start with four read-only commands, and keep the log.

```bash
git status
git ls-files -u
git merge-base HEAD <other>
git reflog
```

**[ANIMATION]** cards: cards=git_status:names_the_operation_in_progress|git_ls-files_-u:which_stages_exist_for_each_conflicted_path|git_merge-base_HEAD_<other>:the_base,_where_the_operation_is_a_merge|git_reflog:what_was_done_before_you_arrived numbered=on question=Four_read-only_commands_first id=first

**[ANIMATION]** step: 4

`git status` names the operation in progress in its first lines: "You have unmerged paths", "interactive rebase in progress", "You are currently cherry-picking", "You are currently reverting". `git ls-files -u` shows which stages exist for each conflicted path. `git merge-base` gives the base where the operation is a merge. `git reflog` tells you what was done before you arrived, and it is where every way back begins.

Don't read `generate.sh` or `check.sh`. Don't change anything until you can say which row of the table you're in.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each with its root cause.

1. **Taking `--ours` in a stopped rebase to keep your own change.** Root cause: ours is HEAD, and in a rebase HEAD is the side you are rebasing onto.
2. **Starting to resolve before identifying the operation.** Root cause: the exits and the meaning of the stages depend on whether a merge, a rebase, a cherry-pick or a revert is in progress.
3. **Reaching a correct end state with `git reset --hard` or a forced push.** Root cause: the safety of the path is scored separately, and a safer command existed.
4. **Reading `A..B` the same way for `git log` and `git diff` in a prediction item.** Root cause: log selects commits by reachability; diff compares two trees, and three dots there mean the merge base.
5. **Choosing an undo without asking whether the commits are shared.** Root cause: the decision tree branches on publication before it names a command.

## PRODUCTION EXAMPLE

Now, out of the lab. What this gate examines is the on-call situation: you are called to a repository that somebody else left halfway through an integration, with a description that is partly wrong. The engineer who does well reads the state first, names the operation, says which commit is on which side, and chooses the exit that keeps the most options open. The engineer who does badly types the command that worked last time.

**[ANIMATION]** cards: cards=Uncommitted_or_committed?|If_committed:_can_anyone_else_already_have_it?|Only_then_a_command,_and_its_risk_said_aloud numbered=on question=The_undo_decision_tree,_in_order id=undo

The undo decision tree of section 11.12 is the same discipline for the other half of the gate. Uncommitted or committed? If committed: can anyone else already have it? Only then a command, and its risk said aloud.

## PRACTICE EXERCISE

Your turn. Redo the four Level 5 exercises of the block, without notes, all in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md):

- Exercise 6.10, "the weekly sync that conflicts more every week".
- Exercise 8.10, "a feature that was merged twice and is half missing".
- Exercise 9.10, ""rebased onto main, no functional change"".
- Exercise 10.10, ""the fix is in the release" and "the fix was never backported"".

For each, before the first command: write which operations are involved, and fill in the row of the base, ours, theirs table for each one. Then predict the output of your first two commands.

When all four go through without notes, take Gate 3: [`assessments/gate-3-merge-and-rebase.md`](../../assessments/gate-3-merge-and-rebase.md). One sitting, parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q100: "`git log main..feature` and `git diff main..feature`: how do the two dots differ in meaning? Which one do you want for a review?"

**[PAUSE]**

Answer out loud. A strong answer says what each command operates on, a set of commits or a pair of trees, and derives the two meanings from that. For the review half it names the form, says which two snapshots it compares, and gives one concrete thing the other form would show wrongly. Expect a follow-up that changes the graph, for example "the branch is now behind `main` by two commits", and asks what each output looks like then.

## RECAP

**[ANIMATION]** step: setup

Let's land this. You should now be able to say:

**[ANIMATION]** step: cells.4

Gate 3 covers the three-way merge, conflicts and stages, undo choices, rebase, cherry-pick and range notation, and I pass at 90 with at least 70 percent in each part. Ours is always HEAD. In a merge, a cherry-pick and a revert that's my branch, and in a rebase it's the upstream plus the copies so far. The base is the merge base for a merge, the parent of the applied commit for a rebase step and a cherry-pick, and the commit itself for a revert. In the hands-on part I read which operation is in progress before I change anything, and I choose the path that can be undone. For any undo I ask first whether the history is shared.

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 8, 9, 10 and 11 aloud.

You've finished four modules, and you can derive the whole table from two sentences. Fill it in once more from memory before the gate. Next time: reading a diff, from summaries to algorithms. Until then, look at the state first and type second. See you in the next one.

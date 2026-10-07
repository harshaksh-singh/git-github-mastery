# V076: Recovering commits II: a wrong rebase, a bad merge, the wrong branch, detached HEAD, a wrong cherry-pick

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 28
- **Prerequisites.** V059, V075
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), the rest of section 13.8
- **Demo scripts.** `labs/ch13/lab-12-4-wrong-rebase.sh`, `labs/ch13/lab-12-5-bad-merge.sh`, `labs/ch13/lab-12-6-wrong-branch.sh`, `labs/ch13/lab-12-7-detached-head.sh`, `labs/ch13/lab-12-9-wrong-cherry-pick.sh`

## HOOK

**[ON SCREEN]** `git reset --hard ORIG_HEAD`, and Git answers: "HEAD is now at f028350 Fix off-by-one in rate limit window"

An engineer cherry-picks the wrong commit onto a release branch. A cherry-pick copies one commit's change onto the current branch. He remembers a recipe: `git reset --hard ORIG_HEAD` undoes the last operation. He runs it. Git answers with a commit subject that is exactly the fix he meant to pick. It looks like success.

**[ANIMATION]** graph: 239cf05-3171b7b-f028350-cad5d75 main; 3171b7b-e30eec3-48b4def release/2.1; f028350 ORIG_HEAD; HEAD=release/2.1; title:A_stale_ORIG__HEAD => 239cf05-3171b7b-f028350-cad5d75 main; 3171b7b-e30eec3-48b4def ORIG_HEAD; f028350 release/2.1; reflog:e30eec3,48b4def; HEAD=release/2.1; cmd:!git_reset_--hard_ORIG__HEAD; say:HEAD_is_now_at_f028350:_the_release_branch_shows_the_history_of_main id=stale dx=260 at_state_1=4 at_state_2=15

**[ANIMATION]** step: state-2

It's not. The release branch now shows the history of `main`. The commit that pins the dependencies for the release is gone from it. The only visible sign is one missing file. If nobody notices, the next release build resolves unpinned dependencies. Remember that missing file.

The command did what it says. The engineer believed that `ORIG_HEAD` means "before the last command". It means "before the last reset, merge, rebase or am", on whatever branch that was.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the previous video you learned the eight-step method and used it on three accidents. Today, five more, all with committed work, all recoverable. Each is the same method with a different ref to consult.

A wrong rebase: the entry in the branch reflog below "rebase (finish)". A reflog is the local log of where a name pointed. A bad merge: the entry below the merge line. Commits on the wrong branch: the difference between `main` and `origin/main`. Detached HEAD, where you commit on no branch: the HEAD reflog, or `git fsck`. A wrong cherry-pick: the branch reflog again.

Two of the five have a root-cause box, and both boxes are about recipes that work in one situation and do damage in the next.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- return a branch to its state before a rebase when `ORIG_HEAD` is stale;
- undo a merge that was not pushed and one that was;
- move commits made on the wrong branch to the right one;
- rescue commits left in detached HEAD;
- remove a wrong cherry-pick without touching the commits around it.

## CONCEPT

Three ideas decide every case today.

**First: which log.** The branch reflog has one line per operation on that branch. A whole rebase is one entry, "rebase (finish)", and the line below it is the tip from before the rebase. A merge is one entry, and the line below it is where the branch was. That's the log you read when the question is "where was this branch". The HEAD reflog is the only log that sees detached HEAD.

**Second: published or not.** Before a push, you may move the branch back. After a push to a branch that others have pulled, you don't rewind. You add commits, such as a revert, which undoes an earlier commit. For a merge the textbook gives a three-row table.

**[ON SCREEN]** The table from section 13.8.

| The merge is | Tool | Reference |
|---|---|---|
| In progress, with conflicts you do not want to resolve | `git merge --abort` | Chapter 8 |
| Committed, not pushed | `git reset --keep ORIG_HEAD`, or the branch reflog | Below |
| Pushed to a shared branch | `git revert -m 1 <merge>`, and know the re-merge problem | Chapter 11, section 11.9 |

The same split applies to a wrong cherry-pick and to commits on the wrong branch: reset before the push, revert after.

**Third: the lowest-risk move.** 🟡 CAUTION: `git reset --keep <id>` moves the branch and the files in the same way as `--hard`, and refuses if that would overwrite an uncommitted change. Use it wherever you would have typed `--hard`. And prefer copying to moving: with commits on the wrong branch, copy first, remove second.

When is `ORIG_HEAD` acceptable? Only as the very next command after the operation you want to undo, and only if that operation writes it. `git cherry-pick` doesn't. A commit doesn't. So a rebase followed by one commit, or a cherry-pick at any time, leaves `ORIG_HEAD` pointing somewhere you didn't intend.

**[ANIMATION]** graph: [a true merge] A-B-M main; A-C-D; D-M; HEAD=main; note:B:HEAD~1:_the_previous_tip || [a fast-forward] A-B-C-D main; HEAD=main; note:B:the_previous_tip; note:C:HEAD~1:_a_commit_of_the_merged_branch title=Recipes_that_count_parents id=parents

Failure modes: recipes that count parents, such as `git reset --hard HEAD~1` to "undo the last merge". After a true merge, `HEAD~1` is the previous tip of the branch. After a fast-forward, there is no merge commit, and `HEAD~1` is the previous commit of the branch that was merged.

**[ANIMATION]** end

## MENTAL MODEL

Keep the picture from last time: the commits are boxes that never left the vault, and each accident put a card in the wrong place.

**[ANIMATION]** stores: boxes=a_branch's_ledger_page:the_branch_reflog|HEAD's_diary:the_HEAD_reflog|a_sticky_note:ORIG__HEAD rows=1:A:where_was_this_card_yesterday?|2:B:where_did_I_walk?|3:C:one_box_number,_no_heading@bad title=Three_records id=notes

Today add one refinement. Each branch has its own ledger page, and HEAD has a diary. The ledger page of a branch answers "where was this card yesterday". The diary answers "where did I walk". `ORIG_HEAD` is a sticky note with one box number and no heading: it doesn't say which card it was copied from, or when.

**[ANIMATION]** end

Try it now, on paper. Thirty seconds: draw a branch of three commits, then the same branch after a rebase. Do three of those commits exist now, or six? Say it out loud.

**[PAUSE]**

**[ANIMATION]** graph: A-B main; A-C-D-E feature; HEAD=feature; title:Three_commits,_or_six? => A-B-C′-D′-E′ feature; B main; A-C-D-E; reflog:C,D,E; HEAD=feature; cmd:git_rebase_main; say:Six:_three_new_boxes_with_new_numbers,_three_old_ones_left_behind; name:rebased id=six

Six. The model breaks in one place worth saying: a rebase doesn't move boxes. It builds new boxes with new numbers and leaves the old ones behind. Undoing a rebase means pointing the card back at the old boxes, and anything committed after the rebase sits on the new ones.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** Five small before-and-after pictures, one per case, with the commit IDs of the transcripts. Show each one as its case begins in the demonstration.

```text
  1. wrong rebase         before: release/1.4 -- c5f4fb7 -- eb1f140                    hotfix (old tip)
                          after : main -- ... -- 262dc41 -- 6ef447a -- 37bb577         hotfix (rebased, plus one new commit)
                          repair: release/1.4 -- c5f4fb7 -- eb1f140 -- 13305ef         hotfix

  2. bad merge (ff)       before: 5aab090 -- 0529d31                                   main
                          after : 5aab090 -- 0529d31 -- efee0cd -- df44d03 -- deec1c6  main   (no merge commit)
                          repair: 5aab090 -- 0529d31                                   main   (reset --keep to the entry below the merge)

  3. wrong branch         before: origin/main -- 0eece93 -- c8fec4d                    main
                          repair: origin/main                                          main
                                  ... fb8cb6c -- c7f48b2 -- ed2177f                    feature/pdf-tables (copies)

  4. detached HEAD        before: be53ce8 -- ba8c3d9 -- 266d3b2                        (no ref)
                          repair: be53ce8 -- ba8c3d9 -- 266d3b2                        hotfix/1.2.1

  5. wrong cherry-pick    before: 3171b7b -- e30eec3 -- 1bccf8e                        release/2.1  (a feature, not the fix)
                          repair: 3171b7b -- e30eec3 -- 5564cff                        release/2.1  (the fix)
```

In four of the five, the repair line contains commits that existed all along. Only the names moved.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/lab-12-4-wrong-rebase`. A hotfix branch was cut from `release/1.4`. `git rebase main`, typed by habit, replayed it onto `main`.

```bash
git status -sb
git log --oneline release/1.4..HEAD
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/01-symptom -->
```text
$ cd evalharness
$ git status -sb
## hotfix/judge-timeout
$ git log --oneline release/1.4..HEAD
37bb577 Log judge latency
6ef447a Retry judge on timeout
262dc41 Add judge timeout
7213db9 Pin judge model for 1.4
5783ca4 Add faithfulness metric
9288f20 Switch judge to JSON mode
$ git log --oneline --graph --all
* 37bb577 Log judge latency
* 6ef447a Retry judge on timeout
* 262dc41 Add judge timeout
* 7213db9 Pin judge model for 1.4
* 5783ca4 Add faithfulness metric
* 9288f20 Switch judge to JSON mode
| * dc1ff44 Pin judge model for 1.4
|/  
* 1d7a7cc Add judge prompt
* cd80329 Add eval runner
```
<!-- /snippet -->

Six commits ahead of the release branch where three belong.

**[ANIMATION]** graph: 1d7a7cc-9288f20-5783ca4 main; 1d7a7cc-dc1ff44 release/1.4; dc1ff44-c5f4fb7-eb1f140 hotfix/judge-timeout; HEAD=hotfix/judge-timeout; title:1._A_wrong_rebase => 1d7a7cc-9288f20-5783ca4 main; 5783ca4-7213db9-262dc41-6ef447a-37bb577 hotfix/judge-timeout; 1d7a7cc-dc1ff44 release/1.4; dc1ff44-c5f4fb7-eb1f140; reflog:c5f4fb7,eb1f140; HEAD=hotfix/judge-timeout; cmd:git_rebase_main; say:Six_commits_ahead_of_release/1.4_where_three_belong; name:wrong => 1d7a7cc-9288f20-5783ca4 main; 5783ca4-7213db9-262dc41-6ef447a-37bb577 hotfix/judge-timeout backup/rebased-hotfix; 1d7a7cc-dc1ff44 release/1.4; dc1ff44-c5f4fb7-eb1f140 rescue/pre-rebase; HEAD=hotfix/judge-timeout; cmd:git_branch_rescue/pre-rebase_'hotfix/judge-timeout@{2}'; say:Two_refs_hold_the_two_versions_of_the_branch; name:anchors => 1d7a7cc-9288f20-5783ca4 main; 5783ca4-7213db9-262dc41-6ef447a-37bb577 backup/rebased-hotfix; 1d7a7cc-dc1ff44 release/1.4; dc1ff44-c5f4fb7-eb1f140 rescue/pre-rebase; eb1f140-13305ef hotfix/judge-timeout; HEAD=hotfix/judge-timeout; cmd:git_rebase_--onto_rescue/pre-rebase_HEAD~1; say:The_two_old_commits,_and_Log_judge_latency_as_13305ef; name:fixed id=rb dx=260

**[ANIMATION]** step: wrong

A commit was added after the rebase, so `ORIG_HEAD` isn't the answer. Read the branch reflog. Predict which entry is the tip from before the rebase. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git reflog show hotfix/judge-timeout
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/02-evidence -->
```text
$ git reflog show hotfix/judge-timeout
37bb577 hotfix/judge-timeout@{0}: commit: Log judge latency
6ef447a hotfix/judge-timeout@{1}: rebase (finish): refs/heads/hotfix/judge-timeout onto 5783ca45370007569bfb3217980f447300484db9
eb1f140 hotfix/judge-timeout@{2}: commit: Retry judge on timeout
c5f4fb7 hotfix/judge-timeout@{3}: commit: Add judge timeout
dc1ff44 hotfix/judge-timeout@{4}: branch: Created from HEAD
```
<!-- /snippet -->

The entry below "rebase (finish)": `hotfix/judge-timeout@{2}`, which is `eb1f140`. Anchor it, and anchor the present state too.

```bash
git branch rescue/pre-rebase 'hotfix/judge-timeout@{2}'
git log --oneline release/1.4..rescue/pre-rebase
git branch backup/rebased-hotfix
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/03-anchor -->
```text
$ git branch rescue/pre-rebase 'hotfix/judge-timeout@{2}'
$ git log --oneline release/1.4..rescue/pre-rebase
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
$ git branch backup/rebased-hotfix
```
<!-- /snippet -->

**[ANIMATION]** step: rb.anchors

Two refs now hold the two versions of the branch. Nothing can be lost by what follows. Move only the commit that was made after the rebase onto the old tip.

**[ON SCREEN]** 🟡 CAUTION: `git rebase --onto <new base> <upstream>`. It moves the branch; the backup branch and the branch reflog are the recovery.

```bash
git rebase --onto rescue/pre-rebase HEAD~1
git log --oneline release/1.4..HEAD
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/04-transplant -->
```text
$ git rebase --onto rescue/pre-rebase HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/hotfix/judge-timeout.
$ git log --oneline release/1.4..HEAD
13305ef Log judge latency
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
```
<!-- /snippet -->

**[ANIMATION]** step: rb.fixed

Three commits on `release/1.4` again: the two old ones with their old IDs, and "Log judge latency" as `13305ef`. A wrong rebase is repaired with a correct rebase.

**[TERMINAL]** Replay `labs/run ch13/lab-12-5-bad-merge`. The branch you meant to merge is `feature/citations`.

```bash
git merge exp/few-shot
git log --oneline
```

<!-- snippet: ch13/lab-12-5-bad-merge/02-disaster -->
```text
# The branch you meant to merge is feature/citations.
$ git merge exp/few-shot
Updating 0529d31..deec1c6
Fast-forward
 examples.txt | 4 ++++
 system.txt   | 1 -
 2 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 examples.txt
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
$ cat system.txt
You answer questions about our product documentation.
```
<!-- /snippet -->

Read the word "Fast-forward".

**[ANIMATION]** graph: 5aab090-0529d31 main; 0529d31-efee0cd-df44d03-deec1c6 exp/few-shot; ^0529d31-3aae83f feature/citations; HEAD=main; title:2._A_bad_merge,_fast-forward => + deec1c6 main; cmd:git_merge_exp/few-shot; say:Fast-forward:_no_merge_commit; name:ff => + 0529d31 main; cmd:git_reset_--keep_ORIG__HEAD; say:Only_main_moved_back; name:back => + deec1c6 main; cmd:git_merge_exp/few-shot; say:A_second_copy_of_the_incident; name:again => + df44d03 main; deec1c6 ORIG_HEAD; cmd:!git_reset_--hard_HEAD~1; say:HEAD~1_is_one_commit_back_along_the_merged_branch; name:recipe => + deec1c6 main; df44d03 ORIG_HEAD; cmd:!git_reset_--hard_ORIG__HEAD; say:Two_commands_late:_back_in_the_merged_state; name:late => + 0529d31 main@{3}; cmd:git_reflog_show_main; say:The_entry_below_the_merge_line_is_where_main_was; name:found id=mg dx=260 at_state_1=8 at_ff=25

**[ANIMATION]** step: ff

Three work-in-progress commits are on `main`, and there is no merge commit.

**[PAUSE]**

```bash
git reflog -2
git log --oneline -1 ORIG_HEAD
git log --oneline ORIG_HEAD..HEAD
```

<!-- snippet: ch13/lab-12-5-bad-merge/03-evidence -->
```text
$ git reflog -2
deec1c6 HEAD@{0}: merge exp/few-shot: Fast-forward
0529d31 HEAD@{1}: checkout: moving from exp/few-shot to main
$ git log --oneline -1 ORIG_HEAD
0529d31 Add prompt loader
$ git log --oneline ORIG_HEAD..HEAD
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
```
<!-- /snippet -->

`ORIG_HEAD..HEAD` lists what the merge brought in. The merge was the last command and merge writes the slot, so `ORIG_HEAD` is valid here.

```bash
git reset --keep ORIG_HEAD
git log --oneline
git merge feature/citations
```

<!-- snippet: ch13/lab-12-5-bad-merge/04-recover -->
```text
$ git reset --keep ORIG_HEAD
$ git log --oneline
0529d31 Add prompt loader
5aab090 Add system prompt
$ git merge feature/citations
Updating 0529d31..3aae83f
Fast-forward
 system.txt | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

**[ANIMATION]** step: mg.back

`--keep` and not `--hard`. The experiment branch still exists. Only `main` moved back.

**[ANIMATION]** step: mg.again

Now the recipe from a tutorial, in a second copy of the incident. Quick quiz, two options. Does `main` end up at `0529d31`, where it was before the merge, or at `df44d03`? Say it out loud.

**[PAUSE]**

```bash
git reset --hard HEAD~1
git log --oneline
```

<!-- snippet: ch13/lab-12-5-bad-merge/06-failure -->
```text
$ cd ../promptstore-incident
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
# The recipe from a tutorial: "undo the merge" by dropping one commit.
$ git reset --hard HEAD~1
HEAD is now at df44d03 WIP: longer examples
$ git log --oneline
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
# Still two experiment commits. The other recipe:
$ git reset --hard ORIG_HEAD
HEAD is now at deec1c6 WIP: drop the refusal rule
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
```
<!-- /snippet -->

**[ANIMATION]** step: mg.recipe

Option two, `df44d03`. After a fast-forward, `HEAD~1` is one commit back along the merged branch. Almost everyone expects the old tip.

**[ANIMATION]** step: mg.late

The second recipe, `git reset --hard ORIG_HEAD`, brings the third commit back: the first reset had written the slot.

**[ANIMATION]** end

**[ON SCREEN]** The first root-cause box of section 13.8.

```text
Observed behavior : "git reset --hard HEAD~1" after a merge leaves two of the three merged commits on main;
                    "git reset --hard ORIG_HEAD" then brings the third one back
Git state         : the merge was a fast-forward: main moved from 0529d31 to deec1c6 along three commits,
                    and no merge commit was created
Mechanism         : HEAD~1 is the first parent of the tip. After a true merge that is the previous tip of
                    main. After a fast-forward it is the previous commit of the branch that was merged.
                    The first reset wrote ORIG_HEAD = deec1c6, so the second one returned to the merged state
Root cause        : the recipe assumes a merge commit, and "ORIG_HEAD" was used two commands late
Why Git does this : a fast-forward only moves a ref (Chapter 8); there is nothing to mark where it started
                    except the reflog and, for one command, ORIG_HEAD
Correct fix       : read "git reflog show main" and reset to the entry below the merge line
Prevention        : undo a merge with ORIG_HEAD immediately, or by reflog entry; never by counting parents
```

The root cause: the recipe assumes a merge commit, and `ORIG_HEAD` was used two commands late.

```bash
git reflog show main
```

<!-- snippet: ch13/lab-12-5-bad-merge/07-recovery-read -->
```text
$ git reflog show main
deec1c6 main@{0}: reset: moving to ORIG_HEAD
df44d03 main@{1}: reset: moving to HEAD~1
deec1c6 main@{2}: merge exp/few-shot: Fast-forward
0529d31 main@{3}: commit: Add prompt loader
5aab090 main@{4}: commit (initial): Add system prompt
```
<!-- /snippet -->

The line "merge exp/few-shot: Fast-forward" is the accident.

**[ANIMATION]** step: mg.found

The line below it, `main@{3}`, is where `main` was before.

**[TERMINAL]** Replay `labs/run ch13/lab-12-6-wrong-branch`. You committed twice on `main` while you believed you were on the feature branch. Nothing is pushed.

```bash
git status -sb
git log --oneline --graph --all
git log --oneline origin/main..main
```

<!-- snippet: ch13/lab-12-6-wrong-branch/01-symptom -->
```text
$ cd ingest
$ git status -sb
## main...origin/main [ahead 2]
$ git log --oneline --graph --all
* c8fec4d Add a table fixture for tests
* 0eece93 Keep table rows together when chunking
| * fb8cb6c Parse PDF tables
|/  
* 4711dcc Add chunker
* 5a80a30 Add document loader
$ git log --oneline origin/main..main
c8fec4d Add a table fixture for tests
0eece93 Keep table rows together when chunking
```
<!-- /snippet -->

`origin/main..main` is the precise name of the misplaced work: the commits on `main` that the server doesn't have.

**[ANIMATION]** graph: 5a80a30-4711dcc origin/main; 4711dcc-0eece93-c8fec4d main; ^4711dcc-fb8cb6c feature/pdf-tables; HEAD=main; title:3._Commits_on_the_wrong_branch => + fb8cb6c-c7f48b2-ed2177f feature/pdf-tables; HEAD=feature/pdf-tables; cmd:git_cherry-pick_origin/main..main; say:Copy_first; name:copy => + 4711dcc main; reflog:0eece93,c8fec4d; HEAD=main; cmd:git_reset_--keep_origin/main; say:Remove_second; name:remove id=wb dx=260 at_state_1=30

**[ANIMATION]** step: state-1

Nothing is lost here. The commits have the wrong name on them. Copy first, remove second.

```bash
git switch feature/pdf-tables
git cherry-pick origin/main..main
git log --oneline -3
```

<!-- snippet: ch13/lab-12-6-wrong-branch/02-copy -->
```text
$ git switch feature/pdf-tables
Switched to branch 'feature/pdf-tables'
$ git cherry-pick origin/main..main
[feature/pdf-tables c7f48b2] Keep table rows together when chunking
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 3 insertions(+)
[feature/pdf-tables ed2177f] Add a table fixture for tests
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 fixtures/table.json
$ git log --oneline -3
ed2177f Add a table fixture for tests
c7f48b2 Keep table rows together when chunking
fb8cb6c Parse PDF tables
```
<!-- /snippet -->

```bash
git switch main
git reset --keep origin/main
git status -sb
```

<!-- snippet: ch13/lab-12-6-wrong-branch/03-move-main-back -->
```text
$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)
$ git reset --keep origin/main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

**[ANIMATION]** step: wb.remove

The order matters. If you reset `main` first, the two commits are held by the reflog only, and you recover them as `origin/main..main@{1}`. The lab does it in that order on purpose. If the target branch doesn't exist yet, no copy is needed: create the branch at the current commit, then move `main` back. And if the commits were already pushed to a shared `main`, don't rewind it: cherry-pick them to the feature branch and revert them on `main`.

**[TERMINAL]** Replay `labs/run ch13/lab-12-7-detached-head`. Work that you did "a few days ago" is on no branch. You remember checking out a tag. The warning that Git prints when you leave such commits scrolled away long ago.

```bash
git reflog
```

<!-- snippet: ch13/lab-12-7-detached-head/02-reflog -->
```text
$ git reflog
f4a81dc HEAD@{0}: commit: Document the endpoints
20459b3 HEAD@{1}: checkout: moving from 852224fe93ed50676b587ace22cee739d967505f to main
852224f HEAD@{2}: commit: Experiment: disable response cache
f6f6bbb HEAD@{3}: checkout: moving from main to HEAD~1
20459b3 HEAD@{4}: commit: Export latency metrics
f6f6bbb HEAD@{5}: checkout: moving from 266d3b2a96a6a113c06fe5974b09562b1d3f440b to main
266d3b2 HEAD@{6}: commit: Hotfix: reject empty prompts
ba8c3d9 HEAD@{7}: commit: Hotfix: cap max_tokens at 4096
be53ce8 HEAD@{8}: checkout: moving from main to v1.2.0
f6f6bbb HEAD@{9}: commit: Add streaming endpoint
be53ce8 HEAD@{10}: commit: Add request limits
3838324 HEAD@{11}: commit (initial): Add inference endpoint
```
<!-- /snippet -->

The marks of a detached session: a "checkout: moving from main to" a tag or a commit, commits above it, and a "checkout: moving from" forty hexadecimal digits "to main" that ends it. There are two sessions in this log. Reading reflogs of real length for such patterns is slow. Predict what `git fsck --no-reflogs` reports.

```bash
git fsck --no-reflogs
git log --oneline --graph 266d3b2 852224f --not --all
```

<!-- snippet: ch13/lab-12-7-detached-head/03-fsck -->
```text
$ git fsck --no-reflogs
dangling commit 852224fe93ed50676b587ace22cee739d967505f
dangling commit 266d3b2a96a6a113c06fe5974b09562b1d3f440b
$ git log --oneline --graph 266d3b2 852224f --not --all
* 852224f Experiment: disable response cache
* 266d3b2 Hotfix: reject empty prompts
* ba8c3d9 Hotfix: cap max_tokens at 4096
```
<!-- /snippet -->

Two dangling commits, tips that no ref names, and the graph shows what hangs on each.

**[ANIMATION]** graph: 3838324-be53ce8-f6f6bbb-20459b3-f4a81dc main; be53ce8 v1.2.0; be53ce8-ba8c3d9-266d3b2; ^f6f6bbb-852224f; HEAD=main; reflog:ba8c3d9,266d3b2,852224f; dangling:266d3b2,852224f; cmd:git_fsck_--no-reflogs; title:4._Detached_HEAD => 3838324-be53ce8-f6f6bbb-20459b3-f4a81dc main; be53ce8 v1.2.0; be53ce8-ba8c3d9-266d3b2 hotfix/1.2.1; ^f6f6bbb-852224f exp/no-response-cache; HEAD=main; cmd:git_branch_hotfix/1.2.1_266d3b2; say:Each_line_has_a_name_now; name:anchored id=dh dx=260 at_state_1=15

**[ANIMATION]** step: state-1

A line of two hotfix commits, and a single experiment.

**[PAUSE]**

```bash
git branch hotfix/1.2.1 266d3b2
git branch exp/no-response-cache 852224f
git log --oneline --graph --all
```

<!-- snippet: ch13/lab-12-7-detached-head/05-anchor -->
```text
$ git branch hotfix/1.2.1 266d3b2
$ git branch exp/no-response-cache 852224f
$ git log --oneline --graph --all
* f4a81dc Document the endpoints
* 20459b3 Export latency metrics
| * 852224f Experiment: disable response cache
|/  
* f6f6bbb Add streaming endpoint
| * 266d3b2 Hotfix: reject empty prompts
| * ba8c3d9 Hotfix: cap max_tokens at 4096
|/  
* be53ce8 Add request limits
* 3838324 Add inference endpoint
```
<!-- /snippet -->

**[ANIMATION]** step: dh.anchored

Each line has a name now. What happens to the hotfixes next is an ordinary decision, made without time pressure.

**[TERMINAL]** Replay `labs/run ch13/lab-12-9-wrong-cherry-pick`. The fix to backport is "Fix off-by-one in rate limit window". The newest commit on `main` is not it.

```bash
git cherry-pick -x main
git log --oneline -3
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/02-disaster -->
```text
# The fix to backport is "Fix off-by-one in rate limit window". The newest commit on main is not it.
$ git cherry-pick -x main
[release/2.1 1bccf8e] Add per-tenant quotas
 Date: Mon Sep 7 10:08:00 2026 +0530
 2 files changed, 2 insertions(+)
 create mode 100644 quotas.yaml
$ git log --oneline -3
1bccf8e Add per-tenant quotas
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git show --stat --format=%B HEAD
Add per-tenant quotas

(cherry picked from commit cad5d75479789f69b0c584495258e2ad3f7ce87f)


 quotas.yaml | 1 +
 router.py   | 1 +
 2 files changed, 2 insertions(+)
```
<!-- /snippet -->

`-x` recorded the source, which makes the mistake visible in review. The pick itself was clean, and that is the dangerous case: a wrong pick that conflicts gets attention, and a clean one ships.

**[ANIMATION]** graph: 239cf05-3171b7b-f028350-cad5d75 main; 3171b7b-e30eec3 release/2.1; HEAD=release/2.1; title:5._A_wrong_cherry-pick => + e30eec3-1bccf8e release/2.1; cmd:git_cherry-pick_-x_main; say:1bccf8e_is_a_copy_of_cad5d75:_a_feature,_not_the_fix; name:wrong => + e30eec3 release/2.1; reflog:1bccf8e; cmd:git_reset_--keep_'HEAD@{1}'; say:One_step_back,_by_reflog_entry; name:back => + e30eec3-5564cff release/2.1; cmd:git_cherry-pick_-x_main~1; say:The_right_pick:_5564cff,_a_copy_of_f028350; name:right id=cp dx=260 at_state_1=8 at_wrong=35

**[ANIMATION]** step: wrong

After it has finished and before a push, step the branch back by one reflog entry and pick the right commit.

```bash
git reset --keep 'HEAD@{1}'
git log --oneline -2
git cherry-pick -x main~1
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/04-recover -->
```text
$ git reset --keep 'HEAD@{1}'
$ git log --oneline -2
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git cherry-pick -x main~1
[release/2.1 5564cff] Fix off-by-one in rate limit window
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

**[ANIMATION]** step: cp.right

One step back, then the right pick, `5564cff`. After a push to a shared release branch, revert the wrong commit instead. And now the reflex from the opening, in a second copy of the incident.

```bash
git reset --hard ORIG_HEAD
git log --oneline
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/06-failure -->
```text
$ cd ../apigw-incident
$ git log --oneline -3
48b4def Add per-tenant quotas
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
# The wrong pick is already here. A recipe remembered from the merge chapter:
$ git reset --hard ORIG_HEAD
HEAD is now at f028350 Fix off-by-one in rate limit window
$ git log --oneline
f028350 Fix off-by-one in rate limit window
3171b7b Add request router
239cf05 Add rate limiter
$ git status -sb
## release/2.1
$ ls
limiter.py
router.py
```
<!-- /snippet -->

**[ANIMATION]** replay: stale

There's the opening again. The release branch lands on the history of `main`, the pinning commit turns dashed, and the reset writes the slot again.

**[ON SCREEN]** The second root-cause box of section 13.8.

```text
Observed behavior : after "git reset --hard ORIG_HEAD" the release branch shows the history of main,
                    and the release-only commit "Pin dependencies for 2.1" is gone
Git state         : ORIG_HEAD = f028350, written days earlier by a fast-forward merge on main
Mechanism         : git cherry-pick does not write ORIG_HEAD (section 13.5), so the slot held a value from
                    another operation on another branch; the reset moved release/2.1 to that commit
Root cause        : ORIG_HEAD was used as "undo the last command"; it means "before the last reset,
                    merge, rebase or am"
Why Git does this : ORIG_HEAD is one file with no notion of which branch or which command it belongs to
Correct fix       : git reflog show release/2.1, then reset --keep to the entry below the cherry-pick
Prevention        : undo by reflog entry; check "git log -1 ORIG_HEAD" before every use of ORIG_HEAD
```

The root cause: `ORIG_HEAD` was used as "undo the last command". It means "before the last reset, merge, rebase or am".

```bash
git reflog show release/2.1
git reflog -4
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/07-recovery-read -->
```text
$ git reflog show release/2.1
f028350 release/2.1@{0}: reset: moving to ORIG_HEAD
48b4def release/2.1@{1}: cherry-pick: Add per-tenant quotas
e30eec3 release/2.1@{2}: commit: Pin dependencies for 2.1
3171b7b release/2.1@{3}: branch: Created from main
$ git reflog -4
f028350 HEAD@{0}: reset: moving to ORIG_HEAD
48b4def HEAD@{1}: cherry-pick: Add per-tenant quotas
e30eec3 HEAD@{2}: commit: Pin dependencies for 2.1
3171b7b HEAD@{3}: checkout: moving from main to release/2.1
```
<!-- /snippet -->

In the branch reflog, `release/2.1@{2}` is the state before the wrong pick: `e30eec3`, "Pin dependencies for 2.1". The result of the bad reset looked plausible, which is what makes this failure expensive. That's the missing file from the opening.

## COMMON MISTAKES

Five mistakes to watch for.

1. **`git reset --hard ORIG_HEAD` after a cherry-pick, or a few commands after a rebase.** Root cause: `ORIG_HEAD` is one slot written by reset, merge, rebase and am; it holds a value from an earlier operation, possibly on another branch.
2. **"Undo the last merge" with `HEAD~1`.** Root cause: a fast-forward creates no merge commit, so `HEAD~1` is a commit of the merged branch, not the previous tip.
3. **Resetting a rebased branch to its old tip when work was added afterwards.** Root cause: the new commit sits on the rebased commits; anchor both tips and transplant the new commit with `--onto`.
4. **Moving `main` back before copying the misplaced commits.** Root cause: after the reset only the reflog names them; copy first, remove second.
5. **Rewinding a shared branch to remove a pushed merge or pick.** Root cause: others have the commits and will bring them back or diverge; add a revert instead.

## PRODUCTION EXAMPLE

Now, out of the lab. A platform team maintains a release branch for an API gateway. On a Friday an engineer backports "the rate limit fix" by cherry-picking the tip of `main`. The tip is a feature, per-tenant quotas, and the pick applies cleanly. It's not pushed yet.

**[ANIMATION]** step: cp.right

**[ANIMATION]** say: In_the_lab:_one_step_back_by_reflog_entry,_then_the_right_pick

A reviewer notices the `-x` line in the message, which names a source commit that isn't the fix. The engineer opens the reflog of the release branch, not of HEAD, takes the entry below the cherry-pick line, and moves the branch there with `--keep`. Then he picks the right commit, again with `-x`. Before pushing he compares the release branch with its state on the server and sees exactly one new commit that changes one line. The whole incident is four commands, and none of them could have overwritten uncommitted work.

Had the pick already been pushed, the same team's rule says: revert on the release branch, and explain in the revert message which commit was meant.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Lab 12.4, "A wrong rebase", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

Start from the symptom. Before you read the reflog, predict how many entries the branch reflog has for the rebase, and which selector names the old tip. Before the repair, draw the graph you expect afterwards, with the number of commits ahead of the release branch.

The challenge is Lab 12.6, "Commits on the wrong branch", in the same file. It resets `main` first on purpose. Predict the range expression that names the two commits afterwards.

## INTERVIEW QUESTION

**[ON SCREEN]** Q194: "`git reset --hard ORIG_HEAD` restored the wrong state. Explain the mechanism and the correct procedure."

Pause and answer out loud.

**[PAUSE]**

A strong answer starts with what `ORIG_HEAD` is on disk and which commands write it, and names at least two common commands that don't. From that it derives how the slot can hold a value from another operation or another branch. It then gives the procedure, not a replacement recipe: which log to read, which line to take, how to anchor before moving, and which form of reset refuses to overwrite uncommitted changes. It closes with the check that would have prevented the incident, which is one read-only command.

## RECAP

Let's land this. You should now be able to say:

- After a rebase, the old tip is the entry below "rebase (finish)" in the branch reflog; work added later is transplanted with `--onto`.
- An unpushed merge is undone by reflog entry or by `ORIG_HEAD` immediately; a pushed merge is reverted.
- Commits on the wrong branch are copied first and removed second.
- Detached work is in the HEAD reflog, and `git fsck --no-reflogs` lists its tips.
- I check `git log -1 ORIG_HEAD` before every use of it, and I prefer `git reset --keep`.

## HOMEWORK

Read the rest of section 13.8 in [Chapter 13](../../textbook/ch13-recovery.md). Do Lab 12.5, "A bad merge", Lab 12.7, "Lost work in detached HEAD", and Lab 12.9, "A wrong cherry-pick", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

Today you undid five accidents by reading the right log. Do the wrong rebase lab before the next video. Next time: uncommitted work, and the remote side. Until then, look at the state first and type second. See you in the next one.

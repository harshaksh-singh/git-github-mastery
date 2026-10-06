# V052: What a rebase is, and why every rebased commit has a new ID

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 18
- **Prerequisites:** V019, V030, V045
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), sections 9.2 and 9.3 (hook from section 9.1)
- **Demo scripts:** `labs/ch09/rebase-basic.sh`, `labs/ch09/rebase-by-hand.sh`

## HOOK

**[ON SCREEN]** Four questions, appearing one at a time.

Four questions a CTO can ask, calmly, after a week in which someone rebased.

"Asha pushed a commit to the feature branch on Tuesday. On Wednesday it was gone from GitHub, and after her next pull it was gone from her laptop as well. Nobody deleted anything. Where is it?"

"The pull request had three commits before the review and three commits after it, with the same titles. The reviewer approved the first version. What exactly is different in the second one?"

"Why does the history of the ingest branch contain every commit twice?"

"A developer says the rebase finished without an error and one of his commits is not in the branch any more. Is that possible?"

The fourth answer is "yes". Hold on to that one. You'll see how it can happen before this video ends. And all four answers start from one fact, which is the subject of this video.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair: a new module starts here. And here's that fact, in the textbook's words: a rebase doesn't move or change commits. It writes new commits and then moves a ref. A commit is one saved snapshot of the project, and a ref is a name, such as a branch, that holds a commit ID.

**[ANIMATION]** remotes: [your clone] A-B-C feature; HEAD=none || [the server] A-B-C feature; HEAD=none || [another clone] A-B-C feature; HEAD=none => + A-M-B′-C′ feature; reflog:B,C; cmd:git_rebase; say:Two_histories,_side_by_side,_for_a_while; name:other-clones || || title=A_rebase_writes_new_commits_and_moves_a_ref

**[ANIMATION]** step: other-clones

The old commits are still in the object database. Other clones still have them. The server still has them, until someone pushes over them. Every surprise in the rebase module is a consequence of two histories existing side by side for a while: the one you rewrote, and the one everybody else still holds.

**[ANIMATION]** end

So this first video does two things and nothing more. It shows you a plain rebase, before and after, and then rebuilds that rebase by hand from three simpler commands, so that there's no magic left in it. And it opens an original commit and its copy side by side, field by field, so that you can say exactly why the copy has a new ID.

The project in this module is `ragkit`, a small retrieval-augmented answering service.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Describe a rebase as copying commits onto a new base and moving the branch.
- Explain from the commit object why each copy has a new ID even with an identical diff.
- Show where the original commits are after the rebase.
- Perform a rebase by hand with `git switch --detach`, `git cherry-pick` and a branch move.

## CONCEPT

**[ANIMATION]** graph: 8afc6bd-5ee19f0-af65a92-bd62876 feat/rerank; 8afc6bd-589d18b-82f1fbb main; HEAD=feat/rerank => bd62876 feat/rerank; 82f1fbb main; HEAD=82f1fbb; name:detach => 82f1fbb-742ab58-ade2990-976a161; bd62876 feat/rerank; 82f1fbb main; HEAD=976a161; name:replay => 976a161 feat/rerank; 82f1fbb main; bd62876 ORIG_HEAD; HEAD=feat/rerank; reflog:5ee19f0,af65a92,bd62876; name:moves title=git_rebase_main,_step_by_step id=four

**[ANIMATION]** step: four.state-1

In one sentence: `git rebase <upstream>` 🟡 CAUTION takes the commits that your branch has and `<upstream>` doesn't have, creates a copy of each one on top of `<upstream>`, in order, and then points your branch at the last copy.

Why would you want that? There are two everyday uses. One is bringing a feature branch up to date before review, so that the reviewer and CI, the automated checks, see your change on top of today's `main`. The other is tidying your own commits before anyone else reads them.

Precisely. The manual describes `git rebase <upstream>` as four steps.

**[ON SCREEN]** The four steps.

**[ANIMATION]** step: four.state-1

One. Make the list of commits to replay: everything reachable from the current branch and not from `<upstream>`, the same set that `git log <upstream>..HEAD` prints, minus commits whose change is already in `<upstream>`, and minus merge commits. Both exceptions get their own videos. On screen, the list is the three commits of `feat/rerank`.

**[ANIMATION]** step: four.detach

Two. Detach HEAD at `<upstream>`. Detached means that HEAD names a commit directly, here the tip of `main`, and not a branch.

**[ANIMATION]** step: four.replay

Three. Replay the commits one by one, oldest first. Each replay is a cherry-pick: one commit's change, applied on top of HEAD as a new commit. Inside, it's a three-way merge whose base is the parent of the original commit, whose "ours" side is HEAD, and whose "theirs" side is the original commit. The result is committed with the original author, author date and message, and with you, now, as committer.

**[ANIMATION]** step: four.moves

Four. Move the branch ref to the last new commit, and attach HEAD to the branch again.

Two words in that description deserve attention. "Reachable": Git has no notion of a parent branch, so the set of commits is computed from the graph, not from where you believe the branch started. And "copy": a commit object is never modified. The copies are new objects with new commit IDs.

Inside `.git`: new commit objects, and new tree objects wherever the combined content differs from anything stored before. Blobs, the stored file contents, are reused when file content is unchanged. One branch ref is rewritten, once, at the end. HEAD is detached while the rebase runs. `ORIG_HEAD` records the old tip. The reflogs of HEAD and of the branch, Git's local lists of where each has been, record every step.

**[ANIMATION]** say: A_new_parent_means_a_new_ID,_for_this_commit_and_for_every_commit_after_it

Now the ID. In one sentence: a commit ID is a hash of the commit object, the commit object names its parent and its tree, and a replayed commit has a different parent and usually a different tree, so it can't have the same ID.

And because each commit names its parent by ID, a new ID for one commit forces a new ID for every commit after it. IDs change from the first rewritten commit onward, never before it.

**[ANIMATION]** end

When not to rebase? The textbook calls it the most important judgment in the chapter. Both everyday uses are safe on a branch that only you use, and both become a team incident on a branch that others have based work on.

## MENTAL MODEL

**[ON SCREEN]** "Rebase copies."

A picture helps. The textbook's analogy: you wrote three amendments to version 4 of a contract. Meanwhile the other party issued version 6. Rebasing is redoing your three amendments, one after the other, against version 6, so that the file reads as if you had started from version 6.

**[ANIMATION]** rebase: amendments onto contract common=v4 main_only=v6 feature_only=A1,A2,A3 cmd=off title=Three_amendments,_redone_against_version_6 say_setup=Three_amendments,_written_against_version_4 say_lift=Each_amendment_is_taken_in_turn say_copy=and_redone_against_version_6 say_ghost=The_originals_are_not_shredded:_they_stay_in_the_drawer say_move=Rebase_copies._Then_it_moves_one_label. id=contract

**[ANIMATION]** step: contract.ghost

It breaks in two places, and both are the lesson. First, the three amendments you wrote against version 4 aren't shredded. They stay in the drawer, the object database, reachable through the reflog. Second, nobody retypes anything. Each amendment is carried over by a three-way merge that Git computes, and that merge can stop and ask you to decide.

**[ANIMATION]** step: contract.move

From today, stop saying "rebase moves my commits". Say "rebase copies". The word "moves" hides the originals, and the originals are where every one of the CTO's four questions gets answered.

## DIAGRAM

**[ANIMATION]** graph: 8afc6bd-5ee19f0-af65a92-bd62876 feat/rerank; 8afc6bd-589d18b-82f1fbb main; HEAD=feat/rerank => 82f1fbb-742ab58-ade2990-976a161 feat/rerank; 82f1fbb main; bd62876 ORIG_HEAD feat/rerank@{1}; HEAD=feat/rerank; reflog:5ee19f0,af65a92,bd62876 title=Before_and_after_git_rebase_main id=ba

**[DIAGRAM]** First the "before" picture. Then, for "after", do not erase anything: leave the three original commits in place, remove only the label `feat/rerank` from them, and draw the three copies on top of `main`.

```text
Before
            5ee19f0---af65a92---bd62876                    feat/rerank
           /
  8afc6bd---589d18b---82f1fbb                              main

After "git rebase main", run on feat/rerank
            5ee19f0---af65a92---bd62876                    no branch: ORIG_HEAD, feat/rerank@{1}
           /
  8afc6bd---589d18b---82f1fbb                              main
                             \
                              742ab58---ade2990---976a161  feat/rerank   (HEAD -> feat/rerank)
```

**[ANIMATION]** step: ba.state-1

First the before picture, with the real IDs. `feat/rerank` has three commits of its own, cut from `8afc6bd`. `main` has gained two.

**[ANIMATION]** step: ba.state-2

After the rebase, nothing was erased. Six commits where there were three. The upper three have no branch, and two names still reach them: `ORIG_HEAD` and the reflog entry `feat/rerank@{1}`.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/rebase-basic`. `feat/rerank` was cut from the first commit of `main`; since then `main` gained two commits.

**Step 1: before.**

<!-- snippet: ch09/rebase-basic/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 82f1fbb (HEAD -> main) Upgrade model to small-v2
* 589d18b Add README
| * bd62876 (feat/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Three commits on the branch: `5ee19f0`, `af65a92`, `bd62876`. Predict: after `git rebase main`, how many of these three IDs appear in the branch's log? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/rebase-basic/02-rebase -->
```text
$ git switch feat/rerank
Switched to branch 'feat/rerank'
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

`Rebasing (1/3)` is a progress line. In a terminal the three lines overwrite each other. The last line names the one ref that moved.

<!-- snippet: ch09/rebase-basic/03-after -->
```text
$ git log --oneline --graph --decorate --all
* 976a161 (HEAD -> feat/rerank) Enable reranking in config
* ade2990 Call reranker from retriever
* 742ab58 Add reranker skeleton
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
$ git log --oneline main..ORIG_HEAD
bd62876 Enable reranking in config
af65a92 Call reranker from retriever
5ee19f0 Add reranker skeleton
```
<!-- /snippet -->

None of them. The branch now holds `742ab58`, `ade2990` and `976a161`, on top of `82f1fbb`. Same three subjects, three new IDs. And the second command shows that the three original commits still exist: `ORIG_HEAD` points at the old tip `bd62876`.

**Step 2: the objects.** Put the first commit of the branch before and after side by side. Quick quiz before you look. Which field of the commit object must differ in the copy? A, the author. B, the parent. C, the message. Your answer?

**[PAUSE]**

<!-- snippet: ch09/rebase-basic/04-objects -->
```text
# The first commit of the branch, before the rebase (reachable through ORIG_HEAD) ...
$ git cat-file -p ORIG_HEAD~2
tree bff5bbd64dc61559cfed48b794c4ac66aa8fd087
parent 8afc6bd28c2572af09f1b6c37d733535230e526f
author Lab User <you@example.com> 1788755580 +0530
committer Lab User <you@example.com> 1788755580 +0530

Add reranker skeleton
# ... and its replacement after the rebase.
$ git cat-file -p HEAD~2
tree 8cc3ecec7607fe1db26fe237762047f282c08338
parent 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
author Lab User <you@example.com> 1788755580 +0530
committer Lab User <you@example.com> 1788756000 +0530

Add reranker skeleton
```
<!-- /snippet -->

**[ON SCREEN]** The field table of section 9.3, with the differing rows highlighted.

```text
Field       Before                   After                    Why
---------   ----------------------   ----------------------   -----------------------------------------------------------
tree        bff5bbd...               8cc3ece...               The new snapshot also contains the README and the model
                                                              upgrade from main
parent      8afc6bd...               82f1fbb...               That is the point of the operation
author      Lab User, 1788755580     identical                Rebase keeps who wrote the change and when
committer   Lab User, 1788755580     Lab User, 1788756000     The committer is whoever created this object, at the time
                                                              it was created
message     identical                identical                Unless you reword it
```

B, the parent, and it's not alone. Three of the five inputs to the hash changed: tree, parent, committer. A copy would get a new ID even with the same parent and tree, because the committer date moves. That's why Git doesn't copy commits that would come out identical. It fast-forwards over them unless you pass `--no-ff`.

**Step 3: what did not change.** A patch ID is a hash of a commit's diff with line numbers ignored.

<!-- snippet: ch09/rebase-basic/05-patch-id -->
```text
$ git show ORIG_HEAD~2 | git patch-id --stable
cf1c4fb899863a713cf682e6a8101ba01f834cb4 5ee19f03aa988c15717abc4b6c14104fc8d23a97
$ git show HEAD~2 | git patch-id --stable
cf1c4fb899863a713cf682e6a8101ba01f834cb4 742ab5805e0a3077be749e44fb92159e284ee0ad
```
<!-- /snippet -->

Same patch ID in the first column, different commit IDs in the second. Git uses this equivalence to recognise "the same change under another ID". You'll meet it again when a rebase drops a commit on purpose. And that's how the CTO's fourth question can be a yes: step one leaves out a commit whose change is already in the upstream, and no error is printed.

**Step 4: the reflogs.**

<!-- snippet: ch09/rebase-basic/06-reflog -->
```text
$ git reflog -6
976a161 HEAD@{0}: rebase (finish): returning to refs/heads/feat/rerank
976a161 HEAD@{1}: rebase (pick): Enable reranking in config
ade2990 HEAD@{2}: rebase (pick): Call reranker from retriever
742ab58 HEAD@{3}: rebase (pick): Add reranker skeleton
82f1fbb HEAD@{4}: rebase (start): checkout main
bd62876 HEAD@{5}: checkout: moving from main to feat/rerank
$ git reflog show feat/rerank
976a161 feat/rerank@{0}: rebase (finish): refs/heads/feat/rerank onto 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
bd62876 feat/rerank@{1}: commit: Enable reranking in config
af65a92 feat/rerank@{2}: commit: Call reranker from retriever
5ee19f0 feat/rerank@{3}: commit: Add reranker skeleton
8afc6bd feat/rerank@{4}: branch: Created from HEAD
```
<!-- /snippet -->

Read the HEAD reflog from the bottom. Start, which is a checkout of `main`. Three picks. Finish, returning to the branch. That's the four steps of the manual, recorded. The branch's own reflog has one line for the whole rebase, and `feat/rerank@{1}` is the old tip, `bd62876`.

**Step 5: nothing to do.**

<!-- snippet: ch09/rebase-basic/07-nothing-to-do -->
```text
$ git rebase main
Current branch feat/rerank is up to date.
$ git switch main
Switched to branch 'main'
$ git rebase feat/rerank
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph --decorate --all
* 976a161 (HEAD -> main, feat/rerank) Enable reranking in config
* ade2990 Call reranker from retriever
* 742ab58 Add reranker skeleton
* 82f1fbb Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Rebase again, and the branch "is up to date". And rebasing `main` onto the feature branch copies nothing: `main` has no commits that the branch lacks, so it's moved forward to the same commit, `976a161`.

**Step 6: the same rebase by hand.** `labs/run ch09/rebase-by-hand`. Detach, cherry-pick the range, move the branch. `git cherry-pick` 🟡 CAUTION.

```bash
git switch --detach main
git cherry-pick main..feat/rerank
```

<!-- snippet: ch09/rebase-by-hand/01-detach-and-replay -->
```text
$ git switch --detach main
HEAD is now at 82f1fbb Upgrade model to small-v2
$ git cherry-pick main..feat/rerank
[detached HEAD 0dea106] Add reranker skeleton
 Date: Mon Sep 7 10:03:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 app/rerank.py
[detached HEAD 20d0897] Call reranker from retriever
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
Auto-merging config/model.yaml
[detached HEAD 4caa98e] Enable reranking in config
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

Three new commits on a detached HEAD. Try it now, thirty seconds, on paper: draw the graph as it is at this moment, and put the label `feat/rerank` where it points. Then say it out loud.

**[PAUSE]**

<!-- snippet: ch09/rebase-by-hand/02-before-the-branch-moves -->
```text
$ git log --oneline --graph --decorate --all
* 4caa98e (HEAD) Enable reranking in config
* 20d0897 Call reranker from retriever
* 0dea106 Add reranker skeleton
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
| * bd62876 (feat/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

**[ANIMATION]** graph: 8afc6bd-589d18b-82f1fbb-0dea106-20d0897-4caa98e; 82f1fbb main; 8afc6bd-5ee19f0-af65a92-bd62876 feat/rerank; HEAD=4caa98e; say:Three_new_commits,_and_only_HEAD_reaches_them => + 4caa98e feat/rerank; HEAD=feat/rerank; reflog:5ee19f0,af65a92,bd62876; cmd:git_switch_-C_feat/rerank; say:The_branch_is_reset_to_HEAD; name:resets title=The_same_rebase_by_hand id=hand

**[ANIMATION]** step: hand.state-1

Still at the old commits. The three new commits belong to no branch, and only HEAD reaches them. This is the state a real rebase is in for most of its running time.

<!-- snippet: ch09/rebase-by-hand/03-move-the-branch -->
```text
$ git switch -C feat/rerank
Switched to and reset branch 'feat/rerank'
$ git log --oneline --graph --decorate --all
* 4caa98e (HEAD -> feat/rerank) Enable reranking in config
* 20d0897 Call reranker from retriever
* 0dea106 Add reranker skeleton
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

`git switch -C <branch>` 🟡, `git checkout -B` in the manual and in older scripts, creates the branch at HEAD or, if it exists, resets it to HEAD. That's the whole trick of step 4.

**Step 7: compare with the real thing.** The demo keeps the hand-made result under a tag, puts the branch back with `git reset --hard` 🔴 on a clean tree, with the old tip taken from the reflog, and lets `git rebase` do the job.

<!-- snippet: ch09/rebase-by-hand/04-compare-with-rebase -->
```text
# Keep the hand-made result under a tag, put the branch back, and let "git rebase" do the job.
$ git tag by-hand
$ git reset --hard "feat/rerank@{1}"
HEAD is now at bd62876 Enable reranking in config
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --format="%h tree %t  %s" main..by-hand
4caa98e tree 273096f  Enable reranking in config
20d0897 tree 9b070ab  Call reranker from retriever
0dea106 tree 8cc3ece  Add reranker skeleton
$ git log --format="%h tree %t  %s" main..feat/rerank
a4cc3fb tree 273096f  Enable reranking in config
a9cc881 tree 9b070ab  Call reranker from retriever
2efc812 tree 8cc3ece  Add reranker skeleton
```
<!-- /snippet -->

Commit for commit, the trees are identical: `273096f`, `9b070ab`, `8cc3ece` in both lists. `git rebase` and three hand-typed cherry-picks built the same snapshots. The commit IDs differ only because the real rebase ran a few lab minutes later, so its committer dates differ. A commit ID doesn't record which command made the commit. It's a function of content: tree, parents, author, committer, dates, message.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Saying "rebase moved my commits" and then looking for the old IDs on the branch.** Root cause: a commit object is never modified; rebase wrote new objects and moved one ref.
2. **Expecting the same ID because the diff is identical.** Root cause: the ID hashes the commit object, whose parent, committer and usually tree changed; the patch ID is what stayed the same.
3. **Believing the originals are deleted.** Root cause: nothing was removed from the object database; `ORIG_HEAD` and the branch's reflog still name the old tip.
4. **Thinking the branch "remembers" where it started.** Root cause: Git has no notion of a parent branch; the commits to replay are computed by reachability from the graph.
5. **Rebasing and assuming everything that recorded an old ID still points at your work.** Root cause: review comments, CI statuses, deployment records and tags refer to commit IDs, and those commits are no longer on the branch.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: ba.state-2

**[ANIMATION]** say: The_model_card_cites_a_commit_that_is_on_no_branch

Now, out of the lab. A training job writes the commit ID of the code it ran into its run metadata. Two days later the engineer rebases the experiment branch, to bring it up to date before review. The model card now cites a commit that isn't on any branch. The commit still exists for a while, but nobody looking at the branch will find it.

**[ANIMATION]** cards: question=Before_you_rebase:_what_has_already_recorded_these_IDs? cards=a_review_comment_anchored_to_a_commit|a_CI_status|a_deployment_record|the_ID_in_run_metadata id=recorded at_1=36 at_2=48 at_3=55 at_4=62

**[ANIMATION]** step: recorded.4

The textbook's rule: before you rebase, ask what has already recorded these IDs. A review comment anchored to a commit, a CI status, a deployment record, the ID in run metadata. Tags don't follow a rebase. And signatures are part of the commit object: a replayed commit is a new object, signed only if you sign it now.

**[ON SCREEN]** Layer label: GitHub.

The "Rebase and merge" button performs this operation on GitHub's servers. According to the documentation, the commits that land on the base branch always have new commit IDs and an updated committer, and they're unsigned, because GitHub can't sign on your behalf. This is described from the documentation, and Chapter 17 covers the three merge buttons.

## PRACTICE EXERCISE

Your turn. Do Exercise 9.1, Level 1, "a plain rebase, before and after", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Predict in writing before the rebase:

- Which commits will be replayed? Write the command whose output is that list.
- After the rebase, which names will still reach the original commits?
- For the first replayed commit: which fields of the commit object will differ from the original, and which will not?

Then verify each prediction with a command. The challenge is Exercise 9.4, Level 2, "the old commits and the new ones", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q143: "Why does a rebase change commit hashes: why does every rebased commit have a new ID even when its diff is identical? Which fields of the commit object changed, and which did not?"

**[PAUSE]**

Answer out loud first. A strong answer starts from what a commit ID is computed from, and goes through the fields one by one, saying for each whether it changes and why. It explains why the change propagates to every later commit and never to an earlier one. It names the thing that does stay equal between an original and its copy, and what Git uses it for. If you can add what follows for anything that has stored the old IDs, you have connected the mechanism to practice.

## RECAP

**[ANIMATION]** replay: four

Let's land this. You should now be able to say:

A rebase lists the commits my branch has and the upstream lacks, detaches HEAD at the upstream, replays each commit as a cherry-pick, and then moves the branch to the last copy.

**[ANIMATION]** walk: columns=field,before,after rows=tree:bff5bbd:8cc3ece|parent:8afc6bd:82f1fbb|author:Lab_User,_1788755580:identical|committer:Lab_User,_1788755580:Lab_User,_1788756000|message:identical:identical marks=1.3:hl,2.3:hl,4.3:hl,3.3:dim,5.3:dim title=The_first_commit_of_the_branch,_before_and_after id=fields

**[ANIMATION]** step: fields.5

The copies are new objects: parent, committer and usually tree differ, so the ID differs, and every later commit changes with it. Author, author date and message are kept, and the patch ID is the same.

**[ANIMATION]** step: ba.state-2

The originals are still in the object database, reachable through `ORIG_HEAD` and the reflog.

**[ANIMATION]** step: hand.resets

I can do the same by hand with a detached HEAD, `git cherry-pick` of the range, and `git switch -C`.

## HOMEWORK

Read sections 9.1 to 9.3 of [Chapter 9](../../textbook/ch09-rebase.md).

You rebuilt a rebase by hand today, so there's no magic left in it: it copies, and then it moves one ref. Do the exercise, and write your predictions first. Next time: what rebase does internally, the state directory, HEAD and the special refs. Until then, look at the state first and type second. See you in the next one.

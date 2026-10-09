# V049: Reverting a merge, and the re-merge problem

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 8, Undoing changes
- **Planned minutes:** 22
- **Prerequisites:** V036, V048
- **Textbook sections:** [Chapter 11](../../textbook/ch11-reset-revert-restore.md), section 11.9
- **Demo scripts:** `labs/ch11/revert-merge.sh`, `labs/ch11/revert-merge-rebuild.sh`, `labs/ch11/revert-squash-remerge.sh`

## HOOK

**[ON SCREEN]** "We reverted the merge of the reranker branch last week. Today the fixed branch was merged again and half of the feature is missing in production. How is that possible?"

Read the CTO's question once more, and notice what isn't in it. No conflict. No error. No red check. The second merge said "Merge made by the 'ort' strategy", listed one file, and exited with status 0. `main` now contains the fix for a feature that `main` doesn't contain. Keep that sentence. In step four you watch it happen.

You saw this once as a pointer at the end of the merge module. Today you get the mechanism, the root cause in one line, and two correct ways out.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you reverted ordinary commits. A merge commit is different in one respect: it has two parents, the two commits it joined. So "the change it made" has two meanings, and you must tell Git which one you mean.

That part takes five minutes. The rest of the video is about what happens afterwards, because reverting a merge changes what every later merge of the same branch does. You'll merge a branch, revert the merge, try to merge it again, and watch Git say "Already up to date". Then you'll watch the dangerous variant, which looks like a success. Then the two repairs: revert the revert, or recreate the branch as new commits. And last, why a squash merge, which packs a branch into one ordinary commit, doesn't have this problem at all.

The project is a ranker for a retrieval service, and the branch is `feature/reranker`.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Revert a merge commit with `-m 1` and say what that choice means.
- Explain why merging the repaired branch again brings only the new commits.
- Repair the situation by reverting the revert or by recreating the branch.
- Contrast the behavior after a squash merge.

## CONCEPT

In one sentence: `git revert -m 1 <merge>` undoes the content that a merge brought into the branch, and leaves the merge itself in the commit graph, which changes what every later merge of the same branch does.

Take the two halves separately.

**[ANIMATION]** graph: fbb8230-31a221c-27bb9f5 main; ^fbb8230-719cc13-c3762df feature/reranker; c3762df-27bb9f5; HEAD=main => + role:31a221c:parent_1; role:c3762df:parent_2; name:parent-one => + 27bb9f5-7e5a38e main; cmd:git_revert_-m_1_27bb9f5; name:revert => + c3762df-6b4e788 feature/reranker; drop:parent_1,parent_2; cmd:git_log_--oneline_main..feature/reranker; name:fix => + note:c3762df:merge_base; range:6b4e788:what_the_next_merge_brings; cmd:git_merge-base_main_feature/reranker; name:base => + 7e5a38e-4b3560c main; range:; drop:c3762df; cmd:git_revert_7e5a38e; name:revert-the-revert => + 4b3560c-018849f main; 6b4e788-018849f; cmd:git_merge_feature/reranker; name:then-merge title=Merge,_revert,_and_merge_again id=rm dx=240

**[ANIMATION]** step: rm.parent-one

First half, the option. A merge commit has two parents, so the inverse has to be computed relative to one of them. `-m <parent-number>`, long form `--mainline`, chooses. On a branch that receives feature branches, the first parent is the branch's own previous tip, as the video on merge commits showed. So `-m 1` takes out what the merge brought in. On screen, the merge is `27bb9f5`. Parent one is `31a221c`, on `main`. Parent two is `c3762df`, the tip of the branch.

**[ANIMATION]** step: rm.revert

Second half, the consequence. The revert commit is an ordinary commit on top of the merge. It changed content. It didn't change the graph, and no commit can. The merge commit is still an ancestor of `main`, and through its second parent so are all the commits of the feature branch. Git's how-to on this situation says the same: a revert undoes the data a merge brought, and none of its effect on history.

**[ANIMATION]** step: rm.fix

Now recall what a merge is: it combines what each side changed since the merge base, the best common ancestor of the two sides. The branch has now gained one commit, a fix. Try it now, thirty seconds: point at the merge base of `main` and the branch. Say its ID out loud.

**[PAUSE]**

**[ANIMATION]** step: rm.base

It's `c3762df`. After the first merge, the merge base of `main` and the branch is the old tip of the branch. So at the next merge, only commits after that tip count as the branch's change. On `main`'s side, the revert is a change since the base. It deletes the feature, nothing opposes it, and it stays.

The manual states the rule bluntly: reverting a merge "declares that you will never want the tree changes brought in by the merge".

**[ANIMATION]** step: rm.then-merge

There are two ways out. Way one: revert the revert, and then merge. Way two: recreate the branch as new commits, which aren't ancestors of `main`, so an ordinary merge brings all of them.

**[ANIMATION]** end

When not to revert a merge at all? The how-to advises finding and reverting the single faulty commit, or fixing forward, and reverting a whole merge only when the merge as such was the mistake. There's a second cost. For `git bisect`, the binary search over commits, the revert is one large commit that undoes many small ones, and so is the later revert of the revert.

## MENTAL MODEL

**[ON SCREEN]** "A revert takes the content out. It cannot take the merge out of the graph."

Go back to the ledger from the last video. A merge posted a whole batch of entries from another department, with a note: "batch received". The revert posts one reversing entry for the batch. The books now balance as if the batch had never arrived. But the note "batch received" is still there, and the clerk who processes the next delivery from that department reads the note first. Everything listed on it is skipped as already received.

**[ANIMATION]** graph: *1-*2-?batch_received-?reversing_entry; ^*1-*3-*4; *4-?batch_received; HEAD=none; say:The_note_is_still_there:_merge_reads_the_graph,_not_intentions title=The_ledger,_one_more_time id=clerk

**[ANIMATION]** step: clerk.state-1

Where the picture breaks: a clerk could be told "that batch was reversed, take it again". Git can't be told. Merge reads the graph, not intentions. The only ways to say it are in the graph's own language: post an entry that reverses the reversal, or deliver the same goods under new delivery numbers.

## DIAGRAM

**[ANIMATION]** step: rm.then-merge

**[DIAGRAM]** Build it left to right along `main`: the fork, the first merge, the revert, the revert of the revert, the second merge. Then the branch above, with its late commit.

```text
          719cc13---c3762df-------------------------------6b4e788      feature/reranker
         /                 \                                     \
fbb8230---31a221c-----------27bb9f5----7e5a38e----4b3560c---------018849f   main (HEAD)
                            merge      revert     revert of the   second
                                       -m 1       revert          merge
```

Read it left to right along `main`: the fork, the first merge `27bb9f5`, the revert `7e5a38e`, the revert of the revert `4b3560c`, and the second merge `018849f`.

Put your finger on `c3762df`. After the first merge it's an ancestor of `main`, and it stays one whatever is committed afterwards. The second merge can only bring what is to the right of it on the branch: `6b4e788`.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch11/revert-merge`.

**Step 1: the merge.**

<!-- snippet: ch11/revert-merge/01-merge -->
```text
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rank.py   | 2 ++
 rerank.py | 2 ++
 2 files changed, 4 insertions(+)
 create mode 100644 rerank.py
$ git log --oneline --graph
*   27bb9f5 Merge branch 'feature/reranker'
|\  
| * c3762df Call the reranker from the ranker
| * 719cc13 Add cross-encoder reranker
* | 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
```
<!-- /snippet -->

A true merge, `27bb9f5`, two branch commits. `rerank.py` is in the listing.

**Step 2: revert it.** `git revert` 🟡 CAUTION.

<!-- snippet: ch11/revert-merge/02-revert-needs-m -->
```text
$ git revert --no-edit HEAD
error: commit 27bb9f5a47a08961498a25b25288c07070ab2576 is a merge but no -m option was given.
fatal: revert failed
[exit status: 128]
$ git show -s --format="%h has parents: %p" HEAD
27bb9f5 has parents: 31a221c c3762df
$ git revert --no-edit -m 1 HEAD
[main 7e5a38e] Revert "Merge branch 'feature/reranker'"
 Date: Mon Sep 7 10:14:00 2026 +0530
 2 files changed, 4 deletions(-)
 delete mode 100644 rerank.py
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

Without `-m`, Git refuses: the commit is a merge but no `-m` option was given. The parents are `31a221c`, the previous tip of `main`, and `c3762df`, the tip of the branch. With `-m 1` the revert goes through, and `rerank.py` is gone from `main`.

<!-- snippet: ch11/revert-merge/03-revert-message -->
```text
$ git show -s --format=%B HEAD
Revert "Merge branch 'feature/reranker'"

This reverts commit 27bb9f5a47a08961498a25b25288c07070ab2576, reversing
changes made to 31a221c51824ee599e5d3059dd928398b65a63e6.

$ git log --oneline --graph -3
* 7e5a38e Revert "Merge branch 'feature/reranker'"
*   27bb9f5 Merge branch 'feature/reranker'
|\  
| * c3762df Call the reranker from the ranker
```
<!-- /snippet -->

The generated message records which parent was treated as the mainline: "reversing changes made to", followed by the ID of parent 1. And the graph: the revert, `7e5a38e`, sits on top of the merge. The merge is still there.

**Step 3: merge the branch again.** Nothing has changed on the branch. Predict the output of `git merge feature/reranker`. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch11/revert-merge/04-remerge-brings-nothing -->
```text
$ git merge feature/reranker
Already up to date.
$ git merge-base main feature/reranker
c3762df49c6a0dd31105d001abb9e995132ca99e
$ git rev-parse feature/reranker
c3762df49c6a0dd31105d001abb9e995132ca99e
```
<!-- /snippet -->

"Already up to date." And the two IDs below it are the same: the merge base of `main` and the branch is the branch tip. For Git, the branch is already merged.

**Step 4: the dangerous variant.** The team fixes the bug with one more commit on the branch, and merges. Quick quiz: what does `main` have afterwards? A, the whole feature plus the fix. B, only the fix. C, a conflict. Your answer?

**[PAUSE]**

<!-- snippet: ch11/revert-merge/05-remerge-brings-only-the-fix -->
```text
$ git log --oneline main..feature/reranker
6b4e788 Cap reranker candidates at 50
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 serve.yaml | 1 +
 1 file changed, 1 insertion(+)
$ ls
metrics.txt
rank.py
serve.yaml
$ cat serve.yaml
timeout_s: 30
rerank_top_k: 50
$ cat rank.py
def score(q, d):
    return bm25(q, d)
```
<!-- /snippet -->

B, only the fix. No conflict, no warning. One file changed: `serve.yaml` gained `rerank_top_k: 50`. There's no `rerank.py`, and `rank.py` has no import. `main` received the fix for a feature it doesn't contain. That's the sentence from the start of the video, on your own screen.

**[ON SCREEN]** The root-cause box of section 11.9.

```text
Observed behavior : After a merge was reverted, merging the fixed branch brings only the new commit.
Git state         : merge-base(main, feature/reranker) is c3762df, the old tip of the branch.
Mechanism         : A merge combines what each side changed since the merge base. The first merge
                    made the old branch commits ancestors of main, so only the commit after c3762df
                    counts as the branch's change. On main's side the revert is a change since the
                    base (it deletes the feature), nothing opposes it, and it stays.
Root cause        : The revert removed the content of the merge and left the merge in the graph.
Why Git does this : Merge reads the graph, not intentions. The manual says that reverting a merge
                    "declares that you will never want the tree changes brought in by the merge".
Correct fix       : Revert the revert and then merge, or recreate the branch as new commits.
Prevention        : Write the re-merge procedure into the message of the revert commit. Where you
                    can, revert the one faulty commit and keep the merge.
```

Here's the mechanism as a root-cause box. The revert removed the content of the merge and left the merge in the graph. The fix is one of two ways out, and the prevention is to write the re-merge procedure into the message of the revert commit.

**[ANIMATION]** end

**Step 5: way out 1, revert the revert.** The demo first takes the half-working merge away with `git reset --hard ORIG_HEAD` 🔴 DANGEROUS. The five answers, briefly, because you met them two videos ago. It moves the branch and rewrites the index and tracked files. It destroys uncommitted changes. Preview with `git status -s`, and by reading what `ORIG_HEAD` names. Commits come back through the reflog. And it's appropriate here because the tree is clean, the merge is unpublished, and it's the very next command after the merge.

<!-- snippet: ch11/revert-merge/06-revert-the-revert -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at 7e5a38e Revert "Merge branch 'feature/reranker'"
$ git revert --no-edit 7e5a38e
[main 4b3560c] Reapply "Merge branch 'feature/reranker'"
 Date: Mon Sep 7 10:30:00 2026 +0530
 2 files changed, 4 insertions(+)
 create mode 100644 rerank.py
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 serve.yaml | 1 +
 1 file changed, 1 insertion(+)
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
```
<!-- /snippet -->

`git revert 7e5a38e` reverts the revert and brings the content of the first merge back. Git 2.55 names such a commit `Reapply "..."`. Then the merge adds the fix, and `rerank.py` is in the listing.

<!-- snippet: ch11/revert-merge/07-final-graph -->
```text
$ git log --oneline --graph
*   018849f Merge branch 'feature/reranker'
|\  
| * 6b4e788 Cap reranker candidates at 50
* | 4b3560c Reapply "Merge branch 'feature/reranker'"
* | 7e5a38e Revert "Merge branch 'feature/reranker'"
* | 27bb9f5 Merge branch 'feature/reranker'
|\| 
| * c3762df Call the reranker from the ranker
| * 719cc13 Add cross-encoder reranker
* | 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
$ cat rank.py
from rerank import rerank

def score(q, d):
    return bm25(q, d)
```
<!-- /snippet -->

This is the graph of today's diagram. Merge, revert, reapply, second merge. And `rank.py` has its import line.

**Step 6: way out 2, recreate the branch.** `labs/run ch11/revert-merge-rebuild`. The idea: new commits aren't ancestors of `main`. The obvious command is `git rebase main`, which replays a branch's commits as new ones on top of `main`. Predict how many commits it replays. Say the number out loud.

**[PAUSE]**

<!-- snippet: ch11/revert-merge-rebuild/01-plain-rebase-leaves-the-work-out -->
```text
$ git log --oneline --graph --all
* 52be493 Cap reranker candidates at 50
| * 9a2eb67 Revert "Merge branch 'feature/reranker'"
| *   27bb9f5 Merge branch 'feature/reranker'
| |\  
| |/  
|/|   
* | c3762df Call the reranker from the ranker
* | 719cc13 Add cross-encoder reranker
| * 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
$ git rebase main feature/reranker
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/reranker.
$ git log --oneline main..feature/reranker
2b155de Cap reranker candidates at 50
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

One. A plain rebase replays only what `main` lacks, and `main` lacks only the fix. The feature is still missing. If you said three, you're in good company.

What works is `git rebase --no-ff` 🟡 from the commit where the branch started, an option the manual documents for exactly this case.

<!-- snippet: ch11/revert-merge-rebuild/02-recreate-the-branch -->
```text
# Where the branch started: the merge base of the two parents of the reverted merge.
$ git merge-base 27bb9f5^1 27bb9f5^2
fbb82301684fb07a59ac805d60f313294b62d3d5
$ git rebase --no-ff fbb8230 feature/reranker
Current branch feature/reranker is up to date, rebase forced.
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/reranker.
$ git log --oneline --graph --all
* 910d8d3 Cap reranker candidates at 50
* e9aea46 Call the reranker from the ranker
* b981ce8 Add cross-encoder reranker
| * 9a2eb67 Revert "Merge branch 'feature/reranker'"
| *   27bb9f5 Merge branch 'feature/reranker'
| |\  
| | * c3762df Call the reranker from the ranker
| | * 719cc13 Add cross-encoder reranker
| |/  
|/|   
| * 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
```
<!-- /snippet -->

**[ANIMATION]** graph: fbb8230-31a221c-27bb9f5-9a2eb67 main; fbb8230-719cc13-c3762df-52be493 feature/reranker; c3762df-27bb9f5; HEAD=feature/reranker => + ^fbb8230-b981ce8-e9aea46-910d8d3 feature/reranker; reflog:52be493; cmd:git_rebase_--no-ff_fbb8230_feature/reranker; name:replayed id=rebuild title=Way_out_2:_the_branch_as_new_commits

**[ANIMATION]** step: rebuild.replayed

Where did the branch start? At the merge base of the two parents of the reverted merge: `fbb8230`. "Rebase forced", three commits replayed. In the graph the three commits have new IDs and hang off `fbb8230` beside the old ones.

<!-- snippet: ch11/revert-merge-rebuild/03-merge-brings-everything -->
```text
$ git switch main
Switched to branch 'main'
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rank.py    | 2 ++
 rerank.py  | 2 ++
 serve.yaml | 1 +
 3 files changed, 5 insertions(+)
 create mode 100644 rerank.py
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
$ cat rank.py
from rerank import rerank

def score(q, d):
    return bm25(q, d)
```
<!-- /snippet -->

An ordinary merge now brings `rerank.py`, the import and the fix. The price is a rewritten feature branch, which is the subject of the rebase module that starts in three videos.

**Step 7: the squash contrast.** `labs/run ch11/revert-squash-remerge`. The branch went in as one ordinary commit, made with `git merge --squash`, and that commit was reverted.

<!-- snippet: ch11/revert-squash-remerge/01-squash-then-revert -->
```text
$ git merge --squash feature/reranker
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -m "Add cross-encoder reranker (squashed)"
[main e195948] Add cross-encoder reranker (squashed)
 2 files changed, 4 insertions(+)
 create mode 100644 rerank.py
$ git show -s --format="%h has parents: %p" HEAD
e195948 has parents: 31a221c
$ git revert --no-edit HEAD
[main f3affb6] Revert "Add cross-encoder reranker (squashed)"
 Date: Mon Sep 7 10:12:00 2026 +0530
 2 files changed, 4 deletions(-)
 delete mode 100644 rerank.py
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

No `-m` was needed: the squashed commit has one parent. Now merge the branch, with its fix. Predict the merge base first.

**[PAUSE]**

<!-- snippet: ch11/revert-squash-remerge/02-remerge-brings-everything -->
```text
$ git log --oneline -1 $(git merge-base main feature/reranker)
fbb8230 Add BM25 ranker and serving config
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rank.py    | 2 ++
 rerank.py  | 2 ++
 serve.yaml | 1 +
 3 files changed, 5 insertions(+)
 create mode 100644 rerank.py
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
$ git log --oneline --graph
*   18eb394 Merge branch 'feature/reranker'
|\  
| * 5eedafc Cap reranker candidates at 50
| * c3762df Call the reranker from the ranker
| * 719cc13 Add cross-encoder reranker
* | f3affb6 Revert "Add cross-encoder reranker (squashed)"
* | e195948 Add cross-encoder reranker (squashed)
* | 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
```
<!-- /snippet -->

The merge base is still `fbb8230`, where the branch started.

**[ANIMATION]** graph: fbb8230-31a221c-e195948-f3affb6 main; fbb8230-719cc13-c3762df-5eedafc feature/reranker; HEAD=main; note:fbb8230:merge_base; note:e195948:squash:_one_parent => + f3affb6-18eb394 main; 5eedafc-18eb394; say:No_ancestry_was_recorded:_the_merge_brings_the_whole_branch; name:brings id=squash title=After_a_squash_merge

**[ANIMATION]** step: squash.brings

There's no second parent, the branch commits never became ancestors of `main`, and so the merge brings the whole branch: three files. Recall the squash trap from video 36: content without ancestry. There it caused a conflict. Here the same property is why the re-merge works.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Merging the repaired branch again and trusting a clean result.** Root cause: the revert removed the content of the merge and left the merge in the graph, so the merge base is the old branch tip and only newer commits arrive.
2. **Running `git rebase main` on the branch to "refresh" it before re-merging.** Root cause: a plain rebase replays only commits that `main` does not have as ancestors, and the old branch commits are ancestors.
3. **Choosing the parent number by guessing.** Root cause: `-m` selects the parent that counts as the mainline; on a branch that receives merges that is parent 1, and the other number computes a different inverse.
4. **Reverting a whole merge because one commit in it was faulty.** Root cause: the revert, and later the revert of the revert, are large commits that hide the small ones from `git bisect`.
5. **Assuming the same problem after a squash merge.** Root cause: a squash commit has one parent, so no ancestry was recorded and the merge base never moved.

## PRODUCTION EXAMPLE

**[ANIMATION]** graph: *1-*2-?merge-?revert main; *1-*3-*4 feature; *4-?merge; HEAD=none; note:?merge:Tuesday; note:?revert:Wednesday => + *4-?one_more_commit feature; note:?one_more_commit:Monday; name:monday => + ?revert-?second_merge main; ?one_more_commit-?second_merge; say:The_diff_shows_one_line,_and_it_merges_cleanly; name:cleanly title=Every_step_looked_right id=prod

**[ANIMATION]** step: prod.state-1

Now, out of the lab. A search team merges a cross-encoder reranker on Tuesday. Latency doubles. On Wednesday the on-call engineer reverts the merge with `-m 1`, and production recovers. That part goes well.

**[ANIMATION]** step: prod.cleanly

The following Monday the branch has one more commit, a cap on reranker candidates. Someone opens a new pull request from the same branch. The diff shows one line. Reviewers approve a one-line change. It merges cleanly, and the release notes say "reranker re-enabled". It isn't. And nobody was careless: every step looked right.

**[ANIMATION]** say: Write_the_re-merge_procedure_into_the_message_of_the_revert_commit

The prevention from the root-cause box costs one paragraph: write the re-merge procedure into the message of the revert commit. "Before merging this branch again, revert this commit first." The person who needs that sentence will be reading that commit.

**[ON SCREEN]** Layer label: GitHub.

On GitHub, the Revert button on a merged pull request "creates a new pull request that reverts the original merge commit", and `gh pr revert <number>` does the same from the command line. This is described from the documentation, not run here. The page says nothing about a later re-merge. By the mechanics you have seen, a pull request that was merged with a merge commit and then reverted needs one of the two ways out before its branch is merged again.

## PRACTICE EXERCISE

Your turn. Do Lab 8.3, "Revert a merge, then re-merge", in [`lab-manual/m08-undo.md`](../../lab-manual/m08-undo.md).

Predict at three points, in writing:

- Before the revert: what are the two parents of the merge, and what will the tree look like after `-m 1`?
- Before the second merge: what does `git merge-base main <branch>` print, and therefore which commits will the merge bring?
- Before each repair: what will the graph look like afterwards, and which IDs, if any, will be new?

The challenge is Exercise 8.10, Level 5, "a feature that was merged twice and is half missing", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q182: "You reverted a merge with `-m 1` last week. Today the fixed branch was merged again and the feature is incomplete. Explain the mechanism with the merge base and give two correct procedures. What would `-m 2` have undone, and why does a squash merge not show the problem?"

**[PAUSE]**

Answer out loud first.

**[PAUSE]**

**[ANIMATION]** replay: rm

This is a four-part question. A strong answer takes the parts in order, and keeps one idea running through all of them: content against ancestry. It states where the merge base is and why, and derives the missing half from that. It gives both procedures, with the cost of each. For `-m 2` it reasons from what "relative to that parent" means and doesn't guess. And for the squash it says what is absent from the graph. Draw the graph while you speak.

## RECAP

**[ANIMATION]** step: rm.then-merge

Let's land this. You should now be able to say:

A merge commit has two parents, so `git revert` needs `-m` to know which one is the mainline, and `-m 1` takes out what the merge brought in. The revert changes content and leaves the merge in the graph, so the branch's old commits stay ancestors of `main`, and a later merge brings only newer commits.

**[ANIMATION]** step: rebuild.replayed

The two repairs are to revert the revert and then merge, or to recreate the branch as new commits with `git rebase --no-ff` from where it started.

**[ANIMATION]** step: squash.brings

After a squash merge no ancestry was recorded, so a later merge brings the whole branch. Where possible I revert the one faulty commit and keep the merge.

## HOMEWORK

Read section 11.9 of [Chapter 11](../../textbook/ch11-reset-revert-restore.md).

A clean merge that loses half a feature is no longer a mystery to you: you can point at the merge base and say why. Do the lab, and write your three predictions down first. Next time: `git clean`, and stash, uncommitted work parked as commits. Until then, look at the state first and type second. See you in the next one.

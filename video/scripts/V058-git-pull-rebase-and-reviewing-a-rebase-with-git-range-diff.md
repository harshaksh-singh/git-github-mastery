# V058: git pull --rebase, and reviewing a rebase with git range-diff

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 20
- **Prerequisites:** V040, V057
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), sections 9.13 and 9.14
- **Demo scripts:** `labs/ch09/pull-rebase.sh`, `labs/ch09/range-diff.sh`, `labs/ch09/range-diff-review.sh`, `labs/ch09/range-diff-context.sh`

## HOOK

**[ON SCREEN]** "Rebased onto main, no functional change."

That sentence is typed into pull requests every day. A pull request is a proposal on GitHub to merge one branch into another. A reviewer approved three commits on Tuesday. On Wednesday the author force-pushes, replacing those commits on the server, with that comment. There are still three commits, with the same three titles.

The CTO's question: "The reviewer approved the first version. What exactly is different in the second one?"

The reviewer has three options. Trust the sentence. Review everything again. Or run one command that compares the old series with the new one, commit by commit, and prints only what changed in the patches. In today's demo, that command finds a constant that was 20 when it was approved and is 12 now.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Two tools today, one small and one that deserves more use than it gets.

The small one is `git pull --rebase`. You have both halves already. Fetch, from the remotes module, downloads what the server has and moves no branch of yours. Rebase, from this module, copies your commits onto a new starting point, and every copy gets a new ID. You'll see them run together, and see why this particular rewriting of history is harmless.

The second is `git range-diff`. Every earlier video in this module ended with some version of "check what the rebase did". This is the tool for that check. It answers the question "how do these two versions of a series of commits differ", which no ordinary diff answers. You'll read its four markers, see why comparing the two tips directly is not the same thing, and see how a reviewer runs it without access to the author's clone. You'll also meet its one limit, so that it doesn't mislead you.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- Explain `git pull --rebase` as fetch followed by a rebase onto the upstream.
- Compare the old and the new version of a branch with `git range-diff`.
- Read the `=`, `!`, `<`, and `>` markers.
- Show a reviewer what changed in a force-pushed branch.

## CONCEPT

**Pull with rebase.** In one sentence: `git pull --rebase` 🟡 CAUTION is `git fetch` followed by a rebase of your unpushed commits onto the fetched upstream branch.

**[ANIMATION]** remotes: [your clone] 8afc6bd-139c7e6 main; 8afc6bd origin/main; HEAD=main || [origin] 8afc6bd-eb7188f main; HEAD=none => + 8afc6bd-eb7188f origin/main; name:fetch; say:First_half:_the_fetch_moves_only_origin/main || => [your clone] 8afc6bd-eb7188f-ad181ff main; eb7188f origin/main; 8afc6bd-139c7e6; reflog:139c7e6; HEAD=main; name:rebase; say:Second_half:_your_commit_is_copied_onto_origin/main || => + ad181ff origin/main; name:push; cmd:git_push; say:A_fast-forward_for_the_server:_no_force || [origin] 8afc6bd-eb7188f-ad181ff main; HEAD=none title=git_pull_--rebase id=pull at_state_1=12 at_fetch=40

**[ANIMATION]** step: fetch

On screen: your `main` has one commit of its own, and `origin/main`, your record of the upstream branch on the server, has one that you lack.

**[ANIMATION]** step: rebase

Your local commits end up on top of the upstream's, and no merge commit is written. `pull.rebase=true` makes it the default.

**[ON SCREEN]** The state table for `git pull --rebase`.

```text
Working tree           Index   HEAD                        Current branch ref           Other refs and files in .git          Remote      GitHub
---------------------  ------  --------------------------  ---------------------------  ------------------------------------  ----------  ---------
Upstream tip plus      Same    Detached during the         Upstream tip plus copies     Remote-tracking branches and          Read, not   unchanged
your replayed commits          rebase, then back on the    of your unpushed commits     FETCH_HEAD updated by the fetch;      changed
                               branch                                                   ORIG_HEAD; reflogs
```

The textbook is plain about what this is: history rewriting.

**[ANIMATION]** step: pull.rebase

**[ANIMATION]** say: The rewritten commit exists nowhere but in your clone

And it's harmless here for one reason: the only commits rewritten are ones that exist nowhere but in your clone. That's the private-or-shared question from the undo module, answered "private".

**[ANIMATION]** end

One more fact, which you met from the receiving end in the video on forced pushes. When the upstream branch itself was rewritten, `git pull --rebase` consults the reflog of the remote-tracking branch, the local list of its past positions, to avoid replaying commits that upstream discarded. The next two videos show that logic doing good and doing harm.

**Range-diff.** In one sentence: `git range-diff` 🟢 SAFE compares two versions of a series of commits: it pairs each old commit with its new counterpart and shows how the two patches differ. A patch is the change one commit makes, written as a diff.

**[ANIMATION]** graph: 8afc6bd-439e4c6 main; ^8afc6bd-5ee19f0-bad8965-1388956 ORIG_HEAD; 439e4c6-1c9f69a-54541c3-2468748 feat/rerank; HEAD=feat/rerank; title:Old_series_and_new_series => + same:5ee19f0; same:1c9f69a; mark:!:bad8965; mark:!:54541c3; same:1388956; same:2468748; name:marks; say:Old_patch:_TOP__K_5_to_20._New_patch:_TOP__K_8_to_12; title:Same_titles,_one_changed_patch id=series dx=240

**[ANIMATION]** step: state-1

On screen, today's example: three old commits, which `ORIG_HEAD` still names, and their three copies on `feat/rerank`.

Precisely. The most convenient spelling is `git range-diff <base> <old tip> <new tip>`. Commits are paired by similarity of their patches, not by position or ID. Between the two columns stands one of four markers.

**[ON SCREEN]** The four markers.

```text
=    same patch
!    patch changed
<    only in the old series
>    only in the new series
```

For a `!` pair Git prints a diff of the two diffs. Each line has two markers. The outer marker says whether a line belongs to the old patch, minus, or the new patch, plus. The inner marker is the patch's own.

When is range-diff not enough? Its pairing is a heuristic, so a small patch whose context changed may be reported as removed and added. And its output is for people: the manual warns that the format may change, so don't parse it.

## MENTAL MODEL

**[ON SCREEN]** "A diff compares two snapshots. A range-diff compares two sets of changes."

**[ANIMATION]** step: series.state-1

An ordinary `git diff` between the old tip and the new tip compares two trees, two full snapshots of the files. After a rebase onto a moved `main`, those two trees differ by everything that arrived from upstream, plus whatever the author changed. The author's part is buried.

A range-diff ignores the trees. It lays the old patches next to the new patches and asks, for each pair: is this the same change? Think of two editions of a contract's amendments. You don't compare the two final contracts, which differ because the base contract changed. You compare amendment 2 of the first edition with amendment 2 of the second.

Where does the picture break? Amendments are numbered, and commits are not paired by number. Git pairs by similarity. A reordered series is still paired correctly. A tiny patch with changed context may not be paired at all. That's the limit you'll see.

## DIAGRAM

**[DIAGRAM]** New diagram. Two columns: the old range on the left, the new range on the right. Draw a pairing line for each commit and put one marker on each line.

```text
   old series  (base..ORIG_HEAD)                    new series  (base..HEAD)

   1:  5ee19f0  Add reranker skeleton       ---- = ----   1:  1c9f69a  Add reranker skeleton
   2:  bad8965  Fetch 20 candidates ...     ---- ! ----   2:  54541c3  Fetch 20 candidates ...
                 patch:  5 -> 20                                        patch:  8 -> 12
   3:  1388956  Enable reranking in config  ---- = ----   3:  2468748  Enable reranking in config

   =  same patch, new ID          !  same title, different patch: read the diff of diffs
   <  no partner on the right: the commit is gone
   >  no partner on the left: the commit is new
```

All six IDs differ, as they must after a rebase. Only the middle line says that something changed.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/pull-rebase`. You committed on `main`; Asha pushed to `main` in the meantime.

**Part 1: pull with rebase.**

<!-- snippet: ch09/pull-rebase/01-diverged -->
```text
$ git fetch
From ../server
   8afc6bd..eb7188f  main       -> origin/main
$ git status --short --branch
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --decorate --all
* 139c7e6 (HEAD -> main) Raise max_tokens to 1024 for long answers
| * eb7188f (origin/main, origin/HEAD) Add README
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Ahead 1, behind 1. A plain `git pull` refuses here until you choose how to reconcile, as in the remotes module.

<!-- snippet: ch09/pull-rebase/02-pull-refuses -->
```text
$ git pull
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[exit status: 128]
```
<!-- /snippet -->

Choosing rebase. Predict the graph. Quick quiz, two options. Your commit is `139c7e6`. Option one: it keeps that ID. Option two: it gets a new one. Say it out loud.

**[PAUSE]**

<!-- snippet: ch09/pull-rebase/03-pull-rebase -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph --decorate --all
* ad181ff (HEAD -> main) Raise max_tokens to 1024 for long answers
* eb7188f (origin/main, origin/HEAD) Add README
* 8afc6bd Add retriever and model config
$ git reflog -4
ad181ff HEAD@{0}: pull --rebase (finish): returning to refs/heads/main
ad181ff HEAD@{1}: pull --rebase (pick): Raise max_tokens to 1024 for long answers
eb7188f HEAD@{2}: pull --rebase (start): checkout eb7188fc630b934cc36f4a355cc5e9c51f2540aa
139c7e6 HEAD@{3}: commit: Raise max_tokens to 1024 for long answers
```
<!-- /snippet -->

A straight line, and option two. Your commit `139c7e6` was replayed as `ad181ff` on top of Asha's. The reflog labels the steps `pull --rebase`: start, pick, finish, the same three verbs as any rebase.

<!-- snippet: ch09/pull-rebase/04-push -->
```text
$ git push
To ../server.git
   eb7188f..ad181ff  main -> main
```
<!-- /snippet -->

And the push is a fast-forward for the server: its branch only moves ahead.

**[ANIMATION]** step: pull.push

No force. The rewritten commit had never left your clone.

**Part 2: range-diff after a conflict.** `labs/run ch09/range-diff`. A rebase with one conflict: `main` says `TOP_K = 8`, your commit says 20. You settle on 12 in the editor, a value that neither side had.

<!-- snippet: ch09/range-diff/01-rebase -->
```text
$ git log --oneline --decorate main..feat/rerank
1388956 (HEAD -> feat/rerank) Enable reranking in config
bad8965 Fetch 20 candidates and filter weak matches
5ee19f0 Add reranker skeleton
# git rebase main stopped with a conflict in app/retriever.py: main says TOP_K = 8, your commit says 20.
# You settle on 12 in the editor, then:
$ git add app/retriever.py
$ git rebase --continue
[detached HEAD 54541c3] Fetch 20 candidates and filter weak matches
 2 files changed, 6 insertions(+), 3 deletions(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

The rebase finished. Three commits, same titles. Now:

```bash
git range-diff main ORIG_HEAD HEAD
```

Try it now, on paper. Thirty seconds: write one marker for each of the three commits. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/range-diff/02-range-diff -->
```text
$ git range-diff main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  1c9f69a Add reranker skeleton
2:  bad8965 ! 2:  54541c3 Fetch 20 candidates and filter weak matches
    @@ app/rerank.py
     
      ## app/retriever.py ##
     @@
    --TOP_K = 5
    -+TOP_K = 20
    +-TOP_K = 8
    ++TOP_K = 12
      
      def retrieve(query):
     -    return search(query, TOP_K)
3:  1388956 = 3:  2468748 Enable reranking in config
```
<!-- /snippet -->

Commits 1 and 3: equals sign, unchanged as patches. Commit 2: exclamation mark. Read the four marked lines in pairs. Lines whose outer marker is a minus belong to the old patch: it turned `TOP_K = 5` into `20`. Lines whose outer marker is a plus belong to the new patch: it turns `8` into `12`. Same title, different change. If the double markers look like noise, that's normal: read the outer one first.

**[ANIMATION]** step: series.marks

This is the answer to the CTO's question from the opening: 20 when approved, 12 now. And it's invisible in a list of commit titles.

<!-- snippet: ch09/range-diff/03-other-spellings -->
```text
$ git range-diff main feat/rerank@{1} feat/rerank | head -3
1:  5ee19f0 = 1:  1c9f69a Add reranker skeleton
2:  bad8965 ! 2:  54541c3 Fetch 20 candidates and filter weak matches
    @@ app/rerank.py
$ git range-diff ORIG_HEAD...HEAD | head -4
-:  ------- > 1:  439e4c6 Raise TOP_K to 8 after recall regression
1:  5ee19f0 = 2:  1c9f69a Add reranker skeleton
2:  bad8965 ! 3:  54541c3 Fetch 20 candidates and filter weak matches
    @@ app/rerank.py
```
<!-- /snippet -->

Two other spellings. The reflog form, `feat/rerank@{1}`, where the branch was one move ago, needs no `ORIG_HEAD`. The three-dot form has no base, so the commit that came from `main` is reported as new, with a greater-than sign.

Why not compare the two tips directly?

<!-- snippet: ch09/range-diff/04-tree-diff -->
```text
$ git diff ORIG_HEAD HEAD
diff --git a/app/retriever.py b/app/retriever.py
index e67ee8b..4321be2 100644
--- a/app/retriever.py
+++ b/app/retriever.py
@@ -1,4 +1,4 @@
-TOP_K = 20
+TOP_K = 12
 
 def retrieve(query):
     return rerank(search(query, TOP_K))
```
<!-- /snippet -->

That's a comparison of two snapshots. Here it happens to show the resolution, 20 against 12. On a real branch it also contains everything that arrived from upstream. Range-diff compares the commits themselves.

**Part 3: the reviewer's side.** `labs/run ch09/range-diff-review`. The reviewer doesn't need your `ORIG_HEAD`. After a fetch, the previous tip is in the reflog of the reviewer's own remote-tracking branch.

<!-- snippet: ch09/range-diff-review/01-fetch -->
```text
# In the reviewer clone. The author has rebased feat/ingest onto main and force-pushed it.
$ git fetch
From ../server
   8afc6bd..589d18b  main        -> origin/main
 + dc5df93...321b338 feat/ingest -> origin/feat/ingest  (forced update)
# The remote-tracking branch before and after that fetch:
$ git rev-parse "origin/feat/ingest@{1}" origin/feat/ingest
dc5df9356273e7c0c2807ce808c378782ea2525a
321b33811c66cc02a14c52dbe5b64ecdbd9c506d
```
<!-- /snippet -->

The fetch prints "(forced update)" for `feat/ingest`. `origin/feat/ingest@{1}` is the tip before that fetch, `dc5df93`, and `origin/feat/ingest` is the tip now.

<!-- snippet: ch09/range-diff-review/02-range-diff -->
```text
$ git range-diff origin/main "origin/feat/ingest@{1}" origin/feat/ingest
1:  1279adf = 1:  5859371 Add document loader
2:  dc5df93 = 2:  321b338 Add text cleaner
```
<!-- /snippet -->

Two equals lines: nothing changed except the base, and the earlier review still stands.

**[ANIMATION]** graph: 8afc6bd-589d18b origin/main; 589d18b-5859371-321b338 origin/feat/ingest; ^8afc6bd-1279adf-dc5df93 special:origin/feat/ingest@{1}; HEAD=none; reflog:1279adf,dc5df93; title:In_the_reviewer's_clone,_after_the_fetch => + same:1279adf; same:5859371; same:dc5df93; same:321b338; name:marks; say:Two_equals_lines:_only_the_base_changed id=review dx=240

In this case "rebased, no functional change" was true, and now it's evidence instead of a claim.

**Part 4: a limit to know.** `labs/run ch09/range-diff-context`. Run the tool on the clean rebase of video 52, in which nothing was edited. Would you predict three equals signs? Say it out loud.

**[PAUSE]**

<!-- snippet: ch09/range-diff-context/01-unpaired -->
```text
# The clean rebase of section 9.2. Nothing was edited, and yet:
$ git range-diff main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  742ab58 Add reranker skeleton
2:  af65a92 = 2:  ade2990 Call reranker from retriever
3:  bd62876 < -:  ------- Enable reranking in config
-:  ------- > 3:  976a161 Enable reranking in config
```
<!-- /snippet -->

Not quite. The third commit is reported as removed and added: a less-than line and a greater-than line under the same subject. Its patch is one added line with three lines of context, and one of those context lines changed underneath it: `main` had moved the model from `small-v1` to `small-v2`. For so small a patch that is too large a difference, and range-diff declines to pair the two. Raise the tolerance and the pair appears.

<!-- snippet: ch09/range-diff-context/02-paired -->
```text
$ git range-diff --creation-factor=90 main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  742ab58 Add reranker skeleton
2:  af65a92 = 2:  ade2990 Call reranker from retriever
3:  bd62876 ! 3:  976a161 Enable reranking in config
    @@ Commit message
     
      ## config/model.yaml ##
     @@
    - model: small-v1
    + model: small-v2
      temperature: 0.2
      max_tokens: 512
     +rerank: true
```
<!-- /snippet -->

With `--creation-factor=90` the pair is found, marked with an exclamation mark, and its only difference is the context line.

**[ANIMATION]** walk: columns=range-diff_prints,what_it_means rows=<_and_>_under_one_subject:look_closer:_the_pair_was_not_found|<_and_no_partner:the_commit_is_gone mono=off title=Two_readings_of_a_less-than_line id=limit

So a less-than and a greater-than under one subject are a prompt to look closer. A lost commit has a less-than and no partner. You saw that one in the last video, after the `--ours` trap.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Reviewing a force-pushed branch by its commit titles.** Root cause: a rebase keeps messages by default, so a patch that changed during conflict resolution carries the same title.
2. **Using `git diff <old tip> <new tip>` to see what a rebase changed.** Root cause: that compares two snapshots, which also differ by everything that arrived from the new base.
3. **Believing the reviewer needs the author's `ORIG_HEAD`.** Root cause: the reviewer's fetch recorded the previous tip in the reflog of their own remote-tracking branch, as `@{1}`.
4. **Reading `<`, then `>`, under one subject as a lost and a new commit.** Root cause: pairing is a similarity heuristic; a small patch with changed context may not be paired until the creation factor is raised.
5. **Treating `git pull --rebase` as free of risk on any branch.** Root cause: it rewrites your unpushed commits, which is harmless only because nobody else has them; on a branch whose upstream was rewritten, its fork-point logic can drop commits.

## PRODUCTION EXAMPLE

Now, out of the lab. Suppose a team that reviews prompt and evaluation changes adopts two rules from this section of the textbook.

**[ANIMATION]** step: series.marks

For authors: run range-diff after every rebase that stopped, before you push, and paste the output into the pull request when you force-push a branch under review. The comment is no longer "rebased, no functional change". It's three lines with equals signs, or it's an exclamation mark with an explanation next to it.

**[ANIMATION]** step: review.marks

For reviewers: after a fetch that prints "(forced update)" for a branch you had approved, run `git range-diff origin/main "origin/<branch>@{1}" origin/<branch>` in your own clone. It takes seconds, and it doesn't depend on trusting anyone.

**[ANIMATION]** end

One caution the textbook attaches: the format is for people. The manual warns that it may change, so don't parse it in a script.

## PRACTICE EXERCISE

Your turn. Do Exercise 9.4, Level 2, "the old commits and the new ones", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Predict before you run range-diff:

- The three arguments: which commit is the base, which is the old tip, which is the new tip, and where you get the old tip from.
- One marker per commit of the series.
- For any commit you expect to be marked with an exclamation mark: the lines of the old patch and of the new patch that differ.

The challenge is Exercise 9.10, Level 5, ""rebased onto main, no functional change"", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q149: "The reviewer approved three commits; after your rebase there are still three with the same titles. How do you show what changed, and how does the reviewer do it without access to your clone?"

**[PAUSE]**

Answer out loud first. A strong answer names the tool and, more importantly, says what it compares and why a comparison of the two tips would not do. It gives the author's command with the three arguments in their roles and says where the old tip comes from. Then it gives the reviewer's command and says where, in the reviewer's own repository, the old tip is recorded and what had to happen for it to be there. It ends with how to read the result, including the case that needs a second look.

## RECAP

**[ANIMATION]** replay: pull

Let's land this. You should now be able to say, in your own words:

`git pull --rebase` is a fetch followed by a rebase of my unpushed commits onto the fetched upstream. It rewrites only commits that exist nowhere else, so the following push is a fast-forward.

**[ANIMATION]** replay: series

`git range-diff <base> <old tip> <new tip>` pairs the commits of two versions of a series by similarity and shows a diff of their patches. An equals sign means the same patch, an exclamation mark a changed patch, and the angle brackets a commit present on one side only. A reviewer finds the old tip in the reflog of their own remote-tracking branch after fetching. Pairing is a heuristic, so a removed-and-added pair under one subject needs a closer look.

## HOMEWORK

Read sections 9.13 and 9.14 of [Chapter 9](../../textbook/ch09-rebase.md).

Today you turned "rebased, no functional change" from a claim into evidence. Run range-diff after your next rebase, before you push, even a clean one. Next time: rebasing a branch that other people use, and recovering from a bad rebase. Until then, look at the state first and type second. See you in the next one.

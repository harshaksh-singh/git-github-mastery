# V054: Choosing what moves and where it lands: upstream, --onto, --keep-base, --root

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 24
- **Prerequisites:** V053
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), section 9.5
- **Demo scripts:** `labs/ch09/rebase-forms.sh`, `labs/ch09/onto-cut.sh`, `labs/ch09/onto-sideways.sh`, `labs/ch09/onto-stacked.sh`, `labs/ch09/keep-base.sh`, `labs/ch09/rebase-root.sh`

## HOOK

**[ON SCREEN]** `CONFLICT (add/add): Merge conflict in ingest/loader.py`

Monday morning. You run `git rebase main` on your branch, the way you do every Monday. It stops on the first commit, with a conflict in `ingest/loader.py`.

Your branch never touched `ingest/loader.py`. You wrote a text cleaner. The loader is a colleague's work, and it was merged to `main` on Friday.

So why is Git asking you to resolve a conflict in somebody else's file, in a commit you didn't write? Because of one word in the definition of rebase, and one thing Git doesn't know about your branch. Hold on to those two. You'll have both by the end of the concept.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A rebase copies commits onto a new base, and then moves the branch. So far, `git rebase main` has been one command with one obvious meaning. This video takes it apart into its arguments, because the obvious meaning is an accident of the simplest case.

**[ANIMATION]** cards: question=Every_form_of_git_rebase_answers_three_questions cards=Which_branch_is_rewritten?|Which_commits_are_replayed?|On_which_commit_are_the_copies_built? numbered=on id=three at_1=22 at_2=30 at_3=38

**[ANIMATION]** step: three.3

Every form of the command answers three questions: which branch is rewritten, which commits are replayed, and on which commit the copies are built. In `git rebase main`, the second and third questions get the same answer, `main`, and so they look like one question. `--onto` separates them.

**[ANIMATION]** end

You'll see the forms of the command in one table. Then three worked cases of `--onto`: the stacked branch from the hook, which is a branch built on top of another branch, a fix moved sideways onto a release line, and commits cut out of the middle of a branch. Then the two special forms: `--root`, which rewrites from the first commit, and `--keep-base`, which rewrites a branch without moving it.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- State which commits `git rebase <upstream>` selects and where it puts them.
- Use `git rebase --onto` with three arguments to cut a range and to move a branch sideways.
- Explain why a plain rebase of a stacked branch replays commits that are not yours.
- Use `--keep-base` to rewrite a branch without moving it, and `--root` to rewrite from the first commit.

## CONCEPT

**[ON SCREEN]** The synopsis.

```bash
git rebase [--onto <newbase>] [<upstream> [<branch>]]
```

Three arguments, three roles.

`<branch>` is the branch that gets rewritten. Default: the current branch. If you name it, Git switches to it as part of the command.

`<upstream>` is only a boundary. The commits replayed are `<upstream>..<branch>`: reachable from the branch, not reachable from `<upstream>`. Reachable means you can get there by following parent links.

`<newbase>` is where the copies are built. Default: `<upstream>`.

Read the middle one again. The upstream argument is only a boundary. It says where your commits begin, by exclusion: everything it can reach isn't yours. It says nothing about where the copies go, unless you leave `--onto` out.

**[ON SCREEN]** The forms table of section 9.5.

```text
Form                            Commits replayed                               Built on
------------------------------  ---------------------------------------------  -----------------------------------------
git rebase main                 main..HEAD                                     main
git rebase main feat/x          main..feat/x, after switching to feat/x        main
git rebase                      from the configured upstream branch, using     that upstream
                                the fork point (section 9.15)
git rebase --onto N U           U..HEAD                                        N
git rebase --keep-base main     main..HEAD                                     the merge base of main and HEAD
git rebase --root               every commit reachable from HEAD               nothing: the root commit is recreated
git rebase -i HEAD~3            the last three commits                         HEAD~3, where they already are
```

Here are the forms in one table. Read each row as two answers: which commits are replayed, and what the copies are built on.

**[ANIMATION]** graph: 8afc6bd-9ba5170-2b2840e main; 8afc6bd-531d3da-7fea52c-3c47896-05dc4ce feat/ingest-cleaner; 7fea52c feat/ingest-loader; HEAD=feat/ingest-cleaner => 2b2840e-085d42e-f35e612 feat/ingest-cleaner; 2b2840e main; 7fea52c feat/ingest-loader; HEAD=feat/ingest-cleaner; reflog:3c47896,05dc4ce title=A_stacked_branch,_after_a_squash_merge id=stack

**[ANIMATION]** step: stack.state-1

Now the reason for the hook. Rebase replays everything not reachable from the upstream. "Reachable" is a statement about the graph. Git has no record that your branch "belongs on top of" another branch. A branch is a ref to a commit. "My commits" is something only you can define, by naming a boundary. That's the one word, reachable, and the one thing Git doesn't know.

Most days the default boundary is right. It goes wrong when the branch below yours lands on `main` in another form: squash-merged, which means packed into one new commit, or rebased. Then `main` has the content of those commits but not the commits. On screen that's `2b2840e`, the squash. The two loader commits below your two are still not reachable from `main`, so a plain rebase puts them on your list.

**[ANIMATION]** end

When not to use these forms? `--root` on a repository that others have cloned is a rewrite of the whole project: the new history and the old one have no commit in common.

## MENTAL MODEL

**[ON SCREEN]** `git rebase --onto <new base> <old base> <tip>`

Read `--onto` as a sentence with three nouns: "Take what lies after the old base, up to the tip, and rebuild it on the new base."

**[ANIMATION]** graph: *1-*2-N; *2-*3-U-x-y-z B; HEAD=none => + role:N:new_base; role:U:old_base; say:N:_the_new_base.__U:_the_old_base.__B:_the_tip.; name:nouns => + range:x,y,z:U..B; cmd:git_log_--oneline_U..B; say:The_range:_what_lies_after_the_old_base,_up_to_the_tip; name:lies => + N-x′-y′-z′ B; reflog:x,y,z; range:; cmd:git_rebase_--onto_N_U_B; say:replay_U..B_on_top_of_N; name:copies title=Three_nouns id=nub

**[ANIMATION]** step: nub.lies

The textbook's analogy from two videos ago still works: amendments redone against a new version of a contract. Extend it. A plain rebase says: "everything of mine that the other party's current version does not contain, redo it on their current version." `--onto` says: "my amendments are these ones, starting after page U; redo them on document N." You name the first page of your own work yourself.

**[ANIMATION]** say: Commits_are_selected_by_reachability,_not_by_author

Where it breaks: in a contract, your amendments are marked with your name. In Git the author field plays no part in the selection. Commits are selected by reachability, and commits written by a colleague will be replayed as readily as your own if they're inside the range.

**[ANIMATION]** say: Print_the_range_first:_git_log_--oneline_<upstream>..<branch>

So before any rebase with consequences, run the command that prints the range: `git log --oneline <upstream>..<branch>`. If a commit on that list isn't yours, your boundary is wrong.

## DIAGRAM

**[ANIMATION]** step: nub.copies

**[DIAGRAM]** Draw the "before" graph and label the three arguments on it: N, new base; U, old base; B, the tip. Then the "after" graph, with the copies marked by primes.

```text
git rebase --onto N U B          replay U..B on top of N

Before                                After
  o---o---N                             o---o---N---x'--y'--z'   B
       \                                     \
        o---U---x---y---z   B                 o---U

  N = new base (where the copies are built)
  U = old base (the boundary: everything it reaches is NOT replayed)
  B = tip      (the branch that is rewritten)
```

Before, on the left: `B` is the tip, and `x`, `y` and `z` come after the old base, `U`. `N` is the new base. After, on the right: three copies, marked with primes, on top of `N`.

`U` itself isn't copied. `x`, `y` and `z` are. And `U` stays where it was, with whatever else pointed at it.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/rebase-forms`. First the two-argument form, started from `main`. `git rebase` 🟡 CAUTION in every form today.

<!-- snippet: ch09/rebase-forms/01-two-arguments -->
```text
$ git status --short --branch
## main
$ git rebase main feat/rerank
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git status --short --branch
## feat/rerank
$ git reflog -5
4caa98e HEAD@{0}: rebase (finish): returning to refs/heads/feat/rerank
4caa98e HEAD@{1}: rebase (pick): Enable reranking in config
20d0897 HEAD@{2}: rebase (pick): Call reranker from retriever
0dea106 HEAD@{3}: rebase (pick): Add reranker skeleton
82f1fbb HEAD@{4}: rebase (start): checkout main
```
<!-- /snippet -->

You started on `main` and you end up on `feat/rerank`. Git doesn't check out the old tip of the branch on the way. It detaches at `main`, makes the copies, and attaches HEAD to the branch at the end, which is what the five reflog lines show.

Without any argument, the branch needs a configured upstream.

<!-- snippet: ch09/rebase-forms/02-no-upstream -->
```text
$ git rebase
There is no tracking information for the current branch.
Please specify which branch you want to rebase against.
See git-rebase(1) for details.

    git rebase '<branch>'

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=<remote>/<branch> feat/rerank

[exit status: 1]
```
<!-- /snippet -->

**Case 1: the stacked branch.** `labs/run ch09/onto-stacked`. `feat/ingest-cleaner` was built on `feat/ingest-loader`. The loader work has since landed on `main` as one squashed commit, with a small change made during review.

<!-- snippet: ch09/onto-stacked/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 2b2840e (main) Add document loader (#41)
* 9ba5170 Add README
| * 05dc4ce (HEAD -> feat/ingest-cleaner) Collapse repeated whitespace
| * 3c47896 Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Look at the graph. `main` has "Add document loader (#41)" as `2b2840e`. The branch below yours has the original loader commits, `531d3da` and `7fea52c`. Same work, different commits. Predict: how many commits will `git rebase main` try to replay? Say the number out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/onto-stacked/02-which-commits -->
```text
# What a plain "git rebase main" would replay:
$ git log --oneline main..feat/ingest-cleaner
05dc4ce Collapse repeated whitespace
3c47896 Add text cleaner
7fea52c Close files after loading
531d3da Add document loader
# What belongs to this branch alone:
$ git log --oneline feat/ingest-loader..feat/ingest-cleaner
05dc4ce Collapse repeated whitespace
3c47896 Add text cleaner
```
<!-- /snippet -->

Four. `main..feat/ingest-cleaner` lists your two commits and the two loader commits below them. The second command, with the loader branch as boundary, lists the two that belong to this branch alone.

<!-- snippet: ch09/onto-stacked/03-plain-rebase-conflicts -->
```text
$ git rebase main
Rebasing (1/4)
Auto-merging ingest/loader.py
CONFLICT (add/add): Merge conflict in ingest/loader.py
error: could not apply 531d3da... Add document loader
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 531d3da... # Add document loader
[exit status: 1]
$ git rebase --abort
```
<!-- /snippet -->

The plain rebase stops at once, at "1 of 4", with an `add/add` conflict in the loader file: it's trying to add a file that the squashed commit already added. That's the hook, reproduced. The demo aborts, and nothing had been resolved.

**[ON SCREEN]** The root-cause box of section 9.5.

```text
Observed behavior : "git rebase main" stops at once with a conflict in ingest/loader.py,
                    a file your branch never touched.
Git state         : main..feat/ingest-cleaner contains four commits: your two, and the two
                    loader commits below them.
Mechanism         : Rebase replays everything not reachable from main. The loader commits are
                    not reachable from main: main has their content in another commit (the
                    squash), not the commits themselves.
Root cause        : Git has no record that your branch "belongs on top of" another branch.
                    It knows reachability only.
Why Git does this : A branch is a ref to a commit. "My commits" is something only you can
                    define, by naming a boundary.
Correct fix       : git rebase --onto main feat/ingest-loader feat/ingest-cleaner
Prevention        : For a stacked branch, name the boundary whenever the branch below it
                    lands in another form.
```

Read the root-cause line: Git knows reachability only.

**[ANIMATION]** step: stack.state-1

Say the fix as the three-noun sentence: new base `main`, old base `feat/ingest-loader`, tip `feat/ingest-cleaner`.

<!-- snippet: ch09/onto-stacked/04-onto -->
```text
$ git rebase --onto main feat/ingest-loader feat/ingest-cleaner
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest-cleaner.
$ git log --oneline --graph --decorate --all
* f35e612 (HEAD -> feat/ingest-cleaner) Collapse repeated whitespace
* 085d42e Add text cleaner
* 2b2840e (main) Add document loader (#41)
* 9ba5170 Add README
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Two commits replayed, no conflict. Your two commits sit on `main`, and the old loader commits are left aside on their own branch.

**[ANIMATION]** step: stack.state-2

The same result as a graph: two copies on top of `main`, and the loader branch exactly where it was.

**[ON SCREEN]** Layer label: GitHub.

"Squash and merge" puts one new commit on the base branch. The commits of the head branch don't become ancestors of it. GitHub's documentation warns that continuing to work on a head branch after it was squash-merged makes later pull requests list the squashed commits again and repeat conflicts. Case 1 is the Git-side remedy.

**Case 2: sideways, onto an older line.** `labs/run ch09/onto-sideways`. `fix/timeout` was cut from `main`, which already carries work for 2.0. The fix has to ship from `release/1.4`.

<!-- snippet: ch09/onto-sideways/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 91476e2 (HEAD -> fix/timeout) Return no documents when search times out
* 1c42ebc Add a timeout to search calls
* c49bad6 (main) Switch default model to large-v3 for 2.0
* 16dfe8e Start 2.0: add async search client
* 8afc6bd (release/1.4) Add retriever and model config
```
<!-- /snippet -->

**[ANIMATION]** graph: 8afc6bd-16dfe8e-c49bad6-1c42ebc-91476e2 fix/timeout; 8afc6bd release/1.4; c49bad6 main; HEAD=fix/timeout => 8afc6bd-58c909f-594044f fix/timeout; 8afc6bd release/1.4; c49bad6 main; HEAD=fix/timeout; reflog:1c42ebc,91476e2 title=Sideways,_onto_release/1.4 id=side

**[ANIMATION]** step: side.state-1

Try it now, thirty seconds, on paper. Write the command before you see it. New base? Old base? Tip? Then say it out loud.

**[PAUSE]**

<!-- snippet: ch09/onto-sideways/02-onto -->
```text
$ git rebase --onto release/1.4 main fix/timeout
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/timeout.
$ git log --oneline --graph --decorate --all
* 594044f (HEAD -> fix/timeout) Return no documents when search times out
* 58c909f Add a timeout to search calls
| * c49bad6 (main) Switch default model to large-v3 for 2.0
| * 16dfe8e Start 2.0: add async search client
|/  
* 8afc6bd (release/1.4) Add retriever and model config
```
<!-- /snippet -->

`--onto release/1.4 main fix/timeout`. `main` served only as the boundary: "my commits are the ones after `main`".

**[ANIMATION]** step: side.state-2

The two fix commits now hang off the release, and the two 2.0 commits are on a separate line.

<!-- snippet: ch09/onto-sideways/03-check -->
```text
$ git diff --stat release/1.4 fix/timeout
 app/retriever.py | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)
$ ls app
retriever.py
```
<!-- /snippet -->

The check confirms that one file differs from the release and that the 2.0 client didn't come along: `app` contains only `retriever.py`.

**Case 3: cutting commits out of the middle.** `labs/run ch09/onto-cut`. Two experiment commits sit in the middle of `feat/rerank`.

<!-- snippet: ch09/onto-cut/01-before -->
```text
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

**[ANIMATION]** graph: 8afc6bd-5ee19f0-195f8d0-e30ba74-45f4f23-6ab8f55 feat/rerank; 8afc6bd main; HEAD=feat/rerank => 5ee19f0-a15178d-31e8a4d feat/rerank; 8afc6bd main; HEAD=feat/rerank; reflog:195f8d0,e30ba74,45f4f23,6ab8f55 title=Cutting_two_commits_out_of_the_middle id=cut

**[ANIMATION]** step: cut.state-1

You want to keep the skeleton, drop the two experiments, and keep the last two commits. Count from the tip: the tip is `~0`, the experiments are `~2` and `~3`, the skeleton is `~4`. New base? Old base? Predict the command.

**[PAUSE]**

<!-- snippet: ch09/onto-cut/02-onto -->
```text
# Keep everything up to feat/rerank~4, drop ~3 and ~2, replay ~1 and the tip.
$ git rebase --onto feat/rerank~4 feat/rerank~2 feat/rerank
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --decorate
31e8a4d (HEAD -> feat/rerank) Enable reranking in config
a15178d Call reranker from retriever
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

The copies are built on `feat/rerank~4`, and the boundary `feat/rerank~2` excludes everything up to and including the second experiment.

**[ANIMATION]** step: cut.state-2

And as a graph: two copies on the skeleton, and the two experiments left behind.

<!-- snippet: ch09/onto-cut/03-check -->
```text
$ git diff --stat ORIG_HEAD HEAD
 app/cross_encoder.py | 7 -------
 1 file changed, 7 deletions(-)
```
<!-- /snippet -->

The diff against `ORIG_HEAD` shows exactly one file gone, the cross-encoder experiment. The same result comes from `drop` in an interactive rebase, which is the next video. This form is the one you can script.

**`--root`.** `labs/run ch09/rebase-root`. Without a boundary, the root commit itself is in the range, so even the first commit can be reworded. This one is interactive. In the transcripts, a small script plays the person at the keyboard, and prints the list as Git opened it and as it was saved.

<!-- snippet: ch09/rebase-root/01-before -->
```text
$ git log --oneline --decorate
82f1fbb (HEAD -> main) Upgrade model to small-v2
589d18b Add README
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-root/02-root -->
```text
$ git rebase -i --root
--- todo list as Git opened it (comment lines removed) ---
pick 8afc6bd # Add retriever and model config
pick 589d18b # Add README
pick 82f1fbb # Upgrade model to small-v2
--- todo list as saved ---
reword 8afc6bd # Add retriever and model config
pick 589d18b # Add README
pick 82f1fbb # Upgrade model to small-v2
Rebasing (1/3)
[detached HEAD 580b0da] Add retriever and default model configuration
 Date: Mon Sep 7 10:02:00 2026 +0530
 2 files changed, 7 insertions(+)
 create mode 100644 app/retriever.py
 create mode 100644 config/model.yaml
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/main.
```
<!-- /snippet -->

`pick` became `reword` on the first line. Quick quiz: how many of the three commits keep their ID? A, two. B, one. C, none. Your answer?

**[PAUSE]**

<!-- snippet: ch09/rebase-root/03-after -->
```text
$ git log --oneline --decorate
6cdce43 (HEAD -> main) Upgrade model to small-v2
ffe456d Add README
580b0da Add retriever and default model configuration
$ git log --oneline ORIG_HEAD
82f1fbb Upgrade model to small-v2
589d18b Add README
8afc6bd Add retriever and model config
$ git merge-base HEAD ORIG_HEAD
[exit status: 1]
```
<!-- /snippet -->

C, none. Every commit has a new ID.

**[ANIMATION]** graph: 8afc6bd-589d18b-82f1fbb ORIG_HEAD; 580b0da-ffe456d-6cdce43 main; HEAD=main; reflog:8afc6bd,589d18b,82f1fbb; say:The_new_history_and_the_old_one_have_no_commit_in_common title=After_git_rebase_-i_--root id=root

And `git merge-base HEAD ORIG_HEAD` exits with status 1: the new history and the old one have no commit in common.

**`--keep-base`.** `labs/run ch09/keep-base`. Tidy a branch without catching up.

<!-- snippet: ch09/keep-base/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 9ba5170 (main) Add README
| * 028ba01 (HEAD -> feat/metrics) fixup! Add exact_match metric
| * a25e84c Add token-level F1 metric
| * 375df0b Test exact_match
| * 143e55a Add exact_match metric
|/  
* 8afc6bd Add retriever and model config
$ git merge-base main feat/metrics
8afc6bd28c2572af09f1b6c37d733535230e526f
```
<!-- /snippet -->

`main` has moved on by one commit. The branch has a `fixup!` commit to fold in, a correction that names the earlier commit it belongs to. The merge base is `8afc6bd`.

<!-- snippet: ch09/keep-base/02-keep-base -->
```text
$ git rebase --autosquash --keep-base main
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

The progress counter starts at 2. Instruction 1, a pick whose parent is already the base, needed no new commit: Git fast-forwards over instructions that would recreate what exists.

<!-- snippet: ch09/keep-base/03-after -->
```text
$ git log --oneline --graph --decorate --all
* e4d27a0 (HEAD -> feat/metrics) Add token-level F1 metric
* 2b30819 Test exact_match
* fa4c85b Add exact_match metric
| * 9ba5170 (main) Add README
|/  
* 8afc6bd Add retriever and model config
$ git merge-base main feat/metrics
8afc6bd28c2572af09f1b6c37d733535230e526f
```
<!-- /snippet -->

The `fixup!` commit was folded into its target, and three commits remain.

**[ANIMATION]** graph: 8afc6bd-9ba5170 main; 8afc6bd-143e55a-375df0b-a25e84c-028ba01 feat/metrics; HEAD=feat/metrics; note:8afc6bd:merge_base => + ^8afc6bd-fa4c85b-2b30819-e4d27a0 feat/metrics; reflog:143e55a,375df0b,a25e84c,028ba01; cmd:git_rebase_--autosquash_--keep-base_main; say:Tidied,_and_still_forking_from_8afc6bd; name:forks title=--keep-base:_rewrite_without_moving id=keep

**[ANIMATION]** step: keep.forks

The branch still forks from `8afc6bd` although `main` has moved on. Same merge base before and after.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Reading `<upstream>` as "the place my commits go".** Root cause: it is only a boundary; the destination is `<newbase>`, which merely defaults to the upstream.
2. **Running a plain `git rebase main` on a stacked branch after the branch below was squash-merged.** Root cause: the lower commits are not reachable from `main`, which holds their content in a different commit, so they are in the range.
3. **Getting the order of the `--onto` arguments wrong.** Root cause: the first argument is where copies are built, the second is the excluded boundary; swapping them replays the wrong range onto the wrong base.
4. **Tidying and catching up in one push.** Root cause: reviewers cannot separate what changed in your commits from a week of upstream changes; `--keep-base` keeps the two apart.
5. **Using `--root` on a shared repository to fix the first commit message.** Root cause: every commit gets a new ID, and the old and new histories share no commit.

## PRODUCTION EXAMPLE

**[ANIMATION]** graph: *0 main; *0-*1 loader; *1-*2 cleaner; *2-*3 chunker; HEAD=none => + *0-?squash main; say:The_bottom_lands_as_a_squash:_the_branch_above_is_in_the_state_of_Case_1; name:lands title=A_team_that_works_in_stacks id=stacks

**[ANIMATION]** step: stacks.lands

Now, out of the lab. A data-pipeline team works in stacks: a loader branch, a cleaner branch on top of it, a chunker on top of that. Their host squash-merges pull requests. Every time the bottom of a stack lands, the branch above it's in the state of Case 1.

**[ANIMATION]** say: The_rule:_rebase_with_--onto,_naming_the_old_base

Before the team understood this, the Monday rebase was a ritual of resolving conflicts in files nobody on the upper branch had touched, and occasionally resolving them wrongly. Now the rule is in the pull request template: when the branch below yours lands in another form, rebase with `--onto`, naming the old base.

**[ANIMATION]** gates: gates=--keep-base:done:-:to_tidy|push:done|plain_rebase:done:-:to_catch_up|push_again:done result=each_push_has_one_explanation title=Two_pushes,_two_explanations at_1=40 at_2=50 at_3=58 at_4=68 at_result=76 id=two

**[ANIMATION]** step: two.result

And for review, the textbook's advice: reviewers of a force-pushed branch want to know what changed in your commits. If one push both tidies and catches up, that answer is mixed with a week of upstream changes. Tidy with `--keep-base` and push. Catch up with a plain rebase and push again. Each push then has one explanation.

## PRACTICE EXERCISE

Your turn. Do Lab 9.2, "Transplant a branch with `--onto`", in [`lab-manual/m09-rebase.md`](../../lab-manual/m09-rebase.md).

Before you type the rebase:

- Draw the graph from `git log --oneline --graph --all`.
- Mark the new base, the old base and the tip on your drawing.
- Write the output you expect from `git log --oneline <old base>..<tip>`: this is the list of commits that will be copied. Run it and compare before you run the rebase.

The challenge is Exercise 9.9, Level 4, "the morning rebase that replays somebody else's commits", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q154: "`git rebase main` on a feature branch conflicts in a file the branch never touched. Give two different root causes and the command that fixes each."

**[PAUSE]**

Answer out loud first. A strong answer begins with the one command that turns the symptom into evidence: the list of commits the rebase is about to replay. From there it gives two causes that are different in mechanism, not two wordings of one, and for each names the fixing command with its arguments in the right roles. Today's video gave you one of the two in full. The other follows from the same definition of the range. Think about what else can put a commit you didn't write, or a change that's already upstream, into `main..HEAD`.

## RECAP

**[ANIMATION]** step: three.3

Let's land this. You should now be able to say:

Every rebase answers three questions: which branch is rewritten, which commits are replayed, and where the copies are built.

**[ANIMATION]** step: nub.copies

The upstream argument is only a boundary: the replayed commits are those reachable from the branch and not from it.

**[ANIMATION]** step: stack.state-2

`--onto <new base> <old base> <tip>` separates the boundary from the destination, which is what a stacked branch needs after the branch below it was squash-merged, and it also moves a branch sideways or cuts a range out.

**[ANIMATION]** step: keep.forks

`--keep-base` rebuilds on the existing merge base, so a branch can be tidied without catching up.

**[ANIMATION]** step: root.state-1

`--root` includes the first commit and leaves no commit in common with the old history.

## HOMEWORK

Read section 9.5 of [Chapter 9](../../textbook/ch09-rebase.md).

Do Exercise 9.5, Level 2, "a commit that `main` already has", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

That Monday conflict in somebody else's file is no longer a puzzle: you can print the range, see the wrong boundary, and name the right one. Do the lab, and draw the graph first. Next time: interactive rebase, where you edit the list of instructions yourself. Until then, look at the state first and type second. See you in the next one.

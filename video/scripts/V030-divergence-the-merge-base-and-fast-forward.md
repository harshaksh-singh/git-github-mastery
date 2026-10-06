# V030: Divergence, the merge base, and fast-forward

- **Part.** 2: Integration and collaboration mechanics
- **Module.** 6
- **Planned minutes.** 20
- **Prerequisites.** V025
- **Textbook sections.** [Chapter 8: Merge](../../textbook/ch08-merge.md), sections 8.1 to 8.3 (with the first transcripts of section 8.4 for the true merge)
- **Demo scripts.** `labs/ch08/merge-base.sh` (snippets `01-merge-base`, `02-three-dot-diff`), `labs/ch08/ff-or-true-merge.sh`

## HOOK

**[ON SCREEN]** "Both pull requests were green. `main` is red. The two branches did not touch a single file in common. How?"

It's the end of an ordinary release week, and your CTO asks: "Both pull requests were green. `main` is red. The two branches did not touch a single file in common. How?"

And a second one: "We reverted the bad merge on Friday. On Monday we merged the repaired branch, the merge was clean, and half of the feature is missing. Where did it go?"

**[PAUSE]**

Neither needs a bug in Git. Each follows from what a merge is. A merge is computed from exactly three snapshots: your commit, their commit, and one common ancestor, called the merge base. Git's own FAQ says it plainly: "Git does not consider the history or the individual commits that have happened on those branches at all". The textbook quotes a 2024 poll in which 61 percent of roughly 1,480 respondents had seen a production bug caused by a bad conflict resolution at least once. It's a self-selected sample, so read it as direction, not as a population estimate. Part 2 starts by getting the foundation right. Keep that Monday mystery in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair: this is Part 2, integration and collaboration mechanics. Everything in this part, merge, fetch, pull, push, rebase, cherry-pick, is explained from the commit graph you learned in Part 1. As in Part 1, the commit IDs on screen equal the IDs in the textbook, because the replays use the fixed clock.

The sample project for the merge videos is `evalkit`, a small evaluation harness for LLM outputs. Eval dot yaml, in the config directory, holds the run configuration. Judge dot txt, in prompts, holds the prompt for the judge model. And metrics dot py, in evalkit, holds the scoring functions. You work on `main`. Asha and Ravi work on branches.

Two things today: the merge base, as the third input of every merge, and the simplest merge there is, the fast-forward, which creates nothing. Before every `git merge` in this video I'll ask you the same question: fast-forward, true merge, or nothing? You answer from the graph.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Find the merge base of two commits, and explain why it is the third input of a merge.
2. Predict from the graph whether `git merge` will fast-forward.
3. List what a fast-forward changes in `.git`, and what it does not create.
4. Explain "Already up to date" from ancestry.

## CONCEPT

**[ANIMATION]** merge: three-way feature/rationale into main title=Two_branches,_one_merge_base

**[ANIMATION]** step: merge-base

**The merge base.** In one sentence: the merge base of two commits is their best common ancestor. That's the most recent commit that both histories contain, and the third input of every merge.

Precisely. A common ancestor of commits A and B is a commit reachable from both by following parents. The manual defines the rest: "One common ancestor is better than another common ancestor if the latter is an ancestor of the former. A common ancestor that does not have any better common ancestor is a best common ancestor, i.e. a merge base". Two branches have diverged when each contains commits that the other lacks.

**[ANIMATION]** step: merge

Why is it an input? Without it, you can't tell what each side did. If a line is present on one side and absent on the other, was it added by the first or deleted by the second? Only the common starting point decides.

**Four commands answer every question about divergence.** You met them in video 25.

**[ON SCREEN]** The table of section 8.2.

Which commit is the merge base? `git merge-base A B`. Is A an ancestor of B? Add `--is-ancestor`: exit status 0 means yes, 1 means no. How many commits does each side have that the other lacks? `git rev-list` with `--left-right`, `--count`, and A, three dots, B. Which commits are they? `git log` with `--oneline`, `--left-right`, and the same three dots.

**Inside `.git`.** Nothing is stored. The merge base is computed from the parent lines of commit objects, every time a command needs it. No file says where a branch "came from".

**[ANIMATION]** merge: fast-forward feature/batch-size into main

**[ANIMATION]** step: fast-forward

**Fast-forward.** In one sentence: when your current commit is an ancestor of the commit you merge, there's nothing to combine. So Git moves your branch ref to that commit, and creates no new object.

Precisely: the condition is `git merge-base --is-ancestor HEAD <other>`. Put differently, the merge base is your own tip. Fast-forwarding is the default.

**"Already up to date."** The opposite case has its own message. If the other commit is already an ancestor of HEAD, the merge prints "Already up to date." and moves nothing. Hold on to that message. It comes back at the end of the demo.

**[ANIMATION]** merge: fast-forward versus three-way

**[ANIMATION]** step: merge

So there are three cases, and ancestry decides between them. HEAD is an ancestor of the other: fast-forward. The other is an ancestor of HEAD: nothing to do. Neither: the branches have diverged, and you get a true merge, which the next video takes apart.

**What a fast-forward changes in `.git`.** The file `refs/heads/main` is rewritten with the new commit ID. `ORIG_HEAD` receives the old one. The reflogs of HEAD and of `main` each gain one line. The index and the working tree are updated as by a branch switch. The object database doesn't change.

One detail the textbook's authors found while testing: every `git merge` call rewrites `ORIG_HEAD` with the tip it started from, even a call that prints "Already up to date." or refuses. So as an undo pointer it's valid only until the next attempt. The reflog is the durable record.

**Risk labels.** `git merge` that fast-forwards or makes a true merge is 🟡 CAUTION: it moves the current branch and rewrites the index and the working tree. A `git merge` that answers "Already up to date." is 🟢 SAFE.

**[ON SCREEN]** The state table of section 8.3. Fast-forward: working-tree files updated to the tree of the other commit; index rewritten to match; HEAD still `ref: refs/heads/main`; current branch ref moves to the tip of the other; `ORIG_HEAD` set to the old tip, reflogs gain an entry, no new objects; remote and GitHub unchanged. "Already up to date.": everything unchanged, except that `ORIG_HEAD` is rewritten with the current tip.

**When a fast-forward is not what you want.** The risk is the missing trace. If somebody fast-forwards an unfinished branch into `main`, the history looks as if the work-in-progress commits had been made on `main` directly, and no merge commit exists to revert. Nobody wants to discover that on a Friday evening. A later video shows how to forbid it.

## MENTAL MODEL

**[ANIMATION]** merge: three-way main=editor_one feature=editor_two base=the_Monday_copy title=The_Monday_copy captions=off

**[ANIMATION]** step: merge-base

A picture helps. The textbook's analogy for the merge base: two editors photocopy a manuscript on Monday, and mark up their copies separately. On Friday you can combine their work only if you still have the Monday copy. Without it, you can't tell a sentence that one editor added from a sentence that the other deleted. The merge base is the Monday copy.

It breaks in two places. Git finds the Monday copy by walking parent links, not by date. And a tangled history can have two equally good Monday copies. That's the next video.

**[ANIMATION]** merge: fast-forward main=bookmark feature=last_page title=Moving_a_bookmark captions=off

**[ANIMATION]** step: fast-forward

And for the fast-forward: a bookmark in a manuscript that somebody else kept writing. You move the bookmark to the last page. It breaks on one point: nothing in the book records that the bookmark moved, or that the new pages were ever a separate branch. Only your local reflog knows.

## DIAGRAM

Now with real commits.

**[DIAGRAM]** The diagram of section 8.2.

```text
            5aec6e0---58a5e60   feature/rationale
           /
  6ae3c51---c089834             main   (HEAD -> main)
     ^
     merge base of main and feature/rationale
```

Two branches from one commit. `main` has one commit of its own, `c089834`. `feature/rationale` has two. The commit under the arrow, `6ae3c51`, is reachable from both tips and is the most recent such commit: the merge base. The Monday copy.

**[DIAGRAM]** The diagram of section 8.3.

```text
  Before                                     After git merge feature/batch-size

  6ae3c51---23db174   feature/batch-size     6ae3c51---23db174   feature/batch-size
     ^                                                    ^
     main  (HEAD -> main)                                 main  (HEAD -> main)
```

Before: `main` points at the older commit, and the feature branch is one commit further along the same line. After: the label `main` has moved one step to the right. Count the commits in both halves: two and two. Nothing was created. A ref moved.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch08/merge-base.sh`.

```bash
labs/run ch08/merge-base
```

`main` has one commit of its own, and `feature/rationale` has two. From the graph, name the merge base and the two counts before the commands print them.

**[PAUSE]**

<!-- snippet: ch08/merge-base/01-merge-base -->
```text
$ git log --oneline --graph --all
* c089834 Use temperature 0 for reproducible evals
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge-base main feature/rationale
6ae3c51e176b786603aea088486677fe30f409bd
$ git rev-list --left-right --count main...feature/rationale
1	2
$ git log --oneline --left-right main...feature/rationale
< c089834 Use temperature 0 for reproducible evals
> 58a5e60 Ask the judge to quote evidence
> 5aec6e0 Ask the judge for a rationale
```
<!-- /snippet -->

The two counts read "one commit only on the left side, two only on the right". In the `--left-right` log, the less-than sign marks commits reachable only from `main`, and the greater-than sign marks commits reachable only from the branch.

<!-- snippet: ch08/merge-base/02-three-dot-diff -->
```text
# Three dots in git diff: from the merge base to the right-hand side.
$ git diff --stat main...feature/rationale
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
# Two dots (or a space): the two tips compared directly.
$ git diff --stat main..feature/rationale
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

Three dots mean something different to `git diff`, and the difference matters for reviews. With three dots, `git diff` compares the merge base with the branch tip: what the branch did, and nothing that `main` did meanwhile. With two dots it compares the two tips, so the temperature change that `main` made appears as if the branch had undone it.

**[TERMINAL]** Caption bar: `labs/ch08/ff-or-true-merge.sh`. Split layout with the "before" half of the diagram.

```bash
labs/run ch08/ff-or-true-merge
```

<!-- snippet: ch08/ff-or-true-merge/01-before -->
```text
$ git log --oneline --graph --all
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge-base --is-ancestor main feature/batch-size
[exit status: 0]
$ git rev-list --count --all
2
```
<!-- /snippet -->

Two commits in a line. `main` is on the older one. `--is-ancestor main feature/batch-size` exits with 0. The repository has two commits.

Fast-forward, true merge, or nothing? Say it out loud. I'll wait.

**[PAUSE]**

`git merge` 🟡 CAUTION.

<!-- snippet: ch08/ff-or-true-merge/02-fast-forward -->
```text
$ git merge feature/batch-size
Updating 6ae3c51..23db174
Fast-forward
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --all
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git rev-list --count --all
2
$ git reflog -2
23db174 HEAD@{0}: merge feature/batch-size: Fast-forward
6ae3c51 HEAD@{1}: checkout: moving from feature/batch-size to main
$ cat .git/ORIG_HEAD
6ae3c51e176b786603aea088486677fe30f409bd
```
<!-- /snippet -->

Fast-forward. "Updating 6ae3c51..23db174" names the old and the new position of `main`. There are still two commits. The reflog entry says `merge feature/batch-size: Fast-forward`, and `ORIG_HEAD` holds `6ae3c51`, the commit to return to if this was a mistake.

Round two. Now `main` and a new branch each gain one commit.

<!-- snippet: ch08/ff-or-true-merge/03-diverged -->
```text
$ git log --oneline --graph --all
* 017bef5 Use temperature 0 for reproducible evals
| * 67feed7 Raise timeout to 60 seconds
|/  
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge-base --is-ancestor main feature/timeout
[exit status: 1]
$ git merge-base main feature/timeout
23db1749f261b3f9ca7627a25923389c32a4a64d
$ git rev-list --left-right --count main...feature/timeout
1	1
```
<!-- /snippet -->

Neither tip is an ancestor of the other. The merge base is `23db174`. Fast-forward, true merge, or nothing?

**[PAUSE]**

<!-- snippet: ch08/ff-or-true-merge/04-true-merge -->
```text
$ git merge feature/timeout
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --all
*   6b10077 Merge branch 'feature/timeout'
|\  
| * 67feed7 Raise timeout to 60 seconds
* | 017bef5 Use temperature 0 for reproducible evals
|/  
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git rev-list --count --all
5
```
<!-- /snippet -->

A true merge. "Auto-merging config/eval.yaml" reports a content merge: both sides changed that file, differently. "Merge made by the 'ort' strategy." names the algorithm. The repository went from four commits to five.

<!-- snippet: ch08/ff-or-true-merge/05-merge-commit -->
```text
$ git cat-file -p HEAD
tree 25ed240b50b6ea31af8a6023d66eac8ce10d5364
parent 017bef5a99c9b0472c2c1fd4181b9d01c243e76c
parent 67feed7ad67adc99e081b8c29515db39c4726dbb
author Lab User <you@example.com> 1788756960 +0530
committer Lab User <you@example.com> 1788756960 +0530

Merge branch 'feature/timeout'
$ git reflog -1
6b10077 HEAD@{0}: merge feature/timeout: Merge made by the 'ort' strategy.
$ cat config/eval.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 32
timeout_s: 60
retries: 2
seed: 7
```
<!-- /snippet -->

The new commit has two parents. The first `parent` is where you were, `017bef5`. The second is what you merged, `67feed7`. The merged file carries `temperature: 0.0` from your side and `timeout_s: 60` from theirs. How did Git arrive at that? That's the next video.

Last round. You merge `feature/timeout` again, and then `feature/batch-size`. Fast-forward, true merge, or nothing?

**[PAUSE]**

<!-- snippet: ch08/ff-or-true-merge/06-up-to-date -->
```text
$ git merge feature/timeout
Already up to date.
$ git merge feature/batch-size
Already up to date.
```
<!-- /snippet -->

Nothing, twice: "Already up to date." Both branch tips are ancestors of HEAD. That message is 🟢 SAFE: no ref moves. Now, the message you were holding on to. It says the other commit is reachable from yours. It does not say that the other branch's changes are present in your files. That difference is the thread back to the Monday mystery, and the challenge exercise is built on it.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Expecting a merge commit after "Fast-forward".** Root cause: the current tip was an ancestor of the other commit, so there was nothing to combine; one ref moved and no object was written.
2. **Reading "Already up to date." as "the change is in my files".** Root cause: the message is a statement about ancestry: the other commit is reachable from HEAD.
3. **Using two dots in `git diff` to review a branch.** Root cause: two dots compare the tips, so everything `main` did since the fork appears reversed; three dots compare from the merge base.
4. **Relying on `ORIG_HEAD` after a second merge attempt.** Root cause: every `git merge` call rewrites `ORIG_HEAD` with the tip it started from; the reflog is the durable record.
5. **Fast-forwarding an unfinished branch into `main`.** Root cause: the default allows it, and it leaves no merge commit to revert.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook draws two production consequences from the merge base.

First, the three-dot diff is what a pull request page shows. That's why a pull request doesn't list changes that landed on the base branch after you forked. It's GitHub's use of the same merge base.

Second, the age of the merge base predicts merge pain. A branch on an evaluation team that forked three weeks ago is combined against a three-week-old snapshot, and everything both sides did since then is in play. So for a branch that must live long, merging `main` into it at intervals moves the merge base forward and keeps each merge small.

And the fast-forward in daily life? It's what `git pull` does on a branch where you have no commits of your own.

## PRACTICE EXERCISE

Your turn. Do Lab 6.1, "Predict fast-forward or three-way", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md).

For each merge in the lab, write down before you run it: fast-forward, true merge, or nothing. The merge base. And how many commits the repository will have afterwards. Then check all three.

## INTERVIEW QUESTION

Q123: "`git merge feature` printed "Fast-forward". What changed in `.git`, and what did not?"

**[PAUSE]**

Answer out loud. A strong answer goes through the dot git folder systematically: refs, the special ref that records the old tip, reflogs, index, objects. It says what is absent from the list and why. And it says what that absence means for someone who later wants to undo the merge, or see in the history that it happened.

## RECAP

**[ANIMATION]** merge: fast-forward versus three-way

Let's land this. You should now be able to say: the merge base is the best common ancestor of two commits and the third input of every merge. It's computed from parent links, not stored. If my tip is an ancestor of the other commit, `git merge` fast-forwards: the branch ref moves, `ORIG_HEAD` and the reflogs record it, and no object is created. If the other commit is an ancestor of mine, Git says "Already up to date." and moves nothing. If neither is an ancestor of the other, the branches have diverged, and the merge creates a commit with two parents.

## HOMEWORK

- Read sections 8.1 to 8.3 of [Chapter 8](../../textbook/ch08-merge.md).
- Do Exercise 6.1, Level 1, "a fast-forward, then a merge commit", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).
- Challenge: Exercise 6.7, Level 3, "Already up to date, and the change is not there", in the same file.

Today you predicted every merge from the graph, before Git answered. If the merge base still feels slippery, that's normal. Next time we take the true merge apart: three inputs, one rule table, and criss-cross histories. Until then, look at the state first and type second. See you in the next one.

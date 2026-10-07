# V036: Controlling the result: --ff-only, --no-ff, --squash, the merge commit, first-parent history and octopus merges

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 6, Divergence and merge
- **Planned minutes:** 24
- **Prerequisites:** V034
- **Textbook sections:** [Chapter 8](../../textbook/ch08-merge.md), sections 8.12, 8.13 and 8.14
- **Demo scripts:** `labs/ch08/merge-flags.sh`, `labs/ch08/merge-commit-anatomy.sh`, `labs/ch08/octopus.sh`

## HOOK

**[ON SCREEN]** A conflict block on one line of `prompts/judge.txt`: "one sentence" against "two sentences".

Your team squash-merges every feature branch. Last week you squashed Asha's rationale branch into `main`. This week she added one more commit to the same branch, and you squash it again. Git stops with a conflict, on a line that last week's squash had already delivered to `main`.

Nobody edited that line on `main`. Git is in conflict with its own earlier merge. The cause is one missing parent link, and when you can see that link, you can also see what every merge option is really choosing. Hold on to that missing parent link.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A merge joins another branch's history into yours. In the last two videos the question was how to resolve one. Today the question is what kind of result you ask for. Four options decide whether a merge creates a commit, what kind, and when: `--ff-only`, `--no-ff`, `--no-commit` and `--squash`. They don't change the merged content. They change the history that records it.

Then you open a merge commit and read it as an object: one tree, more than one parent, and an order of parents that carries meaning. A parent is the commit that another commit was built on. That order is what `git log --first-parent` reads. And you close with the octopus merge, a commit with three or more parents.

All of this is Git. One callout near the end crosses to GitHub, and the label on screen will say so.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Choose between `--ff-only`, `--no-ff`, `--no-commit` and `--squash` for a stated goal.
- Explain what a squash merge leaves behind and why the branch cannot be reused safely.
- Read a merge commit: two parents, and a diff against each.
- Explain what `--first-parent` shows and why the order of parents matters.
- Say when an octopus merge is possible.

## CONCEPT

A merge produces two separate things: a tree, which is the merged content, and ancestry, which is the set of parent links on the commit that records it. The options of this video leave the tree alone and decide about the ancestry.

**[ON SCREEN]** The option table of section 8.12.

```text
Option        Fast-forward possible                  Branches have diverged
------------  -------------------------------------  ------------------------------------------
none (--ff)   fast-forward                           merge commit
--no-ff       merge commit                           merge commit
--ff-only     fast-forward                           refuses; nothing moves; exit status 128
--no-commit   fast-forward (option has no effect)    stops before committing
--squash      stages the result; no commit;          the same
              no MERGE_HEAD
```

Row by row. A fast-forward, remember, moves your branch name forward and creates nothing new. With no option, Git fast-forwards when it can and creates a merge commit when it can't. `--no-ff` forces a merge commit where a fast-forward would do. The branch stays visible in the graph and can be reverted as one unit. `--ff-only` either fast-forwards or moves nothing. `--no-commit` is meant to let you inspect a merge before it's recorded, and it has a gap you'll see in the demo. `--squash` computes the same result as a merge and then deliberately forgets that it was one.

`merge.ff` sets the default: `false` behaves like `--no-ff`, `only` like `--ff-only`.

**[ANIMATION]** graph: 6ae3c51-c089834-821b8ff-630eac8 main; 6ae3c51-5aec6e0-58a5e60 feature/rationale; 58a5e60-821b8ff; HEAD=main => + note:c089834:parent_1; note:58a5e60:parent_2 => + range:5aec6e0,58a5e60:821b8ff^1..821b8ff^2 => + range:; dim:5aec6e0,58a5e60; cmd:git_log_--first-parent title=A_merge_commit_and_its_two_parents id=mc

**[ANIMATION]** step: state-1

Now the merge commit itself. In one sentence: a merge commit is an ordinary commit object with more than one `parent` line, and the order of those lines records which branch received the merge.

**[ANIMATION]** step: state-2

Precisely: a merge commit stores a complete tree, like every commit. It stores no diff, no conflict record and no list of merged commits. Parent 1 is the commit HEAD pointed to when the merge was created. Parent 2 is the commit that was merged.

**[ANIMATION]** step: state-3

On screen, the merge is `821b8ff`, its parent 1 is `c089834` and its parent 2 is `58a5e60`. `M^1` and `M^2` name them. `M^1..M^2` is the set of commits that the merge brought in, and `M^-` is shorthand for the same range plus M itself.

Inside `.git` that is one commit object. No flag and no separate storage distinguishes a merge from any other commit.

**[ANIMATION]** step: state-4

`git log --first-parent` follows only parent 1 at every merge. On a main branch that receives work through merges, that is the list of integrations, one line each. Here it skips the two branch commits.

**[ANIMATION]** graph: 6ae3c51-adad948-5ab7b4d-6cd1b13 main; ^adad948-f18e761 topic/prompt; ^adad948-6e9e321 topic/deps; adad948-436e24c topic/docs; f18e761-6cd1b13; 6e9e321-6cd1b13; 436e24c-6cd1b13; HEAD=main id=octo title=An_octopus_merge dx=300

And the octopus: naming several branches in one `git merge` creates a single commit with three or more parents, made by a separate strategy that refuses any conflict.

**[ANIMATION]** cards: question=When_not_to_use_which? cards=--squash:on_a_branch_that_lives_on|--no-commit_alone:when_you_need_a_guaranteed_stop|an_octopus:when_any_of_the_branches_might_conflict at_1=18 at_2=40 at_3=62

When not to use which? `--squash` on a branch that lives on. `--no-commit` alone when you need a guaranteed stop. An octopus when any of the branches might conflict. The demo shows each failure.

## MENTAL MODEL

**[ON SCREEN]** "Content and ancestry are separate. A squash transfers content without ancestry."

First, one sentence to carry with you.

**[ANIMATION]** graph: A-M main; A-B-C feature; C-M; HEAD=main title=A_river_and_a_tributary

**[ANIMATION]** step: state-1

The textbook's analogy for a merge commit is a river and a tributary. Downstream of the confluence there is one river, and the map still shows which channel was the main stream. First-parent history is following the main stream upstream and ignoring every tributary. On screen, `M` is the confluence and `feature` is the tributary.

Quick quiz. Which commit becomes parent 1 of a merge? A, the tip of `main`. B, whatever was checked out when the merge was made. Your answer?

**[PAUSE]**

It's B, and that's where the river breaks. In Git the "main stream" is not a property of a branch name. It's whichever commit was checked out when the merge was made. Merge `main` into a feature branch and the feature branch is the main stream of that merge commit, whatever the branches are called. You will watch that go wrong.

Try it now. Thirty seconds, on paper. Draw `A`, a branch with `B` and `C`, and a squash commit `S` on `main`. How many lines go into `S`? Say it out loud.

**[PAUSE]**

**[ANIMATION]** graph: A-S main; A-B-C feature; HEAD=main title=A_squash:_content_without_ancestry

One line, from `A`. For the squash, extend the map. A squash merge is water arriving in the river with no channel drawn on the map. The river is fuller, and the map doesn't say from where. The merge base, the best common ancestor, is computed from the map, not from the water.

## DIAGRAM

**[ANIMATION]** graph: [a merge commit] A-M main; A-B-C feature; C-M; HEAD=main || [a squash] A-S main; A-B-C feature; HEAD=main title=The_same_tree,_two_histories

**[DIAGRAM]** First diagram, section 8.12. Draw `A`, then the feature branch `B---C`. On the left close the diamond with `M`. On the right add `S` on `main` with no line to `C`.

```text
  git merge --no-ff feature           git merge --squash feature, then git commit

  A-----------M   main                A---S       main      S has one parent
   \         /                         \
    B-------C     feature               B---C     feature   still listed as not merged

  M and S record the same tree. Only M records where it came from.
```

`M` and `S` record the same tree. Only `M` records where it came from.

**[ANIMATION]** step: mc.state-4

**[DIAGRAM]** Second diagram, section 8.13, with the IDs of the transcript. Draw the mainline first, then the branch, then the two labels.

```text
            5aec6e0---58a5e60             feature/rationale
           /                 \
  6ae3c51---c089834-----------821b8ff---630eac8   main   (HEAD -> main)

  821b8ff^1 = c089834   where main was when the merge was made
  821b8ff^2 = 58a5e60   what was merged

  git log --first-parent main:   630eac8, 821b8ff, c089834, 6ae3c51
```

And the merge commit from a moment ago, with both parents spelled out.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch08/merge-flags`. The repository is `evalkit`; `feature/rationale` has two commits on top of `main`.

**`--no-ff`.** `main` is an ancestor of the branch, so a plain merge would fast-forward. `git merge` 🟡 CAUTION: it moves the current branch and rewrites the index and the working tree.

```bash
git merge --no-ff feature/rationale
git log --oneline --graph
```

<!-- snippet: ch08/merge-flags/01-no-ff -->
```text
# main is an ancestor of feature/rationale, so a plain merge would fast-forward.
$ git merge --no-ff feature/rationale
Merge made by the 'ort' strategy.
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
$ git log --oneline --graph
*   ec7d2b5 Merge branch 'feature/rationale'
|\  
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

A merge commit, `ec7d2b5`, although none was needed.

**[ANIMATION]** graph: 6ae3c51 main; 6ae3c51-5aec6e0-58a5e60 feature/rationale; HEAD=main => 6ae3c51-ec7d2b5 main; 6ae3c51-5aec6e0-58a5e60 feature/rationale; 58a5e60-ec7d2b5; HEAD=main title=git_merge_--no-ff

**[ANIMATION]** step: state-2

The two branch commits form a visible bubble. As a picture: `main` was on `6ae3c51`, and the merge commit `ec7d2b5` closes the loop.

**`--no-commit`.** Same starting state, a fast-forward is possible. You want to look at the result before it is recorded. Predict what `git merge --no-commit` does. Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/merge-flags/02-no-commit-fast-forwards -->
```text
$ git merge --no-commit feature/rationale
Updating 6ae3c51..58a5e60
Fast-forward
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
$ git log --oneline --graph
* 58a5e60 Ask the judge to quote evidence
* 5aec6e0 Ask the judge for a rationale
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

It fast-forwarded. If that surprised you, you're in good company. The branch moved, and there was nothing to inspect first. The manual says so directly: there is no way to stop those merges with `--no-commit`. Combined with `--no-ff` it stops reliably.

<!-- snippet: ch08/merge-flags/03-no-commit -->
```text
$ git merge --no-ff --no-commit feature/rationale
Automatic merge went well; stopped before committing as requested
$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	modified:   prompts/judge.txt

$ ls .git | grep -E 'MERGE|ORIG_HEAD'
AUTO_MERGE
MERGE_HEAD
MERGE_MODE
MERGE_MSG
ORIG_HEAD
$ cat .git/MERGE_MODE; echo
no-ff
$ git log --oneline -1
6ae3c51 Add eval config, judge prompt and metrics
$ git merge --abort
```
<!-- /snippet -->

"Stopped before committing as requested." The state is that of a merge whose conflicts are all resolved: `MERGE_HEAD` exists, HEAD has not moved, and `MERGE_MODE` remembers `no-ff`. This is where you run the tests on the merged tree.

**`--ff-only`.** Now `main` has a commit of its own, so the branches have diverged.

<!-- snippet: ch08/merge-flags/04-ff-only -->
```text
$ git log --oneline --graph --all
* d80b525 Use temperature 0 for reproducible evals
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge --ff-only feature/rationale
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
$ git status --short --branch
## main
```
<!-- /snippet -->

"Not possible to fast-forward, aborting", exit status 128, and the status is clean. Nothing moved. That's why `--ff-only` is the safe way to bring a branch up to date.

**`--squash`.** `git merge --squash` 🟡 CAUTION: it changes the index and the working tree and makes no commit. Predict which files appear in `.git`.

**[PAUSE]**

<!-- snippet: ch08/merge-flags/05-squash -->
```text
$ git merge --squash feature/rationale
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   prompts/judge.txt

$ ls .git | grep -E 'MERGE|ORIG_HEAD|SQUASH'
AUTO_MERGE
ORIG_HEAD
SQUASH_MSG
$ head -3 .git/SQUASH_MSG
Squashed commit of the following:

commit 58a5e6004856ba05b88a2920c3684d15859a867b
```
<!-- /snippet -->

`AUTO_MERGE`, `ORIG_HEAD` and `SQUASH_MSG`. No `MERGE_HEAD`. So `git merge --abort` has nothing to abort, and the way back is `git reset --merge`. `SQUASH_MSG` is a draft message. The commit you make next is an ordinary one.

<!-- snippet: ch08/merge-flags/06-squash-commit -->
```text
$ git commit -q -m "Ask the judge for a rationale and for evidence"
$ git log --oneline --graph --all
* 4b0b1d4 Ask the judge for a rationale and for evidence
* d80b525 Use temperature 0 for reproducible evals
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git show -s --format="%h parents: %p" HEAD
4b0b1d4 parents: d80b525
$ git branch --no-merged
  feature/rationale
$ git branch -d feature/rationale
error: the branch 'feature/rationale' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/rationale'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

`4b0b1d4` has one parent, `d80b525`. The graph shows the branch still hanging off the old fork.

**[ANIMATION]** graph: 6ae3c51-d80b525 main; 6ae3c51-5aec6e0-58a5e60 feature/rationale; HEAD=main => 6ae3c51-d80b525-4b0b1d4 main; 6ae3c51-5aec6e0-58a5e60 feature/rationale; HEAD=main => + 6ae3c51-5aec6e0-58a5e60-?new_commit feature/rationale; name:again => + note:6ae3c51:still_the_merge_base; name:base title=git_merge_--squash,_then_git_commit id=squash

**[ANIMATION]** step: state-2

`git branch --no-merged` lists the branch, and `git branch -d` refuses to delete it here, where the branch has no upstream. The content of the branch is in `main`. Its commits are not.

**[ANIMATION]** step: squash.again

**The trap.** Asha adds a commit to the same branch and you squash again. Before the command, predict the merge base.

**[PAUSE]**

<!-- snippet: ch08/merge-flags/07-squash-then-reuse -->
```text
# The squash commit recorded no second parent, so the merge base has not moved:
$ git log --oneline -1 $(git merge-base main feature/rationale)
6ae3c51 Add eval config, judge prompt and metrics
$ git merge --squash feature/rationale
Auto-merging prompts/judge.txt
CONFLICT (content): Merge conflict in prompts/judge.txt
Squash commit -- not updating HEAD
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat prompts/judge.txt
You are a strict grader.
Answer with PASS or FAIL.
<<<<<<< HEAD
Explain your verdict in one sentence.
=======
Explain your verdict in two sentences.
>>>>>>> feature/rationale
Quote the evidence you used.
```
<!-- /snippet -->

The merge base is still `6ae3c51`, the original fork. That's the missing parent link. So the second merge compares both tips with the old base again. `main` "changed" the line, through the squash, and so did the branch. That's a conflict.

**[ON SCREEN]** The root-cause box of section 8.12, one line at a time.

```text
Observed behavior : Squashing the same branch into main a second time conflicts on a line that
                    the first squash had already delivered.
Git state         : git merge-base main feature/rationale is still 6ae3c51, the original fork.
Mechanism         : The first squash commit has one parent, so no commit of the branch became an
                    ancestor of main. The second merge compares both tips with the old base
                    again: main "changed" the line (through the squash) and so did the branch.
Root cause        : Content was merged without ancestry, so the merge base never moved.
Why Git does this : The merge base is computed from parent links, and a squash writes none.
Correct fix       : Resolve the conflict in favour of the newer text. Then stop reusing the
                    branch.
Prevention        : One squash per branch: delete the branch afterwards and start the next one
                    from main. For branches that must live on, use real merge commits.
```

The replay stops here. What happens after this point is your exercise.

The configuration form, for completeness:

<!-- snippet: ch08/merge-flags/08-merge-ff-config -->
```text
# docs/readme is one commit ahead of main. merge.ff=false behaves like --no-ff:
$ git -c merge.ff=false merge docs/readme
Merge made by the 'ort' strategy.
 README.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
# merge.ff=only behaves like --ff-only:
$ git -c merge.ff=only -c advice.diverging=false merge feature/rationale
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
```
<!-- /snippet -->

**The merge commit as an object.** `labs/run ch08/merge-commit-anatomy`.

```bash
git cat-file -p 821b8ff
```

<!-- snippet: ch08/merge-commit-anatomy/01-object -->
```text
$ git log --oneline --graph
* 630eac8 Raise batch size to 32
*   821b8ff Merge branch 'feature/rationale'
|\  
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
* | c089834 Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git cat-file -p 821b8ff
tree 3e976d90175716430f0495d15e71b1a0069e93e1
parent c089834537b955876054c69c0f4bfbe6230b0cb2
parent 58a5e6004856ba05b88a2920c3684d15859a867b
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

Merge branch 'feature/rationale'
```
<!-- /snippet -->

One tree, two `parent` lines, author, committer, message. Nothing else. Read the two parents. The first begins `c089834`, the commit on `main`. The second begins `58a5e60`, the tip of the branch.

<!-- snippet: ch08/merge-commit-anatomy/02-parents -->
```text
$ git rev-parse --short 821b8ff^1
c089834
$ git rev-parse --short 821b8ff^2
58a5e60
# The commits that came in through the merge: reachable from parent 2, not from parent 1.
$ git log --oneline 821b8ff^1..821b8ff^2
58a5e60 Ask the judge to quote evidence
5aec6e0 Ask the judge for a rationale
# The same range plus the merge itself, with the ^- shorthand:
$ git log --oneline 821b8ff^-
821b8ff Merge branch 'feature/rationale'
58a5e60 Ask the judge to quote evidence
5aec6e0 Ask the judge for a rationale
```
<!-- /snippet -->

`^1` and `^2` name them, the range `^1..^2` lists the commits that came in, and `^-` adds the merge itself.

<!-- snippet: ch08/merge-commit-anatomy/03-first-parent -->
```text
$ git log --oneline --first-parent
630eac8 Raise batch size to 32
821b8ff Merge branch 'feature/rationale'
c089834 Use temperature 0 for reproducible evals
6ae3c51 Add eval config, judge prompt and metrics
$ git log --oneline --merges
821b8ff Merge branch 'feature/rationale'
$ git log --oneline --no-merges
630eac8 Raise batch size to 32
c089834 Use temperature 0 for reproducible evals
58a5e60 Ask the judge to quote evidence
5aec6e0 Ask the judge for a rationale
6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

`--first-parent` gives four lines, and the two branch commits are not among them. `--merges` and `--no-merges` split the history the other way.

A merge commit has one diff per parent, and they answer different questions.

<!-- snippet: ch08/merge-commit-anatomy/04-diff-per-parent -->
```text
# What main gained from the merge:
$ git diff --stat 821b8ff^1 821b8ff
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
# What the feature branch would have gained from it:
$ git diff --stat 821b8ff^2 821b8ff
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Against parent 1: what `main` gained, the prompt lines. Against parent 2: what the feature branch would have gained, the temperature change.

**[ANIMATION]** graph: 630eac8-cfc99c8 main; 630eac8-042925e feature/httpx; HEAD=main => 630eac8-042925e-3f3fd07 feature/httpx main; 630eac8-cfc99c8; cfc99c8-3f3fd07; HEAD=main title=The_first-parent_flip id=flip

**[ANIMATION]** step: state-1

**The first-parent flip.** Someone merges `main` into `feature/httpx` and then fast-forwards `main` to it. Predict the first-parent history of `main` afterwards.

**[PAUSE]**

<!-- snippet: ch08/merge-commit-anatomy/05-flip -->
```text
$ git log --oneline --first-parent -3 main
cfc99c8 Retry the judge three times
630eac8 Raise batch size to 32
821b8ff Merge branch 'feature/rationale'
$ git switch -q feature/httpx
$ git merge main
Merge made by the 'ort' strategy.
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git switch -q main
$ git merge feature/httpx
Updating cfc99c8..3f3fd07
Fast-forward
 requirements.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 requirements.txt
$ git log --oneline --graph -4
*   3f3fd07 Merge branch 'main' into feature/httpx
|\  
| * cfc99c8 Retry the judge three times
* | 042925e Add httpx for the judge client
|/  
* 630eac8 Raise batch size to 32
$ git log --oneline --first-parent -3 main
3f3fd07 Merge branch 'main' into feature/httpx
042925e Add httpx for the judge client
630eac8 Raise batch size to 32
```
<!-- /snippet -->

Before, the first-parent history of `main` contained "Retry the judge three times".

**[ANIMATION]** step: state-2

Afterwards that commit, `cfc99c8`, is on the second-parent side, and the branch commit `042925e`, "Add httpx for the judge client", sits on the mainline. Nothing is lost. But every tool that reads the mainline now walks through the feature branch.

**Octopus.** `labs/run ch08/octopus`.

<!-- snippet: ch08/octopus/01-merge -->
```text
$ git merge topic/prompt topic/deps topic/docs
Trying simple merge with topic/prompt
Trying simple merge with topic/deps
Trying simple merge with topic/docs
Merge made by the 'octopus' strategy.
 README.md         | 2 ++
 prompts/judge.txt | 1 +
 requirements.txt  | 1 +
 3 files changed, 4 insertions(+)
```
<!-- /snippet -->

"Merge made by the 'octopus' strategy."

<!-- snippet: ch08/octopus/02-commit -->
```text
$ git log --oneline --graph
*---.   6cd1b13 Merge branches 'topic/prompt', 'topic/deps' and 'topic/docs'
|\ \ \  
| | | * 436e24c Document how to run
| | * | 6e9e321 Add httpx for the judge client
| | |/  
| * / f18e761 Ask the judge for a rationale
| |/  
* / 5ab7b4d Use temperature 0 for reproducible evals
|/  
* adad948 Add README and requirements
* 6ae3c51 Add eval config, judge prompt and metrics
$ git cat-file -p HEAD
tree 25553fcdd3840e13707bf49acc52fbfc81ef0fba
parent 5ab7b4d031080365343d89dcd529d514e9f9b01c
parent f18e7614e71850ee7b09c35e79b2e1a668d5f925
parent 6e9e3211e05899f0aa9598b4d578584f9189d724
parent 436e24c23d49f55d3231c8e61c555e6945411e92
author Lab User <you@example.com> 1788756420 +0530
committer Lab User <you@example.com> 1788756420 +0530

Merge branches 'topic/prompt', 'topic/deps' and 'topic/docs'
$ git reflog -1
6cd1b13 HEAD@{0}: merge topic/prompt topic/deps topic/docs: Merge made by the 'octopus' strategy.
```
<!-- /snippet -->

Four parents: your tip first, then the three branches in the order you named them.

**[ANIMATION]** step: octo.state-1

Now with a branch that touches the same line as `main`. Predict the state after the failure.

**[PAUSE]**

<!-- snippet: ch08/octopus/03-conflict -->
```text
# topic/temperature changes the same line as main.
$ git merge topic/prompt topic/temperature topic/docs
Trying simple merge with topic/prompt
Trying simple merge with topic/temperature
Simple merge did not work, trying automatic merge.
Auto-merging config/eval.yaml
ERROR: content conflict in config/eval.yaml
fatal: merge program failed
Automated merge did not work.
Should not be doing an octopus.
Merge with strategy octopus failed.
[exit status: 2]
$ git status --short --branch
## main
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
```
<!-- /snippet -->

Exit status 2, no `MERGE_HEAD`, a clean status. An octopus merge that hits a conflict is rolled back, not paused. Merge the conflicting branch separately, resolve it, and bundle the rest.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Squashing a branch, then continuing to work on it and squashing again.** Root cause: content was merged without ancestry, so the merge base never moved and the second merge sees the delivered lines as changed on both sides.
2. **Relying on `--no-commit` alone to inspect a merge.** Root cause: the option has no effect on a fast-forward, which needs no commit; only `--no-ff --no-commit` stops reliably.
3. **Running `git merge --abort` after a `--squash` that you do not want.** Root cause: a squash writes no `MERGE_HEAD`, so there is no merge to abort; `git reset --merge` is the way back.
4. **Merging `main` into a feature branch and fast-forwarding `main` to it.** Root cause: first parent means "what was checked out", not "main", so the mainline now runs through the feature branch.
5. **Starting an octopus merge with a branch that conflicts.** Root cause: the octopus strategy refuses any conflict and rolls the whole merge back.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: mc.state-4

Now, out of the lab. A backend team that serves model inference merges every pull request into `main`. A pull request is GitHub's proposal to merge one branch into another. When a deployment breaks at three in the afternoon, the on-call engineer runs `git log --first-parent --oneline main`. On this team that is the release history: one line per integrated unit, in the order it landed. Each line is a candidate for `git revert -m 1`, which a later video covers.

**[ANIMATION]** step: flip.state-2

That only works because of two rules the team enforces. Integrate into `main` with `--no-ff` merges, and never fast-forward `main` to a branch that has merged `main`.

**[ON SCREEN]** Layer label: GitHub.

One step across the layer boundary. The merge methods of a pull request map onto these options, but they run on GitHub's servers and are not identical to the local commands. GitHub's documentation describes the default method as a merge using the `--no-ff` option. For the squash method the documentation carries the same warning as today's root-cause box: if you keep working on the head branch, later pull requests can include commits that were already squashed into the base branch. Chapter 17 covers the merge methods.

**[ANIMATION]** cards: cards=--ff-only:to_update_your_local_main|--no-ff:to_integrate_a_feature_branch_as_one_revertable_unit|--squash:when_the_branch_history_is_noise,_then_delete_the_branch|--no-ff_--no-commit:to_test_the_merged_tree_before_it_becomes_a_commit title=Four_habits at_1=12 at_2=35 at_3=58 at_4=78

The habits the textbook recommends. `--ff-only` to update your local `main`, so that a surprise divergence stops you. `--no-ff` to integrate a feature branch as one revertable unit. `--squash` when the branch history is noise, then delete the branch. And `--no-ff --no-commit` to test the merged tree before it becomes a commit.

## PRACTICE EXERCISE

Your turn. Do Exercise 6.5, Level 2, "what a squash leaves behind", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Predict before you type:

- After a squash and a commit, how many parents does the new commit have, and what does `git merge-base` between `main` and the branch print?
- Which files in `.git` exist between the squash and the commit?
- What will `git branch --merged` and `git branch --no-merged` say?

The challenge is Exercise 6.4, Level 2, "two merges", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q131: "Compare `git merge -X ours`, `git merge -s ours` and `git merge --squash` in terms of content and ancestry."

**[PAUSE]**

Answer out loud before you open the answers file. A strong answer uses exactly the two axes the question names and fills a small grid: for each of the three, what ends up in the tree, and what parent links the resulting commit has. It separates a strategy option from a strategy. It names the pair that are opposites of each other and says why. And it finishes with one practical consequence of each for a later merge of the same branch.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: squash.base

The merge options choose history, not content: `--ff-only` moves nothing unless it can fast-forward, `--no-ff` always records a merge commit, and `--no-commit` stops only when combined with `--no-ff`. A squash stages the merged content and records no second parent, so the merge base does not move and the branch cannot be reused safely.

**[ANIMATION]** step: mc.state-4

A merge commit is an ordinary commit with more than one parent, and parent 1 is what was checked out. `--first-parent` reads the mainline, and that mainline flips if `main` is fast-forwarded to a branch that merged `main`. An octopus merge has three or more parents and is rolled back on any conflict.

## HOMEWORK

Read sections 8.12 to 8.14 of [Chapter 8](../../textbook/ch08-merge.md).

Today you learned to choose the history a merge leaves behind, and to read a merge commit by its parents. Do the squash exercise while it's fresh. Next time: clean for Git, wrong for humans. Until then, look at the state first and type second. See you in the next one.

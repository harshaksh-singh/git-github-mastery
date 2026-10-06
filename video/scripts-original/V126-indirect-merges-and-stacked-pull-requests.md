# V126: Indirect merges and stacked pull requests

- **Part.** 5: GitHub
- **Module.** 21
- **Planned minutes.** 20
- **Prerequisites.** V056, V125
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), sections 17.13 and 17.14
- **Demo scripts.** `labs/ch17/stacked.sh`

## HOOK

**[ON SCREEN]** Pull request #1: "Merged". Reviews: none. Merge button: never pressed.

An auditor goes through last quarter's pull requests and stops at one. It is marked "merged". It has no approving review. And according to the timeline, nobody pressed its merge button. The auditor asks your CTO: your rules require an approval for every change to `main`. How is this one merged?

Nothing was bypassed and nobody cheated. Another pull request, which contained these commits, was merged. GitHub then marked this one as merged too, because its commits had become reachable from `main`. GitHub documents this, including the sentence that matters to the auditor: it happens "even if branch protection rules on that pull request were not satisfied".

## INTRODUCTION

Two short sections of Chapter 17 that belong together, because both are about pull requests that contain other pull requests.

Section 17.13, indirect merges: how a pull request becomes "merged" by reachability. Section 17.14, stacked pull requests: a deliberate chain of pull requests, each based on the branch below, and what happens to the chain when a layer changes or is merged.

One replay, `labs/ch17/stacked.sh`, with eight snippets. The GitHub side of stacking is described from section 17.14 only. The stacked pull requests feature is in public preview since 30 July 2026, with the CLI extension `github/gh-stack`. That extension is not part of the GitHub CLI 2.88.1 used in this course, none of its commands were run for the book, and I do not walk through the preview interface.

Labels: `git rebase` and `git rebase --onto` are 🟡 CAUTION. `git push --force-with-lease` is 🔴 DANGEROUS; its five answers were given two videos ago, and it is appropriate here for your own pull request branches after a rebase.

## LEARNING OBJECTIVES

After this video you can:

- Explain how a pull request can show as merged although nobody pressed merge on it.
- Build a stack of two pull requests and say what each one's base decides.
- Restack after a review fix in the lower layer.
- Predict the state of the upper pull request when the lower one is squash-merged and its branch deleted, and repair it.
- State the status of GitHub's stacked pull requests feature as the section gives it.

## CONCEPT

Indirect merges. In one sentence: GitHub marks a pull request as merged whenever its head commits become reachable from its base branch, by whatever route that happened.

In the documentation's words: "A pull request can be marked as merged if its head branch commits become reachable from the base branch outside that pull request. This can happen when the same commits are merged through another pull request or pushed directly to the default branch." And then: "Pull requests merged indirectly are marked as `merged` even if branch protection rules on that pull request were not satisfied."

Why does it matter? Reviews and checks are properties of a pull request. Reachability is a property of commits. A rule that requires an approval is satisfied by the pull request that was actually merged, not by each pull request whose commits it contained. So when an audit asks who approved a commit, you answer from the pull request that carried it onto the base.

The chapter lists indirect merges next to two other routes, `--admin` and bypass lists, as three ways a change reaches a protected branch without the reviews the rules describe. Know all three before you tell an auditor that every change was reviewed.

Stacked pull requests. In one sentence: a stack is a chain of pull requests in one repository in which each targets the branch of the one below, so that a large change is reviewed as small layers.

Why would you do that? A reviewer can read three pull requests of two hundred lines; nobody reads one of six hundred well. And the upper layers do not have to wait for the lower ones to merge before they are written.

How it works is nothing new. It is the wrong-base case from the last video, used on purpose. The base decides what you see. The upper pull request against `main` lists both layers. Against the branch below, it lists its own layer.

What GitHub's preview feature adds, from its reference page. All branches must be in the same repository: "Cross-fork stacks are not supported." "Every pull request in a stack is evaluated against rules for the base of the stack", typically `main`: required reviews, required status checks, CODEOWNERS and code scanning. A pull request can merge only when it and "all pull requests below it" meet the requirements, and when "the stack has a fully linear history between its branches". And the asynchronous merge API, generally available since 1 October 2026, "is the only merge API that supports stacked pull requests".

Linear, in Git terms, means the lower branch is an ancestor of the upper one. You can test that with one command, `git merge-base --is-ancestor`.

Two events break a stack, and they are the two failure modes to know.

First: a review fix lands on the lower branch. The upper branch still sits on the old tip. The lower branch is no longer its ancestor. The repair is a rebase of the upper layer onto the new tip of the lower one, and a forced push of the rewritten branch. With more layers this cascades. The preview's button for this exists, and the documentation notes that the button's commits "are not signed". In plain Git, `git rebase --update-refs` moves every branch of the chain in one run.

Second: the bottom layer is squash-merged. Then the upper layer is in the squash-then-reuse situation from the last video, because it was built on commits that never reached `main` as commits. What does GitHub do by itself? With the stack feature: "the remaining branches are automatically rebased so the next pull request targets the default base branch". Without it, GitHub only retargets: when a merged head branch is deleted, pull requests based on it switch to the merged pull request's base. The transplant is then yours to do.

When not to stack: layers that are not dependent should be independent pull requests. A stack multiplies force pushes and re-approvals, and a problem in the bottom layer delays every layer above. And from the chapter's edge cases: stacked pull requests are a preview; do not make a release process depend on them.

## MENTAL MODEL

Picture floors of a building under construction. Each floor is inspected separately, and each stands on the one below.

Two things can happen to a lower floor. It can be altered after the upper floor was built: then the upper floor has to be lifted and set down again on the altered one. That is restacking. Or the lower floor can be torn down and replaced by a prefabricated block of the same shape: that is a squash merge. The block has the same rooms, and none of the original beams. The upper floor is still bolted to beams that are no longer part of the building, and must be moved onto the block.

The model breaks for indirect merges, and the break is instructive. In a building, signing off the top floor does not make anyone think the floors below were inspected. On GitHub, merging the top layer makes every layer below show as "merged", with whatever inspections each one had or lacked.

## DIAGRAM

**[DIAGRAM]** A two-layer stack, before and after the bottom layer is squash-merged.

```text
  before                                           PR 1: base main,                 head feature/priority-routing
                                                   PR 2: base feature/priority-routing, head feature/sla-timers
   main        9a383e5
                     \
   lower              3807b29 --- 02820ea --- 9dcfb58 --- c38d3bd        feature/priority-routing
                                                                \
   upper                                                         bf00849 --- 670af6f      feature/sla-timers
                                                                 merge base of PR 2 = c38d3bd: PR 2 lists 2 commits

  after PR 1 is squash-merged and its branch deleted           PR 2 is retargeted: base main

   main        9a383e5 --- 77fc160    (squash of the lower layer: same content, no link to it)
                     \
                      3807b29 --- 02820ea --- 9dcfb58 --- c38d3bd --- bf00849 --- 670af6f   feature/sla-timers
                      merge base of PR 2 = 9a383e5: PR 2 lists 6 commits

  after  git rebase --onto origin/main feature/priority-routing feature/sla-timers

   main        9a383e5 --- 77fc160 --- a791005 --- 41f9055     feature/sla-timers: PR 2 lists 2 commits
```

At the top, the stack. The lower branch has four commits from `main`. The upper branch adds two. Pull request 2 has the lower branch as its base, so its merge base is the tip of the lower branch, `c38d3bd`, and it lists two commits.

In the middle, the lower pull request has been squash-merged: one new commit on `main`, `77fc160`, with no link to the lower branch. The branch is deleted, and pull request 2 now targets `main`. Lay the ruler: the merge base is back at `9a383e5`. Six commits.

At the bottom, the repair: the two commits of the upper layer, transplanted onto `main` with new IDs.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch17/stacked
```

<!-- snippet: ch17/stacked/01-stack -->
```text
$ git log --oneline --graph --decorate-refs=refs/heads feature/sla-timers
* 60a7f43 Alert before the SLA of a high-priority ticket expires
* 32a2f99 Add SLA minutes per priority
* 9dcfb58 Fix the name of the escalations queue
* 02820ea Route high-priority tickets to escalation
* 3807b29 Add priority scoring
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

Two layers, both pushed: `feature/priority-routing`, and on top of it `feature/sla-timers`.

```bash
git log --oneline origin/main..feature/sla-timers
git log --oneline feature/priority-routing..feature/sla-timers
git diff --stat feature/priority-routing...feature/sla-timers
```

**[PAUSE]** The upper layer has two commits of its own. How many does a pull request from it against `main` list? And against the branch below?

<!-- snippet: ch17/stacked/02-base-decides -->
```text
# The upper pull request against main lists both layers:
$ git log --oneline origin/main..feature/sla-timers
60a7f43 Alert before the SLA of a high-priority ticket expires
32a2f99 Add SLA minutes per priority
9dcfb58 Fix the name of the escalations queue
02820ea Route high-priority tickets to escalation
3807b29 Add priority scoring
# Against the branch below it, it lists its own layer:
$ git log --oneline feature/priority-routing..feature/sla-timers
60a7f43 Alert before the SLA of a high-priority ticket expires
32a2f99 Add SLA minutes per priority
$ git diff --stat feature/priority-routing...feature/sla-timers
 config/routing.yaml | 1 +
 router/priority.py  | 5 +++++
 2 files changed, 6 insertions(+)
```
<!-- /snippet -->

Five against `main`: both layers. Two against the branch below: its own layer. The base decides what the reviewer sees.

```bash
git merge-base --is-ancestor feature/priority-routing feature/sla-timers
```

<!-- snippet: ch17/stacked/03-linear -->
```text
# Linear stack: the lower branch is an ancestor of the upper one.
$ git merge-base --is-ancestor feature/priority-routing feature/sla-timers
[exit status: 0]
```
<!-- /snippet -->

Exit status 0: the lower branch is an ancestor of the upper one. The stack is linear.

Now a review fix lands on the lower branch.

```bash
git switch -q feature/priority-routing
git commit -q -am "Test the escalations route"
git log --oneline --graph --decorate-refs=refs/heads feature/priority-routing feature/sla-timers -4
git merge-base --is-ancestor feature/priority-routing feature/sla-timers
```

**[PAUSE]** One new commit on the lower branch. Is the stack still linear?

<!-- snippet: ch17/stacked/04-review-fix-below -->
```text
# A review fix lands on the lower branch:
$ git switch -q feature/priority-routing
$ printf '\n\ndef test_outage_goes_to_escalations():\n    assert classify({"subject": "Outage in EU"}) == "escalations"\n' >> tests/test_classify.py
$ git commit -q -am "Test the escalations route"
$ git log --oneline --graph --decorate-refs=refs/heads feature/priority-routing feature/sla-timers -4
* c38d3bd Test the escalations route
| * 60a7f43 Alert before the SLA of a high-priority ticket expires
| * 32a2f99 Add SLA minutes per priority
|/  
* 9dcfb58 Fix the name of the escalations queue
$ git merge-base --is-ancestor feature/priority-routing feature/sla-timers
[exit status: 1]
```
<!-- /snippet -->

Exit status 1. The graph shows a fork: the upper branch still sits on the old tip.

```bash
git rebase feature/priority-routing feature/sla-timers
git merge-base --is-ancestor feature/priority-routing feature/sla-timers
git log --oneline feature/priority-routing..feature/sla-timers
git push -q origin feature/priority-routing
git push -q --force-with-lease origin feature/sla-timers
```

<!-- snippet: ch17/stacked/05-restack -->
```text
# Restore the linear history: replay the upper layer on the new tip of the lower one.
$ git rebase feature/priority-routing feature/sla-timers
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/sla-timers.
$ git merge-base --is-ancestor feature/priority-routing feature/sla-timers
[exit status: 0]
$ git log --oneline feature/priority-routing..feature/sla-timers
670af6f Alert before the SLA of a high-priority ticket expires
bf00849 Add SLA minutes per priority
$ git push -q origin feature/priority-routing
$ git push -q --force-with-lease origin feature/sla-timers
```
<!-- /snippet -->

The upper layer is replayed on the new tip of the lower one. Linear again; two commits with new IDs. Notice the two pushes: the lower branch only gained a commit, so its push is a fast-forward. The upper branch was rewritten, so its push is forced. Under "dismiss stale approvals", both pull requests lose their approvals: the diff of each changed.

Now the lower pull request is squash-merged and its branch deleted. The upper one now targets `main`.

```bash
git fetch --prune
git log --oneline origin/main..feature/sla-timers
```

**[PAUSE]** The upper layer still has two commits of its own. What does its pull request list now?

<!-- snippet: ch17/stacked/06-bottom-squashed -->
```text
# The lower pull request was squash-merged and its branch deleted. The upper one now targets main:
$ git fetch --prune
From ../../server/ticket-router
 - [deleted]         (none)     -> origin/feature/priority-routing
   9a383e5..77fc160  main       -> origin/main
$ git log --oneline origin/main..feature/sla-timers
670af6f Alert before the SLA of a high-priority ticket expires
bf00849 Add SLA minutes per priority
c38d3bd Test the escalations route
9dcfb58 Fix the name of the escalations queue
02820ea Route high-priority tickets to escalation
3807b29 Add priority scoring
$ git merge-tree --write-tree --name-only origin/main feature/sla-timers
a9730e29529badbf0b65cf38bfcd5b884dde3c7b
router/priority.py

Auto-merging router/priority.py
CONFLICT (add/add): Merge conflict in router/priority.py
[exit status: 1]
```
<!-- /snippet -->

Six. The four commits of the lower layer are listed again, because the squash commit on `main` has no link to them. This is the middle picture of the diagram.

```bash
git rebase --onto origin/main feature/priority-routing feature/sla-timers
git log --oneline origin/main..feature/sla-timers
git merge-tree --write-tree origin/main feature/sla-timers
```

<!-- snippet: ch17/stacked/07-restack-on-main -->
```text
# Only the upper layer is new. Transplant it: everything after the old lower branch, onto main.
$ git rebase --onto origin/main feature/priority-routing feature/sla-timers
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/sla-timers.
$ git log --oneline origin/main..feature/sla-timers
41f9055 Alert before the SLA of a high-priority ticket expires
a791005 Add SLA minutes per priority
$ git merge-tree --write-tree origin/main feature/sla-timers
a59c7634e45ad06be44cb2ccab2a81fa40028b16
[exit status: 0]
```
<!-- /snippet -->

Only the upper layer is new. The command reads: everything after the old lower branch, onto `main`. Note that the local branch `feature/priority-routing` still exists in this clone and marks where the upper layer begins; `git fetch --prune` removed only the remote-tracking branch. Two commits, and a clean test merge. A forced push republishes it.

Last, the indirect merge, in a copy where nothing was merged yet. Asha merges the upper pull request into `main` with a merge commit.

```bash
git merge -q --no-ff -m "Merge pull request #2 from feature/sla-timers" origin/feature/sla-timers
git push -q origin main
git merge-base --is-ancestor origin/feature/priority-routing main
git log --oneline main..origin/feature/priority-routing
```

**[PAUSE]** Only pull request 2 was merged. What is the state of pull request 1?

<!-- snippet: ch17/stacked/08-indirect-merge -->
```text
# In a copy where nothing was merged yet. Asha merges the UPPER pull request into main:
$ cd ../../asha-indirect/ticket-router
$ git fetch -q
$ git merge -q --no-ff -m "Merge pull request #2 from feature/sla-timers" origin/feature/sla-timers
$ git push -q origin main
# Is the head of the LOWER pull request now reachable from main?
$ git merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 0]
$ git log --oneline main..origin/feature/priority-routing
```
<!-- /snippet -->

Exit status 0, and the range from `main` to the lower branch is empty: every commit of the lower pull request is on `main`. On GitHub, pull request 1 would now show as merged. Nobody pressed its merge button, and whatever review it still lacked was never given. That is the auditor's pull request.

## COMMON MISTAKES

1. Reading "merged" on a pull request as "reviewed and approved". Root cause: a pull request is marked merged when its head commits become reachable from the base, by any route, even if its own rules were not satisfied.
2. Opening the upper layer of a stack against `main`. Root cause: the base decides the range; against `main` the pull request lists every layer below it.
3. Pushing a review fix to a lower layer and leaving the upper layers alone. Root cause: the lower branch is no longer an ancestor of the upper one, so the stack is not linear.
4. Squash-merging the bottom layer and expecting the upper pull request to shrink by itself. Root cause: the squash has no ancestry to the lower branch; without the preview feature GitHub only retargets, and the transplant is yours.
5. Building a release process on stacked pull requests. Root cause: the feature is a public preview.

## PRODUCTION EXAMPLE

An LLM platform team splits a large change into two layers: a new priority-routing module, and SLA timers that use it. The second engineer starts the upper layer the same day, based on the lower branch. Reviews go faster. Then the team hits both events of this video in one week.

Monday, a review fix on the lower layer: the upper engineer restacks with one `git rebase` and a `--force-with-lease` push, and re-requests approval, because the diff changed.

Thursday, the lower layer is squash-merged, which is the repository's only allowed method, and its branch is deleted. The upper pull request suddenly lists six commits. The engineer recognizes the picture, runs `git rebase --onto origin/main` with the old lower branch as the upstream, checks the range, and pushes.

For their audit trail they write one sentence into the review policy: the approval of record for a commit is the approval on the pull request that carried it onto `main`. And they do not merge branches that contain unreviewed pull requests.

## PRACTICE EXERCISE

Do Exercise 21.3, "A stack, and a squash underneath it", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Before each step, write down the base and the merge base of the upper pull request and the number of commits it lists. After the squash, predict the number before you ask Git, and write the `--onto` command with its three arguments before you run it.

The challenge is Exercise 21.6, "Five commits for a two-commit fix", in the same file.

## INTERVIEW QUESTION

Question 277 of the CTO question bank:

> "The bottom pull request of a two-layer stack is squash-merged and its branch is deleted. What state is the upper pull request in, what does GitHub do by itself, and would you let a release process depend on stacked pull requests?"

A strong answer describes the upper pull request by its base, its merge base and its commit list after the event. It separates what GitHub does with the preview feature from what it does without it, and gives the Git command that finishes the job. On the last part it takes a position and bases it on the documented status of the feature, not on taste.

## RECAP

You should now be able to say:

- A pull request is marked merged when its head commits become reachable from its base, whoever merged what.
- Reviews and checks belong to pull requests; reachability belongs to commits.
- In a stack each pull request's base is the branch below, and linear means the lower branch is an ancestor of the upper.
- A fix below is followed by a rebase of the layers above; a squash of the bottom layer is followed by `git rebase --onto` of the next layer onto `main`.
- GitHub's stacked pull requests are a public preview since 30 July 2026.

## HOMEWORK

Read sections 17.13 and 17.14 of [Chapter 17](../../textbook/ch17-pull-requests.md).

# V123: What GitHub creates when a pull request opens, and what a pull request shows

- **Part.** 5: GitHub
- **Module.** 21
- **Planned minutes.** 26
- **Prerequisites.** V037, V064, V115
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), sections 17.1 to 17.3
- **Demo scripts.** `labs/ch17/pr-refs.sh`, `labs/ch17/pr-anatomy.sh`; GitHub-side walkthrough following Lab 21.1

## HOOK

**[ON SCREEN]** "CI: green on the pull request. Red on `main`, ten minutes after the merge."

CI, the automatic testing of every change, was green on the pull request, your proposal to merge a branch into `main`. Ten minutes after the merge it was red on `main`. Nobody pushed anything in between except the merge itself. Your CTO asks: what did CI test?

It tested a commit, one saved snapshot of the project, that is on no branch and in nobody's clone: a test merge that GitHub made, of your branch with `main` as `main` was at that moment. `main` moved on before you merged, and the test merge was not regenerated.

To answer questions like this one you need to know exactly what a pull request is made of, and which three commits every part of its page is computed from. Keep that green check in mind. In the demo you'll watch it go stale.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the first of five videos on pull requests, Chapter 17. Hold on to one sentence through all of them, from the first page of the chapter:

**[ON SCREEN]** "A pull request is a GitHub object that stores two names, a base and a head, and everything it shows is computed from three commits: the tip of the base, the tip of the head, and their merge base."

The page changes when one of the three changes, and for no other reason.

Today, two questions. What does GitHub create when a pull request opens? And what do the "Commits" tab and the "Files changed" tab show?

The sample project is `ticket-router`, a small service that reads a support ticket and names the queue that should answer it. A bare repository on disk, one with no working tree, plays the shared repository. You are the contributor. Asha maintains the repository and merges. Ravi is a teammate.

Two replays, `labs/ch17/pr-refs.sh` and `labs/ch17/pr-anatomy.sh`. One caution about the first: the commands on the "server" are plain Git that the textbook's author chose to produce the documented result. GitHub does not publish the commands it runs.

Labels: opening a pull request, `gh pr create`, is 🟡 CAUTION: it creates a GitHub object and starts review requests, checks and notifications. `git fetch origin pull/N/head:pr-N` is 🟢 SAFE.

## LEARNING OBJECTIVES

After this video you can:

- List what GitHub creates when a pull request is opened and which parts are Git data.
- Fetch a pull request's head with plain Git.
- Explain the test merge commit, when it is regenerated and what it means when it is absent.
- Explain why the commit list is a two-dot range and the diff a three-dot comparison.
- Construct a case where the two differ and say how merging the base into the branch changes each.

## CONCEPT

**[ANIMATION]** graph: fbbcc8d-53e7f57-f3e7ca9-9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=main => 9aa221a main; 16d4788 feature/priority-routing refs/pull/1/head; HEAD=main => 9aa221a main; 16d4788 feature/priority-routing refs/pull/1/head; ^9aa221a-135aad1 refs/pull/1/merge; 16d4788-135aad1; HEAD=main => 9aa221a-028b1de main; 16d4788 feature/priority-routing refs/pull/1/head; 135aad1 refs/pull/1/merge; HEAD=main title=The_base_repository_on_the_server id=refs

**[ANIMATION]** step: state-1

In one sentence: opening a pull request moves no branch. It creates a GitHub object and a little Git data in the base repository: a read-only ref for the head commit and, when the merge is clean, a test merge commit. The base is the branch you merge into, here `main`. The head is the branch whose commits you offer. A ref is a name that holds a commit ID.

You should be able to say which layer owns each item.

**[ON SCREEN]** The table of section 17.2: item, layer, where it lives.

Your commits, the head branch, the base branch: Git. Objects and refs in the head and base repositories.

The pull request number, title, description, labels, reviewers, reviews, comments, review threads: GitHub's database, not in any clone.

`refs/pull/<number>/head`: Git data written by GitHub. A ref in the base repository, read-only for you.

The test merge commit and `refs/pull/<number>/merge`: Git data written by GitHub. A commit and a ref in the base repository, "when possible".

Checks and commit statuses: GitHub and Actions, attached to commit IDs in GitHub's database.

The "Commits" and "Files changed" tabs: GitHub, computed from the three commits, stored nowhere in Git.

**[ANIMATION]** step: state-2

GitHub's reference says: "When you open a pull request, GitHub creates temporary Git references that point to the pull request's head branch and, when possible, to a simulated merge result." The page no longer spells out the ref names. Two other pages of the documentation confirm them: the checkout instructions and the Actions documentation.

**[ANIMATION]** step: state-3

The test merge. GitHub "creates a merge commit to test whether the pull request can be automatically merged into the base branch. This test commit is not added to the base branch or the head branch". Its parents are the latest commit on the base branch and the pull request's head commit. In our picture that's `135aad1`.

Three facts about it. First, CI uses it. For a `pull_request` event, the Actions documentation states that the checkout action "checks out the merge branch. Your CI tests run against the merged result, not just the head branch alone".

**[ANIMATION]** step: refs.state-4

Second, it is a stored commit, so it can be stale: `main` moves on, and its parent is still the old tip. The version note: before the nineteenth of February 2026, the test merge commit was also regenerated when somebody viewed the pull request page. Since then, it is generated only when changes are pushed to the pull request branch, when the merge base changes, or when the current test merge commit is older than 12 hours. Do not build automation on the freshness of the merge ref. One caveat marked unverified in the book: a REST guide still says the commit "is created when you view the pull request in the UI". That conflicts with the later changelog, which the course follows.

**[ANIMATION]** end

Third, when the merge conflicts, there is no merge ref. Two documented consequences: the merge button is deactivated until the conflict is resolved, and workflows will not run on `pull_request` activity. A pull request with no CI run at all is often a conflicting pull request.

**[ANIMATION]** step: refs.state-4

Two more properties. The head ref outlives the head branch: delete the branch, and the commits are still one fetch away. Nobody can rewrite or delete these refs with Git. And the base is pinned: GitHub "sets the base to the commit that branch references" when you open the pull request, and does not update that commit when the branch moves. That is why the pull request page and a compare page of the same branches can show different diffs.

**[ANIMATION]** graph: id=tabs f3e7ca9-9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=feature/priority-routing => + range:44c1e7b,12ae95d,16d4788:main..feature; say:The_"Commits"_tab:_git_log_base..head; name:log => f3e7ca9-9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=feature/priority-routing; mark:from:9a383e5; mark:to:16d4788; note:9a383e5:merge_base; say:The_"Files_changed"_tab:_git_diff_base...head; name:files => f3e7ca9-9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=feature/priority-routing; mark:from:9aa221a; mark:to:16d4788; note:9a383e5:merge_base; say:Two_dots_compare_tip_with_tip; name:two => f3e7ca9-9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=feature/priority-routing; role:9aa221a:base_tip; role:16d4788:head_tip; role:9a383e5:merge_base; say:Which_of_the_three_moved?; name:mine => f3e7ca9-9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788-8335b40 feature/priority-routing; 9aa221a-8335b40; HEAD=feature/priority-routing; note:9aa221a:merge_base; range:44c1e7b,12ae95d,16d4788,8335b40:main..feature; say:After_merging_main_into_the_branch; name:picture title=Two_tabs,_three_commits

**[ANIMATION]** step: files

Now the second question, with both branches on screen. In one sentence: the "Commits" tab is the output of `git log base..head`, and the "Files changed" tab is the output of `git diff base...head`, a diff from the merge base to the head. The merge base is the most recent commit that both histories contain: here, `9a383e5`.

You learned both notations in the history videos. For `git log`, `A..B` means "reachable from B and not from A". For `git diff`, which compares two snapshots, `A...B` means "from the merge base of A and B to B". GitHub's documentation states which one it uses: "Pull requests on GitHub show a three-dot diff", and gives the reason: "it focuses on 'what a pull request introduces'".

The limit of the three-dot diff, as a one-line root cause from the textbook: a three-dot diff is not "what will change on `main` when I merge". It is "what the head changed since the merge base". The two differ exactly when both sides changed the same thing. The test merge is the object that answers the first question.

**[ANIMATION]** end

Quick quiz. `main` gained a commit after you branched. Does the "Files changed" tab show that commit's change? A: yes, reversed. B: no. Your answer?

**[PAUSE]**

**[ANIMATION]** step: tabs.two

B. Three dots start at the merge base, so later commits on `main` stay out. A is what two dots show, and the demo proves it.

## MENTAL MODEL

**[ANIMATION]** stores: id=office boxes=a_shared_book:the_repository|*the_office:its_filing_system rows=1:A:bookmark:_the_base|1:A:bookmark:_the_head|1:B:the_form:_who_asks,_who_must_sign|1:B:the_discussion|2:B:a_drawer_under_your_request_number@hl|3:B:the_drawer_is_refs/pull/N/head@ref arrows=1:B1>A1:clipped_to|2:A2>B3:a_copy_of_the_proposed_pages at_1=15 title=A_change_request_clipped_to_two_bookmarks

**[ANIMATION]** step: 1

The textbook's analogy: a pull request is a change request clipped to two bookmarks in a shared book. The form, who asks, who must sign, the discussion, lives in the office's filing system.

**[ANIMATION]** step: 2

The analogy breaks at one point that matters. The office also keeps a copy of the proposed pages in its own drawer under your request number, where you can read it and cannot change it, and where it stays after you remove your bookmark.

**[ANIMATION]** step: 3

That drawer is `refs/pull/N/head`. It is the reason a deleted branch is not a deleted commit.

**[ANIMATION]** end

And keep the three commits as a triangle in your head: base tip, head tip, merge base. Try it now, thirty seconds, on paper: draw the two branches and mark the three. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: tabs.mine

Here's mine: base tip `9aa221a`, head tip `16d4788`, merge base `9a383e5`. Every question about a pull request page begins with "which of the three moved?"

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** The base repository on the server, after pull request 1 is opened.

```text
  base repository on the server
  fbbcc8d---53e7f57---f3e7ca9---9a383e5---9aa221a              refs/heads/main
                                    \            \
                                     \            135aad1      refs/pull/1/merge   (test merge; on no branch)
                                      \          /
                                       44c1e7b---12ae95d---16d4788
                                                              |
                                                              +-- refs/heads/feature/priority-routing
                                                              +-- refs/pull/1/head   (read-only)
  GitHub's database:  pull request #1  { base: main, head: feature/priority-routing, title, reviews, checks ... }
```

The top line is `main`, ending at `9aa221a`. The branch forks at `9a383e5` and has three commits ending at `16d4788`. Two refs name that commit: your branch, and `refs/pull/1/head`.

Between them, `135aad1`: a merge commit with two parents, the tip of `main` and the head. One ref names it, `refs/pull/1/merge`, and it is on no branch. The bottom line is the GitHub object: two names and the discussion.

**[DIAGRAM]** The same branches, and what the two tabs compare.

```text
                       9aa221a                 main            two-dot:   9aa221a  compared with  16d4788
                      /
  ...f3e7ca9---9a383e5                                         three-dot: 9a383e5  compared with  16d4788
                      \                                                   (merge base)
                       44c1e7b---12ae95d---16d4788             feature/priority-routing
                       \_______________________/
                        git log main..feature: the "Commits" tab
```

The bracket at the bottom is the "Commits" tab: three commits. On the right, the two diffs. Two dots compare tip with tip. Three dots compare the merge base with the head. The "Files changed" tab is the three-dot one.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch17/pr-refs
```

On the server, "pull request 1" becomes a ref.

```bash
cd server/ticket-router.git
git update-ref refs/pull/1/head refs/heads/feature/priority-routing
git config set receive.hideRefs refs/pull
git for-each-ref --format="%(objectname:short) %(refname)"
```

<!-- snippet: ch17/pr-refs/01-server-opens-pr -->
```text
# On the server. Opening pull request 1 for feature/priority-routing, as Git data:
$ cd server/ticket-router.git
$ git update-ref refs/pull/1/head refs/heads/feature/priority-routing
# Clients may read refs/pull/ but not write it:
$ git config set receive.hideRefs refs/pull
$ git for-each-ref --format="%(objectname:short) %(refname)"
16d4788 refs/heads/feature/priority-routing
9aa221a refs/heads/main
16d4788 refs/pull/1/head
```
<!-- /snippet -->

Two refs name commit `16d4788`. `receive.hideRefs` is the stock Git setting that hides a namespace from pushes while leaving it readable.

```bash
cd ../../asha/ticket-router
git ls-remote origin
git config get --all remote.origin.fetch
git fetch
git for-each-ref --format="%(refname)" refs/remotes refs/pull
```

**[PAUSE]** The server advertises `refs/pull/1/head`. After a plain `git fetch`, does Asha's clone have it?

<!-- snippet: ch17/pr-refs/02-client-sees -->
```text
$ cd ../../asha/ticket-router
$ git ls-remote origin
9aa221a9fb05716040012e33f1e7c3074f948edc	HEAD
16d4788572b31e17e4c3104a1d9861a5ce2c47ea	refs/heads/feature/priority-routing
9aa221a9fb05716040012e33f1e7c3074f948edc	refs/heads/main
16d4788572b31e17e4c3104a1d9861a5ce2c47ea	refs/pull/1/head
# A clone fetches refs/heads/* only, so the pull request ref is not in Asha's clone:
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
$ git fetch
$ git for-each-ref --format="%(refname)" refs/remotes refs/pull
refs/remotes/origin/HEAD
refs/remotes/origin/feature/priority-routing
refs/remotes/origin/main
```
<!-- /snippet -->

It does not. A clone fetches `refs/heads/*` only. To take a pull request into your clone, you name the ref.

```bash
git fetch origin pull/1/head:pr-1
git log --oneline -3 pr-1
git rev-parse pr-1 origin/feature/priority-routing
```

<!-- snippet: ch17/pr-refs/03-fetch-head -->
```text
$ git fetch origin pull/1/head:pr-1
From ../../server/ticket-router
 * [new ref]         refs/pull/1/head -> pr-1
$ git log --oneline -3 pr-1
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
$ git rev-parse pr-1 origin/feature/priority-routing
16d4788572b31e17e4c3104a1d9861a5ce2c47ea
16d4788572b31e17e4c3104a1d9861a5ce2c47ea
```
<!-- /snippet -->

`pull/1/head` is shorthand for `refs/pull/1/head`. `gh pr checkout 1` does this fetch for you.

```bash
git push origin pr-1:refs/pull/1/head
```

<!-- snippet: ch17/pr-refs/04-read-only -->
```text
$ git push origin pr-1:refs/pull/1/head
To ../../server/ticket-router.git
 ! [remote rejected] pr-1 -> refs/pull/1/head (deny updating a hidden ref)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git push origin main:refs/pull/9/head
To ../../server/ticket-router.git
 ! [remote rejected] main -> refs/pull/9/head (deny updating a hidden ref)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
```
<!-- /snippet -->

"Deny updating a hidden ref." The namespace is read-only.

Now the test merge. A server has no working tree, so the merge is computed in the object database, with `git merge-tree`, which you met in the merge videos.

```bash
cd ../../server/ticket-router.git
git merge-tree --write-tree main refs/pull/1/head
tree=$(git merge-tree --write-tree main refs/pull/1/head)
merge=$(git commit-tree $tree -p main -p refs/pull/1/head -m "Merge refs/pull/1/head into main")
git update-ref refs/pull/1/merge $merge
git log --oneline --graph -5 refs/pull/1/merge
```

<!-- snippet: ch17/pr-refs/05-test-merge -->
```text
# On the server. A merge without a working tree (Chapter 8, section 8.17):
$ cd ../../server/ticket-router.git
$ git merge-tree --write-tree main refs/pull/1/head
beff5a60b5d7f4a2b93e41130391fc485f5970e0
[exit status: 0]
$ tree=$(git merge-tree --write-tree main refs/pull/1/head)
$ merge=$(git commit-tree $tree -p main -p refs/pull/1/head -m "Merge refs/pull/1/head into main")
$ git update-ref refs/pull/1/merge $merge
$ git log --oneline --graph -5 refs/pull/1/merge
*   135aad1 Merge refs/pull/1/head into main
|\  
| * 16d4788 Fix the name of the escalations queue
| * 12ae95d Route high-priority tickets to escalation
| * 44c1e7b Add priority scoring
* | 9aa221a Raise the confidence threshold to 0.7
|/  
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/heads refs/pull
16d4788 refs/heads/feature/priority-routing
9aa221a refs/heads/main
16d4788 refs/pull/1/head
135aad1 refs/pull/1/merge
```
<!-- /snippet -->

```bash
git branch --contains refs/pull/1/merge
git show -s --format="%h parents: %p" refs/pull/1/merge
git rev-parse main refs/pull/1/head
```

**[PAUSE]** Which branches contain the test merge commit?

<!-- snippet: ch17/pr-refs/06-neither-branch-moved -->
```text
# The test merge commit is on neither branch:
$ git branch --contains refs/pull/1/merge
$ git show -s --format="%h parents: %p" refs/pull/1/merge
135aad1 parents: 9aa221a 16d4788
$ git rev-parse main refs/pull/1/head
9aa221a9fb05716040012e33f1e7c3074f948edc
16d4788572b31e17e4c3104a1d9861a5ce2c47ea
```
<!-- /snippet -->

None. `135aad1` is a real merge commit with two parents, reachable only from `refs/pull/1/merge`. Neither branch moved.

<!-- snippet: ch17/pr-refs/07-ci-checks-out-merge -->
```text
# What a CI job sees when it checks out the merge ref:
$ cd ../../ravi/ticket-router
$ git fetch origin refs/pull/1/merge
From ../../server/ticket-router
 * branch            refs/pull/1/merge -> FETCH_HEAD
$ git switch --detach FETCH_HEAD
HEAD is now at 135aad1 Merge refs/pull/1/head into main
$ git log --oneline -1
135aad1 Merge refs/pull/1/head into main
$ cat config/routing.yaml
model: router-small-v1
confidence_threshold: 0.7
fallback_queue: general
$ grep -c escalations router/classify.py
2
```
<!-- /snippet -->

This is what a CI job does for a pull request event: it checks out the merge ref. It tests your commits merged with `main` as `main` was when the test merge was made.

Now one more commit lands on `main`. Predict: does the stored test merge follow it? Say it out loud.

**[PAUSE]**

```bash
git rev-parse --short main
git show -s --format="%h parents: %p" refs/pull/1/merge
git merge-base --is-ancestor main refs/pull/1/merge
```

<!-- snippet: ch17/pr-refs/08-stale-merge-ref -->
```text
# On the server, after one more commit landed on main:
$ git rev-parse --short main
028b1de
$ git show -s --format="%h parents: %p" refs/pull/1/merge
135aad1 parents: 9aa221a 16d4788
# The merge ref is a stored commit. It is as fresh as its first parent.
$ git merge-base --is-ancestor main refs/pull/1/merge
[exit status: 1]
```
<!-- /snippet -->

It doesn't. The first parent of the stored merge is still `9aa221a`, and `main` is at `028b1de`. The merge ref is as fresh as its first parent.

**[ANIMATION]** step: refs.state-4

And there's the green check from the hook: green on a stale test merge, red on the real one.

<!-- snippet: ch17/pr-refs/09-conflict-no-merge-ref -->
```text
# Pull request 2 changes a line that main has changed since. On the server:
$ git merge-tree --write-tree --name-only main refs/pull/2/head
25dcf7083388484e218d7dc1b73f8e560e6c0909
config/routing.yaml

Auto-merging config/routing.yaml
CONFLICT (content): Merge conflict in config/routing.yaml
[exit status: 1]
# No clean tree, so no test merge commit and no refs/pull/2/merge:
$ git for-each-ref --format="%(refname)" refs/pull
refs/pull/1/head
refs/pull/1/merge
refs/pull/2/head
```
<!-- /snippet -->

A second pull request changes a line that `main` has changed since. `git merge-tree` exits with status 1. There is no clean tree, so no test merge commit and no `refs/pull/2/merge`. That is the "when possible".

```bash
git update-ref -d refs/heads/feature/priority-routing
git for-each-ref --format="%(objectname:short) %(refname)" refs/heads refs/pull
```

**[PAUSE]** The head branch is deleted on the server. Can Ravi still fetch the three commits?

<!-- snippet: ch17/pr-refs/10-head-outlives-branch -->
```text
# The head branch is deleted. The pull request ref still names the commits:
$ git update-ref -d refs/heads/feature/priority-routing
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/heads refs/pull
e996b41 refs/heads/fix/threshold
d8c296f refs/heads/main
16d4788 refs/pull/1/head
135aad1 refs/pull/1/merge
e996b41 refs/pull/2/head
$ cd ../../ravi/ticket-router
$ git fetch --prune
From ../../server/ticket-router
 - [deleted]         (none)     -> origin/feature/priority-routing
   028b1de..d8c296f  main       -> origin/main
$ git fetch origin pull/1/head
From ../../server/ticket-router
 * branch            refs/pull/1/head -> FETCH_HEAD
$ git log --oneline -1 FETCH_HEAD
16d4788 Fix the name of the escalations queue
```
<!-- /snippet -->

He can: `git fetch origin pull/1/head`. So for a leaked secret, deleting the branch removes nothing. The credential must be rotated.

**[TERMINAL]** The two tabs.

```bash
labs/run ch17/pr-anatomy
```

```bash
git fetch
git log --oneline --graph origin/main feature/priority-routing
```

<!-- snippet: ch17/pr-anatomy/01-two-branches -->
```text
$ git fetch
From ../../server/ticket-router
   9a383e5..9aa221a  main       -> origin/main
$ git log --oneline --graph origin/main feature/priority-routing
* 9aa221a Raise the confidence threshold to 0.7
| * 16d4788 Fix the name of the escalations queue
| * 12ae95d Route high-priority tickets to escalation
| * 44c1e7b Add priority scoring
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

```bash
git log --oneline origin/main..feature/priority-routing
git rev-list --count origin/main..feature/priority-routing
git merge-base origin/main feature/priority-routing
```

<!-- snippet: ch17/pr-anatomy/02-commit-list -->
```text
# The "Commits" tab: commits reachable from the head branch and not from the base branch.
$ git log --oneline origin/main..feature/priority-routing
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
$ git rev-list --count origin/main..feature/priority-routing
3
```
<!-- /snippet -->

<!-- snippet: ch17/pr-anatomy/03-merge-base -->
```text
$ git merge-base origin/main feature/priority-routing
9a383e547a1c8840f3c5c7b23bfab6120f366ed0
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
9a383e5 Add classifier test
```
<!-- /snippet -->

The "Commits" tab: three commits. `9aa221a`, the newer commit on `main`, is not among them: it is reachable from the base. The merge base is `9a383e5`.

```bash
git diff --stat origin/main...feature/priority-routing
git diff --stat origin/main..feature/priority-routing
```

**[PAUSE]** Your branch changed two files. How many files will the two-dot diff list?

<!-- snippet: ch17/pr-anatomy/04-three-dot -->
```text
# The "Files changed" tab: merge base compared with the head. Three dots.
$ git diff --stat origin/main...feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch17/pr-anatomy/05-two-dot -->
```text
# Two dots compare the two tips. The newer commit on main appears, reversed.
$ git diff --stat origin/main..feature/priority-routing
 config/routing.yaml | 2 +-
 router/classify.py  | 6 +++++-
 router/priority.py  | 6 ++++++
 3 files changed, 12 insertions(+), 2 deletions(-)
$ git diff origin/main..feature/priority-routing -- config/routing.yaml
diff --git a/config/routing.yaml b/config/routing.yaml
index b97f8de..a84cfc9 100644
--- a/config/routing.yaml
+++ b/config/routing.yaml
@@ -1,3 +1,3 @@
 model: router-small-v1
-confidence_threshold: 0.7
+confidence_threshold: 0.6
 fallback_queue: general
```
<!-- /snippet -->

Three. A third file appears, backwards: the diff claims your branch lowers the threshold from 0.7 to 0.6. Your branch never touched that file. A two-dot diff compares the two tips, so every change that landed on `main` after you branched shows up as its own reversal. It is what `git diff main` shows on your machine, and the usual source of "GitHub shows something different from my terminal".

<!-- snippet: ch17/pr-anatomy/06-equivalence -->
```text
# A three-dot diff is a two-dot diff whose left side is the merge base.
$ git diff --stat $(git merge-base origin/main feature/priority-routing) feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

The three-dot diff is a two-dot diff whose left side is the merge base.

```bash
git merge -q origin/main
git diff --stat origin/main..feature/priority-routing
git diff --stat origin/main...feature/priority-routing
git log --oneline origin/main..feature/priority-routing
```

<!-- snippet: ch17/pr-anatomy/07-merge-main-in -->
```text
# After the base branch is merged into the head branch, the tip of main is the merge base.
$ git merge -q origin/main
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
9aa221a Raise the confidence threshold to 0.7
$ git diff --stat origin/main..feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
$ git diff --stat origin/main...feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
$ git log --oneline origin/main..feature/priority-routing
8335b40 Merge remote-tracking branch 'origin/main' into feature/priority-routing
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
```
<!-- /snippet -->

GitHub's advice for keeping the two views equal is to merge the base into the topic branch. The merge base moved to the tip of `main`, the two diffs agree, and the commit list gained a merge commit.

**[ANIMATION]** step: tabs.picture

Here it is as a picture: the merge base is now the tip of `main`, and the list has four commits. That is the price, and the next video weighs it against rebasing.

**[ANIMATION]** end

**[ON SCREEN]** GitHub walkthrough, in the normal shell, on your practice repository. The interface changes; the documentation pages cited in section 17.2 are the reference. No output is shown.

Push a small branch and open a pull request against `main`. On the pull request page, open the tab that lists commits and the tab that lists changed files. Before you look, predict both from your terminal:

```bash
git fetch
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
```

Then look for the Git data GitHub created, and take the pull request into your clone by its number:

```bash
git ls-remote origin 'refs/pull/*'
git fetch origin pull/1/head:pr-1
```

According to the documentation you will find a `head` ref for the pull request and, when the merge is clean, a `merge` ref. Lab 21.1 itself runs the whole cycle locally in the lab shell with three repositories. Its step "predict the pull request" is this exercise.

## COMMON MISTAKES

Five mistakes to watch for.

1. Believing CI tested the head commit. Root cause: for a pull request event the checkout is the test merge, a stored commit that can be older than the base branch.
2. Deleting a branch to remove a pushed secret. Root cause: `refs/pull/N/head` still names the commits, and nobody can delete that ref with Git.
3. Comparing with `git diff main` and concluding that GitHub shows something else. Root cause: that is a two-dot diff of the tips; the page shows a three-dot diff from the merge base.
4. Reading the "Files changed" tab as "what will change on `main`". Root cause: it is what the head changed since the merge base; the two differ when both sides changed the same thing.
5. Waiting for CI on a pull request that never starts a run. Root cause: with a merge conflict there is no test merge, and `pull_request` workflows do not run.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: refs.state-4

**[ANIMATION]** say: The job recorded the test merge, a commit in nobody's clone

Now, out of the lab. An evaluation job posts a metric to every pull request of an LLM application: answer quality on a fixed test set. A week later someone tries to reproduce a number and cannot. The job recorded the commit it checked out, and that commit is the test merge: a commit in nobody's clone, which may be regenerated at any time.

The fix from the textbook: record `github.event.pull_request.head.sha` next to the metric, or the number cannot be reproduced. And for the hook, the team stops treating a green pull request as a statement about `main`: the statement was about `main` as it was when the test merge was made.

**[ANIMATION]** end

Before opening any pull request, the team's habit is three commands: `git fetch`, `git log --oneline origin/main..HEAD`, and `git diff --stat origin/main...HEAD`. A commit you did not write will be seen by the reviewer too.

## PRACTICE EXERCISE

Your turn. Do Lab 21.1, "A full fork and pull request cycle", in [`lab-manual/m21-pull-requests-forks.md`](../../lab-manual/m21-pull-requests-forks.md). At this stage, concentrate on the steps up to opening the pull request. Before the step that opens it, write down what the "Commits" tab and the "Files changed" tab would show, as the output of two Git commands, and which refs will exist in which of the three repositories.

The challenge is Exercise 21.4, "Three small mysteries", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 262 of the CTO question bank:

> "What exactly does GitHub create when a pull request is opened? Which parts are Git data, and in which repository do they live?"

**[PAUSE]**

Answer out loud. A strong answer lists the items and sorts each into a layer. It names the two refs, says which repository holds them, and says what you can and cannot do to them with Git. It explains the condition under which the second one does not exist, and it mentions what does not happen: no branch moves.

## RECAP

**[ANIMATION]** step: refs.state-4

Let's land this. One picture holds the video: two branches, two refs GitHub wrote, and a test merge that can go stale.

You should now be able to say:

- A pull request is a GitHub object over two names; the page is computed from the base tip, the head tip and their merge base.
- GitHub writes `refs/pull/N/head` and, when the merge is clean, a test merge under `refs/pull/N/merge`, in the base repository.
- CI for a pull request tests the test merge, which is stored and can be stale; with a conflict there is none.
- "Commits" is `git log base..head`; "Files changed" is `git diff base...head`.
- Merging the base into the branch makes the two-dot and three-dot diffs equal and adds a merge commit to the list.

## HOMEWORK

Read sections 17.1 to 17.3 of [Chapter 17](../../textbook/ch17-pull-requests.md). Do Exercise 21.1, "A draft, a range, and the head ref", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

You can now predict a pull request's two tabs from your terminal. Practise with Lab 21.1. Next: the pull request lifecycle, from draft to mergeable. Until then, look at the state first and type second. See you in the next one.

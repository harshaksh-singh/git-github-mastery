# Chapter 17: Pull Requests

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, with the quoted documentation pages re-read on 2 October 2026. Transcripts are real output from `labs/ch17/`. Nothing in this chapter was run against GitHub: every statement about what GitHub does or displays is taken from its documentation or changelog and carries the link.

## 17.1 Why this matters

Four questions a CTO can ask in one week:

1. "The pull request changed one line. The page lists four commits and three files. Which is true?"
2. "CI was green on the pull request and red on `main` ten minutes after the merge. What did CI test?"
3. "The audit asks which commit the reviewer approved. The commit ID on `main` is not in the pull request. Where did it go?"
4. "We deleted the branch that contained the leaked key. Why can the commit still be fetched?"

Each is answered by knowing which part of a pull request is Git data, which part is a GitHub object, and which commits GitHub compares when it draws the page. The answers are in sections 17.12, 17.2, 17.8, and 17.2 again.

Hold on to one sentence through the chapter. **A pull request is a GitHub object that stores two names, a base and a head, and everything it shows is computed from three commits: the tip of the base, the tip of the head, and their merge base.** You met all three in [Chapter 8: Merge](ch08-merge.md). The page changes when one of the three changes, and for no other reason.

The sample project is `ticket-router`, a small service that reads a support ticket and names the queue that should answer it: `router/classify.py` holds the rules, `router/priority.py` the urgency scoring, `config/routing.yaml` the model settings. A bare repository on disk plays the shared repository. You are the contributor. Asha maintains the repository and merges. Ravi is a teammate.

## 17.2 What GitHub creates when a pull request opens

**In one sentence.** Opening a pull request moves no branch; it creates a GitHub object and a little Git data in the base repository: a read-only ref for the head commit and, when the merge is clean, a test merge commit.

**Analogy.** A pull request is a change request clipped to two bookmarks in a shared book. The form (who asks, who must sign, the discussion) lives in the office's filing system. The analogy breaks at one point that matters: the office also keeps a copy of the proposed pages in its own drawer under your request number, where you can read it and cannot change it, and where it stays after you remove your bookmark.

**Precisely.** You should be able to say which layer owns each item.

| Item | Layer | Where it lives |
|---|---|---|
| Your commits, the head branch, the base branch | Git | objects and `refs/heads/...` in the head and base repositories |
| The pull request number, title, description, labels, reviewers, reviews, comments, review threads | GitHub | GitHub's database; not in any clone |
| `refs/pull/<number>/head` | Git data written by GitHub | a ref in the **base** repository, read-only for you |
| The test merge commit and `refs/pull/<number>/merge` | Git data written by GitHub | a commit and a ref in the base repository, "when possible" |
| Checks and commit statuses | GitHub (and Actions) | attached to commit IDs in GitHub's database |
| The "Commits" and "Files changed" tabs | GitHub | computed from the three commits; stored nowhere in Git |

GitHub's reference: "When you open a pull request, GitHub creates temporary Git references that point to the pull request's head branch and, when possible, to a simulated merge result. These refs help GitHub and integrations evaluate the pull request without changing the base branch" ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#pull-request-refs-and-merge-branches)). The page no longer spells out the ref names. Two other pages confirm them: the checkout instructions use `git fetch origin pull/ID/head:BRANCH_NAME` ([checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally)), and the Actions documentation sets `GITHUB_REF` to `refs/pull/PULL_REQUEST_NUMBER/merge` for `pull_request` events ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#how-the-merge-branch-affects-your-workflow)).

**See it.** The Git part can be reproduced with a bare repository. The commands on the "server" below are plain Git that I chose to produce the documented result; GitHub does not publish the commands it runs.

Your branch `feature/priority-routing` has three commits and is pushed. `main` has moved on by one commit since you branched. On the server, "pull request 1" becomes a ref:

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

`receive.hideRefs` is the stock Git setting that hides a ref namespace from pushes while leaving it readable. Both refs name the same commit, `16d4788`. A normal clone never sees the new one, because the default refspec fetches `refs/heads/*` only ([Chapter 12](ch12-remote-operations.md), section 12.12):

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

The server advertises `refs/pull/1/head`; the clone has nothing under `refs/pull`. To take a pull request into your clone you name the ref, as the documentation shows:

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

`pull/1/head` is shorthand for `refs/pull/1/head`. `gh pr checkout 1` does this fetch for you (section 17.16).

The namespace is read-only. GitHub's page quotes the error; plain Git produces the identical line when a ref is hidden from pushes:

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

Now the second piece of Git data. GitHub "creates a merge commit to test whether the pull request can be automatically merged into the base branch. This test commit is not added to the base branch or the head branch" ([REST: get a pull request](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)). Its parents are "the latest commit on the base branch and the pull request's head commit" ([available rules, signed commits](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-signed-commits)). A server has no working tree, so the merge is computed in the object database, which stock Git exposes as `git merge-tree` ([Chapter 8](ch08-merge.md), section 8.17):

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

`135aad1` is a real merge commit with two parents, reachable only from `refs/pull/1/merge`. Neither branch moved:

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

**Picture.**

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

This answers question 2 of section 17.1. For a `pull_request` event, the Actions documentation states that `actions/checkout` "checks out the merge branch. Your CI tests run against the merged result, not just the head branch alone", and that `GITHUB_SHA` "is the SHA of the merge commit on the merge branch" ([events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#how-the-merge-branch-affects-your-workflow)). CI tested `135aad1`: your three commits merged with `main` **as `main` was when the test merge was made**. Chapter 20A: GitHub Actions fundamentals covers the workflow side.

**The test merge is a stored commit, so it can be stale.** After one more commit lands on `main`:

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

The first parent of the stored merge is still `9aa221a`, and `main` is at `028b1de`. Until the merge is regenerated, whatever reads the merge ref sees an older `main`.

> **Version note.** Older behavior: the test merge commit was also regenerated when somebody viewed the pull request page. Current behavior: it is generated only when changes are pushed to the pull request branch, when the merge base changes, or when the current test merge commit is older than 12 hours. Since: 19 February 2026 ([changelog](https://github.blog/changelog/2026-02-19-changes-to-test-merge-commit-generation-for-pull-requests/)). Recommended: do not build automation on the freshness of `refs/pull/N/merge`; the [REST guide](https://docs.github.com/en/rest/guides/using-the-rest-api-to-interact-with-your-git-database#checking-mergeability-of-pull-requests) warns that "this content becomes outdated without warning".

> **Unverified.** The same REST guide still says a test merge commit "is created when you view the pull request in the UI". The Phase 0 report records this as a conflict with the changelog, which is later and which this course follows.

**When the merge conflicts there is no merge ref.** A second pull request changes a line that `main` has changed since:

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

Exit status 1 and no clean tree: the "when possible" in GitHub's sentence. Two documented consequences follow: the merge button is deactivated until the conflict is resolved ([merge conflicts](https://docs.github.com/en/pull-requests/reference/merge-conflicts)), and "Workflows will not run on `pull_request` activity if the pull request has a merge conflict" ([events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)). A pull request with no CI run at all is often a conflicting pull request.

**The head ref outlives the head branch.** This answers question 4:

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

The branch is gone and the commits are still one `git fetch origin pull/1/head` away. GitHub documents the principle: "After a pull request is opened, GitHub stores all of the changes remotely. Commits in a pull request are available in a repository even before the pull request is merged" ([checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally)). Nobody can rewrite or delete these refs with Git. For a leaked secret, deleting the branch therefore removes nothing; the credential must be rotated (Chapter 21B: Repository security).

**The base is pinned.** "When you open a pull request, GitHub sets the base to the commit that branch references. If the branch is updated in the future, GitHub does not update the base branch's commit" ([changing the base branch](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/changing-the-base-branch-of-a-pull-request)). The pull request page keeps describing your change from where it started, while a compare page of the same branches follows the current tips; the two "can calculate changed files from different merge bases. As a result, the same branches can sometimes show different diffs in each place" ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#differences-between-commits-on-compare-and-pull-request-pages)).

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| Open a pull request (`gh pr create`) 🟡 | unchanged | unchanged | unchanged | unchanged | unchanged (`gh` may first push the branch and set its upstream) | base repository gains `refs/pull/N/head` and, when the merge is clean, a test merge commit under `refs/pull/N/merge`; no branch moves | pull request object created; review requests, checks and notifications start |
| `git fetch origin pull/N/head:pr-N` 🟢 | unchanged | unchanged | unchanged | unchanged | new local branch `pr-N`; `FETCH_HEAD` rewritten; objects added | unchanged | unchanged |

**In production.** An evaluation job that posts a metric to every pull request must record which commit it evaluated. With the default checkout that is the test merge, a commit in nobody's clone. Record `github.event.pull_request.head.sha` next to the metric, or the number cannot be reproduced.

## 17.3 What a pull request shows: `base..head` and `base...head`

**In one sentence.** The "Commits" tab is the output of `git log base..head`, and the "Files changed" tab is the output of `git diff base...head`, a diff from the merge base to the head.

**Precisely.** [Chapter 14A: History investigation](ch14a-history-investigation.md) taught both notations (sections 14A.2 and 14A.8). For `git log`, `A..B` means "reachable from B and not from A". For `git diff`, which compares two snapshots and knows nothing about ranges, `A...B` means "from the merge base of A and B to B". GitHub's documentation states which one a pull request uses: "Pull requests on GitHub show a three-dot diff", and gives the reason: "Because the three-dot comparison uses the merge base, it focuses on 'what a pull request introduces'" ([branches reference](https://docs.github.com/en/pull-requests/reference/branches#three-dot-and-two-dot-git-diff-comparisons)).

**See it.** You have not fetched since you pushed. One fetch, then the two branches:

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

The commit list of the pull request, and the commit both sides share:

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

Three commits. `9aa221a`, the newer commit on `main`, is not among them: it is reachable from the base. The diff the reviewer sees:

<!-- snippet: ch17/pr-anatomy/04-three-dot -->
```text
# The "Files changed" tab: merge base compared with the head. Three dots.
$ git diff --stat origin/main...feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

Two files, both yours. Compare the two-dot diff of the same branches:

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

A third file appears, backwards: the diff claims your branch lowers the threshold from 0.7 to 0.6. Your branch never touched that file. A two-dot diff compares the two tips, so every change that landed on `main` after you branched shows up as its own reversal. It is what `git diff main` shows on your machine, and the usual source of "GitHub shows something different from my terminal". The three-dot diff is a two-dot diff whose left side is the merge base:

<!-- snippet: ch17/pr-anatomy/06-equivalence -->
```text
# A three-dot diff is a two-dot diff whose left side is the merge base.
$ git diff --stat $(git merge-base origin/main feature/priority-routing) feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

**Picture.**

```text
                       9aa221a                 main            two-dot:   9aa221a  compared with  16d4788
                      /
  ...f3e7ca9---9a383e5                                         three-dot: 9a383e5  compared with  16d4788
                      \                                                   (merge base)
                       44c1e7b---12ae95d---16d4788             feature/priority-routing
                       \_______________________/
                        git log main..feature: the "Commits" tab
```

GitHub's advice for keeping the two views equal is to merge the base into the topic branch: "When you merge the base branch, the diffs shown by two-dot and three-dot comparisons are the same" (same page). The run confirms it, and shows the price:

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

The merge base moved to `9aa221a`, the two diffs agree, and the commit list gained a merge commit. Section 17.7 weighs that against rebasing.

> **Root cause.** A three-dot diff is not "what will change on `main` when I merge". It is "what the head changed since the merge base". The two differ exactly when both sides changed the same thing. The test merge of section 17.2 is the object that answers the first question.

**In production.** Before you open a pull request, run `git fetch`, `git log --oneline origin/main..HEAD` and `git diff --stat origin/main...HEAD`. A commit you did not write will be seen by the reviewer too (section 17.12).

## 17.4 The lifecycle: draft, ready, review, merge or close

**In one sentence.** A pull request moves from draft to ready for review, collects reviews and checks, and ends merged or closed; each state is GitHub data, and only the merge writes to a branch.

**Draft.** "Draft pull requests cannot be merged, and code owners are not automatically requested to review them." Marking the pull request ready "will request reviews from any code owners", and you "can convert a pull request to a draft at any time" ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#draft-pull-requests)). Use a draft when you want CI and early comments but not a formal review.

> **Outdated advice.** Older material says draft pull requests need a paid plan for private repositories. Since 1 May 2025 they are available in every repository ([changelog](https://github.blog/changelog/2025-05-01-draft-pull-requests-are-now-available-in-all-repositories/)).

**Reviews.** A review has one of three outcomes ([pull request reviews](https://docs.github.com/en/pull-requests/reference/pull-request-reviews)):

| Outcome | Meaning | Does it block the merge? |
|---|---|---|
| Comment | feedback without a verdict | no |
| Approve | the reviewer accepts the change | counts toward required approvals, if a rule requires any |
| Request changes | the author should address feedback first | only if a rule requires a pull request |

GitHub's text on the third row: "The **Request changes** option is purely informational and will not prevent merging unless a ruleset or classic branch protection rule is configured with the 'require a pull request' option." When such a rule exists and the reviewer has write access, "the pull request cannot be merged until the same collaborator submits another review approving the changes" ([reviewing proposed changes](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/reviewing-proposed-changes-in-a-pull-request)). Without a rule, "changes requested" is a request, not a lock ([Chapter 18](ch18-branch-protection.md)).

Two more documented facts: anyone with read access can review and comment, and "pull request authors cannot approve their own pull requests" (same page), which is why the review labs need a second account.

**Suggestions.** A reviewer can propose replacement lines in a comment. When the author applies one suggestion or a batch, the documentation describes the resulting Git data exactly: it "creates a single commit on the compare branch of the pull request. Each person who suggested a change included in the commit will be a co-author of the commit. The person who applies the suggested changes will be a co-author and the committer of the commit" ([incorporating feedback](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/incorporating-feedback-in-your-pull-request)). That commit is made on GitHub's side. Your local branch lacks it until you `git pull`, and a push without pulling is rejected as a non-fast-forward.

**Closing keywords.** `Fixes #12` in the description closes the issue at merge time, but "only when the pull request targets the repository's *default* branch" ([linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)). A pull request into `release/1.0` will not close the issue (Chapter 15: GitHub).

**Automated reviewers.** Since 1 September 2026, in public preview and off by default, Copilot code review can submit an approving review that counts toward required approvals ([changelog](https://github.blog/changelog/2026-09-01-copilot-code-review-can-now-approve-pull-requests/)). When you design a review policy, count the humans.

## 17.5 Stale approvals, dismissal, and the most recent push

**In one sentence.** An approval is attached to the diff as it was when the reviewer approved; two optional settings decide what happens to that approval when the diff changes afterwards.

**The risk they address.** Without either setting, the sequence "approve, then push one more commit, then merge" lands a commit that nobody reviewed. GitHub's documentation calls this a pull request being "hijacked (where unapproved content is added to approved pull requests)".

**Setting 1: dismiss stale approvals.** "GitHub records the state of the diff at the point when a pull request is approved ... If the diff changes from this state (for example, because a contributor pushes new changes to the pull request branch or clicks **Update branch**, or because a related pull request is merged into the target branch), the approving review is dismissed as stale, and the pull request cannot be merged until someone approves the work again" ([available rules, pull request rule](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging)). Note the last cause: the diff can change without anyone touching your branch. The same page adds that approvals "will be dismissed as stale if the merge base introduces new changes after the review was submitted".

**Setting 2: require approval of the most recent reviewable push.** It requires "an approval from someone other than the last person to push to a branch". With this option "'stale' reviews are not dismissed, and the pull request remains approved as long as someone other than the person who made the most recent changes approves it". GitHub presents it as a compromise for large pull requests with many reviewers, and says which one is stricter: "it is safer to dismiss stale reviews."

The first costs a re-review after every update, including an "Update branch". The second can leave earlier approvals standing on a diff that has since changed.

**A side effect in Git terms.** With either setting, GitHub notes that "manually creating the merge commit for a pull request and pushing it directly to a protected branch will fail, unless the contents of the merge exactly match the merge generated by GitHub for the pull request". The server compares your merge with its own test merge.

**Manual dismissal.** People with write access can dismiss a review; "you must add a comment explaining why", and the review becomes a plain comment ([dismissing a review](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/dismissing-a-pull-request-review)). A ruleset can restrict who may do that (generally available in rulesets since 7 July 2026, [changelog](https://github.blog/changelog/2026-07-07-restrict-who-can-dismiss-reviews-in-rulesets/)).

**In production.** A team that rebases pull request branches and also dismisses stale approvals re-approves after every rebase. That is the control working as designed; name the cost when you propose the setting.

## 17.6 Checks, status checks and mergeability

**In one sentence.** Mergeability is two independent questions: can Git merge the two tips (the test merge), and do the repository's rules allow it (reviews, checks and the rest of Chapter 18).

**Two kinds of status checks.** GitHub distinguishes checks, which carry detailed output and are created by GitHub Apps including Actions, from commit statuses, a simpler state set through the API by external services. "GitHub Actions generates checks, not commit statuses" ([status checks](https://docs.github.com/en/pull-requests/reference/status-checks)). Both are attached to a commit ID, not to the pull request. A new push creates a new head commit with no checks yet.

**Which commit must be green.** "Required checks must pass on the latest commit SHA. Checks from earlier commits don't satisfy the requirement." And when the test merge commit has a status, that is the commit that must pass, which the merge box indicates with `Showing checks for the merge commit` ([troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)).

**What the API reports.** The `mergeable` field "can be true, false, or null. If the value is null, then GitHub has started a background job to compute the mergeability." When it is true, `merge_commit_sha` "will be the SHA of the test merge commit" ([REST: get a pull request](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)). A script that treats `null` as "not mergeable" is wrong; it must ask again.

**Optional is not required.** A red check blocks nothing by itself; only a rule that names the check does. Chapter 18, section 18.8 covers the traps of required checks, and Chapters 20A and 20B the workflows that produce them.

> **Unverified.** The status-checks page says checks data is retained for 400 days and that archived required checks must be re-run. A changelog entry states that from 1 October 2026 checks, workflow runs and statuses follow the Actions retention setting, 90 days by default and not retroactive ([changelog](https://github.blog/changelog/2026-08-27-actions-retention-will-cover-checks-workflow-runs-and-statuses/)). The Phase 0 report flags the two as conflicting. Practical consequence either way: an old pull request may need its checks re-run before it can merge.

## 17.7 Conflicts in a pull request

**In one sentence.** A pull request "has conflicts" when the test merge of head into base cannot be computed cleanly, and you repair it by changing the head branch, either by merging the base into it or by rebasing it onto the base.

**Precisely.** It is the ordinary three-way conflict of Chapter 8, detected on the server, where nobody can resolve it. The resolution has to arrive as new commits on the head branch. GitHub offers three routes ([merge conflicts](https://docs.github.com/en/pull-requests/reference/merge-conflicts)):

| Route | What it does to the head branch | Limits |
|---|---|---|
| The web conflict editor | "merges the entire base branch into the head branch" ([resolving on GitHub](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/resolving-a-merge-conflict-on-github)) | only "simple competing line change conflicts" |
| The command line | whatever you choose: a merge of the base, or a rebase | you need a clone and push access to the head branch |
| Copilot (**Fix with Copilot** in the merge box) | commits made by the agent | needs Copilot cloud agent ([changelog, 26 March 2026](https://github.blog/changelog/2026-03-26-ask-copilot-to-resolve-merge-conflicts-on-pull-requests/)); review the result like any resolution |

**See it.** Ravi's branch `fix/threshold` lowers the confidence threshold. Asha raised it on `main` in the meantime. The test merge:

<!-- snippet: ch17/pr-conflict/01-conflict -->
```text
# Ravi. His pull request fix/threshold -> main, and the test merge:
$ git log --oneline origin/main..fix/threshold
0e18437 Document how the threshold was tuned
be88439 Lower the confidence threshold to 0.65
$ git merge-tree --write-tree --name-only origin/main fix/threshold
e7f43627eaf0524ac48167b60df524db4bde078c
config/routing.yaml

Auto-merging config/routing.yaml
CONFLICT (content): Merge conflict in config/routing.yaml
[exit status: 1]
```
<!-- /snippet -->

**Repair 1: merge the base into the head.** This is what the web editor and the **Update branch** button do, and what `gh pr update-branch` does by default.

<!-- snippet: ch17/pr-conflict/02-merge-base-in -->
```text
# Repair 1: merge the base branch into the head branch.
$ git merge origin/main
Auto-merging config/routing.yaml
CONFLICT (content): Merge conflict in config/routing.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git diff
diff --cc config/routing.yaml
index 338a664,b97f8de..0000000
--- a/config/routing.yaml
+++ b/config/routing.yaml
@@@ -1,3 -1,3 +1,7 @@@
  model: router-small-v1
++<<<<<<< HEAD
 +confidence_threshold: 0.65
++=======
+ confidence_threshold: 0.7
++>>>>>>> origin/main
  fallback_queue: general
$ printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' > config/routing.yaml
$ git add config/routing.yaml
$ git commit -q -m "Merge main into fix/threshold"
$ git push
To ../../server/ticket-router.git
   0e18437..ce88db6  fix/threshold -> fix/threshold
```
<!-- /snippet -->

<!-- snippet: ch17/pr-conflict/03-after-merge -->
```text
$ git log --oneline --graph -5
*   ce88db6 Merge main into fix/threshold
|\  
| * 4b21efb Raise the confidence threshold to 0.7
* | 0e18437 Document how the threshold was tuned
* | be88439 Lower the confidence threshold to 0.65
|/  
* 9a383e5 Add classifier test
$ git log --oneline origin/main..fix/threshold
ce88db6 Merge main into fix/threshold
0e18437 Document how the threshold was tuned
be88439 Lower the confidence threshold to 0.65
$ git merge-tree --write-tree origin/main fix/threshold
47f5aab81203b78e95a028e97e22c7935c94b122
[exit status: 0]
```
<!-- /snippet -->

The push was a fast-forward: no force, nobody's clone of the branch is disturbed. The pull request now lists three commits, one of them a merge that carries the resolution.

**Repair 2: rebase the head onto the base.** In a second copy of the same situation:

<!-- snippet: ch17/pr-conflict/04-rebase -->
```text
# Repair 2, in a copy of the clone: rebase the head branch onto the base.
$ cd ../../rebase-copy/ravi/ticket-router
$ git rebase origin/main
Rebasing (1/2)
Auto-merging config/routing.yaml
CONFLICT (content): Merge conflict in config/routing.yaml
error: could not apply be88439... Lower the confidence threshold to 0.65
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply be88439... # Lower the confidence threshold to 0.65
[exit status: 1]
$ printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' > config/routing.yaml
$ git add config/routing.yaml
$ git rebase --continue
[detached HEAD e2639c7] Lower the confidence threshold to 0.65
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/threshold.
```
<!-- /snippet -->

<!-- snippet: ch17/pr-conflict/05-after-rebase -->
```text
$ git log --oneline --graph -5
* fd22cf1 Document how the threshold was tuned
* e2639c7 Lower the confidence threshold to 0.65
* 4b21efb Raise the confidence threshold to 0.7
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
$ git log --oneline origin/main..fix/threshold
fd22cf1 Document how the threshold was tuned
e2639c7 Lower the confidence threshold to 0.65
$ git push
To ../../server/ticket-router.git
 ! [rejected]        fix/threshold -> fix/threshold (non-fast-forward)
error: failed to push some refs to '../../server/ticket-router.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../../server/ticket-router.git
 + 0e18437...fd22cf1 fix/threshold -> fix/threshold (forced update)
```
<!-- /snippet -->

Two commits in a straight line, both new: `be88439` became `e2639c7`. History was rewritten, so the push needs `--force-with-lease` ([Chapter 12](ch12-remote-operations.md), section 12.8). The conflict was resolved inside the first commit; no commit records that it happened.

Both repairs give the reviewer the same diff:

<!-- snippet: ch17/pr-conflict/06-same-diff -->
```text
# Both repairs give reviewers the same three-dot diff:
$ git diff origin/main...fix/threshold
diff --git a/README.md b/README.md
index 98a45e9..d8990f5 100644
--- a/README.md
+++ b/README.md
@@ -1,3 +1,5 @@
 # ticket-router
 
 Sends each support ticket to the queue that can answer it.
+
+The threshold is tuned on the March ticket sample.
diff --git a/config/routing.yaml b/config/routing.yaml
index b97f8de..338a664 100644
--- a/config/routing.yaml
+++ b/config/routing.yaml
@@ -1,3 +1,3 @@
 model: router-small-v1
-confidence_threshold: 0.7
+confidence_threshold: 0.65
 fallback_queue: general
$ diff <(git -C ../../../ravi/ticket-router diff origin/main...fix/threshold) <(git diff origin/main...fix/threshold) && echo identical
identical
```
<!-- /snippet -->

| | Merge base into head | Rebase head onto base |
|---|---|---|
| Push | fast-forward | forced (`--force-with-lease`) |
| Existing commit IDs on the branch | kept | replaced |
| Where the resolution is visible | in the merge commit (`git show --remerge-diff`, Chapter 8, section 8.16) | folded into the rewritten commits |
| Commit list of the pull request | grows by a merge commit | stays clean |
| Stale-approval dismissal (17.5) | triggered, the diff changed | triggered, the diff changed |
| Final history on `main` after a squash merge | identical | identical |

The last row settles many arguments: under the squash method the shape of the branch disappears at merge time, so the cheaper merge is enough. Under the other two methods the shape lands on `main`, which is a reason to rebase.

> **GitHub, not Git.** `gh pr update-branch` "updates with a merge commit (i.e., merging the base branch into the PR's branch)" by default and rebases with `--rebase` (`gh pr update-branch --help`, 2.88.1). The REST endpoint behind the button describes itself as "merging HEAD from the base branch into the pull request branch" ([REST: update a pull request branch](https://docs.github.com/en/rest/pulls/pulls#update-a-pull-request-branch)). Either way the head branch on GitHub moves and your local branch does not: pull before you continue.

**In production.** Do not resolve conflicts in lock files (`uv.lock`) or other generated files by picking a side. Take the base version, regenerate with the tool, commit the result.

## 17.8 The three merge methods

**In one sentence.** The three merge buttons write three different histories for the same content: a merge commit that keeps your commits, one new commit that replaces them, or new copies of your commits in a straight line.

**Analogy.** Three ways to file a report written in drafts: staple the drafts into the folder with a cover note (merge commit), retype one clean page (squash), or retype every draft in order (rebase). The folder's content is the same; what you can prove later about the drafts is not. The analogy breaks because retyped pages in Git are new objects with new IDs, and every tool that tracked the old IDs has lost them.

**Precisely.** These are GitHub server-side operations. Their documented semantics ([pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)):

| | Create a merge commit | Squash and merge | Rebase and merge |
|---|---|---|---|
| Documented mechanics | "all commits from the feature branch are added to the base branch in a merge commit ... using the `--no-ff` option" | "the pull request's commits are squashed into a single commit", then merged "using the fast-forward option" | commits "are added onto the base branch individually without a merge commit" |
| New commits on the base | one merge commit | one commit | one per original commit |
| Your original commit IDs on the base | preserved | not present | not present: "always ... creates new commit SHAs" |
| Committer of what lands | your commits unchanged; the merge commit is committed by GitHub (see the note below) | committed by GitHub | "always updates the committer information" |
| Signature on what lands | your commits keep theirs; the merge commit is signed by GitHub ("GitHub will automatically use GPG to sign commits you make using the web interface") | "GitHub would sign the final squash commit" ([signed commits rule](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-signed-commits)) | none: added "without commit signature verification" |
| Linear history rule (Chapter 18) | not allowed | allowed | allowed (at most 100 commits, [limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits#rebase-limits)) |
| Documented loss | none | "You lose information about when specific changes were originally made and who authored the squashed commits" | originally empty commits are dropped |

On the committer: the Enterprise documentation for metadata rules says committer-email patterns "must also include `noreply@github.com` for web-based merges and other commits created on GitHub.com" ([metadata restrictions](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#metadata-restrictions)).

Why rebase and merge cannot be signed, in GitHub's words: "GitHub creates a modified commit ... GitHub didn't truly create this commit, and can't therefore sign it as a generic system user. GitHub doesn't have access to the committer's private signing keys." The documented workaround is "to rebase and merge locally, and then push". [Chapter 14B](ch14b-config-tags-signing.md), section 14B.17 showed the mechanism: a rewritten commit keeps its author and loses its signature.

> **Unverified.** Who is recorded as the *author* of a squash commit, and whether other contributors become `Co-authored-by` trailers, is not stated on the live documentation pages (the Phase 0 report flags it). The pages say only that an author email selector appears for squash merges "if you are the pull request author and you have more than one email address" ([merging a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-a-pull-request)). Lab 22.1 has you read the real commit and record what you find.

**See it.** One pull request, three copies of the repository, the three local commands that correspond to the buttons. Asha merges. Two differences from GitHub are visible: the committer here is Asha, where GitHub records itself, and nothing here is signed.

<!-- snippet: ch17/merge-methods/01-before -->
```text
# The same starting point in all three copies. Asha is the maintainer.
$ cd merge/asha
$ git log --graph --format="%h %an: %s" main origin/feature/priority-routing
* 9aa221a Asha Rao: Raise the confidence threshold to 0.7
| * 16d4788 Lab User: Fix the name of the escalations queue
| * 12ae95d Lab User: Route high-priority tickets to escalation
| * 44c1e7b Lab User: Add priority scoring
|/  
* 9a383e5 Asha Rao: Add classifier test
* f3e7ca9 Asha Rao: Add routing config
* 53e7f57 Asha Rao: Add keyword classifier
* fbbcc8d Asha Rao: Add README
```
<!-- /snippet -->

Method 1 is `git merge --no-ff` 🟡:

<!-- snippet: ch17/merge-methods/02-merge-commit -->
```text
# Method 1, "Create a merge commit":
$ git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing
Merge made by the 'ort' strategy.
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push -q origin main
$ git log --graph --format="%h %an / %cn: %s" -6
*   4c53f2e Asha Rao / Asha Rao: Merge pull request #1 from feature/priority-routing
|\  
| * 16d4788 Lab User / Lab User: Fix the name of the escalations queue
| * 12ae95d Lab User / Lab User: Route high-priority tickets to escalation
| * 44c1e7b Lab User / Lab User: Add priority scoring
* | 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
|/  
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
```
<!-- /snippet -->

Method 2 is `git merge --squash` 🟡 followed by an ordinary commit:

<!-- snippet: ch17/merge-methods/03-squash -->
```text
# Method 2, "Squash and merge":
$ cd ../../squash/asha
$ git merge --squash origin/feature/priority-routing
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
$ git push -q origin main
$ git log --graph --format="%h %an / %cn: %s" -3
* da48bba Asha Rao / Asha Rao: Route high-priority tickets to an escalations queue (#1)
* 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
$ git show --stat --format="%h parents: %p" HEAD
da48bba parents: 9aa221a

 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

Method 3 is `git rebase` 🟡 followed by a fast-forward:

<!-- snippet: ch17/merge-methods/04-rebase -->
```text
# Method 3, "Rebase and merge":
$ cd ../../rebase/asha
$ git switch -q -c pr-1 origin/feature/priority-routing
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/pr-1.
$ git switch -q main
$ git merge --ff-only pr-1
Updating 9aa221a..ec49c9c
Fast-forward
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push -q origin main
$ git log --graph --format="%h %an / %cn: %s" -5
* ec49c9c Lab User / Asha Rao: Fix the name of the escalations queue
* 2303f3a Lab User / Asha Rao: Route high-priority tickets to escalation
* dbb1f36 Lab User / Asha Rao: Add priority scoring
* 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
```
<!-- /snippet -->

What `main` gained in each copy, with author and committer:

<!-- snippet: ch17/merge-methods/05-what-main-gained -->
```text
# The feature commits as you wrote them:
$ git -C merge/you log --format="%h author=%an committer=%cn %s" main..feature/priority-routing
16d4788 author=Lab User committer=Lab User Fix the name of the escalations queue
12ae95d author=Lab User committer=Lab User Route high-priority tickets to escalation
44c1e7b author=Lab User committer=Lab User Add priority scoring
# What main gained in each copy (main@{1} is where main was before):
$ git -C merge/asha log --format="%h author=%an committer=%cn %s" main@{1}..main
4c53f2e author=Asha Rao committer=Asha Rao Merge pull request #1 from feature/priority-routing
16d4788 author=Lab User committer=Lab User Fix the name of the escalations queue
12ae95d author=Lab User committer=Lab User Route high-priority tickets to escalation
44c1e7b author=Lab User committer=Lab User Add priority scoring
$ git -C squash/asha log --format="%h author=%an committer=%cn %s" main@{1}..main
da48bba author=Asha Rao committer=Asha Rao Route high-priority tickets to an escalations queue (#1)
$ git -C rebase/asha log --format="%h author=%an committer=%cn %s" main@{1}..main
ec49c9c author=Lab User committer=Asha Rao Fix the name of the escalations queue
2303f3a author=Lab User committer=Asha Rao Route high-priority tickets to escalation
dbb1f36 author=Lab User committer=Asha Rao Add priority scoring
```
<!-- /snippet -->

Merge: your three commits arrive under their own IDs, plus `4c53f2e`. Squash: one commit, `da48bba`, and none of yours. Rebase: three commits with you as author, Asha as committer, and three new IDs (`dbb1f36`, `2303f3a`, `ec49c9c`).

And yet:

<!-- snippet: ch17/merge-methods/06-same-tree -->
```text
# Three histories, one result: the tree of main is identical.
$ git -C merge/asha rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git -C squash/asha rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git -C rebase/asha rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
```
<!-- /snippet -->

The tree of `main` is `beff5a6` in all three copies, the tree of the test merge in section 17.2. **The merge method does not change what the code is after the merge. It changes what the history says about how the code got there.**

**Picture.**

```text
  Create a merge commit                 Squash and merge              Rebase and merge

  ...9a383e5---9aa221a-------4c53f2e    ...9aa221a---da48bba          ...9aa221a---dbb1f36---2303f3a---ec49c9c
            \               /
             44c1e7b--12ae95d--16d4788   (44c1e7b, 12ae95d, 16d4788    (44c1e7b, 12ae95d, 16d4788
                                          stay on the old branch,       stay on the old branch,
                                          not on main)                  not on main)

  main keeps your IDs and adds one      main gets one new commit      main gets three new commits
```

**Two documented deviations of the rebase button.** GitHub's rebase and merge "deviates slightly from `git rebase`": it "always updates the committer information and creates new commit SHAs, whereas `git rebase` does not change the committer information when the rebase happens on top of an ancestor commit", and it "drops commits that were empty to begin with ... whereas `git rebase` keeps originally-empty commits by default". Local Git shows both halves. A branch that already sits on top of `main`, with one empty commit:

<!-- snippet: ch17/rebase-deviations/01-already-on-top -->
```text
# Asha, the maintainer. Nothing has landed on main since the branch was created:
$ git switch -q -c pr-1 origin/feature/priority-routing
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
a4deec5 author=Lab User committer=Lab User Trigger CI again
9dcfb58 author=Lab User committer=Lab User Fix the name of the escalations queue
02820ea author=Lab User committer=Lab User Route high-priority tickets to escalation
3807b29 author=Lab User committer=Lab User Add priority scoring
$ git rebase main
Current branch pr-1 is up to date.
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
a4deec5 author=Lab User committer=Lab User Trigger CI again
9dcfb58 author=Lab User committer=Lab User Fix the name of the escalations queue
02820ea author=Lab User committer=Lab User Route high-priority tickets to escalation
3807b29 author=Lab User committer=Lab User Add priority scoring
```
<!-- /snippet -->

Nothing rewritten. To imitate the button you must force new commits and ask for empty ones to be dropped:

<!-- snippet: ch17/rebase-deviations/02-force-new-commits -->
```text
# What the documentation describes for the button: always new commits, new committer.
$ git rebase --no-ff main
Current branch pr-1 is up to date, rebase forced.
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/pr-1.
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
123f252 author=Lab User committer=Asha Rao Trigger CI again
49f7387 author=Lab User committer=Asha Rao Fix the name of the escalations queue
9895c44 author=Lab User committer=Asha Rao Route high-priority tickets to escalation
216a2d1 author=Lab User committer=Asha Rao Add priority scoring
```
<!-- /snippet -->

<!-- snippet: ch17/rebase-deviations/03-drop-empty -->
```text
# And originally empty commits are dropped:
$ git rebase --no-ff --no-keep-empty main
Current branch pr-1 is up to date, rebase forced.
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/pr-1.
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
57537fc author=Lab User committer=Asha Rao Fix the name of the escalations queue
05bb2a6 author=Lab User committer=Asha Rao Route high-priority tickets to escalation
6da6459 author=Lab User committer=Asha Rao Add priority scoring
```
<!-- /snippet -->

So after "Rebase and merge" the commits on `main` are never the commits you pushed, even when no rebase seemed necessary.

| Operation (GitHub, at merge time) | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| Any of the three merge buttons 🟡 | your clone: unchanged | unchanged | unchanged | unchanged | unchanged until you fetch | the base branch gains: your commits and a merge commit (merge), one new commit (squash), or new copies of your commits (rebase). After squash and rebase your original commits are on no branch, still under `refs/pull/N/head` | pull request becomes `merged`; the head branch is deleted if the repository setting or the option says so |

A repository's settings decide which methods are offered, and a ruleset can restrict them per branch (Chapter 18, section 18.6). With a merge queue "you no longer get to choose the merge method, as this is controlled by the queue" ([about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github)).

## 17.9 What the method means later: bisect, blame, revert, traceability

**In one sentence.** The method decides which commits exist on `main`, and every later tool (bisect, blame, revert, an audit that follows a commit ID) works on those commits and no others.

**Is your work "on main"?** Ask Git whether your head commit is an ancestor of `main`:

<!-- snippet: ch17/merge-methods/08-ancestry -->
```text
# Is your original head commit an ancestor of main?
$ git -C merge/asha merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 0]
$ git -C squash/asha merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 1]
$ git -C rebase/asha merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 1]
```
<!-- /snippet -->

Only the merge commit made your commits ancestors of `main`. After the other two methods the content arrived and the commits did not. Four observations follow.

**Observation 1: `git branch -d` refuses.** The maintainer deletes the head branch on the server, and you update your clone:

<!-- snippet: ch17/merge-methods/11-you-update-merge -->
```text
# You, the contributor, after the merge. Copy 1 (merge commit):
$ cd merge/you
$ git pull --ff-only --prune
From ../server
 - [deleted]         (none)     -> origin/feature/priority-routing
   9aa221a..4c53f2e  main       -> origin/main
Updating 9aa221a..4c53f2e
Fast-forward
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git branch -vv
  feature/priority-routing 16d4788 [origin/feature/priority-routing: gone] Fix the name of the escalations queue
* main                     4c53f2e [origin/main] Merge pull request #1 from feature/priority-routing
$ git branch -d feature/priority-routing
Deleted branch feature/priority-routing (was 16d4788).
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch17/merge-methods/12-you-update-squash -->
```text
# Copy 2 (squash):
$ cd ../../squash/you
$ git pull -q --ff-only --prune
$ git branch -vv
  feature/priority-routing 16d4788 [origin/feature/priority-routing: gone] Fix the name of the escalations queue
* main                     da48bba [origin/main] Route high-priority tickets to an escalations queue (#1)
$ git branch -d feature/priority-routing
error: the branch 'feature/priority-routing' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/priority-routing'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

```text
Observed behavior : After a squash merge (or a rebase merge) on GitHub, git branch -d refuses to
                    delete the local branch: "not fully merged".
Git state         : The branch tip 16d4788 is not an ancestor of main. main has da48bba, a commit
                    with one parent and the same content.
Mechanism         : git branch -d deletes only when the branch is merged into its upstream, or
                    into HEAD when it has no upstream. "Merged" means reachable. The upstream is
                    gone (pruned), so Git compares with HEAD and finds three unreachable commits.
Root cause        : Squash and rebase merges transfer content without ancestry.
Why Git does this : -d exists to stop you from deleting the only ref to commits. Git cannot know
                    that another commit carries the same changes.
Correct fix       : Verify that nothing would be lost, then delete with git branch -D.
Prevention        : None needed. Expect it under these two methods, and verify before -D.
```

The Phase 0 report lists this refusal as an inference from the documented new commit IDs; the transcript confirms it for the local equivalents. Lab 22.1 shows the other half of the rule: while the remote-tracking branch still exists, `-d` deletes with a warning, because the branch is merged into its upstream.

To verify before `-D`: after a rebase merge `git cherry` marks every commit `-` (a patch-equivalent is on `main`). After a squash no single commit matches. A test that works for both asks whether merging the branch would change `main` at all:

<!-- snippet: ch17/merge-methods/14-safe-to-delete -->
```text
# Rebase copy: every commit of the branch has an equivalent patch on main ("-"):
$ git cherry -v main feature/priority-routing
- 44c1e7b21c49dd09f0df26e7f5aa147834faba31 Add priority scoring
- 12ae95d534559f98f9aa705ed852f5a4700f6edd Route high-priority tickets to escalation
- 16d4788572b31e17e4c3104a1d9861a5ce2c47ea Fix the name of the escalations queue
# Squash copy: no single commit on main matches a commit of the branch ("+"):
$ cd ../../squash/you
$ git cherry -v main feature/priority-routing
+ 44c1e7b21c49dd09f0df26e7f5aa147834faba31 Add priority scoring
+ 12ae95d534559f98f9aa705ed852f5a4700f6edd Route high-priority tickets to escalation
+ 16d4788572b31e17e4c3104a1d9861a5ce2c47ea Fix the name of the escalations queue
# A test that works for both: would merging the branch change main at all?
$ git merge-tree --write-tree main feature/priority-routing
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git branch -D feature/priority-routing
Deleted branch feature/priority-routing (was 16d4788).
```
<!-- /snippet -->

The merged tree equals the tree of `main`: the branch has nothing left to give. `git branch -D` 🔴 removes the only ref to those commits. What it changes: the branch ref and its reflog are deleted. What it can destroy: nothing at once; the commits stay in the object database and, if you ever had the branch checked out, in the reflog of `HEAD`, for the periods given in [Chapter 13](ch13-recovery.md). Preview: the tree comparison above. Recovery: `git branch <name> <id>`, with the ID that the command printed. When it is appropriate: after you have verified that the base contains the content.

**Observation 2: blame and log name different commits.**

<!-- snippet: ch17/merge-methods/10-blame -->
```text
# Who does blame name for the new lines of classify.py?
$ git -C merge/asha blame -s -L 1,3 router/classify.py
12ae95d5 1) from router.priority import priority
12ae95d5 2) 
16d47885 3) QUEUES = ["billing", "technical", "general", "escalations"]
$ git -C squash/asha blame -s -L 1,3 router/classify.py
da48bba7 1) from router.priority import priority
da48bba7 2) 
da48bba7 3) QUEUES = ["billing", "technical", "general", "escalations"]
$ git -C rebase/asha blame -s -L 1,3 router/classify.py
2303f3af 1) from router.priority import priority
2303f3af 2) 
ec49c9cf 3) QUEUES = ["billing", "technical", "general", "escalations"]
```
<!-- /snippet -->

After a squash every line points to one commit, `da48bba`; otherwise to the commit that introduced it (Chapter 14A, section 14A.18). Under squash the unit of history is the pull request, so the squash commit's message must link to it, as the `(#1)` in a default title does.

**Observation 3: untested commits can land.** The second commit of the branch used a wrong queue name and the third fixed it. Which commits on `main` contain the wrong name?

<!-- snippet: ch17/merge-methods/09-untested-states -->
```text
# The second feature commit used the queue name "escalation"; the third one fixed it.
# Which commits on main contain the wrong name?
$ for c in $(git -C merge/asha rev-list main@{1}..main); do git -C merge/asha grep -c "\"escalation\"" $c -- router/classify.py; done
12ae95d534559f98f9aa705ed852f5a4700f6edd:router/classify.py:2
$ for c in $(git -C squash/asha rev-list main@{1}..main); do git -C squash/asha grep -c "\"escalation\"" $c -- router/classify.py; done
$ for c in $(git -C rebase/asha rev-list main@{1}..main); do git -C rebase/asha grep -c "\"escalation\"" $c -- router/classify.py; done
2303f3af71f7e0db4e5fbc21dcae7d7ba299cf72:router/classify.py:2
```
<!-- /snippet -->

Under merge and rebase, `main` contains a commit whose tree has the bug. CI tested the final result, not each commit, and `git bisect` can stop on that intermediate commit. `git bisect start --first-parent` treats a merged pull request as one step (Chapter 14A, section 14A.22); for the rebase method no flag helps, and every commit has to pass on its own. Squash removes the problem and the granularity with it.

**Observation 4: reverting is three different operations.**

<!-- snippet: ch17/merge-methods/15-revert-merge -->
```text
# Undoing the pull request on main. Copy 1: one revert, and you must name the mainline.
$ cd ../../merge/you
$ git revert --no-edit -m 1 HEAD
[main 4e8155e] Revert "Merge pull request #1 from feature/priority-routing"
 Date: Mon Sep 7 11:34:00 2026 +0530
 2 files changed, 1 insertion(+), 11 deletions(-)
 delete mode 100644 router/priority.py
$ git log --oneline -2
4e8155e Revert "Merge pull request #1 from feature/priority-routing"
4c53f2e Merge pull request #1 from feature/priority-routing
```
<!-- /snippet -->

<!-- snippet: ch17/merge-methods/16-revert-squash -->
```text
# Copy 2: one ordinary revert.
$ cd ../../squash/you
$ git revert --no-edit HEAD
[main 09f2610] Revert "Route high-priority tickets to an escalations queue (#1)"
 Date: Mon Sep 7 11:37:00 2026 +0530
 2 files changed, 1 insertion(+), 11 deletions(-)
 delete mode 100644 router/priority.py
$ git log --oneline -2
09f2610 Revert "Route high-priority tickets to an escalations queue (#1)"
da48bba Route high-priority tickets to an escalations queue (#1)
```
<!-- /snippet -->

<!-- snippet: ch17/merge-methods/17-revert-rebase -->
```text
# Copy 3: one revert per commit, and you must know where the pull request began.
$ cd ../../rebase/you
$ git revert --no-edit HEAD~3..HEAD
[main d1270df] Revert "Fix the name of the escalations queue"
 Date: Mon Sep 7 11:40:00 2026 +0530
 1 file changed, 2 insertions(+), 2 deletions(-)
[main 7e41c05] Revert "Route high-priority tickets to escalation"
 Date: Mon Sep 7 11:40:00 2026 +0530
 1 file changed, 1 insertion(+), 5 deletions(-)
[main 7335fb5] Revert "Add priority scoring"
 Date: Mon Sep 7 11:40:00 2026 +0530
 1 file changed, 6 deletions(-)
 delete mode 100644 router/priority.py
$ git log --oneline -4
7335fb5 Revert "Add priority scoring"
7e41c05 Revert "Route high-priority tickets to escalation"
d1270df Revert "Fix the name of the escalations queue"
ec49c9c Fix the name of the escalations queue
```
<!-- /snippet -->

A merge commit needs `-m 1` and carries the trap of Chapter 8, section 8.18: re-merging the branch brings nothing back until you revert the revert. A squash commit reverts like any commit. A rebased series has no marker of where the pull request began. On GitHub, the **Revert** button and `gh pr revert` create "a new pull request that reverts the original merge commit" ([reverting a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/reverting-a-pull-request)).

**Summary.** No method is best. Each one buys something and pays for it.

| Concern | Merge commit | Squash | Rebase |
|---|---|---|---|
| Commit IDs reviewed = commit IDs on `main` | yes | no | no |
| Bisect granularity | commit, or pull request with `--first-parent` | pull request | commit |
| Revert | one command, `-m 1`, re-merge trap | one command | one per commit |
| Reusing the branch afterwards | safe | old commits listed again, conflicts (17.12) | the same, but a plain `git rebase` skips the old commits |

Contexts: merge commits where the reviewed commit IDs must be the deployed ones (audits, signed-commit policies, long-lived branches merged repeatedly); squash where pull requests are small and short-lived and commit hygiene inside a branch is not enforced; rebase where the team curates every commit, wants a linear history, and does not require signatures on the target. Chapter 27: Open source and team workflows returns to the choice.

## 17.10 Auto-merge

**In one sentence.** Auto-merge is a stored instruction on a pull request: merge with this method as soon as every requirement is met.

**Precisely.** "Auto-merge merges a pull request automatically after all required reviews and status checks pass." It must first be enabled for the repository, and the option "is shown only on pull requests that cannot be merged immediately", that is, when a rule has an unmet requirement. People with write permission can enable it; they and the author can disable it. One safety property is documented: "Auto-merge is disabled if someone without write permissions pushes new changes to the head branch or switches the base branch" ([automatically merging a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/automatically-merging-a-pull-request)). Availability: public repositories on GitHub Free, public and private on paid plans ([managing auto-merge](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-auto-merge-for-pull-requests-in-your-repository)).

```bash
gh repo edit OWNER/REPO --enable-auto-merge       # repository setting, once
gh pr merge 12 --auto --squash                    # merge when the requirements are met
gh pr merge 12 --disable-auto                     # withdraw the instruction
```

**What can go wrong.** Auto-merge waits for *required* things only. In a repository with no required checks and no required reviews there is nothing to wait for. The documentation names one event that switches auto-merge off, a push by someone without write permission. For a commit pushed by someone with write permission after the approval, whether it merges unreviewed is therefore decided by the stale-approval settings of section 17.5 and not by auto-merge. Decide those settings before you allow auto-merge on a branch that deploys.

> **Outdated advice.** The comment command `@dependabot merge` was removed on 27 January 2026 ([changelog](https://github.blog/changelog/2026-01-27-changes-to-github-dependabot-pull-request-comment-commands/)). The current mechanism is auto-merge.

## 17.11 Merge queue and the `merge_group` event

**In one sentence.** A merge queue merges pull requests one group at a time and runs the required checks on the exact commit that will become the new tip of the base branch.

**The problem it solves.** Without "strict" required checks, two pull requests can each be green against an older `main` and break `main` together (Chapter 8, section 8.15). With them, every merge makes all other pull requests out of date: "a race-to-merge situation that impacts developer productivity" ([repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits)).

**Precisely.** "A merge queue creates temporary branches with a special prefix to validate pull request changes ... the changes in the pull request are grouped into a `merge_group` with the latest version of the `base_branch` as well as changes from pull requests ahead of it in the queue." The temporary branches begin with `gh-readonly-queue/{base_branch}` and "contain a different `sha` from the pull request". If a group fails its checks or conflicts, "the pull request will be removed from the queue", and the branches behind it are recreated without it ([managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)).

**See it.** The idea in plain Git, with three approved one-commit pull requests. The branch prefix is the documented one; the rest is my imitation.

<!-- snippet: ch17/merge-queue/02-queue-builds -->
```text
# The queue, in order 1, 2, 3. Each temporary branch contains main and everything ahead of it:
$ git switch -q -c gh-readonly-queue/main/pr-1 main
$ git merge -q --no-ff -m "Merge pull request #1" pr-1
$ git switch -q -c gh-readonly-queue/main/pr-2
$ git merge -q --no-ff -m "Merge pull request #2" pr-2
$ git switch -q -c gh-readonly-queue/main/pr-3
$ git merge -q --no-ff -m "Merge pull request #3" pr-3
$ git log --oneline --graph main..gh-readonly-queue/main/pr-3
*   0569767 Merge pull request #3
|\  
| * 6c162ef Describe how to run the tests
*   7c2fd05 Merge pull request #2
|\  
| * 1621dd9 Lower the confidence threshold to 0.65
* 2b79f02 Merge pull request #1
* 8c7493d Accept tickets without a subject
```
<!-- /snippet -->

<!-- snippet: ch17/merge-queue/03-different-ids -->
```text
# The commits that the checks must test are none of the pull request heads:
$ git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/pr-* refs/heads/gh-readonly-queue
2b79f02 gh-readonly-queue/main/pr-1
7c2fd05 gh-readonly-queue/main/pr-2
0569767 gh-readonly-queue/main/pr-3
8c7493d pr-1
1621dd9 pr-2
6c162ef pr-3
```
<!-- /snippet -->

The checks must run on `2b79f02`, `7c2fd05` and `0569767`, commits that no contributor created and no `pull_request` run ever saw. Pull request 2 fails:

<!-- snippet: ch17/merge-queue/04-entry-fails -->
```text
# The checks fail on the group of pull request 2. It leaves the queue; number 3 is rebuilt:
$ git branch -q -D gh-readonly-queue/main/pr-2
$ git switch -q -C gh-readonly-queue/main/pr-3 gh-readonly-queue/main/pr-1
$ git merge -q --no-ff -m "Merge pull request #3" pr-3
$ git log --oneline --graph main..gh-readonly-queue/main/pr-3
*   3bda42c Merge pull request #3
|\  
| * 6c162ef Describe how to run the tests
* 2b79f02 Merge pull request #1
* 8c7493d Accept tickets without a subject
```
<!-- /snippet -->

The entry for pull request 3 is a different commit now (`3bda42c`, not `0569767`) and must be tested again. When it passes, the base branch moves to the tested commit:

<!-- snippet: ch17/merge-queue/05-land -->
```text
# The checks pass. The base branch moves to the tested commit, unchanged:
$ git switch -q main
$ git merge --ff-only gh-readonly-queue/main/pr-3
Updating 9a383e5..3bda42c
Fast-forward
 README.md          | 2 ++
 router/classify.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git log --oneline --first-parent -3
3bda42c Merge pull request #3
2b79f02 Merge pull request #1
9a383e5 Add classifier test
```
<!-- /snippet -->

**The trap.** Checks on queue branches are triggered by their own event. "You **must** use the `merge_group` event to trigger your GitHub Actions workflow when a pull request is added to a merge queue ... Otherwise, status checks will not be triggered ... The merge will fail as the required status check will not be reported." The fix is one more trigger:

```yaml
on:
  pull_request:
  merge_group:
```

Chapter 20A covers the event. Also documented: the queue fixes the merge method; `gh pr merge` on such a branch adds the pull request to the queue when the checks have passed and otherwise enables auto-merge, and `--admin` bypasses the queue (`gh pr merge --help`).

**Availability.** "Pull request merge queues are available in any public repository owned by an organization, or in private repositories owned by organizations using GitHub Enterprise Cloud" (same page), so not under a personal account.

> **Unverified.** The merge-queue *ruleset rule* appears only in the Enterprise Cloud view of the documentation. The Phase 0 report could not confirm whether a Free or Team organization can enable the queue through a ruleset or only through a classic rule.

**When not to use it.** A queue adds a CI run per group and latency per merge. For a few merges a day, "strict" required checks cost less.

## 17.12 Why a pull request shows unexpected commits or a huge diff

**In one sentence.** The page shows `base..head` and `base...head`; when it shows too much, either the head contains commits that the base does not reach, or the base is not the branch the work started from.

GitHub documents five causes. The first two can be reproduced in plain Git.

| Documented cause | What you see | Mechanism |
|---|---|---|
| The head branch was reused after a squash merge | commits that were "already squashed" listed again; repeated conflicts | the squash commit has no parent link to the branch, so the merge base never moved |
| Wrong or changed base branch | every commit of the branch the work was really based on | the range is taken against a base that does not contain those commits |
| The base branch moved | pull request page and compare page disagree | they "can calculate changed files from different merge bases" |
| Rewritten or force-pushed history | old and new copies of commits, outdated review comments | "Force pushing rewrites repository history and can ... corrupt pull requests" |
| The diff is truncated or hidden | files missing from "Files changed" | diff limits (17.18), or a `.gitattributes` rule hiding the file |

Sources: [pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges#squashing-and-merging-a-long-running-branch), [changing the base branch](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/changing-the-base-branch-of-a-pull-request), [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#differences-between-commits-on-compare-and-pull-request-pages), [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#avoid-force-pushes), [branches reference](https://docs.github.com/en/pull-requests/reference/branches#comparing-branches-in-pull-requests).

### Squash, then reuse the branch

Pull request 1 was squash-merged. Nobody deleted its branch.

<!-- snippet: ch17/squash-reuse/01-after-squash -->
```text
# Pull request 1 was squash-merged. Its branch was not deleted.
$ git log --oneline --graph origin/main feature/priority-routing
* 1b2b8ed Route high-priority tickets to an escalations queue (#1)
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

You make one small follow-up commit on the old branch, push, and open pull request 2. What it lists, what its diff shows, and what you actually changed:

<!-- snippet: ch17/squash-reuse/03-pr2-commits -->
```text
# Pull request 2, same head branch, same base. Its commit list:
$ git log --oneline origin/main..feature/priority-routing
fa6e912 Treat data loss as urgent
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
# Its diff (three dots), and what you believe you changed (your last commit):
$ git diff --stat origin/main...feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
$ git show --stat --format="%h %s" HEAD
fa6e912 Treat data loss as urgent

 router/priority.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Four commits and two files for a one-line change. And the test merge:

<!-- snippet: ch17/squash-reuse/04-pr2-test-merge -->
```text
# The test merge of pull request 2:
$ git merge-tree --write-tree --name-only origin/main feature/priority-routing
55b98ddb581c6463837afef116da1f66dd495a8a
router/priority.py

Auto-merging router/priority.py
CONFLICT (add/add): Merge conflict in router/priority.py
[exit status: 1]
```
<!-- /snippet -->

A conflict in a file that only you ever edited.

<!-- snippet: ch17/squash-reuse/05-why -->
```text
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
9a383e5 Add classifier test
$ git show -s --format="%h parents: %p  %s" origin/main
1b2b8ed parents: 9aa221a  Route high-priority tickets to an escalations queue (#1)
```
<!-- /snippet -->

```text
Observed behavior : Pull request 2 lists the three commits of pull request 1 again, shows their
                    changes again, and conflicts with main in router/priority.py.
Git state         : merge-base(main, branch) is still 9a383e5, the original fork point.
                    main's tip 1b2b8ed has one parent, 9aa221a.
Mechanism         : The squash commit copied the content of the branch and recorded no link to it.
                    For Git, 44c1e7b, 12ae95d and 16d4788 were never merged. base..head lists them.
                    The three-way merge sees "both sides added router/priority.py since 9a383e5,
                    with different content": an add/add conflict.
Root cause        : Content merged without ancestry (Chapter 8, section 8.12), then more work on top
                    of the old ancestry.
Why Git does this : The merge base comes from parent links only. Git never compares patches to
                    guess that a commit "is already there".
Correct fix       : Transplant the new commits onto main: git rebase --onto origin/main <last squashed commit>.
Prevention        : Delete the head branch after a squash or rebase merge and start new work from
                    main. Enable automatic deletion of head branches in the repository.
```

GitHub's page says the same: "If you keep working on the same head branch after a squash merge, later pull requests can include commits that were already squashed into the base branch", and advises "using a merge commit or rebasing the branch before opening the next pull request".

**Way out 1: move only what is new.** `git rebase --onto` 🟡 ([Chapter 9](ch09-rebase.md)) takes the commits after `HEAD~1` and replays them on `main`:

<!-- snippet: ch17/squash-reuse/06-fix-rebase-onto -->
```text
# Way out 1: move only the new commit onto main. Everything up to HEAD~1 is already there.
$ git rebase --onto origin/main HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/priority-routing.
$ git log --oneline origin/main..feature/priority-routing
e73426a Treat data loss as urgent
$ git diff --stat origin/main...feature/priority-routing
 router/priority.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git merge-tree --write-tree origin/main feature/priority-routing
084c79329c5ababb96ff69fb77466efba04e1ca0
[exit status: 0]
$ git push --force-with-lease
To ../../server/ticket-router.git
 + fa6e912...e73426a feature/priority-routing -> feature/priority-routing (forced update)
```
<!-- /snippet -->

One commit, one file, a clean test merge, and a forced push. A plain `git rebase origin/main` is not the same thing. It replays all four commits and relies on Git to notice the duplicates:

<!-- snippet: ch17/squash-reuse/07-plain-rebase -->
```text
# In a copy of the clone: a plain rebase replays all four commits.
$ cd ../../you-plain-rebase/ticket-router
$ git rebase origin/main
Rebasing (1/4)
dropping 44c1e7b21c49dd09f0df26e7f5aa147834faba31 Add priority scoring -- patch contents already upstream
Rebasing (2/4)
Auto-merging router/classify.py
CONFLICT (content): Merge conflict in router/classify.py
error: could not apply 12ae95d... Route high-priority tickets to escalation
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 12ae95d... # Route high-priority tickets to escalation
[exit status: 1]
$ git status --short
UU router/classify.py
$ git rebase --abort
```
<!-- /snippet -->

Git dropped the first commit because replaying it changed nothing. The second conflicts, because the squash already contains the third commit's fix of the same line.

**Way out 2: merge `main` into the branch.** One conflict, resolved once, and the merge base moves:

<!-- snippet: ch17/squash-reuse/08-merge-main -->
```text
# In another copy. Way out 2: merge main into the branch and resolve once.
$ cd ../../you-merge/ticket-router
$ git merge origin/main
Auto-merging router/priority.py
CONFLICT (add/add): Merge conflict in router/priority.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# The branch has everything main has plus the new word, so the branch side is the answer:
$ git restore --ours router/priority.py
$ git add router/priority.py
$ git commit -q -m "Merge main into feature/priority-routing"
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
1b2b8ed Route high-priority tickets to an escalations queue (#1)
$ git diff --stat origin/main...feature/priority-routing
 router/priority.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline origin/main..feature/priority-routing
2710851 Merge main into feature/priority-routing
fa6e912 Treat data loss as urgent
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
```
<!-- /snippet -->

The diff is correct now. The commit list still shows five commits, which does not matter if the pull request is squash-merged.

**Way out 3**, the prevention: a new branch from `main` for every pull request, and automatic deletion of head branches ([documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches)), set by `gh repo edit --delete-branch-on-merge`.

### A pull request against the wrong base

Ravi created `fix/empty-subject` from `main`, by habit. The fix is meant for the release branch, so he opened the pull request with base `release/1.0`:

<!-- snippet: ch17/wrong-base/01-situation -->
```text
# Ravi. One commit of his own, on a branch he created from main:
$ git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject
* a1ae0eb Accept tickets without a subject
* 29be88c Describe how to run the tests
* 7e13c3d Raise the confidence threshold to 0.7
| * bc944fd Set version 1.0.0
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

<!-- snippet: ch17/wrong-base/02-pr-against-release -->
```text
# The pull request was opened with base release/1.0. What it lists and shows:
$ git log --oneline origin/release/1.0..fix/empty-subject
a1ae0eb Accept tickets without a subject
29be88c Describe how to run the tests
7e13c3d Raise the confidence threshold to 0.7
$ git diff --stat origin/release/1.0...fix/empty-subject
 README.md           | 2 ++
 config/routing.yaml | 2 +-
 router/classify.py  | 2 +-
 3 files changed, 4 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

Three commits and three files for a one-line fix. The two extra commits are `main`'s, and merging would carry unreleased work into the release branch. In a real repository this is the pull request with hundreds of unrelated changes. Ask which base makes the branch small:

<!-- snippet: ch17/wrong-base/03-diagnose -->
```text
# Which base makes this branch a one-commit pull request?
$ for b in origin/main origin/release/1.0; do echo "$b: $(git rev-list --count $b..fix/empty-subject) commits"; done
origin/main: 1 commits
origin/release/1.0: 3 commits
$ git log --oneline -1 $(git merge-base origin/release/1.0 fix/empty-subject)
9a383e5 Add classifier test
$ git log --oneline -1 $(git merge-base origin/main fix/empty-subject)
29be88c Describe how to run the tests
```
<!-- /snippet -->

There are two repairs, and they are not interchangeable.

**Fix A: the base is wrong.** If the change belongs on `main`, change the base of the pull request (`gh pr edit --base main`, or **Edit title** next to the title and then the base branch menu, as the documentation describes). The same branch is then a one-commit pull request:

<!-- snippet: ch17/wrong-base/04-fix-a-change-base -->
```text
# Fix A: the change belongs on main after all. Same branch, other base:
$ git log --oneline origin/main..fix/empty-subject
a1ae0eb Accept tickets without a subject
$ git diff --stat origin/main...fix/empty-subject
 router/classify.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

GitHub warns about the side effect: "When you change the base branch of your pull request, some commits may be removed from the timeline. Review comments may also become outdated" ([changing the base branch](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/changing-the-base-branch-of-a-pull-request)).

**Fix B: the base is right and the branch started in the wrong place.** Transplant the one commit:

<!-- snippet: ch17/wrong-base/05-fix-b-transplant -->
```text
# Fix B: the change does belong on release/1.0. Move the one commit there:
$ git rebase --onto origin/release/1.0 origin/main fix/empty-subject
Rebasing (1/1)
Successfully rebased and updated refs/heads/fix/empty-subject.
$ git log --oneline origin/release/1.0..fix/empty-subject
5c46029 Accept tickets without a subject
$ git diff --stat origin/release/1.0...fix/empty-subject
 router/classify.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject
* 5c46029 Accept tickets without a subject
* bc944fd Set version 1.0.0
| * 29be88c Describe how to run the tests
| * 7e13c3d Raise the confidence threshold to 0.7
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

The command reads "take the commits of `fix/empty-subject` that are not on `origin/main` and replay them on `origin/release/1.0`". A plain `git rebase origin/release/1.0` would replay all three commits and change nothing about the pull request except the commit IDs (Lab 21.2).

**Prevention.** `gh pr create` uses the default branch as base unless you pass `--base` (section 17.16). Run `git log --oneline <base>..HEAD` first.

### The other three causes

**The base moved.** Nothing is wrong; if the pull request page and a compare page must agree, update the branch (17.7). **Force-pushed history.** Review comments on the old commits become outdated; and if someone force-pushes the *base* branch, every open pull request against it lists the removed commits. Block force pushes on shared branches (Chapter 18). **Truncated or hidden diffs.** The file changed and the page does not render it; `git diff --stat base...head` on your machine has no such limit.

## 17.13 Indirect merges

**In one sentence.** GitHub marks a pull request as merged whenever its head commits become reachable from its base branch, by whatever route that happened.

**Precisely.** "A pull request can be marked as merged if its head branch commits become reachable from the base branch outside that pull request. This can happen when the same commits are merged through another pull request or pushed directly to the default branch ... Pull requests merged indirectly are marked as `merged` even if branch protection rules on that pull request were not satisfied" ([indirect merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges#indirect-merges)).

**See it.** Two branches where the upper one contains the lower one. Asha merges the *upper* pull request with a merge commit. The reachability test for the lower one:

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

Exit status 0, and `main..origin/feature/priority-routing` is empty: every commit of the lower pull request is on `main`. Nobody pressed its merge button, and whatever review it still lacked was never given.

**Why it matters.** Reviews and checks are properties of a pull request; reachability is a property of commits. A rule that requires an approval is satisfied by the pull request that was actually merged, not by each pull request whose commits it contained. When an audit asks who approved a commit, answer from the pull request that carried it onto the base.

## 17.14 Stacked pull requests

**In one sentence.** A stack is a chain of pull requests in one repository in which each targets the branch of the one below, so that a large change is reviewed as small layers.

> **Version note.** Older behavior: dependent pull requests were a convention maintained by hand. Current behavior: a GitHub feature in **public preview**, with the CLI extension `github/gh-stack`. Since: 30 July 2026 ([changelog](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/), [reference](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests)). Recommended: learn the plain-Git mechanics below first. `gh stack` is not part of `gh` 2.88.1 and none of its commands were run for this book.

**Why the base decides what you see.** Two layers, both pushed:

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

Against `main`, the upper pull request lists both layers, which is the wrong-base case of section 17.12. Against the branch below, it lists its own two commits.

**What GitHub adds**, from the reference page:

- All branches must be in the same repository: "Cross-fork stacks are not supported."
- "Every pull request in a stack is evaluated against rules for the **base of the stack**", typically `main`: required reviews, required status checks, CODEOWNERS and code scanning. Workflows trigger "as if each pull request in the stack targets the base of the stack".
- A pull request can merge only when it and "all pull requests below it" meet the requirements, and when "the stack has a **fully linear history** between its branches".
- The asynchronous merge API, generally available since 1 October 2026, "is the only merge API that supports stacked pull requests" ([changelog](https://github.blog/changelog/2026-10-01-github-async-merge-api-generally-available/)).

**Linear, in Git terms**, means the lower branch is an ancestor of the upper one:

<!-- snippet: ch17/stacked/03-linear -->
```text
# Linear stack: the lower branch is an ancestor of the upper one.
$ git merge-base --is-ancestor feature/priority-routing feature/sla-timers
[exit status: 0]
```
<!-- /snippet -->

A review fix on the lower branch breaks that:

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

The upper branch still sits on the old tip. The repair is a rebase of the upper layer onto the new tip of the lower one, and a forced push of the rewritten branch:

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

With more layers this cascades, which `gh stack rebase` and the **Rebase stack** button automate; the button's commits "are **not** signed" ([managing stacked pull requests](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/managing-stacked-pull-requests)). In plain Git, `git rebase --update-refs` moves every branch of the chain in one run (Chapter 9, section 9.9).

**When the bottom layer is squash-merged**, the upper layer is in the squash-then-reuse situation of section 17.12, because it was built on commits that never reached `main`:

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

The stack feature does this for you: "the remaining branches are automatically rebased so the next pull request targets the default base branch" ([about stacked pull requests](https://docs.github.com/en/pull-requests/get-started/about-stacked-prs)). Without it, GitHub only retargets: when a merged head branch is deleted, pull requests based on it switch to the merged pull request's base ([merging a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-a-pull-request)). The transplant is then yours to do.

**When not to stack.** Layers that are not dependent should be independent pull requests. A stack multiplies force pushes and re-approvals, and a problem in the bottom layer delays every layer above.

## 17.15 The fork workflow end to end

**In one sentence.** In the fork-and-pull model you push to a repository you own and ask the upstream repository to take the commits; the pull request lives in the upstream repository.

**Precisely.** Chapter 12, section 12.10 built the triangular configuration: `origin` is your fork, `upstream` the shared repository. This section adds the pull request. Platform facts first ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#fork-and-pull-model), [forks reference](https://docs.github.com/en/pull-requests/reference/forks)):

- "You do not need permission from the upstream repository to push to a fork you created."
- "A fork and its upstream share the same Git data. This means that all content uploaded to a fork is accessible from the upstream and all other forks of that upstream."
- The author can let maintainers push to the pull request branch. That works only for forks owned by a user: "You cannot give push permissions to a fork owned by an organization" ([allowing changes to a pull request branch](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/allowing-changes-to-a-pull-request-branch-created-from-a-fork)).
- For workflows triggered by a pull request from a fork, "secrets are not passed to the runner" except `GITHUB_TOKEN`, which "has read-only permissions" ([events, workflows in forked repositories](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflows-in-forked-repositories)). Chapter 21A: GitHub Actions security explains why, and what `pull_request_target` changes.

**Picture.**

```text
   upstream: example-org/ticket-router  (Asha maintains)           your fork: you/ticket-router
  +--------------------------------------+   (1) fork             +------------------------------+
  | refs/heads/main                      | ---------------------> | refs/heads/main              |
  | refs/pull/7/head   <-----------------+-- (5) pull request --- | refs/heads/fix/empty-subject |
  +--------------------------------------+                        +------------------------------+
        |            ^                                                  ^            |
        | (3) fetch  | (7) merge by a maintainer                        | (4) push   | (2) clone
        | upstream   |                                                  | origin     |
        v            |                                                  |            v
  +-----------------------------------------------------------------------------------------+
  | your clone:  origin = your fork, upstream = the shared repository                        |
  |   main, fix/empty-subject         (6) review round trips: fetch, commit, push            |
  |   (8) after the merge: fetch upstream, fast-forward main, push main to origin            |
  +-----------------------------------------------------------------------------------------+
```

**See it.** Your fork is one commit behind upstream. Count before you branch:

<!-- snippet: ch17/fork-workflow/01-remotes -->
```text
# Your clone of your fork. origin is the fork, upstream is the shared repository.
$ git remote -v
origin	../../forks/you/ticket-router.git (fetch)
origin	../../forks/you/ticket-router.git (push)
upstream	../../server/ticket-router.git (fetch)
upstream	../../server/ticket-router.git (push)
$ git fetch upstream
From ../../server/ticket-router
 * [new branch]      main       -> upstream/main
# Commits only upstream has (left) and only your fork has (right):
$ git rev-list --left-right --count upstream/main...origin/main
1	0
```
<!-- /snippet -->

`1 0`: upstream has one commit your fork lacks. Start the branch from `upstream/main`, not from the fork's stale `main`:

<!-- snippet: ch17/fork-workflow/02-branch-from-upstream -->
```text
# Start from the current upstream, not from the stale main of the fork:
$ git switch -c fix/empty-subject --no-track upstream/main
Switched to a new branch 'fix/empty-subject'
$ git commit -q -am "Accept tickets without a subject"
$ git push -u origin fix/empty-subject
To ../../forks/you/ticket-router.git
 * [new branch]      fix/empty-subject -> fix/empty-subject
branch 'fix/empty-subject' set up to track 'origin/fix/empty-subject'.
```
<!-- /snippet -->

`--no-track` keeps the branch from adopting `upstream/main` as its upstream; `git push -u origin` sets the fork's branch instead. Opening the pull request puts the head commit into the upstream repository. Imitated on the bare upstream:

<!-- snippet: ch17/fork-workflow/03-pr-ref-upstream -->
```text
# In the upstream repository. Opening pull request 7 from you:fix/empty-subject, as Git data:
$ git fetch -q ../../forks/you/ticket-router.git fix/empty-subject:refs/pull/7/head
$ git for-each-ref --format="%(objectname:short) %(refname)"
01822ed refs/heads/main
0c6455c refs/pull/7/head
# The commit is now stored in upstream, on no branch of upstream:
$ git cat-file -t refs/pull/7/head
commit
$ git branch --contains refs/pull/7/head
```
<!-- /snippet -->

The commit is stored in upstream, on none of its branches. A maintainer fetches it, adds a test, and pushes to *your* branch in *your* fork, which the maintainer-edit permission allows:

<!-- snippet: ch17/fork-workflow/04-maintainer-checks-out -->
```text
# Asha, a maintainer of upstream, takes the pull request into her clone:
$ git fetch origin pull/7/head:pr-7
From ../../server/ticket-router
 * [new ref]         refs/pull/7/head -> pr-7
$ git switch -q pr-7
$ git log --oneline main..pr-7
0c6455c Accept tickets without a subject
```
<!-- /snippet -->

<!-- snippet: ch17/fork-workflow/05-maintainer-edits -->
```text
# She adds a test and pushes it to YOUR branch in YOUR fork (you allowed maintainer edits):
$ printf '\n\ndef test_ticket_without_subject():\n    assert classify({}) == "general"\n' >> tests/test_classify.py
$ git commit -q -am "Test a ticket without a subject"
$ git push ../../forks/you/ticket-router.git pr-7:fix/empty-subject
To ../../forks/you/ticket-router.git
   0c6455c..ef0b9f0  pr-7 -> fix/empty-subject
```
<!-- /snippet -->

Your branch moved without you. Pull before you add anything:

<!-- snippet: ch17/fork-workflow/06-you-pull -->
```text
# You. Your branch in the fork moved without you:
$ git pull
From ../../forks/you/ticket-router
   0c6455c..ef0b9f0  fix/empty-subject -> origin/fix/empty-subject
Updating 0c6455c..ef0b9f0
Fast-forward
 tests/test_classify.py | 4 ++++
 1 file changed, 4 insertions(+)
$ git log --format="%h %an: %s" upstream/main..fix/empty-subject
ef0b9f0 Asha Rao: Test a ticket without a subject
0c6455c Lab User: Accept tickets without a subject
```
<!-- /snippet -->

Asha merges. Then the step that beginners skip, bringing clone and fork back in line with upstream:

<!-- snippet: ch17/fork-workflow/08-sync -->
```text
# You. Bring your clone and your fork up to date with upstream:
$ git switch -q main
$ git fetch upstream
From ../../server/ticket-router
   01822ed..fafe8b6  main       -> upstream/main
$ git merge --ff-only upstream/main
Updating 9a383e5..fafe8b6
Fast-forward
 config/routing.yaml    | 2 +-
 router/classify.py     | 2 +-
 tests/test_classify.py | 4 ++++
 3 files changed, 6 insertions(+), 2 deletions(-)
$ git push origin main
To ../../forks/you/ticket-router.git
   9a383e5..fafe8b6  main -> main
$ git rev-list --left-right --count upstream/main...origin/main
0	0
```
<!-- /snippet -->

<!-- snippet: ch17/fork-workflow/09-clean-up -->
```text
$ git branch -d fix/empty-subject
Deleted branch fix/empty-subject (was ef0b9f0).
$ git push origin --delete fix/empty-subject
To ../../forks/you/ticket-router.git
 - [deleted]         fix/empty-subject
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
  remotes/upstream/HEAD -> upstream/main
  remotes/upstream/main
```
<!-- /snippet -->

`0 0`: fork and upstream agree. On GitHub the same sync is **Sync fork** or `gh repo sync`, which fast-forwards and, with `--force`, hard-resets the fork's branch (`gh repo sync --help`). If you committed on the fork's `main`, `--force` discards those commits. Lab 21.1 has you make that mistake and recover.

**Three rules.** Never commit on the fork's default branch. Branch from `upstream/main` after a fetch. One branch per pull request, deleted after the merge.

## 17.16 `gh pr`: the commands

**In one sentence.** `gh pr` drives the pull request object from the terminal; the Git work around it stays with `git`.

Every command and flag below was checked against `gh <command> --help` of the installed CLI, 2.88.1. None was run against GitHub here. Run them in your normal shell, not in `labs/shell`.

```bash
# Create
gh pr create --base main --title "Accept tickets without a subject" --body "Fixes #12"
gh pr create --draft --fill                 # title and body from the commits; opens as a draft
gh pr create --dry-run                      # print what would be created (may still push)

# Inspect
gh pr status
gh pr list --state open --base main
gh pr view 12 --json baseRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision
gh pr diff 12 --name-only
gh pr checks 12 --required                  # exit status 8 while checks are pending

# Review and iterate
gh pr checkout 12                           # local branch for the head of pull request 12
gh pr review 12 --approve                   # or --request-changes / --comment, with --body
gh pr ready 12                              # draft -> ready;  --undo goes back
gh pr edit 12 --base main                   # change the base branch
gh pr update-branch 12                      # merge the base into the head; --rebase to rebase

# Finish
gh pr merge 12 --squash --delete-branch
gh pr merge 12 --merge --match-head-commit "$(git rev-parse HEAD)"
gh pr merge 12 --auto --rebase
gh pr close 12 --comment "Superseded by #15" --delete-branch
gh pr revert 12
```

What the help text itself tells you:

- `gh pr create` takes the base from `--base`, else from the Git configuration value `branch.<current>.gh-merge-base`, else the default branch. Maintainers may push to the head branch by default; `--no-maintainer-edit` disables that.
- `--match-head-commit` merges only if the head is the given commit: the terminal's answer to the hijack problem of section 17.5.
- `gh pr merge --admin` 🔴 uses "administrator privileges to merge a pull request that does not meet requirements". What it changes: the base branch, without the required reviews or checks. Preview: `gh pr checks --required`. Recovery: `gh pr revert`. Appropriate: a documented emergency, by someone the bypass list names (Chapter 18).
- The JSON field names are those of the [current manual](https://cli.github.com/manual/gh_pr_view), which describes the newest CLI (2.102.0 on 1 October 2026).

## 17.17 Review practice

**In one sentence.** A review is a claim about a specific diff at a specific commit, so a good reviewer controls which diff and which commit they looked at.

This section is practice derived from the mechanics above, not GitHub documentation.

**As an author.** Keep the pull request small; GitHub's own guidance is that merging soon "encourages contributors to make pull requests smaller, which we recommend in general" ([branches reference](https://docs.github.com/en/pull-requests/reference/branches#merging-often)). Check `git log --oneline origin/main..HEAD` before you open it. Say what you tested: for an ML change, which evaluation set, which metric, which commit. Once review has started, add commits instead of rewriting; if you must rewrite, say so and keep the content change separate from the rebase.

**As a reviewer.** For anything risky, run the code: `gh pr checkout 12`, then the tests. After a force push, compare the old and new series with `git range-diff` ([Chapter 9](ch09-rebase.md), section 9.14). Approve the commit you read: `--match-head-commit` on the command line, "dismiss stale approvals" in a ruleset. Give changes under `.github/workflows/`, to `CODEOWNERS`, to lock files and to deployment code a second reader; [Chapter 19](ch19-codeowners.md) turns that habit into a rule. Treat an automated approval as a signal about the diff, not about the intent.

**What a review cannot see.** Semantic conflicts with other open pull requests, files hidden by diff limits, and anything the test merge did not include. Checks on the merged result catch those, which is the argument for "strict" checks or a merge queue.

## 17.18 Display limits

**In one sentence.** GitHub truncates large pull requests; the Git data is complete, the page is not.

The documented limits ([repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits)):

| What | Limit |
|---|---|
| Total diff of a pull request | 20,000 lines that you can load, or 1 MB of raw diff |
| One file's diff | 20,000 loadable lines or 500 KB; 400 lines and 20 KB load automatically |
| Files in one diff | 300 (25 for renderable files such as images) |
| Commits listed on compare and pull request pages | 250, with a note that more exist |
| "Rebase and merge" | 100 commits |
| Recommended maximums | 1,000 open pull requests against one branch; 1 merged pull request per minute |

Beyond a limit, review locally: `git diff --stat base...head` has no ceiling. A pull request that hits these limits is usually a case of section 17.12, or a generated file that should not be in the diff.

> **Version note.** Older behavior: the classic "Files changed" page. Current behavior: a redesigned page is the default. Since: 22 January 2026 ([changelog](https://github.blog/changelog/2026-01-22-improved-pull-request-files-changed-page-on-by-default/)). Recommended: distrust older screenshots. Whether the classic opt-out still exists on 1 October 2026 is not confirmed in the Phase 0 report.

## 17.19 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| The pull request lists commits you did not write | `git log --oneline <base>..<head>`; `git merge-base` | change the base, or `git rebase --onto` (17.12) | check the range before opening |
| Old commits reappear after a squash merge | the merge base is the old fork point | `git rebase --onto origin/main <last squashed commit>` | delete head branches on merge |
| No CI run on the pull request | a conflict (no test merge), a draft, or a workflow filter | resolve the conflict; Chapter 20B | update the branch early |
| CI green, `main` red after the merge | the test merge used an older base (17.2) | fix forward or revert | strict checks or a merge queue |
| "Changes requested", yet the merge button works | no rule requires a pull request (17.4) | add the rule (Chapter 18) | know which controls are advisory |
| `git branch -d` says "not fully merged" | squash or rebase method (17.9) | verify with `merge-tree`, then `-D` | expected |
| A pull request is "merged" that nobody merged | indirect merge (17.13) | review what landed | do not merge branches that contain unreviewed pull requests |
| Fork cannot be synced | commits on the fork's default branch | move them to a branch (Lab 21.1) | never commit there |

## 17.20 When not to use it, and dangerous edge cases

- **A pull request is not a durable record.** It is a GitHub object, in no clone, and it does not move to another host with the repository. Put the "why" into commit messages or files as well.
- **Anything pushed to a pull request is published.** Deleting the branch does not remove the commits (17.2).
- **Commit IDs are not stable evidence under squash and rebase.** If compliance needs "the reviewed commit is the deployed commit", only the merge-commit method satisfies it literally.
- **Rebase and merge discards signatures** and cannot satisfy a rule that requires signed commits on the base (Chapter 18, section 18.10).
- **`--admin`, bypass lists and indirect merges** are three ways a change reaches a protected branch without the reviews the rules describe. Know all three before you tell an auditor that every change was reviewed.
- **Do not gate a deployment on `refs/pull/N/merge`.** It can be stale. Gate on a check that ran on the commit that landed.
- **Stacked pull requests are a preview.** Do not make a release process depend on them.

## 17.21 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git fetch origin pull/N/head:pr-N` | 🟢 SAFE | adds objects and a local branch | `git ls-remote origin 'refs/pull/*'` | `git branch -D pr-N` |
| `git log base..head`, `git diff base...head`, `git merge-tree --write-tree` | 🟢 SAFE | nothing (merge-tree adds unreferenced objects) | not needed | not needed |
| `gh pr create` | 🟡 CAUTION | may push the branch; creates a GitHub object that notifies people | `--dry-run` | `gh pr close` |
| `git merge --no-ff`, `git merge --squash`, `git rebase`, `git rebase --onto` | 🟡 CAUTION | move or rewrite the current branch | `git merge-tree`; `git log <upstream>..HEAD` | `ORIG_HEAD`, the reflog, `git rebase --abort` |
| `git push --force-with-lease` | 🔴 DANGEROUS | replaces the remote branch if it is where you last saw it; can destroy commits on the server that no clone of yours has, and alone the check passes wrongly after a background fetch ([Chapter 12](ch12-remote-operations.md), section 12.8) | add `--dry-run`; `git log HEAD..origin/<branch>` after a fetch | push the old ID back from a reflog; appropriate for your own pull request branch after a rebase |
| `gh pr update-branch`, `gh pr edit --base`, `gh pr merge` | 🟡 CAUTION | move the head branch, change the base, or write to the base branch; can dismiss approvals | `gh pr view`, `gh pr checks --required` | change the base back; `gh pr revert` |
| `gh pr merge --admin` | 🔴 DANGEROUS | merges without the required reviews and checks | as above | `gh pr revert`; record the reason |
| `git push --force` to a shared base branch | 🔴 DANGEROUS | removes commits from the remote branch; corrupts open pull requests | `git log <branch>..origin/<branch>` | [Chapter 13](ch13-recovery.md); Chapter 30: Incident response |
| `git branch -D` | 🔴 DANGEROUS | deletes a ref and its reflog | the tree comparison of 17.9 | `git branch <name> <id>` |
| `gh repo sync --force` | 🔴 DANGEROUS | hard-resets a branch of the fork | `git rev-list --left-right --count upstream/main...origin/main` | push the old commits back from a clone that has them |

## 17.22 Version notes

| Topic | Older behavior | Current behavior | Since | Recommended |
|---|---|---|---|---|
| Test merge commits | also regenerated on page view | on push, on merge-base change, or when older than 12 hours | 19 Feb 2026 | do not rely on a fresh `refs/pull/N/merge` |
| Draft pull requests | paid plans for private repositories | all repositories | 1 May 2025 | use drafts freely |
| Stacked pull requests | manual convention | public preview, `github/gh-stack` | 30 Jul 2026 | learn the Git mechanics first |
| Programmatic merge | synchronous `PUT .../merge` | asynchronous merge API recommended; the synchronous one supports neither stacks nor merge queues | 1 Oct 2026 | new automation uses the asynchronous endpoint |
| Copilot as reviewer | comments only | can approve (preview, off by default) | 1 Sep 2026 | decide whether such approvals count |
| Pull request access | always open | a repository can disable pull requests or limit them to collaborators ([changelog](https://github.blog/changelog/2026-02-13-new-repository-settings-for-configuring-pull-request-access/)) | 13 Feb 2026 | know the setting exists |
| Documentation URLs | `/pull-requests/collaborating-with-pull-requests/...` | `/pull-requests/reference/...` and `/pull-requests/how-tos/...` | 2025 to 2026 | cite the new paths |

## 17.23 Practice

Each lab has a local part with real transcripts and a GitHub part in your practice organization.

- [Module 21 labs](../lab-manual/m21-pull-requests-forks.md): Lab 21.1, a full fork and pull request cycle; Lab 21.2, a pull request against the wrong base; Lab 21.3, the squash-then-reuse problem.
- [Module 22 labs](../lab-manual/m22-merge-methods-releases.md): Lab 22.1, the three merge methods compared; Lab 22.2, a release from an annotated tag.
- Replay any transcript of this chapter with `labs/run`, for example `labs/run ch17/merge-methods`.
- Then read [Chapter 18: Branch Protection and Rulesets](ch18-branch-protection.md), which turns the advisory controls of this chapter into enforced ones.

## 17.24 Interview questions

1. What exactly does GitHub create when a pull request is opened? Which parts are Git data, and in which repository do they live?
2. A pull request for a one-line change lists forty commits. Give three causes and the command that distinguishes them.
3. Why does a pull request show a three-dot diff and not a two-dot diff? Construct a case in which they differ.
4. CI passed on the pull request and failed on `main` right after the merge. Which commit did CI test, and what closes that gap?
5. Compare the three merge methods for a team that requires signed commits on `main` and must show an auditor that the reviewed commit is the deployed commit.
6. After "Squash and merge", `git branch -d` refuses to delete the local branch. Explain the refusal from the definition of "merged", and show how to verify that deleting is safe.
7. A reviewer approved, the author pushed another commit, and the pull request merged. Which two settings address this, and what does each cost?
8. What does a merge queue test that a `pull_request` workflow does not? Why can a required check stay unreported forever on a queue?
9. A pull request is shown as merged, yet nobody merged it and it had no approval. How is that possible?
10. Your fork's `main` cannot be fast-forwarded to upstream. What happened, how do you keep the stray work, and why is `gh repo sync --force` the wrong first move?
11. A contributor leaked a key in a pull request and deleted the branch. Is the commit gone?
12. You are asked to pick one merge method for a 40-person ML platform team. What do you ask before answering?

## 17.25 Sources

**Primary sources** (docs.github.com, the GitHub Changelog and cli.github.com; read on 1 and 2 October 2026)

- Reference pages: [Pull requests](https://docs.github.com/en/pull-requests/reference/pull-requests), [Branches](https://docs.github.com/en/pull-requests/reference/branches), [Pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [Pull request reviews](https://docs.github.com/en/pull-requests/reference/pull-request-reviews), [Status checks](https://docs.github.com/en/pull-requests/reference/status-checks), [Merge conflicts](https://docs.github.com/en/pull-requests/reference/merge-conflicts), [Forks](https://docs.github.com/en/pull-requests/reference/forks), [Stacked pull requests](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests)
- How-to pages: [Checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally), [Merging a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-a-pull-request), [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork); the others are linked where they are quoted.
- Repository pages: [About merge methods on GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [Managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue), [Repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits), [About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), [REST API endpoints for pull requests](https://docs.github.com/en/rest/pulls/pulls), [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- Changelog entries, linked where they are used: 19 February 2026 (test merge commits), 30 July 2026 (stacked pull requests), 1 October 2026 (asynchronous merge API).
- GitHub CLI: `gh pr --help` and its subcommands (2.88.1, local); [gh pr manual](https://cli.github.com/manual/gh_pr).
- Git 2.55 manual pages: `git help merge-tree`, `git help rebase`, `git help branch`, `git help cherry`, `git help config` (`receive.hideRefs`); the [gitfaq](https://git-scm.com/docs/gitfaq) entry on squash merges and long-lived branches.

**Secondary sources**

- The Phase 0 report of this course, sections 2, 3, 12 and 13, and its notes on the GitHub platform.
- GitHub Engineering, [Scaling merge-ort across GitHub](https://github.blog/engineering/infrastructure/scaling-merge-ort-across-github/) (2023): why a server needs a merge without a working tree.

**Videos** (from the Phase 0 report, with its caveats)

- ["The ultimate beginner's guide to GitHub in 2026"](https://www.youtube.com/watch?v=NUELGzIHT-I), GitHub, 22 September 2025: the pull request and merge chapters, 40:44 to 47:14. Mechanics only; compiled from 2024 episodes. The report found no verified video that teaches code review end to end in the 2026 interface.

**Further reading**

- [Chapter 8: Merge](ch08-merge.md), sections 8.12, 8.15 and 8.17; [Chapter 9: Rebase](ch09-rebase.md), sections 9.9 and 9.14; [Chapter 12: Remote Operations](ch12-remote-operations.md), sections 12.8, 12.10 and 12.12; [Chapter 14A: History investigation](ch14a-history-investigation.md), sections 14A.2, 14A.8, 14A.18 and 14A.22.
- [Pro Git, "Contributing to a Project"](https://git-scm.com/book/en/v2/GitHub-Contributing-to-a-Project): the fork-and-pull flow at a book's pace; its screenshots predate the current interface.

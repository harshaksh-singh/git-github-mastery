# V127: The fork workflow end to end, review practice, and display limits

- **Part.** 5: GitHub
- **Module.** 21, 34
- **Planned minutes.** 22
- **Prerequisites.** V043, V116, V126
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), sections 17.15, 17.17 and 17.18
- **Demo scripts.** `labs/ch17/fork-workflow.sh`; GitHub-side walkthrough of Lab 21.1, the complete cycle

## HOOK

**[ON SCREEN]** "This branch is 3 commits ahead, 41 commits behind." — on the `main` of a fork.

A contributor's third pull request to an open-source evaluation library shows eleven commits. She wrote one. The maintainer asks her to clean it up. She opens her fork and finds that its `main` is three commits ahead of upstream and forty-one behind. She never meant to commit on `main`. The page offers to sync, and a search result suggests `gh repo sync --force`.

A colleague who has done this before stops her: what happens to the three commits if you do that?

They are discarded. This video walks the fork workflow from end to end, so that the fork's `main` never gets into that state, and shows how to keep the stray work when it does.

## INTRODUCTION

You already have every piece of this. In the remotes videos you built the triangular configuration: `origin` is your fork, `upstream` the shared repository. In V116 you saw what a fork is on the platform. In the last four videos you learned what a pull request is. This video puts the pieces in order, as one cycle with eight steps.

Then two short sections that close the pull request module. Section 17.17, review practice: this is practice derived from the mechanics of the chapter, not GitHub documentation, and I present it as such. And section 17.18, the display limits of large pull requests.

One replay, `labs/ch17/fork-workflow.sh`, in which bare repositories on disk play upstream and your fork. Then the complete cycle of Lab 21.1 as a walkthrough, with a second account or a teammate.

Labels: `git merge --ff-only` is 🟡 CAUTION as a branch-moving command, and `git switch -c` is 🟢 SAFE: it adds a ref; `git push origin --delete` removes a remote branch; `git branch -D` and `gh repo sync --force` are 🔴 DANGEROUS in the chapter's table. I give the five answers for `gh repo sync --force` in the concept section, and I do not run it.

## LEARNING OBJECTIVES

After this video you can:

- Name the three repositories of the fork workflow and the remotes in the contributor's clone.
- Take a change from upstream to fork to branch to pull request and back.
- Fetch and check out a contributor's pull request as a maintainer, and push to it when allowed.
- Keep the fork's default branch in sync without merge commits.
- Apply the review practices of section 17.17 to a pull request.

## CONCEPT

In one sentence: in the fork-and-pull model you push to a repository you own and ask the upstream repository to take the commits; the pull request lives in the upstream repository.

Three repositories. Upstream, which a maintainer controls. Your fork, on the platform, which you control. And your clone, on your machine, with two remotes: `origin` is your fork, `upstream` is the shared repository.

Platform facts first, from GitHub's reference pages. "You do not need permission from the upstream repository to push to a fork you created." A fork and its upstream share the same Git data, which you saw in V116. The author can let maintainers push to the pull request branch; that works only for forks owned by a user: "You cannot give push permissions to a fork owned by an organization." And for workflows triggered by a pull request from a fork, "secrets are not passed to the runner" except `GITHUB_TOKEN`, which "has read-only permissions". The Actions security videos explain why.

**[ON SCREEN]** Three rules.

The section ends with three rules, and the whole workflow follows from them. Never commit on the fork's default branch. Branch from `upstream/main` after a fetch. One branch per pull request, deleted after the merge.

Why the first rule? The fork's `main` has one job: to be a copy of upstream's `main`. As long as it has no commits of its own, syncing it is a fast-forward, and a fast-forward cannot lose anything. The moment you commit there, a fast-forward is impossible, and every way of syncing either creates a merge commit on your fork's `main`, which then shows up in every later pull request, or discards your commits.

That is where the 🔴 command comes in. `gh repo sync` fast-forwards the fork's branch, and with `--force` it hard-resets it. The five answers. What it changes: a branch of the fork. What it can destroy: commits on that branch that upstream does not have. How to preview: `git rev-list --left-right --count upstream/main...origin/main`, which counts what each side has alone. How to recover: push the old commits back from a clone that still has them. When it is appropriate: when the fork's branch is meant to be an exact copy of its parent, which means after you have moved any stray work to a branch.

Review practice. In one sentence: a review is a claim about a specific diff at a specific commit, so a good reviewer controls which diff and which commit they looked at.

As an author. Keep the pull request small. Check `git log --oneline origin/main..HEAD` before you open it. Say what you tested: for an ML change, which evaluation set, which metric, which commit. Once review has started, add commits instead of rewriting; if you must rewrite, say so, and keep the content change separate from the rebase.

As a reviewer. For anything risky, run the code: `gh pr checkout`, then the tests. After a force push, compare the old and new series with `git range-diff`. Approve the commit you read. Give changes under `.github/workflows/`, to `CODEOWNERS`, to lock files and to deployment code a second reader. And treat an automated approval as a signal about the diff, not about the intent.

What a review cannot see: semantic conflicts with other open pull requests, files hidden by diff limits, and anything the test merge did not include. Checks on the merged result catch those.

Display limits. In one sentence: GitHub truncates large pull requests; the Git data is complete, the page is not.

**[ON SCREEN]** The table of section 17.18.

The total diff of a pull request: 20,000 lines that you can load, or 1 MB of raw diff. One file's diff: 20,000 loadable lines or 500 KB; 400 lines and 20 KB load automatically. Files in one diff: 300. Commits listed on compare and pull request pages: 250, with a note that more exist. "Rebase and merge": 100 commits. Beyond a limit, review locally: `git diff --stat base...head` has no ceiling. A pull request that hits these limits is usually one of the cases from V125, or a generated file that should not be in the diff.

A version note: a redesigned "Files changed" page is the default since 22 January 2026. Distrust older screenshots. Whether the classic opt-out still exists is not confirmed in the course's research.

## MENTAL MODEL

Think of the fork as your outbox on the platform. You do not write letters in the outbox; you write them at your desk, the clone, each on its own sheet, a branch. You put one sheet into the outbox and ask the recipient to take it. The outbox also holds a copy of the recipient's current rulebook, the fork's `main`, and you never write in that copy; you only replace it with the newer edition.

The model breaks at one point, and you know it from V116: a real outbox is yours alone. A fork shares its Git data with the whole network. What you put there is published, and stays reachable through upstream.

## DIAGRAM

**[DIAGRAM]** Three boxes and eight numbered steps. Draw the boxes first, then add the steps in order.

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

One: fork. Two: clone the fork. Three: fetch upstream, because the fork may already be behind. Four: push your branch to `origin`, the fork. Five: the pull request. Look at where the arrow lands: in the upstream box, as `refs/pull/7/head`. The pull request lives upstream, and so does a ref to your commit. Six: review round trips, in your clone. Seven: a maintainer merges. Eight: fetch upstream, fast-forward your `main`, push `main` to the fork.

Step eight is the one beginners skip.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch17/fork-workflow
```

```bash
git remote -v
git fetch upstream
git rev-list --left-right --count upstream/main...origin/main
```

**[PAUSE]** The count prints two numbers: commits only upstream has, and commits only your fork has. For a healthy fork that is merely behind, what must the second number be?

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

Zero. Here: one and zero. Upstream has one commit your fork lacks, and the fork has nothing of its own.

Start the branch from `upstream/main`, not from the fork's stale `main`.

```bash
git switch -c fix/empty-subject --no-track upstream/main
git commit -q -am "Accept tickets without a subject"
git push -u origin fix/empty-subject
```

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

`--no-track` keeps the branch from adopting `upstream/main` as its upstream; `git push -u origin` sets the fork's branch as the upstream branch. You could not push to upstream anyway.

Opening the pull request puts the head commit into the upstream repository. Imitated on the bare upstream:

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

The commit is now stored in upstream, under `refs/pull/7/head`, on none of upstream's branches.

Now the maintainer's side. Asha takes the pull request into her clone.

```bash
git fetch origin pull/7/head:pr-7
git switch -q pr-7
git log --oneline main..pr-7
```

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

That is what `gh pr checkout 7` does for her.

**[PAUSE]** She adds a test. Where can she push it so that it becomes part of your pull request?

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

To your branch in your fork, which the maintainer-edit permission allows. Not to `refs/pull/7/head`: that ref is read-only.

```bash
git pull
git log --format="%h %an: %s" upstream/main..fix/empty-subject
```

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

Your branch moved without you. Pull before you add anything. The log shows two authors on your pull request.

<!-- snippet: ch17/fork-workflow/07-merge -->
```text
# Asha merges pull request 7 with a merge commit and publishes main:
$ git switch -q main
$ git fetch -q origin pull/7/head
$ git merge -q --no-ff -m "Merge pull request #7 from you/fix/empty-subject" FETCH_HEAD
$ git push -q origin main
$ git log --oneline --graph -4
*   fafe8b6 Merge pull request #7 from you/fix/empty-subject
|\  
| * ef0b9f0 Test a ticket without a subject
| * 0c6455c Accept tickets without a subject
|/  
* 01822ed Raise the confidence threshold to 0.7
```
<!-- /snippet -->

Asha merges into upstream's `main`.

Now step eight.

```bash
git switch -q main
git fetch upstream
git merge --ff-only upstream/main
git push origin main
git rev-list --left-right --count upstream/main...origin/main
```

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

`--ff-only` is the safety: if your `main` had commits of its own, this command would refuse, and you would know at once. It fast-forwards. Push `main` to the fork, and the count is zero and zero: fork and upstream agree. On GitHub the same sync is the fork's sync control or `gh repo sync` without `--force`.

```bash
git branch -d fix/empty-subject
git push origin --delete fix/empty-subject
git branch -a
```

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

One branch per pull request, deleted after the merge, locally and in the fork.

**[ON SCREEN]** GitHub walkthrough: the complete cycle of Lab 21.1, with a second account or a teammate as the maintainer. The interface changes; the lab text and the documentation pages cited in section 17.15 are the reference. No output is shown.

Fork a practice repository that the second account owns; you saw where the fork relation is displayed in V116. Clone the fork and add the second remote. Then follow the eight steps. Open the pull request from your fork's branch against the upstream repository; on the form, the documentation describes a setting that allows edits by maintainers. From the maintainer's account:

```bash
gh pr checkout 1
```

Review, merge. Back in your clone, do step eight by hand, with the commands from the replay, before you try the platform's sync control:

```bash
git fetch upstream
git merge --ff-only upstream/main
git push origin main
gh repo sync
```

At each step, say which ref moved in which of the three repositories. That sentence is the objective of the lab.

## COMMON MISTAKES

1. Committing on the fork's default branch. Root cause: that branch can then no longer be fast-forwarded to upstream, and every later pull request from a branch based on it carries the stray commits.
2. Branching from the fork's `main` without fetching upstream. Root cause: the fork's `main` is as old as the last sync; the pull request range is taken against upstream.
3. Running `gh repo sync --force` to fix a fork that is ahead. Root cause: with `--force` the sync is a hard reset and discards the commits upstream does not have.
4. Pushing to a pull request branch after a maintainer edited it, without pulling. Root cause: the branch in your fork moved; your push is a non-fast-forward.
5. Approving a large pull request from the web page alone. Root cause: the page truncates beyond its display limits; the Git data is complete and `git diff --stat base...head` has no ceiling.

## PRODUCTION EXAMPLE

The contributor from the hook, repaired without losing anything. The count says three and forty-one: her fork's `main` has three commits upstream lacks. First she keeps them: a new branch at the current `main`, so the three commits have a name. Then her local `main` is set back to match `upstream/main`, and pushed to the fork; because the fork's `main` is being moved backwards, that push is forced, on a branch only she uses, after the stray work is safe on its own branch. Now the count is zero and zero. The three commits live on a branch, from which she can open a proper pull request or cherry-pick what she wants.

Lab 21.1 has you make exactly this mistake and recover. Had she run `gh repo sync --force` first, the three commits would have been gone from the fork, recoverable only from a clone that still had them.

The maintainer's side of the same project follows section 17.17: for a change to the scoring code, check out the pull request and run the evaluation; after the contributor's force push, compare old and new with `git range-diff`; and ask the author which evaluation set, which metric and which commit the numbers in the description refer to.

## PRACTICE EXERCISE

Do Lab 21.1, "A full fork and pull request cycle", in [`lab-manual/m21-pull-requests-forks.md`](../../lab-manual/m21-pull-requests-forks.md), the complete cycle. The local part runs in the lab shell with three repositories; then repeat it on GitHub with a second account or a teammate. At every step, before you run it, say which ref will move in which repository. Before the failure scenario, predict what `git merge --ff-only upstream/main` will say.

The challenge is Exercise 21.5, "The fork that cannot be synced", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 266 of the CTO question bank:

> "Your fork's `main` cannot be fast-forwarded to upstream. What happened, how do you keep the stray work, and why is `gh repo sync --force` the wrong first move?"

A strong answer states the condition under which a fast-forward is impossible and how to measure it. It gives the order of the repair, with the step that makes the stray commits safe before anything is reset. It says exactly what the forced sync does to the branch, and it ends with the rule that prevents the situation.

## RECAP

You should now be able to say:

- Three repositories: upstream, your fork, your clone, with `origin` for the fork and `upstream` for the shared repository.
- Branch from `upstream/main` after a fetch, push to `origin`, open the pull request against upstream, where it lives as `refs/pull/N/head`.
- A maintainer fetches the pull request ref and, if allowed, pushes to your branch in your fork.
- After the merge: fetch upstream, fast-forward `main`, push it to the fork; never commit on the fork's `main`.
- A review is a claim about a diff at a commit; beyond the display limits, review with Git.

## HOMEWORK

Read sections 17.15, 17.17 and 17.18 of [Chapter 17](../../textbook/ch17-pull-requests.md).

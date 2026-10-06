# V129: What the merge method means later: bisect, blame, revert and traceability; auto-merge; the merge queue

- **Part.** 5: GitHub
- **Module.** 22
- **Planned minutes.** 24
- **Prerequisites.** V049, V070, V071, V128
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), sections 17.9 to 17.11
- **Demo scripts.** `labs/ch17/merge-methods.sh` (snippets 09 to 17), `labs/ch17/merge-queue.sh`

## HOOK

**[ON SCREEN]** "Queued 2 days ago. Required check: Expected — Waiting for status to be reported."

A team turns on a merge queue for `main` on a Friday. On Monday there are eleven pull requests in the queue and none has merged. Every one shows the same line: a required check, expected, waiting for status to be reported. The same check is green on every pull request.

Your CTO asks: the check passed. What is the queue waiting for?

For a result on a commit that no pull request run ever saw. The queue tests a different commit from the one the pull request tested, and the workflow was never told to run there. This video explains which commit, and why one extra line in the workflow fixes it. Before that, it finishes the story of the three merge methods: what each one costs you weeks later.

## INTRODUCTION

In the last video you saw what each merge method writes at merge time. This video is about what happens afterwards, in three parts.

Part one, section 17.9: bisect, blame, revert and traceability under each method, and what your own clone looks like after the merge. The replay is the second half of `labs/ch17/merge-methods.sh`, in the same three copies as last time.

Part two, section 17.10: auto-merge, a stored instruction on a pull request.

Part three, section 17.11: the merge queue, with `labs/ch17/merge-queue.sh`. In that replay the branch prefix is the documented one; the rest is the textbook author's imitation in plain Git. Auto-merge and the queue are described from the documentation, with their availability conditions; the queue is not walked through on GitHub.

Labels: `git revert` is 🟡 CAUTION: it adds a commit and rewrites nothing, and it moves the current branch and updates the index and the working tree. `git branch -D` is 🔴 DANGEROUS, and it gets its five answers. `gh pr merge` is 🟡 CAUTION. `gh pr merge --admin` is 🔴: it merges without the required reviews and checks.

## LEARNING OBJECTIVES

After this video you can:

- Compare the three methods for bisect, blame and revert.
- Say whether `git branch -d` accepts the local branch after each method and why.
- Revert a merged pull request under each method.
- Explain what auto-merge waits for and what it does not check.
- Explain what a merge queue tests that a pull request run does not, and why a required check can stay unreported on queue entries.

## CONCEPT

In one sentence: the method decides which commits exist on `main`, and every later tool, bisect, blame, revert, an audit that follows a commit ID, works on those commits and no others.

Start from the one bit you measured last time: is your head commit an ancestor of `main`? Yes after a merge commit. No after squash. No after rebase. After those two the content arrived and the commits did not. Four observations follow.

Observation one: `git branch -d` refuses. It deletes only when the branch is merged into its upstream, or into HEAD when it has no upstream, and "merged" means reachable. Squash and rebase merges transfer content without ancestry. There is nothing to prevent here. Expect it under these two methods, and verify before you delete with `-D`. One caveat from the textbook: this refusal is an inference from the documented new commit IDs, confirmed in the transcript for the local equivalents. And the other half of the rule: while the remote-tracking branch still exists, `-d` deletes with a warning, because the branch is merged into its upstream.

Observation two: blame and log name different commits. After a squash, every line points to one commit. Under squash the unit of history is the pull request, so the squash commit's message must link to it, as the pull request number in a default title does.

Observation three: untested commits can land. Under merge and rebase, an intermediate commit of the branch is on `main`, and CI tested the final result, not each commit. `git bisect` can stop on it. `git bisect start --first-parent` treats a merged pull request as one step; for the rebase method no flag helps, and every commit has to pass on its own. Squash removes the problem and the granularity with it.

Observation four: reverting is three different operations. A merge commit needs `-m 1`, and carries the trap from the merge videos: re-merging the branch brings nothing back until you revert the revert. A squash commit reverts like any commit. A rebased series has no marker of where the pull request began: one revert per commit. On GitHub, the Revert button and `gh pr revert` create a new pull request that reverts the original merge commit.

**[ON SCREEN]** The summary table of section 17.9.

No method is best. Each one buys something and pays for it. Commit IDs reviewed equal commit IDs on `main`: yes for a merge commit, no for the other two. Bisect granularity: a commit, or a pull request with `--first-parent`; a pull request under squash; a commit under rebase. Revert: one command with `-m 1` and the re-merge trap; one command; one per commit. Reusing the branch afterwards: safe; old commits listed again; the same, though a plain rebase skips the old commits.

The contexts the textbook gives. Merge commits where the reviewed commit IDs must be the deployed ones: audits, signed-commit policies, long-lived branches merged repeatedly. Squash where pull requests are small and short-lived and commit hygiene inside a branch is not enforced. Rebase where the team curates every commit, wants a linear history, and does not require signatures on the target.

Auto-merge. In one sentence: auto-merge is a stored instruction on a pull request: merge with this method as soon as every requirement is met.

"Auto-merge merges a pull request automatically after all required reviews and status checks pass." It must first be enabled for the repository, and the option is shown only on pull requests that cannot be merged immediately. One safety property is documented: auto-merge is disabled if someone without write permissions pushes new changes to the head branch or switches the base branch. Availability: public repositories on GitHub Free, public and private on paid plans.

What it does not check. Auto-merge waits for required things only. In a repository with no required checks and no required reviews there is nothing to wait for. And the documentation names one event that switches it off, a push by someone without write permission. For a commit pushed by someone with write permission after the approval, whether it merges unreviewed is decided by the stale-approval settings from V124, not by auto-merge. Decide those settings before you allow auto-merge on a branch that deploys.

The merge queue. In one sentence: a merge queue merges pull requests one group at a time and runs the required checks on the exact commit that will become the new tip of the base branch.

The problem it solves: without "strict" required checks, two pull requests can each be green against an older `main` and break `main` together. With them, every merge makes all other pull requests out of date; GitHub calls that "a race-to-merge situation".

How it works, from the documentation: the queue "creates temporary branches with a special prefix", and the changes in a pull request "are grouped into a `merge_group` with the latest version of the `base_branch` as well as changes from pull requests ahead of it in the queue". The temporary branches begin with `gh-readonly-queue/` and the base branch name, and "contain a different `sha` from the pull request". If a group fails its checks or conflicts, the pull request is removed from the queue, and the branches behind it are recreated without it.

The trap. Checks on queue branches are triggered by their own event. "You must use the `merge_group` event to trigger your GitHub Actions workflow when a pull request is added to a merge queue ... Otherwise, status checks will not be triggered ... The merge will fail as the required status check will not be reported."

Also documented: the queue fixes the merge method, and `gh pr merge --admin` bypasses the queue.

Availability: merge queues are available "in any public repository owned by an organization, or in private repositories owned by organizations using GitHub Enterprise Cloud". So not under a personal account. And one statement the textbook marks unverified: the merge-queue ruleset rule appears only in the Enterprise Cloud view of the documentation, and the course could not confirm whether a Free or Team organization can enable the queue through a ruleset or only through a classic rule.

When not to use a queue: it adds a CI run per group and latency per merge. For a few merges a day, "strict" required checks cost less.

## MENTAL MODEL

For the first part, keep the filing analogy from the last video: drafts stapled in, one clean page retyped, or every draft retyped. Everything in section 17.9 is the question "what can I still look up in the folder?" With stapled drafts: everything, including the one draft that had a mistake in it. With one clean page: only the final text. With retyped drafts: every step, and no cover note saying which pages belong together.

For the queue, think of a rehearsal. A pull request's CI rehearses your change alone on the stage as it was. The queue rehearses the whole evening in running order: the stage as it is now, plus every act ahead of you, plus you. If an act ahead of you is pulled, your rehearsal no longer describes the evening, and it is run again.

The model breaks at one point: in a theatre, a rehearsal you already did still happened. In the queue, a result on a commit that will not land counts for nothing, because checks belong to commit IDs.

## DIAGRAM

**[ON SCREEN]** The root-cause box of section 17.9.

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

**[DIAGRAM]** A queue of three entries, the second failing.

```text
   main at 9a383e5                  pull request heads:  pr-1 8c7493d   pr-2 1621dd9   pr-3 6c162ef

   the queue builds, in order:
   gh-readonly-queue/main/pr-1   2b79f02  =  main + #1                 checks run here
   gh-readonly-queue/main/pr-2   7c2fd05  =  main + #1 + #2            checks run here   FAIL
   gh-readonly-queue/main/pr-3   0569767  =  main + #1 + #2 + #3       (built on a failing entry)

   #2 leaves the queue; the entry behind it is rebuilt:
   gh-readonly-queue/main/pr-1   2b79f02  =  main + #1
   gh-readonly-queue/main/pr-3   3bda42c  =  main + #1 + #3            a new commit: tested again

   when it passes:  main fast-forwards to 3bda42c, the tested commit, unchanged
```

Three approved pull requests with their head commits on the top line. Below, what the queue builds: one temporary branch per entry, each containing `main` and everything ahead of it. Compare the IDs on the left of each line with the pull request heads at the top: none of them is the same. The checks must run on commits that no contributor created.

The second entry fails. It leaves the queue, and the third is rebuilt without it. Its ID changes from `0569767` to `3bda42c`, so it must be tested again. When it passes, `main` moves to exactly that commit.

Now the hook: a workflow that only runs on pull request events never runs on any line of this picture.

## LIVE TERMINAL DEMO

**[TERMINAL]** The same three copies as in the last video.

```bash
labs/run ch17/merge-methods
```

You are the contributor now. The maintainer deleted the head branch on the server, and you update your clone.

```bash
cd merge/you
git pull --ff-only --prune
git branch -d feature/priority-routing
```

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

Copy 1, the merge commit: `-d` deletes the branch without complaint. Its tip is an ancestor of `main`.

```bash
cd ../../squash/you
git pull -q --ff-only --prune
git branch -vv
git branch -d feature/priority-routing
```

**[PAUSE]** Copy 2, squash. Your work is on `main`. What does `git branch -d` say?

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

"Not fully merged." `git branch -vv` shows the upstream as gone, so Git compares with HEAD and finds three commits that are not reachable.

<!-- snippet: ch17/merge-methods/13-you-update-rebase -->
```text
# Copy 3 (rebase):
$ cd ../../rebase/you
$ git pull -q --ff-only --prune
$ git branch -d feature/priority-routing
error: the branch 'feature/priority-routing' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/priority-routing'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git branch --no-merged main
  feature/priority-routing
```
<!-- /snippet -->

Copy 3, rebase: the same refusal.

How do you verify before `-D`?

```bash
git cherry -v main feature/priority-routing
```

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

In the rebase copy, `git cherry` marks every commit with a minus sign: a patch-equivalent commit is on `main`. In the squash copy every commit gets a plus sign, because no single commit on `main` matches. The test that works for both asks whether merging the branch would change `main` at all: the merged tree equals the tree of `main`. The branch has nothing left to give.

Then the 🔴 command, `git branch -D`. What it changes: the branch ref and its reflog are deleted. What it can destroy: nothing at once; the commits stay in the object database and, if you ever had the branch checked out, in the reflog of HEAD, for the retention periods. Preview: the tree comparison you just saw. Recovery: `git branch <name> <id>`, with the ID the command printed. Appropriate: after you have verified that the base contains the content.

```bash
git -C merge/asha blame -s -L 1,3 router/classify.py
git -C squash/asha blame -s -L 1,3 router/classify.py
```

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

Blame on the same three lines. Under the merge commit, each line names the commit that introduced it. Under squash, every line names `da48bba`.

**[PAUSE]** The second commit of the branch used a wrong queue name and the third fixed it. Under which methods does `main` contain a commit with the wrong name in its tree?

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

Under merge and under rebase: one commit each. Under squash: none. That intermediate commit was never tested on its own, and `git bisect` can stop on it.

Reverting.

```bash
cd ../../merge/you
git revert --no-edit -m 1 HEAD
```

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

One revert, and you must name the mainline with `-m 1`.

```bash
cd ../../squash/you
git revert --no-edit HEAD
```

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

One ordinary revert.

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

One revert per commit, and you must know where the pull request began: here, three commits back.

**[TERMINAL]** The queue, as an idea in plain Git.

```bash
labs/run ch17/merge-queue
```

<!-- snippet: ch17/merge-queue/01-three-prs -->
```text
# Three approved pull requests, each one commit on top of the same main:
$ git log --oneline --graph main pr-1 pr-2 pr-3
* 6c162ef Describe how to run the tests
| * 1621dd9 Lower the confidence threshold to 0.65
|/  
| * 8c7493d Accept tickets without a subject
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

Three approved one-commit pull requests against the same `main`.

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

The queue in order 1, 2, 3. Each temporary branch is created from the one before and merges one more pull request.

```bash
git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/pr-* refs/heads/gh-readonly-queue
```

**[PAUSE]** Six refs: three pull request heads, three queue entries. How many different commit IDs?

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

Six. The checks must run on the three queue commits, which no `pull_request` run ever saw.

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

The checks fail on the group of pull request 2. It leaves the queue, and number 3 is rebuilt on top of number 1. A different commit, tested again.

```bash
git switch -q main
git merge --ff-only gh-readonly-queue/main/pr-3
git log --oneline --first-parent -3
```

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

The checks pass, and the base branch moves to the tested commit by a fast-forward, unchanged. What was tested is what landed.

**[ON SCREEN]** The fix for the hook, from section 17.11. Shown, not run.

```yaml
on:
  pull_request:
  merge_group:
```

One more trigger. With it, the workflow runs on the queue's temporary branches and reports the required check there.

**[ON SCREEN]** And the three auto-merge commands from section 17.10, shown without output.

```bash
gh repo edit OWNER/REPO --enable-auto-merge
gh pr merge 12 --auto --squash
gh pr merge 12 --disable-auto
```

The first is the repository setting, once. The second stores the instruction on pull request 12. The third withdraws it.

## COMMON MISTAKES

1. Enabling a merge queue without adding the `merge_group` trigger. Root cause: checks on queue branches are triggered by their own event; without it the required check is never reported there.
2. Deleting a branch with `-D` after a squash merge without checking. Root cause: `-d` refused because the commits are unreachable from `main`; verify that the base contains the content first.
3. Reverting a merge commit without `-m`, or re-merging the branch after the revert and expecting the change back. Root cause: a merge has two parents, and a reverted merge is still an ancestor; you revert the revert.
4. Assuming every commit on `main` passed CI. Root cause: under merge and rebase methods, intermediate commits land that were only tested as part of the final result.
5. Trusting auto-merge to stop an unreviewed push. Root cause: auto-merge waits only for required reviews and checks; a later push by someone with write access is governed by the stale-approval settings.

## PRODUCTION EXAMPLE

Picture three teams in one company, with three choices, each defensible with this video's table.

The payments team must show that the reviewed commit is the deployed commit: merge commits, and `git bisect start --first-parent` when they hunt a regression, so that a pull request is one step.

The evaluation-tools team has small, short-lived pull requests full of "fix typo" commits: squash, with the pull request number in the squash message so that blame leads back to the discussion. They delete head branches on merge and tell newcomers that `git branch -d` will refuse.

The inference-runtime team curates every commit and wants a straight line: rebase, on a branch that does not require signatures, with a rule that every commit passes the tests on its own, because bisect will visit each one.

The team from the hook adds the `merge_group` trigger on Monday morning. The eleven queued pull requests start reporting. Then they ask the honest question from the end of section 17.11: at a few merges a day, do they need a queue at all, or would "strict" required checks cost less?

## PRACTICE EXERCISE

Do Exercise 22.4, "A merge method for three teams", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). For each team, write down the requirement that decides the method before you name the method, and for the method you choose, the cost the team accepts in bisect, blame or revert.

The challenge is Exercise 22.7, "The approved commit is not on main", in the same file.

## INTERVIEW QUESTION

Question 271 of the CTO question bank:

> "What does a merge queue test that a `pull_request` workflow does not? Why can a required check stay unreported forever on a queue?"

A strong answer names the commit each one tests and what that commit contains. It explains why the two have different IDs and what follows from checks being attached to IDs. For the second part it names the event, states what happens to the merge when the check never reports, and gives the fix. It adds when a queue is not worth its cost.

## RECAP

You should now be able to say:

- Only a merge commit makes your commits ancestors of `main`; after squash and rebase `git branch -d` refuses, and you verify before `-D`.
- Squash gives coarse blame and bisect and a one-command revert; merge commits keep fine steps and revert with `-m 1`; rebase keeps steps and loses the grouping.
- Under merge and rebase, intermediate commits that were never tested alone land on `main`.
- Auto-merge is a stored instruction that waits for required reviews and checks, and for nothing else.
- A merge queue tests the commit that will become the tip of the base, on temporary branches, and workflows must run on the `merge_group` event.

## HOMEWORK

Read sections 17.9 to 17.11 of [Chapter 17](../../textbook/ch17-pull-requests.md). Do Exercise 22.3, "The queue that never finishes", and Exercise 22.6, "Auto-merge did what it was told", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

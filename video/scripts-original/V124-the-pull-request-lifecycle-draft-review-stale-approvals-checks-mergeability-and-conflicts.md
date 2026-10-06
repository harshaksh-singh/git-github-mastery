# V124: The pull request lifecycle: draft, review, stale approvals, checks, mergeability, and conflicts

- **Part.** 5: GitHub
- **Module.** 21
- **Planned minutes.** 24
- **Prerequisites.** V123
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), sections 17.4 to 17.7
- **Demo scripts.** `labs/ch17/pr-conflict.sh`; GitHub-side walkthrough of the review part of Lab 21.1

## HOOK

**[ON SCREEN]** A timeline: "approved" · "pushed 1 commit" · "merged".

A reviewer approved a pull request at eleven. The author pushed one more commit at ten past. The pull request merged at a quarter past. The commit that reached `main` last was read by nobody.

Your CTO asks: we require a review on every change. How did unreviewed code get in, and which setting would have stopped it?

GitHub's documentation has a word for this: a pull request being "hijacked, where unapproved content is added to approved pull requests". Two settings address it. They answer different attacks, and each has a cost that you should be able to state before you propose it.

## INTRODUCTION

In the last video a pull request was an object over three commits. Now it moves through time. We follow it from draft to merged or closed, and at each step ask the question of this whole part: is this GitHub data, or does it write to a branch? The answer from section 17.4 is short: each state is GitHub data, and only the merge writes to a branch.

Four sections of Chapter 17: the lifecycle; stale approvals; checks and mergeability; and conflicts in a pull request. The demonstration is the conflict, repaired in two ways, in `labs/ch17/pr-conflict.sh`. The GitHub side is a walkthrough of a review, which needs a second account or a teammate.

Labels from the chapter's table. `git merge` and `git rebase` are 🟡 CAUTION: they move or rewrite the current branch. `git push --force-with-lease` is 🔴 DANGEROUS, and it appears in this video, so it gets its five answers. `gh pr update-branch` and `gh pr merge` are 🟡: they move the head branch or write to the base branch, and can dismiss approvals.

## LEARNING OBJECTIVES

After this video you can:

- Describe the states of a pull request from draft to merged or closed.
- Explain what a push does to an existing approval under each of the two settings.
- Tell checks from status checks and say what "mergeable" takes into account.
- Resolve a pull request conflict by merging the base in or by rebasing, and say what each does to the review.
- Show that both resolutions produce the same diff.

## CONCEPT

The lifecycle, in one sentence: a pull request moves from draft to ready for review, collects reviews and checks, and ends merged or closed.

Draft. "Draft pull requests cannot be merged, and code owners are not automatically requested to review them." Marking the pull request ready "will request reviews from any code owners", and you can convert a pull request back to a draft at any time. Use a draft when you want CI and early comments but not a formal review. An outdated-advice note: since 1 May 2025, drafts are available in every repository, not only on paid plans.

Reviews. A review has one of three outcomes. Comment: feedback without a verdict; it does not block. Approve: counts toward required approvals, if a rule requires any. Request changes: blocks only if a rule requires a pull request. GitHub's own words on that third outcome: it "is purely informational and will not prevent merging unless a ruleset or classic branch protection rule is configured with the 'require a pull request' option". Without a rule, "changes requested" is a request, not a lock.

Two more documented facts: anyone with read access can review and comment, and "pull request authors cannot approve their own pull requests". That is why the review labs need a second account.

Suggestions. A reviewer can propose replacement lines. When the author applies them, GitHub creates a single commit on the pull request's branch, on GitHub's side. Your local branch lacks it until you pull, and a push without pulling is rejected as a non-fast-forward.

One recent item: since 1 September 2026, in public preview and off by default, Copilot code review can submit an approving review that counts toward required approvals. When you design a review policy, count the humans.

Stale approvals. In one sentence: an approval is attached to the diff as it was when the reviewer approved; two optional settings decide what happens to that approval when the diff changes afterwards.

**[ON SCREEN]** Setting 1 and setting 2, side by side.

Setting 1: dismiss stale approvals. GitHub records the state of the diff at the point of approval. If the diff changes from this state, the approving review is dismissed as stale, and the pull request cannot be merged until someone approves again. Listen to the causes the documentation gives: a contributor pushes new changes; someone clicks Update branch; or a related pull request is merged into the target branch. The diff can change without anyone touching your branch.

Setting 2: require approval of the most recent reviewable push. It requires "an approval from someone other than the last person to push to a branch". With this option stale reviews are not dismissed, and the pull request remains approved as long as someone other than the person who made the most recent changes approves it. GitHub presents it as a compromise for large pull requests with many reviewers, and says which one is stricter: "it is safer to dismiss stale reviews."

The costs. The first costs a re-review after every update, including an "Update branch". The second can leave earlier approvals standing on a diff that has since changed.

Checks and mergeability. In one sentence: mergeability is two independent questions: can Git merge the two tips, which is the test merge, and do the repository's rules allow it.

GitHub distinguishes two kinds of status checks. Checks carry detailed output and are created by GitHub Apps, including Actions. Commit statuses are a simpler state set through the API by external services. "GitHub Actions generates checks, not commit statuses." Both are attached to a commit ID, not to the pull request. A new push creates a new head commit with no checks yet. And "required checks must pass on the latest commit SHA. Checks from earlier commits don't satisfy the requirement."

A red check blocks nothing by itself. Only a rule that names the check does.

For scripts: the API's `mergeable` field can be true, false or null. Null means GitHub has started a background job to compute it. A script that treats null as "not mergeable" is wrong; it must ask again.

One caveat the textbook marks unverified: two GitHub pages disagree about how long checks data is retained, 400 days on one, the Actions retention setting of 90 days by default on a changelog entry effective 1 October 2026. The practical consequence either way: an old pull request may need its checks re-run before it can merge.

Conflicts. In one sentence: a pull request "has conflicts" when the test merge of head into base cannot be computed cleanly, and you repair it by changing the head branch, either by merging the base into it or by rebasing it onto the base.

It is the ordinary three-way conflict from the merge videos, detected on the server, where nobody can resolve it. The resolution has to arrive as new commits on the head branch. GitHub offers three routes: the web conflict editor, which merges the entire base branch into the head branch and handles only simple competing line changes; the command line; and, with the Copilot cloud agent, a button that has the agent commit a resolution, which you review like any resolution.

## MENTAL MODEL

Think of an approval as a signature on a specific printout, not on the folder. If a page in the folder is replaced after the signature, the signature still exists and no longer covers what is in the folder.

Setting 1 tears up the signature whenever the printout would now differ. Setting 2 keeps the signatures and adds a rule about the last page: the person who inserted it cannot be the only one vouching for it.

The model breaks in one respect: with a real folder, pages change only when someone opens it. A pull request's diff can change because the base moved. Nobody touched your branch, and the printout is different. That is why setting 1 also dismisses after "a related pull request is merged into the target branch".

## DIAGRAM

**[DIAGRAM]** The lifecycle as states, with the event that causes each transition.

```text
                  mark ready                 review submitted
   +-------+  ----------------->  +-------+  ----------------->  +--------------------+
   | draft |                      | ready |                      | approved           |
   +-------+  <-----------------  +-------+  <-----------------  | changes requested  |
                convert to draft      ^        push (setting 1:  | commented          |
                                      |        approval dismissed)+--------------------+
                                      |                                   |
                                      | reopen                            | merge (rules satisfied:
                                      |                                   |  reviews, checks, no conflict)
                                  +--------+                              v
                                  | closed |  <--- close           +----------+
                                  +--------+                       |  merged  |   the only transition
                                                                   +----------+   that writes to a branch
   GitHub data: every box and every arrow except the last one.
```

Start at the left: a draft cannot be merged, and code owners are not requested. "Mark ready" moves it to ready and requests reviews. A review moves it to one of three outcomes.

Look at the arrow going back from the review box to "ready": a push. Under setting 1, that arrow dismisses the approval. Under neither setting, there is no such arrow, and that is the hook.

At the bottom right, the merge. The label is the point of the whole diagram: it is the only transition that writes to a branch.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch17/pr-conflict
```

Ravi's branch `fix/threshold` lowers the confidence threshold. Asha raised it on `main` in the meantime.

```bash
git log --oneline origin/main..fix/threshold
git merge-tree --write-tree --name-only origin/main fix/threshold
```

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

Two commits in the pull request. The test merge, computed locally exactly as the server would: exit status 1, and the conflicted file named. On GitHub this pull request would show as conflicting, with no merge ref and no CI run.

Repair 1: merge the base into the head. This is what the web editor and the Update branch button do, and what `gh pr update-branch` does by default.

```bash
git merge origin/main
git diff
```

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

The conflict, now in a place where someone can resolve it. After resolving, adding and committing:

**[PAUSE]** The branch had two commits. After the merge is committed and pushed: how many commits does the pull request list, and does the push need force?

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

Three commits, one of them a merge that carries the resolution. The push was a fast-forward: no force, and nobody's clone of the branch is disturbed.

Repair 2, in a second copy of the same situation: rebase the head onto the base.

```bash
git rebase origin/main
```

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

The rebase stops at the first commit with the same conflict. Resolve, `git add`, `git rebase --continue`.

**[PAUSE]** After the rebase: how many commits in the pull request, are their IDs the ones the reviewer saw, and what does a plain `git push` say?

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

Two commits in a straight line, both new: `be88439` became `e2639c7`. A plain push is rejected as a non-fast-forward. History was rewritten, so the push needs `--force-with-lease`.

That is the 🔴 command. The five answers. What it changes: it replaces the remote branch, if the remote branch is where you last saw it. What it can destroy: commits on the server that no clone of yours has; and alone, the check passes wrongly after a background fetch. How to preview: add `--dry-run`, and after a fetch look at `git log HEAD..origin/<branch>`. How to recover: push the old ID back from a reflog. When it is appropriate: for your own pull request branch after a rebase. Here it is exactly that.

Also note what you cannot see any more: the conflict was resolved inside the first commit. No commit records that it happened.

```bash
git diff origin/main...fix/threshold
```

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

Both repairs give the reviewer the same three-dot diff.

**[ON SCREEN]** The comparison table of section 17.7.

Merge base into head: the push is a fast-forward; existing commit IDs are kept; the resolution is visible in the merge commit; the commit list grows by a merge commit. Rebase head onto base: the push is forced; commit IDs are replaced; the resolution is folded into the rewritten commits; the commit list stays clean. Under both, stale-approval dismissal is triggered, because the diff changed. And the last row settles many arguments: after a squash merge, the final history on `main` is identical. Under the squash method the shape of the branch disappears at merge time, so the cheaper merge is enough. Under the other two methods the shape lands on `main`, which is a reason to rebase.

**[ON SCREEN]** GitHub walkthrough: the review part, on your practice repository, with a second account or a teammate. The interface changes; the documentation pages cited in sections 17.4 and 17.5 are the reference. No output is shown.

Open a pull request as a draft and read the merge box: according to the documentation it cannot be merged. Mark it ready.

```bash
gh pr ready
```

From the second account, submit an approving review; the author cannot approve their own pull request.

```bash
gh pr review --approve
gh pr checks
```

Now push one more commit from the author's side and open the timeline of the pull request. Read the events in order: the approval, then the push. Whether the approval is still counted depends on the repository's rules: with "dismiss stale approvals" enabled, the documentation says the review is dismissed as stale; with neither setting, the approval stands. Rulesets are the subject of the last three videos of this batch; for now, read what your repository does and say which case you are in.

## COMMON MISTAKES

1. Assuming a required review covers the final diff. Root cause: an approval is attached to the diff as it was; without one of the two settings, a later push does not affect it.
2. Treating "changes requested" as a lock. Root cause: it is informational unless a rule requires a pull request.
3. Expecting green checks to carry over after a push. Root cause: checks are attached to a commit ID, and a push creates a new head commit.
4. Treating a null `mergeable` as "not mergeable" in a script. Root cause: null means the computation is still running.
5. Pushing after applying a suggestion or pressing Update branch, and being rejected. Root cause: GitHub made a commit on the branch; the local branch lacks it until you pull.

## PRODUCTION EXAMPLE

The team from the hook enables "dismiss stale approvals" on `main`. The first week brings a complaint: the team rebases pull request branches onto `main` before merging, and now every rebase dismisses the approval, so reviewers approve twice. That is the control working as designed. The textbook's advice is to name the cost when you propose the setting, and the team does: for small pull requests the re-review takes a minute and they keep it. For the two large, long-running pull requests with many reviewers they discuss the second setting, knowing GitHub's own verdict that dismissing is the safer of the two.

A second rule from the same section goes into their contribution guide: do not resolve conflicts in lock files or other generated files by picking a side. Take the base version, regenerate with the tool, commit the result.

## PRACTICE EXERCISE

Do Exercise 21.2, "Is it still approved?", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). For each sequence of events, decide before you look anything up whether the approval still counts, under setting 1, under setting 2, and under neither. Write the reason as "the diff changed" or "the diff did not change", and "who pushed last".

The challenge is Exercise 21.7, "Green on the pull request, red on main", in the same file.

## INTERVIEW QUESTION

Question 270 of the CTO question bank:

> "A reviewer approved, the author pushed another commit, and the pull request merged. Which two settings address this, and what does each cost?"

A strong answer first explains why the sequence is possible at all, in terms of what an approval is attached to. It then describes each setting by what it does when the diff changes, including the case where nobody pushed, and gives the cost of each in a team's daily work. It says which one GitHub calls safer and when the other is defensible.

## RECAP

You should now be able to say:

- Every state of a pull request is GitHub data; only the merge writes to a branch.
- An approval belongs to a diff; "dismiss stale approvals" removes it when the diff changes, and "approval of the most recent reviewable push" requires someone other than the last pusher to approve.
- Actions produces checks; both checks and statuses belong to commit IDs, and required checks must pass on the latest commit.
- Mergeable means Git can merge the tips and the rules allow it.
- A conflict is repaired on the head branch, by merging the base in or by rebasing; the reviewer sees the same diff either way.

## HOMEWORK

Read sections 17.4 to 17.7 of [Chapter 17](../../textbook/ch17-pull-requests.md).

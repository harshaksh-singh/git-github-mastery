# V125: Why a pull request shows unexpected commits or a huge diff

- **Part.** 5: GitHub
- **Module.** 21
- **Planned minutes.** 26
- **Prerequisites.** V036, V054, V124
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), section 17.12
- **Demo scripts.** `labs/ch17/wrong-base.sh`, `labs/ch17/squash-reuse.sh`; GitHub-side walkthrough following Lab 21.2

## HOOK

**[ON SCREEN]** "Commits 4 · Files changed 3" — on a pull request that changes one line.

The pull request changed one line. The page lists four commits and three files. The author says "I only changed one line". The reviewer says "then why am I looking at three files?" Your CTO asks: which is true?

Both. The author is describing a commit. The page is describing a range. And the range starts somewhere the author did not expect.

By the end of this video you will be able to take any pull request that shows too much, name the cause from a short documented list, prove it with one Git command, and choose the repair that fits. One question does most of the work: where does the range start?

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Two videos ago you learned the sentence that the whole chapter hangs on. A pull request, a proposal to merge a head branch into a base branch, shows `base..head` in its commit list and `base...head` in its diff. And everything is computed from three commits: the tip of the base, the tip of the head, and their merge base, the most recent commit that both histories contain.

So every surprise on a pull request page is a surprise about one of those three. Either the head contains commits that the base does not reach, or the base is not the branch the work started from. That is section 17.12 in one sentence, and this video is that section.

GitHub documents five causes. The first two can be reproduced in plain Git, and they are the two replays: `labs/ch17/wrong-base.sh` and `labs/ch17/squash-reuse.sh`. Then a walkthrough following Lab 21.2 on a practice repository.

Labels: `git rebase --onto` is 🟡 CAUTION: it rewrites the current branch. Preview with `git log <upstream>..HEAD`. Recover with `ORIG_HEAD`, the reflog, or `git rebase --abort`. Republishing a rewritten branch needs `git push --force-with-lease`, 🔴 DANGEROUS, with the five answers from the last video: appropriate for your own pull request branch after a rebase. `gh pr edit --base` is 🟡: it changes the base and can dismiss approvals.

## LEARNING OBJECTIVES

After this video you can:

- Give the documented causes of a pull request with many unrelated commits or files.
- Diagnose a pull request opened against the wrong base and fix it by changing the base or by transplanting the branch.
- Explain why a branch reused after a squash merge lists its old commits again and may conflict.
- Repair the reused branch with `git rebase --onto`.
- Name the Git command that tests each cause.

## CONCEPT

**[ON SCREEN]** The table of section 17.12: documented cause, what you see, mechanism.

Cause one: the head branch was reused after a squash merge, the merge that replaces your commits by one new commit. You see commits that were "already squashed" listed again, and repeated conflicts. The mechanism: the squash commit has no parent link to the branch, so the merge base never moved.

Cause two: a wrong or changed base branch. You see every commit of the branch the work was really based on. The mechanism: the range is taken against a base that does not contain those commits.

Cause three: the base branch moved. The pull request page and a compare page disagree, because they "can calculate changed files from different merge bases". Nothing is wrong. If the two must agree, update the branch.

Cause four: rewritten or force-pushed history. You see old and new copies of commits and outdated review comments. GitHub's words: "Force pushing rewrites repository history and can ... corrupt pull requests." And if someone force-pushes the base branch, every open pull request against it lists the removed commits. That is a reason to block force pushes on shared branches.

Cause five: the diff is truncated or hidden. Files are missing from "Files changed" because of display limits, or because a `.gitattributes` rule hides the file. The file changed and the page does not render it. `git diff --stat base...head` on your machine has no such limit.

Now the two causes that deserve a mechanism.

**[ANIMATION]** graph: id=wrong 9a383e5-7e13c3d-29be88c-a1ae0eb fix/empty-subject; 29be88c origin/main; 9a383e5-bc944fd origin/release/1.0; HEAD=fix/empty-subject => + range:7e13c3d,29be88c,a1ae0eb:release/1.0..fix/empty-subject; note:9a383e5:merge_base; name:range => 29be88c origin/main; 9a383e5-bc944fd-5c46029 fix/empty-subject; bc944fd origin/release/1.0; HEAD=fix/empty-subject; reflog:a1ae0eb; range:5c46029:release/1.0..fix/empty-subject; note:bc944fd:merge_base; name:moves title=Created_from_main,_opened_against_release/1.0

**[ANIMATION]** step: range

The wrong base. On screen is today's example: a branch created from `main`, for a fix meant for a release branch. Why does it happen? Because people create branches from `main` by habit, and open the pull request against wherever the fix is meant to go. If those are two different branches, the range `base..head` contains everything on `main` that the release branch does not have. Merging such a pull request would carry unreleased work into the release branch.

There are two repairs, and they are not interchangeable. If the base is wrong, change the base of the pull request. GitHub warns about the side effect: "some commits may be removed from the timeline. Review comments may also become outdated." If the base is right and the branch started in the wrong place, transplant the commits with `git rebase --onto`. A plain `git rebase` onto the release branch would replay every commit, the foreign ones included, and change nothing about the pull request except the commit IDs.

Quick quiz. In our picture the fix really is for the release. Which repair? A: change the base. B: transplant the branch. Your answer?

**[PAUSE]**

**[ANIMATION]** step: wrong.moves

B. The base is right, and the branch started in the wrong place. So the one commit moves, and gets a new ID.

**[ANIMATION]** graph: id=squash 9a383e5-9aa221a-1b2b8ed origin/main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=feature/priority-routing => + note:9a383e5:merge_base; note:1b2b8ed:squash_commit; name:fork => 1b2b8ed origin/main; 16d4788-fa6e912 feature/priority-routing; HEAD=feature/priority-routing; note:9a383e5:merge_base; note:1b2b8ed:squash_commit; note:fa6e912:the_one_new_commit; range:44c1e7b,12ae95d,16d4788,fa6e912:base..head; name:range => 1b2b8ed-e73426a feature/priority-routing; 1b2b8ed origin/main; HEAD=feature/priority-routing; reflog:44c1e7b,12ae95d,16d4788,fa6e912; note:1b2b8ed:merge_base; range:e73426a:base..head; name:repair title=Squash,_then_reuse

**[ANIMATION]** step: fork

Squash, then reuse. On screen: `main` after a squash merge, and the branch that was squashed. This one needs the internals of the merge base, which you learned in the merge videos. The merge base comes from parent links only. Git never compares patches to guess that a commit "is already there". A squash merge creates one new commit on the base that copies the content of the branch and records no link to it. So after the squash, for Git, the branch's commits were never merged. The merge base of `main` and the old branch is still the original fork point.

**[ANIMATION]** step: squash.range

Keep working on that branch, and two things follow. The range `base..head` lists the old commits again. And the three-way merge sees that both sides added the same files since the fork point, with different content: a conflict in a file that only you ever edited.

GitHub's page says the same: "If you keep working on the same head branch after a squash merge, later pull requests can include commits that were already squashed into the base branch."

Three ways out. One: move only what is new, with `git rebase --onto origin/main <last squashed commit>`. Two: merge `main` into the branch and resolve once, which moves the merge base. Three, the prevention: a new branch from `main` for every pull request, and automatic deletion of head branches, set by `gh repo edit --delete-branch-on-merge`.

When not to transplant: when other people have based work on the branch. A rebase replaces its commits, and the push must be forced.

## MENTAL MODEL

Think of the page as a ruler laid between two points, the merge base and the head. Everything between the points is shown. When the page shows too much, don't stare at what is shown. Ask where the left end of the ruler is.

Try it now, thirty seconds, on paper: draw a branch that was squashed and then reused, and mark where the ruler starts. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: squash.range

`git merge-base base head` tells you. If the left end is further back than you expected, there are only two reasons. The head carries history that the base never received as history: that is squash-then-reuse, where the content arrived and the ancestry did not. Or you are measuring against the wrong base: that is the wrong-base case.

**[ANIMATION]** end

The model breaks for the fifth cause. Truncated and hidden diffs are a property of the page, not of the range. There the ruler is right and the display is short.

## DIAGRAM

**[ON SCREEN]** The root-cause box of section 17.12.

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

**[ANIMATION]** step: squash.range

**[DIAGRAM]** The graph behind that box.

```text
                          squash commit: content of the branch, one parent, no link to the branch
                                  |
   9a383e5 --- 9aa221a --- 1b2b8ed                      main
        \
         44c1e7b --- 12ae95d --- 16d4788 --- fa6e912    feature/priority-routing (reused)
         \_________________________/           |
          pull request 1 (squashed)            the one new commit

   merge base of main and the branch: still 9a383e5
   base..head  = 44c1e7b, 12ae95d, 16d4788, fa6e912     four commits for a one-line change

   after  git rebase --onto origin/main 16d4788 :

   9a383e5 --- 9aa221a --- 1b2b8ed --- e73426a          one commit, based on main
```

The top line is `main`. Its tip `1b2b8ed` is the squash commit. Look at its parents: one, `9aa221a`. There is no line from it down to the branch.

The lower line is the branch: the three commits of pull request 1, still there, and one new commit on top.

Now lay the ruler. The merge base is `9a383e5`, at the far left. Between it and the head are four commits. That's the question from the hook, answered: the range starts further back than the author thought.

**[ANIMATION]** step: squash.repair

And the repair: the one new commit, replayed on `main`, with a new ID.

## LIVE TERMINAL DEMO

**[TERMINAL]** First the wrong base.

```bash
labs/run ch17/wrong-base
```

**[ANIMATION]** graph: id=wrong2 9a383e5-7e13c3d-29be88c-a1ae0eb fix/empty-subject; 29be88c origin/main; 9a383e5-bc944fd origin/release/1.0; HEAD=fix/empty-subject => 29be88c origin/main; 9a383e5-bc944fd-5c46029 fix/empty-subject; bc944fd origin/release/1.0; HEAD=fix/empty-subject; reflog:a1ae0eb; range:5c46029:release/1.0..fix/empty-subject; note:bc944fd:merge_base; name:moves title=Created_from_main,_opened_against_release/1.0

**[ANIMATION]** step: state-1

Ravi created the branch `fix/empty-subject` from `main`, by habit. The fix is meant for the release branch, so he opened the pull request with base `release/1.0`.

```bash
git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject
```

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

One commit of his own, `a1ae0eb`, on top of two commits that are on `main` and not on the release branch.

```bash
git log --oneline origin/release/1.0..fix/empty-subject
git diff --stat origin/release/1.0...fix/empty-subject
```

**[PAUSE]** One commit of his own. What will the pull request against `release/1.0` list?

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

Three commits and three files for a one-line fix. The two extra commits are `main`'s. In a real repository this is the pull request with hundreds of unrelated changes.

The diagnosis is one question: which base makes this branch small? Predict the two counts, against `main` and against the release branch. Say them out loud.

**[PAUSE]**

```bash
for b in origin/main origin/release/1.0; do echo "$b: $(git rev-list --count $b..fix/empty-subject) commits"; done
git log --oneline -1 $(git merge-base origin/release/1.0 fix/empty-subject)
git log --oneline -1 $(git merge-base origin/main fix/empty-subject)
```

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

One commit against `main`, three against the release branch. And the two merge bases show where the ruler starts in each case.

Fix A: the change belongs on `main` after all. Same branch, other base.

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

On GitHub that is `gh pr edit --base main`. Nothing in Git changes. The pull request object gets a different base, and the same branch is a one-commit pull request.

Fix B: the change does belong on `release/1.0`. Move the one commit there.

```bash
git rebase --onto origin/release/1.0 origin/main fix/empty-subject
git log --oneline origin/release/1.0..fix/empty-subject
git diff --stat origin/release/1.0...fix/empty-subject
```

**[PAUSE]** Read the command aloud before I run it. Which commits does it take, and where does it put them?

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

"Take the commits of `fix/empty-subject` that are not on `origin/main` and replay them on `origin/release/1.0`."

**[ANIMATION]** step: wrong2.moves

One commit, with a new ID, one file.

<!-- snippet: ch17/wrong-base/06-republish -->
```text
$ git push
To ../../server/ticket-router.git
 ! [rejected]        fix/empty-subject -> fix/empty-subject (non-fast-forward)
error: failed to push some refs to '../../server/ticket-router.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../../server/ticket-router.git
 + a1ae0eb...5c46029 fix/empty-subject -> fix/empty-subject (forced update)
```
<!-- /snippet -->

The branch was rewritten, so republishing it is a forced push, with `--force-with-lease`, on Ravi's own pull request branch.

**[TERMINAL]** Now squash, then reuse.

```bash
labs/run ch17/squash-reuse
```

**[ANIMATION]** graph: id=squash2 9a383e5-9aa221a-1b2b8ed origin/main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=feature/priority-routing => 1b2b8ed origin/main; 16d4788-fa6e912 feature/priority-routing; HEAD=feature/priority-routing; name:reuse => 1b2b8ed-e73426a feature/priority-routing; 1b2b8ed origin/main; HEAD=feature/priority-routing; reflog:44c1e7b,12ae95d,16d4788,fa6e912; note:1b2b8ed:merge_base; range:e73426a:base..head; name:repair title=Squash,_then_reuse

**[ANIMATION]** step: state-1

The branch of pull request 1 is still here: it was squash-merged, and nobody deleted it.

```bash
git log --oneline --graph origin/main feature/priority-routing
```

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

The squash commit `1b2b8ed` is on `main`. The three original commits are still under the branch, and no line connects them to the squash.

<!-- snippet: ch17/squash-reuse/02-keep-working -->
```text
# You keep working on the same branch: one small follow-up commit.
$ git diff --stat
 router/priority.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git commit -q -am "Treat data loss as urgent"
$ git push -q
```
<!-- /snippet -->

**[ANIMATION]** step: squash2.reuse

You make one small follow-up commit on the old branch, push, and open pull request 2.

```bash
git log --oneline origin/main..feature/priority-routing
git diff --stat origin/main...feature/priority-routing
```

**[PAUSE]** One new commit since the squash. How many commits will pull request 2 list?

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

Four commits and two files for a one-line change.

```bash
git merge-tree --write-tree --name-only origin/main feature/priority-routing
```

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

And the test merge fails: an add/add conflict in `router/priority.py`, a file that only you ever edited.

```bash
git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
git show -s --format="%h parents: %p  %s" origin/main
```

<!-- snippet: ch17/squash-reuse/05-why -->
```text
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
9a383e5 Add classifier test
$ git show -s --format="%h parents: %p  %s" origin/main
1b2b8ed parents: 9aa221a  Route high-priority tickets to an escalations queue (#1)
```
<!-- /snippet -->

The two facts of the root-cause box, measured: the merge base is still `9a383e5`, and the tip of `main` has one parent.

Way out 1: move only what is new.

```bash
git rebase --onto origin/main HEAD~1
git log --oneline origin/main..feature/priority-routing
git diff --stat origin/main...feature/priority-routing
```

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

Everything up to `HEAD~1` is already on `main` as content.

**[ANIMATION]** step: squash2.repair

One commit, one file, a clean test merge, and a forced push.

**[PAUSE]** Would a plain `git rebase origin/main` do the same? It replays all four commits. Predict what happens to the first, and to the second.

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

Git dropped the first commit, "patch contents already upstream", because replaying it changed nothing. The second conflicts, because the squash already contains the third commit's fix of the same line. A plain rebase relies on Git noticing duplicates. `--onto` tells Git where the new work starts.

Way out 2, in another copy: merge `main` into the branch and resolve once.

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

The branch has everything `main` has plus the new word, so the branch side is the answer. The diff is correct afterwards. The commit list still shows five commits, which does not matter if the pull request is squash-merged.

<!-- snippet: ch17/squash-reuse/09-prevention -->
```text
# Way out 3, the one that prevents the problem: a new branch from main for new work.
$ cd ../../you/ticket-router
$ git switch -q -c feature/audit-log origin/main
$ git log --oneline origin/main..feature/audit-log
$ git rev-list --count origin/main..feature/audit-log
0
```
<!-- /snippet -->

Way out 3, the prevention: a new branch from `main` for every pull request.

**[ON SCREEN]** GitHub walkthrough following Lab 21.2, on your practice repository, in the normal shell. The interface changes; the documentation page "changing the base branch of a pull request" is the reference. No output is shown.

Create a second long-lived branch in your practice repository, for example a release branch from an older commit, and open a pull request from a branch that was created from `main` against that release branch. On the page, read the commit count and the file count, and compare with your prediction from `git log --oneline <base>..HEAD`.

Then apply fix A on the platform:

```bash
gh pr edit --base main
```

In the browser the same control is next to the title: the edit control, then the base branch menu. Read the page again: the documentation says some commits may be removed from the timeline and review comments may become outdated. And note the prevention from the textbook: `gh pr create` uses the default branch as base unless you pass `--base`.

## COMMON MISTAKES

Five mistakes to watch for.

1. Continuing on a branch after its pull request was squash-merged. Root cause: the squash commit has no parent link to the branch, so the merge base never moved and the old commits are listed again.
2. Fixing a wrong-base pull request with a plain `git rebase <base>`. Root cause: it replays every commit, the foreign ones included; `--onto` with the right upstream selects only your commits.
3. Changing the base when the branch started in the wrong place, or the reverse. Root cause: the two repairs answer different questions: where the change belongs, and where the work began.
4. Opening a pull request without looking at the range. Root cause: `gh pr create` uses the default branch as base unless told otherwise.
5. Trusting the "Files changed" tab to be complete on a very large pull request. Root cause: display limits and `.gitattributes` rules hide files that `git diff --stat base...head` shows.

## PRODUCTION EXAMPLE

**[ANIMATION]** graph: id=prod P-...210-M origin/main; M-?the_fix; P-R origin/release/2.4; HEAD=none; range:...210,M,?the_fix:212_commits_against_release/2.4; say:Branched_from_main_by_habit,_opened_against_release/2.4 => M origin/main; P-R-?the_fix_again; R origin/release/2.4; HEAD=none; reflog:?the_fix; range:?the_fix_again:one_commit; cmd:git_rebase_--onto_origin/release/2.4_origin/main; say:Fix_B:_the_branch_started_in_the_wrong_place; name:rebase dx=230

**[ANIMATION]** step: state-1

Now, out of the lab. An ML platform team maintains `main` and a `release/2.4` branch for a customer deployment. An engineer fixes a tokenizer bug for the release, branches from `main` by habit, and opens the pull request against `release/2.4`. The page shows 212 commits and several hundred files. The reviewer refuses to look at it, correctly.

**[ANIMATION]** step: rebase

The engineer runs the diagnosis from this video: the count of commits against each candidate base. One against `main`, 212 against the release branch. The base is right, the fix is needed in the release, so the branch started in the wrong place: fix B. One `git rebase --onto origin/release/2.4 origin/main`, one check of the range, one push with `--force-with-lease`, and the pull request is one commit.

**[ANIMATION]** end

The team adds two lines to its contribution guide: run `git log --oneline <base>..HEAD` before opening a pull request, and head branches are deleted on merge.

## PRACTICE EXERCISE

Your turn. Do Lab 21.2, "A pull request against the wrong base", in [`lab-manual/m21-pull-requests-forks.md`](../../lab-manual/m21-pull-requests-forks.md). Before you run the diagnosis, write down how many commits the pull request lists and which of them are the author's. Before each repair, predict the commit list and the diff afterwards.

The challenge is Lab 21.3, "The squash-then-reuse problem", in the same file. Predict the merge base before you ask Git for it.

## INTERVIEW QUESTION

Question 263 of the CTO question bank:

> "Why can a pull request show unexpected commits?"

**[PAUSE]**

Answer out loud. A strong answer starts from what the commit list is, as a Git range, and then gives causes as statements about the endpoints of that range, not as a list of anecdotes. For each cause it names the command that confirms it. It treats squash-then-reuse with the mechanism of the merge base, and it distinguishes the two repairs for a wrong base.

## RECAP

**[ANIMATION]** step: squash2.repair

Let's land this. When a pull request shows too much, you now ask one thing first: where does the range start?

You should now be able to say:

- A pull request that shows too much has a head with commits the base does not reach, or a base the work did not start from.
- The five documented causes are: reuse after a squash merge, a wrong or changed base, a base that moved, rewritten history, and truncated or hidden diffs.
- `git merge-base` and `git rev-list --count base..head` test the first two.
- A wrong base is fixed by changing the base or by `git rebase --onto`, depending on where the change belongs.
- After a squash merge the branch's commits are not ancestors of the base; delete the branch and start from `main`.

## HOMEWORK

Read section 17.12 of [Chapter 17](../../textbook/ch17-pull-requests.md). Do Exercise 21.6, "Five commits for a two-commit fix", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

You can now name the cause of an oversized pull request and prove it with one command. Practise with Lab 21.2. Next: indirect merges and stacked pull requests. Until then, look at the state first and type second. See you in the next one.

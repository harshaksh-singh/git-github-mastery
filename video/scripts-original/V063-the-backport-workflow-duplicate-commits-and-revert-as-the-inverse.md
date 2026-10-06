# V063: The backport workflow, duplicate commits, and revert as the inverse

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 10, Cherry-pick and ranges
- **Planned minutes:** 22
- **Prerequisites:** V048, V062
- **Textbook sections:** [Chapter 10](../../textbook/ch10-cherry-pick.md), sections 10.9, 10.10 and 10.11
- **Demo scripts:** `labs/ch10/backport.sh`, `labs/ch10/duplicates.sh`, `labs/ch10/revert-inverse.sh`

## HOOK

**[ON SCREEN]** Two statements side by side: "The fix is in the release." · "The fix was never backported."

A customer on version 1.4 reports a crash on empty prompts. Support asks engineering: is the fix in 1.4?

Engineer one runs `git branch --contains` with the ID of the fix from `main`. The release branch is not listed. "It was never backported."

Engineer two runs `git cherry` between the release and `main`. The fix is marked with a plus sign, meaning "no equivalent on the release". "Confirmed, not backported."

Engineer three opens the file on the release branch. The two lines of the fix are there.

Two tools said no and the file says yes. All three observations are correct. By the end of this video you can explain each of them, and name the one piece of evidence that would have settled the question at once.

## INTRODUCTION

The last two videos took cherry-pick apart. This one puts it to work, in the job it is most used for: the backport.

Three parts. First the workflow, four steps, and the audit question that follows every backport: does the release branch contain the fix, and how do you prove it? You will ask that question in three ways and get three different answers. Second, duplicate commits: after a pick, the same change exists under two IDs. How do you find such pairs, and what happens when the two branches are merged? Third, a short closing of a circle: revert is the same operation as cherry-pick with two inputs exchanged, and you can verify that with tree IDs.

The project is still `gateway`, with `main` and `release/1.4`.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Backport a fix to a release branch and leave an audit trail.
- Establish in three ways whether a release branch contains a fix.
- Find duplicate commits between two branches with `git cherry` and `--cherry-mark`.
- Explain what happens to duplicates when the two branches are later merged.
- Relate revert to cherry-pick as the same operation with base and theirs exchanged.

## CONCEPT

**The backport.** In one sentence: a backport is a fix that lands on the development line first and is then copied to a maintenance line with `git cherry-pick -x`, so that the copy says where it came from.

**[ON SCREEN]** The procedure of section 10.9.

1. Merge the fix into `main` through the normal review.
2. `git switch release/1.4`, then `git cherry-pick -x <commit>`.
3. Build and test on the release branch. "Applied cleanly" says that the text merged, not that the code works there.
4. Publish the release branch the way your team publishes it: a push, or a pull request whose base is the release branch.

Which direction? The textbook says a senior engineer should be able to name both conventions. The Git project commits a fix on the oldest supported branch that needs it and merges upward, so that newer branches contain older ones and cherry-picks are the exception. Trunk-based practice fixes on the main line first and cherry-picks to the release branch, on the argument that a fix made on the release branch can be forgotten on `main` and come back as a regression. This course demonstrates the second; the mechanics are the same in both.

**The audit.** Three ways to ask "is the fix in the release".

By ancestry: `git branch --contains <original>`. It follows parent links, and the original commit is not an ancestor of the release branch; its copy is. So this answers "no" for every backport.

By the recorded line: search commit messages for "cherry picked from commit" and the ID. If a commit on the release states that it is a copy of the fix, that is a proof.

By patch ID: `git cherry`. A patch ID is a hash of a commit's diff with line numbers ignored. It pairs exact copies. It does not pair a copy whose diff differs in any line, including a context line.

**Duplicates.** In one sentence: after a cherry-pick the same change exists under two commit IDs, and `git cherry` and `git log --cherry-mark` find such pairs by comparing patch IDs.

Precisely: `git cherry <upstream> <head>` lists the commits of `<head>` that are not in `<upstream>` and marks each with a minus if `<upstream>` contains a commit with the same patch ID, otherwise with a plus. `git log --left-right --cherry-mark A...B` walks both sides of the symmetric difference and marks such pairs with an equals sign. `--cherry-pick` in place of `--cherry-mark` leaves the pairs out.

**Revert as the inverse.** In one sentence: `git revert <commit>` 🟡 CAUTION is the same three-way merge with base and "theirs" exchanged: the base is the commit itself and "theirs" is its parent, so the change is applied backwards.

```text
                      base           ours    theirs         Result
--------------------  -------------  ------  -------------  ------------------------------
git cherry-pick C     parent of C    HEAD    C              HEAD plus the change of C
git revert C          C              HEAD    parent of C    HEAD minus the change of C
```

## MENTAL MODEL

**[ON SCREEN]** "Ancestry knows parents. Patch IDs know exact diffs. Only the message knows intent."

Three witnesses, and each can testify only to what it saw.

Ancestry saw parent links. It can say "this commit is reachable from that branch". It never saw a copy being made.

The patch ID saw the text of a diff. It can say "these two commits make textually the same change". It cannot recognise the same fix after it was adapted, or even after the surrounding lines differed.

The message line written by `-x` is the only witness that was told, at the moment of the pick, "this is a copy of that". It can be wrong only if a person removed it or wrote it falsely.

Where this model breaks: none of the three testifies that the code works on the release. That is step 3 of the procedure, and no Git command replaces it.

## DIAGRAM

**[DIAGRAM]** New diagram. `main` and the release branch, each with the fix. Draw a dashed line between the two fix commits and label it. Then the three audit questions, each pointing at what it reads.

```text
            6db3c0c---ca6dd48---f98ffd3---0cca736      main
           /                       :
  93787ec                          :   same patch ID (if the copy is exact), NO ancestry
           \                       :
            f395bc9----------------c84bed2             release/1.4
                                   message: "(cherry picked from commit f98ffd3...)"   <- only with -x

  git branch --contains f98ffd3      reads parent links      -> main only
  git log --grep 'cherry picked...'  reads the message       -> finds the copy, if -x was used
  git cherry / --cherry-mark         compares patch IDs      -> pairs exact copies only
```

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch10/backport`. On this release branch, the line `MAX_RETRIES` differs from `main`, as in V061.

**Part 1: the backport.** `git cherry-pick -x` 🟡 CAUTION.

<!-- snippet: ch10/backport/01-pick-x -->
```text
$ git log --oneline -3 main
0cca736 Document the streaming client
f98ffd3 Reject empty prompts before calling the model
ca6dd48 Add streaming client
$ git cherry-pick -x f98ffd3
Auto-merging src/client.py
[release/1.4 c308105] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git log -1 --format=fuller
commit c3081051fe3d7125255eac2894828854bc2682ad
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:09:00 2026 +0530

    Reject empty prompts before calling the model
    
    (cherry picked from commit f98ffd3d15c63376ff2fe882f990e11ff6722de6)
```
<!-- /snippet -->

`--format=fuller` shows both identities. Asha wrote the change at 10:05; you committed this copy at 10:09. The last line of the message is the link to the original, with the full ID that begins `f98ffd3`.

**Part 2: three audits.** The question: is the fix in the 1.4 branch? First by commit ID. Predict.

**[PAUSE]**

<!-- snippet: ch10/backport/02-audit-by-id -->
```text
# Which branches contain the fix? Asking by commit ID finds only the original.
$ git branch --contains f98ffd3
  main
```
<!-- /snippet -->

Only `main`. That is engineer one from the hook. `--contains` follows ancestry, and the original commit is not an ancestor of the release branch; its copy is.

Second, by the recorded line.

<!-- snippet: ch10/backport/03-audit-by-trailer -->
```text
$ git log --all --oneline --grep='cherry picked from commit f98ffd3'
c308105 Reject empty prompts before calling the model
$ git branch --contains $(git log --all --format=%h --grep='cherry picked from commit f98ffd3')
* release/1.4
```
<!-- /snippet -->

`git log --all --grep` finds commit `c308105`, and `git branch --contains` on that commit prints `release/1.4`. That is a proof: a commit on the release states that it is a copy of `f98ffd3`.

Third, by patch ID. Predict the mark in front of the fix.

**[PAUSE]**

<!-- snippet: ch10/backport/04-audit-by-patch -->
```text
$ git cherry -v release/1.4 main
+ 6db3c0c6eace6d80b965fbca258fd96d13ad0e76 Start 1.5 development
+ ca6dd4819cdc3b57d478ca0a5ebc7b9c3c8c3e6c Add streaming client
+ f98ffd3d15c63376ff2fe882f990e11ff6722de6 Reject empty prompts before calling the model
+ 0cca736b9a1a5fe9a95303513732a6c623631f05 Document the streaming client
```
<!-- /snippet -->

A plus sign: "no equivalent on the release". And here that is wrong. That is engineer two. The release differs from `main` in a line inside the hunk's context, `MAX_RETRIES = 3`, so the diff of the copy is not textually the diff of the original, and their patch IDs differ. A context line was enough. Patch comparison finds exact copies only; the `-x` line survives adaptation.

**Part 3: duplicates.** `labs/run ch10/duplicates`. A release branch whose own commit lies outside the context of the fix, so that the copy is exact.

<!-- snippet: ch10/duplicates/01-graph -->
```text
$ git log --oneline --graph --decorate --all
* c84bed2 (HEAD -> release/1.4) Reject empty prompts before calling the model
* f395bc9 Raise the timeout to 60 seconds on the 1.4 line
| * 0cca736 (main) Document the streaming client
| * f98ffd3 Reject empty prompts before calling the model
| * ca6dd48 Add streaming client
| * 6db3c0c Start 1.5 development
|/  
* 93787ec Add model client
```
<!-- /snippet -->

The fix is `f98ffd3` on `main` and `c84bed2` on the release.

<!-- snippet: ch10/duplicates/02-cherry -->
```text
$ git cherry -v release/1.4 main
+ 6db3c0c6eace6d80b965fbca258fd96d13ad0e76 Start 1.5 development
+ ca6dd4819cdc3b57d478ca0a5ebc7b9c3c8c3e6c Add streaming client
- f98ffd3d15c63376ff2fe882f990e11ff6722de6 Reject empty prompts before calling the model
+ 0cca736b9a1a5fe9a95303513732a6c623631f05 Document the streaming client
$ git cherry -v main release/1.4
+ f395bc9ef18134d47129560a98d5bc6c5d2b32ef Raise the timeout to 60 seconds on the 1.4 line
- c84bed2a3af7e44ee969c4b890987cfa6e76769e Reject empty prompts before calling the model
```
<!-- /snippet -->

This time `git cherry` marks the fix with a minus, in both directions: an equivalent exists on the other side.

<!-- snippet: ch10/duplicates/03-cherry-mark -->
```text
$ git log --oneline --left-right --cherry-mark release/1.4...main
= c84bed2 Reject empty prompts before calling the model
< f395bc9 Raise the timeout to 60 seconds on the 1.4 line
> 0cca736 Document the streaming client
= f98ffd3 Reject empty prompts before calling the model
> ca6dd48 Add streaming client
> 6db3c0c Start 1.5 development
```
<!-- /snippet -->

Read the markers. Less-than: a commit only on the left side, the release. Greater-than: only on the right, `main`. Equals: a commit whose change also exists on the other side. Two equals lines, one pair.

<!-- snippet: ch10/duplicates/04-cherry-pick -->
```text
$ git log --oneline --left-right --cherry-pick release/1.4...main
< f395bc9 Raise the timeout to 60 seconds on the 1.4 line
> 0cca736 Document the streaming client
> ca6dd48 Add streaming client
> 6db3c0c Start 1.5 development
```
<!-- /snippet -->

`--cherry-pick` leaves the pairs out, which gives the real difference between the two lines. For "what is on `main` that the release still lacks", add `--right-only`.

The evidence underneath:

<!-- snippet: ch10/duplicates/05-patch-id -->
```text
$ git show main~1 | git patch-id --stable
25663a50190a2730649d2f06cd81f82ff10a1575 f98ffd3d15c63376ff2fe882f990e11ff6722de6
$ git show release/1.4 | git patch-id --stable
25663a50190a2730649d2f06cd81f82ff10a1575 c84bed2a3af7e44ee969c4b890987cfa6e76769e
```
<!-- /snippet -->

The same patch ID in the first column, two commit IDs in the second.

**Part 4: when the two lines meet again.** Merge the release branch back into `main`. Both sides contain the fix. Predict: conflict or clean? And how many times does the fix's subject appear in the log afterwards?

**[PAUSE]**

<!-- snippet: ch10/duplicates/06-merge -->
```text
$ git switch main
Switched to branch 'main'
$ git merge -m "Merge branch release/1.4 into main" release/1.4
Auto-merging src/client.py
Merge made by the 'ort' strategy.
 src/client.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate -7
*   cf36074 (HEAD -> main) Merge branch release/1.4 into main
|\  
| * c84bed2 (release/1.4) Reject empty prompts before calling the model
| * f395bc9 Raise the timeout to 60 seconds on the 1.4 line
* | 0cca736 Document the streaming client
* | f98ffd3 Reject empty prompts before calling the model
* | ca6dd48 Add streaming client
* | 6db3c0c Start 1.5 development
|/  
```
<!-- /snippet -->

Clean. Both sides made the identical change, and identical changes do not conflict; that is a row of the three-way rule table. The merge's stat shows only the release's own change.

<!-- snippet: ch10/duplicates/07-twice-in-history -->
```text
$ git log --oneline --grep="Reject empty prompts"
c84bed2 Reject empty prompts before calling the model
f98ffd3 Reject empty prompts before calling the model
```
<!-- /snippet -->

The history now holds the change twice, once per ID. That is the third of this chapter's CTO questions, "the log showed the same commit title twice, did something go wrong?", and the answer is: nothing went wrong.

It becomes a problem when a copy was adapted. Then the two sides changed the same lines differently, and the merge either conflicts or, with unlucky context, combines them in a way nobody reviewed.

**Part 5: revert, the inverse.** `labs/run ch10/revert-inverse`. The release has the backported fix at its tip.

<!-- snippet: ch10/revert-inverse/01-before -->
```text
$ git log --oneline --decorate -3
4f88542 (HEAD -> release/1.4) Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
93787ec Add model client
$ git rev-parse HEAD~1^{tree}
c0427e5100e84ffed7a94307938f8c547a0919d6
```
<!-- /snippet -->

Note the tree of the commit before the backport: it begins `c0427e5`. Now predict the tree of a revert with `git merge-tree`, using the inputs from the table: base is the commit to undo, ours is HEAD, theirs is its parent.

<!-- snippet: ch10/revert-inverse/02-predict -->
```text
# Base: the commit to undo (HEAD). Ours: HEAD. Theirs: the parent of the commit to undo.
$ git merge-tree --write-tree --merge-base=HEAD HEAD HEAD~1
c0427e5100e84ffed7a94307938f8c547a0919d6
```
<!-- /snippet -->

The same tree ID.

<!-- snippet: ch10/revert-inverse/03-revert -->
```text
$ git revert --no-edit HEAD
[release/1.4 57c5a52] Revert "Reject empty prompts before calling the model"
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 2 deletions(-)
$ git rev-parse HEAD^{tree}
c0427e5100e84ffed7a94307938f8c547a0919d6
$ git log -1 --format=%B
Revert "Reject empty prompts before calling the model"

This reverts commit 4f885421c38859bdc722fa1961433160eca5ab6a.
```
<!-- /snippet -->

The predicted tree, the tree of the revert commit, and the tree of the commit before the backport are one and the same. A revert is a new commit like any other. It uses the same sequencer, with `REVERT_HEAD` in place of `CHERRY_PICK_HEAD` and the same four ways out, and it needs `-m` for a merge commit for the same reason.

<!-- snippet: ch10/revert-inverse/04-after -->
```text
$ git log --oneline --decorate -4
57c5a52 (HEAD -> release/1.4) Revert "Reject empty prompts before calling the model"
4f88542 Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
93787ec Add model client
```
<!-- /snippet -->

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Concluding "not backported" from `git branch --contains <original>`.** Root cause: ancestry follows parent links, and a copy has no parent link to its original.
2. **Concluding "not backported" from a plus sign in `git cherry`.** Root cause: patch IDs pair textually identical diffs; an adapted copy, or one whose context differs, has another patch ID.
3. **Backporting without `-x`.** Root cause: the message line is the only record of the relationship that survives adaptation and travels with the history.
4. **Treating "applied cleanly" as "works on the release".** Root cause: the merge compared text in the files the commit touches; whether the release has what the fix depends on was never checked.
5. **Generating a changelog from `git log` across lines that exchanged picks.** Root cause: each picked change is two commits; anything that counts commits counts it twice unless `--cherry-pick` is used.

## PRODUCTION EXAMPLE

For an ML service the maintenance line is often the version that a customer's evaluation was signed off against. A backport changes that line.

The textbook's advice: record it where the sign-off lives. The `-x` line gives the auditor the original commit, and the original commit leads to the review and the tests. That is a chain from "what is running at the customer" to "who reviewed this change and what was tested", and it exists only because one option was typed.

The second point is for tooling. Anything that counts commits double-counts duplicates: a changelog generated from `git log`, a "commits since last release" metric. Generate such lists with `--cherry-pick`, and remember its limit: an adapted backport is invisible to patch comparison. Lab 10.3 works through that case.

So a release team's standing answer to "is the fix in the release" has an order. First the `-x` line. Then patch comparison, read with its limit in mind. And when both are silent, the content of the file and a test.

## PRACTICE EXERCISE

Do Lab 10.1, "Backport a fix with `-x`", in [`lab-manual/m10-cherry-pick-ranges.md`](../../lab-manual/m10-cherry-pick-ranges.md).

Predict before each audit command:

- What will `git branch --contains <original>` print after the backport, and why?
- What will a search for the recorded line find?
- For `git cherry`: plus or minus in front of the fix? Decide by looking at whether anything in the hunk, including its context, differs between the two branches.

And one prediction for step 3 of the procedure: the pick applies cleanly. Is the release branch therefore correct? Say how you would find out.

The challenge is Exercise 10.10, Level 5, ""the fix is in the release" and "the fix was never backported"", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q159: "A fix was backported with `-x`. Give three ways to establish that the release branch contains it, and say which of them can give a wrong answer and why."

Answer aloud first. A strong answer names three methods that read three different kinds of evidence, and for each says what it reads. Then, for the "wrong answer" part, it is specific about direction: which method says "no" when the truth is "yes", under which condition, and whether any of them can say "yes" when the truth is "no". It closes with the order in which you would use them during an incident, and what you check when none of them gives a clear answer.

## RECAP

You should now be able to say:

A backport is a cherry-pick onto a maintenance branch with `-x`, followed by a build and test there, because a clean pick says only that the text merged. Ancestry does not know about copies, so `--contains` on the original says no. The recorded "cherry picked from" line proves the relationship and survives adaptation. Patch IDs pair exact copies only, which is what `git cherry` and `--cherry-mark` report, and `--cherry-pick` removes such pairs from a comparison. Merging two lines that exchanged an exact pick is clean and leaves the change in history twice. A revert is the same three-way merge with base and theirs exchanged.

## HOMEWORK

Read sections 10.9 to 10.14 of [Chapter 10](../../textbook/ch10-cherry-pick.md) and do the Practice section 10.16, including Lab 10.3, "Detect duplicates with `git cherry`", in [`lab-manual/m10-cherry-pick-ranges.md`](../../lab-manual/m10-cherry-pick-ranges.md).

Do Exercise 10.6, Level 2, "backport, then merge the release back", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

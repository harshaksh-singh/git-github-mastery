# V172: One release and one hotfix under two strategies, and which way a fix travels

- **Part.** 8, Professional practice
- **Module.** 32
- **Planned minutes.** 26
- **Prerequisites.** V063, V171
- **Textbook sections.** [Chapter 27](../../textbook/ch27-open-source-team-workflows.md), sections 27.9 and 27.10
- **Demo scripts.** `labs/ch27/github-flow.sh`, `labs/ch27/release-branch.sh`, `labs/ch27/fix-direction.sh`, `labs/ch27/mixed-directions.sh`

## HOOK

**[ON SCREEN]** "A hotfix went out as 1.4.1. Why did 1.5.0 ship the same bug again?"

A customer upgrades from 1.4.1 to 1.5.0 and reports a bug that was fixed two months ago. Support checks the release notes: the fix is listed under 1.4.1. Engineering checks the code of 1.5.0: the faulty line is there. Nobody reverted anything. Nobody force-pushed.

The answer is precise, and you'll be able to produce it from the repository alone: the fix was committed on the release branch and never reached `main`, and nobody ran the one-line check that would have listed it. Keep that one-line check in mind. You'll watch it print the missing fix.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In video 171 you saw the models as drawings. Today the same project is run through one release and one hotfix twice, with real commits, and you compare the two histories by asking the tags. A tag is a name fixed on one commit, and here every release is a tag. A hotfix is an urgent fix to something already released.

The scenario is fixed. `promptgate` 1.3.0 is released. Two pull requests are merged, and 1.4.0 is released. A third pull request, a batch endpoint, is merged afterwards. Then production reports that suspended tenants, whose limit is 0, aren't blocked, and a fix must ship as 1.4.1.

The second half is about direction. Once there are two lines of development, a fix has to exist on both, and there are two legitimate conventions for how it gets there. They're opposites. Each gives you an invariant, a statement that must always hold, and one command can test it. From video 63 you know cherry-pick, `-x` and patch IDs, which carry the second convention. A cherry-pick copies one commit's change onto another branch as a new commit with a new ID. The `-x` option records the original's ID in the copy's message. And a patch ID is a hash of the change itself, by which Git recognizes the same change under another commit ID.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Run one release and one hotfix under GitHub Flow and under a release-branch strategy and compare the histories.
2. Say what ships in each case and prove it from tags.
3. State the two conventions for the direction of a fix and the invariant each lets you test.
4. Detect a fix that was forgotten on one line of development.
5. Explain what goes wrong when both directions are mixed in one repository.

## CONCEPT

**Two strategies, one sentence.** The same three features and the same one-line fix produce two different answers to "what does the patch release contain", and the difference is where the release tag lives.

Under strategy A, GitHub Flow, releases are tags on `main`. A hotfix is the next deployment of `main`. Under strategy B there is a release branch. The fix is made on `main` first and cherry-picked down, and the tag is on the release branch.

**Inside `.git`.** Strategy A created two tag objects and moved `refs/heads/main`. Strategy B created the same two tags, one extra ref `refs/heads/release/1.4`, and one extra commit object. A "release" in both is `refs/tags/v1.4.1` naming an annotated tag object that names a commit.

**[ON SCREEN]** The comparison table of section 27.9. Show it after the two demos; it is the summary.

| Question | A: GitHub Flow with tags | B: release branch |
|---|---|---|
| Long-lived refs | `main` | `main` and one `release/x.y` per supported version |
| Contents of a patch release | everything merged to `main` since the previous tag | only what was picked onto the release branch |
| Commits per fix | one | two (one per line), linked by patch ID and the `-x` line |
| Can you patch 1.4 after 1.5 exists? | no: there is no line for 1.4 to stand on, short of creating a branch at the old tag | yes |
| Extra failure mode | a half-finished feature on `main` blocks an urgent release unless it is behind a flag | a fix that reaches one line and not the other |
| CI cost | one branch | every supported release branch needs its own pipeline |

One sentence from the textbook belongs on this table: strategy A can become strategy B on the day it is needed. `git switch -c release/1.4 v1.4.0` creates the missing line at the tag, after the fact. That's an argument for starting with the simpler model and adding release branches when a second live version appears.

**GitHub, not Git.** A GitHub release is an object layered on a Git tag. Creating one in the web interface or with `gh release create` can create the tag on the server, and your clone doesn't have it until you fetch tags. With immutable releases enabled, the tag and its assets are locked and the tag name can't be reused.

**Which way does a fix travel?** There are two legitimate conventions and they're opposites: commit the fix on the oldest branch that needs it and merge upward, or commit it on `main` first and cherry-pick it down.

**[ANIMATION]** merge: three-way release/1.4 into main common=518d961 main_only=a1351be feature_only=64610e3 merge_id=1a91aff base=tag_v1.4.0 title=Merge_upward:_one_commit,_carried_by_a_merge say_merge=One_fix,_one_ID:_64610e3_is_now_in_both_lines

**Merge upward.** The Git project's own workflow document states it: "Always commit your fixes to the oldest supported branch that requires them. Then (periodically) merge the integration branches upwards into each other." The fix is one commit with one ID, and the merge commit is, in that document's word, a "promise" that everything from the older branch is included in the newer one. The invariant: each release branch is an ancestor of the next line. Ancestor means that you reach it by following parents back from the newer line.

**[ANIMATION]** end

**Fix on main first, cherry-pick down.** The trunk-based development site, Google's published practice, Microsoft's Release Flow and GitLab's rules all prescribe this. The stated reason is the failure it prevents: a fix made on the release branch can be forgotten on the trunk, and the next release then regresses. The invariant can't be ancestry, because the release branch is never merged back. It's a comparison of patches: every change on the release branch has an equivalent on `main`.

**[ON SCREEN]** The trade-off table of section 27.10.

| | Merge upward | Fix on main, pick down |
|---|---|---|
| Identity of the fix | one commit, one ID | one commit per line; linked by patch ID and the `-x` line |
| "Is the fix in release X?" | `git branch --contains <id>` answers for every line | must search by patch or by message on each line |
| What a forgotten step causes | the fix is missing from `main` until the next upward merge, which brings it along with everything else | nothing dangerous if the pick is forgotten: the old release lacks a fix it never had |
| Extra baggage | merging the release branch upward brings **everything** on it, including version bumps and release-only changes, which then conflict or must be neutralized | the patch-ID check breaks when the port needed conflict resolution, because the diffs then differ |
| Fits | projects with several maintained lines and maintainers who curate merges (Git itself) | trunk-based teams with late-cut, short-lived release branches |

Quick quiz, with the table on screen. Under pick down, somebody forgets the pick. What happens? A, the next release ships the bug again. B, nothing dangerous. Your answer?

**[PAUSE]**

B. That's the third row: the old release lacks a fix it never had. Under merge upward, the forgotten step is the merge, and the fix is then missing from `main` until the next upward merge.

**The limits of the checks.** Two, and you need both for the interview question. A cherry-pick that needed a conflict resolution has a different patch ID, so `--cherry-pick` reports it as missing although a human ported it. The `-x` line is then the evidence. And an upward merge resolved by discarding the release branch's side satisfies the ancestry test while the fix is absent. `git log --remerge-diff` shows what the resolver changed.

## MENTAL MODEL

A picture helps. The textbook's analogy: a textbook in print in two editions. You can correct the older edition and let the correction flow into the newer one. Or you can correct the current manuscript and copy the correction by hand into the older edition.

The first is merge upward: one correction, and the newer edition includes the older one whole. The second is pick down: two corrections that say the same thing, and a note in the margin of the copy that says where it came from. That note is the `-x` line.

Where the analogy breaks: Git can do the first mechanically, with a merge, only while the newer line still contains the older one as an ancestor. Once a line has stopped being an ancestor, or once the two conventions have been mixed, the merge is no longer a clean inclusion.

And one sentence to keep under all of it, from the root-cause box: nothing in Git propagates a fix between branches. Branches are independent refs. "This fix belongs everywhere" is knowledge held by the team, not by the repository.

## DIAGRAM

**[DIAGRAM]** A new drawing: two release lines and `main`, drawn twice. First with upward merges. The fix F is committed once, on the oldest line. Each merge M carries it one line up.

```text
  Merge upward: one commit, carried by merges

    ---o-----------F                          release/1.4
        \           \
         o---o-------M1                       release/1.5
              \        \
               o---o----M2---o                main

    invariant: release/1.4 is an ancestor of release/1.5, which is an ancestor of main
```

Then with downward picks. F is committed on `main`. The two copies, F prime and F double prime, are separate commits with their own IDs. The dashed lines aren't in the repository. They stand for "same change", which Git can only infer from the patch ID or read from the `-x` line.

```text
  Fix on main, pick down: one commit per line, linked only by patch ID and the -x line

    ---o-----------F''                        release/1.4
        \          :
         o---o-----F'                         release/1.5
              \    :
               o---F---o                      main

    invariant: no change on a release branch lacks an equivalent on main
```

**[ON SCREEN]** After the "forgotten" demo, the root-cause box of section 27.10.

```text
Observed behavior : v1.5.0 ships a bug that v1.4.1 fixed.
Git state         : commit 70188ed is reachable from release/1.4 and from tag v1.4.1 only.
                    main and v1.5.0 do not contain it and contain no commit with the same patch.
Mechanism         : a commit on one branch is on another branch only if somebody merges or
                    cherry-picks it. Nothing in Git propagates a fix between branches.
Root cause        : the fix was committed on the release branch, and the step that carries it
                    to main (a merge upward, or a port) was a human step that nobody took.
Why Git does this : branches are independent refs. "This fix belongs everywhere" is knowledge
                    held by the team, not by the repository.
Correct fix       : port the commit to main (git cherry-pick -x 70188ed, or merge release/1.4
                    into main if your convention is merge-upward), then release 1.5.1. Do not
                    move the v1.5.0 tag: people already have it.
Prevention        : make the check a release gate. Either "release/x is an ancestor of main"
                    (merge-upward), or "git log --cherry-pick --right-only main...release/x is
                    empty" (pick-down). Both are one command with a testable result.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Four replays. Start with `labs/run ch27/github-flow`.

Into the lab, for four replays. Strategy A comes first.

**Step 1: strategy A, the release.** Two pull requests are merged. `main` is deployable, so the release is a tag on `main`. 🟢 SAFE: an annotated tag adds a tag object and a ref.

```bash
git log --oneline --graph --decorate
git tag -a v1.4.0 -m "promptgate 1.4.0"
```

<!-- snippet: ch27/github-flow/01-release -->
```text
# Two pull requests are merged. main is deployable, so the release is a tag on main:
$ git log --oneline --graph --decorate
*   518d961 (HEAD -> main) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
* |   a7ccb4b Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
| * b00109d Stream tokens to the client
|/  
* b6e2f58 (tag: v1.3.0) Add per-tenant rate limits
* 9df3d07 Add gateway skeleton
$ git tag -a v1.4.0 -m "promptgate 1.4.0"
```
<!-- /snippet -->

**Step 2: `main` moves on.** Pull request 43 lands after the release.

<!-- snippet: ch27/github-flow/02-main-moves-on -->
```text
# After the release, pull request #43 lands. main is ahead of what customers run:
$ git log --oneline --decorate v1.4.0..main
a1351be (HEAD -> main) Merge pull request #43 from feature/batch-api
5928b76 Add batch endpoint
```
<!-- /snippet -->

`main` is ahead of what customers run, by the batch endpoint.

**Step 3: the hotfix.** 🟡 CAUTION: a merge moves `main`.

```bash
git switch -c hotfix/suspended-tenant main
git diff
git commit -q -am "Fix limit 0 being treated as unlimited"
git switch -q main
git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
git branch -d hotfix/suspended-tenant
git tag -a v1.4.1 -m "promptgate 1.4.1"
```

<!-- snippet: ch27/github-flow/03-hotfix -->
```text
# Production reports that suspended tenants (limit 0) are not blocked.
$ git switch -c hotfix/suspended-tenant main
Switched to a new branch 'hotfix/suspended-tenant'
$ git diff
diff --git a/gateway/limits.py b/gateway/limits.py
index bf5d3ec..18f6e2c 100644
--- a/gateway/limits.py
+++ b/gateway/limits.py
@@ -2,5 +2,5 @@ LIMITS = {"default": 60}
 
 
 def allowed(tenant, used):
-    limit = LIMITS.get(tenant) or LIMITS["default"]
+    limit = LIMITS.get(tenant, LIMITS["default"])
     return used < limit
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q main
$ git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -d hotfix/suspended-tenant
Deleted branch hotfix/suspended-tenant (was 9a75273).
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
```
<!-- /snippet -->

Look at the diff first. The bug is the `or`: a limit of `0` is falsy in Python, so the suspended tenant silently got the default limit. The fix is one line.

**Step 4: what ships.** Predict before the output: what does a customer get when moving from `v1.4.0` to `v1.4.1`? Say it out loud.

**[PAUSE]**

```bash
git log --oneline --no-merges v1.4.0..v1.4.1
git diff --stat v1.4.0 v1.4.1
git branch --list
```

<!-- snippet: ch27/github-flow/05-what-ships -->
```text
# What does a customer get when moving from v1.4.0 to v1.4.1?
$ git log --oneline --no-merges v1.4.0..v1.4.1
9a75273 Fix limit 0 being treated as unlimited
5928b76 Add batch endpoint
$ git diff --stat v1.4.0 v1.4.1
 gateway/batch.py  | 2 ++
 gateway/limits.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git branch --list
* main
```
<!-- /snippet -->

Two commits and two files. Version 1.4.1 contains the fix and the batch endpoint. Under GitHub Flow that is by design: `main` is what you ship, and everything merged since the last tag ships with the next one. For a hosted service with one live version this is fine, and usually desirable. For a customer who pinned 1.4 and expects a patch release to contain only fixes, it's a breach of what the version number promised: Semantic Versioning reserves the third number for backward-compatible bug fixes.

**Step 5: strategy B.** Replay `labs/run ch27/release-branch`. The same two pull requests are merged. The release gets a branch of its own.

```bash
git switch -c release/1.4 main
git tag -a v1.4.0 -m "promptgate 1.4.0"
git switch -q main
```

<!-- snippet: ch27/release-branch/01-cut -->
```text
# The same two pull requests are merged. The release gets a branch of its own:
$ git switch -c release/1.4 main
Switched to a new branch 'release/1.4'
$ git tag -a v1.4.0 -m "promptgate 1.4.0"
$ git switch -q main
```
<!-- /snippet -->

`main` moves on with the batch endpoint, as before. The fix is made and reviewed on `main` first.

<!-- snippet: ch27/release-branch/03-fix-on-main -->
```text
# The fix is made and reviewed on main first:
$ git switch -c hotfix/suspended-tenant main
Switched to a new branch 'hotfix/suspended-tenant'
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q main
$ git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -d hotfix/suspended-tenant
Deleted branch hotfix/suspended-tenant (was bc59804).
```
<!-- /snippet -->

The fix on `main` is `bc59804`. Now it is copied down. 🟡 CAUTION: `git cherry-pick -x <commit>` creates a new commit on the current branch with the same change and moves the branch to it.

```bash
git switch -q release/1.4
git cherry-pick -x bc59804
git tag -a v1.4.1 -m "promptgate 1.4.1"
git log -1 --format=%B
```

<!-- snippet: ch27/release-branch/04-backport -->
```text
# Then the one commit is copied to the release branch and released from there:
$ git switch -q release/1.4
$ git cherry-pick -x bc59804
[release/1.4 996796d] Fix limit 0 being treated as unlimited
 Date: Mon Sep 7 10:24:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
$ git log -1 --format=%B
Fix limit 0 being treated as unlimited

(cherry picked from commit bc5980493f22fc60a53dcc923eb9941b88e13284)
```
<!-- /snippet -->

The last lines are the message of the new commit, `996796d`. The `-x` added "(cherry picked from commit ...)". That line is the only durable record that `996796d` on the release branch and `bc59804` on `main` are the same fix.

**Step 6: what ships, and where the fix is.**

<!-- snippet: ch27/release-branch/06-what-ships -->
```text
# What does a customer get when moving from v1.4.0 to v1.4.1?
$ git log --oneline --no-merges v1.4.0..v1.4.1
996796d Fix limit 0 being treated as unlimited
$ git diff --stat v1.4.0 v1.4.1
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

One commit, one file. Version 1.4.1 contains the fix and nothing else. The batch endpoint will ship in 1.5.0.

```bash
git branch --contains bc59804
git branch --contains v1.4.1
git log --oneline --cherry-mark --left-right --no-merges main...release/1.4
git cherry -v main release/1.4
```

<!-- snippet: ch27/release-branch/07-where-is-the-fix -->
```text
# The fix now exists as two commits with different IDs:
$ git branch --contains bc59804
  main
$ git branch --contains v1.4.1
* release/1.4
# Git can still pair them, because they introduce the same change (the same patch ID):
$ git log --oneline --cherry-mark --left-right --no-merges main...release/1.4
= 996796d Fix limit 0 being treated as unlimited
= bc59804 Fix limit 0 being treated as unlimited
< 7a47553 Add batch endpoint
$ git cherry -v main release/1.4
- 996796dac13d83f14fb959c959ce4080fb1fc11f Fix limit 0 being treated as unlimited
```
<!-- /snippet -->

`git branch --contains` gives a different answer for each ID: one says `main`, the other says `release/1.4`. The fix exists as two commits. Git can still pair them, because they introduce the same change: the two lines marked with an equals sign.

Try it now, for thirty seconds. In any repository you have, type `git log --oneline`, copy one ID, and type `git branch --contains` with that ID. Both commands only read. I'll wait.

**[PAUSE]**

The answer lists the branches from which that commit can be reached. It's the question "is the fix in this line?", asked of one ID.

**Step 7: the two conventions side by side.** Replay `labs/run ch27/fix-direction`. The starting state is the same in all three parts: `release/1.4` at the 1.4.0 tag, and `main` one feature ahead. Convention A, merge upward.

```bash
git switch -q release/1.4
git commit -q -am "Fix limit 0 being treated as unlimited"
git tag -a v1.4.1 -m "promptgate 1.4.1"
git switch -q main
git merge -m "Merge branch release/1.4 into main" release/1.4
```

<!-- snippet: ch27/fix-direction/02-merge-upward -->
```text
# Convention A: commit the fix on the oldest branch that needs it...
$ git switch -q release/1.4
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
# ...then merge that branch upward into main:
$ git switch -q main
$ git merge -m "Merge branch release/1.4 into main" release/1.4
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate --all -6
*   1a91aff (HEAD -> main) Merge branch release/1.4 into main
|\  
| * 64610e3 (tag: v1.4.1, release/1.4) Fix limit 0 being treated as unlimited
* |   a1351be Merge pull request #43 from feature/batch-api
|\ \  
| |/  
|/|   
| * 5928b76 Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
```
<!-- /snippet -->

<!-- snippet: ch27/fix-direction/03-one-commit -->
```text
# One commit, one ID, contained in both lines:
$ git branch --contains v1.4.1
* main
  release/1.4
$ git log --oneline main..release/1.4
# Empty: everything on the release branch is in main. That is an invariant you can test:
$ git merge-base --is-ancestor release/1.4 main
[exit status: 0]
```
<!-- /snippet -->

One commit, `64610e3`, contained in both branches. `git merge-base --is-ancestor release/1.4 main` exits with status 0, and an exit status is something a CI job, an automated check, can test.

Convention B, pick down. Predict: what will the same ancestry test return here? Say it out loud.

**[PAUSE]**

<!-- snippet: ch27/fix-direction/04-pick-down -->
```text
$ cd ../pick-down
# Convention B: commit the fix on main first...
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q release/1.4
# ...then copy it down to the release branch:
$ git cherry-pick -x main
[release/1.4 a2d7a91] Fix limit 0 being treated as unlimited
 Date: Mon Sep 7 10:36:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
$ git log --oneline --graph --decorate --all -6
* a2d7a91 (HEAD -> release/1.4, tag: v1.4.1) Fix limit 0 being treated as unlimited
| * d9474f7 (main) Fix limit 0 being treated as unlimited
| * a1351be Merge pull request #43 from feature/batch-api
|/| 
| * 5928b76 Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
```
<!-- /snippet -->

<!-- snippet: ch27/fix-direction/05-two-commits -->
```text
# Two commits, two IDs. The release branch is never merged into main:
$ git merge-base --is-ancestor release/1.4 main
[exit status: 1]
# The check that replaces the ancestry test compares patches, not IDs:
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
# Empty: every change on the release branch has an equivalent on main.
```
<!-- /snippet -->

Two commits, `d9474f7` and `a2d7a91`. The ancestry test fails by design. What replaces it is `git log --cherry-pick --right-only main...release/1.4`, which lists the commits on the release branch that have no equivalent change on `main`. Empty means nothing is missing. The manual describes `--cherry-pick` as omitting "any commit that introduces the same change as another commit on the 'other side'" of a symmetric difference, and Git decides "the same change" by patch ID. If the two checks blur together at first, that's normal: one tests ancestry, the other compares patches.

**Step 8: the failure both conventions exist to prevent.** A fix made only on the release branch. Weeks later release 1.5 is cut from `main`.

<!-- snippet: ch27/fix-direction/06-forgotten -->
```text
$ cd ../forgotten
# The failure both conventions exist to prevent: a fix made only on the release branch.
$ git switch -q release/1.4
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
# Weeks later release 1.5 is cut from main:
$ git switch -q main
$ git tag -a v1.5.0 -m "promptgate 1.5.0"
$ git show v1.5.0:gateway/limits.py | grep "limit ="
    limit = LIMITS.get(tenant) or LIMITS["default"]
$ git show v1.4.1:gateway/limits.py | grep "limit ="
    limit = LIMITS.get(tenant, LIMITS["default"])
```
<!-- /snippet -->

The two `git show` lines are the hook of this video: `v1.5.0` has the `or` again. Predict: what will each of the two checks say?

**[PAUSE]**

<!-- snippet: ch27/fix-direction/07-detect -->
```text
# v1.5.0 ships the bug that v1.4.1 fixed. Either check finds it before the tag:
$ git merge-base --is-ancestor release/1.4 main
[exit status: 1]
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
70188ed Fix limit 0 being treated as unlimited
```
<!-- /snippet -->

The ancestry test exits with 1. The patch comparison prints one line, and that line names the forgotten fix: `70188ed`. There's the one-line check from the opening. Either check finds it before the tag. The root-cause box has the "Correct fix" line: port the commit, release 1.5.1, and don't move the `v1.5.0` tag, because people already have it.

**Step 9: mixing the directions.** Replay `labs/run ch27/mixed-directions`. The first fix went from `main` to `release/1.4` by cherry-pick. A second fix, on the neighbouring line of the same function, is made on the release branch.

<!-- snippet: ch27/mixed-directions/01-second-fix-on-release -->
```text
# The first fix went main -> release/1.4 by cherry-pick. The second is made on the release branch:
$ sed -i.bak "s/return used < limit/return max(used, 0) < limit/" gateway/limits.py && rm gateway/limits.py.bak
$ git commit -q -am "Clamp negative usage counters"
$ git log --oneline --graph --all -5
* 9e95016 Clamp negative usage counters
* 6b7ad03 Fix limit 0 being treated as unlimited
| * f2771f7 Fix limit 0 being treated as unlimited
| * a1351be Merge pull request #43 from feature/batch-api
|/| 
| * 5928b76 Add batch endpoint
|/  
```
<!-- /snippet -->

Then somebody carries it to `main` by merging the release branch upward. Predict: `main` never touched the second line. Will the merge be clean?

**[PAUSE]**

<!-- snippet: ch27/mixed-directions/02-merge-upward-conflicts -->
```text
# ...and somebody carries it to main by merging the release branch upward:
$ git switch -q main
$ git merge release/1.4
Auto-merging gateway/limits.py
CONFLICT (content): Merge conflict in gateway/limits.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git diff
diff --cc gateway/limits.py
index 18f6e2c,ca849ed..0000000
--- a/gateway/limits.py
+++ b/gateway/limits.py
@@@ -3,4 -3,4 +3,8 @@@ LIMITS = {"default": 60
  
  def allowed(tenant, used):
      limit = LIMITS.get(tenant, LIMITS["default"])
++<<<<<<< HEAD
 +    return used < limit
++=======
+     return max(used, 0) < limit
++>>>>>>> release/1.4
$ git merge --abort
```
<!-- /snippet -->

A conflict. The upward merge brought the picked copy of the first fix with it. Relative to the merge base, `main` changed one line and the release branch changed that line identically plus its neighbour, so the two changes overlap. Git dropped the identical line from the conflict and left the neighbouring line for a human, although `main` never touched it. `git merge --abort` returns to the state before the merge. A repository that mixes the directions satisfies neither check of this video and pays for it in conflicts like this one.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Promising a fix-only patch release under GitHub Flow.** Root cause: the release tag lives on `main`, so a patch release contains everything merged since the previous tag.
2. **Committing a fix on the release branch and stopping there.** Root cause: nothing in Git propagates a fix between branches; carrying it to `main` is a human step.
3. **Cherry-picking without `-x`.** Root cause: the copy has a new ID, and without the recorded line the link between the two commits exists only as a matching patch ID, which a conflict resolution destroys.
4. **Trusting the patch-ID check after a port that needed conflict resolution.** Root cause: the resolved diff differs from the original, so the check reports a ported fix as missing.
5. **Mixing merge-upward and pick-down in one repository.** Root cause: an upward merge brings the picked copies with it, so identical and neighbouring changes overlap and neither invariant holds.

## PRODUCTION EXAMPLE

Now, out of the lab. A team ships an inference SDK with two supported versions and uses the pick-down convention: fix on `main`, cherry-pick with `-x` to each supported release branch. During an urgent customer escalation an engineer fixes a tokenizer bug directly on `release/2.3`, tags 2.3.4 and goes home. Six weeks later 2.4.0 is cut from `main`.

This time nothing regresses, because the team had made the check a release gate after an earlier incident. The release job runs `git log --oneline --cherry-pick --right-only --no-merges main...release/2.3` and fails if it prints anything. It printed one line. The release manager ported the commit to `main` with `git cherry-pick -x`, the job went green, and 2.4.0 was tagged an hour late. The team also knows the gate's limit: when a port needed conflict resolution, the job prints the commit although it was ported, and a person confirms from the `-x` line.

## PRACTICE EXERCISE

Your turn. Do Lab 32.1, "One release and one hotfix under two strategies", in [`lab-manual/m32-branching-release-strategy.md`](../../lab-manual/m32-branching-release-strategy.md). Type it by hand in the lab shell. Your commit IDs will differ from the book where you make the commits yourself.

Before each of the two `git log --oneline --no-merges v1.4.0..v1.4.1` commands, write down the commits you expect to see. Before the lab's failure scenario, predict what each of the two checks will print. The lab's questions are answered in a separate file. Attempt them first.

The challenge is Exercise 32.5, Level 4, "Which fix is missing?", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q346: "State the two conventions for the direction of a fix. For each, give the invariant you can test and one way the test can mislead you."

**[PAUSE]**

Answer out loud. The question has a fixed shape: two conventions, and for each three things. A strong answer names each convention with the commit it produces, one ID or one per line. It gives each invariant as a command whose result a CI job can evaluate. And for each test it names a case where the result is wrong in a specific direction: one test can say "missing" for a fix that is present, the other can say "included" for a fix that is absent. Say which evidence you would then look at. Finish with the recommendation the textbook gives for every team: pick one direction and write it down.

## RECAP

Let's land this, in your own words.

- Under GitHub Flow a patch release is whatever `main` contains at the next tag; with a release branch it is only what was picked onto that branch.
- `git log --no-merges v1.4.0..v1.4.1` and `git diff --stat v1.4.0 v1.4.1` prove what shipped.
- Merge upward gives one commit and the invariant "the release branch is an ancestor of `main`"; pick down gives one commit per line and the invariant "no change on the release branch lacks an equivalent on `main`".
- A forgotten fix is found before the tag by either check; afterwards you port it and release again without moving the tag.
- Mixing the two directions breaks both invariants and produces conflicts on lines nobody changed twice.

## HOMEWORK

Read sections 27.9 and 27.10. Do Exercise 32.3, Level 2, "What does the patch release contain?", and Exercise 32.4, Level 3, "Two directions, one repository", both in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

Today you proved from tags what two strategies ship, and you can now catch a forgotten fix with one command. Run the lab by hand once. The next video adds feature flags, merge queues and stacked changes, and asks what the evidence does and doesn't show. Until then, look at the state first and type second. See you in the next one.

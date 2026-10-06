# V189: Incident drills: a force push to the wrong branch, and rewritten production history

- **Part.** 9, Production debugging and incident response
- **Module.** 37
- **Planned minutes.** 26
- **Prerequisites.** V042, V131, V188
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.6 and 30.8
- **Demo scripts.** `labs/incidents/solve-02-force-push-wrong-branch.sh` (snippets `01-observe` to `08-verify`), `labs/incidents/solve-04-production-history-rewritten.sh` (snippets `01-observe` to `08-verify`)

## HOOK

**[ON SCREEN]** "`main` was force-pushed ten minutes ago." And, from another team: "The release job refuses to deploy. It says the deployed commit is not an ancestor of `production`."

In both cases a shared branch on the server now points at a history that isn't the one everybody had. A branch is a named line of commits, the saved snapshots of a project. A force push overwrites the server's branch, so commits can drop off it. And "not an ancestor" means that the branch's history no longer contains the deployed commit. In both cases the obvious repair is another forced push, to put the old history back.

That repair is itself a rewrite of a shared branch. Done without two checks, it becomes the second incident: it removes whatever a colleague has legitimately pushed or built on top since. Today you learn the two checks, and what the restoring command looks like when it's done properly. Guess them now.

A first question, before any cause is named. By default, Git on the server keeps no record of where a branch used to point. So who, or what, could still know the old position? Name two. Say them out loud.

**[PAUSE]**

**[ANIMATION]** cards: id=who question=Who_could_still_know_the_old_position? cards=a_teammate's_clone_that_hasn't_fetched_since|a_clone_that_has_fetched:its_reflog_keeps_the_previous_value title=The_server_keeps_no_record at_1=2 at_2=22

A teammate's clone that hasn't fetched since. And a clone that has fetched: its reflog, Git's local record of where a ref has been, keeps the previous value. A clone is each person's own copy of the repository.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a debrief of Incident 2, [`incidents/02-force-push-wrong-branch`](../../incidents/02-force-push-wrong-branch/SYMPTOMS.md), and Incident 4, [`incidents/04-production-history-rewritten`](../../incidents/04-production-history-rewritten/SYMPTOMS.md). You must have generated and attempted both, with a command log and a severity rating. Have you? If you haven't, stop the video here.

**[PAUSE]**

The causes are named in the next section.

These are the first drills in which the damaged state is on the server. That changes where the evidence is. From video 185: a bare repository keeps no reflog, so the history of a server-side branch exists only as the sum of what the clones remember, plus whatever the platform records. From video 42 you know what a forced push destroys and what a lease checks. From video 131 you know the rule that would have refused these pushes.

Both incidents are SEV 2 on the scale of video 185, and the second one is the textbook's example of rating by the window: it shipped nothing.

## LEARNING OBJECTIVES

After this video you can:

1. Find out what a forced push replaced and who still has the old commits.
2. Check two things before restoring: what has been built on the new tip, and who has fetched it.
3. Restore the branch without losing a legitimate commit made after the rewrite.
4. Realign teammates' clones.
5. Walk from the root cause to controls on several layers.

## CONCEPT

**[ANIMATION]** cards: id=witnesses cards=a_clone_that_hasn't_fetched_since:its_remote-tracking_branch_still_holds_the_old_value|a_clone_that_has_fetched:its_reflog_has_the_entry_before_the_forced_update|anything_that_recorded_the_commit_by_ID:a_tag,_or_a_deployment_record numbered=on title=Three_kinds_of_witness at_1=22 at_2=48 at_3=74

**[ANIMATION]** step: 3

**Witnesses.** When a server branch has been replaced, the old value is known to three kinds of witness. A clone that hasn't fetched since: its remote-tracking branch, the clone's record of the server's branch, still holds the old value. A clone that has fetched: the reflog of its remote-tracking branch holds the previous value as the entry before the forced update. And anything that recorded the commit by ID: a tag, which is a fixed name for one commit, or a deployment record.

`git status` isn't a witness of the present. It reports on `origin/main`, your clone's memory. `git ls-remote origin` asks the server.

**[ANIMATION]** gates: id=cause2 packet=git_push_--force gates=the_upstream:done:one_clone:feature_branch_follows_origin/main|push.default=upstream:done:one_clone:a_bare_push_updates_the_upstream|--force:bypass:one_clone:no_fast-forward_check|the_server:pass:GitHub:no_rule_refused_it result=main_is_replaced title=Incident_2:_the_root_cause at_1=5 at_2=28 at_3=50 at_4=62 at_result=68

**[ANIMATION]** step: result

**Incident 2: the root cause.** The feature branch was created from `origin/main` and so has `origin/main` as its upstream, the server branch it follows. With `push.default=upstream`, a bare `git push` updates the upstream branch whatever its name. `--force` removed the fast-forward check, the rule that a push may only add to a branch. The server accepted a forced update of `main`. The default, `simple`, would have refused. Layers: Git configuration in one clone, and a missing GitHub rule.

You met the first half of this in video 181: a branch created from a remote-tracking branch follows it. There it made a pull useless. Here, with one configuration value and one flag, it sent a feature branch's commits to `main`.

**[ANIMATION]** end

Try it now. Thirty seconds, read-only. In the lab shell, or in a repository of your own with a recent Git, run `git config get push.default`. Say what it prints.

**[PAUSE]**

If it prints nothing, the setting is unset and Git uses the default, `simple`. If it prints `upstream`, you've found the first half of Incident 2 on your own machine.

**[ANIMATION]** gates: id=cause4 gates=an_interactive_rebase:done:-:new_commits,_and_one_lost|--force:done:-:replaced_the_server's_ref|"reset_to_the_server":done:-:a_second_clone_adopts_the_rewrite|a_legitimate_commit:done:-:shipped_on_top title=Incident_4:_the_root_cause at_1=22 at_2=50 at_3=60 at_4=85

**Incident 4: the root cause.** A branch that deployment records refer to by commit ID accepted a forced update. An interactive rebase, which rewrites a series of commits from an editable list, was meant to "tidy" history. It created new commits and lost one. `--force` replaced the server's ref. Then "reset to the server", given as advice to a confused colleague, made a second clone adopt the rewrite, and a legitimate commit was shipped on top. Layers: Git, and a missing GitHub rule.

**[ANIMATION]** end

**"Same code, fewer commits" is a claim about trees.** A tree is the complete snapshot of files that a commit records. So the claim can be tested: compare the tree of the old tip with the tree of the new one.

**Who did it.** In rewritten history, read the committer and the reflogs, not the author. The author wrote the change, and the committer created this commit. A folded commit keeps its original author and names the person who rewrote it as committer.

**[ANIMATION]** cards: id=checks cards=What_has_been_built_on_the_new_tip?:a_legitimate_commit_there_has_to_be_carried_over|Who_has_fetched_the_new_tip?:every_clone_that_adopted_it_has_to_be_realigned numbered=on title=The_two_checks_before_restoring at_1=18 at_2=55

**[ANIMATION]** step: 2

**The two checks before restoring.** Here are the two checks promised at the start. First: what has been built on the new tip? If a legitimate commit sits on top of the rewritten history, the restore has to carry it over. Second: who has fetched the new tip? Every clone that adopted it will be diverged after the restore and has to be realigned, with a proof that nothing of its own is lost.

And one check on your own evidence: is your copy of the old value the newest good one? Another clone's unfetched value must be an ancestor of it.

**[ANIMATION]** end

**The restoring command.** A forced push with an explicit lease, the value you expect the server's branch to have. It names the server's current, bad value: `git push --force-with-lease=<branch>:<current-bad-id> origin <good>:<branch>`. If anyone pushed meanwhile, it's refused. Before it, an anchor for the state that's about to be replaced, and, where the removed commits are somebody's work, a branch of their own on the server first.

**When a forced restore is the wrong fix.** Had someone already built on the bad tip, the right move in Incident 2 would be `git revert` of the bad commits, which adds commits that undo them. In Incident 4 the textbook compares two routes. One: keep the rewritten history and re-add the fix, with no further force, but then the deployed tag is never an ancestor again and every recorded ID points off-branch. Two: restore the old history and carry the one newer commit over. For a branch whose IDs are recorded elsewhere, restore.

**GitHub, not Git: the rule and the instruments.** A ruleset is GitHub's named list of rules for chosen branches. "Block force pushes" in a ruleset on the default branch rejects this push. It's enabled by default in a new ruleset. For a production branch the textbook's control is a ruleset that blocks force pushes, restricts deletions, requires a pull request, and has an empty bypass list.

When no clone has the old value, GitHub offers instruments of its own. The repository's Activity view lists force pushes with the user and a comparison. A `PushEvent` in the Events API carries the `before` ID, within the last 300 events and 30 days. And the references API can create a branch at that ID.

```bash
gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=<commit ID from before the force push>
```

**[ON SCREEN]** Unverified.

GitHub documents each instrument and not this combined procedure, publishes no retention period for commits that no ref reaches, and documents no "restore" action inside the Activity view. GitHub's own advice is the plain Git route: ask a collaborator who still has the commit to push it.

## MENTAL MODEL

**[ANIMATION]** stores: id=signpost boxes=the_signpost:the_server's_branch|the_travellers:every_clone rows=1:A:somebody_turned_it|1:A:no_camera_at_the_junction@bad|2:B:a_dated_photograph_of_the_signpost|2:B:some_have_two:_before_and_after@ok|3:B:one_has_built_something_at_the_end_of_the_new_road@hl title=A_signpost_at_a_junction at_1=40 at_2=72 at_3=55

**[ANIMATION]** step: 2

Think of the server's branch as a signpost at a junction, and of every clone as a traveller who photographed the signpost the last time they passed. Somebody turned the signpost. There's no camera at the junction: the server keeps no record of where the sign used to point. But every traveller's last photograph is dated, and some travellers have two photographs, before and after.

**[ANIMATION]** step: 3

So the investigation is a collection of photographs. And the repair, turning the sign back, has to consider the travellers who already followed the new direction: one of them has built something at the end of that road.

Where the picture breaks: on GitHub there's a camera after all, the Activity view and the events, with limits and lifetimes of its own, and with the caveats you heard. In the lab's bare repository there's none.

**[ANIMATION]** end

The model for the restoring push: say out loud what you believe the server holds, and let the server refuse if you're wrong. That sentence is the lease.

## DIAGRAM

**[ANIMATION]** cards: id=sofar question=What_we_know_so_far:_two_reports cards="main_was_force-pushed_ten_minutes_ago."|"The_release_job_refuses_to_deploy." title=Before_the_demo at_1=35 at_2=50

**[DIAGRAM]** A new drawing for Incident 4: the server's branch before and after, the witnesses, and the legitimate commit made after the rewrite that the restore must keep. IDs are from the transcript.

```text
  server.git : refs/heads/production

   before:  ...--f46af3d--c644065--1d8b2fc--45e5eb3--3277739      <- tag deploy-2026-09-07 (running)
                                   (round tax)

   after:   ...--f46af3d--f2783aa--4fae70f
                          (4 commits folded into 1;    ^
                           the rounding is missing)    +-- Asha's legitimate new commit, on the rewritten history

  witnesses of the old tip 3277739:
     your clone      production still at 3277739 (not moved)
     your clone      origin/production@{1}  (the entry before "forced update")
     the tag         deploy-2026-09-07

  clones that adopted the rewrite:   ravi (made it),  asha ("reset to the server", then committed)

   restore:  ...--f46af3d--c644065--1d8b2fc--45e5eb3--3277739--a323df1
                                                               (Asha's commit, carried over)
```

Before the demo, what we know so far is two reports: `main` was force-pushed, and a release job refuses to deploy. The picture of the server's branch, before and after, with its witnesses, is drawn in the demo.

## LIVE TERMINAL DEMO

From here on the screen shows the solutions. Is your own command log beside you?

**[PAUSE]**

Then compare as we go.

**[TERMINAL]** Replay `labs/run incidents/solve-02-force-push-wrong-branch`. We sit at our own clone.

**Observe.** 🟢 SAFE.

```bash
git status -sb
git log --oneline -3
git ls-remote origin
```

<!-- snippet: incidents/solve-02-force-push-wrong-branch/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git log --oneline -3
ca03e42 Close the input file after loading
27215c8 Reject rows without a timestamp
f273cd3 Add row validation
# The status is a statement about the last contact with the server. Ask the server:
$ git ls-remote origin
b4554be04054a80a74009ade9d329d2d820c8c5c	HEAD
b4554be04054a80a74009ade9d329d2d820c8c5c	refs/heads/main
```
<!-- /snippet -->

Our status says up to date, with `ca03e42` as the tip. The server says `b4554be`, a commit this clone has never seen. The status is a statement about the last contact with the server.

**Fetch.** A fetch moves remote-tracking refs. Here the old value is evidence, and it's safe: this clone's own `main` still holds it, and the fetch records it in a reflog.

```bash
git fetch
git status -sb
git reflog show origin/main
```

<!-- snippet: incidents/solve-02-force-push-wrong-branch/02-fetch -->
```text
$ git fetch
From ../server
 + ca03e42...b4554be main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 2, behind 2]
$ git reflog show origin/main
b4554be refs/remotes/origin/main@{0}: fetch: forced-update
ca03e42 refs/remotes/origin/main@{1}: update by push
27215c8 refs/remotes/origin/main@{2}: pull: fast-forward
f273cd3 refs/remotes/origin/main@{3}: update by push
```
<!-- /snippet -->

A plus sign and "forced update". Ahead 2, behind 2, without having committed anything. And the reflog of `origin/main`: the entry before the forced update, `origin/main@{1}`, is the value before the event.

**What changed, and is my old value the newest?**

<!-- snippet: incidents/solve-02-force-push-wrong-branch/03-what-changed -->
```text
# What the server lost:
$ git log --format='%h %an: %s' origin/main..'origin/main@{1}'
ca03e42 Lab User: Close the input file after loading
27215c8 Ravi Menon: Reject rows without a timestamp
# What the server gained:
$ git log --format='%h %an: %s' 'origin/main@{1}'..origin/main
b4554be Asha Rao: WIP config flag and readable dedupe, tests still red
a801616 Asha Rao: WIP dedupe by id
# Is my copy of the old value the newest one? Compare with Ravi, who has not fetched:
$ git -C ../ravi rev-parse --short origin/main
27215c8
$ git merge-base --is-ancestor 27215c8 'origin/main@{1}'
[exit status: 0]
```
<!-- /snippet -->

The server lost two reviewed commits and gained two commits marked WIP. Then the check on our own evidence: Ravi hasn't fetched, his `origin/main` is `27215c8`, and that's an ancestor of our old value. So ours is the newest good one.

**The cause.** Look at the clone that pushed. Quick quiz: what will the brackets of her feature branch say? A, `origin/feature/dedupe`. B, `origin/main`. C, nothing at all. Your answer?

**[PAUSE]**

```bash
git -C ../asha branch -vv
git -C ../asha config get --show-origin push.default
git -C ../asha reflog show origin/main
```

<!-- snippet: incidents/solve-02-force-push-wrong-branch/04-cause -->
```text
# Why did a push from feature/dedupe move main? Look at the clone that pushed.
$ git -C ../asha branch -vv
* feature/dedupe b4554be [origin/main] WIP config flag and readable dedupe, tests still red
  main           f273cd3 [origin/main: behind 2] Add row validation
$ git -C ../asha config get --show-origin push.default
file:.git/config	upstream
$ git -C ../asha reflog show origin/main
b4554be refs/remotes/origin/main@{0}: update by push
```
<!-- /snippet -->

B. `feature/dedupe` follows `origin/main`. `push.default` is `upstream`, set in this clone. And her remote-tracking reflog records the push. She pushed "only my branch", and with this configuration her branch's destination was `main`.

**Preserve.** 🟢 SAFE for the anchor. The second command is additive: a new branch on the server.

```bash
git branch rescue/main-before-force 'origin/main@{1}'
git push origin origin/main:refs/heads/feature/dedupe
```

<!-- snippet: incidents/solve-02-force-push-wrong-branch/05-preserve -->
```text
$ git branch rescue/main-before-force 'origin/main@{1}'
# Asha's two commits exist on the server only as the tip of main. Give them their own branch first:
$ git push origin origin/main:refs/heads/feature/dedupe
To ../server.git
 * [new branch]      origin/main -> feature/dedupe
```
<!-- /snippet -->

**[ANIMATION]** graph: 61ac39c-f273cd3-27215c8-ca03e42 main; f273cd3-a801616-b4554be origin/main; HEAD=main => 61ac39c-f273cd3-27215c8-ca03e42 main rescue/main-before-force; f273cd3-a801616-b4554be origin/main origin/feature/dedupe; HEAD=main => 61ac39c-f273cd3-27215c8-ca03e42 main rescue/main-before-force origin/main; f273cd3-a801616-b4554be origin/feature/dedupe; HEAD=main title=Preserve_first,_then_restore

**[ANIMATION]** step: state-2

Asha's two commits existed on the server only as the tip of `main`. Now they have their own branch, so restoring `main` removes nothing from the server.

**Restore.** 🔴 DANGEROUS: a forced update of `main`. The five answers. What it changes: the server's `main`, back to the old tip. What it can destroy: anything pushed to `main` since the bad push. Preview: `git ls-remote origin` once more, and the lease itself. Recovery: the commits being removed now live on their own branch. When appropriate: here, because the commits being removed are unreviewed, are preserved, and nobody built on them.

```bash
git push --force-with-lease=main:b4554be origin rescue/main-before-force:main
git status -sb
```

<!-- snippet: incidents/solve-02-force-push-wrong-branch/06-restore -->
```text
$ git push --force-with-lease=main:b4554be origin rescue/main-before-force:main
To ../server.git
 + b4554be...ca03e42 rescue/main-before-force -> main (forced update)
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

**[ANIMATION]** step: state-3

The lease says: I believe the server's `main` is `b4554be`. Refuse otherwise.

**Fix the cause, in her clone.**

<!-- snippet: incidents/solve-02-force-push-wrong-branch/07-fix-cause -->
```text
$ cd ../asha
$ git fetch
From ../server
 + b4554be...ca03e42 main           -> origin/main  (forced update)
 * [new branch]      feature/dedupe -> origin/feature/dedupe
$ git branch --set-upstream-to=origin/feature/dedupe feature/dedupe
branch 'feature/dedupe' set up to track 'origin/feature/dedupe'.
$ git config unset push.default
$ git status -sb
## feature/dedupe...origin/feature/dedupe
$ git branch -vv
* feature/dedupe b4554be [origin/feature/dedupe] WIP config flag and readable dedupe, tests still red
  main           f273cd3 [origin/main: behind 2] Add row validation
```
<!-- /snippet -->

The upstream of her feature branch now is the branch of the same name, and `push.default` is back to the default.

**Verify.**

<!-- snippet: incidents/solve-02-force-push-wrong-branch/08-verify -->
```text
$ cd ../you
$ git ls-remote origin
ca03e42e9a0a5df9443021ab8b91f1a8364a77ac	HEAD
b4554be04054a80a74009ade9d329d2d820c8c5c	refs/heads/feature/dedupe
ca03e42e9a0a5df9443021ab8b91f1a8364a77ac	refs/heads/main
$ git log --oneline --graph origin/main origin/feature/dedupe
* b4554be WIP config flag and readable dedupe, tests still red
* a801616 WIP dedupe by id
| * ca03e42 Close the input file after loading
| * 27215c8 Reject rows without a timestamp
|/  
* f273cd3 Add row validation
* 61ac39c Add loader
$ git branch -d rescue/main-before-force
Deleted branch rescue/main-before-force (was ca03e42).
$ cd ..
$ incidents/02-force-push-wrong-branch/check.sh
Checking incident 02-force-push-wrong-branch
  ok    main on the server has "Add loader"
  ok    main on the server has "Add row validation"
  ok    main on the server has "Reject rows without a timestamp"
  ok    main on the server has "Close the input file after loading"
  ok    main on the server has no WIP commit
  ok    the server has a branch feature/dedupe
  ok    feature/dedupe on the server has "WIP dedupe by id"
  ok    feature/dedupe on the server has the amended commit
  ok    in asha/, the upstream of feature/dedupe is no longer origin/main (now: origin/feature/dedupe)
  ok    in asha/, push.default is unset (simple)
PASS: the recovery of incident 02-force-push-wrong-branch is complete.
[exit status: 0]
```
<!-- /snippet -->

The server holds `main` at `ca03e42` and `feature/dedupe` at `b4554be`. The check passes: every reviewed commit on `main`, no WIP commit, and the cause removed in the pushing clone.

**The messages.** At once: nobody pulls or pushes `main`. After the restore: `git fetch`, then `git status -sb`. A clone whose `main` shows `ahead` stops and asks. To the CTO: `main` pointed at unreviewed work for a stated number of minutes, nothing was lost, the rule goes on today.

**[TERMINAL]** Replay `labs/run incidents/solve-04-production-history-rewritten`.

**Observe.**

<!-- snippet: incidents/solve-04-production-history-rewritten/01-observe -->
```text
$ cd you
$ git fetch
From ../server
 + 3277739...4fae70f production -> origin/production  (forced update)
$ git branch -vv
* main       905f1ab [origin/main] Add README
  production 3277739 [origin/production: ahead 4, behind 2] Log the invoice id on failure
$ git log --oneline --graph production origin/production
* 4fae70f Add invoice PDF footer
* f2783aa Tax calculation, formatting and logging
| * 3277739 Log the invoice id on failure
| * 45e5eb3 Add currency formatting
| * 1d8b2fc Round tax to two decimals
| * c644065 Add tax calculation
|/  
* f46af3d Add invoice totals
* 905f1ab Add README
```
<!-- /snippet -->

**[ANIMATION]** graph: 905f1ab-f46af3d-c644065-1d8b2fc-45e5eb3-3277739 production tag:deploy-2026-09-07; 905f1ab main origin/main; f46af3d-f2783aa-4fae70f origin/production; HEAD=main => 905f1ab-f46af3d-c644065-1d8b2fc-45e5eb3-3277739-a323df1 production origin/production; 3277739 tag:deploy-2026-09-07; 905f1ab main origin/main; f46af3d-f2783aa-4fae70f rescue/production-rewritten; HEAD=production title=Diverged,_and_I_made_no_commits

**[ANIMATION]** step: state-1

Our untouched `production` is ahead 4, behind 2. We made no commits. "Diverged, and I made no commits" means the server's history was replaced.

**Witnesses.** Three independent records of the old tip.

```bash
git rev-parse production 'origin/production@{1}' 'deploy-2026-09-07^{commit}'
git merge-base --is-ancestor deploy-2026-09-07 origin/production
git log --format='%h %an, committed by %cn: %s' production..origin/production
```

<!-- snippet: incidents/solve-04-production-history-rewritten/02-witnesses -->
```text
# Three independent records of the old tip: my branch, the reflog of origin/production, the tag.
$ git rev-parse production 'origin/production@{1}' 'deploy-2026-09-07^{commit}'
3277739ce8e6fd4a425fdae7a124985414b5dd36
3277739ce8e6fd4a425fdae7a124985414b5dd36
3277739ce8e6fd4a425fdae7a124985414b5dd36
$ git merge-base --is-ancestor deploy-2026-09-07 origin/production
[exit status: 1]
$ git log --format='%h %an, committed by %cn: %s' production..origin/production
4fae70f Asha Rao, committed by Asha Rao: Add invoice PDF footer
f2783aa Lab User, committed by Ravi Menon: Tax calculation, formatting and logging
```
<!-- /snippet -->

Three times `3277739`. The ancestry test exits 1: that's the release job's refusal. And the last line shows who did what: the folded commit keeps its original author and names Ravi as committer.

**[ANIMATION]** walk: id=wit columns=witness,what_it_holds rows=your_clone:production,_still_at_3277739_(not_moved)|your_clone:origin/production@{1},_the_entry_before_"forced_update"|the_tag:deploy-2026-09-07 title=Witnesses_of_the_old_tip_3277739 pace=quick

Three records name the same old tip: our untouched branch, the entry before the forced update, and the deployment tag.

**[ANIMATION]** end

<!-- snippet: incidents/solve-04-production-history-rewritten/03-what-changed -->
```text
$ git range-diff production...origin/production
1:  c644065 < -:  ------- Add tax calculation
2:  1d8b2fc < -:  ------- Round tax to two decimals
3:  45e5eb3 < -:  ------- Add currency formatting
4:  3277739 < -:  ------- Log the invoice id on failure
-:  ------- > 1:  f2783aa Tax calculation, formatting and logging
-:  ------- > 2:  4fae70f Add invoice PDF footer
```
<!-- /snippet -->

`git range-diff` finds no pairs: four old commits on one side, two new ones on the other.

**Test the claim.** "Same code, fewer commits." Predict the output of a tree comparison if the claim were true. Say it out loud.

**[PAUSE]**

```bash
git diff --stat production origin/production
git diff production origin/production -- billing/tax.py
```

<!-- snippet: incidents/solve-04-production-history-rewritten/04-tree-diff -->
```text
# "Same code, fewer commits" is a claim about trees. Compare the trees:
$ git diff --stat production origin/production
 billing/pdf.py | 2 ++
 billing/tax.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff production origin/production -- billing/tax.py
diff --git a/billing/tax.py b/billing/tax.py
index 66a2912..0fce8dc 100644
--- a/billing/tax.py
+++ b/billing/tax.py
@@ -1,2 +1,2 @@
 def tax(amount, rate):
-    return round(amount * rate, 2)
+    return amount * rate
```
<!-- /snippet -->

Were the claim true, only Asha's new file would differ. Two files differ. One is Asha's new commit. The other is `billing/tax.py`, which lost its rounding. The interactive rebase dropped the commit "Round tax to two decimals" when a line of the todo list was deleted. That's the finance ticket about unrounded tax amounts.

**How.**

<!-- snippet: incidents/solve-04-production-history-rewritten/05-how -->
```text
$ git -C ../ravi reflog show production
f2783aa production@{0}: commit (amend): Tax calculation, formatting and logging
7fb64db production@{1}: rebase (finish): refs/heads/production onto f46af3da39ea0c36cdbaef0b34e16f4407a78eb6
3277739 production@{2}: branch: Created from refs/remotes/origin/production
$ git -C ../ravi reflog | grep rebase
7fb64db HEAD@{1}: rebase (finish): returning to refs/heads/production
7fb64db HEAD@{2}: rebase (fixup): Add tax calculation
6d37632 HEAD@{3}: rebase (fixup): # This is a combination of 2 commits.
c644065 HEAD@{4}: rebase (start): checkout production~4
```
<!-- /snippet -->

Ravi's reflogs: a rebase started four commits back, two fixups, a finish, and an amend.

**Restore.** First the anchor, then the legitimate commit, then the push. 🟢 for the anchor. 🟡 for the cherry-pick, which copies the commit onto the current branch. 🔴 for the forced push, conditional on the server's current value, `4fae70f`. It's appropriate because this branch's IDs are recorded elsewhere, the state being replaced is anchored, and the one legitimate commit has been carried over.

```bash
git branch --no-track rescue/production-rewritten origin/production
git switch production
git cherry-pick origin/production
git log --oneline main..production
git push --force-with-lease=production:4fae70f origin production
```

<!-- snippet: incidents/solve-04-production-history-rewritten/06-restore -->
```text
$ git branch --no-track rescue/production-rewritten origin/production
$ git switch production
Switched to branch 'production'
Your branch and 'origin/production' have diverged,
and have 4 and 2 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)
# One commit was shipped on top of the rewritten history. Copy it onto the real history:
$ git cherry-pick origin/production
[production a323df1] Add invoice PDF footer
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:30:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 billing/pdf.py
$ git log --oneline main..production
a323df1 Add invoice PDF footer
3277739 Log the invoice id on failure
45e5eb3 Add currency formatting
1d8b2fc Round tax to two decimals
c644065 Add tax calculation
f46af3d Add invoice totals
$ git push --force-with-lease=production:4fae70f origin production
To ../server.git
 + 4fae70f...a323df1 production -> production (forced update)
```
<!-- /snippet -->

**[ANIMATION]** step: state-2

Asha's commit is now `a323df1`, on top of the real history, and the rounding commit `1d8b2fc` is in the list again. One commit on the rewritten line wasn't part of the mistake, and the restore keeps it.

**Realign.** Each clone that adopted the rewrite proves that nothing of its own is lost before it moves. 🟡 CAUTION: `git reset --keep`.

```bash
git fetch
git status -sb
git cherry -v origin/production production
git reset --keep origin/production
```

<!-- snippet: incidents/solve-04-production-history-rewritten/07-realign -->
```text
$ cd ../asha
$ git fetch
From ../server
 + 4fae70f...a323df1 production -> origin/production  (forced update)
$ git status -sb
## production...origin/production [ahead 2, behind 5]
# Is anything of mine missing from the server? "-" means the server has an equivalent change.
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
- 4fae70f86a56f9c739bd55c2e9830f4fba9145da Add invoice PDF footer
$ git reset --keep origin/production
$ cd ../ravi
$ git fetch
From ../server
 + f2783aa...a323df1 production -> origin/production  (forced update)
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
$ git reset --keep origin/production
```
<!-- /snippet -->

In Asha's clone, `git cherry -v` marks her own commit with a minus sign: the server has an equivalent change. The only plus sign is the folded commit, which is being retired on purpose. In Ravi's clone the same single plus sign. Then each moves with `--keep`.

**Verify.**

<!-- snippet: incidents/solve-04-production-history-rewritten/08-verify -->
```text
$ cd ../you
$ git merge-base --is-ancestor deploy-2026-09-07 origin/production
[exit status: 0]
$ git show origin/production:billing/tax.py
def tax(amount, rate):
    return round(amount * rate, 2)
$ git diff --stat rescue/production-rewritten origin/production
 billing/tax.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -D rescue/production-rewritten
Deleted branch rescue/production-rewritten (was 4fae70f).
$ cd ..
$ incidents/04-production-history-rewritten/check.sh
Checking incident 04-production-history-rewritten
  ok    production on the server has "Add invoice totals"
  ok    production on the server has "Add tax calculation"
  ok    production on the server has "Round tax to two decimals"
  ok    production on the server has "Add currency formatting"
  ok    production on the server has "Log the invoice id on failure"
  ok    production on the server has "Add invoice PDF footer"
  ok    the squashed commit is no longer on production
  ok    the deployed tag is an ancestor of production again
  ok    billing/tax.py on production rounds to two decimals
  ok    billing/pdf.py is on production
  ok    production in you/ equals production on the server
  ok    production in asha/ equals production on the server
  ok    production in ravi/ equals production on the server
PASS: the recovery of incident 04-production-history-rewritten is complete.
[exit status: 0]
```
<!-- /snippet -->

The release job's own test exits 0. The tax function rounds. The difference between the rewritten state and the restored one is exactly one file, the one that was wrong. The check passes for the server and for all three clones.

**The messages.** To the team: the new tip, and the two commands, `git cherry -v`, then `git reset --keep`, with the rule for any unexpected plus sign: stop and ask. To the CTO: nothing bad was deployed because the release job refused, a dropped fix was caught, and the missing rule goes on today.

**[ANIMATION]** layers: id=controls layers=a_client_default:push.default_left_at_simple|a_habit:--force-with-lease,_never_bare_--force|a_platform_rule:block_force_pushes_on_the_default_branch|a_pipeline_check:the_ancestry_test_in_the_release_job|a_line_in_the_handbook:"diverged,_and_I_made_no_commits"+stop_and_ask title=From_root_cause_to_controls_on_several_layers at_1=10 at_2=22 at_3=32 at_4=58 at_5=75

**From root cause to controls on several layers.** A client default: `push.default` left at `simple`. A habit: `--force-with-lease`, never bare `--force`. A platform rule: block force pushes on the default branch. For production, also restrict deletions, require a pull request, and keep the bypass list empty. A pipeline check: the ancestry test in the release job, which is the control that worked. And a line in the handbook: "diverged, and I made no commits" means the server's history was replaced. Stop and ask.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Trusting `git status` about the server.** Root cause: it compares with the remote-tracking branch, which is the clone's memory of the last contact.
2. **Restoring with a bare `--force`.** Root cause: nothing then checks whether somebody pushed to the branch in the meantime, so the recovery can remove a colleague's work.
3. **Restoring without looking at what was built on the new tip.** Root cause: a legitimate commit made after the rewrite sits on the history that is about to be replaced.
4. **Advising "reset to the server" to someone who sees "diverged".** Root cause: with no local commits, divergence means the server's history was replaced, and the reset makes a second clone adopt the rewrite.
5. **Accepting "same code, fewer commits" without a tree comparison.** Root cause: an interactive rebase can drop a commit with one deleted line of the todo list, and only the trees show it.

## PRODUCTION EXAMPLE

Now, out of the lab. A billing team deploys from a branch named `production`. Its release job has one safety check that nobody remembers adding: the commit currently running must be an ancestor of the commit to be deployed. One morning the job refuses.

**[ANIMATION]** cards: id=three cards=her_own_untouched_branch|the_reflog_of_her_remote-tracking_branch|the_deployment_tag marks=1:ok,2:ok,3:ok numbered=on title=Three_witnesses_of_the_old_tip at_1=20 at_2=24 at_3=28 at_marks=32

The engineer on call writes one sentence in the channel, asks two colleagues not to fetch or reset, and collects three witnesses of the old tip: her own untouched branch, the reflog of her remote-tracking branch, and the deployment tag. They agree. She compares trees, finds that a tax-rounding fix is missing from the rewritten history, and connects it to a finance ticket filed the day before. She finds one legitimate commit on top of the rewrite, anchors the rewritten state, carries that commit over, and restores with a lease that names the server's current value.

**[ANIMATION]** cards: id=lines cards=The_control_that_worked:an_automated_ancestry_check|The_control_that_was_missing:one_checkbox|The_advice_"reset_to_the_server":turned_one_affected_clone_into_two title=Three_lines_the_team_remembers at_1=55 at_2=70 at_3=82

Her summary rates the incident SEV 2 although nothing was deployed, because the only thing between the rewritten branch and production was that one check. The postmortem has three lines the team remembers. The control that worked was an automated ancestry check. The control that was missing was one checkbox. And the advice "reset to the server" turned one affected clone into two.

## PRACTICE EXERCISE

Your turn. Do Lab 37.1, "A force push to the wrong branch (incident 2)", in [`lab-manual/m37-incident-drills-platform.md`](../../lab-manual/m37-incident-drills-platform.md), from a freshly generated sandbox.

Before you fetch, write down what you'll record first and why. Before the restore, write the two checks and their results, the ID your lease will name, and what you'll do if the lease is refused. After the restore, write the message to the team with the exact commands for their clones. Type the recovery by hand.

The challenge is Lab 37.2, "Production branch history is rewritten (incident 4)", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q381: "`main` was force-pushed ten minutes ago. Before you restore it, which two things do you check, and what does the restoring command look like?"

**[PAUSE]**

Answer out loud. A strong answer first says where the old value comes from, naming at least two kinds of witness, and how you make sure it's the newest good one. It then gives the two checks as questions about other people's work: one about what sits on top of the new tip, one about who has adopted it. It describes the restoring command by its parts: what is pushed, to which ref, with which condition, and what is anchored beforehand. And it names the case in which you wouldn't force at all, and what you would do instead. Mention the platform rule that would have refused the original push.

## RECAP

Let's land this.

- A server keeps no reflog; the old value of a replaced branch comes from clones that have not fetched, from remote-tracking reflogs, and from tags or deployment records.
- Before restoring, check what was built on the new tip and who has fetched it.
- The restoring push carries an explicit lease naming the server's current value, after the state being replaced has been anchored or given its own branch.
- Clones that adopted the rewrite prove with `git cherry -v` that nothing of their own is missing, then move with `git reset --keep`.
- Controls sit on several layers: a client default, a habit, a ruleset, and an ancestry check in the pipeline.

## HOMEWORK

Read sections 30.6 and 30.8. Then generate Incident 6, [`incidents/06-pr-500-changes`](../../incidents/06-pr-500-changes/SYMPTOMS.md), and attempt it before the next video.

You can now put a replaced branch back without losing what a colleague built since, and say which control was missing on which layer. Practise the first restore by hand before you go on. Next time, a new report: "I pushed one commit and the pull request shows 500 files". Until then, look at the state first and type second. See you in the next one.

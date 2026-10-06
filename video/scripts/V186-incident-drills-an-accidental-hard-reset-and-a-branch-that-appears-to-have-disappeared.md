# V186: Incident drills: an accidental hard reset, and a branch that appears to have disappeared

- **Part.** 9, Production debugging and incident response
- **Module.** 36
- **Planned minutes.** 24
- **Prerequisites.** V043, V075, V185
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.5 and 30.12
- **Demo scripts.** `labs/incidents/solve-01-hard-reset.sh` (snippets `01-observe` to `07-cleanup`), `labs/incidents/solve-08-branch-disappeared.sh` (snippets `01-observe` to `07-verify`)

## HOOK

**[ON SCREEN]** Two reports. Ravi: "I think `git pull` ate my work." Asha: "My branch has disappeared. I am sure everything was pushed."

Each report contains a diagnosis, and each diagnosis names a suspect: a command in the first, the server in the second. A branch is a named line of commits, the saved snapshots of a project. `git pull` fetches commits from the team's server and integrates them, and a push sends yours there. People in this situation aren't careless. They're describing what they believe happened, in the only words they have.

**[ANIMATION]** cards: id=suspects cards=Ravi's_report_suspects_a_command:git_pull|Asha's_report_suspects_the_server title=Two_reports,_two_suspects at_1=15 at_2=25

**[ANIMATION]** step: 2

Your job in the next twenty minutes is to treat both sentences as symptoms, find out from the repositories what did happen, bring back everything that can be brought back, and say plainly what can't. Keep those two suspects in mind. Each gets a verdict before we finish.

A first question. Ravi blames `git pull`. Which record on his laptop could confirm that, or clear it? Say it out loud.

**[PAUSE]**

The reflog: Git's local record of every value a ref has had, with the command behind each change. A pull would have left a line there. We read it together later.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a debrief. It assumes you have generated Incident 1, [`incidents/01-hard-reset`](../../incidents/01-hard-reset/SYMPTOMS.md), and Incident 8, [`incidents/08-branch-disappeared`](../../incidents/08-branch-disappeared/SYMPTOMS.md), and attempted both, with a command log and your four lines for the CTO. Have you? If you haven't, stop the video now and do that.

**[PAUSE]**

The cause of each incident is named in the next section. A drill whose cause you've seen can't be repeated.

Both incidents are rated SEV 4 on the scale of video 185: one person's local work. They're the right place to start, because the stakes are low and the techniques, from video 75 and video 43, are exactly the ones the bigger incidents need: reading a reflog as a sequence of events, anchoring before acting, and choosing a recovery that adds instead of moving.

For each incident we go through the loop: what the evidence said, which hypotheses it separated, the root cause with its layer, the recovery, the verification, and the message to the person. Compare each step with your own log.

## LEARNING OBJECTIVES

After this video you can:

1. Establish what a hard reset destroyed and what the reflog and dangling blobs still hold.
2. Recover the committed and the staged work and state honestly what is gone.
3. Classify a "disappeared" branch: deleted locally, pruned remote-tracking ref, never pushed, renamed.
4. Find the tip, anchor it and restore the branch.
5. Write the summary and the prevention for both.

## CONCEPT

**Incident 1: what a hard reset does to three kinds of work.** `git reset --hard` moves the branch, replaces the index and overwrites the working tree. The index is the proposed next commit, and the working tree is the files you edit. The work that was there before sits on three layers, and each layer has a different answer.

**[ON SCREEN]** The table of section 30.5.

| What | Where Git has it | Recoverable |
|---|---|---|
| Three commits | reachable from the branch reflog | yes |
| A file that was staged and never committed | a dangling blob | yes, as content without a name |
| An unstaged edit | nowhere | no |

Committed work is in the reflog. Staged work was written to the object database by `git add`, so it survives as a blob, Git's object for one file's content, that nothing references. A blob has no file name: the name was in the index entry that the reset removed. Unstaged work was never given to Git, and Git can't return what it never stored.

**The root cause, as the textbook states it.** Ravi wanted to discard one edit and used a command that moves the branch, replaces the index and overwrites the working tree. `origin/main`, his clone's record of the server's `main`, wasn't his branch's counterpart. No counterpart existed. Layer: Git, one laptop. `git pull` wasn't involved.

**[ANIMATION]** graph: 43fb607-44fa655-2876d93-4e4c0b7 feature/escalation-rules; 44fa655 main; 2876d93 origin/main; 44fa655-95d110d-a26c697-0322a16; HEAD=feature/escalation-rules; reflog:95d110d,a26c697,0322a16 => 43fb607-44fa655-2876d93-4e4c0b7-990c316-faa407c-028bfd1 feature/escalation-rules; 44fa655 main; 2876d93 origin/main; 44fa655-95d110d-a26c697-0322a16 rescue/before-reset; HEAD=feature/escalation-rules; reflog: title=Add,_do_not_move

**[ANIMATION]** step: state-1

**Why the tempting recovery is wrong.** The tempting move is to put the branch back where it was before the accident, with another hard reset. But Ravi has committed once since the reset. Moving the branch back would discard that commit.

**[ANIMATION]** step: state-2

So the three commits are added on top instead. This is the ladder of video 184: add, don't move.

**[ANIMATION]** end

**[ANIMATION]** cards: id=missing question=Why_can_a_branch_be_missing? cards=it_was_renamed|it_was_deleted_locally|the_server's_branch_was_deleted,_and_a_pruning_fetch_removed_the_remote-tracking_ref|it_was_never_pushed title="Disappeared"_is_a_symptom at_1=22 at_2=29 at_3=36 at_4=62

**Incident 8: "disappeared" is a symptom with several mechanisms.** A branch can be missing because it was renamed. Because it was deleted locally. Because the server's branch was deleted and a pruning fetch removed the remote-tracking ref, the clone's record of that branch. Or because it was never pushed. Usually more than one of these has happened, and the question that matters isn't "where is the branch" but "which work is where".

**[ANIMATION]** gates: id=foursteps gates=squash_merge:done:GitHub:and_the_head_branch_deleted|fetch.prune:done:Git:removed_the_remote-tracking_ref|more_work:done:Git:continued_on_the_merged_branch|git_branch_-D:done:Git:overrode_the_refusal_of_-d zones=GitHub,Git split=1 title=Four_steps,_each_reasonable_alone at_1=12 at_2=40 at_3=52 at_4=60

**The root cause here: four steps, each reasonable alone.** GitHub squash-merged the pull request, the proposal to merge her branch, and deleted the head branch. A squash merge combines a branch's commits into one new commit. `fetch.prune` removed the remote-tracking ref. Work had continued on the merged branch. `git branch -d` refused, correctly, because squashed commits aren't ancestors of `main`, and `-D` overrode the refusal. Layers: GitHub for the first step, Git for the rest.

**[ANIMATION]** end

**Two tools, one of which misleads.** `git cherry` compares patch IDs, which are hashes of each commit's change, and a squashed commit equals none of its parts, so every original commit looks unmerged. Trees, the complete snapshots, are reliable: compare the content of the old tip with the content of `main`.

**GitHub, not Git.** A closed pull request offers "Restore branch" for its head branch. It restores what the server had. A commit that was never pushed isn't on the server, and Support can't produce it.

**[ANIMATION]** graph: c8dbea7-1a7ca10 main origin/main; c8dbea7-c12fb6d-a93889a-ceaa8bc-70df7f7; HEAD=main; reflog:c12fb6d,a93889a,ceaa8bc,70df7f7 => c8dbea7-1a7ca10-499c20c feature/prompt-validation; 1a7ca10 main origin/main; c8dbea7-c12fb6d-a93889a-ceaa8bc-70df7f7 rescue/prompt-versioning; HEAD=feature/prompt-validation; reflog: title=Which_work_is_where

**[ANIMATION]** step: state-1

**Why the tempting recovery is wrong here too.** Recreating and pushing the old branch would publish three commits whose content is already in `main`: the reused-branch problem of video 125.

**[ANIMATION]** step: state-2

The safe recovery is a new branch from the current `main` with the one commit that isn't merged.

**[ANIMATION]** end

## MENTAL MODEL

**[ANIMATION]** walk: id=desk columns=on_the_desk,in_Git,after_the_sweep rows=pages_that_were_filed:the_commits:in_the_archive,_with_an_index_card:_the_reflog|pages_in_the_out-tray:the_staged_file:photocopied,_without_its_folder_label|pages_you_were_still_writing_on:the_unstaged_edit:never_copied_by_anyone mono=off marks=1.3:ok,2.3:ok,3.3:bad title=A_desk_that_somebody_swept_clean at_1=22 at_2=50 at_3=80

**[ANIMATION]** step: 3

Think of the three layers of Incident 1 as three kinds of paper on a desk that somebody swept clean. Pages that were filed, the commits, are in the archive, and the archive has an index card for each: the reflog. Pages that were put in the out-tray, the staged file, were photocopied by the clerk before the sweep. The copy exists, without its folder label. Pages you were still writing on were never copied by anyone.

Where the picture breaks: the archive's index cards expire. By default a reflog entry for a commit that's no longer reachable lasts 30 days, and a dangling blob goes two weeks after it becomes unreachable, once maintenance runs. The lab switches reflog expiry off. A real laptop doesn't.

**[ANIMATION]** end

Try it now. Thirty seconds, read-only. In the lab shell or any repository you have, run `git reflog -5`, and read the lines from the bottom up.

**[PAUSE]**

Each line is one move of HEAD, Git's note of where you are: the commit it arrived at, and the command behind it. Those are your index cards.

For Incident 8, hold the sentence from video 170: "merged" in Git means "reachable from". A squash keeps the content and discards the ancestry. So every tool that asks about ancestry or patch identity says "not merged", and the tool that compares content says "already there".

## DIAGRAM

**[ANIMATION]** cards: id=sofar question=What_we_know_so_far:_two_reports cards=Ravi:"I_think_git_pull_ate_my_work."|Asha:"My_branch_has_disappeared._I_am_sure_everything_was_pushed." title=Before_the_demo at_1=30 at_2=55

**[DIAGRAM]** A new drawing for each incident: a timeline strip built from reflog entries, read left to right, with the destructive moment marked. Incident 1, from the reflog of the branch:

```text
  feature/escalation-rules, from its reflog (oldest on the left)

   branch       commit      commit      commit      RESET --hard          commit
   created      95d110d     a26c697     0322a16     to origin/main        4e4c0b7
  ---+------------+-----------+-----------+--------------X------------------+----->
    @{5}         @{4}        @{3}        @{2}           @{1}               @{0}
                                           ^              ^
                              last good tip: anchor here  destructive moment

   also lost at X:  a staged file (survives as a dangling blob)
                    an unstaged edit (survives nowhere)
```

Before the demo, here is everything we know so far from the people involved: two reports, each naming a suspect.

**[ANIMATION]** step: sofar.2

```text
  HEAD, from its reflog (oldest on the left)

   clone    switch to     commit    commit    commit    commit     switch     pull:
            the branch    c12fb6d   a93889a   ceaa8bc   70df7f7    to main    fast-forward
  ---+---------+------------+---------+---------+---------+----------+----------+----->
    @{7}      @{6}         @{5}      @{4}      @{3}      @{2}       @{1}       @{0}
                            \_________ pushed, then _______/   ^
                              squash-merged as one commit      never pushed: the only copy

   not in this reflog: the squash merge and branch deletion on GitHub, the pruning fetch,
   and git branch -D, which removed the ref and its reflog
```

Each incident gets a timeline, built from a reflog. We draw both in the demo, once the reflogs are on screen.

## LIVE TERMINAL DEMO

Last call. From here on the screen shows the solutions. Is your own command log beside you?

**[PAUSE]**

Then compare as we go.

**[TERMINAL]** Replay `labs/run incidents/solve-01-hard-reset`. We sit at Ravi's clone.

**Observe.** 🟢 SAFE.

```bash
git status -sb
git branch -vv
git log --oneline --graph --all
```

<!-- snippet: incidents/solve-01-hard-reset/01-observe -->
```text
$ cd ravi
$ git status -sb
## feature/escalation-rules
$ git branch -vv
* feature/escalation-rules 4e4c0b7 Mention escalation in the README
  main                     44fa655 [origin/main: behind 1] Add README
$ git log --oneline --graph --all
* 4e4c0b7 Mention escalation in the README
* 2876d93 Document how to run the tests
* 44fa655 Add README
* 43fb607 Add ticket classifier
```
<!-- /snippet -->

`git status -sb` prints the branch name with no upstream, that is, no server branch that it follows. So there's no "this branch on the server", and "I reset to what is on the server" can't mean what Ravi thinks. The graph shows four commits and none of Friday's.

**The reflog.** Predict: will the HEAD reflog contain a `pull` line?

```bash
git reflog show feature/escalation-rules
git reflog | grep -c pull
```

<!-- snippet: incidents/solve-01-hard-reset/02-reflog -->
```text
$ git reflog show feature/escalation-rules
4e4c0b7 feature/escalation-rules@{0}: commit: Mention escalation in the README
2876d93 feature/escalation-rules@{1}: reset: moving to origin/main
0322a16 feature/escalation-rules@{2}: commit: Never escalate spam
a26c697 feature/escalation-rules@{3}: commit: Route escalated tickets to the on-call queue
95d110d feature/escalation-rules@{4}: commit: Add escalation predicate
44fa655 feature/escalation-rules@{5}: branch: Created from HEAD
# Ravi suspects "git pull". Does the HEAD reflog record a pull at all?
$ git reflog | grep -c pull
0
[exit status: 1]
```
<!-- /snippet -->

Three hypotheses, separated by this one output. A pull rewrote the branch: no `pull` line exists, the count is 0. The commits were made elsewhere: no, three `commit:` lines are in this branch's reflog. A reset moved the branch away from them: `@{1}` says "reset: moving to origin/main". And `@{0}` is the commit Ravi made afterwards.

**[ANIMATION]** walk: id=t1 columns=reflog,what_happened,note rows=@{5}:branch_created:|@{4}:commit_95d110d:|@{3}:commit_a26c697:|@{2}:commit_0322a16:last_good_tip:_anchor_here|@{1}:RESET_--hard_to_origin/main:destructive_moment|@{0}:commit_4e4c0b7:|also_lost:a_staged_file:survives_as_a_dangling_blob|also_lost:an_unstaged_edit:survives_nowhere marks=4.3:ok,5.2:bad,5.3:bad,8.3:bad title=feature/escalation-rules,_from_its_reflog pace=quick

Here's that reflog as a timeline, oldest at the top: the last good tip at `@{2}`, the destructive moment at `@{1}`.

**[ANIMATION]** end

**Anchor.** 🟢 SAFE: a branch at the last good tip.

```bash
git branch rescue/before-reset 'feature/escalation-rules@{2}'
git log --oneline origin/main..rescue/before-reset
git diff --stat origin/main...rescue/before-reset
```

<!-- snippet: incidents/solve-01-hard-reset/03-anchor -->
```text
$ git branch rescue/before-reset 'feature/escalation-rules@{2}'
$ git log --oneline origin/main..rescue/before-reset
0322a16 Never escalate spam
a26c697 Route escalated tickets to the on-call queue
95d110d Add escalation predicate
$ git diff --stat origin/main...rescue/before-reset
 rules/routing.yaml | 1 +
 triage/escalate.py | 4 ++++
 2 files changed, 5 insertions(+)
```
<!-- /snippet -->

The three commits have a name now, whatever happens next.

**The staged file.** `git fsck --lost-found` is the diagnostic command that isn't strictly read-only: it writes files under `.git/lost-found/`.

```bash
git fsck --lost-found
ls .git/lost-found/other
git cat-file -p 959c205
```

<!-- snippet: incidents/solve-01-hard-reset/04-staged -->
```text
$ git fsck --lost-found
dangling blob 959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ ls .git/lost-found/other
959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ git cat-file -p 959c205
outage: 1
billing: 2
how-to: 3
```
<!-- /snippet -->

One dangling blob, `959c205`, and its content is the priority rules. It has no file name. Ravi supplies the name from memory: `rules/priority.yaml`.

**Recover.** 🟡 CAUTION: `git cherry-pick` adds commits to the current branch: it copies each commit's change as a new commit. Predict: why a cherry-pick of a range and not a reset to the rescue branch?

<!-- snippet: incidents/solve-01-hard-reset/05-recover -->
```text
$ git cherry-pick origin/main..rescue/before-reset
[feature/escalation-rules 990c316] Add escalation predicate
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:13:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 triage/escalate.py
[feature/escalation-rules faa407c] Route escalated tickets to the on-call queue
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:14:00 2026 +0530
 1 file changed, 1 insertion(+)
[feature/escalation-rules 028bfd1] Never escalate spam
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git cat-file -p 959c205 > rules/priority.yaml
$ git status -sb
## feature/escalation-rules
?? rules/priority.yaml
```
<!-- /snippet -->

The three commits are added on top of the commit made after the reset, and the blob's content is written back to its path.

**Verify.**

```bash
git log --oneline --graph feature/escalation-rules
git range-diff origin/main rescue/before-reset HEAD
```

<!-- snippet: incidents/solve-01-hard-reset/06-verify -->
```text
$ git log --oneline --graph feature/escalation-rules
* 028bfd1 Never escalate spam
* faa407c Route escalated tickets to the on-call queue
* 990c316 Add escalation predicate
* 4e4c0b7 Mention escalation in the README
* 2876d93 Document how to run the tests
* 44fa655 Add README
* 43fb607 Add ticket classifier
$ git range-diff origin/main rescue/before-reset HEAD
-:  ------- > 1:  4e4c0b7 Mention escalation in the README
1:  95d110d = 2:  990c316 Add escalation predicate
2:  a26c697 = 3:  faa407c Route escalated tickets to the on-call queue
3:  0322a16 = 4:  028bfd1 Never escalate spam
$ cat rules/routing.yaml
default_queue: general
escalation_queue: oncall
$ cd ..
$ incidents/01-hard-reset/check.sh
Checking incident 01-hard-reset
  ok    the commit "Add escalation predicate" is on feature/escalation-rules again
  ok    the commit "Route escalated tickets to the on-call queue" is on feature/escalation-rules again
  ok    the commit "Never escalate spam" is on feature/escalation-rules again
  ok    the commit made after the reset is still on the branch
  ok    no commit of main was copied
  ok    the branch contains the current origin/main
  ok    triage/escalate.py in the last commit has the spam rule
  ok    the staged file rules/priority.yaml is back with its content
  ok    no operation is left in progress
PASS: the recovery of incident 01-hard-reset is complete.
[exit status: 0]
```
<!-- /snippet -->

`git range-diff` shows three pairs marked with an equals sign: each copy carries the same change as its original. The first line, with the arrow, is the commit made after the reset, which the tempting recovery would have lost. Then the check script: every line `ok`, and `PASS`. Compare with the failing check of video 185: the lines that failed there are the commit made after the reset, the relation to `main`, and the staged file.

<!-- snippet: incidents/solve-01-hard-reset/07-cleanup -->
```text
$ git -C ravi branch -D rescue/before-reset
Deleted branch rescue/before-reset (was 0322a16).
```
<!-- /snippet -->

🔴 DANGEROUS: `git branch -D`. It deletes the branch reflog and the only name of commits that aren't merged elsewhere. The recovery is the HEAD reflog, until it expires. It's appropriate here because the range-diff has shown that every commit on the rescue branch has its copy on the real branch. The rescue branch is deleted only after the verification, and the deletion prints the ID once more.

**[ANIMATION]** cards: id=verdict1 cards=Ravi's_report_suspects_a_command:git_pull|Asha's_report_suspects_the_server marks=1:ok title=Two_reports,_two_suspects pace=quick at_marks=72

**The message to Ravi.** What is back: three commits, and one file as untracked content. What isn't: the unstaged edit to the routing rules, which Git never stored. And: `git pull` wasn't involved. That's the first suspect cleared. Nobody else needs a message.

**[TERMINAL]** Replay `labs/run incidents/solve-08-branch-disappeared`. We sit at Asha's clone.

**Observe.**

```bash
git status -sb
git branch -a
git ls-remote origin
```

<!-- snippet: incidents/solve-08-branch-disappeared/01-observe -->
```text
$ cd asha
$ git status -sb
## main...origin/main
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
$ git ls-remote origin
1a7ca10d4574f2b74570b1c78760a98c51498ce5	HEAD
1a7ca10d4574f2b74570b1c78760a98c51498ce5	refs/heads/main
```
<!-- /snippet -->

No ref of that name exists anywhere: not locally, not as a remote-tracking branch, not on the server.

**The reflogs.** Quick quiz: which of the two reflogs still exists? A, the reflog of the branch. B, the reflog of HEAD. Your answer?

**[PAUSE]**

```bash
git reflog show feature/prompt-versioning
git reflog --format='%h %gd %gs'
```

<!-- snippet: incidents/solve-08-branch-disappeared/02-reflog -->
```text
# The branch reflog went with the branch. The HEAD reflog is still here:
$ git reflog show feature/prompt-versioning
fatal: ambiguous argument 'feature/prompt-versioning': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog --format='%h %gd %gs'
1a7ca10 HEAD@{0} pull: Fast-forward
c8dbea7 HEAD@{1} checkout: moving from feature/prompt-versioning to main
70df7f7 HEAD@{2} commit: Validate prompt variables before save
ceaa8bc HEAD@{3} commit: Add version history
a93889a HEAD@{4} commit: Load a prompt by version
c12fb6d HEAD@{5} commit: Store every save as a new version
c8dbea7 HEAD@{6} checkout: moving from main to feature/prompt-versioning
c8dbea7 HEAD@{7} clone: from $LAB/incidents/solve-08-branch-disappeared/server.git
```
<!-- /snippet -->

B. The branch reflog went with the branch. The HEAD reflog is still here, and it holds the four commits and the moment she left the branch. The last commit made on it is `70df7f7`.

**Why is it gone?**

<!-- snippet: incidents/solve-08-branch-disappeared/03-why-gone -->
```text
$ git config get --show-origin fetch.prune
file:.git/config	true
# What is on main now, and who put it there?
$ git log -2 --format='%h author %an, committer %cn: %s' main
1a7ca10 author Asha Rao, committer Ravi Menon: Add prompt versioning (#42)
c8dbea7 author Lab User, committer Lab User: Add README
$ git show --stat --format=%s main
Add prompt versioning (#42)

 registry/history.py | 2 ++
 registry/store.py   | 8 +++++---
 2 files changed, 7 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

The newest commit on `main` has Asha as author and Ravi as committer, and a pull request number in its subject: the shape of a squash merge, which keeps none of the original messages. That's why none of her commit messages are in the log of `main`.

**Classify: which work is where?**

```bash
git log --oneline main..70df7f7
git cherry -v main 70df7f7
git diff --stat main 70df7f7
git diff --stat main 70df7f7~1
```

Predict what `git cherry` will say, and whether you should believe it. Say it out loud.

**[PAUSE]**

<!-- snippet: incidents/solve-08-branch-disappeared/04-classify -->
```text
# The last commit made on the lost branch, from the HEAD reflog:
$ git log --oneline main..70df7f7
70df7f7 Validate prompt variables before save
ceaa8bc Add version history
a93889a Load a prompt by version
c12fb6d Store every save as a new version
# Patch IDs cannot see through a squash: every commit looks unmerged.
$ git cherry -v main 70df7f7
+ c12fb6d8347452b8124fe1d59b2f25c589155a6f Store every save as a new version
+ a93889ae2c557817889f98a9629eb7560ad5a984 Load a prompt by version
+ ceaa8bc13e03ca5676baa71d4401845ee3002318 Add version history
+ 70df7f70daac6ced8a343ab10d9509c1e363cf17 Validate prompt variables before save
# Trees can. What does the old tip have that main does not?
$ git diff --stat main 70df7f7
 registry/validate.py | 9 +++++++++
 1 file changed, 9 insertions(+)
$ git diff --stat main 70df7f7~1
```
<!-- /snippet -->

`git cherry` reports all four commits as unmerged, which is misleading: a squashed commit equals none of its parts. Trees are reliable. The old tip differs from `main` by one file. The commit before it doesn't differ at all. So three commits are in `main` as one, and the fourth, the validation, was never pushed. "I am sure everything was pushed" was true of three commits out of four.

**[ANIMATION]** walk: id=t2 columns=reflog,what_happened,note rows=@{7},_@{6}:clone,_then_switch_to_the_branch:|@{5}_to_@{3}:commits_c12fb6d,_a93889a,_ceaa8bc:pushed,_then_squash-merged_as_one_commit|@{2}:commit_70df7f7:never_pushed:_the_only_copy|@{1},_@{0}:switch_to_main,_then_pull,_fast-forward:|not_in_this_reflog:the_squash_merge_and_branch_deletion_on_GitHub:and_the_pruning_fetch,_and_git_branch_-D marks=3.3:bad,5.1:dim,5.2:dim,5.3:dim title=HEAD,_from_its_reflog pace=quick

And here's the timeline of Incident 8, from the reflog of HEAD, because the branch's own reflog went with the branch.

**[ANIMATION]** end

**Anchor, then recover.** 🟢 SAFE for the anchor and the new branch. 🟡 CAUTION for the cherry-pick and the push of a new branch.

<!-- snippet: incidents/solve-08-branch-disappeared/05-anchor -->
```text
$ git branch rescue/prompt-versioning 70df7f7
$ git branch -vv
* main                     1a7ca10 [origin/main] Add prompt versioning (#42)
  rescue/prompt-versioning 70df7f7 Validate prompt variables before save
```
<!-- /snippet -->

```bash
git switch -c feature/prompt-validation main
git cherry-pick rescue/prompt-versioning
git push -u origin feature/prompt-validation
```

<!-- snippet: incidents/solve-08-branch-disappeared/06-recover -->
```text
$ git switch -c feature/prompt-validation main
Switched to a new branch 'feature/prompt-validation'
$ git cherry-pick rescue/prompt-versioning
[feature/prompt-validation 499c20c] Validate prompt variables before save
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:26:00 2026 +0530
 1 file changed, 9 insertions(+)
 create mode 100644 registry/validate.py
$ git push -u origin feature/prompt-validation
To ../server.git
 * [new branch]      feature/prompt-validation -> feature/prompt-validation
branch 'feature/prompt-validation' set up to track 'origin/feature/prompt-validation'.
```
<!-- /snippet -->

A new branch from the current `main`, with the one commit that isn't merged, under a new name.

**Verify.**

<!-- snippet: incidents/solve-08-branch-disappeared/07-verify -->
```text
# What a pull request for the new branch would show:
$ git log --oneline origin/main..origin/feature/prompt-validation
499c20c Validate prompt variables before save
$ git diff --stat origin/main...origin/feature/prompt-validation
 registry/validate.py | 9 +++++++++
 1 file changed, 9 insertions(+)
$ git diff --stat rescue/prompt-versioning feature/prompt-validation
$ git branch -D rescue/prompt-versioning
Deleted branch rescue/prompt-versioning (was 70df7f7).
$ cd ..
$ incidents/08-branch-disappeared/check.sh
Checking incident 08-branch-disappeared
  ok    the server has the branch feature/prompt-validation
  ok    the branch has "Validate prompt variables before save"
  ok    the branch is based on the current main
  ok    a pull request for the branch would list one commit
  ok    a pull request for the branch would change registry/validate.py only
  ok    registry/validate.py has the content of the lost commit
  ok    main on the server still ends with the squash merge
  ok    the merged branch was not pushed again
PASS: the recovery of incident 08-branch-disappeared is complete.
[exit status: 0]
```
<!-- /snippet -->

A pull request for the new branch would list one commit and one file. The diff between the rescue branch and the new branch prints nothing: the new branch has everything the lost one had. Then the rescue branch goes, and the check passes. Read its last line: "the merged branch was not pushed again".

**[ANIMATION]** cards: id=verdict2 cards=Ravi's_report_suspects_a_command:git_pull|Asha's_report_suspects_the_server marks=1:ok,2:ok title=Two_reports,_two_suspects pace=quick at_marks=70

**The message to Asha.** Nothing was deleted by mistake. Three commits are in `main` as one. The fourth survived only in her reflog. So the server, the second suspect, is cleared too.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Accepting the suspect named in the report.** Root cause: "pull ate my work" and "the server lost my branch" are interpretations; the reflog had no pull entry, and the server never had the fourth commit.
2. **Recovering from a hard reset with another hard reset.** Root cause: the branch has moved on since the accident, so moving it back discards the commit made afterwards.
3. **Promising to recover everything.** Root cause: unstaged work was never written to the object database, so there is nothing to recover it from.
4. **Trusting `git cherry` after a squash merge.** Root cause: patch IDs compare individual commits, and a squashed commit equals none of its parts.
5. **Recreating and pushing the merged branch.** Root cause: its commits are not ancestors of `main` although their content is there, so a pull request from it shows already-merged work again.

## PRODUCTION EXAMPLE

Now, out of the lab. A prompt-engineering team uses squash merges and automatic deletion of head branches. An engineer comes back from two days off, finds her branch gone everywhere, and can't find her commit messages on `main`. She is certain that the server lost her work, and she is about to ask an administrator to restore the branch from the closed pull request.

**[ANIMATION]** graph: *-S main; *-A-B-C-D; HEAD=main; reflog:A,B,C,D; note:S:the_squash_merge; note:D:committed_after_the_last_push => + D rescue; say:They_anchor_the_tip => + S-D′ new-branch; HEAD=new-branch; say:The_one_unmerged_commit_moves_to_a_new_branch id=prod at_state_1=40

**[ANIMATION]** step: state-1

A colleague asks one question first: "Did you commit anything after your last push?" Then he reads the reflog of HEAD with her. The answer is on the screen: one commit after the last push. Restoring the server's branch would have brought back the three commits that are already in `main` and not the one she needs, because the server never had it.

**[ANIMATION]** step: state-3

They anchor the tip, compare trees, and move the one unmerged commit to a new branch. The team's notes get two lines. A new branch after every merge. And "pushed" is read from `git status -sb`, not from memory. The colleague adds the line from the textbook's postmortem, because it's the one that changes behavior: the only copy of a day's work was a reflog entry, which by default expires 30 days after its commit becomes unreachable.

## PRACTICE EXERCISE

Your turn. Do Lab 36.1, "An accidental `git reset --hard` (incident 1)", in [`lab-manual/m36-incident-drills-local.md`](../../lab-manual/m36-incident-drills-local.md), from a freshly generated sandbox and without your earlier notes.

Before you run the first command, predict which of the three kinds of work you'll be able to recover and from where. Before the lab's failure scenario, predict which lines of the check script the tempting recovery will fail. Type the recovery by hand. Your new commit IDs will differ from the book, because commits you make use the real clock.

The challenge is Lab 36.2, "A branch appears to have disappeared (incident 8)", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q396: "A developer says "my commits are gone". Which commands do you run before you touch anything, in which order, and what does each tell you?"

**[PAUSE]**

Answer out loud. The question asks for an order and a reason per command. A strong answer starts with the command whose first line can change everything that follows, moves from the current state to the history of the refs to the server, and says for each command what it rules in or out. It distinguishes the reflog of a branch from the reflog of HEAD and says when only one of them exists. It includes the command for work that was staged and never committed, and notes that this one writes files. It ends with the first change you would make, and why that change can't lose anything.

## RECAP

Let's land this.

- After a hard reset, committed work is in the reflog, staged work is in dangling blobs without names, and unstaged work is gone.
- Recover by adding the lost commits on top of the current tip, not by moving the branch back.
- A branch's reflog is deleted with the branch; the reflog of HEAD survives and holds the tip.
- After a squash merge, compare trees, not patch IDs, to find which work is where.
- Tell the person exactly what is back, what is not and why, and which command was not involved.

## HOMEWORK

Read sections 30.5 and 30.12. Compare your own attempt with [`solutions/incident-01-hard-reset.md`](../../solutions/incident-01-hard-reset.md) only now, line by line: where did your order of commands differ, and did any of your commands change state before you had named the cause? Then generate Incident 10 and Incident 9 and attempt both before the next video.

Two reports named two suspects, and the evidence cleared both. Practise the first recovery by hand before you go on. Next time, two more reports: "It is pushed. GitHub must be caching", and "My fix is in the log and not in the file". Until then, look at the state first and type second. See you in the next one.

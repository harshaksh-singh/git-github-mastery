# V060: Publishing a rebased branch, rebase or merge, and the rebase configuration

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 26
- **Prerequisites:** V042, V059
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), sections 9.17, 9.18, 9.19 and 9.20
- **Demo scripts:** `labs/ch09/force-push.sh`, `labs/ch09/force-lease-explicit.sh`, `labs/ch09/force-damage.sh`, `labs/ch09/merge-vs-rebase.sh`, and as a pointer `labs/ch09/replay-pointer.sh`

## HOOK

**[ON SCREEN]** "Asha pushed a commit to the feature branch on Tuesday. On Wednesday it was gone from GitHub, and after her next pull it was gone from her laptop as well. Nobody deleted anything. Where is it?"

This was the first of the four questions at the start of the module, and it's the last one to be answered.

**[ANIMATION]** remotes: [Asha's clone] 8afc6bd-1279adf-dc5df93-c60bc13 feat/ingest; HEAD=feat/ingest || [the server] 8afc6bd-1279adf-dc5df93-c60bc13 feat/ingest; HEAD=none; say:Tuesday:_Asha's_commit_c60bc13_is_on_the_server => || [the server] 8afc6bd-589d18b-0fbfd81-8aca274 feat/ingest; gone:1279adf,dc5df93,c60bc13; HEAD=none; name:forced; say:Wednesday:_gone_from_the_server => [Asha's clone] 8afc6bd-589d18b-0fbfd81-8aca274 feat/ingest; gone:1279adf,dc5df93,c60bc13; HEAD=feat/ingest; name:pulled; say:After_her_next_pull:_gone_from_her_branch_as_well || title=Where_is_Asha's_commit? fly=off id=lost

**[ANIMATION]** step: pulled

Two things happened. On Wednesday morning a colleague rebased the branch, which replaces its commits with new copies, and published it with `git push --force`. That removed Asha's commit from the server. Then Asha ran `git pull --rebase`, which reported success and removed the commit from her branch as well.

The commit is not destroyed. It's in exactly one place, and you'll find it. Where would you look first? Keep your guess. More usefully, you'll see the same Wednesday morning replayed with a push that refuses.

**[ANIMATION]** end

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video closes the rebase module, and it has three jobs.

First, publishing. After a rebase, a plain push is always rejected. That rejection is not an obstacle. It's the safety check. You have to overwrite the server's ref, its name for the branch, and the only choice is which conditions you attach. A lease is one such condition: overwrite only if the server's branch is still where you expect. You met it in the remotes module from the side of the push. Today you meet it from the side of the rebase, and you see what a bare `--force` costs the teammate.

Second, the question every team argues about: rebase or merge. You'll integrate the same work both ways and compare the results object by object, so that the argument can be about facts.

Third, the settings that make your chosen habits the default, and a short pointer to two experimental commands that the frontier part of the course covers.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Publish a rebased branch with a lease and `--force-if-includes`, and explain each guard.
- Describe the damage a bare `--force` does, and how the teammate recovers.
- Argue for a merge and for a rebase of the same integration.
- Justify each rebase setting you enable.
- Say what `git replay` and `git history` are, as pointers to Part 11.

## CONCEPT

**[ANIMATION]** graph: 8afc6bd-589d18b-5859371-321b338 feat/ingest; 589d18b main; 8afc6bd-1279adf-dc5df93 origin/feat/ingest; HEAD=feat/ingest => dc5df93-c60bc13 origin/feat/ingest; 321b338 feat/ingest; 589d18b main; HEAD=feat/ingest title=Your_clone,_after_your_rebase id=clone

**[ANIMATION]** step: state-1

**Publishing.** In one sentence: after a rebase the server's branch is not an ancestor of yours, so a normal push is refused. You have to overwrite the server's ref, and the only choice is which conditions you attach to the overwrite. On screen: your two new copies on top of `main`, and `origin/feat/ingest`, your record of the server's branch, still on the old pair.

**[ANIMATION]** end

Every forced push is 🔴 DANGEROUS: it replaces history on a remote. The forms differ in what must be true first.

**[ON SCREEN]** The table of section 9.17.

```text
Command                                               The server's ref is overwritten if
----------------------------------------------------  ---------------------------------------------------------------
git push --force                                      always
git push --force-with-lease                           it equals your origin/<branch>
git push --force-with-lease --force-if-includes       as above, and the tip of origin/<branch> is reachable from a
                                                      reflog entry of your local branch: your branch has contained
                                                      it at some point
git push --force-with-lease=<branch>:<expected ID>    it equals the ID you wrote
```

The account this course owes for a 🔴 command, from the textbook. A forced push changes the server's ref, for every ref the push covers. It can destroy commits that exist only on the server and in other people's clones. Preview with `git fetch` followed by `git log --oneline HEAD..origin/<branch>`, which lists what you are about to remove, or with `--dry-run`. Recovery depends on a clone that still has the commits. And appropriate use of plain `--force` and of the bare lease: none. The two guarded forms cost the same keystrokes, and with them everything removed from the server is something your clone has, so your own reflog, the local list of where your branch has been, can restore it.

That last sentence is the whole argument. With the guards, you can only remove what you hold.

**[ANIMATION]** merge: three-way feat/rerank into demo/merged common=8afc6bd main_only=589d18b,82f1fbb feature_only=5ee19f0,af65a92,bd62876 merge_id=9d34396 title=By_merge

**Rebase or merge.** Both integrate the same work, and both reach the same content. What differs is the history, and what that history costs for bisect, the search for the commit that changed a behaviour, for review, and for the people who share the branch.

**[ON SCREEN]** The comparison table of section 9.18.

```text
Question                                   Merge                                           Rebase
-----------------------------------------  ----------------------------------------------  ----------------------------------------------
Commit IDs of the branch                   Kept                                            New
Shape of history                           Fork and join are recorded                      One line
New snapshots that nobody ran              One: the merge result                           One per replayed commit
Conflicts                                  Resolved once, recorded in the merge commit     Resolved per commit, up to once for each
Record of what was integrated, and when    The merge commit; --first-parent reads as a     None
                                           list of integrations
Undoing the whole integration              One revert with -m 1                            One revert per commit, or of the range
On a branch that others use                Safe: it only adds commits                      Needs a forced push and everybody's cooperation
Reading and bisecting                      More paths to walk                              Simpler, provided every commit builds
```

The textbook's verdict: neither column wins. Three questions decide a given case. Is the branch shared? Then merge. What does the target branch require? Must every intermediate commit work? Then a rebase needs `--exec`, or a squash.

**Configuration.**

**[ON SCREEN]** The settings table of section 9.19.

```text
Setting                       Default                             Effect
----------------------------  ----------------------------------  --------------------------------------------------------
rebase.autoSquash             false                               --autosquash for interactive rebases
rebase.autoStash              false                               --autostash for every rebase
rebase.updateRefs             false                               --update-refs for every rebase
rebase.missingCommitsCheck    ignore                              warn or error when a line was deleted from the list
pull.rebase                   unset                               git pull rebases; true, merges or interactive
push.useForceIfIncludes       false                               Adds --force-if-includes to every lease
merge.conflictStyle           merge                               zdiff3 also shows the base in rebase conflicts
rerere.enabled                off unless .git/rr-cache exists     Records conflict resolutions and replays them
```

Every row has had its demonstration in this module or the ones before. The `git config set` and `get` subcommands need Git 2.46 or later. On older versions you write `git config --global rebase.autoSquash true`.

## MENTAL MODEL

**[ON SCREEN]** "A compare-and-swap. Who supplied the expected value?"

The textbook's analogy for publishing: a compare-and-swap. A plain force is an unconditional write. A lease is "set the ref to X only if it still is Y".

**[ANIMATION]** push: src=feat/ingest dst=feat/ingest local=321b338 remote=c60bc13 lease=dc5df93,c60bc13 lease_names=expected_(yours),actual_(server),verdict result=!_[rejected]_(stale_info) steps=refspec,lease,result title=A_lease_is_a_compare-and-swap id=lease

It breaks at Y. You don't type the expected value. Git reads it from your remote-tracking branch, and anything that fetches can change that behind your back. The two stronger forms repair the analogy in two different ways: `--force-if-includes` adds "and Y must be something my branch once contained", and the explicit form lets you type Y yourself.

**[ANIMATION]** step: merge

For rebase against merge, one sentence to keep: a merge records what happened, and a rebase records what you wish had happened. Both are legitimate.

The first is a log.

**[ANIMATION]** graph: 8afc6bd-589d18b-82f1fbb main; 8afc6bd-5ee19f0-af65a92-bd62876 feat/rerank demo/rebased; HEAD=demo/rebased => 82f1fbb-bbbc3e4-60fc46f-668e89e demo/rebased; 82f1fbb main; bd62876 feat/rerank; HEAD=demo/rebased title=By_rebase

**[ANIMATION]** step: state-2

The second is an edited account, and edited accounts are fine as long as every page of them has been checked, and as long as nobody else is holding the unedited pages.

## DIAGRAM

**[ANIMATION]** graph: 8afc6bd-589d18b-82f1fbb main; ^8afc6bd-5ee19f0-af65a92-bd62876 feat/rerank; 82f1fbb-9d34396 demo/merged; bd62876-9d34396; 82f1fbb-bbbc3e4-60fc46f-668e89e demo/rebased; HEAD=none; tree:9d34396:273096f; tree:668e89e:273096f => + tree:5ee19f0:bff5bbd; tree:af65a92:ece63c5; tree:bd62876:96ba5b8; tree:bbbc3e4:8cc3ece; tree:60fc46f:9b070ab; mark:never_run:bbbc3e4,60fc46f; name:trees dy=200 dx=300 title=The_same_work,_integrated_twice id=both

**[DIAGRAM]** New diagram. The same diverged pair of branches, integrated twice, one above the other. Write the tree ID of the final commit under both results.

```text
  start:            5ee19f0---af65a92---bd62876     feat/rerank
                   /
          8afc6bd---589d18b---82f1fbb               main

  by merge:         5ee19f0---af65a92---bd62876
                   /                           \
          8afc6bd---589d18b---82f1fbb-----------9d34396     demo/merged
                                                tree 273096f

  by rebase:
          8afc6bd---589d18b---82f1fbb---bbbc3e4---60fc46f---668e89e     demo/rebased
                                                            tree 273096f

  Same final tree. Merge: three original commits kept, one new snapshot.
  Rebase: three new commits, two of them snapshots that nobody ever ran.
```

**[ANIMATION]** step: state-1

The same diverged pair of branches, integrated twice. By merge: your three commits stay, and one new commit joins the two lines. By rebase: three new copies in one line. Look at the line under each final commit, and keep it in mind for the demo.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/force-push`. The shared branch of the last video, but this time Asha pushed "Add chunker" after your last fetch. You do not know that yet.

**Part 1: publishing with guards.**

<!-- snippet: ch09/force-push/01-rebase -->
```text
# Asha pushed "Add chunker" to feat/ingest after your last fetch. You do not know that yet.
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate --all
* 321b338 (HEAD -> feat/ingest) Add text cleaner
* 5859371 Add document loader
* 589d18b (origin/main, main) Add README
| * dc5df93 (origin/feat/ingest) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Your rebased copies, and `origin/feat/ingest` still on the old pair. A plain push:

<!-- snippet: ch09/force-push/02-plain-push -->
```text
$ git push
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

Rejected, "fetch first". That's the safety check, and it's telling you something you didn't know: the server has a commit you don't have. Now the lease.

<!-- snippet: ch09/force-push/03-lease -->
```text
$ git push --force-with-lease
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

`stale info`: the server has a commit that your `origin/feat/ingest` does not know. The lease did its job.

**[ANIMATION]** step: lease.result

Now the failure mode that the manual itself warns about. Something fetches for you: an editor, a status prompt, or you out of habit. Predict what a dry run of the same lease says afterwards. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/force-push/04-background-fetch -->
```text
# Something fetches for you: an editor, a status prompt, or you out of habit.
$ git fetch
From ../server
   dc5df93..c60bc13  feat/ingest -> origin/feat/ingest
# The lease now compares against the freshly fetched value. A dry run shows it would overwrite:
$ git push --force-with-lease --dry-run
To ../server.git
 + c60bc13...321b338 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

**[ANIMATION]** step: clone.state-2

The fetch moved `origin/feat/ingest` to Asha's commit. The server and your remote-tracking branch agree again, the lease is satisfied, and the dry run shows that the push would replace `c60bc13`, a commit you have never looked at. Careful people walk into this one.

<!-- snippet: ch09/force-push/05-if-includes -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (remote ref updated since checkout)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

"Remote ref updated since checkout." `c60bc13` is in no reflog entry of your branch, so your rewrite can't have been based on it. The fix is to rebase what is really there.

<!-- snippet: ch09/force-push/06-integrate -->
```text
# Rebase what is really on the server, then publish with both checks.
$ git reset --hard origin/feat/ingest
HEAD is now at c60bc13 Add chunker
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/ingest.
$ git push --force-with-lease --force-if-includes
To ../server.git
 + c60bc13...e3f3ba1 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

`git reset --hard origin/feat/ingest` 🔴, on a clean tree, with your earlier copies still in the reflog. Then the rebase replays three commits, hers included, and the guarded push is accepted.

<!-- snippet: ch09/force-push/07-result -->
```text
$ git log --oneline --graph --decorate --all
* e3f3ba1 (HEAD -> feat/ingest, origin/feat/ingest) Add chunker
* b4aeee4 Add text cleaner
* 33bc4fb Add document loader
* 589d18b (origin/main, origin/HEAD, main) Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

The explicit form doesn't depend on the remote-tracking branch at all. `labs/run ch09/force-lease-explicit`: you record the commit you rebased from.

<!-- snippet: ch09/force-lease-explicit/01-record-and-rebase -->
```text
# Before rewriting, record what the server had when you last looked.
$ git rev-parse origin/feat/ingest
dc5df9356273e7c0c2807ce808c378782ea2525a
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
```
<!-- /snippet -->

<!-- snippet: ch09/force-lease-explicit/02-fetch-then-push -->
```text
# Asha pushed in the meantime, and something fetched for you. The explicit lease still refuses:
$ git fetch
From ../server
   dc5df93..c60bc13  feat/ingest -> origin/feat/ingest
$ git push --force-with-lease=feat/ingest:dc5df9356273e7c0c2807ce808c378782ea2525a
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

Asha pushed, something fetched, and the explicit lease still refuses: the server is not at the ID you wrote.

<!-- snippet: ch09/force-lease-explicit/03-bare-lease-would-pass -->
```text
$ git push --force-with-lease --dry-run
To ../server.git
 + c60bc13...8aca274 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

And the bare lease, in the same state, would pass.

**Part 2: what plain `--force` does.** `labs/run ch09/force-damage`. The same situation. The server's branch first.

<!-- snippet: ch09/force-damage/01-server-before -->
```text
$ git -C ../server.git log --oneline feat/ingest
c60bc13 Add chunker
dc5df93 Add text cleaner
1279adf Add document loader
8afc6bd Add retriever and model config
```
<!-- /snippet -->

Asha's `c60bc13` is on the server. Now the careless push. The five answers were given in the Concept section. The answer to "when is it appropriate" was "never, for plain force". The demo runs it so that you can see the cost.

<!-- snippet: ch09/force-damage/02-force -->
```text
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
$ git push --force
To ../server.git
 + c60bc13...8aca274 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

<!-- snippet: ch09/force-damage/03-server-after -->
```text
$ git -C ../server.git log --oneline feat/ingest
8aca274 Add text cleaner
0fbfd81 Add document loader
589d18b Add README
8afc6bd Add retriever and model config
$ git -C ../server.git reflog show feat/ingest
```
<!-- /snippet -->

Asha's commit is gone from the server's branch, and the last command prints nothing. A bare repository, one with no working tree, like the server's, keeps no reflog by default, so the server can't tell you what the branch used to be. Tuesday's commit is "gone from GitHub". Then Asha pulls. Try it now, on paper. Thirty seconds: write the log you expect on her laptop.

**[PAUSE]**

<!-- snippet: ch09/force-damage/04-asha-pulls -->
```text
$ cd ../asha
$ git log --oneline --decorate -1
c60bc13 (HEAD -> feat/ingest, origin/feat/ingest) Add chunker
$ git pull --rebase
From ../server
 + c60bc13...8aca274 feat/ingest -> origin/feat/ingest  (forced update)
   8afc6bd..589d18b  main        -> origin/main
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate
* 8aca274 (HEAD -> feat/ingest, origin/feat/ingest) Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

**[ANIMATION]** step: lost.pulled

"Successfully rebased", and her branch is identical to the new upstream. "Add chunker" is not in it. Gone from her laptop as well. If you put her chunker on top, that was the reasonable guess.

<!-- snippet: ch09/force-damage/05-why -->
```text
$ git reflog show origin/feat/ingest
8aca274 refs/remotes/origin/feat/ingest@{0}: pull --rebase: forced-update
c60bc13 refs/remotes/origin/feat/ingest@{1}: update by push
$ git merge-base --fork-point origin/feat/ingest feat/ingest@{1}
c60bc13f871297055fb1d2e19bd6a39f7a4f1f62
```
<!-- /snippet -->

The reflog of her `origin/feat/ingest` holds `c60bc13`, "update by push", below the forced update.

**[ON SCREEN]** The root-cause box of section 9.17.

```text
Observed behavior : "git pull --rebase" reports success, and "Add chunker", a commit Asha had
                    pushed, is no longer in her branch. (The first question of section 9.1.)
Git state         : The reflog of her origin/feat/ingest holds c60bc13 ("update by push")
                    below the forced update.
Mechanism         : pull --rebase replays the commits after the fork point. The fork point is
                    the newest commit of her branch that was once the tip of
                    origin/feat/ingest: c60bc13, her own commit. Nothing comes after it, so
                    nothing is replayed, and her branch is set to the new upstream.
Root cause        : By pushing, she made the commit part of upstream. Upstream no longer has
                    it, and Git reads that as "upstream discarded this commit". Your force
                    push is what discarded it.
Why Git does this : It is the logic that repaired her history in section 9.15: do not replay
                    what upstream dropped.
Correct fix       : The commit is in the reflog of her branch:
                    git cherry-pick feat/ingest@{1}, then push.
Prevention        : No plain --force on a branch that anyone else pushes to. The lease with
                    --force-if-includes refused in exactly this situation.
```

The fork point is that commit, her own.

**[ANIMATION]** graph: 8afc6bd-589d18b-0fbfd81-8aca274 feat/ingest origin/feat/ingest; HEAD=feat/ingest; title:Asha's_clone => + 8afc6bd-1279adf-dc5df93-c60bc13 special:feat/ingest@{1}; reflog:1279adf,dc5df93,c60bc13; name:found; say:In_the_reflog_of_her_branch,_and_only_there => + 8aca274-82659ee feat/ingest origin/feat/ingest; drop:feat/ingest@{1}; name:back; say:Cherry-picked_as_82659ee,_then_pushed id=found at_state_1=2 at_found=25

**[ANIMATION]** step: found

So where is it? In the reflog of her branch, and only there. Was that your guess?

<!-- snippet: ch09/force-damage/06-asha-recovers -->
```text
$ git reflog show feat/ingest -2
8aca274 feat/ingest@{0}: pull --rebase (finish): refs/heads/feat/ingest onto 8aca274dbad90b9d7b5ad3a578f59a5283073474
c60bc13 feat/ingest@{1}: commit: Add chunker
$ git cherry-pick feat/ingest@{1}
[feat/ingest 82659ee] Add chunker
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 ingest/chunker.py
$ git push
To ../server.git
   8aca274..82659ee  feat/ingest -> feat/ingest
$ git log --oneline --graph --decorate
* 82659ee (HEAD -> feat/ingest, origin/feat/ingest) Add chunker
* 8aca274 Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

`feat/ingest@{1}`, "commit: Add chunker". `git cherry-pick` 🟡 puts it on the new tip as `82659ee`, and an ordinary push publishes it.

**[ANIMATION]** step: found.back

Tuesday's commit is back on her branch, with a new ID, and back on the server.

**Part 3: rebase or merge.** `labs/run ch09/merge-vs-rebase`. Integrate the same work twice.

<!-- snippet: ch09/merge-vs-rebase/01-merge -->
```text
$ git switch -c demo/merged main
Switched to a new branch 'demo/merged'
$ git merge feat/rerank
Auto-merging config/model.yaml
Merge made by the 'ort' strategy.
 app/rerank.py     | 2 ++
 app/retriever.py  | 2 +-
 config/model.yaml | 1 +
 3 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 app/rerank.py
$ git log --oneline --graph --decorate demo/merged
*   9d34396 (HEAD -> demo/merged) Merge branch 'feat/rerank' into demo/merged
|\  
| * bd62876 (feat/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
* | 82f1fbb (main) Upgrade model to small-v2
* | 589d18b Add README
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/merge-vs-rebase/02-rebase -->
```text
$ git switch -c demo/rebased feat/rerank
Switched to a new branch 'demo/rebased'
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/demo/rebased.
$ git log --oneline --graph --decorate demo/rebased
* 668e89e (HEAD -> demo/rebased) Enable reranking in config
* 60fc46f Call reranker from retriever
* bbbc3e4 Add reranker skeleton
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Quick quiz, two options. Are the two final trees, the two final sets of files, equal? Option one: yes, to the byte. Option two: no. Say it out loud.

**[PAUSE]**

<!-- snippet: ch09/merge-vs-rebase/03-same-content -->
```text
$ git rev-parse "demo/merged^{tree}" "demo/rebased^{tree}"
273096fac387738589eb6596acff61b6fb3cf487
273096fac387738589eb6596acff61b6fb3cf487
$ git diff --stat demo/merged demo/rebased
```
<!-- /snippet -->

**[ANIMATION]** step: both.state-1

Option one. The same tree, to the byte, and an empty diff. What differs is everything else.

<!-- snippet: ch09/merge-vs-rebase/04-snapshots -->
```text
# Commit, tree and subject of everything that is new relative to main, for each result:
$ git log --format="%h tree %t  %s" main..demo/merged
9d34396 tree 273096f  Merge branch 'feat/rerank' into demo/merged
bd62876 tree 96ba5b8  Enable reranking in config
af65a92 tree ece63c5  Call reranker from retriever
5ee19f0 tree bff5bbd  Add reranker skeleton
$ git log --format="%h tree %t  %s" main..demo/rebased
668e89e tree 273096f  Enable reranking in config
60fc46f tree 9b070ab  Call reranker from retriever
bbbc3e4 tree 8cc3ece  Add reranker skeleton
```
<!-- /snippet -->

The merge added one new snapshot, the merge commit, and kept your three commits with the trees you built and tested.

**[ANIMATION]** step: both.trees

The rebase produced three new commits. Two of their trees, `8cc3ece` and `9b070ab`, are combinations of your early commits with `main` that nobody has ever run.

<!-- snippet: ch09/merge-vs-rebase/05-first-parent -->
```text
$ git log --oneline --first-parent main..demo/merged
9d34396 Merge branch 'feat/rerank' into demo/merged
$ git log --oneline --first-parent main..demo/rebased
668e89e Enable reranking in config
60fc46f Call reranker from retriever
bbbc3e4 Add reranker skeleton
```
<!-- /snippet -->

Read along first parents, the merged history says "one feature landed" and the rebased one lists three changes.

<!-- snippet: ch09/merge-vs-rebase/06-who-contains-the-originals -->
```text
$ git branch --contains feat/rerank
  demo/merged
  feat/rerank
$ git log --format="%h authored %ad, committed %cd  %s" --date=format:%H:%M main..demo/rebased
668e89e authored 10:05, committed 10:12  Enable reranking in config
60fc46f authored 10:04, committed 10:12  Call reranker from retriever
bbbc3e4 authored 10:03, committed 10:12  Add reranker skeleton
```
<!-- /snippet -->

And the question of who still contains the original commits has a different answer in the two results. `demo/merged` is listed, and `demo/rebased` is not. And the rebased copies keep their author times, with one new committer time.

**Part 4: a pointer.** `labs/run ch09/replay-pointer`. Two experimental commands do parts of this chapter's work without its machinery. Chapter 14D covers them. `git replay` replays a range onto a new base without touching the working tree or the index, so it also works in a bare repository.

<!-- snippet: ch09/replay-pointer/01-replay -->
```text
$ git status --short --branch
## main
$ git replay --onto=main main..feat/rerank
[exit status: 0]
$ git log --oneline --graph --decorate --all
* 4caa98e (feat/rerank) Enable reranking in config
* 20d0897 Call reranker from retriever
* 0dea106 Add reranker skeleton
* 82f1fbb (HEAD -> main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
$ git reflog show feat/rerank -2
4caa98e feat/rerank@{0}: replay --onto 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
bd62876 feat/rerank@{1}: commit: Enable reranking in config
```
<!-- /snippet -->

`feat/rerank` was rebased while `main` stayed checked out, and no state directory was involved. The price of having no working tree is that it can't stop for a conflict: on a conflict it exits with status 1 and leaves the branch where it was. The textbook's version facts: introduced in Git 2.44 as a server-side tool. It updates refs itself since 2.53. Its `--linearize` option was added in Git 2.56, not run here.

`git history`, new in Git 2.54, offers single-purpose rewrites: `reword`, `split` and, since 2.55, `fixup`. `drop` was added in Git 2.56, not run here. Both manual pages carry the word EXPERIMENTAL in their first line.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Publishing a rebased branch with plain `--force`.** Root cause: the overwrite is unconditional, so commits that exist only on the server and in other clones are removed, and a bare server has no reflog of them.
2. **Trusting the bare lease in an environment that fetches in the background.** Root cause: the expected value is read from the remote-tracking branch, which any fetch refreshes.
3. **Reading the push rejection after a rebase as an error to get past.** Root cause: the rejection is the fast-forward check doing its job; here it revealed a commit you had not seen.
4. **Arguing "rebase gives a clean history" without testing the intermediate commits.** Root cause: each replayed commit is a new snapshot that nobody ran; a linear history helps bisect only if every commit builds.
5. **Rebasing a shared branch because the team "prefers linear history".** Root cause: on a branch others use, a rebase needs a forced push and everybody's cooperation, while a merge only adds commits.

## PRODUCTION EXAMPLE

**[ON SCREEN]** A team rule in four lines.

Now, out of the lab. Here's a rule that a backend team for LLM serving could write after a Wednesday morning like that one, built from this chapter.

**[ANIMATION]** cards: cards=Rebase_in_private|Publish_with_both_guards|On_a_branch_somebody_else_pushes_to,_merge|Let_the_pull_request's_merge_method_decide_what_lands_on_main numbered=on question=A_team_rule_in_four_lines id=rule

**[ANIMATION]** step: 1

One: rebase in private. On the branch of your own pull request, rebase as you like, with `--exec` when the history is going to be kept.

**[ANIMATION]** step: rule.2

Two: publish with both guards. `git config set --global push.useForceIfIncludes true` adds the second check to every lease. The textbook notes that editors and prompts that fetch in the background are the usual way the bare lease is defeated. The manual's own example is a scheduled `git fetch`.

**[ANIMATION]** step: rule.3

Three: on a branch somebody else pushes to, merge.

**[ANIMATION]** step: rule.4

Four: let the pull request's merge method decide what lands on `main`.

**[ANIMATION]** end

**[ON SCREEN]** Layer label: GitHub.

Two platform facts from the textbook, described from the documentation. A "Require linear history" rule on GitHub blocks merge commits, which leaves squash or rebase. And after an accepted forced push, pull requests for the branch follow it. Where the rules dismiss stale approvals, an approval is dismissed when the diff changes. The interface changes. The linked documentation in the chapter is the reference.

## PRACTICE EXERCISE

Your turn. Do Exercise 9.9, Level 4, "the morning rebase that replays somebody else's commits", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Predict before each state-changing command:

- The list of commits your rebase is about to replay, and whether each one is yours.
- After the rebase: what a plain push will say, and why that is useful.
- For each of the three forced forms: accepted or rejected in this state, and on what comparison.

The challenge is Incident 5, [`incidents/05-rebased-shared-branch`](../../incidents/05-rebased-shared-branch/SYMPTOMS.md). Read the symptoms file only.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q156: "Compare `--force`, `--force-with-lease`, and `--force-with-lease --force-if-includes`. Describe a sequence of events in which the second overwrites a colleague's commit and the third refuses."

**[PAUSE]**

Answer out loud first. A strong answer states for each of the three the condition under which the server's ref is overwritten, in terms of specific refs and reflogs. Then it tells the sequence as a timeline with three actors, you, the server and the colleague, and marks the one step at which the second form's condition becomes true without your having seen anything. It says exactly what the third form checks at that moment and why the check fails. Close with the setting that makes the third form your default.

## RECAP

Let's land this. You should now be able to say, in your own words:

**[ANIMATION]** walk: columns=push,overwrites_if,in_the_demo rows=--force:always:overwrites_c60bc13|--force-with-lease:server_=_your_origin/<branch>:refused,_until_something_fetches|+_--force-if-includes:and_your_branch_once_held_that_tip:refused|explicit_lease:server_=_the_ID_you_wrote:refused marks=1.3:bad,2.3:wait,3.3:ok,4.3:ok mono=off title=What_must_be_true_before_the_overwrite id=forms

After a rebase a plain push is rejected, and that rejection is the safety check. I publish with `--force-with-lease --force-if-includes`, or with an explicit lease, so that I can only remove from the server what my own clone holds. Plain `--force` and the bare lease have no appropriate use on a branch others push to. A commit that a forced push removed, and that a teammate's `pull --rebase` then dropped, is still in the reflog of the teammate's branch.

**[ANIMATION]** step: both.trees

Merge and rebase reach the same tree. The merge keeps the tested commits and records the integration. The rebase gives one line of new, untested snapshots. On a shared branch I merge. I enable each rebase setting for a reason I can state.

## HOMEWORK

Read sections 9.17 to 9.23 of [Chapter 9](../../textbook/ch09-rebase.md) and do the Practice section 9.25.

That closes the rebase module. You can rewrite a branch, publish it safely, and find your way back. Do the exercise before the next video. Next time: what cherry-pick does, a three-way merge that makes a new commit. Until then, look at the state first and type second. See you in the next one.

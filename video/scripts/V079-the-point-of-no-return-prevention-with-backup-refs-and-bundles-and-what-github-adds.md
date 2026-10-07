# V079: The point of no return, prevention with backup refs and bundles, and what GitHub adds

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 22
- **Prerequisites.** V078
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), sections 13.13 to 13.18
- **Demo scripts.** `labs/ch13/gc-ladder.sh`, `labs/ch13/lab-12-12-point-of-no-return.sh`, `labs/ch13/backup-and-bundle.sh`

## HOOK

**[ON SCREEN]** Two lines:

```bash
git reflog expire --expire=now --all
git gc --prune=now
```

These two commands appear in blog posts under headings like "clean up your repository" and "make Git smaller". They're also the documented way to destroy the safety net that the last six videos relied on. After them, `git reflog` prints nothing, `git fsck --lost-found` prints nothing, and a commit that was recoverable a minute ago doesn't exist.

There is one situation in which you want exactly that. A secret was committed and never pushed, and it must not survive in that clone. And there's every other situation, where someone runs the pair during an incident and turns a five-minute recovery into a permanent loss.

A senior engineer has to know both: how to reach the point of no return on purpose, and how to make sure nobody reaches it by accident. One question to carry with you: after those two commands, can anything still bring the commit back?

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the last content video of the recovery module. You've recovered commits from reflogs, from `git fsck`, from other clones. A reflog is your clone's own list of the values a name has had. Today you walk the ladder in the other direction, from "a reflog names it" down to "the object is deleted", one command per step, so that you can show each state.

Then prevention, which is cheaper than any recovery: a backup ref before a risky operation, and a bundle as an offline backup. And last, the server side: what GitHub adds, described from its documentation and not from a run.

You'll hear layer two, three and four today. Those are the four layers of protection from the start of this module: refs, reflogs, the grace period, and other repositories.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- describe the sequence that destroys the safety net, and when it is appropriate;
- show each step from "reflog protects it" to "pruned";
- protect work before a risky operation with a backup ref;
- create, verify and use a bundle as an offline backup;
- say which evidence GitHub keeps on the server side, as the cited section states it.

## CONCEPT

**[ANIMATION]** graph: id=lost title=A_lost_commit_is_still_an_object ...older-da62b60-dbe6ec8 main; HEAD=main => ...older-da62b60 main; da62b60-dbe6ec8 HEAD@{1}; HEAD=main; reflog:dbe6ec8; cmd:!git_reset_--hard_HEAD~1; say:No_branch_reaches_dbe6ec8,_but_a_reflog_entry_names_it => + drop:HEAD@{1}; ghost:dbe6ec8; dangling:dbe6ec8; cmd:!git_reflog_expire_--expire=now_--all; say:Step_one,_destructive:_nothing_names_it,_the_object_still_exists; name:expire => + gone:dbe6ec8; cmd:!git_gc_--prune=now; say:Step_two,_destructive:_the_object_is_deleted; name:prune twig_expire=worried twig_prune=worried

**[ANIMATION]** step: state-2

In one sentence: a lost commit becomes unrecoverable in two steps. First the last reflog entry that names it is removed. Then a collection, Git's housekeeping run, deletes the object. And two commands can force both steps at once. On screen is today's lost commit, `dbe6ec8`: a hard reset moved `main` off it, so no branch reaches it.

Precisely. The destructive pair is the documented procedure for shrinking a repository after a history rewrite. The manual of `git filter-branch` lists it in a checklist and calls it "a very destructive approach". For the same reason it's the documented way to destroy the safety net.

**[ANIMATION]** step: prune

Inside the dot git folder, step one truncates files in the logs folder. Step two rewrites the pack folder under objects, and removes loose object files. The working tree, the index, HEAD and the current branch are unchanged by both.

**[ON SCREEN]** The table of 🔴 commands from section 13.13. These are the five answers for each.

`git reflog expire --expire=now --all`. What it changes: it empties every reflog, the stash list included. What it can destroy: every layer-two protection, and the list of all stash entries except the newest. Preview: `git reflog expire --dry-run --verbose`. Recovery: the objects still exist, so `git fsck`, until a prune. Appropriate when: a secret must be purged after a history rewrite.

`git gc --prune=now`. What it changes: it repacks and deletes all unreachable objects. What it can destroy: everything on layer three. Preview: `git prune -n`, and `git fsck --unreachable`. Recovery: none in this repository, only layer four. Appropriate when: the same purge, with no other process using the repository. The manual attaches a second warning: `--prune=now` "increases the risk of corruption if another process is writing to the repository concurrently". An object that a running command has written and not yet attached to a ref looks unreachable.

`git prune`: deletes unreachable loose objects with no grace period unless `--expire` is given. The manual says to run `git gc` instead.

And for contrast, plain `git gc` is 🟡 CAUTION: it repacks, expires reflogs by the configured periods, and deletes unreachable objects older than two weeks. Routine housekeeping.

**Automatic maintenance.** You rarely run `git gc` yourself. Some commands start maintenance when they finish. Since Git 2.54 that automatic run uses the geometric strategy and not the `gc` task. It expires data in the reflog and puts unreachable objects into a cruft pack, a pack for unreachable objects with a file that records each object's age. Cruft packs are the default from Git 2.41. The retention periods you learned hold under either strategy. The manual of `git gc` still describes the older trigger, so read "automatic gc" in older texts as "automatic maintenance".

**[ANIMATION]** graph: da62b60-155d4ba-68e6fff-72b1150 feature/rerank; da62b60 main; HEAD=feature/rerank => da62b60 main; 72b1150 feature/rerank backup/rerank-before-squash; HEAD=feature/rerank => da62b60 main; 155d4ba-120120d feature/rerank; 72b1150 backup/rerank-before-squash; HEAD=feature/rerank title=A_backup_ref_before_a_risky_rebase dx=260

**[ANIMATION]** step: state-1

**Prevention, part one: a backup ref.** A branch costs one small file. Here's a branch from today's demo, three commits ahead of `main`, about to be squashed by a rebase.

**[ANIMATION]** step: state-2

Created before a rebase, a history filter, a large merge or a reset, a backup branch turns recovery into one command that needs no reflog, no search and no deadline.

**[ANIMATION]** step: state-3

After the rebase, the branch ends in a new commit, and the backup still names the old ones. You compare against a name, not against a reflog position that moves.

**[ANIMATION]** end

**Prevention, part two: a bundle.** In one sentence: `git bundle` writes refs and the objects they reach into one file that Git can clone and fetch from. Precisely, a bundle is a pack file with a header that lists refs. 🟢 SAFE: `git bundle create <file> --all` includes every ref and writes one file outside `.git`.

**[ANIMATION]** stores: boxes=*the_repository:.git|a_bundle:one_file_outside_.git rows=1:A:refs|1:A:the_objects_they_reach|1:B:header:_a_list_of_refs|1:B:a_pack_file|2:A:reflogs@dim|2:A:the_index@dim|2:A:hooks,_configuration@dim|2:A:older_stash_entries@dim|2:A:untracked_files@dim arrows=1:A1>B1:|1:A2>B2: title=What_a_bundle_holds,_and_what_it_does_not

What a bundle doesn't hold: reflogs, the index, hooks, the configuration, untracked files, and of the stash at most the newest entry. For stashes, Git 2.51 added `git stash export` and `git stash import`. A copy of the whole directory, made while no Git command runs, holds everything, and verifies nothing. For a repository you can't afford to lose, use both kinds, and run `git fsck` on the copy.

## MENTAL MODEL

**[ANIMATION]** ladder: commit=dbe6ec8 rungs=a_reflog_entry_names_it:git_reset_--hard_<id>|the_object_exists,_unnamed:git_fsck,_then_git_branch|the_object_is_deleted:another_clone,_the_server,_a_bundle,_a_backup title=Three_rungs at_2=45

**[ANIMATION]** step: 1

Return to the vault one last time, and picture a ladder with three rungs.

**[ANIMATION]** step: 2

On the top rung, the ledger mentions the box. You recover it by name. On the middle rung, the ledger line has been erased. The box is on the shelf, unmentioned. You recover it by search.

**[ANIMATION]** step: 3

On the bottom rung, the clear-out has emptied the box. There's nothing in this vault to find.

Normally time and maintenance take a box down the ladder slowly: 30 or 90 days for the first step, two weeks of object age and a collection for the second. The destructive pair kicks it down both steps at once.

**[ANIMATION]** end

A backup ref is an index card you write before the risky operation, so the box never leaves the front desk. A bundle is a sealed copy of the boxes and cards, stored in another building. The analogy breaks at one point: the sealed copy contains no ledger. A bundle has no reflogs.

## DIAGRAM

Try it now, on paper. Pause me for thirty seconds and draw the ladder from memory: three states, two arrows down. Then check your answer.

**[PAUSE]**

**[DIAGRAM]** The ladder of section 13.13. Draw the three states first, then add the command on each arrow.

```text
  reflog entry exists      -->  git reset --hard <id>            recoverable, by name
          |
          |  git reflog expire --expire=now --all      (or: 30 or 90 days, then maintenance)
          v
  object exists, unnamed   -->  git fsck ; git branch x <id>     recoverable, by search
          |
          |  git gc --prune=now                        (or: older than two weeks, then maintenance)
          v
  object deleted           -->  another clone, the server, a bundle, a backup        ... or nothing
```

Each arrow down has two labels: the command that forces the step, and the slow path that takes it by default. Each state has, on its right, the tool that still works there.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/gc-ladder`. You saw its first snippet in the opening video of this module. The commit `dbe6ec8` was removed from its branch by a hard reset, and a collection with no grace period did not touch it, because a reflog entry named it.

<!-- snippet: ch13/gc-ladder/01-reflog-protects -->
```text
$ git reflog -2
da62b60 HEAD@{0}: reset: moving to HEAD~1
dbe6ec8 HEAD@{1}: commit: Add cache TTL
$ git prune -n
$ git gc --prune=now
$ git cat-file -t dbe6ec8
commit
$ git count-objects -v | grep -e "^count" -e in-pack
count: 0
in-pack: 12
```
<!-- /snippet -->

Top rung. Now the first step down, in a second copy of the repository. The five answers for `git reflog expire --expire=now --all` are on screen. `git prune -n` is 🟢 SAFE: it only lists.

```bash
git reflog expire --expire=now --all
git fsck
git prune -n
```

Predict how many objects an immediate prune would delete for one lost commit. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch13/gc-ladder/02-preview -->
```text
$ cd ../searchsvc
$ git reflog expire --expire=now --all
$ git fsck
dangling commit dbe6ec85eb878f765ce8aad54c6e44b160a5efbb
$ git prune -n
76020a0a06a8e075a0095bdd4e66f5adfc4bad1b blob
dbe6ec85eb878f765ce8aad54c6e44b160a5efbb commit
e0c634deb63e58e853366c3dc3cff67a35e6aaa2 tree
```
<!-- /snippet -->

**[ANIMATION]** objects: cards=commit:dbe6ec8:tree_e0c634d+parent_da62b60+Add_cache_TTL,tree:e0c634d:blob_76020a0_cache.yaml+blob_5501ef2_embed.py+blob_eda7f04_retriever.yaml,blob:76020a0 title=What_git_prune_-n_lists

Three: the commit, its tree, and the one blob that no other commit shares. `git fsck` now reports the commit as dangling. Middle rung: it's still fully readable.

A collection that respects a grace period doesn't delete such objects. The transcript uses `--prune=never` so that it doesn't depend on a clock. A plain `git gc` behaves the same way for objects younger than two weeks.

```bash
git gc --prune=never
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
git cat-file -t dbe6ec8
```

<!-- snippet: ch13/gc-ladder/03-cruft-pack -->
```text
# A collection that prunes nothing ("never"; the default cut-off is two weeks):
$ git gc --prune=never
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 12
packs: 2
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   2 idx
   1 mtimes
   2 pack
   2 rev
$ git cat-file -t dbe6ec8
commit
$ git fsck
dangling commit dbe6ec85eb878f765ce8aad54c6e44b160a5efbb
```
<!-- /snippet -->

Twelve objects in two packs. One of the packs has a file with the extension `mtimes`: that's the cruft pack. The commit is still there.

**[PAUSE]** Before the next command, the five answers for `git gc --prune=now` once more, aloud. It deletes all unreachable objects. It destroys everything on layer three. The preview was `git prune -n`, which you have read. Recovery in this repository: none. Appropriate: a deliberate purge, with no other process using the repository. This is a sandbox built for the purpose.

```bash
git gc --prune=now
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
git cat-file -t dbe6ec8
git fsck
```

<!-- snippet: ch13/gc-ladder/04-prune-now -->
```text
$ git gc --prune=now
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 9
packs: 1
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 idx
   1 pack
   1 rev
$ git cat-file -t dbe6ec8
fatal: Not a valid object name dbe6ec8
[exit status: 128]
$ git fsck
```
<!-- /snippet -->

Nine objects in one pack. "Not a valid object name". And `git fsck` reports nothing: the repository is healthy, and the commit doesn't exist. Bottom rung.

**[TERMINAL]** Replay `labs/run ch13/lab-12-12-point-of-no-return`. The same ladder in a feature-store project, and then every tool of this module tried against the result.

<!-- snippet: ch13/lab-12-12-point-of-no-return/01-level-reflog -->
```text
$ cd featurestore
$ git log --oneline
b7b5704 Add feature schema
46ab313 Add feature store client
$ git reflog -2
b7b5704 HEAD@{0}: reset: moving to HEAD~1
833b96f HEAD@{1}: commit: Add online store TTL
$ git cat-file -t 833b96f
commit
$ git fsck
dangling blob 3d7644e23622f82d93183edaf4e33904b6a09425
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-12-point-of-no-return/02-expire -->
```text
$ git reflog expire --expire=now --all
$ git reflog
$ git fsck
dangling commit 833b96ffadd6f6df8eda80e107db9dd80a508892
dangling blob 3d7644e23622f82d93183edaf4e33904b6a09425
$ git log --oneline -1 833b96f
833b96f Add online store TTL
$ git count-objects -v | grep -e "^count" -e in-pack
count: 10
in-pack: 0
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-12-point-of-no-return/03-prune -->
```text
$ git gc --prune=now
$ git count-objects -v | grep -e "^count" -e in-pack
count: 0
in-pack: 6
$ git cat-file -t 833b96f
fatal: Not a valid object name 833b96f
[exit status: 128]
```
<!-- /snippet -->

`833b96f` went from a reflog entry, to a dangling commit, to nothing. Now the proof. Quick quiz first. The file `ORIG_HEAD` still holds that ID. Option one: so Git can still read the commit. Option two: the ID is there, the object isn't. Say it out loud.

**[PAUSE]**

```bash
git reflog
git fsck --lost-found
cat .git/ORIG_HEAD
git cat-file -t ORIG_HEAD
git branch rescue/ttl 833b96f
```

<!-- snippet: ch13/lab-12-12-point-of-no-return/04-proof -->
```text
$ git reflog
$ git fsck --lost-found
$ cat .git/ORIG_HEAD
833b96ffadd6f6df8eda80e107db9dd80a508892
$ git cat-file -t ORIG_HEAD
fatal: git cat-file: could not get object info
[exit status: 128]
$ git branch rescue/ttl 833b96f
fatal: not a valid object name: '833b96f'
[exit status: 128]
```
<!-- /snippet -->

Option two. The reflog is empty. `git fsck` finds nothing. `ORIG_HEAD` still holds the ID of the deleted commit and resolves to nothing: it's a file, not a starting point for reachability. And you can't create a branch at an object that doesn't exist.

**[ANIMATION]** remotes: id=bundle title=Layer_four:_a_bundle_kept_from_before [featurestore] 46ab313-b7b5704 main; HEAD=main; say:In_this_repository_833b96f_no_longer_exists || [featurestore-backup.bundle] 46ab313-b7b5704-833b96f main; HEAD=none => [featurestore] 46ab313-b7b5704 main; b7b5704-833b96f rescue/ttl; HEAD=main; cmd:git_fetch_../featurestore-backup.bundle_main:rescue/ttl; say:The_same_content,_so_the_same_ID:_833b96f ||

**[ANIMATION]** step: state-1

What can still bring the commit back? That was the opening question, and the answer is: only layer four. The lab kept a bundle from before.

```bash
git bundle verify ../featurestore-backup.bundle
git fetch ../featurestore-backup.bundle main:rescue/ttl
git log --oneline rescue/ttl
git cat-file -t 833b96f
```

<!-- snippet: ch13/lab-12-12-point-of-no-return/07-recovery-bundle -->
```text
$ cd ../featurestore
$ git bundle verify ../featurestore-backup.bundle
../featurestore-backup.bundle is okay
The bundle contains these 2 refs:
833b96ffadd6f6df8eda80e107db9dd80a508892 refs/heads/main
833b96ffadd6f6df8eda80e107db9dd80a508892 HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
$ git fetch ../featurestore-backup.bundle main:rescue/ttl
From ../featurestore-backup.bundle
 * [new branch]      main       -> rescue/ttl
$ git log --oneline rescue/ttl
833b96f Add online store TTL
b7b5704 Add feature schema
46ab313 Add feature store client
$ git cat-file -t 833b96f
commit
```
<!-- /snippet -->

**[ANIMATION]** step: bundle.state-2

A fetch from a file. The commit is back, with the same ID, because the ID is computed from the content.

**[TERMINAL]** Replay `labs/run ch13/backup-and-bundle`. Prevention. A branch with a fixup commit, about to be squashed.

```bash
git log --oneline main..HEAD
git branch backup/rerank-before-squash
git rebase -q --autosquash main
git log --oneline main..HEAD
```

<!-- snippet: ch13/backup-and-bundle/01-backup-ref -->
```text
$ git log --oneline main..HEAD
72b1150 fixup! Rerank the top 20
68e6fff Rerank the top 20
155d4ba Add reranker
$ git branch backup/rerank-before-squash
$ git rebase -q --autosquash main
$ git log --oneline main..HEAD
120120d Rerank the top 20
155d4ba Add reranker
```
<!-- /snippet -->

One command before the rebase. Now use the name to check the result.

```bash
git diff --stat backup/rerank-before-squash HEAD
git range-diff main backup/rerank-before-squash HEAD
git reset --hard backup/rerank-before-squash
git log --oneline main..HEAD
```

<!-- snippet: ch13/backup-and-bundle/02-compare-and-restore -->
```text
$ git diff --stat backup/rerank-before-squash HEAD
$ git range-diff main backup/rerank-before-squash HEAD
1:  155d4ba = 1:  155d4ba Add reranker
2:  68e6fff < -:  ------- Rerank the top 20
3:  72b1150 < -:  ------- fixup! Rerank the top 20
-:  ------- > 2:  120120d Rerank the top 20
# Had the result been wrong, one command would undo it, with no reflog involved:
$ git reset --hard backup/rerank-before-squash
HEAD is now at 72b1150 fixup! Rerank the top 20
$ git log --oneline main..HEAD
72b1150 fixup! Rerank the top 20
68e6fff Rerank the top 20
155d4ba Add reranker
```
<!-- /snippet -->

The empty `git diff --stat` proves that the squashed branch has the same content as the original. `git range-diff` shows how the commits map. Had the result been wrong, one reset to the backup name would undo it, with no reflog involved. The script runs it to show that. Delete the backup when the result is pushed and verified.

```bash
git bundle create ../searchsvc-2026-09-07.bundle --all
git bundle verify ../searchsvc-2026-09-07.bundle
```

<!-- snippet: ch13/backup-and-bundle/03-bundle-create -->
```text
$ git bundle create ../searchsvc-2026-09-07.bundle --all
$ git bundle verify ../searchsvc-2026-09-07.bundle
../searchsvc-2026-09-07.bundle is okay
The bundle contains these 5 refs:
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/backup/rerank-before-squash
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/feature/rerank
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/heads/main
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/tags/v0.3.0
72b11500bad27ce9dc19833da51fca7015d8655c HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

"is okay", five refs, "records a complete history". Verify every bundle you intend to rely on.

```bash
git bundle list-heads ../searchsvc-2026-09-07.bundle
git clone -q ../searchsvc-2026-09-07.bundle ../restored
git -C ../restored log --oneline --graph --all
```

<!-- snippet: ch13/backup-and-bundle/04-bundle-use -->
```text
$ git bundle list-heads ../searchsvc-2026-09-07.bundle
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/backup/rerank-before-squash
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/feature/rerank
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/heads/main
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/tags/v0.3.0
72b11500bad27ce9dc19833da51fca7015d8655c HEAD
$ git clone -q ../searchsvc-2026-09-07.bundle ../restored
$ git -C ../restored log --oneline --graph --all
* 72b1150 fixup! Rerank the top 20
* 68e6fff Rerank the top 20
* 155d4ba Add reranker
* da62b60 Raise top_k to 10
* 536f5df Add embedding client
* 538ea2f Add retriever config
```
<!-- /snippet -->

A clone from a file, with the full graph.

**[ON SCREEN]** Lower third: **GitHub**. Everything in this segment is a feature of the GitHub platform. It is described from GitHub's documentation, not from a run, and the interface changes; the linked documentation in section 13.15 is the reference.

Git gives a server no reflog by default, and you can't run `git reflog` or `git fsck` on GitHub's copy of your repository. The section lists GitHub's own instruments. Open your own practice repository and find each one as I name it.

**[ANIMATION]** cards: question=What_GitHub_adds,_as_its_documentation_describes_it cards=Activity_view:pushes,_force_pushes,_merges,_branch_creations_and_deletions|"Restore_branch":only_for_branches_that_had_a_pull_request|Events_API:the_last_300_events_and_30_days|Git_references_API:works_only_while_GitHub_still_has_the_commit|Audit_log:organization_events_for_180_days title=Described_from_the_documentation,_not_from_a_run at_2=52 at_3=0 at_4=50 at_5=78

**[ANIMATION]** step: 2

The Activity view of a repository: pushes, force pushes, merges, branch creations and deletions, with the user and a comparison. A force push is a push that removes commits from a branch on the server. "Restore branch" on a closed pull request: it recreates the deleted head branch, only for branches that had a pull request.

**[ANIMATION]** step: 5

The Events API: `PushEvent` records whose `before` and `head` fields are the IDs on both sides of a push. The section gives its limits as the last 300 events and 30 days, with a delivery lag of 30 seconds to 6 hours. The Git references API: it creates a ref at a commit ID you supply, and works only while GitHub still has the commit. And the audit log: organization events for 180 days, while Git events such as `git.push` are in the enterprise log only, for seven days.

**[ANIMATION]** end

The recipe these pieces suggest is to read the ID from before the force push and create a branch at it:

```bash
gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=<commit ID from before the force push>
```

**[ON SCREEN]** "Unverified." Say it as the textbook does. GitHub documents each instrument, not this combined procedure, and it publishes no retention period for commits that no ref reaches. One group of researchers observed that such commits appear to be kept indefinitely; that is their observation, not a statement by GitHub.

That recipe is unverified. GitHub documents each instrument, not this combined procedure, and it publishes no retention period for commits that no ref reaches. One group of researchers observed that such commits appear to be kept indefinitely. That is their observation, not a statement by GitHub.

GitHub's own advice for a deleted or force-pushed branch is the plain Git route: ask a collaborator who still has the commit to push it to a new branch. The same persistence means that a force push doesn't remove a leaked secret from GitHub. Rotation is the remedy. Prevention on this layer is a ruleset, a named list of rules on GitHub, that blocks force pushes and deletions on shared branches.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Running the destructive pair as "clean-up".** Root cause: step one removes every reflog entry and step two deletes every object that nothing names; together they are the documented way to remove the safety net.
2. **Relying on `ORIG_HEAD` to keep a commit alive.** Root cause: it is one file with one ID and is not a starting point for garbage collection.
3. **Running `git gc --prune=now` while another Git process is working.** Root cause: an object that a running command has written and not yet attached to a ref looks unreachable, and the manual warns of corruption.
4. **Treating a bundle as a full copy of the repository.** Root cause: a bundle holds what its refs reach; it has no reflogs, index, hooks, configuration or untracked files.
5. **Assuming a force push removed a commit from GitHub.** Root cause: the server's retention of unreferenced commits is not published; a leaked secret is handled by rotation, not by rewriting.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML team is about to rewrite the history of a model repository to remove a large checkpoint that was committed by mistake. Experiment logs and model cards refer to commit IDs of the old history.

Before the rewrite, the lead does two things from section 13.14. She creates a backup ref at the old tip. And she stores a bundle of the old state, verified, with the incident record: it preserves every old commit ID that the logs and cards refer to. Only after the rewrite is pushed and verified does the team run the destructive pair in each clone. Deliberately, with no other Git process running, because here shrinking the repository is the goal.

The team's rule for everyday work is shorter: experiment branches that live for months are pushed, not left to the reflog of one laptop.

## PRACTICE EXERCISE

Your turn. Do Lab 12.12, "Prove the point of no return", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

At each rung, before you run the command that takes the commit one step down, predict the output of `git reflog`, of `git fsck`, and of `git cat-file -t` for the lost commit. At the bottom, list every tool of this module and predict what each will say, then try them all.

The challenge is Exercise 12.11, Level 5, "Deleted, then cleaned up", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q197: "Describe precisely what `git reflog expire --expire=now --all` followed by `git gc --prune=now` does, when it is appropriate, and what can still bring a commit back afterwards."

Answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** replay: lost

A strong answer takes the two commands separately and says for each what is removed and what is left untouched, including refs, the working tree and the newest stash entry. It places the result on the four layers. It gives a legitimate use and the precondition the manual attaches to the second command. For "what can still bring it back" it lists sources outside the repository, and is careful about the hosting side: what is documented and what is only observed. It also knows which previews exist for each step.

## RECAP

Let's land this. You should now be able to say:

- A commit becomes unrecoverable when its last reflog entry is removed and then a collection deletes the object; two commands force both steps.
- Between the steps the object still exists and `git fsck` finds it.
- A backup ref before a risky operation makes the operation reversible with one command and no deadline.
- A bundle is refs and objects in one file; I verify it, and I know it holds no reflogs.
- GitHub has its own instruments for the server side; none of them is a reflog, and their combined use for recovery is not a documented procedure.

## HOMEWORK

Read sections 13.13 to 13.18 of [Chapter 13](../../textbook/ch13-recovery.md) and do the Practice section, 13.20. Read [`playbooks/disaster-recovery-playbook.md`](../../playbooks/disaster-recovery-playbook.md) and [`cheatsheets/emergency-recovery-one-page.md`](../../cheatsheets/emergency-recovery-one-page.md).

That's the recovery module. You can walk a commit down the ladder, and you know how to keep one from getting there. Make a backup branch before your next rebase. Next time: tags, three kinds, two mechanisms, and how tags travel. Until then, look at the state first and type second. See you in the next one.

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

These two commands appear in blog posts under headings like "clean up your repository" and "make Git smaller". They are also the documented way to destroy the safety net that the last six videos relied on. After them, `git reflog` prints nothing, `git fsck --lost-found` prints nothing, and a commit that was recoverable a minute ago does not exist.

There is a situation in which you want exactly that. A secret was committed and never pushed, and it must not survive in that clone. And there is every other situation, in which someone runs the pair during an incident and turns a five-minute recovery into a permanent loss.

A senior engineer has to know both: how to reach the point of no return on purpose, and how to make sure nobody reaches it by accident.

## INTRODUCTION

This is the last content video of the recovery module. You have recovered commits from reflogs, from `git fsck`, from other clones. Today you walk the ladder in the other direction, from "a reflog names it" down to "the object is deleted", one command per step, so that you can show each state.

Then prevention, which is cheaper than any recovery: a backup ref before a risky operation, and a bundle as an offline backup. And last, the server side: what GitHub adds, described from its documentation and not from a run.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- describe the sequence that destroys the safety net, and when it is appropriate;
- show each step from "reflog protects it" to "pruned";
- protect work before a risky operation with a backup ref;
- create, verify and use a bundle as an offline backup;
- say which evidence GitHub keeps on the server side, as the cited section states it.

## CONCEPT

In one sentence: a lost commit becomes unrecoverable in two steps, first when the last reflog entry that names it is removed and then when a collection deletes the object, and two commands can force both steps at once.

Precisely. The destructive pair is the documented procedure for shrinking a repository after a history rewrite. The manual of `git filter-branch` lists it in a checklist and calls it "a very destructive approach". For the same reason it is the documented way to destroy the safety net.

Inside `.git`: step one truncates files under `logs/`. Step two rewrites `objects/pack/` and removes loose object files. The working tree, the index, HEAD and the current branch are unchanged by both.

**[ON SCREEN]** The table of 🔴 commands from section 13.13. These are the five answers for each.

`git reflog expire --expire=now --all`. What it changes: it empties every reflog, the stash list included. What it can destroy: every layer-two protection, and the list of all stash entries except the newest. Preview: `git reflog expire --dry-run --verbose`. Recovery: the objects still exist, so `git fsck`, until a prune. Appropriate when: a secret must be purged after a history rewrite.

`git gc --prune=now`. What it changes: it repacks and deletes all unreachable objects. What it can destroy: everything on layer three. Preview: `git prune -n`, and `git fsck --unreachable`. Recovery: none in this repository; only layer four. Appropriate when: the same purge, with no other process using the repository. The manual attaches a second warning: `--prune=now` "increases the risk of corruption if another process is writing to the repository concurrently". An object that a running command has written and not yet attached to a ref looks unreachable.

`git prune`: deletes unreachable loose objects with no grace period unless `--expire` is given. The manual says to run `git gc` instead.

And for contrast, plain `git gc` is 🟡 CAUTION: it repacks, expires reflogs by the configured periods, and deletes unreachable objects older than two weeks. Routine housekeeping.

**Automatic maintenance.** You rarely run `git gc` yourself. Some commands start maintenance when they finish. Since Git 2.54 that automatic run uses the geometric strategy and not the `gc` task. It expires data in the reflog and puts unreachable objects into a cruft pack, a pack for unreachable objects with a file that records each object's age. Cruft packs are the default from Git 2.41. The retention periods you learned hold under either strategy. The manual of `git gc` still describes the older trigger, so read "automatic gc" in older texts as "automatic maintenance".

**Prevention, part one: a backup ref.** A branch costs one small file. Created before a rebase, a history filter, a large merge or a reset, it turns recovery into one command that needs no reflog, no search and no deadline. You compare against a name, not against a reflog position that moves.

**Prevention, part two: a bundle.** In one sentence: `git bundle` writes refs and the objects they reach into one file that Git can clone and fetch from. Precisely, a bundle is a pack file with a header that lists refs. 🟢 SAFE: `git bundle create <file> --all` includes every ref and writes one file outside `.git`.

What a bundle does not hold: reflogs, the index, hooks, the configuration, untracked files, and of the stash at most the newest entry. For stashes, Git 2.51 added `git stash export` and `git stash import`. A copy of the whole directory, made while no Git command runs, holds everything, and verifies nothing. For a repository you cannot afford to lose, use both kinds, and run `git fsck` on the copy.

## MENTAL MODEL

Return to the vault one last time, and picture a ladder with three rungs.

On the top rung, the ledger mentions the box. You recover it by name. On the middle rung, the ledger line has been erased; the box is on the shelf, unmentioned. You recover it by search. On the bottom rung, the clear-out has emptied the box. There is nothing in this vault to find.

Normally time and maintenance take a box down the ladder slowly: 30 or 90 days for the first step, two weeks of object age and a collection for the second. The destructive pair kicks it down both steps immediately.

A backup ref is an index card you write before the risky operation, so the box never leaves the front desk. A bundle is a sealed copy of the boxes and cards, stored in another building. The analogy breaks at one point: the sealed copy contains no ledger. A bundle has no reflogs.

## DIAGRAM

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

Predict how many objects an immediate prune would delete for one lost commit.

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

Three: the commit, its tree, and the one blob that no other commit shares. `git fsck` now reports the commit as dangling. Middle rung: it is still fully readable.

A collection that respects a grace period does not delete such objects. The transcript uses `--prune=never` so that it does not depend on a clock; a plain `git gc` behaves the same way for objects younger than two weeks.

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

Twelve objects in two packs. One of the packs has a file with the extension `mtimes`: that is the cruft pack. The commit is still there.

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

Nine objects in one pack. "Not a valid object name". And `git fsck` reports nothing: the repository is healthy, and the commit does not exist. Bottom rung.

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

`833b96f` went from a reflog entry, to a dangling commit, to nothing. Now the proof. Predict what each of these says.

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

The reflog is empty. `git fsck` finds nothing. `ORIG_HEAD` still holds the ID of the deleted commit and resolves to nothing: it is a file, not a starting point for reachability. And you cannot create a branch at an object that does not exist.

What can still bring the commit back? Only layer four. The lab kept a bundle from before.

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

The empty `git diff --stat` proves that the squashed branch has the same content as the original. `git range-diff` shows how the commits map. Had the result been wrong, one reset to the backup name would undo it, with no reflog involved; the script runs it to show that. Delete the backup when the result is pushed and verified.

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

Git gives a server no reflog by default, and you cannot run `git reflog` or `git fsck` on GitHub's copy of your repository. The section lists GitHub's own instruments. Open your own practice repository and find each one as I name it.

The Activity view of a repository: pushes, force pushes, merges, branch creations and deletions, with the user and a comparison. "Restore branch" on a closed pull request: it recreates the deleted head branch, only for branches that had a pull request. The Events API: `PushEvent` records whose `before` and `head` fields are the IDs on both sides of a push; the section gives its limits as the last 300 events and 30 days, with a delivery lag of 30 seconds to 6 hours. The Git references API: it creates a ref at a commit ID you supply, and works only while GitHub still has the commit. And the audit log: organization events for 180 days, while Git events such as `git.push` are in the enterprise log only, for seven days.

The recipe these pieces suggest is to read the ID from before the force push and create a branch at it:

```bash
gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=<commit ID from before the force push>
```

**[ON SCREEN]** "Unverified." Say it as the textbook does. GitHub documents each instrument, not this combined procedure, and it publishes no retention period for commits that no ref reaches. One group of researchers observed that such commits appear to be kept indefinitely; that is their observation, not a statement by GitHub.

GitHub's own advice for a deleted or force-pushed branch is the plain Git route: ask a collaborator who still has the commit to push it to a new branch. The same persistence means that a force push does not remove a leaked secret from GitHub; rotation is the remedy. Prevention on this layer is a ruleset that blocks force pushes and deletions on shared branches.

## COMMON MISTAKES

1. **Running the destructive pair as "clean-up".** Root cause: step one removes every reflog entry and step two deletes every object that nothing names; together they are the documented way to remove the safety net.
2. **Relying on `ORIG_HEAD` to keep a commit alive.** Root cause: it is one file with one ID and is not a starting point for garbage collection.
3. **Running `git gc --prune=now` while another Git process is working.** Root cause: an object that a running command has written and not yet attached to a ref looks unreachable, and the manual warns of corruption.
4. **Treating a bundle as a full copy of the repository.** Root cause: a bundle holds what its refs reach; it has no reflogs, index, hooks, configuration or untracked files.
5. **Assuming a force push removed a commit from GitHub.** Root cause: the server's retention of unreferenced commits is not published; a leaked secret is handled by rotation, not by rewriting.

## PRODUCTION EXAMPLE

An ML team is about to rewrite the history of a model repository to remove a large checkpoint that was committed by mistake. Experiment logs and model cards refer to commit IDs of the old history.

Before the rewrite, the lead does two things from section 13.14. She creates a backup ref at the old tip. And she stores a bundle of the old state, verified, with the incident record: it preserves every old commit ID that the logs and cards refer to. Only after the rewrite is pushed and verified does the team run the destructive pair in each clone, deliberately, with no other Git process running, because here shrinking the repository is the goal.

The team's rule for everyday work is shorter: experiment branches that live for months are pushed, not left to the reflog of one laptop.

## PRACTICE EXERCISE

Do Lab 12.12, "Prove the point of no return", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

At each rung, before you run the command that takes the commit one step down, predict the output of `git reflog`, of `git fsck`, and of `git cat-file -t` for the lost commit. At the bottom, list every tool of this module and predict what each will say, then try them all.

The challenge is Exercise 12.11, Level 5, "Deleted, then cleaned up", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q197: "Describe precisely what `git reflog expire --expire=now --all` followed by `git gc --prune=now` does, when it is appropriate, and what can still bring a commit back afterwards."

Pause and answer aloud.

A strong answer takes the two commands separately and says for each what is removed and what is left untouched, including refs, the working tree and the newest stash entry. It places the result on the four layers. It gives a legitimate use and the precondition the manual attaches to the second command. For "what can still bring it back" it lists sources outside the repository, and is careful about the hosting side: what is documented and what is only observed. It also knows which previews exist for each step.

## RECAP

You should now be able to say:

- A commit becomes unrecoverable when its last reflog entry is removed and then a collection deletes the object; two commands force both steps.
- Between the steps the object still exists and `git fsck` finds it.
- A backup ref before a risky operation makes the operation reversible with one command and no deadline.
- A bundle is refs and objects in one file; I verify it, and I know it holds no reflogs.
- GitHub has its own instruments for the server side; none of them is a reflog, and their combined use for recovery is not a documented procedure.

## HOMEWORK

Read sections 13.13 to 13.18 of [Chapter 13](../../textbook/ch13-recovery.md) and do the Practice section, 13.20. Read [`playbooks/disaster-recovery-playbook.md`](../../playbooks/disaster-recovery-playbook.md) and [`cheatsheets/emergency-recovery-one-page.md`](../../cheatsheets/emergency-recovery-one-page.md).

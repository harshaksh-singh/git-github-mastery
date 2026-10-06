# V092: Submodules in motion: the detached HEAD, moving the pointer, the stale submodule and the silent rollback

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS
- **Planned minutes.** 24
- **Prerequisites.** V024, V091
- **Textbook sections.** [Chapter 23](../../textbook/ch23-submodules.md), sections 23.5 to 23.7
- **Demo scripts.** `labs/ch23/submodule-detached.sh`, `labs/ch23/submodule-update.sh`, `labs/ch23/submodule-recurse.sh`, and the snippet `04-detached` of `labs/ch23/submodule-clone.sh`

## HOOK

**[ON SCREEN]** "I pulled, changed one line in `ingest.py`, committed, and the reviewer says my commit downgrades the library."

Ravi did exactly what he says. He pulled. He edited one file. He ran `git commit -a` with a message about chunk sizes. And his commit contains two changes: his one line, and a second line that moves the shared library back to last month's version.

He never touched the library. He never ran a submodule command. The downgrade was sitting in his working tree from the moment the pull finished, shown by `git status` as "modified", and `git commit -a` stages everything that's modified.

After a push, that becomes the fourth report on the list: the service silently runs the old library again, and CI on `main` goes red over a directory nobody touched. So how did it get there? Today you watch it happen, one command at a time.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you saw a submodule at rest: another repository checked out inside yours, with a gitlink that records one commit ID, a URL, and a repository under `.git/modules`. You learned to compare three values: the commit the superproject records, the commit checked out in the submodule, and the commits that exist in the shared repository.

Today those values move, and they move separately. First inside the submodule, where HEAD is detached. Then in the superproject, when someone moves the pointer on purpose. Then on a teammate's machine, where a pull moves one value and not the other.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- explain why HEAD is detached in a submodule after `update`, and why that is correct;
- commit inside a submodule without losing the commit;
- move the recorded pointer and read the change in `git status` and `git diff --submodule`;
- explain how a teammate's stale submodule leads to a commit that rolls the pointer back;
- configure a clone so that pulls keep submodules in step.

## CONCEPT

**[ANIMATION]** graph: id=inside e216665 main origin/main; HEAD=e216665 => e216665-679aa20; e216665 main origin/main; HEAD=679aa20 => e216665-679aa20 HEAD@{1}; e216665-b3c86ce origin/main v0.2.0; e216665 main; HEAD=b3c86ce; reflog:679aa20 => e216665-679aa20 line-splitter; e216665-b3c86ce origin/main v0.2.0; e216665 main; HEAD=b3c86ce title=Inside_the_submodule

**[ANIMATION]** step: inside.state-1

**The detached HEAD.** The superproject asked for a commit. It didn't ask for a branch, and it can't: the gitlink has no room for one. So `git submodule update` does what `git switch --detach <commit>` does: HEAD points straight at a commit, not at a branch. A local `main` exists in the submodule because the clone created it. HEAD isn't on it. This is the correct state for a dependency you only consume.

**[ANIMATION]** step: inside.state-2

It becomes a trap the moment you edit the library in place. A commit made there's on no branch.

**[ANIMATION]** step: inside.state-3

The next `git submodule update` checks out the commit the superproject records, and says nothing about the commit it left behind.

**[ANIMATION]** step: inside.state-4

The commit isn't lost: the submodule is a repository with its own reflog, its local journal of where HEAD has been. A branch can anchor the commit again. The prevention is a habit: before you change anything inside a submodule, get on a branch there.

**[ANIMATION]** end

For people who develop the library inside the superproject, `git submodule update --merge` or `--rebase` integrates the recorded commit into the submodule's branch and leaves HEAD attached. For consumers, the default checkout is right.

**Moving the pointer.** Nothing changes in the superproject until someone moves the gitlink. 🟡 CAUTION: `git submodule update --remote` fetches in the submodule and checks out the tip of its remote-tracking branch instead of the recorded commit. Which branch? By default the one the remote's HEAD points at. `git submodule set-branch` records another in `.gitmodules`. That setting is read by `update --remote` and by nothing else. It doesn't make the submodule "follow" a branch, and the gitlink is still a commit ID.

Recording the new pointer is an ordinary add and commit in the superproject. Treat it like any dependency bump: one purpose, its own pull request, CI on the result.

**[ANIMATION]** submodule: id=drift [Ravi's doc-qa] 907dbd3 main origin/main; HEAD=main; sub:907dbd3:records_e216665 || [vendor/textsplit] e216665 main origin/main; HEAD=e216665 => [Ravi's doc-qa] 907dbd3-0d51dbc main origin/main; HEAD=main; sub:907dbd3:records_e216665; sub:0d51dbc:records_b3c86ce; name:pull; cmd:git_pull; say:Recorded:_b3c86ce._Checked_out:_still_e216665. || [vendor/textsplit] e216665-b3c86ce origin/main v0.2.0; e216665 main; HEAD=e216665 => [Ravi's doc-qa] 907dbd3-0d51dbc-b98f829 main; 0d51dbc origin/main; HEAD=main; sub:907dbd3:records_e216665; sub:0d51dbc:records_b3c86ce; sub:b98f829:records_e216665; name:rollback; cmd:git_commit_-a; say:b98f829_records_the_old_commit_again || => [Ravi's doc-qa] 907dbd3-0d51dbc-2b86667 main; 0d51dbc origin/main; 0d51dbc-b98f829; reflog:b98f829; HEAD=main; sub:907dbd3:records_e216665; sub:0d51dbc:records_b3c86ce; sub:b98f829:records_e216665; sub:2b86667:records_b3c86ce; name:repair; cmd:git_commit_--amend; say:2b86667_records_b3c86ce,_and_the_submodule_is_on_it || [vendor/textsplit] e216665-b3c86ce origin/main v0.2.0; e216665 main; HEAD=b3c86ce dx=230

**[ANIMATION]** step: drift.pull

**The stale submodule.** `git pull` is fetch plus merge. The fetch notices that the new commits change a gitlink and fetches inside the submodule as well. That on-demand fetch is the default of `fetch.recurseSubmodules`. The merge updates the gitlink in the superproject's index. It doesn't check out the new commit in the submodule. Checking out a superproject commit doesn't move the HEAD of a submodule unless recursion is on.

Why does Git behave this way? The submodule may hold work in progress, and Git won't move it without being asked.

**[ANIMATION]** end

**The cure.** `git config set submodule.recurse true`. With it, `checkout`, `fetch`, `grep`, `pull`, `push`, `read-tree`, `reset`, `restore` and `switch` behave as if `--recurse-submodules` were given. `git clone` is the exception: it needs its own `--recurse-submodules`, and so does `git ls-files`. The manual's workflow section recommends the setting for repositories that are split into submodules. It's local or global configuration, so it can't be shipped with the repository: every clone, and every CI job, has to set it or pass the option.

## MENTAL MODEL

Return to the recipe that cites page 212 of the other book. Three values, written side by side:

What your book cites. What page the reader's copy of the other book is open at. What the bookshop's edition contains.

**[ANIMATION]** walk: id=cmds columns=command,recorded,checked_out rows=git_submodule_update:-:goes_to_the_recorded_commit|update_--remote:-:goes_to_the_newest_on_the_remote|git_add_vendor/textsplit:becomes_the_checked-out_commit:-|git_pull:new:stays_where_it_was|git_commit_-a:becomes_the_checked-out_commit:- marks=4.3:bad,5.2:bad title=Each_command_changes_one_value

**[ANIMATION]** step: cmds.4

Every command today changes one of the three. `git submodule update` opens the reader's copy at the page your book cites. `update --remote` opens it at the newest page in the shop. `git add` on the submodule path rewrites the citation in your book to wherever the copy is open. And `git pull` brings a new edition of your book with a new citation, and leaves the reader's copy open where it was.

**[ANIMATION]** step: cmds.5

The dangerous step follows from that. A reader who then runs "write down where my copy is open", which is what `git commit -a` does, puts the old page back into the book. Where the analogy breaks: nobody decided to do that. It was the default staging of a modified path.

**[ANIMATION]** end

Try it now, on paper, thirty seconds. Two columns: recorded in the superproject, and checked out in the submodule. For Ravi's clone right after his `git pull`, write new or old in each. That's your prediction.

**[PAUSE]**

## DIAGRAM

**[ANIMATION]** walk: id=rows columns=after_this_command_(in_Ravi's_clone),recorded_in_the_index,checked_out,prefix rows=clone,_init,_update:e216665:e216665:space|git_pull_(you_moved_the_pointer):b3c86ce:e216665_STALE:+|git_commit_-a_(one_line_in_ingest.py):e216665_ROLLBACK:e216665:space|repair_(checkout,_git_add,_amend):b3c86ce:b3c86ce:space marks=2.3:bad,3.2:bad,4.2:ok,4.3:ok title=Three_values_after_each_command

**[DIAGRAM]** Three values in a row, compared after each command of the demonstration. Use the abbreviated IDs of the transcript: `e216665` is the old library commit, `b3c86ce` is release 0.2.0.

```text
                                            recorded in the       checked out in        status
  after this command (in Ravi's clone)      superproject's index  the submodule         prefix
  ----------------------------------------  --------------------  --------------------  ------
  clone, init, update                       e216665               e216665               space
  git pull  (you moved the pointer)         b3c86ce               e216665   STALE       +
  git commit -a  (one line in ingest.py)    e216665   ROLLBACK    e216665               space
  repair: checkout b3c86ce in submodule,
          git add, git commit --amend       b3c86ce               b3c86ce               space
```

**[ANIMATION]** step: rows.2

Check your paper against row two: recorded is new, checked out is old.

**[ANIMATION]** step: rows.4

Now read row three slowly. After the bad commit the two values agree again, and the status prefix is a space. The repository looks healthy. The damage is in the history: the recorded value went backwards.

**[ON SCREEN]** The root-cause box of section 23.7, shown at row two.

```text
Observed behavior : After a pull that changed nothing of his own, git status shows
                    "modified: vendor/textsplit (new commits)".
Git state         : HEAD and index of the superproject record gitlink b3c86ce. The submodule's HEAD is
                    still e216665. The library commit b3c86ce has been fetched into .git/modules/.
Mechanism         : pull = fetch + merge. The merge updates the gitlink in the index. Checking out a
                    superproject commit does not move the HEAD of a submodule unless recursion is on.
Root cause        : Two repositories, two HEADs, and no default that ties the second to the first.
Why Git does this : The submodule may hold work in progress; Git will not move it without being asked.
Correct fix       : git submodule update      (then git status is clean)
Prevention        : git config set submodule.recurse true, or git pull --recurse-submodules.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** From `labs/run ch23/submodule-clone`, the snippet you skipped last time. Ravi's submodule, right after `update`.

```bash
git -C vendor/textsplit status
git -C vendor/textsplit branch --all
```

<!-- snippet: ch23/submodule-clone/04-detached -->
```text
$ git -C vendor/textsplit status
HEAD detached at e216665
nothing to commit, working tree clean
$ git -C vendor/textsplit branch --all
* (HEAD detached at e216665)
  main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```
<!-- /snippet -->

"HEAD detached at e216665". A local `main` exists, and HEAD isn't on it.

**[TERMINAL]** Replay `labs/run ch23/submodule-detached`. Ravi fixes something inside `vendor/textsplit` and commits.

```bash
cd vendor/textsplit
git status --short --branch
git commit -am "Add line splitter"
git log --oneline --decorate -2
```

<!-- snippet: ch23/submodule-detached/01-commit-on-detached -->
```text
$ cd vendor/textsplit
$ git status --short --branch
## HEAD (no branch)
$ git commit -am "Add line splitter"
[detached HEAD 679aa20] Add line splitter
 1 file changed, 5 insertions(+)
$ git log --oneline --decorate -2
679aa20 (HEAD) Add line splitter
e216665 (origin/main, origin/HEAD, main) Add overlap between neighbouring chunks
$ cd ../..
```
<!-- /snippet -->

The commit `679aa20` is decorated with HEAD only. No branch. Meanwhile you have moved the pointer to the library's 0.2.0 release and pushed. Ravi pulls and updates. Predict what Git says about `679aa20`. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch23/submodule-detached/02-update-moves-head -->
```text
$ git pull
From $LAB/ch23/submodule-detached/remotes/doc-qa
   907dbd3..3719d28  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/submodule-detached/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Updating 907dbd3..3719d28
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule update
Submodule path 'vendor/textsplit': checked out 'b3c86ceee1901d9cfff1a21920bd863a64ffb738'
$ git -C vendor/textsplit log --oneline --decorate -2
b3c86ce (HEAD, tag: v0.2.0, origin/main, origin/HEAD) Reject an overlap that is not smaller than the chunk size
e216665 (main) Add overlap between neighbouring chunks
# Which branch, local or remote-tracking, contains the commit Ravi made? None:
$ git -C vendor/textsplit branch --all --contains 679aa20
```
<!-- /snippet -->

Nothing. `git submodule update` checked out the commit that the superproject now records. The rescue is the one from the recovery module, run inside the submodule.

```bash
git -C vendor/textsplit reflog -3
git -C vendor/textsplit branch line-splitter 'HEAD@{1}'
git -C vendor/textsplit log --oneline --decorate -1 line-splitter
```

<!-- snippet: ch23/submodule-detached/03-rescue -->
```text
# No branch ever pointed at the commit. The submodule has a reflog of its own:
$ git -C vendor/textsplit reflog -3
b3c86ce HEAD@{0}: checkout: moving from 679aa200d3e14163fc2fc5764cdd69de4c189dbd to b3c86ceee1901d9cfff1a21920bd863a64ffb738
679aa20 HEAD@{1}: commit: Add line splitter
e216665 HEAD@{2}: checkout: moving from main to e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
$ git -C vendor/textsplit branch line-splitter 'HEAD@{1}'
$ git -C vendor/textsplit log --oneline --decorate -1 line-splitter
679aa20 (line-splitter) Add line splitter
```
<!-- /snippet -->

The submodule's own HEAD reflog has the commit at `HEAD@{1}`. A branch anchors it. And the habit that prevents it:

```bash
git -C vendor/textsplit switch line-splitter
git -C vendor/textsplit status --short --branch
git status --short
git submodule status
```

<!-- snippet: ch23/submodule-detached/04-work-on-a-branch -->
```text
# The way to work in a submodule: get on a branch first.
$ git -C vendor/textsplit switch line-splitter
Previous HEAD position was b3c86ce Reject an overlap that is not smaller than the chunk size
Switched to branch 'line-splitter'
$ git -C vendor/textsplit status --short --branch
## line-splitter
$ git status --short
 M vendor/textsplit
$ git submodule status
+679aa200d3e14163fc2fc5764cdd69de4c189dbd vendor/textsplit (v0.1.0-2-g679aa20)
```
<!-- /snippet -->

On a branch inside the submodule. The superproject shows the path as modified, and the status prefix is a plus sign: the checked-out commit differs from the recorded one.

**[TERMINAL]** Replay `labs/run ch23/submodule-update`. You are the one who moves the pointer. Asha has released textsplit 0.2.0.

**[ON SCREEN]** 🟡 CAUTION: `git submodule update --remote`. Files inside the submodule path change; the superproject's index, HEAD and branch are unchanged; the submodule's HEAD is detached at the target commit.

```bash
git submodule status
git -c protocol.file.allow=always submodule update --remote
git submodule status
```

<!-- snippet: ch23/submodule-update/01-remote -->
```text
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git -c protocol.file.allow=always submodule update --remote
From $LAB/ch23/submodule-update/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Submodule path 'vendor/textsplit': checked out 'b3c86ceee1901d9cfff1a21920bd863a64ffb738'
$ git submodule status
+b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
```
<!-- /snippet -->

The prefix went from a space to a plus.

**[ANIMATION]** submodule: id=bump [your doc-qa] 907dbd3 main origin/main; HEAD=main; sub:907dbd3:records_e216665 || [vendor/textsplit] e216665 main origin/main; HEAD=main => || [vendor/textsplit] e216665-b3c86ce origin/main v0.2.0; e216665 main; HEAD=b3c86ce; name:remote; cmd:git_submodule_update_--remote; say:Checked_out:_b3c86ce._Recorded:_still_e216665.

The submodule is at `b3c86ce`, tagged `v0.2.0`. The superproject still records `e216665`.

```bash
git status
git diff --submodule=log
```

<!-- snippet: ch23/submodule-update/02-status-diff -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   vendor/textsplit (new commits)

no changes added to commit (use "git add" and/or "git commit -a")
$ git diff
diff --git a/vendor/textsplit b/vendor/textsplit
index e216665..b3c86ce 160000
--- a/vendor/textsplit
+++ b/vendor/textsplit
@@ -1 +1 @@
-Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
+Subproject commit b3c86ceee1901d9cfff1a21920bd863a64ffb738
$ git diff --submodule=log
Submodule vendor/textsplit e216665..b3c86ce:
  > Reject an overlap that is not smaller than the chunk size
```
<!-- /snippet -->

The words "new commits" in `git status` mean: the submodule's HEAD differs from the gitlink in the index. `git diff --submodule=log` replaces the two IDs by the list of commits between them, which is what a reviewer wants to read. `git config set diff.submodule log` makes it the default.

```bash
git add vendor/textsplit
git commit -m "Update textsplit to 0.2.0"
git push origin main
```

<!-- snippet: ch23/submodule-update/03-commit-pointer -->
```text
$ git add vendor/textsplit
$ git commit -m "Update textsplit to 0.2.0"
[main 0d51dbc] Update textsplit to 0.2.0
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push origin main
To $LAB/ch23/submodule-update/remotes/doc-qa.git
   907dbd3..0d51dbc  main -> main
```
<!-- /snippet -->

One file changed, one insertion, one deletion: the one-line "Subproject commit" file. Now Ravi's clone.

Ravi runs `git pull`. He has made no change of his own. Predict the first character of `git submodule status` afterwards. I'll wait.

**[PAUSE]**

```bash
git pull
```

<!-- snippet: ch23/submodule-update/04-teammate-pull -->
```text
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/submodule-update/remotes/doc-qa
   907dbd3..0d51dbc  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/submodule-update/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Updating 907dbd3..0d51dbc
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   vendor/textsplit (new commits)

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

Read the output in order. The superproject was fetched. "Fetching submodule vendor/textsplit": the new library commit was downloaded. Then the superproject was fast-forwarded. No line says the submodule was checked out, because it wasn't.

```bash
git submodule status
git diff --submodule=log
```

<!-- snippet: ch23/submodule-update/05-teammate-stale -->
```text
$ git submodule status
+e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git diff --submodule=log
Submodule vendor/textsplit b3c86ce..e216665 (rewind):
  < Reject an overlap that is not smaller than the chunk size
```
<!-- /snippet -->

A plus, and the word "rewind".

**[ANIMATION]** step: drift.pull

The superproject now records `b3c86ce`. The submodule's working tree is still at `e216665`. Seen from the superproject, the working tree differs from the index by going one library commit backwards. This is row two of the diagram, and the root-cause box.

**[ANIMATION]** end

The correct next command is `git submodule update`. Ravi doesn't look closely. Quick quiz: he edits `ingest.py` and runs `git commit -a`. Will his commit change one file, or two? Say it out loud.

**[PAUSE]**

```bash
git commit -am "Use larger chunks"
git show --stat --format="%h %an: %s"
```

<!-- snippet: ch23/submodule-update/06-accidental-rollback -->
```text
# Ravi does not look closely. He edits a file and commits everything that is modified:
$ git commit -am "Use larger chunks"
[main b98f829] Use larger chunks
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git show --stat --format="%h %an: %s"
b98f829 Ravi Menon: Use larger chunks

 ingest.py        | 2 +-
 vendor/textsplit | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git ls-tree HEAD vendor/
160000 commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	vendor/textsplit
```
<!-- /snippet -->

Two files changed: `ingest.py`, and `vendor/textsplit`.

**[ANIMATION]** step: drift.rollback

His commit `b98f829` moved the gitlink back. That's the downgrade from the opening. A reviewer sees it only as one changed line in a commit that claims to be about chunk sizes.

**[ANIMATION]** end

The commit hasn't been pushed, so it can be repaired in place. 🟡 CAUTION: `git commit --amend` replaces the tip commit. The old one stays in the reflog.

```bash
git -C vendor/textsplit checkout --quiet $(git rev-parse origin/main:vendor/textsplit)
git add vendor/textsplit
git commit --amend --no-edit
git show --stat --format="%h %an: %s"
```

<!-- snippet: ch23/submodule-update/07-repair -->
```text
# Not pushed yet, so repair the commit: put the submodule on the commit that main records
# upstream, stage it, amend.
$ git -C vendor/textsplit checkout --quiet $(git rev-parse origin/main:vendor/textsplit)
$ git add vendor/textsplit
$ git commit --amend --no-edit
[main 2b86667] Use larger chunks
 Date: Mon Sep 7 10:35:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format="%h %an: %s"
2b86667 Ravi Menon: Use larger chunks

 ingest.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule status
 b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
```
<!-- /snippet -->

`origin/main:vendor/textsplit` is the gitlink as the remote-tracking branch records it. `git rev-parse` returns the ID even though the object isn't in the superproject.

**[ANIMATION]** step: drift.repair

After the amend, the commit changes one file, and `2b86667` has taken the place of `b98f829`. The script uses `git checkout` inside the submodule. `git switch --detach` with the same ID is the newer spelling. If the bad commit had already been pushed, the fix is a new commit that moves the pointer forward again.

**[TERMINAL]** Replay `labs/run ch23/submodule-recurse`. The cure is to make the second step automatic. Without it, the manual sequence after a pull is two commands.

<!-- snippet: ch23/submodule-recurse/01-two-steps -->
```text
$ git pull
From $LAB/ch23/submodule-recurse/remotes/doc-qa
   907dbd3..3719d28  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/submodule-recurse/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Updating 907dbd3..3719d28
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule status
+e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git submodule update
Submodule path 'vendor/textsplit': checked out 'b3c86ceee1901d9cfff1a21920bd863a64ffb738'
$ git submodule status
 b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

And the same staleness appears with every command that moves the superproject's HEAD.

```bash
git switch --detach HEAD~1
git submodule status
git switch -
```

<!-- snippet: ch23/submodule-recurse/02-switch-without -->
```text
# An older commit of doc-qa records the older library commit. Without recursion:
$ git switch --detach HEAD~1
HEAD is now at 907dbd3 Vendor textsplit as a submodule and chunk documents
M	vendor/textsplit
$ git submodule status
+b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
$ git switch -
Previous HEAD position was 907dbd3 Vendor textsplit as a submodule and chunk documents
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git status --short
```
<!-- /snippet -->

An older commit of `doc-qa` records the older library commit. Without recursion the submodule stays where it was, and the prefix is a plus.

```bash
git config set submodule.recurse true
git switch --detach HEAD~1
git submodule status
git switch -
git submodule status
```

<!-- snippet: ch23/submodule-recurse/03-recurse -->
```text
$ git config set submodule.recurse true
$ git switch --detach HEAD~1
HEAD is now at 907dbd3 Vendor textsplit as a submodule and chunk documents
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git switch -
Previous HEAD position was 907dbd3 Vendor textsplit as a submodule and chunk documents
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git submodule status
 b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
$ git config get submodule.recurse
true
```
<!-- /snippet -->

With `submodule.recurse` set, the submodule follows the superproject in both directions, and the prefix stays a space. 🟡 CAUTION: this is a configuration key, written with `git config set`, which needs Git 2.46 or later. It lives in this clone only.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Committing inside a submodule without a branch.** Root cause: `update` leaves HEAD detached at the recorded commit, so the new commit is on no branch and the next `update` moves away from it silently.
2. **Expecting `git pull` to update the submodule's files.** Root cause: pull fetches in the submodule and updates the gitlink in the index, and does not move the submodule's HEAD unless recursion is on.
3. **`git commit -a` with a stale submodule.** Root cause: the stale checkout shows as a modified path, and `-a` stages every modified path, which records the old commit ID again.
4. **Thinking `submodule.<name>.branch` makes the submodule follow a branch.** Root cause: the setting is read by `update --remote` and by nothing else; the gitlink is still a commit ID.
5. **Setting `submodule.recurse` once and assuming the team has it.** Root cause: it is local or global configuration and cannot be shipped with the repository; every clone and every CI job has to set it.

## PRODUCTION EXAMPLE

Now, out of the lab. A retrieval team vendors a chunking library as a submodule in three services. Twice in one month a feature pull request has contained an unexplained second changed line, `vendor/textsplit`, and once it was merged: the service ran the previous library version for two days.

**[ANIMATION]** cards: id=fix cards=The_setup_script:submodule.recurse_true,_diff.submodule_log|Pointer_changes:their_own_pull_request,_a_dependency_bump|Reviewers_look_for:a_"Subproject_commit"_line,_the_word_"rewind" numbered=on title=The_team_changes_three_things

The team changes three things. The setup script that every engineer and every CI job runs sets `submodule.recurse` to true and `diff.submodule` to log, so a pull keeps the submodule in step and a pointer change is readable in review. Pointer changes get their own pull request, titled as a dependency bump. And reviewers are told what to look for: a "Subproject commit" line in a pull request that isn't about the dependency, and the word "rewind" in the submodule diff.

## PRACTICE EXERCISE

Your turn. Do Lab 15.1, "A submodule that breaks for a teammate", in [`lab-manual/m15-submodules-subtrees-lfs.md`](../../lab-manual/m15-submodules-subtrees-lfs.md).

Keep a three-column table as you go: recorded, checked out, status prefix. Before every command, predict which of the three values it changes. Before the teammate's commit, predict how many files it will contain.

The challenge is Exercise 15.4, Level 2, command prediction, "The first character of `git submodule status`", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q428: "Why is HEAD detached in a submodule after `git submodule update`? When does that lose work, and how do you get it back?"

**[PAUSE]**

Answer out loud. A strong answer derives the detached HEAD from what the gitlink can and can't hold, and says why that state is the right one for a consumer. It then describes the exact sequence in which work appears to vanish, and is precise that the commit is unreachable from branches, not deleted. It names where the evidence is, which belongs to the submodule and not to the superproject, and gives the two-step rescue: find, then anchor. It ends with the habit that prevents it, and with the update modes for people who really develop the library in place.

## RECAP

**[ANIMATION]** step: inside.state-4

Let's land this. One last look inside the submodule: a commit left behind, and the branch that anchors it.

You should now be able to say:

- After `update`, a submodule's HEAD is detached because the superproject records a commit, not a branch.
- Before editing inside a submodule I switch to a branch there; a commit left behind is in the submodule's own reflog.
- Moving the pointer is `update --remote`, then `git add` and a commit in the superproject, reviewed as a dependency bump.
- A pull updates the recorded ID and leaves the submodule's checkout stale; `git commit -a` in that state rolls the pointer back.
- `submodule.recurse=true` keeps the checkout in step, and every clone and CI job has to set it.

## HOMEWORK

Read sections 23.5 to 23.7 of [Chapter 23](../../textbook/ch23-submodules.md).

Today you watched a silent rollback form, one value at a time, and you repaired it. Practise with the lab and your three-column table before you move on. Next time: submodule failures, from push order to CI. Until then, look at the state first and type second. See you in the next one.

# V077: Recovering uncommitted work, and recovering from the remote side

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 24
- **Prerequisites.** V042, V076
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), sections 13.9 and 13.10
- **Demo scripts.** `labs/ch13/lab-12-8-overwritten-changes.sh`, `labs/ch13/lab-12-10-remote-tracking.sh`, `labs/ch13/lab-12-11-force-push.sh`

## HOOK

**[ON SCREEN]** "A file was staged and then wiped by `git reset --hard`. Can we get it back?"

Most engineers answer no: a hard reset destroys uncommitted work. Two words first. Staged means recorded with `git add` for the next commit, the next saved snapshot. And a hard reset puts your files back to the last commit.

The exact answer has three parts. The version of the file that you staged: yes, it's an object in the repository right now, without a name. An earlier version that you staged before that: also yes. The line you typed after the last `git add`: no, and you can prove in two commands that no object holds it. Hold on to those two commands.

Then a second question from the same afternoon. A teammate forced a push over `main`, which replaces the server's branch instead of extending it, and two commits by two people are gone from the server. The server kept no record. Who did? You did, if you have fetched before and not thrown it away.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. So far in this module every recovery concerned commits, and every commit had a reflog entry somewhere, a line in Git's local log of where each name has pointed. Today you leave that comfort in two directions.

First, down to layer three: work that became an object and has no name at all. A staged blob, the stored content of one file. A stash entry, parked uncommitted work, that was cleared.

Second, sideways to layer four: the remote side. What your clone knows about the server, when that knowledge is wrong, and how your clone becomes the recovery tool after someone else's forced push.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- state which uncommitted work has an object and which has none;
- recover a staged file wiped by a hard reset from a dangling blob;
- recover a cleared stash entry;
- repair broken remote-tracking state;
- restore commits overwritten by someone's forced push from your own clone.

## CONCEPT

**[ANIMATION]** trees: file=train.yaml steps=setup,edit,add,reset history=off versions=epochs:_3,epochs:_5 title=What_git_add_writes say_setup=One_file_in_three_places._Right_now_they_agree say_add=git_add_writes_a_blob_now._The_index_entry_names_it say_reset=The_reset_removes_the_index_entry,_not_the_blob cmd_reset=git_reset_--hard id=staged

**[ANIMATION]** step: add

**Staged work.** On screen, `train.yaml` from today's demonstration: one edit, then `git add`. `git add` writes a blob at the moment you run it. The index is the list of what goes into your next commit.

**[ANIMATION]** step: reset

A hard reset removes the index entries, not the blobs. Nothing names them, so they are dangling, on layer three. A blob has no file name and no date: the name lived in the index entry that is gone. You identify blobs by content. And every `git add` is a checkpoint that outlives the index entry, so a file staged twice leaves two blobs.

**[ANIMATION]** end

Work typed after the last `git add` was never hashed. No object holds it. That's the boundary of Git's safety net.

**[ANIMATION]** graph: ...older-cf76919 main; cf76919-?index-0b0c40d special:refs/stash; cf76919-0b0c40d; ^cf76919-?index_2-a0cbbaf special:stash@{1}; cf76919-a0cbbaf; HEAD=main; title:Two_stash_entries => + drop:refs/stash,stash@{1}; ghost:0b0c40d,a0cbbaf,?index,?index_2; cmd:!git_stash_clear; say:The_reflog_lines_are_gone:_nothing_names_the_commits; name:cleared id=stash dx=280 dy=200 at_state_1=8 at_cleared=45

**A dropped or cleared stash.** A stash entry is a commit with two or three parents. Dropping it removes its reflog line, so the commit is unreachable. `git stash drop` prints the ID of what it dropped. `git stash clear` prints nothing. The stash manual gives a recipe that lists unreachable commits which look like stash entries. The deadline is the one of layer three, and it's shorter than for a rewritten commit: a dropped stash never has a reflog entry to fall back on.

**[ANIMATION]** remotes: [your clone] 1203ec5-6955492-2a2bf94-d8a3934 main origin/main; HEAD=main || [origin] 1203ec5-6955492-2a2bf94-d8a3934 main; HEAD=none; title:A_forced_push,_seen_from_your_clone => || [origin] ^6955492-882b940 main; 1203ec5-6955492-2a2bf94-d8a3934; ghost:2a2bf94,d8a3934; HEAD=none; cmd:!git_push_--force; say:A_teammate_forces_a_push:_the_server's_branch_is_replaced; name:forced => [your clone] 1203ec5-6955492-2a2bf94-d8a3934 main; ^6955492-882b940 origin/main; HEAD=main; cmd:git_fetch; say:forced_update:_origin/main_moves_to_a_commit_that_does_not_descend_from_the_old_one; name:fetch || => [your clone] + d8a3934 special:origin/main@{1}; cmd:git_reflog_show_origin/main; say:origin/main@{1}_is_the_server's_old_tip; name:witness || => [your clone] 1203ec5-6955492-2a2bf94-d8a3934-d967a92 main; 6955492-882b940 origin/main; 882b940-d967a92; HEAD=main; cmd:git_merge_origin/main; say:Keep_both:_a_merge_commit_joins_the_two_lines; name:merge || => [your clone] + d967a92 origin/main; cmd:git_push; say:The_push_is_a_fast-forward:_882b940..d967a92 || [origin] 1203ec5-6955492-2a2bf94-d8a3934-d967a92 main; 6955492-882b940-d967a92; HEAD=none; name:push id=force fly=off

**[ANIMATION]** step: fetch

**A force push seen from your clone.** On screen, your `main` and `origin/main` agree. Then you fetch after the forced push, and `origin/main` moves to a commit that doesn't descend from the old one.

**[ANIMATION]** step: witness

Your remote-tracking ref has a reflog, and it recorded the value the server had before. `origin/main@{1}` is the server's old tip. The server itself is a bare repository without reflogs by default, so it can't tell you. A teammate who hasn't fetched since is another witness.

**[ANIMATION]** end

There are two honest repairs.

**[ON SCREEN]** The repair table of section 13.10.

| Repair | Command | Effect | Choose it when |
|---|---|---|---|
| Keep both | `git merge origin/main`, then `git push` | The lost commits return with their original IDs, the forced commit stays, and the push is a fast-forward | The forced commit is legitimate work |
| Restore the old value | `git push --force-with-lease=main:<forced id> origin <old id>:main` | The server's branch is set back; the forced commit leaves the branch | The forced commit must not be on the branch (a rewrite that drops history) |

The second repair is a force push in its own right. Give it an explicit expected value, the forced commit, so that it fails if the server has moved again.

**[ANIMATION]** flow: actors=you,your_clone,*the_server subs=-,main_and_origin/main,refs/heads/main msgs=1>2:git_status|2>1:in_sync_(two_local_refs):ok|1>3:git_push|3>1:rejected_(fetch_first):fail|1>3:git_ls-remote|3>1:what_the_server_really_has:ok boundary=2 zones=local,the_network title=Which_answer_do_you_trust? id=trust

**Remote-tracking refs that can't be trusted.** A remote-tracking ref is a local record of the last contact with the server. `git status` compares two local refs. `git push` talks to the server. When they disagree, the server is right, and `git ls-remote` asks it without changing anything. Remote-tracking refs are derived data: remove what is broken and let a fetch write the truth.

**[ANIMATION]** end

When not to do any of this: the reflex "get in sync" with `git reset --hard origin/main` after a forced update. It removes the lost commits from the one local branch that still held them.

## MENTAL MODEL

Now a picture to keep. In the vault, a staged file is a box that was put on a shelf with a sticky label on the counter, the index entry. The reset swept the counter. The box is on the shelf with no label on it at all: no file name, no date. You find it by opening boxes and reading what is inside.

A line you typed and never staged was never put in a box. No audit of the vault will find it.

**[ANIMATION]** step: force.witness

**[ANIMATION]** say: Your_photocopy_ledger:_the_reflog_of_origin/main

For the remote side, picture two branch offices. Your office keeps a photocopy of the other office's index cards, taken at your last visit, and a ledger of how those photocopies changed. When the other office rewrites a card and keeps no ledger of its own, your photocopy ledger is the only written record of what the card used to say. The model breaks if you treat the photocopy as live. It's only as current as your last fetch.

## DIAGRAM

**[ANIMATION]** cards: question=Was_it_ever_an_object? cards=committed|stashed,_then_dropped_or_cleared|staged_with_git_add,_then_reset|edited_after_the_last_git_add|untracked_or_ignored,_then_removed|untracked,_and_only_a_reset_ran numbered=on marks=1:ok,2:ok,3:ok,4:bad,5:bad,6:ring id=kinds

**[ANIMATION]** step: 6

Six kinds of work. For each one ask the first of the three questions: was it ever an object? Try it now, thirty seconds. Answer for each one. Say it out loud.

**[PAUSE]**

**[ANIMATION]** step: marks

The first three say yes. The fourth and fifth say no.

**[DIAGRAM]** A table built row by row: the kind of work, whether an object exists, and what still names it after the accident. It combines the table of section 13.2 with the cases of section 13.9.

```text
  kind of work                         object exists?          what still names it after the accident
  -----------------------------------  ----------------------  ---------------------------------------------
  committed                            yes: commit, trees,     branch reflog, HEAD reflog (layer 2)
                                       blobs
  stashed, then dropped or cleared     yes: a merge commit     nothing (layer 3): git fsck --unreachable
  staged with git add, then reset      yes: one blob per       nothing (layer 3): git fsck --lost-found
                                       git add
  edited after the last git add        no                      nothing in Git: editor history, backups
  untracked or ignored, then removed   no                      nothing in Git
  untracked, and only a reset ran      (the file itself)       still in the working tree: reset does not
                                                               touch untracked files
```

Here is the full table, with what still names each kind of work after the accident. For the fourth and fifth rows you stop using Git at once.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/lab-12-8-overwritten-changes`. A fine-tuning project with three kinds of work at stake.

```bash
git status -s
git diff --cached --stat
git diff --stat
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/01-start -->
```text
$ cd finetune
$ git status -s
A  sweep.yaml
MM train.yaml
?? notes.md
$ git diff --cached --stat
 sweep.yaml | 2 ++
 train.yaml | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff --stat
 train.yaml | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

`sweep.yaml` is new and staged. `train.yaml` has a staged change and a later edit that isn't staged: that is the `MM`. `notes.md` is untracked.

**[ON SCREEN]** 🔴 DANGEROUS: `git reset --hard`. It overwrites the index and the working tree; unstaged changes to tracked files are destroyed for good. Preview: `git status`, and `git stash -u` first. Recovery: staged work through `git fsck --lost-found`; unstaged work, none.

Predict the fate of each of the three files. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git reset --hard
git status -s
ls
cat train.yaml
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/02-disaster -->
```text
$ git reset --hard
HEAD is now at cf76919 Add training config
$ git status -s
?? notes.md
$ ls
notes.md
train.py
train.yaml
$ cat train.yaml
lr: 3e-5
epochs: 3
```
<!-- /snippet -->

`notes.md` survived, because a reset doesn't touch untracked files. `sweep.yaml` is deleted and `train.yaml` is back at the committed version. Stop. Classify: staged, so layer three. 🟢 SAFE: `git fsck --lost-found` writes files under `.git/lost-found` and changes nothing else.

```bash
git fsck --lost-found
ls .git/lost-found/other
```

Predict the number of dangling blobs. Two files were staged.

<!-- snippet: ch13/lab-12-8-overwritten-changes/03-find -->
```text
$ git fsck --lost-found
dangling blob e199091045de591b8baa02bcd6a807b1788fb1cd
dangling blob e4e919703dbad4b896c710848d17d14d447f39ee
dangling blob 0697c1f85fe6c2da00446682c1a538103d96ea5c
$ ls .git/lost-found/other
0697c1f85fe6c2da00446682c1a538103d96ea5c
e199091045de591b8baa02bcd6a807b1788fb1cd
e4e919703dbad4b896c710848d17d14d447f39ee
```
<!-- /snippet -->

Three blobs for two files, because `sweep.yaml` was staged twice and each `git add` wrote a blob. Identify them by content.

```bash
grep -c "" .git/lost-found/other/*
grep -l warmup_ratio .git/lost-found/other/*
grep -l epochs .git/lost-found/other/*
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/04-identify -->
```text
$ grep -c "" .git/lost-found/other/*
.git/lost-found/other/0697c1f85fe6c2da00446682c1a538103d96ea5c:1
.git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd:2
.git/lost-found/other/e4e919703dbad4b896c710848d17d14d447f39ee:2
$ grep -l warmup_ratio .git/lost-found/other/*
.git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd
$ grep -l epochs .git/lost-found/other/*
.git/lost-found/other/e4e919703dbad4b896c710848d17d14d447f39ee
```
<!-- /snippet -->

```bash
cp .git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd sweep.yaml
git cat-file -p e4e9197 > train.yaml
cat sweep.yaml train.yaml
git add sweep.yaml train.yaml
git status -s
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/05-restore -->
```text
$ cp .git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd sweep.yaml
$ git cat-file -p e4e9197 > train.yaml
$ cat sweep.yaml train.yaml
lr: [1e-5, 3e-5]
warmup_ratio: [0.0, 0.1]
lr: 3e-5
epochs: 5
$ git add sweep.yaml train.yaml
$ git status -s
A  sweep.yaml
M  train.yaml
?? notes.md
```
<!-- /snippet -->

Both staged versions are back. The third blob, `0697c1f`, is the earlier staging of `sweep.yaml`.

Now what isn't there. The line `early_stopping: true` was typed after the last `git add`.

```bash
printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' | git hash-object --stdin
git cat-file -t fd0a951
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/06-never-staged -->
```text
# The line that was typed after the last "git add". This is the ID its file would have had:
$ printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' | git hash-object --stdin
fd0a951c99adb02cad59bdf1d4debd1d4de26084
$ git cat-file -t fd0a951
fatal: Not a valid object name fd0a951
[exit status: 128]
```
<!-- /snippet -->

`git hash-object` computes the ID that the full file would have had. No object with that ID exists.

**[ANIMATION]** objects: cards=blob:e199091:lr:_[1e-5,_3e-5]+warmup__ratio:_[0.0,_0.1]|blob:e4e9197:lr:_3e-5+epochs:_5|blob:0697c1f:lr:_[1e-5,_3e-5]|blob:fd0a951:...+early__stopping:_true+_ missing=fd0a951 title=Three_blobs_without_names,_and_one_that_never_existed id=blobs

The boundary of the safety net, drawn in two commands. Those are the two commands from the opening.

**[ANIMATION]** end

The stash, in a second copy of the project.

**[ON SCREEN]** 🔴 DANGEROUS: `git stash clear`. It deletes all stash entries together with their reflog lines. Preview: `git stash show -p`. Recovery: what follows, while the objects exist.

```bash
git stash list
git stash clear
git stash list
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/07-failure -->
```text
$ cd ../finetune-incident
$ git stash list
stash@{0}: On main: lora: rank 16 trial
stash@{1}: WIP on main: cf76919 Add training config
$ git stash clear
$ git stash list
```
<!-- /snippet -->

No output, no IDs. Here's the recipe from the stash manual. There were two entries. Quick quiz, three options: does it find none, one, or both? Say it out loud.

**[PAUSE]**

```bash
git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --grep=WIP --format='%h %s'
git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/08-recovery-recipe -->
```text
# The recipe from the git-stash manual:
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --grep=WIP --format='%h %s'
a0cbbaf WIP on main: cf76919 Add training config
# Without --grep=WIP:
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
0b0c40d On main: lora: rank 16 trial
a0cbbaf WIP on main: cf76919 Add training config
```
<!-- /snippet -->

One. The recipe ends in `--grep=WIP`. The default message of a stash is "WIP on" the branch. An entry made with `git stash push -m` is named "On" the branch and your message, and doesn't match. Leave the `--grep` out and rely on `--merges`: a stash entry is a merge commit, and few other unreachable commits are.

```bash
git stash store -m 'recovered: grad clip' a0cbbaf
git stash store -m 'recovered: lora rank 16 trial' 0b0c40d
git stash list
git stash show -p 'stash@{0}'
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/09-recovery-apply -->
```text
$ git stash store -m 'recovered: grad clip' a0cbbaf
$ git stash store -m 'recovered: lora rank 16 trial' 0b0c40d
$ git stash list
stash@{0}: recovered: lora rank 16 trial
stash@{1}: recovered: grad clip
$ git stash show -p 'stash@{0}'
diff --git a/train.yaml b/train.yaml
index 58da445..db55f58 100644
--- a/train.yaml
+++ b/train.yaml
@@ -1,2 +1,3 @@
 lr: 3e-5
 epochs: 3
+lora_rank: 16
```
<!-- /snippet -->

`git stash store` is 🟢 SAFE: it sets `refs/stash` and adds one reflog line. The entries are back in the list.

**[TERMINAL]** Replay `labs/run ch13/lab-12-11-force-push`. The remote side. A teammate pushed with `--force`.

```bash
git fetch
git status -sb
git log --oneline --graph main origin/main
```

<!-- snippet: ch13/lab-12-11-force-push/02-fetch -->
```text
$ git fetch
From ../server
 + d8a3934...882b940 main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 2, behind 1]
$ git log --oneline --graph main origin/main
* 882b940 Rename settings keys
| * d8a3934 Add cache metrics
| * 2a2bf94 Add answer cache
|/  
* 6955492 Add settings
* 1203ec5 Add question answering endpoint
```
<!-- /snippet -->

The plus sign and "(forced update)" mean that `origin/main` didn't move forward: the server's branch was replaced by a commit that doesn't descend from the old one.

**[ANIMATION]** step: force.witness

Status calls it divergence: ahead 2, behind 1. On the picture, two commits only you have, and one only the server has. Don't "get in sync". Read the evidence.

```bash
git reflog show origin/main
git log --format='%h %an: %s' origin/main..'origin/main@{1}'
git log --format='%h %an: %s' 'origin/main@{1}'..origin/main
```

<!-- snippet: ch13/lab-12-11-force-push/03-evidence -->
```text
$ git reflog show origin/main
882b940 refs/remotes/origin/main@{0}: fetch: forced-update
d8a3934 refs/remotes/origin/main@{1}: update by push
2a2bf94 refs/remotes/origin/main@{2}: pull: fast-forward
6955492 refs/remotes/origin/main@{3}: update by push
$ git log --format='%h %an: %s' origin/main..'origin/main@{1}'
d8a3934 Lab User: Add cache metrics
2a2bf94 Asha Rao: Add answer cache
$ git log --format='%h %an: %s' 'origin/main@{1}'..origin/main
882b940 Ravi Menon: Rename settings keys
```
<!-- /snippet -->

`origin/main@{1}` is the server's old tip, `d8a3934`. The two ranges are the damage report: two commits by two authors were removed from the server, and one commit, `882b940`, was put in their place.

```bash
ls ../server.git
git -C ../server.git reflog list
git -C ../server.git config get core.logAllRefUpdates
```

<!-- snippet: ch13/lab-12-11-force-push/04-server-has-no-record -->
```text
# The server is a bare repository. It kept no record of the value that was overwritten:
$ ls ../server.git
config
description
HEAD
hooks
info
objects
refs
$ git -C ../server.git reflog list
$ git -C ../server.git config get core.logAllRefUpdates
[exit status: 1]
# A teammate who has not fetched still has the value from her last contact with the server:
$ git -C ../asha log --oneline -1 origin/main
2a2bf94 Add answer cache
```
<!-- /snippet -->

The server kept no record. Here the forced commit is legitimate work, so the repair is "keep both".

**[ON SCREEN]** 🟡 CAUTION: `git merge`, then `git push`. New commits on the current branch; no force.

```bash
git merge -m 'Merge origin/main: restore commits removed by a force push' origin/main
git push
```

<!-- snippet: ch13/lab-12-11-force-push/05-repair -->
```text
$ git merge -m 'Merge origin/main: restore commits removed by a force push' origin/main
Merge made by the 'ort' strategy.
 settings.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git push
To ../server.git
   882b940..d967a92  main -> main
```
<!-- /snippet -->

**[ANIMATION]** step: force.push

The push is a fast-forward, `882b940..d967a92`: the server's tip is an ancestor of the merge commit, the commit with two parents that joins both lines. Every clone that already has the old commits, and every CI record that quotes their IDs, stays valid. Rebasing the lost commits onto the forced one would give them new IDs and create duplicates.

**[ANIMATION]** end

**[TERMINAL]** Replay `labs/run ch13/lab-12-10-remote-tracking`. Status says in sync; push is rejected.

```bash
git status -sb
git push
```

<!-- snippet: ch13/lab-12-10-remote-tracking/01-symptom -->
```text
$ cd docsearch
$ git status -sb
## main...origin/main
$ git push
To ../server.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

Two local refs agree, and the server disagrees. Ask the server.

```bash
git ls-remote origin
git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin
```

<!-- snippet: ch13/lab-12-10-remote-tracking/02-ask-the-server -->
```text
$ git ls-remote origin
e2753886b206a1781cfc9cb9520d36220feeae8e	HEAD
c6ec9d6c4248646f6256680df1f68a2772c1f442	refs/heads/feature/hybrid-search
e2753886b206a1781cfc9cb9520d36220feeae8e	refs/heads/main
$ git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin
warning: ignoring broken ref refs/remotes/origin/feature/hybrid-search
5eda6ed9f98f81e3870aadd032aaf47706d771bf refs/remotes/origin/main
```
<!-- /snippet -->

Two discrepancies. `origin/main` holds an ID that the server doesn't have at all, and `origin/feature/hybrid-search` is reported as a broken ref. The ordinary repair fails.

```bash
git fetch
git fsck
```

<!-- snippet: ch13/lab-12-10-remote-tracking/03-fetch-fails -->
```text
$ git fetch
fatal: bad object refs/remotes/origin/feature/hybrid-search
error: ../server.git did not send all necessary objects
[exit status: 1]
$ git fsck
error: refs/remotes/origin/feature/hybrid-search: badRefContent: 
error: refs/remotes/origin/feature/hybrid-search: invalid sha1 pointer 0000000000000000000000000000000000000000
dangling commit e2753886b206a1781cfc9cb9520d36220feeae8e
[exit status: 10]
```
<!-- /snippet -->

`badRefContent` names the damaged file. The dangling commit is worth reading: the fetch downloaded the server's new commit and then failed before it could update any ref.

```bash
wc -c < .git/refs/remotes/origin/feature/hybrid-search
git reflog show origin/main
git log -g --date=iso --format='%gd | %gn | %gs' origin/main
```

<!-- snippet: ch13/lab-12-10-remote-tracking/04-evidence -->
```text
$ wc -c < .git/refs/remotes/origin/feature/hybrid-search
       0
$ git reflog show origin/main
5eda6ed refs/remotes/origin/main@{0}: 
6edd8a2 refs/remotes/origin/main@{1}: update by push
$ git log -g --date=iso --format='%gd | %gn | %gs' origin/main
origin/main@{2026-09-07 10:19:00 +0530} | Lab User | 
origin/main@{2026-09-07 10:07:00 +0530} | Lab User | update by push
```
<!-- /snippet -->

The ref file is empty. And the newest reflog entry of `origin/main` has no message. A fetch writes "fetch:", a push writes "update by push". An entry without a message was written by `git update-ref` from a script or by hand.

**[ON SCREEN]** 🔴 DANGEROUS: `rm` of a file under `.git/refs`. It removes a ref outside Git's locking. The safety table says: move the file aside instead of deleting it, and recovery is to move it back. It is appropriate here because the ref is derived data and `git update-ref -d` cannot delete a ref it cannot read.

```bash
git update-ref -d refs/remotes/origin/feature/hybrid-search
rm .git/refs/remotes/origin/feature/hybrid-search
git fetch
git status -sb
```

<!-- snippet: ch13/lab-12-10-remote-tracking/05-repair -->
```text
$ git update-ref -d refs/remotes/origin/feature/hybrid-search
error: cannot lock ref 'refs/remotes/origin/feature/hybrid-search': unable to resolve reference 'refs/remotes/origin/feature/hybrid-search': reference broken
[exit status: 1]
$ rm .git/refs/remotes/origin/feature/hybrid-search
$ git fetch
From ../server
 + 5eda6ed...e275388 main                  -> origin/main  (forced update)
 * [new branch]      feature/hybrid-search -> origin/feature/hybrid-search
$ git status -sb
## main...origin/main [ahead 2, behind 1]
```
<!-- /snippet -->

The fetch corrected `origin/main` with a forced update and recreated the other ref. Status now tells the truth: two commits to push, one to integrate.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"A hard reset destroyed it, nothing to do."** Root cause: `git add` wrote a blob for every staged version, and the reset removed only the index entries.
2. **Searching for a staged file by name.** Root cause: the file name lived in the index entry; a blob has content only.
3. **Running the stash recipe with `--grep=WIP` and concluding that an entry is gone.** Root cause: entries made with a message are named "On <branch>: ..." and do not contain "WIP".
4. **`git reset --hard origin/main` after a forced update.** Root cause: it removes the lost commits from the one local branch that still held them; they remain only in reflog entries.
5. **Trusting `git status` about the server.** Root cause: status compares local refs, and a remote-tracking ref is a record of the last contact, which can be stale or damaged.

## PRODUCTION EXAMPLE

Now, out of the lab. A data platform team shares `main` of a question-answering service. On Monday morning one engineer's first fetch prints a plus sign and "forced update". Two commits from Friday, an answer cache by one colleague and its metrics by another, are no longer on the server. In their place is one commit that renames settings keys.

**[ANIMATION]** step: force.push

**[ANIMATION]** say: In_the_lab:_merge_origin/main,_then_an_ordinary_push

She doesn't pull and doesn't reset. She reads the reflog of `origin/main` and takes the entry before the forced update. Two range listings give her the damage report with authors, and she posts it with full commit IDs. The team decides that the rename is legitimate work, so she merges `origin/main` into her `main`, which still has the Friday commits, and pushes. No force is needed. The colleague who forced the push learns what a lease is, and the repository gets a rule against force pushes to `main`. That's GitHub's side, and it comes later in the course.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Lab 12.8, "Overwritten changes and a cleared stash", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

Before the reset, write down for each file whether an object exists for its current content, and how many blobs `git fsck` will report afterwards. Before you run the stash recipe, predict how many entries it lists with and without `--grep=WIP`.

The challenge is Lab 12.11, "A force push, seen from the local side", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q191: "A file was staged and then wiped by `git reset --hard`. What exactly can you get back, how, and what is gone? Why?"

Pause and answer out loud.

**[PAUSE]**

**[ANIMATION]** step: blobs.level-1

A strong answer divides the file's history into what was staged and what was typed afterwards, and gives the reason for each half in terms of when an object is written. It names the tool, says what form the findings take and how you tell one from another, since they carry no names. It states the deadline and what starts it. And it doesn't stop at "the rest is gone": it shows how you would demonstrate that, and where outside Git you would look next.

**[ANIMATION]** end

## RECAP

Let's land this. You should now be able to say:

- Every `git add` writes a blob; after a hard reset those blobs are dangling and `git fsck --lost-found` writes them out as files.
- Content that was never staged was never an object, and I can show that with `git hash-object` and `git cat-file`.
- A cleared stash entry is an unreachable merge commit; `git stash store` puts it back.
- After someone's forced push, `origin/main@{1}` in my clone is the server's old tip.
- When status and push disagree, I ask the server with `git ls-remote`.

## HOMEWORK

Read sections 13.9 and 13.10 of [Chapter 13](../../textbook/ch13-recovery.md). Do Lab 12.10, "Broken remote-tracking state, and a corrupt index", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md). Do Exercise 12.5, Level 2, "One file from a commit that only the reflog knows", and Exercise 12.7, Level 3, "A rejected push after "a small addition"", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you recovered work that had no name at all, and you used your own clone as the witness after a forced push. Do the overwritten changes lab before the next video. Next time: a damaged repository, and what can't be recovered. Until then, look at the state first and type second. See you in the next one.

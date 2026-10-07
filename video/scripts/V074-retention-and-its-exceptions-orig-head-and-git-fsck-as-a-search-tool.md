# V074: Retention and its exceptions, ORIG_HEAD, and git fsck as a search tool

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 26
- **Prerequisites.** V073
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), sections 13.4 to 13.6
- **Demo scripts.** `labs/ch13/reflog-retention.sh`, `labs/ch13/orig-head.sh`, `labs/ch13/fsck-find.sh`

## HOOK

**[ON SCREEN]** "How sure are you, and how long do we have?"

That was the CTO's second question in the last video, about work lost in a Git repository. The common answer in engineering chat is "relax, Git keeps everything for 30 days, plus two weeks". Three things are wrong with that sentence.

Nothing happens when the time is up. Expiry is work done by a command. The two weeks aren't added on top of the 30 days. And there are situations in which there was never a reflog entry to begin with: a deleted branch, a server, a tag, a branch you only fetched. The reflog, remember, is Git's local log of where each name has pointed.

If you give the CTO the comfortable number and the work was in one of those situations, you'll be wrong at the moment it matters. Keep that comfortable sentence in mind. By the end you can correct it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Last time you learned the four layers that protect a commit, a saved snapshot of your project: refs, reflogs, a grace period, and other repositories. And you learned how to read a reflog. Today you learn how long layers two and three last, and what shortens them. Then two instruments. `ORIG_HEAD`, which is convenient and holds exactly one value. And `git fsck`, which you met as an integrity check and now use as a search tool for work that no ref and no reflog names.

One remark about the demonstrations, said once. The lab clock is fixed in the past and the expiry code reads the real clock, so the lab configuration sets the two reflog periods to `never`. The 90 and 30 days are stated from the manual. On screen, expiry is shown only with the cut-off `now`, which doesn't depend on a clock. A relative cut-off would depend on the recording date.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- state the default retention periods and which event starts each;
- name the situations in which no reflog exists or it is deleted at once;
- say which four commands write `ORIG_HEAD` and why it is one slot;
- find lost commits with `git fsck` and explain `--no-reflogs`;
- triage a list of dangling commits to the one that matters.

## CONCEPT

**The defaults.** Three numbers govern recoverability in a repository with default configuration.

**[ON SCREEN]** The table of section 13.4.

| Setting | Default | What it removes |
|---|---|---|
| `gc.reflogExpire` | 90 days | Reflog entries older than this |
| `gc.reflogExpireUnreachable` | 30 days | Reflog entries older than this that are "not reachable from the current tip" |
| `gc.pruneExpire` | 2 weeks | Unreachable objects whose file is older than this |

Two facts about these numbers are routinely misunderstood.

First, nothing happens when the time is up. Expiry is work done by a command: `git gc`, Git's garbage collection, `git reflog expire`, or the maintenance that Git starts after some commands. An entry that is 100 days old is still there until one of them runs.

Second, the 30-day rule is the one that matters for recovery, because it applies to the entries you recover from. The manual says such entries "are generally created as a result of using `git commit --amend` or `git rebase` and are the commits prior to the amend or rebase occurring". The exact test, from the source: an entry is subject to the shorter period if its old value or its new value isn't reachable from the ref's current tip.

**The grace period isn't added on top.** `gc.pruneExpire` compares the cut-off with the modification time of the object file. The two weeks are measured against that modification time, not from the moment the object became unreachable.

Try it now, on paper. Thirty seconds: a commit was written 40 days ago and hasn't been touched since. Today it loses its last reflog entry. How much grace period is left? Say it out loud.

**[PAUSE]**

Possibly none. That commit may already be older than the cut-off. The grace period protects what never had a reflog entry and was written recently.

**The exceptions.** Four situations give you less than the table promises, and one gives you more.

**[ANIMATION]** cards: question=Less_than_the_table_promises,_and_once_more cards=a_deleted_branch:its_reflog_is_deleted_at_once|a_commit_never_checked_out:no_HEAD_reflog_entry|a_bare_repository:no_reflogs_by_default|tags:no_reflog|stash_entries:do_not_expire,_until_they_are_dropped marks=5:ok numbered=on id=except

**[ANIMATION]** step: 1

A deleted branch loses its reflog at once. The manual of `git branch` says so for `-d` and `-D`. The commits stay reachable from the HEAD reflog if you ever had the branch checked out. The same holds for a remote-tracking branch that `git fetch --prune` removes.

**[ANIMATION]** step: 2

A commit that was never checked out has no HEAD reflog entry. A teammate's branch that you only fetched exists in your clone as a remote-tracking ref. When that ref is pruned, nothing names the commits, and they are on layer three from that moment.

**[ANIMATION]** step: 3

A bare repository, one with no working tree, as on a server, keeps no reflogs by default. `core.logAllRefUpdates` is true by default in a repository with a working tree and false by default in a bare repository. A server that receives a force push therefore has no record of the value that was overwritten.

**[ANIMATION]** step: 4

Tags, the fixed names for commits, have no reflog. Moving a tag with `git tag -f` prints the old ID once, and that line is the only record.

**[ANIMATION]** step: marks

And the one that gives you more: stash entries, your parked uncommitted work, don't expire, until they are dropped. The textbook cites a comment in Git's source for this, "If unconfigured, make stash never expire", and notes that no manual page states it. The exemption applies to the default periods only. A cut-off given on the command line applies to every ref, `refs/stash` included.

**[ANIMATION]** end

**`ORIG_HEAD`.** In one sentence: a file that holds the commit HEAD, your current position, pointed at before the last "drastic" command, so that the command can be undone with `git reset --hard ORIG_HEAD`. The manual names four commands: `git am`, `git merge`, `git rebase`, `git reset`. `git pull` writes it too, because it runs a merge or a rebase, and so does `git stash push`, through the reset it performs. Inside `.git` it's one file with one ID. It has no reflog, and it's not a starting point for garbage collection.

**`git fsck` as a search tool.** In one sentence: `git fsck` walks the object database from every starting point and reports what it can't reach. 🟢 SAFE, except that `--lost-found` writes files into `.git/lost-found`.

Four options matter. The default, `--dangling`, reports unreachable objects that no other object refers to: the tips of lost history, and blobs that lost their index entry. `--unreachable` reports every unreachable object. `--no-reflogs` doesn't count reflog entries as starting points. And `--lost-found` also writes each dangling commit's ID and each dangling blob's content into files.

**[ANIMATION]** graph: b997512-53c5b13-2ae0c97; HEAD=none; mark:unreachable:b997512,53c5b13; dangling:2ae0c97; note:2ae0c97:unreachable,_and_nothing_refers_to_it; title:A_tip_and_a_chain; say:Three_lost_commits:_all_unreachable,_only_the_newest_dangling id=chain

The difference between "dangling" and "unreachable" is the difference between a tip and a chain. On screen, the three commits of the branch `exp/hybrid` from today's demonstration, after its deletion. If three commits are lost, all three are unreachable, and only the newest is dangling, because the newest still refers to the other two. For recovery you want dangling commits: anchor the tip and the chain comes with it.

## MENTAL MODEL

**[ANIMATION]** graph: A-B-C main; HEAD=main; title:ORIG__HEAD_is_one_slot => + B main; C ORIG_HEAD; reflog:C; cmd:!git_reset_--hard_HEAD~1; say:A_reset_writes_ORIG__HEAD:_the_tip_from_before_the_command; name:first => + A main; B ORIG_HEAD; reflog:B,C; cmd:!git_reset_--hard_HEAD~1; say:The_next_reset_replaces_it._The_reflog_keeps_both; name:second id=slot at_state_1=5 at_first=30 at_second=60

Now a picture to keep. For `ORIG_HEAD` the textbook's analogy is the "last number redial" button of a phone. It holds exactly one number, the newest call replaces it, and it tells you nothing about which call that was. The reflog is the full call list.

**[ANIMATION]** end

Carry the vault from the last video for the rest. A reflog is a ledger that is trimmed by a retention policy. It's not a second copy of the ref. And `git fsck` is the audit that walks the vault with every card and every ledger line in hand and lists the boxes nobody mentions. With `--no-reflogs`, the auditor leaves the ledger at the desk and uses the cards only.

Where the redial button breaks as a model: a phone's last number is at least always the last call. `ORIG_HEAD` is the position before the last command from a short list. After a commit, a switch or a cherry-pick it still holds a value from some earlier command.

## DIAGRAM

**[ANIMATION]** ladder: rungs=day_0,_the_amend:layer_2,_two_reflogs_name_the_old_commit|day_0_to_30:git_reset_--hard_<id>_or_git_branch_<name>_<id>_brings_it_back|after_day_30:next_maintenance_run:_the_reflog_entries_go,_the_object_may_go_too|later:a_collection_deletes_what_is_unreachable_and_older_than_the_cut-off title=The_life_of_an_amended_commit id=life

**[DIAGRAM]** The picture of section 13.4: the life of a commit that was replaced by `git commit --amend`, in a repository with default settings.

```text
  day 0            amend: the old commit leaves the branch.   Layer 2: two reflogs name it.
  day 0 to 30      "git reset --hard <id>" or "git branch <name> <id>" brings it back.
  after day 30     the next maintenance run removes those reflog entries.   Layer 3, or gone:
                   the object file is older than two weeks, so the same run may delete it.
  later            a collection deletes whatever is unreachable and older than the cut-off.
```

Stop on the third row. After day 30 the next maintenance run removes the reflog entries, and because the object file is already older than two weeks, the same run may delete the object. There's no second waiting period.

**[DIAGRAM]** The picture of section 13.6, with the IDs of the transcript.

```text
  b997512 <-- 53c5b13 <-- 2ae0c97                   8fb6e9c
  unreachable  unreachable  unreachable and          a blob: unreachable and dangling
                            DANGLING (nothing        (it was staged, then the index entry was reset)
                            refers to it)
```

Three commits in a chain. All three are unreachable. Only `2ae0c97` is dangling. The blob on the right is both: it was staged, and then its index entry was reset.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/reflog-retention`. A branch was amended, extended by one commit, and reset by one commit.

```bash
git reflog show main
git reflog expire --dry-run --verbose --expire-unreachable=now refs/heads/main
```

**[ANIMATION]** graph: 538ea2f-536f5df-da62b60 main; HEAD=main; title:Amended,_extended,_reset => 538ea2f-536f5df-dfcbd4b main; 536f5df-da62b60; reflog:da62b60; HEAD=main; cmd:git_commit_--amend; name:amend => + dfcbd4b-5c75388 main; cmd:git_commit; name:extend => + dfcbd4b main; reflog:da62b60,5c75388; cmd:!git_reset_--hard_HEAD~1; say:Two_commits_are_off_the_current_history; name:reset => 538ea2f-536f5df-dfcbd4b main; 536f5df-da62b60; dfcbd4b-5c75388; ghost:da62b60,5c75388; dangling:da62b60,5c75388; HEAD=main; cmd:!git_reflog_expire_--expire=now_--all; say:No_reflog_names_them_now:_layer_three; name:expired id=amended dx=260

**[ANIMATION]** step: reset

Here's that branch as a picture: three commits, an amend, one more commit, and a reset. Two commits end up off the current history.

Predict: of six entries, how many fall under the 30-day rule? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch13/reflog-retention/01-which-entries -->
```text
$ git reflog show main
dfcbd4b main@{0}: reset: moving to HEAD~1
5c75388 main@{1}: commit: Temporary debug flag
dfcbd4b main@{2}: commit (amend): Raise top_k from 5 to 10
da62b60 main@{3}: commit: Raise top_k to 10
536f5df main@{4}: commit: Add embedding client
538ea2f main@{5}: commit (initial): Add retriever config
# Which entries does the 30-day rule apply to? Ask with a cut-off of "now" and --dry-run:
$ git reflog expire --dry-run --verbose --expire-unreachable=now refs/heads/main
keep commit (initial): Add retriever config
keep commit: Add embedding client
prune commit: Raise top_k to 10
prune commit (amend): Raise top_k from 5 to 10
prune commit: Temporary debug flag
prune reset: moving to HEAD~1
# It was a dry run. All six entries are still there:
$ git reflog show main | grep -c main@
6
```
<!-- /snippet -->

Four of six. The commit before the amend, the commit that was reset away, and also the two entries whose other end is one of those commits. Despite the word `prune` in the output, the dry run removed nothing.

**[ON SCREEN]** 🔴 DANGEROUS: `git reflog expire`. The five answers. What it changes: it removes reflog entries by age and reachability; it changes no ref and deletes no object. What it can destroy: the names that keep objects on layer two, which is the safety net itself. How to preview: `--dry-run`, as you saw. How to recover: you cannot restore a removed entry; the objects can still be found with `git fsck` while they exist. When it is appropriate: almost never by hand; the manual calls it "typically not used directly by end users".

```bash
git reflog expire --expire-unreachable=now refs/heads/main
git reflog show main
git log --oneline -1 main
git reflog -3
```

<!-- snippet: ch13/reflog-retention/02-after-expiry -->
```text
$ git reflog expire --expire-unreachable=now refs/heads/main
$ git reflog show main
536f5df main@{0}: commit: Add embedding client
538ea2f main@{1}: commit (initial): Add retriever config
$ git log --oneline -1 main
dfcbd4b Raise top_k from 5 to 10
$ git reflog -3
dfcbd4b HEAD@{0}: reset: moving to HEAD~1
5c75388 HEAD@{1}: commit: Temporary debug flag
dfcbd4b HEAD@{2}: commit (amend): Raise top_k from 5 to 10
```
<!-- /snippet -->

**[ON SCREEN]** The first root-cause box of section 13.4.

```text
Observed behavior : "git reflog show main" starts at "Add embedding client", but main points at dfcbd4b
Git state         : refs/heads/main = dfcbd4b; the newest line left in logs/refs/heads/main records 536f5df
Mechanism         : reflog expiry removed every entry with an end that the current tip does not reach,
                    including the entries that moved the branch to its current value
Root cause        : a reflog is a list of past changes that is trimmed by a retention policy; it is not
                    a second copy of the ref
Why Git does this : such changes "are not part of the current project", so "most users will want to
                    expire them sooner" (git help gc)
Correct fix       : none needed; the ref is right and the log is shorter
Prevention        : anchor anything you may want later with a branch or tag before the 30 days are over
```

The HEAD reflog wasn't named in that command and still has every entry. In a real repository both logs are trimmed in the same run.

Now the stash. Two entries.

<!-- snippet: ch13/reflog-retention/04-stash -->
```text
$ printf 'top_k: 20\n' > retriever.yaml
$ git stash push -q -m "try top_k 20"
$ printf 'top_k: 50\n' > retriever.yaml
$ git stash push -q -m "try top_k 50"
$ git stash list
stash@{0}: On main: try top_k 50
stash@{1}: On main: try top_k 20
$ git reflog show refs/stash
71ed40a refs/stash@{0}: On main: try top_k 50
89fc6b8 refs/stash@{1}: On main: try top_k 20
```
<!-- /snippet -->

The stash list is the reflog of `refs/stash`. Predict what `git stash list` prints after a cut-off of `now` is applied to all refs.

```bash
git reflog expire --expire=now --all
git stash list
git log --oneline -1 refs/stash
git fsck
```

<!-- snippet: ch13/reflog-retention/05-stash-after-expire -->
```text
$ git reflog expire --expire=now --all
$ git stash list
$ git log --oneline -1 refs/stash
71ed40a On main: try top_k 50
$ git fsck
dangling commit 89fc6b87236ad6fbf9108422f65174e9dfc095dd
dangling commit da62b6073a1d8c0afa10417bc244ed245ccdff86
dangling commit 5c7538866f5b5c9cfc3186aa957123a55108d5a0
```
<!-- /snippet -->

Nothing. The ref still points at `71ed40a`, the newest entry. The older entry, `89fc6b8`, is now a dangling commit.

**[ANIMATION]** step: amended.expired

And the two commits from the picture are in that list as well.

**[ANIMATION]** end

**[ON SCREEN]** The second root-cause box of section 13.4.

```text
Observed behavior : "git stash list" prints nothing after "git reflog expire --expire=now --all"
Git state         : refs/stash still points at 71ed40a, the newest entry; its log is empty;
                    the older entry 89fc6b8 is a dangling commit
Mechanism         : "git stash list" prints the reflog of refs/stash. The command emptied the log
                    and left the ref alone
Root cause        : only the newest stash entry is held by a ref. Every older entry is held by a
                    reflog line and by nothing else
Why Git does this : the stash was built as one ref plus its reflog, so that "stash@{n}" is ordinary
                    reflog syntax
Correct fix       : "git stash pop" still restores the newest entry (below). The older ones are found
                    with git fsck while their objects exist
Prevention        : do not expire reflogs with --all in a repository that holds stashes you need;
                    commit long-lived work to a branch instead of stashing it
```

The root cause: only the newest stash entry is held by a ref. Every older entry is held by a reflog line and by nothing else.

```bash
git stash pop
git stash list
```

<!-- snippet: ch13/reflog-retention/06-stash-rescue -->
```text
$ git stash pop
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   retriever.yaml

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (71ed40a90f00616a336fa87d8470ab2abfc42ce6)
$ git stash list
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
71ed40a On main: try top_k 50
89fc6b8 On main: try top_k 20
```
<!-- /snippet -->

The newest entry comes back. You recover an older one in the video on uncommitted work.

The server. A push into a bare repository.

```bash
git -C searchsvc push -q origin main
git -C server.git reflog list
git -C server.git config get core.logAllRefUpdates
git -C searchsvc config get core.logAllRefUpdates
```

<!-- snippet: ch13/reflog-retention/07-bare -->
```text
$ git -C searchsvc push -q origin main
$ git -C server.git reflog list
$ git -C server.git config get core.logAllRefUpdates
[exit status: 1]
$ git -C searchsvc config get core.logAllRefUpdates
true
```
<!-- /snippet -->

No reflogs on the bare side. The setting isn't set there. Whoever administers a bare repository can switch it on. `git config set` and `git config get` need Git 2.46 or later.

```bash
git -C server.git config set core.logAllRefUpdates true
git -C searchsvc commit -q --amend -m "Raise top_k to ten"
git -C searchsvc push -q --force origin main
git -C server.git reflog show main
git -C server.git log --oneline -1 'main@{1}'
```

<!-- snippet: ch13/reflog-retention/08-bare-with-reflog -->
```text
# Whoever runs a bare repository can switch reflogs on:
$ git -C server.git config set core.logAllRefUpdates true
$ git -C searchsvc commit -q --amend -m "Raise top_k to ten"
$ git -C searchsvc push -q --force origin main
$ git -C server.git reflog show main
803db47 main@{0}: push
$ git -C server.git log --oneline -1 'main@{1}'
dfcbd4b Raise top_k from 5 to 10
```
<!-- /snippet -->

The log has one line, and `main@{1}` still resolves: Git takes the old value recorded in that line. This is a setting for servers you run yourself. A hosting service has its own instruments, which come at the end of this module.

**[TERMINAL]** Replay `labs/run ch13/orig-head`. A fresh repository has no `ORIG_HEAD`.

<!-- snippet: ch13/orig-head/01-not-written -->
```text
$ git log --oneline --graph --all
* 584d822 Add README
| * 68e6fff Rerank the top 20
| * 155d4ba Add reranker
|/  
* da62b60 Raise top_k to 10
* 536f5df Add embedding client
* 538ea2f Add retriever config
# A fresh repository has no ORIG_HEAD. These four commands move HEAD and do not create it:
$ git commit -q --amend -m "Add a README"
$ git switch -q feature/rerank && git switch -q main
$ git cherry-pick feature/rerank~1 > /dev/null
$ git revert --no-edit HEAD > /dev/null
$ git rev-parse --verify --short ORIG_HEAD
fatal: Needed a single revision
[exit status: 128]
$ git reflog -4
78070c2 HEAD@{0}: revert: Revert "Add reranker"
1ab399b HEAD@{1}: cherry-pick: Add reranker
f912289 HEAD@{2}: checkout: moving from feature/rerank to main
68e6fff HEAD@{3}: checkout: moving from main to feature/rerank
```
<!-- /snippet -->

An amend, two switches, a cherry-pick and a revert: five movements of HEAD, each with a reflog entry, and no `ORIG_HEAD`. A reset, a merge and a rebase each write it.

<!-- snippet: ch13/orig-head/02-reset -->
```text
$ git reset -q --hard HEAD~2
$ git log --oneline -1 ORIG_HEAD
78070c2 Revert "Add reranker"
```
<!-- /snippet -->

<!-- snippet: ch13/orig-head/03-merge -->
```text
$ git log --oneline -1
f912289 Add a README
$ git merge -q feature/rerank
$ git log --oneline -1 ORIG_HEAD
f912289 Add a README
```
<!-- /snippet -->

<!-- snippet: ch13/orig-head/04-rebase -->
```text
$ git reset -q --hard ORIG_HEAD
$ git switch -q feature/rerank
$ git log --oneline -1
68e6fff Rerank the top 20
$ git rebase -q main
$ git log --oneline -1 ORIG_HEAD
68e6fff Rerank the top 20
```
<!-- /snippet -->

Each time the value is the tip from immediately before the command. Now the trap. You switch to `main` and cherry-pick. Quick quiz, three options. Does `ORIG_HEAD` name the tip of `main` before the cherry-pick, the old tip of the feature branch, or nothing? Say it out loud.

**[PAUSE]**

```bash
git switch -q main
git cherry-pick feature/rerank > /dev/null
git log --oneline -1 ORIG_HEAD
git branch --contains ORIG_HEAD
cat .git/ORIG_HEAD
git reflog exists ORIG_HEAD
```

<!-- snippet: ch13/orig-head/05-stale -->
```text
# A later command that does not write ORIG_HEAD leaves the old value in place:
$ git switch -q main
$ git cherry-pick feature/rerank > /dev/null
$ git log --oneline -1 ORIG_HEAD
68e6fff Rerank the top 20
$ git branch --contains ORIG_HEAD
$ cat .git/ORIG_HEAD
68e6fff0a6256f993946e89883a38d029db3cce6
$ git reflog exists ORIG_HEAD
[exit status: 1]
```
<!-- /snippet -->

Option two. `68e6fff`, a commit of the feature branch from before its rebase, which no branch contains any more.

**[ANIMATION]** graph: da62b60-f912289 main; ^da62b60-155d4ba-68e6fff ORIG_HEAD; f912289-?copy_1-?copy_2 feature/rerank; reflog:155d4ba,68e6fff; HEAD=feature/rerank; cmd:git_rebase_main; say:The_rebase_wrote_ORIG__HEAD:_the_old_tip,_68e6fff; title:ORIG__HEAD,_some_commands_later => + f912289-?picked main; HEAD=main; cmd:git_cherry-pick_feature/rerank; say:A_cherry-pick_does_not_write_it._The_old_value_stays; name:later id=stale dx=260

`git reset --hard ORIG_HEAD` at this moment would move `main` onto abandoned history. On the picture, `ORIG_HEAD` sits on a dashed commit that no branch contains. Almost everyone trusts it once too often.

**[ON SCREEN]** The two-column table of section 13.5. Writes `ORIG_HEAD`: `git reset` in every mode, `git merge` including a fast-forward, `git rebase`, `git am`, `git pull`, `git stash push`. Does not write it: `git commit`, `git commit --amend`, `git switch`, `git checkout`, `git cherry-pick`, `git revert`, `git fetch`, `git push`. The textbook is exact about the evidence: the left column is from the manual and the transcripts; the right column is observed.

**[TERMINAL]** Replay `labs/run ch13/fsck-find`. A branch with three commits is deleted. A file was staged earlier and then thrown away by a reset.

**[ON SCREEN]** 🔴 DANGEROUS: `git branch -D`. The five answers, from the command safety table of the chapter. What it changes: it deletes a ref together with that ref's reflog. What it can destroy: the only name of commits that were never merged; it deletes no object. How to preview: use `git branch -d`, which refuses when the branch is not fully merged. How to recover: recreate the ref at the old tip, while the objects exist; that is the next video. When it is appropriate: when you have read the refusal of `-d` and decided the commits are not needed.

```bash
git branch -D exp/hybrid
git fsck
```

**[ANIMATION]** graph: 538ea2f-536f5df-da62b60 main; da62b60-b997512-53c5b13-2ae0c97 exp/hybrid; HEAD=main; title:Three_lost_commits => + drop:exp/hybrid; reflog:b997512,53c5b13,2ae0c97; cmd:!git_branch_-D_exp/hybrid; say:The_branch_is_deleted,_and_its_reflog_with_it; name:deleted => + mark:unreachable:b997512,53c5b13; dangling:2ae0c97; cmd:git_fsck_--no-reflogs; say:Without_the_reflogs:_three_unreachable,_one_dangling; name:noreflogs => 538ea2f-536f5df-da62b60 main; da62b60-b997512-53c5b13-2ae0c97 rescue/hybrid; HEAD=main; cmd:git_branch_rescue/hybrid_2ae0c97; say:One_label_on_the_tip:_layer_one_again; name:anchor id=lostline dx=260

**[ANIMATION]** step: deleted

Predict: does `git fsck` report the three commits? Say it out loud.

**[PAUSE]**

<!-- snippet: ch13/fsck-find/01-with-reflogs -->
```text
$ git branch -D exp/hybrid
Deleted branch exp/hybrid (was 2ae0c97).
$ git fsck
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
```
<!-- /snippet -->

No. Only the blob, the content of one file. The three commits are still reachable from the HEAD reflog, because the branch was checked out when they were made. That default answers "what is at risk of being collected?". To ask "what is no longer on any branch?", take the reflogs out.

```bash
git fsck --no-reflogs
git fsck --no-reflogs --unreachable
```

<!-- snippet: ch13/fsck-find/02-no-reflogs -->
```text
$ git fsck --no-reflogs
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
dangling commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
$ git fsck --no-reflogs --unreachable
unreachable blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
unreachable blob d101568e3177507ffec6dd9a56c478cce1751b2f
unreachable tree 918936da64f9772a5456d5940fb80ffa0d220346
unreachable tree 17b30d538538f6762ec168c66bcaeae783356477
unreachable commit 53c5b13f7e8f3f23e8a4363f15be846e93ff5862
unreachable blob 257d9cc0829b942c09bd1d17b1ec8490ec8bd2b1
unreachable commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
unreachable tree b08f744630034d54db33226cb5fff7e5a816fb87
unreachable blob 34ddd608dd3b612063f7806ca172b6ab36381925
unreachable commit b9975128858772d81064c041f60f4944ec3f428f
```
<!-- /snippet -->

One dangling commit, `2ae0c97`, stands for three unreachable commits with their trees and blobs.

**[ANIMATION]** step: lostline.noreflogs

In a repository that has been used for months the list of dangling commits is long: every amend, every rebase and every dropped stash leaves one. Turn the list into something you can read.

```bash
git fsck --no-reflogs | awk '/dangling commit/ {print $3}' | xargs git log --no-walk --date=iso --format='%h  %cd  %an  %s'
git log --oneline 2ae0c97 --not --all
```

<!-- snippet: ch13/fsck-find/03-triage -->
```text
$ git fsck --no-reflogs | awk '/dangling commit/ {print $3}' | xargs git log --no-walk --date=iso --format='%h  %cd  %an  %s'
2ae0c97  2026-09-07 10:09:00 +0530  Lab User  Tune alpha to 0.6
$ git log --oneline 2ae0c97 --not --all
2ae0c97 Tune alpha to 0.6
53c5b13 Add hybrid weights
b997512 Add dense scorer
```
<!-- /snippet -->

Date, author, subject for each tip. The second command shows the whole lost line: commits reachable from the found tip and from no ref.

```bash
git fsck --no-reflogs --lost-found
find .git/lost-found -type f | sort
cat .git/lost-found/other/*
```

<!-- snippet: ch13/fsck-find/04-lost-found -->
```text
$ git fsck --no-reflogs --lost-found
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
dangling commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
$ find .git/lost-found -type f | sort
.git/lost-found/commit/2ae0c97ba880a6defccc70c29261e46cb2d37bdf
.git/lost-found/other/8fb6e9c8eb419f470869b10b7fcc64cf510486a0
$ cat .git/lost-found/other/*
alpha: [0.5, 0.6, 0.7]
```
<!-- /snippet -->

`--lost-found` saves the findings as files. That's convenient for blobs: a blob has no name and no date and can only be recognised by its content.

A found commit is still unreachable. Reading it doesn't protect it. Give it a ref. 🟢 SAFE: `git branch <name> <id>` writes one ref and changes nothing else.

```bash
git branch rescue/hybrid 2ae0c97
git fsck --no-reflogs
git log --oneline main..rescue/hybrid
```

<!-- snippet: ch13/fsck-find/05-anchor -->
```text
$ git branch rescue/hybrid 2ae0c97
$ git fsck --no-reflogs
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
$ git log --oneline main..rescue/hybrid
2ae0c97 Tune alpha to 0.6
53c5b13 Add hybrid weights
b997512 Add dense scorer
```
<!-- /snippet -->

**[ANIMATION]** step: lostline.anchor

From this moment the three commits are on layer one, and no expiry or collection can touch them. One label on the tip, and the whole chain is solid again.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"30 days in the reflog, then two more weeks."** Root cause: the prune cut-off is compared with the modification time of the object file, not with the moment the object became unreachable.
2. **Expecting a deleted branch's reflog to still exist.** Root cause: `git branch -d` and `-D` delete the reflog with the branch; only the HEAD reflog, or `git fsck`, still knows the tip.
3. **`git reset --hard ORIG_HEAD` some commands later.** Root cause: `ORIG_HEAD` is one slot written by a short list of commands, and it keeps the value of an earlier one after commands that do not write it.
4. **"`git fsck` shows nothing, so the commits are gone."** Root cause: by default reflog entries count as starting points, so commits that a reflog still names are not reported; `--no-reflogs` removes them from the roots.
5. **Reading "dangling" as damage.** Root cause: dangling is information; only lines that begin with `missing`, `broken` or `error` describe a repository that needs repair.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML engineer cleans up a clone that holds six months of experiments. A blog post recommends expiring all reflogs with a cut-off of now to "shrink the repository". Afterwards `git stash list` is empty. It held four parked prompt-tuning experiments.

**[ANIMATION]** stores: boxes=refs/stash:one_ref|its_reflog:what_git_stash_list_prints|after_expire_--all:the_log_is_empty rows=1:A:71ed40a|2:B:stash@{0}_71ed40a|2:B:stash@{1}_89fc6b8|3:C:refs/stash_→_71ed40a@ok|3:C:89fc6b8:_dangling@bad mono=on title=In_the_lab:_two_stash_entries id=stash

The lead reads the state before anyone types more. `refs/stash` still points at the newest entry, so one experiment comes back with `git stash pop`. The other three were held by reflog lines only. They're dangling commits now, on layer three, and nothing has been pruned yet. The team finds them with `git fsck`, anchors each one, and writes down the rule that the root-cause box gives: long-lived work goes on a branch, not into the stash, and nobody expires reflogs with `--all` in a repository that holds work.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Exercise 12.3, Level 1, "`git fsck` as a search tool", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before each `git fsck` invocation, predict how many dangling commits and how many dangling blobs it will print, and say which starting points you included or excluded. Then anchor what you find and predict what the next `git fsck` will no longer report.

The challenge is Exercise 12.6, Level 2, draw the graph, "Reset, commit, rescue, rebase", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q192: "State the default retention periods, say which event starts each period, and explain why "30 days plus two weeks" is not a guarantee."

Pause and answer out loud.

**[PAUSE]**

A strong answer gives three numbers with the setting behind each, and says to which entries the shorter reflog period applies. It then separates two clocks: the timestamp of a reflog entry, and the modification time of an object file. It explains that expiry happens when a command runs and not when a date passes. And it lists the cases in which the first clock never started, because there was no reflog entry at all. If you can add what the lab environment changes and why, you have shown that you know the difference between the manual and a particular configuration.

## RECAP

Let's land this. You should now be able to say:

- By default reflog entries last 90 days, 30 days if an end is off the current history, and unreachable objects older than two weeks can be pruned; none of it happens until a command runs.
- A deleted branch, a bare repository, a tag and a branch that was only fetched have no reflog to recover from.
- `ORIG_HEAD` is one slot written by reset, merge, rebase and am; I use it only as the very next command, and the branch reflog otherwise.
- `git fsck --no-reflogs` lists what no ref reaches; a dangling commit is the tip of a lost chain.
- A found commit is safe only after I give it a ref.

## HOMEWORK

Read sections 13.4 to 13.6 of [Chapter 13](../../textbook/ch13-recovery.md). Do Exercise 12.2, Level 1, "A backup ref, and the one slot of `ORIG_HEAD`", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

**[ANIMATION]** step: life.4

Today you learned how long each layer lasts, and you can now correct that comfortable sentence about 30 days plus two weeks. Find a dangling commit in the lab shell before the next video. Next time: the recovery method, and the first three recoveries. Until then, look at the state first and type second. See you in the next one.

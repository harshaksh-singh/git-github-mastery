# V073: What Git keeps: four layers of protection, and the reflog

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 22
- **Prerequisites.** V009, V047
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), sections 13.1 to 13.3
- **Demo scripts.** `labs/ch13/reflog-anatomy.sh`, `labs/ch13/gc-ladder.sh` (snippet `01-reflog-protects`)

## HOOK

**[ON SCREEN]** 18:40, release day. A message in the incident channel: "I ran a reset and three days of work on the reranker are gone."

A reset points a branch at another commit, another saved snapshot, and the work after it seems to vanish. Your CTO asks you two questions, and neither of them is "which command do we type". The first is: can we get it back? The second is: how sure are you, and how long do we have?

Both questions have exact answers. They depend on three facts about the lost work. Was it ever written into the object database, Git's store of everything it has saved? Does anything still name it? Has the clock run out? If you can answer those three from evidence, you can answer the CTO in a minute, and you can also say the harder sentence when it's true: this can't be recovered, and here is exactly why. Hold on to 18:40. We come back to it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens the recovery module. For the next seven videos you take fifteen kinds of accident and bring the work back, or prove that it is gone.

Three earlier videos supply the foundations. You know reachability: an object is kept as long as some starting point reaches it. You know what `git reset --hard` destroys. And you know force pushes and remote-tracking refs, your records of where a server's branches were. Today those pieces become a map, four layers of protection, and you learn to read the instrument you'll use in almost every recovery: the reflog.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- name the four layers that protect work and what each holds;
- read a reflog entry: old ID, new ID, selector, action;
- tell the HEAD reflog from a branch reflog and choose the right one for an incident;
- use `@{n}` and time selectors, and explain why the reflog is local;
- explain how an unreachable commit survives a maintenance run.

## CONCEPT

In one sentence: Git never deletes an object that something still names, it keeps a private log of every name that recently changed, and it waits before deleting what nothing names. Work is lost only when it was never an object, or when all of these protections are gone.

**[ANIMATION]** cards: question=Starting_points:_what_they_reach_is_kept cards=branches_and_tags|the_index|remote-tracking_branches|reflogs|anything_else_in_refs/*|a_note_on_an_object:does_not_keep_it_alive dim=6 id=starts

Precisely. An object is kept as long as it is reachable from a starting point. The manual of `git gc` lists the starting points: branches and tags, the index, which is your proposed next commit, remote-tracking branches, reflogs, "and anything else in the refs/* namespace". It adds one exclusion: a note attached to an object doesn't keep it alive. An object that no starting point reaches is unreachable. It still exists until a collection, Git's clean-up of its store, deletes it, and a collection deletes only objects older than a cut-off, two weeks by default.

**[ANIMATION]** end

That gives four layers, and a recovery is always a move from a lower layer back to the first one.

**[ON SCREEN]** The four-layer table of section 13.2.

Layer one is refs, the names that hold an object ID. A branch, a tag, a remote-tracking ref, `refs/stash`, HEAD or the index names the object. It lasts until the ref is moved or deleted. You find it with `git log --all` or `git for-each-ref`.

Layer two is reflogs. A reflog entry names the object. The manual's defaults are 90 days, or 30 days for entries off the current history. The lab configuration overrides both, so that the transcripts don't depend on the day they were produced. You get the details in the next video. You find these with `git reflog` and `git log -g`.

Layer three is the grace period. Nothing names the object, but its file is younger than the prune cut-off. Two weeks from the time the object was written, and then until the next collection runs. The tool is `git fsck`.

Layer four is other repositories: another clone, the server, a bundle file, a backup. Its lifetime is independent of this repository.

Before the layers comes a precondition: was the work ever an object?

**[ON SCREEN]** The table "Form of the work" from section 13.2. Committed: yes, a commit, trees and blobs, named by a branch or HEAD and the reflog. Stashed: yes, two or three commits, named by `refs/stash` and its reflog. Staged with `git add` and not committed: yes, a blob, named only by the index entry. Saved in the working tree and never staged: no object. Untracked or ignored: no object.

Read the middle column. Committed, stashed, or staged with `git add`: an object exists. Saved in the working tree and never staged, or untracked: no object, and nothing for Git to bring back.

Now the reflog. In one sentence: a reflog is a local, append-only list of the values a ref has had, with the time, the person and the command behind each change, and every one of those old values is a name you can use.

Precisely. There's one reflog per ref that has logging enabled, plus one for HEAD. In a repository with a working tree, Git by default logs HEAD, branches, remote-tracking branches and notes refs. Tags get no reflog unless the setting `core.logAllRefUpdates` is `always`. Each entry stores the value before the change, the value after it, the committer identity and time, and a message written by the command.

There are two kinds, and they answer different questions. The HEAD reflog records every movement of HEAD: commits, switches, resets, each step of a rebase, merges, cherry-picks. It answers "what did I do, in order", and it's the only log that sees detached HEAD, when you're on no branch. A branch reflog records only changes of that branch's value. It answers "where was this branch before the operation". A whole rebase is one entry there.

When the reflog can't help: it records movements of refs only. Edits to files, staging and unstaging leave no entry. And it's local. No other clone and no server sees your reflog.

## MENTAL MODEL

**[ANIMATION]** stores: boxes=the_front_desk:index_cards_=_refs|the_ledger:old_box_numbers_=_the_reflog|the_vault:boxes_=_objects rows=1:A:a_card|1:C:the_box_it_names|2:B:a_ledger_line|2:C:a_box_only_the_ledger_names|3:C:a_box_nobody_mentions@ghost arrows=1:A1>C1:names|2:B1>C2:names title=A_bank_vault_with_a_ledger id=vault

The textbook's analogy for the layers is a bank vault with a ledger. The safe-deposit boxes are objects. The index cards at the front desk are refs: each card names one box. When a card is rewritten, the clerk notes the old box number in a ledger, the reflog. Boxes that no card and no ledger line mentions are emptied in a periodic clear-out, but only boxes that have been untouched for two weeks.

**[ANIMATION]** say: One_card_protects_a_whole_chain._The_ledger_is_private_to_one_branch_office

The analogy breaks in two places. A box in Git also holds the numbers of older boxes: a commit names its parents and its tree. So one card protects a whole chain. And the ledger is private to one branch office: no other clone, and no server, sees your reflog.

**[ANIMATION]** end

For the reflog alone, the textbook offers the "undo history" of an editor, kept per document. That breaks in two places too. A reflog has no undo command: it gives you old positions, and you decide what to do with them. And it records movements of refs only.

## DIAGRAM

**[ANIMATION]** layers: layers=1_refs:refs/heads/main_→_da62b60+index,_HEAD,_tags,_refs/stash|2_reflogs:HEAD@{1}_→_dbe6ec8+kept_while_the_entry_lives|3_the_grace_period:nothing_names_it+kept_until_a_collection_finds_it_older_than_the_cut-off|4_other_repositories:its_own_copy_of_the_objects+not_affected_by_this_one title=Four_layers_of_protection id=layers

**[DIAGRAM]** The picture of section 13.2. Draw one layer at a time, from the top.

```text
  layer 1   refs/heads/main ----------------> da62b60 --> parents, trees, blobs      kept
            index, HEAD, tags, refs/stash
  layer 2   reflog entry HEAD@{1} ----------> dbe6ec8 --> tree, blob                 kept while the entry lives
            (.git/logs/HEAD)
  layer 3   nothing ------------------------> a staged blob, a pruned fetch          kept until a collection
                                                                                     finds it older than the cut-off
  layer 4   another repository -------------> its own copy of the objects            not affected by this one
```

In layer one the branch names `da62b60`, and through it every parent, tree and blob. In layer two a reflog entry names `dbe6ec8`, a commit that was removed from its branch. In layer three nothing names the object at all. Layer four is outside this `.git`.

**[ANIMATION]** stores: boxes=.git/refs/heads/main:the_ref_itself|.git/logs/refs/heads/main:the_branch_reflog|.git/logs/HEAD:the_HEAD_reflog rows=1:A:da62b60|1:A:only_the_new_value@dim|2:B:f1f247e_da62b60|2:B:reset:_moving_to_HEAD~1|2:C:f1f247e_da62b60|2:C:reset:_moving_to_HEAD~1|3:B:main@{1}_=_f1f247e@ref|3:C:HEAD@{1}_=_f1f247e@ref mono=on title=One_command,_three_places_on_disk id=disk

**[DIAGRAM]** Then the picture of section 13.3: one command, three places on disk.

```text
  one command:  git reset --hard HEAD~1     (on main)
  .git/refs/heads/main      f1f247e  ->  da62b60          the ref itself: only the new value
  .git/logs/refs/heads/main f1f247e da62b60 ... reset: moving to HEAD~1     main@{0}, and main@{1} = f1f247e
  .git/logs/HEAD            f1f247e da62b60 ... reset: moving to HEAD~1     HEAD@{0}, and HEAD@{1} = f1f247e
```

The ref itself holds only the new value. Each of the two log files gains one line with the old value and the new one. A command that moves the current branch appends to both files.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/gc-ladder` and stop after the first snippet. A commit has been removed from its branch with `git reset --hard`. That command is 🔴 DANGEROUS, and it is not run on screen here; it has its own video. What you see is the state it left behind.

`git gc --prune=now` is also 🔴 DANGEROUS: a collection with no grace period at all. Before it runs, the five answers. What it changes: it packs objects and deletes unreachable ones immediately. What it can destroy: everything on layer three. How to preview: `git prune -n` lists what an immediate prune would delete. How to recover: from another repository only. When it's appropriate: you'll see in the last video of this module. Here the preview is the point.

```bash
git reflog -2
git prune -n
git gc --prune=now
git cat-file -t dbe6ec8
git count-objects -v | grep -e "^count" -e in-pack
```

**[ANIMATION]** graph: ...older-da62b60-dbe6ec8 main; HEAD=main; title:A_commit_removed_from_its_branch => ...older-da62b60 main; da62b60-dbe6ec8; reflog:dbe6ec8; HEAD=main; say:After_the_reset:_dbe6ec8_is_on_no_branch; name:reset => + dbe6ec8 HEAD@{1}; cmd:git_gc_--prune=now; say:HEAD@{1}_names_it:_layer_two; name:named id=lost

**[ANIMATION]** step: reset

Predict: the commit `dbe6ec8` is on no branch. Does it survive? Say it out loud. I'll wait.

**[PAUSE]**

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

It survives. `git prune -n` prints nothing: nothing would be deleted. After the collection, `git cat-file -t` still answers `commit`. All twelve objects were packed, the lost commit included.

**[ANIMATION]** step: lost.named

The reflog entry `HEAD@{1}` names it, so it's on layer two, and a reflog is a starting point for reachability.

**[TERMINAL]** Replay `labs/run ch13/reflog-anatomy`. A small history: a branch, a commit, an amend, a fast-forward merge, and a reset that takes the merge back.

<!-- snippet: ch13/reflog-anatomy/01-make-history -->
```text
$ git switch -c feature/rerank
Switched to a new branch 'feature/rerank'
$ printf 'def rerank(q, docs):\n    return sorted(docs)\n' > rerank.py
$ git add rerank.py
$ git commit -q -m "Add reranker"
$ git commit -q --amend -m "Add cross-encoder reranker"
$ git switch main
Switched to branch 'main'
$ git merge -q feature/rerank
$ git reset -q --hard HEAD~1
```
<!-- /snippet -->

**[ANIMATION]** graph: 538ea2f-536f5df-da62b60 main; HEAD=main; title:The_history_behind_the_reflog => + da62b60-14a18d6 feature/rerank; HEAD=feature/rerank; cmd:git_commit_-m_"Add_reranker"; name:commit => 538ea2f-536f5df-da62b60 main; da62b60-f1f247e feature/rerank; da62b60-14a18d6; reflog:14a18d6; HEAD=feature/rerank; cmd:git_commit_--amend; say:The_amend_replaces_14a18d6._Only_reflogs_name_it_now; name:amend => + f1f247e main; HEAD=main; cmd:git_merge_feature/rerank; say:A_fast-forward:_main_moves_to_f1f247e; name:merge => + da62b60 main; cmd:!git_reset_--hard_HEAD~1; say:The_reset_pulls_main_back_to_da62b60; name:reset => + f1f247e HEAD@{1}; 14a18d6 HEAD@{4}; cmd:git_rev-parse_--short_'HEAD@{1}'; say:Every_old_value_is_a_name_you_can_use; name:selectors id=hist

**[ANIMATION]** step: commit

Here's that history as a picture. One branch, `main`, with three commits. Then a second branch, `feature/rerank`, with one commit, `14a18d6`.

**[ANIMATION]** step: amend

The amend replaces that commit with `f1f247e`, and the old one turns dashed.

**[ANIMATION]** step: reset

`main` fast-forwards to `f1f247e`, and then the reset pulls it back to `da62b60`.

Try it now, on paper. Thirty seconds: write down how many lines the HEAD reflog will have, counting the three commits made before this snippet. Then say it out loud.

**[PAUSE]**

```bash
git reflog
```

<!-- snippet: ch13/reflog-anatomy/02-head-reflog -->
```text
$ git reflog
da62b60 HEAD@{0}: reset: moving to HEAD~1
f1f247e HEAD@{1}: merge feature/rerank: Fast-forward
da62b60 HEAD@{2}: checkout: moving from feature/rerank to main
f1f247e HEAD@{3}: commit (amend): Add cross-encoder reranker
14a18d6 HEAD@{4}: commit: Add reranker
da62b60 HEAD@{5}: checkout: moving from main to feature/rerank
da62b60 HEAD@{6}: commit: Raise top_k to 10
536f5df HEAD@{7}: commit: Add embedding client
538ea2f HEAD@{8}: commit (initial): Add retriever config
```
<!-- /snippet -->

Nine. Read it from the bottom. Each line is "the value HEAD had after this event". `HEAD@{0}` is always the current value. The amend at `HEAD@{3}` replaced `14a18d6` with `f1f247e`, and the old commit is still listed one line below. The two `checkout` lines record branch switches, which change HEAD and no branch.

```bash
git reflog show main
git reflog show feature/rerank
git reflog list
```

<!-- snippet: ch13/reflog-anatomy/03-branch-reflogs -->
```text
$ git reflog show main
da62b60 main@{0}: reset: moving to HEAD~1
f1f247e main@{1}: merge feature/rerank: Fast-forward
da62b60 main@{2}: commit: Raise top_k to 10
536f5df main@{3}: commit: Add embedding client
538ea2f main@{4}: commit (initial): Add retriever config
$ git reflog show feature/rerank
f1f247e feature/rerank@{0}: commit (amend): Add cross-encoder reranker
14a18d6 feature/rerank@{1}: commit: Add reranker
da62b60 feature/rerank@{2}: branch: Created from HEAD
$ git reflog list
HEAD
refs/heads/feature/rerank
refs/heads/main
```
<!-- /snippet -->

The reflog of `main` has five lines where HEAD has nine: the switches and the work on the other branch are absent. `git reflog list`, which needs Git 2.45 or later, names every ref that has a log.

**[ANIMATION]** step: hist.selectors

A reflog entry is addressed with a selector, and a selector is a revision, a way of naming a commit, that every command accepts.

```bash
git rev-parse --short 'HEAD@{1}'
git rev-parse --short 'main@{2}'
git rev-parse --short '@{1}'
git rev-parse --abbrev-ref '@{-1}'
git diff --stat 'main@{1}' main
```

<!-- snippet: ch13/reflog-anatomy/04-selectors -->
```text
# Position: the n-th previous value of HEAD, of a branch, of the current branch.
$ git rev-parse --short 'HEAD@{1}'
f1f247e
$ git rev-parse --short 'main@{2}'
da62b60
$ git rev-parse --short '@{1}'
f1f247e
# The n-th branch checked out before the current one.
$ git rev-parse --abbrev-ref '@{-1}'
feature/rerank
# A selector is a revision like any other.
$ git diff --stat 'main@{1}' main
 rerank.py | 2 --
 1 file changed, 2 deletions(-)
```
<!-- /snippet -->

`HEAD@{1}` is the value HEAD had one change ago. `@{1}` with no name is for the current branch, not for HEAD. `@{-1}` is different in kind: it's the branch that was checked out before the current one, a name and not a position. Quote selectors in the shell, because braces are special to some shells.

Time-based selectors read the timestamps in the log. Predict the last command: the log began on 7 September. What does "two days ago" return? Quick quiz, three options: an error, nothing at all, or the oldest value Git knows. Say it out loud.

**[PAUSE]**

```bash
git reflog --date=iso -4
git rev-parse --short 'main@{2026-09-07 10:10:30}'
git rev-parse --short 'HEAD@{5.minutes.ago}'
git rev-parse --short 'main@{2.days.ago}'
```

<!-- snippet: ch13/reflog-anatomy/05-time -->
```text
$ git reflog --date=iso -4
da62b60 HEAD@{2026-09-07 10:13:00 +0530}: reset: moving to HEAD~1
f1f247e HEAD@{2026-09-07 10:12:00 +0530}: merge feature/rerank: Fast-forward
da62b60 HEAD@{2026-09-07 10:11:00 +0530}: checkout: moving from feature/rerank to main
f1f247e HEAD@{2026-09-07 10:10:00 +0530}: commit (amend): Add cross-encoder reranker
$ git rev-parse --short 'main@{2026-09-07 10:10:30}'
da62b60
$ git rev-parse --short 'HEAD@{5.minutes.ago}'
da62b60
$ git rev-parse --short 'main@{2.days.ago}'
warning: log for 'main' only goes back to Mon, 7 Sep 2026 10:03:00 +0530
538ea2f
```
<!-- /snippet -->

At 10:10:30 `main` was still at `da62b60`, because the merge happened at 10:12. The last command asks for a time before the log begins. Option three: Git answers with the oldest value it knows, `538ea2f`, and says so in a warning. A time selector is a statement about your local log, never about the project. In a clone made today, `main@{1.week.ago}` can't know where `main` was a week ago.

`git log -g` walks a reflog instead of the ancestry, with placeholders for the reflog fields.

```bash
git log -g --format='%h %gd %gs' -4
git log -g --date=relative --format='%h %gd | %gn | %s' -3 main
git log -g --format='%h %gd %gs' --grep-reflog='^commit'
```

<!-- snippet: ch13/reflog-anatomy/06-log-g -->
```text
$ git log -g --format='%h %gd %gs' -4
da62b60 HEAD@{0} reset: moving to HEAD~1
f1f247e HEAD@{1} merge feature/rerank: Fast-forward
da62b60 HEAD@{2} checkout: moving from feature/rerank to main
f1f247e HEAD@{3} commit (amend): Add cross-encoder reranker
$ git log -g --date=relative --format='%h %gd | %gn | %s' -3 main
da62b60 main@{15 minutes ago} | Lab User | Raise top_k to 10
f1f247e main@{16 minutes ago} | Lab User | Add cross-encoder reranker
da62b60 main@{23 minutes ago} | Lab User | Raise top_k to 10
$ git log -g --format='%h %gd %gs' --grep-reflog='^commit'
f1f247e HEAD@{3} commit (amend): Add cross-encoder reranker
14a18d6 HEAD@{4} commit: Add reranker
da62b60 HEAD@{6} commit: Raise top_k to 10
536f5df HEAD@{7} commit: Add embedding client
538ea2f HEAD@{8} commit (initial): Add retriever config
```
<!-- /snippet -->

`%gd` is the selector, `%gs` the reflog message, `%gn` the name of the person who made the change. `--grep-reflog` filters by reflog message. The third command lists only the entries that created commits. That's how you search a long log for the event you need, instead of counting positions.

Last, the files.

```bash
tail -2 .git/logs/HEAD
tail -1 .git/logs/refs/heads/main
cat .git/refs/heads/main
```

<!-- snippet: ch13/reflog-anatomy/07-on-disk -->
```text
$ tail -2 .git/logs/HEAD
da62b6073a1d8c0afa10417bc244ed245ccdff86 f1f247eb281770cea385642df710bd095c262b17 Lab User <you@example.com> 1788756120 +0530	merge feature/rerank: Fast-forward
f1f247eb281770cea385642df710bd095c262b17 da62b6073a1d8c0afa10417bc244ed245ccdff86 Lab User <you@example.com> 1788756180 +0530	reset: moving to HEAD~1
$ tail -1 .git/logs/refs/heads/main
f1f247eb281770cea385642df710bd095c262b17 da62b6073a1d8c0afa10417bc244ed245ccdff86 Lab User <you@example.com> 1788756180 +0530	reset: moving to HEAD~1
$ cat .git/refs/heads/main
da62b6073a1d8c0afa10417bc244ed245ccdff86
```
<!-- /snippet -->

One event on the current branch is two lines, one in each file. The first ID of a line is the old value and the second the new one. That's more than `git reflog` prints, and it matters: the old value of the newest line tells you where a ref was even when no older line exists.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Looking in the reflog for an edit that was never committed.** Root cause: a reflog records movements of refs only; edits to files, staging and unstaging leave no entry.
2. **Counting positions in the HEAD reflog to find where a branch was.** Root cause: HEAD has one line per step, including every step of a rebase; the branch reflog has one line per operation.
3. **Writing `main@{1}` in an incident note.** Root cause: a selector is relative to the log at that moment; it means something else after the next command and nothing on a colleague's machine. Record the full ID.
4. **Asking a teammate or the server for "your reflog".** Root cause: reflogs are never pushed or cloned; each repository has its own.
5. **Trusting a time selector in a fresh clone.** Root cause: the log starts when the clone was made, and Git answers with the oldest value it knows, with a warning.

## PRODUCTION EXAMPLE

Back to 18:40 on release day. The first minute of a recovery is classification, not typing.

**[ANIMATION]** step: layers.4

**[ANIMATION]** say: Committed,_then_reset:_layer_two._Recoverable

You ask the engineer what form the work had. "Three days of commits on a feature branch, and I reset the branch" is layer two: the branch reflog has the old tip, and with default settings the entry for a commit off the current history lives for 30 days. You tell the CTO: recoverable, high confidence, weeks of margin, and nobody should run maintenance in that clone meanwhile.

**[ANIMATION]** say: Edited_and_never_staged:_never_an_object._No_layer_applies

A different answer changes everything. "I had edited the files since lunch and then ran `git restore`" was never an object. No layer applies. You move on to editor history and backups at once, and you say so, instead of spending an hour in `git fsck`.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Exercise 12.1, Level 1, "Read a reflog before you need it", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Work in `labs/shell`. Before you print any reflog, predict the number of lines in the HEAD reflog and in the branch reflog for the operations the exercise has you perform, and which lines will appear in one and not in the other.

The challenge is Exercise 12.4, Level 2, command prediction, "What the reflog will say", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q185: "How does the reflog help?"

Pause and answer out loud. It's a short question, and a short answer is a weak one.

**[PAUSE]**

**[ANIMATION]** step: hist.selectors

A strong answer defines the reflog by what it records and where it lives, then connects it to reachability: why an entry keeps a commit alive through a collection. It distinguishes the HEAD reflog from a branch reflog and says which one you read for which incident. It states the limits without being asked: local only, movements of refs only, entries that expire, and the cases in which there is no reflog. And it finishes with a concrete recovery in two steps: find the ID, then give it a name.

**[ANIMATION]** end

## RECAP

Let's land this. You should now be able to say:

- Work is protected by refs, then by reflogs, then by a grace period, then by other repositories; a recovery moves it back to a ref.
- Only work that became an object can be recovered from Git: committed, stashed, or staged.
- A reflog entry holds an old value, a new value, who, when and which command; every old value is a usable name.
- The HEAD reflog shows what I did in order; a branch reflog shows where that branch was.
- The reflog is local, and objects it names count as reachable.

## HOMEWORK

Read sections 13.1 to 13.3 of [Chapter 13](../../textbook/ch13-recovery.md).

**[ANIMATION]** step: layers.4

Today you got the map: four layers, one precondition, and a log of every move a ref made. Read a reflog in the lab shell before the next video. Next time: retention, `ORIG_HEAD`, and `git fsck` as a search tool. Until then, look at the state first and type second. See you in the next one.

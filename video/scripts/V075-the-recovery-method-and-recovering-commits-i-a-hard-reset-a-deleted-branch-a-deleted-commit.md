# V075: The recovery method, and recovering commits I: a hard reset, a deleted branch, a deleted commit

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 26
- **Prerequisites.** V074
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), section 13.7 and the first recoveries of section 13.8 (an accidental reset, a deleted branch, a deleted commit)
- **Demo scripts.** `labs/ch13/lab-12-1-hard-reset.sh`, `labs/ch13/lab-12-2-deleted-branch.sh`, `labs/ch13/lab-12-3-deleted-commit.sh`

## HOOK

**[ON SCREEN]** `git reset --hard HEAD~3`

The plan was to drop the last commit, the last saved snapshot on the branch. A hard reset moves the branch back and overwrites your files. The typo was a 3 where a 1 was meant. Three commits and their changes are gone from the branch and from the working tree.

What the engineer does in the next sixty seconds decides the outcome. One option is to search the web, find a command that "cleans up the repository", and run it. Another is to delete the directory and clone again. Both destroy the thing that would have saved the work: the first removes the evidence, and the second produces a clone with no reflog, Git's local log of where each name has pointed, and none of the unpushed objects. The textbook calls re-cloning "the classic non-fix".

The correct first step is one word. Stop. Keep those three commits in mind.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last two videos you learned what Git keeps and for how long. Today that knowledge becomes a procedure of eight steps, and you apply it three times: to a hard reset, to a deleted branch, and to a commit that vanished from the middle of a branch.

This is the guided pass. For each incident I read the symptom, ask the three questions, show the evidence command, then the anchor, then the repair. In the labs you repeat all three from the symptoms alone.

The curriculum summary for this video describes the method in five words: stop, don't run maintenance, find the ID, anchor, repair. The textbook's section 13.7 has eight numbered steps, and that is the version you get here.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- ask the three questions that come before any recovery command;
- recover the commits lost to `git reset --hard`;
- recreate a deleted branch at its last tip, with and without its reflog;
- bring back a commit dropped from history;
- anchor every recovered commit with a ref before doing anything else.

## CONCEPT

The three questions come from the first page of the chapter. Was the work ever written into the object database? Does anything still name it? Has the clock run out? The first answer decides whether Git can help at all. The second tells you the layer. The third tells you the deadline.

Then the method. Every recovery follows the same eight steps.

**[ON SCREEN]** The eight steps of section 13.7, one at a time.

**[ANIMATION]** cards: cards=Stop:waiting_loses_nothing|Record:symptom,_last_commands|Classify:which_form_of_work?|Find_the_ID:scrollback_first|Anchor_it:git_branch_rescue/<what>_<id>|Inspect:before_you_move_anything|Integrate:the_lowest-risk_move|Verify:then_clean_up numbered=on marks=5:ring id=method

**[ANIMATION]** step: 1

One. **Stop.** Don't run another command that moves refs or deletes files, and don't run `git gc`, `git prune`, `git clean` or `git stash clear`. Waiting loses nothing. A second "fix" can.

**[ANIMATION]** step: 2

Two. **Record the symptom and the last commands.** Copy the terminal scrollback if you have it. Git prints the ID you need in more places than people remember: "Deleted branch x (was ...)", "Dropped refs/stash@{0}", "HEAD is now at", the warning on leaving detached HEAD, when you are on no branch.

**[ANIMATION]** step: 3

Three. **Classify.** Was the work committed, stashed, staged, or only saved? That decides the layer, and whether to continue with Git at all.

**[ANIMATION]** step: 4

Four. **Find the ID.** From the scrollback, the branch reflog, the HEAD reflog, `ORIG_HEAD`, `git fsck`, or another repository, in that order.

**[ANIMATION]** step: 5

Five. **Anchor it.** `git branch rescue/<what> <id>`. A branch is a name for a commit, and an anchored commit can't expire.

**[ANIMATION]** step: 6

Six. **Inspect before you move anything.** `git log`, `git show --stat`, `git diff`, `git range-diff`, `git cherry` against the anchor.

**[ANIMATION]** step: 7

Seven. **Integrate with the lowest-risk move.** Prefer adding, a branch, a cherry-pick or a merge, over rewinding. And prefer `git reset --keep` over `git reset --hard`.

**[ANIMATION]** step: 8

Eight. **Verify, then clean up.** Prove that the result holds what was lost, and only then delete the rescue branch.

**[ANIMATION]** step: marks

Why is the anchor a separate step, before any repair? Because of what it costs and what it buys. 🟢 SAFE: `git branch rescue/x <id>` leaves the working tree, the index, HEAD and the current branch unchanged. It adds one ref with a new reflog. In exchange, the commit moves from layer two or three to layer one, and no expiry or collection can touch it. After that, every repair you attempt is reversible.

**[ANIMATION]** end

When not to follow the method to its end, from section 13.17. Don't recover a secret: if the "lost" commit contains a credential, restoring it puts the credential back on a branch, so rotate first. Don't rewind shared history to recover: on a branch that others have pulled, add commits. And recovered isn't verified: a branch that points at the right commit proves nothing about the working tree you now have. Run the tests.

## MENTAL MODEL

**[ANIMATION]** stores: boxes=the_front_desk:index_cards_=_refs|the_ledger:the_reflog|the_vault:boxes_=_commits rows=1:C:the_box_never_left|2:A:the_card_was_lost@bad|3:B:the_old_box_number@ok arrows=3:B1>C1:finds_it title=What_was_lost_was_the_card id=card

Think of a recovery as moving a box in the vault back under an index card. In all the accidents of today, the box never left the vault. The commit never stopped existing. What was lost was the card: the ref that named it.

**[ANIMATION]** say: A_ref_is_pointed_at_a_commit_that_never_stopped_existing

So every one of these recoveries ends with the same act: a ref is pointed at a commit that never stopped existing. The hard part isn't the repair. It's finding the right box number, and not ordering a clear-out while you search.

**[ANIMATION]** end

Where this picture breaks: it covers committed work only. Uncommitted work that a hard reset overwrote was never in a box, or was a single blob without a card. That's a different video.

## DIAGRAM

**[DIAGRAM]** The decision flow of section 13.7: where to look. Reveal it branch by branch, and for each branch name the layer.

```text
  Was the lost work ever committed, stashed, or staged with "git add"?
   |
   +-- no ----> Git has no object. Editor history, IDE local history, backups, Time Machine.   (13.12)
   |
   +-- staged only ----> git fsck --lost-found ; look in .git/lost-found/other                  (13.9)
   |
   +-- stashed, then dropped or cleared ----> git fsck --unreachable | ... git log --merges     (13.9)
   |
   +-- committed
        |
        +-- Do you have the ID (scrollback, CI log, pull request, chat)? -- yes --> git branch rescue <id>
        |
        +-- Did a branch move (reset, rebase, merge, amend, cherry-pick)?
        |      --> git reflog show <branch> ; take the entry below the bad operation            (13.8)
        |
        +-- Is the branch itself gone, or was the work done in detached HEAD?
        |      --> git reflog (HEAD) ; or git fsck --no-reflogs for the dangling tips           (13.8)
        |
        +-- Did the server lose it (force push, deleted remote branch)?
        |      --> git reflog show origin/<branch> ; a teammate's clone ; the host's tools      (13.10, 13.15)
        |
        +-- No reflog entry anywhere (pruned fetch, expired log, other machine)?
               --> git fsck --lost-found ; then another clone, a bundle, a backup               (13.6, 13.14)
```

Today's three incidents are three branches of the "committed" subtree. Try it now, thirty seconds: point at the branch of this tree for each of the three. Then say your answer.

**[PAUSE]**

The hard reset: a branch moved. The deleted branch: the branch itself is gone. The dropped commit: a branch moved, through a rebase.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/lab-12-1-hard-reset`. First incident.

**[ON SCREEN]** 🔴 DANGEROUS: `git reset --hard <id>`. The five answers, from the safety table. What it changes: it moves the branch and overwrites the index and the working tree. What it can destroy: unstaged work, for good. How to preview: `git status`, and `git stash -u` first if there is anything uncommitted. How to recover: commits through the reflog; staged work through `git fsck --lost-found`; unstaged work, none. When it is appropriate: when the working tree is clean and you mean to move the branch.

```bash
git reset --hard HEAD~3
git log --oneline
cat config.yaml
```

<!-- snippet: ch13/lab-12-1-hard-reset/02-disaster -->
```text
# The plan: drop the last commit. The typo: 3 instead of 1.
$ git reset --hard HEAD~3
HEAD is now at 798cb66 Add recall@k evaluation
$ git log --oneline
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
$ cat config.yaml
top_k: 5
```
<!-- /snippet -->

"HEAD is now at 798cb66". Three commits shorter.

**[ANIMATION]** graph: 7525edc-8d2e200-798cb66-13ed88d-3106f68-495f3a9 main; HEAD=main; title:First_incident:_a_hard_reset => + 798cb66 main; reflog:13ed88d,3106f68,495f3a9; cmd:!git_reset_--hard_HEAD~3; say:Three_commits_shorter._The_commits_still_exist; name:typo => + 495f3a9 ORIG_HEAD HEAD@{1} main@{1}; cmd:git_reflog_-3; say:Three_names,_one_commit:_495f3a9; name:evidence => + drop:HEAD@{1},main@{1}; 495f3a9 rescue/before-reset; cmd:git_branch_rescue/before-reset_ORIG__HEAD; say:Anchored:_layer_one_again; name:anchor => 7525edc-8d2e200-798cb66-13ed88d-3106f68-495f3a9 main rescue/before-reset; 798cb66 ORIG_HEAD; HEAD=main; cmd:!git_reset_--hard_rescue/before-reset; say:This_reset_wrote_ORIG__HEAD_again:_it_now_holds_798cb66; name:back id=reset

**[ANIMATION]** step: typo

Stop, and ask the three questions. Was the work an object? Yes, three commits. On the picture they turn dashed, and they still exist. Does anything name it? Predict which three places. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git reflog -3
git log --oneline -1 ORIG_HEAD
git reflog show main -2
```

<!-- snippet: ch13/lab-12-1-hard-reset/03-evidence -->
```text
$ git reflog -3
798cb66 HEAD@{0}: reset: moving to HEAD~3
495f3a9 HEAD@{1}: commit: WIP: debug prints
3106f68 HEAD@{2}: commit: Normalise queries before search
$ git log --oneline -1 ORIG_HEAD
495f3a9 WIP: debug prints
$ git reflog show main -2
798cb66 main@{0}: reset: moving to HEAD~3
495f3a9 main@{1}: commit: WIP: debug prints
```
<!-- /snippet -->

The HEAD reflog, `ORIG_HEAD` and the branch reflog, and they agree: the old tip is `495f3a9`.

**[ANIMATION]** step: reset.evidence

`ORIG_HEAD` is safe to use here, because `git reset` wrote it and nothing has run since. Anchor, look, move.

```bash
git branch rescue/before-reset ORIG_HEAD
git log --oneline rescue/before-reset
git reset --hard rescue/before-reset
git log --oneline -3
```

<!-- snippet: ch13/lab-12-1-hard-reset/04-recover -->
```text
$ git branch rescue/before-reset ORIG_HEAD
$ git log --oneline rescue/before-reset
495f3a9 WIP: debug prints
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
$ git reset --hard rescue/before-reset
HEAD is now at 495f3a9 WIP: debug prints
$ git log --oneline -3
495f3a9 WIP: debug prints
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
$ cat config.yaml
top_k: 10
```
<!-- /snippet -->

**[ANIMATION]** step: reset.back

The rescue branch lists all six commits. The branch is back at `495f3a9`. `ORIG_HEAD` moves as well, because this reset wrote it again. The lost commits were on layer two, the reflogs, for the whole time. Those are the three commits from the opening.

**[ANIMATION]** end

The usual complication, said now so that you recognise it in the lab: if you committed new work on the shortened branch before you noticed, a reset back to the old tip trades one loss for another. Anchor both tips, reset to the one you want as the base, and cherry-pick the commits from the other.

The same slip without `--hard` is milder.

```bash
git reset HEAD~2
git log --oneline -1
git status -s
cat config.yaml
git reset 'HEAD@{1}'
git status -s
```

<!-- snippet: ch13/lab-12-1-hard-reset/06-mixed -->
```text
# The same slip without --hard: the branch moves, the files do not.
$ git reset HEAD~2
Unstaged changes after reset:
M	config.yaml
M	retriever.py
$ git log --oneline -1
798cb66 Add recall@k evaluation
$ git status -s
 M config.yaml
 M retriever.py
$ cat config.yaml
top_k: 10
$ git reset 'HEAD@{1}'
$ git status -s
$ git log --oneline -1
3106f68 Normalise queries before search
```
<!-- /snippet -->

A mixed reset moves the branch and the index and leaves the working tree alone. The content of the two "missing" commits is still in your files, shown as modifications. A second mixed reset to `HEAD@{1}` puts the branch and the index back, and the status is clean.

**[TERMINAL]** Replay `labs/run ch13/lab-12-2-deleted-branch`. Second incident.

```bash
git branch -d feature/cross-encoder
git branch -D feature/cross-encoder
git branch
git log --oneline --graph --all
```

<!-- snippet: ch13/lab-12-2-deleted-branch/02-disaster -->
```text
$ git branch -d feature/cross-encoder
error: the branch 'feature/cross-encoder' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/cross-encoder'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git branch -D feature/cross-encoder
Deleted branch feature/cross-encoder (was 2f65488).
$ git branch
* main
$ git log --oneline --graph --all
* 6f16e54 Document the pipeline stages
| * 60184f9 Deduplicate mined negatives
| * 0cea4ee Mine hard negatives from click logs
|/  
* 0875e65 Add pipeline config
* f9b487c Add retrieval pipeline
```
<!-- /snippet -->

Git refused the safe form, `-d`, because the branch was "not fully merged". That refusal is the first safety net. `-D` skips the check. It is 🔴 DANGEROUS, because it deletes the ref together with its reflog. It also prints the one fact you need: "(was 2f65488)". Step two of the method: copy the scrollback.

**[ANIMATION]** graph: f9b487c-0875e65-6f16e54 main; 0875e65-7e43259-405080d-2f65488 feature/cross-encoder; ^0875e65-0cea4ee-60184f9 origin/exp/hard-negatives; HEAD=main; title:Second_incident:_a_deleted_branch => + drop:feature/cross-encoder; reflog:7e43259,405080d,2f65488; cmd:!git_branch_-D_feature/cross-encoder; say:Deleted_branch_feature/cross-encoder_(was_2f65488); name:deleted => f9b487c-0875e65-6f16e54 main; 0875e65-7e43259-405080d-2f65488 feature/cross-encoder; ^0875e65-0cea4ee-60184f9 origin/exp/hard-negatives; HEAD=main; cmd:git_branch_feature/cross-encoder_2f65488; say:A_branch_is_a_ref:_recreate_the_ref; name:recreated => f9b487c-0875e65-6f16e54 main; 0875e65-7e43259-405080d-2f65488 feature/cross-encoder; ^0875e65-0cea4ee-60184f9; ghost:0cea4ee,60184f9; HEAD=main; cmd:git_fetch_--prune; say:No_ref_and_no_reflog_entry_names_these_two; name:pruned => f9b487c-0875e65-6f16e54 main; 0875e65-7e43259-405080d-2f65488 feature/cross-encoder; ^0875e65-0cea4ee-60184f9 exp/hard-negatives origin/exp/hard-negatives; HEAD=main; cmd:git_push_-u_origin_exp/hard-negatives; say:Anchored,_and_pushed; name:anchored id=branch

**[ANIMATION]** step: deleted

On the picture, the label is gone and three commits have no name. A branch is a ref, so recreating the ref recreates the branch.

```bash
git branch feature/cross-encoder 2f65488
git log --oneline main..feature/cross-encoder
git reflog show feature/cross-encoder
```

Predict: how many lines will the reflog of the recreated branch have?

<!-- snippet: ch13/lab-12-2-deleted-branch/04-recover -->
```text
$ git branch feature/cross-encoder 2f65488
$ git log --oneline main..feature/cross-encoder
2f65488 Cache reranker scores
405080d Rerank the top 50 candidates
7e43259 Add cross-encoder reranker
$ git reflog show feature/cross-encoder
2f65488 feature/cross-encoder@{0}: branch: Created from 2f65488
```
<!-- /snippet -->

The three commits are back. The reflog isn't: it has one line, "branch: Created from 2f65488". The record of how the branch moved over its life was deleted with it and can't be restored.

**[ANIMATION]** step: branch.recreated

On the picture, the label is back, and the chain is solid again.

And without the printed ID? The branch reflog is gone, so ask the HEAD reflog.

```bash
git reflog show feature/cross-encoder
git reflog -6
```

<!-- snippet: ch13/lab-12-2-deleted-branch/03-evidence -->
```text
$ git reflog show feature/cross-encoder
fatal: ambiguous argument 'feature/cross-encoder': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog -6
6f16e54 HEAD@{0}: commit: Document the pipeline stages
0875e65 HEAD@{1}: checkout: moving from feature/cross-encoder to main
2f65488 HEAD@{2}: commit: Cache reranker scores
405080d HEAD@{3}: commit: Rerank the top 50 candidates
7e43259 HEAD@{4}: commit: Add cross-encoder reranker
0875e65 HEAD@{5}: checkout: moving from main to feature/cross-encoder
```
<!-- /snippet -->

"checkout: moving from feature/cross-encoder to main" records where HEAD went. The entry below it, `HEAD@{2}`, is the last thing HEAD pointed at while it was on the branch. That's the tip, unless the branch was moved afterwards without being checked out. In a long reflog, search for the message instead of counting.

```bash
git log -g --format='%h %gd %gs' --grep-reflog='moving from feature/cross-encoder'
git log --oneline -1 'HEAD@{2}'
```

<!-- snippet: ch13/lab-12-2-deleted-branch/05-from-the-reflog -->
```text
# Without the "Deleted branch" line: the last entry that left the branch is in the HEAD reflog.
$ git log -g --format='%h %gd %gs' --grep-reflog='moving from feature/cross-encoder'
0875e65 HEAD@{1} checkout: moving from feature/cross-encoder to main
# That entry records where HEAD went. The entry below it records where the branch was.
$ git log --oneline -1 'HEAD@{2}'
2f65488 Cache reranker scores
```
<!-- /snippet -->

Now the hard variant: no reflog knows the commits. A teammate's branch that you fetched and never checked out is held by a remote-tracking ref only, your record of a branch on the server.

**[ON SCREEN]** 🟡 CAUTION: `git fetch --prune`. It deletes stale remote-tracking refs and their reflogs. Preview: `git remote prune --dry-run <remote>`.

```bash
git branch -r
git log --oneline -2 origin/exp/hard-negatives
git fetch --prune
git branch -r
git reflog show origin/exp/hard-negatives
```

<!-- snippet: ch13/lab-12-2-deleted-branch/06-failure -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/exp/hard-negatives
  origin/main
$ git log --oneline -2 origin/exp/hard-negatives
60184f9 Deduplicate mined negatives
0cea4ee Mine hard negatives from click logs
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/exp/hard-negatives
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git reflog show origin/exp/hard-negatives
fatal: ambiguous argument 'origin/exp/hard-negatives': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog | grep -c negatives
0
```
<!-- /snippet -->

Git printed "(none)" where a local deletion prints the old ID.

**[ANIMATION]** step: branch.pruned

The commits are on layer three now. Quick quiz, two options. Does plain `git fsck`, without `--no-reflogs`, find them: yes, or no? Say it out loud.

**[PAUSE]**

```bash
git fsck
git fsck --lost-found
git log --format='%h %an, %ad%n        %s' --date=short $(cat .git/lost-found/commit/*) --not --all
```

<!-- snippet: ch13/lab-12-2-deleted-branch/07-recovery-find -->
```text
$ git fsck
dangling commit 60184f9abb50a1f151181c08df375e5274ead3c6
$ git fsck --lost-found
dangling commit 60184f9abb50a1f151181c08df375e5274ead3c6
$ git log --format='%h %an, %ad%n        %s' --date=short $(cat .git/lost-found/commit/*) --not --all
60184f9 Asha Rao, 2026-09-07
        Deduplicate mined negatives
0cea4ee Asha Rao, 2026-09-07
        Mine hard negatives from click logs
```
<!-- /snippet -->

Yes, without any option, because no reflog entry competes. `--not --all` limits the listing to commits that no ref reaches, which is the lost work and nothing else.

```bash
git branch exp/hard-negatives $(cat .git/lost-found/commit/*)
git log --oneline main..exp/hard-negatives
git push -u origin exp/hard-negatives
```

<!-- snippet: ch13/lab-12-2-deleted-branch/08-recovery-anchor -->
```text
$ git branch exp/hard-negatives $(cat .git/lost-found/commit/*)
$ git log --oneline main..exp/hard-negatives
60184f9 Deduplicate mined negatives
0cea4ee Mine hard negatives from click logs
$ git push -u origin exp/hard-negatives
To ../server.git
 * [new branch]      exp/hard-negatives -> exp/hard-negatives
branch 'exp/hard-negatives' set up to track 'origin/exp/hard-negatives'.
```
<!-- /snippet -->

**[ANIMATION]** step: branch.anchored

Anchored, and pushed, which puts it on layer four as well. In a repository with default settings this rescue has a deadline: the grace period, counted from the day the objects were written into your repository, and then the next collection.

**[TERMINAL]** Replay `labs/run ch13/lab-12-3-deleted-commit`. Third incident. A commit that you remember is not in the branch, and the setting it introduced is not in the file. The branch has newer commits, so the loss is not recent.

```bash
git log --oneline main..feature/batching
cat client.yaml
git log --oneline --all -- client.yaml
```

<!-- snippet: ch13/lab-12-3-deleted-commit/01-symptom -->
```text
$ cd embedder
$ git log --oneline main..feature/batching
a7061c1 Document batching in the README
0309a41 Log batch sizes
285e3af Retry on rate limit
696a15f Batch embedding requests
$ cat client.yaml
model: embed-small-v2
$ git log --oneline --all -- client.yaml
f7736c7 Add client config
```
<!-- /snippet -->

`git log --all` knows one commit for that file. The timeout commit is on no branch. Commits leave a branch through three commands: `git reset`, `git rebase`, and `git commit --amend`. The reflog of the branch says which one ran.

```bash
git reflog show feature/batching
```

<!-- snippet: ch13/lab-12-3-deleted-commit/02-evidence -->
```text
$ git reflog show feature/batching
a7061c1 feature/batching@{0}: commit: Document batching in the README
0309a41 feature/batching@{1}: rebase (finish): refs/heads/feature/batching onto f7736c7d7ea7d8c345ef1888de925509d5117e39
76a49ed feature/batching@{2}: commit: Log batch sizes
f35b47a feature/batching@{3}: commit: Retry on rate limit
2ebd700 feature/batching@{4}: commit: Add request timeout
696a15f feature/batching@{5}: commit: Batch embedding requests
f7736c7 feature/batching@{6}: branch: Created from HEAD
```
<!-- /snippet -->

One "rebase (finish)" line, with the old tip `76a49ed` directly below it and the lost commit `2ebd700` two lines further down. Anchor the old tip, and compare by content. `git cherry` marks with a plus the commits whose change has no equivalent on the other side.

**[ANIMATION]** graph: f7736c7-696a15f-2ebd700-f35b47a-76a49ed feature/batching; HEAD=feature/batching; title:Third_incident:_a_commit_dropped_by_a_rebase => f7736c7-696a15f-285e3af-0309a41 feature/batching; ^696a15f-2ebd700-f35b47a-76a49ed; reflog:2ebd700,f35b47a,76a49ed; HEAD=feature/batching; cmd:git_rebase; say:The_rebase_rebuilt_two_commits_and_left_one_out; name:rebase => + 0309a41-a7061c1 feature/batching; cmd:git_commit; say:Then_one_new_commit_on_top; name:commit => f7736c7-696a15f-285e3af-0309a41-a7061c1 feature/batching; ^696a15f-2ebd700-f35b47a-76a49ed rescue/before-rebase; HEAD=feature/batching; mark:+:2ebd700; mark:−:f35b47a,76a49ed; cmd:git_cherry_-v_feature/batching_rescue/before-rebase; say:Plus:_no_equivalent_on_the_other_side; name:anchor => + a7061c1-ff46c25 feature/batching; cmd:git_cherry-pick_2ebd700; say:The_change_is_copied_forward_as_ff46c25; name:pick id=dropped

**[ANIMATION]** step: commit

Here's what that reflog describes. A branch of four commits. Then a rebase, which copies commits: it rebuilt two and left one out. Then one new commit on top. The old ones turn dashed, `2ebd700` among them.

```bash
git branch rescue/before-rebase 'feature/batching@{2}'
git log --oneline main..rescue/before-rebase
git cherry -v feature/batching rescue/before-rebase
```

<!-- snippet: ch13/lab-12-3-deleted-commit/03-compare -->
```text
# Anchor the tip from before the rebase, then ask what the rebase left out:
$ git branch rescue/before-rebase 'feature/batching@{2}'
$ git log --oneline main..rescue/before-rebase
76a49ed Log batch sizes
f35b47a Retry on rate limit
2ebd700 Add request timeout
696a15f Batch embedding requests
$ git cherry -v feature/batching rescue/before-rebase
+ 2ebd700e9eb436ad1c04d80c284f18f294fc5011 Add request timeout
- f35b47a4e60533a59aba361e16d42aa94602ee05 Retry on rate limit
- 76a49edc7fb8cf1ba56ecdc367f05eb1dae9ec89 Log batch sizes
```
<!-- /snippet -->

Two commits were rebuilt with new IDs and the same change: minus. One was left out: plus.

**[ANIMATION]** step: dropped.anchor

**[PAUSE]** Which repair? You could reset the branch to the rescue branch. Look at the reflog again before you answer: a commit was added after the rebase. A reset would lose it. Step seven says prefer adding over rewinding.

**[ON SCREEN]** 🟡 CAUTION: `git cherry-pick <id>`. A new commit on the current branch. Preview: `git show --stat <id>`. Recovery: `--abort`, or the branch reflog.

```bash
git show --stat --format='%h %s' 2ebd700
git cherry-pick 2ebd700
cat client.yaml
```

<!-- snippet: ch13/lab-12-3-deleted-commit/04-recover -->
```text
$ git show --stat --format='%h %s' 2ebd700
2ebd700 Add request timeout

 client.yaml | 1 +
 1 file changed, 1 insertion(+)
$ git cherry-pick 2ebd700
[feature/batching ff46c25] Add request timeout
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+)
$ cat client.yaml
model: embed-small-v2
timeout_s: 10
```
<!-- /snippet -->

**[ANIMATION]** step: dropped.pick

The setting is back, as a new commit on top, and nothing after the rebase was disturbed. A cherry-pick copied the change forward.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Running a clean-up command during the incident.** Root cause: `git gc`, `git prune`, `git stash clear` and `git reflog expire` remove the names and objects that the recovery depends on.
2. **Deleting the repository and cloning again.** Root cause: reflogs are local and start with the clone, and the clone has none of the unpushed objects.
3. **Using `HEAD@{1}` some commands later.** Root cause: any later movement, even a switch, shifts the positions; search with `--grep-reflog` and use the full ID.
4. **Repairing before anchoring.** Root cause: a found commit is still unreachable from refs; until a branch names it, a failed repair or an expiry can lose it again.
5. **Resetting a branch back to recover one commit.** Root cause: the reset discards commits made since; copy the missing commit forward instead.

## PRODUCTION EXAMPLE

Now, out of the lab. A search team keeps an experiment branch on the server for hard-negative mining. Its author deletes it after the experiment is written up. A week later a colleague needs two of its commits for a new training run. He had fetched the branch and never checked it out, and his nightly fetch runs with pruning.

**[ANIMATION]** step: branch.anchored

**[ANIMATION]** say: In_the_lab:_the_same_rescue,_for_exp/hard-negatives

He classifies first: committed work, no ref, no reflog entry in his clone, so layer three, with a deadline. He doesn't run anything that might trigger a collection. `git fsck --lost-found` gives one dangling commit. A log of that tip with `--not --all` shows exactly the two commits and their author. He anchors the tip, pushes the branch so that a second repository holds it, and only then tells the author that the experiment is back under a new branch name. The incident note gives the full commit ID, not a selector.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Lab 12.1, "An accidental hard reset", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

Work from the symptom only. Before you run an evidence command, write down the answers to the three questions and name the three places that should hold the old tip. In the lab's failure scenario, new work has been committed on the shortened branch. Predict what a plain reset to the old tip would cost before you choose the repair.

The challenge is Lab 12.2, "A deleted branch", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q188: "Someone lost work. Which three questions do you ask before you type anything, and what does each answer rule in or out?"

Pause and answer out loud.

**[PAUSE]**

**[ANIMATION]** step: method.marks

A strong answer gives the three questions in an order that narrows the search, and for each one says what a "no" means in practice. It ties the answers to the four layers by name. It mentions the instruction that precedes all three: what the person must not run while you think. And it ends with what you'll say to the person who asked, in terms of confidence and deadline, not in terms of commands.

**[ANIMATION]** end

## RECAP

Let's land this. You should now be able to say:

- Before any command I ask: was it an object, does anything name it, has the clock run out.
- The method is stop, record, classify, find the ID, anchor, inspect, integrate with the lowest-risk move, verify.
- After a hard reset the old tip is in the branch reflog, the HEAD reflog and `ORIG_HEAD`.
- A deleted branch is recreated at its tip; its own reflog is gone for good.
- A commit dropped by a rebase is copied forward with a cherry-pick, not recovered by rewinding.

## HOMEWORK

Read section 13.7 and the first three recoveries of section 13.8 in [Chapter 13](../../textbook/ch13-recovery.md). Do Lab 12.3, "A deleted commit", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md).

**[ANIMATION]** step: method.marks

Today you brought back commits three times with one method. Do the hard reset lab from the symptom alone before the next video. Next time: five more recoveries, from a wrong rebase to a wrong cherry-pick. Until then, look at the state first and type second. See you in the next one.

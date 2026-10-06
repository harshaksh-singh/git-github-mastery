# Module 12 labs: Recovery and disaster recovery

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch13/`. Read [Chapter 13: Recovery](../textbook/ch13-recovery.md) first.

## How to run these labs

Each lab has a setup script that builds a disaster, or the moment before one, in the hands-on sandbox, and a replay script that runs the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch13/setup-12-1-hard-reset.sh      # build the starting state (run again to start over)
labs/shell m12-1                             # open the isolated lab shell in that sandbox
labs/run ch13/lab-12-1-hard-reset            # optional: replay the whole lab and print its transcript
```

**Do every lab twice.** The first time, follow the guide and predict each output before you run the command. Then run the setup script again and work from the symptom card alone, with the guide closed, using the method of Chapter 13, section 13.7: stop, record, classify, find the ID, anchor, inspect, integrate, verify. The second pass is the one that prepares you for a real incident.

| Lab | Sandbox | Replay | Symptom card for the second pass |
|---|---|---|---|
| 12.1 | `m12-1` | `ch13/lab-12-1-hard-reset` | "I wanted to drop my last commit and now three are gone." |
| 12.2 | `m12-2` | `ch13/lab-12-2-deleted-branch` | "I force-deleted the reranker branch. It was not merged." |
| 12.3 | `m12-3` | `ch13/lab-12-3-deleted-commit` | "The request timeout is not in the config any more. I added it last week." |
| 12.4 | `m12-4` | `ch13/lab-12-4-wrong-rebase` | "My hotfix pull request against release/1.4 shows six commits. I wrote three." |
| 12.5 | `m12-5` | `ch13/lab-12-5-bad-merge` | "I merged the wrong branch into main. Nothing is pushed." |
| 12.6 | `m12-6` | `ch13/lab-12-6-wrong-branch` | "My last two commits are on main. They belong on the feature branch." |
| 12.7 | `m12-7` | `ch13/lab-12-7-detached-head` | "I fixed two things on top of v1.2.0 a few days ago. I cannot find the commits." |
| 12.8 | `m12-8` | `ch13/lab-12-8-overwritten-changes` | "I ran a hard reset and my sweep file is gone. It was never committed." |
| 12.9 | `m12-9` | `ch13/lab-12-9-wrong-cherry-pick` | "The backport on release/2.1 contains a feature instead of the fix." |
| 12.10 | `m12-10` | `ch13/lab-12-10-remote-tracking` | "Status says I am in sync, push is rejected, and fetch dies with 'bad object'." |
| 12.11 | `m12-11` | `ch13/lab-12-11-force-push` | "After a fetch, main is 'ahead 2, behind 1'. I have not committed anything today." |
| 12.12 | `m12-12` | `ch13/lab-12-12-point-of-no-return` | "Prove to me that the commit is gone for good, and then get it back anyway." |

**Which IDs will match the book.** The setup scripts create their commits with the same fixed clock as the replays, so every commit, stash entry and reflog entry that exists when you enter the sandbox has the ID printed in this manual. Commits you create yourself (a cherry-pick, a merge, a rebased commit) get the real time and therefore other IDs. Blob IDs depend only on content and always match.

**The lab clock and reflog expiry.** The commits in these sandboxes are dated 7 September 2026. The sandbox configuration sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never`, so their reflog entries do not age out, whatever day you run a lab. Real repositories use the defaults of 90 and 30 days (Chapter 13, section 13.4). The only expiry you will perform here is explicit: `--expire=now` and `--prune=now` in Lab 12.12.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from a script, not output of Git.
- Merges do not open an editor in the lab shell, because the lab environment sets `GIT_MERGE_AUTOEDIT=no`. In your own shell they do.

Answers to the Questions of every lab are in [solutions/m12-lab-answers.md](../solutions/m12-lab-answers.md). Write your own answers first.

## Lab 12.1: An accidental hard reset

### Objective

Lose three commits to a mistyped `git reset --hard`, find the old tip in three places, and restore the branch through an anchor. See why the same slip without `--hard` loses nothing. Then face the realistic version, in which work was committed after the bad reset.

### Prerequisites

- Chapter 13, sections 13.3, 13.5 and 13.7.
- Chapter 11, section 11.4, for the reset modes.

### Setup

```bash
bash labs/ch13/setup-12-1-hard-reset.sh
labs/shell m12-1
```

The script builds `retriever`, six commits on `main` of which the last is a throwaway, and `retriever-incident` for the failure scenario: the same repository after a bad reset and one new commit.

### Commands

Step 1. Look at the branch. The plan is to drop the last commit.

```bash
cd retriever
git log --oneline
git status -s
```

Step 2. The slip: `3` where you meant `1`.

```bash
git reset --hard HEAD~3
git log --oneline
cat config.yaml
```

Step 3. Stop. Collect the evidence before you change anything.

```bash
git reflog -3
git log --oneline -1 ORIG_HEAD
git reflog show main -2
```

Step 4. Anchor the old tip, inspect it, and move the branch back.

```bash
git branch rescue/before-reset ORIG_HEAD
git log --oneline rescue/before-reset
git reset --hard rescue/before-reset
git log --oneline -3
cat config.yaml
```

Step 5. Now do what you intended, and remove the anchor.

```bash
git reset --hard HEAD~1
git log --oneline -3
git branch -D rescue/before-reset
```

Step 6. The same kind of slip without `--hard`.

```bash
git reset HEAD~2
git log --oneline -1
git status -s
cat config.yaml
git reset 'HEAD@{1}'
git status -s
git log --oneline -1
```

### Expected output

<!-- snippet: ch13/lab-12-1-hard-reset/01-start -->
```text
$ cd retriever
$ git log --oneline
495f3a9 WIP: debug prints
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
$ git status -s
```
<!-- /snippet -->

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

<!-- snippet: ch13/lab-12-1-hard-reset/05-do-it-right -->
```text
# Now the operation that was intended: drop only the last commit.
$ git reset --hard HEAD~1
HEAD is now at 3106f68 Normalise queries before search
$ git log --oneline -3
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
798cb66 Add recall@k evaluation
$ git branch -D rescue/before-reset
Deleted branch rescue/before-reset (was 495f3a9).
```
<!-- /snippet -->

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

### What happened internally

- `git reset --hard HEAD~3` wrote `798cb66` into `refs/heads/main`, wrote the old value `495f3a9` into `.git/ORIG_HEAD`, appended one line to `logs/HEAD` and one to `logs/refs/heads/main`, and rewrote the index and the working tree. No object was deleted. The three commits were reachable from two reflog entries from that moment on.
- `git branch rescue/before-reset ORIG_HEAD` created a ref. The commits were back on the first layer of protection before the branch `main` had moved at all.
- The second `git reset --hard` moved `main` to the anchor and overwrote `ORIG_HEAD` again, this time with `798cb66`.
- The mixed reset in step 6 moved the branch and rebuilt the index from the older commit. The working tree was not touched, so the two files still held the content of the "removed" commits and showed as modified. `git reset 'HEAD@{1}'` moved the branch and the index back; the files already matched.

### Checkpoint

- `git log --oneline -1` prints `3106f68 Normalise queries before search`.
- `git status -s` prints nothing.
- `git branch` lists only `main`.

### Failure scenario

`retriever-incident` is the realistic case. The bad reset happened, nobody noticed, and a new commit, "Add MRR metric", was made on the shortened branch. Now you notice, and you apply the remedy that worked a minute ago:

```bash
cd ../retriever-incident
git log --oneline
git reset --hard ORIG_HEAD
git log --oneline
```

<!-- snippet: ch13/lab-12-1-hard-reset/07-failure -->
```text
$ cd ../retriever-incident
$ git log --oneline
4d74950 Add MRR metric
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
# Two commits and the debug commit are missing. The remedy that worked a minute ago:
$ git reset --hard ORIG_HEAD
HEAD is now at 495f3a9 WIP: debug prints
$ git log --oneline
495f3a9 WIP: debug prints
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
```
<!-- /snippet -->

The three old commits are back, including the debug commit you never wanted. The MRR commit is gone from the branch. One loss was exchanged for another.

### Recovery

Read the reflog of the branch. Every state the branch has had is one line:

```bash
git reflog show main
```

<!-- snippet: ch13/lab-12-1-hard-reset/08-recovery-read -->
```text
$ git reflog show main
495f3a9 main@{0}: reset: moving to ORIG_HEAD
4d74950 main@{1}: commit: Add MRR metric
798cb66 main@{2}: reset: moving to HEAD~3
495f3a9 main@{3}: commit: WIP: debug prints
3106f68 main@{4}: commit: Normalise queries before search
13ed88d main@{5}: commit: Raise top_k to 10
798cb66 main@{6}: commit: Add recall@k evaluation
8d2e200 main@{7}: commit: Add retrieval config
7525edc main@{8}: commit (initial): Add BM25 retriever
```
<!-- /snippet -->

`main@{1}` is the MRR commit. Anchor it, set the branch to the base you want (the old history without the debug commit), and copy the MRR commit onto it:

```bash
git branch rescue/mrr 'main@{1}'
git log --oneline -2 rescue/mrr
git reset --hard HEAD~1
git cherry-pick rescue/mrr
```

<!-- snippet: ch13/lab-12-1-hard-reset/09-recovery-anchor -->
```text
$ git branch rescue/mrr 'main@{1}'
$ git log --oneline -2 rescue/mrr
4d74950 Add MRR metric
798cb66 Add recall@k evaluation
$ git reset --hard HEAD~1
HEAD is now at 3106f68 Normalise queries before search
$ git cherry-pick rescue/mrr
[main e0dfe19] Add MRR metric
 Date: Mon Sep 7 10:10:00 2026 +0530
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

### Verification

```bash
git log --oneline
git range-diff rescue/mrr~1..rescue/mrr HEAD~1..HEAD
git status -s
git branch -D rescue/mrr
```

<!-- snippet: ch13/lab-12-1-hard-reset/10-verification -->
```text
$ git log --oneline
e0dfe19 Add MRR metric
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
$ git range-diff rescue/mrr~1..rescue/mrr HEAD~1..HEAD
1:  4d74950 = 1:  e0dfe19 Add MRR metric
$ git status -s
$ git branch -D rescue/mrr
Deleted branch rescue/mrr (was 4d74950).
```
<!-- /snippet -->

Five commits of the original history and the MRR commit on top. `git range-diff` compares the old MRR commit with the new one and prints `=`: the same change, a new ID. Your cherry-picked commit has a different ID than `e0dfe19`, because it was created at the real time.

### Questions

1. After `git reset --hard HEAD~3`, which three names pointed at the old tip? Which of them would still be correct after one more `git reset`?
2. Why did step 4 create a branch before it moved `main`? `git reset --hard ORIG_HEAD` alone would have produced the same branch.
3. In step 6, why was `git status -s` empty after `git reset 'HEAD@{1}'`, although that reset did not touch any file?
4. In the failure scenario, `ORIG_HEAD` pointed at a commit that the setup script's reset had left there. Why was it not the state you wanted, and what in the reflog told you which entry to anchor?
5. The repository contains uncommitted edits to `retriever.py` when someone runs `git reset --hard HEAD~3`. What is recoverable, and what is not?

## Lab 12.2: A deleted branch

### Objective

Force-delete an unmerged branch and bring it back, first from the ID that Git printed and then as if that line were lost. Then lose a branch that no reflog ever knew, and find it with `git fsck`.

### Prerequisites

- Chapter 13, sections 13.4 and 13.6.
- Chapter 12, section 12.11, for `git fetch --prune`.

### Setup

```bash
bash labs/ch13/setup-12-2-deleted-branch.sh
labs/shell m12-2
```

The script builds a bare `server.git` and your clone `reranker`. Locally you have `main` and the unmerged branch `feature/cross-encoder` with three commits. Your clone also has the remote-tracking ref `origin/exp/hard-negatives`: a teammate's experiment that you fetched and never checked out. She has since deleted that branch on the server, and her clone no longer exists.

### Commands

Step 1. The branch, and its reflog while it still has one.

```bash
cd reranker
git log --oneline --graph --all
git reflog show feature/cross-encoder
```

Step 2. Delete it. Read both messages.

```bash
git branch -d feature/cross-encoder
git branch -D feature/cross-encoder
git branch
git log --oneline --graph --all
```

Step 3. Look for what is left.

```bash
git reflog show feature/cross-encoder
git reflog -6
```

Step 4. Recreate the branch from the printed ID.

```bash
git branch feature/cross-encoder 2f65488
git log --oneline main..feature/cross-encoder
git reflog show feature/cross-encoder
```

Step 5. Suppose the `Deleted branch` line had scrolled away. Find the tip in the HEAD reflog.

```bash
git log -g --format='%h %gd %gs' --grep-reflog='moving from feature/cross-encoder'
git log --oneline -1 'HEAD@{2}'
```

### Expected output

<!-- snippet: ch13/lab-12-2-deleted-branch/01-start -->
```text
$ cd reranker
$ git log --oneline --graph --all
* 6f16e54 Document the pipeline stages
| * 2f65488 Cache reranker scores
| * 405080d Rerank the top 50 candidates
| * 7e43259 Add cross-encoder reranker
|/  
| * 60184f9 Deduplicate mined negatives
| * 0cea4ee Mine hard negatives from click logs
|/  
* 0875e65 Add pipeline config
* f9b487c Add retrieval pipeline
$ git reflog show feature/cross-encoder
2f65488 feature/cross-encoder@{0}: commit: Cache reranker scores
405080d feature/cross-encoder@{1}: commit: Rerank the top 50 candidates
7e43259 feature/cross-encoder@{2}: commit: Add cross-encoder reranker
0875e65 feature/cross-encoder@{3}: branch: Created from HEAD
```
<!-- /snippet -->

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

### What happened internally

- `git branch -d` compared the branch with HEAD, found three commits that `main` does not contain, and refused. `-D` skipped the comparison, deleted `refs/heads/feature/cross-encoder` and deleted `logs/refs/heads/feature/cross-encoder` with it.
- The commits stayed reachable through `logs/HEAD`, because HEAD had been on the branch while they were made. That is why `git log --all` no longer shows them and `git reflog` does.
- `git branch feature/cross-encoder 2f65488` wrote a new ref and started a new reflog with one line. The four lines you read in step 1 are not coming back.
- In the HEAD reflog, the entry `checkout: moving from feature/cross-encoder to main` records the commit HEAD arrived at. The entry below it is the last position HEAD had on the branch.

### Checkpoint

- `git log --oneline main..feature/cross-encoder` lists three commits, the newest `2f65488`.
- `git reflog show feature/cross-encoder` has exactly one line.

### Failure scenario

Now the branch that only a remote-tracking ref held. Look at it, then let a pruning fetch remove it:

```bash
git branch -r
git log --oneline -2 origin/exp/hard-negatives
git fetch --prune
git branch -r
git reflog show origin/exp/hard-negatives
git reflog | grep -c negatives
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

The ref is gone, its reflog is gone, the fetch printed `(none)` instead of an ID, and the HEAD reflog never saw these commits because you never checked them out. The server does not have them and the author's clone does not exist. Your object database is the last copy.

### Recovery

No name is left, so search the objects:

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

One dangling commit, and behind it a line of two commits by Asha that no ref reaches. Anchor the tip, check it, and put the branch back on the server:

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

`$(cat .git/lost-found/commit/*)` works here because there is exactly one file in that directory. With several findings, pass the one ID you chose.

### Verification

```bash
git fsck
git branch -a
git ls-remote origin
```

<!-- snippet: ch13/lab-12-2-deleted-branch/09-verification -->
```text
$ git fsck
$ git branch -a
  exp/hard-negatives
  feature/cross-encoder
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/exp/hard-negatives
  remotes/origin/main
$ git ls-remote origin
0875e653e1ea445820cf809b04e76ad29e461f14	HEAD
60184f9abb50a1f151181c08df375e5274ead3c6	refs/heads/exp/hard-negatives
0875e653e1ea445820cf809b04e76ad29e461f14	refs/heads/main
```
<!-- /snippet -->

`git fsck` is silent: nothing dangles. Both branches exist locally, and the experiment is on the server again under its old name and with its old IDs.

### Questions

1. Which two things did `git branch -D` delete, and which of them can be recreated?
2. Why did plain `git fsck` report nothing dangling after step 2, yet report a dangling commit after the pruning fetch?
3. In step 5, why is the branch tip the entry *below* the `checkout: moving from feature/cross-encoder to main` line? Describe a history of commands for which that entry would not be the tip.
4. In a repository with default configuration, how long would the commits of `exp/hard-negatives` have survived after the pruning fetch, and what would have ended that period?
5. Your teammate asks whether she could have recovered the branch herself. Under which conditions, and with which command?

## Lab 12.3: A deleted commit

### Objective

Find a commit that vanished from the middle of a branch, prove which operation removed it, and restore it without disturbing the work that came after. Then make a commit disappear a second way, with `git commit --amend`, and take the two commits apart again.

### Prerequisites

- Chapter 13, section 13.8.
- Chapter 9, section 9.6, for the todo list of an interactive rebase; Chapter 10, section 10.10, for `git cherry`.

### Setup

```bash
bash labs/ch13/setup-12-3-deleted-commit.sh
labs/shell m12-3
```

The script builds `embedder`. The branch `feature/batching` once had four commits. During a tidy-up with `git rebase -i`, the second line of the todo list was deleted, and one more commit was made afterwards. You are on `feature/batching`.

### Commands

Step 1. The symptom.

```bash
cd embedder
git log --oneline main..feature/batching
cat client.yaml
git log --oneline --all -- client.yaml
```

Step 2. Ask the branch what happened to it.

```bash
git reflog show feature/batching
```

Step 3. Anchor the tip from before the rebase and compare by content.

```bash
git branch rescue/before-rebase 'feature/batching@{2}'
git log --oneline main..rescue/before-rebase
git cherry -v feature/batching rescue/before-rebase
```

Step 4. Inspect the missing commit and copy it onto the branch.

```bash
git show --stat --format='%h %s' 2ebd700
git cherry-pick 2ebd700
cat client.yaml
```

Step 5. Verify, and remove the anchor.

```bash
git log --oneline main..feature/batching
git cherry -v feature/batching rescue/before-rebase
git status -s
git branch -D rescue/before-rebase
```

### Expected output

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

<!-- snippet: ch13/lab-12-3-deleted-commit/05-verification -->
```text
$ git log --oneline main..feature/batching
ff46c25 Add request timeout
a7061c1 Document batching in the README
0309a41 Log batch sizes
285e3af Retry on rate limit
696a15f Batch embedding requests
$ git cherry -v feature/batching rescue/before-rebase
- 2ebd700e9eb436ad1c04d80c284f18f294fc5011 Add request timeout
- f35b47a4e60533a59aba361e16d42aa94602ee05 Retry on rate limit
- 76a49edc7fb8cf1ba56ecdc367f05eb1dae9ec89 Log batch sizes
$ git status -s
$ git branch -D rescue/before-rebase
Deleted branch rescue/before-rebase (was 76a49ed).
```
<!-- /snippet -->

### What happened internally

- The interactive rebase replayed the lines that were left in the todo list. The first commit, `696a15f`, kept its ID because it stayed on the same parent. "Retry on rate limit" and "Log batch sizes" were recreated on top of it as `285e3af` and `0309a41`. The commit whose line was deleted, `2ebd700`, was not replayed. Nothing was deleted from the object database.
- The reflog of the branch recorded the whole rebase as one line, `rebase (finish)`. The entry below that line is the tip before the rebase, `76a49ed`.
- `git cherry -v feature/batching rescue/before-rebase` compared the commits of the old tip with the branch by patch ID. Two have an equivalent on the branch (`-`). One does not (`+`), and that is the lost commit.
- `git cherry-pick 2ebd700` applied that one change on top of the current branch as a new commit. After it, `git cherry` reports `-` for all three.

### Checkpoint

- `client.yaml` contains `timeout_s: 10`.
- `git log --oneline main..feature/batching` shows five commits, the newest "Add request timeout".
- `git status -s` prints nothing.

### Failure scenario

The README has a typo, "batchs". You fix it and commit, and by habit you type `--amend`:

```bash
printf 'Embedding client. Requests are sent in batches of 32.\n' > README.md
git commit -a --amend -m "Fix typo in README"
git log --oneline -3
git show --stat --format=%s HEAD
```

<!-- snippet: ch13/lab-12-3-deleted-commit/06-failure -->
```text
# A typo fix that was meant to be a commit of its own:
$ printf 'Embedding client. Requests are sent in batches of 32.\n' > README.md
$ git commit -a --amend -m "Fix typo in README"
[feature/batching 50df155] Fix typo in README
 Date: Mon Sep 7 10:07:00 2026 +0530
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git log --oneline -3
50df155 Fix typo in README
a7061c1 Document batching in the README
0309a41 Log batch sizes
$ git show --stat --format=%s HEAD
Fix typo in README

 README.md   | 2 +-
 client.yaml | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

There is no fourth commit. The tip is now called "Fix typo in README" and contains two changes: the typo fix and the request timeout. The commit "Add request timeout" that you restored a minute ago has disappeared from the log again.

### Recovery

The amend replaced the tip, and the reflog has the commit it replaced. Move the branch back to it and keep the index:

```bash
git reflog -2
git reset --soft 'HEAD@{1}'
git status -s
git diff --cached
git commit -m "Fix typo in README"
```

<!-- snippet: ch13/lab-12-3-deleted-commit/07-recovery -->
```text
$ git reflog -2
50df155 HEAD@{0}: commit (amend): Fix typo in README
ff46c25 HEAD@{1}: cherry-pick: Add request timeout
$ git reset --soft 'HEAD@{1}'
$ git status -s
M  README.md
$ git diff --cached
diff --git a/README.md b/README.md
index 202d75c..5c95234 100644
--- a/README.md
+++ b/README.md
@@ -1 +1 @@
-Embedding client. Requests are sent in batchs of 32.
+Embedding client. Requests are sent in batches of 32.
$ git commit -m "Fix typo in README"
[feature/batching fdbbfc7] Fix typo in README
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

### Verification

```bash
git log --oneline -4
git show --stat --format=%s HEAD~1
```

<!-- snippet: ch13/lab-12-3-deleted-commit/08-after -->
```text
$ git log --oneline -4
fdbbfc7 Fix typo in README
ff46c25 Add request timeout
a7061c1 Document batching in the README
0309a41 Log batch sizes
$ git show --stat --format=%s HEAD~1
Add request timeout

 client.yaml | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

Two commits where the amend had left one: "Add request timeout" with its one-line change to `client.yaml`, and the typo fix on top.

### Questions

1. Name the three commands that can remove a commit from a branch without deleting the branch. What does the reflog message of each look like?
2. Why did "Batch embedding requests" keep its ID through the rebase while the two commits after the deleted line received new ones?
3. Why was `git cherry-pick` the right repair in step 4 and `git reset --hard rescue/before-rebase` the wrong one?
4. `git cherry` compares by patch ID. Under which circumstances would it have printed `+` for a commit that was in fact rebased and kept?
5. Explain why `git reset --soft 'HEAD@{1}'` left exactly the typo fix staged.

## Lab 12.4: A wrong rebase

### Objective

Repair a branch that was rebased onto the wrong base, when new work was committed after the rebase. Keep the new work, restore the old base, and prove that the result is what was intended.

### Prerequisites

- Chapter 13, section 13.8.
- Chapter 9, sections 9.5 and 9.16, and Lab 9.5, which covers the simpler case that is noticed at once.

### Setup

```bash
bash labs/ch13/setup-12-4-wrong-rebase.sh
labs/shell m12-4
```

The script builds `evalharness` with `main`, `release/1.4` and `hotfix/judge-timeout`. The hotfix branch was cut from `release/1.4` and got two commits. Then `git rebase main` was run on it by habit, and a third commit, "Log judge latency", was added. `evalharness-incident` is a copy for the failure scenario.

### Commands

Step 1. The symptom: what a pull request against `release/1.4` would contain.

```bash
cd evalharness
git status -sb
git log --oneline release/1.4..HEAD
git log --oneline --graph --all
```

Step 2. The evidence.

```bash
git reflog show hotfix/judge-timeout
```

Step 3. Two anchors: the tip before the rebase, and the present state.

```bash
git branch rescue/pre-rebase 'hotfix/judge-timeout@{2}'
git log --oneline release/1.4..rescue/pre-rebase
git branch backup/rebased-hotfix
```

Step 4. Transplant the one commit that was made after the rebase onto the old tip.

```bash
git rebase --onto rescue/pre-rebase HEAD~1
git log --oneline release/1.4..HEAD
```

Step 5. Verify, and remove the anchors.

```bash
git log --oneline --graph release/1.4 hotfix/judge-timeout main
git range-diff backup/rebased-hotfix~1..backup/rebased-hotfix HEAD~1..HEAD
git diff --stat release/1.4 HEAD
git branch -D rescue/pre-rebase backup/rebased-hotfix
```

### Expected output

<!-- snippet: ch13/lab-12-4-wrong-rebase/01-symptom -->
```text
$ cd evalharness
$ git status -sb
## hotfix/judge-timeout
$ git log --oneline release/1.4..HEAD
37bb577 Log judge latency
6ef447a Retry judge on timeout
262dc41 Add judge timeout
7213db9 Pin judge model for 1.4
5783ca4 Add faithfulness metric
9288f20 Switch judge to JSON mode
$ git log --oneline --graph --all
* 37bb577 Log judge latency
* 6ef447a Retry judge on timeout
* 262dc41 Add judge timeout
* 7213db9 Pin judge model for 1.4
* 5783ca4 Add faithfulness metric
* 9288f20 Switch judge to JSON mode
| * dc1ff44 Pin judge model for 1.4
|/  
* 1d7a7cc Add judge prompt
* cd80329 Add eval runner
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-4-wrong-rebase/02-evidence -->
```text
$ git reflog show hotfix/judge-timeout
37bb577 hotfix/judge-timeout@{0}: commit: Log judge latency
6ef447a hotfix/judge-timeout@{1}: rebase (finish): refs/heads/hotfix/judge-timeout onto 5783ca45370007569bfb3217980f447300484db9
eb1f140 hotfix/judge-timeout@{2}: commit: Retry judge on timeout
c5f4fb7 hotfix/judge-timeout@{3}: commit: Add judge timeout
dc1ff44 hotfix/judge-timeout@{4}: branch: Created from HEAD
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-4-wrong-rebase/03-anchor -->
```text
$ git branch rescue/pre-rebase 'hotfix/judge-timeout@{2}'
$ git log --oneline release/1.4..rescue/pre-rebase
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
$ git branch backup/rebased-hotfix
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-4-wrong-rebase/04-transplant -->
```text
$ git rebase --onto rescue/pre-rebase HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/hotfix/judge-timeout.
$ git log --oneline release/1.4..HEAD
13305ef Log judge latency
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-4-wrong-rebase/05-verification -->
```text
$ git log --oneline --graph release/1.4 hotfix/judge-timeout main
* 13305ef Log judge latency
* eb1f140 Retry judge on timeout
* c5f4fb7 Add judge timeout
* dc1ff44 Pin judge model for 1.4
| * 5783ca4 Add faithfulness metric
| * 9288f20 Switch judge to JSON mode
|/  
* 1d7a7cc Add judge prompt
* cd80329 Add eval runner
$ git range-diff backup/rebased-hotfix~1..backup/rebased-hotfix HEAD~1..HEAD
1:  37bb577 = 1:  13305ef Log judge latency
$ git diff --stat release/1.4 HEAD
 runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -D rescue/pre-rebase backup/rebased-hotfix
Deleted branch rescue/pre-rebase (was eb1f140).
Deleted branch backup/rebased-hotfix (was 37bb577).
```
<!-- /snippet -->

### What happened internally

- `git rebase main` had replayed every commit in `main..hotfix/judge-timeout` onto `main`. That range held three commits: the two hotfix commits and "Pin judge model for 1.4", which the branch had inherited from `release/1.4`. All three were recreated with new IDs, which is why the graph shows "Pin judge model for 1.4" twice.
- The reflog of the branch has the rebase as one line. The entry below it, `hotfix/judge-timeout@{2}`, is `eb1f140`, the tip from before.
- `git rebase --onto rescue/pre-rebase HEAD~1` took the commits after `HEAD~1`, which is the single commit "Log judge latency", and replayed them onto `rescue/pre-rebase`. The branch ref then moved to the result.
- `git range-diff` paired the latency commit before and after the transplant and printed `=`: the same change. `git diff --stat release/1.4 HEAD` shows that the branch differs from the release branch in `runner.py` only.

### Checkpoint

- `git log --oneline release/1.4..HEAD` lists three commits: "Log judge latency", `eb1f140` and `c5f4fb7`.
- The graph shows the hotfix on top of `dc1ff44`, and `main` as a separate line.

### Failure scenario

In the copy, take the shortcut: move the branch back to the tip from before the rebase and stop there.

```bash
cd ../evalharness-incident
git reset --hard 'hotfix/judge-timeout@{2}'
git log --oneline release/1.4..HEAD
cat runner.py
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/06-failure -->
```text
$ cd ../evalharness-incident
$ git reset --hard 'hotfix/judge-timeout@{2}'
HEAD is now at eb1f140 Retry judge on timeout
$ git log --oneline release/1.4..HEAD
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
$ cat runner.py
def run(cases):
    return [with_retry(judge, c, timeout_s=30) for c in cases]
```
<!-- /snippet -->

The base is right, and the latency commit is gone from the branch. `runner.py` has no `timed(` call.

### Recovery

The reset that caused this loss also recorded where the branch was. Here `ORIG_HEAD` is trustworthy, because the reset was the last command that writes it. The branch reflog says the same:

```bash
git log --oneline -1 ORIG_HEAD
git reflog show hotfix/judge-timeout -2
git cherry-pick ORIG_HEAD
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/07-recovery -->
```text
$ git log --oneline -1 ORIG_HEAD
37bb577 Log judge latency
$ git reflog show hotfix/judge-timeout -2
eb1f140 hotfix/judge-timeout@{0}: reset: moving to hotfix/judge-timeout@{2}
37bb577 hotfix/judge-timeout@{1}: commit: Log judge latency
$ git cherry-pick ORIG_HEAD
[hotfix/judge-timeout eed9fb5] Log judge latency
 Date: Mon Sep 7 10:14:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

### Verification

```bash
git log --oneline release/1.4..HEAD
cat runner.py
```

<!-- snippet: ch13/lab-12-4-wrong-rebase/08-after -->
```text
$ git log --oneline release/1.4..HEAD
eed9fb5 Log judge latency
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
$ cat runner.py
def run(cases):
    return [timed(with_retry, judge, c, timeout_s=30) for c in cases]
```
<!-- /snippet -->

Three commits on the release base, and `runner.py` calls `timed(` again. This is the same result as step 4, reached by reset and cherry-pick instead of `rebase --onto`.

### Questions

1. Why did the wrong rebase create a second "Pin judge model for 1.4" commit?
2. In the reflog of the branch, which entry is the tip from before the rebase, and why is its position `@{2}` and not `@{1}`?
3. What does each of the three arguments in `git rebase --onto rescue/pre-rebase HEAD~1` mean, including the one that is not written?
4. `ORIG_HEAD` was the wrong tool in Lab 12.9 and the right one in this lab's recovery. What is the difference?
5. The wrongly rebased branch had already been pushed with `--force-with-lease`. What changes in the repair?

## Lab 12.5: A bad merge

### Objective

Merge the wrong branch into `main` as a fast-forward and undo it correctly. Then apply the recipe "undo the merge with `HEAD~1`", watch it fail, watch `ORIG_HEAD` fail after it, and recover from the reflog by reading messages.

### Prerequisites

- Chapter 13, sections 13.5 and 13.8.
- Chapter 8 for fast-forward merges; Chapter 11, section 11.6, for `git reset --keep`.

### Setup

```bash
bash labs/ch13/setup-12-5-bad-merge.sh
labs/shell m12-5
```

The script builds `promptstore` with `main`, the finished branch `feature/citations` and the unfinished experiment `exp/few-shot`, whose last commit removes the refusal rule from the system prompt. `promptstore-incident` is the same repository after `exp/few-shot` was merged into `main` by mistake.

### Commands

Step 1. The branches.

```bash
cd promptstore
git log --oneline --graph --all
```

Step 2. The mistake: you mean to merge `feature/citations`.

```bash
git merge exp/few-shot
git log --oneline
cat system.txt
```

Step 3. Evidence: where was `main`, and what did the merge bring in?

```bash
git reflog -2
git log --oneline -1 ORIG_HEAD
git log --oneline ORIG_HEAD..HEAD
```

Step 4. Move `main` back, and do the merge you intended.

```bash
git reset --keep ORIG_HEAD
git log --oneline
git merge feature/citations
```

Step 5. Verify.

```bash
git log --oneline --graph --all
cat system.txt
git branch --contains exp/few-shot
```

### Expected output

<!-- snippet: ch13/lab-12-5-bad-merge/01-start -->
```text
$ cd promptstore
$ git log --oneline --graph --all
* deec1c6 WIP: drop the refusal rule
* df44d03 WIP: longer examples
* efee0cd Try few-shot examples
| * 3aae83f Require citations in answers
|/  
* 0529d31 Add prompt loader
* 5aab090 Add system prompt
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-5-bad-merge/02-disaster -->
```text
# The branch you meant to merge is feature/citations.
$ git merge exp/few-shot
Updating 0529d31..deec1c6
Fast-forward
 examples.txt | 4 ++++
 system.txt   | 1 -
 2 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 examples.txt
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
$ cat system.txt
You answer questions about our product documentation.
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-5-bad-merge/03-evidence -->
```text
$ git reflog -2
deec1c6 HEAD@{0}: merge exp/few-shot: Fast-forward
0529d31 HEAD@{1}: checkout: moving from exp/few-shot to main
$ git log --oneline -1 ORIG_HEAD
0529d31 Add prompt loader
$ git log --oneline ORIG_HEAD..HEAD
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-5-bad-merge/04-recover -->
```text
$ git reset --keep ORIG_HEAD
$ git log --oneline
0529d31 Add prompt loader
5aab090 Add system prompt
$ git merge feature/citations
Updating 0529d31..3aae83f
Fast-forward
 system.txt | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-5-bad-merge/05-verification -->
```text
$ git log --oneline --graph --all
* deec1c6 WIP: drop the refusal rule
* df44d03 WIP: longer examples
* efee0cd Try few-shot examples
| * 3aae83f Require citations in answers
|/  
* 0529d31 Add prompt loader
* 5aab090 Add system prompt
$ cat system.txt
You answer questions about our product documentation.
If the answer is not in the context, say that you do not know.
Cite the source document for every claim.
$ git branch --contains exp/few-shot
  exp/few-shot
```
<!-- /snippet -->

### What happened internally

- `main` had no commits that `exp/few-shot` lacked, so the merge was a fast-forward: Git wrote `deec1c6` into `refs/heads/main`, updated the index and the working tree, and created no commit. `git merge` wrote the previous value `0529d31` into `ORIG_HEAD`.
- `ORIG_HEAD..HEAD` lists the commits the merge added to `main`: three. There is no merge commit that could be removed to undo them together.
- `git reset --keep ORIG_HEAD` moved `main` back to `0529d31` and updated the files that differ between the two commits. It would have refused if one of those files had an uncommitted change.
- The second merge was a fast-forward to `3aae83f`. `exp/few-shot` was never changed by any of this, which the last command confirms: only the experiment branch contains its tip.

### Checkpoint

- `system.txt` has three lines, the last one about citations.
- `git branch --contains exp/few-shot` lists only `exp/few-shot`.

### Failure scenario

`promptstore-incident` is at the moment after the wrong merge. Apply the recipe that many tutorials give, and when it does not work, the one from step 4:

```bash
cd ../promptstore-incident
git log --oneline
git reset --hard HEAD~1
git log --oneline
git reset --hard ORIG_HEAD
git log --oneline
```

<!-- snippet: ch13/lab-12-5-bad-merge/06-failure -->
```text
$ cd ../promptstore-incident
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
# The recipe from a tutorial: "undo the merge" by dropping one commit.
$ git reset --hard HEAD~1
HEAD is now at df44d03 WIP: longer examples
$ git log --oneline
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
# Still two experiment commits. The other recipe:
$ git reset --hard ORIG_HEAD
HEAD is now at deec1c6 WIP: drop the refusal rule
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
```
<!-- /snippet -->

`HEAD~1` removed one experiment commit of three. `ORIG_HEAD` then put it back, because the first reset had overwritten the slot with the merged tip. You are where you started, and both recipes are used up.

### Recovery

The reflog of `main` has every state. Find the merge by its message; the entry below it is the state before:

```bash
git reflog show main
git log -g --format='%gd %gs' main | grep -A1 'merge exp/few-shot'
git reset --keep 'main@{3}'
git log --oneline
git merge feature/citations
```

<!-- snippet: ch13/lab-12-5-bad-merge/07-recovery-read -->
```text
$ git reflog show main
deec1c6 main@{0}: reset: moving to ORIG_HEAD
df44d03 main@{1}: reset: moving to HEAD~1
deec1c6 main@{2}: merge exp/few-shot: Fast-forward
0529d31 main@{3}: commit: Add prompt loader
5aab090 main@{4}: commit (initial): Add system prompt
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-5-bad-merge/08-recovery -->
```text
$ git log -g --format='%gd %gs' main | grep -A1 'merge exp/few-shot'
main@{2} merge exp/few-shot: Fast-forward
main@{3} commit: Add prompt loader
$ git reset --keep 'main@{3}'
$ git log --oneline
0529d31 Add prompt loader
5aab090 Add system prompt
$ git merge feature/citations
Updating 0529d31..3aae83f
Fast-forward
 system.txt | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

The number in `main@{3}` is valid for this transcript. If you typed other commands in between, take the selector that your own `grep` prints on its second line.

### Verification

```bash
git log --oneline --graph --all
cat system.txt
```

<!-- snippet: ch13/lab-12-5-bad-merge/09-after -->
```text
$ git log --oneline --graph --all
* deec1c6 WIP: drop the refusal rule
* df44d03 WIP: longer examples
* efee0cd Try few-shot examples
| * 3aae83f Require citations in answers
|/  
* 0529d31 Add prompt loader
* 5aab090 Add system prompt
$ cat system.txt
You answer questions about our product documentation.
If the answer is not in the context, say that you do not know.
Cite the source document for every claim.
```
<!-- /snippet -->

### Questions

1. Why is `git reset --hard HEAD~1` a correct undo for a merge that created a merge commit and a wrong one for a fast-forward?
2. After the two resets of the failure scenario, what did `ORIG_HEAD` hold, and which command had written it?
3. Why did the lab use `git reset --keep` where many recipes use `--hard`? Describe a situation in which the two behave differently.
4. The wrong merge had been pushed to a shared `main`. Which command replaces the reset, and which later problem must the team know about?
5. How could configuration have prevented a fast-forward here, and would that have made the recipe with `HEAD~1` correct?

## Lab 12.6: Commits on the wrong branch

### Objective

Move two unpushed commits from `main` to the feature branch they belong on, in the safe order: copy first, remove second. Then do it in the unsafe order and recover the commits from the reflog.

### Prerequisites

- Chapter 13, section 13.8.
- Chapter 10, section 10.5, for cherry-picking a range; Chapter 12, section 12.5, for `ahead` and `behind`.

### Setup

```bash
bash labs/ch13/setup-12-6-wrong-branch.sh
labs/shell m12-6
```

The script builds `server.git` and your clone `ingest`. `main` is two commits ahead of `origin/main`: work on PDF tables that should be on the existing branch `feature/pdf-tables`. `ingest-incident` is a copy.

### Commands

Step 1. The symptom, and the exact name of the misplaced commits.

```bash
cd ingest
git status -sb
git log --oneline --graph --all
git log --oneline origin/main..main
```

Step 2. Copy them to the branch where they belong.

```bash
git switch feature/pdf-tables
git cherry-pick origin/main..main
git log --oneline -3
```

Step 3. Only now move `main` back to the server's state.

```bash
git switch main
git reset --keep origin/main
git status -sb
```

Step 4. Verify that nothing was lost.

```bash
git log --oneline --graph --all
git cherry -v feature/pdf-tables ORIG_HEAD
git diff --stat ORIG_HEAD feature/pdf-tables
```

### Expected output

<!-- snippet: ch13/lab-12-6-wrong-branch/01-symptom -->
```text
$ cd ingest
$ git status -sb
## main...origin/main [ahead 2]
$ git log --oneline --graph --all
* c8fec4d Add a table fixture for tests
* 0eece93 Keep table rows together when chunking
| * fb8cb6c Parse PDF tables
|/  
* 4711dcc Add chunker
* 5a80a30 Add document loader
$ git log --oneline origin/main..main
c8fec4d Add a table fixture for tests
0eece93 Keep table rows together when chunking
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-6-wrong-branch/02-copy -->
```text
$ git switch feature/pdf-tables
Switched to branch 'feature/pdf-tables'
$ git cherry-pick origin/main..main
[feature/pdf-tables c7f48b2] Keep table rows together when chunking
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 3 insertions(+)
[feature/pdf-tables ed2177f] Add a table fixture for tests
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 fixtures/table.json
$ git log --oneline -3
ed2177f Add a table fixture for tests
c7f48b2 Keep table rows together when chunking
fb8cb6c Parse PDF tables
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-6-wrong-branch/03-move-main-back -->
```text
$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)
$ git reset --keep origin/main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-6-wrong-branch/04-verification -->
```text
$ git log --oneline --graph --all
* ed2177f Add a table fixture for tests
* c7f48b2 Keep table rows together when chunking
* fb8cb6c Parse PDF tables
* 4711dcc Add chunker
* 5a80a30 Add document loader
$ git cherry -v feature/pdf-tables ORIG_HEAD
- 0eece93917b25b13d6ce44e865e3f34ffe852be4 Keep table rows together when chunking
- c8fec4d032b7fa4886242a1a5e89658a5e58cf76 Add a table fixture for tests
$ git diff --stat ORIG_HEAD feature/pdf-tables
 tables.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

### What happened internally

- `origin/main..main` is the set of commits reachable from `main` and not from `origin/main`: the two commits that exist only locally. `git cherry-pick` applied them in order, oldest first, onto `feature/pdf-tables` as two new commits.
- For a moment the work existed twice: the originals `0eece93` and `c8fec4d` on `main`, and the copies on the feature branch. That overlap is the safety margin.
- `git reset --keep origin/main` moved `main` to `4711dcc` and wrote the old tip into `ORIG_HEAD`. The originals are now held by the reflog only.
- `git cherry -v feature/pdf-tables ORIG_HEAD` marks both originals with `-`: an equivalent change is on the feature branch. `git diff --stat` between the old tip of `main` and the feature branch shows `tables.py` only, the feature's own earlier commit.

### Checkpoint

- `git status -sb` on `main` prints `## main...origin/main` with nothing after it.
- `feature/pdf-tables` has three commits on top of `4711dcc`.

### Failure scenario

In the copy, do it in the other order: tidy `main` first.

```bash
cd ../ingest-incident
git status -sb
git reset --hard origin/main
git log --oneline --graph --all
```

<!-- snippet: ch13/lab-12-6-wrong-branch/05-failure -->
```text
$ cd ../ingest-incident
$ git status -sb
## main...origin/main [ahead 2]
# Tidy main first, copy later:
$ git reset --hard origin/main
HEAD is now at 4711dcc Add chunker
$ git log --oneline --graph --all
* fb8cb6c Parse PDF tables
* 4711dcc Add chunker
* 5a80a30 Add document loader
```
<!-- /snippet -->

No branch contains the two commits. `git log --all` does not show them.

### Recovery

`main` moved, so the reflog of `main` has the old tip. The range you need is the same as before, with `main@{1}` in the place of `main`:

```bash
git reflog show main -3
git log --oneline origin/main..'main@{1}'
git switch feature/pdf-tables
git cherry-pick origin/main..'main@{1}'
```

<!-- snippet: ch13/lab-12-6-wrong-branch/06-recovery -->
```text
$ git reflog show main -3
4711dcc main@{0}: reset: moving to origin/main
c8fec4d main@{1}: commit: Add a table fixture for tests
0eece93 main@{2}: commit: Keep table rows together when chunking
$ git log --oneline origin/main..'main@{1}'
c8fec4d Add a table fixture for tests
0eece93 Keep table rows together when chunking
$ git switch feature/pdf-tables
Switched to branch 'feature/pdf-tables'
$ git cherry-pick origin/main..'main@{1}'
[feature/pdf-tables ba6fa3a] Keep table rows together when chunking
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 3 insertions(+)
[feature/pdf-tables 28df4a5] Add a table fixture for tests
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 fixtures/table.json
```
<!-- /snippet -->

### Verification

```bash
git log --oneline --graph --all
ls
```

<!-- snippet: ch13/lab-12-6-wrong-branch/07-after -->
```text
$ git log --oneline --graph --all
* 28df4a5 Add a table fixture for tests
* ba6fa3a Keep table rows together when chunking
* fb8cb6c Parse PDF tables
* 4711dcc Add chunker
* 5a80a30 Add document loader
$ ls
chunker.py
fixtures
loader.py
tables.py
```
<!-- /snippet -->

### Questions

1. Why is `origin/main..main` a better name for the misplaced commits than `HEAD~2..HEAD`?
2. If `feature/pdf-tables` had not existed yet, which two commands would have done the whole job without a cherry-pick?
3. In step 4, what does each `-` in the output of `git cherry -v` prove?
4. In the failure scenario the commits were unreachable from every branch. Which layer of protection held them, and for how long would it hold them in a repository with default settings?
5. The two commits had already been pushed to `origin/main`. Why is `git reset` no longer acceptable, and what do you do instead?

## Lab 12.7: Lost work in detached HEAD

### Objective

Find commits that were made in detached HEAD days ago and are on no branch, when the warning Git printed at the time is long gone. Use `git fsck --no-reflogs` to find the tips, inspect them, and give each line a branch. Then copy "the hotfix" to `main` the wrong way and the right way.

### Prerequisites

- Chapter 13, sections 13.6 and 13.8.
- Chapter 7, section 7.7, and Lab 4.2, which rescues detached commits from the warning itself.

### Setup

```bash
bash labs/ch13/setup-12-7-detached-head.sh
labs/shell m12-7
```

The script builds `modelserver`: `main` with five commits and the tag `v1.2.0`. In the past, two sessions of work were done in detached HEAD and left behind. You do not know their IDs.

### Commands

Step 1. The symptom: the hotfixes you remember are nowhere.

```bash
cd modelserver
git status -sb
git log --oneline --graph --all
git branch --contains v1.2.0
```

Step 2. The HEAD reflog has everything, mixed with everything else.

```bash
git reflog
```

Step 3. Ask for the tips that no branch and no tag reaches, and for what hangs on them.

```bash
git fsck --no-reflogs
git log --oneline --graph 266d3b2 852224f --not --all
```

Step 4. Inspect each tip.

```bash
git show --stat --format='%h %ad %s' --date=format:'%a %H:%M' 266d3b2
git show --stat --format='%h %ad %s' --date=format:'%a %H:%M' 852224f
```

Step 5. Give each line a name.

```bash
git branch hotfix/1.2.1 266d3b2
git branch exp/no-response-cache 852224f
git log --oneline --graph --all
```

Step 6. Verify.

```bash
git fsck --no-reflogs
git log --oneline v1.2.0..hotfix/1.2.1
```

### Expected output

<!-- snippet: ch13/lab-12-7-detached-head/01-symptom -->
```text
$ cd modelserver
$ git status -sb
## main
$ git log --oneline --graph --all
* f4a81dc Document the endpoints
* 20459b3 Export latency metrics
* f6f6bbb Add streaming endpoint
* be53ce8 Add request limits
* 3838324 Add inference endpoint
$ git branch --contains v1.2.0
* main
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-7-detached-head/02-reflog -->
```text
$ git reflog
f4a81dc HEAD@{0}: commit: Document the endpoints
20459b3 HEAD@{1}: checkout: moving from 852224fe93ed50676b587ace22cee739d967505f to main
852224f HEAD@{2}: commit: Experiment: disable response cache
f6f6bbb HEAD@{3}: checkout: moving from main to HEAD~1
20459b3 HEAD@{4}: commit: Export latency metrics
f6f6bbb HEAD@{5}: checkout: moving from 266d3b2a96a6a113c06fe5974b09562b1d3f440b to main
266d3b2 HEAD@{6}: commit: Hotfix: reject empty prompts
ba8c3d9 HEAD@{7}: commit: Hotfix: cap max_tokens at 4096
be53ce8 HEAD@{8}: checkout: moving from main to v1.2.0
f6f6bbb HEAD@{9}: commit: Add streaming endpoint
be53ce8 HEAD@{10}: commit: Add request limits
3838324 HEAD@{11}: commit (initial): Add inference endpoint
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-7-detached-head/03-fsck -->
```text
$ git fsck --no-reflogs
dangling commit 852224fe93ed50676b587ace22cee739d967505f
dangling commit 266d3b2a96a6a113c06fe5974b09562b1d3f440b
$ git log --oneline --graph 266d3b2 852224f --not --all
* 852224f Experiment: disable response cache
* 266d3b2 Hotfix: reject empty prompts
* ba8c3d9 Hotfix: cap max_tokens at 4096
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-7-detached-head/04-inspect -->
```text
$ git show --stat --format='%h %ad %s' --date=format:'%a %H:%M' 266d3b2
266d3b2 Mon 10:09 Hotfix: reject empty prompts

 validate.py | 2 ++
 1 file changed, 2 insertions(+)
$ git show --stat --format='%h %ad %s' --date=format:'%a %H:%M' 852224f
852224f Mon 10:13 Experiment: disable response cache

 cache.yaml | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-7-detached-head/05-anchor -->
```text
$ git branch hotfix/1.2.1 266d3b2
$ git branch exp/no-response-cache 852224f
$ git log --oneline --graph --all
* f4a81dc Document the endpoints
* 20459b3 Export latency metrics
| * 852224f Experiment: disable response cache
|/  
* f6f6bbb Add streaming endpoint
| * 266d3b2 Hotfix: reject empty prompts
| * ba8c3d9 Hotfix: cap max_tokens at 4096
|/  
* be53ce8 Add request limits
* 3838324 Add inference endpoint
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-7-detached-head/06-verification -->
```text
$ git fsck --no-reflogs
$ git log --oneline v1.2.0..hotfix/1.2.1
266d3b2 Hotfix: reject empty prompts
ba8c3d9 Hotfix: cap max_tokens at 4096
```
<!-- /snippet -->

### What happened internally

- In detached HEAD, each commit wrote its ID into `.git/HEAD` directly. No file under `refs/heads` changed, so no branch reflog has these commits. Only `logs/HEAD` recorded them.
- The reflog shows both sessions. Each begins with a `checkout: moving from main to ...` line and ends with a line whose message contains a full 40-digit ID in the place of a branch name: `moving from 266d3b2a96a6... to main`. That ID is the tip that was left behind.
- `git fsck --no-reflogs` used branches, tags, HEAD and the index as starting points and ignored the reflog. It reported the two tips as dangling. Without the option it reports nothing here, because the reflog reaches both.
- `git log ... --not --all` limited the graph to commits that no ref reaches: three commits on two lines.
- `git branch hotfix/1.2.1 266d3b2` wrote one ref. Afterwards `git fsck --no-reflogs` is silent.

### Checkpoint

- `git log --oneline --graph --all` shows three lines of development: `main`, the hotfix line from `be53ce8`, and the experiment from `f6f6bbb`.
- `git fsck --no-reflogs` prints nothing.

### Failure scenario

The two hotfixes are needed on `main` as well. You copy "the hotfix", meaning the newest commit:

```bash
git cherry-pick 266d3b2
git status -s
```

<!-- snippet: ch13/lab-12-7-detached-head/07-failure -->
```text
# The hotfixes are needed on main as well. Copying "the hotfix", that is, the newest commit:
$ git cherry-pick 266d3b2
CONFLICT (modify/delete): validate.py deleted in HEAD and modified in 266d3b2 (Hotfix: reject empty prompts).  Version 266d3b2 (Hotfix: reject empty prompts) of validate.py left in tree.
error: could not apply 266d3b2... Hotfix: reject empty prompts
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ git status -s
DU validate.py
```
<!-- /snippet -->

`266d3b2` changes `validate.py`, and that file was created by the commit before it, `ba8c3d9`, which is not on `main`. Git reports a modify/delete conflict, and `DU` in the status means "deleted by us, modified by them". The pick has stopped half-way.

### Recovery

Abort, then pick the whole line. The range `v1.2.0..hotfix/1.2.1` is every commit on the hotfix branch after the tag:

```bash
git cherry-pick --abort
git status -s
git cherry-pick v1.2.0..hotfix/1.2.1
```

<!-- snippet: ch13/lab-12-7-detached-head/08-recovery -->
```text
$ git cherry-pick --abort
$ git status -s
$ git cherry-pick v1.2.0..hotfix/1.2.1
[main 097e0be] Hotfix: cap max_tokens at 4096
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 3 insertions(+)
 create mode 100644 validate.py
[main f563b49] Hotfix: reject empty prompts
 Date: Mon Sep 7 10:09:00 2026 +0530
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

### Verification

```bash
git log --oneline -3
cat validate.py
git status -sb
```

<!-- snippet: ch13/lab-12-7-detached-head/09-after -->
```text
$ git log --oneline -3
f563b49 Hotfix: reject empty prompts
097e0be Hotfix: cap max_tokens at 4096
f4a81dc Document the endpoints
$ cat validate.py
def validate(req):
    if req.max_tokens > 4096:
        raise TooLarge()
    if not req.prompt.strip():
        raise EmptyPrompt()
$ git status -sb
## main
```
<!-- /snippet -->

### Questions

1. Why does no branch reflog contain the hotfix commits?
2. `git fsck` without options reported nothing in this repository. Why, and what does that tell you about how safe the commits were?
3. In the reflog, what distinguishes the line that ended a detached session from an ordinary switch between branches?
4. `git fsck --no-reflogs` printed two commits, and three were lost. Explain.
5. Why did the cherry-pick of `266d3b2` alone conflict, and how could you have seen that before running it?

## Lab 12.8: Overwritten changes and a cleared stash

### Objective

Run `git reset --hard` over uncommitted work and recover everything that was ever staged from dangling blobs. Prove that the part that was never staged does not exist. Then clear a stash list with two entries and bring both back.

### Prerequisites

- Chapter 13, section 13.9.
- Chapter 5 for what `git add` writes; Chapter 11, sections 11.5 and 11.11.

### Setup

```bash
bash labs/ch13/setup-12-8-overwritten-changes.sh
labs/shell m12-8
```

The script builds `finetune` with uncommitted work in three states: `sweep.yaml` is new and was staged twice, `train.yaml` has a staged change and one more line that is not staged, and `notes.md` is untracked. It also builds `finetune-incident`, a clean repository with two stash entries.

### Commands

Step 1. What is at stake.

```bash
cd finetune
git status -s
git diff --cached --stat
git diff --stat
```

Step 2. The accident.

```bash
git reset --hard
git status -s
ls
cat train.yaml
```

Step 3. Search the object database for content that nothing names.

```bash
git fsck --lost-found
ls .git/lost-found/other
```

Step 4. Identify the blobs by content. They have no names.

```bash
grep -c "" .git/lost-found/other/*
grep -l warmup_ratio .git/lost-found/other/*
grep -l epochs .git/lost-found/other/*
```

Step 5. Restore the two files, once from the lost-found copy and once from the object, and stage them again.

```bash
cp .git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd sweep.yaml
git cat-file -p e4e9197 > train.yaml
cat sweep.yaml train.yaml
git add sweep.yaml train.yaml
git status -s
```

Step 6. Look for the line that was never staged.

```bash
printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' | git hash-object --stdin
git cat-file -t fd0a951
```

### Expected output

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

### What happened internally

- Every `git add` wrote a blob: two for `sweep.yaml` (`0697c1f`, then `e199091`) and one for `train.yaml` (`e4e9197`). The index entry of `sweep.yaml` pointed at the second one.
- `git reset --hard` replaced the index with the tree of HEAD and made the working tree match. `sweep.yaml` is not in HEAD, so its index entry and its file were removed. `train.yaml` was overwritten with the committed version. `notes.md` was untracked and was not touched.
- No blob was deleted. With their index entries gone, nothing refers to the three blobs: they are dangling. `git fsck --lost-found` listed them and wrote their content into files named after their IDs.
- A blob stores content only. The file names were in the index, so you identify the blobs by what they contain: `grep -c ""` counts lines, `grep -l` finds a known word.
- The edit `early_stopping: true` existed only in the working tree file. `git hash-object --stdin` computed the ID that file would have had, and `git cat-file -t` shows that no such object exists.

### Checkpoint

- `git status -s` prints `A  sweep.yaml`, `M  train.yaml` and `?? notes.md`.
- `train.yaml` has two lines and ends with `epochs: 5`. The third line is lost.

### Failure scenario

`finetune-incident` has two stash entries, one made with a message and one without. You decide the list is old and clear it:

```bash
cd ../finetune-incident
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

`git stash clear` prints nothing: no IDs, no confirmation. Both entries are gone from the list.

### Recovery

The stash manual has a recipe for this. Run it as printed, then without its last filter:

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

`--grep=WIP` matches the default message only. The entry that was created with `-m` is named `On main: lora: rank 16 trial` and is found only by the second command. Put both back into the list, oldest first so that the order is as before, and look inside one:

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

### Verification

```bash
git fsck --unreachable
git stash list
git status -s
```

<!-- snippet: ch13/lab-12-8-overwritten-changes/10-verification -->
```text
$ git fsck --unreachable
$ git stash list
stash@{0}: recovered: lora rank 16 trial
stash@{1}: recovered: grad clip
$ git status -s
```
<!-- /snippet -->

Nothing is unreachable any more, the list has two entries, and the working tree is clean.

### Questions

1. Three blobs were dangling after the reset, for two files. Where did the third come from, and what does that tell you about `git add` as a habit?
2. Why can `git fsck --lost-found` give you the content of `sweep.yaml` and not its name?
3. `notes.md` survived the hard reset. Which command would have destroyed it, and would Git have had an object for it?
4. Why did the manual's recipe with `--grep=WIP` find only one of the two entries? Why is `--merges` a good filter for stash entries?
5. Why did the recovery store `a0cbbaf` before `0b0c40d`? What determines which entry is `stash@{0}`?

## Lab 12.9: A wrong cherry-pick

### Objective

Backport the wrong commit to a release branch, undo it by reflog entry, and pick the right one. Then undo a wrong pick with `git reset --hard ORIG_HEAD`, land on a commit from another branch, and find the way back.

### Prerequisites

- Chapter 13, sections 13.5 and 13.8.
- Chapter 10, sections 10.4 and 10.9, for `-x` and the backport workflow.

### Setup

```bash
bash labs/ch13/setup-12-9-wrong-cherry-pick.sh
labs/shell m12-9
```

The script builds `apigw`. `main` has the fix "Fix off-by-one in rate limit window" and, after it, the feature "Add per-tenant quotas", which arrived through a fast-forward merge some time ago. You are on `release/2.1`, which has one commit of its own. `apigw-incident` is the same repository with the wrong commit already picked.

### Commands

Step 1. The situation.

```bash
cd apigw
git status -sb
git log --oneline --graph --all
```

Step 2. The mistake: the newest commit on `main` is not the fix.

```bash
git cherry-pick -x main
git log --oneline -3
git show --stat --format=%B HEAD
```

Step 3. Evidence.

```bash
git reflog -2
git reflog show release/2.1 -2
```

Step 4. Step back one entry, and pick the right commit.

```bash
git reset --keep 'HEAD@{1}'
git log --oneline -2
git cherry-pick -x main~1
```

Step 5. Verify.

```bash
git log --oneline -3
git cherry -v release/2.1 main
ls
```

### Expected output

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/01-start -->
```text
$ cd apigw
$ git status -sb
## release/2.1
$ git log --oneline --graph --all
* e30eec3 Pin dependencies for 2.1
| * cad5d75 Add per-tenant quotas
| * f028350 Fix off-by-one in rate limit window
|/  
* 3171b7b Add request router
* 239cf05 Add rate limiter
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/02-disaster -->
```text
# The fix to backport is "Fix off-by-one in rate limit window". The newest commit on main is not it.
$ git cherry-pick -x main
[release/2.1 1bccf8e] Add per-tenant quotas
 Date: Mon Sep 7 10:08:00 2026 +0530
 2 files changed, 2 insertions(+)
 create mode 100644 quotas.yaml
$ git log --oneline -3
1bccf8e Add per-tenant quotas
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git show --stat --format=%B HEAD
Add per-tenant quotas

(cherry picked from commit cad5d75479789f69b0c584495258e2ad3f7ce87f)


 quotas.yaml | 1 +
 router.py   | 1 +
 2 files changed, 2 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/03-evidence -->
```text
$ git reflog -2
1bccf8e HEAD@{0}: cherry-pick: Add per-tenant quotas
e30eec3 HEAD@{1}: commit: Pin dependencies for 2.1
$ git reflog show release/2.1 -2
1bccf8e release/2.1@{0}: cherry-pick: Add per-tenant quotas
e30eec3 release/2.1@{1}: commit: Pin dependencies for 2.1
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/04-recover -->
```text
$ git reset --keep 'HEAD@{1}'
$ git log --oneline -2
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git cherry-pick -x main~1
[release/2.1 5564cff] Fix off-by-one in rate limit window
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/05-verification -->
```text
$ git log --oneline -3
5564cff Fix off-by-one in rate limit window
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git cherry -v release/2.1 main
- f02835061937dde4e4ec5fdb869bc3c6b2b2c352 Fix off-by-one in rate limit window
+ cad5d75479789f69b0c584495258e2ad3f7ce87f Add per-tenant quotas
$ ls
limiter.py
requirements.txt
router.py
```
<!-- /snippet -->

### What happened internally

- `git cherry-pick -x main` created one new commit on `release/2.1` with the change of `cad5d75` and a line in its message that names the source. It wrote one entry into the HEAD reflog and one into the reflog of the branch. It did not write `ORIG_HEAD`.
- `git reset --keep 'HEAD@{1}'` moved `release/2.1` back to `e30eec3` and removed the two files' changes from the working tree. The wrong commit is now held by the reflog only.
- `git cherry -v release/2.1 main` compares by change: `-` in front of the fix means the release branch has an equivalent commit, `+` in front of the quota feature means it does not. That is the intended state of a release branch.

### Checkpoint

- `git log --oneline -2` shows "Fix off-by-one in rate limit window" on top of `e30eec3`.
- `ls` shows no `quotas.yaml`.

### Failure scenario

In `apigw-incident` the wrong pick is already on the branch. You remember "undo with `ORIG_HEAD`" from merges and resets:

```bash
cd ../apigw-incident
git log --oneline -3
git reset --hard ORIG_HEAD
git log --oneline
git status -sb
ls
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/06-failure -->
```text
$ cd ../apigw-incident
$ git log --oneline -3
48b4def Add per-tenant quotas
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
# The wrong pick is already here. A recipe remembered from the merge chapter:
$ git reset --hard ORIG_HEAD
HEAD is now at f028350 Fix off-by-one in rate limit window
$ git log --oneline
f028350 Fix off-by-one in rate limit window
3171b7b Add request router
239cf05 Add rate limiter
$ git status -sb
## release/2.1
$ ls
limiter.py
router.py
```
<!-- /snippet -->

The branch is still called `release/2.1`, and its tip is the fix. It looks like success. But the history is the history of `main`, the release-only commit "Pin dependencies for 2.1" is gone, and so is `requirements.txt`. `ORIG_HEAD` held `f028350`: the position of `main` before the fast-forward merge that brought in the quota feature.

### Recovery

```bash
git reflog show release/2.1
git reflog -4
git reset --keep 'release/2.1@{2}'
git log --oneline -2
git cherry-pick -x main~1
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/07-recovery-read -->
```text
$ git reflog show release/2.1
f028350 release/2.1@{0}: reset: moving to ORIG_HEAD
48b4def release/2.1@{1}: cherry-pick: Add per-tenant quotas
e30eec3 release/2.1@{2}: commit: Pin dependencies for 2.1
3171b7b release/2.1@{3}: branch: Created from main
$ git reflog -4
f028350 HEAD@{0}: reset: moving to ORIG_HEAD
48b4def HEAD@{1}: cherry-pick: Add per-tenant quotas
e30eec3 HEAD@{2}: commit: Pin dependencies for 2.1
3171b7b HEAD@{3}: checkout: moving from main to release/2.1
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/08-recovery -->
```text
$ git reset --keep 'release/2.1@{2}'
$ git log --oneline -2
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git cherry-pick -x main~1
[release/2.1 b10148a] Fix off-by-one in rate limit window
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The reflog of the branch has four lines, and the one you want is named by its message: `commit: Pin dependencies for 2.1`, the state before the wrong pick.

### Verification

```bash
git log --oneline --graph --all
ls
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/09-after -->
```text
$ git log --oneline --graph --all
* b10148a Fix off-by-one in rate limit window
* e30eec3 Pin dependencies for 2.1
| * cad5d75 Add per-tenant quotas
| * f028350 Fix off-by-one in rate limit window
|/  
* 3171b7b Add request router
* 239cf05 Add rate limiter
$ ls
limiter.py
requirements.txt
router.py
```
<!-- /snippet -->

### Questions

1. Which reflogs did the cherry-pick write to, and which file did it not write?
2. In the failure scenario, which command had written the value that `ORIG_HEAD` held, on which branch, and why was that value still there?
3. After `git reset --hard ORIG_HEAD` the tip of `release/2.1` was the very fix you wanted. List the evidence that the branch was nevertheless wrong.
4. Why does the `-x` line matter for people who review or audit the release branch later?
5. The wrong pick was already pushed and deployed from `release/2.1`. What do you run instead of `git reset`, and what does the history of the release branch look like afterwards?

## Lab 12.10: Broken remote-tracking state, and a corrupt index

### Objective

Diagnose a clone whose remote-tracking refs are wrong in two different ways, by asking the server directly, and rebuild them. Then damage the index file and rebuild it from HEAD without losing a line of work.

### Prerequisites

- Chapter 13, sections 13.10 and 13.11.
- Chapter 12, sections 12.4 and 12.14; Chapter 3, section 3.12, for the index file.

### Setup

```bash
bash labs/ch13/setup-12-10-remote-tracking.sh
labs/shell m12-10
```

The script builds `server.git` and your clone `docsearch`, with two commits on `main` that are not pushed. Two things have gone wrong in the clone, and the server has received a commit from a teammate that you have not seen.

### Commands

Step 1. The symptom: status and push disagree.

```bash
cd docsearch
git status -sb
git push
```

Step 2. Compare what the server says with what your clone believes.

```bash
git ls-remote origin
git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin
```

Step 3. Try the ordinary repair, and let `git fsck` name the problem.

```bash
git fetch
git fsck
```

Step 4. Evidence for each of the two faults.

```bash
wc -c < .git/refs/remotes/origin/feature/hybrid-search
git reflog show origin/main
git log -g --date=iso --format='%gd | %gn | %gs' origin/main
```

Step 5. Repair.

```bash
git update-ref -d refs/remotes/origin/feature/hybrid-search
rm .git/refs/remotes/origin/feature/hybrid-search
git fetch
git status -sb
```

Step 6. Verify against the server.

```bash
git ls-remote origin
git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin
git fsck
git log --oneline --graph main origin/main
```

### Expected output

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

<!-- snippet: ch13/lab-12-10-remote-tracking/06-verification -->
```text
$ git ls-remote origin
e2753886b206a1781cfc9cb9520d36220feeae8e	HEAD
c6ec9d6c4248646f6256680df1f68a2772c1f442	refs/heads/feature/hybrid-search
e2753886b206a1781cfc9cb9520d36220feeae8e	refs/heads/main
$ git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin
e2753886b206a1781cfc9cb9520d36220feeae8e refs/remotes/origin/HEAD
c6ec9d6c4248646f6256680df1f68a2772c1f442 refs/remotes/origin/feature/hybrid-search
e2753886b206a1781cfc9cb9520d36220feeae8e refs/remotes/origin/main
$ git fsck
$ git log --oneline --graph main origin/main
* 5eda6ed Add query cache
* 44f08e7 Add phrase queries
| * e275388 Add synonym expansion
|/  
* 6edd8a2 Add query parser
* e0d7e1d Add inverted index
```
<!-- /snippet -->

### What happened internally

- `git status` compared `refs/heads/main` with `refs/remotes/origin/main`, two local refs with the same value `5eda6ed`, and reported no difference. `git push` asked the server, whose `main` is `e275388`, a commit your clone did not have, and was rejected.
- `git ls-remote` printed the server's refs without changing anything locally. `git for-each-ref` printed the local remote-tracking refs: one with an ID the server does not have, and one that Git cannot read.
- The first `git fetch` downloaded the server's new commit and then stopped at the unreadable ref before it updated anything. That is why `git fsck` lists `e275388` as dangling: the object arrived, and no ref was written.
- The file for `origin/feature/hybrid-search` is empty. `git update-ref -d` must read a ref to delete it and failed, so the file was removed directly.
- The reflog of `origin/main` shows a newest entry with an empty message. Entries written by a fetch or a push carry a message; this one was written by `git update-ref`, which a helper script had used to "synchronise" the ref.
- The second `git fetch` set `origin/main` to the server's value, marked as a forced update because the old value was not an ancestor of the new one, and created the missing ref again.

### Checkpoint

- `git status -sb` prints `## main...origin/main [ahead 2, behind 1]`.
- The lists of `git ls-remote origin` and `git for-each-ref` agree, apart from `origin/HEAD`.
- `git fsck` prints nothing.

### Failure scenario

Create some work, one change staged and one not, and then damage the index file by overwriting its first four bytes, as a failing disk or a syncing tool might:

```bash
printf 'def parse(q):\n    return PHRASE.findall(q.lower().strip())\n' > query.py
git add query.py
printf 'def cached(q):\n    return CACHE.get(q.strip())\n' > cache.py
git status -s
printf 'XXXX' | dd of=.git/index bs=1 conv=notrunc 2>/dev/null
git status
git log --oneline -1
```

<!-- snippet: ch13/lab-12-10-remote-tracking/07-failure -->
```text
$ printf 'def parse(q):\n    return PHRASE.findall(q.lower().strip())\n' > query.py
$ git add query.py
$ printf 'def cached(q):\n    return CACHE.get(q.strip())\n' > cache.py
$ git status -s
 M cache.py
M  query.py
# Simulate a damaged index file: overwrite its first four bytes.
$ printf 'XXXX' | dd of=.git/index bs=1 conv=notrunc 2>/dev/null
$ git status
error: bad signature 0x58585858
fatal: index file corrupt
[exit status: 128]
$ git log --oneline -1
5eda6ed Add query cache
[exit status: 0]
```
<!-- /snippet -->

Every command that needs the index stops with `index file corrupt`. Commands that read only history still work.

### Recovery

Move the damaged file aside and let Git build a new index from HEAD:

```bash
mv .git/index .git/index.corrupt
git status -s
git reset
git status -s
```

<!-- snippet: ch13/lab-12-10-remote-tracking/08-recovery -->
```text
$ mv .git/index .git/index.corrupt
$ git status -s
D  cache.py
D  index.py
D  query.py
?? cache.py
?? index.py
?? query.py
$ git reset
Unstaged changes after reset:
M	cache.py
M	query.py
$ git status -s
 M cache.py
 M query.py
```
<!-- /snippet -->

With no index at all, Git sees every committed file as deleted and every file on disk as untracked. `git reset` writes a new index from the tree of HEAD and does not touch a file in the working tree.

### Verification

```bash
cat query.py
git fsck
git add query.py
git status -s
rm .git/index.corrupt
```

<!-- snippet: ch13/lab-12-10-remote-tracking/09-after -->
```text
$ cat query.py
def parse(q):
    return PHRASE.findall(q.lower().strip())
$ git fsck
dangling blob 93d6b9331161c632d901ef93a7938f6aa97766a9
$ git add query.py
$ git status -s
 M cache.py
M  query.py
$ rm .git/index.corrupt
```
<!-- /snippet -->

Both edits are intact. What the new index could not know is that `query.py` had been staged: both files came back as unstaged. The blob that `git add` had written is still in the object database, and `git fsck` lists it as dangling until you stage the file again.

### Questions

1. Why did `git status` report that the branch was in sync while `git push` was rejected? Which of the two talked to the server?
2. What does an empty reflog message on a remote-tracking ref tell you, and what would the message have been after a fetch or after a push?
3. Why did `git fsck` report a dangling commit after the failed fetch, and why was it gone after the successful one?
4. Remote-tracking refs and the index are both called "derived" in Chapter 13. From what is each one rebuilt, and what was lost when the index was rebuilt?
5. Why is it better to move `.git/index` aside than to delete it, and better to run `git reset` than `git reset --hard`?

## Lab 12.11: A force push, seen from the local side

### Objective

Recognise a force push in the output of `git fetch`, read the lost commits out of the reflog of the remote-tracking ref, and repair the server without a second force push. Then destroy your local copy of the lost commits with a reflexive reset, and recover them.

### Prerequisites

- Chapter 13, section 13.10.
- Chapter 12, section 12.8, for force pushes and leases.

### Setup

```bash
bash labs/ch13/setup-12-11-force-push.sh
labs/shell m12-11
```

The script builds `server.git` and three clones: yours (`askdocs`), `asha` and `ravi`. Asha pushed "Add answer cache", you pulled and pushed "Add cache metrics", and then Ravi, whose clone was two commits behind, pushed "Rename settings keys" with `--force`. You have not fetched since. The directory `incident` holds an independent copy of the server and of your clone for the failure scenario.

### Commands

Step 1. Your clone before it knows.

```bash
cd askdocs
git status -sb
git log --oneline
```

Step 2. Fetch, and read the output.

```bash
git fetch
git status -sb
git log --oneline --graph main origin/main
```

Step 3. The damage report: the server's old value, what was removed, what was put in.

```bash
git reflog show origin/main
git log --format='%h %an: %s' origin/main..'origin/main@{1}'
git log --format='%h %an: %s' 'origin/main@{1}'..origin/main
```

Step 4. Other witnesses: the server and a teammate's clone.

```bash
ls ../server.git
git -C ../server.git reflog list
git -C ../server.git config get core.logAllRefUpdates
git -C ../asha log --oneline -1 origin/main
```

Step 5. Repair: keep Ravi's commit and bring the two lost commits back, with their IDs.

```bash
git merge -m 'Merge origin/main: restore commits removed by a force push' origin/main
git push
```

Step 6. Verify.

```bash
git log --oneline --graph
git status -sb
git log --oneline 'origin/main@{2}'..origin/main
```

### Expected output

<!-- snippet: ch13/lab-12-11-force-push/01-before-fetch -->
```text
$ cd askdocs
$ git status -sb
## main...origin/main
$ git log --oneline
d8a3934 Add cache metrics
2a2bf94 Add answer cache
6955492 Add settings
1203ec5 Add question answering endpoint
```
<!-- /snippet -->

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

<!-- snippet: ch13/lab-12-11-force-push/06-verification -->
```text
$ git log --oneline --graph
*   d967a92 Merge origin/main: restore commits removed by a force push
|\  
| * 882b940 Rename settings keys
* | d8a3934 Add cache metrics
* | 2a2bf94 Add answer cache
|/  
* 6955492 Add settings
* 1203ec5 Add question answering endpoint
$ git status -sb
## main...origin/main
$ git log --oneline 'origin/main@{2}'..origin/main
d967a92 Merge origin/main: restore commits removed by a force push
882b940 Rename settings keys
```
<!-- /snippet -->

### What happened internally

- Before the fetch, `origin/main` was your clone's memory of the last contact, `d8a3934`. The server already had `882b940`.
- The fetch found that the server's `main` is not a descendant of `d8a3934`. The default fetch refspec begins with `+`, so the remote-tracking ref was overwritten anyway, and the output marks that with `+` and `(forced update)`. The old value went into the reflog of `origin/main` as entry 1.
- Your local `main` was not touched. It still holds the two commits that the server lost, so status reports `ahead 2, behind 1`.
- The bare `server.git` has no `logs` directory and no reflog setting. It cannot tell you what `main` was before the force push. Asha's clone has not fetched, so its `origin/main` is still the commit she pushed.
- `git merge origin/main` created a merge commit with your `main` as first parent and Ravi's commit as second parent. The server's tip is an ancestor of that merge, so `git push` was an ordinary fast-forward.

### Checkpoint

- `git status -sb` prints `## main...origin/main`.
- `git log --oneline --graph` shows a merge commit whose two sides are `882b940` and the line `2a2bf94`, `d8a3934`.

### Failure scenario

In the independent copy, react the way many people do when a branch has "diverged from the server":

```bash
cd ../incident/askdocs
git fetch
git status -sb
git reset --hard origin/main
git log --oneline
ls
```

<!-- snippet: ch13/lab-12-11-force-push/07-failure -->
```text
$ cd ../incident/askdocs
$ git fetch
From ../server
 + d8a3934...882b940 main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 2, behind 1]
# A common reaction: make the local branch match the server.
$ git reset --hard origin/main
HEAD is now at 882b940 Rename settings keys
$ git log --oneline
882b940 Rename settings keys
6955492 Add settings
1203ec5 Add question answering endpoint
$ ls
app.py
settings.yaml
```
<!-- /snippet -->

`main` now matches the server, and the two commits are on no branch in this clone. `cache.py` and `cache_metrics.py` are gone from the working tree.

### Recovery

Two reflogs recorded the old value, and they agree:

```bash
git reflog show main -2
git reflog show origin/main -2
git rev-parse 'main@{1}' 'origin/main@{1}'
```

<!-- snippet: ch13/lab-12-11-force-push/08-recovery-read -->
```text
$ git reflog show main -2
882b940 main@{0}: reset: moving to origin/main
d8a3934 main@{1}: commit: Add cache metrics
$ git reflog show origin/main -2
882b940 refs/remotes/origin/main@{0}: fetch: forced-update
d8a3934 refs/remotes/origin/main@{1}: update by push
$ git rev-parse 'main@{1}' 'origin/main@{1}'
d8a3934d8191f6b0a0f2494e04fcae7d15f0460c
d8a3934d8191f6b0a0f2494e04fcae7d15f0460c
```
<!-- /snippet -->

Anchor it, look at it, merge it, push:

```bash
git branch rescue/before-force-push 'origin/main@{1}'
git log --oneline rescue/before-force-push
git merge -m 'Merge the commits removed by a force push' rescue/before-force-push
git push
```

<!-- snippet: ch13/lab-12-11-force-push/09-recovery -->
```text
$ git branch rescue/before-force-push 'origin/main@{1}'
$ git log --oneline rescue/before-force-push
d8a3934 Add cache metrics
2a2bf94 Add answer cache
6955492 Add settings
1203ec5 Add question answering endpoint
$ git merge -m 'Merge the commits removed by a force push' rescue/before-force-push
Merge made by the 'ort' strategy.
 cache.py         | 2 ++
 cache_metrics.py | 2 ++
 2 files changed, 4 insertions(+)
 create mode 100644 cache.py
 create mode 100644 cache_metrics.py
$ git push
To ../server.git
   882b940..98df04c  main -> main
```
<!-- /snippet -->

### Verification

```bash
git log --oneline --graph
git status -sb
ls
git branch -d rescue/before-force-push
```

<!-- snippet: ch13/lab-12-11-force-push/10-after -->
```text
$ git log --oneline --graph
*   98df04c Merge the commits removed by a force push
|\  
| * d8a3934 Add cache metrics
| * 2a2bf94 Add answer cache
* | 882b940 Rename settings keys
|/  
* 6955492 Add settings
* 1203ec5 Add question answering endpoint
$ git status -sb
## main...origin/main
$ ls
app.py
cache_metrics.py
cache.py
settings.yaml
$ git branch -d rescue/before-force-push
Deleted branch rescue/before-force-push (was d8a3934).
```
<!-- /snippet -->

The same three commits are on the server as after the guided repair. The merge commit differs: here Ravi's commit is the first parent, because the merge was made from a branch that already matched the server.

### Questions

1. Which two details in the output of `git fetch` identify a force push, and why did the fetch overwrite `origin/main` although the update was not a fast-forward?
2. What exactly is `origin/main@{1}`, and why does it exist in your clone and not on the server?
3. The lab repaired the damage with a merge. Give the alternative that restores the server's old value exactly, and say when you would choose it.
4. Why would `git pull --rebase` have been a poor repair here, although it also ends with all three commits on `main`?
5. A fourth colleague cloned the repository after the force push. Which of the recovery sources of this lab does her clone have?

## Lab 12.12: Prove the point of no return

### Objective

Take a lost commit down the layers of protection one step at a time, and verify after each step what can still bring it back. Finish by proving, with every tool of this module, that it is gone. Then damage a healthy repository by deleting an object that is still needed, and repair both losses from copies outside the repository.

### Prerequisites

- Chapter 13, sections 13.2, 13.11, 13.13 and 13.14.
- Labs 12.1 and 12.8.

### Setup

```bash
bash labs/ch13/setup-12-12-point-of-no-return.sh
labs/shell m12-12
```

The script builds `featurestore`, in which the commit "Add online store TTL" was removed from `main` with a hard reset, together with a staged file. It also builds `featurestore-backup.bundle`, written while that commit was still on `main`; `teammate`, a clone made after the reset; and `featurestore-damaged`, a copy for the failure scenario.

🔴 This lab runs the two commands that destroy Git's safety net. Run them only in this sandbox.

### Commands

Step 1. The commit is lost from the branch and held by the reflog.

```bash
cd featurestore
git log --oneline
git reflog -2
git cat-file -t 833b96f
git fsck
```

Step 2. Remove the reflog entries. Check what you could still do.

```bash
git reflog expire --expire=now --all
git reflog
git fsck
git log --oneline -1 833b96f
git count-objects -v | grep -e "^count" -e in-pack
```

Step 3. Delete every unreachable object.

```bash
git gc --prune=now
git count-objects -v | grep -e "^count" -e in-pack
git cat-file -t 833b96f
```

Step 4. The proof: try every tool.

```bash
git reflog
git fsck --lost-found
cat .git/ORIG_HEAD
git cat-file -t ORIG_HEAD
git branch rescue/ttl 833b96f
```

### Expected output

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

### What happened internally

- In step 1 the commit `833b96f` was reachable from `HEAD@{1}`. `git fsck` therefore did not list it. It listed one dangling blob: the staged file that the reset threw away.
- `git reflog expire --expire=now --all` emptied the files under `.git/logs`. No object was touched: ten loose objects before and after. The commit became a dangling commit, and it was still fully readable. At this point `git branch rescue/ttl 833b96f` would have saved it.
- `git gc --prune=now` packed the six objects that `main` reaches and deleted the four that nothing reaches: the commit, its tree, its blob and the staged blob.
- After that, no tool has anything to work with. The reflog is empty, `git fsck` finds no unreachable object, and `git branch` cannot create a ref to an ID that names no object. `.git/ORIG_HEAD` still contains the ID, which shows two things: `ORIG_HEAD` is a plain file that nobody tidies, and it is not a starting point that protects an object from collection.

### Checkpoint

- `git cat-file -t 833b96f` fails with `Not a valid object name`.
- `git count-objects -v` reports `count: 0` and `in-pack: 6`.
- `git fsck` prints nothing: the repository is healthy.

### Failure scenario

The second kind of loss. In `featurestore-damaged`, delete an object that the current commit needs, as a failing disk would:

```bash
cd ../featurestore-damaged
git rev-parse HEAD:store.py
rm -f .git/objects/$(git rev-parse HEAD:store.py | sed 's/../&\//')
git status -sb
git show HEAD:store.py
git fsck --name-objects
```

<!-- snippet: ch13/lab-12-12-point-of-no-return/05-failure -->
```text
$ cd ../featurestore-damaged
$ git rev-parse HEAD:store.py
2ef65411041fc138b1cf609d6f52a5a31a8a6011
$ rm -f .git/objects/$(git rev-parse HEAD:store.py | sed 's/../&\//')
$ git status -sb
## main
$ git show HEAD:store.py
fatal: bad object HEAD:store.py
[exit status: 128]
$ git fsck --name-objects
missing blob 2ef65411041fc138b1cf609d6f52a5a31a8a6011 (:store.py)
dangling blob 3d7644e23622f82d93183edaf4e33904b6a09425
[exit status: 2]
```
<!-- /snippet -->

The `sed` expression turns an object ID into the path of its loose file: the first two digits, a slash, the rest. `git status` notices nothing. `git show` fails, and `git fsck` reports `missing blob`, with the path the blob has in the tree. This is not a lost name. A reachable object is gone, and the repository is corrupt.

### Recovery

Both losses have the same answer: a copy outside the repository. For the missing blob, a teammate's clone has the identical object. An ordinary fetch does not transfer it, because your refs claim that you have everything. Ask for the one object explicitly:

```bash
git fetch ../teammate main
git fsck
git rev-parse HEAD:store.py | git -C ../teammate pack-objects --stdout -q | git unpack-objects -q
git fsck
git show HEAD:store.py
```

<!-- snippet: ch13/lab-12-12-point-of-no-return/06-recovery-object -->
```text
$ git fetch ../teammate main
From ../teammate
 * branch            main       -> FETCH_HEAD
[exit status: 0]
$ git fsck
missing blob 2ef65411041fc138b1cf609d6f52a5a31a8a6011
dangling blob 3d7644e23622f82d93183edaf4e33904b6a09425
[exit status: 2]
$ git rev-parse HEAD:store.py | git -C ../teammate pack-objects --stdout -q | git unpack-objects -q
$ git fsck
dangling blob 3d7644e23622f82d93183edaf4e33904b6a09425
[exit status: 0]
$ git show HEAD:store.py
def get(entity, features):
    return online.read(entity, features)
```
<!-- /snippet -->

For the commit that went past the point of no return, the bundle that was written before the reset still has it. A bundle is a remote in a file:

```bash
cd ../featurestore
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

### Verification

```bash
git fsck
git diff --stat main rescue/ttl
git merge --ff-only rescue/ttl
git log --oneline
```

<!-- snippet: ch13/lab-12-12-point-of-no-return/08-verification -->
```text
$ git fsck
$ git diff --stat main rescue/ttl
 ttl.yaml | 1 +
 1 file changed, 1 insertion(+)
$ git merge --ff-only rescue/ttl
Updating b7b5704..833b96f
Fast-forward
 ttl.yaml | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 ttl.yaml
$ git log --oneline
833b96f Add online store TTL
b7b5704 Add feature schema
46ab313 Add feature store client
```
<!-- /snippet -->

The commit is back with the same ID, `833b96f`, because the bundle delivered the same bytes. The staged file `offline.yaml` is not back. It was never committed, so no ref ever reached it, and a bundle holds only what its refs reach.

### Questions

1. After step 2 the commit was still recoverable. With which command, and what would you have needed to know?
2. Step 3 reduced ten loose objects to six packed ones. Name the four objects that were deleted.
3. `.git/ORIG_HEAD` still held the ID after the collection. What does that prove about `ORIG_HEAD` and garbage collection?
4. Why did `git fetch ../teammate main` not repair the missing blob, and why did the pipeline with `git pack-objects` and `git unpack-objects` succeed?
5. The bundle restored the commit and not the staged file. State the rule that explains both.
6. On a real repository with default settings, which events would have had to happen, and after how much time, for this commit to be deleted without anyone typing the two 🔴 commands?

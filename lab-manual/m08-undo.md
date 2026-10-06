# Module 8 labs: Undo with restore, reset, revert, clean and stash

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch11/`. Read [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md) first.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and a replay script that runs the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch11/setup-08-1-reset-prediction.sh    # build the starting state (run again to start over)
labs/shell m08-1                                 # open the isolated lab shell in that sandbox
labs/run ch11/lab-08-1-reset-prediction          # optional: replay the whole lab and print its transcript
```

Type the commands of a lab by hand, and predict before you run.

**Which IDs will match the book.** The setup scripts create their commits with the same fixed clock as the replays, so every commit that exists when you enter the sandbox has the ID printed in this manual. Commits you create yourself (a revert, a merge, an amended commit, a stash entry) get the real time and therefore other IDs. Blob IDs depend only on content and always match.

**A note on the lab clock.** Replays and setup scripts use a fixed clock in the past (7 September 2026) so that commit IDs match the book, and the sandbox configuration sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never` so that reflog entries do not age out, whatever day you run a lab. Real repositories use Git's defaults of 90 and 30 days. Chapter 1, section 1.7 explains the design, and Chapter 13: Recovery covers the defaults.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command to see its exit status.
- Lines that start with `#` are notes from a script, not output of Git.
- `git revert` without `--no-edit` opens your editor with the generated message. Save and close it. Merges do not open an editor in the lab shell, because the lab environment sets `GIT_MERGE_AUTOEDIT=no`. In your own shell they do.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 8.1 | The reset prediction table | `m08-1` | `ch11/lab-08-1-reset-prediction` |
| 8.2 | Revert a pushed commit | `m08-2` | `ch11/lab-08-2-revert-pushed-commit` |
| 8.3 | Revert a merge, then re-merge | `m08-3` | `ch11/lab-08-3-revert-merge-remerge` |
| 8.4 | Restore variants | `m08-4` | `ch11/lab-08-4-restore-variants` |
| 8.5 | Clean safely | `m08-5` | `ch11/lab-08-5-clean-safely` |
| 8.6 | Stash and a pop conflict | `m08-6` | `ch11/lab-08-6-stash-pop-conflict` |
| 8.7 | Scenario cards | `m08-7` | `ch11/lab-08-7-scenario-cards` |

Answers to the Questions of every lab are in [solutions/m08-lab-answers.md](../solutions/m08-lab-answers.md). Write your own answers first.

## Lab 8.1: The reset prediction table

### Objective

Predict, and then verify, what each reset mode does to HEAD, the index and the working tree when all three hold different versions of a file. Then undo a reset with `ORIG_HEAD`, lose `ORIG_HEAD` on purpose, and recover through the reflog.

### Prerequisites

- Chapter 11, sections 11.4 to 11.6.
- Lab 2.1, the three-trees prediction table. This lab runs the same exercise backwards.

### Setup

```bash
bash labs/ch11/setup-08-1-reset-prediction.sh
labs/shell m08-1
```

The script builds the repository `promptlab` and five identical copies, one per reset mode: `promptlab-soft`, `promptlab-mixed`, `promptlab-hard`, `promptlab-keep` and `promptlab-merge`. In each of them `prompt.txt` exists in five versions: v1, v2 and v3 are committed, v4 is staged, and v5 is only on disk. This lab creates no commits, so every ID you see equals the ID in the book.

### Commands

Step 1. Look at the starting state.

```bash
cd promptlab
git log --oneline
git show HEAD:prompt.txt      # the version in HEAD
git show :prompt.txt          # the version in the index
cat prompt.txt                # the version in the working tree
git status -s
```

Step 2. Before you run anything else, fill in this table on paper. Write which version (v1 to v5) each place holds after `git reset <mode> HEAD~1`, and what `git status -s` prints. For the last two modes, also predict whether the command runs at all.

| Mode | HEAD | Index | Working tree | `git status -s` |
|---|---|---|---|---|
| `--soft` | | | | |
| `--mixed` | | | | |
| `--hard` | | | | |
| `--keep` | | | | |
| `--merge` | | | | |

Step 3. Run each mode in its own copy and compare the result with your table.

```bash
cd ../promptlab-soft
git reset --soft HEAD~1
git log --oneline
git show HEAD:prompt.txt
git show :prompt.txt
cat prompt.txt
git status -s

cd ../promptlab-mixed
git reset --mixed HEAD~1
git show HEAD:prompt.txt
git show :prompt.txt
cat prompt.txt
git status -s

cd ../promptlab-hard
git reset --hard HEAD~1
git show HEAD:prompt.txt
git show :prompt.txt
cat prompt.txt
git status -s

cd ../promptlab-keep
git reset --keep HEAD~1
git log --oneline -1
git status -s

cd ../promptlab-merge
git reset --merge HEAD~1
git log --oneline -1
git status -s
```

Step 4. Undo the soft reset with `ORIG_HEAD`.

```bash
cd ../promptlab-soft
git rev-parse --short ORIG_HEAD
git reflog -2
git reset --soft ORIG_HEAD
git log --oneline -1
git status -s
```

### Expected output

The starting state:

<!-- snippet: ch11/lab-08-1-reset-prediction/01-start -->
```text
$ cd promptlab
$ git log --oneline
978507c Refuse when unsure (v3)
60c3e2e Require a citation (v2)
c8cddb6 Add system prompt (v1)
$ git show HEAD:prompt.txt
v3: Answer briefly. Cite the source. Refuse when unsure.
$ git show :prompt.txt
v4: staged, never committed
$ cat prompt.txt
v5: only in the working tree
$ git status -s
MM prompt.txt
```
<!-- /snippet -->

The three modes that run:

<!-- snippet: ch11/lab-08-1-reset-prediction/02-soft -->
```text
$ cd ../promptlab-soft
$ git reset --soft HEAD~1
$ git log --oneline
60c3e2e Require a citation (v2)
c8cddb6 Add system prompt (v1)
$ git show HEAD:prompt.txt
v2: Answer briefly. Cite the source.
$ git show :prompt.txt
v4: staged, never committed
$ cat prompt.txt
v5: only in the working tree
$ git status -s
MM prompt.txt
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-1-reset-prediction/03-mixed -->
```text
$ cd ../promptlab-mixed
$ git reset --mixed HEAD~1
Unstaged changes after reset:
M	prompt.txt
$ git show HEAD:prompt.txt
v2: Answer briefly. Cite the source.
$ git show :prompt.txt
v2: Answer briefly. Cite the source.
$ cat prompt.txt
v5: only in the working tree
$ git status -s
 M prompt.txt
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-1-reset-prediction/04-hard -->
```text
$ cd ../promptlab-hard
$ git reset --hard HEAD~1
HEAD is now at 60c3e2e Require a citation (v2)
$ git show HEAD:prompt.txt
v2: Answer briefly. Cite the source.
$ git show :prompt.txt
v2: Answer briefly. Cite the source.
$ cat prompt.txt
v2: Answer briefly. Cite the source.
$ git status -s
```
<!-- /snippet -->

The two modes that refuse:

<!-- snippet: ch11/lab-08-1-reset-prediction/05-keep -->
```text
$ cd ../promptlab-keep
$ git reset --keep HEAD~1
error: Entry 'prompt.txt' would be overwritten by merge. Cannot merge.
fatal: Could not reset index file to revision 'HEAD~1'.
[exit status: 128]
$ git log --oneline -1
978507c Refuse when unsure (v3)
$ git status -s
MM prompt.txt
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-1-reset-prediction/06-merge -->
```text
$ cd ../promptlab-merge
$ git reset --merge HEAD~1
error: Entry 'prompt.txt' not uptodate. Cannot merge.
fatal: Could not reset index file to revision 'HEAD~1'.
[exit status: 128]
$ git log --oneline -1
978507c Refuse when unsure (v3)
$ git status -s
MM prompt.txt
```
<!-- /snippet -->

The undo with `ORIG_HEAD`:

<!-- snippet: ch11/lab-08-1-reset-prediction/07-orig-head -->
```text
$ cd ../promptlab-soft
$ git rev-parse --short ORIG_HEAD
978507c
$ git reflog -2
60c3e2e HEAD@{0}: reset: moving to HEAD~1
978507c HEAD@{1}: commit: Refuse when unsure (v3)
$ git reset --soft ORIG_HEAD
$ git log --oneline -1
978507c Refuse when unsure (v3)
$ git status -s
MM prompt.txt
```
<!-- /snippet -->

### What happened internally

| Mode | HEAD | Index | Working tree | `git status -s` |
|---|---|---|---|---|
| `--soft` | v2 | v4 | v5 | `MM` |
| `--mixed` | v2 | v2 | v5 | ` M` |
| `--hard` | v2 | v2 | v2 | clean |
| `--keep` | refused: still v3 | v4 | v5 | `MM` |
| `--merge` | refused: still v3 | v4 | v5 | `MM` |

- **`--soft`** moved one ref: it rewrote `.git/refs/heads/main` from `978507c` to `60c3e2e`, wrote the old ID to `.git/ORIG_HEAD`, and appended a line to both reflogs. The index still holds v4, so the first `M` of the status now compares v4 with v2 where it compared v4 with v3 before.
- **`--mixed`** did the same and also rewrote the index from the tree of `60c3e2e`. The staged v4 lost the only thing that named it. Its blob is still in the object database, and the Recovery part of this lab finds it.
- **`--hard`** did all of that and also overwrote `prompt.txt` with v2. v5 existed nowhere but in that file.
- **`--keep` and `--merge`** refused, and nothing moved. Both must rewrite `prompt.txt`, because it differs between v3 and v2, and the file has local changes. This is the first table in the "Discussion" section of the git-reset manual: working tree A, index B, HEAD C, target D, both modes "disallowed". The two messages differ because the two modes protect different things. `--keep` protects every local change and stops at the staged one ("would be overwritten"). `--merge` would discard a staged change without complaint and stops at the unstaged one on top of it ("not uptodate").
- **`ORIG_HEAD`** held `978507c`, the tip before the reset. Resetting to it with `--soft` moved the branch back. The index and the file had never been touched, so the repository is exactly in its starting state again.

### Checkpoint

Check each statement with the command given. If one surprises you, reread section 11.4.

- In `promptlab-mixed`, `git diff --cached` prints nothing, and `git diff` shows v2 against v5.
- In `promptlab-hard`, `git diff HEAD` prints nothing.
- In `promptlab-keep` and `promptlab-merge`, `git log --oneline -1` still shows `978507c`.
- In `promptlab-soft`, `git status -s` prints `MM` and `git log --oneline -1` shows `978507c`, as if nothing had happened.

### Failure scenario

`promptlab-hard` has already been reset once and is at v2. Reset it a second time, then try to get v3 back the way step 4 did:

```bash
cd ../promptlab-hard
git reset --hard HEAD~1
git log --oneline
git reset --hard ORIG_HEAD
git log --oneline
```

<!-- snippet: ch11/lab-08-1-reset-prediction/08-failure -->
```text
$ cd ../promptlab-hard
$ git reset --hard HEAD~1
HEAD is now at c8cddb6 Add system prompt (v1)
$ git log --oneline
c8cddb6 Add system prompt (v1)
$ git reset --hard ORIG_HEAD
HEAD is now at 60c3e2e Require a citation (v2)
$ git log --oneline
60c3e2e Require a citation (v2)
c8cddb6 Add system prompt (v1)
```
<!-- /snippet -->

You wanted v3. You are at v2.

```text
Observed behavior : "git reset --hard ORIG_HEAD" went back one step, not to the commit you remember.
Git state         : main is at 60c3e2e (v2). 978507c (v3) is on no branch.
Mechanism         : Every reset overwrites ORIG_HEAD with the tip it is leaving. The second reset
                    replaced 978507c with 60c3e2e.
Root cause        : ORIG_HEAD is a single slot. It remembers one move.
Why Git does this : It is a shortcut for undoing the last command. The history of moves is the reflog.
Correct fix       : Find the commit in the reflog and reset to that entry.
Prevention        : After more than one move, do not use ORIG_HEAD. Read the reflog.
```

### Recovery

```bash
git reflog
git reset --hard HEAD@{3}
git log --oneline
```

<!-- snippet: ch11/lab-08-1-reset-prediction/09-recovery -->
```text
$ git reflog
60c3e2e HEAD@{0}: reset: moving to ORIG_HEAD
c8cddb6 HEAD@{1}: reset: moving to HEAD~1
60c3e2e HEAD@{2}: reset: moving to HEAD~1
978507c HEAD@{3}: commit: Refuse when unsure (v3)
60c3e2e HEAD@{4}: commit: Require a citation (v2)
c8cddb6 HEAD@{5}: commit (initial): Add system prompt (v1)
$ git reset --hard HEAD@{3}
HEAD is now at 978507c Refuse when unsure (v3)
$ git log --oneline
978507c Refuse when unsure (v3)
60c3e2e Require a citation (v2)
c8cddb6 Add system prompt (v1)
```
<!-- /snippet -->

Choose the entry by its text, `commit: Refuse when unsure (v3)`, not by counting. The three commits are back. Now look for the two versions that were never committed:

```bash
git fsck --lost-found
git cat-file -p 7f9b38a
printf 'v5: only in the working tree\n' | git hash-object --stdin
git cat-file -t 1732b24d8b7877d2e96d0fa80ca928851d408b10
```

<!-- snippet: ch11/lab-08-1-reset-prediction/10-staged-version -->
```text
$ git fsck --lost-found
dangling blob 7f9b38a5ce58fb5df522658178eb46f0f751a1bd
$ git cat-file -p 7f9b38a
v4: staged, never committed
$ printf 'v5: only in the working tree\n' | git hash-object --stdin
1732b24d8b7877d2e96d0fa80ca928851d408b10
$ git cat-file -t 1732b24d8b7877d2e96d0fa80ca928851d408b10
fatal: git cat-file: could not get object info
[exit status: 128]
```
<!-- /snippet -->

v4 was staged, so `git add` had written it as a blob, and `git fsck` finds it. v5 was only ever a file. `git hash-object` computes the ID its content would have, and no object with that ID exists. v5 is gone.

### Verification

```bash
git log --oneline
git status -s
git show HEAD:prompt.txt
```

<!-- snippet: ch11/lab-08-1-reset-prediction/11-verification -->
```text
$ git log --oneline
978507c Refuse when unsure (v3)
60c3e2e Require a citation (v2)
c8cddb6 Add system prompt (v1)
$ git status -s
$ git show HEAD:prompt.txt
v3: Answer briefly. Cite the source. Refuse when unsure.
```
<!-- /snippet -->

Three commits, a clean status, v3 in HEAD.

### Questions

1. `git status -s` printed `MM` before and after `git reset --soft HEAD~1`, although HEAD changed. What does each `M` compare after the reset?
2. `--keep` and `--merge` both refused, with different messages. Describe one state of `prompt.txt` in which `--keep` succeeds, and one in which `--merge` succeeds and silently discards something.
3. After the two hard resets, which command had written the value that `ORIG_HEAD` held, and at which reflog entry was v3?
4. The dangling blob holds v4. Why does it have no file name, and why is there no blob for v5?
5. In your own repository you will have run other commands in between, and `HEAD@{3}` will not be the right entry. How do you choose the right reflog entry without counting?

## Lab 8.2: Revert a pushed commit

### Objective

Undo a commit that is already on `origin/main` by adding a revert commit, push it, and watch a teammate receive it as an ordinary update. Then try the wrong tool, `git reset`, and see the server refuse.

### Prerequisites

- Chapter 11, sections 11.2 and 11.8.
- Chapter 12 (Remote Operations) for remote-tracking branches and push rejections. Lab 7.2 covers a rejected push in depth.

### Setup

```bash
bash labs/ch11/setup-08-2-revert-pushed-commit.sh
labs/shell m08-2
```

The script builds three repositories: `server.git`, a bare repository that plays `origin`; `you`, your clone; and `asha`, a teammate's clone. `origin/main` has three commits. The second one, `6820622 Raise batch size to 512`, is the bad one, and Asha has already built on top of it. Both clones are up to date.

### Commands

Step 1. Establish the facts: what the commit changed, and who has it.

```bash
cd you
git status -sb
git log --format="%h %an: %s"
git show --stat --format='%h %s' 6820622
git branch -r --contains 6820622
```

Step 2. Revert it. Your editor opens with the generated message. Add the reason as a new paragraph at the end, save and close: `Batch 512 exhausts memory on the 16 GB feature workers.`

```bash
git revert --edit 6820622
git show -s --format=%B HEAD
cat store.yaml
```

Step 3. Publish.

```bash
git status -sb
git push
git status -sb
```

Step 4. Become Asha and update.

```bash
cd ../asha
git pull
git log --format="%h %an: %s"
cat store.yaml
```

### Expected output

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/01-investigate -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git log --format="%h %an: %s"
dbd9949 Asha Rao: Add retry to feature fetch
6820622 Lab User: Raise batch size to 512
c98d2c1 Lab User: Add feature-store client
$ git show --stat --format='%h %s' 6820622
6820622 Raise batch size to 512

 store.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -r --contains 6820622
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/02-revert -->
```text
$ git revert --edit 6820622
[main 7c3c467] Revert "Raise batch size to 512"
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show -s --format=%B HEAD
Revert "Raise batch size to 512"

This reverts commit 682062253e7c2d4709951b36c5e5c0a8f29a5b4e.

Batch 512 exhausts memory on the 16 GB feature workers.

$ cat store.yaml
batch_size: 128
timeout_s: 10
```
<!-- /snippet -->

Your revert commit has another ID than `7c3c467`, because you made it at another time. Its message, parent and tree are the same.

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/03-push -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To $LAB/ch11/lab-08-2-revert-pushed-commit/server.git
   dbd9949..7c3c467  main -> main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/04-teammate -->
```text
$ cd ../asha
$ git pull
From $LAB/ch11/lab-08-2-revert-pushed-commit/server
   dbd9949..7c3c467  main       -> origin/main
Updating dbd9949..7c3c467
Fast-forward
 store.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --format="%h %an: %s"
7c3c467 Lab User: Revert "Raise batch size to 512"
dbd9949 Asha Rao: Add retry to feature fetch
6820622 Lab User: Raise batch size to 512
c98d2c1 Lab User: Add feature-store client
$ cat store.yaml
batch_size: 128
timeout_s: 10
```
<!-- /snippet -->

### What happened internally

- `git branch -r --contains 6820622` listed `origin/main`. The commit is shared history, so the rule of section 11.2 applies: add, do not rewrite.
- The revert was a three-way merge. The base was the bad commit `6820622`, "ours" was HEAD (`dbd9949`, Asha's commit), and "theirs" was the parent of the bad commit, `c98d2c1`. Between base and "theirs" only `store.yaml` differs (512 against 128). HEAD has the same `store.yaml` as the base, so the result takes 128. Asha's later change to `client.py` is on "our" side only and stays. There was nothing to conflict.
- The result is one new commit whose parent is `dbd9949`. Nothing was removed: `6820622` is still in the log.
- `git push` moved `refs/heads/main` in `server.git` forward by one commit. For the server this was a fast-forward, like any other push.
- Asha's `git pull` fetched the commit, moved her `origin/main`, and fast-forwarded her `main`. She needed no instructions.

### Checkpoint

- In `you`, `git log --oneline origin/main` lists four commits, and the newest is the revert.
- `git diff c98d2c1 HEAD -- store.yaml` prints nothing: the file is back to its first version.
- In `asha`, `git status -sb` shows no `ahead` and no `behind`.

### Failure scenario

Suppose you had tried to erase the bad commit instead. Asha's commit sits on top of it, so erasing means going back to the first commit:

```bash
cd ../you
git reset --hard c98d2c1
git log --oneline
git push
git status -sb
```

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/05-failure -->
```text
$ cd ../you
$ git reset --hard c98d2c1
HEAD is now at c98d2c1 Add feature-store client
$ git log --oneline
c98d2c1 Add feature-store client
$ git push
To $LAB/ch11/lab-08-2-revert-pushed-commit/server.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ch11/lab-08-2-revert-pushed-commit/server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git status -sb
## main...origin/main [behind 3]
```
<!-- /snippet -->

Your `main` is now an ancestor of `origin/main` (`behind 3`), and the server refuses to move its branch backwards. The only way to make it accept would be a forced push. That would delete three commits from `origin/main`: the bad one, your revert, and Asha's unrelated `Add retry to feature fetch`. Asha's clone would still have all three, and her next push would put them back. Do not run it.

### Recovery

Nothing was published, so recovery is local: put your branch back on the commit that the upstream branch has.

```bash
git reset --hard @{u}
git status -sb
git log --oneline
```

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/06-recovery -->
```text
$ git reset --hard @{u}
HEAD is now at 7c3c467 Revert "Raise batch size to 512"
$ git status -sb
## main...origin/main
$ git log --oneline
7c3c467 Revert "Raise batch size to 512"
dbd9949 Add retry to feature fetch
6820622 Raise batch size to 512
c98d2c1 Add feature-store client
```
<!-- /snippet -->

### Verification

```bash
git diff --stat c98d2c1 HEAD -- store.yaml
git rev-parse HEAD origin/main
git -C ../asha rev-parse HEAD
```

<!-- snippet: ch11/lab-08-2-revert-pushed-commit/07-verification -->
```text
$ git diff --stat c98d2c1 HEAD -- store.yaml
$ git rev-parse HEAD origin/main
7c3c4672764e5c198b097c7835b2ba5b8cf9ccbe
7c3c4672764e5c198b097c7835b2ba5b8cf9ccbe
$ git -C ../asha rev-parse HEAD
7c3c4672764e5c198b097c7835b2ba5b8cf9ccbe
```
<!-- /snippet -->

The diff is empty, and all three refs name the same commit. Your ID differs from the book's, and the three lines must be equal to each other.

### Questions

1. Which three versions of `store.yaml` did Git merge to compute the revert? Why did Asha's commit, which came after the bad one, cause no conflict?
2. Asha's pull printed "Fast-forward". What would have happened if she had had an unpushed commit of her own? Would the revert still have reached her?
3. In the failure scenario, what exactly would `git push --force` have changed on the server? What would Asha's clone have looked like afterwards, and what would her next `git push` have done?
4. `git branch -r --contains 6820622` printed `origin/main`. What does that prove, and what can it not prove?
5. Why was `git reset --hard @{u}` a safe recovery here? Describe a situation in which the same command destroys work.

## Lab 8.3: Revert a merge, then re-merge

### Objective

Revert a merge with `-m 1`, see that merging the same branch again brings nothing, and bring the feature back correctly by reverting the revert. Then make the mistake that production teams make, and repair it.

### Prerequisites

- Chapter 11, section 11.9.
- Chapter 8 (Merge) for merge base and first parent.

### Setup

```bash
bash labs/ch11/setup-08-3-revert-merge-remerge.sh
labs/shell m08-3
```

The repository `pipeline` has a branch `feature/dedup` with two commits that is not merged yet. `main` has one commit of its own, so the merge will create a merge commit.

### Commands

Step 1. Merge the feature.

```bash
cd pipeline
git log --oneline --graph --all
git merge feature/dedup
ls
```

Step 2. The feature turns out to be faulty. Revert the merge. Run the first command to see it fail, and read the parents before you choose `-m`.

```bash
git revert --no-edit HEAD
git show -s --format="%h parents: %p" HEAD
git revert --no-edit -m 1 HEAD
ls
```

Step 3. Predict the output of the next command before you run it.

```bash
git merge feature/dedup
git merge-base main feature/dedup
git rev-parse feature/dedup
```

Step 4. The team fixes the feature with one more commit on the branch.

```bash
git switch feature/dedup
printf 'columns: [id, text, label]\ndedup_threshold: 0.95\n' > schema.yaml
git commit -am "Read the duplicate threshold from the schema"
git switch main
```

Step 5. Bring the feature back: revert the revert, then merge. `main` points at the revert commit, so `HEAD` names it. The transcript uses its ID, `4e16399`, and yours differs.

```bash
git revert --no-edit HEAD
git merge feature/dedup
ls
```

### Expected output

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/01-merge -->
```text
$ cd pipeline
$ git log --oneline --graph --all
* 48485f3 Document the input schema
| * cb65ab5 Run the filter in the pipeline
| * 9255465 Add near-duplicate filter
|/  
* 22b3b69 Add ingestion pipeline
$ git merge feature/dedup
Merge made by the 'ort' strategy.
 dedup.py    | 2 ++
 pipeline.py | 4 +++-
 2 files changed, 5 insertions(+), 1 deletion(-)
 create mode 100644 dedup.py
$ ls
dedup.py
pipeline.py
README.md
schema.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/02-revert-the-merge -->
```text
$ git revert --no-edit HEAD
error: commit a17b6378480e6c2bf7813e568972ae09405346f5 is a merge but no -m option was given.
fatal: revert failed
[exit status: 128]
$ git show -s --format="%h parents: %p" HEAD
a17b637 parents: 48485f3 cb65ab5
$ git revert --no-edit -m 1 HEAD
[main 4e16399] Revert "Merge branch 'feature/dedup'"
 Date: Mon Sep 7 10:15:00 2026 +0530
 2 files changed, 1 insertion(+), 5 deletions(-)
 delete mode 100644 dedup.py
$ ls
pipeline.py
README.md
schema.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/03-remerge-brings-nothing -->
```text
$ git merge feature/dedup
Already up to date.
$ git merge-base main feature/dedup
cb65ab5bae4053008a2f88d22ac15e9867d85a15
$ git rev-parse feature/dedup
cb65ab5bae4053008a2f88d22ac15e9867d85a15
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/04-fix-on-the-branch -->
```text
$ git switch feature/dedup
Switched to branch 'feature/dedup'
$ printf 'columns: [id, text, label]\ndedup_threshold: 0.95\n' > schema.yaml
$ git commit -am "Read the duplicate threshold from the schema"
[feature/dedup b541a5e] Read the duplicate threshold from the schema
 1 file changed, 1 insertion(+)
$ git switch main
Switched to branch 'main'
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/05-revert-the-revert-then-merge -->
```text
$ git revert --no-edit 4e16399
[main d96dc2a] Reapply "Merge branch 'feature/dedup'"
 Date: Mon Sep 7 10:24:00 2026 +0530
 2 files changed, 5 insertions(+), 1 deletion(-)
 create mode 100644 dedup.py
$ git merge feature/dedup
Merge made by the 'ort' strategy.
 schema.yaml | 1 +
 1 file changed, 1 insertion(+)
$ ls
dedup.py
pipeline.py
README.md
schema.yaml
```
<!-- /snippet -->

### What happened internally

- The merge commit has two parents: `48485f3`, the previous tip of `main`, and `cb65ab5`, the tip of the feature. `-m 1` told revert to compute the inverse relative to the first parent, which removes what the feature brought in: `dedup.py` and the change to `pipeline.py`.
- The revert changed files. It did not change the graph. Both feature commits are still ancestors of `main`, which is why `git merge-base main feature/dedup` printed the tip of the feature itself, and why the merge said "Already up to date."
- The revert of the revert, named `Reapply "Merge branch 'feature/dedup'"` by Git, is an ordinary commit with one parent. Its change is the opposite of the revert, so the content of the first merge is back.
- The final merge had a real job again: the merge base is `cb65ab5`, the branch has one commit beyond it, and that commit touches only `schema.yaml`.

### Checkpoint

- `ls` shows `dedup.py`.
- `git log --oneline --first-parent -4` shows, from newest to oldest: a merge, a `Reapply`, a `Revert`, a merge.
- `git log --oneline main..feature/dedup` prints nothing.

### Failure scenario

This is the version of the story that reaches production. Go back to the moment after step 4, when `main` was at the revert and the branch had its fix, and merge without reverting the revert. In the good state, the revert commit is two first-parent steps behind HEAD, so `HEAD~2` names it (the transcript uses its ID).

```bash
git reset --hard HEAD~2
git merge feature/dedup
ls
git grep -n dedup
```

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/06-failure -->
```text
$ git reset --hard 4e16399
HEAD is now at 4e16399 Revert "Merge branch 'feature/dedup'"
$ git merge feature/dedup
Merge made by the 'ort' strategy.
 schema.yaml | 1 +
 1 file changed, 1 insertion(+)
$ ls
pipeline.py
README.md
schema.yaml
$ git grep -n dedup
schema.yaml:2:dedup_threshold: 0.95
```
<!-- /snippet -->

The merge succeeded without a conflict. `main` now has a `dedup_threshold` setting and no `dedup.py`: the fix arrived, the feature did not. No message warned you.

### Recovery

The good merge is still in the reflog. Find the entry `merge feature/dedup` that precedes your reset and return to it. In the transcript that entry is `HEAD@{2}`, commit `2408259`.

```bash
git reflog -4
git reset --hard HEAD@{2}
ls
```

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/07-recovery -->
```text
$ git reflog -4
ee0bcbe HEAD@{0}: merge feature/dedup: Merge made by the 'ort' strategy.
4e16399 HEAD@{1}: reset: moving to 4e16399
2408259 HEAD@{2}: merge feature/dedup: Merge made by the 'ort' strategy.
d96dc2a HEAD@{3}: revert: Reapply "Merge branch 'feature/dedup'"
$ git reset --hard 2408259
HEAD is now at 2408259 Merge branch 'feature/dedup'
$ ls
dedup.py
pipeline.py
README.md
schema.yaml
```
<!-- /snippet -->

### Verification

```bash
git log --oneline --graph
git branch --merged main
git grep -n dedup -- pipeline.py schema.yaml
```

<!-- snippet: ch11/lab-08-3-revert-merge-remerge/08-verification -->
```text
$ git log --oneline --graph
*   2408259 Merge branch 'feature/dedup'
|\  
| * b541a5e Read the duplicate threshold from the schema
* | d96dc2a Reapply "Merge branch 'feature/dedup'"
* | 4e16399 Revert "Merge branch 'feature/dedup'"
* | a17b637 Merge branch 'feature/dedup'
|\| 
| * cb65ab5 Run the filter in the pipeline
| * 9255465 Add near-duplicate filter
* | 48485f3 Document the input schema
|/  
* 22b3b69 Add ingestion pipeline
$ git branch --merged main
  feature/dedup
* main
$ git grep -n dedup -- pipeline.py schema.yaml
pipeline.py:1:from dedup import drop_near_duplicates
schema.yaml:2:dedup_threshold: 0.95
```
<!-- /snippet -->

### Questions

1. Right after the revert, `git merge feature/dedup` said "Already up to date." Name the merge base and explain the message.
2. In the failure scenario the merge changed one file and reported no conflict. Using base, ours and theirs for `dedup.py`, explain why the file did not come back.
3. What is in the diff of the `Reapply` commit, and how many parents does it have?
4. Suppose the team had rebuilt the branch with `git rebase --no-ff` from its starting point instead of adding a fix on top. Which step of this lab would then have been wrong?
5. `git branch --merged main` lists `feature/dedup` in the final state. It also listed it right after the first revert. What does that tell you about using `--merged` to decide whether a feature is live?

## Lab 8.4: Restore variants

### Objective

Use the five forms of `git restore` on one file and say, for each, where the content comes from and where it is written. Bring back a deleted file, and discard one hunk of a file with `-p`. Then run a restore over a whole tree by mistake and find out what can be brought back.

### Prerequisites

- Chapter 11, section 11.3, and Chapter 4, section 4.7.
- Chapter 5 for the hunk prompt of `git add -p`. `git restore -p` uses the same one.

### Setup

```bash
bash labs/ch11/setup-08-4-restore-variants.sh
labs/shell m08-4
```

The script builds `evalsuite` and five identical copies, `evalsuite-1` to `evalsuite-5`. In each of them `rubric.yaml` has a pass mark of 0.80 in HEAD, 0.85 in the index and 0.90 on disk, and the first commit, `HEAD~2`, has 0.60. It also builds `evalsuite-bulk` for the failure scenario and `scorer` for `git restore -p`. This lab creates no commits, so all IDs equal the book's.

### Commands

Step 1. Look at the starting state.

```bash
cd evalsuite
git log --oneline
git show HEAD:rubric.yaml
git show :rubric.yaml
cat rubric.yaml
git status -s
```

Step 2. Fill in the table on paper before you run anything.

| Copy | Command | Index after | File after | `git status -s` |
|---|---|---|---|---|
| `evalsuite-1` | `git restore rubric.yaml` | | | |
| `evalsuite-2` | `git restore --staged rubric.yaml` | | | |
| `evalsuite-3` | `git restore --staged --worktree rubric.yaml` | | | |
| `evalsuite-4` | `git restore --source=HEAD~2 rubric.yaml` | | | |
| `evalsuite-5` | `git restore --source=HEAD~2 --staged --worktree rubric.yaml` | | | |

Step 3. Run each command in its copy, and check the three places after each one.

```bash
cd ../evalsuite-1
git restore rubric.yaml
git show :rubric.yaml
cat rubric.yaml
git status -s

cd ../evalsuite-2
git restore --staged rubric.yaml
git show :rubric.yaml
cat rubric.yaml
git status -s

cd ../evalsuite-3
git restore --staged --worktree rubric.yaml
git show :rubric.yaml
cat rubric.yaml
git status -s

cd ../evalsuite-4
git restore --source=HEAD~2 rubric.yaml
git show :rubric.yaml
cat rubric.yaml
git status -s

cd ../evalsuite-5
git restore --source=HEAD~2 --staged --worktree rubric.yaml
git show :rubric.yaml
cat rubric.yaml
git status -s
git log --oneline -1
```

Step 4. Still in `evalsuite-5`, delete a tracked file and bring it back.

```bash
rm judge.txt
git status -s
git restore judge.txt
git status -s
```

Step 5. `score.py` in `scorer` has two unstaged changes: a debug line and a real fix. Discard only the debug line. Answer `y` to the first hunk and `n` to the second.

```bash
cd ../scorer
git restore -p score.py
git diff
```

### Expected output

<!-- snippet: ch11/lab-08-4-restore-variants/01-start -->
```text
$ cd evalsuite
$ git log --oneline
6b72e01 Add test cases, raise pass mark to 0.80
0c09e07 Add judge prompt, raise pass mark to 0.70
fe011d4 Add grading rubric
$ git show HEAD:rubric.yaml
pass_mark: 0.80
$ git show :rubric.yaml
pass_mark: 0.85
$ cat rubric.yaml
pass_mark: 0.90
$ git status -s
MM rubric.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/02-worktree-from-index -->
```text
$ cd ../evalsuite-1
$ git restore rubric.yaml
$ git show :rubric.yaml
pass_mark: 0.85
$ cat rubric.yaml
pass_mark: 0.85
$ git status -s
M  rubric.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/03-index-from-head -->
```text
$ cd ../evalsuite-2
$ git restore --staged rubric.yaml
$ git show :rubric.yaml
pass_mark: 0.80
$ cat rubric.yaml
pass_mark: 0.90
$ git status -s
 M rubric.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/04-both-from-head -->
```text
$ cd ../evalsuite-3
$ git restore --staged --worktree rubric.yaml
$ git show :rubric.yaml
pass_mark: 0.80
$ cat rubric.yaml
pass_mark: 0.80
$ git status -s
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/05-worktree-from-commit -->
```text
$ cd ../evalsuite-4
$ git restore --source=HEAD~2 rubric.yaml
$ git show :rubric.yaml
pass_mark: 0.85
$ cat rubric.yaml
pass_mark: 0.60
$ git status -s
MM rubric.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/06-both-from-commit -->
```text
$ cd ../evalsuite-5
$ git restore --source=HEAD~2 --staged --worktree rubric.yaml
$ git show :rubric.yaml
pass_mark: 0.60
$ cat rubric.yaml
pass_mark: 0.60
$ git status -s
M  rubric.yaml
$ git log --oneline -1
6b72e01 Add test cases, raise pass mark to 0.80
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/07-deleted-file -->
```text
$ rm judge.txt
$ git status -s
 D judge.txt
M  rubric.yaml
$ git restore judge.txt
$ git status -s
M  rubric.yaml
```
<!-- /snippet -->

In the next transcript the replay script piped the two answers into the command, so each prompt is followed directly by the next hunk. On your terminal Git waits after each prompt.

<!-- snippet: ch11/lab-08-4-restore-variants/08-patch -->
```text
$ cd ../scorer
$ printf 'y\nn\n' | git restore -p score.py
diff --git a/score.py b/score.py
index 9f65fd2..564c708 100644
--- a/score.py
+++ b/score.py
@@ -2,6 +2,7 @@ import json
 
 
 def load(path):
+    print("DEBUG loading", path)
     with open(path) as f:
         return [json.loads(line) for line in f]
 
(1/2) Discard this hunk from worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -16,7 +17,7 @@ def exact_match(pred, gold):
 
 def accuracy(rows):
     hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
-    return hits / len(rows)
+    return hits / max(len(rows), 1)
 
 
 if __name__ == "__main__":
(2/2) Discard this hunk from worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-4-restore-variants/09-patch-result -->
```text
$ git diff
diff --git a/score.py b/score.py
index 9f65fd2..7c6b98d 100644
--- a/score.py
+++ b/score.py
@@ -16,7 +16,7 @@ def exact_match(pred, gold):
 
 def accuracy(rows):
     hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
-    return hits / len(rows)
+    return hits / max(len(rows), 1)
 
 
 if __name__ == "__main__":
```
<!-- /snippet -->

### What happened internally

| Copy | Source | Destination | Index after | File after | `git status -s` |
|---|---|---|---|---|---|
| `evalsuite-1` | index | working tree | 0.85 | 0.85 | `M ` |
| `evalsuite-2` | HEAD | index | 0.80 | 0.90 | ` M` |
| `evalsuite-3` | HEAD | index and working tree | 0.80 | 0.80 | clean |
| `evalsuite-4` | `HEAD~2` | working tree | 0.85 | 0.60 | `MM` |
| `evalsuite-5` | `HEAD~2` | index and working tree | 0.60 | 0.60 | `M ` |

- No command moved a ref or created an object. In every copy HEAD is still `6b72e01`, and no reflog has a new line. That is why a restore has no undo.
- In `evalsuite-1` the 0.90 on disk was overwritten and existed nowhere else. In `evalsuite-2` the staged 0.85 left the index and is on disk nowhere, because the file says 0.90. Its blob still exists, unnamed.
- In `evalsuite-4` the status is `MM` because both comparisons differ: the index (0.85) against HEAD (0.80), and the file (0.60) against the index.
- `rm judge.txt` deleted a file and nothing else. The index entry still named the blob, and `git restore judge.txt` wrote the blob back to disk.
- `git restore -p` computed the difference between the index and the file, split it into two hunks, and wrote the index version back for the hunk you answered with `y`.

### Checkpoint

- In every copy, `git log --oneline -1` shows `6b72e01`.
- In `evalsuite-2`, `git fsck --lost-found` reports one dangling blob, and `git cat-file -p` on its ID prints `pass_mark: 0.85`.
- In `scorer`, `git diff` shows the `max(len(rows), 1)` change and no `DEBUG` line.

### Failure scenario

In `evalsuite-bulk` you have improved the judge prompt and not staged it yet. You want `rubric.yaml` as it was in the first commit, and you type `.` where you meant the file name:

```bash
cd ../evalsuite-bulk
git status -s
git diff
git restore --source=HEAD~2 .
git status -s
ls
```

<!-- snippet: ch11/lab-08-4-restore-variants/10-failure -->
```text
$ cd ../evalsuite-bulk
$ git status -s
 M judge.txt
$ git diff
diff --git a/judge.txt b/judge.txt
index 4d49fa2..d6d6e2f 100644
--- a/judge.txt
+++ b/judge.txt
@@ -1 +1 @@
-You are a strict grader. Reply PASS or FAIL.
+You are a strict grader. Reply PASS or FAIL, then one sentence of reasoning.
$ git restore --source=HEAD~2 .
$ git status -s
 D cases.jsonl
 D judge.txt
 M rubric.yaml
$ ls
rubric.yaml
```
<!-- /snippet -->

Two files are deleted and one is changed. The pathspec `.` named every tracked path, and the default mode of restore makes the destination match the source exactly: the first commit contained only `rubric.yaml`, so the other tracked files were removed.

### Recovery

The index was not written (there was no `--staged`), so it still describes the last commit. Restore everything from it:

```bash
git restore .
git status -s
ls
cat judge.txt
```

<!-- snippet: ch11/lab-08-4-restore-variants/11-recovery -->
```text
$ git restore .
$ git status -s
$ ls
cases.jsonl
judge.txt
rubric.yaml
$ cat judge.txt
You are a strict grader. Reply PASS or FAIL.
```
<!-- /snippet -->

All three files are back, in the version of the index. Read `judge.txt`: the sentence you had added, "then one sentence of reasoning", is not there. It was an unstaged edit, the first restore overwrote it, and no command brings it back.

### Verification

```bash
git status -s
git diff --stat HEAD
git fsck
```

<!-- snippet: ch11/lab-08-4-restore-variants/12-verification -->
```text
$ git status -s
$ git diff --stat HEAD
$ git fsck
```
<!-- /snippet -->

All three commands print nothing. The tree is clean, and `git fsck` has no dangling blob to offer, because the lost sentence was never staged.

### Questions

1. For each of the five commands of step 3, name the source and the destination without looking at the table.
2. After `git restore --staged rubric.yaml` in `evalsuite-2`, where is the 0.85 version, and how would you get it back?
3. `git restore --source=HEAD~2 rubric.yaml` left the status `MM`. What does each letter compare, and which versions are involved?
4. Why did `git restore --source=HEAD~2 .` delete two files? Which option of `git restore` would have left them alone?
5. After the recovery, `git fsck` is silent. Why can nothing bring the lost sentence back, and which single command before the mistake would have made it recoverable?

## Lab 8.5: Clean safely

### Objective

Read the dry runs of `git clean` until you can predict them, and remove only what can be regenerated. Then run the "pristine tree" command that many answers recommend, and prove that Git cannot give back what it deleted.

### Prerequisites

- Chapter 11, section 11.10.
- Chapter 4, sections 4.3 (tracked, untracked, ignored) and 4.14 (`git clean`).

### Setup

```bash
bash labs/ch11/setup-08-5-clean-safely.sh
labs/shell m08-5
```

The repository `trainer` has a committed skeleton (`train.py`, `config.yaml`, `.gitignore`, `.env.example`) and a working tree full of files that Git does not track: a notebook, a results file, a debug file, a vendored repository, and several ignored paths. This lab creates no commits.

### Commands

Step 1. See everything that is not tracked.

```bash
cd trainer
git status -s --ignored
```

Step 2. Fill in the table on paper. The `.gitignore` is five lines long, so read it with `cat .gitignore`.

| Path | Untracked or ignored? | Can it be regenerated? | Should a cleanup remove it? |
|---|---|---|---|
| `__pycache__/` | | | |
| `run.log` | | | |
| `data/` (holds `data/cache/`) | | | |
| `.env` | | | |
| `checkpoints/` | | | |
| `notebooks/` | | | |
| `results/` | | | |
| `tmp_debug.txt` | | | |
| `third_party/` | | | |

Step 3. Run `git clean` without options, and then the four dry runs. Predict each list before you press Enter.

```bash
git clean
git clean -n
git clean -n -d
git clean -n -d -X
git clean -n -d -x
```

Step 4. Remove what can be regenerated: the ignored paths, without `.env` and `checkpoints/`, and the one debug file by name. Each real run is preceded by its dry run.

```bash
git clean -n -d -X -e '!.env' -e '!checkpoints/'
git clean -f -d -X -e '!.env' -e '!checkpoints/'
git clean -n tmp_debug.txt
git clean -f tmp_debug.txt
git status -s --ignored
```

### Expected output

<!-- snippet: ch11/lab-08-5-clean-safely/01-status -->
```text
$ cd trainer
$ git status -s --ignored
?? notebooks/
?? results/
?? third_party/
?? tmp_debug.txt
!! .env
!! __pycache__/
!! checkpoints/
!! data/
!! run.log
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-5-clean-safely/02-refused -->
```text
$ git clean
fatal: clean.requireForce is true and -f not given: refusing to clean
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-5-clean-safely/03-dry-runs -->
```text
$ git clean -n
Would remove tmp_debug.txt
$ git clean -n -d
Would remove notebooks/
Would remove results/
Would skip repository third_party/tokenizer
Would remove tmp_debug.txt
$ git clean -n -d -X
Would remove .env
Would remove __pycache__/
Would remove checkpoints/
Would remove data/
Would remove run.log
$ git clean -n -d -x
Would remove .env
Would remove __pycache__/
Would remove checkpoints/
Would remove data/
Would remove notebooks/
Would remove results/
Would remove run.log
Would skip repository third_party/tokenizer
Would remove tmp_debug.txt
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-5-clean-safely/04-targeted -->
```text
$ git clean -n -d -X -e '!.env' -e '!checkpoints/'
Would remove __pycache__/
Would remove data/
Would remove run.log
$ git clean -f -d -X -e '!.env' -e '!checkpoints/'
Removing __pycache__/
Removing data/
Removing run.log
$ git clean -n tmp_debug.txt
Would remove tmp_debug.txt
$ git clean -f tmp_debug.txt
Removing tmp_debug.txt
$ git status -s --ignored
?? notebooks/
?? results/
?? third_party/
!! .env
!! checkpoints/
```
<!-- /snippet -->

### What happened internally

- In the status, `??` marks untracked paths and `!!` marks ignored ones. Both kinds have no index entry, so Git holds no object for any of them.
- `git clean` without `-f`, `-n` or `-i` refuses to run, because `clean.requireForce` defaults to true.
- Plain `-n` lists untracked files in the current directory only. `-d` adds untracked directories. `-X` lists only what the ignore rules match. `-x` does not use the ignore rules at all and lists everything without an index entry.
- `third_party/tokenizer` is a repository of its own. Clean skips it unless `-f` is given twice.
- `-e <pattern>` adds a pattern to the ignore rules for this one run. A pattern that starts with `!` takes paths out of the ignored set, so with `-e '!.env' -e '!checkpoints/'` those two do not count as ignored, and `-X`, which removes only ignored paths, leaves them alone.
- Nothing under `.git` changed in this lab. Clean reads the index and the ignore rules and deletes files. It writes no object, moves no ref and keeps no record.

### Checkpoint

- `git status -s --ignored` lists `notebooks/`, `results/` and `third_party/` as untracked, and `.env` and `checkpoints/` as ignored. Nothing else.
- `git status -s -uno` prints nothing: no tracked file was touched.
- You can say which dry run preceded each of the two real runs.

### Failure scenario

A build fails with a stale cache. A much-copied answer says: get a pristine tree.

```bash
git clean -f -d -x
git status -s --ignored
ls -A
```

<!-- snippet: ch11/lab-08-5-clean-safely/05-failure -->
```text
$ git clean -f -d -x
Removing .env
Removing checkpoints/
Removing notebooks/
Removing results/
Skipping repository third_party/tokenizer
$ git status -s --ignored
?? third_party/
$ ls -A
.env.example
.git
.gitignore
config.yaml
third_party
train.py
```
<!-- /snippet -->

The cache is gone, and so are `.env` with the local token, the checkpoint, the notebook and the results file. Only the nested repository survived.

### Recovery

First establish what Git can give back:

```bash
git fsck
printf 'TRACKING_TOKEN=local-dev-only\nDATA_ROOT=/data/corpus\n' | git hash-object --stdin
git cat-file -t 7c1ea6ccf37927d05649eba390e0f9ef87b4cd9d
cp .env.example .env
cat .env
```

<!-- snippet: ch11/lab-08-5-clean-safely/06-recovery -->
```text
$ git fsck
$ printf 'TRACKING_TOKEN=local-dev-only\nDATA_ROOT=/data/corpus\n' | git hash-object --stdin
7c1ea6ccf37927d05649eba390e0f9ef87b4cd9d
$ git cat-file -t 7c1ea6ccf37927d05649eba390e0f9ef87b4cd9d
fatal: git cat-file: could not get object info
[exit status: 128]
$ cp .env.example .env
$ cat .env
TRACKING_TOKEN=
DATA_ROOT=
```
<!-- /snippet -->

`git fsck` is silent, and the ID that the content of `.env` would have names no object. Git never had these files. What remains is rebuilding: `.env` from its committed template, with values that you must obtain again; the checkpoint by training again; the notebook and the results from a backup, if one exists.

### Verification

```bash
git status -s --ignored
git status -s
```

<!-- snippet: ch11/lab-08-5-clean-safely/07-verification -->
```text
$ git status -s --ignored
?? third_party/
!! .env
$ git status -s
?? third_party/
```
<!-- /snippet -->

### Questions

1. Which of the four dry runs list `.env`, and why exactly those?
2. `third_party/tokenizer` was skipped by every run. What would it take to delete it, and why does Git make that harder?
3. Explain how `-e '!.env'` changed the result of `-X`.
4. After the failure, `git status -s` is nearly empty and `git fsck` reports nothing. Why are these two facts not good news?
5. A release build needs a pristine tree. Which clean command would you allow in a CI job, which on a developer laptop, and what avoids cleaning altogether?

## Lab 8.6: Stash and a pop conflict

### Objective

Stash work that exists in three forms (staged, unstaged, untracked), pop it after a hotfix has changed the same line, resolve the conflict and drop the entry. Then lose a stash entry under pressure and get it back.

### Prerequisites

- Chapter 11, section 11.11.
- Chapter 8 (Merge) for conflict markers and index stages.

### Setup

```bash
bash labs/ch11/setup-08-6-stash-pop-conflict.sh
labs/shell m08-6
```

The script builds `gateway`, with work in progress on per-tenant rate limits: a staged change to `router.py`, an unstaged change to `limits.yaml`, and an untracked `notes.md`. It also builds `gateway-incident` for the failure scenario: the same repository after the work was stashed and a hotfix was committed. In `gateway` the IDs of your stash entry and your hotfix commit differ from the book's. In `gateway-incident` all IDs match.

### Commands

Step 1. An incident comes in. Park the work, all three forms of it.

```bash
cd gateway
git status -s
git stash push -u -m "wip: per-tenant limits"
git status -s
git stash list
git stash show --include-untracked
```

Step 2. Commit the hotfix. It changes the line that your parked work also changes.

```bash
printf 'requests_per_minute: 30\nburst: 10\n' > limits.yaml
git commit -am "Hotfix: throttle to 30 rpm during the incident"
```

Step 3. Bring the work back, and inspect what you get.

```bash
git stash pop
git status -s
cat limits.yaml
git stash list
```

Step 4. Resolve: keep the hotfix value of 30 and your new `per_tenant` line. Mark the file as resolved and drop the entry yourself.

```bash
printf 'requests_per_minute: 30\nburst: 10\nper_tenant: true\n' > limits.yaml
git add limits.yaml
git status -s
git stash drop
git stash list
```

### Expected output

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/01-stash -->
```text
$ cd gateway
$ git status -s
 M limits.yaml
M  router.py
?? notes.md
$ git stash push -u -m "wip: per-tenant limits"
Saved working directory and index state On main: wip: per-tenant limits
$ git status -s
$ git stash list
stash@{0}: On main: wip: per-tenant limits
$ git stash show --include-untracked
 limits.yaml | 3 ++-
 notes.md    | 1 +
 router.py   | 2 +-
 3 files changed, 4 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/02-hotfix -->
```text
$ printf 'requests_per_minute: 30\nburst: 10\n' > limits.yaml
$ git commit -am "Hotfix: throttle to 30 rpm during the incident"
[main 132065e] Hotfix: throttle to 30 rpm during the incident
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/03-pop-conflict -->
```text
$ git stash pop
Auto-merging limits.yaml
CONFLICT (content): Merge conflict in limits.yaml
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   router.py

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

The stash entry is kept in case you need it again.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/04-conflict-state -->
```text
$ git status -s
UU limits.yaml
M  router.py
?? notes.md
$ cat limits.yaml
<<<<<<< Updated upstream
requests_per_minute: 30
=======
requests_per_minute: 120
>>>>>>> Stashed changes
burst: 10
per_tenant: true
$ git stash list
stash@{0}: On main: wip: per-tenant limits
```
<!-- /snippet -->

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/05-resolve-and-drop -->
```text
$ printf 'requests_per_minute: 30\nburst: 10\nper_tenant: true\n' > limits.yaml
$ git add limits.yaml
$ git status -s
M  limits.yaml
M  router.py
?? notes.md
$ git stash drop
Dropped refs/stash@{0} (0b6017bc03df82287741442bb314937900f484f6)
$ git stash list
```
<!-- /snippet -->

### What happened internally

- `git stash push -u` created three commits and one ref. The stash commit records your tracked files, and its first parent is the commit you were on. Its second parent records the index, and its third parent holds the untracked `notes.md`. `refs/stash` points at the stash commit. Then Git reset the tracked files and the index to HEAD and removed `notes.md` from disk. `git log --oneline --graph 'stash@{0}'` shows the shape.
- The hotfix moved `main` by one commit. The stash entry is still based on the old commit.
- `git stash pop` merged three versions: the base is the commit the entry was made on, "ours" is your files as they are now, and "theirs" is the stash commit. `router.py` was changed only by the entry and merged cleanly. Line 1 of `limits.yaml` was changed by both sides, 30 against 120, and conflicted. The `per_tenant` line was added only by the entry and merged cleanly below the conflict. `notes.md` came back as an untracked file.
- `router.py` is staged although you did not pass `--index`. The pop stopped in the middle of a merge, and a merge puts every cleanly merged path into the index.
- Because the pop did not finish, the entry was kept. `git add limits.yaml` replaced the three conflict stages with your resolution, and `git stash drop` removed the entry by hand. From that moment the three stash commits were unreachable.

### Checkpoint

- `git stash list` prints nothing.
- `git status -s` shows `limits.yaml` and `router.py` as staged and `notes.md` as untracked.
- `limits.yaml` holds 30 requests per minute and `per_tenant: true`.

### Failure scenario

`gateway-incident` is at the moment before step 3: the work is stashed and the hotfix is committed. This time the pop conflicts while people are waiting for you. You throw the conflicted state away, and you tidy up the stash list, believing that the pop had delivered the work.

```bash
cd ../gateway-incident
git stash list
git stash pop
git reset --hard
git stash drop
git stash list
git status -s
```

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/06-failure -->
```text
$ cd ../gateway-incident
$ git stash list
stash@{0}: On main: wip: per-tenant limits
$ git stash pop
Auto-merging limits.yaml
CONFLICT (content): Merge conflict in limits.yaml
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   router.py

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

The stash entry is kept in case you need it again.
[exit status: 1]
$ git reset --hard
HEAD is now at 7982811 Hotfix: throttle to 30 rpm during the incident
$ git stash drop
Dropped refs/stash@{0} (3e0cea035f7be6eb3d829fe3a7490bd0265e7929)
$ git stash list
$ git status -s
?? notes.md
```
<!-- /snippet -->

`git reset --hard` deleted the half-merged files, which was harmless as long as the entry existed. `git stash drop` then removed the entry. The staged and the unstaged work are on no branch, in no stash, and not on disk. Only `notes.md` is left, because a reset does not touch untracked files.

### Recovery

`git stash drop` printed the ID of the commit it let go of. If that line is still on your screen, you have what you need. If it is not, the stash manual offers a recipe that lists unreachable commits that look like stash entries:

```bash
git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
```

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/07-recovery-find -->
```text
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
3e0cea0 On main: wip: per-tenant limits
```
<!-- /snippet -->

Put the commit back into the stash list, and look at the untracked file it carries:

```bash
git stash store -m 'recovered: per-tenant limits' 3e0cea0
git stash list
git show 'stash@{0}^3:notes.md'
cat notes.md
rm notes.md
```

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/08-recovery-store -->
```text
$ git stash store -m 'recovered: per-tenant limits' 3e0cea0
$ git stash list
stash@{0}: recovered: per-tenant limits
$ git show 'stash@{0}^3:notes.md'
Per-tenant limits: decide the default quota.
$ cat notes.md
Per-tenant limits: decide the default quota.
$ rm notes.md
```
<!-- /snippet -->

The `notes.md` that the failed pop left on disk is identical to the one in the entry, so it can be removed. It must be: Git never overwrites an existing untracked file when it restores a stash. If you skip the `rm`, the next command still creates the branch and applies the tracked changes, then reports `notes.md already exists, no checkout`, keeps the entry and exits with status 1.

The chapter's demo `ch11/stash-untracked-trap` shows the same refusal with `git stash pop`, in two steps. An entry made with `-u` is popped onto a file that has a local edit. The pop is refused, and it writes the untracked file of the entry anyway:

<!-- snippet: ch11/stash-untracked-trap/01-refused-but-not-untouched -->
```text
$ git stash show --include-untracked
 limits.yaml | 2 +-
 notes.md    | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git status -s
 M limits.yaml
$ git stash pop
error: Your local changes to the following files would be overwritten by merge:
	limits.yaml
Please commit your changes or stash them before you merge.
Aborting
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
$ git status -s
 M limits.yaml
?? notes.md
```
<!-- /snippet -->

With the local edit out of the way, the second pop applies the tracked change and refuses the untracked file, because it now exists:

<!-- snippet: ch11/stash-untracked-trap/02-half-applied -->
```text
$ git restore limits.yaml
$ git stash pop
notes.md already exists, no checkout
error: could not restore untracked files from stash
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
$ git status -s
 M limits.yaml
?? notes.md
$ git stash list
stash@{0}: On main: wip: per-tenant limits
```
<!-- /snippet -->

Both times the entry stayed in the list, although after the second pop all of its content is on disk. Compare before you drop such an entry by hand:

<!-- snippet: ch11/stash-untracked-trap/03-compare-then-drop -->
```text
# Tracked part: the working tree against the stash commit. No output means identical.
$ git diff 'stash@{0}' -- limits.yaml
# Untracked part: it lives in the third parent of the stash commit.
$ git show 'stash@{0}^3:notes.md' | diff - notes.md
[exit status: 0]
$ git stash drop
Dropped refs/stash@{0} (0907588c369b90c4d2f36bbac3e020f15c62e4e3)
```
<!-- /snippet -->

Back to the lab.

With `notes.md` removed, apply the entry where it cannot conflict, on a branch at the commit it was made on:

```bash
git stash branch wip/per-tenant-limits
```

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/09-recovery-apply -->
```text
$ git stash branch wip/per-tenant-limits
Switched to a new branch 'wip/per-tenant-limits'
On branch wip/per-tenant-limits
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   router.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

Dropped refs/stash@{0} (3e0cea035f7be6eb3d829fe3a7490bd0265e7929)
```
<!-- /snippet -->

### Verification

```bash
git status -s
git log --oneline --decorate --all
git stash list
```

<!-- snippet: ch11/lab-08-6-stash-pop-conflict/10-verification -->
```text
$ git status -s
 M limits.yaml
M  router.py
?? notes.md
$ git log --oneline --decorate --all
7982811 (main) Hotfix: throttle to 30 rpm during the incident
086271a (HEAD -> wip/per-tenant-limits) Add request router and rate limits
$ git stash list
```
<!-- /snippet -->

All three forms of the work are back in their original state: staged, unstaged, untracked. The branch `wip/per-tenant-limits` sits on the commit before the hotfix. Commit the work there, and merge or rebase it onto `main` when the incident is over.

### Questions

1. After `git stash push -u`, where exactly were the three pieces of work: the staged change to `router.py`, the unstaged change to `limits.yaml`, and `notes.md`?
2. In the conflict, what do the labels `Updated upstream` and `Stashed changes` refer to, and which three versions of `limits.yaml` did Git merge?
3. Why was `router.py` staged after the conflicted pop although you did not pass `--index`?
4. In the failure scenario, which command destroyed what? Was anything lost before `git stash drop` ran?
5. The recipe found the entry with `git log --merges`. Why is a stash entry a merge commit, and under which conditions does the recipe find nothing?

## Lab 8.7: Scenario cards

### Objective

Practise the decision, not the commands. For six situations: establish the facts, choose between restore, reset, revert, clean and stash, justify the choice, perform it, and verify the result.

### Prerequisites

- All of Chapter 11, in particular sections 11.2, 11.12 and 11.13.
- Labs 8.1 to 8.6.

### Setup

```bash
bash labs/ch11/setup-08-7-scenario-cards.sh
labs/shell m08-7
```

The script builds six repositories, `card-1` to `card-6`. Cards 1 to 3 have a bare repository next to them that plays `origin`, so "pushed" and "not pushed" can be checked. The commits that exist at the start have the book's IDs. The commits you create have your own.

### Commands

For every card: read the situation, run the inspection commands, and fill in this worksheet before you touch anything. Then perform your undo and verify it. The model solutions are in "Expected output". Cover them until you have your own.

| Worksheet | Your answer |
|---|---|
| 1. Is the history involved private or shared? Which output proves it? | |
| 2. Which places must change: working tree, index, branch ref, history? | |
| 3. What must not be lost? | |
| 4. Which command? Why not its neighbours? | |
| 5. How will you verify the result? | |

**Card 1.** Three commits named `wip`, `wip 2` and `fix typo` sit on top of what is pushed. The reviewer wants one commit with a proper message. No change may be lost.

```bash
cd card-1
git status -sb
git log --oneline
git diff --stat @{u} HEAD
```

**Card 2.** The commit `Set temperature to 1.5` is on `origin/main` and broke the evaluation. The later commit `Raise max_tokens to 1024` is good and must stay.

```bash
cd ../card-2
git status -sb
git log --oneline
git branch -r --contains HEAD~1
```

**Card 3.** Your last commit is not pushed. It contains `outputs/predictions.jsonl`, a generated file that went in by accident. The commit should contain only the code change. The file must stay on disk, and it must not be committed again.

```bash
cd ../card-3
git status -sb
git show --stat --format="%h %s" HEAD
```

**Card 4.** `prompts/system.txt` must go back to the version of the first commit. The other changes of the last two commits must stay, and history must not be rewritten.

```bash
cd ../card-4
git log --oneline --stat
git show HEAD~2:prompts/system.txt
```

**Card 5.** A minute ago you merged `feature/cache` into `main`. It was too early. Nothing is pushed. Your uncommitted edit to `notes.md` must survive.

```bash
cd ../card-5
git status -s
git log --oneline --graph -4
git log --oneline -1 ORIG_HEAD
```

**Card 6.** Experiments everywhere: a staged change, an unstaged change, an untracked file and an untracked directory. All of it is to be thrown away. The ignored `.env` must survive.

```bash
cd ../card-6
git status -s --ignored
```

### Expected output

Card 1: private history, so the branch may move. `--soft` keeps the combined change staged.

<!-- snippet: ch11/lab-08-7-scenario-cards/01-card-1 -->
```text
$ cd card-1
$ git status -sb
## main...origin/main [ahead 3]
$ git log --oneline
2ac04c1 fix typo
d40ae05 wip 2
fd9fc58 wip
5535f6c Add metrics module
$ git reset --soft @{u}
$ git status -s
M  metrics.py
A  test_metrics.py
$ git commit -m "Add F1 metric with a test"
[main 22b22b1] Add F1 metric with a test
 2 files changed, 7 insertions(+)
 create mode 100644 test_metrics.py
$ git log --oneline
22b22b1 Add F1 metric with a test
5535f6c Add metrics module
```
<!-- /snippet -->

Card 2: shared history, so a commit is added.

<!-- snippet: ch11/lab-08-7-scenario-cards/02-card-2 -->
```text
$ cd ../card-2
$ git log --oneline
ba17304 Raise max_tokens to 1024
c769739 Set temperature to 1.5
37459c8 Add generation config
$ git branch -r --contains c769739
  origin/main
$ git revert --no-edit c769739
Auto-merging gen.yaml
[main 4089b4d] Revert "Set temperature to 1.5"
 Date: Mon Sep 7 10:43:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat gen.yaml
temperature: 0.2
top_p: 0.95
stop: []
max_tokens: 1024
$ git push
To $LAB/ch11/lab-08-7-scenario-cards/card-2-origin.git
   ba17304..4089b4d  main -> main
```
<!-- /snippet -->

Card 3: private history, last commit: amend.

<!-- snippet: ch11/lab-08-7-scenario-cards/03-card-3 -->
```text
$ cd ../card-3
$ git status -sb
## main...origin/main [ahead 1]
$ git show --stat --format="%h %s" HEAD
f787015 Log token counts per request

 infer.py                  | 4 +++-
 outputs/predictions.jsonl | 2 ++
 2 files changed, 5 insertions(+), 1 deletion(-)
$ git rm --cached outputs/predictions.jsonl
rm 'outputs/predictions.jsonl'
$ printf 'outputs/\n' > .gitignore
$ git add .gitignore
$ git commit --amend --no-edit
[main bda52e4] Log token counts per request
 Date: Mon Sep 7 10:15:00 2026 +0530
 2 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 .gitignore
$ git show --stat --format="%h %s" HEAD
bda52e4 Log token counts per request

 .gitignore | 1 +
 infer.py   | 4 +++-
 2 files changed, 4 insertions(+), 1 deletion(-)
$ git status -s --ignored
!! outputs/
```
<!-- /snippet -->

Card 4: one file from an old commit, recorded as a new commit.

<!-- snippet: ch11/lab-08-7-scenario-cards/04-card-4 -->
```text
$ cd ../card-4
$ git log --oneline
ece8f48 Add refusal rule and a README
b0e52b1 Tighten the system prompt, add calculator tool
76a1f62 Add system prompt and tool list
$ git restore --source=HEAD~2 prompts/system.txt
$ git status -s
 M prompts/system.txt
$ git commit -am "Restore the original system prompt"
[main e81513a] Restore the original system prompt
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat HEAD~3 HEAD
 README.md  | 1 +
 tools.yaml | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

Card 5: a local merge, with an edit to keep.

<!-- snippet: ch11/lab-08-7-scenario-cards/05-card-5 -->
```text
$ cd ../card-5
$ git status -s
 M notes.md
$ git log --oneline --graph -4
*   781e07c Merge branch 'feature/cache'
|\  
| * 88864f7 Cache embeddings on disk
* | 61cd319 Pin the embedding model version
|/  
* 96519f7 Add retrieval service
$ git reset --merge ORIG_HEAD
$ git log --oneline --graph -3
* 61cd319 Pin the embedding model version
* 96519f7 Add retrieval service
$ git status -s
 M notes.md
```
<!-- /snippet -->

Card 6: tracked changes with restore, untracked files with clean, dry run first.

<!-- snippet: ch11/lab-08-7-scenario-cards/06-card-6 -->
```text
$ cd ../card-6
$ git status -s --ignored
M  agent.py
 M tools.py
?? debug.txt
?? scratch/
!! .env
$ git restore --staged --worktree .
$ git clean -n -d
Would remove debug.txt
Would remove scratch/
$ git clean -f -d
Removing debug.txt
Removing scratch/
$ git status -s --ignored
!! .env
```
<!-- /snippet -->

### What happened internally

- **Card 1.** `@{u}` is `origin/main`, commit `5535f6c`. `git reset --soft @{u}` moved `main` there and left the index as it was: the tree of `fix typo`, which is the sum of the three commits. One `git commit` recorded that tree on top of `5535f6c`. The three `wip` commits are off the branch and still in the reflog.
- **Card 2.** The revert was a three-way merge with the bad commit as base. `Auto-merging gen.yaml` appears because HEAD had also changed that file since. The two changes are on different lines (the temperature on line 1, `max_tokens` on line 4), so they merged without conflict: the temperature is 0.2 again and `max_tokens` is still 1024. The push was a fast-forward.
- **Card 3.** `git rm --cached` removed the index entry and left the file. The new `.gitignore` makes Git stop offering it. `git commit --amend` replaced `f787015` with a new commit that has the same parent and contains `infer.py` and `.gitignore`. The file is on disk and ignored.
- **Card 4.** `git restore --source=HEAD~2 prompts/system.txt` wrote the old content into the working tree only. `git commit -am` recorded it as a new change. No commit was removed, and the last command shows that, compared with the first commit, only `README.md` and `tools.yaml` differ now.
- **Card 5.** The merge had written `ORIG_HEAD`, and nothing had overwritten it. `git reset --merge ORIG_HEAD` moved `main` back to `61cd319`, removed the file that the merge had brought, and kept the unstaged edit to `notes.md`, which the merge had not touched.
- **Card 6.** `git restore --staged --worktree .` set the index and every tracked file to HEAD. `git clean -n -d` listed the untracked file and directory and not `.env`, because ignored paths are only cleaned with `-x` or `-X`. Then the same command ran with `-f`.

### Checkpoint

| Card | Check | Expected |
|---|---|---|
| 1 | `git log --oneline`, `git status -sb` | two commits; `ahead 1` |
| 2 | `git log --oneline origin/main -1`, `cat gen.yaml` | a `Revert "Set temperature to 1.5"` commit; temperature 0.2 and `max_tokens` 1024 |
| 3 | `git show --stat --format=%s HEAD`, `ls outputs` | the commit lists `.gitignore` and `infer.py` only; the file is still on disk |
| 4 | `git diff HEAD~3 HEAD -- prompts/system.txt`, `git log --oneline` | no output; four commits |
| 5 | `git log --oneline -1`, `git status -s` | `61cd319`; ` M notes.md` |
| 6 | `git status -s --ignored` | `!! .env` and nothing else |

### Failure scenario

Back to card 1. You want to change the message of the new commit and reach for reset. Under time pressure you type `--hard` where you meant `--soft`:

```bash
cd ../card-1
git log --oneline
git reset --hard HEAD~1
git status -s
ls
```

<!-- snippet: ch11/lab-08-7-scenario-cards/07-failure -->
```text
$ cd ../card-1
$ git log --oneline
22b22b1 Add F1 metric with a test
5535f6c Add metrics module
$ git reset --hard HEAD~1
HEAD is now at 5535f6c Add metrics module
$ git status -s
$ ls
metrics.py
```
<!-- /snippet -->

With `--soft` the change would be staged now. With `--hard` the status is clean and `test_metrics.py` is gone from disk.

### Recovery

The reset was the last command that moved HEAD, so `ORIG_HEAD` still names the commit:

```bash
git reset --hard ORIG_HEAD
git log --oneline
ls
```

<!-- snippet: ch11/lab-08-7-scenario-cards/08-recovery -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at 22b22b1 Add F1 metric with a test
$ git log --oneline
22b22b1 Add F1 metric with a test
5535f6c Add metrics module
$ ls
metrics.py
test_metrics.py
```
<!-- /snippet -->

Nothing was lost, because everything had been committed. Had the tree held uncommitted edits, the hard reset would have destroyed them, and `ORIG_HEAD` would have brought back the commit only. To change a message, the command is `git commit --amend`.

### Verification

```bash
git status -sb
git diff --stat @{u} HEAD
```

<!-- snippet: ch11/lab-08-7-scenario-cards/09-verification -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git diff --stat @{u} HEAD
 metrics.py      | 3 +++
 test_metrics.py | 4 ++++
 2 files changed, 7 insertions(+)
```
<!-- /snippet -->

### Questions

1. For each card, name the command a hurried colleague might have reached for, and say what it would have destroyed or broken.
2. Card 1: what can `git rebase -i @{u}` do that `git reset --soft @{u}` cannot?
3. Card 2: the revert printed `Auto-merging gen.yaml` and did not conflict, although a later commit had changed the same file. Why?
4. Card 3: the old commit `f787015` still contains the generated file. From where can it still be reached, and when would that matter?
5. Card 4: under which condition would `git revert` have done the same job as `git restore --source` followed by a commit?
6. Card 5: why was `ORIG_HEAD` still valid? Name two commands that would have invalidated it.

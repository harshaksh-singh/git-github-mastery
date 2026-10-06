# Module 4 labs: Refs, branches, HEAD, and detached HEAD

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch07/`. Read [Chapter 7: Branches](../textbook/ch07-branches.md) first.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and a replay script that runs the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch07/setup-04-1-refs-by-hand.sh    # build the starting state (run again to start over)
labs/shell m04-1                             # open the isolated lab shell in that sandbox
labs/run ch07/lab-04-1-refs-by-hand          # optional: replay the whole lab and print its transcript
```

Type the commands of a lab by hand, and predict before you run.

**Which IDs will match the book.** The setup scripts create their commits with the same fixed clock as the replays, so every commit that exists when you enter the sandbox has the ID printed here. Labs 4.1, 4.3 and 4.4 create no commits, so every ID in them matches the book. In Lab 4.2 the two commits you make yourself get other IDs; the manual says where to substitute yours.

**The lab clock.** Replays and setup scripts use a fixed clock in the past (7 September 2026), and the sandbox configuration they write sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never`. The lab shell uses the real clock, and its configuration carries the same two settings; none of these labs runs `git gc`. In Labs 4.1, 4.3 and 4.4 the only lines that differ from the book are the timestamps inside the raw reflog lines that Lab 4.1 prints.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command to see its exit status.
- Lines that start with `#` are notes from a script, not output of Git.
- `git switch --detach` and `git checkout <tag>` print a long advice block the first time in a repository; the replays show it in full once, in Chapter 7.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 4.1 | Refs by hand | `m04-1` | `ch07/lab-04-1-refs-by-hand` |
| 4.2 | Detached HEAD rescue | `m04-2` | `ch07/lab-04-2-detached-head-rescue` |
| 4.3 | The `feature` versus `feature/x` conflict | `m04-3` | `ch07/lab-04-3-df-conflict` |
| 4.4 | Counting divergence | `m04-4` | `ch07/lab-04-4-divergence` |

Answers to the Questions of every lab are in [solutions/m04-lab-answers.md](../solutions/m04-lab-answers.md). Write your own answers first.

## Lab 4.1: Refs by hand

### Objective

Read, create, move and delete a branch with plumbing only, and compare each step with what the porcelain shows. Move HEAD alone and watch `git status` change. Then corrupt a ref file by hand and repair it from its reflog.

### Prerequisites

- Chapter 7, sections 7.2 and 7.3.
- Chapter 3 for the layout of `.git`.

### Setup

```bash
bash labs/ch07/setup-04-1-refs-by-hand.sh
labs/shell m04-1
```

The script builds `evalkit` with three commits on `main`. This lab creates no commits, so every ID you see equals the ID in the book.

### Commands

Step 1. Read where you are, through the file and through plumbing.

```bash
cd evalkit
git log --oneline
cat .git/HEAD
git symbolic-ref HEAD
cat .git/refs/heads/main
git rev-parse HEAD
```

Step 2. Create a branch with `git update-ref`, at the second commit.

```bash
git update-ref refs/heads/exp/prompt-v2 HEAD~1
git branch -v
cat .git/refs/heads/exp/prompt-v2
```

Step 3. Move it with a compare-and-swap: the third argument is the value the ref must currently have. Predict which of the two commands fails.

```bash
git update-ref -m 'lab: advance to the tip of main' refs/heads/exp/prompt-v2 HEAD HEAD~1
git update-ref -m 'lab: a second writer with stale information' refs/heads/exp/prompt-v2 HEAD~2 HEAD~1
git branch -v
```

Step 4. Do the same move with porcelain and read the reflog that both wrote.

```bash
git branch -f exp/prompt-v2 HEAD~2
git reflog show exp/prompt-v2
```

Step 5. Move HEAD alone, without touching the index or the working tree.

```bash
git symbolic-ref HEAD refs/heads/exp/prompt-v2
git status --short
git symbolic-ref HEAD refs/heads/main
git status --short
```

Step 6. Delete the branch with plumbing.

```bash
git update-ref -d refs/heads/exp/prompt-v2
git branch -v
ls .git/logs/refs/heads
```

### Expected output

<!-- snippet: ch07/lab-04-1-refs-by-hand/01-read -->
```text
$ git log --oneline
7aecf06 Add batch runner
69d8252 Add exact-match metric
6eab4a9 Add README
$ cat .git/HEAD
ref: refs/heads/main
$ git symbolic-ref HEAD
refs/heads/main
$ cat .git/refs/heads/main
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
$ git rev-parse HEAD
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-1-refs-by-hand/02-create -->
```text
$ git update-ref refs/heads/exp/prompt-v2 HEAD~1
$ git branch -v
  exp/prompt-v2 69d8252 Add exact-match metric
* main          7aecf06 Add batch runner
$ cat .git/refs/heads/exp/prompt-v2
69d82526af97115a79ad14d198c1ba24c22d5fb9
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-1-refs-by-hand/03-compare-and-swap -->
```text
$ git update-ref -m 'lab: advance to the tip of main' refs/heads/exp/prompt-v2 HEAD HEAD~1
$ git update-ref -m 'lab: a second writer with stale information' refs/heads/exp/prompt-v2 HEAD~2 HEAD~1
fatal: update_ref failed for ref 'refs/heads/exp/prompt-v2': cannot lock ref 'refs/heads/exp/prompt-v2': is at 7aecf069859aa045bb7e47a6b1fb0693f7c3da7f but expected 69d82526af97115a79ad14d198c1ba24c22d5fb9
[exit status: 128]
$ git branch -v
  exp/prompt-v2 7aecf06 Add batch runner
* main          7aecf06 Add batch runner
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-1-refs-by-hand/04-porcelain -->
```text
$ git branch -f exp/prompt-v2 HEAD~2
$ git reflog show exp/prompt-v2
6eab4a9 exp/prompt-v2@{0}: branch: Reset to HEAD~2
7aecf06 exp/prompt-v2@{1}: lab: advance to the tip of main
69d8252 exp/prompt-v2@{2}: 
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-1-refs-by-hand/05-head-only -->
```text
$ git symbolic-ref HEAD refs/heads/exp/prompt-v2
$ git status --short
A  evalkit/metrics.py
A  evalkit/runner.py
$ git symbolic-ref HEAD refs/heads/main
$ git status --short
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-1-refs-by-hand/06-delete -->
```text
$ git update-ref -d refs/heads/exp/prompt-v2
$ git branch -v
* main 7aecf06 Add batch runner
$ ls .git/logs/refs/heads
main
```
<!-- /snippet -->

### What happened internally

- `git update-ref refs/heads/exp/prompt-v2 HEAD~1` resolved `HEAD~1` to `69d8252` and wrote that ID into a new file `.git/refs/heads/exp/prompt-v2`, after checking that the object exists and is a commit. Because `core.logAllRefUpdates` is true in a non-bare repository, it also created the branch's reflog, with an empty message: the third reflog line in step 4 ends after the colon.
- The three-argument form is a compare-and-swap. The first call found the ref at `69d8252`, as expected, and moved it to `7aecf06`. The second call expected `69d8252` again, found `7aecf06`, and refused without touching anything. Porcelain uses the same lock-and-compare mechanism, which is why two commands cannot corrupt a ref by racing.
- `git branch -f` wrote the same kind of update and the reflog line `branch: Reset to HEAD~2`. Plumbing and porcelain produced one reflog.
- `git symbolic-ref HEAD refs/heads/exp/prompt-v2` changed the text in `.git/HEAD` and nothing else. `git status` compares the commit HEAD names (`6eab4a9`, with only `README.md`) against the index (still the content of `main`), and reports two staged additions. Switching HEAD back makes the report empty again.
- `git update-ref -d` deleted the ref and its reflog; `ls .git/logs/refs/heads` lists only `main`.

### Checkpoint

- `git branch -v` lists only `main`, at `7aecf06`.
- `cat .git/HEAD` prints `ref: refs/heads/main`.
- `git status --short` prints nothing.

### Failure scenario

Recreate the branch, move it once, then write garbage into its file, as a careless script or an editor might:

```bash
git branch exp/prompt-v2 HEAD~1
git update-ref -m 'lab: advance to the tip of main' refs/heads/exp/prompt-v2 HEAD
echo 'oops' > .git/refs/heads/exp/prompt-v2
git branch -v
git log --oneline --all
git refs verify
```

<!-- snippet: ch07/lab-04-1-refs-by-hand/07-failure -->
```text
$ git branch exp/prompt-v2 HEAD~1
$ git update-ref -m 'lab: advance to the tip of main' refs/heads/exp/prompt-v2 HEAD
$ echo 'oops' > .git/refs/heads/exp/prompt-v2
$ git branch -v
warning: ignoring broken ref refs/heads/exp/prompt-v2
* main 7aecf06 Add batch runner
$ git log --oneline --all
fatal: bad object refs/heads/exp/prompt-v2
[exit status: 128]
$ git refs verify
error: refs/heads/exp/prompt-v2: badRefContent: oops
[exit status: 255]
```
<!-- /snippet -->

One broken ref makes `git log --all` fail outright, because `--all` includes every ref and one of them names no object. `git refs verify` names the ref and the bad content.

### Recovery

`git update-ref` refuses to write over a broken ref, but the branch's reflog is intact and its last line names the last good value. Read it, remove the broken file, and recreate the ref with plumbing so that the reflog continues:

```bash
git update-ref refs/heads/exp/prompt-v2 HEAD
cat .git/logs/refs/heads/exp/prompt-v2
good=$(awk 'END {print $2}' .git/logs/refs/heads/exp/prompt-v2); echo "$good"
rm .git/refs/heads/exp/prompt-v2
git update-ref -m 'lab: restore after corruption' refs/heads/exp/prompt-v2 "$good"
```

<!-- snippet: ch07/lab-04-1-refs-by-hand/08-recovery -->
```text
$ git update-ref refs/heads/exp/prompt-v2 HEAD
fatal: update_ref failed for ref 'refs/heads/exp/prompt-v2': cannot lock ref 'refs/heads/exp/prompt-v2': unable to resolve reference 'refs/heads/exp/prompt-v2': reference broken
[exit status: 128]
$ cat .git/logs/refs/heads/exp/prompt-v2
0000000000000000000000000000000000000000 69d82526af97115a79ad14d198c1ba24c22d5fb9 Lab User <you@example.com> 1788756960 +0530	branch: Created from HEAD~1
69d82526af97115a79ad14d198c1ba24c22d5fb9 7aecf069859aa045bb7e47a6b1fb0693f7c3da7f Lab User <you@example.com> 1788757020 +0530	lab: advance to the tip of main
$ good=$(awk 'END {print $2}' .git/logs/refs/heads/exp/prompt-v2); echo "$good"
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
$ rm .git/refs/heads/exp/prompt-v2
$ git update-ref -m 'lab: restore after corruption' refs/heads/exp/prompt-v2 "$good"
```
<!-- /snippet -->

Each raw reflog line is `<old-id> <new-id> <who> <when>\t<message>`; the second field of the last line is the value the ref had before the corruption. Your two timestamps differ from the book's, because the lab shell uses the real clock.

### Verification

```bash
git branch -v
git reflog show exp/prompt-v2
git refs verify
git log --oneline --all
```

<!-- snippet: ch07/lab-04-1-refs-by-hand/09-verify -->
```text
$ git branch -v
  exp/prompt-v2 7aecf06 Add batch runner
* main          7aecf06 Add batch runner
$ git reflog show exp/prompt-v2
7aecf06 exp/prompt-v2@{0}: lab: restore after corruption
7aecf06 exp/prompt-v2@{1}: lab: advance to the tip of main
69d8252 exp/prompt-v2@{2}: branch: Created from HEAD~1
$ git refs verify
[exit status: 0]
$ git log --oneline --all
7aecf06 Add batch runner
69d8252 Add exact-match metric
6eab4a9 Add README
```
<!-- /snippet -->

The branch is back at `7aecf06`, its reflog has the restore as its newest line, and `git refs verify` is silent.

### Questions

1. Step 2 created a reflog with an empty message, while `git branch` writes `branch: Created from ...`. What does this tell you about where reflog messages come from?
2. Explain the three-argument form of `git update-ref`. Which production problem does the check protect against, and what would happen without it when two processes update the same branch?
3. After `git symbolic-ref HEAD refs/heads/exp/prompt-v2`, `git status` showed two files as staged additions. Which two things did it compare, and why did the working tree not change?
4. The broken ref made `git log --oneline --all` fail but `git branch -v` only warn. Which operations in a real repository would the broken ref have blocked, and which would have continued to work?
5. Why did the recovery delete the file with `rm` and then use `git update-ref` instead of writing the good ID into the file with `echo`? Name two things the plumbing command did that `echo` would not.

## Lab 4.2: Detached HEAD rescue

### Objective

Detach HEAD at a tag, make two commits there, switch away and watch them vanish from every listing. Find them in the reflog and give them a branch. Then rescue the wrong commit by trusting `HEAD@{1}` blindly, and recover by searching the reflog for what you need.

### Prerequisites

- Chapter 7, sections 7.3 and 7.7.
- Chapter 6, section 6.7, for reflogs and dangling commits.

### Setup

```bash
bash labs/ch07/setup-04-2-detached-head-rescue.sh
labs/shell m04-2
```

The script builds `evalkit` with three commits on `main` and the lightweight tag `v0.1.0` on the second one, `b01a3f1`.

### Commands

Step 1. Detach HEAD at the tag.

```bash
cd evalkit
git switch --detach v0.1.0
git status
cat .git/HEAD
```

Step 2. Experiment: two commits that change the judge threshold.

```bash
printf 'judge_model: judge-v1\nthreshold: 0.8\n' > configs/eval.yaml
git commit -am "Experiment: stricter judge threshold"
printf 'judge_model: judge-v1\nthreshold: 0.9\n' > configs/eval.yaml
git commit -am "Experiment: threshold 0.9"
```

Step 3. Leave, and read the warning.

```bash
git switch main
```

Step 4. Look for the two commits.

```bash
git log --oneline --all
git reflog
```

Step 5. Rescue them by giving the newer one a branch.

```bash
git branch rescue/judge-threshold 'HEAD@{1}'
git log --oneline --graph --all
```

### Expected output

<!-- snippet: ch07/lab-04-2-detached-head-rescue/01-detach -->
```text
$ git switch --detach v0.1.0
HEAD is now at b01a3f1 Add exact-match metric
$ git status
HEAD detached at v0.1.0
nothing to commit, working tree clean
$ cat .git/HEAD
b01a3f163c939b93bd0754e7ca95653dda249b4c
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-2-detached-head-rescue/02-commit -->
```text
$ printf 'judge_model: judge-v1\nthreshold: 0.8\n' > configs/eval.yaml
$ git commit -am "Experiment: stricter judge threshold"
[detached HEAD b05f89a] Experiment: stricter judge threshold
 1 file changed, 1 insertion(+), 1 deletion(-)
$ printf 'judge_model: judge-v1\nthreshold: 0.9\n' > configs/eval.yaml
$ git commit -am "Experiment: threshold 0.9"
[detached HEAD 5ff0417] Experiment: threshold 0.9
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Your two commit IDs differ from `b05f89a` and `5ff0417`; use yours wherever the book shows them from here on.

<!-- snippet: ch07/lab-04-2-detached-head-rescue/03-leave -->
```text
$ git switch main
Warning: you are leaving 2 commits behind, not connected to
any of your branches:

  5ff0417 Experiment: threshold 0.9
  b05f89a Experiment: stricter judge threshold

If you want to keep them by creating a new branch, this may be a good time
to do so with:

 git branch <new-branch-name> 5ff0417

Switched to branch 'main'
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-2-detached-head-rescue/04-find -->
```text
$ git log --oneline --all
2daf400 Add batch runner
b01a3f1 Add exact-match metric
7f5f11a Add README and eval config
$ git reflog
2daf400 HEAD@{0}: checkout: moving from 5ff041787895bc079ad6308eeac4baf44e1bc86d to main
5ff0417 HEAD@{1}: commit: Experiment: threshold 0.9
b05f89a HEAD@{2}: commit: Experiment: stricter judge threshold
b01a3f1 HEAD@{3}: checkout: moving from main to v0.1.0
2daf400 HEAD@{4}: commit: Add batch runner
b01a3f1 HEAD@{5}: commit: Add exact-match metric
7f5f11a HEAD@{6}: commit (initial): Add README and eval config
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-2-detached-head-rescue/05-rescue -->
```text
$ git branch rescue/judge-threshold 'HEAD@{1}'
$ git log --oneline --graph --all
* 5ff0417 Experiment: threshold 0.9
* b05f89a Experiment: stricter judge threshold
| * 2daf400 Add batch runner
|/  
* b01a3f1 Add exact-match metric
* 7f5f11a Add README and eval config
```
<!-- /snippet -->

### What happened internally

- `git switch --detach v0.1.0` wrote the raw ID `b01a3f1...` into `.git/HEAD` and updated the index and working tree to that commit. No branch was involved.
- Each commit in detached state wrote a new commit object and updated `.git/HEAD` itself to the new ID. No file under `refs/heads/` changed; only `logs/HEAD` grew.
- `git switch main` wrote `ref: refs/heads/main` into `.git/HEAD`. At that moment nothing under `refs/` named the two commits any more, which is what the warning says. `git log --all` includes HEAD and every ref, and none of them reaches the experiments, so they are not listed.
- The HEAD reflog kept them: `HEAD@{1}` is the newer experiment and `HEAD@{2}` the older. `git branch rescue/judge-threshold 'HEAD@{1}'` wrote that ID into a new ref, and the commits are reachable again; `--graph` shows them as a branch off `v0.1.0`.

### Checkpoint

- `git log --oneline --graph --all` shows two lines of development that join at `b01a3f1`.
- `git branch --contains rescue/judge-threshold` lists `rescue/judge-threshold`.
- `git status` reports `On branch main` and a clean working tree.

### Failure scenario

Delete the rescue branch and repeat the detour, this time without committing. Then apply the same recipe, `HEAD@{1}`, from memory:

```bash
git branch -D rescue/judge-threshold
git switch --detach v0.1.0
git switch main
git branch rescue/judge-threshold 'HEAD@{1}'
git log --oneline -1 rescue/judge-threshold
```

<!-- snippet: ch07/lab-04-2-detached-head-rescue/06-failure -->
```text
$ git branch -D rescue/judge-threshold
Deleted branch rescue/judge-threshold (was 5ff0417).
$ git switch --detach v0.1.0
HEAD is now at b01a3f1 Add exact-match metric
$ git switch main
Previous HEAD position was b01a3f1 Add exact-match metric
Switched to branch 'main'
$ git branch rescue/judge-threshold 'HEAD@{1}'
$ git log --oneline -1 rescue/judge-threshold
b01a3f1 Add exact-match metric
```
<!-- /snippet -->

The branch points at `b01a3f1`, the tag's commit, because `HEAD@{1}` means "where HEAD was one movement ago", and the latest movement was the harmless detour. The experiments are further down the reflog now. A recipe that names a reflog position is only right immediately after the movement it assumes.

### Recovery

Search the reflog for the commits you want instead of counting positions. `git log -g` walks the reflog, and `--grep-reflog` filters by the reflog message:

```bash
git log -g --grep-reflog='commit: Experiment' --format='%h %gd %gs'
git branch -f rescue/judge-threshold <ID of "Experiment: threshold 0.9" from the previous command>
git log --oneline main..rescue/judge-threshold
```

<!-- snippet: ch07/lab-04-2-detached-head-rescue/07-recovery -->
```text
$ git log -g --grep-reflog='commit: Experiment' --format='%h %gd %gs'
5ff0417 HEAD@{3} commit: Experiment: threshold 0.9
b05f89a HEAD@{4} commit: Experiment: stricter judge threshold
$ git branch -f rescue/judge-threshold 5ff0417
$ git log --oneline main..rescue/judge-threshold
5ff0417 Experiment: threshold 0.9
b05f89a Experiment: stricter judge threshold
```
<!-- /snippet -->

In the replay the ID was `5ff0417`; type the ID that your own first command printed on its first line. `%gd` prints the reflog selector of each hit, so you can also see how far down the experiments have moved.

### Verification

```bash
git branch --contains <the same ID>
git log --oneline --graph --all
git fsck --no-reflogs
```

<!-- snippet: ch07/lab-04-2-detached-head-rescue/08-verify -->
```text
$ git branch --contains 5ff0417
  rescue/judge-threshold
$ git log --oneline --graph --all
* 5ff0417 Experiment: threshold 0.9
* b05f89a Experiment: stricter judge threshold
| * 2daf400 Add batch runner
|/  
* b01a3f1 Add exact-match metric
* 7f5f11a Add README and eval config
$ git fsck --no-reflogs
```
<!-- /snippet -->

The rescue branch contains the experiment, the graph is the same as after the first rescue, and `git fsck --no-reflogs` finds no dangling commit: every commit in the repository is reachable from a ref again.

### Questions

1. Why was the experiment allowed at all? What does Git gain by letting you commit without a current branch?
2. After `git switch main`, which file in `.git` still referred to the experiment commits, and which command reads it?
3. The warning printed `git branch <new-branch-name> 5ff0417`. Would `git tag keep-this 5ff0417` have worked as well? What would be different afterwards?
4. In the failure scenario, `HEAD@{1}` pointed at the tag's commit. Write the reflog entries, newest first, as they were at that moment, and mark the one the recipe should have used.
5. Reflog entries expire. In an ordinary repository, how long would the experiment commits have stayed recoverable by this method, and which configuration keys decide that?

## Lab 4.3: The `feature` versus `feature/x` conflict

### Objective

See the ref-name rule that a name cannot be both a ref and a prefix of other refs, first locally and then in the form that reaches a whole team: a stale remote-tracking ref makes `git fetch` fail until it is pruned.

### Prerequisites

- Chapter 7, sections 7.10 and 7.12.
- Chapter 12 for `git fetch`; this lab uses only its basic form.

### Setup

```bash
bash labs/ch07/setup-04-3-df-conflict.sh
labs/shell m04-3
```

The script builds three repositories under the sandbox: `origin.git`, a bare repository that plays the server; `evalkit`, your clone, which has a local branch `feature` and a remote-tracking ref `origin/feature` from an earlier fetch; and `asha-evalkit`, Asha's clone. Asha has already deleted `feature` on the server and pushed `feature/login`. Your clone has not fetched since.

### Commands

Step 1. Try to create a branch under `feature/`.

```bash
cd evalkit
git branch
git switch -c feature/eval-cache
ls .git/refs/heads
```

Step 2. Rename the blocking branch and try again.

```bash
git branch -m feature feature/base
git switch -c feature/eval-cache
git branch
git switch main
```

### Expected output

<!-- snippet: ch07/lab-04-3-df-conflict/01-local-conflict -->
```text
$ git branch
  feature
* main
$ git switch -c feature/eval-cache
fatal: cannot lock ref 'refs/heads/feature/eval-cache': 'refs/heads/feature' exists; cannot create 'refs/heads/feature/eval-cache'
[exit status: 128]
$ ls .git/refs/heads
feature
main
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-3-df-conflict/02-local-fix -->
```text
$ git branch -m feature feature/base
$ git switch -c feature/eval-cache
Switched to a new branch 'feature/eval-cache'
$ git branch
  feature/base
* feature/eval-cache
  main
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

### What happened internally

- `refs/heads/feature` exists as a loose ref file. `git switch -c feature/eval-cache` needed to create `refs/heads/feature/eval-cache`, which requires `refs/heads/feature` to be a directory, and a path cannot be a file and a directory at once. Git reports it as a lock failure on the new ref, because the check happens when the ref is locked for writing.
- The rule belongs to the ref namespace, not to the file system: Chapter 7, section 7.12, shows the same refusal with packed refs and in a reftable repository.
- `git branch -m feature feature/base` moved the ref, its reflog and its configuration under the `feature/` prefix. Afterwards `feature` is a prefix only, and new branches under it can be created.

### Checkpoint

- `git branch` lists `feature/base`, `feature/eval-cache` and `main`.
- `ls .git/refs/heads/feature` lists `base` and `eval-cache`.

### Failure scenario

The same rule applies to remote-tracking refs, and there it is not your doing. Fetch:

```bash
git branch -r
git fetch
git branch -r
```

<!-- snippet: ch07/lab-04-3-df-conflict/03-fetch-fails -->
```text
$ git branch -r
  origin/feature
  origin/main
$ git fetch
error: some local refs could not be updated; try running
 'git remote prune origin' to remove any old, conflicting branches
From $LAB/ch07/lab-04-3-df-conflict/origin
 ! [new branch]      feature/login -> origin/feature/login  (unable to update local ref)
[exit status: 1]
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature
  origin/main
```
<!-- /snippet -->

The server offers `feature/login`, your clone still holds `origin/feature`, and the fetch cannot create `origin/feature/login` next to it. Git prints the fix in its error message. Note what else happened: `origin/HEAD` appeared, because the fetch created it before failing on the conflicting ref.

### Recovery

Preview what pruning would remove, then fetch with pruning:

```bash
git remote prune origin --dry-run
git fetch --prune
git branch -r
```

<!-- snippet: ch07/lab-04-3-df-conflict/04-recovery -->
```text
$ git remote prune origin --dry-run
Pruning origin
URL: $LAB/ch07/lab-04-3-df-conflict/origin.git
 * [would prune] origin/feature
$ git fetch --prune
From $LAB/ch07/lab-04-3-df-conflict/origin
 - [deleted]         (none)        -> origin/feature
 * [new branch]      feature/login -> origin/feature/login
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/login
  origin/main
```
<!-- /snippet -->

`--prune` deleted `origin/feature`, which the server no longer has, and the same fetch then created `origin/feature/login`.

### Verification

```bash
git fetch
git for-each-ref --format='%(refname)'
```

<!-- snippet: ch07/lab-04-3-df-conflict/05-verify -->
```text
$ git fetch
[exit status: 0]
$ git for-each-ref --format='%(refname)'
refs/heads/feature/base
refs/heads/feature/eval-cache
refs/heads/main
refs/remotes/origin/HEAD
refs/remotes/origin/feature/login
refs/remotes/origin/main
```
<!-- /snippet -->

A plain fetch succeeds again, and the full ref list shows both namespaces in order: no `feature` without a slash remains anywhere.

### Questions

1. Why did `git branch -r` show `origin/feature` although the branch had been deleted on the server? What is a remote-tracking ref a record of?
2. The first error said `cannot lock ref`, the fetch error said `unable to update local ref`. Explain why the same rule produces different wording in the two places.
3. Would `git fetch --prune` have been the right fix if `feature` had been your own unpushed local branch instead of a remote-tracking ref? What would you do then?
4. The team agreed on `feature/` as a namespace. Which single `git` configuration key would make every future fetch prune automatically, and what is its risk?
5. Asha deleted `feature` on the server with `git push origin --delete feature`. Which refs changed in which of the three repositories at that moment, and which did not?

## Lab 4.4: Counting divergence

### Objective

Measure how far branches have diverged with the merge base, two-dot and three-dot ranges, `--left-right --count` and `%(ahead-behind:)`; test ancestry; predict which merges can fast-forward. Then see three ways in which a divergence count comes out wrong.

### Prerequisites

- Chapter 7, section 7.8.
- Chapter 8, section 8.3, for fast-forward merges (reading ahead is optional; this lab uses `--ff-only` only as a test).

### Setup

```bash
bash labs/ch07/setup-04-4-divergence.sh
labs/shell m04-4
```

The script builds `evalkit` with `main` and three branches: `feature/rouge`, which has diverged from `main`; `docs/quickstart`, one commit ahead of `main`; and `fix/strip`, whose commit is already in `main`. This lab creates no commits, so every ID matches the book.

### Commands

Step 1. Look at the graph.

```bash
cd evalkit
git log --oneline --graph --all
```

Step 2. Find the merge base of `main` and `feature/rouge` and list what each side has that the other lacks.

```bash
git merge-base main feature/rouge
git rev-list --left-right --count main...feature/rouge
git log --oneline main..feature/rouge
git log --oneline feature/rouge..main
```

Step 3. Test ancestry. Before each command, predict the exit status.

```bash
git merge-base --is-ancestor main feature/rouge; echo "exit status: $?"
git merge-base --is-ancestor main docs/quickstart; echo "exit status: $?"
git merge-base --is-ancestor fix/strip main; echo "exit status: $?"
```

Step 4. Produce the whole table in one command.

```bash
git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
```

### Expected output

<!-- snippet: ch07/lab-04-4-divergence/01-graph -->
```text
$ git log --oneline --graph --all
* 618b77f Add quickstart to README
* 9b51803 Add CI workflow
* 9500b9e Exact match: strip whitespace
| * eaab34d ROUGE-L: add tests
| * 5351fa7 ROUGE-L: tokenize on whitespace
| * 22c856c Add ROUGE-L metric
|/  
* 03f74b9 Add exact-match metric
* 6eab4a9 Add README
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-4-divergence/02-diverged -->
```text
$ git merge-base main feature/rouge
03f74b9ac8547c31330105153beb4b90c5ddeea8
$ git rev-list --left-right --count main...feature/rouge
2	3
$ git log --oneline main..feature/rouge
eaab34d ROUGE-L: add tests
5351fa7 ROUGE-L: tokenize on whitespace
22c856c Add ROUGE-L metric
$ git log --oneline feature/rouge..main
9b51803 Add CI workflow
9500b9e Exact match: strip whitespace
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-4-divergence/03-ancestry -->
```text
$ git merge-base --is-ancestor main feature/rouge; echo "exit status: $?"
exit status: 1
$ git merge-base --is-ancestor main docs/quickstart; echo "exit status: $?"
exit status: 0
$ git merge-base --is-ancestor fix/strip main; echo "exit status: $?"
exit status: 0
```
<!-- /snippet -->

<!-- snippet: ch07/lab-04-4-divergence/04-table -->
```text
$ git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
docs/quickstart 1 0
feature/rouge 3 2
fix/strip 0 1
main 0 0
```
<!-- /snippet -->

### What happened internally

- `git merge-base` walked both histories back to their best common ancestor, `03f74b9`. Every count in this lab is computed from that commit: `main...feature/rouge` is the set of commits reachable from one tip but not the other, two on the left and three on the right.
- `main..feature/rouge` and `feature/rouge..main` are the two halves of that symmetric difference. `--left-right --count` printed both at once, in the order of the operands.
- `--is-ancestor main feature/rouge` exited with 1: `main` has commits the feature lacks, so the feature cannot be fast-forwarded onto `main`. `main` is an ancestor of `docs/quickstart` (status 0), so that merge can fast-forward. `fix/strip` is an ancestor of `main` (status 0): it is already merged.
- `%(ahead-behind:main)` reports each branch from its own point of view: `fix/strip 0 1` means zero commits of its own and one commit behind `main`.

### Checkpoint

- You can state, without running anything, which of the three branches `git merge --ff-only` would accept from `main`.
- `git rev-list --count main..feature/rouge` prints `3`.

### Failure scenario

Three variants of the count that look right and are not:

```bash
git rev-list --left-right --count main..feature/rouge
git rev-list --count main...feature/rouge
git rev-list --left-right --count feature/rouge...main
```

<!-- snippet: ch07/lab-04-4-divergence/05-failure -->
```text
$ git rev-list --left-right --count main..feature/rouge
0	3
$ git rev-list --count main...feature/rouge
5
$ git rev-list --left-right --count feature/rouge...main
3	2
```
<!-- /snippet -->

The first used two dots, which is a one-sided range, so the left count is 0 and the right count is the whole range. The second dropped `--left-right`, so both sides were added into one number, 5, which answers no question anyone asks. The third swapped the operands, so the numbers are right and the labels are backwards.

### Recovery

Say which number you need and ask for exactly that:

```bash
git rev-list --left-right --count main...feature/rouge
git for-each-ref --format='%(ahead-behind:main)' refs/heads/feature/rouge
git rev-list --count main..feature/rouge
git rev-list --count feature/rouge..main
```

<!-- snippet: ch07/lab-04-4-divergence/06-recovery -->
```text
$ git rev-list --left-right --count main...feature/rouge
2	3
$ git for-each-ref --format='%(ahead-behind:main)' refs/heads/feature/rouge
3 2
$ git rev-list --count main..feature/rouge
3
$ git rev-list --count feature/rouge..main
2
```
<!-- /snippet -->

Three dots with `--left-right` for both numbers in operand order; `%(ahead-behind:)` for the same pair from the branch's side; two dots with `--count` when one number is enough.

### Verification

Use the ancestry tests as predictions and let `git merge --ff-only` confirm them. The first merge must fail, the second must succeed:

```bash
git merge --ff-only feature/rouge
git merge --ff-only docs/quickstart
git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
```

<!-- snippet: ch07/lab-04-4-divergence/07-verify -->
```text
$ git merge --ff-only feature/rouge
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
$ git merge --ff-only docs/quickstart
Updating 9b51803..618b77f
Fast-forward
 README.md | 4 ++++
 1 file changed, 4 insertions(+)
$ git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
docs/quickstart 0 0
feature/rouge 3 3
fix/strip 0 2
main 0 0
```
<!-- /snippet -->

After the fast-forward, `main` and `docs/quickstart` name the same commit (`0 0`), `fix/strip` is two behind, and `feature/rouge` is three ahead and three behind. No new commit was created: a fast-forward only moves a ref.

### Questions

1. Define the merge base of two commits without using the word "common". Why can there be more than one?
2. `git log main..feature/rouge` and `git log feature/rouge..main`: which question does each answer, and how do the two relate to `main...feature/rouge`?
3. Why is "main is an ancestor of X" the exact condition for `git merge --ff-only X` to succeed on `main`? What does the merge do to `.git` when it succeeds?
4. A pull request page says "3 commits ahead, 2 behind". Which two of the commands in this lab compute those numbers, and from which commit are they counted?
5. After the verification, `feature/rouge` is `3 3`, where before it was `3 2`. Which commit changed the second number, and did anything about `feature/rouge` itself change?

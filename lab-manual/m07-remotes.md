# Module 7 labs: Remotes, fetch, pull, and push

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" is real output of a replay script in `labs/ch12/`. Read [Chapter 12](../textbook/ch12-remote-operations.md) first; each lab names the sections it uses.

## How these labs work

There is no network in this module. A bare repository on disk plays the server, and separate clones play you, Asha and Ravi. Whose clone your shell is in decides whose commits you make: the setup scripts store Asha's and Ravi's names in the configuration of their clones, and your own clone uses the identity of the lab shell.

Each lab has a setup script that builds its starting state in a sandbox of its own, and a replay script that runs the whole lab with a fixed clock:

```bash
bash labs/ch12/setup-07-2-rejected-push.sh    # build (or rebuild) the starting state of Lab 7.2
labs/shell m07-2                              # open the lab shell in that sandbox, then type the commands
labs/run ch12/lab-07-2-rejected-push          # or: watch the exact replay that the book prints
```

Three differences between your terminal and the book are expected:

- **Commit IDs.** Commits made by a setup script have the same IDs as in the book. Commits that you make by hand have different IDs, because the commit time is part of the ID, and so does every commit built on them (merges, rebased commits). Compare the shape of the output, not those IDs. In Lab 7.1 you make every commit yourself, so every ID differs.
- **Paths.** `$LAB` stands for the lab root. Where the book shows `$LAB/ch12/lab-07-1-...`, your shell shows `$LAB/hands-on/m07-1`.
- **Graph order.** `git log --graph` lists commits by date. Commits from a setup script carry the book's fixed clock and yours carry the real time, so the same graph can be drawn with its lines in a different order.

Run a setup script again whenever you want to start a lab over. It throws the sandbox away and rebuilds it.

## Lab 7.1: A bare server and two clones, watching every ref

### Objective

Build a server and two clones from nothing. After every operation, list the refs of all three repositories and explain each difference: which ref moved, in which repository, and which command moved it.

### Prerequisites

Chapter 12, sections 12.1 to 12.4. `git show-ref` and `git update-ref` from Chapter 3.

### Setup

```bash
bash labs/ch12/setup-07-1-bare-server-two-clones.sh
labs/shell m07-1
```

The sandbox is empty. You create everything in it by hand.

### Commands

```bash
# 1. The server: a bare repository with no refs
git init --bare server/support-bot.git
ls -F server/support-bot.git
git -C server/support-bot.git show-ref

# 2. Your clone of the empty server
git clone server/support-bot.git you/support-bot
cd you/support-bot
git config get --all --show-names --regexp "^(remote|branch)\."
git show-ref

# 3. A first commit: compare your refs with the server's
printf '# support-bot\n' > README.md
git add README.md
git commit -m "Add README"
git show-ref --abbrev
git -C ../../server/support-bot.git show-ref --abbrev

# 4. The first push: compare again
git push
git show-ref --abbrev
git -C ../../server/support-bot.git show-ref --abbrev

# 5. Asha clones and gets her own identity
cd ../..
git clone server/support-bot.git asha/support-bot
cd asha/support-bot
git config set user.name "Asha Rao"
git config set user.email asha@example.com
git show-ref --abbrev

# 6. Asha commits and pushes
printf 'model: small-v1\ntop_k: 5\n' > config.yaml
git add config.yaml
git commit -m "Add retrieval config"
git push

# 7. Three views of the same branch: Asha, the server, you
git show-ref --abbrev
git -C ../../server/support-bot.git show-ref --abbrev
git -C ../../you/support-bot show-ref --abbrev

# 8. You fetch
cd ../../you/support-bot
git status
git fetch
git show-ref --abbrev
git status -sb

# 9. You integrate
git merge --ff-only origin/main
git show-ref --abbrev
git log --format="%h %an: %s"
```

Before each `show-ref`, write down what you expect to see. That prediction is the lab.

### Expected output

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/01-server -->
```text
$ git init --bare server/support-bot.git
Initialized empty Git repository in $LAB/ch12/lab-07-1-bare-server-two-clones/server/support-bot.git/
$ ls -F server/support-bot.git
config
description
HEAD
hooks/
info/
objects/
refs/
$ git -C server/support-bot.git show-ref
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/02-first-clone -->
```text
$ git clone server/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
warning: You appear to have cloned an empty repository.
done.
$ cd you/support-bot
$ git config get --all --show-names --regexp "^(remote|branch)\."
remote.origin.url $LAB/ch12/lab-07-1-bare-server-two-clones/server/support-bot.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
branch.main.remote origin
branch.main.merge refs/heads/main
$ git show-ref
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/03-first-commit -->
```text
$ printf '# support-bot\n' > README.md
$ git add README.md
$ git commit -m "Add README"
[main (root-commit) 96f8422] Add README
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
# Refs in your clone, then refs on the server:
$ git show-ref --abbrev
96f8422 refs/heads/main
$ git -C ../../server/support-bot.git show-ref --abbrev
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/04-first-push -->
```text
$ git push
To $LAB/ch12/lab-07-1-bare-server-two-clones/server/support-bot.git
 * [new branch]      main -> main
# Refs in your clone, then refs on the server:
$ git show-ref --abbrev
96f8422 refs/heads/main
96f8422 refs/remotes/origin/main
$ git -C ../../server/support-bot.git show-ref --abbrev
96f8422 refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/05-second-clone -->
```text
$ cd ../..
$ git clone server/support-bot.git asha/support-bot
Cloning into 'asha/support-bot'...
done.
$ cd asha/support-bot
$ git config set user.name "Asha Rao"
$ git config set user.email asha@example.com
$ git show-ref --abbrev
96f8422 refs/heads/main
96f8422 refs/remotes/origin/HEAD
96f8422 refs/remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/06-asha-pushes -->
```text
$ printf 'model: small-v1\ntop_k: 5\n' > config.yaml
$ git add config.yaml
$ git commit -m "Add retrieval config"
[main b7857ec] Add retrieval config
 1 file changed, 2 insertions(+)
 create mode 100644 config.yaml
$ git push
To $LAB/ch12/lab-07-1-bare-server-two-clones/server/support-bot.git
   96f8422..b7857ec  main -> main
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/07-three-views -->
```text
# Asha:
$ git show-ref --abbrev
b7857ec refs/heads/main
b7857ec refs/remotes/origin/HEAD
b7857ec refs/remotes/origin/main
# The server:
$ git -C ../../server/support-bot.git show-ref --abbrev
b7857ec refs/heads/main
# You:
$ git -C ../../you/support-bot show-ref --abbrev
96f8422 refs/heads/main
96f8422 refs/remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/08-you-fetch -->
```text
$ cd ../../you/support-bot
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
$ git fetch
From $LAB/ch12/lab-07-1-bare-server-two-clones/server/support-bot
   96f8422..b7857ec  main       -> origin/main
$ git show-ref --abbrev
96f8422 refs/heads/main
b7857ec refs/remotes/origin/HEAD
b7857ec refs/remotes/origin/main
$ git status -sb
## main...origin/main [behind 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/09-you-integrate -->
```text
$ git merge --ff-only origin/main
Updating 96f8422..b7857ec
Fast-forward
 config.yaml | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 config.yaml
$ git show-ref --abbrev
b7857ec refs/heads/main
b7857ec refs/remotes/origin/HEAD
b7857ec refs/remotes/origin/main
$ git log --format="%h %an: %s"
b7857ec Asha Rao: Add retrieval config
96f8422 Lab User: Add README
```
<!-- /snippet -->

### What happened internally

- **Steps 1 and 2.** A new bare repository has no refs at all, so `show-ref` prints nothing and exits with status 1. Its `HEAD` still names `refs/heads/main`, a branch that is not born. Cloning it warns about the empty repository, yet writes the complete configuration: the remote, and an upstream for a local `main` that does not exist either.
- **Step 3.** A commit moves `refs/heads/main` in your repository and nothing anywhere else.
- **Step 4.** The push created `refs/heads/main` on the server and, in your clone, `refs/remotes/origin/main`. You never fetched: a successful push records what the server now has. There is still no `origin/HEAD` in your clone, because the clone of an empty repository had nothing to record.
- **Step 5.** Asha's clone was made from a server that has a branch, so it gets `origin/main`, `origin/HEAD` and a local `main` at once.
- **Steps 6 and 7.** Asha's push moves the server's `main` and her own `origin/main`. Your clone is untouched: both of your refs still name your first commit.
- **Step 8.** `git status` reports "up to date" from your two local refs. `git fetch` moves `origin/main`, and creates the missing `origin/HEAD` on the way. Only then does status say `[behind 1]`.
- **Step 9.** The fast-forward merge moves `refs/heads/main`, the index and the working tree. The log shows two commits by two authors.

### Checkpoint

At the end of step 9 the three repositories agree: in your clone `git status -sb` prints `## main...origin/main` with nothing in brackets, and `git show-ref --abbrev` shows the same ID for `refs/heads/main`, `refs/remotes/origin/HEAD` and `refs/remotes/origin/main`. If your `origin/main` is behind Asha's commit, you skipped the fetch in step 8.

### Failure scenario

Delete your remote-tracking ref by hand, as a careless script might:

```bash
git update-ref -d refs/remotes/origin/main
git show-ref --abbrev
git status
git rev-parse origin/main
```

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/10-failure -->
```text
$ git update-ref -d refs/remotes/origin/main
$ git show-ref --abbrev
b7857ec refs/heads/main
$ git status
On branch main
Your branch is based on 'origin/main', but the upstream is gone.
  (use "git branch --unset-upstream" to fixup)

nothing to commit, working tree clean
$ git rev-parse origin/main
fatal: ambiguous argument 'origin/main': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
origin/main
[exit status: 128]
```
<!-- /snippet -->

Your branch and your files are unharmed. What is lost is your clone's memory of the server: status can no longer compare, and `origin/main` no longer names anything.

### Recovery

```bash
git fetch
git show-ref --abbrev
git status -sb
```

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/11-recovery -->
```text
$ git fetch
From $LAB/ch12/lab-07-1-bare-server-two-clones/server/support-bot
 * [new branch]      main       -> origin/main
$ git show-ref --abbrev
b7857ec refs/heads/main
b7857ec refs/remotes/origin/HEAD
b7857ec refs/remotes/origin/main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

A remote-tracking ref is a cache of the server's state. A fetch rebuilds it.

### Verification

```bash
git rev-parse main origin/main
git ls-remote origin refs/heads/main
git -C ../../asha/support-bot rev-parse main
```

<!-- snippet: ch12/lab-07-1-bare-server-two-clones/12-verification -->
```text
$ git rev-parse main origin/main
b7857ece90d78dfe70c02ce8cf6c41d75d6e438e
b7857ece90d78dfe70c02ce8cf6c41d75d6e438e
$ git ls-remote origin refs/heads/main
b7857ece90d78dfe70c02ce8cf6c41d75d6e438e	refs/heads/main
$ git -C ../../asha/support-bot rev-parse main
b7857ece90d78dfe70c02ce8cf6c41d75d6e438e
```
<!-- /snippet -->

Four answers, one ID: your branch, your remote-tracking branch, the server and Asha's branch.

### Questions

1. After your first push, your clone had `refs/remotes/origin/main` but no `refs/remotes/origin/HEAD`, while Asha's fresh clone had both. Why, and which command later created yours?
2. You had never run `git fetch` when `refs/remotes/origin/main` appeared in your clone. Which command created it, and why is that safe?
3. In step 8, `git status` printed "Your branch is up to date with 'origin/main'" while the server was one commit ahead. Was the message wrong? What exactly did it compare?
4. In the failure scenario you deleted only `refs/remotes/origin/main`, yet `git show-ref` stopped listing `refs/remotes/origin/HEAD` as well. Explain.
5. The server has `refs/heads/main` and nothing under `refs/remotes/`. Why does a server not need remote-tracking refs?
6. Asha's commit carries her name. Where did Git take the name from, and what would the commit say if she had skipped the two `git config set` commands in this lab shell?

## Lab 7.2: A rejected push, then fetch and integrate by merge and by rebase

### Objective

Reproduce both rejection messages of the fast-forward rule, then publish your work twice: once by merging (in your clone) and once by rebasing (in Ravi's). Then watch a forced push remove three commits from the server, and restore them without a second forced push.

### Prerequisites

Chapter 12, sections 12.4, 12.7 and 12.8. Merge and rebase from Chapters 8 and 9. Lab 7.1.

### Setup

```bash
bash labs/ch12/setup-07-2-rejected-push.sh
labs/shell m07-2
```

Starting state: Asha has pushed a commit (`Raise top_k to 8`) that nobody has fetched. You and Ravi each have one local commit that is not on the server.

### Commands

```bash
# 1. Your push is rejected
cd you/support-bot
git status -sb
git push

# 2. Fetch, look, and try again
git fetch
git status -sb
git log --oneline --graph --decorate --all
git push

# 3. Integrate by merge, then push
git merge origin/main
git push
git log --oneline --graph --decorate

# 4. Ravi is rejected too
cd ../../ravi/support-bot
git push
git fetch
git log --oneline --graph --decorate --all

# 5. Ravi integrates by rebase, then pushes
git rebase origin/main
git push
git log --oneline --graph --decorate
```

### Expected output

<!-- snippet: ch12/lab-07-2-rejected-push/01-rejected -->
```text
$ cd you/support-bot
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/02-fetch-and-look -->
```text
$ git fetch
From ../../server/support-bot
   510ee94..04db75f  main       -> origin/main
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --decorate --all
* 2ce93f5 (HEAD -> main) Add dev requirements
| * 04db75f (origin/main, origin/HEAD) Raise top_k to 8
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/03-merge-and-push -->
```text
$ git merge origin/main
Merge made by the 'ort' strategy.
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../server/support-bot.git
   04db75f..b90ac08  main -> main
$ git log --oneline --graph --decorate
*   b90ac08 (HEAD -> main, origin/main, origin/HEAD) Merge remote-tracking branch 'origin/main'
|\  
| * 04db75f Raise top_k to 8
* | 2ce93f5 Add dev requirements
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/04-ravi-rejected -->
```text
$ cd ../../ravi/support-bot
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git fetch
From ../../server/support-bot
   510ee94..b90ac08  main       -> origin/main
$ git log --oneline --graph --decorate --all
*   b90ac08 (origin/main, origin/HEAD) Merge remote-tracking branch 'origin/main'
|\  
| * 04db75f Raise top_k to 8
* | 2ce93f5 Add dev requirements
|/  
| * 7dca6cc (HEAD -> main) Add eval harness entry point
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/05-rebase-and-push -->
```text
$ git rebase origin/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git push
To ../../server/support-bot.git
   b90ac08..8421e1c  main -> main
$ git log --oneline --graph --decorate
* 8421e1c (HEAD -> main, origin/main, origin/HEAD) Add eval harness entry point
*   b90ac08 Merge remote-tracking branch 'origin/main'
|\  
| * 04db75f Raise top_k to 8
* | 2ce93f5 Add dev requirements
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
```
<!-- /snippet -->

### What happened internally

- **Step 1.** The server advertised a `main` that names a commit you do not have. Your Git cannot test ancestry against an object it lacks, so it reports `(fetch first)` and sends nothing. The status line still says `[ahead 1]`: a rejected push does not fetch.
- **Step 2.** The fetch moved `origin/main`. Now your Git has both commits, sees that the server's tip is not an ancestor of yours, and reports `(non-fast-forward)`.
- **Step 3.** `git merge origin/main` created a merge commit with two parents: your commit and Asha's. The server's tip is an ancestor of the merge, so the push is a fast-forward for the server.
- **Step 4.** For Ravi the server has moved by three commits: Asha's, yours and your merge.
- **Step 5.** `git rebase origin/main` re-created Ravi's single commit on top of the fetched tip. His old commit `7dca6cc` was replaced by a new one (`8421e1c` in the replay); nobody else ever had the old one, so nothing was rewritten for anyone but Ravi.

### Checkpoint

```bash
git rev-parse main
git ls-remote origin refs/heads/main
git -C ../../server/support-bot.git log --oneline main
```

<!-- snippet: ch12/lab-07-2-rejected-push/06-checkpoint -->
```text
$ git rev-parse main
8421e1c01f45851273af8f2290e3d99e73534049
$ git ls-remote origin refs/heads/main
8421e1c01f45851273af8f2290e3d99e73534049	refs/heads/main
$ git -C ../../server/support-bot.git log --oneline main
8421e1c Add eval harness entry point
b90ac08 Merge remote-tracking branch 'origin/main'
2ce93f5 Add dev requirements
04db75f Raise top_k to 8
510ee94 Add retrieval config
95671d3 Add retriever skeleton
f56c1bb Add README
```
<!-- /snippet -->

Ravi's `main` and the server's `main` are the same commit, and the server's history has seven commits, one of them a merge.

### Failure scenario

Asha has not fetched since her own push. She commits, is rejected, and forces:

```bash
cd ../../asha/support-bot
printf 'model: small-v1\ntop_k: 6\n' > config.yaml
git commit -am "Lower top_k to 6"
git push
git push --force
git -C ../../server/support-bot.git log --oneline main
```

<!-- snippet: ch12/lab-07-2-rejected-push/07-failure-force -->
```text
$ cd ../../asha/support-bot
$ printf 'model: small-v1\ntop_k: 6\n' > config.yaml
$ git commit -am "Lower top_k to 6"
[main de0a845] Lower top_k to 6
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force
To ../../server/support-bot.git
 + 8421e1c...de0a845 main -> main (forced update)
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/08-damage -->
```text
$ git -C ../../server/support-bot.git log --oneline main
de0a845 Lower top_k to 6
04db75f Raise top_k to 8
510ee94 Add retrieval config
95671d3 Add retriever skeleton
f56c1bb Add README
```
<!-- /snippet -->

The server's `main` lost three commits: yours, your merge and Ravi's. The server kept no record of where `main` used to be.

### Recovery

Ravi's clone still has all of it. Do not reach for `git pull --rebase` there. Fetch, look, merge, push:

```bash
cd ../../ravi/support-bot
git fetch
git status -sb
git log --oneline --graph --decorate --all

git merge origin/main
git push
git log --oneline --graph --decorate

cd ../../asha/support-bot
git pull --ff-only
```

<!-- snippet: ch12/lab-07-2-rejected-push/09-recovery-see -->
```text
$ cd ../../ravi/support-bot
$ git fetch
From ../../server/support-bot
 + 8421e1c...de0a845 main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 3, behind 1]
$ git log --oneline --graph --decorate --all
* de0a845 (origin/main, origin/HEAD) Lower top_k to 6
| * 8421e1c (HEAD -> main) Add eval harness entry point
| *   b90ac08 Merge remote-tracking branch 'origin/main'
| |\  
| |/  
|/|   
* | 04db75f Raise top_k to 8
| * 2ce93f5 Add dev requirements
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/10-recovery-merge -->
```text
$ git merge origin/main
Merge made by the 'ort' strategy.
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../server/support-bot.git
   de0a845..3bf134b  main -> main
$ git log --oneline --graph --decorate
*   3bf134b (HEAD -> main, origin/main, origin/HEAD) Merge remote-tracking branch 'origin/main'
|\  
| * de0a845 Lower top_k to 6
* | 8421e1c Add eval harness entry point
* | b90ac08 Merge remote-tracking branch 'origin/main'
|\| 
| * 04db75f Raise top_k to 8
* | 2ce93f5 Add dev requirements
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-2-rejected-push/11-asha-catches-up -->
```text
$ cd ../../asha/support-bot
$ git pull --ff-only
From ../../server/support-bot
   de0a845..3bf134b  main       -> origin/main
Updating de0a845..3bf134b
Fast-forward
 eval/run_eval.py     | 1 +
 requirements-dev.txt | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 eval/run_eval.py
 create mode 100644 requirements-dev.txt
```
<!-- /snippet -->

Ravi merged Asha's forced commit into the history she had overwritten. The result contains her commit, so his push is a fast-forward for the server and needs no force.

### Verification

```bash
git rev-parse main
git -C ../../ravi/support-bot rev-parse main
git ls-remote origin refs/heads/main
git rev-list --count main
```

<!-- snippet: ch12/lab-07-2-rejected-push/12-verification -->
```text
$ git rev-parse main
3bf134bb05745d29f1199ae12b63ad4b105da680
$ git -C ../../ravi/support-bot rev-parse main
3bf134bb05745d29f1199ae12b63ad4b105da680
$ git ls-remote origin refs/heads/main
3bf134bb05745d29f1199ae12b63ad4b105da680	refs/heads/main
$ git rev-list --count main
9
```
<!-- /snippet -->

Asha, Ravi and the server agree, and `main` has nine commits: the seven from the checkpoint, Asha's last commit and Ravi's recovery merge.

### Questions

1. Steps 1 and 2 gave two different rejection messages for the same situation. What was different in your repository between the two attempts?
2. Your merge commit in step 3 is called `Merge remote-tracking branch 'origin/main'`. The merge that `git pull` creates in Lab 7.3 is called `Merge branch 'main' of <URL>`. Why do the names differ?
3. You merged and Ravi rebased. Which of the two changed the ID of an existing commit, and whose commit was it?
4. After Asha's forced push, which commits were no longer reachable from the server's `main`? Name every repository in which each of them still existed.
5. The recovery warns against `git pull --rebase`. Predict what it would have done in Ravi's clone, then read the transcript in the solutions.
6. Ravi's last push used no `--force`. Why did the server accept it?

## Lab 7.3: The diverged pull error and the three configurations

### Objective

Produce the fatal error of `git pull` on diverged branches, answer it in each of the three documented ways, and then diagnose a pull that refuses because two configuration scopes disagree.

### Prerequisites

Chapter 12, section 12.6. Configuration scopes from Chapter 14B. Lab 7.2.

### Setup

```bash
bash labs/ch12/setup-07-3-diverged-pull.sh
labs/shell m07-3
```

Starting state: `main` has diverged. Asha has pushed one commit and holds a second one locally. You have one local commit and have not fetched.

### Commands

```bash
# 1. The fatal error
cd you/support-bot
git status -sb
git pull
git status -sb

# 2. Answer one: fast-forward only
git config set pull.ff only
git pull
git config unset pull.ff

# 3. Answer two: merge
git config set pull.rebase false
git pull
git log --oneline --graph --decorate -5

# 4. Take the merge back
git reset --hard ORIG_HEAD
git status -sb

# 5. Answer three: rebase, then publish
git config set pull.rebase true
git pull
git log --oneline --graph --decorate -4
git push
```

`git reset --hard` is a 🔴 command: it discards uncommitted changes. Here the working tree is clean, and the reset only moves `main` back to the commit that `ORIG_HEAD` recorded.

### Expected output

<!-- snippet: ch12/lab-07-3-diverged-pull/01-fatal -->
```text
$ cd you/support-bot
$ git status -sb
## main...origin/main [ahead 1]
$ git pull
From ../../server/support-bot
   510ee94..719650d  main       -> origin/main
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[exit status: 128]
$ git status -sb
## main...origin/main [ahead 1, behind 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-3-diverged-pull/02-ff-only -->
```text
$ git config set pull.ff only
$ git pull
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
$ git config unset pull.ff
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-3-diverged-pull/03-merge -->
```text
$ git config set pull.rebase false
$ git pull
Merge made by the 'ort' strategy.
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate -5
*   c680405 (HEAD -> main) Merge branch 'main' of ../../server/support-bot
|\  
| * 719650d (origin/main, origin/HEAD) Raise top_k to 8
* | 2ce93f5 Add dev requirements
|/  
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-3-diverged-pull/04-back -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at 2ce93f5 Add dev requirements
$ git status -sb
## main...origin/main [ahead 1, behind 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-3-diverged-pull/05-rebase -->
```text
$ git config set pull.rebase true
$ git pull
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph --decorate -4
* 79fa150 (HEAD -> main) Add dev requirements
* 719650d (origin/main, origin/HEAD) Raise top_k to 8
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
$ git push
To ../../server/support-bot.git
   719650d..79fa150  main -> main
```
<!-- /snippet -->

### What happened internally

- **Step 1.** The fetch half of the pull moved `origin/main` and rewrote `FETCH_HEAD`. Then Git found that neither commit is an ancestor of the other, found no instruction, and stopped. The second status line, `[ahead 1, behind 1]`, is the proof that the fetch happened.
- **Step 2.** With `pull.ff=only`, Git has an instruction: move the branch only if that is a fast-forward. It is not, so the refusal has a different text. The second pull printed no `From` block because there was nothing new to fetch.
- **Step 3.** `pull.rebase=false` selects a merge. The merge commit's second parent is the fetched commit, and its message names the URL that was pulled from.
- **Step 4.** The merge had stored the previous tip in `ORIG_HEAD`.
- **Step 5.** `pull.rebase=true` replays your commit on top of `origin/main`. The replayed commit has a new ID and the fetched commit as its parent, so the push is a fast-forward.

### Checkpoint

```bash
git config get --show-origin --show-scope pull.rebase
git status -sb
```

<!-- snippet: ch12/lab-07-3-diverged-pull/06-checkpoint -->
```text
$ git config get --show-origin --show-scope pull.rebase
local	file:.git/config	true
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

`pull.rebase=true` is stored in this repository only, and your branch equals `origin/main`.

### Failure scenario

Someone decides that fast-forward-only is a good machine-wide default and sets it globally. In this lab shell `--global` writes the lab's own configuration file, not your real one. Then both sides commit again:

```bash
git config set --global pull.ff only

cd ../../asha/support-bot
git pull --rebase
git push

cd ../../you/support-bot
printf '\n## Development\n\nRun pytest before you push.\n' >> README.md
git commit -am "Document the test command"

git pull
git config list --show-origin --show-scope | grep -F pull.
```

<!-- snippet: ch12/lab-07-3-diverged-pull/07-failure-setup -->
```text
$ git config set --global pull.ff only
$ cd ../../asha/support-bot
$ git pull --rebase
From ../../server/support-bot
   719650d..79fa150  main       -> origin/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git push
To ../../server/support-bot.git
   79fa150..ee25493  main -> main
$ cd ../../you/support-bot
$ printf '\n## Development\n\nRun pytest before you push.\n' >> README.md
$ git commit -am "Document the test command"
[main ca63c8c] Document the test command
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-3-diverged-pull/08-failure -->
```text
$ git pull
From ../../server/support-bot
   79fa150..ee25493  main       -> origin/main
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
$ git config list --show-origin --show-scope | grep -F pull.
global	file:$LAB/ch12/lab-07-3-diverged-pull/home/.gitconfig	pull.ff=only
local	file:.git/config	pull.rebase=true
```
<!-- /snippet -->

The repository says "rebase" and the pull still refuses. The last command shows why: two settings from two scopes are both in force.

### Recovery

```bash
git pull --rebase
git config unset --global pull.ff
git push
```

<!-- snippet: ch12/lab-07-3-diverged-pull/09-recovery -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git config unset --global pull.ff
$ git push
To ../../server/support-bot.git
   ee25493..dd0c27c  main -> main
```
<!-- /snippet -->

The flag overrides both settings for one invocation. Removing the global key is part of the recovery: the lab shell shares one global file across all hands-on labs, so a leftover `pull.ff=only` would change the behavior of later labs.

### Verification

```bash
git config list --show-origin --show-scope | grep -F pull.
git status -sb
git log --oneline --graph --decorate -5
```

<!-- snippet: ch12/lab-07-3-diverged-pull/10-verification -->
```text
$ git config list --show-origin --show-scope | grep -F pull.
local	file:.git/config	pull.rebase=true
$ git status -sb
## main...origin/main
$ git log --oneline --graph --decorate -5
* dd0c27c (HEAD -> main, origin/main, origin/HEAD) Document the test command
* ee25493 Describe the evaluation run
* 79fa150 Add dev requirements
* 719650d Raise top_k to 8
* 510ee94 Add retrieval config
```
<!-- /snippet -->

One `pull.` setting is left, the local one. History is linear and published.

### Questions

1. After the first `git pull` failed, `git status -sb` changed from `[ahead 1]` to `[ahead 1, behind 1]`. What moved, and what did not?
2. The same diverged state produced two different fatal messages. Which configuration state produces which message?
3. Why did `git reset --hard ORIG_HEAD` return you to the diverged state after the merge? What would it have destroyed if you had had uncommitted edits?
4. After the rebase pull, `Add dev requirements` has a new commit ID. Is the old commit gone? How would you find it?
5. In the failure scenario `pull.rebase=true` was set and the pull still refused. State the precedence you observed. How did Asha's `git pull --rebase` succeed under the same global setting?
6. Which of the three answers would you configure on a deploy host, and why?

## Lab 7.4: When `--force-with-lease` saves you and when it does not

### Objective

Rewrite a published commit, see `--force-with-lease` protect a teammate's commit, defeat that protection with a single fetch, try the two stronger forms, and bring the overwritten commit back from your own clone.

### Prerequisites

Chapter 12, sections 12.7 and 12.8. `git commit --amend` from Chapter 11 and the reflog from Chapter 13. Lab 7.2.

### Setup

```bash
bash labs/ch12/setup-07-4-force-with-lease.sh
labs/shell m07-4
```

Starting state: you published `feature/prompt-cache` with two commits; the second has a typo in its message (`Add cahce TTL`). Asha has checked the branch out and committed a test on top of it. She has not pushed yet.

### Commands

```bash
# 1. Rewrite the published commit, keeping a marker at the old tip
cd you/support-bot
git log --oneline --decorate -2
git branch backup/prompt-cache
git commit --amend -m "Add cache TTL"
git status -sb
git push

# 2. Meanwhile Asha publishes her test on top of the old commit
cd ../../asha/support-bot
git push
cd ../../you/support-bot

# 3. The lease holds
git push --force-with-lease
git rev-parse --short origin/feature/prompt-cache
git ls-remote origin feature/prompt-cache

# 4. A fetch that you do not look at (an editor would do this for you)
git fetch
git status -sb
git log --oneline --graph --decorate --all -5

# 5. Two stronger forms still refuse
git push --force-with-lease --force-if-includes
git push --force-with-lease=feature/prompt-cache:backup/prompt-cache
```

### Expected output

<!-- snippet: ch12/lab-07-4-force-with-lease/01-rewrite -->
```text
$ cd you/support-bot
$ git log --oneline --decorate -2
914980c (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add cahce TTL
bdbe39f Add prompt cache
$ git branch backup/prompt-cache
$ git commit --amend -m "Add cache TTL"
[feature/prompt-cache b70d216] Add cache TTL
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 1 insertion(+)
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 1, behind 1]
$ git push
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (non-fast-forward)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-4-force-with-lease/02-asha-pushes -->
```text
$ cd ../../asha/support-bot
$ git push
To ../../server/support-bot.git
   914980c..00e201d  feature/prompt-cache -> feature/prompt-cache
$ cd ../../you/support-bot
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-4-force-with-lease/03-lease-holds -->
```text
$ git push --force-with-lease
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git rev-parse --short origin/feature/prompt-cache
914980c
$ git ls-remote origin feature/prompt-cache
00e201d913bf7a63855e14755e79cbde419388e4	refs/heads/feature/prompt-cache
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-4-force-with-lease/04-background-fetch -->
```text
$ git fetch
From ../../server/support-bot
   914980c..00e201d  feature/prompt-cache -> origin/feature/prompt-cache
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 1, behind 2]
$ git log --oneline --graph --decorate --all -5
* b70d216 (HEAD -> feature/prompt-cache) Add cache TTL
| * 00e201d (origin/feature/prompt-cache) Add cache test
| * 914980c (backup/prompt-cache) Add cahce TTL
|/  
* bdbe39f Add prompt cache
* 510ee94 (origin/main, origin/HEAD, main) Add retrieval config
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-4-force-with-lease/05-guards -->
```text
$ git push --force-with-lease --force-if-includes
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (remote ref updated since checkout)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease=feature/prompt-cache:backup/prompt-cache
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

### What happened internally

- **Step 1.** `git commit --amend` created a new commit with the same tree and parent and a corrected message. Your branch moved to it; the published commit `914980c` is still what `origin/feature/prompt-cache` and `backup/prompt-cache` name. The plain push is not a fast-forward and is rejected.
- **Step 2.** Asha's push is a fast-forward of the server's branch: her test sits on top of `914980c`.
- **Step 3.** The lease compares the server's branch (now Asha's commit) with your remote-tracking ref (still `914980c`). They differ: `(stale info)`. Your Git made that decision from the server's advertisement and sent nothing.
- **Step 4.** The fetch moved your remote-tracking ref to Asha's commit. Your local branch does not contain it: the graph shows her commit on the other side of the fork.
- **Step 5.** `--force-if-includes` additionally requires that the tip of the remote-tracking ref was part of your local branch at some time, according to the branch's reflog. It never was. The explicit form compares the server with `backup/prompt-cache`, the commit you rewrote, and finds a different commit there.

### Checkpoint

```bash
git ls-remote origin feature/prompt-cache
git rev-parse origin/feature/prompt-cache
```

<!-- snippet: ch12/lab-07-4-force-with-lease/06-checkpoint -->
```text
$ git ls-remote origin feature/prompt-cache
00e201d913bf7a63855e14755e79cbde419388e4	refs/heads/feature/prompt-cache
$ git rev-parse origin/feature/prompt-cache
00e201d913bf7a63855e14755e79cbde419388e4
```
<!-- /snippet -->

The server still has Asha's commit, and your remote-tracking ref now equals the server. That equality is the problem.

### Failure scenario

```bash
git push --force-with-lease
git ls-remote origin feature/prompt-cache
git -C ../../server/support-bot.git log --oneline feature/prompt-cache -3
```

<!-- snippet: ch12/lab-07-4-force-with-lease/07-failure -->
```text
$ git push --force-with-lease
To ../../server/support-bot.git
 + 00e201d...b70d216 feature/prompt-cache -> feature/prompt-cache (forced update)
$ git ls-remote origin feature/prompt-cache
b70d216eab7ebe036b916183d2f12b36dc46d766	refs/heads/feature/prompt-cache
$ git -C ../../server/support-bot.git log --oneline feature/prompt-cache -3
b70d216 Add cache TTL
bdbe39f Add prompt cache
510ee94 Add retrieval config
```
<!-- /snippet -->

The same command that was refused in step 3 now succeeds, and Asha's test commit is gone from the server's branch.

### Recovery

Your clone fetched the commit before overwriting it, so the reflog of the remote-tracking ref still names it:

```bash
git reflog show origin/feature/prompt-cache
git log --oneline -1 origin/feature/prompt-cache@{1}

git cherry-pick origin/feature/prompt-cache@{1}
git push
git log --oneline --decorate -3
```

Then Asha brings her clone in line:

```bash
cd ../../asha/support-bot
git fetch
git status -sb
git pull --rebase
git status -sb
git log --oneline --decorate -3
```

<!-- snippet: ch12/lab-07-4-force-with-lease/08-recovery-find -->
```text
$ git reflog show origin/feature/prompt-cache
b70d216 refs/remotes/origin/feature/prompt-cache@{0}: update by push
00e201d refs/remotes/origin/feature/prompt-cache@{1}: fetch: fast-forward
914980c refs/remotes/origin/feature/prompt-cache@{2}: update by push
$ git log --oneline -1 origin/feature/prompt-cache@{1}
00e201d Add cache test
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-4-force-with-lease/09-recovery-restore -->
```text
$ git cherry-pick origin/feature/prompt-cache@{1}
[feature/prompt-cache 2d24bde] Add cache test
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 tests/test_cache.py
$ git push
To ../../server/support-bot.git
   b70d216..2d24bde  feature/prompt-cache -> feature/prompt-cache
$ git log --oneline --decorate -3
2d24bde (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add cache test
b70d216 Add cache TTL
bdbe39f Add prompt cache
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-4-force-with-lease/10-asha-realigns -->
```text
$ cd ../../asha/support-bot
$ git fetch
From ../../server/support-bot
 + 00e201d...2d24bde feature/prompt-cache -> origin/feature/prompt-cache  (forced update)
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 2, behind 2]
$ git pull --rebase
Successfully rebased and updated refs/heads/feature/prompt-cache.
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache
$ git log --oneline --decorate -3
2d24bde (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add cache test
b70d216 Add cache TTL
bdbe39f Add prompt cache
```
<!-- /snippet -->

The cherry-pick re-created Asha's commit on top of your rewritten commit, with her name as author, and an ordinary push published it.

### Verification

```bash
git rev-parse feature/prompt-cache
git -C ../../you/support-bot rev-parse feature/prompt-cache
git ls-remote origin feature/prompt-cache
ls tests
```

<!-- snippet: ch12/lab-07-4-force-with-lease/11-verification -->
```text
$ git rev-parse feature/prompt-cache
2d24bde89c8d7e71d8268bfa071214c5c19b303e
$ git -C ../../you/support-bot rev-parse feature/prompt-cache
2d24bde89c8d7e71d8268bfa071214c5c19b303e
$ git ls-remote origin feature/prompt-cache
2d24bde89c8d7e71d8268bfa071214c5c19b303e	refs/heads/feature/prompt-cache
$ ls tests
test_cache.py
```
<!-- /snippet -->

Both clones and the server agree, and the test file exists.

### Questions

1. Who rejected the push in step 3, your Git or the server? What two values were compared?
2. Which ref of yours did the fetch in step 4 change, and why did that make the bare lease worthless?
3. The two commands in step 5 refused for different reasons. State the condition that each one checks.
4. Immediately after the forced push in the failure scenario, name every place where Asha's test commit still existed.
5. In the recovery, Asha ran `git pull --rebase` and ended on your history, without a duplicate of her test commit and without replaying the old `Add cahce TTL`. Explain why. When does the same mechanism cost someone a commit?
6. A commit message cannot be corrected without rewriting the commit. Given that Asha was building on the branch, what should have happened before step 1?

## Lab 7.5: Upstream configuration and a triangular fork simulation

### Objective

Create a fork as a second bare repository, set up a clone that fetches from the shared repository (`upstream`) and pushes to your fork (`origin`), and follow one feature branch through a rebase onto a moved upstream. Then push to the wrong remote by mistake and make that mistake impossible.

### Prerequisites

Chapter 12, sections 12.5 and 12.10. Lab 7.4 for `--force-with-lease`.

### Setup

```bash
bash labs/ch12/setup-07-5-upstream-triangular.sh
labs/shell m07-5
```

Starting state: the shared repository `server/support-bot.git` and Ravi, its maintainer, with his clone. You have no fork and no clone yet.

### Commands

```bash
# 1. Fork (a server-side copy) and clone the fork
git clone --bare server/support-bot.git forks/you/support-bot.git
git clone forks/you/support-bot.git you/support-bot
cd you/support-bot
git remote set-url origin ../../forks/you/support-bot.git
git remote add upstream ../../server/support-bot.git
git fetch upstream
git remote -v

# 2. Two sets of remote-tracking refs
git show-ref --abbrev
git branch -vv

# 3. Push to the fork by default; start a feature from upstream
git config set remote.pushDefault origin
git config set push.default current
git switch -c feature/streaming upstream/main
mkdir -p app && printf 'def stream(answer):\n    yield answer\n' > app/stream.py
git add app/stream.py
git commit -m "Add streaming responses"

# 4. A bare push goes to the fork
git push
git rev-parse --abbrev-ref @{upstream} @{push}
git branch -vv

# 5. What each server has
git ls-remote --branches upstream
git ls-remote --branches origin

# 6. The shared repository moves: Ravi publishes a commit
cd ../../ravi/support-bot
printf 'model: small-v1\ntop_k: 8\n' > config.yaml
git commit -am "Raise top_k to 8"
git push
cd ../../you/support-bot

# 7. Two comparisons in one status
git config set status.compareBranches "@{upstream} @{push}"
git fetch upstream
git status

# 8. Rebase onto upstream and publish the rewritten branch to the fork
git pull --rebase
git push
git push --force-with-lease
git status

# 9. Bring the fork's main up to date
git switch main
git merge --ff-only upstream/main
git push
git log --oneline --graph --decorate --all -4
```

The `set-url` in step 1 replaces the absolute path that `git clone` recorded with a relative one, so that your output matches the book.

### Expected output

<!-- snippet: ch12/lab-07-5-upstream-triangular/01-fork-and-clone -->
```text
$ git clone --bare server/support-bot.git forks/you/support-bot.git
Cloning into bare repository 'forks/you/support-bot.git'...
done.
$ git clone forks/you/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
done.
$ cd you/support-bot
$ git remote set-url origin ../../forks/you/support-bot.git
$ git remote add upstream ../../server/support-bot.git
$ git fetch upstream
From ../../server/support-bot
 * [new branch]      main       -> upstream/main
$ git remote -v
origin	../../forks/you/support-bot.git (fetch)
origin	../../forks/you/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	../../server/support-bot.git (push)
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/02-refs -->
```text
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
510ee94 refs/remotes/upstream/HEAD
510ee94 refs/remotes/upstream/main
$ git branch -vv
* main 510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/03-configure -->
```text
$ git config set remote.pushDefault origin
$ git config set push.default current
$ git switch -c feature/streaming upstream/main
Switched to a new branch 'feature/streaming'
branch 'feature/streaming' set up to track 'upstream/main'.
$ mkdir -p app && printf 'def stream(answer):\n    yield answer\n' > app/stream.py
$ git add app/stream.py
$ git commit -m "Add streaming responses"
[feature/streaming c6f5b32] Add streaming responses
 1 file changed, 2 insertions(+)
 create mode 100644 app/stream.py
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/04-push-goes-to-fork -->
```text
$ git push
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{upstream} @{push}
upstream/main
origin/feature/streaming
$ git branch -vv
* feature/streaming c6f5b32 [upstream/main: ahead 1] Add streaming responses
  main              510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/05-three-repositories -->
```text
# The shared repository, then your fork:
$ git ls-remote --branches upstream
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
$ git ls-remote --branches origin
c6f5b32c05995740d225f899fcfb82c6371280ee	refs/heads/feature/streaming
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/06-upstream-moves -->
```text
$ cd ../../ravi/support-bot
$ printf 'model: small-v1\ntop_k: 8\n' > config.yaml
$ git commit -am "Raise top_k to 8"
[main 1a0527b] Raise top_k to 8
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../server/support-bot.git
   510ee94..1a0527b  main -> main
$ cd ../../you/support-bot
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/07-two-comparisons -->
```text
$ git config set status.compareBranches "@{upstream} @{push}"
$ git fetch upstream
From ../../server/support-bot
   510ee94..1a0527b  main       -> upstream/main
$ git status
On branch feature/streaming
Your branch and 'upstream/main' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Your branch is up to date with 'origin/feature/streaming'.

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/08-rebase-and-republish -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/streaming.
$ git push
To ../../forks/you/support-bot.git
 ! [rejected]        feature/streaming -> feature/streaming (non-fast-forward)
error: failed to push some refs to '../../forks/you/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../../forks/you/support-bot.git
 + c6f5b32...e86f478 feature/streaming -> feature/streaming (forced update)
$ git status
On branch feature/streaming
Your branch is ahead of 'upstream/main' by 1 commit.

Your branch is up to date with 'origin/feature/streaming'.

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-5-upstream-triangular/09-sync-fork-main -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git merge --ff-only upstream/main
Updating 510ee94..1a0527b
Fast-forward
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../forks/you/support-bot.git
   510ee94..1a0527b  main -> main
$ git log --oneline --graph --decorate --all -4
* e86f478 (origin/feature/streaming, feature/streaming) Add streaming responses
* 1a0527b (HEAD -> main, upstream/main, upstream/HEAD, origin/main, origin/HEAD) Raise top_k to 8
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
```
<!-- /snippet -->

### What happened internally

- **Steps 1 and 2.** Each remote has its own section in `.git/config` and its own namespace of remote-tracking refs, including its own `HEAD`. All five refs name one commit, stored once. `main` tracks `origin/main`, because you cloned the fork.
- **Step 3.** `git switch -c feature/streaming upstream/main` set the upstream of the new branch to `upstream/main` (`branch.feature/streaming.remote=upstream`, `merge=refs/heads/main`).
- **Step 4.** `remote.pushDefault=origin` chose the remote and `push.default=current` chose the name: the push created `feature/streaming` in the fork. `@{upstream}` and `@{push}` now resolve to different refs, and `git branch -vv` shows only the first.
- **Step 7.** `git status` compares the branch with both: diverged from `upstream/main` by one commit each way, and equal to what the fork has.
- **Step 8.** `git pull --rebase` fetched from `upstream` and replayed your commit on Ravi's. The fork still has the commit from before the rebase, so the plain push is not a fast-forward. The forced push with a lease replaces it. Nobody else pushes to this branch of your fork.
- **Step 9.** Your fork's `main` only ever fast-forwards to `upstream/main`. You never commit on it.

### Checkpoint

After step 9, `main`, `origin/main` and `upstream/main` name the same commit (Ravi's), and `feature/streaming` and `origin/feature/streaming` name your rebased commit, one ahead of it. The last transcript above shows exactly this as a graph. If `origin/feature/streaming` is missing from the graph, the push in step 8 did not happen.

### Failure scenario

Out of habit you name a remote and a branch, and the remote is the wrong one:

```bash
git switch feature/streaming
git push upstream feature/streaming
git ls-remote --branches upstream
```

<!-- snippet: ch12/lab-07-5-upstream-triangular/10-failure -->
```text
$ git switch feature/streaming
Switched to branch 'feature/streaming'
Your branch is ahead of 'upstream/main' by 1 commit.

Your branch is up to date with 'origin/feature/streaming'.
$ git push upstream feature/streaming
To ../../server/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git ls-remote --branches upstream
e86f4782d4800659bd3846940460c5d80db710d5	refs/heads/feature/streaming
1a0527b3a3ba14afd58c08d0da0456bdb9c405a9	refs/heads/main
```
<!-- /snippet -->

Your unreviewed branch is now in the shared repository. An explicit remote on the command line overrides `remote.pushDefault`, and nothing on this server objects.

### Recovery

```bash
git push upstream --delete feature/streaming
git remote set-url --push upstream DISABLED
git remote -v
git push upstream feature/streaming
```

<!-- snippet: ch12/lab-07-5-upstream-triangular/11-recovery -->
```text
$ git push upstream --delete feature/streaming
To ../../server/support-bot.git
 - [deleted]         feature/streaming
$ git remote set-url --push upstream DISABLED
$ git remote -v
origin	../../forks/you/support-bot.git (fetch)
origin	../../forks/you/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	DISABLED (push)
$ git push upstream feature/streaming
fatal: 'DISABLED' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

The first command removes the branch from the shared repository. The second gives `upstream` a push URL that is not a repository, so every later push to it from this clone fails before anything is sent.

### Verification

```bash
git ls-remote --branches upstream
git ls-remote --branches origin
git fetch upstream
git config get --all --show-names --regexp "^(remote|push|branch\.feature)"
```

<!-- snippet: ch12/lab-07-5-upstream-triangular/12-verification -->
```text
$ git ls-remote --branches upstream
1a0527b3a3ba14afd58c08d0da0456bdb9c405a9	refs/heads/main
$ git ls-remote --branches origin
e86f4782d4800659bd3846940460c5d80db710d5	refs/heads/feature/streaming
1a0527b3a3ba14afd58c08d0da0456bdb9c405a9	refs/heads/main
$ git fetch upstream
$ git config get --all --show-names --regexp "^(remote|push|branch\.feature)"
remote.origin.url ../../forks/you/support-bot.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
remote.upstream.url ../../server/support-bot.git
remote.upstream.fetch +refs/heads/*:refs/remotes/upstream/*
remote.upstream.pushurl DISABLED
remote.pushdefault origin
push.default current
branch.feature/streaming.remote upstream
branch.feature/streaming.merge refs/heads/main
```
<!-- /snippet -->

The shared repository has only `main`, your fork has both branches, fetching from `upstream` still works, and the configuration shows the whole arrangement in nine lines.

### Questions

1. `feature/streaming` has `upstream/main` as its upstream, yet `git push` created `feature/streaming` in your fork. Which two settings produced that result, and what does each decide?
2. For `main` in this clone, what do `@{upstream}` and `@{push}` resolve to, and why are they the same?
3. In step 8, nobody but you pushes to your fork. Why was the plain `git push` rejected?
4. Section 12.8 calls a forced push dangerous. Why is `--force-with-lease` the right command in step 8?
5. After the mistaken push, your clone had a ref `upstream/feature/streaming`. Which command created it, and which removed it?
6. `DISABLED` is not a Git keyword. Explain exactly why the push fails, and name one limit of this guard.

## Lab 7.6: Prune and "gone" branches

### Objective

Find the remote-tracking refs in your clone that no longer exist on the server, see one of them block a fetch, prune them, clean up the local branches whose upstream is gone, and then watch a deleted branch come back to life through an innocent `git push`.

### Prerequisites

Chapter 12, sections 12.11 and 12.16. `git branch -d` and `-D` from Chapter 7.

### Setup

```bash
bash labs/ch12/setup-07-6-prune-gone.sh
labs/shell m07-6
```

Starting state: your clone has local branches for three server branches and has seen a branch called `release`. Since your last fetch, Asha has merged `feature/reranker` and deleted it on the server, deleted `spike/hybrid-search` unmerged, and the team has replaced `release` by `release/1.0`.

### Commands

```bash
# 1. Your view against the server's
cd you/support-bot
git branch -vv
git branch -r
git ls-remote --branches origin

# 2. A fetch that fails
git fetch

# 3. Preview, then prune while fetching
git remote prune --dry-run origin
git fetch --prune
git branch -r

# 4. Which local branches lost their upstream?
git branch -vv
git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads | grep -F "[gone]"

# 5. A merged branch can be deleted safely
git pull --ff-only
git branch -d feature/reranker

# 6. An unmerged one needs a decision
git branch -d spike/hybrid-search
git log --oneline main..spike/hybrid-search
git branch -D spike/hybrid-search

# 7. Prune on every fetch from now on
git config set fetch.prune true
git config get --show-origin fetch.prune
```

`git branch -D` is a 🔴 command: it deletes a branch whose commits are on no other branch. Step 6 looks at those commits first.

### Expected output

<!-- snippet: ch12/lab-07-6-prune-gone/01-stale-view -->
```text
$ cd you/support-bot
$ git branch -vv
  feature/eval-harness 2b4c64c [origin/feature/eval-harness] Add eval harness entry point
  feature/reranker     336d5ee [origin/feature/reranker] Add reranker stub
* main                 510ee94 [origin/main] Add retrieval config
  spike/hybrid-search  ba1b11e [origin/spike/hybrid-search] Try hybrid search
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/feature/reranker
  origin/main
  origin/release
  origin/spike/hybrid-search
$ git ls-remote --branches origin
2b4c64c997b56198ac65a43b7e098b5c4f7e0d07	refs/heads/feature/eval-harness
64bfb30bada61120550520e0a3e8caae7dcbf3f8	refs/heads/main
64bfb30bada61120550520e0a3e8caae7dcbf3f8	refs/heads/release/1.0
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-6-prune-gone/02-fetch-blocked -->
```text
$ git fetch
error: some local refs could not be updated; try running
 'git remote prune origin' to remove any old, conflicting branches
From ../../server/support-bot
   510ee94..64bfb30  main        -> origin/main
 ! [new branch]      release/1.0 -> origin/release/1.0  (unable to update local ref)
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-6-prune-gone/03-prune -->
```text
$ git remote prune --dry-run origin
Pruning origin
URL: ../../server/support-bot.git
 * [would prune] origin/feature/reranker
 * [would prune] origin/release
 * [would prune] origin/spike/hybrid-search
$ git fetch --prune
From ../../server/support-bot
 - [deleted]         (none)      -> origin/feature/reranker
 - [deleted]         (none)      -> origin/release
 - [deleted]         (none)      -> origin/spike/hybrid-search
 * [new branch]      release/1.0 -> origin/release/1.0
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/main
  origin/release/1.0
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-6-prune-gone/04-gone -->
```text
$ git branch -vv
  feature/eval-harness 2b4c64c [origin/feature/eval-harness] Add eval harness entry point
  feature/reranker     336d5ee [origin/feature/reranker: gone] Add reranker stub
* main                 510ee94 [origin/main: behind 2] Add retrieval config
  spike/hybrid-search  ba1b11e [origin/spike/hybrid-search: gone] Try hybrid search
$ git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads | grep -F "[gone]"
feature/reranker [gone]
spike/hybrid-search [gone]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-6-prune-gone/05-delete-merged -->
```text
$ git pull --ff-only
Updating 510ee94..64bfb30
Fast-forward
 app/reranker.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 app/reranker.py
$ git branch -d feature/reranker
Deleted branch feature/reranker (was 336d5ee).
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-6-prune-gone/06-delete-unmerged -->
```text
$ git branch -d spike/hybrid-search
error: the branch 'spike/hybrid-search' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D spike/hybrid-search'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git log --oneline main..spike/hybrid-search
ba1b11e Try hybrid search
$ git branch -D spike/hybrid-search
Deleted branch spike/hybrid-search (was ba1b11e).
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-6-prune-gone/07-prune-by-default -->
```text
$ git config set fetch.prune true
$ git config get --show-origin fetch.prune
file:.git/config	true
```
<!-- /snippet -->

### What happened internally

- **Step 1.** `git branch -vv` and `git branch -r` read your refs: six remote-tracking entries. `git ls-remote` reads the server: three branches. Three of your remote-tracking refs are stale, and one server branch is unknown to you.
- **Step 2.** The fetch updated `origin/main` and then could not create `origin/release/1.0`, because your stale `origin/release` occupies the name that would have to become a prefix. The exit status is 1 although part of the fetch succeeded.
- **Step 3.** `--prune` deleted the three stale refs first, which freed the name, and then fetched.
- **Step 4.** Pruning removed remote-tracking refs only. The upstream settings of your local branches still name the deleted branches, and Git reports them as `gone`.
- **Step 5.** After the fast-forward, `main` contains the merge of `feature/reranker`, so `-d` accepts the deletion.
- **Step 6.** `spike/hybrid-search` holds a commit that is on no other branch. `-d` refuses, `git log main..spike/hybrid-search` shows what would become unreachable, and `-D` deletes anyway. The commit stays in the object database, and the reflog of `HEAD` still names it from the time the branch was checked out.
- **Step 7.** `fetch.prune=true` is written to this repository's configuration.

### Checkpoint

```bash
git branch -vv
git branch -r
```

<!-- snippet: ch12/lab-07-6-prune-gone/08-checkpoint -->
```text
$ git branch -vv
  feature/eval-harness 2b4c64c [origin/feature/eval-harness] Add eval harness entry point
* main                 64bfb30 [origin/main] Merge branch feature/reranker
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/main
  origin/release/1.0
```
<!-- /snippet -->

Two local branches, both with a live upstream, and remote-tracking refs that match the server exactly.

### Failure scenario

You are on `feature/eval-harness`. Asha deletes that branch on the server. You fetch, which now prunes, and then push out of habit:

```bash
git switch feature/eval-harness
git -C ../../asha/support-bot push origin --delete feature/eval-harness
git fetch
git status
git push
git ls-remote --branches origin
```

<!-- snippet: ch12/lab-07-6-prune-gone/09-failure -->
```text
$ git switch feature/eval-harness
Switched to branch 'feature/eval-harness'
Your branch is up to date with 'origin/feature/eval-harness'.
$ git -C ../../asha/support-bot push origin --delete feature/eval-harness
To ../../server/support-bot.git
 - [deleted]         feature/eval-harness
$ git fetch
From ../../server/support-bot
 - [deleted]         (none)     -> origin/feature/eval-harness
$ git status
On branch feature/eval-harness
Your branch is based on 'origin/feature/eval-harness', but the upstream is gone.
  (use "git branch --unset-upstream" to fixup)

nothing to commit, working tree clean
$ git push
To ../../server/support-bot.git
 * [new branch]      feature/eval-harness -> feature/eval-harness
$ git ls-remote --branches origin
2b4c64c997b56198ac65a43b7e098b5c4f7e0d07	refs/heads/feature/eval-harness
64bfb30bada61120550520e0a3e8caae7dcbf3f8	refs/heads/main
64bfb30bada61120550520e0a3e8caae7dcbf3f8	refs/heads/release/1.0
```
<!-- /snippet -->

`git status` said that the upstream is gone. `git push` created the branch again: the branch that the team deleted is back on the server.

### Recovery

```bash
git push origin --delete feature/eval-harness
git branch --unset-upstream
git push
```

<!-- snippet: ch12/lab-07-6-prune-gone/10-recovery -->
```text
$ git push origin --delete feature/eval-harness
To ../../server/support-bot.git
 - [deleted]         feature/eval-harness
$ git branch --unset-upstream
$ git push
fatal: The current branch feature/eval-harness has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature/eval-harness

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

Deleting the branch on the server repeats Asha's decision. Removing the upstream setting takes away the destination that a bare `git push` used, so the same command now stops and asks.

### Verification

```bash
git ls-remote --branches origin
git branch -vv
```

<!-- snippet: ch12/lab-07-6-prune-gone/11-verification -->
```text
$ git ls-remote --branches origin
64bfb30bada61120550520e0a3e8caae7dcbf3f8	refs/heads/main
64bfb30bada61120550520e0a3e8caae7dcbf3f8	refs/heads/release/1.0
$ git branch -vv
* feature/eval-harness 2b4c64c Add eval harness entry point
  main                 64bfb30 [origin/main] Merge branch feature/reranker
```
<!-- /snippet -->

The server has `main` and `release/1.0`. Your `feature/eval-harness` is a purely local branch with no upstream.

### Questions

1. Why did the first `git fetch` fail, and why did the same fetch succeed with `--prune`?
2. `git fetch --prune` deleted three remote-tracking refs. Did it delete or change any local branch? Which output told you which local branches had lost their upstream?
3. `git branch -d feature/reranker` succeeded and `git branch -d spike/hybrid-search` refused. What does `-d` check?
4. After `git branch -D spike/hybrid-search`, where in your clone is commit `ba1b11e` still recorded, and what would you type to get the branch back?
5. In the failure scenario, which settings made a bare `git push` re-create the deleted branch, and why did the warning in `git status` not stop it?
6. After `--unset-upstream` the bare push refused. With `push.autoSetupRemote=true` it would have pushed again. What does that tell you about combining `fetch.prune` with `push.autoSetupRemote`, and what is the reliable way to avoid resurrecting branches?

## Lab 7.7: Refspec surgery

### Objective

Read and edit fetch refspecs: widen a single-branch clone, exclude a namespace, map pull-request refs, and push with explicit refspecs. Then break a clone with a mirror-style refspec and repair it from the reflog.

### Prerequisites

Chapter 12, sections 12.3 and 12.12. Lab 7.1.

### Setup

```bash
bash labs/ch12/setup-07-7-refspec-surgery.sh
labs/shell m07-7
```

Starting state: the server has `main`, `release/0.1`, a bot branch `dependabot/pip/requests-2.33`, and one ref outside `refs/heads/`, `refs/pull/7/head`, which imitates the ref a hosting platform keeps for pull request 7. Your clone was made with `--single-branch`, as a CI job would make it.

### Commands

```bash
# 1. A narrow clone
cd you/support-bot
git config get --all remote.origin.fetch
git branch -r
git ls-remote origin
git switch release/0.1

# 2. Add one branch
git remote set-branches --add origin release/0.1
git config get --all remote.origin.fetch
git fetch
git switch release/0.1

# 3. All branches
git remote set-branches origin "*"
git config get --all remote.origin.fetch
git fetch

# 4. All branches except the bot's
git config set --append remote.origin.fetch "^refs/heads/dependabot/*"
git branch -r -d origin/dependabot/pip/requests-2.33
git fetch
git branch -r

# 5. A ref outside refs/heads: once, then permanently
git fetch origin refs/pull/7/head
git log --oneline -1 FETCH_HEAD
git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
git fetch
git config get --all remote.origin.fetch

# 6. Push refspecs: preview, create under another name, delete
printf '0.1.1\n' > VERSION
git commit -am "Bump version to 0.1.1"
git push --dry-run origin HEAD:refs/heads/review/version-bump
git push origin release/0.1:refs/heads/review/version-bump
git push origin :review/version-bump
```

### Expected output

<!-- snippet: ch12/lab-07-7-refspec-surgery/01-narrow -->
```text
$ cd you/support-bot
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git ls-remote origin
510ee948fb6354959cf03862f0ebe47c58eb2a74	HEAD
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/dependabot/pip/requests-2.33
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
bd50a6d123f39435b3a506911022af1d615df7fb	refs/heads/release/0.1
a3b0283892821a8f9fc95bda5760237390817915	refs/pull/7/head
$ git switch release/0.1
fatal: invalid reference: release/0.1
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-7-refspec-surgery/02-one-more-branch -->
```text
$ git remote set-branches --add origin release/0.1
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
+refs/heads/release/0.1:refs/remotes/origin/release/0.1
$ git fetch
From ../../server/support-bot
 * [new branch]      release/0.1 -> origin/release/0.1
$ git switch release/0.1
Switched to a new branch 'release/0.1'
branch 'release/0.1' set up to track 'origin/release/0.1'.
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-7-refspec-surgery/03-all-branches -->
```text
$ git remote set-branches origin "*"
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
$ git fetch
From ../../server/support-bot
 * [new branch]      dependabot/pip/requests-2.33 -> origin/dependabot/pip/requests-2.33
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-7-refspec-surgery/04-exclude-a-namespace -->
```text
$ git config set --append remote.origin.fetch "^refs/heads/dependabot/*"
$ git branch -r -d origin/dependabot/pip/requests-2.33
Deleted remote-tracking branch origin/dependabot/pip/requests-2.33 (was 510ee94).
$ git fetch
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/release/0.1
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-7-refspec-surgery/05-pull-request-refs -->
```text
$ git fetch origin refs/pull/7/head
From ../../server/support-bot
 * branch            refs/pull/7/head -> FETCH_HEAD
$ git log --oneline -1 FETCH_HEAD
a3b0283 Add reranker stub
$ git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
$ git fetch
From ../../server/support-bot
 * [new ref]         refs/pull/7/head -> origin/pr/7
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
^refs/heads/dependabot/*
+refs/pull/*/head:refs/remotes/origin/pr/*
```
<!-- /snippet -->

<!-- snippet: ch12/lab-07-7-refspec-surgery/06-push-refspecs -->
```text
$ printf '0.1.1\n' > VERSION
$ git commit -am "Bump version to 0.1.1"
[release/0.1 66c5d63] Bump version to 0.1.1
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push --dry-run origin HEAD:refs/heads/review/version-bump
To ../../server/support-bot.git
 * [new branch]      HEAD -> review/version-bump
$ git push origin release/0.1:refs/heads/review/version-bump
To ../../server/support-bot.git
 * [new branch]      release/0.1 -> review/version-bump
$ git push origin :review/version-bump
To ../../server/support-bot.git
 - [deleted]         review/version-bump
```
<!-- /snippet -->

### What happened internally

- **Step 1.** The server has four refs besides `HEAD`. Your refspec names one branch, so your clone has one remote-tracking branch, and `git switch release/0.1` has nothing to guess from.
- **Step 2.** `set-branches --add` appended a second refspec. The fetch created `origin/release/0.1`, and now the switch can create the local branch with its upstream.
- **Step 3.** `set-branches origin "*"` replaced both refspecs with the usual wildcard. The fetch brought the bot branch.
- **Step 4.** The negative refspec removes matching refs from what a fetch selects. It does not delete the ref you already had; `git branch -r -d` does. The next fetch prints nothing: the bot branch is no longer selected.
- **Step 5.** A ref named on the command line is fetched into `FETCH_HEAD` only. The appended refspec maps every `refs/pull/<n>/head` to `refs/remotes/origin/pr/<n>`, and the next fetch creates `origin/pr/7`.
- **Step 6.** `--dry-run` shows what would be created. The second push creates `review/version-bump` on the server from your local `release/0.1`; the third deletes it with an empty source. Your commit is still unpublished on `release/0.1` itself.

### Checkpoint

```bash
git branch -vv
git show-ref --abbrev
```

<!-- snippet: ch12/lab-07-7-refspec-surgery/07-checkpoint -->
```text
$ git branch -vv
  main        510ee94 [origin/main] Add retrieval config
* release/0.1 66c5d63 [origin/release/0.1: ahead 1] Bump version to 0.1.1
$ git show-ref --abbrev
510ee94 refs/heads/main
66c5d63 refs/heads/release/0.1
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
a3b0283 refs/remotes/origin/pr/7
bd50a6d refs/remotes/origin/release/0.1
```
<!-- /snippet -->

`release/0.1` is one commit ahead of its upstream. Besides `origin/HEAD`, your remote-tracking refs are `main`, `release/0.1` and `pr/7`, with no bot branch.

### Failure scenario

Someone pastes a mirror-style refspec from a wiki page into this ordinary clone:

```bash
git config get --all remote.origin.fetch > ../refspecs.saved
git config set --all remote.origin.fetch "+refs/heads/*:refs/heads/*"
git fetch
git switch --detach
git fetch
git branch -vv
```

<!-- snippet: ch12/lab-07-7-refspec-surgery/08-failure -->
```text
$ git config get --all remote.origin.fetch > ../refspecs.saved
$ git config set --all remote.origin.fetch "+refs/heads/*:refs/heads/*"
$ git fetch
fatal: refusing to fetch into branch 'refs/heads/release/0.1' checked out at '$LAB/ch12/lab-07-7-refspec-surgery/you/support-bot'
[exit status: 128]
$ git switch --detach
HEAD is now at 66c5d63 Bump version to 0.1.1
$ git fetch
From ../../server/support-bot
 * [new branch]      dependabot/pip/requests-2.33 -> dependabot/pip/requests-2.33
 + 66c5d63...bd50a6d release/0.1 -> release/0.1  (forced update)
$ git branch -vv
* (HEAD detached at 66c5d63)   66c5d63 Bump version to 0.1.1
  dependabot/pip/requests-2.33 510ee94 Add retrieval config
  main                         510ee94 [main] Add retrieval config
  release/0.1                  bd50a6d [release/0.1] Add VERSION file
```
<!-- /snippet -->

The first fetch refused, because it would have overwritten the branch you have checked out. Detaching `HEAD` removed that protection, and the second fetch force-updated your local `release/0.1` to the server's commit. Your version bump is no longer on any branch, and the bot branch has become a local branch.

### Recovery

```bash
git reflog show release/0.1
git branch -f release/0.1 release/0.1@{1}
git branch -D dependabot/pip/requests-2.33

git remote set-branches origin "*"
git config set --append remote.origin.fetch "^refs/heads/dependabot/*"
git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
git switch release/0.1
```

<!-- snippet: ch12/lab-07-7-refspec-surgery/09-recovery -->
```text
$ git reflog show release/0.1
bd50a6d release/0.1@{0}: fetch: forced-update
66c5d63 release/0.1@{1}: commit: Bump version to 0.1.1
bd50a6d release/0.1@{2}: branch: Created from refs/remotes/origin/release/0.1
$ git branch -f release/0.1 release/0.1@{1}
$ git branch -D dependabot/pip/requests-2.33
Deleted branch dependabot/pip/requests-2.33 (was 510ee94).
$ git remote set-branches origin "*"
$ git config set --append remote.origin.fetch "^refs/heads/dependabot/*"
$ git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
$ git switch release/0.1
Switched to branch 'release/0.1'
Your branch is ahead of 'origin/release/0.1' by 1 commit.
  (use "git push" to publish your local commits)
```
<!-- /snippet -->

The branch's reflog recorded the forced update, so the entry before it is your commit. `git branch -f` moves the branch back (it is allowed because the branch is not checked out). Then the three refspecs are written again.

### Verification

```bash
git config get --all remote.origin.fetch
cat ../refspecs.saved
git fetch
git branch -vv
git push
```

<!-- snippet: ch12/lab-07-7-refspec-surgery/10-verification -->
```text
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
^refs/heads/dependabot/*
+refs/pull/*/head:refs/remotes/origin/pr/*
$ cat ../refspecs.saved
+refs/heads/*:refs/remotes/origin/*
^refs/heads/dependabot/*
+refs/pull/*/head:refs/remotes/origin/pr/*
$ git fetch
$ git branch -vv
  main        510ee94 [origin/main] Add retrieval config
* release/0.1 66c5d63 [origin/release/0.1: ahead 1] Bump version to 0.1.1
$ git push
To ../../server/support-bot.git
   bd50a6d..66c5d63  release/0.1 -> release/0.1
```
<!-- /snippet -->

The refspecs equal the saved ones, a fetch changes nothing, and the version bump is finally published.

### Questions

1. `git ls-remote` listed `release/0.1`, and `git switch release/0.1` still failed at first. Why?
2. What exactly did `git remote set-branches --add origin release/0.1` and `git remote set-branches origin "*"` write?
3. After adding the negative refspec, why was `git branch -r -d` still needed, and why did the following fetch print nothing?
4. `git fetch origin refs/pull/7/head` created no ref. Where was the result, and what changed after the refspec was appended?
5. In the failure scenario the first fetch refused and the second overwrote `release/0.1`. What protected you the first time, and what part did the `+` play the second time?
6. The recovery depended on `release/0.1@{1}`. Why did that entry exist, and where would the same accident have left no such record?

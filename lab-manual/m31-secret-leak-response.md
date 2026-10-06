# Module 31 labs: Secret-leak response and history rewriting as an operation

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.10, 21B.11 and 21B.14 to 21B.19, first. Every transcript under "Expected output" is real output of the replay script `labs/ch21b/lab-31-1-tabletop.sh`. The secret is a dummy, `DUMMY-KEY-not-a-real-secret-12345`, spelled so that no scanner pattern matches it, and its "issuer" is a small script inside the sandbox.

## How this lab works

Lab 31.1 is a tabletop exercise: a complete incident, played on a bare "server" with three clones, from the first report to prevention. It runs entirely in the lab shell.

```bash
bash labs/ch21b/setup-31-1-tabletop.sh       # build the starting state (run again to start over)
labs/shell m31-1                             # open the isolated lab shell in that sandbox
labs/run ch21b/lab-31-1-tabletop             # optional: replay the lab and print its transcript
```

Two things are simulated, and you should know exactly how:

- **The issuer.** `provider/keyctl` stands in for the console of the service that issued the key: `status KEY`, `revoke KEY`, `issue`. In a real incident this step happens in the provider's console and is the one that matters most.
- **The rewrite tool.** The lab rewrites history with `git filter-branch`, **only because it ships with Git** and the course installs nothing. Git's own manual says its use is not recommended. On a real repository use git-filter-repo, with the commands in Chapter 21B, section 21B.16. The mechanics you will observe (new IDs for every descendant, tags, old objects, the stale clone) are the same with either tool.

What a bare repository cannot show is the GitHub side: pull request refs, forks, cached views and the Support request. Section 21B.19 covers those; the lab marks the points where they would apply.

**Do the lab twice.** First with this guide. Then run the setup again and work from the symptom card alone: *"The provider emailed: our staging LLM key is in the ragdesk repository. It has been there since Monday."* Write the six step names on paper and do not touch Git until step 1 is done.

Differences between your terminal and the transcripts: lines such as `[exit status: 128]` are printed by the replay script (by hand, run `echo $?`); lines that start with `#` are notes; `$LAB` stands for the lab root. The setup uses the fixed lab clock, so its commits have the IDs printed here. `git filter-branch` preserves the dates of the commits it rewrites, so the rewritten commits also get the printed IDs. Commits you create by hand (the one in step 3, merges, rebased commits) get the real time and other IDs, and so does everything rewritten on top of them.

Answers to the Questions are in [solutions/m31-lab-answers.md](../solutions/m31-lab-answers.md). Write your own first.

## Lab 31.1: The tabletop: a committed secret, from report to prevention

### Objective

Lead the response to a secret that was committed, followed by three more commits, pushed, tagged and fetched by two teammates. Take it through contain, assess, eradicate, recover, communicate and prevent, and experience the failure that makes a history rewrite an operation: a stale clone that pushes the secret back.

### Prerequisites

- Chapter 21B, sections 21B.10 to 21B.19.
- Chapter 13 (reflogs, pruning), Chapter 12 (force pushes), Chapter 9 (`git rebase --onto`).

### Setup

```bash
bash labs/ch21b/setup-31-1-tabletop.sh
labs/shell m31-1
```

| Directory | What it is |
|---|---|
| `server.git` | the bare repository that plays the server |
| `ragdesk` | your clone |
| `asha` | Asha's clone, with one commit she has not pushed |
| `ravi` | Ravi's clone, no local work |
| `provider/` | the stand-in for the key's issuer |
| `kit/` | a `pre-commit` and a `pre-receive` hook for step 6 |

### Commands

Type every command yourself. `first` is a shell variable that you set in step 2 and use until the end, so stay in one shell.

**Step 0. Confirm the report.**

```bash
ls
cd ragdesk
git grep -n LLM_API_KEY -- .env
git log --oneline -S'DUMMY-KEY-not-a-real-secret-12345'
git status -sb
```

**Step 1. Contain: revoke at the issuer, before any Git command changes anything.**

```bash
../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
../provider/keyctl revoke DUMMY-KEY-not-a-real-secret-12345
../provider/keyctl issue
../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
```

**Step 2. Assess: first commit, author, time, refs, other secrets, first push.**

```bash
first=$(git log --format=%h --diff-filter=A -- .env); echo $first
git log -1 --format='%h%nauthor:    %an <%ae>%ncommitted: %cd%nsubject:   %s' --date=iso-local $first
git branch -a --contains $first
git tag --contains $first
git rev-list --count $first..origin/main
git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | sort | uniq -c
git reflog show origin/main
```

**Step 3. Eradicate, part one: the tip.** Stop tracking the file, ignore it, provide an example file, push normally.

```bash
git rm -q --cached .env
printf '.env\n' > .gitignore
printf 'LLM_API_KEY=\nLLM_BASE_URL=https://llm.example.com\n' > .env.example
git add .gitignore .env.example && git commit -q -m 'Stop tracking .env; add .env.example'
git push -q origin main
git grep -c DUMMY-KEY origin/main || echo "tip is clean"
git grep -c DUMMY-KEY v0.2.0
```

**Step 3, part two: the decision.** The key is revoked. In this tabletop the incident lead decides to rewrite anyway, because the same `.env` pattern would be used for customer data next quarter and the team wants to have practised. Write that decision down, then announce the freeze (step 5 has the message).

**Step 3, part three: the rewrite, in a fresh mirror clone.**

```bash
cd ..
git clone -q --mirror server.git cleanup.git
cd cleanup.git
git for-each-ref --format="%(objectname) %(refname)" > ../refs-before.txt
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter.log 2>&1
grep -v 'seconds passed' ../filter.log
```

Verify, remove the tool's backup refs, prune, record the ref map.

```bash
git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
git reflog expire --expire=now --all && git gc -q --prune=now
git cat-file -t $first
git for-each-ref --format="%(objectname) %(refname)" > ../refs-after.txt
join -1 2 -2 2 ../refs-before.txt ../refs-after.txt | awk '{printf "%-28s %.7s -> %.7s\n", $1, $2, $3}'
```

Force-push every ref, then deal with what the server still holds.

```bash
git push --force --mirror origin
git -C ../server.git show $first:.env
git -C ../server.git gc -q --prune=now
git -C ../server.git cat-file -t $first
```

**Step 4. Recover: your own clone is stale too.** Delete it and clone again. Check that you are in the sandbox directory before you type `rm -rf`.

```bash
cd ..
pwd
rm -rf ragdesk
git clone -q server.git ragdesk
git -C ragdesk log --oneline
git -C ragdesk tag -l
(cd ragdesk && git grep -l DUMMY-KEY $(git rev-list --all) | wc -l)
```

In a real incident this step also deploys the new key from step 1 to every consumer.

**Step 5. Communicate.** Write the message to the team now, with the facts from your transcript: what was exposed and since when, that it was revoked and when, the first changed commit, the old and new tips from the ref map, and the instruction "do not pull, do not push from an existing clone; save your work, delete the clone, clone again, re-apply by rebase or patch, never merge". The template is in the [security guide](../guides/security-guide.md), section 6, step 5.

**Step 6. Prevent, and test the prevention.** Install the guard on the server and the hook in your clone. Then play Ravi, who did not read the message: he pulls and pushes.

```bash
cp kit/pre-receive server.git/hooks/pre-receive
cp kit/pre-commit ragdesk/.git/hooks/pre-commit
cd ravi
git pull -q --no-rebase
git log --oneline --graph -4
git push
```

Ravi has no local work, so his clone is cleaned by resetting, refetching tags and pruning.

```bash
git reset -q --hard origin/main
git tag -l | xargs git tag -d
git fetch -q --prune --tags
git reflog expire --expire=now --all && git gc -q --prune=now
git cat-file -t $first
git status -sb
cd ..
```

### Expected output

Step 0 and step 1:

<!-- snippet: ch21b/lab-31-1-tabletop/01-confirm -->
```text
$ ls
asha
home
kit
provider
ragdesk
ravi
server.git
$ cd ragdesk
$ git grep -n LLM_API_KEY -- .env
.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
$ git log --oneline -S'DUMMY-KEY-not-a-real-secret-12345'
0805fd8 Add staging settings
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-31-1-tabletop/02-contain -->
```text
$ ../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
ACTIVE   DUMMY-KEY-not-a-real-secret-12345
$ ../provider/keyctl revoke DUMMY-KEY-not-a-real-secret-12345
revoked  DUMMY-KEY-not-a-real-secret-12345
$ ../provider/keyctl issue
issued   DUMMY-KEY-rotated-not-a-real-secret-2
$ ../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
REVOKED  DUMMY-KEY-not-a-real-secret-12345
```
<!-- /snippet -->

Step 2. The secret entered in `0805fd8`, three commits were made on top of it, and it is contained in `main`, in Asha's pushed branch and in the tag `v0.2.0`:

<!-- snippet: ch21b/lab-31-1-tabletop/03-assess -->
```text
$ first=$(git log --format=%h --diff-filter=A -- .env); echo $first
0805fd8
$ git log -1 --format='%h%nauthor:    %an <%ae>%ncommitted: %cd%nsubject:   %s' --date=iso-local $first
0805fd8
author:    Lab User <you@example.com>
committed: 2026-09-07 10:10:00 +0530
subject:   Add staging settings
$ git branch -a --contains $first
* main
  remotes/origin/feature/streaming
  remotes/origin/main
$ git tag --contains $first
v0.2.0
$ git rev-list --count $first..origin/main
3
$ git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | sort | uniq -c
   5 DUMMY-KEY-not-a-real-secret-12345
$ git reflog show origin/main
d4b8762 refs/remotes/origin/main@{0}: update by push
```
<!-- /snippet -->

Step 3. The tip is clean and the tag still serves the file:

<!-- snippet: ch21b/lab-31-1-tabletop/04-eradicate-tip -->
```text
$ git rm -q --cached .env
$ printf '.env\n' > .gitignore
$ printf 'LLM_API_KEY=\nLLM_BASE_URL=https://llm.example.com\n' > .env.example
$ git add .gitignore .env.example && git commit -q -m 'Stop tracking .env; add .env.example'
$ git push -q origin main
$ git grep -c DUMMY-KEY origin/main || echo "tip is clean"
tip is clean
$ git grep -c DUMMY-KEY v0.2.0
v0.2.0:.env:1
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-31-1-tabletop/05-rewrite -->
```text
$ cd ..
$ git clone -q --mirror server.git cleanup.git
$ cd cleanup.git
$ git for-each-ref --format="%(objectname) %(refname)" > ../refs-before.txt
$ FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter.log 2>&1
$ grep -v 'seconds passed' ../filter.log
Ref 'refs/heads/feature/streaming' was rewritten
Ref 'refs/heads/main' was rewritten
WARNING: Ref 'refs/tags/v0.1.0' is unchanged
Ref 'refs/tags/v0.2.0' was rewritten
v0.1.0 -> v0.1.0 (987a49db5aa45d6cb1e4b10024438f21b8e28444 -> 987a49db5aa45d6cb1e4b10024438f21b8e28444)
v0.2.0 -> v0.2.0 (64b9b890cf46c6a921380d722eaf0b33d790bb9a -> 66a99cccb3cd6ac483eccafadf8c4804770799ea)
```
<!-- /snippet -->

The first scan after the rewrite still counts 5, because `--all` includes the backup refs under `refs/original/`:

<!-- snippet: ch21b/lab-31-1-tabletop/06-verify-rewrite -->
```text
$ git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
       5
$ git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
$ git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
       0
$ git reflog expire --expire=now --all && git gc -q --prune=now
$ git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
$ git for-each-ref --format="%(objectname) %(refname)" > ../refs-after.txt
$ join -1 2 -2 2 ../refs-before.txt ../refs-after.txt | awk '{printf "%-28s %.7s -> %.7s\n", $1, $2, $3}'
refs/heads/feature/streaming 7fae871 -> ba9f0e0
refs/heads/main              b51c127 -> 0177e32
refs/tags/v0.1.0             b4a2514 -> b4a2514
refs/tags/v0.2.0             c38ee42 -> 17124a2
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-31-1-tabletop/07-force-push -->
```text
$ git push --force --mirror origin 2>&1
To $LAB/ch21b/lab-31-1-tabletop/server.git
 + 7fae871...ba9f0e0 feature/streaming -> feature/streaming (forced update)
 + b51c127...0177e32 main -> main (forced update)
 + c38ee42...17124a2 v0.2.0 -> v0.2.0 (forced update)
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-31-1-tabletop/08-server-prune -->
```text
# The force push moved the refs. The old commits are still in the server repository:
$ git -C ../server.git show $first:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
# On your own server you can prune. On GitHub only GitHub Support can (section 21B.19).
$ git -C ../server.git gc -q --prune=now
$ git -C ../server.git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
```
<!-- /snippet -->

Step 4:

<!-- snippet: ch21b/lab-31-1-tabletop/09-recover-own-clone -->
```text
$ cd ..
$ rm -rf ragdesk
$ git clone -q server.git ragdesk
$ git -C ragdesk log --oneline
0177e32 Stop tracking .env; add .env.example
c8ce738 Document setup in README
51e2d95 Add request timeout
66a99cc Add retry with backoff
0ac4257 Add staging settings
987a49d Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ git -C ragdesk tag -l
v0.1.0
v0.2.0
$ (cd ragdesk && git grep -l DUMMY-KEY $(git rev-list --all) | wc -l)
       0
```
<!-- /snippet -->

Step 6. Ravi's pull merged the old history into the new one, and the server declined the push:

<!-- snippet: ch21b/lab-31-1-tabletop/10-prevent -->
```text
$ cp kit/pre-receive server.git/hooks/pre-receive
$ cp kit/pre-commit ragdesk/.git/hooks/pre-commit
# Test the server guard with a clone that still has the old history: Ravi pulls and pushes.
$ cd ravi
$ git pull -q --no-rebase 2>&1
$ git log --oneline --graph -4
*   b412d8e Merge branch 'main' of ../server
|\  
| * 0177e32 Stop tracking .env; add .env.example
| * c8ce738 Document setup in README
| * 51e2d95 Add request timeout
$ git push 2>&1
remote: push declined: refs/heads/main: commit b412d8e contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-31-1-tabletop/11-clean-a-clone-without-local-work -->
```text
$ git reset -q --hard origin/main
$ git tag -l | xargs git tag -d
Deleted tag 'v0.1.0' (was b4a2514)
Deleted tag 'v0.2.0' (was c38ee42)
$ git fetch -q --prune --tags
$ git reflog expire --expire=now --all && git gc -q --prune=now
$ git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
$ git status -sb
## main...origin/main
$ cd ..
```
<!-- /snippet -->

### What happened internally

- **Step 1** changed nothing in Git. It is the only step that made the leaked value harmless, and it did so for every copy at once.
- **Step 3, tip.** A new commit with a tree that lacks `.env`. Every older commit kept its tree, which is why `v0.2.0` still printed the file.
- **Step 3, rewrite.** `filter-branch` walked every commit of every ref and recreated each with `.env` removed from its tree. The four commits below `0805fd8` came out byte-identical and kept their IDs. `0805fd8` got a new tree and became `0ac4257`; every commit above it records its parent's ID and so changed too, up to the new tip `0177e32`. The annotated tag object `c38ee42` was recreated as `17124a2`, pointing at the rewritten commit. The old objects stayed in `cleanup.git`, reachable from `refs/original/` and reflogs, until you deleted those and pruned.
- **Force push.** `receive-pack` on the server set three refs to new values. The old commits became unreachable there and remained readable by ID until `git gc --prune=now`. A bare repository keeps no reflogs by default, so nothing else held them. **On GitHub you cannot run that command:** unreachable commits, cached views and pull request refs remain until GitHub Support acts, and Support acts only where rotation cannot mitigate the risk.
- **Ravi's pull** fetched the forced update and merged `origin/main` into his `main`, which still pointed into the old history. The merge commit `b412d8e` has the old tip as a parent, so pushing it would deliver `0805fd8` again. The hook found the key in the merge commit's own tree, because the old side of the merge still had `.env`.

```text
  before:   ...987a49d--0805fd8--64b9b89--b509fe3--d4b8762--b51c127   main      (v0.2.0 at 64b9b89)
  after:    ...987a49d--0ac4257--66a99cc--51e2d95--c8ce738--0177e32   main      (v0.2.0 at 66a99cc)
```

### Checkpoint

Before the failure scenario, you should be able to state from your own transcript:

1. The first changed commit and the old and new ID of `main`, `feature/streaming` and `v0.2.0`.
2. Why the scan printed 5 and then 0 without any rewrite in between.
3. The three places where the secret existed after the force push and before any cleanup of clones.

### Failure scenario

This is the state of every team that stops after step 5: the history is clean, and nothing guards the server. Switch the guard off, then play Asha. She has one unpushed commit and does what she does every morning.

```bash
mv server.git/hooks/pre-receive kit/pre-receive.off
cd asha
git log --oneline -2
git pull -q --no-rebase
git push
cd ..
git -C server.git log --oneline main -S'DUMMY-KEY'
git -C server.git show $first:.env | head -1
```

<!-- snippet: ch21b/lab-31-1-tabletop/12-failure -->
```text
# The state of a team that stopped before prevention: no guard on the server.
$ mv server.git/hooks/pre-receive kit/pre-receive.off
$ cd asha
$ git log --oneline -2
95f98b0 Add contains metric
d4b8762 Document setup in README
$ git pull -q --no-rebase 2>&1
$ git push 2>&1
To ../server.git
   0177e32..9d6c12c  main -> main
$ cd ..
$ git -C server.git log --oneline main -S'DUMMY-KEY'
0805fd8 Add staging settings
$ git -C server.git show $first:.env | head -1
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
```
<!-- /snippet -->

Her push is an ordinary fast-forward from `0177e32` to her merge commit. No force was needed, and a rule that forbids force pushes would not have stopped it. The secret is on the server's `main` again.

### Recovery

**The server first.** `cleanup.git` still holds the clean refs. Push them again, restore the guard, prune.

```bash
cd cleanup.git
git push --force --mirror origin
cd ..
mv kit/pre-receive.off server.git/hooks/pre-receive
git -C server.git gc -q --prune=now
git -C server.git cat-file -t $first
```

<!-- snippet: ch21b/lab-31-1-tabletop/13-recovery-server -->
```text
$ cd cleanup.git
$ git push --force --mirror origin 2>&1
To $LAB/ch21b/lab-31-1-tabletop/server.git
 + 9d6c12c...0177e32 main -> main (forced update)
$ cd ..
$ mv kit/pre-receive.off server.git/hooks/pre-receive
$ git -C server.git gc -q --prune=now
$ git -C server.git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
```
<!-- /snippet -->

That force push removed Asha's merge commit, and with it her own commit, from the server. Her work exists only in her clone now, which is why the clone is repaired and not deleted.

**Then Asha's clone.** Find the commit her work was based on, undo the merge, and replay only her own commit onto the clean history.

```bash
cd asha
git fetch -q
git reflog show origin/main
git reflog show main -3
old=$(git reflog show main --format=%h | tail -1); echo $old
git reset -q --hard 'main@{1}'
git rebase -q --onto origin/main $old
git log --oneline -3
```

<!-- snippet: ch21b/lab-31-1-tabletop/14-recovery-clone -->
```text
$ cd asha
$ git fetch -q 2>&1
$ git reflog show origin/main
0177e32 refs/remotes/origin/main@{0}: fetch -q: forced-update
9d6c12c refs/remotes/origin/main@{1}: update by push
0177e32 refs/remotes/origin/main@{2}: pull -q --no-rebase: forced-update
$ git reflog show main -3
9d6c12c main@{0}: pull -q --no-rebase: Merge made by the 'ort' strategy.
95f98b0 main@{1}: commit: Add contains metric
d4b8762 main@{2}: clone: from $LAB/ch21b/lab-31-1-tabletop/server.git
$ old=$(git reflog show main --format=%h | tail -1); echo $old
d4b8762
# Undo the merge, then replay only her own commit onto the clean history.
$ git reset -q --hard 'main@{1}'
$ git rebase -q --onto origin/main $old 2>&1
$ git log --oneline -3
01e4fd0 Add contains metric
0177e32 Stop tracking .env; add .env.example
c8ce738 Document setup in README
```
<!-- /snippet -->

`$old` is `d4b8762`, the tip she cloned, read from the oldest entry of her `main` reflog. `git rebase --onto origin/main $old` replays the commits after `$old`, which is exactly her one commit. Without `--onto`, `git rebase origin/main` would treat every old commit that is missing from the new history as hers, and would try to replay "Add staging settings" with its `.env`.

Then remove the old history from her clone and push her work.

```bash
git tag -l | xargs git tag -d
git fetch -q --prune --tags
git reflog expire --expire=now --all && git gc -q --prune=now
git cat-file -t $first
git push
cd ..
```

<!-- snippet: ch21b/lab-31-1-tabletop/15-recovery-clone-prune -->
```text
$ git tag -l | xargs git tag -d
Deleted tag 'v0.1.0' (was b4a2514)
Deleted tag 'v0.2.0' (was c38ee42)
$ git fetch -q --prune --tags
$ git reflog expire --expire=now --all && git gc -q --prune=now
$ git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
$ git push 2>&1
To ../server.git
   0177e32..01e4fd0  main -> main
$ cd ..
```
<!-- /snippet -->

The push passes the guard: her rebased commit `01e4fd0` sits on the clean history.

### Verification

```bash
./provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
git -C server.git log --oneline main
git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
git -C server.git fsck --no-progress --unreachable | wc -l
for c in ragdesk asha ravi; do printf "%s: " $c; git -C $c cat-file -t $first 2>&1; done
cat refs-after.txt | cut -c1-7,41-
```

<!-- snippet: ch21b/lab-31-1-tabletop/16-verification -->
```text
$ ./provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
REVOKED  DUMMY-KEY-not-a-real-secret-12345
$ git -C server.git log --oneline main
01e4fd0 Add contains metric
0177e32 Stop tracking .env; add .env.example
c8ce738 Document setup in README
51e2d95 Add request timeout
66a99cc Add retry with backoff
0ac4257 Add staging settings
987a49d Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
       0
$ git -C server.git fsck --no-progress --unreachable | wc -l
       0
$ for c in ragdesk asha ravi; do printf "%s: " $c; git -C $c cat-file -t $first 2>&1; done
ragdesk: fatal: Not a valid object name 0805fd8
asha: fatal: Not a valid object name 0805fd8
ravi: fatal: Not a valid object name 0805fd8
$ cat refs-after.txt | cut -c1-7,41-
ba9f0e0 refs/heads/feature/streaming
0177e32 refs/heads/main
b4a2514 refs/tags/v0.1.0
17124a2 refs/tags/v0.2.0
```
<!-- /snippet -->

The key is revoked; the server's history is clean on every ref and holds no unreachable objects; none of the three clones can resolve the first changed commit; Asha's work is on `main`. What you could not verify here, and must on GitHub: forks, pull request refs, cached views, and the issuer's log of whether the key was used.

### Questions

1. Step 1 changed nothing in the repository. Why is it first, and what would you have to check at the issuer that this lab's stand-in cannot show?
2. After the rewrite, `987a49d` kept its ID and `64b9b89` did not, although neither commit touched `.env`. Why?
3. The rewrite ran in a mirror clone and ended with `git push --force --mirror`. Name one thing that command does besides updating refs, and the precaution that follows.
4. Ravi's push was declined and Asha's was accepted. Compare the two pushes: were they force pushes? What on GitHub would correspond to the guard?
5. In Asha's clone, why `git rebase --onto origin/main $old` and not `git rebase origin/main` or `git pull --rebase`?
6. Why delete all tags before `git fetch --prune --tags`?
7. List what a real GitHub repository would still hold after your force push, and who can remove each.
8. The lead decided to rewrite although the key was revoked. Give the argument against that decision that a CTO should hear.

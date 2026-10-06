# Module 18 labs: Transfer, scale, and performance

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch26/` (Labs 18.1 and 18.3) or `labs/ch24/` (Labs 18.2 and 18.4). Read [Chapter 26: Performance](../textbook/ch26-performance.md) for Labs 18.1 and 18.3 and [Chapter 24: Monorepos](../textbook/ch24-monorepos.md) for Labs 18.2 and 18.4. The transcripts show counts of objects and of work done, never timings.

## How to run these labs

Each lab has a setup script that builds the repository `orbit`, and where needed a bare repository `server/orbit.git` that plays the hosting server, with a fixed clock. The commit IDs of `orbit` in your sandbox are therefore the ones printed here. Commits that you create yourself in the lab shell get the real time and other IDs. From the course root:

```bash
bash labs/ch26/setup-18-1-clones.sh           # build the starting state (run again to start over)
labs/shell m18-1                              # open the isolated lab shell in that sandbox
labs/run ch26/lab-18-1-clone-three-ways       # optional: replay the whole lab and print its transcript
```

| Lab | Setup script | Sandbox | Replay |
|---|---|---|---|
| 18.1 | `labs/ch26/setup-18-1-clones.sh` | `m18-1` | `ch26/lab-18-1-clone-three-ways` |
| 18.2 | `labs/ch24/setup-18-2-sparse.sh` | `m18-2` | `ch24/lab-18-2-sparse-checkout` |
| 18.3 | `labs/ch26/setup-18-3-bundles.sh` | `m18-3` | `ch26/lab-18-3-bundle-round-trip` |
| 18.4 | `labs/ch24/setup-18-4-scalar-by-hand.sh` | `m18-4` | `ch24/lab-18-4-scalar-by-hand` |

Four things to know before you start:

- **The server is a directory, reached by URL.** Clone with `"file://$PWD/server/orbit.git"`, typed in the sandbox directory. A plain path would make `git clone` copy files and ignore `--depth` and `--filter`. The setup scripts set `uploadpack.allowFilter` on the server so that partial clones work.
- **Nothing here installs a scheduler or starts a daemon.** No lab runs `git maintenance start`, `git maintenance register` or `scalar`. Lab 18.4 explains why and what you may do on your own machine.
- Lines such as `[exit status: 1]` are printed by the replay scripts; by hand, run `echo $?`. Lines that start with `#` are notes from the replay script.
- Answers to the questions are in [solutions/m18-lab-answers.md](../solutions/m18-lab-answers.md). Write your own first.

## Lab 18.1: Clone one repository three ways and compare what arrived

### Objective

Make a full, a shallow and a blobless clone of the same repository, count what each one holds, ask all three the same history questions, and repair the shallow one when a release script fails in it.

### Prerequisites

Chapter 26, sections 26.10 to 26.13. Chapter 12, sections 12.3 and 12.12, for refspecs.

### Setup

```bash
bash labs/ch26/setup-18-1-clones.sh
labs/shell m18-1
```

The sandbox holds `server/orbit.git`: 94 commits on `main`, a branch `feature/rerank-cache` with two more, five annotated tags named after projects.

### Commands

```bash
git clone "file://$PWD/server/orbit.git" full
git clone --depth 1 "file://$PWD/server/orbit.git" shallow
git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless

for c in full shallow blobless; do echo "== $c"; git -C $c cat-file --batch-all-objects --batch-check="%(objecttype)" 2>/dev/null | sort | uniq -c; done
for c in full shallow blobless; do echo "== $c: $(git -C $c for-each-ref | wc -l) refs, fetch refspec $(git -C $c config get remote.origin.fetch)"; done
cat shallow/.git/shallow
git -C blobless config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"
git -C blobless rev-list --objects --all --missing=print | grep -c '^?'
```

Before you run the three questions below, fill in the table with your predictions.

| Question | full | shallow | blobless |
|---|---|---|---|
| How many commits changed `services/ranker`? | | | |
| Which commit last changed line 3 of `services/gateway/routes.py`? | | | |
| What does `git describe --match 'gateway/v*'` print? | | | |

```bash
for c in full shallow blobless; do echo "$c: $(git -C $c log --oneline -- services/ranker | wc -l)"; done
for c in full shallow blobless; do echo "$c: $(git -C $c blame -s -L 3,3 services/gateway/routes.py)"; done
for c in full shallow blobless; do echo "$c: $(git -C $c describe --match 'gateway/v*' 2>&1)"; done
```

### Expected output

<!-- snippet: ch26/lab-18-1-clone-three-ways/01-clone -->
```text
$ git clone "file://$PWD/server/orbit.git" full
Cloning into 'full'...
$ git clone --depth 1 "file://$PWD/server/orbit.git" shallow
Cloning into 'shallow'...
$ git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless
Cloning into 'blobless'...
```
<!-- /snippet -->

<!-- snippet: ch26/lab-18-1-clone-three-ways/02-objects -->
```text
$ for c in full shallow blobless; do echo "== $c"; git -C $c cat-file --batch-all-objects --batch-check="%(objecttype)" 2>/dev/null | sort | uniq -c; done
== full
 122 blob
  96 commit
   5 tag
 284 tree
== shallow
  33 blob
   1 commit
   1 tag
  20 tree
== blobless
  33 blob
  96 commit
   5 tag
 284 tree
```
<!-- /snippet -->

<!-- snippet: ch26/lab-18-1-clone-three-ways/03-refs-and-config -->
```text
$ for c in full shallow blobless; do echo "== $c: $(git -C $c for-each-ref | wc -l) refs, fetch refspec $(git -C $c config get remote.origin.fetch)"; done
== full:        9 refs, fetch refspec +refs/heads/*:refs/remotes/origin/*
== shallow:        4 refs, fetch refspec +refs/heads/main:refs/remotes/origin/main
== blobless:        9 refs, fetch refspec +refs/heads/*:refs/remotes/origin/*
$ cat shallow/.git/shallow
100bb993157cac87afe81008782cd27cd39f8c9d
[exit status: 0]
$ git -C blobless config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"
remote.origin.promisor true
remote.origin.partialclonefilter blob:none
$ git -C blobless rev-list --objects --all --missing=print | grep -c '^?'
89
```
<!-- /snippet -->

<!-- snippet: ch26/lab-18-1-clone-three-ways/04-questions -->
```text
# Question 1: how many commits changed services/ranker?
$ for c in full shallow blobless; do echo "$c: $(git -C $c log --oneline -- services/ranker | wc -l)"; done
full:       13
shallow:        1
blobless:       13
# Question 2: which commit last changed line 3 of the gateway routes?
$ for c in full shallow blobless; do echo "$c: $(git -C $c blame -s -L 3,3 services/gateway/routes.py)"; done
full: e6f20d31 3)     ("POST", "/v1/search/1"),
shallow: ^100bb99 3)     ("POST", "/v1/search/1"),
blobless: e6f20d31 3)     ("POST", "/v1/search/1"),
# Question 3: what is the latest gateway release before this commit?
$ for c in full shallow blobless; do echo "$c: $(git -C $c describe --match 'gateway/v*' 2>&1)"; done
full: gateway/v1.1.0-28-g100bb99
shallow: fatal: No names found, cannot describe anything.
blobless: gateway/v1.1.0-28-g100bb99
```
<!-- /snippet -->

### What happened internally

All three requests asked for the same tips. The shallow one added `deepen 1`, so the server sent one commit with its 20 trees and 33 blobs and named it as the boundary; the client wrote that ID into `.git/shallow` and, because `--depth` implies `--single-branch`, a refspec for `main` only. One tag object arrived because it points at the tip. The blobless request added `filter blob:none`: the server sent all 96 commits, all 284 trees and all five tags, and the checkout then fetched the 33 blobs it needed in a second pack. 89 objects that the history refers to are not in that repository, and its configuration names `origin` as the remote that has promised them.

The full and the blobless clone give the same three answers. The shallow clone answers 1, blames the boundary commit (the `^` marks it), and cannot describe: the first two are wrong answers with exit status 0.

### Checkpoint

The blobless clone answered the second question correctly. What did that cost? Predict whether the number of packs and the number of missing objects changed, then look:

```bash
ls blobless/.git/objects/pack/*.pack | wc -l
git -C blobless rev-list --objects --all --missing=print | grep -c '^?'
```

<!-- snippet: ch26/lab-18-1-clone-three-ways/05-cost-of-asking -->
```text
# The blobless clone answered question 2 by downloading. Count its packs now:
$ ls blobless/.git/objects/pack/*.pack | wc -l
      14
$ git -C blobless rev-list --objects --all --missing=print | grep -c '^?'
77
```
<!-- /snippet -->

Two packs became 14, and 12 of the 89 missing objects are now local: `git blame` fetched one old version of the file at a time.

### Failure scenario

A release script runs in the shallow clone. It needs the last gateway release, the gateway's changes since then, and the files a feature branch touched.

```bash
cd shallow
git describe --match 'gateway/v*'
git log --oneline gateway/v1.1.0..HEAD -- services/gateway
git fetch -q --depth 1 origin feature/rerank-cache:refs/remotes/origin/feature/rerank-cache
git diff --name-only HEAD...origin/feature/rerank-cache
```

<!-- snippet: ch26/lab-18-1-clone-three-ways/06-failure -->
```text
# Failure scenario: a release script runs in the shallow clone.
$ cd shallow
$ git describe --match 'gateway/v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git log --oneline gateway/v1.1.0..HEAD -- services/gateway
fatal: bad revision 'gateway/v1.1.0..HEAD'
[exit status: 128]
$ git fetch -q --depth 1 origin feature/rerank-cache:refs/remotes/origin/feature/rerank-cache
$ git diff --name-only HEAD...origin/feature/rerank-cache
fatal: HEAD...origin/feature/rerank-cache: no merge base
[exit status: 128]
```
<!-- /snippet -->

Three different messages, one cause. The tag is not there, so `git describe` finds no name and `gateway/v1.1.0` is a bad revision. The branch tip was fetched with depth 1 as well, so the two tips have no common ancestor in this repository and the three-dot diff has no merge base. Nothing is damaged. The clone holds what it was asked to hold.

### Recovery

```bash
git fetch --unshallow
git rev-parse --is-shallow-repository
git remote set-branches origin '*'
git fetch
git config get remote.origin.fetch
```

<!-- snippet: ch26/lab-18-1-clone-three-ways/07-recovery -->
```text
$ git fetch --unshallow
From file://$LAB/ch26/lab-18-1-clone-three-ways/server/orbit
 * [new tag]         gateway/v1.0.0 -> gateway/v1.0.0
 * [new tag]         gateway/v1.1.0 -> gateway/v1.1.0
 * [new tag]         ranker/v0.9.0 -> ranker/v0.9.0
 * [new tag]         schemas/v1.0.0 -> schemas/v1.0.0
$ git rev-parse --is-shallow-repository
false
# The clone still follows one branch only. Widen the refspec and fetch again:
$ git remote set-branches origin '*'
$ git fetch
$ git config get remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
```
<!-- /snippet -->

`git fetch --unshallow` 🟢 fetched the history behind the boundary, removed `.git/shallow`, and brought the tags that now have their commits. The clone still followed one branch. `git remote set-branches origin '*'` 🟢 rewrote the refspec, and the next fetch created the other remote-tracking branch.

### Verification

```bash
git describe --match 'gateway/v*'
git log --oneline gateway/v1.1.0..HEAD -- services/gateway
git diff --name-only HEAD...origin/feature/rerank-cache
git rev-list --count --all
git fsck
```

<!-- snippet: ch26/lab-18-1-clone-three-ways/08-verification -->
```text
$ git describe --match 'gateway/v*'
gateway/v1.1.0-28-g100bb99
$ git log --oneline gateway/v1.1.0..HEAD -- services/gateway
100bb99 schemas, gateway, ingest: add the tenant field in one change
cb65af7 gateway: add search route 12
5f20f82 gateway: add search route 11
47dda3a gateway: add search route 10
$ git diff --name-only HEAD...origin/feature/rerank-cache
services/ranker/config.yaml
services/ranker/model.py
$ git rev-list --count --all
96
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

The three commands of the release script now answer, and the repository has all 96 commits.

### Questions

1. The shallow clone holds 33 blobs and so does the blobless clone. Why is one of them able to answer history questions and the other not?
2. `git cat-file -p HEAD` in the shallow clone prints a `parent` line. Why does `git log` show no parent, and what would break if Git removed the line from the object instead?
3. Which of the three history questions made the blobless clone talk to the server, which did not, and what decides that?
4. After `git fetch --unshallow` the clone still had only `origin/main`. Why, and which command changed that?
5. A CI job computes "files changed by this pull request" with a three-dot diff. Which of the three clone shapes can it use, and which is the cheapest that is still correct?
6. You make a blobless clone on Friday and take the laptop on a flight. Name two commands that will work in the air and two that will fail, and the one command you should have run at the gate.

## Lab 18.2: Cone-mode sparse-checkout

### Objective

Narrow a clone to the directories you work in, read the definition and the index, widen the cone, and clean up after a helper script and a scratch file that landed outside it, without losing the scratch file.

### Prerequisites

Chapter 24, sections 24.4 and 24.5. Chapter 5 for the index and `git ls-files`.

### Setup

```bash
bash labs/ch24/setup-18-2-sparse.sh
labs/shell m18-2
```

### Commands

```bash
git clone "file://$PWD/server/orbit.git" dev
cd dev
git ls-files | wc -l
ls

git sparse-checkout set services/gateway libs/schemas
git sparse-checkout list
ls -A
ls services libs
git status

cat .git/info/sparse-checkout
git config list --worktree
git ls-files -t | cut -c1 | sort | uniq -c
git ls-files -t libs
```

### Expected output

<!-- snippet: ch24/lab-18-2-sparse-checkout/01-clone -->
```text
$ git clone "file://$PWD/server/orbit.git" dev
Cloning into 'dev'...
$ cd dev
$ git ls-files | wc -l
      33
$ ls
docs
libs
pipelines
pyproject.toml
README.md
services
tools
```
<!-- /snippet -->

<!-- snippet: ch24/lab-18-2-sparse-checkout/02-narrow -->
```text
$ git sparse-checkout set services/gateway libs/schemas
$ git sparse-checkout list
libs/schemas
services/gateway
$ ls -A
.git
.gitignore
libs
pyproject.toml
README.md
services
$ ls services libs
libs:
schemas

services:
gateway
$ git status
On branch main
Your branch is up to date with 'origin/main'.

You are in a sparse checkout with 43% of tracked files present.

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ch24/lab-18-2-sparse-checkout/03-inside -->
```text
$ cat .git/info/sparse-checkout
/*
!/*/
/libs/
!/libs/*/
/services/
!/services/*/
/libs/schemas/
/services/gateway/
$ git config list --worktree
core.sparsecheckout=true
core.sparsecheckoutcone=true
$ git ls-files -t | cut -c1 | sort | uniq -c
  14 H
  19 S
$ git ls-files -t libs
H libs/schemas/__init__.py
H libs/schemas/events.py
H libs/schemas/v1/click.json
H libs/schemas/v1/document_indexed.json
H libs/schemas/v1/feedback.json
H libs/schemas/v1/search_request.json
H libs/schemas/v1/session.json
S libs/tokenizer/tokenizer.py
S libs/tokenizer/vocab.txt
```
<!-- /snippet -->

### What happened internally

`git sparse-checkout set` 🟡 wrote eight patterns into `.git/info/sparse-checkout`: the top level, `libs` and `services` as parent directories (their own files, no subdirectories), and the two named directories with everything below them. It set `core.sparseCheckout` and `core.sparseCheckoutCone` in `.git/config.worktree`. Then it went through the index, set the skip-worktree bit on the 19 entries the patterns do not select, and removed those files from the working tree. The index still has 33 entries, `HEAD` did not move, and no object was added or deleted. `libs/tokenizer` is in the index with `S`, and absent from disk.

### Checkpoint

Predict which directories exist after the next command, and the percentage that `git status` will print. Then run it.

```bash
git sparse-checkout add docs/runbooks
find . -path ./.git -prune -o -type d -print | sort
git status | sed -n 4p
```

<!-- snippet: ch24/lab-18-2-sparse-checkout/04-checkpoint -->
```text
# Predict the directories and the percentage before you run the next two commands.
$ git sparse-checkout add docs/runbooks
$ find . -path ./.git -prune -o -type d -print | sort
.
./docs
./docs/runbooks
./libs
./libs/schemas
./libs/schemas/v1
./services
./services/gateway
./services/gateway/tests
$ git status | sed -n 4p
You are in a sparse checkout with 55% of tracked files present.
```
<!-- /snippet -->

`docs` appeared as a parent directory, so `docs/architecture.md` is present too: 18 of 33 files, 55%. Work inside the cone needs nothing special:

```bash
printf 'timeout_ms: 600\nupstream: ranker\n' > services/gateway/config.yaml
git commit -q -am 'gateway: lower the upstream timeout to 600 ms'
git log --oneline -1
git show --stat --format= HEAD
```

<!-- snippet: ch24/lab-18-2-sparse-checkout/05-work -->
```text
# Ordinary work inside the cone needs nothing special:
$ printf 'timeout_ms: 600\nupstream: ranker\n' > services/gateway/config.yaml
$ git commit -q -am 'gateway: lower the upstream timeout to 600 ms'
$ git log --oneline -1
1b7616a gateway: lower the upstream timeout to 600 ms
$ git show --stat --format= HEAD
 services/gateway/config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Your commit ID differs from `1b7616a`, because you committed at the real time.

### Failure scenario

A tool writes into a directory outside the cone: a scratch result and a helper script that you want to keep.

```bash
mkdir -p pipelines/eval
printf 'recall@10 = 0.83\n' > pipelines/eval/results.tmp
printf 'import json\n\n\ndef summarize(path):\n    return len([json.loads(line) for line in open(path)])\n' > pipelines/eval/summarize.py
git status --short
git add pipelines/eval/summarize.py
git commit -m "eval: add a summary helper"
```

<!-- snippet: ch24/lab-18-2-sparse-checkout/06-failure -->
```text
# Failure scenario: a tool writes into a directory that is outside the cone.
$ mkdir -p pipelines/eval
$ printf 'recall@10 = 0.83\n' > pipelines/eval/results.tmp
$ printf 'import json\n\n\ndef summarize(path):\n    return len([json.loads(line) for line in open(path)])\n' > pipelines/eval/summarize.py
$ git status --short
?? pipelines/eval/results.tmp
?? pipelines/eval/summarize.py
$ git add pipelines/eval/summarize.py
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
pipelines/eval/summarize.py
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
[exit status: 1]
$ git commit -m "eval: add a summary helper"
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

You are in a sparse checkout with 55% of tracked files present.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	pipelines/eval/results.tmp
	pipelines/eval/summarize.py

nothing added to commit but untracked files present (use "git add" to track)
[exit status: 1]
```
<!-- /snippet -->

`git add` refused to update the index for a path outside the sparse-checkout definition and exited with status 1, so the commit had nothing to record. A script that ignores exit statuses would report "committed" here and lose the helper at the next cleanup.

### Recovery

```bash
git add --sparse pipelines/eval/summarize.py
git commit -q -m 'eval: add a summary helper'
git status --short
git sparse-checkout reapply
find pipelines -type f
git sparse-checkout clean --dry-run
mv pipelines/eval/results.tmp ../results.tmp
git sparse-checkout clean -f
ls pipelines
```

<!-- snippet: ch24/lab-18-2-sparse-checkout/07-recovery -->
```text
# The helper is wanted: stage it with --sparse and commit it.
$ git add --sparse pipelines/eval/summarize.py
$ git commit -q -m 'eval: add a summary helper'
$ git status --short
?? pipelines/eval/results.tmp
# The committed file is still on disk outside the cone. Reapply the definition:
$ git sparse-checkout reapply
warning: directory 'pipelines/' contains untracked files, but is not in the sparse-checkout cone
$ find pipelines -type f
pipelines/eval/results.tmp
# What is left is the scratch file. The cleanup would delete it with its directory:
$ git sparse-checkout clean --dry-run
Would remove pipelines/
# It is not garbage, so move it out first, then clean:
$ mv pipelines/eval/results.tmp ../results.tmp
$ git sparse-checkout clean -f
Removing pipelines/
$ ls pipelines
ls: pipelines: No such file or directory
[exit status: 1]
```
<!-- /snippet -->

`git add --sparse` 🟢 staged the helper, and the commit recorded it. It was then a tracked file on disk outside the cone, and `git sparse-checkout reapply` 🟡 set its skip-worktree bit and removed it from the working tree; the warning says that the directory stays because of the untracked file. `git sparse-checkout clean --dry-run` showed what the cleanup would remove: the whole `pipelines/` directory, the scratch file included. That file was never in Git, so `clean -f` 🔴 would have destroyed it beyond recovery. Moving it out first is the whole recovery.

### Verification

```bash
git status
git sparse-checkout list
git ls-files -t pipelines/eval
git show --stat --format=%s HEAD
cat ../results.tmp
git fsck
git sparse-checkout disable
ls
git ls-files -t | cut -c1 | sort | uniq -c
```

<!-- snippet: ch24/lab-18-2-sparse-checkout/08-verification -->
```text
$ git status
On branch main
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

You are in a sparse checkout with 53% of tracked files present.

nothing to commit, working tree clean
$ git sparse-checkout list
docs/runbooks
libs/schemas
services/gateway
$ git ls-files -t pipelines/eval
S pipelines/eval/cases.jsonl
S pipelines/eval/run_eval.py
S pipelines/eval/summarize.py
$ git show --stat --format=%s HEAD
eval: add a summary helper

 pipelines/eval/summarize.py | 5 +++++
 1 file changed, 5 insertions(+)
$ cat ../results.tmp
recall@10 = 0.83
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch24/lab-18-2-sparse-checkout/09-disable -->
```text
$ git sparse-checkout disable
$ ls
docs
libs
pipelines
pyproject.toml
README.md
services
tools
$ git ls-files -t | cut -c1 | sort | uniq -c
  34 H
```
<!-- /snippet -->

The working tree is clean, the cone is unchanged, the helper is committed and carries `S` like its neighbours, and the scratch file is safe outside the repository. `git sparse-checkout disable` 🟡 brings back every tracked file: 34 entries, all `H`.

### Questions

1. After `git sparse-checkout set services/gateway libs/schemas`, where is `libs/tokenizer/vocab.txt`: in the working tree, in the index, in `HEAD`, in the object database? Which command proves each answer?
2. You asked for `docs/runbooks` and got `docs/architecture.md` as well. State the rule, and say what it means for a directory whose parent holds large files.
3. Why are the sparse-checkout switches in `.git/config.worktree` and not in `.git/config`?
4. `git add pipelines/eval/summarize.py` failed and `git commit` then printed "nothing added to commit". Explain both, and name the two ways to get the file committed.
5. Compare what narrowing a cone does to a tracked file, an untracked file and an ignored file in a directory that leaves the cone.
6. `git sparse-checkout clean -f` and `git clean -fd` both delete untracked files. What does each look at, and why is the dry run of the first not optional?

## Lab 18.3: A bundle round trip

### Objective

Move a repository to a site with no network route as a bundle, send an incremental update, bring work back from that site the same way, and recover when one update is lost in transit.

### Prerequisites

Chapter 26, section 26.14. Chapter 12, section 12.13, and Chapter 13, section 13.14, for the basics of bundles.

### Setup

```bash
bash labs/ch26/setup-18-3-bundles.sh
labs/shell m18-3
```

The sandbox holds `orbit`, packed, with automatic maintenance switched off. It plays the connected site. The directory `transfer` that you create plays the courier.

### Commands

```bash
mkdir transfer
cd orbit
git bundle create ../transfer/orbit-full.bundle --all
git bundle verify ../transfer/orbit-full.bundle | tail -2
git tag lastbundle/site-b main
cd ..

git clone transfer/orbit-full.bundle site-b
git -C site-b log --oneline -1
git -C site-b branch -a
git -C site-b tag -l | wc -l

cd orbit
printf 'timeout_ms: 600\nupstream: ranker\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 600 ms'
git tag -a gateway/v1.2.0 -m 'gateway 1.2.0'
git bundle create ../transfer/orbit-update-1.bundle lastbundle/site-b..main gateway/v1.2.0
git bundle verify ../transfer/orbit-update-1.bundle
git tag -f lastbundle/site-b main
cd ..

cd site-b
git bundle verify --quiet ../transfer/orbit-update-1.bundle
git fetch ../transfer/orbit-update-1.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'
git merge --ff-only origin/main
```

### Expected output

<!-- snippet: ch26/lab-18-3-bundle-round-trip/01-full-bundle -->
```text
$ mkdir transfer
$ cd orbit
$ git bundle create ../transfer/orbit-full.bundle --all
$ git bundle verify ../transfer/orbit-full.bundle | tail -2
../transfer/orbit-full.bundle is okay
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
# Remember what the other site now has (the manual of git bundle uses a tag for this):
$ git tag lastbundle/site-b main
$ cd ..
```
<!-- /snippet -->

<!-- snippet: ch26/lab-18-3-bundle-round-trip/02-site-b -->
```text
$ git clone transfer/orbit-full.bundle site-b
Cloning into 'site-b'...
$ git -C site-b log --oneline -1
100bb99 schemas, gateway, ingest: add the tenant field in one change
$ git -C site-b branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/feature/rerank-cache
  remotes/origin/main
$ git -C site-b tag -l | wc -l
       5
```
<!-- /snippet -->

<!-- snippet: ch26/lab-18-3-bundle-round-trip/03-update-out -->
```text
# Work continues at the connected site:
$ cd orbit
$ printf 'timeout_ms: 600\nupstream: ranker\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 600 ms'
$ git tag -a gateway/v1.2.0 -m 'gateway 1.2.0'
$ git bundle create ../transfer/orbit-update-1.bundle lastbundle/site-b..main gateway/v1.2.0
$ git bundle verify ../transfer/orbit-update-1.bundle
../transfer/orbit-update-1.bundle is okay
The bundle contains these 2 refs:
65a5f46a8d03c9dc3874674e86cc214b44e24535 refs/heads/main
7a87196129206e084b78ca7141e54ac1cbd851a6 refs/tags/gateway/v1.2.0
The bundle requires this ref:
100bb993157cac87afe81008782cd27cd39f8c9d 
The bundle uses this hash algorithm: sha1
$ git tag -f lastbundle/site-b main
Updated tag 'lastbundle/site-b' (was 100bb99)
$ cd ..
```
<!-- /snippet -->

<!-- snippet: ch26/lab-18-3-bundle-round-trip/04-update-in -->
```text
$ cd site-b
$ git bundle verify --quiet ../transfer/orbit-update-1.bundle
../transfer/orbit-update-1.bundle is okay
[exit status: 0]
$ git fetch ../transfer/orbit-update-1.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'
From ../transfer/orbit-update-1.bundle
   100bb99..65a5f46  main           -> origin/main
 * [new tag]         gateway/v1.2.0 -> gateway/v1.2.0
$ git merge --ff-only origin/main
Updating 100bb99..65a5f46
Fast-forward
 services/gateway/config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Your IDs for the new commit and tag differ from the transcript; the prerequisite `100bb99` is the same.

### What happened internally

`git bundle create --all` 🟢 wrote a header with every ref and a pack with every reachable object: "The bundle records a complete history". The tag `lastbundle/site-b` is your own bookkeeping; it records what the other site has, and it was created after the bundle, so it is not in it. `git clone` treated the file as a remote.

The second bundle was made from a range. Git packed only the objects that `lastbundle/site-b..main` adds, and wrote the excluded commit into the header as a prerequisite: "The bundle requires this ref". At the receiving site, `git bundle verify` checked that the prerequisite exists there, and `git fetch` with explicit refspecs updated `origin/main` and created the tag. Nothing moved the local branch until `git merge --ff-only`.

### Checkpoint

Send work back the same way. Before you run `git bundle create`, predict the prerequisite of the bundle.

```bash
printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
git bundle create ../transfer/site-b-1.bundle origin/main..main
git bundle list-heads ../transfer/site-b-1.bundle
cd ../orbit
git fetch ../transfer/site-b-1.bundle main:refs/remotes/site-b/main
git merge --ff-only site-b/main
git log --oneline -3
```

<!-- snippet: ch26/lab-18-3-bundle-round-trip/05-way-back -->
```text
# Work at the isolated site, sent back the same way:
$ printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
$ git bundle create ../transfer/site-b-1.bundle origin/main..main
$ git bundle list-heads ../transfer/site-b-1.bundle
abcb4dd332b01640cf92ca83ed3638e74e0ca1d4 refs/heads/main
$ cd ../orbit
$ git fetch ../transfer/site-b-1.bundle main:refs/remotes/site-b/main
From ../transfer/site-b-1.bundle
 * [new branch]      main       -> site-b/main
$ git merge --ff-only site-b/main
Updating 65a5f46..abcb4dd
Fast-forward
 services/ranker/config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline -3
abcb4dd ranker: return the top 20
65a5f46 gateway: lower the upstream timeout to 600 ms
100bb99 schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

At `site-b`, `origin/main` is exactly "what the connected site already has", so `origin/main..main` is the right range and its lower end is the prerequisite.

### Failure scenario

Two more updates are cut at the connected site, and the courier loses the first of them.

```bash
printf 'BATCH_SIZE = 1000\n' > services/ingest/settings.py && git commit -q -am 'ingest: raise the batch size to 1000'
git bundle create ../transfer/orbit-update-2.bundle lastbundle/site-b..main && git tag -f lastbundle/site-b main
printf 'epochs: 20\nlearning_rate: 0.0003\nbatch_size: 32\n' > pipelines/training/config.yaml && git commit -q -am 'training: train for 20 epochs'
git bundle create ../transfer/orbit-update-3.bundle lastbundle/site-b..main && git tag -f lastbundle/site-b main
rm ../transfer/orbit-update-2.bundle
cd ../site-b
git bundle verify ../transfer/orbit-update-3.bundle
git fetch ../transfer/orbit-update-3.bundle 'refs/heads/*:refs/remotes/origin/*'
```

<!-- snippet: ch26/lab-18-3-bundle-round-trip/06-failure -->
```text
# Failure scenario: two more updates are cut, and only the second one reaches the site.
$ printf 'BATCH_SIZE = 1000\n' > services/ingest/settings.py && git commit -q -am 'ingest: raise the batch size to 1000'
$ git bundle create ../transfer/orbit-update-2.bundle lastbundle/site-b..main && git tag -f lastbundle/site-b main
Updated tag 'lastbundle/site-b' (was 65a5f46)
$ printf 'epochs: 20\nlearning_rate: 0.0003\nbatch_size: 32\n' > pipelines/training/config.yaml && git commit -q -am 'training: train for 20 epochs'
$ git bundle create ../transfer/orbit-update-3.bundle lastbundle/site-b..main && git tag -f lastbundle/site-b main
Updated tag 'lastbundle/site-b' (was ed94f2a)
$ rm ../transfer/orbit-update-2.bundle
$ cd ../site-b
$ git bundle verify ../transfer/orbit-update-3.bundle
error: Repository lacks these prerequisite commits:
error: ed94f2a3aae3d3dc02355dce0cccc35bd4136dd7 
[exit status: 1]
$ git fetch ../transfer/orbit-update-3.bundle 'refs/heads/*:refs/remotes/origin/*'
error: Repository lacks these prerequisite commits:
error: ed94f2a3aae3d3dc02355dce0cccc35bd4136dd7 
[exit status: 1]
```
<!-- /snippet -->

The third bundle requires the commit that the second one would have delivered. Both `verify` and `fetch` refuse and name it. Nothing was changed at `site-b`. The bookkeeping tag at the connected site is now wrong as well: it claims the site has a commit that never arrived.

### Recovery

Do not guess. Ask the site what it has, and cut a bundle from exactly there. Use the ID that your `site-b` prints in place of the one in the transcript.

```bash
git rev-parse main
cd ../orbit
git bundle create ../transfer/orbit-catchup.bundle <id-from-site-b>..main
git bundle verify ../transfer/orbit-catchup.bundle 2>&1 | grep -A1 requires
cd ../site-b
git bundle verify --quiet ../transfer/orbit-catchup.bundle
git fetch ../transfer/orbit-catchup.bundle 'refs/heads/*:refs/remotes/origin/*'
git merge --ff-only origin/main
```

<!-- snippet: ch26/lab-18-3-bundle-round-trip/07-recovery -->
```text
# The site reports what it has:
$ git rev-parse main
abcb4dd332b01640cf92ca83ed3638e74e0ca1d4
# The connected site cuts a bundle from exactly there:
$ cd ../orbit
$ git bundle create ../transfer/orbit-catchup.bundle abcb4dd332b01640cf92ca83ed3638e74e0ca1d4..main
$ git bundle verify ../transfer/orbit-catchup.bundle 2>&1 | grep -A1 requires
The bundle requires this ref:
abcb4dd332b01640cf92ca83ed3638e74e0ca1d4 
$ cd ../site-b
$ git bundle verify --quiet ../transfer/orbit-catchup.bundle
../transfer/orbit-catchup.bundle is okay
[exit status: 0]
$ git fetch ../transfer/orbit-catchup.bundle 'refs/heads/*:refs/remotes/origin/*'
From ../transfer/orbit-catchup.bundle
   65a5f46..81bb510  main       -> origin/main
$ git merge --ff-only origin/main
Updating abcb4dd..81bb510
Fast-forward
 pipelines/training/config.yaml | 2 +-
 services/ingest/settings.py    | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

The basis is `main` at `site-b`, a commit that both sides hold because the connected site merged it in the checkpoint. The catch-up bundle contains both lost commits. Applying the lost bundle first, if a copy exists, would have worked equally well.

### Verification

```bash
git -C ../orbit rev-parse main
git rev-parse main origin/main
git log --oneline -5
git tag -l | wc -l
git fsck
```

<!-- snippet: ch26/lab-18-3-bundle-round-trip/08-verification -->
```text
$ git -C ../orbit rev-parse main
81bb510fd9c2926c73931929dca5fcb012310672
$ git rev-parse main origin/main
81bb510fd9c2926c73931929dca5fcb012310672
81bb510fd9c2926c73931929dca5fcb012310672
$ git log --oneline -5
81bb510 training: train for 20 epochs
ed94f2a ingest: raise the batch size to 1000
abcb4dd ranker: return the top 20
65a5f46 gateway: lower the upstream timeout to 600 ms
100bb99 schemas, gateway, ingest: add the tenant field in one change
$ git tag -l | wc -l
       6
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

Both sites name the same commit as `main`, and `site-b` has six tags: the five it started with and `gateway/v1.2.0`. The bookkeeping tag `lastbundle/site-b` never left the connected site, because no bundle named it.

### Questions

1. What is in the header of an incremental bundle that is not in the header of a full one, and what does Git do with it?
2. Why did `git clone transfer/orbit-full.bundle site-b` work while cloning an incremental bundle fails?
3. The update bundle was fetched with two explicit refspecs. What would a plain `git pull ../transfer/orbit-update-1.bundle main` have updated, and what would it have left out?
4. The connected site moved its tag `lastbundle/site-b` when it created a bundle, not when the other site confirmed receipt. Explain how that produced the wrong basis, and propose a bookkeeping rule that cannot go wrong in this way.
5. What does a bundle not carry that a copy of the `.git` directory would? Name three things.
6. When would you use `git clone --bundle-uri` instead of sending bundles by hand?

## Lab 18.4: The clone that `scalar clone` builds, made by hand

### Objective

Build a blobless, sparse clone in the layout `scalar` uses, apply a selection of its settings, run its hourly maintenance tasks once in the foreground, and find out what such a clone can and cannot do when the server is unreachable.

### Prerequisites

Chapter 24, sections 24.4 to 24.7. Chapter 26, sections 26.3 and 26.12.

### Setup

```bash
bash labs/ch24/setup-18-4-scalar-by-hand.sh
labs/shell m18-4
```

**Why this lab does not run `scalar clone`.** `scalar clone` works against a local repository. A contained test made for this course (Git 2.55.0, macOS) showed that it also starts a file-system monitor daemon for the new working tree, even with `--no-maintenance`, and that without that option it installs a maintenance schedule on your machine. The lab rules of this course allow neither, so the replay builds the same clone from its parts. If you decide to try `scalar clone --no-maintenance "file://$PWD/server/orbit.git" enlistment` yourself afterwards, clean up with `git -C enlistment/src fsmonitor--daemon stop` and `scalar delete enlistment`; `git help scalar` describes both commands. Do not omit `--no-maintenance`: the lab shell keeps the Scalar registration inside its own configuration file, but the scheduler entries would be written under your real home directory.

### Commands

```bash
git clone --filter=blob:none --sparse "file://$PWD/server/orbit.git" orbit-dev/src
cd orbit-dev/src
ls -A
git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
git status

git sparse-checkout set services/ranker libs/tokenizer
find . -path ./.git -prune -o -type f -print | sort
git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
git rev-list --objects --all --missing=print | grep -c '^?'

git config set commitGraph.changedPaths true
git config set fetch.showForcedUpdates false
git config set advice.fetchShowForcedUpdates false
git config set fetch.unpackLimit 1
git config set status.aheadBehind false
git config set log.excludeDecoration "refs/prefetch/*"
git config set index.version 4
git update-index --index-version 4
git update-index --show-index-version
git config set maintenance.auto false
git config set maintenance.strategy incremental

GIT_TRACE="$PWD/../maintenance.log" git maintenance run --quiet --task=prefetch --task=commit-graph
sed -n 's/.*trace: run_command: git //p' ../maintenance.log | grep -e '^fetch' -e '^commit-graph'
git for-each-ref --format='%(refname)' refs/prefetch
find .git/objects/info -type f | sed 's/[0-9a-f]\{40\}/ID/' | sort
```

### Expected output

<!-- snippet: ch24/lab-18-4-scalar-by-hand/01-clone -->
```text
$ git clone --filter=blob:none --sparse "file://$PWD/server/orbit.git" orbit-dev/src
Cloning into 'orbit-dev/src'...
$ cd orbit-dev/src
$ ls -A
.git
.gitignore
pyproject.toml
README.md
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
   3 blob
  96 commit
   5 tag
 284 tree
$ git status
On branch main
Your branch is up to date with 'origin/main'.

You are in a sparse checkout with 10% of tracked files present.

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ch24/lab-18-4-scalar-by-hand/02-cone -->
```text
$ git sparse-checkout set services/ranker libs/tokenizer
$ find . -path ./.git -prune -o -type f -print | sort
./.gitignore
./libs/tokenizer/tokenizer.py
./libs/tokenizer/vocab.txt
./pyproject.toml
./README.md
./services/ranker/config.yaml
./services/ranker/features.py
./services/ranker/model.py
./services/ranker/tests/test_model.py
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
   9 blob
  96 commit
   5 tag
 284 tree
$ git rev-list --objects --all --missing=print | grep -c '^?'
113
```
<!-- /snippet -->

<!-- snippet: ch24/lab-18-4-scalar-by-hand/03-settings -->
```text
# Settings from the list in "git help scalar", written by hand:
$ git config set commitGraph.changedPaths true
$ git config set fetch.showForcedUpdates false
$ git config set advice.fetchShowForcedUpdates false
$ git config set fetch.unpackLimit 1
$ git config set status.aheadBehind false
$ git config set log.excludeDecoration "refs/prefetch/*"
$ git config set index.version 4
$ git update-index --index-version 4
$ git update-index --show-index-version
4
# What "git maintenance register" would set in this repository:
$ git config set maintenance.auto false
$ git config set maintenance.strategy incremental
```
<!-- /snippet -->

<!-- snippet: ch24/lab-18-4-scalar-by-hand/04-maintenance -->
```text
# The hourly tasks of the incremental strategy, once, in the foreground:
$ GIT_TRACE="$PWD/../maintenance.log" git maintenance run --quiet --task=prefetch --task=commit-graph
$ sed -n 's/.*trace: run_command: git //p' ../maintenance.log | grep -e '^fetch' -e '^commit-graph'
fetch origin --prefetch --prune --no-tags --no-write-fetch-head --recurse-submodules=no --quiet
commit-graph write --split --reachable --no-progress
$ git for-each-ref --format='%(refname)' refs/prefetch
refs/prefetch/remotes/origin/feature/rerank-cache
refs/prefetch/remotes/origin/main
$ find .git/objects/info -type f | sed 's/[0-9a-f]\{40\}/ID/' | sort
.git/objects/info/commit-graphs/commit-graph-chain
.git/objects/info/commit-graphs/graph-ID.graph
```
<!-- /snippet -->

### What happened internally

The clone asked the server for `filter blob:none`, received commits, trees and tags, and because of `--sparse` checked out only the top level, which needed three blobs. Setting the cone needed six more. 113 objects are promised and absent.

The settings are a selection from the section "Recommended config values" of `git help scalar`, each with the manual's reason: changed-path filters for path-limited history, no forced-update check after fetch and no ahead/behind count in `git status` because both walk history, one pack per fetch because maintenance will merge them, index version 4 for a smaller index, and `refs/prefetch/*` hidden from decorations. `maintenance.auto=false` and the `incremental` strategy are what `git maintenance register` would set. Two things `scalar` does were deliberately left out: `core.fsmonitor=true` and the scheduler.

The `prefetch` task ran `git fetch` with a refspec that writes to `refs/prefetch/` and touches neither tags nor your remote-tracking branches. The `commit-graph` task wrote a first layer under `objects/info/commit-graphs/`, with changed-path filters because of the setting.

### Checkpoint

Predict how many requests `git log -p` for one file of the cone will send to the server after a backfill, and what the filter statistics will be for `services/ranker`.

```bash
git backfill --sparse
GIT_TRACE=1 git log -p --format=%s -- services/ranker/features.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'
```

<!-- snippet: ch24/lab-18-4-scalar-by-hand/05-checkpoint -->
```text
# Checkpoint: the history of the cone without one request per commit.
$ git backfill --sparse
$ GIT_TRACE=1 git log -p --format=%s -- services/ranker/features.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
0
$ GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":13,"definitely_not":81,"false_positive":0}
```
<!-- /snippet -->

No request: `git backfill --sparse` 🟢 had already downloaded every historical version of the files in the cone. And 81 of 94 commits were dismissed by their filter.

### Failure scenario

The server becomes unreachable, and you need one more directory.

```bash
mv ../../server ../../server-offline
git sparse-checkout add services/gateway
git sparse-checkout list
ls services
git status --short --branch
```

<!-- snippet: ch24/lab-18-4-scalar-by-hand/06-failure -->
```text
# Failure scenario: the server cannot be reached, and you need one more directory.
$ mv ../../server ../../server-offline
$ git sparse-checkout add services/gateway
fatal: '$LAB/ch24/lab-18-4-scalar-by-hand/server/orbit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch ba797a4dad301d287161e2a0ed5fef0c6dbb1882 from promisor remote
[exit status: 128]
$ git sparse-checkout list
libs/tokenizer
services/ranker
$ ls services
ranker
[exit status: 0]
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

Widening the cone needs the blobs of the new directory, they are promised and absent, and the promisor remote does not answer. The command failed as a whole: the cone is what it was, no file was written, and the working tree is clean. Everything inside what you hold keeps working, including commits:

```bash
git log --oneline -2 -- services/ranker
git blame -s -L 1,3 services/ranker/features.py
printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
git log --oneline -1
```

<!-- snippet: ch24/lab-18-4-scalar-by-hand/07-still-works -->
```text
# Everything inside what you already hold keeps working without the server:
$ git log --oneline -2 -- services/ranker
d8e029f ranker: add ranking signal 12
03a3d3e ranker: add ranking signal 11
$ git blame -s -L 1,3 services/ranker/features.py
8c2da00f 1) FEATURES = [
8c2da00f 2)     "bm25",
3c4ab9bd 3)     "signal_01",
$ printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
$ git log --oneline -1
bad3a4d ranker: return the top 20
```
<!-- /snippet -->

### Recovery

```bash
mv ../../server-offline ../../server
git sparse-checkout add services/gateway
git sparse-checkout list
ls services/gateway
```

<!-- snippet: ch24/lab-18-4-scalar-by-hand/08-recovery -->
```text
$ mv ../../server-offline ../../server
$ git sparse-checkout add services/gateway
$ git sparse-checkout list
libs/tokenizer
services/gateway
services/ranker
$ ls services/gateway
app.py
config.yaml
routes.py
tests
```
<!-- /snippet -->

Nothing had to be repaired, because the failed command had changed nothing. The recovery is the connection and the same command again. The prevention is to widen the cone and run `git backfill --sparse` while you still have the server.

### Verification

```bash
git status
git ls-files -t | cut -c1 | sort | uniq -c
git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
git fsck
git commit-graph verify
```

<!-- snippet: ch24/lab-18-4-scalar-by-hand/09-verification -->
```text
$ git status
On branch main
Your branch and 'origin/main' refer to different commits.
  (use "git status --ahead-behind" for details)

You are in a sparse checkout with 40% of tracked files present.

nothing to commit, working tree clean
$ git ls-files -t | cut -c1 | sort | uniq -c
  13 H
  20 S
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
  38 blob
  97 commit
   5 tag
 287 tree
$ git fsck
[exit status: 0]
$ git commit-graph verify
[exit status: 0]
```
<!-- /snippet -->

`git status` prints "refer to different commits" where it would normally count commits ahead: that is `status.aheadBehind=false` at work. Thirteen files are present, 38 blobs are local, and `git fsck` accepts a repository in which most blobs are missing.

### Questions

1. Which two mechanisms make this clone small, where is each one configured, and what does each one leave out?
2. After the clone, three blobs were local; after `git sparse-checkout set`, nine; after `git backfill --sparse`, 33. Explain each number.
3. What do `status.aheadBehind=false` and `fetch.showForcedUpdates=false` save, and what information do you give up?
4. What does the `prefetch` task change in the repository, and why does it not move `origin/main`?
5. `git sparse-checkout add services/gateway` failed while the server was offline. What state did it leave, and why is that the right behavior?
6. List what `scalar clone` would have added to this lab's result on your machine, outside the repository, and the command that removes each.

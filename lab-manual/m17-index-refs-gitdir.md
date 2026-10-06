# Module 17 labs: The index file, ref storage, and the `.git` directory

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the replay scripts in `labs/ch03/`. Read [Chapter 3](../textbook/ch03-git-internals.md) first; each lab names the sections it relies on.

## How to run these labs

Every lab starts from a repository that a setup script builds with a fixed clock, so the commits you start from have the IDs printed here. From the course root:

```bash
bash labs/ch03/setup-17-1-index.sh          # Lab 17.1
labs/shell m17-1
cd inference-service
```

Lab 17.2 uses `setup-17-2-case-clash.sh` and `labs/shell m17-2`; Lab 17.3 uses `setup-17-3-special-refs.sh`, `labs/shell m17-3` and `cd inference-service`. Commits that you create by hand get the real time and therefore other IDs; blob and tree IDs are the same as in the book.

Three notes:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from the replay script.
- `labs/shell` exports `COURSE_ROOT`, so the command `python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index` works as written. The reader script is sixty lines of Python that follow `git help gitformat-index`; read it once.

To see a lab exactly as printed, replay it: `labs/run ch03/lab-17-1-index-structure`, `labs/run ch03/lab-17-2-files-vs-reftable` or `labs/run ch03/lab-17-3-special-refs-tour`. Answers to the questions are in [solutions/m17-lab-answers.md](../solutions/m17-lab-answers.md). Write your own first.

## Lab 17.1: Read the index as a data structure

### Objective

Read `.git/index` as the manual describes it: header, entries with stat data and flags, stages and extensions. Watch `git add`, `git status` and a conflict change it, then destroy it and rebuild it without losing history.

### Prerequisites

Chapter 3, section 3.12; [Chapter 5](../textbook/ch05-index.md) for what staging means. `xxd` and `python3`, both present on macOS.

### Setup

```bash
bash labs/ch03/setup-17-1-index.sh
labs/shell m17-1
cd inference-service
```

You are on `main` with three tracked files. The branch `feature/timeouts` changes the same line of `config.toml` as `main` does, so a merge will conflict.

### Commands

The entries, the first twelve bytes, and the whole structure:

```bash
git ls-files --stage
head -c 12 .git/index | xxd
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
```

Add a file and watch the entry count and the `TREE` extension; commit and watch the extension come back:

```bash
printf 'def health():\n    return "ok"\n' > src/health.py
git add src/health.py
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
git cat-file -t 7dd51168
git commit --quiet -m "Add health handler"
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep extension
```

The cached stat data, compared with what the filesystem says (your numbers differ from the book):

```bash
git ls-files --debug
python3 "$COURSE_ROOT/labs/ch03/read-index.py" --stat .git/index | grep -A1 config.toml
stat -f 'ctime=%c mtime=%m dev=%d ino=%i uid=%u gid=%g size=%z' config.toml
```

The stat cache at work, then a conflict:

```bash
touch -t 202001010000 src/server.py
git diff-files
git status --short
git diff-files
git merge feature/timeouts
git ls-files --stage
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
git show :1:config.toml
git show :3:config.toml
```

### Expected output

<!-- snippet: ch03/lab-17-1-index-structure/01-entries -->
```text
$ git ls-files --stage
100644 406053bfa3b0d2c429b4ec17cab826e7c510f0a1 0	config.toml
100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc 0	run.sh
100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 0	src/server.py
$ head -c 12 .git/index | xxd
00000000: 4449 5243 0000 0002 0000 0003            DIRC........
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
header     signature=DIRC version=2 entries=3
entry      100644 406053bfa3b0d2c429b4ec17cab826e7c510f0a1 stage=0 size=31    config.toml
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh
entry      100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 stage=0 size=40    src/server.py
extension  TREE (53 bytes)
checksum   valid
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-1-index-structure/02-add -->
```text
$ printf 'def health():\n    return "ok"\n' > src/health.py
$ git add src/health.py
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
header     signature=DIRC version=2 entries=4
entry      100644 406053bfa3b0d2c429b4ec17cab826e7c510f0a1 stage=0 size=31    config.toml
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh
entry      100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 stage=0 size=30    src/health.py
entry      100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 stage=0 size=40    src/server.py
extension  TREE (15 bytes)
checksum   valid
# The entry points at a blob that "git add" has already written:
$ git cat-file -t 7dd51168
blob
$ git commit --quiet -m "Add health handler"
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep extension
extension  TREE (53 bytes)
```
<!-- /snippet -->

The stat numbers come from your filesystem and differ on every machine, so this part is not compared by `labs/verify-all.sh`:

<!-- snippet: ch03/lab-17-1-index-stat-volatile/01-debug -->
```text
$ git ls-files --debug
config.toml
  ctime: 1790892138:519231142
  mtime: 1790892138:519231142
  dev: 16777231	ino: 67019222
  uid: 501	gid: 0
  size: 31	flags: 0
run.sh
  ctime: 1790892138:439193386
  mtime: 1790892138:436754219
  dev: 16777231	ino: 67019155
  uid: 501	gid: 0
  size: 42	flags: 0
src/server.py
  ctime: 1790892138:439658761
  mtime: 1790892138:439658761
  dev: 16777231	ino: 67019156
  uid: 501	gid: 0
  size: 40	flags: 0
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-1-index-stat-volatile/02-compare -->
```text
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" --stat .git/index | grep -A1 config.toml
entry      100644 406053bfa3b0d2c429b4ec17cab826e7c510f0a1 stage=0 size=31    config.toml
           ctime=1790892138.519231142 mtime=1790892138.519231142 dev=16777231 ino=67019222 uid=501 gid=0
$ stat -f 'ctime=%c mtime=%m dev=%d ino=%i uid=%u gid=%g size=%z' config.toml
ctime=1790892138 mtime=1790892138 dev=16777231 ino=67019222 uid=501 gid=0 size=31
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-1-index-structure/03-stat-cache -->
```text
$ touch -t 202001010000 src/server.py
$ git diff-files
:100644 100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 0000000000000000000000000000000000000000 M	src/server.py
$ git status --short
$ git diff-files
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-1-index-structure/04-stages -->
```text
$ git merge feature/timeouts
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git ls-files --stage
100644 3635c8470ebd3d3e70fb74c4705d011de687e7f9 1	config.toml
100644 406053bfa3b0d2c429b4ec17cab826e7c510f0a1 2	config.toml
100644 34506a9f404ff3496c2a0fc37293305f6c5acae4 3	config.toml
100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc 0	run.sh
100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 0	src/health.py
100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 0	src/server.py
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
header     signature=DIRC version=2 entries=6
entry      100644 3635c8470ebd3d3e70fb74c4705d011de687e7f9 stage=1 size=0     config.toml
entry      100644 406053bfa3b0d2c429b4ec17cab826e7c510f0a1 stage=2 size=0     config.toml
entry      100644 34506a9f404ff3496c2a0fc37293305f6c5acae4 stage=3 size=0     config.toml
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh
entry      100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 stage=0 size=30    src/health.py
entry      100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 stage=0 size=40    src/server.py
extension  TREE (34 bytes)
checksum   valid
$ git show :1:config.toml
retry_limit = 3
timeout_s = 30
$ git show :3:config.toml
retry_limit = 3
timeout_s = 60
```
<!-- /snippet -->

### What happened internally

The header is `DIRC`, version 2, three entries; each entry carries the mode, the blob ID, stage 0, the file size and the rest of the stat data, and the `TREE` extension (53 bytes) caches the two tree IDs, top level and `src`, that the entries already correspond to. `git add src/health.py` wrote the blob `7dd51168` to the object database and a fourth entry, and shrank `TREE` to 15 bytes: the nodes for `src` and the top level were invalidated, because the index no longer matches those trees. The commit computed new trees and the extension grew back. `touch` changed only the modification time of `src/server.py`; `git diff-files` compares cached stat data with the filesystem and reported a possible change with an all-zero ID, `git status` hashed the file, found the blob the entry already named, and wrote the fresh stat data back. The merge stopped on `config.toml` and left three entries for it: stage 1 is the common ancestor, stage 2 the version of `main`, stage 3 the version of `feature/timeouts`. Their size field is 0, because a stage entry describes a blob and no file in the working tree.

### Checkpoint

Resolve by taking the feature's version, and watch the three stages collapse into one entry and move into the resolve-undo extension:

```bash
printf 'retry_limit = 3\ntimeout_s = 60\n' > config.toml
git add config.toml
git ls-files --stage config.toml
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e extension -e checksum
git commit --quiet -m "Merge feature/timeouts"
```

<!-- snippet: ch03/lab-17-1-index-structure/05-resolve -->
```text
$ printf 'retry_limit = 3\ntimeout_s = 60\n' > config.toml
$ git add config.toml
$ git ls-files --stage config.toml
100644 34506a9f404ff3496c2a0fc37293305f6c5acae4 0	config.toml
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e extension -e checksum
extension  TREE (34 bytes)
extension  REUC (93 bytes)
checksum   valid
$ git commit --quiet -m "Merge feature/timeouts"
```
<!-- /snippet -->

The stage 0 entry names `34506a9f`, the blob that stage 3 had: taking "their" version wrote no new blob. `REUC` holds the three stage IDs so that `git checkout -m config.toml` could recreate the conflict.

### Failure scenario

Stage one new file, leave one edit unstaged, and then damage the index as a crash during a write would:

```bash
printf 'log_level = "info"\n' > logging.toml
git add logging.toml
printf 'retry_limit = 5\ntimeout_s = 60\n' > config.toml
git status --short
printf 'JUNK' | dd of=.git/index conv=notrunc 2>/dev/null
head -c 12 .git/index | xxd
git status
git log --oneline -1
```

<!-- snippet: ch03/lab-17-1-index-structure/06-failure -->
```text
# Failure scenario. Stage one new file, leave one edit unstaged, then damage the index.
$ printf 'log_level = "info"\n' > logging.toml
$ git add logging.toml
$ printf 'retry_limit = 5\ntimeout_s = 60\n' > config.toml
$ git status --short
 M config.toml
A  logging.toml
$ printf 'JUNK' | dd of=.git/index conv=notrunc 2>/dev/null
$ head -c 12 .git/index | xxd
00000000: 4a55 4e4b 0000 0002 0000 0005            JUNK........
$ git status
error: bad signature 0x4b4e554a
fatal: index file corrupt
[exit status: 128]
# History does not live in the index. It is unharmed:
$ git log --oneline -1
1116b17 Merge feature/timeouts
```
<!-- /snippet -->

Every command that reads the index now refuses. The history is unharmed, because no part of it lives in the index.

### Recovery

Throw the damaged file away and rebuild the index from `HEAD`. `git reset` 🟡 without arguments rewrites the index to match the commit and leaves every working tree file alone:

```bash
rm .git/index
git reset
git status --short
git fsck
git cat-file -p e8b40360
git ls-tree 28956793
git cat-file -p 28956793:config.toml
```

<!-- snippet: ch03/lab-17-1-index-structure/07-recovery -->
```text
# Throw the damaged index away and rebuild it from HEAD. The working tree is not touched.
$ rm .git/index
$ git reset
Unstaged changes after reset:
M	config.toml
$ git status --short
 M config.toml
?? logging.toml
# What was lost is the staging of logging.toml. Its blob is still in the object database:
$ git fsck
dangling tree 28956793140e969ea1b15117d01640a395d6a124
dangling blob e8b40360b00dca73037256f4da6ca1a53b72639c
$ git cat-file -p e8b40360
log_level = "info"
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-1-index-structure/08-dangling-tree -->
```text
# The dangling tree is a leftover of the conflicted merge in step 4:
$ git ls-tree 28956793
100644 blob c316b11742c99d8b1f1dc4de34cabb273a6a5466	config.toml
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc	run.sh
040000 tree 3673884392168af748f6380a22c74529a786f72a	src
$ git cat-file -p 28956793:config.toml
retry_limit = 3
<<<<<<< HEAD
timeout_s = 45
=======
timeout_s = 60
>>>>>>> feature/timeouts
```
<!-- /snippet -->

What was lost is the staging of `logging.toml`, now untracked again; its blob `e8b40360` is still in the object database, which `git fsck` shows as dangling. The unstaged edit to `config.toml` survived, because `git reset` does not touch the working tree. The dangling tree is a leftover of the conflicted merge: the `ort` strategy records the tree it wrote to the working tree, conflict markers included, under `AUTO_MERGE`; the commit removed that name, and the tree stayed behind as an unreachable object.

### Verification

```bash
git add logging.toml
git status --short
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e checksum
```

<!-- snippet: ch03/lab-17-1-index-structure/09-verification -->
```text
$ git add logging.toml
$ git status --short
 M config.toml
A  logging.toml
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e checksum
header     signature=DIRC version=2 entries=5
checksum   valid
```
<!-- /snippet -->

### Questions

1. The `TREE` extension shrank from 53 to 15 bytes after `git add src/health.py` and grew back after the commit. What does it cache, and why did adding a file invalidate it?
2. The three stage entries show `size=0`. Why do conflict entries carry no stat data, and which stage does `git add config.toml` write?
3. `touch` made `git diff-files` report `src/server.py`, and one `git status` silenced it. What did each command compare, and what did `git status` write?
4. After the corruption, `git log` worked and `git status` failed. Which information exists only in the index, and what exactly was lost after `rm .git/index && git reset` here?
5. `git fsck` listed a dangling tree whose `config.toml` contains conflict markers. Which operation wrote that tree, why is it in the object database, and what will happen to it?
6. Why was it safe to run `git reset` with an edited `config.toml` in the working tree, and which form of `git reset` would have destroyed that edit?

## Lab 17.2: The `files` backend versus reftable

### Objective

Compare one repository in the `files` format with its byte-for-byte copy migrated to reftable, through the filesystem and through plumbing. Then reproduce a failure that the `files` format cannot avoid on a Mac, two branches whose names differ only in case, diagnose it from the ref storage, and fix it with a migration.

### Prerequisites

Chapter 3, sections 3.9 and 3.13. The failure scenario needs a case-insensitive filesystem, which is the default on macOS: `git -C laptop config get core.ignorecase` prints `true` after the setup.

### Setup

```bash
bash labs/ch03/setup-17-2-case-clash.sh
labs/shell m17-2
```

The setup builds three repositories in the sandbox: `server.git`, a bare repository with the branches `main`, `Hotfix` and `hotfix`; `teammate`, the clone that pushed them (a colleague on Linux, where the two names never collide); and `laptop`, your clone in the default `files` format, made when each branch had one commit. The teammate has since added a commit to each of the two branches and pushed. `server.git` and `teammate` use reftable, which is what lets a Mac hold both names at all.

### Commands

Part A, in the sandbox directory. Build a small repository, copy it, migrate the copy, and compare:

```bash
git init --quiet files-repo
cd files-repo
printf 'retry_limit = 3\n' > config.toml
git add config.toml
git commit --quiet -m "Add service configuration"
git branch feature/batching
git tag -a v1.0.0 -m "Release 1.0.0"
cd ..
cp -R files-repo reftable-repo
git -C reftable-repo refs migrate --ref-format=reftable
ls -A files-repo/.git
ls -A reftable-repo/.git
cat files-repo/.git/HEAD
cat reftable-repo/.git/HEAD
cat reftable-repo/.git/refs/heads
ls reftable-repo/.git/reftable | sed -E 's/-[0-9a-f]{8}\./-<random>./'
diff files-repo/.git/config reftable-repo/.git/config
```

Then the same questions through plumbing:

```bash
git -C files-repo for-each-ref
git -C reftable-repo for-each-ref
git -C files-repo symbolic-ref HEAD
git -C reftable-repo symbolic-ref HEAD
git -C reftable-repo reflog show main
git -C files-repo rev-parse --show-ref-format
git -C reftable-repo rev-parse --show-ref-format
```

### Expected output

<!-- snippet: ch03/lab-17-2-files-vs-reftable/01-build -->
```text
$ git init --quiet files-repo
$ cd files-repo
$ printf 'retry_limit = 3\n' > config.toml
$ git add config.toml
$ git commit --quiet -m "Add service configuration"
$ git branch feature/batching
$ git tag -a v1.0.0 -m "Release 1.0.0"
$ cd ..
# A byte-for-byte copy, then a migration of the copy to the other ref format:
$ cp -R files-repo reftable-repo
$ git -C reftable-repo refs migrate --ref-format=reftable
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-2-files-vs-reftable/02-on-disk -->
```text
$ ls -A files-repo/.git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
objects
refs
$ ls -A reftable-repo/.git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
objects
refs
reftable
$ cat files-repo/.git/HEAD
ref: refs/heads/main
$ cat reftable-repo/.git/HEAD
ref: refs/heads/.invalid
$ cat reftable-repo/.git/refs/heads
this repository uses the reftable format
$ ls reftable-repo/.git/reftable | sed -E 's/-[0-9a-f]{8}\./-<random>./'
0x000000000001-0x000000000003-<random>.ref
tables.list
$ diff files-repo/.git/config reftable-repo/.git/config
2c2
< 	repositoryformatversion = 0
---
> 	repositoryformatversion = 1
7a8,9
> [extensions]
> 	refstorage = reftable
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-2-files-vs-reftable/03-plumbing -->
```text
# Ask Git instead of the filesystem, and the two repositories give the same answers:
$ git -C files-repo for-each-ref
c2b21cba9323b02eb5f48fb94b95c5fc58519c16 commit	refs/heads/feature/batching
c2b21cba9323b02eb5f48fb94b95c5fc58519c16 commit	refs/heads/main
2d188081f73eaeaeea778324d89466d19b5d8e0a tag	refs/tags/v1.0.0
$ git -C reftable-repo for-each-ref
c2b21cba9323b02eb5f48fb94b95c5fc58519c16 commit	refs/heads/feature/batching
c2b21cba9323b02eb5f48fb94b95c5fc58519c16 commit	refs/heads/main
2d188081f73eaeaeea778324d89466d19b5d8e0a tag	refs/tags/v1.0.0
$ git -C files-repo symbolic-ref HEAD
refs/heads/main
$ git -C reftable-repo symbolic-ref HEAD
refs/heads/main
$ git -C reftable-repo reflog show main
c2b21cb main@{0}: commit (initial): Add service configuration
$ git -C files-repo rev-parse --show-ref-format
files
$ git -C reftable-repo rev-parse --show-ref-format
reftable
```
<!-- /snippet -->

### What happened internally

`git refs migrate` 🟡 read every ref and every reflog entry through the `files` backend and wrote them into one reftable table, then removed `refs/heads`, `refs/tags` and `logs/`, replaced `HEAD` by the stub `ref: refs/heads/.invalid`, created the stub file `refs/heads`, and set `extensions.refstorage = reftable` with `core.repositoryformatversion = 1`. Objects were not touched: the two repositories share every blob, tree, commit and tag ID. The table's name (`0x000000000001-0x000000000003-<random>.ref`) says that it covers update numbers 1 to 3; the random suffix is masked in the transcript. Plumbing gives identical answers for the two repositories because it asks the ref backend, not the filesystem.

### Checkpoint

The habit this lab is about. A script that reads ref files works in one of the two repositories; the plumbing works in both:

```bash
cat files-repo/.git/refs/heads/main
cat reftable-repo/.git/refs/heads/main
git -C reftable-repo update-ref -m "start experiment" refs/heads/experiment main
git -C reftable-repo branch --list
```

<!-- snippet: ch03/lab-17-2-files-vs-reftable/04-by-hand -->
```text
# A script that reads ref files by hand works in one repository only:
$ cat files-repo/.git/refs/heads/main
c2b21cba9323b02eb5f48fb94b95c5fc58519c16
[exit status: 0]
$ cat reftable-repo/.git/refs/heads/main
cat: reftable-repo/.git/refs/heads/main: Not a directory
[exit status: 1]
# Writes go through the same commands in both:
$ git -C reftable-repo update-ref -m "start experiment" refs/heads/experiment main
$ git -C reftable-repo branch --list
  experiment
  feature/batching
* main
```
<!-- /snippet -->

### Failure scenario

Part B. Your clone fetches the teammate's two new commits:

```bash
cd laptop
git rev-parse --show-ref-format
git branch --remotes
git fetch origin
```

<!-- snippet: ch03/lab-17-2-files-vs-reftable/05-failure -->
```text
# Failure scenario. The server has branches Hotfix and hotfix; your clone uses the files format.
$ cd laptop
$ git rev-parse --show-ref-format
files
$ git branch --remotes
  origin/HEAD -> origin/main
  origin/Hotfix
  origin/hotfix
  origin/main
$ git fetch origin
error: You're on a case-insensitive filesystem, and the remote you are
trying to fetch from has references that only differ in casing. It
is impossible to store such references with the 'files' backend. You
can either accept this as-is, in which case you won't be able to
store all remote references on disk. Or you can alternatively
migrate your repository to use the 'reftable' backend with the
following command:

    git refs migrate --ref-format=reftable

Please keep in mind that not all implementations of Git support this
new format yet. So if you use tools other than Git to access this
repository it may not be an option to migrate to reftables.

From $LAB/ch03/lab-17-2-files-vs-reftable/server
   2cd9286..b97d03d  Hotfix     -> origin/Hotfix
 ! 6bf35b1..23223f8  hotfix     -> origin/hotfix  (unable to update local ref)
[exit status: 1]
```
<!-- /snippet -->

Git names the cause in its message. Now diagnose from the storage, and watch the clone give two different answers for one ref:

```bash
git ls-remote origin "refs/heads/[Hh]otfix"
git rev-parse origin/Hotfix origin/hotfix
git for-each-ref "refs/remotes/origin/[Hh]otfix"
find .git/refs/remotes -type f | sort
grep -i hotfix .git/packed-refs
git fetch origin
```

<!-- snippet: ch03/lab-17-2-files-vs-reftable/06-diagnosis -->
```text
# What the server has:
$ git ls-remote origin "refs/heads/[Hh]otfix"
b97d03d2179e3618e58b928988691f3fb303fa4e	refs/heads/Hotfix
23223f825010835de9d522e0c99ccf98b471cbcb	refs/heads/hotfix
# Ask this clone for each ref by name, and both names give the new value of Hotfix:
$ git rev-parse origin/Hotfix origin/hotfix
b97d03d2179e3618e58b928988691f3fb303fa4e
b97d03d2179e3618e58b928988691f3fb303fa4e
# List the refs instead, and hotfix still has its value from before the fetch:
$ git for-each-ref "refs/remotes/origin/[Hh]otfix"
b97d03d2179e3618e58b928988691f3fb303fa4e commit	refs/remotes/origin/Hotfix
6bf35b11575d7e82d5b52a6dd1c77a1d4fdf4028 commit	refs/remotes/origin/hotfix
# One loose file answers to both names. The listing takes the name hotfix from packed-refs:
$ find .git/refs/remotes -type f | sort
.git/refs/remotes/origin/HEAD
.git/refs/remotes/origin/Hotfix
$ grep -i hotfix .git/packed-refs
2cd9286461e269f39107bd3208452c83d9f0a38a refs/remotes/origin/Hotfix
6bf35b11575d7e82d5b52a6dd1c77a1d4fdf4028 refs/remotes/origin/hotfix
# Every further fetch fails on that contradiction:
$ git fetch origin
error: cannot lock ref 'refs/remotes/origin/hotfix': is at b97d03d2179e3618e58b928988691f3fb303fa4e but expected 6bf35b11575d7e82d5b52a6dd1c77a1d4fdf4028
From $LAB/ch03/lab-17-2-files-vs-reftable/server
 ! 6bf35b1..23223f8  hotfix     -> origin/hotfix  (unable to update local ref)
[exit status: 1]
```
<!-- /snippet -->

The clone was created with both remote-tracking branches in `packed-refs`, where names are only text and never collide. The fetch wrote the new value of `Hotfix` as a loose file `refs/remotes/origin/Hotfix`, and then tried to write `refs/remotes/origin/hotfix`: on a case-insensitive filesystem that is the same file. A lookup by name opens the file and gets the value of `Hotfix` for both names. A listing reads the directory, which yields `Hotfix`, and `packed-refs`, which supplies `hotfix` with its old value. The second fetch compares the lookup (`b97d03d`) with the listed value (`6bf35b1`), sees a contradiction, and refuses to lock the ref.

### Recovery

Migrate this clone to a format that does not use one file per ref, and fetch again:

```bash
git refs migrate --ref-format=reftable
git fetch origin
git for-each-ref refs/remotes/origin
```

<!-- snippet: ch03/lab-17-2-files-vs-reftable/07-recovery -->
```text
# Recovery in this clone: a ref format that does not use one file per ref.
$ git refs migrate --ref-format=reftable
$ git fetch origin
From $LAB/ch03/lab-17-2-files-vs-reftable/server
   6bf35b1..23223f8  hotfix     -> origin/hotfix
[exit status: 0]
$ git for-each-ref refs/remotes/origin
e644f959123510ac3615c57500dd6146be830270 commit	refs/remotes/origin/HEAD
b97d03d2179e3618e58b928988691f3fb303fa4e commit	refs/remotes/origin/Hotfix
23223f825010835de9d522e0c99ccf98b471cbcb commit	refs/remotes/origin/hotfix
e644f959123510ac3615c57500dd6146be830270 commit	refs/remotes/origin/main
```
<!-- /snippet -->

The migration took `hotfix` with the value the listing had, `6bf35b1`, which is why the fetch reports `6bf35b1..23223f8`. Both remote-tracking branches now hold the values the server has. The alternative fix is on the server: rename one of the two branches, which is the only fix that helps every `files`-format clone on every Mac and Windows machine of the team.

### Verification

```bash
git ls-remote origin "refs/heads/*"
git rev-parse --show-ref-format
git fetch origin
```

<!-- snippet: ch03/lab-17-2-files-vs-reftable/08-verification -->
```text
$ git ls-remote origin "refs/heads/*"
b97d03d2179e3618e58b928988691f3fb303fa4e	refs/heads/Hotfix
23223f825010835de9d522e0c99ccf98b471cbcb	refs/heads/hotfix
e644f959123510ac3615c57500dd6146be830270	refs/heads/main
$ git rev-parse --show-ref-format
reftable
$ git fetch origin
[exit status: 0]
```
<!-- /snippet -->

### Questions

1. After the migration `.git/HEAD` contains `ref: refs/heads/.invalid`, while `git symbolic-ref HEAD` prints `refs/heads/main`. Why does the repository keep a file with a wrong-looking content?
2. List what the migration removed from `.git`, what it added, and what stayed identical. Which of these would differ if the repository had a stash entry?
3. The first fetch updated `Hotfix` and failed on `hotfix`. Then `git rev-parse` gave the same ID for both names, and `git for-each-ref` gave different ones. Which storage location answered each of the three questions?
4. The second fetch failed with `is at b97d03d... but expected 6bf35b1...`. Where did each of the two IDs come from?
5. After the migration, the fetch printed `6bf35b1..23223f8 hotfix -> origin/hotfix`. Why was the starting value `6bf35b1` and not `b97d03d`?
6. The server and the teammate use reftable, the laptop used `files`, and they exchanged objects without any trouble. What does that tell you about where the ref format matters? Name the fix on the server side and say why it is the better one for a team.

## Lab 17.3: A tour of every special ref and file

### Objective

Start a fetch, a reset, a merge, a cherry-pick, a revert, a rebase, a bisect and a stash, inspect the files and refs each one leaves under `.git`, abort each one, and end where you began. Then repair a merge whose `MERGE_HEAD` was deleted by hand.

### Prerequisites

Chapter 3, sections 3.9 to 3.11. The operations themselves are the subject of Chapters 8 to 11; here you only start and abort them.

### Setup

```bash
bash labs/ch03/setup-17-3-special-refs.sh
labs/shell m17-3
cd inference-service
```

`main` is two commits ahead of `origin/main`, and `feature/timeouts` changes the same line of `config.toml` as `main`, so every integration attempt stops with a conflict.

### Commands

Baseline, then one operation at a time. After each `ls -A .git`, name the new files before you read on.

```bash
git log --graph --oneline --all
ls -A .git
git fetch origin
cat .git/FETCH_HEAD
git reset --soft HEAD~1
cat .git/ORIG_HEAD
git reset --soft ORIG_HEAD
git log --oneline -1
git merge feature/timeouts
ls -A .git
cat .git/MERGE_HEAD
cat .git/MERGE_MSG
git cat-file -t AUTO_MERGE
git for-each-ref --include-root-refs
git rev-parse MERGE_HEAD FETCH_HEAD
git update-ref MERGE_HEAD HEAD
git update-ref FETCH_HEAD HEAD
git merge --abort
ls -A .git
git cherry-pick feature/timeouts
ls -A .git
cat .git/CHERRY_PICK_HEAD
git cherry-pick --abort
git revert --no-commit HEAD~1
ls -A .git
cat .git/REVERT_HEAD
git revert --abort
git switch --quiet feature/timeouts
git rebase main
ls -A .git
cat .git/REBASE_HEAD
cat .git/HEAD
cat .git/rebase-merge/head-name
cat .git/rebase-merge/onto
git rebase --abort
git switch --quiet main
git bisect start HEAD HEAD~2
ls -A .git
git for-each-ref refs/bisect
git bisect reset
printf 'retry_limit = 4\ntimeout_s = 45\n' > config.toml
git stash push --quiet -m "try four retries"
git for-each-ref refs/stash
cat .git/logs/refs/stash
git stash pop --quiet
git restore config.toml
```

### Expected output

<!-- snippet: ch03/lab-17-3-special-refs-tour/01-baseline -->
```text
$ git log --graph --oneline --all
* 740729a Add logging configuration
* 98932fb Raise timeout to 45 seconds
| * 0cab12e Double the timeout
|/  
* ed95c38 Add service configuration
$ ls -A .git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
objects
refs
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/02-fetch-and-reset -->
```text
$ git fetch origin
$ cat .git/FETCH_HEAD
ed95c389d59e4eb36fc24a0bf54973ff5eab05b4		branch 'main' of ../server
# A command that moves HEAD "in a drastic way" saves the old position first:
$ git reset --soft HEAD~1
$ cat .git/ORIG_HEAD
740729a560918e0aa319995c3593b861891232bb
$ git reset --soft ORIG_HEAD
$ git log --oneline -1
740729a Add logging configuration
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/03-merge -->
```text
$ git merge feature/timeouts
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ ls -A .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
ORIG_HEAD
refs
$ cat .git/MERGE_HEAD
0cab12efae273ef530412d8a4be1e79e5b73a2ba
$ cat .git/MERGE_MSG
Merge branch 'feature/timeouts'

# Conflicts:
#	config.toml
$ git cat-file -t AUTO_MERGE
tree
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/04-root-refs -->
```text
# Root refs are listed. The two pseudorefs, FETCH_HEAD and MERGE_HEAD, are not:
$ git for-each-ref --include-root-refs
e998f4a6456530454a3965aa39ae3817c10a9abd tree	AUTO_MERGE
740729a560918e0aa319995c3593b861891232bb commit	HEAD
740729a560918e0aa319995c3593b861891232bb commit	ORIG_HEAD
0cab12efae273ef530412d8a4be1e79e5b73a2ba commit	refs/heads/feature/timeouts
740729a560918e0aa319995c3593b861891232bb commit	refs/heads/main
ed95c389d59e4eb36fc24a0bf54973ff5eab05b4 commit	refs/remotes/origin/HEAD
ed95c389d59e4eb36fc24a0bf54973ff5eab05b4 commit	refs/remotes/origin/main
# Pseudorefs can be read like refs, but update-ref refuses to write them:
$ git rev-parse MERGE_HEAD FETCH_HEAD
0cab12efae273ef530412d8a4be1e79e5b73a2ba
ed95c389d59e4eb36fc24a0bf54973ff5eab05b4
$ git update-ref MERGE_HEAD HEAD
fatal: update_ref failed for ref 'MERGE_HEAD': refusing to update pseudoref 'MERGE_HEAD'
[exit status: 128]
$ git update-ref FETCH_HEAD HEAD
fatal: update_ref failed for ref 'FETCH_HEAD': refusing to update pseudoref 'FETCH_HEAD'
[exit status: 128]
$ git merge --abort
$ ls -A .git
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
objects
ORIG_HEAD
refs
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/05-cherry-pick -->
```text
$ git cherry-pick feature/timeouts
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
error: could not apply 0cab12e... Double the timeout
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ ls -A .git
AUTO_MERGE
CHERRY_PICK_HEAD
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
MERGE_MSG
objects
ORIG_HEAD
refs
$ cat .git/CHERRY_PICK_HEAD
0cab12efae273ef530412d8a4be1e79e5b73a2ba
$ git cherry-pick --abort
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/06-revert -->
```text
$ git revert --no-commit HEAD~1
$ ls -A .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
MERGE_MSG
objects
ORIG_HEAD
refs
REVERT_HEAD
$ cat .git/REVERT_HEAD
98932fbf33570ff0646bd86bc3bccf01e7643938
$ git revert --abort
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/07-rebase -->
```text
$ git switch --quiet feature/timeouts
$ git rebase main
Rebasing (1/1)
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
error: could not apply 0cab12e... Double the timeout
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 0cab12e... # Double the timeout
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/08-rebase-state -->
```text
$ ls -A .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
MERGE_MSG
objects
ORIG_HEAD
REBASE_HEAD
rebase-merge
refs
$ cat .git/REBASE_HEAD
0cab12efae273ef530412d8a4be1e79e5b73a2ba
# During a rebase HEAD is detached. The branch being rebased is remembered in the state directory:
$ cat .git/HEAD
740729a560918e0aa319995c3593b861891232bb
$ cat .git/rebase-merge/head-name
refs/heads/feature/timeouts
$ cat .git/rebase-merge/onto
740729a560918e0aa319995c3593b861891232bb
$ git rebase --abort
$ git switch --quiet main
```
<!-- /snippet -->

<!-- snippet: ch03/lab-17-3-special-refs-tour/09-bisect-and-stash -->
```text
$ git bisect start HEAD HEAD~2
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[98932fbf33570ff0646bd86bc3bccf01e7643938] Raise timeout to 45 seconds
$ ls -A .git
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
objects
ORIG_HEAD
refs
$ git for-each-ref refs/bisect
740729a560918e0aa319995c3593b861891232bb commit	refs/bisect/bad
ed95c389d59e4eb36fc24a0bf54973ff5eab05b4 commit	refs/bisect/good-ed95c389d59e4eb36fc24a0bf54973ff5eab05b4
$ git bisect reset
Previous HEAD position was 98932fb Raise timeout to 45 seconds
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)
$ printf 'retry_limit = 4\ntimeout_s = 45\n' > config.toml
$ git stash push --quiet -m "try four retries"
$ git for-each-ref refs/stash
1afc44e76a9af9491ca8c030b2305cc27a843310 commit	refs/stash
$ cat .git/logs/refs/stash
0000000000000000000000000000000000000000 1afc44e76a9af9491ca8c030b2305cc27a843310 Lab User <you@example.com> 1788758580 +0530	On main: try four retries
$ git stash pop --quiet
$ git restore config.toml
```
<!-- /snippet -->

### What happened internally

| Operation | Left under `.git` | Removed by |
|---|---|---|
| `git fetch` | `FETCH_HEAD`: the fetched ref with its source | the next fetch overwrites it |
| `git reset --soft HEAD~1` | `ORIG_HEAD`: where `HEAD` was | the next command that moves `HEAD` drastically overwrites it |
| a merge that stops | `MERGE_HEAD` (the commit being merged), `MERGE_MODE`, `MERGE_MSG`, `AUTO_MERGE` (the tree written to the working tree, markers included) | `git merge --abort`, or the commit that concludes the merge |
| a cherry-pick that stops | `CHERRY_PICK_HEAD`, `MERGE_MSG`, `AUTO_MERGE` | `--abort`, `--skip`, or the commit |
| `git revert --no-commit` | `REVERT_HEAD`, `MERGE_MSG`, `AUTO_MERGE` | `--abort` or the commit |
| a rebase that stops | `REBASE_HEAD`, the directory `rebase-merge/` with `head-name`, `onto` and the todo list; `HEAD` detached | `--abort`, or the end of the rebase |
| `git bisect start` | `BISECT_START`, `BISECT_LOG`, `BISECT_TERMS`, `BISECT_NAMES`, `BISECT_EXPECTED_REV`, `BISECT_ANCESTORS_OK`; the refs `refs/bisect/bad` and `refs/bisect/good-<id>`; `HEAD` detached at the commit under test | `git bisect reset` |
| `git stash push` | `refs/stash` and its reflog, which is the stash list; `ORIG_HEAD` | `git stash pop` removes the entry; an empty reflog and ref disappear |

Two of the names are pseudorefs: `FETCH_HEAD` and `MERGE_HEAD` can hold several lines and `git update-ref` refuses them. `ORIG_HEAD`, `AUTO_MERGE` and `HEAD` are root refs and appear in `git for-each-ref --include-root-refs`. During the rebase `HEAD` is detached, because the rebase replays commits onto `onto` without moving the branch until it is done; `rebase-merge/head-name` is how `--abort` and the final step know which branch to move.

### Checkpoint

No operation is in progress. Three leftovers remain:

```bash
git status --short --branch
git stash list
ls -A .git
```

<!-- snippet: ch03/lab-17-3-special-refs-tour/10-checkpoint -->
```text
# No operation is in progress. Three leftovers remain: FETCH_HEAD, ORIG_HEAD, and AUTO_MERGE,
# the tree that "git stash pop" merged. None of them describes unfinished work.
$ git status --short --branch
## main...origin/main [ahead 2]
$ git stash list
$ ls -A .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
objects
ORIG_HEAD
refs
```
<!-- /snippet -->

`FETCH_HEAD` and `ORIG_HEAD` are expected. `AUTO_MERGE` is the tree that `git stash pop` merged into the working tree; on Git 2.55 a clean stash pop leaves it behind, and the next commit removes it. None of the three describes unfinished work, and none protects an object from garbage collection.

### Failure scenario

A merge is resolved, and then someone "cleans up" `.git` by hand:

```bash
git merge feature/timeouts > /dev/null
printf 'retry_limit = 3\ntimeout_s = 60\n' > config.toml
git add config.toml
git status | grep merg
rm .git/MERGE_HEAD
git status | grep merg
git merge --continue
git commit --quiet -m "Merge branch 'feature/timeouts'"
git log --graph --oneline --all
git branch --no-merged main
```

<!-- snippet: ch03/lab-17-3-special-refs-tour/11-failure -->
```text
# Failure scenario: a merge is resolved, and then MERGE_HEAD is deleted by hand.
$ git merge feature/timeouts > /dev/null
$ printf 'retry_limit = 3\ntimeout_s = 60\n' > config.toml
$ git add config.toml
$ git status | grep merg
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)
$ rm .git/MERGE_HEAD
# Git no longer knows that a merge is in progress. The same question now finds nothing:
$ git status | grep merg
$ git merge --continue
fatal: There is no merge in progress (MERGE_HEAD missing).
[exit status: 128]
$ git commit --quiet -m "Merge branch 'feature/timeouts'"
$ git log --graph --oneline --all
* 3764eae Merge branch 'feature/timeouts'
* 740729a Add logging configuration
* 98932fb Raise timeout to 45 seconds
| * 0cab12e Double the timeout
|/  
* ed95c38 Add service configuration
$ git branch --no-merged main
  feature/timeouts
```
<!-- /snippet -->

Without `MERGE_HEAD`, Git has no record that a merge was in progress. `git commit` made an ordinary commit: the right tree, because the index held the resolved content, and one parent, because `MERGE_HEAD` was the only place that named the second one. `feature/timeouts` is therefore still "not merged", and a later merge would bring its commit in again.

### Recovery

The content is right and the ancestry is wrong, so build the commit that should have been made, with the same tree and both parents, and move the branch to it:

```bash
git cat-file -p HEAD
fixed=$(git commit-tree -p HEAD~1 -p feature/timeouts -m "Merge branch 'feature/timeouts'" "HEAD^{tree}")
echo $fixed
git reset --soft $fixed
git log --graph --oneline --all
```

<!-- snippet: ch03/lab-17-3-special-refs-tour/12-recovery -->
```text
# The content is right; the commit lacks its second parent. Build the commit it should have been:
$ git cat-file -p HEAD
tree cbf3d17573b8aa459c4464c020972f62009dfc81
parent 740729a560918e0aa319995c3593b861891232bb
author Lab User <you@example.com> 1788759480 +0530
committer Lab User <you@example.com> 1788759480 +0530

Merge branch 'feature/timeouts'
$ fixed=$(git commit-tree -p HEAD~1 -p feature/timeouts -m "Merge branch 'feature/timeouts'" "HEAD^{tree}")
$ echo $fixed
3d99621c26fbe6251e0a3ba35d3ef9740690c22b
# Nothing points at the new commit yet. Move the branch to it; index and working tree stay as they are:
$ git reset --soft $fixed
$ git log --graph --oneline --all
*   3d99621 Merge branch 'feature/timeouts'
|\  
| * 0cab12e Double the timeout
* | 740729a Add logging configuration
* | 98932fb Raise timeout to 45 seconds
|/  
* ed95c38 Add service configuration
```
<!-- /snippet -->

`git commit-tree` 🟢 writes a commit object and moves nothing; `git reset --soft` 🟡 moves `main` to it and leaves the index and the working tree as they are, which is right because they already match that tree. The faulty single-parent commit is now reachable only from the reflog (and from `ORIG_HEAD`, which the reset wrote). Had it been pushed already, you would not move the branch: you would merge `feature/timeouts` again, which records the second parent in a new merge commit on top (Chapter 8).

### Verification

```bash
git cat-file -p HEAD
git branch --no-merged main
git status --short
ls -A .git
```

<!-- snippet: ch03/lab-17-3-special-refs-tour/13-verification -->
```text
$ git cat-file -p HEAD
tree cbf3d17573b8aa459c4464c020972f62009dfc81
parent 740729a560918e0aa319995c3593b861891232bb
parent 0cab12efae273ef530412d8a4be1e79e5b73a2ba
author Lab User <you@example.com> 1788759720 +0530
committer Lab User <you@example.com> 1788759720 +0530

Merge branch 'feature/timeouts'
$ git branch --no-merged main
$ git status --short
$ ls -A .git
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
objects
ORIG_HEAD
refs
```
<!-- /snippet -->

### Questions

1. Sort the names you saw into pseudorefs, root refs, and files that are neither. Give the test that separates the first two groups.
2. Name three commands in this tour that wrote `ORIG_HEAD`, and explain why a script must not rely on its value after more than one command. Which command left `AUTO_MERGE` behind at the checkpoint?
3. During the rebase `HEAD` was detached and `rebase-merge/head-name` held `refs/heads/feature/timeouts`. Why does a rebase detach `HEAD`, and how does `git rebase --abort` find its way back?
4. `git bisect start` created refs under `refs/bisect/` and plain files named `BISECT_*`. Why does the commit information live under `refs/` while the log is a plain file, and what does `git bisect reset` do with each?
5. After `MERGE_HEAD` was deleted, `git commit` produced a commit with the correct tree and the wrong parents. Explain both facts, and say what `git branch --no-merged main` showed afterwards.
6. The repair used `git commit-tree` followed by `git reset --soft`. Why `--soft`, what happened to the faulty commit, and what would you have done if that commit had already been pushed?

# V106: The index file as a data structure

- **Part.** 4: Git internals
- **Module.** 17
- **Planned minutes.** 20
- **Prerequisites.** V018, V105
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), section 3.12
- **Demo scripts.** `labs/ch03/index-file.sh`, `labs/ch03/index-debug.sh`, `labs/ch03/lab-17-1-index-structure.sh` (the companion `labs/ch03/lab-17-1-index-stat-volatile.sh` is volatile and is not replayed on screen)

## HOOK

**[ON SCREEN]** `git status`: every file listed as modified.

A CI job restores its workspace from a cache, and `git status` reports every tracked file as modified. A second job copies the repository into a container with `COPY` and sees the same thing. An engineer restores a laptop from backup: the same. Nobody edited anything.

And one more, from the first page of Chapter 3: a laptop lost power during a commit, and Git now says `fatal: index file corrupt`. Your CTO asks: what did we lose, the history, the work in progress, or nothing?

Both questions are about one file, `.git/index`, and both have a one-command answer once you know what that file contains.

## INTRODUCTION

You have used the index, also called the staging area, as a concept since the start of the course: the proposed next commit. In this video it is a data structure. You will read its header with `xxd`, decode its entries, watch its cache at work, see its flags and its stage numbers, and change its version.

Two replays from `labs/ch03`, `index-file.sh` and `index-debug.sh`, then the replay of Lab 17.1 up to its checkpoint. A sixty-line Python script in the course, `labs/ch03/read-index.py`, decodes the file by following the manual page; you will see its output.

Labels: `git ls-files` is 🟢 SAFE. `git update-index --index-version 4` is 🟢: it changes the storage of the index, not its content.

## LEARNING OBJECTIVES

After this video you can:

- List the fields of an index entry.
- Explain why every file shows as modified after a repository is copied, and repair it with one command.
- Read flags and stage numbers in `git ls-files --debug` and `--stage` output.
- Say what the index version changes.
- Create a commit without using the index. This last objective is practised in the homework exercise; the cited section does not demonstrate it.

## CONCEPT

Why look inside? Because the index does two jobs, and incidents come from confusing them.

In one sentence: the index is one binary file that records, for every tracked path, a mode, a blob ID, a stage number and a copy of the file's `stat` data, followed by extensions that let Git skip work; it is at once the proposed next commit and the cache that makes `git status` fast.

The format is specified in `git help gitformat-index`. A 12-byte header: the signature `DIRC`, a version, which is 2, 3 or 4, and the number of entries. Then the entries, sorted by path as bytes and then by stage.

Each entry has three parts before its path. First, 40 bytes of `stat` data: change time and modification time with nanoseconds, device, inode, mode, user, group, size. Second, the object ID. Third, 16 bits of flags: an assume-valid bit, an "extended" bit, the two-bit stage, and the length of the path. Version 3 adds 16 more bits, with the skip-worktree and intent-to-add flags. The path follows, padded with NUL bytes to a multiple of eight. Version 4 compresses each path against the previous one and drops the padding.

After the entries come the extensions, each a four-letter signature, a length and data. `TREE` caches the tree IDs that unchanged parts of the index already correspond to. `REUC` keeps the stages of a resolved conflict, so that `git checkout -m` can recreate it. Others serve the split index, the untracked cache and the filesystem monitor. The file ends with a checksum, unless `index.skipHash` replaces it by zeros.

Inside `.git`: one file, `index`, rewritten as a whole by every command that changes it. That includes `git status`, which refreshes the stat data and writes the result back.

Now the mechanism behind the hook. Git trusts the cached stat data to skip reading files. If the size, the times, the inode and the rest still match, Git does not open the file. A copy of a repository gives every file a new inode number and a new change time. The content is identical, and every cached entry is stale. Nothing is wrong with the data.

And the failure mode of the second question. The index is derived data, with one exception: content that was staged and never committed is named only there. So `fatal: index file corrupt` is repaired by deleting the file and running `git reset`; history and working tree are untouched, and only what was staged and not committed must be staged again.

## MENTAL MODEL

The textbook's analogy is a packing list for the next shipment, with an inspection sticker on every line saying when the item was last checked and how big it was. The list becomes the commit's tree. The stickers let the clerk skip boxes nobody touched.

The analogy breaks during a conflict, when the list carries three lines for one item: the merge base, ours and theirs.

Keep the two halves of each line apart. The left half, mode, ID, path, is content: it is the next commit. The right half, the sticker, is a cache: it can be wrong without anything being lost, and it is refreshed by reading the file again.

## DIAGRAM

**[DIAGRAM]** The file from top to bottom, one entry expanded.

```text
 header     DIRC | version | entry count                                            12 bytes
 entry      ctime  ctime_ns  mtime  mtime_ns  dev  ino  mode  uid  gid  size        40 bytes of stat data
            object ID                                                               20 bytes
            flags: assume-valid | extended | stage (2 bits) | path length           2 bytes
            path, NUL, padding to a multiple of 8 bytes                             variable
 ...        one entry per path, and per stage during a conflict, sorted by path
 extension  TREE | size | cached tree IDs        REUC | size | the stages that were resolved
 checksum   hash of everything above                                                20 bytes
```

Draw the header first: twelve bytes. Then one entry, opened up. The first row is the sticker: forty bytes of stat data. The second row is the object ID, twenty bytes. The third is two bytes of flags, and inside them the two-bit stage. Then the path.

Below: one entry per path, and per stage during a conflict. Then the tail of extensions, `TREE` and `REUC`. Then the checksum.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch03/index-file
```

```bash
git ls-files --stage
head -c 12 .git/index | xxd
```

**[PAUSE]** Eight tracked paths. Predict the twelve bytes: what are the first four as text, and what is the last number?

<!-- snippet: ch03/index-file/01-stage -->
```text
$ git ls-files --stage
100644 60a72d9888260645df622ecd424e474d09d40560 0	config.toml
120000 ac850302da978fa7e1ffb2915871a2a50175cfea 0	current-model
100644 ba6f678b335f69ce9ddd1551c01e264366b80a6b 0	models/v2.bin
100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc 0	run.sh
100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 0	src/handlers/health.py
100644 1ea8895d490a68d48ff799a4b567792e5fb4c2fb 0	src/handlers/ready.py
100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 0	src/server.py
160000 9eb542d53a49342a2e19fbca1482a3d10d638739 0	tokenizer
# The first twelve bytes of the file: signature, version, number of entries.
$ head -c 12 .git/index | xxd
00000000: 4449 5243 0000 0002 0000 0008            DIRC........
```
<!-- /snippet -->

`4449 5243` is `DIRC`, then version 2, then eight entries. In the listing above it, the columns are mode, blob ID, stage and path. Stage 0 everywhere: no conflict.

```bash
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
```

<!-- snippet: ch03/index-file/02-read-index -->
```text
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
header     signature=DIRC version=2 entries=8
entry      100644 60a72d9888260645df622ecd424e474d09d40560 stage=0 size=46    config.toml
entry      120000 ac850302da978fa7e1ffb2915871a2a50175cfea stage=0 size=13    current-model
entry      100644 ba6f678b335f69ce9ddd1551c01e264366b80a6b stage=0 size=11    models/v2.bin
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh
entry      100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 stage=0 size=30    src/handlers/health.py
entry      100644 1ea8895d490a68d48ff799a4b567792e5fb4c2fb stage=0 size=29    src/handlers/ready.py
entry      100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 stage=0 size=40    src/server.py
entry      160000 9eb542d53a49342a2e19fbca1482a3d10d638739 stage=0 size=0     tokenizer
extension  TREE (117 bytes)
checksum   valid
```
<!-- /snippet -->

The decoded file: the header, eight entries, a `TREE` extension, a valid checksum.

**[TERMINAL]** The stat data itself comes from the second script. Its numbers come from the filesystem and differ on every machine, so this transcript is not reproduced by `labs/verify-all.sh`. Yours will differ from the book.

```bash
labs/run ch03/index-debug
```

<!-- snippet: ch03/index-debug/01-debug -->
```text
$ git ls-files --debug config.toml run.sh
config.toml
  ctime: 1790892135:837284071
  mtime: 1790892135:837284071
  dev: 16777231	ino: 67018155
  uid: 501	gid: 0
  size: 46	flags: 0
run.sh
  ctime: 1790892135:668514559
  mtime: 1790892135:665748392
  dev: 16777231	ino: 67018022
  uid: 501	gid: 0
  size: 42	flags: 0
# The same numbers, asked from the filesystem (BSD stat, as on macOS):
$ stat -f 'ctime=%c mtime=%m dev=%d ino=%i uid=%u gid=%g size=%z' config.toml
ctime=1790892135 mtime=1790892135 dev=16777231 ino=67018155 uid=501 gid=0 size=46
```
<!-- /snippet -->

`git ls-files --debug` prints the sticker: change time, modification time, device, inode, user, group, size and flags. Below it, the same numbers asked from the filesystem with `stat`. They match. That match is what lets Git skip the file.

**[TERMINAL]** Back to the first script. Change only the modification time of a file.

```bash
touch -t 202001010000 config.toml
git diff-files
git status --short
git diff-files
```

**[PAUSE]** The content is unchanged. What does the plumbing command `git diff-files` print the first time, and the second time?

<!-- snippet: ch03/index-file/03-stat-cache -->
```text
# Change the modification time of a file, not its content.
$ touch -t 202001010000 config.toml
# Plumbing compares cached stat data only, and reports the path as possibly changed:
$ git diff-files
:100644 100644 60a72d9888260645df622ecd424e474d09d40560 0000000000000000000000000000000000000000 M	config.toml
# Porcelain re-reads the file, finds the same content, and refreshes the cached stat data:
$ git status --short
$ git diff-files
```
<!-- /snippet -->

The first time it reports the path as possibly changed, with an all-zero ID that means "look at the working tree". Plumbing compares cached stat data only. Then `git status` reads the file, hashes it, finds the blob the index already names, and writes fresh stat data back. The second `diff-files` is silent.

Now copy a whole repository.

```bash
cp -R . ../restored-copy
git -C ../restored-copy diff-files --name-status
git -C ../restored-copy diff-files --quiet
git -C ../restored-copy update-index --refresh
git -C ../restored-copy diff-files --quiet
```

<!-- snippet: ch03/index-file/04-copied-repository -->
```text
# Copy the whole repository, as a backup restore or a CI cache would.
$ cp -R . ../restored-copy
$ git -C ../restored-copy diff-files --name-status
M	config.toml
M	current-model
M	models/v2.bin
M	run.sh
M	src/handlers/health.py
M	src/handlers/ready.py
M	src/server.py
$ git -C ../restored-copy diff-files --quiet
[exit status: 1]
# New inode numbers and change times: every cached entry is stale. One refresh fixes it.
$ git -C ../restored-copy update-index --refresh
$ git -C ../restored-copy diff-files --quiet
[exit status: 0]
```
<!-- /snippet -->

Every entry is stale, and no file has changed. One refresh repairs it: `git update-index --refresh`. This is the whole explanation of "every file shows as modified" after a restore from backup, a CI cache, or a `COPY` into a container. It is never a data problem.

The flags.

```bash
git update-index --assume-unchanged run.sh
git update-index --skip-worktree config.toml
printf '# Inference service\n' > README.md
git add --intent-to-add README.md
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e "\["
```

**[PAUSE]** Look at the header line when it appears. Which field changed without anyone asking?

<!-- snippet: ch03/index-file/05-flags -->
```text
$ git update-index --assume-unchanged run.sh
$ git update-index --skip-worktree config.toml
$ printf '# Inference service\n' > README.md
$ git add --intent-to-add README.md
# Only the header and the entries that carry a flag:
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e "\["
header     signature=DIRC version=3 entries=9
entry      100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 stage=0 size=0     README.md  [intent-to-add]
entry      100644 60a72d9888260645df622ecd424e474d09d40560 stage=0 size=46    config.toml  [skip-worktree]
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh  [assume-valid]
```
<!-- /snippet -->

The version. Setting a version-3 flag upgraded the file from version 2 to version 3 on the spot. And the intent-to-add entry names the empty blob. Chapter 5 explains what each flag is for.

Stages.

```bash
git merge feature/timeouts
git ls-files --unmerged
git cat-file -p :1:config.toml | grep timeout
git cat-file -p :2:config.toml | grep timeout
git cat-file -p :3:config.toml | grep timeout
```

<!-- snippet: ch03/index-file/06-stages -->
```text
$ git merge feature/timeouts
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# One path, three entries: stage 1 is the merge base, 2 is ours, 3 is theirs.
$ git ls-files --unmerged
100644 60a72d9888260645df622ecd424e474d09d40560 1	config.toml
100644 cf333b0c40d2484e3c6d5040d289bdfb06d7e62a 2	config.toml
100644 62235dd3403d45d5edec627dcf862fe1b0ba940e 3	config.toml
$ git cat-file -p :1:config.toml | grep timeout
timeout_s = 30
$ git cat-file -p :2:config.toml | grep timeout
timeout_s = 45
$ git cat-file -p :3:config.toml | grep timeout
timeout_s = 60
```
<!-- /snippet -->

One path, three entries. Stage 1 is the merge base, 2 is ours, 3 is theirs. The colon syntax from the `rev-parse` video reads each of them.

```bash
git restore --theirs config.toml
git add config.toml
git ls-files --stage config.toml
python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e extension -e checksum
git commit --quiet -m "Merge feature/timeouts"
```

<!-- snippet: ch03/index-file/07-resolve -->
```text
$ git restore --theirs config.toml
$ git add config.toml
$ git ls-files --stage config.toml
100644 62235dd3403d45d5edec627dcf862fe1b0ba940e 0	config.toml
# The three stages moved into the "resolve undo" extension (REUC):
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e extension -e checksum
header     signature=DIRC version=2 entries=8
extension  TREE (98 bytes)
extension  REUC (93 bytes)
checksum   valid
$ git commit --quiet -m "Merge feature/timeouts"
```
<!-- /snippet -->

`git add` replaced the three entries by one stage-0 entry and moved them into the `REUC` extension, the resolve-undo record.

The version field.

```bash
git update-index --show-index-version
wc -c < .git/index
git update-index --index-version 4
head -c 12 .git/index | xxd
wc -c < .git/index
git update-index --index-version 2
```

<!-- snippet: ch03/index-file/08-version-4 -->
```text
$ git update-index --show-index-version
2
$ wc -c < .git/index
     898
$ git update-index --index-version 4
$ head -c 12 .git/index | xxd
00000000: 4449 5243 0000 0004 0000 0008            DIRC........
$ wc -c < .git/index
     860
$ git update-index --index-version 2
```
<!-- /snippet -->

Version 4 saved 38 bytes here by sharing path prefixes. In a repository with a hundred thousand paths, that saving is what makes `feature.manyFiles` worth switching on.

**[TERMINAL]** Lab 17.1, up to the checkpoint.

```bash
labs/run ch03/lab-17-1-index-structure
```

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

The lab repeats these steps on its own small repository. Point at one thing here: after `git add`, the entry already names a blob that exists. `git add` wrote the object. The lab continues through the stat cache and a conflict to its checkpoint; the failure scenario, a corrupt index, and its recovery are yours.

## COMMON MISTAKES

1. Treating "everything is modified" after a copy as changed files. Root cause: the copy has new inode numbers and change times, so the cached stat data is stale while the content is identical.
2. Treating `fatal: index file corrupt` as lost history. Root cause: the index is derived data; only content that was staged and never committed is named nowhere else.
3. Reading `git diff-files` output as proof of a change. Root cause: plumbing compares cached stat data only and does not read the file.
4. Being surprised that the index version changed. Root cause: skip-worktree and intent-to-add are version-3 flags, and setting one upgrades the file.
5. Expecting one entry per path at all times. Root cause: during a conflict a path has an entry per stage.

## PRODUCTION EXAMPLE

Three illustrative incidents for one backend team, and the first command for each.

"Everything is modified after the restore": `git update-index --refresh`. The CI job that restores a cached workspace now runs it, or any `git status`, before it asks whether the tree is clean.

"`git status` takes a minute on the monorepo": the stat cache already does its job; the next steps are `core.untrackedCache`, `core.fsmonitor` and `feature.manyFiles`, which Chapter 26 covers.

"`fatal: index file corrupt`" after the power loss: move the file aside, so that you can put it back, and run `git reset`. History and working tree are untouched, and only what was staged and not committed must be staged again. That is the failure scenario of Lab 17.1.

## PRACTICE EXERCISE

Do Lab 17.1, "Read the index as a data structure", in [`lab-manual/m17-index-refs-gitdir.md`](../../lab-manual/m17-index-refs-gitdir.md). Before each step, predict the header line: version and entry count. Before the conflict, predict how many entries `config.toml` will have and what each stage holds. Before the recovery, write down what you expect to have lost.

The challenge is Exercise 17.8, "An edit that Git does not see", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 74 of the CTO question bank:

> "Someone copied a repository with `cp -R` and now every file is "modified". Explain the mechanism and the one-command fix."

A strong answer says what the index caches for each entry and why, names which of those values a copy changes, and distinguishes the command that compares cached data from the command that reads the file. It gives the fix and adds, unprompted, why no data was at risk.

## RECAP

You should now be able to say:

- The index is a header, sorted entries, extensions and a checksum.
- An entry is stat data, an object ID, flags with a two-bit stage, and a path.
- Git trusts the stat data to skip reading files; a copy makes it stale, and `git update-index --refresh` repairs it.
- A conflict puts three entries for one path into the index; resolving moves them into `REUC`.
- Version 3 adds flags; version 4 compresses paths.

## HOMEWORK

Read section 3.12 of [Chapter 3](../../textbook/ch03-git-internals.md). Do Exercise 17.1, "The index as a table", Exercise 17.4, "The index during a conflict", and Exercise 17.6, "A commit without the index", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

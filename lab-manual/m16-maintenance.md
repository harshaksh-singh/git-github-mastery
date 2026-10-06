# Module 16 labs: The object database, part 2 (maintenance)

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the replay scripts in `labs/ch26/`. Read [Chapter 26: Performance](../textbook/ch26-performance.md), sections 26.3 to 26.6, first. Labs 16.1 and 16.2, on object storage, are in [m16-object-database.md](m16-object-database.md) and belong to Chapter 3.

## How to run these labs

Each lab has a setup script that builds the repository `orbit` (33 files, 94 commits on `main`) with a fixed clock, so the commit IDs in your sandbox are the ones printed here. Commits you create yourself get the real time and other IDs. From the course root:

```bash
bash labs/ch26/setup-16-3-maintenance.sh      # Lab 16.3: orbit as 507 loose objects, never maintained
labs/shell m16-3
cd orbit

bash labs/ch26/setup-16-4-commit-graph.sh     # Lab 16.4: orbit in one pack, without a commit-graph
labs/shell m16-4
cd orbit
```

Four things to know before you start:

- **Automatic maintenance is switched off in both repositories** (`maintenance.auto=false`, set by the setup scripts). With the default, your first commit would start a maintenance process in the background, and you would be studying a repository that changes while you look at it. Lab 16.3 shows what that process would have done.
- **Nothing here installs a scheduler.** Every `git maintenance run` in these labs runs in the foreground and ends before the prompt returns. Do not run `git maintenance start` in a lab: it writes to your system scheduler.
- **No timings.** The transcripts count objects, packs, commands started and filters consulted. Measure times on your own machine with `time` if you want them; they will be small on a repository of this size and are not the lesson.
- Lines such as `[exit status: 1]` are printed by the replay scripts; by hand, run `echo $?`. Lines that start with `#` are notes from the replay script.

To see a lab exactly as printed: `labs/run ch26/lab-16-3-maintenance-trace` or `labs/run ch26/lab-16-4-commit-graph`. Answers to the questions are in [solutions/m16-maintenance-lab-answers.md](../solutions/m16-maintenance-lab-answers.md). Write your own first.

## Lab 16.3: Trace what a maintenance run does

### Objective

Find out, from a trace and from the files under `.git`, exactly which commands one `git maintenance run` starts on Git 2.55, predict what the second run will do, and diagnose a maintenance run that reports success and does nothing.

### Prerequisites

Chapter 26, sections 26.3 and 26.4. Chapter 3, sections 3.7 (packs) and 3.9 (`packed-refs`). Lab 16.1.

### Setup

```bash
bash labs/ch26/setup-16-3-maintenance.sh
labs/shell m16-3
cd orbit
```

### Commands

```bash
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
find .git/refs -type f | wc -l
ls .git/objects/info .git/packed-refs
git maintenance is-needed --auto; echo $?

GIT_TRACE="$PWD/../trace-1.log" git maintenance run
sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -v -e '^pack-objects' -e '^multi-pack-index'

git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\{40\}/ID/' | sort
find .git/refs -type f | wc -l
wc -l < .git/packed-refs
git maintenance is-needed --auto; echo $?
```

`GIT_TRACE` with an absolute file name appends the trace to that file instead of printing it. The `sed` command keeps the lines in which one Git process starts another and strips everything before the command; the `grep` drops the helpers that `git repack` starts in turn. Read the whole file once with `less ../trace-1.log` to see what was dropped.

### Expected output

<!-- snippet: ch26/lab-16-3-maintenance-trace/01-before -->
```text
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 507
in-pack: 0
packs: 0
$ find .git/refs -type f | wc -l
       7
$ ls .git/objects/info .git/packed-refs
ls: .git/packed-refs: No such file or directory
.git/objects/info:
[exit status: 1]
$ git maintenance is-needed --auto
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch26/lab-16-3-maintenance-trace/02-trace -->
```text
$ GIT_TRACE="$PWD/../trace-1.log" git maintenance run
$ sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -v -e '^pack-objects' -e '^multi-pack-index'
pack-refs --all --prune
reflog expire --all
repack -d -l --cruft --cruft-expiration=2.weeks.ago --quiet --write-midx
commit-graph write --split --reachable --no-progress
worktree prune --expire 3.months.ago
rerere gc
```
<!-- /snippet -->

<!-- snippet: ch26/lab-16-3-maintenance-trace/03-after -->
```text
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 507
packs: 1
$ find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\{40\}/ID/' | sort
.git/objects/info/commit-graphs/commit-graph-chain
.git/objects/info/commit-graphs/graph-ID.graph
.git/objects/info/packs
.git/objects/pack/multi-pack-index
.git/objects/pack/pack-ID.idx
.git/objects/pack/pack-ID.pack
.git/objects/pack/pack-ID.rev
$ find .git/refs -type f | wc -l
       0
$ wc -l < .git/packed-refs
      13
$ git maintenance is-needed --auto
[exit status: 1]
```
<!-- /snippet -->

### What happened internally

Before the run: 507 loose objects, seven refs in seven files, no `packed-refs`, an empty `objects/info`, and `is-needed --auto` exiting 0, which means an automatic run would have acted.

The run started six commands, the six tasks of the `geometric` strategy in the order Git runs them:

| Command | Task | Effect here |
|---|---|---|
| `pack-refs --all --prune` | `pack-refs` | Seven refs moved into `packed-refs`; their loose files removed |
| `reflog expire --all` | `reflog-expire` | Nothing: the lab configuration sets both expiry periods to `never` |
| `repack -d -l --cruft --cruft-expiration=2.weeks.ago --quiet --write-midx` | `geometric-repack` | 507 loose objects into one pack; a multi-pack-index written |
| `commit-graph write --split --reachable --no-progress` | `commit-graph` | A commit-graph chain with one layer |
| `worktree prune --expire 3.months.ago` | `worktree-prune` | Nothing: there are no linked working trees |
| `rerere gc` | `rerere-gc` | Nothing: there is no `rr-cache` |

There is no `git gc` in the list. The repack line has no `--geometric`: with no pack to preserve, Git chose an all-into-one repack, which is also the only kind that writes a cruft pack. `packed-refs` has 13 lines: a header, seven refs, and one extra line for each of the five annotated tags giving the commit it points to.

### Checkpoint

Make three commits and predict the repack line of the second run before you look at it. Will it say `--cruft` or `--geometric=2`? How many packs will there be, with how many objects?

```bash
printf 'timeout_ms: 700\nupstream: ranker\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 700 ms'
printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
printf 'BATCH_SIZE = 1000\n' > services/ingest/settings.py && git commit -q -am 'ingest: raise the batch size to 1000'
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
GIT_TRACE="$PWD/../trace-2.log" git maintenance run
sed -n 's/.*trace: run_command: git //p' ../trace-2.log | grep -e '^repack'
for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
```

<!-- snippet: ch26/lab-16-3-maintenance-trace/04-checkpoint -->
```text
# Three commits, then a second run. Predict the repack line before you look.
$ printf 'timeout_ms: 700\nupstream: ranker\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 700 ms'
$ printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
$ printf 'BATCH_SIZE = 1000\n' > services/ingest/settings.py && git commit -q -am 'ingest: raise the batch size to 1000'
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 15
in-pack: 507
packs: 1
$ GIT_TRACE="$PWD/../trace-2.log" git maintenance run
$ sed -n 's/.*trace: run_command: git //p' ../trace-2.log | grep -e '^repack'
repack -d -l --geometric=2 --quiet --write-midx
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
      15
```
<!-- /snippet -->

Fifteen loose objects (three commits, each with a commit object, three trees and a blob) became a second pack. The existing pack of 507 was left alone, because 507 is more than twice 15.

### Failure scenario

A maintenance process was killed in the middle of its work (a laptop lid closed, a CI runner cancelled) and left its lock file behind. Simulate that, then commit and maintain as usual.

```bash
: > .git/objects/maintenance.lock
printf 'epochs: 20\nlearning_rate: 0.0003\nbatch_size: 32\n' > pipelines/training/config.yaml && git commit -q -am 'training: train for 20 epochs'
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
git maintenance run; echo $?
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
GIT_TRACE="$PWD/../trace-3.log" git maintenance run
grep -c 'run_command' ../trace-3.log
```

<!-- snippet: ch26/lab-16-3-maintenance-trace/05-failure -->
```text
# Failure scenario: a maintenance process was killed and left its lock file behind.
$ : > .git/objects/maintenance.lock
$ printf 'epochs: 20\nlearning_rate: 0.0003\nbatch_size: 32\n' > pipelines/training/config.yaml && git commit -q -am 'training: train for 20 epochs'
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 5
in-pack: 522
packs: 2
# Maintenance reports success:
$ git maintenance run
[exit status: 0]
# and has done nothing:
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 5
in-pack: 522
packs: 2
$ GIT_TRACE="$PWD/../trace-3.log" git maintenance run
$ grep -c 'run_command' ../trace-3.log
0
```
<!-- /snippet -->

Exit status 0, no message, and the five loose objects are still loose. The trace contains no child command at all: maintenance started nothing. In your terminal you may see a warning where the transcript shows none, because standard error is a terminal there. In a scheduled or automatic run nobody sees it. A repository in this state accumulates loose objects and packs for weeks while every log says that maintenance succeeded.

### Recovery

Make maintenance speak, find the lock, make sure that no maintenance process is running for this repository, and only then remove the lock.

```bash
git maintenance run --no-quiet; echo $?
ls .git/objects/*.lock
wc -c < .git/objects/maintenance.lock
pgrep -fl 'git maintenance'
rm .git/objects/maintenance.lock
git maintenance run --no-quiet; echo $?
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
```

<!-- snippet: ch26/lab-16-3-maintenance-trace/06-diagnosis -->
```text
# Without a terminal on standard error, maintenance is quiet. Ask it to speak:
$ git maintenance run --no-quiet
warning: lock file '.git/objects/maintenance' exists, skipping maintenance
[exit status: 0]
$ ls .git/objects/*.lock
.git/objects/maintenance.lock
# The lock is an empty file. A running maintenance process holds the same file.
$ wc -c < .git/objects/maintenance.lock
       0
```
<!-- /snippet -->

<!-- snippet: ch26/lab-16-3-maintenance-trace/07-recovery -->
```text
# After checking that no maintenance process is running for this repository:
$ rm .git/objects/maintenance.lock
$ git maintenance run --no-quiet
[exit status: 0]
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 527
packs: 3
```
<!-- /snippet -->

With `--no-quiet` the reason appears: "lock file '.git/objects/maintenance' exists, skipping maintenance". The lock is the file `maintenance.lock`, and it is empty; a live maintenance process holds the very same file, which is why you check for a process before you delete it. `pgrep -fl 'git maintenance'` lists such processes with their command lines and prints nothing when there are none. The replay does not run it, because its output depends on what else your machine is doing. After the lock is gone, the same command packs the five objects into a third pack.

### Verification

```bash
git fsck
git multi-pack-index verify
git commit-graph verify
ls .git/objects/*.lock
git log --oneline -4
```

<!-- snippet: ch26/lab-16-3-maintenance-trace/08-verification -->
```text
$ git fsck
[exit status: 0]
$ git multi-pack-index verify
[exit status: 0]
$ git commit-graph verify
[exit status: 0]
$ ls .git/objects/*.lock
ls: .git/objects/*.lock: No such file or directory
[exit status: 1]
$ git log --oneline -4
9549dc8 training: train for 20 epochs
5d6e554 ingest: raise the batch size to 1000
90b6267 ranker: return the top 20
9faaf97 gateway: lower the upstream timeout to 700 ms
```
<!-- /snippet -->

The object database, the multi-pack-index and the commit-graph check out, no lock is left, and all four of your commits are in history. Your commit IDs differ from the transcript.

### Questions

1. List the six commands that one `git maintenance run` started and say, for each, whether it can delete anything, and what.
2. The first run used `--cruft --cruft-expiration=2.weeks.ago` and the second `--geometric=2`. What decides which form Git uses, and what does each do with unreachable objects?
3. After the recovery the repository has three packs with 507, 15 and 5 objects. Is that a problem? What will the next run do if you add 20 more loose objects?
4. `git maintenance run` exited 0 while a lock file existed. Why is that a reasonable design for automatic maintenance, and why is it dangerous for a scheduled job that somebody monitors by exit status?
5. The manual says that `git gc` "does not take the lock in the same way as `git maintenance run`". What follows for a cron job that runs `git gc` on a repository with scheduled maintenance?
6. With the default configuration, which of your commands in this lab would have started maintenance on their own, and how could you have seen it?

## Lab 16.4: Write and verify a commit-graph

### Objective

Write a commit-graph with changed-path filters, read its header, count the work that the filters save on path-limited history queries, and recover from a commit-graph file that makes Git give wrong answers about a healthy history.

### Prerequisites

Chapter 26, section 26.6. Chapter 3, section 3.8, for `git fsck`.

### Setup

```bash
bash labs/ch26/setup-16-4-commit-graph.sh
labs/shell m16-4
cd orbit
```

The repository is packed and has no commit-graph.

### Commands

```bash
git rev-list --count HEAD
ls .git/objects/info/commit-graph
git log --oneline -- docs | wc -l
GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | grep -c 'statistics:'

git commit-graph write --reachable --changed-paths
git commit-graph verify; echo $?
xxd -l 64 .git/objects/info/commit-graph

GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | sed -n 's/.*statistics://p'
GIT_TRACE2_PERF=1 git log --oneline -- tools/ci/affected.py 2>&1 >/dev/null | sed -n 's/.*statistics://p'
git log --oneline -- tools/ci/affected.py
```

`GIT_TRACE2_PERF=1` makes Git print a table of what a command did. One row of `git log` reports how the changed-path filters answered, and the `sed` command prints that row's payload. To feel the difference on a large repository of your own, put `time` in front of the `git log` command with and without `-c core.commitGraph=false`.

### Expected output

<!-- snippet: ch26/lab-16-4-commit-graph/01-before -->
```text
$ git rev-list --count HEAD
94
$ ls .git/objects/info/commit-graph
ls: .git/objects/info/commit-graph: No such file or directory
[exit status: 1]
$ git log --oneline -- docs | wc -l
      13
$ GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | grep -c 'statistics:'
0
```
<!-- /snippet -->

<!-- snippet: ch26/lab-16-4-commit-graph/02-write -->
```text
$ git commit-graph write --reachable --changed-paths
$ git commit-graph verify
[exit status: 0]
$ xxd -l 64 .git/objects/info/commit-graph
00000000: 4347 5048 0101 0600 4f49 4446 0000 0000  CGPH....OIDF....
00000010: 0000 005c 4f49 444c 0000 0000 0000 045c  ...\OIDL.......\
00000020: 4344 4154 0000 0000 0000 0bdc 4744 4132  CDAT........GDA2
00000030: 0000 0000 0000 195c 4249 4458 0000 0000  .......\BIDX....
```
<!-- /snippet -->

<!-- snippet: ch26/lab-16-4-commit-graph/03-after -->
```text
$ GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":13,"definitely_not":81,"false_positive":0}
$ GIT_TRACE2_PERF=1 git log --oneline -- tools/ci/affected.py 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":1,"definitely_not":93,"false_positive":0}
$ git log --oneline -- tools/ci/affected.py
3642e7e docs, tools: add the architecture notes, runbooks and the affected-projects script
```
<!-- /snippet -->

### What happened internally

`git commit-graph write --reachable --changed-paths` 🟢 walked all commits reachable from refs, 96 of them, and wrote one file. The header is the signature `CGPH`, a version, the hash version, the number of chunks (six) and the number of base graphs (zero). The chunk table follows, each entry a four-letter name and an offset: `OIDF` at 0x5c, `OIDL` at 0x45c, `CDAT` at 0xbdc, then `GDA2`, `BIDX` and `BDAT`. `OIDL` is the sorted list of commit IDs; `CDAT` holds, for each commit in that order, its tree, the positions of its parents in the list, its generation and its date, 36 bytes per commit.

Before the file existed, `git log -- docs` had no filters to consult and compared trees for all 94 commits on `main`. With filters, 81 commits answered "definitely not" and were skipped, and 13 answered "maybe" and were compared; all 13 turned out to be real. For a file that one commit touched, 93 of 94 were skipped.

### Checkpoint

A commit-graph must never change an answer. Check two different kinds of question with the file and with the file bypassed:

```bash
git log --oneline -- docs | wc -l
git -c core.commitGraph=false log --oneline -- docs | wc -l
git merge-base main feature/rerank-cache
git -c core.commitGraph=false merge-base main feature/rerank-cache
```

<!-- snippet: ch26/lab-16-4-commit-graph/04-checkpoint -->
```text
# Checkpoint: the answers are the same with and without the file.
$ git log --oneline -- docs | wc -l
      13
$ git -c core.commitGraph=false log --oneline -- docs | wc -l
      13
$ git merge-base main feature/rerank-cache
d259a34f3117e4516fb2f7c071b2dd9c8edc9e5b
$ git -c core.commitGraph=false merge-base main feature/rerank-cache
d259a34f3117e4516fb2f7c071b2dd9c8edc9e5b
```
<!-- /snippet -->

### Failure scenario

One byte of the file is damaged: a failing disk, a bad copy, a backup restored over a newer file. The chunk table says that the commit data starts at 0xbdc, which is 3036. Byte 3059 lies in the first entry of that chunk, in the field that names the first parent. Flip all its bits. The file is read-only, so make it writable first.

```bash
chmod u+w .git/objects/info/commit-graph
python3 -c "import sys; f = open(sys.argv[1], 'r+b'); f.seek(3059); b = f.read(1); f.seek(3059); f.write(bytes([b[0] ^ 255])); f.close()" .git/objects/info/commit-graph
git rev-list --count HEAD; echo $?
git log --oneline 2>/dev/null | wc -l
git log --oneline -3
```

<!-- snippet: ch26/lab-16-4-commit-graph/05-failure -->
```text
# Failure scenario: one damaged byte in the commit data chunk (it starts at 0xbdc = 3036).
$ chmod u+w .git/objects/info/commit-graph
$ python3 -c "import sys; f = open(sys.argv[1], 'r+b'); f.seek(3059); b = f.read(1); f.seek(3059); f.write(bytes([b[0] ^ 255])); f.close()" .git/objects/info/commit-graph
$ git rev-list --count HEAD
fatal: invalid parent position 227
[exit status: 128]
$ git log --oneline 2>/dev/null | wc -l
      88
$ git log --oneline -3
100bb99 schemas, gateway, ingest: add the tenant field in one change
d259a34 docs: record architecture change 12
a7c68be training: train for 15 epochs
[exit status: 0]
```
<!-- /snippet -->

`git rev-list --count HEAD` dies. `git log --oneline` prints 88 commits and then dies; with the error hidden, as in a script that discards standard error, the history looks six commits shorter than it is. `git log -3` works, because it never reaches the damaged entry. The entry belongs to the commit with the smallest ID, `00eae68`, an early commit; every walk that passes through it is told that its parent is at position 227 of a list that has 96 entries.

### Recovery

First decide what is damaged: the history or the file that describes it. Bypass the file, then verify it.

```bash
git -c core.commitGraph=false rev-list --count HEAD
git commit-graph verify; echo $?
git fsck; echo $?
git -c core.commitGraph=false fsck; echo $?
rm .git/objects/info/commit-graph
git rev-list --count HEAD
git commit-graph write --reachable --changed-paths
```

<!-- snippet: ch26/lab-16-4-commit-graph/06-diagnosis -->
```text
# Is the history damaged, or only the file that describes it? Bypass the file:
$ git -c core.commitGraph=false rev-list --count HEAD
94
$ git commit-graph verify
the commit-graph file has incorrect checksum and is likely corrupt
fatal: invalid parent position 227
[exit status: 128]
$ git fsck
the commit-graph file has incorrect checksum and is likely corrupt
fatal: invalid parent position 227
[exit status: 16]
# With the file bypassed, the object database checks out clean:
$ git -c core.commitGraph=false fsck
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch26/lab-16-4-commit-graph/07-recovery -->
```text
# The commit-graph is derived data. Delete it and write it again from the objects:
$ rm .git/objects/info/commit-graph
$ git rev-list --count HEAD
94
$ git commit-graph write --reachable --changed-paths
```
<!-- /snippet -->

With `core.commitGraph=false` the count is 94 again: the commits are intact. `git commit-graph verify` reports that the file's checksum is wrong, which Git does not check on ordinary reads, and `git fsck` fails with exit status 16 because it runs the same verification. The same `git fsck` with the file bypassed is clean. The commit-graph is derived data, so the repair is to delete it, after which Git reads commit objects as it did before the file existed, and to write it again.

### Verification

```bash
git commit-graph verify; echo $?
git fsck; echo $?
git rev-list --count HEAD
GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | sed -n 's/.*statistics://p'
```

<!-- snippet: ch26/lab-16-4-commit-graph/08-verification -->
```text
$ git commit-graph verify
[exit status: 0]
$ git fsck
[exit status: 0]
$ git rev-list --count HEAD
94
$ GIT_TRACE2_PERF=1 git log --oneline -- docs 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":13,"definitely_not":81,"false_positive":0}
```
<!-- /snippet -->

### Questions

1. What two kinds of information does the file hold, and which commands benefit from each?
2. In the statistics for `docs`, what do `maybe`, `definitely_not` and `false_positive` count, and why can a filter never answer "definitely yes"?
3. After you commit, the new commit is not in the commit-graph. Does `git log` give a wrong answer? What does Git do, and when is the file updated?
4. One damaged byte made `git rev-list --count HEAD` fail while `git log -3` worked. Explain both.
5. `git fsck` reported the damage. Why did it exit with a failure although every object was intact, and how did you prove that the objects were intact?
6. Which other files under `.git/objects` are derived data that you may delete and rebuild, and which must you never delete?

# V108: The commit-graph, the multi-pack-index, reachability bitmaps, and the working-tree accelerators

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 22
- **Prerequisites.** V104
- **Textbook sections.** [Chapter 26](../../textbook/ch26-performance.md), sections 26.6 to 26.9
- **Demo scripts.** `labs/ch26/commit-graph.sh`, `labs/ch26/midx-bitmaps.sh`, `labs/ch26/scale-dimensions.sh` (snippet `fsmonitor-off`)

## HOOK

**[ON SCREEN]** "Which commits changed the scoring rubric?" — twenty seconds.

An evaluation team asks one question many times a day: which commits changed the scoring rubric? The command is `git log` with a path. On their repository, with its long history, the answer takes twenty seconds each time.

The repository is not broken. To answer, Git compares the tree of every commit with its parent's tree, one commit after another, to find the few that touched the path. The fix is not a smaller history. It is a file that lets Git dismiss most commits without looking at their trees.

## INTRODUCTION

In V104 you saw a table: slow command, what it touches, remedy. This video takes four remedies from that table. The commit-graph, for history walks and path-limited logs. The multi-pack-index, for object lookups across many packs. Reachability bitmaps, for serving clones and fetches. And two accelerators for the working tree: the untracked cache and the file-system monitor.

All four are derived data. Each can be deleted and rebuilt. None changes a commit ID.

Two things about the demos. They show counts of work, not seconds, because timings are not reproducible and counters are. And this course starts no daemon: the file-system monitor is described, and the transcript shows only that it is off and how to ask.

Labels: `git commit-graph write`, `git commit-graph verify` and `git multi-pack-index write` are 🟢 SAFE. They add derived files.

## LEARNING OBJECTIVES

After this video you can:

- Say which two kinds of data a commit-graph file holds and which commands each helps.
- Write a commit-graph and observe the effect on a history query.
- Explain what a stale commit-graph does and when Git ignores the file.
- Say what a multi-pack-index and a bitmap are for and why bitmaps are mainly a server feature.
- Name the two features that speed up `git status` in a large working tree.

## CONCEPT

The commit-graph. In one sentence: it is a file that stores, for every commit, its parents, its root tree, its date and its distance from the roots of history, and optionally a compact summary of the paths it changed, so that history walks stop decompressing commit objects and stop comparing trees that did not change.

Two things are stored, and they help different commands.

First, the graph with generation numbers. A commit's generation is larger than that of every ancestor. A walk that asks "is A an ancestor of B" can stop as soon as it reaches commits whose generation is below A's, instead of walking to the root. This is what `git merge-base`, `git branch --contains`, `git tag --contains` and `git log --graph` gain from.

Second, changed-path Bloom filters, written with `--changed-paths`. For each commit, a small probabilistic set of the paths that differ from its first parent. Asked "did this commit touch `services/ranker`?", a filter answers "definitely not" or "maybe". Only the "maybe" commits need their trees compared. This is what `git log` with a path and `git blame` gain from.

Who writes the file? You can, with `git commit-graph write --reachable --changed-paths`. `git gc` writes one; the setting is `gc.writeCommitGraph`, default true. The `commit-graph` maintenance task writes one incrementally. And `fetch.writeCommitGraph` does it after fetches. Filters are written only if you requested them once, or with `commitGraph.changedPaths=true`, which needs Git 2.52 or later.

Failure modes. A stale file is slower, not wrong: Git notices commits that are missing from the file and reads those from the objects. A damaged file is another matter, and Lab 16.4 produces one. And Git stops using the file altogether in some repositories. The manual's caveat: "The existence of replace objects or commit grafts turns off reading or writing to the commit-graph." The same holds in a shallow repository.

The multi-pack-index. In one sentence: it is one sorted index over the objects of many packs, so that finding an object costs one lookup however many packs there are. Each pack has its own `.idx`. With N packs, a lookup may search N indexes. Geometric repacking, fetches and partial clones all produce many packs on purpose, so the cost has to be removed elsewhere: the file `objects/pack/multi-pack-index` maps every object ID to a pack and an offset. Git reads it when `core.multiPackIndex` is true, the default.

Reachability bitmaps. In one sentence: a bitmap file stores, for selected commits, one bit per object in the pack saying whether that commit reaches it, so that a server can answer "which objects does this client need" without walking the graph. Serving a clone or fetch starts with enumerating objects: everything reachable from the wanted commits minus everything reachable from the ones the client has. With bitmaps that is a few bitwise operations, and stretches of the existing pack can be copied to the client verbatim.

Why is this a server feature? The setting `repack.writeBitmaps` "defaults to true on bare repos, false otherwise". And `scalar` sets `pack.useBitmaps=false` on clients, with the reason that bitmaps "are optimized for server-side use, not client-side use".

The working tree. In one sentence: the untracked cache remembers which directories contained no untracked files, the file-system monitor tells Git which paths changed since the last command, and together they replace the scan of the working tree by a question.

Recall the two kinds of work in `git status`: an `lstat` call per tracked file, and a walk of every directory in search of untracked files. The untracked cache, `core.untrackedCache`, attacks the second: the index records the modification time of each directory, and a directory whose time has not changed is not read again. Its default is `keep`; `feature.manyFiles=true` and `scalar` switch it on. The file-system monitor, `core.fsmonitor=true`, attacks the first: a daemon, `git fsmonitor--daemon`, subscribes to the operating system's change notifications for one working tree, and `git status` calls `lstat` only on the paths it reports. The manual lists caveats: it does not know about submodules, and it refuses network-mounted repositories by default.

One fact here the textbook marks unverified, and so do I: the first release with a working built-in daemon. The manual page exists at the 2.36.0 tag, and a GitHub engineering post dates the feature to Git 2.37. Git 2.55 added the daemon on Linux according to its release notes, while the configuration manual of 2.55 still names only Windows and macOS.

When not to use them: both working-tree features belong to developer machines. A CI job that runs `git status` once gains nothing from a daemon that must first be started.

## MENTAL MODEL

The textbook's analogy for the commit-graph: a railway timetable printed from the day's train records. Asking the timetable is faster than reading the records, and it is wrong the moment the records change without a reprint.

The analogy breaks in Git's favour. Git notices commits that are missing from the file and reads those from the objects. So a stale commit-graph is slower, not wrong.

Extend the model to all four features of this video: each is an index printed from primary data. The primary data are the objects and the working tree. If an index is missing or old, Git does the work the long way. That is why deleting any of them is safe and why none of them is a backup.

## DIAGRAM

**[DIAGRAM]** The same question, `git log -- services/ranker`, drawn twice.

```text
  without a commit-graph                        with changed-path filters

  commit 94 --> open commit, open its tree,     commit 94 --> filter: "definitely not"   skip
                compare with parent's tree
  commit 93 --> open, compare                   commit 93 --> filter: "maybe"            compare trees
  commit 92 --> open, compare                   commit 92 --> filter: "definitely not"   skip
     ...                                           ...
  commit  1 --> open, compare                   commit  1 --> filter: "definitely not"   skip

  94 tree comparisons                           13 "maybe", 81 "definitely not":
                                                13 tree comparisons, read from one file
```

On the left, no file. For each of the 94 commits on `main`, Git opens the commit object, opens its tree, and compares it with the parent's tree. Ninety-four comparisons to find the commits that changed one directory.

On the right, one file. For each commit, Git consults a filter. "Definitely not": skip, no tree is opened. "Maybe": compare. The numbers at the bottom are the ones you will see Git report in a moment.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch26/commit-graph
```

```bash
ls .git/objects/info
git rev-list --count main
git log --oneline -- services/ranker | wc -l
GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'
```

<!-- snippet: ch26/commit-graph/01-without -->
```text
# No commit-graph yet. A path-limited log has to compare trees commit by commit:
$ ls .git/objects/info
[exit status: 0]
$ git rev-list --count main
94
$ git log --oneline -- services/ranker | wc -l
      13
# Git reports statistics about changed-path filters through trace2. Without a file there are none:
$ GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'
0
```
<!-- /snippet -->

No commit-graph yet. Ninety-four commits, thirteen of which changed `services/ranker`. Git reports statistics about changed-path filters through trace2; without a file there are none.

```bash
git commit-graph write --reachable --changed-paths
ls .git/objects/info
git commit-graph verify
xxd -l 96 .git/objects/info/commit-graph
```

<!-- snippet: ch26/commit-graph/02-write -->
```text
$ git commit-graph write --reachable --changed-paths
$ ls .git/objects/info
commit-graph
$ git commit-graph verify
[exit status: 0]
# The file starts with the signature CGPH and a table of chunks:
$ xxd -l 96 .git/objects/info/commit-graph
00000000: 4347 5048 0101 0600 4f49 4446 0000 0000  CGPH....OIDF....
00000010: 0000 005c 4f49 444c 0000 0000 0000 045c  ...\OIDL.......\
00000020: 4344 4154 0000 0000 0000 0bdc 4744 4132  CDAT........GDA2
00000030: 0000 0000 0000 195c 4249 4458 0000 0000  .......\BIDX....
00000040: 0000 1adc 4244 4154 0000 0000 0000 1c5c  ....BDAT.......\
00000050: 0000 0000 0000 0000 0000 1e07 0000 0001  ................
```
<!-- /snippet -->

One file, `objects/info/commit-graph`. Its header is the signature `CGPH`, and the chunk table names the parts. `OIDF` and `OIDL`: the commit IDs, sorted, with a fan-out table. `CDAT`: tree, parents, generation and date per commit. `GDA2`: generation data. `BIDX` and `BDAT`: the Bloom filters.

```bash
GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'
GIT_TRACE2_PERF=1 git log --oneline -- libs/schemas 2>&1 >/dev/null | sed -n 's/.*statistics://p'
git log --oneline -- libs/schemas
```

**[PAUSE]** Ninety-four commits, thirteen real matches. How many filters will say "maybe", and how many "definitely not"?

<!-- snippet: ch26/commit-graph/03-with -->
```text
# The same question again. One filter per commit was consulted:
$ GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":13,"definitely_not":81,"false_positive":0}
$ git log --oneline -- services/ranker | wc -l
      13
# A path that few commits touch:
$ GIT_TRACE2_PERF=1 git log --oneline -- libs/schemas 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":2,"definitely_not":92,"false_positive":0}
$ git log --oneline -- libs/schemas
100bb99 schemas, gateway, ingest: add the tenant field in one change
00eae68 schemas: add the event types and their JSON schemas
```
<!-- /snippet -->

Thirteen "maybe" and 81 "definitely not"; all 13 were real, so `false_positive` is 0. For `libs/schemas`, 92 were dismissed. The answer did not change, and the work fell from 94 comparisons to 13, and to 2. That ratio, not a stopwatch, is why the feature matters: in a monorepo, most commits do not touch any given path.

```bash
printf '\nSee docs/runbooks for the on-call procedures.\n' >> README.md
git commit -q -am 'readme: point to the runbooks'
git commit-graph verify
git commit-graph write --reachable --changed-paths --split
wc -l < .git/objects/info/commit-graphs/commit-graph-chain
```

**[PAUSE]** A new commit that is not in the file. Does `verify` fail?

<!-- snippet: ch26/commit-graph/04-stale-and-split -->
```text
# A commit-graph is a snapshot. New commits are not in it until it is written again:
$ printf '\nSee docs/runbooks for the on-call procedures.\n' >> README.md
$ git commit -q -am 'readme: point to the runbooks'
$ git commit-graph verify
[exit status: 0]
# Maintenance adds a small file on top instead of rewriting the large one:
$ git commit-graph write --reachable --changed-paths --split
$ find .git/objects/info -type f | sed 's/[0-9a-f]\{40\}/ID/' | sort
.git/objects/info/commit-graphs/commit-graph-chain
.git/objects/info/commit-graphs/graph-ID.graph
.git/objects/info/commit-graphs/graph-ID.graph
$ wc -l < .git/objects/info/commit-graphs/commit-graph-chain
       2
$ git commit-graph verify
[exit status: 0]
```
<!-- /snippet -->

It passes. A new commit does not invalidate the file. With `--split`, the form maintenance uses, a small file is added on top and `commit-graph-chain` lists the layers. Layers are merged when the upper one grows large relative to the one below.

```bash
git replace --graft HEAD HEAD~2
git replace -d HEAD
GIT_TRACE2_PERF=1 git -c core.commitGraph=false log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'
```

<!-- snippet: ch26/commit-graph/05-switched-off -->
```text
# A replacement object changes what the history is, so Git stops trusting the file:
$ git replace --graft HEAD HEAD~2
$ GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'
0
$ git replace -d HEAD
Deleted replace ref '80e1432b3813ec4352a4131e441d28a312b981ca'
$ GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'
1
# The switch that bypasses the file for one command:
$ GIT_TRACE2_PERF=1 git -c core.commitGraph=false log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'statistics:'
0
```
<!-- /snippet -->

A replacement object changes what the history is, so Git stops trusting the file: zero statistics lines. Delete the replacement, and the file is used again. The last command is the diagnostic to remember: `core.commitGraph=false` bypasses the file for one command.

**[ON SCREEN]** State table: `git commit-graph write --reachable --changed-paths` leaves working tree, index, HEAD and the current branch ref unchanged; it writes `objects/info/commit-graph`, or a layer under `objects/info/commit-graphs/` with `--split`; remote and GitHub unchanged.

**[TERMINAL]**

```bash
labs/run ch26/midx-bitmaps
```

<!-- snippet: ch26/midx-bitmaps/01-several-packs -->
```text
# A clone that has fetched three times since it was made holds four packs, each with its own index:
$ cd dev
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   4 idx
   4 pack
   4 rev
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
       4
       4
       4
```
<!-- /snippet -->

A clone that has fetched three times with `fetch.unpackLimit=1`, the setting `scalar` uses so that every fetch keeps its pack. Four packs, four indexes.

```bash
git multi-pack-index write
git multi-pack-index verify
xxd -l 12 .git/objects/pack/multi-pack-index
git cat-file -t HEAD
git rev-list --count --objects --all
```

<!-- snippet: ch26/midx-bitmaps/02-midx -->
```text
# One index over all packs:
$ git multi-pack-index write
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   4 idx
   1 multi-pack-index
   4 pack
   4 rev
$ git multi-pack-index verify
[exit status: 0]
# Signature MIDX, version, hash version, number of chunks, number of base files, number of packs:
$ xxd -l 12 .git/objects/pack/multi-pack-index
00000000: 4d49 4458 0101 0400 0000 0004            MIDX........
# Objects are found exactly as before:
$ git cat-file -t HEAD
commit
$ git rev-list --count --objects --all
519
```
<!-- /snippet -->

One new file. The signature `MIDX`, and the last byte of the header shown says four packs. Nothing else changed, and nothing you can observe through Git changed. Maintenance writes this file as part of its repack; you saw `--write-midx` in the trace in V104.

<!-- snippet: ch26/midx-bitmaps/03-bitmap-on-server -->
```text
$ cd ..
# The bare repository that plays the server was packed by "git gc". Beside the pack:
$ ls server/orbit.git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 bitmap
   1 idx
   1 pack
   1 rev
# The non-bare repository after the same command:
$ ls orbit/.git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 idx
   1 pack
   1 rev
# Why the difference: the default of repack.writeBitmaps depends on the kind of repository.
$ git -C server/orbit.git config get repack.writeBitmaps
[exit status: 1]
$ git -C server/orbit.git rev-parse --is-bare-repository
true
```
<!-- /snippet -->

The same `git gc` on two repositories. Only the bare one, which plays the server, got a `.bitmap`. The default of `repack.writeBitmaps` depends on the kind of repository.

**[PAUSE]** We serve one full clone with the bitmap and one without. Will the clones differ?

<!-- snippet: ch26/midx-bitmaps/04-what-a-bitmap-saves -->
```text
# Serve one full clone and ask the serving side how it filled the pack:
$ GIT_TRACE2_PERF=1 git clone -q --bare "file://$PWD/server/orbit.git" with-bitmap.git 2>&1 | awk -F'|' '$4 ~ /data/ {gsub(/[ .]/, "", $NF); gsub(/ /, "", $(NF-1)); print $(NF-1), $NF}' | grep -e ' written:' -e ' reused:' -e 'pack-reused:'
pack-objects written:519
pack-objects reused:0
pack-objects pack-reused:519
# Remove the bitmap and serve the same clone again:
$ rm server/orbit.git/objects/pack/*.bitmap
$ GIT_TRACE2_PERF=1 git clone -q --bare "file://$PWD/server/orbit.git" without-bitmap.git 2>&1 | awk -F'|' '$4 ~ /data/ {gsub(/[ .]/, "", $NF); gsub(/ /, "", $(NF-1)); print $(NF-1), $NF}' | grep -e ' written:' -e ' reused:' -e 'pack-reused:'
pack-objects written:519
pack-objects reused:519
pack-objects pack-reused:0
# Both clones are complete:
$ git -C with-bitmap.git rev-list --count --objects --all
519
$ git -C without-bitmap.git rev-list --count --objects --all
519
```
<!-- /snippet -->

They are identical: 519 objects each. What differs is the work on the serving side. With the bitmap, all 519 objects were `pack-reused`: copied from the existing pack as one stretch, with no per-object work. Without it, the same 519 objects were found by a walk and reused one at a time.

**[TERMINAL]** The working tree, from `scale-dimensions`.

<!-- snippet: ch26/scale-dimensions/04-fsmonitor-off -->
```text
# Neither accelerator of the working-tree scan is on by default:
$ git config get core.fsmonitor
[exit status: 1]
$ git config get core.untrackedCache
[exit status: 1]
# Asking for the status of the daemon does not start one:
$ git fsmonitor--daemon status
fsmonitor-daemon is not watching '$LAB/ch26/scale-dimensions/orbit'
[exit status: 1]
$ git version --build-options | grep feature
feature: fsmonitor--daemon
```
<!-- /snippet -->

Neither accelerator is on by default. `git fsmonitor--daemon status` exits 1 and starts nothing. The untracked cache is not demonstrated with counters either: its effect depends on directory modification times, and a transcript that depends on file ages is not reproducible.

## COMMON MISTAKES

1. Deleting the commit-graph because it is "out of date". Root cause: a stale file is a snapshot; Git reads the missing commits from the objects, so stale is slower, not wrong.
2. Expecting the commit-graph to help in a shallow clone or with grafts. Root cause: replace objects, grafts and shallow repositories turn off reading the file.
3. Enabling bitmaps on a developer clone. Root cause: bitmaps answer the server's question of what a client needs; they are optimized for server-side use.
4. Counting packs as the problem. Root cause: many packs are expected; many packs with no multi-pack-index are the sign that maintenance has not run.
5. Starting the file-system monitor in CI. Root cause: a job that runs `git status` once gains nothing from a daemon that must first be started.

## PRODUCTION EXAMPLE

The evaluation team from the hook enables changed-path filters once, with `git commit-graph write --reachable --changed-paths`, and lets maintenance keep the file current. The question "which commits changed the scoring rubric" then compares trees only for the commits whose filter says "maybe". Microsoft published the effect on the Linux and Windows repositories when the feature was introduced in Git 2.18; the numbers there are theirs, on their machines.

For the working tree, the textbook cites one published measurement: Canva reported `git status` going from 10 seconds to about 3 with the monitor, the untracked cache, scheduled maintenance and sparse checkout together. That is their measurement. These two features matter when the `lstat` and directory counters are in the hundreds of thousands.

## PRACTICE EXERCISE

Do Lab 16.4, "Write and verify a commit-graph", in [`lab-manual/m16-maintenance.md`](../../lab-manual/m16-maintenance.md). Before you write the file, predict the statistics line for the path the lab asks about: how many "maybe", how many "definitely not". Before the failure scenario, predict whether a damaged file makes Git slower or makes it fail.

The challenge is Exercise 18.6, "History without content", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 84 of the CTO question bank:

> "What two kinds of data does a commit-graph hold, and which commands does each help? What happens when the file is stale, and when it is damaged?"

A strong answer names both kinds of data with the question each one answers, and attaches commands to each. It treats "stale" and "damaged" as two different cases with two different outcomes, and gives the one-command diagnostic that takes the file out of the picture. It says what kind of data the file is, and therefore what the repair is.

## RECAP

You should now be able to say:

- The commit-graph holds generation numbers for graph walks and changed-path filters for path-limited history.
- It is a cache: stale is slower, not wrong; grafts, replace objects and shallow repositories switch it off.
- The multi-pack-index is one index over many packs.
- A bitmap tells a server what each selected commit reaches, and is written by default only in bare repositories.
- The untracked cache and the file-system monitor replace the working-tree scan of `git status` by a question.

## HOMEWORK

Read sections 26.6 to 26.9 of [Chapter 26](../../textbook/ch26-performance.md).

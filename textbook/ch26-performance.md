# Chapter 26: Performance

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch26/`. They show counts of objects, packs and work done. They show no timings, because a time measured on one machine on one day is not a fact about Git.

## 26.1 Why this matters

Four questions a CTO can ask:

1. "`git status` takes four seconds and `git log -- path` takes twenty. Is the repository broken, or too big?"
2. "CI clones 3 GB for every job. Someone proposed `--depth 1` everywhere. What breaks?"
3. "A consultant told us to put `git gc --aggressive` into a nightly cron job. Should we?"
4. "The air-gapped training cluster needs our code every week. How do we ship it, and how do we ship only what is new?"

The answers. Neither: slow commands map to specific kinds of size, and each kind has a remedy that changes no history (sections 26.2 to 26.9). History questions break, silently: versions, blame, merge bases; a partial clone is usually what was wanted (26.11 to 26.13). No: since 2.54 Git's automatic maintenance uses a strategy that avoids exactly that kind of full rewrite, and `git gc` does not even take maintenance's lock (26.3 to 26.5). As bundles, with an incremental bundle whose prerequisite names what the other side must already have (26.14).

Everything in this chapter is derived data or a way of leaving data out. A commit-graph, a multi-pack-index, a bitmap, an untracked cache can be deleted and rebuilt; a shallow or partial clone holds fewer objects, not different ones. No feature here changes a commit ID. That is why they are safe to adopt, and why a slow repository is rarely a reason to rewrite history.

The repository is `orbit` from [Chapter 24](ch24-monorepos.md): 33 files, 94 commits on `main`, a feature branch, five tags.

## 26.2 What makes a repository slow

**In one sentence.** A Git command is slow when the amount of data it must touch is large, so the diagnosis is to find which data a command touches and then to make that amount smaller or indexed.

**Precisely.** "Large" has dimensions that do not depend on each other (Chapter 24, section 24.3): tracked files, commits and trees, blob content in all versions, loose objects and packs, refs. Measure them before you tune anything:

<!-- snippet: ch26/scale-dimensions/01-dimensions -->
```text
# History: how many commits, and how many objects of each type?
$ git rev-list --count --all
96
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
# Working tree: how many tracked files does every status have to consider?
$ git ls-files | wc -l
      33
# Refs: how many names does every fetch have to advertise and compare?
$ git for-each-ref | wc -l
       7
# Storage: loose objects and packs.
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 507
in-pack: 0
packs: 0
```
<!-- /snippet -->

<!-- snippet: ch26/scale-dimensions/02-largest -->
```text
# The largest blob of each path in the whole history, five largest paths first:
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep '^blob' | sort -k2 -n -r | awk '!seen[$3]++' | head -5
blob 43334 pipelines/eval/cases.jsonl
blob 19407 libs/tokenizer/vocab.txt
blob 814 docs/architecture.md
blob 401 services/gateway/routes.py
blob 352 tools/ci/affected.py
# How many versions of the largest file does the history hold?
$ git log --oneline -- pipelines/eval/cases.jsonl | wc -l
      13
```
<!-- /snippet -->

The second pipeline is the one to remember. `git rev-list --objects --all` 🟢 lists every reachable object with a path that leads to it, and `git cat-file --batch-check` adds type and size. One 43 KB file with 13 versions is where the bytes of `orbit` are. In a real repository this list usually shows a few committed archives, datasets or generated files (Chapter 22). `git repo structure` (experimental, [Chapter 14D](ch14d-frontier.md)) and the external tool [git-sizer](https://github.com/github/git-sizer) summarise the same dimensions.

**Counting work.** To see where one command spends its effort, ask Git. `GIT_TRACE2_PERF=1` 🟢 makes any command print a table of what it did ([api-trace2](https://git-scm.com/docs/api-trace2)). Most columns are times. The rows of type `data` carry counters, and counters are reproducible:

<!-- snippet: ch26/scale-dimensions/03-status-work -->
```text
# What one "git status" does, in counted work. GIT_TRACE2_PERF prints a table; the awk
# program keeps the rows that carry a counter and drops the columns that carry times.
$ GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '$4 ~ /data/ {gsub(/[ .]/, "", $NF); gsub(/ /, "", $(NF-1)); print $(NF-1), $NF}' | grep -e read/cache_nr -e sum_lstat -e visited
index read/cache_nr:33
index refresh/sum_lstat:33
read_directo directories-visited:20
read_directo paths-visited:53
```
<!-- /snippet -->

One `git status` in a repository of 33 files read 33 index entries, made 33 `lstat` calls to compare them with the working tree, and visited 20 directories and 53 paths to look for untracked files. Scale those three numbers to 500,000 files and you have the four seconds of question 1. The remedies follow from the counters: fewer files to examine (sparse-checkout, Chapter 24), a smaller index (sparse index), or not examining at all (section 26.9). On your own machine, read the time columns too: `GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | less`.

| Slow command | What it touches | Remedy | Section |
|---|---|---|---|
| `git status`, `git add`, `git switch` | Every index entry and tracked file; every directory | Sparse-checkout, sparse index, untracked cache, file-system monitor | Chapter 24; 26.9 |
| `git log -- <path>`, `git blame` | Every commit's tree | Changed-path filters in the commit-graph | 26.6 |
| `git log --graph`, `git merge-base`, `git branch --contains` | Commit objects, one by one | Commit-graph | 26.6 |
| Any object lookup | One index per pack | Repacking, multi-pack-index | 26.3 to 26.7 |
| `git clone`, `git fetch` | Everything reachable | Partial clone; bitmaps on the server | 26.8, 26.12 |

## 26.3 `git gc` and `git maintenance`

**In one sentence.** `git gc` is one command that repacks everything and deletes what has expired, `git maintenance` runs a configurable set of smaller tasks, and since Git 2.54 the maintenance that Git starts on its own no longer runs `git gc`.

**Analogy.** `git gc` closes the warehouse for a full inventory and reshelving. `git maintenance` sends a clerk through one aisle at a time while the warehouse stays open. The analogy breaks at deletion: a full inventory is also the moment when unclaimed goods are thrown away, and the clerk's rounds postpone that moment (section 26.5).

**Precisely.** Chapter 3, section 3.7 showed what a pack is, and Chapter 13 what `git gc` deletes. `git maintenance run` 🟡 executes **tasks**. The manual lists them: `gc`, `commit-graph`, `prefetch`, `loose-objects`, `incremental-repack`, `pack-refs`, `reflog-expire`, `rerere-gc`, `worktree-prune`. Git 2.55 also accepts `geometric-repack`, which the task list of its manual page omits. Which tasks run without `--task` is decided by `maintenance.strategy`:

| Strategy | Tasks | Deletes data? | When it is the default |
|---|---|---|---|
| `geometric` | `commit-graph`, `geometric-repack`, `pack-refs`, `reflog-expire`, `rerere-gc`, `worktree-prune` | Reflog entries past their expiry; unreachable objects only at an all-into-one repack (26.5) | Manual and automatic maintenance, since Git 2.54 |
| `gc` | `gc` | Yes: what `git gc` deletes | Before Git 2.54 |
| `incremental` | Hourly `prefetch`, `commit-graph`; daily `loose-objects`, `incremental-repack`; weekly `pack-refs` | No | Set by `git maintenance register` for scheduled runs |
| `none` | None | No | Scheduled maintenance, until a strategy is configured |

The table is assembled from `git help maintenance` and, for the task lists, from [builtin/gc.c](https://github.com/git/git/blob/v2.55.0/builtin/gc.c) at the 2.55.0 tag. The manual page of 2.55 is not consistent with itself: it calls geometric "the default strategy for manual maintenance" and still says in two places that "by default, only `maintenance.gc.enabled` is true". The trace below settles it.

Maintenance runs in three ways. **Automatic:** commands that write objects finish by starting `git maintenance run --auto`, detached, and each task runs only if its threshold is met (`maintenance.auto`, default true). **Manual:** you run it. **Scheduled:** `git maintenance start` 🟡 registers the repository in your global configuration, installs entries in the system scheduler (launchd on macOS, with files in `~/Library/LaunchAgents`; cron or systemd timers on Linux) that run `git maintenance run --schedule=hourly|daily|weekly`, sets the `incremental` strategy, and sets `maintenance.auto=false` in the repository. This book does not run `start`: it writes outside the sandbox. It is described here from `git help maintenance`.

**See it.** The trigger, in a new repository:

<!-- snippet: ch26/maintenance-trace/01-trigger -->
```text
# Commands that write objects end by asking for maintenance. In a new repository:
$ git init -q probe
$ echo 'probe' > probe/file.txt && git -C probe add file.txt
$ GIT_TRACE=1 git -C probe commit -q -m 'Add a file' 2>&1 | sed -n 's/.*trace: run_command: //p'
git maintenance run --auto --quiet --detach
# In the repository we are going to study, nothing may run behind our back. Switch the trigger off:
$ cd orbit
$ git config set maintenance.auto false
```
<!-- /snippet -->

`orbit` has never been maintained: 507 loose objects. `git maintenance is-needed` (Git 2.53 or later) answers with its exit status whether an automatic run would act:

<!-- snippet: ch26/maintenance-trace/02-needed -->
```text
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 507
in-pack: 0
packs: 0
# Would an automatic run do anything? Exit status 0 means yes.
$ git maintenance is-needed --auto
[exit status: 0]
# Task by task:
$ git maintenance is-needed --auto --task=geometric-repack
[exit status: 0]
$ git maintenance is-needed --auto --task=commit-graph
[exit status: 1]
$ git maintenance is-needed --auto --task=gc
[exit status: 1]
```
<!-- /snippet -->

The repack is needed, because more than about 100 loose objects exist. The commit-graph is not (fewer than 100 commits are missing from it), and the old `gc` threshold of about 6,700 loose objects is far away. The loose count is an estimate: Git counts the files in one of the 256 object directories, `objects/17`, and multiplies ([odb/source-loose.c](https://github.com/git/git/blob/v2.55.0/odb/source-loose.c)).

<!-- snippet: ch26/maintenance-trace/03-trace -->
```text
# Run maintenance in the foreground and write the trace into a file beside the repository:
$ GIT_TRACE="$PWD/../trace-1.log" git maintenance run
# The commands that maintenance started, in order:
$ sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -v -e '^pack-objects' -e '^multi-pack-index'
pack-refs --all --prune
reflog expire --all
repack -d -l --cruft --cruft-expiration=2.weeks.ago --quiet --write-midx
commit-graph write --split --reachable --no-progress
worktree prune --expire 3.months.ago
rerere gc
# The commands that the repack started in turn (process ID and temporary file name masked):
$ sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -e '^pack-objects' -e '^multi-pack-index' | sed -e 's/tmp-[0-9]*-pack/tmp-PID-pack/' -e 's/pack-[0-9a-f]*\.pack/pack-ID.pack/' -e 's/--refs-snapshot=[^ ]*/--refs-snapshot=FILE/' | fold -s -w 100
pack-objects --local --quiet --delta-base-offset --honor-pack-keep .git/objects/pack/.tmp-PID-pack 
--keep-true-parents --non-empty --all --reflog --indexed-objects
pack-objects --local --quiet --delta-base-offset --honor-pack-keep .git/objects/pack/.tmp-PID-pack 
--cruft --cruft-expiration=2.weeks.ago --non-empty
multi-pack-index write --no-progress --preferred-pack=pack-ID.pack --refs-snapshot=FILE 
--stdin-packs
```
<!-- /snippet -->

`GIT_TRACE` 🟢 with a file name appends the trace to that file. Six commands, and no `git gc` among them. The repack line says `--cruft` with no `--geometric`, because there was no pack yet and so everything went into one. Below it, `repack` started `pack-objects` twice, once for reachable objects and once for a cruft pack that turned out empty, and then wrote a multi-pack-index.

**Inside `.git`.**

<!-- snippet: ch26/maintenance-trace/04-after -->
```text
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 507
packs: 1
# Every file under objects/ that is not a loose object (40-digit names masked):
$ find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\{40\}/ID/' | sort
.git/objects/info/commit-graphs/commit-graph-chain
.git/objects/info/commit-graphs/graph-ID.graph
.git/objects/info/packs
.git/objects/pack/multi-pack-index
.git/objects/pack/pack-ID.idx
.git/objects/pack/pack-ID.pack
.git/objects/pack/pack-ID.rev
# The refs moved into packed-refs:
$ head -3 .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
88222b7043b92ba564af0aefc4acd25af9ef15e2 refs/heads/feature/rerank-cache
100bb993157cac87afe81008782cd27cd39f8c9d refs/heads/main
$ find .git/refs -type f | wc -l
       0
$ git maintenance is-needed --auto
[exit status: 1]
```
<!-- /snippet -->

One pack with its index and reverse index, a multi-pack-index (26.7), a commit-graph stored as a chain (26.6), and every ref moved from its own file into `packed-refs` (Chapter 3, section 3.9). For comparison, the same repository maintained by the `gc` task:

<!-- snippet: ch26/maintenance-trace/07-gc-task -->
```text
# The same repository, maintained the older way:
$ GIT_TRACE="$PWD/../trace-3.log" git maintenance run --task=gc
$ sed -n 's/.*trace: run_command: git //p' ../trace-3.log | grep -v -e '^pack-objects'
pack-refs --all --prune
gc --quiet --no-detach --skip-foreground-tasks
repack -d -l -q --cruft --cruft-expiration=2.weeks.ago
prune --expire 2.weeks.ago --no-progress
worktree prune --expire 3.months.ago
rerere gc
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     611
$ find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\{40\}/ID/' | sort
.git/objects/info/commit-graph
.git/objects/info/packs
.git/objects/pack/pack-ID.idx
.git/objects/pack/pack-ID.pack
.git/objects/pack/pack-ID.rev
```
<!-- /snippet -->

Here `git gc` appears, with `git prune`, which deletes loose unreachable objects past the grace period. It leaves one pack of all 611 objects (the repository had grown by then), a single commit-graph file, and no multi-pack-index.

The tasks of the `incremental` strategy, which a scheduler would spread over hours and days, can be run by name:

<!-- snippet: ch26/maintenance-trace/08-incremental-tasks -->
```text
# The tasks of the "incremental" strategy, which a scheduler would run hourly and daily,
# run here once in the foreground (prefetch is left out: this repository has no remote):
$ GIT_TRACE="$PWD/../trace-4.log" git maintenance run --task=commit-graph --task=loose-objects --task=incremental-repack
$ sed -n 's/.*trace: run_command: git //p' ../trace-4.log
commit-graph write --split --reachable --no-progress
prune-packed --quiet
multi-pack-index write --no-progress
multi-pack-index expire --no-progress
multi-pack-index repack --no-progress --batch-size=1
```
<!-- /snippet -->

None of these deletes an object that is not stored elsewhere. `prune-packed` removes loose copies of objects that are already in a pack, and the three `multi-pack-index` steps index all packs, drop packs that have become redundant, and merge small ones. The manual describes the tasks that `register` enables as "safe for running in the background without disrupting foreground processes".

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git maintenance run` | unchanged | unchanged | unchanged | Same value, now in `packed-refs` | Loose objects packed; multi-pack-index and commit-graph chain written; reflog entries past expiry removed; `rr-cache` and stale worktree records pruned | unchanged | unchanged |
| `git maintenance run --task=gc`, `git gc` | unchanged | unchanged | unchanged | Same value, now in `packed-refs` | All packs rewritten into one; unreachable objects into a cruft pack, or deleted when past the grace period | unchanged | unchanged |

**In production.** Leave automatic maintenance on for ordinary repositories; it is the reason you rarely think about any of this. For a very large repository use `git maintenance start` on developer machines, which is what `scalar` does, and know what it installs (Chapter 24, section 24.7). Do not put `git gc` into cron next to it: the manual says "`git gc` modifies the object database but does not take the lock in the same way as `git maintenance run`. If possible, use `git maintenance run --task=gc` instead of `git gc`." And question 3: `--aggressive` discards all existing deltas and recomputes them. The manual's own verdict is that it is "probably not worth it" without benchmarks for your repository.

## 26.4 Geometric repacking

**In one sentence.** Geometric repacking keeps packs in a sequence where each is at least twice as large as the next, by merging only the small ones, so that regular maintenance never rewrites the large pack.

**Precisely.** `git repack --geometric=<factor>` 🟡 "determines a 'cut' of packfiles that need to be repacked into one in order to ensure a geometric progression", leaving as many of the larger packs intact as possible (`git help repack`). Size is counted in objects. The cost of a run is then proportional to the new data, not to the repository. `git gc` and `git repack -a` rewrite everything every time, and on a large repository that difference decides whether maintenance can run daily.

**See it.** Six commits later, the second run uses the geometric mode:

<!-- snippet: ch26/maintenance-trace/05-second-run -->
```text
# Six more commits, then a second run:
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 24
in-pack: 507
packs: 1
$ GIT_TRACE="$PWD/../trace-2.log" git maintenance run
$ sed -n 's/.*trace: run_command: git //p' ../trace-2.log | grep -v -e '^pack-objects' -e '^multi-pack-index'
pack-refs --all --prune
reflog expire --all
repack -d -l --geometric=2 --quiet --write-midx
commit-graph write --split --reachable --no-progress
worktree prune --expire 3.months.ago
rerere gc
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 531
packs: 2
```
<!-- /snippet -->

<!-- snippet: ch26/maintenance-trace/06-progression -->
```text
# Objects per pack, largest first:
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
      24
# Six more commits and a third run. The new pack is not rolled into the old small one yet:
$ git maintenance run
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
      24
      24
# Fourteen more commits and a fourth run. Now the two small packs and the new objects merge:
$ git maintenance run
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
     104
# The commit-graph grew as a chain of files, one line per file:
$ wc -l < .git/objects/info/commit-graphs/commit-graph-chain
       2
```
<!-- /snippet -->

After the second run: 507 and 24. After the third: 507, 24 and 24. The split is computed over the packs that exist, 507 and 24, which are in progression, so nothing is merged and the new loose objects become a pack of their own. At the fourth run the existing packs are 507, 24 and 24; the two small ones break the rule, so they merge with the new objects into one pack of 104, and 507 is at least twice 104. The large pack was never touched.

**Picture.**

```text
  run 2:  [ 507 ]  [ 24 ]                        new loose objects become a pack
  run 3:  [ 507 ]  [ 24 ]  [ 24 ]                507 >= 2 x 24: nothing existing is merged
  run 4:  [ 507 ]  [     104     ]               24 < 2 x 24: the small packs and 56 new objects merge
           never rewritten
```

**In production.** GitHub described the move to geometric repacking on its servers in 2021, with the multi-pack-index and bitmaps that make many packs cheap to read ([Scaling monorepo maintenance](https://github.blog/open-source/git/scaling-monorepo-maintenance/)). On your side the consequence is that several packs are the normal state of a healthy repository. A count of packs is not a problem to fix; a count in the hundreds with no multi-pack-index is (26.16).

## 26.5 Cruft packs

**In one sentence.** A cruft pack is a pack that holds only unreachable objects, with a companion file recording when each was last touched, so that garbage can wait out its grace period without becoming thousands of loose files.

**Precisely.** Chapter 13, section 13.13 covered the retention rules and the destructive pair of commands. The storage side is new here. Unreachable objects must be kept for a grace period (`gc.pruneExpire`, two weeks), because a running command may be about to reference them. A cruft pack stores them together with a `.mtimes` file of per-object timestamps (`git help gitformat-pack`, "Cruft packs"). Under the geometric strategy a cruft pack is written only when the repack is all-into-one; an ordinary geometric run does not look at reachability at all.

**See it.** Start from one pack, delete an unmerged branch and expire the reflogs:

<!-- snippet: ch26/cruft-packs/01-make-garbage -->
```text
# One pack, everything reachable:
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
$ git fsck --unreachable --no-reflogs | wc -l
       0
# Delete the unmerged feature branch. Its two commits were made on that branch, so its reflog
# went with it, but the HEAD reflog still names them:
$ git branch -D feature/rerank-cache
Deleted branch feature/rerank-cache (was 88222b7).
$ git fsck --unreachable | wc -l
       0
# Remove that protection too (Chapter 13). Now the objects are unreachable:
$ git reflog expire --expire=now --all
$ git fsck --unreachable | sort
unreachable blob 0aced5d065592ae1a158a66931131e377b97dbbe
unreachable blob c2cf087c511ab0c6fbcf5667654692ea854df5ff
unreachable commit 88222b7043b92ba564af0aefc4acd25af9ef15e2
unreachable commit 9c9fd21b4c3b6d3699faf92edca795c05502285d
unreachable tree 1daf6eb53180a27301435609d474f8052dc5e3aa
unreachable tree 251b5335442f8401b0fc4c2dd70755de905d2062
unreachable tree 57751408afbae309db0f6d6cbee79823581a949c
unreachable tree 5a983380960468216ce59f604efbd7fe29996b8a
unreachable tree dfdea423ad6498c15fc99a910f4fcaa4729fdebf
unreachable tree fe9a2ed70859ef92d48e7dfb7d4d5a302c977f1e
```
<!-- /snippet -->

<!-- snippet: ch26/cruft-packs/02-geometric-keeps -->
```text
# One new commit, then a maintenance run of the default strategy. It packs the new loose
# objects and deletes nothing:
$ printf '\nSee docs/runbooks for the on-call procedures.\n' >> README.md
$ git commit -q -am 'readme: point to the runbooks'
$ git maintenance run
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     507
       3
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   2 idx
   1 multi-pack-index
   2 pack
   2 rev
$ git fsck --unreachable | wc -l
      10
```
<!-- /snippet -->

The default strategy packed three new objects and left the ten unreachable ones where they were: inside the large pack, which a geometric run does not rewrite.

<!-- snippet: ch26/cruft-packs/03-gc-cruft -->
```text
# The gc task repacks everything into one pack and separates the unreachable objects:
$ git maintenance run --task=gc
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     500
      10
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   2 idx
   1 mtimes
   2 pack
   2 rev
# The pack that has an .mtimes file is the cruft pack. Its objects are still readable:
$ git cat-file -t 88222b7
commit
$ git log --oneline -2 88222b7
88222b7 ranker: make the cache size configurable
9c9fd21 ranker: cache scores per query and document
```
<!-- /snippet -->

The `gc` task separates them: 498 reachable objects in one pack, ten in a cruft pack with its `.mtimes` file. The deleted branch is still readable by ID.

<!-- snippet: ch26/cruft-packs/04-prune -->
```text
# The cruft pack waits for the grace period (two weeks by default). With no grace period:
$ git gc --prune=now
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 idx
   1 pack
   1 rev
$ git cat-file -t 88222b7
fatal: Not a valid object name 88222b7
[exit status: 128]
$ git fsck --unreachable | wc -l
       0
```
<!-- /snippet -->

`git gc --prune=now` 🔴 ends the grace period (Chapter 13 gives the five facts for this command). The transcript uses `now` because a cut-off that depends on the clock could not be reproduced.

**In production.** Two consequences. A repository under the default strategy can hold unreachable objects for a long time, which matters after a secret has been removed from history: rewriting and force-pushing does not delete the objects from your clone, and the purge is the deliberate procedure of [Chapter 21B](ch21b-repository-security-incident-response.md). And `count-objects` no longer shows garbage as loose files, so "the repository is large although the history is small" is diagnosed with `git fsck --unreachable | wc -l` and by looking for `.mtimes` files.

## 26.6 The commit-graph

**In one sentence.** The commit-graph is a file that stores, for every commit, its parents, its root tree, its date and its distance from the roots of history, and optionally a compact summary of the paths it changed, so that history walks stop decompressing commit objects and stop comparing trees that did not change.

**Analogy.** A railway timetable printed from the day's train records. Asking the timetable is faster than reading the records, and it is wrong the moment the records change without a reprint. The analogy breaks in Git's favour: Git notices commits that are missing from the file and reads those from the objects, so a stale commit-graph is slower, not wrong. A damaged one is another matter (Lab 16.4).

**Precisely.** Two things are stored ([commit-graph design](https://github.com/git/git/blob/v2.55.0/Documentation/technical/commit-graph.adoc); [Git's database internals II](https://github.blog/open-source/git/gits-database-internals-ii-commit-history-queries/) and [III](https://github.blog/open-source/git/gits-database-internals-iii-file-history-queries/)):

- **The graph with generation numbers.** A commit's generation is larger than that of every ancestor. A walk that asks "is A an ancestor of B" can stop as soon as it reaches commits whose generation is below A's, instead of walking to the root. This is what `git merge-base`, `git branch --contains`, `git tag --contains` and `git log --graph` gain from.
- **Changed-path Bloom filters** (`--changed-paths`). For each commit, a small probabilistic set of the paths that differ from its first parent. Asked "did this commit touch `services/ranker`?", a filter answers "definitely not" or "maybe". Only the "maybe" commits need their trees compared. This is what `git log -- <path>` and `git blame` gain from.

`git commit-graph write --reachable --changed-paths` 🟢 writes the file for all commits reachable from refs; `git commit-graph verify` 🟢 checks it against the object database. `git gc` writes one (`gc.writeCommitGraph`, default true), the `commit-graph` maintenance task writes one incrementally, and `fetch.writeCommitGraph` does it after fetches. Filters are written only if requested once, or with `commitGraph.changedPaths=true` (Git 2.52 or later).

**See it.**

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

Without the file, `git log -- services/ranker` compares the tree of each of the 94 commits with its parent's to find the 13 that changed the path.

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

**Inside `.git`.** One file, `objects/info/commit-graph`. Its header is the signature `CGPH`, and the chunk table that follows names the parts: `OIDF` and `OIDL` (the commit IDs, sorted, with a fan-out table), `CDAT` (tree, parents, generation and date per commit), `GDA2` (generation data), `BIDX` and `BDAT` (the Bloom filters) ([gitformat-commit-graph](https://git-scm.com/docs/gitformat-commit-graph)).

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

The statistics come from Git itself. For `services/ranker`, 81 of 94 commits were dismissed by their filter without a tree comparison and 13 said "maybe"; all 13 were real, so `false_positive` is 0. For `libs/schemas`, 92 were dismissed. The answer did not change, and the work fell from 94 comparisons to 13 and to 2. That ratio, not a stopwatch, is why the feature matters: in a monorepo most commits do not touch any given path.

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

A new commit does not invalidate the file. With `--split`, the form maintenance uses, a small file is added on top and `commit-graph-chain` lists the layers; layers are merged when the upper one grows large relative to the one below (`git help commit-graph`).

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

The manual's caveat, observed: "The existence of replace objects or commit grafts turns off reading or writing to the commit-graph." The same holds in a shallow repository, as section 26.11 shows. `core.commitGraph=false` bypasses the file for one command, which is the diagnostic to remember.

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit-graph write --reachable --changed-paths` | unchanged | unchanged | unchanged | unchanged | `objects/info/commit-graph` written, or a layer under `objects/info/commit-graphs/` with `--split` | unchanged | unchanged |

**In production.** An evaluation team asks "which commits changed the scoring rubric" many times a day. On a repository with a long history that question is the twenty seconds of section 26.1, and changed-path filters are the fix. Microsoft published the effect on the Linux and Windows repositories when the feature was introduced in Git 2.18 ([Supercharging the Git Commit Graph](https://devblogs.microsoft.com/devops/supercharging-the-git-commit-graph/)); the numbers there are theirs, on their machines.

## 26.7 The multi-pack-index

**In one sentence.** The multi-pack-index is one sorted index over the objects of many packs, so that finding an object costs one lookup however many packs there are.

**Precisely.** Each pack has its own `.idx` (Chapter 3, section 3.7). With N packs, a lookup may search N indexes. Geometric repacking, fetches and partial clones all produce many packs on purpose, so the cost has to be removed elsewhere: `objects/pack/multi-pack-index` maps every object ID to a pack and an offset ([git-multi-pack-index](https://git-scm.com/docs/git-multi-pack-index)). Git reads it when `core.multiPackIndex` is true, the default.

**See it.** A clone that has fetched three times with `fetch.unpackLimit=1`, the setting `scalar` uses so that every fetch keeps its pack:

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

`git multi-pack-index write` 🟢 created one file; the last byte of the header shown says four packs. Nothing else changed, and nothing you can observe through Git changed. Maintenance writes this file as part of its repack (`--write-midx` in the trace of 26.3), and the `incremental-repack` task uses it to merge small packs without a full rewrite.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git multi-pack-index write` | unchanged | unchanged | unchanged | unchanged | `objects/pack/multi-pack-index` written; packs untouched | unchanged | unchanged |

**In production.** You do not run this command by hand. You recognise the file, you know it is derived data that `git multi-pack-index verify` checks, and you know that many packs without it are a sign that maintenance has not run (26.16).

## 26.8 Reachability bitmaps

**In one sentence.** A bitmap file stores, for selected commits, one bit per object in the pack saying whether that commit reaches it, so that a server can answer "which objects does this client need" without walking the graph.

**Precisely.** Serving a clone or fetch starts with "enumerating objects": everything reachable from the wanted commits minus everything reachable from the ones the client has. A walk does that commit by commit and tree by tree. With bitmaps it is a few bitwise operations, and stretches of the existing pack can be copied to the client verbatim ([bitmap-format](https://git-scm.com/docs/bitmap-format); [Git's database internals IV](https://github.blog/open-source/git/gits-database-internals-iv-distributed-synchronization/)). `repack.writeBitmaps` "defaults to true on bare repos, false otherwise": bitmaps are a server feature. `scalar` sets `pack.useBitmaps=false` on clients, with the reason that bitmaps "are optimized for server-side use, not client-side use".

**See it.**

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

The same `git gc`, and only the bare repository got a `.bitmap`. Now serve one clone from it and read the counters that `git pack-objects` on the serving side reports:

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

With the bitmap, all 519 objects were `pack-reused`: copied from the existing pack as one stretch, with no per-object work. Without it, the same 519 objects were found by a walk and reused one at a time. The clones are identical.

**In production.** This is the hosting provider's concern, and yours if you run a Git server or a mirror for CI: a bare repository that is repacked as a whole gets its bitmap without further configuration. As a user you meet the feature in the first phase of a clone, which the configuration manual calls "counting objects": that is the phase a bitmap shortens.

## 26.9 The working tree: untracked cache and file-system monitor

**In one sentence.** The untracked cache remembers which directories contained no untracked files, the file-system monitor tells Git which paths changed since the last command, and together they replace the scan of the working tree by a question.

**Precisely.** Section 26.2 counted two kinds of work in `git status`: an `lstat` call per tracked file, and a walk of every directory in search of untracked files.

- **Untracked cache** (`core.untrackedCache`). The index records the modification time of each directory; a directory whose time has not changed is not read again. It depends on the file system updating directory times, which `git update-index --test-untracked-cache` checks. The default is `keep`; `feature.manyFiles=true` and `scalar` switch it on.
- **File-system monitor** (`core.fsmonitor=true`). A daemon, `git fsmonitor--daemon`, subscribes to the operating system's change notifications for one working tree. `git status` asks it for the changed paths and calls `lstat` only on those. With the configuration set, "commands, such as `git status`, will ask the daemon for changes and automatically start it (if necessary)" (`git help fsmonitor--daemon`). The manual lists caveats: it does not know about submodules, and it refuses network-mounted repositories by default.

**See it.** This book starts no daemon, so the transcript shows only that both are off by default and how to ask:

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

`git fsmonitor--daemon status` 🟢 exits 1 and starts nothing. The untracked cache is not demonstrated with counters either: its effect depends on directory modification times, and a transcript that depends on file ages is not reproducible.

> **Unverified.** The first release with a working built-in daemon: the manual page exists at the 2.36.0 tag, and a GitHub engineering post dates the feature to Git 2.37 ([GitHub Blog](https://github.blog/engineering/infrastructure/improve-git-monorepo-performance-with-a-file-system-monitor/)). Git 2.55 added the daemon on Linux according to its release notes, while the configuration manual of 2.55 still names only Windows and macOS.

**In production.** These two matter when `sum_lstat` and `directories-visited` are in the hundreds of thousands. Canva reported `git status` going from 10 seconds to about 3 with the monitor, the untracked cache, scheduled maintenance and sparse checkout together (their measurement; article linked in Chapter 24). Both features belong to developer machines. A CI job that runs `git status` once gains nothing from a daemon that must first be started.

## 26.10 The fetch conversation

**In one sentence.** A fetch is a short dialogue in which the server advertises what it has, the client says what it wants and what it already has, and the server answers with one pack of the difference.

**Precisely.** Chapter 12, section 12.13 printed a whole trace. Four steps are enough to reason about every clone shape in this chapter ([gitprotocol-v2](https://git-scm.com/docs/gitprotocol-v2)):

1. **Advertise.** The server names the protocol version and its capabilities. The client asks for refs with `ls-refs`.
2. **Want.** The client names the tips it wants.
3. **Have.** The client names commits it has; the server acknowledges those it knows. This negotiation finds the common boundary, and `fetch.negotiationAlgorithm` controls how the client picks what to offer.
4. **Pack.** The server enumerates the objects on its side of the boundary (26.8) and sends them as one packfile.

**See it.**

<!-- snippet: ch26/fetch-conversation/01-capabilities -->
```text
# What the serving side says it can do for a fetch:
$ GIT_TRACE_PACKET=1 git ls-remote "file://$PWD/server/orbit.git" HEAD 2>&1 | sed -n 's/.*packet: *ls-remote< //p' | sed -n '1,/^0000/p'
version 2
agent=git/2.55.0-Darwin
ls-refs=unborn
fetch=shallow wait-for-done filter
server-option
object-format=sha1
0000
```
<!-- /snippet -->

The line `fetch=shallow wait-for-done filter` is the server saying which extras its `fetch` command supports. `filter` appears only because the lab server sets `uploadpack.allowFilter`.

<!-- snippet: ch26/fetch-conversation/02-full-clone -->
```text
# A full clone, with the conversation written to a file beside it:
$ GIT_TRACE_PACKET="$PWD/full.trace" git clone -q "file://$PWD/server/orbit.git" full
# The request names one tip per ref it wants, has nothing to offer, and says so:
$ sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,$p' | grep -c '^want'
8
$ sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,$p' | grep -c '^have'
0
$ sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,$p' | grep -v -e '^want' | tr '\n' ' '
command=fetch agent=git/2.55.0-Darwin object-format=sha1 0001 thin-pack no-progress ofs-delta done 0000 
# The answer is one section, the pack:
$ sed -n 's/.*packet: *clone< //p' full.trace | grep -e acknowledgments -e shallow-info -e packfile
packfile
```
<!-- /snippet -->

<!-- snippet: ch26/fetch-conversation/03-shallow-and-partial -->
```text
# A shallow clone adds one line to the request, and the answer starts with the boundary:
$ GIT_TRACE_PACKET=1 git clone --depth 1 "file://$PWD/server/orbit.git" shallow 2>&1 | sed -n 's/.*packet: *\(clone[<>]\)/\1/p' | grep -e deepen -e shallow
clone< fetch=shallow wait-for-done filter
clone> deepen 1
clone< shallow-info
clone< shallow 100bb993157cac87afe81008782cd27cd39f8c9d
# A partial clone adds one line as well:
$ GIT_TRACE_PACKET=1 git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless 2>&1 | sed -n 's/.*packet: *\(clone[<>]\)/\1/p' | grep -e 'filter '
clone> filter blob:none
```
<!-- /snippet -->

A clone has nothing to offer, so it sends wants and `done`. Each special clone is one more line in that request. `deepen 1` makes the server stop after one commit per tip, and the answer begins with a `shallow-info` section naming the commits where history was cut. `filter blob:none` makes the server leave out objects the filter rejects. Both are decisions of the server's enumeration; the client receives an ordinary pack either way.

<!-- snippet: ch26/fetch-conversation/04-incremental -->
```text
# Later, the server has two new commits. The client names what it wants and what it has:
$ cd full
$ GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\(fetch[<>]\)/\1/p' | sed -n '/command=fetch/,$p' | grep -e want -e have -e done -e ACK -e ready -e packfile | cut -c1-60
fetch> want 9ea7ebd6450f44a34cc11c227de15f7d2837a510
fetch> have 100bb993157cac87afe81008782cd27cd39f8c9d
fetch> have 88222b7043b92ba564af0aefc4acd25af9ef15e2
fetch> have f5915c95c140a7bfddf0cc4b9da258aa5bebe3a2
fetch> have 52ee19bf6e6ff1d7594abe2f2ecc1ac5523a2061
fetch> have 153c8285ef8f669100822c87e96585b181a79b09
fetch< ACK 100bb993157cac87afe81008782cd27cd39f8c9d
fetch< ACK 88222b7043b92ba564af0aefc4acd25af9ef15e2
fetch< ACK f5915c95c140a7bfddf0cc4b9da258aa5bebe3a2
fetch< ACK 52ee19bf6e6ff1d7594abe2f2ecc1ac5523a2061
fetch< ACK 153c8285ef8f669100822c87e96585b181a79b09
fetch< ready
fetch< packfile
$ git log --oneline -3 origin/main
9ea7ebd docs: add note 2
12adbc3 docs: add note 1
100bb99 schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

An ordinary fetch names one wanted tip and offers the tips it has; the server acknowledges them, says `ready`, and sends a pack of the two new commits with their trees and blobs.

**In production.** When a fetch is slow, this model tells you where to look: a long wait before any progress is the server enumerating (bitmaps, 26.8); a long transfer is the pack (blob content, 26.2); a long pause after the transfer is the client indexing the pack and running maintenance. `GIT_TRACE_PACKET=1` and `GIT_TRACE2_PERF=1` separate the three ([Chapter 29](ch29-production-troubleshooting.md)).

## 26.11 Shallow clones and their limits

**In one sentence.** A shallow clone contains the commits within a given distance of the requested tips and a file that tells Git to pretend the history ends there.

**Analogy.** The last page of a ledger, photocopied. It is enough to see today's balance and useless for an audit, and if you forget that it is a photocopy of one page you will conclude that the business started yesterday. The analogy breaks in one direction: unlike a photocopy, a shallow clone can be deepened later.

**Precisely.** `git clone --depth <n>` 🟢 sends `deepen <n>`. The server sends the commits within that distance with their complete trees and blobs. The client writes the IDs of the boundary commits into `$GIT_DIR/shallow`, and Git treats those commits as if they had no parents ([shallow](https://git-scm.com/docs/shallow)). `--depth` implies `--single-branch` unless `--no-single-branch` is given, and tags that point behind the boundary do not arrive. Related options: `--shallow-since=<date>` and `--shallow-exclude=<ref>` on clone and fetch, `git fetch --deepen=<n>`, `git fetch --unshallow`.

**See it.**

<!-- snippet: ch26/clone-shapes/03-shallow -->
```text
$ git clone --depth 1 "file://$PWD/server/orbit.git" shallow
Cloning into 'shallow'...
$ git -C shallow cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
  33 blob
   1 commit
   1 tag
  20 tree
$ git -C shallow log --oneline
100bb99 schemas, gateway, ingest: add the tenant field in one change
$ git -C shallow tag -l | wc -l
       1
```
<!-- /snippet -->

One commit, its 20 trees and 33 blobs: one complete snapshot.

**Inside `.git`.**

<!-- snippet: ch26/shallow-limits/01-inside -->
```text
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
100bb993157cac87afe81008782cd27cd39f8c9d
# The commit object is unchanged and still names its parent. Git has been told to stop there:
$ git cat-file -p HEAD | sed -n 1,2p
tree f2e47b39bb31b7f1afa42bfb51fa6919b4aa3842
parent d259a34f3117e4516fb2f7c071b2dd9c8edc9e5b
$ git log --format='%h parents:[%p] %s'
100bb99 parents:[] schemas, gateway, ingest: add the tenant field in one change
$ git cat-file -t HEAD~1
fatal: Not a valid object name HEAD~1
[exit status: 128]
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
```
<!-- /snippet -->

The commit object still names its parent `d259a34`. An object cannot be altered without changing its ID. What changed is Git's reading: the ID in `.git/shallow` makes every walk stop there, `%p` prints no parent, and `HEAD~1` does not resolve.

<!-- snippet: ch26/shallow-limits/02-wrong-answers -->
```text
# Questions about history get short or wrong answers, without a warning:
$ git rev-list --count HEAD
1
$ git log --oneline -- services/ranker | wc -l
       1
$ git blame -s services/gateway/routes.py | sed -n 1,3p
^100bb99  1) ROUTES = [
^100bb99  2)     ("GET", "/healthz"),
^100bb99  3)     ("POST", "/v1/search/1"),
$ git shortlog -sn HEAD
     1	Lab User
$ git describe --match 'gateway/v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
# A commit-graph cannot be written while the history is cut off. Git says nothing:
$ git commit-graph write --reachable
[exit status: 0]
$ ls .git/objects/info
[exit status: 0]
```
<!-- /snippet -->

This is the danger. Every command exits with status 0 and a plausible answer: one commit in history, one commit that ever touched the ranker, every line of the file blamed on the boundary commit (the `^` marks it), one author. Only `git describe` fails loudly, because the gateway tags lie behind the boundary. And `git commit-graph write` writes nothing, without a message.

```text
Observed behavior : a version string, a changelog or a "who changed this" report produced in CI is
                    wrong or empty, while the same command on a laptop is right.
Git state         : "git rev-parse --is-shallow-repository" prints true; .git/shallow exists.
Mechanism         : history walks stop at the boundary commits and report what they saw.
Root cause        : the job needed history and was given a snapshot.
Why Git does this : a shallow repository is defined as complete up to its boundary. Git cannot know
                    that your question reaches further.
Correct fix       : "git fetch --unshallow", or enough depth plus tags; or a blobless clone.
Prevention        : shallow clones only where the job reads one snapshot and is thrown away.
```

<!-- snippet: ch26/shallow-limits/03-deepen -->
```text
$ git fetch --deepen=5
$ git rev-list --count HEAD
6
$ cat .git/shallow
8d17b5e4d7bcbb52ee1b37a94a03d6704394b4db
$ git log --oneline -- services/ranker | wc -l
       1
```
<!-- /snippet -->

<!-- snippet: ch26/shallow-limits/04-unshallow -->
```text
$ git fetch --unshallow
From file://$LAB/ch26/shallow-limits/server/orbit
 * [new tag]         gateway/v1.0.0 -> gateway/v1.0.0
 * [new tag]         gateway/v1.1.0 -> gateway/v1.1.0
 * [new tag]         ranker/v0.9.0 -> ranker/v0.9.0
 * [new tag]         schemas/v1.0.0 -> schemas/v1.0.0
$ git rev-parse --is-shallow-repository
false
$ ls .git/shallow
ls: .git/shallow: No such file or directory
[exit status: 1]
$ git rev-list --count HEAD
94
$ git describe --match 'gateway/v*'
gateway/v1.1.0-28-g100bb99
# The refspec is still the narrow one that --depth implied (Chapter 12, section 12.12):
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

`--deepen=5` moved the boundary five commits back; `--unshallow` 🟢 removed it and brought the tags. The refspec stays narrow: the clone still follows `main` only (Chapter 12, section 12.12 widens it).

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clone --depth <n> <url>` | Full checkout of the tip | Full | The cloned branch | Created | Objects of `n` commits per tip; `.git/shallow`; a refspec for one branch | unchanged | unchanged |
| `git fetch --deepen=<n>`, `--unshallow` | unchanged | unchanged | unchanged | unchanged | Older commits added; `.git/shallow` rewritten or removed; tags that became reachable created | Read only | unchanged |

**In production.** GitHub's own guidance is that shallow clones belong in builds that are thrown away, because later fetches into a shallow repository are expensive for the server and history commands break ([GitHub Blog](https://github.blog/open-source/git/get-up-to-speed-with-partial-clone-and-shallow-clone/)). `actions/checkout` produces a shallow, tagless clone by default (Chapter 24, section 24.9). If a repository must not be cloned from a shallow source, `git clone --reject-shallow` and `clone.rejectShallow` refuse it.

## 26.12 Partial clone and promisor remotes

**In one sentence.** A partial clone has all of the history's structure and leaves out objects of a chosen kind, which a designated remote has promised to deliver when a command needs them.

**Analogy.** A book whose footnotes are kept at the publisher. The text is complete, every footnote number is there, and when you look one up it is sent to you and stays in your copy. Read offline, the footnotes you never looked up are unavailable. The analogy breaks at who looks things up: here it is any Git command, without asking you.

**Precisely.** `git clone --filter=<spec>` 🟢 sends `filter <spec>` (`git help rev-list` lists the forms):

- `blob:none`, **blobless**: all commits and trees, no blobs except those the checkout needs.
- `tree:0`, **treeless**: all commits, no trees or blobs except those the checkout needs.
- `blob:limit=<n>`: omit blobs of at least that size.

The clone records `remote.<name>.promisor=true` and `remote.<name>.partialclonefilter`. Packs from that remote get a `.promisor` file beside them, and an object that is missing but referenced from such a pack counts as promised, not as corruption ([partial-clone](https://git-scm.com/docs/partial-clone)). When a command needs a missing object, Git fetches it from the promisor remote.

**See it.**

<!-- snippet: ch26/clone-shapes/04-blobless -->
```text
$ git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless
Cloning into 'blobless'...
$ git -C blobless cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
  33 blob
  96 commit
   5 tag
 284 tree
$ git -C blobless rev-list --count --all
96
$ git -C blobless ls-files | wc -l
      33
```
<!-- /snippet -->

All 96 commits, all 284 trees, and 33 blobs: the files of the checkout. `git cat-file` warns that it lists only what is local.

**Inside `.git`.**

<!-- snippet: ch26/partial-clone/01-promisor -->
```text
$ git config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"
remote.origin.promisor true
remote.origin.partialclonefilter blob:none
# Two packs arrived: commits and trees at clone time, then the blobs of the checkout.
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   2 idx
   2 pack
   2 promisor
   2 rev
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     385
      33
# Objects that the history refers to and this repository does not hold:
$ git rev-list --objects --all --missing=print | grep -c '^?'
89
# Git does not call that damage:
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

89 objects that the history refers to are absent, and `git fsck` exits 0.

<!-- snippet: ch26/partial-clone/02-on-demand -->
```text
# A command that needs an old version of a file fetches it, without being asked:
$ GIT_TRACE=1 git show HEAD~20:services/ranker/features.py 2>&1 >/dev/null | sed -n 's/.*trace: run_command: git //p' | grep -v -e '^pack-objects' -e '^index-pack' -e '^maintenance'
-c fetch.negotiationAlgorithm=noop fetch origin --no-tags --no-write-fetch-head --recurse-submodules=no --filter=blob:none --stdin
$ ls .git/objects/pack/*.pack | wc -l
       3
# Commands that only read commits and trees fetch nothing:
$ git log --oneline -- services/ranker | wc -l
      13
$ git diff --name-status HEAD~10 HEAD -- services | wc -l
       5
$ ls .git/objects/pack/*.pack | wc -l
       3
# Counting changed lines needs file contents. Git asks for all of them in one request:
$ GIT_TRACE=1 git diff --stat HEAD~10 HEAD -- services 2>&1 | grep -c 'run_command: git .*fetch'
1
$ ls .git/objects/pack/*.pack | wc -l
       4
```
<!-- /snippet -->

`git show` of an old version triggered a `git fetch` for one object, with negotiation switched off (`noop`). Commands that read only commits and trees (`git log -- <path>`, `git diff --name-status`, `git merge-base`) fetched nothing. `git diff --stat` needed contents and fetched them in one request.

<!-- snippet: ch26/partial-clone/03-one-by-one -->
```text
# A patch needs both versions of the file for every commit shown: one request per commit.
$ GIT_TRACE=1 git log -p --format=%s -- services/ingest/settings.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
11
# Blame walks one version at a time as well:
$ GIT_TRACE=1 git blame pipelines/training/config.yaml 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
12
$ ls .git/objects/pack/*.pack | wc -l
      27
$ git rev-list --objects --all --missing=print | grep -c '^?'
60
```
<!-- /snippet -->

This is the cost. `git log -p` on one file made 11 separate requests and `git blame` made 12, each a round trip to the server, and the repository now holds 27 packs. The manual of `git backfill` describes it in the same terms: such commands "become very slow as they download the missing blobs in single-blob requests".

<!-- snippet: ch26/partial-clone/04-backfill -->
```text
# git backfill (experimental) asks for the missing blobs of the current branch in batches:
$ GIT_TRACE=1 git backfill 2>&1 | grep -c 'run_command: git .*fetch'
1
$ git rev-list --objects --all --missing=print | grep -c '^?'
2
# What is still missing belongs to another branch:
$ git rev-list --objects HEAD --missing=print | grep -c '^?'
0
$ ls .git/objects/pack/*.pack | wc -l
      28
```
<!-- /snippet -->

<!-- snippet: ch26/partial-clone/05-consolidate -->
```text
# Many small packs are the price of on-demand fetching. Maintenance merges them:
$ git maintenance run
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 idx
   1 multi-pack-index
   1 pack
   1 promisor
   1 rev
```
<!-- /snippet -->

`git backfill` 🟢 (experimental, Git 2.49 or later) fetched everything reachable from `HEAD` in one batch, grouped by path; the two objects still missing belong to the other branch. Maintenance then merged 28 packs into one promisor pack.

**When the promise cannot be kept.**

<!-- snippet: ch26/partial-clone/06-offline -->
```text
# A second blobless clone, and the server becomes unreachable:
$ cd ..
$ git clone -q --filter=blob:none "file://$PWD/server/orbit.git" laptop
$ mv server server-offline
$ cd laptop
# What is local still works:
$ git log --oneline -2
100bb99 schemas, gateway, ingest: add the tenant field in one change
d259a34 docs: record architecture change 12
$ git status --short --branch
## main...origin/main
# What needs a missing blob does not:
$ git show HEAD~20:services/ranker/features.py
fatal: '$LAB/ch26/partial-clone/server/orbit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch 3b82e45dc30fa47e6f6aa66193090e2b590f7da5 from promisor remote
[exit status: 128]
$ git switch feature/rerank-cache
fatal: '$LAB/ch26/partial-clone/server/orbit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch 03ada008385944bed720efa38fd6346db17f4169 from promisor remote
[exit status: 128]
$ git status --short --branch
## main...origin/main
$ mv ../server-offline ../server
$ git switch feature/rerank-cache
Switched to a new branch 'feature/rerank-cache'
branch 'feature/rerank-cache' set up to track 'origin/feature/rerank-cache'.
```
<!-- /snippet -->

Without the server, everything local works and anything that needs a missing blob fails with `could not fetch ... from promisor remote`. `git switch` failed before touching the working tree: `git status` afterwards still shows `main`, clean.

**A filter that is silently not applied.**

<!-- snippet: ch26/clone-shapes/06-filter-ignored -->
```text
# A path instead of a URL: the local transport copies files and ignores the filter.
$ git clone --filter=blob:none server/orbit.git by-path
Cloning into 'by-path'...
warning: --filter is ignored in local clones; use file:// instead.
done.
$ git -C by-path cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
# A server that does not allow filters (uploadpack.allowFilter is false unless set):
$ git -C server/orbit.git config set uploadpack.allowFilter false
$ git clone --filter=blob:none "file://$PWD/server/orbit.git" refused
Cloning into 'refused'...
warning: filtering not recognized by server, ignoring
$ git -C refused cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
# Both clones are complete, and both are nevertheless configured as partial clones:
$ git -C refused config get remote.origin.partialclonefilter
blob:none
$ git -C server/orbit.git config set uploadpack.allowFilter true
```
<!-- /snippet -->

Two traps. A local path makes `git clone` copy files, so the filter is ignored; use a `file://` URL. And a server without `uploadpack.allowFilter` ignores the filter. In both cases you get a warning, a complete clone, and a repository that is still configured as partial.

**Treeless.**

<!-- snippet: ch26/clone-shapes/05-treeless -->
```text
$ git clone --filter=tree:0 "file://$PWD/server/orbit.git" treeless
Cloning into 'treeless'...
$ git -C treeless cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
  33 blob
  96 commit
   5 tag
  20 tree
$ git -C treeless rev-list --count --all
96
# A path-limited log needs the trees of every commit, and asks for them one commit at a time:
$ GIT_TRACE=1 git -C treeless log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
93
$ ls treeless/.git/objects/pack/*.pack | wc -l
      96
```
<!-- /snippet -->

Only the 20 trees of the checkout are present, so a walk that looks at paths must fetch trees: one `git log -- services/ranker` sent 93 requests and left 96 packs behind. The GitHub post cited in 26.11 recommends blobless clones for developers and treeless clones only for builds that need the commit history and nothing else.

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clone --filter=blob:none <url>` | Full checkout | Full | Default branch | Created | Promisor configuration; `.promisor` packs; blobs outside the checkout absent | unchanged | unchanged |
| Any command that needs a missing object | As that command | As that command | As that command | As that command | One more promisor pack | Read only | unchanged |
| `git backfill` | unchanged | unchanged | unchanged | unchanged | Promisor packs with the missing blobs | Read only | unchanged |

> **GitHub, not Git.** Whether a filter is honoured is the server's decision. GitHub supports partial clone, and its engineers wrote the guidance cited above. A self-hosted server needs `uploadpack.allowFilter`.

## 26.13 `--single-branch`, and choosing a clone

`--single-branch` narrows the refspec to one branch (Chapter 12, section 12.3). It limits history by reachability, not by depth:

<!-- snippet: ch26/clone-shapes/01-full -->
```text
$ git clone "file://$PWD/server/orbit.git" full
Cloning into 'full'...
$ git -C full cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
$ git -C full for-each-ref --format="%(refname)" | wc -l
       9
```
<!-- /snippet -->

<!-- snippet: ch26/clone-shapes/02-single-branch -->
```text
$ git clone --single-branch "file://$PWD/server/orbit.git" single
Cloning into 'single'...
$ git -C single cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
 120 blob
  94 commit
   5 tag
 278 tree
$ git -C single branch -r
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

The saving is the two commits of the other branch with their trees and blobs. It pays off when a repository has long-lived branches with large unshared histories, and hardly at all otherwise.

The five shapes of `orbit`, from the transcripts of this chapter:

| Clone | Commits | Trees | Blobs | Tags | History questions | Works offline |
|---|---|---|---|---|---|---|
| Full | 96 | 284 | 122 | 5 | Right | Yes |
| `--single-branch` | 94 | 278 | 120 | 5 | Right, for that branch | Yes |
| `--depth 1` | 1 | 20 | 33 | 1 | Wrong or failing, silently | Yes, for the snapshot |
| `--filter=blob:none` | 96 | 284 | 33 | 5 | Right; contents fetched on demand | Only for what was fetched |
| `--filter=tree:0` | 96 | 20 | 33 | 5 | Right; trees and contents fetched on demand | Only for what was fetched |

| Situation | Choice |
|---|---|
| Developer on a large repository | Blobless, with sparse-checkout if the tree is wide (Chapter 24) |
| CI job that builds one snapshot and is discarded | Shallow |
| CI job that computes versions, changelogs or affected projects | Blobless, or full depth |
| Mirror, backup, server | Full |
| Machine without a route to the server | Full, or a bundle (26.14) |

## 26.14 Bundles

**In one sentence.** A bundle is a file that holds a pack and the refs that go with it, and an incremental bundle is one that names commits the receiver must already have.

**Precisely.** Chapter 12, section 12.13 and Chapter 13, section 13.14 created and cloned bundles. Two things remain. A bundle made from a range, `git bundle create <file> <old>..<new>` 🟢, contains only the objects that the range adds, and records `<old>` as a **prerequisite**: `git bundle verify` and every fetch from the bundle refuse a repository that lacks it. And `git clone --bundle-uri=<uri>` takes the bulk of a clone from a bundle, for example from a CDN, and only the remainder from the server.

**See it.**

<!-- snippet: ch26/bundles/01-full-and-incremental -->
```text
$ git bundle create ../orbit-full.bundle --all
$ git bundle verify ../orbit-full.bundle | tail -2
../orbit-full.bundle is okay
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
# Two more commits and a release tag, then a bundle of only what is new since the last one:
$ git log --oneline schemas/v1.1.0..main
6d3aa59 gateway: retry the upstream twice
aa0428a gateway: lower the upstream timeout to 600 ms
$ git bundle create ../orbit-update.bundle schemas/v1.1.0..main gateway/v1.2.0
$ git bundle verify ../orbit-update.bundle
../orbit-update.bundle is okay
The bundle contains these 2 refs:
6d3aa5958cd87cc93b3d598f9d92f1c1289f1204 refs/heads/main
b796e9ea912be02a0f9a0e2471070693a83a6efa refs/tags/gateway/v1.2.0
The bundle requires this ref:
100bb993157cac87afe81008782cd27cd39f8c9d 
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

**Inside the file.**

<!-- snippet: ch26/bundles/02-header -->
```text
# A bundle is a short text header followed by a pack. The header of the incremental bundle:
$ head -n 4 ../orbit-update.bundle
# v2 git bundle
-100bb993157cac87afe81008782cd27cd39f8c9d schemas, gateway, ingest: add the tenant field in one change
6d3aa5958cd87cc93b3d598f9d92f1c1289f1204 refs/heads/main
b796e9ea912be02a0f9a0e2471070693a83a6efa refs/tags/gateway/v1.2.0
$ head -n 2 ../orbit-full.bundle | cut -c1-70
# v2 git bundle
88222b7043b92ba564af0aefc4acd25af9ef15e2 refs/heads/feature/rerank-cac
```
<!-- /snippet -->

A signature line, one line per prerequisite starting with `-`, one line per ref, an empty line, and then a pack ([gitformat-bundle](https://git-scm.com/docs/gitformat-bundle)). The prerequisite is the commit `100bb99`, which was the tip when the full bundle was made.

<!-- snippet: ch26/bundles/03-prerequisite -->
```text
$ cd ..
# A repository that was cloned from the full bundle has the prerequisite commit:
$ git clone -q orbit-full.bundle site-b
$ git -C site-b bundle verify --quiet ../orbit-update.bundle
../orbit-update.bundle is okay
[exit status: 0]
$ git -C site-b fetch ../orbit-update.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'
From ../orbit-update.bundle
   100bb99..6d3aa59  main           -> origin/main
 * [new tag]         gateway/v1.2.0 -> gateway/v1.2.0
$ git -C site-b merge --ff-only origin/main
Updating 100bb99..6d3aa59
Fast-forward
 services/gateway/config.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
# An empty repository does not:
$ git init -q empty
$ git -C empty bundle verify ../orbit-update.bundle
error: Repository lacks these prerequisite commits:
error: 100bb993157cac87afe81008782cd27cd39f8c9d 
[exit status: 1]
$ git clone orbit-update.bundle from-update
Cloning into 'from-update'...
error: Repository lacks these prerequisite commits:
error: 100bb993157cac87afe81008782cd27cd39f8c9d 
fatal: remote transport reported error
[exit status: 128]
```
<!-- /snippet -->

The site that has `100bb99` verifies and fetches the update; the empty repository is refused twice with the name of the missing commit. An incremental bundle is thin on purpose, and its deltas may be based on objects it does not contain.

<!-- snippet: ch26/bundles/04-bundle-uri -->
```text
# A clone that takes the bulk from a bundle and only the rest from the server:
$ GIT_TRACE_PACKET="$PWD/seeded.trace" git clone -q --bundle-uri="$PWD/orbit-full.bundle" "file://$PWD/server/orbit.git" seeded
$ git -C seeded for-each-ref --format='%(refname)' | sed 's,^\(refs/[a-z]*\)/.*,\1,' | sort | uniq -c
   7 refs/bundles
   1 refs/heads
   3 refs/remotes
   6 refs/tags
# The request to the server offers what the bundle brought:
$ sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^have'
5
$ sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^want'
3
$ git -C seeded log --oneline -3
6d3aa59 gateway: retry the upstream twice
aa0428a gateway: lower the upstream timeout to 600 ms
100bb99 schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

The seeded clone first unpacked the bundle, kept its refs in a namespace of their own, and then told the server what it had: five `have` lines and three `want` lines, where the plain clone of 26.10 sent eight wants and no have. On this machine the namespace is `refs/bundles/`; the manual of `git clone` writes `refs/bundle/`. Servers can advertise bundle URIs themselves, and clients ignore that unless `transfer.bundleURI` is set ([bundle-uri](https://git-scm.com/docs/bundle-uri)).

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git bundle create <file> <range>` | unchanged | unchanged | unchanged | unchanged | unchanged; a file is written outside | unchanged | unchanged |
| `git fetch <bundle> <refspec>` | unchanged | unchanged | unchanged | unchanged | Objects added; the refs named by the refspec updated | unchanged | unchanged |

**In production.** For question 4 of section 26.1: one full bundle to start, then an incremental bundle per week whose basis is a tag that records what was sent last (the pattern in the EXAMPLES of `git help bundle`). Keep the bundles in order; Lab 18.3 loses one and recovers. A bundle carries no reflogs, hooks or configuration (Chapter 13).

## 26.15 When each feature matters

| Feature | Matters when | Who has reported it (their own figures) |
|---|---|---|
| Automatic maintenance | Always; leave it on | Git's default since 2.54 |
| Scheduled maintenance with prefetch | Large repositories on developer machines | Microsoft's Scalar ([Introducing Scalar](https://devblogs.microsoft.com/devops/introducing-scalar/)) |
| Commit-graph with changed-path filters | Long history and path-limited queries | Microsoft ([commit-graph post](https://devblogs.microsoft.com/devops/supercharging-the-git-commit-graph/)) |
| Geometric repack, multi-pack-index, bitmaps | Servers and very large clones | GitHub ([Scaling monorepo maintenance](https://github.blog/open-source/git/scaling-monorepo-maintenance/)) |
| File-system monitor, untracked cache | Hundreds of thousands of tracked files | Canva; Dropbox in 2020 ([Dropbox](https://dropbox.tech/application/speeding-up-a-git-monorepo-at-dropbox-with--200-lines-of-code)) |
| Sparse-checkout, sparse index | A wide tree of which each person needs little | Canva; GitHub Blog (Chapter 24) |
| Partial clone | Much blob content in history | GitHub Blog (26.11) |
| Shallow clone | Throwaway builds of one snapshot | GitHub Blog (26.11) |
| Checking what the pack contains | A repository much larger than its content explains | Dropbox in 2026 |

The last row deserves a paragraph. Dropbox reported in 2026 that its monorepo shrank from 87 GB to 20 GB through repacking, not through deleting history. The cause was the heuristic by which Git chooses delta candidates, which paired translation files of different languages because of the directory layout; the fix was a repack on the server with a larger window and depth ([Dropbox](https://dropbox.tech/infrastructure/reducing-our-monorepo-size-to-improve-developer-velocity)). Section 3.7 of Chapter 3 said that a delta is "between two objects chosen for similarity"; here the choice went wrong at scale. The lesson of both chapters is the same: measure the dimension that is large before choosing the feature.

## 26.16 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| Hundreds of packs or thousands of loose objects; everything slow | `git count-objects -v`; `git maintenance is-needed --auto` exits 0 | `git maintenance run` | Leave `maintenance.auto` on, or schedule maintenance |
| Maintenance "runs" and nothing changes | `git maintenance run --no-quiet` warns that a lock file exists; `.git/objects/maintenance.lock` | Check that no maintenance process runs for the repository, then remove the lock (Lab 16.3) | Do not kill maintenance; do not run `git gc` beside it |
| History commands fail with `invalid parent position` or give answers that differ between clones | `git commit-graph verify`; the same command with `-c core.commitGraph=false` | Delete `objects/info/commit-graph` or `commit-graphs/` and write it again (Lab 16.4) | Treat derived files as disposable; never copy them between repositories by hand |
| `git log -- <path>` slow although a commit-graph exists | The statistics line shows `filter_not_present` above zero, or does not appear | `git commit-graph write --reachable --changed-paths` | `commitGraph.changedPaths=true` |
| Versions, blame or changelogs wrong in CI | `git rev-parse --is-shallow-repository` | `git fetch --unshallow`, or a blobless clone | Shallow only for snapshot jobs |
| `could not fetch <id> from promisor remote` | Partial clone; server unreachable or the object deleted there | Restore access; `git backfill` | Backfill before going offline; keep the promisor remote alive |
| `git blame` or `git log -p` crawls in a partial clone | The trace shows one fetch per blob | `git backfill`, then `git maintenance run` | Backfill what you work on |
| A "partial" clone is as large as a full one | The clone printed "filtering not recognized by server" or "--filter is ignored in local clones" | Clone again from a server that allows filters, by URL | Read the output of `git clone` |
| `Repository lacks these prerequisite commits` | An incremental bundle arrived without its predecessor | Apply the missing bundle, or cut a new one from what the site has (Lab 18.3) | Number bundles; record the basis in a tag |
| The repository stays large after history was cleaned | `git fsck --unreachable`; `.mtimes` files in `objects/pack` | The purge of Chapter 21B | Know that geometric maintenance postpones deletion |

## 26.17 When not to use it, and dangerous edge cases

- **Do not tune a small repository.** Every feature here is configuration that the next person must understand. Automatic maintenance is enough until a counter of section 26.2 is large.
- **`git gc --aggressive`** recomputes every delta and rarely pays for itself; `git gc --prune=now` and `git prune` remove the grace period that protects running commands and your own mistakes (Chapter 13).
- **`git maintenance start` and `scalar` change your machine, not only the repository:** scheduler entries, global configuration and, for `scalar`, a daemon. Remove them with `git maintenance unregister`, `git maintenance stop` and `scalar unregister` when a repository goes away.
- **A shallow clone gives wrong answers with exit status 0.** It is safe only where nobody asks it about history.
- **A partial clone is not a backup.** It cannot be completed without its promisor remote. If the server loses the repository, or an object is removed there by a history rewrite, the promised objects are gone.
- **Not every combination works.** `git repack --filter` cannot write a bitmap (`git help repack`), and `--bundle-uri` is incompatible with `--depth` (`git help clone`). Read the manual of the version you run before combining transfer options.
- **Derived files can be wrong.** A damaged commit-graph changed the answer of `git rev-list --count` in Lab 16.4, and Git does not verify its checksum on every read. When two clones disagree about history, bypass the derived data first.
- **`fetch.unpackLimit=1` without maintenance** produces one pack per fetch for ever. The settings of `scalar` are a set; copying one of them is not a tuning.

## 26.18 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git count-objects -v`, `git maintenance is-needed`, `git commit-graph verify`, `git multi-pack-index verify`, `git bundle verify`, `git fsmonitor--daemon status` | 🟢 | nothing | not needed | not needed |
| `GIT_TRACE`, `GIT_TRACE_PACKET`, `GIT_TRACE2_PERF` | 🟢 | nothing; a trace file if a path is given | not needed | not needed |
| `git commit-graph write`, `git multi-pack-index write` | 🟢 | Derived files | not needed | Delete the file |
| `git maintenance run` | 🟡 | Packs, `packed-refs`, commit-graph, multi-pack-index; expires reflog entries by the configured periods | `git maintenance is-needed`; `GIT_TRACE=1` | None for expired reflog entries |
| `git maintenance run --task=gc`, `git gc` | 🟡 | The same, in one pack; deletes unreachable objects past the grace period | `git count-objects -v`; `git prune -n` | None for what was deleted |
| `git gc --prune=now` | 🔴 | Deletes all unreachable objects | `git fsck --unreachable` | None in this repository |
| `git maintenance start`, `register` | 🟡 | Global configuration and the system scheduler | `git help maintenance` | `git maintenance stop`, `unregister` |
| `git clone --depth`, `--filter`, `--single-branch`, `--bundle-uri` | 🟢 | Creates a repository | not needed | Delete the directory |
| `git fetch --deepen`, `--unshallow`, `git backfill` | 🟢 | Adds objects; moves or removes the shallow boundary | not needed | not needed |
| `git bundle create` | 🟢 | Writes a file | `git bundle verify`, `list-heads` | Delete the file |
| `git repack --geometric=2 -d` | 🟡 | Rewrites packs | `git count-objects -v` | Not needed for reachable objects |
| `git repack -a -d` | 🔴 | Rewrites everything reachable into one pack and deletes the packs it replaces. What it can destroy: the unreachable objects in those packs, which are what `git fsck` recovery depends on ([Chapter 3](ch03-git-internals.md), section 3.17) | `git fsck --unreachable`; `git count-objects -v` | Another clone or a backup only. Appropriate after a deliberate history rewrite, in a repository you have copied first |

## 26.19 Version notes

> **Version note.** Older behavior: porcelain commands ran `git gc --auto`, triggered by about 6,700 loose objects or 50 packs. Current behavior: they run `git maintenance run --auto` with the geometric strategy, and `git gc` is not involved. Since: `git maintenance` in Git 2.29, the geometric strategy in 2.52, the default in 2.54 ([maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc)). Recommended: nothing to configure. Read "automatic gc" in older texts, and in `git help gc` itself, as "automatic maintenance".

> **Version note.** `git maintenance is-needed` needs Git 2.53, `git backfill` 2.49 (experimental), `commitGraph.changedPaths` 2.52, `--bundle-uri` 2.38. The commit-graph dates from Git 2.18. Sources: the release table of the Phase 0 report, section 1, and the posts cited above.

> **Version note.** Git 2.56 adds `git repack --drop-filtered` and makes path-walk repacking work with bitmaps ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc); [Highlights from Git 2.56](https://github.blog/open-source/git/highlights-from-git-2-56/)). Not run here.

> **Outdated advice.** "Run `git gc` regularly" and "use `--depth 1` to make clones fast" both predate the features of this chapter. The first is now automatic and incremental. The second trades correctness for speed where a blobless clone would give both.

> **Unverified.** Whether `gc.auto=0` suppresses all automatic maintenance under the geometric strategy was not tested for this course. `maintenance.auto=false` is the documented switch and the one the transcripts use.

## 26.20 Practice

Labs 16.3 and 16.4 in [lab-manual/m16-maintenance.md](../lab-manual/m16-maintenance.md): trace a maintenance run and diagnose one that silently does nothing; write, verify, damage and rebuild a commit-graph. Labs 18.1 and 18.3 in [lab-manual/m18-transfer-scale.md](../lab-manual/m18-transfer-scale.md): one repository cloned three ways, and a bundle round trip with a lost update. Replay any transcript with `labs/run ch26/<demo>`. A drill: in `ch26/partial-clone/dev`, predict how many objects `git rev-list --objects --all --missing=print` still reports after `git backfill feature/rerank-cache`, then check.

## 26.21 Interview questions

1. `git status` is slow in one repository and `git log -- path` in another. How do you find out what each command is doing, without a stopwatch?
2. What does Git 2.55 run when a commit triggers automatic maintenance? How does that differ from `git gc`, and what does each delete?
3. Explain geometric repacking with three packs of 500, 30 and 30 objects. What happens at the next run, and what is never rewritten?
4. What is a cruft pack, and why can a repository under the default strategy hold unreachable objects for a long time?
5. What two kinds of data does a commit-graph hold, and which commands does each help? What happens when the file is stale, and when it is damaged?
6. Why are bitmaps a server feature? What does the counter `pack-reused` tell you?
7. Describe a fetch as a conversation. Where do `--depth` and `--filter` enter it?
8. A CI job reports the wrong version and an empty changelog, with exit status 0. Diagnose it.
9. Compare shallow, blobless and treeless clones: what each holds, what each answers correctly, and what each costs later.
10. A partial clone fails with `could not fetch ... from promisor remote`. What are the two possible causes, and how do you make a laptop independent of the server for a week?
11. How do you ship weekly updates to a site with no network route to the server? What goes wrong if one shipment is lost?
12. A consultant recommends `git gc --aggressive` every night. What do you answer?

## 26.22 Sources

**Primary sources.** The local manual of Git 2.55.0: `git help maintenance`, `gc`, `repack`, `commit-graph`, `multi-pack-index`, `fsmonitor--daemon`, `update-index`, `clone`, `fetch`, `rev-list`, `backfill`, `bundle`, `config`. Online: [git-maintenance](https://git-scm.com/docs/git-maintenance), [git-gc](https://git-scm.com/docs/git-gc), [git-repack](https://git-scm.com/docs/git-repack), [git-commit-graph](https://git-scm.com/docs/git-commit-graph), [gitformat-commit-graph](https://git-scm.com/docs/gitformat-commit-graph), [git-multi-pack-index](https://git-scm.com/docs/git-multi-pack-index), [bitmap-format](https://git-scm.com/docs/bitmap-format), [gitformat-pack](https://git-scm.com/docs/gitformat-pack), [git-fsmonitor--daemon](https://git-scm.com/docs/git-fsmonitor--daemon), [shallow](https://git-scm.com/docs/shallow), [partial-clone](https://git-scm.com/docs/partial-clone), [git-backfill](https://git-scm.com/docs/git-backfill), [git-bundle](https://git-scm.com/docs/git-bundle), [bundle-uri](https://git-scm.com/docs/bundle-uri), [gitprotocol-v2](https://git-scm.com/docs/gitprotocol-v2), [api-trace2](https://git-scm.com/docs/api-trace2). Git source at the 2.55.0 tag: [builtin/gc.c](https://github.com/git/git/blob/v2.55.0/builtin/gc.c) (strategies, tasks and thresholds) and [odb/source-loose.c](https://github.com/git/git/blob/v2.55.0/odb/source-loose.c) (the loose-object estimate).

**Secondary sources.** Derrick Stolee, Git's database internals, GitHub Blog, 2022: [I, the packed object store](https://github.blog/open-source/git/gits-database-internals-i-packed-object-store/), [II, commit history queries](https://github.blog/open-source/git/gits-database-internals-ii-commit-history-queries/), [III, file history queries](https://github.blog/open-source/git/gits-database-internals-iii-file-history-queries/), [IV, distributed synchronization](https://github.blog/open-source/git/gits-database-internals-iv-distributed-synchronization/). [Get up to speed with partial clone and shallow clone](https://github.blog/open-source/git/get-up-to-speed-with-partial-clone-and-shallow-clone/) (2020). Taylor Blau, [Scaling monorepo maintenance](https://github.blog/open-source/git/scaling-monorepo-maintenance/) (2021). Jeff Hostetler, [the file system monitor](https://github.blog/engineering/infrastructure/improve-git-monorepo-performance-with-a-file-system-monitor/) (2022). The practitioner reports of section 26.15: each from the publisher's own environment and date, not comparable with one another. The Phase 0 report of this course, sections 1, 12 and 13.

**Videos** (optional; assessments from the Phase 0 report). Derrick Stolee, ["Git Internals: a Database Perspective"](https://www.youtube.com/watch?v=YdstUWcg5j4) (Git Merge 2022, 27 min): pack indexes, the multi-pack-index, bitmaps, `git maintenance start`; current, and the best compact talk on this layer. Derrick Stolee, ["Git at Scale for Everyone"](https://www.youtube.com/watch?v=USLB1gwl1vA) (32 min, 2020): partial clone and background maintenance; the Scalar packaging shown is the one of 2020.

**Further reading.** [Chapter 3](ch03-git-internals.md), section 3.7, for packs and deltas; [Chapter 13](ch13-recovery.md), sections 13.4 and 13.13, for retention; [Chapter 24](ch24-monorepos.md) for the working-tree side; [Chapter 29](ch29-production-troubleshooting.md) for traces in diagnosis.

# V104: What makes a repository slow, git gc versus git maintenance, geometric repacking, and cruft packs

- **Part.** 4: Git internals
- **Module.** 16
- **Planned minutes.** 26
- **Prerequisites.** V103
- **Textbook sections.** [Chapter 26](../../textbook/ch26-performance.md), sections 26.1 to 26.5
- **Demo scripts.** `labs/ch26/scale-dimensions.sh`, `labs/ch26/maintenance-trace.sh`, `labs/ch26/cruft-packs.sh`

## HOOK

**[ON SCREEN]** Two lines: "`git status`: 4 s. `git log -- path`: 20 s." and "nightly cron: `git gc --aggressive`?"

Two things land on your desk in the same week. First: `git status` takes four seconds and `git log` on a path takes twenty. The CTO asks, is the repository broken, or too big? Second: a consultant told the team to put `git gc --aggressive` into a nightly cron job, a task the machine runs on a timer. Should you? Yes or no: say it out loud.

**[PAUSE]**

The answers from Chapter 26. To the first: neither. Slow commands map to specific kinds of size, and each kind has a remedy that changes no history. To the second: no. Since Git 2.54, Git's automatic maintenance uses a strategy that avoids exactly that kind of full rewrite, and `git gc` doesn't even take maintenance's lock. Hold on to both answers. By the end you can defend them.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video is about what Git does to its own storage in the background, after your commit returns. That housekeeping is called maintenance. You'll measure a repository along its dimensions, trace one maintenance run command by command, watch packs form a geometric progression over four runs, and see where unreachable objects go before they are deleted. A pack is one file that stores many objects. An unreachable object is one that no name leads to.

One principle first, in the textbook's words: everything in this chapter is derived data or a way of leaving data out. Derived data is data Git can rebuild from something else. No feature here changes a commit ID. That's why these features are safe to adopt, and why a slow repository is rarely a reason to rewrite history.

The repository is `orbit`, the monorepo of Chapter 24, one repository that holds many projects: 33 files, 94 commits on `main`, a feature branch, five tags. Three replays from `labs/ch26`.

One rule of this course: it never runs `git maintenance start`. That command writes outside the sandbox. I describe it from the manual and don't run it.

## LEARNING OBJECTIVES

After this video you can:

- Name the dimensions along which a repository grows and the command that each slows.
- Say what runs when a commit triggers automatic maintenance on Git 2.55.
- Trace one maintenance run task by task.
- Explain geometric repacking with three packs of given sizes.
- Explain what a cruft pack holds and when unreachable objects are finally deleted.

## CONCEPT

Start with slowness. In one sentence: a Git command is slow when the amount of data it must touch is large, so the diagnosis is to find which data a command touches and then to make that amount smaller or indexed.

**[ANIMATION]** cards: question=Large_in_which_way? cards=tracked_files|commits_and_trees|blob_content,_in_all_versions|loose_objects_and_packs|refs:branches,_tags_and_other_names title=Five_dimensions_that_do_not_depend_on_each_other id=dims

"Large" has dimensions that don't depend on each other: tracked files, commits and trees, blob content in all versions, loose objects and packs, and refs, the names such as branches and tags. Measure them before you tune anything.

**[ON SCREEN]** The table of section 26.2: slow command, what it touches, remedy.

`git status`, `git add` and `git switch` touch every index entry and tracked file, and every directory. The index is Git's list of tracked files. The remedies are sparse-checkout, the sparse index, the untracked cache and the file-system monitor. `git log` on a path and `git blame` touch every commit's tree, and the remedy is changed-path filters in the commit-graph. `git log --graph`, `git merge-base` and `git branch --contains` touch commit objects one by one, and the remedy is the commit-graph. Any object lookup touches one index per pack. The remedies are repacking and the multi-pack-index. `git clone` and `git fetch` touch everything reachable. The remedies are partial clone, and bitmaps on the server. The next videos take those one at a time.

Now maintenance. In one sentence: `git gc` is one command that repacks everything and deletes what has expired, `git maintenance` runs a configurable set of smaller tasks, and since Git 2.54 the maintenance that Git starts on its own no longer runs `git gc`.

`git maintenance run`, labelled 🟡 CAUTION, executes tasks. The manual lists them: `gc`, `commit-graph`, `prefetch`, `loose-objects`, `incremental-repack`, `pack-refs`, `reflog-expire`, `rerere-gc` and `worktree-prune`. Git 2.55 also accepts `geometric-repack`, which the task list of its manual page omits.

Which tasks run when you name none is decided by `maintenance.strategy`. There are four.

**[ON SCREEN]** The strategy table of section 26.3.

`geometric` runs `commit-graph`, `geometric-repack`, `pack-refs`, `reflog-expire`, `rerere-gc` and `worktree-prune`. It deletes reflog entries past their expiry, and unreachable objects only at an all-into-one repack. It's the default for manual and automatic maintenance since Git 2.54. `gc` runs the `gc` task, deletes what `git gc` deletes, and was the default before Git 2.54. `incremental` runs `prefetch` and `commit-graph` hourly, `loose-objects` and `incremental-repack` daily, and `pack-refs` weekly. It deletes no data, and `git maintenance register` sets it for scheduled runs. `none` runs nothing and is what scheduled maintenance uses until a strategy is configured.

A caveat the textbook attaches: the manual page of 2.55 is not consistent with itself. It calls geometric "the default strategy for manual maintenance" and still says in two places that "by default, only `maintenance.gc.enabled` is true". The trace in the demo settles it.

**[ANIMATION]** cards: cards=automatic:after_a_command_that_writes_objects|manual:you_run_it|scheduled:git_maintenance_start,_through_the_system_scheduler title=Three_ways_maintenance_runs numbered=on id=ways

Maintenance runs in three ways. Automatic: commands that write objects finish by starting `git maintenance run --auto`, detached, and each task runs only if its threshold is met. Manual: you run it. Scheduled: `git maintenance start`, also 🟡, registers the repository in your global configuration, installs entries in the system scheduler, launchd on macOS, sets the `incremental` strategy, and sets `maintenance.auto=false` in the repository.

**[ANIMATION]** end

Geometric repacking, in one sentence: it keeps packs in a sequence where each is at least twice as large as the next, by merging only the small ones, so that regular maintenance never rewrites the large pack. Size is counted in objects. The cost of a run is then proportional to the new data, not to the repository. `git gc` and `git repack -a` rewrite everything every time, and on a large repository that difference decides whether maintenance can run daily.

**[ANIMATION]** ladder: rungs=reachable:in_an_ordinary_pack|unreachable:still_in_its_pack,_a_geometric_run_does_not_look_at_reachability|in_the_cruft_pack:after_an_all-into-one_repack,_with_a_last-touched_time_in_.mtimes|deleted:after_the_grace_period,_gc.pruneExpire,_two_weeks title=Where_an_unreachable_object_goes id=cruft

Cruft packs, in one sentence: a cruft pack is a pack that holds only unreachable objects, with a companion file recording when each was last touched, so that garbage can wait out its grace period without becoming thousands of loose files. The grace period is `gc.pruneExpire`, two weeks, and it exists because a running command may be about to reference those objects. The companion is a `.mtimes` file. Under the geometric strategy a cruft pack is written only when the repack is all-into-one. An ordinary geometric run doesn't look at reachability at all.

**[ANIMATION]** walk: columns=,git_gc,git_maintenance_(geometric) rows=maintenance's_lock:not_taken:taken|repacks:everything,_every_time:only_the_small_packs|cost_follows:the_whole_repository:the_new_data|unreachable_objects:deleted_once_expired:stay_until_an_all-into-one_repack title=Full_inventory,_or_one_aisle_at_a_time mono=off id=versus steps=header,1,2,3,4

**[ANIMATION]** step: 1

When should you not interfere? Leave automatic maintenance on for ordinary repositories. And don't put `git gc` into cron next to it. The manual says: "`git gc` modifies the object database but does not take the lock in the same way as `git maintenance run`. If possible, use `git maintenance run --task=gc` instead of `git gc`." As for `--aggressive`: it discards all existing deltas and recomputes them, and the manual's own verdict is that it is "probably not worth it" without benchmarks for your repository.

## MENTAL MODEL

**[ANIMATION]** step: 3

The textbook's analogy: `git gc` closes the warehouse for a full inventory and reshelving. `git maintenance` sends a clerk through one aisle at a time while the warehouse stays open.

**[ANIMATION]** step: 4

The analogy breaks at deletion. A full inventory is also the moment when unclaimed goods are thrown away, and the clerk's rounds postpone that moment. Under the default strategy, unreachable objects can sit inside the large pack for a long time, because nothing rewrites that pack.

## DIAGRAM

**[ANIMATION]** stores: boxes=after_run_2:new_loose_objects_become_a_pack|after_run_3:507_is_at_least_2_x_24|after_run_4:the_same_rule,_pair_by_pair rows=1:A:pack_of_507|1:A:pack_of_24@hl|2:B:pack_of_507|2:B:pack_of_24|2:B:pack_of_24@hl|3:C:pack_of_507@ok|3:C:pack_of_104@hl arrows=3:B2>C2|3:B3>C2:merge title=Objects_per_pack,_run_by_run say_1=The_24_new_loose_objects_become_a_pack_of_their_own say_2=507_is_at_least_twice_24:_nothing_existing_is_merged say_3=The_two_small_packs_and_56_new_objects_merge._The_large_pack_was_never_rewritten id=geo

**[ANIMATION]** step: 2

**[DIAGRAM]** Three rows, one per maintenance run. Each box is a pack; the number is its object count.

```text
  run 2:  [ 507 ]  [ 24 ]                        new loose objects become a pack
  run 3:  [ 507 ]  [ 24 ]  [ 24 ]                507 >= 2 x 24: nothing existing is merged
  run 4:  [ 507 ]  [     104     ]               24 < 2 x 24: the small packs and 56 new objects merge
           never rewritten
```

The first run put all 507 objects into one pack. At run 2, the 24 new loose objects become a pack of their own. At run 3, Git looks at the packs that exist, 507 and 24. They are in progression, 507 is at least twice 24, so nothing existing is merged, and the new loose objects again become a pack of their own: 507, 24, 24.

Try it now, on paper, thirty seconds. Before run 4 the packs are 507, 24 and 24. Check the rule pair by pair: is each pack at least twice the next? Which packs will Git merge? I'll wait.

**[PAUSE]**

**[ANIMATION]** step: 3

At run 4 the existing packs are 507, 24 and 24. The two small ones break the rule, because 24 isn't at least twice 24. They merge with the new objects into one pack of 104. And 507 is at least twice 104. Notice the caption: the large pack was never rewritten.

## LIVE TERMINAL DEMO

**[TERMINAL]** First, measure.

```bash
labs/run ch26/scale-dimensions
```

```bash
git rev-list --count --all
git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
git ls-files | wc -l
git for-each-ref | wc -l
git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
```

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

Four dimensions in five commands: history, working tree, refs, storage. Look at the last three lines: 507 loose objects, no pack. This repository has never been maintained.

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

You saw this pipeline in video 100. One 43 KB file with 13 versions is where the bytes of `orbit` are.

To see where one command spends its effort, ask Git. `GIT_TRACE2_PERF=1` makes any command print a table of what it did. The rows of type `data` carry counters, and counters are reproducible.

33 tracked files. How many `lstat` calls, questions to the filesystem about one file, does one `git status` make? Say your number out loud.

**[PAUSE]**

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

Thirty-three index entries read, 33 `lstat` calls, 20 directories and 53 paths visited to look for untracked files. Scale those numbers to 500,000 files and you have the four seconds of the hook. That's the first answer, measured.

**[TERMINAL]** Second replay: the trace.

```bash
labs/run ch26/maintenance-trace
```

```bash
git init -q probe
echo 'probe' > probe/file.txt && git -C probe add file.txt
GIT_TRACE=1 git -C probe commit -q -m 'Add a file' 2>&1 | sed -n 's/.*trace: run_command: //p'
cd orbit
git config set maintenance.auto false
```

A quick quiz. A commit in a brand-new repository. What does Git start as its last act: `git gc --auto`, `git maintenance run --auto`, or nothing at all? Your answer?

**[PAUSE]**

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

`git maintenance run --auto --quiet --detach`. Not `git gc --auto`. Then, in `orbit`, the demo switches the trigger off, so that nothing runs behind our back.

```bash
git maintenance is-needed --auto
git maintenance is-needed --auto --task=geometric-repack
git maintenance is-needed --auto --task=commit-graph
git maintenance is-needed --auto --task=gc
```

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

`git maintenance is-needed` needs Git 2.53 or later and answers with its exit status: 0 means yes. The repack is needed, because more than about 100 loose objects exist. The commit-graph is not: fewer than 100 commits are missing from it. And the old `gc` threshold of about 6,700 loose objects is far away. The loose count is an estimate: Git counts the files in one of the 256 object directories and multiplies.

Now the 🟡 command, in the foreground, with the trace written to a file.

```bash
GIT_TRACE="$PWD/../trace-1.log" git maintenance run
sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -v -e '^pack-objects' -e '^multi-pack-index'
```

How many commands will maintenance start, and is `gc` one of them? Say it out loud.

**[PAUSE]**

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

Six commands, and no `git gc` among them: `pack-refs`, `reflog expire`, `repack`, `commit-graph write`, `worktree prune`, `rerere gc`. The repack line says `--cruft` with no `--geometric`, because there was no pack yet and so everything went into one. Below, `repack` started `pack-objects` twice, once for reachable objects and once for a cruft pack that turned out empty, and then wrote a multi-pack-index.

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

One pack with its index and reverse index, a multi-pack-index, a commit-graph stored as a chain, and every ref moved from its own file into `packed-refs`. No loose ref files remain. Remember that line for the next video.

**[ON SCREEN]** The state table: for `git maintenance run`, working tree, index and HEAD unchanged; the current branch ref has the same value, now in `packed-refs`; loose objects are packed, the multi-pack-index and commit-graph chain are written, reflog entries past expiry are removed; remote and GitHub unchanged.

The state table for `git maintenance run`. Working tree, index and HEAD are unchanged. The current branch ref has the same value, now in `packed-refs`. Loose objects are packed, the multi-pack-index and the commit-graph chain are written, and reflog entries past expiry are removed. The remote and GitHub are unchanged.

Six commits later, the second run.

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

Now the repack line reads `--geometric=2`. Two packs afterwards.

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

This is the diagram, measured. First 507 and 24. Then 507, 24 and 24. Then 507 and 104.

For comparison, the older way.

```bash
GIT_TRACE="$PWD/../trace-3.log" git maintenance run --task=gc
```

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

Here `git gc` appears, with `git prune`, which deletes loose unreachable objects past the grace period. It leaves one pack of all 611 objects, a single commit-graph file, and no multi-pack-index.

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

The tasks of the `incremental` strategy, run once by name. None of these deletes an object that isn't stored elsewhere.

**[TERMINAL]** Third replay: garbage.

```bash
labs/run ch26/cruft-packs
```

This replay contains two 🔴 commands, so the five answers first. `git reflog expire --expire=now --all` deletes every reflog entry. It destroys the record of where refs used to point, the safety net of recovery. Preview it with `git reflog expire --dry-run --expire=now --all`. There's no recovery for the entries. `git fsck` still finds the objects until they're pruned. `git gc --prune=now` deletes unreachable objects at once. Preview with `git fsck --unreachable`, and recover from another clone or a backup only. Both are appropriate after a deliberate history rewrite, in a repository you've copied first, never as routine maintenance. Here they run in a throwaway sandbox.

**[ANIMATION]** graph: 9c9fd21-88222b7 feature/rerank-cache; HEAD=none => 9c9fd21-88222b7; HEAD=none; reflog:9c9fd21,88222b7; name:deleted; say:The_branch_is_deleted:_the_reflog_of_HEAD_still_names_the_commits => 9c9fd21-88222b7; HEAD=none; ghost:9c9fd21,88222b7; name:unreachable; say:The_reflogs_are_expired:_nothing_names_them_now title=The_two_commits_of_the_deleted_branch id=two

Watch two commits in this replay: `9c9fd21` and `88222b7`, the work of one feature branch. Once the branch and the reflog entries are gone, they're unreachable, and now the question is when they're deleted.

```bash
git branch -D feature/rerank-cache
git fsck --unreachable | wc -l
git reflog expire --expire=now --all
git fsck --unreachable | sort
```

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

After the branch is deleted, nothing is unreachable: the reflog of HEAD still names the commits. After the reflogs are expired, ten objects are unreachable.

```bash
git maintenance run
git fsck --unreachable | wc -l
```

A quick quiz. A maintenance run of the default strategy. How many of the ten unreachable objects does it delete: all ten, some, or none? Your answer?

**[PAUSE]**

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

None. It packed three new objects and left the ten where they were: inside the large pack, which a geometric run doesn't rewrite. If you said all ten, that's what most people expect from a clean-up.

```bash
git maintenance run --task=gc
```

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

The `gc` task separates them. The pack that has an `.mtimes` file is the cruft pack: ten objects. The deleted branch's commit `88222b7` is still readable by ID.

```bash
git gc --prune=now
```

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

With no grace period, the cruft pack is gone and so is the commit. The transcript uses `now` because a cut-off that depends on the clock could not be reproduced.

## COMMON MISTAKES

Five mistakes to watch for.

1. Scheduling `git gc` next to automatic maintenance. Root cause: `git gc` modifies the object database without taking the lock that `git maintenance run` takes.
2. Treating several packs as a fault. Root cause: under geometric repacking, several packs are the normal state of a healthy repository.
3. Assuming a removed commit is deleted after maintenance. Root cause: an ordinary geometric run does not look at reachability; unreachable objects leave only at an all-into-one repack, and then wait in a cruft pack for the grace period.
4. Looking for garbage as loose files. Root cause: unreachable objects sit in packs; diagnose with `git fsck --unreachable | wc -l` and by looking for `.mtimes` files.
5. Tuning before measuring. Root cause: the dimensions of size are independent, and each slows different commands.

## PRODUCTION EXAMPLE

**[ANIMATION]** stores: boxes=a_default_maintenance_run:geometric|the_gc_task:all_into_one|git_gc_--prune=now:no_grace_period rows=1:A:pack_of_507@hl|1:A:pack_of_3|2:B:pack_of_500|2:B:cruft_pack_of_10,_.mtimes@hl|3:C:one_pack|3:C:the_10_objects_are_deleted@bad arrows=2:A1>B2:10_objects title=Ten_unreachable_objects,_three_clean-ups say_1=The_ten_stay_inside_the_large_pack,_which_is_not_rewritten say_2=An_all-into-one_repack_separates_them_into_a_cruft_pack say_3=Without_a_grace_period_they_are_deleted_at_once id=ten

Now, out of the lab. Suppose a team removed a leaked credential from the history of its evaluation repository, rewrote the branch and force-pushed. A week later a security review finds the old blob still readable in a developer's clone. Nothing is broken. That clone runs the default strategy, and a repository under the default strategy can hold unreachable objects for a long time. Rewriting and force-pushing doesn't delete the objects from a clone. The purge is the deliberate procedure of Chapter 21B.

**[ANIMATION]** step: versus.4

**[ANIMATION]** say: Leave_automatic_maintenance_on,_and_keep_git_gc_out_of_cron

For the nightly cron question, the same team's decision: leave automatic maintenance on for ordinary repositories. For the very large repository, use `git maintenance start` on developer machines, which is what `scalar` does, and know what it installs.

## PRACTICE EXERCISE

Your turn. Do Lab 16.3, "Trace what a maintenance run does", in [`lab-manual/m16-maintenance.md`](../../lab-manual/m16-maintenance.md). Before you read the trace, write down which commands you expect maintenance to start, in order, and whether `gc` is among them. Before each later run, predict the object count of every pack.

The challenge is Exercise 16.6, "The largest blobs in history", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 82 of the CTO question bank:

> "What does Git 2.55 run when a commit triggers automatic maintenance? How does that differ from `git gc`, and what does each delete?"

A strong answer names the trigger and the strategy, lists the tasks rather than saying "it cleans up", and contrasts what is rewritten in each case. On deletion it's exact about three things: reflog entries, unreachable objects, and the grace period. It mentions the version in which the default changed.

## RECAP

**[ANIMATION]** step: cruft.4

**[ANIMATION]** say: Unreachable_is_not_yet_deleted

Let's land this. Measure before you tune, let maintenance do its rounds, and remember that unreachable is not yet deleted.

You should now be able to say:

- A command is slow because of the data it touches; measure files, commits, blobs, packs and refs separately.
- Since Git 2.54, a commit triggers `git maintenance run --auto` with the geometric strategy, and that does not run `git gc`.
- Geometric repacking merges only small packs, so the large pack is never rewritten.
- Unreachable objects are separated into a cruft pack only at an all-into-one repack, and are deleted after the grace period.
- Nothing here changes a commit ID.

## HOMEWORK

Read sections 26.1 to 26.5 of [Chapter 26](../../textbook/ch26-performance.md).

Today you traced what Git does after a commit returns, and you answered a consultant with a measurement. Do the lab before the next video: refs in depth, from loose refs to reflog storage. Until then, look at the state first and type second. See you in the next one.

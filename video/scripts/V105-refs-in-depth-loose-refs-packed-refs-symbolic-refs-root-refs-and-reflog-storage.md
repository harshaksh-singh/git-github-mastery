# V105: Refs in depth: loose refs, packed-refs, symbolic refs, root refs, and reflog storage

- **Part.** 4: Git internals
- **Module.** 17
- **Planned minutes.** 24
- **Prerequisites.** V022, V103
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), sections 3.9, 3.10 and 3.11
- **Demo scripts.** `labs/ch03/refs-storage.sh`, `labs/ch03/root-refs.sh`, `labs/ch03/lab-17-3-special-refs-tour.sh`

## HOOK

**[ON SCREEN]** `cat: .git/refs/heads/main: No such file or directory`

The release script stamps every build with a commit ID. It gets that ID by reading the file `.git/refs/heads/main`. It has done so for years. On the new build image that file doesn't exist, and the release stops.

Your CTO asks: is the repository damaged?

It isn't. The branch exists and Git resolves it. The ref is stored somewhere else, and the script should have asked Git. A ref is a name that holds an object ID, and a branch is one kind of ref. This video shows every place a ref can be stored in the default format, and why no script should read any of them. Keep that missing file in mind. It comes back.

## INTRODUCTION

**[ANIMATION]** graph: b602c1f-4f2cc0c-0c2cf43 main origin/main atag:v1.0.0#0b624ed; ^b602c1f-62001eb feature/batching; 62001eb-0c2cf43; 4f2cc0c tag:v1.0.0-rc1; HEAD=main => 0c2cf43 main origin/main atag:v1.0.0#0b624ed; 62001eb feature/batching; 4f2cc0c tag:v1.0.0-rc1 experiment; HEAD=main => 0c2cf43 main origin/main atag:v1.0.0#0b624ed experiment; 62001eb feature/batching; 4f2cc0c tag:v1.0.0-rc1; HEAD=main => 0c2cf43 main origin/main atag:v1.0.0#0b624ed; 62001eb feature/batching; 4f2cc0c tag:v1.0.0-rc1; HEAD=main => 0c2cf43 main origin/main atag:v1.0.0#0b624ed; 4f2cc0c tag:v1.0.0-rc1; HEAD=main => 0c2cf43-a8eea18 main; 0c2cf43 origin/main atag:v1.0.0#0b624ed; 4f2cc0c tag:v1.0.0-rc1; HEAD=main title=Refs:_names_that_point_at_commits id=refs at_state_5=0 at_state_6=22

**[ANIMATION]** step: refs.state-1

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You've used refs since the first part of this course: a branch is a ref, a tag is a ref, HEAD is a ref. Now we look at how they are stored. Three sections of Chapter 3. First, refs under `refs/` as loose files and as lines of `packed-refs`. Second, the refs that live outside `refs/`, called root refs, and the two pseudorefs. Third, where reflogs are kept. A reflog is the journal of the values a ref has had.

**[ANIMATION]** end

Three replays from `labs/ch03`: `refs-storage.sh`, `root-refs.sh`, and the replay of Lab 17.3 up to its checkpoint.

The labels, from the chapter's command safety table. `git for-each-ref` and `git show-ref` are 🟢 SAFE. `git pack-refs --all` is 🟢: it changes the storage of refs, not their content. `git update-ref` with a new value is 🟡 CAUTION, and so is `git symbolic-ref`. `git update-ref -d` is 🔴 DANGEROUS, and I'll answer the five questions when it appears.

## LEARNING OBJECTIVES

After this video you can:

- Explain why a branch may have no file under `refs/heads/` and still exist.
- Create, update, verify and delete refs with plumbing, with a reflog message.
- Name the root refs and the pseudorefs and say which command writes each.
- Say which of them protect objects from garbage collection.
- Say where reflogs are stored and when a ref has none.

## CONCEPT

In one sentence: a ref is a name that holds an object ID or the name of another ref, and in the default `files` format a ref is a small file under `refs/`, a line in `packed-refs`, or both.

The glossary's definition: "a name that points to an object name or another ref (the latter is called a symbolic ref)". Names either start with `refs/` or sit in the root of the hierarchy.

**[ON SCREEN]** The namespace table of section 3.9.

Under `refs/`: `refs/heads/<name>` is a local branch, moved by commit, merge, reset, rebase and `git branch -f`. `refs/tags/<name>` is a tag, pointing at a commit or at a tag object, meant to stay put. `refs/remotes/<remote>/<name>` is a remote-tracking branch, the last known position of a branch in that remote, moved by fetch and push. `refs/stash` is the newest stash entry, work you set aside, and older entries live in its reflog. And tools own namespaces such as `refs/bisect/`, `refs/notes/` and `refs/replace/`.

**[ANIMATION]** stores: boxes=.git/HEAD:a_symbolic_ref|*.git/refs/heads/main:a_loose_ref|.git/packed-refs:many_refs,_sorted rows=1:A:ref:_refs/heads/main|1:B:0c2cf43...|2:B:after_packing:_no_file@dim|2:C:0c2cf43..._refs/heads/main|3:B:after_a_commit:_a8eea18@hl arrows=1:A1>B|2:B1>C1:packed title=Where_the_value_of_main_is_kept say_1=A_loose_ref_is_a_file_that_holds_the_ID say_2=After_packing,_main_is_a_line_in_packed-refs say_3=The_loose_file_is_back_and_wins._The_packed_line_is_stale id=where at_1=12

**[ANIMATION]** step: 1

How they're stored in the `files` format. A loose ref is a file holding the ID and a newline. A symbolic ref is a file holding `ref:` and a name. `packed-refs` is one sorted text file with many refs. Why three forms? One file per ref wastes space and is slow with thousands of refs.

**[ANIMATION]** step: 2

The lookup rule is the heart of this video. Lookup reads the loose file first and `packed-refs` second. And, quoting the manual of `git pack-refs`: "subsequent updates to branches always create new files under `$GIT_DIR/refs`". So after packing, a branch that moves gets a loose file again, and the old line in `packed-refs` stays, stale. The loose file wins.

**[ANIMATION]** cards: cards=git_for-each-ref:lists_and_formats|git_show-ref:lists_and_verifies|git_update-ref:writes_or_deletes_one_ref|git_symbolic-ref:reads_and_writes_symbolic_refs|git_pack-refs:moves_loose_refs_into_packed-refs title=The_plumbing_works_the_same_in_every_format id=plumbing

The plumbing works the same in every format. `git for-each-ref` lists and formats. `git show-ref` lists and verifies. `git update-ref` writes or deletes one ref with an optional check of its old value. `git symbolic-ref` reads and writes symbolic refs. `git pack-refs` moves loose refs into `packed-refs` without changing a value.

**[ANIMATION]** end

Second topic: root refs. In one sentence: a few refs live directly in the repository directory, with names in capital letters that end in `_HEAD`. Two of them, `FETCH_HEAD` and `MERGE_HEAD`, aren't refs at all in the strict sense and are called pseudorefs.

The glossary says a pseudoref has "different semantics than normal refs", can be read by normal Git commands, and cannot be written by commands like `git update-ref`. It lists two. `FETCH_HEAD` "may refer to multiple object IDs", each annotated with its source. `MERGE_HEAD` "contains all commit IDs which are being merged".

**[ANIMATION]** walk: columns=kind,names,for_Git rows=root_ref:HEAD,_ORIG__HEAD_and_the_other_names_in_capitals:stored_like_any_other_ref|pseudoref:FETCH__HEAD_and_MERGE__HEAD_only:git_update-ref_cannot_write_it title=Since_Git_2.46 mono=off id=kinds

A version note you need when you read older material. Before Git 2.46 the glossary called every special file under `.git` a pseudoref. Since Git 2.46, "pseudoref" means `FETCH_HEAD` and `MERGE_HEAD` only. The others are root refs, stored by the ref backend like any other ref. Say "root ref" for `ORIG_HEAD` and its relatives, and notice that older tutorials, and the description of `--include-root-refs` in the `git for-each-ref` manual, still use the old wording.

**[ON SCREEN]** The table of section 3.10: name, written by, holds, gone when.

`HEAD` is written by `git init`, `git switch` and `git checkout`, and is never gone. `ORIG_HEAD` is written by merge, rebase, reset and `git am`, and on Git 2.55 also by `git stash push`. It holds where HEAD was before, until the next such command overwrites it. `FETCH_HEAD` is written by fetch and pull. `MERGE_HEAD` is written by a merge that stops, and goes when the merge is committed or aborted. `CHERRY_PICK_HEAD` and `REVERT_HEAD` are written by a cherry-pick or revert that stops or runs with `--no-commit`. `REBASE_HEAD` is written by a rebase that stops. `BISECT_HEAD` is written by `git bisect --no-checkout`. `AUTO_MERGE` is written by the `ort` merge machinery when it leaves conflicts, and on Git 2.55 also by a clean `git stash pop`. It holds a tree.

**[ANIMATION]** cards: question=Which_names_keep_an_object_alive? cards=refs/|HEAD|the_reflogs|the_index|FETCH__HEAD|ORIG__HEAD|AUTO__MERGE marks=1:ok,2:ok,3:ok,4:ok,5:bad,6:bad,7:bad title=Starting_points_for_reachability id=alive

**[ANIMATION]** step: marks

The property that matters in an incident: these names, HEAD excepted, aren't starting points for reachability. An object is reachable when a starting point leads to it, and garbage collection deletes what nothing reaches. The starting points are `refs/`, HEAD, the reflogs and the index. So `FETCH_HEAD`, `ORIG_HEAD` and `AUTO_MERGE` protect nothing from garbage collection beyond the grace period.

**[ANIMATION]** walk: columns=ref,reflog_under_the_default_setting rows=HEAD:yes|a_branch:yes,_deleted_with_the_branch|a_remote-tracking_branch:yes|notes:yes|a_tag:no|any_ref_in_a_bare_repository:no marks=1.2:ok,2.2:ok,3.2:ok,4.2:ok,5.2:bad,6.2:bad title=Who_gets_a_reflog mono=off id=logs

Third topic: reflogs. In one sentence: a reflog is an append-only record of the values a ref has had, one file per ref under `logs/` in the `files` format, written whenever the ref moves. `core.logAllRefUpdates` is `true` in a repository with a working tree, which creates logs for HEAD, branches, remote-tracking branches and notes. The value `always` extends this to every ref under `refs/`. A bare repository, one without a working tree, has it off and keeps no reflogs by default. Tags get no reflog under the default setting, and deleting a branch deletes its log.

**[ANIMATION]** end

When should you not use the plumbing? `git update-ref` on the checked-out branch and `git symbolic-ref HEAD` move the branch and leave the index and the working tree behind. Treat them as repairs. Use `git switch` and `git reset` for daily work.

## MENTAL MODEL

**[ANIMATION]** step: refs.state-1

The textbook's analogy is signposts. Each carries a name and points at one house, an object. A few point at another signpost: those are symbolic refs. Moving a signpost is cheap and changes no house.

**[ANIMATION]** end

The analogy breaks at demolition. In Git, a house that no signpost leads to is eventually torn down. That was the previous video.

**[ANIMATION]** step: where.2

**[ANIMATION]** say: More_than_one_cupboard:_ask_the_keeper,_the_plumbing

Add one thing to the picture for this video: the signposts are kept in more than one cupboard. You don't open the cupboards yourself. You ask the keeper, which is the plumbing, Git's low-level commands, and the keeper knows which cupboard is current.

## DIAGRAM

**[ANIMATION]** decide: nodes=q1:loose_file_.git/refs/heads/main_exists?|a:use_its_content|q2:a_line_for_refs/heads/main_in_packed-refs?|b:use_that_line|c:not_found edges=q1>a:yes|q1>q2:no|q2>b:yes|q2>c:no title=Resolve_refs/heads/main_(files_format) id=lookup

**[ANIMATION]** step: level-3

**[DIAGRAM]** First the lookup, drawn as a decision.

```text
  resolve refs/heads/main (files format)

     loose file .git/refs/heads/main exists?  --- yes --->  use its content
                    | no
                    v
     line for refs/heads/main in packed-refs? --- yes --->  use that line
                    | no
                    v
               not found
```

Loose file first. If there is one, it's the answer, whatever `packed-refs` says. Only if there is none does Git read the line in `packed-refs`. A script that reads only the file fails when the ref is packed. A script that reads only `packed-refs` gets a stale value when the ref has moved since.

**[DIAGRAM]** Then one reflog line, field by field, from section 3.11.

```text
 b602c1fa... 62001eb8... Asha Rao <asha@example.com> 1788756480 +0530 <TAB> commit: Add batch size setting
 old value   new value   committer                   seconds    zone        message
```

The old value, the new value, the committer's identity and time, a tab, and a message naming the command.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch03/refs-storage
```

The inference-service repository again, now with a remote, a stash entry and two tags.

```bash
find .git/refs -type f | sort
cat .git/refs/heads/main
cat .git/refs/tags/v1.0.0
cat .git/HEAD
cat .git/refs/remotes/origin/HEAD
```

<!-- snippet: ch03/refs-storage/01-loose-refs -->
```text
$ find .git/refs -type f | sort
.git/refs/heads/feature/batching
.git/refs/heads/main
.git/refs/remotes/origin/HEAD
.git/refs/remotes/origin/main
.git/refs/stash
.git/refs/tags/v1.0.0
.git/refs/tags/v1.0.0-rc1
$ cat .git/refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ cat .git/refs/tags/v1.0.0
0b624edf4a556c702b6ed110ef2702570ced1558
# Two symbolic refs. They hold a ref name, not an object ID:
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/remotes/origin/HEAD
ref: refs/remotes/origin/main
```
<!-- /snippet -->

Seven files. Five hold an object ID. Two hold `ref:` and a name: those are the symbolic refs.

```bash
git for-each-ref
git for-each-ref --format='%(refname:short) -> %(objectname:short) %(upstream:short)' refs/heads
git show-ref --tags --dereference
git show-ref --verify refs/heads/main
git show-ref --exists refs/heads/no-such-branch
```

<!-- snippet: ch03/refs-storage/02-list -->
```text
$ git for-each-ref
62001eb879c6506f6d3c8e625dfadfa5029367b7 commit	refs/heads/feature/batching
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	refs/remotes/origin/HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	refs/remotes/origin/main
0c3d1b1c205d3248bab3061f235ef2309f653b49 commit	refs/stash
0b624edf4a556c702b6ed110ef2702570ced1558 tag	refs/tags/v1.0.0
4f2cc0c5f842120f109977a97bc72acef5aa5ccd commit	refs/tags/v1.0.0-rc1
$ git for-each-ref --format='%(refname:short) -> %(objectname:short) %(upstream:short)' refs/heads
feature/batching -> 62001eb 
main -> 0c2cf43 origin/main
# show-ref can peel annotated tags (the ^{} lines) and test for existence:
$ git show-ref --tags --dereference
0b624edf4a556c702b6ed110ef2702570ced1558 refs/tags/v1.0.0
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/tags/v1.0.0^{}
4f2cc0c5f842120f109977a97bc72acef5aa5ccd refs/tags/v1.0.0-rc1
$ git show-ref --verify refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/heads/main
[exit status: 0]
$ git show-ref --exists refs/heads/no-such-branch
error: reference does not exist
[exit status: 2]
```
<!-- /snippet -->

`for-each-ref` prints ID, type and full name by default, and `--format` chooses any field. `show-ref --dereference` adds a `^{}` line with the commit an annotated tag peels to. `--verify` takes a full name. `--exists` answers by exit status.

Try it now, thirty seconds, in a repository in the lab shell: run `git for-each-ref` and count the lines. I'll wait.

**[PAUSE]**

Each line is one ref: an ID, a type and a full name. Your branches are the lines under `refs/heads/`.

Now 🟡: `git update-ref`. It changes one ref and its reflog. Preview with `git rev-parse` on the ref. Recover with the ref's reflog.

**[ANIMATION]** step: refs.state-2

On the graph, that's a new name. The demo creates the ref `experiment` at the release candidate.

**[ANIMATION]** step: refs.state-3

Then it moves the name to the commit of `main`. No commit changes.

```bash
git update-ref -m "experiment: start at the release candidate" refs/heads/experiment v1.0.0-rc1
git branch --list --verbose experiment
git update-ref refs/heads/experiment main b602c1fa61adb577fc9ca3113292b7cf734e856a
git update-ref refs/heads/experiment main v1.0.0-rc1
git reflog show experiment
```

The third command has a third argument: an expected old value. The branch is at the release candidate, and the command expects the root commit. What happens? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch03/refs-storage/03-update-ref -->
```text
# A branch is a ref, so plumbing can create one: name, new value, reflog message.
$ git update-ref -m "experiment: start at the release candidate" refs/heads/experiment v1.0.0-rc1
$ git branch --list --verbose experiment
  experiment 4f2cc0c Add readiness handler
# With a third argument the update happens only if the ref still has that old value.
$ git update-ref refs/heads/experiment main b602c1fa61adb577fc9ca3113292b7cf734e856a
fatal: update_ref failed for ref 'refs/heads/experiment': cannot lock ref 'refs/heads/experiment': is at 4f2cc0c5f842120f109977a97bc72acef5aa5ccd but expected b602c1fa61adb577fc9ca3113292b7cf734e856a
[exit status: 128]
$ git update-ref refs/heads/experiment main v1.0.0-rc1
[exit status: 0]
$ git reflog show experiment
0c2cf43 experiment@{0}: 
4f2cc0c experiment@{1}: experiment: start at the release candidate
# Two refusals: an object that does not exist, and a branch that would not name a commit.
$ git update-ref refs/heads/broken 1234567890123456789012345678901234567890
fatal: update_ref failed for ref 'refs/heads/broken': trying to write ref 'refs/heads/broken' with nonexistent object 1234567890123456789012345678901234567890
[exit status: 128]
$ git update-ref refs/heads/broken HEAD:config.toml
fatal: update_ref failed for ref 'refs/heads/broken': trying to write non-commit object 60a72d9888260645df622ecd424e474d09d40560 to branch 'refs/heads/broken'
[exit status: 128]
$ git update-ref -d refs/heads/experiment
```
<!-- /snippet -->

It's refused: "is at `4f2cc0c`... but expected `b602c1f`...". With a third argument, `update-ref` is a compare-and-swap. The update happens only if the ref still has the expected old value, which keeps concurrent writers from overwriting each other. It's the idea behind `git push --force-with-lease`. Two more refusals follow: an ID that names no object, and a non-commit under `refs/heads/`.

The last line is the 🔴 command, `git update-ref -d`. The five answers. It deletes the ref and its reflog, with no merge check. It destroys the safety net for that ref. Preview: `git rev-parse` on the ref, and note the ID. Recover: `git update-ref` with that ID, which the reflog of HEAD or `git fsck` find. Appropriate: for a ref you created with plumbing and have just inspected, as here.

**[ANIMATION]** step: refs.state-4

On the graph the name is gone, and every commit is where it was.

**[ANIMATION]** end

```bash
git symbolic-ref HEAD
git symbolic-ref --short HEAD
git symbolic-ref refs/remotes/origin/HEAD
git symbolic-ref refs/heads/latest refs/heads/main
cat .git/refs/heads/latest
git symbolic-ref --delete refs/heads/latest
git switch --quiet --detach v1.0.0-rc1
cat .git/HEAD
git symbolic-ref HEAD
git switch --quiet main
```

<!-- snippet: ch03/refs-storage/04-symbolic-ref -->
```text
$ git symbolic-ref HEAD
refs/heads/main
$ git symbolic-ref --short HEAD
main
$ git symbolic-ref refs/remotes/origin/HEAD
refs/remotes/origin/main
# Any ref can be symbolic. This one makes "latest" another name for main:
$ git symbolic-ref refs/heads/latest refs/heads/main
$ cat .git/refs/heads/latest
ref: refs/heads/main
$ git rev-parse latest main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ git symbolic-ref --delete refs/heads/latest
# Detached HEAD: the file holds an object ID, so there is no symbolic ref to read.
$ git switch --quiet --detach v1.0.0-rc1
$ cat .git/HEAD
4f2cc0c5f842120f109977a97bc72acef5aa5ccd
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
$ git switch --quiet main
```
<!-- /snippet -->

A symbolic ref is a name for a name. With HEAD detached, the file holds an object ID, and `git symbolic-ref HEAD` fails: "ref HEAD is not a symbolic ref".

Reflog storage.

```bash
find .git/logs -type f | sort
cat .git/logs/refs/heads/feature/batching
git reflog show feature/batching
git reflog exists refs/tags/v1.0.0
git branch -d feature/batching
find .git/logs -type f | sort
```

A quick quiz. After the branch is deleted, is its log file still there, or gone with it? Your answer?

**[PAUSE]**

<!-- snippet: ch03/refs-storage/05-reflog-files -->
```text
$ find .git/logs -type f | sort
.git/logs/HEAD
.git/logs/refs/heads/feature/batching
.git/logs/refs/heads/main
.git/logs/refs/remotes/origin/HEAD
.git/logs/refs/remotes/origin/main
.git/logs/refs/stash
$ cat .git/logs/refs/heads/feature/batching
0000000000000000000000000000000000000000 b602c1fa61adb577fc9ca3113292b7cf734e856a Lab User <you@example.com> 1788756420 +0530	branch: Created from HEAD
b602c1fa61adb577fc9ca3113292b7cf734e856a 62001eb879c6506f6d3c8e625dfadfa5029367b7 Asha Rao <asha@example.com> 1788756480 +0530	commit: Add batch size setting
$ git reflog show feature/batching
62001eb feature/batching@{0}: commit: Add batch size setting
b602c1f feature/batching@{1}: branch: Created from HEAD
# Tags get no reflog by default. A deleted branch loses its reflog with it:
$ git reflog exists refs/tags/v1.0.0
[exit status: 1]
$ git branch -d feature/batching
Deleted branch feature/batching (was 62001eb).
$ find .git/logs -type f | sort
.git/logs/HEAD
.git/logs/refs/heads/main
.git/logs/refs/remotes/origin/HEAD
.git/logs/refs/remotes/origin/main
.git/logs/refs/stash
```
<!-- /snippet -->

It's gone. A deleted branch loses its reflog with it. Tags have none. `refs/stash` has a log, and that log is the stash list.

Now the hook, and that missing file.

```bash
git pack-refs --all
cat .git/packed-refs
find .git/refs -type f | sort
printf 'max_tokens = 256\n' >> config.toml
git commit --quiet -am "Add token limit"
find .git/refs -type f | sort
grep refs/heads/main .git/packed-refs
git rev-parse main
```

After the commit: where is `main` stored, and what does the line in `packed-refs` say? Make your prediction. I'll wait.

**[PAUSE]**

<!-- snippet: ch03/refs-storage/06-packed-refs -->
```text
$ git pack-refs --all
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/remotes/origin/main
0c3d1b1c205d3248bab3061f235ef2309f653b49 refs/stash
0b624edf4a556c702b6ed110ef2702570ced1558 refs/tags/v1.0.0
^0c2cf4371cac2e5d412153dc58293c0cb484c4ba
4f2cc0c5f842120f109977a97bc72acef5aa5ccd refs/tags/v1.0.0-rc1
# The loose files are gone, except the symbolic ref, which cannot be packed:
$ find .git/refs -type f | sort
.git/refs/remotes/origin/HEAD
# The next update writes a loose file again. It wins over the stale packed line:
$ printf 'max_tokens = 256\n' >> config.toml
$ git commit --quiet -am "Add token limit"
$ find .git/refs -type f | sort
.git/refs/heads/main
.git/refs/remotes/origin/HEAD
$ grep refs/heads/main .git/packed-refs
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/heads/main
$ git rev-parse main
a8eea183b656f17da1e2456a2e49995e8388fcb4
```
<!-- /snippet -->

After packing, the only file left is the symbolic ref, which can't be packed. The header lists the traits of the file. An annotated tag is followed by a `^` line with the commit it points at. After the commit, the loose file is back and wins: `git rev-parse main` prints the new ID, while the `packed-refs` line still shows the old one.

**[ANIMATION]** step: where.3

In the picture, `main` has moved to `a8eea18`. The stale line still says `0c2cf43`, and the loose file wins.

**[ANIMATION]** end

**[ON SCREEN]** The root-cause box of section 3.9.

```text
Observed behavior : a release script runs "cat .git/refs/heads/main" and finds no file; a variant greps
                    packed-refs and stamps the build with last week's commit
Git state         : main was packed by git gc (or arrived packed from git clone), then moved on
Mechanism         : lookup reads the loose file first and packed-refs second; maintenance moves loose
                    refs into packed-refs; a later update writes a new loose file and leaves the old line
Root cause        : the scripts read one of several storage locations instead of asking Git
Why Git does this : one file per ref wastes space and is slow with thousands of refs
Correct fix       : git rev-parse --verify refs/heads/main
Prevention        : never read .git/refs or packed-refs from a script; use rev-parse, for-each-ref,
                    update-ref and symbolic-ref, which also work with reftable
```

Read the root-cause line of the box: the scripts read one of several storage locations instead of asking Git.

**[TERMINAL]** Root refs.

```bash
labs/run ch03/root-refs
```

```bash
git fetch origin
cat .git/FETCH_HEAD
git rev-parse FETCH_HEAD
```

<!-- snippet: ch03/root-refs/01-fetch-head -->
```text
$ git fetch origin
# One line per fetched branch: object ID, a marker for "git pull", and where it came from.
$ cat .git/FETCH_HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba		branch 'main' of ../server
62001eb879c6506f6d3c8e625dfadfa5029367b7	not-for-merge	branch 'feature/batching' of ../server
# Used as a revision, FETCH_HEAD means its first line:
$ git rev-parse FETCH_HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

One line per fetched branch: an ID, a marker for `git pull`, and where it came from. Used as a revision, `FETCH_HEAD` means its first line.

```bash
git merge --no-commit topic/metrics topic/tracing
cat .git/MERGE_HEAD
cat .git/ORIG_HEAD
```

<!-- snippet: ch03/root-refs/02-merge-head -->
```text
# A merge of two branches at once, stopped before the commit is made:
$ git merge --no-commit topic/metrics topic/tracing
Fast-forwarding to: topic/metrics
Trying simple merge with topic/tracing
Automatic merge went well; stopped before committing as requested
# MERGE_HEAD holds one line per branch being merged. ORIG_HEAD holds where main was:
$ cat .git/MERGE_HEAD
228726e45b0adbf88785b4d004845222a7d5e973
67b8eefa35c8ad680fc5cb88ec2d028ba2c09cc6
$ cat .git/ORIG_HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
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
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
ORIG_HEAD
refs
```
<!-- /snippet -->

`MERGE_HEAD` holds two lines, one per branch being merged. That is the "different semantics": a list of IDs where a ref holds exactly one.

```bash
git for-each-ref --include-root-refs | grep -v refs/
git update-ref ORIG_HEAD HEAD~1
git update-ref MERGE_HEAD HEAD~1
git reflog exists ORIG_HEAD; echo "exit status: $?"
git merge --abort
```

<!-- snippet: ch03/root-refs/03-root-refs -->
```text
# The refs outside refs/, as Git lists them. The two pseudorefs are not in the list:
$ git for-each-ref --include-root-refs | grep -v refs/
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	ORIG_HEAD
# A root ref is an ordinary ref, so update-ref writes it. A pseudoref is refused:
$ git update-ref ORIG_HEAD HEAD~1
[exit status: 0]
$ git update-ref MERGE_HEAD HEAD~1
fatal: update_ref failed for ref 'MERGE_HEAD': refusing to update pseudoref 'MERGE_HEAD'
[exit status: 128]
$ git reflog exists ORIG_HEAD; echo "exit status: $?"
exit status: 1
$ git merge --abort
```
<!-- /snippet -->

HEAD and `ORIG_HEAD` are listed. The two pseudorefs aren't. `ORIG_HEAD` accepts an update like any ref, and has no reflog. `MERGE_HEAD` is refused.

Now the incident property. This step ends with `git gc --prune=now`, 🔴: it removes every unreachable object at once. Preview with `git fsck --unreachable` and `git prune -n`. Recover only from another clone or a backup. It's never routine maintenance.

```bash
git fetch ../teammate fix/timeout
git log --oneline -1 FETCH_HEAD
git fsck
git gc --quiet --prune=now
cat .git/FETCH_HEAD
git log --oneline -1 FETCH_HEAD
```

A quick quiz. A teammate's commit is named by `FETCH_HEAD` and by nothing else. Does it survive the collection: yes or no? Your answer?

**[PAUSE]**

<!-- snippet: ch03/root-refs/04-not-a-starting-point -->
```text
# A branch of a teammate, fetched by path without a destination ref. It lands in FETCH_HEAD only:
$ git fetch ../teammate fix/timeout
From ../teammate
 * branch            fix/timeout -> FETCH_HEAD
$ git log --oneline -1 FETCH_HEAD
25623b2 Lower the timeout to 20 seconds
# No ref under refs/ and no reflog entry names that commit, so fsck reports it.
# (The dangling tree is the result of the two-branch merge that was aborted above.)
$ git fsck
dangling commit 25623b2b4f51bc94cebfa8e80099a56f6b754270
dangling tree 7396eea3ac2000acc286f477277694a681054728
# A garbage collection without a grace period deletes it. The name stays behind and names nothing:
$ git gc --quiet --prune=now
$ cat .git/FETCH_HEAD
25623b2b4f51bc94cebfa8e80099a56f6b754270		branch 'fix/timeout' of ../teammate
$ git log --oneline -1 FETCH_HEAD
fatal: bad object FETCH_HEAD
[exit status: 128]
```
<!-- /snippet -->

It doesn't. The name stays behind and names nothing: "bad object FETCH_HEAD". If you said yes, that's the trap: the name looks like a ref. Give such a commit a ref before you rely on it: `git fetch <url> <branch>:refs/heads/review/<name>`, or `git switch -c review/<name> FETCH_HEAD`.

**[TERMINAL]** Lab 17.3, up to the checkpoint.

```bash
labs/run ch03/lab-17-3-special-refs-tour
```

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

The lab visits every special name through a fetch, a reset, a merge, a cherry-pick, a revert, a rebase, a bisect and a stash. At the checkpoint no operation is in progress and three leftovers remain: `FETCH_HEAD`, `ORIG_HEAD` and `AUTO_MERGE`. None of them describes unfinished work. The failure and the recovery are yours.

## COMMON MISTAKES

Five mistakes to watch for.

1. Reading `.git/refs/heads/<branch>` in a script. Root cause: the ref may be a line in `packed-refs`, so the script reads one of several storage locations instead of asking Git.
2. Grepping `packed-refs` for a branch. Root cause: a later update writes a loose file and leaves the old line stale.
3. Relying on `FETCH_HEAD` or `ORIG_HEAD` to keep a commit. Root cause: apart from HEAD, root refs and pseudorefs are not starting points for reachability.
4. Testing for a file to ask "is a merge in progress?". Root cause: root refs are not files in every format; resolve the name with `git rev-parse --verify --quiet MERGE_HEAD`.
5. Expecting a deleted branch's reflog to remain. Root cause: deleting a branch deletes its log.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: where.3

**[ANIMATION]** say: A_script_that_walks_.git/refs/heads_sees_only_the_loose_files

Now, out of the lab. Picture a platform team that lists stale branches for a weekly clean-up report. Their first script walked `.git/refs/heads` and missed most branches on the build server, where refs are packed. The replacement is one command: `git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads`, which lists branches by age and needs no parsing. `git branch --format` and `git tag --format` accept the same language.

**[ANIMATION]** step: logs.6

**[ANIMATION]** say: A_reflog_is_local,_and_a_deleted_branch_loses_its_own

Two more habits from the same team. Before a risky rewrite, `git reflog show <branch>` is the cheapest insurance, and deleting a branch cancels its policy. And the reflog is local: it isn't pushed, and a clone starts with an empty one.

## PRACTICE EXERCISE

Your turn. Do Lab 17.3, "A tour of every special ref and file", in [`lab-manual/m17-index-refs-gitdir.md`](../../lab-manual/m17-index-refs-gitdir.md). Before each operation, predict which special name it will write, what the name will hold, and when it will disappear. Check with `ls -A .git` and with the plumbing, not with your memory.

The challenge is Exercise 17.7, "A branch that Git ignores", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 81 of the CTO question bank:

> "A release script reads `.git/refs/heads/main` and checks that the content is forty hexadecimal digits. It has worked for years and now fails in two repositories with two different errors. Explain both root causes at the storage level, and state the rule that prevents this class of failure."

A strong answer treats the two failures separately and names, for each, where the ref's value is and what the file the script reads contains or doesn't contain. Part of this answer needs the two storage formats of the video after next, so come back to it then. It closes with one rule, stated as a rule, and the commands that implement it.

## RECAP

**[ANIMATION]** step: refs.state-6

Let's land this. A ref is a name, where it's kept is Git's business, and you ask Git.

You should now be able to say:

- A ref is a loose file, a line in `packed-refs`, or both; the loose file is read first.
- Plumbing reads and writes refs in every format: `for-each-ref`, `show-ref`, `update-ref`, `symbolic-ref`.
- Since Git 2.46, only `FETCH_HEAD` and `MERGE_HEAD` are pseudorefs; `ORIG_HEAD` and its relatives are root refs.
- Apart from HEAD, none of them keeps an object alive.
- Reflogs are files under `logs/`; tags have none by default, and a deleted branch loses its own.

## HOMEWORK

Read sections 3.9 to 3.11 of [Chapter 3](../../textbook/ch03-git-internals.md). Do Exercise 17.2, "Loose refs and packed refs", and Exercise 17.3, "Refs by plumbing", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

Today you found every place a ref can live, and you learned to ask Git instead of reading files. Do the lab before the next video: the index file as a data structure. Until then, look at the state first and type second. See you in the next one.

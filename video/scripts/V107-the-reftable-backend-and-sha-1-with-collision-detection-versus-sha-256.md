# V107: The reftable backend, and SHA-1 with collision detection versus SHA-256

- **Part.** 4: Git internals
- **Module.** 17, 42
- **Planned minutes.** 22
- **Prerequisites.** V105
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), sections 3.13 and 3.14 (with the tables of 3.15 to 3.18)
- **Demo scripts.** `labs/ch03/reftable.sh`, `labs/ch03/sha256.sh`, `labs/ch03/lab-17-2-files-vs-reftable.sh`

## HOOK

**[ON SCREEN]** The same release script, two repositories, two errors.

Two videos ago a release script failed because it read `.git/refs/heads/main` and the ref was packed. A ref is a name, such as a branch, that holds a commit ID. Suppose the team patched it: the script now reads the file if it exists and greps `packed-refs` otherwise, and it checks that the result is forty hexadecimal digits.

It will fail again, in two new ways. In one repository, `.git/refs/heads` isn't a directory at all. It's a file that says "this repository uses the reftable format". In another, the commit ID is correct and has sixty-four digits.

Neither repository is damaged. Both use storage formats that Git supports today and plans as defaults for new repositories in Git 3.0. This video shows both formats and what stays the same across them. Keep those two failures in mind. Both come back.

## INTRODUCTION

**[ANIMATION]** walk: columns=the_choice,Git_2.55_default,the_alternative rows=ref_format,_how_names_are_stored:files:reftable|object_format,_which_hash_names_objects:SHA-1:SHA-256 title=Two_independent_choices,_made_when_a_repository_is_created mono=off id=choices

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Two independent choices are made when a repository is created. The ref format: how names are stored. The object format: which hash function names the objects. A hash function computes an object's ID from its bytes. Git 2.55 defaults to `files` and SHA-1. The alternatives are reftable and SHA-256.

**[ANIMATION]** end

Three replays from `labs/ch03`: `reftable.sh`, `sha256.sh`, and the replay of Lab 17.2 up to its checkpoint.

One labelled command is discussed and not run in the two demos: `git refs migrate --ref-format=reftable`, 🟡 CAUTION. It changes the ref storage format and keeps the values. Preview it with `--dry-run`. Recover by migrating back, or by restoring the copy of `.git` you made first.

## LEARNING OBJECTIVES

After this video you can:

- Create a repository with the reftable backend and show what replaces the ref files.
- Show that ref plumbing gives the same answers in both backends.
- Say what breaks when tools read `.git/refs` directly.
- Create a SHA-256 repository and state why it cannot exchange objects with a SHA-1 repository.
- State what Git 3.0 plans for new repositories, as the section gives it.

## CONCEPT

Reftable first. In one sentence: reftable stores refs and reflogs in binary, block-structured tables under `.git/reftable/` instead of in loose files, `packed-refs` and `logs/`. It has been available since Git 2.45 and is planned as the default for new repositories in Git 3.0. A reflog is the journal of the values a ref has had.

**[ANIMATION]** cards: cards=two_names_that_differ_only_in_case:cannot_both_be_stored_on_macOS_and_Windows|deleting_a_packed_ref:rewrites_the_whole_packed-refs_file|multi-ref_updates:are_not_atomic title=Three_problems_of_the_files_format numbered=on id=why

Why does it exist? The project gives three reasons. The `files` format can't store two refs whose names differ only in case on the case-insensitive filesystems of macOS and Windows. Deleting a packed ref rewrites the whole `packed-refs` file. And multi-ref updates aren't atomic. Reftable compacts geometrically after every write and uses prefix compression.

**[ANIMATION]** stores: boxes=reftable/tables.list:oldest_first|after_git_pack-refs_--all:compacted rows=1:A:one_table:_updates_1_to_3|1:A:one_table:_update_4,_the_tag@hl|2:B:one_table:_updates_1_to_4 arrows=2:A>B:merged title=A_stack_of_tables say_1=Every_transaction_adds_a_thin_table_on_top say_2=Thin_tables_are_merged_into_a_thick_one._A_table_is_never_amended id=tables at_1=15

**[ANIMATION]** step: 1

Now precisely. The tables live in `$GIT_DIR/reftable/`, and the file `tables.list` names the ones in use, oldest first. A table name is its first and last update number and a random suffix. Each table starts with a 24-byte header: `REFT`, a version byte, a block size, and the range of update numbers it covers.

**[ANIMATION]** stores: boxes=files_backend:.git|*reftable_backend:.git rows=1:A:HEAD_-_ref:_refs/heads/main|1:A:refs/heads/_-_one_file_per_loose_ref|1:A:packed-refs_-_many_refs_in_one_file|1:A:logs/_-_one_reflog_file_per_ref|2:B:HEAD_-_ref:_refs/heads/.invalid_(stub)@hl|2:B:refs/heads_-_a_regular_file_(stub)@hl|3:B:reftable/tables.list_-_the_tables_in_use|3:B:reftable/*.ref_-_refs_and_reflogs|4:A:config|4:B:config_-_extensions.refstorage_=_reftable|4:B:config_-_core.repositoryformatversion_=_1|5:A:MERGE__HEAD,_FETCH__HEAD_-_files@ok|5:B:MERGE__HEAD,_FETCH__HEAD_-_files@ok title=Two_.git_directories_side_by_side say_2=Two_stubs_stay_for_tools_that_look_for_them say_3=No_packed-refs_and_no_logs/:_refs_and_reflogs_are_in_the_tables say_5=The_two_pseudorefs_are_files_in_both_formats id=layout

**[ANIMATION]** step: 4

Two stubs stay for tools that look for them: `.git/HEAD` containing `ref: refs/heads/.invalid`, and `.git/refs/heads` as a regular file. The format is declared by `extensions.refstorage = reftable` with `core.repositoryformatversion = 1`, and a Git that doesn't know the extension must refuse the repository.

**[ANIMATION]** cards: cards=git_init_or_git_clone:--ref-format=reftable|init.defaultRefFormat:a_setting,_since_Git_2.47|git_refs_migrate:since_Git_2.46,_for_an_existing_repository title=Three_ways_in numbered=on id=ways at_2=40 at_3=62

**[ANIMATION]** step: 3

There are three ways in. `git init --ref-format=reftable`, or `git clone --ref-format=reftable`. The setting `init.defaultRefFormat`, since Git 2.47. Or, for an existing repository, `git refs migrate --ref-format=reftable`, since Git 2.46, which can't migrate a repository with linked worktrees and must not run while anything else writes.

**[ANIMATION]** say: The_ref_format_is_local_to_each_repository

The ref format is local to each repository. A `files` clone fetches from a reftable server, and the other way round.

**[ANIMATION]** hash: differs=byte steps=one,same left=git_hash-object_in_sha256-repo right=shasum_-a_256,_outside_Git lines=blob_16,\0,retry__limit_=_3 alt=retry__limit_=_3 ids=ca399e7a...,ca399e7a... fn=SHA-256 same=The_same_bytes_through_the_same_function_give_the_same_ID title=SHA-256:_another_hash_function,_the_same_object id=same256

**[ANIMATION]** step: one

Now the object format. In one sentence: Git names objects with SHA-1 by default, computed by an implementation that detects attempted collision attacks, and can create repositories that use SHA-256 instead. The two kinds can't exchange objects, and a repository that must live on GitHub stays SHA-1. A collision is two different contents with the same hash.

**[ANIMATION]** cards: cards=created_by:git_init_--object-format=sha256|fixed:for_the_life_of_the_repository|covers:object_IDs,_the_index_checksum,_the_pack_checksums|no_interoperability:with_SHA-1_repositories title=A_SHA-256_repository id=sha at_1=30 at_2=60 at_3=86 at_4=40

Since Git 2.13 the default SHA-1 code is the collision-detecting variant, "SHA1_DC", which recognises the patterns of the known attacks on SHA-1. SHA-256 repositories were experimental in 2.29 and are a supported format since 2.42. You create one with `git init --object-format=sha256`. It's declared by `extensions.objectformat = sha256`, and it's fixed for the life of the repository: changing the setting afterwards, the documentation says, "will not work and will produce hard-to-diagnose issues". The format applies to object IDs, the index checksum and the pack checksums alike. And the documentation states "no interoperability between SHA-256 repositories and SHA-1 repositories". A clone adopts the format of what it clones.

**[ANIMATION]** cards: cards=SHA-256:conditional,_with_no_plan_to_deprecate_SHA-1|reftable|main:as_the_initial_branch title=Planned_defaults_for_new_repositories_in_Git_3.0:_unreleased,_no_date id=plan

The Git 3.0 plans, exactly as the chapter gives them: for new repositories, SHA-256 and reftable as defaults, and `main` as the initial branch. The plan for SHA-256 is conditional on libraries, applications and forges being ready, with no plan to deprecate SHA-1. Git 3.0 is unreleased, and the official documentation gives no date.

**[ANIMATION]** end

**[ON SCREEN]** "GitHub, not Git."

GitHub had no publicly available support for SHA-256 repositories on 1 October 2026. A private preview is reported by GitLab's blog, by a community comment and by a conference speaker, but no GitHub blog post, changelog entry or documentation page announces it, so the course marks it unverified. Forgejo supports SHA-256 repositories since v7.0; GitLab announced experimental support in August 2024. Every repository in this course that touches GitHub therefore stays SHA-1.

**[ANIMATION]** step: why.3

**[ANIMATION]** say: Adopt_it_where_it_solves_a_problem_you_have,_after_checking_every_tool

When to adopt reftable: where it solves a problem you have. Branch names that collide on a case-insensitive disk, tens of thousands of refs, or automation that updates many refs at once. When not: before you've checked every tool that opens the repository. A tool built on an older Git library refuses such a repository. The repository is fine. The tool is behind.

## MENTAL MODEL

**[ANIMATION]** step: tables.2

The textbook's analogy for reftable: a stack of ledgers instead of a drawer of index cards. Every transaction adds a thin ledger on top. From time to time thin ledgers are merged into a thick one, and a lookup reads the stack from the newest down.

The analogy breaks at correction: a ledger page could be amended, a table never is.

**[ANIMATION]** hash: differs=byte lines=blob_16|\0|retry__limit_=_3 fn=SHA-1 fn2=SHA-256 ids=f784b58423ef67be5af8d1cfdfd9bea5eaa26bae,ca399e7aeebdebc3e8ae90cbb2d8cab88b72cd16ebf654d483f48652356f1d68 steps=one,different left=in_sha1-repo right=in_sha256-repo diff=The_same_bytes,_two_functions,_two_IDs:_40_digits_and_64 title=What_differs_is_how_long_an_ID_is id=two

For both formats, hold one model: the format is a property of the repository, not of Git. The names and the objects are the same things in every format. What differs is where the bytes are, and how long an ID is. Plumbing, Git's low-level commands, hides the first difference. `git rev-parse --show-object-format` tells you the second.

## DIAGRAM

**[ANIMATION]** step: layout.4

**[DIAGRAM]** Two `.git` directories side by side. Mark the entries that differ.

```text
   files backend                              reftable backend

   .git/HEAD        ref: refs/heads/main      .git/HEAD        ref: refs/heads/.invalid      (stub)
   .git/refs/heads/ one file per loose ref    .git/refs/heads  a regular file, not a ref     (stub)
   .git/packed-refs many refs in one file     (none)
   .git/logs/       one reflog file per ref   (none)
   (none)                                     .git/reftable/tables.list   the tables in use
                                              .git/reftable/*.ref         refs and reflogs
   .git/config                                .git/config      extensions.refstorage = reftable
                                                               core.repositoryformatversion = 1
   .git/MERGE_HEAD, .git/FETCH_HEAD: files in both formats (the two pseudorefs)
```

On the left, what you know: HEAD as a text file naming a branch, a directory of loose refs, `packed-refs`, and `logs/`.

**[ANIMATION]** say: On_the_right:_two_stubs,_no_packed-refs,_no_logs/

On the right: HEAD is still a file, and it's a stub. `refs/heads` is a regular file, also a stub. There's no `packed-refs` and no `logs/`. The refs and the reflogs are in the tables under `reftable/`.

**[ANIMATION]** step: 5

The bottom line is the same on both sides: `MERGE_HEAD` and `FETCH_HEAD` are files in every format. That's what makes them pseudorefs.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch03/reftable
```

```bash
git init --ref-format=reftable inference-service
cd inference-service
git rev-parse --show-ref-format
cat .git/config
```

<!-- snippet: ch03/reftable/01-init -->
```text
$ git init --ref-format=reftable inference-service
Initialized empty Git repository in $LAB/ch03/reftable/inference-service/.git/
$ cd inference-service
$ git rev-parse --show-ref-format
reftable
$ cat .git/config
[extensions]
	refstorage = reftable
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

`git init` is 🟢. Look at the two lines of the configuration: `refstorage = reftable` under `extensions`, and `repositoryformatversion = 1`.

```bash
ls -A .git
cat .git/HEAD
cat .git/refs/heads
git symbolic-ref HEAD
```

The repository is on `main`. What does the file `.git/HEAD` contain? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch03/reftable/02-stubs -->
```text
$ ls -A .git
config
description
HEAD
hooks
info
objects
refs
reftable
# Two stub files are kept for tools that look for them. Neither holds a ref:
$ cat .git/HEAD
ref: refs/heads/.invalid
$ cat .git/refs/heads
this repository uses the reftable format
# The real answer comes from Git:
$ git symbolic-ref HEAD
refs/heads/main
```
<!-- /snippet -->

`ref: refs/heads/.invalid`. Neither stub holds a ref. The real answer comes from Git: `git symbolic-ref HEAD` prints `refs/heads/main`. This is what breaks a tool that reads `.git/refs` directly: it finds a file where it expects a directory, and a HEAD that names nothing. That's the first failure of the hook.

```bash
printf 'retry_limit = 3\n' > config.toml
git add config.toml
git commit --quiet -m "Add service configuration"
git branch feature/batching
git tag -a v1.0.0 -m "Release 1.0.0"
git pack-refs --all
```

<!-- snippet: ch03/reftable/03-tables -->
```text
$ printf 'retry_limit = 3\n' > config.toml
$ git add config.toml
$ git commit --quiet -m "Add service configuration"
$ git branch feature/batching
$ git tag -a v1.0.0 -m "Release 1.0.0"
# Refs and reflogs live in binary tables. tables.list names the tables in use, oldest first.
# A table name is first update number, last update number and a random suffix (masked here).
$ sed -E 's/-[0-9a-f]{8}\./-<random>./' .git/reftable/tables.list
0x000000000001-0x000000000003-<random>.ref
0x000000000004-0x000000000004-<random>.ref
# Compaction merges tables. Git does it on its own; git pack-refs asks for it explicitly:
$ git pack-refs --all
$ sed -E 's/-[0-9a-f]{8}\./-<random>./' .git/reftable/tables.list
0x000000000001-0x000000000004-<random>.ref
# The 24-byte header: REFT, version 1, block size, first and last update number.
$ head -c 24 .git/reftable/*.ref | xxd
00000000: 5245 4654 0100 1000 0000 0000 0000 0001  REFT............
00000010: 0000 0000 0000 0004                      ........
```
<!-- /snippet -->

The commit wrote update 2, the branch update 3, the tag update 4. Auto-compaction had already merged updates 1 to 3 into one table, and `git pack-refs --all` merged all four. The header bytes read `REFT`, version 1, the block size of 4,096 bytes, then update numbers 1 and 4.

```bash
ls -A .git
git for-each-ref
git reflog show feature/batching
git rev-parse main
```

<!-- snippet: ch03/reftable/04-same-answers -->
```text
# No logs directory and no packed-refs file. Plumbing answers as in any other repository:
$ ls -A .git
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
$ git for-each-ref
849357d27dcaa9267a13a0be93d3ea0b5c52ea01 commit	refs/heads/feature/batching
849357d27dcaa9267a13a0be93d3ea0b5c52ea01 commit	refs/heads/main
90350c8a07136a48c3b158534161e6057047243a tag	refs/tags/v1.0.0
$ git reflog show feature/batching
849357d feature/batching@{0}: branch: Created from main
$ git rev-parse main
849357d27dcaa9267a13a0be93d3ea0b5c52ea01
```
<!-- /snippet -->

No `logs/`, no `packed-refs`, and every plumbing command answers as before. The reflog of the branch is in the same tables as the branch.

A conflicted merge, to see where the root refs are kept.

A quick quiz. After the merge stops: which of `MERGE_HEAD`, `ORIG_HEAD` and `AUTO_MERGE` will `ls -A .git` show as files? All three, two, or one? Your answer?

**[PAUSE]**

<!-- snippet: ch03/reftable/05-root-refs -->
```text
# A conflicted merge, to see where the refs outside refs/ are kept in this format:
$ git switch --quiet feature/batching && printf 'retry_limit = 4\n' > config.toml && git commit --quiet -am 'Allow four retries'
$ git switch --quiet main && printf 'retry_limit = 5\n' > config.toml && git commit --quiet -am 'Allow five retries'
$ git merge feature/batching
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# MERGE_HEAD is a file, as in every repository. ORIG_HEAD and AUTO_MERGE are not files here:
$ ls -A .git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
refs
reftable
$ git for-each-ref --include-root-refs | grep -v refs/
4c07605aeed786c4596df1b9212ab37962730b08 tree	AUTO_MERGE
1dd74b5d1a428941e018b4c2f6f98f0559cc5b27 commit	HEAD
1dd74b5d1a428941e018b4c2f6f98f0559cc5b27 commit	ORIG_HEAD
$ git merge --abort
```
<!-- /snippet -->

One: only `MERGE_HEAD`. `ORIG_HEAD` and `AUTO_MERGE` are refs and live in the tables, and `git for-each-ref --include-root-refs` lists them. This is the cleanest demonstration of the root-ref and pseudoref distinction.

```bash
git branch Hotfix
git branch hotfix
git branch --list "[Hh]otfix"
git branch feature
```

<!-- snippet: ch03/reftable/06-names -->
```text
# Names that differ only in case are two refs here, on a filesystem that ignores case:
$ git branch Hotfix
$ git branch hotfix
$ git branch --list "[Hh]otfix"
  Hotfix
  hotfix
# The same two commands in a files-format repository on the same disk:
$ git init --quiet ../files-repo
$ git -C ../files-repo commit --quiet --allow-empty -m "Start"
$ git -C ../files-repo branch Hotfix
$ git -C ../files-repo branch hotfix
fatal: a branch named 'hotfix' already exists
[exit status: 128]
# One rule of the files layout is kept: a ref cannot be both a name and a prefix of names.
$ git branch feature
fatal: 'refs/heads/feature/batching' exists; cannot create 'refs/heads/feature'
[exit status: 128]
```
<!-- /snippet -->

Two branches whose names differ only in case, on a filesystem that ignores case. In the `files` repository on the same disk, the second is refused. One rule is kept on purpose: `feature` and `feature/batching` can't both exist, so that repositories stay interchangeable.

<!-- snippet: ch03/reftable/07-git-3-preview -->
```text
# The two formats that Git 3.0 plans as defaults for new repositories can be chosen today:
$ git init --quiet --object-format=sha256 --ref-format=reftable ../future-repo
$ cat ../future-repo/.git/config
[extensions]
	objectformat = sha256
	refstorage = reftable
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

Both planned formats can be chosen today, with `--object-format=sha256 --ref-format=reftable`. Use that in throwaway repositories.

**[TERMINAL]** The object format.

```bash
labs/run ch03/sha256
```

```bash
git version --build-options | grep -e SHA -e default
```

<!-- snippet: ch03/sha256/01-build -->
```text
# What this Git was built with:
$ git version --build-options | grep -e SHA -e default
SHA-1: SHA1_DC
SHA-256: SHA256_BLK
default-ref-format: files
default-hash: sha1
```
<!-- /snippet -->

`SHA-1: SHA1_DC`: the collision-detecting implementation. And the two defaults of this build: `files` and `sha1`.

```bash
git init --quiet sha1-repo
git init --quiet --object-format=sha256 sha256-repo
git -C sha1-repo rev-parse --show-object-format
git -C sha256-repo rev-parse --show-object-format
```

<!-- snippet: ch03/sha256/02-init -->
```text
$ git init --quiet sha1-repo
$ git init --quiet --object-format=sha256 sha256-repo
$ cat sha256-repo/.git/config
[extensions]
	objectformat = sha256
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
$ git -C sha1-repo rev-parse --show-object-format
sha1
$ git -C sha256-repo rev-parse --show-object-format
sha256
```
<!-- /snippet -->

Try it now, thirty seconds, in a repository in the lab shell: run `git rev-parse --show-object-format`, then `git rev-parse --show-ref-format`. I'll wait.

**[PAUSE]**

With the defaults of Git 2.55 you read `sha1` and `files`. Two words, and you know both formats.

```bash
git -C sha1-repo hash-object config.toml
git -C sha256-repo hash-object config.toml
printf 'blob 16\0retry_limit = 3\n' | shasum -a 256
```

A quick quiz. The same sixteen bytes in both repositories. Is the object stored differently, or only named differently? Your answer?

**[PAUSE]**

<!-- snippet: ch03/sha256/03-ids -->
```text
# The same sixteen bytes, hashed by each repository:
$ printf 'retry_limit = 3\n' > sha1-repo/config.toml
$ cp sha1-repo/config.toml sha256-repo/config.toml
$ git -C sha1-repo hash-object config.toml
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae
$ git -C sha256-repo hash-object config.toml
ca399e7aeebdebc3e8ae90cbb2d8cab88b72cd16ebf654d483f48652356f1d68
# The object format is the same; only the hash function differs:
$ printf 'blob 16\0retry_limit = 3\n' | shasum -a 256
ca399e7aeebdebc3e8ae90cbb2d8cab88b72cd16ebf654d483f48652356f1d68  -
$ git -C sha256-repo log --oneline
ecfdab6 Add service configuration
$ git -C sha256-repo cat-file -p HEAD
tree 13e25952da64d7ebd81886b745d0ddef276fe0249a4869054efe6b27a72675b5
author Lab User <you@example.com> 1788756240 +0530
committer Lab User <you@example.com> 1788756240 +0530

Add service configuration
$ cat sha256-repo/.git/refs/heads/main
ecfdab60723aa25daa18b6d1de7fba739cdd5c2013ef47d827cc33d48261bfb5
```
<!-- /snippet -->

Only named differently. The same `blob 16`, the same NUL, the same sixteen bytes, and `shasum -a 256` agrees with Git. Everything in that repository now carries 64-digit IDs: the tree header of the commit, and the ref.

**[ANIMATION]** step: same256.same

The same bytes through the same function, inside Git or outside it, give the same ID.

**[ANIMATION]** end

```bash
git -C sha1-repo fetch ../sha256-repo main
git -C sha1-repo push ../sha256-repo main:refs/heads/from-sha1
git -C sha256-repo push ../sha1-repo main:refs/heads/from-sha256
git clone --quiet sha256-repo sha256-clone
```

<!-- snippet: ch03/sha256/04-no-interop -->
```text
# The two formats cannot exchange objects, in either direction:
$ git -C sha1-repo fetch ../sha256-repo main
fatal: mismatched algorithms: client sha1; server sha256
[exit status: 128]
$ git -C sha1-repo push ../sha256-repo main:refs/heads/from-sha1
fatal: the receiving end does not support this repository's hash algorithm
fatal: the remote end hung up unexpectedly
[exit status: 128]
$ git -C sha256-repo push ../sha1-repo main:refs/heads/from-sha256
fatal: the receiving end does not support this repository's hash algorithm
fatal: the remote end hung up unexpectedly
[exit status: 128]
# A clone adopts the format of what it clones:
$ git clone --quiet sha256-repo sha256-clone
$ git -C sha256-clone rev-parse --show-object-format
sha256
```
<!-- /snippet -->

"Mismatched algorithms: client sha1; server sha256", and in both push directions "the receiving end does not support this repository's hash algorithm". There's no conversion. The fix is to recreate one side in the other format.

<!-- snippet: ch03/sha256/05-forty-hex -->
```text
# A check that assumes forty hexadecimal digits accepts one repository and rejects the other:
$ git -C sha1-repo rev-parse HEAD | grep -E -c '^[0-9a-f]{40}$'
1
$ git -C sha256-repo rev-parse HEAD | grep -E -c '^[0-9a-f]{40}$'
0
```
<!-- /snippet -->

And the second failure of the hook: a check that assumes forty hexadecimal digits accepts one repository and rejects the other.

**[TERMINAL]** Lab 17.2, up to the checkpoint.

```bash
labs/run ch03/lab-17-2-files-vs-reftable
```

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

The lab builds the same history in both backends. On disk they differ, as in the diagram. Asked through Git, they give the same answers, ID for ID. The lab's failure scenario is a fetch that collides on a case-insensitive filesystem, and its recovery uses the migration. Those are yours.

## COMMON MISTAKES

Five mistakes to watch for.

1. Reading `.git/HEAD` or `.git/refs` in a tool. Root cause: in a reftable repository both are stubs and the refs are in binary tables.
2. Validating a commit ID as forty hexadecimal digits. Root cause: the length is a property of the repository's object format, not of Git.
3. Editing `extensions.objectFormat` or `extensions.refStorage` in `.git/config`. Root cause: they are set by `git init` and `git refs migrate`; editing them corrupts the repository.
4. Trying to push a SHA-256 repository to a SHA-1 remote. Root cause: there is no interoperability between the two object formats, and no conversion.
5. Migrating a shared repository while it is in use. Root cause: `git refs migrate` must not run while anything else writes, and linked worktrees block it.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: why.3

**[ANIMATION]** say: Names_that_differ_only_in_case:_the_problem_this_team_has

Now, out of the lab. An ML team has contributors on Linux and on macOS. Someone on Linux pushes a branch `Fix/tokenizer` while `fix/tokenizer` exists. On the Macs, `git fetch` now complains about a case-insensitive filesystem. The diagnosis: `git ls-remote` shows names that differ only in case, and `git rev-parse` and `git for-each-ref` disagree. Two fixes are available. Rename a branch on the server, and add a branch naming rule. Or migrate the affected clones with `git refs migrate --ref-format=reftable`. The server stays as it is, because the ref format is local.

**[ANIMATION]** step: ways.3

**[ANIMATION]** say: Before_migrating:_check_every_tool,_stop_all_writers,_no_linked_worktrees

Before migrating the shared build repository, the same team checks every tool that opens it, stops all writers, and remembers that linked worktrees block the migration. Their repositories that are pushed to GitHub stay SHA-1.

## PRACTICE EXERCISE

Your turn. Do Lab 17.2, "The `files` backend versus reftable", in [`lab-manual/m17-index-refs-gitdir.md`](../../lab-manual/m17-index-refs-gitdir.md). Before you list each `.git` directory, predict which entries exist in one and not in the other. Before each plumbing command, predict whether the two repositories answer identically.

The challenge is Exercise 16.8, "Scripts that read `.git` by hand", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md). With this video you can now answer every part of it, and Question 81 from the refs video.

## INTERVIEW QUESTION

Question 86 of the CTO question bank:

> "When would you migrate a repository to reftable, what breaks if you do it carelessly, and what stays the same?"

A strong answer starts with the problems that reftable solves and says which of them the team has. It lists the preconditions of the migration command and the tools that must be checked. For "what stays the same" it names the layer at which nothing changes and the commands that prove it. It keeps the Git 3.0 plan a plan.

## RECAP

**[ANIMATION]** step: choices.2

**[ANIMATION]** say: The_format_belongs_to_the_repository._You_ask_Git

Let's land this. The format belongs to the repository, the names and the objects stay the same, and you ask Git.

You should now be able to say:

- Reftable keeps refs and reflogs in binary tables; `.git/HEAD` and `.git/refs/heads` remain as stubs.
- Ref plumbing gives the same answers in both backends; only the two pseudorefs are files in both.
- Git's SHA-1 implementation detects known collision attacks; SHA-256 is a separate object format with 64-digit IDs and no interoperability.
- Decide the object format at `git init`; keep repositories for GitHub in SHA-1.
- Git 3.0 plans SHA-256 and reftable as defaults for new repositories, conditionally, with no date.

## HOMEWORK

Read sections 3.13 to 3.17 of [Chapter 3](../../textbook/ch03-git-internals.md) and do the Practice section 3.19.

Today you met both formats that Git 3.0 plans, and you know what stays the same across them. Do the lab before the next video: the commit-graph, the multi-pack-index and reachability bitmaps. Until then, look at the state first and type second. See you in the next one.

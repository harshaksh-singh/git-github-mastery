# V100: The four object types in full, and reading objects with cat-file, ls-tree and show

- **Part.** 4: Git internals
- **Module.** 16
- **Planned minutes.** 22
- **Prerequisites.** V099
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), sections 3.4 and 3.5
- **Demo scripts.** `labs/ch03/object-types.sh`, `labs/ch03/read-objects.sh`

## HOOK

**[ON SCREEN]** A deploy log: "permission denied" on `run.sh`.

A deploy step fails on the server with "permission denied" on `run.sh`. The same script runs on every laptop in the team. Nobody changed the server. Your CTO asks one calm question: is this a server problem or a repository problem, and how do you prove which?

You can answer in one command, if you know what a tree, Git's listing of one directory, records for each entry, and what it leaves out. The answer is in the object store, and by the end of this video you'll read it there with plumbing, the low-level commands with stable output: from a commit, to its tree, to one entry, to the bytes of one file. Keep that failing deploy in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Last time you opened the `.git` directory and recomputed the ID of a loose object by hand. An object is one unit of Git's storage, named by a hash of its type and content, and a hash is a fixed-length fingerprint. Today: what the four types of object contain, and the three commands that read them, `git cat-file`, `git ls-tree` and `git show`.

All three commands only read. Everything you see me run in this video carries the 🟢 SAFE label: it reads state and changes nothing.

We replay two scripts from `labs/ch03`: `object-types.sh` and `read-objects.sh`. They use the fixed lab clock, so the object IDs on my screen are the IDs printed in Chapter 3 of the book. Compare them as we go.

## LEARNING OBJECTIVES

After this video you can:

- Read the raw form of a tree entry and list the modes Git uses.
- Explain why changing a message three commits back changes the ID of HEAD.
- Read an annotated tag object.
- List every object of a repository with its type and size.
- Walk from a commit to the bytes of one file with plumbing only.

## CONCEPT

Start with why. Every question about what Git has stored comes down to four kinds of object. If you can read each of them in its raw form, no report from Git is a mystery, and no claim about history has to be taken on trust.

**[ANIMATION]** objects: cards=tag:0b624ed:object_0c2cf43+type_commit+tag_v1.0.0+tagger_Lab_User,commit:0c2cf43:tree_31fc0d3+parent_4f2cc0c+parent_62001eb+author_Lab_User+committer_Lab_User+Merge_feature/batching,tree:31fc0d3:100644_60a72d9_config.toml+120000_ac85030_current-model+040000_a67ce55_models+100755_ea66be4_run.sh+040000_c009bc4_src+160000_9eb542d_tokenizer,blob:60a72d9:retry__limit_=_3+timeout__s_=_30+batch__size_=_8 title=Four_types_of_object id=four pace=quick

In one sentence: a blob is the bytes of one file, a tree is one directory listing, a commit is a snapshot with its ancestry and its metadata, and a tag object is a named, dated pointer to another object. A snapshot is the complete state of every tracked file at one moment.

**[ANIMATION]** end

**[ON SCREEN]** The table of section 3.4: type, content, deliberately absent.

What each type leaves out matters as much as what it holds. A blob holds the bytes of a file, or the target path of a symbolic link, a file that only points at another path. It has no name, no mode and no timestamps. A tree holds entries of mode, name and object ID, sorted by name. It doesn't know its own path and it holds no history. A commit holds the headers `tree`, `parent`, `author` and `committer`, some optional headers, a blank line, and the message. It holds no diff and no branch name. A tag object holds the headers `object`, `type`, `tag` and `tagger`, a blank line, the message, and optionally a signature. It gives no guarantee that the ref of the same name still points at it. A ref is a name that holds an object ID.

Now how. Each of the four is one entry in the object database, loose in a file of its own or packed with others, stored and named exactly as you saw in the previous video. The type is the first word of the header.

**[ANIMATION]** walk: columns=mode,the_entry_is,the_ID_names rows=100644:a_regular_file:a_blob|100755:an_executable_file:a_blob|120000:a_symbolic_link:a_blob_holding_the_target|040000:a_directory:another_tree|160000:a_gitlink_(submodule):a_commit_in_another_repository title=The_five_modes_of_a_tree_entry id=modes

**[ANIMATION]** step: 5

Trees first. A tree entry has a mode, and Git uses five of them. `100644` is a regular file, and the ID names a blob. `100755` is an executable file, and the ID names a blob. `120000` is a symbolic link, and the ID names a blob whose content is the link target. `040000` is a directory, and the ID names another tree. `160000` is a gitlink, the record of a submodule, which is another repository checked out inside yours, and the ID names a commit in that other repository. These five are the complete list.

**[ANIMATION]** say: The_executable_bit_is_the_only_permission_Git_records

The modes look like Unix permissions, and they're not. The executable bit is the only permission Git records. Owner, group, the other bits and every timestamp aren't in the repository. A directory exists only as a tree with entries, which is why an empty directory can't be committed.

**[ANIMATION]** graph: b602c1f-4f2cc0c-0c2cf43; ^b602c1f-62001eb; 62001eb-0c2cf43; HEAD=none; title:Every_commit_names_its_parents => + 4f2cc0c tag:v1.0.0-rc1; name:light; title:Two_kinds_of_tag; say:A_lightweight_tag_is_a_ref_that_holds_a_commit_ID => + 0c2cf43 atag:v1.0.0#0b624ed; name:annotated; say:An_annotated_tag_holds_the_ID_of_a_tag_object,_which_names_the_commit id=hist

**[ANIMATION]** step: state-1

Commits next. A commit has exactly one `tree` header: the ID of the top-level tree, the complete snapshot. It has no `parent` header, one, or several, in order. A parent is a commit this one was built on. The first parent is the commit you were on, the second is the one you merged. On screen is today's demo history: four commits, the last with two parents.

**[ANIMATION]** step: four.level-3

**[ANIMATION]** say: One_author_and_one_committer:_name,_email,_seconds,_time_zone

A commit also has one `author` and one `committer`, each with a name, an email, seconds since 1 January 1970 UTC, and a time-zone offset. The committer differs from the author after an amend, a rebase, a cherry-pick or an applied patch. Three headers are optional. `encoding` appears when the message isn't UTF-8. `gpgsig` is a signature over the rest of the commit, with that name for OpenPGP, SSH and X.509 signatures alike. And `mergetag` is the complete signed tag object that this commit merged.

**[ANIMATION]** hash: differs=byte steps=one,same left=commit_271,_a_NUL_byte,_then_this_text right=the_same_bytes,_piped_into_shasum lines=tree_31fc0d3,parent_4f2cc0c,parent_62001eb,author_and_committer_lines,Merge_feature/batching alt=Merge_feature/batching ids=0c2cf43,0c2cf43 same=The_same_text_gives_the_same_ID,_inside_Git_or_outside_it title=A_commit_ID_is_the_hash_of_the_commit's_text

**[ANIMATION]** step: one

The consequence is the centre of this video. A commit ID is the hash of the word `commit`, the size, a NUL byte, which is a byte of value zero, and exactly that text. The text contains the ID of the tree, which contains the IDs of every blob and subtree. It contains the IDs of the parents, which contain the IDs of theirs. One commit ID therefore fixes every file in the snapshot and every commit behind it. Nothing in a commit can be edited. A different message, timestamp or parent is a different text with a different hash. "Amending" and "rebasing" always create new commits.

**[ANIMATION]** step: hist.light

**[ANIMATION]** step: hist.annotated

Tags last. A lightweight tag is a ref that holds a commit ID and nothing else. An annotated tag is a ref that holds the ID of a tag object, and the tag object names the commit, its type, the tag's own name, who tagged and when.

**[ANIMATION]** end

When do you read objects this way? When you need proof: of a file mode, of what a release contains, of what makes a repository large. And when not? For everyday reading, `git show` and `git log` format the same data for a person, and you don't need the raw form.

## MENTAL MODEL

**[ANIMATION]** step: four.level-3

**[ANIMATION]** say: Blobs_are_contents,_trees_put_the_names_back,_a_commit_is_the_cover_sheet

The textbook's analogy is a filesystem taken apart. Blobs are file contents with the name torn off. Trees are the directory pages that put names back. A commit is a dated cover sheet stapled to the top directory page, noting which cover sheets came before.

**[ANIMATION]** say: Change_one_file:_a_new_blob,_new_trees_above_it,_a_new_commit

Here's where the analogy breaks: at mutation. A directory entry in a filesystem points at a place, and the content of that place can change. A tree entry points at content. Change one file, and its blob, every tree above it, and the commit are new objects with new IDs.

**[ANIMATION]** step: hist.annotated

**[ANIMATION]** say: Each_ID_covers_the_IDs_it_contains

Hold that in mind for the interview question at the end. A change anywhere propagates upward through the trees and forward through every descendant commit, because each object's ID covers the IDs it contains.

## DIAGRAM

**[ANIMATION]** objects: cards=tag:0b624ed:object_0c2cf43+type_commit+tag_v1.0.0,commit:0c2cf43:tree_31fc0d3+parent_4f2cc0c_(1st)+parent_62001eb_(2nd),tree:31fc0d3:100644_60a72d9_config.toml+120000_ac85030_current-model+040000_a67ce55_models+100755_ea66be4_run.sh+040000_c009bc4_src+160000_9eb542d_tokenizer,commit:4f2cc0c:parent_b602c1f_(root),commit:62001eb:parent_b602c1f_(root),commit:9eb542d refs=tag:v1.0.0>0b624ed missing=9eb542d id=map title=Every_arrow_is_an_ID_stored_at_its_tail

**[ANIMATION]** step: level-3

**[DIAGRAM]** Build this from left to right.

```text
 refs/tags/v1.0.0 --> tag 0b624ed --> commit 0c2cf43 --tree--> tree 31fc0d3
                                       |          |              100644 blob 60a72d9  config.toml
                          1st parent   |          |  2nd parent  120000 blob ac85030  current-model
                                       v          v              040000 tree a67ce55  models
                           commit 4f2cc0c      commit 62001eb    100755 blob ea66be4  run.sh
                                       |          |              040000 tree c009bc4  src
                                       v          v              160000 commit 9eb542d  tokenizer
                                    commit b602c1f (root)                (in another repository)
```

Start on the left with the ref `refs/tags/v1.0.0`. It's a name, and it holds one ID: the tag object `0b624ed`. The tag object points at commit `0c2cf43`. That commit has one arrow marked "tree", to tree `31fc0d3`, and the six entries of that tree are listed on the right with their modes. Then two parent arrows go down: the first parent `4f2cc0c` and the second parent `62001eb`, which both lead to the root commit `b602c1f`.

**[ANIMATION]** say: The_gitlink_names_a_commit_that_is_not_stored_here

Look at the last tree entry. Mode `160000`, type commit, ID `9eb542d`, and the note "in another repository". That commit is not stored here at all.

**[ANIMATION]** say: No_arrow_points_back:_a_blob_does_not_know_its_trees,_a_commit_not_its_children

Every arrow is an object ID stored inside the object at its tail. There are none in the other direction. A blob doesn't know which trees contain it. A commit doesn't know its children or its branches.

## LIVE TERMINAL DEMO

**[TERMINAL]** From the course root, replay the first script, then step through its snippets.

```bash
labs/run ch03/object-types
```

The demo repository is a small inference service. Its top-level directory contains every kind of entry Git can record.

```bash
ls -F
git ls-tree HEAD
git cat-file -p HEAD:current-model; echo
```

Predict before I show it. Six entries in the working tree, the files you edit. How many different modes will `git ls-tree HEAD` print, and what type will the `tokenizer` line show? `HEAD` means the commit you're on. I'll wait.

**[PAUSE]**

<!-- snippet: ch03/object-types/01-tree-modes -->
```text
$ ls -F
config.toml
current-model@
models/
run.sh*
src/
tokenizer/
$ git ls-tree HEAD
100644 blob 60a72d9888260645df622ecd424e474d09d40560	config.toml
120000 blob ac850302da978fa7e1ffb2915871a2a50175cfea	current-model
040000 tree a67ce55a4207beac5330d0947d65bffa4354fc52	models
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc	run.sh
040000 tree c009bc4782e140b36dc7a2136770393623a345bf	src
160000 commit 9eb542d53a49342a2e19fbca1482a3d10d638739	tokenizer
# A symbolic link is a blob whose content is the target path:
$ git cat-file -p HEAD:current-model; echo
models/v2.bin
```
<!-- /snippet -->

Five modes. Look at `run.sh`: mode `100755`. That's the answer to the hook. If this line said `100644`, the executable bit was never recorded, and the server is innocent. Now `current-model`: mode `120000`, and its blob contains the text `models/v2.bin`, the link target. And `tokenizer`: mode `160000`, type `commit`. If you said blob, you're in good company.

Now the stored form of a tree.

```bash
git cat-file -p HEAD:src
git cat-file tree HEAD:src | xxd
```

<!-- snippet: ch03/object-types/02-tree-raw -->
```text
$ git cat-file -p HEAD:src
040000 tree 1722c9815eb7036ae06efcaf8d93c9c3140fb744	handlers
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	server.py
# The same tree as stored: mode, space, name, NUL, then the ID as 20 raw bytes.
$ git cat-file tree HEAD:src | xxd
00000000: 3430 3030 3020 6861 6e64 6c65 7273 0017  40000 handlers..
00000010: 22c9 815e b703 6ae0 6efc af8d 93c9 c314  "..^..j.n.......
00000020: 0fb7 4431 3030 3634 3420 7365 7276 6572  ..D100644 server
00000030: 2e70 7900 e223 8784 c412 f0a5 1517 64c0  .py..#........d.
00000040: 7c7a 44e7 b3a9 c073                      |zD....s
```
<!-- /snippet -->

Read the hex dump, the raw bytes written as hexadecimal digits, against the listing. Each entry is the mode in ASCII, here `40000` without the leading zero that the listing prints, then a space, the name, a NUL byte, and the object ID as twenty raw bytes. The type column of the listing isn't stored. Git derives it from the mode.

Commits.

```bash
git log --graph --oneline
git cat-file -p HEAD
git cat-file -p HEAD~2
```

HEAD is a merge, a commit with more than one parent. How many `tree` headers and how many `parent` headers? And `HEAD~2` is the first commit of the repository: how many `parent` headers there? I'll wait.

**[PAUSE]**

<!-- snippet: ch03/object-types/03-commit -->
```text
$ git log --graph --oneline
*   0c2cf43 Merge feature/batching
|\  
| * 62001eb Add batch size setting
* | 4f2cc0c Add readiness handler
|/  
* b602c1f Add inference service skeleton
# A merge commit: one tree, two parent headers.
$ git cat-file -p HEAD
tree 31fc0d39799d6931bb12f7befeb250a539f84a96
parent 4f2cc0c5f842120f109977a97bc72acef5aa5ccd
parent 62001eb879c6506f6d3c8e625dfadfa5029367b7
author Lab User <you@example.com> 1788756720 +0530
committer Lab User <you@example.com> 1788756720 +0530

Merge feature/batching
# A root commit has no parent header at all:
$ git cat-file -p HEAD~2
tree b6f6972aea97f7f084242c2b859bf307959a0920
author Lab User <you@example.com> 1788756360 +0530
committer Lab User <you@example.com> 1788756360 +0530

Add inference service skeleton
```
<!-- /snippet -->

One tree, two parents for the merge. No parent header at all for the root commit, the first one. Notice what isn't there: no diff, no branch name.

Try it now, thirty seconds, in a repository in the lab shell: run `git cat-file -p HEAD` and count the parent lines. I'll wait.

**[PAUSE]**

One parent line for an ordinary commit, several for a merge, none for the very first commit.

```bash
git cat-file -s HEAD
(printf 'commit %s\0' "$(git cat-file -s HEAD)"; git cat-file commit HEAD) | shasum
git rev-parse HEAD
```

<!-- snippet: ch03/object-types/04-commit-id -->
```text
# A commit ID is the hash of "commit <size>", a NUL byte, and exactly the text above.
$ git cat-file -s HEAD
271
$ (printf 'commit %s\0' "$(git cat-file -s HEAD)"; git cat-file commit HEAD) | shasum
0c2cf4371cac2e5d412153dc58293c0cb484c4ba  -
$ git rev-parse HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

The two IDs are equal. The commit ID is the hash of the header and exactly the text you read a moment ago. Nothing else goes in.

**[ANIMATION]** step: same

Same text in, same ID out: `0c2cf43`, from `shasum` and from Git alike.

**[ANIMATION]** end

The annotated tag.

```bash
git cat-file -t v1.0.0
git cat-file -t v1.0.0-rc1
git cat-file -p v1.0.0
git rev-parse v1.0.0 "v1.0.0^{}" HEAD
```

One of these two tags is annotated and one is lightweight. What type will each one report? Say it out loud.

**[PAUSE]**

<!-- snippet: ch03/object-types/05-tag -->
```text
$ git cat-file -t v1.0.0
tag
$ git cat-file -t v1.0.0-rc1
commit
$ git cat-file -p v1.0.0
object 0c2cf4371cac2e5d412153dc58293c0cb484c4ba
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788756780 +0530

Release 1.0.0
# The ref holds the ID of the tag object; ^{} peels it to the commit it tags.
$ git rev-parse v1.0.0 "v1.0.0^{}" HEAD
0b624edf4a556c702b6ed110ef2702570ced1558
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

`v1.0.0` is type `tag`. `v1.0.0-rc1` is type `commit`, because a lightweight tag is a ref that holds a commit ID. In the last command, the first line is the tag object, and `v1.0.0^{}` peels it: it follows the tag until it reaches something that isn't a tag. The peeled ID equals HEAD.

One optional header, because it's deterministic.

```bash
printf 'max_tokens = 256\n' >> config.toml
git -c i18n.commitEncoding=ISO-8859-1 commit -q -am "Add token limit"
git cat-file -p HEAD
```

This is the one state-changing command of the video: `git commit` adds a commit and moves the branch. The demo makes it in a sandbox.

<!-- snippet: ch03/object-types/06-encoding -->
```text
# An optional header: the encoding of the message when it is not UTF-8.
$ printf 'max_tokens = 256\n' >> config.toml
$ git -c i18n.commitEncoding=ISO-8859-1 commit -q -am "Add token limit"
$ git cat-file -p HEAD
tree 4274d7332863c24a4bebec4082f0ea6c6fdbd467
parent 0c2cf4371cac2e5d412153dc58293c0cb484c4ba
author Lab User <you@example.com> 1788757800 +0530
committer Lab User <you@example.com> 1788757800 +0530
encoding ISO-8859-1

Add token limit
```
<!-- /snippet -->

Look at the `encoding` line between the committer and the blank line. The `gpgsig` and `mergetag` headers aren't printed in the book, because a signature differs on every run.

**[TERMINAL]** Second script.

```bash
labs/run ch03/read-objects
```

```bash
git cat-file -t HEAD
git cat-file -t "HEAD^{tree}"
git cat-file -t HEAD:config.toml
git cat-file -s HEAD:config.toml
git cat-file -p HEAD:config.toml
git cat-file -e HEAD:config.toml
git cat-file -e 1234567890123456789012345678901234567890
```

<!-- snippet: ch03/read-objects/01-cat-file -->
```text
# Type, size and content of one object, named three different ways.
$ git cat-file -t HEAD
commit
$ git cat-file -t "HEAD^{tree}"
tree
$ git cat-file -t HEAD:config.toml
blob
$ git cat-file -s HEAD:config.toml
46
$ git cat-file -p HEAD:config.toml
retry_limit = 3
timeout_s = 30
batch_size = 8
# -e answers "does this object exist?" with the exit status only.
$ git cat-file -e HEAD:config.toml
[exit status: 0]
$ git cat-file -e 1234567890123456789012345678901234567890
[exit status: 1]
```
<!-- /snippet -->

Three names, three types. `-s` gives the size of the content without the header. `-e` prints nothing: it answers with the exit status only, the number a command hands back when it ends, zero when the object exists and one when it doesn't.

Starting one process per object is slow in a script. The batch modes read names from standard input and answer in one process.

```bash
printf 'HEAD\nHEAD^{tree}\nHEAD:run.sh\nv1.0.0\nno-such-branch\n' | git cat-file --batch-check
git ls-tree -r HEAD | awk '{print $3, $4}' | git cat-file --batch-check='%(objectsize) %(objecttype) %(rest)'
```

A quick quiz. Five names go in, and one of them doesn't exist. Does the command stop there, or carry on? Say it out loud.

**[PAUSE]**

<!-- snippet: ch03/read-objects/02-batch-check -->
```text
# Many objects in one process: names on standard input, one line of output each.
$ printf 'HEAD\nHEAD^{tree}\nHEAD:run.sh\nv1.0.0\nno-such-branch\n' | git cat-file --batch-check
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit 271
31fc0d39799d6931bb12f7befeb250a539f84a96 tree 214
ea66be4ca05594e98649f4f08ac9fa9ff25578dc blob 42
0b624edf4a556c702b6ed110ef2702570ced1558 tag 137
no-such-branch missing
# A custom format. %(rest) echoes whatever followed the name on the input line.
$ git ls-tree -r HEAD | awk '{print $3, $4}' | git cat-file --batch-check='%(objectsize) %(objecttype) %(rest)'
46 blob config.toml
13 blob current-model
11 blob models/v2.bin
42 blob run.sh
30 blob src/handlers/health.py
29 blob src/handlers/ready.py
40 blob src/server.py
9eb542d53a49342a2e19fbca1482a3d10d638739 missing
```
<!-- /snippet -->

It carries on: the line reads `no-such-branch missing`. The default line is ID, type, size. In the second command, `%(rest)` repeats whatever followed the name on the input line, which is how each path reaches the output. The last line is the gitlink: the tree names commit `9eb542d`, and this object database doesn't contain it. "Missing" here is correct.

```bash
git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep '^blob' | sort -k2 -n | tail -3
```

<!-- snippet: ch03/read-objects/03-batch-all-objects -->
```text
# Every object in the database, reachable or not, without walking any history:
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
   8 blob
   4 commit
   1 tag
   9 tree
# The three largest blobs in the whole history, with the path that leads to them:
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep '^blob' | sort -k2 -n | tail -3
blob 40 src/server.py
blob 42 run.sh
blob 46 config.toml
```
<!-- /snippet -->

Twenty-two objects for four commits. `--batch-all-objects` visits loose and packed objects without walking any history, so it also finds objects that nothing refers to. The second pipeline is the first one to run when a repository is larger than expected.

```bash
git ls-tree HEAD src/
git ls-tree -r HEAD
git ls-tree -r -t HEAD src
git ls-tree -l HEAD
git ls-tree -d --name-only HEAD
```

<!-- snippet: ch03/read-objects/04-ls-tree -->
```text
$ git ls-tree HEAD src/
040000 tree 1722c9815eb7036ae06efcaf8d93c9c3140fb744	src/handlers
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	src/server.py
# -r recurses into subtrees and lists only the leaves; -t also shows the trees on the way.
$ git ls-tree -r HEAD
100644 blob 60a72d9888260645df622ecd424e474d09d40560	config.toml
120000 blob ac850302da978fa7e1ffb2915871a2a50175cfea	current-model
100644 blob ba6f678b335f69ce9ddd1551c01e264366b80a6b	models/v2.bin
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc	run.sh
100644 blob 7dd511683bc85b8cb7d31982e55a6d1a06f814f9	src/handlers/health.py
100644 blob 1ea8895d490a68d48ff799a4b567792e5fb4c2fb	src/handlers/ready.py
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	src/server.py
160000 commit 9eb542d53a49342a2e19fbca1482a3d10d638739	tokenizer
$ git ls-tree -r -t HEAD src
040000 tree c009bc4782e140b36dc7a2136770393623a345bf	src
040000 tree 1722c9815eb7036ae06efcaf8d93c9c3140fb744	src/handlers
100644 blob 7dd511683bc85b8cb7d31982e55a6d1a06f814f9	src/handlers/health.py
100644 blob 1ea8895d490a68d48ff799a4b567792e5fb4c2fb	src/handlers/ready.py
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	src/server.py
# -l adds the blob size; -d lists only trees.
$ git ls-tree -l HEAD
100644 blob 60a72d9888260645df622ecd424e474d09d40560      46	config.toml
120000 blob ac850302da978fa7e1ffb2915871a2a50175cfea      13	current-model
040000 tree a67ce55a4207beac5330d0947d65bffa4354fc52       -	models
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc      42	run.sh
040000 tree c009bc4782e140b36dc7a2136770393623a345bf       -	src
160000 commit 9eb542d53a49342a2e19fbca1482a3d10d638739       -	tokenizer
$ git ls-tree -d --name-only HEAD
models
src
tokenizer
```
<!-- /snippet -->

Without `-r` you see one directory level, with trees as entries. With `-r` you see only the leaves: the flat list of paths a checkout would create. `-t` adds the trees passed on the way. `-l` prints sizes, and a dash where an entry isn't a blob. `-d` keeps the directories, the gitlink among them.

```bash
git show HEAD:config.toml
git show "HEAD^{tree}"
git show --no-patch v1.0.0
git show --no-patch --format=raw HEAD^2
```

<!-- snippet: ch03/read-objects/05-show -->
```text
# git show adapts to the object type. A blob: its content.
$ git show HEAD:config.toml
retry_limit = 3
timeout_s = 30
batch_size = 8
# A tree: the names in it.
$ git show "HEAD^{tree}"
tree HEAD^{tree}

config.toml
current-model
models/
run.sh
src/
tokenizer
# An annotated tag: the tag object, then the commit it points at.
$ git show --no-patch v1.0.0
tag v1.0.0
Tagger: Lab User <you@example.com>
Date:   Mon Sep 7 10:23:00 2026 +0530

Release 1.0.0

commit 0c2cf4371cac2e5d412153dc58293c0cb484c4ba
Merge: 4f2cc0c 62001eb
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:22:00 2026 +0530

    Merge feature/batching
# A commit in raw form: the object headers, then the message.
$ git show --no-patch --format=raw HEAD^2
commit 62001eb879c6506f6d3c8e625dfadfa5029367b7
tree 537b759e6f31d04b14514d85b1cca6e8db79933c
parent b602c1fa61adb577fc9ca3113292b7cf734e856a
author Asha Rao <asha@example.com> 1788756480 +0530
committer Asha Rao <asha@example.com> 1788756480 +0530

    Add batch size setting
```
<!-- /snippet -->

`git show` is the porcelain on top, the user-facing layer. It picks a presentation by object type: the content of a blob, the names in a tree, the tag object followed by its commit, and with `--format=raw` the headers of a commit as stored.

## COMMON MISTAKES

Five mistakes to watch for.

1. Reading a mode as Unix permissions. Root cause: Git records only the executable bit; owner, group, the other bits and timestamps are not in the repository.
2. Treating "missing" for a gitlink as corruption. Root cause: the commit a gitlink names lives in another repository, so this object database does not contain it.
3. Believing a commit can be edited in place. Root cause: the commit ID is the hash of the commit's text, so any change produces a different object, and every descendant changes with it.
4. Assuming an annotated tag ref points at the commit. Root cause: the ref holds the ID of the tag object; you peel it with `^{}` to reach the commit.
5. Trying to commit an empty directory. Root cause: a directory exists only as a tree with entries.

## PRODUCTION EXAMPLE

**[ANIMATION]** walk: columns=mode_in_the_tree,a_fresh_checkout_creates_run.sh,the_deploy rows=100755:executable:runs|100644:not_executable:permission_denied marks=1.3:ok,2.3:bad pick=2 title=What_the_tree_records_for_run.sh id=deploy

Now, out of the lab, and back to the deploy that fails with "permission denied" on `run.sh`. On the build machine you run `git ls-tree HEAD run.sh` and read the mode. It shows `100644`. The executable bit was never recorded, so every fresh checkout creates the file without it. The laptops work only because their files were made executable by hand. So the CTO has an answer: a repository problem, proved with one command. The fix is a commit that changes the mode, which Chapter 4 covers.

**[ANIMATION]** end

A second case from the same team. The release notes say a new release is "the same code" as the last one. You compare `git rev-parse v1.0.0^{tree}` with the tree of the other tag. Equal tree IDs mean identical content in every file. And in CI, before deploying a commit ID that arrived as a parameter, the pipeline runs `git cat-file -e "$id^{commit}"`, which fails for a missing object and for an ID that names anything other than a commit.

## PRACTICE EXERCISE

Your turn. Do Exercise 16.2, "From a commit to the bytes of a file", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md). You walk from `HEAD` to the content of `config/shards.yaml` with `git cat-file`, `git rev-parse` and `git ls-tree`.

Before you type anything, write down your predictions: how many objects you'll read on the way, the type of each, and which mode a subdirectory, an executable file and a submodule would have. Then run the commands and check yourself.

The challenge is Exercise 16.4, "Count the objects", in the same file. Predict the counts per type before you ask Git.

## INTERVIEW QUESTION

Question 72 of the CTO question bank:

> "What does a commit ID commit you to? Explain why changing a commit message three commits back changes the ID of `HEAD`."

A strong answer starts from what is hashed: the commit's own text. It then names what that text contains, the tree ID and the parent IDs, and follows the chain in both directions: down into every file of the snapshot and back through every ancestor. It ends with the practical consequence for rewriting history and for trust in an ID. Say it out loud before you open the answers file.

**[PAUSE]**

## RECAP

**[ANIMATION]** step: hist.annotated

**[ANIMATION]** say: One_commit_ID_fixes_every_file_and_every_commit_behind_it

Let's land this. One commit ID fixes every file and every commit behind it.

You should now be able to say:

- A blob has content and no name; a tree gives names and modes to IDs; a commit names one tree and its parents; a tag object names another object.
- Git uses five tree entry modes, and the executable bit is the only permission it records.
- A commit ID covers its tree and its parents, so one ID fixes every file and every commit behind it.
- `git cat-file` answers type, size, content and existence, for one object or for all of them in one process.
- `git ls-tree` lists a tree; `git show` formats any object for a person.

## HOMEWORK

Read sections 3.4 and 3.5 of [Chapter 3](../../textbook/ch03-git-internals.md).

Today you read all four object types in their raw form. Practise that before the next video: turning names into IDs with `git rev-parse`. Until then, look at the state first and type second. See you in the next one.

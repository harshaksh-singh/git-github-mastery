# V095: Git LFS: why it exists, the pointer file, the two filters, and tracking

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS
- **Planned minutes.** 22
- **Prerequisites.** V088
- **Textbook sections.** [Chapter 22](../../textbook/ch22-git-lfs.md), sections 22.1 to 22.4
- **Demo scripts.** `labs/ch22/why-lfs.sh`, `labs/ch22/lfs-pointer.sh`

## HOOK

**[ON SCREEN]** "The push to GitHub was rejected because of a model file. I deleted the file and committed. It is still rejected. Why?"

That question reaches a CTO's desk in an AI and ML team, usually followed by three more.

**[ANIMATION]** cards: id=q4 cards=The_push_was_rejected_because_of_a_model_file:I_deleted_the_file._It_is_still_rejected.|The_clone_takes_twenty_minutes:the_repository_holds_400_lines_of_Python|The_model_file_is_132_bytes:and_starts_with_the_word_version|The_storage_bill_keeps_growing:nobody_has_added_a_model_in_months numbered=on title=Four_questions_for_the_CTO

**[ANIMATION]** step: q4.4

"The clone takes twenty minutes and the repository holds four hundred lines of Python." "The training job in CI crashed while loading the weights: the file is 132 bytes and starts with the word `version`." "Our storage bill for this repository keeps growing, and nobody has added a model in months."

The first two are Git doing what it was designed to do, with content it wasn't designed for. The third is Git LFS working as designed on a machine that doesn't have it. The fourth is how GitHub accounts for LFS. To answer any of them you need to know one thing: what LFS stores where. Hold on to the first question. You'll answer it in the first demo.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Git LFS, Large File Storage, isn't part of Git. It's a separate program, `git-lfs`, that plugs into Git through two mechanisms you already know: a clean and smudge filter selected by `.gitattributes`, the file that attaches settings to paths, and hooks, the programs Git runs at fixed points. So this video doesn't teach you a new mechanism. It shows you what this particular filter does.

The project is `transcriber`, a speech-to-text service: a little code and one acoustic model file. The lab uses stand-in files of 1.2 to 1.3 megabytes so that the demos run in a second. Real models are a thousand times larger and behave the same.

One statement about evidence, as the textbook makes it. The remote in this chapter is a bare repository reached through a file path, which git-lfs 3.7.1 supports with a built-in transfer adapter. So tracking, pushing, cloning, fetching, pruning and migrating are real transcripts. Anything that needs an LFS server could not be run: the HTTP API, authentication, file locking, and all GitHub limits and billing. Those parts are described from the documentation and labelled.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- explain what large binary files do to every clone, and why deleting them later does not help;
- say what Git stores for an LFS-tracked path and what LFS stores, and where each is;
- read a pointer file;
- explain which two Git mechanisms LFS uses and which parts travel with a clone;
- state what `git lfs track` does not do for files already committed.

## CONCEPT

**[ANIMATION]** graph: id=del c66100a-f9e56b8-65c2188-1ddbfc0-8b13104 main; HEAD=main; sub:f9e56b8:model_v1; sub:65c2188:model_v2; sub:8b13104:model_v3 => c66100a-f9e56b8-65c2188-1ddbfc0-8b13104-09c8ef8 main; HEAD=main; sub:f9e56b8:model_v1; sub:65c2188:model_v2; sub:8b13104:model_v3; sub:09c8ef8:model_deleted; say:The_earlier_commits_still_reach_all_three_versions title=Deleting_a_file_adds_a_commit

**[ANIMATION]** step: del.state-1

**Why LFS exists.** In one sentence: Git keeps every version of every file forever and gives every clone all of them, which is right for source code and ruinous for large binaries that change.

Packfiles, the files Git packs its objects into, store similar objects as deltas, and that helps when versions share long runs of bytes. Retrained weights, compressed archives, images and audio share almost nothing from one version to the next. So each version costs its full size, and zlib can't shrink data that's already dense. The cost grows with the number of versions, and it's paid again by every clone and every CI job.

**[ANIMATION]** step: del.state-2

Deleting the file adds a commit. The old blobs, the objects that hold the file's content, are still reachable from the earlier commits. A hosting platform that rejects a large blob rejects it because it's in a commit being pushed, not because it's in the latest tree. Only a history rewrite removes it.

**[ANIMATION]** end

LFS changes one thing: Git stores a small text file in place of the binary, and the binary goes to a separate store that's downloaded per version, on demand.

**[ANIMATION]** stores: id=flt boxes=working_tree:what_you_edit|*Git_objects:index_and_commits|LFS_store:.git/lfs/objects rows=1:A:the_real_content|2:B:a_three-line_pointer@hl|2:C:the_content,_named_by_its_SHA-256|3:A:the_real_content,_again@ok arrows=2:A1>B1:clean|2:A1>C1:content|3:C1>A2:smudge title=Two_filters,_two_stores

**[ANIMATION]** step: flt.2

**The pointer and the two filters.** In one sentence: for a path that's tracked by LFS, the blob in Git is a three-line pointer containing the SHA-256 and the size of the real content. SHA-256 is a checksum, a fingerprint computed from the bytes. The real content lives in an LFS object store, locally under `.git/lfs/objects` and remotely beside the Git repository.

Now precisely: two filter commands do the exchange. Clean, run by `git add`, reads the file content, computes its SHA-256, and stores the content in `.git/lfs/objects`, in a path made of the first two hex digits, the next two, and the full hash. Then it hands Git the pointer text. Git hashes and stores the pointer as a blob.

**[ANIMATION]** step: flt.3

Smudge, run by checkout, reads the pointer from the blob, finds the object in the local store, downloads it from the remote if it isn't there, and writes the real content into the working tree.

The pointer format is fixed by the specification: UTF-8 text, one key and value per line, `version` first and the other keys in alphabetical order, less than 1024 bytes in total. The required keys are `version`, `oid` with the hash method as prefix, and `size`.

**[ANIMATION]** end

**The `.gitattributes` line.** `git lfs track` writes it.

**[ON SCREEN]** The attribute table of section 22.4.

| Attribute | Effect |
|---|---|
| `filter=lfs` | Run the `lfs` clean and smudge filter for matching paths. This is the attribute that matters. |
| `diff=lfs` | Use a diff driver named `lfs`. `git lfs install` defines none, so `git diff` shows the difference between pointers. |
| `merge=lfs` | Use a merge driver named `lfs`. None is defined either, so Git merges the pointers as text. |
| `-text` | Never apply line-ending conversion. |

Three rules follow from this being an ordinary attributes file. Commit `.gitattributes`: it's the only part of the setup that travels with the repository. The filter definition is local configuration and the hooks are local files, and a clone gets neither. Patterns follow gitignore syntax. Quote them in the shell, or the shell expands the pattern to the files that exist today and `git lfs track` records those names. And tracking applies from the next `git add`. `git lfs track` edits a text file. It doesn't convert a file that's already in the index or in history.

When not to reach for LFS is a topic of its own two videos from now. For today, note the limit that the design implies: the LFS content isn't a Git object. `git cat-file`, `git fsck`, `git gc` and `git push` know nothing about it.

## MENTAL MODEL

**[ANIMATION]** say: The pointer is the ticket. The content is the coat.

The textbook's analogy: a coat check. You hand over the coat and carry a numbered ticket. The ticket goes wherever you go, and the coat stays in the cloakroom until someone presents the ticket. Git history carries tickets.

**[ANIMATION]** hash: differs=byte left=the_model_file right=the_model_file,_again lines=1200000_bytes alt=1250000_bytes ids=0269885262,f8719e1ac8 fn=sha256 same=The_same_bytes_always_get_the_same_oid diff=A_new_version:_other_bytes,_another_oid title=The_ticket_is_computed_from_the_coat

**[ANIMATION]** step: same

The analogy breaks in two places. The number on the ticket is computed from the coat itself, so the same content always gets the same ticket. And a ticket can be copied to a place that has no cloakroom attendant, where it is only a piece of paper.

**[ANIMATION]** end

Keep that second break in mind. A machine without the LFS client receives the tickets, because tickets are ordinary Git blobs, and nobody there exchanges them. That's the 132-byte model file, and it's the next video.

Try it now, on paper, thirty seconds. Draw three boxes: working tree, Git objects, LFS store. For a model of 1,200,000 bytes, write in each box what you predict it holds.

**[PAUSE]**

## DIAGRAM

**[ANIMATION]** stores: id=lfs boxes=working_tree:models/acoustic.onnx|*Git_objects:index_and_commits|LFS_store:.git/lfs/objects/02/69/ rows=1:A:1,200,000_bytes|2:B:blob_1097a4b_(132_bytes)@hl|2:B:version_https://git-lfs...|2:B:oid_sha256:0269885262...|2:B:size_1200000|2:C:0269885262...e8de|2:C:1,200,000_bytes|3:B:travels_with_git_push_/_fetch@dim|3:C:travels_with_git_lfs@dim arrows=2:A1>B1:clean|2:B3>C1:oid|2:B1>A1:smudge title=What_is_stored_where

**[DIAGRAM]** The picture of section 22.3. Three boxes, left to right; add the two arrows between each pair, and then the two captions at the bottom.

```text
   working tree                 index and commits (Git objects)          LFS store
  +---------------------+       +-------------------------------+       +---------------------------+
  | models/acoustic.onnx|       | blob 1097a4b  (132 bytes)     |       | .git/lfs/objects/02/69/   |
  | 1,200,000 bytes     | clean | version https://git-lfs...    | oid   |   0269885262...e8de       |
  |                     | ----> | oid sha256:0269885262...      | ----> |   1,200,000 bytes         |
  |                     | <---- | size 1200000                  | <---- |                           |
  +---------------------+ smudge+-------------------------------+       +---------------------------+
                                   travels with git push / fetch          travels with git lfs
                                                                          (pre-push hook, smudge, pull)
```

Check your drawing. Left: the real file, 1,200,000 bytes. Middle: what Git stores, a blob of 132 bytes. Right: where the real bytes are kept, in a file named by their own SHA-256. The two captions say who moves each store. Git moves the middle one. The LFS client moves the right one.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch22/why-lfs`. Three versions of the model were committed as ordinary files.

```bash
git log --oneline
wc -c models/acoustic.onnx
git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
```

Predict: the working tree has one model. How many model blobs does the repository have? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch22/why-lfs/01-three-versions -->
```text
$ git log --oneline
8b13104 Retrain acoustic model with accents (v3)
1ddbfc0 Resample input to 16 kHz
65c2188 Retrain acoustic model on noisy audio (v2)
f9e56b8 Add acoustic model v1
c66100a Add transcription entry point
$ wc -c models/acoustic.onnx
 1300000 models/acoustic.onnx
# Every blob that any commit reaches, with its size in bytes:
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
blob 68 README.md
blob 1300000 models/acoustic.onnx
blob 14 models/vocab.txt
blob 231 transcribe.py
blob 1250000 models/acoustic.onnx
blob 198 transcribe.py
blob 1200000 models/acoustic.onnx
```
<!-- /snippet -->

Three, one per version, each stored whole.

```bash
git push origin main
git clone remotes/transcriber.git ravi-transcriber
```

<!-- snippet: ch22/why-lfs/02-clone-gets-all -->
```text
$ git push origin main
To $LAB/ch22/why-lfs/remotes/transcriber.git
   c66100a..8b13104  main -> main
$ cd ..
$ git clone remotes/transcriber.git ravi-transcriber
Cloning into 'ravi-transcriber'...
done.
$ cd ravi-transcriber
# One model file in the working tree, three in the repository:
$ ls models
acoustic.onnx
vocab.txt
$ git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"
3
```
<!-- /snippet -->

A teammate's clone downloads all three, to check out one. Now the reflex from the opening: delete the model and commit. A quick quiz. How many of the three big blobs are left afterwards: none, or all three? Say it out loud.

**[PAUSE]**

```bash
git rm --quiet models/acoustic.onnx
git commit -m "Remove the model from the repository"
git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
```

<!-- snippet: ch22/why-lfs/03-delete-does-not-help -->
```text
$ git rm --quiet models/acoustic.onnx
$ git commit -m "Remove the model from the repository"
[main 09c8ef8] Remove the model from the repository
 1 file changed, 0 insertions(+), 0 deletions(-)
 delete mode 100644 models/acoustic.onnx
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 1300000 models/acoustic.onnx
blob 1250000 models/acoustic.onnx
blob 1200000 models/acoustic.onnx
```
<!-- /snippet -->

All three. The deleting commit says "0 insertions, 0 deletions" and "delete mode".

**[ANIMATION]** step: del.state-2

And the three blobs, 1.3, 1.25 and 1.2 megabytes, are still there, reachable from the earlier commits. That's the answer to question 1, the one you were holding on to.

**[TERMINAL]** Replay `labs/run ch22/lfs-pointer`. The same project, done with LFS.

**[ON SCREEN]** 🟢 SAFE: `git lfs install --local`. Normally `git lfs install` writes the filter definition into your global configuration. In this course it is always run with `--local`, which writes the definition into the repository's own `.git/config` and installs hooks in this repository, and nothing anywhere else.

```bash
git lfs version
git lfs install --local
git config list --local | grep -e ^filter -e ^lfs | sort
```

<!-- snippet: ch22/lfs-pointer/01-install -->
```text
$ git lfs version
git-lfs/3.7.1 (GitHub; darwin arm64; go 1.25.3)
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git config list --local | grep -e ^filter -e ^lfs | sort
filter.lfs.clean=git-lfs clean -- %f
filter.lfs.process=git-lfs filter-process
filter.lfs.required=true
filter.lfs.smudge=git-lfs smudge -- %f
lfs.repositoryformatversion=0
$ ls .git/hooks | grep -v sample
post-checkout
post-commit
post-merge
pre-push
```
<!-- /snippet -->

A clean command, a smudge command, a `process` variant that handles all files of one command in a single process, and `filter.lfs.required=true`.

**[ANIMATION]** stores: id=travel boxes=this_repository:after_git_lfs_install_--local|a_fresh_clone:what_git_clone_brings rows=1:A:.gitattributes_(committed)|1:A:filter.lfs.*_in_.git/config|1:A:four_hooks_in_.git/hooks|2:B:.gitattributes@ok|2:B:no_filter_definition@bad|2:B:no_hooks@bad arrows=2:A1>B1:clone title=What_travels_with_a_clone

You know that last key from the filters video: if the filter fails, the Git command fails. You also know its limit: it's part of a definition that a clone doesn't receive.

**[ANIMATION]** end

The filter definition says how to convert. `.gitattributes` says which paths get converted. 🟢 SAFE: `git lfs track` writes that line.

```bash
git lfs track "*.onnx"
cat .gitattributes
git lfs track
git check-attr filter diff merge text -- models/acoustic.onnx
```

<!-- snippet: ch22/lfs-pointer/02-track -->
```text
$ git lfs track "*.onnx"
Tracking "*.onnx"
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
$ git lfs track
Listing tracked patterns
    *.onnx (.gitattributes)
Listing excluded patterns
$ git check-attr filter diff merge text -- models/acoustic.onnx
models/acoustic.onnx: filter: lfs
models/acoustic.onnx: diff: lfs
models/acoustic.onnx: merge: lfs
models/acoustic.onnx: text: unset
$ git check-attr filter -- models/vocab.txt
models/vocab.txt: filter: unspecified
```
<!-- /snippet -->

One line in `.gitattributes`, with the four attributes from the table, and `git check-attr` confirms them for the model path. Notice the quotes around the pattern.

Now add a model of 1,200,000 bytes and commit it together with `.gitattributes`.

```bash
wc -c models/acoustic.onnx
shasum -a 256 models/acoustic.onnx
git add .gitattributes models/acoustic.onnx
git commit -m "Add acoustic model v1, tracked with Git LFS"
```

<!-- snippet: ch22/lfs-pointer/03-commit -->
```text
$ wc -c models/acoustic.onnx
 1200000 models/acoustic.onnx
$ shasum -a 256 models/acoustic.onnx
02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de  models/acoustic.onnx
$ git add .gitattributes models/acoustic.onnx
$ git commit -m "Add acoustic model v1, tracked with Git LFS"
[main 26caf87] Add acoustic model v1, tracked with Git LFS
 2 files changed, 4 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 models/acoustic.onnx
```
<!-- /snippet -->

Remember the start of the checksum: `0269885262`.

Predict two numbers. The size of the blob that Git stored for `models/acoustic.onnx`. And the size of the file in the working tree. I'll wait.

**[PAUSE]**

```bash
git cat-file -p HEAD:models/acoustic.onnx
git cat-file -s HEAD:models/acoustic.onnx
wc -c models/acoustic.onnx
```

<!-- snippet: ch22/lfs-pointer/04-pointer -->
```text
# What Git stored for the path:
$ git cat-file -p HEAD:models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
$ git cat-file -s HEAD:models/acoustic.onnx
132
# What is in the working tree:
$ wc -c models/acoustic.onnx
 1200000 models/acoustic.onnx
```
<!-- /snippet -->

The blob is 132 bytes of text. Read the three lines: `version` and a URL, then `oid sha256:` and the checksum that `shasum` printed, then `size 1200000`.

**[ANIMATION]** trees: file=models/acoustic.onnx chips=1200000_bytes,pointer:_132_bytes,pointer:_132_bytes commits=26caf87,26caf87 steps=setup title=One_path,_two_very_different_sizes say_setup=The_clean_filter_changes_what_goes_into_the_repository

The working tree still has the real file. The clean filter changes what goes into the repository, not what is on your disk. If you predicted 132 bytes in both places, that's a natural guess.

```bash
find .git/lfs/objects -type f
git lfs ls-files
git lfs ls-files --long --size
git lfs pointer --file=models/acoustic.onnx
```

<!-- snippet: ch22/lfs-pointer/05-local-store -->
```text
$ find .git/lfs/objects -type f
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
$ git lfs ls-files
0269885262 * models/acoustic.onnx
$ git lfs ls-files --long --size
02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de * models/acoustic.onnx (1.2 MB)
$ git lfs pointer --file=models/acoustic.onnx
Git LFS pointer for models/acoustic.onnx

version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
```
<!-- /snippet -->

The content is under `.git/lfs/objects/02/69/`, in a file named by its own SHA-256. It isn't a Git object. `git lfs ls-files` lists the LFS-tracked paths of the current commit. The asterisk means the working tree file holds the real content, and a minus sign would mean it holds a pointer. `git lfs pointer --file` computes the pointer for a file without storing anything.

A new version of the model, not yet staged.

```bash
git status --short
git diff
git lfs status
```

<!-- snippet: ch22/lfs-pointer/06-new-version -->
```text
$ git status --short
 M models/acoustic.onnx
$ git diff
diff --git a/models/acoustic.onnx b/models/acoustic.onnx
index 1097a4b..366f6ac 100644
--- a/models/acoustic.onnx
+++ b/models/acoustic.onnx
@@ -1,3 +1,3 @@
 version https://git-lfs.github.com/spec/v1
-oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
-size 1200000
+oid sha256:f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
+size 1250000
$ git lfs status
On branch main
Objects to be pushed to origin/main:

	models/acoustic.onnx (02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de)

Objects to be committed:


Objects not staged for commit:

	models/acoustic.onnx (LFS: 0269885 -> File: f8719e1)
```
<!-- /snippet -->

`git diff` shows the difference between two pointers: an `oid` line and a `size` line. No diff driver named `lfs` is defined, so this is all a diff of an LFS file can say. `git lfs status` adds what a push would upload.

**[ANIMATION]** step: different

New bytes, so a new ticket: `0269885` has become `f8719e1`.

**[ANIMATION]** end

And the second mechanism: hooks.

```bash
cat .git/hooks/pre-push
cat .git/hooks/post-checkout
```

<!-- snippet: ch22/lfs-pointer/07-hook -->
```text
$ cat .git/hooks/pre-push
#!/bin/sh
command -v git-lfs >/dev/null 2>&1 || { printf >&2 "\n%s\n\n" "This repository is configured for Git LFS but 'git-lfs' was not found on your path. If you no longer wish to use Git LFS, remove this hook by deleting the 'pre-push' file in the hooks directory (set by 'core.hookspath'; usually '.git/hooks')."; exit 2; }
git lfs pre-push "$@"
$ cat .git/hooks/post-checkout
#!/bin/sh
command -v git-lfs >/dev/null 2>&1 || { printf >&2 "\n%s\n\n" "This repository is configured for Git LFS but 'git-lfs' was not found on your path. If you no longer wish to use Git LFS, remove this hook by deleting the 'post-checkout' file in the hooks directory (set by 'core.hookspath'; usually '.git/hooks')."; exit 2; }
git lfs post-checkout "$@"
```
<!-- /snippet -->

Each hook has two lines. The first checks that `git-lfs` is on the path and prints an explanation if it isn't. That's the rule from the hooks video about hooks that depend on tools. The second hands over to `git lfs`. The `pre-push` hook is what uploads the content when you push.

**[ON SCREEN]** The state table for `git add` and `git commit` of an LFS-tracked file.

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged (real content) | entry for the path names a pointer blob | new commit on `git commit` | advanced on `git commit` | pointer blob in `.git/objects`; real content in `.git/lfs/objects` | unchanged until pushed | unchanged until pushed |

## COMMON MISTAKES

Five mistakes to watch for.

1. **Deleting a large file to get a rejected push through.** Root cause: the blob is still reachable from the earlier commits being pushed; only a history rewrite removes it.
2. **Running `git lfs track` and assuming existing files are converted.** Root cause: it edits `.gitattributes`; conversion happens at the next `git add`, and nothing changes for files already in the index or in history.
3. **An unquoted pattern in `git lfs track`.** Root cause: the shell expands it to the files that exist today, and those names are recorded instead of the pattern.
4. **Not committing `.gitattributes`.** Root cause: it is the only part of the LFS setup that travels with the repository.
5. **Expecting `git fsck`, `git gc` or `git push` to look after the model content.** Root cause: LFS objects are files under `.git/lfs/objects`, not Git objects; only the pointer is.

## PRODUCTION EXAMPLE

Now, out of the lab. A repository holds an evaluation harness and three reference checkpoints of a few hundred megabytes that change twice a year. Before LFS, every retraining added a full copy of each checkpoint to every clone, and the CI jobs that only lint the code downloaded all of them.

**[ANIMATION]** replay: flt

With LFS, a clone downloads the code and the pointers at once, and each checkpoint only when a checkout needs it. A CI job that doesn't need the checkpoints can skip them. The team's review checklist gained one line: a pull request that adds a new binary type must also add its pattern to `.gitattributes`, in the same commit, and the checksum in the pointer is what the model card cites.

## PRACTICE EXERCISE

Your turn. Do Lab 15.3, "Inspect an LFS pointer", in [`lab-manual/m15-submodules-subtrees-lfs.md`](../../lab-manual/m15-submodules-subtrees-lfs.md).

Before you commit the tracked file, predict the three lines of the pointer: compute the checksum yourself and write down the size. Predict the size that `git cat-file -s` will print for the path, and the path of the file under `.git/lfs/objects`.

The challenge is Exercise 15.6, Level 2, command prediction, "Tracked too late", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q355: "What does Git store for an LFS-tracked path, what does LFS store, and where is each on your machine and on the remote?"

**[PAUSE]**

Answer out loud. A strong answer names two stores and never blurs them. For Git's side it says what kind of object the path is, what its content looks like and roughly how large it is. For the LFS side it says how the content is addressed and gives the local location. It says which program moves each store and at which moment, and it's careful about the remote: what is known from a run against a local remote and what a hosted service does according to its documentation. It may add which part of the setup a fresh clone receives and which it doesn't.

## RECAP

**[ANIMATION]** trees: file=models/acoustic.onnx chips=1200000_bytes,pointer:_132_bytes,pointer:_132_bytes commits=26caf87,26caf87 steps=setup title=One_path,_two_very_different_sizes say_setup=Git_carries_the_ticket,_LFS_keeps_the_coat

Let's land this. One path, two sizes: the real bytes in your working tree, and a 132-byte pointer in Git.

You should now be able to say:

- Git gives every clone every version of every file, and binaries that change do not delta or compress, so each version costs its full size for everyone.
- Deleting a large file later does not remove its blobs from history.
- For an LFS-tracked path Git stores a pointer of about 130 bytes with the SHA-256 and the size; the content is under `.git/lfs/objects`, named by that hash.
- LFS is a clean and smudge filter selected by `.gitattributes`, plus hooks; only `.gitattributes` travels with a clone.
- `git lfs track` affects files added afterwards, not files already committed.

## HOMEWORK

Read sections 22.1 to 22.4 of [Chapter 22](../../textbook/ch22-git-lfs.md). Do Exercise 15.2, Level 1, "A first LFS pointer", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you read a pointer file and matched its checksum by hand, and you can now say what LFS stores where. Practise with the lab before you move on. Next time: Git LFS day to day, and that 132-byte model file. Until then, look at the state first and type second. See you in the next one.

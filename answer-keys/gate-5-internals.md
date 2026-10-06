# Answer key, Gate 5: Internals

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 5](../assessments/gate-5-internals.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. Every transcript is real output of a script under `labs/gates/` on Git 2.55.0, `files` ref format, SHA-1.

**Marking, in general.** A concept answer is marked on the distinction that runs through this gate: primary data (objects, refs, the staging content of the index) against derived data (pack indexes, the commit-graph, bitmaps, the stat cache), and the model (four object types, snapshots) against its storage (loose files, packs, deltas). An answer that mixes the levels earns at most 3 of 5. Deduct a point for each statement that is wrong about Git.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** The object is the byte sequence `<type> <size>`, one NUL byte, then the content: for a nine-byte file, `blob 9\0` followed by the nine bytes. The ID is the SHA-1 of exactly those uncompressed bytes. The file on disk is that sequence compressed with zlib, stored at `.git/objects/<first two hex digits>/<remaining 38>`. Consequences. The hash covers type, size and content and nothing else, no file name, no date, no author, so equal content gives an equal ID everywhere, and Git stores it once. The file is compressed, so a text search over `.git/objects` finds nothing; ask Git (`git grep`, `git cat-file`, `git log -S`). Verification: ordinary commands read an object by its name and do not recompute the hash. `git fsck` hashes what it finds and compares the result with the name. A transfer through Git's transport sends content without IDs and the receiver computes every ID itself, so a damaged object cannot arrive under a name its content does not have; a clone from a local path copies or hard-links files and skips that check unless `--no-local` is given.

**Marking.** 1 point: header, NUL, content, hashed uncompressed. 1 point: zlib and the path rule. 1 point: same content, same ID, with the reason that nothing else is hashed. 1 point: why a text search fails. 1 point: when the hash is checked and when it is not.

**Common wrong answers.** "The hash is of the file content." (The header is included: `sha1sum file` gives a different value.) "Git checks the hash every time it reads an object." "The ID depends on the file name."

**Reference.** Chapter 3, sections 3.3 and 3.8.

### C2 (5 points)

**Model answer.** A packfile holds many objects in one file, each compressed, and each stored either whole or as a delta: instructions to rebuild it from a base object in the same pack. The `.idx` file is a sorted table from object ID to offset in the pack (with a checksum per entry), so that one object is found without reading the pack from the start. Which objects are compared for deltas is a heuristic over objects of the same type with similar names and sizes; a delta base is any similar object, not "the previous version" in the history sense. For a file with many versions the newest is usually the one stored whole and the older versions are deltas against it, because the newest is read most often. None of this changes what an object is: `git cat-file -p` returns the complete object whatever its storage, and a commit still names a tree that names every blob. Packing is compression below the model. The `.idx` is derived data: every byte of it can be recomputed from the pack. Without it Git cannot find the objects in that pack, so commands fail with "Could not read" and `git count-objects -v` warns "no corresponding .idx" and counts the pack as garbage, but nothing is lost. `git index-pack <pack>` writes the index again.

**Marking.** 1 point: pack and index contents. 1 point: the delta base is a similar object chosen by heuristic. 1 point: the newest version is usually whole. 1 point: model against storage. 1 point: derived data and `git index-pack`.

**Common wrong answers.** "Packs store each version as a diff from the previous commit." "Deleting the `.idx` deletes the objects." "Re-clone."

**Reference.** Chapter 3, section 3.7, and the table of section 3.15.

### C3 (5 points)

**Model answer.** One entry records: the path, the mode (regular, executable, symbolic link, gitlink), the ID of the blob with the staged content, a stage number (0 normally, 1 to 3 during a conflict), flags such as assume-unchanged, skip-worktree and intent-to-add, and a copy of the file's `stat` data from the moment the entry was last refreshed: size, modification and change times, inode and so on. `git status` calls `lstat` on each tracked file and compares the result with the stored copy. If they match, the file is taken as unchanged and is not read. If they differ, Git reads the file, hashes it and compares the hash with the entry's blob ID; when the content turns out to be equal, porcelain commands store the new stat data, which is why `git status` can rewrite the index. So the index is two things in one file: the proposed next commit, and a cache. If the file is deleted, `git reset` (mixed) rebuilds it from the tree of `HEAD`: paths, modes and blob IDs. The stat cache is refilled by reading the working tree. What cannot be rebuilt is everything the index knew that `HEAD` does not: which changes were staged, the stages of an unresolved conflict, intent-to-add entries, and the flag bits. Staged content still exists as blobs without names.

**Marking.** 1 point: the fields. 1 point: the stat comparison. 1 point: the fallback of reading and hashing. 1 point: rebuild from `HEAD` with a mixed reset. 1 point: what is lost.

**Common wrong answers.** "The index is a list of file names." "`git status` hashes every file." "Deleting the index loses commits."

**Reference.** Chapter 3, section 3.12; Chapter 5, sections 5.14 and 5.15.

### C4 (5 points)

**Model answer.** A ref is a loose file, `.git/refs/heads/main`, containing the ID; or a line in `.git/packed-refs`; or both. Lookup reads the loose file first and `packed-refs` second, so the loose file wins. `git pack-refs`, which `git gc` and maintenance run, moves loose refs into `packed-refs` and removes the files; a clone delivers its refs packed. The next update of a ref writes a new loose file and leaves the old line in `packed-refs` untouched. The script: after packing there is no file, so `cat` fails; a variant that falls back to `grep` in `packed-refs` finds the old line after the branch has moved on, and stamps the build with a stale commit. The script read one of several storage locations instead of asking Git. It should use `git rev-parse --verify refs/heads/main`. reftable replaces loose files, `packed-refs` and `logs/` by binary, block-structured tables under `.git/reftable/`, which makes ref updates atomic across refs, and lookups fast with very many refs; it has been available since Git 2.45 and is planned as the default for new repositories in Git 3.0. It does not change what a ref is or what any command prints, which is exactly why scripts that use `rev-parse`, `for-each-ref`, `update-ref` and `symbolic-ref` keep working and scripts that read files do not.

**Marking.** 1 point: both locations and the precedence. 1 point: when packing happens and what the next update does. 1 point: both script failures. 1 point: `git rev-parse --verify`. 1 point: reftable, what changes and what does not.

**Common wrong answers.** "`packed-refs` wins." "Refs are always files." "reftable is a new kind of ref."

**Reference.** Chapter 3, sections 3.9 (root-cause box "a release script runs cat .git/refs/heads/main") and 3.13.

### C5 (5 points)

**Model answer.**

| | Has locally | Marker | Behaves differently |
|---|---|---|---|
| Full | every commit, tree and blob reachable from the fetched refs | none | nothing; works offline |
| Shallow (`--depth n`) | the commits within `n` of the tips, with their trees and blobs | `.git/shallow` lists the boundary commits whose parents Git pretends do not exist | `git log` ends at the boundary; `git blame` attributes old lines to the boundary commit; `git describe` fails or picks a wrong tag because tags behind the boundary are not there; `git merge-base` can find no base. Most of these exit with status 0 and a wrong answer |
| Blobless partial (`--filter=blob:none`) | all commits and trees; only the blobs that a checkout needed | `remote.<name>.promisor=true` and `remote.<name>.partialclonefilter` | history questions are right; commands that need old file contents (`git show <old>:<path>`, `git log -p`, `git blame`, checkout of an old commit) fetch blobs on demand and fail offline or when the promisor remote is unreachable |

The CI job that runs `git describe` needs the history back to the tag and the tags: a full fetch of history (on GitHub Actions, `fetch-depth: 0`), or a blobless clone, which has every commit and tag and is still small. A depth-1 checkout gives a wrong or failing version. The laptop in the ten-year repository: a blobless partial clone, because history questions stay right and the cost is paid only for the contents actually opened; not a shallow clone, which answers history questions wrongly and silently.

**Marking.** 1 point per kind for content and marker (shallow, partial: 2). 1 point: at least two commands per kind that behave differently. 1 point: the CI choice with the reason. 1 point: the laptop choice with the reason.

**Common wrong answers.** "Shallow and partial are the same." "A shallow clone only lacks old blobs." "Partial clones give wrong history."

**Reference.** Chapter 26, sections 26.11 to 26.13.

### C6 (5 points)

**Model answer.**

| | Stores | Speeds up | Deleting it |
|---|---|---|---|
| commit-graph | for every commit: parents, root tree, date, generation number; optionally a summary of changed paths | history walks: `git log`, `merge-base`, `--contains`, `git log -- <path>` with the path summaries | loses nothing; walks decompress commit objects again |
| multi-pack-index | one sorted index over the objects of many packs | object lookup when there are many packs | loses nothing; lookup consults each `.idx` |
| reachability bitmap | for selected commits, one bit per object: reachable or not | "which objects does this client need": clone and fetch on the serving side, counting | loses nothing; the graph is walked again |
| cruft pack | unreachable objects, with a companion file of last-touched times | keeps garbage out of thousands of loose files while it waits out the grace period | loses the unreachable objects in it: this one holds primary data, although data nothing refers to |

Repacking everything rewrites the largest pack each time, which costs time and I/O proportional to the whole repository. Geometric repacking keeps packs in a sequence in which each is at least twice the size of the next and merges only the small ones, so routine maintenance touches only recent data. Since Git 2.54, the maintenance that Git starts on its own no longer runs `git gc`; it runs the `geometric` set of tasks (commit-graph, geometric repack, pack-refs, reflog expiry and others), and unreachable objects are deleted only at an all-into-one repack.

**Marking.** 1 point each for commit-graph, multi-pack-index and bitmap. 1 point: the cruft pack, including that it is not derived data. 1 point: geometric repacking and the 2.54 change.

**Common wrong answers.** "The commit-graph is the history." "Bitmaps speed up `git status`." "Maintenance always runs gc."

**Reference.** Chapter 26, sections 26.3 to 26.8.

---

## Part 2: Prediction

Marking for every prediction item: a prediction counts when the lines and their order are right. Exact spacing is not required. A right output with a wrong mechanism earns half of that sub-item.

### P1 (5 points)

<!-- snippet: gates/g5-predict/p1-answer -->
```text
$ find .git/objects -type f | sort
.git/objects/13/80a9de8d8f7c7cb7da1739d9dfc9c7539b9fe6
$ git cat-file -t 1380a9d
blob
$ git cat-file -s 1380a9d
9
# The file, decompressed: header, NUL byte, content.
$ python3 -c "import zlib,sys; print(repr(zlib.decompress(open(sys.argv[1],'rb').read())))" .git/objects/13/80a9de8d8f7c7cb7da1739d9dfc9c7539b9fe6
b'blob 9\x00top_k: 5\n'
$ git status --short
?? a.yaml
?? b.yaml
$ git fsck
notice: No default references
dangling blob 1380a9de8d8f7c7cb7da1739d9dfc9c7539b9fe6
```
<!-- /snippet -->

One file: two files with the same content are one object, and the second `hash-object -w` wrote nothing. The path is the ID split after two characters. The size is 9, the length of the content, not of the file on disk. `hash-object -w` touches neither the index nor any ref, so both files are untracked and the blob is dangling.

**Marking.** 1 point: one file, at `13/80a9...`. 1 point: `blob` and `9`. 1 point: `blob 9\0top_k: 5\n`. 2 points: both files `??`, and "dangling blob". Two object files, or a size other than 9, lose the respective point.

**Reference.** Chapter 3, sections 3.3 and 3.5.

### P2 (5 points)

<!-- snippet: gates/g5-predict/p2-answer-a -->
```text
$ git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 9
in-pack: 0
packs: 0
$ find .git/refs -type f | sort
.git/refs/heads/main
.git/refs/tags/v1
```
<!-- /snippet -->

Three commits, three root trees and three blobs: nine loose objects. Two loose refs. A lightweight tag adds no object.

<!-- snippet: gates/g5-predict/p2-answer-b -->
```text
$ git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 0
in-pack: 9
packs: 1
$ find .git/refs -type f | sort
$ grep -c . .git/packed-refs
3
$ git rev-parse --short main
394161e
```
<!-- /snippet -->

`git gc` put all nine objects into one pack and both refs into `packed-refs`, which has three non-empty lines: a header comment, `main` and the tag. No loose ref file is left, and `git rev-parse` still resolves `main`.

<!-- snippet: gates/g5-predict/p2-answer-c -->
```text
$ git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 3
in-pack: 9
packs: 1
$ find .git/refs -type f | sort
.git/refs/heads/main
$ grep -c "$(git rev-parse main)" .git/packed-refs
0
```
<!-- /snippet -->

The new commit wrote three loose objects (blob, tree, commit) and a loose ref for `main`. The line in `packed-refs` still holds the old ID; the loose file wins.

**Marking.** 1 point: 9, 0, 0 and two ref files. 2 points: 0, 9, 1, no ref files, three lines. 2 points: 3, 9, 1, the loose `main` only, and the new ID is not in `packed-refs`. A candidate who predicts that `packed-refs` is updated by the commit has the wrong model of ref storage and loses the last 2.

**Reference.** Chapter 3, sections 3.7 and 3.9.

### P3 (5 points)

<!-- snippet: gates/g5-predict/p3-answer -->
```text
$ git ls-files -s | cut -c1-7,48-
100644  0	NOTES.md
100644  0	conf/base.yaml
120000  0	current.yaml
100755  0	tools/run.sh
$ git ls-files -s NOTES.md
100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	NOTES.md
$ git status --short
 A NOTES.md
A  conf/base.yaml
A  current.yaml
A  tools/run.sh
$ git cat-file -p $(git write-tree) | cut -c1-12,53-
040000 tree 	conf
120000 blob 	current.yaml
040000 tree 	tools
```
<!-- /snippet -->

Entries are sorted by path as bytes, so `NOTES.md` sorts before the lowercase names. The symbolic link is mode `120000`, the executable `100755`. The intent-to-add entry carries the ID of the empty blob and shows in the status as ` A`: nothing staged, an addition in the working tree. An intent-to-add entry is not written into a tree, so the tree has three entries: two subtrees and the link. Git stores the index flat and trees nested: `conf/base.yaml` is one index entry and becomes a tree `conf` with one blob.

**Marking.** 1 point: four lines in this order. 1 point: the three modes. 1 point: the empty blob for `NOTES.md`. 1 point: ` A` for `NOTES.md` and `A ` for the others. 1 point: the three tree entries without `NOTES.md`.

**Reference.** Chapter 3, section 3.12; Chapter 5, sections 5.6 and 5.11; Chapter 4, section 4.10.

### P4 (5 points)

<!-- snippet: gates/g5-predict/p4-answer -->
```text
$ git rev-list --count HEAD
3
$ git rev-list --objects --missing=print HEAD | grep -c '^?'
2
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c | sed 's/^ *//'
warning: This repository uses promisor remotes. Some objects may not be loaded.
2 blob
3 commit
3 tree
$ git show HEAD~1:model.yaml
lr: 0.01
$ git rev-list --objects --missing=print HEAD | grep -c '^?'
1
$ git log --oneline -- model.yaml | wc -l | tr -d " "
3
$ git rev-list --objects --missing=print HEAD | grep -c '^?'
1
$ git log -p --format=%s -- model.yaml | grep -c "^[-+]lr"
5
$ git rev-list --objects --missing=print HEAD | grep -c '^?'
0
```
<!-- /snippet -->

A blobless clone has all three commits and all three trees. Of the four blobs in history (three versions of `model.yaml`, one `README.md`) it has the two that the checkout of `HEAD` needed; two are missing. `git show HEAD~1:model.yaml` fetches one blob on demand. `git log -- model.yaml` needs no blob: it finds the commits that changed the path by comparing tree entries, which are IDs. `git log -p` has to produce diffs, so it fetches the remaining blob.

**Marking.** 1 point: 3 commits, 2 missing. 1 point: 3 commits, 3 trees, 2 blobs. 1 point: 1 missing after `git show`. 2 points: still 1 after `git log --oneline -- model.yaml`, and 0 after `git log -p`. The expected wrong answer is that the path-limited log downloads the blobs.

**Reference.** Chapter 26, section 26.12.

---

## Part 3: Hands-on diagnosis

**End state (12 points).** Run `check.sh`. 12 points for `PASS`; otherwise 12 minus the number of `FAIL` lines, not below zero. A re-clone earns 0 for the whole part: the unpushed commit and the uncommitted work are the reason the clone must be repaired.

**Safety of the path (8 points).**

| Points | Evidence in the log |
|---|---|
| 2 | The faults listed separately, with read-only evidence for each, before the first repair |
| 2 | Each file under `.git` that is removed or written was read or measured first (`ls`, `wc -c`, `cat`, `git cat-file`) |
| 2 | Derived data regenerated with the Git command made for it; `.git/index` not deleted in variant A; no `git reset --hard` in either variant |
| 2 | `git gc` and `git prune` not run before `git fsck` was clean; nothing pushed |

**Explanation (10 points).** 2 points per fault for files, primary or derived, and mechanism (three faults: 6). 2 points: the order of repairs and why. 2 points: the observation that is not damage.

### Variant A (`corpus-sync`): model solution

Four observations, three faults and one property of the clone.

| Observation | Fault | Files | Kind of data |
|---|---|---|---|
| "Could not read", "invalid sha1 pointer" | the pack has no index | `objects/pack/pack-*.idx` (and `.rev`) deleted by the disk cleaner | derived |
| "unable to create lock file" | stale lock from the interrupted `git add` | `.git/index.lock` | neither: an empty leftover |
| (found by `git fsck` after the first repair) | the object file of the staged blob is empty | one file under `objects/` | primary, and the working tree still has the content |
| two commits in `git log`, `git describe` fails | not damage | `.git/shallow` | the clone was made with `--depth 1` |

<!-- snippet: gates/solve-g5-a/01-observe -->
```text
$ cd ravi
$ git log --oneline
error: Could not read 066a06af3553f186ec3ffcc5f3590f3471833fe3
fatal: Failed to traverse parents of commit 9c7817a0e0aef9c1b9dfe38ddc3b935ccf4f257b
[exit status: 128]
$ git status -sb 2>&1 | tail -2
## main...origin/main [gone]
A  sync/manifest.py
$ ls .git/objects/pack
pack-f22e71a14811a5f70ee2a939943799c72580ba93.pack
$ git count-objects -v 2>&1 | grep -E '^(warning|count|in-pack|packs|garbage):'
warning: no corresponding .idx: .git/objects/pack/pack-f22e71a14811a5f70ee2a939943799c72580ba93.pack
count: 5
in-pack: 0
packs: 0
garbage: 1
```
<!-- /snippet -->

The pack is there and its index is not: `git count-objects -v` says so in its warning and counts the pack as garbage. This is repaired first, because until Git can read the packed objects no other diagnosis is trustworthy.

<!-- snippet: gates/solve-g5-a/02-pack-index -->
```text
# A pack without its .idx: the objects are there and Git cannot find them. The index is derived data.
$ git index-pack .git/objects/pack/pack-*.pack
f22e71a14811a5f70ee2a939943799c72580ba93
$ ls .git/objects/pack
pack-f22e71a14811a5f70ee2a939943799c72580ba93.idx
pack-f22e71a14811a5f70ee2a939943799c72580ba93.pack
pack-f22e71a14811a5f70ee2a939943799c72580ba93.rev
$ git log --oneline
9c7817a Skip keys that already exist
066a06a Add README
$ git count-objects -v 2>&1 | grep -E '^(warning|count|in-pack|packs|garbage):'
count: 5
in-pack: 7
packs: 1
garbage: 0
```
<!-- /snippet -->

<!-- snippet: gates/solve-g5-a/03-lock -->
```text
$ git add README.md
fatal: Unable to create '$LAB/gates/solve-g5-a/ravi/.git/index.lock': File exists.

Another git process seems to be running in this repository, or the lock file may be stale
[exit status: 128]
# Before removing a lock: make sure no Git process is working in this repository (pgrep -fl git).
$ rm .git/index.lock
$ git status -sb
## main...origin/main [ahead 1]
A  sync/manifest.py
```
<!-- /snippet -->

The lock is removed only after making sure that no Git process is working in the repository. The index itself is intact and holds the staged entry, so it must not be deleted.

<!-- snippet: gates/solve-g5-a/04-fsck -->
```text
$ git fsck --no-dangling
error: object file .git/objects/c4/00d9c844fb249dcb5068ce369dfe01d873f8c8 is empty
error: unable to mmap .git/objects/c4/00d9c844fb249dcb5068ce369dfe01d873f8c8: No such file or directory
error: c400d9c844fb249dcb5068ce369dfe01d873f8c8: object corrupt or missing: .git/objects/c4/00d9c844fb249dcb5068ce369dfe01d873f8c8
missing blob c400d9c844fb249dcb5068ce369dfe01d873f8c8
[exit status: 3]
$ git ls-files -s sync/manifest.py
100644 c400d9c844fb249dcb5068ce369dfe01d873f8c8 0	sync/manifest.py
```
<!-- /snippet -->

`git fsck` now finds the third fault. The index entry names a blob whose file is empty: the power cut came between creating the file and writing its content. The ID is the hash of the content, and the content is in the working tree, so the object can be made again.

<!-- snippet: gates/solve-g5-a/05-rebuild-object -->
```text
# The blob named by the index entry is an empty file. The content is in the working tree.
$ git hash-object sync/manifest.py
c400d9c844fb249dcb5068ce369dfe01d873f8c8
$ git hash-object -w sync/manifest.py
c400d9c844fb249dcb5068ce369dfe01d873f8c8
$ git cat-file -t :sync/manifest.py
error: object file .git/objects/c4/00d9c844fb249dcb5068ce369dfe01d873f8c8 is empty
fatal: git cat-file: could not get object info
[exit status: 128]
# An object file that exists is not rewritten. Remove the empty file, then write the object.
$ rm -f .git/objects/c4/00d9c844fb249dcb5068ce369dfe01d873f8c8
$ git hash-object -w sync/manifest.py
c400d9c844fb249dcb5068ce369dfe01d873f8c8
$ git cat-file -t :sync/manifest.py
blob
$ git fsck --no-dangling
[exit status: 0]
```
<!-- /snippet -->

The first `git hash-object -w` prints the right ID and repairs nothing: Git does not rewrite an object file that already exists. The empty file has to be removed first. This is the same trap as with a corrupt object that is restored from another clone.

<!-- snippet: gates/solve-g5-a/06-shallow -->
```text
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
066a06af3553f186ec3ffcc5f3590f3471833fe3
$ git log --oneline
9c7817a Skip keys that already exist
066a06a Add README
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git fetch --unshallow
From ../server
 * [new tag]         v1.2.0     -> v1.2.0
$ git log --oneline
9c7817a Skip keys that already exist
066a06a Add README
6c630a0 Add copy step
0199918 Add listing diff
4359deb Add remote listing
$ git describe
v1.2.0-3-g9c7817a
```
<!-- /snippet -->

The short history is not damage. `.git/shallow` names the boundary commit: the team's bootstrap script cloned with `--depth 1`. `git describe` failed because the tag lies behind the boundary. `git fetch --unshallow` fetches the rest of the history and the tag that became reachable.

<!-- snippet: gates/solve-g5-a/07-verify -->
```text
$ git status -sb
## main...origin/main [ahead 1]
A  sync/manifest.py
$ git fsck --no-dangling
[exit status: 0]
$ cd ..
$ assessments/gen/gate-5-internals/variant-a/check.sh
Checking g5-a
  ok    every pack has its index
  ok    no index.lock is left
  ok    git fsck reports nothing
  ok    HEAD is on main
  ok    main still has Ravi's commit on top
  ok    the staged file is still staged, with the same blob
  ok    that blob can be read
  ok    git status reports the staged file and nothing else
  ok    the clone is no longer shallow
  ok    the whole history is there
  ok    git describe finds the release tag
  ok    the server has not been changed
PASS: the end state of g5-a is right.
[exit status: 0]
```
<!-- /snippet -->

**Partial credit and common mistakes, variant A.**

- `rm .git/index` and `git reset` "to clear the lock problem": the staged entry is gone and `sync/manifest.py` is untracked. Two lines of the check fail; 0 for the third safety row.
- `git gc` or `git repack` to "regenerate the index of the pack": fails while the pack cannot be read, or, after other repairs, is harmless. Before `git fsck` is clean it costs the fourth safety row.
- `git add sync/manifest.py` instead of removing the empty object file: it also reports success and leaves the empty file in place. The candidate must notice with `git fsck`.
- `git fetch --depth=100` or `--deepen`: acceptable if the result is a complete history; the check asks whether the repository is still shallow.
- Calling the shallow history "corruption": 0 for the last 2 explanation points.

**Reference.** Chapter 3, sections 3.7, 3.8 and 3.15; Chapter 5, section 5.15; Chapter 13, section 13.11; Chapter 26, section 26.11.

### Variant B (`shardlog`): model solution

| Observation | Fault | Files | Kind of data |
|---|---|---|---|
| "your current branch appears to be broken" | the ref file of `main` is empty | `.git/refs/heads/main`, written by the sync client | primary; the reflog still records the value |
| (appears after the first repair) "index file smaller than expected" | the index is truncated | `.git/index` | the staging content is primary, the rest derived; nothing was staged |
| `git show v1.0.0:...` needs a remote | not damage | `remote.origin.promisor`, `remote.origin.partialclonefilter` | a blobless partial clone |
| "does not appear to be a git repository" | the remote moved | `remote.origin.url` in `.git/config` | configuration |

<!-- snippet: gates/solve-g5-b/01-observe -->
```text
$ cd asha
$ git log --oneline -1
fatal: your current branch appears to be broken
[exit status: 128]
$ cat .git/HEAD
ref: refs/heads/main
$ wc -c < .git/refs/heads/main | tr -d " "
0
$ grep -c refs/heads/main .git/packed-refs
0
$ tail -2 .git/logs/refs/heads/main | cut -d' ' -f1,2 | cut -c1-90
0000000000000000000000000000000000000000 0fc3166fa8b62a27c806d32aaef8f8fdc415307a
0fc3166fa8b62a27c806d32aaef8f8fdc415307a bbe8520c019e98fefe79267f0323d022a72c9f49
$ tail -2 .git/logs/refs/heads/main | cut -f2
clone: from file://$LAB/gates/solve-g5-b/server-old.git
commit: Add shard id to the writer
```
<!-- /snippet -->

`HEAD` is fine. The file it names has zero bytes, and `packed-refs` has no line for `main`. The branch's reflog is a separate file and still holds the last value: the commit Asha made on Friday.

<!-- snippet: gates/solve-g5-b/02-ref -->
```text
$ git cat-file -t bbe8520
commit
$ git update-ref refs/heads/main bbe8520
fatal: update_ref failed for ref 'refs/heads/main': cannot lock ref 'refs/heads/main': unable to resolve reference 'refs/heads/main': reference broken
[exit status: 128]
# A broken ref cannot be locked for an update. Remove the empty file, then write the ref.
$ rm .git/refs/heads/main
$ git update-ref -m 'repair: empty ref file' refs/heads/main bbe8520c019e98fefe79267f0323d022a72c9f49
$ git log --oneline -2
bbe8520 Add shard id to the writer
0fc3166 Add README
```
<!-- /snippet -->

`git update-ref` cannot lock a ref it cannot resolve, so the empty file is removed first. The ref is repaired before the index, and the order matters: `git reset` rebuilds the index from `HEAD`. With `HEAD` pointing at a branch that does not resolve, the rebuilt index is empty and every file of the project is reported as untracked.

<!-- snippet: gates/solve-g5-b/03-index -->
```text
$ git status -sb
fatal: .git/index: index file smaller than expected
[exit status: 128]
$ wc -c < .git/index | tr -d " "
4
# The index is rebuilt from HEAD. The working tree is not touched by a mixed reset.
$ rm .git/index
$ git reset
Unstaged changes after reset:
M	README.md
$ git status -sb
## main...origin/main [ahead 1]
 M README.md
$ git diff --stat
 README.md | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

A mixed reset writes the index from the tree of `HEAD` and leaves the working tree alone: the README edit is reported as an unstaged change. `git reset --hard` would have destroyed it. What a rebuilt index cannot bring back is the difference between staged and unstaged changes, conflict stages and flag bits. Asha had nothing staged, so nothing is lost.

<!-- snippet: gates/solve-g5-b/04-partial -->
```text
$ git config get --all --show-origin remote.origin.url
file:.git/config	../server-old.git
$ git config get remote.origin.promisor
true
$ git config get remote.origin.partialclonefilter
blob:none
$ git rev-list --objects --missing=print v1.0.0 | grep -c '^?'
1
$ git show v1.0.0:shardlog/schema.py
fatal: '../server-old.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch 7d24a25b670b30c3764594109ab181bc8f31d338 from promisor remote
[exit status: 128]
```
<!-- /snippet -->

No history is missing. The clone is a blobless partial clone: every commit and tree is local, and one blob of the tagged version is not, because no checkout ever needed it. Git tried to fetch it from the promisor remote, whose path no longer exists.

<!-- snippet: gates/solve-g5-b/05-remote -->
```text
$ git remote set-url origin ../server.git
$ git ls-remote origin
0fc3166fa8b62a27c806d32aaef8f8fdc415307a	HEAD
0fc3166fa8b62a27c806d32aaef8f8fdc415307a	refs/heads/main
3242870778135703cf2e94f9b8bc9c09386b3e88	refs/tags/v1.0.0
2e62578b85e7799aad1422e4c0b63ca1943466e3	refs/tags/v1.0.0^{}
$ git show v1.0.0:shardlog/schema.py
FIELDS = ["ts", "shard", "payload"]
$ git rev-list --objects --missing=print v1.0.0 | grep -c '^?'
0
$ GIT_NO_LAZY_FETCH=1 git show v1.0.0:shardlog/schema.py
FIELDS = ["ts", "shard", "payload"]
```
<!-- /snippet -->

After the URL is corrected, the first `git show` fetches the blob, and from then on the object is local: the last command reads it with lazy fetching switched off.

<!-- snippet: gates/solve-g5-b/06-verify -->
```text
$ git fetch
$ git status -sb
## main...origin/main [ahead 1]
 M README.md
$ git fsck --no-dangling
[exit status: 0]
$ cd ..
$ assessments/gen/gate-5-internals/variant-b/check.sh
Checking g5-b
  ok    HEAD is on main
  ok    main names Asha's unpushed commit
  ok    the index can be read and equals HEAD
  ok    the README edit is still in the working tree
  ok    git status reports the README edit, unstaged, and nothing else
  ok    the remote origin can be reached
  ok    the clone is still a partial clone of origin
  ok    the 1.0.0 schema can be read without the network
  ok    git fsck reports nothing
  ok    the server has not been changed
PASS: the end state of g5-b is right.
[exit status: 0]
```
<!-- /snippet -->

**Partial credit and common mistakes, variant B.**

- Rebuilding the index before the ref: everything is untracked. Recoverable by repairing the ref and resetting again; minus 1 safety point if the candidate noticed and explained, minus 2 if not.
- `git reset --hard` to rebuild the index: the README edit is destroyed, and no object holds it. Two lines of the check fail; 0 for safety.
- Writing the ID into `.git/refs/heads/main` with an editor: works in the files format. Accepted if the ID was first verified with `git cat-file -t`; say that `git update-ref` also writes the reflog.
- Taking the ID from `origin/main` instead of the reflog: `main` then lacks the unpushed commit. One line fails, and the commit is one more reflog line away from being forgotten.
- "Fixing" the partial clone by unsetting the promisor settings: the next command that needs a missing blob fails with a missing object, permanently. One line fails.
- `git fetch --refetch` or `--unshallow`: the first downloads everything again and is allowed, although unnecessary; the second does not apply, the clone is not shallow.

**Reference.** Chapter 3, sections 3.9, 3.11 and 3.12; Chapter 5, section 5.15; Chapter 13, section 13.11; Chapter 26, section 26.12.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** As objects in a content-addressed database: each object is stored under the hash of its type, size and content, first as a compressed loose file and later inside packfiles. Names for objects are kept separately, as refs. *Follow-up:* a blob is the bytes of one file and nothing else. A tree is one directory listing: entries of mode, name and object ID. A commit names one root tree, its parent commits, author, committer and message. The name of a file is in the tree that lists it, never in the blob, which is why a rename costs no new blob.

**Weak answer.** "Git stores the files and their changes." **Reference.** Chapter 3, sections 3.3 and 3.4.

### O2 (3 points)

**Model answer.** An object is reachable if you can arrive at it from a starting point by following the IDs stored inside objects: commit to tree and parents, tree to blobs and subtrees, tag to its target. Everything Git promises to keep is defined by it. *Follow-up:* `git fsck` starts from the refs, the index, `HEAD` and the reflogs. A missing object is one that something reachable refers to and that cannot be read: damage. A dangling object exists and nothing refers to it: routine, the residue of amends, rebases and unstaged content.

**Weak answer.** "Whether the commit is on a branch." **Reference.** Chapter 3, section 3.8.

### O3 (3 points)

**Model answer.** A collection repacks objects into packs, packs refs, expires old reflog entries, and deletes objects that are unreachable and older than the grace period. It never deletes anything reachable from a ref, the index or a reflog entry that has not expired. *Follow-up:* no. A collection does not repair anything: it needs to read every reachable object and fails on the corrupt one, and `--prune=now` deletes exactly the unreachable objects that might be the only surviving copy of lost work. First `git fsck`, then restore the damaged object from another copy or from the working tree.

**Weak answer.** "It cleans up old commits." **Reference.** Chapter 26, sections 26.3 and 26.5; Chapter 13, sections 13.4 and 13.13.

### O4 (3 points)

**Model answer.** The server advertises its refs and their IDs. The client says which of them it wants and which commits it already has. The server computes the objects reachable from the wants and not from the haves and sends them as one pack; the client indexes the pack and updates its remote-tracking refs. *Follow-up:* the negotiation is by commits, and my refs say I have those commits, so the server sends nothing. The damaged object has to be fetched explicitly from a healthy copy, or everything refetched with `git fetch --refetch`, or rebuilt from the working tree with `git hash-object -w` after removing the bad file.

**Weak answer.** "It downloads the changes." **Reference.** Chapter 26, section 26.10; Chapter 13, section 13.11.

### O5 (4 points)

**Model answer.** Without `--verify`, `git rev-parse` prints an argument it cannot resolve to standard output, writes an error to standard error and exits with status 128, because its first job is to sort a script's arguments into revisions and other things. The script captured the output and never looked at the status. The line should be `id=$(git rev-parse --verify --quiet "$BRANCH^{commit}") || exit 1`. *Follow-up:* `.git/HEAD` contains `ref: refs/heads/<name>` only while a branch is checked out. On a CI runner the checkout is usually detached and the file holds a commit ID; in a linked worktree `.git` is a file and `HEAD` is elsewhere; with reftable the file is a stub. Ask Git: `git symbolic-ref --short -q HEAD`, with a fallback for the detached case. The production consequence is the one in the question: a deploy of something that is not a commit.

**Weak answer.** "Add a check that the output is 40 characters." **Reference.** Chapter 3, sections 3.6 (root-cause box) and 3.9.

### O6 (4 points)

**Model answer.** `git status` does three things: it reads the index, it calls `lstat` on every tracked file to compare with the cached stat data, and it scans the working tree for untracked files, reading ignore rules as it goes. With 300,000 entries, each part is large. The file-system monitor replaces the `lstat` pass by a question to a daemon about what changed; the untracked cache remembers directories without untracked files; a sparse checkout in cone mode shrinks the working tree to the directories you work on, and the sparse index shrinks the index with it. `scalar` sets these up together with a partial clone and scheduled maintenance. Measure before and after with `GIT_TRACE2_PERF` or `GIT_TRACE_PERFORMANCE`. *Follow-up:* in a sparse checkout the files outside the cone are in the repository, in the index and in every commit, and not on disk. A script that walks the working tree sees only the cone. It asked a working-tree question where a repository question was meant: use `git ls-files`, `git grep --cached` or `git ls-tree -r HEAD`.

**Weak answer.** "Run `git gc`." **Reference.** Chapter 26, sections 26.2 and 26.9; Chapter 24, sections 24.4 to 24.6 (root-cause box in 24.5).

# Solutions to the exercises of Modules 16 to 18

> **Baseline.** Git 2.55.0 on macOS. Every transcript below is real output of a replay script in `labs/ex2/`: `answers-mNN.sh` for exercises 1 to 8 of a module, `solve-<name>.sh` for each Level 4 exercise. `labs/run ex2/<script name>` replays one of them on your machine. `$LAB` stands for the lab root.

The questions are in [exercises/m16-m18-internals.md](../exercises/m16-m18-internals.md). Each solution has the same five parts: the solution, the reasoning, the common mistakes, the expert approach, and the textbook sections that teach it.

Sizes inside a pack (the fourth column of `git verify-pack -v`) depend on the compression library, so yours may differ by a few bytes. Object IDs of blobs and trees, and the IDs of commits made by a generator, are the same on every machine.

---

## Module 16: The object database and its maintenance

### Exercise 16.1

**Solution.**

<!-- snippet: ex2/answers-m16/16-1-hash -->
```text
$ printf 'shards: 16\n' > shards.yaml
$ git hash-object shards.yaml
1c52e2e1498d7a2df887ca9b2bbd1fd9601f0696
$ printf 'blob 11\0shards: 16\n' | shasum
1c52e2e1498d7a2df887ca9b2bbd1fd9601f0696  -
$ find .git/objects -type f | wc -l
       0
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-1-write -->
```text
$ git hash-object -w shards.yaml
1c52e2e1498d7a2df887ca9b2bbd1fd9601f0696
$ find .git/objects -type f
.git/objects/1c/52e2e1498d7a2df887ca9b2bbd1fd9601f0696
$ python3 -c 'import sys, zlib; print(zlib.decompress(open(sys.argv[1], "rb").read()))' .git/objects/1c/52e2e1498d7a2df887ca9b2bbd1fd9601f0696
b'blob 11\x00shards: 16\n'
$ cp shards.yaml other.yaml && git hash-object other.yaml
1c52e2e1498d7a2df887ca9b2bbd1fd9601f0696
```
<!-- /snippet -->

1. The header `blob <size>`, a NUL byte, then the content. 11 is the number of bytes of the content: ten characters and the line feed.
2. The first two hexadecimal digits are the directory, the other 38 the file name.
3. In tree objects. A blob is content and nothing else, which is why two files with the same content share one blob.
4. `-w` writes the object into the object database. The count of zero before it proves that plain `git hash-object` only computes.
5. The same ID, `1c52e2e`: the last command of the second transcript shows it for `other.yaml`. The ID depends on the bytes, not on the name, the repository or the time.

**Reasoning.** Git's object database is a content-addressed store: the key is a hash of type, size and content. The loose object file is that same byte string, compressed with zlib, which the Python line makes visible.

**Common mistakes.** Hashing the file alone (`shasum shards.yaml`), without the header. Getting the size wrong by forgetting the trailing line feed, or by using `echo -n`. Expecting the file name or the mode inside the blob.

**Expert approach.** Use the property instead of memorizing it: "is this file identical to the one in that commit" is `git hash-object <file>` against `git rev-parse <commit>:<path>`, with no diff and no checkout.

**Reference.** Chapter 3, section 3.3 (the loose object format, the hash reproduced with `shasum`, the zlib one-liner). Content addressing: Chapter 2, section 2.4.

### Exercise 16.2

**Solution.**

<!-- snippet: ex2/answers-m16/16-2-chain -->
```text
$ git cat-file -p HEAD
tree b97ac59d42154f8b22b1ab96cd409c69aeb85904
parent 83671527ccbe3e5f09b5979c16a638749a6e281a
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Add README
$ git cat-file -p 'HEAD^{tree}'
100644 blob 664032fa313f8829df7221939f62064fa59dd2af	README.md
040000 tree ecb17dc81e1725d2f96816c05eca1ce253c00d22	config
040000 tree d40acba780ecb22476af8f0e51f817aecc28f0c5	shardmap
$ git cat-file -p HEAD:config
100644 blob 9fbebee70cdac5c2c05d0ff50703b85b5d27ea75	shards.yaml
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-2-blob -->
```text
$ git rev-parse HEAD:config/shards.yaml
9fbebee70cdac5c2c05d0ff50703b85b5d27ea75
$ git cat-file -t 9fbebee
blob
$ git cat-file -s 9fbebee
23
$ git cat-file -p 9fbebee
shards: 16
replicas: 2
$ git ls-tree -r HEAD
100644 blob 664032fa313f8829df7221939f62064fa59dd2af	README.md
100644 blob 9fbebee70cdac5c2c05d0ff50703b85b5d27ea75	config/shards.yaml
100644 blob b75b379eb1e2e6e3ad2557d80c03eff8a6d3dd48	shardmap/assign.py
```
<!-- /snippet -->

1. `tree`, `parent`, `author`, `committer`, then a blank line and the message. A commit with the same files by someone else a minute later has the same `tree` line and differs in `author`, `committer` and both timestamps, so its ID differs.
2. Four: the commit, the root tree, the tree of `config`, and the blob.
3. Mode, object type, object ID. A subdirectory is `040000` (a tree), an executable file `100755`, a submodule `160000` (a commit in another repository).
4. `-r` descends into the trees and prints only the leaves, with their full paths. The trees are still there; they are what the paths are assembled from.

**Reasoning.** A commit names one tree. A tree names blobs and trees. Every path in a snapshot is a walk through tree objects, and every object on the walk is named by the hash of its content, so a commit ID fixes the content of every file in it.

**Common mistakes.** Looking for the diff inside the commit object: there is none. Expecting a tree entry per path in the root tree: each tree lists one directory level. Reading `100644` as full Unix permissions: Git records only whether a file is executable.

**Expert approach.** `git rev-parse <commit>:<path>` and `git cat-file -p` reach any object in two commands. `git cat-file --batch-check` does the same for thousands of names in one process.

**Reference.** Chapter 3, section 3.4 (the four object types, tree entries and modes) and section 3.5 (`git cat-file`, `git ls-tree`).

### Exercise 16.3

**Solution.**

<!-- snippet: ex2/answers-m16/16-3-before -->
```text
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 33
in-pack: 0
packs: 0
$ git gc -q
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 33
packs: 1
$ find .git/objects -type f | sed "s/[0-9a-f]\{40\}/ID/" | sort
.git/objects/info/commit-graph
.git/objects/info/packs
.git/objects/pack/pack-ID.idx
.git/objects/pack/pack-ID.pack
.git/objects/pack/pack-ID.rev
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-3-pack -->
```text
$ git cat-file --batch-check --batch-all-objects | awk '{print $2}' | sort | uniq -c
   9 blob
   8 commit
  16 tree
$ git verify-pack -v .git/objects/pack/pack-*.idx | awk '$2 == "blob" && NF == 7'
d4c7ef78896ff66ed5c7f48378265fad38dc318e blob   200 185 2429 1 4dffb31cf0668013d0ebff3828c87b9ca0e0365e
91c1487a13e0fc60023a88b33d96aa3f61c5b509 blob   202 185 3214 1 4dffb31cf0668013d0ebff3828c87b9ca0e0365e
cfb9e7db622bdf804277022110152b678cb151da blob   203 186 3797 1 4dffb31cf0668013d0ebff3828c87b9ca0e0365e
73b9d713fcf42e340ab4b082d6b28c9cc3e2e29e blob   203 185 4182 1 4dffb31cf0668013d0ebff3828c87b9ca0e0365e
08f15dcf32f1525a66ba087bdeadfa0f0600271c blob   205 186 4566 1 4dffb31cf0668013d0ebff3828c87b9ca0e0365e
$ git verify-pack -v .git/objects/pack/pack-*.idx | tail -5
ecb17dc81e1725d2f96816c05eca1ce253c00d22 tree   39 50 4865
a95856d2f7bf3702029a378b9c1afac01ceaf08a tree   68 76 4915
non delta: 28 objects
chain length = 1: 5 objects
.git/objects/pack/pack-2eec184b8c8d2f469c8146415c6f5d8b22362028.pack: ok
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-3-base -->
```text
$ for c in $(git rev-list --reverse HEAD -- config/assignments.yaml); do echo "$(git log -1 --format=%s ${c}): $(git rev-parse --short "${c}:config/assignments.yaml"), $(git cat-file -s "${c}:config/assignments.yaml") bytes"; done
Rebalance shards, round 1: 08f15dc, 6150 bytes
Rebalance shards, round 2: 73b9d71, 6150 bytes
Rebalance shards, round 3: cfb9e7d, 6150 bytes
Rebalance shards, round 4: 4dffb31, 6150 bytes
Rebalance shards, round 5: 91c1487, 6149 bytes
Rebalance shards, round 6: d4c7ef7, 6149 bytes
```
<!-- /snippet -->

1. 33 loose objects became 33 objects in one pack. No ID changed, and the type counts are the same: packing changes how objects are stored, not what they are.
2. `.pack` holds the objects. `.idx` maps an object ID to its position in the pack. `.rev` is the reverse map, from position to index entry. `git gc` also wrote `objects/info/commit-graph` and `objects/info/packs`.
3. The depth of the delta chain and the ID of the base object. For such an object the pack stores instructions (copy this range from the base, insert these bytes) and not the content; the third column is then the size of the delta, about 200 bytes here against 6,150 for the whole file.
4. No. A delta is a storage detail inside a pack, chosen by size heuristics between any two similar objects, and it is invisible above the object layer: `git cat-file -p` returns the complete blob for every one of the six IDs. The commit still names a tree, the tree still names a complete blob.
5. The version of round 4, `4dffb31`: neither the oldest nor the newest. The other five, older and newer, are deltas against it with a chain length of 1. In the example of Chapter 3, section 3.7 the whole version is the newest one. What the two cases have in common: in both, the object stored whole is one of the largest versions (here four versions tie at 6,150 bytes and the two newest are one byte smaller), and in both, older versions are reconstructed from a newer one.

> **Unverified.** Which object becomes the base is decided by packing heuristics that this course does not document in detail. The observation above is from this run; do not build a rule on it.

**Reasoning.** Loose objects are simple and wasteful: one compressed file per object, however similar two objects are. A pack stores similar objects as deltas and adds an index for lookup. Nothing a user-level command reports changes.

**Common mistakes.** Concluding that Git "stores diffs between commits". Reading the delta size as the size of the object. Believing that `git gc` is needed for correctness: it is housekeeping, and since Git 2.54 the default automatic maintenance does it incrementally.

**Expert approach.** `git count-objects -v` before and after, `git verify-pack -v ... | tail -3` for the chain statistics, and `git cat-file --batch-all-objects --batch-check` when you need every object with type and size.

**Reference.** Chapter 3, section 3.7 (packfiles, pack indexes, delta compression, `git verify-pack -v`). Chapter 26, section 26.3 (`git gc` and `git maintenance`).

### Exercise 16.4

**Solution.**

<!-- snippet: ex2/answers-m16/16-4-setup -->
```text
$ git init -q objects-lab && cd objects-lab
$ echo 'shards: 16' > a.yaml && cp a.yaml b.yaml && git add a.yaml b.yaml
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-4-answers -->
```text
$ git count-objects -v | head -1
count: 1
$ git commit -q -m 'Add two files' && git count-objects -v | head -1
count: 3
$ git commit -q --amend -m 'Add two identical files' && git count-objects -v | head -1
count: 4
$ mkdir config && git mv a.yaml config/a.yaml && git commit -q -m 'Move a file' && git count-objects -v | head -1
count: 7
$ echo 'shards: 32' > b.yaml && git commit -q -am 'Use 32 shards' && git count-objects -v | head -1
count: 10
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-4-types -->
```text
$ git cat-file --batch-check --batch-all-objects | awk '{print $2}' | sort | uniq -c
   2 blob
   4 commit
   4 tree
```
<!-- /snippet -->

| Step | Count | New objects |
|---|---|---|
| `git add` of two identical files | 1 | one blob: same content, same ID, stored once |
| first commit | 3 | the root tree, the commit |
| amend, message only | 4 | one commit; the tree is reused |
| move `a.yaml` into `config/` | 7 | the tree of `config`, a new root tree, the commit; no blob |
| change `b.yaml` | 10 | one blob, a new root tree, the commit; the tree of `config` is reused |

Two blobs, four commits, four trees.

**Reasoning.** `git add` writes blobs. `git commit` writes one tree per directory whose content changed, and one commit. An object whose content already exists is not written again, which is why identical files, renames and unchanged directories cost nothing.

**Common mistakes.** Two blobs for two identical files. Forgetting that the amended commit stays in the database (four commit objects, three on the branch). A new blob for the move. A new `config` tree in the last step.

**Expert approach.** Predict object counts from "what content is new". It is the quickest way to check whether your model of an operation is right, and it explains why a commit that touches one file in a repository with 100,000 files writes a handful of objects.

**Reference.** Chapter 2, section 2.3 (snapshots share unchanged blobs) and section 2.4. Chapter 3, section 3.4. What `git add` writes: Chapter 5, section 5.3.

### Exercise 16.5

**Solution.**

<!-- snippet: ex2/answers-m16/16-5-start -->
```text
$ git branch -a
* main
$ git reflog | grep consistent
9abf85a HEAD@{0}: checkout: moving from spike/consistent-hashing to main
9b3fc36 HEAD@{1}: commit: Try consistent hashing
9abf85a HEAD@{2}: checkout: moving from main to spike/consistent-hashing
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 13
in-pack: 0
packs: 0
```
<!-- /snippet -->

Point 1, after `git gc`:

<!-- snippet: ex2/answers-m16/16-5-gc -->
```text
$ git gc -q
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 13
packs: 1
$ git cat-file -t 9b3fc36
commit
```
<!-- /snippet -->

Point 2, after expiring the reflogs and collecting again:

<!-- snippet: ex2/answers-m16/16-5-cruft -->
```text
$ git reflog expire --expire=now --all
$ git gc -q
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 13
packs: 2
$ ls .git/objects/pack | sed "s/[0-9a-f]\{40\}/ID/" | sort
pack-ID.idx
pack-ID.idx
pack-ID.mtimes
pack-ID.pack
pack-ID.pack
pack-ID.rev
pack-ID.rev
$ git cat-file -t 9b3fc36
commit
```
<!-- /snippet -->

Point 3, after `git gc --prune=now`:

<!-- snippet: ex2/answers-m16/16-5-prune -->
```text
$ git gc -q --prune=now
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 9
packs: 1
$ git cat-file -t 9b3fc36
fatal: Not a valid object name 9b3fc36
[exit status: 128]
```
<!-- /snippet -->

1. One pack with all 13 objects, and the commit is readable. The HEAD reflog still names it (`HEAD@{1}`), and `git gc` treats reflog entries as starting points, so the object counts as reachable and is packed with everything else.
2. Two packs, still 13 objects, and the commit is still readable. With the reflogs empty the commit is unreachable. `git gc` does not delete unreachable objects that are younger than the grace period; it moves them into a cruft pack, the one with the `.mtimes` file, which records when each was last touched.
3. One pack with 9 objects, and the name no longer resolves. `--prune=now` sets the grace period to zero, so the cruft was deleted: the commit, its two trees and its blob.

How long each protection lasts with default settings: a reflog entry for a commit that is not reachable from the current tip is kept 30 days (`gc.reflogExpireUnreachable`; 90 days for reachable ones), and after that the unreachable object is kept until it is two weeks old (`gc.pruneExpire`). The lab configuration sets the reflog periods to `never`, which is why the exercise expires them explicitly.

**Reasoning.** Two independent safety nets stand between `git branch -D` and the loss of the commit: the reflog, which keeps the object reachable, and the grace period, which keeps unreachable objects for a while. `git gc` respects both. Only the explicit pair `git reflog expire --expire=now --all` and `git gc --prune=now` removes both at once.

**Common mistakes.** Expecting the first `git gc` to delete the commit. Expecting `git reflog expire` alone to delete it. Reading "packs: 2" as a failed repack. Running the last two commands in a real repository to "clean up": they are the point of no return for everything unreachable, not only for the object you had in mind.

**Expert approach.** Before any pruning, list what would go: `git fsck --unreachable --no-reflogs`. In a real repository let the defaults work; the only reason to force pruning is content that must not exist any more (exercise 16.9).

**Reference.** Chapter 26, section 26.3 (`git gc`) and section 26.5 (cruft packs, the `.mtimes` file, pruning with no grace period). Chapter 13, section 13.4 (retention defaults) and section 13.13 (the point of no return).

### Exercise 16.6

**Solution.**

<!-- snippet: ex2/answers-m16/16-6-largest -->
```text
$ git ls-files
README.md
config/shards.yaml
shardmap/assign.py
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' | awk '$1 == "blob"' | sort -k2 -n -r | head -3
blob 240000 aa9f5abe37c4f9de001ec22b6c48fb7e10fb034d fixtures/index.bin
blob 150000 49a2c3ce5dfb0df000951296a0e899708bc485dc data/tenants.snapshot
blob 90000 6c90768a015f22f51183ca4b186c349cae1eb06d data/tenants.snapshot
```
<!-- /snippet -->

The pipeline: `git rev-list --objects --all` prints every object reachable from any ref, with the path under which it was first found; `git cat-file --batch-check` with a format adds type and size and passes the path through as `%(rest)`; `awk` keeps the blobs; `sort` orders by size.

<!-- snippet: ex2/answers-m16/16-6-where -->
```text
$ git log --oneline --diff-filter=A -- fixtures/index.bin
40b3154 Add index fixture
$ git log --oneline --diff-filter=D -- fixtures/index.bin
e08c340 Remove load-test data from the repository
$ git cat-file -e aa9f5ab && echo still in the object database
still in the object database
```
<!-- /snippet -->

The largest blob is `fixtures/index.bin`, 240,000 bytes, added in `40b3154` and removed in `e08c340`. `git cat-file -e` succeeds: the object is still in the database.

Removing a file in a commit creates a new tree without the entry. The commits before it are unchanged, they are ancestors of `main`, and their trees still name the blob. Reachable objects are never collected. The repository can become smaller only if no commit that contains the blob is reachable any more, which means rewriting history from the commit that added it.

**Reasoning.** Repository size is the size of everything reachable from any ref, across all of history, not the size of the newest snapshot. A deletion adds to history; it does not subtract.

**Common mistakes.** Measuring the working tree. Sorting `git ls-files` by size, which sees only the current commit. Leaving out `--all` and missing blobs that live on other branches. Expecting `git gc` to help.

**Expert approach.** Keep the pipeline as an alias. For a first overview of a repository you do not know, the same listing grouped by path shows which paths cost the most over time. Decide about a rewrite by cost and benefit: it changes every commit ID after the first affected commit, for everyone.

**Reference.** Chapter 3, section 3.5 (`git cat-file --batch-check` with a format) and section 3.8 (reachability). Chapter 26, section 26.2 (what makes a repository large). Finding the adding and deleting commit: Chapter 14A, section 14A.13.

### Exercise 16.7

**Solution.**

<!-- snippet: ex2/answers-m16/16-7-fsck -->
```text
$ git fsck
dangling commit c9f6702e847cd19d630a7cc16a171e3e19d394dc
dangling blob 35c035a45b0035965145d4564e8c8557083b30f7
missing blob b75b379eb1e2e6e3ad2557d80c03eff8a6d3dd48
[exit status: 2]
$ git status -sb
## main
$ git show HEAD:shardmap/assign.py
fatal: bad object HEAD:shardmap/assign.py
[exit status: 128]
```
<!-- /snippet -->

Three lines, two kinds.

**Harmless: the two `dangling` lines.** A dangling object is complete and readable; nothing refers to it.

<!-- snippet: ex2/answers-m16/16-7-dangling -->
```text
$ git show -s --format='%h %s' c9f6702
c9f6702 Try weighted tenants
$ git cat-file -p 35c035a
shards: 32
replicas: 2
```
<!-- /snippet -->

The commit is the tip of a branch that was deleted ("Try weighted tenants"). The blob is a version of `config/shards.yaml` that was staged with `git add` and replaced by another version before the commit. Both are leftovers of normal work and will be pruned by a later garbage collection. Neither is a reason to do anything.

**Damage: `missing blob`.** An object that a reachable tree names cannot be read. `git status` works, because it compares the working tree with the index and needs no blob content; `git show HEAD:shardmap/assign.py` fails, as would `git diff` against an older commit, `git checkout` of the path, a clone, and a push that has to send the object.

<!-- snippet: ex2/answers-m16/16-7-missing -->
```text
$ git ls-tree -r HEAD | grep b75b379eb1e2e6e3ad2557d80c03eff8a6d3dd48
100644 blob b75b379eb1e2e6e3ad2557d80c03eff8a6d3dd48	shardmap/assign.py
$ git hash-object shardmap/assign.py
b75b379eb1e2e6e3ad2557d80c03eff8a6d3dd48
$ git hash-object -w shardmap/assign.py
b75b379eb1e2e6e3ad2557d80c03eff8a6d3dd48
$ git fsck
dangling commit c9f6702e847cd19d630a7cc16a171e3e19d394dc
dangling blob 35c035a45b0035965145d4564e8c8557083b30f7
[exit status: 0]
```
<!-- /snippet -->

`git ls-tree -r HEAD` finds the path that the missing ID belongs to: `shardmap/assign.py`. The file is unchanged in the working tree, and an object's ID is the hash of its content: `git hash-object` on the working tree file prints the missing ID. `-w` writes the object, and `git fsck` exits with 0. The dangling lines remain, as they should.

The teammate's proposal could not have been carried out (there is no remote to clone from), and its premise was wrong: the dangling lines were never the problem.

**Reasoning.** `git fsck` reports two different things in one list: objects that exist and are not needed, and objects that are needed and do not exist. Only the second is damage. A missing object can be rebuilt from any place that has the same bytes, because the ID is derived from the content.

**Common mistakes.** Treating every line of `git fsck` as an error. `git prune` or `git gc --prune=now` to make the output shorter, which deletes the harmless objects and leaves the damage. Repairing from the working tree without comparing the ID first: if the file had been edited since, `git hash-object -w` would write a different object and the old one would still be missing. Trusting a clean `git status` as a health check.

**Expert approach.** Read `git fsck` by keyword: `missing`, `broken link`, `corrupt` and `error:` are damage; `dangling` is not. For each missing object find the path (`git ls-tree -r`, or `git rev-list --objects --all | grep <id>`), then the cheapest source of the same bytes: the working tree, another clone, the server.

**Reference.** Chapter 3, section 3.8 (reachability, `git fsck`, repairing a blob with `git hash-object -w`). Chapter 13, section 13.6 (dangling versus unreachable) and section 13.11 (a missing object: symptoms, `missing` as the diagnosis).

### Exercise 16.8

**Solution.**

<!-- snippet: ex2/answers-m16/16-8-before -->
```text
$ tools/current-commit.sh
0b9db19e45a05ffcac85d1e31cf0f1a037f25868
$ tools/count-objects.sh
14
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-8-after -->
```text
$ git gc -q
$ tools/current-commit.sh
cat: .git/refs/heads/main: No such file or directory
[exit status: 1]
$ tools/count-objects.sh
0
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m16/16-8-why -->
```text
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
0b9db19e45a05ffcac85d1e31cf0f1a037f25868 refs/heads/main
$ ls .git/refs/heads | wc -l
       0
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 14
packs: 1
```
<!-- /snippet -->

`current-commit.sh` reads the file `.git/refs/heads/main`. `git gc` packed the refs: the value of `main` is now a line in `.git/packed-refs`, and the loose file is gone until the branch moves again. `count-objects.sh` counts files in the two-character directories of `.git/objects`. `git gc` moved all 14 objects into a pack, so there are no loose files left to count.

Both facts were readable all the time through Git itself:

<!-- snippet: ex2/answers-m16/16-8-fix -->
```text
$ git rev-parse --verify refs/heads/main
0b9db19e45a05ffcac85d1e31cf0f1a037f25868
$ git cat-file --batch-check --batch-all-objects | wc -l
      14
```
<!-- /snippet -->

The rewritten scripts: `git rev-parse --verify refs/heads/main` (or `git rev-parse HEAD`, if the deployed commit is whatever is checked out), and `git cat-file --batch-check --batch-all-objects | wc -l` (or the sum of `count` and `in-pack` from `git count-objects -v`).

The rule the originals broke: the layout of `.git` is an implementation detail with more than one valid state for the same content. A ref may be loose or packed, or stored by the reftable backend, where there are no ref files at all. An object may be loose or in a pack. Plumbing commands give the same answer in every state.

**Reasoning.** Git maintenance changes representation, never meaning. A script that reads the representation works until the first maintenance run, which on Git 2.54 and later happens automatically after ordinary commands.

**Common mistakes.** "Fixing" the first script by falling back to `grep` on `packed-refs`: that handles two of the three representations and still ignores symbolic refs and worktrees. Disabling maintenance on the host. Parsing the output of porcelain commands such as `git branch` or `git log` without a format.

**Expert approach.** In scripts: `git rev-parse` for names, `git for-each-ref --format` for lists of refs, `git cat-file --batch` for objects, `git status --porcelain` for state. Test a script against a repository on which `git gc` has run.

**Reference.** Chapter 3, section 3.9 (loose refs and `packed-refs`), section 3.7 (packs), section 3.13 (the reftable backend) and section 3.6 (`git rev-parse`). Automatic maintenance: Chapter 26, section 26.3.

### Exercise 16.9

**Solution.**

<!-- snippet: ex2/solve-m16-shardmap/01-observe -->
```text
$ git log --oneline --decorate
7d43aa1 (HEAD -> main, tag: v1.0.0) Add shard configuration
bca3d52 Add README
e930266 Add shard assignment
$ git ls-files
README.md
shardmap/assign.py
shards.yaml
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 23
packs: 1
$ git log --oneline main -- data/shards.bin
```
<!-- /snippet -->

`main` is clean: three commits, three files, no trace of the path. And yet 23 objects for a three-commit history. Ask the object database what is reachable from any ref, by size:

<!-- snippet: ex2/solve-m16-shardmap/02-find-the-blob -->
```text
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' | sort -k2 -n -r | head -2
blob 600000 7e06a0279f2cb738bc520606dcd8bec0c02fd81a data/shards.bin
commit 270 583a2e55f299326519c38623af38605c34121610 
```
<!-- /snippet -->

`7e06a02`, 600,000 bytes, `data/shards.bin`. `git rev-list --all` found it, so some ref reaches it. Which?

<!-- snippet: ex2/solve-m16-shardmap/03-holders-refs -->
```text
$ git for-each-ref
6837214d52584db82f5374e2954cecd327c6b4e4 commit	refs/backup/main-before-cleanup
7d43aa181a2ebda994ac8ee0b1ae237131fee708 commit	refs/heads/main
583a2e55f299326519c38623af38605c34121610 commit	refs/stash
6753b2c97469333f3c7a6b983e41b76459d0a10c tag	refs/tags/v1.0.0
$ git log --all --oneline --diff-filter=A -- data/shards.bin
1e04bfc Add shard dump for debugging
$ git for-each-ref --contains 1e04bfc
6837214d52584db82f5374e2954cecd327c6b4e4 commit	refs/backup/main-before-cleanup
583a2e55f299326519c38623af38605c34121610 commit	refs/stash
```
<!-- /snippet -->

`git for-each-ref` lists every ref, including two that neither `git branch` nor `git tag` shows: `refs/backup/main-before-cleanup`, the old `main` kept as a precaution, and `refs/stash`. The commit that added the dump is `1e04bfc`, and `--contains` confirms that both of those refs have it in their history. The stash was made on the old `main`, so its first parent is the old tip.

Refs are not the only holders:

<!-- snippet: ex2/solve-m16-shardmap/04-holders-reflogs -->
```text
$ git reflog | grep -c .
9
$ git reflog | grep '^1e04bfc'
1e04bfc HEAD@{7}: commit: Add shard dump for debugging
$ git stash list
stash@{0}: On main: try 32 shards
$ git stash show -p stash@{0}
diff --git a/shards.yaml b/shards.yaml
index 9fbebee..35c035a 100644
--- a/shards.yaml
+++ b/shards.yaml
@@ -1,2 +1,2 @@
-shards: 16
+shards: 32
 replicas: 2
```
<!-- /snippet -->

The HEAD reflog still names the commit that added the dump, and the old history after it. And the stash holds parked work: a change of `shards.yaml` from 16 to 32 shards. That is the answer to "say what it is" before discarding it. If it were wanted, the way to keep it would be to apply it on the new `main` and commit it there; the exercise allows dropping it.

So there are three holders: the backup ref, the stash, and the reflogs. Remove the two refs first and look again:

<!-- snippet: ex2/solve-m16-shardmap/05-remove-refs -->
```text
$ git update-ref -d refs/backup/main-before-cleanup
$ git stash drop
Dropped refs/stash@{0} (583a2e55f299326519c38623af38605c34121610)
$ git for-each-ref
7d43aa181a2ebda994ac8ee0b1ae237131fee708 commit	refs/heads/main
6753b2c97469333f3c7a6b983e41b76459d0a10c tag	refs/tags/v1.0.0
$ git gc -q
$ git cat-file -t 7e06a02
blob
```
<!-- /snippet -->

Only `main` and the tag are left, a `git gc` has run, and the blob is still there: the reflogs hold it, and behind the reflogs the grace period would. Now the two 🔴 commands, on purpose:

<!-- snippet: ex2/solve-m16-shardmap/06-point-of-no-return -->
```text
$ git reflog expire --expire=now --all
$ git gc -q --prune=now
$ git cat-file -t 7e06a02
fatal: Not a valid object name 7e06a02
[exit status: 128]
$ git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
count: 0
in-pack: 11
packs: 1
```
<!-- /snippet -->

`git reflog expire --expire=now --all` empties every reflog. `git gc --prune=now` deletes every unreachable object without a grace period. The ID no longer resolves, and the pack has 11 objects.

<!-- snippet: ex2/solve-m16-shardmap/07-verify -->
```text
$ git fsck
[exit status: 0]
$ git log --oneline --decorate
7d43aa1 (HEAD -> main, tag: v1.0.0) Add shard configuration
bca3d52 Add README
e930266 Add shard assignment
$ git status -sb
## main
$ cd ..
$ exercises/gen/m16-shardmap/check.sh
Checking exercise m16-shardmap
  ok    the blob of data/shards.bin is no longer in the object database
  ok    main still ends with "Add shard configuration"
  ok    main still has three commits
  ok    v1.0.0 is still an annotated tag on the tip of main
  ok    the working tree is clean
  ok    git fsck finds no problem
PASS: exercise m16-shardmap is complete.
[exit status: 0]
```
<!-- /snippet -->

`git fsck` is silent, `main` and `v1.0.0` are where they were.

**Reasoning.** An object stays as long as anything reaches it. "Removed from history" was true for one ref, `main`. The cleanup had left three other starting points that still led to the old commits: a ref outside the usual namespaces, the stash, and the reflogs. Garbage collection did what it is designed to do and kept everything.

**Common mistakes.** Asking only `main`, as the report did: `git log --all -- data/shards.bin` walks from every ref, including the backup ref and the stash, and shows the commit at once. Looking at `git branch -a` and `git tag` and declaring that no ref is left. Dropping the stash without reading it. Running the two destructive commands first and the investigation never: they would have changed nothing while the two refs existed. Deleting `.git/refs/backup/...` by hand instead of `git update-ref -d`, which fails without a message when the ref is packed. Forgetting that every other clone and the server still have the object: here there is no remote, and with one, each copy has to be cleaned or re-created.

**Expert approach.** Start from the object: find it by size, then ask "who reaches this": `git for-each-ref --contains <commit>` for refs, `git reflog` and `git stash list` for the rest, `git worktree list` in a repository with several worktrees. Remove the holders one kind at a time and re-test with `git cat-file -e`. Record in the cleanup notes that the last two commands also destroyed every other unreachable commit in the repository.

**Reference.** Chapter 3, section 3.8 (reachability) and section 3.9 (`git for-each-ref`, `git update-ref -d`, refs outside `refs/heads` and `refs/tags`). Chapter 13, section 13.2 (the four layers of protection), section 13.13 (the point of no return, the 🔴 pair of commands) and section 13.18. Chapter 26, section 26.5 (cruft packs). The stash as commits and a ref: Chapter 14C, section 14C.2.

---

## Module 17: The index, refs, and the files of `.git`

### Exercise 17.1

**Solution.**

<!-- snippet: ex2/answers-m17/17-1-index -->
```text
$ git ls-files --stage
100644 1bf18cd1ee63e2d9f5850821afe782e36f32f8c5 0	README.md
100644 c8f3c807be0aa9a70e0a4ae51434cc50558815df 0	config.yaml
100644 37feb05c4ffa659c8599f19c883df4bd37b53a86 0	docs/format.md
100644 56f285a21f70be9339c34c2172c83604cc24619c 0	src/ingest.py
$ echo 'workers: 8' >> config.yaml
$ git ls-files --stage config.yaml
100644 c8f3c807be0aa9a70e0a4ae51434cc50558815df 0	config.yaml
$ git status -s
 M config.yaml
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m17/17-1-add -->
```text
$ git add config.yaml
$ git ls-files --stage config.yaml
100644 d35020d6686250f65000ed56a6a8a67cbbf6d48a 0	config.yaml
$ git rev-parse HEAD:config.yaml
c8f3c807be0aa9a70e0a4ae51434cc50558815df
$ git rev-parse :config.yaml
d35020d6686250f65000ed56a6a8a67cbbf6d48a
$ git ls-files --debug config.yaml | grep -e size -e flags
  size: 37	flags: 0
```
<!-- /snippet -->

1. Mode, object ID of the blob, stage number, path.
2. The index entry also caches stat data of the file (size, timestamps and more). `git status` compares the file's current stat data with the cached values; the size no longer matches, so Git compares content and reports the change. The entry's blob ID is untouched because nothing was staged.
3. A new blob in the object database and the new blob ID in the index entry. Now the index and `HEAD` disagree; `git diff --cached` shows that as a diff.
4. `HEAD:config.yaml` is the blob that the current commit records for the path. `:config.yaml`, short for `:0:config.yaml`, is the blob in the index.
5. Creation and modification times, device and inode, user and group IDs, and the flags. They let Git decide that a file is unchanged without reading it.

**Reasoning.** The index is a table with one row per path: which blob the next commit will contain, and what the file looked like on disk when the row was written. `git add` rewrites a row. `git status` is two comparisons, one on each side of the table.

**Common mistakes.** Thinking that the index holds a diff or a list of changes: it holds the full list of paths. Expecting `git ls-files --stage` to change when a file is edited. Confusing `:path` with `HEAD:path` in scripts.

**Expert approach.** `git ls-files --stage <path>` together with `git rev-parse HEAD:<path>` and `git hash-object <path>` gives the three IDs for a path: index, commit, working tree. Three equal IDs mean a clean path, with no diff needed.

**Reference.** Chapter 3, section 3.12 (the index file: entries, cached stat data, `--stage`, `--debug`). Chapter 5, section 5.3 (what `git add` writes), section 5.11 (`git ls-files`) and section 5.14 (the cached stat data).

### Exercise 17.2

**Solution.**

<!-- snippet: ex2/answers-m17/17-2-loose -->
```text
$ git for-each-ref
66e4e23a29a1063c2c55a47f26006f4fb405bb5b commit	refs/heads/feature/retries
66e4e23a29a1063c2c55a47f26006f4fb405bb5b commit	refs/heads/main
2605da3568b48ab6033670f9a30599daa3a6f04b tag	refs/tags/v0.1.0
$ find .git/refs -type f | sort
.git/refs/heads/feature/retries
.git/refs/heads/main
.git/refs/tags/v0.1.0
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m17/17-2-packed -->
```text
$ git pack-refs --all
$ find .git/refs -type f | sort
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
66e4e23a29a1063c2c55a47f26006f4fb405bb5b refs/heads/feature/retries
66e4e23a29a1063c2c55a47f26006f4fb405bb5b refs/heads/main
2605da3568b48ab6033670f9a30599daa3a6f04b refs/tags/v0.1.0
^66e4e23a29a1063c2c55a47f26006f4fb405bb5b
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m17/17-2-both -->
```text
$ echo 'See docs/format.md.' >> README.md && git commit -q -am 'Point to the format description'
$ find .git/refs -type f | sort
.git/refs/heads/main
$ cat .git/refs/heads/main
00387b8fc8e2090eed6d227026c8b07962735fbb
$ grep refs/heads/main .git/packed-refs
66e4e23a29a1063c2c55a47f26006f4fb405bb5b refs/heads/main
$ git rev-parse main
00387b8fc8e2090eed6d227026c8b07962735fbb
```
<!-- /snippet -->

1. Before: one file per ref under `.git/refs/`. After: no file there; all three refs are lines in `.git/packed-refs`.
2. The peeled value of the annotated tag on the line above: the commit that the tag object points at, stored so that Git does not have to open the tag object.
3. The loose file wins. The line in `packed-refs` is the value from the time of packing and is now stale; it is ignored while a loose ref of the same name exists, and replaced at the next packing.
4. That it is wrong in two ways: after packing the file may not exist, and when both exist only one of them is current. `git rev-parse main` is right in every state.

**Reasoning.** With the `files` backend, a ref lives in a loose file, in `packed-refs`, or in both, and lookup checks the loose file first. Packing is an optimization for repositories with many refs.

**Common mistakes.** Editing `packed-refs` by hand. Deleting a branch by removing its loose file, which resurrects the packed value (exercise 17.7 uses exactly this trap). Assuming that `packed-refs` is authoritative.

**Expert approach.** Never read or write ref storage directly. `git for-each-ref` to list, `git rev-parse --verify` to read, `git update-ref` to write and delete. They also work on the reftable backend, where neither file exists.

**Reference.** Chapter 3, section 3.9 (loose refs, `packed-refs`, the lookup order, the peeled line) and section 3.13 (reftable).

### Exercise 17.3

**Solution.**

<!-- snippet: ex2/answers-m17/17-3-head -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git symbolic-ref HEAD
refs/heads/main
$ git symbolic-ref --short HEAD
main
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m17/17-3-update-ref -->
```text
$ git update-ref refs/heads/experiment HEAD~1
$ git branch -v
  experiment bf1af83 Add configuration
* main       70873c5 Double the batch size
$ git update-ref refs/heads/experiment HEAD HEAD
fatal: update_ref failed for ref 'refs/heads/experiment': cannot lock ref 'refs/heads/experiment': is at bf1af83f9444f972db491fbb01a46ba9db8b9e56 but expected 70873c5d5be90520c25ec28efab78490a2ae0a3a
[exit status: 128]
$ git update-ref refs/heads/experiment HEAD HEAD~1
$ git reflog show experiment
70873c5 experiment@{0}: 
bf1af83 experiment@{1}: 
$ git update-ref -d refs/heads/experiment
$ git branch
* main
```
<!-- /snippet -->

1. A symbolic ref: its content is the name of another ref. In detached HEAD state the file contains a commit ID.
2. The value that the ref is expected to have now. The first call said "set it to `HEAD`, provided it is at `HEAD`", and the ref was at `HEAD~1`, so Git refused and printed both values. The second call named the right old value and succeeded. This is a compare-and-swap: a script that computes a new value from an old one cannot overwrite a change that someone made in between. `git push --force-with-lease` is the same idea across a network.
3. `git branch` refuses to overwrite an existing branch without `-f`, checks that the name is valid for a branch, can set an upstream, and writes a reflog message. `git update-ref` does what it is told to any ref name.
4. It takes a lock, so two processes cannot write half a file each; it works whether the ref is loose or packed and with any ref backend; it writes the reflog; and with the third argument it checks the old value.

The reflog of `experiment` has two entries with empty messages: `git update-ref` records the movement, and the reason only when `-m` gives one.

**Reasoning.** Refs are the only mutable part of the object model, so how they are updated matters. The plumbing command is the single, safe way to change one, and the porcelain commands are policies on top of it.

**Common mistakes.** `echo <id> > .git/refs/heads/x`: no lock, no reflog, no check, and broken as soon as refs are packed. Forgetting `-m` in scripts, which leaves reflog entries nobody can interpret. Using `git update-ref` on `HEAD` when `git symbolic-ref` was meant: it then updates the branch that `HEAD` points at.

**Expert approach.** In automation always pass the old value and a message: `git update-ref -m '<why>' <ref> <new> <old>`. For several refs at once, `git update-ref --stdin` applies all updates or none.

**Reference.** Chapter 3, section 3.9 (`git update-ref`, `git symbolic-ref`, the old-value check) and section 3.11 (reflog storage). Chapter 7, section 7.2 and 7.3 (a branch is a ref; HEAD is a symbolic ref).

### Exercise 17.4

**Solution.**

<!-- snippet: ex2/answers-m17/17-4-merge -->
```text
$ git merge feature/streaming
Auto-merging config.yaml
CONFLICT (content): Merge conflict in config.yaml
CONFLICT (modify/delete): docs/format.md deleted in feature/streaming and modified in HEAD.  Version HEAD of docs/format.md left in tree.
Auto-merging src/stream.py
CONFLICT (add/add): Merge conflict in src/stream.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m17/17-4-stages -->
```text
$ git status -s
UU config.yaml
UD docs/format.md
AA src/stream.py
$ git ls-files -u
100644 c8f3c807be0aa9a70e0a4ae51434cc50558815df 1	config.yaml
100644 d07c91e51c31b31b6570ac7aff0da37488b0c6dc 2	config.yaml
100644 02c759addbad9ffeb63be82e678830310cf76a28 3	config.yaml
100644 37feb05c4ffa659c8599f19c883df4bd37b53a86 1	docs/format.md
100644 aebc79e6e5a7f1d7c3150261728683e2d3ff944c 2	docs/format.md
100644 cae60f7e3ead6439944786ad18e57bae470bc924 2	src/stream.py
100644 5f21ff531d007457444d0cd49262c4229eb2284f 3	src/stream.py
```
<!-- /snippet -->

Seven lines: three for `config.yaml` (stages 1, 2, 3), two for `docs/format.md` (stages 1 and 2), two for `src/stream.py` (stages 2 and 3).

Stage 1 is the version in the merge base, stage 2 the version of the current branch ("ours"), stage 3 the version of the branch being merged ("theirs"). `docs/format.md` has no stage 3 because the other branch deleted the file: there is no "theirs" version. `src/stream.py` has no stage 1 because the file did not exist in the merge base: both sides added it. The status codes say the same: `UU` both modified, `UD` deleted by them, `AA` both added.

<!-- snippet: ex2/answers-m17/17-4-read -->
```text
$ git show :1:config.yaml | head -1
max_batch: 100
$ git show :2:config.yaml | head -1
max_batch: 50
$ git show :3:config.yaml | head -1
max_batch: 500
$ git merge --abort
$ git ls-files -u | wc -l
       0
```
<!-- /snippet -->

`git show :2:config.yaml` prints our version; its first line is `max_batch: 50`. After `git merge --abort` the index has no unmerged entries: zero lines.

**Reasoning.** During a conflict the index holds up to three rows per path instead of one. Which rows exist tells you the type of conflict before you open a file, and each row is a complete version that you can read, diff and check out.

**Common mistakes.** Three lines per path regardless of type. Swapping stages 2 and 3 (in a rebase their meaning is reversed with respect to "my branch", which is a separate trap). Expecting conflict markers in a modify/delete conflict: there is one version, left in the working tree, and the decision is whether the file should exist.

**Expert approach.** `git ls-files -u` first, then `git diff :1:<path> :3:<path>` to see what the other side did and `git diff :1:<path> :2:<path>` for your side. Resolving is replacing the rows by one row at stage 0, which `git add` or `git rm` does.

**Reference.** Chapter 5, section 5.13 (index stages during a conflict). Chapter 8, section 8.8 (anatomy of a conflict: stages, `git ls-files -u`, `git show :N:path`) and section 8.11 (conflict types beyond content).

### Exercise 17.5

**Solution.**

<!-- snippet: ex2/answers-m17/17-5-names -->
```text
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse --symbolic-full-name HEAD
refs/heads/main
$ git switch -q --detach
$ git rev-parse --abbrev-ref HEAD
HEAD
$ git rev-parse --symbolic-full-name HEAD
HEAD
$ git switch -q main
```
<!-- /snippet -->

On a branch, `--abbrev-ref HEAD` prints the branch name and `--symbolic-full-name HEAD` the full ref name. In detached HEAD state both print `HEAD`: there is no ref to name.

<!-- snippet: ex2/answers-m17/17-5-index -->
```text
$ echo 'Run it with python3 -m src.ingest.' >> README.md && git add README.md
$ git rev-parse HEAD:README.md
1bf18cd1ee63e2d9f5850821afe782e36f32f8c5
$ git rev-parse :README.md
290acd9888278e09f298e81087826610e68e2f3f
```
<!-- /snippet -->

Different IDs: `HEAD:README.md` is the committed blob, `:README.md` the staged one.

<!-- snippet: ex2/answers-m17/17-5-where -->
```text
$ cd src
$ git rev-parse --show-prefix
src/
$ git rev-parse --show-cdup
../
$ git rev-parse --show-toplevel
$LAB/ex2/answers-m17/ex-17-5
$ git rev-parse --git-dir
$LAB/ex2/answers-m17/ex-17-5/.git
$ cd ..
```
<!-- /snippet -->

From a subdirectory: the path from the top level to here, the path from here to the top level, the absolute top level, and the Git directory, which is printed as an absolute path when you are not at the top level.

<!-- snippet: ex2/answers-m17/17-5-errors -->
```text
$ git rev-parse -q --verify refs/heads/nope; echo "exit status: $?"
exit status: 1
$ git rev-parse HEAD^2
fatal: ambiguous argument 'HEAD^2': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
HEAD^2
[exit status: 128]
```
<!-- /snippet -->

`-q --verify` on a ref that does not exist prints nothing and exits with 1. `HEAD^2`, the second parent of a commit that has one parent, is an error with exit status 128; note that the unresolved text is also echoed on standard output, which a careless script would take for a result.

A script should use `git rev-parse -q --verify refs/heads/<name>` because the answer does not depend on how refs are stored: the file test fails for packed refs (exercise 17.2) and for the reftable backend, and it cannot be run from a subdirectory or a linked worktree without knowing where `.git` is.

**Reasoning.** `git rev-parse` is the translator between names and facts: revisions to IDs, the current directory to repository paths, a name to "exists or not". Each of its answers has a file-based imitation that works in the simple case and fails in another.

**Common mistakes.** Using `git rev-parse --abbrev-ref HEAD` as "the current branch" in CI, where the checkout is often detached and the answer is the literal word `HEAD`. Using `git rev-parse <name>` without `--verify` to test existence. Building paths with `$(git rev-parse --git-dir)` as if it were always `.git`.

**Expert approach.** `git symbolic-ref -q --short HEAD` for "the branch, or nothing when detached"; `git rev-parse --show-toplevel` at the top of every script that needs paths; `--verify` with `^{commit}` when a commit is required.

**Reference.** Chapter 3, section 3.6 (`git rev-parse`: what it resolves, `--abbrev-ref`, `--show-toplevel`, `--git-dir`, `--verify`).

### Exercise 17.6

**Solution.**

<!-- snippet: ex2/answers-m17/17-6-commands -->
```text
$ git ls-tree HEAD
100644 blob 1bf18cd1ee63e2d9f5850821afe782e36f32f8c5	README.md
100644 blob c8f3c807be0aa9a70e0a4ae51434cc50558815df	config.yaml
040000 tree d71a8db53fedde90ee32077a10816ad267084de1	docs
040000 tree 27fa52f045b4affb1ff9e51287af3f50279394b0	src
$ git commit-tree HEAD:docs -m 'Snapshot of the documentation'
878e1c99f9416f627531aae8f355d693b270d66d
$ git update-ref refs/heads/docs-snapshot 878e1c9
```
<!-- /snippet -->

`HEAD:docs` names the tree object of the `docs` directory. `git commit-tree <tree> -m <message>` wraps a commit around an existing tree and prints the new ID; without `-p` the commit has no parent. `git update-ref` gives it a name. (Your commit ID differs: the commit carries your clock.)

<!-- snippet: ex2/answers-m17/17-6-graph -->
```text
$ git log --graph --oneline --all
* 878e1c9 Snapshot of the documentation
* ddd6b2d Document the size limit
* 67f5f83 Add configuration
* 9111677 Add batching ingester
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m17/17-6-inspect -->
```text
$ git ls-tree docs-snapshot
100644 blob adf86beab38716b2fff22cc07c237d7fcf41d22a	format.md
$ git cat-file -p docs-snapshot
tree d71a8db53fedde90ee32077a10816ad267084de1
author Lab User <you@example.com> 1788761820 +0530
committer Lab User <you@example.com> 1788761820 +0530

Snapshot of the documentation
$ git status -sb
## main
$ git merge docs-snapshot
fatal: refusing to merge unrelated histories
[exit status: 128]
```
<!-- /snippet -->

The graph is unusual in what it does not draw: `git log --graph` prints the new commit directly above the tip of `main`, and no line connects them. The repository now has two root commits and two histories with no common ancestor. The commit object confirms it: a `tree` line and no `parent` line. The tree is `d71a8db`, the ID that `git ls-tree HEAD` printed for `docs`: no new tree and no new blob were written. `git status` shows `main` and a clean tree; nothing was checked out and nothing was staged.

`git merge docs-snapshot` refuses: "refusing to merge unrelated histories". Without a merge base there is nothing to compute a three-way merge from.

**Reasoning.** A commit is a small object that names a tree and parents. Porcelain builds the tree from the index; plumbing lets you name any tree that exists. Since subtrees are ordinary tree objects, "a commit of one directory" needs no copying and no checkout.

**Common mistakes.** Creating the snapshot with `git switch --orphan`, `git rm`, and `git add`: it works, and it rewrites your working tree and index on the way. Passing `-p HEAD`, which makes the snapshot a child of `main` with a tree that seems to delete everything else. Reading the graph as a linear history because the asterisks are stacked.

**Expert approach.** This technique is how tools publish a subdirectory as its own branch (generated documentation, a split-out library). For a split that keeps history, `git subtree split` does the same thing commit by commit.

**Reference.** Chapter 2, section 2.6 (building a commit by hand: `git commit-tree`, `git update-ref`). Chapter 3, section 3.4 (the commit object, root commits) and section 3.6 (`rev:path`). Unrelated histories and the merge base: Chapter 8, section 8.2.

### Exercise 17.7

**Solution.**

<!-- snippet: ex2/answers-m17/17-7-symptom -->
```text
$ git branch
warning: ignoring broken ref refs/heads/release/1.0
* main
$ git log --oneline -1 release/1.0
warning: ignoring broken ref refs/heads/release/1.0
warning: ignoring broken ref refs/heads/release/1.0
fatal: ambiguous argument 'release/1.0': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
```
<!-- /snippet -->

"Ignoring broken ref": the ref exists and its content is not a valid value. Three places know something about the branch:

<!-- snippet: ex2/answers-m17/17-7-evidence -->
```text
$ cat .git/refs/heads/release/1.0
7c3f9a1b2d4e
$ grep release .git/packed-refs
e448b01d1bf178f31cf394c14742f99db95344a3 refs/heads/release/1.0
$ awk '{print $1, $2}' .git/logs/refs/heads/release/1.0
0000000000000000000000000000000000000000 68b4fd50ae24c60a1eec4eab7dc54336d1b7465f
68b4fd50ae24c60a1eec4eab7dc54336d1b7465f e448b01d1bf178f31cf394c14742f99db95344a3
e448b01d1bf178f31cf394c14742f99db95344a3 ea066d0db972e6a8367d782e165893806366fa22
```
<!-- /snippet -->

The loose file holds twelve characters, not an object ID. `packed-refs` has a complete ID for the branch, `e448b01`. The reflog has three entries, and the newest says that the branch last moved from `e448b01` to `ea066d0`. So the packed value is one commit behind: the refs were packed, then one more commit was made, which wrote the loose file, and that file is the one that was damaged.

The colleague's proposal, tested:

<!-- snippet: ex2/answers-m17/17-7-trap -->
```text
$ mv .git/refs/heads/release/1.0 ../release-1.0.broken
$ git log --oneline -2 release/1.0
e448b01 Use eight workers in the 1.0 line
68b4fd5 Add configuration
```
<!-- /snippet -->

Git does fall back to the packed copy, without any warning, and the branch is one commit short: "Add an ingest timeout to the 1.0 line" is gone from it. On a release branch that would have shipped the next build without that commit.

The true last value is in the reflog. Check that the object exists, then write the ref with a reason:

<!-- snippet: ex2/answers-m17/17-7-fix -->
```text
$ git cat-file -t ea066d0
commit
$ git update-ref -m 'repair: newest value from the reflog' refs/heads/release/1.0 ea066d0
$ git log --oneline -3 release/1.0
ea066d0 Add an ingest timeout to the 1.0 line
e448b01 Use eight workers in the 1.0 line
68b4fd5 Add configuration
$ git fsck
```
<!-- /snippet -->

Three commits again, and `git fsck` is silent.

**Reasoning.** A branch is one value, and three files can hold a version of it: the loose ref (current), `packed-refs` (as of the last packing), the reflog (every value, in order). When the loose file is damaged, the packed value is a plausible answer and possibly an old one; the reflog is the record that says which value was last.

**Common mistakes.** Deleting the loose file and stopping, as proposed. Typing the ID into the file by hand. Taking the *first* ID of the last reflog line (the old value) instead of the second. Skipping `git cat-file -t`: if the object named by the reflog were missing too, the ref would have to go to the newest value whose object exists.

**Expert approach.** Move damaged files aside, do not delete them. Read `tail -1 .git/logs/refs/heads/<branch>`, verify the object, `git update-ref -m`, and compare with a remote-tracking branch or a colleague's clone when there is one. Then ask how a ref file came to be half-written, because the cause may have touched other files: run `git fsck`.

**Reference.** Chapter 3, section 3.9 (loose and packed refs: the loose one wins; `git update-ref`) and section 3.11 (the reflog on disk). Chapter 13, section 13.3 and section 13.11 (a damaged repository).

### Exercise 17.8

**Solution.**

<!-- snippet: ex2/answers-m17/17-8-symptom -->
```text
$ cat config.yaml
max_batch: 100
workers: 16
$ git status -sb
## main...origin/main
$ git diff
$ git pull
From ../server
   bd5bf8a..b9e05e2  main       -> origin/main
error: Your local changes to the following files would be overwritten by merge:
	config.yaml
Please commit your changes or stash them before you merge.
Aborting
Updating bd5bf8a..b9e05e2
[exit status: 1]
```
<!-- /snippet -->

The file differs from the commit, `git status` and `git diff` say nothing, and the pull refuses to overwrite "local changes". One command shows why:

<!-- snippet: ex2/answers-m17/17-8-diagnose -->
```text
$ git ls-files -v
H README.md
S config.yaml
H docs/format.md
H src/ingest.py
```
<!-- /snippet -->

`S` in front of `config.yaml`: the skip-worktree bit is set on that index entry (`git update-index --skip-worktree`). It tells Git not to look at the working tree file, so status and diff report nothing. The merge that a pull performs does check the real file before it overwrites it, and stops.

<!-- snippet: ex2/answers-m17/17-8-fix -->
```text
$ git update-index --no-skip-worktree config.yaml
$ git status -sb
## main...origin/main [behind 1]
 M config.yaml
$ git stash
Saved working directory and index state WIP on main: bd5bf8a Add configuration
$ git pull -q
$ git stash pop
Auto-merging config.yaml
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   config.yaml

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (f2ac7be3168aabccd838e41fd6a2082184c70f96)
$ cat config.yaml
queue: ingest-main
max_batch: 100
workers: 16
```
<!-- /snippet -->

`--no-skip-worktree` clears the bit, and the edit becomes visible as an ordinary modification. Stash, pull, pop: the incoming change (a new first line) and the local value merge cleanly, and the file has both.

Whoever set the bit wanted a private, permanent edit to a tracked file. Git has no feature for that: the two bits exist for other purposes (sparse checkout, and a performance promise on slow filesystems), they hide the edit from the commands you would use to save it, they are lost when the index is rebuilt, and no clone has them. What to do instead: keep the tracked file as the shared default and read local overrides from a second, ignored file (`config.local.yaml` in `.gitignore`) or from environment variables.

> **Unverified.** While this exercise was being written, one of two otherwise identical runs let the pull fast-forward and overwrite the hidden edit. In that run the edit had the same size as the committed file and was made within the same second. Git decides whether such a file is unchanged from cached stat data, so an edit that the stat data does not betray may not be protected. The run could not be reproduced on demand and no transcript is shown; the generator now writes a value of a different length. Treat it as one more reason not to hide edits behind this bit.

**Reasoning.** The bit changes what Git looks at, not what is true. The file was modified all along, and every command that trusted the index said otherwise.

**Common mistakes.** Looking for the cause in `.gitignore` (the file is tracked, so ignore rules do not apply) or in `core.fileMode`. `git stash` before clearing the bit: "No local changes to save". `git checkout -- config.yaml` to make the pull work, which is refused for a skip-worktree path, or, after clearing the bit, discards the local value. Setting the bit again after the pull.

**Expert approach.** When `git status` is clean and a command still complains about local changes: `git ls-files -v | grep '^[a-zS]'` lists every entry with either bit (`S` for skip-worktree, a lower-case letter for assume-unchanged). In a sparse checkout `S` is normal for paths outside the cone; anywhere else it is somebody's workaround.

**Reference.** Chapter 5, section 5.12 (two bits that are not an ignore mechanism: `git ls-files -v`, what each command does with them, the FAQ's answer), section 5.14 (the cached stat data) and section 5.15. Stash: Chapter 11, section 11.11.

### Exercise 17.9

**Solution.**

<!-- snippet: ex2/solve-m17-ingestd/01-symptom -->
```text
$ git status
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
```
<!-- /snippet -->

"Not a git repository" in a directory with a `.git` directory. Git decides whether a directory is a repository by looking for a few things in it, and one of them is a valid `HEAD`:

<!-- snippet: ex2/solve-m17-ingestd/01-first-look -->
```text
$ ls -A .git | sort
COMMIT_EDITMSG
config
description
HEAD
hooks
index
index.lock
info
logs
objects
refs
$ wc -c < .git/HEAD
       0
```
<!-- /snippet -->

Everything is there, including a file that should not be: `index.lock`. And `HEAD` is empty.

**HEAD.** It must name the branch that was checked out. The notes say "my feature branch"; the HEAD reflog says which:

<!-- snippet: ex2/solve-m17-ingestd/02-head -->
```text
$ tail -3 .git/logs/HEAD | cut -f2
checkout: moving from main to feature/batching
commit: Use batches of 250 documents
commit: Match the configured batch size
$ find .git/refs/heads -type f | sort
.git/refs/heads/feature/batching
.git/refs/heads/main
$ printf 'ref: refs/heads/feature/batching\n' > .git/HEAD
$ git status -sb
## feature/batching
 M README.md
$ git log --oneline -3
91babe7 Match the configured batch size
8f2daf2 Use batches of 250 documents
e5c77b4 Add configuration
```
<!-- /snippet -->

The last checkout was "moving from main to feature/batching", followed by two commits. The ref file exists. `HEAD` must be written by hand here, because `git symbolic-ref` needs a repository to work in, and there is none until `HEAD` is valid. One line, `ref: refs/heads/feature/batching`, and Git recognizes the repository: the branch has both commits, and the uncommitted README edit is still in the working tree.

**The lock.** Reading works. The first command that has to write the index does not:

<!-- snippet: ex2/solve-m17-ingestd/03-lock -->
```text
$ git reset
fatal: Unable to create '$LAB/ex2/solve-m17-ingestd/you/.git/index.lock': File exists.

Another git process seems to be running in this repository, or the lock file may be stale
[exit status: 128]
$ wc -c < .git/index.lock
       0
# No git process is running (ps shows none), so the lock is stale.
$ rm .git/index.lock
$ git reset
Unstaged changes after reset:
M	README.md
```
<!-- /snippet -->

Git creates `index.lock`, writes the new index into it, and renames it over `index`. A lock file that exists means either that another Git process is running or that one died. No Git process is running, and the file is empty: it is stale, and removing it is the documented repair. `git reset` then works and reports the unstaged README edit, unchanged.

**The configuration.** The notes say that both branches tracked the server. They do not any more:

<!-- snippet: ex2/solve-m17-ingestd/04-config -->
```text
$ git branch -vv
* feature/batching 91babe7 Match the configured batch size
  main             e5c77b4 Add configuration
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
[remote "origin"]
	url = ../ser
$ git fetch
fatal: '../ser' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

`git branch -vv` shows no upstream for either branch. The configuration file ends in the middle of the `[remote "origin"]` section: the URL is cut off after `../ser`, the fetch refspec is missing, and so are the two `[branch ...]` sections that follow it in a clone. This damage produced no error of its own until `git fetch`: a truncated value is still a valid value.

<!-- snippet: ex2/solve-m17-ingestd/05-rebuild-config -->
```text
$ git remote set-url origin ../server.git
$ git config set remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
$ git fetch
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/batching
  origin/main
$ git branch -u origin/main main
branch 'main' set up to track 'origin/main'.
$ git branch -u origin/feature/batching feature/batching
branch 'feature/batching' set up to track 'origin/feature/batching'.
```
<!-- /snippet -->

The URL comes from the notes (`../server.git`). The refspec is the default one that every clone gets. The remote-tracking branches were never damaged, they are refs, so `git branch -r` lists them and `git fetch` has nothing to download. `git branch -u` restores the two upstream settings.

<!-- snippet: ex2/solve-m17-ingestd/06-verify -->
```text
$ git branch -vv
* feature/batching 91babe7 [origin/feature/batching: ahead 1] Match the configured batch size
  main             e5c77b4 [origin/main] Add configuration
$ git status -sb
## feature/batching...origin/feature/batching [ahead 1]
 M README.md
$ git config list --local | sed -n "/^remote/,\$p"
remote.origin.url=../server.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main
branch.feature/batching.remote=origin
branch.feature/batching.merge=refs/heads/feature/batching
$ git fsck
[exit status: 0]
$ cd ..
$ exercises/gen/m17-ingestd/check.sh
Checking exercise m17-ingestd
  ok    HEAD is a symbolic ref to feature/batching
  ok    no stale index.lock is left
  ok    the unpushed commit is still the tip of the branch
  ok    the uncommitted README edit is still in the working tree
  ok    remote.origin.url is ../server.git
  ok    remote.origin.fetch is the default refspec
  ok    the remote answers
  ok    main tracks origin/main
  ok    feature/batching tracks origin/feature/batching
  ok    this is the original clone (the unpushed commit is the original object)
  ok    git fsck finds no problem
PASS: exercise m17-ingestd is complete.
[exit status: 0]
```
<!-- /snippet -->

**Where each repair came from.**

| Damaged file | Symptom | Source of the repair |
|---|---|---|
| `.git/HEAD` (empty) | "not a git repository" | the HEAD reflog, `.git/logs/HEAD`: the last checkout names the branch |
| `.git/index.lock` (left behind) | "Unable to create ... index.lock: File exists" on any command that writes the index | nothing to rebuild: verify that no Git process runs, remove the file |
| `.git/config` (truncated) | no upstream in `git branch -vv`; `git fetch` cannot find the remote | the URL from your own knowledge of the server; the refspec is the default; the upstream settings follow from the remote-tracking branches that exist |

The colleague's proposal would have lost the second commit on the branch, which was never pushed, and the README edit. Nothing in the object database or the refs was damaged at all.

**Reasoning.** A repository is objects and refs. `HEAD`, the index lock and the configuration are small files around them, each with a known format and a place from which it can be rebuilt. The first error message describes the first file Git failed on; the others show up only when a command needs them, which is why the task lists four commands to test.

**Common mistakes.** Re-cloning. Running `git init` in the directory to "repair" it: it recreates missing files, and with an empty `HEAD` you then have to check very carefully what it wrote. Writing a commit ID into `HEAD`, which gives a detached HEAD and hides which branch was current. Removing `index.lock` without checking for a running process. Stopping when `git status` works, with a remote that points nowhere. Setting the URL and forgetting the refspec: `git fetch` then succeeds and updates only `FETCH_HEAD`, and remote-tracking branches silently stop moving.

**Expert approach.** Copy the directory first. Then go through the files in the order in which Git reads them: `HEAD`, `config`, refs, index. Compare `.git/config` with that of any healthy clone of the same repository: the structure is identical. Afterwards run `git fsck` and push the unpushed commit: a clone with unpushed work and no backup was the real exposure.

**Reference.** Chapter 3, section 3.2 (the `.git` directory, file by file: `HEAD`, `config`, `index`, `logs`), section 3.9 (symbolic refs) and section 3.11 (the HEAD reflog). Chapter 1, section 1.13 ("not a git repository": look at `.git/HEAD`). Chapter 5, section 5.15 (the index lock). Chapter 12, section 12.2 (a remote is a name, URLs and refspecs in `.git/config`) and section 12.5 (upstream configuration, `git branch -u`).

---

## Module 18: Transfer and scale

The server that every exercise of this module clones:

<!-- snippet: ex2/answers-m18/18-0-server -->
```text
$ git -C server.git log --graph --oneline --decorate --all
* 0e30841 (release/0.2) Correct the restart order for 0.2
| *   e5603f6 (HEAD -> main) Merge branch 'feature/keep-ten'
| |\  
| | * 8fdeecb Document the new reranker cut-off
| | * ec2507b Keep ten passages after reranking
| |/  
|/|   
| * 49e3cde Retrieve 80 candidates
|/  
* 8df50a3 (tag: v0.2.0) Add runbook
* b5fafaa Tokenize on word characters
* c4fe278 Add reranker service
* 3fdf7f7 (tag: v0.1.0) Describe the architecture
* 43a0273 Add retriever service and tokenizer library
```
<!-- /snippet -->

### Exercise 18.1

**Solution.**

<!-- snippet: ex2/answers-m18/18-1-shallow -->
```text
$ git clone --depth 1 "file://$PWD/server.git" shallow
Cloning into 'shallow'...
$ cd shallow
$ git log --oneline
e5603f6 Merge branch 'feature/keep-ten'
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
e5603f61784e43b551d678e0f5dc59affa8fb638
$ git cat-file -p HEAD | grep parent
parent 49e3cde0d1861c5124f77cca010a6bea8d59c045
parent 8fdeecb001ec9b46490017bccd76c6d4aa35db25
$ git cat-file -t HEAD^1
fatal: Not a valid object name HEAD^1
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m18/18-1-refs -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git tag
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m18/18-1-unshallow -->
```text
$ git fetch -q --unshallow
$ git rev-parse --is-shallow-repository
false
$ git rev-list --count HEAD
9
$ git tag
v0.1.0
v0.2.0
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

1. It lists the boundary commits. Git treats a commit named there as if it had no parents, although the commit object still names them. That is why `git log` stops and `git cat-file -t HEAD^1` cannot find the parent: the object was never sent.
2. For example: `git log` and `git rev-list --count` (history ends at the boundary, with exit status 0), `git blame` (every line is attributed to the boundary commit), `git describe` (no tag is reachable), `git merge-base` with a branch whose common ancestor lies behind the boundary (no result). All but `git describe` fail without saying so.
3. `--depth` implies `--single-branch`: the fetch refspec names `main` only. The last line of the third transcript shows it: after `--unshallow`, `git branch -r` still lists only `origin/main`.
4. Fetch creates a tag when the commit it points at arrives. The tagged commits were behind the boundary; `--unshallow` fetched them, and the tags followed.

**Reasoning.** A shallow clone is a complete snapshot with a truncated history and a file that makes the truncation look like the beginning. It is the right tool for a build that needs the files of one commit, and a trap for anything that asks a question about history.

**Common mistakes.** Using a shallow clone for version stamping, changelogs, or "what changed since main". Believing that `--unshallow` makes the clone equal to a full one: the refspec stays narrow (exercise 18.9 repairs that). Cloning with a local path and wondering why `--depth` had no effect.

**Expert approach.** `git rev-parse --is-shallow-repository` as the first line of any script that reads history, with a clear error. For builds that need some history, a blobless clone (exercise 18.2) keeps every commit and is still small.

**Reference.** Chapter 26, section 26.11 (shallow clones and their limits: the `shallow` file, the silent wrong answers, `--deepen`, `--unshallow`, the narrow refspec) and section 26.13 (`--single-branch`, local clones by path). Tags and shallow clones: Chapter 14B, section 14B.12.

### Exercise 18.2

**Solution.**

<!-- snippet: ex2/answers-m18/18-2-blobless -->
```text
$ git clone -q --filter=blob:none "file://$PWD/server.git" blobless && cd blobless
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
   6 blob
  10 commit
   2 tag
  27 tree
$ git rev-list --objects --missing=print --all | grep -c '^?'
5
$ git config get remote.origin.promisor
true
$ git config get remote.origin.partialclonefilter
blob:none
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m18/18-2-on-demand -->
```text
$ git log --oneline -3 -- docs
8fdeecb Document the new reranker cut-off
8df50a3 Add runbook
3fdf7f7 Describe the architecture
$ git rev-list --objects --missing=print --all | grep -c '^?'
5
$ git show v0.1.0:docs/architecture.md
# Architecture

Query -> retriever -> reranker -> answer.
$ git rev-list --objects --missing=print --all | grep -c '^?'
4
```
<!-- /snippet -->

1. The six blobs of the files in the checked-out commit. The clone itself transferred commits, trees and tags; the checkout then needed the content of the files and fetched exactly those blobs. Five more blobs, older versions, are missing.
2. `git show v0.1.0:docs/architecture.md` lowered the missing count from 5 to 4: it needed the content of an old version and fetched one blob. `git log -- docs` did not change it: to decide whether a commit touched a path, Git compares the IDs in tree objects, and the clone has all trees.
3. `remote.origin.promisor=true` marks the remote as one that has promised to supply missing objects on request. `remote.origin.partialclonefilter=blob:none` is the filter that later fetches apply as well.
4. All of them: every commit is here, so `git log`, `git rev-list --count`, `git describe` and `git merge-base` are correct. `git blame` works too, and downloads the blobs it needs.
5. Any command that needs a blob it does not have while the remote is unreachable: `git log -p`, `git blame` or `git checkout` of an old commit on a train, or after the server has been renamed.

**Reasoning.** A partial clone omits objects by a rule and remembers who can supply them. `blob:none` keeps the whole graph (commits and trees), which is what history questions need, and treats file content as something to fetch when a command reads it.

**Common mistakes.** Expecting zero blobs after a clone that checks out files. Reading "missing" as corruption: missing objects that a promisor remote can supply are by design, and `git fsck` knows it. Running a history-wide content search (`git log -S`, `git grep` over many revisions) and being surprised by the stream of small fetches.

**Expert approach.** For a developer machine on a large repository, `--filter=blob:none` is the default choice. Before working offline, fetch what you will need (check out the branches, or `git backfill`, which is experimental). On a server that you control, `uploadpack.allowFilter` must be enabled.

**Reference.** Chapter 26, section 26.12 (partial clone and promisor remotes: the filters, the two configuration values, on-demand fetches, what "missing" means) and section 26.13 (choosing a clone).

### Exercise 18.3

**Solution.**

<!-- snippet: ex2/answers-m18/18-3-sparse -->
```text
$ git clone -q "file://$PWD/server.git" work && cd work
$ git ls-files
README.md
docs/architecture.md
docs/runbook.md
libs/tokenize/tokenize.py
services/reranker/rerank.py
services/retriever/retrieve.py
$ git sparse-checkout set --cone services/reranker libs/tokenize
$ git sparse-checkout list
libs/tokenize
services/reranker
$ find . -path ./.git -prune -o -type f -print | sort
./libs/tokenize/tokenize.py
./README.md
./services/reranker/rerank.py
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m18/18-3-index -->
```text
$ git ls-files -t
H README.md
S docs/architecture.md
S docs/runbook.md
H libs/tokenize/tokenize.py
H services/reranker/rerank.py
S services/retriever/retrieve.py
$ git status
On branch main
Your branch is up to date with 'origin/main'.

You are in a sparse checkout with 50% of tracked files present.

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m18/18-3-disable -->
```text
$ git sparse-checkout disable
$ find . -path ./.git -prune -o -type f -print | wc -l
       6
```
<!-- /snippet -->

1. The files of `libs/tokenize` and `services/reranker`, and `README.md`. In cone mode the files at the top level of the repository are always included; the pattern set starts from them.
2. `H`: the entry is in the index and the file is in the working tree. `S`: the skip-worktree bit is set, so the entry is in the index and the file is deliberately not on disk. Nothing was removed from the index (`git ls-files` still lists six paths) or from the object database.
3. Sparse checkout reduces the working tree: fewer files on disk, faster status and checkout. Partial clone reduces the object database: fewer objects downloaded. They are independent and combine well.
4. One line: "You are in a sparse checkout with 50% of tracked files present."

**Reasoning.** Sparse checkout is a filter between the index and the working tree. The commit you are on is unchanged, and so is what you would commit: paths outside the cone keep the blob they have in `HEAD`.

**Common mistakes.** Thinking that the other directories were deleted, and "restoring" them. Thinking that a sparse checkout makes the clone smaller. Creating files outside the cone and wondering why `git add` refuses (exercise 18.8).

**Expert approach.** `git sparse-checkout list` and `git ls-files -t | grep -c '^S'` describe the state. `git sparse-checkout add <dir>` widens the cone without retyping it. For a large monorepo, combine: `git clone --filter=blob:none --sparse <url>`, then `git sparse-checkout set`.

**Reference.** Chapter 24, section 24.4 (cone mode: `set`, `list`, `disable`, the top-level files), section 24.5 (living in a sparse checkout, the `S` entries) and section 24.7 (partial clone plus sparse checkout).

### Exercise 18.4

**Solution.**

<!-- snippet: ex2/answers-m18/18-4-graph -->
```text
$ git clone -q --depth 2 "file://$PWD/server.git" two
$ git -C two log --graph --oneline
*   e5603f6 Merge branch 'feature/keep-ten'
|\  
| * 8fdeecb Document the new reranker cut-off
* 49e3cde Retrieve 80 candidates
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m18/18-4-count -->
```text
$ git -C two rev-list --count HEAD
3
$ git -C server.git rev-list --count main
9
$ wc -l < two/.git/shallow
       2
```
<!-- /snippet -->

Three commits: the merge at the tip and both of its parents. Nine on the server. Two lines in `.git/shallow`, one for each parent, because history is cut below each of them.

Depth counts commits along every path from the tip: depth 1 is the tip, depth 2 adds its parents. A merge has two parents, so depth 2 from a merge yields three commits, and both parent lines end at the boundary although on the server they go on (and meet again).

**Reasoning.** `--depth <n>` is a distance in the graph, not a number of commits and not a number of first-parent steps. On a branch full of merges, a small depth already contains many commits, and still not the merge base you may need.

**Common mistakes.** Drawing two commits. Drawing the first parent only. Expecting the graph to show where the two lines rejoin: that commit is not in the clone, and Git draws the two boundary commits as roots.

**Expert approach.** When a build needs "the last few commits", ask what for. If it is for a merge base or a version, depth is the wrong measure: deepen until the thing you need exists (`--shallow-exclude`, `--deepen`), or use a blobless clone.

**Reference.** Chapter 26, section 26.11 ("the commits within a given distance of the requested tips"; boundary commits in the `shallow` file).

### Exercise 18.5

**Solution.**

<!-- snippet: ex2/answers-m18/18-5-single -->
```text
$ git clone -q --single-branch "file://$PWD/server.git" single && cd single
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git tag
v0.1.0
v0.2.0
$ git switch release/0.2
fatal: invalid reference: release/0.2
[exit status: 128]
```
<!-- /snippet -->

One remote-tracking branch; a refspec that names `main` and nothing else; both tags; `git switch release/0.2` fails with "invalid reference", because there is neither a local branch nor a remote-tracking branch of that name to create one from; and `git fetch` prints nothing: within the refspec, the clone is up to date.

<!-- snippet: ex2/answers-m18/18-5-widen -->
```text
$ git fetch
$ git remote set-branches --add origin release/0.2
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
+refs/heads/release/0.2:refs/remotes/origin/release/0.2
$ git fetch
From file://$LAB/ex2/answers-m18/ex-18-5/server
 * [new branch]      release/0.2 -> origin/release/0.2
$ git switch release/0.2
Switched to a new branch 'release/0.2'
branch 'release/0.2' set up to track 'origin/release/0.2'.
```
<!-- /snippet -->

`git remote set-branches --add origin release/0.2` appends a second refspec. The next fetch creates `origin/release/0.2`, and `git switch` can then create the local branch with its upstream.

The tags are here because fetch follows tags: it creates every tag of the server that points into the history it downloads. `v0.1.0` and `v0.2.0` point at ancestors of `main`. The branch `release/0.2` is a ref, and refs are fetched only when a refspec covers them.

**Reasoning.** What a clone tracks is decided by `remote.origin.fetch`. `--single-branch` writes a refspec for one branch instead of the wildcard. From then on every `git fetch` is correct with respect to that refspec and blind to everything else, without any message.

**Common mistakes.** `git fetch origin release/0.2`, which downloads the commits and updates only `FETCH_HEAD`: there is still no `origin/release/0.2`, and the next plain fetch still ignores the branch. Re-cloning. Editing `.git/config` by hand and dropping the `+`. Expecting `git branch -r` to show what the server has: it shows what the last fetch stored.

**Expert approach.** `git config get --all remote.origin.fetch` belongs in the first minute of any "the branch is not there" diagnosis, next to `git ls-remote origin`. `git remote set-branches origin '*'` restores the default wildcard in one command.

**Reference.** Chapter 12, section 12.12 (refspecs in depth, `git remote set-branches`), section 12.4 (what fetch moves, followed tags) and section 12.15 ("invalid reference, though the server has the branch"). Chapter 26, section 26.13 (`--single-branch`).

### Exercise 18.6

**Solution.**

<!-- snippet: ex2/answers-m18/18-6-history-only -->
```text
$ git clone -q --filter=blob:none --no-checkout "file://$PWD/server.git" history && cd history
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
  10 commit
   2 tag
  27 tree
$ git log --oneline -- services/reranker
ec2507b Keep ten passages after reranking
c4fe278 Add reranker service
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
  10 commit
   2 tag
  27 tree
```
<!-- /snippet -->

`--filter=blob:none` omits all blobs, and `--no-checkout` keeps the clone from fetching the blobs of the tip for a working tree. Ten commits, two tags, 27 trees, no blob. The first question, which commits touched `services/reranker`, is answered with the blob count still at zero.

<!-- snippet: ex2/answers-m18/18-6-one-blob -->
```text
$ git show HEAD:services/reranker/rerank.py
"""Reorders candidates with a cross-encoder."""

KEEP = 10


def rerank(scorer, query, passages):
    return sorted(passages, key=lambda p: scorer(query, p), reverse=True)[:KEEP]
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
   1 blob
  10 commit
   2 tag
  27 tree
```
<!-- /snippet -->

The second question needs content: `git show HEAD:services/reranker/rerank.py` fetches one blob. Two answers, one blob downloaded.

The first question needs no blob because a tree entry records the ID of everything beneath it. Git compares the entry `services/reranker` in a commit's tree with the same entry in its parent's tree: equal IDs mean that nothing below changed, different IDs mean that something did. No file content is read.

With `--filter=tree:0` the clone has no trees either:

<!-- snippet: ex2/answers-m18/18-6-treeless -->
```text
$ cd .. && git clone -q --filter=tree:0 --no-checkout "file://$PWD/server.git" treeless && cd treeless
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
  10 commit
   2 tag
$ git log --oneline -- services/reranker
ec2507b Keep ten passages after reranking
c4fe278 Add reranker service
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
  10 commit
   2 tag
  25 tree
```
<!-- /snippet -->

Ten commits and two tags after the clone. The same `git log -- services/reranker` gives the same answer, and to get it Git had to fetch trees from the server: 25 of them are in the repository afterwards. A treeless clone is smaller at rest and pays with requests to the server for every history command that looks at paths.

**Reasoning.** Each kind of question needs one kind of object. "Which commits" needs commits. "Which commits touched this path" needs trees as well. "What does the file contain" needs one blob. A filter that keeps the objects your questions need turns history queries into local operations.

**Common mistakes.** A shallow clone for a history question. Forgetting `--no-checkout` and counting six blobs. Using `git log -p`, which reads the content of every version and fetches blobs one request at a time. Choosing `tree:0` for a developer machine.

**Expert approach.** `blob:none` for people, `tree:0` only for automation that needs commit metadata and one checkout, `--depth 1` only for throwaway builds that read no history. State the question before choosing the clone.

**Reference.** Chapter 26, section 26.12 (the filters `blob:none` and `tree:0`; what each history command needs) and section 26.13 (choosing a clone). Tree entries and their IDs: Chapter 3, section 3.4.

### Exercise 18.7

**Solution.**

<!-- snippet: ex2/answers-m18/18-7-symptom -->
```text
$ scripts/changed-services.sh
fatal: ambiguous argument '': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 0]
$ git merge-base origin/main HEAD; echo "exit status: $?"
exit status: 1
$ git diff --name-only origin/main...HEAD
fatal: origin/main...HEAD: no merge base
[exit status: 128]
```
<!-- /snippet -->

The script prints an error from `git diff`, no service, and exits with 0. The command inside it that fails is `git merge-base origin/main HEAD`: no output, exit status 1. The third command shows what a single Git command makes of the same situation: "no merge base", exit status 128.

<!-- snippet: ex2/answers-m18/18-7-diagnose -->
```text
$ git rev-parse --is-shallow-repository
true
$ git log --graph --oneline --all
* 24ed2ba Add script that lists the changed services
* e5603f6 Merge branch 'feature/keep-ten'
$ cat .git/shallow
24ed2ba03472a813db8c9687e563db94229d8730
e5603f61784e43b551d678e0f5dc59affa8fb638
```
<!-- /snippet -->

The clone is shallow, with a depth of one commit for each of the two refs it has. Both commits are listed in `.git/shallow`, so Git treats both as parentless: two commits with no common ancestor. The real history, in which the feature branch starts at the tip of `main`, was never downloaded. Root cause: the pipeline asks a question about history in a clone that has no history.

<!-- snippet: ex2/answers-m18/18-7-fix -->
```text
$ git fetch -q --unshallow
$ git log --graph --oneline --all | head -6
* 24ed2ba Add script that lists the changed services
* 1a075d4 Add synonym table and expand queries in the retriever
*   e5603f6 Merge branch 'feature/keep-ten'
|\  
| * 8fdeecb Document the new reranker cut-off
| * ec2507b Keep ten passages after reranking
$ git merge-base origin/main HEAD
e5603f61784e43b551d678e0f5dc59affa8fb638
$ scripts/changed-services.sh; echo "exit status: $?"
retriever
exit status: 0
$ git diff --name-only origin/main...HEAD
libs/tokenize/synonyms.py
scripts/changed-services.sh
services/retriever/retrieve.py
```
<!-- /snippet -->

After `git fetch --unshallow` the merge base exists, and the script prints `retriever`.

A cheaper way to the same result is to fetch only as much history as the question needs: `git fetch --deepen=<n>` in a loop until `git merge-base` succeeds, or a blobless clone (`--filter=blob:none`) from the start, which has every commit and tree and downloads file content only for what is checked out.

**The script's own defects.** The missing merge base was the trigger. These turned it into a green pipeline:

1. The result of `git merge-base` is not checked: the script continues with an empty variable.
2. The exit status of a pipeline is that of its last command. `git diff` fails, `sed` and `sort` succeed, and the script exits with 0.
3. Empty output is a valid answer ("no service changed"), so the caller cannot tell "nothing to test" from "could not compute".
4. Two commands do what one does: `git diff --name-only origin/main...HEAD` computes the merge base itself and fails loudly when there is none.

**Reasoning.** Shallow clones give wrong answers quietly. The defence is in two places: a clone that contains what the question needs, and scripts that treat "could not compute" as a failure.

**Common mistakes.** Fetching `main` again with `--depth 1`: that is the state that failed. Hard-coding a larger depth "that should be enough". Falling back to "test everything" inside the script without logging why, which hides the problem and doubles the pipeline time. Fixing the clone and leaving the script as it is.

**Expert approach.** Make the script strict (`set -eu`, test the merge base, exit non-zero with a message that names the shallow clone as the likely cause), use the three-dot diff, and make the pipeline's clone a deliberate choice written down next to the script. On GitHub Actions the equivalent setting is the fetch depth of the checkout step (Chapter 20A, section 20A.8).

**Reference.** Chapter 26, section 26.11 (shallow clones: history questions break silently; `--deepen`, `--unshallow`; the root-cause box) and section 26.12. Three-dot diff: Chapter 14A, section 14A.2. The path-filter and required-check trap in monorepo CI: Chapter 24, section 24.9.

### Exercise 18.8

**Solution.**

<!-- snippet: ex2/answers-m18/18-8-symptom -->
```text
$ ls
README.md
services
$ git ls-files docs
docs/architecture.md
docs/runbook.md
$ git status -sb
## main...origin/main
$ mkdir docs && echo '# Notes' > docs/notes.md
$ git add docs/notes.md
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
docs/notes.md
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
[exit status: 1]
```
<!-- /snippet -->

`ls` shows `README.md` and `services`. `git ls-files docs` lists two files that are not on disk, and `git status` is clean. `git add docs/notes.md` refuses and says why: the path is outside the sparse-checkout definition.

<!-- snippet: ex2/answers-m18/18-8-diagnose -->
```text
$ git sparse-checkout list
services/reranker
$ git ls-files -t docs services
S docs/architecture.md
S docs/runbook.md
H services/reranker/rerank.py
S services/retriever/retrieve.py
```
<!-- /snippet -->

One cause for both observations: the setup script made a cone-mode sparse checkout that contains `services/reranker` only. The `docs` entries are in the index with the `S` flag, which is why Git neither writes them to disk nor reports them as deleted. A new file under `docs` is outside the cone, and `git add` will not update the index there unless asked.

<!-- snippet: ex2/answers-m18/18-8-fix -->
```text
$ git sparse-checkout add docs
$ ls docs
architecture.md
notes.md
runbook.md
$ git add docs/notes.md
$ git status -sb
## main...origin/main
A  docs/notes.md
```
<!-- /snippet -->

`git sparse-checkout add docs` widens the cone by one directory. The two documents appear next to her file, and `git add` accepts it.

The hint's first suggestion, `git add --sparse docs/notes.md`, would have staged the file while leaving the cone as it is. The file would be committed, and it would stay on disk as the one `H` entry among `S` entries in `docs` until the next `git sparse-checkout reapply` removed it from the working tree. She would still not see `docs/runbook.md`, which was her first question. Widening the cone answers both.

**Reasoning.** In a sparse checkout, "tracked", "on disk" and "in the cone" are three different properties. `git ls-files` answers the first, `ls` the second, `git sparse-checkout list` the third.

**Common mistakes.** `git sparse-checkout set docs`, which replaces the cone and removes `services/reranker` from disk. `git sparse-checkout disable`, which works and gives her the whole monorepo. `git checkout -- docs/runbook.md` or `git restore`, which do not materialize a file outside the cone. Looking for the file on other branches.

**Expert approach.** For any "the file is not there" report in a monorepo: `git sparse-checkout list` first. A setup script that creates a sparse checkout should print the cone and the command to widen it.

**Reference.** Chapter 24, section 24.5 (living in a sparse checkout: files outside the cone, `git add` and `--sparse`, `reapply`, `add`) and section 24.4. The `S` flag: Chapter 5, section 5.12.

### Exercise 18.9

**Solution.**

<!-- snippet: ex2/solve-m18-searchstack/01-symptoms -->
```text
$ git switch release/0.2
fatal: invalid reference: release/0.2
[exit status: 128]
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git log --oneline
e5603f6 Merge branch 'feature/keep-ten'
$ git fetch; echo "exit status: $?"
exit status: 0
```
<!-- /snippet -->

All four reports are reproduced. The explanation is in the clone's configuration and in one file:

<!-- snippet: ex2/solve-m18-searchstack/02-evidence -->
```text
$ git config list --local | grep -e ^remote -e ^branch
remote.origin.url=file://$LAB/ex2/solve-m18-searchstack/server.git
remote.origin.tagopt=--no-tags
remote.origin.fetch=+refs/heads/main:refs/remotes/origin/main
branch.main.remote=origin
branch.main.merge=refs/heads/main
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
e5603f61784e43b551d678e0f5dc59affa8fb638
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git ls-remote origin
e5603f61784e43b551d678e0f5dc59affa8fb638	HEAD
e5603f61784e43b551d678e0f5dc59affa8fb638	refs/heads/main
0e308418e6b678bfd75aca2b8fe00fae8232b7e6	refs/heads/release/0.2
836276da87e6597096c0f969433f6c568bfeb2b1	refs/tags/v0.1.0
3fdf7f741298b88db030923dc32549f87f553753	refs/tags/v0.1.0^{}
f2b9d0df8434d9ec623232fd9ee1dafea94a4fa3	refs/tags/v0.2.0
8df50a35a89dc33b1357617414ceb7320b76eead	refs/tags/v0.2.0^{}
```
<!-- /snippet -->

Three independent restrictions:

| Symptom | Evidence | Cause |
|---|---|---|
| `invalid reference: release/0.2` | `remote.origin.fetch=+refs/heads/main:refs/remotes/origin/main` | the refspec covers `main` only, so no fetch ever creates `origin/release/0.2` |
| `No names found` | `remote.origin.tagopt=--no-tags` | fetch is told not to create tags |
| one commit in `git log` | `.git/shallow` exists; `--is-shallow-repository` is `true` | history is cut at the tip |

`git ls-remote origin` shows that the server has the branch and both tags. And `git fetch` prints nothing, truthfully: under these three settings there is nothing to do.

Lift them one at a time. The branches:

<!-- snippet: ex2/solve-m18-searchstack/03-branches -->
```text
$ git remote set-branches origin "*"
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
$ git fetch
From file://$LAB/ex2/solve-m18-searchstack/server
 * [new branch]      release/0.2 -> origin/release/0.2
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/release/0.2
```
<!-- /snippet -->

The history:

<!-- snippet: ex2/solve-m18-searchstack/04-history -->
```text
$ git rev-list --count --all
7
$ git fetch --unshallow
$ git rev-parse --is-shallow-repository
false
$ git rev-list --count --all
10
$ git tag
```
<!-- /snippet -->

`--unshallow` removed the boundary: ten commits instead of seven. The tags did not come, although exercise 18.1 showed `--unshallow` bringing them: `--no-tags` is still configured. The tags:

<!-- snippet: ex2/solve-m18-searchstack/05-tags -->
```text
$ git config unset remote.origin.tagOpt
$ git fetch
From file://$LAB/ex2/solve-m18-searchstack/server
 * [new tag]         v0.1.0     -> v0.1.0
 * [new tag]         v0.2.0     -> v0.2.0
$ git tag
v0.1.0
v0.2.0
```
<!-- /snippet -->

With `remote.origin.tagOpt` unset, the next plain fetch follows tags again and creates both.

<!-- snippet: ex2/solve-m18-searchstack/06-verify -->
```text
$ git describe
v0.2.0-4-ge5603f6
$ git -C ../server.git describe main
v0.2.0-4-ge5603f6
$ git switch release/0.2
Switched to a new branch 'release/0.2'
branch 'release/0.2' set up to track 'origin/release/0.2'.
$ git describe
v0.2.0-1-g0e30841
$ git switch -q main
$ git config list --local | grep -e ^remote
remote.origin.url=file://$LAB/ex2/solve-m18-searchstack/server.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
$ cd ..
$ exercises/gen/m18-searchstack/check.sh
Checking exercise m18-searchstack
  ok    the clone is no longer shallow
  ok    main has its full history
  ok    the fetch refspec covers every branch
  ok    origin/release/0.2 is where the server has the branch
  ok    both tags are present
  ok    tag fetching is no longer switched off (remote.origin.tagOpt)
  ok    git describe on main agrees with the server
  ok    git fsck finds no problem
PASS: exercise m18-searchstack is complete.
[exit status: 0]
```
<!-- /snippet -->

`git describe` on `main` prints `v0.2.0-4-ge5603f6`, the same as on the server; `release/0.2` can be checked out and describes itself as one commit after `v0.2.0`. The configuration is that of an ordinary clone, so a plain `git fetch` keeps it complete.

**Reasoning.** The clone was created with three options (the equivalent of `--depth 1 --single-branch --no-tags`), and each left a durable trace: a `shallow` file, a narrow refspec, a `tagOpt` setting. None of them is an error, and a fetch honors all of them, which is why "up to date" and "incomplete" were both true. The repair is to remove each trace with the command made for it.

**Common mistakes.** `git fetch --all` or `git fetch --tags` once: the first changes nothing here, the second fetches the tags today and leaves `--no-tags` in place for tomorrow. `git fetch origin release/0.2`, which fills `FETCH_HEAD` and creates no remote-tracking branch. Stopping after `--unshallow`. `git pull --unshallow` on a detached or dirty build checkout. Deleting the clone, which the report ruled out.

**Expert approach.** `git config list --local` and `ls .git` (for `shallow`) describe how any clone was made. To convert in one go: `git remote set-branches origin '*'`, `git config unset remote.origin.tagOpt`, `git fetch --unshallow`. Then decide whether the build machine should have been given a blobless clone in the first place: complete history and refs, and small.

**Reference.** Chapter 12, section 12.12 (refspecs, `git remote set-branches`) and section 12.15. Chapter 26, section 26.11 (shallow clones, `--unshallow`, the refspec that stays narrow) and section 26.13 (`--single-branch`, choosing a clone). `git describe` and missing tags: Chapter 14B, section 14B.12.

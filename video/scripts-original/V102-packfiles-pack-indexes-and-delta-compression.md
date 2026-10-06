# V102: Packfiles, pack indexes and delta compression

- **Part.** 4: Git internals
- **Module.** 16
- **Planned minutes.** 24
- **Prerequisites.** V007, V100
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), section 3.7
- **Demo scripts.** `labs/ch03/packfiles.sh`, `labs/ch03/pack-anatomy.sh`, `labs/ch03/lab-16-1-loose-to-pack.sh`, `labs/ch03/lab-16-2-delta-chain.sh`

## HOOK

**[ON SCREEN]** "400 versions × 16 MB = 6 GB?"

Your team keeps four hundred versions of a 16 MB evaluation set in one repository. The CTO does the arithmetic on a whiteboard, four hundred times sixteen megabytes, and asks: are we storing 6 GB?

You have told people for the whole course that Git stores snapshots, not diffs. Every commit is a complete tree. If that is true, the whiteboard arithmetic looks right. And yet the repository on disk is small. Both statements have to be true at once, and this video shows how.

## INTRODUCTION

In the last two videos every object was one zlib-compressed file under `.git/objects`, a loose object. That is how every object begins. It is not how most objects are stored for long. Maintenance consolidates loose objects into a packfile, and inside a packfile an object may be stored as a difference from a similar object.

The plan: the concept, then four replays from `labs/ch03`. `packfiles.sh` and `pack-anatomy.sh` are the demonstration; `lab-16-1-loose-to-pack.sh` and `lab-16-2-delta-chain.sh` are the two labs you will do yourself, shown up to their checkpoints.

One command in this video changes state: `git gc`, labelled 🟡 CAUTION in the chapter's command safety table. Everything else reads.

## LEARNING OBJECTIVES

After this video you can:

- Explain how a pack stores many objects and why that does not change the snapshot model.
- Watch loose objects become a pack and count both.
- Read a `git verify-pack -v` listing and follow a delta chain to its base.
- Say which version of the lab's file is stored whole and how the listing shows it.
- Say what the pack index is for.

## CONCEPT

Why packs exist: a loose object is one file per object, and each version of a file is a complete compressed copy. That is fine for today's work and wasteful for years of history.

In one sentence: a packfile stores many objects in one file and may store an object as a difference from a similar object, an index file beside it finds any object by ID, and none of this changes what an object is.

Precisely. Every command that records content writes loose objects. Maintenance later consolidates them into a pack. In this video that is `git gc`; the automatic strategies are the subject of Chapter 26 and of a later video. A pack is three files.

**[ON SCREEN]** `pack-<checksum>.pack`, `.idx`, `.rev`.

The `.pack` file has a 12-byte header: the signature `PACK`, a version, and the number of objects. Then one entry per object, and at the end a checksum of everything before it. An entry is a type, a size and zlib-compressed data. In the deltified form, the data is a list of copy and insert instructions against a base object, and the base is named by its offset in the same pack or by its ID.

The `.idx` file is the pack index. It holds the object IDs in sorted order, a CRC32 and the pack offset for each, and a 256-entry table saying where the IDs with each first byte begin. Finding an object is a binary search in the index, then one read at the offset.

The `.rev` file is the reverse map, from position in the pack to position in the index.

The manual states the principle in one line. I will read it as written: "Conceptually there are only four object types: commit, tree, tag and blob. However to save space, an object could be stored as a 'delta' of another 'base' object."

How does Git choose what to compare? It is a heuristic. `git pack-objects` sorts the objects by type, size and name, compares each with its neighbours inside a window of ten, the `--window` option, and does not let a chain grow deeper than fifty, the `--depth` option.

Three statements keep the two levels apart, and you should be able to say all three.

First: a delta is between two objects chosen for similarity. It is not "the change a commit made". The base can be another version of the same file or a different file.

Second: IDs are computed from full content. So packing changes no ID, no tree and no commit, and `git cat-file`, `git show` and `git checkout` always deliver full content.

Third: the choice of base, in the words of the `git cat-file` manual, "is arbitrary and is subject to change during a repack". So a size on disk says little about which commit "caused" it.

Inside `.git`, when `git gc` runs: loose object files disappear; one `.pack`, one `.idx` and one `.rev` appear under `objects/pack/`; and `git gc` also writes `packed-refs` and `objects/info/commit-graph`. Both of those come back in later videos.

When does this not help? Three limits. Deltas need similar bytes, so compressed archives and model weights gain nothing. Files above `core.bigFileThreshold`, 512 MiB by default, are stored without any attempt at deltas. And a clone transfers a pack, so everything reachable is downloaded however well it compresses.

## MENTAL MODEL

The textbook's analogy is a warehouse. It keeps one complete copy of a long contract and, for each earlier draft, a sheet of instructions: copy bytes 0 to 2,400 of the complete copy, insert these twelve bytes, copy the rest. You ask for a draft by its number and you always receive the complete draft.

Where the analogy breaks is in who decides. The warehouse chooses which version is kept whole. It may choose differently at every reorganisation. And nothing you see through Git depends on it.

So keep two levels in your head. The object level is what Git promises: four types, full content, an ID computed from that content. The storage level is how the bytes happen to sit on disk today. The snapshot model lives at the first level. Deltas live at the second.

## DIAGRAM

**[DIAGRAM]** Build the chain from left to right. Each arrow reads "is stored as a delta against".

```text
   newest version                                                       oldest version
   a4e58256 <--- 739088cd <--- d77675f2 <--- d900a91b <--- 782b8e9b <--- 0928d48c
   whole         depth 1       depth 2       depth 3       depth 4       depth 5
   1372 bytes    35 bytes      30 bytes      35 bytes      30 bytes      35 bytes    in the pack
   16789 bytes   16788         16787         16786         16785         16784       as an object
```

Six versions of one file. On the left, `a4e58256`, stored whole: 1,372 bytes in the pack for an object of 16,789 bytes. Then `739088cd` at depth 1, stored as a delta against it, 35 bytes in the pack. Then depth 2, 3, 4, and on the right `0928d48c` at depth 5.

Now read the top line. The newest version is the whole one, and the old versions are the deltas. That is the opposite of what "Git stores diffs" would suggest. To read the oldest version, Git reads the base and applies five deltas.

Read the bottom line. As an object, every version has its full size. That line is what Git shows you; the line above it is what the disk holds.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch03/packfiles
```

An evaluation harness whose test-case file has 200 lines. Five commits each change one line of it.

```bash
git log --oneline
wc -l eval/cases.jsonl
git count-objects -v
```

**[PAUSE]** Six commits. Predict the `count` line: how many loose objects? Count the commits, the trees and the blobs.

<!-- snippet: ch03/packfiles/01-loose -->
```text
$ git log --oneline
14fbba9 Relax case 150 to two sentences
d076308 Relax case 120 to two sentences
5c0b0dc Relax case 90 to two sentences
709d5d8 Relax case 60 to two sentences
213918f Relax case 30 to two sentences
609e81f Add evaluation cases
$ wc -l eval/cases.jsonl
     200 eval/cases.jsonl
$ git count-objects -v
count: 25
size: 100
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
```
<!-- /snippet -->

Twenty-five: six commits, twelve trees, six versions of `cases.jsonl` and one small configuration file. `count` and `size` describe loose objects, and `size` is disk space in KiB. Every one of the 25 files occupies a 4 KiB block, however small its content.

Now the 🟡 command. `git gc` packs objects and refs, expires reflog entries by age, and deletes unreachable objects older than two weeks. Preview what it could remove with `git fsck --unreachable`. Within the retention periods, nothing is lost.

```bash
git gc
git count-objects -v
find .git/objects -type f | sort
```

**[PAUSE]** What will `count` say now, and what will `in-pack` say?

<!-- snippet: ch03/packfiles/02-gc -->
```text
$ git gc
$ git count-objects -v
count: 0
size: 0
in-pack: 25
packs: 1
size-pack: 4
prune-packable: 0
garbage: 0
size-garbage: 0
$ find .git/objects -type f | sort
.git/objects/info/commit-graph
.git/objects/info/packs
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
```
<!-- /snippet -->

The same 25 objects, now `in-pack`, in 4 KiB where there were 100. Point at the three pack files, and at `commit-graph` beside them.

**[ON SCREEN]** The state table for `git gc`: working tree unchanged, index unchanged, HEAD unchanged, current branch ref the same value with the loose file moved into `packed-refs`; in `.git`, loose objects become a pack, `packed-refs` and `commit-graph` are written, reflog entries past their expiry are removed and unreachable objects past the grace period are deleted; remote unchanged; GitHub unchanged.

Look inside the pack.

```bash
git verify-pack -v .git/objects/pack/pack-*.idx
```

<!-- snippet: ch03/packfiles/03-verify-pack -->
```text
$ git verify-pack -v .git/objects/pack/pack-*.idx
14fbba9f81a145d88e699ad6379b7844b71e855a commit 232 163 12
d076308a75023ff48e849cd91e1acac4fce7f4c6 commit 232 166 175
5c0b0dc76a1661cca61de1475a80959793e9280c commit 231 164 341
709d5d8beab89236b8649acadca336e7406c6132 commit 231 163 505
213918f93a4e5886620977a101f7181e57459140 commit 231 165 668
609e81f2752953bc7efa6215b74b1d08bde2ceef commit 173 128 833
a4e58256c921e15fecaaaf744fbdb04b37907a40 blob   16789 1372 961
26489f627fb36b56d87f8b615855f57c7888fd60 blob   17 27 2333
794774c4549fba17c4a64943e946feeac7c0ed4d tree   31 40 2360
89f3a9862e1b2373ab6e9bcac1e76d158b8c478f tree   78 85 2400
8c9b4e17e9e4d4e2aa09bd48ba220549944e06d2 tree   31 40 2485
5a92fde4e91ed06f182b9a45d78fa51d92e87e7f tree   78 85 2525
739088cda5ca15c1fd59dc40238f8852f7f677de blob   22 35 2610 1 a4e58256c921e15fecaaaf744fbdb04b37907a40
59ded879fc1920533dd82f4e9f2a55ecc7480549 tree   31 41 2645
9513db28fdebd67318d477e402e045a33336949c tree   78 84 2686
d77675f2a7b00158d41dc879b35011a742015f48 blob   17 30 2770 2 739088cda5ca15c1fd59dc40238f8852f7f677de
b19c9a4c02f3742eab5f0ccfc40e1fc2b4f66b3c tree   31 40 2800
5b0701b0d0b031208d1e4972513376c5cd0ae392 tree   78 85 2840
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 blob   22 35 2925 3 d77675f2a7b00158d41dc879b35011a742015f48
be320f0afa9a2877aa5134ee84b85c6ada640031 tree   31 40 2960
b99c6ada4476e39a26ae54f9ab22db3aec8d1f1d tree   78 84 3000
782b8e9b7662fd152695234c4ba08fde34c18f73 blob   18 30 3084 4 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
b803d0495a5e56f35f19109a922d0ca78f64c184 tree   31 41 3114
a1356effbbb0a03fd3fa3115791bcf98670794b4 tree   78 84 3155
0928d48c558a6457e11c9fa47f347fb2a190259f blob   22 35 3239 5 782b8e9b7662fd152695234c4ba08fde34c18f73
non delta: 20 objects
chain length = 1: 1 object
chain length = 2: 1 object
chain length = 3: 1 object
chain length = 4: 1 object
chain length = 5: 1 object
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack: ok
```
<!-- /snippet -->

The columns are object ID, type, size, size in the pack, and offset. A deltified object has two more: the depth of its chain and the ID of its base. Find the line for `a4e58256`: 16,789 bytes that compress to 1,372, and five columns only, so it is stored whole. Find `739088cd`: seven columns, depth 1, base `a4e58256`. For a delta, the size column is the size of the delta. The summary at the bottom counts chain lengths: twenty objects that are not deltas, and one object at each length from 1 to 5.

Is the oldest version still a complete file?

```bash
git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'
git cat-file -p 0928d48c | wc -l
git cat-file -p 0928d48c | sed -n 30p
git cat-file -p HEAD:eval/cases.jsonl | sed -n 30p
```

**[PAUSE]** The oldest version costs 35 bytes in the pack. How many lines will `git cat-file -p` print for it?

<!-- snippet: ch03/packfiles/04-snapshots-intact -->
```text
# Logical size, size on disk, and delta base of each version of the file, newest first:
$ git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'
a4e58256c921e15fecaaaf744fbdb04b37907a40 16789 1372 0000000000000000000000000000000000000000
739088cda5ca15c1fd59dc40238f8852f7f677de 16788 35 a4e58256c921e15fecaaaf744fbdb04b37907a40
d77675f2a7b00158d41dc879b35011a742015f48 16787 30 739088cda5ca15c1fd59dc40238f8852f7f677de
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 16786 35 d77675f2a7b00158d41dc879b35011a742015f48
782b8e9b7662fd152695234c4ba08fde34c18f73 16785 30 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
0928d48c558a6457e11c9fa47f347fb2a190259f 16784 35 782b8e9b7662fd152695234c4ba08fde34c18f73
# The oldest version sits at the end of a five-step chain and still reads back whole:
$ git cat-file -p 0928d48c | wc -l
     200
$ git cat-file -p 0928d48c | sed -n 30p
{"id": 30, "prompt": "Summarise ticket 30 in one sentence", "expected_tokens": 30}
$ git cat-file -p HEAD:eval/cases.jsonl | sed -n 30p
{"id": 30, "prompt": "Summarise ticket 30 in two sentences", "expected_tokens": 30}
```
<!-- /snippet -->

Two hundred lines. `%(objectsize)` is the size of the object, `%(objectsize:disk)` is what its entry costs in the pack, and `%(deltabase)` is all zeros for an object that is stored whole.

One more step. Commit again after the `git gc`.

```bash
printf 'threshold = 0.85\n' > eval/config.toml
git commit -q -am "Raise pass threshold"
git count-objects -v
```

<!-- snippet: ch03/packfiles/05-loose-again -->
```text
$ printf 'threshold = 0.85\n' > eval/config.toml
$ git commit -q -am "Raise pass threshold"
$ git count-objects -v
count: 4
size: 16
in-pack: 25
packs: 1
size-pack: 4
prune-packable: 0
garbage: 0
size-garbage: 0
```
<!-- /snippet -->

Four loose objects next to the pack of 25. New commits are loose objects again until the next consolidation. That is the normal state of a working repository.

**[TERMINAL]** The files themselves.

```bash
labs/run ch03/pack-anatomy
```

```bash
ls .git/objects/pack
head -c 12 .git/objects/pack/pack-*.pack | xxd
tail -c 20 .git/objects/pack/pack-*.pack | xxd -p
```

<!-- snippet: ch03/pack-anatomy/01-pack-file -->
```text
$ ls .git/objects/pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
# The first twelve bytes of the pack: signature, version, number of objects (0x19 is 25).
$ head -c 12 .git/objects/pack/pack-*.pack | xxd
00000000: 5041 434b 0000 0002 0000 0019            PACK........
# The last twenty bytes: a checksum of everything before them. It is also the name of the file.
$ tail -c 20 .git/objects/pack/pack-*.pack | xxd -p
8027c3005e9ed6293511e1bef76969aa63a131bc
```
<!-- /snippet -->

Twelve bytes: the signature `PACK`, version 2, and hexadecimal 19, which is 25 objects. The last twenty bytes are the checksum of everything before them, and that checksum is also the name of the file.

```bash
head -c 8 .git/objects/pack/pack-*.idx | xxd
git show-index < .git/objects/pack/pack-*.idx | head -4
git show-index < .git/objects/pack/pack-*.idx | sort -n | head -4
tail -c 40 .git/objects/pack/pack-*.idx | xxd -p -c 20
```

<!-- snippet: ch03/pack-anatomy/02-pack-index -->
```text
# The index starts with a magic number and its own version:
$ head -c 8 .git/objects/pack/pack-*.idx | xxd
00000000: ff74 4f63 0000 0002                      .tOc....
# Its entries, decoded: offset in the pack, object ID, CRC32. They are sorted by object ID:
$ git show-index < .git/objects/pack/pack-*.idx | head -4
3239 0928d48c558a6457e11c9fa47f347fb2a190259f (713cb177)
12 14fbba9f81a145d88e699ad6379b7844b71e855a (197f240b)
668 213918f93a4e5886620977a101f7181e57459140 (d1bdaf2c)
2333 26489f627fb36b56d87f8b615855f57c7888fd60 (ac6cf501)
# Sorted by offset instead, the same entries give the order of the objects inside the pack:
$ git show-index < .git/objects/pack/pack-*.idx | sort -n | head -4
12 14fbba9f81a145d88e699ad6379b7844b71e855a (197f240b)
175 d076308a75023ff48e849cd91e1acac4fce7f4c6 (06d8d7ea)
341 5c0b0dc76a1661cca61de1475a80959793e9280c (b18d9a25)
505 709d5d8beab89236b8649acadca336e7406c6132 (7d7faf7e)
# The index ends with the checksum of its pack, then a checksum of itself:
$ tail -c 40 .git/objects/pack/pack-*.idx | xxd -p -c 20
8027c3005e9ed6293511e1bef76969aa63a131bc
d34871f7ea2e09071ce733054562a3a8be5765c3
```
<!-- /snippet -->

The index starts with a magic number and version 2. Its entries are offset, object ID and CRC32, sorted by object ID. Sorted by offset, the same entries give the order of objects inside the pack: 12, 175, 341, the offsets the pack listing showed. The index ends with the checksum of its pack, then a checksum of itself. The index is derived data: Lab 16.1 deletes it and rebuilds an identical one.

**[TERMINAL]** The two labs, up to their checkpoints. Replay them; the IDs match the lab manual.

```bash
labs/run ch03/lab-16-1-loose-to-pack
```

A vocabulary file of 400 tokens and three commits. After `git gc`:

<!-- snippet: ch03/lab-16-1-loose-to-pack/03-gc -->
```text
$ git gc
$ git count-objects -v
count: 0
size: 0
in-pack: 9
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
$ find .git/objects -type f | sort
.git/objects/info/commit-graph
.git/objects/info/packs
.git/objects/pack/pack-681612f23eec6d108669ce9fcd88366a662d2c2f.idx
.git/objects/pack/pack-681612f23eec6d108669ce9fcd88366a662d2c2f.pack
.git/objects/pack/pack-681612f23eec6d108669ce9fcd88366a662d2c2f.rev
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
b85fc6562e9f858ee4bb51cf2466413db7601510 refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch03/lab-16-1-loose-to-pack/04-content-unchanged -->
```text
# Every snapshot is still complete. The first version of the file has its 400 lines:
$ git cat-file -p HEAD~2:vocab.txt | wc -l
     400
$ git cat-file -s HEAD~2:vocab.txt
4400
# Inside the pack, two of the three versions are stored as deltas:
$ git verify-pack -v .git/objects/pack/pack-*.idx | grep blob
664847f27762fa1c3e652eff3a5a5a70545379b9 blob   4422 739 450
3a0a6a81d285b670659e61ddf1367404a2d41069 blob   7 18 1284 1 664847f27762fa1c3e652eff3a5a5a70545379b9
891043a303f645d3227dfe8b43d419be23af0633 blob   7 18 1350 1 664847f27762fa1c3e652eff3a5a5a70545379b9
```
<!-- /snippet -->

Point at the three blob lines. One is whole; two have seven columns, both at depth 1 against the same base. The first version of the file still has its 400 lines.

```bash
labs/run ch03/lab-16-2-delta-chain
```

<!-- snippet: ch03/lab-16-2-delta-chain/03-chain -->
```text
# Deltified objects have seven columns. Print depth, object and base, shallowest first:
$ git verify-pack -v .git/objects/pack/pack-*.idx | awk 'NF == 7 {print $6, $1, $7}' | sort -n
1 739088cda5ca15c1fd59dc40238f8852f7f677de a4e58256c921e15fecaaaf744fbdb04b37907a40
2 d77675f2a7b00158d41dc879b35011a742015f48 739088cda5ca15c1fd59dc40238f8852f7f677de
3 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 d77675f2a7b00158d41dc879b35011a742015f48
4 782b8e9b7662fd152695234c4ba08fde34c18f73 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
5 0928d48c558a6457e11c9fa47f347fb2a190259f 782b8e9b7662fd152695234c4ba08fde34c18f73
# The base of the whole chain is the one object that is stored whole:
$ git verify-pack -v .git/objects/pack/pack-*.idx | grep a4e58256 | head -1
a4e58256c921e15fecaaaf744fbdb04b37907a40 blob   16789 1372 961
```
<!-- /snippet -->

<!-- snippet: ch03/lab-16-2-delta-chain/04-which-version -->
```text
# Which version of the file is which object? Newest commit first:
$ git log --format='%h %s' -- eval/cases.jsonl | while read commit subject; do echo "$(git rev-parse --short=8 $commit:eval/cases.jsonl) $commit $subject"; done
a4e58256 14fbba9 Relax case 150 to two sentences
739088cd d076308 Relax case 120 to two sentences
d77675f2 5c0b0dc Relax case 90 to two sentences
d900a91b 709d5d8 Relax case 60 to two sentences
782b8e9b 213918f Relax case 30 to two sentences
0928d48c 609e81f Add evaluation cases
```
<!-- /snippet -->

The chain, shallowest first, and then the mapping from object to commit. The object stored whole belongs to the newest commit. Stop here: the rest of each lab, the failure and the recovery, is yours.

## COMMON MISTAKES

1. Saying "Git stores diffs" after seeing a pack listing. Root cause: a delta is a storage detail between two similar objects; every object still has its full content and its ID is computed from that content.
2. Blaming a commit for disk usage because its blob is the large entry. Root cause: the choice of base is arbitrary and can change at any repack.
3. Expecting packs to shrink model weights or compressed archives. Root cause: deltas need similar bytes.
4. Treating a missing `.idx` as lost data. Root cause: the pack index is derived from the pack and can be rebuilt with `git index-pack`.
5. Being surprised by loose objects after `git gc`. Root cause: every command that records content writes loose objects; consolidation happens later.

## PRODUCTION EXAMPLE

Back to the whiteboard. Four hundred versions of a line-oriented 16 MB evaluation set that differ in a few records cost roughly one compressed copy plus four hundred small deltas. That is the answer for a JSON Lines file of test cases.

The same team also commits a model checkpoint. For that file the answer is different, and you can say why before you measure: deltas need similar bytes, so the checkpoint gains nothing; above `core.bigFileThreshold` Git does not even try; and whatever the compression, a clone transfers a pack, so everything reachable is downloaded. That is where Chapter 22, Git LFS, begins.

## PRACTICE EXERCISE

Do Lab 16.1, "Watch loose objects become a pack", in [`lab-manual/m16-object-database.md`](../../lab-manual/m16-object-database.md). Before you run `git gc`, predict `count`, `in-pack` and `packs`. Before the fourth commit, predict what `git count-objects -v` will show after it. Then do the lab's failure scenario and recovery.

The challenge is Lab 16.2, "Read a pack listing and find a delta chain", in the same file. Before you read the listing, predict which version of the file is stored whole.

## INTERVIEW QUESTION

Question 77 of the CTO question bank:

> "We have six versions of a 16 MB file. What does the pack contain, which version is stored whole, and what happens when a byte in that version is damaged?"

A strong answer separates the object level from the storage level in its first sentence. It says what determines whether deltas are possible at all, describes the direction of the chain and what follows for every object that depends on the base, and ends with how the damage is detected and from where the object is restored. Lab 16.2 lets you produce the damage yourself before you answer.

## RECAP

You should now be able to say:

- New objects are loose; maintenance consolidates them into a `.pack` with an `.idx` and a `.rev`.
- In a pack, an object may be stored as a delta against a similar base, chosen by a heuristic.
- Packing changes no ID: every object reads back with its full content.
- In a `git verify-pack -v` listing, seven columns mean a delta, and the last two are depth and base.
- The pack index maps IDs to offsets and can be rebuilt.

## HOMEWORK

Read section 3.7 of [Chapter 3](../../textbook/ch03-git-internals.md). Do Exercise 16.3, "Loose objects become a pack", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

# Module 16 labs: The object database, part 1 (object storage)

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the replay scripts in `labs/ch03/`. Read [Chapter 3](../textbook/ch03-git-internals.md), sections 3.3, 3.7 and 3.8, first. Labs 16.3 and 16.4, on maintenance, belong to Chapter 26 and live in a separate file of this module.

## How to run these labs

Lab 16.1 starts from an empty directory that you fill yourself. Lab 16.2 starts from a repository that a setup script builds with a fixed clock, so its commit IDs are the ones printed here. From the course root:

```bash
labs/shell m16-1                                  # Lab 16.1: an empty sandbox
bash labs/ch03/setup-16-2-delta-history.sh        # Lab 16.2: builds the starting repository
labs/shell m16-2
cd eval-harness
```

Three differences between your terminal and the transcripts:

- In Lab 16.1 you create the commits yourself at the real time, so your commit IDs, tree IDs and pack name differ from the book. Blob IDs are identical, because a blob ID depends on content alone. Compare counts, sizes and structure, not commit IDs.
- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from the replay script.

To see a lab exactly as printed, replay it: `labs/run ch03/lab-16-1-loose-to-pack` or `labs/run ch03/lab-16-2-delta-chain`. Answers to the questions are in [solutions/m16-lab-answers.md](../solutions/m16-lab-answers.md). Write your own first.

## Lab 16.1: Watch loose objects become a pack

### Objective

See `git gc` turn loose objects into a pack while every object keeps its ID and its content, read the pack listing, and rebuild a deleted pack index from the pack.

### Prerequisites

Chapter 3, sections 3.3 (loose objects), 3.7 (packs) and 3.8 (reachability). The commands `git count-objects -v`, `git verify-pack -v` and `git index-pack`.

### Setup

```bash
labs/shell m16-1
```

The sandbox is empty. You build a repository for a tokenizer vocabulary.

### Commands

Three commits to one file, then the inventory of `.git/objects`. Before you run `git count-objects`, write down how many loose objects you expect and of which types.

```bash
git init tokenizer-vocab
cd tokenizer-vocab
seq -f 'token_%04g' 1 400 > vocab.txt
git add vocab.txt
git commit --quiet -m "Add vocabulary of 400 tokens"
echo 'token_0401' >> vocab.txt
git commit --quiet -am "Add token 401"
echo 'token_0402' >> vocab.txt
git commit --quiet -am "Add token 402"
git log --oneline
git count-objects -v
find .git/objects -type f | sort
```

Now consolidate, and inventory again:

```bash
git gc
git count-objects -v
find .git/objects -type f | sort
cat .git/packed-refs
```

### Expected output

<!-- snippet: ch03/lab-16-1-loose-to-pack/01-history -->
```text
$ git init tokenizer-vocab
Initialized empty Git repository in $LAB/ch03/lab-16-1-loose-to-pack/tokenizer-vocab/.git/
$ cd tokenizer-vocab
$ seq -f 'token_%04g' 1 400 > vocab.txt
$ git add vocab.txt
$ git commit --quiet -m "Add vocabulary of 400 tokens"
$ echo 'token_0401' >> vocab.txt
$ git commit --quiet -am "Add token 401"
$ echo 'token_0402' >> vocab.txt
$ git commit --quiet -am "Add token 402"
$ git log --oneline
b85fc65 Add token 402
735950d Add token 401
da51397 Add vocabulary of 400 tokens
```
<!-- /snippet -->

<!-- snippet: ch03/lab-16-1-loose-to-pack/02-loose -->
```text
$ git count-objects -v
count: 9
size: 36
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
$ find .git/objects -type f | sort
.git/objects/3a/0a6a81d285b670659e61ddf1367404a2d41069
.git/objects/66/4847f27762fa1c3e652eff3a5a5a70545379b9
.git/objects/73/5950d5df6b56b47c60c46b3852064282919853
.git/objects/89/1043a303f645d3227dfe8b43d419be23af0633
.git/objects/98/3817d99837de69b578cd23f01b226b7087cd19
.git/objects/a7/aa335413ba58088a7c4484c7b3419fe8a641da
.git/objects/b8/5fc6562e9f858ee4bb51cf2466413db7601510
.git/objects/da/513977559346b2a44fbd9306ee1e076f6e573d
.git/objects/fd/5b74dc5e272d5d0ac889fbb6ebe83bdc23b338
```
<!-- /snippet -->

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

### What happened internally

Nine loose objects for three commits: three commits, three trees and three blobs. Each commit changed `vocab.txt`, so each has its own blob and, because the top-level tree names that blob, its own tree. `size: 36` is disk space in KiB: nine files, one 4 KiB filesystem block each. `git gc` ran a repack that wrote every reachable object into one pack with its `.idx` and `.rev` files, deleted the loose files, ran `git pack-refs --all` (which moved `refs/heads/main` into `packed-refs` and removed the loose ref file), and wrote `objects/info/commit-graph`. The same nine objects now take 2 KiB: one file, zlib across the whole, and two of the three blobs stored as deltas.

### Checkpoint

The content is untouched. Confirm it, read the blob lines of the pack listing, then make a fourth commit and watch loose objects appear beside the pack and disappear again:

```bash
git cat-file -p HEAD~2:vocab.txt | wc -l
git cat-file -s HEAD~2:vocab.txt
git verify-pack -v .git/objects/pack/pack-*.idx | grep blob
echo 'token_0403' >> vocab.txt
git commit --quiet -am "Add token 403"
git count-objects -v
git gc
git count-objects -v
```

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

<!-- snippet: ch03/lab-16-1-loose-to-pack/05-loose-again -->
```text
$ echo 'token_0403' >> vocab.txt
$ git commit --quiet -am "Add token 403"
$ git count-objects -v
count: 3
size: 12
in-pack: 9
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
$ git gc
$ git count-objects -v
count: 0
size: 0
in-pack: 12
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
```
<!-- /snippet -->

The newest blob, `664847f2` with 4,422 bytes, is stored whole; the two older versions are deltas of seven bytes each against it, at depth 1. Your pack name differs from the book because the commits differ; the three blob IDs and the sizes do not.

### Failure scenario

The pack index disappears. This is what a half-finished copy of a repository, or a cleanup script that matched `*.idx`, leaves behind:

```bash
mv .git/objects/pack/pack-*.idx ../saved.idx
git status
git rev-parse HEAD
git cat-file -t HEAD
git count-objects -v
```

<!-- snippet: ch03/lab-16-1-loose-to-pack/06-failure -->
```text
# Failure scenario: the pack index disappears.
$ mv .git/objects/pack/pack-*.idx ../saved.idx
$ git status
error: bad tree object HEAD
[exit status: 128]
# The ref still resolves. The object it names cannot be found:
$ git rev-parse HEAD
1edd58edbf23b330988073db163ff58ca10761c4
$ git cat-file -t HEAD
fatal: git cat-file: could not get object info
[exit status: 128]
$ git count-objects -v
warning: no corresponding .idx: .git/objects/pack/pack-7c887439693a848f0f5224f70d8e1877c7b1d336.pack
warning: no corresponding .idx: .git/objects/pack/pack-7c887439693a848f0f5224f70d8e1877c7b1d336.rev
count: 0
size: 0
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 2
size-garbage: 1
```
<!-- /snippet -->

Git cannot find any object: without the index it does not know where in the pack anything is, and `count-objects` reports the pack and its `.rev` file as garbage. The refs are intact, which is why `git rev-parse HEAD` still prints an ID.

### Recovery

The index is derived data. Rebuild it from the pack:

```bash
git index-pack .git/objects/pack/pack-*.pack
ls .git/objects/pack
cmp .git/objects/pack/pack-*.idx ../saved.idx && echo "identical to the index we removed"
git status --short
```

<!-- snippet: ch03/lab-16-1-loose-to-pack/07-recovery -->
```text
# The index of a pack is derived data. Rebuild it from the pack itself:
$ git index-pack .git/objects/pack/pack-*.pack
7c887439693a848f0f5224f70d8e1877c7b1d336
$ ls .git/objects/pack
pack-7c887439693a848f0f5224f70d8e1877c7b1d336.idx
pack-7c887439693a848f0f5224f70d8e1877c7b1d336.pack
pack-7c887439693a848f0f5224f70d8e1877c7b1d336.rev
$ cmp .git/objects/pack/pack-*.idx ../saved.idx && echo "identical to the index we removed"
identical to the index we removed
$ git status --short
[exit status: 0]
```
<!-- /snippet -->

`git index-pack` 🟢 reads every object in the pack, recomputes its ID from its content, and writes the sorted table of IDs, offsets and checksums. It prints the pack checksum, which is also the pack's name. The rebuilt index is byte for byte the one that was removed, because both are functions of the same pack.

### Verification

```bash
git fsck
git count-objects -v
git log --oneline
```

<!-- snippet: ch03/lab-16-1-loose-to-pack/08-verification -->
```text
$ git fsck
[exit status: 0]
$ git count-objects -v
count: 0
size: 0
in-pack: 12
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
$ git log --oneline
1edd58e Add token 403
b85fc65 Add token 402
735950d Add token 401
da51397 Add vocabulary of 400 tokens
```
<!-- /snippet -->

### Questions

1. Name the nine loose objects by type and explain why there are three trees although the repository has one directory.
2. `size: 36` before the first `git gc`, `size-pack: 2` after it. Give the two separate reasons for the difference.
3. In the `verify-pack` listing the two older blobs show `7` in the size column, while `git cat-file -s` reports 4,400 and 4,411 bytes for them. What is the 7, and which object is their base?
4. With the `.idx` removed, `git rev-parse HEAD` succeeded and `git cat-file -t HEAD` failed. Which data does each command need?
5. `git index-pack` produced an index identical to the deleted one. Why could it, what could it not have rebuilt if the `.pack` had been deleted instead, and where would you have found the objects then?

## Lab 16.2: Read a pack listing and find a delta chain

### Objective

Read `git verify-pack -v` line by line, identify a delta chain and relate each object in it to a version of the file, prove that the logical size of every version is intact, and then recover from one damaged byte in the pack without a backup.

### Prerequisites

Chapter 3, sections 3.7 and 3.8; Lab 16.1.

### Setup

```bash
bash labs/ch03/setup-16-2-delta-history.sh
labs/shell m16-2
cd eval-harness
```

The repository holds an evaluation harness: `eval/cases.jsonl` with 200 test cases, one JSON document per line, and `eval/config.toml`. Six commits; five of them each change one line of the cases file. The setup script fixes the clock, so the IDs below are the IDs in your sandbox.

### Commands

Pack the repository and read the listing. Then extract the chain: deltified objects have seven columns, and the sixth is the depth.

```bash
git log --oneline
git gc
ls .git/objects/pack
git verify-pack -v .git/objects/pack/pack-*.idx
git verify-pack -v .git/objects/pack/pack-*.idx | awk 'NF == 7 {print $6, $1, $7}' | sort -n
git verify-pack -v .git/objects/pack/pack-*.idx | grep a4e58256 | head -1
```

Fill in the table before you look at the expected output:

| Depth | Object (first 8 digits) | Stored as a delta against | Size in the pack |
|---|---|---|---|
| 0 (whole) | | — | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

### Expected output

<!-- snippet: ch03/lab-16-2-delta-chain/01-pack -->
```text
$ git log --oneline
14fbba9 Relax case 150 to two sentences
d076308 Relax case 120 to two sentences
5c0b0dc Relax case 90 to two sentences
709d5d8 Relax case 60 to two sentences
213918f Relax case 30 to two sentences
609e81f Add evaluation cases
$ git gc
$ ls .git/objects/pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
```
<!-- /snippet -->

<!-- snippet: ch03/lab-16-2-delta-chain/02-listing -->
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

### What happened internally

Twenty-five objects: six commits, twelve trees (a top-level tree and an `eval` tree per commit), six versions of `cases.jsonl` and one `config.toml`. Twenty are stored whole. Five are deltas, and they form one chain: `739088cd` is a delta against `a4e58256`, `d77675f2` against `739088cd`, and so on down to `0928d48c` at depth 5. The base of the chain, `a4e58256`, is 16,789 bytes and compresses to 1,372; each delta is 17 to 22 bytes of instructions ("copy this range of the base, insert these bytes, copy the rest") and 30 to 35 bytes in the pack. To deliver the object at depth 5, Git reads the base and applies five deltas. The columns of the listing are object ID, type, size (for a delta, the size of the delta), size in the pack, offset, and for deltas the depth and the base.

### Checkpoint

Which version of the file is which object, newest commit first, and the sizes as Git presents them:

```bash
git log --format='%h %s' -- eval/cases.jsonl | while read commit subject; do echo "$(git rev-parse --short=8 $commit:eval/cases.jsonl) $commit $subject"; done
git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'
git cat-file -p 0928d48c | wc -c
```

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

<!-- snippet: ch03/lab-16-2-delta-chain/05-logical-size -->
```text
# Size of the object as Git presents it, and size of what is stored for it:
$ git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'
a4e58256c921e15fecaaaf744fbdb04b37907a40 16789 1372 0000000000000000000000000000000000000000
739088cda5ca15c1fd59dc40238f8852f7f677de 16788 35 a4e58256c921e15fecaaaf744fbdb04b37907a40
d77675f2a7b00158d41dc879b35011a742015f48 16787 30 739088cda5ca15c1fd59dc40238f8852f7f677de
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 16786 35 d77675f2a7b00158d41dc879b35011a742015f48
782b8e9b7662fd152695234c4ba08fde34c18f73 16785 30 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
0928d48c558a6457e11c9fa47f347fb2a190259f 16784 35 782b8e9b7662fd152695234c4ba08fde34c18f73
$ git cat-file -p 0928d48c | wc -c
   16784
```
<!-- /snippet -->

The whole object is the newest version, the one that `HEAD` names; the oldest version is at the end of the chain. `%(objectsize)` says 16,784 to 16,789 for all six: the delta is a storage form, not a smaller object.

### Failure scenario

One byte inside the base object is damaged. The listing shows that the base starts at offset 961 and occupies 1,372 bytes, so byte 1000 lies inside it. Flip every bit of that byte:

```bash
chmod u+w .git/objects/pack/pack-*.pack
python3 -c "import sys; f = open(sys.argv[1], 'r+b'); f.seek(1000); b = f.read(1); f.seek(1000); f.write(bytes([b[0] ^ 255])); f.close()" .git/objects/pack/pack-*.pack
git verify-pack .git/objects/pack/pack-*.idx
git cat-file -p 0928d48c > /dev/null
git fsck 2>&1 | grep -c "cannot unpack"
git log --oneline -2
git status --short
```

<!-- snippet: ch03/lab-16-2-delta-chain/06-failure -->
```text
# Failure scenario: one damaged byte inside the base object of the chain.
$ chmod u+w .git/objects/pack/pack-*.pack
$ python3 -c "import sys; f = open(sys.argv[1], 'r+b'); f.seek(1000); b = f.read(1); f.seek(1000); f.write(bytes([b[0] ^ 255])); f.close()" .git/objects/pack/pack-*.pack
$ git verify-pack .git/objects/pack/pack-*.idx
error: inflate: data stream error (invalid code -- missing end-of-block)
fatal: pack has bad object at offset 961: inflate returned -3
[exit status: 1]
# Every version of the file depends on that base, so every version is unreadable:
$ git cat-file -p 0928d48c > /dev/null
error: inflate: data stream error (invalid code -- missing end-of-block)
error: failed to read delta base object a4e58256c921e15fecaaaf744fbdb04b37907a40 at offset 961 from .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
error: failed to read delta base object 739088cda5ca15c1fd59dc40238f8852f7f677de at offset 2610 from .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
error: failed to read delta base object d77675f2a7b00158d41dc879b35011a742015f48 at offset 2770 from .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
error: failed to read delta base object d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 at offset 2925 from .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
error: failed to read delta base object 782b8e9b7662fd152695234c4ba08fde34c18f73 at offset 3084 from .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
fatal: packed object 0928d48c558a6457e11c9fa47f347fb2a190259f (stored in .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack) is corrupt
$ git fsck 2>&1 | grep -c "cannot unpack"
6
# Commits and trees are other objects in the pack. They still read, and status notices nothing:
$ git log --oneline -2
14fbba9 Relax case 150 to two sentences
d076308 Relax case 120 to two sentences
$ git status --short
[exit status: 0]
```
<!-- /snippet -->

The damaged bytes are inside the zlib stream of the base, so inflating it fails. Every delta in the chain needs that base, so all six versions of the file are unreadable: one damaged byte, six lost objects. Commits and trees are other entries in the pack and still read, which is why `git log` works. `git status` says nothing because the index tells it that `eval/cases.jsonl` is unchanged, and it never opens the blob. A repository can look healthy to the commands you run every day and be unable to produce a single version of a file.

### Recovery

First preserve the evidence: never repair your only copy. Then use the one fact that makes the repair possible: the damaged object is the newest version of the file, the working tree still holds those bytes, and content alone determines the ID.

```bash
cp -R .git ../eval-harness-damaged.git
git hash-object eval/cases.jsonl
git hash-object -w eval/cases.jsonl
git count-objects
mkdir ../quarantine
mv .git/objects/pack/pack-* ../quarantine/
git hash-object -w eval/cases.jsonl
git count-objects
mv ../quarantine/pack-* .git/objects/pack/
git cat-file -p 0928d48c | wc -l
git gc
```

<!-- snippet: ch03/lab-16-2-delta-chain/07-recovery -->
```text
# Never repair your only copy. Keep the damaged repository as it is, next to the one you work on:
$ cp -R .git ../eval-harness-damaged.git
# The damaged object is the newest version of the file, and the working tree still holds those bytes:
$ git hash-object eval/cases.jsonl
a4e58256c921e15fecaaaf744fbdb04b37907a40
# Git does not write an object that it believes it has. Nothing loose appears:
$ git hash-object -w eval/cases.jsonl
a4e58256c921e15fecaaaf744fbdb04b37907a40
$ git count-objects
0 objects, 0 kilobytes
# So take the pack out of the object database, write the object, and put the pack back:
$ mkdir ../quarantine
$ mv .git/objects/pack/pack-* ../quarantine/
$ git hash-object -w eval/cases.jsonl
a4e58256c921e15fecaaaf744fbdb04b37907a40
$ git count-objects
1 objects, 4 kilobytes
$ mv ../quarantine/pack-* .git/objects/pack/
# Reads now fall back to the loose copy of the base, with a complaint about the packed one:
$ git cat-file -p 0928d48c | wc -l
error: inflate: data stream error (invalid code -- missing end-of-block)
error: failed to read delta base object a4e58256c921e15fecaaaf744fbdb04b37907a40 at offset 961 from .git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
     200
# Now let maintenance rewrite the pack from what is readable:
$ git gc
error: bad packed object CRC for a4e58256c921e15fecaaaf744fbdb04b37907a40
error: bad packed object CRC for a4e58256c921e15fecaaaf744fbdb04b37907a40
[exit status: 0]
```
<!-- /snippet -->

`git hash-object -w` 🟢 prints the ID of the file's content, `a4e58256`, which is the base object: the content is right. But Git does not write an object that its pack index says it already has, so the first `-w` wrote nothing. Moving the pack out of the way makes the object unknown, the second `-w` writes it as a loose object, and the pack goes back. Now a read of any version finds the packed base corrupt, complains, and falls back to the loose copy of the same ID, which is why `0928d48c` reads back with 200 lines again. `git gc` 🟡 then writes a new pack from objects it can read: it notices the bad CRC of the packed copy, takes the loose copy instead, and replaces the damaged pack. The error lines it prints are the damaged entries being skipped.

If you had not had the content in the working tree, the sources would have been, in this order: another clone or the remote (a fresh clone is the simplest complete repair, and copying the intact pack from a healthy clone also works), a backup of the repository, or the same file from any machine that has that version. Any copy with the right ID is the right object.

### Verification

```bash
git verify-pack .git/objects/pack/pack-*.idx
git fsck
git count-objects -v
ls .git/objects/pack
git cat-file -p 0928d48c | wc -l
```

<!-- snippet: ch03/lab-16-2-delta-chain/08-verification -->
```text
$ git verify-pack .git/objects/pack/pack-*.idx
[exit status: 0]
$ git fsck
[exit status: 0]
$ git count-objects -v
count: 0
size: 0
in-pack: 25
packs: 1
size-pack: 4
prune-packable: 0
garbage: 0
size-garbage: 0
$ ls .git/objects/pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
$ git cat-file -p 0928d48c | wc -l
     200
```
<!-- /snippet -->

The pack has the same name as before the damage. A pack is named after the checksum of its content, so the repository is byte for byte what it was before the byte flipped.

### Questions

1. Which object is the base of the chain, which commit's version of the file is it, and why is the newest version stored whole rather than the oldest?
2. The deltas are 17 to 22 bytes for a 16 KB file. What do the instructions in a delta contain, and why does `%(objectsize)` still report about 16,785 bytes for each version?
3. One damaged byte made six objects unreadable, while `git log` and `git status` kept working. Explain both halves.
4. Why did the first `git hash-object -w` write nothing, and why did moving the pack away change that?
5. After the repair, the pack had the same name as before the damage. What does that prove, and what would a different name have meant?
6. In production the damaged object's content is usually not in your working tree. List the other sources in the order you would try them, and name the risk of running `git gc` or `git repack` before the repair.

# Module 1 labs: What Git actually is

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the replay scripts in `labs/ch02/`. Read [Chapter 2](../textbook/ch02-mental-model.md) first; each lab names the sections it relies on.

## How to run these labs

All three labs are typed by hand in the lab shell, each in its own repository created from nothing:

```bash
labs/shell m01        # opens your shell in $LAB/hands-on/m01 with an isolated Git configuration
```

The clock is real in the lab shell, so commits you make get IDs that differ from the book. Blob and tree IDs do not differ: they depend on content alone, which is the point of this module. Lab 1.3 pins the commit dates on the command line, and there even your commit IDs match the book.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command to see its exit status.
- Lines that start with `#` are notes from the replay script.
- Where you type a shell variable such as `$readme`, the replay prints the full ID instead. The commands are otherwise identical.

To see a lab exactly as printed, replay it: `labs/run ch02/lab-01-1-commit-by-hand`. The sandbox stays under `$LAB/ch02/` for inspection. Answers to the questions are in [solutions/m01-lab-answers.md](../solutions/m01-lab-answers.md). Write your own first.

## Lab 1.1: Build a commit by hand

### Objective

Create two commits with plumbing commands only, with the same content as the first repository of Chapter 1, so that your blob and tree IDs come out identical to the ones `git add` and `git commit` produced there. Prove that porcelain builds the same tree. Then lose a third commit on purpose and get it back.

### Prerequisites

Chapter 2, sections 2.2 to 2.8. Lab 0.2.

### Setup

```bash
labs/shell m01
rm -rf handmade porcelain     # only if a previous attempt left them behind
```

### Commands

Step 1. Store two blobs and look at them. Capture each ID in a shell variable, because `--cacheinfo` needs the full 40 digits:

```bash
git init handmade
cd handmade
readme=$(printf '# rag-eval\n' | git hash-object -w --stdin); echo "$readme"
config=$(printf 'model: small-v2\ntimeout_s: 60\n' | git hash-object -w --stdin); echo "$config"
git cat-file -t "$readme"
git cat-file -p "$config"
```

Step 2. Register both blobs in the index, under paths that do not exist in the working tree:

```bash
git update-index --add --cacheinfo 100644,"$readme",README.md
git update-index --add --cacheinfo 100644,"$config",configs/eval.yaml
git ls-files --stage
```

Step 3. Write the tree and read it back, one level and then recursively:

```bash
tree1=$(git write-tree); echo "$tree1"
git cat-file -p "$tree1"
git ls-tree -r "$tree1"
```

Step 4. Create the commit and point the branch at it:

```bash
c1=$(git commit-tree "$tree1" -m 'Add README and evaluation config'); echo "$c1"
git cat-file -p "$c1"
git update-ref refs/heads/main "$c1"
git log --oneline
```

Step 5. A second commit that changes one file. The three-argument form of `git update-ref` states the value you expect the branch to have now:

```bash
config2=$(printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' | git hash-object -w --stdin); echo "$config2"
git update-index --cacheinfo 100644,"$config2",configs/eval.yaml
tree2=$(git write-tree); echo "$tree2"
c2=$(git commit-tree "$tree2" -p "$c1" -m 'Add top_k to evaluation config'); echo "$c2"
git update-ref refs/heads/main "$c2" "$c1"
git log --oneline
git cat-file -p "$c2"
```

Step 6. The working tree is still empty. Fill it from the index:

```bash
git status --short
git restore .
git status
cat configs/eval.yaml
```

### Expected output

<!-- snippet: ch02/lab-01-1-commit-by-hand/01-blobs -->
```text
$ git init handmade
Initialized empty Git repository in $LAB/ch02/lab-01-1-commit-by-hand/handmade/.git/
$ cd handmade
$ printf '# rag-eval\n' | git hash-object -w --stdin
3a79082bc80505c7543e79c4312e3e3d276a0e04
$ printf 'model: small-v2\ntimeout_s: 60\n' | git hash-object -w --stdin
422e9c0c59f64154ed466adcfb7b7b7c0d43e89f
$ git cat-file -t 3a79082bc80505c7543e79c4312e3e3d276a0e04
blob
$ git cat-file -p 422e9c0c59f64154ed466adcfb7b7b7c0d43e89f
model: small-v2
timeout_s: 60
```
<!-- /snippet -->

Your two IDs must be `3a79082b…` and `422e9c0c…`, the IDs that appeared in Chapter 1, section 1.9, step 3, when `git add` stored the same two files.

<!-- snippet: ch02/lab-01-1-commit-by-hand/02-index -->
```text
$ git update-index --add --cacheinfo 100644,3a79082bc80505c7543e79c4312e3e3d276a0e04,README.md
$ git update-index --add --cacheinfo 100644,422e9c0c59f64154ed466adcfb7b7b7c0d43e89f,configs/eval.yaml
$ git ls-files --stage
100644 3a79082bc80505c7543e79c4312e3e3d276a0e04 0	README.md
100644 422e9c0c59f64154ed466adcfb7b7b7c0d43e89f 0	configs/eval.yaml
```
<!-- /snippet -->

<!-- snippet: ch02/lab-01-1-commit-by-hand/03-tree -->
```text
$ git write-tree
e621cb090a7d826cce2a614885f534bde7015533
$ git cat-file -p e621cb090a7d826cce2a614885f534bde7015533
100644 blob 3a79082bc80505c7543e79c4312e3e3d276a0e04	README.md
040000 tree 0d722fc2a87c4b61afef355250e6e77f41a44cd0	configs
$ git ls-tree -r e621cb090a7d826cce2a614885f534bde7015533
100644 blob 3a79082bc80505c7543e79c4312e3e3d276a0e04	README.md
100644 blob 422e9c0c59f64154ed466adcfb7b7b7c0d43e89f	configs/eval.yaml
```
<!-- /snippet -->

The top-level tree is `e621cb09…` and the `configs/` tree is `0d722fc2…`, again the IDs from Chapter 1. Two files in two directories give two trees.

<!-- snippet: ch02/lab-01-1-commit-by-hand/04-commit -->
```text
$ git commit-tree e621cb090a7d826cce2a614885f534bde7015533 -m 'Add README and evaluation config'
d368da94c502aefe8ec66170d98960042ccb4508
$ git cat-file -p d368da94c502aefe8ec66170d98960042ccb4508
tree e621cb090a7d826cce2a614885f534bde7015533
author Lab User <you@example.com> 1788756240 +0530
committer Lab User <you@example.com> 1788756240 +0530

Add README and evaluation config
$ git update-ref refs/heads/main d368da94c502aefe8ec66170d98960042ccb4508
$ git log --oneline
d368da9 Add README and evaluation config
```
<!-- /snippet -->

Your commit ID differs from `d368da9`, because its two timestamps are yours. Its `tree` line must be identical.

<!-- snippet: ch02/lab-01-1-commit-by-hand/05-second-commit -->
```text
$ printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' | git hash-object -w --stdin
327cd0ba552a90dc306910be4a4bf9348b3e2119
$ git update-index --cacheinfo 100644,327cd0ba552a90dc306910be4a4bf9348b3e2119,configs/eval.yaml
$ git write-tree
aec64f76cfa3e796dd5da8e3e1a64bdf9e4ded5a
$ git commit-tree aec64f76cfa3e796dd5da8e3e1a64bdf9e4ded5a -p d368da94c502aefe8ec66170d98960042ccb4508 -m 'Add top_k to evaluation config'
c5fe1bf78b3d002d16cf74efefbb714b3c081091
$ git update-ref refs/heads/main c5fe1bf78b3d002d16cf74efefbb714b3c081091 d368da94c502aefe8ec66170d98960042ccb4508
$ git log --oneline
c5fe1bf Add top_k to evaluation config
d368da9 Add README and evaluation config
$ git cat-file -p c5fe1bf78b3d002d16cf74efefbb714b3c081091
tree aec64f76cfa3e796dd5da8e3e1a64bdf9e4ded5a
parent d368da94c502aefe8ec66170d98960042ccb4508
author Lab User <you@example.com> 1788756660 +0530
committer Lab User <you@example.com> 1788756660 +0530

Add top_k to evaluation config
```
<!-- /snippet -->

Blob `327cd0ba…` and tree `aec64f76…` must match. The `parent` line of your second commit names your first commit, so it differs from `d368da9`.

<!-- snippet: ch02/lab-01-1-commit-by-hand/06-working-tree -->
```text
$ git status --short
 D README.md
 D configs/eval.yaml
$ git restore .
$ git status
On branch main
nothing to commit, working tree clean
$ cat configs/eval.yaml
model: small-v2
timeout_s: 60
top_k: 5
```
<!-- /snippet -->

### What happened internally

| Command | Objects written | Index | Refs and reflogs |
|---|---|---|---|
| `git hash-object -w --stdin` 🟢 | One blob per distinct content | unchanged | unchanged |
| `git update-index --add --cacheinfo` 🟡 | none | One entry: mode, blob ID, stage 0, path | unchanged |
| `git write-tree` 🟢 | One tree per directory that has no object yet | unchanged | unchanged |
| `git commit-tree` 🟢 | One commit | unchanged | unchanged: no ref moves, no reflog line |
| `git update-ref refs/heads/main <new> [<old>]` 🟡 | none | unchanged | The branch is created or moved; a reflog line is written for it and for HEAD, with no message |
| `git restore .` 🔴 | none | unchanged | unchanged; the working tree is written from the index |

Before step 6, `git status --short` showed ` D` for both files: the index and the commit had them, the working tree did not. `git restore <path>` takes the index as its source, so it created the files. On files with uncommitted edits the same command would overwrite them, which is why it carries the red label everywhere in this book.

### Checkpoint

The two commits were built by hand. Build the same final content with porcelain in a second repository and compare the tree IDs:

```bash
git init -q ../porcelain
mkdir ../porcelain/configs
printf '# rag-eval\n' > ../porcelain/README.md
printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' > ../porcelain/configs/eval.yaml
git -C ../porcelain add .
git -C ../porcelain commit -q -m "Add README and evaluation config with top_k"
git -C ../porcelain rev-parse 'HEAD^{tree}'
git rev-parse 'main^{tree}'
```

<!-- snippet: ch02/lab-01-1-commit-by-hand/07-checkpoint -->
```text
# Checkpoint: the same two files through git add and git commit, in a second repository.
$ git init -q ../porcelain
$ mkdir ../porcelain/configs
$ printf '# rag-eval\n' > ../porcelain/README.md
$ printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' > ../porcelain/configs/eval.yaml
$ git -C ../porcelain add .
$ git -C ../porcelain commit -q -m "Add README and evaluation config with top_k"
$ git -C ../porcelain rev-parse 'HEAD^{tree}'
aec64f76cfa3e796dd5da8e3e1a64bdf9e4ded5a
$ git rev-parse 'main^{tree}'
aec64f76cfa3e796dd5da8e3e1a64bdf9e4ded5a
```
<!-- /snippet -->

Both print `aec64f76…`. `git add` and `git commit` wrote the same blobs and the same trees that you wrote by hand; the only differences between the two repositories are inside the commit objects.

### Failure scenario

Make a third commit and forget the last step, as a script with a missing line would:

```bash
printf '# rag-eval\n\nEvaluation harness for the retrieval service.\n' > README.md
readme2=$(git hash-object -w README.md); echo "$readme2"
git update-index --cacheinfo 100644,"$readme2",README.md
tree3=$(git write-tree); echo "$tree3"
c3=$(git commit-tree "$tree3" -p "$c2" -m 'Describe the project in the README'); echo "$c3"
git log --oneline
git status
```

<!-- snippet: ch02/lab-01-1-commit-by-hand/08-lost-commit -->
```text
# Failure scenario: make a third commit and forget to move the branch.
$ printf '# rag-eval\n\nEvaluation harness for the retrieval service.\n' > README.md
$ git hash-object -w README.md
ac78bd577b1c12782be9a0f3dab8824df1ea7e0e
$ git update-index --cacheinfo 100644,ac78bd577b1c12782be9a0f3dab8824df1ea7e0e,README.md
$ git write-tree
5eead415d1cacc496dfcf7125a0150ca543ca38d
$ git commit-tree 5eead415d1cacc496dfcf7125a0150ca543ca38d -p c5fe1bf78b3d002d16cf74efefbb714b3c081091 -m 'Describe the project in the README'
7395c60cdf34fc8b7a88413232638a50ae124897
$ git log --oneline
c5fe1bf Add top_k to evaluation config
d368da9 Add README and evaluation config
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md
```
<!-- /snippet -->

`git log` shows two commits, and `git status` reports the README as staged and not committed. The commit exists, but no ref leads to it. Pretend that you cleared the terminal and no longer have the ID:

```bash
git fsck
git cat-file -p <the dangling commit>
```

<!-- snippet: ch02/lab-01-1-commit-by-hand/09-find-it -->
```text
$ git fsck
dangling commit 7395c60cdf34fc8b7a88413232638a50ae124897
$ git cat-file -p 7395c60cdf34fc8b7a88413232638a50ae124897
tree 5eead415d1cacc496dfcf7125a0150ca543ca38d
parent c5fe1bf78b3d002d16cf74efefbb714b3c081091
author Lab User <you@example.com> 1788757860 +0530
committer Lab User <you@example.com> 1788757860 +0530

Describe the project in the README
```
<!-- /snippet -->

Before the repair, try three mistakes that Git refuses, so that you know what the guard rails look like:

```bash
git update-index --cacheinfo 100644,"$readme",docs/intro.md; echo $?
git update-ref refs/heads/main "$readme"; echo $?
git update-ref refs/heads/main "$c3" "$c1"; echo $?
```

<!-- snippet: ch02/lab-01-1-commit-by-hand/10-refused -->
```text
# Three more mistakes. Git refuses each of them, and nothing changes.
$ git update-index --cacheinfo 100644,3a79082bc80505c7543e79c4312e3e3d276a0e04,docs/intro.md
error: docs/intro.md: cannot add to the index - missing --add option?
fatal: git update-index: --cacheinfo cannot add docs/intro.md
[exit status: 128]
$ git update-ref refs/heads/main 3a79082bc80505c7543e79c4312e3e3d276a0e04
fatal: update_ref failed for ref 'refs/heads/main': trying to write non-commit object 3a79082bc80505c7543e79c4312e3e3d276a0e04 to branch 'refs/heads/main'
[exit status: 128]
$ git update-ref refs/heads/main 7395c60cdf34fc8b7a88413232638a50ae124897 d368da94c502aefe8ec66170d98960042ccb4508
fatal: update_ref failed for ref 'refs/heads/main': cannot lock ref 'refs/heads/main': is at c5fe1bf78b3d002d16cf74efefbb714b3c081091 but expected d368da94c502aefe8ec66170d98960042ccb4508
[exit status: 128]
```
<!-- /snippet -->

### Recovery

Move the branch to the found commit, and state the value you expect it to have now. `-m` records a reason in the reflog:

```bash
git update-ref -m 'by hand: describe the project' refs/heads/main "$c3" "$c2"
```

<!-- snippet: ch02/lab-01-1-commit-by-hand/11-recover -->
```text
# Recovery: move the branch, and state the value you expect it to have now.
$ git update-ref -m 'by hand: describe the project' refs/heads/main 7395c60cdf34fc8b7a88413232638a50ae124897 c5fe1bf78b3d002d16cf74efefbb714b3c081091
```
<!-- /snippet -->

### Verification

```bash
git log --oneline
git fsck
git status
git reflog show main
```

<!-- snippet: ch02/lab-01-1-commit-by-hand/12-verify -->
```text
$ git log --oneline
7395c60 Describe the project in the README
c5fe1bf Add top_k to evaluation config
d368da9 Add README and evaluation config
$ git fsck
$ git status
On branch main
nothing to commit, working tree clean
$ git reflog show main
7395c60 main@{0}: by hand: describe the project
c5fe1bf main@{1}: 
d368da9 main@{2}: 
```
<!-- /snippet -->

Three commits, nothing dangling, a clean working tree, and a reflog of `main` with three entries. Only the last one has a message, because only the last `git update-ref` was given one.

### Questions

1. Your blob and tree IDs equal the book's and your commit IDs do not. List every input to a commit ID and mark the ones that differed for your first commit and for your second.
2. After `git update-index --add --cacheinfo`, `git status` said "deleted" for a file that you never deleted. Which two comparisons does `git status` make, and which one produced that line?
3. `git write-tree` produced two trees for two files. What decides how many tree objects a commit writes?
4. `git fsck` found the lost commit, but `git log` never would have. Why? In a porcelain workflow, which other record would have found it?
5. The third refused command said that `main` "is at c5fe1bf… but expected d368da9…". What protection is that, and what would have happened without the third argument?
6. The reflog of `main` shows two entries without a message and one with. Why, and what does that tell you about porcelain?

## Lab 1.2: Snapshots share unchanged blobs

### Objective

Prove that three snapshots of a four-file project share every unchanged blob and every unchanged subtree, and that a snapshot which returns to an earlier content reuses the earlier tree outright. Then delete a shared object and rebuild it from content.

### Prerequisites

Chapter 2, sections 2.3 to 2.5.

### Setup

```bash
labs/shell m01
rm -rf promptlib     # only if a previous attempt left one behind
```

### Commands

Step 1. Four files in three directories, one commit, and a recursive tree listing that includes the subtrees:

```bash
git init promptlib
cd promptlib
mkdir prompts eval
printf '# promptlib\n' > README.md
printf 'Answer only from the provided context.\n' > prompts/system.txt
printf 'Reply with PASS or FAIL.\n' > prompts/judge.txt
printf 'def exact_match(pred, gold):\n    return pred == gold\n' > eval/metrics.py
git add .
git commit -q -m "Add prompts and metrics"
git ls-tree -r -t HEAD
```

Step 2. Count the objects by type:

```bash
git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
```

Step 3. Change one file, commit, and list and count again. Predict the three numbers before you run the last command:

```bash
printf 'Reply with PASS or FAIL, then one sentence of reasoning.\n' > prompts/judge.txt
git commit -q -am "Ask the judge for its reasoning"
git ls-tree -r -t HEAD
git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
```

### Expected output

<!-- snippet: ch02/lab-01-2-shared-blobs/01-first-commit -->
```text
$ git init promptlib
Initialized empty Git repository in $LAB/ch02/lab-01-2-shared-blobs/promptlib/.git/
$ cd promptlib
$ mkdir prompts eval
$ printf '# promptlib\n' > README.md
$ printf 'Answer only from the provided context.\n' > prompts/system.txt
$ printf 'Reply with PASS or FAIL.\n' > prompts/judge.txt
$ printf 'def exact_match(pred, gold):\n    return pred == gold\n' > eval/metrics.py
$ git add .
$ git commit -q -m "Add prompts and metrics"
$ git ls-tree -r -t HEAD
100644 blob 4718105e278b99388b9be1f12ce7553ffc6b4a91	README.md
040000 tree 56ebe9f6b6d55e8a2b88d71b70f904767611bc3f	eval
100644 blob a82fda10838664b875761f47c08c0175acbb4f1f	eval/metrics.py
040000 tree fe35fd80775cf9edadd28c9bb2607c77f8482271	prompts
100644 blob 7be668dbbdbae780d8fad9e61bb621057e69a929	prompts/judge.txt
100644 blob a7f6bbccac4db25937e64faa9292a454e408d871	prompts/system.txt
```
<!-- /snippet -->

`-t` makes `git ls-tree -r` print the subtrees as well as the files, so you see all three trees: the top level, `eval` and `prompts`.

<!-- snippet: ch02/lab-01-2-shared-blobs/02-count -->
```text
$ git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
   4 blob
   1 commit
   3 tree
```
<!-- /snippet -->

<!-- snippet: ch02/lab-01-2-shared-blobs/03-second-commit -->
```text
$ printf 'Reply with PASS or FAIL, then one sentence of reasoning.\n' > prompts/judge.txt
$ git commit -q -am "Ask the judge for its reasoning"
$ git ls-tree -r -t HEAD
100644 blob 4718105e278b99388b9be1f12ce7553ffc6b4a91	README.md
040000 tree 56ebe9f6b6d55e8a2b88d71b70f904767611bc3f	eval
100644 blob a82fda10838664b875761f47c08c0175acbb4f1f	eval/metrics.py
040000 tree 211d835222b7814a47d2186cb8376feefaed1a1d	prompts
100644 blob f82755024e8bd1d33196967556ee615ca7efb7a8	prompts/judge.txt
100644 blob a7f6bbccac4db25937e64faa9292a454e408d871	prompts/system.txt
$ git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
   5 blob
   2 commit
   5 tree
```
<!-- /snippet -->

### What happened internally

The first commit wrote eight objects: four blobs, three trees, one commit. The second wrote four: a blob for the new `prompts/judge.txt`, a tree for `prompts/` because one of its entries changed, a top-level tree because the `prompts` entry changed, and the commit. Everything else kept its ID. `README.md`, `eval/metrics.py` and the whole `eval` tree cost nothing, and they are not copied: both commits refer to the same objects.

### Checkpoint

Ask Git which tree entries changed between the two commits, and confirm that the `eval` subtree is the same object in both:

```bash
git diff-tree -t --abbrev HEAD~1 HEAD
git rev-parse HEAD~1:eval HEAD:eval
```

<!-- snippet: ch02/lab-01-2-shared-blobs/04-what-changed -->
```text
$ git diff-tree -t --abbrev HEAD~1 HEAD
:040000 040000 fe35fd8 211d835 M	prompts
:100644 100644 7be668d f827550 M	prompts/judge.txt
$ git rev-parse HEAD~1:eval HEAD:eval
56ebe9f6b6d55e8a2b88d71b70f904767611bc3f
56ebe9f6b6d55e8a2b88d71b70f904767611bc3f
```
<!-- /snippet -->

Now go back to the short prompt. Predict the object counts, then check them and compare the tree IDs of the first and the third commit:

```bash
printf 'Reply with PASS or FAIL.\n' > prompts/judge.txt
git commit -q -am "Go back to the short judge prompt"
git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
git rev-parse 'HEAD~2^{tree}' 'HEAD^{tree}'
git log --oneline
```

<!-- snippet: ch02/lab-01-2-shared-blobs/05-third-commit -->
```text
$ printf 'Reply with PASS or FAIL.\n' > prompts/judge.txt
$ git commit -q -am "Go back to the short judge prompt"
$ git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
   5 blob
   3 commit
   5 tree
$ git rev-parse 'HEAD~2^{tree}' 'HEAD^{tree}'
ee4037ef48c13f9c4a6521c72ebfc17c85446c5a
ee4037ef48c13f9c4a6521c72ebfc17c85446c5a
$ git log --oneline
19c28d0 Go back to the short judge prompt
1011528 Ask the judge for its reasoning
3d31c04 Add prompts and metrics
```
<!-- /snippet -->

The third commit added exactly one object, the commit itself. Its tree is the tree of the first commit, `ee4037ef…`, because every blob and every subtree already existed. Two commits with the same tree are the strongest statement Git can make that two project states are identical; after a rollback in production, this comparison is the proof.

### Failure scenario

Delete the loose object that holds `prompts/system.txt`, which all three snapshots share. Then see what still works and what does not:

```bash
git rev-parse HEAD:prompts/system.txt
rm -f .git/objects/a7/f6bbccac4db25937e64faa9292a454e408d871
git status
git show HEAD~2:prompts/system.txt; echo $?
git fsck; echo $?
```

<!-- snippet: ch02/lab-01-2-shared-blobs/06-break -->
```text
# Failure scenario: delete one loose object that all three snapshots share.
$ git rev-parse HEAD:prompts/system.txt
a7f6bbccac4db25937e64faa9292a454e408d871
$ rm -f .git/objects/a7/f6bbccac4db25937e64faa9292a454e408d871
$ git status
On branch main
nothing to commit, working tree clean
$ git show HEAD~2:prompts/system.txt
fatal: bad object HEAD~2:prompts/system.txt
[exit status: 128]
$ git fsck
missing blob a7f6bbccac4db25937e64faa9292a454e408d871
[exit status: 2]
```
<!-- /snippet -->

`git status` noticed nothing, because it compares IDs and cached file information and never had to read the blob. Reading the file from any commit fails, and `git fsck` names the missing object with exit status 2.

### Recovery

Find out which path had that ID, and whether the file on disk still hashes to it. Only then write the object back:

```bash
git ls-tree -r HEAD | grep a7f6bbc
git hash-object prompts/system.txt
git hash-object -w prompts/system.txt
```

<!-- snippet: ch02/lab-01-2-shared-blobs/07-repair -->
```text
# Recovery: which path had that ID, and does the file on disk still hash to it?
$ git ls-tree -r HEAD | grep a7f6bbc
100644 blob a7f6bbccac4db25937e64faa9292a454e408d871	prompts/system.txt
$ git hash-object prompts/system.txt
a7f6bbccac4db25937e64faa9292a454e408d871
# Same ID, so the same bytes. Write the object back.
$ git hash-object -w prompts/system.txt
a7f6bbccac4db25937e64faa9292a454e408d871
```
<!-- /snippet -->

The repair works because an object is nothing but its content: the same bytes produce the same ID, so the rebuilt object is indistinguishable from the deleted one. In a real repository the same content usually comes from another clone (Chapter 13: Recovery).

### Verification

```bash
git show HEAD~2:prompts/system.txt
git fsck; echo $?
git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
```

<!-- snippet: ch02/lab-01-2-shared-blobs/08-verify -->
```text
$ git show HEAD~2:prompts/system.txt
Answer only from the provided context.
$ git fsck
[exit status: 0]
$ git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c
   5 blob
   3 commit
   5 tree
```
<!-- /snippet -->

### Questions

1. After the second commit the counts were 5 blobs, 2 commits and 5 trees. Account for every object the second commit added, and explain why `README.md` and `eval/metrics.py` cost nothing.
2. The third commit added one object. Which one, and how do you prove that its tree is the first commit's tree?
3. After you deleted the blob, `git status` still reported a clean working tree. Why did it not notice?
4. Which two commands told you what was missing and which path needed it? What would you do if no file on disk had the content?
5. Would `git add prompts/system.txt` have repaired the object as well? What makes restoring it from a colleague's clone possible?

## Lab 1.3: Same content, same ID, in two repositories

### Objective

Show that blobs, trees and, when every input is fixed, even commits get identical IDs in two independent repositories; that one second changes a commit ID and leaves the tree ID alone; and that one invisible byte breaks the equality of two files that look identical.

### Prerequisites

Chapter 2, section 2.4.

### Setup

```bash
labs/shell m01
rm -rf laptop server ci export     # only if a previous attempt left them behind
```

### Commands

Step 1. Two repositories, two identical files, two index entries:

```bash
git init -q laptop
git init -q server
printf 'temperature: 0.2\n' > laptop/eval.yaml
printf 'temperature: 0.2\n' > server/eval.yaml
git -C laptop add eval.yaml
git -C server add eval.yaml
git -C laptop ls-files --stage
git -C server ls-files --stage
```

Step 2. Two trees:

```bash
git -C laptop write-tree
git -C server write-tree
```

Step 3. Two commits with every input pinned. The dates are given on the command line, and the identity comes from the lab shell's configuration, so your commit IDs equal the book's:

```bash
when='2026-09-07T12:00:00+05:30'
GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C laptop commit -q -m "Add eval settings"
GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C server commit -q -m "Add eval settings"
git -C laptop rev-parse HEAD
git -C server rev-parse HEAD
git -C laptop cat-file -p HEAD
```

### Expected output

<!-- snippet: ch02/lab-01-3-same-content-same-id/01-blobs -->
```text
$ git init -q laptop
$ git init -q server
$ printf 'temperature: 0.2\n' > laptop/eval.yaml
$ printf 'temperature: 0.2\n' > server/eval.yaml
$ git -C laptop add eval.yaml
$ git -C server add eval.yaml
$ git -C laptop ls-files --stage
100644 b5fee68e16090ca243c174fd28853ad0abe8b77a 0	eval.yaml
$ git -C server ls-files --stage
100644 b5fee68e16090ca243c174fd28853ad0abe8b77a 0	eval.yaml
```
<!-- /snippet -->

<!-- snippet: ch02/lab-01-3-same-content-same-id/02-trees -->
```text
$ git -C laptop write-tree
097da7ea458de812ac723fb7085d40be43fdae05
$ git -C server write-tree
097da7ea458de812ac723fb7085d40be43fdae05
```
<!-- /snippet -->

<!-- snippet: ch02/lab-01-3-same-content-same-id/03-commits -->
```text
$ when='2026-09-07T12:00:00+05:30'
$ GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C laptop commit -q -m "Add eval settings"
$ GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C server commit -q -m "Add eval settings"
$ git -C laptop rev-parse HEAD
95eaa9c6e56accd4ec06d5494699718d2e4d609c
$ git -C server rev-parse HEAD
95eaa9c6e56accd4ec06d5494699718d2e4d609c
$ git -C laptop cat-file -p HEAD
tree 097da7ea458de812ac723fb7085d40be43fdae05
author Lab User <you@example.com> 1788762600 +0530
committer Lab User <you@example.com> 1788762600 +0530

Add eval settings
```
<!-- /snippet -->

Both commit IDs are `95eaa9c6…`, in the book and on your machine. `git cat-file -p` shows why: the tree, the two identities, the two pinned times and the message are the same bytes in both repositories, and a commit ID is the hash of those bytes.

### What happened internally

Nothing was exchanged between `laptop` and `server`. Each repository hashed its own bytes: the blob from the file content, the tree from the entry `100644`, `eval.yaml` and the blob ID, the commit from the tree ID, the identities, the dates and the message. Identical inputs, identical hashes. The lab shell's `user.name` and `user.email` are inputs too, which is why the manual asked you to use it.

### Checkpoint

A third repository commits the same content one second later:

```bash
git init -q ci
printf 'temperature: 0.2\n' > ci/eval.yaml
git -C ci add eval.yaml
when='2026-09-07T12:00:01+05:30'
GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C ci commit -q -m "Add eval settings"
git -C ci rev-parse HEAD 'HEAD^{tree}'
git -C laptop rev-parse HEAD 'HEAD^{tree}'
```

<!-- snippet: ch02/lab-01-3-same-content-same-id/04-one-second-later -->
```text
$ git init -q ci
$ printf 'temperature: 0.2\n' > ci/eval.yaml
$ git -C ci add eval.yaml
$ when='2026-09-07T12:00:01+05:30'
$ GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C ci commit -q -m "Add eval settings"
$ git -C ci rev-parse HEAD 'HEAD^{tree}'
4fd1085b9558d7892a6ffba6373b7fdfbe02af98
097da7ea458de812ac723fb7085d40be43fdae05
$ git -C laptop rev-parse HEAD 'HEAD^{tree}'
95eaa9c6e56accd4ec06d5494699718d2e4d609c
097da7ea458de812ac723fb7085d40be43fdae05
```
<!-- /snippet -->

The commit IDs differ, `4fd1085b…` against `95eaa9c6…`, and the tree IDs are both `097da7ea…`. Whenever two commits have the same tree, their file contents are identical, whatever their IDs, dates or messages say.

### Failure scenario

A copy of the file arrives from another tool. It looks identical and hashes differently:

```bash
mkdir export
printf 'temperature: 0.2\r\n' > export/eval.yaml
git hash-object export/eval.yaml
git hash-object laptop/eval.yaml
```

<!-- snippet: ch02/lab-01-3-same-content-same-id/05-invisible-byte -->
```text
# Failure scenario: a file that looks the same and hashes differently.
$ mkdir export
$ printf 'temperature: 0.2\r\n' > export/eval.yaml
$ git hash-object export/eval.yaml
01b0246d15968030a9ea17ebf0430711413c9c0f
$ git hash-object laptop/eval.yaml
b5fee68e16090ca243c174fd28853ad0abe8b77a
```
<!-- /snippet -->

Diagnose it with tools that show bytes rather than text:

```bash
cmp export/eval.yaml laptop/eval.yaml; echo $?
od -c export/eval.yaml
od -c laptop/eval.yaml
```

<!-- snippet: ch02/lab-01-3-same-content-same-id/06-diagnose -->
```text
$ cmp export/eval.yaml laptop/eval.yaml
export/eval.yaml laptop/eval.yaml differ: char 17, line 1
[exit status: 1]
$ od -c export/eval.yaml
0000000    t   e   m   p   e   r   a   t   u   r   e   :       0   .   2
0000020   \r  \n                                                        
0000022
$ od -c laptop/eval.yaml
0000000    t   e   m   p   e   r   a   t   u   r   e   :       0   .   2
0000020   \n                                                            
0000021
```
<!-- /snippet -->

The seventeenth byte is `\r`, a carriage return before the newline: the file has Windows line endings. Git hashes bytes, not what a text editor displays.

### Recovery

Remove the carriage return:

```bash
tr -d '\r' < export/eval.yaml > export/eval.yaml.lf
mv export/eval.yaml.lf export/eval.yaml
```

<!-- snippet: ch02/lab-01-3-same-content-same-id/07-repair -->
```text
# Recovery: remove the carriage return.
$ tr -d '\r' < export/eval.yaml > export/eval.yaml.lf
$ mv export/eval.yaml.lf export/eval.yaml
```
<!-- /snippet -->

### Verification

```bash
git hash-object export/eval.yaml
cmp export/eval.yaml laptop/eval.yaml; echo $?
```

<!-- snippet: ch02/lab-01-3-same-content-same-id/08-verify -->
```text
$ git hash-object export/eval.yaml
b5fee68e16090ca243c174fd28853ad0abe8b77a
$ cmp export/eval.yaml laptop/eval.yaml
[exit status: 0]
```
<!-- /snippet -->

The ID is `b5fee68e…` again, and `cmp` is silent with exit status 0. For a whole team, line endings are normalized by rule rather than by hand ([Chapter 4](../textbook/ch04-working-tree.md), section 4.13).

### Questions

1. Your commit ID equals the book's. List every input that had to be identical, and name the one that the lab shell supplied without you typing it.
2. The `ci` repository committed one second later. Which fields of its commit object differ from the `laptop` commit, and why does the tree ID not differ?
3. `cmp` reported a difference at byte 17. What is that byte, where does it come from in practice, and why does Git not see through it?
4. Which commands in this lab needed a repository, and which did not? What does that tell you about where an ID is computed?
5. Name two invisible differences other than a carriage return that would change a blob ID, and the mechanism that normalizes line endings for a whole team.

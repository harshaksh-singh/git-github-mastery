# Gate 5: Internals

> **Baseline.** Git 2.55.0 on macOS, default `files` ref format and SHA-1 object format. Every transcript in this file is real output of `labs/gates/g5-predict.sh`. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 18. **Covers** the object database, packfiles, the index format, ref storage, and transfer and scale: Chapters [3](../textbook/ch03-git-internals.md), [26](../textbook/ch26-performance.md) and [24](../textbook/ch24-monorepos.md).

**Pass rule.** 85 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 50 minutes, lab shell |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences. Every answer must name the files under `.git` that are involved and say whether each holds primary data or data that can be derived again.

### C1 (5 points)

Describe the loose object format exactly: what bytes are hashed, what bytes are written to disk, and how the file path follows from the hash. From that, explain three consequences: why the same file content always gets the same ID in every repository, why you cannot find an object by searching `.git/objects` for a string it contains, and at which moments Git verifies that the content of an object still matches its name.

### C2 (5 points)

What is in a packfile, and what is in the `.idx` file beside it? Explain delta compression: against which objects a delta is made, which version of a frequently edited file is usually stored whole, and why none of this contradicts the statement "a commit is a snapshot". A disk-cleaning tool deletes all `.idx` files. What is lost, and what is the repair?

### C3 (5 points)

List what one index entry records. Explain how the index lets `git status` decide that a file is unchanged without reading the file, and what Git does when that shortcut is inconclusive. The index file is deleted. What exactly can be rebuilt and from what, with which command, and what cannot be rebuilt?

### C4 (5 points)

In the default ref format a branch can be stored in two places. Name them, say which one wins when both exist, and describe when Git moves refs from one to the other. A release script that reads `.git/refs/heads/main` worked for a year and now stamps builds with a commit from last week, or fails. Explain both failures and give the one command the script should use. Then say in two sentences what reftable changes and what it does not.

### C5 (5 points)

Compare a shallow clone, a blobless partial clone and a full clone: what each has locally after the clone, what marks the clone as that kind in `.git`, and which everyday commands behave differently in each (name at least two per kind). Which would you choose for a CI job that builds and tags a version from `git describe`, and which for a developer's laptop in a repository with ten years of history, and why?

### C6 (5 points)

A repository has grown slow. For each of these files or features, say which data it indexes or summarizes, which commands it speeds up, and whether deleting it loses information: the commit-graph, the multi-pack-index, a reachability bitmap, a cruft pack. Then explain why regular maintenance in a large repository uses geometric repacking instead of repacking everything, and what changed about automatic maintenance in Git 2.54.

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect, as literally as you can, and one sentence of mechanism for each prediction. Where an object ID would appear and is not given, write `<id>` and say which object it names.

### P1 (5 points)

<!-- snippet: gates/g5-predict/p1-setup -->
```text
$ git init -q objdb
$ cd objdb
$ printf 'top_k: 5\n' > a.yaml
$ cp a.yaml b.yaml
$ git hash-object -w a.yaml
1380a9de8d8f7c7cb7da1739d9dfc9c7539b9fe6
$ git hash-object -w b.yaml
1380a9de8d8f7c7cb7da1739d9dfc9c7539b9fe6
```
<!-- /snippet -->

Predict:

1. The output of `find .git/objects -type f`: how many files, and the path of each.
2. The output of `git cat-file -t` and of `git cat-file -s` for that ID.
3. The bytes of the object file after decompression, written out with `\0` for a NUL byte.
4. The output of `git status --short`, and the kind of line `git fsck` prints for the object.

### P2 (5 points)

<!-- snippet: gates/g5-predict/p2-setup -->
```text
$ git init -q packing
$ cd packing
$ printf 'epochs: 1\n' > train.yaml && git add . && git commit -q -m 'One epoch'
$ printf 'epochs: 2\n' > train.yaml && git commit -q -am 'Two epochs'
$ printf 'epochs: 3\n' > train.yaml && git commit -q -am 'Three epochs'
$ git tag v1
```
<!-- /snippet -->

Predict:

1. The values of `count`, `in-pack` and `packs` in `git count-objects -v`, and the files that `find .git/refs -type f` lists.

Then `git gc -q` runs. Predict:

2. The same three values, and the same file listing.
3. How many non-empty lines `.git/packed-refs` has, and what each line holds.

Then one more commit is made:

<!-- snippet: gates/g5-predict/p2-setup-c -->
```text
$ printf 'epochs: 4\n' > train.yaml && git commit -q -am 'Four epochs'
```
<!-- /snippet -->

Predict:

4. The three values, the file listing, and whether `.git/packed-refs` contains the ID that `main` now names.

### P3 (5 points)

<!-- snippet: gates/g5-predict/p3-setup -->
```text
$ git init -q idx
$ cd idx
$ mkdir -p tools conf
$ printf '#!/bin/sh\necho ok\n' > tools/run.sh && chmod +x tools/run.sh
$ printf 'a: 1\n' > conf/base.yaml
$ ln -s conf/base.yaml current.yaml
$ printf 'draft\n' > NOTES.md
$ git add tools conf current.yaml
$ git add -N NOTES.md
```
<!-- /snippet -->

Predict:

1. The output of `git ls-files -s`, reduced to mode, stage and path: four lines, in the order Git prints them.
2. The object ID in the entry of `NOTES.md`. It is a well-known one; name what it is.
3. The output of `git status --short`, with the exact two status characters of every line.
4. The entries of the tree that `git write-tree` would write from this index: mode, type and name of each.

### P4 (5 points)

<!-- snippet: gates/g5-predict/p4-setup -->
```text
# server.git has three commits on main. Each commit changed model.yaml; README.md was
# added in the first commit and never changed.
$ git -C seed log --oneline --stat --format="%s" | grep -v "^$" | grep -v changed
Lower learning rate again
 model.yaml | 2 +-
Lower learning rate
 model.yaml | 2 +-
Add model
 README.md  | 1 +
 model.yaml | 1 +
$ git clone -q --filter=blob:none file://$PWD/server.git partial
$ cd partial
```
<!-- /snippet -->

`git rev-list --objects --missing=print HEAD | grep -c '^?'` counts the objects reachable from `HEAD` that are not in the local object database. Predict:

1. The output of `git rev-list --count HEAD`, and the count of missing objects directly after the clone.
2. How many commits, trees and blobs the local object database holds directly after the clone.
3. The count of missing objects after `git show HEAD~1:model.yaml`.
4. Whether `git log --oneline -- model.yaml` changes that count, and whether `git log -p -- model.yaml` does. Give the count after each.

---

## Part 3: Hands-on diagnosis (30 points)

One generated sandbox with a damaged clone. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| Build it | `assessments/gen/gate-5-internals/variant-a/generate.sh` | `assessments/gen/gate-5-internals/variant-b/generate.sh` |
| What was reported | [`variant-a/SYMPTOMS.md`](gen/gate-5-internals/variant-a/SYMPTOMS.md) | [`variant-b/SYMPTOMS.md`](gen/gate-5-internals/variant-b/SYMPTOMS.md) |
| Check the end state | `assessments/gen/gate-5-internals/variant-a/check.sh` | `assessments/gen/gate-5-internals/variant-b/check.sh` |

Run the generator from the course root, open the lab shell at the path it prints, and read `SYMPTOMS.md`. Do not read `generate.sh` or `check.sh`. Keep a log of every command you type; the log is graded.

In this part, and only in this part, you may remove or write individual files under `.git` by hand where no Git command can do the repair. Each such step must be preceded in your log by the command that proved what the file was.

| Graded on | Points | What earns them |
|---|---|---|
| End state | 12 | `check.sh` ends with `PASS`. One point is lost for each failed line, down to zero |
| Safety of the path | 8 | Faults separated before any repair; each file under `.git` inspected before it is removed or rewritten; derived data regenerated and primary data never discarded; no re-clone; `git gc` and `git prune` not run before `git fsck` is clean |
| Explanation | 10 | For each fault: the files involved, primary or derived, the mechanism, and why the repair is sufficient; the order of repairs justified; the observation that is not damage identified |

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each, without a terminal. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

How does Git store data? *Follow-up:* what are a blob, a tree and a commit, and which of them knows a file's name?

### O2 (3 points)

What is reachability? *Follow-up:* what does `git fsck` start from, and what is the difference between a missing object and a dangling one?

### O3 (3 points)

What is garbage collection in Git, and what does it never delete? *Follow-up:* a colleague wants to run `git gc --prune=now` "to fix a corrupted repository". What do you say?

### O4 (3 points)

What happens between client and server during `git fetch`? *Follow-up:* an object in your clone is corrupt. Why does `git fetch` not repair it?

### O5 (4 points)

A script in your release pipeline calls `git rev-parse "$BRANCH"` and stores the output as the commit to deploy. One day it deployed the literal text of a branch name that did not exist. Explain, and fix the line. *Follow-up:* the same script reads the current branch with `cat .git/HEAD`. What breaks, and where?

### O6 (4 points)

Your monorepo has 300,000 files and `git status` takes eight seconds. Walk me through what Git is doing in those seconds and which features reduce each part. *Follow-up:* a developer turns on a sparse checkout and a search script reports that most of the repository is gone. Explain.

---

## Score sheet

| Item | Max | Score | | Item | Max | Score |
|---|---|---|---|---|---|---|
| C1 | 5 | | | P1 | 5 | |
| C2 | 5 | | | P2 | 5 | |
| C3 | 5 | | | P3 | 5 | |
| C4 | 5 | | | P4 | 5 | |
| C5 | 5 | | | **Prediction** | **20** | |
| C6 | 5 | | | H end state | 12 | |
| **Concepts** | **30** | | | H safety | 8 | |
| O1 to O4 | 12 | | | H explanation | 10 | |
| O5, O6 | 8 | | | **Hands-on** | **30** | |
| **Oral** | **20** | | | **Total** | **100** | |

Pass: total 85 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, redo the labs of that module, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 3, sections 3.3 and 3.8 | 16 |
| C2 | Chapter 3, sections 3.7 and 3.15 | 16 |
| C3 | Chapter 3, section 3.12; Chapter 5, sections 5.14 and 5.15 | 17, 2 |
| C4 | Chapter 3, sections 3.9 and 3.13 | 17 |
| C5 | Chapter 26, sections 26.11 to 26.13 | 18 |
| C6 | Chapter 26, sections 26.3 to 26.8 | 16 |
| P1 | Chapter 3, sections 3.3 and 3.5 | 16 |
| P2 | Chapter 3, sections 3.7 and 3.9 | 16, 17 |
| P3 | Chapter 3, section 3.12; Chapter 5, sections 5.6 and 5.11; Chapter 4, section 4.10 | 17, 2 |
| P4 | Chapter 26, section 26.12 | 18 |
| Hands-on A | Chapter 3, sections 3.7, 3.8 and 3.15; Chapter 5, section 5.15; Chapter 13, section 13.11; Chapter 26, section 26.11 | 16, 18 |
| Hands-on B | Chapter 3, sections 3.9, 3.11 and 3.12; Chapter 5, section 5.15; Chapter 13, section 13.11; Chapter 26, section 26.12 | 17, 18 |
| O1 | Chapter 3, sections 3.3 and 3.4 | 16 |
| O2 | Chapter 3, section 3.8 | 16 |
| O3 | Chapter 26, sections 26.3 and 26.5; Chapter 13, sections 13.4 and 13.13 | 16 |
| O4 | Chapter 26, section 26.10; Chapter 13, section 13.11 | 18 |
| O5 | Chapter 3, sections 3.6 and 3.9 | 17 |
| O6 | Chapter 26, sections 26.2 and 26.9; Chapter 24, sections 24.4 to 24.6 | 18 |

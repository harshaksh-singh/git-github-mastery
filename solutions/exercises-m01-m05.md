# Solutions to the exercises of Modules 1 to 5

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the scripts in `labs/ex1/`: `ex-m01.sh` to `ex-m05.sh` for Levels 1 to 3 and `solve-m0N-<name>.sh` for the generated exercises. The questions are in [exercises/m01-m05-foundations.md](../exercises/m01-m05-foundations.md). Read a solution only after you have written your own answer.

## How to read these solutions

Each solution has the same parts: the **solution** with its transcript, the **reasoning** that leads there from the state of the repository, the **common mistakes**, the **expert approach** (what a senior engineer does or says beyond the right answer), and the **reference** to the textbook section that teaches the mechanism.

Differences between the transcripts and your terminal:

- `$LAB` is the lab root. The model runs happened in `$LAB/ex1/<script name>/...`; your work is in `$LAB/hands-on/x1/...` or, for generated exercises, in `$LAB/exercises/<name>/...`.
- The model runs use the fixed lab clock (7 September 2026), so their commit IDs are the same on every machine. Commits that you create in the lab shell have the real time and therefore other IDs. Blob and tree IDs depend on content only and match yours. In a generated sandbox the commits that the generator made have exactly the IDs printed here.
- `[exit status: N]` is printed by the scripts. By hand, run `echo $?` after the command.
- Lines that start with `#` inside a transcript are notes from the script, not output of Git.
- You can replay any model run: `labs/run ex1/ex-m01`, `labs/run ex1/solve-m01-unborn-main`, and so on.

---

## Module 1: What Git is

### Solution 1.1: one commit, three object types

**Solution.**

<!-- snippet: ex1/ex-m01/e01-objects -->
```text
$ git init chunker
Initialized empty Git repository in $LAB/ex1/ex-m01/chunker/.git/
$ cd chunker
$ printf 'def split(text, size):\n    return [text[i:i+size] for i in range(0, len(text), size)]\n' > chunker.py
$ git add chunker.py
$ git commit -m "Add fixed-size splitter"
[main (root-commit) db5b54c] Add fixed-size splitter
 1 file changed, 2 insertions(+)
 create mode 100644 chunker.py
$ git cat-file -t HEAD
commit
$ git cat-file -p HEAD
tree ff8e7ef67f36e23e92807f7b13e6f54018573690
author Lab User <you@example.com> 1788755760 +0530
committer Lab User <you@example.com> 1788755760 +0530

Add fixed-size splitter
$ git cat-file -p "HEAD^{tree}"
100644 blob c6e6c4ffc4812f68f213221f55be2b6646aec35c	chunker.py
$ git cat-file -t HEAD:chunker.py
blob
$ git cat-file -p HEAD:chunker.py
def split(text, size):
    return [text[i:i+size] for i in range(0, len(text), size)]
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m01/e01-files -->
```text
$ find .git/objects -type f | sort
.git/objects/c6/e6c4ffc4812f68f213221f55be2b6646aec35c
.git/objects/db/5b54c1c0023aac80e8eb5c5ccf5ba71c88ebc3
.git/objects/ff/8e7ef67f36e23e92807f7b13e6f54018573690
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
db5b54c1c0023aac80e8eb5c5ccf5ba71c88ebc3
```
<!-- /snippet -->

1. Three objects: a commit, a tree and a blob. The commit's `tree` line names the tree; the tree's single entry names the blob; nothing names the commit except the ref `refs/heads/main`.
2. The blob ID and the tree ID are the same in your terminal as here, because they are hashes of content that you typed identically: the bytes of `chunker.py`, and one tree entry made of a mode, a name and that blob ID. The commit ID differs, because the commit object also contains the author, the committer and two timestamps, and yours are not the lab's.
3. `HEAD` is a file that says `ref: refs/heads/main`. That ref is a file that holds the commit ID. The commit object names a tree. The tree maps the name `chunker.py` to a blob ID. The blob holds the bytes.

**Reasoning.** An object ID is the hash of the object's type, size and content. Equal input gives equal IDs on any machine. The three files under `.git/objects` are the three objects, each stored under the first two characters of its ID as a directory name.

**Common mistakes.** Expecting a "diff" somewhere: there is none, the commit points at a complete snapshot. Believing the file name is stored in the blob: the name lives in the tree, which is why a rename does not create a new blob. Calling the branch "the commits": the branch is the 41-byte file `refs/heads/main`.

**Expert approach.** When a tool reports an ID, ask "ID of what?" and check with `git cat-file -t`. Being able to walk HEAD, ref, commit, tree, blob by hand is what later makes recovery a matter of creating one ref.

**Reference.** Chapter 2, sections 2.4 to 2.6 and 2.8; Chapter 1, section 1.9.

### Solution 1.2: Git or GitHub?

**Solution.**

| # | Thing | Layer | Where it lives | Arrives with a clone? |
|---|---|---|---|---|
| 1 | Commit | Git | Object in the repository | Yes |
| 2 | Branch | Git | A ref in the repository | Yes; the server's branches arrive as remote-tracking branches |
| 3 | Pull request | GitHub | GitHub's database, plus read-only refs on the server | No |
| 4 | Annotated tag | Git | A tag object and a ref | Yes |
| 5 | Release, notes, attached files | GitHub | An object that points at a Git tag | The tag yes, the release no |
| 6 | Fork | GitHub | A server-side repository linked to its parent; to Git one more remote | Not applicable |
| 7 | Your reflog | Git, local only | `.git/logs` | No, every clone has its own |
| 8 | Author name and email | Git | Inside each commit object | Yes |
| 9 | "Verified" badge | GitHub | GitHub's judgement of a signature; the signature itself is Git data | No |
| 10 | Workflow file | Git | A tracked file in commits | Yes |
| 11 | Log of a workflow run | GitHub Actions | GitHub | No |
| 12 | Ruleset | GitHub | Repository or organization settings | No |
| 13 | `.git/config` | Git, local only | Your `.git` | No |
| 14 | Star | GitHub | GitHub's database | No |

"The merge is blocked" has a cause in one of three layers. Git stops a merge when both sides changed the same lines (a conflict, visible in `git status` or `git merge-tree`). GitHub stops it when a rule is not satisfied, for example a required review. GitHub Actions stops it, through a rule, when a required check has not reported success. The telling observation is where the refusal is shown: in the output of a Git command, in the merge box as a review requirement, or as a pending or failed check.

**Reasoning.** The test for "Git data" is: is it an object or a ref in the repository? Everything else that is Git's but local (HEAD, index, reflogs, configuration, hooks) stays in your `.git`. Everything GitHub adds is in GitHub's database and reaches you only through its interface or API.

**Common mistakes.** Calling a pull request a Git feature. Expecting reflogs, hooks or configuration to come along with a clone. Treating a release as a tag: the tag is Git's, the release is GitHub's object on top of it.

**Expert approach.** In an incident, label the layer in every sentence you say: "Git rejected the push as a non-fast-forward" and "the ruleset rejected the push" lead to different fixes and different owners.

**Reference.** Chapter 1, section 1.5.

### Solution 1.3: the diagnosis ritual on a small state

**Solution.**

<!-- snippet: ex1/ex-m01/e03-state -->
```text
$ printf 'def split(text, size, overlap=0):\n    step = size - overlap\n    return [text[i:i+size] for i in range(0, len(text), step)]\n' > chunker.py
$ printf 'pytest\n' > requirements-dev.txt
$ git add requirements-dev.txt
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   requirements-dev.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   chunker.py
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m01/e03-diagnosis -->
```text
$ git branch -vv
* main db5b54c Add fixed-size splitter
$ git remote -v
$ git log --graph --decorate --oneline --all
* db5b54c (HEAD -> main) Add fixed-size splitter
$ git diff --stat
 chunker.py | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
$ git diff --cached --stat
 requirements-dev.txt | 1 +
 1 file changed, 1 insertion(+)
$ git ls-files
chunker.py
requirements-dev.txt
$ git config list --show-origin --show-scope
global	file:$LAB/ex1/ex-m01/home/.gitconfig	user.name=Lab User
global	file:$LAB/ex1/ex-m01/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ex1/ex-m01/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ex1/ex-m01/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ex1/ex-m01/home/.gitconfig	gc.reflogexpireunreachable=never
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
```
<!-- /snippet -->

| Command | Question it answers | Reads |
|---|---|---|
| `git status` | What differs between HEAD, the index and the working tree? | HEAD, index, working tree |
| `git branch -vv` | Which branches exist, where do they point, what do they follow? | refs, configuration |
| `git remote -v` | Which other repositories does this one know? | configuration |
| `git log --graph --decorate --oneline --all` | What does the commit graph look like, and which names sit on it? | objects, refs, HEAD |
| `git diff --stat` | What is changed and not staged? | index against working tree |
| `git diff --cached --stat` | What would the next commit change? | HEAD against index |
| `git ls-files` | Which paths does the index contain? | index |
| `git config list --show-origin --show-scope` | Which settings are in force, and from which file? | configuration |

`git diff` and `git diff --cached` together contain everything `git status` summarized, except the untracked files. `git remote -v` printed nothing: this repository knows no other repository, so there is nothing to push to, fetch from, or be "behind".

**Reasoning.** `git ls-files` lists `requirements-dev.txt` although it was never committed, because `git add` already put it into the index. `git branch -vv` shows no bracket after the commit ID, because `main` has no upstream.

**Common mistakes.** Reading `git status` only and guessing the rest. Taking an empty output for a failure: silence from `git remote -v` and from `git diff` is information. Forgetting that `git diff` alone never shows staged changes.

**Expert approach.** Run the read-only commands in the same order every time and before any command that changes state. Evidence first, hypothesis second; the ritual costs twenty seconds and prevents the "fix" that destroys the evidence.

**Reference.** Chapter 1, sections 1.10 and 1.11.

### Solution 1.4: how many objects?

**Solution.** Eight objects: three blobs, three trees, two commits.

<!-- snippet: ex1/ex-m01/e04-count -->
```text
$ git init counts
Initialized empty Git repository in $LAB/ex1/ex-m01/counts/.git/
$ cd counts
$ printf 'alpha\n' > a.txt
$ printf 'beta\n' > b.txt
$ mkdir docs
$ printf 'alpha\n' > docs/a-copy.txt
$ git add .
$ git commit -q -m "First"
$ printf 'beta v2\n' > b.txt
$ git commit -q -am "Second"
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
   3 blob
   2 commit
   3 tree
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m01/e04-why -->
```text
$ git ls-tree -r HEAD
100644 blob 4a58007052a65fbc2fc3f910f2855f45a4058e74	a.txt
100644 blob 892f5705b5026ed7130eae97ab57da9572ec2f00	b.txt
100644 blob 4a58007052a65fbc2fc3f910f2855f45a4058e74	docs/a-copy.txt
$ git ls-tree HEAD~1
100644 blob 4a58007052a65fbc2fc3f910f2855f45a4058e74	a.txt
100644 blob 65b2df87f7df3aeedef04be96703e55ac19c2cfb	b.txt
040000 tree d92e8a888c5da8f851c24b772ae4d5b4eb6eb120	docs
$ git ls-tree HEAD
100644 blob 4a58007052a65fbc2fc3f910f2855f45a4058e74	a.txt
100644 blob 892f5705b5026ed7130eae97ab57da9572ec2f00	b.txt
040000 tree d92e8a888c5da8f851c24b772ae4d5b4eb6eb120	docs
```
<!-- /snippet -->

- Blobs: `alpha` once (used by `a.txt` and by `docs/a-copy.txt`), `beta`, and `beta v2`. Three contents, three blobs, although four file versions were committed.
- Trees: the root tree of the first commit, the root tree of the second commit (its entry for `b.txt` changed), and the tree for `docs`, which both root trees refer to because nothing below `docs` changed.
- Commits: two.

**Reasoning.** Count contents, not files. A blob is identified by its bytes, so the same bytes under two names are one object. A tree is identified by its list of entries, so a directory that did not change between two commits is one object referred to twice. The second commit added exactly three objects: one blob, one root tree, one commit.

**Common mistakes.** Counting four blobs (one per file) or five (one per file version). Counting two `docs` trees. Expecting the second commit to store "the difference": it stores a new root tree that reuses everything unchanged.

**Expert approach.** This arithmetic is how to estimate what a change costs. A one-line edit in a file four directories deep creates one blob, five trees and one commit, whatever the size of the repository. Packfiles compress further (Chapter 3, section 3.7), but that is storage, not the model.

**Reference.** Chapter 2, sections 2.3 and 2.4.

### Solution 1.5: add twice, commit once

**Solution.** Four objects: two blobs, one tree, one commit. `draft 1` exists as a blob that nothing refers to.

<!-- snippet: ex1/ex-m01/e05-twice -->
```text
$ git init twice
Initialized empty Git repository in $LAB/ex1/ex-m01/twice/.git/
$ cd twice
$ printf 'draft 1\n' > note.txt
$ git add note.txt
$ printf 'draft 2\n' > note.txt
$ git add note.txt
$ git commit -q -m "Add note"
$ git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectname)'
blob 0ff97eebb7214533df3df349a8d3f8f67227ab78
blob 3e035a95df46586e649017eaeb72ef48271392c7
tree 7901a37e26ebb4fef490ed79bed49674ca634873
commit b7e2be4cc4df53c004bb7c2ff5392e46ea32eec8
$ git ls-tree HEAD
100644 blob 3e035a95df46586e649017eaeb72ef48271392c7	note.txt
$ git fsck
dangling blob 0ff97eebb7214533df3df349a8d3f8f67227ab78
$ git cat-file -p 0ff97ee
draft 1
```
<!-- /snippet -->

Each `git add` wrote a blob at once: the first for `draft 1`, the second for `draft 2`. The second `git add` also replaced the index entry for `note.txt`, so the first blob lost its only referrer. `git commit` wrote the tree (from the index) and the commit. `git fsck` reports the orphan as a `dangling blob`.

**Reasoning.** `git add` is not a note to self that says "include this file later". It copies the file's content into the object database immediately and records the blob ID in the index. A commit then needs no access to the working tree at all.

**Common mistakes.** Predicting three objects because "only one version was committed". Believing that `git fsck` output means damage: `dangling` is routine, `missing` and `error:` are not. Assuming the blob is gone for good the moment it is unreferenced: it stays until garbage collection prunes it.

**Expert approach.** This is the mechanism behind one of the few recoveries of uncommitted work: content that was staged once can be found again with `git fsck` even after `git reset --hard` (Exercise 8.8, and Chapter 13, section 13.9). The practical rule: when in doubt, `git add` before a risky command.

**Reference.** Chapter 2, sections 2.6 and 2.9; Chapter 5, section 5.3.

### Solution 1.6: two branches and a tag

**Solution.**

<!-- snippet: ex1/ex-m01/e06-graph -->
```text
$ git init graph
Initialized empty Git repository in $LAB/ex1/ex-m01/graph/.git/
$ cd graph
$ git commit -q --allow-empty -m A
$ git commit -q --allow-empty -m B
$ git branch topic
$ git commit -q --allow-empty -m C
$ git switch -q topic
$ git commit -q --allow-empty -m D
$ git commit -q --allow-empty -m E
$ git tag v1 main
$ git switch -q main
$ git log --graph --oneline --all
* 662d422 E
* 8fb9e4c D
| * 4f86638 C
|/  
* d314157 B
* e35c2d0 A
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m01/e06-refs -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git for-each-ref --format="%(refname) %(objectname:short) %(subject)"
refs/heads/main 4f86638 C
refs/heads/topic 662d422 E
refs/tags/v1 4f86638 C
$ git log --oneline main
4f86638 C
d314157 B
e35c2d0 A
```
<!-- /snippet -->

`main` and the tag `v1` name `C`; `topic` names `E`; HEAD is the symbolic ref `ref: refs/heads/main`. With the decorations that `--decorate` would add, the picture is:

```text
            D---E          topic
           /
  A---B---C                main, tag v1      (HEAD -> main)
```

`git log --oneline main` lists `C`, `B`, `A`. `E` is not among them because `git log main` walks parent links backwards from `C`, and no chain of parents leads from `C` to `E`. Time does not enter into it.

**Reasoning.** `git branch topic` created a ref at `B` and did not switch. The next commit, `C`, therefore moved `main`. After `git switch topic`, the commits `D` and `E` moved `topic`. `git tag v1 main` created a second name for the commit that `main` named at that moment.

**Common mistakes.** Drawing `D` and `E` on top of `C` because they were made later. Drawing the tag as something that follows the branch. Putting HEAD on a commit: HEAD points at the branch name, and through it at the commit.

**Expert approach.** Read `--graph` output as a set of parent links, and treat every ref as a label that can be peeled off and stuck elsewhere without changing the graph. Most "where did my commits go" questions are answered by asking which refs make which commits reachable.

**Reference.** Chapter 2, sections 2.7 and 2.8.

### Solution 1.7: the same files, two different commit IDs

**Solution.** Nothing is corrupt. The two commits record the same content; they differ in metadata.

<!-- snippet: ex1/ex-m01/e07-trees -->
```text
$ git -C laptop rev-parse "HEAD^{tree}"
054f5cf5ddc9866ec187c05c844785d5bae9bb0b
$ git -C ci-box rev-parse "HEAD^{tree}"
054f5cf5ddc9866ec187c05c844785d5bae9bb0b
$ git -C laptop ls-tree -r HEAD
100644 blob b5fee68e16090ca243c174fd28853ad0abe8b77a	config.yaml
100644 blob 2c7dba0b0f79357c2ea616712d4ba5ac43c8c821	prompts/system.txt
$ git -C ci-box ls-tree -r HEAD
100644 blob b5fee68e16090ca243c174fd28853ad0abe8b77a	config.yaml
100644 blob 2c7dba0b0f79357c2ea616712d4ba5ac43c8c821	prompts/system.txt
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m01/e07-commits -->
```text
$ git -C laptop cat-file -p HEAD
tree 054f5cf5ddc9866ec187c05c844785d5bae9bb0b
author Lab User <you@example.com> 1788759480 +0530
committer Lab User <you@example.com> 1788759480 +0530

Import prompt and config
$ git -C ci-box cat-file -p HEAD
tree 054f5cf5ddc9866ec187c05c844785d5bae9bb0b
author Asha Rao <asha@example.com> 1788759840 +0530
committer Asha Rao <asha@example.com> 1788759840 +0530

Import prompt and config
```
<!-- /snippet -->

1. A commit ID is the hash of the commit object: the tree ID, the parent IDs, the author name, email and date, the committer name, email and date, and the message. Here the tree and the message are equal, there is no parent on either side, and the author, the committer and both dates differ.
2. `git rev-parse "HEAD^{tree}"` in both repositories. Equal tree IDs mean that every path, every mode and every byte of every file is equal, because a tree ID is a hash over the entries and each entry contains the hash of what it names. Different tree IDs would mean different content, and `git ls-tree -r HEAD` in both would show which path.
3. Copying `.git` from one machine to the other would repair nothing and would replace one history by the other. If the two repositories are meant to be one project, one of them should be cloned or fetched from the other, so that both hold the same commit.

**Reasoning.** Content addressing gives a cheap equality test at every level. Blob IDs compare files, tree IDs compare whole directory states, commit IDs compare "this state, recorded by this person at this moment on top of that history".

**Common mistakes.** Comparing files with `diff -r` across machines when two IDs do the job. Concluding "corruption" from different commit IDs. Concluding "same history" from equal trees: equal trees prove equal content, not equal ancestry.

**Expert approach.** State the claim at the right level: "the trees are identical, so the content is; the commits differ because author and time are part of a commit". Corruption is what `git fsck` reports, and it looks different (Chapter 3, section 3.8).

**Reference.** Chapter 2, sections 2.4 and 2.5; Chapter 6, section 6.4.

### Solution 1.8: the object that no history shows

**Solution.**

<!-- snippet: ex1/ex-m01/e08-setup -->
```text
$ git init vault
Initialized empty Git repository in $LAB/ex1/ex-m01/vault/.git/
$ cd vault
$ printf 'v1\n' > notes.txt
$ git add notes.txt
$ git commit -q -m "Add notes"
$ printf '{"lowercase": true, "max_tokens": 512}\n' > tokenizer.json
$ git hash-object -w tokenizer.json
cb84445943a414858a2ed8e52b27683c1df8ccfb
$ rm tokenizer.json
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m01/e08-diagnosis -->
```text
$ git fsck
dangling blob cb84445943a414858a2ed8e52b27683c1df8ccfb
$ git ls-tree -r HEAD
100644 blob 626799f0f85326a8c1fc522db584e86cdfccd51f	notes.txt
$ git clone -q --no-local . ../vault-copy
$ git -C ../vault-copy cat-file -t cb84445
fatal: Not a valid object name cb84445
[exit status: 128]
```
<!-- /snippet -->

1. `git hash-object -w` wrote one blob into the object database. No tree has an entry for it, so no commit contains it, so no ref reaches it. It has content and no name, no path, no history.
2. `git fsck` calls it a `dangling blob`. A clone made through Git's transport does not contain it: a clone asks for the server's refs and receives the objects reachable from them. The model run uses `--no-local` because a clone from a plain local path copies or hard-links the object files without that selection (Chapter 3, section 3.8).
3. Attach the existing blob to the index under a path, commit, and let the working tree catch up:

<!-- snippet: ex1/ex-m01/e08-fix -->
```text
$ git update-index --add --cacheinfo 100644,cb84445943a414858a2ed8e52b27683c1df8ccfb,tokenizer.json
$ git status --short
AD tokenizer.json
$ git commit -q -m "Add tokenizer settings"
$ git restore tokenizer.json
$ git ls-tree -r HEAD
100644 blob 626799f0f85326a8c1fc522db584e86cdfccd51f	notes.txt
100644 blob cb84445943a414858a2ed8e52b27683c1df8ccfb	tokenizer.json
$ git fsck
```
<!-- /snippet -->

The status `AD` after `git update-index` reads: added in the index, deleted in the working tree. That is accurate, the file was removed by hand. `git restore tokenizer.json` copies it out of the index. `git fsck` is now silent.

**Reasoning.** "In the repository" has two meanings: present in the object database, and part of history. Only the second survives a clone, a push and, in the long run, garbage collection. Reachability from a ref is the dividing line.

**Common mistakes.** Recreating the file by hand and adding it, which works and misses the point that the content was already stored. Expecting `git log --all` to find an object that no commit refers to. Relying on a noted ID as a backup: an unreachable loose object is deleted by `git gc` once it is older than the prune grace period (two weeks by default).

**Expert approach.** Treat `git hash-object -w` as plumbing for building objects, not as storage. If something must be kept without being committed to a branch, give it a ref: a commit on a scratch branch, or a stash.

**Reference.** Chapter 2, sections 2.6 and 2.7; Chapter 3, section 3.8.

### Solution 1.9: "git log says there are no commits"

**Solution.** The commits are intact. HEAD names the branch `main`, and the ref `refs/heads/main` does not exist: the interrupted script had moved the ref file to `refs/heads/trunk`.

<!-- snippet: ex1/solve-m01-unborn-main/01-symptom -->
```text
$ cd chunk-index
$ git log --oneline
fatal: your current branch 'main' does not have any commits yet
[exit status: 128]
$ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   README.md
	new file:   chunkindex/build.py
	new file:   chunkindex/lookup.py
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m01-unborn-main/02-evidence -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git for-each-ref
377b28da7e467d9a39cf2d8662ba46bce5d4e827 commit	refs/heads/trunk
$ git branch -vv
  trunk 377b28d Add README
$ git log --oneline trunk
377b28d Add README
2761ad5 Add lookup by position
b8ea260 Add in-memory chunk index
$ git fsck
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m01-unborn-main/03-repair -->
```text
$ git branch -m trunk main
$ git for-each-ref
377b28da7e467d9a39cf2d8662ba46bce5d4e827 commit	refs/heads/main
$ git status
On branch main
nothing to commit, working tree clean
$ git log --oneline
377b28d Add README
2761ad5 Add lookup by position
b8ea260 Add in-memory chunk index
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m01-unborn-main/04-check -->
```text
$ cd ..
$ exercises/gen/m01-unborn-main/check.sh
Checking exercise m01-unborn-main
  ok    HEAD is a symbolic ref to refs/heads/main
  ok    main points at the last commit of Friday
  ok    the history has exactly the three original commits
  ok    main is the only branch
  ok    the working tree and the index match the commit
  ok    the object database is intact
PASS: exercise m01-unborn-main is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.**

```text
Observed behavior : "your current branch 'main' does not have any commits yet"; status lists
                    every tracked file as new.
Git state         : HEAD = ref: refs/heads/main. refs/heads/main does not exist.
                    refs/heads/trunk names the last commit. Index and working tree are intact.
Mechanism         : HEAD pointing at a missing ref is how Git represents a branch before its
                    first commit. With no HEAD commit to compare with, every index entry is "new".
Root cause        : a script renamed the ref file by hand and did not update HEAD.
Why Git does this : Git trusts refs. It does not search the object database for commits
                    that no ref names.
Correct fix       : give the commits the name HEAD expects: git branch -m trunk main.
Prevention        : rename branches with git branch -m, which moves the ref, its reflog and
                    HEAD together. Never edit files under .git/refs by hand.
```

`git fsck` printing nothing was the reassurance: no object is missing and none is dangling, because `trunk` reaches all three commits. The equivalent plumbing repair is `git update-ref refs/heads/main refs/heads/trunk` followed by `git update-ref -d refs/heads/trunk`; `git symbolic-ref HEAD refs/heads/trunk` would also make `git log` work, and would keep the wrong branch name.

**Common mistakes.** Running `git commit` in this state: it would create a new root commit on `main` with all files and no history, and the two histories would then have to be untangled. Cloning afresh and copying files over, which discards the local history that never needed saving. Searching with `git reflog` only: the reflog of HEAD does show the commits, and the direct evidence is one `git for-each-ref` away.

**Expert approach.** Three reads decide the case: `cat .git/HEAD`, `git for-each-ref`, `git fsck`. When HEAD and the refs disagree, repair the name, never the content, and prefer the porcelain command that keeps the reflog.

**Reference.** Chapter 2, sections 2.6 and 2.8; Chapter 7, sections 7.3 and 7.5.

---

## Module 2: Working tree, index, HEAD

### Solution 2.1: every short status code, made on purpose

**Solution.**

<!-- snippet: ex1/ex-m02/e01-status -->
```text
$ printf 'ideas\n' > notes.md
$ printf 'def report(rows):\n    return len(rows)\n' > report.py
$ git add report.py
$ printf 'def audit(rows):\n    return [r for r in rows if not r.label]\n' > audit.py
$ printf '# label-audit\n\nFinds rows without a label.\n' > README.md
$ git add README.md
$ printf 'id,label\n1,spam\n2,ham\n3,spam\n' > labels.csv
$ git add labels.csv
$ printf 'id,label\n1,spam\n2,ham\n3,spam\n4,ham\n' > labels.csv
$ rm old_rules.txt
$ git rm -q legacy.py
$ git mv loader.py reader.py
$ git status --short
M  README.md
 M audit.py
MM labels.csv
D  legacy.py
 D old_rules.txt
R  loader.py -> reader.py
A  report.py
?? notes.md
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m02/e01-long -->
```text
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md
	modified:   labels.csv
	deleted:    legacy.py
	renamed:    loader.py -> reader.py
	new file:   report.py

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   audit.py
	modified:   labels.csv
	deleted:    old_rules.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md
```
<!-- /snippet -->

The left column compares HEAD with the index (what is staged). The right column compares the index with the working tree (what is not staged).

| Path | Code | Left: HEAD against index | Right: index against working tree | Long form heading |
|---|---|---|---|---|
| `README.md` | `M ` | modified | same | Changes to be committed |
| `audit.py` | ` M` | same | modified | Changes not staged for commit |
| `labels.csv` | `MM` | modified | modified again | both headings |
| `legacy.py` | `D ` | deleted | (gone in both) | Changes to be committed |
| `old_rules.txt` | ` D` | same | deleted | Changes not staged for commit |
| `loader.py -> reader.py` | `R ` | renamed | same | Changes to be committed |
| `report.py` | `A ` | added | same | Changes to be committed |
| `notes.md` | `??` | not in the index | present | Untracked files |

`labels.csv` appears twice because there are three versions of it: the committed one, the staged one with three rows, and the working tree one with four. Each heading reports one of the two comparisons.

**Reasoning.** `git status` is two diffs printed together. `rm` changes only the working tree, so the deletion shows in the right column; `git rm` also removes the index entry, so it shows in the left. `git mv` is a delete and an add in the index that Git reports as a rename because the content is identical.

**Common mistakes.** Reading `MM` as "modified twice, will be committed in full". Reading ` D` as a staged deletion. Believing that `R` proves Git stored a rename: the index holds a removed path and an added path, and the `R` is computed when status runs.

**Expert approach.** Use `git status --short` (or `-sb`) as the default view and read it column by column. For scripts use `--porcelain`, whose format is guaranteed not to change.

**Reference.** Chapter 4, sections 4.3 and 4.4; Chapter 5, section 5.7.

### Solution 2.2: which rule ignores which path

**Solution.**

<!-- snippet: ex1/ex-m02/e02-ignore -->
```text
$ git init -q ignore-rules
$ cd ignore-rules
$ printf '*.log\n/build/\ndata/*\n!data/README.md\n.env*\n!.env.example\n' > .gitignore
$ cat -n .gitignore
     1	*.log
     2	/build/
     3	data/*
     4	!data/README.md
     5	.env*
     6	!.env.example
$ git check-ignore -v -n app.log logs/app.log build/out.bin src/build/out.bin data/train.csv data/README.md .env.local .env.example
.gitignore:1:*.log	app.log
.gitignore:1:*.log	logs/app.log
.gitignore:2:/build/	build/out.bin
::	src/build/out.bin
.gitignore:3:data/*	data/train.csv
.gitignore:4:!data/README.md	data/README.md
.gitignore:5:.env*	.env.local
.gitignore:6:!.env.example	.env.example
```
<!-- /snippet -->

| Path | Result | Deciding line | Why |
|---|---|---|---|
| `app.log` | ignored | 1 `*.log` | A pattern without a slash matches the name at any depth |
| `logs/app.log` | ignored | 1 `*.log` | Same pattern, deeper directory |
| `build/out.bin` | ignored | 2 `/build/` | Leading `/` anchors at the directory of the `.gitignore`; trailing `/` matches directories only |
| `src/build/out.bin` | not ignored | none (`::`) | The anchored pattern does not match a `build` directory further down |
| `data/train.csv` | ignored | 3 `data/*` | Everything directly inside `data` |
| `data/README.md` | not ignored | 4 `!data/README.md` | A later negation re-includes it |
| `.env.local` | ignored | 5 `.env*` | Name starts with `.env` |
| `.env.example` | not ignored | 6 `!.env.example` | A later negation re-includes it |

**Reasoning.** Within one file the last matching line wins, which is why the two `!` lines stand after the patterns they correct. With `-v`, `git check-ignore` prints the deciding line even when that line is a negation, so "a rule is printed" does not mean "ignored": read the pattern. With `-n` it also prints paths that no rule matches, with empty fields.

**Common mistakes.** Taking every line of `-v` output for an ignored path. Writing `build/` when only the top-level directory is meant, which also ignores `src/build/`. Forgetting that the command evaluates names: the paths need not exist.

**Expert approach.** Test a new pattern with `git check-ignore -v -n` before committing the `.gitignore`, with one path that must be ignored and one that must not. Ignore rules affect untracked paths only; a tracked file stays tracked whatever `.gitignore` says (section 4.6).

**Reference.** Chapter 4, section 4.5.

### Solution 2.3: three diffs, three comparisons

**Solution.**

<!-- snippet: ex1/ex-m02/e03-diffs -->
```text
$ git init -q three-diffs
$ cd three-diffs
$ printf 'min_agreement: 0.80\n' > thresholds.yaml
$ git add thresholds.yaml
$ git commit -q -m "Add thresholds"
$ printf 'min_agreement: 0.85\n' > thresholds.yaml
$ git add thresholds.yaml
$ printf 'min_agreement: 0.90\n' > thresholds.yaml
$ git diff
diff --git a/thresholds.yaml b/thresholds.yaml
index 176fffa..167cd6b 100644
--- a/thresholds.yaml
+++ b/thresholds.yaml
@@ -1 +1 @@
-min_agreement: 0.85
+min_agreement: 0.90
$ git diff --cached
diff --git a/thresholds.yaml b/thresholds.yaml
index c602e83..176fffa 100644
--- a/thresholds.yaml
+++ b/thresholds.yaml
@@ -1 +1 @@
-min_agreement: 0.80
+min_agreement: 0.85
$ git diff HEAD
diff --git a/thresholds.yaml b/thresholds.yaml
index c602e83..167cd6b 100644
--- a/thresholds.yaml
+++ b/thresholds.yaml
@@ -1 +1 @@
-min_agreement: 0.80
+min_agreement: 0.90
```
<!-- /snippet -->

| Command | Compares | Left value | Right value |
|---|---|---|---|
| `git diff` | index with working tree | 0.85 | 0.90 |
| `git diff --cached` | HEAD with index | 0.80 | 0.85 |
| `git diff HEAD` | HEAD with working tree | 0.80 | 0.90 |

`git commit` would record what `git diff --cached` shows: 0.85. `git commit -a` would first stage the working tree version and record what `git diff HEAD` shows: 0.90.

**Reasoning.** There are three places, hence three pairs. The `index` line of each diff header names the two blob IDs being compared, and the same abbreviated IDs reappear across the three outputs: one blob per version of the file.

**Common mistakes.** Reviewing with `git diff` before a commit: it shows exactly what will **not** be committed. Assuming `git diff HEAD` equals the next commit. Forgetting that `--staged` is a synonym of `--cached`.

**Expert approach.** Before every commit, read `git diff --cached`. It is the only one of the three that shows the commit you are about to make.

**Reference.** Chapter 5, section 5.4.

### Solution 2.4: what does the commit contain?

**Solution.**

<!-- snippet: ex1/ex-m02/e04-answer -->
```text
$ git show HEAD:job.yaml
retries: 2
$ cat job.yaml
retries: 3
$ git status --short
 M job.yaml
$ git diff
diff --git a/job.yaml b/job.yaml
index f69399f..efc3dd6 100644
--- a/job.yaml
+++ b/job.yaml
@@ -1 +1 @@
-retries: 2
+retries: 3
$ git ls-files --stage
100644 f69399fd996c3bc511a8ab9655f04bb35ffe28d2 0	job.yaml
```
<!-- /snippet -->

The commit contains `retries: 2`. The working tree still has `retries: 3`, reported as an unstaged modification.

**Reasoning.** `git commit` builds its tree from the index and never looks at the working tree. The index entry for `job.yaml` was set by the second `git add`, when the file said 2. The later edit to 3 changed the working tree only.

**Common mistakes.** Predicting 3 because "that is what the file contains". Predicting a clean status after the commit. Blaming Git for "committing an old version": it committed the version you staged.

**Expert approach.** This behavior is the reason partial commits are possible at all. Use it deliberately (`git add -p`), and when you want "everything as it is on disk", say so with `git commit -a` or a fresh `git add`. After any commit, a glance at `git status --short` shows what did not go in.

**Reference.** Chapter 5, sections 5.2, 5.3 and 5.10.

### Solution 2.5: a negated pattern that does not work

**Solution.**

<!-- snippet: ex1/ex-m02/e05-answer -->
```text
$ git status --short --untracked-files=all
?? .gitignore
?? models/tiny.ckpt
$ git check-ignore -v data/README.md
.gitignore:1:data/	data/README.md
[exit status: 0]
$ git check-ignore -v models/tiny.ckpt
.gitignore:4:!models/tiny.ckpt	models/tiny.ckpt
[exit status: 0]
$ git check-ignore -v models/best.ckpt
.gitignore:3:*.ckpt	models/best.ckpt
[exit status: 0]
```
<!-- /snippet -->

`models/tiny.ckpt` is re-included; `data/README.md` is not. The pattern `data/` excludes the directory itself, Git therefore never looks inside it, and the negation on the next line has nothing to act on. `*.ckpt` excludes files, not their directory, so `!models/tiny.ckpt` works.

The fix is to exclude the contents of `data` and not the directory:

<!-- snippet: ex1/ex-m02/e05-fix -->
```text
$ printf 'data/*\n!data/README.md\n*.ckpt\n!models/tiny.ckpt\n' > .gitignore
$ git status --short --untracked-files=all
?? .gitignore
?? data/README.md
?? models/tiny.ckpt
$ git check-ignore -v data/README.md
.gitignore:2:!data/README.md	data/README.md
[exit status: 0]
$ git check-ignore -v data/raw/a.csv
.gitignore:1:data/*	data/raw/a.csv
```
<!-- /snippet -->

**Reasoning.** The manual states the limit in one sentence: it is not possible to re-include a file if a parent directory of that file is excluded. `git check-ignore -v data/README.md` names line 1 (`data/`) before the fix and line 2 (the negation) after it.

**Common mistakes.** Reordering the two lines, which changes nothing. Adding more `!` lines. Using `git add -f data/README.md` and leaving the broken rule in place for the next person. Note that `data/*` matches one level: `data/raw/a.csv` is covered because `data/raw` is, as the last command shows.

**Expert approach.** For "ignore a directory but keep one file in it", the pattern is always the pair `dir/*` and `!dir/keep`. Prove it with `git status --short --untracked-files=all`, which lists individual files instead of collapsed directories.

**Reference.** Chapter 4, section 4.5 ("Negation has a hard limit") and section 4.15.

### Solution 2.6: a move and an edit, as two commits

**Solution.**

<!-- snippet: ex1/ex-m02/e06-rename -->
```text
$ mkdir trainer
$ git mv train.py trainer/run.py
$ git status --short
R  train.py -> trainer/run.py
$ git commit -q -m "Move training loop into the trainer package"
$ sed -e 's/print("epoch", epoch)/print("epoch", epoch + 1, "of", epochs)/' trainer/run.py > run.tmp && mv run.tmp trainer/run.py
$ git commit -q -am "Print one-based epoch numbers"
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m02/e06-verify -->
```text
$ git show --stat --format=%s HEAD~1
Move training loop into the trainer package

 train.py => trainer/run.py | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git show --stat --format=%s HEAD
Print one-based epoch numbers

 trainer/run.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --follow -- trainer/run.py
cb7ac18 Print one-based epoch numbers
eebcebd Move training loop into the trainer package
0005f48 Add training loop
$ git log --oneline -- trainer/run.py
cb7ac18 Print one-based epoch numbers
eebcebd Move training loop into the trainer package
```
<!-- /snippet -->

`git log --follow` lists all three commits; without `--follow` the history of `trainer/run.py` stops at the commit that created that path.

**Reasoning.** Git stored nothing that says "rename". The move commit has a tree in which `train.py` is absent and `trainer/run.py` has the same blob ID that `train.py` had. `git show --stat` compares the two trees, finds a deleted path and an added path with identical content, and prints `train.py => trainer/run.py` with zero changed lines. Because rename detection works on similarity of content, a move that is committed together with a large edit can fall below the threshold and be shown as one deletion and one addition.

**Common mistakes.** Moving and editing in one commit, which makes the review diff unreadable and can break `--follow`. Using `mv` and forgetting to stage the deletion of the old path. Believing `git mv` records something that `mv` plus `git add -A` would not: the resulting index is the same.

**Expert approach.** Split "move" from "change" whenever a file moves, and say so in the commit message. Reviewers read the first commit in seconds, and `git log --follow` and `git blame` keep working across it.

**Reference.** Chapter 4, sections 4.8 and 4.9; Chapter 5, section 5.7; Chapter 14A, section 14A.10.

### Solution 2.7: "git restore ." did not throw everything away

**Solution.**

<!-- snippet: ex1/ex-m02/e07-setup -->
```text
$ git init -q discard
$ cd discard
$ printf 'k: 5\n' > retrieval.yaml
$ printf 'model: small\n' > model.yaml
$ git add .
$ git commit -q -m "Add configs"
$ printf 'k: 50\n' > retrieval.yaml
$ printf 'model: large\n' > model.yaml
$ git add model.yaml
$ printf 'scratch\n' > notes.md
$ git status --short
M  model.yaml
 M retrieval.yaml
?? notes.md
$ git restore .
$ git status --short
M  model.yaml
?? notes.md
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m02/e07-explain -->
```text
$ cat retrieval.yaml model.yaml
k: 5
model: large
$ git diff --cached
diff --git a/model.yaml b/model.yaml
index 4a39d85..51dad65 100644
--- a/model.yaml
+++ b/model.yaml
@@ -1 +1 @@
-model: small
+model: large
```
<!-- /snippet -->

1. `git restore <path>` copies **from the index to the working tree**, for tracked paths.
   - `retrieval.yaml`: the index held the committed version, so the edit was overwritten. It is gone for good, it was never staged.
   - `model.yaml`: the index held the staged version (`large`), and the working tree was already equal to it. Nothing to do, and the staged change remains staged.
   - `notes.md`: untracked, not in the index, not touched by `git restore`.
2. Reset index and working tree from HEAD, then remove the untracked file after a preview:

<!-- snippet: ex1/ex-m02/e07-discard -->
```text
$ git restore --staged --worktree .
$ git status --short
?? notes.md
$ git clean -n
Would remove notes.md
$ git clean -f
Removing notes.md
$ git status --short
```
<!-- /snippet -->

`git restore --staged --worktree .` takes HEAD as its source when `--staged` is given. 🔴 `git clean -f` is the step with no undo: an untracked file was never an object, so nothing in `.git` can bring it back. `git clean -n` is its preview.

3. Commit experiments on a throwaway branch. A branch can be deleted, and until garbage collection its commits can even be brought back.

**Reasoning.** "Discard my changes" is three different operations because the changes live in three different places: a staged change is in the index, an unstaged change is in the working tree, an untracked file is known to nothing.

**Common mistakes.** Reaching for 🔴 `git reset --hard` plus `git clean -fd` by reflex: correct here, and the fastest way to destroy the one file you forgot about. Believing `git restore .` reaches the index. Running `git clean -f` without `-n`.

**Expert approach.** Name the source and the destination of every undo before typing it, and preview: `git status --short` for what will change, `git clean -n` for what will be deleted.

**Reference.** Chapter 4, sections 4.7 and 4.14; Chapter 11, section 11.3.

### Solution 2.8: the commit that took more than was staged

**Solution.**

<!-- snippet: ex1/ex-m02/e08-before -->
```text
$ git status --short
M  README.md
MM metrics.py
$ git diff --cached -- metrics.py
diff --git a/metrics.py b/metrics.py
index 17d2823..23889c8 100644
--- a/metrics.py
+++ b/metrics.py
@@ -1,5 +1,5 @@
 def exact_match(a, b):
-    return a == b
+    return normalize(a) == normalize(b)
 
 
 
$ git diff -- metrics.py
diff --git a/metrics.py b/metrics.py
index 23889c8..83bbeda 100644
--- a/metrics.py
+++ b/metrics.py
@@ -8,4 +8,4 @@ def exact_match(a, b):
 
 
 def normalize(s):
-    return s
+    return s.strip().lower()  # experiment: also strip punctuation?
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m02/e08-commit -->
```text
$ git commit -m "Compare normalized strings" metrics.py
[main b4e878b] Compare normalized strings
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git status --short
M  README.md
$ git show --format=%s HEAD
Compare normalized strings

diff --git a/metrics.py b/metrics.py
index 17d2823..83bbeda 100644
--- a/metrics.py
+++ b/metrics.py
@@ -1,5 +1,5 @@
 def exact_match(a, b):
-    return a == b
+    return normalize(a) == normalize(b)
 
 
 
@@ -8,4 +8,4 @@ def exact_match(a, b):
 
 
 def normalize(s):
-    return s
+    return s.strip().lower()  # experiment: also strip punctuation?
```
<!-- /snippet -->

1. `git commit <path>` records the **working tree** content of the named paths, on top of HEAD, and ignores what was staged for other paths. So the whole of `metrics.py` went in, experiment included, and the hunk selection made with `git add -p` was overwritten in the index by the full file. The README stayed staged and uncommitted, as the status shows.
2. The commit is private, so take it back with a soft reset and build it again from the index:

<!-- snippet: ex1/ex-m02/e08-redo -->
```text
# The commit is private, so it can be taken back and made again from the index.
$ git reset -q --soft HEAD~1
$ git restore --staged README.md metrics.py
$ printf 'y\nn\n' | git add -p metrics.py > /dev/null
$ git commit -q -m "Compare normalized strings"
$ git show --stat --format=%s HEAD
Compare normalized strings

 metrics.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git add README.md
$ git status --short
M  README.md
 M metrics.py
```
<!-- /snippet -->

🟡 `git reset --soft HEAD~1` moves the branch and leaves index and working tree alone. `--mixed` would also work here (the next step unstages anyway). `--hard` would be wrong: it would overwrite the working tree and destroy the experiment. After the redo, the commit has one changed line, the experiment is an unstaged modification, and the README is staged for later.

3. Plain `git commit`, after unstaging the README (`git restore --staged README.md`). To commit the staged content, name no path.

**Reasoning.** Two commit forms read the working tree at commit time and thereby bypass the staging you did: `git commit -a` and `git commit <path>`. Both are convenient exactly when nothing was staged selectively.

**Common mistakes.** Reading `git commit <path>` as "commit the staged part of this path". Repairing with `git commit --amend` after editing the experiment out of the file, which loses the experiment. Not checking `git show --stat HEAD` after a commit that was supposed to be partial.

**Expert approach.** After `git add -p`, the only safe commit is the one without arguments, and `git diff --cached` beforehand shows it. `git commit --dry-run <path>` would have shown the surprise in advance.

**Reference.** Chapter 5, sections 5.5 and 5.10; Chapter 11, section 11.4.

### Solution 2.9: "Git does not see my edits"

**Solution.** Two per-entry bits in the index tell Git not to look at the files: `skip-worktree` on the two configuration files and `assume-unchanged` on `agreement.py`.

<!-- snippet: ex1/solve-m02-invisible-edit/01-symptom -->
```text
$ cd annotator
$ git status
On branch main
nothing to commit, working tree clean
$ git diff
$ cat configs/eval.yaml
agreement_threshold: 0.90
min_annotators: 2
$ git show HEAD:configs/eval.yaml
agreement_threshold: 0.8
min_annotators: 2
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m02-invisible-edit/02-evidence -->
```text
# Not ignored: the paths are tracked, and no ignore rule matches them.
$ git ls-files configs annotator
annotator/agreement.py
configs/eval.yaml
configs/local.yaml
$ git check-ignore -v configs/eval.yaml annotator/agreement.py
[exit status: 1]
# The index is asked about its per-entry bits.
$ git ls-files -v
H README.md
h annotator/agreement.py
S configs/eval.yaml
S configs/local.yaml
```
<!-- /snippet -->

`git check-ignore` exits with status 1: no ignore rule is involved, and ignore rules would not affect tracked files in any case. `git ls-files -v` prints a tag per entry: `H` is a normal entry, a lower-case `h` has the assume-unchanged bit, `S` has the skip-worktree bit.

<!-- snippet: ex1/solve-m02-invisible-edit/03-repair -->
```text
$ git update-index --no-skip-worktree configs/eval.yaml
$ git update-index --no-assume-unchanged annotator/agreement.py
$ git ls-files -v
H README.md
H annotator/agreement.py
H configs/eval.yaml
S configs/local.yaml
$ git status --short
 M annotator/agreement.py
 M configs/eval.yaml
$ git diff
diff --git a/annotator/agreement.py b/annotator/agreement.py
index a3ec7ac..0be4f19 100644
--- a/annotator/agreement.py
+++ b/annotator/agreement.py
@@ -1,3 +1,5 @@
 def agreement(votes):
+    if not votes:
+        return 0.0
     top = max(set(votes), key=votes.count)
     return votes.count(top) / len(votes)
diff --git a/configs/eval.yaml b/configs/eval.yaml
index 385811b..b288644 100644
--- a/configs/eval.yaml
+++ b/configs/eval.yaml
@@ -1,2 +1,2 @@
-agreement_threshold: 0.8
+agreement_threshold: 0.90
 min_annotators: 2
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m02-invisible-edit/04-commit -->
```text
$ git add configs/eval.yaml annotator/agreement.py
$ git commit -m "Raise agreement threshold to 0.90 and guard empty votes"
[main 21e7944] Raise agreement threshold to 0.90 and guard empty votes
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git status --short
$ git diff HEAD --stat -- configs/local.yaml
$ cat configs/local.yaml
cache_dir: /Users/asha/.cache/annotator
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m02-invisible-edit/05-check -->
```text
$ cd ..
$ exercises/gen/m02-invisible-edit/check.sh
Checking exercise m02-invisible-edit
  ok    the committed configs/eval.yaml has the threshold 0.90
  ok    the committed agreement.py guards the empty vote list
  ok    the committed configs/local.yaml still has the shared default
  ok    the laptop path is still in the working copy of configs/local.yaml
  ok    no assume-unchanged or skip-worktree bit is left on the shared files
  ok    the working copy of eval.yaml equals the committed one
  ok    the working copy of agreement.py equals the committed one
  ok    the two original commits are still the base of the history
PASS: exercise m02-invisible-edit is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.**

```text
Observed behavior : edited tracked files; status clean, diff empty, "nothing to commit".
Git state         : index entries of the files carry the assume-unchanged or skip-worktree bit.
Mechanism         : with either bit set, Git does not compare the working tree file with the
                    index entry. Status, diff, add and commit -a all skip the path.
Root cause        : the bits were set months ago to "make Git ignore local tweaks" and were
                    forgotten. They are local to this index and invisible in every normal view.
Why Git does this : assume-unchanged is a performance promise ("I will not change this file");
                    skip-worktree belongs to sparse checkouts. Neither is an ignore mechanism.
Correct fix       : clear the bits (--no-skip-worktree, --no-assume-unchanged), then stage
                    and commit as usual.
Prevention        : never use these bits for configuration. Commit a template and ignore the
                    per-machine copy.
```

`configs/local.yaml` keeps its bit in the model solution because the task says its local value must not be committed, and clearing the bit would put a permanent ` M` into every status. That is a stopgap you must be able to justify, not a design: the next checkout that changes the tracked file will collide with the hidden edit. The sound arrangement is a tracked `configs/local.example.yaml` and an ignored `configs/local.yaml`.

**Common mistakes.** Cloning afresh and copying the files over: it works, because the bits live in the old index, and it teaches nothing. Suspecting `.gitignore` and stopping there. Suspecting index corruption without evidence. Clearing only one kind of bit: the two have different options.

**Expert approach.** When Git and the disk disagree about a tracked file, ask the index: `git ls-files -v | grep -v '^H'`. In a team, search for the habit as well as the instance, since the blog advice that caused this is widespread.

**Reference.** Chapter 5, sections 5.11 and 5.12; Chapter 4, section 4.6.

---

## Module 3: Commits

### Solution 3.1: read a commit field by field

**Solution.**

<!-- snippet: ex1/ex-m03/e01-read -->
```text
$ git init -q batch-scorer
$ cd batch-scorer
$ printf 'def score(batch):\n    return [len(x) for x in batch]\n' > scorer.py
$ git add scorer.py
$ git commit -q -m "Add batch scorer"
$ printf 'def score(batch):\n    return [len(x.strip()) for x in batch]\n' > scorer.py
$ git commit -q -am "Ignore surrounding whitespace when scoring"
$ git cat-file -p HEAD
tree a467ccfa46699e618f770cdca2e1bbad9fb2e226
parent 67a89f105fd1ee60ca82c22113d1c648b948fe88
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530

Ignore surrounding whitespace when scoring
$ git rev-parse HEAD "HEAD^{tree}" HEAD~1
e03aa34151ae7f2db71bd3f501abe1b5de384d54
a467ccfa46699e618f770cdca2e1bbad9fb2e226
67a89f105fd1ee60ca82c22113d1c648b948fe88
$ git show -s --format=fuller HEAD
commit e03aa34151ae7f2db71bd3f501abe1b5de384d54
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:08:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:08:00 2026 +0530

    Ignore surrounding whitespace when scoring
```
<!-- /snippet -->

| Line of the commit object | Meaning | Refers to |
|---|---|---|
| `tree a467ccf...` | The snapshot: the root directory of the project at this commit | A tree object |
| `parent 67a89f1...` | The commit this one was made on top of | A commit object |
| `author ... 1788755880 +0530` | Who wrote the change, when (seconds since 1970), in which time zone | A person; nothing in Git |
| `committer ...` | Who created this commit object, and when | A person; nothing in Git |
| empty line, then the message | Free text; the first line is the title | Nothing |

The three IDs printed by `git rev-parse` are, in order: the commit's own ID (which appears nowhere inside the object, it is the hash of the object), the `tree` line, and the `parent` line.

In the `--format=fuller` output the first line, `commit e03aa34...`, is not stored in the object: Git computed it. The dates are stored as a number and an offset and are formatted for display.

**Reasoning.** A commit is a small text object: one tree, zero or more parents, two identities with times, a message. It contains no file names, no file content and no diff. Whatever looks like a diff in `git show` is computed by comparing this commit's tree with its parent's tree.

**Common mistakes.** Looking for the changed lines inside the commit object. Thinking the commit ID is a serial number or is stored in the commit. Assuming author and committer are always the same because they usually are.

**Expert approach.** `git cat-file -p` is the ground truth when two tools disagree about a commit. Since the ID is the hash of exactly this text, any change to any line, including one second on a date, gives another commit.

**Reference.** Chapter 6, sections 6.2, 6.4 and 6.12.

### Solution 3.2: author and committer

**Solution.**

<!-- snippet: ex1/ex-m03/e02-author -->
```text
$ printf 'def mean(xs):\n    return sum(xs) / len(xs)\n' > stats.py
$ git add stats.py
$ git commit -q --author='Asha Rao <asha@example.com>' --date='2026-09-01T09:00:00+05:30' -m 'Add mean helper'
$ git show -s --format=fuller HEAD
commit 98a743c8b9df6bb8d0f821087a5981b9f8c6fbc4
Author:     Asha Rao <asha@example.com>
AuthorDate: Tue Sep 1 09:00:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:14:00 2026 +0530

    Add mean helper
$ git log --format='%h | author %an, %ad | committer %cn, %cd' --date=short
98a743c | author Asha Rao, 2026-09-01 | committer Lab User, 2026-09-07
e03aa34 | author Lab User, 2026-09-07 | committer Lab User, 2026-09-07
67a89f1 | author Lab User, 2026-09-07 | committer Lab User, 2026-09-07
$ git log --oneline --author=Asha
98a743c Add mean helper
$ git log --oneline --committer=Asha
```
<!-- /snippet -->

The author is Asha Rao with the date 1 September; the committer is Lab User with the date of the commit command, 7 September. `--author=Asha` finds the commit, `--committer=Asha` finds nothing: Asha wrote the change and never created a commit object in this repository.

Operations that produce differing author and committer without `--author`: `git cherry-pick` and `git rebase` (the author is kept, the person who runs the command becomes committer with a new date), `git am` (applying a mailed patch), and `git commit --amend` on someone else's commit.

**Reasoning.** The author field answers "whose change is this", the committer field answers "who put this object into history, and when". Git keeps the author stable through every rewrite so that credit survives; the committer changes whenever a new commit object has to be created.

**Common mistakes.** Using `--date` and expecting the committer date to change too. Counting contributions with `git log --author` and concluding that someone "did nothing" in a week in which they rebased and landed other people's work. Believing that `--author` is authenticated: anyone can type any name (Chapter 14B, section 14B.18).

**Expert approach.** Use `--format=fuller` whenever time or attribution matters. In an audit, quote both fields and say which one your statement rests on.

**Reference.** Chapter 6, section 6.5.

### Solution 3.3: zero, one and two parents

**Solution.**

<!-- snippet: ex1/ex-m03/e03-parents -->
```text
$ git switch -q -c feature/median
$ printf 'def median(xs):\n    return sorted(xs)[len(xs) // 2]\n' >> stats.py
$ git commit -q -am "Add median helper"
$ git switch -q main
$ git merge -q --no-ff -m "Merge feature/median" feature/median
$ git log --graph --oneline
*   e9a3166 Merge feature/median
|\  
| * d4caefb Add median helper
|/  
* 98a743c Add mean helper
* e03aa34 Ignore surrounding whitespace when scoring
* 67a89f1 Add batch scorer
$ git rev-list --parents -n 1 HEAD
e9a316647433ba8c8c72ec1aac5813c110eb4b23 98a743c8b9df6bb8d0f821087a5981b9f8c6fbc4 d4caefbf84e8079f2aa855185c9c6d071921aa15
$ git rev-list --parents -n 1 HEAD~1
98a743c8b9df6bb8d0f821087a5981b9f8c6fbc4 e03aa34151ae7f2db71bd3f501abe1b5de384d54
$ git rev-list --parents -n 1 --max-parents=0 HEAD
67a89f105fd1ee60ca82c22113d1c648b948fe88
$ git show -s --format=%s HEAD^1
Add mean helper
$ git show -s --format=%s HEAD^2
Add median helper
```
<!-- /snippet -->

- HEAD has two parents: a merge commit.
- `HEAD~1` has one parent: an ordinary commit.
- The commit found with `--max-parents=0` has none: the root commit.

`HEAD^2` is the **second parent** of HEAD, the tip of the branch that was merged in ("Add median helper"). `HEAD~2` is the **first parent of the first parent**, two steps back along `main` ("Ignore surrounding whitespace when scoring"). On a history without merges `HEAD~2` works as long as there are two ancestors, and `HEAD^2` is an error, because no commit has a second parent.

**Reasoning.** `~n` walks n generations along first parents. `^n` selects the n-th parent of one commit. `HEAD^1` and `HEAD~1` are the same commit; from 2 on they diverge. The order of the parents of a merge is fixed at merge time: first the branch you were on, second the branch you named.

**Common mistakes.** Reading `^2` as "two commits back". Assuming the first parent is "the older one". Forgetting that `git log --first-parent` depends on that order.

**Expert approach.** Say "first-parent history" when you mean "what happened on `main`", and check parent order before reverting a merge, where `-m 1` means "keep the first parent's side" (Chapter 11, section 11.9).

**Reference.** Chapter 6, section 6.6; Chapter 14A, section 14A.7.

### Solution 3.4: a commit that changes nothing

**Solution.**

<!-- snippet: ex1/ex-m03/e04-answer -->
```text
$ git rev-parse "HEAD^{tree}" "HEAD~1^{tree}"
512d7f6472b0ca081e381fb4703e8cc34f32b141
512d7f6472b0ca081e381fb4703e8cc34f32b141
$ git show --stat --format="%h %s" HEAD
e726eea Trigger a re-run of the nightly evaluation
$ git diff --quiet HEAD~1 HEAD
[exit status: 0]
$ git rev-list --count HEAD
2
$ find .git/objects -type f | wc -l | tr -d ' '
4
```
<!-- /snippet -->

1. The tree IDs are equal.
2. Nothing: there is no stat block, because the diff against the parent is empty.
3. Exit status 0: no difference.
4. Four object files: one blob, one tree, two commits.

**Reasoning.** The empty commit is one new object, a commit whose `tree` line names the same tree as its parent. It still has its own ID because its parent line, its dates and its message differ from those of every other commit. `--allow-empty` exists because `git commit` normally refuses to record a commit whose tree equals the parent's.

**Common mistakes.** Predicting a new tree object. Calling an empty commit "invalid". Using empty commits as a habit to re-trigger CI where the platform offers a re-run: each one is permanent history.

**Expert approach.** An empty commit is a legitimate marker (the start of a branch for an early pull request, a deliberate trigger). The same fact, "a new commit can reuse an existing tree", explains why reverting to an old state costs one object.

**Reference.** Chapter 6, sections 6.3, 6.4 and 6.8.

### Solution 3.5: which date is shown, which date filters?

**Solution.**

<!-- snippet: ex1/ex-m03/e05-answer -->
```text
$ git log -1
commit ed17ed1307ef02d813902b5cfce9277fc2394844
Author: Lab User <you@example.com>
Date:   Sat Aug 1 12:00:00 2026 +0000

    Backdated work
$ git log -1 --format='author date:    %ad%ncommitter date: %cd'
author date:    Sat Aug 1 12:00:00 2026 +0000
committer date: Mon Sep 7 10:45:00 2026 +0530
$ git log --oneline --since=2026-08-15
ed17ed1 Backdated work
$ git log --oneline --until=2026-08-15
```
<!-- /snippet -->

1. `git log` prints the **author date**: 1 August.
2. `--since=2026-08-15` lists the commit.
3. `--until=2026-08-15` does not.

The rule: `git log` displays the author date and selects by the **committer date**. The commit displays 1 August and counts as created on the day the command ran.

**Reasoning.** The author date is for people and survives every rebase and cherry-pick. The committer date is what Git's history walk relies on, and what tells you when a commit object came into being.

A report that this distorts: after a branch is rebased, all its commits have the rebase day as committer date. "Commits since Monday" then counts weeks of work as this week's, while the dates printed next to them are old.

**Common mistakes.** Assuming one date per commit. Filtering with `--since` and presenting the displayed dates as the selection criterion. "Fixing" history order by backdating with `--date`, which changes only the author date.

**Expert approach.** For any time-based query, decide which question is being asked, "when was this written" or "when did this arrive", and print the matching field explicitly with `%ad` or `%cd`.

**Reference.** Chapter 6, section 6.5.

### Solution 3.6: two atomic commits and a trailer

**Solution.**

<!-- snippet: ex1/ex-m03/e06-before -->
```text
$ git status --short
 M README.md
 M retry.py
$ git diff --stat
 README.md | 4 ++++
 retry.py  | 1 +
 2 files changed, 5 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m03/e06-commits -->
```text
$ git add retry.py
$ git commit -q -m 'Raise TimeoutError when every attempt timed out' -m 'retry() returned None after the last failed attempt, so callers treated a timeout as an empty result.' --trailer 'Co-authored-by: Asha Rao <asha@example.com>'
$ git add README.md
$ git commit -q -m 'Document how to run the tests'
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m03/e06-verify -->
```text
$ git log --stat --format="--- %h %s" -2
--- 6b17c3f Document how to run the tests

 README.md | 4 ++++
 1 file changed, 4 insertions(+)
--- 0588b86 Raise TimeoutError when every attempt timed out

 retry.py | 1 +
 1 file changed, 1 insertion(+)
$ git log -1 --format=%B HEAD~1
Raise TimeoutError when every attempt timed out

retry() returned None after the last failed attempt, so callers treated a timeout as an empty result.

Co-authored-by: Asha Rao <asha@example.com>

$ git log -1 --format="%(trailers:key=Co-authored-by,valueonly)" HEAD~1
Asha Rao <asha@example.com>
```
<!-- /snippet -->

**Reasoning.** The two changes are in two files, so `git add <file>` separates them; had they been in one file, `git add -p` would. Each `-m` becomes one paragraph. `--trailer` places the line in the last paragraph of the message, which is the only place where Git's trailer parser looks, and the `%(trailers:...)` placeholder proves that it was recognized.

**Common mistakes.** One commit titled "Fix retry and update docs": it cannot be reverted or backported without dragging the other change along. Typing the trailer by hand into the middle of the body, where tools do not find it. A title in the past tense or longer than a `git log --oneline` line can show. A body that repeats what the diff says and omits why.

**Expert approach.** The test for an atomic commit is a question: "could I revert this commit alone, and would the result still be consistent?" Write the body for the engineer who runs `git blame` on this line in a year.

**Reference.** Chapter 6, sections 6.9 and 6.10.

### Solution 3.7: one ahead, one behind, and nobody else pushed

**Solution.** The commit you are behind is your own earlier commit. You amended it after pushing.

<!-- snippet: ex1/ex-m03/e07-diagnosis -->
```text
$ git reflog -3
a0939f2 HEAD@{0}: commit (amend): Add maximum batch size
ed78368 HEAD@{1}: commit: Add maximum batch sise
fcf77d2 HEAD@{2}: commit (initial): Add pass mark
$ git rev-parse 'HEAD^{tree}' 'origin/main^{tree}'
b0894f8458ae12d02b3b844e335d52664a4c55f7
b0894f8458ae12d02b3b844e335d52664a4c55f7
$ git log --format="%h %an %ad | %cd | %s" --date=format:%H:%M HEAD -1
a0939f2 Lab User 11:08 | 11:10 | Add maximum batch size
$ git log --format="%h %an %ad | %cd | %s" --date=format:%H:%M origin/main -1
ed78368 Lab User 11:08 | 11:08 | Add maximum batch sise
```
<!-- /snippet -->

1. `git commit --amend`. The reflog names it: `commit (amend)`. An amend does not edit a commit. It creates a new commit with the same parent and moves the branch to it. The pushed commit stays on the server and in `origin/main`, so the two are siblings: one ahead, one behind.
2. The same files: only the message was corrected. The check is the comparison of the two tree IDs, which are equal. The author date is kept and the committer date is new, as the last two commands show.
3. `git pull` would merge the two siblings: a merge commit that joins two versions of one change, with both titles in the history for ever.
4. (a) Somebody may have the pushed commit: return to it and leave it alone.

<!-- snippet: ex1/ex-m03/e07-fix-shared -->
```text
# If anyone may already have the pushed commit: go back to it and keep the message as it is.
$ git reset --soft '@{u}'
$ git status -sb
## main...origin/main
$ git log --oneline --graph --all
* ed78368 Add maximum batch sise
* fcf77d2 Add pass mark
```
<!-- /snippet -->

`git reset --soft '@{u}'` moves the branch back to the pushed commit and keeps index and working tree. Here nothing remains to commit, because the amend changed only the message: a typo in a published title stays. Had the amend changed files, the difference would now be staged, ready for a new, additional commit.

(b) The branch is provably yours alone: replace the pushed commit deliberately with 🔴 `git push --force-with-lease` (Chapter 12, section 12.8). What decides is whether anyone else can have fetched the commit. A protected `main` answers the question for you.

**Reasoning.** `[ahead 1, behind 1]` right after your own work, with nobody else pushing, is the signature of rewritten published history. The graph shows two commits with one parent.

**Common mistakes.** Following the hint and pulling. Forcing the push on a shared branch "because it is my own commit". Taking the rejected push for a server problem.

**Expert approach.** Amend only what is unpublished; check `git status -sb` before amending. When the evidence is two sibling commits, read the reflog before touching anything, and state the private-or-shared decision aloud.

**Reference.** Chapter 6, sections 6.7 and 6.13; Chapter 11, section 11.2.

### Solution 3.8: the commit that `--author` does not find

**Solution.**

<!-- snippet: ex1/ex-m03/e08-answer -->
```text
$ git log --format='%h  author: %an  committer: %cn  %s'
e6d3501  author: Lab User  committer: Lab User  Add README
23cd6fe  author: Ravi Menon  committer: Asha Rao  Allow a burst above the quota
161cdd6  author: Lab User  committer: Lab User  Add quota
$ git log --oneline --committer=Asha
23cd6fe Allow a burst above the quota
$ git show -s --format=fuller HEAD~1
commit 23cd6fe0cc266867731ea7a69859507574f7ddcd
Author:     Ravi Menon <ravi@example.com>
AuthorDate: Fri Sep 4 18:20:00 2026 +0530
Commit:     Asha Rao <asha@example.com>
CommitDate: Mon Sep 7 11:24:00 2026 +0530

    Allow a burst above the quota
```
<!-- /snippet -->

1. Ravi wrote the change on Friday; Asha created the commit object on Monday, for example by applying his patch or cherry-picking his commit. Ravi is the author, Asha the committer.
2. `git log --committer=Asha` answers "which commits did Asha put into this history". `git show -s --format=fuller <commit>` shows both people and both dates.
3. `--since` and `--until` use the committer date. For "what arrived on `main` last week" that is the right one: the change was written on Friday and arrived on Monday.

**Reasoning.** `--author` and `--committer` filter on two different header lines of the commit object. A question about who **landed** something is a committer question; a question about who **wrote** it is an author question.

**Common mistakes.** Answering an audit from `--author` alone. Reading the `Date:` line of plain `git log` as the landing time. Treating either field as proof of identity; without a signature both are text typed by whoever made the commit.

**Expert approach.** Say which layer your answer comes from. The commit fields tell you who wrote a change and who created the commit object. Who approved a pull request and who pressed its merge button are facts in GitHub's database, not in Git's objects (Chapter 1, section 1.5), so an audit of "who merged" needs the platform's record as well.

**Reference.** Chapter 6, section 6.5; Chapter 14A, section 14A.9.

### Solution 3.9: a commit made on the meeting-room laptop

**Solution.**

<!-- snippet: ex1/solve-m03-wrong-commit/01-observe -->
```text
$ cd scorer-service
$ git log --oneline
4231cad Add retry buget to the scoerr
80d6d35 Add retry helper
1efaece Add batch scorer
$ git show --stat --format=fuller HEAD
commit 4231cada2da80e42dcea6616bcbbfc00455a859f
Author:     Meeting Room 4 <room4@office.example>
AuthorDate: Mon Sep 7 10:07:00 2026 +0530
Commit:     Meeting Room 4 <room4@office.example>
CommitDate: Mon Sep 7 10:07:00 2026 +0530

    Add retry buget to the scoerr
    
    A batch is retried until the budget of the run is used up, so one slow model cannot hold the whole evaluation.
    
    Reviewed-by: Asha Rao <asha@example.com>

 configs/scorer.yaml | 1 +
 debug.log           | 3 +++
 scorer/retry.py     | 5 +++--
 3 files changed, 7 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m03-wrong-commit/02-private -->
```text
# Is the commit private? No remote, no upstream: nothing has left this repository.
$ git remote -v
$ git branch -vv
* main 4231cad Add retry buget to the scoerr
$ git var GIT_AUTHOR_IDENT
Ravi Menon <ravi@example.com> 1788756180 +0530
```
<!-- /snippet -->

No remote and no upstream: the commit exists in this repository only, so replacing it harms nobody. `git var GIT_AUTHOR_IDENT` confirms that the repository's configuration now supplies Ravi's identity; the wrong name came from the other machine's environment.

<!-- snippet: ex1/solve-m03-wrong-commit/03-repair -->
```text
$ git rm --cached debug.log
rm 'debug.log'
$ git status --short
D  debug.log
?? debug.log
$ git commit --amend --author='Ravi Menon <ravi@example.com>'
[main 0c96d5a] Add retry budget to the scorer
 Date: Mon Sep 7 10:07:00 2026 +0530
 2 files changed, 4 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

`git rm --cached debug.log` removes the file from the index and leaves it on disk; the status shows both facts (`D ` staged deletion, `??` untracked file). `git commit --amend --author=...` opens the editor with the old message, where the two words of the title are corrected and the body and trailer are left alone.

<!-- snippet: ex1/solve-m03-wrong-commit/04-verify -->
```text
$ git show --stat --format=fuller HEAD
commit 0c96d5a1ba19a963da475ea6198e41356a1f3ce8
Author:     Ravi Menon <ravi@example.com>
AuthorDate: Mon Sep 7 10:07:00 2026 +0530
Commit:     Ravi Menon <ravi@example.com>
CommitDate: Mon Sep 7 10:16:00 2026 +0530

    Add retry budget to the scorer
    
    A batch is retried until the budget of the run is used up, so one slow model cannot hold the whole evaluation.
    
    Reviewed-by: Asha Rao <asha@example.com>

 configs/scorer.yaml | 1 +
 scorer/retry.py     | 5 +++--
 2 files changed, 4 insertions(+), 2 deletions(-)
$ git status --short
?? debug.log
$ git log --oneline
0c96d5a Add retry budget to the scorer
80d6d35 Add retry helper
1efaece Add batch scorer
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m03-wrong-commit/05-old-commit -->
```text
$ git reflog -2
0c96d5a HEAD@{0}: commit (amend): Add retry budget to the scorer
4231cad HEAD@{1}: commit: Add retry buget to the scoerr
$ git show -s --format='%h %an <%ae> %s' 'HEAD@{1}'
4231cad Meeting Room 4 <room4@office.example> Add retry buget to the scoerr
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m03-wrong-commit/06-check -->
```text
$ cd ..
$ exercises/gen/m03-wrong-commit/check.sh
Checking exercise m03-wrong-commit
  ok    the corrected commit has the same parent as the original
  ok    the branch has exactly three commits
  ok    HEAD is on main
  ok    the author is Ravi Menon <ravi@example.com>
  ok    the author date is the original one
  ok    the title is corrected
  ok    the body is unchanged
  ok    the Reviewed-by trailer is still a trailer
  ok    debug.log is not in the commit
  ok    debug.log is still in the working tree
  ok    debug.log is not staged either
  ok    scorer/retry.py is committed as before
  ok    configs/scorer.yaml is committed as before
  ok    no tracked file differs from the commit
PASS: exercise m03-wrong-commit is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.** Field by field, old commit against new:

| Field | Changed? | Why |
|---|---|---|
| tree | yes | `debug.log` is no longer in it |
| parent | no | an amend keeps the parent |
| author name and email | yes | `--author` |
| author date | no | `--author` replaces the identity and keeps the date |
| committer name and email | yes | taken from the current identity |
| committer date | yes | the time of the amend |
| message | yes | title corrected |

Any one of these changes would have been enough for a new ID. The old commit `4231cad` is unreachable from every branch and still reachable from the reflog (`HEAD@{1}`). With default settings a reflog entry for an unreachable commit is kept for 30 days, after which garbage collection may delete the commit. The lab configuration switches that expiry off.

**Common mistakes.** `git commit --amend --reset-author`: it sets the right person and also resets the author date to now, which the task forbids. `git commit --amend -m "..."`: it replaces the whole message and drops the body and the `Reviewed-by` trailer. `git rm debug.log` without `--cached`: it deletes the file Ravi still needs. Making a second commit that "removes debug.log": the file would stay in history.

**Expert approach.** First establish that the commit is private, then fix everything in one amend, then compare with `git show --format=fuller --stat`. If the file had contained a secret and the commit had been pushed, the amend would not be the end of the story (Chapter 21B).

**Reference.** Chapter 6, sections 6.5, 6.7 and 6.13; Chapter 4, section 4.6; Chapter 13, section 13.4.

---

## Module 4: Refs, branches, HEAD

### Solution 4.1: a branch, and the file behind each step

**Solution.**

<!-- snippet: ex1/ex-m04/e01-branch -->
```text
$ git init -q model-router
$ cd model-router
$ printf 'routes:\n  default: small\n' > routes.yaml
$ git add routes.yaml
$ git commit -q -m "Add default route"
$ git branch feature/fallback
$ git branch -v
  feature/fallback 41c8c3c Add default route
* main             41c8c3c Add default route
$ cat .git/refs/heads/feature/fallback
41c8c3c7d00a878752561ff02369870cddad0131
$ git rev-parse main
41c8c3c7d00a878752561ff02369870cddad0131
$ git branch -m feature/fallback feature/fallback-route
$ find .git/refs/heads -type f | sort
.git/refs/heads/feature/fallback-route
.git/refs/heads/main
$ git branch -d feature/fallback-route
Deleted branch feature/fallback-route (was 41c8c3c).
$ find .git/refs/heads -type f | sort
.git/refs/heads/main
```
<!-- /snippet -->

- `git branch feature/fallback` created one file, `.git/refs/heads/feature/fallback`, containing the ID of the commit HEAD names. No object was written, HEAD did not move, index and working tree are untouched.
- `git branch -m` renamed that file (and its reflog).
- `git branch -d` deleted it, and printed the ID it held: `Deleted branch ... (was 41c8c3c)`.

Creating the branch copied no project data at all. The cost is 41 bytes: forty hexadecimal digits and a newline.

**Reasoning.** A branch is a ref: a name for one commit. Everything a branch seems to "contain" is what is reachable from that commit by following parents. Two branches on the same commit share every object.

**Common mistakes.** Thinking that a new branch copies the files or the history. Expecting `git branch <name>` to switch to it. Ignoring the `(was ...)` in the deletion message: it is the fastest way back if the deletion was a mistake (`git branch <name> <ID>`).

**Expert approach.** Since branches cost nothing, create one before anything risky: `git branch backup/before-rebase` is a complete backup of the current history.

**Reference.** Chapter 7, sections 7.2 and 7.5.

### Solution 4.2: HEAD follows you

**Solution.**

<!-- snippet: ex1/ex-m04/e02-head -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git switch -c fix/timeout
Switched to a new branch 'fix/timeout'
$ cat .git/HEAD
ref: refs/heads/fix/timeout
$ printf 'routes:\n  default: small\ntimeout_s: 30\n' > routes.yaml
$ git commit -q -am "Add request timeout"
$ git branch -v
* fix/timeout 5c94420 Add request timeout
  main        41c8c3c Add default route
$ git switch -
Switched to branch 'main'
$ git symbolic-ref HEAD
refs/heads/main
$ git rev-parse --abbrev-ref HEAD '@{-1}'
main
fix/timeout
$ git branch -v
  fix/timeout 5c94420 Add request timeout
* main        41c8c3c Add default route
```
<!-- /snippet -->

`.git/HEAD` is `ref: refs/heads/main`, then `ref: refs/heads/fix/timeout` after `git switch -c`, then `ref: refs/heads/main` again. The commit moved `fix/timeout`, the branch HEAD named at that moment, and left `main` where it was, as the two `git branch -v` listings show. `git switch -` returns to the previous branch, and `@{-1}` is the revision syntax for "the branch I was on before this one".

Git knows the previous branch from the reflog of HEAD: every switch is recorded there as `checkout: moving from <a> to <b>`.

**Reasoning.** HEAD is a symbolic ref: it holds the name of a branch, not a commit ID. `git commit` writes the new commit ID into whatever ref HEAD names. That indirection is the whole mechanism by which "the current branch advances".

**Common mistakes.** Describing HEAD as "the latest commit". Thinking that a commit moves "the branch it was created from". Parsing `git branch` output in scripts to find the current branch: use `git symbolic-ref --short HEAD` or `git branch --show-current`.

**Expert approach.** Before a command that moves refs, ask: "which ref does HEAD name right now?" `git status -sb` answers in its first line.

**Reference.** Chapter 7, sections 7.3, 7.4 and 7.6.

### Solution 4.3: a lightweight tag is a ref that does not move

**Solution.**

<!-- snippet: ex1/ex-m04/e03-tag -->
```text
$ git tag v0.1.0
$ cat .git/refs/tags/v0.1.0
41c8c3c7d00a878752561ff02369870cddad0131
$ printf '# model-router\n' > README.md
$ git add README.md
$ git commit -q -m "Add README"
$ git rev-parse v0.1.0 main
41c8c3c7d00a878752561ff02369870cddad0131
8db47ce8906113e87d593fac7a8fc0dd09ea9db8
$ git log --oneline --decorate --all
8db47ce (HEAD -> main) Add README
5c94420 (fix/timeout) Add request timeout
41c8c3c (tag: v0.1.0) Add default route
$ git cat-file -t v0.1.0
commit
```
<!-- /snippet -->

After the commit, `main` names the new commit and `v0.1.0` still names the old one. `git cat-file -t v0.1.0` says `commit`: a lightweight tag is a ref under `refs/tags/` that points straight at a commit, with no object of its own.

The one behavioral difference: HEAD can name a branch, and `git commit` advances the ref HEAD names. HEAD never names a tag (switching to a tag detaches HEAD), so no commit ever advances one.

**Reasoning.** Both are files with one commit ID. The difference is not in the files and lies in which commands write to them: `git commit`, `git merge`, `git rebase` and `git reset` update the current branch; only `git tag` writes under `refs/tags/`.

**Common mistakes.** Believing tags are "immutable" in Git: a tag can be moved with `git tag -f`, and the reason not to is social and operational (Chapter 14B, section 14B.11). Giving `git rev-parse --short` two revisions: the run showed that it accepts a single one, so the model run prints full IDs. Giving a tag and a branch the same name (Exercise 4.8).

**Expert approach.** Use lightweight tags for private bookmarks and annotated tags for releases, which carry a tagger, a date and a message of their own.

**Reference.** Chapter 7, section 7.11; Chapter 14B, section 14B.8.

### Solution 4.4: a commit made while HEAD was detached

**Solution.**

<!-- snippet: ex1/ex-m04/e04-setup -->
```text
$ git init -q detached
$ cd detached
$ git commit -q --allow-empty -m A
$ git commit -q --allow-empty -m B
$ git commit -q --allow-empty -m C
$ git switch -q --detach HEAD~1
$ git commit -q --allow-empty -m X
$ git switch main
Warning: you are leaving 1 commit behind, not connected to
any of your branches:

  666a367 X

If you want to keep it by creating a new branch, this may be a good time
to do so with:

 git branch <new-branch-name> 666a367

Switched to branch 'main'
```
<!-- /snippet -->

<!-- snippet: ex1/ex-m04/e04-answer -->
```text
$ git log --graph --oneline --all
* 22d270f C
* ebd608b B
* 197466b A
$ git reflog -3
22d270f HEAD@{0}: checkout: moving from 666a36736bf593db9a19f32c4033f89b1e49b46c to main
666a367 HEAD@{1}: commit: X
ebd608b HEAD@{2}: checkout: moving from main to HEAD~1
```
<!-- /snippet -->

1. The graph shows `A`, `B`, `C` in a line. `X` is not in it. `--all` means "start from all refs", and no ref names `X`.
2. `X` is in the object database. Its ID is in the warning that `git switch main` printed and in the reflog of HEAD (`HEAD@{1}`).
3. One ref brings it back into view:

<!-- snippet: ex1/ex-m04/e04-keep -->
```text
$ git branch keep/x 'HEAD@{1}'
$ git log --graph --oneline --all
* 666a367 X
| * 22d270f C
|/  
* ebd608b B
* 197466b A
```
<!-- /snippet -->

**Reasoning.** With a detached HEAD, `.git/HEAD` holds a commit ID. A commit made in that state updates HEAD itself and no branch. When HEAD moves away, the commit is reachable from the reflog only.

**Common mistakes.** Drawing `X` in the first graph. Reading the warning as an error, or not reading it at all. Thinking a detached HEAD is a broken state: it is the normal state while you look at a tag, bisect, or rebase.

**Expert approach.** Committing with a detached HEAD is fine for experiments; the discipline is to name the result before leaving, with `git switch -c <name>`. If you already left, `git reflog` has the ID for as long as reflog entries live (90 days by default, 30 for commits that no branch reaches; Chapter 13, section 13.4).

**Reference.** Chapter 7, section 7.7.

### Solution 4.5: which branches may be deleted?

**Solution.**

<!-- snippet: ex1/ex-m04/e05-answer -->
```text
$ git branch --merged main
  done-1
  done-2
* main
$ git branch --no-merged main
  open-1
$ git branch -d done-1 done-2 open-1
error: the branch 'open-1' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D open-1'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
Deleted branch done-1 (was 54cf522).
Deleted branch done-2 (was 60ac6ca).
[exit status: 1]
$ git branch
* main
  open-1
$ git log --graph --oneline --all
* 5e29cab B
| * e431c64 O1
|/  
* 60ac6ca D2
* 54cf522 A
```
<!-- /snippet -->

`done-1` and `done-2` are merged into `main`; `open-1` is not. The command deletes the first two, refuses the third with `error: the branch 'open-1' is not fully merged`, and exits with status 1.

The test: `git branch -d` deletes a branch only if its tip is reachable from HEAD (or from the branch's upstream, when it has one). `done-1` points at `A`, an ancestor of `main`, although no merge command was ever run for it. `done-2` was fast-forwarded into `main`. `O1` is reachable from `open-1` only.

**Reasoning.** "Merged" means "is an ancestor". It says nothing about whether a merge commit exists or whether the content arrived by another route. The refusal protects the commits that would become unreachable.

**Common mistakes.** Predicting that the whole command fails and deletes nothing: each branch is handled on its own. Believing a branch must have been merged by a `git merge` to count. Answering the refusal with `-D` by reflex: 🟡 `-D` deletes without the test, and for a branch without upstream the commits are then reachable from the reflog only. Expecting `-d` to accept a branch whose content was squash-merged: its commits are not ancestors of `main`, so `-d` refuses (Exercise 6.5).

**Expert approach.** List before deleting: `git branch --merged main` is the safe set. For what remains, look with `git log --oneline main..<branch>` before deciding.

**Reference.** Chapter 7, sections 7.5, 7.8 and 7.13.

### Solution 4.6: from which branch was it created?

**Solution.**

<!-- snippet: ex1/ex-m04/e06-answer -->
```text
$ git log --graph --oneline --all
* 426bbd9 E
| * 3de192a D
| * 7184451 C
|/  
* 7c21098 B
* 11b9fd4 A
```
<!-- /snippet -->

```text
        C            feature/a, feature/c
       / \
      /   D          feature/b
     /
A---B---E            main        (HEAD -> main)
```

<!-- snippet: ex1/ex-m04/e06-lineage -->
```text
$ git show -s --format=%s "$(git merge-base feature/b main)"
B
$ git show -s --format=%s "$(git merge-base feature/b feature/a)"
C
$ git reflog show feature/b
3de192a feature/b@{0}: commit: D
7184451 feature/b@{1}: branch: Created from HEAD
$ git reflog show feature/c
7184451 feature/c@{0}: branch: Created from feature/a
$ git config list --local | grep branch
```
<!-- /snippet -->

2. The graph answers: `feature/b` shares history with `main` up to `B` and with `feature/a` up to `C`. It cannot answer "created from which branch", because a commit records parents, not branch names. The reflog of `feature/b` says `branch: Created from HEAD`: it remembers the event, not the name. (For `feature/c`, created with an explicit start point, it says `Created from feature/a`.) The configuration holds nothing: the `grep` prints no line, because branches created from local branches get no upstream entry.
3. Neither is the original. Two refs with the same content are indistinguishable. For "original" to mean something, Git would have to store a parent-branch relation, and it stores none.

**Reasoning.** Branch names are not part of history. Once `feature/a` gains a commit or is deleted, even the graph forgets that `feature/b` ever had anything to do with it.

**Common mistakes.** Reading the graph layout as lineage ("it comes out of `feature/a`'s line"). Relying on the reflog for this: it is local, expires, and is missing in every other clone. Assuming a pull request's base branch is a Git property: it is chosen on GitHub.

**Expert approach.** When a tool needs "the base of this branch", make it explicit: compute `git merge-base <branch> main`, or record the intended base in the pull request. Do not infer it. Git 2.47 and later offer a heuristic, `%(is-base:<commit>)` in `git for-each-ref`; the book's advice is to treat it as a hint for humans and never as an input to automation (section 7.17).

**Reference.** Chapter 7, sections 7.8, 7.9 and 7.17.

### Solution 4.7: one switch carries the edit, the next one refuses

**Solution.**

<!-- snippet: ex1/ex-m04/e07-observed -->
```text
$ printf 'timeout_s: 60\n' > router.yaml
$ git switch exp/large-model
Switched to branch 'exp/large-model'
M	router.yaml
$ git switch main
Switched to branch 'main'
M	router.yaml
$ git restore router.yaml
$ printf 'model: medium\n' > model.yaml
$ git switch exp/large-model
error: Your local changes to the following files would be overwritten by checkout:
	model.yaml
Please commit your changes or stash them before you switch branches.
Aborting
[exit status: 1]
```
<!-- /snippet -->

1. `git switch` carries an uncommitted edit along when the edited file is **identical in the two commits** involved; it refuses when the file differs between them. `git diff --name-only main exp/large-model` lists the paths that differ: an edit to one of those blocks the switch.
2. `model.yaml` is `small` on `main` and `large` on the branch. Switching means writing the branch's version over the working tree file, and the uncommitted `medium` would be overwritten. It exists nowhere else.
3. Three ways: commit the edit (no risk; the commit can be amended or moved later); stash it and pop it after the switch (the pop can conflict, and a stash is soon forgotten); `git switch --merge`, which since Git 2.55 saves the edit in a stash, switches, and reapplies it: when it does not apply cleanly you have a conflict to resolve and a stash to look after (section 7.17). The model run takes the lowest risk for an experiment: a new branch at the current commit, which always carries the edit, and a commit.

<!-- snippet: ex1/ex-m04/e07-explain -->
```text
$ git diff --name-only main exp/large-model
model.yaml
$ git status --short
 M model.yaml
# Lowest risk: take the edit to a new branch that starts at the commit you are on.
$ git switch -c exp/medium-model
Switched to a new branch 'exp/medium-model'
$ git commit -q -am "Try the medium model"
$ git log --graph --oneline --all
* 3fb6b07 Try the medium model
| * 399cd05 Try the large model
|/  
* be8bccb Add configs
```
<!-- /snippet -->

**Reasoning.** A switch updates the files that differ between the old and the new commit and leaves all others alone. An edit in a file that the switch does not need to touch is safe; an edit in a file that it must rewrite is a collision, and Git stops before writing.

**Common mistakes.** Concluding that "Git sometimes loses changes when switching": it never overwrites a modified file silently in a switch. Using 🔴 `git switch --discard-changes` (or `git checkout -f`) to get past the message. Forgetting that the carried edit now sits in the working tree of a different branch.

**Expert approach.** Read the refusal as protection, and decide where the edit belongs before moving it. `git stash` is for minutes, a commit on a branch is for anything longer.

**Reference.** Chapter 7, sections 7.6 and 7.14.

### Solution 4.8: the deploy script that picks the wrong commit

**Solution.** A tag and a branch share the short name `release-1.0`.

<!-- snippet: ex1/ex-m04/e08-diagnosis -->
```text
$ git for-each-ref --format='%(refname) %(objectname:short) %(subject)'
refs/heads/main 262e673 Start 1.1
refs/heads/release-1.0 d794d7f Hotfix: clamp temperature
refs/tags/release-1.0 12c6b92 Release 1.0
$ git rev-parse refs/heads/release-1.0 refs/tags/release-1.0
d794d7fb6d2901ed15d25ed7f980a6d894eef28b
12c6b926837dd460b166d8cd0483cd0cadedd685
$ git rev-parse --short heads/release-1.0
d794d7f
```
<!-- /snippet -->

1. `git branch -v` lists `refs/heads/*` only, so it shows the branch, with the hotfix. `git rev-parse release-1.0` resolves a short name, finds two candidates, warns, and takes the tag. `git for-each-ref` lists everything the name could mean.
2. Git tries a short name as `refs/tags/<name>` before `refs/heads/<name>`. The spellings `heads/release-1.0` and `tags/release-1.0` (or the full `refs/heads/...`, `refs/tags/...`) are never ambiguous.
3. Give the tagged release commit an unambiguous name, then remove the colliding tag:

<!-- snippet: ex1/ex-m04/e08-fix -->
```text
$ git tag v1.0.0 refs/tags/release-1.0
$ git tag -d release-1.0
Deleted tag 'release-1.0' (was 12c6b92)
$ git rev-parse --short release-1.0
d794d7f
$ git for-each-ref --format='%(refname) %(objectname:short) %(subject)'
refs/heads/main 262e673 Start 1.1
refs/heads/release-1.0 d794d7f Hotfix: clamp temperature
refs/tags/v1.0.0 12c6b92 Release 1.0
```
<!-- /snippet -->

The released commit keeps a name (`v1.0.0`), the warning is gone, and the short name resolves to the branch. The script should ask for what it means: `git rev-parse --verify refs/heads/release-1.0`.

**Reasoning.** Ref names live in one namespace tree, and short names are a convenience resolved by a fixed search order. The warning went to standard error, where a deploy script that captures standard output never sees it.

**Common mistakes.** Deleting the tag without first giving the release commit another name. Believing that `git switch release-1.0` being unambiguous (it only considers branches) means every command is. If the tag was pushed, deleting it locally is half the job; the remote tag and other clones still have it (Chapter 14B, section 14B.10).

**Expert approach.** Keep tag names and branch names disjoint by convention (`v1.0.0` for tags, `release/1.0` for branches), and write full ref names in every script. A script must also fail on warnings it does not expect.

**Reference.** Chapter 7, sections 7.11, 7.12 and 7.14.

### Solution 4.9: three commits on the wrong branch

**Solution.**

<!-- snippet: ex1/solve-m04-wrong-branch/01-symptom -->
```text
$ cd you
$ git push
remote: main is protected: push a feature/<name> branch and open a pull request        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
$ git status -sb
## main...origin/main [ahead 3]
 M gateway/limits.py
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m04-wrong-branch/02-evidence -->
```text
$ git branch -vv
  feature/old-cache  1b81d0e Add response cache
* main               be64013 [origin/main: ahead 3] Give the batch tenant a higher limit
  spike/token-bucket 0d6aaa2 Spike: token bucket sketch
$ git log --graph --oneline --all
* be64013 Give the batch tenant a higher limit
* 673fb13 Reject requests above the tenant limit
* 6c8495f Add per-tenant request limits
| * 0d6aaa2 Spike: token bucket sketch
|/  
* 1b81d0e Add response cache
* ce8ecf3 Add request routing
$ git branch --merged origin/main
  feature/old-cache
$ git branch --no-merged origin/main
* main
  spike/token-bucket
```
<!-- /snippet -->

The work is on `main`, three commits ahead of `origin/main`. `feature/old-cache` is fully contained in `origin/main`; `spike/token-bucket` has a commit that exists nowhere else.

<!-- snippet: ex1/solve-m04-wrong-branch/03-repair -->
```text
# A new name for the commit you are on: no commit changes, the edit stays in the working tree.
$ git switch -c feature/rate-limit
Switched to a new branch 'feature/rate-limit'
# main is no longer the current branch, so its ref can be moved without touching any file.
$ git branch -f main origin/main
branch 'main' set up to track 'origin/main'.
$ git branch -d feature/old-cache
Deleted branch feature/old-cache (was 1b81d0e).
$ git branch -d spike/token-bucket
error: the branch 'spike/token-bucket' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D spike/token-bucket'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m04-wrong-branch/04-push -->
```text
$ git push -u origin feature/rate-limit
To ../server.git
 * [new branch]      feature/rate-limit -> feature/rate-limit
branch 'feature/rate-limit' set up to track 'origin/feature/rate-limit'.
$ git branch -vv
* feature/rate-limit be64013 [origin/feature/rate-limit] Give the batch tenant a higher limit
  main               1b81d0e [origin/main] Add response cache
  spike/token-bucket 0d6aaa2 Spike: token bucket sketch
$ git status --short
 M gateway/limits.py
$ git log --graph --oneline --all
* be64013 Give the batch tenant a higher limit
* 673fb13 Reject requests above the tenant limit
* 6c8495f Add per-tenant request limits
| * 0d6aaa2 Spike: token bucket sketch
|/  
* 1b81d0e Add response cache
* ce8ecf3 Add request routing
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m04-wrong-branch/05-check -->
```text
$ cd ..
$ exercises/gen/m04-wrong-branch/check.sh
Checking exercise m04-wrong-branch
  ok    feature/rate-limit points at the third commit, unchanged
  ok    the server has feature/rate-limit at the same commit
  ok    local main is the commit that main has on the server
  ok    main on the server did not move
  ok    HEAD is on feature/rate-limit
  ok    the uncommitted edit is still in the working tree
  ok    the edit is still uncommitted
  ok    the merged branch feature/old-cache is deleted
  ok    the unmerged branch spike/token-bucket is kept
PASS: exercise m04-wrong-branch is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.** The repair is three ref movements and no commit:

| Ref | From | To | Command |
|---|---|---|---|
| `refs/heads/feature/rate-limit` | (did not exist) | the third commit | `git switch -c feature/rate-limit` (HEAD now names it) |
| `refs/heads/main` | the third commit | the commit of `origin/main` | `git branch -f main origin/main` |
| `refs/heads/feature/old-cache` | its commit | (deleted) | `git branch -d feature/old-cache` |

No commit ID changed because no commit was created or rewritten: commits do not know which branch they are "on". The uncommitted edit was never at risk, because `git switch -c` creates a branch at the current commit, so no file has to change, and `git branch -f` moves a ref that is not checked out, so it touches neither index nor working tree.

The popular alternative, staying on `main` and running 🔴 `git reset --hard origin/main` after creating the branch, overwrites the working tree and destroys the uncommitted edit.

A side effect to know: `git branch -f main origin/main` printed that `main` was "set up to track" `origin/main`, because the start point is a remote-tracking branch. Here that is what `main` followed anyway.

**Common mistakes.** Cherry-picking the three commits onto a new branch: it works and produces three new commits with new IDs, which the task forbids and review tools would show as different commits. Deleting branches with `-D` from a list made by eye: the refusal for `spike/token-bucket` is the safety net doing its job. Trying to force the push to `main`.

**Expert approach.** "Wrong branch" is a naming problem. Solve it with names. Then make the mistake harder: check `git status -sb` before the first commit of a task, and keep `main` protected on the server, which is what turned this slip into a rejected push and not into an incident.

> **GitHub, not Git.** The refusal in the sandbox comes from a server-side hook that stands in for a GitHub ruleset. On GitHub the message and the mechanism are the platform's (Chapter 18); the Git-side repair is the same.

**Reference.** Chapter 7, sections 7.2, 7.5, 7.6 and 7.13; Chapter 12, section 12.5.

---

## Module 5: Configuration

The model runs of this module were made with the preamble of the exercise file. Its effect, once:

<!-- snippet: ex1/ex-m05/e00-preamble -->
```text
$ mkdir -p home
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ git config set --global user.name "Lab User"
$ git config set --global user.email you@example.com
$ git config set --global init.defaultBranch main
$ git config list --show-scope --show-origin
global	file:$LAB/ex1/ex-m05/m05-ex0/home/.gitconfig	user.name=Lab User
global	file:$LAB/ex1/ex-m05/m05-ex0/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ex1/ex-m05/m05-ex0/home/.gitconfig	init.defaultbranch=main
```
<!-- /snippet -->

### Solution 5.1: one key in the local file

**Solution.**

<!-- snippet: ex1/ex-m05/e01-local -->
```text
$ git init -q svc
$ cd svc
$ git config set pull.ff only
$ git config get pull.ff
only
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
[pull]
	ff = only
$ git config unset pull.ff
$ git config get pull.ff
[exit status: 1]
$ git config unset pull.ff
[exit status: 5]
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

Without a scope option, `git config set` writes to the repository's own file, `.git/config` (the local scope). It added a `[pull]` section with `ff = only`; `unset` removed the key and, since the section became empty, the section. Exit status 1 from `get` means "this key is not set"; exit status 5 from `unset` means "there was nothing to unset".

A script tests the exit status because an unset key and a key set to an empty value both print nothing useful, and because an error message goes to standard error where a pipeline does not see it.

**Reasoning.** Configuration is plain text in INI style, one file per scope. The subcommands are a safe editor for these files: they keep the syntax valid.

**Common mistakes.** Expecting `git config set` to be global by default. Editing `.git/config` by hand and leaving a broken section header, after which every Git command fails. Using the subcommands in a script that must also run on Git older than 2.46, where only the legacy spelling (`git config <key> <value>`, `git config --unset`) exists.

**Expert approach.** State the scope in every command you paste into documentation (`--local`, `--global`), so that the reader's result does not depend on where they happen to stand.

**Reference.** Chapter 14B, sections 14B.2 and 14B.3.

### Solution 5.2: scope and origin of one key

**Solution.**

<!-- snippet: ex1/ex-m05/e02-scope -->
```text
$ git init -q svc
$ cd svc
$ git config set --global merge.conflictStyle zdiff3
$ git config set merge.conflictStyle diff3
$ git config get --all --show-scope --show-origin merge.conflictStyle
global	file:$LAB/ex1/ex-m05/m05-ex2/home/.gitconfig	zdiff3
local	file:.git/config	diff3
$ git config get merge.conflictStyle
diff3
$ git -c merge.conflictStyle=merge config get --show-scope merge.conflictStyle
command	merge
$ cd ..
$ git config get --show-scope merge.conflictStyle
global	zdiff3
```
<!-- /snippet -->

- `get --all` lists both values in the order Git reads them: global first, local second.
- Plain `get` prints the last one read: `diff3`, the local value.
- With `-c merge.conflictStyle=merge` the command-line value wins, and its scope is reported as `command`.
- Outside the repository there is no local file, so the global value is what remains.

Precedence, lowest to highest: system, global, local, worktree, command line (`-c`). The lab switches the system file off, which is why it never appears.

**Reasoning.** For a single-valued key Git reads all scopes in a fixed order and the last value read wins. "More specific overrides more general" is a consequence of that reading order.

**Common mistakes.** Changing the global value and wondering why a repository ignores it, when a local value overrides it. Debugging with `git config get <key>` alone, which hides where the winning value comes from. Forgetting that `-c` beats everything in the files, which is what makes it the right tool for a one-off.

**Expert approach.** The first diagnostic for any "Git behaves differently here" report is `git config get --all --show-scope --show-origin <key>`, run in the affected repository.

**Reference.** Chapter 14B, section 14B.2.

### Solution 5.3: typed values

**Solution.**

<!-- snippet: ex1/ex-m05/e03-types -->
```text
$ git init -q svc
$ cd svc
$ git config set core.bigFileThreshold 1m
$ git config get core.bigFileThreshold
1m
$ git config get --type=int core.bigFileThreshold
1048576
$ git config set fetch.prune yes
$ git config get --type=bool fetch.prune
true
$ git config get --type=bool core.bigFileThreshold
true
[exit status: 0]
$ git config get --type=int fetch.prune
fatal: bad numeric config value 'yes' for 'fetch.prune' in file .git/config: invalid unit
[exit status: 128]
$ git config set --global core.excludesFile '~/.gitignore-global'
$ git config get core.excludesFile
~/.gitignore-global
$ git config get --type=path core.excludesFile
$LAB/ex1/ex-m05/m05-ex3/home/.gitignore-global
```
<!-- /snippet -->

- `--type=int` expanded the suffix: `1m` is 1048576 (`k`, `m` and `g` multiply by powers of 1024).
- `--type=bool` canonicalized `yes` to `true`.
- `--type=bool` on `1m` printed `true` with exit status 0. That is the unexpected one: where Git wants a boolean it also accepts a number, and any number other than zero counts as true.
- `--type=int` on `yes` failed with status 128 and a message that names the key and the file: `yes` is not a number.
- `--type=path` expanded the leading `~/` to the home directory. The stored text is still `~/.gitignore-global`, which is why the same configuration file works for every user.

**Reasoning.** The file stores text. A type is applied when a value is read, by Git itself according to what each setting expects, or by you with `--type`. The stored spelling and the interpreted value can therefore differ.

**Common mistakes.** Comparing a boolean setting with the string `true` in a script, which misses `yes`, `on` and `1`. Writing an expanded absolute path into a shared configuration file. Assuming that a nonsensical value is rejected when it is written: `git config set` stores text without knowing what the key means.

**Expert approach.** In scripts always read with `--type`, and treat status 128 as "the configuration is broken", not as "unset".

**Reference.** Chapter 14B, section 14B.3.

### Solution 5.4: four sources for one identity

**Solution.**

<!-- snippet: ex1/ex-m05/e04-answer -->
```text
$ git log --format='%s: author %ae, committer %ce'
two: author env@example.com, committer cli@example.com
one: author local@example.com, committer local@example.com
$ git config get --all --show-scope user.email
global	global@example.com
local	local@example.com
```
<!-- /snippet -->

Commit `one`: author and committer are both `local@example.com`. Local configuration beats global.

Commit `two`: the author is `env@example.com`, the committer is `cli@example.com`.

- Author: the environment variable `GIT_AUTHOR_EMAIL` is consulted before any configuration, and it beats `user.email` even when `user.email` is given with `-c`.
- Committer: no `GIT_COMMITTER_EMAIL` was set, so configuration decides, and within configuration the command line (`-c`) beats local, which beats global.

**Reasoning.** Two rules are stacked. First, for each identity: environment variable, then configuration, then a guess from the system. Second, inside configuration: the scope order of Exercise 5.2. Author and committer are resolved separately, which is how one commit ends up with two addresses.

**Common mistakes.** Predicting `cli@example.com` for both because "`-c` beats everything": it beats everything in configuration. Forgetting that author and committer have separate variables. Setting only `GIT_AUTHOR_EMAIL` in a CI job and being surprised by the committer address.

**Expert approach.** `git var GIT_AUTHOR_IDENT` and `git var GIT_COMMITTER_IDENT` print what the next commit will record, with every rule already applied. Run them before the first commit on a new machine or in a new CI image.

**Reference.** Chapter 14B, section 14B.2; Chapter 6, section 6.5.

### Solution 5.5: unset, and the position of an include

**Solution.** Part A:

<!-- snippet: ex1/ex-m05/e05-answer-a -->
```text
$ git config get --show-scope pull.rebase
global	true
$ git config unset pull.rebase
[exit status: 5]
$ git config get --show-scope pull.rebase
global	true
```
<!-- /snippet -->

The first `unset` (in the setup) removed the local value, so `get` now shows the global one, `true`. The second `unset` has nothing to remove in the local file and exits with status 5; it does not reach into the global file. The global value is still there.

Part B:

<!-- snippet: ex1/ex-m05/e05-answer-b -->
```text
$ cat ~/.gitconfig
[user]
	name = Lab User
	email = you@example.com
[init]
	defaultBranch = main
[pull]
	rebase = true
[core]
	editor = vim
[include]
	path = ~/extra.gitconfig
$ git config get --all --show-origin core.editor
file:$LAB/ex1/ex-m05/m05-ex5/home/.gitconfig	vim
file:$LAB/ex1/ex-m05/m05-ex5/home/extra.gitconfig	nano
$ git config get core.editor
nano
```
<!-- /snippet -->

`nano` wins. Both values are in the global scope, so scope precedence does not decide; reading order does. The include line stands **after** `[core] editor = vim` in `~/.gitconfig`, the included file is read at the position of that line, and so its value is read last.

For `vim` to win with both settings kept, the `[core]` section must come after the `[include]` section in the file.

**Reasoning.** An included file is not a lower-ranking scope. It is inserted, in effect, where the include line stands. "Last one wins" then applies to the combined text.

**Common mistakes.** Expecting `unset` to remove a key "wherever it is". Assuming the including file always overrides what it includes, or the reverse. Using `git config get --global <key>` to investigate: asking one scope by name switches include processing off unless you add `--includes`, so the answer can differ from what Git uses.

**Expert approach.** Keep includes at the end of `~/.gitconfig` when they are meant to override, and at the top when they are meant to provide defaults. Decide which it is, and say so in a comment in the file.

**Reference.** Chapter 14B, sections 14B.2, 14B.3 and 14B.4.

### Solution 5.6: two aliases

**Solution.**

<!-- snippet: ex1/ex-m05/e06-aliases -->
```text
$ git config set --global alias.recent "branch --sort=-committerdate --format='%(committerdate:relative) %(refname:short)'"
$ git recent
3 minutes ago fix/timeout
4 minutes ago feature/fallback
8 minutes ago main
$ git config set --global alias.where '!echo "$(git branch --show-current) at $(git rev-parse --short HEAD) in $PWD"'
$ cd src/router
$ git where
main at 3119b72 in $LAB/ex1/ex-m05/m05-ex6/branches
$ git config get --all --show-names --regexp "^alias\."
alias.recent branch --sort=-committerdate --format='%(committerdate:relative) %(refname:short)'
alias.where !echo "$(git branch --show-current) at $(git rev-parse --short HEAD) in $PWD"
```
<!-- /snippet -->

`git where`, run from `src/router`, prints the top-level directory of the repository: an alias that starts with `!` is handed to the shell and run from the top level, not from the directory you are in.

**Reasoning.** `git recent` is an ordinary alias: its value is a Git command line, and whatever you type after `git recent` is appended to it. `git where` needs the shell because it combines three commands. The value is written in single quotes so that your shell does not expand `$(...)` and `$PWD` when you define the alias; the dollar signs must arrive in the configuration file as they are.

**Common mistakes.** Defining the shell alias in double quotes, which freezes the branch name and commit ID of the moment of definition into the alias. Expecting a `!` alias to run in the current subdirectory. Naming an alias like an existing command: Git ignores it. Relying on aliases in shared scripts or documentation: they exist on your machine only.

**Expert approach.** Keep aliases for reading and for typing less (`st`, `lg`, `recent`), and keep commands that rewrite or delete spelled out, so that a slip of the fingers cannot run them.

**Reference.** Chapter 14B, section 14B.6.

### Solution 5.7: the include is there and the work address is not used

**Solution.** The conditional include stands **before** the `[user]` section in `~/.gitconfig`.

<!-- snippet: ex1/ex-m05/e07-diagnosis -->
```text
$ git config get --all --show-origin user.email
file:$LAB/ex1/ex-m05/m05-ex7/home/.gitconfig-work	lab.user@corp.example
file:$LAB/ex1/ex-m05/m05-ex7/home/.gitconfig	lab.user@personal.example
$ git config get user.email
lab.user@personal.example
```
<!-- /snippet -->

1. The include matches and is read, at the top of the file. Then `[user]` further down sets `user.email` again, and the last value read wins.
2. `git config get --all --show-origin user.email` lists two values for the work repository: first the one from `~/.gitconfig-work`, then the one from `~/.gitconfig`. Seeing the included file in the list proves that the condition matched; seeing it first explains why it lost.
3. Move the conditional include to the end of the file, then repair the commit:

<!-- snippet: ex1/ex-m05/e07-fix -->
```text
$ printf '[user]\n\tname = Lab User\n\temail = lab.user@personal.example\n[init]\n\tdefaultBranch = main\n[includeIf "gitdir:~/work/"]\n\tpath = ~/.gitconfig-work\n' > ~/.gitconfig
$ git config get --all --show-origin user.email
file:$LAB/ex1/ex-m05/m05-ex7/home/.gitconfig	lab.user@personal.example
file:$LAB/ex1/ex-m05/m05-ex7/home/.gitconfig-work	lab.user@corp.example
$ git commit -q --amend --no-edit --reset-author
$ git log -1 --format='%an <%ae>  %s'
Lab User <lab.user@corp.example>  Add invoice prompt
```
<!-- /snippet -->

`--reset-author` is right here: the wrong value is the identity itself, and the commit is not pushed.

**Reasoning.** The three checks the colleague made rule out three of the documented ways a conditional include silently fails (the slash, a missing file, a repository outside the directory). The fourth is order.

**Common mistakes.** Adding a repository-local `user.email` to "make it work", which hides the cause and fixes one repository. Checking with `git config get --global user.email`, which does not process includes without `--includes`. Amending commits that are already pushed.

**Expert approach.** Put conditional includes last in the global file. Better still, give the global file no default address at all and set `user.useConfigOnly=true`: a repository that no include covers then refuses to commit, which is an error instead of a wrong address.

**Reference.** Chapter 14B, section 14B.4; Chapter 6, section 6.13.

### Solution 5.8: the configuration is right and the commit is wrong

**Solution.** The shell exports `GIT_AUTHOR_EMAIL` and `GIT_COMMITTER_EMAIL`.

<!-- snippet: ex1/ex-m05/e08-diagnosis -->
```text
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@old-startup.example> 1788760920 +0530
$ git var GIT_COMMITTER_IDENT
Lab User <lab.user@old-startup.example> 1788760980 +0530
$ env | grep -E '^GIT_(AUTHOR|COMMITTER)_(NAME|EMAIL)' | sort
GIT_AUTHOR_EMAIL=lab.user@old-startup.example
GIT_COMMITTER_EMAIL=lab.user@old-startup.example
```
<!-- /snippet -->

1. For each of author and committer Git reads, in this order: the environment (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`), then `user.name` and `user.email` from configuration with its scope rules, then a guess from the system user and host name.
2. `git var GIT_AUTHOR_IDENT` (and `GIT_COMMITTER_IDENT`) prints the identity the next commit would get. `env | grep '^GIT_'` finds the variables.
3. Unset the variables in the shell, remove the lines that export them (typically in `~/.zshrc`, `~/.zprofile`, a tool's environment file, or a CI job definition), and repair the unpushed commit:

<!-- snippet: ex1/ex-m05/e08-fix -->
```text
$ unset GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@corp.example> 1788761160 +0530
$ git commit -q --amend --no-edit --reset-author
$ git log -1 --format='author %an <%ae>, committer %cn <%ce>'
author Lab User <lab.user@corp.example>, committer Lab User <lab.user@corp.example>
```
<!-- /snippet -->

**Reasoning.** `git config` reports configuration and nothing else. When configuration is provably right and the result is wrong, the cause is one level above: the environment.

**Common mistakes.** Setting `user.email` again, in more scopes. Reinstalling Git. Looking only for `GIT_AUTHOR_*` and missing `GIT_COMMITTER_*`. Unsetting the variable in the current shell and finding the problem back in the next terminal window.

**Expert approach.** Ask Git what it will do (`git var`) before asking why. In a diagnosis, list `env | grep '^GIT_'` together with `git config list --show-origin --show-scope`: the lab environment itself removes inherited `GIT_*` variables for exactly this reason.

**Reference.** Chapter 14B, sections 14B.2 and 14B.7; Chapter 6, sections 6.5 and 6.13.

### Solution 5.9: two work repositories, two wrong addresses

**Solution.** Two independent causes.

<!-- snippet: ex1/solve-m05-two-identities/01-first-step -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ git -C ~/work/billing-llm log --format='%h %ae | %ce | %s'
de6e50f lab.user@personal.example | lab.user@personal.example | Add dunning prompt
f03cbbb lab.user@personal.example | lab.user@personal.example | Add invoice prompts
$ git -C ~/work/invoice-ocr log --format='%h %ae | %ce | %s'
8795118 intern@corp.example | intern@corp.example | Retry OCR on timeout
37c6aec intern@corp.example | intern@corp.example | Add OCR client
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m05-two-identities/02-evidence -->
```text
$ git -C ~/work/billing-llm config get --all --show-scope --show-origin user.email
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig	lab.user@personal.example
$ git -C ~/work/invoice-ocr config get --all --show-scope --show-origin user.email
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig	lab.user@personal.example
local	file:.git/config	intern@corp.example
$ git -C ~/oss/dotfiles config get --all --show-scope --show-origin user.email
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig	lab.user@personal.example
```
<!-- /snippet -->

`billing-llm` sees one value, the global personal address: the include contributes nothing. `invoice-ocr` sees the same global value and, after it, a local one that wins.

<!-- snippet: ex1/solve-m05-two-identities/03-include -->
```text
$ git config get --global --all --show-names --regexp "^includeif"
includeif.gitdir:~/work/.path ~/.gitconfig-wrok
$ ls -a ~ | grep gitconfig
.gitconfig
.gitconfig-work
$ git -C ~/work/billing-llm rev-parse --absolute-git-dir
$LAB/ex1/solve-m05-two-identities/home/work/billing-llm/.git
```
<!-- /snippet -->

The pattern is right (`gitdir:~/work/`, with its slash, and the repository lies below it). The path is not: it names `~/.gitconfig-wrok`, and the file is called `.gitconfig-work`. An include that names a missing file is skipped without any message.

<!-- snippet: ex1/solve-m05-two-identities/04-repair-config -->
```text
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ git -C ~/work/billing-llm config get --all --show-scope --show-origin user.email
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig	lab.user@personal.example
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig-work	lab.user@corp.example
$ git -C ~/work/invoice-ocr config unset user.email
$ git -C ~/work/invoice-ocr config get --all --show-scope --show-origin user.email
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig	lab.user@personal.example
global	file:$LAB/ex1/solve-m05-two-identities/home/.gitconfig-work	lab.user@corp.example
$ git -C ~/oss/dotfiles config get user.email
lab.user@personal.example
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m05-two-identities/05-repair-commits -->
```text
$ cd ~/work/billing-llm
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@corp.example> 1788757020 +0530
$ git commit -q --amend --no-edit --reset-author
$ git log --format='%h %ae | %ce | %s'
50e4713 lab.user@corp.example | lab.user@corp.example | Add dunning prompt
f03cbbb lab.user@personal.example | lab.user@personal.example | Add invoice prompts
$ cd ~/work/invoice-ocr
$ git commit -q --amend --no-edit --reset-author
$ git log --format='%h %ae | %ce | %s'
82c91a3 lab.user@corp.example | lab.user@corp.example | Retry OCR on timeout
37c6aec intern@corp.example | intern@corp.example | Add OCR client
```
<!-- /snippet -->

<!-- snippet: ex1/solve-m05-two-identities/06-check -->
```text
$ cd "$HOME/.."
$ exercises/gen/m05-two-identities/check.sh
Checking exercise m05-two-identities
  ok    billing-llm: the effective address is the company address
  ok    billing-llm: no repository-local user.email papers over the cause
  ok    billing-llm: the last commit has the company address as author and committer
  ok    billing-llm: the history still has two commits
  ok    invoice-ocr: the effective address is the company address
  ok    invoice-ocr: no repository-local user.email papers over the cause
  ok    invoice-ocr: the last commit has the company address as author and committer
  ok    invoice-ocr: the history still has two commits
  ok    billing-llm: the older commit is untouched
  ok    invoice-ocr: the older commit is untouched
  ok    the personal repository still resolves the personal address
  ok    the personal repository is untouched
  ok    the global default address is still the personal one
  ok    the include for ~/work/ names a file that exists
PASS: exercise m05-two-identities is solved.
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.**

| Repository | Cause | Rule behind it | Repair at the source |
|---|---|---|---|
| both | The conditional include names a file that does not exist | A missing include file is skipped silently | Correct the path in the global file |
| `invoice-ocr` | A repository-local `user.email` | Local scope overrides global, included values too | `git config unset user.email` in that repository |

After the repair both work repositories list the personal address first and the company address last, from `~/.gitconfig-work`, and the personal repository still has one value. Only the last commit of each repository was amended: the older commits had been accepted by the server and are shared history.

The setting that turns both silent failures into errors is `user.useConfigOnly=true` combined with a global file that has **no** default `user.email`: then a repository that no include covers cannot commit. It would not have caught the stray local value in `invoice-ocr`; for that, the server-side check that rejected the push is the control that worked.

**Common mistakes.** Setting `user.email` locally in each work repository: both pass a quick test and the next repository under `~/work/` is wrong again (the check script looks for exactly this). Fixing the include and forgetting the local override, or the reverse. Using `--reset-author` on the older commits as well. Forgetting the first step of the module, so that the diagnosis reads the lab's shared global file and not the sandbox's.

**Expert approach.** Diagnose per repository with one command, `git config get --all --show-scope --show-origin user.email`, and read it as a list of candidates in reading order. Then verify with `git var GIT_AUTHOR_IDENT` before amending anything.

> **GitHub, not Git.** Rejecting pushes by committer address is a platform rule (on GitHub, a metadata restriction in a ruleset, which Chapter 18 lists as an Enterprise plan feature). Git itself accepts any address.

**Reference.** Chapter 14B, sections 14B.2, 14B.4 and 14B.5; Chapter 6, section 6.13.

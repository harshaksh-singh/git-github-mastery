# Exercises, Modules 16 to 18: the object database, the index and refs, transfer and scale

> **Baseline.** Git 2.55.0 on macOS. Every exercise was run on that version; the model answers in [solutions/exercises-m16-m18.md](../solutions/exercises-m16-m18.md) are real transcripts. This file contains no answers. Open the solutions only after you have written your own answer down.

## How to use these exercises

The levels, the sandboxes, the lab shell and the check scripts work as described at the top of [the exercises for Modules 11 to 15](m11-m15-investigation-recovery.md). In short:

```bash
exercises/gen/<name>/generate.sh              # builds the sandbox and prints its path
labs/shell "<the path it printed>"            # an isolated shell; your real Git configuration is never touched
exercises/gen/<name>/check.sh                 # Level 4 only: read-only, exit status 0 when the end state is right
```

Three things are particular to these modules.

- **You will read and write files under `.git` by hand.** That is the subject. Do it only inside the sandbox, and prefer the plumbing command whenever one exists: the exercises show you where the hand-written file and the command differ.
- **Maintenance runs in the foreground only.** `git gc` and `git maintenance run` are fine. Do not run `git maintenance start` or `git maintenance register`: they install a scheduler on your machine.
- **Expiry uses clock-independent cut-offs.** `--expire=now` and `--prune=now` only (Chapter 1, section 1.7). Both are 🔴 outside a sandbox.

Object IDs of blobs and trees depend on content alone, so the ones you compute are the ones in the solutions. Commit IDs match for commits made by a generator and differ for commits you make yourself.

| Module | Level 1 | Level 2 | Level 3 | Level 4 |
|---|---|---|---|---|
| 16 Object database and maintenance | 16.1, 16.2, 16.3 | 16.4 (prediction), 16.5 (prediction), 16.6 | 16.7, 16.8 | 16.9 |
| 17 Index, refs, the `.git` directory | 17.1, 17.2, 17.3 | 17.4 (prediction), 17.5 (prediction), 17.6 (graph) | 17.7, 17.8 | 17.9 |
| 18 Transfer and scale | 18.1, 18.2, 18.3 | 18.4 (graph), 18.5 (prediction), 18.6 | 18.7, 18.8 | 18.9 |

---

## Module 16: The object database and its maintenance

Chapters: [3, Git internals](../textbook/ch03-git-internals.md), sections 3.3 to 3.8, and [26, Performance](../textbook/ch26-performance.md), sections 26.3 to 26.8. Labs 16.1 to 16.4 come first.

Exercises 16.1 to 16.8 use small repositories of the project `shardmap` (a service that maps tenants to shards of a vector index), one directory per exercise:

```bash
exercises/gen/m16-shardmap-practice/generate.sh
```

Several commands below are long. This one prints the three numbers that matter in `git count-objects -v`; the exercises call it "the counts":

```bash
git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
```

### Exercise 16.1 (Level 1): An object ID by hand

Directory `ex-16-1`, an empty repository.

**Do.**

```bash
printf 'shards: 16\n' > shards.yaml
git hash-object shards.yaml
printf 'blob 11\0shards: 16\n' | shasum
find .git/objects -type f | wc -l
git hash-object -w shards.yaml
find .git/objects -type f
python3 -c 'import sys, zlib; print(zlib.decompress(open(sys.argv[1], "rb").read()))' <the file that find printed>
```

**Answer in writing.**

1. Which bytes does Git hash to get the ID of a blob? Where does the number 11 come from?
2. What is the relation between the object ID and the path of the file under `.git/objects`?
3. The file name `shards.yaml` appears nowhere in what you decompressed. Where does Git record names?
4. What does `-w` add, and what does the count before it prove about plain `git hash-object`?
5. Predict the ID of the blob for a file with the same content and the name `other.yaml` in another repository. Check it.

### Exercise 16.2 (Level 1): From a commit to the bytes of a file

Directory `ex-16-2`.

**Do.**

```bash
git cat-file -p HEAD
git cat-file -p 'HEAD^{tree}'
git cat-file -p HEAD:config
git rev-parse HEAD:config/shards.yaml
git cat-file -t <that ID>
git cat-file -s <that ID>
git cat-file -p <that ID>
git ls-tree -r HEAD
```

**Answer in writing.**

1. List the headers of the commit object. Which of them make this commit's ID different from that of a commit with the same files made by someone else a minute later?
2. How many objects did you read to get from `HEAD` to the content of `config/shards.yaml`? Name the type of each.
3. What do the three columns before the name in a tree entry mean? Which mode would a subdirectory, an executable file and a submodule have?
4. `git ls-tree -r HEAD` shows no tree entries. Where did they go?

### Exercise 16.3 (Level 1): Loose objects become a pack

Directory `ex-16-3`: eight commits, six of which rewrite a 400-line file with small differences.

**Do.**

```bash
git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
git gc -q
git count-objects -v | grep -e '^count' -e in-pack -e '^packs'
find .git/objects -type f | sed "s/[0-9a-f]\{40\}/ID/" | sort
git cat-file --batch-check --batch-all-objects | awk '{print $2}' | sort | uniq -c
git verify-pack -v .git/objects/pack/pack-*.idx | awk '$2 == "blob" && NF == 7'
git verify-pack -v .git/objects/pack/pack-*.idx | tail -5
for c in $(git rev-list --reverse HEAD -- config/assignments.yaml); do echo "$(git log -1 --format=%s ${c}): $(git rev-parse --short "${c}:config/assignments.yaml"), $(git cat-file -s "${c}:config/assignments.yaml") bytes"; done
```

**Answer in writing.**

1. What changed in the counts, and did any object ID change?
2. What are the files with the suffixes `.pack`, `.idx` and `.rev`?
3. The sixth command lists blobs with seven columns. What are the last two columns, and what is stored for such an object?
4. Does a delta mean that Git stores commits as differences? Reconcile your answer with "a commit is a snapshot".
5. The last command lists the six versions of the file, oldest first. Which one is stored whole and serves as the base of the deltas: the oldest, the newest, or another one? Compare with the example in Chapter 3, section 3.7, and say what the two cases have in common.

### Exercise 16.4 (Level 2, command prediction): Count the objects

Directory `ex-16-4` is empty. Type the first two lines:

```bash
git init -q objects-lab && cd objects-lab
echo 'shards: 16' > a.yaml && cp a.yaml b.yaml && git add a.yaml b.yaml
```

**Write down the number** that `git count-objects -v | head -1` prints now and after each of the following four steps. For each step, name the type of every new object.

```bash
git commit -q -m 'Add two files'
git commit -q --amend -m 'Add two identical files'
mkdir config && git mv a.yaml config/a.yaml && git commit -q -m 'Move a file'
echo 'shards: 32' > b.yaml && git commit -q -am 'Use 32 shards'
```

Then predict the three lines of:

```bash
git cat-file --batch-check --batch-all-objects | awk '{print $2}' | sort | uniq -c
```

### Exercise 16.5 (Level 2, command prediction): What `git gc` does with unreachable objects

Directory `ex-16-5`. A branch, `spike/consistent-hashing`, with one commit was deleted with `git branch -D`. Find the ID of that commit with `git reflog | grep consistent` and call it `<c>`.

**Write down** the counts and the result of `git cat-file -t <c>` (a type, or an error) at each of the three numbered points, before you run anything:

```bash
git gc -q
# point 1: the counts, and git cat-file -t <c>

git reflog expire --expire=now --all
git gc -q
# point 2: the counts, and git cat-file -t <c>; also: ls .git/objects/pack

git gc -q --prune=now
# point 3: the counts, and git cat-file -t <c>
```

**Then explain** why the object survived two of the three garbage collections, what protected it each time, and how long each protection lasts in a repository with default settings.

### Exercise 16.6 (Level 2): The largest blobs in history

Directory `ex-16-6`. The working tree holds a few small text files, and the repository is much larger than they are.

**Goal.** With one pipeline, list the three largest blobs that are reachable from any ref, each with its size and the path under which it was committed. Then find, for the largest one, the commit that added it and the commit that removed it, and show that the blob still exists.

**Hints.** `git rev-list --objects` prints an ID and a path per object. `git cat-file --batch-check` accepts a format, and `%(rest)` passes through whatever follows the ID on the input line.

**Then explain** why removing the file in a commit did not make the repository smaller.

### Exercise 16.7 (Level 3): Which `git fsck` lines matter

Directory `ex-16-7`.

**Situation.** A teammate ran `git fsck` here, saw several lines of output, and concluded: "The repository is corrupt, it reports dangling objects. Delete it and clone again." This repository has no remote.

**Task.** Run `git fsck` and classify every line as harmless or as damage, with the reason. For each harmless line, say what the object is and how it came to be there. For the damage: find out what the object was, which commands fail because of it and which do not, and repair it from what you have. Finish with a `git fsck` that exits with status 0.

### Exercise 16.8 (Level 3): Scripts that read `.git` by hand

Directory `ex-16-8`.

**Situation.** Two helper scripts in `tools/` have worked for a year: `current-commit.sh` prints the commit that is deployed from this checkout, and `count-objects.sh` feeds a capacity dashboard. After a routine `git gc` on the deployment host, the first one fails and the second one reports that the repository has no objects.

**Task.** Run both scripts, run `git gc -q`, run them again. Explain each failure from what `git gc` did. Rewrite both scripts so that they are correct in every state of the repository, and say which general rule the originals broke.

### Exercise 16.9 (Level 4): Removed from history, and still there

```bash
exercises/gen/m16-shardmap/generate.sh
```

Read [the symptoms](gen/m16-shardmap/SYMPTOMS.md). Finish with `exercises/gen/m16-shardmap/check.sh`.

---

## Module 17: The index, refs, and the files of `.git`

Chapters: [3, Git internals](../textbook/ch03-git-internals.md), sections 3.2, 3.6 and 3.9 to 3.12, and [5, The index](../textbook/ch05-index.md), sections 5.11 to 5.15. Labs 17.1 to 17.3 come first.

Exercises 17.1 to 17.8 use small repositories of the project `ingestd` (a daemon that ingests documents into a search index), one directory per exercise:

```bash
exercises/gen/m17-ingestd-practice/generate.sh
```

### Exercise 17.1 (Level 1): The index as a table

Directory `ex-17-1`.

**Do.**

```bash
git ls-files --stage
echo 'workers: 8' >> config.yaml
git ls-files --stage config.yaml
git status -s
git add config.yaml
git ls-files --stage config.yaml
git rev-parse HEAD:config.yaml
git rev-parse :config.yaml
git ls-files --debug config.yaml | grep -e size -e flags
```

**Answer in writing.**

1. Name the four columns of `git ls-files --stage`.
2. After the edit and before `git add`, the index entry is unchanged, and `git status` still knows that the file changed. How?
3. What did `git add` write, and where? Which two things now disagree, and which command shows that disagreement as a diff?
4. What do `HEAD:config.yaml` and `:config.yaml` name?
5. Besides the size, which other cached values does `--debug` print, and what are they for?

### Exercise 17.2 (Level 1): Loose refs and packed refs

Directory `ex-17-2`: two branches and one annotated tag.

**Do.**

```bash
git for-each-ref
find .git/refs -type f | sort
git pack-refs --all
find .git/refs -type f | sort
cat .git/packed-refs
echo 'See docs/format.md.' >> README.md && git commit -q -am 'Point to the format description'
find .git/refs -type f | sort
cat .git/refs/heads/main
grep refs/heads/main .git/packed-refs
git rev-parse main
```

**Answer in writing.**

1. Where is each ref stored before and after `git pack-refs --all`?
2. What is the line that begins with `^` in `packed-refs`?
3. After the new commit, `main` exists in two places with two values. Which one wins, and what is the other one?
4. What does this exercise say about a script that reads `.git/refs/heads/main` to learn the current commit?

### Exercise 17.3 (Level 1): Refs by plumbing

Directory `ex-17-3`.

**Do.**

```bash
cat .git/HEAD
git symbolic-ref HEAD
git symbolic-ref --short HEAD
git update-ref refs/heads/experiment HEAD~1
git branch -v
git update-ref refs/heads/experiment HEAD HEAD
git update-ref refs/heads/experiment HEAD HEAD~1
git reflog show experiment
git update-ref -d refs/heads/experiment
git branch
```

**Answer in writing.**

1. What kind of ref is `HEAD` here, and what would `cat .git/HEAD` show in detached HEAD state?
2. `git update-ref` takes an optional third argument. What is it, why did the first of the two calls with three arguments fail, and when is that behavior valuable?
3. Compare `git update-ref refs/heads/experiment HEAD~1` with `git branch experiment HEAD~1`: what does the porcelain command check or do in addition?
4. Give two reasons to prefer `git update-ref` over writing the file under `.git/refs` yourself.

### Exercise 17.4 (Level 2, command prediction): The index during a conflict

Directory `ex-17-4`, on `main`. The branch `feature/streaming` and `main` have each made three changes since they diverged:

| Path | `main` | `feature/streaming` |
|---|---|---|
| `config.yaml` | changed line 1 | changed line 1 differently |
| `docs/format.md` | appended a line | deleted the file |
| `src/stream.py` | added the file | added the file with other content |

Run `git merge feature/streaming`. **Before you look at the index, write down** the output of `git status -s` (three lines) and of `git ls-files -u`: how many lines, and for each path which stage numbers appear. Then check.

**Then answer.** What do stages 1, 2 and 3 hold? Why do two of the paths have fewer than three entries? What does `git show :2:config.yaml` print? Finish with `git merge --abort` and predict the output of `git ls-files -u | wc -l`.

### Exercise 17.5 (Level 2, command prediction): What `git rev-parse` answers

Directory `ex-17-5`, on `main`. **Write down** the output of every `git rev-parse` call before you run it. For IDs, say whether two outputs are equal or different.

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse --symbolic-full-name HEAD
git switch -q --detach
git rev-parse --abbrev-ref HEAD
git rev-parse --symbolic-full-name HEAD
git switch -q main

echo 'Run it with python3 -m src.ingest.' >> README.md && git add README.md
git rev-parse HEAD:README.md
git rev-parse :README.md

cd src
git rev-parse --show-prefix
git rev-parse --show-cdup
git rev-parse --show-toplevel
git rev-parse --git-dir
cd ..

git rev-parse -q --verify refs/heads/nope; echo "exit status: $?"
git rev-parse HEAD^2
```

**Then explain** why a script should use `git rev-parse -q --verify <ref>` and not `test -f .git/refs/heads/<name>` to find out whether a branch exists.

### Exercise 17.6 (Level 2, draw the graph): A commit without the index

Directory `ex-17-6`, on `main` with three commits.

**Goal.** Create a branch `docs-snapshot` whose only commit has the `docs/` directory of `HEAD` as its root tree, has no parent, and has the message `Snapshot of the documentation`. You may not switch branches, and the index and the working tree must not change.

**Hints.** The tree you need already exists as an object. Two plumbing commands are enough: one creates a commit from a tree, one creates a ref.

**Before you run `git log --graph --oneline --all`, draw its output.** Then show `git ls-tree docs-snapshot`, `git cat-file -p docs-snapshot` and `git status -sb`.

**Then explain** what is unusual about the graph, and what `git merge docs-snapshot` would say.

### Exercise 17.7 (Level 3): A branch that Git ignores

Directory `ex-17-7`, on `main`.

**Situation.** `git branch` prints a warning and does not list `release/1.0`, which had two commits beyond `main`. `git log release/1.0` fails. A colleague looked at the repository and proposes: "The ref file is garbage. Delete it and Git will fall back to the packed copy."

**Task.** Find out what is wrong with the ref, and what each place that knows something about this branch says: the ref file, `packed-refs`, the reflog. Test the colleague's proposal and say exactly what it would have cost. Then repair the branch to its true last value, with a plumbing command, and verify.

### Exercise 17.8 (Level 3): An edit that Git does not see

Directory `ex-17-8/work`, a clone of `ex-17-8/server.git`.

**Situation.** `config.yaml` in this working tree says `workers: 16`. `git status` reports a clean tree and `git diff` prints nothing, although the committed value is 4. `git pull` fails and names this file.

**Task.** Find out why Git does not report the edit, with one command that shows the cause. Undo the cause, keep the local value, and complete the pull. Then say what the person who set this up wanted, why Git has no feature for it, and what to do instead.

### Exercise 17.9 (Level 4): "Not a git repository"

```bash
exercises/gen/m17-ingestd/generate.sh
```

Read [the symptoms](gen/m17-ingestd/SYMPTOMS.md). Finish with `exercises/gen/m17-ingestd/check.sh`.

---

## Module 18: Transfer and scale

Chapters: [26, Performance](../textbook/ch26-performance.md), sections 26.10 to 26.14, and [24, Monorepos](../textbook/ch24-monorepos.md), sections 24.4 to 24.7; refspecs are in Chapter 12, section 12.12. Labs 18.1 to 18.4 come first.

Every exercise directory contains `server.git`, a bare copy of the monorepo `searchstack` (two services, one library, documentation; nine commits on `main` with a merge at the tip; the branch `release/0.2`; the annotated tags `v0.1.0` and `v0.2.0`):

```bash
exercises/gen/m18-searchstack-practice/generate.sh
```

Clone with a `file://` URL, as shown. With a plain path Git copies or links the object files directly and ignores `--depth` and `--filter`.

Two commands below are long; the exercises call them "the types" and "the missing count":

```bash
git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
git rev-list --objects --missing=print --all | grep -c '^?'
```

### Exercise 18.1 (Level 1): A shallow clone, and what it lacks

Directory `ex-18-1`. Look at the server first: `git -C server.git log --graph --oneline --decorate --all`.

**Do.**

```bash
git clone --depth 1 "file://$PWD/server.git" shallow
cd shallow
git log --oneline
git rev-parse --is-shallow-repository
cat .git/shallow
git cat-file -p HEAD | grep parent
git cat-file -t HEAD^1
git branch -r
git tag
git config get --all remote.origin.fetch
git fetch -q --unshallow
git rev-parse --is-shallow-repository
git rev-list --count HEAD
git tag
git branch -r
```

**Answer in writing.**

1. The commit object names two parents, and `git log` shows one commit. What does the file `.git/shallow` do?
2. Name three everyday commands whose answers are wrong or missing in this clone, and say why for each.
3. `--depth` implied a second restriction that is visible in the configuration. Which, and which line of the last output shows that `--unshallow` did not lift it?
4. Why did the tags appear only after `--unshallow`?

### Exercise 18.2 (Level 1): A blobless clone fetches on demand

Directory `ex-18-2`.

**Do.**

```bash
git clone -q --filter=blob:none "file://$PWD/server.git" blobless && cd blobless
git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
git rev-list --objects --missing=print --all | grep -c '^?'
git config get remote.origin.promisor
git config get remote.origin.partialclonefilter
git log --oneline -3 -- docs
git rev-list --objects --missing=print --all | grep -c '^?'
git show v0.1.0:docs/architecture.md
git rev-list --objects --missing=print --all | grep -c '^?'
```

**Answer in writing.**

1. The clone was made with `blob:none`, and it has blobs. Which ones, and what fetched them?
2. Which command changed the missing count, and which one, although it filters history by path, did not? Why?
3. What do the two configuration values do?
4. Compare with exercise 18.1: which of the three broken commands you named there work here?
5. Name a situation in which this clone fails where a full clone would not.

### Exercise 18.3 (Level 1): Cone-mode sparse checkout

Directory `ex-18-3`.

**Do.**

```bash
git clone -q "file://$PWD/server.git" work && cd work
git ls-files
git sparse-checkout set --cone services/reranker libs/tokenize
git sparse-checkout list
find . -path ./.git -prune -o -type f -print | sort
git ls-files -t
git status
git sparse-checkout disable
find . -path ./.git -prune -o -type f -print | wc -l
```

**Answer in writing.**

1. Which files are on disk after `set`, and why is `README.md` among them although you did not ask for it?
2. What do the letters `H` and `S` in `git ls-files -t` mean? Was anything removed from the index or from the object database?
3. Sparse checkout reduces one kind of size and partial clone another. Which is which?
4. What does `git status` add to its usual output here?

### Exercise 18.4 (Level 2, draw the graph): A clone of depth 2

Directory `ex-18-4`. Look at the graph of the server (`git -C server.git log --graph --oneline main`). The tip of `main` is a merge.

You will run:

```bash
git clone -q --depth 2 "file://$PWD/server.git" two
git -C two log --graph --oneline
```

**Before you run the second command, draw its output**, and write down the numbers that these commands print:

```bash
git -C two rev-list --count HEAD
wc -l < two/.git/shallow
```

**Then explain** what "depth" counts, using the merge.

### Exercise 18.5 (Level 2, command prediction): A single-branch clone

Directory `ex-18-5`. **Write down** the output of each command before you run it:

```bash
git clone -q --single-branch "file://$PWD/server.git" single && cd single
git branch -r
git config get --all remote.origin.fetch
git tag
git switch release/0.2
git fetch
```

The server has the branch `release/0.2`. **State the goal's solution before you try it:** make this clone track `release/0.2` as well, without changing how it treats any other branch, so that `git switch release/0.2` works. Then do it and show the fetch refspecs.

**Then explain** why the tags are here although the release branch is not.

### Exercise 18.6 (Level 2): History without content

Directory `ex-18-6`.

**Goal.** Starting from nothing but `server.git`, answer two questions while downloading as few blobs as possible: which commits touched `services/reranker`, and what does `services/reranker/rerank.py` contain on `main` now? Show, with the types, how many blobs your repository holds after each answer.

**Hints.** A filter; an option that keeps `git clone` from populating the working tree. A blob count of zero after the first answer is possible.

**Then explain** why the first question needs no blob at all, and why the same exercise with `--filter=tree:0` would behave differently.

### Exercise 18.7 (Level 3): A merge base that is not there

Directory `ex-18-7/ci`.

**Situation.** The pipeline runs `scripts/changed-services.sh` on a feature branch to decide which services to test. On developer machines it prints `retriever` for this branch. In the pipeline's clone it prints an error message, then nothing, and exits with status 0, so the pipeline tests nothing and reports success.

**Task.** Run the script here and find the root cause in the clone. Fix the clone so that the script gives the right answer, and name a second, cheaper way to get there. Then list every defect of the script itself that turned a missing merge base into a green pipeline.

### Exercise 18.8 (Level 3): A file that is not on disk

Directory `ex-18-8/work`.

**Situation.** A new colleague cloned the monorepo with the team's setup script. She cannot find `docs/runbook.md` on disk, although `git ls-files docs` lists it and `git status` is clean. She created `docs/notes.md`, and `git add docs/notes.md` refuses.

**Task.** Explain both observations with one cause, and show it with two commands. Give her the directory without changing anything else, and add her file. Then say what the option suggested in Git's own hint would have done instead, and why you did not use it.

### Exercise 18.9 (Level 4): The clone that believes it is up to date

```bash
exercises/gen/m18-searchstack/generate.sh
```

Read [the symptoms](gen/m18-searchstack/SYMPTOMS.md). Finish with `exercises/gen/m18-searchstack/check.sh`.

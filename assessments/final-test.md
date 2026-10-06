# The final knowledge test

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every transcript in this file is real output of the scripts in `labs/final/`. This file contains no answers. The answer key is `answer-keys/final-test-answers.md`; you receive it after you have handed in the whole test.

**Taken in** Module 40, after the ninth mastery gate. **Covers** the whole book, Chapters 1 to 30.

The test has 250 items in eighteen sections. It measures the standard the course was built for: given a state or a symptom, you name the mechanism, show the evidence, choose the lowest-risk fix, verify it, and say what prevents a repeat. Recalling a command earns little. Explaining what it does to the working tree, the index, HEAD, the refs and the remote earns the points.

## How the test is taken

| Item type | Count | Points each | How it is answered | Minutes each |
|---|---|---|---|---|
| Multiple choice | 86 | 1 | One letter. Closed book, no terminal | 1.5 |
| Command prediction | 24 | 3 | Write the output you expect, as literally as you can, and one sentence of mechanism. No terminal | 4 |
| Diagram | 16 | 3 | Draw the commit graph with every ref and HEAD, or answer the questions about the graph shown. No terminal | 5 |
| Output interpretation | 20 | 4 | A real transcript is shown. Explain what happened, line by line where it matters, and what you would do next. No terminal | 6 |
| Debugging | 42 | 4 | A situation is described. Give at least two hypotheses, the read-only command that separates them, the root cause with its layer, the fix and the prevention | 6 |
| Practical lab | 9 | 10 | A generated repository and a task card. Work in the lab shell; a `check.sh` verifies the end state | 30 |
| Incident response | 12 | 8 | Written response in the seven stages of Chapter 30, section 30.2, ending with the four-part summary of section 30.15 | 15 |
| Oral | 41 | 4 | Spoken to an examiner, or recorded. Two to three minutes per answer, no notes, no terminal | 4 |
| **Total** | **250** | **804** | | **about 21.5 hours** |

**Rules.**

1. Closed book except in the practical labs, where `git help <command>` and the manual pages are allowed and the textbook is not.
2. Where an item says "no terminal", a terminal is a failed item. The prediction items are worthless if you run them.
3. In prediction items write `<id>` where an abbreviated commit ID would appear. Lines that start with `#` in a transcript are comments that describe hidden setup or what a person did.
4. In debugging and incident items, a state-changing command given before the root cause is established loses half of the item's points, whatever follows. The read-only phase is the first thing that is marked.
5. GitHub-side items are answered from what you know of the documented behavior. Nothing in this test requires a GitHub account or a network connection.
6. The practical labs follow the generator protocol of the incident drills: run `generate.sh`, open `labs/shell` at the path it prints, work, then run `check.sh` from the course root. Running `generate.sh` again rebuilds the lab from nothing. A lab counts when its check prints `PASS` and the hand-in listed on its task card is complete: 6 points for the end state, 4 for the hand-in.

**Sittings.** Take the test in six sittings, in this order, on separate days. The time budget is the sum of the minutes per item, rounded up.

| Sitting | Sections | Items | Points | Time budget |
|---|---|---|---|---|
| 1 | 1 Fundamentals, 2 Git internals, 3 Branching | 44 | 120 | 3 h 15 min |
| 2 | 4 Merge, 5 Rebase, 6 Undo | 44 | 137 | 4 h 15 min |
| 3 | 7 Recovery, 8 Remote workflows, 9 GitHub | 42 | 134 | 4 h |
| 4 | 10 Pull requests, 11 GitHub Actions, 12 Security | 43 | 133 | 3 h 30 min |
| 5 | 13 Open source, 14 AI/ML workflows, 15 Production incidents, 16 Debugging | 50 | 184 | 5 h 30 min |
| 6 | 17 Architecture, 18 CTO interview | 27 | 96 | 2 h |

**Pass rule.** 85% of the total (684 of 804 points), at least 70% in every section, and at least seven of the nine practical labs with a passing check. A section below 70% is retaken alone after the restudy that the answer key names for each item; the labs are retaken by regenerating them.

---

## Section 1: Fundamentals (35 points)

### 1.1 Multiple choice (1 point)

Which statement describes what a commit object stores?

- A. The differences between this commit and its parent, file by file.
- B. The list of files that were staged, with a compressed copy of each one inside the commit object.
- C. The ID of one tree that describes the whole project, the IDs of the parent commits, an author, a committer and a message.
- D. The name of the branch it was made on, and the changes made on that branch since it was created.

### 1.2 Multiple choice (1 point)

You change `router.py`, run `git add router.py`, change `router.py` again, and run `git commit -m "Fix routing"` without any path or option. Which version of `router.py` is in the commit?

- A. The version on disk at the moment of the commit, because a commit records the working tree.
- B. The version that was on disk when `git add` ran, because a commit records the index.
- C. Both versions, as two entries in the commit's tree.
- D. Neither: Git refuses to commit while a staged file has further unstaged changes.

### 1.3 Multiple choice (1 point)

`settings.env` has been tracked for months. Today you add the line `*.env` to `.gitignore` and commit `.gitignore`. What happens to `settings.env`?

- A. It stays tracked; later edits still appear in `git status` and can be committed.
- B. It becomes untracked and ignored from the next commit on, and stays on disk.
- C. It is removed from every earlier commit the next time `git gc` runs.
- D. It stays tracked until the next `git add .`, which drops ignored paths from the index.

### 1.4 Multiple choice (1 point)

Which statement about HEAD is correct?

- A. HEAD is the newest commit in the repository.
- B. HEAD is another name for the tip of `main`.
- C. HEAD is a symbolic ref to the current branch, or holds a commit ID directly, in which case no branch is current.
- D. HEAD is the commit that the working tree was last synchronized with on the server.

### 1.5 Multiple choice (1 point)

A colleague runs `git clone` on a GitHub repository. Which of the following arrives in the clone?

- A. The review comments of the merged pull requests.
- B. The ruleset that protects `main`.
- C. The open issues that commits refer to with `Fixes #12`.
- D. The annotated tag `v2.0.0`.

### 1.6 Multiple choice (1 point)

You run `git mv loader.py reader.py` and commit, without editing the file. What does the new commit contain that records the rename?

- A. A rename entry in the commit object that links the old path to the new one.
- B. A new blob for `reader.py`, and a deletion marker for the blob of `loader.py`.
- C. Nothing that says "rename": its tree lists the same blob ID under the new name, and tools infer the rename when they compare trees.
- D. A line in the index that `git log --follow` reads later.

### 1.7 Command prediction (3 points)

<!-- snippet: final/s01/p1-setup -->
```text
$ git init -q tracecollect
$ cd tracecollect
$ printf 'boot ok\n' > service.log
$ printf 'PORT=8080\n' > settings.env
$ git add .
$ git commit -q -m "Add service skeleton"
$ printf '*.log\n*.env\n' > .gitignore
$ printf 'boot ok\nretry 1\n' > service.log
$ printf 'debug trace\n' > worker.log
$ git add .
```
<!-- /snippet -->

Predict the output of these three commands, including the exit status of the last one, and say in one sentence why `service.log` and `worker.log` are treated differently.

```bash
git status --short
git status --short --ignored
git check-ignore -v service.log worker.log
```

### 1.8 Command prediction (3 points)

<!-- snippet: final/s01/p2-setup -->
```text
$ git init -q seedbank
$ cd seedbank
$ printf 'seed: 13\n' > seeds.yaml
$ printf 'def split(rows):\n    return rows[:80], rows[80:]\n' > old_split.py
$ git add .
$ git commit -q -m "Add seeds and the split"
$ printf 'seed: 42\n' > seeds.yaml
$ rm old_split.py
$ printf 'def split(rows, ratio):\n    cut = int(len(rows) * ratio)\n    return rows[:cut], rows[cut:]\n' > new_split.py
$ git commit -q -a -m "Change the seed and the split"
```
<!-- /snippet -->

Predict the output of the two commands below. Then say what a colleague who pulls this commit and imports `split` will find.

```bash
git show --name-status --format=%s HEAD
git status --short
```

### 1.9 Diagram (3 points)

<!-- snippet: final/s01/g1-setup -->
```text
$ git init -q tilecache
$ cd tilecache
$ printf 'ttl: 60\n' > cache.yaml
$ git add cache.yaml
$ git commit -q -m "Add cache settings"
$ printf 'ttl: 120\n' > cache.yaml
$ git add cache.yaml
$ printf 'ttl: 300\n' > cache.yaml
$ git commit -q -m "Raise the TTL"
$ printf 'ttl: 600\n' > cache.yaml
$ git add cache.yaml
$ printf 'ttl: 900\n' > cache.yaml
$ git restore --staged cache.yaml
```
<!-- /snippet -->

Draw three boxes side by side, labelled HEAD, index and working tree, and write into each the content of `cache.yaml` it holds after the last command. Below the boxes write the output of `git status --short`, and say which of the five values the file has had (60, 120, 300, 600, 900) is stored in a commit, which exists only as a blob that no commit and no index entry names, and which was never stored as an object.

### 1.10 Output interpretation (4 points)

A module is renamed without being edited:

<!-- snippet: final/s01/i1-transcript -->
```text
$ git mv hashing.py fingerprint.py
$ git status --short
R  hashing.py -> fingerprint.py
$ git commit -q -m "Name the module after what it computes"
$ git log --oneline -- fingerprint.py
5b207fc Name the module after what it computes
$ git log --oneline --follow -- fingerprint.py
5b207fc Name the module after what it computes
2888a4d Add text fingerprint
$ git ls-tree HEAD~1
100644 blob 85ba132fd60306c46e4e9903bd967f189aa0a3b4	hashing.py
$ git ls-tree HEAD
100644 blob 85ba132fd60306c46e4e9903bd967f189aa0a3b4	fingerprint.py
$ git diff --name-status --no-renames HEAD~1 HEAD
A	fingerprint.py
D	hashing.py
```
<!-- /snippet -->

Explain: (a) why the first `git log` prints one commit and the second prints two; (b) what the two `git ls-tree` outputs prove about how the rename is stored; (c) why the last command reports an addition and a deletion, and what decides whether Git reports a rename instead; (d) one situation in which `--follow` would not find the older commit.

### 1.11 Debugging (4 points)

`git status` in a service repository prints "nothing to commit, working tree clean". `git pull` then stops with "Your local changes to the following files would be overwritten by merge: config/local.yaml". The engineer insists that nothing was edited, and `git diff` prints nothing.

Give two hypotheses, the one read-only command that separates them, the root cause, the lowest-risk fix, and what the team should do instead of the habit that caused this.

### 1.12 Debugging (4 points)

A deployment gate compares the commit ID that reviewers approved with the commit ID at the tip of the release branch, and refuses to deploy: the IDs differ. The author says: "I only ran `git commit --amend --no-edit` to trigger the hook again. I changed nothing." `git diff` between the two commits prints nothing.

Explain why the IDs differ although the content is equal, give the command that proves the content is equal, and say what you would do about the blocked deployment and about the gate.

### 1.13 Oral (4 points)

A pull request is merged with the "Create a merge commit" button. Take the CTO through what exists afterwards, and for each thing say whether it is Git data that arrives in every clone or a GitHub object that does not.

### 1.14 Oral (4 points)

Describe what changes inside `.git` when you run `git add report.py` on a modified tracked file, and then what changes when you run `git commit`. Name the objects that are written at each step and the refs and files that are updated.

---

## Section 2: Git internals (42 points)

### 2.1 Multiple choice (1 point)

A repository contains `eu/service.yaml` and `us/service.yaml` with byte-identical content. How many blob objects store them?

- A. Two, because the paths differ.
- B. One, because a blob's ID is computed from its content and the path is stored in the tree.
- C. Two until `git gc` runs, then one.
- D. One blob and one delta that records the second path.

### 2.2 Multiple choice (1 point)

You run `git reset --hard HEAD~3` on a local branch and never refer to the three commits again. With default settings and no manual expiry, when can `git gc` first delete them?

- A. Immediately: the reset removes them from the object database.
- B. At the next automatic `git gc`, because nothing reachable from a branch needs them.
- C. Once their reflog entries have expired (30 days by default for entries that the current tip does not reach) and the objects are older than the prune grace period.
- D. Never, unless you run `git prune` by hand.

### 2.3 Multiple choice (1 point)

A colleague argues: "Packfiles store deltas, so a commit is a diff after all." Which reply is correct?

- A. Agreed: after `git gc` each commit holds the difference to its parent commit.
- B. Delta compression is a storage detail inside a pack: Git picks similar objects as delta bases, whatever their place in history, and every object still reads back as a full snapshot.
- C. Only merge commits are stored as deltas; ordinary commits stay full.
- D. Deltas are stored in the index, not in packs, so the object model is unaffected.

### 2.4 Multiple choice (1 point)

Which description of the index is correct?

- A. A list of the paths that have changed since the last commit.
- B. A queue of diffs that `git commit` applies to the previous tree.
- C. One file that lists every tracked path with a mode, a blob ID and a stage number, and so describes the whole next snapshot.
- D. A cache that only speeds up `git status` and plays no part in what a commit contains.

### 2.5 Multiple choice (1 point)

Which clone has every commit and every tree of the project and downloads file contents only when a command needs them?

- A. `git clone --depth 1 <url>`
- B. `git clone --single-branch <url>`
- C. `git clone --filter=blob:none <url>`
- D. `git clone --no-checkout <url>`

### 2.6 Multiple choice (1 point)

Which of these actions leaves the ID of an existing commit unchanged?

- A. Changing its message with `git commit --amend`.
- B. Replaying it onto another parent with `git rebase`.
- C. Creating a lightweight tag that points at it.
- D. Recommitting it with `git commit --amend --no-edit --reset-author`.

### 2.7 Command prediction (3 points)

<!-- snippet: final/s02/p1-setup -->
```text
$ git init -q modelzoo
$ cd modelzoo
$ git commit -q --allow-empty -m "Add the model registry"
$ git tag candidate
$ git tag -a v1.0 -m "Release 1.0"
```
<!-- /snippet -->

Predict the output of the commands below. For the loop, it is enough to say which of the four lines are equal. Then say what `git push origin v1.0` transfers that `git push origin candidate` does not.

```bash
git count-objects | cut -d, -f1
git cat-file -t candidate
git cat-file -t v1.0
for r in HEAD candidate v1.0 "v1.0^{commit}"; do git rev-parse --short "$r"; done
```

### 2.8 Command prediction (3 points)

<!-- snippet: final/s02/p2-setup -->
```text
$ git init -q refstore
$ cd refstore
$ git commit -q --allow-empty -m "First"
$ git branch topic
$ git pack-refs --all
```
<!-- /snippet -->

(a) Predict the output of `ls .git/refs/heads` and of `git branch --list` at this point.

<!-- snippet: final/s02/p2-setup-b -->
```text
$ git commit -q --allow-empty -m "Second"
```
<!-- /snippet -->

(b) Predict the output of `ls .git/refs/heads` now. The file `.git/packed-refs` still has a line for `refs/heads/main`: does that line show the first or the second commit, and which of the two does `git rev-parse main` print? Say why.

### 2.9 Command prediction (3 points)

<!-- snippet: final/s02/p3-setup -->
```text
$ git init -q deployer
$ cd deployer
$ git commit -q --allow-empty -m "Add the deploy script"
```
<!-- /snippet -->

A deploy script contains each of the three lines below in turn. Predict what each one prints, and say which line belongs in a script and why.

```bash
target=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? target=[$target]"
target=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? target=[$target]"
target=$(git rev-parse --verify --quiet "main^{commit}"); echo "status=$? length=${#target}"
```

### 2.10 Diagram (3 points)

<!-- snippet: final/s02/g1-setup -->
```text
$ git init -q labelsync
$ cd labelsync
$ git commit -q --allow-empty -m "Add the label schema"
$ git commit -q --allow-empty -m "Add the export job"
$ git branch review HEAD~1
$ git tag -a v0.1 -m "First schema" HEAD~1
$ git switch -q --detach v0.1
```
<!-- /snippet -->

Draw the two commits and every ref. For each ref write its full name and the type of the object it points at. Then write what the file `.git/HEAD` contains (a ref name, a tag name or a commit ID, and of which object), and what `git symbolic-ref HEAD` does.

### 2.11 Output interpretation (4 points)

<!-- snippet: final/s02/i1-transcript -->
```text
$ git ls-tree HEAD
100644 blob 635645b3622a17850f8b82dfc94065fd8db30f75	README.md
100755 blob 75adf17945069812d12533afd5ddcf2d2f08dd56	build.sh
040000 tree 0d7bea658d7f920762bc776add9ac79d1fb90f61	conf
120000 blob b897657486a900352187e2b2e7ea3aca663e2cf4	current.yaml
040000 tree e04ce330a3a2c98a0d77da720baeebaed2a3961f	vendor
$ git cat-file -p HEAD:current.yaml; echo
conf/prod.yaml
$ git ls-tree HEAD vendor/
160000 commit 0293c36efbee8bdd13caf4fed6b7b17aa86ef208	vendor/tokenizer
$ git cat-file -t HEAD:conf
tree
[exit status: 0]
```
<!-- /snippet -->

Explain each of the five mode values that appear (`100644`, `100755`, `040000`, `120000`, `160000`): what kind of entry it is and what the object ID next to it names. Then answer: what is stored in the blob of `current.yaml`, and what does a plain `git clone` of this repository put into `vendor/tokenizer`?

### 2.12 Output interpretation (4 points)

Three commits were made, a branch `backup` was created and deleted again, and `main` was reset by one commit. Then:

<!-- snippet: final/s02/i2-transcript -->
```text
$ git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 9
in-pack: 0
packs: 0
$ ls .git/refs/heads
main
$ git gc --quiet
$ git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 0
in-pack: 9
packs: 1
$ ls .git/refs/heads
$ git log --oneline
b840e3c Run batch 2
79789e9 Run batch 1
$ git cat-file -t 125fcaa
commit
$ git reflog -2
b840e3c HEAD@{0}: reset: moving to HEAD~1
125fcaa HEAD@{1}: commit: Run batch 3
```
<!-- /snippet -->

Explain: (a) what `git gc` did to the nine objects and to the file under `.git/refs/heads`; (b) why `git log` and `git branch` behave as before although that file is gone; (c) why the commit that the reset removed from `main` still exists after the collection; (d) what would have to be true for a collection to delete it.

### 2.13 Debugging (4 points)

A release script stamps every build with the commit of `main`:

```bash
grep ' refs/heads/main$' .git/packed-refs | cut -d' ' -f1
```

It worked on the build server for a year. Since Tuesday the stamp has been the same commit ID for every build, although `main` moves several times a day and `git log -1 main` on the same machine shows the newest commit.

Give the mechanism, the root cause, the corrected line, and the rule for scripts that follows.

### 2.14 Debugging (4 points)

A nightly job produces a "who last changed each line of the pricing rules" report with `git blame`. Since the job moved to a new CI system, every line of every file is attributed to the same commit, the newest one, and `git log --oneline | wc -l` prints 1 in the job. On laptops the report is right.

Give two hypotheses, the command that separates them, the root cause with its layer, two fixes with their cost, and the rule for which jobs may keep the fast setting.

### 2.15 Oral (4 points)

What is reachability? Name the starting points Git uses, and explain why every recovery technique in this course is a consequence of it.

### 2.16 Oral (4 points)

Explain loose objects, packfiles and what `git gc` does to each. What does a collection never delete, and which two commands remove the protection that a collection respects?

---

## Section 3: Branching (43 points)

### 3.1 Multiple choice (1 point)

What does `git branch feature/tokens` create?

- A. A copy of the project's files under a new name.
- B. One ref, `refs/heads/feature/tokens`, that holds the ID of the current commit.
- C. A new line of commits that records `main` as its parent branch.
- D. A new commit that marks where the branch starts.

### 3.2 Multiple choice (1 point)

A release engineer asks Git: "From which branch was `feature/streaming` created?" What can the repository's shared data answer?

- A. The parent branch, stored in the first commit of the branch.
- B. The parent branch, stored in `.git/config` on the server.
- C. Nothing of the kind: a branch is a ref to one commit, and Git can only compute the merge base of two branches you name.
- D. The parent branch, through `git branch --contains`.

### 3.3 Multiple choice (1 point)

You check out a tag, make two commits, and run `git switch main`. What is true of the two commits right after the switch?

- A. They were added to the tag, which now points at the second one.
- B. They were discarded when HEAD left them.
- C. They are on `main`, because commits made without a branch go to the default branch.
- D. No branch or tag contains them; they exist and are reachable only through the reflog of HEAD.

### 3.4 Multiple choice (1 point)

When does `git branch -d topic` refuse to delete?

- A. When the tip of `topic` is not reachable from its upstream branch or, if it has none, from HEAD.
- B. When `topic` has no upstream branch.
- C. When `topic` has commits that are newer than the tip of `main`.
- D. When another branch was created from `topic`.

### 3.5 Multiple choice (1 point)

What does `git branch -D spike/cache` remove at once?

- A. The ref and its reflog; the commits stay in the object database.
- B. The ref, its reflog and every commit that only that branch contained.
- C. The ref only; `git reflog show spike/cache` keeps working for 90 days.
- D. The ref and the matching branch on the server.

### 3.6 Command prediction (3 points)

<!-- snippet: final/s03/p1-setup -->
```text
$ git init -q slotfill
$ cd slotfill
$ git commit -q --allow-empty -m "Add the slot schema"
$ git commit -q --allow-empty -m "Add the slot parser"
$ git branch docs/schema HEAD~1
$ git switch -q -c parser-v2
$ git commit -q --allow-empty -m "Rewrite the parser"
$ git switch -q main
```
<!-- /snippet -->

Predict the output of the four commands, including the exit status of the last one.

```bash
git branch --merged main
git branch --no-merged main
git branch --contains docs/schema
git branch -d parser-v2
```

### 3.7 Command prediction (3 points)

<!-- snippet: final/s03/p2-setup -->
```text
$ git init -q notifier
$ cd notifier
$ git commit -q --allow-empty -m "Add the notifier"
$ git branch feature
```
<!-- /snippet -->

Predict, for each of the first two commands, whether it succeeds or fails and with what kind of message. Then predict the output of the third.

```bash
git branch feature/retry
git branch -m feature feature/retry
git branch --list
```

### 3.8 Diagram (3 points)

<!-- snippet: final/s03/g1-setup -->
```text
$ git init -q embedjob
$ cd embedjob
$ git commit -q --allow-empty -m "A: add the job runner"
$ git commit -q --allow-empty -m "B: add the retry policy"
$ git switch -q -c feature/batching
$ git commit -q --allow-empty -m "C: batch the requests"
$ git switch -q main
$ git commit -q --allow-empty -m "D: log the job duration"
$ git switch -q -c hotfix/timeout HEAD~1
$ git commit -q --allow-empty -m "E: raise the timeout"
$ git switch -q feature/batching
$ git commit -q --allow-empty -m "F: flush partial batches"
$ git tag v0.2 main
```
<!-- /snippet -->

Draw the commit graph with the letters A to F, every branch, the tag and HEAD. Then name the merge base of `feature/batching` and `hotfix/timeout`.

### 3.9 Diagram (3 points)

<!-- snippet: final/s03/g2-graph -->
```text
$ git log --graph --oneline --all --decorate
* 33f761d (HEAD -> main) G: document the tracing headers
*   8c70090 M: merge feature/rerank
|\  
* | 88f1cd0 (tag: v1.0) E: add request tracing
| | * 8fde92f (feature/rerank) F: tune the batch size
| |/  
| * 3df7c78 D: cache the scores
| * e480e5a C: add the cross-encoder
|/  
* 15d4d59 B: add the scorer
* 8efbcc7 A: add the candidate fetcher
```
<!-- /snippet -->

Answer from the graph, without a terminal. Give commits by their letter.

1. What is the merge base of `main` and `feature/rerank`?
2. Which commits does `git log main..feature/rerank` list, and which does `git log feature/rerank..main` list?
3. Which commits do `main~2` and `main~1^2` name? Does `main^2` exist?
4. Is `v1.0` an ancestor of `feature/rerank`?
5. Which commits does `git log --first-parent main` list?

### 3.10 Output interpretation (4 points)

<!-- snippet: final/s03/i1-transcript -->
```text
$ git worktree add -q ../edgeproxy-hotfix -b hotfix/tls-reload
$ git branch -vv
  feature/http3     6f054aa Add connection pooling
+ hotfix/tls-reload 6f054aa ($LAB/final/s03/edgeproxy-hotfix) Add connection pooling
* main              6f054aa Add connection pooling
$ git switch hotfix/tls-reload
fatal: 'hotfix/tls-reload' is already used by worktree at '$LAB/final/s03/edgeproxy-hotfix'
[exit status: 128]
$ git branch -d hotfix/tls-reload
error: cannot delete branch 'hotfix/tls-reload' used by worktree at '$LAB/final/s03/edgeproxy-hotfix'
[exit status: 1]
$ git -C ../edgeproxy-hotfix commit -q --allow-empty -m "Reload certificates without a restart"
$ git log --oneline -1 hotfix/tls-reload
13f4fa6 Reload certificates without a restart
```
<!-- /snippet -->

Explain: (a) what the `+` and the path in the output of `git branch -vv` mean; (b) why the switch and the deletion are refused; (c) how the branch ref could move without any command in this directory moving it, and what that tells you about what two worktrees share and do not share; (d) the lowest-risk way to work on `hotfix/tls-reload` from this directory if you must.

### 3.11 Debugging (4 points)

Since this morning `git fetch` fails on every laptop in the team with:

```text
error: cannot lock ref 'refs/remotes/origin/sweep/lr-warmup': 'refs/remotes/origin/sweep' exists; cannot create 'refs/remotes/origin/sweep/lr-warmup'
```

New clones work. Nobody changed their configuration. Reconstruct what happened on the server, explain why old clones fail and new ones do not, give the fix for a laptop, and the naming rule that prevents it.

### 3.12 Debugging (4 points)

An engineer keeps a second working tree of the same repository for running long evaluations. In that directory, where nobody has edited anything for a week, `git status` shows "Changes to be committed", and `git diff --cached` shows the exact inverse of the commit that a colleague pair-programmed with him in the first directory an hour ago. He is about to run `git commit -m "sync"` there.

Say what state produces this, how it could arise, what the commit he is about to make would do, and the fix for each of the two cases: the second directory has no work of its own, or it has.

### 3.13 Practical lab (10 points)

The task card is [`assessments/gen/final-branching/TASK.md`](gen/final-branching/TASK.md).

```bash
assessments/gen/final-branching/generate.sh
assessments/gen/final-branching/check.sh
```

### 3.14 Oral (4 points)

Define HEAD, a branch and a remote-tracking branch, each in one sentence that says where it is stored and what moves it. Then explain what `git status` compares when it prints "Your branch is up to date with 'origin/main'".

---

## Section 4: Merge (47 points)

### 4.1 Multiple choice (1 point)

In a three-way merge, a line was changed on your side and is unchanged on the other side, compared with the merge base. What does Git put into the result?

- A. The other side's version, because the branch being merged in wins.
- B. Your version, because exactly one side changed it.
- C. A conflict, because the two tips differ on that line.
- D. Whichever version has the newer commit date.

### 4.2 Multiple choice (1 point)

`main` has not moved since `feature/audit` was created from it. You are on `main` and run `git merge feature/audit` with default settings. What is created?

- A. A merge commit with two parents.
- B. A merge commit with one parent.
- C. Nothing: the ref `main` is moved to the tip of `feature/audit`.
- D. Copies of the branch's commits with new IDs on `main`.

### 4.3 Multiple choice (1 point)

Two branches each changed one line of the same file: line 7 on one branch, line 8 on the other. The merge stops with a conflict. Why?

- A. Git compares whole files, and both branches changed the file.
- B. The two changes are adjacent: with no unchanged line between them they form one region that both sides changed.
- C. The commits were made within the same minute.
- D. One of the branches was rebased earlier.

### 4.4 Multiple choice (1 point)

Branch A renames the function `score()` to `grade()` and updates every caller. Branch B adds a new file that calls `score()`. Both pass their tests. They are merged without a conflict, and the result fails. Which explanation is correct?

- A. The merge used the wrong merge base.
- B. Rename detection failed below the similarity threshold.
- C. One of the branches must have been force-pushed.
- D. Git merged the paths correctly by its rules; the dependency between the two changes is in the language, not in the text of any one file, and Git does not parse or test code.

### 4.5 Multiple choice (1 point)

A long-lived branch was squash-merged into `main` last week. The team kept working on the same branch and squash-merges it again today. The merge conflicts on lines that last week's squash already delivered. Why?

- A. A squash commit has one parent, so the merge base of `main` and the branch is still the original fork point.
- B. Squash merges disable rename detection.
- C. The reflog of `main` expired between the two merges.
- D. The second squash uses the "theirs" strategy by default.

### 4.6 Command prediction (3 points)

<!-- snippet: final/s04/p1-setup -->
```text
$ git init -q samplerconf
$ cd samplerconf
$ printf 'temperature: 0.7\ntop_p: 0.9\n' > sampling.yaml
$ printf 'max_tokens: 256\n' > limits.yaml
$ git add .
$ git commit -q -m "Add sampling defaults"
$ git switch -q -c feature/deterministic
$ printf 'temperature: 0.0\ntop_p: 0.9\n' > sampling.yaml
$ printf 'max_tokens: 1024\n' > limits.yaml
$ git commit -q -a -m "Deterministic sampling, longer answers"
$ git switch -q main
$ printf 'temperature: 0.2\ntop_p: 0.9\n' > sampling.yaml
$ git commit -q -a -m "Lower the temperature"
$ git merge -q -X ours -m "Merge feature/deterministic" feature/deterministic
Auto-merging sampling.yaml
```
<!-- /snippet -->

Predict the content of `sampling.yaml` and of `limits.yaml` after the merge, and say how the result would differ with `-s ours` instead of `-X ours`.

### 4.7 Command prediction (3 points)

<!-- snippet: final/s04/p2-setup -->
```text
$ git init -q indexer
$ cd indexer
$ printf 'shards: 4\n' > index.yaml
$ git add . && git commit -q -m "Add index settings"
$ git switch -q -c feature/replicas
$ printf 'replicas: 2\n' > replicas.yaml
$ git add . && git commit -q -m "Add replica settings"
$ git switch -q main
$ printf 'shards: 8\n' > index.yaml
$ git commit -q -a -m "Double the shards"
```
<!-- /snippet -->

Predict the outcome of each command: success or failure, the exit status, and what has changed in the repository afterwards.

```bash
git merge --ff-only feature/replicas
git status -sb
git merge-tree --write-tree --name-only main feature/replicas
```

### 4.8 Diagram (3 points)

<!-- snippet: final/s04/g1-setup -->
```text
$ git init -q metricsd
$ cd metricsd
$ git commit -q --allow-empty -m "A: add the collector"
$ git switch -q -c feature/histograms
$ git commit -q --allow-empty -m "B: add histograms"
$ git switch -q -c feature/exemplars main
$ git commit -q --allow-empty -m "C: add exemplars"
$ git switch -q main
$ git commit -q --allow-empty -m "D: add the scrape endpoint"
$ git merge -q -m "M: merge histograms and exemplars" feature/histograms feature/exemplars
Trying simple merge with feature/histograms
Trying simple merge with feature/exemplars
```
<!-- /snippet -->

Draw the commit graph with the letters A to D and M, every branch and HEAD. State how many parents M has, in which order, and which commits `git log --first-parent main` lists.

### 4.9 Diagram (3 points)

<!-- snippet: final/s04/g2-graph -->
```text
$ git log --graph --oneline --all --decorate
*   7907a49 (HEAD -> develop) M2: merge main into develop
|\  
| | * b628314 (main) M1: merge develop into main
| |/| 
| |/  
|/|   
* | c056393 C: add tax settings
| * f0e9e3e B: add rounding settings
|/  
* 1f7591d A: add price settings
```
<!-- /snippet -->

Answer from the graph, without a terminal.

1. Which commit or commits does `git merge-base --all main develop` print?
2. What is this shape called, and how did the two branches produce it?
3. If you now merge `develop` into `main` and a file conflicts, what does Git use as the base version of that file?

### 4.10 Output interpretation (4 points)

The branch `refactor/layout` moved a file. The branch `fix/empty-input`, created before the move, edited the file at its old path.

<!-- snippet: final/s04/i1-transcript -->
```text
$ git ls-files
chunking/split.py
$ git log --oneline --name-status -1 fix/empty-input
c928575 Return an empty list for empty input
M	utils/text.py
$ git merge -m "Merge fix/empty-input" fix/empty-input
Merge made by the 'ort' strategy.
 chunking/split.py | 2 ++
 1 file changed, 2 insertions(+)
$ git ls-files
chunking/split.py
$ grep -n "if not words" -A1 chunking/split.py
3:    if not words:
4-        return []
```
<!-- /snippet -->

Explain: (a) why the fix landed in `chunking/split.py` although the fix branch never had that path; (b) where the information "this file was moved" comes from; (c) under which condition Git would have reported `CONFLICT (modify/delete)` instead; (d) how you would check after such a merge that nothing was left behind at the old path.

### 4.11 Output interpretation (4 points)

<!-- snippet: final/s04/i2-transcript -->
```text
$ git merge cleanup/remove-v1
CONFLICT (modify/delete): v1.py deleted in cleanup/remove-v1 and modified in HEAD.  Version HEAD of v1.py left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UD v1.py
$ git ls-files -u
100644 9101d82937b98d653f0d3076c0243e5a1679b71f 1	v1.py
100644 0b75e9a4cf40a57a04ac4c7425bd5ef9e3a56ac0 2	v1.py
$ ls
v1.py
v2.py
```
<!-- /snippet -->

Explain: (a) what `UD` means and which side is which; (b) why `git ls-files -u` shows stages 1 and 2 and no stage 3; (c) what is in the working tree file and why there are no conflict markers; (d) the exact commands for each of the two possible resolutions.

### 4.12 Debugging (4 points)

A formatting branch re-indents the whole code base. To avoid conflicts with open work, the team lead merges it into `main` with `git merge -X ignore-space-change style/reindent`. The merge succeeds, the branch counts as merged, and half of the files on `main` are still in the old indentation.

Explain the mechanism, state what the option does with a line that their side only re-indented and our side kept or changed, give the fix, and say how a formatting change should be landed.

### 4.13 Debugging (4 points)

You merge `main` into your branch and get `CONFLICT (modify/delete)` on `retrieval/ranker.py`: "deleted in main and modified in HEAD". Nobody on the team decided to delete the ranker. On `main` there is a new file `ranking/bm25.py` that contains some of the same functions and a great deal of new code, added in the same commit that removed the old file.

Give the root cause, the command that would show you how similar the two files are, two ways to finish the merge without losing your edit, and the practice that prevents this.

### 4.14 Practical lab (10 points)

The task card is [`assessments/gen/final-merge/TASK.md`](gen/final-merge/TASK.md).

```bash
assessments/gen/final-merge/generate.sh
assessments/gen/final-merge/check.sh
```

### 4.15 Oral (4 points)

"Git merged it without a conflict, so the merge is correct." Take this sentence apart. Say what a clean merge does and does not guarantee, and name the controls that cover the gap.

---

## Section 5: Rebase (47 points)

### 5.1 Multiple choice (1 point)

Why does every commit get a new ID when a branch is rebased onto a newer `main`, even when no file content had to be merged by hand?

- A. Rebase re-compresses the objects, and compression changes the hash.
- B. The ID is a hash of the commit object, which contains the parent ID and the committer line; both change.
- C. Git assigns IDs in the order commits are created in a repository.
- D. Only the first commit gets a new ID; its descendants keep theirs.

### 5.2 Multiple choice (1 point)

`git rebase main` stops with a conflict while replaying your commit. In the conflicted file, which version does `--ours` (stage 2) refer to?

- A. Your commit that is being replayed.
- B. Whichever version is newer.
- C. The merge base of your branch and `main`.
- D. The commits you are rebasing onto: the tip built so far on top of `main`.

### 5.3 Multiple choice (1 point)

Your branch `feature/b` was created on top of a colleague's branch `feature/a`. `feature/a` was squash-merged into `main`. You run `git rebase main` on `feature/b` and get conflicts in files you never touched. Why, and what is the right command?

- A. Rebase replays every commit that is not reachable from `main`, and the commits of `feature/a` are not: `main` has their content in another commit. Name the boundary: `git rebase --onto main feature/a feature/b`.
- B. `main` is corrupt; re-clone.
- C. The squash commit must be reverted first.
- D. `git rebase` cannot be used on a branch that was created from another branch; merge instead.

### 5.4 Multiple choice (1 point)

Asha pushed a commit to a shared branch. You then rebased the branch without her commit and force-pushed. Asha runs `git pull --rebase`; it reports success, and her commit is no longer in her branch. Which mechanism removed it?

- A. `pull --rebase` replays only commits after the fork point, which it finds through the reflog of her remote-tracking branch; her pushed commit was once the tip of that ref, so nothing is left to replay.
- B. The server deleted her commit object during your push, and the fetch synchronized the deletion.
- C. Her local reflog was overwritten by the fetch.
- D. `pull --rebase` always resets the local branch to the remote branch.

### 5.5 Multiple choice (1 point)

A rebase has finished and the result is wrong. Nothing else has been done since. Which command returns the branch to its state before the rebase?

- A. `git rebase --abort`
- B. `git revert HEAD`
- C. `git reset --hard ORIG_HEAD`
- D. `git pull`

### 5.6 Command prediction (3 points)

<!-- snippet: final/s05/p1-setup -->
```text
$ git init -q citations
$ cd citations
$ git commit -q --allow-empty -m "Add the citation style"
$ git switch -q -c feature/doi
# Asha makes the next commit, on her machine, with her identity.
$ git commit -q --allow-empty -m "Resolve DOIs"
# You continue, with your identity, some minutes later.
$ git switch -q main
$ git commit -q --allow-empty -m "Add the BibTeX export"
$ git switch -q feature/doi
$ git rebase -q main
```
<!-- /snippet -->

For the commit "Resolve DOIs" before the rebase (`ORIG_HEAD`) and after it (`HEAD`), predict the author name, the committer name, and whether the author time and the committer time are equal. Say whether the two commit IDs are equal.

### 5.7 Command prediction (3 points)

<!-- snippet: final/s05/p2-setup -->
```text
$ git init -q summarizer
$ cd summarizer
$ printf 'max_len: 200\n' > summary.yaml
$ git add . && git commit -q -m "Add summarizer settings"
$ git switch -q -c feature/long-docs
$ printf 'max_len: 800\n' > summary.yaml
$ git commit -q -a -m "Allow long documents"
$ printf 'stride: 400\n' > window.yaml
$ git add . && git commit -q -m "Add a sliding window"
$ git switch -q main
$ printf 'max_len: 300\n' > summary.yaml
$ git commit -q -a -m "Raise the default length"
$ git switch -q feature/long-docs
$ git rebase main > /dev/null 2>&1
```
<!-- /snippet -->

The rebase has stopped at a conflict. Predict the output of each command. For the two `git log` lines it is enough to give the subject.

```bash
git branch --show-current
git rev-parse --abbrev-ref HEAD
cat .git/rebase-merge/head-name
git log --oneline -1 feature/long-docs
git log --oneline -1 HEAD
git status --short
```

### 5.8 Diagram (3 points)

<!-- snippet: final/s05/g1-setup -->
```text
$ git init -q etlflow
$ cd etlflow
$ git commit -q --allow-empty -m "A: add the scheduler"
$ git switch -q -c stack/extract
$ git commit -q --allow-empty -m "B: extract from the API"
$ git switch -q -c stack/transform
$ git commit -q --allow-empty -m "C: normalize the records"
$ git switch -q -c stack/load
$ git commit -q --allow-empty -m "D: load into the warehouse"
$ git switch -q main
$ git commit -q --allow-empty -m "E: add retries to the scheduler"
$ git switch -q stack/load
```
<!-- /snippet -->

The graph before:

<!-- snippet: final/s05/g1-before -->
```text
$ git log --graph --oneline --all --decorate
* 4987d91 (main) E: add retries to the scheduler
| * 8bd0fba (HEAD -> stack/load) D: load into the warehouse
| * e2fe762 (stack/transform) C: normalize the records
| * b18d14d (stack/extract) B: extract from the API
|/  
* 77f19a6 A: add the scheduler
```
<!-- /snippet -->

Then one command is run:

<!-- snippet: final/s05/g1-command -->
```text
$ git rebase -q --update-refs main
```
<!-- /snippet -->

Draw the graph afterwards with all four branches. Then say where `stack/extract` and `stack/transform` would point if `--update-refs` had been left out.

### 5.9 Diagram (3 points)

The branch `feature/lookup` has four commits on top of `main`:

<!-- snippet: final/s05/g2-before -->
```text
$ git log --oneline main..feature/lookup
3935c00 Fix a typo in the synonyms
8534d40 wip: debug print
ec40242 Add synonyms
6f34b54 Add term lookup
```
<!-- /snippet -->

You run `git rebase -i main` and change the todo list so that the first two lines stay `pick`, the third line (`wip: debug print`) becomes `drop`, and the fourth line (`Fix a typo in the synonyms`) becomes `fixup`.

Draw the branch afterwards: how many commits, with which subjects. Mark every commit that keeps its original ID, and explain why it does.

### 5.10 Output interpretation (4 points)

A branch with three commits is rebased onto `main`:

<!-- snippet: final/s05/i1-transcript -->
```text
$ git rebase main 2>&1 | grep -v "^hint:"
warning: skipped previously applied commit 4619b66
Rebasing (1/2)
Auto-merging evaluate.py
CONFLICT (content): Merge conflict in evaluate.py
error: could not apply 0645ad4... Raise the pass threshold and add a strict report
Could not apply 0645ad4... # Raise the pass threshold and add a strict report
$ git diff --name-only --diff-filter=U
evaluate.py
# You open evaluate.py in the editor, set the threshold to 0.85, and save.
$ git add evaluate.py
$ git rebase --continue 2>&1 | grep -v "^hint:"
[detached HEAD fd34f44] Raise the pass threshold and add a strict report
 1 file changed, 11 insertions(+), 1 deletion(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/strict-eval.
$ git range-diff main ORIG_HEAD HEAD
1:  0645ad4 ! 1:  fd34f44 Raise the pass threshold and add a strict report
    @@ Commit message
     
      ## evaluate.py ##
     @@
    --THRESHOLD = 0.50
    -+THRESHOLD = 0.80
    +-THRESHOLD = 0.60
    ++<<<<<<< HEAD
    ++=======
    ++THRESHOLD = 0.85
    ++>>>>>>> 0645ad4 (Raise the pass threshold and add a strict report)
      METRIC = "f1"
      
      
2:  4619b66 < -:  ------- Fix the random seed
3:  f7587ca = 2:  62f0afe Use ten folds
```
<!-- /snippet -->

Explain: (a) the first line of the rebase output, and which line of the `range-diff` shows its consequence; (b) what `!`, `<` and `=` mean in the first column pairs; (c) what the inner diff under the first pair tells you about the rebased commit; (d) whether this branch is fit to push, and the lowest-risk way to repair it.

### 5.11 Output interpretation (4 points)

The same repository, right after the rebase of item 5.10:

<!-- snippet: final/s05/i2-transcript -->
```text
$ git reflog -7
62f0afe HEAD@{0}: rebase (finish): returning to refs/heads/feature/strict-eval
62f0afe HEAD@{1}: rebase (pick): Use ten folds
fd34f44 HEAD@{2}: rebase (continue): Raise the pass threshold and add a strict report
bb3d10e HEAD@{3}: rebase (start): checkout main
f7587ca HEAD@{4}: checkout: moving from main to feature/strict-eval
bb3d10e HEAD@{5}: commit: Fix the random seed
9091346 HEAD@{6}: commit: Raise the threshold a little
$ git reflog show feature/strict-eval
62f0afe feature/strict-eval@{0}: rebase (finish): refs/heads/feature/strict-eval onto bb3d10e70c2a7a04fdcfc21edc3541909816542c
f7587ca feature/strict-eval@{1}: commit: Use ten folds
4619b66 feature/strict-eval@{2}: commit: Fix the random seed
0645ad4 feature/strict-eval@{3}: commit: Raise the pass threshold and add a strict report
282bc8a feature/strict-eval@{4}: branch: Created from HEAD
$ git log --oneline -1 ORIG_HEAD
f7587ca Use ten folds
```
<!-- /snippet -->

Explain: (a) why the HEAD reflog has four lines for the rebase and the branch reflog has one; (b) what that says about where the branch ref pointed while the rebase was running; (c) two different expressions that name the tip of the branch before the rebase, and which of them is safe to use tomorrow; (d) why the old commits have not been deleted.

### 5.12 Debugging (4 points)

A developer rebases `feature/dedup` onto `main`. One commit conflicts in `pipeline/dedupe.py`. He runs `git checkout --ours pipeline/dedupe.py`, `git add pipeline/dedupe.py`, `git rebase --continue`. The rebase finishes without a message. Later a reviewer notices that the commit "Deduplicate by normalized URL" is not in the branch at all.

Explain what `--ours` selected, why the commit vanished without an error, how to get the branch back, and which two habits would have caught it.

### 5.13 Debugging (4 points)

With `rerere.enabled=true`, a long rebase on Git 2.55 stops at a conflicting commit with:

```text
fatal: Unable to create '.../.git/MERGE_RR.lock': File exists.
```

The engineer's next idea is to delete the lock file and run the rebase again from the start.

Explain which two processes want the lock, why this appears with recent Git versions, whether anything is damaged, how to continue, and the setting that prevents it.

### 5.14 Practical lab (10 points)

The task card is [`assessments/gen/final-rebase/TASK.md`](gen/final-rebase/TASK.md).

```bash
assessments/gen/final-rebase/generate.sh
assessments/gen/final-rebase/check.sh
```

### 5.15 Oral (4 points)

Rebase or merge: state the rule you apply to a branch that only you use, to a branch that others have fetched, and to bringing a pull request up to date. Give the reason behind each, in terms of what happens to commit IDs and to other people's clones.

---

## Section 6: Undo (43 points)

### 6.1 Multiple choice (1 point)

Which form of `git reset <commit>` moves the branch, makes the index match `<commit>`, and leaves every file in the working tree as it is?

- A. `--soft`
- B. `--mixed`, the default
- C. `--hard`
- D. `--keep`

### 6.2 Multiple choice (1 point)

A faulty commit has been on the shared `main` for a day and colleagues have built on it. Which undo is appropriate, and why?

- A. `git reset --hard <commit before it>` and `git push --force`, because it removes the commit completely.
- B. `git revert <commit>`, because it adds a new commit with the inverse change and leaves every published commit ID in place.
- C. `git commit --amend`, because it corrects the commit where it is.
- D. `git rebase -i` to drop the commit, because a linear history is cleaner.

### 6.3 Multiple choice (1 point)

Immediately after `git reset --hard`, which of these cannot be brought back with Git?

- A. A commit that the reset removed from the branch.
- B. A new file that had been staged with `git add` and never committed.
- C. An edit to a tracked file that had been saved in the editor and never staged.
- D. A stash entry created before the reset.

### 6.4 Multiple choice (1 point)

A feature branch was merged into `main`, and the merge was then reverted. The branch gets one more commit that fixes the problem, and is merged again. What arrives on `main`?

- A. Only the change of the new commit: the earlier commits are already ancestors of `main`, and the revert stays in effect.
- B. The whole feature, because the branch contains all of its commits.
- C. Nothing, because Git refuses to merge a branch whose merge was reverted.
- D. The whole feature twice, producing conflicts in every file.

### 6.5 Multiple choice (1 point)

What does `git clean -fdx` remove, and how is it undone?

- A. Untracked files only; undone with `git reflog`.
- B. Untracked files and directories, without ignored files; undone with `git stash pop`.
- C. Every change since the last commit; undone with `git reset ORIG_HEAD`.
- D. Untracked and ignored files and directories; Git never stored them, so there is no undo.

### 6.6 Command prediction (3 points)

<!-- snippet: final/s06/p1-setup -->
```text
$ git init -q throttle
$ cd throttle
$ printf 'per_minute: 60\n' > limits.yaml
$ printf 'burst: 10\n' > burst.yaml
$ printf '# throttle\n' > README.md
$ git add . && git commit -q -m "Add rate limits"
$ printf 'per_minute: 30\n' > limits.yaml
$ git commit -q -a -m "Tighten the limit"
$ printf 'burst: 20\n' > burst.yaml
$ git add burst.yaml
$ printf '# throttle\n\nSee limits.yaml.\n' > README.md
$ git reset -q HEAD~1
```
<!-- /snippet -->

Predict the output of the commands below, and the content of `limits.yaml` on disk.

```bash
git status --short
git log --oneline
git diff --cached --stat
```

### 6.7 Command prediction (3 points)

<!-- snippet: final/s06/p2-setup -->
```text
$ git init -q retries
$ cd retries
$ printf 'attempts: 1\n' > retry.yaml
$ git add . && git commit -q -m "Add retry settings"
$ printf 'attempts: 2\n' > retry.yaml
$ git add retry.yaml
$ printf 'attempts: 3\n' > retry.yaml
$ git restore retry.yaml
```
<!-- /snippet -->

(a) Predict the content of `retry.yaml` and the output of `git status --short`.

<!-- snippet: final/s06/p2-setup-b -->
```text
$ git restore --source=HEAD --staged --worktree retry.yaml
```
<!-- /snippet -->

(b) Predict both again. Which of the three values (1, 2, 3) can no longer be found anywhere, and which exists only as an object that nothing names?

### 6.8 Command prediction (3 points)

<!-- snippet: final/s06/p3-setup -->
```text
$ git init -q trainrun
$ cd trainrun
$ printf '*.ckpt\n' > .gitignore
$ printf 'print("train")\n' > train.py
$ git add . && git commit -q -m "Add the training script"
$ printf 'try a lower learning rate\n' > notes.txt
$ mkdir scratch
$ printf 'print("probe")\n' > scratch/probe.py
$ printf 'weights\n' > model.ckpt
```
<!-- /snippet -->

Predict what each of the four dry runs lists.

```bash
git clean -n
git clean -n -d
git clean -n -d -x
git clean -n -d -X
```

### 6.9 Diagram (3 points)

<!-- snippet: final/s06/g1-setup -->
```text
$ git init -q faqbot
$ cd faqbot
$ printf 'def answer(q):\n    return index.search(q)\n' > app.py
$ git add . && git commit -q -m "A: add the answer endpoint"
$ git switch -q -c feature/spellcheck
$ printf 'def correct(q):\n    return q.replace("teh", "the")\n' > spell.py
$ git add . && git commit -q -m "B: add spelling correction"
$ git switch -q main
$ git merge -q --no-ff -m "M1: merge feature/spellcheck" feature/spellcheck
$ git revert -m 1 --no-edit HEAD > /dev/null
$ git switch -q feature/spellcheck
$ printf 'teh the\nrecieve receive\n' > corrections.txt
$ git add . && git commit -q -m "C: read corrections from a file"
$ git switch -q main
$ git merge -q --no-ff -m "M2: merge feature/spellcheck again" feature/spellcheck
```
<!-- /snippet -->

Draw the final graph of `main` with the letters A, B, C, M1, M2 and R for the revert. Then say which of the files `app.py`, `spell.py` and `corrections.txt` exist on `main`, and which commit the second merge used as its merge base.

### 6.10 Output interpretation (4 points)

An edit was stashed, another edit to the same line was committed, and then:

<!-- snippet: final/s06/i1-transcript -->
```text
$ git stash pop
Auto-merging delivery.yaml
CONFLICT (content): Merge conflict in delivery.yaml
On branch main
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   delivery.yaml

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
$ git status --short
UU delivery.yaml
$ cat delivery.yaml
<<<<<<< Updated upstream
retries: 4
=======
retries: 5
>>>>>>> Stashed changes
timeout_s: 10
$ git stash list
stash@{0}: On main: try five retries
```
<!-- /snippet -->

Explain: (a) why applying a stash can conflict at all; (b) which side each of the two labels "Updated upstream" and "Stashed changes" stands for; (c) the meaning of the last line of the `pop` output and why Git behaves that way; (d) the commands to finish, for the case where you want the stashed value.

### 6.11 Debugging (4 points)

A developer wanted to keep `fixtures/large_sample.json` out of the commit he was preparing, so he "unstaged" it with `git rm --cached fixtures/large_sample.json`, committed and pushed. The next morning three colleagues report that the file disappeared from their working trees when they pulled, and a test fails.

Explain the state that the command produced and how `git status --short` displayed it, the root cause, the repair now that the commit is published, and the command he should have used.

### 6.12 Debugging (4 points)

Pull request #214 was squash-merged. It contained a feature and, as a side change, a new default for `max_batch`. The new default causes trouble in production. An engineer runs `git revert <the squash commit>`, pushes, and an hour later support reports that the whole feature is gone.

Explain why the revert removed more than intended, give two ways to end up with "feature present, old default" without rewriting `main`, and say what this implies for how pull requests are cut when the team squashes.

### 6.13 Practical lab (10 points)

The task card is [`assessments/gen/final-undo/TASK.md`](gen/final-undo/TASK.md).

```bash
assessments/gen/final-undo/generate.sh
assessments/gen/final-undo/check.sh
```

### 6.14 Oral (4 points)

"`git reset --hard` deleted my commits." Correct this sentence precisely: say what the command changes in each of the three places, what it leaves recoverable and for how long, and what it destroys for good.

---

## Section 7: Recovery (52 points)

### 7.1 Multiple choice (1 point)

Which statement about reflogs is correct?

- A. A reflog is part of the repository's history and is transferred by `git clone` and `git push`.
- B. A reflog is a local log of the values a ref has had in this repository; it is not transferred, and a bare repository keeps none by default.
- C. The reflog is stored on the server, which is why a force push can always be undone from any clone.
- D. There is one reflog per repository, shared by all branches and all worktrees.

### 7.2 Multiple choice (1 point)

With Git's defaults, how long is a commit protected after it was removed from its branch by a reset, if you do nothing?

- A. Two weeks.
- B. Until the next `git gc`.
- C. About 30 days through its reflog entries, and after that until a collection finds the object older than the two-week prune cut-off.
- D. 90 days, then it is deleted at midnight.

### 7.3 Multiple choice (1 point)

Which command does **not** write `ORIG_HEAD`?

- A. `git reset`
- B. `git merge`
- C. `git rebase`
- D. `git cherry-pick`

### 7.4 Multiple choice (1 point)

A repository has three stash entries. What keeps the two older ones alive?

- A. Only lines in the reflog of `refs/stash`; the ref itself points at the newest entry.
- B. They are parents of the newest stash commit.
- C. Each entry has its own ref: `refs/stash/0`, `refs/stash/1`, `refs/stash/2`.
- D. They are stored in the index.

### 7.5 Multiple choice (1 point)

A colleague force-pushed over `feature/ingest` on a plain bare Git server and four commits are no longer on the branch there. Where is the most reliable place to get them back?

- A. `git reflog` on the server, because servers log every push.
- B. Nowhere: a force push deletes the objects on every machine.
- C. `git fsck` in a fresh clone.
- D. Any clone that still has them: the local branch or reflogs of whoever pushed them, or the remote-tracking reflog of anyone who fetched them.

### 7.6 Command prediction (3 points)

<!-- snippet: final/s07/p1-setup -->
```text
$ git init -q ocrqueue
$ cd ocrqueue
$ git commit -q --allow-empty -m "Add the queue"
$ git switch -q -c spike/priority
$ git commit -q --allow-empty -m "Try a priority heap"
$ git switch -q main
$ git branch -q -D spike/priority
```
<!-- /snippet -->

Predict: does `git reflog show spike/priority` work? How many lines does `git reflog` print, and which of them names the commit "Try a priority heap"? What does `git branch --contains "HEAD@{1}"` print?

### 7.7 Command prediction (3 points)

<!-- snippet: final/s07/p2-setup -->
```text
$ git init -q ckptstore
$ cd ckptstore
$ printf 'lr: 0.1\n' > run.yaml
$ git add . && git commit -q -m "Add the baseline run"
$ printf 'lr: 0.01\n' > run.yaml
$ git commit -q -a -m "Experiment X"
$ x=$(git rev-parse HEAD)
$ git reset -q --hard HEAD~1
$ printf 'lr: 0.5\n' > run.yaml
$ git commit -q -a -m "Experiment Y"
$ y=$(git rev-parse HEAD)
$ git tag keep/y
$ git reset -q --hard HEAD~1
$ printf 'lr: 0.2\n' > run.yaml
$ git stash push -q -m "older idea"
$ z1=$(git rev-parse stash@{0})
$ printf 'lr: 0.3\n' > run.yaml
$ git stash push -q -m "newer idea"
$ z2=$(git rev-parse stash@{0})
$ git reflog expire --expire=now --all
$ git gc --quiet --prune=now
```
<!-- /snippet -->

For each of `$x`, `$y`, `$z1` and `$z2`, predict whether `git cat-file -t` still finds the object. Then predict the output of `git stash list`. Give the reason for each of the five answers.

### 7.8 Diagram (3 points)

<!-- snippet: final/s07/g1-reflog -->
```text
$ git reflog show main
9e3cc94 main@{0}: commit (amend): Seed the shuffle buffer from the run configuration
8f2a574 main@{1}: merge feature/shuffle: Fast-forward
ef0fc67 main@{2}: commit: Add the streaming loader
ce2a58a main@{3}: reset: moving to HEAD~2
6faaffb main@{4}: commit: Add batching
950a556 main@{5}: commit: Add the tokenizer
ce2a58a main@{6}: commit (initial): Add the loader
```
<!-- /snippet -->

Answer from the reflog, without a terminal.

1. Draw the graph of every commit this reflog mentions, with `main` at its present position.
2. Which reflog selector names the tip that the reset abandoned, and which commits did the reset remove from `main`?
3. Which selector names `main` as it was before the merge, and how many commits did the merge bring?
4. Is `main@{1}` an ancestor of `main`? What happened to that commit?

### 7.9 Output interpretation (4 points)

You pushed two commits to `feature/quotas` yesterday. This morning:

<!-- snippet: final/s07/i1-transcript -->
```text
$ git fetch
From ../server
 + 8787bba...7bc78d2 feature/quotas -> origin/feature/quotas  (forced update)
$ git status -sb
## feature/quotas...origin/feature/quotas [ahead 1, behind 1]
$ git reflog show origin/feature/quotas
7bc78d2 refs/remotes/origin/feature/quotas@{0}: fetch: forced-update
8787bba refs/remotes/origin/feature/quotas@{1}: update by push
$ git log --oneline --left-right 'origin/feature/quotas@{1}...origin/feature/quotas'
> 7bc78d2 Add a quota window
< 8787bba Count quotas per API key
```
<!-- /snippet -->

Explain: (a) what the `+` and "(forced update)" in the fetch output mean; (b) what the two lines of the remote-tracking reflog record, and which of them is your proof of what the server had before; (c) what the last command shows was removed and what replaced it; (d) what you do next, before any `git pull`, and which form of `git pull` would lose your commit without telling you.

### 7.10 Output interpretation (4 points)

A branch of two commits was rebased. Then:

<!-- snippet: final/s07/i2-transcript -->
```text
$ git fsck
$ git fsck --no-reflogs --unreachable
unreachable tree e452b56377e72d20c66290c956b749bf0f35979d
unreachable tree ea2fe566931eac6bd04de4903c3111371e6524a9
unreachable commit b90fb577f411445aa328f49ef8f854c94b9f0bff
unreachable commit fb16aceb9a9614ff1abbadcea07fb2e4943461f6
$ git fsck --no-reflogs --dangling
dangling commit b90fb577f411445aa328f49ef8f854c94b9f0bff
$ git fsck --no-reflogs --dangling | cut -d" " -f3 | xargs git log -1 --format=%s
Add two more examples
```
<!-- /snippet -->

Explain: (a) why plain `git fsck` prints nothing; (b) what `--no-reflogs` changes; (c) why four objects are unreachable and only one is dangling; (d) how you would use this output if the reflogs had been lost and you needed the old branch back.

### 7.11 Debugging (4 points)

A wiki page says: "To undo the last merge, run `git reset --hard HEAD~1`." An engineer merges `hotfix/cache-key` (three commits) into his local `release/3.2`, regrets it, and follows the wiki. `git log` now shows two of the three hotfix commits still on `release/3.2`.

Explain why the recipe failed here, what `HEAD~1` meant in this case, and give two correct ways to undo the merge, one of which still works tomorrow.

### 7.12 Debugging (4 points)

A developer worked for three days on a local branch `experiment/reranker-v3`, never pushed it, and yesterday deleted the whole project directory to "get a clean clone". He re-cloned and asks you to recover the branch with the reflog.

Say what can and cannot be recovered and exactly why, in terms of the four layers of protection. Name the places outside Git that are worth five minutes, and the habit that would have saved the work.

### 7.13 Practical lab (10 points)

The task card is [`assessments/gen/final-recovery/TASK.md`](gen/final-recovery/TASK.md).

```bash
assessments/gen/final-recovery/generate.sh
assessments/gen/final-recovery/check.sh
```

### 7.14 Incident response (8 points)

The team's deployments read from a bare mirror repository on a build server. On Friday someone force-pushed an older state of `release/4.1` to the mirror by mistake; four commits are missing from the branch there. On Monday, before anyone noticed, a scheduled housekeeping script on the mirror ran:

```bash
git reflog expire --expire=now --all
git gc --prune=now
```

A deployment is planned for this afternoon. Three engineers have clones; one of them was on holiday all last week.

Write the response in the seven stages. State what is certainly gone on the mirror and why, where the four commits are most likely to survive, how you would prove which commit was the tip, how you restore the branch, and what you change so that neither the force push nor the housekeeping can do this again.

### 7.15 Oral (4 points)

How does the reflog help you recover, and in which four situations does it not help at all?

---

## Section 8: Remote workflows (48 points)

### 8.1 Multiple choice (1 point)

What is `origin/main` in your clone?

- A. A live view of the branch `main` on the server.
- B. A ref in your own repository that records where the server's `main` was at your last fetch or push.
- C. A copy of your local `main` that Git keeps as a backup.
- D. The default branch of the remote, whatever it is called.

### 8.2 Multiple choice (1 point)

Your `main` and the server's `main` have each gained a commit. Nothing about pulling is configured. What does `git pull` do on Git 2.55?

- A. It fetches and creates a merge commit.
- B. It fetches and rebases your commit on top.
- C. It fetches, then stops with a fatal error that asks you to choose how to reconcile divergent branches.
- D. It overwrites your commit with the server's.

### 8.3 Multiple choice (1 point)

Why is the bare form `git push --force-with-lease` not a guarantee that you overwrite only what you have seen?

- A. It skips the check when the branch has an upstream.
- B. The lease compares the server's ref with your remote-tracking ref, and any fetch, including one your editor runs in the background, updates that ref without you looking at the new commits.
- C. It works only over SSH.
- D. The server ignores leases on protected branches.

### 8.4 Multiple choice (1 point)

You are on `hotfix/timeout`, commit a fix, and run `git push origin main`. Git prints "Everything up-to-date". What happened?

- A. The fix was pushed to `main`.
- B. The fix was pushed to `hotfix/timeout` on the server.
- C. The push was queued until `main` is checked out.
- D. Nothing was transferred: the command asked to send your local `main` to the server's `main`, and those were already equal.

### 8.5 Multiple choice (1 point)

What does a Git server check before it accepts an ordinary (non-forced) push to an existing branch?

- A. That the commit the server's branch points at now is an ancestor of the commit it is asked to move to.
- B. That the pusher's local branch has the same name as the server's.
- C. That the pushed commits are newer by date than the server's tip.
- D. That the pusher fetched within the last hour.

### 8.6 Command prediction (3 points)

<!-- snippet: final/s08/p1-setup -->
```text
# you/ and asha/ are clones of one server. You pushed "Add a response cache" to feature/cache.
# Then Asha pushed "Add cache metrics" on top of it. You have not fetched since your push.
$ seen=$(git rev-parse origin/feature/cache)
$ printf 'ttl: 120\n' > cache.yaml
$ git commit -q -a --amend --no-edit
# Your editor fetches in the background:
$ git fetch -q
```
<!-- /snippet -->

Predict the outcome of each of the two pushes below (accepted or rejected, and the reason Git prints in brackets), and say what the plain `git push --force-with-lease origin feature/cache` would have done at this point.

```bash
git push --force-with-lease=feature/cache:$seen origin feature/cache
git push --force-with-lease --force-if-includes origin feature/cache
```

### 8.7 Command prediction (3 points)

<!-- snippet: final/s08/p2-setup -->
```text
$ git init -q kiosk
$ git -C kiosk commit -q --allow-empty -m "Add the kiosk page"
$ git clone -q kiosk kiosk-dev
$ cd kiosk-dev
$ git commit -q --allow-empty -m "Add the idle screen"
```
<!-- /snippet -->

`kiosk` is an ordinary repository with a working tree, and `main` is checked out in it. Predict the result of each push, and say why Git treats them differently.

```bash
git push origin main
git push origin main:refs/heads/incoming
```

### 8.8 Diagram (3 points)

<!-- snippet: final/s08/g1-setup -->
```text
# server.git is the server; you/ and asha/ are clones. All three have main at "Add the service".
$ git -C you commit -q --allow-empty -m "Y1: add health check"
$ git -C you push -q
$ git -C asha fetch -q
$ git -C asha commit -q --allow-empty -m "A1: add request log"
$ git -C you commit -q --allow-empty -m "Y2: add readiness probe"
```
<!-- /snippet -->

Draw three boxes: `server.git`, `you`, `asha`. In each, write every branch and remote-tracking branch for `main` with the commit it points at (use "Add the service", Y1, Y2, A1). Then write what `git status -sb` prints in `you` and in `asha`.

### 8.9 Output interpretation (4 points)

<!-- snippet: final/s08/i1-transcript -->
```text
$ git push
To ../server.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git fetch
From ../server
   75f5dc1..0aaf9bf  main       -> origin/main
$ git push
To ../server.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

The same push is rejected twice with two different reasons. Explain: (a) what "(fetch first)" tells you about what your repository knows; (b) what changed between the two attempts; (c) what "(non-fast-forward)" tells you and why the server's answer is the same in substance; (d) two ways to continue, with the history each produces.

### 8.10 Output interpretation (4 points)

<!-- snippet: final/s08/i2-transcript -->
```text
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/feature/c
   24bd506..340671e  main       -> origin/main
 + c5732f8...213510d feature/a  -> origin/feature/a  (forced update)
 * [new branch]      feature/b  -> origin/feature/b
 * [new tag]         v2.0       -> v2.0
$ git branch -vv
  feature/a c5732f8 [origin/feature/a: ahead 1, behind 1] Work on feature/a
  feature/c b47b4b3 [origin/feature/c: gone] Work on feature/c
* main      24bd506 [origin/main: behind 1] Add the service
```
<!-- /snippet -->

Explain each of the five lines of the fetch output: what happened on the server and what the fetch changed in this clone. Then explain the three lines of `git branch -vv`, and say for `feature/a` and `feature/c` whether any local work is at risk and what you would check before acting.

### 8.11 Debugging (4 points)

After `git pull` on `main`, an engineer who changed nothing sees:

```text
modified:   vendor/textnorm (new commits)
```

`git diff` shows two commit IDs for `vendor/textnorm`. He is about to run `git add -A && git commit -m "sync"`.

Explain what the two IDs are, why the pull did not bring the directory up to date, what his commit would do to the team, the correct command, and the setting that makes the pull do it.

### 8.12 Debugging (4 points)

On `feature/batch-window`, `git push origin feature/batch-window` is rejected as non-fast-forward. The developer runs `git pull`, which answers "Already up to date." He pushes again: rejected again. `git branch -vv` shows `[origin/main: ahead 3]` for the branch.

Explain how the branch got that upstream, why pull and push disagree, how to integrate the server's commit without forcing, and how to create feature branches so that this cannot happen.

### 8.13 Debugging (4 points)

After `git fetch --prune`, `git branch -vv` shows `[origin/feature/tokenizer-cache: gone]` next to a local branch with five commits. The developer asks whether his work has been deleted and whether he may run the one-liner a colleague sent him, which deletes every local branch marked "gone" with `git branch -D`.

Say what "gone" means and does not mean, give the checks that decide whether the five commits are safe to delete, and name the case in which the one-liner destroys work.

### 8.14 Practical lab (10 points)

The task card is [`assessments/gen/final-remote/TASK.md`](gen/final-remote/TASK.md).

```bash
assessments/gen/final-remote/generate.sh
assessments/gen/final-remote/check.sh
```

### 8.15 Oral (4 points)

Why does `--force-with-lease` exist, where is its hole, and what exactly do you require of a team that is allowed to rewrite its own feature branches?

---

## Section 9: GitHub (34 points)

> **GitHub, not Git.** The items of sections 9 to 12 are answered from the documented behavior of the platform. No GitHub output is shown and none is needed.

### 9.1 Multiple choice (1 point)

A new engineer is added to an organization and to one team that has Write on one repository. She finds that she can clone every private repository of the organization. Which setting explains it?

- A. The organization's base permission, which gives every member that access on every repository; team grants only add to it.
- B. Her team's Write role, which GitHub extends to all repositories of the same owner.
- C. Her SSH key, which was registered for the whole organization.
- D. Private repositories are readable by all members of an organization and this cannot be changed.

### 9.2 Multiple choice (1 point)

A contributor pushed a commit with a credential to their fork of your public repository and then deleted the fork. What is true?

- A. Deleting a fork deletes its commits from GitHub immediately.
- B. The commit may remain accessible by its ID through other repositories of the fork network, because the network shares Git data.
- C. The commit moves to the upstream repository's default branch.
- D. The commit is kept for 90 days in the contributor's reflog on GitHub.

### 9.3 Multiple choice (1 point)

A release `v0.9.0` is created in the GitHub web interface for a tag name that does not exist yet. Later `git describe` on the build machine reports the previous version. Why?

- A. Releases are not Git data, so no tag was created.
- B. `git describe` reads GitHub Releases through the API and the build machine has no token.
- C. The tag was created in the wiki repository.
- D. GitHub created a lightweight tag at the tip of the target branch, and `git describe` considers only annotated tags unless `--tags` is given.

### 9.4 Multiple choice (1 point)

`git clone` of a private repository that certainly exists ends with "Repository not found". Which reading is correct?

- A. The repository was deleted or renamed in the last minutes.
- B. The URL is wrong; the server compares names case-sensitively.
- C. The server authenticated the request as an identity that cannot see the repository, and answers as if it did not exist so as not to confirm that it does.
- D. The clone needs `--depth 1` for private repositories.

### 9.5 Multiple choice (1 point)

You push over SSH with your work key, and on GitHub the new commits are shown under your private account. What decides which account a commit is attributed to?

- A. The SSH key that authenticated the push.
- B. The token stored in the credential helper.
- C. The account that owns the repository.
- D. The author email recorded in each commit, which GitHub matches against the email addresses of accounts.

### 9.6 Multiple choice (1 point)

A pull request whose description says "Fixes #88" is merged into `release/2.3`. The issue stays open. Why?

- A. Closing keywords in a pull request description are interpreted only when the pull request targets the default branch.
- B. The keyword must be `Closes`, not `Fixes`.
- C. Issues can only be closed by commits that are signed.
- D. The issue closes when the release is published.

### 9.7 Debugging (4 points)

On a Mac, `git push` over HTTPS to a company repository fails with HTTP 403 every time. Git never prompts for a username or token. `gh auth status` shows the engineer logged in with the company account, and `gh repo view` works.

Give the mechanism that keeps the failure permanent, two read-only commands that show which program supplies the credential, the fix, and the arrangement that prevents it on a machine with two GitHub accounts.

### 9.8 Debugging (4 points)

A nightly job on an engineer's own workstation runs `git fetch` over SSH from `cron` and fails with "Permission denied (publickey)". The same command typed in the terminal works.

Explain the difference between the two environments, the command that proves it, why "run it with sudo" or "copy my private key into the job" are the wrong fixes, and what identity the job should have.

### 9.9 Debugging (4 points)

A compliance script counts open pull requests per repository with `gh api repos/OWNER/REPO/pulls --jq 'length'`. For the three busiest repositories it reports exactly 30, every day.

Give the cause, the corrected call, and a second way a `gh api` call in a script can silently do something other than what the author meant when fields are added to it.

### 9.10 Incident response (8 points)

A contractor's engagement ended on Friday and his account was removed from the organization. On Tuesday the security team notices that a nightly mirror job still pushes to two repositories, and that a clone with write access was made from an unknown address on Monday.

Write the response in the seven stages. Cover: which kinds of credential survive the removal of a person, how you find them, what you revoke first, what you assume about the two repositories, and what replaces person-bound credentials for machines.

### 9.11 Oral (4 points)

Three different things are called "identity" when you work with GitHub: who the connection is authenticated as, what that account is authorized to do, and whose name is on the commit. Explain each, where it is decided, and give one failure that belongs to each.

### 9.12 Oral (4 points)

Your company moves a repository to another hosting platform with `git clone --mirror` and `git push --mirror`. List what arrives and what does not, and say which of the missing things you would export first and why.

---

## Section 10: Pull requests (42 points)

### 10.1 Multiple choice (1 point)

Which comparison does the "Files changed" tab of a pull request show?

- A. The merge base of the two branches against the tip of the head branch (three dots).
- B. The tip of the base branch against the tip of the head branch (two dots).
- C. The first commit of the head branch against its last commit.
- D. The head branch against the default branch, whatever the base is.

### 10.2 Multiple choice (1 point)

What does opening a pull request change in Git terms?

- A. It moves the base branch to a test merge commit.
- B. It creates a branch named after the pull request in the head repository.
- C. It moves no branch; GitHub writes a read-only ref for the head commit into the base repository and, when the merge is clean, a test merge commit.
- D. Nothing: a pull request has no Git data at all.

### 10.3 Multiple choice (1 point)

A reviewer submits "Request changes" on a pull request in a repository that has no ruleset and no branch protection. The author presses the merge button. What happens?

- A. The merge is blocked until the reviewer approves.
- B. The merge is blocked for 24 hours.
- C. The merge goes through: a review blocks only when a rule requires reviews.
- D. The merge goes through, and the review is deleted.

### 10.4 Multiple choice (1 point)

A ruleset has "Dismiss stale pull request approvals when new commits are pushed" switched on. Which event can dismiss an approval although nobody pushed to the head branch?

- A. A comment by the author.
- B. Nothing: only a push to the head branch changes the diff.
- C. A re-run of the CI workflow.
- D. A change of the diff caused by the base branch, for example when a related pull request is merged into it.

### 10.5 Multiple choice (1 point)

A pull request with five signed commits is merged with "Rebase and merge". What lands on the base branch?

- A. The five original commits, with their IDs and signatures.
- B. One commit signed by GitHub.
- C. Five new commits with new IDs and updated committer information, without signature verification.
- D. A merge commit signed by the person who pressed the button.

### 10.6 Command prediction (3 points)

<!-- snippet: final/s10/p1-setup -->
```text
$ git init -q invoicer
$ cd invoicer
$ printf 'standard: 19\nreduced: 7\n' > rates.yaml
$ printf '# invoicer\n' > README.md
$ git add . && git commit -q -m "Add tax rates"
$ git switch -q -c feature/vat-id
$ printf 'pattern: "[A-Z]{2}[0-9]{9}"\n' > vat_id.yaml
$ git add . && git commit -q -m "Validate VAT IDs"
$ git switch -q main
$ printf 'retention_days: 3650\n' > audit.yaml
$ printf '# invoicer\n\nCreates invoices.\n' > README.md
$ git add . && git commit -q -m "Add audit retention"
```
<!-- /snippet -->

Predict which files each of the two commands lists, and say which of the two a pull request from `feature/vat-id` into `main` shows and why the other one would mislead a reviewer.

```bash
git diff --stat main..feature/vat-id
git diff --stat main...feature/vat-id
```

### 10.7 Diagram (3 points)

<!-- snippet: final/s10/g1-setup -->
```text
$ git init -q geocoder
$ cd geocoder
$ git commit -q --allow-empty -m "A: add the geocoder"
$ git switch -q -c feature/cache
$ git commit -q --allow-empty -m "X: add a result cache"
$ git commit -q --allow-empty -m "Y: expire cache entries"
$ git switch -q main
$ git commit -q --allow-empty -m "N: add rate limiting"
# Three copies of main, one per merge method:
$ git branch main-merge && git branch main-squash && git branch main-rebase
```
<!-- /snippet -->

`feature/cache` is merged into each copy with the plain Git equivalent of one merge button: a merge commit into `main-merge`, a squash into `main-squash`, a rebase-style copy of the commits onto `main-rebase`. Draw the three resulting histories. For each, say whether `git branch --merged <that main>` lists `feature/cache`.

### 10.8 Diagram (3 points)

`feature/paging` was squash-merged into `main` as "Add paging (#31)". The branch was not deleted, and one more commit was made on it:

<!-- snippet: final/s10/g2-graph -->
```text
$ git log --graph --oneline --all --decorate
* b02adf2 (feature/paging) Escalate after fifteen minutes
* a9fab03 Add the on-call rota
* de00c20 Add the pager channel
| * 6591eca (HEAD -> main) Add paging (#31)
| * 4068c4f Add quiet hours
|/  
* f7c3781 Add alert channels
```
<!-- /snippet -->

Answer from the graph.

1. What is the merge base of `main` and `feature/paging`?
2. Which commits will a new pull request from `feature/paging` into `main` list?
3. Write the one command that makes the branch contain only the new work on top of `main`, and draw the graph afterwards.

### 10.9 Output interpretation (4 points)

<!-- snippet: final/s10/i1-transcript -->
```text
$ git merge --squash feature/paging
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -q -m "Add paging (#31)"
$ git branch -d feature/paging
error: the branch 'feature/paging' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/paging'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git log --oneline main..feature/paging
a9fab03 Add the on-call rota
de00c20 Add the pager channel
$ git cherry -v main feature/paging
+ de00c208e21ddf6ac04e833401bde83a306d30e0 Add the pager channel
+ a9fab03c6ab69f4736d762dd51378273edd1c979 Add the on-call rota
$ git diff --stat main...feature/paging
 alerts.yaml | 2 +-
 rota.yaml   | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git merge-tree --write-tree main feature/paging
250e6042f48962b7d98fbe5e3843097685de38b0
$ git rev-parse 'main^{tree}'
250e6042f48962b7d98fbe5e3843097685de38b0
```
<!-- /snippet -->

Explain: (a) why `git branch -d` refuses although the work is on `main`; (b) what `git log main..feature/paging` and `git cherry -v` each test, and why both still report the two commits; (c) what the equality of the last two IDs proves; (d) whether `git branch -D feature/paging` is safe here, and what else you would check in a real repository first.

### 10.10 Debugging (4 points)

Two pull requests were each green. Both were merged within ten minutes. `main` is red. The repository requires the check `ci`, and "Require branches to be up to date before merging" is not selected.

Explain which commit each pull request's check had tested, why both could be green, and the two platform mechanisms that close the gap, with the cost of each.

### 10.11 Debugging (4 points)

A pull request that changes only `docs/` shows "ci — Expected — Waiting for status to be reported" and cannot be merged. The workflow that produces the check begins:

```yaml
on:
  pull_request:
    paths:
      - "src/**"
      - "tests/**"
```

Explain why the check never reports, why a job skipped with `if:` would have behaved differently, and how to restructure so that documentation changes can merge while code changes are still tested.

### 10.12 Debugging (4 points)

A pull request has two approvals and all checks green, and the merge button is disabled. Give four distinct reasons that fit the rules described in this course, and for each the place where you would see it.

### 10.13 Incident response (8 points)

A reviewer approved a pull request at 14:02. At 14:05 the author pushed one more commit, "small cleanup", and merged at 14:06. The cleanup commit disabled an input check. It was found in production two days later. The repository required one approval and had neither of the two settings that react to a changed diff.

Write the response: what you establish from Git and from GitHub, how the faulty change is removed from `main` (the pull request was squash-merged), how you check for other pull requests with the same pattern, and which setting you choose, with its cost.

### 10.14 Oral (4 points)

"I pushed one commit and the pull request shows forty." Give the three most likely causes in terms of the base, the merge base and the head, and the command that tells them apart.

---

## Section 11: GitHub Actions (42 points)

### 11.1 Multiple choice (1 point)

A workflow runs on `pull_request` and uses the checkout action with its defaults. Which commit is in the working tree of the job?

- A. The tip of the pull request's head branch.
- B. The tip of the base branch.
- C. A test merge of the head into the current base (`refs/pull/N/merge`), checked out as a detached HEAD.
- D. The commit the reviewer approved.

### 11.2 Multiple choice (1 point)

With its default settings, how much history does the checkout action fetch?

- A. One commit and no tags.
- B. The full history of the checked-out branch, without tags.
- C. The full history of all branches and all tags.
- D. The last 50 commits.

### 11.3 Multiple choice (1 point)

A job named `test` is a required check. In which case is the pull request blocked?

- A. The workflow started and the job was skipped by its `if:` condition.
- B. The workflow never started for this commit because of a `paths` filter.
- C. The job ran and passed on the second attempt.
- D. The job ran and passed, and another, optional job failed.

### 11.4 Multiple choice (1 point)

A matrix contains `python-version: [3.9, 3.10, 3.11]` without quotes. Which versions does the job try to set up?

- A. 3.9, 3.10 and 3.11.
- B. 3.9, 3.1 and 3.11, because YAML reads 3.10 as the number 3.1.
- C. Only 3.11, because the last entry wins.
- D. None: unquoted versions are a syntax error.

### 11.5 Multiple choice (1 point)

A step on a Linux runner has no `shell:` key and contains `pytest | tee report.txt`. `pytest` fails. What is the step's result?

- A. Success, because the default command line is `bash -e` without `pipefail`, and the pipeline's status is that of `tee`.
- B. Failure, because every command in a step is checked.
- C. Failure, because `tee` propagates the status of its input.
- D. Neutral, because pipelines are not supported in `run`.

### 11.6 Multiple choice (1 point)

A workflow on `pull_request` uses `${{ secrets.EVAL_API_KEY }}`. What does the job see when the pull request comes from a fork?

- A. The secret, masked in the log.
- B. An error that stops the job before the first step.
- C. The fork owner's secret of the same name.
- D. An empty string.

### 11.7 Output interpretation (4 points)

A release job computes its version with `git describe`. The transcript shows the same repository on a laptop, and then what a job has after a checkout that fetches one commit:

<!-- snippet: final/s11/i1-transcript -->
```text
# On the laptop:
$ git -C tariffs describe
v1.4.0-2-g3d0cd95
# What the job has: one commit, fetched the way a default checkout step fetches it.
$ git clone -q --depth 1 --no-tags "file://$PWD/tariffs" job
$ cd job
$ git rev-parse --is-shallow-repository
true
$ git rev-list --count HEAD
1
$ git tag --list
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --always
3d0cd95
```
<!-- /snippet -->

Explain: (a) the two facts about the job's repository that make `git describe` fail; (b) why `--always` "fixes" the error and why it must not be used for a version; (c) the one setting of the checkout step that repairs the job; (d) how the release job should behave when no exact tag is found.

### 11.8 Debugging (4 points)

A dependency was upgraded in the lock file two weeks ago. CI still installs the old version, and a test that needs the new one fails only in CI. The cache step is:

```yaml
- uses: actions/cache@<full commit ID>
  with:
    path: .venv
    key: venv-${{ runner.os }}
    restore-keys: |
      venv-
```

Explain why the cache never changes, what a restore key does, and give the corrected key together with the install command habit that makes a stale cache harmless.

### 11.9 Debugging (4 points)

Since a "speed-up" change, CI runs on one pull request are cancelled whenever somebody pushes to another pull request. The workflow now contains:

```yaml
concurrency:
  group: ci
  cancel-in-progress: true
```

Explain the mechanism, give the corrected group for CI, and say why the deploy workflow needs the opposite setting.

### 11.10 Debugging (4 points)

A deploy step is supposed to run only on `main`. It ran on a feature branch. The step is:

```yaml
- name: Deploy
  if: github.ref == 'refs/heads/main' && ${{ inputs.deploy }}
  run: ./scripts/deploy.sh
```

Explain why the condition is always true, how to write it, and where the run itself tells you about this mistake.

### 11.11 Debugging (4 points)

A job that declares `environment: production` deployed immediately. The team was sure that production deployments wait for an approval. The repository is private and was created last week.

Give two hypotheses that fit, the command that separates them, the root cause in each case, and the practice that prevents the surprise.

### 11.12 Incident response (8 points)

Monday 09:30: every pull request in a repository fails in the `build` job. Nothing was merged since Friday evening, when the same job was green on `main`. The failing step installs dependencies. The workflow uses `runs-on: ubuntu-latest`, one third-party action referenced as `@v3`, and `pip install -r requirements.txt` without a lock file.

Write the response. Start with how you test the claim "nothing changed", walk the investigation order far enough to separate at least four causes that fit, state what you do to unblock the team today, and what you change so that the next "sudden" failure is attributable in minutes.

### 11.13 Oral (4 points)

A developer says: "CI tests my branch." Correct this for a `pull_request` workflow, name the two Git facts that make laptop and runner differ on "the same commit", and say how you reproduce the runner's tree locally.

### 11.14 Oral (4 points)

"It passes locally and fails in GitHub Actions." Give the order in which you investigate, from "did the right thing start" to "what did it say", and one typical finding for each of the first six steps.

---

## Section 12: Security (49 points)

> All credentials in this section are obvious dummies. Every item is about detection, containment and prevention.

### 12.1 Multiple choice (1 point)

A workflow step is:

```yaml
- run: echo "Title: ${{ github.event.pull_request.title }}"
```

Why is this a vulnerability, and what is the fix?

- A. The title may be long; truncate it.
- B. Pull request titles are private data; remove the step.
- C. `echo` prints secrets; use `printf`.
- D. The expression is substituted into the script text before the shell starts, so a crafted title runs as commands; pass the value through `env:` and use `"$TITLE"`.

### 12.2 Multiple choice (1 point)

Which reference to a third-party action guarantees that the code you reviewed is the code that runs?

- A. `@v4`, a major version tag.
- B. `@v4.2.1`, an exact release tag.
- C. `@main`.
- D. The full commit ID.

### 12.3 Multiple choice (1 point)

When does a `pull_request_target` workflow become dangerous?

- A. When it checks out the pull request's head and then executes that code, because the job has the base repository's token and secrets.
- B. Always: the event cannot be used safely.
- C. Only when the repository is private.
- D. When it posts a comment on the pull request.

### 12.4 Multiple choice (1 point)

A job gets `permissions: { contents: read }` added. A later step that labels the pull request now fails with "Resource not accessible by integration". Why?

- A. Naming one scope sets every scope that is not named to `none`.
- B. `contents: read` disables the token entirely.
- C. Labels need a personal access token.
- D. The `permissions` key is only valid at workflow level.

### 12.5 Multiple choice (1 point)

A cloud access key was pushed to a public repository ten minutes ago. What is the first action?

- A. Delete the file and push.
- B. Rewrite history and force-push.
- C. Make the repository private.
- D. Revoke or rotate the key at its issuer.

### 12.6 Multiple choice (1 point)

What does a "Verified" badge on a commit establish?

- A. That the code in the commit was reviewed.
- B. That the holder of a key registered with an account created exactly this commit object.
- C. That the commit is free of malware.
- D. That the author field cannot have been forged, even for unsigned commits.

### 12.7 Command prediction (3 points)

<!-- snippet: final/s12/p1-setup -->
```text
$ git init -q mailer
$ cd mailer
$ printf 'def send(to, body):\n    return smtp.send(to, body)\n' > send.py
$ git add . && git commit -q -m "Add the mail sender"
$ printf 'SMTP_PASSWORD=dummy-not-a-real-password-0000\n' > .env
$ git add . && git commit -q -m "Add local settings"
$ printf 'def retry(fn, n=3):\n    return fn()\n' > retry.py
$ git add . && git commit -q -m "Add a retry helper"
$ git rm -q .env
$ git commit -q -m "Remove local settings"
```
<!-- /snippet -->

Predict the result of each command: what it prints, or that it prints nothing, and the exit status of the first. For the third it is enough to say how many commits are named and which.

```bash
git grep -l dummy-not-a-real-password
git log --oneline -S'dummy-not-a-real-password'
git rev-list HEAD | xargs git grep -l dummy-not-a-real-password
```

### 12.8 Output interpretation (4 points)

Ravi pushed a branch whose one commit contained a hard-coded webhook secret (a dummy). Asha cloned. Ravi then amended the commit and force-pushed.

<!-- snippet: final/s12/i1-transcript -->
```text
# Ravi: "I amended the commit and force-pushed. 6d12921 is gone."
$ git -C server.git for-each-ref --format="%(objectname:short) %(refname)"
f365b56 refs/heads/feature/signing
dcd8674 refs/heads/main
$ git -C server.git cat-file -t 6d12921
commit
$ git -C server.git grep -c dummy-not-a-real-secret 6d12921
6d12921:verify.py:1
$ git -C ravi reflog show feature/signing
f365b56 feature/signing@{0}: commit (amend): Verify webhook signatures
6d12921 feature/signing@{1}: commit: Verify webhook signatures
dcd8674 feature/signing@{2}: branch: Created from HEAD
$ git -C asha branch -r --contains 6d12921
  origin/feature/signing
```
<!-- /snippet -->

Explain what each of the five commands proves about where the secret still is. Then state what has to happen first, what Git alone cannot clean up, and what would be different on GitHub compared with this bare repository.

### 12.9 Debugging (4 points)

A build container mounts the repository from the host. Every Git command in the container fails with "fatal: detected dubious ownership in repository at '/workspace'". A teammate proposes `git config --global --add safe.directory '*'` in the image.

Explain what Git is protecting against, why the wildcard is the wrong fix, the narrow fix, and the way to build the image so that the question does not arise.

### 12.10 Debugging (4 points)

A commit on `main` carries Asha's name and email as author. Asha was on a flight when it was made and says she did not write it. The commit has no signature.

Explain why this is possible without any account being compromised, how you find out who pushed it, why the incident is on the pushing account and not on Asha's, and the two controls, one per person and one per repository, that make such a commit stand out or impossible.

### 12.11 Debugging (4 points)

`git push` is blocked by push protection for a secret in `config/dev.yaml`. The developer deletes the line, commits "remove key", and pushes again. Blocked again, for the same secret.

Explain why, give the command that lists what the push would send, the repair when nothing of this has been published, and what must happen to the key even though the push never succeeded.

### 12.12 Incident response (8 points)

At 10:40 a scanner alert arrives: a commit pushed at 10:02 to a public repository contains `LLM_API_KEY=dummy-not-a-real-key-3333` in `scripts/eval.sh`. The repository has eleven forks and one open pull request from the branch.

Write the response in the six steps for a leaked secret, in order, with the reason for the order. State the five facts an assessment must produce and which of them only the key's issuer can supply, which copies survive a history rewrite and who can remove each, and when you would decide not to rewrite at all.

### 12.13 Incident response (8 points)

A third-party action that twelve of your workflows reference as `@v2` is reported compromised: the tag was moved to a commit that prints the environment of the job. Your workflows ran with it for about six hours. Several of those jobs receive deploy credentials.

Write the response: how you establish which runs used the bad commit, what you treat as exposed, the order of containment, and the three controls that reduce the next such event to a non-event.

### 12.14 Oral (4 points)

How do you secure GitHub Actions? Give six controls, and for each the specific attack or accident it stops.

### 12.15 Oral (4 points)

A team lead wants to enforce "no secrets, no large files, conventional messages" with Git hooks. Explain why client-side hooks cannot enforce policy, what they are good for, and where enforcement has to live.

---

## Section 13: Open source (36 points)

### 13.1 Multiple choice (1 point)

What is a fork, from Git's point of view?

- A. A special kind of branch that Git creates on the server.
- B. A submodule of the upstream repository.
- C. A clone that Git keeps synchronized with its parent.
- D. Nothing special: one more repository with a URL. The link to its parent and the shared object store are GitHub's.

### 13.2 Multiple choice (1 point)

The "Sync fork" action cannot fast-forward the `main` of your fork. What is the usual cause?

- A. Forks can be synchronized only by the upstream's maintainers.
- B. The upstream rewrote its history.
- C. The fork is older than 90 days.
- D. Your fork's `main` has commits of its own, so it has diverged from the upstream's `main`.

### 13.3 Multiple choice (1 point)

Your pull request was squash-merged upstream. `git branch --merged upstream/main` does not list your branch. Which test tells you whether your work is contained in `upstream/main`?

- A. `git merge-base --is-ancestor <branch> upstream/main`
- B. A comparison of content: an empty `git diff upstream/main <branch>`, or a test merge whose tree equals the tree of `upstream/main`.
- C. `git branch -d <branch>`, which fails only when work would be lost.
- D. `git log upstream/main..<branch>`, which is empty when the work is merged.

### 13.4 Multiple choice (1 point)

Every pull request from a fork fails in a job that calls a paid evaluation API with a repository secret. What is the right design?

- A. Switch the workflow to `pull_request_target` and check out the pull request's head, so that the secret is available.
- B. Ask contributors to add the secret to their forks.
- C. Print the secret into the log so that contributors can debug.
- D. Keep `pull_request` runs free of secrets, and run the evaluation in a separate, maintainer-triggered step after review.

### 13.5 Command prediction (3 points)

<!-- snippet: final/s13/p1-setup -->
```text
# origin is your fork, upstream is the project. Your branch fix/unicode-escapes has one commit
# and is pushed to the fork; a pull request is open. The project then gained "Add the lexer".
$ git fetch -q upstream
$ git rebase -q upstream/main
```
<!-- /snippet -->

Predict the output of `git status -sb`, the result of a plain `git push`, and the result of `git push --force-with-lease`. Say why the forced push is acceptable on this branch and what it does to the open pull request.

### 13.6 Diagram (3 points)

A pull request branch with two commits is one commit behind the project:

<!-- snippet: final/s13/g1-before -->
```text
$ git log --graph --oneline --decorate feature/comments upstream/main
* 7b8acf3 (upstream/main, upstream/HEAD) U1: add the lexer
| * e11140c (HEAD -> feature/comments, origin/feature/comments, by-rebase, by-merge) P2: parse block comments
| * 55f9b9a P1: parse line comments
|/  
* ba65dfd (origin/main, origin/HEAD, main) Add the parser
```
<!-- /snippet -->

Two copies of the branch are brought up to date in two ways:

<!-- snippet: final/s13/g1-setup -->
```text
$ git switch -q by-merge && git merge -q -m "Merge upstream/main into the branch" upstream/main
$ git switch -q by-rebase && git rebase -q upstream/main
```
<!-- /snippet -->

Draw both results. For each, say whether it can be pushed to the fork without force and which commits `upstream/main..<branch>` lists. Name one reason a maintainer might prefer each.

### 13.7 Debugging (4 points)

A first-time contributor opens a pull request with "one small fix". It lists 37 commits, most of them authored by maintainers months ago, and the file view shows changes in 60 files. The contributor's own commit touches one file.

Give two states of the contributor's fork and branch that produce this picture, the commands (run in the contributor's clone) that separate them, and the instructions you send, written so that a newcomer can follow them without losing the fix.

### 13.8 Debugging (4 points)

A library maintains `release/2.x` and `main`. A security fix was committed on `release/2.x` and released as 2.7.3. Six weeks later 3.0.0 is released from `main` and contains the vulnerability again.

State the root cause in terms of what Git does and does not do between branches, the read-only command that lists fixes on the release branch that `main` lacks, the repair, and the two conventions for the direction a fix travels, with the failure each is exposed to.

### 13.9 Practical lab (10 points)

The task card is [`assessments/gen/final-fork/TASK.md`](gen/final-fork/TASK.md).

```bash
assessments/gen/final-fork/generate.sh
assessments/gen/final-fork/check.sh
```

### 13.10 Oral (4 points)

You want to fix a bug in an open-source project to which you have no write access. Take me from reading the repository to a merged pull request: the repositories and remotes involved, the branch you work on, how you keep it current, and what you never do.

### 13.11 Oral (4 points)

You maintain a public project. Strangers send pull requests, and your CI needs a cloud credential for its integration tests. Describe how you run CI for those pull requests without handing your credential to code you have not read.

---

## Section 14: AI/ML workflows (40 points)

### 14.1 Multiple choice (1 point)

Which set belongs in Git for a model-training project?

- A. Code, configuration, prompts, lock files, and small pointer files that name data and weights by checksum.
- B. Code, the training data set and every checkpoint, so that one commit reproduces a run.
- C. Code and notebooks with their outputs, so that reviewers can see the plots.
- D. Code only; configuration belongs in the experiment tracker.

### 14.2 Multiple choice (1 point)

A repository tracks `*.safetensors` with Git LFS. A colleague clones on a machine without the LFS client and opens a model file of about 130 bytes. What is it?

- A. A corrupted download.
- B. The pointer file that Git stores in place of the content: a small text file with the object's hash and size.
- C. A symbolic link to the LFS server.
- D. A delta against the previous version of the model.

### 14.3 Multiple choice (1 point)

A notebook that nobody edited shows as modified after it was opened and run. Why?

- A. The file stores code, outputs and execution counts together, and running it changes the outputs and counters.
- B. Jupyter rewrites the file's line endings.
- C. Git cannot track JSON files reliably.
- D. The notebook's modification time changed, and Git compares times.

### 14.4 Multiple choice (1 point)

An experiment record says only `commit: 42d9714`. Why can checking out that commit fail to reproduce the metric?

- A. Commit IDs are not stable across machines.
- B. The run may have used uncommitted changes, another data version or another environment; a commit ID identifies a snapshot that was taken, not what was on disk or installed when the run started.
- C. Git garbage collection changes old commits.
- D. Checkout does not restore file modes.

### 14.5 Multiple choice (1 point)

The team uses the pre-commit framework to strip notebook outputs and block large files. Why must the same checks also run in CI as required checks?

- A. Hooks run too slowly on laptops.
- B. Required checks are needed before hooks are allowed to run.
- C. CI is the only place where Python is available.
- D. Hooks are installed per clone, are not copied by `git clone`, and can be skipped with `--no-verify` or by any client that does not run them.

### 14.6 Command prediction (3 points)

<!-- snippet: final/s14/p1-setup -->
```text
$ git init -q churn-analysis
$ cd churn-analysis
# A toy notebook format: lines that start with IN: are code, lines that start with OUT: are outputs.
$ git config set filter.dropout.clean "sed '/^OUT:/d'"
$ printf '*.nb filter=dropout\n' > .gitattributes
$ printf 'IN: df.describe()\nOUT: count 100\nIN: plot(df)\nOUT: <figure 1>\n' > analysis.nb
$ git add . && git commit -q -m "Add the churn analysis"
# The notebook is run again. Only the outputs change.
$ printf 'IN: df.describe()\nOUT: count 250\nIN: plot(df)\nOUT: <figure 7>\n' > analysis.nb
$ git clone -q . ../churn-clone
```
<!-- /snippet -->

Predict: (a) the content of `analysis.nb` in the last commit, and the output of `git status --short` in the original repository after the re-run; (b) the content of `analysis.nb` in the clone, and whether the clone has the filter program configured; (c) what a colleague stages in the clone after running the notebook there.

### 14.7 Output interpretation (4 points)

An evaluation result is questioned. The run record and the state of the repository at the time were captured:

<!-- snippet: final/s14/i1-transcript -->
```text
$ cat runs/run-0042.json
{"commit": "42d9714", "eval_f1": 0.871}
$ git rev-parse --short HEAD
42d9714
$ git status --short
 M train.py
$ git describe --dirty
v0.3.0-dirty
$ git diff
diff --git a/train.py b/train.py
index 058673c..c6cd427 100644
--- a/train.py
+++ b/train.py
@@ -1,4 +1,4 @@
-LR = 1e-4
+LR = 3e-4
 EPOCHS = 3
 
 def train(data):
```
<!-- /snippet -->

Explain: (a) what the record claims and why it is not enough; (b) what `git describe --dirty` adds; (c) which code produced the metric, and whether the result can be reproduced; (d) what a training script should do at start-up so that this cannot happen again.

### 14.8 Debugging (4 points)

`git push` to GitHub is rejected because `checkpoints/epoch-3.bin` exceeds the file size limit. The developer has already run `git rm checkpoints/epoch-3.bin`, committed, and pushed again: rejected again, for the same file.

Explain why, give the read-only command that shows which unpushed commit contains the file, the repair for commits that were never published, and what the project should set up so that large files cannot be committed by accident.

### 14.9 Debugging (4 points)

The nightly evaluation reports a drop of four points. No commit was made between the last good run and the first bad one: the same commit ID, the same lock file, the same container digest.

Name the one input that the commit does not pin by itself, how a pointer file with a checksum would have shown the change, the control in the evaluation script, and what you tell the product team about the two numbers.

### 14.10 Debugging (4 points)

One engineer's script that walks the repository with `find . -name '*.py'` reports 40 files; everyone else gets 2,300. Her clone was made with a company bootstrap script. `git status` prints a line that begins "You are in a sparse checkout".

Explain the state, why `find` and Git disagree, three Git commands that answer "which files does the repository have" without changing the checkout, and the rule for scripts that follows.

### 14.11 Incident response (8 points)

A data scientist pushed a notebook to a public repository. An output cell shows the environment of the process, including `OPENAI_API_KEY=dummy-not-a-real-key-4444`. The team "uses nbstripout". The push was 25 minutes ago; the notebook is also in an open pull request.

Write the response. Cover the first action, how the output reached history although a filter exists, what you do about the notebook in history, and the controls that make the filter something the team can rely on.

### 14.12 Oral (4 points)

Design the Git side of reproducible training runs: what the run records at start-up, what it refuses, how data and model versions are tied to the commit, and what you tag.

### 14.13 Oral (4 points)

AI coding agents now open pull requests in your repositories. Which properties of an agent as a contributor matter for Git and GitHub, and which controls do you rely on?

---

## Section 15: Production incidents (61 points)

### 15.1 Multiple choice (1 point)

In the seven-stage incident loop, what distinguishes stages 2 and 3 (preserve, diagnose) from stage 4 (recover)?

- A. Stages 2 and 3 are done by the incident commander, stage 4 by the author of the bad commit.
- B. Stages 2 and 3 use only commands that add refs or read state; stage 4 is the first moment anything is moved or overwritten.
- C. Stages 2 and 3 happen on the server, stage 4 in clones.
- D. Stages 2 and 3 are optional when the cause is known.

### 15.2 Multiple choice (1 point)

A rewritten production branch was caught by the release job before anything was deployed from it. How is its severity assigned?

- A. By what could have happened in the window as well as by what did; and the level is raised the moment a secret is involved.
- B. The lowest level, because nothing reached production.
- C. By the seniority of the person who caused it.
- D. By the number of commits affected.

### 15.3 Multiple choice (1 point)

Which of these does **not** belong in the incident summary for a CTO?

- A. What happened, with impact first and times with a time zone.
- B. The root cause in one sentence, with the layer named.
- C. The list of Git commands that were run and the name of the person who made the mistake.
- D. What was done and how it was verified, and the control that prevents a repeat.

### 15.4 Output interpretation (4 points)

<!-- snippet: final/s15/i1-transcript -->
```text
# Yesterday you removed a leaked key from history and force-pushed main. This morning:
$ git fetch
From ../server
   bbc6c48..482496f  main       -> origin/main
$ git log --graph --format="%h %an: %s" origin/main
*   482496f Ravi Menon: Merge branch 'main' of ../server
|\  
| * bbc6c48 Lab User: Normalize the vectors
| * 1390a85 Lab User: Batch the requests
* | 9e6d78b Ravi Menon: Add a cache key
* | fc3cd67 Lab User: Normalize the vectors
* | 32cabe9 Lab User: Batch the requests
* | 6c16674 Lab User: Add local environment
|/  
* a359981 Lab User: Add the embedding client
$ git log --oneline origin/main -- .env
6c16674 Add local environment
$ git reflog show origin/main
482496f refs/remotes/origin/main@{0}: fetch: fast-forward
bbc6c48 refs/remotes/origin/main@{1}: update by push
fc3cd67 refs/remotes/origin/main@{2}: update by push
```
<!-- /snippet -->

Explain: (a) what the graph shows happened to `main` overnight, and how you can tell from the parents of the top commit; (b) why the server accepted it without a forced push; (c) what the last two commands prove; (d) the recovery, including what has to happen in the clone that caused it, and the instruction that would have prevented it.

### 15.5 Debugging (4 points)

A hotfix was deployed from `main` on Friday. On Monday the bug is back in the build from `main`, and `git log main` does not show the hotfix commit.

Give three hypotheses that fit, and for each the one read-only command whose output would confirm it. State which evidence exists only in clones and which only on the hosting platform.

### 15.6 Debugging (4 points)

A deployment fails to parse `deploy/values.yaml`. The file on `main` contains the lines `<<<<<<< HEAD`, `=======` and `>>>>>>> origin/main`. The last commit that touched the file is a merge commit made by a developer who "resolved a small conflict".

Explain how markers get into a commit, which command shows what the person changed relative to a mechanical merge, the lowest-risk repair on a published branch, and two controls that catch committed markers.

### 15.7 Practical lab (10 points)

The briefing is [`assessments/gen/final-incident/SYMPTOMS.md`](gen/final-incident/SYMPTOMS.md).

```bash
assessments/gen/final-incident/generate.sh
assessments/gen/final-incident/check.sh
```

### 15.8 Incident response (8 points)

At 11:20 an organization owner, cleaning up a local clone, runs `git push --force origin main` from a `main` that is two weeks old. The repository's `main` is protected by a classic branch protection rule that requires pull requests; "Do not allow bypassing the above settings" is not selected. Twenty-three commits are no longer on `main`. Nine engineers have clones. A deployment at 11:00 used the newest commit.

Write the response in the seven stages, with the exact evidence you collect before anything is restored, the restoring command with its lease, the verification against the 11:00 deployment, the message to the nine engineers, and the rule change.

### 15.9 Incident response (8 points)

A shared branch `feature/ranking-v2` has an open pull request and two authors. One of them rebased it onto `main` and force-pushed. The other, who had unpushed commits, ran `git pull`, got a merge, and pushed. The pull request now lists every commit twice and reviewers have stopped reviewing.

Write the recovery as the eleven steps of the senior standard: say what you do in each step for this situation, which steps change nothing, and what the final history of the branch looks like.

### 15.10 Incident response (8 points)

The annotated tag `v3.2.0` was published on Tuesday. On Thursday a maintainer moved it to a newer commit with `git tag -f` and `git push --force origin v3.2.0`, "to include a late fix". Customers who installed on Wednesday and on Friday report different behavior for the same version. CI caches and some clones have the old tag.

Write the response: how you establish both commits and who has which, what the tag is restored to and why, how the late fix is released, why plain `git fetch` did not warn anybody, and the server-side rule.

### 15.11 Incident response (8 points)

You rebased `feature/audit-log` and pushed it with `--force`. An hour later a teammate writes: "I ran `git pull --rebase` as always. It said it succeeded. My commit from this morning is gone, and I had pushed it."

Write the response: what you tell her to do and not to do in the first minute, where her commit is, the mechanism that removed it, the repair without another rewrite, and the two changes, one in habit and one in configuration, that you make yourself.

### 15.12 Oral (4 points)

Give me, in under a minute and without a single command, the incident summary for item 15.8 as you would say it to a CTO. Then tell me what you deliberately left out and why.

---

## Section 16: Debugging (47 points)

### 16.1 Multiple choice (1 point)

In `git bisect run <script>`, what does exit status 125 from the script mean?

- A. The commit is good.
- B. The commit is bad.
- C. The commit cannot be tested and is to be skipped.
- D. Abort the bisection.

### 16.2 Multiple choice (1 point)

A function call was moved from one line to another inside the same file in one commit, unchanged. Which search finds that commit?

- A. `git log -S'call()'`, because `-S` finds every commit whose diff contains the string.
- B. `git log -G'call\(\)'`, because `-G` matches added and removed lines, while `-S` reports only commits that change the number of occurrences.
- C. Neither can find it.
- D. Both find it, and `-S` is faster.

### 16.3 Multiple choice (1 point)

What is the difference between `git log main..topic` and `git log main...topic`?

- A. None; the dots are interchangeable in `git log`.
- B. Two dots: commits reachable from `topic` and not from `main`. Three dots: commits reachable from either and not from both.
- C. Two dots compares the tips; three dots compares with the merge base.
- D. Three dots includes merge commits; two dots does not.

### 16.4 Multiple choice (1 point)

What does `git blame` tell you about a line?

- A. The commit that last changed that line as it stands, which can be a reformatting or a move; finding the origin of the logic takes further steps.
- B. Who introduced the bug that the line contains.
- C. Every commit that ever touched the line.
- D. The author of the pull request that contained the line.

### 16.5 Command prediction (3 points)

<!-- snippet: final/s16/p1-setup -->
```text
$ git init -q ratecard
$ cd ratecard
# Asha:
$ printf 'def price(tokens):\n  base = tokens * 0.002\n  return round(base, 4)\n' > price.py
$ git add . && git commit -q -m "Add the price function"
# Ravi runs the formatter (two spaces become four):
$ printf 'def price(tokens):\n    base = tokens * 0.002\n    return round(base, 4)\n' > price.py
$ git commit -q -a -m "Format with four spaces"
```
<!-- /snippet -->

Predict which commit each of the two commands names for lines 2 and 3 (answer with the author), and say what you would add to the repository so that everybody's blame skips the formatting commit.

```bash
git blame -s -L 2,3 price.py
git blame -s -w -L 2,3 price.py
```

### 16.6 Command prediction (3 points)

<!-- snippet: final/s16/p2-setup -->
```text
$ git init -q textnorm
$ cd textnorm
# Asha:
$ printf 'def squash_spaces(s):\n    parts = s.split()\n    joined = " ".join(parts)\n    return joined.strip()\n\ndef lower(s):\n    return s.lower()\n' > clean.py
$ git add . && git commit -q -m "Add text cleaning"
# Ravi moves one function into a new file, unchanged, in one commit:
$ printf 'def squash_spaces(s):\n    parts = s.split()\n    joined = " ".join(parts)\n    return joined.strip()\n' > spaces.py
$ printf 'def lower(s):\n    return s.lower()\n' > clean.py
$ git add . && git commit -q -m "Move squash_spaces into its own module"
```
<!-- /snippet -->

Predict which commit and which file each command names for the four lines of `spaces.py` (answer with the author), and explain the difference.

```bash
git blame -s spaces.py
git blame -s -C spaces.py
```

### 16.7 Diagram (3 points)

<!-- snippet: final/s16/g1-graph -->
```text
$ git log --oneline --decorate
4bebbaa (HEAD -> main) C8: add the dashboard link
9c722d5 C7: add the reset endpoint
8fda2fd C6: add labels
a94939a C5: switch to a ring buffer
127f599 C4: add the exporter
bcf966f C3: add the window
58d92b3 C2: add percentile math
7dfd876 (tag: v1.0) C1: add the tracker
# The check "grep -q list tracker.yaml" passes at v1.0 and fails at HEAD.
```
<!-- /snippet -->

The first bad commit is C5, which you do not know yet. You run `git bisect start HEAD v1.0` and then `git bisect run grep -q list tracker.yaml`. On a drawing of the eight commits, mark the commits that bisect tests, in order, with the verdict for each, and state how many commits were tested out of how many candidates.

### 16.8 Output interpretation (4 points)

On a release branch, two commits were to be copied from `main`:

<!-- snippet: final/s16/i1-transcript -->
```text
$ git cherry-pick main~1 main 2>&1 | grep -v "^hint:"
Auto-merging fence.yaml
CONFLICT (content): Merge conflict in fence.yaml
error: could not apply 77cf7e6... Widen the fence
$ git status
On branch release/1.0
You are currently cherry-picking commit 77cf7e6.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   fence.yaml

no changes added to commit (use "git add" and/or "git commit -a")
$ ls .git | grep -E "^(CHERRY_PICK_HEAD|REVERT_HEAD|MERGE_HEAD|ORIG_HEAD|sequencer|rebase-merge)$"
CHERRY_PICK_HEAD
sequencer
$ cat .git/sequencer/todo
pick 77cf7e6 Widen the fence
pick a3e1ed0 Support polygons
$ git log --oneline -1 CHERRY_PICK_HEAD
77cf7e6 Widen the fence
```
<!-- /snippet -->

Explain: (a) which operation is in progress and how far it got; (b) what each of the two entries found in `.git` means; (c) what the `todo` file tells you about what `--continue` will do after the conflict is resolved; (d) the four ways out of this state and what each leaves behind.

### 16.9 Output interpretation (4 points)

<!-- snippet: final/s16/i2-transcript -->
```text
# In Asha's clone, after "git pull" on feature/vector-tiles:
$ git log --graph --format="%h %s" feature/vector-tiles
*   bc462a6 Merge branch 'feature/vector-tiles' of ../server into feature/vector-tiles
|\  
| * dc80d0d Limit the zoom level
| * fad1ac0 Serve vector tiles
| * 3b0bfad Add a health endpoint
* | cee40f7 Compress the tiles
* | 6d6b3e9 Limit the zoom level
* | 694ce07 Serve vector tiles
|/  
* 6c8c275 Add the tile server
$ git log --format="%m %h %s" --cherry-mark --left-right "HEAD^1...HEAD^2"
= dc80d0d Limit the zoom level
= fad1ac0 Serve vector tiles
> 3b0bfad Add a health endpoint
< cee40f7 Compress the tiles
= 6d6b3e9 Limit the zoom level
= 694ce07 Serve vector tiles
$ git reflog show origin/feature/vector-tiles
dc80d0d refs/remotes/origin/feature/vector-tiles@{0}: pull -q --no-rebase --no-edit: forced-update
```
<!-- /snippet -->

Explain: (a) what the graph shows and why two pairs of commits have the same subjects; (b) what `=`, `<` and `>` in the second output mean and which commits are real new work; (c) what the reflog line proves about the cause; (d) what Asha should have done instead of a plain pull, and what a clean branch would contain.

### 16.10 Debugging (4 points)

For an incident timeline you run, at 12:51, `git log --since=2026-09-10 --until=2026-09-11 --oneline`. The output omits four commits that were made on the morning of 10 September and includes one from the morning of the 11th.

Explain how Git read the two dates, give the corrected command, and state the rule for dates in scripts and incident notes.

### 16.11 Debugging (4 points)

In one repository every Git command, including `git status` and `git config list`, fails with:

```text
fatal: bad config line 19 in file .git/config
```

Other repositories on the machine work. The engineer plans to delete `.git` and clone again; the repository has unpushed branches.

Explain why one bad line stops every command, what is and is not damaged, the repair, and the habit that prevents it.

### 16.12 Debugging (4 points)

A ticket contains one line of evidence: "fatal: Could not read from remote repository. Please make sure you have the correct access rights and the repository exists." The reporter concludes that their access was revoked.

Explain what this message does and does not tell you, where the cause is to be found, the next command when nothing else was printed, and what you ask people to put into tickets.

### 16.13 Practical lab (10 points)

The task card is [`assessments/gen/final-debugging/TASK.md`](gen/final-debugging/TASK.md).

```bash
assessments/gen/final-debugging/generate.sh
assessments/gen/final-debugging/check.sh
```

### 16.14 Oral (4 points)

Name the ten commands of your diagnosis ritual and what question each answers. Then tell me which kinds of command you do not allow yourself before the root cause is named, and why.

---

## Section 17: Architecture (40 points)

### 17.1 Multiple choice (1 point)

Which two questions come before all others when you choose a branching model?

- A. How many versions are live at once, and how often do you release?
- B. Which model do the largest technology companies use, and which has the best diagram?
- C. How many engineers know Git Flow, and how many branches can the CI system build?
- D. Do you prefer merge commits or a linear history, and do you sign commits?

### 17.2 Multiple choice (1 point)

An organization ruleset requires one approval on default branches. A repository ruleset on `main` requires three approvals and signed commits. A classic rule on `main` requires linear history. What must a merge into `main` satisfy?

- A. Only the organization ruleset, because it has the highest priority.
- B. Only the repository ruleset, because the most specific rule wins.
- C. Everything: the rules are aggregated, and where one rule is defined in several ways the most restrictive version applies: three approvals, signed commits and linear history.
- D. Whichever ruleset was created last.

### 17.3 Multiple choice (1 point)

Under a ruleset with an empty bypass list, who can push directly to the protected branch?

- A. Repository administrators.
- B. Organization owners.
- C. Members with the Maintain role.
- D. Nobody.

### 17.4 Multiple choice (1 point)

A `CODEOWNERS` file contains, in this order, the lines `/services/billing/ @org/billing` and `* @org/platform`. No ruleset requires code owner review. A pull request changes `services/billing/api.py`. What happens?

- A. `@org/billing` is requested, and its approval is required.
- B. Nobody is requested, because the patterns conflict.
- C. Both teams are requested and both must approve.
- D. `@org/platform` is requested, because the last matching pattern wins; and the request is advisory, because no rule requires code owner review.

### 17.5 Multiple choice (1 point)

Developers of a very large monorepo need full history for `blame` and `bisect`, and each works in a few directories. Which clone do you standardize on for laptops?

- A. `--depth 1`, because it is the fastest.
- B. A full clone, because anything else breaks Git.
- C. A blobless partial clone with a cone-mode sparse checkout.
- D. One clone per directory, made with `--single-branch`.

### 17.6 Diagram (3 points)

A team ships a hosted product from `main` and supports the last on-premises release. They follow the convention "fix on `main` first, cherry-pick down". Release 1.4.0 was cut from `main` last month; `main` has moved on; a bug is found that affects both lines.

Draw `main`, the release branch and the tags after the bug has been fixed and 1.4.1 has been released. Show the direction in which the fix travelled, mark which commits have equal content and different IDs, and write the option that makes the copy say where it came from. Then draw the same situation in one line of text for the other convention, "merge upward".

### 17.7 Debugging (4 points)

After a governance clean-up, no pull request in a repository can be merged: the merge box offers no method. The repository settings allow only squash merging. A new organization ruleset for default branches contains a pull request rule whose allowed merge methods are "merge" only.

Explain the mechanism, why relaxing the repository's own ruleset would not help, the two possible repairs, and how such changes should be made so that the two settings cannot drift apart again.

### 17.8 Debugging (4 points)

`CODEOWNERS` assigns `/models/ @acme/ml-research`. Pull requests that change files under `models/` request nobody, although a ruleset requires code owner review, and those pull requests cannot be merged.

Give three causes that fit, the one API call that reports errors in the file, and the fix for each cause. Then say which branch's copy of the file GitHub uses for a pull request, and why that matters when you fix it.

### 17.9 Incident response (8 points)

An internal audit finds that in the last quarter an engineer with the Admin role merged his own pull request into the production branch of a payments service without review, twice, "to fix an outage quickly". The branch is protected by a classic rule. No customer impact is known. The auditor asks for a design that makes this impossible to do silently and still allows an emergency fix at 03:00.

Write the response: what you establish about the two merges, the target design (rule kinds, bypass mode, review settings, who owns the workflow files), how an emergency change works under it and what trace it leaves, and how you verify the design after it is switched on.

### 17.10 Oral (4 points)

A company of forty engineers runs a hosted API that deploys several times a day, sells an on-premises edition with two supported versions, and is audited once a year. Propose the branching model, the release and tag policy, the protection of the important branches, and the merge method, and name the two risks you would watch.

### 17.11 Oral (4 points)

Your ML platform group is split across fourteen repositories and wants to move into one. Give the three strongest arguments for it, the three strongest against, the Git features that make a large repository workable, and the one thing Git cannot give you in a monorepo.

### 17.12 Oral (4 points)

Three teams use the same tokenizer library. Should it be consumed as a submodule, a subtree or a package? Give your decision rule, and for the option you reject most firmly, the failure you have seen it produce.

### 17.13 Oral (4 points)

State your policy for release tags: what kind of tag, who creates it and from what, what the version number promises, and why a published tag must never move. Then say what enforces it.

---

## Section 18: CTO interview (56 points)

Fourteen questions, 4 points each, asked one at a time by an examiner who interrupts with one follow-up per question. Two to three minutes per answer. No notes and no terminal. The examiner marks correctness, mechanism, terminology and production judgment, one point each.

### 18.1 Oral (4 points)

A junior engineer tells you: "Git stores diffs, so a long history makes everything slow." Correct both halves of the sentence in terms a board member could follow, and say what does make a repository slow.

### 18.2 Oral (4 points)

You amended a commit that you had already pushed to a shared branch. Describe, object by object and ref by ref, the state of your clone, the server and a colleague's clone. Then give me three ways out, ranked by risk.

### 18.3 Oral (4 points)

Explain `A..B` and `A...B` for `git log` and for `git diff`. Then tell me which of the four a pull request uses for its commit list and which for its file view, and what misunderstanding that causes in reviews.

### 18.4 Oral (4 points)

A developer comes to your desk: "My branch is gone." You have five minutes and their laptop. What do you ask, what do you run, in which order, and at which point do you stop and say it cannot be recovered?

### 18.5 Oral (4 points)

Write the force-push policy for an organization of sixty engineers: where it is forbidden, where it is allowed, in which form, and what enforces each part.

### 18.6 Oral (4 points)

Why does a cherry-pick create a new commit, and what does that mean later for merges between the two branches, for `git branch --contains`, and for anyone asking "is the fix in the release"?

### 18.7 Oral (4 points)

Explain a three-way merge to an engineer who has never used Git. Then give me one case in which Git reports a conflict that a person would not, and one in which Git reports none and the result is wrong.

### 18.8 Oral (4 points)

We are considering "require signed commits" on `main`. What do we gain, what do we not gain, and what will stop working on the day we switch it on?

### 18.9 Oral (4 points)

A CI job spends most of its twenty-five minutes cloning a repository of nine gigabytes. Give me the options from cheapest to most invasive, and for each the kind of job that it breaks.

### 18.10 Oral (4 points)

A credential was committed three weeks ago, in a private repository with forty collaborators, and was found today. Take me through your first thirty minutes, and tell me what you would not spend time on.

### 18.11 Oral (4 points)

What is garbage collection in Git, what triggers it, and which commands would you forbid on a shared server or in an incident, and why?

### 18.12 Oral (4 points)

Where does Git stop and GitHub begin in protecting `main`? Give me one protection that only Git on the client can offer, one that only the server can offer, and one common belief about each that is false.

### 18.13 Oral (4 points)

Git 3.0 is planned. Which changes of defaults would you prepare our tooling for, how can a team try them today, and which widely repeated claim about removals is false?

### 18.14 Oral (4 points)

I give you a repository that you have never seen. In ten minutes, tell me whether its history and its governance can be trusted. What do you look at, in which order, and what would make you say "no"?

---

## Scoring sheet

Enter the points per section. A section is passed at 70% of its points.

| Section | Items | Points | 70% | Scored |
|---|---|---|---|---|
| 1 Fundamentals | 14 | 35 | 25 | |
| 2 Git internals | 16 | 42 | 30 | |
| 3 Branching | 14 | 43 | 31 | |
| 4 Merge | 15 | 47 | 33 | |
| 5 Rebase | 15 | 47 | 33 | |
| 6 Undo | 14 | 43 | 31 | |
| 7 Recovery | 15 | 52 | 37 | |
| 8 Remote workflows | 15 | 48 | 34 | |
| 9 GitHub | 12 | 34 | 24 | |
| 10 Pull requests | 14 | 42 | 30 | |
| 11 GitHub Actions | 14 | 42 | 30 | |
| 12 Security | 15 | 49 | 35 | |
| 13 Open source | 11 | 36 | 26 | |
| 14 AI/ML workflows | 13 | 40 | 28 | |
| 15 Production incidents | 12 | 61 | 43 | |
| 16 Debugging | 14 | 47 | 33 | |
| 17 Architecture | 13 | 40 | 28 | |
| 18 CTO interview | 14 | 56 | 40 | |
| **Total** | **250** | **804** | **684 (85%)** | |

Items per type and section:

| Section | Multiple choice | Prediction | Diagram | Interpretation | Debugging | Lab | Incident | Oral |
|---|---|---|---|---|---|---|---|---|
| 1 | 6 | 2 | 1 | 1 | 2 | 0 | 0 | 2 |
| 2 | 6 | 3 | 1 | 2 | 2 | 0 | 0 | 2 |
| 3 | 5 | 2 | 2 | 1 | 2 | 1 | 0 | 1 |
| 4 | 5 | 2 | 2 | 2 | 2 | 1 | 0 | 1 |
| 5 | 5 | 2 | 2 | 2 | 2 | 1 | 0 | 1 |
| 6 | 5 | 3 | 1 | 1 | 2 | 1 | 0 | 1 |
| 7 | 5 | 2 | 1 | 2 | 2 | 1 | 1 | 1 |
| 8 | 5 | 2 | 1 | 2 | 3 | 1 | 0 | 1 |
| 9 | 6 | 0 | 0 | 0 | 3 | 0 | 1 | 2 |
| 10 | 5 | 1 | 2 | 1 | 3 | 0 | 1 | 1 |
| 11 | 6 | 0 | 0 | 1 | 4 | 0 | 1 | 2 |
| 12 | 6 | 1 | 0 | 1 | 3 | 0 | 2 | 2 |
| 13 | 4 | 1 | 1 | 0 | 2 | 1 | 0 | 2 |
| 14 | 5 | 1 | 0 | 1 | 3 | 0 | 1 | 2 |
| 15 | 3 | 0 | 0 | 1 | 2 | 1 | 4 | 1 |
| 16 | 4 | 2 | 1 | 2 | 3 | 1 | 0 | 1 |
| 17 | 5 | 0 | 1 | 0 | 2 | 0 | 1 | 4 |
| 18 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 14 |
| **Total** | **86** | **24** | **16** | **20** | **42** | **9** | **12** | **41** |

The practical labs, their generators and checks:

| Item | Lab | Project | Generator and check under `assessments/gen/` |
|---|---|---|---|
| 3.13 | branching | `driftwatch` | `final-branching/` |
| 4.14 | merge | `answerbank` | `final-merge/` |
| 5.14 | rebase | `citecheck` | `final-rebase/` |
| 6.13 | undo | `routeplan` | `final-undo/` |
| 7.13 | recovery | `chunkstore` | `final-recovery/` |
| 8.14 | remote | `intentmap` | `final-remote/` |
| 13.9 | fork | `spanlog` | `final-fork/` |
| 15.7 | incident | `tokenbudget` | `final-incident/` |
| 16.13 | debugging | `latencylab` | `final-debugging/` |

Each lab sandbox is built at `$GIT_MASTERY_LABS/final/<lab>` (`~/git-mastery-labs/final/<lab>` by default). A generator runs with the fixed lab clock, so the commit IDs in your sandbox equal the IDs in the answer key until you make a commit of your own.

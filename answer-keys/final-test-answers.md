# The final knowledge test: answer key

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every transcript in this file is real output of the scripts in `labs/final/`. For the examiner. A learner opens this file only after the whole test in `assessments/final-test.md` has been handed in.

## How to mark

| Item type | Points | Marking |
|---|---|---|
| Multiple choice | 1 | The letter is right or wrong. The key says which documented wrong model each distractor comes from: use it for the restudy, not for partial credit |
| Command prediction | 3 | 2 points for the output (1 if the idea is right and a detail is wrong: a status letter, a count, an exit status), 1 for the mechanism sentence |
| Diagram | 3 | 2 points for commits, parent links and refs in the right places, 1 for HEAD and for the questions asked beside the drawing |
| Output interpretation | 4 | 1 point per lettered part; where an item has no letters, the key lists the four things to look for |
| Debugging | 4 | 1 hypotheses and the separating read-only command, 1 root cause with its layer, 1 lowest-risk fix, 1 prevention. A state-changing command before the cause is established halves the item |
| Practical lab | 10 | 6 for `PASS` from `check.sh`, 4 for the hand-in on the task card. No `PASS`, no points for the end state, whatever the transcript looks like |
| Incident response | 8 | 1 stabilise and preserve, 2 diagnosis from evidence, 2 recovery that destroys least, 1 verification, 2 for the four-part summary and a control that is a control |
| Oral | 4 | 1 correct, 1 mechanism named, 1 exact terminology, 1 production judgment. An answer that recites a command without the state it changes earns at most 1 |

Every entry ends with the textbook reference to restudy. "Chapter 8, section 8.7" is `textbook/ch08-merge.md`, section 8.7. Object IDs in this file are the IDs the scripts produce with the lab clock; a learner who ran a generator sees the same IDs in the lab until the first commit of their own.

Surprising real behaviors that this key relies on, all visible in the transcripts below: `git branch -m feature feature/retry` succeeds where `git branch feature/retry` fails (item 3.7); a three-argument `git range-diff` shows conflict markers that were committed during a rebase (5.10); `git stash list` is empty after reflog expiry while `refs/stash` still holds the newest entry (7.7); `@{push}` cannot be resolved for a branch without an upstream even when `remote.pushDefault` decides where the push goes (lab "remote"); `git branch -f main upstream/main` also sets the upstream (lab "fork").

---

## Section 1: Fundamentals

### 1.1

**Answer: C.** A commit names one top-level tree, its parents, an author, a committer and a message. A diff is computed on demand from two trees. A is the "a commit stores a diff" model; B confuses the commit with its blobs (file content lives in blob objects that trees name); D invents a link between a commit and a branch, which Git does not store.

*Reference:* Chapter 2, sections 2.3, 2.5 and 2.11.

### 1.2

**Answer: B.** `git add` wrote a blob and put its ID into the index; `git commit` turns the index into a tree. The second edit exists only in the working tree. A is the "commit records what is on disk" model that the worked example of Chapter 1 takes apart; D is a safety check Git does not have.

*Reference:* Chapter 1, section 1.12; Chapter 5, sections 5.2 and 5.3.

### 1.3

**Answer: A.** Ignore rules are consulted only for paths that have no index entry. A tracked path is compared with its index entry and no pattern is checked. The fix is `git rm --cached settings.env` and a commit; if the file holds a credential, the credential is leaked and must be rotated. B and D are the "adding it to `.gitignore` stops tracking it" model; C confuses ignoring with history rewriting.

*Reference:* Chapter 4, sections 4.5 and 4.6.

### 1.4

**Answer: C.** `.git/HEAD` contains either `ref: refs/heads/<branch>` or a commit ID (detached HEAD). A is the most common wrong model in the polls the textbook cites; B fails as soon as another branch is checked out; D mixes HEAD with a remote-tracking branch.

*Reference:* Chapter 2, sections 2.8 and 2.11; Chapter 7, section 7.3.

### 1.5

**Answer: D.** A tag is a ref and, when annotated, a tag object: Git data, transferred by clone. Review comments, rulesets and issues are records in GitHub's database and are in no clone.

*Reference:* Chapter 1, section 1.5; Chapter 2, section 2.12; Chapter 15, section 15.2.

### 1.6

**Answer: C.** Trees store names and blob IDs. The blob is unchanged, so no new blob is written (B is wrong); neither the commit object nor the index has a rename record (A and D are wrong). `git status`, `git diff -M` and `git log --follow` infer the rename by comparing trees.

*Reference:* Chapter 4, sections 4.8 and 4.9; Chapter 14A, section 14A.4.

### 1.7

<!-- snippet: final/s01/p1-answer -->
```text
$ git status --short
A  .gitignore
M  service.log
$ git status --short --ignored
A  .gitignore
M  service.log
!! worker.log
$ git check-ignore -v service.log worker.log
.gitignore:1:*.log	worker.log
[exit status: 0]
```
<!-- /snippet -->

`service.log` was tracked before the rule existed, so `git add .` stages its modification and `check-ignore` does not report it; `worker.log` is untracked, so the pattern applies and `git add .` skips it. `settings.env` is tracked and unmodified, so it appears nowhere. The exit status is 0 because at least one path is ignored.

Award 2 for the three outputs (1 if `M  service.log` is missing or `worker.log` is shown as `??`), 1 for "tracked first, ignored second: tracking wins".

*Reference:* Chapter 4, sections 4.3, 4.5 and 4.6.

### 1.8

<!-- snippet: final/s01/p2-answer -->
```text
$ git show --name-status --format=%s HEAD
Change the seed and the split

D	old_split.py
M	seeds.yaml
$ git status --short
?? new_split.py
```
<!-- /snippet -->

`git commit -a` stages modifications and deletions of tracked paths and nothing else. The deletion of `old_split.py` is committed; `new_split.py` was never tracked and stays untracked. The colleague gets a project in which `split` no longer exists: the old module is gone and the new one is in no commit.

Award 2 for the output, 1 for the consequence. A prediction that lists `A new_split.py` shows the "commit -a commits everything" model.

*Reference:* Chapter 5, sections 5.8 and 5.10.

### 1.9

<!-- snippet: final/s01/g1-answer -->
```text
$ git show HEAD:cache.yaml
ttl: 120
$ git show :cache.yaml
ttl: 120
$ cat cache.yaml
ttl: 900
$ git status --short
 M cache.yaml
$ git log --oneline
df44cee Raise the TTL
b29f1da Add cache settings
```
<!-- /snippet -->

```text
   HEAD                 index                working tree
 +-----------+        +-----------+        +-----------+
 | ttl: 120  |        | ttl: 120  |        | ttl: 900  |
 +-----------+        +-----------+        +-----------+
```

60 and 120 are in commits. 600 was staged, so a blob exists for it, and `git restore --staged` then replaced the index entry with the one from HEAD: the blob for 600 is now named by no commit and no index entry (a dangling blob that `git fsck --lost-found` would list). 300 and 900 were never staged: 300 was overwritten in the working tree and is gone, 900 exists only as the file.

Award 2 for the three boxes and the status line, 1 for the fate of 300, 600 and 900.

*Reference:* Chapter 2, section 2.9; Chapter 5, sections 5.3 and 5.9; Chapter 13, section 13.9.

### 1.10

(a) Without `--follow`, a path limit selects commits that change that exact path, and only the rename commit touches `fingerprint.py`. `--follow` asks Git to detect, at the commit where the path appears, whether it was renamed from another path, and to continue with the old name. (b) Both trees list the same blob ID, once under each name: the rename is two snapshots with the same content under different names, and nothing else. (c) With rename detection off, a tree comparison shows one path gone and one path new. With detection on (the default for `git status`, `git diff` and `git log --stat`), a deleted and an added path are paired when their similarity reaches the threshold, 50% by default; here it is 100%. (d) When the file was renamed and rewritten below the threshold in one commit, or when more than one path is given: `--follow` works for a single file.

*Reference:* Chapter 4, section 4.9; Chapter 14A, sections 14A.4 and 14A.10.

### 1.11

Hypotheses: (1) the file is untracked or ignored and the incoming commits add a tracked file at that path; (2) the file is tracked and an index flag hides its modification from commands that list changes. Separating command: `git ls-files -v config/local.yaml`. A lower-case letter (`h`) is the assume-unchanged bit, `S` is skip-worktree; no output means untracked.

Root cause (Git): the bit was set to hide a local edit. It is a promise to Git that there is no edit. Commands that list changes skip the entry; a command that must replace the file checks the real file, finds the edit and stops.

Fix: `git update-index --no-assume-unchanged config/local.yaml` (or `--no-skip-worktree`), then deal with the edit in the open: commit it, stash it, or copy it aside and restore the file. Then pull.

Prevention: private settings belong in a separate file that is ignored and that no commit tracks. Find leftover bits with `git ls-files -v | grep '^[a-zS]'`.

*Reference:* Chapter 5, section 5.12.

### 1.12

The commit ID is the hash of the commit object, and the object contains the committer line with its time. `--amend` writes a new commit object with a new committer time, so the ID changes even when the tree, the parent, the author and the message are the same. Proof of equal content: `git rev-parse X^{tree} Y^{tree}` prints the same tree ID twice (an empty `git diff X Y` says the same less directly).

The deployment: either move the branch back to the approved commit (it is still in the reflog and, if it was pushed, on the server) or have the new commit approved. Do not weaken the gate. The gate is right: it compares the one identifier that covers every byte of what was reviewed. The process change is that a commit is not rewritten after review; hooks are re-run with a new empty commit or by re-running the job.

*Reference:* Chapter 6, sections 6.4 and 6.7.

### 1.13

Model answer. Git data, in every clone after a fetch: the commits of the head branch, one new merge commit on the base branch with two parents (created with the `--no-ff` behavior and committed by GitHub), the moved ref `refs/heads/main`, and, if it was not deleted, the head branch ref. Git data that GitHub wrote and that a normal clone does not fetch: `refs/pull/<n>/head` in the base repository. GitHub objects, in no clone: the pull request number, title, description, reviews, review threads, labels, the checks attached to commit IDs, the "merged" state and who pressed the button, the rules that had to be satisfied.

Listen for: "the merge commit is Git, the pull request is GitHub", the hidden ref, and the consequence that migrating the repository with a mirror clone carries the commits and not the review record.

*Reference:* Chapter 2, section 2.12; Chapter 15, section 15.2; Chapter 17, sections 17.2 and 17.8.

### 1.14

Model answer. `git add report.py`: Git compresses the content into a new blob object under `.git/objects/` (unless a blob with that ID exists) and rewrites `.git/index` so that the entry for `report.py` holds the new blob ID and fresh stat data. No ref moves, no commit exists yet. `git commit`: Git writes tree objects from the index (one per directory whose content changed; unchanged subtrees are reused), writes one commit object that names the top-level tree, the current commit as parent, author, committer and message, then updates the branch that HEAD points at (`refs/heads/<branch>`) to the new commit ID and appends a line to the reflog of HEAD and of the branch. HEAD itself still says `ref: refs/heads/<branch>`. The index is unchanged and now equals the new commit's tree.

Listen for: blob at `add`, trees and commit at `commit`, the branch ref moves and HEAD does not, the reflog entries.

*Reference:* Chapter 2, section 2.6; Chapter 5, section 5.3; Chapter 6, section 6.3; Chapter 7, section 7.4.

---

## Section 2: Git internals

### 2.1

**Answer: B.** Content addressing: the ID is a hash of the type, the length and the bytes. The two tree entries carry the two paths and the same blob ID. C and D invent a deduplication step; it is a property of the naming, not of maintenance.

*Reference:* Chapter 2, section 2.4; Chapter 3, section 3.3.

### 2.2

**Answer: C.** The commits stay reachable from the reflogs of HEAD and of the branch. An entry that the current tip does not reach expires after 30 days by default (90 for the others); after that the objects are unreachable, and a collection deletes unreachable objects only when they are older than the prune cut-off of two weeks. A and B are the "reset deletes commits" model; D ignores that `git gc` prunes.

*Reference:* Chapter 3, section 3.8; Chapter 13, sections 13.2 and 13.4.

### 2.3

**Answer: B.** The delta base is chosen by similarity (type, name, size), often a newer version as the base of an older one, and never changes what `git cat-file -p` returns. A is the diff model moved one level down; C and D are invented.

*Reference:* Chapter 2, section 2.3; Chapter 3, section 3.7.

### 2.4

**Answer: C.** The index is a sorted, flat list of entries, each with a mode, a blob ID, a stage number (0 normally; 1, 2, 3 during a conflict) and a path, plus cached stat data. A is the "list of files to commit" model; B is the diff model; D ignores that `git commit` builds the tree from it.

*Reference:* Chapter 3, section 3.12; Chapter 5, section 5.2.

### 2.5

**Answer: C.** A blobless partial clone. `--depth 1` cuts history (a shallow clone); `--single-branch` narrows the fetch refspec; `--no-checkout` fetches everything and populates no working tree.

*Reference:* Chapter 26, sections 26.11, 26.12 and 26.13.

### 2.6

**Answer: C.** A lightweight tag is a ref; it writes no object and changes none. A, B and D each write a new commit object (new message, new parent, new author and committer lines), and an object with different bytes has a different ID.

*Reference:* Chapter 6, section 6.4; Chapter 7, section 7.11.

### 2.7

<!-- snippet: final/s02/p1-answer -->
```text
$ git count-objects | cut -d, -f1
3 objects
$ git cat-file -t candidate
commit
$ git cat-file -t v1.0
tag
$ for r in HEAD candidate v1.0 "v1.0^{commit}"; do git rev-parse --short "$r"; done
cb74ca8
cb74ca8
265efc7
cb74ca8
$ git cat-file -p v1.0
object cb74ca803e054641cb0b501f894fab8244328149
type commit
tag v1.0
tagger Lab User <you@example.com> 1788755760 +0530

Release 1.0
```
<!-- /snippet -->

Three objects: one commit, the empty tree, and one tag object. A lightweight tag creates no object: `candidate` resolves straight to the commit. `v1.0` resolves to the tag object, which has its own ID and names the commit; `v1.0^{commit}` peels it. So lines 1, 2 and 4 of the loop are equal and line 3 differs. `git push origin v1.0` transfers the tag object (tagger, date, message) as well as the ref; pushing `candidate` transfers only a ref to a commit.

Award 2 for the output (1 if the object count is 2 or 4), 1 for the mechanism.

*Reference:* Chapter 3, section 3.4; Chapter 14B, section 14B.8.

### 2.8

<!-- snippet: final/s02/p2-answer-a -->
```text
$ ls .git/refs/heads
$ git branch --list
* main
  topic
```
<!-- /snippet -->

(a) `ls` prints nothing: both branches were moved into `.git/packed-refs` and their loose files removed. `git branch` lists both, because lookup reads loose refs first and `packed-refs` second.

<!-- snippet: final/s02/p2-answer-b -->
```text
$ ls .git/refs/heads
main
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
40f917f1f7b0c0bffd30f0eb07da1ec01aef3e5b refs/heads/main
40f917f1f7b0c0bffd30f0eb07da1ec01aef3e5b refs/heads/topic
$ git rev-parse main
f51bdd56ffc52fac7b30cdd3b94fdbb6652b9840
```
<!-- /snippet -->

(b) The commit wrote a new loose file for `main` and left the packed line alone. The packed line shows the first commit; `git rev-parse main` prints the second, because the loose ref wins. The stale line is harmless to Git and wrong for anything that reads the file by hand.

Award 1 for (a), 1 for (b), 1 for "loose first, packed second".

*Reference:* Chapter 3, section 3.9.

### 2.9

<!-- snippet: final/s02/p3-answer -->
```text
$ target=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? target=[$target]"
status=128 target=[no-such-branch]
$ target=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? target=[$target]"
status=1 target=[]
$ target=$(git rev-parse --verify --quiet "main^{commit}"); echo "status=$? length=${#target}"
status=0 length=40
```
<!-- /snippet -->

Without `--verify`, `git rev-parse` passes an argument it cannot resolve through to standard output and reports the failure only through standard error and status 128: the script stores the text `no-such-branch` as if it were a commit ID. With `--verify --quiet` nothing is printed and the status is 1. The third form belongs in a script: `--verify` for exactly one revision, `^{commit}` so that the object exists and is a commit, and the status is tested.

Award 2 for the three lines (1 if the first is predicted as empty), 1 for the reason.

*Reference:* Chapter 3, section 3.6.

### 2.10

<!-- snippet: final/s02/g1-answer -->
```text
$ cat .git/HEAD
61353ac2e1a7ec78ad338208ab7c517a250b0b68
$ git for-each-ref --format='%(refname) %(objecttype) %(objectname:short)'
refs/heads/main commit 6793114
refs/heads/review commit 61353ac
refs/tags/v0.1 tag e62245a
$ git log --oneline --graph --all --decorate
* 6793114 (main) Add the export job
* 61353ac (HEAD, tag: v0.1, review) Add the label schema
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
```
<!-- /snippet -->

```text
  61353ac ---------- 6793114
  ^  ^  ^               ^
  |  |  |               refs/heads/main        (commit)
  |  |  refs/heads/review                      (commit)
  |  refs/tags/v0.1 --> tag object e62245a --> 61353ac
  HEAD (detached: the file holds the full commit ID)
```

`.git/HEAD` holds the ID of the commit, not `ref: ...` and not the ID of the tag object: switching to a tag peels it to the commit. `git symbolic-ref HEAD` fails with status 128 because HEAD is not a symbolic ref. No branch is current, although `review` points at the same commit.

Award 2 for the drawing with the tag object as its own node, 1 for the content of HEAD.

*Reference:* Chapter 3, sections 3.9 and 3.10; Chapter 7, sections 7.3 and 7.7.

### 2.11

`100644`: a regular file; the ID names a blob with its content. `100755`: an executable file; the only permission Git records is this one bit. `040000`: a directory; the ID names another tree. `120000`: a symbolic link; the ID names a blob whose content is the link target, here the text `conf/prod.yaml`, which is what the second command prints. `160000`: a gitlink, the entry a submodule uses; the ID is a commit in another repository and is not an object of this one.

A plain `git clone` creates an empty directory `vendor/tokenizer`: the superproject records only the commit ID, and without `.gitmodules`, `git submodule init` and `update` nothing is fetched. (In this transcript there is not even a `.gitmodules`: the entry was written with plumbing to show the mode.)

Award 1 for the file modes, 1 for the symbolic link, 1 for the gitlink, 1 for what a clone delivers.

*Reference:* Chapter 3, section 3.4; Chapter 4, section 4.10; Chapter 23, sections 23.2 and 23.3.

### 2.12

(a) The nine loose objects were written into one packfile, and the loose ref `main` was moved into `.git/packed-refs`. (b) Name lookup reads loose refs first and `packed-refs` second, so every command resolves `main` as before; only code that reads `.git/refs/heads/main` by hand breaks. (c) The commit is reachable from the reflog of HEAD (`HEAD@{1}`), and reflogs are starting points for reachability; a collection keeps everything reachable. (d) Its reflog entries would have to be gone (expired after 30 days by default, or removed with `git reflog expire`), and the object would have to be older than the prune cut-off, or the collection run with `--prune=now`. Deleting the branch `backup` removed one name for this commit and that ref's own reflog; the reflogs of HEAD and of `main` still reach it.

*Reference:* Chapter 3, sections 3.7 to 3.9; Chapter 13, sections 13.2 and 13.4; Chapter 26, section 26.3.

### 2.13

Mechanism: a ref can be stored as a loose file or as a line in `packed-refs`. Lookup reads the loose file first. Maintenance packs refs; the next update of `main` writes a new loose file and leaves the packed line as it was. Root cause (Git, and the script): the script reads one of two storage places instead of asking Git. On Tuesday a collection packed `main`; since then the packed line has been stale and the loose file has been current.

Corrected line: `git rev-parse --verify --quiet 'refs/heads/main^{commit}'`, with the exit status tested. Rule: a script never reads `.git/refs`, `packed-refs` or `.git/HEAD`; it uses `git rev-parse`, `git for-each-ref` and `git symbolic-ref`. The same rule keeps the script working when the repository uses the reftable backend, where neither file exists.

*Reference:* Chapter 3, sections 3.6, 3.9 and 3.13.

### 2.14

Hypotheses: (1) the job's clone is shallow, so history ends at the one fetched commit; (2) the job checks out a squashed export of the repository or another repository. Separating command: `git rev-parse --is-shallow-repository` (and `cat .git/shallow`).

Root cause (the CI system's checkout default, acting on Git): a clone of depth 1. A shallow repository is complete up to its boundary; `git blame` walks to the boundary commit, cannot go further, and attributes every line to it. Git cannot know that the question reaches further.

Fixes: fetch full history in this job (`git fetch --unshallow`, or the checkout step's full-depth option): slower on a large repository. Or a blobless partial clone (`--filter=blob:none`): every commit and tree, file contents on demand; `blame` then downloads the blobs it needs. Rule: a job may be shallow when it reads one snapshot and is thrown away; a job that blames, describes, bisects, computes a merge base or writes a changelog asks history a question and needs history.

*Reference:* Chapter 26, sections 26.11 to 26.13; Chapter 20A, section 20A.8.

### 2.15

Model answer. An object is reachable when it can be found by starting at a root and following links: a ref to a commit, a commit to its tree and parents, a tree to blobs and trees, a tag object to its target. The roots are branches, tags, remote-tracking branches and every other ref under `refs/`, HEAD, the index, and the reflogs. Git never deletes a reachable object. An unreachable object stays until a collection runs and the object is older than the grace period.

Every recovery is a move back into reachability: a reset or a rebase leaves the old commits reachable from a reflog, so you name them with a branch; a deleted branch leaves commits reachable from the reflog of HEAD; when the reflogs are gone, `git fsck` walks the object database and lists what nothing reaches, while the objects still exist. What was never an object (an unstaged edit) has nothing to reach.

Listen for: the list of roots including reflogs and the index, "delete only what is unreachable and old", and the precondition "was it ever an object".

*Reference:* Chapter 3, section 3.8; Chapter 13, sections 13.2 and 13.12.

### 2.16

Model answer. A new object is written as one zlib-compressed file under `.git/objects/xx/`, a loose object. A packfile holds many objects in one file with an index beside it, and stores similar objects as deltas against each other. `git gc` (and the maintenance tasks that replace it) packs loose objects, packs refs into `packed-refs`, expires reflog entries by the retention settings, and prunes unreachable objects older than the cut-off; unreachable objects that are still inside the grace period are kept, on Git 2.55 in a cruft pack. It never deletes an object that a ref, the index or a reflog entry reaches. The two commands that remove that protection are `git reflog expire --expire=now --all`, which removes the reflog entries, and `git gc --prune=now` (or `git prune`), which removes the grace period. Run together they are the point of no return.

Listen for: packing is not deleting, reflogs as protection, the two-week grace period, and the pair of commands.

*Reference:* Chapter 3, sections 3.3 and 3.7; Chapter 13, section 13.13; Chapter 26, sections 26.3 and 26.5.

---

## Section 3: Branching

### 3.1

**Answer: B.** A branch is a ref: a name that holds one commit ID. No file is copied (A), no parent branch is recorded (C), no commit is written (D). A and C are the "a branch is a copy of the code, with a parent branch" model.

*Reference:* Chapter 7, section 7.2; Chapter 2, section 2.11.

### 3.2

**Answer: C.** Git has no parent-branch concept. `git merge-base` computes the best common ancestor of two refs you name; the only trace of the creation is local, in the reflog of the branch ("branch: Created from ..."), and it is not shared. D lists branches that contain a commit, which is another question.

*Reference:* Chapter 7, sections 7.8 and 7.9.

### 3.3

**Answer: D.** On a detached HEAD a commit moves HEAD and no branch. After the switch nothing names the commits except reflog entries, so they survive for the reflog's retention time and are invisible to `git log --all`. A tag does not move (A); nothing is deleted (B); no rule sends commits to `main` (C).

*Reference:* Chapter 7, section 7.7; Chapter 13, section 13.8.

### 3.4

**Answer: A.** `-d` protects the only ref to commits: it deletes when the branch is merged into its upstream, or into HEAD when it has no upstream. "Merged" means reachable. This is why it refuses after a squash merge, and why it can refuse for a branch that is merged into `main` when HEAD is elsewhere.

*Reference:* Chapter 7, section 7.5; Chapter 17, section 17.9.

### 3.5

**Answer: A.** Deleting a branch deletes the ref and the reflog of that ref. The commits stay until nothing reaches them and a collection prunes them; the reflog of HEAD usually still reaches them. B is the "deleting a branch deletes commits" model, C the "the reflog will always save me" model, D confuses a local branch with the server's.

*Reference:* Chapter 7, section 7.5; Chapter 13, sections 13.8 and 13.12.

### 3.6

<!-- snippet: final/s03/p1-answer -->
```text
$ git branch --merged main
  docs/schema
* main
$ git branch --no-merged main
  parser-v2
$ git branch --contains docs/schema
  docs/schema
* main
  parser-v2
$ git branch -d parser-v2
error: the branch 'parser-v2' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D parser-v2'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

"Merged into `main`" means "the tip is reachable from `main`": true for `docs/schema` (an ancestor) and for `main` itself, false for `parser-v2`. `--contains docs/schema` lists every branch whose history includes that commit, which is all three. `-d` refuses with status 1 because `parser-v2` has no upstream and its tip is not reachable from HEAD.

Award 2 for the outputs (1 if `main` is missing from a list), 1 for "reachable from".

*Reference:* Chapter 7, sections 7.5 and 7.8.

### 3.7

<!-- snippet: final/s03/p2-answer -->
```text
$ git branch feature/retry
fatal: cannot lock ref 'refs/heads/feature/retry': 'refs/heads/feature' exists; cannot create 'refs/heads/feature/retry'
[exit status: 128]
$ git branch -m feature feature/retry
[exit status: 0]
$ git branch --list
  feature/retry
* main
```
<!-- /snippet -->

Ref names form one hierarchy: `refs/heads/feature` is a file, so `refs/heads/feature/retry` cannot be created beside it, and the first command dies with "cannot lock ref" and status 128. The rename succeeds: a rename takes the old name away in the same operation, so the two names never have to exist side by side. A prediction that both fail is the usual one and is wrong on Git 2.55; the run decides.

Award 1 for each command predicted correctly.

*Reference:* Chapter 7, sections 7.5 and 7.12.

### 3.8

<!-- snippet: final/s03/g1-answer -->
```text
$ git log --graph --oneline --all --decorate
* df56248 (HEAD -> feature/batching) F: flush partial batches
* 7ae33fe C: batch the requests
| * 9532bae (hotfix/timeout) E: raise the timeout
|/  
| * 5c5d613 (tag: v0.2, main) D: log the job duration
|/  
* 9f8290e B: add the retry policy
* b0e1e43 A: add the job runner
$ git branch --show-current
feature/batching
$ git merge-base feature/batching hotfix/timeout | xargs git log -1 --format=%s
B: add the retry policy
```
<!-- /snippet -->

```text
            C---F    feature/batching   (HEAD)
           /
  A-------B---D      main, tag v0.2
           \
            E        hotfix/timeout
```

All three lines fork at B, which is also the merge base asked for. The tag sits on D with `main`; if `main` gains a commit the tag stays.

Award 2 for the graph and refs, 1 for HEAD on `feature/batching` and the merge base B. A drawing in which E hangs off D misreads `HEAD~1` in `git switch -c hotfix/timeout HEAD~1`.

*Reference:* Chapter 7, sections 7.6, 7.8 and 7.11.

### 3.9

<!-- snippet: final/s03/g2-answer -->
```text
$ git merge-base main feature/rerank | xargs git log -1 --format=%s
D: cache the scores
$ git log --format=%s main..feature/rerank
F: tune the batch size
$ git log --format=%s feature/rerank..main
G: document the tracing headers
M: merge feature/rerank
E: add request tracing
$ git log -1 --format=%s main~2
E: add request tracing
$ git log -1 --format=%s main~1^2
D: cache the scores
$ git rev-parse --verify --quiet main^2
[exit status: 1]
$ git merge-base --is-ancestor v1.0 feature/rerank
[exit status: 1]
$ git log --first-parent --format=%s main
G: document the tracing headers
M: merge feature/rerank
E: add request tracing
B: add the scorer
A: add the candidate fetcher
```
<!-- /snippet -->

1. D: the merge M made C and D ancestors of `main`, so the best common ancestor is the old tip of the branch, not the fork point B.
2. `main..feature/rerank`: F. `feature/rerank..main`: G, M and E.
3. `main~2` is E (two steps along first parents: G, M, E). `main~1^2` is D (the second parent of M). `main^2` does not exist: G has one parent.
4. No. E is on `main`'s side only; the branch never merged `main`.
5. G, M, E, B, A: the commits as `main` moved, without the branch's own commits.

Award 1 point for parts 1 and 2 together, 1 for part 3, 1 for parts 4 and 5.

*Reference:* Chapter 7, section 7.8; Chapter 8, sections 8.2 and 8.13; Chapter 14A, sections 14A.7 and 14A.8.

### 3.10

(a) `+` marks a branch that is checked out in another worktree; the path is that worktree. `*` is the branch of this worktree. (b) One branch can be checked out in one worktree only: a second checkout would give two indexes and two sets of files that follow one ref, and a deletion would pull the branch from under the other worktree. (c) All worktrees share one object database and one set of refs; each has its own HEAD, index and files. The commit made in the other directory moved `refs/heads/hotfix/tls-reload`, and this directory sees the new value at once. (d) Go to the other directory, or run `git -C ../edgeproxy-hotfix <command>`. To look at the content here without taking the branch, `git switch --detach hotfix/tls-reload`. Do not use `--force`.

*Reference:* Chapter 25, sections 25.2 to 25.4.

### 3.11

On the server a branch named `sweep` existed. It was deleted, and a branch `sweep/lr-warmup` was created. Each old clone still has the remote-tracking ref `refs/remotes/origin/sweep` from an earlier fetch, because a fetch without pruning never deletes remote-tracking refs. The new fetch tries to create `origin/sweep/lr-warmup`, and a ref cannot be a name and a prefix of another name at once. A new clone has no stale ref, so it works.

Layer: Git (ref naming and the default of not pruning). Fix on a laptop: `git fetch --prune`, or `git remote prune origin`; both delete only the stale remote-tracking ref. Local branches are untouched. Prevention: reserve top-level names such as `sweep`, `feature`, `fix` as namespaces and never create a plain branch with one of them; `fetch.prune=true` in the team configuration.

*Reference:* Chapter 7, section 7.12; Chapter 12, section 12.11.

### 3.12

State: both worktrees have HEAD attached to the same branch. The commit made in the first directory advanced the shared ref. The second directory's index and files still describe the old commit. `git status` compares HEAD (now the new commit) with the index (the old tree), and the difference read in that direction is the inverse of the new commit.

It can only arise by overriding the one-branch-one-worktree rule: `git worktree add --force`, or moving HEAD by hand. The commit he is about to make would record the old tree on top of the new commit: a silent revert of the colleague's work, with the message "sync".

Fix, no own work there: `git reset --hard` in the second directory (preview with `git status`; the "changes" are not his). Own work there: `git stash`, `git reset --hard`, `git stash pop`. Then give the second worktree its own branch or a detached HEAD (`git switch --detach`), so that the state cannot recur.

*Reference:* Chapter 25, section 25.4.

### 3.13

Model solution, as a replay of the lab. The two commits are named by the reflog of HEAD; the branch name is refused because a branch called `fix` exists and a ref cannot be a name and a prefix.

<!-- snippet: final/solve-branching/01-observe -->
```text
$ cd driftwatch
$ git status -sb
## main
$ git log --oneline --graph --all --decorate
* 86bfef7 (HEAD -> main) Add the Slack alert
* 652d087 (tag: v0.3.0) Add the drift report
* 01cb53a (fix) Avoid division by zero in empty bins
* 359c50d Add the KS test
* ebc532f Add the PSI metric
$ git reflog -5
86bfef7 HEAD@{0}: checkout: moving from 25322378c74fb9034e091a69cfe3939fd96d222a to main
2532237 HEAD@{1}: commit: Reject a window size below one
525dcc6 HEAD@{2}: commit: Make the window size configurable
652d087 HEAD@{3}: checkout: moving from main to v0.3.0
86bfef7 HEAD@{4}: commit: Add the Slack alert
```
<!-- /snippet -->

<!-- snippet: final/solve-branching/02-name -->
```text
$ git branch fix/window-size "HEAD@{1}"
fatal: cannot lock ref 'refs/heads/fix/window-size': 'refs/heads/fix' exists; cannot create 'refs/heads/fix/window-size'
[exit status: 128]
$ git branch -vv
  fix  01cb53a Avoid division by zero in empty bins
* main 86bfef7 Add the Slack alert
$ git branch --merged main
  fix
* main
```
<!-- /snippet -->

`fix` is an ancestor of `main`, so `git branch -d` removes it without losing anything. Renaming it out of the way (`git branch -m fix fixes-old`) also passes the check.

<!-- snippet: final/solve-branching/03-repair -->
```text
$ git branch -d fix
Deleted branch fix (was 01cb53a).
$ git switch -c fix/window-size "HEAD@{1}"
Switched to a new branch 'fix/window-size'
$ git log --oneline --graph --all --decorate
* 2532237 (HEAD -> fix/window-size) Reject a window size below one
* 525dcc6 Make the window size configurable
| * 86bfef7 (main) Add the Slack alert
|/  
* 652d087 (tag: v0.3.0) Add the drift report
* 01cb53a Avoid division by zero in empty bins
* 359c50d Add the KS test
* ebc532f Add the PSI metric
$ cd ..
$ assessments/gen/final-branching/check.sh
Checking final-test lab branching
  ok    the branch fix/window-size exists and points at the second of the two commits
  ok    fix/window-size starts at the release v0.3.0
  ok    main has not moved
  ok    the tag v0.3.0 has not moved
  ok    no branch named "fix" is left
  ok    the commit of the old branch "fix" is still reachable from main
  ok    HEAD is on fix/window-size
  ok    nothing is staged, modified or untracked
PASS: the end state of branching is right.
[exit status: 0]
```
<!-- /snippet -->

Hand-in (4 points): 2 for the command that found the commits (`git reflog`, with the two "commit:" lines after "checkout: moving from main to v0.3.0"), 2 for the explanation of the refusal (one ref hierarchy; `refs/heads/fix` is a file where a directory is needed). Deduct 2 from the hand-in if the commits were copied with `git cherry-pick`: the check then fails, because the task asks for the existing commit IDs, and a copy on `main` would also put release-only fixes on the wrong line.

*Reference:* Chapter 7, sections 7.7 and 7.12; Chapter 13, sections 13.3 and 13.8.

### 3.14

Model answer. HEAD is the file `.git/HEAD`; it normally holds `ref: refs/heads/<branch>`, and `git switch` rewrites it, while a commit moves the branch it names and leaves HEAD's content alone. A branch is the ref `refs/heads/<name>` in your repository; commits, resets, merges and rebases on that branch move it, and nothing on the server moves it. A remote-tracking branch is the ref `refs/remotes/<remote>/<name>` in your repository; it records where the remote's branch was when you last fetched from or pushed to that remote, and only those exchanges move it.

"Up to date with 'origin/main'" compares two refs in your own repository, `refs/heads/main` and `refs/remotes/origin/main`. No connection is opened. The server may be ahead; `git fetch` or `git ls-remote origin main` tells you.

Listen for: three refs in the local repository, "last fetch", and the fact that status is computed offline.

*Reference:* Chapter 7, sections 7.2, 7.3 and 7.10; Chapter 12, section 12.4.

---

## Section 4: Merge

### 4.1

**Answer: B.** The rule table of the three-way merge: changed on one side only, take that side; changed identically on both, take it; changed differently on both, conflict. A is the "theirs wins" model; C compares the two tips and forgets the base, which is what makes the merge three-way; D: dates play no part.

*Reference:* Chapter 8, section 8.4.

### 4.2

**Answer: C.** A fast-forward moves a ref and writes no object. A needs `--no-ff`; B does not exist as a merge; D describes a rebase or a cherry-pick.

*Reference:* Chapter 8, sections 8.3 and 8.12.

### 4.3

**Answer: B.** The merge works on hunks; two changes with no unchanged line between them form one region changed by both sides. One unchanged line between them is enough to keep them apart. A is the "Git merges whole files" model.

*Reference:* Chapter 8, section 8.7.

### 4.4

**Answer: D.** The sides changed disjoint paths, so by the rule table each path was taken as it was; no file-level merge ran. Git has no parser and no test runner. The control is to test the merge result (CI on the pull request's merge ref with an up-to-date base, or a merge queue).

*Reference:* Chapter 8, section 8.15.

### 4.5

**Answer: A.** The merge base is computed from parent links, and a squash writes none to the branch. Both sides have "changed" the same lines since the old base. The rule is one squash per branch: delete the branch afterwards.

*Reference:* Chapter 8, section 8.12; Chapter 17, section 17.12.

### 4.6

<!-- snippet: final/s04/p1-answer -->
```text
$ cat sampling.yaml
temperature: 0.2
top_p: 0.9
$ cat limits.yaml
max_tokens: 1024
$ git log --oneline --graph
*   ecf7c8a Merge feature/deterministic
|\  
| * cfc4463 Deterministic sampling, longer answers
* | 9650ef8 Lower the temperature
|/  
* 1a4775f Add sampling defaults
```
<!-- /snippet -->

`-X ours` is an option of the ordinary strategy: where the two sides conflict, our hunk is taken (temperature 0.2), and everything that does not conflict is merged as usual (their `max_tokens: 1024` arrives). `-s ours` is a different strategy: it records a merge commit whose tree is exactly ours and ignores the other branch's content completely, so `limits.yaml` would still say 256 while the branch would count as merged.

Award 2 for the two files, 1 for the contrast.

*Reference:* Chapter 8, section 8.6.

### 4.7

<!-- snippet: final/s04/p2-answer -->
```text
$ git merge --ff-only feature/replicas
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
$ git status -sb
## main
$ git merge-tree --write-tree --name-only main feature/replicas
f19c8968721347a160ac7442ad3071f41d939558
[exit status: 0]
$ git log --oneline --graph --all
* 6db9330 Double the shards
| * 64f991f Add replica settings
|/  
* ff0c46d Add index settings
```
<!-- /snippet -->

The branches have diverged, so `--ff-only` refuses with status 128 and changes nothing: no ref, no index entry, no file. `git merge-tree --write-tree` performs the merge in the object database only: it prints the ID of the tree a merge would produce, exits 0 because the merge is clean (1 would mean conflicts), and moves no ref and touches no working tree. The graph afterwards still shows two tips.

Award 1 per command.

*Reference:* Chapter 8, sections 8.12 and 8.17.

### 4.8

<!-- snippet: final/s04/g1-answer -->
```text
$ git log --graph --oneline --all --decorate
*-.   1b06686 (HEAD -> main) M: merge histograms and exemplars
|\ \  
| | * 3bf928e (feature/exemplars) C: add exemplars
| * | 8ae5ffa (feature/histograms) B: add histograms
| |/  
* / 3cd6bdc D: add the scrape endpoint
|/  
* 003e6e4 A: add the collector
$ git cat-file -p HEAD | grep -c "^parent"
3
$ git log -1 --format=%s HEAD^3
C: add exemplars
$ git log --first-parent --format=%s
M: merge histograms and exemplars
D: add the scrape endpoint
A: add the collector
```
<!-- /snippet -->

```text
        B-----------.      feature/histograms
       /             \
  A---+---D-----------M    main   (HEAD)
       \             /
        C-----------'      feature/exemplars
```

An octopus merge: one commit, three parents, in the order "current branch first, then the arguments as given": D, B, C. `HEAD^3` is C. `--first-parent` lists M, D, A.

Award 2 for the graph, 1 for the parent order and the first-parent list. Two successive merge commits is the wrong drawing: one `git merge` command with two branch arguments makes one commit.

*Reference:* Chapter 8, sections 8.13 and 8.14.

### 4.9

<!-- snippet: final/s04/g2-answer -->
```text
$ git merge-base --all main develop | xargs -n1 git log -1 --format=%s
B: add rounding settings
C: add tax settings
$ git merge-base main develop | xargs git log -1 --format=%s
B: add rounding settings
```
<!-- /snippet -->

1. Two commits: B and C. Neither is an ancestor of the other, and both are common ancestors of the two tips. Without `--all`, `git merge-base` prints one of them.
2. A criss-cross: each branch merged the other's earlier tip (`main` merged C, `develop` merged B).
3. The ort strategy first merges the merge bases with each other and uses the result as a virtual base. If that inner merge conflicts, its result, markers included, becomes the base; the markers are labelled "Temporary merge branch 1" and "2".

Award 1 per part.

*Reference:* Chapter 8, section 8.5.

### 4.10

(a) During the merge Git compares each side with the merge base. On our side `utils/text.py` disappeared and `chunking/split.py` appeared with the same content, so rename detection pairs them, and their side's change to the old path is applied to the new path. The message says "Auto-merging chunking/split.py". (b) From nowhere in the history: no commit records a rename. It is inferred, at merge time, from the similarity of a deleted and an added path. (c) If the move had also rewritten the file so far that the similarity fell below the threshold (50% by default), Git would have seen a deletion and an unrelated addition, and their edit of a deleted file is a modify/delete conflict. (d) `git ls-files` (no `utils/text.py`), `git status`, and a search for the fixed code: `git grep -n "if not words"` shows one hit in the new file.

*Reference:* Chapter 8, section 8.11; Chapter 4, section 4.9.

### 4.11

(a) The two letters are our side and their side: `U` unmerged (we modified), `D` deleted by them. "Ours" is HEAD, the branch being merged into (`main`); "theirs" is `cleanup/remove-v1`. (b) Stage 1 is the base version, stage 2 ours, stage 3 theirs. Their side has no such file, so there is no stage 3 entry. (c) Our modified version, whole: "Version HEAD of v1.py left in tree". There are no markers because there are not two texts to interleave; the conflict is about whether the path exists. (d) Keep the file: `git add v1.py`, then `git commit`. Accept the deletion: `git rm v1.py`, then `git commit`. In the second case the timeout change is dropped on purpose; say so in the merge message.

*Reference:* Chapter 8, sections 8.8 and 8.11; Chapter 5, section 5.13.

### 4.12

Mechanism (Git, documented in the manual of `git merge`): with a whitespace option, when their version only introduces whitespace changes to a line, our version of the line is used. The option does not merge whitespace changes; it discards them wherever they meet a line that our side kept or changed. A line cannot carry their indentation and our text without Git inventing a third version. In the extreme case the merge commit's tree equals its first parent's tree and the branch still counts as merged.

Fix: run the formatter again on `main` and commit the result. Landing a formatting change: when no other branch is open on those files, or by having every open branch run the same formatter after merging; record the commit in a `.git-blame-ignore-revs` file so that blame skips it.

*Reference:* Chapter 8, section 8.6; Chapter 14A, section 14A.17.

### 4.13

Root cause: a move and a rewrite in one commit. A tree stores names and blob IDs; a rename is an inference from similarity and needs a cut-off, 50% by default. Below it Git sees a deleted path and an added path, and your edit of the deleted path is a modify/delete conflict.

Similarity: `git diff --name-status -M10% $(git merge-base HEAD main) main -- retrieval ranking` prints an `R` line with the score when the pair reaches the lowered threshold.

To finish: (1) `git merge --abort`, then `git merge -X find-renames=30% main` (a threshold below the score), so that your edit is merged into the new file; or (2) keep the merge, port your edit into `ranking/bm25.py` by hand, `git rm retrieval/ranker.py`, `git add`, commit. Prevention: land a move as its own commit with no content change, merge it into every open branch, and rewrite afterwards.

*Reference:* Chapter 8, section 8.11.

### 4.14

Model diagnosis and repair, as a replay of the lab.

<!-- snippet: final/solve-merge/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ sh tests/smoke.sh
undefined: store.fetch_answer
[exit status: 1]
$ git log --oneline --graph
*   f6bcf8e Merge feature/bulk-export
|\  
| * cd08d0e Add the bulk export
* |   9323598 Merge refactor/store-names
|\ \  
| |/  
|/|   
| * 47fcf69 Rename fetch_answer to get_answer
|/  
* 8c6f278 Add the answer store and its API
```
<!-- /snippet -->

<!-- snippet: final/solve-merge/02-evidence -->
```text
$ git grep -n "fetch_answer\|get_answer"
answerbank/api.py:5:    answer = store.get_answer(qid)
answerbank/export.py:7:        rows.append((qid, store.fetch_answer(qid)))
answerbank/store.py:4:def get_answer(qid):
$ git diff --stat HEAD~1 HEAD
 answerbank/export.py | 8 ++++++++
 1 file changed, 8 insertions(+)
$ git diff --stat HEAD~2 HEAD~1
 answerbank/api.py   | 2 +-
 answerbank/store.py | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
# Did the second merge have to combine any file? Which paths did each side change since the merge base?
$ git diff --name-only HEAD~1...origin/feature/bulk-export
answerbank/export.py
$ git diff --name-only origin/feature/bulk-export...HEAD~1
answerbank/api.py
answerbank/store.py
```
<!-- /snippet -->

The two three-dot listings are the proof asked for in step 1: since the merge base, one side changed only `answerbank/export.py` and the other only `answerbank/api.py` and `answerbank/store.py`. No path was changed by both, so no file-level merge ran and there was nothing for Git to report.

<!-- snippet: final/solve-merge/03-repair -->
```text
$ sed -e 's/store\.fetch_answer(/store.get_answer(/' answerbank/export.py > export.new && mv export.new answerbank/export.py
$ git diff
diff --git a/answerbank/export.py b/answerbank/export.py
index b74df5a..a52af1c 100644
--- a/answerbank/export.py
+++ b/answerbank/export.py
@@ -4,5 +4,5 @@ from answerbank import store
 def export(qids):
     rows = []
     for qid in qids:
-        rows.append((qid, store.fetch_answer(qid)))
+        rows.append((qid, store.get_answer(qid)))
     return rows
$ sh tests/smoke.sh
smoke test passed
[exit status: 0]
$ git commit -q -a -m "Call get_answer in the bulk export"
$ git push
To ../server.git
   f6bcf8e..2250c38  main -> main
$ git log --oneline --graph -4
* 2250c38 Call get_answer in the bulk export
*   f6bcf8e Merge feature/bulk-export
|\  
| * cd08d0e Add the bulk export
* |   9323598 Merge refactor/store-names
|\ \  
| |/  
|/|   
$ cd ..
$ assessments/gen/final-merge/check.sh
Checking final-test lab merge
  ok    main on the server still contains the two merges (nothing was rewritten)
  ok    main on the server has at least one new commit
  ok    the rename is still on main: store.py defines get_answer
  ok    the bulk export is still on main
  ok    tests/smoke.sh is unchanged
  ok    every store.<name>( call on main has a definition (the smoke test passes)
  ok    your main equals main on the server
  ok    nothing is staged, modified or untracked in your clone
  ok    no operation is left in progress
PASS: the end state of merge is right.
[exit status: 0]
```
<!-- /snippet -->

Hand-in (4 points): 2 for the root cause with its layer ("a semantic conflict: the dependency between a renamed function and a new caller lives in Python's name resolution, not in the text of one file; Git merged disjoint paths by its rule table"), 2 for a control that tests the merge result before it reaches `main`: required checks with "require branches to be up to date", or a merge queue. "Be more careful when merging" earns nothing. Reverting one of the merges fails the check and is also the worse fix: it removes a feature, and re-merging a reverted merge needs the revert to be reverted.

*Reference:* Chapter 8, sections 8.15 and 8.16; Chapter 17, sections 17.6 and 17.11; Chapter 18, section 18.8.

### 4.15

Model answer. A clean merge guarantees one thing: for every region of every file, at most one side changed it since the merge base, or both changed it identically. It says nothing about whether the combination compiles, passes tests or means what either author meant. Git merges snapshots of text; it has no knowledge of any language. The classic failure: one side renames a function, the other adds a caller of the old name in another file. Two more: both sides add the same import or the same list entry in different places and the result has it twice; a whitespace option silently discards one side's change.

Controls: test the merge result, not the branch (the pull request's merge ref, with the base required to be current, or a merge queue that tests the exact commit that will land); keep branches short so that the overlap is small; review the merge commit itself when a conflict was resolved by hand (`git show --remerge-diff`).

Listen for: "clean is a statement about text regions", a concrete example, and a control that runs code on the merged tree.

*Reference:* Chapter 8, sections 8.4, 8.15 and 8.16.

---

## Section 5: Rebase

### 5.1

**Answer: B.** A rebase writes new commit objects: each has a new parent and a new committer line (name, email, time), and the ID is the hash of those bytes. The descendants change because their parent IDs change. A, C and D are inventions; D reverses the truth.

*Reference:* Chapter 9, section 9.3; Chapter 6, section 6.4.

### 5.2

**Answer: D.** A rebase checks out the new base and replays your commits onto it one at a time, so the side being merged into ("ours", stage 2) is the upstream side, and the commit being replayed is "theirs" (stage 3). The roles are the reverse of what "my branch" suggests; in the poll cited in section 12 of the Phase 0 report, 48% of respondents did not know this.

*Reference:* Chapter 9, section 9.11; Chapter 2, section 2.11.

### 5.3

**Answer: A.** Git knows reachability only; it has no record that your branch "belongs on top of" another. After the squash, the commits of `feature/a` are not reachable from `main`, so a plain rebase replays them against a `main` that already has their content. `--onto <new base> <boundary> <branch>` names what is yours.

*Reference:* Chapter 9, section 9.5; Chapter 17, section 17.14.

### 5.4

**Answer: A.** The fork point is the newest commit of the local branch that was once the tip of the remote-tracking ref, found in that ref's reflog (`git merge-base --fork-point`). Git cannot tell "upstream dropped this on purpose" from "someone overwrote it". The commit is still in her branch reflog: `git cherry-pick <branch>@{1}`. B is the "force push deletes objects" model; C and D are false.

*Reference:* Chapter 9, section 9.17; Chapter 12, section 12.8.

### 5.5

**Answer: C.** A finished rebase wrote `ORIG_HEAD`; resetting to it right away restores the old tip. Tomorrow use the branch reflog (`<branch>@{1}` or the entry below "rebase (finish)"), because `ORIG_HEAD` is one slot that the next reset, merge or rebase overwrites. `--abort` works only while a rebase is in progress; `revert` undoes one commit's change, not a rewrite; `pull` integrates something else.

*Reference:* Chapter 9, section 9.16; Chapter 13, section 13.5.

### 5.6

<!-- snippet: final/s05/p1-answer -->
```text
$ git log -1 --date=format:%H:%M --format='%s%nauthor    %an at %ad%ncommitter %cn at %cd' ORIG_HEAD
Resolve DOIs
author    Asha Rao at 10:06
committer Asha Rao at 10:06
$ git log -1 --date=format:%H:%M --format='%s%nauthor    %an at %ad%ncommitter %cn at %cd' HEAD
Resolve DOIs
author    Asha Rao at 10:06
committer Lab User at 10:10
$ git log --format=%h -1 ORIG_HEAD; git log --format=%h -1 HEAD
e593260
692bcd5
```
<!-- /snippet -->

The author is preserved: Asha, with her original time. The committer becomes whoever ran the rebase, with the time of the rebase. Before the rebase both lines were Asha's and equal; afterwards they differ. The IDs differ because the parent and the committer line are part of the object.

Award 2 for the four names and the two time comparisons, 1 for the reason.

*Reference:* Chapter 6, section 6.5; Chapter 9, section 9.3.

### 5.7

<!-- snippet: final/s05/p2-answer -->
```text
$ git branch --show-current
$ git rev-parse --abbrev-ref HEAD
HEAD
$ cat .git/rebase-merge/head-name
refs/heads/feature/long-docs
$ git log --oneline -1 feature/long-docs
43a6d37 Add a sliding window
$ git log --oneline -1 HEAD
240cf0e Raise the default length
$ git status --short
UU summary.yaml
$ git status | head -5
interactive rebase in progress; onto 240cf0e
Last command done (1 command done):
   pick f38d452 # Allow long documents
Next command to do (1 remaining command):
   pick 43a6d37 # Add a sliding window
```
<!-- /snippet -->

During a rebase HEAD is detached: `--show-current` prints an empty line and `--abbrev-ref` prints `HEAD`. The branch being rebased is remembered in `.git/rebase-merge/head-name`, and the branch ref itself has not moved: it still points at the old tip, "Add a sliding window". HEAD is at the tip of `main` because the first pick stopped before creating a commit. The ref moves only when the last instruction has succeeded, which is what makes `--abort` possible and what makes commits made "inside" a rebase invisible to `git push <remote> <branch>`.

Award 2 for the outputs (1 if the branch is predicted to have moved), 1 for the mechanism.

*Reference:* Chapter 9, section 9.4; Chapter 29, sections 29.3 and 29.6.

### 5.8

<!-- snippet: final/s05/g1-answer -->
```text
$ git log --graph --oneline --all --decorate
* 7847495 (HEAD -> stack/load) D: load into the warehouse
* 1904dde (stack/transform) C: normalize the records
* 264eeeb (stack/extract) B: extract from the API
* 4987d91 (main) E: add retries to the scheduler
* 77f19a6 A: add the scheduler
```
<!-- /snippet -->

```text
  A---E---B'---C'---D'
      ^   ^    ^    ^
   main   |    |    stack/load   (HEAD)
          |    stack/transform
          stack/extract
```

All three commits are new objects. With `--update-refs`, every branch that pointed at a commit being replayed is moved to the corresponding new commit when the rebase finishes. Without the option only `stack/load` moves: `stack/extract` and `stack/transform` stay on the old B and C, which fork from A, and each has to be rebased separately with `--onto`.

Award 2 for the graph, 1 for the contrast.

*Reference:* Chapter 9, section 9.9.

### 5.9

<!-- snippet: final/s05/g2-rebase -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 6f34b54 # Add term lookup
pick ec40242 # Add synonyms
pick 8534d40 # wip: debug print
pick 3935c00 # Fix a typo in the synonyms
--- todo list as saved ---
pick 6f34b54 # Add term lookup
pick ec40242 # Add synonyms
drop 8534d40 # wip: debug print
fixup 3935c00 # Fix a typo in the synonyms
Rebasing (4/4)
Successfully rebased and updated refs/heads/feature/lookup.
```
<!-- /snippet -->

<!-- snippet: final/s05/g2-answer -->
```text
$ git log --oneline main..feature/lookup
b322548 Add synonyms
6f34b54 Add term lookup
$ git ls-files
loader.py
lookup.py
synonyms.py
$ cat synonyms.py
SYNONYMS = {"llm": "large language model"}
```
<!-- /snippet -->

Two commits: "Add term lookup" and "Add synonyms". The first keeps its ID: its parent, tree, author and committer lines are all unchanged, so there is nothing to rewrite and the rebase fast-forwards over it. The second is a new object with a new ID: the fixup changed its tree (the corrected spelling) and the commit was created again. `debug.py` is in no commit of the branch.

Award 2 for the drawing, 1 for "an unchanged prefix keeps its IDs, and why".

*Reference:* Chapter 9, sections 9.6 and 9.7.

### 5.10

(a) "skipped previously applied commit": "Fix the random seed" is already on `main` as a commit with the same patch, so the rebase leaves it out. In the `range-diff` it is the line `2: ... < -: -------`, a commit of the old series with no counterpart in the new one. (b) `=`: the two commits have the same patch. `!`: the commits correspond and their patches differ; a diff of the two diffs follows. `<`: only in the old range. `>` would mean only in the new range. (c) The rebased commit no longer changes the threshold line to one value: it adds the lines `<<<<<<< HEAD`, `=======` and `>>>>>>>` around it. Conflict markers were saved into the file and committed. (d) No. The file is not valid Python. Lowest risk, since the branch is not pushed: `git reset --hard ORIG_HEAD` (the old tip; check it with `git log -1 ORIG_HEAD` first) and rebase again, or a fixup commit that removes the markers followed by `git rebase -i --autosquash`. Then run `range-diff` again.

*Reference:* Chapter 9, sections 9.12 and 9.14; Chapter 8, section 8.10.

### 5.11

(a) The HEAD reflog records every position of HEAD: the checkout of the new base ("rebase (start)"), each replayed commit, and the return to the branch ("rebase (finish)"). The branch reflog records one movement, from the old tip to the new one. (b) The branch ref stayed on the old tip for the whole rebase and moved once, at the end. (c) `ORIG_HEAD` and `feature/strict-eval@{1}`. Use the branch reflog tomorrow: `ORIG_HEAD` is a single slot that the next reset, merge, rebase or `git am` overwrites, on whatever branch that happens. (d) They are reachable from both reflogs. Reflog entries are roots for reachability, and a collection deletes only what nothing reaches.

*Reference:* Chapter 9, sections 9.4 and 9.16; Chapter 13, sections 13.3 and 13.5.

### 5.12

In a rebase "ours" is the side being rebased onto. `git checkout --ours` put `main`'s version of the file into the working tree, and `git add` staged it. The index then equalled HEAD, so the instruction had nothing to commit. A commit that becomes empty during a replay is dropped by default (`--empty=drop`), without a message, because the usual reason is that the change is already upstream.

Recovery: the old tip is in the branch reflog. If nothing else happened, `git reset --hard ORIG_HEAD`; otherwise `git branch rescue <branch>@{1}` and rebase again, taking `--theirs` for that file or editing by hand.

Habits: read `git status` before `--continue` (an empty status at a conflict stop means "this commit will vanish"), and run `git range-diff <base> ORIG_HEAD HEAD` after every rebase that stopped; the dropped commit appears there with `<`.

*Reference:* Chapter 9, sections 9.11, 9.14 and 9.16.

### 5.13

Each commit of a rebase starts `git maintenance run --auto` in the background. Since Git 2.54 the default strategy includes the task `rerere-gc`, which runs whenever the rerere cache has an entry and holds `MERGE_RR.lock` while it works. The next step of the rebase wants the same lock at the same moment and dies with status 128.

Nothing is damaged: the rebase is stopped at that commit with conflict markers, and rerere has neither recorded nor replayed anything for it. Do not delete the lock file by hand while a process may still own it, and do not restart from the beginning. Continue: `git rerere`, resolve, `git add`, `git rebase --continue`. Prevention: `git config set maintenance.rerere-gc.auto 0` in repositories where you rebase with rerere, and an occasional `git rerere gc` by hand.

*Reference:* Chapter 14C, section 14C.3.

### 5.14

Model solution, as a replay of the lab.

<!-- snippet: final/solve-rebase/01-observe -->
```text
$ cd you
$ git status -sb
## feature/span-match
$ git log --oneline --graph --all --decorate
* a5c3d4c (origin/main, origin/HEAD) Add citation parser
| * 8c119de (HEAD -> feature/span-match) Remove debug log
| * 1fb8f3a fixup! Add span matcher
| * 742cb3c Add fuzzy threshold
| * 06b6803 wip
| * 00276ee Add span matcher
|/  
* fe3cccd (main) Add README
* 0d97beb Add citation extraction
$ git log --oneline --name-status origin/main..feature/span-match
8c119de Remove debug log
D	debug.log
1fb8f3a fixup! Add span matcher
M	citecheck/match.py
742cb3c Add fuzzy threshold
A	config.yaml
06b6803 wip
A	citecheck/overlap.py
A	debug.log
00276ee Add span matcher
A	citecheck/match.py
```
<!-- /snippet -->

A backup ref first. `--autosquash` moves the `fixup!` commit behind its target. Two edits remain for you: the `wip` line becomes `reword` and the commit that deletes the log is moved directly behind it as a `fixup`, so that the log is added and deleted inside one commit and appears in none.

<!-- snippet: final/solve-rebase/02-rebase -->
```text
$ git branch backup/span-match
$ git rebase -i --autosquash origin/main
--- todo list as Git opened it (comment lines removed) ---
pick 00276ee # Add span matcher
fixup 1fb8f3a # fixup! Add span matcher
pick 06b6803 # wip
pick 742cb3c # Add fuzzy threshold
pick 8c119de # Remove debug log
--- todo list as saved ---
pick 00276ee # Add span matcher
fixup 1fb8f3a # fixup! Add span matcher
reword 06b6803 # wip
fixup 8c119de # Remove debug log
pick 742cb3c # Add fuzzy threshold
Rebasing (1/5)
Rebasing (2/5)
Rebasing (3/5)
[detached HEAD 6cdc8da] Add overlap scoring
 Date: Mon Sep 7 10:11:00 2026 +0530
 2 files changed, 5 insertions(+)
 create mode 100644 citecheck/overlap.py
 create mode 100644 debug.log
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feature/span-match.
```
<!-- /snippet -->

<!-- snippet: final/solve-rebase/03-verify -->
```text
$ git log --oneline --name-status origin/main..feature/span-match
b15bf71 Add fuzzy threshold
A	config.yaml
edf2540 Add overlap scoring
A	citecheck/overlap.py
520382a Add span matcher
A	citecheck/match.py
$ git range-diff origin/main backup/span-match feature/span-match
1:  00276ee < -:  ------- Add span matcher
2:  06b6803 < -:  ------- wip
-:  ------- > 1:  520382a Add span matcher
-:  ------- > 2:  edf2540 Add overlap scoring
3:  742cb3c = 3:  b15bf71 Add fuzzy threshold
4:  1fb8f3a < -:  ------- fixup! Add span matcher
5:  8c119de < -:  ------- Remove debug log
# Proof of content: the new tip against a test merge of the old branch with origin/main.
$ git merge-tree --write-tree origin/main backup/span-match
0237d1afe4cc5a417d4ae3e603f2c6d62ee9caf2
$ git rev-parse 'feature/span-match^{tree}'
0237d1afe4cc5a417d4ae3e603f2c6d62ee9caf2
$ git branch -D backup/span-match
Deleted branch backup/span-match (was 8c119de).
$ cd ..
$ assessments/gen/final-rebase/check.sh
Checking final-test lab rebase
  ok    HEAD is on feature/span-match
  ok    no rebase or other operation is left in progress
  ok    the branch sits on top of the current origin/main
  ok    the branch has exactly these three commits, in this order
  ok    the files at the tip are what the five commits and origin/main produce together
  ok    no commit of the branch touches debug.log
  ok    the commit "Add span matcher" no longer contains the misspelled name
  ok    the commit "Add overlap scoring" adds citecheck/overlap.py
  ok    main on the server was not touched
  ok    nothing is staged, modified or untracked
PASS: the end state of rebase is right.
[exit status: 0]
```
<!-- /snippet -->

The proof of content is the last pair of lines: the tree of the new tip equals the tree of a test merge of the old branch with `origin/main`. `range-diff` shows what was done to each commit and is the second acceptable proof.

Hand-in (4 points): 2 for the saved todo list (order and verbs as above, or an equivalent that passes), 2 for a proof command that compares content and not messages: `git merge-tree --write-tree` against the tree of the tip, `git diff backup/span-match feature/span-match` read together with `git diff backup...origin/main`, or `git range-diff`. No backup ref and no reference to the reflog as the alternative: deduct 1.

*Reference:* Chapter 9, sections 9.6, 9.7, 9.14 and 9.16; Chapter 8, section 8.17.

### 5.15

Model answer. A branch only I use: rebase freely. The old commits stay in my reflog, nobody else has them, and a linear branch on a current base is cheaper to review and to bisect. A branch others have fetched: do not rebase it. A rebase gives every commit a new ID; the others' clones still hold the old commits, and their next pull either merges old and new (every commit twice) or, with `pull --rebase`, can drop commits they had pushed. If it has to be done, it is announced, done by one person, pushed with `--force-with-lease` and `--force-if-includes`, and everyone else resets or rebases with `--onto`. Bringing a pull request up to date: on my own pull request branch rebase onto the base and force-push with a lease, knowing that approvals may be dismissed as stale; on a branch others push to, merge the base in, which keeps every ID. The merge method on the platform is a separate decision.

Listen for: new IDs, what happens in other clones, the lease, and the cost in review state.

*Reference:* Chapter 9, sections 9.15, 9.17 and 9.18; Chapter 17, section 17.5.

---

## Section 6: Undo

### 6.1

**Answer: B.** `--soft` moves only the branch; `--mixed` also resets the index; `--hard` also overwrites the working tree; `--keep` moves the branch and updates files like `--hard` but refuses when a local change would be overwritten.

*Reference:* Chapter 11, sections 11.4 and 11.6.

### 6.2

**Answer: B.** The deciding question of the chapter is whether another repository has the commit. If it does, undo by adding. A and D rewrite published history: every clone that has the commit must then be repaired, and a careless pull brings it back. C creates a second commit with a new ID and leaves the published one where it is.

*Reference:* Chapter 11, sections 11.2, 11.8 and 11.12.

### 6.3

**Answer: C.** An edit that was only saved in the editor was never written as an object; `--hard` overwrote the one place it existed. A is in the reflog; B has a blob that `git fsck --lost-found` finds (without its file name); D is untouched by a reset. A and B are the "reset --hard deletes everything" model, in reverse.

*Reference:* Chapter 11, section 11.5; Chapter 13, sections 13.9 and 13.12.

### 6.4

**Answer: A.** A merge combines what each side changed since the merge base. The first merge made the old branch commits ancestors of `main`, so the base is the old branch tip and only the new commit counts as the branch's change; on `main`'s side the revert is a change that nothing opposes. The fix is to revert the revert and then merge, or to recreate the branch as new commits.

*Reference:* Chapter 11, section 11.9.

### 6.5

**Answer: D.** `-d` adds untracked directories, `-x` adds ignored files; none of them was ever an object, so no reflog and no `fsck` can help. Preview with `-n`.

*Reference:* Chapter 11, section 11.10; Chapter 4, section 4.14.

### 6.6

<!-- snippet: final/s06/p1-answer -->
```text
$ git status --short
 M README.md
 M burst.yaml
 M limits.yaml
$ git log --oneline
147e7f6 Add rate limits
$ git diff --cached --stat
$ cat limits.yaml
per_minute: 30
```
<!-- /snippet -->

A mixed reset moves the branch to the first commit and resets the whole index to it, not only the paths of the removed commit. So the staged change of `burst.yaml` becomes unstaged, the change that the removed commit made to `limits.yaml` shows as an unstaged modification, and `README.md` is as before. No file content changes: `limits.yaml` still says 30. Nothing is staged.

Award 2 for the output (1 if `burst.yaml` is predicted as still staged), 1 for "the index is reset as a whole, the working tree is not touched".

*Reference:* Chapter 11, section 11.4.

### 6.7

<!-- snippet: final/s06/p2-answer-a -->
```text
$ cat retry.yaml
attempts: 2
$ git status --short
M  retry.yaml
```
<!-- /snippet -->

(a) `git restore <path>` without `--source` copies from the index. The index holds 2, so the file becomes 2 and the staged change stays staged.

<!-- snippet: final/s06/p2-answer-b -->
```text
$ cat retry.yaml
attempts: 1
$ git status --short
```
<!-- /snippet -->

(b) With `--source=HEAD --staged --worktree` both the index entry and the file are taken from the commit: 1, and a clean status. The value 3 was only ever in the working tree and was overwritten by the first restore: it is gone. The value 2 was staged, so a blob for it exists and is now named by nothing (a dangling blob).

Award 1 for (a), 1 for (b), 1 for the fate of 2 and 3.

*Reference:* Chapter 11, section 11.3; Chapter 4, section 4.7; Chapter 13, section 13.9.

### 6.8

<!-- snippet: final/s06/p3-answer -->
```text
$ git clean -n
Would remove notes.txt
$ git clean -n -d
Would remove notes.txt
Would remove scratch/
$ git clean -n -d -x
Would remove model.ckpt
Would remove notes.txt
Would remove scratch/
$ git clean -n -d -X
Would remove model.ckpt
```
<!-- /snippet -->

Without `-d`, untracked directories are left alone. `-x` adds what the ignore rules protect; `-X` (capital) removes only ignored files, which is the "delete build products, keep my new files" form. `.gitignore` itself is tracked and never listed.

Award 2 for the four lists, 1 for the distinction between `-x` and `-X`.

*Reference:* Chapter 4, section 4.14; Chapter 11, section 11.10.

### 6.9

<!-- snippet: final/s06/g1-answer -->
```text
$ git log --graph --oneline
*   2072fae M2: merge feature/spellcheck again
|\  
| * 731de3a C: read corrections from a file
* | 8b55878 Revert "M1: merge feature/spellcheck"
* | c072596 M1: merge feature/spellcheck
|\| 
| * 60bf90d B: add spelling correction
|/  
* 1426d42 A: add the answer endpoint
$ git ls-files
app.py
corrections.txt
$ git merge-base HEAD~1 feature/spellcheck | xargs git log -1 --format=%s
B: add spelling correction
```
<!-- /snippet -->

```text
        B-----------------C        feature/spellcheck
       /                 \ \
  A---+------------M1--R--M2       main   (HEAD)
                  /
       (B is the second parent of M1)
```

`app.py` and `corrections.txt` exist on `main`; `spell.py` does not. The merge base of the second merge is B, the old tip of the branch: since B, the branch added only `corrections.txt`, and `main` deleted `spell.py` through the revert R. Nothing opposes the deletion, so it stands, and `main` now has a corrections file for code that is not there. To land the feature: `git revert R` first, then merge.

Award 2 for the graph, 1 for the files and the merge base.

*Reference:* Chapter 11, section 11.9.

### 6.10

(a) Applying a stash is a three-way merge: the base is the commit the stash was made on, one side is the current working tree, the other is the stashed state. The same line changed on both sides since the base. (b) "Updated upstream" is the current HEAD and working tree (the committed 4); "Stashed changes" is the stash (5). (c) `pop` is `apply` followed by `drop`, and the drop happens only after a clean apply. After a conflict the entry stays in the list so that the stashed state is not lost if the resolution goes wrong. (d) Edit the file to `retries: 5` and remove the markers (or `git checkout --theirs delivery.yaml`), then `git restore --staged delivery.yaml` if you do not want it staged, check with `git diff`, and `git stash drop` when the result is right.

*Reference:* Chapter 11, section 11.11; Chapter 14C, section 14C.2.

### 6.11

State: the path exists in HEAD and has no entry in the index. `git status --short` showed two lines for it: `D ` (the next commit deletes it) and `??` (the file on disk is untracked). The commit recorded the deletion; a pull then removed the file from every colleague's working tree.

Root cause (Git, misuse of a command): `git rm --cached` removes the index entry. It exists to stop tracking a file. To unstage a change you restore the entry from HEAD.

Repair, published: add a commit that brings the file back, `git restore --source=<commit before the deletion> --staged --worktree fixtures/large_sample.json`, commit, push. No rewrite. He should have used `git restore --staged fixtures/large_sample.json`. Habit: read `D ` in the first column as "the next commit deletes this".

*Reference:* Chapter 5, section 5.9.

### 6.12

A squash merge makes the whole pull request one commit, so the unit of undo is the whole pull request: `git revert` applies the inverse of everything it changed.

Without rewriting `main`: (1) `git revert <the revert commit>` to bring everything back, then a new commit that sets `max_batch` to the old default; or (2) leave the revert, apply the squash commit again without committing (`git cherry-pick -n <squash commit>`), restore the old default in the file, and commit the result as a new commit. Both add commits only. Verify with `git diff <squash commit> HEAD`: the only difference must be the default.

Implication: under squash merging a pull request is the smallest thing you can undo, find with bisect, or backport. An unrelated default belongs in its own pull request.

*Reference:* Chapter 27, section 27.19; Chapter 17, section 17.9; Chapter 11, section 11.8.

### 6.13

Model diagnosis and repair, as a replay of the lab. The reflog shows the amend; after a fetch the branches are one ahead and two behind.

<!-- snippet: final/solve-undo/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git reflog -3
f5a148a HEAD@{0}: commit (amend): Add a toll penalty
f776402 HEAD@{1}: commit: Add a toll penalty
542f5ef HEAD@{2}: commit (initial): Add route weights
$ git fetch
From ../server
   f776402..2b6922d  main       -> origin/main
$ git status -sb
## main...origin/main [ahead 1, behind 2]
$ git log --oneline --graph --all
* f5a148a Add a toll penalty
| * 2b6922d Add a ferry penalty
| * f776402 Add a toll penalty
|/  
* 542f5ef Add route weights
```
<!-- /snippet -->

The difference between the published commit and the amended one is one line. The second diff shows the trap: the amended tree compared with the server's tip also lacks Asha's line, so any fix that takes whole files from the amended commit (`git reset --soft origin/main` followed by a commit, or `git checkout --theirs` in a conflict) deletes her work.

<!-- snippet: final/solve-undo/02-difference -->
```text
# The published commit against the amended one: this is what has to reach the server.
$ git diff origin/main~1 main
diff --git a/weights.yaml b/weights.yaml
index 38f5d81..58f7dc9 100644
--- a/weights.yaml
+++ b/weights.yaml
@@ -1,4 +1,4 @@
 highway: 1.0
-tool: 1.5
+toll: 1.5
 arterial: 1.2
 local: 1.4
# The shortcut that would lose work: the amended tree against the server tip.
$ git diff main origin/main -- weights.yaml
diff --git a/weights.yaml b/weights.yaml
index 58f7dc9..c7b10d1 100644
--- a/weights.yaml
+++ b/weights.yaml
@@ -1,4 +1,5 @@
 highway: 1.0
-toll: 1.5
+tool: 1.5
 arterial: 1.2
 local: 1.4
+ferry: 3.0
```
<!-- /snippet -->

<!-- snippet: final/solve-undo/03-repair -->
```text
$ git branch rescue/amended
$ git reset --keep origin/main
$ git diff origin/main~1 rescue/amended | git apply
$ git diff
diff --git a/weights.yaml b/weights.yaml
index c7b10d1..3b847dc 100644
--- a/weights.yaml
+++ b/weights.yaml
@@ -1,5 +1,5 @@
 highway: 1.0
-tool: 1.5
+toll: 1.5
 arterial: 1.2
 local: 1.4
 ferry: 3.0
$ git commit -q -a -m "Correct the name of the toll weight"
$ git push
To ../server.git
   2b6922d..09ad84b  main -> main
```
<!-- /snippet -->

<!-- snippet: final/solve-undo/04-verify -->
```text
$ git log --oneline --graph --all
* 09ad84b Correct the name of the toll weight
* 2b6922d Add a ferry penalty
* f776402 Add a toll penalty
| * f5a148a Add a toll penalty
|/  
* 542f5ef Add route weights
$ cat weights.yaml
highway: 1.0
toll: 1.5
arterial: 1.2
local: 1.4
ferry: 3.0
$ git branch -D rescue/amended
Deleted branch rescue/amended (was f5a148a).
$ cd ..
$ assessments/gen/final-undo/check.sh
Checking final-test lab undo
  ok    exactly one new commit sits on top of Asha's commit on the server
  ok    weights.yaml on the server has the corrected key and the ferry penalty
  ok    the new commit changes weights.yaml and nothing else
  ok    your main equals main on the server
  ok    your origin/main equals main on the server
  ok    nothing is staged, modified or untracked in your clone
  ok    no operation is left in progress
PASS: the end state of undo is right.
[exit status: 0]
```
<!-- /snippet -->

Also accepted, because the check verifies the end state: `git pull --rebase` (or `git rebase origin/main`), which stops with a conflict on the key line; resolving it by editing the line to `toll: 1.5` and continuing produces one commit with the same content.

Hand-in (4 points): 2 for the reasoning about `git pull` (a merge pull would publish a merge of two versions of the same commit, with the original and the amended commit both in history and a conflict to resolve; it was not chosen because one clean commit says what happened), 2 for naming the shortcut that loses Asha's line and why (whole-file content from the amended commit, which was made before her change).

*Reference:* Chapter 6, section 6.7; Chapter 11, sections 11.6, 11.7 and 11.13; Chapter 12, section 12.7.

### 6.14

Model answer. `git reset --hard <commit>` does three things: it moves the current branch ref to `<commit>`, makes the index equal to that commit's tree, and overwrites the working tree files to match. It deletes no object. The commits that are no longer on the branch are still in the object database and are named by the reflog of HEAD and of the branch, by default for 30 days once the branch no longer reaches them, and after that until a collection prunes them; a branch placed on the old tip brings them back unchanged. Staged content that was never committed survives as blobs without names, found with `git fsck --lost-found`. What is destroyed for good is content that was never an object: edits to tracked files that were saved and not staged. Untracked files are left alone unless the target commit tracks a file at the same path.

Listen for: three places, "moves a ref, deletes no object", the reflog with its retention, and the unstaged edit as the real loss.

*Reference:* Chapter 11, sections 11.4 and 11.5; Chapter 13, sections 13.2 and 13.12.

---

## Section 7: Recovery

### 7.1

**Answer: B.** One reflog per ref with logging enabled, plus one for HEAD, each worktree with its own HEAD log; local, never transferred; a bare repository does not log unless `core.logAllRefUpdates` is set. A and C are the "the reflog will always save me, even on the server" model.

*Reference:* Chapter 13, section 13.3; Chapter 12, section 12.3.

### 7.2

**Answer: C.** `gc.reflogExpireUnreachable` is 30 days (90 for entries the tip still reaches); once the entry is gone the object is unreachable, and `gc.pruneExpire` is two weeks measured from when the object was written. The lab configuration sets both reflog periods to "never"; the question asks for Git's defaults.

*Reference:* Chapter 13, section 13.4.

### 7.3

**Answer: D.** `ORIG_HEAD` is written by `git am`, `git merge`, `git rebase` and `git reset` (and through them by `git pull` and `git stash push`). A cherry-pick moves HEAD "in an ordinary way" and leaves the slot with whatever an earlier command put there, on whatever branch that was.

*Reference:* Chapter 13, section 13.5.

### 7.4

**Answer: A.** The stash is one ref plus its reflog: `stash@{1}` is reflog syntax. Expiring that reflog leaves the newest entry (held by the ref) and turns the older ones into dangling commits.

*Reference:* Chapter 13, section 13.4; Chapter 14C, section 14C.2.

### 7.5

**Answer: D.** A bare repository keeps no reflog by default, and a fresh clone receives only what the server's refs reach, so `fsck` there finds nothing. Other clones are the fourth layer of protection: the pusher still has the commits on a branch or in a reflog, and anyone who fetched has "update by push" or "fetch" lines in the reflog of the remote-tracking branch. On GitHub there are also platform records (Activity view, Events API).

*Reference:* Chapter 13, sections 13.2, 13.10 and 13.15.

### 7.6

<!-- snippet: final/s07/p1-answer -->
```text
$ git reflog show spike/priority
fatal: ambiguous argument 'spike/priority': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog
87064b3 HEAD@{0}: checkout: moving from spike/priority to main
d9fb286 HEAD@{1}: commit: Try a priority heap
87064b3 HEAD@{2}: checkout: moving from main to spike/priority
87064b3 HEAD@{3}: commit (initial): Add the queue
$ git log -1 --format=%s 'HEAD@{1}'
Try a priority heap
$ git branch --contains "HEAD@{1}"
```
<!-- /snippet -->

The branch's reflog was deleted with the branch, so Git no longer knows the name. The reflog of HEAD is independent: four lines, and `HEAD@{1}` ("commit: Try a priority heap") still names the commit. No branch contains it, so the last command prints nothing. `git branch spike/priority "HEAD@{1}"` would restore the branch, with a new, empty reflog.

Award 2 for the outputs, 1 for "a branch reflog dies with the branch; the HEAD reflog does not".

*Reference:* Chapter 13, sections 13.3 and 13.8.

### 7.7

<!-- snippet: final/s07/p2-answer -->
```text
$ git cat-file -t $x
fatal: git cat-file: could not get object info
[exit status: 128]
$ git cat-file -t $y
commit
[exit status: 0]
$ git cat-file -t $z1
fatal: git cat-file: could not get object info
[exit status: 128]
$ git cat-file -t $z2
commit
[exit status: 0]
$ git stash list
$ git log --format=%s -1 refs/stash
On main: newer idea
```
<!-- /snippet -->

After the expiry no reflog names anything. `$x` was held only by reflog entries: pruned. `$y` is named by the tag `keep/y`: kept. `$z1`, the older stash entry, was held only by a line in the reflog of `refs/stash`: pruned. `$z2` is the value of `refs/stash` itself: kept. `git stash list` prints the reflog of `refs/stash`, which is empty, so it prints nothing although the newest stash still exists and `git stash pop` would restore it.

Award 2 for the five predictions (1 with one wrong), 1 for the reasons.

*Reference:* Chapter 13, sections 13.4 and 13.13.

### 7.8

<!-- snippet: final/s07/g1-answer -->
```text
$ git log -1 --format=%s 'main@{4}'
Add batching
$ git log --format=%s 'main@{3}..main@{4}'
Add batching
Add the tokenizer
$ git log -1 --format=%s 'main@{2}'
Add the streaming loader
$ git log --format=%s 'main@{2}..main@{1}'
Seed the shuffle buffer
Add a shuffle buffer
$ git merge-base --is-ancestor 'main@{1}' main; echo "exit status $?"
exit status 1
$ git log --graph --oneline main "main@{1}" "main@{4}"
* 9e3cc94 Seed the shuffle buffer from the run configuration
| * 8f2a574 Seed the shuffle buffer
|/  
* 01957d7 Add a shuffle buffer
* ef0fc67 Add the streaming loader
| * 6faaffb Add batching
| * 950a556 Add the tokenizer
|/  
* ce2a58a Add the loader
```
<!-- /snippet -->

1. See the graph in the transcript: two commits hang off "Add the loader" and are on no branch; the amended commit and the commit it replaced share the parent "Add a shuffle buffer".
2. `main@{4}` ("Add batching"). The reset removed "Add the tokenizer" and "Add batching" (`main@{3}..main@{4}`).
3. `main@{2}` ("Add the streaming loader"). The fast-forward brought two commits.
4. No. `main@{1}` is the commit that `--amend` replaced: it has the same parent as the current tip and is on no branch.

Award 1 for the graph, 1 for parts 2 and 3, 1 for part 4.

*Reference:* Chapter 13, section 13.3; Chapter 6, section 6.7.

### 7.9

(a) The server's branch moved to a commit that is not a descendant of the one your clone knew; `+` marks a non-fast-forward update of the remote-tracking ref, which the default refspec allows. (b) Bottom line: your push yesterday set `origin/feature/quotas` to your commit. Top line: this fetch replaced it. Entry `@{1}` is the proof of what the server had. (c) Removed: "Count quotas per API key" (`<`, only on the old side). Added: "Add a quota window" (`>`). The first commit of the branch is common to both. (d) Before integrating anything, anchor your commit (`git branch rescue/quotas feature/quotas`), find out who rewrote the branch and why, then put your commit on top of the new tip with `git cherry-pick` or `git rebase --onto origin/feature/quotas <old base>`. `git pull --rebase` is the form that loses it silently: your commit was once the tip of the remote-tracking ref, so the fork-point logic treats it as dropped by upstream and replays nothing.

*Reference:* Chapter 13, section 13.10; Chapter 12, section 12.8; Chapter 9, section 9.17.

### 7.10

(a) By default `git fsck` treats reflog entries as roots; the pre-rebase commits are in the reflogs of HEAD and of the branch, so everything is reachable. (b) `--no-reflogs` ignores those roots and shows what would be unreachable if the reflogs were gone. (c) Unreachable: the two old commits and their two trees. Dangling means unreachable and also not referred to by any other unreachable object. The older commit is the parent of the newer one, and the trees are named by the commits, so only the old tip is dangling. (d) A dangling commit is the tip of a lost line of work: inspect it with `git log <id>`, then `git branch <name> <id>`. One name on the tip makes the whole chain reachable again.

*Reference:* Chapter 3, section 3.8; Chapter 13, section 13.6.

### 7.11

The merge was a fast-forward: `release/3.2` moved along three commits and no merge commit exists. `HEAD~1` is the first parent of the tip, which after a fast-forward is the second-to-last commit of the branch that was merged, not the previous tip of `release/3.2`. The recipe silently assumes a merge commit.

Correct: right away, `git reset --keep ORIG_HEAD` (the merge wrote `ORIG_HEAD`; but his first reset overwrote it with the three-commit state, so in his situation this no longer points where he needs). The way that works now and tomorrow: `git reflog show release/3.2`, find the line "merge hotfix/cache-key: Fast-forward", and reset to the entry below it: `git reset --keep 'release/3.2@{2}'` in his case (the entry below the merge line, counted after his own reset). Rule: undo a merge with `ORIG_HEAD` at once or by reflog entry, never by counting parents.

*Reference:* Chapter 13, sections 13.5 and 13.8; Chapter 8, section 8.3.

### 7.12

It cannot be recovered with Git. Layer 1 (refs), layer 2 (reflogs) and layer 3 (unreachable objects inside the grace period) all lived in the `.git` directory he deleted; the new clone has its own, empty reflog and only the objects the server's refs reach. Layer 4 (another repository) never existed because the branch was never pushed. Say "it is gone, and here is why" and do not run recovery commands for show.

Worth five minutes outside Git: the system trash or a Time Machine or other file-system backup of the old directory (the whole `.git` can be restored), editor local history, a colleague's clone if he ever fetched from this machine, CI logs or artifacts if the branch was ever built, and terminal scrollback for diffs. Habit: push work in progress to a personal branch at the end of each day; a push is the one protection that survives the loss of the machine.

*Reference:* Chapter 13, sections 13.2 and 13.12.

### 7.13

Model solution, as a replay of the lab. The reflogs are empty, so the search goes through the object database.

<!-- snippet: final/solve-recovery/01-observe -->
```text
$ cd chunkstore
$ git status -sb
## main
$ git branch -a
* main
$ git stash list
$ git reflog
$ git count-objects | cut -d, -f1
25 objects
```
<!-- /snippet -->

<!-- snippet: final/solve-recovery/02-search -->
```text
$ git fsck --dangling
dangling commit 05bb978737f8ca8a8f664268f4a4a9c8a1c979dc
dangling commit f84267198d4ddd3bd793fe9674a769ec8182b9ec
# Two dangling commits. One line each: parents and subject.
$ git log -1 --format='%h parents: %p%n  %s' 05bb978
05bb978 parents: 619e74a
  Reject a negative sentence overlap
$ git log -1 --format='%h parents: %p%n  %s' f842671
f842671 parents: 0f4b8e7 9b0d8d2
  On main: overlap 128 with a minimum chunk
```
<!-- /snippet -->

The two are told apart by shape: a stash entry is a commit with two parents (the commit it was made on, and a commit of the index) and a subject that starts with "On main:" or "WIP on"; the branch tip has one parent and an ordinary subject.

<!-- snippet: final/solve-recovery/03-recover -->
```text
$ git log --oneline 05bb978
05bb978 Reject a negative sentence overlap
619e74a Overlap chunks by whole sentences
cd755bc Split text into sentences
0f4b8e7 Add README
850ee82 Add the chunk store
17ee5ed Add the fixed-size chunker
$ git branch spike/semantic-overlap 05bb978
$ git stash apply f842671
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   config/chunking.yaml

no changes added to commit (use "git add" and/or "git commit -a")
$ git diff
diff --git a/config/chunking.yaml b/config/chunking.yaml
index b8ba739..b684df0 100644
--- a/config/chunking.yaml
+++ b/config/chunking.yaml
@@ -1,2 +1,3 @@
 size: 512
-overlap: 64
+overlap: 128
+min_chunk: 32
```
<!-- /snippet -->

<!-- snippet: final/solve-recovery/04-verify -->
```text
$ git log --oneline --graph --all
* 05bb978 Reject a negative sentence overlap
* 619e74a Overlap chunks by whole sentences
* cd755bc Split text into sentences
* 0f4b8e7 Add README
* 850ee82 Add the chunk store
* 17ee5ed Add the fixed-size chunker
$ git status --short
 M config/chunking.yaml
$ git fsck --dangling
dangling commit f84267198d4ddd3bd793fe9674a769ec8182b9ec
$ cd ..
$ assessments/gen/final-recovery/check.sh
Checking final-test lab recovery
  ok    the branch spike/semantic-overlap is back at its last commit, with the original commit ID
  ok    main has not moved
  ok    HEAD is on main
  ok    config/chunking.yaml in the working tree has the stashed edit
  ok    the edit is not staged and nothing else is changed
  ok    no operation is left in progress
PASS: the end state of recovery is right.
[exit status: 0]
```
<!-- /snippet -->

The stash commit is still dangling after `git stash apply <id>`: applying by ID reads the commit and creates no ref. That is fine; the edit is in the working tree.

Hand-in (4 points): 2 for the way the two commits were told apart, 2 for the command that would have ended it: `git gc --prune=now` (or `git prune`), which deletes unreachable objects at once. The Friday script expired the reflogs and stopped one step short of the point of no return.

*Reference:* Chapter 13, sections 13.6, 13.8, 13.9 and 13.13; Chapter 14C, section 14C.2.

### 7.14

Model response.

1. **Stabilise.** Stop the afternoon deployment and stop pushes to `release/4.1` on the mirror. Ask the three engineers not to fetch from or prune against the mirror, and not to run any cleanup, until told otherwise. Disable the housekeeping job.
2. **Preserve.** In each clone, before any fetch: `git branch rescue/release-4.1 origin/release/4.1` and a copy of `git reflog show origin/release/4.1`. A clone is copied whole if in doubt.
3. **Diagnose.** On the mirror the four commits are gone for certain: a bare repository keeps no reflog by default, so after the force push nothing named them, and `git gc --prune=now` deletes unreachable objects without a grace period. (Exception to check: another ref on the mirror, a tag or a branch, that still reaches them: `git branch -a --contains`, `git tag --contains` with a candidate ID.) They survive in clones. The engineer who was on holiday has not fetched since before Friday: his `origin/release/4.1` still names the old tip. The other two have it in the reflog of their remote-tracking ref, below a "forced-update" line, if they fetched in between. Whoever pushed the commits has them on a local branch. Proof of the tip: the candidates from the three clones must agree; cross-check with the last deployment record, a CI run or a release tag.
4. **Recover.** From the clone that has the tip: `git push origin <tip ID>:refs/heads/release/4.1`. The mirror's branch is an older state of the same line, so this is a fast-forward and needs no force. If the mirror has gained commits since Friday, do not force over them: put them on top of the restored tip and push.
5. **Verify.** `git ls-remote origin refs/heads/release/4.1` equals the tip; `git merge-base --is-ancestor <last deployed commit> <tip>`; the diff between the last deployed commit and the tip lists the four commits; a fresh clone builds.
6. **Communicate.** Tell the team to fetch; nobody has to repair a clone, because the branch moved forward again. Summary for the CTO: what happened (a release branch on the deployment mirror lost four commits for three days; nothing was deployed from it), root cause with layer (Git: a forced push was accepted by a server without protection, and a maintenance script then removed the only local copy), what was done and verified, prevention.
7. **Prevent.** On the mirror: `receive.denyNonFastForwards=true` and `receive.denyDeletes=true`; `core.logAllRefUpdates=true` so that the bare repository keeps reflogs; housekeeping with plain `git maintenance run` or `git gc`, never with `--expire=now` or `--prune=now`. Deployments from tags or commit IDs, not from a branch name.

Award as in the marking table. A response that starts with `git fetch --prune` in the clones, or that "re-pushes main to be safe", loses the points for stabilise and preserve.

*Reference:* Chapter 13, sections 13.10, 13.13 and 13.14; Chapter 12, sections 12.3 and 12.8; Chapter 30, sections 30.2 and 30.15.

### 7.15

Model answer. Whenever a ref changes, Git appends the old and the new value, a time and a reason to that ref's log. So after a reset, a rebase, an amend, a bad merge or a deleted branch, the previous tip still has a name (`main@{1}`, `HEAD@{5}`), and being named by a reflog also keeps it from being collected. Recovery is then one command that adds a ref: `git branch rescue <entry>`.

It does not help (1) for work that was never committed or staged, because there was never an object to log; (2) on the server or in a fresh clone, because reflogs are local and a bare repository keeps none by default; (3) for the reflog of a branch that was deleted, which goes with the branch, although the HEAD reflog usually still has the commits; (4) after expiry: 90 days, or 30 for entries the branch no longer reaches, or at once after `git reflog expire --expire=now`. A fifth case worth naming: a clone that was deleted.

Listen for: "a log of ref values, local", the retention numbers, and the "never an object" precondition.

*Reference:* Chapter 13, sections 13.3, 13.4 and 13.12.

---

## Section 8: Remote workflows

### 8.1

**Answer: B.** `refs/remotes/origin/main` is a local ref, moved by fetch and by a successful push. A is the "origin/main is the branch on the server" model; `git status` opens no connection.

*Reference:* Chapter 12, sections 12.2 and 12.4.

### 8.2

**Answer: C.** Pull is fetch plus one integration step, and with diverged branches and neither `pull.rebase` nor `pull.ff` set it refuses and asks you to choose. A is the behavior of older versions and the "pull downloads the latest and merges it" model; D never happens.

*Reference:* Chapter 12, section 12.6.

### 8.3

**Answer: B.** The lease means "the server's ref still equals my remote-tracking ref". A fetch makes them equal again whether or not you looked. The manual calls the forms without an explicit expected value experimental. Use `--force-with-lease=<ref>:<expected>` or add `--force-if-includes`.

*Reference:* Chapter 12, section 12.8.

### 8.4

**Answer: D.** `git push origin main` is a refspec: send my `main` to their `main`. The commit is on `hotfix/timeout`, which has no upstream. A push transfers the refs you name, not "my work". Read the last lines of the push output: source, arrow, destination.

*Reference:* Chapter 12, sections 12.7 and 12.14.

### 8.5

**Answer: A.** The fast-forward rule protects whatever commits are on the server's branch: after the update they must still be reachable from it. Names, dates and the time of the last fetch play no part.

*Reference:* Chapter 12, section 12.7.

### 8.6

<!-- snippet: final/s08/p1-answer -->
```text
$ git push --force-with-lease=feature/cache:$seen origin feature/cache
To ../server.git
 ! [rejected]        feature/cache -> feature/cache (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
$ git push --force-with-lease --force-if-includes origin feature/cache
To ../server.git
 ! [rejected]        feature/cache -> feature/cache (remote ref updated since checkout)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git log --oneline -1 origin/feature/cache
91fccbb Add cache metrics
$ git status -sb
## feature/cache...origin/feature/cache [ahead 1, behind 2]
```
<!-- /snippet -->

First push: rejected with "(stale info)". The explicit value says "overwrite only if the server still has the commit I saw", and the server has Asha's commit. Second push: rejected with "(remote ref updated since checkout)". The bare lease alone would pass, because the background fetch made the remote-tracking ref equal to the server's ref; `--force-if-includes` adds the test that the tip of the remote-tracking ref is in the reflog of the local branch, that is, that you have integrated it. The plain `git push --force-with-lease` would have been accepted and would have removed "Add cache metrics" from the server's branch.

Award 1 per push, 1 for what the plain form would have done.

*Reference:* Chapter 12, section 12.8.

### 8.7

<!-- snippet: final/s08/p2-answer -->
```text
$ git push origin main > ../push.log 2>&1
[exit status: 1]
$ grep -E "refusing|rejected" ../push.log | sed "s/ *$//"
remote: error: refusing to update checked out branch: refs/heads/main
 ! [remote rejected] main -> main (branch is currently checked out)
$ git push -q origin main:refs/heads/incoming
[exit status: 0]
$ git -C ../kiosk branch -v
  incoming 3dea418 Add the idle screen
* main     4ecde27 Add the kiosk page
```
<!-- /snippet -->

The first push is refused by the receiving repository (`receive.denyCurrentBranch`, default refuse): moving the checked-out branch would leave its index and working tree describing an older commit. The second push creates a branch that is not checked out there, which changes no file anybody is looking at, so it is accepted.

Award 2 for the two outcomes, 1 for the reason. This is why a server holds a bare repository.

*Reference:* Chapter 12, section 12.9.

### 8.8

<!-- snippet: final/s08/g1-answer -->
```text
$ git -C server.git for-each-ref --format='%(refname) -> %(subject)' refs/heads
refs/heads/main -> Y1: add health check
$ git -C you for-each-ref --format='%(refname) -> %(subject)' refs/heads refs/remotes/origin/main
refs/heads/main -> Y2: add readiness probe
refs/remotes/origin/main -> Y1: add health check
$ git -C asha for-each-ref --format='%(refname) -> %(subject)' refs/heads refs/remotes/origin/main
refs/heads/main -> A1: add request log
refs/remotes/origin/main -> Y1: add health check
$ git -C you status -sb
## main...origin/main [ahead 1]
$ git -C asha status -sb
## main...origin/main [ahead 1, behind 1]
```
<!-- /snippet -->

```text
  server.git                you                          asha
 +----------------+        +--------------------+       +--------------------+
 | main -> Y1     |        | main        -> Y2  |       | main        -> A1  |
 +----------------+        | origin/main -> Y1  |       | origin/main -> Y1  |
                           +--------------------+       +--------------------+
                            ## main...origin/main        ## main...origin/main
                               [ahead 1]                    [ahead 1, behind 1]
```

Asha's fetch moved her `origin/main` to Y1 and left her `main` where it was; her new commit A1 has the old commit as parent, so she is one ahead and one behind. Your `origin/main` moved to Y1 through your own push.

Award 2 for the five refs, 1 for the two status lines. `main -> Y1` in Asha's box is the "fetch updates my branch" model.

*Reference:* Chapter 12, sections 12.4 and 12.7.

### 8.9

(a) The server has a commit on `main` that your repository does not have at all: your remote-tracking ref is behind, and Git learned of the mismatch only from the server's answer. (b) The fetch brought the commit and moved `origin/main`. Your local `main` did not move. (c) Now your own repository knows that your branch does not contain the tip of its remote counterpart. In both cases the server applied the same rule: its current tip must be an ancestor of what you push. (d) `git pull --rebase` (or `git rebase origin/main`): your commit is recreated on top, linear history, new ID for your commit. `git merge origin/main` (or a merge pull): a merge commit with two parents, your commit keeps its ID. Then push. Not `--force`: it would remove the colleague's commit.

*Reference:* Chapter 12, sections 12.6 and 12.7.

### 8.10

Line by line. `- [deleted] (none) -> origin/feature/c`: the branch no longer exists on the server and `--prune` removed the remote-tracking ref. `main -> origin/main` with two dots: a fast-forward of the remote-tracking ref. `+ ... feature/a (forced update)`: the server's branch was rewritten; three dots and `+` mark a non-fast-forward. `* [new branch] feature/b`: a new remote-tracking ref. `* [new tag] v2.0`: a tag that points into the fetched history was created locally.

`git branch -vv`: `main` is behind 1 (the fetch moved no local branch). `feature/a` is ahead 1, behind 1: your local commit and the rewritten one have a common parent; compare them with `git range-diff` or `git log --left-right feature/a...origin/feature/a` before deciding which to keep. `feature/c` is "gone": its upstream ref was pruned. The local branch and its commit are untouched. Before deleting it, check that the commit is on the server under another name (`git branch -r --contains feature/c`) or in `main`.

Award 2 for the five fetch lines, 2 for the branch lines with the checks.

*Reference:* Chapter 12, sections 12.4, 12.8 and 12.11.

### 8.11

The superproject records one commit ID for the submodule (a gitlink). The pull updated that ID in the index and in HEAD; the submodule's own repository under `vendor/textnorm` still has its HEAD on the old commit. The two IDs in `git diff` are "what the superproject now wants" and "what is checked out". Root cause (Git): two repositories, two HEADs, and no default that moves the second when the first changes.

His `git add -A && git commit` would record the old submodule commit again: a silent rollback of the library for everyone who pulls. Correct: `git submodule update` (then status is clean). Setting: `git config set submodule.recurse true`, or `git pull --recurse-submodules`.

*Reference:* Chapter 23, section 23.7.

### 8.12

The branch was created with a remote-tracking branch as the starting point (`git switch -c feature/batch-window origin/main`), and with `branch.autoSetupMerge=true` that makes `origin/main` the upstream. `git pull` without arguments integrates the upstream: `origin/main` has nothing new. `git push origin feature/batch-window` addresses the server branch of the same name, where a colleague's commit sits. Pull and push address different branches.

Evidence: `git config get branch.feature/batch-window.merge`, `git status -sb`, `git log --oneline --left-right HEAD...origin/feature/batch-window` after a fetch. Fix: `git branch --set-upstream-to=origin/feature/batch-window`, then `git pull --rebase` (or a merge), then push; no force. Prevention: `git switch -c <name> --no-track origin/main`, or branch from the local `main`; read the bracket in `git branch -vv` after creating a branch.

*Reference:* Chapter 29, section 29.4; Chapter 12, section 12.5.

### 8.13

"Gone" means: the branch has an upstream configured, and the remote-tracking ref for it no longer exists in this clone, because the server's branch was deleted and a prune removed the ref. It says nothing about the local branch, whose five commits are intact, and nothing about whether the work was merged.

Checks: `git branch --merged origin/main` (is the tip reachable from `main`?); if the pull request was squash-merged or rebase-merged the tip is not reachable although the content landed, so compare content: `git diff origin/main...<branch>` against what `main` has, or `git merge-tree --write-tree origin/main <branch>` equal to the tree of `origin/main`. Also `git log origin/main..<branch>`: are there commits made after the pull request was merged?

The one-liner destroys work in exactly that last case, and when a branch was deleted on the server by mistake or before it was merged: `-D` skips the reachability test that `-d` exists for. Use `-d` in the one-liner and look at what it refuses.

*Reference:* Chapter 12, section 12.11; Chapter 17, section 17.9; Chapter 27, section 27.3.

### 8.14

Model diagnosis and repair, as a replay of the lab.

<!-- snippet: final/solve-remote/01-observe -->
```text
$ cd you
$ git status -sb
## feature/slot-carryover
$ git branch -vv
* feature/slot-carryover 1a8a375 Do not overwrite a slot with an empty value
  main                   a708020 [origin/main] Add slot lookup
$ git remote -v
origin	../origin.git (fetch)
origin	../origin.git (push)
staging	../staging.git (fetch)
staging	../staging.git (push)
$ git branch -r
  origin/main
  staging/feature/slot-carryover
  staging/main
```
<!-- /snippet -->

The branch has no upstream, and `git branch -r` shows it under `staging/`. The server's own answer and the configuration confirm it:

<!-- snippet: final/solve-remote/02-evidence -->
```text
$ git ls-remote --heads origin
a70802042b2bc064502eedd06fbf0efc4f0ce2db	refs/heads/main
$ git ls-remote --heads staging
1a8a375513cf7dca190d5580a053dab8da62e587	refs/heads/feature/slot-carryover
a70802042b2bc064502eedd06fbf0efc4f0ce2db	refs/heads/main
$ git rev-parse --abbrev-ref 'feature/slot-carryover@{upstream}'
fatal: no upstream configured for branch 'feature/slot-carryover'
[exit status: 128]
$ git rev-parse --abbrev-ref 'feature/slot-carryover@{push}'
fatal: no upstream configured for branch 'feature/slot-carryover'
[exit status: 128]
$ git push --dry-run --verbose
Pushing to ../staging.git
To ../staging.git
 = [up to date]      feature/slot-carryover -> feature/slot-carryover
Everything up-to-date
$ git config get --show-origin --show-scope remote.pushDefault
local	file:.git/config	staging
$ git config get --default "simple (the built-in default)" push.default
simple (the built-in default)
```
<!-- /snippet -->

`remote.pushDefault=staging` in `.git/config` sends every bare `git push` to `staging`. With `push.default=simple` and a push remote that differs from the remote you pull from, Git pushes the current branch to a branch of the same name, so the first push created the branch there and said nothing about an upstream. `@{push}` cannot be resolved for a branch without an upstream, which is why the verbose dry run is the command that shows the destination.

<!-- snippet: final/solve-remote/03-repair -->
```text
$ git config unset remote.pushDefault
$ git push -u origin feature/slot-carryover
To ../origin.git
 * [new branch]      feature/slot-carryover -> feature/slot-carryover
branch 'feature/slot-carryover' set up to track 'origin/feature/slot-carryover'.
$ git push staging --delete feature/slot-carryover
To ../staging.git
 - [deleted]         feature/slot-carryover
```
<!-- /snippet -->

<!-- snippet: final/solve-remote/04-verify -->
```text
$ git branch -vv
* feature/slot-carryover 1a8a375 [origin/feature/slot-carryover] Do not overwrite a slot with an empty value
  main                   a708020 [origin/main] Add slot lookup
$ git rev-parse --abbrev-ref 'feature/slot-carryover@{push}'
origin/feature/slot-carryover
$ git ls-remote --heads origin
1a8a375513cf7dca190d5580a053dab8da62e587	refs/heads/feature/slot-carryover
a70802042b2bc064502eedd06fbf0efc4f0ce2db	refs/heads/main
$ git ls-remote --heads staging
a70802042b2bc064502eedd06fbf0efc4f0ce2db	refs/heads/main
$ git -C ../asha fetch
From ../origin
 * [new branch]      feature/slot-carryover -> origin/feature/slot-carryover
$ cd ..
$ assessments/gen/final-remote/check.sh
Checking final-test lab remote
  ok    the team's repository has feature/slot-carryover with your two commits
  ok    your local branch still has the same two commits
  ok    the upstream of feature/slot-carryover is origin/feature/slot-carryover
  ok    a bare git push on feature/slot-carryover now goes to origin/feature/slot-carryover
  ok    staging no longer has the branch feature/slot-carryover
  ok    main on staging has not moved
  ok    main on the team's repository has not moved
  ok    remote.pushDefault no longer sends pushes to staging
  ok    the remote "staging" is still configured (the demo environment needs it)
PASS: the end state of remote is right.
[exit status: 0]
```
<!-- /snippet -->

Hand-in (4 points): 2 for the three settings in order: `branch.<name>.pushRemote`, then `remote.pushDefault`, then `branch.<name>.remote` (falling back to `origin`); 2 for a command that shows the destination without pushing: `git push --dry-run --verbose`, or `git rev-parse --abbrev-ref @{push}` once an upstream exists. Setting `remote.pushDefault` to `origin` instead of removing it passes the check.

*Reference:* Chapter 12, sections 12.5, 12.7 and 12.10; Chapter 29, section 29.5.

### 8.15

Model answer. A plain `--force` says "replace the server's branch with mine, whatever is there". If a colleague pushed in the meantime, their commit is removed from the branch and nobody is told. `--force-with-lease` adds a condition: replace only if the server's ref still has the value I expect. That turns the silent overwrite into a rejection.

The hole: in the bare form the expected value is my remote-tracking ref, and that is updated by any fetch, including background fetches of an editor. After such a fetch the condition is true although I never looked at the new commit. Two repairs: give the value explicitly (`--force-with-lease=<branch>:<commit I based my rewrite on>`), or add `--force-if-includes` (or set `push.useForceIfIncludes=true`), which also requires that the remote tip is in the reflog of my local branch.

What I require of a team: rewrite only branches that one person pushes to; never the default or release branches, enforced on the server by a rule that blocks force pushes; always lease plus if-includes, set in the shared configuration; after any "(forced update)" in a fetch, look before integrating; and announce a rewrite of a branch that someone else has fetched.

Listen for: what plain force destroys, the remote-tracking ref as the weak point, the two repairs, and a server-side rule.

*Reference:* Chapter 12, section 12.8; Chapter 9, section 9.17; Chapter 18, section 18.11.

---

## Section 9: GitHub

> **GitHub, not Git.** The answers of sections 9 to 12 are taken from the textbook chapters, which describe the platform from its documentation and link each page. Nothing here was run against GitHub.

### 9.1

**Answer: A.** The base permission applies to every member on every repository of the organization; grants only add, and the highest grant wins. B, C and D are inventions; D ignores that the base permission can be set to none.

*Reference:* Chapter 15, section 15.4.

### 9.2

**Answer: B.** Repositories in a fork network share Git data, and commits can remain accessible through other repositories of the network after a fork is deleted. A is the "a fork is an independent copy" model. The credential is leaked: rotate it.

*Reference:* Chapter 15, section 15.7; Chapter 21B, section 21B.10.

### 9.3

**Answer: D.** A release is a GitHub object attached to a Git tag. When the tag does not exist, the platform creates it at the tip of the target branch, as a lightweight tag. `git describe` uses annotated tags unless `--tags` is given. Create and push the annotated tag first, and create the release with `--verify-tag`.

*Reference:* Chapter 15, section 15.12; Chapter 14B, section 14B.12.

### 9.4

**Answer: C.** GitHub answers "not found" for private resources that the authenticated identity cannot access. It is an identity problem: the wrong account's credential answered, a fine-grained token does not include the repository, the credential is not authorized for the organization's single sign-on, or access was never granted. Find out who the server thinks you are (`gh auth status`, `ssh -T git@github.com`).

*Reference:* Chapter 16, section 16.19.

### 9.5

**Answer: D.** Authentication decides whether the push is accepted. Attribution is by the author email inside each commit object, which Git takes from `user.email` and which anyone can set. Diagnose with `git config get --show-origin user.email`; prevent with a conditional include per directory.

*Reference:* Chapter 16, sections 16.2 and 16.13; Chapter 14B, section 14B.4.

### 9.6

**Answer: A.** In a pull request description the nine closing keywords are interpreted only when the pull request targets the default branch; `Fixes` is one of the nine. In a commit message the issue closes when the commit reaches the default branch.

*Reference:* Chapter 15, section 15.8.

### 9.7

Mechanism: Git asks its credential helpers before it prompts. A stored credential for another account (here the private one, in the macOS keychain) answers. The server authenticates it and refuses the action with 403. Git erases a stored credential only when it is rejected outright (401); a 403 is "known account, not allowed", so nothing is erased and every later push sends the same credential. `gh` has its own token and is not involved.

Read-only evidence: `git config get --show-origin --all credential.helper` and `git config get --show-origin --all credential.https://github.com.helper` (which program answers, and from which file); `git remote -v` (HTTPS, and no user in the URL). Fix: remove the stale keychain entry for the host, or let `gh` supply Git's credential with `gh auth setup-git`. Prevention with two accounts: one helper per host set on purpose, and for the second account an SSH host alias with its own key and `IdentitiesOnly yes`.

*Reference:* Chapter 16, sections 16.4, 16.5, 16.13 and 16.19.

### 9.8

In the terminal `ssh` reaches the agent through `SSH_AUTH_SOCK`, and the agent holds the unlocked key. `cron` starts the job without that variable, so `ssh` has no key to offer and the server refuses. Proof: run `ssh-add -l` inside the job (status 2: no agent), or `ssh -vT git@github.com` there and read which identities are offered.

`sudo` changes the user and the environment and has the same problem, and Git run as root leaves root-owned files in the repository. Copying a personal private key into a job puts a person's full access, without a passphrase, where a script can read it. The job should have its own identity: a read-only deploy key for that one repository, or a GitHub App installation token, so that its access is scoped, visible in an inventory, and independent of the person.

*Reference:* Chapter 16, sections 16.9, 16.14 and 16.18.

### 9.9

The REST API returns list results in pages, and `gh api` requests one page unless told otherwise; the default page holds 30 items. Corrected: `gh api --paginate repos/OWNER/REPO/pulls --jq '.[].number' | wc -l`. Counting lines avoids depending on how `--jq` treats several pages. Or ask the higher-level command: `gh pr list --state open --limit 1000 --json number --jq length`.

> **Unverified.** Whether `--jq 'length'` together with `--paginate` prints one number per page or one total was not run here (`gh` is used only with `--help` in this course); the line-count form does not depend on it.

Second trap: adding a field with `-f` or `-F` switches the request method from GET to POST, so a call that was meant to filter a list can create something. Give the method explicitly with `-X GET` in scripts.

*Reference:* Chapter 15, sections 15.16, 15.17 and 15.20.

### 9.10

Model response.

1. **Stabilise.** Treat it as a live credential in unknown hands (SEV 1 until shown otherwise). Revoke first, investigate second: remove every deploy key on the two repositories that he added or that nobody can account for, revoke personal access tokens and OAuth and app authorizations of his account that the organization can revoke, and suspend the mirror job.
2. **Preserve.** Export the audit log entries and the list of deploy keys and installed apps before deleting anything further; record the current tips of all branches and tags of both repositories (`git ls-remote`), and fetch them into a clone that nobody force-pushes into.
3. **Diagnose.** Removing a person from an organization ends membership. It does not end credentials that are attached to something else: deploy keys (attached to a repository, no expiry), tokens of a machine user, an app installation, a personal token of another account, webhooks with secrets, self-hosted runners, and secrets that he could read. Find them: `gh repo deploy-key list` per repository, the organization's lists of fine-grained tokens and of installed apps, the audit log for the Monday clone. Establish which credential the mirror job uses and which credential made the Monday clone.
4. **Recover.** Assume everything the surviving credential could read is disclosed and everything it could write may be changed: compare every ref with the recorded values and with a trusted clone, look for new workflow files, deploy keys and webhooks, and rotate every secret the repositories' workflows can read. Re-create the mirror job with its own identity.
5. **Verify.** No deploy key, token or app remains that cannot be mapped to an owner and a purpose; the mirror job runs with the new identity; refs equal the trusted values.
6. **Communicate.** Four parts for the CTO; the unknown address and what it could read are stated plainly, including what is not yet known.
7. **Prevent.** Machines get machine identities: GitHub App installation tokens (one hour) or per-repository read-only deploy keys, recorded in an inventory with an owner; an offboarding checklist that lists credentials, not only membership; alerts on new deploy keys.

*Reference:* Chapter 15, sections 15.4 and 15.20; Chapter 16, section 16.14; Chapter 21B, sections 21B.8 and 21B.14; Chapter 30, sections 30.2 and 30.3.

### 9.11

Model answer. Authentication: which account the connection belongs to. Decided by the transport: over HTTPS by the token a credential helper supplies, over SSH by the key that `ssh` offers. Typical failure: the wrong account's stored credential or key answers ("Repository not found", or a 403 that never prompts). Authorization: what that account may do to this repository. Decided on GitHub by roles, the base permission, token permissions, single sign-on authorization and rules. Typical failure: a fine-grained token that does not include the repository, or a push refused by a ruleset although the login works. Commit identity: the author and committer name and email written into the commit object from `user.name` and `user.email` on the machine. Git checks neither; GitHub attributes by email. Typical failure: commits under a private address on a work repository, or a commit that carries a colleague's name. The three are independent: a push authenticated as one person can carry commits that name another.

Listen for: transport versus platform versus commit object, and one concrete failure each.

*Reference:* Chapter 16, sections 16.2 and 16.13; Chapter 21B, section 21B.5.

### 9.12

Model answer. What arrives is Git data: every commit, tree, blob and tag object, and the refs (branches, tags, notes). What does not arrive, because it was never in the repository: pull requests with their reviews, review threads and approvals; issues, labels, milestones, projects, discussions; releases as objects, with their notes and uploaded assets (the tags arrive); rulesets, branch protection, CODEOWNERS enforcement (the file arrives, the rule that requires it does not); Actions secrets, variables, environments and run history (the workflow files arrive); webhooks, deploy keys, app installations; the wiki, which is its own repository; and Git LFS content, which lives in a separate store and has to be fetched and pushed with the LFS client. The hidden pull request refs are Git data on the old host and are usually refused by the new one.

Export first: the review record (who approved what, for which commit), because it is the audit trail and cannot be reconstructed from commits; then the rules, because the first day without them is the day somebody force-pushes; then the secrets inventory, which cannot be exported at all and has to be re-created.

Listen for: "Git data versus platform objects", LFS as a separate store, and a reasoned priority.

*Reference:* Chapter 15, sections 15.2 and 15.12; Chapter 17, section 17.2; Chapter 22, section 22.6.

---

## Section 10: Pull requests

### 10.1

**Answer: A.** The file view is the three-dot comparison: what the head changed since the merge base. The commit list is `base..head`. The two can disagree, which is why one reviewer sees a broken pull request and another an unchanged one.

*Reference:* Chapter 17, section 17.3; Chapter 14A, section 14A.2.

### 10.2

**Answer: C.** `refs/pull/<n>/head` in the base repository, read-only for you, and "when possible" `refs/pull/<n>/merge` with a test merge commit. No branch moves. D is the "a pull request is a Git feature / has nothing to do with Git" confusion in its other direction.

*Reference:* Chapter 17, section 17.2.

### 10.3

**Answer: C.** Review outcomes are advisory until a ruleset or a classic rule requires a pull request with approvals. The same holds for CODEOWNERS.

*Reference:* Chapter 17, section 17.4; Chapter 18, section 18.7; Chapter 19, section 19.6.

### 10.4

**Answer: D.** GitHub records the state of the diff at approval. The diff can change without a push to the head: "Update branch", or new changes in the merge base because another pull request was merged. The setting then dismisses the approval.

*Reference:* Chapter 17, section 17.5.

### 10.5

**Answer: C.** "Rebase and merge" always creates new commits with updated committer information, and they are added without signature verification, because GitHub does not have the committers' keys. A describes a fast-forward that GitHub does not offer as a button; B is the squash method; D the merge-commit method (signed by GitHub, not by the person).

*Reference:* Chapter 17, section 17.8; Chapter 18, section 18.10.

### 10.6

<!-- snippet: final/s10/p1-answer -->
```text
$ git diff --stat main..feature/vat-id
 README.md   | 2 --
 audit.yaml  | 1 -
 vat_id.yaml | 1 +
 3 files changed, 1 insertion(+), 3 deletions(-)
$ git diff --stat main...feature/vat-id
 vat_id.yaml | 1 +
 1 file changed, 1 insertion(+)
$ git log --oneline main..feature/vat-id
aeb819c Validate VAT IDs
```
<!-- /snippet -->

Two dots compares the two tips: everything `main` gained after the fork is absent from the feature's tree and prints as deleted (`audit.yaml`, the README lines), mixed with the feature's own file. Three dots compares the merge base with the feature tip: only `vat_id.yaml`. A pull request shows the three-dot form. A reviewer who runs the two-dot form locally "sees" the branch deleting the audit settings, which it never touched.

Award 2 for the two file lists, 1 for the explanation.

*Reference:* Chapter 14A, section 14A.2; Chapter 17, section 17.3.

### 10.7

<!-- snippet: final/s10/g1-answer -->
```text
$ git switch -q main-merge && git merge -q --no-ff -m "Merge pull request #7" feature/cache
$ git switch -q main-squash && git merge -q --squash feature/cache && git commit -q --allow-empty -m "Add a result cache (#7)"
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git switch -q main-rebase && git cherry-pick --allow-empty main..feature/cache > /dev/null
$ git log --graph --oneline main-merge
*   9d6a4a9 Merge pull request #7
|\  
| * 5ce32da Y: expire cache entries
| * 33f9de0 X: add a result cache
* | f278164 N: add rate limiting
|/  
* 13d8a44 A: add the geocoder
$ git log --graph --oneline main-squash
* 4f1e3ac Add a result cache (#7)
* f278164 N: add rate limiting
* 13d8a44 A: add the geocoder
$ git log --graph --oneline main-rebase
* 55af11c Y: expire cache entries
* e878691 X: add a result cache
* f278164 N: add rate limiting
* 13d8a44 A: add the geocoder
$ git branch --merged main-merge --list "feature/*"
  feature/cache
$ git branch --merged main-squash --list "feature/*"
$ git branch --merged main-rebase --list "feature/*"
```
<!-- /snippet -->

```text
  merge commit:   A---N-------M        squash:   A---N---S        rebase:   A---N---X'---Y'
                   \         /
                    X---Y---'
```

Only the merge commit makes X and Y ancestors of the base, so only `main-merge` lists `feature/cache` as merged. S is one new commit with one parent and the combined content. X' and Y' are new commits with new IDs. On GitHub the committer of M, S, X' and Y' is GitHub, and X' and Y' are unsigned; the local commands here stand in for the buttons.

Award 2 for the three graphs, 1 for the three answers about `--merged`.

*Reference:* Chapter 17, sections 17.8 and 17.9; Chapter 8, section 8.12.

### 10.8

<!-- snippet: final/s10/g2-answer -->
```text
$ git merge-base main feature/paging | xargs git log -1 --format=%s
Add alert channels
$ git log --oneline main..feature/paging
b02adf2 Escalate after fifteen minutes
a9fab03 Add the on-call rota
de00c20 Add the pager channel
$ git rebase -q --onto main feature/paging~1 feature/paging
$ git log --oneline main..feature/paging
aac9540 Escalate after fifteen minutes
$ git log --graph --oneline --all --decorate
* aac9540 (HEAD -> feature/paging) Escalate after fifteen minutes
* 6591eca (main) Add paging (#31)
* 4068c4f Add quiet hours
* f7c3781 Add alert channels
```
<!-- /snippet -->

1. "Add alert channels", the original fork point: the squash commit has one parent, so no commit of the branch became an ancestor of `main`.
2. Three: the two that were already squashed, and the new one. Their changes appear again in the file view, and the merge will tend to conflict.
3. `git rebase --onto main feature/paging~1 feature/paging`: replay only what comes after the last squashed commit. Afterwards the branch is one commit on top of `main`. It then needs a forced push with a lease, because the published branch was rewritten.

Award 1 per part.

*Reference:* Chapter 17, section 17.12; Chapter 9, section 9.5.

### 10.9

(a) `-d` deletes only when the tip is reachable from the upstream or from HEAD. The squash commit carries the content and has no parent link to the branch. (b) `main..feature/paging` tests reachability. `git cherry` compares patch IDs commit by commit; a squash of two commits is one patch that equals neither of the two, so both are marked `+`. (c) A test merge of `main` with the branch produces exactly the tree `main` already has: the branch would add nothing, so its content is fully contained. (d) Yes here. In a real repository also check `git log origin/main..feature/paging` for commits made after the pull request was merged, and that the branch was pushed, before `-D` removes the last local name.

*Reference:* Chapter 17, section 17.9; Chapter 27, section 27.3; Chapter 8, section 8.17.

### 10.10

Each check ran on that pull request's test merge with the base as it was when the run started. Neither run contained the other pull request. Each combination with the old `main` works; the combination of both does not (a semantic conflict). Layer: GitHub rule configuration, on top of the Git fact that a clean merge is not a tested merge.

Mechanisms: (1) strict required checks ("Require branches to be up to date before merging"): the second pull request must merge the new base and run again; cost: every merge makes all other pull requests out of date, and build time multiplies. (2) A merge queue: the checks run on the exact commit that will become the tip, for groups in order; cost: setup, a workflow that also triggers on `merge_group`, and waiting time in the queue. Today: fix forward or revert the later merge.

*Reference:* Chapter 17, sections 17.6 and 17.11; Chapter 18, section 18.8; Chapter 8, section 8.15.

### 10.11

A required check is a name that must have a passing result on the newest commit. The `paths` filter is evaluated on the pull request's three-dot diff; nothing under `src/` or `tests/` changed, so the workflow never starts, no run exists, nothing reports under the name, and the rule waits forever. A job skipped by `if:` belongs to a workflow that did start: it reports `skipped`, which counts as passing.

Restructure: no filter on the trigger of a required workflow. Start it always, detect in a first job whether code changed, and let the expensive jobs depend on that with `if:`. Require one aggregate job that always runs and fails when a needed job failed (a job skipped because a job it `needs` failed must not count as green).

*Reference:* Chapter 20B, section 20B.13; Chapter 18, section 18.8.

### 10.12

Any four of these, each with where it shows:

1. An approval was dismissed as stale after a push or a base change, or the approvals were given by the last pusher while "require approval of the most recent reviewable push" is on: the review list in the merge box.
2. A code owner's review is required and missing: the "Code owner review required" line; check which owner the base branch's CODEOWNERS names.
3. Another reviewer's "Request changes" is still active, or unresolved conversations block under "require conversation resolution".
4. A second layer applies: another repository ruleset, an organization ruleset or a classic rule with a higher approval count or another required check; the repository's `/rules` page for the branch, or `gh ruleset check <branch>`.
5. The branch is not up to date under strict checks, or the pull request is in a merge queue state, or it is still a draft.
6. No allowed merge method is enabled: the ruleset allows only a method the repository has disabled.
7. Unsigned commits under a signed-commits rule.

*Reference:* Chapter 18, sections 18.4, 18.7, 18.17 and 18.19; Chapter 17, section 17.5.

### 10.13

Model response.

1. **Stabilise.** The faulty check is live: decide on a rollback or a hotfix deployment first; severity SEV 1 or 2, since wrong code reached production.
2. **Preserve and diagnose.** From GitHub: the pull request timeline (approval at 14:02 for which commit, the push at 14:05, the merge at 14:06, by whom) and the commit list. From Git: fetch `refs/pull/<n>/head`, and compare the approved commit with the merged head: `git diff <approved> <head>` is the unreviewed change. The squash commit on `main` contains both.
3. **Recover.** A revert of the squash commit would remove the whole pull request. Lowest risk that keeps the reviewed work: a new commit on `main` that restores the input check, taken from the diff above (`git diff <head> <approved> -- <path> | git apply`, or `git restore --source=<approved> -- <path>` when the file has no other changes), through a reviewed pull request.
4. **Verify.** The check is back on `main` (test, and `git diff <approved> main -- <path>` shows only later, reviewed changes); the deployment carries the fix.
5. **Scope.** Search for the same pattern: for merged pull requests, compare the time of the last approval with the time of the last push; `gh pr list --state merged --json number,reviews,commits` gives both. Review each hit's unapproved diff.
6. **Communicate.** Four parts, without names.
7. **Prevent.** Choose between the two settings. "Dismiss stale approvals" is the stricter: any change of the diff needs a new approval; cost: a re-review after every update, including "Update branch". "Require approval of the most recent reviewable push" requires an approval from someone other than the last pusher; cost: earlier approvals stand on a diff that changed. GitHub's own statement is that dismissing stale reviews is safer.

*Reference:* Chapter 17, sections 17.2, 17.5 and 17.9; Chapter 30, sections 30.2 and 30.15.

### 10.14

Model answer. A pull request lists `base..head`: every commit reachable from the head and not from the base. Forty commits appear when thirty-nine of them are not reachable from the base although their content may be there. Three causes. The wrong base: the branch was cut from `develop` or from a colleague's branch and the pull request targets `main`; the commits are real and belong elsewhere. An old merge base: the work the branch sits on was squash-merged or rebase-merged, so the base has the content under other IDs. A rewritten base or head: someone rebased the base branch or the branch was merged with a stale clone, so old and new copies both hang off the head.

Tell them apart with `git log --oneline --graph <base>...<head>` and `git merge-base <base> <head>`: the merge base tells you where the histories actually meet; `git log --cherry-mark --left-right <base>...<head>` marks commits whose patch is on both sides with `=`. The fix is to change the base, or `git rebase --onto <base> <last commit that is not mine>`.

Listen for: "reachable, not content", the merge base, and `--onto`.

*Reference:* Chapter 17, sections 17.3 and 17.12; Chapter 14A, section 14A.14.

---

## Section 11: GitHub Actions

### 11.1

**Answer: C.** On `pull_request`, `GITHUB_REF` is `refs/pull/N/merge` and the checkout uses it. `GITHUB_SHA` is a commit that does not exist in the contributor's clone. A is the "CI tests my branch" model.

*Reference:* Chapter 20A, section 20A.8.

### 11.2

**Answer: A.** `fetch-depth: 1` and `fetch-tags: false`. Jobs that describe, blame, compare or write a changelog need `fetch-depth: 0`.

*Reference:* Chapter 20A, section 20A.8; Chapter 26, section 26.11.

### 11.3

**Answer: B.** A workflow that never starts reports nothing, and the required check stays pending. A job skipped by `if:` reports success. A is the "a skipped required check blocks the merge" model, which is true only for the never-started case.

*Reference:* Chapter 20B, section 20B.13; Chapter 18, section 18.8.

### 11.4

**Answer: B.** YAML reads the unquoted `3.10` as a floating-point number, 3.1. Quote every version.

*Reference:* Chapter 20A, sections 20A.3 and 20A.16.

### 11.5

**Answer: A.** Without a `shell:` key a Linux step runs as `bash -e {0}`. With `shell: bash` the runner uses `bash --noprofile --norc -eo pipefail {0}`. Set `defaults.run.shell: bash` once per workflow.

*Reference:* Chapter 20A, section 20A.7.

### 11.6

**Answer: D.** Secrets other than the job token are not passed to runs triggered from forks; an unset or withheld secret is an empty string, not an error. Design pull request CI to need no secrets; do not switch to `pull_request_target` as a shortcut.

*Reference:* Chapter 20A, section 20A.16; Chapter 21A, section 21A.4.

### 11.7

(a) The repository is shallow (one commit, recorded in `.git/shallow`) and has no tags. `git describe` needs a tag that is reachable from HEAD through parent links, and the walk ends at the boundary. (b) `--always` falls back to the abbreviated commit ID. The command succeeds and the "version" is no version: packages and images get a name that sorts nowhere and says nothing about the release. (c) `fetch-depth: 0` on the checkout step of the job that needs history; the answer snippet shows the same repair with plain Git:

<!-- snippet: final/s11/i1-answer -->
```text
$ git fetch -q --unshallow --tags
$ git rev-list --count HEAD
4
$ git describe
v1.4.0-2-g3d0cd95
```
<!-- /snippet -->

(d) It fails. A release job runs `git describe --exact-match` and stops when the commit is not tagged; a fallback such as `|| echo 0.0.0` or `--always` turns a configuration error into a published artifact.

*Reference:* Chapter 20A, section 20A.8; Chapter 20B, section 20B.12; Chapter 14B, section 14B.12.

### 11.8

A cache entry is immutable per key. The key `venv-Linux` never changes, so after the first save every run gets an exact hit and nothing is saved again: the environment of two weeks ago is restored forever. A restore key is a prefix: when the exact key misses, the newest entry whose key starts with the prefix is restored, and the job then saves the result under the new key, which carries stale content forward.

Corrected: `key: venv-${{ runner.os }}-${{ hashFiles('uv.lock') }}` (the lock file the project uses), with a narrow restore key or none, and a manual prefix such as `v2-` for the day everything must be invalidated. Habit: install from the lock file with the tool's locked mode (`uv sync --locked`, or the equivalent), so that whatever the cache restores, the installed set is what the lock file says.

*Reference:* Chapter 20A, section 20A.11.

### 11.9

A concurrency group is a name, shared by everything that uses it. With the constant group `ci`, all runs of the workflow, for every branch and pull request, are on one track, and `cancel-in-progress: true` lets each new run cancel the one in progress. Group names are also not private to a workflow.

CI: `group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true`: only the newest commit of one branch or pull request matters. Deployment wants the opposite: one group per environment and `cancel-in-progress: false`, because a deployment that is cancelled halfway leaves the environment in an unknown state; and a decision about pending runs (by default a newer pending run replaces an older pending one; `queue: max` keeps them in order).

*Reference:* Chapter 20B, section 20B.5.

### 11.10

In an `if:`, the `${{ }}` wrapper is optional. Here part of the expression is outside it and part inside: the text outside turns the whole value into a non-empty string, and a non-empty string is truthy. The condition is always true.

Write the whole expression inside one wrapper, or with none: `if: ${{ github.ref == 'refs/heads/main' && inputs.deploy }}`. Since January 2026 the workflow editor flags this and the run shows an annotation. A deploy step should in addition be protected by an environment with a branch restriction, so that one wrong `if` is not the only control.

*Reference:* Chapter 20A, sections 20A.5 and 20A.16; Chapter 20B, section 20B.2.

### 11.11

Hypotheses: (1) the environment `production` has no protection rules: it was created automatically, with no rules, by the first run that named it, or the name in the workflow is misspelled and a second, empty environment was created; (2) rules were configured but do not apply: on this plan required reviewers are not available for a private repository. Separating command: `gh api repos/OWNER/REPO/environments/production` (and the list of environments, to find a stray one).

Root cause in both cases: the gate was assumed from the YAML and never configured or read back. Naming a missing environment creates it so that a first deployment works without an administrator; rules are an administrator's decision and a plan feature. Prevention: create environments before the workflow that uses them, read the rules back with the API as part of the pull request that introduces the deployment, and review workflow changes through CODEOWNERS.

*Reference:* Chapter 20B, sections 20B.2 and 20B.4.

### 11.12

Model response.

1. **Test "nothing changed".** `git log --oneline -- .github/workflows requirements.txt` since Friday, and `gh run list --workflow <file> --branch main --limit 20` to find where green turns red. If the repository did not change, something outside it did.
2. **Stabilise.** Tell the team that the failure is not caused by their pull requests; nobody "fixes" their branch.
3. **Diagnose in the fixed order.** Workflow and event: the same file, the same trigger. Runner: `ubuntu-latest` is a moving label; compare the runner image version that the logs of the last green and the first red run record. Dependencies: no lock file, so `pip install -r requirements.txt` resolved newer releases over the weekend; compare the installed versions in the two logs. Action versions: `@v3` is a tag that can move; compare the commit ID the two runs downloaded. Cache: which key was restored in each. Logs: `gh run view <id> --log-failed` for the actual message. Each of the four (image, dependency, action, cache) predicts a different difference between the two logs; one command per hypothesis.
4. **Recover.** Pin what moved: the dependency that broke (an exact version in the requirements, in a reviewed pull request), or the runner label to the previous image, or the action to the previous commit. Re-run.
5. **Verify.** `main` is green on a new run, and an open pull request is green after an update.
6. **Communicate.** What happened, the cause with its layer (GitHub Actions and the package index, not the repository), what was pinned, what remains unpinned.
7. **Prevent.** A lock file and locked installs; actions pinned by full commit ID with an update bot; an explicit runner image label; a scheduled run on `main`, so that the next outside change is found on a quiet branch at night and is attributable to a day.

*Reference:* Chapter 30, section 30.18; Chapter 20B, sections 20B.11 and 20B.12; Chapter 21A, section 21A.7.

### 11.13

Model answer. On `pull_request` the job checks out `refs/pull/N/merge`: a test merge of the head into the current base, as a detached HEAD. So CI tests "my branch merged into today's base", which is the question a pull request asks. Two Git facts make the laptop differ. The commit: the runner has a merge commit that exists on no laptop; my HEAD is the branch tip, and the base may have gained a commit that changes behavior my code relies on. The history: the checkout is one commit deep and has no tags, so anything that reads history (`git describe`, a diff against the base, blame) sees a different repository.

Reproduce: `git fetch origin`, then `git switch --detach <head>` and `git merge origin/<base>` (or fetch `refs/pull/N/merge` and check it out), and run the tests there. First thing to read in the run log is the checked-out commit.

Listen for: the merge ref, detached HEAD, depth 1 without tags, and the local reproduction.

*Reference:* Chapter 20A, section 20A.8; Chapter 20B, section 20B.12.

### 11.14

Model answer. The order goes from "did the right thing start" to "what did it say", and an answer early in the list makes the later ones irrelevant. Workflow: which file from which commit defined the run (scheduled and manually dispatched runs use the default branch's file). Event: what triggered it and which commit was checked out (the merge ref on pull requests). Permissions: what the token could do (unlisted scopes are none; fork and Dependabot runs are read-only). Runner: which image and size (a `-latest` label moved; private repositories get smaller machines). Environment: whether the job referenced one and whether its rules passed. Dependencies: whether the same versions were installed as locally (no lock file, or not installed in locked mode). Then secrets (an unset secret is an empty string), action versions (a moved tag, an old major on a new runtime), and only then the log of the failed step, artifacts, cache and concurrency.

Listen for: an order, the first six with a typical finding each, and "the log comes ninth".

*Reference:* Chapter 20B, section 20B.11; Chapter 30, section 30.18.

---

## Section 12: Security

### 12.1

**Answer: D.** Script injection: `${{ }}` is a templating step over the workflow file, done before the shell exists. The title is attacker-controlled text placed where the shell expects source code. Through `env:` the value arrives as data.

*Reference:* Chapter 21A, section 21A.6.

### 12.2

**Answer: D.** A tag can be moved or deleted by whoever controls the action's repository; a full commit ID is the only immutable reference. B is the "pinning to a version tag fixes its code" model.

*Reference:* Chapter 21A, section 21A.7.

### 12.3

**Answer: A.** The event runs the workflow from the default branch with a read/write token and secrets; it is safe exactly as long as it never executes the stranger's code. The checkout alone does not execute it; the next step that runs what was checked out completes the "pwn request".

*Reference:* Chapter 21A, section 21A.5.

### 12.4

**Answer: A.** Once `permissions` names any scope, every unnamed scope is `none`. Add the missing scope to that job only (`pull-requests: write` or `issues: write`).

*Reference:* Chapter 21A, sections 21A.3 and 21A.20.

### 12.5

**Answer: D.** The damage happens at the issuer, where the key is accepted. Revocation is the only step that works against clones, forks, caches and screenshots alike. A, B and C are the "deleting, force-pushing or making it private removes a leaked secret" model.

*Reference:* Chapter 21B, sections 21B.10 and 21B.14.

### 12.6

**Answer: B.** A signature authenticates the creator of one exact object. It does not judge the change (A, C), and unsigned commits remain forgeable in their author field (D); vigilant mode makes unsigned commits that carry your name show as "Unverified".

*Reference:* Chapter 21B, sections 21B.6 and 21B.7; Chapter 14B, section 14B.17.

### 12.7

<!-- snippet: final/s12/p1-answer -->
```text
$ git grep -l dummy-not-a-real-password
[exit status: 1]
$ git log --oneline -S'dummy-not-a-real-password'
632dffe Remove local settings
c9f2226 Add local settings
$ git rev-list HEAD | xargs git grep -l dummy-not-a-real-password
34f5d3310ff537c7677d813e312c6411814bc3b6:.env
c9f2226ff3f254a1c8c8ebd56bc4c81271743764:.env
```
<!-- /snippet -->

`git grep` without a revision searches the tracked files of the working tree: nothing, status 1. `-S` lists the commits in which the number of occurrences of the string changes: the commit that added the file and the commit that removed it. Searching every commit's tree finds the file in the two commits that contain it: the one that added it and the one after. The commit that removed the file did not remove the content from the earlier snapshots.

Award 2 for the three results (1 if the third is predicted as one commit or as three), 1 for the mechanism.

*Reference:* Chapter 21B, sections 21B.10 and 21B.11; Chapter 14A, section 14A.11.

### 12.8

The five commands: (1) the server's refs point at the amended commit: the branch tip is clean. (2) The old commit object still exists on the server: a force push moves a ref and deletes nothing. (3) The secret is in that commit's tree on the server. (4) Ravi's own reflog names the old commit, so his clone has it for weeks. (5) Asha's remote-tracking branch still contains the old commit: her clone has it and will keep it in a reflog after her next fetch.

First: revoke the secret at its issuer. It was pushed, so it is disclosed; nothing done to the repositories changes that. Git alone cannot clean other people's clones (their owners must re-clone or expire and prune), and on a server you do not administer you cannot run a collection. On this bare repository an administrator could prune (`git gc --prune=now`; a bare repository has no reflog to expire by default). On GitHub the unreachable commit stays served by ID in cached views, pull request refs and forks can keep it reachable, and only GitHub Support can run the collection, which it does only where rotation cannot mitigate the risk.

Award 1 for commands 1 to 3, 1 for commands 4 and 5, 1 for "rotate first", 1 for the GitHub side.

*Reference:* Chapter 21B, sections 21B.10, 21B.14, 21B.17 and 21B.19.

### 12.9

Git refuses to act on a repository whose directory belongs to another user, because a repository's own configuration can make Git run programs (hooks, `core.fsmonitor`, aliases, a pager): opening someone else's repository would execute their settings as you. In a container the mounted directory belongs to the host's user ID, not to the user inside.

The wildcard switches the protection off for every path on the machine or image, including any directory an attacker can write. Narrow fix: `git config --global --add safe.directory /workspace` for that one path, in the global file of the user who runs Git (the setting is ignored in repository-level configuration on purpose). Better: build the image so that the checkout is created by, or owned by, the user that runs Git.

*Reference:* Chapter 21B, sections 21B.2, 21B.3 and 21B.21.

### 12.10

Author and committer fields are text that the committing machine writes from its configuration; Git verifies neither, and GitHub attributes by matching the email address. Anyone with push access can create a commit that names Asha. Evidence: `git log --format='%h %an %cn %G?' -1 <id>` (author, committer, no signature); on GitHub the pusher is in the repository's Activity view and, for an enterprise, in the audit log's Git events. The account that pushed is the one to examine: either its owner did it or its credential is in other hands. Asha's account did nothing.

Controls. Per person: Asha signs her commits on every machine and enables vigilant mode, after which an unsigned commit carrying her name is displayed as "Unverified". Per repository: a rule that requires signed commits on the protected branch, so that an unsigned commit cannot land; know that it constrains the merge methods.

*Reference:* Chapter 21B, sections 21B.5 and 21B.6; Chapter 14B, section 14B.18; Chapter 18, section 18.10.

### 12.11

Push protection scans every commit the push would send, not the tip's files. The first commit still contains the key; the second commit only changes the next snapshot. `git log --oneline @{u}..` (or `origin/<branch>..`) lists the unpushed commits; `git log -p -S<part of the key> @{u}..` shows the one that has it.

Repair, nothing published: rewrite the unpushed commits so that the key was never committed: `git reset --soft @{u}` and commit again without it, or an interactive rebase that edits the first commit. Do not bypass the block with a reason.

The key: decide by where it has been. It never reached the server, but it is in the local object database and reflog, and possibly in an editor backup or a terminal log. If the machine and those places are trusted and nothing was shared, rotation is a judgment call; the cheap and safe answer is still to rotate, and it becomes mandatory the moment any copy left the machine.

*Reference:* Chapter 21B, sections 21B.12 and 21B.21.

### 12.12

Model response.

1. **Contain.** Revoke or rotate the key at the provider now; the repository is not where the damage happens. It has been public for 38 minutes: assume it was copied.
2. **Assess.** Five facts, written down: which secret and what it can reach (models, spend limit, data); the first commit that contains it and when it was first pushed (`git log --all --oneline -S'dummy-not-a-real-key-3333'`); which refs contain it (`git branch -a --contains`, `git tag --contains`, the pull request ref); who could read it (public: everyone; eleven forks; CI logs); whether it was used. The last comes only from the provider's logs.
3. **Eradicate.** Remove it from the current code (read it from the environment). Decide on a history rewrite: with the key revoked, the remaining content is a dead string, and GitHub's guidance is that a rewrite is often unnecessary then. Rewrite only if the file exposes more than the key (other values, internal hostnames), with git-filter-repo in a fresh clone, all refs, then a forced push.
4. **Recover.** Put the new key where the services read it; if history was rewritten, everyone re-clones and force-push protection is switched back on; close the alert as revoked.
5. **Communicate.** Internally at once; exact instructions for clones if there was a rewrite; the four-part summary; a disclosure contact kept reachable.
6. **Prevent.** Push protection for the repository, a pre-commit scanner backed by the same scanner as a required check, the key in a secret store with a spend cap and narrow scope, short-lived credentials where the provider supports them.

Copies that survive a rewrite: unreachable commits and cached views in the repository, and the pull request ref (GitHub Support, on request, where rotation cannot mitigate); the eleven forks (each fork's owner; the network shares objects); clones (their owners). You decide not to rewrite when revocation makes the leaked value worthless and nothing else in those commits is sensitive.

*Reference:* Chapter 21B, sections 21B.11, 21B.14, 21B.16 and 21B.19; Chapter 30, section 30.17.

### 12.13

Model response.

1. **Stabilise.** Stop using the action: disable the twelve workflows or pin them to the last known good commit ID in one pull request. Pause deployments.
2. **Preserve.** Export the run lists and logs for the window before they expire or are deleted; note the commit ID that `@v2` resolved to in each run (question 8 of the investigation order, "which commit of each action ran", answered from each run's log).
3. **Diagnose.** Establish the window from the action's repository (when the tag moved, to which commit) and match it against your runs: `gh run list` per workflow with creation times, then the resolved ID in each log. For every affected job list what was in its environment: secrets it named, the job token and its permissions, OIDC permission, cache access.
4. **Recover.** Treat every credential reachable from an affected job as disclosed, whether or not the log shows it: masking is not a boundary, and code in the job can send values anywhere. Rotate them all, deploy credentials first, in one pass; partial rotation is how second breaches happen. Review what the job token could write in the window: new commits, tags, releases, workflow files, caches. Delete caches written in the window. Delete logs that printed values, after export.
5. **Verify.** No workflow references the action by tag; old credentials are refused by their issuers; refs and releases equal trusted values.
6. **Communicate.** Four parts; say what could have been reached, not only what was seen.
7. **Prevent.** Three controls: pin third-party actions to full commit IDs, with an update bot and an organization policy that requires it; least privilege per job (`permissions` set explicitly, secrets passed only to the step that needs them, environments with reviewers for deploy credentials); short-lived cloud credentials through OIDC federation instead of stored keys, so that a printed environment contains nothing that outlives the job.

*Reference:* Chapter 21A, sections 21A.3, 21A.7, 21A.8, 21A.9, 21A.10 and 21A.18; Chapter 21B, section 21B.14.

### 12.14

Model answer. Six controls, each with what it stops. (1) `permissions` set per job, read-only by default: a compromised step cannot push commits, tags or releases with the job token. (2) Third-party actions pinned to full commit IDs: a moved tag does not change the code that runs. (3) No untrusted text in `run:` through `${{ }}`; values pass through `env:`: script injection through titles, branch names and comments. (4) No execution of pull request code under `pull_request_target` or with secrets: the "pwn request"; fork CI is designed to need no secrets. (5) Secrets scoped to the job and step that need them, deploy credentials behind environments with required reviewers and branch restrictions, cloud access through OIDC: a leak or an unreviewed workflow change cannot reach production credentials. (6) CODEOWNERS plus a rule on `.github/workflows/`, and static analysis of workflows as a required check: a pull request cannot quietly weaken the other five. Also worth a sentence: self-hosted runners never on public repositories, and caches and artifacts treated as untrusted input.

Listen for: each control tied to an attack, and at least one control that protects the workflow files themselves.

*Reference:* Chapter 21A, sections 21A.3 to 21A.7, 21A.9 to 21A.14 and 21A.19.

### 12.15

Model answer. A client-side hook is a program in `.git/hooks` or wherever `core.hooksPath` points, in one clone. Clone does not copy hooks, because copying executable code from a server onto every developer's machine would be a security hole; so each person has to install them. Anyone can skip them with `--no-verify`, a commit made through a web interface or an API never runs them, and neither does a tool that uses its own Git client. They also run with whatever versions are on that machine.

What they are good for: fast feedback before a commit or a push leaves the machine: formatters, a secret scanner, a size check, a message check. They save a round trip; they do not guarantee anything.

Enforcement lives where the contributor cannot opt out: on the server. On a plain Git server that is a `pre-receive` hook and `receive.*` settings. On GitHub it is rulesets (push rules for file size, paths and extensions; branch rules for required checks, reviews, signatures), push protection for secrets, and the same checks the hooks run executed again in CI as required checks.

Listen for: not cloned, `--no-verify`, "feedback, not enforcement", and the server-side list.

*Reference:* Chapter 14C, sections 14C.9, 14C.11, 14C.12 and 14C.13; Chapter 28, section 28.10; Chapter 18, section 18.12.

---

## Section 13: Open source

### 13.1

**Answer: D.** Git has no notion of a fork. The Fork button creates a GitHub object: a server-side repository connected to its parent, in a network that shares objects. In your clone it is a remote with a URL, by convention `origin`, with the project as `upstream`.

*Reference:* Chapter 12, section 12.10; Chapter 27, section 27.2; Chapter 15, section 15.7.

### 13.2

**Answer: D.** Commits on the fork's default branch make it diverge. Move them to a topic branch and reset the fork's `main` to the upstream's. Check with `git rev-list --left-right --count upstream/main...origin/main`: a second number above zero is the diagnosis.

*Reference:* Chapter 17, section 17.19; Chapter 27, sections 27.3 and 27.19.

### 13.3

**Answer: B.** After a squash, ancestry is gone and content is present. A and D test reachability and answer "not merged"; C refuses for the same reason. Test content.

*Reference:* Chapter 27, section 27.3; Chapter 17, section 17.9.

### 13.4

**Answer: D.** Fork runs get no secrets by design. A is the "pwn request": the base repository's token and secrets in a job that executes a stranger's code. Split the workflows: untrusted build and test, trusted evaluation started by a maintainer.

*Reference:* Chapter 21A, sections 21A.4 and 21A.5; Chapter 27, section 27.19; Chapter 28, section 28.11.

### 13.5

<!-- snippet: final/s13/p1-answer -->
```text
$ git status -sb
## fix/unicode-escapes...origin/fix/unicode-escapes [ahead 2, behind 1]
$ git push
To ../fork.git
 ! [rejected]        fix/unicode-escapes -> fix/unicode-escapes (non-fast-forward)
error: failed to push some refs to '../fork.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../fork.git
 + 69d8d3e...ff43f3c fix/unicode-escapes -> fix/unicode-escapes (forced update)
[exit status: 0]
$ git log --oneline --graph fix/unicode-escapes
* ff43f3c Decode unicode escapes
* 5e4349e Add the lexer
* 6956593 Add the parser
```
<!-- /snippet -->

After the rebase the local branch has the project's new commit and a new copy of your commit; the branch in the fork still has the old copy: ahead 2, behind 1. A plain push is rejected as non-fast-forward, because the fork's tip is not an ancestor of the new tip. `--force-with-lease` replaces it. That is acceptable because the branch is yours alone and exists to carry this pull request; the lease guards against a maintainer having pushed to it in the meantime. The pull request follows the branch: it now shows one commit on a current base, review comments on changed lines may become outdated, and an approval may be dismissed as stale.

Award 2 for the three outcomes, 1 for the judgment.

*Reference:* Chapter 27, section 27.3; Chapter 9, section 9.17; Chapter 17, section 17.5.

### 13.6

<!-- snippet: final/s13/g1-answer -->
```text
$ git log --graph --oneline by-merge
*   26d9af2 Merge upstream/main into the branch
|\  
| * 7b8acf3 U1: add the lexer
* | e11140c P2: parse block comments
* | 55f9b9a P1: parse line comments
|/  
* ba65dfd Add the parser
$ git log --graph --oneline by-rebase
* 20f1b05 P2: parse block comments
* 7ba89be P1: parse line comments
* 7b8acf3 U1: add the lexer
* ba65dfd Add the parser
$ git merge-base --is-ancestor origin/feature/comments by-merge; echo "by-merge can be pushed without force: exit status $?"
by-merge can be pushed without force: exit status 0
$ git merge-base --is-ancestor origin/feature/comments by-rebase; echo "by-rebase can be pushed without force: exit status $?"
by-rebase can be pushed without force: exit status 1
$ git log --oneline upstream/main..by-merge
26d9af2 Merge upstream/main into the branch
e11140c P2: parse block comments
55f9b9a P1: parse line comments
$ git log --oneline upstream/main..by-rebase
20f1b05 P2: parse block comments
7ba89be P1: parse line comments
```
<!-- /snippet -->

```text
  by merge:    A---U1---------M        by rebase:    A---U1---P1'---P2'
                \            /
                 P1---P2----'
```

The merge keeps P1 and P2 and adds a merge commit: it is a descendant of what is in the fork, so it is pushed without force, and existing review comments keep their commits; the price is a merge commit in the pull request's commit list. The rebase gives two new commits on top of the project's tip: a linear list of exactly the contributor's work, which needs a forced push and invalidates references to the old commit IDs. A maintainer who squash-merges does not care about the merge commit; one who uses "rebase and merge" or reads history commit by commit prefers the rebase.

Award 2 for the two graphs, 1 for push behavior and the range lists.

*Reference:* Chapter 27, section 27.3; Chapter 9, section 9.18.

### 13.7

State 1: the branch was created from the `main` of a fork that had never been synchronized, and the pull request targets a branch that has since been rewritten or is another line (a release branch): the 36 commits are real upstream commits that the chosen base does not contain. State 2: the fork's `main` carries old commits whose content was squash-merged or rebased upstream under other IDs, and the branch sits on them.

Separate, in the contributor's clone, after `git remote add upstream <url>` and `git fetch upstream`: `git merge-base upstream/main <branch>` and `git log --oneline upstream/main..<branch>` (which commits are not upstream by ancestry), then `git log --oneline --cherry-mark --left-right upstream/main...<branch>` (which of them are upstream by content, marked `=`).

Instructions for a newcomer, which never lose the fix: (1) `git branch backup/my-fix` (a name for the present state); (2) `git fetch upstream`; (3) `git switch -c fix/<topic> upstream/main`; (4) `git cherry-pick <ID of your one commit>`; (5) `git push -u origin fix/<topic>` and open a new pull request from that branch, or change the old pull request's head. Say what not to do: no "Update branch" merge loops, no pull with rebase on the old branch.

*Reference:* Chapter 17, sections 17.12 and 17.15; Chapter 27, sections 27.2 and 27.3.

### 13.8

Root cause: a commit on one branch is on another branch only if somebody merges or cherry-picks it. Nothing in Git propagates a fix between branches; "this fix belongs everywhere" is knowledge held by the team. The step that carries the fix to `main` was a human step that nobody took.

Evidence: `git log --oneline --cherry-pick --right-only --no-merges main...release/2.x` lists commits on the release branch that `main` has neither by ancestry nor by patch. Repair: port the fix to `main` (`git cherry-pick -x <fix>`, or merge the release branch up if that is the convention), release 3.0.1; do not move the 3.0.0 tag.

Conventions: merge upward (fix on the oldest supported branch, merge that branch into the newer ones): one commit ID everywhere, and the failure is a forgotten or conflicting upward merge. Fix on `main` first and cherry-pick down: the fix cannot be missing from the future, and the failure is a forgotten or diverging backport, visible as two commits with different IDs. Either way the check above belongs in the release procedure as a gate.

*Reference:* Chapter 27, sections 27.10 and 27.19; Chapter 10, sections 10.9 and 10.10.

### 13.9

Model solution, as a replay of the lab.

<!-- snippet: final/solve-fork/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git remote -v
origin	../fork.git (fetch)
origin	../fork.git (push)
$ git log --oneline --graph --all
* c42e61f Test that timestamps are UTC
* 20d0693 Emit UTC timestamps
* c90e433 Add span clock and exporter
```
<!-- /snippet -->

<!-- snippet: final/solve-fork/02-upstream -->
```text
$ git remote add upstream ../upstream.git
$ git fetch upstream
From ../upstream
 * [new branch]      main       -> upstream/main
$ git log --oneline --graph --all
* b72b27a Add a pretty option to the exporter
* b96a7cc Add span sampling
| * c42e61f Test that timestamps are UTC
| * 20d0693 Emit UTC timestamps
|/  
* c90e433 Add span clock and exporter
$ git log --oneline upstream/main..main
c42e61f Test that timestamps are UTC
20d0693 Emit UTC timestamps
```
<!-- /snippet -->

<!-- snippet: final/solve-fork/03-branch -->
```text
# The two commits get a name first. Then the copy on top of the project is made.
$ git switch -c fix/utc-timestamps
Switched to a new branch 'fix/utc-timestamps'
$ git rebase upstream/main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/utc-timestamps.
$ git push -u origin fix/utc-timestamps
To ../fork.git
 * [new branch]      fix/utc-timestamps -> fix/utc-timestamps
branch 'fix/utc-timestamps' set up to track 'origin/fix/utc-timestamps'.
```
<!-- /snippet -->

The step that rewrites a published branch is the push of `main` to the fork. It is acceptable because the fork's `main` is yours, nobody is expected to build on it, and the two commits are safe on the topic branch before the ref moves. The safest form names the value you expect the fork to have:

<!-- snippet: final/solve-fork/04-main -->
```text
# main is not checked out, so the ref can be moved without touching any file.
$ git branch -f main upstream/main
branch 'main' set up to track 'upstream/main'.
$ git push --force-with-lease=main:origin/main origin main
To ../fork.git
 + c42e61f...b72b27a main -> main (forced update)
```
<!-- /snippet -->

`git branch -f main upstream/main` moved the ref without touching a file, because `main` was not checked out, and, since the start point is a remote-tracking branch, also made `upstream/main` the upstream of `main`.

<!-- snippet: final/solve-fork/05-verify -->
```text
$ git log --oneline --graph --all
* d773210 Test that timestamps are UTC
* ea814ea Emit UTC timestamps
* b72b27a Add a pretty option to the exporter
* b96a7cc Add span sampling
* c90e433 Add span clock and exporter
$ git branch -vv
* fix/utc-timestamps d773210 [origin/fix/utc-timestamps] Test that timestamps are UTC
  main               b72b27a [upstream/main] Add a pretty option to the exporter
$ cd ..
$ assessments/gen/final-fork/check.sh
Checking final-test lab fork
  ok    the project (upstream.git) was not touched
  ok    your clone has a remote "upstream" that points at the project
  ok    main in your fork equals main of the project
  ok    your local main equals main of the project
  ok    the fork has the branch fix/utc-timestamps, based on the project's current main
  ok    fix/utc-timestamps holds exactly your two commits, in order
  ok    your local fix/utc-timestamps equals the one in the fork
  ok    the upstream of your local fix/utc-timestamps is origin/fix/utc-timestamps
  ok    the branch still has the UTC change
  ok    nothing is staged, modified or untracked in your clone
  ok    no operation is left in progress
PASS: the end state of fork is right.
[exit status: 0]
```
<!-- /snippet -->

Hand-in (4 points): 2 for the ordered command list with labels (remote add and fetch 🟢; switch -c 🟢; rebase 🟡; push of the new branch 🟢; `branch -f` 🟡; forced push of `main` 🔴 with a lease), 2 for the alternative when others have based work on the fork's `main`: do not rewrite it; leave it, or revert the two commits on it, and tell the people who use it. Using `git reset --hard upstream/main` on a checked-out `main` before the commits have another name loses the hand-in points for order even when the check passes through the reflog.

*Reference:* Chapter 27, sections 27.2 and 27.3; Chapter 12, sections 12.8 and 12.10; Chapter 17, section 17.15.

### 13.10

Model answer. Three repositories: the project, which I can only fetch; my fork on the platform, which I can push to; my clone. In the clone the fork is `origin` and the project is `upstream`. First I read `CONTRIBUTING`, look for an existing issue, and open or comment on one before writing a large change. I fetch `upstream` and create a topic branch from `upstream/main`, never from my fork's `main` and never on `main` itself. I make small commits with messages in the project's convention, run its tests, push the branch to my fork and open a pull request against the project, as a draft if I want early feedback.

When the project moves, I fetch `upstream` and either merge `upstream/main` into my branch or rebase onto it and push with `--force-with-lease`, following what the project asks. I answer review comments with new commits unless asked to squash. After the merge I delete the branch in the fork and locally; if it was squash-merged, `git branch -d` refuses once the remote-tracking branch is pruned, and I verify by content before `-D`. What I never do: commit on the fork's default branch, force-push anything that is not my own pull request branch, or put a credential in a commit.

Listen for: the three repositories with their remote names, the base of the branch, the update choice with the lease, and the etiquette.

*Reference:* Chapter 27, sections 27.2 to 27.4; Chapter 17, section 17.15.

### 13.11

Model answer. Two classes of work, two workflows. The untrusted class runs on `pull_request`: build, lint, unit tests. For a fork it gets a read-only token and no secrets, and it must be written to pass without any. First-time contributors need a maintainer's approval before a run starts, and I set that to the strict option, knowing that one merged typo fix lifts it. The trusted class, the integration tests with the cloud credential, never runs code from a pull request that a maintainer has not read: it runs after merge on `main`, or it is started by a maintainer for a specific reviewed commit, in a job that references an environment with required reviewers. I do not use `pull_request_target` to get the secret into pull request runs; if I use that event at all it is for labeling and commenting, and it never checks out or executes the pull request's code.

Around it: the credential is short-lived through OIDC with a trust policy bound to the environment, the job has minimal `permissions`, caches written by pull request runs are not trusted by the privileged job, and no self-hosted runner serves the public repository.

Listen for: the split, "no secrets on fork runs by design", the approval gate with its limit, and the refusal of `pull_request_target` plus checkout.

*Reference:* Chapter 21A, sections 21A.4, 21A.5, 21A.10 to 21A.13; Chapter 28, section 28.11.

---

## Section 14: AI/ML workflows

### 14.1

**Answer: A.** Git holds what a human writes and reviews, plus small references to everything else. B fails on size (every clone carries every version, objects cannot be recalled, and the platform blocks files above 100 MiB); C puts program output into review; D removes configuration from review and from the commit that a run names.

*Reference:* Chapter 28, sections 28.2 and 28.6.

### 14.2

**Answer: B.** With LFS, the blob in Git is a pointer: a few lines with a version line, the SHA-256 of the content and its size. The clean and smudge filters swap pointer and content; without the client there is no smudge, so the pointer is what is checked out.

*Reference:* Chapter 22, sections 22.3 and 22.7.

### 14.3

**Answer: A.** One file mixes what a person wrote with what a program produced. Git has no knowledge of file formats; awareness is added with a clean filter or by reviewing a paired text file.

*Reference:* Chapter 28, section 28.3.

### 14.4

**Answer: B.** A result is identified by the commit, the state of the working tree relative to it, the data and model versions, the resolved configuration and the environment. A is false: an ID is stable everywhere. C and D are inventions.

*Reference:* Chapter 28, sections 28.7 and 28.8.

### 14.5

**Answer: D.** The filter and the hooks live in each clone's configuration. A clone without them, `--no-verify`, a web edit or an agent with its own client all bypass them. The same checks as a required CI job are the enforcement.

*Reference:* Chapter 28, section 28.10; Chapter 14C, section 14C.13.

### 14.6

<!-- snippet: final/s14/p1-answer -->
```text
$ git show HEAD:analysis.nb
IN: df.describe()
IN: plot(df)
$ git status --short
$ cat ../churn-clone/analysis.nb
IN: df.describe()
IN: plot(df)
$ git -C ../churn-clone config get filter.dropout.clean
[exit status: 1]
$ git -C ../churn-clone check-attr filter analysis.nb
analysis.nb: filter: dropout
# A colleague runs the notebook in the clone and stages it:
$ printf 'IN: df.describe()\nOUT: count 250\nIN: plot(df)\nOUT: <figure 7>\n' > ../churn-clone/analysis.nb
$ git -C ../churn-clone add analysis.nb && git -C ../churn-clone diff --cached
diff --git a/analysis.nb b/analysis.nb
index 948f321..5ef6e63 100644
--- a/analysis.nb
+++ b/analysis.nb
@@ -1,2 +1,4 @@
 IN: df.describe()
+OUT: count 250
 IN: plot(df)
+OUT: <figure 7>
```
<!-- /snippet -->

(a) The clean filter runs when content goes into the index, so the blob has the two `IN:` lines only. After the re-run the file on disk differs, but its cleaned form equals the blob, so `git status` reports nothing. (b) The clone's file has no outputs, because it was checked out from the blob. `.gitattributes` travelled with the repository and still names the filter `dropout`; the definition of that filter lives in `.git/config` of the first repository and did not travel, so `git config get` exits 1. (c) With no filter program, Git stores the file as it is: the outputs are staged, and would be committed.

Award 1 per part. This is the mechanism behind "outputs in history although we use a stripping filter".

*Reference:* Chapter 28, sections 28.4 and 28.16; Chapter 14C, sections 14C.4 and 14C.8.

### 14.7

(a) The record names a commit. It does not say whether the working tree equalled that commit when the run started. (b) The suffix `-dirty`: at least one tracked file differs from HEAD. (c) The code on disk, with `LR = 3e-4`; the commit says `1e-4`. Checking out the commit gives another learning rate and another metric. The run can be reproduced only because the diff is known here: apply it to the commit and rerun. If the patch had not been captured, the result could not be reproduced, and the right statement is to say so and rerun from a commit. (d) Refuse to start a tracked run from a dirty tree, or record with the commit ID the output of `git status --porcelain` and the diff, plus the data version, the lock file and the container digest.

*Reference:* Chapter 28, section 28.7.

### 14.8

A push sends commits, and every commit is a full snapshot. The commit that added the checkpoint is still among the unpushed commits; the later commit that deleted it changes the next snapshot only. The server rejects the push because one of the objects in it exceeds the limit (GitHub blocks files above 100 MiB).

Evidence: `git log --oneline --stat @{u}.. -- checkpoints/epoch-3.bin`, or `git log --diff-filter=A --oneline @{u}.. -- checkpoints/`. Repair, never published: rewrite the unpushed commits so that the file was never added: `git reset --soft @{u}`, `git restore --staged checkpoints/`, commit again; or an interactive rebase that edits the adding commit. Keep the file on disk and ignore it.

Set up: `checkpoints/` and weight extensions in `.gitignore`; a pre-commit size check backed by the same check in CI; a push ruleset that limits file size; and a decision on where checkpoints live (LFS, or an object store with pointer files).

*Reference:* Chapter 15, sections 15.15 and 15.20; Chapter 28, sections 28.2, 28.9 and 28.16; Chapter 18, section 18.12.

### 14.9

The data. A commit pins code and whatever small pointers it contains; an evaluation set that is read from a path or a bucket by name can be edited in place without any commit. With a pointer file that records a checksum and a size, the evaluation compares the data it reads with the pointer: the check reports "differs", and the change of data becomes either a failed run or a reviewed commit that updates the pointer.

Control: the evaluation refuses data that does not match its pointer, and the run record stores the data checksum next to the commit ID. To the product team: the two numbers were measured on different data and are not comparable; one of them has to be re-measured, on the old data restored from the store or on the new data for both models, before anything is concluded about the model.

*Reference:* Chapter 28, sections 28.6, 28.7 and 28.16.

### 14.10

Her clone is a sparse checkout (the bootstrap script, or `scalar clone`, configured it): `core.sparseCheckout` is on, most index entries carry the skip-worktree bit, and only the directories in the cone are written to disk. `find` reads the working tree and sees the cone. Git commands that read the index or commits see everything.

Without changing the checkout: `git ls-files '*.py'` (the index), `git ls-tree -r --name-only HEAD` (the commit), `git grep --cached -l <pattern>` (search without files on disk). `git sparse-checkout list` shows the cone. Rule: a script that must see all files asks Git, not the directory listing; and a working-tree question is not a repository question.

*Reference:* Chapter 24, sections 24.4 and 24.5.

### 14.11

Model response.

1. **Contain.** Revoke the key at the provider now. Twenty-five minutes in a public repository means it is disclosed.
2. **Preserve and assess.** Which commit added the output (`git log --all --oneline -S'dummy-not-a-real-key-4444'`), which refs contain it (the branch, the pull request ref), who could read it (public; forks), whether the key was used (provider logs), and what else the same output cell printed: an environment dump may hold more than one credential. Rotate all of them.
3. **Diagnose.** "Uses nbstripout" means that some clones have the filter configured. The filter definition is per clone; `.gitattributes` travels, the program and its configuration do not. In the committing clone `git config get filter.nbstripout.clean` exits 1, or the commit was made through a web upload or with a client that does not run filters.
4. **Eradicate.** Strip the notebook and commit. Decide on a rewrite with the key already revoked: the remaining content is the dead key and whatever else the cell showed. If nothing else is sensitive, do not rewrite a public history; if there is, rewrite with git-filter-repo in a fresh clone, force-push, and ask Support about the pull request ref and cached views.
5. **Recover and verify.** New keys in place and working; old keys refused; a scan of all refs is clean or shows only revoked values.
6. **Communicate.** Four parts; what the key could reach and what the logs show.
7. **Prevent.** A setup script that installs the filter, and `required = true` for it so that a clone without the program fails at `git add` instead of committing outputs; the same strip check as a required CI job; push protection on the repository; no secrets in environment variables of interactive kernels where a cell can print them (a dedicated low-privilege, spend-capped key for notebooks).

*Reference:* Chapter 28, sections 28.3, 28.4, 28.14 and 28.16; Chapter 21B, sections 21B.12 and 21B.14.

### 14.12

Model answer. At start-up the run records, together: the commit ID; whether the tree was dirty, and if it may be dirty, the status and the diff; the lock file's hash; the container image by digest, not by tag; the resolved configuration after all overrides; the checksum or version of each data set and base model it reads. It refuses to start as a tracked run when the tree is dirty, unless the patch is stored with the record, and it refuses data that does not match the pointer file committed in the repository.

Data and models are tied to the commit by pointer files: small committed files with a checksum and size, the bytes in a content-addressed store (LFS or an object store), so that "which data" is answered by `git show <commit>:<pointer>`. Notebooks are committed without outputs. What I tag: the exact commit that produced a released model or prompt set, with an annotated tag, and the tag message or a release record names the data and model versions; the tag never moves.

Listen for: commit plus dirty state, lock file, digest, resolved configuration, data checksum; refusal as a control; pointers; an immutable annotated tag.

*Reference:* Chapter 28, sections 28.6 to 28.8 and 28.12; Chapter 14B, section 14B.11.

### 14.13

Model answer. An agent is a contributor with a different Git client, unusual speed and no memory of our conventions, so I rely only on controls that do not depend on the contributor. It may not run local hooks: every hook that matters is also a required check. It produces large changes quickly: small pull requests, and a human approval that an automated approval cannot replace, enforced by a ruleset. It reads whatever is in the repository and the task, so text in an issue, a title or a file can steer it: agents do not run automatically on untrusted contributions and get no write token unless the task needs one. It holds credentials while it works: a dedicated low-privilege, spend-capped key and narrowly scoped tokens. It does not know our conventions: they are in a committed instruction file, and checks enforce them anyway.

Attribution is decided up front: a bot account, a trailer or a signature, so that "which commits did an agent write" is a `git log` query. And the rest of the rulebook applies unchanged: protected `main`, CODEOWNERS on workflows, no secrets on fork runs.

Listen for: "controls that do not depend on the contributor", prompt injection as an input problem, credentials, and attribution.

*Reference:* Chapter 28, section 28.15; Chapter 21A, section 21A.17.

---

## Section 15: Production incidents

### 15.1

**Answer: B.** Stages 2 and 3 only add refs or read state. Most damage in Git incidents is done by a command typed before the state was understood.

*Reference:* Chapter 30, section 30.2; Chapter 29, section 29.2.

### 15.2

**Answer: A.** Severity is assigned on what could have happened in the window; the example is SEV 2 although nothing shipped, because one check stood between the rewritten branch and production. It never depends on who caused the incident.

*Reference:* Chapter 30, section 30.3.

### 15.3

**Answer: C.** The summary has four parts: what happened, root cause with its layer, what was done and how it was verified, prevention. No names, and commands help with none of the three decisions a CTO has to make.

*Reference:* Chapter 30, section 30.15.

### 15.4

(a) The top commit is a merge by Ravi with two parents: his local `main`, which still had the old history including "Add local environment" (the commit with the key), and the cleaned history from the server. The old commits and their rewritten copies are both in `main` now, which is why two subjects appear twice with different IDs. (b) His merge commit has the server's tip as a parent, so the push was a fast-forward. To Git these are two lines of work that someone chose to merge. (c) The commit that adds `.env` is reachable from `origin/main` again; and the remote-tracking reflog shows the sequence: your first push, your forced push of the clean history, and today's fast-forward. (d) Force-push the clean tip again with an explicit lease (`origin/main@{1}` is that tip); in Ravi's clone anchor his one real commit ("Add a cache key"), reset his `main` to the clean `origin/main`, cherry-pick his commit and push; expire the old history in his clone or re-clone. Prevention: before a rewrite, freeze; after it, everybody re-clones or rebases onto the new history and nobody merges; and a server-side check that rejects pushes containing the old commits. The key was rotated yesterday, which is why this is a cleanup and not a second leak.

*Reference:* Chapter 21B, sections 21B.16 and 21B.18; Chapter 13, section 13.10.

### 15.5

Hypotheses and commands:

1. **`main` was rewritten** (a forced push from an old clone): in any clone that fetched on Friday, `git reflog show origin/main` shows a "forced-update" line with the hotfix below it; on the platform, the Activity view lists the force push.
2. **The hotfix was reverted** or overwritten by a bad conflict resolution: `git log --oneline --grep='Revert' main`, and `git log --oneline -S'<a line of the fix>' main` shows the commit that added the line and the one that removed it.
3. **The hotfix was never on `main`**: it was deployed from a branch or a tag: `git branch -a --contains <hotfix ID>` and `git tag --contains <hotfix ID>`; the deployment record names the ref that was built.

A fourth worth naming: Monday's build is not from the tip the team thinks (a stale checkout or cache): compare the build's recorded commit with `git ls-remote origin main`.

Evidence only in clones: reflogs of local and remote-tracking branches, unreachable commits. Evidence only on the platform: who pushed and when (Activity view, audit log, pull request timeline), deployment records.

*Reference:* Chapter 29, sections 29.2, 29.7 and 29.8; Chapter 30, section 30.2.

### 15.6

During a conflict Git writes the markers into the working tree file and leaves the path unmerged. `git add` marks it resolved whatever the file contains: Git does not check for markers. A hurried `git add -A && git commit` records them.

Evidence: `git show --remerge-diff <merge>` shows the difference between a mechanical re-merge and what was recorded, that is, exactly what the person did; `git log --merges -1 -- deploy/values.yaml` finds the merge. Repair on a published branch: a new commit that fixes the file to the intended content, decided with the authors of both sides (read stage by stage from the merge's parents: `git show <merge>^1:deploy/values.yaml` and `^2`), through a pull request. No rewrite.

Controls: `git diff --check` (it reports leftover conflict markers) in a pre-commit hook and again in CI as a required check; a syntax check of YAML in CI; `merge.conflictStyle=zdiff3` so that conflicts are easier to resolve correctly.

*Reference:* Chapter 8, sections 8.9, 8.10 and 8.16; Chapter 14A, section 14A.6; Chapter 30, section 30.13.

### 15.7

Model diagnosis and repair, as a replay of the lab.

<!-- snippet: final/solve-incident/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git log --oneline --graph --all --decorate
* 59e1918 (HEAD -> main, tag: v1.5.0, origin/main, origin/HEAD) Account usage per team
* 6d56963 Add budget alerts
* 5088890 Add per-team budgets
| * 5b81a41 (tag: v1.4.1, origin/release/1.4) Allow a request that exactly reaches the budget
|/  
* 235a339 (tag: v1.4.0, release/1.4) Add usage accounting
* 5c9decb Add the token budget
```
<!-- /snippet -->

Ravi's search succeeds because `--all` looks at every ref. The commit is on `release/1.4` and in `v1.4.1`, and on nothing else. Nothing was reverted, and no commit on `main` carries the same patch.

<!-- snippet: final/solve-incident/02-evidence -->
```text
# Ravi's search finds the commit. On which refs is it?
$ git log --all --oneline --grep="exactly reaches the budget"
5b81a41 Allow a request that exactly reaches the budget
$ git branch -a --contains 5b81a41
  remotes/origin/release/1.4
$ git tag --contains 5b81a41
v1.4.1
$ git merge-base --is-ancestor 5b81a41 v1.5.0
[exit status: 1]
# Was anything reverted on main? And is the change there under another commit ID?
$ git log --oneline --grep=Revert v1.5.0
$ git cherry -v main origin/release/1.4
+ 5b81a41a0cd58b19b0081534062b55ca030d259a Allow a request that exactly reaches the budget
$ git show v1.5.0:budget.py | head -2
def allowed(used, limit):
    return used < limit
$ git show v1.4.1:budget.py | head -2
def allowed(used, limit):
    return used <= limit
```
<!-- /snippet -->

```text
Observed behavior : 1.5.0 refuses a request that exactly reaches the budget; 1.4.1 allows it.
Git state         : 5b81a41 is reachable from release/1.4 and v1.4.1 only. main and v1.5.0 do not
                    contain it and contain no commit with the same patch.
Mechanism         : a commit on one branch reaches another only by a merge or a cherry-pick.
Root cause        : the fix was committed on the release branch and the step that carries it to
                    main was never taken.
Why Git does this : branches are independent refs; nothing propagates a change between them.
Correct fix       : cherry-pick -x onto main, release as 1.5.1. No published ref moves.
Prevention        : a release gate that lists fixes on supported release branches missing from main.
```

<!-- snippet: final/solve-incident/03-repair -->
```text
$ git cherry-pick -x 5b81a41
[main 3043fc1] Allow a request that exactly reaches the budget
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:17:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format=%B HEAD
Allow a request that exactly reaches the budget

(cherry picked from commit 5b81a41a0cd58b19b0081534062b55ca030d259a)


 budget.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.5.1 -m "Release 1.5.1: budget fix from 1.4.1"
$ git push origin main v1.5.1
To ../server.git
   59e1918..3043fc1  main -> main
 * [new tag]         v1.5.1 -> v1.5.1
```
<!-- /snippet -->

<!-- snippet: final/solve-incident/04-verify -->
```text
$ git cherry -v main origin/release/1.4
- 5b81a41a0cd58b19b0081534062b55ca030d259a Allow a request that exactly reaches the budget
$ git describe main
v1.5.1
$ git for-each-ref --format='%(refname:short) %(objecttype) %(*objectname:short)' refs/tags
v1.4.0 tag 235a339
v1.4.1 tag 5b81a41
v1.5.0 tag 59e1918
v1.5.1 tag 3043fc1
$ cd ..
$ assessments/gen/final-incident/check.sh
Checking final-test lab incident
  ok    exactly one new commit sits on top of the commit released as 1.5.0
  ok    that commit records where the fix came from (cherry-pick -x)
  ok    budget.py on main has the fixed comparison
  ok    the new commit changes budget.py and nothing else
  ok    v1.5.1 on the server is an annotated tag
  ok    v1.5.1 names the new commit
  ok    the tag v1.5.0 has not moved
  ok    the tag v1.4.1 has not moved
  ok    release/1.4 has not moved
  ok    your main equals main on the server
  ok    nothing is staged, modified or untracked in your clone
  ok    no operation is left in progress
PASS: the end state of incident is right.
[exit status: 0]
```
<!-- /snippet -->

After the port `git cherry` marks the release commit with `-`: `main` has an equivalent patch.

Hand-in (4 points): 1 for evidence with interpretation, 1 for the box, 2 for the four lines. A model: "Release 1.5.0 reintroduced a budget bug that 1.4.1 had fixed; customers on 1.5.0 had requests refused at exactly the budget limit from Friday until 1.5.1. Root cause, Git and process: the fix was made on the release branch and never ported to `main`; Git does not carry commits between branches. The fix was copied to `main` with its origin recorded and released as 1.5.1; verified by comparing the patch sets of the two branches and by the tag pointing at the new commit; 1.5.0 was not changed. Prevention: the release job fails when a supported release branch has a fix that `main` lacks; owner and date." Moving `v1.5.0` fails the check and is the one thing the release manager asked not to do.

*Reference:* Chapter 27, sections 27.10 and 27.19; Chapter 10, sections 10.4, 10.9 and 10.10; Chapter 14B, section 14B.11; Chapter 30, section 30.15.

### 15.8

Model response.

1. **Stabilise (minutes).** Message to all: "Do not push to, pull from, or prune `main` until told. Do not run cleanup commands." Pause deployments and merges. SEV 2: a shared default branch held wrong content.
2. **Preserve.** In two or three clones, before any fetch: `git branch rescue/main-before origin/main`, and `git rev-parse origin/main`. The deployment at 11:00 recorded a commit ID: that is the candidate for the lost tip. On GitHub the Activity view shows the force push with the IDs before and after.
3. **Diagnose.** Agreement of three sources on the old tip: the 11:00 deployment record, `origin/main` in clones that fetched after 11:00 and before 11:20, and the "before" value of the force push in the Activity view. `git ls-remote origin main` for the present value. `git log --oneline <present>..<old tip>` lists the 23 commits; `git log --oneline <old tip>..<present>` must be empty (was anything pushed after the accident?). Why it was accepted: under a classic rule, administrators are not bound unless bypassing is disallowed.
4. **Recover.** From a clone that has the old tip: `git push --force-with-lease=main:<present value> origin <old tip>:main`. The lease guarantees that nothing pushed since the diagnosis is overwritten. If commits were pushed on top of the wrong state in the meantime, restore first and cherry-pick them after.
5. **Verify.** `git ls-remote origin main` equals the old tip; `git merge-base --is-ancestor <11:00 commit> origin/main` succeeds; the 23 commits are listed in `git log`; open pull requests show their expected commit lists; a new CI run on `main` is green.
6. **Communicate.** To the nine: "`main` is restored to `<short ID>`. If you fetched or pulled between 11:20 and 12:05, run `git fetch`, then `git status -sb`. If your `main` shows 'ahead', do not push; rebase your own commits onto `origin/main` with `git rebase --onto origin/main <old base>` or ask in the channel." To the CTO: the four parts.
7. **Prevent.** Replace the classic rule with a ruleset on the default branch: block force pushes and deletions, require pull requests, an empty bypass list or bypass "for pull requests only"; rulesets bind administrators unless they are on the bypass list. `gh ruleset check main` after the change. Personal habit for owners: no `--force` without a lease, and no pushes from a clone that has not fetched.

*Reference:* Chapter 30, sections 30.2, 30.6 and 30.15; Chapter 13, sections 13.10 and 13.15; Chapter 18, sections 18.5, 18.11, 18.14 and 18.19.

### 15.9

Model response, the eleven steps. Steps 1 to 6 change nothing.

1. **Inspect the state.** `git status -sb` in your clone, then what the pull request lists: every subject twice, the file view unchanged. Commit list and file view answer different questions.
2. **Inspect refs.** `git for-each-ref refs/heads refs/remotes` and `git ls-remote origin`: local, remote-tracking and server agree, so this is not a stale view.
3. **Inspect the reflogs.** The second author's branch reflog and `origin/feature/ranking-v2` reflog, read bottom-up: commits, "forced-update", then "pull: Merge made".
4. **Identify the old branch state.** The entry below the forced update is the tip before the rebase; the entry above it is the rebased tip.
5. **Understand what changed.** `git range-diff <old base>..<old tip> main..<rebased tip>` shows the rebased commits as `=` copies; `git log --cherry-mark --left-right <merge>^1...<merge>^2` shows which commits are duplicates and which are the second author's real work.
6. **Preserve.** `git branch rescue/ranking-merged <current tip>`, `rescue/ranking-rebased <rebased tip>`, `rescue/ranking-second-author <her tip before the pull>`.
7. **Determine the safest recovery.** Target: the rebased commits once, plus the second author's commits on top. Options: revert the merge (leaves duplicates in history), or rebuild the branch (a second forced push, coordinated). Choose the rebuild, announced, with a lease, because the pull request is unreviewable otherwise and both authors are reachable.
8. **Restore the correct history.** From the rebased tip: `git switch -c fix/ranking rescue/ranking-rebased`, `git cherry-pick <her real commits>` in order.
9. **Update the pull request safely.** Both authors stop pushing. `git push --force-with-lease=feature/ranking-v2:<current tip> origin fix/ranking:feature/ranking-v2`. The other author then resets to the new tip (`git fetch`, `git reset --keep origin/feature/ranking-v2` with her work already contained).
10. **Explain.** A note on the pull request: what happened, that no content changed (the range-diff), and what reviewers need to re-check. Approvals may have been dismissed.
11. **Prevent.** No rebase of a branch that someone else pushes to; if it must happen, announce it and the other person integrates with `git pull --rebase` only after checking, or `git rebase --onto`; `pull.ff=only` or `pull.rebase=true` in the team configuration so that a plain pull cannot create this merge silently.

Final history: `main`, then the rebased commits once, then the second author's commits. Award 2 for the read-only steps with the right evidence, 2 for the preserve step and the lease, 2 for a recovery that keeps both people's work, 2 for explain and prevent.

*Reference:* Chapter 30, sections 30.9 and 30.16; Chapter 9, sections 9.14, 9.15 and 9.17.

### 15.10

Model response.

1. **Stabilise.** Stop builds and releases that resolve `v3.2.0` by name. Ask that nobody "fixes" the tag in either direction.
2. **Preserve.** Record both commits. The server: `git ls-remote origin 'refs/tags/v3.2.0*'` (the line ending in `^{}` is the commit). An old clone or CI cache: `git rev-parse 'v3.2.0^{commit}'` and `git cat-file -p v3.2.0` (tagger and date of the original tag object). Give each a branch or a backup tag name in one clone.
3. **Diagnose.** Who has which: clones that fetched before Thursday have the old tag and keep it, because fetch creates missing tags and does not overwrite existing ones; a plain fetch does not even report the difference. Clones and builds made after Thursday have the new one. Wednesday's artifacts were built from the first commit, Friday's from the second.
4. **Recover.** A published tag is a promise about content. Put `v3.2.0` back on the commit it was published with (the original tag object if a clone still has it: `git push --force origin <old tag object ID>:refs/tags/v3.2.0`), and release the late fix under a new name: `git tag -a v3.2.1 <new commit>`, push. Rebuild and re-publish Friday's artifacts as 3.2.1.
5. **Verify.** `git ls-remote` shows the old commit for `v3.2.0` and the new one for `v3.2.1`; a fresh clone and an old clone agree after `git fetch --tags --force` in the clones that hold the moved tag; artifact checksums match their tags.
6. **Communicate.** Customers who installed "3.2.0" on Friday have 3.2.1 content: tell them, with checksums. Team: the exact command for clones with the moved tag.
7. **Prevent.** A tag ruleset on `v*`: block updates and deletions of existing tags; releases created from an annotated, already pushed tag with tag verification; the release job fails unless `git describe --exact-match` succeeds and the tag is new.

*Reference:* Chapter 14B, sections 14B.10, 14B.11 and 14B.13; Chapter 18, section 18.12; Chapter 30, sections 30.2 and 30.15.

### 15.11

Model response.

1. **First minute, to her.** "Do not run anything that cleans up: no `gc`, no `reflog expire`, no re-clone. Your commit is in your clone." This is SEV 3 or 4 at most, and it is my doing.
2. **Where it is.** In the reflog of her local branch, one entry below the pull: `git reflog show feature/audit-log`, the line before "pull --rebase (finish)". Also in the reflog of her `origin/feature/audit-log` as "update by push".
3. **Preserve.** `git branch rescue/audit-mine 'feature/audit-log@{1}'` (after checking the entry with `git log -1`).
4. **Mechanism.** `git pull --rebase` replays the commits after the fork point, and it finds the fork point in the reflog of her remote-tracking branch. Her commit had been the tip of that ref, because she had pushed it. My forced push removed it from the server; her fetch recorded a forced update; the fork-point logic then read her commit as "was upstream, upstream dropped it" and replayed nothing. Git cannot tell a deliberate drop from an overwrite.
5. **Recover.** No second rewrite: she runs `git cherry-pick rescue/audit-mine` on the current branch and pushes normally. Verify with `git log --oneline origin/feature/audit-log` and a look at the diff of her commit.
6. **Communicate.** To the others on the branch: check `git reflog show origin/feature/audit-log` for a forced update before your next pull.
7. **Prevent.** Habit: I do not rebase a branch that someone else pushes to without saying so first, and I fetch and read `git status -sb` before I rewrite. Configuration: never plain `--force`; `--force-with-lease` together with `push.useForceIfIncludes=true`, which would have rejected my push because her commit was on the server and not in my branch. On the platform, a rule that blocks force pushes on shared branches.

*Reference:* Chapter 9, sections 9.15 and 9.17; Chapter 12, section 12.8; Chapter 13, section 13.10.

### 15.12

Model answer. "Between 11:20 and about 12:05 today the main branch of the repository pointed at a two-week-old state; twenty-three merged changes were missing from it. Nothing was lost and nothing wrong was deployed: the 11:00 deployment was made before the accident and deployments were paused. Root cause, on the GitHub layer: the branch was protected by an older kind of rule that does not bind administrators, so a forced push from an owner's stale clone was accepted. We restored the branch from the commit the 11:00 deployment had recorded and verified that all twenty-three changes and every open pull request are as before. Not yet verified: whether any engineer still has the wrong state locally; they have instructions. Prevention: by Thursday the rule is replaced with a ruleset that blocks force pushes for everyone, administrators included; I own it."

Left out on purpose: every command, because a CTO decides about customers, residual risk and prevention, and commands help with none of them; the name of the person, because severity and learning must not depend on who it was; and speculation about what might have happened beyond the one sentence on what could have shipped.

Listen for: impact first, layer named, verified and not-verified separated, a control with owner and date, no names, no commands.

*Reference:* Chapter 30, sections 30.15 and 30.19.

---

## Section 16: Debugging

### 16.1

**Answer: C.** 0 is good, 1 to 127 except 125 is bad, 125 is "cannot be tested: skip", and anything else, such as 128 and above, aborts the bisection.

*Reference:* Chapter 14A, section 14A.21.

### 16.2

**Answer: B.** `-S` counts occurrences before and after; a move within a file leaves the count unchanged. `-G` matches the regular expression against the added and removed lines of each diff.

*Reference:* Chapter 14A, section 14A.11.

### 16.3

**Answer: B.** For `git log`, two dots is "reachable from the right and not from the left", three dots the symmetric difference. C describes `git diff`, where the dots mean something else; that the two commands differ is the documented confusion.

*Reference:* Chapter 14A, sections 14A.2 and 14A.8.

### 16.4

**Answer: A.** Blame names the last commit that changed each line as it now stands. A reformat, a move or a squash merge hides the origin; `-w`, `--ignore-rev`, `-M` and `-C` look through some of these, and the method continues with `git log -L` or the pickaxe.

*Reference:* Chapter 14A, sections 14A.16 to 14A.19.

### 16.5

<!-- snippet: final/s16/p1-answer -->
```text
$ git blame -s -L 2,3 price.py
581f817a 2)     base = tokens * 0.002
581f817a 3)     return round(base, 4)
$ git blame -s -w -L 2,3 price.py
^55abb25 2)     base = tokens * 0.002
^55abb25 3)     return round(base, 4)
$ git log --format='%h %an: %s'
581f817 Ravi Menon: Format with four spaces
55abb25 Asha Rao: Add the price function
```
<!-- /snippet -->

Without options both lines are attributed to Ravi's formatting commit, because it is the last commit that changed them. With `-w`, whitespace is ignored when comparing a line with its parent's version, so blame passes through the formatting commit to Asha's. The `^` marks a boundary commit (the root). For the team: list the formatting commit's full ID in a file such as `.git-blame-ignore-revs` and point `blame.ignoreRevsFile` at it.

Award 2 for the two attributions, 1 for the ignore-revs file.

*Reference:* Chapter 14A, section 14A.17.

### 16.6

<!-- snippet: final/s16/p2-answer -->
```text
$ git blame -s spaces.py
0e6d584c 1) def squash_spaces(s):
0e6d584c 2)     parts = s.split()
0e6d584c 3)     joined = " ".join(parts)
0e6d584c 4)     return joined.strip()
$ git blame -s -C spaces.py
^2b4e490 clean.py 1) def squash_spaces(s):
^2b4e490 clean.py 2)     parts = s.split()
^2b4e490 clean.py 3)     joined = " ".join(parts)
^2b4e490 clean.py 4)     return joined.strip()
$ git log --format='%h %an: %s'
0e6d584 Ravi Menon: Move squash_spaces into its own module
2b4e490 Asha Rao: Add text cleaning
```
<!-- /snippet -->

Plain blame attributes all four lines to Ravi's commit: for the new file `spaces.py` it is the commit that created the lines. With `-C`, blame also looks for lines that were moved or copied from other files changed in the same commit, finds them in `clean.py`, and continues there: Asha's commit, with the original file name in the output.

Award 2 for the attributions, 1 for the mechanism (`-M` within a file, `-C` across files of the same commit).

*Reference:* Chapter 14A, section 14A.18.

### 16.7

<!-- snippet: final/s16/g1-answer -->
```text
$ git bisect start HEAD v1.0
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[127f59944ba5ca51714646cf0e31ff5a7a8351ae] C4: add the exporter
$ git bisect run grep -q list tracker.yaml
running 'grep' '-q' 'list' 'tracker.yaml'
Bisecting: 1 revision left to test after this (roughly 1 step)
[8fda2fdab7aa56431b309a1d55d50695cfe4aa47] C6: add labels
running 'grep' '-q' 'list' 'tracker.yaml'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[a94939a7141aca9e7ec2ea29d65a4032f3f90bdf] C5: switch to a ring buffer
running 'grep' '-q' 'list' 'tracker.yaml'
a94939a7141aca9e7ec2ea29d65a4032f3f90bdf is the first 'bad' commit
commit a94939a7141aca9e7ec2ea29d65a4032f3f90bdf
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:27:00 2026 +0530

    C5: switch to a ring buffer

 step.txt     | 2 +-
 tracker.yaml | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
bisect found first 'bad' commit
$ git bisect log | grep "^git bisect"
git bisect start 'HEAD' 'v1.0'
git bisect good 127f59944ba5ca51714646cf0e31ff5a7a8351ae
git bisect bad 8fda2fdab7aa56431b309a1d55d50695cfe4aa47
git bisect bad a94939a7141aca9e7ec2ea29d65a4032f3f90bdf
$ git bisect reset
Previous HEAD position was a94939a C5: switch to a ring buffer
Switched to branch 'main'
```
<!-- /snippet -->

```text
  C1 --- C2 --- C3 --- C4 --- C5 --- C6 --- C7 --- C8
  good                 1st    3rd    2nd           bad
  (given)              good   bad    bad           (given)
```

Seven candidates (C2 to C8). Three tests: C4 good, C6 bad, C5 bad, and C5 is the first bad commit because its parent C4 is good. A binary search over seven candidates needs about three steps; over five hundred it needs about nine.

Award 2 for the three commits in order with verdicts, 1 for the counts.

*Reference:* Chapter 14A, sections 14A.20 and 14A.21.

### 16.8

(a) A cherry-pick of two commits. The first, "Widen the fence", stopped with a content conflict in `fence.yaml`; no commit has been created yet. (b) `CHERRY_PICK_HEAD` names the commit being picked: it is the sign that a cherry-pick is in progress and supplies the message and author for the commit to come. The directory `sequencer` exists because more than one commit was requested; it holds the rest of the plan. (c) The todo still lists the current pick and the next one: after the conflict is resolved and staged, `git cherry-pick --continue` commits the first and goes on to "Support polygons". (d) `--continue` after resolving: both commits end up on the branch. `--skip`: drop the current commit and go on with the next. `--abort`: return the branch to the state before the command, discarding the resolution in progress. `--quit`: forget the operation and leave HEAD, index and files as they are now, including the half-resolved file.

*Reference:* Chapter 10, sections 10.5 to 10.7; Chapter 29, section 29.6.

### 16.9

(a) A merge of two versions of the same branch. The right-hand side is the branch as it was rebased onto the new `main` and force-pushed; the left-hand side is Asha's local branch, which still had the original two commits plus her own. The rebase gave the two commits new IDs, so Git sees four commits where a person sees two. (b) `=` marks commits whose patch exists on both sides: the two pairs of duplicates. `<` is only on Asha's side: "Compress the tiles", her real work. `>` is only on the other side: "Add a health endpoint", which came from `main` through the rebase. (c) "forced-update": the remote-tracking branch was replaced with a commit that did not descend from the previous one. The server's branch had been rewritten before she pulled. (d) Look before integrating after a forced update; then replay only her own commit onto the new tip: `git rebase --onto origin/feature/vector-tiles <the old upstream tip>` or `git reset --keep origin/feature/vector-tiles` followed by a cherry-pick of her commit. A clean branch: the tile server, the health endpoint, the two rebased commits once, then "Compress the tiles".

*Reference:* Chapter 9, section 9.15; Chapter 10, section 10.10; Chapter 14A, section 14A.14; Chapter 30, section 30.9.

### 16.10

Git's date parser took the missing time of day from the clock: `--since=2026-09-10` was read as "10 September at 12:51" and `--until=2026-09-11` as "11 September at 12:51". The same parser serves "yesterday" and "2 days ago", which are meant relative to now. So the morning of the 10th is before the window and the morning of the 11th is inside it.

Corrected: `git log --since='2026-09-10 00:00' --until='2026-09-11 00:00' --oneline`. Rule: in scripts and incident notes always write a full timestamp and state the time zone. Also remember that these options filter by committer date, and that rebased or cherry-picked commits carry a newer committer date than their author date.

*Reference:* Chapter 14A, section 14A.9; Chapter 6, section 6.5.

### 16.11

Every Git command reads the whole configuration before it does anything, and a parse error in a file it must read is fatal: running with half a configuration could mean the wrong identity, the wrong remote or a skipped safety setting. Objects, refs, the index, reflogs and the unpushed branches are intact; one line of one text file is not valid syntax (typically a hand edit, such as a section header without its closing bracket).

Repair: open `.git/config` at line 19 with a text editor, not with Git, and correct the line; `git config list --local` then proves that the file parses. Do not delete `.git`: that would destroy the only copy of the unpushed branches to fix a typo. Habit: change settings with `git config set`, and run `git config list` after any hand edit.

*Reference:* Chapter 14B, section 14B.3.

### 16.12

The message says only that the program Git started for the other side (`ssh`, or `git-upload-pack` for a local path) exited before the Git conversation began. The two reasons it offers are a hint, the most common ones, and people read the hint as a diagnosis. The cause is in the line above, written by `ssh`, by the server, or by Git's own check of a path: "Permission denied (publickey)", "Host key verification failed", "Could not resolve hostname", "Repository not found" each point somewhere else.

When there is no line above, run the transport alone: `ssh -vT git@github.com` (which key is offered, which account answers), and `git remote -v` for the URL actually used. In tickets: the whole error output, never only the last line, plus the output of `git remote -v`.

*Reference:* Chapter 16, sections 16.17 and 16.18.

### 16.13

Model solution, as a replay of the lab. Nine commits lie between the tag and `main`, one of them a merge.

<!-- snippet: final/solve-debugging/01-observe -->
```text
$ cd latencylab
$ git status -sb
## main
$ sh check-p95.sh
worst case: 2350 ms
[exit status: 1]
$ git log --oneline --graph
* 4aac260 Pass a trace context to the client
* 16a2b21 Raise the timeout to 450 ms
* bb3e0e2 Add README
*   d0e5be0 Merge feature/second-region
|\  
| * 44c8fde Add region failover
| * b130940 Tune client defaults for the new region
| * bf9e7ed Add the second region
* | f887a94 Add the p95 calculation
|/  
* c015516 Add a latency histogram
* 38efb61 Add the client wrapper
* 2d970a4 Add the client configuration and the p95 check
$ git rev-list --count v1.0..main
9
```
<!-- /snippet -->

<!-- snippet: final/solve-debugging/02-bisect -->
```text
$ git bisect start main v1.0
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[44c8fde9e4278a6e275f125d01d8062be12ac26e] Add region failover
$ git bisect run sh check-p95.sh
running 'sh' 'check-p95.sh'
worst case: 2200 ms
Bisecting: 1 revision left to test after this (roughly 1 step)
[bf9e7ed45d95d16a3a0057f6195637dec17a83ab] Add the second region
running 'sh' 'check-p95.sh'
worst case: 1400 ms
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[b1309404ad1a921744ce25a7e5cefe62583b579e] Tune client defaults for the new region
running 'sh' 'check-p95.sh'
worst case: 2200 ms
b1309404ad1a921744ce25a7e5cefe62583b579e is the first 'bad' commit
commit b1309404ad1a921744ce25a7e5cefe62583b579e
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:09:00 2026 +0530

    Tune client defaults for the new region

 config/client.yaml  | 2 +-
 config/regions.yaml | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
bisect found first 'bad' commit
$ git bisect log | grep "^git bisect"
git bisect start 'main' 'v1.0'
git bisect bad 44c8fde9e4278a6e275f125d01d8062be12ac26e
git bisect good bf9e7ed45d95d16a3a0057f6195637dec17a83ab
git bisect bad b1309404ad1a921744ce25a7e5cefe62583b579e
$ git bisect reset
Previous HEAD position was b130940 Tune client defaults for the new region
Switched to branch 'main'
```
<!-- /snippet -->

Three tests. The first bad commit is inside the merged branch and has a harmless subject. The on-call engineer's suspect also changes the numbers, but the check already fails at its parent:

<!-- snippet: final/solve-debugging/03-cause -->
```text
$ git show --stat --format='%h %an: %s' b130940
b130940 Lab User: Tune client defaults for the new region

 config/client.yaml  | 2 +-
 config/regions.yaml | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git show b130940 -- config/client.yaml
commit b1309404ad1a921744ce25a7e5cefe62583b579e
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:09:00 2026 +0530

    Tune client defaults for the new region

diff --git a/config/client.yaml b/config/client.yaml
index 4413bf2..46eb3d8 100644
--- a/config/client.yaml
+++ b/config/client.yaml
@@ -1,3 +1,3 @@
 timeout_ms: 400
 retries: 2
-backoff_ms: 100
+backoff_ms: 500
# The suspect, tested alone: its parent fails already.
$ git log --oneline -1 --grep="Raise the timeout"
16a2b21 Raise the timeout to 450 ms
$ git show HEAD~2:config/client.yaml
timeout_ms: 400
retries: 2
backoff_ms: 500
```
<!-- /snippet -->

<!-- snippet: final/solve-debugging/04-repair -->
```text
$ git revert --no-edit b130940
Auto-merging config/client.yaml
[main 05b266d] Revert "Tune client defaults for the new region"
 Date: Mon Sep 7 10:31:00 2026 +0530
 2 files changed, 1 insertion(+), 2 deletions(-)
$ git show --stat --format=%B HEAD
Revert "Tune client defaults for the new region"

This reverts commit b1309404ad1a921744ce25a7e5cefe62583b579e.


 config/client.yaml  | 2 +-
 config/regions.yaml | 1 -
 2 files changed, 1 insertion(+), 2 deletions(-)
$ sh check-p95.sh
worst case: 1550 ms
[exit status: 0]
$ cat config/client.yaml
timeout_ms: 450
retries: 2
backoff_ms: 100
$ cd ..
$ assessments/gen/final-debugging/check.sh
Checking final-test lab debugging
  ok    HEAD is on main
  ok    no bisection or other operation is left in progress
  ok    main still contains everything it had (nothing was rewritten)
  ok    a new commit on main says which commit it reverts, and it is the first bad one
  ok    check-p95.sh is unchanged
  ok    the p95 check passes on main (worst case 1550 ms)
  ok    the later commit "Raise the timeout to 450 ms" is still in effect
  ok    the second region is still configured
  ok    nothing is staged, modified or untracked
PASS: the end state of debugging is right.
[exit status: 0]
```
<!-- /snippet -->

The revert touches a line that a later commit's neighbor changed, and still applies: one unchanged line lies between them. The raised timeout stays; the worst case is 1550 ms.

Hand-in (4 points): 1 for the counts (9 commits, 3 tested), 1 for the ID and subject of the first bad commit, 2 for the sentence about the suspect ("raising the timeout to 450 alone gives 1550 ms, which passes; the check fails at its parent already, because the backoff had been raised from 100 to 500 earlier, inside the merged branch"). Finding the commit by reading diffs earns the end-state points if the check passes and none of the two points for method. Reverting "Raise the timeout" fails the check.

*Reference:* Chapter 14A, sections 14A.19 to 14A.22; Chapter 11, section 11.8.

### 16.14

Model answer. The ritual: `git status` (where am I, what is uncommitted, is an operation in progress); `git branch -vv` (which branches exist and what each follows, ahead and behind); `git remote -v` (which repositories this one talks to); `git log --graph --decorate --oneline --all` (the shape of history and where every ref is); `git reflog` (what was done here, in which order); `git rev-parse` (which exact object a name stands for); `git show` (what is in a commit); `git diff` and `git diff --cached` (working tree against index, index against HEAD); `git config list --show-origin --show-scope` (which settings are in effect and from which file); `git ls-files` (what Git tracks). I run them every time and in that order, because under pressure people skip the one command that would have shown the cause.

Before the root cause is named I allow only commands that read state or add a ref. Not allowed: anything that moves a ref (`reset`, `rebase`, `pull`, `commit --amend`), overwrites the working tree (`restore`, `checkout <path>`, `clean`, `stash drop`, any `--abort`), talks to the server in a changing way (`push`, and `fetch --prune`, which deletes evidence), or removes the safety net (`gc --prune`, `reflog expire`). The reason: most damage in Git incidents is done by a command typed before the state was understood, and several of these destroy the evidence I need.

Listen for: the list with a question per command, both diffs, and "read or add only".

*Reference:* Chapter 1, sections 1.10 and 1.11; Chapter 29, sections 29.2 and 29.9.

---

## Section 17: Architecture

### 17.1

**Answer: A.** No strategy is best; the reputable sources tie the choice to context, and these two questions come first. One live version deployed continuously needs one long-lived branch; several supported versions need a line per version.

*Reference:* Chapter 27, section 27.14.

### 17.2

**Answer: C.** Rulesets have no priority. Every active ruleset that targets the ref, and the classic rule that matches it, are aggregated, and for a rule defined in several ways the most restrictive version applies. A, B and D assume an order that does not exist.

*Reference:* Chapter 18, section 18.4.

### 17.3

**Answer: D.** A ruleset applies to everyone, administrators included, except the actors on its bypass list. The Maintain role's "push to protected branches" applies to classic rules only. A to C are the "admins and maintainers can always push to a protected branch" model.

*Reference:* Chapter 18, section 18.5.

### 17.4

**Answer: D.** In CODEOWNERS the last matching pattern wins, and `*` matches everything, so a general line after a specific one takes over. The file only requests reviews until a rule requires code owner review. Put general lines at the top.

*Reference:* Chapter 19, sections 19.5, 19.6 and 19.12.

### 17.5

**Answer: C.** Every commit and tree, so history queries work; blobs on demand; only the cone on disk. GitHub's own guidance reserves shallow clones for throwaway CI. `scalar clone` sets this combination up.

*Reference:* Chapter 24, sections 24.4 and 24.7; Chapter 26, sections 26.11 to 26.13.

### 17.6

No transcript belongs to this item; the letters are free.

```text
  fix on main first, cherry-pick down:

    A---B---C---D---F---G            main          F = the fix, made and reviewed on main
             \       .
              \       .  git cherry-pick -x F
               \       v
                R1------F'           release/1.4
                ^       ^
              v1.4.0  v1.4.1         annotated tags; neither ever moves

  F and F' have the same change and different commit IDs. The message of F' ends with
  "(cherry picked from commit <ID of F>)", written by the option -x.
```

Merge upward, in one line: the fix is committed once on `release/1.4`, tagged `v1.4.1`, and `release/1.4` is then merged into `main`; `main` contains the same commit, with the same ID, through a merge commit, and nothing is copied.

Award 1 for the two lines and tags, 1 for the direction and `-x`, 1 for the contrast (one ID and a merge, against two IDs and a trailer). A drawing that merges `main` into the release branch ships unreleased features in a patch release and earns nothing.

*Reference:* Chapter 27, sections 27.8 to 27.10; Chapter 10, sections 10.4 and 10.9.

### 17.7

Two settings must both allow a method: the repository's own merge-method settings and the `allowed_merge_methods` of every pull request rule that applies. The repository allows only squash; the organization ruleset allows only merge commits; the intersection is empty. Relaxing the repository's ruleset does not help because rulesets layer: the organization ruleset still applies, and a repository ruleset can add restrictions and never subtract.

Repairs: enable merge commits in the repository settings (and accept merge commits on `main`), or change the organization ruleset to allow squash. Decide which history the organization wants first. To prevent drift: keep rulesets and repository settings as files in an infrastructure repository and change both in the same reviewed pull request; run a new organization ruleset in evaluate mode and read the insights before making it active.

*Reference:* Chapter 18, sections 18.3, 18.4, 18.13 and 18.19.

### 17.8

Causes: (1) the team has no explicit write access to the repository (an owner must be able to write); (2) the team is a secret team, which cannot be a code owner; (3) the name is misspelled, or the path's case does not match the repository (`Models/`); also possible: a later, more general line overrides the entry, or the edited file is not the one GitHub uses (there is more than one CODEOWNERS file, and `.github/` is searched first).

API call: `gh api repos/OWNER/REPO/codeowners/errors`. Fixes: grant the team write access; make the team visible; correct the name or the path (compare with `git ls-files`); move general lines to the top; keep one file, in `.github/`.

A pull request is judged by the CODEOWNERS file on its base branch. A fix on a feature branch changes nothing for pull requests into `main` until the fix itself is merged, and the pull request that carries the fix is reviewed under the old file.

*Reference:* Chapter 19, sections 19.3, 19.5, 19.7, 19.11 and 19.12.

### 17.9

Model response.

1. **Establish.** For each of the two merges: the pull request timeline (who approved, who merged, when), the diff that landed (`git show --stat <merge or squash commit>`), whether CI ran on it, and whether anything after it corrected it. Classic rules do not bind people with admin permissions unless bypassing is disallowed, which is how it was possible without any trace beyond the merge itself. Severity by what could have happened: unreviewed code on a payments production branch, SEV 2.
2. **Review the two changes now**, by someone other than the author, and record the result.
3. **Target design.** A ruleset on the production branch, active, replacing the classic rule: block force pushes and deletions; require a pull request with at least one approval by someone other than the last pusher, stale approvals dismissed, code owner review required; required status checks with one aggregate check; allowed merge methods as the team decided. Bypass list: empty, or an on-call team with the mode "for pull requests only", so that even a bypass goes through a pull request and leaves a record in the pull request and the audit log. Never the exempt mode, which leaves none. CODEOWNERS covers `/.github/` and the CODEOWNERS file itself, owned by a team, so that the rules and the workflows cannot be weakened by the people they constrain.
4. **Emergency at 03:00.** The on-call engineer opens a pull request with the fix; a second on-call person approves (an on-call pair exists for this), or, if the bypass mode is configured, the engineer merges with a bypass that is recorded and reviewed the next morning as a standing rule. The deployment still goes through the environment's rules.
5. **Verify.** `gh ruleset check <branch>` lists the rules that apply; a test pull request by an administrator cannot be merged without review; a direct push by an administrator is refused; Rule Insights shows the evaluation; the classic rule is gone, so only one mechanism remains.
6. **Communicate.** Four parts to the auditor and the CTO; the control has an owner and a date.

*Reference:* Chapter 18, sections 18.5, 18.7, 18.14, 18.16 and 18.18; Chapter 19, section 19.8; Chapter 30, sections 30.3 and 30.15.

### 17.10

Model answer. The company is in three rows of the decision table at once: a continuously deployed service, several supported versions, and an audit. So: one integration branch, `main`, with short-lived feature branches and feature flags for unfinished work; the hosted API deploys from `main`. For the on-premises edition a release branch per supported version, `release/x.y`, cut late from `main`, receiving fixes only; fixes are made on `main` first and cherry-picked down with `-x`, and the release job has a gate that lists fixes on a release branch that `main` lacks. Releases are annotated tags created from the release branch, semantic versions, never moved; a tag ruleset blocks updates and deletions.

Protection: rulesets on `main` and on `release/**/*` forms that match the names in use: pull request required, approval by someone other than the last pusher, code owners for sensitive paths, one aggregate required check, no force pushes or deletions, bypass only "for pull requests", so that the audit can read who approved what. Merge method: squash on `main` for a linear, revertible history, knowing that the unit of undo and of bisect is then the pull request, so pull requests stay small. Two risks to watch: a fix that never travels between lines, and review latency turning the required approval into a rubber stamp; also retire old release branches on a schedule.

Listen for: the two questions, fix direction with a gate, immutable tags, rulesets with visible bypass, and named costs.

*Reference:* Chapter 27, sections 27.8 to 27.14; Chapter 18, sections 18.12 and 18.18; Chapter 14B, sections 14B.11 and 14B.13.

### 17.11

Model answer. For: one commit and one review can change a library and all its users, so there is no version drift between internal components and no merge order across repositories; refactoring across boundaries is possible; one set of tooling, rules and CI conventions. Against: Git has no per-directory read permission, so everyone who can clone reads everything; a broken `main` blocks everybody, so the failure radius grows; and CI must compute what a change affects, which needs a dependency-aware build system and people who maintain it. Ownership needs path-based rules (CODEOWNERS), and releases and versions per component have to be designed.

Workable with: blobless partial clone and cone-mode sparse checkout (what `scalar clone` configures), the sparse index, automatic and scheduled maintenance, commit-graph, the file-system monitor and untracked cache for very wide trees; in CI, full-depth or blobless clones for jobs that compare against a base, because a shallow clone cannot compute a merge base. What Git cannot give: read access control inside one repository. If two of the fourteen repositories have different audiences, they stay separate.

Listen for: atomic change against access control and failure radius, the performance features by name, and the limit.

*Reference:* Chapter 24, sections 24.2 to 24.9; Chapter 26, section 26.15.

### 17.12

Model answer. Decision rule, in order. If the library is or can be published as a package with versions, use the package manager: it solves versioning, transitive dependencies and advisories, which neither Git mechanism attempts, and the consumer records a name and a version in a manifest and a lock file. If it is not a package and must be present after a plain clone, a subtree: the files are in the consumer's own history. If it must remain a separate repository with its own access rules or release cadence, and the team adopts the configuration that makes it bearable (`submodule.recurse`, a push check for submodule commits), a submodule. If the real wish is one atomic commit across both, they belong in one repository.

For a tokenizer used by three teams: a package. The option I reject most firmly here is the submodule, for the failures it produces by default: an empty directory after a plain clone, a pointer that moves on pull while the checked-out commit does not, so that an unthinking `git add -A` rolls the library back for everyone; a superproject commit pushed before the submodule commit it names, which a colleague then cannot fetch; and work done on the detached HEAD that `update` leaves.

Listen for: the three things each option records (commit ID and URL, files, name and version), a rule, and concrete failure states.

*Reference:* Chapter 23, sections 23.2, 23.5, 23.7, 23.8 and 23.14.

### 17.13

Model answer. A release is an annotated tag: its own object with tagger, date and message, optionally signed, which `git describe` uses by default. It is created by the release procedure, not by hand in a web form, on a commit that is already on the release line and has passed the release checks; the tag is pushed first and the platform release is created from the existing tag with verification, because a release created for a missing tag makes a lightweight tag at whatever the branch tip is. The number follows Semantic Versioning: a patch release contains fixes only, a minor release adds compatible features, a major release may break; a version number is never reused.

A published tag must not move because a tag name is a promise about content. Fetch creates missing tags and does not overwrite existing ones, and a plain fetch does not report a difference, so after a move some clones, caches and builds have the old commit and some the new one, under one name, and nobody is warned. A mistake is corrected with a new version. Enforcement: a tag ruleset on the version pattern that blocks updates and deletions; a release job that fails unless `git describe --exact-match` finds the tag on the commit being built; and no person with a bypass.

Listen for: annotated, tag first, the promise, "fetch does not overwrite", and a server-side rule.

*Reference:* Chapter 14B, sections 14B.8 and 14B.10 to 14B.13; Chapter 15, section 15.12; Chapter 18, section 18.12.

---

## Section 18: CTO interview

Mark each answer on four points: correct, mechanism named, exact terminology, production judgment. Each entry gives the model answer, what to listen for, and the follow-up to ask.

### 18.1

Model answer. A commit is a complete snapshot of the project: it names one tree, and the tree names every file by the hash of its content. A commit that changes two files out of a thousand creates two new blobs and reuses the rest, which is why snapshots are cheap. A diff is something Git computes when you ask, from two snapshots. Inside packfiles Git also stores similar objects as deltas of each other, but that is compression: it is chosen by similarity and not by history, and nothing in the model depends on it.

History length alone rarely makes daily work slow. What does: the number of tracked files that every `status` has to examine; large binary content in history, which every full clone downloads in every version; very many refs, which every fetch has to compare; many loose objects or packs when maintenance does not run; and commands that walk all history without the commit-graph. The remedies are specific to the dimension: partial and sparse clones, keeping large files out, maintenance, and measuring before tuning.

Listen for: snapshot, content addressing, "delta is storage", and the dimensions of size. Follow-up: "Then why does `git log -- <path>` get slower over the years, and what helps?" (It walks commits and compares trees; the commit-graph with changed-path filters.)

*Reference:* Chapter 2, sections 2.3 and 2.4; Chapter 3, section 3.7; Chapter 26, sections 26.2 and 26.6.

### 18.2

Model answer. My clone: a new commit object A' with the same parent as the original A, a new committer time and, if I changed anything, a new tree. `refs/heads/<branch>` points at A'. A still exists and is named by my reflog and by `refs/remotes/origin/<branch>`. `git status` says ahead 1, behind 1. The server: its branch points at A; it has never heard of A'. The colleague's clone: A, possibly with their own commits on top.

Ways out, by risk. Lowest: publish only the difference. Keep A' under a rescue name, move my branch back to the server's tip with `git reset --keep`, apply the difference between A and A' as a new commit, push. Nothing published changes. Middle: rebase A' onto the server's tip or pull with rebase; I resolve a conflict of A against A' and end with one extra commit; nothing published changes, and the trap is taking whole files from A' and deleting a colleague's later change. Highest: `git push --force-with-lease`, replacing A with A' on the server. Acceptable only when nobody has built on A, which I check, and announce; everyone who fetched A must then reset. I do not use a plain pull that merges A and A': it publishes both versions of one commit.

Listen for: two objects with one parent, the three refs, "ahead 1, behind 1", and a ranking that starts with adding. Follow-up: "What if the amend was to remove a password?" (Rotate first; then it is an incident, not an undo.)

*Reference:* Chapter 6, section 6.7; Chapter 11, sections 11.7 and 11.13; Chapter 12, section 12.8.

### 18.3

Model answer. For `git log`, the dots select sets of commits. `A..B` is the commits reachable from B and not from A: "what B has that A lacks". `A...B` is the symmetric difference: commits reachable from either and not from both, which with `--left-right` shows what each side has alone. For `git diff`, the dots select two snapshots. `A..B` is the same as `A B`: the tree of A against the tree of B. `A...B` compares the merge base of A and B with B: "what B changed since it forked".

A pull request lists commits as `base..head`, the log meaning, and shows files as `base...head`, the diff meaning. The misunderstanding: a reviewer who runs `git diff main..feature` locally sees everything `main` gained since the fork displayed as deletions by the feature; and after a squash merge the commit list shows old commits again while the file view looks unchanged, so two reviewers describe the same pull request differently.

Listen for: sets of commits against pairs of trees, the merge base, and the pull request mapping. Follow-up: "Which spelling do you put in a script?" (`git diff --merge-base A B`, explicit.)

*Reference:* Chapter 14A, sections 14A.2 and 14A.8; Chapter 17, section 17.3.

### 18.4

Model answer. Questions first: what was the branch called, was it ever pushed, what was the last thing you did, and has anything like `gc`, a cleanup script or a re-clone happened since? Then, read-only, in order. `git status` and `git branch -a`: am I in the right repository and worktree, is the branch only renamed, or is HEAD detached in the middle of a rebase. `git reflog`: the HEAD reflog almost always has "checkout: moving from <branch>" and the commits made on it; the newest of those is the tip. `git branch -r` and `git ls-remote origin`: is it on the server. If the reflog has it: `git branch <name> <entry>`, one command that adds a ref, then verify with `git log`. If the reflog is empty or expired: `git fsck --lost-found` and look at dangling commits. If a colleague fetched it: their remote-tracking branch. On GitHub, a branch that had a pull request can be restored from the pull request page.

I stop and say "gone" when the work was never committed or staged, or when the clone that held it was deleted and it was never pushed, or when the reflogs were expired and a prune has run. I say which of those it is.

Listen for: questions before commands, the HEAD reflog, "add a ref", and an honest end. Follow-up: "They used `git branch -D` and then `git gc`. Still recoverable?" (Yes by default: `gc` keeps what reflogs reach and prunes only old unreachable objects.)

*Reference:* Chapter 13, sections 13.7, 13.8, 13.12 and 13.15; Chapter 29, section 29.2.

### 18.5

Model answer. Forbidden on every shared line: the default branch, release branches, any branch that deploys, and release tags. Enforced on the server by rulesets that block force pushes and deletions for those patterns, with an empty bypass list or bypass through pull requests only, and by a tag ruleset; not by trust and not by client hooks. Allowed on a branch that one person pushes to, typically their own pull request branch, for rebasing and cleaning history before review. Form: never plain `--force`; `--force-with-lease` together with `--force-if-includes`, set once in the shared configuration (`push.useForceIfIncludes=true`), and for anything risky the explicit form `--force-with-lease=<branch>:<expected commit>`. On a branch that two people push to: no rewriting without saying so first, and the other person does not pull blindly after a "(forced update)".

Around it: the team knows that a force push deletes nothing, so recovery is routine, from the pusher's reflog, another clone, or the platform's activity record; and that rewriting a pull request branch may dismiss approvals. The exception process for a real need, such as purging a secret after rotation, is a planned operation with a freeze and re-clones, not a personal decision.

Listen for: server-side enforcement per branch class, the two-flag form and why, and what happens to reviews. Follow-up: "Why is the lease alone not enough?" (A background fetch renews it.)

*Reference:* Chapter 12, section 12.8; Chapter 18, sections 18.5, 18.11 and 18.12; Chapter 21B, section 21B.16.

### 18.6

Model answer. A commit object contains the ID of its parent. The same change on another branch has another parent, usually another tree, and a new committer line, so it is a different object with a different ID. Mechanically a cherry-pick is a three-way merge whose base is the picked commit's parent; the result is committed as a new commit that copies the author and message.

Consequences. Git records no link between the two commits, so `git branch --contains <original>` does not list the branch that has the copy, and "is the fix in the release" cannot be answered by ancestry. It is answered by patch equivalence (`git cherry`, `git log --cherry-mark`) or by the trailer that `-x` writes, which is why backports are always made with `-x`. When the two branches are merged later, Git sees the same change on both sides: identical changes merge cleanly, but if either copy was adjusted, or later commits touched the same lines, the merge conflicts on work that is "already there", and history shows the change twice. Rebase skips commits whose patch is already upstream; merge has no such step.

Listen for: the parent is part of the hashed object, three-way merge, patch-id against ancestry, `-x`. Follow-up: "How do you find fixes on a release branch that never reached `main`?" (`git log --cherry-pick --right-only --no-merges main...release/x`.)

*Reference:* Chapter 10, sections 10.2 to 10.4 and 10.10; Chapter 2, section 2.10.

### 18.7

Model answer. Two people start from the same version of a document and each edits a copy. To combine them you need three versions: the common starting point and the two results. For every region of the text you ask who changed it since the start. Changed by one person only: take that change. Changed by both in the same way: take it. Changed by both differently: stop and ask a human. Git does this for every file, with the commit both branches descend from as the starting point.

A conflict a person would not report: two edits on neighboring lines with no unchanged line between them. Git treats them as one region changed by both sides, although the edits are independent. A wrong result without a conflict: one branch renames a function and updates all callers; the other adds a new caller of the old name in another file. No region was changed by both, the merge is clean, and the program is broken. Git merges text; it does not parse or run it. That is why the thing to test is the merge result.

Listen for: base, ours, theirs; the rule table; hunks and adjacency; "clean is not correct". Follow-up: "Which side is 'ours' during a rebase?" (The branch being rebased onto.)

*Reference:* Chapter 8, sections 8.4, 8.7 and 8.15; Chapter 9, section 9.11.

### 18.8

Model answer. Gain: every commit that lands on `main` was created by the holder of a key registered with an account. That removes cheap impersonation, since author fields are otherwise text anyone can set, and it anchors the audit trail. No gain: a signature does not say the change is correct, reviewed or benign, and it says nothing about artifacts built elsewhere. An authorized insider signs perfectly. And verification on the platform is recorded at the time it was done.

What stops working on the first day. Every contributor needs signing set up on every machine and the public key registered as a signing key; unsigned commits on a head branch block the merge, including a squash merge, because the rule is evaluated against the commits a pull request introduces. "Rebase and merge" cannot satisfy the rule at all, because the platform creates new commits it cannot sign for you. Bots and automation need an identity that signs. Rebased or amended commits lose their signatures unless they are re-signed. So I would announce it, give people a week with vigilant mode and local verification, decide the merge method with the rule in mind, and switch it on in evaluate mode first.

Listen for: what a signature proves, the squash and rebase consequences, bots, and a rollout. Follow-up: "SSH or GPG, and what does a verifier need for SSH?" (An allowed-signers file; without it Git reports no signature status.)

*Reference:* Chapter 14B, sections 14B.15 to 14B.18; Chapter 18, section 18.10; Chapter 21B, sections 21B.6 and 21B.7.

### 18.9

Model answer. Measure first: is the time in transfer, in checkout, or in LFS. Then, cheapest first. A shallow clone of depth 1: one commit, minutes saved at once; it breaks every job that asks history a question: `git describe` for versions, a diff or merge base against the base branch, blame, changelogs. Fetch only the branch and no tags: little risk for a build. A blobless partial clone: all commits and trees, file content on demand; history questions work, and a job that touches many old blobs pays for them one by one. Sparse checkout on top: only the directories the job builds are written to disk; it breaks scripts that walk the directory tree expecting everything. Reuse: a persistent runner or a cached mirror that is fetched into, instead of a fresh clone per job; it needs hygiene so that a stale checkout is never built. Then the repository itself: find what the nine gigabytes are with the object-size pipeline; large binaries move to LFS or an artifact store for the future; a history rewrite to remove them is the most invasive option, a coordinated operation with new commit IDs for everyone. Server-side repacking can also shrink a repository without rewriting it.

Listen for: per-job choice by the question the job asks, blobless as the default for history, and "rewrite last". Follow-up: "Why can a shallow clone not tell you what changed in a pull request?" (No merge base inside the boundary.)

*Reference:* Chapter 26, sections 26.2, 26.11 to 26.13 and 26.15; Chapter 24, section 24.9; Chapter 20A, section 20A.8.

### 18.10

Model answer. Minute zero: revoke or rotate the credential at its issuer. Three weeks and forty collaborators mean it is disclosed; private is an access list, not secrecy. Then assess, in writing: what the credential can reach; the first commit that contains it and when it was pushed (`git log --all -S`); which branches, tags and pull requests contain it; who could read it, including forks, CI logs and anyone who has left since; and whether it was used, which only the issuer's logs can tell. Raise the severity to the top until the logs say otherwise, and tell security and the CTO now, not after the cleanup.

Then: remove it from the current code and deploy the new credential to the services that need it; look for the same credential elsewhere; decide about history. With the credential dead, a history rewrite of a forty-person repository costs more than it buys, unless the same commits expose something that cannot be rotated. I would not spend the first thirty minutes on deleting the file, rewriting history, making anything private, or finding out who did it. Afterwards: push protection, scanning in pre-commit and CI, secrets in a store, short-lived credentials.

Listen for: rotate first and why, the five facts, issuer logs, a reasoned "no rewrite". Follow-up: "After a rewrite the scanner finds it on `main` again the next day. Why?" (A stale clone merged the old history back and pushed a fast-forward.)

*Reference:* Chapter 21B, sections 21B.10, 21B.14, 21B.16 and 21B.18; Chapter 30, section 30.17.

### 18.11

Model answer. Git's object database only grows during normal work: every add and commit writes objects, and rewrites leave the old ones behind. Garbage collection is the housekeeping that packs loose objects into packfiles, packs refs, expires old reflog entries by the retention settings, and deletes objects that nothing reaches and that are older than a grace period. It is triggered automatically after commands that add many objects, through `git maintenance run --auto`, and can be scheduled; on current Git the default strategy packs incrementally and keeps young unreachable objects in a cruft pack.

What it never does by default is delete something a ref, the index or a reflog still reaches. So the commands I forbid are the ones that remove those protections: `git reflog expire --expire=now --all`, which deletes the record of where every ref has been, and `git gc --prune=now` or `git prune`, which removes the grace period. Together they are the point of no return for every commit that was only reachable through a reflog, and on a shared server they destroy the evidence of an incident and the commits a force push displaced. In an incident nobody runs cleanup of any kind until the recovery is verified. A server keeps reflogs only if `core.logAllRefUpdates` is set, which I would set.

Listen for: pack against prune, reachability including reflogs, the pair of commands, and the incident rule. Follow-up: "Is `git gc` itself dangerous?" (No: with defaults it respects reflogs and the two-week cut-off.)

*Reference:* Chapter 13, sections 13.2, 13.4 and 13.13; Chapter 26, sections 26.3 to 26.5.

### 18.12

Model answer. Git, on the client, decides what a push proposes; Git, on the server, applies one built-in rule: a branch may only move forward unless the push is forced. Everything else that people call protection is the platform's: rules evaluated on each ref update, which can require a pull request, reviews, passing checks, signatures, linear history, and can block force pushes and deletions, for named actors or for everyone.

Only the client can offer: `--force-with-lease` with `--force-if-includes`, a condition on my own push that protects a colleague's commit from me, and local checks before anything leaves the machine. The false belief: that client hooks enforce policy. They are not cloned, and `--no-verify` skips them. Only the server can offer: a rule that binds everyone, including administrators, with a record of every bypass; and a record of what the branch pointed at before, which a bare Git server does not keep. The false belief: "`main` is protected, so admins cannot force-push". Under a classic rule they can unless bypassing is disallowed; under a ruleset nobody can unless they are on the bypass list, and an exempt actor leaves no trace. And a third: "Request changes" and CODEOWNERS block a merge. Both are advisory until a rule requires them.

Listen for: the fast-forward rule as the only native one, lease on the client, rulesets with bypass modes, and the advisory controls. Follow-up: "How do you find out which rules apply to a branch right now?" (The repository's rules page for the branch, `gh ruleset check <branch>`.)

*Reference:* Chapter 12, sections 12.7 and 12.8; Chapter 14C, section 14C.13; Chapter 18, sections 18.2, 18.5, 18.14 and 18.16.

### 18.13

Model answer. From the BreakingChanges document that ships with Git: new repositories will use SHA-256 as the hash function, when libraries, applications and forges are ready, and SHA-1 is not being deprecated; new repositories will store refs in the reftable format; the initial branch name becomes `main`; bare repositories found by walking up directories are refused unless explicit; and building Git will require Rust. Removals include `git whatchanged`, grafts, `git pack-redundant` and the old `.git/branches` and `.git/remotes` directories. No release date is in any official document.

Preparation: every script that reads `.git/refs`, `packed-refs` or `.git/HEAD` by hand breaks with reftable, and anything that assumes 40-character IDs breaks with SHA-256, so tooling must ask Git and must not hard-code a length. A team can try the future defaults today in new sandbox repositories with `init.defaultRefFormat=reftable` and `init.defaultObjectFormat=sha256`, and set `safe.bareRepository=explicit` on developer machines now. Existing repositories do not change by themselves, and a SHA-256 repository cannot be pushed to a host that does not support it. The false claim: that `git checkout` is being removed. The document records the decision to keep it beside `git switch` and `git restore`. Also false: that `master` is gone in current Git; unconfigured Git 2.55 still creates it.

Listen for: the five default changes with their conditions, "no date", scripts that read `.git`, and the checkout claim. Follow-up: "What tells you today that a command is on its way out?" (`git whatchanged` refuses to run without an explicit flag on 2.55.)

*Reference:* Chapter 14D, sections 14D.2 to 14D.5; Chapter 3, sections 3.13 and 3.14.

### 18.14

Model answer. History first, read-only. `git log --graph --oneline --all` and `--first-parent` on the default branch: is there one readable line of merges or squashes, or criss-crossing merges and "Merge branch main of" commits that show people pulling without thought. `git log --format='%h %an %cn %G?'`: who commits, are commits signed, do author and committer make sense. Tags: annotated or lightweight, do they follow a version scheme, does `git describe` work. Size and content: the largest objects in history, tracked files that should be ignored, anything that looks like a credential in a quick pickaxe for common key prefixes. `git fsck` for integrity. Messages: can I tell why a change was made.

Then governance, on the platform. Which rules apply to the default and release branches, as rulesets or classic rules, who can bypass, and in which mode. Is a pull request with review required, are checks required, and is the required check something that cannot be filtered away. CODEOWNERS: does it exist, does it cover the workflows and itself. Workflows: `permissions`, pinned actions, the triggers. Who has admin, what the base permission is, which deploy keys and apps exist. Secret scanning and push protection.

I say "no" when the default branch accepts direct or forced pushes from more than nobody, when release tags can move, when workflows run untrusted code with secrets, when history contains live-looking credentials, or when nobody can tell me who can bypass the rules.

Listen for: an order, evidence commands for history, the bypass question, and explicit stop conditions. Follow-up: "Which single finding worries you most?" (A bypass that leaves no record: an exempt actor, or administrators under a classic rule.)

*Reference:* Chapter 29, sections 29.2 and 29.8; Chapter 18, sections 18.5 and 18.16; Chapter 21A, section 21A.19; Chapter 14A, section 14A.15.

---

## Multiple-choice answers at a glance

| Section | Answers, in item order |
|---|---|
| 1 | 1.1 C · 1.2 B · 1.3 A · 1.4 C · 1.5 D · 1.6 C |
| 2 | 2.1 B · 2.2 C · 2.3 B · 2.4 C · 2.5 C · 2.6 C |
| 3 | 3.1 B · 3.2 C · 3.3 D · 3.4 A · 3.5 A |
| 4 | 4.1 B · 4.2 C · 4.3 B · 4.4 D · 4.5 A |
| 5 | 5.1 B · 5.2 D · 5.3 A · 5.4 A · 5.5 C |
| 6 | 6.1 B · 6.2 B · 6.3 C · 6.4 A · 6.5 D |
| 7 | 7.1 B · 7.2 C · 7.3 D · 7.4 A · 7.5 D |
| 8 | 8.1 B · 8.2 C · 8.3 B · 8.4 D · 8.5 A |
| 9 | 9.1 A · 9.2 B · 9.3 D · 9.4 C · 9.5 D · 9.6 A |
| 10 | 10.1 A · 10.2 C · 10.3 C · 10.4 D · 10.5 C |
| 11 | 11.1 C · 11.2 A · 11.3 B · 11.4 B · 11.5 A · 11.6 D |
| 12 | 12.1 D · 12.2 D · 12.3 A · 12.4 A · 12.5 D · 12.6 B |
| 13 | 13.1 D · 13.2 D · 13.3 B · 13.4 D |
| 14 | 14.1 A · 14.2 B · 14.3 A · 14.4 B · 14.5 D |
| 15 | 15.1 B · 15.2 A · 15.3 C |
| 16 | 16.1 C · 16.2 B · 16.3 B · 16.4 A |
| 17 | 17.1 A · 17.2 C · 17.3 D · 17.4 D · 17.5 C |

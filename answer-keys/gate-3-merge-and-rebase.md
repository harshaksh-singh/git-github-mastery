# Answer key, Gate 3: Merge and rebase

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 3](../assessments/gate-3-merge-and-rebase.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. Every transcript is real output of a script under `labs/gates/` on Git 2.55.0.

**Marking, in general.** A concept answer is marked on mechanism: which commits are compared, which index stage holds what, which ref moves. Correct vocabulary without mechanism earns at most 2 of 5. Deduct a point for each statement that is wrong about Git.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** The inputs are three versions of the file: ours (the commit `HEAD` names), theirs (the commit being merged) and the base, which is the file in the merge base, the best common ancestor that Git finds by walking parent links from both tips. Git compares base with ours and base with theirs and applies one rule to each region: changed on one side only, take that side; changed on both sides in the same way, take it once; changed on both sides differently, conflict. Git merges text regions, not individual lines: when the two sides change lines that touch each other, no unchanged line separates the two changes, they fall into one region, both sides differ from the base there, and the result is a conflict although nobody edited the same line. The rule knows nothing about meaning. If one side renames a function and the other adds a call to the old name in another file, each region changed on one side only, the merge is clean, and the result fails. Each branch was green; the merge result was never tested by anyone.

**Marking.** 1 point: the three inputs and how the base is found. 1 point: the rule table. 1 point: regions and adjacency. 1 point: a correct example of a clean and wrong merge. 1 point: the conclusion that the merge result is a new state that must be tested.

**Common wrong answers.** "Git compares the two branches." (Two-way comparison cannot tell an addition from a deletion.) "Conflicts happen when two people edit the same file." "No conflict means the merge is correct."

**Reference.** Chapter 8, sections 8.2, 8.4, 8.7 (root-cause box "A conflict, although the two branches changed different lines") and 8.15 (root-cause box "Two green branches, a merge without conflict, a red merge commit").

### C2 (5 points)

**Model answer.** Working tree: the file with conflict markers around each conflicting region and the cleanly merged regions already applied. Index: instead of one entry at stage 0, up to three entries for the path: stage 1 the base, stage 2 ours, stage 3 theirs; cleanly merged files are staged normally. Under `.git`: `MERGE_HEAD` (the commit being merged), `ORIG_HEAD` (where the branch was), `MERGE_MSG`, `MERGE_MODE`, and `AUTO_MERGE`, a tree that matches what was written to the working tree. `git add <file>` replaces the three staged versions by one stage-0 entry with the content of the working-tree file; that is all "marking as resolved" means, and Git does not check that the markers are gone. In a merge, ours is the branch you are on and theirs is the branch being merged. In a cherry-pick, ours is the branch you are on and theirs is the picked commit. In a rebase the roles look reversed: Git checks out the new base and replays your commits onto it, so ours is the commit being built on (the upstream side, plus your commits already replayed) and theirs is your own commit being replayed. Taking "ours" for the whole file in a rebase discards your change; if nothing else is in that commit, the commit has become empty and `--continue` drops it without a message.

**Marking.** 1 point: working tree and the three stages. 1 point: the files under `.git` (at least `MERGE_HEAD` and `ORIG_HEAD`). 1 point: what `git add` does. 1 point: the three meanings with the rebase reversal explained by "your commits are replayed onto a checked-out base". 1 point: the dropped commit.

**Common wrong answers.** "Ours is always my work." "`git add` tells Git the conflict is fixed, and Git verifies it." "Stage 1 is ours."

**Reference.** Chapter 8, section 8.8; Chapter 9, section 9.11 (root-cause box "The rebase finishes normally, and ... is not in the branch"); Chapter 10, section 10.7.

### C3 (5 points)

**Model answer.** A rebase replays each commit as a new commit on a new parent. The commit ID is the hash of the commit object, which contains the parent ID and the committer line; the first replayed commit has a different parent, so it is a different object, and each later one has a different parent in turn. Author, author date and message are copied; the tree is recomputed. The old commits are not deleted. They are unreachable from the branch but named by `ORIG_HEAD` until the next command that writes it, and by the reflogs of the branch and of `HEAD` for as long as the reflog entries live (by default 90 days, 30 for entries that are unreachable from the current tip), after which garbage collection may remove them. The colleague's branch still contains the old commits. Their pull merges the rewritten branch into it; the merge base is the commit below the rewritten part, so the result contains every change twice, once as old commits and once as new, usually after conflicts. The forced update should have been `git push --force-with-lease --force-if-includes`: the lease makes the server update the ref only if it still has the value of my remote-tracking ref, and `--force-if-includes` additionally requires that the tip of that remote-tracking ref is reachable from a reflog entry of my local branch, that is, that I have integrated what I am about to overwrite. And a branch others build on should not have been rebased without agreement.

**Marking.** 1 point: why the IDs change. 1 point: where the old commits are and for how long. 1 point: duplicates on the colleague's side with the reason. 1 point for each of the two push options, with what it checks.

**Common wrong answers.** "The IDs change because the content changed." "The old commits are gone." "`--force-with-lease` is always safe" (a background fetch renews the lease).

**Reference.** Chapter 9, sections 9.3, 9.15, 9.16 and 9.17; Chapter 12, section 12.8 (root-cause box on `--force-with-lease`).

### C4 (5 points)

**Model answer.**

- (a) `git revert <commit>`. The commit is published and others have built on it; a revert adds a new commit that applies the inverse change, so nobody's history is rewritten. A reset would need a forced push and would remove ten commits of other people from the branch.
- (b) Not published, so the commit may be replaced: `git rm --cached <file>` (or `git restore --staged --source=HEAD~1 <file>` if the file existed before) followed by `git commit --amend --no-edit`. An amend is a soft reset plus a new commit; the old commit stays in the reflog.
- (c) `git restore --staged <file>`: copies the entry from `HEAD` into the index, working tree untouched. `git reset <file>` is the older spelling.
- (d) `git restore <file>`: copies the index entry over the working-tree file. The discarded edits were only in the working tree, so no object holds them: neither the reflog nor `git fsck` can bring them back. Had they been staged at some point, the blob would still exist as a dangling object.

The deciding question for every undo is whether the thing to undo has left your repository.

**Marking.** 1 point per situation with form and reason (4). 1 point: the unrecoverable part of (d), with the reason that Git writes a blob only when content is staged or committed.

**Common wrong answers.** `git reset --hard` for (a) "then force-push". `git rm --cached` for (c) (deletes the file in the next commit if it was tracked). "The reflog can restore (d)."

**Reference.** Chapter 11, sections 11.2 to 11.8 and 11.12; section 11.5 (root-cause box "After git reset --hard, an edit is gone").

### C5 (5 points)

**Model answer.** A merge commit has two parents, and a revert needs to know against which parent to compute the inverse: `-m 1` says "the mainline is parent 1", so the revert undoes what the merge brought in relative to `main` before the merge. The revert is a new commit that removes the content. It does not remove the merge commit, so in the graph the old branch commits are still ancestors of `main`. When the branch is merged again, the merge base is the old tip of the branch. Since that base, the branch changed only by the one new commit; `main` changed by the revert, which deletes the feature. One side deleted, the other did not touch: the deletion stands, and only the new commit arrives. The correct ways: revert the revert on `main` and then merge the branch (the feature comes back and the fix is added), or recreate the branch as new commits (for example `git rebase --no-ff` or a fresh branch with cherry-picks) so that Git sees them as new changes.

**Marking.** 1 point: what `-m 1` selects. 1 point: the merge stays in the graph. 1 point: the merge base is the old branch tip. 1 point: why the revert's deletion wins. 1 point: at least one correct way back, stated precisely.

**Common wrong answers.** "Git remembers that the branch was reverted." "Merge again with `-X theirs`." "Delete the revert commit" on a shared branch.

**Reference.** Chapter 11, section 11.9 (root-cause box "After a merge was reverted, merging the fixed branch brings only the new commit").

### C6 (5 points)

**Model answer.** In `git log`, `A..B` is the set of commits reachable from B and not from A; `A...B` is the symmetric difference, the commits reachable from either but not from both. In `git diff` there are no sets, only two endpoints: `git diff A..B` is the same as `git diff A B`, the tree of A against the tree of B; `git diff A...B` compares the merge base of A and B with B, which is "what B changed since it forked". The reviewer's `git diff main feature` compares the two tips. Whatever `main` added after the fork is absent from the feature's tree and prints as a deletion, although the feature never touched it. The reviewer wanted `git diff main...feature` (or `git diff --merge-base main feature`), which is also what a pull request shows. `git cherry-pick A..B` picks the commits after A up to B: A itself is excluded. To include it, write `A^..B`.

**Marking.** 1 point: the two `log` meanings. 1 point: the two `diff` meanings. 1 point: the explanation of the phantom deletion. 1 point: the three-dot diff. 1 point: A is excluded.

**Common wrong answers.** "Three dots show more commits in diff too." "`A..B` in diff shows what B added." "`A..B` includes A."

**Reference.** Chapter 14A, sections 14A.2 (root-cause box) and 14A.8; Chapter 10, section 10.5.

---

## Part 2: Prediction

Marking for every prediction item: a prediction counts when the lines and their order are right. Exact spacing is not required. A right output with a wrong mechanism earns half of that sub-item.

### P1 (5 points)

<!-- snippet: gates/g3-predict/p1-answer -->
```text
$ git merge tune/top-k
Auto-merging sampling.yaml
CONFLICT (content): Merge conflict in sampling.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU sampling.yaml
$ git ls-files -u
100644 65c794e940500bc9fced922d159e0f2efa3924e9 1	sampling.yaml
100644 859067e84c5b872be1e0e58a4a44fa32042904df 2	sampling.yaml
100644 8bfdf3eed9be7e493f3d19fcb59d75c77437dbfd 3	sampling.yaml
$ cat sampling.yaml
temperature: 0.7
<<<<<<< HEAD
top_p: 0.95
top_k: 40
=======
top_p: 0.9
top_k: 20
>>>>>>> tune/top-k
max_tokens: 512
seed: 7
$ ls .git | grep -E "MERGE|ORIG|AUTO"
AUTO_MERGE
MERGE_HEAD
MERGE_MODE
MERGE_MSG
ORIG_HEAD
```
<!-- /snippet -->

`top_p` (line 2) changed on `main`, `top_k` (line 3) on the branch. The two changed lines touch, so they form one region in which both sides differ from the base: a conflict, exit status 1. The index holds three entries for the path, stages 1, 2 and 3. The conflict block contains both lines on each side, which shows the region. Lines 1, 4 and 5 are outside it.

**Marking.** 2 points: conflict and non-zero status. 1 point: `UU sampling.yaml`. 1 point: three lines, stages 1, 2, 3. 1 point: the marker block spans both lines, with `HEAD` first. "Clean merge with both changes" is the expected wrong answer and earns 0 for the first two sub-items.

**Reference.** Chapter 8, sections 8.7 and 8.8.

### P2 (5 points)

<!-- snippet: gates/g3-predict/p2-answer-a -->
```text
$ git status --short
 M lr.yaml
?? decay.txt
$ cat lr.yaml
warmup: 800
$ git log --oneline
ac7facb Add warmup
```
<!-- /snippet -->

A mixed reset moves the branch to the first commit and makes the index match it; the working tree is not touched. `lr.yaml` therefore keeps `800` and differs from the index (` M`), and `decay.txt`, which the index no longer knows, is untracked.

<!-- snippet: gates/g3-predict/p2-answer-b -->
```text
$ git log --oneline
932a2f8 Longer warmup, cosine decay
ac7facb Add warmup
$ git status --short
D  decay.txt
MM lr.yaml
?? decay.txt
$ git diff --cached --stat
 decay.txt | 1 -
 lr.yaml   | 2 +-
 2 files changed, 1 insertion(+), 2 deletions(-)
```
<!-- /snippet -->

The first reset wrote the old tip into `ORIG_HEAD`. A soft reset moves the branch back there and touches neither index nor working tree. The index still holds the tree of the first commit, so against the new `HEAD` it looks like a staged undo of the second commit: `decay.txt` staged as deleted and `lr.yaml` staged as changed back to 100. The working tree has 800, which differs from the index (second `M`), and `decay.txt` exists on disk without an index entry (`??`). A commit now would delete `decay.txt` from the project.

**Marking.** 2 points: ` M lr.yaml`, `?? decay.txt` and `800`. 1 point: two commits. 2 points: the three status lines, of which `D  decay.txt` together with `?? decay.txt` is worth 1 and `MM lr.yaml` is worth 1. Candidates who expect a clean status after the soft reset have the model "soft reset undoes the reset" and earn at most 3.

**Reference.** Chapter 11, sections 11.4 and 11.7; Chapter 13, section 13.5.

### P3 (5 points)

<!-- snippet: gates/g3-predict/p3-answer -->
```text
$ git log --graph --all --format='%s%d'
* G (HEAD -> feature/printer)
* F
* E (main)
| * D (feature/parser)
| * C
|/  
* B
* A
$ git branch --show-current
feature/printer
$ git log --format=%s main..feature/printer
G
F
$ git log --format=%s feature/printer..feature/parser
D
C
$ git log --format=%s ORIG_HEAD -3
G
F
D
```
<!-- /snippet -->

`git rebase --onto main feature/parser feature/printer` replays the commits reachable from `feature/printer` and not from `feature/parser` (F and G) onto `main` and moves `feature/printer`, which is also checked out. `feature/parser` is not moved and still holds C and D, which are no longer below `feature/printer`. `ORIG_HEAD` names the old tip of `feature/printer`, whose history is still G, F, D.

**Marking.** 2 points: the graph, with F and G above E and C, D on a side branch. 1 point: `G`, `F`. 1 point: `D`, `C`. 1 point: `G`, `F`, `D`. A graph in which C and D moved as well earns 0 for the first sub-item.

**Reference.** Chapter 9, sections 9.5 and 9.9.

### P4 (5 points)

<!-- snippet: gates/g3-predict/p4-answer -->
```text
$ git log --format=%s main..topic
Q
X
P
$ git log --format="%m %s" --left-right main...topic
> Q
> X
< Y
< X
> P
$ git log --format="%m %s" --left-right --cherry-pick main...topic
> Q
< Y
> P
$ git cherry main topic | cut -c1
+
-
+
$ git diff --stat main...topic
 p.txt | 1 +
 q.txt | 1 +
 x.txt | 1 +
 3 files changed, 3 insertions(+)
$ git diff --stat main..topic
 p.txt | 1 +
 q.txt | 1 +
 y.txt | 1 -
 3 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

`main..topic` lists three commits, including the copy of X: the copy is a different commit that `main` cannot reach. The symmetric difference lists both X commits, one on each side. `--cherry-pick` drops commits whose patch has an equivalent on the other side, so both X lines disappear. `git diff main...topic` compares the merge base with `topic` (p, q and x added); `git diff main..topic` compares the two tips, where `x.txt` is equal on both sides and `y.txt`, which only `main` has, prints as a deletion.

**Marking.** 1 point: `Q`, `X`, `P`. 1 point: five lines with the right markers. 1 point: three lines, both X gone. 2 points: the two file lists, 1 each; for the second, `y.txt` with `-` is required.

**Reference.** Chapter 14A, sections 14A.2, 14A.8 and 14A.14; Chapter 10, section 10.10.

---

## Part 3: Hands-on diagnosis

**End state (12 points).** Run `check.sh`. 12 points for `PASS`; otherwise 12 minus the number of `FAIL` lines, not below zero.

**Safety of the path (8 points).** Read the candidate's command log.

| Points | Evidence in the log |
|---|---|
| 2 | The stopped operation inspected first: `git status`, the todo or sequencer state, the commit being applied |
| 2 | `git ls-files -u` or `git show :N:<path>` before the resolution |
| 2 | A way back before each rewrite: a backup branch, or an explicit statement of the reflog entry or `ORIG_HEAD` that leads back, checked with `git rev-parse` |
| 2 | Nothing pushed; no `git reset --hard` without a named way back; no `git checkout --ours` or `--theirs` on the whole file |

**Explanation (10 points).** 4 points: the three stages and "ours", stated before the resolution and confirmed by a command. 3 points: the second rule in `SYMPTOMS.md` (variant A: the way back; variant B: the selected and the wanted commits). 3 points: the third rule (variant A: the proof of equal changes; variant B: the ways out of the operation and what each leaves).

### Variant A (`chunker`): model solution

<!-- snippet: gates/solve-g3-a/01-observe -->
```text
$ cd you
$ git status -sb
## HEAD (no branch)
UU chunker/split.py
$ git log --oneline --graph --all
* fad8e6e Add README
* f95db79 Rename size to max_len and raise the default
| * cbc8cf0 fixup! Add overlap to the splitter
| * 9f7441a Fix off-by-one in window end
| * d5489d9 Add overlap to the splitter
|/  
* e82d013 Add window helper
* 85ff2bc Add fixed-size splitter
$ cat .git/rebase-merge/head-name
refs/heads/feature/overlap
$ git log --oneline main..ORIG_HEAD
cbc8cf0 fixup! Add overlap to the splitter
9f7441a Fix off-by-one in window end
d5489d9 Add overlap to the splitter
```
<!-- /snippet -->

`HEAD` is detached because a rebase is in progress; `.git/rebase-merge/head-name` names the branch that will be moved at the end, and `ORIG_HEAD` names its old tip with the three original commits.

<!-- snippet: gates/solve-g3-a/02-stages -->
```text
$ git ls-files -u
100644 12a8caa46d1b1c8f79efea8d7a1ffe9c30813109 1	chunker/split.py
100644 88093af91d9e6fa58d9a94bf95732c1406cc9607 2	chunker/split.py
100644 89559278b361713c4413da3df6692fd2f46df446 3	chunker/split.py
# Stage 2, "ours": in a rebase this is the commit being built on, here main.
$ git show :2:chunker/split.py | head -2
def split(text, max_len=512):
    """Split text into chunks of at most max_len characters."""
# Stage 3, "theirs": the commit being replayed, here your own.
$ git show :3:chunker/split.py | head -2
def split(text, size=200, overlap=0):
    """Split text into chunks of at most size characters."""
$ git log -1 --oneline REBASE_HEAD
d5489d9 Add overlap to the splitter
$ git diff
diff --cc chunker/split.py
index 88093af,8955927..0000000
--- a/chunker/split.py
+++ b/chunker/split.py
@@@ -1,8 -1,8 +1,18 @@@
++<<<<<<< HEAD
 +def split(text, max_len=512):
 +    """Split text into chunks of at most max_len characters."""
 +    chunks = []
 +    start = 0
 +    while start < len(text):
 +        chunks.append(text[start:start + max_len])
 +        start += max_len
++=======
+ def split(text, size=200, overlap=0):
+     """Split text into chunks of at most size characters."""
+     chunks = []
+     start = 0
+     while start < len(text):
+         chunks.append(text[start:start + size])
+         start += size - overlap
++>>>>>>> d5489d9 (Add overlap to the splitter)
      return chunks
```
<!-- /snippet -->

Stage 1 is the file in the parent of the commit being replayed, stage 2 ("ours") is the file on the new base, which is `main`, and stage 3 ("theirs") is the candidate's own commit. `git checkout --ours` would keep Asha's rename and discard the overlap.

<!-- snippet: gates/solve-g3-a/03-resolve -->
```text
# chunker/split.py edited by hand to the agreed function
$ git diff --stat
 chunker/split.py | Unmerged
 chunker/split.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git add chunker/split.py
$ git rebase --continue
[detached HEAD 073d1a6] Add overlap to the splitter
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/overlap.
$ git log --oneline main..feature/overlap
e759ce4 fixup! Add overlap to the splitter
a06579f Fix off-by-one in window end
073d1a6 Add overlap to the splitter
```
<!-- /snippet -->

The rebase replayed all three commits. The `fixup!` commit is still separate: a plain `git rebase` does not rearrange. Before the second rewrite the state gets a name; without it, the way back is `ORIG_HEAD` (which the next rebase overwrites) or the branch reflog.

<!-- snippet: gates/solve-g3-a/04-autosquash -->
```text
# A name for the state before the second rewrite.
$ git branch backup/overlap-before-squash
$ git rebase --autosquash main
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/overlap.
$ git log --oneline --stat main..feature/overlap
75b5902 Fix off-by-one in window end
 chunker/window.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ea54f60 Add overlap to the splitter
 chunker/split.py    | 4 ++--
 tests/test_split.py | 4 ++++
 2 files changed, 6 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

Since Git 2.44 `--autosquash` works without `-i`. The proof that nothing was lost: the trees before and after are identical (the empty `git diff --stat`), and `git range-diff` pairs the commits. Commit 1 gained the test file, commit 2 is unchanged (`=`), and the fixup has no counterpart because it was folded in.

<!-- snippet: gates/solve-g3-a/05-prove -->
```text
$ git diff --stat backup/overlap-before-squash feature/overlap
$ git range-diff main backup/overlap-before-squash feature/overlap
1:  073d1a6 ! 1:  ea54f60 Add overlap to the splitter
    @@ chunker/split.py
     -        start += max_len
     +        start += max_len - overlap
          return chunks
    +
    + ## tests/test_split.py (new) ##
    +@@
    ++from chunker.split import split
    ++
    ++def test_overlap_repeats_the_tail():
    ++    assert split("abcdef", 4, overlap=2) == ["abcd", "cdef", "ef"]
2:  a06579f = 2:  75b5902 Fix off-by-one in window end
3:  e759ce4 < -:  ------- fixup! Add overlap to the splitter
$ git show feature/overlap:chunker/split.py
def split(text, max_len=512, overlap=0):
    """Split text into chunks of at most max_len characters."""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + max_len])
        start += max_len - overlap
    return chunks
```
<!-- /snippet -->

The backport is made after the clean-up and not before it: the `-x` line must name the commit as it will be in the pull request, and every rewrite of the branch changes that ID.

<!-- snippet: gates/solve-g3-a/06-backport -->
```text
$ git switch release/1.2
Switched to branch 'release/1.2'
Your branch is up to date with 'origin/release/1.2'.
$ git cherry-pick -x feature/overlap
[release/1.2 27c5f3f] Fix off-by-one in window end
 Date: Mon Sep 7 10:13:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format=%B
Fix off-by-one in window end

(cherry picked from commit 75b59024c241433323b7ffa743a9fd495953ddc1)

$ git log --oneline origin/release/1.2..release/1.2
27c5f3f Fix off-by-one in window end
$ git diff --stat origin/release/1.2 release/1.2
 chunker/window.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git cherry -v release/1.2 feature/overlap
+ f95db790ac13b74ffbefde6cfe73c89b757b8291 Rename size to max_len and raise the default
+ fad8e6e3062c0d88f4d8721bd7ab310e868e04c9 Add README
+ ea54f60f2a70d66ea7c491b5b303f2afb848bfc1 Add overlap to the splitter
- 75b59024c241433323b7ffa743a9fd495953ddc1 Fix off-by-one in window end
```
<!-- /snippet -->

`git cherry -v` confirms it from the other direction: of the commits on `feature/overlap`, only the fix has an equivalent (`-`) on `release/1.2`.

<!-- snippet: gates/solve-g3-a/07-finish -->
```text
$ git switch feature/overlap
Switched to branch 'feature/overlap'
$ git branch -D backup/overlap-before-squash
Deleted branch backup/overlap-before-squash (was e759ce4).
$ git status -sb
## feature/overlap
$ cd ..
$ assessments/gen/gate-3-merge-and-rebase/variant-a/check.sh
Checking g3-a
  ok    no rebase or cherry-pick is in progress
  ok    HEAD is on feature/overlap
  ok    main is where the server has it, locally and on the server
  ok    feature/overlap starts at the tip of main
  ok    feature/overlap has exactly these two commits, in this order
  ok    the splitter has both parameters
  ok    the step is max_len - overlap
  ok    the old parameter name and the conflict markers are gone
  ok    the test file is part of the first commit
  ok    release/1.2 has exactly one new commit
  ok    it is the off-by-one fix
  ok    its message names the commit on the feature branch it was picked from
  ok    release/1.2 has the fixed window helper
  ok    release/1.2 did not receive the overlap feature
  ok    release/1.2 on the server has not moved
  ok    nothing is staged, modified or untracked
PASS: the end state of g3-a is right.
[exit status: 0]
```
<!-- /snippet -->

**Partial credit and common mistakes, variant A.**

- `git rebase --abort`, then a fresh `git rebase --autosquash main`: a correct and shorter path. The conflict then appears once, in the squashed commit. Full marks.
- `git checkout --ours chunker/split.py` and `--continue`: the first commit keeps only the test or is dropped as empty; the overlap is gone. Three or more lines of the check fail; 0 for the stages explanation.
- Cherry-picking the fix to the release branch before the autosquash: the `-x` line names a commit that no longer exists on the branch. One line of the check fails. This is the point of the "as it will be in the pull request" requirement.
- `git merge main` into the feature branch instead of finishing the rebase: the check fails on the commit list; the candidate did not read the reviewers' request.
- Pushing anything: minus 2 safety points.

**Reference.** Chapter 9, sections 9.4, 9.7, 9.11, 9.14 and 9.16; Chapter 10, sections 10.4 and 10.9.

### Variant B (`quota-svc`): model solution

<!-- snippet: gates/solve-g3-b/01-observe -->
```text
$ cd asha
$ git status -sb
## release/2.1...origin/release/2.1 [ahead 1]
UU quota/window.py
$ git log --oneline origin/release/2.1..HEAD
21073f0 Add per-tenant burst setting
$ git log -1 --oneline CHERRY_PICK_HEAD
3d5408a Fix window rollover at midnight UTC
$ cat .git/sequencer/todo
pick 3d5408a Fix window rollover at midnight UTC
pick 04049e0 Fix rounding of the quota header
```
<!-- /snippet -->

The release branch already has one new commit, the burst setting, which must not be there. The sequencer still has two picks to do. The first fix is nowhere.

<!-- snippet: gates/solve-g3-b/02-range -->
```text
$ git log --oneline --reverse origin/release/2.1..main
f98d799 Fix negative remaining quota
66620fd Add per-tenant burst setting
3d5408a Fix window rollover at midnight UTC
04049e0 Fix rounding of the quota header
# What the range that Asha typed selects: the left end is excluded.
$ git log --oneline --reverse f98d799..04049e0
66620fd Add per-tenant burst setting
3d5408a Fix window rollover at midnight UTC
04049e0 Fix rounding of the quota header
```
<!-- /snippet -->

`A..B` is "reachable from B and not from A", so the first fix, which was the left end, is excluded, and the range includes every commit between the ends, wanted or not. A range is the wrong tool when the wanted commits are not contiguous.

<!-- snippet: gates/solve-g3-b/03-stages -->
```text
$ git ls-files -u
100644 70cfad86ea6aecae4465aea685c56db52211d362 1	quota/window.py
100644 a76458d598eb925e679582dcf82498d4821fad9c 2	quota/window.py
100644 5c7124afe933aba4f99ffff76fc42fcaae4295ce 3	quota/window.py
# Stage 2, "ours": the branch being built, release/2.1. Stage 3, "theirs": the picked commit.
$ git show :1:quota/window.py | head -2
WINDOW_S = 3600

$ git show :2:quota/window.py | head -2
WINDOW_S = 60

$ git show :3:quota/window.py | head -2
WINDOW_S = 3600
DAY_S = 86400
```
<!-- /snippet -->

Stage 1 is the file in the parent of the picked commit (the value 3600 of `main`), stage 2 ("ours") is the release branch with 60, stage 3 ("theirs") is the picked commit. The picked commit did not change the first line; the release branch did. The lines touch, hence the conflict.

The ways out: `--continue` after resolving would keep the unwanted commit below and still lack the first fix; `--skip` would drop the rollover fix; `--quit` would end the operation and leave the unwanted commit and a conflicted working tree; `--abort` returns the branch, the index and the working tree to the state before the whole sequence. Abort is the one that leaves nothing behind.

<!-- snippet: gates/solve-g3-b/04-abort -->
```text
$ git cherry-pick --abort
$ git status -sb
## release/2.1...origin/release/2.1
$ git log --oneline origin/release/2.1..HEAD
```
<!-- /snippet -->

<!-- snippet: gates/solve-g3-b/05-pick -->
```text
$ git cherry-pick -x f98d799 3d5408a 04049e0
[release/2.1 59618c3] Fix negative remaining quota
 Date: Mon Sep 7 10:13:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
Auto-merging quota/window.py
CONFLICT (content): Merge conflict in quota/window.py
error: could not apply 3d5408a... Fix window rollover at midnight UTC
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
$ git status -sb
## release/2.1...origin/release/2.1 [ahead 1]
UU quota/window.py
```
<!-- /snippet -->

<!-- snippet: gates/solve-g3-b/06-resolve -->
```text
# quota/window.py edited by hand to the agreed file
$ git add quota/window.py
$ git cherry-pick --continue
[release/2.1 d9bb4e2] Fix window rollover at midnight UTC
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+), 1 deletion(-)
[release/2.1 d9073da] Fix rounding of the quota header
 Date: Mon Sep 7 10:16:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: gates/solve-g3-b/07-verify -->
```text
$ git log --format='%h %s%n  %b' origin/release/2.1..release/2.1
d9073da Fix rounding of the quota header
  (cherry picked from commit 04049e047acdf88285d4fdeab187e5377a883293)

d9bb4e2 Fix window rollover at midnight UTC
  (cherry picked from commit 3d5408afa549eca32d9a64cc214e9d3878260af1)

59618c3 Fix negative remaining quota
  (cherry picked from commit f98d79912983cb85e3103fc902e4fdbd5ac1636a)

$ git cherry -v release/2.1 main
- f98d79912983cb85e3103fc902e4fdbd5ac1636a Fix negative remaining quota
+ 66620fd930c91d5394588b0e3e7f86cdd8ce92df Add per-tenant burst setting
+ 3d5408afa549eca32d9a64cc214e9d3878260af1 Fix window rollover at midnight UTC
- 04049e047acdf88285d4fdeab187e5377a883293 Fix rounding of the quota header
$ git diff --stat origin/release/2.1 release/2.1
 quota/check.py   | 2 +-
 quota/headers.py | 2 +-
 quota/window.py  | 3 ++-
 3 files changed, 4 insertions(+), 3 deletions(-)
$ git status -sb
## release/2.1...origin/release/2.1 [ahead 3]
$ cd ..
$ assessments/gen/gate-3-merge-and-rebase/variant-b/check.sh
Checking g3-b
  ok    no cherry-pick is in progress
  ok    HEAD is on release/2.1
  ok    release/2.1 is three commits ahead of the server: the three fixes, oldest first
  ok    the commit release/2.1~0 names the commit on main it was picked from
  ok    the commit release/2.1~1 names the commit on main it was picked from
  ok    the commit release/2.1~2 names the commit on main it was picked from
  ok    the burst setting is not on the release branch
  ok    the release keeps its 60 second window
  ok    the release has the rollover fix
  ok    no conflict marker and no 3600 in quota/window.py
  ok    the release has the other two fixes
  ok    release/2.1 on the server has not moved
  ok    main has not moved
  ok    nothing is staged, modified or untracked
PASS: the end state of g3-b is right.
[exit status: 0]
```
<!-- /snippet -->

`git cherry -v release/2.1 main` marks two of the fixes with `-` (an equivalent patch is on the release branch) and the rollover fix with `+`. That is not an error: the conflict resolution changed the patch, so its patch ID no longer matches. It is the reason the `-x` line matters. Award a bonus mention, no extra points, to a candidate who notices this.

**Partial credit and common mistakes, variant B.**

- Resolve and `--continue`, then remove the unwanted commit and add the first fix with an interactive rebase: correct end state if the order is fixed too. Full end-state points; the explanation of the ways out must still be given.
- `git cherry-pick --quit` followed by `git reset --hard origin/release/2.1`: correct result; 1 safety point deducted unless the candidate first showed that nothing uncommitted existed.
- Picking without `-x`: three lines of the check fail.
- `git cherry-pick f1^..f3`: includes the first fix and still includes the burst setting. One or two lines fail.
- `git revert` of the burst commit on the release branch: leaves two extra commits. The check fails on the commit list.
- Resolving with `git checkout --theirs`: 2.1 gets the 3600 second window. Two lines fail, and this is the mistake the task was built to detect.

**Reference.** Chapter 10, sections 10.4 to 10.7 and 10.10; Chapter 14A, section 14A.8.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** Git finds the merge base of the two tips, compares the base with each tip, and for each path and each region takes the side that changed, takes an identical change once, and reports a conflict where both changed differently. The result becomes a commit with two parents, unless one tip is an ancestor of the other, in which case the branch is fast-forwarded and nothing is created. *Follow-up:* with two merge bases (a criss-cross, where each branch has merged the other) the `ort` strategy first merges the bases with each other and uses that result as a virtual base. If that inner merge conflicts, the base itself contains conflict markers, which is why a base section can show "Temporary merge branch" labels.

**Weak answer.** "Git combines the changes of both branches line by line." **Reference.** Chapter 8, sections 8.4 and 8.5.

### O2 (3 points)

**Model answer.** The merge is textual and per region. It has no knowledge of the language or of relations between files. Two changes that are each correct, in different places, can be wrong together: a renamed function and a new caller of the old name, a changed default and code that relied on it, a duplicated line after both sides added it in different places. *Follow-up:* the merge result is a new state, so it must be built and tested as such: CI on the merge result and not only on the branch tip, a merge queue on busy branches, and a read of the merge with `git show --remerge-diff` or a diff against the first parent when a merge needed hand resolution.

**Weak answer.** "Because of conflicts." **Reference.** Chapter 8, sections 8.15 and 8.16.

### O3 (3 points)

**Model answer.** A commit is immutable and names its parent. Cherry-pick applies the change of a commit, computed against its parent, onto a different parent: the new commit has another parent, usually another tree, and a new committer line, so it is a different object with a different ID. Nothing links the two. *Follow-up:* by content, not by ID: `git cherry -v release main` or `git log --cherry-pick --right-only release...main` compare patch IDs; they fail when the pick needed a conflict resolution, so backports should be made with `-x`, and then `git log --grep` for the original ID finds them.

**Weak answer.** "It copies the commit." **Reference.** Chapter 10, sections 10.3 and 10.10.

### O4 (3 points)

**Model answer.** Revert when the commit is published: it adds an inverse commit and rewrites nothing. Reset when the commits exist only in my repository: it moves the branch ref, and `--soft`, `--mixed` and `--hard` decide whether the index and the working tree follow. *Follow-up:* uncommitted changes to tracked files that were never staged. Commits stay reachable through the reflog and staged content stays as dangling blobs; an edit that was only saved in the editor was never an object, so nothing in Git holds it.

**Weak answer.** "Reset deletes commits, revert does not." **Reference.** Chapter 11, sections 11.2, 11.5 and 11.8.

### O5 (4 points)

**Model answer.** A squash merge writes a commit with one parent. The content arrives on `main`, but no commit of the branch becomes an ancestor of `main`, so the merge base stays at the original fork. The second merge compares both tips with that old base again: `main` changed those lines (through the squash commit) and so did the branch, and wherever the two versions differ, because the branch moved on, it is a conflict. *Follow-up:* do not reuse a squashed branch. Delete it after the merge and start the next piece of work from the new `main`; or, for a branch that must live long, merge with a true merge commit so that the base moves. In production this shows up as release branches or long-running integration branches that get harder to merge every week.

**Weak answer.** "Squash loses history, so Git gets confused." **Reference.** Chapter 8, section 8.12 (root-cause box).

### O6 (4 points)

**Model answer.** Both integrate the same content; the resulting trees are identical. A merge keeps both histories and adds a merge commit; it never rewrites, so it is the safe choice for a branch others have fetched. A rebase gives a linear history and replays my commits one by one, which means conflicts are resolved per commit and every commit gets a new ID; I do it only on commits that nobody else builds on, and I publish with `--force-with-lease --force-if-includes`. The team's merge method on the hosting service matters too: if pull requests are squashed, the shape of my branch history matters less. *Follow-up:* `git pull --rebase` replays the commits after the fork point, which it finds in the reflog of the remote-tracking branch. My commit had been pushed, so it was once the tip of the remote-tracking branch; after the forced push the upstream no longer contains it, and Git treats it as a commit that upstream discarded and does not replay it. My branch is set to the new upstream without it. It is still in my reflog. The root cause is the forced push that discarded my commit.

**Weak answer.** "Rebase is cleaner, always rebase." **Reference.** Chapter 9, sections 9.17 (root-cause box) and 9.18.

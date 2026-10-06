# Answer key, Gate 4: Recovery

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 4](../assessments/gate-4-recovery.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. Every transcript is real output of a script under `labs/gates/` on Git 2.55.0. The lab configuration never expires reflog entries by age; the answers about retention state Git's defaults from the manual.

**Marking, in general.** A concept answer is marked on what names an object and for how long. "It is in the reflog" without saying which reflog, in which repository, earns half. Deduct a point for each statement that is wrong about Git. In this gate a wrong "this is gone" and a wrong "this can be recovered" cost the same: both mislead the person who lost the work.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** Layer 1, refs: no longer applies, because the branch was moved off the commit; a tag or another branch that names it would keep it for as long as that ref exists. Layer 2, reflogs: the reflog of `HEAD` and the reflog of the branch each have an entry that names the commit. Entries are kept 90 days by default (`gc.reflogExpire`), and 30 days when the entry is not reachable from the current tip of its ref (`gc.reflogExpireUnreachable`), which is the case here. Found with `git reflog` or `git log -g`. Layer 3, the grace period: once nothing names the commit, a collection deletes the object only if its file is older than `gc.pruneExpire`, two weeks by default. Found with `git fsck`. Layer 4, other repositories: a clone that fetched it, the server if it was pushed, a bundle, a backup; independent of this repository. The summary is wrong in two ways. The grace period is not added on top of the 30 days: the two-week cut-off is compared with the age of the object file, and after 30 days the file is long past it, so the first collection after the reflog entry expires may delete it. And nothing happens on day 30 by itself: expiry and pruning happen when a collection runs, so the object may live much longer, or, after an explicit `git reflog expire --expire=now` and `git gc --prune=now`, not at all.

**Marking.** 1 point: the two reflogs with 90 and 30 days and which applies. 1 point: the grace period and its setting. 1 point: other repositories. 1 point: the grace period is not additive, with the reason. 1 point: nothing is deleted until a collection runs.

**Common wrong answers.** "Deleted immediately." "30 days exactly." "The reflog is on the server too."

**Reference.** Chapter 13, sections 13.2 and 13.4.

### C2 (5 points)

**Model answer.** A reflog is a local journal of the values a ref has had: each entry records the old ID, the new ID, who, when, and a message naming the command. `HEAD` has one, every local branch has one, remote-tracking branches have one, and `refs/stash` has one (the stash list is that reflog). It lives under `.git/logs` in the files backend. It is not part of the repository's shared data: clone does not copy it, push and fetch do not transfer it, a fresh clone starts with an empty one, and a bare repository keeps none by default. `git branch -D` deletes the branch's reflog with the branch; the `HEAD` reflog still lists commits that were checked out. A reflog that begins with an entry that is not the current value: expiry removes entries whose commits the current tip does not reach after 30 days, and that can include the entries that moved the ref to its current value, for example after a rewrite. The ref is right and the log is shorter. So a reflog is a list of past changes that a retention policy trims; it is not a second copy of the ref and not a backup. Anything worth keeping gets a branch or a tag.

**Marking.** 1 point: what an entry records and which refs have one. 1 point: local only, not cloned or pushed. 1 point: deleted with the branch, and what `HEAD`'s reflog still offers. 1 point: the expiry explanation. 1 point: the conclusion.

**Common wrong answers.** "The reflog is the history of the repository." "`git reflog` shows what my colleagues did." "The reflog is corrupt."

**Reference.** Chapter 13, sections 13.3 and 13.4 (root-cause box "git reflog show main starts at ...").

### C3 (5 points)

**Model answer.**

| | Recoverable | Reason | Found with |
|---|---|---|---|
| (a) | Yes | The commit object exists; the reflogs of `HEAD` and of the branch name it; `ORIG_HEAD` may too | `git reflog`, then `git branch <name> <id>` |
| (b) | No | Git writes a blob only when content is staged or committed; no object ever held those edits | nothing in Git; editor history or a backup |
| (c) | Yes, the content | `git add` wrote a blob. The reset removed the index entry, so nothing names the blob, but the object exists until it is pruned. The file name is lost, because names live in trees and index entries | `git fsck --lost-found`, then `git cat-file -p` on each dangling blob |
| (d) | No | Untracked files are never stored | nothing in Git; `git clean -n` would have shown it beforehand |
| (e) | Yes, while the objects exist | A stash entry is a commit. Only the newest is held by `refs/stash`; the older ones are held by reflog lines, and `stash clear` removes the ref and the log. The commits are unreachable, not deleted | `git fsck`, look for dangling commits whose subject starts with `WIP on` or `On <branch>:`, then `git stash apply <id>` |

**Marking.** 1 point per row; the reason must be about objects and names. "(c) is gone because it was never committed" is the expected wrong answer and earns 0 for that row.

**Common wrong answers.** "Everything uncommitted is gone." "The reflog has the stash." "(b) can be found with fsck."

**Reference.** Chapter 13, sections 13.8, 13.9 and 13.12.

### C4 (5 points)

**Model answer.** All five commits are unreachable, but only the newest is dangling: "dangling" means unreachable and not referred to by any other object. The newest commit refers to its parent, the parent to its parent, so one dangling tip stands for the whole chain; `git fsck --unreachable` lists all of them together with their trees and blobs. Before the reflogs were expired `git fsck` printed nothing because reflog entries are starting points for its reachability walk: the `HEAD` reflog still named commits of the branch if it was ever checked out. `git fsck --no-reflogs` would have shown the dangling commit at that moment. A dangling blob has no name because a blob is content only: the name was in the index entry or tree that pointed at it, and that is gone. To choose among several: `git fsck --lost-found` writes each to `.git/lost-found/other/`, or read each with `git cat-file -p`; compare sizes and content with what you expect, and remember that every `git add` of a later-changed file leaves such a blob, so older drafts turn up beside the wanted version.

**Marking.** 1 point: one tip stands for the chain. 1 point: dangling against unreachable. 1 point: reflogs are starting points, `--no-reflogs`. 1 point: why a blob has no name. 1 point: a workable way to choose.

**Common wrong answers.** "fsck found only one of the five; the others are lost." "Dangling means corrupt." "fsck repairs the repository."

**Reference.** Chapter 13, section 13.6; Chapter 3, section 3.8.

### C5 (5 points)

**Model answer.**

| Tool | Answers | Misleads when |
|---|---|---|
| `git blame` | which commit last changed each line of a file as it is now | a reformat, a move or a rename touched the line: it names the last toucher, not the origin. Use `-w`, `--ignore-rev`, `-M`, `-C` |
| `git log -S<string>` | which commits changed the number of occurrences of a string | the line was moved inside a file (count unchanged, not listed) or reformatted (the string changed, so a formatting commit is listed) |
| `git log -G<regex>` | which commits have a diff line that matches | it lists pure moves and reformatting too; more hits, more noise |
| `git log -L` | the history of a line range or a function | the range drifts when the code was moved between files; it is expensive |
| `git bisect` | the first commit at which a test changes from good to bad | the property is not monotonic, the test is flaky, or commits cannot be tested; it finds where behavior changed, not why the line was written |

A path given to `git log` is a filter on the current name: Git does not record renames, so before the rename no commit touched a file of that name and the listing stops. `--follow` re-detects the rename by content similarity and continues under the old name; it works for one file only, not for directories or several paths, and fails when the rename and a large rewrite happened in the same commit.

**Marking.** 3 points for the table: five correct rows 3, four rows 2, three rows 1. 1 point: why the listing stops. 1 point: the limits of `--follow`.

**Common wrong answers.** "Blame shows who wrote the line." "`-S` and `-G` are the same." "Git tracks renames."

**Reference.** Chapter 14A, sections 14A.10 to 14A.12 and 14A.16 to 14A.20.

### C6 (5 points)

**Model answer.** `ORIG_HEAD` is written by `git reset` (every mode), `git merge` (a fast-forward too), `git rebase`, `git am`, `git pull` and `git stash push`. It is not written by `git commit`, `git commit --amend`, `git switch`, `git checkout` or `git cherry-pick`. It is one file with no notion of which branch or which command it belongs to. First case: the cherry-pick did not write it, so it still held a value from an earlier operation, a merge on `main` days before; the reset moved the release branch to that commit of `main`. Second case: the merge was a fast-forward, so there is no merge commit and `HEAD~1` is the previous commit of the merged branch, one step back along three; counting parents assumes a merge commit that does not exist. The correct method in both cases: read the branch's own reflog, `git reflog show <branch>`, find the entry below the operation to undo, and reset to that entry, preferably with `--keep`, which refuses to overwrite uncommitted changes. If `ORIG_HEAD` is used at all, immediately after the operation and after checking `git log -1 ORIG_HEAD`.

**Marking.** 1 point: at least four writers. 1 point: cherry-pick and commit do not write it. 1 point: the first case. 1 point: the second case. 1 point: undo by reflog entry.

**Common wrong answers.** "`ORIG_HEAD` is the previous commit." "`HEAD~1` undoes the last operation." "`ORIG_HEAD` is per branch."

**Reference.** Chapter 13, sections 13.5 and 13.8 (both root-cause boxes).

---

## Part 2: Prediction

Marking for every prediction item: a prediction counts when the lines and their order are right. Exact spacing is not required. A right output with a wrong mechanism earns half of that sub-item.

### P1 (5 points)

<!-- snippet: gates/g4-predict/p1-answer -->
```text
$ git reflog --format='%gd %gs'
HEAD@{0} commit: Add caching
HEAD@{1} reset: moving to HEAD~2
HEAD@{2} checkout: moving from spike/async to main
HEAD@{3} commit: Try asyncio
HEAD@{4} checkout: moving from main to spike/async
HEAD@{5} commit: Add retry
HEAD@{6} commit: Add batching
HEAD@{7} commit (initial): Add embedder
$ git reflog show main --format='%gd %gs'
main@{0} commit: Add caching
main@{1} reset: moving to HEAD~2
main@{2} commit: Add retry
main@{3} commit: Add batching
main@{4} commit (initial): Add embedder
$ git log -1 --format=%s 'main@{3}'
Add batching
$ git log -1 --format=%s 'HEAD@{3}'
Try asyncio
$ git log -1 --format=%s ORIG_HEAD
Add retry
```
<!-- /snippet -->

The `HEAD` reflog records every movement of `HEAD`, including the two checkouts and the commit on the other branch. The reflog of `main` records only what moved `main`. That is why the same index means different things: `main@{3}` is "Add batching", `HEAD@{3}` is "Try asyncio". The reset wrote `ORIG_HEAD`, the later commit did not, so `ORIG_HEAD` still names "Add retry", the tip before the reset.

**Marking.** 2 points: the eight lines, with the two `checkout: moving from ... to ...` entries and `reset: moving to HEAD~2` (1 point if one entry is missing or misplaced). 1 point: the five lines for `main`. 2 points: the three subjects (all three 2, two right 1).

**Reference.** Chapter 13, sections 13.3 and 13.5.

### P2 (5 points)

<!-- snippet: gates/g4-predict/p2-answer-a -->
```text
$ git fsck
$ git fsck --no-reflogs
dangling commit 14530d107bc9162277b6485389056915ab6a3d44
```
<!-- /snippet -->

<!-- snippet: gates/g4-predict/p2-answer-b -->
```text
$ git fsck
dangling commit 14530d107bc9162277b6485389056915ab6a3d44
$ git fsck --unreachable
unreachable commit a4dc3206740c38637fbf3070e4f1c107e1b0ea75
unreachable commit 14530d107bc9162277b6485389056915ab6a3d44
$ git gc -q --prune=now
$ git fsck --unreachable
```
<!-- /snippet -->

With the reflogs in place nothing is dangling: the `HEAD` reflog names both commits of the deleted branch. Without the reflogs as starting points, one commit is dangling: the tip, "Listwise sampler". After the expiry `git fsck` reports that one dangling commit, and `--unreachable` reports two commits, the tip and its parent "Listwise loss". The commits are empty, so they add no unreachable tree. After pruning with `--prune=now` the objects are deleted and nothing is reported: that is the point of no return.

**Marking.** 1 point: nothing. 1 point: one dangling commit with `--no-reflogs`. 2 points: one dangling, two unreachable, with the right subjects. 1 point: nothing after the collection, with the statement that the objects no longer exist.

**Reference.** Chapter 13, sections 13.6 and 13.13; Chapter 3, section 3.8.

### P3 (5 points)

<!-- snippet: gates/g4-predict/p3-answer-a -->
```text
$ git status --short
?? todo.txt
$ git show -s --format=%p 'stash@{0}' | wc -w | tr -d ' '
2
```
<!-- /snippet -->

`git stash` without `-u` takes tracked changes only, staged and unstaged, and leaves the untracked file. The stash commit has two parents: the commit that was `HEAD` and a commit that holds the index. With `-u` there would be a third.

<!-- snippet: gates/g4-predict/p3-answer-b -->
```text
$ git status --short
 M loader.yaml
 M sampler.yaml
?? todo.txt
$ git stash list
```
<!-- /snippet -->

`pop` without `--index` restores the content and not the staging: `loader.yaml` was staged when it was stashed and comes back as an unstaged change. The entry is dropped after a successful pop.

**Marking.** 1 point: `?? todo.txt` only. 1 point: two parents. 2 points: both tracked files as ` M` (space, then M); a candidate who writes `M  loader.yaml` loses these 2. 1 point: the empty list.

**Reference.** Chapter 11, section 11.11.

### P4 (5 points)

<!-- snippet: gates/g4-predict/p4-answer -->
```text
$ git log --format=%s -S'retries = 3'
Retry five times
Add client settings
$ git log --format=%s -G'retries = 3'
Retry five times
Move retries to the end
Add client settings
$ git log --format=%s -L4,4:client.cfg -s
Retry five times
Move retries to the end
$ git log --format=%s -- client.cfg | wc -l | tr -d ' '
3
```
<!-- /snippet -->

`-S` lists commits that change how often the string occurs: the commit that added it and the commit that replaced it. The move kept the count at one and is not listed. `-G` lists commits whose diff has a matching added or removed line, and the move shows the line as removed and added. The line history starts from line 4 of the current file and follows it back through the change and the move; it ends at the move, because that is where the line arrived at this position as an added line.

**Marking.** 2 points: two subjects for `-S`. 2 points: three subjects for `-G`. 1 point: the two subjects for `-L`. Candidates who give identical lists for `-S` and `-G` earn at most 2.

**Reference.** Chapter 14A, sections 14A.11 and 14A.12.

---

## Part 3: Hands-on diagnosis

**End state (12 points).** Run `check.sh`. 12 points for `PASS`; otherwise 12 minus the number of `FAIL` lines, not below zero. A candidate who ran `git gc` or `git prune` before the check passed gets 0 for this part of the gate, whatever the check says: in a repository with default settings that command can be the point of no return.

**Safety of the path (8 points).**

| Points | Evidence in the log |
|---|---|
| 2 | Read-only search first: `git status`, `git reflog`, `git stash list`, `git fsck` (without `--lost-found`, which writes files, or with it and a remark that it writes only under `.git/lost-found`) |
| 2 | Every candidate inspected with `git cat-file`, `git show` or `git log` before a ref was created |
| 2 | Found commits anchored with a ref before anything else was changed |
| 2 | No `git reset --hard`, no `git stash pop` on a found entry without `apply` first, nothing pushed |

**Explanation (10 points).** 4 points: what each found object is and the evidence. 3 points: why the reflog did not help. 3 points: the item that cannot be recovered, with the reason in terms of objects.

### Variant A (`modelcard-gen`): model solution

<!-- snippet: gates/solve-g4-a/01-observe -->
```text
$ cd modelcard-gen
$ git status -sb
## feature/license-section
$ git branch
* feature/license-section
  main
$ git tag
$ git stash list
$ git reflog
$ git log --oneline --all
fa26066 Add the list of known licenses
9755343 Add intended-use and limitations sections
186b2b0 Add renderer
3e3096e Add card template
```
<!-- /snippet -->

Layers 1 and 2 are empty: no ref and no reflog entry names anything that is missing. Layer 4 does not exist. That leaves the objects themselves.

<!-- snippet: gates/solve-g4-a/02-fsck -->
```text
$ git fsck
dangling blob 2b88191c9f226fb747e8ee55bf4a804e2be7a213
dangling tag 32ffca9e303b4a93b3e0947ec52d07053648aac3
dangling commit 34fa2d5f049225d9d8b7f10402506528701d79c7
dangling commit c2b93d5dd55b2f5cb90d97686343a49245feeda2
```
<!-- /snippet -->

Four dangling objects. Each is inspected before anything is created.

<!-- snippet: gates/solve-g4-a/03-identify-tag -->
```text
$ git cat-file -p 32ffca9
object 8544ae2afff8f5e179cd3c0dd560fdf6f2807747
type commit
tag v0.9.0
tagger Ravi Menon <ravi@example.com> 1788756060 +0530

modelcard-gen 0.9.0, approved by QA
$ git log --oneline main..32ffca9
8544ae2 Freeze the renderer output format
83d4c30 Pin the template version for 0.9
```
<!-- /snippet -->

The dangling tag is the original annotated tag object, with QA's message, and it names the tip of the lost release line. Both release commits are reachable from it, which is why they are not listed as dangling.

<!-- snippet: gates/solve-g4-a/04-identify-commits -->
```text
$ git show -s --format='%h parents: %p%n  %s' c2b93d5 34fa2d5
c2b93d5 parents: fa26066 c810260 7335521
  On feature/license-section: license section, half done
34fa2d5 parents: 186b2b0
  Add intended-use section
# The first one has three parents: a stash made with -u. What does it hold?
$ git show --stat --format=%s c2b93d5
On feature/license-section: license section, half done

 cards/template.md | 4 ++++
 1 file changed, 4 insertions(+)
$ git show --stat --format=%s 'c2b93d5^3'
untracked files on feature/license-section: fa26066 Add the list of known licenses

 notes/eval-plan.md | 4 ++++
 1 file changed, 4 insertions(+)
# The second one: a commit that an amend replaced. main has its successor.
$ git diff --stat 34fa2d5 main
 cards/template.md | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

One dangling commit has three parents and the subject of a stash entry: parent 1 is the commit that was `HEAD`, parent 2 holds the index, parent 3 holds the untracked files, because the stash was made with `-u`. The other is the commit that an amend replaced on `main`; `main` has its successor with more content. It is not wanted.

<!-- snippet: gates/solve-g4-a/05-identify-blob -->
```text
$ git cat-file -p 2b88191 | tail -3
## License

See LICENSE.
$ git show c2b93d5:cards/template.md | tail -3
## License

{{ license }} ({{ license_url }})
```
<!-- /snippet -->

The dangling blob is the first draft of the license section, staged once and replaced. The stash holds the last version. Not wanted.

<!-- snippet: gates/solve-g4-a/06-restore-release -->
```text
$ git tag v0.9.0 32ffca9
$ git cat-file -t v0.9.0
tag
$ git branch release/0.9 'v0.9.0^{commit}'
$ git log --oneline --decorate main..release/0.9
8544ae2 (tag: v0.9.0, release/0.9) Freeze the renderer output format
83d4c30 Pin the template version for 0.9
```
<!-- /snippet -->

A ref under `refs/tags/` that points at the existing tag object is the original annotated tag. `git tag -a` would have created a new tag object with a new tagger and date, which is what Ravi excluded.

<!-- snippet: gates/solve-g4-a/07-restore-stash -->
```text
$ git stash apply c2b93d5
On branch feature/license-section
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   cards/template.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes/

no changes added to commit (use "git add" and/or "git commit -a")
$ git status -sb
## feature/license-section
 M cards/template.md
?? notes/
$ git diff --stat
 cards/template.md | 4 ++++
 1 file changed, 4 insertions(+)
$ git fsck
dangling blob 2b88191c9f226fb747e8ee55bf4a804e2be7a213
dangling commit 34fa2d5f049225d9d8b7f10402506528701d79c7
dangling commit c2b93d5dd55b2f5cb90d97686343a49245feeda2
$ cd ..
$ assessments/gen/gate-4-recovery/variant-a/check.sh
Checking g4-a
  ok    the tag v0.9.0 is the original tag object
  ok    v0.9.0 is an annotated tag
  ok    the branch release/0.9 is back on the tagged commit
  ok    HEAD is on feature/license-section
  ok    feature/license-section has no new commit
  ok    main has not moved
  ok    cards/template.md has the final license section, uncommitted
  ok    notes/eval-plan.md is back
  ok    the working tree differs from HEAD in exactly these two paths
  ok    no operation is left in progress
PASS: the end state of g4-a is right.
[exit status: 0]
```
<!-- /snippet -->

`git stash apply <id>` works on any commit that has the shape of a stash entry, and it restores the untracked file from the third parent. The stash commit is still dangling afterwards; `git stash store -m "..." <id>` would put it back into the list, which is optional here.

**Item 3 of Ravi's list cannot be recovered.** The edit to `gen/render.py` was saved in the editor and never staged. Git writes a blob only on `git add`, `git commit` or `git stash`; `git restore` overwrote the file, and no object ever held the edit. The model message to Ravi: "The rewrite of `gen/render.py` was never given to Git: it was not staged, committed or stashed, so no object holds it and `git fsck` has nothing to find. Your editor's local history or a disk backup are the only places to look."

**How long the found objects would have survived.** In this sandbox, indefinitely, because nothing prunes. With default settings: unreachable objects are deleted by the first collection that runs after their files are older than two weeks (`gc.pruneExpire`), and automatic maintenance decides when a collection runs. The clean-up made everything unreachable at once, so the clock had been running since each object was written.

**Partial credit and common mistakes, variant A.**

- `git tag -a v0.9.0 <commit> -m ...`: a new tag object. One line of the check fails. This is the most common mistake and shows that the candidate did not read the dangling tag.
- Restoring the release commit as a branch and forgetting the tag, or the reverse: one line each.
- `git stash apply` on the wrong dangling commit (the amended-away one): Git refuses, because it is not a stash-like commit. No penalty if the candidate reads the message and corrects.
- Writing the dangling blob into `cards/template.md`: restores the first draft. One line fails; 0 for the "what each object is" explanation of the blob.
- `git checkout <stash> -- .` in place of `git stash apply`: restores the template and misses the untracked file, which is in the third parent. One line fails.
- Resetting `main` to the amended-away commit "to restore it": one line fails; minus 2 safety points.
- Claiming that the `gen/render.py` edit "may be found with fsck": 0 of the 3 points for that explanation.

**Reference.** Chapter 13, sections 13.2, 13.6, 13.7, 13.9 and 13.12; Chapter 11, section 11.11; Chapter 14B, section 14B.8.

### Variant B (`latency-probe`): model solution

<!-- snippet: gates/solve-g4-b/01-observe -->
```text
$ cd asha
$ git status -sb
## main...origin/main
$ sh tools/p95.sh
2500
$ git log --oneline v1.0.0..main
ae085d9 Document the probe and its alerts
1762546 Add p99 alert
13f9815 Reformat config with the new formatter
5da5628 Tidy retry module
f3ee54c Add jitter to retries
72810cd Rename settings module to config
```
<!-- /snippet -->

<!-- snippet: gates/solve-g4-b/02-test-the-claim -->
```text
$ git log --oneline -- probe/config.py
13f9815 Reformat config with the new formatter
72810cd Rename settings module to config
$ git log --oneline --follow -- probe/config.py
13f9815 Reformat config with the new formatter
72810cd Rename settings module to config
7cac0c7 Add probe settings and retry policy
$ git log --oneline -G'TIMEOUT_MS' v1.0.0..main
13f9815 Reformat config with the new formatter
$ git grep -n 'TIMEOUT_MS' v1.0.0 main -- probe
v1.0.0:probe/settings.py:1:TIMEOUT_MS = 250
main:probe/config.py:3:TIMEOUT_MS = 250  # milliseconds
```
<!-- /snippet -->

Ravi's statement is wrong in its premise and in its conclusion. `git log -- probe/config.py` filters by the current path and stops at the rename; `--follow` continues to the commit that created the file under its old name. More important: the value of `TIMEOUT_MS` is 250 at the tag and 250 on `main`. The formatter added a comment to the line and did not change the number. The setting Ravi suspects did not change, so the cause is elsewhere, and reverting the formatter commit would repair nothing.

<!-- snippet: gates/solve-g4-b/03-bisect -->
```text
$ git bisect start main v1.0.0
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[5da5628c346d0b5fd79787515ec979182722d793] Tidy retry module
$ git bisect run sh -c 'test "$(sh tools/p95.sh)" = 250'
running 'sh' '-c' 'test "$(sh tools/p95.sh)" = 250'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[f3ee54ceb59d0f80375314001ec0c3a04c4442be] Add jitter to retries
running 'sh' '-c' 'test "$(sh tools/p95.sh)" = 250'
5da5628c346d0b5fd79787515ec979182722d793 is the first 'bad' commit
commit 5da5628c346d0b5fd79787515ec979182722d793
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 7 10:13:00 2026 +0530

    Tidy retry module

 probe/retry.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
bisect found first 'bad' commit
```
<!-- /snippet -->

The search is over behavior: the test is the script that monitoring uses, compared with the known good value. Two steps over six commits.

<!-- snippet: gates/solve-g4-b/04-culprit -->
```text
$ git bisect log
# bad: [ae085d950bce9077627f255925ccf6e05e17d204] Document the probe and its alerts
# good: [efac93155fe68a79b581eada9d6561c0e6252bdd] Add alert thresholds
git bisect start 'main' 'v1.0.0'
# bad: [5da5628c346d0b5fd79787515ec979182722d793] Tidy retry module
git bisect bad 5da5628c346d0b5fd79787515ec979182722d793
# good: [f3ee54ceb59d0f80375314001ec0c3a04c4442be] Add jitter to retries
git bisect good f3ee54ceb59d0f80375314001ec0c3a04c4442be
# first 'bad' commit: [5da5628c346d0b5fd79787515ec979182722d793] Tidy retry module
$ git tag culprit refs/bisect/bad
$ git bisect reset
Previous HEAD position was f3ee54c Add jitter to retries
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git show --format="%h %an: %s" culprit
5da5628 Asha Rao: Tidy retry module

diff --git a/probe/retry.py b/probe/retry.py
index e0d6a3f..b0e9561 100644
--- a/probe/retry.py
+++ b/probe/retry.py
@@ -1,2 +1,3 @@
-RETRY_MULTIPLIER = 1
+# Retry policy
 JITTER_MS = 20
+RETRY_MULTIPLIER = 10
```
<!-- /snippet -->

A commit called "Tidy retry module" changed `RETRY_MULTIPLIER` from 1 to 10 while reordering the file. The tag is created from `refs/bisect/bad` before `git bisect reset` removes the bisect refs.

<!-- snippet: gates/solve-g4-b/05-revert -->
```text
$ git revert --no-edit culprit
[main 3d4269c] Revert "Tidy retry module"
 Date: Mon Sep 7 10:44:00 2026 +0530
 1 file changed, 1 insertion(+), 2 deletions(-)
$ sh tools/p95.sh
250
$ git show --stat --format="%s%n%n%b" HEAD
Revert "Tidy retry module"

This reverts commit 5da5628c346d0b5fd79787515ec979182722d793.


 probe/retry.py | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)
$ git status -sb
## main...origin/main [ahead 1]
```
<!-- /snippet -->

`main` is published, so the undo is a revert: one new commit, nothing rewritten. No later commit touched `probe/retry.py`, so the revert applies cleanly, and the jitter setting from the commit before the culprit stays. An equally acceptable repair for production is a new commit that changes only the number and keeps the tidy-up; the task asked for an undo that names the commit, which `git revert` writes by default.

<!-- snippet: gates/solve-g4-b/06-spike-search -->
```text
$ git reflog | grep -c histogram
0
[exit status: 1]
$ cat .git/FETCH_HEAD
ae085d950bce9077627f255925ccf6e05e17d204		branch 'main' of ../server
$ git fsck
dangling commit 9fcfb29d08b9c32f284b56ccbcbc9e5f2de0338e
$ git log --format='%h %an: %s' main..9fcfb29
9fcfb29 Ravi Menon: Add bucket lookup
a2e202a Ravi Menon: Sketch latency histogram buckets
```
<!-- /snippet -->

Why the reflog has no trace: the branch was created by a fetch into a local branch and never checked out, so `HEAD` never pointed at its commits and the `HEAD` reflog has no entry. The branch's own reflog had the one line "fetch ...", and `git branch -D` deleted it with the branch. Places where the ID of a deleted branch can still be found: the terminal scrollback (`Deleted branch ... (was <id>)`), the `HEAD` reflog if the branch was ever checked out, `ORIG_HEAD` and similar files if an operation left it there, `.git/FETCH_HEAD` if the last fetch brought it (here a later fetch from `origin` has overwritten that file, as the transcript shows), another repository, and finally the object database itself through `git fsck`.

<!-- snippet: gates/solve-g4-b/07-spike-restore -->
```text
$ git branch spike/histogram 9fcfb29
$ git log --oneline --graph -4 spike/histogram
* 9fcfb29 Add bucket lookup
* a2e202a Sketch latency histogram buckets
* ae085d9 Document the probe and its alerts
* 1762546 Add p99 alert
$ git fsck
$ cd ..
$ assessments/gen/gate-4-recovery/variant-b/check.sh
Checking g4-b
  ok    the tag "culprit" names the commit that changed the effective timeout
  ok    no bisect or other operation is in progress
  ok    HEAD is on main
  ok    main is exactly one commit ahead of origin/main
  ok    that commit is a revert that names the culprit
  ok    the retry multiplier is 1 again
  ok    the jitter setting is still there
  ok    probe/config.py was not changed
  ok    the branch spike/histogram is back with both commits
  ok    main on the server has not moved
  ok    nothing is staged, modified or untracked
PASS: the end state of g4-b is right.
[exit status: 0]
```
<!-- /snippet -->

**The alert threshold cannot be recovered**, for the same reason as in variant A: saved, never staged, overwritten by `git restore`; no object was ever written.

**Partial credit and common mistakes, variant B.**

- Reverting the formatter commit, as Ravi asked: the effective timeout stays 2500. Three lines of the check fail, and the explanation earns 0 for the forensic part. Accepting a colleague's diagnosis without testing it is the failure this variant is built to detect.
- Finding the culprit by reading `git log -p`: acceptable for the end state; the rule asked for a search over behavior, so 2 of the explanation points are lost unless a bisect log is shown.
- Forgetting `git bisect reset`: `HEAD` is detached on a bisect commit; two lines fail.
- An annotated tag `culprit`: accepted by the check (it peels the tag); no penalty.
- `git reset --hard` to the commit before the culprit, on a published branch: 0 for safety, and the check fails.
- Pushing the revert: the task said nothing is pushed; one line fails.
- Recreating the spike from memory, or declaring it lost because "the reflog is empty": 0 for that part of the explanation.

**Reference.** Chapter 14A, sections 14A.10 and 14A.19 to 14A.21; Chapter 13, sections 13.6, 13.8 and 13.12; Chapter 11, section 11.8.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** `git reset --hard` moves the branch ref, and makes the index and the working tree match the target commit. It does not delete objects. The commits it moved away from still exist and are named by the reflogs of `HEAD` and of the branch, and by `ORIG_HEAD` until the next command that writes it; with default settings they stay findable for at least 30 days. *Follow-up:* changes to tracked files that were never staged or committed. They existed only in the working tree, and `--hard` overwrote the files. Staged content survives as dangling blobs, without file names.

**Weak answer.** "Git keeps everything forever." **Reference.** Chapter 13, section 13.2; Chapter 11, section 11.5.

### O2 (3 points)

**Model answer.** It records every value `HEAD` and each branch have had in this clone, with the command that changed it, so any commit I was on in the last weeks can be found and given a name again. Limits: it is local, it is not cloned or pushed, entries expire (90 and 30 days), a deleted branch loses its own reflog, and it knows nothing about work that was never committed. *Follow-up:* yes, the reflog of my remote-tracking branch, and my local branch itself if I had the commits. My `origin/<branch>` reflog recorded the value the server had before my fetch saw the forced update. The server's own reflog usually does not exist: bare repositories keep none by default, and a hosting service has its own records.

**Weak answer.** "It is an undo history." **Reference.** Chapter 13, sections 13.3, 13.4 and 13.10.

### O3 (3 points)

**Model answer.** A commit is reachable when a ref, a reflog entry or another reachable object leads to it. A reset, a rebase, an amend, a branch deletion or a dropped stash moves or removes the last ref that led to it. The object stays; reflog entries keep it alive, then the grace period, and after that a collection deletes it. *Follow-up:* find the tip: the deletion message, the `HEAD` reflog (`git reflog | grep <branch>` shows the checkouts), a teammate's clone or the server, or `git fsck` for dangling commits. Then `git branch <name> <id>`, and verify with `git log`. After a week with default settings everything is still there.

**Weak answer.** "It is garbage collected." **Reference.** Chapter 13, sections 13.2 and 13.8.

### O4 (3 points)

**Model answer.** A binary search over the commits between a known good and a known bad commit: Git checks out a commit in the middle, I or a script say good or bad, and the range halves until one commit is left, the first bad one. The property must be monotonic along the range: good before some commit and bad from it on. A flaky test or a bug that comes and goes gives a wrong answer with full confidence. *Follow-up:* mark them with `git bisect skip`, or let the script return 125, which means "cannot be tested". If the skipped commits surround the culprit, bisect reports a range and not one commit.

**Weak answer.** "It checks every commit." **Reference.** Chapter 14A, sections 14A.20 to 14A.22.

### O5 (4 points)

**Model answer.** First, stop them from running anything else, in particular a clean-up or a collection. Then questions: was the work committed, stashed, staged, or only saved? Then read-only evidence in that order: `git status`, `git reflog` for commits and for the stash movements, `git stash list`, `git fsck` for dangling commits and blobs, the terminal scrollback, and other clones. Whatever is found gets a branch before anything else happens. *Follow-up:* "I never added the files", "I ran `git clean`", "I discarded the changes with restore or checkout", or "I ran `gc --prune=now` afterwards". Then I say exactly why: Git stores content when it is staged, committed or stashed, and this content never was; and I point at editor history and backups. A reasoned "it is gone" is part of the job, and so is the prevention: commit early on a branch, `git stash -u` instead of clean.

**Weak answer.** "Check the reflog", and nothing else. **Reference.** Chapter 13, sections 13.7, 13.9 and 13.12.

### O6 (4 points)

**Model answer.** Blame names the last commit that touched the line. Look past it: `git blame -w` ignores whitespace-only changes, `--ignore-rev <formatter commit>` or an ignore-revs file skips the formatting commit, and then blame names the commit before it. Or follow the line with `git log -L`, or search for the logic with `-S` or `-G`. For the team, record formatting commits in a file named by `blame.ignoreRevsFile`. *Follow-up:* blame follows lines within a file by default. `-M` detects lines moved inside a file and `-C` lines moved or copied from other files in the same commit; repeated, it looks further. `git log --follow` covers a renamed file. A squash merge is the limit: the original commits are not in the history, so blame ends at the squash commit, and the pull request is the place to continue.

**Weak answer.** "Ask the author." **Reference.** Chapter 14A, sections 14A.16 to 14A.19.

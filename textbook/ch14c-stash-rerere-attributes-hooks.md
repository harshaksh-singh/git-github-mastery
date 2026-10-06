# Chapter 14C: Stash Internals, Rerere, Attributes, Hooks

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch14c/`. One demo (`rerere-lock-race`) measures a timing race, so its numbers differ from run to run; it is marked where it appears.

## 14C.1 Why this matters

Four questions a CTO can ask, one for each part of this chapter:

1. "An engineer popped a stash and says the careful staging is gone. Was anything lost?"
2. "The team switched on rerere because one conflict came back at every rebase. Last week a wrong value reached `main` without anyone typing it. How?"
3. "We committed a `.gitattributes` that strips notebook outputs. A new hire's first commit contains 40 MB of outputs. Why did the rule not apply to her?"
4. "We have a pre-commit hook that blocks secrets. A secret is on `main`. Whose fault is that?"

The four topics share one design decision. A repository holds content that is versioned and travels with `clone`, `fetch` and `push` (commits and the files in them, such as `.gitattributes`), and machinery that is local and never travels (`.git/config`, `.git/hooks`, `.git/rr-cache`, `refs/stash`). Everything in this chapter sits on the local side of that line, or straddles it.

The short answers:

1. Nothing was lost. A stash entry is a commit with two or three parents, and the second parent holds the index as it was. A plain `git stash pop` ignores it (section 14C.2).
2. Rerere replays a recorded resolution whenever the same conflict text appears, a wrong one as faithfully as a right one, and with `rerere.autoUpdate` it also stages the result (section 14C.3).
3. `.gitattributes` names a filter. The filter is defined in configuration, and configuration is not cloned. Her clone had the name without the definition, and Git treats that as "no filter" without a warning (sections 14C.4 and 14C.8).
4. Nobody's, as far as Git is concerned. A client-side hook is a file in one clone that one option skips. Policy is enforced where every push arrives: on the server and in CI (sections 14C.11 to 14C.13).

Chapter 11 (Reset, Revert, Restore) teaches the stash commands, Chapter 8 (Merge) conflicts, and Chapter 4 (Working Tree) introduces line endings.

## 14C.2 Stash internals: a stash entry is a small commit graph

**In one sentence.** A stash entry is a commit `W` that records your tracked files, with the commit that was HEAD as its first parent, a commit `I` that records the index as its second parent and, when you stash untracked files, a parentless commit `U` as its third; `refs/stash` points at the newest `W`, and the stash list is the reflog of that ref.

**Analogy.** A labelled envelope with two or three sheets: a photocopy of the bench (the files), a photocopy of the outbox (the index), and the loose notes that were lying around (untracked files). The analogy breaks in one place: there is no drawer for the envelopes. They are ordinary commits in the object database, held by one ref and its log, which is why a dropped stash can be found again.

**Precisely.** The stash manual gives the shape: `W` is "a commit whose tree records the state of the working directory", its first parent is the commit at HEAD, and "the tree of the second parent records the state of the index" ([git-stash](https://git-scm.com/docs/git-stash)). The manual does not name the third parent; `git stash show --include-untracked` and `--only-untracked` read it. Consequences of the shape:

- `git stash show -p` is the diff from `H` to `W`: the staged and the unstaged part appear as one change.
- `git stash apply` merges `W` into your files with `H` as the base (Chapter 11). Only `--index` also reads `I`.
- Revision syntax works on an entry: `stash@{1}^2` is the index commit of the second entry, `stash@{0}:config.yaml` one file of the newest. `stash@{n}` is reflog syntax; there is one ref.

**Inside `.git`.** New objects for `W`, `I` and (with `-u` or `-a`) `U`; the ref `refs/stash`; the log `logs/refs/stash`, one line per entry.

**See it.** A repository with one staged change (`score.py`), one unstaged change (`config.yaml`) and one untracked file (`notes.md`) was stashed with `git stash push -u`. The graph of the entry, with the parents of every commit in brackets:

<!-- snippet: ch14c/stash-anatomy/02-graph -->
```text
# Each line: commit, [its parents], subject.
$ git log --graph --format='%h [%p] %s' 'stash@{0}'
*-.   962e38f [8f8672d 7ee160e 8fb87d5] On main: wip: strip whitespace
|\ \  
| | * 8fb87d5 [] untracked files on main: 8f8672d Add scorer and config
| * 7ee160e [8f8672d] index on main: 8f8672d Add scorer and config
|/  
* 8f8672d [] Add scorer and config
```
<!-- /snippet -->

`962e38f` is `W`, a merge commit with three parents. `8f8672d` is the commit you were on. `7ee160e` is `I`, a child of that commit. `8fb87d5` is `U`: its bracket is empty, so it has no parent. The raw commit shows the same:

<!-- snippet: ch14c/stash-anatomy/03-commit-object -->
```text
$ git show -s --format=raw 'stash@{0}'
commit 962e38fce2cce7e6ec1b3897921414fceb38409b
tree 36051caa44c7daac943f640b3d43f0a50a135455
parent 8f8672db13ec116a0e66b597dde4c3f41fdc2dd2
parent 7ee160e569bbbb323ff60b5e84b8f54b9ef16013
parent 8fb87d55587295bedf701e94a8d5a9d1de921a08
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530

    On main: wip: strip whitespace
```
<!-- /snippet -->

Now the four trees. Compare the blob IDs column by column:

<!-- snippet: ch14c/stash-anatomy/04-trees -->
```text
# H, the commit that was HEAD:
$ git ls-tree -r 'stash@{0}^1'
100644 blob 464dad17678e625818cf5f96c2e878a8b8e21647	config.yaml
100644 blob 2c9e3f43f09999102c43be95c5d1f3ef1d6f6bc0	score.py
# I, the index as it was (second parent):
$ git ls-tree -r 'stash@{0}^2'
100644 blob 464dad17678e625818cf5f96c2e878a8b8e21647	config.yaml
100644 blob 6ba285dc88264166ccae82826a80ecacdd417104	score.py
# W, the tracked files as they were on disk (the stash commit itself):
$ git ls-tree -r 'stash@{0}'
100644 blob b571eab8daac6f68438fc7580829f656c4427932	config.yaml
100644 blob 6ba285dc88264166ccae82826a80ecacdd417104	score.py
# U, the untracked files (third parent, only with -u or -a):
$ git ls-tree -r 'stash@{0}^3'
100644 blob 8b2489b1aa1ff7ba005bedb45f156e8dd99f77f9	notes.md
```
<!-- /snippet -->

`score.py` changes between `H` and `I` (`2c9e3f4` becomes `6ba285d`): the staged change. `config.yaml` changes between `I` and `W` (`464dad1` becomes `b571eab`): the unstaged one. `U` holds only the untracked file. No tree mixes the three kinds of work, so they can be taken apart again.

<!-- snippet: ch14c/stash-anatomy/05-show -->
```text
# What "git stash show -p" prints is the difference between H and W:
$ git stash show -p
diff --git a/config.yaml b/config.yaml
index 464dad1..b571eab 100644
--- a/config.yaml
+++ b/config.yaml
@@ -1 +1 @@
-threshold: 0.5
+threshold: 0.7
diff --git a/score.py b/score.py
index 2c9e3f4..6ba285d 100644
--- a/score.py
+++ b/score.py
@@ -1,2 +1,2 @@
 def score(pred, gold):
-    return pred == gold
+    return pred.strip() == gold.strip()
# The staged part is H against I, the unstaged part is I against W:
$ git diff --stat 'stash@{0}^1' 'stash@{0}^2'
 score.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat 'stash@{0}^2' 'stash@{0}'
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git stash show --only-untracked
 notes.md | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

`git stash show -p` prints both tracked changes together. The two `git diff` commands separate them, because each compares the right pair of commits.

**Picture.**

```text
                    8fb87d5  U   untracked files (no parent)
                           \
        .-------------------962e38f  W   <- refs/stash      tracked files as on disk
       /                   /
   8f8672d  H ---------7ee160e  I                           the index as it was
   (main, HEAD)
```

**The ref and its log.** A second entry is pushed, and then the two files that make up the stash list are printed:

<!-- snippet: ch14c/stash-anatomy/06-ref-and-reflog -->
```text
$ printf 'threshold: 0.9\n' > config.yaml
$ git stash push -m "wip: threshold 0.9"
Saved working directory and index state On main: wip: threshold 0.9
$ git stash list
stash@{0}: On main: wip: threshold 0.9
stash@{1}: On main: wip: strip whitespace
$ cat .git/refs/stash
e5fe33887289800d1015fbecba39e952ff467eb9
$ cat .git/logs/refs/stash
0000000000000000000000000000000000000000 962e38fce2cce7e6ec1b3897921414fceb38409b Lab User <you@example.com> 1788755880 +0530	On main: wip: strip whitespace
962e38fce2cce7e6ec1b3897921414fceb38409b e5fe33887289800d1015fbecba39e952ff467eb9 Lab User <you@example.com> 1788756720 +0530	On main: wip: threshold 0.9
$ git rev-parse 'stash@{0}' 'stash@{1}'
e5fe33887289800d1015fbecba39e952ff467eb9
962e38fce2cce7e6ec1b3897921414fceb38409b
```
<!-- /snippet -->

The ref holds the ID of the newest entry. The log has one line per entry, oldest first, in the reflog format of Chapter 3. `git stash list` prints the message column of this file, which is not necessarily the subject of the commit, as the next transcript shows.

**Building an entry without touching anything.** Two subcommands split `push` into its halves. Scripts use them, and so does Git: the autostash of `git rebase --autostash` is a stash commit that is never put on the list (Chapter 9, section 9.8).

<!-- snippet: ch14c/stash-anatomy/07-create-store -->
```text
$ printf 'threshold: 0.8\n' > config.yaml
# "create" builds the commits and prints the ID. No ref is written and the files stay as they are.
$ git stash create "wip: threshold 0.8"
4bd62aa12a2c6896b596b2b7e718393ed816ccb1
$ git stash list
stash@{0}: On main: wip: threshold 0.9
stash@{1}: On main: wip: strip whitespace
$ git status -s
 M config.yaml
# "store" puts an existing stash commit on the list:
$ git stash store -m 'stored by hand' 4bd62aa
$ git stash list
stash@{0}: stored by hand
stash@{1}: On main: wip: threshold 0.9
stash@{2}: On main: wip: strip whitespace
```
<!-- /snippet -->

`git stash create` wrote the commits and printed the ID of `W`; the list did not change and the file is still modified. `git stash store` appended a reflog line with your message. The commit's own subject is still `On main: wip: threshold 0.8`.

**What `drop` does.**

<!-- snippet: ch14c/stash-anatomy/08-drop -->
```text
$ git stash drop 'stash@{1}'
Dropped stash@{1} (e5fe33887289800d1015fbecba39e952ff467eb9)
$ git stash list
stash@{0}: stored by hand
stash@{1}: On main: wip: strip whitespace
$ cat .git/logs/refs/stash
0000000000000000000000000000000000000000 962e38fce2cce7e6ec1b3897921414fceb38409b Lab User <you@example.com> 1788755880 +0530	On main: wip: strip whitespace
962e38fce2cce7e6ec1b3897921414fceb38409b 4bd62aa12a2c6896b596b2b7e718393ed816ccb1 Lab User <you@example.com> 1788757260 +0530	stored by hand
# The dropped commit still exists as an unreachable object:
$ git cat-file -t e5fe338
commit
```
<!-- /snippet -->

Dropping the middle entry deleted its line from the log and rewrote the next line to follow the entry before it. No object was deleted: `e5fe338` is still a commit, unreachable now, until unreachable objects are pruned (two weeks by default; Chapter 13: Recovery). Lab 8.6 recovers such an entry.

**Stashes that travel.** Nothing fetches or pushes `refs/stash`. Since Git 2.51, `git stash export` writes all entries into one chain of ordinary commits that can be pushed like a branch, and `git stash import` turns such a chain back into entries:

<!-- snippet: ch14c/stash-anatomy/09-export -->
```text
$ git stash export --to-ref refs/stashes/laptop
$ git log --graph --format='%h %s' refs/stashes/laptop
*   14ab5f1 git stash: On main: wip: threshold 0.8
|\  
| *   4bd62aa On main: wip: threshold 0.8
| |\  
| | * b01d0a0 index on main: 8f8672d Add scorer and config
| |/  
* |   1f87106 git stash: On main: wip: strip whitespace
|\ \  
| | \     
| |  \    
| *-. \   962e38f On main: wip: strip whitespace
| |\ \ \  
| | |_|/  
| |/| |   
| | | * 8fb87d5 untracked files on main: 8f8672d Add scorer and config
| | * 7ee160e index on main: 8f8672d Add scorer and config
| |/  
| * 8f8672d Add scorer and config
* 73c9bab 
```
<!-- /snippet -->

Each `git stash: ...` commit has two parents: the previous commit of the chain and one stash commit. After a push of that ref and a fetch elsewhere, `git stash import <commit>` rebuilds the list; the demo `ch14c/stash-anatomy` runs it. Imported entries show their commit subjects, because messages such as `stored by hand` exist only in the reflog of the repository that wrote them.

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| 🟡 `git stash push [-u]` | tracked files reset to HEAD; with `-u` untracked files removed | reset to HEAD | unchanged | unchanged | objects for `W`, `I`, (`U`); `refs/stash` moved; one line added to `logs/refs/stash`; `ORIG_HEAD` rewritten | unchanged | unchanged |
| 🟢 `git stash create`, then `store <commit>` | unchanged | unchanged | unchanged | unchanged | objects; then `refs/stash` moved and one log line added | unchanged | unchanged |
| 🔴 `git stash drop` | unchanged | unchanged | unchanged | unchanged | one log line removed; `refs/stash` moved or deleted; objects stay, unreachable | unchanged | unchanged |

**In production.** When the staging mattered, bring work back with `git stash pop --index`; when you forgot, restore the index from the second parent of the dropped commit, whose ID `pop` printed (Lab 14.6). When you need one file from an entry, read it with `git show 'stash@{0}:path'` or `git restore --source='stash@{0}' -- path` and leave the entry alone.

## 14C.3 Rerere: resolve a conflict once

**In one sentence.** With `rerere.enabled` set, Git records the text of every conflict together with what you made of it, and when a conflict with the same text appears again, in any merge, rebase, cherry-pick, revert or `git am -3`, it writes your earlier resolution into the file instead of the conflict markers.

**Analogy.** A notebook next to the merge desk, each page with a conflict on the left and your answer on the right. When the same left side turns up, Git copies the right side into the file. The analogy breaks where the danger is: the notebook matches text, not intent, and never asks before it copies.

**Precisely.** "Rerere" stands for "reuse recorded resolution" ([git-rerere](https://git-scm.com/docs/git-rerere)). `git merge`, `git rebase`, `git commit` and the other commands that can stop on a conflict call `git rerere` for you; you rarely type it. It works in two moments:

1. **When a conflict appears.** Git normalizes the conflict in each file (labels stripped from the markers, the two sides sorted, the base part of `diff3` output removed), hashes the conflict hunks, and uses the hash as the name of a directory in `.git/rr-cache`. Without a recorded resolution there, it stores the normalized conflict as `preimage` and prints `Recorded preimage`. With one, it merges the old conflict, the old resolution and the new conflict and, when that merge is clean, writes the result into your file and prints `Resolved ... using previous resolution`.
2. **When you conclude.** At the commit (or `git rebase --continue`), Git stores the resolved file as `postimage` and prints `Recorded resolution`.

The normalization is why one record serves both directions of a merge, and a merge as well as a rebase: the name depends on the two competing texts, not on branch names, on who is "ours", or on the path ([rerere technical notes](https://github.com/git/git/blob/v2.56.0/Documentation/technical/rerere.adoc)). Rerere leaves the index alone: a replayed file stays unmerged until you `git add` it, unless `rerere.autoUpdate` is true.

**Inside `.git`.** `rr-cache/<conflict-id>/preimage` and `postimage` (and at times a scratch file `thisimage`); `MERGE_RR`, which maps the conflicted paths of the operation in progress to conflict IDs; and, briefly, `MERGE_RR.lock`. All of it is local: `rr-cache` is not pushed, fetched or cloned. `git rerere gc` prunes unresolved records after 15 days and resolved ones after 60 (`gc.rerereUnresolved`, `gc.rerereResolved`).

**See it: a repeated merge.** `feature/rerank` is a long-lived branch. It and `main` changed the same two lines of `retrieval.yaml`. You want to test the branch against the newest `main` today and merge it for real next week, without a test merge in its history: the workflow the rerere manual describes.

<!-- snippet: ch14c/rerere-merge/01-first-conflict -->
```text
$ git log --oneline --graph --all
* 96196ef Raise top_k to 20
| * 62e40dc Add reranker module
| * c9ca15a Enable reranking over the top 50 candidates
|/  
* d9ec3c5 Add retrieval config
$ git config set rerere.enabled true
$ git switch -q feature/rerank
$ git merge main
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
Recorded preimage for 'retrieval.yaml'
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

The new line is `Recorded preimage for 'retrieval.yaml'`. What was recorded, next to what is in your file:

<!-- snippet: ch14c/rerere-merge/02-recorded -->
```text
$ ls .git/rr-cache
ec4b2990356a9f0ab0af396e6ce888496e91b4c7
$ cat .git/rr-cache/*/preimage
model: bge-small
<<<<<<<
top_k: 20
rerank: false
=======
top_k: 50
rerank: true
>>>>>>>
$ cat retrieval.yaml
model: bge-small
<<<<<<< HEAD
top_k: 50
rerank: true
=======
top_k: 20
rerank: false
>>>>>>> main
$ git rerere status
retrieval.yaml
```
<!-- /snippet -->

The preimage has bare markers and the two sides in sorted order (`top_k: 20` first), although your file shows `HEAD` first. The directory name is the conflict ID. Resolve as usual; `git rerere diff` compares the recorded conflict with your file:

<!-- snippet: ch14c/rerere-merge/03-resolve -->
```text
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
$ git rerere diff
--- a/retrieval.yaml
+++ b/retrieval.yaml
@@ -1,8 +1,3 @@
 model: bge-small
-<<<<<<<
-top_k: 20
-rerank: false
-=======
 top_k: 50
 rerank: true
->>>>>>>
$ git commit -am "Test merge of main"
Recorded resolution for 'retrieval.yaml'.
[feature/rerank 047a898] Test merge of main
$ ls .git/rr-cache/*
postimage
preimage
$ cat .git/rr-cache/*/postimage
model: bge-small
top_k: 50
rerank: true
```
<!-- /snippet -->

The commit printed `Recorded resolution`, and the directory now has both halves. The test merge has done its job and is removed:

<!-- snippet: ch14c/rerere-merge/04-throw-away -->
```text
# The test merge served its purpose. Remove it; the recorded resolution stays.
$ git reset --hard HEAD^
HEAD is now at 62e40dc Add reranker module
$ ls .git/rr-cache/*
postimage
preimage
```
<!-- /snippet -->

A week later the branch is merged into `main`, in the opposite direction from the test:

<!-- snippet: ch14c/rerere-merge/05-real-merge -->
```text
$ git switch -q main
$ git merge feature/rerank
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
Resolved 'retrieval.yaml' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

Read this output with care. The merge still reports `CONFLICT`, still says `Automatic merge failed`, and still exits with status 1. Only the line `Resolved 'retrieval.yaml' using previous resolution.` tells you that the file no longer contains markers:

<!-- snippet: ch14c/rerere-merge/06-state -->
```text
$ git status -s
A  rerank.py
UU retrieval.yaml
$ cat retrieval.yaml
model: bge-small
top_k: 50
rerank: true
$ git rerere remaining
$ git ls-files -u
100644 fa370c130d79ca732a1fe0c9a0f8d556609b92b9 1	retrieval.yaml
100644 7ac2dd090cea0e852d25ee65af7e485b7a90e698 2	retrieval.yaml
100644 820d682527a387ff7594053d7bb1a01c230cf715 3	retrieval.yaml
```
<!-- /snippet -->

The file holds your resolution. `git status` says `UU` and the index still has three stages, because rerere wrote the file and nothing else. `git rerere remaining` prints nothing: no path is left to resolve by hand. The stop is your review point. Read the file, run the tests, then stage and conclude:

<!-- snippet: ch14c/rerere-merge/07-finish -->
```text
$ git add retrieval.yaml
$ git commit --no-edit
[main cad2174] Merge branch 'feature/rerank'
$ git log --oneline --graph
*   cad2174 Merge branch 'feature/rerank'
|\  
| * 62e40dc Add reranker module
| * c9ca15a Enable reranking over the top 50 candidates
* | 96196ef Raise top_k to 20
|/  
* d9ec3c5 Add retrieval config
```
<!-- /snippet -->

**See it: a rebase.** The same record, made in a merge, serves a rebase of the branch onto `main`. In a rebase the sides are swapped (Chapter 9, section 9.11), and the normalization makes that irrelevant:

<!-- snippet: ch14c/rerere-rebase/01-rebase -->
```text
$ git switch -q feature/rerank
$ git rebase main
Rebasing (1/2)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply c9ca15a... Enable reranking over the top 50 candidates
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Resolved 'retrieval.yaml' using previous resolution.
Could not apply c9ca15a... # Enable reranking over the top 50 candidates
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch14c/rerere-rebase/02-continue -->
```text
$ git status -s
UU retrieval.yaml
$ cat retrieval.yaml
model: bge-small
top_k: 50
rerank: true
$ git add retrieval.yaml
$ git rebase --continue
[detached HEAD 74fea46] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/rerank.
$ git log --oneline --graph --all
* 4dd76a7 Add reranker module
* 74fea46 Enable reranking over the top 50 candidates
* 96196ef Raise top_k to 20
* d9ec3c5 Add retrieval config
```
<!-- /snippet -->

With `rerere.autoUpdate` set, the replayed file is also staged. The rebase still stops, and only `git rebase --continue` is left to do:

<!-- snippet: ch14c/rerere-rebase/03-autoupdate -->
```text
$ git config set rerere.autoUpdate true
$ git -c advice.mergeConflict=false rebase main
Rebasing (1/2)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply c9ca15a... Enable reranking over the top 50 candidates
Staged 'retrieval.yaml' using previous resolution.
Could not apply c9ca15a... # Enable reranking over the top 50 candidates
[exit status: 1]
$ git status -s
M  retrieval.yaml
$ git rebase --continue
[detached HEAD f0e118a] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/rerank.
```
<!-- /snippet -->

**Picture.**

```text
   conflict appears              you resolve and commit        the same conflict again
   file: <<<<<<< ... >>>>>>>     file: your resolution         file: <<<<<<< ... >>>>>>>
          | normalize, hash             |                             | normalize, hash: same <id>
          v                             v                             v
   rr-cache/<id>/preimage        rr-cache/<id>/postimage       3-way merge of preimage, postimage, new conflict
                                                                      |
                                                                      v
                                                               file: your resolution (index still unmerged)
```

**State table.**

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| A conflict that rerere has not seen | conflict markers, as usual | stages 1 to 3 | unchanged | unchanged | `rr-cache/<id>/preimage`, `MERGE_RR` | unchanged | unchanged |
| Concluding commit or `--continue` | unchanged | resolved | new commit | moved | `rr-cache/<id>/postimage` | unchanged | unchanged |
| A conflict that rerere knows | your recorded resolution | stages 1 to 3 (stage 0 with `rerere.autoUpdate`) | unchanged | unchanged | `MERGE_RR` | unchanged | unchanged |
| 🟡 `git rerere forget <path>` | unchanged | unchanged | unchanged | unchanged | `postimage` deleted, `preimage` replaced by the current conflict | unchanged | unchanged |

### The risk: a wrong resolution is replayed as faithfully as a right one

Suppose the test merge had been resolved in a hurry: `top_k` kept at 20 from `main`, `rerank: true` from the branch. Each line is valid, and together they starve the reranker of candidates. Git cannot know that, and the real merge replays the record:

<!-- snippet: ch14c/rerere-wrong/01-replayed -->
```text
$ cat .git/rr-cache/*/postimage
model: bge-small
top_k: 20
rerank: true
$ git merge feature/rerank
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
Resolved 'retrieval.yaml' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat retrieval.yaml
model: bge-small
top_k: 20
rerank: true
```
<!-- /snippet -->

Apart from the file content, the output is identical to the correct case. With `rerere.autoUpdate` and a rebase, the wrong value is one `git rebase --continue` away from being a commit (Lab 14.5 repairs that case). The correction has three steps: make rerere forget, bring the conflict back, resolve again.

<!-- snippet: ch14c/rerere-wrong/02-forget -->
```text
$ git rerere forget retrieval.yaml
Updated preimage for 'retrieval.yaml'
Forgot resolution for 'retrieval.yaml'
$ ls .git/rr-cache/*
preimage
thisimage
$ git restore --merge retrieval.yaml
$ cat retrieval.yaml
model: bge-small
<<<<<<< ours
top_k: 20
rerank: false
=======
top_k: 50
rerank: true
>>>>>>> theirs
```
<!-- /snippet -->

`git rerere forget <path>` deletes the recorded resolution for the conflict in that path, and 🔴 `git restore --merge <path>` (older: `git checkout --merge <path>`) overwrites the file with the conflict rebuilt from the index. The new resolution is recorded at the commit:

<!-- snippet: ch14c/rerere-wrong/03-record-again -->
```text
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
$ git add retrieval.yaml
$ git commit --no-edit
Recorded resolution for 'retrieval.yaml'.
[main f22692f] Merge branch 'feature/rerank'
$ cat .git/rr-cache/*/postimage
model: bge-small
top_k: 50
rerank: true
```
<!-- /snippet -->

If the wrong merge is already committed and not pushed, undo it first (`git reset --keep HEAD^`, Chapter 11), merge again, and then forget. If it is pushed, fix forward with a new commit and still forget, or the next rebase brings the mistake back.

### The lock race between rerere and automatic maintenance

While this chapter was written, replays of the rebase transcripts failed now and then with a message that has nothing to do with conflicts. Two correct features collide:

```text
Observed behavior : "git rebase --continue" with rerere enabled sometimes ends at the next conflicting commit with
                    "fatal: Unable to create '.../.git/MERGE_RR.lock': File exists." (exit status 128).
Git state         : the rebase is stopped at that commit with conflict markers; rerere has neither recorded the
                    conflict nor replayed a resolution for it.
Mechanism         : each commit of a rebase starts "git maintenance run --auto" in the background. Since Git 2.54
                    its default strategy includes the task rerere-gc, which runs whenever rr-cache has an entry
                    (maintenance.rerere-gc.auto defaults to 1) and takes MERGE_RR.lock while it works.
Root cause        : the background task and the next step of the rebase want the same lock at the same moment.
Why Git does this : the lock protects MERGE_RR from two writers; pruning rr-cache became a maintenance task.
Correct fix       : nothing is damaged. Run "git rerere", resolve, "git add", "git rebase --continue".
Prevention        : "git config set maintenance.rerere-gc.auto 0" where you rebase with rerere, and an occasional
                    "git rerere gc" by hand.
```

The failure and the recovery on demand: an `exec` line of the rebase creates the lock file after each replayed commit, as a stand-in for the background task.

<!-- snippet: ch14c/rerere-lock/01-locked -->
```text
# Stand-in for the background task: after each replayed commit, hold the lock that rerere needs.
$ git -c advice.mergeConflict=false rebase -x 'touch .git/MERGE_RR.lock' main
Rebasing (1/6)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply 4c042d7... Enable reranking over the top 50 candidates
Recorded preimage for 'retrieval.yaml'
Could not apply 4c042d7... # Enable reranking over the top 50 candidates
[exit status: 1]
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml && git add retrieval.yaml
$ git -c advice.mergeConflict=false rebase --continue
Recorded resolution for 'retrieval.yaml'.
[detached HEAD 4f7e530] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/6)
Executing: touch .git/MERGE_RR.lock
Rebasing (3/6)
Auto-merging scoring.py
CONFLICT (content): Merge conflict in scoring.py
error: could not apply 27f7ed2... Blend dense scores into the ranking
fatal: Unable to create '$LAB/ch14c/rerere-lock/ranker/.git/MERGE_RR.lock': File exists.

Another git process seems to be running in this repository, or the lock file may be stale
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch14c/rerere-lock/02-recover -->
```text
$ git status -s
UU scoring.py
# The real background task removes its lock when it ends. Remove the stand-in by hand:
$ rm .git/MERGE_RR.lock
# rerere never saw this conflict. Run it yourself:
$ git rerere status
$ git rerere
Recorded preimage for 'scoring.py'
$ git rerere status
scoring.py
```
<!-- /snippet -->

After the failure `git rerere status` prints nothing: rerere never saw this conflict, so a resolution made now would not be recorded. One manual `git rerere` repairs that. How often does the real race occur? The demo `rerere-lock-race` runs the same rebase twenty times per configuration:

<!-- snippet: ch14c/rerere-lock-race/01-counts -->
```text
# Twenty rebases with two conflicting commits each, per configuration (labs/ch14c/rerere-lock-race.sh):
default: MERGE_RR.lock failures in 20 rebases: 1
no-rerere-gc: MERGE_RR.lock failures in 20 rebases: 0
```
<!-- /snippet -->

This snippet is volatile: the first number depends on timing and varied between 1 and 10 in the runs made for this chapter; the second was always 0. Every rerere repository in this chapter and in Lab 14.5 therefore sets `maintenance.rerere-gc.auto=0` (`labs/ch14c/fixtures.bash`).

> **Unverified.** The race was observed on Git 2.55.0 on macOS only. No manual or release note read for this course describes it, and Git 2.56 was not tested. The mechanism is inferred from the [maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc) and the measurement above.

**In production.** Turn rerere on for people who rebase long branches or rebuild integration branches. Leave `rerere.autoUpdate` off unless tests run before every `--continue`: the stop with `UU` is the only review a replay gets. Know the limits: records are per clone, they expire, and a conflict whose text has changed is a new conflict. To teach rerere from merges that were resolved before it was switched on, the Git distribution ships [contrib/rerere-train.sh](https://github.com/git/git/blob/v2.56.0/contrib/rerere-train.sh), which replays old merge commits; it is not installed as a command.

## 14C.4 `.gitattributes`: per-path settings that travel, drivers that do not

**In one sentence.** A `.gitattributes` file attaches named attributes to paths, and Git consults them whenever it converts, compares, merges or archives a file; the file is versioned and reaches every clone, while the programs that some attributes name are defined in configuration and reach nobody.

**Analogy.** Labels on folders in a shared filing cabinet: "text", "do not merge", "show through viewer X". Everyone sees the labels. Whether viewer X exists is a matter of each reader's own desk, and here the analogy breaks: a missing viewer produces no complaint.

**Precisely.** Each line is a pattern followed by attributes ([gitattributes](https://git-scm.com/docs/gitattributes)). For one path, an attribute is in one of four states:

| Written as | State | `git check-attr` prints |
|---|---|---|
| `text` | set | `set` |
| `-text` | unset | `unset` |
| `eol=lf` | set to a value | the value |
| not mentioned, or `!text` | unspecified | `unspecified` |

Patterns follow the rules of `.gitignore` with two exceptions: negative patterns are forbidden, and a pattern that matches a directory does not apply to the files inside it (write `docs/**` to reach them). Within one file a later line overrides an earlier one, per attribute. Between files the order of precedence is:

1. `.git/info/attributes` (local to this clone, not versioned);
2. the `.gitattributes` in the directory of the path, then those of its parent directories up to the top of the working tree, the nearer the stronger;
3. the file named by `core.attributesFile` (default `$XDG_CONFIG_HOME/git/attributes` or `~/.config/git/attributes`);
4. the system-wide file.

A macro attribute sets several others at once; the one built-in macro is `binary`, defined as `-diff -merge -text`.

**Inside `.git`.** Nothing, unless you use `.git/info/attributes`. A `.gitattributes` file is an ordinary tracked file. The drivers it may name live in `.git/config` or in a global configuration file.

**See it.** A training repository with two attribute files:

<!-- snippet: ch14c/attr-basics/01-files -->
```text
$ cat .gitattributes
# pattern     attributes
*             text=auto
*.sh          text eol=lf
*.csv         text eol=crlf
*.bin         binary
CHANGELOG.md  merge=union
docs          export-ignore
.gitattributes export-ignore
$ cat data/.gitattributes
# Vendor exports: keep every byte as delivered.
*.csv  -text
```
<!-- /snippet -->

`git check-attr` answers "which attributes does Git see for this path", the first diagnostic for every problem in the next four sections:

<!-- snippet: ch14c/attr-basics/02-check-attr -->
```text
$ git check-attr -a -- src/train.py scripts/run.sh data/encoder.bin
src/train.py: text: auto
scripts/run.sh: text: set
scripts/run.sh: eol: lf
data/encoder.bin: binary: set
data/encoder.bin: diff: unset
data/encoder.bin: merge: unset
data/encoder.bin: text: unset
# Ask for named attributes to see the unspecified state as well:
$ git check-attr text eol merge -- src/train.py
src/train.py: text: auto
src/train.py: eol: unspecified
src/train.py: merge: unspecified
```
<!-- /snippet -->

`data/encoder.bin` matched `*` and `*.bin`: the later line won for `text`, and the macro `binary` expanded into three unset attributes.

<!-- snippet: ch14c/attr-basics/03-precedence -->
```text
# The same pattern, one file at the top and one below data/:
$ git check-attr text eol -- labels.csv data/labels.csv
labels.csv: text: set
labels.csv: eol: crlf
data/labels.csv: text: unset
data/labels.csv: eol: crlf
# .git/info/attributes is not versioned and beats every .gitattributes file:
$ printf 'data/labels.csv text eol=lf\n' > .git/info/attributes
$ git check-attr text eol -- data/labels.csv
data/labels.csv: text: set
data/labels.csv: eol: lf
$ rm .git/info/attributes
```
<!-- /snippet -->

For `data/labels.csv` the file in `data/` unset `text`, and `eol` still comes from the top-level file: precedence is decided attribute by attribute. Then `.git/info/attributes` overrode both.

`export-ignore` concerns none of the conversions: it keeps a path out of `git archive`, for what belongs in the repository and not in a release tarball:

<!-- snippet: ch14c/attr-basics/04-export-ignore -->
```text
$ git ls-files
.gitattributes
data/.gitattributes
data/encoder.bin
data/labels.csv
docs/design.md
labels.csv
scripts/run.sh
src/train.py
$ git archive --format=tar HEAD | tar -tf -
data/
data/encoder.bin
data/labels.csv
labels.csv
scripts/
scripts/run.sh
src/
src/train.py
```
<!-- /snippet -->

`docs` and both attribute files are tracked and absent from the archive. Its sibling `export-subst` expands placeholders such as `$Format:%H$` while archiving, so that a tarball can carry the ID of its commit.

**Which attributes need configuration.** `text`, `eol`, `export-ignore`, `-diff`, `-merge`, the built-in diff patterns and the built-in merge drivers work from the attribute alone. `diff=<name>`, `merge=<name>` and `filter=<name>` with names of your own need a definition in configuration; the table in section 14C.8 says what happens without one. The manual also describes `whitespace`, `conflict-marker-size`, `working-tree-encoding`, `ident` and `delta`.

**In production.** Commit a `.gitattributes` at the top of the repository early in the life of the project. When a file "behaves strangely" (always modified, shown as binary, never conflicting), run `git check-attr -a -- <path>` first.

> **GitHub, not Git.** GitHub reads `.gitattributes` for purposes of its own, such as the `linguist-*` attributes for language statistics and collapsed diffs. Those names mean nothing to Git.

## 14C.5 Line endings: `text`, `eol`, and what `core.autocrlf` cannot do

**In one sentence.** A path with the `text` attribute is stored with LF line endings in the repository whatever its endings are on disk, `eol` chooses the endings that a checkout writes, and `* text=auto` lets Git decide per file which files are text.

**Precisely.** Chapter 4 (section 4.13) showed the symptom: an editor rewrites the line endings and every line of the file counts as changed. The states of `text` decide whether Git converts ([gitattributes](https://git-scm.com/docs/gitattributes)):

| `text` is | On `git add` | On checkout |
|---|---|---|
| set | CRLF becomes LF, always | LF becomes CRLF if `eol=crlf` (or the platform default says so) |
| unset (`-text`) | bytes are stored as they are | bytes are written as they are |
| `auto` | as "set" if Git judges the content to be text **and** the file is not already stored with CRLF | the same condition |
| unspecified | `core.autocrlf` decides | `core.autocrlf` and `core.eol` decide |

`eol=lf` and `eol=crlf` fix the working-tree endings for a path and imply `text`. Without `eol`, a text file is checked out with CRLF on Windows and LF elsewhere, unless `core.eol` or `core.autocrlf` say otherwise.

`core.autocrlf` is the older, per-user mechanism: `true` converts in both directions, `input` only on the way in. It is not deprecated, and it is not a team policy, for two reasons the transcript shows:

<!-- snippet: ch14c/attr-eol/01-before -->
```text
$ git ls-files --eol
i/crlf  w/crlf  attr/                 	loader.py
i/lf    w/lf    attr/                 	run.sh
i/crlf  w/crlf  attr/                 	sample.csv
```
<!-- /snippet -->

A teammate on Windows committed two files with CRLF (`i/` is the index, `w/` the working tree, `attr/` the attributes in force).

<!-- snippet: ch14c/attr-eol/02-autocrlf -->
```text
# A personal setting converts what YOU add from now on:
$ printf 'def clean(row):\r\n    return row.strip()\r\n' > clean.py
$ git -c core.autocrlf=input add clean.py
warning: in the working copy of 'clean.py', CRLF will be replaced by LF the next time Git touches it
$ git ls-files --eol clean.py loader.py
i/lf    w/crlf  attr/                 	clean.py
i/crlf  w/crlf  attr/                 	loader.py
# It does not touch a file that is already stored with CRLF, and a teammate without the setting
# still commits CRLF:
$ printf 'def split(row):\r\n    return row.split()\r\n' > split.py
$ git add split.py
$ git ls-files --eol split.py
i/crlf  w/crlf  attr/                 	split.py
```
<!-- /snippet -->

Your setting normalized the file you added. It did not touch `loader.py`, which is already stored with CRLF, and it had no power over the next commit made without it. A configuration value covers what one person adds on one machine. An attribute is part of the project.

<!-- snippet: ch14c/attr-eol/03-attributes -->
```text
$ printf '* text=auto\n*.sh text eol=lf\n*.csv text eol=crlf\n' > .gitattributes
$ git status -s
 M sample.csv
?? .gitattributes
$ git add --renormalize .
$ git status -s
M  loader.py
M  sample.csv
M  split.py
?? .gitattributes
$ git diff --cached --stat
 loader.py  | 4 ++--
 sample.csv | 4 ++--
 split.py   | 4 ++--
 3 files changed, 6 insertions(+), 6 deletions(-)
```
<!-- /snippet -->

Writing the attributes changed what `git status` reports: `sample.csv` now has `text` set, so its stored CRLF no longer matches what Git would store. `loader.py` and `split.py` fall under `text=auto` and are left alone because they are already stored with CRLF, so that introducing `text=auto` does not by itself rewrite a project. `git add --renormalize .` is the deliberate rewrite: it applies the current "clean" conversion to every tracked file and stages the result ([git-add](https://git-scm.com/docs/git-add)).

<!-- snippet: ch14c/attr-eol/04-after -->
```text
$ git add .gitattributes
$ git commit -q -m "Normalize line endings with .gitattributes"
$ git ls-files --eol
i/lf    w/lf    attr/text=auto        	.gitattributes
i/lf    w/crlf  attr/text=auto        	clean.py
i/lf    w/crlf  attr/text=auto        	loader.py
i/lf    w/lf    attr/text eol=lf      	run.sh
i/lf    w/crlf  attr/text eol=crlf    	sample.csv
i/lf    w/crlf  attr/text=auto        	split.py
```
<!-- /snippet -->

Every file is `i/lf` now. Files on disk keep their endings until Git writes them again:

<!-- snippet: ch14c/attr-eol/05-fresh-checkout -->
```text
# The index now holds LF. Files on disk keep their old endings until they are written again:
$ rm loader.py sample.csv split.py
$ git restore .
$ git ls-files --eol
i/lf    w/lf    attr/text=auto        	.gitattributes
i/lf    w/crlf  attr/text=auto        	clean.py
i/lf    w/lf    attr/text=auto        	loader.py
i/lf    w/lf    attr/text eol=lf      	run.sh
i/lf    w/crlf  attr/text eol=crlf    	sample.csv
i/lf    w/lf    attr/text=auto        	split.py
```
<!-- /snippet -->

The rewritten `loader.py` and `split.py` have LF on this Mac, `sample.csv` has CRLF on every platform because of `eol=crlf`, and `clean.py`, which was not rewritten, keeps its CRLF.

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| 🟡 `git add --renormalize .` | unchanged | every tracked file re-added through the current conversion and filters; new blobs where the stored form changes | unchanged | unchanged | new blobs | unchanged | unchanged |

**In production.** The renormalizing commit touches every line of every converted file. Make it a commit of its own, announce it, merge open branches first where you can, and list its ID in a file that `git blame --ignore-revs-file <file>` (or `blame.ignoreRevsFile`) reads. Unmerged work will conflict on those files; `git merge -X renormalize` (or `merge.renormalize=true`) normalizes all three versions before merging and removes the conflicts that come from the conversion alone. Mark files that must keep their bytes (vendor exports, fixtures with deliberate CRLF, everything binary) with `-text` or `binary`.

> **Outdated advice.** "Set `core.autocrlf` and you are done." The setting is a convenience for one user. The Git FAQ recommends marking text and binary files in `.gitattributes` ([gitfaq](https://git-scm.com/docs/gitfaq)), and the attributes manual gives the procedure used above: `* text=auto`, then one `git add --renormalize .`.

## 14C.6 Diff drivers: `textconv`, hunk headers and `binary`

**In one sentence.** The `diff` attribute tells Git how to show changes to a path: not at all (`-diff`), with a named built-in pattern set for hunk headers (`diff=python`), or through a driver that you define in configuration, of which `textconv` is the most useful kind.

**Precisely.** A `textconv` program receives the name of a temporary file and prints a text rendering of it; Git then diffs the renderings ([gitattributes](https://git-scm.com/docs/gitattributes)). The conversion is one-way and meant for people: `git diff`, `git show` and `git log -p` use it, and `git format-patch` never does, because a patch made from converted text could not be applied. `diff.<name>.cachetextconv` caches renderings, and `diff.<name>.command` replaces the diff program altogether. `-diff` (or the `binary` macro) marks a file as binary: Git prints `Binary files differ`.

**See it.** A notebook was run again after one cell was edited. The raw diff mixes the edit with a new execution count and new output:

<!-- snippet: ch14c/attr-diff/01-raw-diff -->
```text
$ git diff --stat
 eda.ipynb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git diff eda.ipynb
diff --git a/eda.ipynb b/eda.ipynb
index 41de20e..e0025c4 100644
--- a/eda.ipynb
+++ b/eda.ipynb
@@ -9,19 +9,19 @@
   },
   {
    "cell_type": "code",
-   "execution_count": 7,
+   "execution_count": 9,
    "metadata": {},
    "outputs": [
     {
      "name": "stdout",
      "output_type": "stream",
      "text": [
-      "accuracy 0.81\n"
+      "accuracy 0.84\n"
      ]
     }
    ],
    "source": [
-    "print('accuracy', evaluate(model))"
+    "print('accuracy', evaluate(model, split='test'))"
    ]
   }
  ],
```
<!-- /snippet -->

Three changed lines, of which one matters. Name a driver in `.gitattributes`:

<!-- snippet: ch14c/attr-diff/02-attribute-only -->
```text
$ printf '*.ipynb diff=notebook\n' > .gitattributes
$ git check-attr diff -- eda.ipynb
eda.ipynb: diff: notebook
# The attribute names a driver that no configuration defines yet, so nothing changes:
$ git diff --stat eda.ipynb
 eda.ipynb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

`git check-attr` reports the attribute, and the diff is unchanged: an attribute that names an undefined driver has no effect and causes no message. Define the driver:

<!-- snippet: ch14c/attr-diff/03-driver -->
```text
$ cat tools/nbsource.py
#!/usr/bin/env python3
"""textconv for notebooks: print only the source of each cell."""
import json
import sys

nb = json.load(open(sys.argv[1], encoding="utf-8"))
for n, cell in enumerate(nb["cells"], 1):
    print(f"# cell {n} ({cell['cell_type']})")
    print("".join(cell["source"]))
$ git config set diff.notebook.textconv 'python3 tools/nbsource.py'
$ git diff eda.ipynb
diff --git a/eda.ipynb b/eda.ipynb
index 41de20e..e0025c4 100644
--- a/eda.ipynb
+++ b/eda.ipynb
@@ -1,4 +1,4 @@
 # cell 1 (markdown)
 # Error analysis
 # cell 2 (code)
-print('accuracy', evaluate(model))
+print('accuracy', evaluate(model, split='test'))
```
<!-- /snippet -->

The header still names `eda.ipynb` and the real blob IDs. The body is the difference between the two renderings: one line of code.

<!-- snippet: ch14c/attr-diff/04-scope -->
```text
# textconv is for reading. Commands that produce patches for machines ignore it:
$ git diff --no-textconv --stat eda.ipynb
 eda.ipynb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git add . && git commit -q -m "Evaluate on the test split"
$ git log -1 -p --format=%s -- eda.ipynb
Evaluate on the test split

diff --git a/eda.ipynb b/eda.ipynb
index 41de20e..e0025c4 100644
--- a/eda.ipynb
+++ b/eda.ipynb
@@ -1,4 +1,4 @@
 # cell 1 (markdown)
 # Error analysis
 # cell 2 (code)
-print('accuracy', evaluate(model))
+print('accuracy', evaluate(model, split='test'))
$ git format-patch -1 --stdout -- eda.ipynb | grep -c "execution_count"
2
```
<!-- /snippet -->

`--no-textconv` switches the conversion off, `git log -p` uses it, and the patch that `format-patch` writes contains the raw JSON (hence the two `execution_count` lines).

**Hunk headers.** The text after `@@ ... @@` is meant to name the enclosing function. Git finds it with a pattern, and the default pattern does not know your language. A set of built-in drivers does (the manual lists `python`, `java`, `golang`, `rust`, `markdown`, `bash` and about twenty more), and they need only the attribute:

<!-- snippet: ch14c/attr-diff/05-funcname -->
```text
$ git diff metrics.py
diff --git a/metrics.py b/metrics.py
index 75ceae5..7bfb222 100644
--- a/metrics.py
+++ b/metrics.py
@@ -5,7 +5,7 @@ class Accuracy:
         if gold is None:
             return
         self.pairs.append((pred, gold))
-        self.hits += int(pred == gold)
+        self.hits += int(pred.strip() == gold.strip())
 
     def result(self):
         return self.hits / self.total
$ printf '*.py diff=python\n' >> .gitattributes
$ git diff metrics.py
diff --git a/metrics.py b/metrics.py
index 75ceae5..7bfb222 100644
--- a/metrics.py
+++ b/metrics.py
@@ -5,7 +5,7 @@ def update(self, pred, gold):
         if gold is None:
             return
         self.pairs.append((pred, gold))
-        self.hits += int(pred == gold)
+        self.hits += int(pred.strip() == gold.strip())
 
     def result(self):
         return self.hits / self.total
```
<!-- /snippet -->

The first header says `class Accuracy:`, the second `def update(self, pred, gold):`.

**In production.** The same technique serves other formats that are text to a machine and noise to a reader: lock files, exported JSON, SVG. Two cautions. A `textconv` program runs with your permissions on every diff of a matching file. And a rendering hides what it leaves out: the diff above no longer shows that the output changed.

## 14C.7 Merge drivers: `union`, `-merge` and your own

**In one sentence.** The `merge` attribute chooses the file-level merge for a path when both sides changed it: the normal three-way text merge, a refusal to merge by content (`-merge`, also spelled `merge=binary`), the built-in `union` driver that keeps the lines of both sides, or a command of your own.

**Precisely.** A custom driver is a configuration section `merge.<name>` with a `driver` command line. Git calls it with temporary files for the three versions: `%O` (base), `%A` (current branch) and `%B` (other branch). The driver leaves the result in `%A` and exits with status 0 for a clean merge or 1 to 128 for a conflict ([gitattributes](https://git-scm.com/docs/gitattributes)). The attribute applies to merges, cherry-picks, reverts and rebases alike: all use the same file-level merge (Chapter 8).

**See it.** A service repository. Both branches appended a line to `CHANGELOG.md` and a dependency to `requirements.lock`:

<!-- snippet: ch14c/attr-merge/01-two-conflicts -->
```text
$ git merge feat/cache
Auto-merging CHANGELOG.md
CONFLICT (content): Merge conflict in CHANGELOG.md
Auto-merging requirements.lock
CONFLICT (content): Merge conflict in requirements.lock
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --abort
```
<!-- /snippet -->

Two conflicts of a kind that returns at every merge. Add two attributes, one naming a built-in driver and one naming a driver of your own that does not exist yet:

<!-- snippet: ch14c/attr-merge/02-attributes -->
```text
$ printf 'CHANGELOG.md      merge=union\nrequirements.lock merge=keep-ours\n' > .gitattributes
$ git add .gitattributes && git commit -q -m "Add merge attributes"
$ git merge feat/cache
Auto-merging CHANGELOG.md
Auto-merging requirements.lock
CONFLICT (content): Merge conflict in requirements.lock
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status -s
M  CHANGELOG.md
UU requirements.lock
$ cat CHANGELOG.md
# Changelog

- Add retrieval endpoint
- Add rate limiting
- Cache embeddings on disk
$ git merge --abort
```
<!-- /snippet -->

`union` merged the changelog: both new lines are there. The lock file still conflicts, because `merge=keep-ours` names an undefined driver and Git fell back to the text merge without a word. Define it:

<!-- snippet: ch14c/attr-merge/03-driver -->
```text
# A merge driver is a command that leaves its result in %A and reports success with exit status 0.
# "true" changes nothing, so the version of the current branch stays:
$ git config set merge.keep-ours.name 'keep our version of generated files'
$ git config set merge.keep-ours.driver true
$ git merge feat/cache
Auto-merging CHANGELOG.md
Auto-merging requirements.lock
Merge made by the 'ort' strategy.
 CHANGELOG.md | 1 +
 1 file changed, 1 insertion(+)
[exit status: 0]
$ cat requirements.lock
torch==2.4.0
limits==3.13.0
$ git show --stat --format=%s HEAD
Merge branch 'feat/cache'

 CHANGELOG.md | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

The merge is clean, and the lock file is the version of `main`: the dependency that `feat/cache` added is not in it. A lock file is generated, so the honest sequence is "keep one side, then regenerate from the merged manifest and commit".

Where silently keeping one side would be wrong, unset the attribute:

<!-- snippet: ch14c/attr-merge/04-unset -->
```text
$ printf 'CHANGELOG.md      merge=union\nrequirements.lock -merge\n' > .gitattributes
$ git commit -q -am "Lock file: never merge by content"
$ git merge feat/cache
Auto-merging CHANGELOG.md
warning: Cannot merge binary files: requirements.lock (HEAD vs. feat/cache)
Auto-merging requirements.lock
CONFLICT (content): Merge conflict in requirements.lock
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status -s
M  CHANGELOG.md
UU requirements.lock
$ cat requirements.lock
torch==2.4.0
limits==3.13.0
$ git ls-files -u
100644 59fbd9ace1e2d2383413a0183f124e7e501d03ec 1	requirements.lock
100644 09a1d7444516306c5387d7b61274d47d30e30803 2	requirements.lock
100644 b678f049b99091f662d137755b1bc3b3121cf6af 3	requirements.lock
```
<!-- /snippet -->

The path conflicts, the working file is the version of the current branch without markers, and the three stages are in the index for you to choose from (Chapter 8, section 8.11 on binary conflicts).

**In production.** `union` suits append-only files where order and duplicates matter little, such as changelogs. The manual warns that it "tends to leave the added lines in the resulting file in random order"; it also keeps both versions of a line that both sides edited. A keep-ours driver is safe only with a CI check that the lock file matches the manifest. And a custom driver exists only in the clones that defined it: a teammate without the definition gets ordinary conflicts.

> **GitHub, not Git.** Merges for a pull request run on GitHub's servers, where your `merge.<name>.driver` configuration does not exist. Whether GitHub honors the built-in `union` driver is not stated in the pages read for this course, so treat merge attributes as a local aid.

## 14C.8 Clean and smudge filters

**In one sentence.** A filter driver is a pair of commands: `clean` rewrites a file's content on its way from the working tree into the repository (`git add`), and `smudge` rewrites it on its way from the repository into the working tree (checkout); the blob holds the cleaned form.

**Analogy.** A customs desk between your files and the object database: goods are repacked on the way in and unpacked on the way out. Where it breaks: every traveller brings a desk of their own, or none.

**Precisely.** `filter=<name>` in `.gitattributes` names the driver; `filter.<name>.clean` and `filter.<name>.smudge` in configuration define it. Each command reads the content on standard input and writes the converted content to standard output; `%f` in the command line is replaced by the path. Either half may be missing. The manual distinguishes two purposes and Git treats them differently:

- **Convenience filters** make content nicer (strip notebook outputs, normalize formatting), and the project stays usable without them. Every filter is of this kind by default: "a missing filter driver definition in the config, or a filter driver that exits with a non-zero status, is not an error but makes the filter a no-op passthru."
- **Required filters** turn stored content that is unusable by itself (a pointer, ciphertext) into the real thing. With `filter.<name>.required = true` a failing filter becomes an error. Git LFS (Chapter 22) is the best-known example; its `process` variant handles all files of a command in one long-running process.

On the way in the filter runs before the line-ending conversion, on the way out after it. A clean filter should be idempotent: cleaning cleaned content changes nothing.

**Inside `.git`.** The filter definition in `config`. Blobs hold cleaned content, and `git status` compares the cleaned form of your file with the index.

**See it: a convenience filter.** The clean filter below removes outputs and execution counts from notebooks. The notebook was committed before the filter existed:

<!-- snippet: ch14c/attr-filter/01-before -->
```text
# The notebook was committed with its outputs:
$ grep -c output_type eda.ipynb
1
$ git cat-file -p HEAD:eda.ipynb | grep -c output_type
1
```
<!-- /snippet -->

<!-- snippet: ch14c/attr-filter/02-define -->
```text
$ cat tools/nbstrip.py
#!/usr/bin/env python3
"""clean filter for notebooks: drop outputs and execution counts (stdin to stdout)."""
import json
import sys

nb = json.load(sys.stdin)
for cell in nb["cells"]:
    if cell["cell_type"] == "code":
        cell["outputs"] = []
        cell["execution_count"] = None
json.dump(nb, sys.stdout, indent=1, sort_keys=True)
sys.stdout.write("\n")
$ printf '*.ipynb filter=nbstrip\n' > .gitattributes
$ git config set filter.nbstrip.clean 'python3 tools/nbstrip.py'
$ git config set filter.nbstrip.smudge cat
```
<!-- /snippet -->

`smudge` is `cat`: nothing is added on the way out. Once the filter is defined, the committed notebook counts as modified, because its cleaned form differs from the stored blob. `--renormalize` stages the cleaned form:

<!-- snippet: ch14c/attr-filter/03-renormalize -->
```text
$ git status -s
 M eda.ipynb
?? .gitattributes
$ git add --renormalize .
$ git status -s
M  eda.ipynb
?? .gitattributes
$ git add .gitattributes && git commit -q -m "Strip notebook outputs on the way into the repository"
$ git cat-file -p HEAD:eda.ipynb | grep -c output_type
0
$ grep -c output_type eda.ipynb
1
```
<!-- /snippet -->

The commit has no outputs and your file still has them. From now on, running the notebook again does not produce a change:

<!-- snippet: ch14c/attr-filter/04-rerun -->
```text
# Run the notebook again (simulated with sed): a new execution count, the same source.
$ sed 's/"execution_count": 7/"execution_count": 8/' eda.ipynb > eda.tmp && mv eda.tmp eda.ipynb
$ grep execution_count eda.ipynb
   "execution_count": 8,
$ git status -s
$ git diff --stat
```
<!-- /snippet -->

The file on disk differs from the blob, and `git status` and `git diff` are silent. That is the purpose, and a trap when you debug: with a filter, "clean working tree" means "cleans to what is committed".

**See it: the clone.** A teammate clones and commits:

<!-- snippet: ch14c/attr-filter/05-clone -->
```text
$ cd ..
$ git clone -q server.git analysis-asha
$ cd analysis-asha
$ git check-attr filter -- eda.ipynb
eda.ipynb: filter: nbstrip
$ git config get filter.nbstrip.clean
[exit status: 1]
# Asha runs the notebook (simulated by copying an executed copy over it) and commits.
# Nothing strips her outputs, and nothing warns her:
$ cp ../executed.ipynb eda.ipynb
$ git commit -q -am "Rerun error analysis"
$ git cat-file -p HEAD:eda.ipynb | grep -c output_type
1
```
<!-- /snippet -->

Her clone knows that `eda.ipynb` has `filter=nbstrip`. It has no `filter.nbstrip.clean`, so the filter is a no-op and her commit puts outputs into history, without a warning: the third question of section 14C.1.

**Picture.**

```text
   working tree                                   repository (index, then commit)
   +---------------------+      clean (git add)     +----------------------+
   | eda.ipynb           |  --------------------->  | blob: no outputs     |
   | with outputs        |                          |                      |
   |                     |  <---------------------  |                      |
   +---------------------+   smudge (checkout)      +----------------------+
        .gitattributes: "*.ipynb filter=nbstrip"         travels with clone
        .git/config:    [filter "nbstrip"] clean = ...   stays on this machine
```

**The rule for all three kinds of driver.**

| | Named in (versioned) | Defined in (local) | In a clone without the definition |
|---|---|---|---|
| Diff driver | `diff=<name>` | `diff.<name>.textconv`, `.command`, `.xfuncname` | default diff, no message |
| Merge driver | `merge=<name>` | `merge.<name>.driver` | default text merge, no message |
| Filter, convenience | `filter=<name>` | `filter.<name>.clean`, `.smudge` | content passes through unchanged, no message |
| Filter, required | `filter=<name>` | the same, plus `filter.<name>.required = true` | still passes through: `required` is part of the missing definition |

The last row surprises people. `required` protects against a filter that is defined and fails, not against a clone that never defined it. Lab 14.4 builds a required pointer filter, a small model of a large-file extension, and reproduces what happens when a teammate without the definition commits real content over a pointer.

Git does not let the repository define the commands because that would let anyone whose repository you clone run programs on your machine. The line between "versioned" and "local" is a security boundary (section 14C.12).

**In production.** Three arrangements work. (1) A setup step that every clone runs once executes the `git config set filter...` commands. (2) The definition lives in a tracked configuration file that each engineer includes once with `git config set include.path ../.gitconfig`; later changes to that file take effect on pull, which is code execution by pull request, so review it like CI configuration. (3) A tool installs its filter into the global configuration, as `git lfs install` does. In all three, what cannot be skipped is a CI job that fails when the stored form is wrong.

## 14C.9 Hooks: programs that Git runs at fixed points

**In one sentence.** A hook is an executable file with a fixed name in the hooks directory (or, since Git 2.54, a command named in configuration) that Git runs at a defined point of a command, passing information as arguments and standard input, and for some hooks treating a non-zero exit status as "stop".

**Analogy.** Tripwires in your own workshop: you place them, they do nothing in a colleague's workshop, and you can step over them. The analogy fits client-side hooks and is wrong for server-side ones, which sit at the door that every delivery must pass.

**Precisely.** The hooks manual lists 28 hook names ([githooks](https://git-scm.com/docs/githooks)). Git looks for them in `$GIT_DIR/hooks`, or in the directory named by `core.hooksPath`, and ignores files without the executable bit. A hook runs at the top of the working tree (in `$GIT_DIR` for a bare repository and for the receiving side of a push), with `GIT_DIR` and related variables exported. `git init` copies inactive samples from the template directory:

<!-- snippet: ch14c/hook-tour/01-samples -->
```text
$ ls .git/hooks
applypatch-msg.sample
commit-msg.sample
fsmonitor-watchman.sample
post-update.sample
pre-applypatch.sample
pre-commit.sample
pre-merge-commit.sample
pre-push.sample
pre-rebase.sample
pre-receive.sample
prepare-commit-msg.sample
push-to-checkout.sample
sendemail-validate.sample
update.sample
```
<!-- /snippet -->

**The complete list.** "Stops" means that a non-zero exit status makes the command fail.

| Hook | Run by | Arguments | Standard input | Stops? | Skipped by |
|---|---|---|---|---|---|
| `pre-commit` | `git commit`, before the message is obtained | none | none | yes | `--no-verify` |
| `prepare-commit-msg` | `git commit`, after the default message is prepared | message file, source, commit ID | none | yes | nothing |
| `commit-msg` | `git commit`, `git merge` | message file | none | yes | `--no-verify` |
| `post-commit` | `git commit` | none | none | no | nothing |
| `pre-merge-commit` | `git merge`, after a clean automatic merge | none | none | yes | `--no-verify` |
| `post-merge` | `git merge` and so `git pull`, after success | squash flag | none | no | nothing |
| `pre-rebase` | `git rebase` | upstream, branch (absent for the current one) | none | yes | `--no-verify` |
| `post-rewrite` | `git commit --amend`, `git rebase` | `amend` or `rebase` | per commit: old ID, new ID | no | nothing |
| `post-checkout` | `git switch`, `git checkout`, `git restore` from a commit, `git clone`, `git worktree add` | old HEAD, new HEAD, flag (1 branch, 0 file) | none | no; its status becomes the command's | nothing |
| `pre-push` | `git push`, before anything is sent | remote name, URL | per ref: local ref, local ID, remote ref, remote ID | yes | `--no-verify` |
| `applypatch-msg`, `pre-applypatch`, `post-applypatch` | `git am` | message file; none; none | none | the first two | `--no-verify` (first two) |
| `reference-transaction` | every ref update, on either side | `preparing`, `prepared`, `committed` or `aborted` | per ref: old value, new value, ref | in the first two states | nothing |
| `post-index-change`, `pre-auto-gc`, `sendemail-validate`, `fsmonitor-watchman`, four `p4-*` hooks | index writes, `git gc --auto`, `git send-email`, index refresh, `git p4 submit` | see the manual | none | varies | see the manual |
| **Server side** (run by `git receive-pack`) | | | | | |
| `pre-receive` | once per push, before any ref is updated | none | per ref: old ID, new ID, ref | yes, the whole push | nothing on the client |
| `update` | once per pushed ref | ref, old ID, new ID | none | yes, that ref | nothing on the client |
| `proc-receive` | for refs matching `receive.procReceiveRefs` | none | a packet protocol | per ref | nothing on the client |
| `post-receive` | once, after the updates | none | as `pre-receive` | no | nothing on the client |
| `post-update` | once, after the updates | the updated refs | none | no | nothing on the client |
| `push-to-checkout` | a push into the checked-out branch under `receive.denyCurrentBranch=updateInstead` | the new commit | none | yes | nothing on the client |

An all-zero object ID in these inputs means "does not exist": the ref is being created (old side) or deleted (new side).

**See it.** One tracing script is installed under ten client-side names and four server-side names:

<!-- snippet: ch14c/hook-tour/02-install -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# Installed under many hook names: print the name, the arguments and the standard input.
name=$(basename "$0")
echo "[$name] args: $*"
case "$name" in
  pre-push|pre-receive|post-receive|post-rewrite) sed "s/^/[$name] stdin: /" ;;
esac
exit 0
# The same script under every client-side name of interest, and four names on the server:
$ cd .git/hooks && for h in prepare-commit-msg commit-msg post-commit pre-merge-commit post-merge post-checkout pre-rebase post-rewrite pre-push; do cp pre-commit $h; done; cd ../..
$ for h in pre-receive update post-receive post-update; do cp .git/hooks/pre-commit ../server.git/hooks/$h; done
$ chmod +x .git/hooks/* ../server.git/hooks/*
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-tour/03-commit -->
```text
$ printf 'def route(request):\n    return upstream(request)\n' > router.py && git add router.py
$ git commit -m "Add router"
[pre-commit] args: 
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[commit-msg] args: .git/COMMIT_EDITMSG
[post-commit] args: 
[main (root-commit) 3f5eb96] Add router
 1 file changed, 2 insertions(+)
 create mode 100644 router.py
```
<!-- /snippet -->

Four hooks, in this order. `prepare-commit-msg` learned that the message came from `-m`.

<!-- snippet: ch14c/hook-tour/04-amend -->
```text
$ git commit --amend -m "Add request router"
[pre-commit] args: 
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[commit-msg] args: .git/COMMIT_EDITMSG
[post-commit] args: 
[post-rewrite] args: amend
[post-rewrite] stdin: 3f5eb9642223832c879d35738acfdecb6e70042d 9533ef0c056b35d8b7869ef013c63c330b112994
[main 9533ef0] Add request router
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 router.py
```
<!-- /snippet -->

An amend runs the same four and then `post-rewrite`, with the old and the new commit ID on standard input.

<!-- snippet: ch14c/hook-tour/05-checkout -->
```text
$ git switch -c feature/timeouts
Switched to a new branch 'feature/timeouts'
[post-checkout] args: 9533ef0c056b35d8b7869ef013c63c330b112994 9533ef0c056b35d8b7869ef013c63c330b112994 1
$ git switch main
Switched to branch 'main'
[post-checkout] args: a9d0f65fdda8978f82efaaee132e7ecd93270647 9533ef0c056b35d8b7869ef013c63c330b112994 1
# Restoring a file from a commit is a "file checkout": the last argument is 0.
$ git restore --source=feature/timeouts limits.yaml
[post-checkout] args: 9533ef0c056b35d8b7869ef013c63c330b112994 9533ef0c056b35d8b7869ef013c63c330b112994 0
```
<!-- /snippet -->

`post-checkout` receives the previous HEAD, the new HEAD and the flag. Creating a branch does not change the commit, so both IDs are equal.

<!-- snippet: ch14c/hook-tour/06-merge -->
```text
$ git merge feature/timeouts
[pre-merge-commit] args: 
[prepare-commit-msg] args: .git/MERGE_MSG merge
[commit-msg] args: .git/MERGE_MSG
Merge made by the 'ort' strategy.
 limits.yaml | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 limits.yaml
[post-merge] args: 0
```
<!-- /snippet -->

A merge runs `pre-merge-commit` in place of `pre-commit`, and `post-merge` at the end.

<!-- snippet: ch14c/hook-tour/07-rebase -->
```text
$ git rebase main
[pre-rebase] args: main
[post-checkout] args: 76794b68b300e425c07a0027a44a530b5df0129b 12328180f791c3157820266ae1969bc1189457a4 1
Rebasing (1/1)
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[post-commit] args: 
[post-rewrite] args: rebase
[post-rewrite] stdin: 76794b68b300e425c07a0027a44a530b5df0129b 927de69e6948cd33c8e970e5ddb2af33f79a99a9
Successfully rebased and updated refs/heads/feature/retries.
```
<!-- /snippet -->

A rebase runs `pre-rebase` once and `post-rewrite` once. For the commit it replayed, `prepare-commit-msg` and `post-commit` ran, and `pre-commit` and `commit-msg` did not. `git revert` behaves the same on Git 2.55 (Lab 14.2). A hook that "checks every commit" checks the commits made by `git commit` and `git merge`.

<!-- snippet: ch14c/hook-tour/08-push -->
```text
$ git push origin main
[pre-push] args: origin ../server.git
[pre-push] stdin: refs/heads/main 12328180f791c3157820266ae1969bc1189457a4 refs/heads/main 0000000000000000000000000000000000000000
remote: [pre-receive] args:         
remote: [pre-receive] stdin: 0000000000000000000000000000000000000000 12328180f791c3157820266ae1969bc1189457a4 refs/heads/main        
remote: [update] args: refs/heads/main 0000000000000000000000000000000000000000 12328180f791c3157820266ae1969bc1189457a4        
remote: [post-receive] args:         
remote: [post-receive] stdin: 0000000000000000000000000000000000000000 12328180f791c3157820266ae1969bc1189457a4 refs/heads/main        
remote: [post-update] args: refs/heads/main        
To ../server.git
 * [new branch]      main -> main
```
<!-- /snippet -->

`pre-push` ran in your clone. The lines that start with `remote:` were printed by hooks in the other repository and sent back: `pre-receive` with all refs on standard input, `update` once per ref, then `post-receive` and `post-update`.

<!-- snippet: ch14c/hook-tour/09-no-verify -->
```text
$ git commit --no-verify --allow-empty -m "Skip the checks"
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[post-commit] args: 
[main cc3cbfb] Skip the checks
```
<!-- /snippet -->

`--no-verify` skipped `pre-commit` and `commit-msg`. The two hooks that `--no-verify` does not cover still ran: `prepare-commit-msg` and `post-commit`. Of these, `prepare-commit-msg` can still stop a commit by exiting non-zero, with or without `--no-verify` (run on Git 2.55.0 to confirm); `post-commit` cannot.

**In production.** Use client-side hooks for fast feedback to the person at the keyboard, and keep them fast, or people learn the bypass.

## 14C.10 Worked hooks

The scripts are in `labs/ch14c/files/`.

**`pre-commit`: inspect what is staged.** A commit is made from the index, so the hook reads the index, not the files on disk: `git diff --cached` for content and `git cat-file -s :<path>` for sizes.

<!-- snippet: ch14c/hook-pre-commit/01-hook -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# pre-commit: look at what is STAGED (the index), not at the files on disk.
# Refuse a commit that adds a private key or a file larger than 500 kB.
fail=0

if git diff --cached -U0 | grep -q '^+.*-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  echo "pre-commit: a private key is staged. Unstage it and rotate the key." >&2
  fail=1
fi

limit=512000
for path in $(git diff --cached --name-only --diff-filter=AM); do
  size=$(git cat-file -s ":$path")
  if [ "$size" -gt "$limit" ]; then
    echo "pre-commit: $path is $size bytes (limit $limit). Use Git LFS or a data store." >&2
    fail=1
  fi
done

exit $fail
$ chmod +x .git/hooks/pre-commit
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-pre-commit/02-blocked -->
```text
# A deploy key and a 600 kB checkpoint are staged together with a real change:
$ printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy_key
$ head -c 600000 /dev/zero > checkpoint.pt
$ printf 'import torch\nimport wandb\n' > train.py
$ git add .
$ git commit -m "Log runs to the tracker"
pre-commit: a private key is staged. Unstage it and rotate the key.
pre-commit: checkpoint.pt is 600000 bytes (limit 512000). Use Git LFS or a data store.
[exit status: 1]
$ git log --oneline
8d50bdb Add training script
```
<!-- /snippet -->

No commit was made. Deleting the two files from disk does not satisfy the hook, because they are still staged:

<!-- snippet: ch14c/hook-pre-commit/03-index-not-disk -->
```text
# The hook reads the index. Deleting the files on disk is not enough:
$ rm deploy_key checkpoint.pt
$ git commit -m "Log runs to the tracker"
pre-commit: a private key is staged. Unstage it and rotate the key.
pre-commit: checkpoint.pt is 600000 bytes (limit 512000). Use Git LFS or a data store.
[exit status: 1]
$ git restore --staged deploy_key checkpoint.pt
$ git commit -m "Log runs to the tracker"
[main 6053c0f] Log runs to the tracker
 1 file changed, 1 insertion(+)
[exit status: 0]
```
<!-- /snippet -->

Know the limits of this hook: file names without spaces only (a robust version reads `--name-only -z`), one secret pattern, and one option removes it:

<!-- snippet: ch14c/hook-pre-commit/04-no-verify -->
```text
$ printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy_key
$ git add deploy_key
$ git commit --no-verify -m "Add deploy key"
[main 86a145d] Add deploy key
 1 file changed, 3 insertions(+)
 create mode 100644 deploy_key
[exit status: 0]
$ git show --stat --format=%s HEAD
Add deploy key

 deploy_key | 3 +++
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

**`commit-msg`: enforce a message convention.** The hook receives the name of the file that holds the proposed message and may edit or refuse it. Lab 14.2 installs this one:

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/02-refuse-and-accept -->
```text
$ printf 'def exact(pred, gold):\n    return pred.strip() == gold.strip()\n' > metrics.py
$ git commit -am "updated scorer"
commit-msg: the subject must look like 'fix(scorer): handle empty labels'
commit-msg: got: updated scorer
[exit status: 1]
$ git status -s
 M metrics.py
$ git log --oneline -1
1b79baa docs: describe the metrics module
$ git commit -am "fix(metrics): ignore surrounding whitespace"
[main 6757929] fix(metrics): ignore surrounding whitespace
 1 file changed, 1 insertion(+), 1 deletion(-)
[exit status: 0]
```
<!-- /snippet -->

After the refusal, `git status -s` shows the change as unstaged: `git commit -a` stages into a temporary index and discards it when the commit fails. The lab also shows the classic defect of such hooks: they refuse the subjects that Git writes itself (`Merge branch ...`, `fixup! ...`), and a merge then stops half-way.

**`pre-push`: a last look before commits leave.** Standard input has one line per ref. The hook below refuses to delete `main`, to rewrite it, and to push commits whose subject starts with `WIP`, `fixup!` or `squash!` to it. Lab 14.3 prints the script and installs it; here is its effect:

<!-- snippet: ch14c/lab-14-3-pre-push-guard/03-main-refused -->
```text
$ git switch -q main
$ git merge -q --ff-only feature/limits
$ git push origin main
pre-push: unfinished commits must not reach main:
  6378124 WIP: per-tenant limits, quota still undecided
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git status -sb
## main...origin/main [ahead 2]
```
<!-- /snippet -->

**`post-checkout` and `post-merge`: tell the developer what changed.** Neither can stop anything. They are the place for "your dependencies are out of date":

<!-- snippet: ch14c/hook-deps/01-hooks -->
```text
$ cat .git/hooks/post-checkout
#!/bin/sh
# post-checkout <old-HEAD> <new-HEAD> <flag>: flag 1 is a branch checkout, 0 a file checkout.
# Tell the developer when the dependency lock file differs between the two commits.
[ "$3" = 1 ] || exit 0
if ! git diff --quiet "$1" "$2" -- requirements.lock; then
  echo "post-checkout: requirements.lock changed. Run: pip install -r requirements.lock"
fi
$ cat .git/hooks/post-merge
#!/bin/sh
# post-merge <squash-flag>: runs after a merge that succeeded, which includes "git pull".
# ORIG_HEAD is the commit the branch was on before the merge.
if ! git diff --quiet ORIG_HEAD HEAD -- requirements.lock; then
  echo "post-merge: requirements.lock changed. Run: pip install -r requirements.lock"
fi
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-deps/02-checkout -->
```text
$ git switch feature/tracing
Switched to branch 'feature/tracing'
post-checkout: requirements.lock changed. Run: pip install -r requirements.lock
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
post-checkout: requirements.lock changed. Run: pip install -r requirements.lock
# A file checkout calls the hook with flag 0, and the hook stays silent:
$ git restore --source=feature/tracing app.py
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-deps/03-pull -->
```text
$ git pull
From $LAB/ch14c/hook-deps/server
   8848493..977e90f  main       -> origin/main
Updating 8848493..977e90f
Fast-forward
 requirements.lock | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
post-merge: requirements.lock changed. Run: pip install -r requirements.lock
```
<!-- /snippet -->

The pull was a fast-forward, and `post-merge` ran all the same. The exit status of `post-checkout` is passed on without undoing the switch:

<!-- snippet: ch14c/hook-deps/04-exit-status -->
```text
# post-checkout cannot undo the switch, but its exit status becomes the exit status of the command:
$ printf '#!/bin/sh\nexit 3\n' > .git/hooks/post-checkout
$ git switch feature/tracing
Switched to branch 'feature/tracing'
[exit status: 1]
$ git status -sb
## feature/tracing
```
<!-- /snippet -->

The hook exited with 3, `git switch` exited with 1, and the branch was switched: a failing `post-checkout` hook breaks scripts that test the status of `git switch`.

**`pre-rebase`: refuse to rewrite what is published.** The hook receives the upstream and, unless the current branch is rebased, the branch:

<!-- snippet: ch14c/hook-pre-rebase/01-hook -->
```text
$ cat .git/hooks/pre-rebase
#!/bin/sh
# pre-rebase <upstream> [<branch>]: <branch> is absent when the current branch is rebased.
# Refuse to rebase commits that a remote-tracking branch already contains.
upstream=$1
branch=${2:-HEAD}
all=$(git rev-list --count "$upstream..$branch")
unpublished=$(git rev-list --count "$upstream..$branch" --not --remotes)
if [ "$all" != "$unpublished" ]; then
  echo "pre-rebase: $((all - unpublished)) of $all commits are already on a remote." >&2
  echo "pre-rebase: rebasing them rewrites published history (Chapter 9)." >&2
  exit 1
fi
$ git log --oneline --graph --all
* eb2bc26 Add README
| * 6c7937a Add version endpoint
|/  
| * 8cd8387 Add health endpoint
|/  
* 0443504 Add service skeleton
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-pre-rebase/02-local-branch -->
```text
$ git switch -q feature/local
$ git rebase main
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/local.
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-pre-rebase/03-published-branch -->
```text
$ git switch -q feature/shared
$ git rebase main
pre-rebase: 1 of 1 commits are already on a remote.
pre-rebase: rebasing them rewrites published history (Chapter 9).
error: The pre-rebase hook refused to rebase.
[exit status: 1]
$ git status -sb
## feature/shared...origin/feature/shared
```
<!-- /snippet -->

The local branch was rebased, the pushed one was not. And the usual door:

<!-- snippet: ch14c/hook-pre-rebase/04-no-verify -->
```text
$ git rebase --no-verify main
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/shared.
[exit status: 0]
$ git status -sb
## feature/shared...origin/feature/shared [ahead 2, behind 1]
```
<!-- /snippet -->

The branch is now 2 ahead of and 1 behind its upstream (Chapter 9, section 9.15).

## 14C.11 `--no-verify`, `core.hooksPath`, and sharing hooks

**Why hooks are not cloned.** `git clone` transfers objects and refs. `.git/hooks` and `.git/config` are not transferred, by design: otherwise cloning a repository would mean agreeing to run its author's programs.

<!-- snippet: ch14c/hooks-sharing/01-not-cloned -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# Refuse a commit whose staged changes add the marker NOCOMMIT.
if git diff --cached -U0 | grep -q '^+.*NOCOMMIT'; then
  echo "check-marker: a staged line contains NOCOMMIT" >&2
  exit 1
fi
$ printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > infer.py
$ git commit -am "Debug inference"
check-marker: a staged line contains NOCOMMIT
[exit status: 1]
# A teammate clones the same repository:
$ git clone -q ../server.git ../asha
$ ls ../asha/.git/hooks | grep -v sample
$ printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > ../asha/infer.py
$ git -C ../asha commit -q -am "Debug inference"
[exit status: 0]
$ git -C ../asha log --oneline -1
069b8ab Debug inference
```
<!-- /snippet -->

Your clone refuses the debug line. Asha's clone has no hook, and her commit is made.

**Sharing, first way: a tracked directory and `core.hooksPath`.** Keep the hooks in the repository and tell Git to look there. The directory travels. The setting is configuration, and each clone must make it once:

<!-- snippet: ch14c/hooks-sharing/02-hookspath -->
```text
# Put the hook into a tracked directory and point core.hooksPath at it:
$ mkdir .githooks && mv .git/hooks/pre-commit .githooks/pre-commit
$ git add .githooks && git commit -q -m "Share hooks through .githooks" && git push -q
$ git config set core.hooksPath .githooks
$ git rev-parse --git-path hooks
.githooks
# The directory arrives with a pull. The setting does not: every clone must make it once.
$ git -C ../asha pull -q
$ ls ../asha/.githooks
pre-commit
$ git -C ../asha config get core.hooksPath
[exit status: 1]
$ git -C ../asha config set core.hooksPath .githooks
$ printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > ../asha/infer.py
$ git -C ../asha commit -q -am "Debug inference"
check-marker: a staged line contains NOCOMMIT
[exit status: 1]
```
<!-- /snippet -->

A relative `core.hooksPath` is relative to the directory in which the hook runs, the top of the working tree. From then on every pull can change what runs on the next commit: review changes under `.githooks/` as carefully as changes to CI.

**Sharing, second way: hooks defined in configuration.** Since Git 2.54 a hook can be declared as `hook.<name>.command` plus one or more `hook.<name>.event` values, in any configuration file ([git-hook](https://git-scm.com/docs/git-hook)). One script can serve several events and several repositories, and several hooks can share an event:

<!-- snippet: ch14c/hooks-sharing/03-config-hooks -->
```text
# Since Git 2.54 a hook can be a configuration entry: a name, a command, and one or more events.
$ git config unset core.hooksPath
$ git config set hook.marker.command .githooks/pre-commit
$ git config set --append hook.marker.event pre-commit
$ git config set --global hook.whoami.command 'echo "committing as $(git config get user.email)"'
$ git config set --global hook.whoami.event pre-commit
$ printf '#!/bin/sh\necho "hook file in .git/hooks ran"\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
$ git hook list --show-scope pre-commit
global	whoami
local	marker
hook from hookdir
$ git commit --allow-empty -m "Empty commit to watch the hooks"
committing as you@example.com
hook file in .git/hooks ran
[main 8696828] Empty commit to watch the hooks
```
<!-- /snippet -->

`git hook list --show-scope <event>` is the first diagnostic for "why did something run": it shows, in order of execution, the configured hooks with the scope of the file that defined them, and last the file in the hooks directory. Here the global hook ran, then `marker` (silently, since nothing was staged), then the hook file. `hook.<name>.enabled=false` switches one hook off; `hook.<name>.parallel` and `hook.jobs` allow parallel runs since Git 2.55, except for hooks such as `pre-commit` and `commit-msg` that touch shared state.

<!-- snippet: ch14c/hooks-sharing/04-switches -->
```text
# core.hooksPath=/dev/null silences the hooks directory, not the configured hooks:
$ git -c core.hooksPath=/dev/null commit --allow-empty -m "Second empty commit"
committing as you@example.com
[main 2acf6fa] Second empty commit
# --no-verify skips every pre-commit hook, wherever it is defined:
$ git commit --no-verify --allow-empty -m "Third empty commit"
[main 500a741] Third empty commit
# One named hook off, in this repository only:
$ git config set hook.whoami.enabled false
$ git hook list --show-scope pre-commit
global	disabled	whoami
local	marker
hook from hookdir
```
<!-- /snippet -->

The manual describes `core.hooksPath=/dev/null` as a way to "disable all hooks entirely"; on Git 2.55.0 it silenced the hooks directory and the configured hook still ran. `--no-verify` skipped the `pre-commit` hooks of both kinds.

**`git hook run`** executes the hooks of an event, so CI and wrapper tools can run what a developer's commit would run:

<!-- snippet: ch14c/hooks-sharing/05-hook-run -->
```text
# Run the hooks of an event by hand, for example from a CI job:
$ git hook run pre-commit
hook file in .git/hooks ran
[exit status: 0]
$ git hook list commit-msg
warning: no hooks found for event 'commit-msg'
[exit status: 1]
```
<!-- /snippet -->

**Other ways to distribute.** `init.templateDir` (or `git init --template`) names a directory whose contents are copied into every new `.git`, hooks included, on one person's machine. A setup script that copies files into `.git/hooks` works everywhere and has to be run. Hook managers automate that step (section 14C.13).

**`--no-verify` in full.** With `git commit` it skips `pre-commit` and `commit-msg`; with `git merge`, `pre-merge-commit` and `commit-msg`; with `git push`, `pre-push`; with `git rebase`, `pre-rebase`; with `git am`, `applypatch-msg` and `pre-applypatch`. No option skips a server-side hook.

## 14C.12 Hook security

**In one sentence.** A hook, and several configuration values, are commands that run with your permissions, so the question "is it safe to use this repository" is the question "where did its `.git` directory come from".

**Precisely.** The security section of the `git` manual draws the line: because configuration and hooks are not copied by `git clone`, it is generally safe to clone a repository with untrusted content and inspect it; it is not safe to run Git commands in a `.git` directory, or the working tree around it, that itself came from an untrusted source such as an archive or a shared folder ([git](https://git-scm.com/docs/git)).

**See it.** A repository arrives as a tar file. Its author has put a command into `core.fsmonitor` and a `post-checkout` hook into `.git/hooks`. Both only print a line here:

<!-- snippet: ch14c/hook-untrusted/01-archive -->
```text
# You download research-code.tar, unpack it and look around:
$ tar -xf research-code.tar
$ cd research-code
$ git status -s
  >> a command from the archive ran (core.fsmonitor)
  >> a command from the archive ran (core.fsmonitor)
$ git switch -c look-around
Switched to a new branch 'look-around'
  >> a command from the archive ran (post-checkout hook)
```
<!-- /snippet -->

`git status`, the command people run to look around, executed a command from the archive, and the switch ran the hook.

<!-- snippet: ch14c/hook-untrusted/02-what-ran -->
```text
$ git config list --local --show-origin | grep fsmonitor
file:.git/config	core.fsmonitor=echo "  >> a command from the archive ran (core.fsmonitor)" >&2; false
$ ls .git/hooks | grep -v sample
post-checkout
```
<!-- /snippet -->

The manual's remedy is a clone, with `--no-local` so that objects are transferred through the normal protocol and not copied as files:

<!-- snippet: ch14c/hook-untrusted/03-clone -->
```text
# A clone copies objects and refs. It copies neither .git/config nor .git/hooks:
$ cd ..
$ git clone -q --no-local research-code safe-copy
$ cd safe-copy
$ git status -s
$ git switch -c inspect
Switched to a new branch 'inspect'
$ git config get core.fsmonitor
[exit status: 1]
$ ls .git/hooks | grep -v sample
```
<!-- /snippet -->

The clone has the history, without the setting and without the hook.

**The rest of the threat model**, in the order in which you are likely to meet it:

- **Hooks you chose to run.** A tracked hooks directory, an included configuration file and a hook manager turn "pull" into "update the programs that run on my machine".
- **Hooks in global configuration.** Since Git 2.54 a hook defined in `~/.gitconfig` runs in every repository of that user, which suits a personal secret scanner and equally an attacker who can write to that file.
- **Repositories owned by someone else.** Git refuses them unless `safe.directory` lists them.
- **Bugs that write into `.git` during a clone.** CVE-2024-32002 got a hook written into a submodule's `.git` and run while the clone was in progress. Keep Git current, and do not clone untrusted repositories with `--recurse-submodules` (Chapters 21 and 23).
- **A bare repository inside a working tree.** Chapter 14D shows the case and `safe.bareRepository`.

## 14C.13 Why hooks cannot enforce policy, and what does

A client-side hook fails open in four ways: it is not installed by cloning, one option skips it, it does not run for commits made in the web interface, through an API or by a tool with its own Git implementation (a coding agent's, for example), and several Git commands that create commits do not run the commit hooks at all (section 14C.9).

Enforcement needs a place that every change must pass and that its author does not control. There are two.

**The server.** On a Git server that you run, `pre-receive` and `update` are that place. Lab 14.3 moves the rule of its `pre-push` hook into a `pre-receive` hook in the bare repository, and the bypass stops working:

<!-- snippet: ch14c/lab-14-3-pre-push-guard/08-recovery-test -->
```text
$ git commit -q --allow-empty -m "WIP: another placeholder"
$ git push --no-verify origin main
remote: policy: unfinished commits must not reach main:        
remote:   f1edb7c WIP: another placeholder        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
$ cd ../asha
$ git pull -q
$ git commit -q --allow-empty -m "fixup! Add per-tenant limits"
$ git push origin main
remote: policy: unfinished commits must not reach main:        
remote:   f76de82 fixup! Add per-tenant limits        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

`--no-verify` made no difference, and Asha's clone, which has no hooks, was refused as well. `[remote rejected]` with `pre-receive hook declined` is how every client reports it.

> **GitHub, not Git.** On github.com you cannot install server-side hooks. The equivalents are rulesets and branch protection (required pull requests and status checks, blocked force pushes and deletions), push rulesets (file paths, file sizes) and push protection, which rejects a push that contains a recognized secret ([about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)). GitHub Enterprise Server additionally supports pre-receive hook scripts ([documentation](https://docs.github.com/en/enterprise-server@latest/admin/enforcing-policies/enforcing-policy-with-pre-receive-hooks/about-pre-receive-hooks)). Chapter 18 covers rulesets; this paragraph is described from the documentation.

**CI as a required check.** Whatever a hook checks locally, a workflow can check for every pull request, and a ruleset can require it before a merge. The hook then saves a round trip, and the check is the control. Run the same script in both places.

**The pre-commit framework.** `pre-commit` ([pre-commit.com](https://pre-commit.com/)) is a hook manager that is common in Python repositories. It is not installed on the lab machine: this paragraph is described from its documentation (version 4.6.2 when this was written), and nothing in it was run. A file `.pre-commit-config.yaml` in the repository lists hook repositories, each pinned with `rev` and each providing hooks by `id`:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: <a tag or a commit ID of that repository>
    hooks:
      - id: ruff-check
      - id: ruff-format
```

`pre-commit install` sets up the Git hook script in `.git/hooks/pre-commit`; `--hook-type` does the same for other events such as `commit-msg` and `pre-push`. The framework builds an environment for each hook and caches it under `~/.cache/pre-commit`. `pre-commit run --all-files` is the documented CI usage, and `pre-commit autoupdate` moves each `rev` forward. A branch name as `rev` is not supported: pin a tag or a commit ID. Typical hooks for an ML repository, from the Phase 0 report: `ruff-check` and `ruff-format`, `check-added-large-files` (default threshold 500 kB), `detect-private-key`, `nbstripout`, and one secret scanner ([pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks/blob/main/README.md), [ruff-pre-commit](https://github.com/astral-sh/ruff-pre-commit/blob/main/README.md)).

The configuration is versioned and the tools are pinned, so every engineer runs the same checks. That makes the framework better than hand-copied scripts and does not make it a control: `pre-commit install` is still a step that each clone has to take, `git commit --no-verify` and the framework's `SKIP` variable skip it, and each `repo` entry is third-party code that runs on your machine and, in CI, next to your credentials. What enforces is the CI run, required by a ruleset.

## 14C.14 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| After `git stash pop`, staged changes are unstaged | `pop` ran without `--index`; it printed the ID of the dropped commit | `git restore --staged --source='<id>^2' -- .` (Lab 14.6) | `git stash pop --index` |
| A merge or rebase produced a value nobody typed | The output said `Resolved ...` or `Staged ... using previous resolution` | Redo, `git rerere forget <path>`, `git restore --merge <path>`, resolve (Lab 14.5) | `rerere.autoUpdate` off; read replayed files |
| `Unable to create '.../MERGE_RR.lock'` in a rebase | Background `git rerere gc` held the lock; `git rerere status` is empty | `git rerere`, resolve, continue | `maintenance.rerere-gc.auto=0` |
| A file is "modified" right after clone or checkout | `git check-attr -a -- <path>`, `git ls-files --eol <path>`: stored form and attributes disagree | `git add --renormalize .`, commit | A renormalizing commit when attributes or filters change |
| A teammate's diff, merge or filter behaves differently | `git config get filter.<name>.clean` (or the `diff`, `merge` key) fails in their clone | Define the driver there | A setup step per clone and a CI check |
| A hook does not run, or one runs that you did not install | Executable bit; `git rev-parse --git-path hooks`; `git hook list --show-scope <event>` | `chmod +x`; fix or remove the entry | Install hooks with a script; know your global configuration |
| A merge stops with `Not committing merge` | A `commit-msg` hook refused `Merge branch ...` | Fix the hook, `git commit --no-edit` (Lab 14.2) | Let hooks pass subjects that Git writes |
| A secret or WIP commit is on `main` despite a hook | No hook in that clone, `--no-verify`, or a command that runs no hook | Rotate the secret (Chapter 21); enforce on the server | Rulesets, push protection, required checks |

## 14C.15 When not to use it, and dangerous edge cases

**The stash is not storage.** An entry is reachable only through one line of one reflog, and `drop` and `clear` delete such lines.

**Do not enable `rerere.autoUpdate` to save a keystroke.** It removes the only pause in which a replay can be reviewed. And records are local: two people can replay different resolutions of one conflict.

**Do not use `union` on files with structure.** JSON, nested YAML, lock files and code survive a union merge as text and break as data.

**Do not put secrets behind a clean filter.** The first commit from a clone without the definition stores the secret. Use a secret manager (Chapter 21).

**A filter changes what "unchanged" means.** `git status`, `git diff` and `git stash` compare cleaned content. A slow filter slows all of them, and one that is not idempotent makes files flicker between modified and clean.

**Hooks that modify the commit.** A `pre-commit` hook that reformats files changes the working tree, not the index, unless it runs `git add`, and then it commits content you did not review. Prefer hooks that refuse and say what to run.

**🔴 `git stash drop` and `git stash clear`** delete one line, or all lines, of the log of `refs/stash`. They can destroy stashed changes once the unreachable commits are pruned. Preview with `git stash show -p`. Recover with `git stash store <id>` or the `git fsck --unreachable` recipe of Lab 8.6. `clear` is almost never appropriate.

**🔴 `git restore --merge <path>`** overwrites one working file with the conflicted version rebuilt from the index, destroying your edits to that file. Preview with `git diff <path>`. There is no recovery. It is appropriate when a resolution, yours or rerere's, is wrong and you want to start over.

## 14C.16 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git stash show`, `create`, `git log 'stash@{n}'` | 🟢 | nothing, or objects only | not needed | not needed |
| `git stash store`, `import`, `export --to-ref` | 🟢 | `refs/stash` and its log, or the named ref | `git stash list` | `git stash drop`; `git update-ref -d <ref>` |
| `git stash drop`, `git stash clear` | 🔴 | removes reflog lines of `refs/stash` | `git stash show -p 'stash@{n}'` | `git stash store <id>` while the objects exist |
| `git rerere status`, `diff`, `remaining`; `git check-attr`; `git ls-files --eol` | 🟢 | nothing | not needed | not needed |
| `git rerere forget <path>`, `clear`, `gc` | 🟡 | deletes recorded resolutions | `git rerere diff`; `ls .git/rr-cache` | resolve again |
| `git add --renormalize .` | 🟡 | stages every file whose stored form changes | `git status` before committing | `git restore --staged .` |
| `git restore --merge <path>` | 🔴 | overwrites the file with conflict markers | `git diff <path>` | none for your edits to that file |
| `git config set core.hooksPath`, `hook.<name>.*`, `filter.*`, `diff.*`, `merge.*` | 🟡 | which programs Git runs on your machine | `git hook list --show-scope <event>`; `git config list --show-origin` | unset the keys |
| `--no-verify`; `git hook run <event>` | 🟡 | skips local checks; runs them | `git hook list <event>` | the server may still refuse |

## 14C.17 Version notes

> **Version note.** Older behavior: a hook was a file in the hooks directory, one per event. Current behavior: hooks can also be declared in configuration, listed with `git hook list`, and run in parallel. Since: `git hook` in Git 2.36 (dated in the Phase 0 report from the manual page, not from a release note), configuration-defined hooks in Git 2.54, parallel execution in Git 2.55 ([release notes 2.54](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc), [2.55](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)). Recommended: hook files for repository-specific checks, configuration for personal ones.

> **Version note.** Older behavior: `git gc --auto` ran after some commands. Current behavior: `git maintenance run --auto` with the geometric strategy, which includes a `rerere-gc` task. Since: Git 2.54. Recommended: see the lock race in section 14C.3.

> **Version note.** Older behavior: stashes could not leave a repository. Current behavior: `git stash export` and `git stash import`. Since: Git 2.51 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)). Recommended: export to a ref and push it.

> **Unverified.** Four observations in this chapter were made on Git 2.55.0 and are not stated in the manuals: `git revert` and the picks of a rebase do not run `pre-commit` and `commit-msg`; `core.hooksPath=/dev/null` does not stop configuration-defined hooks; a `post-checkout` hook that exits with 3 makes `git switch` exit with 1; and the `MERGE_RR.lock` race. A fifth is from one exploration run without a transcript: with `hook.<event>.enabled=false` the hook file in the hooks directory still ran, although the manual says that no hooks fire. Other versions were not tested.

## 14C.18 Practice

- **Module 14** ([lab manual](../lab-manual/m14-hooks-rerere-attributes.md)): 14.2 a commit-msg hook; 14.3 a pre-push guard and its server-side twin; 14.4 a clean and smudge filter that stores pointers; 14.5 rerere, resolve once, and the repair of a wrong resolution; 14.6 stash anatomy. Lab 14.1 on worktrees belongs to Chapter 25.
- Replay any transcript with `labs/run ch14c/<demo>`; the sandbox stays in place.
- Three drills, each in the sandbox a replay leaves. `ch14c/attr-merge`: write a merge driver for `requirements.lock` that keeps the lines of both sides, sorted and without duplicates, and decide whether that is correct for a lock file. `ch14c/hooks-sharing`: make the `marker` hook run on `pre-push` as well, without creating a file. `ch14c/stash-anatomy`: find the dropped entry with `git fsck` and read one of its files without restoring it.

## 14C.19 Interview questions

1. Draw the commits of a stash entry made with `git stash push -u`. Which tree holds the staged change, which the unstaged one, and what does `git stash show -p` compare?
2. Where is the stash list stored, and what exactly does `git stash drop 'stash@{1}'` write?
3. An engineer lost their staging after `git stash pop`. Why does the information still exist, and which single command restores it?
4. What does rerere record, and when? Why does a resolution recorded in a merge also serve a rebase in the other direction?
5. A wrong value reached `main` through a replayed resolution. Give the diagnosis and the complete fix. Why is a new commit alone not enough?
6. A rebase with rerere dies with `Unable to create MERGE_RR.lock`. Root cause, recovery, prevention?
7. Your team adds `* text=auto` to a five-year-old repository. What does the next `git status` show, what does `git add --renormalize .` do, and how do you protect open branches and `git blame`?
8. Explain "the attribute travels, the driver does not" for a diff driver, a merge driver and a required filter.
9. Which hooks run for `git commit`, in which order, and which does `--no-verify` skip? Which commit-creating commands run none of the checking hooks?
10. Why are hooks not cloned? Describe three ways to share them and the security cost of each.
11. The CTO asks for a guarantee that no commit with a private key reaches `main`. Which layers do you propose, and what does each one fail to catch?

## 14C.20 Sources

**Primary sources**

- [git-stash](https://git-scm.com/docs/git-stash), [git-rerere](https://git-scm.com/docs/git-rerere), [gitattributes](https://git-scm.com/docs/gitattributes), [git-check-attr](https://git-scm.com/docs/git-check-attr), [git-archive](https://git-scm.com/docs/git-archive), [git-add](https://git-scm.com/docs/git-add), [git-restore](https://git-scm.com/docs/git-restore), [githooks](https://git-scm.com/docs/githooks), [git-hook](https://git-scm.com/docs/git-hook), [git-receive-pack](https://git-scm.com/docs/git-receive-pack), [git-config](https://git-scm.com/docs/git-config), [git-maintenance](https://git-scm.com/docs/git-maintenance), [gitfaq](https://git-scm.com/docs/gitfaq) and the security section of [git](https://git-scm.com/docs/git). Every command and option in this chapter was checked against the local Git 2.55.0 copies (`git help -m <command>`).
- [Rerere technical notes](https://github.com/git/git/blob/v2.56.0/Documentation/technical/rerere.adoc) for conflict normalization and conflict IDs; [contrib/rerere-train.sh](https://github.com/git/git/blob/v2.56.0/contrib/rerere-train.sh).
- [Maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc) and [hook configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/hook.adoc).
- Release notes [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), [2.54.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc) and [2.55.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc).
- GitHub Docs: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [About push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection), [About pre-receive hooks](https://docs.github.com/en/enterprise-server@latest/admin/enforcing-policies/enforcing-policy-with-pre-receive-hooks/about-pre-receive-hooks) (GitHub Enterprise Server).
- [pre-commit](https://pre-commit.com/), the documentation of the framework, with [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks/blob/main/README.md) and [ruff-pre-commit](https://github.com/astral-sh/ruff-pre-commit/blob/main/README.md).

**Secondary sources**

- Pro Git, [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), [Git Attributes](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes) and [Rerere](https://git-scm.com/book/en/v2/Git-Tools-Rerere). Caveat: the second edition predates `git restore`, `git hook` and configuration-defined hooks, and uses `master`.
- The Phase 0 report of this course, sections 1, 4, 14 and 15, for release dates, the hook count, the fail-open argument and the pre-commit facts.
- [nbstripout](https://github.com/kynan/nbstripout), the tool whose idea the notebook filter of section 14C.8 imitates in twelve lines.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [So You Think You Know Git Part 2](https://www.youtube.com/watch?v=Md44rcw13k4), Scott Chacon, DevWorld 2024, 23 minutes, 20 March 2024: hooks, attributes, smudge and clean filters. Caveat from the report: no depth on hook security.
- [So You Think You Know Git](https://www.youtube.com/watch?v=aolI_Rz0ZqY), Scott Chacon, FOSDEM 2024, 47 minutes, 8 February 2024: rerere among many other settings. Caveat: a survey, with about one minute of product pitch.

**Further reading**

- [Chapter 8](ch08-merge.md) for conflicts, [Chapter 9](ch09-rebase.md) for rebase, [Chapter 11](ch11-reset-revert-restore.md) for the stash commands, [Chapter 13](ch13-recovery.md) for unreachable objects, [Chapter 14D](ch14d-frontier.md) for `safe.bareRepository`.

# Answer key, Gate 2: Branching

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 2](../assessments/gate-2-branching.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. Every transcript is real output of a script under `labs/gates/` on Git 2.55.0.

**Marking, in general.** A concept answer is marked on mechanism: which ref, in which repository, moved by which command. Correct vocabulary without mechanism earns at most 2 of 5. Deduct a point for each statement that is wrong about Git. In this gate, any answer that treats `origin/main` as a live view of the server loses the points of the sub-question in which it appears.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** `git status` compared `refs/heads/main` with `refs/remotes/origin/main`. Both are refs in your own repository; `git status` opens no connection. `origin/main` is a remote-tracking branch: a record of where the server's `main` was at your last transfer. It moves when you fetch (and `git pull` starts with a fetch), and when a push of yours to that branch succeeds. Nothing else moves it, so its age is the age of your last fetch or push. To learn the truth: `git ls-remote origin main` asks the server and changes nothing locally; `git fetch` asks the server and updates `refs/remotes/origin/*` (and downloads the objects), after which `git status` is accurate. Neither touches your local `main` or your working tree.

**Marking.** 1 point: the two refs by name. 1 point: both are local, no network. 1 point: what moves `origin/main`. 1 point: `git ls-remote` as the read-only question. 1 point: `git fetch`, with what it changes and what it does not.

**Common wrong answers.** "`origin/main` is the branch on GitHub." "`git status` checks the remote." "`git fetch` updates my branch."

**Reference.** Chapter 12, section 12.4 (root-cause box "Your branch is up to date with 'origin/main', yet the server has newer commits"), and section 12.2.

### C2 (5 points)

**Model answer.** A branch is a ref that holds one commit ID. Creating a branch writes that one ref; the commit object it names has parents but no field for a branch, so nothing shared records "created from `main`". Commits do not know which branch they were made on either. The only trace is the first line of the branch's reflog in the clone where it was created ("branch: Created from ..."), which is local, is not transferred by clone, fetch or push, and expires. What Git can compute for two named branches is their merge base: the best common ancestor, `git merge-base A B`. It is not the creation point when, for example, the feature branch has since merged `main` into itself (the merge base moves forward to the merged commit), when the branch was created from another feature branch that was later merged or deleted, or when the branch was rebased. So the honest answer is "name the branch you want to compare with, and I will tell you where the two histories part".

**Marking.** 2 points: no parent-branch data in refs or commits, with the reason. 1 point: the reflog trace and its limits. 1 point: the merge base as what can be computed. 1 point: a valid case in which it differs from the creation point.

**Common wrong answers.** "`git branch -vv` shows the parent." (It shows the upstream.) "The upstream is the parent branch." "Git records the branch name in each commit."

**Reference.** Chapter 7, sections 7.8 and 7.9.

### C3 (5 points)

**Model answer.**

| Command | Local branches | Remote-tracking branches | Server branches | Working tree |
|---|---|---|---|---|
| `git fetch` | unchanged | updated to the server's state | unchanged | unchanged |
| `git pull` | the current branch is integrated with its upstream (fast-forward, merge or rebase) | updated first, by the fetch | unchanged | updated to the new commit of the current branch |
| `git push` | unchanged | the one for the pushed branch is updated after success | the named branch is set to your commit | unchanged |

Before accepting an update of an existing branch the server checks that the update is a fast-forward: the commit the ref names now must be an ancestor of the commit you ask it to name. If it is not, accepting would make the current commits unreachable from that branch, so the push is rejected as non-fast-forward. The check protects commits that someone else pushed since your last fetch. It is a rule of the receiving Git; branch protection on a hosting service is an additional, separate layer.

**Marking.** 1 point per correct row (3). 1 point: the ancestry check stated correctly, in the right direction. 1 point: whose commits it protects. "Fetch updates my branches" loses the first row and one more point.

**Common wrong answers.** "Pull is the opposite of push." "The server compares timestamps." "The server merges my push."

**Reference.** Chapter 12, sections 12.4, 12.6 and 12.7.

### C4 (5 points)

**Model answer.** The upstream is two settings in the repository's local configuration: `branch.<name>.remote` (a remote) and `branch.<name>.merge` (the ref on that remote, by the server's name, for example `refs/heads/main`). It is set by: `git push -u`; `git branch --set-upstream-to`; creating a branch from a remote-tracking branch, as in `git switch -c fix/timeout origin/main` or the guess `git switch <name>` when exactly one remote has that branch (`branch.autoSetupMerge`, default `true`); and `push.autoSetupRemote=true` on the first push. In the example the upstream of `fix/timeout` became `origin/main`. Under the default `push.default=simple`, a plain `git push` pushes the current branch to its upstream only if the upstream has the same name; here the names differ, so Git refuses and prints both alternatives, because it cannot know whether you mean "update `main`" or "publish `fix/timeout`". With `push.default=upstream` the same command would have pushed the commits to `main` on the server.

**Marking.** 1 point: the two configuration keys. 1 point: three ways of setting it. 1 point: the upstream in the example is `origin/main`. 1 point: `simple` refuses and why. 1 point: `upstream` pushes to `main`.

**Common wrong answers.** "The upstream is always the branch of the same name." "`git push` creates the branch on the server by default." "`simple` pushes to `main`."

**Reference.** Chapter 12, section 12.5.

### C5 (5 points)

**Model answer.** Two branches have diverged when each can reach at least one commit that the other cannot: neither tip is an ancestor of the other. "A is fully merged into B" means the tip of A is an ancestor of the tip of B (or equal to it), so every commit of A is reachable from B. `git branch -d X` does not compare with `main`. It requires X to be fully merged into X's upstream, or into `HEAD` when X has no upstream (or the upstream no longer exists). A case: X was merged into `main`, the server branch was deleted and pruned so the upstream is gone, and you are on another feature branch that was created before the merge. `HEAD` does not contain X, so `-d` refuses although `main` contains every commit of X. The reverse also exists: X is merged into `HEAD` but has a commit that its upstream lacks, and `-d` refuses.

**Marking.** 1 point: divergence as a statement about ancestry. 1 point: fully merged as ancestry. 2 points: the upstream-or-HEAD rule. 1 point: a valid case.

**Common wrong answers.** "`-d` checks whether the branch is merged into main." "Diverged means there are conflicts."

**Reference.** Chapter 7, sections 7.5 and 7.8.

### C6 (5 points)

**Model answer.** At the moment of deletion nothing changes in the colleague's clone. A plain `git fetch` does not change anything either: fetch adds and updates remote-tracking refs and does not delete them unless asked. The stale `refs/remotes/origin/<branch>` disappears with `git fetch --prune`, `git remote prune origin` or `fetch.prune=true`. The local branch is never touched by any of this; after pruning, `git branch -vv` shows it as `[origin/<branch>: gone]`. That means only that the configured upstream ref no longer exists in this clone. It does not say that the work was merged: the server branch may have been deleted by mistake, or squash-merged, or abandoned. The `fix` case: clones that have not pruned still hold `refs/remotes/origin/fix`. When someone later pushes `fix/retry`, a fetch tries to create `refs/remotes/origin/fix/retry`, and a ref name cannot be both a name and a prefix of another name, so the fetch reports "unable to update local ref" until the stale ref is pruned.

**Marking.** 1 point: nothing happens without pruning. 1 point: how the remote-tracking ref is removed. 1 point: the local branch stays; meaning of `[gone]`. 1 point: gone is not merged. 1 point: the name-and-prefix conflict.

**Common wrong answers.** "Fetch deletes it automatically." "Gone means merged, so `-D` is safe." "The fetch error is a corrupted repository; clone again."

**Reference.** Chapter 12, section 12.11; Chapter 7, section 7.12 (root-cause box) and section 7.13.

---

## Part 2: Prediction

Marking for every prediction item: a prediction counts when the lines and their order are right. Exact spacing is not required. A right output with a wrong mechanism earns half of that sub-item.

### P1 (5 points)

<!-- snippet: gates/g2-predict/p1-answer -->
```text
$ git status -sb
## main...origin/main [ahead 2, behind 1]
$ git rev-list --left-right --count main...origin/main
2	1
$ git merge-base --is-ancestor origin/main main
[exit status: 1]
$ git log --oneline main..origin/main
ac10501 Fix unicode normalization
```
<!-- /snippet -->

Before the fetch the status said "ahead 2" although Asha had already pushed: the status compares local refs. The fetch moved `origin/main`; `main` did not move. `A...B` with `--left-right --count` prints the commits only in A, then the commits only in B. `origin/main` is not an ancestor of `main` (exit status 1), which together with "ahead 2" is the definition of diverged.

**Marking.** 2 points: `[ahead 2, behind 1]`. 1 point: `2` then `1`. 1 point: exit status 1. 1 point: the one subject. "ahead 2" unchanged after the fetch earns 0 for the first sub-item.

**Reference.** Chapter 7, section 7.8; Chapter 12, section 12.4.

### P2 (5 points)

<!-- snippet: gates/g2-predict/p2-answer -->
```text
$ git branch --merged main
  feature/cache
  fix/bpe
* main
$ git branch --no-merged main
  feature/stream
$ git branch --contains feature/cache
  feature/cache
  feature/stream
* main
$ git log --oneline --graph --all
* 4c7558e D
| * e4c6778 C
|/  
* 14e4f75 B
* 936d6f6 A
$ git branch -d feature/cache
Deleted branch feature/cache (was 14e4f75).
[exit status: 0]
```
<!-- /snippet -->

`fix/bpe` (at A) and `feature/cache` (at B) are ancestors of `main` (at D), so they are merged without any merge ever having run. `feature/stream` holds C, which `main` cannot reach. `--contains feature/cache` lists every branch that can reach B. `-d` succeeds: the branch has no upstream and its commit is an ancestor of `HEAD`.

**Marking.** 2 points: both lists. 1 point: the `--contains` list with three branches. 1 point: the graph with C and D as two tips above B. 1 point: deleted, status 0. A candidate who lists only `main` under `--merged` has the "merged means a merge happened" model and earns at most 2.

**Reference.** Chapter 7, sections 7.5 and 7.8.

### P3 (5 points)

<!-- snippet: gates/g2-predict/p3-answer -->
```text
$ git log -1 --format=%s origin/main
Fix unicode normalization
$ git log -1 --format=%s main
Cache the vocabulary
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git pull --ff-only
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
$ git log --oneline --graph --all
* 9dab0ed Fix unicode normalization
| * 3b627c4 Cache the vocabulary
|/  
* 553b2a7 Add vocabulary loader
* d823d91 Add tokenizer
```
<!-- /snippet -->

A pull is a fetch followed by one integration step. The fetch ran and succeeded: `origin/main` now names Asha's commit. The integration step was refused because the branches have diverged and no strategy is configured. `main`, the index and the working tree are untouched. `--ff-only` cannot succeed on diverged branches either.

**Marking.** 2 points: `origin/main` moved to "Fix unicode normalization" and `main` did not move. 2 points: `[ahead 1, behind 1]`. 1 point: `--ff-only` fails with a non-zero status. The common wrong answer "nothing changed, the pull failed" earns at most 2.

**Reference.** Chapter 12, section 12.6.

### P4 (5 points)

<!-- snippet: gates/g2-predict/p4-answer-a -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/streaming
  origin/main
$ git branch -vv
  feature/streaming a5ce5e8 [origin/feature/streaming] Stream tokens
* main              a4c8712 [origin/main] Add vocabulary loader
```
<!-- /snippet -->

<!-- snippet: gates/g2-predict/p4-answer-b -->
```text
$ git branch -vv
  feature/streaming a5ce5e8 [origin/feature/streaming: gone] Stream tokens
* main              a4c8712 [origin/main] Add vocabulary loader
$ git branch -d feature/streaming
error: the branch 'feature/streaming' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/streaming'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git push origin feature/streaming
To ../server.git
 * [new branch]      feature/streaming -> feature/streaming
[exit status: 0]
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/streaming
  origin/main
```
<!-- /snippet -->

A plain fetch does not delete remote-tracking refs, so the deleted branch is still listed and the upstream looks healthy. After pruning, the upstream is `gone`. `-d` then compares with `HEAD`, which is `main` and does not contain "Stream tokens", so it refuses. The push creates the branch on the server again: a deleted server branch is recreated by anyone who still has the commits, and a push updates the remote-tracking ref.

**Marking.** 1 point for each of the five predictions. For prediction 4 the reason must be the upstream-or-HEAD rule.

**Reference.** Chapter 12, section 12.11; Chapter 7, section 7.5.

---

## Part 3: Hands-on diagnosis

**End state (12 points).** Run `check.sh`. 12 points for `PASS`; otherwise 12 minus the number of `FAIL` lines, not below zero.

**Safety of the path (8 points).** Read the candidate's command log.

| Points | Evidence in the log |
|---|---|
| 2 | Read-only commands first, including `git ls-remote origin` or a fetch before any statement about the server |
| 2 | Before each deletion, a command that lists what would become unreachable (`git log <kept>..<deleted>`, `git branch --merged`) |
| 2 | No `--force`, `+refspec`, `-D`, `git reset --hard` |
| 2 | Variant A: `main` on the server never moved. Variant B: the commits on the detached `HEAD` were given a branch before the first fetch or switch |

**Explanation (10 points).** Variant A: three root causes, 3 points each, plus 1 for prevention. Variant B: two root causes, 4 points each, plus 2 for prevention. For each cause: the Git state with full ref names, the mechanism, and a root cause that names the command or belief.

### Variant A (`rerank-api`): model solution

<!-- snippet: gates/solve-g2-a/01-observe -->
```text
$ cd you
$ git status -sb
## feature/mmr-rerank...remotes/origin/main [ahead 2, behind 4]
$ git branch -vv
  feature/bm25-tuning 89c0613 [origin/feature/bm25-tuning] Raise k1 after the offline evaluation
* feature/mmr-rerank  9a912de [remotes/origin/main: ahead 2, behind 4] Add MMR selection
  main                d1cdccf [remotes/origin/main: behind 4] Add rerank endpoint
  origin/main         d1cdccf Add rerank endpoint
  spike/colbert       8a6eeed [origin/spike/colbert] Implement MaxSim
$ git branch -r
  origin/HEAD -> remotes/origin/main
  origin/feature/bm25-tuning
  origin/main
  origin/spike/colbert
$ git ls-remote origin
39f9a3bb2b0230cc1ed0feb8a72eb03b64483952	HEAD
39f9a3bb2b0230cc1ed0feb8a72eb03b64483952	refs/heads/main
```
<!-- /snippet -->

The first evidence is already odd: Git prints the upstream as `remotes/origin/main` and not as `origin/main`. It does that because the short name is ambiguous. `git ls-remote` shows that the server has `main` only.

<!-- snippet: gates/solve-g2-a/02-ambiguous -->
```text
$ git switch -q main
$ git status -sb
## main...remotes/origin/main [behind 4]
$ git merge origin/main
warning: refname 'origin/main' is ambiguous.
Already up to date.
$ git rev-parse origin/main refs/heads/origin/main refs/remotes/origin/main
warning: refname 'origin/main' is ambiguous.
d1cdccf56ce62b2f8b23713473214e49fc087230
d1cdccf56ce62b2f8b23713473214e49fc087230
39f9a3bb2b0230cc1ed0feb8a72eb03b64483952
$ git for-each-ref --format="%(refname)" "refs/*/origin/main"
refs/heads/origin/main
refs/remotes/origin/main
```
<!-- /snippet -->

**Root cause 1.** State: `refs/heads/origin/main` (a local branch whose name contains a slash) and `refs/remotes/origin/main` both exist. Mechanism: a short name is tried under `refs/heads/` before `refs/remotes/`, so `origin/main` on a command line means the local branch, which sits on an old commit. `git status` is not fooled, because it uses the configured upstream by its full name. Root cause: `git branch origin/main`, typed with the idea of "making a local copy of origin/main". The local branch has no commit that the remote-tracking branch lacks, so `-d` is safe, and the proof is in the log.

<!-- snippet: gates/solve-g2-a/03-delete-stray -->
```text
# Would deleting the stray branch lose a commit? List what it has that the real branch lacks.
$ git log --oneline refs/remotes/origin/main..refs/heads/origin/main
$ git branch -d origin/main
Deleted branch origin/main (was d1cdccf).
$ git rev-parse --symbolic-full-name origin/main
refs/remotes/origin/main
$ git merge --ff-only origin/main
Updating d1cdccf..39f9a3b
Fast-forward
 README.md      | 3 +++
 rerank/bm25.py | 2 ++
 2 files changed, 5 insertions(+)
 create mode 100644 README.md
 create mode 100644 rerank/bm25.py
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

**Root cause 2.** State: `branch.feature/mmr-rerank.merge` is `refs/heads/main`. Mechanism: creating a branch from a remote-tracking branch sets that branch as upstream; `push.default=simple` refuses to push when the upstream's name differs. Root cause: the start point of a branch was taken for a neutral choice; it also configured where `git push` and `git pull` go. `git push -u origin feature/mmr-rerank` publishes under the branch's own name and replaces the upstream.

<!-- snippet: gates/solve-g2-a/04-upstream -->
```text
$ git switch -q feature/mmr-rerank
$ git rev-parse --abbrev-ref @{upstream}
origin/main
$ git push
fatal: The upstream branch of your current branch does not match
the name of your current branch.  To push to the upstream branch
on the remote, use

    git push origin HEAD:main

To push to the branch of the same name on the remote, use

    git push origin HEAD

To choose either option permanently, see push.default in 'git help config'.

To avoid automatically configuring an upstream branch when its name
won't match the local branch, see option 'simple' of branch.autoSetupMerge
in 'git help config'.

[exit status: 128]
$ git push -u origin feature/mmr-rerank
To ../server.git
 * [new branch]      feature/mmr-rerank -> feature/mmr-rerank
branch 'feature/mmr-rerank' set up to track 'origin/feature/mmr-rerank'.
$ git status -sb
## feature/mmr-rerank...origin/feature/mmr-rerank
$ git rev-parse --abbrev-ref @{upstream}
origin/feature/mmr-rerank
```
<!-- /snippet -->

**Root cause 3.** State: two remote-tracking refs for branches that the server no longer has. Mechanism: fetch does not delete remote-tracking refs without `--prune`. After pruning both local branches show `gone`, which says nothing about merging.

<!-- snippet: gates/solve-g2-a/05-stale -->
```text
$ git remote prune --dry-run origin
Pruning origin
URL: ../server.git
 * [would prune] origin/feature/bm25-tuning
 * [would prune] origin/spike/colbert
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/feature/bm25-tuning
 - [deleted]         (none)     -> origin/spike/colbert
$ git branch -vv
  feature/bm25-tuning 89c0613 [origin/feature/bm25-tuning: gone] Raise k1 after the offline evaluation
* feature/mmr-rerank  9a912de [origin/feature/mmr-rerank] Add MMR selection
  main                39f9a3b [origin/main] Document the BM25 parameters
  spike/colbert       8a6eeed [origin/spike/colbert: gone] Implement MaxSim
```
<!-- /snippet -->

The decision between the two branches is an ancestry question, asked against the freshly fetched `origin/main`. `feature/bm25-tuning` has nothing that `origin/main` lacks; `spike/colbert` has two commits that exist on no server branch and, since Asha deleted her local branch, in no other clone that is known. The first `git branch -d` fails although the branch is merged into `main`: its upstream is gone, so `-d` compares with `HEAD`, which is `feature/mmr-rerank`. The answer to that is to stand on `main`, not `-D`.

<!-- snippet: gates/solve-g2-a/06-gone-is-not-merged -->
```text
$ git branch --merged origin/main
  feature/bm25-tuning
  main
$ git log --oneline origin/main..spike/colbert
8a6eeed Implement MaxSim
f637d26 Sketch late-interaction scoring
$ git log --oneline origin/main..feature/bm25-tuning
$ git branch -d feature/bm25-tuning
error: the branch 'feature/bm25-tuning' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/bm25-tuning'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
# The upstream is gone, so -d compares with HEAD, and HEAD is feature/mmr-rerank.
$ git switch -q main
$ git branch -d feature/bm25-tuning
Deleted branch feature/bm25-tuning (was 89c0613).
$ git switch -q feature/mmr-rerank
$ git push -u origin spike/colbert
To ../server.git
 * [new branch]      spike/colbert -> spike/colbert
branch 'spike/colbert' set up to track 'origin/spike/colbert'.
```
<!-- /snippet -->

<!-- snippet: gates/solve-g2-a/07-verify -->
```text
$ git branch -vv
* feature/mmr-rerank 9a912de [origin/feature/mmr-rerank] Add MMR selection
  main               39f9a3b [origin/main] Document the BM25 parameters
  spike/colbert      8a6eeed [origin/spike/colbert] Implement MaxSim
$ git ls-remote origin
39f9a3bb2b0230cc1ed0feb8a72eb03b64483952	HEAD
9a912de7ac64a52e8f2153ba4931b6fac823333a	refs/heads/feature/mmr-rerank
39f9a3bb2b0230cc1ed0feb8a72eb03b64483952	refs/heads/main
8a6eeed0bd734c77fb9f3032b44a601d4d933b91	refs/heads/spike/colbert
$ cd ..
$ assessments/gen/gate-2-branching/variant-a/check.sh
Checking g2-a
  ok    you/ has no local branch called origin/main
  ok    main on the server is where Asha left it
  ok    your main equals main on the server
  ok    origin/main in your clone equals main on the server
  ok    feature/mmr-rerank still has your two commits and nothing else new
  ok    feature/mmr-rerank is on the server under its own name
  ok    its upstream is origin/feature/mmr-rerank
  ok    the stale remote-tracking ref origin/feature/bm25-tuning is gone
  ok    the merged local branch feature/bm25-tuning is deleted
  ok    feature/bm25-tuning was not put back on the server
  ok    spike/colbert is back on the server with both commits
  ok    your local spike/colbert still has both commits
  ok    nothing is staged, modified or untracked in you/
  ok    no operation is left in progress
PASS: the end state of g2-a is right.
[exit status: 0]
```
<!-- /snippet -->

**Partial credit and common mistakes, variant A.**

- `git push origin HEAD:main`, the first suggestion in Git's message: moves `main` on the server. Two lines of the check fail and the safety points for the server are lost. It cannot be undone without a forced push.
- `git pull` or `git merge` on `main` with the ambiguity still in place and "it worked": check which ref was merged. A merge commit on `main` fails the check.
- `git branch -D feature/bm25-tuning`: correct end state, minus 2 safety points; the candidate did not understand what `-d` compared with.
- Deleting `spike/colbert` locally "because the server deleted it": the only copy of two commits is then held by a reflog. The check fails two lines; 0 points for the second safety row.
- Pushing `feature/bm25-tuning` back "to be safe": fails one line. Its commits are in `main`.
- Explanations that earn nothing: "Git was confused", "the cache was stale".

**Reference.** Chapter 7, sections 7.5, 7.11 and 7.12; Chapter 12, sections 12.4, 12.5 and 12.11.

### Variant B (`ingestd`): model solution

<!-- snippet: gates/solve-g2-b/01-observe -->
```text
$ cd you
$ git status -sb
## HEAD (no branch)
$ git branch -vv
* (HEAD detached from origin/feature/dedupe-window) d954027 Test seen_recently on an unknown key
  main                                              d7be0f7 [origin/main] Add batch writer
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/dedupe-window
  origin/hotfix
  origin/main
$ git log --oneline --graph -4
* d954027 Test seen_recently on an unknown key
* 0a23aee Add seen_recently
* 1781e5f Add dedupe window setting
* d7be0f7 Add batch writer
```
<!-- /snippet -->

**Root cause of note 2.** State: `HEAD` holds a commit ID; there is no `refs/heads/feature/dedupe-window`. Mechanism: `git checkout origin/feature/dedupe-window` names a remote-tracking branch, which is not a branch one can be on, so `HEAD` was detached. The two commits moved `HEAD` only. Root cause: the remote-tracking branch was taken for "Asha's branch". `git switch feature/dedupe-window` would have created a local branch with the upstream set. The commits are reachable from `HEAD` alone, so they get a name first.

<!-- snippet: gates/solve-g2-b/02-anchor -->
```text
# The two commits are reachable from HEAD only. Name them before anything else.
$ git switch -c feature/dedupe-window
Switched to a new branch 'feature/dedupe-window'
$ git status -sb
## feature/dedupe-window
```
<!-- /snippet -->

**Root cause of note 1.** State: the clone holds `refs/remotes/origin/hotfix`; the server has deleted `hotfix` and now has `hotfix/retry-storm`. Mechanism: the fetch must create `refs/remotes/origin/hotfix/retry-storm`, and a ref cannot be a name and a prefix at once. The other refs of the same fetch are updated. Root cause: a branch was replaced on the server by a namespace of the same name, and this clone never pruned.

<!-- snippet: gates/solve-g2-b/03-fetch-fails -->
```text
$ git fetch
error: some local refs could not be updated; try running
 'git remote prune origin' to remove any old, conflicting branches
From ../server
   1781e5f..f1501d3  feature/dedupe-window -> origin/feature/dedupe-window
 ! [new branch]      hotfix/retry-storm    -> origin/hotfix/retry-storm  (unable to update local ref)
   d7be0f7..af48ae5  main                  -> origin/main
[exit status: 1]
$ git ls-remote --heads origin
f1501d3f881ad9f5ffe7f7c495cd70dfb7bd7a9a	refs/heads/feature/dedupe-window
ec8d4c91abe7cc6165e13744bb241a25cef668cc	refs/heads/hotfix/retry-storm
af48ae5ecd127a4e86c9490fe799eed695333081	refs/heads/main
$ git for-each-ref --format="%(refname)" refs/remotes
refs/remotes/origin/HEAD
refs/remotes/origin/feature/dedupe-window
refs/remotes/origin/hotfix
refs/remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: gates/solve-g2-b/04-prune -->
```text
$ git remote prune --dry-run origin
Pruning origin
URL: ../server.git
 * [would prune] origin/hotfix
$ git fetch --prune
From ../server
 - [deleted]         (none)             -> origin/hotfix
 * [new branch]      hotfix/retry-storm -> origin/hotfix/retry-storm
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/dedupe-window
  origin/hotfix/retry-storm
  origin/main
```
<!-- /snippet -->

With the upstream set, the status states the divergence, and the three commits can be listed by side:

<!-- snippet: gates/solve-g2-b/05-upstream -->
```text
$ git branch --set-upstream-to=origin/feature/dedupe-window
branch 'feature/dedupe-window' set up to track 'origin/feature/dedupe-window'.
$ git status -sb
## feature/dedupe-window...origin/feature/dedupe-window [ahead 2, behind 1]
$ git log --oneline --graph --left-right HEAD...@{upstream}
> f1501d3 Document the dedupe window
< d954027 Test seen_recently on an unknown key
< 0a23aee Add seen_recently
```
<!-- /snippet -->

A push is rejected as non-fast-forward, which is the server protecting Asha's commit. Integrate, then push. A merge is shown here; `git pull --rebase` is equally correct at this gate, because the two commits being rebased were never published, and it passes the check as well.

<!-- snippet: gates/solve-g2-b/06-integrate -->
```text
$ git push
To ../server.git
 ! [rejected]        feature/dedupe-window -> feature/dedupe-window (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 README.md | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
$ git log --oneline --graph -5
*   641c196 Merge branch 'feature/dedupe-window' of ../server into feature/dedupe-window
|\  
| * f1501d3 Document the dedupe window
* | d954027 Test seen_recently on an unknown key
* | 0a23aee Add seen_recently
|/  
* 1781e5f Add dedupe window setting
$ git push
To ../server.git
   f1501d3..641c196  feature/dedupe-window -> feature/dedupe-window
$ git status -sb
## feature/dedupe-window...origin/feature/dedupe-window
```
<!-- /snippet -->

<!-- snippet: gates/solve-g2-b/07-main -->
```text
$ git switch -q main
$ git merge --ff-only
Updating d7be0f7..af48ae5
Fast-forward
 ingestd/writer.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git switch -q feature/dedupe-window
$ git branch -vv
* feature/dedupe-window 641c196 [origin/feature/dedupe-window] Merge branch 'feature/dedupe-window' of ../server into feature/dedupe-window
  main                  af48ae5 [origin/main] Do not write empty batches
$ cd ..
$ assessments/gen/gate-2-branching/variant-b/check.sh
Checking g2-b
  ok    the stale remote-tracking ref origin/hotfix is gone
  ok    origin/hotfix/retry-storm exists in your clone and equals the server
  ok    HEAD is on the local branch feature/dedupe-window
  ok    its upstream is origin/feature/dedupe-window
  ok    the server has the same commit as your branch
  ok    Asha's commits on the server branch were not rewritten
  ok    the server branch has "Add seen_recently" exactly once
  ok    the server branch has "Test seen_recently on an unknown key" exactly once
  ok    the server branch has your code and Asha's README
  ok    main on the server is untouched
  ok    your main equals main on the server
  ok    nothing is staged, modified or untracked in you/
  ok    no operation is left in progress
PASS: the end state of g2-b is right.
[exit status: 0]
```
<!-- /snippet -->

**Partial credit and common mistakes, variant B.**

- `git switch main` or `git switch feature/dedupe-window` as the first command: the second creates a local branch at `origin/feature/dedupe-window` and leaves the two commits reachable only from the `HEAD` reflog. If the candidate recovers them from the reflog, full end state, minus 2 safety points.
- `git push origin HEAD:feature/dedupe-window --force`: removes Asha's commit from the server branch. The check fails; 0 for safety.
- `git push origin HEAD:feature/dedupe-window` after integrating, while still detached: the server is right, the local state is not (two lines fail).
- Deleting `.git/refs/remotes/origin/hotfix` by hand: works in the files backend; 1 safety point deducted, because `git remote prune` exists and has a dry run.
- Cloning again: 0 for safety and explanation of note 1; the two commits exist only in the old clone.

**Reference.** Chapter 7, sections 7.7 and 7.12; Chapter 12, sections 12.5, 12.6, 12.7 and 12.11.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** A branch is a ref under `refs/heads/` that names a commit and moves when you commit on it. A remote-tracking branch is a ref under `refs/remotes/<remote>/` that records where a branch of that remote was at the last fetch or push; only transfer commands move it. `HEAD` says what is checked out: normally a symbolic ref to a local branch. *Follow-up:* `HEAD` cannot point at a remote-tracking branch symbolically, so checking out `origin/main` detaches `HEAD` at that commit. A commit then moves `HEAD` alone; `origin/main` does not move and no branch contains the new commit.

**Weak answer.** "`origin/main` is main on GitHub." **Reference.** Chapter 7, sections 7.3, 7.7 and 7.10.

### O2 (3 points)

**Model answer.** With the symmetric difference: `git rev-list --left-right --count A...B` prints how many commits are reachable only from A and only from B. `git merge-base A B` gives the commit where the histories part. *Follow-up:* "ahead 3" counts commits reachable from the local branch and not from its upstream's remote-tracking ref; "behind 2" the reverse. Both are computed from local refs, so they are as fresh as the last fetch.

**Weak answer.** "Compare the dates", "look at the diff". **Reference.** Chapter 7, section 7.8.

### O3 (3 points)

**Model answer.** `git pull` runs `git fetch` for the upstream's remote, then integrates the fetched upstream commit into the current branch with one of fast-forward, merge or rebase, as configured or as the flag says. *Follow-up:* since Git 2.33.1 and 2.34.0 an unconfigured pull on diverged branches fetches, prints the hint and stops with "Need to specify how to reconcile divergent branches". The remote-tracking refs have moved and the objects are there; the branch, the index and the working tree are unchanged.

**Weak answer.** "It downloads the latest code." **Reference.** Chapter 12, section 12.6 and its version note.

### O4 (3 points)

**Model answer.** The server compared the commit its branch names now with the commit I asked it to name, and mine does not have the server's commit as an ancestor: accepting it would not be a fast-forward. *Follow-up:* first fetch and look at what the server has that I lack, `git log HEAD..origin/<branch>`, and whose commits those are. The rejection protects commits pushed by others since my last fetch. A forced push would make them unreachable from the branch on the server.

**Weak answer.** "Git wants me to pull first" with no idea why. **Reference.** Chapter 12, sections 12.7 and 12.8.

### O5 (4 points)

**Model answer.** Pull reads from the branch's upstream: `branch.<name>.remote` and `branch.<name>.merge`. Push goes to the remote named by `branch.<name>.pushRemote`, else `remote.pushDefault`, else the upstream's remote, and the destination branch follows `push.default`. In a fork setup the usual arrangement is upstream `upstream/main` for pulls and `remote.pushDefault=origin` for pushes. *Follow-up:* `git rev-parse --abbrev-ref @{upstream} @{push}`, and `git push --dry-run` shows the source and destination. The consequence of getting it wrong is a push to the project's repository instead of the fork, or a pull from a stale fork.

**Weak answer.** "It always goes to origin." **Reference.** Chapter 12, sections 12.5 and 12.10.

### O6 (4 points)

**Model answer.** No. `main` is an ordinary ref. It is the default only because `init.defaultBranch`, or the hosting service, chose that name; unconfigured Git 2.55 still creates `master`. What makes a branch "the default" on a server is the server's `HEAD`, a symbolic ref. *Follow-up:* `refs/remotes/origin/HEAD` is a symbolic ref in the clone that records which branch the server's `HEAD` named; clone sets it, and it is what lets you write `origin` for `origin/main`. When the default changes on the server, existing clones keep the old value: a fetch brings the new branch and, with the default `remote.<name>.followRemoteHEAD=create`, leaves an existing `origin/HEAD` alone. `git remote set-head origin --auto` repoints it. Local branches, their upstreams and any scripts that name the old branch are not changed by anything.

**Weak answer.** "`main` is the trunk and Git treats it specially." **Reference.** Chapter 7, section 7.2; Chapter 12, section 12.3.

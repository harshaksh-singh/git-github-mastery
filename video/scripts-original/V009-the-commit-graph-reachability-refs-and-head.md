# V009: The commit graph, reachability, refs and HEAD

- **Part.** 1: Foundations
- **Module.** 1
- **Planned minutes.** 24
- **Prerequisites.** V008
- **Textbook sections.** [Chapter 2: The Mental Model](../../textbook/ch02-mental-model.md), sections 2.7 and 2.8 (and the `git update-ref` trap of section 2.13)
- **Demo scripts.** `labs/ch02/graph.sh`, `labs/ch02/refs-head.sh`, `labs/ch02/update-ref-trap.sh`

## HOOK

**[ON SCREEN]** "Is the fix in what we shipped?"

A customer reports a bug that you fixed last week. Your CTO asks one question: "Is the fix in what we shipped?"

You could open the release notes. You could search the log for the message. Both can mislead you, because a message can appear on a commit that is not in the release.

**[PAUSE]**

The question is an ancestry question, and Git answers it with an exit status: is the fix commit reachable from the released commit, yes or no. To ask it, you need to know what "reachable" means, and what a name such as `main` really is. That is this video.

## INTRODUCTION

You now know the objects. This video is about how commits connect to each other, and how names connect to commits.

The first half is the commit graph: parent pointers, what "the history of X" means, and what happens to a commit that no name leads to. The second half is refs and HEAD: you will read a branch as a file with one ID in it, watch a commit move that file, and see the two forms that HEAD can take. We close with a trap, a ref written under the wrong name, because it shows how literally Git treats names.

## LEARNING OBJECTIVES

After this video you can:

1. Draw the commit graph of a small history from its parent pointers.
2. Define reachable, and decide for a given commit whether a ref reaches it.
3. Show that a branch is a file holding one commit ID, and that HEAD names a branch.
4. Rescue a commit that no ref reaches by giving it a name.

## CONCEPT

**The commit graph.** In one sentence: every commit names its parent commits, so the commits form a graph that is walked from child to parent, and "the history of X" means everything you can reach from X by following those links.

Precisely. The commits form a directed acyclic graph, a DAG. It is directed because the link is stored in the child and points at the parent. It is acyclic because a commit's ID is computed from its parents' IDs: a parent must exist before its child, so no chain of links can return to its start.

An object is reachable from another if a chain leads to it that follows tags to what they tag, commits to their parents and trees, and trees to their entries.

Three things follow, and each corrects a common belief.

One: a commit does not know its children. So "what came after this commit?" has an answer only relative to a starting point. History commands start from a ref.

Two: "the commits on a branch" is not a stored list. It is the set reachable from the commit that the branch names.

Three: "A is an ancestor of B" means that A is reachable from B. `git merge-base --is-ancestor A B` answers with its exit status.

Inside `.git`: the graph is not stored anywhere as a whole. Parent IDs are inside commit objects, and the starting points are refs.

**Unreachable is not gone.** A commit that no ref reaches still exists as an object. Deleting a branch deletes a name, never a commit. `git gc` removes unreachable objects only after a grace period, two weeks by default; the setting is `gc.pruneExpire`. Reflog entries also count as starting points, and are kept for 90 days by default, or 30 days once the commit is no longer reachable from the tip of its ref; the settings are `gc.reflogExpire` and `gc.reflogExpireUnreachable`. The lab configuration sets both of those to `never`, as you know from V001. The recovery chapter is built on these numbers.

**Refs and HEAD.** In one sentence: a ref is a name for an object ID, a branch is a ref that moves forward when you commit, and HEAD records which branch, or which commit, you are on.

Precisely. A ref refers either to an object ID or to another ref, in which case it is a symbolic ref. Its place in the hierarchy decides how Git treats it.

**[ON SCREEN]** The four-row table of section 2.8.

`refs/heads/<name>` is a branch. It refers to a commit, and it moves when you commit, merge, reset or rebase while it is the current branch.

`refs/tags/<name>` is a tag. It refers usually to a commit or a tag object, and it normally never moves.

`refs/remotes/<remote>/<name>` is a remote-tracking branch. It refers to a commit, and it moves when you fetch from that remote or push to it.

`HEAD` refers to the current branch, as a symbolic ref; or to one commit ID directly, which is called detached HEAD. It moves when you switch.

A branch contains no commits. It names one, and its history is what is reachable from there. Creating a branch writes one ref and copies nothing. And Git records no "parent branch", so merge and rebase must be told the other side.

**A caution about files.** In this video each ref is a file that `cat` can read. That is the default "files" format, not a guarantee: refs can be packed into one file, and the reftable format stores them in binary. `git rev-parse`, `git symbolic-ref` and `git for-each-ref` work with every format.

**Risk labels.** `git branch <name>` is 🟢 SAFE: it adds one ref. `git switch` is 🟢 SAFE: it changes HEAD, the index and the working tree, and refuses to overwrite uncommitted changes. `git update-ref` is 🟡 CAUTION: it changes one ref and nothing else.

## MENTAL MODEL

For the graph, the textbook's analogy is a family tree in which each record lists the parents and none lists the children. From any person you can find all ancestors, but to find descendants you must start from someone younger. It breaks on the counts: a commit has no parent, which makes it a root commit; one parent, an ordinary commit; or several, a merge.

For refs: sticky labels on a wall chart of the commit graph. Moving a label changes nothing on the chart, and removing one removes no commit. HEAD is the "you are here" marker, normally stuck onto a label rather than onto the chart. It breaks because labels are local: every clone has its own set, and learns about another repository's labels only when it fetches.

Combine them. The chart is permanent and shared by content. The labels are small, movable and yours. Almost every Git command you will learn moves labels.

## DIAGRAM

**[DIAGRAM]** The diagram of section 2.7. Draw the bottom line left to right, then the upper commit, then the labels.

```text
                    ea0d3fa -----------+          feature/dedupe -> ea0d3fa
                   /                    \
 dec99b5---0fd50fb---6d7e946----------2511274---2c65cfc
                                          ^         ^
                                        main      rescue
                                    (HEAD -> main)
```

Time flows left to right. Two commits, then a fork: one commit on the lower line, one on the upper. They join in `2511274`, the merge, which has two parents. `main` points there, and HEAD names `main`. `feature/dedupe` points at `ea0d3fa`. The last commit on the right, `2c65cfc`, is the one we will create without a name and then rescue.

**[DIAGRAM]** The diagram of section 2.8, animated: the branch label moves, and HEAD stays attached to the label.

```text
 before the commit                          after the commit

   3046dc6                                    3046dc6 <------ 4a3fb80
      ^                                          ^               ^
      +-- main                                   |               |
      +-- feature/unicode <-- HEAD               main            feature/unicode <-- HEAD
```

Before: two labels on one commit, and HEAD attached to the label `feature/unicode`. After: a new commit whose parent is the old one. The label `feature/unicode` moved to it. `main` did not move. HEAD did not move either: it is still attached to the same label, and the label carried it.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch02/graph.sh`.

```bash
labs/run ch02/graph
```

Five commits, one of them a merge.

<!-- snippet: ch02/graph/01-graph -->
```text
$ git log --graph --decorate --oneline --all
*   2511274 (HEAD -> main) Merge branch 'feature/dedupe'
|\  
| * ea0d3fa (feature/dedupe) Add dedupe rules
* | 6d7e946 Add split step
|/  
* 0fd50fb Add clean step
* dec99b5 Add load step
```
<!-- /snippet -->

Before the next snippet, draw this graph on paper from the picture, with arrows from child to parent. Then check your arrows against the parent pointers.

<!-- snippet: ch02/graph/02-parents -->
```text
$ git log --format='%h  parents: %p' main
2511274  parents: 6d7e946 ea0d3fa
6d7e946  parents: 0fd50fb
ea0d3fa  parents: 0fd50fb
0fd50fb  parents: dec99b5
dec99b5  parents: 
$ git cat-file -p main
tree a9772be4c20443bc529f1b4fd1072be849341e67
parent 6d7e94608a939094e01cc57ba109f162c33cf7cd
parent ea0d3faa4a9e73d5df7cf0b7df41e67546ae932f
author Lab User <you@example.com> 1788755940 +0530
committer Lab User <you@example.com> 1788755940 +0530

Merge branch 'feature/dedupe'
```
<!-- /snippet -->

`%p` prints the parents. The merge commit `2511274` has two `parent` lines: first the commit that `main` pointed at when the merge was made, `6d7e946`, then the tip of the merged branch, `ea0d3fa`. A merge commit is an ordinary commit with more than one parent, and its tree is the merged snapshot. The root, `dec99b5`, has none.

Predict: how many commits are reachable from `main`, and how many from `feature/dedupe`?

<!-- snippet: ch02/graph/03-reachable -->
```text
$ git rev-list --count main
5
$ git rev-list --count feature/dedupe
3
$ git log --oneline feature/dedupe
ea0d3fa Add dedupe rules
0fd50fb Add clean step
dec99b5 Add load step
$ git merge-base --is-ancestor feature/dedupe main
[exit status: 0]
$ git merge-base --is-ancestor main feature/dedupe
[exit status: 1]
```
<!-- /snippet -->

Five from `main`. Three from `feature/dedupe`: its own commit and the two it shares with `main`. And the ancestry test: the branch is an ancestor of `main`, status 0; `main` is not an ancestor of the branch, status 1. That is the command for "is the fix in what we shipped?".

Now a commit with no name. `git commit-tree` writes a commit object and moves no ref.

<!-- snippet: ch02/graph/04-unreachable -->
```text
$ git commit-tree 'main^{tree}' -p main -m 'Experiment that no ref points at'
2c65cfc7d0ba9f3dcd757786eba7734820034807
$ git cat-file -t 2c65cfc7d0ba9f3dcd757786eba7734820034807
commit
$ git rev-list --count --all
5
$ git fsck
dangling commit 2c65cfc7d0ba9f3dcd757786eba7734820034807
```
<!-- /snippet -->

Stop here. A sixth commit was created, `2c65cfc`, whose parent is the tip of `main`. Where is it now?

**[PAUSE]**

It is in the object database: `git cat-file -t` says `commit`. But `git rev-list --count --all` still counts five, and `git fsck` reports a dangling commit. It exists, and no ref leads to it.

<!-- snippet: ch02/graph/05-rescued -->
```text
$ git branch rescue 2c65cfc7d0ba9f3dcd757786eba7734820034807
$ git rev-list --count --all
6
$ git fsck
$ git log --graph --decorate --oneline --all
* 2c65cfc (rescue) Experiment that no ref points at
*   2511274 (HEAD -> main) Merge branch 'feature/dedupe'
|\  
| * ea0d3fa (feature/dedupe) Add dedupe rules
* | 6d7e946 Add split step
|/  
* 0fd50fb Add clean step
* dec99b5 Add load step
```
<!-- /snippet -->

`git branch rescue <id>` 🟢 SAFE created a ref for it. Six commits are reachable, `git fsck` is silent, and the graph shows the commit. No object changed. A name was added.

**[TERMINAL]** Caption bar: `labs/ch02/refs-head.sh`.

```bash
labs/run ch02/refs-head
```

One commit on `main`. We read the ref files.

<!-- snippet: ch02/refs-head/01-files -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git rev-parse HEAD main
3046dc6147cc4993920eb20efeb20d44f2b73d77
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git symbolic-ref HEAD
refs/heads/main
```
<!-- /snippet -->

HEAD contains the name of a branch, and the branch file contains a commit ID. `git rev-parse` resolves both names to that ID. `git symbolic-ref HEAD` prints the branch that HEAD names.

Predict: `git branch feature/unicode` creates a branch. How many objects does it add?

<!-- snippet: ch02/refs-head/02-new-branch -->
```text
$ git cat-file --batch-all-objects --batch-check
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit 171
3a19f43c4181bfd7a3b52b74fbb1b1079e9c2bac tree 37
bfb2990471be330c8cdd6365bd10b4d3fac0ddbc blob 10
$ git branch feature/unicode
$ cat .git/refs/heads/feature/unicode
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git cat-file --batch-all-objects --batch-check
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit 171
3a19f43c4181bfd7a3b52b74fbb1b1079e9c2bac tree 37
bfb2990471be330c8cdd6365bd10b4d3fac0ddbc blob 10
$ git for-each-ref
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit	refs/heads/feature/unicode
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit	refs/heads/main
```
<!-- /snippet -->

None. The object list is identical before and after. The command wrote one small file holding one ID. `git for-each-ref` lists every ref with the object it names: two refs, one commit.

Now we switch and commit. Predict which of three files change: `HEAD`, `refs/heads/main`, `refs/heads/feature/unicode`.

**[PAUSE]**

<!-- snippet: ch02/refs-head/03-commit-moves-branch -->
```text
$ git switch feature/unicode
Switched to branch 'feature/unicode'
$ cat .git/HEAD
ref: refs/heads/feature/unicode
$ printf 'lowercase\nnormalize NFC\n' > rules.txt
$ git commit -am "Normalize to NFC"
[feature/unicode 4a3fb80] Normalize to NFC
 1 file changed, 1 insertion(+)
$ cat .git/HEAD
ref: refs/heads/feature/unicode
$ git for-each-ref
4a3fb8058851f5b863aea726837405da25a9a7e9 commit	refs/heads/feature/unicode
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit	refs/heads/main
$ git log --graph --decorate --oneline --all
* 4a3fb80 (HEAD -> feature/unicode) Normalize to NFC
* 3046dc6 (main) Add lowercase rule
```
<!-- /snippet -->

`git switch` 🟢 SAFE rewrote HEAD to name the other branch. The commit then moved `feature/unicode` to `4a3fb80`. `main` stayed at `3046dc6`, and HEAD reads the same before and after the commit. A commit moves the current branch, and HEAD follows because it names that branch.

<!-- snippet: ch02/refs-head/04-checkout-equivalent -->
```text
# Older scripts switch branches with git checkout. Same effect.
$ git checkout main
Switched to branch 'main'
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

Older scripts switch branches with `git checkout`. Same effect. You see it once here so that you can read those scripts.

<!-- snippet: ch02/refs-head/05-detached -->
```text
# The second form of HEAD: a commit ID instead of a branch name.
$ git switch --detach feature/unicode
HEAD is now at 4a3fb80 Normalize to NFC
$ cat .git/HEAD
4a3fb8058851f5b863aea726837405da25a9a7e9
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
$ git switch main
Previous HEAD position was 4a3fb80 Normalize to NFC
Switched to branch 'main'
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

The second form of HEAD. `git switch --detach` wrote a commit ID into HEAD. `git symbolic-ref` fails, because HEAD is not a symbolic ref now. No branch is current, so a new commit would move no branch. Switching back to `main` restores the symbolic form. V024 is devoted to this state.

**[TERMINAL]** Caption bar: `labs/ch02/update-ref-trap.sh`.

```bash
labs/run ch02/update-ref-trap
```

The trap. The intent is to move the branch `main` to the first commit. The name given to `git update-ref` 🟡 CAUTION is `main` instead of `refs/heads/main`. Predict what moves.

<!-- snippet: ch02/update-ref-trap/01-stray-ref -->
```text
# Intent: point the branch main at the first commit. Mistake: the short name.
$ git log --oneline
cfa6dbc Normalize to NFC
3046dc6 Add lowercase rule
$ git update-ref main 3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git branch -vv
* main cfa6dbc Normalize to NFC
$ git rev-parse main
warning: refname 'main' is ambiguous.
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git rev-parse refs/heads/main
cfa6dbcdb38cee2b5a32420a51a8dea71fab1dc1
```
<!-- /snippet -->

The command printed nothing, and the branch did not move: `git branch -vv` still shows `cfa6dbc`. But the name `main` now resolves to the old commit, with a warning that the name is ambiguous.

<!-- snippet: ch02/update-ref-trap/02-find-and-remove -->
```text
$ git for-each-ref
cfa6dbcdb38cee2b5a32420a51a8dea71fab1dc1 commit	refs/heads/main
$ find .git -maxdepth 1 -type f | sort
.git/COMMIT_EDITMSG
.git/config
.git/description
.git/HEAD
.git/index
.git/main
$ cat .git/main
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git update-ref -d main
error: refusing to update ref with bad name 'main'
[exit status: 1]
$ rm .git/main
$ git rev-parse main
cfa6dbcdb38cee2b5a32420a51a8dea71fab1dc1
```
<!-- /snippet -->

`git for-each-ref`, which lists `refs/`, does not show the stray ref. A listing of the top of `.git` does: a file `.git/main`, holding the old ID. `git update-ref -d main` is refused, and the fix is to delete that file.

**[ON SCREEN]** The root-cause box of section 2.13, one line at a time.

The mechanism: `update-ref` writes exactly the ref it is given, and for an update it checks only that the name is well-formed. Name lookup tries the name at the top of `.git` before `refs/heads/`. For a deletion, Git accepts only names under `refs/` and names in capitals such as `ORIG_HEAD`. The root cause: a plumbing command received a short name where it needs the full ref name. Why Git does this: plumbing serves scripts; it does what it is told and guesses nothing. Prevention: write `refs/heads/<name>` for `update-ref`, and move branches with porcelain. The textbook notes that the two name checks were read from the Git 2.55.0 source, and that the fix applies to the files format, where a ref is a file.

## COMMON MISTAKES

1. **Thinking a branch contains commits.** Root cause: a branch is a ref that names one commit; "its commits" are whatever is reachable from there.
2. **Believing that deleting a branch deletes commits.** Root cause: deleting a branch deletes a name; unreachable objects remain until garbage collection, after a grace period.
3. **Reading HEAD as "the latest commit".** Root cause: HEAD is a symbolic ref to the current branch, or a direct reference to a commit, in which case no branch is current.
4. **A name such as `main` is reported ambiguous.** Root cause: a stray ref outside `refs/`, written by `git update-ref` with a short name.
5. **Answering "which commit is deployed?" with a branch name.** Root cause: `main` is a moving name; it meant another commit yesterday and may mean a different one in a colleague's clone today.

## PRODUCTION EXAMPLE

A backend team ships release builds from tagged commits. A fix for a retry bug is merged, and a customer on the previous release still sees the bug. "Is the fix in what we shipped?" is settled with `git merge-base --is-ancestor <fix> <released commit>`: exit status 1 means the released commit cannot reach the fix. Nobody reads a changelog to decide it.

And the textbook's rule about names in production: "Which commit is deployed?" must be answered with a commit ID. A tag is a name that is not supposed to move; whether it can is decided by the rules on the server, a GitHub matter that a later chapter covers.

## PRACTICE EXERCISE

Do Exercise 1.6, Level 2, "two branches and a tag", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Draw the graph on paper first, with refs and HEAD, from the commands alone. Only then run `git log --graph --decorate --oneline --all` and compare your drawing with it.

## INTERVIEW QUESTION

Q19: "Define "reachable". Why is a commit that no ref can reach still in the repository, and for how long by default?"

Answer aloud. A strong answer gives the definition as a chain of links and says which links count. It separates the existence of an object from the existence of a name for it. For "how long", it names the mechanisms that keep or remove such a commit and the default periods the manual gives, and it knows that reflog entries are starting points too.

## RECAP

You should now be able to say: each commit stores the IDs of its parents, so history is a graph walked from child to parent. Reachable means there is a chain of such links from a starting point, and history commands start from refs. A commit that no ref reaches still exists; giving it a name makes it reachable again. A branch is a ref holding one commit ID. HEAD normally names a branch, and a commit moves that branch while HEAD stays attached to it. And plumbing takes names literally, so I write `refs/heads/` in full.

## HOMEWORK

- Read sections 2.7 and 2.8 of [Chapter 2](../../textbook/ch02-mental-model.md).
- Draw the graph of Lab 1.1, "Build a commit by hand", and of the guided repository on paper, with refs and HEAD.
- Challenge: Exercise 1.9, Level 4, "git log says there are no commits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

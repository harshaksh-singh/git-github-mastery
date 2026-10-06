# V085: Stash internals: a stash entry is a small commit graph

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 16
- **Prerequisites.** V019, V050
- **Textbook sections.** [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), sections 14C.1 and 14C.2
- **Demo scripts.** `labs/ch14c/stash-anatomy.sh`

## HOOK

**[ON SCREEN]** "An engineer popped a stash and says the careful staging is gone. Was anything lost?"

She had spent twenty minutes with `git add -p`, staging exactly the hunks, the blocks of changed lines, that belonged in the next commit, and leaving the debugging lines unstaged. Then an interruption, `git stash`, which parks uncommitted work and resets the files. A branch switch, and later `git stash pop`. Every change came back as unstaged. The separation she had built is gone from `git status`.

The short answer for the CTO is: nothing was lost. A stash entry is a commit with two or three parents, and the second parent holds the index, the staging area, as it was. A plain `git stash pop` ignores it. And `pop` printed the ID of the commit it dropped.

To give that answer with confidence you have to know what a stash entry is made of.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You learned the stash commands in the undo module: push, list, apply, pop, drop. In the recovery module you rescued a dropped entry by treating it as an unreachable merge commit. Today you open one up.

This chapter has a theme that will come back in every video of this module. A repository holds content that is versioned and travels with clone, fetch and push. And it holds machinery that is local and never travels: `.git/config`, `.git/hooks`, `.git/rr-cache`, `refs/stash`. The stash is on the local side of that line.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- draw the commits of a stash entry made with and without untracked files;
- say which tree holds the staged state and which the unstaged state;
- show that the stash list is the reflog of one ref;
- create a stash commit without touching the list, and store it;
- recover a dropped entry by ID.

## CONCEPT

**[ANIMATION]** graph: id=entry title=A_stash_entry_made_with_-u 8f8672d main; 8f8672d-7ee160e; 8f8672d-962e38f; 7ee160e-962e38f; ^8fb87d5-962e38f; HEAD=main; role:8f8672d:H; role:7ee160e:I; role:962e38f:W; role:8fb87d5:U; say:W_has_three_parents:_H,_I_and_the_parentless_U => + 962e38f special:refs/stash; say:refs/stash_points_at_the_newest_W pace=quick

**[ANIMATION]** step: state-1

In one sentence: a stash entry is a commit W that records your tracked files. Its first parent is H, the commit that was HEAD. Its second parent is a commit I that records the index. And when you stash untracked files, a parentless commit U is its third. A parent is the commit another commit was built on.

**[ANIMATION]** step: state-2

`refs/stash` points at the newest W, and the stash list is the reflog of that ref: the local list of values the ref has had.

Precisely, in the manual's words: W is "a commit whose tree records the state of the working directory", its first parent is the commit at HEAD, and "the tree of the second parent records the state of the index". The manual doesn't name the third parent. `git stash show --include-untracked` and `--only-untracked` read it.

Three consequences of the shape.

**[ANIMATION]** say: git_stash_show_-p_compares_H_with_W

`git stash show -p` is the diff from H to W. The staged and the unstaged part appear as one change.

**[ANIMATION]** say: apply_and_pop_merge_W_with_H_as_the_base._Only_--index_reads_I

`git stash apply` merges W into your files with H as the base. Only `--index` also reads I. That's the whole explanation of the hook: a plain pop restores the files and doesn't restore the staging.

**[ANIMATION]** end

Revision syntax works on an entry. `stash@{1}^2` is the index commit of the second entry. `stash@{0}:config.yaml` is one file of the newest. And `stash@{n}` is reflog syntax. There is one ref.

Inside the dot git folder: new objects for W, I and, with `-u` or `-a`, U. The ref `refs/stash`. And the log `logs/refs/stash`, one line per entry.

**[ANIMATION]** graph: id=list dx=330 title=One_ref_and_its_log,_each_entry_drawn_as_its_W_only 8f8672d-e5fe338; ^8f8672d-962e38f; 8f8672d main; HEAD=main; role:8f8672d:H; role:962e38f:W; role:e5fe338:W; 962e38f special:stash@{1}; e5fe338 special:refs/stash special:stash@{0}; say:Two_entries:_the_ref_holds_the_newest => 8f8672d-e5fe338; ^8f8672d-962e38f; 8f8672d main; HEAD=main; role:8f8672d:H; role:962e38f:W; role:e5fe338:W; 8f8672d-4bd62aa; role:4bd62aa:W; 962e38f special:stash@{1}; e5fe338 special:refs/stash special:stash@{0}; cmd:git_stash_create; say:create_builds_the_commits._No_ref_is_written; name:create => 8f8672d-e5fe338; ^8f8672d-962e38f; 8f8672d main; HEAD=main; role:8f8672d:H; role:962e38f:W; role:e5fe338:W; 8f8672d-4bd62aa; role:4bd62aa:W; 962e38f special:stash@{2}; e5fe338 special:stash@{1}; 4bd62aa special:refs/stash special:stash@{0}; cmd:git_stash_store_4bd62aa; say:store_puts_an_existing_stash_commit_on_the_list; name:store => 8f8672d-e5fe338; ^8f8672d-962e38f; 8f8672d main; HEAD=main; role:8f8672d:H; role:962e38f:W; role:e5fe338:W; 8f8672d-4bd62aa; role:4bd62aa:W; 962e38f special:stash@{1}; 4bd62aa special:refs/stash special:stash@{0}; ghost:e5fe338; cmd:git_stash_drop_stash@{1}; say:drop_removes_a_log_line._The_commit_still_exists,_unreachable; name:drop

**[ANIMATION]** step: store

Two plumbing subcommands split `push` into its halves. `git stash create` builds the commits and prints the ID of W. No ref is written and the files stay as they are. `git stash store` puts an existing stash commit on the list. Scripts use them, and so does Git: the autostash of `git rebase --autostash` is a stash commit that is never put on the list.

**[ANIMATION]** step: drop

What `drop` does: it deletes one line from the log and adjusts the ref. No object is deleted. The commit is unreachable until unreachable objects are pruned, two weeks by default.

**[ANIMATION]** end

And travel: nothing fetches or pushes `refs/stash`. Since Git 2.51, `git stash export` writes all entries into one chain of ordinary commits that can be pushed like a branch, and `git stash import` turns such a chain back into entries.

When not to stash: for anything long-lived. You saw in the recovery module that only the newest entry is held by a ref. Long-lived work belongs on a branch.

## MENTAL MODEL

**[ANIMATION]** step: entry.state-2

**[ANIMATION]** say: W_is_the_bench,_I_is_the_outbox,_U_is_the_loose_notes

The textbook's analogy: a labelled envelope with two or three sheets. A photocopy of the bench, which is the files. A photocopy of the outbox, which is the index. And the loose notes that were lying around, the untracked files.

**[ANIMATION]** say: Ordinary_commits,_held_by_one_ref_and_its_log

The analogy breaks in one place: there is no drawer for the envelopes. They are ordinary commits in the object database, held by one ref and its log. That's why a dropped stash can be found again, and also why an expired log loses the list.

**[ANIMATION]** end

## DIAGRAM

Try it now, on paper, from memory. Draw H, I, W and U with their parent edges, and put `refs/stash` on the right commit. Pause me for thirty seconds and draw your answer.

**[PAUSE]**

**[ANIMATION]** graph: id=anat title=With_-u,_and_without 8f8672d main; 8f8672d-7ee160e; 8f8672d-962e38f special:refs/stash; 7ee160e-962e38f; ^8fb87d5-962e38f; HEAD=main; role:8f8672d:H; role:7ee160e:I; role:962e38f:W; role:8fb87d5:U; note:7ee160e:the_index_as_it_was; note:962e38f:tracked_files_as_on_disk; note:8fb87d5:untracked_files,_no_parent; say:Staged:_H_to_I._Not_staged:_I_to_W => 8f8672d main; 8f8672d-7ee160e; 8f8672d-962e38f special:refs/stash; 7ee160e-962e38f; HEAD=main; role:8f8672d:H; role:7ee160e:I; role:962e38f:W; note:7ee160e:the_index_as_it_was; note:962e38f:tracked_files_as_on_disk; gone:8fb87d5; say:Without_-u_there_is_no_U:_W_has_two_parents; name:without

**[DIAGRAM]** The picture of section 14C.2, with the IDs of the transcript. Draw H first, then I as its child, then W as a merge of the two, and last U floating with no parent.

```text
                    8fb87d5  U   untracked files (no parent)
                           \
        .-------------------962e38f  W   <- refs/stash      tracked files as on disk
       /                   /
   8f8672d  H ---------7ee160e  I                           the index as it was
   (main, HEAD)
```

Compare with yours. Without `-u`, erase U and its edge: W then has two parents. In both forms, the difference between H and I is what was staged, and the difference between I and W is what was not.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14c/stash-anatomy`. A repository with one staged change in `score.py`, one unstaged change in `config.yaml` and one untracked file, `notes.md`.

**[ON SCREEN]** 🟡 CAUTION: `git stash push`. Tracked files and the index are reset to HEAD; with `-u` untracked files are removed from the working tree; objects are written, `refs/stash` moves, and `ORIG_HEAD` is rewritten.

<!-- snippet: ch14c/stash-anatomy/01-push -->
```text
$ git status -s
 M config.yaml
M  score.py
?? notes.md
$ git stash push -u -m "wip: strip whitespace"
Saved working directory and index state On main: wip: strip whitespace
$ git status -s
$ git stash list
stash@{0}: On main: wip: strip whitespace
```
<!-- /snippet -->

The entry exists. Predict the shape of the graph: how many parents does the stash commit have? Say it out loud. I'll wait.

**[PAUSE]**

```bash
git log --graph --format='%h [%p] %s' 'stash@{0}'
```

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

Three. `962e38f` is W. In its brackets: `8f8672d`, the commit you were on. Then `7ee160e`, which is I, a child of that commit. And `8fb87d5`, which is U. Look at U's own brackets: empty. It has no parent. The raw commit shows the same thing.

```bash
git show -s --format=raw 'stash@{0}'
```

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

An ordinary commit object with three `parent` lines. Now the trees. Compare the blob IDs column by column.

```bash
git ls-tree -r 'stash@{0}^1'
git ls-tree -r 'stash@{0}^2'
git ls-tree -r 'stash@{0}'
git ls-tree -r 'stash@{0}^3'
```

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

**[ANIMATION]** walk: id=trees columns=commit,config.yaml,score.py,notes.md rows=H__8f8672d:464dad1:2c9e3f4:-|I__7ee160e:464dad1:6ba285d:-|W__962e38f:b571eab:6ba285d:-|U__8fb87d5:-:-:8b2489b marks=2.3:hl,3.2:hl,4.4:hl title=Four_trees,_compared_by_blob_ID

`score.py` changes between H and I: `2c9e3f4` becomes `6ba285d`. That's the staged change. `config.yaml` changes between I and W: `464dad1` becomes `b571eab`. That's the unstaged one. U holds only the untracked file. No tree mixes the three kinds of work, so they can be taken apart again.

```bash
git stash show -p
```

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

`git stash show -p` prints both tracked changes together, because it compares H with W. The two `git diff` commands at the end of the snippet separate them, because each compares the right pair of commits.

Now the ref and its log. A second entry is pushed.

```bash
git stash push -m "wip: threshold 0.9"
git stash list
cat .git/refs/stash
cat .git/logs/refs/stash
```

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

The ref holds the ID of the newest entry. The log has one line per entry, oldest first, in the reflog format you know. `git stash list` prints the message column of this file.

Build an entry without touching anything. 🟢 SAFE: `git stash create`, then `store`.

```bash
git stash create "wip: threshold 0.8"
git stash list
git status -s
git stash store -m 'stored by hand' 4bd62aa
```

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

`create` printed the ID of W, `4bd62aa`. The list didn't change and the file is still modified. `store` appended a reflog line with your message. The commit's own subject is still "On main: wip: threshold 0.8". The list shows the reflog message, not the commit subject.

**[ON SCREEN]** 🔴 DANGEROUS: `git stash drop`. What it changes: one log line is removed and `refs/stash` moves or is deleted. What it can destroy: the only name of that entry. Preview: `git stash show -p` on the entry. Recovery: by the ID that `drop` prints, while the objects exist. Appropriate: for an entry you have applied or no longer need.

```bash
git stash drop 'stash@{1}'
git stash list
cat .git/logs/refs/stash
git cat-file -t e5fe338
```

Quick quiz, two options. After the drop, the commit object is deleted. Or it still exists. Say it out loud.

**[PAUSE]**

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

It still exists. "Dropped stash@{1}" and the full ID. The line is gone from the log, and the next line was rewritten to follow the entry before it. `git cat-file -t` still says `commit`. That ID, with `git stash store` or `git stash apply`, is the recovery.

Last, stashes that travel.

```bash
git stash export --to-ref refs/stashes/laptop
git log --graph --format='%h %s' refs/stashes/laptop
```

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

Each "git stash:" commit has two parents: the previous commit of the chain and one stash commit. After a push of that ref and a fetch elsewhere, `git stash import` rebuilds the list.

<!-- snippet: ch14c/stash-anatomy/10-import -->
```text
$ git clone -q . ../evalkit-desktop
$ cd ../evalkit-desktop
$ git stash list
$ git fetch -q origin refs/stashes/laptop
$ git stash import FETCH_HEAD
$ git stash list
stash@{0}: On main: wip: threshold 0.8
stash@{1}: On main: wip: strip whitespace
```
<!-- /snippet -->

Imported entries show their commit subjects, because messages such as "stored by hand" exist only in the reflog of the repository that wrote them.

## COMMON MISTAKES

Five mistakes to watch for. Almost everyone makes the first one.

1. **Expecting `git stash pop` to restore what was staged.** Root cause: apply and pop merge W with H as the base; only `--index` also reads I, the second parent.
2. **Reading `git stash show -p` as "what I had unstaged".** Root cause: it is the diff from H to W, so the staged and unstaged parts appear as one change.
3. **Treating a dropped stash as deleted.** Root cause: drop removes a reflog line; the commits stay in the object database, unreachable, until a prune.
4. **Expecting stashes on another machine after a push.** Root cause: nothing fetches or pushes `refs/stash`; export and import exist since Git 2.51 for that purpose.
5. **Searching for a stash by the message shown in the list.** Root cause: the list prints the reflog message, which can differ from the commit's subject.

## PRODUCTION EXAMPLE

Now, out of the lab, and back to the engineer whose staging disappeared. Her terminal still shows the line that `pop` printed: "Dropped refs/stash@{0}" and an ID. The lead asks her to change nothing else and reads the dropped commit's second parent: that tree is the index as she had built it. The staged hunks are restored from it, and the debugging lines stay unstaged, as they were.

The team's note afterwards is two lines from the textbook. When the staging mattered, bring work back with `git stash pop --index`. And when you need one file from an entry, read it with `git show` on the entry and the path, or `git restore --source` from the entry, and leave the entry alone.

## PRACTICE EXERCISE

Your turn. Do Lab 14.6, "Stash anatomy", in [`lab-manual/m14-hooks-rerere-attributes.md`](../../lab-manual/m14-hooks-rerere-attributes.md).

Before you look at the graph of your entry, draw it: how many commits, which parents, which one has none. Before each `git ls-tree`, predict which blob IDs will differ from the previous listing. In the recovery part, predict what a plain pop will restore and what it will not.

The challenge is Exercise 14.4, Level 2, draw the graph, "The shape of a stash entry", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q178: "Draw the commits of a stash entry made with `git stash push -u`. Which tree holds the staged change, which the unstaged one, and what does `git stash show -p` compare?"

Pause, draw it on paper, and answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: entry.state-2

**[ANIMATION]** say: Staged:_H_to_I._Not_staged:_I_to_W._show_-p_compares_H_with_W

A strong answer draws four commits with the right parent edges and says which one has no parent and why that is unusual. It locates each kind of work as a difference between two named trees, not as "in the stash". It states the pair of commits that `show -p` compares, and from that explains a behavior the interviewer didn't ask about, such as what a plain pop restores. It also says what holds the entry: one ref and a log.

## RECAP

Let's land this. You should now be able to say:

- A stash entry is a merge commit W with parents H and I, and a third parentless parent U when untracked files are included.
- The staged change is the difference between H and I; the unstaged change is the difference between I and W.
- `refs/stash` names the newest entry and the stash list is that ref's reflog.
- `git stash create` builds an entry without touching anything, and `git stash store` lists an existing one.
- A dropped entry is still a commit; with its ID I can store or apply it until it is pruned.

## HOMEWORK

Read section 14C.2 of [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md).

Today you opened a stash entry and found ordinary commits inside. Before the next video, stash something in the lab and draw its graph before you print it. Next time: rerere, which lets you resolve a conflict once. Until then, look at the state first and type second. See you in the next one.

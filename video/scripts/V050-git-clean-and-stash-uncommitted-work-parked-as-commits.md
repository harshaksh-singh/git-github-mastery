# V050: git clean, and stash: uncommitted work parked as commits

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 8, Undoing changes
- **Planned minutes:** 24
- **Prerequisites:** V047
- **Textbook sections:** [Chapter 11](../../textbook/ch11-reset-revert-restore.md), sections 11.10 and 11.11
- **Demo scripts:** `labs/ch11/clean.sh`, `labs/ch11/stash-basics.sh`, `labs/ch11/stash-conflict.sh`, and last `labs/ch11/stash-untracked-trap.sh` (it belongs to Lab 8.6)

## HOOK

**[ON SCREEN]** `git clean -fdx`

An engineer wants a "fresh checkout" before rerunning an evaluation. They paste a command from a wiki page. Four seconds later the build artifacts are gone, as intended. So are a notebook with a week of error analysis, a `.env` file with local settings, and a directory of model checkpoints. None of them was tracked: none had ever been added to Git.

They open the reflog, Git's local record of where each ref has been. Nothing. They run `git fsck`, which lists objects that nothing reaches. Nothing. They ask you which command brings the files back.

There's no such command. After this video you'll be able to say exactly why, and what they should have typed instead. Hold on to those two questions.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Two commands today, and they sit at opposite ends of the undo map.

`git clean` deletes untracked files. It's the only undo in Git whose effect nothing in Git can reverse.

`git stash` does nearly the opposite. It takes uncommitted work, turns it into commits, and clears your working tree, so that the work can come back later. Because the work becomes objects, almost everything about stash is recoverable, including an entry you dropped by mistake.

You'll see `clean` through its dry runs, which list what would be deleted and delete nothing. Then stash: what goes into an entry, `apply` against `pop`, the `--index` option, a pop that conflicts and the two ways on from there, and how to recover a dropped entry. At the end comes a trap with untracked files that belongs to the lab.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Preview and run `git clean`, and state why it has no undo.
- Park and restore work with stash, including untracked files and the staged state.
- Resolve a conflict from `git stash pop`, and explain why the entry was kept.
- Recover a dropped stash entry by its ID.
- Give three reasons to prefer a commit on a branch to a stash.

## CONCEPT

**Clean.** `git restore` and `git reset --hard` leave untracked files alone, with the one exception you saw. The command that removes them is `git clean` 🔴 DANGEROUS. It's the only undo whose effect no reflog, no `git fsck` and no stash can reverse, because an untracked file was never an object.

**[ANIMATION]** trees: file=debug_dump.json in=wt absent=no_object versions=its_content history=off steps=setup title=An_untracked_file say_setup=On_disk_only:_Git_never_stored_it id=untracked

That's the whole reason, and it's the same question as in the reset video: did Git ever store it? For an untracked file the answer is no, by definition.

**[ON SCREEN]** The five answers for `git clean`.

What it changes: the working tree only. It deletes untracked paths, and ignored ones too with `-x` or `-X`.

What it can destroy: anything Git doesn't track: notebooks, results, `.env` files, datasets, checkpoints.

How to preview: the same command with `-n` in place of `-f`. Git insists on one of them: without `-f`, `-n` or `-i` it refuses to run. The setting is `clean.requireForce`.

How to recover: not through Git.

When it's appropriate: after you have read the dry run line by line. When in doubt, `git stash push -u` clears the same untracked files and keeps them as objects.

**Stash.** In one sentence: `git stash push` 🟡 CAUTION records the index and the working tree as commits that only `refs/stash` reaches, then resets both to HEAD, so that the work can be brought back later, on this commit or on another.

**[ANIMATION]** graph: H main; HEAD=main; name:precisely => + H-I; name:stash-entry => + H-W; I-W; name:first-parent => + ?untracked-W; say:With_-u,_a_third_parent_holds_the_untracked_files; name:third => + W special:refs/stash; say:refs/stash_points_at_the_newest_entry; name:points title=A_stash_entry_is_a_commit id=entry

**[ANIMATION]** step: entry.points

Precisely. A stash entry is a commit whose tree is the state of your tracked files. Its first parent is the commit that was HEAD, and its second parent records the index. With `-u`, a third parent holds the untracked files. `refs/stash` points at the newest entry, and older entries live in the reflog of that ref, hence the names `stash@{1}`, `stash@{2}`.

**[ANIMATION]** say: pop_=_apply,_then_drop._The_drop_happens_only_if_the_apply_succeeded.

`git stash apply` merges the entry's changes into the current files. `git stash pop` is `apply` followed by `drop`, and the drop happens only if the apply succeeded.

**[ANIMATION]** say: HEAD_and_the_branch_do_not_move

Inside `.git`: new commit objects, the ref `refs/stash` and its reflog. HEAD and the branch don't move. `ORIG_HEAD` is overwritten. You saw that cause trouble in the reset video.

**[ANIMATION]** cards: question=For_work_that_must_outlive_the_day:_a_commit_on_a_branch cards=it_shows_in_git_log|it_can_be_pushed|no_single_command_drops_it id=why at_1=58 at_2=74 at_3=84

When not to use stash? For anything that must outlive the day. The textbook gives three reasons in one sentence: a commit on a branch shows in `git log`, can be pushed, and no single command drops it.

## MENTAL MODEL

**[ON SCREEN]** "A labelled tray."

A picture helps. The textbook's analogy for stash: a labelled tray. You slide the half-built work off the bench onto a tray, and the bench is clear for the urgent job.

**[ANIMATION]** stores: boxes=the_bench:your_working_tree|a_labelled_tray:a_stash_entry|the_bin:git_clean rows=1:A:half-built_work|2:B:half-built_work@ok|3:C:swept_in,_emptied_at_once@bad arrows=2:A1>B1:git_stash_push|3:A1>C1:git_clean title=The_tray_and_the_bin id=bench

**[ANIMATION]** step: bench.2

It breaks in two places. The tray remembers which commit the work was based on, and putting it back onto a changed bench is a merge, which can conflict. And trays never leave your workshop: a stash isn't pushed, not fetched, and not shown by `git log`.

**[ANIMATION]** step: bench.3

Now put the two commands side by side with that picture. Stash slides things onto a tray. Clean sweeps the bench into the bin, and the bin is emptied at once. If you're not certain, use the tray.

## DIAGRAM

**[ANIMATION]** graph: H main; HEAD=main => + H-I => + H-W; I-W => + W special:refs/stash => + note:H:the_commit_you_were_on; note:I:the_index; note:W:your_tracked_files; name:records title=What_git_stash_push_creates id=draw

**[DIAGRAM]** Draw `H` with `main` on it. Then `I` as a child of `H`. Then `W` with two lines, one to `H` and one to `I`. Last, the label `refs/stash`.

```text
          .-----W      refs/stash -> W      W: the tracked files as they were on disk
         /     /                            I: the index as it was
   -----H-----I        main (HEAD -> main) stays at H; files and index are reset to H
```

**[ANIMATION]** step: draw.state-1

Draw it with me. `H` is the commit you're on, with `main` on it.

**[ANIMATION]** step: draw.state-2

`I` is a child of `H`. It records the index as it was.

**[ANIMATION]** step: draw.state-3

`W` has two parents, `H` and `I`. It records the tracked files as they were on disk.

**[ANIMATION]** step: draw.state-4

`W` is a commit with two parents. No branch reaches it. Only `refs/stash` does. `main` hasn't moved. That's why `git log` doesn't show your stash, and why dropping the ref leaves the commit unreachable but, for a while, still present.

**[ANIMATION]** end

Try it now, thirty seconds, on paper: redraw the three commits from memory, and write beside each what it records. Then say it out loud.

**[PAUSE]**

**[ANIMATION]** step: draw.records

`H`, the commit you were on. `I`, the index. `W`, your tracked files. With those three, you can read any stash entry.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch11/clean`. A repository with untracked files, ignored files, a nested repository and one tracked edit.

<!-- snippet: ch11/clean/01-status -->
```text
$ git status -s --ignored
 M serve.yaml
?? debug_dump.json
?? scratch/
?? vendor/
!! .env
!! __pycache__/
!! train.log
```
<!-- /snippet -->

`??` is untracked, `!!` is ignored. Note `.env` among the ignored paths.

<!-- snippet: ch11/clean/02-refuses-without-force -->
```text
$ git clean
fatal: clean.requireForce is true and -f not given: refusing to clean
[exit status: 128]
```
<!-- /snippet -->

Bare `git clean` refuses. Now five dry runs. For each, predict the list before it appears. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch11/clean/03-dry-runs -->
```text
$ git clean -n
Would remove debug_dump.json
$ git clean -n -d
Would remove debug_dump.json
Would remove scratch/
Would skip repository vendor/tokenizers
$ git clean -n -d -X
Would remove .env
Would remove __pycache__/
Would remove train.log
$ git clean -n -d -x
Would remove .env
Would remove __pycache__/
Would remove debug_dump.json
Would remove scratch/
Would remove train.log
Would skip repository vendor/tokenizers
$ git clean -n -d -e scratch/
Would remove debug_dump.json
Would skip repository vendor/tokenizers
```
<!-- /snippet -->

**[ANIMATION]** walk: columns=git_clean,debug__dump.json,scratch/,ignored_paths rows=-n:remove:-:-|-n_-d:remove:remove:-|-n_-d_-X:-:-:remove|-n_-d_-x:remove:remove:remove|-n_-d_-e_scratch/:remove:protected:- marks=1.2:bad,2.2:bad,2.3:bad,3.4:bad,4.2:bad,4.3:bad,4.4:bad,5.2:bad,5.3:ok title=A_blast_radius_that_widens_and_narrows at_1=12 at_2=28 at_3=38 at_4=54 at_5=64

**[ANIMATION]** step: 5

Read them as a blast radius that widens and narrows. Plain `-n` lists untracked files in the current directory. `-d` adds untracked directories. `-X`, capital, lists only ignored paths, which include `.env`. `-x`, lower case, lists both kinds. `-e` protects a pattern. The nested repository `vendor/tokenizers` is never on the removal list, and the tracked edit to `serve.yaml` isn't clean's business at all.

**[ANIMATION]** end

The five answers were given a minute ago. The dry run has been read line by line. Now the real thing.

<!-- snippet: ch11/clean/04-clean -->
```text
$ git clean -f -d
Removing debug_dump.json
Removing scratch/
Skipping repository vendor/tokenizers
$ git status -s --ignored
 M serve.yaml
?? vendor/
!! .env
!! __pycache__/
!! train.log
```
<!-- /snippet -->

<!-- snippet: ch11/clean/05-gone-for-good -->
```text
$ printf '{"query": "q1", "scores": [0.9, 0.4]}\n' | git hash-object --stdin
d702a51f40a7856802f55fc97f9a9c06a50bcad4
$ git cat-file -t d702a51f40a7856802f55fc97f9a9c06a50bcad4
fatal: git cat-file: could not get object info
[exit status: 128]
$ git fsck
```
<!-- /snippet -->

The ID that the deleted file's content would have names no object, and `git fsck` has nothing to report. Gone for good. That's the first answer for the engineer from the start: why no command brings the files back.

**Stash basics.** `labs/run ch11/stash-basics`. One staged change, one unstaged change, one untracked file.

```bash
git stash push -m "wip: blend dense scores"
```

Predict `git status -s` afterwards.

**[PAUSE]**

<!-- snippet: ch11/stash-basics/01-push -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push -m "wip: blend dense scores"
Saved working directory and index state On main: wip: blend dense scores
$ git status -s
?? plan.md
$ git stash list
stash@{0}: On main: wip: blend dense scores
```
<!-- /snippet -->

The tracked changes are gone from the files. The untracked `plan.md` stayed: a plain stash takes tracked files only.

<!-- snippet: ch11/stash-basics/02-show -->
```text
$ git stash show
 rank.py    | 2 +-
 serve.yaml | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git stash show -p
diff --git a/rank.py b/rank.py
index 4b0bb9d..b29d4bd 100644
--- a/rank.py
+++ b/rank.py
@@ -1,2 +1,2 @@
 def score(q, d):
-    return bm25(q, d)
+    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)
diff --git a/serve.yaml b/serve.yaml
index 946ab07..40933f2 100644
--- a/serve.yaml
+++ b/serve.yaml
@@ -1,2 +1,2 @@
-timeout_s: 30
+timeout_s: 10
 retries: 2
```
<!-- /snippet -->

`git stash show` summarizes an entry, and `-p` prints its full difference from the commit it was made on.

<!-- snippet: ch11/stash-basics/03-apply -->
```text
$ git stash apply -q
$ git status -s
 M rank.py
 M serve.yaml
?? plan.md
$ git stash list
stash@{0}: On main: wip: blend dense scores
```
<!-- /snippet -->

After `apply` the entry is still in the list. And look at `rank.py`: it was staged when it was stashed and came back unstaged. Only `--index` restores the split.

<!-- snippet: ch11/stash-basics/04-pop-index -->
```text
$ git stash pop --index
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   rank.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   serve.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	plan.md

Dropped refs/stash@{0} (3041fc614ff2d5678e22fcce3440c08ea4709d63)
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash list
```
<!-- /snippet -->

Staged and unstaged, as before. And one line to remember: "Dropped refs/stash@{0}", followed by a commit ID in parentheses. `pop` dropped the entry and printed the ID of the commit it let go of. That line matters later.

**[ON SCREEN]** The table "what goes into an entry".

```text
Command                        Goes into the entry                             Left in your files and index
-----------------------------  ----------------------------------------------  ---------------------------------
git stash push                 staged and unstaged changes to tracked files    untracked files
git stash push -u              the same, plus untracked files (not ignored)    nothing: git status is clean
git stash push --staged        only what is staged                             unstaged changes, untracked files
git stash push --keep-index    staged and unstaged changes, as without the     the staged changes, still staged
                               option
git stash push -- <path>       changes to <path> only                          everything else
```

Here's the whole table: five forms of push, what goes into the entry, and what's left behind. The next snippets walk the last four rows.

<!-- snippet: ch11/stash-basics/05-include-untracked -->
```text
$ git stash push -u -m "wip: dense blend, with the plan file"
Saved working directory and index state On main: wip: dense blend, with the plan file
$ git status -s
$ git stash show --include-untracked
 plan.md    | 1 +
 rank.py    | 2 +-
 serve.yaml | 2 +-
 3 files changed, 3 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

With `-u` the status is clean, and `plan.md` is in the entry.

The two that are confused most often:

<!-- snippet: ch11/stash-basics/06-staged-only -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push --staged -m "ranker change only"
Saved working directory and index state On main: ranker change only
$ git status -s
 M serve.yaml
?? plan.md
$ git stash show
 rank.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch11/stash-basics/07-keep-index -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push --keep-index -m "everything; index left in place"
Saved working directory and index state On main: everything; index left in place
$ git status -s
M  rank.py
?? plan.md
$ git stash show
 rank.py    | 2 +-
 serve.yaml | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

`--staged` stashes the index and nothing else. `--keep-index` stashes everything and also leaves the staged part in place, so you can test exactly what you're about to commit.

<!-- snippet: ch11/stash-basics/08-pathspec -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push -m "serving timeout only" -- serve.yaml
Saved working directory and index state On main: serving timeout only
$ git status -s
M  rank.py
?? plan.md
$ git stash list
stash@{0}: On main: serving timeout only
```
<!-- /snippet -->

And with a path, only that path's changes go.

**A pop that conflicts.** `labs/run ch11/stash-conflict`. Work is stashed, a hotfix changes the same line, and the stash comes back.

<!-- snippet: ch11/stash-conflict/01-stash-then-hotfix -->
```text
$ git status -s
 M serve.yaml
$ git stash push -m "wip: try a 10s timeout"
Saved working directory and index state On main: wip: try a 10s timeout
$ printf 'timeout_s: 20\nretries: 2\ncache: on\n' > serve.yaml
$ git commit -am "Hotfix: lower timeout to 20s"
[main 00eed5e] Hotfix: lower timeout to 20s
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

**[ANIMATION]** graph: 6cde22d-00eed5e main; ^6cde22d-?index-c94265d special:refs/stash; 6cde22d-c94265d; HEAD=none; note:00eed5e:timeout_20; note:c94265d:timeout_10 => + drop:refs/stash; ghost:?index,c94265d; cmd:git_stash_drop; name:dropped => + c94265d special:refs/stash; ghost:; cmd:git_stash_store_c94265d; name:put-back title=An_entry_based_on_an_older_commit id=pop dx=230

**[ANIMATION]** step: pop.state-1

Quick quiz about `git stash pop`, in two parts. The exit status: zero or one? And the entry: A, dropped, or B, still in the list? Your answer?

**[PAUSE]**

<!-- snippet: ch11/stash-conflict/02-pop-conflict -->
```text
$ git stash pop
Auto-merging serve.yaml
CONFLICT (content): Merge conflict in serve.yaml
On branch main
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   serve.yaml

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
```
<!-- /snippet -->

Exit status 1, and B, still in the list. The last line is the important one: "The stash entry is kept in case you need it again." The drop happens only if the apply succeeded.

<!-- snippet: ch11/stash-conflict/03-conflict-state -->
```text
$ git status -s
UU serve.yaml
$ cat serve.yaml
<<<<<<< Updated upstream
timeout_s: 20
=======
timeout_s: 10
>>>>>>> Stashed changes
retries: 2
cache: on
$ git stash list
stash@{0}: On main: wip: try a 10s timeout
```
<!-- /snippet -->

It's an ordinary conflict with its own labels: `Updated upstream` is the file as it is now, `Stashed changes` is the entry.

There are two ways on. One: resolve the file, clear the conflict state with `git restore --staged` or `git add`, and drop the entry yourself. `git stash drop` 🔴 DANGEROUS: it deletes the only ref to work that was never committed. Preview with `git stash show -p stash@{n}`. Recovery is by the ID it prints, for as long as the objects exist. Appropriate only when the entry's content is committed elsewhere, or on disk as here, or you want none of it.

<!-- snippet: ch11/stash-conflict/04-resolve-and-drop -->
```text
$ printf 'timeout_s: 10\nretries: 2\ncache: on\n' > serve.yaml
$ git restore --staged serve.yaml
$ git status -s
 M serve.yaml
$ git stash list
stash@{0}: On main: wip: try a 10s timeout
$ git stash drop
Dropped refs/stash@{0} (c94265dd6415b63fc30a245db496836c128b5b90)
$ git stash list
```
<!-- /snippet -->

Two: back out with `git reset --merge` 🔴, which clears a conflicted index, and use `git stash branch`. It creates a branch at the commit the entry was made on, applies the entry there, where it can't conflict, and drops it.

<!-- snippet: ch11/stash-conflict/05-back-out-and-branch -->
```text
$ git reset --merge
$ git status -s
$ git stash branch try-10s-timeout
Switched to a new branch 'try-10s-timeout'
On branch try-10s-timeout
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   serve.yaml

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (c94265dd6415b63fc30a245db496836c128b5b90)
$ git log --oneline --decorate --all
00eed5e (main) Hotfix: lower timeout to 20s
6cde22d (HEAD -> try-10s-timeout) Add serving config
$ git stash list
```
<!-- /snippet -->

**[ANIMATION]** step: pop.put-back

**A dropped entry.** The objects stay for a while, and with the ID that `drop` printed, `c94265d`, the entry can be put back. That's why the line was worth remembering.

<!-- snippet: ch11/stash-conflict/06-dropped-entry-by-id -->
```text
$ git stash show c94265d
 serve.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git stash store -m 'recovered: try a 10s timeout' c94265d
$ git stash list
stash@{0}: recovered: try a 10s timeout
```
<!-- /snippet -->

`git stash store` gives the commit its place in the list again. Without the ID, the stash manual's `git fsck --unreachable` recipe lists candidates. Lab 8.6 uses it.

**The trap, shown last.** `labs/run ch11/stash-untracked-trap`. An entry made with `-u` holds a change to `limits.yaml` and an untracked `notes.md`. You pop it onto a `limits.yaml` that has a local edit.

<!-- snippet: ch11/stash-untracked-trap/01-refused-but-not-untouched -->
```text
$ git stash show --include-untracked
 limits.yaml | 2 +-
 notes.md    | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git status -s
 M limits.yaml
$ git stash pop
error: Your local changes to the following files would be overwritten by merge:
	limits.yaml
Please commit your changes or stash them before you merge.
Aborting
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
$ git status -s
 M limits.yaml
?? notes.md
```
<!-- /snippet -->

The pop is refused, the entry is kept, and look at the last status: `notes.md` is on disk. Refused, but not untouched. You move the local edit out of the way and pop again.

<!-- snippet: ch11/stash-untracked-trap/02-half-applied -->
```text
$ git restore limits.yaml
$ git stash pop
notes.md already exists, no checkout
error: could not restore untracked files from stash
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   limits.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
$ git status -s
 M limits.yaml
?? notes.md
$ git stash list
stash@{0}: On main: wip: per-tenant limits
```
<!-- /snippet -->

"notes.md already exists, no checkout." The tracked change was applied, the untracked file was refused because it now exists, and the entry stayed in the list although all of its content is on disk. Compare before you drop such an entry by hand.

<!-- snippet: ch11/stash-untracked-trap/03-compare-then-drop -->
```text
# Tracked part: the working tree against the stash commit. No output means identical.
$ git diff 'stash@{0}' -- limits.yaml
# Untracked part: it lives in the third parent of the stash commit.
$ git show 'stash@{0}^3:notes.md' | diff - notes.md
[exit status: 0]
$ git stash drop
Dropped refs/stash@{0} (0907588c369b90c4d2f36bbac3e020f15c62e4e3)
```
<!-- /snippet -->

The tracked part against the stash commit: no output means identical. The untracked part lives in the third parent of the stash commit, `stash@{0}^3`. Identical too. Only then the drop.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Running `git clean -f` without the same command with `-n` first.** Root cause: untracked files were never objects, so no reflog, `fsck` or stash can bring them back.
2. **Using `-x` where `-d` was meant.** Root cause: `-x` adds ignored paths, which is where `.env` files, datasets and checkpoints usually are.
3. **Assuming a plain `git stash push` took the new files.** Root cause: without `-u` an entry holds changes to tracked files only.
4. **Running `git stash drop` straight after a conflicted pop "because pop did not".** Root cause: pop skipped the drop on purpose; the entry is the only complete copy until the conflict is resolved.
5. **Keeping a week of work in the stash.** Root cause: an entry is reachable only from `refs/stash`, is not pushed, not shown by `git log`, and one `drop` or `clear` removes its only ref.

## PRODUCTION EXAMPLE

**[ANIMATION]** gates: gates=git_stash_push_-u:done|fix_the_incident:done|commit:done|git_stash_pop:done packet=wip:_per-tenant_limits title=Four_commands,_ten_minutes at_1=35 at_2=55 at_3=62 at_4=68

**[ANIMATION]** step: 4

Now, out of the lab. An incident interrupts a refactoring of per-tenant rate limits in an inference gateway. The engineer runs `git stash push -u -m "wip: per-tenant limits"`, fixes the incident, commits, and runs `git stash pop`. Four commands, ten minutes. That's what stash is for.

**[ANIMATION]** end

The textbook's advice on the message: always give `-m`. Without it, entries are listed as `WIP on <branch>` plus the subject of the base commit, and five of those look alike.

**[ANIMATION]** replay: why

And when the interruption turns out to last until tomorrow: for work that must outlive the day, a commit on a branch is the better container. It shows in `git log`, can be pushed, and no single command drops it. `git stash branch` converts an entry into exactly that.

**[ANIMATION]** step: bench.3

**[ANIMATION]** say: git_stash_push_-u_clears_the_same_untracked_files_and_keeps_them_as_objects

For the engineer in the hook, the lesson is the last of the five answers. They wanted a clean tree. `git stash push -u` clears the same untracked files and keeps them as objects. That's the second answer: what they should have typed.

## PRACTICE EXERCISE

Your turn. Do Lab 8.6, "Stash and a pop conflict", in [`lab-manual/m08-undo.md`](../../lab-manual/m08-undo.md).

Predict before you type:

- After `git stash push`, what does `git status -s` show, and where do `refs/stash`, HEAD and your branch point?
- When the pop conflicts: what are the two marker labels, what is the exit status, and is the entry still listed?
- After you drop the entry in the failure scenario: by which two routes can it be found, and what does each need?

The challenge is Lab 8.5, "Clean safely", in the same file. Write down the expected list of every dry run before you run it.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q177: "What is inside a stash entry and where is it stored? What happens when `git stash pop` conflicts? Give three reasons not to use the stash for long-term storage."

**[PAUSE]**

Answer out loud first.

**[PAUSE]**

**[ANIMATION]** step: draw.records

A strong answer describes an entry as objects and a ref, with the parents by role, and says where older entries are kept. For the conflict it gives the state of the working tree, the index and the stash list, and names both ways forward. The three reasons should be consequences of the storage you described in the first part, not a separate list of opinions. If the reasons follow from the mechanism, the answer holds together.

## RECAP

**[ANIMATION]** step: untracked.setup

Let's land this. You should now be able to say:

`git clean` deletes untracked files, which were never objects, so nothing in Git can restore them. I run it with `-n` first and read the list.

**[ANIMATION]** step: draw.records

A stash entry is a commit whose parents are the old HEAD and the index, plus a third for untracked files with `-u`, reachable only from `refs/stash`.

**[ANIMATION]** step: pop.put-back

`pop` is `apply` plus `drop`, and the drop is skipped when the apply conflicts. `--index` restores the staged state. A dropped entry can be stored again by the ID that `drop` printed, while the object still exists.

**[ANIMATION]** step: why.3

For work that must outlive the day I commit on a branch.

## HOMEWORK

Read sections 11.10 and 11.11 of [Chapter 11](../../textbook/ch11-reset-revert-restore.md).

Do Exercise 8.3, Level 1, "park an edit and bring it back", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

You can now tell that engineer why nothing brings the files back, and which tray would have kept them. Try a stash and a pop in the lab before the next video. Next time: one table, one decision tree, and seven worked undo scenarios. Until then, look at the state first and type second. See you in the next one.

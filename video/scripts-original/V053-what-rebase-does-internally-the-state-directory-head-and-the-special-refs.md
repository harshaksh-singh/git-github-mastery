# V053: What rebase does internally: the state directory, HEAD, and the special refs

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 20
- **Prerequisites:** V024, V052
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), section 9.4
- **Demo scripts:** `labs/ch09/rebase-internals.sh`, `labs/ch09/apply-backend.sh`

## HOOK

**[ON SCREEN]** `* (no branch, rebasing feat/rerank)`

A colleague calls you over. Their terminal shows a wall of hints ending in "Could not apply". `git branch` prints the line on screen. `git status` says "interactive rebase in progress", and they are certain they never typed `-i`. They ask two things: "Have I broken the branch?" and "Is it safe to delete whatever is stuck?"

The answer to the first is no, and you can prove it with one command. The answer to the second is also no, and the reason is a directory inside `.git` that almost nobody has opened. Today you open it.

## INTRODUCTION

In the last video a rebase ran from start to finish in one second, and you saw only the before and the after. To see the machinery you have to make it stop in the middle.

So today's repository has a conflict built in: the second commit of the feature branch changes a line that `main` has also changed. The rebase replays one commit, stops at the second, and waits. The conflict itself is the subject of a later video. Today you leave it alone and look around: where HEAD is, where the branch is, what the state directory contains, and what the special refs `ORIG_HEAD` and `REBASE_HEAD` name.

Then you leave with `--abort`, read the reflogs, and take a short look at the older implementation, the apply backend, because you will meet its messages in old scripts and old answers.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Say where HEAD, the branch ref, `ORIG_HEAD` and `REBASE_HEAD` point while a rebase is stopped.
- Read the files of `.git/rebase-merge` to learn what is done and what remains.
- Explain when the branch ref moves, and what that means for commits made during the stop.
- Contrast the merge backend with the apply backend.

## CONCEPT

In one sentence: a rebase is a small interpreter. It writes a list of instructions into a state directory inside `.git`, executes them one at a time on a detached HEAD, and touches the branch ref only when the list is empty.

Each clause of that sentence is something you can check.

"A list of instructions": one line per commit, each beginning with `pick`. Git calls it the todo list; the file is `git-rebase-todo`.

"A state directory": `.git/rebase-merge/`. It exists exactly as long as a rebase is in progress. It records which ref will be moved at the end, where that ref pointed at the start, which commit the copies are built on, what has been done and what remains.

"On a detached HEAD": while the rebase runs, `.git/HEAD` holds a raw commit ID. HEAD walks along the new commits as they are made.

"Touches the branch ref only when the list is empty": this is the clause people get wrong. While a rebase is stopped, the branch has not moved. It still names the old tip. The new commits made so far are reachable only from HEAD.

Two consequences. First, `--abort` is cheap and safe: it only has to attach HEAD to the branch again and restore the index and working tree from it. Second, if you make commits of your own during the stop, they are made on the detached HEAD; they become part of the branch only if the rebase finishes.

The special names. `ORIG_HEAD` is the tip of the branch before the rebase began. `REBASE_HEAD` is the commit that is being replayed right now; it exists only while a rebase is stopped.

The textbook attaches a version note to those names. Older behavior: the glossary called every such file, `ORIG_HEAD` and `REBASE_HEAD` included, a pseudoref, and most tutorials still do. Current behavior, since Git 2.46: "pseudoref" means only `FETCH_HEAD` and `MERGE_HEAD`; the others are ordinary refs that live at the root of the ref namespace. Recommended: say "root ref", and read them with `git rev-parse`, not with `cat`.

And the failure mode: deleting the state directory by hand. That leaves HEAD detached on a half-built history.

## MENTAL MODEL

**[ON SCREEN]** "An interpreter with a program counter. The branch is the last instruction."

Think of a tiny interpreter running a script. The script is the todo list. `done` is the part already executed, `git-rebase-todo` the part still to run, and `msgnum` and `end` are the program counter: instruction 2 of 3. A conflict is the interpreter pausing for input.

The move of the branch is not something that happens along the way. It is the last step of the script, after the last `pick`.

Where the picture breaks: a paused program usually holds its state in memory, and killing the process loses it. Git holds the state in files. You can close the terminal, restart the machine, come back the next day, and `git status` will read the same state directory back to you. That is also why a rebase left half done by somebody else is still sitting there, waiting.

## DIAGRAM

**[DIAGRAM]** Draw `main` and the feature branch as they were. Then add one copy above `main`'s tip and put the HEAD label on it. Keep the `feat/rerank` label on the old tip. Last, the `REBASE_HEAD` arrow.

```text
                     1c9f69a                    HEAD (detached): copy of 5ee19f0
                    /
  8afc6bd---439e4c6                             main
         \
          5ee19f0---569e6c9---ad106e3           feat/rerank, ORIG_HEAD
                    ^
                    REBASE_HEAD: the commit being replayed
```

**[DIAGRAM]** Second picture: what the files of the state directory mean.

```text
head-name          the ref that will be moved at the end: refs/heads/feat/rerank
orig-head          where that ref pointed when the rebase started
onto               the commit that the copies are built on
git-rebase-todo    the instructions not yet executed, one per line: Git calls this the todo list
done               the instructions already executed
msgnum, end        the position: instruction 2 of 3
author-script      author name, email and date of the commit being replayed, reused for its copy
message            the commit message that will be reused when you continue
stopped-sha        the commit at which the rebase stopped
rewritten-list     "old ID, new ID" for each commit copied so far; input for the post-rewrite hook
interactive        marker of the merge backend (see the note on "git status" below)
```

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/rebase-internals`.

**Step 1: before.**

<!-- snippet: ch09/rebase-internals/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 439e4c6 (main) Raise TOP_K to 8 after recall regression
| * ad106e3 (HEAD -> feat/rerank) Enable reranking in config
| * 569e6c9 Fetch 20 candidates for the reranker
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Three commits on `feat/rerank`, one new commit on `main`. The middle commit, "Fetch 20 candidates for the reranker", touches the line that `main` changed.

**Step 2: the stop.** `git rebase` 🟡 CAUTION.

<!-- snippet: ch09/rebase-internals/02-stop -->
```text
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
error: could not apply 569e6c9... Fetch 20 candidates for the reranker
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 569e6c9... # Fetch 20 candidates for the reranker
[exit status: 1]
```
<!-- /snippet -->

One commit replayed, the second stopped with a conflict, exit status 1. Now the question of this video. Where does `feat/rerank` point right now: at the old tip, at the one copy that was made, or somewhere else? Decide before you go on.

**[PAUSE]**

**Step 3: HEAD.**

<!-- snippet: ch09/rebase-internals/03-head -->
```text
$ cat .git/HEAD
1c9f69a02aeeb08430a5015ba7af214c9b96d0a0
$ git branch
* (no branch, rebasing feat/rerank)
  feat/rerank
  main
$ git log --oneline --decorate -3
1c9f69a (HEAD) Add reranker skeleton
439e4c6 (main) Raise TOP_K to 8 after recall regression
8afc6bd Add retriever and model config
```
<!-- /snippet -->

`.git/HEAD` holds a raw commit ID, not `ref: refs/heads/...`. HEAD is detached. It sits on `1c9f69a`, the copy of "Add reranker skeleton", which sits on the tip of `main`. `git branch` describes the situation as "no branch, rebasing feat/rerank".

**Step 4: the state directory.**

<!-- snippet: ch09/rebase-internals/04-state-dir -->
```text
$ ls .git/rebase-merge
author-script
done
drop_redundant_commits
end
git-rebase-todo
git-rebase-todo.backup
head-name
interactive
message
msgnum
no-reschedule-failed-exec
onto
orig-head
patch
rewritten-list
stopped-sha
```
<!-- /snippet -->

Sixteen files. You need six of them.

<!-- snippet: ch09/rebase-internals/05-state-files -->
```text
$ cat .git/rebase-merge/head-name
refs/heads/feat/rerank
$ cat .git/rebase-merge/orig-head
ad106e3ecc6f4d2e14376112d9580c6892a12093
$ cat .git/rebase-merge/onto
439e4c6ba104e7816d32d16fd3bd9548e536b33f
$ cat .git/rebase-merge/done
pick 5ee19f03aa988c15717abc4b6c14104fc8d23a97 # Add reranker skeleton
pick 569e6c983316561062d42644d649129e50eeda5d # Fetch 20 candidates for the reranker
$ cat .git/rebase-merge/git-rebase-todo
pick ad106e3ecc6f4d2e14376112d9580c6892a12093 # Enable reranking in config
$ cat .git/rebase-merge/msgnum .git/rebase-merge/end
2
3
$ cat .git/rebase-merge/author-script
GIT_AUTHOR_NAME='Lab User'
GIT_AUTHOR_EMAIL='you@example.com'
GIT_AUTHOR_DATE='@1788755640 +0530'
```
<!-- /snippet -->

`head-name`: the ref that will be moved at the end. `orig-head`: where it pointed at the start. `onto`: what the copies are built on. `done`: two picks, the one that succeeded and the one that stopped. `git-rebase-todo`: one pick left. `msgnum` and `end`: 2 of 3. And `author-script`: the author name, email and date of the commit being replayed, to be reused for its copy. That file is how a rebase keeps the author while changing the committer.

**Step 5: the four names.**

<!-- snippet: ch09/rebase-internals/06-special-refs -->
```text
$ git rev-parse --short ORIG_HEAD
ad106e3
$ git rev-parse --short REBASE_HEAD
569e6c9
$ git rev-parse --short feat/rerank
ad106e3
$ git rev-parse --short HEAD
1c9f69a
```
<!-- /snippet -->

Four names, three commits. `ORIG_HEAD` is `ad106e3`, the tip before the rebase. `REBASE_HEAD` is `569e6c9`, the commit being replayed. HEAD is `1c9f69a`, the last copy made. And `feat/rerank` is `ad106e3`: it still equals `ORIG_HEAD`. The branch has not moved. That is the answer to the question, and to your colleague's first question: no, the branch is not broken. It has not been touched.

**Step 6: status.**

<!-- snippet: ch09/rebase-internals/07-status -->
```text
$ git status
interactive rebase in progress; onto 439e4c6
Last commands done (2 commands done):
   pick 5ee19f0 # Add reranker skeleton
   pick 569e6c9 # Fetch 20 candidates for the reranker
Next command to do (1 remaining command):
   pick ad106e3 # Enable reranking in config
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feat/rerank' on '439e4c6'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   app/retriever.py

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

`git status` reads the state directory back to you: what was done, what remains, and the three ways out. And the first line says "interactive rebase in progress", although no `-i` was typed. The root cause, from the textbook: the default backend of `git rebase` is the machinery that once served only interactive rebases; it always writes the marker file `interactive`, and `git status` reports what it finds.

**Step 7: leave the way you came.** `git rebase --abort` 🟡 CAUTION in the textbook's table, with one thing it cannot give back. The five answers. It changes HEAD, the index and the working tree: all return to the old tip. It destroys resolution work in progress, the edits you made to conflicted files. Preview with `git status`. There is no recovery for unstaged resolution edits; the copies already made stay in the reflog. It is appropriate whenever you want the state before the rebase and have no resolution work worth keeping. Here nothing has been resolved.

<!-- snippet: ch09/rebase-internals/08-abort -->
```text
$ git rebase --abort
$ git status
On branch feat/rerank
nothing to commit, working tree clean
$ git reflog -3
ad106e3 HEAD@{0}: rebase (abort): returning to refs/heads/feat/rerank
1c9f69a HEAD@{1}: rebase (pick): Add reranker skeleton
439e4c6 HEAD@{2}: rebase (start): checkout main
```
<!-- /snippet -->

On the branch again, clean. The reflog shows start, one pick, abort. The copy `1c9f69a` is now reachable from nothing except the reflog.

**[ON SCREEN]** The state table of section 9.4, three rows.

```text
Operation                  Working tree                 Index                  HEAD                       Current branch ref        Other refs and files in .git
-------------------------  ---------------------------  ---------------------  -------------------------  ------------------------  ------------------------------------
stopped at a conflict      conflict markers in the      stages 1, 2 and 3      detached at the last       unchanged: still the      state directory .git/rebase-merge/;
                           conflicted files             for conflicted paths   copy                       old tip                   REBASE_HEAD; ORIG_HEAD
git rebase --abort         reset to the old tip:        reset to the old tip   attached to the branch     unchanged                 state directory and REBASE_HEAD
                           resolution work is lost                             again                                                removed; ORIG_HEAD stays
git rebase --quit          unchanged                    unchanged              stays detached where       unchanged                 state directory removed; an
                                                                               it is                                                autostash moves to the stash list
```

Look at the column "Current branch ref". Unchanged, unchanged, unchanged. And look at `--quit`: it removes the state directory and leaves HEAD detached where it is. That is what deleting the directory by hand does, except that `--quit` does it on purpose.

When a rebase runs to the end, the two reflogs record it differently; you saw this in the last video. The HEAD reflog has one line per step. The branch reflog has one line for the whole rebase, and the line below it is the old tip. So `<branch>@{1}` means "this branch before its last rebase", and that is the most reliable undo handle you have.

**Step 8: the other backend.** `labs/run ch09/apply-backend`. Until Git 2.26 the default implementation turned each commit into a patch and applied the patches. It is still there, as `git rebase --apply`.

<!-- snippet: ch09/apply-backend/01-apply-stops -->
```text
$ git rebase --apply main
First, rewinding head to replay your work on top of it...
Applying: Add reranker skeleton
Applying: Fetch 20 candidates for the reranker
Using index info to reconstruct a base tree...
M	app/retriever.py
Falling back to patching base and 3-way merge...
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
error: Failed to merge in the changes.
hint: Use 'git am --show-current-patch=diff' to see the failed patch
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Patch failed at 0002 Fetch 20 candidates for the reranker
[exit status: 1]
```
<!-- /snippet -->

Different words: "rewinding head", "Applying", "Patch failed at 0002".

<!-- snippet: ch09/apply-backend/02-state -->
```text
$ ls .git | grep rebase
rebase-apply
$ ls .git/rebase-apply | head -5
0001
0002
0003
abort-safety
apply-opt
$ git status | head -2
rebase in progress; onto 439e4c6
You are currently rebasing branch 'feat/rerank' on '439e4c6'.
$ head -5 app/retriever.py
<<<<<<< HEAD
TOP_K = 8
=======
TOP_K = 20
>>>>>>> Fetch 20 candidates for the reranker
```
<!-- /snippet -->

A different state directory, `.git/rebase-apply`, with one numbered patch file per commit. "Rebase in progress" without the word interactive. And a conflict label that carries only the subject of your commit, not its ID.

<!-- snippet: ch09/apply-backend/03-abort -->
```text
$ git rebase --abort
$ git status --short --branch
## feat/rerank
```
<!-- /snippet -->

The way out is the same command.

The manual lists what the apply backend does worse: it works from patch context and can apply a hunk in the wrong place without reporting a conflict, it cannot detect directory renames, and it drops empty commits. The textbook's advice is four words: leave `rebase.backend` alone.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Believing the branch has already moved when a rebase stops.** Root cause: the branch ref is touched only when the todo list is empty; until then HEAD is detached and the branch equals `ORIG_HEAD`.
2. **Deleting `.git/rebase-merge` to "get out".** Root cause: the directory is the interpreter's state; removing it leaves HEAD detached on a half-built history, which is what `--quit` does deliberately.
3. **Panicking at "interactive rebase in progress".** Root cause: the default backend always writes the marker file `interactive`, and `git status` reports the file, not what you typed.
4. **Reading `ORIG_HEAD` or `REBASE_HEAD` with `cat`.** Root cause: since Git 2.46 they are ordinary root refs, not pseudorefs, and their storage depends on the ref format; `git rev-parse` reads them correctly.
5. **Aborting after an hour of conflict resolution to "start clean".** Root cause: `--abort` resets the working tree and the index to the old tip, and unstaged resolution edits are objects nowhere.

## PRODUCTION EXAMPLE

A shared build machine for nightly evaluations starts failing with a strange message about a detached HEAD. Someone logs in and finds that the workspace was left in the middle of a rebase by an interrupted job, three days ago.

The textbook's routine for this is short. "Is a rebase in progress here?" The first line of `git status` answers it, and so does `ls .git | grep rebase`. If the answer is yes, nothing is lost: the branch ref has not moved, and `git rebase --abort` returns to it. Do not delete the state directory by hand.

The second lesson from that incident is for the pipeline, not for the person: an automated job that rebases must handle a non-zero exit status by aborting, so that it never leaves a state directory behind for the next job to find.

## PRACTICE EXERCISE

Do Exercise 9.3, Level 1, "a conflict, a look around, and the way back", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

When the rebase stops, do not resolve anything. First write down your predictions for:

- The content of `.git/HEAD`.
- The four values: HEAD, the branch, `ORIG_HEAD`, `REBASE_HEAD`. Which of them are equal?
- The content of `done` and of `git-rebase-todo`.

Then check each one with a command, and only then leave.

The challenge is Exercise 9.7, Level 3, "a rebase that stopped at an `exec` line", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q147: "A rebase is stopped at a conflict. Where do the branch ref, HEAD, `ORIG_HEAD` and `REBASE_HEAD` point? What does that imply for `--abort`?"

Answer aloud first. A strong answer gives four positions without hesitation and says which two are equal and why. It then derives the second half from the first: what `--abort` has to do, and what it therefore cannot give back. It mentions where the information for the abort is stored. If the follow-up asks what happens to a commit you made by hand during the stop, be ready to reason from "HEAD is detached".

## RECAP

You should now be able to say:

A rebase writes a todo list into `.git/rebase-merge`, runs it on a detached HEAD, and moves the branch only when the list is empty. While it is stopped, the branch still equals `ORIG_HEAD`, HEAD is on the last copy, and `REBASE_HEAD` names the commit being replayed. `git status` reads the state directory back: done, remaining, and the ways out. `--abort` returns to the branch and discards resolution work in progress; `--quit` removes the state and leaves HEAD detached. The apply backend uses `.git/rebase-apply` and patch files, and the default merge backend is the one to keep.

## HOMEWORK

Read section 9.4 of [Chapter 9](../../textbook/ch09-rebase.md).

# V006: Worked example: the fix that was committed and did not ship

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 20
- **Prerequisites.** V005
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), sections 1.12 to 1.15
- **Demo scripts.** `labs/ch01/diagnosis.sh` (snippets `11-test`, `12-fix`, `13-verify`), `labs/ch01/pitfalls.sh` (snippets `01-unconfigured-init`, `02-not-a-repository`, `04-embedded-repository`, `05-embedded-undo`)

## HOOK

**[ON SCREEN]** "The fix is committed."

Friday evening again. The pipeline, the team's automated build and test run, is red. The engineer on call says "the fix is committed", and can show the commit on screen. And the pipeline fails again on the same line.

In video 1 the CTO asked three questions. What exactly is in the commit that the pipeline built? Where does that commit exist right now? And what is the smallest change that makes the main branch correct, and how will we know that it worked?

**[PAUSE]**

In the last video you collected the evidence. Now you answer all three questions, in order, without guessing once.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video is one complete investigation, from report to prevention. You have the framework from video 4 and the evidence from video 5. We continue with the remaining steps: understand the state, form hypotheses, test them, name the root cause, select the lowest-risk fix, execute, verify, prevent.

Then, because first days go wrong in a small number of known ways, we look at the pitfalls that the textbook collects in section 1.13, and read what Git prints for each. Most of those messages name the cause, if you read them word by word.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Apply the framework to the report "the fix is committed" and find where it is not.
2. List the places where "committed" can be true or false.
3. Recognize four first-day pitfalls from their output.
4. Decide when a guided method is the wrong tool.

## CONCEPT

**Understand state.** The outputs of `git rev-parse`, `git show` and `git diff` from the last video give the content of two files in each place. The places, once more: the working tree is the files on disk, the index is what the next commit will record, and the last commit is the latest snapshot.

**[ON SCREEN]** The state table of section 1.12.

`configs/eval.yaml`: in the last commit, `f29df3b`, which is also on the server, it says `timeout_s: 120`. The index has the same, and so does the working tree. `eval/runner.py`: in the last commit, `MAX_TIMEOUT_S = 60`. In the index, 60. In the working tree, 120.

**[ANIMATION]** trees: setup, edit, add, commit file=eval/runner.py

**[ANIMATION]** step: edit

Say that in one sentence: the fix has two halves, the commit holds one of them, and the other exists only on the laptop's disk. On screen, that's the edit sitting in the working tree alone.

**Form hypotheses.** Four mechanisms could produce the symptom, and for each there is evidence that would confirm it.

H1: the change to `runner.py` was never saved. Then the working tree would show 60.

H2: it was saved and never staged, so no commit contains it. Then the commit would show 60, and `git diff` would show the change.

**[ANIMATION]** graph: 25fbbb0-f29df3b main origin/main; 25fbbb0-1c96817 feature/cache; HEAD=main => 25fbbb0-f29df3b-230ef10 main origin/main; 25fbbb0-1c96817 feature/cache; HEAD=main

**[ANIMATION]** step: state-1

H3: it was committed on another branch. Then another commit would touch `runner.py`.

H4: it was committed and not pushed, so CI built an older commit. Then `HEAD` and `origin/main` would differ.

Quick quiz, and the picture helps. Last video's evidence already rejects one of these two. Option one: H3, another branch. Option two: H4, not pushed. Say it out loud.

**[PAUSE]**

H4. In the picture, `main` and `origin/main` sit on the same commit, so nothing is waiting to be pushed. H3 is still open: `feature/cache` exists, and we haven't checked what it touched.

**[ANIMATION]** end

Notice that these four are the places where "committed" can be false: not saved, not staged, on another branch, not pushed. Each has its own checking command.

**Select the lowest-risk fix.** Once the root cause is named, there are two candidate fixes. Option one: a new commit with the missing file. Its risk is 🟢: it adds a commit, and anyone who already fetched `f29df3b` is unaffected. Option two: amend `f29df3b` and force-push, which means replace the commit and overwrite the server's copy. That is 🟡, then 🔴: it replaces a commit that the server and possibly colleagues already have. The textbook's verdict on the second: rejected, because a tidier log is not worth rewriting shared history.

**Execute, with a preview.** `git push` carries the label 🟡 CAUTION, because it changes shared state: it moves a branch on the remote and copies objects to it. The preview is `git push --dry-run`. And the recovery line of the command-safety table is worth hearing once: a push can't be taken back quietly once others have fetched. You publish a correcting commit.

**When not to use it.** Section 1.14 lists where Git alone is the wrong tool. Large binary data such as datasets, model weights and media: every version of every file stays in the history and travels to every clone, so keep a pointer in Git and the data elsewhere. Secrets: a committed and pushed secret is in every clone. Deleting the file in a later commit doesn't remove it from history, and the remedy starts with rotating the secret. Generated files such as build output, virtual environments and caches: ignore them.

And where the method is not enough: the ten commands describe one clone. They say nothing certain about the server until you fetch, and nothing at all about GitHub objects such as pull requests, rulesets and check results.

## MENTAL MODEL

**[ANIMATION]** step: edit

Hold "committed" as a chain of four links: saved, staged, committed on the branch you think, pushed. A change ships only if every link holds. The report "the fix is committed" asserts the third link and says nothing about the others.

**[ANIMATION]** step: state-1

The chain breaks as a model at its last link. "Pushed" is true as far as your clone knows. Your clone's knowledge of the server is the cached `origin/main`. And beyond the server there is the platform: whether the pipeline ran, and on which commit, is a GitHub fact that no local command shows.

## DIAGRAM

**[DIAGRAM]** The diagram of section 1.12. Draw the left box, then the server, then the arrow.

```text
  Your clone                                            The server (origin.git, bare)
 +----------------------------------------------+      +-------------------------------+
 |  25fbbb0---f29df3b   main, origin/main       | push |  25fbbb0---f29df3b   main     |
 |        \                (HEAD -> main)       | ---> |                               |
 |         1c96817      feature/cache           |      |  CI builds f29df3b:           |
 |                                              |      |  MAX_TIMEOUT_S = 60           |
 |  index:        runner.py has 60              |      +-------------------------------+
 |  working tree: runner.py has 120  (the fix)  |
 +----------------------------------------------+
```

On the left, your clone: two commits on `main`, one on `feature/cache`. Under the graph, the two lines that matter: the index has 60 in `runner.py`, the working tree has 120. On the right, the server has the same two commits on `main`, and CI builds `f29df3b`, where the constant is 60. The push arrow carried commits. It didn't carry the working tree, because a push never does.

**[ANIMATION]** step: state-1

**[DIAGRAM]** The root-cause box of section 1.12, one line at a time, after the test.

```text
Observed behavior : CI fails with the old 60-second limit although the fix commit is on main.
                    The test passes on the author's laptop.
Git state         : HEAD = origin/main = f29df3b, which changes configs/eval.yaml only.
                    eval/runner.py is modified in the working tree and not staged.
Mechanism         : git commit records the index. Two files were edited; one was staged.
                    The local test reads the working tree. CI checks out the commit.
Root cause        : The second file was never added to the index, so it is in no commit.
Why Git does this : The index exists so that you choose what a commit contains. A commit is
                    what was staged, not what is on disk.
Correct fix       : Stage eval/runner.py, commit, push. One new commit; nothing is rewritten.
Prevention        : Read git status and git diff --cached before each commit.
                    Trust the test that runs on the commit, which is what CI does.
```

The root-cause box comes after the test. Until then, hold this picture: `main` and `origin/main` on the same commit.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/diagnosis.sh`, snippet `11-test`.

**Test the hypotheses.** Three read-only commands separate the four hypotheses. Predict the output of each before it appears. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch01/diagnosis/11-test -->
```text
$ git log --oneline --all -- eval/runner.py
25fbbb0 Add evaluation runner and config
$ git show HEAD:eval/runner.py | grep '^MAX_TIMEOUT_S'
MAX_TIMEOUT_S = 60
$ grep '^MAX_TIMEOUT_S' eval/runner.py
MAX_TIMEOUT_S = 120
```
<!-- /snippet -->

`git log --all -- <path>` lists the commits on any branch that changed the path. Only `25fbbb0` does. So H3, "committed on another branch", is rejected. `git show HEAD:eval/runner.py` prints the file as the last commit recorded it: 60. The plain `grep` reads the working tree: 120. So H1, "never saved", is rejected, because the working tree shows 120. H4, "not pushed", was rejected in the last video: `HEAD` and `origin/main` have the same ID. H2 is confirmed: saved, never staged, in no commit.

Try it now, on paper. Thirty seconds: write the root cause in one sentence. Then compare your answer with mine.

**[PAUSE]**

**[DIAGRAM]** Show the root-cause box now.

**Root cause.** The second file was never added to the index, so it's in no commit. And the layer is Git. GitHub and Actions did their job: the pipeline tested the commit it was given.

**[TERMINAL]** Snippet `12-fix`.

**[ANIMATION]** step: commit

**Execute.** `git add` and `git commit` are 🟢 SAFE. `git push` is 🟡 CAUTION, so it's previewed with `--dry-run` first. Predict what the dry run will print.

<!-- snippet: ch01/diagnosis/12-fix -->
```text
$ git add eval/runner.py
$ git diff --cached --stat
 eval/runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git commit -m "Raise runner timeout cap to 120s"
[main 230ef10] Raise runner timeout cap to 120s
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push --dry-run
To $LAB/ch01/diagnosis/origin.git
   f29df3b..230ef10  main -> main
$ git push
To $LAB/ch01/diagnosis/origin.git
   f29df3b..230ef10  main -> main
```
<!-- /snippet -->

`git diff --cached` now shows exactly what the commit will record: one file, one line each way. The commit is `230ef10`. The dry run and the real push print the same line: `f29df3b..230ef10  main -> main` means the server's `main` moved from the old commit to the new one.

**[ON SCREEN]** The state table for `git push`: working tree, index, HEAD and current branch ref unchanged; `refs/remotes/origin/main` moves to the pushed commit; the server's `main` moves and missing objects are copied to it; on GitHub, workflows that listen for pushes can start.

**[TERMINAL]** Snippet `13-verify`.

**Verify.** Repeat the commands that showed the problem. The evidence must have changed for the reason you predicted.

<!-- snippet: ch01/diagnosis/13-verify -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	run.log

nothing added to commit but untracked files present (use "git add" to track)
$ git log --oneline -3
230ef10 Raise runner timeout cap to 120s
f29df3b Raise eval timeout to 120s
25fbbb0 Add evaluation runner and config
$ git rev-parse HEAD origin/main
230ef105d2234274936997629350568cbac83839
230ef105d2234274936997629350568cbac83839
$ git show HEAD:eval/runner.py | grep '^MAX_TIMEOUT_S'
MAX_TIMEOUT_S = 120
```
<!-- /snippet -->

Nothing tracked is modified. The new commit is on top. `HEAD` and `origin/main` agree. And the committed file has the new value. On GitHub, the pipeline run for `230ef10` must pass. That part can't be shown from a local sandbox.

**[ANIMATION]** step: state-2

Here's the history now. `230ef10` is on top, and the names `main`, `origin/main` and HEAD all sit on it.

**Prevent.** Before every commit, read both lists in `git status`, and read `git diff --cached` as the text of what you're about to record. `git commit -a` would have included the second file, because it stages every modified tracked file first. For the same reason it also includes changes you didn't mean to commit, so it's not a substitute for looking.

**So, the CTO's three questions.** What was in the commit? One half of the fix. Where is the whole fix now? In `230ef10`, on your clone and on the server. And how do we know? The commands that showed the problem now show it gone.

**[TERMINAL]** Caption bar: `labs/ch01/pitfalls.sh`.

**Now the first-day pitfalls.** You saw one of them, "nothing staged", in video 4. Here are the others. Read each message word by word.

```bash
labs/run ch01/pitfalls
```

**The first branch is not called `main`.**

<!-- snippet: ch01/pitfalls/01-unconfigured-init -->
```text
# With no configuration at all, Git 2.55 still names the first branch master.
$ GIT_CONFIG_GLOBAL=/dev/null git init plain
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
Initialized empty Git repository in $LAB/ch01/pitfalls/plain/.git/
$ cat plain/.git/HEAD
ref: refs/heads/master
$ git -C plain branch -m main
$ cat plain/.git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

With no configuration at all, Git 2.55 names the first branch `master` and prints a hint. The hint says where the name comes from, that it will change to "main" in Git 3.0, and how to set it. The lab configuration sets `init.defaultBranch=main`, which is why every other transcript says `main`. `git branch -m main` is 🟡 CAUTION: it renames the current branch. Here the branch is unborn, and the last line shows that only the text in `HEAD` changed.

**Git says there is no repository.**

<!-- snippet: ch01/pitfalls/02-not-a-repository -->
```text
$ mkdir notes && cd notes
$ git status
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
$ cd ..
```
<!-- /snippet -->

Read the parenthesis: "or any of the parent directories". Git searched the current directory and its parents for a dot git directory and found none. Exit status 128.

**A repository inside a repository.**

<!-- snippet: ch01/pitfalls/04-embedded-repository -->
```text
$ git status --short
?? vendor/
$ git add .
warning: adding embedded git repository: vendor/tokenizer
hint: You've added another git repository inside your current repository.
hint: Clones of the outer repository will not contain the contents of
hint: the embedded repository and will not know how to obtain it.
hint: If you meant to add a submodule, use:
hint:
hint: 	git submodule add <url> vendor/tokenizer
hint:
hint: If you added this path by mistake, you can remove it from the
hint: index with:
hint:
hint: 	git rm --cached vendor/tokenizer
hint:
hint: See "git help submodule" for more information.
hint: Disable this message with "git config set advice.addEmbeddedRepo false"
$ git ls-files --stage
100644 3a79082bc80505c7543e79c4312e3e3d276a0e04 0	README.md
160000 26803e94675c7c4dba579a4a20be4109737ce628 0	vendor/tokenizer
```
<!-- /snippet -->

`vendor/tokenizer` has its own `.git` directory. Git doesn't add its files. It records one entry with mode `160000`, a gitlink: the ID of a commit in the inner repository. The warning says what follows: clones of the outer repository will not contain the contents of the embedded repository. This happens when you run `git init` or `git clone` inside an existing working tree. And the hint offers an undo. Predict: will the command from the hint work?

**[PAUSE]**

<!-- snippet: ch01/pitfalls/05-embedded-undo -->
```text
# The command from the hint is refused. Unstaging with git restore works.
$ git rm --cached vendor/tokenizer
error: the following file has staged content different from both the
file and the HEAD:
    vendor/tokenizer
(use -f to force removal)
[exit status: 1]
$ git restore --staged vendor/tokenizer
$ git status --short
?? vendor/
```
<!-- /snippet -->

It's refused. `git rm --cached` and `git restore --staged` are both 🟡 CAUTION: they change or remove an index entry, and files on disk stay. The textbook's root-cause box gives the reason for the refusal. `git rm` refuses to drop an index entry that matches neither HEAD nor the working tree. That test protects staged content that exists nowhere else, and a freshly added embedded repository fails both halves of it. The correct fix is `git restore --staged vendor/tokenizer`, which resets only the index entry. Before the first commit there is no HEAD to restore from. There, `git rm --cached -f` works, and `--cached` guarantees that the working tree is not touched. The textbook notes that this mechanism was read from the Git 2.55.0 source. After unstaging, decide what the inner repository is: a separate project to ignore, or a dependency to add properly as a submodule.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A commit that lacks a file.** Root cause: `git commit` records the index; two files were edited and one was staged.
2. **Fixing a pushed commit by amending and force-pushing.** Root cause: a wish for a tidier log; the amend replaces a commit that the server and possibly colleagues already have.
3. **"not a git repository".** Root cause: Git searched the current directory and its parents for `.git` and found none; `pwd` and `git rev-parse --show-toplevel` show where you are.
4. **"adding embedded git repository".** Root cause: `git init` or `git clone` was run inside an existing working tree; run `git rev-parse --show-toplevel` before either.
5. **Trusting the local test over the test on the commit.** Root cause: the local test reads the working tree, and CI checks out the commit.

## PRODUCTION EXAMPLE

Now, out of the lab. The case you've worked through is the production example, and the textbook draws one more lesson from it. The symptom "the fix did not ship" was reported against the pipeline, so the first suspicion fell on GitHub Actions. The root cause was in Git, on one laptop, in the gap between the working tree and the index. The pipeline had done what it was built to do. For an evaluation team this matters twice: a score computed from a working tree with uncommitted edits can't be reproduced from the commit ID in the report. Trust the test that runs on the commit.

## PRACTICE EXERCISE

Your turn. Do Exercise 1.9, Level 4, "git log says there are no commits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before you run anything in the generated sandbox, write the symptom in one sentence without interpretation, and list at least three hypotheses with the read-only command that would separate them. Only then start the ritual.

## INTERVIEW QUESTION

Q11: "A colleague says "the fix is committed". List the distinct places where that statement can be true or false, and the command that checks each."

**[PAUSE]**

Answer out loud. A strong answer walks the path of a change from the editor to the machine that builds it, names each place the change can be missing, and pairs each place with one read-only command. It distinguishes what your clone knows from what the server holds now. Don't open the answers file until you've named every place you can think of.

## RECAP

**[ANIMATION]** step: commit

Let's land this. You should now be able to say: "committed" can be false in four places: not saved, not staged, on another branch, not pushed. I separate those with `git diff`, `git show HEAD:<path>`, `git log --all -- <path>` and `git rev-parse HEAD origin/main`.

**[ANIMATION]** end

When the faulty commit is already shared, I add a commit and don't rewrite. I preview a push with `--dry-run`, and I verify by repeating the commands that showed the problem. And when Git prints a message, I read it word by word, including the hints, without assuming that a hint is always right.

## HOMEWORK

- Read sections 1.12 to 1.15 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Do the Practice section 1.17.
- Challenge: Exercise 1.8, Level 3, "the object that no history shows", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

That was a complete investigation, from a red pipeline to a prevention rule, and you never had to guess. Do the exercise before the next video. Next time, Part 1 begins: snapshots, not diffs, and content addressing. Until then, look at the state first and type second. See you in the next one.

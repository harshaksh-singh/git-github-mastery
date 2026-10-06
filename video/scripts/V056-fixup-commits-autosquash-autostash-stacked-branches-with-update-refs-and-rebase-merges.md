# V056: Fixup commits, --autosquash, --autostash, stacked branches with --update-refs, and --rebase-merges

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 28
- **Prerequisites:** V055
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), sections 9.7, 9.8, 9.9 and 9.10
- **Demo scripts:** `labs/ch09/autosquash.sh`, `labs/ch09/autosquash-config.sh`, `labs/ch09/autostash.sh`, `labs/ch09/autostash-stopped.sh`, `labs/ch09/update-refs.sh`, `labs/ch09/update-refs-push.sh`, `labs/ch09/rebase-merges.sh`

## HOOK

**[ON SCREEN]** Three pull requests in a chain: loader, cleaner on top of it, chunker on top of that.

**[ANIMATION]** graph: A-R main; A-L1-L2 feat/ingest-loader; L2-C1 feat/ingest-cleaner; C1-K1-K2 feat/ingest-chunker; HEAD=none; say:Three_pull_requests_in_a_chain => + ^L1-L2' feat/ingest-loader; say:A_small_fix_in_the_bottom_branch => + L2'-C1' feat/ingest-cleaner; say:Rebase_the_middle_branch => + C1'-K1'-K2' feat/ingest-chunker; reflog:L2,C1,K1,K2; say:Rebase_the_top_branch:_three_rewrites_for_one_fix id=hook

**[ANIMATION]** step: state-2

Your change is too big for one review. So you split it into three pull requests, each built on the one below. A pull request is GitHub's proposal to merge one branch into another. The reviewer of the bottom one asks for a small fix. You make it.

**[ANIMATION]** step: state-4

Now the middle branch is built on a commit that no longer exists on the bottom branch. So you rebase the middle branch. Now the top branch is built on a commit that no longer exists on the middle branch. So you rebase that as well. Three rebases, three forced pushes, for a one-line fix. And tomorrow there'll be another review comment.

Teams give up on stacked pull requests for exactly this reason. One option makes it a single command. Remember that count: three rebases.

**[ANIMATION]** end

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A commit is one saved snapshot of your project. A branch is a name that points at one commit. A rebase copies your branch's commits onto another commit, and every copy has a new ID.

The last video gave you the todo list, which a rebase executes from top to bottom, and the eight instructions. Today: four options that write or extend that list for you. None of them is a new mechanism. Each one automates something you could do by hand in the editor.

Four options, four jobs. `--autosquash` reads specially named commits and arranges the list. `--autostash` deals with uncommitted changes that would otherwise stop a rebase from starting. `--update-refs` moves every branch in a stack, not only the one you're on. And `--rebase-merges` rebuilds a branch that contains merge commits, commits with more than one parent, which a plain rebase would flatten.

For each one you'll see what it adds, and what it still leaves for you to do. That second half is where the surprises are, and it's today's interview question.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- Record a correction as a fixup commit and fold it in with `--autosquash`.
- Explain where local changes are while a rebase with `--autostash` is stopped.
- Rebase a stack of branches in one operation with `--update-refs`, and publish it.
- Keep merge commits through a rebase with `--rebase-merges`, and say what replaced `--preserve-merges`.

## CONCEPT

**Fixup commits and `--autosquash`.** In one sentence: a fixup commit is a correction recorded now, as a commit of its own, whose subject line names the earlier commit it belongs to. `--autosquash` reads those subjects and arranges the to-do list for you.

`git commit` 🟢 SAFE creates them, with three kinds of subject.

**[ON SCREEN]** The table of section 9.7.

```text
Created with                         Subject of the new commit   Becomes in the list   Effect on the target
-----------------------------------  --------------------------  --------------------  ------------------------------------------------
git commit --fixup=<commit>          fixup! <target subject>     fixup                 Content corrected, message kept
git commit --squash=<commit>         squash! <target subject>    squash                Content corrected, editor opens on both messages
git commit --fixup=amend:<commit>    amend! <target subject>     fixup -C              Content corrected, message replaced
git commit --fixup=reword:<commit>   amend! <target subject>     fixup -C              Message replaced, content untouched
```

Making the correction is safe: it only adds a commit. The rewriting happens later, once, when you run the rebase.

**[ANIMATION]** stores: boxes=working_tree:the_files_you_edit|*state_directory:.git/rebase-merge/|stash_list:git_stash_list rows=1:A:your_uncommitted_edit|2:B:autostash:_a_stash_ID@hl|3:A:the_edit,_applied_again@ok|4:C:stash@{0}:_autostash@ref arrows=2:A1>B1:parked|3:B1>A2:applied|4:B1>C1:--quit title=Where_is_the_autostash? id=stash

**[ANIMATION]** step: 2

**`--autostash`.** In one sentence: a rebase refuses to start while tracked files have uncommitted changes. `--autostash` puts those changes into a stash commit, rebases, and applies the stash to the result. A stash is uncommitted work, recorded as commits that no branch reaches.

The detail that matters: an autostash is a stash commit that is never put on the stash list. While the rebase is stopped, your change is in no file of the working tree, the folder of files you edit, and not on the list. Its ID is in the state directory, the rebase's own folder inside dot git.

**[ANIMATION]** graph: A-R main; A-L1-L2 feat/ingest-loader; L2-C1 feat/ingest-cleaner; C1-K1-K2 feat/ingest-chunker; HEAD=feat/ingest-chunker => R-L1'-L2' feat/ingest-loader; L2'-C1' feat/ingest-cleaner; C1'-K1'-K2' feat/ingest-chunker; A-R main; A-L1-L2-C1-K1-K2; HEAD=feat/ingest-chunker; reflog:L1,L2,C1,K1,K2 title=A_stack_of_three_branches title_state_2=One_rebase_with_--update-refs id=stack

**[ANIMATION]** step: state-1

**`--update-refs`.** In one sentence: it makes a rebase move every local branch that points at one of the replayed commits, not only the branch you're on.

Precisely: for each such branch, Git adds a line `update-ref refs/heads/<name>` to the list, directly after the commit the branch points at, and sets the branch when the list is finished. Not moved: branches checked out in another worktree, tags, which are names that aren't expected to move, and remote-tracking branches, your record of the server's branches.

**[ANIMATION]** graph: 8afc6bd-9cfa98f main; 8afc6bd-1279adf-9a23ecd-7537190-75c9283 feat/ingest; 1279adf-dc5df93 feat/ingest-cleaner; dc5df93-7537190; HEAD=feat/ingest; title:A_branch_with_a_merge_inside => 8afc6bd-9cfa98f main; 9cfa98f-a10544a-043ec63-f4b3cef-c623381 feat/ingest; 8afc6bd-1279adf-9a23ecd-7537190-75c9283; 1279adf-dc5df93 feat/ingest-cleaner; dc5df93-7537190; HEAD=feat/ingest; reflog:9a23ecd,7537190,75c9283; title:A_plain_rebase_flattens_it; name:flattened id=flat

**[ANIMATION]** step: state-1

**`--rebase-merges`.** In one sentence: by default a rebase leaves merge commits out and lays all other commits out in one line. `--rebase-merges` rebuilds the branch structure, merge commits included. On screen: today's last demo branch, with its merge commit, `7537190`.

**[ANIMATION]** end

When not to use these? `--autostash` when the uncommitted change matters. The textbook's advice is to commit it as work in progress first, because a commit is in the reflog, Git's local list of where a branch has been, and an edit in the working tree is not. And `--rebase-merges`: first ask whether a branch that contains merges should be rebased at all. A long-lived integration branch that others pull from should not.

## MENTAL MODEL

**[ON SCREEN]** "Four options, one list. Each writes lines you could have written."

Keep the film editor's decision list from the last video. Today's four options are assistants who prepare the list before you see it.

**[ANIMATION]** cards: cards=--autosquash:reads_the_sticky_notes,_sorts_the_list|--autostash:clears_your_desk,_puts_it_back|--update-refs:relabels_every_can|--rebase-merges:cuts_two_storylines_that_join question=Four_assistants_prepare_the_list at_2=30 at_3=50 at_4=72

**[ANIMATION]** step: 4

The first assistant reads sticky notes on the takes, "this one fixes that one", and sorts the list accordingly. That's `--autosquash`. The second clears your desk before the session and puts everything back afterwards: `--autostash`. The third knows that three reels share footage, and relabels all three cans when the footage is re-cut: `--update-refs`. The fourth writes cutting instructions for a film with two storylines that join: `--rebase-merges`.

Where does the picture break? In the same place each time: an assistant does what the notes say, not what you meant. A sticky note on the wrong take folds a fix into the wrong commit. A can labelled "backup" that holds the same footage gets relabelled with the others. So the habit from the last video carries over: when it matters, add `-i` and read the list before it runs.

## DIAGRAM

**[ANIMATION]** step: stack.state-1

**[DIAGRAM]** Left: the stack before. Three branches, each built on the one below, and `main` one commit ahead. Right: after one rebase with `--update-refs`. Then, as an overlay, what a plain rebase would have produced: only the top label moved.

```text
Before                                          After "git rebase --update-refs main" on the top branch

  A---R                 main                      A---R                               main
   \                                                   \
    L1--L2              feat/ingest-loader              L1'--L2'                      feat/ingest-loader
          \                                                    \
           C1           feat/ingest-cleaner                     C1'                   feat/ingest-cleaner
             \                                                     \
              K1--K2    feat/ingest-chunker                         K1'--K2'          feat/ingest-chunker (HEAD)

Without --update-refs: only feat/ingest-chunker moves to K2'. The two lower branches stay on L2 and C1,
and the top branch then contains private copies (L1', L2', C1') of their work.
```

First, the stack before: three branches, each built on the one below, and `main` one commit ahead. A plain rebase of the top branch would move only the top label, and leave private copies of the lower work inside it.

**[ANIMATION]** step: stack.state-2

After one rebase with `--update-refs`, every commit is a new copy, marked with a prime, and all three labels sit on the copies. The originals turn dashed: only a reflog still names them.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/autosquash`. A three-commit branch, and three review comments.

**Part 1: fixup commits.**

<!-- snippet: ch09/autosquash/01-before -->
```text
$ git log --oneline --decorate
a25e84c (HEAD -> feat/metrics) Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

Review comment 1: `exact_match` must ignore surrounding whitespace. That belongs in the first commit.

<!-- snippet: ch09/autosquash/02-fixup-commit -->
```text
# Review comment 1: exact_match must ignore surrounding whitespace. That belongs in the first commit.
$ git diff
diff --git a/eval/metrics.py b/eval/metrics.py
index a82fda1..652e0e2 100644
--- a/eval/metrics.py
+++ b/eval/metrics.py
@@ -1,2 +1,2 @@
 def exact_match(pred, gold):
-    return pred == gold
+    return pred.strip() == gold.strip()
$ git commit -a --fixup=HEAD~2
[feat/metrics 2c37c8c] fixup! Add exact_match metric
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

`git commit --fixup=HEAD~2` wrote a commit whose subject is `fixup!` followed by the subject of its target. `HEAD~2` is two commits below HEAD, where you are: the first commit. Comment 2 gets a `--squash` commit with a note. And comment 3, which is only about a message, gets `--fixup=reword:`.

<!-- snippet: ch09/autosquash/03-squash-commit -->
```text
# Review comment 2: cover disjoint answers in the F1 test. That belongs in the last commit, with a note.
$ git commit -a --squash=HEAD~1 -m "Also covers the zero-overlap case."
[feat/metrics 02094a9] squash! Add token-level F1 metric
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch09/autosquash/04-amend-commit -->
```text
# Review comment 3: the message of "Test exact_match" should say what is tested. Only the message changes.
$ git commit --fixup=reword:HEAD~3
[feat/metrics eaf99b7] amend! Test exact_match
```
<!-- /snippet -->

<!-- snippet: ch09/autosquash/05-log -->
```text
$ git log --oneline --decorate
eaf99b7 (HEAD -> feat/metrics) amend! Test exact_match
02094a9 squash! Add token-level F1 metric
2c37c8c fixup! Add exact_match metric
a25e84c Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

`git rebase -i --autosquash main` 🟡 opens a todo list of six lines.

**[ANIMATION]** graph: 8afc6bd-143e55a-375df0b-a25e84c-2c37c8c-02094a9-eaf99b7 feat/metrics; 8afc6bd main; HEAD=feat/metrics; title:Three_commits,_three_corrections => 8afc6bd-143e55a-375df0b-a25e84c-2c37c8c-02094a9-eaf99b7 ORIG_HEAD; 8afc6bd-6b055fc-8c07d2a-7f88f67 feat/metrics; 8afc6bd main; HEAD=feat/metrics; reflog:143e55a,375df0b,a25e84c,2c37c8c,02094a9,eaf99b7; title:Six_commits_folded_into_three; say:git_diff_--stat_ORIG__HEAD_HEAD_prints_nothing:_the_same_tree id=squash

**[ANIMATION]** step: state-1

Six commits: three originals and, on top, three corrections in the order they were made. Try it now, on paper. Thirty seconds: write the six lines. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/autosquash/06-autosquash -->
```text
$ git rebase -i --autosquash main
--- todo list as Git opened it (comment lines removed) ---
pick 143e55a # Add exact_match metric
fixup 2c37c8c # fixup! Add exact_match metric
pick 375df0b # Test exact_match
fixup -C eaf99b7 # amend! Test exact_match # empty
pick a25e84c # Add token-level F1 metric
squash 02094a9 # squash! Add token-level F1 metric
--- todo list as saved ---
pick 143e55a # Add exact_match metric
fixup 2c37c8c # fixup! Add exact_match metric
pick 375df0b # Test exact_match
fixup -C eaf99b7 # amend! Test exact_match # empty
pick a25e84c # Add token-level F1 metric
squash 02094a9 # squash! Add token-level F1 metric
Rebasing (2/6)
Rebasing (3/6)
Rebasing (4/6)
Rebasing (5/6)
Rebasing (6/6)
[detached HEAD 7f88f67] Add token-level F1 metric
 Date: Mon Sep 7 10:05:00 2026 +0530
 2 files changed, 11 insertions(+)
 create mode 100644 eval/f1.py
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

The list arrives already arranged: every correction sits directly below its target, with the right instruction. `fixup` under the first commit. `fixup -C` under the second, with `# empty` marking the commit that carries only a message. `squash` under the third. The editor opens once, for the `squash`.

<!-- snippet: ch09/autosquash/07-after -->
```text
$ git log --oneline --decorate
7f88f67 (HEAD -> feat/metrics) Add token-level F1 metric
8c07d2a Test exact_match on identical strings
6b055fc Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git log -1 --format=%B
Add token-level F1 metric

Tested on identical and on disjoint answers.

$ git diff --stat ORIG_HEAD HEAD
```
<!-- /snippet -->

Three commits again, with the corrected messages.

**[ANIMATION]** step: squash.state-2

And the last command, a diff from `ORIG_HEAD`, the old tip, to HEAD, prints nothing: the tree at the tip is identical before and after. Autosquash changes how the history is cut into commits, not what the branch contains.

**[ANIMATION]** end

Without `-i` the list isn't shown at all.

<!-- snippet: ch09/autosquash/08-non-interactive -->
```text
# One more fix, this time without opening the todo list at all.
$ git commit -a --fixup=HEAD
[feat/metrics 06c9467] fixup! Add token-level F1 metric
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git rebase --autosquash main
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
dc93e0c (HEAD -> feat/metrics) Add token-level F1 metric
8c07d2a Test exact_match on identical strings
6b055fc Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

One trap in the configuration. `labs/run ch09/autosquash-config`. `rebase.autoSquash` exists so that you need not type the option. Predict what a plain `git rebase main` does with a `fixup!` commit on the branch. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/autosquash-config/01-config-and-plain-rebase -->
```text
$ git config set rebase.autoSquash true
$ git log --oneline --decorate
028ba01 (HEAD -> feat/metrics) fixup! Add exact_match metric
a25e84c Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git rebase main
Current branch feat/metrics is up to date.
$ git log --oneline --decorate -1
028ba01 (HEAD -> feat/metrics) fixup! Add exact_match metric
```
<!-- /snippet -->

"Up to date", and the `fixup!` commit is still there. Almost everyone expects a fold here the first time. Root cause, from the textbook: the setting applies to interactive rebases only. The manual says "by default for interactive mode". A plain rebase of a branch that is already on top of `main` has nothing to do. Type `--autosquash`, or use `-i`.

<!-- snippet: ch09/autosquash-config/02-interactive-honours-it -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 143e55a # Add exact_match metric
fixup 028ba01 # fixup! Add exact_match metric
pick 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
--- todo list as saved ---
pick 143e55a # Add exact_match metric
fixup 028ba01 # fixup! Add exact_match metric
pick 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
862cc90 (HEAD -> feat/metrics) Add token-level F1 metric
2049ba1 Test exact_match
f7171b1 Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

**Part 2: autostash.** `labs/run ch09/autostash`.

<!-- snippet: ch09/autostash/01-dirty -->
```text
# An uncommitted experiment in the working tree:
$ git status --short
 M app/rerank.py
$ git rebase main
error: cannot rebase: You have unstaged changes.
error: Please commit or stash them.
[exit status: 1]
```
<!-- /snippet -->

"Cannot rebase: You have unstaged changes."

<!-- snippet: ch09/autostash/02-autostash -->
```text
$ git rebase --autostash main
Created autostash: 855c10e
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Applied autostash.
Successfully rebased and updated refs/heads/feat/rerank.
$ git status --short
 M app/rerank.py
$ git stash list
```
<!-- /snippet -->

"Created autostash", three picks, "Applied autostash". The edit is back in the working tree, and the stash list is empty.

So where is your change while a rebase is stopped at a conflict, waiting for you to decide a file's content? `labs/run ch09/autostash-stopped`. Quick quiz, three options: in your files, on the stash list, or neither? Say it out loud.

**[PAUSE]**

<!-- snippet: ch09/autostash-stopped/02-where-is-it -->
```text
$ git status --short
UU app/retriever.py
$ git stash list
$ cat .git/rebase-merge/autostash
a73072956efd7f13df50384c97d52782d1dc32af
$ git stash show -p $(cat .git/rebase-merge/autostash)
diff --git a/config/model.yaml b/config/model.yaml
index 2d94ebc..d0061c7 100644
--- a/config/model.yaml
+++ b/config/model.yaml
@@ -2,3 +2,4 @@ model: small-v1
 temperature: 0.2
 max_tokens: 512
 rerank: true
+top_p: 0.9
```
<!-- /snippet -->

Neither. It's in no file of the working tree, and not on the stash list. Its ID is in `.git/rebase-merge/autostash`, and `git stash show -p` on that ID prints your edit. The two ways out treat it differently.

<!-- snippet: ch09/autostash-stopped/03-abort -->
```text
$ git rebase --abort
Applied autostash.
$ git status --short
 M config/model.yaml
```
<!-- /snippet -->

`--abort` 🟡, which discards resolution work in progress as you saw in video 53, applies the autostash: the edit is back.

<!-- snippet: ch09/autostash-stopped/04-quit -->
```text
# The same stop again. This time the rebase is left with --quit.
$ git rebase --quit
Autostash exists; creating a new stash entry.
Your changes are safe in the stash.
You can run "git stash pop" or "git stash drop" at any time.
$ git stash list
stash@{0}: autostash
$ git status --short
UU app/retriever.py
```
<!-- /snippet -->

`--quit` creates a stash entry and says so: "Your changes are safe in the stash." Now it's on the list, and the conflict is still in the working tree.

The last step can itself conflict, when the rebase brought in a change to the lines you had edited. Back to `ch09/autostash`.

<!-- snippet: ch09/autostash/03-conflict-setup -->
```text
# main gained a commit that rewrites the README sentence. You have an uncommitted edit to the same sentence.
$ git status --short
 M README.md
$ git rebase --autostash main
Created autostash: 946f166
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Your local changes are stashed, however applying them
resulted in conflicts.  You can either resolve the conflicts
and then discard the stash with "git stash drop", or, if you
do not want to resolve them now, run "git reset --hard" and
apply the local changes later by running "git stash pop".
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

Read the last line of the rebase output first: the rebase succeeded and the branch has moved. What conflicted is the stash application afterwards.

<!-- snippet: ch09/autostash/04-conflict-state -->
```text
$ git status --short
UU README.md
$ git stash list
stash@{0}: autostash
$ cat README.md
# ragkit

<<<<<<< Updated upstream
Retrieval-augmented answering service with reranking.
=======
Retrieval-augmented answering service (internal).
>>>>>>> Stashed changes
$ git log --oneline --decorate -2
20835dd (HEAD -> feat/rerank) Enable reranking in config
c994617 Call reranker from retriever
```
<!-- /snippet -->

Git kept the stash on the list, and the markers are labelled `Updated upstream`, the rebased branch, and `Stashed changes`, your edit. Resolve the file, then `git stash drop` 🔴, as in the stash video: only once the content is safely on disk.

**Part 3: a stack and `--update-refs`.** `labs/run ch09/update-refs`.

<!-- snippet: ch09/update-refs/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 9cfa98f (main) Add README
| * e86ad55 (HEAD -> feat/ingest-chunker) Make chunk size configurable
| * f3f4739 Add chunker
| * b10b821 (feat/ingest-cleaner) Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

**[ANIMATION]** graph: 8afc6bd-9cfa98f main; 8afc6bd-531d3da-7fea52c feat/ingest-loader; 7fea52c-b10b821 feat/ingest-cleaner; b10b821-f3f4739-e86ad55 feat/ingest-chunker; HEAD=feat/ingest-chunker; title:A_plain_rebase_of_the_top_branch => 9cfa98f-8e64e59-8b13775-477c93c-59e5878-a30ab1a feat/ingest-chunker; 9cfa98f main; 8afc6bd-531d3da-7fea52c feat/ingest-loader; 7fea52c-b10b821 feat/ingest-cleaner; b10b821-f3f4739-e86ad55; HEAD=feat/ingest-chunker; reflog:f3f4739,e86ad55 id=plain

**[ANIMATION]** step: state-1

Three branch labels on one line of five commits: the stack from the opening, with real IDs. First a plain rebase of the top branch. Predict which labels move. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/update-refs/02-without -->
```text
$ git rebase main
Rebasing (1/5)
Rebasing (2/5)
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
$ git log --oneline --graph --decorate --all
* a30ab1a (HEAD -> feat/ingest-chunker) Make chunk size configurable
* 59e5878 Add chunker
* 477c93c Add text cleaner
* 8b13775 Close files after loading
* 8e64e59 Add document loader
* 9cfa98f (main) Add README
| * b10b821 (feat/ingest-cleaner) Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

**[ANIMATION]** step: plain.state-2

Only `feat/ingest-chunker` moved. The two lower branches still point at the old commits, and the top branch now contains private copies of their work. That's the state from the opening. Now, after going back to the start, with the option.

<!-- snippet: ch09/update-refs/04-with -->
```text
$ git rebase -i --update-refs main
--- todo list as Git opened it (comment lines removed) ---
pick 531d3da # Add document loader
pick 7fea52c # Close files after loading
update-ref refs/heads/feat/ingest-loader
pick b10b821 # Add text cleaner
update-ref refs/heads/feat/ingest-cleaner
pick f3f4739 # Add chunker
pick e86ad55 # Make chunk size configurable
--- todo list as saved ---
pick 531d3da # Add document loader
pick 7fea52c # Close files after loading
update-ref refs/heads/feat/ingest-loader
pick b10b821 # Add text cleaner
update-ref refs/heads/feat/ingest-cleaner
pick f3f4739 # Add chunker
pick e86ad55 # Make chunk size configurable
Rebasing (1/7)
Rebasing (2/7)
Rebasing (3/7)
Rebasing (4/7)
Rebasing (5/7)
Rebasing (6/7)
Rebasing (7/7)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
Updated the following refs with --update-refs:
	refs/heads/feat/ingest-cleaner
	refs/heads/feat/ingest-loader
```
<!-- /snippet -->

Two `update-ref` lines in the list, each directly after the commit its branch points at. A ref is Git's word for a name such as a branch. And at the end: "Updated the following refs with --update-refs", with both lower branches named.

<!-- snippet: ch09/update-refs/05-after -->
```text
$ git log --oneline --graph --decorate --all
* 4b52940 (HEAD -> feat/ingest-chunker) Make chunk size configurable
* c439cc8 Add chunker
* 06c29f9 (feat/ingest-cleaner) Add text cleaner
* 1599a67 (feat/ingest-loader) Close files after loading
* eed2aa8 Add document loader
* 9cfa98f (main) Add README
* 8afc6bd Add retriever and model config
$ git reflog show feat/ingest-loader -2
1599a67 feat/ingest-loader@{0}: rewritten during rebase
7fea52c feat/ingest-loader@{1}: commit: Close files after loading
```
<!-- /snippet -->

One line, and all three labels on the new commits. The reflog of a moved branch says "rewritten during rebase", and its `@{1}`, the value one change ago, is the old commit.

**[ANIMATION]** graph: 8afc6bd-9cfa98f main; 9cfa98f-eed2aa8-1599a67 feat/ingest-loader; 1599a67-06c29f9 feat/ingest-cleaner; 06c29f9-c439cc8-4b52940 feat/ingest-chunker; HEAD=feat/ingest-chunker; title:The_same_stack,_with_--update-refs => + 4b52940 backup/chunker tag:before-rebase; title:A_backup_branch_and_a_tag_at_the_tip => + 9cfa98f-*1 main; *1-*2-*3 feat/ingest-loader; *3-*4 feat/ingest-cleaner; *4-*5-2925218 feat/ingest-chunker backup/chunker; title:The_branch_moved,_the_tag_stayed id=trap

**[ANIMATION]** step: state-2

Now the assistant doing what the labels say. You make a "backup" branch and a tag at the tip before a risky rebase. Predict what each points at afterwards.

**[PAUSE]**

<!-- snippet: ch09/update-refs/06-backup-trap -->
```text
# A "backup" branch that points into the range is a branch like any other:
$ git branch backup/chunker
$ git tag before-rebase
$ git rebase --update-refs main
Rebasing (1/8)
Rebasing (2/8)
Rebasing (3/8)
Rebasing (4/8)
Rebasing (5/8)
Rebasing (6/8)
Rebasing (7/8)
Rebasing (8/8)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
Updated the following refs with --update-refs:
	refs/heads/backup/chunker
	refs/heads/feat/ingest-cleaner
	refs/heads/feat/ingest-loader
$ git log --oneline --decorate -1 backup/chunker
2925218 (HEAD -> feat/ingest-chunker, backup/chunker) Make chunk size configurable
$ git log --oneline --decorate -1 before-rebase
4b52940 (tag: before-rebase) Make chunk size configurable
```
<!-- /snippet -->

`backup/chunker` is in the list of updated refs. It now points at the new tip, `2925218`. It no longer backs anything up. The tag stayed on `4b52940`.

**[ANIMATION]** step: trap.state-3

Root cause: a "backup" made with `git branch` is a branch that points into the rebased range, so `--update-refs` moved it along with the others. Before a risky rebase, mark the old tip with a tag, or write down the ID, or rely on the reflog.

**[ANIMATION]** end

The undo is also per branch. `git reset --hard ORIG_HEAD` 🔴 restores the branch you're on. Each of the others has to be put back from its own reflog.

Publishing is per branch as well, in one command. `labs/run ch09/update-refs-push`. A forced push 🔴, one that replaces commits on the server's branch. The five answers were given in the video on forcing a push, and the two guards are on.

<!-- snippet: ch09/update-refs-push/03-push-the-stack -->
```text
$ git push --force-with-lease --force-if-includes origin feat/ingest-loader feat/ingest-cleaner feat/ingest-chunker
To ../server.git
 + 31e0e7e...82bd9b8 feat/ingest-chunker -> feat/ingest-chunker (forced update)
 + b10b821...3616f79 feat/ingest-cleaner -> feat/ingest-cleaner (forced update)
 + 7fea52c...129c95a feat/ingest-loader -> feat/ingest-loader (forced update)
```
<!-- /snippet -->

Three "(forced update)" lines. Every ref gets its own lease.

**Part 4: merges.** `labs/run ch09/rebase-merges`. `feat/ingest` contains a merge of a side branch.

<!-- snippet: ch09/rebase-merges/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 9cfa98f (main) Add README
| * 75c9283 (HEAD -> feat/ingest) Wire loader, cleaner and chunker together
| *   7537190 Merge branch 'feat/ingest-cleaner' into feat/ingest
| |\  
| | * dc5df93 (feat/ingest-cleaner) Add text cleaner
| * | 9a23ecd Add chunker
| |/  
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Predict the shape of the branch after a plain `git rebase main`.

**[PAUSE]**

<!-- snippet: ch09/rebase-merges/02-flattened -->
```text
$ git rebase main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate feat/ingest
* c623381 (HEAD -> feat/ingest) Wire loader, cleaner and chunker together
* f4b3cef Add text cleaner
* 043ec63 Add chunker
* a10544a Add document loader
* 9cfa98f (main) Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Four commits in a line, and the merge commit is gone.

**[ANIMATION]** step: flat.flattened

Whatever existed only in the merge commit, such as a conflict resolution or a fix made while merging, is not replayed. So the conflict it resolved comes back at one of the single commits. Now with `-r`, after going back.

<!-- snippet: ch09/rebase-merges/04-rebase-merges -->
```text
$ git rebase -i --rebase-merges main
--- todo list as Git opened it (comment lines removed) ---
label onto
reset onto
pick 1279adf # Add document loader
label branch-point
pick dc5df93 # Add text cleaner
label feat-ingest-cleaner
reset branch-point # Add document loader
pick 9a23ecd # Add chunker
merge -C 7537190 feat-ingest-cleaner # Merge branch 'feat/ingest-cleaner' into feat/ingest
pick 75c9283 # Wire loader, cleaner and chunker together
--- todo list as saved ---
label onto
reset onto
pick 1279adf # Add document loader
label branch-point
pick dc5df93 # Add text cleaner
label feat-ingest-cleaner
reset branch-point # Add document loader
pick 9a23ecd # Add chunker
merge -C 7537190 feat-ingest-cleaner # Merge branch 'feat/ingest-cleaner' into feat/ingest
pick 75c9283 # Wire loader, cleaner and chunker together
Rebasing (1/10)
Rebasing (2/10)
Rebasing (3/10)
Rebasing (4/10)
Rebasing (5/10)
Rebasing (6/10)
Rebasing (7/10)
Rebasing (8/10)
Rebasing (9/10)
Rebasing (10/10)
Successfully rebased and updated refs/heads/feat/ingest.
```
<!-- /snippet -->

The list has become a small graph program. Read it line by line. `label onto` names the new base. `reset onto` moves HEAD there. After the first pick, `label branch-point` remembers where the side branch forks. The side commit is picked and labelled.

Then `reset branch-point` goes back, the mainline commit is picked, and `merge -C 7537190 feat-ingest-cleaner` makes a new merge with the message of the old one. Labels are temporary refs under `refs/rewritten/`, deleted when the rebase ends.

<!-- snippet: ch09/rebase-merges/05-after -->
```text
$ git log --oneline --graph --decorate --all
* a52bef6 (HEAD -> feat/ingest) Wire loader, cleaner and chunker together
*   5fff212 Merge branch 'feat/ingest-cleaner' into feat/ingest
|\  
| * 3452235 Add text cleaner
* | 7187f81 Add chunker
|/  
* 8cf8070 Add document loader
* 9cfa98f (main) Add README
| * dc5df93 (feat/ingest-cleaner) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

The diamond is back, on top of `main`.

**[ANIMATION]** graph: 8afc6bd-9cfa98f main; 8afc6bd-1279adf-9a23ecd-7537190-75c9283 feat/ingest; 1279adf-dc5df93 feat/ingest-cleaner; dc5df93-7537190; HEAD=feat/ingest; title:The_same_branch,_with_--rebase-merges; name:before => 8afc6bd-9cfa98f main; 9cfa98f-8cf8070-7187f81-5fff212-a52bef6 feat/ingest; ^8cf8070-3452235; 3452235-5fff212; 8afc6bd-1279adf-9a23ecd-7537190-75c9283; 1279adf-dc5df93 feat/ingest-cleaner; dc5df93-7537190; HEAD=feat/ingest; reflog:9a23ecd,7537190,75c9283; title:The_diamond_is_rebuilt_on_main id=rm

Two details. First, the branch `feat/ingest-cleaner` still points at the old commit `dc5df93`. `-r` rebuilds commits, it doesn't move other branches. Add `--update-refs` for that. Second, the new merge is a fresh merge. The manual states that conflict resolutions and manual amendments in the original merge commits have to be redone by hand.

<!-- snippet: ch09/rebase-merges/06-preserve-merges -->
```text
$ git rebase --preserve-merges main
fatal: --preserve-merges was replaced by --rebase-merges
Note: Your `pull.rebase` configuration may also be set to 'preserve',
which is no longer supported; use 'merges' instead
[exit status: 128]
```
<!-- /snippet -->

The textbook marks this as outdated advice: `git rebase -p` or `--preserve-merges`, and `pull.rebase=preserve`, appear in older tutorials. The option was deprecated in Git 2.22 and removed in 2.34. Git 2.55 answers with the fatal message on screen. Use `--rebase-merges` and `pull.rebase=merges`.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Setting `rebase.autoSquash` and expecting a plain `git rebase main` to fold fixups.** Root cause: the setting applies to interactive mode only, and a branch already on top of `main` has nothing to replay.
2. **Looking for autostashed work in `git stash list` during a stopped rebase.** Root cause: the autostash is a stash commit recorded in the state directory, put on the list only by `--quit` or when applying it conflicts.
3. **Making a safety copy with `git branch` before a rebase with `--update-refs`.** Root cause: a branch that points into the range is moved with the others; a tag is not.
4. **Undoing a stack rebase with one `git reset --hard ORIG_HEAD`.** Root cause: `ORIG_HEAD` restores only the current branch; every other moved branch has its own reflog.
5. **Expecting `--rebase-merges` to keep an old merge's conflict resolution.** Root cause: the merge is made afresh, and resolutions or amendments in the original merge commit have to be redone.

## PRODUCTION EXAMPLE

Now, out of the lab. Two practices from the textbook, both from teams that review in small pieces.

During a review, answer each comment with a fixup commit and push normally. The reviewer sees every response as a small diff, and nothing is force-pushed meanwhile. Before the merge, one `git rebase -i --autosquash` and one force push fold everything. A CI job, an automated check, that fails while a subject starts with `fixup!`, `squash!` or `amend!` keeps unfolded corrections out of `main`. The check in Lab 9.3 is one line of `git log --grep`.

**[ANIMATION]** step: stack.state-2

And the stack from the opening? A large change reviewed as a chain of small pull requests lives or dies by `--update-refs`, because every review fix in the lowest branch has to ripple upward. `git config set rebase.updateRefs true` makes it the default. Now count again. The three rebases and three pushes of the opening become one rebase on the top branch, and one push that names three branches.

**[ANIMATION]** step: stash.2

On autostash, a caution. `rebase.autoStash=true` makes it the default, and `git pull --rebase --autostash` does the same for pulls. The cost is that uncommitted work travels through a mechanism you don't see.

## PRACTICE EXERCISE

Your turn. Do Lab 9.3, "Autosquash fixups", in [`lab-manual/m09-rebase.md`](../../lab-manual/m09-rebase.md).

Predict before you run the rebase:

- The subject line of each correction commit you create.
- The todo list that `--autosquash` will open, line by line, with the verbs.
- The output of `git diff --stat` between the old tip and the new tip. Think about why.

The challenge is Lab 9.7, "`--update-refs` on stacked branches", in the same file. Before the rebase there, list every local branch that points into the range, including any you didn't think of as part of the stack.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q158: "What do `--update-refs` and `--rebase-merges` each add to a plain rebase, and what does each still leave for you to do?"

**[PAUSE]**

Answer out loud first. The question has four cells: two options, and for each "adds" and "leaves". A strong answer starts from what a plain rebase does in each situation, so that the addition is a contrast and not a slogan. For "leaves", think along three lines. Which refs are not moved. What is not carried over from the old history. And what publishing and undoing then require. An answer that fills all four cells from the todo list itself, naming the lines each option writes, is a senior answer.

## RECAP

Let's land this. You should now be able to say:

A fixup commit is an ordinary commit whose subject names its target, and `--autosquash` places it under that target in the todo list. The configuration setting covers interactive rebases only.

**[ANIMATION]** step: stash.4

`--autostash` parks uncommitted changes in a stash commit that is recorded in the state directory, applied at the end or on abort, and moved to the stash list by `--quit` or by a conflict.

**[ANIMATION]** replay: stack

`--update-refs` moves every local branch that points into the replayed range, including a branch meant as a backup, and undo and publishing are per branch.

**[ANIMATION]** replay: rm

A plain rebase flattens merges. `--rebase-merges` rebuilds them with `label`, `reset` and `merge` lines, as fresh merges. `--preserve-merges` was removed.

## HOMEWORK

Read sections 9.7 to 9.10 of [Chapter 9](../../textbook/ch09-rebase.md).

Do Exercise 9.2, Level 1, "fold a fix into the commit it belongs to", and Exercise 9.6, Level 2, "a merge inside the branch", both in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Today you let four assistants write the todo list, and you know what each one leaves for you. Practise the fixup lab before the next video. Next time: conflicts during a rebase, who "ours" is, and the ways out. Until then, look at the state first and type second. See you in the next one.

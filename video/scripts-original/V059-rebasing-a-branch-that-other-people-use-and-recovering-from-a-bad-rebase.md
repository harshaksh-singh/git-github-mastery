# V059: Rebasing a branch that other people use, and recovering from a bad rebase

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 24
- **Prerequisites:** V058
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), sections 9.15 and 9.16
- **Demo scripts:** `labs/ch09/shared-rebase.sh`, `labs/ch09/recover.sh`

## HOOK

**[ON SCREEN]** "Why does the history of the ingest branch contain every commit twice?"

The CTO is looking at a branch. "Add document loader" appears in it twice, with two different IDs. So does "Add text cleaner". There is a merge commit on top that nobody remembers wanting.

Two engineers were involved. One rebased the branch and force-pushed it, with a lease, exactly as the documentation recommends. The other fetched, read what `git status` suggested, and followed the suggestion. Each did something reasonable. Together they produced a history in which every change is recorded twice.

You are going to play both roles, watch the duplication happen, and then repair it. After that you break a branch on your own, lose the obvious way back, and recover it anyway.

## INTRODUCTION

Every tutorial has the sentence "never rebase a public branch". You have probably repeated it. Today you replace the slogan with the mechanism, so that you can also say when the rule does not apply and what to do after someone has broken it.

The mechanism is the one from the first video of this module: a rebase copies. After you rebase and publish, your clone and the server hold the copies. Your colleague's clone still holds the originals, with her own work on top. Git identifies commits by ID. To Git, the copies and the originals are unrelated commits that happen to make the same changes.

The second half of the video is about your own mistakes. A rebase destroys nothing. There are three handles on the old state, and they differ in how long they last. You will see the shortest-lived one fail and the most durable one save the branch.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Explain how a teammate ends up with every commit twice after a shared branch was rebased.
- Repair the teammate's branch without losing their own commit.
- Recover the pre-rebase state through `ORIG_HEAD` and through the reflog, and say when the first fails.
- State the rule about published history as a consequence, not as a slogan.

## CONCEPT

**Section 9.15, in one sentence.** If you rebase a branch that someone else has built on and publish the result, their clone holds the old commits, the server holds the new ones, and Git sees two separate lines of history that happen to make the same changes.

Follow it step by step. Before: you pushed commits L and C. Your teammate fetched them and committed K on top. You rebase: L and C become L-prime and C-prime, on a new base. You force-push: the server now has L-prime and C-prime. Her clone has L, C, K. When she fetches, her branch and its upstream have diverged. If she merges, the merge keeps the commits of both sides: L, C, K, and L-prime, C-prime. Every change twice.

The root cause, as the textbook states it: Git identifies a commit by its ID. Your copies have new IDs, so for Git they are different commits from the originals, and a merge keeps the commits of both sides.

Is the content duplicated? No. The merge's diff is small, because both lines make the same changes. The history is duplicated.

Why is that more than noise? Every later reader of the history meets each change twice. Worse: if she pushes her merge, the commits you removed are back on the server. When the purpose of the rewrite was to remove something, a credential or a large file, one stale clone that merges and pushes undoes the cleanup.

The repair is on her side: go back to before the merge, then replay only her own commit onto the new upstream.

Now the rule. Pro Git states it as: "Do not rebase commits that exist outside your repository and that people may have based work on." The textbook gives it a working form, a question to ask before you rebase anything you have pushed: who else has commits on top of this? Nobody, as on the branch of your own pull request: rebase and publish. Somebody: agree on it first and send them the repair command, or do not rebase; merge instead.

**Section 9.16, in one sentence.** A rebase destroys nothing: the old tip is named by `ORIG_HEAD` until another command overwrites that ref, and by the reflog of the branch for weeks.

**[ON SCREEN]** The three handles.

```text
Handle                                   Usable                             Caveat
---------------------------------------  ---------------------------------  ---------------------------------------------------------
git rebase --abort                       While the rebase is in progress    Discards resolution work done so far
ORIG_HEAD                                Directly after the rebase          Rewritten by the next git reset, git merge, git rebase
                                                                            or git am
<branch>@{n}, the reflog of the branch   Until the entry expires            One entry per rebase, so count in the listing; a deleted
                                                                            branch has no reflog
```

How long is "until the entry expires"? The textbook gives the defaults: a reflog entry whose commit is no longer reachable from the branch tip, which is what a rebase leaves behind, expires after 30 days, and the unreachable objects are pruned after a further two weeks. The lab configuration sets the reflog never to expire, so the transcripts do not depend on the date.

## MENTAL MODEL

**[ON SCREEN]** "Reprinted chapters, stapled twice."

The textbook's analogy: you reprint chapters 1 and 2 of a shared manuscript with corrections and replace the copies in the office. Your co-author is at home with chapter 3 stapled to the old chapters 1 and 2. If she staples the new print on as well, the manuscript contains chapters 1 and 2 twice.

It breaks at one point: a person would recognise the duplicate text. Git, which identifies commits by ID, does not, unless you ask it to compare patches. That "unless" is the tool for diagnosis: `--cherry-mark` compares patch IDs and marks the pairs.

For recovery, the model is a ladder with three rungs, and each rung lasts longer than the one above it. `--abort` exists only during the rebase. `ORIG_HEAD` exists until the next command that writes it. The reflog entry exists for weeks. When a rung is gone, step down to the next.

## DIAGRAM

**[DIAGRAM]** Three boxes: your clone, the server, Asha's clone. First the legend. Then fill your box and push to the server. Then her box, with the two refs that have diverged. Last, the line about her merge.

```text
L = Add document loader   C = Add text cleaner   K = Add chunker   R = Add README   ' = copy made by your rebase

      you/                       server.git                    asha/
 +------------------+       +------------------+       +---------------------------------+
 | feat/ingest      | push  | feat/ingest      | fetch | origin/feat/ingest   A-R-L'-C'  |
 |   A-R-L'-C'      | ----> |   A-R-L'-C'      | ----> | feat/ingest          A-L-C-K    |
 | reflog: A-L-C    | forced| (L and C gone)   |       | after her merge: both lines     |
 +------------------+       +------------------+       +---------------------------------+
```

Three repositories, and after your push the originals L and C exist as branch history in exactly one of them: hers.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/shared-rebase`. A bare repository plays the server; `you/` and `asha/` are two clones. You pushed two commits to `feat/ingest`. Asha fetched them and committed "Add chunker" on top, not yet pushed.

**Part 1: you rebase and publish.**

<!-- snippet: ch09/shared-rebase/01-you-rebase -->
```text
$ git log --oneline --graph --decorate --all
* 589d18b (origin/main, main) Add README
| * dc5df93 (HEAD -> feat/ingest, origin/feat/ingest) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
```
<!-- /snippet -->

`git rebase main` 🟡 CAUTION. Two commits replayed. Then a plain push.

<!-- snippet: ch09/shared-rebase/02-you-push -->
```text
$ git push
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease --force-if-includes
To ../server.git
 + dc5df93...8aca274 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

Rejected, non-fast-forward: the server's tip is not an ancestor of yours. Read the hint: it recommends `git pull`. After a rebase of your own that advice is wrong. A pull would bring the old commits back, merged next to your copies or, with `--rebase`, in place of them.

The second command is a forced push 🔴 DANGEROUS, with both guards. The five answers are in the video on forcing a push. The one that matters most today is "what can it destroy": every commit on the server's branch that is not in your history. Here that is your own two originals, and you meant to replace them. What you did not check is who else had built on them.

**Part 2: in Asha's clone.**

<!-- snippet: ch09/shared-rebase/03-asha-before -->
```text
$ cd ../asha
$ git log --oneline --graph --decorate --all
* c60bc13 (HEAD -> feat/ingest) Add chunker
* dc5df93 (origin/feat/ingest) Add text cleaner
* 1279adf Add document loader
* 8afc6bd (origin/main, origin/HEAD, main) Add retriever and model config
```
<!-- /snippet -->

Her branch: `1279adf`, `dc5df93`, and her own `c60bc13` on top.

<!-- snippet: ch09/shared-rebase/04-asha-fetch -->
```text
$ git fetch
From ../server
 + dc5df93...8aca274 feat/ingest -> origin/feat/ingest  (forced update)
   8afc6bd..589d18b  main        -> origin/main
$ git status
On branch feat/ingest
Your branch and 'origin/feat/ingest' have diverged,
and have 3 and 3 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```
<!-- /snippet -->

"(forced update)" on the fetch line. And status: diverged, "3 and 3 different commits each". Her side has the two old commits and her own. The other side has the README commit and the two copies. Status suggests `git pull`. She does it, with a merge. Predict the graph.

**[PAUSE]**

<!-- snippet: ch09/shared-rebase/05-asha-merges -->
```text
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 README.md | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
$ git log --oneline --graph --decorate
*   f0c9542 (HEAD -> feat/ingest) Merge branch 'feat/ingest' of ../server into feat/ingest
|\  
| * 8aca274 (origin/feat/ingest) Add text cleaner
| * 0fbfd81 Add document loader
| * 589d18b (origin/main, origin/HEAD) Add README
* | c60bc13 Add chunker
* | dc5df93 Add text cleaner
* | 1279adf Add document loader
|/  
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

Two parallel lines joined by a merge. "Add document loader" on the left as `1279adf` and on the right as `0fbfd81`. "Add text cleaner" as `dc5df93` and as `8aca274`.

<!-- snippet: ch09/shared-rebase/06-duplicates -->
```text
$ git log --oneline --left-right --cherry-mark ORIG_HEAD...origin/feat/ingest
= 8aca274 Add text cleaner
= 0fbfd81 Add document loader
> 589d18b Add README
< c60bc13 Add chunker
= dc5df93 Add text cleaner
= 1279adf Add document loader
$ git diff --stat ORIG_HEAD HEAD
 README.md | 3 +++
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

`--cherry-mark` puts an equals sign on four commits: two pairs with the same patch. Her own commit is marked with a less-than sign and the README with a greater-than sign. And the diff from before the merge to after it shows one file, the README: the content is not duplicated, the history is.

**Part 3: the repair, on her side.** Go back to before the merge with `git reset --hard ORIG_HEAD` 🔴. It is the very next state-changing command after the merge, her tree is clean, and the merge has not been pushed. Then replay only her own commit.

<!-- snippet: ch09/shared-rebase/07-repair -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at c60bc13 Add chunker
$ git merge-base --fork-point origin/feat/ingest feat/ingest
dc5df9356273e7c0c2807ce808c378782ea2525a
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate
* fbce73d (HEAD -> feat/ingest) Add chunker
* 8aca274 (origin/feat/ingest) Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

Look at the middle command. `git merge-base --fork-point` looks into the reflog of `origin/feat/ingest`, finds that her branch left that remote-tracking branch when its tip was `dc5df93`, and so identifies "Add chunker" as the only commit that is hers. `git pull --rebase` uses the same logic: one commit replayed. Her chunker, now `fbce73d`, sits on top of your two copies. One line, nothing twice.

You saw this fork-point logic do harm in the video on forced pushes, where it dropped a commit the teammate had pushed. Here it does good, because her commit was never pushed. Same rule, different history. The explicit form, `git rebase --onto origin/feat/ingest dc5df93`, is in Lab 9.6.

**Part 4: your own bad rebase.** `labs/run ch09/recover`. The plan was to drop two experiment commits. The wrong lines were deleted from the todo list.

<!-- snippet: ch09/recover/01-bad-rebase -->
```text
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
# The plan was to drop the two experiment commits. The wrong lines were deleted from the todo list.
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 5ee19f0 # Add reranker skeleton
pick 195f8d0 # Experiment: cross-encoder scoring
pick e30ba74 # Experiment: cache cross-encoder scores
pick 45f4f23 # Call reranker from retriever
pick 6ab8f55 # Enable reranking in config
--- todo list as saved ---
pick 5ee19f0 # Add reranker skeleton
pick 195f8d0 # Experiment: cross-encoder scoring
pick e30ba74 # Experiment: cache cross-encoder scores
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --decorate
e30ba74 (HEAD -> feat/rerank) Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

The saved list has three lines: the skeleton and the two experiments. The two commits you wanted to keep are gone, and Git said nothing. Noticed at once, the undo is one command.

`git reset --hard ORIG_HEAD` 🔴. From the textbook: it moves the current branch to that commit and overwrites the index and the working tree with it. It destroys uncommitted changes to tracked files. Preview with `git status`, which should be clean, as it is after a finished rebase, and `git diff ORIG_HEAD HEAD`. What it moves away from stays recoverable: the rebased tip is now `<branch>@{1}`.

<!-- snippet: ch09/recover/02-orig-head -->
```text
$ git rev-parse --short ORIG_HEAD
6ab8f55
$ git reset --hard ORIG_HEAD
HEAD is now at 6ab8f55 Enable reranking in config
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

Five commits again. Now the same mistake, not noticed, followed by a reset for another reason. Predict what `ORIG_HEAD` names afterwards.

**[PAUSE]**

<!-- snippet: ch09/recover/03-orig-head-overwritten -->
```text
# The same bad rebase again. This time you do not notice, and remove one more commit with a reset:
$ git reset --hard HEAD~1
HEAD is now at 195f8d0 Experiment: cross-encoder scoring
$ git log --oneline --decorate
195f8d0 (HEAD -> feat/rerank) Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
$ git rev-parse --short ORIG_HEAD
e30ba74
```
<!-- /snippet -->

`e30ba74`: the tip before the reset, which is the damaged branch. The first rung is gone, the second has been overwritten. Step down to the third.

<!-- snippet: ch09/recover/04-reflog -->
```text
$ git reflog show feat/rerank
195f8d0 feat/rerank@{0}: reset: moving to HEAD~1
e30ba74 feat/rerank@{1}: rebase (finish): refs/heads/feat/rerank onto 8afc6bd28c2572af09f1b6c37d733535230e526f
6ab8f55 feat/rerank@{2}: reset: moving to ORIG_HEAD
e30ba74 feat/rerank@{3}: rebase (finish): refs/heads/feat/rerank onto 8afc6bd28c2572af09f1b6c37d733535230e526f
6ab8f55 feat/rerank@{4}: commit: Enable reranking in config
45f4f23 feat/rerank@{5}: commit: Call reranker from retriever
e30ba74 feat/rerank@{6}: commit: Experiment: cache cross-encoder scores
195f8d0 feat/rerank@{7}: commit: Experiment: cross-encoder scoring
5ee19f0 feat/rerank@{8}: commit: Add reranker skeleton
8afc6bd feat/rerank@{9}: branch: Created from HEAD
```
<!-- /snippet -->

Read it from the top: a reset; the second bad rebase; the reset to `ORIG_HEAD`; the first bad rebase; and below that the five original commits. Which entry is the last good state?

**[PAUSE]**

`feat/rerank@{2}`: `6ab8f55`, "reset: moving to ORIG_HEAD". There is one entry per rebase, so you count in the listing.

<!-- snippet: ch09/recover/05-rescue -->
```text
$ git branch rescue/rerank feat/rerank@{2}
$ git log --oneline rescue/rerank
6ab8f55 Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd Add retriever and model config
$ git reset --hard rescue/rerank
HEAD is now at 6ab8f55 Enable reranking in config
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank, rescue/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

The rescue branch comes first for a reason. It is a ref, so the commits stay reachable whatever you type next, and you can inspect them before moving the real branch. Only then the reset.

<!-- snippet: ch09/recover/06-head-reflog -->
```text
$ git reflog -8
6ab8f55 HEAD@{0}: reset: moving to rescue/rerank
195f8d0 HEAD@{1}: reset: moving to HEAD~1
e30ba74 HEAD@{2}: rebase (finish): returning to refs/heads/feat/rerank
e30ba74 HEAD@{3}: rebase (start): checkout main
6ab8f55 HEAD@{4}: reset: moving to ORIG_HEAD
e30ba74 HEAD@{5}: rebase (finish): returning to refs/heads/feat/rerank
e30ba74 HEAD@{6}: rebase (start): checkout main
6ab8f55 HEAD@{7}: commit: Enable reranking in config
```
<!-- /snippet -->

The reflog of HEAD holds the same story in more detail, one line per step. For "the branch before its last rebase", the branch's own reflog is the shorter list to read.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Following the `git pull` hint after your own rebase was rejected on push.** Root cause: the server still has the originals; a pull merges them next to your copies or replaces your copies with them.
2. **Merging after a "(forced update)" on a branch you have built on.** Root cause: commits are identified by ID, so the copies and the originals are different commits, and a merge keeps both lines.
3. **Pushing that merge.** Root cause: it makes the removed commits reachable on the server again, which undoes a rewrite whose purpose was to remove something.
4. **Relying on `ORIG_HEAD` hours after a rebase.** Root cause: it is one slot, rewritten by the next reset, merge, rebase or `git am`.
5. **Moving the real branch before creating a rescue ref.** Root cause: until a ref points at the recovered commits, they are reachable only through reflog entries that further commands keep pushing down.

## PRODUCTION EXAMPLE

Picture a team that shares a long-running branch for an ingestion pipeline. On a Friday one engineer rebases it onto `main` "to keep it fresh" and force-pushes with a lease. The lease holds: nobody had pushed since. Two colleagues had unpushed commits on top of the old history. On Monday both pull. One gets a merge with every commit twice and pushes it. By Tuesday the branch on the server contains the old line, the new line and two merges.

Nothing in that story required a mistake by Git or a missing guard on the push. The lease protects the server's ref. It says nothing about clones.

So the control is the textbook's working question, asked before the rebase: who else has commits on top of this? If the answer is "somebody", either the team agrees first and everybody receives the repair command, or the branch is brought up to date with a merge.

**[ON SCREEN]** Layer label: GitHub.

On the platform side, according to the documentation, a new ruleset has "Block force pushes" enabled by default, and classic branch protection rules disable force pushes by default. The textbook's advice: use that for `main` and for release branches, and leave topic branches open to their owners.

And for recovery: it is local. If you had already force-pushed a damaged branch, restore it in your clone first, and then publish it again.

## PRACTICE EXERCISE

Do Lab 9.5, "Break a branch on purpose and recover it", in [`lab-manual/m09-rebase.md`](../../lab-manual/m09-rebase.md).

Predict before each step:

- After the bad rebase: which commits are missing, and what does `ORIG_HEAD` name?
- After the failure step of the lab: what does `ORIG_HEAD` name now?
- In the branch's reflog: which entry number is the last good state? Count before you print it.

Create the rescue branch before you move anything.

The challenge is Lab 9.6, "Rebase a shared branch and watch a teammate's history duplicate", in the same file. Play both roles, and write down what each person saw at each step.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q155: "You force-pushed a rebased branch. A teammate now has every commit twice. Explain how that happened, how they repair it, and what you would have done differently."

Answer aloud first. A strong answer has three parts in the order asked. The explanation follows the commits through three repositories and rests on one fact about how Git identifies a commit. The repair is given from the teammate's seat, with the state she must return to first and how her own commits are told apart from the old copies. The third part is not "I would not have rebased": it names the question you would have asked, and the two acceptable courses depending on its answer.

## RECAP

You should now be able to say:

A rebase copies, so after I publish a rebased branch, a teammate who built on the old commits holds originals that Git treats as unrelated to my copies; a merge then keeps both lines, and pushing it brings the old commits back to the server. The repair is on their side: return to before the merge and replay only their own commits onto the new tip. Before rebasing anything pushed, I ask who else has commits on top of it. My own bad rebase destroys nothing: `--abort` works while it runs, `ORIG_HEAD` until the next command that writes it, and the branch's reflog for weeks. I create a rescue branch before I move the real one.

## HOMEWORK

Read sections 9.15 and 9.16 of [Chapter 9](../../textbook/ch09-rebase.md).

# V033: Anatomy of a conflict: working tree, index and .git, and the conflict styles

- **Part.** 2: Integration and collaboration mechanics
- **Module.** 6
- **Planned minutes.** 26
- **Prerequisites.** V018, V032
- **Textbook sections.** [Chapter 8: Merge](../../textbook/ch08-merge.md), sections 8.8 and 8.9
- **Demo scripts.** `labs/ch08/conflict-anatomy.sh`, `labs/ch08/conflict-styles.sh`

## HOOK

**[ON SCREEN]** A conflict block: two candidate lines between markers.

A merge stops. In the file there's a block with two candidate lines: one ends in `.strip()`, the other in `.lower()`. An engineer looks at the two, decides the second looks newer, deletes the first, and commits.

The correct answer was neither line. It was both normalizations together. And nothing in the block could have told them, because the block did not show what the line had been before either side touched it. Hold that block in your mind. You'll face the same choice later.

**[PAUSE]**

The textbook cites a poll in which 61 percent of roughly 1,480 respondents had seen a production bug caused by a bad conflict resolution at least once. It's a self-selected sample, as it notes. Most bad resolutions have the same cause: someone guessed from the markers. A conflict is not two lines in a file. It is a merge that stopped halfway and wrote its state into three places. This video reads all three.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A merge combines two branches, and a conflict is the point where Git can't combine two edits and asks you. In the last video you learned when two edits conflict. Now the merge has stopped, and the question is: what exactly did Git leave behind, and how do you read it?

We go through one conflicted merge, one snippet at a time: the working tree, the index with its three stages, and the files in the dot git folder. You met the stages briefly in video 18. Then we see the same conflict written three times, in the three conflict styles, and you'll see why the hook's engineer couldn't have got it right with the default.

The full resolution workflow, with abort, continue and quit, is the next video. Today we resolve one conflict the plain way, to see the anatomy close again.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. List everything Git writes when a merge stops at a conflict.
2. Read stages 1, 2 and 3 of a path without touching the working tree.
3. Read conflict markers in the `merge`, `diff3` and `zdiff3` styles.
4. Explain which commands are blocked while the merge is in progress.

## CONCEPT

**[ANIMATION]** trees: file=config/eval.yaml steps=setup names=Working_tree,Index,HEAD subs=the_file_with_marker_blocks,three_entries_for_the_path,has_not_moved chips=<<<<_====_>>>>,stages_1_2_3,ours title=A_conflict_is_written_into_three_places say_setup=A_merge_that_stopped_halfway_leaves_its_state_in_three_places ref=main

**In one sentence.** A conflicted merge is a merge that stopped halfway and wrote its unfinished state into three places: marker blocks in working-tree files, up to three index entries per conflicted path, and a handful of files in `.git`. A reminder: the working tree is your files on disk, and the index is the staging area, Git's draft of the next commit.

**Precisely.** The manual lists what happens when a merge cannot complete.

**[ON SCREEN]** The six points, one at a time.

One: "The `HEAD` pointer stays the same."

Two: `MERGE_HEAD` is set to the other branch's tip.

Three: paths that merged cleanly are updated in the index and in the working tree.

Four: for conflicting paths, the index records up to three versions: "stage 1 stores the version from the common ancestor, stage 2 from `HEAD`, and stage 3 from `MERGE_HEAD`". The working-tree files contain the merge result with conflict markers.

Five: `AUTO_MERGE` points to a tree that matches what was written to the working tree.

Six: nothing else changes.

Quick quiz. Asha checks out your branch and merges `main` into it. During her merge, are your commits A, ours, or B, theirs? Your answer?

**[PAUSE]**

**[ANIMATION]** merge: three-way feature/creative-judge into main title=Stage_1_base,_stage_2_ours,_stage_3_theirs steps=setup,merge-base common=6ae3c51 main_only=5397d5f feature_only=640bfe1,45a7a67

**Ours and theirs, exactly.** In a merge, ours is stage 2: the commit you were on when you typed `git merge`. Theirs is stage 3: the commit you named. It has nothing to do with who wrote what. So the answer is A: if Asha checks out your branch and merges `main`, your commits are "ours" to her. And during a rebase, the roles are swapped relative to intuition. The textbook quotes a poll in which 48 percent of 1,511 respondents did not know that.

**[ANIMATION]** end

**[ANIMATION]** step: merge-base

**Reading the stages.** The syntax `:<stage>:<path>` names the three blobs, so any command that reads objects can read them. `git show :1:path` is the base. `:2:` is ours. `:3:` is theirs. Each is a complete file, with no markers. Reading them does not touch the working tree.

**[ANIMATION]** graph: 6ae3c51-5397d5f main ORIG_HEAD; 6ae3c51-640bfe1-45a7a67 feature/creative-judge MERGE_HEAD; HEAD=main at_state_1=8

**The files in `.git`.** `MERGE_HEAD` is the commit being merged. It's what will make the next commit a merge commit. HEAD has not moved, and `ORIG_HEAD` equals it. `MERGE_MSG` is the prepared message, with the conflicted paths as a comment. `MERGE_MODE` is empty unless you passed `--no-ff`. `AUTO_MERGE` is a tree: the snapshot of what Git wrote to the working tree, markers included.

**The diff during a conflict.** `git diff` prints a combined diff, one column per side. The first column compares the working-tree file with ours, stage 2. The second compares it with theirs, stage 3. `git diff --ours`, `--theirs` and `--base` compare the working-tree file with one stage in the ordinary two-way format. And `git diff AUTO_MERGE` shows exactly what your hand edits changed relative to what Git wrote.

**What is blocked.** While the merge is open, Git refuses the two things that would lose track of it. `git commit` is refused while there are unmerged files. The second refusal you will read from the transcript.

**[ON SCREEN]** The state table of section 8.8: `git merge` that stops on a conflict, 🟡 CAUTION. Working tree: clean paths updated; conflicted files rewritten with marker blocks. Index: clean paths at stage 0; conflicted paths at stages 1, 2, 3. HEAD and current branch ref: unchanged. In `.git`: `MERGE_HEAD`, `MERGE_MSG`, `MERGE_MODE`, `AUTO_MERGE` created; `ORIG_HEAD` set; new blobs and trees; no commit.

**Conflict styles.** In one sentence: the conflict style decides how much of the three versions is written between the markers. `merge` shows ours and theirs. `diff3` adds the base. `zdiff3` adds the base, while moving lines that both sides share at the edges out of the block.

`merge.conflictStyle` selects the style, and `merge` is the default. `zdiff3` is available since Git 2.35, and the textbook recommends it. `git checkout --conflict=<style> <path>` and `git restore --conflict=<style> <path>` rewrite one conflicted file in another style from the index stages, without repeating the merge.

**How to read a three-part block.** Compare each side with the base, not the sides with each other. A side that equals the base did nothing in this region: take the other side. An empty base means both sides added text at the same place: usually keep both. Two sides that each differ from the base are two intents, and you need to serve both.

**Risk labels for the resolution steps.** `git add <path>` on an unmerged path is 🟢 SAFE: it collapses stages 1 to 3 into stage 0. Remember from video 18 that `git add` does not judge a resolution. `git merge --continue` is 🟡 CAUTION: it creates the merge commit and moves the branch. Its preview is `git diff --cached --check`, and running the tests. `git config set` is 🟡 CAUTION. The two red commands of this video are introduced with their five questions where they appear.

## MENTAL MODEL

A picture helps. The textbook's analogy: a customs desk. Everything that passed inspection is already through. Each contested parcel sits on the counter with three documents: the original declaration, your version and their version.

That picture corrects the usual one. A conflicted file is mostly finished. Only the marked regions are open, and for each open item you have three documents, not two.

The analogy breaks on time: nothing here expires until you conclude the merge or abort it. You're not under pressure from Git. Breathe, and read the documents.

## DIAGRAM

**[DIAGRAM]** The diagram of section 8.8. Draw the three boxes, then the line of `.git` files underneath.

```text
  Working tree                  Index (stage, path, blob)               HEAD -> main -> 5397d5f
  +-------------------------+   +-----------------------------------+   +----------------------+
  | config/eval.yaml        |   | 1  config/eval.yaml    c5b3327    |   | config/eval.yaml     |
  |   merged, except one    |   | 2  config/eval.yaml    0e8b97c    |   |   0e8b97c            |
  |   marker block (line 2) |   | 3  config/eval.yaml    db5c556    |   |                      |
  | prompts/judge.txt       |   | 0  prompts/judge.txt   38cb437    |   | prompts/judge.txt    |
  |   merged                |   | 0  evalkit/metrics.py  9bbcd7a    |   |   cfe0ef0            |
  +-------------------------+   +-----------------------------------+   +----------------------+

  .git/MERGE_HEAD = 45a7a67 (their tip)   .git/ORIG_HEAD = 5397d5f   .git/MERGE_MSG   .git/AUTO_MERGE (a tree)
```

Left: the working tree. One file with one marker block, and one file fully merged. Middle: the index. The conflicted path appears three times, at stages 1, 2 and 3, with three blob IDs, and has no stage 0. The other paths are at stage 0. Right: HEAD, which has not moved. Look at stage 2 and at HEAD's entry for the same path: the same blob, `0e8b97c`. Stage 2 is ours. Underneath: the four files in `.git` that say "a merge is in progress".

**[DIAGRAM]** The diagram of section 8.9.

```text
  <<<<<<< HEAD                         our version starts      (stage 2)
  ||||||| 6ae3c51                      base version starts     (stage 1; the label is the merge base)
  =======                              their version starts    (stage 3)
  >>>>>>> feature/case-insensitive     end of the block
```

Four marker lines, three sections. In the default style, the second marker and the base section are missing.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch08/conflict-anatomy.sh`. One snippet at a time.

```bash
labs/run ch08/conflict-anatomy
```

Into the lab. You set the temperature to 0.0 on `main`. Asha set it to 0.7 on her branch, changed the seed in the same commit, and added a prompt line in another. `git merge` 🟡 CAUTION. Predict, with the rule table: which paths merge cleanly, and which line conflicts? Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-anatomy/01-merge -->
```text
$ git log --oneline --graph --all
* 5397d5f Use temperature 0 for reproducible evals
| * 45a7a67 Ask the judge for a rationale
| * 640bfe1 Raise temperature and reseed for judge diversity
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

The exit status is 1.

<!-- snippet: ch08/conflict-anatomy/02-status -->
```text
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Changes to be committed:
	modified:   prompts/judge.txt

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   config/eval.yaml
```
<!-- /snippet -->

`git status` separates what is done from what is open. `prompts/judge.txt` merged cleanly, and is already staged. Only `config/eval.yaml` is unmerged.

<!-- snippet: ch08/conflict-anatomy/03-markers -->
```text
$ cat config/eval.yaml
model: judge-large-v2
<<<<<<< HEAD
temperature: 0.0
=======
temperature: 0.7
>>>>>>> feature/creative-judge
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 1234
```
<!-- /snippet -->

The working-tree copy. Between `<<<<<<< HEAD` and `=======` is our version of the region. Between `=======` and `>>>>>>> feature/creative-judge` is theirs. The last line, `seed: 1234`, is her seed change, merged outside the markers.

Now the index. Predict how many entries `config/eval.yaml` has.

<!-- snippet: ch08/conflict-anatomy/04-stages -->
```text
$ git ls-files -s
100644 c5b33275d88c041381cff59f23d3cd88b9f22c98 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 3	config/eval.yaml
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 0	evalkit/metrics.py
100644 38cb43793f7d697e3d7c88c83da85d1fcd783d68 0	prompts/judge.txt
$ git ls-files -u
100644 c5b33275d88c041381cff59f23d3cd88b9f22c98 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 3	config/eval.yaml
```
<!-- /snippet -->

The third column is the stage. Merged paths are at stage 0. The conflicted path has no stage 0 entry and three others: `c5b3327` at stage 1, `0e8b97c` at stage 2, `db5c556` at stage 3.

Try it now. Thirty seconds, on paper. Write the three `git show` commands that print the base, ours and theirs of `config/eval.yaml`, without touching the working tree. Then say them out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-anatomy/05-read-stages -->
```text
$ git show :1:config/eval.yaml
model: judge-large-v2
temperature: 0.2
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 7
# What our side did to the base, and what their side did:
$ git diff -U0 :1:config/eval.yaml :2:config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..0e8b97c 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.2
+temperature: 0.0
$ git diff -U0 :1:config/eval.yaml :3:config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..db5c556 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.2
+temperature: 0.7
@@ -7 +7 @@ retries: 2
-seed: 7
+seed: 1234
```
<!-- /snippet -->

The answer: `git show :1:config/eval.yaml` for the base, then `:2:` for ours and `:3:` for theirs. After the base come two diffs: base to ours, and base to theirs. The textbook calls those two diffs the most useful commands in conflict resolution: they show what each side intended. Here they reveal something the marker block did not: their side changed two lines, ours one.

<!-- snippet: ch08/conflict-anatomy/06-gitdir -->
```text
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
AUTO_MERGE
MERGE_HEAD
MERGE_MODE
MERGE_MSG
ORIG_HEAD
$ cat .git/MERGE_HEAD
45a7a672d9b049a35269a5e7d09e7920fa1d4c87
$ git rev-parse feature/creative-judge
45a7a672d9b049a35269a5e7d09e7920fa1d4c87
$ git rev-parse HEAD ORIG_HEAD
5397d5f953dda5e3acd0d0970078420baf6e0488
5397d5f953dda5e3acd0d0970078420baf6e0488
$ cat .git/MERGE_MSG
Merge branch 'feature/creative-judge'

# Conflicts:
#	config/eval.yaml
$ git cat-file -t AUTO_MERGE
tree
```
<!-- /snippet -->

Inside `.git`: `AUTO_MERGE`, `MERGE_HEAD`, `MERGE_MODE`, `MERGE_MSG`, `ORIG_HEAD`.

<!-- snippet: ch08/conflict-anatomy/07-diff -->
```text
$ git diff
diff --cc config/eval.yaml
index 0e8b97c,db5c556..0000000
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@@ -1,5 -1,5 +1,9 @@@
  model: judge-large-v2
++<<<<<<< HEAD
 +temperature: 0.0
++=======
+ temperature: 0.7
++>>>>>>> feature/creative-judge
  max_tokens: 512
  batch_size: 16
  timeout_s: 30
```
<!-- /snippet -->

The combined diff: two columns of markers before each line. A `+` in both columns marks a line that neither side has, which here means the marker lines.

<!-- snippet: ch08/conflict-anatomy/08-log-merge -->
```text
$ git log --oneline --left-right main...feature/creative-judge
< 5397d5f Use temperature 0 for reproducible evals
> 45a7a67 Ask the judge for a rationale
> 640bfe1 Raise temperature and reseed for judge diversity
$ git log --oneline --left-right --merge
< 5397d5f Use temperature 0 for reproducible evals
> 640bfe1 Raise temperature and reseed for judge diversity
```
<!-- /snippet -->

`git log --merge` narrows the two sides to the commits that touched the conflicted path: one of yours, one of hers. The commit that only added a prompt line is not listed.

Now try to walk away. Predict what `git commit` says. Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-anatomy/09-blocked -->
```text
$ git commit -m "Merge feature/creative-judge"
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
U	config/eval.yaml
[exit status: 128]
$ git switch feature/creative-judge
fatal: cannot switch branch while merging
Consider "git merge --quit" or "git worktree add".
[exit status: 128]
```
<!-- /snippet -->

Refused: "Committing is not possible because you have unmerged files." Read the second refusal in the same snippet: it is the other thing that would lose track of the merge.

<!-- snippet: ch08/conflict-anatomy/10-resolve -->
```text
# In your editor: delete the three marker lines and the 0.7 line. Keep temperature 0.0.
$ cat config/eval.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 1234
$ git diff AUTO_MERGE
diff --git a/config/eval.yaml b/config/eval.yaml
index 46bae64..1642b99 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -1,9 +1,5 @@
 model: judge-large-v2
-<<<<<<< HEAD
 temperature: 0.0
-=======
-temperature: 0.7
->>>>>>> feature/creative-judge
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
```
<!-- /snippet -->

The resolution, in an editor: delete the three marker lines and the 0.7 line. `git diff AUTO_MERGE` shows exactly what the hand edit changed, relative to what Git wrote.

<!-- snippet: ch08/conflict-anatomy/11-add -->
```text
$ git add config/eval.yaml
$ git ls-files -s
100644 1642b99ceb64bd0a58b86f8d20ab8b50fd1c9cee 0	config/eval.yaml
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 0	evalkit/metrics.py
100644 38cb43793f7d697e3d7c88c83da85d1fcd783d68 0	prompts/judge.txt
$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	modified:   config/eval.yaml
	modified:   prompts/judge.txt
```
<!-- /snippet -->

`git add` 🟢 SAFE on the unmerged path: three entries become one at stage 0. Status: "All conflicts fixed but you are still merging."

<!-- snippet: ch08/conflict-anatomy/12-continue -->
```text
$ git merge --continue
[main a94e9f6] Merge branch 'feature/creative-judge'
$ git log --oneline --graph
*   a94e9f6 Merge branch 'feature/creative-judge'
|\  
| * 45a7a67 Ask the judge for a rationale
| * 640bfe1 Raise temperature and reseed for judge diversity
* | 5397d5f Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
```
<!-- /snippet -->

`git merge --continue` 🟡 CAUTION creates the merge commit, `a94e9f6`. The `MERGE_*` files are gone, and `ORIG_HEAD` remains.

<!-- snippet: ch08/conflict-anatomy/13-result -->
```text
$ git show --stat --format=medium HEAD
commit a94e9f6aa320603f006ce6c0414285c7a24e1fb7
Merge: 5397d5f 45a7a67
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:33:00 2026 +0530

    Merge branch 'feature/creative-judge'
    
    Keep temperature 0.0: reproducible scores are a release requirement.
    The new seed and the rationale line in the judge prompt are taken as they are.

 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

And the message says why 0.0 was kept. A resolution is a decision, and the merge commit's message is where the reason belongs.

**[TERMINAL]** Caption bar: `labs/ch08/conflict-styles.sh`. The same conflict, three times.

```bash
labs/run ch08/conflict-styles
```

Both branches added the same guard against missing predictions, and then changed the comparison differently.

<!-- snippet: ch08/conflict-styles/01-merge-style -->
```text
# The function as both branches found it (the merge base):
$ git show main~1:evalkit/metrics.py | head -2
def exact_match(pred, gold):
    return float(pred == gold)
$ git merge feature/case-insensitive
Auto-merging evalkit/metrics.py
CONFLICT (content): Merge conflict in evalkit/metrics.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ head -9 evalkit/metrics.py
def exact_match(pred, gold):
    if pred is None:
        return 0.0
<<<<<<< HEAD
    return float(pred.strip() == gold.strip())
=======
    return float(pred.lower() == gold.lower())
>>>>>>> feature/case-insensitive
```
<!-- /snippet -->

The default style. Two candidate lines, and no hint of what the line was before. Did one side add `.strip()` and the other `.lower()`, or did someone remove something? This is the block from the hook. Decide now what you would keep, from this view alone. Say it out loud.

**[PAUSE]**

The next two commands rewrite the conflicted file from the index stages. `git checkout --conflict=<style>` and `git restore --conflict=<style>` belong to the group the textbook labels 🔴 DANGEROUS: restoring a conflicted path overwrites the working-tree file.

The five questions. What it changes: the working-tree file only. What it can destroy: your hand edits to that file, which exist nowhere else until you `git add` them. How to preview: `git diff --ours` or `git diff --theirs`. How to recover: `git restore --merge <path>` brings back the starting point, not your edits. When it is appropriate: to restart a resolution, or, as here, before you have edited anything.

<!-- snippet: ch08/conflict-styles/02-diff3 -->
```text
$ git checkout --conflict=diff3 evalkit/metrics.py
Recreated 1 merge conflict
$ head -13 evalkit/metrics.py
def exact_match(pred, gold):
<<<<<<< ours
    if pred is None:
        return 0.0
    return float(pred.strip() == gold.strip())
||||||| base
    return float(pred == gold)
=======
    if pred is None:
        return 0.0
    return float(pred.lower() == gold.lower())
>>>>>>> theirs
```
<!-- /snippet -->

In `diff3` style, the section after `|||||||` is the base. And it settles the question from the hook: the original compared `pred == gold`, so each side added one normalization, and the right answer applies both. The price is a larger block: the guard lines that both sides added identically are inside the conflict, twice.

<!-- snippet: ch08/conflict-styles/03-zdiff3 -->
```text
$ git restore --conflict=zdiff3 evalkit/metrics.py
$ head -11 evalkit/metrics.py
def exact_match(pred, gold):
    if pred is None:
        return 0.0
<<<<<<< ours
    return float(pred.strip() == gold.strip())
||||||| base
    return float(pred == gold)
=======
    return float(pred.lower() == gold.lower())
>>>>>>> theirs
```
<!-- /snippet -->

`zdiff3` keeps the base and removes that noise: the shared guard lines are outside the block. The labels read `ours`, `base` and `theirs`, because these two files were rebuilt from index stages, and stages carry no branch names.

Last: make it the setting, and merge afresh. That needs `git merge --abort` first, which is 🔴 DANGEROUS. What it changes: the index, the working tree and the merge state. What it can destroy: every resolution made so far, and any uncommitted edit that was staged during the merge. How to preview: `git status`. How to recover: staged content survives as unreferenced objects that `git fsck` lists, and unstaged resolution edits are gone. When it is appropriate: when the merge was a mistake or needs a different approach. Here nothing has been resolved.

<!-- snippet: ch08/conflict-styles/04-config -->
```text
$ git merge --abort
$ git config set merge.conflictStyle zdiff3
$ git config get --show-origin merge.conflictStyle
file:.git/config	zdiff3
$ git merge feature/case-insensitive
Auto-merging evalkit/metrics.py
CONFLICT (content): Merge conflict in evalkit/metrics.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ head -11 evalkit/metrics.py
def exact_match(pred, gold):
    if pred is None:
        return 0.0
<<<<<<< HEAD
    return float(pred.strip() == gold.strip())
||||||| 6ae3c51
    return float(pred == gold)
=======
    return float(pred.lower() == gold.lower())
>>>>>>> feature/case-insensitive
```
<!-- /snippet -->

`git config set merge.conflictStyle zdiff3` 🟡 CAUTION, and a fresh merge. The base is now labelled with its abbreviated commit ID.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Resolving from the two candidate lines alone.** Root cause: the default style shows ours and theirs and hides the base, so you cannot tell what each side changed from.
2. **Thinking "ours" means "my work".** Root cause: in a merge, ours is stage 2, the commit you were on; theirs is stage 3, the commit you named; authorship plays no part.
3. **Treating the whole file as broken.** Root cause: overlooking that a conflicted file is mostly merged; only the marker blocks are open, and other changes from their side are already in.
4. **Committing with markers left in.** Root cause: `git add` does not judge a resolution; it stages the file as it is.
5. **Trusting a merge tool over the repository.** Root cause: tools read the same three stages; when a tool and the command line seem to disagree, `git ls-files -u` is the ground truth.

## PRODUCTION EXAMPLE

Now, out of the lab. An evaluation team has a function `exact_match` that scores model outputs. One engineer makes it ignore surrounding whitespace. Another makes it case-insensitive. Both also add the same guard for a missing prediction. The merge conflicts on the comparison line. With the default style, the reviewer sees two lines and picks one, and the published scores silently lose one of the two normalizations. With `zdiff3`, the base line is on screen, each side's intent is visible, and the resolution keeps both.

The textbook's advice: set `merge.conflictStyle` to `zdiff3` once, globally. The setting changes only how conflicts are written to your working tree, and nothing that is committed, so it is a personal choice, not a team decision. The one thing to check is tooling that parses conflict markers, which must accept the `|||||||` section.

## PRACTICE EXERCISE

Your turn. Do Lab 6.2, "An edit-against-edit conflict, resolved by reading the stages", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md).

Before you open the conflicted file, predict from the two branches: how many index entries the conflicted path will have, and what `git show :1:`, `:2:` and `:3:` will print for it. Decide the resolution from the two diffs against the base, and only then edit the file.

## INTERVIEW QUESTION

Q128: "During a conflict, what are index stages 1, 2 and 3? How do you read "their" version of a file without touching the working tree?"

**[PAUSE]**

Answer out loud. A strong answer defines each stage by the commit it comes from, not by the person, and gives the exact notation that names a stage. It says what stage 0 is and what its absence means, and adds the two comparisons that show what each side intended.

## RECAP

**[ANIMATION]** step: state-1

Let's land this. You should now be able to say: when a merge stops, HEAD stays where it is. `MERGE_HEAD`, `MERGE_MSG`, `MERGE_MODE` and `AUTO_MERGE` appear in `.git`. Clean paths are staged. And each conflicted path has entries at stage 1, the base, stage 2, ours, and stage 3, theirs, plus a working-tree file with marker blocks. I read a stage with `git show :2:path` without touching the working tree, and I compare each side with the base. `git commit` is blocked until every path is back at stage 0. The `merge` style shows two sides. `diff3` adds the base. `zdiff3` adds the base and moves shared edge lines out of the block.

## HOMEWORK

- Read sections 8.8 and 8.9 of [Chapter 8](../../textbook/ch08-merge.md).
- Do Exercise 6.3, Level 1, "one conflict, step by step", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).
- Challenge: Exercise 6.8, Level 3, "conflict markers in `main`", in the same file.

A conflict is no longer two mysterious lines. It's three documents and a paused merge, and you know where each one lives. Do the lab, and read the stages before you edit. Next time: the resolution workflow, with abort, continue and quit, and restoring one side. Until then, look at the state first and type second. See you in the next one.

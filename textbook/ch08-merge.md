# Chapter 8: Merge

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch08/`.

## 8.1 Why this matters

Three questions a CTO can ask after an ordinary release week:

1. "Both pull requests were green. `main` is red. The two branches did not touch a single file in common. How?"
2. "Ravi's retry setting disappeared from the config in a merge commit. `git log -p` shows no diff for that commit. Who removed the line, and how do we prove it?"
3. "We reverted the bad merge on Friday. On Monday we merged the repaired branch, the merge was clean, and half of the feature is missing. Where did it go?"

The answers are in sections 8.15, 8.16 and 8.18. None needs a bug in Git. Each follows from what a merge is.

The stakes are measurable. In a 2024 poll of working developers, 61% of roughly 1,480 respondents had seen a production bug caused by a bad conflict resolution at least once, and 48% of 1,511 did not know that "ours" and "theirs" swap between a merge and a rebase ([poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/); a self-selected sample, so read it as direction, not as a population estimate).

Hold on to one idea through the chapter. A merge is computed from exactly three snapshots: your commit, their commit, and one common ancestor called the merge base. Git's FAQ states it plainly: "Git does not consider the history or the individual commits that have happened on those branches at all" ([gitfaq](https://git-scm.com/docs/gitfaq)). Git compares lines of text in those three snapshots. It does not know what the lines mean. Every surprise in this chapter is one of those two facts showing through.

The sample project is `evalkit`, a small evaluation harness for LLM outputs: `config/eval.yaml` holds the run configuration, `prompts/judge.txt` the prompt for the judge model, and `evalkit/metrics.py` the scoring functions. You work on `main`. Asha and Ravi work on branches.

## 8.2 Divergence and the merge base

**In one sentence.** The merge base of two commits is their best common ancestor: the most recent commit that both histories contain, and the third input of every merge.

**Analogy.** Two editors photocopy a manuscript on Monday and mark up their copies separately. On Friday you can combine their work only if you still have the Monday copy: without it you cannot tell a sentence that one editor added from a sentence that the other deleted. The merge base is the Monday copy. The analogy breaks in two places. Git finds the Monday copy by walking parent links, not by date. And a tangled history can have two equally good Monday copies (section 8.5).

**Precisely.** A common ancestor of commits A and B is a commit reachable from both by following parents ([Chapter 7](ch07-branches.md) introduced ancestry and divergence). The manual defines the rest: "One common ancestor is better than another common ancestor if the latter is an ancestor of the former. A common ancestor that does not have any better common ancestor is a best common ancestor, i.e. a merge base" ([git-merge-base](https://git-scm.com/docs/git-merge-base)). Two branches have diverged when each contains commits that the other lacks. Four commands answer every question about this:

| Question | Command |
|---|---|
| Which commit is the merge base? | `git merge-base A B` (add `--all` to print every merge base) |
| Is A an ancestor of B? | `git merge-base --is-ancestor A B` (exit status 0 means yes, 1 means no) |
| How many commits does each side have that the other lacks? | `git rev-list --left-right --count A...B` |
| Which commits are they? | `git log --oneline --left-right A...B` |

**Inside `.git`.** Nothing is stored. The merge base is computed from the `parent` lines of commit objects every time a command needs it. No file says where a branch "came from".

**See it.** `main` has one commit of its own, `feature/rationale` has two:

<!-- snippet: ch08/merge-base/01-merge-base -->
```text
$ git log --oneline --graph --all
* c089834 Use temperature 0 for reproducible evals
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge-base main feature/rationale
6ae3c51e176b786603aea088486677fe30f409bd
$ git rev-list --left-right --count main...feature/rationale
1	2
$ git log --oneline --left-right main...feature/rationale
< c089834 Use temperature 0 for reproducible evals
> 58a5e60 Ask the judge to quote evidence
> 5aec6e0 Ask the judge for a rationale
```
<!-- /snippet -->

The two counts read "one commit only on the left side, two only on the right". In the `--left-right` log, `<` marks commits reachable only from `main` and `>` commits reachable only from the branch.

Three dots mean something different to `git diff`, and the difference matters for reviews:

<!-- snippet: ch08/merge-base/02-three-dot-diff -->
```text
# Three dots in git diff: from the merge base to the right-hand side.
$ git diff --stat main...feature/rationale
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
# Two dots (or a space): the two tips compared directly.
$ git diff --stat main..feature/rationale
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

With three dots, `git diff` compares the merge base with the branch tip: what the branch did, and nothing that `main` did meanwhile. With two dots it compares the two tips, so the temperature change that `main` made appears as if the branch had undone it.

**Picture.**

```text
            5aec6e0---58a5e60   feature/rationale
           /
  6ae3c51---c089834             main   (HEAD -> main)
     ^
     merge base of main and feature/rationale
```

**In production.** The three-dot diff is what a pull request page shows, which is why a pull request does not list changes that landed on the base branch after you forked ([Chapter 17](ch17-pull-requests.md)). The age of the merge base also predicts merge pain. A branch that forked three weeks ago is combined against a three-week-old snapshot, and everything both sides did since then is in play. For a branch that must live long, merging `main` into it at intervals moves the merge base forward and keeps each merge small.

## 8.3 Fast-forward: a merge that creates nothing

**In one sentence.** When your current commit is an ancestor of the commit you merge, there is nothing to combine, so Git moves your branch ref to that commit and creates no new object.

**Analogy.** A bookmark in a manuscript that somebody else kept writing. You move the bookmark to the last page. The analogy breaks on one point: nothing in the book records that the bookmark moved, or that the new pages were ever a separate branch. Only your local reflog knows.

**Precisely.** The condition is `git merge-base --is-ancestor HEAD <other>`. Put differently, the merge base is your own tip. Fast-forwarding is the default (`--ff`). The opposite case has its own message: if `<other>` is already an ancestor of HEAD, the merge prints "Already up to date." and moves nothing.

**Inside `.git`.** The file `refs/heads/main` is rewritten with the new commit ID. `ORIG_HEAD` receives the old one. The reflogs of HEAD and of `main` each gain one line. The index and the working tree are updated as by a branch switch. The object database does not change: count the commits before and after. One detail found while testing: every `git merge` call rewrites `ORIG_HEAD` with the tip it started from, even a call that prints "Already up to date." or refuses. As an undo pointer it is valid only until the next attempt; the reflog is the durable record.

**See it.**

<!-- snippet: ch08/ff-or-true-merge/01-before -->
```text
$ git log --oneline --graph --all
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge-base --is-ancestor main feature/batch-size
[exit status: 0]
$ git rev-list --count --all
2
```
<!-- /snippet -->

<!-- snippet: ch08/ff-or-true-merge/02-fast-forward -->
```text
$ git merge feature/batch-size
Updating 6ae3c51..23db174
Fast-forward
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --all
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git rev-list --count --all
2
$ git reflog -2
23db174 HEAD@{0}: merge feature/batch-size: Fast-forward
6ae3c51 HEAD@{1}: checkout: moving from feature/batch-size to main
$ cat .git/ORIG_HEAD
6ae3c51e176b786603aea088486677fe30f409bd
```
<!-- /snippet -->

"Updating 6ae3c51..23db174" names the old and the new position of `main`. There are still two commits. The reflog entry says `merge feature/batch-size: Fast-forward`, and `ORIG_HEAD` holds `6ae3c51`, the commit to return to if this was a mistake.

**Picture.**

```text
  Before                                     After git merge feature/batch-size

  6ae3c51---23db174   feature/batch-size     6ae3c51---23db174   feature/batch-size
     ^                                                    ^
     main  (HEAD -> main)                                 main  (HEAD -> main)
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git merge <other>`, fast-forward 🟡 | files updated to the tree of `<other>` | rewritten to match `<other>` | still `ref: refs/heads/main` | moves to the tip of `<other>` | `ORIG_HEAD` set to the old tip; reflogs of HEAD and the branch gain an entry; no new objects | unchanged | unchanged |
| `git merge <other>`, "Already up to date." 🟢 | unchanged | unchanged | unchanged | unchanged | `ORIG_HEAD` rewritten with the current tip; nothing else | unchanged | unchanged |

**In production.** A fast-forward is what `git pull` does on a branch where you have no commits of your own ([Chapter 12](ch12-remote-operations.md)). The risk is the missing trace. If somebody fast-forwards an unfinished branch into `main`, the history looks as if the work-in-progress commits had been made on `main` directly, and no merge commit exists to revert. Lab 6.1 reproduces this and recovers with `ORIG_HEAD`. Section 8.12 shows how to forbid it.

## 8.4 The true merge: three inputs, one rule table

**In one sentence.** When both sides have commits that the other lacks, Git combines the two tips against their merge base, path by path and then line by line, and records the result as a commit with two parents.

**Analogy.** The editor-in-chief has three copies on the desk: Monday's, yours and theirs. If only one of you changed a page, take that version. If both made the same change, take it once. If both changed it differently, open the page and compare paragraphs. The analogy breaks where it matters most: the editor-in-chief reads for meaning, Git compares text.

**Precisely.** Call the three trees base, ours (the commit HEAD points to) and theirs (the commit named on the command line). For every path Git compares three blob IDs. X, Y and Z stand for different contents:

| Base | Ours | Theirs | Result | Path in the transcript below |
|---|---|---|---|---|
| X | X | X | X: nobody changed it | `evalkit/metrics.py` |
| X | Y | X | Y: only ours changed it | `README.md` |
| X | X | Y | Y: only theirs changed it | `requirements.txt` |
| X | Y | Y | Y: both made the same change | `prompts/judge.txt` |
| X | Y | Z | merge the content of the three files (section 8.7) | `config/eval.yaml` |
| absent | absent | Y | Y: added by theirs | `evalkit/rouge.py` |
| X | X | absent | absent: deleted by theirs, untouched by ours | `scripts/legacy_eval.sh` |
| X | Y | absent | conflict: modify/delete (section 8.11) | |
| absent | Y | Z | conflict: add/add (section 8.11) | |

The table is not an interpretation. The manual of `git read-tree`, Git's original three-way merge plumbing, states the first rows as "stage 2 and 3 are the same; take one or the other", "stage 1 and stage 2 are the same and stage 3 is different; take stage 3", and "stage 1 and stage 3 are the same and stage 2 is different take stage 2" ([git-read-tree](https://git-scm.com/docs/git-read-tree)). Stages 1, 2 and 3 are base, ours and theirs (section 8.8).

Two consequences follow. First, most paths are settled without reading a file: equal content has an equal blob ID ([Chapter 2](ch02-mental-model.md)), so comparing three IDs is enough. Second, the rows mention three snapshots and nothing else. The commits between the base and each tip do not take part. A change that both sides made is taken once and silently. A change that one side made and later undid counts as "that side did nothing", which section 8.15 turns into a production incident.

**Inside `.git`.** A clean true merge writes a blob for every file merged by content, the trees above those blobs, and one commit object with two `parent` lines. Then it does what any commit does: the current branch ref moves to the new commit and the reflogs gain a line. `ORIG_HEAD` holds the previous tip.

**See it.** After the fast-forward of section 8.3, `main` and a new branch each gain one commit:

<!-- snippet: ch08/ff-or-true-merge/03-diverged -->
```text
$ git log --oneline --graph --all
* 017bef5 Use temperature 0 for reproducible evals
| * 67feed7 Raise timeout to 60 seconds
|/  
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge-base --is-ancestor main feature/timeout
[exit status: 1]
$ git merge-base main feature/timeout
23db1749f261b3f9ca7627a25923389c32a4a64d
$ git rev-list --left-right --count main...feature/timeout
1	1
```
<!-- /snippet -->

Neither tip is an ancestor of the other, so a fast-forward is impossible. The merge base is `23db174`.

<!-- snippet: ch08/ff-or-true-merge/04-true-merge -->
```text
$ git merge feature/timeout
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --all
*   6b10077 Merge branch 'feature/timeout'
|\  
| * 67feed7 Raise timeout to 60 seconds
* | 017bef5 Use temperature 0 for reproducible evals
|/  
* 23db174 Raise batch size to 32
* 6ae3c51 Add eval config, judge prompt and metrics
$ git rev-list --count --all
5
```
<!-- /snippet -->

"Auto-merging config/eval.yaml" reports a content merge: both sides changed that file, differently. "Merge made by the 'ort' strategy." names the algorithm (section 8.6). The repository went from four commits to five. The new one has two parents:

<!-- snippet: ch08/ff-or-true-merge/05-merge-commit -->
```text
$ git cat-file -p HEAD
tree 25ed240b50b6ea31af8a6023d66eac8ce10d5364
parent 017bef5a99c9b0472c2c1fd4181b9d01c243e76c
parent 67feed7ad67adc99e081b8c29515db39c4726dbb
author Lab User <you@example.com> 1788756960 +0530
committer Lab User <you@example.com> 1788756960 +0530

Merge branch 'feature/timeout'
$ git reflog -1
6b10077 HEAD@{0}: merge feature/timeout: Merge made by the 'ort' strategy.
$ cat config/eval.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 32
timeout_s: 60
retries: 2
seed: 7
```
<!-- /snippet -->

The first `parent` is where you were (`017bef5`), the second is what you merged (`67feed7`). The merged file carries `temperature: 0.0` from your side and `timeout_s: 60` from theirs. Merging either branch again finds nothing to do:

<!-- snippet: ch08/ff-or-true-merge/06-up-to-date -->
```text
$ git merge feature/timeout
Already up to date.
$ git merge feature/batch-size
Already up to date.
```
<!-- /snippet -->

Now the rule table on a larger example. Compare the abbreviated blob IDs of the three listings path by path before you look at the result:

<!-- snippet: ch08/three-way-rules/01-three-inputs -->
```text
$ git merge-base main feature/rouge
e650b75915a1645cdb222c495fa22e6273eab187
# base (the merge base, tagged "base" by the demo):
$ git ls-tree -r --abbrev=7 base
100644 blob af7f9b5	README.md
100644 blob c5b3327	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob cfe0ef0	prompts/judge.txt
100644 blob 3aecde9	requirements.txt
100644 blob 4a41a25	scripts/legacy_eval.sh
# ours (main):
$ git ls-tree -r --abbrev=7 main
100644 blob aa477a1	README.md
100644 blob 0e8b97c	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob 38cb437	prompts/judge.txt
100644 blob 3aecde9	requirements.txt
100644 blob 4a41a25	scripts/legacy_eval.sh
# theirs (feature/rouge):
$ git ls-tree -r --abbrev=7 feature/rouge
100644 blob af7f9b5	README.md
100644 blob caf8b0d	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob fe0b96e	evalkit/rouge.py
100644 blob 38cb437	prompts/judge.txt
100644 blob 4a7b8a2	requirements.txt
```
<!-- /snippet -->

<!-- snippet: ch08/three-way-rules/02-merge -->
```text
$ git merge feature/rouge
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml       | 2 +-
 evalkit/rouge.py       | 2 ++
 requirements.txt       | 1 +
 scripts/legacy_eval.sh | 2 --
 4 files changed, 4 insertions(+), 3 deletions(-)
 create mode 100644 evalkit/rouge.py
 delete mode 100644 scripts/legacy_eval.sh
```
<!-- /snippet -->

<!-- snippet: ch08/three-way-rules/03-result -->
```text
# result (the tree of the merge commit):
$ git ls-tree -r --abbrev=7 HEAD
100644 blob aa477a1	README.md
100644 blob cef358f	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob fe0b96e	evalkit/rouge.py
100644 blob 38cb437	prompts/judge.txt
100644 blob 4a7b8a2	requirements.txt
```
<!-- /snippet -->

`README.md` is `af7f9b5` in base and theirs and `aa477a1` in ours: the result is `aa477a1`. `requirements.txt` changed only in theirs: the result is `4a7b8a2`. `prompts/judge.txt` is `38cb437` on both sides because Asha and you added the same line independently: taken once, no message. `scripts/legacy_eval.sh` is unchanged in ours and missing in theirs: deleted. `evalkit/rouge.py` exists only in theirs: added. Only `config/eval.yaml` has three different IDs, and its result, `cef358f`, is a new blob:

<!-- snippet: ch08/three-way-rules/04-content-merge -->
```text
# What ours changed since the base (HEAD^1 is the first parent of the merge):
$ git diff -U0 base HEAD^1 -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..0e8b97c 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.2
+temperature: 0.0
# What theirs changed since the base (HEAD^2 is the second parent):
$ git diff -U0 base HEAD^2 -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..caf8b0d 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -5 +5 @@ batch_size: 16
-timeout_s: 30
+timeout_s: 60
# The merged file carries both changes:
$ git diff -U0 base HEAD -- config/eval.yaml
diff --git a/config/eval.yaml b/config/eval.yaml
index c5b3327..cef358f 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -2 +2 @@ model: judge-large-v2
-temperature: 0.2
+temperature: 0.0
@@ -5 +5 @@ batch_size: 16
-timeout_s: 30
+timeout_s: 60
```
<!-- /snippet -->

**Picture.**

```text
                      67feed7----------.          feature/timeout
                     /                  \
  6ae3c51---23db174---017bef5-----------6b10077   main   (HEAD -> main)
               ^
               merge base
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git merge <other>`, true merge without conflict 🟡 | files updated to the merged tree | rewritten to match the merged tree | still `ref: refs/heads/main` | moves to the new merge commit | new blobs, trees and one commit; `ORIG_HEAD` set to the old tip; reflogs gain an entry | unchanged | unchanged |

**In production.** The tree of a merge commit is a snapshot that neither author wrote and that no test has run on. Both parents can be green while the merge is red (section 8.15), so CI has to run on the merge result.

> **GitHub, not Git.** For a `pull_request` event GitHub Actions checks out a merge of the pull request's head into the current base by default, so the tests run against the merged result and not against the head branch alone ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)). That merge is computed on GitHub's servers (section 8.17). Chapter 20A covers what this means for `GITHUB_SHA`.

## 8.5 Criss-cross histories: more than one merge base

**In one sentence.** When two branches have each merged the other, they can have two best common ancestors, and Git then merges those ancestors with each other first and uses the result as the base.

**Analogy.** Two Monday copies, each containing a decision that one editor made and the other rejected. Before the editor-in-chief can compare Friday's copies, the two Monday copies have to be reconciled into one. The analogy breaks when they cannot be: Git then keeps the disagreement inside the base, as conflict markers.

**Precisely.** `git merge-base --all` prints every merge base. Without `--all` you get one, and "it is unspecified which best one is output" ([git-merge-base](https://git-scm.com/docs/git-merge-base)). The default strategy handles the case as follows: "When there is more than one common ancestor that can be used for 3-way merge, it creates a merged tree of the common ancestors and uses that as the reference tree for the 3-way merge" ([git-merge](https://git-scm.com/docs/git-merge)). That merged tree is called the virtual merge base.

**Inside `.git`.** The virtual merge base is computed during the merge and never becomes a commit. Its only visible trace is stage 1 of a conflicted path.

**See it.** `main` and `release/1.0` disagreed about the judge temperature. Asha merged `main` into the release branch and kept 0.7. At the same time you merged the release branch into `main` and kept 0.0:

<!-- snippet: ch08/merge-base/03-crisscross -->
```text
$ git log --oneline --graph --all
*   bd573ed Merge release/1.0 into main, keep temperature 0.0
|\  
| | * 4f30da1 Merge main into release/1.0, keep temperature 0.7
| |/| 
| |/  
|/|   
* | 5d28836 Use temperature 0 for reproducible evals
| * 2725147 Raise temperature for the 1.0 judge
|/  
* 36749ac Add eval config, judge prompt and metrics
$ git merge-base main release/1.0
272514788670fe9d71d00daeca408d3494e15041
$ git merge-base --all main release/1.0
272514788670fe9d71d00daeca408d3494e15041
5d288362f8c011ad12da5920c8cc763443e61c5d
```
<!-- /snippet -->

Two merge bases: `2725147` (her commit) and `5d28836` (yours). What would happen if Git picked one? `git merge-tree` (section 8.17) can be told which base to use:

<!-- snippet: ch08/merge-base/04-three-answers -->
```text
# Merge with only the first candidate as the base:
$ tree=$(git merge-tree --write-tree --merge-base=release/1.0~1 main release/1.0)
$ git show $tree:config/eval.yaml | grep temperature
temperature: 0.0
# Merge with only the second candidate as the base:
$ tree=$(git merge-tree --write-tree --merge-base=main~1 main release/1.0)
$ git show $tree:config/eval.yaml | grep temperature
temperature: 0.7
```
<!-- /snippet -->

Two silent, opposite answers. Against her commit as base, the release tip "did nothing" to the temperature and your side wins. Against your commit as base, her side wins. Neither would show a conflict, and nobody would have decided either. The real merge does better:

<!-- snippet: ch08/merge-base/05-virtual-base -->
```text
$ git merge release/1.0
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git ls-files -u
100644 eeb99652ab2e2dc7f9c07b8a0db026159a245750 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 3e21100524f1361d04738d41f1012b9221082155 3	config/eval.yaml
$ git show :1:config/eval.yaml
model: judge-large-v2
<<<<<<<<< Temporary merge branch 1
temperature: 0.0
=========
temperature: 0.7
>>>>>>>>> Temporary merge branch 2
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 7
```
<!-- /snippet -->

Stage 1, the base version, contains conflict markers. That file is the virtual merge base: the result of merging the two base commits with each other, labelled "Temporary merge branch 1" and "2". Because both tips differ from it, the outer merge conflicts and the decision comes back to you. The `diff3` conflict style (section 8.9) shows the nesting in one view. The inner markers are nine characters long, the outer ones seven:

<!-- snippet: ch08/merge-base/06-diff3-nested -->
```text
$ git merge --abort
$ git -c merge.conflictStyle=diff3 merge release/1.0
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat config/eval.yaml
model: judge-large-v2
<<<<<<< HEAD
temperature: 0.0
||||||| merged common ancestors
<<<<<<<<< Temporary merge branch 1
temperature: 0.0
||||||||| 36749ac
temperature: 0.2
=========
temperature: 0.7
>>>>>>>>> Temporary merge branch 2
=======
temperature: 0.7
>>>>>>> release/1.0
max_tokens: 512
batch_size: 16
timeout_s: 30
retries: 2
seed: 7
```
<!-- /snippet -->

**Picture.**

```text
  36749ac---5d28836---bd573ed   main   (HEAD -> main)
        \          \ /
         \          X
          \        / \
           2725147---4f30da1    release/1.0

  merge bases of main and release/1.0: 5d28836 and 2725147
```

```text
Observed behavior : The base version of a conflicted file (git show :1:path, or the middle
                    section in diff3 style) contains conflict markers labelled
                    "Temporary merge branch 1" and "Temporary merge branch 2".
Git state         : git merge-base --all prints two commits; neither is an ancestor of the other.
Mechanism         : The ort strategy first merges the two merge bases with each other. That inner
                    merge conflicts, and its result, markers included, becomes the base.
Root cause        : A criss-cross. Each branch merged the other, and the two merges resolved the
                    same conflict in opposite ways.
Why Git does this : Either base alone would silently reapply one side's old decision, as the
                    two-answer transcript shows. A base that matches neither tip returns the
                    question to a human.
Correct fix       : Resolve it as an ordinary conflict. Read the inner block as the two earlier
                    decisions and the outer sides as the two current values.
Prevention        : Between long-lived branches, merge in one direction only. Keep other
                    branches short enough that they never merge each other.
```

**In production.** The usual producers are a release branch and `main` that merge each other "to stay in sync", and two developers who each pull the other's feature branch. The reported symptom is "the same conflict keeps coming back". Run `git merge-base --all` before theorizing.

## 8.6 Strategies and strategy options

**In one sentence.** A merge strategy is the algorithm that turns the inputs into a result tree, selected with `-s`; a strategy option, passed with `-X`, adjusts how one strategy behaves.

**Precisely.** These are the strategies that the Git 2.55 manual lists, in its own words where quoted:

| Strategy | Heads | What the manual says | Where you meet it |
|---|---|---|---|
| `ort` | 2 | "the default merge strategy when pulling or merging one branch"; 3-way; builds a virtual base when there are several merge bases; detects renames; defaults to the histogram diff algorithm | Every ordinary merge; also under rebase, cherry-pick and revert (Chapters 9 to 11) |
| `recursive` | 2 | "now a synonym for `ort`" | Old scripts and old tutorials |
| `resolve` | 2 | 3-way; "does not handle renames" | Legacy; section 8.20 shows why to leave it alone |
| `octopus` | more than 2 | "refuses to do a complex merge that needs manual resolution"; the default for several heads | Section 8.14 |
| `ours` | any | the result tree "is always that of the current branch head, effectively ignoring all changes from all other branches" | Recording that an obsolete branch is superseded |
| `subtree` | 2 | "a modified `ort` strategy" that shifts one tree to match a subdirectory of the other | Embedding another project in a subdirectory |

The options that `ort` accepts with `-X` are `ours` and `theirs` (which side wins a conflicting hunk), the whitespace options `ignore-space-change`, `ignore-all-space`, `ignore-space-at-eol` and `ignore-cr-at-eol`, the rename options `find-renames[=<n>]` and `no-renames` (section 8.11), and `diff-algorithm=<name>`, `renormalize` and `subtree[=<path>]`.

**`-X ours` is not `-s ours`.** You changed the temperature; Asha changed the temperature and the seed, and added a prompt line.

<!-- snippet: ch08/strategy-options/01-what-differs -->
```text
# ours changed temperature; theirs changed temperature AND seed, and added a prompt line.
$ git diff --stat main...feature/creative-judge
 config/eval.yaml  | 4 ++--
 prompts/judge.txt | 1 +
 2 files changed, 3 insertions(+), 2 deletions(-)
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 7
```
<!-- /snippet -->

<!-- snippet: ch08/strategy-options/02-x-ours -->
```text
$ git merge -X ours feature/creative-judge
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 1234
$ tail -1 prompts/judge.txt
Explain your verdict in one sentence.
```
<!-- /snippet -->

`-X ours` is a real three-way merge in which only the conflicting hunk is decided in your favour (temperature stays 0.0). Her seed and her prompt line arrive. `-X theirs` is the mirror image:

<!-- snippet: ch08/strategy-options/03-x-theirs -->
```text
$ git merge -X theirs feature/creative-judge
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml  | 4 ++--
 prompts/judge.txt | 1 +
 2 files changed, 3 insertions(+), 2 deletions(-)
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.7
7:seed: 1234
```
<!-- /snippet -->

`-s ours` does not look at her tree at all:

<!-- snippet: ch08/strategy-options/04-s-ours -->
```text
$ git merge -s ours feature/creative-judge
Merge made by the 'ours' strategy.
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 7
$ tail -1 prompts/judge.txt
Answer with PASS or FAIL.
# The tree of the merge commit is the tree of its first parent:
$ git rev-parse HEAD^{tree} HEAD^1^{tree}
3dfab55ba26e160c0bf7d8f7533173a3d264618f
3dfab55ba26e160c0bf7d8f7533173a3d264618f
# Yet the history says the branch is merged:
$ git branch --merged
  feature/creative-judge
* main
```
<!-- /snippet -->

No seed change, no prompt line, and the tree of the merge commit is identical to the tree of its first parent. Yet `git branch --merged` lists her branch, because her commits are now ancestors of `main`. The merge recorded ancestry and discarded content.

| | `-X ours` | `-s ours` |
|---|---|---|
| What it is | an option of the `ort` strategy | a different strategy |
| Their non-conflicting changes | merged | discarded |
| Conflicting hunks | your side, without a conflict being reported | not applicable |
| Tree of the merge commit | a real merge result | identical to the first parent's tree |
| Legitimate use | rare: mechanical conflicts where one side is known to be right | declare a branch obsolete so that it never merges again |

There is no `-s theirs`, and `recursive` still works as a name:

<!-- snippet: ch08/strategy-options/05-no-s-theirs -->
```text
$ git merge -s theirs feature/creative-judge
Could not find merge strategy 'theirs'.
Available strategies are: octopus ours recursive resolve subtree.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch08/strategy-options/06-recursive -->
```text
$ git merge -s recursive -X ours feature/creative-judge
Auto-merging config/eval.yaml
Merge made by the 'recursive' strategy.
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

The list of "available strategies" lacks `ort` because it enumerates helper programs named `git-merge-<strategy>` on disk, and `ort` is built into `git merge` itself (section 8.20).

**Whitespace options.** A formatter re-indents a YAML list on one branch while you rename a metric on `main`:

<!-- snippet: ch08/strategy-options/07-whitespace-conflict -->
```text
$ git merge chore/yaml-format
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat config/eval.yaml
model: judge-large-v2
metrics:
<<<<<<< HEAD
  - exact_match
  - token_f1
=======
    - exact_match
    - f1
>>>>>>> chore/yaml-format
seed: 7
$ git merge --abort
```
<!-- /snippet -->

<!-- snippet: ch08/strategy-options/08-ignore-space-change -->
```text
$ git merge -X ignore-space-change chore/yaml-format
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
$ cat config/eval.yaml
model: judge-large-v2
metrics:
  - exact_match
  - token_f1
seed: 7
```
<!-- /snippet -->

The conflict is gone, and so is the reformatting. The merged file has your two-space indentation, and the merge printed no diffstat because its tree equals your tree.

```text
Observed behavior : After git merge -X ignore-space-change, the formatting branch counts as
                    merged, but the file is not reformatted.
Git state         : The merge commit's tree is identical to its first parent's tree.
Mechanism         : With a whitespace option, "if their version only introduces whitespace
                    changes to a line, our version is used" (git-merge manual).
Root cause        : The option does not merge whitespace changes. It discards them
                    wherever they meet a line that our side kept or changed.
Why Git does this : A line cannot carry their indentation and our text at the same time
                    without Git inventing a third version.
Correct fix       : Run the formatter again on the merge result and commit.
Prevention        : Land formatting-only changes when no other branch is open on those files,
                    or have every branch run the same formatter before merging.
```

**In production.** `-X ours` and `-X theirs` turn "Git stopped and asked" into "Git chose and said nothing". They are defensible where one side is correct by construction, as with a regenerated lock file. They are indefensible as a way to make a red merge green. The audit command of section 8.16 still shows the choice, because it repeats the merge without your options.

## 8.7 Exactly why conflicts occur

**In one sentence.** A content conflict occurs when both sides changed the same lines of a file, or lines with no unchanged line between them, and did not make the identical change.

**Analogy.** Two people mark up the same printed page. Marks in different paragraphs can both be typed in. Marks in the same sentence need a conversation. The analogy breaks at the boundary: Git's unit is the line and its test is adjacency, not whether the two edits have anything to do with each other.

**Precisely.** For a path in the "X, Y, Z" row of the rule table, Git merges the three file contents. It finds what ours changed relative to the base and what theirs changed relative to the base, each as a set of hunks: runs of base lines that were replaced, removed or inserted into. Hunks that do not touch are both applied. Hunks that cover the same base lines with the same replacement are applied once. Everything else is a conflict. The manual's wording is "When both sides made changes to the same area, however, Git cannot randomly pick one side over the other" ([git-merge](https://git-scm.com/docs/git-merge)). The unit is the line. A one-word change in a long line conflicts with any other change to that line.

**See it.** `git merge-file` runs this file-level merge on three ordinary files, with no repository involved. Its exit status is the number of conflicts. Start with changes in different regions:

<!-- snippet: ch08/why-conflicts/01-different-regions -->
```text
$ cat base.yaml
model: judge-large-v2
temperature: 0.2
max_tokens: 512
batch_size: 16
timeout_s: 30
$ sed 's/temperature: 0.2/temperature: 0.0/' base.yaml > ours.yaml
$ sed 's/timeout_s: 30/timeout_s: 60/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 16
timeout_s: 60
[exit status: 0]
```
<!-- /snippet -->

Same line, different values: a conflict. Same line, same value: none.

<!-- snippet: ch08/why-conflicts/02-same-line -->
```text
$ sed 's/temperature: 0.2/temperature: 0.7/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
<<<<<<< ours.yaml
temperature: 0.0
=======
temperature: 0.7
>>>>>>> theirs.yaml
max_tokens: 512
batch_size: 16
timeout_s: 30
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch08/why-conflicts/03-same-change -->
```text
$ sed 's/temperature: 0.2/temperature: 0.0/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 16
timeout_s: 30
[exit status: 0]
```
<!-- /snippet -->

The case that surprises people is the next one. Ours changes line 2, theirs changes line 3:

<!-- snippet: ch08/why-conflicts/04-adjacent-lines -->
```text
# ours changes line 2, theirs changes line 3: no unchanged line between them.
$ sed 's/max_tokens: 512/max_tokens: 1024/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
<<<<<<< ours.yaml
temperature: 0.0
max_tokens: 512
=======
temperature: 0.2
max_tokens: 1024
>>>>>>> theirs.yaml
batch_size: 16
timeout_s: 30
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch08/why-conflicts/05-one-line-apart -->
```text
# ours changes line 2, theirs changes line 4: line 3 is unchanged on both sides.
$ sed 's/batch_size: 16/batch_size: 32/' base.yaml > theirs.yaml
$ git merge-file -p ours.yaml base.yaml theirs.yaml
model: judge-large-v2
temperature: 0.0
max_tokens: 512
batch_size: 32
timeout_s: 30
[exit status: 0]
```
<!-- /snippet -->

```text
Observed behavior : A conflict, although the two branches changed different lines.
Git state         : Ours changed line 2 of the file, theirs changed line 3.
Mechanism         : The merge works on hunks. Two hunks with no unchanged line between them
                    form one region, and that region was changed by both sides.
Root cause        : Adjacency. One unchanged line between the edits (the last transcript)
                    is enough to keep them apart.
Why Git does this : It needs a boundary between "independent" and "the same area", and an
                    unchanged line is the only evidence of independence that text offers.
Correct fix       : Take the changed line from each side: temperature 0.0 and max_tokens 1024.
Prevention        : None needed. Recognize the pattern and resolve it in seconds. Do not reach
                    for -X ours, which would drop their line.
```

**Picture.**

```text
  base lines         1    2    3    4    5
  ours changes            #
  theirs changes                         #    far apart: both applied
  theirs changes               #              touches ours: one region, conflict
  theirs changes                    #         one unchanged line between: both applied
```

What Git never does is conflict on meaning. Two changes that are textually far apart and logically incompatible merge without a word (section 8.15).

**In production.** Some files conflict far more often than others. A Jupyter notebook stores outputs and an execution counter next to the code, so two people who only ran the same notebook have changed the same lines, and a conflicted merge can leave a file that is no longer valid JSON ([nbdime](https://nbdime.readthedocs.io/en/latest/); [Chapter 28](ch28-ai-ml-workflows.md)). Append-only files are the other regular source: changelogs, migration lists, dependency lists. Every branch inserts after the same last line, which is the same region.

## 8.8 Anatomy of a conflict: working tree, index, `.git`

**In one sentence.** A conflicted merge is a merge that stopped halfway and wrote its unfinished state into three places: marker blocks in working tree files, up to three index entries per conflicted path, and a handful of files in `.git`.

**Analogy.** A customs desk. Everything that passed inspection is already through. Each contested parcel sits on the counter with three documents: the original declaration, your version and their version. The analogy breaks on time: nothing here expires until you conclude the merge or abort it.

**Precisely.** The manual lists what happens when a merge cannot complete ([git-merge](https://git-scm.com/docs/git-merge)):

1. "The `HEAD` pointer stays the same."
2. `MERGE_HEAD` is set to the other branch's tip.
3. Paths that merged cleanly are updated in the index and in the working tree.
4. For conflicting paths the index records up to three versions: "stage 1 stores the version from the common ancestor, stage 2 from `HEAD`, and stage 3 from `MERGE_HEAD`". The working tree files contain the merge result with conflict markers.
5. `AUTO_MERGE` points to a tree that matches what was written to the working tree.
6. Nothing else changes.

**Ours and theirs, exactly.** In a merge, ours is stage 2: the commit you were on when you typed `git merge`. Theirs is stage 3: the commit you named. It has nothing to do with who wrote what. If Asha checks out your branch and merges `main`, your commits are "ours" to her. During a rebase the roles are swapped relative to intuition ([Chapter 9](ch09-rebase.md)).

**See it.** You set the temperature to 0.0 on `main`. Asha set it to 0.7 on her branch, changed the seed in the same commit, and added a prompt line in another:

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

The exit status is 1. `git status` separates what is done from what is open:

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

`prompts/judge.txt` merged cleanly and is already staged. Only `config/eval.yaml` is unmerged. Its working tree copy:

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

Between `<<<<<<< HEAD` and `=======` is our version of the region, between `=======` and `>>>>>>> feature/creative-judge` is theirs. The last line, `seed: 1234`, is her seed change, merged outside the markers. A conflicted file is mostly finished. Only the marked regions are open.

The index holds the three whole files:

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

The third column is the stage. Merged paths are at stage 0. The conflicted path has no stage 0 entry and three others. The syntax `:<stage>:<path>` names those blobs, so any command that reads objects can read them:

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

Those two diffs, base to ours and base to theirs, are the most useful commands in conflict resolution: they show what each side intended. Here they reveal something the marker block did not: their side changed two lines, ours one.

**Inside `.git`.**

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

`MERGE_HEAD` is the commit being merged. It is what will make the next commit a merge commit. HEAD has not moved, and `ORIG_HEAD` equals it. `MERGE_MSG` is the prepared message, with the conflicted paths as a comment. `MERGE_MODE` is empty unless you passed `--no-ff`. `AUTO_MERGE` is a tree, the snapshot of what Git wrote to the working tree, markers included. During a conflict `git diff` prints a combined diff, one column per side:

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

The first column compares the working tree file with ours (stage 2), the second with theirs (stage 3). A `+` in both columns marks a line that neither side has, which here means the marker lines. `git diff --ours`, `--theirs` and `--base` compare the working tree file with one stage in the ordinary two-way format.

While the merge is open, Git refuses the two things that would lose track of it:

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

**Picture.**

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

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git merge <other>` that stops on a conflict 🟡 | clean paths updated; conflicted files rewritten with marker blocks | clean paths staged at stage 0; conflicted paths at stages 1, 2, 3 | unchanged | unchanged | `MERGE_HEAD`, `MERGE_MSG`, `MERGE_MODE`, `AUTO_MERGE` created; `ORIG_HEAD` set; new blobs and trees; no commit | unchanged | unchanged |

**In production.** `git mergetool` hands the three stage versions to an external tool chosen by `merge.tool`, and IDE merge editors work from the same stages. When a tool and the command line seem to disagree, `git ls-files -u` is the ground truth.

## 8.9 Conflict styles: `merge`, `diff3`, `zdiff3`

**In one sentence.** The conflict style decides how much of the three versions is written between the markers: `merge` shows ours and theirs, `diff3` adds the base, and `zdiff3` adds the base while moving lines that both sides share at the edges out of the block.

**Precisely.** `merge.conflictStyle` selects the style, and `merge` is the default. `git checkout --conflict=<style> <path>` and `git restore --conflict=<style> <path>` rewrite one conflicted file in another style from the index stages, without repeating the merge.

**See it.** Both branches added the same guard against missing predictions and then changed the comparison differently. In the default style:

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

Two candidate lines and no hint of what the line was before. Did one side add `.strip()` and the other `.lower()`, or did someone remove something? In `diff3` style the section after `|||||||` is the base:

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

Now the base is visible, and it settles the question: the original compared `pred == gold`, so each side added one normalization and the right answer applies both. The price is a larger block. The guard lines that both sides added identically are inside the conflict, twice. `zdiff3` keeps the base and removes that noise:

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

The labels changed to `ours`, `base` and `theirs` because these two files were rebuilt from index stages, and stages carry no branch names. A fresh merge with the setting in place labels the base with its abbreviated commit ID:

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

**Picture.**

```text
  <<<<<<< HEAD                         our version starts      (stage 2)
  ||||||| 6ae3c51                      base version starts     (stage 1; the label is the merge base)
  =======                              their version starts    (stage 3)
  >>>>>>> feature/case-insensitive     end of the block
```

**How to read a three-part block.** Compare each side with the base, not the sides with each other. A side that equals the base did nothing in this region: take the other side. An empty base means both sides added text at the same place: usually keep both. Two sides that each differ from the base are two intents, and you need to serve both.

**In production.** Set `git config set --global merge.conflictStyle zdiff3` once. The setting changes only how conflicts are written to your working tree and nothing that is committed, so it is a personal choice, not a team decision. The one thing to check is tooling that parses conflict markers, which must accept the `|||||||` section. Lab 6.7 is a conflict that cannot be resolved correctly without the base.

## 8.10 The resolution workflow

**Step 1: see what is open.** `git status`, or `git diff --name-only --diff-filter=U` for only the unmerged paths.

**Step 2: learn both intents.** Resolving a conflict is an investigation, not an editing chore. The stage diffs of section 8.8 show what changed. `git log --merge` shows why: it lists the commits from either side that touch a conflicted path.

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

Of Asha's two commits, only the one that touched `config/eval.yaml` is listed. Add `-p` to see the patches. If the intent is still unclear, ask the author.

**Step 3: write the result.** Edit the file until it says what the merged project should say, and delete the marker lines. The answer may be one side, both sides, or new text. Here the release requirement is reproducible scores, so the temperature stays at 0.0:

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

`git diff AUTO_MERGE` compares your file with what Git left behind, so it shows exactly what your resolution did: removed three marker lines and their candidate.

**Step 4: mark it resolved.** `git add` on an unmerged path replaces stages 1 to 3 with one stage 0 entry:

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

`git add` does not check your work. It stages whatever is in the file, markers included (section 8.19). Run the tests now, and run `git diff --cached --check`, which reports leftover markers.

**Step 5: conclude.** `git merge --continue` checks that a merge is in progress and then runs `git commit`. Plain `git commit` does the same job. Use the message to record the decision:

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

The `MERGE_*` files are gone. The stat is relative to the first parent: it shows what the merge brought to `main`.

**Whole-file shortcuts.** `git restore --ours <path>` and `git restore --theirs <path>` write stage 2 or stage 3 to the working tree. They take the whole file, not the conflicted hunks:

<!-- snippet: ch08/restore-sides/01-ours -->
```text
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
$ grep -n -e '<<<' -e temperature -e '>>>' -e seed config/eval.yaml
2:<<<<<<< HEAD
3:temperature: 0.0
5:temperature: 0.7
6:>>>>>>> feature/creative-judge
11:seed: 1234
$ git restore --ours config/eval.yaml
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.0
7:seed: 7
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
```
<!-- /snippet -->

After `--ours` the seed is 7 again. Asha's non-conflicting change in this file is gone from the working tree, and if you stage this, from the merge. The path is still `UU` because the index was not touched.

<!-- snippet: ch08/restore-sides/02-theirs -->
```text
$ git restore --theirs config/eval.yaml
$ grep -n -e temperature -e seed config/eval.yaml
2:temperature: 0.7
7:seed: 1234
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
```
<!-- /snippet -->

`git restore --merge <path>` rebuilds the marker version from the stages. It is the undo for both shortcuts and for a botched edit:

<!-- snippet: ch08/restore-sides/03-merge -->
```text
$ git restore --merge config/eval.yaml
$ grep -n -e '<<<' -e temperature -e '>>>' -e seed config/eval.yaml
2:<<<<<<< ours
3:temperature: 0.0
5:temperature: 0.7
6:>>>>>>> theirs
11:seed: 1234
```
<!-- /snippet -->

Older scripts use `git checkout` for the same three operations:

<!-- snippet: ch08/restore-sides/04-checkout -->
```text
$ git checkout --ours config/eval.yaml
Updated 1 path from the index
$ git checkout --theirs config/eval.yaml
Updated 1 path from the index
$ git checkout --merge config/eval.yaml
Recreated 1 merge conflict
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
```
<!-- /snippet -->

`--merge` also works after `git add`. The index keeps a record of the stages that the resolution replaced:

<!-- snippet: ch08/restore-sides/05-unresolve -->
```text
# Take their whole file, stage it, then change your mind.
$ git restore --theirs config/eval.yaml
$ git add config/eval.yaml
$ git status --short
M  config/eval.yaml
M  prompts/judge.txt
$ git ls-files -s config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 0	config/eval.yaml
$ git restore --merge config/eval.yaml
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
$ git ls-files -s config/eval.yaml
100644 c5b33275d88c041381cff59f23d3cd88b9f22c98 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 3	config/eval.yaml
```
<!-- /snippet -->

**The three exits.** `--continue` needs every path resolved:

<!-- snippet: ch08/abort-continue-quit/01-continue-too-early -->
```text
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --continue
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
U	config/eval.yaml
[exit status: 128]
```
<!-- /snippet -->

`--abort` returns to the state before the merge. The manual defines it as `git reset --merge` while `MERGE_HEAD` exists, and the reflog shows the reset:

<!-- snippet: ch08/abort-continue-quit/02-abort -->
```text
$ git merge --abort
$ git status --short --branch
## main
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
$ git reflog -2
5397d5f HEAD@{0}: reset: moving to HEAD
5397d5f HEAD@{1}: commit: Use temperature 0 for reproducible evals
```
<!-- /snippet -->

Outside a merge, both commands say so:

<!-- snippet: ch08/abort-continue-quit/03-nothing-in-progress -->
```text
$ git merge --abort
fatal: There is no merge to abort (MERGE_HEAD missing).
[exit status: 128]
$ git merge --continue
fatal: There is no merge in progress (MERGE_HEAD missing).
[exit status: 128]
```
<!-- /snippet -->

`--quit` is the odd one. It deletes the merge state and leaves the index and the working tree as they are:

<!-- snippet: ch08/abort-continue-quit/04-quit -->
```text
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --quit
[exit status: 0]
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   prompts/judge.txt

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   config/eval.yaml
```
<!-- /snippet -->

<!-- snippet: ch08/abort-continue-quit/05-after-quit -->
```text
# The merge is forgotten, the half-merged files are not. A commit made now has ONE parent:
$ git add config/eval.yaml
$ git commit -q -m "Resolve temperature conflict"
$ git log --oneline --graph --all
* cdacf6e Resolve temperature conflict
* 5397d5f Use temperature 0 for reproducible evals
| * 45a7a67 Ask the judge for a rationale
| * 640bfe1 Raise temperature and reseed for judge diversity
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git branch --no-merged
  feature/creative-judge
```
<!-- /snippet -->

Without `MERGE_HEAD` the commit has one parent. The content of Asha's branch is in `main`, but her commits are not ancestors of it, so the branch still counts as unmerged. To get the pre-merge state back after `--quit`, use `git reset --merge` 🔴:

<!-- snippet: ch08/abort-continue-quit/06-quit-cleanup -->
```text
# The clean way back after --quit: reset the index and the files the merge touched.
$ git merge --quit
$ git merge --abort
fatal: There is no merge to abort (MERGE_HEAD missing).
[exit status: 128]
$ git reset --merge
$ git status --short --branch
## main
```
<!-- /snippet -->

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git restore --ours <path>` or `--theirs <path>` 🔴 | file overwritten with the whole stage 2 or stage 3 version; your edits to it are lost | unchanged (path stays unmerged) | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git restore --merge <path>` 🔴 | file overwritten with a fresh marker version; your edits to it are lost | stages 1 to 3 restored if the path was already staged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git add <path>` on an unmerged path 🟢 | unchanged | stages 1 to 3 replaced by one stage 0 entry with the file's content | unchanged | unchanged | new blob | unchanged | unchanged |
| `git merge --continue` 🟡 | unchanged | unchanged | still `ref: refs/heads/main` | moves to the new merge commit | merge commit and trees written; `MERGE_*` and `AUTO_MERGE` removed; reflogs gain `commit (merge)` | unchanged | unchanged |
| `git merge --abort` 🔴 | merge results removed; files as before the merge, with the exceptions of section 8.19 | reset to HEAD | unchanged | unchanged | `MERGE_*` and `AUTO_MERGE` removed; reflog gains `reset: moving to HEAD` | unchanged | unchanged |
| `git merge --quit` 🟡 | unchanged | unchanged, still unmerged | unchanged | unchanged | `MERGE_*` and `AUTO_MERGE` removed | unchanged | unchanged |

**In production.** The merge commit message is the only place where a resolution can explain itself. One sentence there answers the question that somebody will ask in six months.

## 8.11 Conflict types beyond content

The word in parentheses after `CONFLICT` names the type. Only some types put markers in a file. The table collects what the transcripts of this section show:

| Type | `git status --short` | Stages present | Working tree after the merge stops | Resolve with |
|---|---|---|---|---|
| content | `UU` | 1, 2, 3 | file with marker blocks | edit, `git add` |
| add/add | `AA` | 2, 3 | file with one block holding both whole files | edit or choose, `git add` |
| modify/delete | `UD` (deleted by them) or `DU` (deleted by us) | 1 and the modifying side | the modified version, no markers | `git add` to keep, `git rm` to delete |
| rename/rename | `DD` old name, `AU` our name, `UA` their name | one stage per path | both new files | `git add` one name, `git rm` the other two |
| rename/delete | `UD` on the new name | 1, 2 | the renamed file | `git add` or `git rm` |
| binary (reported as content) | `UU` | 1, 2, 3 | our version, no markers | pick a stage or regenerate, `git add` |
| file/directory | `AU` on a renamed path | 2 | the file moved aside, the directory in place | rename, `git add`, `git rm` |
| file location | `UA` on the suggested path | 3 | the file at the suggested path | `git add` to accept, or move it |

**add/add.** Both branches create the same path with different content. There is no stage 1, because there was no common version:

<!-- snippet: ch08/conflict-add-add/01-merge -->
```text
$ git merge feature/disk-cache
Auto-merging evalkit/cache.py
CONFLICT (add/add): Merge conflict in evalkit/cache.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
AA evalkit/cache.py
$ git ls-files -u
100644 7f040298ad3ac9af50f69563114d5f3f5fff3576 2	evalkit/cache.py
100644 8d7d969205f3f1edf8a7f316f04e2481e6df6a31 3	evalkit/cache.py
$ git show :1:evalkit/cache.py
fatal: path 'evalkit/cache.py' is in the index, but not at stage 1
hint: Did you mean ':2:evalkit/cache.py'?
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch08/conflict-add-add/02-file -->
```text
$ cat evalkit/cache.py
<<<<<<< HEAD
_CACHE = {}


def load(key):
    return _CACHE.get(key)
=======
import json


def load(path):
    with open(path) as f:
        return json.load(f)
>>>>>>> feature/disk-cache
```
<!-- /snippet -->

Two modules with the same name are usually two answers to one need. The resolution is a design conversation.

**modify/delete.** One side edited a file, the other deleted it. Git keeps the edited version in the working tree and waits:

<!-- snippet: ch08/conflict-modify-delete/01-merge -->
```text
$ git merge cleanup/remove-legacy
CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in cleanup/remove-legacy and modified in HEAD.  Version HEAD of scripts/legacy_eval.sh left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add/rm <file>..." as appropriate to mark resolution)
	deleted by them: scripts/legacy_eval.sh

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ch08/conflict-modify-delete/02-stages -->
```text
$ git status --short
UD scripts/legacy_eval.sh
$ git ls-files -u
100644 4a41a25aa3c40cf94e023b2f4e69974e8d1b0e5f 1	scripts/legacy_eval.sh
100644 26610f62ce9e5b2744199a6dd9e966eb004ca890 2	scripts/legacy_eval.sh
$ ls scripts
legacy_eval.sh
```
<!-- /snippet -->

Stage 3 does not exist: "their version" is no file. The whole-file shortcuts behave inconsistently here:

<!-- snippet: ch08/conflict-modify-delete/03-restore-vs-checkout -->
```text
# Stage 3 does not exist for this path. The two commands react differently:
$ git checkout --theirs scripts/legacy_eval.sh
error: path 'scripts/legacy_eval.sh' does not have their version
[exit status: 1]
$ git restore --theirs scripts/legacy_eval.sh
[exit status: 0]
$ test -f scripts/legacy_eval.sh
[exit status: 1]
$ git status --short
UD scripts/legacy_eval.sh
$ git restore --ours scripts/legacy_eval.sh
$ test -f scripts/legacy_eval.sh
[exit status: 0]
$ git restore --merge scripts/legacy_eval.sh
error: path 'scripts/legacy_eval.sh' does not have all necessary versions
[exit status: 1]
```
<!-- /snippet -->

`git checkout --theirs` refuses. `git restore --theirs` succeeds silently and removes the file from the working tree: restoring "their version" of a path that they deleted means deleting it. Neither marks the path as resolved. From the branch that did the deleting, the same conflict is `DU`:

<!-- snippet: ch08/conflict-modify-delete/04-deleted-by-us -->
```text
$ git merge main
CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in HEAD and modified in main.  Version main of scripts/legacy_eval.sh left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
DU scripts/legacy_eval.sh
$ git ls-files -u
100644 4a41a25aa3c40cf94e023b2f4e69974e8d1b0e5f 1	scripts/legacy_eval.sh
100644 26610f62ce9e5b2744199a6dd9e966eb004ca890 3	scripts/legacy_eval.sh
# Decision on this branch: keep the edited file.
$ git add scripts/legacy_eval.sh
$ git status --short
A  scripts/legacy_eval.sh
```
<!-- /snippet -->

The resolution is `git add` (the file lives) or `git rm` (the deletion stands):

<!-- snippet: ch08/conflict-modify-delete/05-resolve-delete -->
```text
# Back on main, same conflict as in the first snippet. Decision: the deletion wins.
$ git rm scripts/legacy_eval.sh
rm 'scripts/legacy_eval.sh'
$ git status --short
D  scripts/legacy_eval.sh
$ git merge --continue
[main 7e2950a] Merge branch 'cleanup/remove-legacy'
$ git ls-files
config/eval.yaml
evalkit/metrics.py
prompts/judge.txt
```
<!-- /snippet -->

The question is not "which file wins" but "why was it deleted, and does the edit need a new home?" Lab 6.4 is such a case.

**Renames.** Git does not record renames ([Chapter 4](ch04-working-tree.md)). The merge detects them by comparing content, with the same 50% similarity threshold as `git diff`. When detection succeeds, a rename on one side and an edit on the other is no conflict at all:

<!-- snippet: ch08/conflict-rename/01-rename-edit -->
```text
$ git log --oneline --graph --all
* e5b08ff Strip whitespace before comparing
| * 727adba Rename the metrics module to scoring
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge refactor/scoring-module
Merge made by the 'ort' strategy.
 evalkit/{metrics.py => scoring.py} | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename evalkit/{metrics.py => scoring.py} (100%)
$ git ls-files evalkit
evalkit/scoring.py
$ head -2 evalkit/scoring.py
def exact_match(pred, gold):
    return float(pred.strip() == gold.strip())
```
<!-- /snippet -->

Your edit to `metrics.py` arrived in `scoring.py`. Two different renames of the same file do conflict, and three paths need an answer:

<!-- snippet: ch08/conflict-rename/02-rename-rename -->
```text
$ git merge refactor/scorers
CONFLICT (rename/rename): evalkit/metrics.py renamed to evalkit/scoring.py in HEAD and to evalkit/scorers.py in refactor/scorers.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
DD evalkit/metrics.py
UA evalkit/scorers.py
AU evalkit/scoring.py
$ git ls-files -u
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 1	evalkit/metrics.py
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 3	evalkit/scorers.py
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 2	evalkit/scoring.py
$ ls evalkit
scorers.py
scoring.py
```
<!-- /snippet -->

<!-- snippet: ch08/conflict-rename/03-rename-rename-resolve -->
```text
# Decision: the module is called scoring. All three paths need an answer.
$ git add evalkit/scoring.py
$ git rm evalkit/scorers.py
rm 'evalkit/scorers.py'
$ git rm evalkit/metrics.py
rm 'evalkit/metrics.py'
$ git status --short
$ git merge --continue
[main 02943f6] Merge branch 'refactor/scorers'
$ git ls-files evalkit
evalkit/scoring.py
```
<!-- /snippet -->

A rename against a deletion of the same file is reported under the new name:

<!-- snippet: ch08/conflict-rename/04-rename-delete -->
```text
$ git merge cleanup/drop-metrics
CONFLICT (rename/delete): evalkit/metrics.py renamed to evalkit/scoring.py in HEAD, but deleted in cleanup/drop-metrics.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UD evalkit/scoring.py
$ git ls-files -u
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 1	evalkit/scoring.py
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 2	evalkit/scoring.py
```
<!-- /snippet -->

The dangerous case is a rename that Git does not recognize. Ravi moved `metrics.py` to `scoring.py` and rewrote most of it in the same commit. Only 39% of the content survived:

<!-- snippet: ch08/conflict-rename/05-below-threshold -->
```text
$ git diff --summary main...refactor/score-objects
 delete mode 100644 evalkit/metrics.py
 create mode 100644 evalkit/scoring.py
$ git diff --summary --find-renames=30% main...refactor/score-objects
 rename evalkit/{metrics.py => scoring.py} (39%)
$ git merge refactor/score-objects
CONFLICT (modify/delete): evalkit/metrics.py deleted in refactor/score-objects and modified in HEAD.  Version HEAD of evalkit/metrics.py left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UD evalkit/metrics.py
A  evalkit/scoring.py
```
<!-- /snippet -->

```text
Observed behavior : CONFLICT (modify/delete) on evalkit/metrics.py, although nobody decided to
                    delete the module. The new evalkit/scoring.py is staged without your edit.
Git state         : Theirs has no metrics.py and a scoring.py that shares 39% of its content.
Mechanism         : Rename detection pairs a deleted path with an added path only when their
                    similarity reaches the threshold, 50% by default. Below that, Git sees a
                    deletion and an addition.
Root cause        : A move and a rewrite in one commit. The snapshot holds no rename, only two
                    paths with different content.
Why Git does this : Trees store names and blob IDs. A rename is an inference from similarity,
                    and every inference needs a cutoff.
Correct fix       : Abort and merge again with -X find-renames=30%, or port your edit into the
                    new file by hand and git rm the old path.
Prevention        : Land the move as its own change and merge it into every open branch before
                    the rewrite starts. Two commits on one branch are not enough for the
                    merge, which compares only the tips, though they keep git log --follow
                    working.
```

With a lower threshold the same merge becomes a content conflict inside the new file, which is the conflict you can reason about:

<!-- snippet: ch08/conflict-rename/06-find-renames -->
```text
$ git merge --abort
$ git merge -X find-renames=30% refactor/score-objects
Auto-merging evalkit/scoring.py
CONFLICT (content): Merge conflict in evalkit/scoring.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
D  evalkit/metrics.py
UU evalkit/scoring.py
$ grep -n -B1 -A5 '<<<<<<<' evalkit/scoring.py
11-def exact_match(pred, gold):
12:<<<<<<< HEAD:evalkit/metrics.py
13-    return float(pred.strip() == gold.strip())
14-=======
15-    return Score("exact_match", float(pred == gold))
16->>>>>>> refactor/score-objects:evalkit/scoring.py
17-
```
<!-- /snippet -->

The labels now include paths, `HEAD:evalkit/metrics.py` against `refactor/score-objects:evalkit/scoring.py`, because the two sides know the file under different names.

**Binary files.** Git cannot merge them line by line. It reports a content conflict, records all three stages, leaves your version in the working tree and writes no markers:

<!-- snippet: ch08/conflict-binary/01-merge -->
```text
$ git merge feature/new-palette
warning: Cannot merge binary files: reports/confusion.png (HEAD vs. feature/new-palette)
Auto-merging reports/confusion.png
CONFLICT (content): Merge conflict in reports/confusion.png
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU reports/confusion.png
$ git ls-files -u
100644 ba14cea3b6767bd483472d2b9ba04134aef2afae 1	reports/confusion.png
100644 32a12ecade27b0c495b09a683cd0c12510e81468 2	reports/confusion.png
100644 c4a999a147a8710d34a4971df06840aaca348ba5 3	reports/confusion.png
$ git diff
diff --cc reports/confusion.png
index 32a12ec,c4a999a..0000000
Binary files differ
```
<!-- /snippet -->

<!-- snippet: ch08/conflict-binary/02-which-version -->
```text
# The working tree file is our version (stage 2), byte for byte:
$ git hash-object reports/confusion.png
32a12ecade27b0c495b09a683cd0c12510e81468
```
<!-- /snippet -->

<!-- snippet: ch08/conflict-binary/03-resolve -->
```text
# Decision: regenerate later; for now take their file.
$ git restore --theirs reports/confusion.png
$ git hash-object reports/confusion.png
c4a999a147a8710d34a4971df06840aaca348ba5
$ git status --short
UU reports/confusion.png
$ git add reports/confusion.png
$ git status --short
M  reports/confusion.png
$ git merge --continue
[main 4d7fbd3] Merge branch 'feature/new-palette'
```
<!-- /snippet -->

For a generated artifact the honest resolution is to regenerate it from the merged sources. Text files that must never be merged line by line, such as lock files, can be given the same treatment with the `merge` attribute (`-merge` or `merge=binary` in `.gitattributes`; Chapter 14C).

**File against directory.** One branch adds a file named `docs`, the other a directory named `docs`. Both cannot exist, so Git moves the file aside under a name that says where it came from:

<!-- snippet: ch08/conflict-file-directory/01-merge -->
```text
$ git merge feature/docs-directory
CONFLICT (file/directory): directory in the way of docs from HEAD; moving it to docs~HEAD instead.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
D  docs
A  docs/calibration.md
AU docs~HEAD
$ git ls-files -s docs docs~HEAD
100644 37cc29f51e7d512294b921cadd0f36e408ede85a 0	docs/calibration.md
100644 7ef0c38ff113fe6b29f348c4cce89653ba08aac7 2	docs~HEAD
```
<!-- /snippet -->

**Directory renames.** You moved the package under `src/`. Meanwhile Asha added a new file in the old directory. Git notices that the directory was renamed and asks:

<!-- snippet: ch08/conflict-directory-rename/01-merge -->
```text
$ git diff --name-status feature/cache...main
R100	evalkit/__init__.py	src/evalkit/__init__.py
R100	evalkit/metrics.py	src/evalkit/metrics.py
R100	evalkit/report.py	src/evalkit/report.py
$ git diff --name-status main...feature/cache
A	evalkit/cache.py
$ git merge feature/cache
CONFLICT (file location): evalkit/cache.py added in feature/cache inside a directory that was renamed in HEAD, suggesting it should perhaps be moved to src/evalkit/cache.py.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UA src/evalkit/cache.py
$ git ls-files -u
100644 7f040298ad3ac9af50f69563114d5f3f5fff3576 3	src/evalkit/cache.py
$ ls src/evalkit
__init__.py
cache.py
metrics.py
report.py
```
<!-- /snippet -->

There are no markers and only one stage. The file is already at the suggested path, so accepting is one command:

<!-- snippet: ch08/conflict-directory-rename/02-resolve -->
```text
# Git has already written the file where it suggests. Accepting the suggestion is one command:
$ git add src/evalkit/cache.py
$ git status --short
A  src/evalkit/cache.py
$ git merge --continue
[main d1b5f4e] Merge branch 'feature/cache'
$ git ls-files src
src/evalkit/__init__.py
src/evalkit/cache.py
src/evalkit/metrics.py
src/evalkit/report.py
```
<!-- /snippet -->

`merge.directoryRenames` controls this. Its default is `conflict`. The other two values act without asking:

<!-- snippet: ch08/conflict-directory-rename/03-config -->
```text
# The same merge with merge.directoryRenames=true does not stop:
$ git -c merge.directoryRenames=true merge feature/cache
Path updated: evalkit/cache.py added in feature/cache inside a directory that was renamed in HEAD; moving it to src/evalkit/cache.py.
Merge made by the 'ort' strategy.
 src/evalkit/cache.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 src/evalkit/cache.py
# With merge.directoryRenames=false the new file stays in the old directory, without a word:
$ git -c merge.directoryRenames=false merge feature/cache
Merge made by the 'ort' strategy.
 evalkit/cache.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 evalkit/cache.py
$ git ls-files evalkit src
evalkit/cache.py
src/evalkit/__init__.py
src/evalkit/metrics.py
src/evalkit/report.py
```
<!-- /snippet -->

With `false` the merge is clean and wrong: `evalkit/cache.py` sits in a directory that no longer contains the package. The default costs one `git add`.

**In production.** Refactoring branches are where these types appear together. Announce large moves, land them quickly, and merge them into open feature branches the same day.

## 8.12 Controlling the result: `--ff-only`, `--no-ff`, `--no-commit`, `--squash`

**In one sentence.** Four options decide whether a merge creates a commit, what kind, and when; `merge.ff` can make `--no-ff` or `--ff-only` the default.

| Option | When a fast-forward is possible | When the branches have diverged |
|---|---|---|
| none (`--ff`) | fast-forward | merge commit |
| `--no-ff` | merge commit | merge commit |
| `--ff-only` | fast-forward | refuses; nothing moves; exit status 128 |
| `--no-commit` | fast-forward (the option has no effect) | stops before committing, as if a conflict had been resolved |
| `--squash` | stages the result; no commit; no `MERGE_HEAD` | the same |

**`--no-ff`** forces a merge commit where a fast-forward would do. The branch stays visible in the graph and can be reverted as one unit:

<!-- snippet: ch08/merge-flags/01-no-ff -->
```text
# main is an ancestor of feature/rationale, so a plain merge would fast-forward.
$ git merge --no-ff feature/rationale
Merge made by the 'ort' strategy.
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
$ git log --oneline --graph
*   ec7d2b5 Merge branch 'feature/rationale'
|\  
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

**`--no-commit`** is meant to let you inspect a merge before it is recorded. Alone, it does not stop a fast-forward. The manual says so directly: "there is no way to stop those merges with `--no-commit`".

<!-- snippet: ch08/merge-flags/02-no-commit-fast-forwards -->
```text
$ git merge --no-commit feature/rationale
Updating 6ae3c51..58a5e60
Fast-forward
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
$ git log --oneline --graph
* 58a5e60 Ask the judge to quote evidence
* 5aec6e0 Ask the judge for a rationale
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

Combined with `--no-ff` it stops reliably. The state is that of a merge whose conflicts are all resolved: `MERGE_HEAD` exists, HEAD has not moved, and `MERGE_MODE` remembers `no-ff`.

<!-- snippet: ch08/merge-flags/03-no-commit -->
```text
$ git merge --no-ff --no-commit feature/rationale
Automatic merge went well; stopped before committing as requested
$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	modified:   prompts/judge.txt

$ ls .git | grep -E 'MERGE|ORIG_HEAD'
AUTO_MERGE
MERGE_HEAD
MERGE_MODE
MERGE_MSG
ORIG_HEAD
$ cat .git/MERGE_MODE; echo
no-ff
$ git log --oneline -1
6ae3c51 Add eval config, judge prompt and metrics
$ git merge --abort
```
<!-- /snippet -->

**`--ff-only`** is the safe way to bring a branch up to date. Either it fast-forwards or it moves nothing:

<!-- snippet: ch08/merge-flags/04-ff-only -->
```text
$ git log --oneline --graph --all
* d80b525 Use temperature 0 for reproducible evals
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge --ff-only feature/rationale
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
$ git status --short --branch
## main
```
<!-- /snippet -->

**`--squash`** computes the same result as a merge and then deliberately forgets that it was one:

<!-- snippet: ch08/merge-flags/05-squash -->
```text
$ git merge --squash feature/rationale
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   prompts/judge.txt

$ ls .git | grep -E 'MERGE|ORIG_HEAD|SQUASH'
AUTO_MERGE
ORIG_HEAD
SQUASH_MSG
$ head -3 .git/SQUASH_MSG
Squashed commit of the following:

commit 58a5e6004856ba05b88a2920c3684d15859a867b
```
<!-- /snippet -->

The index and the working tree hold the merge result. HEAD has not moved. There is no `MERGE_HEAD`, so `git merge --abort` has nothing to abort (the way back is `git reset --merge`). `SQUASH_MSG` is a draft message. The commit you make next is an ordinary one:

<!-- snippet: ch08/merge-flags/06-squash-commit -->
```text
$ git commit -q -m "Ask the judge for a rationale and for evidence"
$ git log --oneline --graph --all
* 4b0b1d4 Ask the judge for a rationale and for evidence
* d80b525 Use temperature 0 for reproducible evals
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git show -s --format="%h parents: %p" HEAD
4b0b1d4 parents: d80b525
$ git branch --no-merged
  feature/rationale
$ git branch -d feature/rationale
error: the branch 'feature/rationale' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/rationale'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

One parent. The content of the branch is in `main`; its commits are not, so `git branch -d` refuses to delete it here, where the branch has no upstream (with an upstream that still contains the branch, `-d` compares with that and deletes with a warning: [Chapter 7](ch07-branches.md), section 7.5). A squash merge transfers content without ancestry, the exact opposite of `-s ours`. That matters when the branch lives on:

<!-- snippet: ch08/merge-flags/07-squash-then-reuse -->
```text
# The squash commit recorded no second parent, so the merge base has not moved:
$ git log --oneline -1 $(git merge-base main feature/rationale)
6ae3c51 Add eval config, judge prompt and metrics
$ git merge --squash feature/rationale
Auto-merging prompts/judge.txt
CONFLICT (content): Merge conflict in prompts/judge.txt
Squash commit -- not updating HEAD
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat prompts/judge.txt
You are a strict grader.
Answer with PASS or FAIL.
<<<<<<< HEAD
Explain your verdict in one sentence.
=======
Explain your verdict in two sentences.
>>>>>>> feature/rationale
Quote the evidence you used.
```
<!-- /snippet -->

```text
Observed behavior : Squashing the same branch into main a second time conflicts on a line that
                    the first squash had already delivered.
Git state         : git merge-base main feature/rationale is still 6ae3c51, the original fork.
Mechanism         : The first squash commit has one parent, so no commit of the branch became an
                    ancestor of main. The second merge compares both tips with the old base
                    again: main "changed" the line (through the squash) and so did the branch.
Root cause        : Content was merged without ancestry, so the merge base never moved.
Why Git does this : The merge base is computed from parent links, and a squash writes none.
Correct fix       : Resolve the conflict in favour of the newer text. Then stop reusing the
                    branch.
Prevention        : One squash per branch: delete the branch afterwards and start the next one
                    from main. For branches that must live on, use real merge commits.
```

Git's FAQ makes the same recommendation: "if you want to merge two long-lived branches repeatedly, it's best to always use a regular merge commit" ([gitfaq](https://git-scm.com/docs/gitfaq)).

**Picture.**

```text
  git merge --no-ff feature           git merge --squash feature, then git commit

  A-----------M   main                A---S       main      S has one parent
   \         /                         \
    B-------C     feature               B---C     feature   still listed as not merged

  M and S record the same tree. Only M records where it came from.
```

**`merge.ff`** sets the default: `false` behaves like `--no-ff`, `only` like `--ff-only`.

<!-- snippet: ch08/merge-flags/08-merge-ff-config -->
```text
# docs/readme is one commit ahead of main. merge.ff=false behaves like --no-ff:
$ git -c merge.ff=false merge docs/readme
Merge made by the 'ort' strategy.
 README.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
# merge.ff=only behaves like --ff-only:
$ git -c merge.ff=only -c advice.diverging=false merge feature/rationale
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
```
<!-- /snippet -->

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git merge --no-ff --no-commit <other>` 🟡 | files updated to the merge result | merge result staged | unchanged | unchanged | `MERGE_HEAD`, `MERGE_MSG`, `MERGE_MODE` (`no-ff`), `AUTO_MERGE` created; `ORIG_HEAD` set | unchanged | unchanged |
| `git merge --squash <other>` 🟡 | files updated to the merge result (with markers on conflict) | merge result staged | unchanged | unchanged | `SQUASH_MSG` created; `ORIG_HEAD` set; no `MERGE_HEAD` | unchanged | unchanged |
| `git merge --ff-only <other>` on diverged branches 🟢 | unchanged | unchanged | unchanged | unchanged | `ORIG_HEAD` rewritten with the current tip; nothing else | unchanged | unchanged |

> **GitHub, not Git.** The merge methods of a pull request map onto these options, but they run on GitHub's servers and are not identical to the local commands. The default method is documented as a merge "using the `--no-ff` option". For the squash method, GitHub's documentation carries the warning of the root-cause box above: if you keep working on the head branch, "later pull requests can include commits that were already squashed into the base branch" ([pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges)). Chapter 17 covers the merge methods.

**In production.** Habits that work: `--ff-only` to update your local `main`, so that a surprise divergence stops you; `--no-ff` to integrate a feature branch as one revertable unit; `--squash` when the branch history is noise, then delete the branch; `--no-ff --no-commit` to test the merged tree before it becomes a commit.

## 8.13 Anatomy of a merge commit and first-parent history

**In one sentence.** A merge commit is an ordinary commit object with more than one `parent` line, and the order of those lines records which branch received the merge.

**Analogy.** A river and a tributary. Downstream of the confluence there is one river, and the map still shows which channel was the main stream. The analogy breaks because in Git the "main stream" is not a property of a branch name: it is whichever commit was checked out when the merge was made.

**Precisely.** A merge commit stores a complete tree, like every commit. It stores no diff, no conflict record and no list of merged commits. Parent 1 is the commit HEAD pointed to when the merge was created. Parent 2 is the commit that was merged. `M^1` and `M^2` name them. `M^1..M^2` is the set of commits that the merge brought in, and `M^-` is shorthand for the same range plus M itself.

**Inside `.git`.** One commit object. No flag and no separate storage distinguishes a merge from any other commit.

**See it.**

<!-- snippet: ch08/merge-commit-anatomy/01-object -->
```text
$ git log --oneline --graph
* 630eac8 Raise batch size to 32
*   821b8ff Merge branch 'feature/rationale'
|\  
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
* | c089834 Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git cat-file -p 821b8ff
tree 3e976d90175716430f0495d15e71b1a0069e93e1
parent c089834537b955876054c69c0f4bfbe6230b0cb2
parent 58a5e6004856ba05b88a2920c3684d15859a867b
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

Merge branch 'feature/rationale'
```
<!-- /snippet -->

<!-- snippet: ch08/merge-commit-anatomy/02-parents -->
```text
$ git rev-parse --short 821b8ff^1
c089834
$ git rev-parse --short 821b8ff^2
58a5e60
# The commits that came in through the merge: reachable from parent 2, not from parent 1.
$ git log --oneline 821b8ff^1..821b8ff^2
58a5e60 Ask the judge to quote evidence
5aec6e0 Ask the judge for a rationale
# The same range plus the merge itself, with the ^- shorthand:
$ git log --oneline 821b8ff^-
821b8ff Merge branch 'feature/rationale'
58a5e60 Ask the judge to quote evidence
5aec6e0 Ask the judge for a rationale
```
<!-- /snippet -->

`git log --first-parent` follows only parent 1 at every merge. On a main branch that receives work through merges, this is the list of integrations, one line each:

<!-- snippet: ch08/merge-commit-anatomy/03-first-parent -->
```text
$ git log --oneline --first-parent
630eac8 Raise batch size to 32
821b8ff Merge branch 'feature/rationale'
c089834 Use temperature 0 for reproducible evals
6ae3c51 Add eval config, judge prompt and metrics
$ git log --oneline --merges
821b8ff Merge branch 'feature/rationale'
$ git log --oneline --no-merges
630eac8 Raise batch size to 32
c089834 Use temperature 0 for reproducible evals
58a5e60 Ask the judge to quote evidence
5aec6e0 Ask the judge for a rationale
6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

A merge commit has one diff per parent, and they answer different questions:

<!-- snippet: ch08/merge-commit-anatomy/04-diff-per-parent -->
```text
# What main gained from the merge:
$ git diff --stat 821b8ff^1 821b8ff
 prompts/judge.txt | 2 ++
 1 file changed, 2 insertions(+)
# What the feature branch would have gained from it:
$ git diff --stat 821b8ff^2 821b8ff
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

**Picture.**

```text
            5aec6e0---58a5e60             feature/rationale
           /                 \
  6ae3c51---c089834-----------821b8ff---630eac8   main   (HEAD -> main)

  821b8ff^1 = c089834   where main was when the merge was made
  821b8ff^2 = 58a5e60   what was merged
  git log --first-parent main:   630eac8, 821b8ff, c089834, 6ae3c51
```

**The first-parent flip.** "First parent" means "what was checked out", not "main". Watch what happens when someone merges `main` into a feature branch and then fast-forwards `main` to it:

<!-- snippet: ch08/merge-commit-anatomy/05-flip -->
```text
$ git log --oneline --first-parent -3 main
cfc99c8 Retry the judge three times
630eac8 Raise batch size to 32
821b8ff Merge branch 'feature/rationale'
$ git switch -q feature/httpx
$ git merge main
Merge made by the 'ort' strategy.
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git switch -q main
$ git merge feature/httpx
Updating cfc99c8..3f3fd07
Fast-forward
 requirements.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 requirements.txt
$ git log --oneline --graph -4
*   3f3fd07 Merge branch 'main' into feature/httpx
|\  
| * cfc99c8 Retry the judge three times
* | 042925e Add httpx for the judge client
|/  
* 630eac8 Raise batch size to 32
$ git log --oneline --first-parent -3 main
3f3fd07 Merge branch 'main' into feature/httpx
042925e Add httpx for the judge client
630eac8 Raise batch size to 32
```
<!-- /snippet -->

Before, the first-parent history of `main` contained "Retry the judge three times". Afterwards that commit is on the second-parent side and Ravi's branch commit sits on the mainline. Nothing is lost, but every tool that reads the mainline, `git log --first-parent`, `git bisect start --first-parent`, a changelog generator, now walks through the feature branch. The prevention is the pair of rules that most teams enforce anyway: integrate into `main` with `--no-ff` merges (GitHub's default merge method does this), and never fast-forward `main` to a branch that has merged `main`.

**In production.** On a team that merges pull requests, `git log --first-parent --oneline main` is the release history: one line per integrated unit, in the order it landed. When a deployment breaks, each line is a candidate for `git revert -m 1` (section 8.18).

## 8.14 Octopus merges

**In one sentence.** Naming several branches in one `git merge` creates a single commit with three or more parents, made by a separate strategy that refuses any conflict.

**See it.**

<!-- snippet: ch08/octopus/01-merge -->
```text
$ git merge topic/prompt topic/deps topic/docs
Trying simple merge with topic/prompt
Trying simple merge with topic/deps
Trying simple merge with topic/docs
Merge made by the 'octopus' strategy.
 README.md         | 2 ++
 prompts/judge.txt | 1 +
 requirements.txt  | 1 +
 3 files changed, 4 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch08/octopus/02-commit -->
```text
$ git log --oneline --graph
*---.   6cd1b13 Merge branches 'topic/prompt', 'topic/deps' and 'topic/docs'
|\ \ \  
| | | * 436e24c Document how to run
| | * | 6e9e321 Add httpx for the judge client
| | |/  
| * / f18e761 Ask the judge for a rationale
| |/  
* / 5ab7b4d Use temperature 0 for reproducible evals
|/  
* adad948 Add README and requirements
* 6ae3c51 Add eval config, judge prompt and metrics
$ git cat-file -p HEAD
tree 25553fcdd3840e13707bf49acc52fbfc81ef0fba
parent 5ab7b4d031080365343d89dcd529d514e9f9b01c
parent f18e7614e71850ee7b09c35e79b2e1a668d5f925
parent 6e9e3211e05899f0aa9598b4d578584f9189d724
parent 436e24c23d49f55d3231c8e61c555e6945411e92
author Lab User <you@example.com> 1788756420 +0530
committer Lab User <you@example.com> 1788756420 +0530

Merge branches 'topic/prompt', 'topic/deps' and 'topic/docs'
$ git reflog -1
6cd1b13 HEAD@{0}: merge topic/prompt topic/deps topic/docs: Merge made by the 'octopus' strategy.
```
<!-- /snippet -->

Four parents: your tip first, then the three branches in the order you named them. Now with a branch that touches the same line as `main`:

<!-- snippet: ch08/octopus/03-conflict -->
```text
# topic/temperature changes the same line as main.
$ git merge topic/prompt topic/temperature topic/docs
Trying simple merge with topic/prompt
Trying simple merge with topic/temperature
Simple merge did not work, trying automatic merge.
Auto-merging config/eval.yaml
ERROR: content conflict in config/eval.yaml
fatal: merge program failed
Automated merge did not work.
Should not be doing an octopus.
Merge with strategy octopus failed.
[exit status: 2]
$ git status --short --branch
## main
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
ORIG_HEAD
```
<!-- /snippet -->

Exit status 2, no `MERGE_HEAD`, a clean status. An octopus merge that hits a conflict is rolled back, not paused. Merge the conflicting branch separately, resolve it, and bundle the rest.

**In production.** The octopus fits one job: bundling independent, conflict-free topic branches, such as documentation and dependency bumps, into an integration branch. It has costs: the audit command of section 8.16 skips it, and `git revert -m` has to choose among more than two parents. Most application teams never need it.

## 8.15 Clean for Git, wrong for humans

**In one sentence.** A merge without conflicts means that no two text changes overlapped; it says nothing about whether the result builds, passes its tests or makes sense.

**Analogy.** A spell-checker passes two paragraphs that contradict each other, because every word is spelled correctly. The analogy breaks only in degree: Git checks even less, one property, the overlap of changed lines.

**Semantic conflicts.** Ravi renames `accuracy()` to `mean_score()` and updates the only caller he can see. Asha, from the same starting commit, adds a new module that calls `accuracy()`. A shell script stands in for the test suite: it fails when a module imports a name that `metrics.py` does not define.

<!-- snippet: ch08/clean-but-wrong/01-both-merge-cleanly -->
```text
$ git log --oneline --graph --all
* 5008877 Add a leaderboard ranked by accuracy
| * d1c3cff Rename accuracy() to mean_score()
|/  
* 68c652c Add the report module and the import check
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge -q refactor/mean-score
$ git merge feature/leaderboard
Merge made by the 'ort' strategy.
 evalkit/leaderboard.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 evalkit/leaderboard.py
```
<!-- /snippet -->

<!-- snippet: ch08/clean-but-wrong/02-check-fails -->
```text
$ sh ci/check_imports.sh
FAIL evalkit/leaderboard.py imports accuracy, which evalkit/metrics.py does not define
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch08/clean-but-wrong/03-parents-pass -->
```text
# The same check on each parent of the merge commit:
$ git switch -q --detach main^1 && sh ci/check_imports.sh
OK every import from evalkit.metrics resolves
$ git switch -q --detach main^2 && sh ci/check_imports.sh
OK every import from evalkit.metrics resolves
$ git switch -q main
```
<!-- /snippet -->

Both parents pass. The merge fails. The reason is visible when you list what each side changed:

<!-- snippet: ch08/clean-but-wrong/04-no-path-in-common -->
```text
# Paths each side changed since the merge base:
$ git diff --name-only main^2...main^1
evalkit/metrics.py
evalkit/report.py
$ git diff --name-only main^1...main^2
evalkit/leaderboard.py
```
<!-- /snippet -->

```text
Observed behavior : Two green branches, a merge without conflict, a red merge commit.
Git state         : The sides changed disjoint paths: metrics.py and report.py on one,
                    leaderboard.py on the other.
Mechanism         : By the rule table, a path changed on one side only is taken as it is.
                    No file-level merge ran. There was nothing for Git to compare.
Root cause        : The dependency between the two changes, a renamed function and a new
                    caller of the old name, lives in the Python import system, not in the
                    text of any one file.
Why Git does this : Git merges snapshots of text. It has no parser, no type checker and no
                    test runner, for any language.
Correct fix       : Update the caller, in a commit on top of the merge (below) or inside the
                    merge commit (see "Evil merges").
Prevention        : Test the merge result before it reaches main: CI on the pull request's
                    merge commit, plus a rule that the branch is up to date with main, or a
                    merge queue (Chapter 18).
```

<!-- snippet: ch08/clean-but-wrong/05-fix -->
```text
# The repair is a normal, reviewable commit on top of the merge.
$ git diff --stat
 evalkit/leaderboard.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git commit -q -a -m "Use mean_score() in the leaderboard"
$ sh ci/check_imports.sh
OK every import from evalkit.metrics resolves
```
<!-- /snippet -->

The quiet variant is worse than the loud one. If one branch renames a configuration key and another adds code that reads the old key with a default, nothing fails. An evaluation run uses the default, the scores shift, and the merge that caused it shows no conflict and no red check. Lab 6.5 is a third form: two migrations with the same number.

**Changed on both sides, reverted on one.** A fix is applied to `main` and to a branch. `main` then reverts it, for a good reason. The branch is merged:

<!-- snippet: ch08/revert-one-side/01-history -->
```text
$ git log --oneline --graph --all
* a2a0277 Revert "Allow long answers: max_tokens 2048"
* 523ed40 Allow long answers: max_tokens 2048
| * 4fac9ee Ask for full sentences
| * c8e320d Allow long answers: max_tokens 2048
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ grep max_tokens config/eval.yaml
max_tokens: 512
```
<!-- /snippet -->

<!-- snippet: ch08/revert-one-side/02-merge -->
```text
$ git merge feature/long-answers
Merge made by the 'ort' strategy.
 config/eval.yaml  | 2 +-
 prompts/judge.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ grep max_tokens config/eval.yaml
max_tokens: 2048
```
<!-- /snippet -->

The reverted change is back, without a conflict and without a message. The three inputs explain it:

<!-- snippet: ch08/revert-one-side/03-three-inputs -->
```text
# base, ours, theirs, result:
$ git show $(git merge-base HEAD^1 HEAD^2):config/eval.yaml | grep max_tokens
max_tokens: 512
$ git show HEAD^1:config/eval.yaml | grep max_tokens
max_tokens: 512
$ git show HEAD^2:config/eval.yaml | grep max_tokens
max_tokens: 2048
$ git show HEAD:config/eval.yaml | grep max_tokens
max_tokens: 2048
```
<!-- /snippet -->

Base 512, ours 512, theirs 2048: the row "only theirs changed it". The apply-then-revert pair on `main` cancels out, and the merge never sees it. The manual describes this behavior and admits that "some people find this behavior confusing". If the revert must win, say so in the tree that the merge will see: revert the change on the branch too before merging.

**Evil merges.** The glossary definition: "An evil merge is a merge that introduces changes that do not appear in any parent." It happens through a resolution that also changes something outside the conflict, an edit between `git merge --no-commit` and the commit, or `git commit --amend` on a merge. The name is harsher than the practice. Fixing a semantic conflict inside the merge commit is such a change, and it keeps every mainline commit green, which `git bisect` needs. The cost is visibility: `git log -p` shows no diff for a merge. The manual asks you to "refrain from abusing this option to sneak substantial changes into a merge commit". A defensible team rule: anything beyond resolving the conflict goes into a normal commit, or is named in the merge message.

## 8.16 Auditing a merge

**In one sentence.** A merge commit stores a tree and no diff, so "what did this merge do" has to be computed, and Git offers three computations that answer three different questions.

| View | Command | Shows | Blind to |
|---|---|---|---|
| default log | `git log -p` | no diff at all for merge commits | everything a merge did |
| first-parent diff | `git show --first-parent M`, `git diff M^1 M` | everything the merge brought to the mainline | which part is branch content and which is hand-made |
| combined diff | `git show M` (the `--cc` format) | lines that differ from every parent | resolutions that took one side unchanged |
| remerge diff | `git show --remerge-diff M`, `git log --merges --remerge-diff` | the difference between a mechanical re-merge and the recorded result | octopus merges, which it skips |

**See it.** A history with three merges: one conflict resolved by keeping our temperature, one clean merge that also set `retries` to 0, a line that neither branch touched, and one honest clean merge.

<!-- snippet: ch08/audit-merge/01-log-p-is-blind -->
```text
$ git log --oneline --first-parent -5
9a6385a Merge branch 'topic/max-tokens'
fc83756 Merge branch 'topic/docs'
8353ff1 Add requirements
70bae5f Merge branch 'feature/creative-judge'
5397d5f Use temperature 0 for reproducible evals
# By default git log shows no diff for a merge commit, with -p or with --stat:
$ git log -1 -p --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'
$ git log -1 --stat --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'
```
<!-- /snippet -->

<!-- snippet: ch08/audit-merge/02-show-combined -->
```text
# git show uses the dense combined format (--cc) for merges.
$ git show --format='%h %s' 70bae5f
70bae5f Merge branch 'feature/creative-judge'

$ git show --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'

diff --cc config/eval.yaml
index 1642b99,1642b99..29fd375
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@@ -3,5 -3,5 +3,5 @@@ temperature: 0.
  max_tokens: 512
  batch_size: 16
  timeout_s: 30
--retries: 2
++retries: 0
  seed: 1234
```
<!-- /snippet -->

`git show` prints nothing for the first merge, the one with the hand-resolved conflict. The dense combined format omits hunks where the result equals one of the parents, and that resolution took our side exactly. For the second merge it shows the smuggled line, with `--` and `++` because the result differs from both parents. The remerge diff shows both:

<!-- snippet: ch08/audit-merge/03-remerge-diff -->
```text
$ git log --merges --remerge-diff --format='== %h %s'
== 9a6385a Merge branch 'topic/max-tokens'
== fc83756 Merge branch 'topic/docs'

diff --git a/config/eval.yaml b/config/eval.yaml
index 1642b99..29fd375 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -3,5 +3,5 @@ temperature: 0.0
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
-retries: 2
+retries: 0
 seed: 1234
== 70bae5f Merge branch 'feature/creative-judge'

diff --git a/config/eval.yaml b/config/eval.yaml
remerge CONFLICT (content): Merge conflict in config/eval.yaml
index 2c6727a..1642b99 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -1,9 +1,5 @@
 model: judge-large-v2
-<<<<<<< 5397d5f (Use temperature 0 for reproducible evals)
 temperature: 0.0
-=======
-temperature: 0.7
->>>>>>> 45a7a67 (Ask the judge for a rationale)
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
```
<!-- /snippet -->

Read it as "what a human did after Git stopped". Git repeats each merge into a temporary tree, conflict markers included, and diffs that tree against the recorded one. No output means that the merge is exactly what Git computes on its own (`9a6385a`). Removed marker lines with one candidate kept are a resolution (`70bae5f`). A change with no markers nearby came from neither branch (`fc83756`). The first-parent view answers the other question, "what did `main` receive":

<!-- snippet: ch08/audit-merge/04-first-parent -->
```text
# Everything a merge brought to main, as one ordinary diff against its first parent:
$ git show --first-parent --format='%h %s' fc83756
fc83756 Merge branch 'topic/docs'

diff --git a/README.md b/README.md
new file mode 100644
index 0000000..e8fdfb1
--- /dev/null
+++ b/README.md
@@ -0,0 +1 @@
+# evalkit
diff --git a/config/eval.yaml b/config/eval.yaml
index 1642b99..29fd375 100644
--- a/config/eval.yaml
+++ b/config/eval.yaml
@@ -3,5 +3,5 @@ temperature: 0.0
 max_tokens: 512
 batch_size: 16
 timeout_s: 30
-retries: 2
+retries: 0
 seed: 1234
```
<!-- /snippet -->

The remerge diff repeats the merge with default settings, so a merge made with `-X ours` or `-s ours` shows up as a diff, however clean it looked when it was made. Its limits: Git 2.36 or later, two-parent merges only, and an output format that the manual declares "subject to change", so read it and do not parse it.

**In production.** This answers the second question of section 8.1. `git log --merges --remerge-diff --first-parent <last-release>..main` lists every hand-made change in every merge since the last release. Lab 6.6 uses it to find a merge where a whole-file `--theirs` deleted a teammate's retry setting.

## 8.17 `git merge-tree`: a merge without a working tree

**In one sentence.** `git merge-tree --write-tree` performs a real merge with the same strategy as `git merge`, using only the object database: no index, no working tree and no ref update.

**Precisely.** The command prints the ID of the resulting tree. Its exit status is 0 for a clean merge and 1 for a conflict. On a conflict it also prints the stage entries that `git merge` would have put into the index, and the messages. It creates objects and changes nothing else, so it works in a bare repository, where `git merge` cannot run:

<!-- snippet: ch08/merge-tree/01-bare -->
```text
$ git clone -q --bare evalkit server.git
$ cd server.git
$ git rev-parse --is-bare-repository
true
$ git log --oneline --graph --all
* 7c974a2 Add a README
| * 5397d5f Use temperature 0 for reproducible evals
|/  
| * 45a7a67 Ask the judge for a rationale
| * 640bfe1 Raise temperature and reseed for judge diversity
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge docs/readme
fatal: this operation must be run in a work tree
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch08/merge-tree/02-clean -->
```text
$ git merge-tree --write-tree main docs/readme
0c05f61e275e97d119913a164e7312d48cd50d66
[exit status: 0]
$ tree=$(git merge-tree --write-tree main docs/readme)
$ git ls-tree -r --abbrev=7 $tree
100644 blob af7f9b5	README.md
100644 blob 0e8b97c	config/eval.yaml
100644 blob 9bbcd7a	evalkit/metrics.py
100644 blob cfe0ef0	prompts/judge.txt
```
<!-- /snippet -->

A tree is not a commit. Two more plumbing commands turn it into a merge and publish it:

<!-- snippet: ch08/merge-tree/03-commit -->
```text
$ commit=$(git commit-tree $tree -p main -p docs/readme -m "Merge branch 'docs/readme'")
$ git update-ref refs/heads/main $commit
$ git log --oneline --graph -4 main
*   40fb5aa Merge branch 'docs/readme'
|\  
| * 7c974a2 Add a README
* | 5397d5f Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
```
<!-- /snippet -->

A conflicting pair of branches:

<!-- snippet: ch08/merge-tree/04-conflict -->
```text
$ git merge-tree --write-tree main feature/creative-judge
9615415b8675a4fb67a61eb8a37e816decd78066
100644 c5b33275d88c041381cff59f23d3cd88b9f22c98 1	config/eval.yaml
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 db5c556ef5edb6802e492cd59b5a0b9721a882da 3	config/eval.yaml

Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
[exit status: 1]
```
<!-- /snippet -->

The tree is still written. It contains the file with markers, labelled with the names from the command line:

<!-- snippet: ch08/merge-tree/05-conflict-tree -->
```text
$ tree=$(git merge-tree --write-tree main feature/creative-judge | head -1)
$ git show $tree:config/eval.yaml | head -6
model: judge-large-v2
<<<<<<< main
temperature: 0.0
=======
temperature: 0.7
>>>>>>> feature/creative-judge
```
<!-- /snippet -->

<!-- snippet: ch08/merge-tree/06-quiet -->
```text
# A yes/no answer for a "can this be merged?" indicator:
$ git merge-tree --quiet main feature/creative-judge
[exit status: 1]
$ git merge-tree --write-tree --name-only --no-messages main feature/creative-judge
9615415b8675a4fb67a61eb8a37e816decd78066
config/eval.yaml
[exit status: 1]
```
<!-- /snippet -->

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git merge-tree --write-tree A B` 🟢 | unchanged | unchanged | unchanged | unchanged | new tree and blob objects only (`--quiet` avoids writing most of them) | unchanged | unchanged |

> **GitHub, not Git.** A server has no working tree to merge in. GitHub's engineering blog lists "It can't check out the repository" among its requirements for a merge implementation, and its changelog states: "When GitHub creates merge commits, like to test whether a pull request can be merged cleanly or to actually merge a pull request, it now uses the `merge-ort` strategy" ([blog, 2023](https://github.blog/engineering/infrastructure/scaling-merge-ort-across-github/); [changelog, 2022](https://github.blog/changelog/2022-09-12-merge-commits-now-created-using-the-merge-ort-strategy/)). Neither page says which command GitHub runs; `git merge-tree` is how stock Git exposes the same strategy without a working tree. This is described from GitHub's publications, not run here. One documented consequence: "Workflows will not run on `pull_request` activity if the pull request has a merge conflict" ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)).

**In production.** `git merge-tree --write-tree --name-only main feature/x` is a dry run that cannot disturb your working tree. Use it before a risky merge, or in a script that reports which branches conflict with `main`. Decide by the exit status, as the manual warns, not by whether the list of conflicted files is empty.

## 8.18 Pointers: rerere, reverting a merge, `git add --resolved`

**rerere.** "Reuse recorded resolution" remembers how you resolved a conflict and replays the resolution when the identical conflict appears again. It is off until you set `rerere.enabled`. It matters for long-lived branches, criss-cross histories and aborted merges. Chapter 14C covers it.

**Reverting a merge.** `git revert` refuses a merge commit until you say which parent is the mainline:

<!-- snippet: ch08/revert-merge-preview/01-revert -->
```text
$ git log --oneline --graph
*   821b8ff Merge branch 'feature/rationale'
|\  
| * 58a5e60 Ask the judge to quote evidence
| * 5aec6e0 Ask the judge for a rationale
* | c089834 Use temperature 0 for reproducible evals
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git revert --no-edit HEAD
error: commit 821b8ff2e4e35c648578cd9e11514117ae0fd1b9 is a merge but no -m option was given.
fatal: revert failed
[exit status: 128]
$ git revert --no-edit -m 1 HEAD
[main 504ae98] Revert "Merge branch 'feature/rationale'"
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 deletions(-)
$ cat prompts/judge.txt
You are a strict grader.
Answer with PASS or FAIL.
```
<!-- /snippet -->

`-m 1` creates a commit that undoes the difference between the merge and its first parent. It undoes content. It cannot undo ancestry: the merge commit is still in the history and the branch still counts as merged. Asha adds one more commit and the branch is merged again:

<!-- snippet: ch08/revert-merge-preview/02-remerge -->
```text
$ git log --oneline main..feature/rationale
b752dc4 Give the judge 60 seconds for longer answers
$ git merge feature/rationale
Auto-merging config/eval.yaml
Merge made by the 'ort' strategy.
 config/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# The timeout arrived. The two prompt lines of the first merge did not come back:
$ grep timeout_s config/eval.yaml
timeout_s: 60
$ cat prompts/judge.txt
You are a strict grader.
Answer with PASS or FAIL.
$ git branch --merged
  feature/rationale
* main
```
<!-- /snippet -->

Only the new commit arrived. The two prompt lines from the first merge are missing, because their commits are ancestors of `main` already and the merge base is past them. The manual states the rule: "Reverting a merge commit declares that you will never want the tree changes brought in by the merge. As a result, later merges will only bring in tree changes introduced by commits that are not ancestors of the previously reverted merge" ([git-revert](https://git-scm.com/docs/git-revert)). That is the third question of section 8.1. The repair, reverting the revert before merging again, is in [Chapter 11](ch11-reset-revert-restore.md).

**`git add --resolved`.** Added in Git 2.56 (not run here). According to the 2.56 documentation it updates the index "for unmerged paths matching `<pathspec>` where no conflict markers remain in the working tree", and "any path with leftover conflict markers causes the command to refuse to stage any files" ([git-add at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-add.adoc)). The release notes add that it leaves "unrelated local changes unstaged" ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)). It closes both traps of the next section.

## 8.19 What can go wrong

**Before the merge starts.** `git merge` protects uncommitted work by refusing to start. The manual gives two rules: it stops when local changes "overlap with files that `git pull`/`git merge` may need to update", and it aborts "if there are any changes registered in the index relative to the `HEAD` commit". Under the second rule a staged change blocks the merge even in a file that the merge does not touch, and the message does not say why:

<!-- snippet: ch08/pre-merge-checks/01-staged-change -->
```text
# A staged change in a file the merge does not even touch:
$ echo "# scoring helpers" >> evalkit/metrics.py
$ git add evalkit/metrics.py
$ git merge feature/creative-judge
error: Your local changes to the following files would be overwritten by merge:
  evalkit/metrics.py
Merge with strategy ort failed.
[exit status: 2]
```
<!-- /snippet -->

An untracked file that the merge would create is protected in the same way:

<!-- snippet: ch08/pre-merge-checks/04-untracked-file -->
```text
# The branch adds NOTES.md. You have an untracked file with the same name:
$ echo "my scratch notes" > NOTES.md
$ git merge feature/creative-judge
error: The following untracked working tree files would be overwritten by merge:
	NOTES.md
Please move or remove them before you merge.
Aborting
Merge with strategy ort failed.
[exit status: 2]
```
<!-- /snippet -->

Uncommitted work in paths that the merge does not touch is allowed, and it survives both the merge and an abort. The transcript uses an untracked file; an unstaged edit to a tracked file behaved the same in the sandbox:

<!-- snippet: ch08/abort-continue-quit/07-dirty-tree -->
```text
# An uncommitted edit in a file the merge does not touch survives merge and abort.
$ echo "# evalkit" > NOTES.md
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
?? NOTES.md
$ git merge --abort
$ git status --short
?? NOTES.md
```
<!-- /snippet -->

**`--autostash`.** An unstaged edit in a file that the merge does touch stops the merge, unless you let Git stash it (`merge.autoStash` makes that the default):

<!-- snippet: ch08/abort-continue-quit/08-autostash -->
```text
# An uncommitted edit in a file the merge DOES touch stops the merge before it starts...
$ echo "Be concise." >> prompts/judge.txt
$ git merge feature/creative-judge
error: Your local changes to the following files would be overwritten by merge:
	prompts/judge.txt
Please commit your changes or stash them before you merge.
Aborting
Merge with strategy ort failed.
[exit status: 2]
# ...unless Git stashes it for you.
$ git merge --autostash feature/creative-judge
Created autostash: 02ed132
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
[exit status: 1]
$ ls .git | grep -E 'MERGE|ORIG_HEAD'
AUTO_MERGE
MERGE_AUTOSTASH
MERGE_HEAD
MERGE_MODE
MERGE_MSG
ORIG_HEAD
$ git merge --abort
Applied autostash.
$ git status --short
 M prompts/judge.txt
```
<!-- /snippet -->

The hint printed after a conflict deserves a closer look:

<!-- snippet: ch08/autostash-continue/01-stopped -->
```text
# An uncommitted edit in a file that the merge also changes (on another line):
$ sed -e 's/strict grader/strict but fair grader/' prompts/judge.txt > j && mv j prompts/judge.txt
$ git status --short
 M prompts/judge.txt
$ git merge --autostash feature/creative-judge
Created autostash: 1b5e0ea
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
When finished, apply stashed changes with `git stash pop`
[exit status: 1]
$ git status --short
UU config/eval.yaml
M  prompts/judge.txt
# The hint says "git stash pop". The stash list is empty:
$ git stash list
$ git stash pop
No stash entries found.
[exit status: 1]
$ git log -1 --format="%h %s" MERGE_AUTOSTASH
1b5e0ea On main: autostash
```
<!-- /snippet -->

<!-- snippet: ch08/autostash-continue/02-concluded -->
```text
# Resolve the conflict as in section 8.10, then conclude the merge:
$ git add config/eval.yaml
$ git merge --continue
[main 29f236b] Merge branch 'feature/creative-judge'
Applied autostash.
$ git status --short
 M prompts/judge.txt
$ cat prompts/judge.txt
You are a strict but fair grader.
Answer with PASS or FAIL.
Explain your verdict in one sentence.
$ git stash list
```
<!-- /snippet -->

> **Root cause.** The autostash is a stash-shaped commit that `.git/MERGE_AUTOSTASH` points to, not an entry in the stash list, so `git stash pop` finds nothing. `git merge --continue` and `git merge --abort` apply it for you. It reaches the stash list after `git merge --quit` or `git reset --merge` (per the manual), or when applying it conflicts (seen in the sandbox). Only then is `git stash pop` the right command.

**During the merge.** `git add` records whatever is in the file. A second merge and a partial commit are refused while one is open:

<!-- snippet: ch08/pre-merge-checks/02-leftover-markers -->
```text
$ git merge feature/creative-judge
Auto-merging config/eval.yaml
CONFLICT (content): Merge conflict in config/eval.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# Nothing was edited. git add accepts the file anyway:
$ git add config/eval.yaml
$ git status --short
M  config/eval.yaml
M  prompts/judge.txt
$ git diff --cached --check
config/eval.yaml:2: leftover conflict marker
config/eval.yaml:4: leftover conflict marker
config/eval.yaml:6: leftover conflict marker
[exit status: 2]
```
<!-- /snippet -->

<!-- snippet: ch08/pre-merge-checks/03-merge-in-progress -->
```text
$ git merge feature/creative-judge
fatal: You have not concluded your merge (MERGE_HEAD exists).
Please, commit your changes before you merge.
[exit status: 128]
$ git commit -m "Resolve config" config/eval.yaml
fatal: cannot do a partial commit during a merge.
[exit status: 128]
```
<!-- /snippet -->

**The abort that loses work.** `git merge --abort` is `git reset --merge`. It resets every staged path, and it cannot tell a merge result from an edit of yours that predates the merge and that you staged meanwhile, for example with the `git add -A` reflex. The manual warns that abort "will in some cases be unable to reconstruct the original (pre-merge) changes". Lab 6.7 reproduces the loss and recovers the edit from an object that few people know exists: before a true merge starts on a tree with local changes, Git 2.55 runs `git stash create` as a safety copy ([builtin/merge.c](https://github.com/git/git/blob/v2.55.0/builtin/merge.c)). No ref points to that commit, so it lasts only until unreachable objects are pruned (Chapter 13). `git fsck` lists it as a dangling commit.

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `error: Your local changes ... would be overwritten by merge` | `git status`: an unstaged edit in a file the merge updates, or any staged change | commit or stash, then merge; or `git merge --autostash` | merge from a clean tree |
| Conflict markers in a commit; a syntax error at `<<<<<<<` | `git grep -n -E '^(<<<<<<<\|=======\|>>>>>>>)'` | remove them in a new commit | `git diff --cached --check` before concluding; the same check in CI |
| A teammate's change vanished in a merge | `git show --remerge-diff <merge>`; `git log --full-history -- <path>` | restore the lines in a new commit that says why | no whole-file `--ours` or `--theirs` unless the whole file is the decision |
| Merge was clean, build is red | run the check on `M^1` and on `M^2`: both pass | fix forward, or `git revert -m 1 M` | CI on the merge result (section 8.15) |
| The same conflict returns at every merge | `git merge-base --all` prints two commits, or the branch was squash-merged before | resolve once more; enable rerere | one-directional merges; delete squashed branches |
| `fatal: There is no merge to abort (MERGE_HEAD missing).` with unmerged paths in `git status` | a `--squash` merge, or `--quit` was used | `git reset --merge` | check the state first: `ls .git \| grep MERGE` |
| An uncommitted edit is gone after `git merge --abort` | it was staged during the merge | `git fsck`, then restore from the "WIP on" commit (Lab 6.7) | commit or stash first; stage paths by name |
| Branch counts as merged, its changes are missing | a reverted merge, `-s ours`, or a whitespace option: `git show --remerge-diff <merge>` | revert the revert ([Chapter 11](ch11-reset-revert-restore.md)), or reapply | read the merge before trusting `git branch --merged` |

## 8.20 When not to use it, and dangerous edge cases

**When not to merge.** Do not merge to silence a conflict: `-X ours`, `-s ours` and whole-file checkouts make the conflict disappear by deleting one side's answer. Do not merge `main` into a short-lived feature branch by habit: each merge adds a commit that explains nothing and sets up the first-parent flip of section 8.13; for a private branch, a rebase is often cleaner (Chapter 9). Do not squash-merge a branch that will keep living. Do not start a merge on top of uncommitted work that you cannot afford to lose.

**Unrelated histories.** Two commits with no common ancestor have no merge base, and Git refuses:

<!-- snippet: ch08/pre-merge-checks/05-unrelated-histories -->
```text
$ git merge-base main imported/prompt-library
[exit status: 1]
$ git merge imported/prompt-library
fatal: refusing to merge unrelated histories
[exit status: 128]
```
<!-- /snippet -->

The usual cause is a mistake, such as a second `git init` whose history is then pulled into an existing repository. `--allow-unrelated-histories` exists for the rare intended case, joining two projects.

**Annotated tags.** Merging a tag can create a merge commit where you expected a fast-forward. Here it does not:

<!-- snippet: ch08/pre-merge-checks/06-annotated-tag -->
```text
# v0.1 is an annotated tag, one commit ahead of main, stored as refs/tags/v0.1:
$ git cat-file -t v0.1
tag
$ git merge v0.1
Updating 5397d5f..2f528c3
Fast-forward
 README.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
```
<!-- /snippet -->

The "MERGING TAG" section of the 2.55 manual says that Git "always creates a merge commit" for an annotated tag. The description of `--ff` on the same page is the accurate one: the merge commit is forced only for a tag "that is not stored in its natural place in the `refs/tags/` hierarchy". In the sandbox, the same tag object stored under another name produced a commit titled "Merge tag" that carried the tag message. `git merge --ff-only <tag>` never creates one.

**Legacy strategies.** `resolve` and `octopus` are shell scripts from 2005 that still ship with Git. On a criss-cross built like the one in section 8.5, `-s resolve` does this:

<!-- snippet: ch08/strategy-resolve/01-resolve -->
```text
$ git merge-base --all main release/1.0
f66460bde7a1c01671e6268b8f4209a580951592
5397d5f953dda5e3acd0d0970078420baf6e0488
$ git merge -s resolve release/1.0
Trying simple merge.
Simple merge failed, trying Automatic merge.
Added config/eval.yaml in both, but differently.
fatal: unable to read blob object e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
error: Could not stat : No such file or directory
ERROR: content conflict in config/eval.yaml
fatal: merge program failed
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
AA config/eval.yaml
$ git ls-files -u
100644 0e8b97cd35b023b2949d7efeed9dbd491d065ae8 2	config/eval.yaml
100644 3e21100524f1361d04738d41f1012b9221082155 3	config/eval.yaml
# The path is unmerged, and the file contains no conflict marker:
$ grep -n -e "<<<<<<<" -e temperature -e ">>>>>>>" config/eval.yaml
2:temperature: 0.0
$ git merge --abort
```
<!-- /snippet -->

An internal error, and a state that is worse than a conflict: the path is unmerged, there is no stage 1, and the working tree file contains our version with no markers. The script behind it is in Git's exec path:

<!-- snippet: ch08/strategy-resolve/02-exec-path -->
```text
# The strategies that exist as separate programs (ort is built into git merge itself):
$ ls "$(git --exec-path)" | grep -E "^git-merge-(octopus|ours|recursive|resolve|subtree)$"
git-merge-octopus
git-merge-ours
git-merge-recursive
git-merge-resolve
git-merge-subtree
$ head -6 "$(git --exec-path)/git-merge-resolve"
#!/bin/sh
#
# Copyright (c) 2005 Linus Torvalds
# Copyright (c) 2005 Junio C Hamano
#
# Resolve two trees, using enhanced multi-base read-tree.
```
<!-- /snippet -->

There is no reason to pass `-s resolve` or `-s recursive` today.

**Ignored files.** A merge silently overwrites an ignored file when the other branch tracks a file at that path. That is the default, `--overwrite-ignore`. [Chapter 4](ch04-working-tree.md), section 4.16, shows the same loss with `git switch`; `git merge --no-overwrite-ignore` aborts instead.

**Submodules.** A submodule path merges by fast-forwarding to the descendant commit when one side's commit descends from the other's. Otherwise it is a conflict (Chapter 23).

## 8.21 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git merge-base`, `git merge-file -p`, `git ls-files -u`, `git show :<n>:<path>`, `git log --merge`, `git log --remerge-diff` | 🟢 SAFE | nothing | not needed | not needed |
| `git merge-tree --write-tree A B` | 🟢 SAFE | adds unreferenced objects | it is the preview | not needed |
| `git merge <other>` (fast-forward or true merge) | 🟡 CAUTION | moves the current branch; rewrites index and working tree | `git merge-tree --write-tree --name-only HEAD <other>`; `git diff HEAD...<other>` | before pushing: `git reset --merge ORIG_HEAD` (check it first, or take the commit from the reflog); after pushing: `git revert -m 1` (Chapter 11) |
| `git merge -X ours`, `-X theirs`, `-X ignore-space-change` | 🟡 CAUTION | as above, and silently drops one side of every conflicting hunk | merge without the option first | as above; audit with `--remerge-diff` |
| `git merge -s ours <other>` | 🟡 CAUTION | records `<other>` as merged and takes none of its content | `git diff HEAD...<other>` shows what is discarded | as above |
| `git merge --squash <other>` | 🟡 CAUTION | index and working tree; no commit | as for `git merge` | `git reset --merge` |
| `git add <path>` on an unmerged path | 🟢 SAFE | collapses stages 1 to 3 into stage 0 | `git diff`, `git diff AUTO_MERGE` | `git restore --merge <path>` |
| `git merge --continue`, `git commit` during a merge | 🟡 CAUTION | creates the merge commit and moves the branch | `git diff --cached --check`; run the tests | `git reset --merge ORIG_HEAD` before pushing |
| `git merge --quit` | 🟡 CAUTION | deletes the merge state only | `git status` | `git reset --merge`; no command resumes the merge |
| `git restore --ours\|--theirs\|--merge <path>` and the `git checkout` forms | 🔴 DANGEROUS | overwrites the working tree file | `git diff --ours`, `git diff --theirs` | see below |
| `git merge --abort`, `git reset --merge` | 🔴 DANGEROUS | resets index and working tree to HEAD; deletes the merge state | `git status`, `git diff --cached --stat` | see below |

For the 🔴 commands:

- **`git restore --ours|--theirs|--merge <path>`.** Changes the working tree file only. Destroys your hand edits to that file, which exist nowhere else until you `git add` them. Preview with `git diff --ours` or `--theirs`. Recovery: `git restore --merge <path>` brings back the starting point, not your edits. Appropriate when the whole file from one side is the decision, or to restart a botched resolution.
- **`git merge --abort` and `git reset --merge`.** Change the index, the working tree and the merge state. Destroy every resolution made so far and any uncommitted edit that was staged during the merge. Preview with `git status`. Recovery: staged content survives as unreferenced objects that `git fsck` lists (Lab 6.7, [Chapter 13](ch13-recovery.md)); unstaged resolution edits are gone. Appropriate when the merge was a mistake or needs a different approach.

## 8.22 Version notes

> **Version note.** Older behavior: `recursive` was the default strategy for two heads "from Git v0.99.9k until v2.33.0". Current behavior: `ort` is the default and `recursive` "is now a synonym for `ort`". Since: default in Git 2.34 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc)), synonym in 2.50 ([merge strategies](https://github.com/git/git/blob/v2.56.0/Documentation/merge-strategies.adoc)). Recommended: configure nothing, and read "recursive" in older material as "the default strategy".

> **Version note.** Older behavior: conflict styles `merge` and `diff3`. Current behavior: the default is still `merge`; `zdiff3` is available. Since: Git 2.35 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.35.0.adoc)). Recommended: `merge.conflictStyle=zdiff3`.

> **Version note.** Older behavior: a resolution could be reviewed only through combined diffs. Current behavior: `--remerge-diff` for `git log` and `git show`. Since: Git 2.36 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.36.0.adoc)). Recommended: use it for every merge that had a conflict.

> **Version note.** Older behavior: `git merge-tree <base> <branch1> <branch2>`, a trivial-merge mode that the manual now calls deprecated. Current behavior: `git merge-tree --write-tree` runs a full merge. Since: Git 2.38 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.0.adoc)); the mode that only checks for a clean merge arrived in 2.50 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.50.0.adoc)). Recommended: the `--write-tree` form.

> **Version note.** Older behavior: `git add` stages a conflicted file with its markers. Current behavior on 2.55: the same. Since: Git 2.56 adds `git add --resolved` (not run here). The 2.56 release notes also list a fix for `git merge-base` without `--all`, which "could return incorrect results on repositories with v1 commit graphs and clock skew"; whether that affects a given 2.55 repository was not tested. Recommended: upgrade when convenient.

> **Outdated advice.** Pro Git's "Advanced Merging" chapter teaches index stages and `--conflict=diff3` well, but it describes the `recursive` strategy and mentions neither `ort` nor `zdiff3`. Older answers that recommend `git checkout --theirs .` to "accept incoming changes" recommend the whole-file shortcut of section 8.10.

> **Unverified.** The release in which `git merge` began to write a stash-shaped commit before every true merge on a dirty tree was not determined; the behavior was observed on 2.55.0 and read in its source. Which command GitHub runs to compute merges is not stated in the pages cited in section 8.17.

## 8.23 Practice

- Labs 6.1 to 6.7 in the [Module 6 lab manual](../lab-manual/m06-merge.md): seven scenarios, from predicting a fast-forward to recovering an edit after an abort. Answers are in [solutions](../solutions/m06-lab-answers.md).
- Replay any transcript with `labs/run ch08/<demo>`, for example `labs/run ch08/conflict-anatomy`. The sandbox stays in place afterwards.
- Three drills in those sandboxes:
  1. In `ch08/why-conflicts`, edit `base.yaml` so that the adjacent-line case merges cleanly, and prove it with `git merge-file -p`.
  2. In `ch08/merge-base/crisscross`, predict the output of `git merge-base --all main release/1.0` after `main` merges `release/1.0` once more. Then do it.
  3. In `ch08/merge-tree/server.git`, write a loop over all branches that prints "clean" or "conflict" against `main`, using only exit statuses.

## 8.24 Interview questions

1. Define "merge base". How can two commits have more than one, and what does the default strategy do then?
2. `git merge feature` printed "Fast-forward". What changed in `.git`, and what did not?
3. State the three-way rule for a single path as a table of base, ours and theirs. Which rows never read file content?
4. Two branches changed different lines of one file and the merge still conflicted. Give the exact condition under which that happens.
5. During a conflict, what are index stages 1, 2 and 3? How do you read "their" version of a file without touching the working tree?
6. A conflict was resolved with `git checkout --theirs path`, and a teammate's unrelated fix in that file disappeared. Explain the mechanism and prove it from history.
7. Compare `git merge -X ours`, `git merge -s ours` and `git merge --squash` in terms of content and ancestry.
8. Both branches were green, the merge had no conflict, and `main` is red. Why can Git not detect this, and which process controls can?
9. What do `git show <merge>`, `git show --first-parent <merge>` and `git show --remerge-diff <merge>` each display? Which one audits a conflict resolution?
10. A change was made on two branches and reverted on one. After the merge it is back. Explain with the merge base.
11. You reverted a merge and later merged the repaired branch; part of the feature is missing. What happened, and what is the correct sequence?
12. How can a server with no working tree decide whether a pull request merges cleanly? What does stock Git offer for that?

## 8.25 Sources

**Primary sources**

- [git-merge](https://git-scm.com/docs/git-merge), [git-merge-base](https://git-scm.com/docs/git-merge-base), [git-merge-tree](https://git-scm.com/docs/git-merge-tree), [git-merge-file](https://git-scm.com/docs/git-merge-file), [git-read-tree](https://git-scm.com/docs/git-read-tree), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-status](https://git-scm.com/docs/git-status), [git-restore](https://git-scm.com/docs/git-restore), [git-checkout](https://git-scm.com/docs/git-checkout), [git-log](https://git-scm.com/docs/git-log), [git-diff](https://git-scm.com/docs/git-diff), [git-revert](https://git-scm.com/docs/git-revert), [git-rerere](https://git-scm.com/docs/git-rerere), [gitattributes](https://git-scm.com/docs/gitattributes), [gitglossary](https://git-scm.com/docs/gitglossary), [gitfaq](https://git-scm.com/docs/gitfaq). The local copies (`git help -m <command>`) are the Git 2.55.0 text that every quotation and transcript was checked against.
- Git source and documentation at fixed tags: [merge strategies](https://github.com/git/git/blob/v2.56.0/Documentation/merge-strategies.adoc), [merge configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/merge.adoc), [git-add at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-add.adoc), [builtin/merge.c at 2.55](https://github.com/git/git/blob/v2.55.0/builtin/merge.c).
- Release notes: [2.34](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.35](https://github.com/git/git/blob/master/Documentation/RelNotes/2.35.0.adoc), [2.36](https://github.com/git/git/blob/master/Documentation/RelNotes/2.36.0.adoc), [2.38](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.0.adoc), [2.50](https://github.com/git/git/blob/master/Documentation/RelNotes/2.50.0.adoc), [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- GitHub: [Pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request), [changelog of 12 September 2022](https://github.blog/changelog/2022-09-12-merge-commits-now-created-using-the-merge-ort-strategy/), [Scaling merge-ort across GitHub](https://github.blog/engineering/infrastructure/scaling-merge-ort-across-github/) (27 July 2023).

**Secondary sources**

- Pro Git, [Basic Branching and Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging) and [Advanced Merging](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging). Caveat: see the "Outdated advice" note in section 8.22.
- Julia Evans, [Git poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/) (2024). Self-selected samples.
- [nbdime](https://nbdime.readthedocs.io/en/latest/) documentation, for notebook diffs and merges.
- The Phase 0 report of this course, sections 1, 4, 12 and 13.

**Videos** (optional; the assessments in the Phase 0 report rest on captions and chapter lists, not on full viewing)

- David Mahler, ["Branching and Merging"](https://www.youtube.com/watch?v=FyAAIHHClqI) (29 min, 2017). Fast-forward against three-way merges drawn on the commit graph. Conceptually excellent; uses `master` and the commands that predate `git restore`.
- ThePrimeagen for Boot.dev, ["Git and GitHub - Full Course"](https://www.youtube.com/watch?v=rH3zE7VlIMs) (2024): merge from 1:03:27, merge conflicts from 2:41:25. Current commands; a digressive commentary style.
- Elijah Newren, the author of `ort`, at Git Merge [2022](https://www.youtube.com/watch?v=omGgXdXCt_8) and [2025](https://www.youtube.com/watch?v=0JSsxRcs-aE): the merge backend and `--remerge-diff`. Contributor level; watch after this chapter.

**Further reading**

- [Chapter 9](ch09-rebase.md) for the other way to integrate, [Chapter 11](ch11-reset-revert-restore.md) for undoing merges, Chapter 14C for rerere and merge drivers, Chapter 17 for merge methods on GitHub.

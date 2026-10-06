# V190: Incident drill: a pull request that suddenly shows 500 unrelated changes

- **Part.** 9, Production debugging and incident response
- **Module.** 37
- **Planned minutes.** 18
- **Prerequisites.** V125, V189
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), section 30.10
- **Demo scripts.** `labs/incidents/solve-06-pr-500-changes.sh` (snippets `01-pull-request-view` to `08-verify`), `labs/incidents/lab-37-3-pr-500-changes.sh` (snippet `02-consequence`)

## HOOK

**[ON SCREEN]** "I pushed one commit and the pull request shows 500 files."

Ravi's pull request had three commits and two files, and it was approved. He pushed one small commit. Now the page shows more than five hundred files and commits by a colleague who never touched his branch. He suspects that somebody rewrote `main`, or that somebody changed the base of his pull request.

And one detail that he mentions last, as if it were good news: the approval still stands.

## INTRODUCTION

**[PAUSE]** This is a debrief of Incident 6, [`incidents/06-pr-500-changes`](../../incidents/06-pr-500-changes/SYMPTOMS.md). You must have generated and attempted it, with your hypotheses written down before you tested them. If you have not, stop the video here. The cause is named in the next section.

From V125 you know what a pull request page computes: a commit list, which is everything reachable from the head and not from the base, and a diff, which is the three-dot comparison from the merge base to the head. So when the page changes dramatically, one of three things moved: the head, the base, or the merge base between them. The incident is an exercise in finding out which, with Git commands on the developer's machine, and then repairing the branch without closing the pull request.

In the lab the pull request is simulated as `main..head` and `main...head`, which is what GitHub computes.

## LEARNING OBJECTIVES

After this video you can:

1. List the mechanisms that make a small pull request show hundreds of files.
2. Name the Git command that tests each mechanism on the developer's machine.
3. Attribute the extra changes to the commit that brought them in.
4. Rebuild the branch so that the pull request shows only its own change.
5. Explain the consequence of leaving it as it is.

## CONCEPT

**The candidates.** The page shows a three-dot diff: either an endpoint or the merge base is not what the author thinks. The catalog of V184 lists the mechanisms for "a pull request shows hundreds of changes": the wrong base branch; the head branch reused after a squash merge; the branch rebased or force-pushed, or its base rewritten; every line changed, by line endings or a formatter; a lock file or generated file; and a merge of the wrong branch into the head.

Each has a local test. A rewritten `main`: the reflog of `origin/main` and the merge base. A force-pushed head: the reflog of the pushing clone. A merge: `git log --merges` over the pull request's range. Reformatting: `git diff --ignore-cr-at-eol --stat` against the plain diff. A wrong base: the range from each candidate base.

**The root cause here.** A topic branch aimed at `main` was updated from `develop`, an unreleased long-running branch. A merge makes every commit of the merged branch an ancestor of the result, and a pull request lists everything reachable from the head and not from the base. Layer: Git. GitHub displayed the branch correctly.

**Why "one small commit" felt true.** `git log --first-parent` shows the branch as Ravi experienced it: his commits and one merge. The five hundred files came in through the second parent of that merge.

**The tempting fix, and why it is wrong.** `git revert -m 1` of the merge commit: no forced push, and the diff shrinks. It is wrong here for two reasons. The commits of `develop` stay ancestors of the branch, so the commit list stays long. And once this branch is merged, `main` contains those commits together with a commit that undoes them, so the later release of `develop` brings nothing: the re-merge problem. The textbook's sentence for it: a reverted merge is not a removed merge.

**The repair.** The branch has one author, so it is rebuilt: anchor the current tip, replay what came after the merge onto the merge's first parent, and publish with a lease.

**GitHub, not Git: the approval.** Whether an approval survives a push depends on the rules: "dismiss stale pull request approvals" removes it when the diff changes. Here an approval given to two files stood on 504. Treat it as void and review again.

**Severity.** SEV 3. Nothing was merged. The near miss is the standing approval, not the file count.

## MENTAL MODEL

Picture the pull request as the answer to one question: "what would arrive in the base if this were merged now?" Everything the head can reach and the base cannot. A merge commit is a door: whatever is behind its second parent walks in with it.

Ravi opened a door to `develop` to get one thing he wanted from it. Everything else on `develop` came through the same door, and the page showed it faithfully.

Where the picture breaks: you can close a door, and you cannot un-open a merge by adding a commit. A revert changes the content back and leaves the ancestry in place. Only a branch that never contained the merge is a branch without the door, which is why the repair is a rebuild.

For the method, one habit: read the commit list, not only the files. The files said "something large changed". The commit list, with its authors, said what.

## DIAGRAM

**[DIAGRAM]** A new drawing: the pull request's two endpoints and merge base on the graph, before and after the rebuild. IDs are from the transcript.

```text
  before

    main (base, and merge base) ---bdb4a59---6d230a6---f94e7f0---461c3ea---5dc3109   feature/snippet-highlight (head)
              \                                               /   (merge of develop)
               796fd96---5f0c2ae---069daa8-------------------+    develop
               (fixture generator, 500 golden fixtures, tokenizer)

    commit list  main..head  : 5 of Ravi's (one a merge) + 3 of Asha's
    diff         main...head : 504 files

  after

    main (base, and merge base) ---bdb4a59---6d230a6---f94e7f0---1981450   feature/snippet-highlight (head)

               796fd96---5f0c2ae---069daa8    develop  (untouched, no longer reachable from the head)

    commit list  main..head  : 4 commits
    diff         main...head : 2 files
```

Neither the base nor the merge base moved. The head grew a second line of ancestors. After the rebuild the last commit has a new ID, because its parent changed.

## LIVE TERMINAL DEMO

**[PAUSE]** From here on the screen shows the solution.

**[TERMINAL]** Replay `labs/run incidents/solve-06-pr-500-changes`. We start in our own clone, as a reviewer would. Everything until the rebuild is 🟢 SAFE.

**What the pull request shows.**

```bash
git fetch
git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
git diff --shortstat origin/main...origin/feature/snippet-highlight
git diff --dirstat=files,5 origin/main...origin/feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/01-pull-request-view -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      develop    -> origin/develop
 * [new branch]      feature/snippet-highlight -> origin/feature/snippet-highlight
# The commit list of the pull request, and the size of its diff:
$ git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
5dc3109 Ravi Menon: Highlight every query term
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
f94e7f0 Ravi Menon: Escape HTML in snippets
6d230a6 Ravi Menon: Test snippet highlighting
bdb4a59 Ravi Menon: Add snippet highlighting
069daa8 Asha Rao: Switch the tokenizer to ICU word breaking
5f0c2ae Asha Rao: Regenerate golden fixtures
796fd96 Asha Rao: Add golden fixture generator
$ git diff --shortstat origin/main...origin/feature/snippet-highlight
 504 files changed, 517 insertions(+), 1 deletion(-)
$ git diff --dirstat=files,5 origin/main...origin/feature/snippet-highlight
  99.2% tests/golden/
```
<!-- /snippet -->

Eight commits, three of them by Asha. 504 files. And one line that already narrows it: 99.2 percent of the changed files are under `tests/golden/`. Read the commit list with the authors: one subject begins with "Merge branch 'develop'".

**Hypotheses, tested one at a time.**

<!-- snippet: incidents/solve-06-pr-500-changes/02-hypotheses -->
```text
# Hypothesis 1: main was rewritten or moved. Its history in my clone:
$ git reflog show origin/main
88eab01 refs/remotes/origin/main@{0}: update by push
$ git merge-base origin/main origin/feature/snippet-highlight
88eab017330e48da73bb6cc625a59fc9daaa61b9
$ git rev-parse origin/main
88eab017330e48da73bb6cc625a59fc9daaa61b9
# Hypothesis 2: the branch was force-pushed. The pushing clone recorded its pushes:
$ git -C ../ravi reflog show origin/feature/snippet-highlight
5dc3109 refs/remotes/origin/feature/snippet-highlight@{0}: update by push
f94e7f0 refs/remotes/origin/feature/snippet-highlight@{1}: update by push
```
<!-- /snippet -->

Was `main` rewritten? The reflog of `origin/main` and the merge base say no. Was the head branch force-pushed? The pushing clone's reflog shows ordinary pushes. Two of Ravi's own suspects are ruled out with read-only commands.

**Hypothesis 3: another branch was merged into the head branch.** Predict what `git log --merges` over the pull request's range will list.

```bash
git log --merges --format='%h %an: %s%n        parents: %p' origin/main..origin/feature/snippet-highlight
git log --oneline --graph origin/main..origin/feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/03-merge -->
```text
# Hypothesis 3: another branch was merged into the head branch.
$ git log --merges --format='%h %an: %s%n        parents: %p' origin/main..origin/feature/snippet-highlight
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
        parents: f94e7f0 069daa8
$ git log --oneline --graph origin/main..origin/feature/snippet-highlight
* 5dc3109 Highlight every query term
*   461c3ea Merge branch 'develop' of ../server into feature/snippet-highlight
|\  
| * 069daa8 Switch the tokenizer to ICU word breaking
| * 5f0c2ae Regenerate golden fixtures
| * 796fd96 Add golden fixture generator
* f94e7f0 Escape HTML in snippets
* 6d230a6 Test snippet highlighting
* bdb4a59 Add snippet highlighting
```
<!-- /snippet -->

One merge commit, `461c3ea`, by Ravi, with the tip of `develop`, `069daa8`, as its second parent. The graph shows the three commits that came in through it.

**Attribution: which commit brought the files?**

<!-- snippet: incidents/solve-06-pr-500-changes/04-attribution -->
```text
# What the merge alone brought in, and what the branch looks like without its second parent:
$ git diff --shortstat 461c3ea^1 461c3ea
 502 files changed, 508 insertions(+), 1 deletion(-)
$ git log --oneline --first-parent origin/main..origin/feature/snippet-highlight
5dc3109 Highlight every query term
461c3ea Merge branch 'develop' of ../server into feature/snippet-highlight
f94e7f0 Escape HTML in snippets
6d230a6 Test snippet highlighting
bdb4a59 Add snippet highlighting
$ git branch -r --contains 461c3ea^2
  origin/develop
  origin/feature/snippet-highlight
$ git -C ../ravi reflog -4
5dc3109 HEAD@{0}: commit: Highlight every query term
461c3ea HEAD@{1}: pull --no-rebase origin develop: Merge made by the 'ort' strategy.
f94e7f0 HEAD@{2}: commit: Escape HTML in snippets
6d230a6 HEAD@{3}: commit: Test snippet highlighting
```
<!-- /snippet -->

The file count belongs to the commits behind the second parent, and Ravi's reflog names the command that made the merge: a pull of `develop` without rebase.

**[PAUSE]** Root cause, with its layer: Git. A topic branch aimed at `main` was updated from `develop`. GitHub displayed the branch correctly.

**Rebuild, in Ravi's clone.** 🟢 for the anchor. 🟡 CAUTION: `git rebase --onto` replaces the commits after the merge with new ones. The two arguments: the merge's first parent as the new base, and the merge itself as the boundary.

```bash
git status -sb
git branch rescue/with-develop
git rebase --onto 461c3ea^1 461c3ea
git log --oneline --graph main..feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/05-rebuild -->
```text
$ cd ../ravi
$ git status -sb
## feature/snippet-highlight...origin/feature/snippet-highlight
$ git branch rescue/with-develop
$ git rebase --onto 461c3ea^1 461c3ea
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/snippet-highlight.
$ git log --oneline --graph main..feature/snippet-highlight
* 1981450 Highlight every query term
* f94e7f0 Escape HTML in snippets
* 6d230a6 Test snippet highlighting
* bdb4a59 Add snippet highlighting
```
<!-- /snippet -->

One commit replayed. Four commits in a line, no merge. The last one is now `1981450`.

**Check the result before publishing.**

```bash
git range-diff 461c3ea..rescue/with-develop 461c3ea^1..feature/snippet-highlight
git diff --shortstat main...feature/snippet-highlight
git merge-base --is-ancestor origin/develop feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/06-check-result -->
```text
$ git range-diff 461c3ea..rescue/with-develop 461c3ea^1..feature/snippet-highlight
1:  5dc3109 = 1:  1981450 Highlight every query term
$ git diff --shortstat main...feature/snippet-highlight
 2 files changed, 9 insertions(+)
$ git merge-base --is-ancestor origin/develop feature/snippet-highlight
[exit status: 1]
```
<!-- /snippet -->

The replayed commit carries the same change as the original: one pair with an equals sign. Two files. And `develop` is no longer an ancestor of the branch: exit status 1, which here is the result you want.

**Publish.** 🔴 DANGEROUS: `git push --force-with-lease --force-if-includes`. What it changes: the server's topic branch, to a commit that does not descend from the old one. What it can destroy: commits on that server branch that are not in this clone. Preview: `git fetch`, then look at what the server's branch has that you lack. Recovery: the old tip is anchored as `rescue/with-develop`. When appropriate: for a topic branch with one author, as here.

<!-- snippet: incidents/solve-06-pr-500-changes/07-publish -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 5dc3109...1981450 feature/snippet-highlight -> feature/snippet-highlight (forced update)
```
<!-- /snippet -->

**Verify, from the reviewer's clone.**

<!-- snippet: incidents/solve-06-pr-500-changes/08-verify -->
```text
$ cd ../you
$ git fetch
From ../server
 + 5dc3109...1981450 feature/snippet-highlight -> origin/feature/snippet-highlight  (forced update)
$ git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
1981450 Ravi Menon: Highlight every query term
f94e7f0 Ravi Menon: Escape HTML in snippets
6d230a6 Ravi Menon: Test snippet highlighting
bdb4a59 Ravi Menon: Add snippet highlighting
$ git diff --stat origin/main...origin/feature/snippet-highlight
 search/highlight.py     | 7 +++++++
 tests/test_highlight.py | 2 ++
 2 files changed, 9 insertions(+)
$ git -C ../ravi branch -D rescue/with-develop
Deleted branch rescue/with-develop (was 5dc3109).
$ cd ..
$ incidents/06-pr-500-changes/check.sh
Checking incident 06-pr-500-changes
  ok    the server still has the feature branch
  ok    "Add snippet highlighting" is in the pull request exactly once
  ok    "Test snippet highlighting" is in the pull request exactly once
  ok    "Escape HTML in snippets" is in the pull request exactly once
  ok    "Highlight every query term" is in the pull request exactly once
  ok    the pull request lists four commits
  ok    the pull request changes two files
  ok    no commit of develop is reachable from the feature branch
  ok    the feature branch contains no merge commit
  ok    search/highlight.py handles every query term
  ok    develop on the server is untouched
  ok    main on the server is untouched
PASS: the recovery of incident 06-pr-500-changes is complete.
[exit status: 0]
```
<!-- /snippet -->

Four commits, all Ravi's. Two files. The check passes, including two lines about what was not touched: `develop` and `main` on the server.

**The consequence of leaving it, or of reverting the merge.** Replay `labs/run incidents/lab-37-3-pr-500-changes` and show the snippet `consequence`. In the lab's failure scenario the merge was reverted instead of removed. Later the pull request is merged into `main`, and then `develop` is released into `main`. Predict what the release merge prints.

<!-- snippet: incidents/lab-37-3-pr-500-changes/02-consequence -->
```text
# Later: the pull request is merged into main, and then develop is released into main.
$ git switch -q --detach main
$ git merge -q --no-ff -m 'Merge pull request: snippet highlighting' feature/snippet-highlight
$ git merge -m 'Release develop' origin/develop
Already up to date.
$ ls tests
test_highlight.py
test_tokenize.py
$ git switch -q feature/snippet-highlight
$ cd ..
$ incidents/06-pr-500-changes/check.sh
Checking incident 06-pr-500-changes
  ok    the server still has the feature branch
  ok    "Add snippet highlighting" is in the pull request exactly once
  ok    "Test snippet highlighting" is in the pull request exactly once
  ok    "Escape HTML in snippets" is in the pull request exactly once
  ok    "Highlight every query term" is in the pull request exactly once
  FAIL  the pull request lists 9 commits (expected 4)
  ok    the pull request changes two files
  FAIL  no commit of develop is reachable from the feature branch
  FAIL  the feature branch contains 1 merge commit(s); a reverted merge is not a removed merge
  ok    search/highlight.py handles every query term
  ok    develop on the server is untouched
  ok    main on the server is untouched
NOT YET: 3 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

**[PAUSE]** "Already up to date." The release of `develop` brings nothing, because its commits are already ancestors of `main`, together with the commit that undid them. The listing of `tests` shows no golden fixtures. An entire release has silently become empty. And the check script says it in one line: a reverted merge is not a removed merge.

**The messages.** To Ravi: GitHub showed what the branch contained; here is the reflog line; the last commit has a new ID. To the lead: the near miss is the standing approval, not the file count. Had it been merged, 500 fixtures and an unreleased tokenizer would have reached `main` under an approval for two files.

## COMMON MISTAKES

1. **Blaming the platform or a rewritten `main` first.** Root cause: the page is a computation over the head, the base and the merge base, and the reflogs showed that neither the base nor the head had been rewritten.
2. **Updating a topic branch from a branch other than its base.** Root cause: a merge makes every commit of the merged branch an ancestor of the result, so all of it enters the pull request.
3. **Reverting the merge to shrink the diff.** Root cause: the revert changes content and leaves ancestry, so the commit list stays long and a later merge of the same branch brings nothing.
4. **Reading only the changed files.** Root cause: the commit list, with authors, names the foreign commits directly; the file view only says that something is large.
5. **Letting the old approval stand.** Root cause: the approval was given to a different diff, and whether it is dismissed depends on a rule that may not be enabled.

## PRODUCTION EXAMPLE

A search team keeps a long-running `develop` branch for a tokenizer migration that regenerates five hundred golden test fixtures. An engineer working on snippet highlighting, on a branch aimed at `main`, needs one helper that exists only on `develop`, and pulls `develop` into his branch to get it.

His reviewer, the next morning, does not approve again. She reads the commit list and sees a colleague's name on three commits and a merge subject that names `develop`. She runs `git log --merges` over the pull request's range in her clone, sends him the one line, and asks him not to revert the merge. They rebuild the branch together: an anchor, one `rebase --onto`, three checks, a push with a lease. The helper he needed is cherry-picked as its own reviewed commit instead.

The team adds two lines to its contribution guide. Update a topic branch from the branch it will be merged into, and name that branch in the command. And the repository's ruleset gets the option that dismisses stale approvals when the diff changes, because an approval for two files had stood on five hundred and four.

## PRACTICE EXERCISE

Do Lab 37.3, "A pull request suddenly shows 500 unrelated changes (incident 6)", in [`lab-manual/m37-incident-drills-platform.md`](../../lab-manual/m37-incident-drills-platform.md), from a freshly generated sandbox.

Before any command, write four mechanisms that could produce the symptom and the local command that tests each. Before the rebuild, write the two arguments of `git rebase --onto` you will use and what each stands for, and predict the commit count afterwards. In the lab's failure scenario, predict what the later merge of `develop` will print before you run it.

The challenge is Exercise 21.7, Level 5, "Green on the pull request, red on main", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q414: "A pull request shows 400 changed files for a two-line change. List four mechanisms and the Git command that tests each one locally."

Answer aloud. The question fixes the form: four mechanisms, four commands. A strong answer begins with what the page computes, so that the four mechanisms follow from it instead of being recited: something about the base, something about the head's ancestry, something about a rewrite, something about content that changed on every line. Each command is one that the developer can run in their own clone, and for each you say what output confirms the mechanism. Add the order in which you would test them and why, and one sentence on which repairs keep the pull request open.

## RECAP

- A pull request lists everything reachable from the head and not from the base, and shows the diff from the merge base to the head.
- A sudden jump in size means the head, the base or the merge base changed; each candidate has a read-only local test.
- A merge of another branch into the head brings all of that branch's commits into the pull request.
- A reverted merge is not a removed merge: the ancestry stays, and a later merge of that branch brings nothing.
- The repair for a single-author topic branch is a rebuild with `git rebase --onto`, a lease, and a new review.

## HOMEWORK

Read section 30.10. Then generate Incident 7, [`incidents/07-ci-passes-locally`](../../incidents/07-ci-passes-locally/SYMPTOMS.md), read its evidence directory together with the symptoms, and attempt it before the next video.

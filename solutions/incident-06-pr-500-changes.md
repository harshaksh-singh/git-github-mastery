# Incident 6: a pull request suddenly shows 500 unrelated changes — solution

> Read this only after your own attempt at [`incidents/06-pr-500-changes`](../incidents/06-pr-500-changes/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-06-pr-500-changes.sh`. There is no GitHub in the sandbox: the "pull request" is the commit list `main..head` and the diff `main...head`, which is what GitHub computes ([Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), section 17.3). Layers: the cause is Git; the display and the approval are GitHub.

## 1. Symptoms

A pull request of three commits and two files shows more than 500 changed files and commits by another author after one ordinary push. The author suspects a rewritten `main` or a changed base. The approval is still shown.

## 2. Evidence

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

Eight commits, three of them Asha's, 504 files. `--dirstat` says where the bulk is: 99.2% of the changed files are under `tests/golden/`.

## 3. Hypotheses

The documented causes of an unexpectedly large pull request are a reused head branch after a squash merge, a wrong or changed base, a base that moved, rewritten history, and other branches merged into the head ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.12).

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | `main` was rewritten or force-pushed | The reflog of `origin/main`; is the merge base still the tip of `main`? | One entry, no forced update; merge base equals `origin/main` |
| 2 | The head branch was force-pushed | The pushing clone's reflog of the remote-tracking branch | Two ordinary pushes |
| 3 | The base of the pull request was changed | On GitHub: the pull request timeline. Not reproducible here | Would not add commits by another author to `main..head` unless they are missing from the new base |
| 4 | Another branch was merged into the head branch | A merge commit in `main..head` | Confirmed |

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

## 4. Diagnostic commands

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

The merge commit `461c3ea` has `develop` as its second parent. Compared with its first parent it brings 502 files. `--first-parent` shows the branch as Ravi experienced it: his four commits and one merge, which is why "I pushed one small commit" felt true. The last line is his reflog: `pull --no-rebase origin develop`. He meant to update his branch from `main` and named the wrong branch.

## 5. Root cause

```text
Observed behavior : a pull request into main lists three commits and 502 files that belong to develop
Git state         : the head branch contains a merge commit whose second parent is the tip of develop
Mechanism         : a pull request lists main..head and shows main...head; everything reachable from head and not from main is "in" it
Root cause        : "git pull origin develop" merged an unreleased long-running branch into a topic branch aimed at main
Why Git does this : a merge makes every commit of the merged branch an ancestor of the result; reachability is all a comparison sees
Correct fix       : rebuild the head branch without the merge and publish it with a lease
Prevention        : update a topic branch only from its own base; read "git log --graph" before pushing a merge
```

## 6. The fix that looks safer and is not

Reverting the merge with `git revert -m 1 461c3ea` needs no forced push and shrinks the diff to two files again. It is the wrong fix here for two reasons.

- The commit list of the pull request stays at nine or more: the commits of `develop` remain ancestors of the head branch.
- When this branch is merged into `main`, the commits of `develop` become ancestors of `main` together with a commit that undoes their content. When `develop` is released later, Git finds its commits already merged and brings nothing: the 500 fixtures and the tokenizer change silently stay out of `main`. This is the re-merge problem of [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md), section 11.9.

A reverted merge is not a removed merge. The check script tests for this.

## 7. Safe recovery

The branch has one author and the pull request is its only consumer, so rewriting it is acceptable. Anchor the current tip, then replay what came after the merge onto the commit before the merge.

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

`git rebase --onto 461c3ea^1 461c3ea` means: take the commits after `461c3ea` and put them on its first parent. `^1` is the branch as it was before the pull.

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

The one replayed commit is content-identical (`=`), the comparison with `main` is two files, and `develop` is no longer an ancestor (exit status 1).

<!-- snippet: incidents/solve-06-pr-500-changes/07-publish -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 5dc3109...1981450 feature/snippet-highlight -> feature/snippet-highlight (forced update)
```
<!-- /snippet -->

## 8. Verification

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

## 9. The approval

> **GitHub, not Git.** Whether the approval survived the push depends on the repository's rules. With "dismiss stale pull request approvals when new commits are pushed", any push that changes the diff dismisses it; without that setting an approval stays attached while the content under it changes ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.5). In this incident the approval was given to two files and stood, for a while, on 504. A reviewer should treat it as void and review again after the repair; the repair is itself a forced push.

## 10. Prevention, communication, postmortem

**Prevention.** Update a topic branch from the branch it will be merged into, and name it: `git fetch origin && git rebase origin/main` or `git merge origin/main`. Enable dismissal of stale approvals, or "require approval of the most recent reviewable push", on protected branches. Reviewers check the commit list, not only the files.

**To Ravi:** "GitHub showed what the branch contained. Your `git pull origin develop` merged all of `develop` into your branch; your reflog has the line. I rebuilt the branch without that merge and pushed it with a lease. Your four commits are intact; the last one has a new ID. Please do not revert a merge to shrink a pull request: section 6 of the write-up explains what it would have cost later."

**To the team lead:** "The pull request briefly contained unreleased work from `develop`. It was not merged. Had it been merged with the standing approval, 500 fixture files and an unreleased tokenizer change would have reached `main` unreviewed. The approval should be renewed."

**Postmortem.** Severity low, because nothing was merged; the near miss is the standing approval. What went well: the author raised it before merging. Contributing condition: two long-running branches with similar roles, and a habit of `git pull <remote> <branch>` typed from memory. Actions: stale-approval dismissal on `main`; a `git sync` alias in the team setup that always rebases onto the pull request's base.

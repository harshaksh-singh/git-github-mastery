# V025: Divergence, ancestry, and why Git has no parent-branch concept

- **Part.** 1: Foundations
- **Module.** 4
- **Planned minutes.** 22
- **Prerequisites.** V024
- **Textbook sections.** [Chapter 7: Branches](../../textbook/ch07-branches.md), sections 7.8 to 7.10
- **Demo scripts.** `labs/ch07/divergence.sh`, `labs/ch07/no-parent-branch.sh`, `labs/ch07/base-guess.sh`, `labs/ch07/upstream-preview.sh`

## HOOK

**[ON SCREEN]** "This branch is 3 commits ahead."

A status page says "3 commits ahead". Ahead of what?

An engineer opens a review for a small change, one commit, on a branch they created from a colleague's feature branch. The review shows forty changed files. Their one commit is in there somewhere, under everything the colleague did.

**[PAUSE]**

Nothing is broken. The engineer assumed that Git knows which branch their branch was created from, and compares against that. Git does not know. Nothing in a repository records which branch a branch was created from. Every comparison needs a base that you name, and "3 commits ahead" is meaningless until you say ahead of what.

## INTRODUCTION

You know what one branch is. This video is about the relation between two.

First, the arithmetic: divergence, the merge base, and how to count how far each side is ahead. Then the test behind "merged" and "can be fast-forwarded": is one commit an ancestor of another? Then the absence that surprises people: Git has no parent-branch concept. And last, a preview of remote-tracking branches and upstreams, because "ahead" and "behind" in `git status` are this same arithmetic against a ref that is only as fresh as your last fetch.

## LEARNING OBJECTIVES

After this video you can:

1. Compute the merge base of two branches, and count how far each is ahead.
2. Test whether one commit is an ancestor of another.
3. Explain why Git cannot say which branch a branch was created from.
4. Read `ahead` and `behind` against a remote-tracking branch as a statement about the last fetch.

## CONCEPT

**Divergence and ancestry.** In one sentence: two branches have diverged when neither tip is an ancestor of the other; their merge base is the best common ancestor, and "ahead" and "behind" are counted from it.

Precisely. A common ancestor is a commit reachable from both tips. The manual: "One common ancestor is better than another common ancestor if the latter is an ancestor of the former", and a best one is a merge base. There can be more than one, which the videos on merge take up.

**Ranges are sets of commits.** `A..B`, two dots, is everything reachable from B but not from A. `A...B`, three dots, is the symmetric difference: reachable from one side but not both. `git merge-base --is-ancestor A B` exits with 0 when A is an ancestor of B, and with 1 when it is not.

**The dots mean something else in `git diff`.** This is a known trap, and the textbook gives it a table.

**[ON SCREEN]** The notation table of section 7.8.

In `git log` and `git rev-list`, `A..B` is the commits reachable from B and not from A; `A...B` is the commits reachable from exactly one side. In `git diff`, `A..B` compares the two tips directly, the same as `git diff A B`; and `A...B` compares from the merge base of A and B to B: what B changed.

**No parent branch.** In one sentence: nothing in a repository records which branch a branch was created from; the only trace is a line in a local reflog, and every comparison needs a base that you name.

Look for the relationship in each place it could be. The new ref holds an ID. The commit it names has no field for a branch. The local configuration has no entry for it. The only mention is the reflog line `branch: Created from` the other branch, which exists in this clone and nowhere else, and which `git branch -D` or reflog expiry removes.

`git branch --contains` answers "which branches reach this commit", which is reachability, not origin.

The nearest thing to an answer is a guess. The field `%(is-base:<commit>)` of `git for-each-ref` marks, in the manual's words, "the ref that is most likely the ref used as a starting point for the branch that produced" the commit, chosen by a first-parent heuristic, and the guess changes with the refs that exist. It exists since Git 2.47, and the textbook's recommendation is: a hint for humans, never an input to automation.

This is why `git rebase` and `git merge` take the target as an argument: Git cannot infer it.

**[ON SCREEN]** Lower third: **GitHub**. A pull request has a base branch, chosen when it is opened, and stored by GitHub, not by Git. It is the one place where "created from" is recorded. And GitHub computes a pull request's changes from a merge base too.

**Remote-tracking branches and upstream.** In one sentence: a remote-tracking branch such as `origin/main` is a ref in your own repository that records the last position of a branch in another repository, and an upstream is two configuration lines that pair a local branch with one.

Remote-tracking branches live under `refs/remotes/<remote>/`, and `git fetch` updates them. The upstream of a branch B is configured by `branch.B.remote` and `branch.B.merge`, and `B@{upstream}`, or `@{u}`, names the corresponding remote-tracking branch. `git status -sb` and `git branch -v` compare a branch with its upstream. Nothing in that comparison talks to the server.

A branch created from another local branch has no upstream. A branch created from a remote-tracking branch gets one automatically, by `branch.autoSetupMerge`, which defaults to `true`.

**Risk labels.** Everything in this video is 🟢 SAFE, reading state or adding a ref, with two exceptions that appear once each: `git branch -D`, 🔴 DANGEROUS, whose five questions V023 answered; and `git fetch`, which is 🟢 SAFE.

**When this arithmetic is the wrong tool.** When the question is about content and not commits. A squash merge puts a branch's content into `main` without any of its commits, and then the ranges say "three commits ahead" about work that has landed. The next video deals with that blind spot.

## MENTAL MODEL

Picture a road that forks. Two cars start at the fork and drive down different arms. The fork is the merge base. "Ahead by three" is how far one car has driven from the fork; "behind by two" is how far the other has.

Now the limit of the picture, which is the point of the video. On a real road, each arm has a name painted on a sign at the fork, so you know which arm branched off which. In Git there is no sign. The fork is a commit, and both arms are equally "the road". Which one you call the trunk is your decision, made each time you compare.

For remote-tracking branches: `origin/main` is a photograph of where the other car was when you last looked. Until you look again, with a fetch, every "ahead" and "behind" is measured against the photograph.

## DIAGRAM

**[DIAGRAM]** The diagram of section 7.8. Draw the shared part, then the fork, then the two arms, then the counts.

```text
                       9500b9e---e12f113   main          <  left: 2 commits
                      /
  6eab4a9---03f74b9--+                 merge base: 03f74b9
                      \
                       22c856c---5351fa7---eaab34d   feature/rouge   > right: 3 commits
```

Two commits are shared. The fork is at `03f74b9`: that is the merge base. `main` has two commits of its own; `feature/rouge` has three. Three numbers and a merge base describe the relation: two, three, and `03f74b9`.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch07/divergence.sh`.

```bash
labs/run ch07/divergence
```

<!-- snippet: ch07/divergence/01-graph -->
```text
$ git log --oneline --graph --all
* e12f113 Add CI workflow
* 9500b9e Exact match: strip whitespace
| * eaab34d ROUGE-L: add tests
| * 5351fa7 ROUGE-L: tokenize on whitespace
| * 22c856c Add ROUGE-L metric
|/  
* 03f74b9 Add exact-match metric
* 6eab4a9 Add README
```
<!-- /snippet -->

`main` and `feature/rouge` after both received commits. From the graph alone, predict the merge base and the two counts.

<!-- snippet: ch07/divergence/02-merge-base -->
```text
$ git merge-base main feature/rouge
03f74b9ac8547c31330105153beb4b90c5ddeea8
$ git log --oneline main..feature/rouge
eaab34d ROUGE-L: add tests
5351fa7 ROUGE-L: tokenize on whitespace
22c856c Add ROUGE-L metric
$ git log --oneline feature/rouge..main
e12f113 Add CI workflow
9500b9e Exact match: strip whitespace
```
<!-- /snippet -->

The merge base is `03f74b9`. `main..feature/rouge` is what the feature has that `main` lacks: three commits. `feature/rouge..main` is the reverse: two.

<!-- snippet: ch07/divergence/03-count -->
```text
$ git rev-list --left-right --count main...feature/rouge
2	3
$ git log --oneline --left-right main...feature/rouge
< e12f113 Add CI workflow
< 9500b9e Exact match: strip whitespace
> eaab34d ROUGE-L: add tests
> 5351fa7 ROUGE-L: tokenize on whitespace
> 22c856c Add ROUGE-L metric
$ git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
feature/rouge 3 2
main 0 0
```
<!-- /snippet -->

`--left-right --count` prints the two numbers in the order of the operands: two commits only on the left side, three only on the right. The `%(ahead-behind:main)` field of `git for-each-ref` computes the same pair for every branch at once, from the branch's point of view.

Now the yes-or-no test. Predict the three exit statuses.

<!-- snippet: ch07/divergence/04-ancestor -->
```text
$ git merge-base --is-ancestor main feature/rouge
[exit status: 1]
$ git merge-base --is-ancestor main~2 feature/rouge
[exit status: 0]
$ git merge-base --is-ancestor main~2 main
[exit status: 0]
```
<!-- /snippet -->

`main` is not an ancestor of the feature branch: status 1. So merging the feature into `main` cannot be a fast-forward. `main~2`, the merge base, is an ancestor of both: status 0, twice.

<!-- snippet: ch07/divergence/05-diff-dots -->
```text
$ git diff --stat main...feature/rouge
 evalkit/rouge.py | 6 ++++++
 test_rouge.py    | 2 ++
 2 files changed, 8 insertions(+)
$ git diff --stat main..feature/rouge
 ci.yaml            | 1 -
 evalkit/metrics.py | 2 +-
 evalkit/rouge.py   | 6 ++++++
 test_rouge.py      | 2 ++
 4 files changed, 9 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

The dots trap. `git diff --stat main...feature/rouge`, three dots, lists the feature's own work. `main..feature/rouge`, two dots, also shows `main`'s two commits, reversed.

**[TERMINAL]** Caption bar: `labs/ch07/no-parent-branch.sh`.

```bash
labs/run ch07/no-parent-branch
```

Create a branch from `feature/rouge`, and look for the relationship. Predict where, if anywhere, the name `feature/rouge` is recorded.

**[PAUSE]**

<!-- snippet: ch07/no-parent-branch/01-created-from -->
```text
$ git switch -c feature/rouge-stemming feature/rouge
Switched to a new branch 'feature/rouge-stemming'
$ cat .git/refs/heads/feature/rouge-stemming
936bfbd7a649344c04602bfd7b614a32596b06a7
$ git cat-file -p HEAD
tree 8dd91332643c665aad37f53a444b610cabdfd9c0
parent 7a1ccc7e383d6b20935992a53b77015c81bbd978
author Lab User <you@example.com> 1788755820 +0530
committer Lab User <you@example.com> 1788755820 +0530

ROUGE-L: tokenize on whitespace
$ git config list --local
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
core.ignorecase=true
core.precomposeunicode=true
$ git reflog show feature/rouge-stemming
936bfbd feature/rouge-stemming@{0}: branch: Created from feature/rouge
```
<!-- /snippet -->

The new ref holds an ID. The commit has no field for a branch. The configuration has no entry. The only mention is the reflog line `branch: Created from feature/rouge`.

<!-- snippet: ch07/no-parent-branch/02-which-branch -->
```text
$ git log --oneline --graph --all
* 37431c0 ROUGE-L: stem tokens
* 936bfbd ROUGE-L: tokenize on whitespace
* 7a1ccc7 Add ROUGE-L metric
* 69d8252 Add exact-match metric
* 6eab4a9 Add README
$ git branch --contains feature/rouge
  feature/rouge
* feature/rouge-stemming
$ git branch --contains main
  feature/rouge
* feature/rouge-stemming
  main
```
<!-- /snippet -->

`git branch --contains feature/rouge` lists both branches: the commits of `feature/rouge` are on `feature/rouge-stemming` as much as on `feature/rouge`.

<!-- snippet: ch07/no-parent-branch/03-you-choose-the-base -->
```text
$ git log --oneline main..feature/rouge-stemming
37431c0 ROUGE-L: stem tokens
936bfbd ROUGE-L: tokenize on whitespace
7a1ccc7 Add ROUGE-L metric
$ git log --oneline feature/rouge..feature/rouge-stemming
37431c0 ROUGE-L: stem tokens
$ git branch -D feature/rouge
Deleted branch feature/rouge (was 936bfbd).
$ git log --oneline main..feature/rouge-stemming
37431c0 ROUGE-L: stem tokens
936bfbd ROUGE-L: tokenize on whitespace
7a1ccc7 Add ROUGE-L metric
```
<!-- /snippet -->

You choose the base. Against `main`, three commits. Against `feature/rouge`, one. Then the script deletes `feature/rouge` with `git branch -D` 🔴 DANGEROUS; its commits remain reachable from the stemming branch, so no commit loses its last name here. And the first answer does not change, because the commits never belonged to a branch.

**[TERMINAL]** Caption bar: `labs/ch07/base-guess.sh`.

```bash
labs/run ch07/base-guess
```

<!-- snippet: ch07/base-guess/01-guess -->
```text
$ git log --oneline --decorate
ad8abff (HEAD -> feature/rouge-stemming) ROUGE-L: stem tokens
936bfbd (feature/rouge) ROUGE-L: tokenize on whitespace
7a1ccc7 Add ROUGE-L metric
69d8252 (main) Add exact-match metric
6eab4a9 Add README
$ git for-each-ref --format='%(refname:short) %(is-base:feature/rouge-stemming)' refs/heads/main refs/heads/feature/rouge
feature/rouge (feature/rouge-stemming)
main 
$ git branch -D feature/rouge
Deleted branch feature/rouge (was 936bfbd).
$ git for-each-ref --format='%(refname:short) %(is-base:feature/rouge-stemming)' refs/heads/main
main (feature/rouge-stemming)
```
<!-- /snippet -->

`%(is-base:...)`: the guess, and how it changes with the refs that exist.

**[TERMINAL]** Caption bar: `labs/ch07/upstream-preview.sh`.

```bash
labs/run ch07/upstream-preview
```

<!-- snippet: ch07/upstream-preview/01-refs -->
```text
$ git for-each-ref --format='%(objectname:short) %(refname)'
d1e8f22 refs/heads/main
d1e8f22 refs/remotes/origin/main
$ git branch -vv
* main d1e8f22 [origin/main] Add exact-match metric
```
<!-- /snippet -->

Two refs, same ID, two namespaces: `refs/heads/main` and `refs/remotes/origin/main`.

<!-- snippet: ch07/upstream-preview/02-upstream -->
```text
$ git rev-parse --abbrev-ref '@{upstream}'
origin/main
$ git rev-parse --symbolic-full-name '@{u}'
refs/remotes/origin/main
$ git config get branch.main.remote
origin
$ git config get branch.main.merge
refs/heads/main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

`@{upstream}` resolves through the two configuration entries to `refs/remotes/origin/main`.

Now Asha pushes a commit to the server from her own clone. Your repository has not been told. Predict what `git status -sb` says.

**[PAUSE]**

<!-- snippet: ch07/upstream-preview/03-last-known-state -->
```text
# Asha has pushed one commit to the server. Your repository has not been told.
$ git status -sb
## main...origin/main
$ git rev-parse --short origin/main
d1e8f22
$ git fetch
From $LAB/ch07/upstream-preview/origin
   d1e8f22..0015820  main       -> origin/main
$ git rev-parse --short origin/main
0015820
$ git status -sb
## main...origin/main [behind 1]
```
<!-- /snippet -->

Before the fetch, no difference, because `origin/main` is what your repository last heard. `git fetch` 🟢 SAFE moves `origin/main`, and the status changes to `behind 1`. "Up to date with origin/main" is a statement about your copy of the remote, never about the remote itself.

<!-- snippet: ch07/upstream-preview/04-setting-upstream -->
```text
$ git switch -c feature/rouge
Switched to a new branch 'feature/rouge'
$ git rev-parse --abbrev-ref '@{upstream}'
fatal: no upstream configured for branch 'feature/rouge'
[exit status: 128]
$ git switch -c hotfix/ci origin/main
Switched to a new branch 'hotfix/ci'
branch 'hotfix/ci' set up to track 'origin/main'.
$ git branch -vv
  feature/rouge d1e8f22 Add exact-match metric
* hotfix/ci     0015820 [origin/main] Add CI workflow
  main          d1e8f22 [origin/main: behind 1] Add exact-match metric
```
<!-- /snippet -->

A branch created from another local branch has no upstream. A branch created from a remote-tracking branch gets one automatically, which is what the line `set up to track` reports.

## COMMON MISTAKES

1. **Saying "3 commits ahead" without a base.** Root cause: ahead and behind are counted from a merge base with a second ref, and Git has no default "parent" to compare with.
2. **Using two dots in `git diff` to see what a branch changed.** Root cause: in `git diff`, `A..B` compares the tips directly; `A...B` compares from the merge base.
3. **Asking Git which branch a branch was created from.** Root cause: a branch stores one commit ID and no origin; the only trace is a local reflog line.
4. **Reading "up to date with 'origin/main'" as the state of the server.** Root cause: `origin/main` is the last-known state, updated only by fetch or push.
5. **Feeding `%(is-base:...)` to automation.** Root cause: it is a first-parent heuristic whose answer changes with the refs that exist.

## PRODUCTION EXAMPLE

Stacked branches are where this bites, as the textbook describes. Branch B was created from branch A. A is merged with a squash, or deleted. B's "changes against `main`" suddenly include everything A did, because the base you implied no longer exists. That is the forty-file review from the hook. The repair is `git rebase --onto`, which moves B to its real base; the rebase videos cover it.

And the general rule for reports and dashboards: `[ahead 2, behind 3]` in `git status`, the counts on a pull request, "can this be fast-forwarded", and "which commits does this release contain" are all this arithmetic. Compute them with ranges, not with dates, and state the base.

## PRACTICE EXERCISE

Do Lab 4.4, "Counting divergence", in [`lab-manual/m04-refs-branches-head.md`](../../lab-manual/m04-refs-branches-head.md).

For each pair of branches in the lab, write the merge base and the two counts from the graph before you run `git merge-base` and `git rev-list --left-right --count`. Then predict the exit status of `--is-ancestor` in both directions.

## INTERVIEW QUESTION

Q108: "Does Git know which branch a branch was created from? What is the closest it can offer, and why is a pull request's base branch not the same thing?"

Answer aloud. A strong answer goes through the places where such a fact could be stored and says what each holds. It names the local trace and the heuristic, with the limits of both, and then separates the layers: what Git stores, and what the platform stores.

## RECAP

You should now be able to say: two branches have diverged when neither tip is an ancestor of the other. The merge base is their best common ancestor, and I count each side from it with `git rev-list --left-right --count A...B`. `git merge-base --is-ancestor` answers ancestry with its exit status. In `git log`, two dots and three dots select sets of commits; in `git diff`, three dots means "from the merge base". Git records no parent branch, so I name the base in every comparison. And `ahead` and `behind` against `origin/main` describe my last fetch, not the server.

## HOMEWORK

- Read sections 7.8 to 7.10 of [Chapter 7](../../textbook/ch07-branches.md).
- Challenge: Exercise 4.6, Level 2, "from which branch was it created?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

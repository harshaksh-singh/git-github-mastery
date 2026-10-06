# Module 21 labs: Pull requests, review, and the fork workflow

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. Read [Chapter 17](../textbook/ch17-pull-requests.md) first; each lab names the sections it uses. Every transcript under "Expected output" is real output of a replay script in `labs/ch17/`. Nothing in this file was run against GitHub: what GitHub shows is described from its documentation, with the link, and you record what you actually see.

## How these labs work

Each lab has two parts.

**Part A, local.** A bare repository on disk plays the platform, and separate clones play you, Asha (the maintainer) and Ravi. You type the commands in the lab shell. A setup script builds the starting state; a replay script produced the transcripts printed here.

```bash
bash labs/ch17/setup-21-2-wrong-base.sh       # build (or rebuild) the starting state of Lab 21.2
labs/shell m21-2                              # open the lab shell in that sandbox, then type the commands
labs/run ch17/lab-21-2-wrong-base             # or: watch the exact replay that the book prints
```

Commits made by a setup script have the same IDs as in the book. Commits you make by hand have other IDs, because the commit time is part of the ID. `$LAB` in a transcript stands for the lab root. A line `[exit status: N]` is added by the replay tool; in your own shell, `echo $?` right after a command prints the same number.

**Part B, on GitHub.** The same situation in a real repository in your practice organization.

> **Run Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub (Chapter 16: Authentication explains the mechanism). Part B commands are shown without output, because nothing here was captured from GitHub.

### One-time preparation for Part B

You need the practice organization of Lab 19.1 (Chapter 15: GitHub) and a working `gh auth status` (Module 20). A second GitHub account, or a teammate, is optional in this module and required in Lab 23.2.

1. Build the starter repository. It contains the four commits that the book's transcripts start from, with the same commit IDs:

```bash
bash labs/ch17/setup-21-0-practice-repo.sh
```

The script prints the directory. With the default lab root it is `~/git-mastery-labs/hands-on/m21-github/ticket-router-lab`, the path used below. Once you have published the repository, the script leaves the directory alone, so running it again (or `labs/verify-all.sh`) cannot destroy your work.

2. In your **normal shell**, go to the directory the script printed, and publish it as a public repository in your organization. Replace `your-practice-org` and `your-username`:

```bash
ORG=your-practice-org
ME=your-username
cd ~/git-mastery-labs/hands-on/m21-github/ticket-router-lab
git log --oneline
gh repo create "$ORG/ticket-router-lab" --public --source . --remote origin --push
gh repo edit "$ORG/ticket-router-lab" --enable-merge-commit --enable-squash-merge --enable-rebase-merge
gh repo view "$ORG/ticket-router-lab" --web
```

The repository must be public: on a Free plan the rules of Module 23 work only in public repositories ([about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)). The four starter commits carry the lab identity `Asha Rao <asha@example.com>`, which is no GitHub account, so GitHub shows them without a linked profile. Commits you make from now on carry your own identity. Set `ORG` and `ME` again in every new terminal.

## Lab 21.1: A full fork and pull request cycle

### Objective

Carry one change through the whole fork-and-pull cycle and say, at every step, which ref moved in which of the three repositories: upstream, your fork, your clone. Then recover from the most common fork mistake, a commit on the fork's default branch.

### Prerequisites

Chapter 17, sections 17.2 and 17.15. Chapter 12, section 12.10 (two remotes). Lab 7.5.

### Setup

**Part A.**

```bash
bash labs/ch17/setup-21-1-fork-cycle.sh
labs/shell m21-1
```

The sandbox contains `server/ticket-router.git` (upstream), `forks/you/ticket-router.git` (your fork), `you/ticket-router` (your clone, with `origin` and `upstream` configured) and `asha/ticket-router` (the maintainer's clone). Upstream gained one commit after you forked.

**Part B.** The one-time preparation above.

### Commands

**Part A, in the lab shell.**

```bash
# 1. Where you are
cd you/ticket-router
git remote -v
git branch -vv

# 2. How far is the fork behind upstream?
git fetch upstream
git rev-list --left-right --count upstream/main...origin/main

# 3. A branch from upstream's main, one commit, pushed to the fork
git switch -c docs/queues --no-track upstream/main
printf '\n## Queues\n\nbilling, technical, general\n' >> README.md
git commit -am "List the queues in the README"
git push -u origin docs/queues

# 4. Predict the pull request before it exists
git log --oneline upstream/main..docs/queues
git diff --stat upstream/main...docs/queues

# 5. "Open the pull request": upstream takes the head commit under refs/pull/
git -C ../../server/ticket-router.git fetch ../../forks/you/ticket-router.git docs/queues:refs/pull/1/head
git ls-remote upstream

# 6. The maintainer checks it out and merges it
cd ../../asha/ticket-router
git fetch origin pull/1/head:pr-1
git log --oneline main..pr-1
git merge --no-ff -m "Merge pull request #1 from you/docs/queues" pr-1
git push origin main

# 7. You bring clone and fork back in line, and clean up
cd ../../you/ticket-router
git switch main
git fetch upstream
git merge --ff-only upstream/main
git push origin main
git branch -d docs/queues
git push origin --delete docs/queues
```

**Part B, in your normal shell.** You are the contributor and, as owner of the organization, also the maintainer.

```bash
mkdir -p ~/gh-practice && cd ~/gh-practice
gh repo fork "$ORG/ticket-router-lab" --clone
cd ticket-router-lab
git remote -v
git fetch upstream
git rev-list --left-right --count upstream/main...origin/main

git switch -c docs/queues --no-track upstream/main
printf '\n## Queues\n\nbilling, technical, general\n' >> README.md
git commit -am "List the queues in the README"
git push -u origin docs/queues
gh pr create --repo "$ORG/ticket-router-lab" --base main --head "$ME:docs/queues" \
  --title "List the queues in the README" --body "Lab 21.1"

# Look at what was created (use the number that gh pr create printed, here 1)
gh pr view 1 --repo "$ORG/ticket-router-lab" --json number,baseRefName,headRefName,headRefOid,isCrossRepository,maintainerCanModify,mergeable
git ls-remote upstream 'refs/pull/*'
git fetch upstream pull/1/head:pr-1
git rev-parse pr-1 docs/queues

# Merge as the maintainer, then sync
gh pr merge 1 --repo "$ORG/ticket-router-lab" --merge
git switch main
git fetch upstream
git merge --ff-only upstream/main
git push origin main
git branch -d docs/queues pr-1
git push origin --delete docs/queues
```

### Expected output

**Part A.**

<!-- snippet: ch17/lab-21-1-fork-cycle/01-where-you-are -->
```text
$ cd you/ticket-router
$ git remote -v
origin	../../forks/you/ticket-router.git (fetch)
origin	../../forks/you/ticket-router.git (push)
upstream	../../server/ticket-router.git (fetch)
upstream	../../server/ticket-router.git (push)
$ git branch -vv
* main 9a383e5 [origin/main] Add classifier test
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-1-fork-cycle/02-fetch-upstream -->
```text
$ git fetch upstream
From ../../server/ticket-router
 * [new branch]      main       -> upstream/main
$ git rev-list --left-right --count upstream/main...origin/main
1	0
```
<!-- /snippet -->

`1 0`: one commit that only upstream has, none that only the fork has.

<!-- snippet: ch17/lab-21-1-fork-cycle/03-branch-commit-push -->
```text
$ git switch -c docs/queues --no-track upstream/main
Switched to a new branch 'docs/queues'
$ printf '\n## Queues\n\nbilling, technical, general\n' >> README.md
$ git commit -am "List the queues in the README"
[docs/queues c6c03ef] List the queues in the README
 1 file changed, 4 insertions(+)
$ git push -u origin docs/queues
To ../../forks/you/ticket-router.git
 * [new branch]      docs/queues -> docs/queues
branch 'docs/queues' set up to track 'origin/docs/queues'.
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-1-fork-cycle/04-predict-the-pr -->
```text
$ git log --oneline upstream/main..docs/queues
c6c03ef List the queues in the README
$ git diff --stat upstream/main...docs/queues
 README.md | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-1-fork-cycle/05-open-pr -->
```text
# On GitHub: gh pr create. Here the upstream repository takes the head commit under refs/pull/:
$ git -C ../../server/ticket-router.git fetch ../../forks/you/ticket-router.git docs/queues:refs/pull/1/head
From ../../forks/you/ticket-router
 * [new branch]      docs/queues -> refs/pull/1/head
$ git ls-remote upstream
01822edaea9cc204391c1b9e3a04edecbc94e930	HEAD
01822edaea9cc204391c1b9e3a04edecbc94e930	refs/heads/main
c6c03ef3b6894bbb4126080285bcd7da0f27917b	refs/pull/1/head
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-1-fork-cycle/06-maintainer -->
```text
# Asha, the maintainer of upstream:
$ cd ../../asha/ticket-router
$ git fetch origin pull/1/head:pr-1
From ../../server/ticket-router
 * [new ref]         refs/pull/1/head -> pr-1
$ git log --oneline main..pr-1
c6c03ef List the queues in the README
# On GitHub: gh pr merge --merge. In plain Git:
$ git merge --no-ff -m "Merge pull request #1 from you/docs/queues" pr-1
Merge made by the 'ort' strategy.
 README.md | 4 ++++
 1 file changed, 4 insertions(+)
$ git push origin main
To ../../server/ticket-router.git
   01822ed..a6d95e0  main -> main
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-1-fork-cycle/07-sync -->
```text
$ cd ../../you/ticket-router
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git fetch upstream
From ../../server/ticket-router
   01822ed..a6d95e0  main       -> upstream/main
$ git merge --ff-only upstream/main
Updating 9a383e5..a6d95e0
Fast-forward
 README.md           | 4 ++++
 config/routing.yaml | 2 +-
 2 files changed, 5 insertions(+), 1 deletion(-)
$ git push origin main
To ../../forks/you/ticket-router.git
   9a383e5..a6d95e0  main -> main
$ git branch -d docs/queues
Deleted branch docs/queues (was c6c03ef).
$ git push origin --delete docs/queues
To ../../forks/you/ticket-router.git
 - [deleted]         docs/queues
```
<!-- /snippet -->

**Part B, described from the documentation (not captured).**

- `gh repo fork --clone` makes the fork your `origin` and the organization's repository `upstream` (`gh repo fork --help`: "the new fork is set to be your `origin` remote and any existing origin remote is renamed to `upstream`").
- `gh pr create` prints the URL of the new pull request (`gh pr create --help`).
- `git ls-remote upstream 'refs/pull/*'` should list `refs/pull/1/head` at your commit. The documentation says GitHub creates refs "that point to the pull request's head branch and, when possible, to a simulated merge result" ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#pull-request-refs-and-merge-branches), read 2 October 2026), so expect `refs/pull/1/merge` as well, since this pull request merges cleanly. Write down what you see.
- `git rev-parse pr-1 docs/queues` should print the same ID twice.
- In the JSON, `isCrossRepository` should be true (the head is in your fork). `mergeable` carries the GraphQL value `MERGEABLE`, `CONFLICTING` or `UNKNOWN`, the last meaning "still being calculated" ([GraphQL reference, MergeableState](https://docs.github.com/en/graphql/reference/pulls)); ask again after a moment.

### What happened internally

Three repositories, and no command touched more than one of them at a time. Your push wrote `refs/heads/docs/queues` in the **fork**. Opening the pull request wrote `refs/pull/1/head` in **upstream**; in Part A you did that by hand with a fetch that ran inside the upstream repository, which is the Git-level content of "open a pull request". The merge moved `refs/heads/main` in upstream only. Your fork's `main` moved when you pushed to it in step 7, and not before: a fork is never updated by its upstream.

The pull request itself, its title, its number and its state, is in none of the three. It is a GitHub object (Chapter 17, section 17.2).

### Checkpoint

<!-- snippet: ch17/lab-21-1-fork-cycle/08-checkpoint -->
```text
$ git rev-list --left-right --count upstream/main...origin/main
0	0
$ git log --oneline --graph -4
*   a6d95e0 Merge pull request #1 from you/docs/queues
|\  
| * c6c03ef List the queues in the README
|/  
* 01822ed Raise the confidence threshold to 0.7
* 9a383e5 Add classifier test
```
<!-- /snippet -->

`0 0`, and the merge commit is on top. In Part B the same two commands must give `0 0` and a merge commit whose second parent is your commit.

### Failure scenario

The most common fork mistake: a commit made directly on `main` of the fork, and pushed. Then upstream moves.

```bash
printf '\nSee CONTRIBUTING.md before you open a pull request.\n' >> README.md
git commit -q -am "Point to the contributing guide"
git push -q origin main
git -C ../../asha/ticket-router commit -q --allow-empty -m 'Start the 1.1 cycle'
git -C ../../asha/ticket-router push -q origin main
git fetch upstream
git merge --ff-only upstream/main
git rev-list --left-right --count upstream/main...origin/main
```

<!-- snippet: ch17/lab-21-1-fork-cycle/09-failure -->
```text
# The mistake: a commit made directly on main of the fork, and pushed.
$ printf '\nSee CONTRIBUTING.md before you open a pull request.\n' >> README.md
$ git commit -q -am "Point to the contributing guide"
$ git push -q origin main
# Meanwhile upstream moves (Asha):
$ git -C ../../asha/ticket-router commit -q --allow-empty -m 'Start the 1.1 cycle'
$ git -C ../../asha/ticket-router push -q origin main
$ git fetch upstream
From ../../server/ticket-router
   a6d95e0..eb7f7af  main       -> upstream/main
$ git merge --ff-only upstream/main
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
$ git rev-list --left-right --count upstream/main...origin/main
1	1
```
<!-- /snippet -->

`1 1`: the fork's `main` has diverged from upstream. A fast-forward is impossible. On GitHub, `gh repo sync` would refuse, and `gh repo sync --force` would hard-reset the fork's branch and discard your commit (`gh repo sync --help`).

### Recovery

Keep the commit on a branch of its own, then put `main` back on upstream's history.

```bash
git switch -c docs/contributing-pointer
git branch -f --no-track main upstream/main
git push --force-with-lease origin main
git push -u origin docs/contributing-pointer
```

<!-- snippet: ch17/lab-21-1-fork-cycle/10-recovery -->
```text
# Keep the commit on a branch of its own, then put main back on the upstream history.
$ git switch -c docs/contributing-pointer
Switched to a new branch 'docs/contributing-pointer'
$ git branch -f --no-track main upstream/main
$ git push --force-with-lease origin main
To ../../forks/you/ticket-router.git
 + 8997ab9...eb7f7af main -> main (forced update)
$ git push -u origin docs/contributing-pointer
To ../../forks/you/ticket-router.git
 * [new branch]      docs/contributing-pointer -> docs/contributing-pointer
branch 'docs/contributing-pointer' set up to track 'origin/docs/contributing-pointer'.
```
<!-- /snippet -->

`--no-track` matters. Without it, `git branch -f main upstream/main` also makes `upstream/main` the upstream of your `main`, and a later bare `git push` on `main` would address the shared repository. The replay script was first written without the option and printed "branch 'main' set up to track 'upstream/main'".

In Part B, do the same in your fork clone if you want to see it on GitHub: make the stray commit, push it, merge any small pull request into the organization's `main` so that upstream moves, and repeat the four recovery commands.

### Verification

<!-- snippet: ch17/lab-21-1-fork-cycle/11-verification -->
```text
$ git rev-list --left-right --count upstream/main...origin/main
0	0
$ git log --oneline upstream/main..docs/contributing-pointer
8997ab9 Point to the contributing guide
$ git branch -vv
* docs/contributing-pointer 8997ab9 [origin/docs/contributing-pointer] Point to the contributing guide
  main                      eb7f7af [origin/main] Start the 1.1 cycle
```
<!-- /snippet -->

`0 0` again, the stray commit is alone on its branch and ready to become a pull request, and `main` still tracks `origin/main`.

### Questions

1. In step 5 of Part A, in which repository did the `git fetch` run, and which repository gained a ref? Why does that one command capture the Git side of "opening a pull request"?
2. After the maintainer merged, your fork's `main` was still behind. Which command updated it, and what would have happened to the fork if you had never run it?
3. Why did the lab start the branch from `upstream/main` and not from `main`?
4. In the failure scenario, `git rev-list --left-right --count` printed `1 1`. What is each number counting?
5. Part B: what did `git ls-remote upstream 'refs/pull/*'` list? Which of the refs can you push to?
6. Part B: `git branch -d docs/queues` worked without complaint after the merge. Would it also have worked after "Squash and merge"? Explain.

## Lab 21.2: A pull request against the wrong base

### Objective

Predict what a pull request against the wrong base lists, find the base that fits the branch, and repair it both ways: by changing the base and by transplanting the branch. See why a plain rebase does not repair it.

### Prerequisites

Chapter 17, sections 17.3 and 17.12. Chapter 9 for `git rebase --onto`. Chapter 14A, section 14A.8 for ranges.

### Setup

**Part A.**

```bash
bash labs/ch17/setup-21-2-wrong-base.sh
labs/shell m21-2
```

The server has `main` and `release/1.0`. You created `fix/empty-subject` from `main`, with one commit, and pushed it. The fix is meant for the release branch.

**Part B.** The starter repository on GitHub, after Lab 21.1 (its `main` is ahead of the first four commits).

### Commands

**Part A, in the lab shell.**

```bash
# 1. Observe
cd you/ticket-router
git status -sb
git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject

# 2. What a pull request with base release/1.0 would list and show
git log --oneline origin/release/1.0..fix/empty-subject
git diff --stat origin/release/1.0...fix/empty-subject

# 3. Diagnose: which base makes this a one-commit pull request?
for b in origin/main origin/release/1.0; do echo "$b: $(git rev-list --count $b..fix/empty-subject) commits"; done
git log --oneline -1 $(git merge-base origin/release/1.0 fix/empty-subject)
git log --oneline -1 $(git merge-base origin/main fix/empty-subject)

# 4. Transplant the one commit onto the release branch (keep a backup first)
git branch backup/fix-empty-subject
git rebase --onto origin/release/1.0 origin/main fix/empty-subject
git log --oneline origin/release/1.0..fix/empty-subject
git diff --stat origin/release/1.0...fix/empty-subject

# 5. Publish the rewritten branch
git push
git push --force-with-lease
```

**Part B, in your normal shell.** In the starter repository directory (`origin` is the organization's repository):

```bash
cd ~/git-mastery-labs/hands-on/m21-github/ticket-router-lab
git switch main && git pull --ff-only
git push origin 9a383e5:refs/heads/release/1.0          # the release branch starts at the fourth starter commit

git switch -c fix/empty-subject main
sed -i '' 's/ticket\["subject"\]/ticket.get("subject", "")/' router/classify.py
git commit -am "Accept tickets without a subject"
git push -u origin fix/empty-subject
gh pr create --base release/1.0 --title "Accept tickets without a subject" --body "Lab 21.2"

gh pr view --json commits --jq '.commits | length'
gh pr diff --name-only

git fetch origin
git rebase --onto origin/release/1.0 origin/main fix/empty-subject
git push --force-with-lease
gh pr view --json commits --jq '.commits | length'
gh pr diff --name-only
gh pr close fix/empty-subject --delete-branch
```

### Expected output

**Part A.**

<!-- snippet: ch17/lab-21-2-wrong-base/01-observe -->
```text
$ cd you/ticket-router
$ git status -sb
## fix/empty-subject...origin/fix/empty-subject
$ git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject
* 5de30a9 Accept tickets without a subject
* 29be88c Describe how to run the tests
* 7e13c3d Raise the confidence threshold to 0.7
| * bc944fd Set version 1.0.0
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-2-wrong-base/02-pr-view -->
```text
$ git log --oneline origin/release/1.0..fix/empty-subject
5de30a9 Accept tickets without a subject
29be88c Describe how to run the tests
7e13c3d Raise the confidence threshold to 0.7
$ git diff --stat origin/release/1.0...fix/empty-subject
 README.md           | 2 ++
 config/routing.yaml | 2 +-
 router/classify.py  | 2 +-
 3 files changed, 4 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-2-wrong-base/03-diagnose -->
```text
$ for b in origin/main origin/release/1.0; do echo "$b: $(git rev-list --count $b..fix/empty-subject) commits"; done
origin/main: 1 commits
origin/release/1.0: 3 commits
$ git log --oneline -1 $(git merge-base origin/release/1.0 fix/empty-subject)
9a383e5 Add classifier test
$ git log --oneline -1 $(git merge-base origin/main fix/empty-subject)
29be88c Describe how to run the tests
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-2-wrong-base/04-transplant -->
```text
$ git branch backup/fix-empty-subject
$ git rebase --onto origin/release/1.0 origin/main fix/empty-subject
Rebasing (1/1)
Successfully rebased and updated refs/heads/fix/empty-subject.
$ git log --oneline origin/release/1.0..fix/empty-subject
fddea5e Accept tickets without a subject
$ git diff --stat origin/release/1.0...fix/empty-subject
 router/classify.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-2-wrong-base/05-republish -->
```text
$ git push
To ../../server/ticket-router.git
 ! [rejected]        fix/empty-subject -> fix/empty-subject (non-fast-forward)
error: failed to push some refs to '../../server/ticket-router.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../../server/ticket-router.git
 + 5de30a9...fddea5e fix/empty-subject -> fix/empty-subject (forced update)
```
<!-- /snippet -->

**Part B, described from the documentation (not captured).** The first `gh pr view` should print a number greater than 1: your commit plus every commit that `main` has and `release/1.0` lacks, because the commit list is `base..head` and the diff is the three-dot diff ([branches reference](https://docs.github.com/en/pull-requests/reference/branches#three-dot-and-two-dot-git-diff-comparisons), read 2 October 2026). `gh pr diff --name-only` should list `README.md` next to `router/classify.py`. After the transplant and the forced push, the same commands should print `1` and one file. GitHub notes that after a force push review comments can become outdated ([troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#avoid-force-pushes)).

### What happened internally

Nothing was wrong with any commit. The pull request asked "what does the head have that `release/1.0` does not", and the honest answer included two commits of `main`, because the branch was built on them. The merge base of your branch with `release/1.0` is the old fork point `9a383e5`; with `main` it is `main`'s tip.

`git rebase --onto origin/release/1.0 origin/main fix/empty-subject` selected the commits in `origin/main..fix/empty-subject`, one commit, and replayed it on top of `origin/release/1.0`. The commit got a new parent, so it got a new ID, and the branch ref moved to it. The old commit is still in your repository, reachable from `backup/fix-empty-subject` and from the reflog.

### Checkpoint

<!-- snippet: ch17/lab-21-2-wrong-base/06-checkpoint -->
```text
$ git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject
* fddea5e Accept tickets without a subject
* bc944fd Set version 1.0.0
| * 29be88c Describe how to run the tests
| * 7e13c3d Raise the confidence threshold to 0.7
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

The branch now grows out of `release/1.0`.

### Failure scenario

The repair that sounds right: "rebase onto the base". Try it on a copy of the original branch.

```bash
git switch -c try/plain-rebase backup/fix-empty-subject
git rebase origin/release/1.0
git log --oneline origin/release/1.0..try/plain-rebase
git diff --stat origin/release/1.0...try/plain-rebase
```

<!-- snippet: ch17/lab-21-2-wrong-base/07-failure -->
```text
# The repair that sounds right and is not: a plain rebase onto the base branch.
$ git switch -c try/plain-rebase backup/fix-empty-subject
Switched to a new branch 'try/plain-rebase'
$ git rebase origin/release/1.0
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/try/plain-rebase.
$ git log --oneline origin/release/1.0..try/plain-rebase
c6cf322 Accept tickets without a subject
1769c6a Describe how to run the tests
4163a0d Raise the confidence threshold to 0.7
$ git diff --stat origin/release/1.0...try/plain-rebase
 README.md           | 2 ++
 config/routing.yaml | 2 +-
 router/classify.py  | 2 +-
 3 files changed, 4 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

The rebase succeeded and repaired nothing: three commits, three files. It replayed every commit that `release/1.0` lacks, the two from `main` included, as new copies. A pull request from this branch would still carry unreleased work into the release.

### Recovery

```bash
git reflog -4 try/plain-rebase
git rebase --onto origin/release/1.0 HEAD~1
git log --oneline origin/release/1.0..try/plain-rebase
```

<!-- snippet: ch17/lab-21-2-wrong-base/08-recovery -->
```text
$ git reflog -4 try/plain-rebase
c6cf322 try/plain-rebase@{0}: rebase (finish): refs/heads/try/plain-rebase onto bc944fddb4e1954b66658884f1b781acb228d3e0
5de30a9 try/plain-rebase@{1}: branch: Created from backup/fix-empty-subject
$ git rebase --onto origin/release/1.0 HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/try/plain-rebase.
$ git log --oneline origin/release/1.0..try/plain-rebase
d54e915 Accept tickets without a subject
```
<!-- /snippet -->

`HEAD~1` as the upstream argument means "replay only the last commit". The reflog shows the way back to the state before the rebase, had you needed it.

### Verification

```bash
git rev-parse fix/empty-subject^{tree} try/plain-rebase^{tree}
git rev-list --count origin/release/1.0..fix/empty-subject
git switch -q fix/empty-subject
git branch -D try/plain-rebase backup/fix-empty-subject
git status -sb
```

<!-- snippet: ch17/lab-21-2-wrong-base/09-verification -->
```text
# Both branches now hold the same tree, one commit on top of release/1.0:
$ git rev-parse fix/empty-subject^{tree} try/plain-rebase^{tree}
4bd1b0b871a8113ed3b9bc4941489c45f19986c4
4bd1b0b871a8113ed3b9bc4941489c45f19986c4
$ git rev-list --count origin/release/1.0..fix/empty-subject
1
$ git switch -q fix/empty-subject
$ git branch -D try/plain-rebase backup/fix-empty-subject
Deleted branch try/plain-rebase (was d54e915).
Deleted branch backup/fix-empty-subject (was 5de30a9).
$ git status -sb
## fix/empty-subject...origin/fix/empty-subject
```
<!-- /snippet -->

Both routes end at the same tree, one commit above `release/1.0`.

### Questions

1. Why did the pull request against `release/1.0` list three commits although you wrote one?
2. The diagnosis loop printed a count per candidate base. State the rule it applies in one sentence.
3. `git rebase --onto A B C`: say in words which commits are replayed and where.
4. Why was the plain `git push` rejected after the transplant, and why is `--force-with-lease` acceptable here?
5. The plain rebase in the failure scenario reported success. How would you have noticed, before pushing, that it had not helped?
6. When is "change the base of the pull request" the right repair, and when is the transplant?

## Lab 21.3: The squash-then-reuse problem

### Objective

Reproduce a pull request that lists commits which were already merged, and that conflicts in a file only you edit. Explain it from the merge base, repair the branch, and state the habit that prevents it.

### Prerequisites

Chapter 17, sections 17.8, 17.9 and 17.12. Chapter 8, section 8.12 (`--squash`).

### Setup

**Part A.**

```bash
bash labs/ch17/setup-21-3-squash-reuse.sh
labs/shell m21-3
```

Pull request 1 from `feature/priority-routing` was squash-merged into `main`. The branch still exists, on the server and in your clone.

**Part B.** The starter repository on GitHub.

### Commands

**Part A, in the lab shell.**

```bash
# 1. Observe
cd you/ticket-router
git status -sb
git log --oneline --graph origin/main feature/priority-routing

# 2. Keep working on the old branch: one follow-up commit
printf '\n\ndef is_urgent(ticket):\n    return priority(ticket) == "high"\n' >> router/priority.py
git commit -am "Add is_urgent helper"
git push

# 3. What pull request 2 would list and show, and what you really changed
git log --oneline origin/main..feature/priority-routing
git diff --stat origin/main...feature/priority-routing
git show --stat --format="%h %s" HEAD

# 4. Its test merge, and the reason
git merge-tree --write-tree --name-only origin/main feature/priority-routing
git log --oneline -1 $(git merge-base origin/main feature/priority-routing)

# 5. Repair: move only the new commit onto main
git branch before-fix
git rebase --onto origin/main HEAD~1
git log --oneline origin/main..feature/priority-routing
git diff --stat origin/main...feature/priority-routing
git merge-tree --write-tree origin/main feature/priority-routing
git push --force-with-lease
```

**Part B, in your normal shell.**

```bash
cd ~/git-mastery-labs/hands-on/m21-github/ticket-router-lab
git switch main && git pull --ff-only
git switch -c feature/priority-routing main
printf 'URGENT_WORDS = ["outage", "down", "urgent"]\n' > router/priority.py
git add router/priority.py && git commit -m "Add urgent words"
printf '\n\ndef priority(ticket):\n    text = ticket.get("subject", "").lower()\n    return "high" if any(w in text for w in URGENT_WORDS) else "normal"\n' >> router/priority.py
git commit -am "Add priority scoring"
git push -u origin feature/priority-routing
gh pr create --base main --title "Add priority scoring" --body "Lab 21.3, pull request 1"
gh pr merge --squash                       # no --delete-branch: the branch stays

# Keep working on the same branch
printf '\n\ndef is_urgent(ticket):\n    return priority(ticket) == "high"\n' >> router/priority.py
git commit -am "Add is_urgent helper"
git push
gh pr create --base main --title "Add is_urgent helper" --body "Lab 21.3, pull request 2"
gh pr view --json commits,mergeable --jq '{commits: (.commits | length), mergeable: .mergeable}'
gh pr diff --name-only

# Repair, then finish properly
git fetch origin
git rebase --onto origin/main HEAD~1
git push --force-with-lease
gh pr view --json commits,mergeable --jq '{commits: (.commits | length), mergeable: .mergeable}'
gh pr merge --squash --delete-branch
gh repo edit --delete-branch-on-merge
```

### Expected output

**Part A.**

<!-- snippet: ch17/lab-21-3-squash-reuse/01-observe -->
```text
$ cd you/ticket-router
$ git status -sb
## feature/priority-routing...origin/feature/priority-routing
$ git log --oneline --graph origin/main feature/priority-routing
* 1b2b8ed Route high-priority tickets to an escalations queue (#1)
* 9aa221a Raise the confidence threshold to 0.7
| * 16d4788 Fix the name of the escalations queue
| * 12ae95d Route high-priority tickets to escalation
| * 44c1e7b Add priority scoring
|/  
* 9a383e5 Add classifier test
* f3e7ca9 Add routing config
* 53e7f57 Add keyword classifier
* fbbcc8d Add README
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-3-squash-reuse/02-follow-up -->
```text
$ printf '\n\ndef is_urgent(ticket):\n    return priority(ticket) == "high"\n' >> router/priority.py
$ git commit -am "Add is_urgent helper"
[feature/priority-routing 53e2eaf] Add is_urgent helper
 1 file changed, 4 insertions(+)
$ git push
To ../../server/ticket-router.git
   16d4788..53e2eaf  feature/priority-routing -> feature/priority-routing
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-3-squash-reuse/03-pr2-view -->
```text
$ git log --oneline origin/main..feature/priority-routing
53e2eaf Add is_urgent helper
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
$ git diff --stat origin/main...feature/priority-routing
 router/classify.py |  6 +++++-
 router/priority.py | 10 ++++++++++
 2 files changed, 15 insertions(+), 1 deletion(-)
$ git show --stat --format="%h %s" HEAD
53e2eaf Add is_urgent helper

 router/priority.py | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

Four commits and two files, for four added lines in one file.

<!-- snippet: ch17/lab-21-3-squash-reuse/04-pr2-conflict -->
```text
$ git merge-tree --write-tree --name-only origin/main feature/priority-routing
958088835f48ec7e6ebddaf1e88770300d439cab
router/priority.py

Auto-merging router/priority.py
CONFLICT (add/add): Merge conflict in router/priority.py
[exit status: 1]
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
9a383e5 Add classifier test
```
<!-- /snippet -->

<!-- snippet: ch17/lab-21-3-squash-reuse/05-fix -->
```text
$ git branch before-fix
$ git rebase --onto origin/main HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/priority-routing.
$ git log --oneline origin/main..feature/priority-routing
1da89f2 Add is_urgent helper
$ git diff --stat origin/main...feature/priority-routing
 router/priority.py | 4 ++++
 1 file changed, 4 insertions(+)
$ git merge-tree --write-tree origin/main feature/priority-routing
8dbd170faac439c0ec56c18ba8ea10381b7682c3
[exit status: 0]
$ git push --force-with-lease
To ../../server/ticket-router.git
 + 53e2eaf...1da89f2 feature/priority-routing -> feature/priority-routing (forced update)
```
<!-- /snippet -->

**Part B, described from the documentation (not captured).** GitHub's page on merge methods predicts the first observation: after squashing, "commits that you previously squashed and merged will be listed in the new pull request", and you "may also have conflicts that you have to repeatedly resolve" ([about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github#squashing-your-merge-commits), read 2 October 2026). So the first `gh pr view` should report three commits, and a `mergeable` value of `CONFLICTING` once GitHub has computed it (`UNKNOWN` until then; the values are those of the [GraphQL MergeableState](https://docs.github.com/en/graphql/reference/pulls)). After the repair it should report one commit and `MERGEABLE`. None of this was captured here; record what you see.

### What happened internally

The squash commit on `main` has one parent. It contains the content of your three commits and no link to them. So for Git your branch was never merged: the merge base of `main` and the branch is still the commit where you first branched. `origin/main..feature/priority-routing` therefore lists all four commits, and the three-way merge compares two sides that both "added `router/priority.py`" since that base, with different content: an add/add conflict.

`git rebase --onto origin/main HEAD~1` replayed the single commit after `HEAD~1` onto `main`. On `main`, `router/priority.py` already exists with the content of pull request 1, so your commit applies as the four-line addition it always was.

### Checkpoint

<!-- snippet: ch17/lab-21-3-squash-reuse/06-checkpoint -->
```text
$ git log --oneline --graph -3
* 1da89f2 Add is_urgent helper
* 1b2b8ed Route high-priority tickets to an escalations queue (#1)
* 9aa221a Raise the confidence threshold to 0.7
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
1b2b8ed Route high-priority tickets to an escalations queue (#1)
```
<!-- /snippet -->

The merge base is now the squash commit.

### Failure scenario

What a plain rebase onto `main` does with the unrepaired branch:

```bash
git switch -c try/plain-rebase before-fix
git rebase origin/main
git status
```

<!-- snippet: ch17/lab-21-3-squash-reuse/07-failure -->
```text
# What a plain rebase onto main does with the same branch:
$ git switch -c try/plain-rebase before-fix
Switched to a new branch 'try/plain-rebase'
$ git rebase origin/main
Rebasing (1/4)
dropping 44c1e7b21c49dd09f0df26e7f5aa147834faba31 Add priority scoring -- patch contents already upstream
Rebasing (2/4)
Auto-merging router/classify.py
CONFLICT (content): Merge conflict in router/classify.py
error: could not apply 12ae95d... Route high-priority tickets to escalation
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 12ae95d... # Route high-priority tickets to escalation
[exit status: 1]
$ git status
interactive rebase in progress; onto 1b2b8ed
Last commands done (2 commands done):
   pick 44c1e7b # Add priority scoring
   pick 12ae95d # Route high-priority tickets to escalation
Next commands to do (2 remaining commands):
   pick 16d4788 # Fix the name of the escalations queue
   pick 53e2eaf # Add is_urgent helper
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'try/plain-rebase' on '1b2b8ed'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   router/classify.py

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

Git dropped the first commit, because replaying it changed nothing ("patch contents already upstream"). The second stops in a conflict: it writes a queue name that the squash commit already contains in its corrected form. You are being asked to resolve pull request 1 again.

### Recovery

```bash
git rebase --abort
git status -sb
git switch -q feature/priority-routing
git branch -D try/plain-rebase before-fix
```

<!-- snippet: ch17/lab-21-3-squash-reuse/08-recovery -->
```text
$ git rebase --abort
$ git status -sb
## try/plain-rebase
$ git switch -q feature/priority-routing
$ git branch -D try/plain-rebase before-fix
Deleted branch try/plain-rebase (was 53e2eaf).
Deleted branch before-fix (was 53e2eaf).
```
<!-- /snippet -->

`git rebase --abort` returns the branch to the state before the rebase. The repaired branch from step 5 is untouched.

### Verification

```bash
git rev-list --count origin/main..feature/priority-routing
git cherry -v origin/main feature/priority-routing
git status -sb
```

<!-- snippet: ch17/lab-21-3-squash-reuse/09-verification -->
```text
$ git rev-list --count origin/main..feature/priority-routing
1
$ git cherry -v origin/main feature/priority-routing
+ 1da89f2fc558ae0b76cc0133fd51b7b3410df5e4 Add is_urgent helper
$ git status -sb
## feature/priority-routing...origin/feature/priority-routing
```
<!-- /snippet -->

One commit, marked `+`: its patch is not on `main` yet.

### Questions

1. Why is the merge base of `main` and the branch unchanged after a squash merge? What would it be after "Create a merge commit"?
2. Pull request 2 conflicted in `router/priority.py`, a file that nobody but you has edited. Describe the three versions that the merge compared.
3. Why did the plain rebase drop the first commit and then conflict on the second?
4. In step 5 you rebased onto `origin/main` with `HEAD~1` as the second argument. What would `HEAD~2` have done?
5. Which repository setting prevents the situation, and which habit?
6. Would the same problem occur after "Rebase and merge"? What would a plain `git rebase origin/main` do in that case?

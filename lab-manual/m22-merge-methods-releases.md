# Module 22 labs: Merge methods and releases on GitHub

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. Read [Chapter 17](../textbook/ch17-pull-requests.md), sections 17.8 and 17.9, first. Releases are covered in Chapter 15: GitHub, and tags in [Chapter 14B](../textbook/ch14b-config-tags-signing.md). Every transcript under "Expected output" is real output of a replay script in `labs/ch17/`. Nothing in this file was run against GitHub: what GitHub shows is described from its documentation, with the link, and you record what you actually see.

## How these labs work

As in Module 21, each lab has a local Part A in the lab shell and a Part B on GitHub.

> **Run Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub. Part B needs the starter repository from "One-time preparation" in the [Module 21 labs](m21-pull-requests-forks.md), and `ORG` set to your practice organization in each new terminal.

In transcripts, a line `[exit status: N]` is added by the replay tool. In your own shell, `echo $?` right after a command prints the same number.

## Lab 22.1: The three merge methods compared

### Objective

Merge the same pull request three ways and compare what each method leaves on `main`: the graph, the commit IDs, author and committer, the tree, and what the contributor meets afterwards. Then read the same facts from real GitHub merges, including the two that the documentation does not state.

### Prerequisites

Chapter 17, sections 17.8 and 17.9. Chapter 8, sections 8.12 and 8.13. Chapter 9.

### Setup

**Part A.**

```bash
bash labs/ch17/setup-22-1-three-methods.sh
labs/shell m22-1
```

The sandbox contains three independent copies of one situation, in `merge/`, `squash/` and `rebase/`. Each has `server.git` (the shared repository), `asha` (the maintainer's clone) and `you` (your clone). In all of them your branch `feature/priority-routing` has three commits, and `main` has one commit the branch lacks.

**Part B.** The starter repository on GitHub, with all three merge methods enabled (done in the preparation).

### Commands

**Part A, in the lab shell.** You play Asha for steps 2 to 4.

```bash
# 1. Observe
ls
git -C merge/asha log --oneline --graph main origin/feature/priority-routing

# 2. Copy 1: "Create a merge commit"
cd merge/asha
git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing
git push origin main

# 3. Copy 2: "Squash and merge"
cd ../../squash/asha
git merge --squash origin/feature/priority-routing
git commit -m "Route high-priority tickets to an escalations queue (#1)"
git push origin main

# 4. Copy 3: "Rebase and merge"
cd ../../rebase/asha
git switch -c pr-1 origin/feature/priority-routing
git rebase main
git switch main
git merge --ff-only pr-1
git push origin main
cd ../..

# 5. Compare
for m in merge squash rebase; do echo "== $m"; git -C $m/asha log --graph --format="%h %an / %cn: %s" -5 main; done
for m in merge squash rebase; do git -C $m/asha rev-parse main^{tree}; done
for m in merge squash rebase; do echo "$m: $(git -C $m/asha rev-list --count main) commits, $(git -C $m/asha rev-list --count --merges main) merge"; done
for m in merge squash rebase; do git -C $m/asha merge-base --is-ancestor origin/feature/priority-routing main; echo "$m: exit status $?"; done

# 6. You, the contributor, clean up in each copy
git -C merge/you pull -q --ff-only
git -C merge/you branch -d feature/priority-routing
git -C rebase/you pull -q --ff-only
git -C rebase/you cherry -v main feature/priority-routing
git -C rebase/you branch -d feature/priority-routing
git -C squash/asha push origin --delete feature/priority-routing
git -C squash/you pull -q --ff-only --prune
git -C squash/you branch -vv
git -C squash/you branch -d feature/priority-routing
```

**Part B, in your normal shell.** One repository, three base branches that start at the same commit, three head branches that are the same commits. Each pull request is merged with a different method.

```bash
cd ~/git-mastery-labs/hands-on/m21-github/ticket-router-lab
git switch main && git pull --ff-only
for m in merge squash rebase; do git push origin main:refs/heads/base/$m; done

git switch -c pr/demo main
printf '\nRelease notes live in CHANGELOG.md.\n' >> README.md
git commit -am "Point to the changelog"
printf '# Changelog\n' > CHANGELOG.md
git add CHANGELOG.md && git commit -m "Add an empty changelog"
git log --format='%h %an / %cn %s' main..pr/demo
for m in merge squash rebase; do git push origin pr/demo:refs/heads/pr/$m; done

gh pr create --base base/merge  --head pr/merge  --title "Demo: merge commit"    --body "Lab 22.1"
gh pr create --base base/squash --head pr/squash --title "Demo: squash and merge" --body "Lab 22.1"
gh pr create --base base/rebase --head pr/rebase --title "Demo: rebase and merge" --body "Lab 22.1"
gh pr merge pr/merge  --merge
gh pr merge pr/squash --squash
gh pr merge pr/rebase --rebase

git fetch origin
for m in merge squash rebase; do echo "== $m"; git log --graph --format='%h %an / %cn %G? %s' -4 origin/base/$m; done
for m in merge squash rebase; do git rev-parse origin/base/$m^{tree}; done
git log --format=fuller -1 origin/base/squash
git cat-file -p origin/base/merge | grep -c '^gpgsig'
git cat-file -p origin/base/squash | grep -c '^gpgsig'
git cat-file -p origin/base/rebase | grep -c '^gpgsig'
```

### Expected output

**Part A.**

<!-- snippet: ch17/lab-22-1-three-methods/01-observe -->
```text
$ ls
asha
home
merge
ravi
rebase
server
squash
you
$ git -C merge/asha log --oneline --graph main origin/feature/priority-routing
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

<!-- snippet: ch17/lab-22-1-three-methods/02-merge-commit -->
```text
$ cd merge/asha
$ git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing
Merge made by the 'ort' strategy.
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push origin main
To ../server.git
   9aa221a..c4ec061  main -> main
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/03-squash -->
```text
$ cd ../../squash/asha
$ git merge --squash origin/feature/priority-routing
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -m "Route high-priority tickets to an escalations queue (#1)"
[main da48bba] Route high-priority tickets to an escalations queue (#1)
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push origin main
To ../server.git
   9aa221a..da48bba  main -> main
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/04-rebase -->
```text
$ cd ../../rebase/asha
$ git switch -c pr-1 origin/feature/priority-routing
Switched to a new branch 'pr-1'
branch 'pr-1' set up to track 'origin/feature/priority-routing'.
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/pr-1.
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git merge --ff-only pr-1
Updating 9aa221a..6d55949
Fast-forward
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push origin main
To ../server.git
   9aa221a..6d55949  main -> main
$ cd ../..
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/05-compare-graphs -->
```text
$ for m in merge squash rebase; do echo "== $m"; git -C $m/asha log --graph --format="%h %an / %cn: %s" -5 main; done
== merge
*   c4ec061 Asha Rao / Asha Rao: Merge pull request #1 from feature/priority-routing
|\  
| * 16d4788 Lab User / Lab User: Fix the name of the escalations queue
| * 12ae95d Lab User / Lab User: Route high-priority tickets to escalation
| * 44c1e7b Lab User / Lab User: Add priority scoring
* | 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
|/  
== squash
* da48bba Asha Rao / Asha Rao: Route high-priority tickets to an escalations queue (#1)
* 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
* f3e7ca9 Asha Rao / Asha Rao: Add routing config
* 53e7f57 Asha Rao / Asha Rao: Add keyword classifier
== rebase
* 6d55949 Lab User / Asha Rao: Fix the name of the escalations queue
* 8088296 Lab User / Asha Rao: Route high-priority tickets to escalation
* 15b9ff8 Lab User / Asha Rao: Add priority scoring
* 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/06-compare-trees -->
```text
$ for m in merge squash rebase; do git -C $m/asha rev-parse main^{tree}; done
beff5a60b5d7f4a2b93e41130391fc485f5970e0
beff5a60b5d7f4a2b93e41130391fc485f5970e0
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ for m in merge squash rebase; do echo "$m: $(git -C $m/asha rev-list --count main) commits, $(git -C $m/asha rev-list --count --merges main) merge"; done
merge: 9 commits, 1 merge
squash: 6 commits, 0 merge
rebase: 8 commits, 0 merge
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/07-ancestry -->
```text
$ for m in merge squash rebase; do git -C $m/asha merge-base --is-ancestor origin/feature/priority-routing main; echo "$m: exit status $?"; done
merge: exit status 0
squash: exit status 1
rebase: exit status 1
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/08-contributor -->
```text
# You, the contributor. Copy 1, merge commit:
$ git -C merge/you pull -q --ff-only
$ git -C merge/you branch -d feature/priority-routing
Deleted branch feature/priority-routing (was 16d4788).
# Copy 3, rebase. First ask whether the patches of the branch are on main:
$ git -C rebase/you pull -q --ff-only
$ git -C rebase/you cherry -v main feature/priority-routing
- 44c1e7b21c49dd09f0df26e7f5aa147834faba31 Add priority scoring
- 12ae95d534559f98f9aa705ed852f5a4700f6edd Route high-priority tickets to escalation
- 16d4788572b31e17e4c3104a1d9861a5ce2c47ea Fix the name of the escalations queue
$ git -C rebase/you branch -d feature/priority-routing
warning: deleting branch 'feature/priority-routing' that has been merged to
         'refs/remotes/origin/feature/priority-routing', but not yet merged to HEAD
Deleted branch feature/priority-routing (was 16d4788).
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-1-three-methods/09-contributor-squash -->
```text
# Copy 2, squash. Asha deletes the head branch on the server, as the platform offers after a merge:
$ git -C squash/asha push origin --delete feature/priority-routing
To ../server.git
 - [deleted]         feature/priority-routing
$ git -C squash/you pull -q --ff-only --prune
$ git -C squash/you branch -vv
  feature/priority-routing 16d4788 [origin/feature/priority-routing: gone] Fix the name of the escalations queue
* main                     da48bba [origin/main] Route high-priority tickets to an escalations queue (#1)
$ git -C squash/you branch -d feature/priority-routing
error: the branch 'feature/priority-routing' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/priority-routing'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

Your commit IDs for the merge commit, the squash commit and the rebased commits differ from the book's, because you created them at another time. The tree ID is the same as the book's: it depends only on content.

**Part B, described from the documentation (not captured).** From [pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges) and [about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), read 2 October 2026:

| Branch | The graph should show | Commit IDs of `pr/demo` | `gpgsig` count on the tip |
|---|---|---|---|
| `origin/base/merge` | a merge commit with your two commits behind it ("merged using the `--no-ff` option") | preserved | 1: "GitHub will automatically use GPG to sign commits you make using the web interface" |
| `origin/base/squash` | one new commit | absent | 1 |
| `origin/base/rebase` | two new commits in a line | absent: "always ... creates new commit SHAs" | 0: added "without commit signature verification" |

The three tree IDs should be identical. `%G?` should print `N` for the rebased commits. For the two signed commits it prints `E` when your machine does not have GitHub's public key (the letter means the signature cannot be checked; `git help log`, "PRETTY FORMATS"). Two facts are not stated in the documentation and are yours to read from `git log --format=fuller`: who the *committer* of each new commit is, and who the *author* of the squash commit is (Chapter 17, section 17.8 flags both). Write them down.

### What happened internally

The three methods compute the same merged content: one tree ID in all three copies. They differ in the commit objects that carry it.

The merge commit has two parents, so your three commits became ancestors of `main` under their original IDs. The squash commit has one parent: it holds the content of the branch and no link to it. The rebased commits are new objects, because each has a new parent and a new committer; their patches equal yours, which is what `git cherry` detects with `-`.

Step 6 shows the rule behind `git branch -d`: a branch may be deleted when it is merged into its upstream, or into `HEAD` if it has no upstream. In the rebase copy the branch still existed on the server, so `-d` deleted it with a warning. In the squash copy the upstream was gone, Git compared with `HEAD`, and refused.

### Checkpoint

Would merging the squashed branch change `main` at all?

```bash
git -C squash/you merge-tree --write-tree main feature/priority-routing
git -C squash/you rev-parse main^{tree}
git -C squash/you branch -D feature/priority-routing
```

<!-- snippet: ch17/lab-22-1-three-methods/10-checkpoint -->
```text
# Would merging the branch change main at all? Compare the merged tree with the tree of main:
$ git -C squash/you merge-tree --write-tree main feature/priority-routing
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git -C squash/you rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git -C squash/you branch -D feature/priority-routing
Deleted branch feature/priority-routing (was 16d4788).
```
<!-- /snippet -->

The merged tree equals the tree of `main`. The branch has nothing left to give, and `-D` is safe.

### Failure scenario

The pull request has to be undone on `main`. In the merge-commit copy, try the command you would use for any commit:

```bash
cd merge/you
git revert --no-edit HEAD
```

<!-- snippet: ch17/lab-22-1-three-methods/11-failure -->
```text
# Undo the pull request in the merge-commit copy, the way you would undo any commit:
$ cd merge/you
$ git revert --no-edit HEAD
error: commit c4ec06181f02934f7e7baab79ba6aab463472bae is a merge but no -m option was given.
fatal: revert failed
[exit status: 128]
```
<!-- /snippet -->

A merge commit has two parents, and Git will not guess which side is the mainline.

### Recovery

```bash
git show -s --format="%h parents: %p" HEAD
git revert --no-edit -m 1 HEAD
git diff --quiet HEAD~2 HEAD; echo "exit status: $?"
```

<!-- snippet: ch17/lab-22-1-three-methods/12-recovery -->
```text
$ git show -s --format="%h parents: %p" HEAD
c4ec061 parents: 9aa221a 16d4788
$ git revert --no-edit -m 1 HEAD
[main 800ea29] Revert "Merge pull request #1 from feature/priority-routing"
 Date: Mon Sep 7 11:10:00 2026 +0530
 2 files changed, 1 insertion(+), 11 deletions(-)
 delete mode 100644 router/priority.py
# The tree is back to what it was before the merge:
$ git diff --quiet HEAD~2 HEAD
[exit status: 0]
```
<!-- /snippet -->

`-m 1` keeps the first parent, `main` before the merge. The empty diff confirms that the tree is back to what it was. Remember the consequence from Chapter 8, section 8.18: merging the same branch again later brings nothing back until this revert is itself reverted.

On GitHub the same undo is `gh pr revert <number>`, which opens a pull request (`gh pr revert --help`).

### Verification

```bash
git log --oneline -3
git status -sb
git branch
```

<!-- snippet: ch17/lab-22-1-three-methods/13-verification -->
```text
$ git log --oneline -3
800ea29 Revert "Merge pull request #1 from feature/priority-routing"
c4ec061 Merge pull request #1 from feature/priority-routing
9aa221a Raise the confidence threshold to 0.7
$ git status -sb
## main...origin/main [ahead 1]
$ git branch
* main
```
<!-- /snippet -->

In Part B, clean up when you have recorded your observations:

```bash
for m in merge squash rebase; do git push origin --delete base/$m; done
git ls-remote --branches origin 'pr/*'     # delete what is listed with: git push origin --delete pr/<name>
git switch main && git branch -D pr/demo
```

If you switched on automatic deletion of head branches in Lab 21.3, the three `pr/` branches are already gone.

### Questions

1. The tree of `main` is identical in the three copies and the histories are not. What does that tell you about what a merge method decides?
2. In which copies is your original head commit an ancestor of `main`? Name two commands that behave differently because of it.
3. Why did `git branch -d` delete the branch in the rebase copy with only a warning, and refuse in the squash copy?
4. `git cherry` printed `-` for all three commits in the rebase copy. What would it print in the squash copy, and why?
5. Part B: which commits carry a `gpgsig` header, and who are the committers? What follows for a branch that requires signed commits?
6. Part B: who is the author of the squash commit, and are there `Co-authored-by` trailers? The documentation read for this course does not say; what did you observe?
7. For each method, how many commands undo the pull request on `main`, and what must you know to type them?

## Lab 22.2: A release from an annotated tag

### Objective

Create an annotated tag, publish it, and attach a GitHub Release to it. Then see what happens when the release is created first and the platform invents the tag, and repair it.

### Prerequisites

Chapter 14B, sections 14B.8 to 14B.12 (tags, `git describe`). Chapter 15: GitHub, for releases as GitHub objects.

### Setup

**Part A.**

```bash
bash labs/ch17/setup-22-2-annotated-tag-release.sh
labs/shell m22-2
```

A server, your clone and Asha's clone. Nothing is tagged.

**Part B.** The starter repository on GitHub.

### Commands

**Part A, in the lab shell.**

```bash
# 1. An annotated tag is an object of its own
cd you/ticket-router
git log --oneline -2
git tag -a v0.1.0 -m "ticket-router 0.1.0: keyword classifier"
git cat-file -t v0.1.0
git cat-file -p v0.1.0

# 2. Publish it and look at what the server stores
git push origin v0.1.0
git ls-remote --tags origin
git describe

# 3. What a release would point at
git for-each-ref --format="%(refname) %(objecttype) -> %(*objecttype) %(*objectname:short)" refs/tags
git rev-parse v0.1.0 "v0.1.0^{commit}" main
```

**Part B, in your normal shell.**

```bash
cd ~/git-mastery-labs/hands-on/m21-github/ticket-router-lab
git switch main && git pull --ff-only
git tag -a v0.1.0 -m "ticket-router 0.1.0: keyword classifier"
git push origin v0.1.0
gh release create v0.1.0 --verify-tag --notes-from-tag --title "ticket-router 0.1.0"
gh release view v0.1.0
gh release list
git ls-remote --tags origin
```

### Expected output

**Part A.**

<!-- snippet: ch17/lab-22-2-annotated-tag-release/01-tag -->
```text
$ cd you/ticket-router
$ git log --oneline -2
9a383e5 Add classifier test
f3e7ca9 Add routing config
$ git tag -a v0.1.0 -m "ticket-router 0.1.0: keyword classifier"
$ git cat-file -t v0.1.0
tag
$ git cat-file -p v0.1.0
object 9a383e547a1c8840f3c5c7b23bfab6120f366ed0
type commit
tag v0.1.0
tagger Lab User <you@example.com> 1788756180 +0530

ticket-router 0.1.0: keyword classifier
```
<!-- /snippet -->

<!-- snippet: ch17/lab-22-2-annotated-tag-release/02-push-tag -->
```text
$ git push origin v0.1.0
To ../../server/ticket-router.git
 * [new tag]         v0.1.0 -> v0.1.0
$ git ls-remote --tags origin
4f7a52d76df009522b0be5a3071462f507b67529	refs/tags/v0.1.0
9a383e547a1c8840f3c5c7b23bfab6120f366ed0	refs/tags/v0.1.0^{}
$ git describe
v0.1.0
```
<!-- /snippet -->

Two lines for one tag: the tag object, and with `^{}` the commit it points at.

<!-- snippet: ch17/lab-22-2-annotated-tag-release/03-release -->
```text
# On GitHub the next step is: gh release create v0.1.0 --verify-tag --notes-from-tag
# The release is a GitHub object. The Git data it points at is what you see here:
$ git for-each-ref --format="%(refname) %(objecttype) -> %(*objecttype) %(*objectname:short)" refs/tags
refs/tags/v0.1.0 tag -> commit 9a383e5
```
<!-- /snippet -->

**Part B, described from the documentation (not captured).** `--verify-tag` makes the command "abort the release if the tag doesn't already exist", and `--notes-from-tag` takes "the release notes from the annotated git tag" (`gh release create --help`, 2.88.1). The release is a GitHub object that points at the tag; the tag stays Git data ([about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)). `git ls-remote --tags origin` should show the same two lines as in Part A, with your IDs. Creating the release must not change them.

### What happened internally

`git tag -a` wrote a tag object: it names the commit, the tagger, a date and a message. `refs/tags/v0.1.0` points at that object, not at the commit. `git push origin v0.1.0` sent the object and created the ref on the server. `git describe` found the tag because it considers annotated tags by default.

The release added nothing to Git. Its title, notes, assets and flags live in GitHub's database, keyed by the tag name.

### Checkpoint

<!-- snippet: ch17/lab-22-2-annotated-tag-release/04-checkpoint -->
```text
$ git rev-parse v0.1.0 "v0.1.0^{commit}" main
4f7a52d76df009522b0be5a3071462f507b67529
9a383e547a1c8840f3c5c7b23bfab6120f366ed0
9a383e547a1c8840f3c5c7b23bfab6120f366ed0
```
<!-- /snippet -->

Three IDs: the tag object, then the commit twice. If the first two are equal, your tag is lightweight and you skipped `-a`.

### Failure scenario

`main` moves on by one commit. Then somebody creates the next release on the platform for a tag that does not exist. The help text of `gh release create` states what happens: "If a matching git tag does not yet exist, one will automatically get created from the latest state of the default branch." In Part A you imitate that on the bare server with a plain tag:

```bash
# Asha moves main by one commit (the replay does this step without showing it)
git -C ../../asha/ticket-router pull -q --ff-only
printf 'model: router-small-v1\nconfidence_threshold: 0.7\nfallback_queue: general\n' > ../../asha/ticket-router/config/routing.yaml
git -C ../../asha/ticket-router commit -q -am "Raise the confidence threshold to 0.7"
git -C ../../asha/ticket-router push -q origin main

# The platform creates the tag for a release: a plain tag on the tip of the default branch
git -C ../../server/ticket-router.git tag v0.2.0 main
git pull -q --ff-only
git fetch --tags origin
git for-each-ref --format="%(refname:short) %(objecttype)" refs/tags
git describe
git describe --tags
git cat-file -p v0.2.0 | grep -c "^tagger"
```

<!-- snippet: ch17/lab-22-2-annotated-tag-release/05-failure -->
```text
# main has moved on by one commit (Asha). Someone creates release v0.2.0 on the platform for a
# tag that does not exist. Documented result: the tag is created from the default branch.
# The same thing in plain Git, on the server:
$ git -C ../../server/ticket-router.git tag v0.2.0 main
$ git pull -q --ff-only
$ git fetch --tags origin
$ git for-each-ref --format="%(refname:short) %(objecttype)" refs/tags
v0.1.0 tag
v0.2.0 commit
$ git describe
v0.1.0-1-gbab2607
$ git describe --tags
v0.2.0
$ git cat-file -p v0.2.0 | grep -c "^tagger"
0
[exit status: 1]
```
<!-- /snippet -->

`v0.2.0` is a ref that points straight at a commit. It has no tagger, no date and no message, and `git describe` ignores it: the build that derives its version from `git describe` still says `v0.1.0-1-g...`.

In Part B the same mistake is one command:

```bash
gh release create v0.2.0 --title "ticket-router 0.2.0" --notes "Created without a tag, on purpose."
git fetch --tags origin
git cat-file -t v0.2.0
git describe
```

> **Unverified.** The help text says a tag is created; it does not say of which type. This lab expects `git cat-file -t v0.2.0` to print `commit`, a lightweight tag, as in the local imitation. Record what you see.

### Recovery

Remove the platform-made tag, create the tag deliberately, publish it, and only then create the release.

```bash
git push origin --delete v0.2.0
git tag -d v0.2.0
git tag -a v0.2.0 -m "ticket-router 0.2.0: stricter threshold"
git push origin v0.2.0
```

<!-- snippet: ch17/lab-22-2-annotated-tag-release/06-recovery -->
```text
# On GitHub: gh release delete v0.2.0 --cleanup-tag, then recreate from an annotated tag.
$ git push origin --delete v0.2.0
To ../../server/ticket-router.git
 - [deleted]         v0.2.0
$ git tag -d v0.2.0
Deleted tag 'v0.2.0' (was bab2607)
$ git tag -a v0.2.0 -m "ticket-router 0.2.0: stricter threshold"
$ git push origin v0.2.0
To ../../server/ticket-router.git
 * [new tag]         v0.2.0 -> v0.2.0
```
<!-- /snippet -->

In Part B the release must go first, together with its tag, and then the same three Git commands and a verified release:

```bash
gh release delete v0.2.0 --cleanup-tag --yes
git tag -d v0.2.0
git tag -a v0.2.0 -m "ticket-router 0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --verify-tag --notes-from-tag --title "ticket-router 0.2.0"
```

`--cleanup-tag` deletes "the specified tag in addition to its release" (`gh release delete --help`). If the repository uses immutable releases, a published release locks its tag and this repair is not possible (Chapter 15); that is the point of immutability, and one more reason to tag first.

### Verification

```bash
git for-each-ref --format="%(refname:short) %(objecttype) %(taggername) %(subject)" refs/tags
git describe
git ls-remote --tags origin
```

<!-- snippet: ch17/lab-22-2-annotated-tag-release/07-verification -->
```text
$ git for-each-ref --format="%(refname:short) %(objecttype) %(taggername) %(subject)" refs/tags
v0.1.0 tag Lab User ticket-router 0.1.0: keyword classifier
v0.2.0 tag Lab User ticket-router 0.2.0: stricter threshold
$ git describe
v0.2.0
$ git ls-remote --tags origin
4f7a52d76df009522b0be5a3071462f507b67529	refs/tags/v0.1.0
9a383e547a1c8840f3c5c7b23bfab6120f366ed0	refs/tags/v0.1.0^{}
242c2d46b27a81b854acc725d90ac148b622e95e	refs/tags/v0.2.0
bab2607a8de7faa3113ebfdbeb53aaaabd586822	refs/tags/v0.2.0^{}
```
<!-- /snippet -->

Both tags are tag objects with a tagger, `git describe` reports `v0.2.0`, and the server stores four lines for two tags.

### Questions

1. What is the difference between the two lines that `git ls-remote --tags` prints for an annotated tag?
2. Why did `git describe` print `v0.1.0-1-g...` while a tag `v0.2.0` existed on the same commit?
3. Which part of a GitHub Release is Git data, and which is not? What would a fresh clone contain?
4. What does `--verify-tag` protect you from?
5. In the recovery you deleted a published tag and created it again. Chapter 14B, section 14B.11 explains why moving a published tag is dangerous. What makes this case acceptable, and what on GitHub can forbid it?
6. Part B: of which type was the tag that GitHub created? How did you find out?

# V145: What actions/checkout does by default: one commit, no tags, and the merge ref

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 24
- **Prerequisites.** V082, V109, V123, V144
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.8
- **Demo scripts.** `labs/ch20a/shallow-checkout.sh`, `labs/ch20a/merge-ref.sh`, `labs/ch20a/lab-26-3-describe.sh`

## HOOK

**[ON SCREEN]** Questions 1 and 2 of section 20A.1.

"The tests passed on your laptop and failed in CI on the same commit. Was it the same commit?"

"The build stamped the release as `6fe5455` and not as a version. Who removed the tags?"

Two questions, one cause. The answer to the first is no: it was not the same commit, and the commit CI tested does not exist in your clone. The answer to the second is nobody: the tags were never fetched.

Both follow from the defaults of one action that is the first step of almost every job. In this video you rebuild what that action leaves on the runner, with plain Git, on your own machine.

## INTRODUCTION

In V142 you heard that Git appears in exactly one place in GitHub Actions: when a job fetches commits onto the runner. This is the video about that place.

**[ON SCREEN]** Lower third: GitHub Actions, then Git.

The layers are worth separating. Which ref and which options the checkout action uses is GitHub Actions, taken from the action's README and its definition at version 7.0.1, the version pinned in this course. What a repository with one commit and no tags then answers to `git describe` or `git log` is Git, and it behaves the same on a runner and on your Mac.

So the demonstration can be local. A bare repository stands in for GitHub. One honest limit, which the textbook states: the runner's own sequence of Git commands is an implementation detail and is not what is shown. What is shown is the documented result, reproduced.

There are two halves. One commit and no tags: the shallow clone and what it does to history questions. Then the merge ref: which commit a pull request run checks out.

## LEARNING OBJECTIVES

After this video you can:

- say what the runner's repository contains after a default checkout;
- name three commands or tools that give wrong results there and the minimal fix for each;
- explain which commit a `pull_request` run checks out and why it is not in your clone;
- reproduce the runner's checkout locally with a shallow fetch;
- decide when full history is worth its cost.

## CONCEPT

**In one sentence.** A runner starts with no repository at all; `actions/checkout` fetches one commit, without tags, for the ref of the event, and on `pull_request` events that ref is the test merge commit `refs/pull/N/merge`, checked out with a detached HEAD.

**Precisely.** The inputs and their defaults.

**[ON SCREEN]** The table of section 20A.8.

`ref`: the ref or commit of the event. On `pull_request`, that is `refs/pull/N/merge`.

`fetch-depth`: 1. The README: "Only a single commit is fetched by default". Zero fetches all history for all branches and tags.

`fetch-tags`: false. No tags, so nothing for `git describe` to find.

`persist-credentials`: true. The job token is kept for later `git` commands of the job and removed in post-job cleanup. Since version 6 it is stored under the runner's temporary directory and not in `.git/config`. The course workflows set it to false, because none of them runs an authenticated `git` command after the checkout, and a credential that is not on disk cannot be read by a later step.

`lfs` and `submodules`: false. LFS pointers are not replaced by content; submodule directories are empty.

`clean`: true, which matters on self-hosted runners that reuse a workspace.

And `allow-unsafe-pr-checkout`: false. Version 7 refuses to check out fork pull request code under `pull_request_target` and `workflow_run`. Part 7 explains why.

**Inside `.git`.** A shallow fetch writes the fetched commit's ID to the file `.git/shallow`. That file tells Git to treat the commit as having no parents, although the commit object itself still names them. No tag refs are created. HEAD is a branch for `push` events and a bare commit ID for pull requests.

Think about what "no parents" does. Every command that walks history starts at HEAD, reaches the cut, and stops. `git describe` walks parents looking for a tagged commit. `git log` for a path looks for the commit that changed the file. `git merge-base` looks for a common ancestor. None of them can see past the cut.

**Why it does this.** The textbook gives the reason and it is a fair one: a job that only compiles and tests needs the snapshot, not the history. Fetching one commit is the fastest correct default for that job. The default is right for most jobs and wrong for the ones that ask history a question.

**The merge ref.** You know from Chapter 17 that GitHub keeps, for a mergeable pull request, a test merge commit under `refs/pull/N/merge`. The events reference states that `pull_request` workflows set `GITHUB_REF` to that ref and `GITHUB_SHA` to that commit, and that the checkout action therefore, in the documentation's words, "checks out the merge branch", so that "CI tests run against the merged result, not just the head branch alone".

Why? The textbook: the question a pull request asks is "is the result of merging safe", which only the merged tree can answer.

Three consequences, all from the same pages.

The test merge can be older than `main`. It is regenerated when the pull request branch is pushed, when the merge base changes, or when it is older than 12 hours. And a re-run of a job reuses the original commit, so a re-run does not pick up a newer base.

A conflicted pull request has no merge ref, and its `pull_request` workflows do not run at all. The symptom is missing checks, not failed ones.

And to test the head commit alone, the README documents setting `ref` to the head commit of the pull request from the event payload. You then test something that will never be on the base branch. Do it knowingly, for example for a linter that should judge only the author's files.

**When full history is worth its cost.** The rule from the root-cause box: decide per job whether it asks history a question. A job that runs unit tests does not. A job that computes a version from tags, generates a changelog, detects changed files, or runs blame-based analysis does. For those, `fetch-depth: 0`, as workflow 3 has it.

## MENTAL MODEL

**Analogy,** from the textbook. You asked a courier for "the contract" and received the last page, unstapled, with a cover sheet that merges your draft and the other party's latest draft. It is the right thing to sign and the wrong thing to consult about the history of clause 4.

The last page is the single commit. The cover sheet that merges two drafts is the test merge.

The analogy breaks in one place: the last page here is a complete snapshot of every file. Only the history is missing, not the content. That is why compiling and testing work perfectly, and why the failures are so specific.

There is a distinction in the interview question for this video that you should carry through the demonstration: does a tool fail, or does it lie? A tool that fails gives you an error and a red job. A tool that lies gives you a confident wrong answer and a green job. You will see one of each in the next five minutes, and one that fails or lies depending on a single flag.

## DIAGRAM

**[DIAGRAM]** The picture of section 20A.8, with the IDs of the transcript. Draw `main` first, then your branch from the older commit, then ask where CI's commit is, and only then draw the merge commit below `main`.

```text
   6fe5455 --------------- 29b222b            main          (threshold 10)
        \                         \
         \                         d04ef31    refs/pull/7/merge   <-- runner HEAD (detached)
          \                       /
           80c9cfa --------------             feature/reorder-report, refs/pull/7/head
                                              <-- your HEAD
```

**[DIAGRAM]** Three commits matter. `80c9cfa` is yours. `29b222b` is the new tip of `main`. `d04ef31` exists only on the server: neither you nor your colleague created it.

**[ON SCREEN]** The first root-cause box of section 20A.8, one line at a time. Observed behavior: the build names the release `6fe5455` instead of `v0.1.0-1-g6fe5455`. Git state: `.git/shallow` lists HEAD; one commit; no refs under `refs/tags`. Mechanism: `git describe` walks parents looking for a tagged commit; the graft ends the walk. Root cause: the `actions/checkout` defaults, fetch-depth 1 and fetch-tags false. Why it does this: a job that only compiles and tests needs the snapshot, not the history; fetching one commit is the fastest correct default for that job. Correct fix: `fetch-depth: 0` in the job that needs history or tags. Prevention: decide per job whether it asks history a question; never use `--always` to silence describe in a release build.

**[ON SCREEN]** The second root-cause box. Observed behavior: tests pass locally, fail in CI "on the same commit". Git state: laptop HEAD is `80c9cfa`, the pull request head; runner HEAD is `d04ef31`, the test merge. Mechanism: `pull_request` sets `GITHUB_REF` to `refs/pull/N/merge`; checkout uses `GITHUB_REF`. Root cause: the base branch gained a commit that changes behavior the new code relies on. Why it does this: the question a pull request asks is "is the result of merging safe", which only the merged tree can answer. Correct fix: update the branch, by merge or rebase onto the base, fix the code, push. Prevention: reproduce with a fetch and a merge of `origin/main` before debugging; a merge queue or "require branches to be up to date" closes the remaining gap.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20a/shallow-checkout`. The IDs equal the book's.

**Step 1: your clone.**

```bash
git log --oneline --decorate
git describe --tags
```

<!-- snippet: ch20a/shallow-checkout/01-full-clone -->
```text
# Your clone: three commits, one annotated tag.
$ cd you/inventory-api
$ git log --oneline --decorate
6fe5455 (HEAD -> main, origin/main) Document how to run the tests
ae299cb (tag: v0.1.0) Add Maven module for price calculation
05d3477 Add stock functions and tests
$ git describe --tags
v0.1.0-1-g6fe5455
$ cd ../..
```
<!-- /snippet -->

Three commits and one annotated tag, `v0.1.0`, on the middle commit. `git describe` prints the tag, one commit after it, and the abbreviated ID.

**Step 2: the runner's clone.**

```bash
git clone --depth 1 --no-tags "$HUB" runner
git log --oneline --decorate
git rev-parse --is-shallow-repository
cat .git/shallow
git tag --list
git rev-list --count HEAD
```

`git clone` is 🟢 SAFE: it creates a new directory. `HUB` is a `file://` URL of the bare repository that plays GitHub. The URL form matters: a plain path would make Git copy the repository and ignore `--depth`. **[PAUSE]** Predict the five outputs: the log, shallow or not, the content of `.git/shallow`, the tags, the commit count.

<!-- snippet: ch20a/shallow-checkout/02-runner-clone -->
```text
# HUB is a file:// URL of the bare repository that plays GitHub.
# fetch-depth: 1 and fetch-tags: false, as a clone:
$ git clone --depth 1 --no-tags "$HUB" runner
Cloning into 'runner'...
$ cd runner
$ git log --oneline --decorate
6fe5455 (grafted, HEAD -> main, origin/main, origin/HEAD) Document how to run the tests
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
6fe5455926c26261fe2c73104018ca2d96fdb554
$ git tag --list
$ git rev-list --count HEAD
1
```
<!-- /snippet -->

One line of log, with the word "grafted" in the decoration. Shallow: true. The file holds the full ID of that one commit. The tag list is empty. The count is 1. "Grafted" and the ID in `.git/shallow` say the same thing: history is cut here.

**Step 3: asking history questions.**

```bash
git describe --tags
git describe --tags --always
git log --oneline -- java-service/pom.xml
```

**[PAUSE]** For each of the three: does it fail, or does it lie?

<!-- snippet: ch20a/shallow-checkout/03-describe-fails -->
```text
$ git describe --tags
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --tags --always
6fe5455
[exit status: 0]
# History questions get wrong answers, not errors:
$ git log --oneline -- java-service/pom.xml
6fe5455 Document how to run the tests
$ git merge-base HEAD origin/main~1
fatal: Not a valid object name origin/main~1
[exit status: 128]
```
<!-- /snippet -->

`git describe --tags` fails: "No names found", status 128. A red job. Annoying, and honest.

With `--always` it does not fail. It prints `6fe5455`, status 0, and a build stamps that as the version. That is the CTO's second question. One flag turned a failure into a lie.

The `git log` line is the worst of the three. It claims that `pom.xml` was last changed by the only commit there is, because a parentless commit "adds" every file. The true answer, which you will see in a moment, is another commit. Any tool that asks history a question gets a confident wrong answer: changed-file detection, blame-based analysis, changelog generators, version-from-tag plugins.

And `git merge-base` fails, because the name it was given cannot be resolved here.

**Step 4: tags alone are not enough.**

```bash
git fetch --depth 1 origin "refs/tags/*:refs/tags/*"
git tag --list
git describe --tags
```

`git fetch` is 🟢 SAFE. This is what `fetch-tags: true` with depth 1 amounts to. **[PAUSE]** The tag will now exist. Does `git describe` work?

<!-- snippet: ch20a/shallow-checkout/04-tags-are-not-enough -->
```text
# fetch-tags: true with depth 1: the tag arrives, its commit is not an ancestor we have.
$ git fetch --depth 1 origin "refs/tags/*:refs/tags/*"
From file://$LAB/ch20a/shallow-checkout/hub/inventory-api
 * [new tag]         v0.1.0     -> v0.1.0
$ git tag --list
v0.1.0
$ git describe --tags
fatal: No tags can describe '6fe5455926c26261fe2c73104018ca2d96fdb554'.
Try --always, or create some tags.
[exit status: 128]
```
<!-- /snippet -->

The tag arrived. `describe` still fails, with a different message: "No tags can describe". The walk from HEAD through parents ends at the graft before it reaches the tagged commit. Tags need the history between them and HEAD.

**Step 5: full history.**

```bash
git fetch --unshallow --tags
```

🟢 SAFE: it adds objects and tag refs and removes `.git/shallow`. This is `fetch-depth: 0` as a repair of an existing clone.

<!-- snippet: ch20a/shallow-checkout/05-full-history -->
```text
# fetch-depth: 0, as a repair of this clone:
$ git fetch --unshallow --tags
$ git rev-parse --is-shallow-repository
false
$ git rev-list --count HEAD
3
$ git describe --tags
v0.1.0-1-g6fe5455
$ git log --oneline -- java-service/pom.xml
ae299cb Add Maven module for price calculation
```
<!-- /snippet -->

Not shallow, three commits, the right description. And the true answer for `pom.xml`: `ae299cb`, "Add Maven module for price calculation".

**Step 6: the lab replay, briefly.** `labs/run ch20a/lab-26-3-describe`.

<!-- snippet: ch20a/lab-26-3-describe/01-predict -->
```text
$ git tag --list -n1
v0.1.0          inventory-api 0.1.0
$ git describe --tags --always
v0.1.0-1-g6fe5455
# A clone like the default checkout (one commit, no tags):
$ git clone --quiet --depth 1 --no-tags "file://$PWD" ../default-checkout
$ git -C ../default-checkout describe --tags --always
6fe5455
# A clone like fetch-depth: 0 (all history, all tags):
$ git clone --quiet "file://$PWD" ../full-checkout
$ git -C ../full-checkout describe --tags --always
v0.1.0-1-g6fe5455
```
<!-- /snippet -->

The same commit described three times: in your repository, in a clone like the default checkout, and in a clone like `fetch-depth: 0`. The middle answer is the bare ID.

**Step 7: the merge ref.** Replay `labs/run ch20a/merge-ref`. The fixture: your branch adds a reorder report whose test assumes the low-stock threshold is 5. A colleague raised the threshold to 10 on `main`. The two changes touch different files, so they merge without a conflict.

<!-- snippet: ch20a/merge-ref/01-your-branch -->
```text
# Your clone, on the pull request branch. The tests pass.
$ cd you/inventory-api
$ git switch feature/reorder-report
Switched to branch 'feature/reorder-report'
Your branch is up to date with 'origin/feature/reorder-report'.
$ git log --oneline -2
80c9cfa Add reorder report
6fe5455 Document how to run the tests
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ cd ../..
```
<!-- /snippet -->

On your branch, at `80c9cfa`, the tests pass.

```bash
git ls-remote "$HUB"
```

The server is a bare repository in which the fixture created the two pull request refs with plain Git, imitating the documented behavior.

<!-- snippet: ch20a/merge-ref/02-server-refs -->
```text
# The repository on the platform after pull request 7 was opened:
$ git ls-remote "$HUB"
29b222ba49c3886f27c205a7ec4c982d141052c3	HEAD
80c9cfa3a369de2fb126f79a0e34f6139c858a76	refs/heads/feature/reorder-report
29b222ba49c3886f27c205a7ec4c982d141052c3	refs/heads/main
80c9cfa3a369de2fb126f79a0e34f6139c858a76	refs/pull/7/head
d04ef31e3ed5a74c9a89af11e2cbb441599e84c7	refs/pull/7/merge
192d2bc34d491d9b35cc1c00e50dde959dd9df55	refs/tags/v0.1.0
ae299cbfba5ad3d9388d3dded0eeee37b09946aa	refs/tags/v0.1.0^{}
```
<!-- /snippet -->

`refs/pull/7/head` is your commit. `refs/pull/7/merge` is `d04ef31`. Compare it with every other line: no branch points at it.

```bash
git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
git checkout --detach refs/remotes/pull/7/merge
```

The runner fetches that one commit and detaches HEAD on it. `git checkout --detach` is the older spelling; the script uses the `git switch --detach` form a few steps later.

<!-- snippet: ch20a/merge-ref/03-runner-checkout -->
```text
# The runner: fetch one commit, the one refs/pull/7/merge names, and detach HEAD on it.
$ git init --quiet runner && cd runner
$ git remote add origin "$HUB"
$ git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
From file://$LAB/ch20a/merge-ref/hub/inventory-api
 * [new ref]         refs/pull/7/merge -> pull/7/merge
$ git checkout --detach refs/remotes/pull/7/merge
HEAD is now at d04ef31 Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
```
<!-- /snippet -->

Read the subject of the commit: "Merge", your commit's full ID, "into", the ID of `main`'s tip.

**[PAUSE]** On the runner now: what does `git status` say about the branch, who is the author of HEAD, how many commits are there, and what is the threshold in `stock.py`?

<!-- snippet: ch20a/merge-ref/04-what-is-checked-out -->
```text
$ git status --short --branch
## HEAD (no branch)
$ git log -1 --format="GITHUB_SHA would be %H%n%an: %s"
GITHUB_SHA would be d04ef31e3ed5a74c9a89af11e2cbb441599e84c7
GitHub: Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
$ git rev-list --count HEAD
1
$ git branch --show-current
$ grep LOW_STOCK_THRESHOLD src/inventory_api/stock.py
LOW_STOCK_THRESHOLD = 10
def low_stock(stock, threshold=LOW_STOCK_THRESHOLD):
$ ls src/inventory_api
__init__.py
report.py
stock.py
```
<!-- /snippet -->

"HEAD (no branch)". The author is GitHub. One commit. No current branch. The threshold is 10, from `main`, and `report.py`, from your branch, is there too. The working tree contains both changes.

<!-- snippet: ch20a/merge-ref/05-tests-on-the-merge -->
```text
# The merged code is what CI tests. main changed the threshold; the new test assumed 5.
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 1]
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
```
<!-- /snippet -->

The tests fail on the runner and pass on your laptop. Both results are correct. They tested different commits.

```bash
merge=$(git ls-remote "$HUB" refs/pull/7/merge | cut -f1)
git cat-file -t $merge
git fetch --quiet origin
git switch --quiet --detach feature/reorder-report
git merge --quiet --no-edit origin/main
git rev-parse HEAD^{tree}
```

Back in your clone. **[PAUSE]** You copy the commit ID from the CI log and ask your clone about it. What happens?

<!-- snippet: ch20a/merge-ref/06-not-in-your-clone -->
```text
# Back in your clone: the commit CI tested is not there, and your branch is unchanged.
$ cd ../you/inventory-api
$ merge=$(git ls-remote "$HUB" refs/pull/7/merge | cut -f1)
$ git cat-file -t $merge
fatal: git cat-file: could not get object info
[exit status: 128]
# Reproduce what CI tested: merge the current base into a throwaway copy of your branch.
$ git fetch --quiet origin
$ git switch --quiet --detach feature/reorder-report
$ git merge --quiet --no-edit origin/main
$ git rev-parse HEAD^{tree}
745aaaaed0f47d2429feeb200e9776b329be83ef
$ git -C ../../runner rev-parse HEAD^{tree}
745aaaaed0f47d2429feeb200e9776b329be83ef
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
$ git switch --quiet feature/reorder-report
```
<!-- /snippet -->

"Could not get object info." The commit is not in your clone. Then the reproduction: fetch, detach on your branch so that the branch itself does not move, and merge `origin/main`. `git merge` is 🟡 CAUTION; on a detached HEAD it moves only HEAD. The tree ID of your local merge equals the tree ID on the runner, `745aaaa`. Same tree, so the same test result: the failure reproduces locally. Then the script switches back to the branch, which is unchanged.

## COMMON MISTAKES

1. **Silencing `git describe` with `--always` in a release build.** Root cause: with one commit and no tags the command would fail, and `--always` turns that failure into a bare commit ID that gets stamped as the version.
2. **Setting `fetch-tags: true` and keeping depth 1.** Root cause: `describe` walks parents from HEAD to a tagged ancestor, and the graft ends the walk before it gets there.
3. **Debugging a CI failure on your branch tip.** Root cause: a `pull_request` run checks out the test merge under `refs/pull/N/merge`, a commit that is not in your clone.
4. **Re-running a job to "pick up the new main".** Root cause: a re-run reuses the original commit.
5. **Reading missing checks on a conflicted pull request as a broken workflow.** Root cause: a conflicted pull request has no merge ref, so its `pull_request` workflows do not run at all.

## PRODUCTION EXAMPLE

The textbook's case. An ML team's pull request adds a metric and passes locally. CI fails in an unrelated data-loader test. The author spends an hour on the loader before looking at the first lines of the checkout step's log, where the fetched ref is `refs/pull/412/merge`. Someone had merged a loader change twenty minutes earlier.

The habit that prevents the lost hour: read which commit the job checked out before reading anything else. Workflow 1 prints it in its own step for that reason.

## PRACTICE EXERCISE

Do Lab 26.3, "Workflow 3, build the application", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell.

The lab asks for two predictions, and you should write both down. When the tag is pushed: which workflows start, and what will the build job print after "Building"? And after one more commit lands on `main`: what will the description be then?

The challenge is Exercise 28.5, "Green here, red in a fresh clone", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q283: "What does `actions/checkout` put on the runner by default? Name three tools or commands that give wrong results there, and say whether each fails or lies."

A strong answer describes the repository on the runner as Git state: how many commits, which refs, what HEAD is, and which file marks the cut. Then it picks three history questions and classifies each as an error or a wrong answer, with the mechanism. It says which is more dangerous and why. The follow-up is about `fetch-tags: true` with the depth left at one; you have seen the answer, so explain it from how `describe` finds a tag.

## RECAP

You should now be able to say:

- After a default checkout the runner has one commit, no tags, and a `.git/shallow` file that cuts history at HEAD.
- History questions there either fail or give a confident wrong answer; `fetch-depth: 0` in the job that needs history is the fix.
- A `pull_request` run checks out the test merge under `refs/pull/N/merge` with a detached HEAD: a commit that is on the server and not in your clone.
- To reproduce what CI tested, fetch and merge the base into a detached copy of your branch, and compare tree IDs.
- A re-run reuses the original commit, and a conflicted pull request gets no run at all.

## HOMEWORK

Read section 20A.8 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md).

# V113: Partial clone plus sparse-checkout, what scalar clone configures, and ownership, CI and releases in a monorepo

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 24
- **Prerequisites.** V080, V112
- **Textbook sections.** [Chapter 24](../../textbook/ch24-monorepos.md), sections 24.7 to 24.14
- **Demo scripts.** `labs/ch24/sparse-partial.sh`, `labs/ch24/affected-projects.sh`, `labs/ch24/project-tags.sh`, `labs/ch24/lab-18-4-scalar-by-hand.sh`

## HOOK

**[ON SCREEN]** "0 projects affected. Skipping tests." — on a pull request that changed the ranker.

A monorepo's CI computes which projects a pull request affects and runs only their tests. One day a pull request that changes the ranker reports zero affected projects, skips every test, and merges. `main` is broken an hour later.

The script that computes the list had not changed. The clone had. Someone made the CI clone shallow to save time. The "what changed" step now fails with "no merge base", and the script swallowed the error and concluded that nothing changed.

Your CTO asks: what was wrong, and what is the smallest clone that gives the right answer? You will be able to say exactly which objects that question needs.

## INTRODUCTION

This video closes the monorepo topic and the scale topic by putting the pieces together.

First, the combination: a blobless partial clone with a cone-mode sparse checkout, and what the command `scalar clone` sets up around that combination. Then three things a monorepo needs beyond a small working tree: ownership by path, CI that computes affected projects, and releases of several projects from one repository.

Replays from `labs/ch24`: `sparse-partial.sh`, `affected-projects.sh`, `project-tags.sh`, and the replay of Lab 18.4 up to its checkpoint.

There is no `scalar clone` on screen. The lab rules forbid demos that install schedulers or start daemons, and `scalar clone` does both. It is labelled 🟡 CAUTION in the chapter's table: it also writes global configuration, installs a scheduler unless `--no-maintenance`, and starts a monitor daemon. The lab builds the same clone by hand and registers nothing. The commands we do run, `git clone --filter=blob:none --sparse`, `git backfill` and `git maintenance run --task=prefetch`, are 🟢 SAFE: they add objects and refs under `refs/prefetch/`.

## LEARNING OBJECTIVES

After this video you can:

- Combine a blobless clone with a cone and say what is fetched when.
- List what `scalar clone` sets up and which parts live outside the repository.
- Compute affected projects correctly and explain why the naive form fails in shallow and partial CI clones.
- Tag and describe releases of several projects in one repository.
- Say how CODEOWNERS is used at this scale, as a pointer to Part 5.

## CONCEPT

In one sentence: a blobless partial clone leaves file contents on the server until something needs them, a sparse checkout limits that "something" to your cone, and `scalar clone` sets up both together with settings and scheduled maintenance.

Why combine them? A sparse checkout alone still downloaded every version of every file. `git clone --filter=blob:none` asks the server for commits and trees without blobs, and Git fetches a blob when a command first needs it. With `--sparse`, the checkout needs only the blobs of the cone.

These are two independent mechanisms in two files. The promise of the remote belongs to the repository and is in `.git/config`. The cone belongs to the working tree and is in `.git/config.worktree`.

What `scalar clone` does. `scalar` ships with Git since 2.38 and is not labelled experimental. Its manual describes `scalar clone <url> <enlistment>` in four parts.

**[ON SCREEN]** Four parts of `scalar clone`.

One: a partial clone. "By default, only commit and tree objects are cloned", with the working tree in `<enlistment>/src`. Two: a cone-mode sparse checkout with only the top-level files, unless `--full-clone`. Three: configuration "to optimize for large repositories", each value with its reason in the manual; among others `commitGraph.changedPaths=true`, `core.untrackedCache=true`, `index.version=4`, `fetch.unpackLimit=1`, `gc.auto=0`, `status.aheadBehind=false`, `fetch.showForcedUpdates=false`, `pack.useBitmaps=false`, and `log.excludeDecoration=refs/prefetch/*`. You have met the reason for almost every one of those in the last five videos. Four: background maintenance, the scheduler of `git maintenance start`, unless `--no-maintenance`.

Which parts live outside the repository? The textbook ran a contained test on Git 2.55.0 on macOS, in a sandbox with its own `HOME` and the scheduler replaced by a logging stub. It found: with `--no-maintenance` the scheduler was not called; the enlistment was registered in the global configuration as `scalar.repo`; and the repository received `core.fsmonitor=true` while `scalar` ran `git fsmonitor--daemon start`, which left a daemon running. `--no-maintenance` does not prevent that, and the 2.55 manual page does not list the setting. The source does.

So `scalar clone` leaves three things behind: a registration in your global configuration, scheduler entries, on macOS under `~/Library/LaunchAgents`, and one monitor process per enlistment. `scalar unregister` undoes the first two for a repository, `scalar delete <enlistment>` also removes the directory, and `git fsmonitor--daemon stop` inside the working tree stops the daemon.

Ownership. This is GitHub, not Git: Git stores `.github/CODEOWNERS` as an ordinary file and gives it no meaning. In a monorepo, ownership is a function of the path, and on GitHub that function is the `CODEOWNERS` file. Part 5 teaches it. Four documented facts decide whether it works at this scale. The last matching pattern wins. The file is read from the pull request's base branch. The file only requests reviews; requiring them is a ruleset or branch protection setting. And a line with invalid syntax is skipped, and the pull request does not fail because of it.

CI. A monorepo's CI must first answer: which projects does this change affect? Building everything is correct and unaffordable; building too little lets a broken `main` through. Git's part of the answer is a diff against the merge base: three dots. Three dots mean "from the merge base to the second commit": what the branch did since it forked. Two dots compare the tips and charge the branch with what `main` did meanwhile. A build system then extends the list by dependency, which Git cannot know.

Releases. In one sentence: tags name commits of the whole repository, so a monorepo that releases projects separately puts the project into the tag name and into every question about "the last release". There is one `refs/tags/` namespace per repository. The usual convention is a prefix per project; the slash is only a character to Git, and patterns can match it.

When not to use a monorepo at all, from section 24.13: when projects have different readers, because Git cannot restrict reading to part of a repository; when lifecycles are unrelated; when the content is large binaries, because sparse checkout and partial clone postpone a download and do not shrink it; and when there is no one to own the tooling.

## MENTAL MODEL

Recall the library with closed stacks from two videos ago: the catalogue lists every book and your desk holds the shelves you asked for. The analogy broke because in a normal clone the stacks are in your building. A partial clone moves the stacks out. Now the catalogue, which is commits and trees, is complete and local; the books, which are blobs, arrive when you ask; and the desk, the cone, limits what you ask for by default.

Where this combined model breaks: questions about history need the catalogue, not the books. A blobless clone answers them. A shallow clone has thrown away most of the catalogue. That is the whole difference in the hook.

## DIAGRAM

**[DIAGRAM]** The monorepo tree, a change in one project, and the jobs that must run.

```text
   d259a34 ---------------- 100bb99   main        (changed libs/schemas, services/gateway, services/ingest)
        \
         9c9fd21 --- 88222b7   feature/rerank-cache   (changed services/ranker)

   orbit/
     services/gateway     main touched it          three dots: not affected     two dots: "affected"
     services/ingest      main touched it          three dots: not affected     two dots: "affected"
     services/ranker      the branch touched it    three dots: AFFECTED         two dots: affected
     libs/schemas         main touched it          three dots: not affected     two dots: "affected"

   git diff --name-only main...feature/rerank-cache    = from merge base d259a34 to the branch tip
   git diff --name-only main..feature/rerank-cache     = tip against tip
```

The merge base is `d259a34`. From there, `main` went on to `100bb99`, which changed the schemas, the gateway and the ingest worker. The branch made two commits that changed the ranker.

With three dots, one project is affected: the ranker. With two dots, four are, and three of those are `main`'s work charged to the branch.

Now cover the commit `d259a34` with your hand. That is a shallow CI clone: two tips with no connection. Three dots has no merge base to start from.

**[ON SCREEN]** The root-cause box of section 24.9.

```text
Observed behavior : the "what changed" step fails with "no merge base", or a script that swallows the
                    error concludes that nothing changed and skips every test.
Git state         : a shallow repository; "git log --all" shows two commits with no connection.
Mechanism         : each fetch with --depth 1 delivered one commit and recorded it as a boundary.
Root cause        : a history question asked of a clone that was told to have no history.
Why Git does this : a shallow clone is "these commits and nothing behind them" (Chapter 26, 26.11).
Correct fix       : a full-depth fetch, or a blobless clone: every commit and tree, no file content
                    that is not checked out.
Prevention        : jobs that build one snapshot may be shallow; jobs that compare, describe or
                    compute versions may not.
```

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch24/sparse-partial
```

The layout that `scalar clone` creates, an enlistment directory with the working tree in `src`, built by hand.

```bash
git clone --filter=blob:none --sparse "file://$PWD/server/orbit.git" orbit-dev/src
cd orbit-dev/src
ls -A
git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
```

**[PAUSE]** Blobless and sparse together. How many commits, how many trees, how many blobs?

<!-- snippet: ch24/sparse-partial/01-clone -->
```text
$ git clone --filter=blob:none --sparse "file://$PWD/server/orbit.git" orbit-dev/src
Cloning into 'orbit-dev/src'...
$ cd orbit-dev/src
$ ls -A
.git
.gitignore
pyproject.toml
README.md
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
   3 blob
  96 commit
   5 tag
 284 tree
$ git status | sed -n 4p
You are in a sparse checkout with 10% of tracked files present.
```
<!-- /snippet -->

Three blobs for three files, and all 96 commits and 284 trees.

<!-- snippet: ch24/sparse-partial/02-config -->
```text
# What makes it partial is in .git/config; what makes it sparse is in .git/config.worktree:
$ git config list --local --show-origin | grep -i -e promisor -e partialclone -e worktreeconfig
file:.git/config	remote.origin.promisor=true
file:.git/config	remote.origin.partialclonefilter=blob:none
file:.git/config	extensions.worktreeconfig=true
$ git config list --worktree --show-origin
file:.git/config.worktree	core.sparsecheckout=true
file:.git/config.worktree	core.sparsecheckoutcone=true
```
<!-- /snippet -->

What makes it partial is in `.git/config`; what makes it sparse is in `.git/config.worktree`.

```bash
git sparse-checkout set services/ranker libs/tokenizer
git rev-list --objects --all --missing=print | grep -c '^?'
```

<!-- snippet: ch24/sparse-partial/03-widen -->
```text
# Widening the cone downloads the blobs of those directories, and only those:
$ git sparse-checkout set services/ranker libs/tokenizer
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
   9 blob
  96 commit
   5 tag
 284 tree
$ git rev-list --objects --all --missing=print | grep -c '^?'
113
$ git status | sed -n 4p
You are in a sparse checkout with 28% of tracked files present.
```
<!-- /snippet -->

Widening the cone fetched six more blobs, the current versions of six files. 113 objects that the history refers to are not here, and nothing is wrong.

```bash
git backfill --sparse
git log -p --format=%s -1 -- services/ranker/features.py | sed -n 1,12p
```

<!-- snippet: ch24/sparse-partial/04-history-in-cone -->
```text
# History of the cone, fetched in one batch instead of one request per commit:
$ git backfill --sparse
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
  33 blob
  96 commit
   5 tag
 284 tree
$ git log -p --format=%s -1 -- services/ranker/features.py | sed -n 1,12p
ranker: add ranking signal 12

diff --git a/services/ranker/features.py b/services/ranker/features.py
index 04b3cf5..2e52099 100644
--- a/services/ranker/features.py
+++ b/services/ranker/features.py
@@ -11,4 +11,5 @@ FEATURES = [
     "signal_09",
     "signal_10",
     "signal_11",
+    "signal_12",
 ]
```
<!-- /snippet -->

`git backfill --sparse` is experimental and needs Git 2.49 or later. It downloads the historical versions of the files in the cone in batches, so that `git log -p` and `git blame` there stop fetching blob by blob.

<!-- snippet: ch24/sparse-partial/05-settings -->
```text
# A few of the settings that scalar would write, set by hand (the manual lists them all):
$ git config set commitGraph.changedPaths true
$ git config set status.aheadBehind false
$ git config set fetch.showForcedUpdates false
$ git config set advice.fetchShowForcedUpdates false
$ git config set log.excludeDecoration "refs/prefetch/*"
$ git config set maintenance.auto false
$ git config set maintenance.strategy incremental
```
<!-- /snippet -->

A few of the settings that `scalar` would write, set by hand. The manual lists them all.

```bash
GIT_TRACE="$PWD/../maintenance.log" git maintenance run --task=prefetch --task=commit-graph
git for-each-ref --format='%(refname)' refs/prefetch
git log --oneline --decorate -1
```

<!-- snippet: ch24/sparse-partial/06-maintenance -->
```text
# What the scheduler would run every hour, run once in the foreground:
$ GIT_TRACE="$PWD/../maintenance.log" git maintenance run --task=prefetch --task=commit-graph
$ sed -n 's/.*trace: run_command: git //p' ../maintenance.log | grep -v -e '^maintenance' -e '^pack-objects' -e '^index-pack'
fetch origin --prefetch --prune --no-tags --no-write-fetch-head --recurse-submodules=no --quiet
commit-graph write --split --reachable --no-progress
$ git for-each-ref --format='%(refname)' refs/prefetch
refs/prefetch/remotes/origin/feature/rerank-cache
refs/prefetch/remotes/origin/main
# The prefetched refs do not move your remote-tracking branches and stay out of the log:
$ git log --oneline --decorate -1
100bb99 (HEAD -> main, tag: schemas/v1.1.0, origin/main, origin/HEAD) schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

What the scheduler would run every hour, run once in the foreground. The `prefetch` task fetches into `refs/prefetch/`. Your remote-tracking branches do not move, and when you run `git fetch` yourself the objects are already local.

**[TERMINAL]** Affected projects.

```bash
labs/run ch24/affected-projects
```

```bash
git diff --name-only main...feature/rerank-cache | cut -d/ -f1-2 | sort -u
git diff --name-only main..feature/rerank-cache | cut -d/ -f1-2 | sort -u
```

<!-- snippet: ch24/affected-projects/01-three-dot -->
```text
$ cd orbit
$ git log --oneline --graph -4 main feature/rerank-cache
* 100bb99 schemas, gateway, ingest: add the tenant field in one change
| * 88222b7 ranker: make the cache size configurable
| * 9c9fd21 ranker: cache scores per query and document
|/  
* d259a34 docs: record architecture change 12
# What the branch changed since it forked (three dots: diff from the merge base):
$ git diff --name-only main...feature/rerank-cache
services/ranker/config.yaml
services/ranker/model.py
$ git diff --name-only main...feature/rerank-cache | cut -d/ -f1-2 | sort -u
services/ranker
# Two dots compare the two tips, and blame the branch for what main did meanwhile:
$ git diff --name-only main..feature/rerank-cache | cut -d/ -f1-2 | sort -u
libs/schemas
services/gateway
services/ingest
services/ranker
$ cd ..
```
<!-- /snippet -->

The diagram, measured. One project with three dots, four with two.

```bash
git clone -q --depth 1 --branch feature/rerank-cache "file://$PWD/server/orbit.git" ci-shallow
cd ci-shallow
git fetch -q --depth 1 origin main:refs/remotes/origin/main
git diff --name-only origin/main...HEAD
git merge-base origin/main HEAD
```

**[PAUSE]** One commit per branch. What do the three-dot diff and `git merge-base` print, and with what exit status?

<!-- snippet: ch24/affected-projects/02-shallow-ci -->
```text
# The CI job clones the branch with depth 1 and fetches the tip of main the same way:
$ git clone -q --depth 1 --branch feature/rerank-cache "file://$PWD/server/orbit.git" ci-shallow
$ cd ci-shallow
$ git fetch -q --depth 1 origin main:refs/remotes/origin/main
$ git log --oneline --all
100bb99 schemas, gateway, ingest: add the tenant field in one change
88222b7 ranker: make the cache size configurable
$ git diff --name-only origin/main...HEAD
fatal: origin/main...HEAD: no merge base
[exit status: 128]
$ git merge-base origin/main HEAD
[exit status: 1]
$ cd ..
```
<!-- /snippet -->

"No merge base", status 128. And `git merge-base` prints nothing with status 1. A script that reads only the output sees an empty list.

```bash
git clone -q --filter=blob:none --no-checkout --branch feature/rerank-cache "file://$PWD/server/orbit.git" ci-blobless
cd ci-blobless
git merge-base origin/main HEAD
git diff --name-only origin/main...HEAD | cut -d/ -f1-2 | sort -u
git sparse-checkout set services/ranker libs/tokenizer
git checkout -q
```

<!-- snippet: ch24/affected-projects/03-blobless-ci -->
```text
# A blobless clone without a checkout has every commit and tree and not a single file:
$ git clone -q --filter=blob:none --no-checkout --branch feature/rerank-cache "file://$PWD/server/orbit.git" ci-blobless
$ cd ci-blobless
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
  96 commit
   5 tag
 284 tree
$ git merge-base origin/main HEAD
d259a34f3117e4516fb2f7c071b2dd9c8edc9e5b
$ git diff --name-only origin/main...HEAD | cut -d/ -f1-2 | sort -u
services/ranker
# Then check out only what the job needs:
$ git sparse-checkout set services/ranker libs/tokenizer
$ git checkout -q
$ find . -path ./.git -prune -o -type f -print | sort
./.gitignore
./libs/tokenizer/tokenizer.py
./libs/tokenizer/vocab.txt
./pyproject.toml
./README.md
./services/ranker/config.yaml
./services/ranker/features.py
./services/ranker/model.py
./services/ranker/tests/test_model.py
```
<!-- /snippet -->

Ninety-six commits, 284 trees and no blob are enough for `git merge-base` and for `git diff --name-only`, which compares trees. The job then checks out the affected project and its dependencies: nine files. That is the smallest clone that gives the right answer.

**[ON SCREEN]** "GitHub Actions, not Git."

By default `actions/checkout` fetches one commit and no tags, which is the failing state; its README documents inputs for depth, a partial-clone filter and sparse-checkout. That is described from the documentation and not run here. And one trap that belongs to GitHub: a workflow that a path filter keeps from starting never reports, so a required check on it stays pending. Part 6 returns to it.

**[TERMINAL]** Releases.

```bash
labs/run ch24/project-tags
```

<!-- snippet: ch24/project-tags/01-tags -->
```text
$ git for-each-ref --format='%(refname:short) %(objecttype) -> %(*objectname:short) %(*subject)' refs/tags
gateway/v1.0.0 tag -> 153c828 gateway: add search route 3
gateway/v1.1.0 tag -> f5915c9 gateway: add search route 9
ranker/v0.9.0 tag -> 52ee19b ranker: add ranking signal 6
schemas/v1.0.0 tag -> 6f3c9a4 docs: record architecture change 2
schemas/v1.1.0 tag -> 100bb99 schemas, gateway, ingest: add the tenant field in one change
$ git tag -l 'gateway/*'
gateway/v1.0.0
gateway/v1.1.0
```
<!-- /snippet -->

Five tags with project prefixes. `schemas/v1.0.0` points at a documentation commit: a tag names a state of the entire tree.

```bash
git describe main
git describe --match 'gateway/v*' main
git describe --match 'ranker/v*' main
```

**[PAUSE]** `git describe main` with no pattern, in a build of the gateway. Which project's tag will it print?

<!-- snippet: ch24/project-tags/02-describe -->
```text
# Without a pattern, describe answers with the nearest tag of any project:
$ git describe main
schemas/v1.1.0
# With a pattern it answers for one project:
$ git describe --match 'gateway/v*' main
gateway/v1.1.0-28-g100bb99
$ git describe --match 'ranker/v*' main
ranker/v0.9.0-48-g100bb99
```
<!-- /snippet -->

The schemas tag: the nearest tag of any project. A build that stamps the gateway with it is wrong, and nothing fails. `--match` restricts the candidates.

<!-- snippet: ch24/project-tags/03-changelog -->
```text
# The range between two gateway releases contains everybody else too:
$ git log --oneline gateway/v1.0.0..gateway/v1.1.0 | wc -l
      42
# Limit it to the paths that go into the gateway:
$ git log --oneline gateway/v1.0.0..gateway/v1.1.0 -- services/gateway libs/schemas
f5915c9 gateway: add search route 9
b8f00f5 gateway: add search route 8
6df5fa6 gateway: add search route 7
bc833b0 gateway: add search route 6
f29a33b gateway: add search route 5
aa79006 gateway: add search route 4
# Has anything that the gateway ships changed since its last release?
$ git log --oneline gateway/v1.1.0..main -- services/gateway libs/schemas
100bb99 schemas, gateway, ingest: add the tenant field in one change
cb65af7 gateway: add search route 12
5f20f82 gateway: add search route 11
47dda3a gateway: add search route 10
$ git diff --quiet gateway/v1.1.0 main -- services/gateway libs/schemas
[exit status: 1]
$ git diff --quiet ranker/v0.9.0 gateway/v1.0.0 -- libs/schemas
[exit status: 0]
```
<!-- /snippet -->

Of the 42 commits between two gateway releases, six concern the gateway. A changelog, and the question "does this project need a release", must be limited to the paths the project ships, its libraries included. `git diff --quiet` with paths turns the question into an exit status.

**[TERMINAL]** Lab 18.4, up to the checkpoint.

```bash
labs/run ch24/lab-18-4-scalar-by-hand
```

<!-- snippet: ch24/lab-18-4-scalar-by-hand/05-checkpoint -->
```text
# Checkpoint: the history of the cone without one request per commit.
$ git backfill --sparse
$ GIT_TRACE=1 git log -p --format=%s -- services/ranker/features.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
0
$ GIT_TRACE2_PERF=1 git log --oneline -- services/ranker 2>&1 >/dev/null | sed -n 's/.*statistics://p'
{"filter_not_present":0,"maybe":13,"definitely_not":81,"false_positive":0}
```
<!-- /snippet -->

At the checkpoint, the hand-built clone answers `git log -p` in the cone with zero fetches, and a path-limited log uses the changed-path filters. Then the lab cuts the connection to the server. What still works and what does not is yours to predict.

## COMMON MISTAKES

1. Computing affected projects with two dots. Root cause: two dots compare the tips and charge the branch with what `main` did meanwhile.
2. Running the three-dot diff in a depth-1 clone. Root cause: the merge base is a commit in the past, and each `--depth 1` fetch delivered one commit and recorded it as a boundary.
3. Stamping a build with `git describe` and no pattern. Root cause: there is one tag namespace, and describe answers with the nearest tag of any project.
4. Running `scalar clone` and later finding a daemon and scheduler entries. Root cause: it registers the enlistment globally, installs maintenance and starts a file-system monitor; remove them with `scalar unregister` and `git fsmonitor--daemon stop`.
5. Triggering deploys on any tag. Root cause: tag-triggered automation must filter on the project prefix.

## PRODUCTION EXAMPLE

The search platform team fixes the incident from the hook in three changes. The affected-projects job becomes a blobless clone without a checkout, computes `git diff --name-only origin/main...HEAD`, and then checks out the affected project and its dependencies with a cone. The script stops swallowing the exit status of the diff. And snapshot build jobs stay shallow, under the rule from the root-cause box: jobs that build one snapshot may be shallow; jobs that compare, describe or compute versions may not.

For releases, each project has its own release script that calls `git describe --match '<project>/v*'` and limits its changelog to the project's paths. And they note one platform fact: on GitHub a release is attached to one tag, so the release list mixes all projects.

## PRACTICE EXERCISE

Do Lab 18.4, "The clone that `scalar clone` builds, made by hand", in [`lab-manual/m18-transfer-scale.md`](../../lab-manual/m18-transfer-scale.md). At each step, predict the object counts by type. Before the failure scenario, list which of your next five commands will work without the server and which will fail, and with what message.

The challenge is Exercise 18.9, "The clone that believes it is up to date", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 446 of the CTO question bank:

> "Our CI computes affected projects with `git diff main..HEAD`. What is wrong, and why does the fix fail in a shallow clone?"

A strong answer explains what the two notations compare, with the merge base named. It then says which object the corrected command needs that a shallow clone does not have, and what the failure looks like, including the dangerous silent variant. It finishes with the clone shape that fixes it and why that shape is enough, in terms of commits, trees and blobs.

## RECAP

You should now be able to say:

- Blobless plus cone: all commits and trees are local, and blobs are fetched only for the cone and on demand.
- `scalar clone` is a partial clone, a cone, a set of settings and background maintenance; it also registers the enlistment globally and starts a monitor daemon.
- Affected projects come from a three-dot diff, which needs the merge base; a blobless clone has it, a shallow clone does not.
- Tags are repository-wide; prefix them per project and use `git describe --match`.
- CODEOWNERS is GitHub's path-based ownership; it requests reviews and is read from the base branch.

## HOMEWORK

Read sections 24.7 to 24.14 of [Chapter 24](../../textbook/ch24-monorepos.md) and do the Practice section 24.16.

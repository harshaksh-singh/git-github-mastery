# Chapter 24: Monorepos

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch24/`.

## 24.1 Why this matters

Four questions a CTO can ask in one planning meeting:

1. "Every cross-service change is five pull requests in forty repositories that must merge in order. Should we move to one repository?"
2. "Google and Meta run monorepos. Why does `git status` take seconds in ours?"
3. "A new engineer on the ranking team needs four directories out of nine hundred. Does she have to download and check out everything?"
4. "A required check has been 'expected' for two days on a documentation pull request. What is broken?"

The answers, in order. A monorepo exchanges coordination across repositories for tooling inside one (section 24.2). The repositories those two companies are known for are not Git repositories, and stock Git needs features switched on at that size (sections 24.2 and 24.3, and [Chapter 26](ch26-performance.md)). No: a partial clone with a cone-mode sparse checkout downloads and checks out only what she works on (sections 24.4 to 24.7). And nothing is broken in Git: a workflow that a path filter kept from starting never reports, so the requirement cannot be met (section 24.9).

A monorepo is not a Git feature. It is a decision about where the boundary of a repository lies, and Git stores it like any repository: one object database, one set of refs, one index per working tree. This chapter covers the decision and the working-tree side; Chapter 26 covers history, storage and transfer.

Both chapters use `orbit`, a small search platform in one repository: three services, two libraries, two pipelines, documentation and tooling, 33 files, 94 commits on `main`. It is small so that you can read every transcript to the end. The mechanisms are the same at ten thousand times the size.

## 24.2 Monorepo versus polyrepo

**In one sentence.** A monorepo keeps many separately deployed projects in one repository so that one commit can change all of them; a polyrepo layout gives each project its own history, access rules and release cadence.

**Analogy.** One shared kitchen against a row of food stalls. In the kitchen a change to the menu is one conversation, and one cook's mess slows everyone. The stalls never collide, and agreeing on anything takes a meeting. The analogy breaks at cost: a kitchen gets crowded by people, a repository gets slow by files, commits and refs, whoever made them.

**Precisely.** The layouts differ in where a change crosses a boundary.

| Concern | Monorepo | Polyrepo |
|---|---|---|
| A change to a library and its users | One commit, one review. In `orbit`, commit `100bb99` changes a schema, the gateway and the ingest worker together | One pull request per repository, merged in order, with a published version between them |
| Internal dependency versions | One: what is in the tree | Each consumer pins; consumers drift |
| Access control | Git has no per-directory read permission: who can clone reads everything | Per repository |
| Ownership and review | Needs path-based rules (section 24.8) | Follows the repository |
| Continuous integration | Must compute what a change affects (section 24.9) | Each repository builds itself; integration is tested late |
| Git performance | Degrades with total size unless tuned | Rarely a concern |
| Tooling investment | A dependency-aware build system and its maintainers | Release and dependency-update automation |
| Failure radius | A broken `main` blocks everyone | A broken `main` blocks one team |

Neither column wins. Google's paper on its monorepo lists the benefits (one source of truth, shared code, atomic changes, large-scale refactoring) and the costs: heavy investment in tooling and in code health ([Potvin and Levenberg, CACM 2016](https://cacm.acm.org/research/why-google-stores-billions-of-lines-of-code-in-a-single-repository/)).

**The largest monorepos are not Git.**

- **Google** keeps its main codebase in Piper, a centralized system it built itself, because it found no existing version control system able to host about one billion files and 35 million commits (figures of January 2015, same paper).
- **Meta** serves a repository of tens of millions of files from its own server and virtual file system, with Sapling as the client. Sapling can also work with Git repositories; Meta's main repository is not one ([Engineering at Meta, 2022](https://engineering.fb.com/2022/11/15/open-source/sapling-source-control-scalable/)).
- **Microsoft** did move a very large codebase to Git: Windows, about 3.5 million files and 300 GB in 2017, first with a virtual file system and then with Scalar, whose techniques were contributed to Git ([Brian Harry, 2017](https://devblogs.microsoft.com/bharry/the-largest-git-repo-on-the-planet/); [The Story of Scalar](https://github.blog/open-source/git/the-story-of-scalar/)). Sections 24.4 to 24.7 come from that work.

Git monorepos of ordinary company size are documented by the people who run them: Canva with about half a million files in 2022 ([Canva](https://www.canva.dev/blog/engineering/we-put-half-a-million-files-in-one-git-repository-heres-what-we-learned/)), Dropbox shrinking its monorepo from 87 GB to 20 GB in 2026 ([Dropbox](https://dropbox.tech/infrastructure/reducing-our-monorepo-size-to-improve-developer-velocity)), Uber running Git operations on its Go monorepo as an internal service ([Uber](https://www.uber.com/us/en/blog/gitfarm-as-a-service/)). Each figure is that company's own measurement and no benchmark.

**In production.** For an AI/ML platform, split by coupling. Feature code, training pipeline, serving code and shared schemas change together and benefit from one repository. Components with other owners or other access rules are separate repositories, because Git cannot hide a directory. Model weights and datasets belong in neither ([Chapter 22](ch22-git-lfs.md), [Chapter 28](ch28-ai-ml-workflows.md)). No primary study of this choice for ML platforms was found for this course; treat it as a trade-off, not a rule.

## 24.3 What Git has to carry

Size has independent dimensions, and each slows different commands. Sorting a complaint into the right row is the first step of a diagnosis.

| Dimension | Commands that feel it | What addresses it |
|---|---|---|
| Tracked files (index entries, `lstat` calls) | `git status`, `git add`, `git switch` | Sparse-checkout, sparse index (sections 24.4 to 24.6); untracked cache, file-system monitor (Chapter 26, section 26.9) |
| Commits and trees | `git log -- <path>`, `git blame`, `git merge-base` | Commit-graph (26.6) |
| Blobs in all versions | `git clone`, `git fetch`, disk | Partial clone (24.7, 26.12); keeping large binaries out (Chapter 22) |
| New objects and packs per day | Everything, gradually | Maintenance (26.3 to 26.5) |
| Refs | `git fetch`, `git push` | Narrow refspecs, pruning (Chapter 12) |

The file `labs/ch24/fixture-orbit.bash` builds `orbit` for every demo and lab of both chapters, with the same commit IDs each time.

## 24.4 Sparse-checkout in cone mode

**In one sentence.** `git sparse-checkout` makes Git write only chosen directories into the working tree, while the repository, its history and its index still contain every file.

**Analogy.** A library with closed stacks: the catalogue lists every book, and your desk holds the shelves you asked for. The analogy breaks in one place: in a normal clone the stacks are in your building too, since every object is on your disk. Section 24.7 moves them out.

**Precisely.** The definition is a list of patterns in `$GIT_DIR/info/sparse-checkout`. For every index entry the patterns do not select, Git sets the **skip-worktree** bit, does not write the file, and does not report it as deleted. In **cone mode**, the default, you name directories: each is included with everything below it, and each of its parents with the files directly inside it, the top level always included. That restriction lets Git decide inclusion by hash lookup instead of matching every path against every pattern, and it is the precondition for the sparse index. The older pattern mode is deprecated in the manual's own words.

The manual carries this warning: "THIS COMMAND IS EXPERIMENTAL. ITS BEHAVIOR, AND THE BEHAVIOR OF OTHER COMMANDS IN THE PRESENCE OF SPARSE-CHECKOUTS, WILL LIKELY CHANGE IN THE FUTURE." The command dates from Git 2.25 and cone mode is the default since 2.37; the label is still there in 2.56 ([git-sparse-checkout](https://github.com/git/git/blob/v2.56.0/Documentation/git-sparse-checkout.adoc)).

The subcommands: `set <dirs>` 🟡 switches the feature on and replaces the list; `add <dirs>` 🟡 extends it; `list` 🟢 prints it; `reapply` 🟡 enforces it again; `disable` 🟡 switches it off; `init --cone` 🟡 is the older spelling of `set` with no directories, which the manual calls deprecated; `clean` 🔴 is in section 24.5.

**See it.** A full clone of `orbit`, by project:

<!-- snippet: ch24/sparse-cone/01-full -->
```text
$ ls
docs
libs
pipelines
pyproject.toml
README.md
services
tools
$ git ls-files | wc -l
      33
$ git ls-files | cut -d/ -f1-2 | sort | uniq -c
   1 .github/CODEOWNERS
   1 .gitignore
   1 docs/architecture.md
   3 docs/runbooks
   7 libs/schemas
   2 libs/tokenizer
   2 pipelines/eval
   2 pipelines/training
   1 pyproject.toml
   1 README.md
   4 services/gateway
   3 services/ingest
   4 services/ranker
   1 tools/ci
```
<!-- /snippet -->

Older tutorials start with `init --cone`. It still works and shows where every cone starts: the top-level files.

<!-- snippet: ch24/sparse-cone/02-init -->
```text
$ git sparse-checkout init --cone
$ ls -A
.git
.gitignore
pyproject.toml
README.md
$ git status
On branch main
Your branch is up to date with 'origin/main'.

You are in a sparse checkout with 10% of tracked files present.

nothing to commit, working tree clean
$ git sparse-checkout list
[exit status: 0]
```
<!-- /snippet -->

**Inside `.git`.** Three things changed, and no object or ref did:

<!-- snippet: ch24/sparse-cone/03-inside -->
```text
# The definition is a file of patterns, and the switches live in a per-worktree config file:
$ cat .git/info/sparse-checkout
/*
!/*/
$ cat .git/config.worktree
[core]
	sparseCheckout = true
	sparseCheckoutCone = true
$ git config get extensions.worktreeConfig
true
```
<!-- /snippet -->

The two patterns read "everything directly at the top level, but no directory". The switches are not in `.git/config` but in `.git/config.worktree`, which applies to one working tree and is read because `extensions.worktreeConfig` is now `true`: each linked working tree ([Chapter 25](ch25-worktrees.md)) can have its own cone.

Now name the directories you work in. `set` alone would have done what `init` did:

<!-- snippet: ch24/sparse-cone/04-set -->
```text
$ git sparse-checkout set services/ranker libs/tokenizer
$ git sparse-checkout list
libs/tokenizer
services/ranker
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
$ git status | sed -n 4p
You are in a sparse checkout with 28% of tracked files present.
```
<!-- /snippet -->

<!-- snippet: ch24/sparse-cone/05-patterns -->
```text
$ cat .git/info/sparse-checkout
/*
!/*/
/libs/
!/libs/*/
/services/
!/services/*/
/libs/tokenizer/
/services/ranker/
# Every tracked file is still in the index. Those outside the cone carry the skip-worktree bit (S):
$ git ls-files | wc -l
      33
$ git ls-files -t | cut -c1 | sort | uniq -c
   9 H
  24 S
$ git ls-files -t services
S services/gateway/app.py
S services/gateway/config.yaml
S services/gateway/routes.py
S services/gateway/tests/test_routes.py
S services/ingest/settings.py
S services/ingest/tests/test_worker.py
S services/ingest/worker.py
H services/ranker/config.yaml
H services/ranker/features.py
H services/ranker/model.py
H services/ranker/tests/test_model.py
```
<!-- /snippet -->

Read the pattern file in pairs: `/libs/` with `!/libs/*/` includes `libs` without its subdirectories (a parent), `/libs/tokenizer/` includes one subdirectory with everything below (recursive). You never edit this file in cone mode. The index still has 33 entries; `git ls-files -t` 🟢 marks ordinary entries `H` and skip-worktree entries `S`. The gateway is in the index, in `HEAD` and in the object database. It is not on disk.

<!-- snippet: ch24/sparse-cone/06-add -->
```text
$ git sparse-checkout add docs/runbooks
$ git sparse-checkout list
docs/runbooks
libs/tokenizer
services/ranker
# The parent directory arrives with its own files, but not with its other subdirectories:
$ ls docs docs/runbooks
docs:
architecture.md
runbooks

docs/runbooks:
gateway-latency.md
ingest-backlog.md
ranker-rollback.md
$ git status | sed -n 4p
You are in a sparse checkout with 40% of tracked files present.
```
<!-- /snippet -->

`docs/runbooks` was requested and `docs/architecture.md` came with it, because `docs` became a parent and parents bring their own files. There is no switch for that.

<!-- snippet: ch24/sparse-cone/07-disable -->
```text
$ git sparse-checkout disable
$ ls
docs
libs
pipelines
pyproject.toml
README.md
services
tools
$ git ls-files -t | cut -c1 | sort | uniq -c
  33 H
$ git status | sed -n 1,4p
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
# The switch is off. The old definition stays on disk, unused:
$ cat .git/config.worktree
[core]
	sparseCheckout = false
	sparseCheckoutCone = false
[index]
	sparse = false
$ wc -l < .git/info/sparse-checkout
      11
```
<!-- /snippet -->

`disable` writes every file back and sets the switches to `false`; the pattern file stays on disk, unused.

**Picture.**

```text
     HEAD (tree of 100bb99)          index: 33 entries            working tree: 9 files
  +-------------------------+   +-------------------------+   +-------------------------+
  | README.md               |   | H README.md             |   | README.md               |
  | docs/...                |   | S docs/...              |   |                         |
  | libs/schemas/...        |   | S libs/schemas/...      |   |                         |
  | libs/tokenizer/...      |   | H libs/tokenizer/...    |   | libs/tokenizer/...      |
  | services/gateway/...    |   | S services/gateway/...  |   |                         |
  | services/ranker/...     |   | H services/ranker/...   |   | services/ranker/...     |
  +-------------------------+   +-------------------------+   +-------------------------+
     every commit complete        S = skip-worktree               only the H entries
```

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git sparse-checkout set <dirs>` | Files outside the cone removed, inside written | Same entries; skip-worktree bits changed | unchanged | unchanged | `info/sparse-checkout`, `config.worktree`, `extensions.worktreeConfig` | unchanged | unchanged |
| `git sparse-checkout add <dirs>` | Files of the added directories written | Bits cleared for them | unchanged | unchanged | `info/sparse-checkout` extended | unchanged | unchanged |
| `git sparse-checkout disable` | Every tracked file written | All bits cleared | unchanged | unchanged | Switches `false`; pattern file kept | unchanged | unchanged |

**In production.** A sparse checkout is a property of one working tree. It is not committed and not pushed. A team that wants every member to start with the same cone puts the `set` line into its onboarding script. Canva used the feature to leave out generated translation files, about 70% of all files in its repository (article cited in 24.2).

## 24.5 Living in a sparse checkout

One rule explains every difference: a path with the skip-worktree bit is in the index and in history, and Git does not look at it on disk.

<!-- snippet: ch24/sparse-behaviour/01-reads -->
```text
# History and objects are complete. Only the working tree is narrow:
$ git log --oneline -2 -- services/gateway
100bb99 schemas, gateway, ingest: add the tenant field in one change
cb65af7 gateway: add search route 12
$ git show HEAD:services/gateway/config.yaml
timeout_ms: 800
upstream: ranker
# A search of the working tree sees only what is checked out; --cached searches the index:
$ git grep -l tenant
[exit status: 1]
$ git grep -l --cached tenant
libs/schemas/events.py
services/gateway/app.py
services/ingest/worker.py
```
<!-- /snippet -->

Commands that read commits, trees and blobs see the whole repository. `git grep` 🟢 without options searches the working tree, finds nothing in files that are not there, and exits with "no match": a wrong answer without a warning. `git grep --cached` searches the index.

The cone pays off in work per command. The pipeline is explained in Chapter 26, section 26.2; it prints counters that Git reports about itself, not times:

<!-- snippet: ch24/sparse-behaviour/02-status-work -->
```text
# The work of one status, counted (Chapter 26, section 26.2 explains the pipeline):
$ GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '$4 ~ /data/ {gsub(/[ .]/, "", $NF); gsub(/ /, "", $(NF-1)); print $(NF-1), $NF}' | grep -e read/cache_nr -e sum_lstat -e visited
index read/cache_nr:33
index refresh/sum_lstat:9
read_directo directories-visited:6
read_directo paths-visited:15
```
<!-- /snippet -->

The index still has 33 entries to read, but `git status` asked the file system about nine files instead of 33 and walked six directories instead of twenty.

**Files outside the cone.** A working tree gets them in two everyday ways. The first: you or a tool create one.

<!-- snippet: ch24/sparse-behaviour/03-add-outside -->
```text
# A new file in a directory outside the cone:
$ mkdir -p services/gateway
$ printf '# Gateway notes\n\nRoutes are versioned under /v1.\n' > services/gateway/NOTES.md
$ git add services/gateway/NOTES.md
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
services/gateway/NOTES.md
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
[exit status: 1]
$ git status --short
?? services/gateway/NOTES.md
```
<!-- /snippet -->

<!-- snippet: ch24/sparse-behaviour/04-add-sparse -->
```text
$ git add --sparse services/gateway/NOTES.md
$ git commit -q -m 'gateway: add notes on route versioning'
$ git ls-files -t services/gateway
H services/gateway/NOTES.md
S services/gateway/app.py
S services/gateway/config.yaml
S services/gateway/routes.py
S services/gateway/tests/test_routes.py
# The file is committed and still on disk although its directory is outside the cone:
$ ls services/gateway
NOTES.md
$ git sparse-checkout reapply
$ ls services
ranker
$ git ls-files -t services/gateway/NOTES.md
S services/gateway/NOTES.md
```
<!-- /snippet -->

`git add` refuses with exit status 1 and names the ways forward. With `--sparse` the file is staged and committed, and it stays on disk as an `H` entry among `S` entries until `git sparse-checkout reapply` removes it. The second way, in the manual's description of `reapply`: a merge or rebase may "materialize paths to do their work (e.g. in order to show you a conflict)". The same `reapply` cleans up after the resolution.

**Untracked and ignored files.** Narrowing a cone removes tracked files. What about the rest?

<!-- snippet: ch24/sparse-behaviour/05-untracked-blocks -->
```text
# Widen the cone, leave an untracked file behind, and narrow it again:
$ git sparse-checkout add pipelines/eval
$ printf 'recall@10 = 0.83\n' > pipelines/eval/results.tmp
$ git sparse-checkout set services/ranker libs/tokenizer
warning: directory 'pipelines/' contains untracked files, but is not in the sparse-checkout cone
$ find pipelines -type f
pipelines/eval/results.tmp
$ git status --short
?? pipelines/eval/results.tmp
```
<!-- /snippet -->

<!-- snippet: ch24/sparse-behaviour/06-clean -->
```text
# Preview first: the cleanup removes the whole directory, the untracked file included.
$ git sparse-checkout clean --dry-run
Would remove pipelines/
$ git sparse-checkout clean
fatal: for safety, refusing to clean without one of --force or --dry-run
[exit status: 128]
$ git sparse-checkout clean -f
Removing pipelines/
$ ls pipelines
ls: pipelines: No such file or directory
[exit status: 1]
```
<!-- /snippet -->

Git kept the untracked file and its directory and warned. `git sparse-checkout clean` 🔴 (Git 2.52 or later) removes such directories. What it changes: the working tree. What it can destroy: untracked files there, here `results.tmp`, which were never in Git, so no reflog and no `git fsck` returns them. Preview: `--dry-run`, with `--verbose` for every file. Recovery: none from Git. Appropriate: after reading the preview and moving away what you need.

Ignored files get no warning. The manual states the rule: if everything untracked in a directory outside the cone is ignored, "then the directory will be deleted".

<!-- snippet: ch24/sparse-behaviour/07-ignored-lost -->
```text
# The same sequence with a file that .gitignore covers (build/ is ignored in this repository):
$ git sparse-checkout add pipelines/eval
$ mkdir pipelines/eval/build && printf 'cached features\n' > pipelines/eval/build/features.bin
$ git status --short --ignored
!! pipelines/eval/build/
$ git sparse-checkout set services/ranker libs/tokenizer
$ ls pipelines
ls: pipelines: No such file or directory
[exit status: 1]
```
<!-- /snippet -->

Exit status 0, and the cache is gone. For a build cache that is a convenience. For an ignored file you cannot regenerate, such as a local `.env` or a downloaded evaluation set, narrowing the cone is a 🔴 operation whose only preview is `git status --short --ignored`.

```text
Observed behavior : a search or a file-listing script reports that most of the repository is gone,
                    in one engineer's clone only.
Git state         : core.sparseCheckout=true in .git/config.worktree; most index entries carry the
                    skip-worktree bit; "git status" prints "You are in a sparse checkout".
Mechanism         : commands that read the working tree see the cone; commands that read the index
                    or commits see everything.
Root cause        : a working-tree question was asked where a repository question was meant.
Why Git does this : the purpose of the feature is that the files are not on disk.
Correct fix       : ask Git: "git grep --cached", "git ls-files", "git ls-tree -r HEAD".
Prevention        : scripts that must see all files read from Git, not from the directory listing.
```

## 24.6 The sparse index

**In one sentence.** A sparse index replaces all entries of a directory outside the cone by one entry that names the directory's tree, so the index shrinks with the cone.

**Analogy.** A table of contents that lists every section of the chapters you read and one line for each other chapter. Whoever needs a section of a collapsed chapter must expand the line first, and the expansion is the slow part. The analogy breaks at who decides: a reader chooses to expand, while Git expands whenever a command asks for a path that the collapsed entry cannot answer.

**Precisely.** Section 24.5 left `read/cache_nr:33` untouched: every command still reads, and often rewrites, an index proportional to the whole repository. With `index.sparse=true`, written by `git sparse-checkout set --sparse-index` 🟡, the index may hold **sparse directory entries**: mode `040000`, a tree ID, the skip-worktree bit, a path ending in a slash ([design notes](https://github.com/git/git/blob/v2.55.0/Documentation/technical/sparse-index.adoc)). It needs cone mode. The manual marks it separately: "This feature is still experimental", and warns that external tools may not understand such an index.

**See it.**

<!-- snippet: ch24/sparse-index/01-full-index -->
```text
# A sparse checkout with an ordinary index: 33 entries for 7 files on disk.
$ git ls-files --sparse | wc -l
      33
$ git ls-files -t | cut -c1 | sort | uniq -c
   7 H
  26 S
```
<!-- /snippet -->

<!-- snippet: ch24/sparse-index/02-enable -->
```text
$ git sparse-checkout set --sparse-index services/ranker
$ cat .git/config.worktree
[core]
	sparseCheckout = true
	sparseCheckoutCone = true
[index]
	sparse = true
$ git ls-files --sparse | wc -l
      14
```
<!-- /snippet -->

<!-- snippet: ch24/sparse-index/03-entries -->
```text
# A whole directory outside the cone is now a single entry that names a tree object:
$ git ls-files --sparse --stage
040000 a3f81eb96031c5886197d2da2d1aeb5d17e4c646 0	.github/
100644 982c4febe4ff8d8dd6daee80ed5d8a282f228d44 0	.gitignore
100644 b47224884eaf3c9f9ac2bfbb32638072b748d8b7 0	README.md
040000 1e616b23f37f85ce3b07a9157ade65588054b583 0	docs/
040000 ac165d9f7472f790a4477c93edf90960e84774a7 0	libs/
040000 01bedcc4c53928618088e5c7bf68ca94f1757667 0	pipelines/
100644 897065b8f51bfbd091c267898cef63ea44564ee3 0	pyproject.toml
040000 74cd101987d4a8b085ecf364708437364befbf28 0	services/gateway/
040000 710e8eb227d465fde35a63d622e4040521e6f339 0	services/ingest/
100644 b89d0b7fac309a1df9cf9c4c1e57cc77e37ba8f6 0	services/ranker/config.yaml
100644 2e52099a797292009b44e5b9d721e5b37aeb7197 0	services/ranker/features.py
100644 fa20c90bd0927af350059ca40e00a7d2e390193b 0	services/ranker/model.py
100644 dd50a7eb0825765c50f09d9d205ff43c89f15916 0	services/ranker/tests/test_model.py
040000 c2505f39bb5212640238d272ed2c9f50aec4e0d1 0	tools/
```
<!-- /snippet -->

Fourteen entries instead of 33. `docs/`, `libs/`, `pipelines/` and `tools/` are one entry each; `services/` is not collapsed because the cone reaches into it.

**Inside `.git`.** The index file is rewritten, and `index.sparse = true` joins the switches in `config.worktree`. The tree IDs are those of `HEAD`, so Git can compare such an entry with a commit without opening it:

<!-- snippet: ch24/sparse-index/04-same-tree -->
```text
# The entry for docs/ holds exactly the ID of the docs tree in HEAD:
$ git rev-parse HEAD:docs
1e616b23f37f85ce3b07a9157ade65588054b583
$ git ls-files --sparse --stage docs/
040000 1e616b23f37f85ce3b07a9157ade65588054b583 0	docs/
$ git status
On branch main
Your branch is up to date with 'origin/main'.

You are in a sparse checkout.

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ch24/sparse-index/05-counted -->
```text
$ GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '$4 ~ /data/ {gsub(/[ .]/, "", $NF); gsub(/ /, "", $(NF-1)); print $(NF-1), $NF}' | grep -e read/cache_nr -e sum_lstat
index read/cache_nr:14
index refresh/sum_lstat:7
```
<!-- /snippet -->

Both counters now follow the cone. On `orbit` that saves nothing you can feel. GitHub's engineers reported an index shrinking from about 180 MB to under 10 MB on a test repository of two million files ([GitHub Blog, 2021](https://github.blog/open-source/git/make-your-monorepo-feel-small-with-gits-sparse-index/)); the figure is theirs.

**The cost.** A command that needs paths inside a collapsed directory expands the index in memory first:

<!-- snippet: ch24/sparse-index/06-expand -->
```text
# A command that asks for every path expands the index in memory, and says so:
$ git ls-files | wc -l
hint: The sparse index is expanding to a full index, a slow operation.
hint: Your working directory likely has contents that are outside of
hint: your sparse-checkout patterns. Use 'git sparse-checkout list' to
hint: see your sparse-checkout definition and compare it to your working
hint: directory contents. Cleaning up any merge conflicts or staged
hint: changes before running 'git sparse-checkout clean' or 'git
hint: sparse-checkout reapply' may assist in this cleanup.
hint: Disable this message with "git config set advice.sparseIndexExpanded false"
      33
# The file on disk stays sparse:
$ git ls-files --sparse | wc -l
      14
```
<!-- /snippet -->

`git ls-files` without `--sparse` lists every path, so it expands, and Git says that this is "a slow operation". The hint's guess at the cause is wrong here. A tool that runs such a command on every prompt or save cancels the benefit. `git sparse-checkout set --no-sparse-index <dirs>` goes back, and the transcript `ch24/sparse-index/07-back` shows it.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git sparse-checkout set --sparse-index <dirs>` | As `set` | Rewritten: one tree entry per directory outside the cone | unchanged | unchanged | `index.sparse=true` in `config.worktree` | unchanged | unchanged |

**In production.** Use it when the index itself is the bottleneck, which means hundreds of thousands of tracked files, and when the tools that share the working tree (editor integration, prompt, hook framework, an older Git) cope with it.

## 24.7 Partial clone plus sparse-checkout, and what `scalar clone` configures

**In one sentence.** A blobless partial clone leaves file contents on the server until something needs them, a sparse checkout limits that "something" to your cone, and `scalar clone` sets up both together with settings and scheduled maintenance.

**Precisely.** A sparse checkout alone still downloaded every version of every file. `git clone --filter=blob:none` asks the server for commits and trees without blobs, and Git fetches a blob when a command first needs it (Chapter 26, section 26.12). With `--sparse`, the checkout needs only the blobs of the cone.

**See it.** The layout that `scalar clone` creates, an enlistment directory with the working tree in `src`, built by hand:

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

Three blobs for three files, and all 96 commits and 284 trees. On one machine this needs a `file://` URL and `uploadpack.allowFilter` on the serving repository; section 26.12 shows what happens without them.

**Inside `.git`.** Two independent mechanisms in two files: the promise of the remote belongs to the repository, the cone to the working tree.

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

`git backfill --sparse` 🟢 (experimental, Git 2.49 or later) downloads the historical versions of the files in the cone in batches, so that `git log -p` and `git blame` there stop fetching blob by blob.

**What `scalar clone` does.** `scalar` ships with Git since 2.38 and is not labelled experimental. `git help scalar` describes `scalar clone <url> <enlistment>` in four parts:

1. A partial clone: "By default, only commit and tree objects are cloned", with the working tree in `<enlistment>/src`.
2. A cone-mode sparse checkout with only the top-level files, unless `--full-clone`.
3. Configuration "to optimize for large repositories", each value with its reason in the manual: among others `commitGraph.changedPaths=true`, `core.untrackedCache=true`, `index.version=4`, `fetch.unpackLimit=1`, `gc.auto=0`, `status.aheadBehind=false`, `fetch.showForcedUpdates=false`, `pack.useBitmaps=false`, `log.excludeDecoration=refs/prefetch/*`.
4. Background maintenance, the scheduler of `git maintenance start` (section 26.3), unless `--no-maintenance`.

**Why there is no `scalar clone` transcript here.** The lab rules forbid demos that install schedulers or start daemons. A contained test for this chapter (Git 2.55.0, macOS, a sandbox with its own `HOME`, the scheduler replaced by a logging stub) found: with `--no-maintenance` the scheduler was not called; the enlistment was registered in the global configuration as `scalar.repo`; and the repository received `core.fsmonitor=true` while `scalar` ran `git fsmonitor--daemon start`, which left a daemon running. `--no-maintenance` does not prevent that, and the 2.55 manual page does not list the setting. The source does ([scalar.c](https://github.com/git/git/blob/v2.55.0/scalar.c)).

On your own machine `scalar clone` is a reasonable start for a large repository if you know what it leaves behind: a registration in your global configuration, scheduler entries (on macOS under `~/Library/LaunchAgents`, per `git help maintenance`) and one monitor process per enlistment. `scalar unregister` undoes the first two for a repository, `scalar delete <enlistment>` also removes the directory, and `git fsmonitor--daemon stop` inside the working tree stops the daemon.

The hand-built clone has the same data layout without those side effects. What remains is settings and maintenance:

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

The `prefetch` task fetches into `refs/prefetch/`. Your remote-tracking branches do not move, and when you run `git fetch` yourself the objects are already local. Lab 18.4 builds this clone and then cuts the connection to the server.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clone --filter=blob:none --sparse <url>` | Top-level files | All entries; skip-worktree below the top level | Default branch | Created | Promisor configuration and packs; sparse switches | unchanged | unchanged |
| `git backfill --sparse` | unchanged | unchanged | unchanged | unchanged | New promisor packs | Read only | unchanged |
| `git maintenance run --task=prefetch` | unchanged | unchanged | unchanged | unchanged | Objects; `refs/prefetch/*` | Read only | unchanged |

## 24.8 Ownership at scale: CODEOWNERS

> **GitHub, not Git.** Git stores `.github/CODEOWNERS` as an ordinary file and gives it no meaning.

In a monorepo, ownership is a function of the path, and on GitHub that function is the `CODEOWNERS` file. `orbit` maps `/services/gateway/` to `@orbit/gateway`, `/services/ingest/` to `@orbit/data`, `/libs/` to `@orbit/platform`, and so on. [Chapter 19](ch19-codeowners.md) teaches the file. Four documented facts decide whether it works at this scale ([About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)):

- The **last matching pattern** wins, so a broad rule below a specific one replaces it silently.
- The file is read from the pull request's **base branch**: a pull request cannot change who reviews it.
- The file only requests reviews. Requiring them is a ruleset or branch protection setting ([Chapter 18](ch18-branch-protection.md)).
- A line with invalid syntax is skipped, and the pull request does not fail because of it.

Commit `100bb99` touches `libs/schemas`, `services/gateway` and `services/ingest`: three teams are asked. That is the trade-off of section 24.2 in one pull request.

## 24.9 Continuous integration at scale

A monorepo's CI must first answer: which projects does this change affect? Building everything is correct and unaffordable; building too little lets a broken `main` through. Git's part of the answer is a diff against the merge base.

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

Three dots mean "from the merge base to the second commit": what the branch did since it forked ([Chapter 14A](ch14a-history-investigation.md), section 14A.2). Two dots compare the tips and charge the branch with what `main` did meanwhile, so a pipeline built on them runs, and blames, jobs for projects the pull request never touched. A build system (section 24.10) then extends the list by dependency, which Git cannot know.

**The shallow-clone trap.** The merge base is a commit in the past, and a job that fetches one commit per branch does not have it:

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

96 commits, 284 trees and no blob are enough for `git merge-base` and for `git diff --name-only`, which compares trees. The job then checks out the affected project and its dependencies: nine files.

> **GitHub Actions, not Git.** By default `actions/checkout` fetches one commit and no tags, which is the state above; its README documents inputs for depth, a partial-clone filter and sparse-checkout ([README at v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md); [Chapter 20A](ch20a-actions-fundamentals.md)). Not run here.

**The path-filter and required-check trap.** Saving CI time with a `paths` filter and protecting `main` by requiring that workflow's check do not combine. A workflow that a path filter, a branch filter or `[skip ci]` keeps from starting never reports, so its required check stays pending and the pull request cannot merge ([skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs)). A job that starts and is skipped by a condition reports success ([troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)). That is question 4 of section 24.1. The design that follows is an inference of this course, not a GitHub recipe: start one workflow on every pull request, compute the affected projects inside it, skip jobs by condition, and require one final job that fails if any job that ran has failed ([Chapters 20A](ch20a-actions-fundamentals.md) and [20B](ch20b-actions-delivery-debugging.md)).

## 24.10 Build systems, by name and purpose

Git answers "which files changed". A monorepo also needs "which targets depend on them, and which results can be reused". That is the work of a build system that models the dependency graph: it rebuilds and retests only what a change can affect and caches results by the content of their inputs. This book teaches none of them. Know the names: [Bazel](https://bazel.build/) ("build and test your multi-language, multi-platform projects"), [Buck2](https://buck2.build/) ("an open-source large-scale build system from Meta"), [Pants](https://www.pantsbuild.org/) ("currently focused on Python, Go, Java, Scala, Kotlin, Shell, and Docker"), [Nx](https://nx.dev/) and [Turborepo](https://turborepo.dev/docs) (both describe themselves as build systems for monorepos), and [Gradle](https://gradle.org/) ("for Java, Android, and Kotlin developers"). The quotations are from the tools' own pages as fetched on 2 October 2026 and will change. For Git, two things matter: these tools write large ignored output directories, the very files that narrowing a cone deletes, and their notion of "affected" starts from the diff of section 24.9.

## 24.11 Versioning and releases in a monorepo

**In one sentence.** Tags name commits of the whole repository, so a monorepo that releases projects separately puts the project into the tag name and into every question about "the last release".

**Precisely.** There is one `refs/tags/` namespace per repository ([Chapter 14B](ch14b-config-tags-signing.md)). The usual convention is a prefix per project; the slash is only a character to Git, and patterns can match it.

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

`schemas/v1.0.0` points at a documentation commit: a tag names a state of the entire tree, here whatever `main` was when the release was cut.

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

`git describe` 🟢 without a pattern answers with the nearest tag of any project. A build that stamps the gateway with `schemas/v1.1.0` is wrong, and nothing fails. `--match` restricts the candidates.

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

Of the 42 commits between two gateway releases, six concern the gateway. A changelog, and the question "does this project need a release", must be limited to the paths the project ships, its libraries included. `git diff --quiet` 🟢 with paths turns the question into an exit status.

**In production.** Tag-triggered automation must filter on the prefix, or a ranker release deploys the gateway. A shallow clone has no tags behind its boundary, so version stamping fails there (section 26.11). On GitHub a release is attached to one tag ([Chapter 15](ch15-github.md)), so the release list mixes all projects. Whether projects share one version number is a product decision that Git neither supports specially nor prevents.

## 24.12 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A search or linter "cannot find" code that exists | `git status` says "sparse checkout"; `git ls-files -t` shows `S` | `git grep --cached`, or widen the cone | Scripts read the file list from Git |
| `git add`: "outside of your sparse-checkout definition" | `git sparse-checkout list` | `git add --sparse`, or `add` the directory | Keep what you write to inside the cone |
| Tracked files outside the cone stay on disk | `H` entries among `S` entries | `git sparse-checkout reapply` | `reapply` after conflicts outside the cone |
| "contains untracked files, but is not in the sparse-checkout cone" | Untracked, not ignored, files there | Move or commit them; `clean --dry-run`, then `-f` | Scratch output outside the repository |
| A cache or local file vanished after narrowing | It was ignored; ignored content outside the cone is deleted | None from Git | `git status --short --ignored` first |
| A tool is slow or fails after `--sparse-index` | The "expanding to a full index" hint | `set --no-sparse-index` | Test the tools first |
| `could not fetch <id> from promisor remote` | Partial clone, server unreachable | Reconnect and repeat | `git backfill --sparse` before going offline |
| CI fails with `no merge base` | `git rev-parse --is-shallow-repository` is `true` | Full depth or a blobless clone | Shallow only for snapshot jobs |
| A required check stays pending | The workflow has a path filter and never started | Start it always; decide inside | Require one aggregate job |
| A build carries another project's version | `git describe` without `--match` | Add the pattern | One release script per project |
| An unexplained daemon and scheduler entries | `scalar list`; `git fsmonitor--daemon status` | `scalar unregister`; `git fsmonitor--daemon stop` | Section 24.7 |

## 24.13 When not to use a monorepo, and dangerous edge cases

**When a monorepo is the wrong tool.**

- **Different readers.** Git cannot restrict reading to part of a repository. If some people may see some projects and not others, those are separate repositories. A review rule protects writes, not reads.
- **Unrelated lifecycles.** Projects that never change together gain nothing from atomic commits and pay for the shared history, CI queue and failure radius.
- **Large binary content.** Sparse checkout and partial clone postpone a download; they do not shrink it (Chapter 22).
- **No one to own the tooling.** Without affected-target CI and ownership rules, a monorepo becomes a slow repository with a red `main`.
- **Code you do not control** belongs in a package manager, a subtree or a submodule ([Chapter 23](ch23-submodules.md)).

**Dangerous edge cases.**

- Narrowing a cone deletes ignored files without a warning, and `clean -f` deletes untracked ones (section 24.5).
- `git commit -a` "will not record paths outside the sparse-checkout directories/patterns as deleted" (the manual). Intended, and a stray file out there is left alone too.
- A pattern file edited by hand can switch cone mode off: Git then behaves "as though `core.sparseCheckoutCone` was false", and the sparse index stops working.
- Changing the cone neither removes nor initialises submodules (`git help sparse-checkout`).
- The experimental label is real. Pin the Git version in automation that depends on these details ([Chapter 14D](ch14d-frontier.md)).
- Merging repositories into one, or splitting one, creates new commit IDs (`git subtree`, Chapter 23; `git filter-repo`, [Chapter 21B](ch21b-repository-security-incident-response.md)). Plan it as a migration with a freeze.

## 24.14 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git sparse-checkout list`, `git ls-files -t`, `git ls-files --sparse` | 🟢 | nothing | not needed | not needed |
| `git sparse-checkout set`, `add`, `init --cone` | 🟡 | Working tree, skip-worktree bits, pattern file, `config.worktree`; deletes ignored files in directories that leave the cone | `git status --short --ignored` | `set` again or `disable`; ignored files are gone |
| `git sparse-checkout reapply`, `disable` | 🟡 | Removes, or writes, tracked files | `git ls-files -t` | `set` or `add` |
| `git sparse-checkout set --sparse-index` | 🟡 | Rewrites the index in a form some tools cannot read | not needed | `--no-sparse-index` |
| `git sparse-checkout clean -f` | 🔴 | Deletes directories outside the cone with untracked files | `--dry-run`, `--verbose` | None |
| `git add --sparse` | 🟢 | Stages a path outside the cone | `git status` | `git restore --staged` |
| `git clone --filter=blob:none --sparse`, `git backfill`, `git maintenance run --task=prefetch` | 🟢 | Add objects; `refs/prefetch/*` | not needed | not needed |
| `scalar clone` | 🟡 | Also writes global configuration, installs a scheduler unless `--no-maintenance`, starts a monitor daemon | `git help scalar` | `scalar unregister` or `delete`; `git fsmonitor--daemon stop` |
| `git describe --match`, `git diff --quiet`, `git diff --name-only A...B` | 🟢 | nothing | not needed | not needed |

## 24.15 Version notes

> **Version note.** Older behavior: `git sparse-checkout init --cone` followed by `set`; without `--cone`, pattern mode. Current behavior: cone mode is the default, `set` does everything, the manual calls `init` deprecated. Since: the command in Git 2.25, the default in 2.37 ([GitHub Blog](https://github.blog/open-source/git/bring-your-monorepo-down-to-size-with-sparse-checkout/); Phase 0 report, section 1). Recommended: `git sparse-checkout set <dirs>`.

> **Version note.** Older behavior: Scalar was a separate application from Microsoft, preceded by VFS for Git, whose README now recommends Scalar ([VFS for Git](https://github.com/microsoft/VFSForGit)). Current behavior: `scalar` is a command in Git. Since: Git 2.38 ([The Story of Scalar](https://github.blog/open-source/git/the-story-of-scalar/)). Recommended: read `git help scalar` for the version you run; the list of settings changes between releases.

> **Version note.** `git sparse-checkout clean` needs Git 2.52 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)) and `git backfill` Git 2.49. `git backfill`, the sparse index, and `git sparse-checkout` as a whole are labelled experimental in Git 2.56.

## 24.16 Practice

Labs 18.2 and 18.4 in [lab-manual/m18-transfer-scale.md](../lab-manual/m18-transfer-scale.md): a cone-mode sparse checkout with work that lands outside the cone, and the clone that `scalar clone` would build, made by hand and then cut off from its server. Replay any transcript with `labs/run ch24/<demo>` (`sparse-cone`, `sparse-behaviour`, `sparse-index`, `sparse-partial`, `affected-projects`, `project-tags`); the sandbox stays in place. A drill: in `ch24/affected-projects/ci-shallow`, make the three-dot diff work with the smallest fetch you can find.

## 24.17 Interview questions

1. We are considering one repository for all services. Name three costs we would stop paying and three we would start paying. Which are Git's and which are tooling's?
2. "Google uses a monorepo, so Git can handle ours." What is wrong with that sentence?
3. Explain a cone-mode sparse checkout in terms of the index. What is on disk, in the index, in `HEAD`?
4. A search finds nothing in a colleague's clone although the code exists. Mechanism, and the command that searches everything?
5. What happens to untracked and to ignored files when a cone is narrowed?
6. What does the sparse index change, why only in cone mode, and what makes a command slower with it?
7. What does `scalar clone` set up, which parts live outside the repository, and how do you remove each?
8. Our CI computes affected projects with `git diff main..HEAD`. What is wrong, and why does the fix fail in a shallow clone?
9. A required check has been pending for two days on a documentation pull request. Cause, and the design that avoids it?
10. How do you tag and describe releases of twenty projects in one repository?
11. A team asks for a directory that only they can read. What do you answer?

## 24.18 Sources

**Primary sources.** The local manual of Git 2.55.0: `git help sparse-checkout` with its "Internals" sections, `git help scalar`, `git help clone`, `git help backfill`. Online: [git-sparse-checkout](https://git-scm.com/docs/git-sparse-checkout), [scalar](https://git-scm.com/docs/scalar), [git-backfill](https://git-scm.com/docs/git-backfill), [partial-clone](https://git-scm.com/docs/partial-clone), [git-describe](https://git-scm.com/docs/git-describe), the [sparse-index design notes](https://github.com/git/git/blob/v2.55.0/Documentation/technical/sparse-index.adoc) and [scalar.c](https://github.com/git/git/blob/v2.55.0/scalar.c) at the 2.55.0 tag. Potvin and Levenberg, [Why Google Stores Billions of Lines of Code in a Single Repository](https://cacm.acm.org/research/why-google-stores-billions-of-lines-of-code-in-a-single-repository/) (2016; not Git). Engineering at Meta, [Sapling](https://engineering.fb.com/2022/11/15/open-source/sapling-source-control-scalable/) (2022). GitHub Docs as linked in sections 24.8 and 24.9.

**Secondary sources.** GitHub Blog: [sparse-checkout](https://github.blog/open-source/git/bring-your-monorepo-down-to-size-with-sparse-checkout/) (2020), [sparse index](https://github.blog/open-source/git/make-your-monorepo-feel-small-with-gits-sparse-index/) (2021), [The Story of Scalar](https://github.blog/open-source/git/the-story-of-scalar/) (2022), [Git's database internals V](https://github.blog/open-source/git/gits-database-internals-v-scalability/) (2022) on ways to split a repository. [Software Engineering at Google, chapter 16](https://abseil.io/resources/swe-book/html/ch16.html). The practitioner reports linked in section 24.2, each from the publisher's own environment. The Phase 0 report of this course, sections 1, 12 and 13.

**Videos** (optional; assessments from the Phase 0 report). Derrick Stolee, ["Git at Scale for Everyone"](https://www.youtube.com/watch?v=USLB1gwl1vA) (32 min, 2020): partial clone and a cone-mode demo; concepts current, the Scalar packaging is the one of 2020. Scott Chacon, ["So You Think You Know Git"](https://www.youtube.com/watch?v=aolI_Rz0ZqY) (FOSDEM 2024, 47 min): a survey, with about a minute of product pitch. Stolee's [Scalar talk](https://www.youtube.com/watch?v=8iZqagosc5w) (2021) and ["Scaling Git at Microsoft"](https://www.youtube.com/watch?v=g_MPGU_m01s) (2017) describe superseded designs: history only.

**Further reading.** [Chapter 26](ch26-performance.md) for maintenance, the commit-graph and clone shapes; [Chapter 25](ch25-worktrees.md) for per-worktree configuration.

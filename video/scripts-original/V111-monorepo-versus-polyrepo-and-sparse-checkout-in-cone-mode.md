# V111: Monorepo versus polyrepo, and sparse-checkout in cone mode

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 20
- **Prerequisites.** V018, V109
- **Textbook sections.** [Chapter 24](../../textbook/ch24-monorepos.md), sections 24.1 to 24.4
- **Demo scripts.** `labs/ch24/sparse-cone.sh`

## HOOK

**[ON SCREEN]** "Four directories out of nine hundred."

A new engineer joins the ranking team. She needs four directories out of nine hundred. Your CTO asks: does she have to download and check out everything?

And in the same planning meeting: every cross-service change is five pull requests in forty repositories that must merge in order. Should we move to one repository? Google and Meta run monorepos, so why does `git status` take seconds in ours?

Three questions, and the answers start from one statement: a monorepo is not a Git feature. It is a decision about where the boundary of a repository lies, and Git stores it like any repository. Whether Git stays fast inside that boundary depends on features you switch on.

## INTRODUCTION

This video has two halves. First the decision: one repository against many, as the textbook lists the trade-offs, and what Git has to carry when you choose one. Then the first tool for living with that choice: `git sparse-checkout` in cone mode, which writes only chosen directories into the working tree.

The repository is `orbit`, a small search platform in one repository: three services, two libraries, two pipelines, documentation and tooling, 33 files, 94 commits on `main`. It is small so that you can read every transcript to the end. The mechanisms are the same at ten thousand times the size.

One replay: `labs/ch24/sparse-cone.sh`. The subcommands `set`, `add`, `reapply`, `disable` and `init --cone` are 🟡 CAUTION: they add and remove files in the working tree. `list` is 🟢 SAFE.

## LEARNING OBJECTIVES

After this video you can:

- State the trade-offs of one repository against many as the section lists them.
- Say what Git has to carry in a monorepo.
- Explain a cone-mode sparse checkout in terms of the index: what is on disk, in the index and in HEAD.
- Set, widen and disable a cone.
- Explain the label "experimental" that the documentation still carries.

## CONCEPT

In one sentence: a monorepo keeps many separately deployed projects in one repository so that one commit can change all of them; a polyrepo layout gives each project its own history, access rules and release cadence.

The layouts differ in where a change crosses a boundary.

**[ON SCREEN]** The comparison table of section 24.2.

A change to a library and its users: in a monorepo, one commit and one review; in `orbit`, one commit changes a schema, the gateway and the ingest worker together. In a polyrepo, one pull request per repository, merged in order, with a published version between them. Internal dependency versions: one in a monorepo, what is in the tree; in a polyrepo each consumer pins, and consumers drift. Access control: Git has no per-directory read permission, so who can clone reads everything; in a polyrepo, access is per repository. Ownership and review: a monorepo needs path-based rules. Continuous integration: a monorepo must compute what a change affects; in a polyrepo each repository builds itself and integration is tested late. Git performance degrades with total size unless tuned. Tooling: a dependency-aware build system and its maintainers on one side, release and dependency-update automation on the other. Failure radius: a broken `main` blocks everyone, or one team.

Neither column wins. Google's paper on its monorepo lists the benefits, one source of truth, shared code, atomic changes, large-scale refactoring, and the costs: heavy investment in tooling and in code health.

And to the CTO's second question: the largest monorepos are not Git. Google keeps its main codebase in Piper, a centralized system it built itself. Meta serves its main repository from its own server and virtual file system, with Sapling as the client. Microsoft did move a very large codebase to Git: Windows, about 3.5 million files and 300 GB in 2017, first with a virtual file system and then with Scalar, whose techniques were contributed to Git. The features of this video and the next two come from that work. Every figure the textbook quotes for a company is that company's own measurement and no benchmark.

What Git has to carry. Size has independent dimensions, and each slows different commands. Tracked files slow `git status`, `git add` and `git switch`; sparse-checkout and the sparse index address that. Commits and trees slow path-limited logs, blame and merge bases; the commit-graph addresses that. Blobs in all versions cost clone, fetch and disk; partial clone addresses that. New objects and packs per day slow everything gradually; maintenance addresses that. Refs slow fetch and push; narrow refspecs and pruning address that. Sorting a complaint into the right row is the first step of a diagnosis.

Now sparse-checkout. In one sentence: `git sparse-checkout` makes Git write only chosen directories into the working tree, while the repository, its history and its index still contain every file.

Precisely. The definition is a list of patterns in `$GIT_DIR/info/sparse-checkout`. For every index entry the patterns do not select, Git sets the skip-worktree bit, does not write the file, and does not report it as deleted. You met that bit in the index video.

In cone mode, the default, you name directories. Each is included with everything below it, and each of its parents with the files directly inside it. The top level is always included. That restriction lets Git decide inclusion by hash lookup instead of matching every path against every pattern, and it is the precondition for the sparse index. The older pattern mode is deprecated in the manual's own words.

The label. The manual carries this warning, in capitals: "THIS COMMAND IS EXPERIMENTAL. ITS BEHAVIOR, AND THE BEHAVIOR OF OTHER COMMANDS IN THE PRESENCE OF SPARSE-CHECKOUTS, WILL LIKELY CHANGE IN THE FUTURE." The command dates from Git 2.25, and cone mode is the default since 2.37. The label is still there in 2.56. So you use the feature knowing that details of how other commands behave around it may change between versions.

When not to use it: when the repository is small. A sparse checkout is one more piece of state that explains why a file is not on disk.

## MENTAL MODEL

For the decision, the textbook's analogy: one shared kitchen against a row of food stalls. In the kitchen a change to the menu is one conversation, and one cook's mess slows everyone. The stalls never collide, and agreeing on anything takes a meeting. The analogy breaks at cost: a kitchen gets crowded by people; a repository gets slow by files, commits and refs, whoever made them.

For sparse-checkout: a library with closed stacks. The catalogue lists every book, and your desk holds the shelves you asked for. The analogy breaks in one place: in a normal clone the stacks are in your building too, since every object is on your disk. Moving them out is partial clone, two videos from now.

The catalogue is the index. That is the model to keep: the index lists everything; the desk is the working tree.

## DIAGRAM

**[DIAGRAM]** Three boxes side by side: HEAD, the index, the working tree.

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

On the left, HEAD: the tree of commit `100bb99`, with every path. In the middle, the index: 33 entries, the same paths, each marked H or S. S is skip-worktree. On the right, the working tree: nine files, only the H entries.

Read the caption under the left box: every commit complete. A commit is made from the index, and the index has all 33 entries. A commit from a sparse checkout is a commit of the whole tree.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch24/sparse-cone
```

```bash
ls
git ls-files | wc -l
git ls-files | cut -d/ -f1-2 | sort | uniq -c
```

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

A full clone of `orbit`: 33 tracked files, listed by project.

Older tutorials start with `init --cone`. The manual calls it deprecated; it still works, and it shows where every cone starts.

```bash
git sparse-checkout init --cone
ls -A
git status
git sparse-checkout list
```

**[PAUSE]** No directory has been named yet. What is left in the working tree?

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

The top-level files, and nothing else. `git status` says so in words: "You are in a sparse checkout with 10% of tracked files present." And the working tree is clean: the missing files are not reported as deleted.

```bash
cat .git/info/sparse-checkout
cat .git/config.worktree
git config get extensions.worktreeConfig
```

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

Three things changed, and no object or ref did. The two patterns read "everything directly at the top level, but no directory". The switches are not in `.git/config`; they are in `.git/config.worktree`, which applies to one working tree and is read because `extensions.worktreeConfig` is now `true`. Each linked working tree can have its own cone.

Now name the directories you work in.

```bash
git sparse-checkout set services/ranker libs/tokenizer
git sparse-checkout list
find . -path ./.git -prune -o -type f -print | sort
git status | sed -n 4p
```

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

Nine files, 28% of the tracked files.

```bash
cat .git/info/sparse-checkout
git ls-files | wc -l
git ls-files -t | cut -c1 | sort | uniq -c
git ls-files -t services
```

**[PAUSE]** Nine files are on disk. How many entries does the index have?

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

Thirty-three. Nine marked H, twenty-four marked S. The gateway is in the index, in HEAD and in the object database. It is not on disk.

Read the pattern file in pairs: `/libs/` with `!/libs/*/` includes `libs` without its subdirectories, as a parent; `/libs/tokenizer/` includes one subdirectory with everything below. You never edit this file in cone mode.

```bash
git sparse-checkout add docs/runbooks
git sparse-checkout list
ls docs docs/runbooks
```

**[PAUSE]** Only `docs/runbooks` was requested. Will `docs/architecture.md` appear?

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

It does. `docs` became a parent, and parents bring their own files. There is no switch for that.

```bash
git sparse-checkout disable
ls
git ls-files -t | cut -c1 | sort | uniq -c
cat .git/config.worktree
wc -l < .git/info/sparse-checkout
```

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

`disable` writes every file back and sets the switches to `false`. The pattern file stays on disk, unused.

**[ON SCREEN]** The state table of section 24.4: `set` removes files outside the cone and writes those inside, keeps the same index entries and changes skip-worktree bits; HEAD and the branch ref are unchanged; `info/sparse-checkout`, `config.worktree` and `extensions.worktreeConfig` are written; remote and GitHub unchanged.

## COMMON MISTAKES

1. Believing a commit from a sparse checkout contains only the cone. Root cause: the index still has every entry, and a commit is made from the index.
2. Expecting a teammate to get your cone after a pull. Root cause: a sparse checkout is a property of one working tree; it is not committed and not pushed.
3. Editing `.git/info/sparse-checkout` by hand in cone mode. Root cause: cone mode generates parent and recursive pattern pairs; the commands maintain them.
4. Being surprised by files next to the requested directory. Root cause: every parent of a cone directory is included with the files directly inside it.
5. Moving to a monorepo to restrict who reads what. Root cause: Git has no per-directory read permission; who can clone reads everything.

## PRODUCTION EXAMPLE

An AI/ML platform team decides its layout by coupling, as the textbook suggests. Feature code, the training pipeline, serving code and shared schemas change together and benefit from one repository. Components with other owners or other access rules are separate repositories, because Git cannot hide a directory. Model weights and datasets belong in neither. The textbook adds a caveat that I repeat: no primary study of this choice for ML platforms was found for this course; treat it as a trade-off, not a rule.

In the shared repository, the team wants every new member of the ranking group to start with the same cone. Because a cone is not committed, they put the `git sparse-checkout set` line into the onboarding script. For scale, the textbook cites Canva, which used the feature to leave out generated translation files, about 70% of all files in its repository, by its own account.

## PRACTICE EXERCISE

Do Lab 18.2, "Cone-mode sparse-checkout", in [`lab-manual/m18-transfer-scale.md`](../../lab-manual/m18-transfer-scale.md). Before each `set` or `add`, write down three numbers: files on disk, entries in the index, entries marked S. Then check with `git ls-files -t`.

The challenge is Exercise 18.8, "A file that is not on disk", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 423 of the CTO question bank:

> "Explain a cone-mode sparse checkout in terms of the index. What is on disk, in the index, in `HEAD`?"

A strong answer takes the three places one at a time and gives a count or a rule for each. It names the bit that makes the difference and says what that bit tells Git to do and not to do. It adds what cone mode restricts and why that restriction exists, and it draws the consequence for commits.

## RECAP

You should now be able to say:

- A monorepo is a decision about a repository boundary; it trades coordination across repositories for tooling inside one.
- Size has independent dimensions, and each has its own remedy.
- In a sparse checkout, HEAD and the index describe every file; the working tree holds only entries without the skip-worktree bit.
- Cone mode selects directories, with their parents' own files and the top level.
- The cone is local to one working tree, and the command is still labelled experimental in the manual.

## HOMEWORK

Read sections 24.1 to 24.4 of [Chapter 24](../../textbook/ch24-monorepos.md). Do Exercise 18.3, "Cone-mode sparse checkout", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

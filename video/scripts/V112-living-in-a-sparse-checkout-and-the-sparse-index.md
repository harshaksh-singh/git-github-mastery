# V112: Living in a sparse checkout, and the sparse index

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 20
- **Prerequisites.** V111
- **Textbook sections.** [Chapter 24](../../textbook/ch24-monorepos.md), sections 24.5 and 24.6
- **Demo scripts.** `labs/ch24/sparse-behaviour.sh`, `labs/ch24/sparse-index.sh`

## HOOK

**[ON SCREEN]** `git grep -l tenant` — no output, exit status 1.

An engineer is asked which files use the `tenant` field before a schema change. She runs `git grep` in her clone, gets no match, and reports that nothing uses it. Three files use it. The change breaks two services.

Her repository wasn't damaged, and her command wasn't wrong. Her clone was a sparse checkout, a working tree that holds only chosen directories. She asked a working-tree question where a repository question was meant.

Later the same week she narrows her cone, the set of directories she chose, and loses a downloaded evaluation set that took an hour to fetch. Git printed nothing and exited with status 0. Both events follow from one rule, and that rule comes first. Hold on to that silent exit.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Here's the rule, from section 24.5: a path with the skip-worktree bit is in the index and in history, and Git does not look at it on disk. The index is Git's record of every tracked path, and the skip-worktree bit is a flag on one of its entries.

In the last video you set a cone. Now you live in one. You'll see which commands see the cone and which see everything, what `git add` does outside the cone, and what happens to untracked and ignored files when the cone gets narrower. Then the sparse index: a way to make the index itself shrink with the cone.

Two replays: `labs/ch24/sparse-behaviour.sh` and `labs/ch24/sparse-index.sh`.

Labels. `git grep` is 🟢 SAFE. `git sparse-checkout reapply` and `set --sparse-index` are 🟡 CAUTION. `git sparse-checkout clean` is 🔴 DANGEROUS, and it gets its five answers before it runs.

## LEARNING OBJECTIVES

After this video you can:

- Predict what search, status and add do for paths outside the cone.
- Explain what happens to untracked and ignored files when a cone is narrowed.
- Clean leftovers after narrowing a cone, with a dry run first.
- Say what the sparse index changes, why only in cone mode, and what makes a command expand it.

## CONCEPT

Start from the rule and derive the behaviour.

**[ANIMATION]** stores: id=places boxes=HEAD_and_history:every_path|index:every_path|*working_tree:only_the_cone rows=1:A:git_log|1:A:git_show|2:C:git_grep:_no_match@bad|3:B:git_grep_--cached@ok|4:C:git_status mono=on title=Which_place_does_the_command_read? at_1=3 at_2=45 at_3=85

**[ANIMATION]** step: 3

Commands that read commits, trees and blobs see the whole repository: `git log` on a path outside the cone, `git show` of a file outside the cone. Commands that read the working tree, the files on your disk, see only the cone. `git grep` without options searches the working tree. It finds nothing in files that aren't there, and exits with "no match". That's a wrong answer without a warning. `git grep --cached` searches the index, which has every path.

**[ANIMATION]** step: 4

Why accept that? Because the cone pays off in work per command. `git status` asks the file system only about files inside the cone and walks only the directories that exist.

**[ANIMATION]** walk: id=outside columns=step,on_disk,index_entry rows=a_new_file_outside_the_cone:yes:none|git_add:yes:refused,_exit_status_1|git_add_--sparse:yes:staged|git_sparse-checkout_reapply:removed:skip-worktree marks=2.3:bad,3.3:ok,4.2:hl title=A_file_outside_the_cone at_1=12 at_2=30 at_3=45 at_4=58

**[ANIMATION]** step: 4

Now files outside the cone. A working tree gets them in two everyday ways. The first: you or a tool create one. `git add` then refuses with exit status 1 and names the ways forward. With `git add --sparse` the file is staged, and it stays on disk until `git sparse-checkout reapply` removes it. The second way, in the manual's description of `reapply`: a merge or rebase may "materialize paths to do their work (e.g. in order to show you a conflict)". The same `reapply` cleans up after the resolution.

**[ANIMATION]** walk: id=narrow columns=kind_of_file,when_the_cone_narrows,warning rows=tracked:removed_from_disk,_still_in_the_index_and_in_history:-|untracked:kept,_with_its_directory:yes|ignored:its_directory_is_deleted:none marks=1.2:ok,2.3:ok,3.2:bad,3.3:bad mono=off title=Narrowing_a_cone twig_3=worried

**[ANIMATION]** step: 1

Then narrowing. Narrowing a cone removes tracked files. That's safe: they're in the index and in history. What about the rest?

**[ANIMATION]** step: 2

Untracked files have no index entry and match no ignore pattern. Git keeps such a file and its directory, and warns. Removing such directories is the job of `git sparse-checkout clean`, which needs Git 2.52 or later.

**[ANIMATION]** step: 3

Ignored files, the ones an ignore pattern matches, get no warning. The manual states the rule: if everything untracked in a directory outside the cone is ignored, "then the directory will be deleted". For a build cache that's a convenience. For an ignored file you can't regenerate, such as a local `.env` or a downloaded evaluation set, narrowing the cone is a 🔴 operation whose only preview is `git status --short --ignored`.

**[ANIMATION]** stores: id=sparse boxes=ordinary_index:33_entries|*sparse_index:14_entries rows=1:A:S_docs/architecture.md|1:A:S_docs/runbooks/..._(3)|2:B:040000_docs/@hl|3:A:H_services/ranker/..._(4)|3:B:100644_services/ranker/..._(4)|4:B:a_path_inside_docs/:_expand_first@bad arrows=2:A1>B1:one_tree_entry mono=on title=One_entry_for_a_whole_directory at_1=40 at_2=60

**[ANIMATION]** step: 2

Now the sparse index. The problem it solves: after everything above, each command still reads, and often rewrites, an index proportional to the whole repository. In one sentence: a sparse index replaces all entries of a directory outside the cone by one entry that names the directory's tree, so the index shrinks with the cone. A tree is the object that holds one directory listing.

**[ANIMATION]** step: 3

Now precisely. With `index.sparse=true`, written by `git sparse-checkout set --sparse-index`, the index may hold sparse directory entries: mode `040000`, a tree ID, the skip-worktree bit, and a path ending in a slash. It needs cone mode, because only cone mode guarantees that a whole directory is either in or out. The manual marks it separately: "This feature is still experimental", and it warns that external tools may not understand such an index.

**[ANIMATION]** step: 4

The cost: a command that needs paths inside a collapsed directory expands the index in memory first, and Git itself calls that "a slow operation".

**[ANIMATION]** end

When should you use the sparse index? When the index itself is the bottleneck, which means hundreds of thousands of tracked files, and when the tools that share the working tree cope with it: the editor integration, the prompt, the hook framework, an older Git. When not? When a tool runs an expanding command on every prompt or save. That cancels the benefit.

## MENTAL MODEL

**[ANIMATION]** step: sparse.4

The textbook's analogy for the sparse index: a table of contents that lists every section of the chapters you read and one line for each other chapter. Whoever needs a section of a collapsed chapter must expand the line first, and the expansion is the slow part.

The analogy breaks at who decides. A reader chooses to expand. Git expands whenever a command asks for a path that the collapsed entry cannot answer.

**[ANIMATION]** step: places.4

For the first half of the video, keep the question you learned to ask in the last video: which of the three places does this command read? HEAD and history, the index, or the disk. If it reads the disk, it sees the cone.

**[ANIMATION]** end

Try it now, thirty seconds, on paper. Write those three places down. Next to each, put the one that reads it: `git log`, `git grep`, or `git grep --cached`. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: places.4

`git log` reads history. `git grep --cached` reads the index. Plain `git grep` reads the disk, so it sees only the cone.

## DIAGRAM

**[DIAGRAM]** The same index twice: full, then sparse.

```text
   ordinary index in a sparse checkout            sparse index (index.sparse = true)
   33 entries                                     14 entries

   S  .github/CODEOWNERS                          040000  .github/              one tree entry
   H  .gitignore                                  100644  .gitignore
   H  README.md                                   100644  README.md
   S  docs/architecture.md        \
   S  docs/runbooks/...  (3)      /               040000  docs/                 one tree entry
   S  libs/schemas/...   (7)      \
   S  libs/tokenizer/... (2)      /               040000  libs/                 one tree entry
   S  pipelines/...      (4)                      040000  pipelines/            one tree entry
   H  pyproject.toml                              100644  pyproject.toml
   S  services/gateway/... (4)                    040000  services/gateway/     one tree entry
   S  services/ingest/...  (3)                    040000  services/ingest/      one tree entry
   H  services/ranker/...  (4)                    100644  services/ranker/...   4 file entries
   S  tools/ci/...       (1)                      040000  tools/                one tree entry
```

On the left, the index you know: 33 entries, most of them marked S, for skip-worktree. On the right, the same content with `index.sparse` on: 14 entries. Each directory that lies wholly outside the cone has become one line with mode `040000` and a tree ID.

Look at `services`. It isn't collapsed, because the cone reaches into it. Its two outside subdirectories collapse separately, and the four files of the ranker stay as file entries.

**[ON SCREEN]** The root-cause box of section 24.5.

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

Read the root-cause line: a working-tree question was asked where a repository question was meant. The fix is to ask Git.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch24/sparse-behaviour
```

The cone is `services/ranker` and `libs/tokenizer`.

```bash
git log --oneline -2 -- services/gateway
git show HEAD:services/gateway/config.yaml
git grep -l tenant
git grep -l --cached tenant
```

The gateway is outside the cone. Which of these four commands give an answer about it? Say it out loud. I'll wait.

**[PAUSE]**

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

`git log` and `git show` answer: history and objects are complete. `git grep` finds nothing and exits 1. `git grep --cached` finds three files. That's the hook.

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

The work of one `git status`, counted. The index still has 33 entries to read, but Git asked the file system about nine files where a full checkout needs 33, and walked six directories where it would walk twenty.

A new file outside the cone.

```bash
mkdir -p services/gateway
printf '# Gateway notes\n\nRoutes are versioned under /v1.\n' > services/gateway/NOTES.md
git add services/gateway/NOTES.md
git status --short
```

Quick quiz, two options. A plain `git add` of a new file in a directory outside the cone: staged or refused? Say it out loud.

**[PAUSE]**

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

Refused, with exit status 1, and the hint names `--sparse`. If you said staged, that's a fair guess: staging is what `git add` is for.

```bash
git add --sparse services/gateway/NOTES.md
git commit -q -m 'gateway: add notes on route versioning'
git ls-files -t services/gateway
ls services/gateway
git sparse-checkout reapply
ls services
git ls-files -t services/gateway/NOTES.md
```

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

The file is committed and still on disk, an H entry among S entries. `git sparse-checkout reapply`, 🟡, enforces the cone again: the file leaves the disk and its entry becomes S.

Now untracked files.

```bash
git sparse-checkout add pipelines/eval
printf 'recall@10 = 0.83\n' > pipelines/eval/results.tmp
git sparse-checkout set services/ranker libs/tokenizer
find pipelines -type f
git status --short
```

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

Git kept the untracked file and its directory, and warned.

Now the 🔴 command, `git sparse-checkout clean`. Twig looks worried, and fairly so. The five answers. What it changes: the working tree. What it can destroy: untracked files there, here `results.tmp`, which were never in Git, so no reflog and no `git fsck` returns them. Preview: `--dry-run`, with `--verbose` for every file. Recovery: none from Git. Appropriate: after reading the preview and moving away what you need.

```bash
git sparse-checkout clean --dry-run
git sparse-checkout clean
git sparse-checkout clean -f
ls pipelines
```

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

The dry run says it would remove the whole directory `pipelines/`. Without `--force` or `--dry-run` the command refuses. With `-f` the directory is gone, the untracked file with it.

The same sequence with an ignored file. `build/` is ignored in this repository.

```bash
git sparse-checkout add pipelines/eval
mkdir pipelines/eval/build && printf 'cached features\n' > pipelines/eval/build/features.bin
git status --short --ignored
git sparse-checkout set services/ranker libs/tokenizer
ls pipelines
```

Last time Git warned and kept the file. This time the file is ignored. What does narrowing print? Make your prediction. I'll wait.

**[PAUSE]**

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

Nothing. Exit status 0, and the cache is gone. That's the silent exit from the hook.

**[TERMINAL]** The sparse index.

```bash
labs/run ch24/sparse-index
```

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

A sparse checkout with an ordinary index: 33 entries for 7 files on disk.

```bash
git sparse-checkout set --sparse-index services/ranker
cat .git/config.worktree
git ls-files --sparse | wc -l
```

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

```bash
git ls-files --sparse --stage
```

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

Fourteen entries. This is the right-hand side of the diagram, with the real tree IDs.

```bash
git rev-parse HEAD:docs
git ls-files --sparse --stage docs/
git status
```

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

The entry for `docs/` holds exactly the ID of the `docs` tree in HEAD. So Git can compare such an entry with a commit without opening it.

<!-- snippet: ch24/sparse-index/05-counted -->
```text
$ GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '$4 ~ /data/ {gsub(/[ .]/, "", $NF); gsub(/ /, "", $(NF-1)); print $(NF-1), $NF}' | grep -e read/cache_nr -e sum_lstat
index read/cache_nr:14
index refresh/sum_lstat:7
```
<!-- /snippet -->

Both counters now follow the cone: 14 entries read, 7 `lstat` calls. On `orbit` that saves nothing you can feel. The textbook cites GitHub's engineers, who reported an index shrinking from about 180 megabytes to under 10 megabytes on a test repository of two million files. The figure is theirs.

```bash
git ls-files | wc -l
git ls-files --sparse | wc -l
```

`git ls-files` without `--sparse` must list every path. What does Git have to do first? Say it out loud.

**[PAUSE]**

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

It expands the index in memory and says so: "a slow operation". The hint's guess at the cause is wrong here. The file on disk stays sparse: 14 entries.

<!-- snippet: ch24/sparse-index/07-back -->
```text
$ git sparse-checkout set --no-sparse-index services/ranker
hint: The sparse index is expanding to a full index, a slow operation.
hint: Your working directory likely has contents that are outside of
hint: your sparse-checkout patterns. Use 'git sparse-checkout list' to
hint: see your sparse-checkout definition and compare it to your working
hint: directory contents. Cleaning up any merge conflicts or staged
hint: changes before running 'git sparse-checkout clean' or 'git
hint: sparse-checkout reapply' may assist in this cleanup.
hint: Disable this message with "git config set advice.sparseIndexExpanded false"
$ git ls-files --sparse | wc -l
      33
$ git config get index.sparse
false
```
<!-- /snippet -->

And the way back: `git sparse-checkout set --no-sparse-index`.

## COMMON MISTAKES

Five mistakes to watch for.

1. Searching a sparse checkout with plain `git grep` or a directory listing and trusting "no match". Root cause: a working-tree question was asked where a repository question was meant; `git grep --cached` and `git ls-files` read the index.
2. Narrowing a cone over a directory with ignored files that cannot be regenerated. Root cause: if everything untracked in a directory outside the cone is ignored, the directory is deleted without a warning.
3. Running `git sparse-checkout clean -f` without the dry run. Root cause: it removes whole directories, including untracked files that were never in Git.
4. Expecting `git add` to stage a new file outside the cone. Root cause: Git does not update index entries outside the sparse-checkout definition unless `--sparse` is given.
5. Enabling the sparse index and seeing no gain. Root cause: a tool that asks for every path makes Git expand the index on each call.

## PRODUCTION EXAMPLE

Now, out of the lab. A search team's pre-merge script lists Python files with `find` and checks that each has a test. In one engineer's clone it reports that most of the repository has no tests, and in CI, the automated checks, it's right. Her clone is a sparse checkout: `git status` prints "You are in a sparse checkout". The script is changed to read from Git, with `git ls-files`, so that it sees all files in every clone.

The same team adopts a rule for narrowing a cone: run `git status --short --ignored` first, and move away any ignored file that cannot be regenerated, such as a local `.env` or a downloaded evaluation set. Then narrow, then `git sparse-checkout clean --dry-run`, then clean.

## PRACTICE EXERCISE

Your turn. Do Exercise 18.8, "A file that is not on disk", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md). Before you run anything, state for the file in question where it exists: on disk, in the index, in HEAD. Then predict what each command of the exercise will report, and only then run it.

The challenge is Exercise 18.9, "The clone that believes it is up to date", in the same file.

## INTERVIEW QUESTION

Question 431 of the CTO question bank:

> "What happens to untracked and to ignored files when a cone is narrowed?"

**[PAUSE]**

Answer out loud. A strong answer separates three kinds of file, tracked, untracked and ignored, and gives a different outcome for each. It says which outcome comes with a warning and which without, names the command that removes leftovers and its preview, and names the only preview there is for the silent case. It states plainly what can't be recovered from Git.

## RECAP

Let's land this.

You should now be able to say:

- A path with the skip-worktree bit is in the index and in history, and Git does not look at it on disk.
- Working-tree commands see the cone; index and history commands see everything; `git grep` needs `--cached`.
- Narrowing a cone keeps untracked files with a warning and deletes directories whose untracked content is all ignored, silently.
- `git sparse-checkout clean` removes leftovers and cannot be undone; run it with `--dry-run` first.
- The sparse index stores one tree entry per directory outside the cone, needs cone mode, and expands when a command asks for a path inside.

## HOMEWORK

Read sections 24.5 and 24.6 of [Chapter 24](../../textbook/ch24-monorepos.md).

**[ANIMATION]** step: places.4

Today you watched a correct command give a wrong answer, and you know which place to ask instead. Practise the three places on one file before the next video: partial clone plus sparse checkout. Until then, look at the state first and type second. See you in the next one.

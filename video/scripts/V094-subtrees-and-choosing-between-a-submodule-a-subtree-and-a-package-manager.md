# V094: Subtrees, and choosing between a submodule, a subtree and a package manager

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS
- **Planned minutes.** 20
- **Prerequisites.** V036, V093
- **Textbook sections.** [Chapter 23](../../textbook/ch23-submodules.md), sections 23.13 to 23.17
- **Demo scripts.** `labs/ch23/subtree.sh`, and the snippet `05-failure` of `labs/ch23/lab-15-2-subtree.sh`

## HOOK

**[ON SCREEN]** "Why does this mechanism fail so often, and should we be using it at all?"

That was the CTO's question after a week of reports about submodules, which are other repositories checked out inside yours: an empty directory, `not our ref`, a silent downgrade, a red `main`. You have spent three videos on the first half. You can now explain every one of those failures as a disagreement between three values.

The second half is a decision, and it deserves a real answer. There are two alternatives. One of them makes all four reports impossible, because a plain clone contains everything, and pays for that in other ways. Hold on to that claim. The other isn't a Git mechanism at all: it's a package manager, such as pip or npm, and for most libraries it's the right answer.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Today you solve the same problem a second time. The library `textsplit` goes into the service `doc-qa` again, under the same path, as a subtree: its files become ordinary files in your repository's own history.

You'll add it, see what a teammate's clone contains, pull an upstream release into it, change the library and the application in one commit, and offer the library part back upstream. Then the decision table: submodule, subtree, or a package manager.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- add a dependency as a subtree and show what the superproject's history then contains;
- pull an upstream release into the subtree and contribute a local change back;
- explain how `git subtree split` can reproduce upstream commit IDs;
- decide between submodule, subtree and package manager for a described dependency.

## CONCEPT

**[ANIMATION]** graph: id=plan 1d93b09-bf78eb9 main; HEAD=main => 1d93b09-bf78eb9-fb692e1 main; c77d389-fb692e1; HEAD=main; sub:c77d389:split:_e216665 => 1d93b09-bf78eb9-fb692e1-7241fca main; c77d389-c2dc1b7-7241fca; HEAD=main; sub:c77d389:split:_e216665; sub:c2dc1b7:split:_4980f0b title=doc-qa_with_a_subtree dx=250

**[ANIMATION]** step: plan.state-2

In one sentence: 🟡 CAUTION, `git subtree add` copies another project's files into a subdirectory of your repository as ordinary tracked files, and records in commit messages where they came from, so that later commands can merge newer upstream versions in or extract your changes back out.

**[ANIMATION]** end

Now precisely. `git subtree` is a script from Git's `contrib/` directory. The Homebrew Git on the course's Mac installs it. It has no page in `git help`. Its documentation is in the Git source tree, and `git subtree -h` prints the usage. That documentation states the contrast with submodules itself: subtrees "do not need any special constructions (like `.gitmodules` files or gitlinks) be present in your repository, and do not force end-users of your repository to do anything special or to understand how subtrees work". Don't confuse the command with the `subtree` merge strategy of `git merge -s subtree`, which it builds on.

**[ANIMATION]** objects: id=msg cards=commit:c77d389:tree_bb3d20d+Squashed_'vendor/textsplit/'_content+git-subtree-dir:_vendor/textsplit+git-subtree-split:_e216665,tree:bb3d20d:README.md+splitter.py title=The_whole_mechanism:_two_trailer_lines

Inside `.git`: nothing special at all. The entry at the prefix, the subdirectory you chose, has mode `040000`, a tree like any other directory. The files are blobs in your object database. There's no `.gitmodules`, no `.git/modules`, no configuration. The whole mechanism is two trailer lines, the labelled lines at the end of a commit message: `git-subtree-dir`, and `git-subtree-split`, the upstream commit that the content corresponds to.

**[ANIMATION]** step: plan.state-3

**Updating.** 🟡 CAUTION: `git subtree pull` fetches the upstream branch, builds a squash commit, one commit that carries the whole difference since the recorded split point, and merges it. It's an ordinary merge: if you changed the vendored files yourself and upstream changed the same lines, you resolve a normal content conflict in normal files.

The `--squash` option has to be used consistently. A repository whose subtree was added with `--squash` has none of the upstream commits in its history, so a pull without it tries to merge two histories with no common ancestor.

**[ANIMATION]** end

**Contributing back.** Because the files are yours, one commit can change the library and the application together, which a submodule can't do. 🟢 SAFE: `git subtree split` walks your history and synthesizes a history that contains only what happened under the prefix, with the prefix removed from the paths. `git subtree push` is a split followed by a push of the result.

**The price.** The repository grows with every vendored version. The link to upstream lives in commit messages that a rebase or a squash-merge of the pull request can destroy. And everyone who updates the copy must use the same command with the same options.

**[ANIMATION]** cards: id=rule cards=Published_as_a_package:the_package_manager|Not_a_package,_must_be_there_after_a_plain_clone:a_subtree|Must_remain_a_separate_repository:a_submodule,_with_the_recommended_configuration|"One_atomic_commit_across_both":maybe_one_repository numbered=on title=The_textbook's_rule,_in_four_steps

**[ANIMATION]** step: rule.4

**How to decide.** The textbook's rule has four steps. If the dependency is published as a package, use the package manager: it solves versioning, transitive dependencies and security advisories, which neither Git mechanism attempts. If it isn't a package and must be present after a plain clone, use a subtree. If it must remain a separate repository, with its own access rules, its own release cadence, or a size you don't want in your history, and the team will adopt the recommended configuration, use a submodule. And if the real wish is "one atomic commit across both", the two projects may belong in one repository.

**[ANIMATION]** end

When should you not use a subtree? When the vendored content is large or changes often, because every version stays in your history. Or when its access rules must differ from those of the consuming repository.

## MENTAL MODEL

The textbook continues the recipe analogy. Instead of a reference to page 212 of the other book, you photocopy the page and bind the copy into yours, with a note in the margin saying which printing it was copied from. Every reader of your book has the recipe.

The margin note is the only link to the original. If somebody copies a newer printing over it without updating the note, the next update has nothing to go by.

**[ANIMATION]** stores: id=link boxes=as_a_submodule:the_link_to_the_library|as_a_subtree:the_link_to_upstream rows=1:A:a_tree_entry@hl|1:B:text_in_a_commit_message@hl|2:A:Git_reads_it|2:B:a_script_reads_it|3:B:rewrite_or_squash_that_commit:_gone@bad title=Where_the_link_lives

That's where the analogy holds exactly, and it's the thing to remember. A submodule's link is a tree entry that Git reads. A subtree's link is text in a commit message that a script reads. Rewrite or squash that commit, and the link is gone, without an error.

**[ANIMATION]** end

Try it now, on paper, thirty seconds. Write the entry for `vendor/textsplit` twice: once as a submodule, once as a subtree. Predict the mode of each.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** The same dependency drawn twice.

```text
  AS A SUBMODULE                                         AS A SUBTREE
  doc-qa commit                                          doc-qa commit
    tree                                                   tree
      100644 blob   ingest.py                                100644 blob   ingest.py
      100644 blob   .gitmodules   (url)                      040000 tree   vendor
      040000 tree   vendor                                     040000 tree   textsplit
        160000 commit e216665  textsplit --+                     100644 blob   README.md
                                           |                     100644 blob   splitter.py
        points OUT of this repository      |
        (the object is not here)           v             everything is IN this repository;
                                   textsplit repository   the only link to upstream is in a commit message:
                                                            git-subtree-dir:   vendor/textsplit
                                                            git-subtree-split: e2166657d4da...
```

Check your paper. On the left, one entry of mode `160000` whose target is somewhere else. On the right, an ordinary tree, mode `040000`, with ordinary blobs. A plain clone of the left has an empty directory. A plain clone of the right has the files.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch23/subtree`. Start again from `doc-qa` without any dependency.

**[ON SCREEN]** 🟡 CAUTION: `git subtree add` and `git subtree pull`. New commits on the current branch, a merge; they need a clean working tree. Preview: `git ls-remote <repository> <ref>`. Recovery: `git reset --hard ORIG_HEAD` if not pushed, which is itself 🔴 DANGEROUS for uncommitted work; `git revert -m 1` if pushed.

```bash
git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git log --graph --format="%h %an: %s"
```

Predict how many new commits appear. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch23/subtree/01-add -->
```text
$ git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git fetch ../remotes/textsplit.git main
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
Added dir 'vendor/textsplit'
$ git log --graph --format="%h %an: %s"
*   fb692e1 Lab User: Merge commit 'c77d389e2c498a974e85fe327f712348bbe6f573' as 'vendor/textsplit'
|\  
| * c77d389 Lab User: Squashed 'vendor/textsplit/' content from commit e216665
* bf78eb9 Lab User: Add keyword answerer
* 1d93b09 Lab User: Add document loader
```
<!-- /snippet -->

**[ANIMATION]** graph: id=hist 1d93b09-bf78eb9 main; HEAD=main => 1d93b09-bf78eb9-fb692e1 main; c77d389-fb692e1; HEAD=main; sub:c77d389:split:_e216665 => 1d93b09-bf78eb9-fb692e1-7241fca main; c77d389-c2dc1b7-7241fca; HEAD=main; sub:c77d389:split:_e216665; sub:c2dc1b7:split:_4980f0b => 1d93b09-bf78eb9-fb692e1-7241fca-e3827e6 main; HEAD=main; sub:c77d389:split:_e216665; sub:c2dc1b7:split:_4980f0b => 1d93b09-bf78eb9-fb692e1-7241fca-e3827e6 main; ceaafe1-e216665-4980f0b-ee9c8f1 textsplit-export; HEAD=main; sub:c77d389:split:_e216665; sub:c2dc1b7:split:_4980f0b; sub:ceaafe1:Asha_Rao; sub:e216665:Asha_Rao; sub:4980f0b:Asha_Rao; sub:ee9c8f1:Lab_User title=doc-qa_with_a_subtree dx=250

**[ANIMATION]** step: hist.state-2

Two. `c77d389` is a commit with no parent in your history, whose tree is the library's tree at upstream commit `e216665`. `fb692e1` merges it into `main` and places that tree at `vendor/textsplit`. Without `--squash` the merge would bring the library's entire history into yours.

```bash
git ls-tree HEAD vendor/
git ls-files vendor
git log -1 --format=%B HEAD^2
```

<!-- snippet: ch23/subtree/02-what-it-is -->
```text
$ git ls-tree HEAD vendor/
040000 tree bb3d20df131c55a48b035cace5cd1812d87d5332	vendor/textsplit
$ git ls-files vendor
vendor/textsplit/README.md
vendor/textsplit/splitter.py
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/textsplit/' content from commit e216665

git-subtree-dir: vendor/textsplit
git-subtree-split: e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4

$ git status --short
$ ls -A
.git
answer.py
ingest.py
README.md
vendor
```
<!-- /snippet -->

Mode `040000`, type tree. Two ordinary files.

**[ANIMATION]** step: msg.level-2

And the message of the squash commit, with the two trailers. That message is the whole mechanism.

**[ANIMATION]** end

Now the teammate.

```bash
git push origin main
git clone remotes/doc-qa.git ravi-doc-qa
ls ravi-doc-qa/vendor/textsplit
```

<!-- snippet: ch23/subtree/03-teammate -->
```text
$ git push origin main
To $LAB/ch23/subtree/remotes/doc-qa.git
   bf78eb9..fb692e1  main -> main
$ cd ..
$ git clone remotes/doc-qa.git ravi-doc-qa
Cloning into 'ravi-doc-qa'...
done.
$ ls ravi-doc-qa/vendor/textsplit
README.md
splitter.py
$ cd doc-qa
```
<!-- /snippet -->

A plain clone has the library. No `init`, no `update`, no second fetch, no second set of credentials. Report 1 of the hook can't happen. That's the claim from the opening, kept.

Asha has published textsplit 0.2.0.

```bash
git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git log --graph --format="%h %an: %s"
```

<!-- snippet: ch23/subtree/04-pull -->
```text
# Asha has published textsplit 0.2.0.
$ git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
Merge made by the 'ort' strategy.
 vendor/textsplit/splitter.py | 2 ++
 1 file changed, 2 insertions(+)
$ git log --graph --format="%h %an: %s"
*   7241fca Lab User: Merge commit 'c2dc1b7050d0f35c26e98632a0a8916c9f9b61e3'
|\  
| * c2dc1b7 Lab User: Squashed 'vendor/textsplit/' changes from e216665..4980f0b
* | fb692e1 Lab User: Merge commit 'c77d389e2c498a974e85fe327f712348bbe6f573' as 'vendor/textsplit'
|\| 
| * c77d389 Lab User: Squashed 'vendor/textsplit/' content from commit e216665
* bf78eb9 Lab User: Add keyword answerer
* 1d93b09 Lab User: Add document loader
```
<!-- /snippet -->

**[ANIMATION]** step: hist.state-3

"Merge made by the 'ort' strategy": an ordinary merge of a new squash commit.

```bash
git log -1 --format=%B HEAD^2
```

<!-- snippet: ch23/subtree/05-pull-message -->
```text
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/textsplit/' changes from e216665..4980f0b

4980f0b Reject an overlap that is not smaller than the chunk size

git-subtree-dir: vendor/textsplit
git-subtree-split: 4980f0b1f99fa205fd4882634ce93e661ede41fd
```
<!-- /snippet -->

The new squash commit's message lists the upstream commits it covers, `e216665..4980f0b`, and records the new split point.

A quick quiz. The same update, with `--squash` forgotten: does Git merge it anyway, or refuse? Say it out loud.

**[PAUSE]**

**[TERMINAL]** From `labs/run ch23/lab-15-2-subtree`: the same update with `--squash` forgotten. Predict.

```bash
git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main
git status --short --branch
```

<!-- snippet: ch23/lab-15-2-subtree/05-failure -->
```text
# Update the vendored copy, and forget --squash:
$ git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
fatal: refusing to merge unrelated histories
[exit status: 128]
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

It refuses: "refusing to merge unrelated histories", exit status 128. Nothing was changed. Repeat the pull with `--squash`. Better still, put the update command in a script or an alias, so that everyone uses the same options.

Back to the first replay. A change of your own that touches the library and the application in one commit.

```bash
git commit -am "Split documents by paragraph"
git show --stat --format="%h %s"
```

<!-- snippet: ch23/subtree/06-local-change -->
```text
# A change of your own that touches the library and the application in one commit:
$ git commit -am "Split documents by paragraph"
[main e3827e6] Split documents by paragraph
 2 files changed, 9 insertions(+)
$ git show --stat --format="%h %s"
e3827e6 Split documents by paragraph

 ingest.py                    | 4 ++++
 vendor/textsplit/splitter.py | 5 +++++
 2 files changed, 9 insertions(+)
```
<!-- /snippet -->

One commit, `e3827e6`, two files: `ingest.py` and the vendored `splitter.py`.

**[ANIMATION]** step: hist.state-4

Now offer the library part upstream.

`git subtree split` will build a history that contains only what happened under the prefix. Your repository was populated with squash commits, so it has none of Asha's commits in its history. Predict whose commits, and which IDs, the split branch will contain. I'll wait.

**[PAUSE]**

```bash
git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export
git log --graph --format="%h %an: %s" textsplit-export
git ls-tree --name-only textsplit-export
```

<!-- snippet: ch23/subtree/07-split -->
```text
$ git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export
ee9c8f1aeeb272a682e93f0137db86efd7c142e8
$ git log --graph --format="%h %an: %s" textsplit-export
* ee9c8f1 Lab User: Split documents by paragraph
* 4980f0b Asha Rao: Reject an overlap that is not smaller than the chunk size
* e216665 Asha Rao: Add overlap between neighbouring chunks
* ceaafe1 Asha Rao: Add fixed-size splitter
$ git ls-tree --name-only textsplit-export
README.md
splitter.py
$ git show --stat --format="%h %s" textsplit-export
ee9c8f1 Split documents by paragraph

 splitter.py | 5 +++++
 1 file changed, 5 insertions(+)
```
<!-- /snippet -->

Look at the IDs. The synthetic branch ends in `ee9c8f1`: your commit reduced to its library part. `ingest.py` is gone from it. Below it are `4980f0b`, `e216665` and `ceaafe1`: the upstream commits themselves, with their original IDs and Asha as author. If you predicted new IDs all the way down, that's the natural guess.

**[ANIMATION]** step: hist.state-5

The split found them through the `git-subtree-split` trailers. The result is a branch that upstream can merge or review as a normal contribution.

```bash
git subtree push --quiet --prefix=vendor/textsplit ../remotes/textsplit.git docqa/paragraphs
git ls-remote --heads ../remotes/textsplit.git
```

<!-- snippet: ch23/subtree/08-push -->
```text
$ git subtree push --quiet --prefix=vendor/textsplit ../remotes/textsplit.git docqa/paragraphs
git push using:  ../remotes/textsplit.git docqa/paragraphs
To ../remotes/textsplit.git
 * [new branch]      ee9c8f1aeeb272a682e93f0137db86efd7c142e8 -> docqa/paragraphs
$ git ls-remote --heads ../remotes/textsplit.git
ee9c8f1aeeb272a682e93f0137db86efd7c142e8	refs/heads/docqa/paragraphs
4980f0b1f99fa205fd4882634ce93e661ede41fd	refs/heads/main
```
<!-- /snippet -->

A new branch in the library's repository, at `ee9c8f1`. 🟡 CAUTION: `git subtree push` creates or updates a branch in the library's repository. Run `split` first and inspect the result.

**[ON SCREEN]** The state table of section 23.13.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git subtree add --squash`, `git subtree pull --squash` | Files under the prefix created or updated | updated to match | two new commits (a squash commit and a merge) | advanced | new objects; `FETCH_HEAD` | unchanged (a fetch) | unchanged |
| `git subtree split -b <branch>` | unchanged | unchanged | unchanged | unchanged | a new branch with synthetic commits | unchanged | unchanged |
| `git subtree push` | unchanged | unchanged | unchanged | unchanged | new synthetic commits | a branch created or updated in the **library's** repository | as for any push |

The state table of section 23.13, one row per command. Only `git subtree push` changes anything outside your own repository.

**[ON SCREEN]** The decision table of section 23.14. Read it row by row with the audience.

| Question | Submodule | Subtree | Package manager (pip, npm, Maven, Go modules) |
|---|---|---|---|
| What the consuming repository records | A commit ID (gitlink) and a URL in `.gitmodules` | The files themselves, plus trailers in commit messages | A name and a version, in a manifest and a lock file |
| Where the dependency's content lives | In the dependency's repository; cloned beside yours | In your repository's own objects | In a registry or artifact store; installed at build time |
| After a plain `git clone` | An empty directory | Complete | Manifest only; an install step is required |
| Updating | `update --remote`, then commit the pointer | `git subtree pull --squash` | Change the version, regenerate the lock file |
| Changing the dependency from inside the consumer | Commit in the submodule, push it, then commit the pointer: two repositories, in order | Edit and commit normally; `split` and `push` to offer it upstream | Not possible in place; publish a new version or use the tool's local-override mechanism |
| Access control and licensing separation | Kept: the dependency keeps its own repository and permissions | Lost: whoever can read your repository reads the copy | Kept, through the registry |
| Typical failure | The states of this chapter: uninitialized, stale, unpushed, detached | Lost trailers; mixed `--squash` usage; local edits that conflict on every update | Version conflicts; a registry that is unavailable; unpinned versions |
| Fits | A dependency developed in step with the consumer by people who have access to both; large or access-restricted content | A small dependency that must be present in every clone and changes rarely | Anything that is published with versions, which is most libraries |

And the decision table of section 23.14. Pause here and read it row by row.

And for the teams that do choose submodules, the configuration from section 23.16 that removes most of the failures. It's local configuration, so each clone and each CI job needs it.

```bash
git config set submodule.recurse true            # switch, pull, checkout, reset follow the gitlink
git config set push.recurseSubmodules check      # refuse to push a pointer to an unpublished commit
git config set diff.submodule log                # diffs list the library commits
git config set status.submoduleSummary true      # status shows them too
```

## COMMON MISTAKES

Five mistakes to watch for.

1. **Pulling a squashed subtree without `--squash`.** Root cause: the repository contains none of the upstream commits, so the pull tries to merge histories with no common ancestor.
2. **Squash-merging or rebasing the pull request that added or updated the subtree.** Root cause: the link to upstream is two trailers in a commit message; rewriting the commit discards or rewrites them.
3. **Vendoring a large or fast-changing dependency as a subtree.** Root cause: every version stays in your repository's history.
4. **Using a submodule for a library that is published as a package.** Root cause: you rebuild a worse package manager, without versioning, transitive dependencies or advisories.
5. **Running `update --remote` in CI for a submodule.** Root cause: the job tests a library commit that no superproject commit records, so the run cannot be reproduced; do it in a scheduled job that opens a pull request with the pointer change.

## PRODUCTION EXAMPLE

Now, out of the lab. A document-processing team has three dependencies of three kinds, and after this chapter it treats each differently.

**[ANIMATION]** step: rule.4

A tokenizer library that's published on a package index: a version in the manifest and the lock file, nothing in Git beyond that. A three-hundred-line chunking utility from an open-source project, which every CI job and every Docker build must have after a plain clone and which changes twice a year: a subtree, added with `--squash`, updated through one script so that the options never vary, in pull requests that are merged with a merge commit so the trailers survive. And a repository of protocol definitions shared with seven other services, with its own access rules and release cadence: a submodule, with the four configuration lines in the setup script that every clone and every CI job runs.

The decision record for each has one sentence that begins "after a plain clone".

## PRACTICE EXERCISE

Your turn. Do Lab 15.2, "The same dependency as a subtree", in [`lab-manual/m15-submodules-subtrees-lfs.md`](../../lab-manual/m15-submodules-subtrees-lfs.md).

Before `git subtree add`, predict the number of new commits, the mode of the tree entry at the prefix, and what a fresh clone contains. Before the split, predict which commit IDs on the exported branch will equal IDs in the upstream repository. The lab's failure scenario is the missing `--squash`. Predict the message.

The challenge is Exercise 15.5, Level 2, draw the graph, "Two subtree operations", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q454: "Submodule, subtree, package manager: decide for (a) an internal protocol-definition repository used by eight services, (b) a 300-line utility copied from an open-source project, (c) a tokenizer library published on a package index."

**[PAUSE]**

Answer out loud. Decide each case before you justify it.

A strong answer applies the same few questions to all three and doesn't start from a favourite tool: is it published as a package, must it be present after a plain clone, must it stay a separate repository with its own access and cadence, who changes it and how often. For each case it gives the choice, the deciding property, and the typical failure the team is accepting with that choice, together with the setting or practice that contains it. It may also say when the honest answer is a fourth option.

## RECAP

**[ANIMATION]** step: hist.state-5

Let's land this. Here is `doc-qa` one more time: two squash merges on `main`, and an exported branch that carries the upstream IDs. And you can now answer the CTO's second question.

You should now be able to say:

- A subtree is the dependency's files as ordinary blobs under a prefix in my own history; a plain clone has them.
- The link to upstream is two trailers in a commit message, so rewriting those commits breaks later updates.
- `git subtree pull --squash` is an ordinary merge, and `--squash` must be used consistently.
- `git subtree split` rebuilds the prefix's history and, through the trailers, reproduces the upstream commit IDs.
- Published as a package: the package manager. Must be present after a plain clone: a subtree. Must stay a separate repository: a submodule with the recommended configuration.

## HOMEWORK

Read sections 23.13 to 23.17 of [Chapter 23](../../textbook/ch23-submodules.md) and do the Practice section, 23.19. Do Exercise 15.3, Level 1, "The same library as a subtree", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you solved one problem two ways and learned how to choose. If the decision table felt dense, that's normal: practise by running one dependency of your own through it. Next time: Git LFS, why it exists, and the pointer file. Until then, look at the state first and type second. See you in the next one.

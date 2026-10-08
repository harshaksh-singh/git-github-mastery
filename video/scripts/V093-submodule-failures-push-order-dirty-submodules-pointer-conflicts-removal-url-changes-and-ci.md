# V093: Submodule failures: push order, dirty submodules, pointer conflicts, removal, URL changes, and CI

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS
- **Planned minutes.** 28
- **Prerequisites.** V092
- **Textbook sections.** [Chapter 23](../../textbook/ch23-submodules.md), sections 23.8 to 23.12
- **Demo scripts.** `labs/ch23/submodule-push-order.sh`, `labs/ch23/submodule-dirty.sh`, `labs/ch23/submodule-switch.sh`, `labs/ch23/submodule-conflict.sh`, `labs/ch23/submodule-remove.sh`, `labs/ch23/submodule-url.sh`

## HOOK

**[ON SCREEN]** `fatal: remote error: upload-pack: not our ref 17d78577459b6c2e681d54d4cfac2b350aaf7b2c`

"`git pull` worked for everyone yesterday. Today it dies with `not our ref`."

**[ANIMATION]** remotes: id=order [doc-qa: the author's clone] 907dbd3-ee30f63 main; 907dbd3 origin/main; HEAD=main; sub:ee30f63:records_17d7857 || [textsplit.git: shared] e216665 main; HEAD=none || [vendor/textsplit: the author's clone] e216665-17d7857 main; e216665 origin/main; HEAD=main => [doc-qa: the author's clone] 907dbd3-ee30f63 main origin/main; HEAD=main; sub:ee30f63:records_17d7857; name:push; cmd:git_push_origin_main; say:The_server_accepts_it:_a_gitlink_is_only_an_ID || [textsplit.git: shared] e216665 main; HEAD=none; note:e216665:17d7857_is_not_here || => || [textsplit.git: shared] e216665-17d7857 main; HEAD=none; name:fix; cmd:git_-C_vendor/textsplit_push_origin_main; say:The_library_commit_reaches_the_shared_repository || [vendor/textsplit: the author's clone] e216665-17d7857 main origin/main; HEAD=main title=The_recorded_commit_and_the_shared_repository

**[ANIMATION]** step: order.push

It dies for everyone except one person. That person improved the shared library from inside the service, committed in both repositories, and pushed the service. The push was accepted. Nothing warned them. And the service on the server now records a library commit that exists in exactly one place in the world: under `.git/modules` on that person's laptop.

If the laptop goes on holiday before anyone works out what happened, the whole team is blocked, and so is CI. Keep that laptop in mind.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A quick reminder first. A submodule is another repository checked out inside yours. The superproject is the repository that contains it, and a gitlink is the entry that records the one commit it expects. Two videos ago you learned what a superproject records about a submodule. In the last one you watched the recorded commit and the checked-out commit drift apart on a teammate's machine. Today you add the third value: the commits that exist in the submodule's shared repository. And you go through the remaining standard failures, one after another, each with its diagnosis, fix and prevention.

**[ANIMATION]** cards: id=six cards=The_push_order|A_dirty_submodule|A_commit_without_the_submodule|Two_pointers_in_conflict|Removal|A_changed_URL numbered=on title=Six_standard_failures

There are six: the push order, a dirty submodule, switching to a commit without the submodule, a conflict between two pointers, removal, and a changed URL. The video ends with what all of this means for a CI job, where nobody is there to read `git status`.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- diagnose `not our ref` and prevent it with a push guard;
- handle a dirty submodule when switching branches;
- resolve a conflict between two recorded pointers, and say when Git resolves it alone;
- remove a submodule completely, re-add one, and propagate a changed URL to existing clones;
- state what a CI checkout needs for submodules, as the section gives it.

## CONCEPT

**Push order.** A gitlink is only an ID, and the server doesn't check it. So pushing the superproject alone is accepted even when the library commit it names hasn't been pushed. Git has a guard for this, and it's off by default. 🟢 SAFE: `git push --recurse-submodules=check` verifies, before anything is sent, that every submodule commit named by the commits being pushed is reachable from a remote-tracking branch of that submodule. `--recurse-submodules=on-demand` goes one step further and pushes the submodules first. `push.recurseSubmodules=check` is the setting to put in every developer's configuration for a repository with submodules.

Its limits: `check` trusts your remote-tracking branches, so it's satisfied by a commit that sits on a library branch you pushed and that someone later deletes. And `on-demand` needs push permission on the library, which consumers often don't have. In that case the library change goes through the library's own review first, and the superproject bumps the pointer afterwards.

**[ANIMATION]** stores: id=dirty boxes=the_superproject:its_gitlink|the_submodule:HEAD|the_submodule:working_tree rows=1:A:names_one_commit|1:B:that_commit|1:C:uncommitted_changes@bad|2:B:a_new_commit,_on_a_branch@ok|3:A:the_new_commit_ID,_staged@ok title=A_gitlink_can_only_name_a_commit

**[ANIMATION]** step: dirty.3

**Dirty submodules.** A submodule's working tree can have uncommitted changes of its own. The superproject reports them and can't record them: a gitlink can only name a commit. The work has to be committed inside the submodule first, on a branch, and then the new commit ID can be staged in the superproject.

**[ANIMATION]** end

**Switching to a commit without the submodule** leaves its directory behind, because Git won't delete a directory that contains a repository's working tree. With recursion, the checkout removes and restores the submodule's working tree together with the superproject's files. The repository itself stays in `.git/modules/` either way.

**[ANIMATION]** graph: id=lib ceaafe1-e216665-de689e2 origin/main v0.2.0; e216665-cd2a8a4 origin/feature/tokens; e216665 main; ceaafe1 v0.1.0; HEAD=cd2a8a4 => ceaafe1-e216665-de689e2-5a1935a origin/main; e216665-cd2a8a4 origin/feature/tokens; cd2a8a4-5a1935a; de689e2 v0.2.0; e216665 main; ceaafe1 v0.1.0; HEAD=cd2a8a4 title=Two_library_commits_that_diverged settle=on

**[ANIMATION]** step: lib.state-1

**Pointer conflicts.** Two branches of the superproject move the gitlink. What a merge does depends on how the two library commits relate, and Git can look that up only in the submodule's repository. If one is an ancestor of the other, Git resolves the pointer by itself and takes the descendant. If they have diverged, as these two have, the superproject can't produce the answer.

**[ANIMATION]** step: lib.state-2

The correct pointer is a library commit that contains both lines of development, and only the library can create it.

**Removal.** There are two different "removals". 🟡 CAUTION: `git submodule deinit <path>` is local. It empties the working directory and removes the section from your `.git/config`, and `git submodule update --init` undoes it. 🟡 CAUTION: `git rm <path>` removes the submodule from the project. It deletes the gitlink and the section in `.gitmodules`, and you commit that.

**[ANIMATION]** walk: id=rm columns=piece,git_submodule_deinit,git_rm rows=the_section_in_.git/config:removed:stays|the_gitlink:stays:deleted|the_section_in_.gitmodules:stays:deleted|the_repository_in_.git/modules/:stays:stays marks=1.3:hl,4.3:hl title=Two_different_removals

**[ANIMATION]** step: rm.4

Three leftovers remain: a possibly empty `.gitmodules`, the section in `.git/config`, and the repository under `.git/modules/`. Git keeps the repository on purpose, so that old commits which still contain the gitlink can be checked out without a new clone.

**[ANIMATION]** stores: id=url boxes=.gitmodules:versioned|your_.git/config:local|a_teammate's_.git/config:local rows=1:A:the_new_URL@hl|1:B:the_new_URL@ok|2:C:the_URL_that_init_copied@bad arrows=1:A1>B1:set-url title=A_changed_URL

**[ANIMATION]** step: url.2

**A changed URL.** `git submodule set-url` edits `.gitmodules` and synchronizes your own configuration. A teammate's configuration still has the URL that `init` copied months ago.

**[ANIMATION]** end

🟢 SAFE: `git submodule sync` copies the URLs from `.gitmodules` into `.git/config` and into the `origin` remote of each initialized submodule.

**CI.** A CI job is a fresh clone made by a script, so every default of this chapter applies to it.

When not to use submodules at all is the question of the next video. For today: every failure here is a disagreement between two of three values, and every fix makes them agree again.

## MENTAL MODEL

The three values, once more. What your book cites. What page the reader's copy is open at. What the bookshop's edition contains.

**[ANIMATION]** say: Your book cites a page that was never printed

Last time, the first two disagreed. Today's headline failure is the first and third: your book cites a page that was never printed. It exists only in the author's manuscript. Every reader who follows the citation is told by the bookshop: we don't have that.

**[ANIMATION]** step: lib.state-2

A pointer conflict is two editions of your book citing two different pages. If one page is a later revision of the other, the choice is obvious. If the two pages were revised independently, somebody has to write a page that combines them, and that somebody works at the other publisher.

**[ANIMATION]** end

Where the analogy stops being useful: a dirty submodule. Scribbles in the reader's copy can't be cited at all. Only printed pages have numbers.

## DIAGRAM

**[DIAGRAM]** A table of failures: symptom, the value that disagrees, fix, prevention. Reveal one row as each demonstration ends.

```text
  symptom                              what disagrees                          fix                               prevention
  -----------------------------------  --------------------------------------  --------------------------------  --------------------------------------
  pull fails: "not our ref"            recorded ID  vs  commits on the         author pushes the library commit  push.recurseSubmodules=check
                                       library's shared repository
  "modified content" in status,        submodule working tree  vs  its own     commit inside the submodule on    work on a branch in the submodule
  commit -a records nothing            HEAD (the gitlink can name only a       a branch, then stage the new ID
                                       commit)
  stray untracked vendor/ directory    superproject commit has no gitlink;     switch back, or switch with       submodule.recurse=true
  after switching to an old commit     the directory is still on disk          --recurse-submodules
  UU on the submodule path in a merge  two recorded IDs that have diverged     check out a library commit that   bump pointers in small, single-purpose
                                       in the library                          contains both, git add, commit    pull requests
  re-add refused: "A git directory     .git/modules/<name> left after git rm   delete the leftovers, then add    know the three leftovers
  ... is found locally"
  fetch from the old location          .git/config URL  vs  .gitmodules URL    git submodule sync                announce URL changes with the command
```

Every row names two things that should agree. That's the diagnosis method for submodules: find the two values, print both, compare.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch23/submodule-push-order`. The textbook marks this demo as volatile: when the remote is a directory, two processes report the same refusal and their lines can appear in either order.

You improve the library from inside the service, on the submodule's `main`, as the last video advised.

<!-- snippet: ch23/submodule-push-order/01-local-library-commit -->
```text
$ cd vendor/textsplit
$ git switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
$ git commit -am "Add line splitter"
[main 17d7857] Add line splitter
 1 file changed, 5 insertions(+)
$ cd ../..
$ git status --short
 M vendor/textsplit
$ git commit -am "Use the line splitter from textsplit"
[main ee30f63] Use the line splitter from textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

There are now two unpushed commits in two repositories: `17d7857` in the library, and a commit in the superproject whose tree names it. With the guard, the push is refused before anything is sent.

```bash
git push --recurse-submodules=check origin main
```

<!-- snippet: ch23/submodule-push-order/02-guard -->
```text
$ git push --recurse-submodules=check origin main
The following submodule paths contain changes that can
not be found on any remote:
  vendor/textsplit

Please try

	git push --recurse-submodules=on-demand

or cd to the path and use

	git push

to push them to a remote.

fatal: Aborting.
fatal: the remote end hung up unexpectedly
[exit status: 128]
```
<!-- /snippet -->

"The following submodule paths contain changes that can not be found on any remote." Now without the guard. Predict: does the server accept a superproject commit that names an unpushed library commit? Say it out loud. I'll wait.

**[PAUSE]**

**[ON SCREEN]** 🟡 CAUTION: `git push` moves a ref on the remote. Predict: does the server accept a superproject commit that names an unpushed library commit?

```bash
git push origin main
```

<!-- snippet: ch23/submodule-push-order/03-mistake -->
```text
# Without the guard, the push of the superproject succeeds:
$ git push origin main
To $LAB/ch23/submodule-push-order/remotes/doc-qa.git
   907dbd3..ee30f63  main -> main
```
<!-- /snippet -->

Accepted. The server doesn't check a gitlink. Ravi pulls.

```bash
git pull
```

<!-- snippet: ch23/submodule-push-order/04-teammate -->
```text
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/submodule-push-order/remotes/doc-qa
   907dbd3..ee30f63  main       -> origin/main
Fetching submodule vendor/textsplit
fatal: git upload-pack: not our ref 17d78577459b6c2e681d54d4cfac2b350aaf7b2c
fatal: remote error: upload-pack: not our ref 17d78577459b6c2e681d54d4cfac2b350aaf7b2c
Errors during submodule fetch:
	vendor/textsplit
[exit status: 1]
```
<!-- /snippet -->

"not our ref" and the full ID. Note what state the failure left: the fetch of the superproject succeeded, and the merge didn't run. Now the diagnosis. Try it now, on paper, thirty seconds: write down the questions you would ask to find the missing commit. I'll wait.

**[PAUSE]**

```bash
git status --short --branch
git ls-tree origin/main vendor/
git ls-remote ../remotes/textsplit.git
```

<!-- snippet: ch23/submodule-push-order/05-diagnose -->
```text
$ git status --short --branch
## main...origin/main [behind 1]
$ git ls-tree origin/main vendor/
160000 commit 17d78577459b6c2e681d54d4cfac2b350aaf7b2c	vendor/textsplit
$ git ls-remote ../remotes/textsplit.git
e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	HEAD
e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	refs/heads/main
f8fdba471fcee4fa0c9a10d59be41c10c86f79ec	refs/tags/v0.1.0
ceaafe1cb2284284c7aa91a8ac843268d1dad25e	refs/tags/v0.1.0^{}
```
<!-- /snippet -->

Three questions. Which library commit does the superproject want? `git ls-tree origin/main vendor/` says `17d7857`. Does the library's shared repository have it? `git ls-remote` shows `main` still at `e216665`, and no ref leads to the wanted commit.

```bash
git -C vendor/textsplit cat-file -t 17d7857
git -C ../doc-qa/vendor/textsplit branch --all --contains 17d7857
```

<!-- snippet: ch23/submodule-push-order/05b-not-here -->
```text
$ git -C vendor/textsplit cat-file -t 17d7857
fatal: Not a valid object name 17d7857
[exit status: 128]
$ git -C ../doc-qa/vendor/textsplit branch --all --contains 17d7857
* main
```
<!-- /snippet -->

Who has it? Not Ravi's clone. The author of the superproject commit, on a local branch. That's the laptop from the opening. So the fix is on the author's side.

```bash
git -C vendor/textsplit push origin main
cd ../ravi-doc-qa
git pull
```

<!-- snippet: ch23/submodule-push-order/06-fix -->
```text
$ cd ../doc-qa
$ git -C vendor/textsplit push origin main
To $LAB/ch23/submodule-push-order/remotes/textsplit.git
   e216665..17d7857  main -> main
$ cd ../ravi-doc-qa
$ git pull
Updating 907dbd3..ee30f63
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git -c protocol.file.allow=always submodule update
From $LAB/ch23/submodule-push-order/remotes/textsplit
   e216665..17d7857  main       -> origin/main
Submodule path 'vendor/textsplit': checked out '17d78577459b6c2e681d54d4cfac2b350aaf7b2c'
$ git submodule status
 17d78577459b6c2e681d54d4cfac2b350aaf7b2c vendor/textsplit (v0.1.0-2-g17d7857)
```
<!-- /snippet -->

**[ANIMATION]** step: order.fix

The library commit is pushed, and the teammate's pull works.

**[ANIMATION]** end

With `on-demand`, Git pushes the submodule first:

<!-- snippet: ch23/submodule-push-order/07-on-demand -->
```text
$ cd ../doc-qa
$ git -C vendor/textsplit commit -am "Add sentence splitter"
[main 0dd831a] Add sentence splitter
 1 file changed, 4 insertions(+)
$ git commit -am "Use the sentence splitter from textsplit"
[main 9b2d81f] Use the sentence splitter from textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push --recurse-submodules=on-demand origin main
Pushing submodule 'vendor/textsplit'
To $LAB/ch23/submodule-push-order/remotes/textsplit.git
   17d7857..0dd831a  main -> main
To $LAB/ch23/submodule-push-order/remotes/doc-qa.git
   ee30f63..9b2d81f  main -> main
```
<!-- /snippet -->

And the setting for every developer's configuration:

```bash
git config set push.recurseSubmodules check
git config get push.recurseSubmodules
```

<!-- snippet: ch23/submodule-push-order/08-config -->
```text
$ git config set push.recurseSubmodules check
$ git config get push.recurseSubmodules
check
```
<!-- /snippet -->

**[TERMINAL]** Replay `labs/run ch23/submodule-dirty`. An edited file and an untracked file inside the submodule.

```bash
git status
```

<!-- snippet: ch23/submodule-dirty/01-dirty -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)
	modified:   vendor/textsplit (modified content, untracked content)

no changes added to commit (use "git add" and/or "git commit -a")
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->

"modified content, untracked content" means: the submodule's HEAD is the recorded commit and its working tree isn't clean. `git submodule status` therefore shows no plus sign.

```bash
git diff
git diff --submodule=diff
```

<!-- snippet: ch23/submodule-dirty/02-diff -->
```text
$ git diff
diff --git a/vendor/textsplit b/vendor/textsplit
--- a/vendor/textsplit
+++ b/vendor/textsplit
@@ -1 +1 @@
-Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
+Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4-dirty
$ git diff --submodule=diff
Submodule vendor/textsplit contains modified content
diff --git a/vendor/textsplit/splitter.py b/vendor/textsplit/splitter.py
index c0dea76..6f4648f 100644
--- a/vendor/textsplit/splitter.py
+++ b/vendor/textsplit/splitter.py
@@ -2,3 +2,4 @@ def split(text, size=200, overlap=0):
     """Cut text into pieces of at most `size` characters; neighbours share `overlap` characters."""
     step = size - overlap
     return [text[i:i + size] for i in range(0, len(text), step)]
+# debug: print every chunk
```
<!-- /snippet -->

The diff appends `-dirty` to the ID. Predict what `git commit -am` does with it. I'll wait.

**[PAUSE]**

```bash
git commit -am "Save my work"
```

<!-- snippet: ch23/submodule-dirty/03-commit-a -->
```text
$ git commit -am "Save my work"
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)
	modified:   vendor/textsplit (modified content, untracked content)

no changes added to commit (use "git add" and/or "git commit -a")
[exit status: 1]
```
<!-- /snippet -->

Nothing to commit. If you expected a commit, that's a fair guess, but there's nothing for the superproject to stage. To look into all submodules at once:

```bash
git submodule foreach "git status --short"
git status --short
git status --short --ignore-submodules=untracked
```

<!-- snippet: ch23/submodule-dirty/04-foreach -->
```text
$ git submodule foreach "git status --short"
Entering 'vendor/textsplit'
 M splitter.py
?? notes.txt
$ git status --short
 m vendor/textsplit
$ git status --short --ignore-submodules=untracked
 m vendor/textsplit
$ git status --short --ignore-submodules=dirty
```
<!-- /snippet -->

The lower-case `m` in short status is the superproject's marker for modified content inside a submodule.

**[ON SCREEN]** 🔴 DANGEROUS: `git submodule update --force`. What it changes: it checks the submodule's files out again at the recorded commit. What it can destroy: edits to tracked files inside the submodule. Preview: `git submodule foreach "git status --short"`. Recovery: none for uncommitted edits. Appropriate: when you have looked and want exactly the recorded state. Untracked files need `git clean` inside the submodule, previewed with `-n`.

```bash
git submodule update
git status --short
git submodule update --force
git status --short
```

<!-- snippet: ch23/submodule-dirty/05-discard -->
```text
# update does nothing: the checked-out commit already is the recorded one.
$ git submodule update
$ git status --short
 m vendor/textsplit
# --force checks the files out again, which discards the edit to the tracked file:
$ git submodule update --force
Submodule path 'vendor/textsplit': checked out 'e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4'
$ git status --short
 ? vendor/textsplit
$ git -C vendor/textsplit clean -n
Would remove notes.txt
$ git -C vendor/textsplit clean -f
Removing notes.txt
$ git status --short
```
<!-- /snippet -->

Plain `update` does nothing: the checked-out commit already is the recorded one. `--force` discards the edit to the tracked file.

**[TERMINAL]** Replay `labs/run ch23/submodule-switch`. Switch to a commit from before the submodule existed.

```bash
git log --oneline
git switch --detach HEAD~1
git status
```

<!-- snippet: ch23/submodule-switch/01-stray-directory -->
```text
$ git log --oneline
907dbd3 Vendor textsplit as a submodule and chunk documents
bf78eb9 Add keyword answerer
1d93b09 Add document loader
$ git switch --detach HEAD~1
warning: unable to rmdir 'vendor/textsplit': Directory not empty
HEAD is now at bf78eb9 Add keyword answerer
$ git status
HEAD detached at bf78eb9
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	vendor/

nothing added to commit but untracked files present (use "git add" to track)
$ ls -A vendor/textsplit
.git
README.md
splitter.py
```
<!-- /snippet -->

"unable to rmdir 'vendor/textsplit': Directory not empty". The stray `vendor/` is untracked on that commit. A careless `git add -A` there would stage it as a new gitlink. With recursion:

```bash
git switch --recurse-submodules --detach HEAD~1
git status --short
ls vendor 2>&1
git switch --recurse-submodules main
```

<!-- snippet: ch23/submodule-switch/03-recurse -->
```text
$ git switch --recurse-submodules --detach HEAD~1
HEAD is now at bf78eb9 Add keyword answerer
$ git status --short
$ ls vendor 2>&1
ls: vendor: No such file or directory
$ git switch --recurse-submodules main
Previous HEAD position was bf78eb9 Add keyword answerer
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->

The directory is removed and restored together with the superproject's files.

**[TERMINAL]** Replay `labs/run ch23/submodule-conflict`. Two branches of `doc-qa` move the gitlink.

```bash
git log --graph --oneline --decorate --all
git ls-tree use-release vendor/
git ls-tree use-tokens vendor/
```

<!-- snippet: ch23/submodule-conflict/01-two-pointers -->
```text
$ git log --graph --oneline --decorate --all
* 7a1b409 (HEAD -> use-tokens) Use the token splitter of textsplit
| * e5a77ed (use-release) Use textsplit 0.2.0
|/  
* 907dbd3 (origin/main, main) Vendor textsplit as a submodule and chunk documents
* bf78eb9 Add keyword answerer
* 1d93b09 Add document loader
$ git ls-tree use-release vendor/
160000 commit de689e20c2a64f6ebe2a0f3ec7c98efc09459cb9	vendor/textsplit
$ git ls-tree use-tokens vendor/
160000 commit cd2a8a45f5da8ab7bfedfe413228a50b91874c72	vendor/textsplit
$ git -C vendor/textsplit log --graph --oneline --decorate v0.2.0 origin/feature/tokens
* de689e2 (tag: v0.2.0, origin/main, origin/HEAD) Reject an overlap that is not smaller than the chunk size
| * cd2a8a4 (HEAD, origin/feature/tokens) Add token splitter
|/  
* e216665 (main) Add overlap between neighbouring chunks
* ceaafe1 (tag: v0.1.0) Add fixed-size splitter
```
<!-- /snippet -->

`use-release` records the 0.2.0 release. `use-tokens` records a feature branch of the library. The two library commits have diverged.

```bash
git merge use-release
```

<!-- snippet: ch23/submodule-conflict/02-conflict -->
```text
$ git merge use-release
hint: Recursive merging with submodules currently only supports trivial cases.
hint: Please manually handle the merging of each conflicted submodule.
hint: This can be accomplished with the following steps:
hint:  - go to submodule (vendor/textsplit), and either merge commit de689e2
hint:    or update to an existing commit which has merged those changes
hint:  - come back to superproject and run:
hint:
hint:       git add vendor/textsplit
hint:
hint:    to record the above merge or update
hint:  - resolve any other conflicts in the superproject
hint:  - commit the resulting index in the superproject
hint:
hint: Disable this message with "git config set advice.submoduleMergeConflict false"
Failed to merge submodule vendor/textsplit
CONFLICT (submodule): Merge conflict in vendor/textsplit
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->

Git's hint says it: recursive merging with submodules supports only trivial cases.

```bash
git status --short
git ls-files --unmerged
git submodule status
```

<!-- snippet: ch23/submodule-conflict/03-stages -->
```text
$ git status --short
UU vendor/textsplit
$ git ls-files --unmerged
160000 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 1	vendor/textsplit
160000 cd2a8a45f5da8ab7bfedfe413228a50b91874c72 2	vendor/textsplit
160000 de689e20c2a64f6ebe2a0f3ec7c98efc09459cb9 3	vendor/textsplit
$ git submodule status
U0000000000000000000000000000000000000000 vendor/textsplit
$ git diff
diff --cc vendor/textsplit
index cd2a8a4,de689e2..0000000
--- a/vendor/textsplit
+++ b/vendor/textsplit
```
<!-- /snippet -->

`UU` on the path, and three stages in the index, each a gitlink: stage 1 the merge base's pointer, stage 2 ours, stage 3 theirs. There are no conflict markers, because there's no file to put them in. `git submodule status` prints a `U` and zeros.

**[ANIMATION]** graph: id=ptr ceaafe1-e216665-de689e2 origin/main v0.2.0; e216665-cd2a8a4 origin/feature/tokens; e216665 main; ceaafe1 v0.1.0; HEAD=cd2a8a4; role:e216665:base; role:cd2a8a4:ours; role:de689e2:theirs; say:Three_stages,_each_a_gitlink => ceaafe1-e216665-de689e2-5a1935a origin/main; e216665-cd2a8a4 origin/feature/tokens; cd2a8a4-5a1935a; de689e2 v0.2.0; e216665 main; ceaafe1 v0.1.0; HEAD=none; sub:de689e2:use-release; sub:5a1935a:use-merged; name:merged; say:de689e2_is_an_ancestor_of_5a1935a:_Git_takes_the_descendant title=The_library,_inside_the_submodule

**[ANIMATION]** step: ptr.state-1

The hint lists two ways. Merge inside the submodule yourself, which creates a merge commit that exists only in your clone and must be pushed to the library before anyone else can use it. Or wait for the library to merge, and then point at the result. The demonstration does the second.

```bash
git -C vendor/textsplit fetch origin
git -C vendor/textsplit log --graph --oneline --decorate -4 origin/main
```

<!-- snippet: ch23/submodule-conflict/04-library-merges -->
```text
$ git -C vendor/textsplit fetch origin
From $LAB/ch23/submodule-conflict/remotes/textsplit
   de689e2..5a1935a  main       -> origin/main
$ git -C vendor/textsplit log --graph --oneline --decorate -4 origin/main
*   5a1935a (origin/main, origin/HEAD) Merge feature/tokens
|\  
| * cd2a8a4 (HEAD, origin/feature/tokens) Add token splitter
* | de689e2 (tag: v0.2.0) Reject an overlap that is not smaller than the chunk size
|/  
* e216665 (main) Add overlap between neighbouring chunks
```
<!-- /snippet -->

The library's `main` now has a merge, `5a1935a`, that contains both.

```bash
git -C vendor/textsplit checkout --quiet origin/main
git add vendor/textsplit
git status --short
git commit --no-edit
git ls-tree HEAD vendor/
```

<!-- snippet: ch23/submodule-conflict/05-resolve -->
```text
$ git -C vendor/textsplit checkout --quiet origin/main
$ git add vendor/textsplit
$ git status --short
M  vendor/textsplit
$ git commit --no-edit
[use-tokens c927444] Merge branch 'use-release' into use-tokens
$ git ls-tree HEAD vendor/
160000 commit 5a1935ae4e615fa75f14284cab1eb1906c8cdf33	vendor/textsplit
$ git submodule status
 5a1935ae4e615fa75f14284cab1eb1906c8cdf33 vendor/textsplit (v0.2.0-2-g5a1935a)
```
<!-- /snippet -->

`git add` on the path stages whatever commit the submodule has checked out, which resolves the path. `git commit` concludes the merge. And the case Git resolves alone:

<!-- snippet: ch23/submodule-conflict/06-ancestor-case -->
```text
# A new branch from main that records the library merge commit. use-release records v0.2.0,
# an ancestor of that merge. Both branches moved the pointer away from the one main has.
$ git ls-tree main vendor/
160000 commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	vendor/textsplit
$ git ls-tree use-merged vendor/
160000 commit 5a1935ae4e615fa75f14284cab1eb1906c8cdf33	vendor/textsplit
$ git ls-tree use-release vendor/
160000 commit de689e20c2a64f6ebe2a0f3ec7c98efc09459cb9	vendor/textsplit
$ git merge use-release
Note: Fast-forwarding submodule vendor/textsplit to 5a1935ae4e615fa75f14284cab1eb1906c8cdf33
Merge made by the 'ort' strategy.
[exit status: 0]
$ git ls-tree HEAD vendor/
160000 commit 5a1935ae4e615fa75f14284cab1eb1906c8cdf33	vendor/textsplit
```
<!-- /snippet -->

When one of the two library commits is an ancestor of the other, Git takes the descendant and says so in one line.

**[ANIMATION]** step: ptr.merged

That needs both commits to be present in the submodule's local repository. The textbook reports, from runs without a printed transcript, that in a clone where the submodule isn't checked out the merge reports a conflict instead, and that `-X theirs` doesn't help.

**[TERMINAL]** Replay `labs/run ch23/submodule-remove`.

```bash
git submodule deinit vendor/textsplit
git submodule status
```

<!-- snippet: ch23/submodule-remove/01-deinit -->
```text
$ git submodule deinit vendor/textsplit
Cleared directory 'vendor/textsplit'
Submodule 'vendor/textsplit' (../textsplit.git) unregistered for path 'vendor/textsplit'
$ git submodule status
-e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit
$ ls -A vendor/textsplit
$ git status --short
$ git config list --local | grep ^submodule
$ ls .git/modules/vendor
textsplit
```
<!-- /snippet -->

Local only: the directory is cleared, the status prefix is a minus, and the history is untouched. Now the removal from the project.

```bash
git rm vendor/textsplit
git status
```

<!-- snippet: ch23/submodule-remove/03-rm -->
```text
$ git rm vendor/textsplit
rm 'vendor/textsplit'
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   .gitmodules
	deleted:    vendor/textsplit

$ git diff --cached
diff --git a/.gitmodules b/.gitmodules
index 9f740c3..e69de29 100644
--- a/.gitmodules
+++ b/.gitmodules
@@ -1,3 +0,0 @@
-[submodule "vendor/textsplit"]
-	path = vendor/textsplit
-	url = ../textsplit.git
diff --git a/vendor/textsplit b/vendor/textsplit
deleted file mode 160000
index e216665..0000000
--- a/vendor/textsplit
+++ /dev/null
@@ -1 +0,0 @@
-Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
```
<!-- /snippet -->

```bash
git commit -m "Stop vendoring textsplit"
ls -A
```

<!-- snippet: ch23/submodule-remove/04-commit -->
```text
$ git commit -m "Stop vendoring textsplit"
[main 4adef58] Stop vendoring textsplit
 2 files changed, 4 deletions(-)
 delete mode 160000 vendor/textsplit
$ ls -A
.git
.gitmodules
answer.py
ingest.py
README.md
vendor
```
<!-- /snippet -->

"delete mode 160000". Look at the listing: `.gitmodules` is still there. And two more leftovers on your disk:

```bash
git config list --local | grep ^submodule
ls .git/modules/vendor
```

<!-- snippet: ch23/submodule-remove/05-leftovers -->
```text
$ git config list --local | grep ^submodule
submodule.vendor/textsplit.active=true
submodule.vendor/textsplit.url=$LAB/ch23/submodule-remove/remotes/textsplit.git
$ ls .git/modules/vendor
textsplit
```
<!-- /snippet -->

A quick quiz. Someone adds a submodule under the same name again. Does Git accept it, or refuse it? Say it out loud.

**[PAUSE]**

```bash
git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
```

<!-- snippet: ch23/submodule-remove/06-readd-refused -->
```text
$ git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
fatal: A git directory for 'vendor/textsplit' is found locally with remote(s):
  origin	$LAB/ch23/submodule-remove/remotes/textsplit.git
If you want to reuse this local git directory instead of cloning again from
  $LAB/ch23/submodule-remove/remotes/textsplit.git
use the '--force' option. If the local git directory is not the correct repo
or you are unsure what this means choose another name with the '--name' option.
[exit status: 128]
```
<!-- /snippet -->

Refused: "A git directory for 'vendor/textsplit' is found locally". To remove a submodule completely from your clone, delete the leftovers.

**[ON SCREEN]** 🔴 DANGEROUS: `rm -rf .git/modules/<name>`. What it changes: it deletes the submodule's repository from your clone. What it can destroy: every unpushed commit, stash and reflog of that submodule. Preview: inside the submodule's repository, check for commits that no remote has. Recovery: none. Appropriate: when the submodule is removed for good and nothing in it is unpushed.

```bash
rm -rf .git/modules/vendor/textsplit
git config remove-section submodule.vendor/textsplit
git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
git status --short
```

<!-- snippet: ch23/submodule-remove/07-complete-removal -->
```text
$ rm -rf .git/modules/vendor/textsplit
$ git config remove-section submodule.vendor/textsplit
$ git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
Cloning into '$LAB/ch23/submodule-remove/doc-qa/vendor/textsplit'...
done.
$ git status --short
M  .gitmodules
A  vendor/textsplit
```
<!-- /snippet -->

History isn't rewritten by any of this. A checkout of a commit from before the removal has the gitlink again, and the directory is empty until the next `git submodule update --init`.

**[TERMINAL]** Replay `labs/run ch23/submodule-url`. The library's repository has moved.

```bash
git submodule set-url vendor/textsplit ../chunking.git
git diff
```

<!-- snippet: ch23/submodule-url/01-set-url -->
```text
$ git submodule set-url vendor/textsplit ../chunking.git
Synchronizing submodule url for 'vendor/textsplit'
$ git diff
diff --git a/.gitmodules b/.gitmodules
index 9f740c3..7902bc0 100644
--- a/.gitmodules
+++ b/.gitmodules
@@ -1,3 +1,3 @@
 [submodule "vendor/textsplit"]
 	path = vendor/textsplit
-	url = ../textsplit.git
+	url = ../chunking.git
$ git config get submodule.vendor/textsplit.url
$LAB/ch23/submodule-url/remotes/chunking.git
$ git -c protocol.file.allow=always submodule update --remote
From $LAB/ch23/submodule-url/remotes/chunking
   e216665..4f00a5b  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Submodule path 'vendor/textsplit': checked out '4f00a5b8bb1f8ba700d273d9ec2f453be23efc75'
$ git commit -am "textsplit moved to chunking.git; update to 0.2.0"
[main 109e5d9] textsplit moved to chunking.git; update to 0.2.0
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git push --recurse-submodules=check origin main
To $LAB/ch23/submodule-url/remotes/doc-qa.git
   907dbd3..109e5d9  main -> main
```
<!-- /snippet -->

One line of `.gitmodules` changes, and your own configuration is synchronized. Ravi pulls.

<!-- snippet: ch23/submodule-url/02-teammate-stale-url -->
```text
$ cd ../ravi-doc-qa
$ git pull --no-recurse-submodules
From $LAB/ch23/submodule-url/remotes/doc-qa
   907dbd3..109e5d9  main       -> origin/main
Updating 907dbd3..109e5d9
Fast-forward
 .gitmodules      | 2 +-
 vendor/textsplit | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ cat .gitmodules
[submodule "vendor/textsplit"]
	path = vendor/textsplit
	url = ../chunking.git
$ git config get submodule.vendor/textsplit.url
$LAB/ch23/submodule-url/remotes/textsplit.git
$ git -c protocol.file.allow=always submodule update
fatal: '$LAB/ch23/submodule-url/remotes/textsplit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
Unable to fetch in submodule path 'vendor/textsplit'; trying to directly fetch 4f00a5b8bb1f8ba700d273d9ec2f453be23efc75:
fatal: '$LAB/ch23/submodule-url/remotes/textsplit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: Fetched in submodule path 'vendor/textsplit', but it did not contain 4f00a5b8bb1f8ba700d273d9ec2f453be23efc75. Direct fetching of that commit failed.
[exit status: 128]
```
<!-- /snippet -->

He has the new `.gitmodules`. His configuration still has the old URL.

```bash
git submodule sync
git config get submodule.vendor/textsplit.url
git -C vendor/textsplit remote get-url origin
git -c protocol.file.allow=always submodule update
```

<!-- snippet: ch23/submodule-url/03-sync -->
```text
$ git submodule sync
Synchronizing submodule url for 'vendor/textsplit'
$ git config get submodule.vendor/textsplit.url
$LAB/ch23/submodule-url/remotes/chunking.git
$ git -C vendor/textsplit remote get-url origin
$LAB/ch23/submodule-url/remotes/chunking.git
$ git -c protocol.file.allow=always submodule update
From $LAB/ch23/submodule-url/remotes/chunking
   e216665..4f00a5b  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Submodule path 'vendor/textsplit': checked out '4f00a5b8bb1f8ba700d273d9ec2f453be23efc75'
```
<!-- /snippet -->

`sync` copies the URL into `.git/config` and into the submodule's `origin` remote. Then `update` fetches from the new location.

**[ON SCREEN]** Lower third: **GitHub Actions**. This segment is described from the action's documentation; nothing was captured. The textbook states that `actions/checkout` does not check out submodules unless told to: its `submodules` input defaults to `false`, and the README describes the values as `true` to check out submodules or `recursive` to check them out recursively. The job's token is scoped to the repository that triggered the run, so a private submodule in another repository needs a token or an SSH key with access to it.

This segment is described from the action's documentation; nothing was captured. The textbook states that `actions/checkout` doesn't check out submodules unless told to: its `submodules` input defaults to `false`.

**[ANIMATION]** cards: id=ci cards=An_empty_directory_isn't_an_error:add_a_git_submodule_status_step|The_job_tests_the_recorded_commit:not_the_library's_latest|The_push-order_failure:appears_in_CI_first|A_fork's_pull_request,_checked_out_recursively:its_.gitmodules_chooses_what_is_cloned|git_archive:doesn't_include_submodule_contents numbered=on title=The_textbook's_five_points

What follows from the mechanics, in the textbook's five points. An empty directory isn't an error to Git, so a job without submodule checkout fails later and elsewhere. So add an explicit step such as `git submodule status`, and fail if any line starts with a minus or a plus. The job tests the recorded commit, not the library's latest. The push-order failure appears in CI first. A workflow that recursively checks out submodules of a pull request from a fork lets the fork's `.gitmodules` choose what is cloned onto the runner. And `git archive` doesn't include submodule contents, so a build that starts from an archive needs the submodules fetched separately.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Pushing the superproject before the library.** Root cause: a gitlink is only an ID and the server does not check that the commit exists in the library's shared repository.
2. **Trying to save work in a dirty submodule with a commit in the superproject.** Root cause: a gitlink can name only a commit; uncommitted content inside the submodule has no ID.
3. **Resolving a pointer conflict by picking one side.** Root cause: when the library commits have diverged, the correct pointer is a library commit that contains both, which only the library can create.
4. **`git rm` and then a failed re-add.** Root cause: the repository under `.git/modules/` and the section in `.git/config` are kept after removal.
5. **Changing the URL in `.gitmodules` and expecting clones to follow.** Root cause: each clone uses the copy that `init` wrote into `.git/config` until `git submodule sync` runs.

## PRODUCTION EXAMPLE

Now, out of the lab. A platform team shares protocol definitions between eight services through a submodule. On a Thursday, CI on `main` of one service fails at checkout with "not our ref". The engineer on call doesn't start with the service's code.

**[ANIMATION]** cards: id=diag question=He_prints_three_values cards=What_origin/main_records:the_gitlink_for_the_submodule_path|What_the_shared_repository_has:git_ls-remote|Who_has_the_wanted_commit:the_branches_in_the_author's_clone numbered=on

He prints three values. The gitlink that `origin/main` records for the submodule path. The refs of the definitions repository, with `git ls-remote`. And, after a message in the team channel, the branches in the author's clone that contain the wanted commit. The first value appears in neither of the other repository's refs, and the author finds it on a local branch. One push of the definitions repository fixes every clone and CI.

**[ANIMATION]** end

The follow-up is two lines in the team's setup script: `push.recurseSubmodules` set to `check`, and a CI step that runs `git submodule status` and fails on a leading minus or plus.

## PRACTICE EXERCISE

Your turn. Do Exercise 15.4, Level 2, command prediction, "The first character of `git submodule status`", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

For each situation the exercise describes, write the character you expect, space, minus, plus or U, and the two values that agree or disagree, before you run the command.

The challenge is Exercise 15.9, Level 4, "It works on your machine", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q440: "A teammate's pull fails with `not our ref`. Give the root cause, the three commands that prove it, the fix, and the setting that prevents it."

**[PAUSE]**

Answer out loud. A strong answer states the root cause as a disagreement between two named things, and says where the missing commit physically is. Each of the three commands answers one question, and the answer names the question with the command: what is wanted, whether the shared repository has it, and who does. It says on whose machine the fix runs, which isn't the teammate's. For prevention it names the setting, describes what it checks before a push, and gives its limits. It may add where this failure is usually seen first.

## RECAP

**[ANIMATION]** step: order.fix

Let's land this. Six failures, and one method: find the two values that should agree, print both, compare. Here, the library commit had to reach the shared repository.

You should now be able to say:

- "not our ref" means the superproject records a library commit that the library's shared repository does not have; `push.recurseSubmodules=check` prevents it.
- Uncommitted work in a submodule cannot be recorded by the superproject; it is committed inside the submodule first.
- A pointer conflict is three gitlinks in the index; Git resolves it alone only when one commit contains the other.
- Removing a submodule leaves `.gitmodules`, a config section and a repository under `.git/modules`; a changed URL reaches clones through `git submodule sync`.
- A CI job is a fresh clone with every default of this chapter, so it has to ask for submodules and check their status.

## HOMEWORK

Read sections 23.8 to 23.12 of [Chapter 23](../../textbook/ch23-submodules.md).

Today you diagnosed "not our ref" from three questions, and that's a real on-call skill. If six failures felt like a lot, that's normal. The table in the diagram section is your map, so practise with it. Next time: subtrees, and choosing between a submodule, a subtree and a package manager. Until then, look at the state first and type second. See you in the next one.

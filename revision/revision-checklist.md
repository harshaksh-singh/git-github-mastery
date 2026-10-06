# Revision checklist: one page per mastery gate

> **Baseline.** Git 2.55.0, GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. Every statement below is taught in the textbook section named in brackets; nothing here is new, and nothing here is an answer to a gate item.

## How to use this page

- **Explain.** Tick a statement only when you can explain it aloud, with the mechanism, without notes: what changes in objects, refs, HEAD, the index and the working tree, and why Git or GitHub behaves that way. Reciting the sentence does not count.
- **Predict.** For each command, write down the output and the new state before you run it in `labs/shell`. The table tells you what to predict, not what the answer is. A wrong prediction is the most useful thing this page can give you: go to the section and find out why.
- **Redo.** Repeat the listed labs from an empty sandbox, without the lab text open, including the failure scenario and the recovery.
- A gate is passed with its threshold overall **and** at least 70% in each of its four parts: concepts 30%, prediction 20%, hands-on diagnosis 30%, oral interview 20% (roadmap, section 4).

| Gate | Threshold | Taken after | Chapters | Page |
|---|---|---|---|---|
| 1 Fundamentals | 85% | Module 5 | 1, 2, 4, 5, 6, 7, 14B (configuration) | [Gate 1](#gate-1-fundamentals) |
| 2 Branching | 90% | Module 7 | 7, 8 (fast-forward), 12 | [Gate 2](#gate-2-branching) |
| 3 Merge and rebase | 90% | Module 10 | 8, 9, 10, 11, 14A (ranges) | [Gate 3](#gate-3-merge-and-rebase) |
| 4 Recovery | 90% | Module 15 | 13, 14A, 14B (tags), 14C, 22, 23, 25 | [Gate 4](#gate-4-recovery) |
| 5 Internals | 85% | Module 18 | 3, 24, 26 | [Gate 5](#gate-5-internals) |
| 6 GitHub | 85% | Module 25 | 15, 16, 17, 18, 19, 14B and 21B (signing) | [Gate 6](#gate-6-github) |
| 7 Actions | 85% | Module 28 | 20A, 20B | [Gate 7](#gate-7-actions) |
| 8 Security | 90% | Module 31 | 21A, 21B | [Gate 8](#gate-8-security) |
| 9 Production debugging | 90% | Module 38 | 27, 28, 29, 30 | [Gate 9](#gate-9-production-debugging) |

## Gate 1: Fundamentals

### Explain

- [ ] Git is a program that stores history in a `.git` directory; GitHub is a service that stores Git repositories and surrounds them with its own objects (1.5).
- [ ] A commit records the complete state of every tracked file as the ID of one tree; it does not record what changed (2.3).
- [ ] An object's ID is a hash of its type and content, so identical content has the identical ID in every repository (2.4).
- [ ] The four object types, and what each one does not contain: a blob has no name, a tree has no history (2.5, 3.4).
- [ ] A ref is a name for an object ID, a branch is a ref that moves when you commit, and HEAD records which branch, or which commit, you are on (2.8).
- [ ] A file can exist in three states at once: in the commit HEAD names, in the index, in the working tree (2.9).
- [ ] The index decides whether a path is tracked, untracked or ignored; no ignore pattern affects a tracked file (4.3, 4.6).
- [ ] `git add` stores a copy of the content at that moment; it is not a subscription to the file (5.3).
- [ ] The three everyday diffs compare three different pairs (5.4).
- [ ] `git commit -a` and `git commit <path>` read the working tree at commit time, whatever you staged before (5.10).
- [ ] Author and committer are two different records, each with its own time (6.5).
- [ ] `git commit --amend` creates a new commit with a new ID; the old one stays reachable from the reflog (6.7).
- [ ] A commit writes the new ID into the ref that HEAD names, and nothing else moves (7.4).
- [ ] When a key is set in several configuration scopes, the value read last wins, and `--show-origin` tells you which file that was (14B.2).
- [ ] Why `git restore <path>` and `git clean -f` are 🔴 while `git commit` is 🟢 (1.8, 4.7, 4.14).

### Predict

| Command | Starting state | What you must be able to predict | Section |
|---|---|---|---|
| `git status -s` | One file staged, then edited again | Both status columns for that file, and why | 4.4 |
| `git diff`, `git diff --cached`, `git diff HEAD` | The same state | Which of the three shows which change | 5.4 |
| `git commit -m` | A staged change plus an unstaged one | Which change is in the commit; what status says afterwards | 5.3, 6.3 |
| `git restore --staged <path>`, `git reset <path>`, `git rm --cached <path>` | A staged new file; a staged edit | Which of them leave the same index, and which stages a deletion | 5.9 |
| `git add -p`, then `git commit -a` | Two hunks, one accepted | What the commit contains | 5.5, 5.10 |
| `git commit --amend --no-edit` | An unrelated change is staged | The new commit's content, its ID, the reflog line | 6.7 |
| `git cat-file -t`, `git cat-file -p` | A commit, its tree, a blob | The type and the fields of each object | 2.5 |
| `git hash-object <file>` | The same bytes under two file names | Whether the IDs are equal, and why | 2.4 |
| `git switch --detach <commit>`, then `git commit` | Any | What HEAD holds; which ref moved | 7.7 |
| `git config get --show-origin --show-scope <key>` | The key set globally and locally | The value and the file that wins | 14B.2 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 1.1: Build a commit by hand | A commit is objects plus one ref update | [m01-what-git-is.md](../lab-manual/m01-what-git-is.md) |
| Lab 2.1: The three-trees prediction table | You can predict status from the three places | [m02-working-tree-index-head.md](../lab-manual/m02-working-tree-index-head.md) |
| Lab 2.3: The `.gitignore` trap and its fix | Ignore rules do not apply to tracked files | [m02-working-tree-index-head.md](../lab-manual/m02-working-tree-index-head.md) |
| Lab 2.4: Unstage three ways and compare the results | Two meanings of "unstage" | [m02-working-tree-index-head.md](../lab-manual/m02-working-tree-index-head.md) |
| Lab 3.1: Amend a commit and find the old one | Amend replaces; the reflog remembers | [m03-commits.md](../lab-manual/m03-commits.md) |
| Lab 4.1: Refs by hand | A branch is one small name | [m04-refs-branches-head.md](../lab-manual/m04-refs-branches-head.md) |
| Lab 5.1: Scopes and origins | Which file a setting comes from | [m05-configuration.md](../lab-manual/m05-configuration.md) |

### If you cannot

Restudy 2.11 (common wrong mental models), 5.9 and 5.16, and 4.15. Keep the [glossary](../reference/glossary.md) open for the words, and the daily-use table of the [Git cheat sheet](../cheatsheets/git-cheat-sheet.md) for the commands.

## Gate 2: Branching

### Explain

- [ ] A branch is a ref under `refs/heads/` that holds one commit ID; its history is whatever that commit reaches through its parents (7.2).
- [ ] HEAD is normally a symbolic ref that names the current branch; detached, it holds a commit ID, and new commits advance HEAD itself (7.3, 7.7).
- [ ] Two branches have diverged when neither tip is an ancestor of the other; ahead and behind are counted from the merge base (7.8).
- [ ] Nothing in a repository records which branch a branch was created from (7.9).
- [ ] `git branch -d` checks merge status and `-D` does not; both delete the branch's reflog (7.5).
- [ ] A remote-tracking branch such as `origin/main` is a ref in your own repository that records the last position you saw; it is a cache, not the server (7.10, 12.4).
- [ ] An upstream is two lines of configuration that pair a local branch with a branch on a remote (12.5).
- [ ] `git fetch` moves remote-tracking refs and never a local branch, the index or the working tree (12.4).
- [ ] `git pull` is a fetch plus one integration step, and on diverged branches Git makes you say which (12.6).
- [ ] A push succeeds for each ref only if both your Git and the remote accept the update; a non-fast-forward is refused (12.7).
- [ ] What `--force`, `--force-with-lease` and `--force-if-includes` each check, and why every forced push is 🔴 (12.8).
- [ ] A refspec decides which refs a fetch or a push touches (12.12).
- [ ] A fetch never deletes a remote-tracking ref unless you prune, and pruning deletes that ref's reflog (12.11).
- [ ] A fast-forward creates no object: the branch ref moves to a commit that already exists (8.3).

### Predict

| Command | Starting state | What you must be able to predict | Section |
|---|---|---|---|
| `git branch <name>`, then `git for-each-ref` | Any commit | Which refs exist, and what did not change | 7.5 |
| `git switch -c x`, commit, `git switch -` | A clean tree | HEAD, both branch refs, the HEAD reflog | 7.6 |
| `git rev-list --left-right --count A...B` | Two diverged branches | Both numbers | 7.8 |
| `git branch -d <branch>` | A branch whose work was squash-merged | Refusal or success, and the reason | 7.5, 7.14 |
| `git fetch` | The server has one new commit on `main` | `origin/main`, `main`, `FETCH_HEAD`, the working tree | 12.4 |
| `git status -sb` after that fetch | You also have one local commit | The ahead and behind text | 12.5 |
| `git pull` | Diverged branches, nothing configured | The message and the state afterwards | 12.6 |
| `git push` | The server has a commit you lack | The rejection text; what changed locally | 12.7 |
| `git push --force-with-lease` | A background fetch already updated `origin/<branch>` | Whether the lease protects the server's commit | 12.8 |
| `git fetch --prune` | A branch was deleted on the server | Which refs and reflogs disappear; what `git branch -vv` shows | 12.11 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 4.2: Detached HEAD rescue | Commits without a branch are found through the reflog | [m04-refs-branches-head.md](../lab-manual/m04-refs-branches-head.md) |
| Lab 4.3: The `feature` versus `feature/x` conflict | Ref names are paths | [m04-refs-branches-head.md](../lab-manual/m04-refs-branches-head.md) |
| Lab 4.4: Counting divergence | Ahead and behind from the merge base | [m04-refs-branches-head.md](../lab-manual/m04-refs-branches-head.md) |
| Lab 7.1: A bare server and two clones, watching every ref | Which ref each command moves | [m07-remotes.md](../lab-manual/m07-remotes.md) |
| Lab 7.2: A rejected push, then fetch and integrate by merge and by rebase | The non-fast-forward rule | [m07-remotes.md](../lab-manual/m07-remotes.md) |
| Lab 7.4: When `--force-with-lease` saves you and when it does not | The lease and its blind spot | [m07-remotes.md](../lab-manual/m07-remotes.md) |
| Lab 7.6: Prune and "gone" branches | Stale remote-tracking refs | [m07-remotes.md](../lab-manual/m07-remotes.md) |
| Incident 10, a commit exists locally but not remotely | Diagnosis from `git status -sb` and `git ls-remote` | [incidents](../incidents/README.md) |

### If you cannot

Restudy 7.14 and 12.15, then 12.14 (two diagnoses from first principles). Commands: the remotes table of the [Git cheat sheet](../cheatsheets/git-cheat-sheet.md); the push rows of [command safety](../reference/command-safety.md), section 7.

## Gate 3: Merge and rebase

### Explain

- [ ] The merge base is the best common ancestor and the third input of every merge (8.2).
- [ ] A true merge combines the two tips against the merge base, path by path and then line by line, and records a commit with two parents (8.4).
- [ ] A content conflict occurs when both sides changed the same lines, or lines with no unchanged line between them, and did not make the identical change (8.7).
- [ ] A conflicted merge leaves its state in three places: marker blocks in files, up to three index entries per path, and files in `.git` (8.8).
- [ ] A merge without conflicts says nothing about whether the result builds or makes sense (8.15).
- [ ] `git reset` moves the branch; the mode decides how far the change spreads, and `--hard` destroys uncommitted work (11.4, 11.5).
- [ ] `git revert` adds a commit and removes nothing, which makes it the undo for published history (11.8).
- [ ] After `git revert -m 1 <merge>`, a later merge of the same branch brings almost nothing, and why (11.9).
- [ ] A rebased commit cannot keep its ID: its parent, and usually its tree, are different (9.3).
- [ ] During a rebase "ours" is the new base plus the copies made so far and "theirs" is your own commit (9.11).
- [ ] A rebase destroys nothing: `ORIG_HEAD` and the branch reflog name the old tip (9.16).
- [ ] What a teammate's clone looks like after you rebase and force-push a shared branch (9.15).
- [ ] A cherry-pick is a three-way merge whose base is the picked commit's parent; the copy shares author, author date and message with the original, and nothing else (10.2, 10.3).
- [ ] `A..B` in `git log` is a set of commits; `A..B` and `A...B` in `git diff` each compare two snapshots (14A.2, 14A.8).

### Predict

| Command | Starting state | What you must be able to predict | Section |
|---|---|---|---|
| `git merge <other>` | `<other>` is ahead; or both sides have commits | Fast-forward or merge commit; parents; `ORIG_HEAD` | 8.3, 8.4 |
| `git ls-files -u` | A stopped merge | The stages present for an edit-against-edit and for a modify-against-delete conflict | 8.8, 8.11 |
| `git merge --abort` | A resolution half done, one unrelated edit staged | What survives | 8.10 |
| `git reset --soft`, `--mixed`, `--hard`, `--keep` to `HEAD~1` | One staged and one unstaged change | Branch, index and working tree for each mode | 11.4, 11.6 |
| `git revert <commit>` | A pushed commit | The new commit; what `git log` shows | 11.8 |
| `git rebase main` | Three local commits, `main` moved | Which IDs change; the reflog lines; `ORIG_HEAD` | 9.2, 9.4 |
| `git restore --ours <path>` | A rebase stopped at a conflict | Whose version you get | 9.11 |
| `git rebase --onto <new> <old>` | A branch stacked on another | Exactly which commits are replayed | 9.5 |
| `git cherry-pick -x <commit>` | A release branch | The new commit's ID, author, committer and message | 10.3, 10.4 |
| `git log A..B`, `git log A...B --left-right`, `git diff A..B`, `git diff A...B` | Two diverged branches | The output of all four | 14A.2, 14A.8 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 6.2: An edit-against-edit conflict, resolved by reading the stages | The three stages | [m06-merge.md](../lab-manual/m06-merge.md) |
| Lab 6.5: A clean merge that breaks the build | Clean for Git, wrong for humans | [m06-merge.md](../lab-manual/m06-merge.md) |
| Lab 8.1: The reset prediction table | The four modes | [m08-undo.md](../lab-manual/m08-undo.md) |
| Lab 8.3: Revert a merge, then re-merge | The re-merge problem | [m08-undo.md](../lab-manual/m08-undo.md) |
| Lab 9.4: A conflict in a rebase, and who is "ours" | The swap | [m09-rebase.md](../lab-manual/m09-rebase.md) |
| Lab 9.6: Rebase a shared branch and watch a teammate's history duplicate | Why shared branches are not rebased | [m09-rebase.md](../lab-manual/m09-rebase.md) |
| Lab 10.1: Backport a fix with `-x` | A copy with a new ID and a trace | [m10-cherry-pick-ranges.md](../lab-manual/m10-cherry-pick-ranges.md) |
| Lab 10.4: Predict two-dot and three-dot output for `git log` and for `git diff` | Range notation | [m10-range-notation.md](../lab-manual/m10-range-notation.md) |
| Incidents 5 and 9, a rebased shared branch and a misunderstood conflict | Diagnosis from symptoms only | [incidents](../incidents/README.md) |

### If you cannot

Restudy 8.19, 9.21, 10.12 and 11.14, then the decision tree of 11.12. Commands: the undo and branches tables of the [Git cheat sheet](../cheatsheets/git-cheat-sheet.md); [command safety](../reference/command-safety.md), sections 5 and 6.

## Gate 4: Recovery

### Explain

- [ ] The four layers of protection, and what moves an object from one layer to the next (13.2).
- [ ] A reflog is local and append-only; a fresh clone, a CI runner and a deleted branch have none (13.3).
- [ ] The default retention periods, and why the lab configuration differs (13.4).
- [ ] `ORIG_HEAD` is one slot that several commands overwrite (13.5).
- [ ] `git fsck` finds what nothing names; "dangling" is information, not damage (13.6).
- [ ] The recovery method: stop, look, anchor with a ref, recover with the mildest command (13.7).
- [ ] Why `git reset --hard` does not delete commits, and what it does destroy (11.5, 13.8).
- [ ] What cannot be recovered, and exactly why: content that was never an object (13.12).
- [ ] The two steps that make a commit unrecoverable, and the two commands that force both (13.13).
- [ ] After a teammate's force push, your clone is the recovery tool: `origin/<branch>@{1}` (13.10).
- [ ] The pickaxe `-S` and `-G` answer different questions (14A.11).
- [ ] `git blame` names the last change to a line, not the cause of a bug (14A.16).
- [ ] `git bisect` halves the suspects; exit status 125 marks a commit that cannot be tested (14A.20, 14A.21).
- [ ] A stash entry is a small commit graph that only `refs/stash` reaches (14C.2).
- [ ] A published tag must not move: every clone keeps its own copy (14B.11).
- [ ] A submodule is one recorded commit ID; an LFS-tracked path is a pointer file in Git (23.2, 22.3).

### Predict

| Command | Starting state | What you must be able to predict | Section |
|---|---|---|---|
| `git reflog`, `git reflog show <branch>` | After a commit, an amend and a reset | The entries, their order, their selectors | 13.3 |
| `git reset --hard HEAD~2`, then `git fsck --lost-found` | One staged and one unstaged edit | What is found, and what is not | 13.8, 13.9 |
| `git branch -D <branch>`, then `git reflog show <branch>` | An unmerged branch | The error, and where the ID still is | 13.8 |
| `git stash drop`, then `git stash store <id>` | One stash entry | Whether the entry returns, and until when | 13.9 |
| `git gc --prune=now` | An unreachable commit that a reflog entry names | Whether it survives | 13.2, 13.13 |
| `git reflog expire --expire=now --all`, then `git gc --prune=now` | The same | What is left | 13.13 |
| `git log -S<string>` against `git log -G<regex>` | A line that was edited, not added | Which one reports the commit | 14A.11 |
| `git bisect start <bad> <good>` | A linear range of known length | The number of steps | 14A.20 |
| `git fetch --tags` | The server moved a tag you already have | The message, and your tag afterwards | 14B.11 |
| `git submodule update` | You committed inside the submodule on its detached HEAD | Where those commits are afterwards | 23.5 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 12.1: An accidental hard reset | Commits from the reflog, staged content from `fsck` | [m12-recovery.md](../lab-manual/m12-recovery.md) |
| Lab 12.2: A deleted branch | The HEAD reflog outlives the branch | [m12-recovery.md](../lab-manual/m12-recovery.md) |
| Lab 12.8: Overwritten changes and a cleared stash | The limits of recovery | [m12-recovery.md](../lab-manual/m12-recovery.md) |
| Lab 12.11: A force push, seen from the local side | The remote-tracking reflog | [m12-recovery.md](../lab-manual/m12-recovery.md) |
| Lab 12.12: Prove the point of no return | Expiry plus prune | [m12-recovery.md](../lab-manual/m12-recovery.md) |
| Lab 11.5: An automated `git bisect run` | The exit-code protocol | [m11-history-forensics.md](../lab-manual/m11-history-forensics.md) |
| Lab 13.2: A moved tag between two clones | Two things with one name | [m13-tags-versions.md](../lab-manual/m13-tags-versions.md) |
| Lab 15.1: A submodule that breaks for a teammate | Push order | [m15-submodules-subtrees-lfs.md](../lab-manual/m15-submodules-subtrees-lfs.md) |
| Incidents 1 and 8, a hard reset and a branch that disappeared | Diagnosis from symptoms only | [incidents](../incidents/README.md) |

### If you cannot

Restudy 13.16 and 13.12, then 14A.25. Keep the [emergency recovery page](../cheatsheets/emergency-recovery-one-page.md) and the [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md) at hand; the recovery table of the [Git cheat sheet](../cheatsheets/git-cheat-sheet.md) lists the commands.

## Gate 5: Internals

### Explain

- [ ] The `.git` directory is the repository; the files next to it are a working tree that Git can rebuild (3.2).
- [ ] A loose object is one compressed file: a header, a NUL byte and the data, named by the hash of those bytes (3.3).
- [ ] A packfile may store an object as a delta from a similar object, and this does not make commits diffs (3.7).
- [ ] Reachability decides what `git fsck` reports and what a collection may delete (3.8).
- [ ] A ref can be a loose file, a line in `packed-refs`, or both; scripts read refs with `git rev-parse`, never from files (3.9).
- [ ] Which names are root refs and which two are pseudorefs since Git 2.46 (3.10).
- [ ] The index holds, per path, a mode, a blob ID, a stage number and cached `stat` data (3.12).
- [ ] reftable and SHA-256 exist today, are planned defaults for Git 3.0, and a SHA-256 repository cannot exchange objects with a SHA-1 repository (3.13, 3.14).
- [ ] Since Git 2.54 the maintenance Git starts on its own no longer runs `git gc`; what geometric repacking does (26.3, 26.4).
- [ ] The commit-graph, the multi-pack-index and bitmaps are derived files: each can be deleted and rebuilt (26.6, 26.7, 26.8).
- [ ] A shallow clone pretends history ends; a partial clone has the structure and fetches missing objects from a promisor remote (26.11, 26.12).
- [ ] Sparse-checkout limits the working tree, not the repository, its history or its index (24.4).
- [ ] A bundle is a pack plus refs in one file; an incremental bundle has prerequisites (26.14).

### Predict

| Command | Starting state | What you must be able to predict | Section |
|---|---|---|---|
| `git count-objects -v` before and after `git gc` | A repository with loose objects | Which counters change | 3.7 |
| `git cat-file -p <tree>` | A tree with a file, a directory and an executable | The modes and types listed | 3.4 |
| `git rev-parse <name>` | A branch and a tag with the same name | Which one wins, and the warning | 3.6 |
| `git pack-refs --all`, then `cat .git/refs/heads/<branch>` | Loose refs | What happens to the file; what `git rev-parse` says | 3.9 |
| `git ls-files --stage`, `git ls-files --debug` | A clean index | The fields per entry | 3.12 |
| `git clone --depth 1`, then `git describe` | A repository with tags | The failure, and the fix | 26.11 |
| `git clone --filter=blob:none`, then `git log -p` | Online | When objects are fetched | 26.12 |
| `git sparse-checkout set <dir>`, then `git ls-files -t` | A repository with three top-level directories | The working tree, the entry count, the tags | 24.4 |
| `git maintenance run --task=<task>` | Several small packs | Which files appear or disappear | 26.3 |
| `git bundle create <file> <old>..<new>`, then fetch from it | A receiver without `<old>` | The error | 26.14 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 0.2: Read every file in an empty `.git` | What a repository consists of | [m00-lab-setup.md](../lab-manual/m00-lab-setup.md) |
| Lab 16.1: Watch loose objects become a pack | Packing changes storage, not objects | [m16-object-database.md](../lab-manual/m16-object-database.md) |
| Lab 16.2: Read a pack listing and find a delta chain | Deltas | [m16-object-database.md](../lab-manual/m16-object-database.md) |
| Lab 17.1: Read the index as a data structure | The index format | [m17-index-refs-gitdir.md](../lab-manual/m17-index-refs-gitdir.md) |
| Lab 17.2: The `files` backend versus reftable | Ref storage | [m17-index-refs-gitdir.md](../lab-manual/m17-index-refs-gitdir.md) |
| Lab 17.3: A tour of every special ref and file | Root refs and operation state | [m17-index-refs-gitdir.md](../lab-manual/m17-index-refs-gitdir.md) |
| Lab 18.1: Clone one repository three ways and compare what arrived | Full, shallow, partial | [m18-transfer-scale.md](../lab-manual/m18-transfer-scale.md) |
| Lab 18.2: Cone-mode sparse-checkout | The cone | [m18-transfer-scale.md](../lab-manual/m18-transfer-scale.md) |

### If you cannot

Restudy 3.15, 26.16 and 24.12. The plumbing table of the [Git command reference](../reference/git-command-reference.md), section 10, lists every command of this gate; the [glossary](../reference/glossary.md) separates the look-alike terms (commit graph and commit-graph, shallow and partial).

## Gate 6: GitHub

### Explain

- [ ] A repository on GitHub is a Git repository you can copy completely, surrounded by records you cannot copy with Git at all (15.2).
- [ ] In an organization, what a person can do is the highest of every grant that reaches them (15.4).
- [ ] A fork is a GitHub repository with its own refs and permissions that stores its Git data together with its parent (15.7).
- [ ] A tag is a Git ref; a release is a GitHub record that points at a tag name (15.12).
- [ ] Authentication establishes which account a connection belongs to; authorization decides what it may do (16.2).
- [ ] Over HTTPS, GitHub accepts a token where a password is expected, and nothing else; which helper answers, and where the token lives (16.3, 16.5).
- [ ] What a token's prefix tells you, and how far a leak of each kind reaches (16.6).
- [ ] Who wrote an error line: your `ssh` client, GitHub's server, or Git (16.17).
- [ ] Opening a pull request moves no branch; it creates a GitHub object and two read-only refs (17.2).
- [ ] "Commits" is `git log base..head`; "Files changed" is `git diff base...head` (17.3).
- [ ] The three merge buttons write three different histories, with different commit IDs (17.8).
- [ ] Why a pull request can show unexpected commits or a huge diff (17.12).
- [ ] A rule is evaluated on GitHub's server before a ref moves; all active rulesets that target a ref add up (18.2, 18.4).
- [ ] A required status check is a list of check names; a check that never reports blocks the merge (18.8).
- [ ] `CODEOWNERS` is read from the base branch, the last matching pattern wins, and without a rule an owner is only a suggested reviewer (19.3, 19.5, 19.6).
- [ ] What GitHub's "Verified" badge does and does not establish (21B.6, 21B.7).

### Predict

| Command or configuration | Situation | What you must be able to predict | Section |
|---|---|---|---|
| `git fetch origin pull/N/head:pr-N` | An open pull request | Which local ref appears; what it points at | 17.2 |
| `git log base..head` and `git diff base...head` | The base moved after the branch was cut | What each tab of the page shows | 17.3 |
| Merge commit, squash, rebase | The same three-commit pull request | The commits on `main`, their IDs and parents; what `git branch -d` says afterwards | 17.8, 17.9 |
| A pull request opened against the wrong base | The branch was cut from another feature branch | Which commits and files the page shows | 17.12 |
| `git push --force` to a branch with a ruleset that blocks force pushes | Any | Who refuses, and with which kind of message | 18.2, 18.11 |
| A required check plus a `paths` filter on its workflow | A pull request that touches no matching path | The state of the merge box | 18.8 |
| Two lines of `CODEOWNERS` that match one file | Any | Which owner is requested | 19.5 |
| `ssh -T git@github.com` | Two keys in the agent, two accounts | Which account answers, and how to change it | 16.13 |
| `git push` over HTTPS with an expired token | A helper holds the old token | The error line, and who wrote it | 16.17, 16.19 |
| A signed commit by a key that is not registered on any account | Pushed to GitHub | The badge, with and without vigilant mode | 21B.6 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 19.2: An inventory of Git data and GitHub objects | What a clone does not contain | [m19-github-platform.md](../lab-manual/m19-github-platform.md) |
| Lab 20.3: Three failures, reproduced and diagnosed | Reading authentication errors | [m20-authentication-ssh.md](../lab-manual/m20-authentication-ssh.md) |
| Lab 21.1: A full fork and pull request cycle | The fork workflow | [m21-pull-requests-forks.md](../lab-manual/m21-pull-requests-forks.md) |
| Lab 21.2: A pull request against the wrong base | Unexpected commits | [m21-pull-requests-forks.md](../lab-manual/m21-pull-requests-forks.md) |
| Lab 22.1: The three merge methods compared | Three histories | [m22-merge-methods-releases.md](../lab-manual/m22-merge-methods-releases.md) |
| Lab 23.1: A ruleset on the default branch | Server-side rules | [m23-governance.md](../lab-manual/m23-governance.md) |
| Lab 23.3: Three blocked merges to diagnose | "Why can't I merge?" | [m23-governance.md](../lab-manual/m23-governance.md) |
| Lab 24.3: What GitHub shows for unsigned, signed and forged commits | Verification states | [m24-signing-github.md](../lab-manual/m24-signing-github.md) |

GitHub-side labs run in your normal shell, not in `labs/shell`, and their expected results are described from the documentation.

### If you cannot

Restudy 17.19, 18.17 (the "Why can't I merge?" procedure) and 16.20 (the decision tree). Reference: the [GitHub reference](../reference/github-reference.md) for limits, roles, rule types and token types; the [GitHub CLI cheat sheet](../cheatsheets/github-cli-cheat-sheet.md) for commands.

## Gate 7: Actions

### Explain

- [ ] Workflow, event, job, step, action, runner: what each is, and that every job is a fresh machine (20A.2).
- [ ] A workflow file is data: a YAML parser reads it before GitHub Actions interprets any key (20A.3).
- [ ] Each event fixes which commit and ref the run is about and which copy of the workflow file is used (20A.4).
- [ ] An expression is replaced by its value before the step starts (20A.5).
- [ ] `env`, `vars` and `secrets` differ in where they are stored and whether they are masked (20A.6).
- [ ] State survives a step only through files the runner provides, such as `GITHUB_OUTPUT` and `GITHUB_ENV` (20A.7).
- [ ] `actions/checkout` fetches one commit without tags; on `pull_request` it is the test merge commit, with a detached HEAD (20A.8).
- [ ] A cache is an optimization that may be absent; an artifact is stored with the run and expires (20A.11, 20A.12).
- [ ] An environment holds protection rules and secrets that a job reaches only after passing the rules (20B.2).
- [ ] A concurrency group lets at most one run or job with that name execute at a time (20B.5).
- [ ] A reusable workflow replaces whole jobs; a composite action replaces steps (20B.6).
- [ ] The investigation order for a failing workflow (20B.11).
- [ ] Why a required check can stay pending forever (20B.13).

### Predict

| Workflow fragment or command | Situation | What you must be able to predict | Section |
|---|---|---|---|
| `on: pull_request` with a default checkout | A pull request whose base moved | Which commit the job tests | 20A.8 |
| `git describe` in a job with a default checkout | The repository has tags | The result, and the one-line fix | 20A.8 |
| A matrix value written without quotes, `3.10` | Any | The version that is installed | 20A.3, 20A.10 |
| A piped command in `run` without `shell: bash` | The first command of the pipe fails | The colour of the job | 20A.7 |
| A step reads `${{ secrets.X }}` | The run comes from a fork | The value | 20A.6 |
| `concurrency` with `cancel-in-progress: true` and a group without the ref | Two branches push at once | Which run survives | 20B.5 |
| `environment: prodution` (misspelled) | The real environment has required reviewers | Whether the job waits for approval | 20B.2 |
| `gh run rerun RUN_ID` | `main` has moved since the run | The commit and workflow file the new attempt uses | 20B.14 |
| `gh workflow run FILE --ref BRANCH` | A pull request requires that check | Whether the pull request's check is satisfied | 20A.4 |
| A `paths` filter on the workflow of a required check | A pull request outside the paths | The state of the pull request | 20B.13 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 26.1: Workflow 1, run the tests | The model, and what checkout puts on the runner | [m26-actions-fundamentals.md](../lab-manual/m26-actions-fundamentals.md) |
| Lab 26.3: Workflow 3, build the application | History, outputs, `needs` | [m26-actions-fundamentals.md](../lab-manual/m26-actions-fundamentals.md) |
| Lab 26.4: Workflow 4, Python tests with uv and caching | Cache keys | [m26-actions-fundamentals.md](../lab-manual/m26-actions-fundamentals.md) |
| Lab 26.8: Workflow 10, matrix testing | Matrix and the aggregate job | [m26-actions-fundamentals.md](../lab-manual/m26-actions-fundamentals.md) |
| Lab 27.4: Staging, then production behind an approval (workflow 9) | Environments | [m27-build-package-deliver.md](../lab-manual/m27-build-package-deliver.md) |
| Lab 27.5: A reusable workflow and its caller (workflow 11) | Reuse | [m27-build-package-deliver.md](../lab-manual/m27-build-package-deliver.md) |
| Lab 28.1: Six broken workflows | Diagnosis | [m28-runners-debugging-ci.md](../lab-manual/m28-runners-debugging-ci.md) |
| Lab 28.2: The investigation order, applied to a failing run | The method | [m28-runners-debugging-ci.md](../lab-manual/m28-runners-debugging-ci.md) |
| Incident 7, CI passes locally | Paper diagnosis from a workflow file and a described run | [incidents](../incidents/README.md) |

### If you cannot

Restudy 20A.16, 20B.16 and the table of 20B.12. Reference: the [GitHub Actions cheat sheet](../cheatsheets/github-actions-cheat-sheet.md) and the [GitHub Actions guide](../guides/github-actions-guide.md).

## Gate 8: Security

### Explain

- [ ] A workflow run is a program GitHub starts on your behalf with a credential for your repository; its safety depends on who controls its code and inputs (21A.2).
- [ ] Every job gets a short-lived token, and `permissions` decides what it may do (21A.3).
- [ ] A `pull_request` run from a fork gets a read-only token and no secrets (21A.4).
- [ ] `pull_request_target` runs your workflow with your token and secrets, and is safe only while it never executes the pull request's code (21A.5).
- [ ] How an expression becomes script injection, and why passing the value through `env` is safe (21A.6).
- [ ] Only a full commit ID guarantees that an action is the code you reviewed (21A.7).
- [ ] A secret is as exposed as the least trustworthy code in any job that receives it; masking is not a boundary (21A.9).
- [ ] OIDC replaces a stored cloud key by a credential valid for one job (21A.10).
- [ ] Cloning copies nothing that Git would execute; running Git inside a `.git` directory somebody else wrote is not safe (21B.2).
- [ ] What `safe.directory`, `safe.bareRepository` and `protocol.file.allow` each guard (21B.3).
- [ ] Author and committer are assertions that neither Git nor a push checks (21B.5).
- [ ] Why deleting the file, force-pushing and making the repository private do not remove a secret (21B.10).
- [ ] The six response steps, and why rotation comes first (21B.14).
- [ ] A history rewrite replaces the first affected commit and every descendant; the command is the smallest part of the work (21B.16).
- [ ] How a stale clone pushes the secret back (21B.18).

### Predict

| Workflow fragment or command | Situation | What you must be able to predict | Section |
|---|---|---|---|
| A workflow without a `permissions` key against one with `contents: read` | A step tries to comment on a pull request | Which one fails, and the message | 21A.3 |
| `run: echo "${{ github.event.pull_request.title }}"` | A title that contains shell syntax | What the shell executes | 21A.6 |
| `on: pull_request_target` with a checkout of the pull request's head | A pull request from a fork | Whose code runs, with which token | 21A.5 |
| `uses: owner/action@v1` | The owner moves the tag | What your next run executes | 21A.7 |
| `git log --all -S'<secret>'` after `git rm` and a commit | The secret was committed once | Whether it is found | 21B.11 |
| `git push` of a commit that contains a recognized secret | Push protection is on | Where the push stops; which commits must change | 21B.12 |
| `git status` in a directory owned by another user | No `safe.directory` entry | The error | 21B.3 |
| `git commit --author="Someone Else <x@example.com>"`, then push | No signature rule | What the server accepts; what the page shows | 21B.5 |
| A history filter on `main` only | The secret is also reachable from a tag | The result of a second scan | 21B.17 |
| `git push` from a clone that fetched before the rewrite | After the cleanup | What returns to the server | 21B.18 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 29.1: Find and fix five planted weaknesses | Reading workflows as an attacker | [m29-actions-security.md](../lab-manual/m29-actions-security.md) |
| Lab 29.2: Justify every control of workflow 12 | Secure by default | [m29-actions-security.md](../lab-manual/m29-actions-security.md) |
| Lab 29.3: Review a pull request that changes workflows | The review checklist | [m29-actions-security.md](../lab-manual/m29-actions-security.md) |
| Lab 24.2: A spoofed-author commit | Identity is text | [m24-signing-local.md](../lab-manual/m24-signing-local.md) |
| Lab 30.1: Push protection, and what a push-time check catches | The limits of the control | [m30-repository-security.md](../lab-manual/m30-repository-security.md) |
| Lab 30.3: Scan a full history for planted secrets | Finding secrets with built-in commands | [m30-repository-security.md](../lab-manual/m30-repository-security.md) |
| Lab 31.1: The tabletop: a committed secret, from report to prevention | The six steps | [m31-secret-leak-response.md](../lab-manual/m31-secret-leak-response.md) |
| Incident 3, a committed secret | "I deleted the file, so the branch is clean now" | [incidents](../incidents/README.md) |

### If you cannot

Restudy 21A.20, 21A.19 and 21B.21. Reference: the [security cheat sheet](../cheatsheets/security-cheat-sheet.md), the [security guide](../guides/security-guide.md), and the 🔴 rows of [command safety](../reference/command-safety.md), sections 8 and 11.

## Gate 9: Production debugging

### Explain

- [ ] Diagnosis is a read-only search for the one fact about the state that explains the symptom, followed by the smallest change that repairs that fact (29.2).
- [ ] The ten-command opening, and what each command rules in or out (1.11, 29.5).
- [ ] Every interrupted operation leaves named files in `.git` that say which operation it is and where it started (29.6).
- [ ] Before the first state-changing command, preserve: a backup ref, a copy, a bundle, and what each one does not hold (29.7).
- [ ] Your clone records what you did; GitHub records what reached the server and which rules were evaluated (29.8).
- [ ] Rank fixes by what each can destroy and how each is undone, and take the one that only adds (29.9).
- [ ] A fix is verified when the commands that showed the problem now show its absence, for the reason you predicted (29.10).
- [ ] An incident is a problem in shared state that other people depend on while you are still working out what it is (30.2).
- [ ] Why `git push --force-with-lease=<ref>:<expect>` is the forced push for an incident, and plain `--force` is not (30.23).
- [ ] Which way a fix travels between `main` and a release branch, and what each convention costs (27.10).
- [ ] The research associates short-lived branches and small batches with delivery performance; it does not rank named workflows (27.13).
- [ ] A result in an ML project is identified by more than the commit (28.7).
- [ ] What a blameless postmortem records, and what "blameless" means (30.19).

### Predict

| Command | Situation | What you must be able to predict | Section |
|---|---|---|---|
| `git status` | A rebase, a merge, a cherry-pick or a bisect was interrupted | The operation named, and the files in `.git` that say so | 29.6 |
| `git rebase --abort` | Two new commits were made while the rebase was stopped | Where those commits are afterwards | 29.3 |
| `git status -sb` and `git ls-remote origin` | "It is pushed, GitHub must be caching" | Which of the two disproves the claim | 29.4 |
| `git reflog show origin/<branch>` | A teammate force-pushed | The entry that holds the lost tip | 13.10 |
| `git push --force-with-lease=<ref>:<expect>` | Someone pushed after your fetch | Whether the push is accepted | 30.23 |
| `git revert -m 1 <merge>` | The merged branch will be merged again later | What the later merge brings | 11.9 |
| `git cherry-pick <A>..<B>` onto a rescue of `main` | Commits lost by a reset, new commits made since | The resulting history | 30.5 |
| `git merge-base --is-ancestor <deployed> production` | "The deployed commit is not an ancestor of `production`" | The exit status, and what it implies | 30.8 |
| `git bundle create <file> --all` against `cp -Rp` | Evidence before a risky fix | What each one preserves | 29.7 |
| `git log --oneline main..<branch>` after a squash merge | The branch is about to be deleted | What it lists, and what to compare instead | 17.9 |

### Redo

| Lab | What it proves | File |
|---|---|---|
| Lab 35.1: The ten-command diagnosis on three repositories | The opening | [m35-diagnosis-method.md](../lab-manual/m35-diagnosis-method.md) |
| Lab 35.2: Five operations in progress, read from `.git` alone | Operation state | [m35-diagnosis-method.md](../lab-manual/m35-diagnosis-method.md) |
| Lab 35.3: Preserve evidence, then fix | Preserve before repair | [m35-diagnosis-method.md](../lab-manual/m35-diagnosis-method.md) |
| Lab 36.5: A developer rebases a shared branch (incident 5) | The eleven-step recovery | [m36-incident-drills-local.md](../lab-manual/m36-incident-drills-local.md) |
| Lab 37.2: Production branch history is rewritten (incident 4) | A leased restore | [m37-incident-drills-platform.md](../lab-manual/m37-incident-drills-platform.md) |
| Lab 38.2: A blameless postmortem | Writing for prevention | [m38-communication-postmortems.md](../lab-manual/m38-communication-postmortems.md) |
| Lab 38.3: Senior standard 1, against the clock: the rebased and force-pushed branch | Speed with safety | [m38-communication-postmortems.md](../lab-manual/m38-communication-postmortems.md) |
| All ten incidents, each with `check.sh` | Diagnosis from an incomplete and partly wrong report | [incidents](../incidents/README.md) |

### If you cannot

Restudy 29.12 and 29.13, then the worked incidents of Chapter 30 one at a time. Keep the [troubleshooting playbook](../playbooks/troubleshooting-playbook.md), the [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md) and the [emergency recovery page](../cheatsheets/emergency-recovery-one-page.md) at hand.

## Before every gate

- [ ] You can state the verification rule of the roadmap (section 3.7) and you applied it: every claim you make about Git output was run, not remembered.
- [ ] You practised aloud. The oral part is run one question at a time, as the [interview-mode protocol](../interview/interview-mode-protocol.md) describes.
- [ ] You know the pass rule: the threshold overall and at least 70% in every part.
- [ ] A missed gate leads to targeted remediation and a different variant; the answers to a failed gate are not handed out (roadmap, section 4).

## Chapter files

Section numbers map to chapter files as listed in [command safety](../reference/command-safety.md), section 13.

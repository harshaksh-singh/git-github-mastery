# V026: Lightweight tags, branch names, and stale branches

- **Part.** 1: Foundations
- **Module.** 4
- **Planned minutes.** 22
- **Prerequisites.** V025
- **Textbook sections.** [Chapter 7: Branches](../../textbook/ch07-branches.md), sections 7.11 to 7.16
- **Demo scripts.** `labs/ch07/lightweight-tags.sh`, `labs/ch07/ref-name-conflict.sh`, `labs/ch07/case-trap.sh`, `labs/ch07/stale-branches.sh`, `labs/ch07/wrong-branch.sh`

## HOOK

**[ON SCREEN]** `cannot lock ref 'refs/heads/feature/login'`

Your CTO asks: "Why does every laptop in the team fail with `cannot lock ref 'refs/heads/feature/login'` since this morning?"

Nobody changed a setting. Nobody upgraded Git. One person pushed one branch with a perfectly reasonable name, and since then `git fetch`, the command that downloads what's new from the server, fails on every clone. What's your first guess? Say it out loud.

**[PAUSE]**

Somebody once created a branch named `feature`. And a ref, Git's word for a name that points at a commit, can't be both a name and a directory of names. That one rule about how refs are named explains the incident, and the fix is one command. This video is about refs as names: tags that don't move, names that collide, and names that nobody needs any more. Keep that error message in mind. You'll produce it yourself in the demo.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the last video on refs, and it's the practical one. Four topics.

Lightweight tags: a ref that doesn't move when you commit. Naming: what Git allows, what teams agree on, and the `feature` versus `feature/x` conflict. Stale branches: how to answer "which of our 340 branches can be deleted without losing anything". And the wrong-branch commit from video 22, repaired with two ref writes.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Show that a lightweight tag is a ref that does not move when you commit.
2. Explain why `feature` and `feature/x` cannot both exist, and what breaks for teammates.
3. Find branches that are merged, gone or old, and decide which may be deleted.
4. Recognize a commit made on the wrong branch as two ref writes, and plan the repair.

## CONCEPT

**[ANIMATION]** graph: 6eab4a9-69d8252 main v0.1.0; HEAD=main

**Lightweight tags.** In one sentence: a lightweight tag is a ref under `refs/tags/` that names an object directly. It's a label that is not expected to move. `git tag <name>` is 🟢 SAFE: it adds a ref. On screen, the tag `v0.1.0` and the branch `main` name the same commit.

An annotated tag, made with `-a`, is different: the ref names a tag object with its own ID, tagger, date and message. The manual reserves annotated tags for releases, and lightweight tags for "private or temporary object labels".

**[ANIMATION]** end

Tags have no reflog by default. A reflog is Git's local journal of where a name has pointed, and `core.logAllRefUpdates` creates reflogs for branches, remote-tracking branches, notes and HEAD, not for tags. So `git tag -f` and `git tag -d`, both 🟡 CAUTION, leave no trace except the "was" ID in their output. Write it down.

A branch and a tag with the same short name are legal and confusing. Git resolves a short name by trying `refs/tags/<name>` before `refs/heads/<name>`.

**Naming: conventions and rules.** A branch name is a path under `refs/heads/`, so slashes group branches: `feature/retry-backoff`, `fix/judge-timeout`, `release/0.2`. Lowercase names with hyphens avoid the case trap and need no quoting. Those are conventions.

The rules are Git's. It rejects names with a space, two consecutive dots, a tilde, a caret, a colon, a question mark, an asterisk, an opening bracket, a backslash, or a control character. It rejects a component that starts with a dot or ends with `.lock`, a trailing dot, the sequence `@{`, a leading or trailing slash, and a double slash. And a branch name may not start with a hyphen. No need to memorize the list: `git check-ref-format --branch <name>` tests a candidate without creating anything.

**The conflict.** One more rule follows from the path structure: a name can't be both a ref and the prefix of other refs. With the files backend, where a ref is a small file, the reason is visible: `refs/heads/feature` is a file, and `refs/heads/feature/login` would need a directory of the same name. But the rule is not a file-system accident. It holds for packed refs, and in a reftable repository, where there are no such files. Ref names form one hierarchy, and the rule keeps every ref name unambiguous.

**The case trap.** The default macOS volume format doesn't distinguish `main` from `MAIN`. With the files backend a loose ref is a file, so a wrong-case name finds the right file, and HEAD records the wrong name. The textbook notes that the reasons for making reftable the default in Git 3.0 include exactly this class of clash.

**Stale branches.** In one sentence: a stale branch is a ref that nobody needs any more, and Git offers three tests for it, each with a blind spot: age, reachability from `main`, and a deleted upstream.

Age says when the branch last changed, not whether its work landed. Reachability, `git branch --merged main`, can't see a squash merge: `main` then contains a new commit with the same tree and none of the branch's commits. A deleted upstream shows as `[gone]` in `git branch -vv` after `git fetch --prune`. The upstream is the server branch your branch follows, and that fetch is 🟡 CAUTION: it removes remote-tracking refs for branches the server no longer has.

On a team that deletes branches on the server after merging, `gone` is the most reliable signal. Its blind spot: a branch that was never pushed has no upstream and no `gone`.

For a squash-merged branch there is a proof that it's finished. `git merge-tree --write-tree main <branch>` prints the tree a merge would produce. If it equals the tree of `main`, merging the branch would change nothing, so `-D` is safe.

**[ON SCREEN]** "Version note: added in Git 2.56, not run here."

Git 2.56 adds `git branch --delete-merged <pattern>`. It deletes local branches whose configured upstream matches the pattern, but only when their tip is reachable from that upstream, with `--dry-run` to list them first. It's not run here: Git 2.55 reports the option as unknown. The textbook quotes two limits from the 2.56 manual. It skips a branch when its configured upstream ref no longer exists, so it doesn't handle `[gone]` branches. And a squash-merged branch is silently skipped.

**What deleting does and does not do.** Deleting a local branch deletes a name in your clone. It doesn't delete the commits, and it doesn't remove them from the server, from colleagues' clones or from a pull request. A branch deletion is never a way to withdraw content. And a detail that surprises people: a plain `git branch -d` can delete `main`. There is nothing special about the name.

**[ANIMATION]** graph: faf3622-6b3b610-478ecd8-cf0610c main; faf3622-6b3b610 origin/main; HEAD=main => faf3622-6b3b610-478ecd8-cf0610c main feature/judge-cache; faf3622-6b3b610 origin/main; HEAD=feature/judge-cache => faf3622-6b3b610-478ecd8-cf0610c feature/judge-cache; faf3622-6b3b610 main origin/main; HEAD=feature/judge-cache

**[ANIMATION]** step: state-1

**Commits on the wrong branch.** Because branches are refs, the repair takes two ref writes and copies nothing. Here, two commits sit on `main` that belong on a feature branch.

**[ANIMATION]** step: state-3

First, `git switch -c <feature>` creates a branch at the current commit and attaches HEAD to it. Then `git branch -f main origin/main`, 🟡 CAUTION, moves `main` back. The second is allowed once `main` is no longer checked out.

## MENTAL MODEL

A picture helps. Think of refs as files in folders, whatever the storage really is. `refs/heads/feature` is a file. `refs/heads/feature/login` is a file in a folder called `feature`. One name can't be a file and a folder at once.

That model explains the conflict. It also explains why a tag and a branch can share a short name: they're in different folders, `refs/tags/` and `refs/heads/`.

Where the model breaks is instructive. The storage is not always files: refs can be packed, or kept in reftable. The rule about names holds anyway, because it's a rule about the hierarchy of names. And on a case-insensitive file system the model becomes too literal. There, the folder can't tell `main` from `MAIN`, and Git's idea of the name and the file system's idea drift apart.

## DIAGRAM

**[DIAGRAM]** The root-cause box of section 7.12, one line at a time.

```text
Observed behavior : since this morning, git fetch fails on every laptop with "cannot lock ref 'refs/heads/feature/login'"
                    or reports "unable to update local ref" for origin/feature/login
Git state         : each clone still has refs/remotes/origin/feature from an earlier fetch; the server now has feature/login
Mechanism         : the fetch tries to create origin/feature/login while origin/feature exists, and a ref cannot be
                    a name and a prefix at the same time
Root cause        : a branch named "feature" was deleted on the server after branches under "feature/" were agreed on,
                    and nobody's clone was told about the deletion
Why Git does this : ref names form one hierarchy; the rule keeps every ref name unambiguous
Correct fix       : git fetch --prune (or git remote prune origin) deletes the stale origin/feature and the fetch succeeds
Prevention        : reserve top-level names for namespaces (feature/, fix/) and never create a plain branch with one of them
```

Read the "Git state" line twice. The conflict is not on the server. The server is consistent: it has `feature/login`, and no `feature`. The conflict is in each clone, between a stale remote-tracking ref and a new one.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch07/lightweight-tags.sh`.

```bash
labs/run ch07/lightweight-tags
```

`git tag v0.1.0` 🟢 SAFE.

<!-- snippet: ch07/lightweight-tags/01-a-ref -->
```text
$ git tag v0.1.0
$ cat .git/refs/tags/v0.1.0
69d82526af97115a79ad14d198c1ba24c22d5fb9
$ git cat-file -t v0.1.0
commit
$ git for-each-ref
69d82526af97115a79ad14d198c1ba24c22d5fb9 commit	refs/heads/main
69d82526af97115a79ad14d198c1ba24c22d5fb9 commit	refs/tags/v0.1.0
```
<!-- /snippet -->

The tag file holds the commit ID, and `git cat-file -t` on the tag name reaches the commit: no object was created. Now one more commit. Predict where the tag is afterwards. Say it out loud.

**[PAUSE]**

<!-- snippet: ch07/lightweight-tags/02-does-not-move -->
```text
$ git log --oneline --decorate
e09c144 (HEAD -> main) Add batch runner
69d8252 (tag: v0.1.0) Add exact-match metric
6eab4a9 Add README
```
<!-- /snippet -->

The branch moved, and the tag did not.

<!-- snippet: ch07/lightweight-tags/03-annotated-contrast -->
```text
$ git tag -a v0.2.0 -m "Release 0.2.0"
$ git cat-file -t v0.2.0
tag
$ git rev-parse v0.2.0 'v0.2.0^{commit}' HEAD
f850d5e1360ebcb51575a79519e389642a005ad3
e09c14440a4310ac2cb3110c0a778b2f2ec34e0f
e09c14440a4310ac2cb3110c0a778b2f2ec34e0f
```
<!-- /snippet -->

The contrast: an annotated tag is an object of type `tag` with its own ID, and `v0.2.0^{commit}` peels it to the commit.

<!-- snippet: ch07/lightweight-tags/04-no-reflog -->
```text
$ ls .git/logs/refs
heads
$ git tag v0.1.0 HEAD
fatal: tag 'v0.1.0' already exists
[exit status: 128]
$ git tag -f v0.1.0 HEAD
Updated tag 'v0.1.0' (was 69d8252)
$ git tag -d v0.1.0
Deleted tag 'v0.1.0' (was e09c144)
```
<!-- /snippet -->

`.git/logs/refs` has a `heads` directory and no `tags` directory. `git tag -f` 🟡 CAUTION and `git tag -d` 🟡 CAUTION print the "was" ID, and that is all the record there is.

Quick quiz. The next step creates a branch named like the tag, `v0.2.0`. Which one does the short name mean? A, the branch. B, the tag. C, Git refuses. Your answer?

**[PAUSE]**

<!-- snippet: ch07/lightweight-tags/05-ambiguous -->
```text
$ git branch v0.2.0 HEAD~1
$ git log -1 --format='%h %s' v0.2.0
warning: refname 'v0.2.0' is ambiguous.
e09c144 Add batch runner
$ git log -1 --format='%h %s' heads/v0.2.0
69d8252 Add exact-match metric
$ git branch -D v0.2.0
Deleted branch v0.2.0 (was 69d8252).
```
<!-- /snippet -->

B. A branch named like the tag: the short name means the tag, with a warning. `heads/v0.2.0` and `tags/v0.2.0` are unambiguous. The script removes the branch with `-D` 🔴 DANGEROUS. The branch pointed at a commit that `main` reaches, so no commit loses its last name.

**[TERMINAL]** Caption bar: `labs/ch07/ref-name-conflict.sh`.

```bash
labs/run ch07/ref-name-conflict
```

A branch named `feature` exists. Predict what `git branch feature/login` does. Say it out loud.

**[PAUSE]**

<!-- snippet: ch07/ref-name-conflict/01-conflict -->
```text
$ git branch feature
$ git branch feature/login
fatal: cannot lock ref 'refs/heads/feature/login': 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
[exit status: 128]
$ ls .git/refs/heads
feature
main
```
<!-- /snippet -->

`cannot lock ref`: `refs/heads/feature` exists, so `refs/heads/feature/login` can't be created. There it is: the message from the hook, made with two commands.

<!-- snippet: ch07/ref-name-conflict/02-not-only-files -->
```text
$ git pack-refs --all
$ ls .git/refs/heads
$ git branch feature/login
fatal: 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
[exit status: 128]
$ git init -q --ref-format=reftable ../reftable-repo
$ git -C ../reftable-repo commit -q --allow-empty -m "Start"
$ git -C ../reftable-repo branch feature
$ git -C ../reftable-repo branch feature/login
fatal: 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
[exit status: 128]
```
<!-- /snippet -->

After `git pack-refs --all` there is no loose file in the way, and the branch is still refused. And in a repository created with the reftable format, the same.

<!-- snippet: ch07/ref-name-conflict/03-other-direction -->
```text
$ git branch -m feature feature/base
$ git branch feature/login
$ git branch feature
fatal: cannot lock ref 'refs/heads/feature': 'refs/heads/feature/base' exists; cannot create 'refs/heads/feature'
[exit status: 128]
$ git branch
  feature/base
  feature/login
* main
```
<!-- /snippet -->

The fix is a rename, `git branch -m` 🟡 CAUTION. And the rule holds in the other direction: with `feature/base` in place, a plain `feature` is refused.

Try it now. Thirty seconds, on paper. Four candidate names: `fix bug`, `fix..bug`, `fix/judge.lock` and `fix/judge-timeout`. Which does Git accept? Say your answer out loud.

**[PAUSE]**

<!-- snippet: ch07/ref-name-conflict/04-invalid-names -->
```text
$ git branch 'fix bug'
fatal: 'fix bug' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
[exit status: 128]
$ git check-ref-format --branch fix..bug
fatal: 'fix..bug' is not a valid branch name
[exit status: 128]
$ git check-ref-format --branch fix/judge.lock
fatal: 'fix/judge.lock' is not a valid branch name
[exit status: 128]
$ git check-ref-format --branch fix/judge-timeout
fix/judge-timeout
[exit status: 0]
```
<!-- /snippet -->

Only the last one passes. A space, two consecutive dots, and a component that ends with `.lock` are all on the list.

<!-- snippet: ch07/ref-name-conflict/05-full-name-trap -->
```text
$ git branch refs/heads/fix/judge-timeout
$ git for-each-ref --format='%(refname)' refs/heads
refs/heads/feature/base
refs/heads/feature/login
refs/heads/main
refs/heads/refs/heads/fix/judge-timeout
$ git branch -D refs/heads/fix/judge-timeout
Deleted branch refs/heads/fix/judge-timeout (was 6eab4a9).
```
<!-- /snippet -->

Then a name that is legal and wrong. `git branch refs/heads/fix/judge-timeout` created `refs/heads/refs/heads/fix/judge-timeout`, because `git branch` takes a short name and prepends `refs/heads/` itself.

**[DIAGRAM]** Show the root-cause box.

**[TERMINAL]** Caption bar: `labs/ch07/case-trap.sh`.

```bash
labs/run ch07/case-trap
```

<!-- snippet: ch07/case-trap/01-wrong-case -->
```text
$ git config get core.ignoreCase
true
$ git switch MAIN
Switched to branch 'MAIN'
$ cat .git/HEAD
ref: refs/heads/MAIN
$ git branch
  main
$ git status
On branch MAIN
nothing to commit, working tree clean
```
<!-- /snippet -->

`git switch MAIN` succeeded. HEAD says `refs/heads/MAIN`, and `git branch` lists `main` without an asterisk. The current branch is not in the list.

<!-- snippet: ch07/case-trap/02-commit -->
```text
$ printf '\nRun the tests with: python -m pytest\n' >> README.md
$ git commit -am "Document how to run the tests"
[MAIN 6e419d0] Document how to run the tests
 1 file changed, 2 insertions(+)
$ git log --oneline --decorate
6e419d0 (HEAD, main) Document how to run the tests
6eab4a9 Add README
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
6e419d0 refs/heads/main
```
<!-- /snippet -->

A commit in this state moves the file that exists. `git log --decorate` prints `(HEAD, main)` rather than `(HEAD -> main)`.

<!-- snippet: ch07/case-trap/03-fix -->
```text
$ git switch main
Switched to branch 'main'
$ git branch
* main
$ git log --oneline --decorate -1
6e419d0 (HEAD -> main) Document how to run the tests
```
<!-- /snippet -->

Switching to the correctly spelled name repairs it, and nothing was lost.

<!-- snippet: ch07/case-trap/04-two-names -->
```text
$ git branch Main
fatal: a branch named 'Main' already exists
[exit status: 128]
$ git pack-refs --all
$ git branch Main
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
6e419d0 refs/heads/Main
6e419d0 refs/heads/main
```
<!-- /snippet -->

Once the refs are packed, the file system is out of the picture, and `Main` is created as a second ref. Two branches that differ only in case.

**[TERMINAL]** Caption bar: `labs/ch07/stale-branches.sh`.

```bash
labs/run ch07/stale-branches
```

<!-- snippet: ch07/stale-branches/01-by-date -->
```text
$ git for-each-ref --sort=committerdate --format='%(committerdate:short) %(authorname) | %(refname:short)' refs/heads
2026-06-30 Lab User | feature/rouge
2026-08-20 Lab User | wip/prompt-tuning
2026-08-31 Lab User | fix/empty-gold
2026-09-07 Lab User | main
$ git for-each-ref --sort=committerdate --exclude=refs/remotes/origin/HEAD --format='%(committerdate:short) %(authorname) | %(refname:short)' refs/remotes/origin
2026-03-12 Asha Rao | origin/spike/judge-cache
2026-06-30 Lab User | origin/feature/rouge
2026-08-31 Lab User | origin/fix/empty-gold
2026-09-07 Lab User | origin/main
$ git for-each-ref --sort=committerdate --format='%(committerdate:short) %(refname:short)' refs/remotes/origin | awk '$1 < "2026-07-01"'
2026-03-12 origin/spike/judge-cache
2026-06-30 origin/feature/rouge
```
<!-- /snippet -->

Test one, age: `git for-each-ref --sort=committerdate`.

<!-- snippet: ch07/stale-branches/02-merged -->
```text
$ git branch --merged main
  fix/empty-gold
* main
$ git branch --no-merged main
  feature/rouge
  wip/prompt-tuning
$ git branch -r --no-merged origin/main
  origin/feature/rouge
  origin/spike/judge-cache
```
<!-- /snippet -->

Test two, reachability. `--merged main` lists `fix/empty-gold`, merged with a merge commit. `feature/rouge` is missing, although its content is in `main`: it was squash-merged.

<!-- snippet: ch07/stale-branches/03-gone -->
```text
# The two merged branches have been deleted on the server.
$ git fetch --prune
From $LAB/ch07/stale-branches/origin
 - [deleted]         (none)     -> origin/feature/rouge
 - [deleted]         (none)     -> origin/fix/empty-gold
$ git branch -vv
  feature/rouge     842be74 [origin/feature/rouge: gone] ROUGE-L: return a float
  fix/empty-gold    cad8f2c [origin/fix/empty-gold: gone] Exact match: handle empty gold answer
* main              00b2e49 [origin/main] Add CI workflow
  wip/prompt-tuning 9287f33 WIP: stricter judge prompt
$ git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads
feature/rouge [gone]
fix/empty-gold [gone]
main 
wip/prompt-tuning 
```
<!-- /snippet -->

Test three: `git fetch --prune` 🟡 CAUTION, then `[gone]` in `git branch -vv`. `wip/prompt-tuning` was never pushed, so it has no upstream and no `gone`.

Predict which of the two finished branches `git branch -d` 🟡 CAUTION will delete. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch07/stale-branches/04-squash-merged -->
```text
$ git branch -d fix/empty-gold
Deleted branch fix/empty-gold (was cad8f2c).
$ git branch -d feature/rouge
error: the branch 'feature/rouge' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/rouge'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git merge-tree --write-tree main feature/rouge
1442f02427f21cdc85e98b91d69535929f65e7ab
$ git rev-parse 'main^{tree}'
1442f02427f21cdc85e98b91d69535929f65e7ab
$ git branch -D feature/rouge
Deleted branch feature/rouge (was 842be74).
```
<!-- /snippet -->

It deletes the merge-commit branch and refuses the squash-merged one. Its upstream is gone, so Git falls back to HEAD, and finds commits that `main` can't reach. The `git merge-tree` comparison proves that merging the branch would change nothing.

<!-- snippet: ch07/stale-branches/05-git-2-56 -->
```text
$ git branch --delete-merged 'origin/*' 2>&1 | head -n 1
error: unknown option `delete-merged'
```
<!-- /snippet -->

And Git 2.55's answer to the 2.56 option: unknown.

**[TERMINAL]** Caption bar: `labs/ch07/wrong-branch.sh`.

```bash
labs/run ch07/wrong-branch
```

<!-- snippet: ch07/wrong-branch/01-symptom -->
```text
$ git status -sb
## main...origin/main [ahead 2]
 M README.md
$ git log --oneline --decorate
cf0610c (HEAD -> main) Add cached() helper
478ecd8 Cache judge responses in memory
6b3b610 (origin/main) Add judge client
faf3622 Add README
```
<!-- /snippet -->

Two commits on `main` that belong on a feature branch, and a third, uncommitted edit. `[ahead 2]` says the commits are local only, so the repair is private. Plan it before you see it: which two refs must be written? Say them out loud.

**[PAUSE]**

<!-- snippet: ch07/wrong-branch/02-two-ref-writes -->
```text
$ git switch -c feature/judge-cache
Switched to a new branch 'feature/judge-cache'
$ git branch -f main origin/main
branch 'main' set up to track 'origin/main'.
$ git log --oneline --decorate
cf0610c (HEAD -> feature/judge-cache) Add cached() helper
478ecd8 Cache judge responses in memory
6b3b610 (origin/main, main) Add judge client
faf3622 Add README
$ git status -sb
## feature/judge-cache
 M README.md
```
<!-- /snippet -->

`git switch -c feature/judge-cache` 🟢 SAFE: the index and working tree are untouched, so the uncommitted edit comes along. `git branch -f main origin/main` 🟡 CAUTION moves `main` back to the published commit. Nothing was copied.

<!-- snippet: ch07/wrong-branch/03-what-moved -->
```text
$ git reflog show main -2
6b3b610 main@{0}: branch: Reset to origin/main
cf0610c main@{1}: commit: Add cached() helper
$ git reflog -1
cf0610c HEAD@{0}: checkout: moving from main to feature/judge-cache
$ git branch -vv
* feature/judge-cache cf0610c Add cached() helper
  main                6b3b610 [origin/main] Add judge client
```
<!-- /snippet -->

The reflogs record both writes.

## COMMON MISTAKES

Five mistakes to watch for.

1. **`cannot lock ref 'refs/heads/feature/x'`.** Root cause: a branch named `feature` exists, and a name cannot be a ref and a prefix of refs.
2. **`git fetch` fails with "unable to update local ref".** Root cause: a stale `origin/feature` in the clone blocks the new `origin/feature/...`; `git fetch --prune` removes it.
3. **`git branch -d` refuses although the branch "was merged".** Root cause: a squash merge put the content, not the commits, into `main`, and the upstream is gone, so `-d` tests against HEAD.
4. **`git branch` shows no asterisk.** Root cause: a wrong-case name was accepted on a case-insensitive file system, and HEAD records that name; check `cat .git/HEAD`.
5. **Deleting a branch to withdraw content.** Root cause: deletion removes a name, not commits, and nothing on the server, in other clones or in a pull request.

## PRODUCTION EXAMPLE

Now, out of the lab, to the CTO's 340 branches. Deleting the branch on the server is a push, and affects everyone's next prune. Before that, the textbook's procedure: apply the three tests, and for each candidate run `git log --oneline main..<branch>`. If that range is empty, or every commit in it is squash-merged, nothing is lost.

A team that deletes branches on the server in the same step as the merge keeps the list short, and gets `[gone]` as a reliable local signal. And the textbook's prevention for the morning's incident: `fetch.prune=true` on a team that uses namespaces, and top-level names reserved for namespaces.

## PRACTICE EXERCISE

Your turn. Do Lab 4.3, "The `feature` versus `feature/x` conflict", in [`lab-manual/m04-refs-branches-head.md`](../../lab-manual/m04-refs-branches-head.md).

The lab runs the incident from both sides. Before the fetch that fails, list the refs in the clone and on the server, and predict the exact ref that the fetch will not be able to create.

## INTERVIEW QUESTION

Q109: "Why does `git fetch` fail on every clone after someone pushes `feature/login`, and what is the one-command fix?"

**[PAUSE]**

Answer out loud. A strong answer places the conflict in the right repository, names the two refs involved and the rule they break, and says why the rule is not a quirk of files on disk. Give the fix, and then the prevention.

## RECAP

**[ANIMATION]** graph: 6eab4a9-69d8252-e09c144 main; 6eab4a9-69d8252 v0.1.0; HEAD=main

Let's land this. You should now be able to say: a lightweight tag is a ref under `refs/tags/` that points at a commit and does not move when I commit. Tags have no reflog by default. Ref names form one hierarchy, so `feature` and `feature/x` can't both exist, in any ref storage. A stale `origin/feature` breaks fetch until I prune. On a case-insensitive file system, a wrong-case branch name can be accepted and recorded in HEAD. Three tests find stale branches: age, reachability from `main`, and a gone upstream. A squash merge defeats reachability. And a commit on the wrong branch is repaired with two ref writes.

## HOMEWORK

- Read sections 7.11 to 7.16 of [Chapter 7](../../textbook/ch07-branches.md), and do the Practice section 7.18.
- Do Exercise 4.3, Level 1, "a lightweight tag is a ref that does not move", and Exercise 4.8, Level 3, "the deploy script that picks the wrong commit", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
- Challenge: Exercise 4.9, Level 4, "three commits on the wrong branch", in the same file.

You can now read an error about names as a statement about one hierarchy, and that calms a whole team on a bad morning. Do the lab: making the failure yourself is the quickest way to stop fearing it. Next time: configuration, with its scopes, its precedence, and how to read and write settings. Until then, look at the state first and type second. See you in the next one.

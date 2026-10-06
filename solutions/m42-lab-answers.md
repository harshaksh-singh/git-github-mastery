# Module 42 lab answers: the frontier

Answers to the "Questions" of Labs 42.1 to 42.3 in [the Module 42 lab manual](../lab-manual/m42-frontier.md). Write your own answers before you read these.

## Lab 42.1: SHA-256 and reftable repositories

1. `objectformat = sha256` and `refstorage = reftable` in the section `[extensions]`. An extension is honored only when `core.repositoryformatversion` is 1, and a Git version that does not know an extension listed there refuses to use the repository. That is the purpose: an old Git must stop with an error and not misread 64-digit IDs or look for ref files that do not exist.

2. `git fetch` copies objects as they are, and every commit and tree contains the IDs of other objects. An object hashed with SHA-1 cannot be placed into a SHA-256 object database, and its internal references would name objects that do not exist there. `fast-export` does not send objects. It sends a description (file contents, authors, dates, messages, and marks that stand for "the commit I described earlier"), and `fast-import` builds new objects from the description with the receiving repository's hash.

3. Any three of: CI configuration and deployment manifests that pin a commit; issue and pull-request comments; commit messages that quote other commits (`This reverts commit ...`, `cherry picked from commit ...`); release notes and changelogs; `.git-blame-ignore-revs` files; submodule pointers in other repositories; signed tags and signed commits, whose signatures cover the old content; container image labels and build metadata.

4. `Not a directory`: the script read `.git/refs/heads/main`, assuming that a branch is a file. After `git refs migrate --ref-format=reftable` the refs are records in `.git/reftable/`, and `.git/refs/heads` is a placeholder file. `not a commit ID`: the script checked for exactly forty hexadecimal digits, assuming SHA-1. The single fix is to ask Git with `git rev-parse --verify 'refs/heads/main^{commit}'`, which is independent of both the ref backend and the hash.

5. The ref format is a way of storing a small table of names and values. The values do not change, so the table can be written in another layout and back. The object format determines the name of every object and the content of every tree and commit, which contain names. Changing it means creating different objects, which is a different history.

6. Roll out `init.defaultBranch=main` and `safe.bareRepository=explicit`: both are independent of the host and match what 3.0 will do. Hold back `init.defaultObjectFormat=sha256`, because a SHA-256 repository cannot be pushed to github.com today. `init.defaultRefFormat=reftable` is a local matter and would work with GitHub, but hold it back as a team-wide default until every tool that opens your working copies (IDE plugins and other tools built on libgit2 or JGit) is known to read reftable; individuals can opt in per repository.

## Lab 42.2: `git history reword`

1. `--update-refs=head` moves only the current HEAD. `topic/judge` would have stayed on the old commits, so the graph would have forked below the reworded commit: `main` on the new `Add recall metric` and `Add README`, and `topic/judge` on the old pair plus `Add judge prompt`, with the pushed `Add F1` as the common ancestor. Two copies of the same two changes: the duplicate-commit situation of Chapter 9, created locally.

2. A commit ID is a hash of the commit's content, and that content includes the ID of the parent. The reworded commit has a new ID because its message changed. Its child names it as parent, so the child's content changed, and so on up to every tip. Trees and blobs were reused.

3. It wrote the new commit objects into the object database. It did not write any ref, any reflog entry, the index or the working tree. The objects are unreachable until a ref points at them, and the printed `update` lines are what would make them reachable.

4. `git branch -r --contains HEAD~2` listed `origin/main`. The rule: before rewriting a commit, check whether any remote-tracking branch contains it; if one does, other people may have it, and the rewrite needs their agreement and a force push, or should not happen. (After a `git fetch`, so that the remote-tracking branches are current.)

5. The reflog of `main` had three relevant entries: `main@{0}` after the unwanted reword, `main@{1}` after the wanted one (typo fixed), `main@{2}` before both. `main@{1}` keeps the typo fix and drops the rewrite of the pushed commit. `main@{2}` would also have thrown away the wanted change. `ORIG_HEAD` is no help: in a test on Git 2.55.0 `git history reword` did not write it, so it still held the value of some earlier operation. The reflog of each branch is the dependable record.

6. No. The manual says that `git history` does not execute hooks, and the chapter's demo `ch14d/history` shows a `commit-msg` hook that refuses every message while a reword goes through. A rule enforced only by a client-side hook therefore does not cover commits rewritten with this command.

## Lab 42.3: A format-patch and am round trip

1. `From: Name <email>` becomes the author; `Date:` becomes the author date; `Subject:` without the bracketed prefix becomes the subject line; the text between the headers and the `---` line becomes the body of the message, including trailers such as `Signed-off-by`. `[PATCH 1/2]` is removed by `git am`. The diffstat between `---` and the first `diff --git` is for human readers and is ignored, as is anything else in that place, which is why reviewers put notes there that should not enter history. The committer and the committer date come from the person and the time of `git am`. The first line, `From <id> Mon Sep 17 00:00:00 2001`, marks the mailbox format; the ID in it is not used to create the commit.

2. The committer name and e-mail (Ravi Menon in place of Lab User) and the committer date. The parent of the first applied commit is the same commit in both repositories, the trees are equal, and the author fields were copied. A different committer is enough to change the ID of the first commit, and the second differs at least in its parent.

3. Without `-3`, `git am` applies the patch like `git apply`: the context lines must match the file. They did not, so the patch was rejected as a whole and nothing was written. `-3` uses the `index <old>..<new>` line of the patch: if the blob `<old>` exists in the repository, Git reconstructs the tree the patch was made against, applies the patch there, and merges the result with the current tree, which can produce ordinary conflict markers. It fails when the base blob is unknown to the receiving repository, for example when the patch was made on top of commits the maintainer does not have.

4. `--abort` ends the session and restores the branch to where it was before `git am` started. `--skip` drops the current patch and goes on with the next one. `--continue` commits the current patch from what you have staged and goes on. In the failure scenario `--skip` would have skipped the tokenizer change and applied the README patch, leaving documentation for a behavior that was not applied.

5. `git apply` when you want the changes without the commits: to test whether a patch applies (`--check`), to look at it (`--stat`), to apply a diff that is not in mailbox format (the output of `git diff`), or to stage it with `--index` for a commit you will write yourself. `git am` when the patch files carry commits that should arrive as commits with their authors and messages.

6. Any two of: contributing to projects that work by mailing list (Git itself, the Linux kernel); moving commits between repositories that cannot reach each other, such as an air-gapped environment or a customer's network; receiving a fix from a vendor or a security researcher before it may appear in a public repository; carrying local patches on top of an upstream release in a packaging workflow; attaching a proposed change to a ticket for someone without access to your hosting.

# V021: Amend, empty commits, trailers, messages and atomic commits

- **Part.** 1: Foundations
- **Module.** 3
- **Planned minutes.** 26
- **Prerequisites.** V020
- **Textbook sections.** [Chapter 6: Commits](../../textbook/ch06-commits.md), sections 6.7 to 6.15
- **Demo scripts.** `labs/ch06/amend.sh`, `labs/ch06/amend-pushed.sh`, `labs/ch06/empty-commit.sh`, `labs/ch06/trailers.sh`, `labs/ch06/message-craft.sh`, `labs/ch06/atomic.sh`, `labs/ch06/signed-header.sh` (volatile: a fresh key on every run)

## HOOK

**[ON SCREEN]** `! [rejected]  main -> main (non-fast-forward)`

An engineer pushes a commit, notices a typo in the message, fixes it with `git commit --amend`, and pushes again. The push is rejected. Git prints a hint: use `git pull` before pushing again.

They pull. Now the history has the old commit, the new commit, and a merge of the two: two versions of one change, joined together, on a shared branch.

**[PAUSE]**

The hint was the wrong advice for this situation, and following it made things worse. To see why, you need one fact: amend does not edit a commit. It creates a sibling. This video is about that fact, and about what makes a commit good enough that you rarely need to amend it.

## INTRODUCTION

This video closes the block on commits with five practical topics.

`git commit --amend`: what it creates, and where the old commit goes. Empty commits. Trailers: structured lines at the end of a message that tools can parse. How Git reads a message, and how to write one. And atomic commits: commits that can be reverted one by one. At the end, a short look at where a signature is stored, as a preview of the part on security.

## LEARNING OBJECTIVES

After this video you can:

1. Show that `git commit --amend` creates a new commit, and find the old one.
2. Predict what happens when an amended commit had already been pushed.
3. Write trailers that Git recognizes, and query them.
4. Split work into atomic commits, and justify the split by what a revert would do.
5. Say where a signature is stored in a commit object.

## CONCEPT

**Amend.** In one sentence: `git commit --amend` writes a new commit that takes the place of the current one: same parent, new tree and message as you choose, new ID. It is 🟡 CAUTION.

The manual's description is "Replace the tip of the current branch by creating a new commit", and "The new commit has the same parents and author as the current one". The old commit is neither modified nor deleted. The branch stops pointing at it, and only reflog entries still refer to it.

**[ON SCREEN]** The state table of section 6.7: working tree unchanged; index entries unchanged, and they become the tree of the new commit; HEAD unchanged, resolves to the new commit; current branch ref set to the new commit, whose parent is the old commit's parent; new commit object, old commit kept, reflog lines `commit (amend)`; remote unchanged, but if the old commit was pushed, branch and upstream now diverge.

**How long the old commit survives.** By default, a reflog entry that is not reachable from the current tip expires after 30 days, and any other entry after 90. An object that no ref and no reflog entry refers to is pruned by maintenance once it is more than two weeks old. The lab configuration sets the two reflog values to `never`, so replays do not depend on the calendar.

**When to amend, and when not.** Amend freely while a commit exists only in your repository. `--no-edit` keeps the message, `--only` leaves staged changes out, and `--reset-author` repairs a wrong identity. Remember that everything staged goes into an amend unless you say `--only`. Do not amend what others may have: on a shared branch an amend produces a divergence for every colleague. And an amend does not delete anything: a secret committed and then amended away is still in the old commit, in your reflog, and on the server if it was pushed. Rotate the secret.

**Empty commits.** An empty commit has the same tree as its parent: a point in history with a message and no change. Without `--allow-empty`, Git refuses. The manual says the option "is primarily for use by foreign SCM interface scripts". Teams use it to start a push-triggered pipeline without touching a file. Two cautions from the textbook: a pipeline filtered by changed paths has no path to match, so an empty commit may not start it; and the commit stays in history. Empty commits are permanent.

**Trailers.** In one sentence: a trailer is a `Key: value` line in the last paragraph of a commit message: ordinary text, placed where Git and other tools can find and parse it. `git commit -s` adds a `Signed-off-by` trailer with the committer's identity, and `--trailer` adds any other. The trailers are part of the message, so they are part of the commit object and of its ID.

The rules. Git recognises a trailer block only at the end of the message, after an empty line. Every line of the block must be a trailer, unless at least a quarter of the lines are, and one of them has a key that Git generates itself, such as `Signed-off-by`, or a key defined in your configuration.

What they mean. `Signed-off-by`: a statement defined by the project, commonly the Developer Certificate of Origin. It is text, not a cryptographic signature. `Co-authored-by`: credit for a further author; Git only stores the line. Others such as `Reviewed-by`, `Refs` and `Fixes` mean whatever your team defines.

**[ON SCREEN]** Lower third: **GitHub**. GitHub reads `Co-authored-by` trailers to attribute a commit to multiple authors, with an email address associated with each co-author's account. That is GitHub's behavior, described from its documentation.

Version notes from the textbook. `git commit --trailer` exists since Git 2.32. `git shortlog --group=trailer:<key>` since Git 2.29. And up to Git 2.55 the trailer parser can take a line that begins with a URL for a trailer; Git 2.56 no longer does. That last one is "added in Git 2.56, not run here".

**How Git reads a message.** Two rules matter. First, the title is the text up to the first empty line, not the first line. Without the empty line, your body becomes part of the title. Second, when a message passes through the editor, lines that begin with `#` are comments and are removed. Do not start a line with `#`.

**Craft, with the reasons.**

**[ON SCREEN]** The craft table of section 6.10.

A title of about 50 characters without a full stop: because, in the manual's words, "that title is used throughout Git": one-line logs, shortlog, branch listings, reflogs, mail subjects and patch file names. An empty line, then the body. Imperative mood, "Retry judge calls", not "Retried": the Git project asks for it, "as if you are giving orders to the codebase". The body states the problem and why this solution: the diff shows what changed; nothing else records why. Lines of at most about 72 characters: Git does not re-wrap. And machine-readable facts as trailers.

Team conventions such as Conventional Commits add a pattern to the title; they are agreements on top of Git, enforced by hooks or CI if at all.

**Atomic commits.** An atomic commit contains one logical change, complete enough that the project still builds and passes its tests. The Git project's rule: "Make separate commits for logically separate changes". The test of a good split is what a revert would do. `git revert` is 🟡 CAUTION: it adds one commit that applies the inverse change.

**Signatures.** A signed commit carries its signature inside the commit object, in a `gpgsig` header between the committer line and the message. Because it is inside the object, it is covered by the commit ID, and signing a commit that already exists means writing a new commit. Do not confuse the two options: capital `-S` signs with a key; small `-s` adds the `Signed-off-by` text.

## MENTAL MODEL

For amend, forget the word "edit". Picture a fork with two short prongs. Both prongs grow from the same parent. One is the commit you made first. The other is the commit amend made. The branch label is moved from the first prong to the second. Nothing is erased.

Now read the hook with that picture. The server holds the first prong. You hold the second. Your branch is one commit ahead and one commit behind at the same time. A pull merges the prongs. That is why the hint is wrong here.

The model's limit: the first prong is not permanent. It is kept by reflog entries, and those expire. So "nothing is erased" is true today and has a time limit.

## DIAGRAM

**[DIAGRAM]** The diagram of section 6.7: the old commit and the amended commit as siblings under one parent, with the branch label on the new one.

```text
             831f9ff  "Add F1 metrc"     reachable only from HEAD@{1} and main@{1}
            /
  d4c9fab--+
            \
             8f6fa22  "Add F1 metric"    main   (HEAD -> main)
```

One parent, `d4c9fab`. Two children. The upper one, `831f9ff`, has the typo, and is reachable only from the reflog entries `HEAD@{1}` and `main@{1}`. The lower one, `8f6fa22`, carries the branch label. No arrow leads from one sibling to the other: the new commit does not know the old one existed.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch06/amend.sh`.

```bash
labs/run ch06/amend
```

<!-- snippet: ch06/amend/01-mistake -->
```text
$ git add evalkit/metrics.py
$ git commit -m "Add F1 metrc"
[main 831f9ff] Add F1 metrc
 1 file changed, 4 insertions(+)
$ git status --short
?? tests/
$ git log --oneline
831f9ff Add F1 metrc
d4c9fab Add exact-match metric
```
<!-- /snippet -->

A commit with a typo in its message, and a forgotten test file. `git commit --amend` 🟡 CAUTION. Predict: after the amend, how many commits does `git log` show, and what is the ID of the tip?

<!-- snippet: ch06/amend/02-amend -->
```text
$ git add tests/test_metrics.py
$ git commit --amend -m "Add F1 metric"
[main 8f6fa22] Add F1 metric
 Date: Mon Sep 7 10:05:00 2026 +0530
 2 files changed, 9 insertions(+)
 create mode 100644 tests/test_metrics.py
$ git log --oneline
8f6fa22 Add F1 metric
d4c9fab Add exact-match metric
```
<!-- /snippet -->

Still two commits. The log shows `8f6fa22` where `831f9ff` was. The `Date:` line in the summary is the author date, carried over by the amend. Where is `831f9ff` now?

**[PAUSE]**

<!-- snippet: ch06/amend/03-two-objects -->
```text
$ git reflog
8f6fa22 HEAD@{0}: commit (amend): Add F1 metric
831f9ff HEAD@{1}: commit: Add F1 metrc
d4c9fab HEAD@{2}: commit (initial): Add exact-match metric
$ git cat-file -p 'HEAD@{1}'
tree 29b018434273c541b9fce4dfc1e29fb92a358447
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Add F1 metrc
$ git cat-file -p HEAD
tree 304b1d11e74d6497529760e3c17e94c881773561
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755940 +0530

Add F1 metric
```
<!-- /snippet -->

In the reflog, one entry down. `git cat-file -p 'HEAD@{1}'` prints the old object: same `parent`, same `author` line; different `tree`, `committer` time and message. Two commits that share a parent.

<!-- snippet: ch06/amend/04-reachability -->
```text
$ git branch --contains 'HEAD@{1}'
$ git log --oneline --all
8f6fa22 Add F1 metric
d4c9fab Add exact-match metric
$ git fsck --no-reflogs
dangling commit 831f9ff6c0dc934d7528503ecc13565dfe506791
```
<!-- /snippet -->

No branch contains the old commit, and `git log --all` does not list it. `git fsck --no-reflogs` reports it as dangling: only the reflog still refers to it.

<!-- snippet: ch06/amend/05-keep-it -->
```text
$ git branch before-amend 'HEAD@{1}'
$ git log --oneline --graph --all
* 8f6fa22 Add F1 metric
| * 831f9ff Add F1 metrc
|/  
* d4c9fab Add exact-match metric
```
<!-- /snippet -->

Give it a name with `git branch` 🟢 SAFE, and it is an ordinary commit again. The graph now shows the fork.

**[TERMINAL]** Caption bar: `labs/ch06/amend-pushed.sh`.

```bash
labs/run ch06/amend-pushed
```

The commit has been pushed. Then it is amended. Predict what `git status -sb` says about `main` and `origin/main`.

<!-- snippet: ch06/amend-pushed/01-diverged -->
```text
$ git status -sb
## main...origin/main
$ git commit --amend -m "Exact match: strip whitespace"
[main 4f33829] Exact match: strip whitespace
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --all
* 4f33829 Exact match: strip whitespace
| * f8456dc Exact match: strp whitespace
|/  
* 4279e65 Add exact-match metric
```
<!-- /snippet -->

`[ahead 1, behind 1]` is the diagnosis: your branch has the new commit, the upstream has the old one.

<!-- snippet: ch06/amend-pushed/02-push-rejected -->
```text
$ git push
To $LAB/ch06/amend-pushed/origin.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ch06/amend-pushed/origin.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

`git push` 🟡 CAUTION is rejected as a non-fast-forward, and the hint says to pull. Do not follow the hint: it would merge two versions of one commit. The textbook's two ways out: if others may have the published commit, return to it with `git reset --soft '@{u}'`, which is 🟡 CAUTION, and fix the mistake in a new commit. If the branch is yours alone, replace the published commit deliberately; that is a topic of Part 2.

**[TERMINAL]** Caption bar: `labs/ch06/empty-commit.sh`.

```bash
labs/run ch06/empty-commit
```

<!-- snippet: ch06/empty-commit/01-allow-empty -->
```text
$ git commit -m "Re-run the nightly evaluation"
On branch main
nothing to commit, working tree clean
[exit status: 1]
$ git commit --allow-empty -m "Re-run the nightly evaluation"
[main 6642d40] Re-run the nightly evaluation
$ git rev-parse 'HEAD^{tree}' 'HEAD~1^{tree}'
0fbd18cca19ea00c195639456eecd36debe578ab
0fbd18cca19ea00c195639456eecd36debe578ab
$ git show --stat --format=fuller HEAD
commit 6642d40c372fdf1e58fbcc287284a33ad528da84
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:05:00 2026 +0530

    Re-run the nightly evaluation
```
<!-- /snippet -->

Without the option, Git refuses with exit status 1. With it, the new commit and its parent have the same tree ID.

**[TERMINAL]** Caption bar: `labs/ch06/trailers.sh`.

```bash
labs/run ch06/trailers
```

<!-- snippet: ch06/trailers/01-write -->
```text
$ git add evalkit/judge.py
$ git commit -s -m 'Retry judge calls on HTTP 429' \
    -m 'The judge endpoint rate-limits bursts. Retry with exponential backoff, at most five attempts.' \
    --trailer 'Co-authored-by: Asha Rao <asha@example.com>' --trailer 'Refs: EVAL-212'
[main 7b588dd] Retry judge calls on HTTP 429
 1 file changed, 10 insertions(+)
 create mode 100644 evalkit/judge.py
$ git cat-file -p HEAD
tree a4e08def686cfbb567d5f427573310e3344a9056
parent 6eab4a90f8944518dce3aef708249b338e8f709a
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Retry judge calls on HTTP 429

The judge endpoint rate-limits bursts. Retry with exponential backoff, at most five attempts.

Signed-off-by: Lab User <you@example.com>
Co-authored-by: Asha Rao <asha@example.com>
Refs: EVAL-212
```
<!-- /snippet -->

`-s` and two `--trailer` options. Three trailers at the end of the message.

<!-- snippet: ch06/trailers/02-read -->
```text
$ git log -1 --format=%B | git interpret-trailers --parse
Signed-off-by: Lab User <you@example.com>
Co-authored-by: Asha Rao <asha@example.com>
Refs: EVAL-212
$ git log -1 --format='%(trailers:key=Refs,valueonly)'
EVAL-212

$ git log --oneline --grep='^Refs: EVAL-212'
7b588dd Retry judge calls on HTTP 429
$ git shortlog -sn --group=author --group=trailer:co-authored-by HEAD
     2	Lab User
     1	Asha Rao
```
<!-- /snippet -->

Three ways to read them back, and one to count by them: `git interpret-trailers --parse`, the `%(trailers)` format with a key, and `git shortlog` grouped by a trailer.

Now the rules, as five cases. For each input, predict whether Git finds the trailer.

**[PAUSE]**

<!-- snippet: ch06/trailers/03-rules -->
```text
# A trailer block is the last paragraph, and it must look like trailers.
$ printf 'Fix tokenizer\n\nRefs: EVAL-300\n' | git interpret-trailers --parse
Refs: EVAL-300
$ printf 'Fix tokenizer\nRefs: EVAL-300\n' | git interpret-trailers --parse
$ printf 'Fix tokenizer\n\nSee the design note.\nRefs: EVAL-300\n' | git interpret-trailers --parse
$ printf 'Fix tokenizer\n\nSee the design note.\nRefs: EVAL-300\n' | git -c trailer.ticket.key=Refs interpret-trailers --parse
Refs: EVAL-300
$ printf 'Fix tokenizer\n\nRefs: EVAL-300\n\nThanks to the platform team.\n' | git interpret-trailers --parse
```
<!-- /snippet -->

In order: recognised. No empty line before it: not recognised. A sentence inside the block: not recognised. The same with `Refs` configured as a key: recognised. Text after the block: not recognised.

**[TERMINAL]** Caption bar: `labs/ch06/message-craft.sh`.

```bash
labs/run ch06/message-craft
```

<!-- snippet: ch06/message-craft/01-message -->
```text
$ cat ../msg.txt
Retry judge calls on HTTP 429

Nightly evaluation runs failed about once a week with "judge rate
limit": the judge endpoint rejects bursts, and one rejected call
aborted the whole run after the generation step had already used
its GPU hours.

Retry up to five times with exponential backoff (1, 2, 4, 8, 16 s).
Other HTTP errors still fail at once, because retrying them would
hide real bugs.

Refs: EVAL-212
$ git commit -q -F ../msg.txt
$ git show -s --format=reference HEAD
6083abf (Retry judge calls on HTTP 429, 2026-09-07)
```
<!-- /snippet -->

A message that states the problem and why this solution, with trailers.

<!-- snippet: ch06/message-craft/02-where-the-title-is-used -->
```text
$ git log --oneline
24f43cf fix stuff
6083abf Retry judge calls on HTTP 429
6eab4a9 Add README
$ git shortlog HEAD
Asha Rao (1):
      fix stuff

Lab User (2):
      Add README
      Retry judge calls on HTTP 429

$ git branch -v
* main 24f43cf fix stuff
$ git reflog -2
24f43cf HEAD@{0}: commit: fix stuff
6083abf HEAD@{1}: commit: Retry judge calls on HTTP 429
```
<!-- /snippet -->

The title appears wherever Git needs one line for a commit. Compare it with the title of the commit above it, "fix stuff", in each of these listings.

<!-- snippet: ch06/message-craft/03-format-patch -->
```text
$ git format-patch -1 --stdout HEAD~1 | head -n 6
From 6083abf1acecb06ad1ccb415b8036c7dfb1229db Mon Sep 17 00:00:00 2001
From: Lab User <you@example.com>
Date: Mon, 7 Sep 2026 10:06:00 +0530
Subject: [PATCH] Retry judge calls on HTTP 429

Nightly evaluation runs failed about once a week with "judge rate
$ git format-patch -1 -o ../outbox HEAD~1
../outbox/0001-Retry-judge-calls-on-HTTP-429.patch
```
<!-- /snippet -->

And in a mail subject and a patch file name.

**[TERMINAL]** Caption bar: `labs/ch06/atomic.sh`.

```bash
labs/run ch06/atomic
```

<!-- snippet: ch06/atomic/01-two-commits -->
```text
$ git status --short
 M evalkit/metrics.py
 M requirements.txt
$ git add evalkit/metrics.py
$ git commit -q -m "Return 0.0 from F1 when no tokens overlap"
$ git add requirements.txt
$ git commit -q -m "Bump tokenizers to 0.21.0"
$ git log --oneline --stat -2
edc60de Bump tokenizers to 0.21.0
 requirements.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
4ea5f60 Return 0.0 from F1 when no tokens overlap
 evalkit/metrics.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

Two unrelated edits in the working tree, a bug fix and a dependency bump, committed separately. Then the new dependency breaks the nightly run. `git revert` 🟡 CAUTION. Predict what is left after reverting the tip.

<!-- snippet: ch06/atomic/02-revert-one -->
```text
# The new tokenizers release breaks the nightly run. Undo that change only.
$ git revert --no-edit HEAD
[main fb38675] Revert "Bump tokenizers to 0.21.0"
 Date: Mon Sep 7 10:10:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat requirements.txt
tokenizers==0.20.3
pyyaml==6.0.2
$ grep -n "common == 0" evalkit/metrics.py
4:    if common == 0:
```
<!-- /snippet -->

The dependency bump was undone, and the bug fix stayed, because they were two commits.

**[TERMINAL]** Caption bar: `labs/ch06/signed-header.sh`. On screen: "This demo creates a throwaway SSH key in the sandbox. The IDs and the signature differ on every run."

```bash
labs/run ch06/signed-header
```

<!-- snippet: ch06/signed-header/01-gpgsig -->
```text
$ git commit -q -S -m "Describe the project"
$ git cat-file -p HEAD
tree 5dca3a6e589a5d9b648e2563ac9c17bee742e961
parent 150744516440fbc2cc4197e81141ce63d5fa7cb2
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgeAvXs1QLvASH7oyGmTC81lgOeA
 6h9gfo2suPhirxoDgAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQMMcYH0dg+LhdIIe0rd3ubk6j0JVijcMdpjwjHWVTTO8y+/dNh80pVbiWWOPlTtXcO
 T8VhfAj9d5XxVa0EFx6gU=
 -----END SSH SIGNATURE-----

Describe the project
```
<!-- /snippet -->

The `gpgsig` header sits between the committer line and the message; continuation lines begin with a space. It is inside the object. Keys, verification and trust come later in the course.

## COMMON MISTAKES

1. **`git push` rejected after an amend, then a pull.** Root cause: the amend created a sibling of the published commit; the pull merges two versions of one commit.
2. **An amend swallowed unrelated staged changes.** Root cause: everything staged goes into an amend unless you say `--only`; run `git status` before amending.
3. **A line of the message is missing.** Root cause: the line began with `#` and the message went through the editor, where such lines are comments.
4. **`git log --oneline` shows a very long title.** Root cause: there is no empty line after the first line, and the title is the text up to the first empty line.
5. **A trailer is not found by tooling.** Root cause: it is not in the last paragraph, or a sentence shares its block; add trailers with `--trailer`, not by hand.

## PRODUCTION EXAMPLE

An evaluation team puts the ticket number and the evaluation-run ID of each change into trailers. The textbook's reason: a ticket number or a run ID in a trailer travels with the commit into every clone; a pull-request label does not. A year later, "which commits belong to this ticket?" is one `git log` format away, on any machine, with no network.

And the atomic split pays off on the night the new tokenizer release breaks the nightly run: one revert undoes the bump and leaves the bug fix. The same separation lets you cherry-pick the fix to a release branch, and lets `git bisect` stop on a commit small enough to read.

## PRACTICE EXERCISE

Do Lab 3.1, "Amend a commit and find the old one", in [`lab-manual/m03-commits.md`](../../lab-manual/m03-commits.md).

Before the amend, write down the ID of the tip and predict three things: whether that ID will still be printed by `git log`, by `git reflog`, and by `git branch --contains`. Then check each.

## INTERVIEW QUESTION

Q33: "After `git commit --amend`, where is the old commit, how long does it stay, and how do you get it back?"

Answer aloud. A strong answer says what still refers to the old commit and what no longer does, gives the default retention periods and what removes the object afterwards, and names the one-line recovery. Add what changes if the old commit had been pushed.

## RECAP

You should now be able to say: `git commit --amend` creates a new commit with the same parent; the old one stays in the object database, reachable only from the reflog, until its entries expire. If the old commit was pushed, my branch is one ahead and one behind, and I do not pull to fix that. A trailer is a `Key: value` line in the last paragraph of the message, and Git parses it only if the block follows the rules. The title is everything up to the first empty line, and tools use it everywhere. An atomic commit is one logical change that can be reverted alone. A signature lives in a `gpgsig` header inside the commit object.

## HOMEWORK

- Read sections 6.7 to 6.15 of [Chapter 6](../../textbook/ch06-commits.md), and do the Practice section 6.17, including Lab 3.3, "Trailers", in [`lab-manual/m03-commits.md`](../../lab-manual/m03-commits.md).
- Challenge: Exercise 3.9, Level 4, "a commit made on the meeting-room laptop", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

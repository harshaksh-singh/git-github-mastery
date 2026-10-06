# Module 3 labs: Commits

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch06/`. Read [Chapter 6: Commits](../textbook/ch06-commits.md) first.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and a replay script that runs the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch06/setup-03-1-amend.sh        # build the starting state (run again to start over)
labs/shell m03-1                          # open the isolated lab shell in that sandbox
labs/run ch06/lab-03-1-amend              # optional: replay the whole lab and print its transcript
```

Type the commands of a lab by hand, and predict before you run.

**Which IDs will match the book.** The setup scripts create their commits with the same fixed clock as the replays, so every commit that exists when you enter the sandbox has the ID printed here. A commit you create yourself gets the real time as its committer date and therefore another ID. Lab 3.2 is the exception that proves the rule: it pins the committer date by hand, and at that point your IDs equal the book's again.

**The lab clock.** Replays and setup scripts use a fixed clock in the past (7 September 2026), and the sandbox configuration they write sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never`. The lab shell uses the real clock, and its configuration carries the same two settings (Git's defaults are 90 days, and 30 days for unreachable entries); none of these labs runs `git gc`, so nothing here expires. Chapter 1, section 1.7 explains the design.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command to see its exit status.
- Lines that start with `#` are notes from a script, not output of Git.
- The commands below pass `-m`, `--no-edit` or `-F`, so no editor opens. If you leave one of those out, your editor opens with the proposed message; save and close it.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 3.1 | Amend a commit and find the old one | `m03-1` | `ch06/lab-03-1-amend` |
| 3.2 | Change only the committer date and watch the ID change | `m03-2` | `ch06/lab-03-2-committer-date` |
| 3.3 | Trailers | `m03-3` | `ch06/lab-03-3-trailers` |

Answers to the Questions of every lab are in [solutions/m03-lab-answers.md](../solutions/m03-lab-answers.md). Write your own answers first.

## Lab 3.1: Amend a commit and find the old one

### Objective

Amend a commit to fix its message and add a forgotten file, then prove that the original commit still exists and is reachable only through the reflog. Break a commit with an amend that swallows unrelated staged work, and repair it.

### Prerequisites

- Chapter 6, sections 6.3, 6.4 and 6.7.
- Chapter 5 for `git add` and `git restore --staged`.

### Setup

```bash
bash labs/ch06/setup-03-1-amend.sh
labs/shell m03-1
```

The script builds the repository `evalkit` with two commits. The second one, `f17f3d5 Add F1 metrc`, has a typo in its message and left `tests/test_metrics.py` untracked in the working tree.

### Commands

Step 1. Look at the starting state and note the ID of the commit you are about to replace.

```bash
cd evalkit
git log --oneline
git status --short
git rev-parse HEAD
```

Step 2. Stage the forgotten test file and amend. Predict first: will the amended commit have the same parent as `f17f3d5`? The same tree? The same ID?

```bash
git add tests/test_metrics.py
git commit --amend -m "Add F1 metric"
git log --oneline
git rev-parse HEAD
```

Step 3. Find the old commit and compare the two objects.

```bash
git reflog
git cat-file -p 'HEAD@{1}'
git cat-file -p HEAD
```

Step 4. Prove that only the reflog refers to the old commit.

```bash
git branch --contains 'HEAD@{1}'
git fsck --no-reflogs
```

### Expected output

<!-- snippet: ch06/lab-03-1-amend/01-start -->
```text
$ git log --oneline
f17f3d5 Add F1 metrc
d4c9fab Add exact-match metric
$ git status --short
?? tests/
$ git rev-parse HEAD
f17f3d52350ff961d4b0877f5488409e060d6d46
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-1-amend/02-amend -->
```text
$ git add tests/test_metrics.py
$ git commit --amend -m "Add F1 metric"
[main 575b500] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 2 files changed, 9 insertions(+)
 create mode 100644 tests/test_metrics.py
$ git log --oneline
575b500 Add F1 metric
d4c9fab Add exact-match metric
$ git rev-parse HEAD
575b5005b689afaee9431a2fcd1b27c11c698b36
```
<!-- /snippet -->

Your amended commit has a different ID from `575b500`, because its committer date is the real time. Its `Date:` line matches the book: that is the author date, which the amend kept from the original commit.

<!-- snippet: ch06/lab-03-1-amend/03-find-old -->
```text
$ git reflog
575b500 HEAD@{0}: commit (amend): Add F1 metric
f17f3d5 HEAD@{1}: commit: Add F1 metrc
d4c9fab HEAD@{2}: commit (initial): Add exact-match metric
$ git cat-file -p 'HEAD@{1}'
tree 29b018434273c541b9fce4dfc1e29fb92a358447
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755640 +0530
committer Lab User <you@example.com> 1788755640 +0530

Add F1 metrc
$ git cat-file -p HEAD
tree 304b1d11e74d6497529760e3c17e94c881773561
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755640 +0530
committer Lab User <you@example.com> 1788755940 +0530

Add F1 metric
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-1-amend/04-only-the-reflog -->
```text
$ git branch --contains 'HEAD@{1}'
$ git fsck --no-reflogs
dangling commit f17f3d52350ff961d4b0877f5488409e060d6d46
```
<!-- /snippet -->

### What happened internally

- `git commit --amend` read the index (now including the test file), wrote a new tree `304b1d1` and a new commit object whose `parent` is `d4c9fab`, the same parent as `f17f3d5`. It copied the `author` line, wrote a new `committer` line, and moved `refs/heads/main` to the new commit.
- The old object `f17f3d5` was not touched. The reflogs of HEAD and of `main` each gained a line `commit (amend): Add F1 metric`, and the previous line still names `f17f3d5`; that is what `HEAD@{1}` resolves to.
- `git branch --contains 'HEAD@{1}'` printed nothing: no branch's history includes the old commit. `git fsck --no-reflogs` listed it as a dangling commit, which is how a commit looks when only reflog entries refer to it.

### Checkpoint

- `git log --oneline` shows two commits, and the newer one is titled `Add F1 metric`.
- `git cat-file -p HEAD` and `git cat-file -p 'HEAD@{1}'` show the same `parent` and the same `author` line, and different `tree` lines.
- `git status --short` prints nothing.

### Failure scenario

You start a BLEU metric and stage its skeleton, meant for a later commit. Then you notice one more missing test for F1, stage it too, and amend to add the test. The staged skeleton goes along:

```bash
printf 'def bleu(pred, gold, max_n=4):\n    raise NotImplementedError\n' > evalkit/bleu.py
git add evalkit/bleu.py
printf '\n\ndef test_f1_whitespace():\n    assert f1(" ", " ") == 0.0\n' >> tests/test_metrics.py
git add tests/test_metrics.py
git commit --amend --no-edit
git show --stat --format='%h %s' HEAD
```

<!-- snippet: ch06/lab-03-1-amend/05-failure -->
```text
$ printf 'def bleu(pred, gold, max_n=4):\n    raise NotImplementedError\n' > evalkit/bleu.py
$ git add evalkit/bleu.py
$ printf '\n\ndef test_f1_whitespace():\n    assert f1(" ", " ") == 0.0\n' >> tests/test_metrics.py
$ git add tests/test_metrics.py
$ git commit --amend --no-edit
[main 23a1e1a] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 3 files changed, 15 insertions(+)
 create mode 100644 evalkit/bleu.py
 create mode 100644 tests/test_metrics.py
$ git show --stat --format='%h %s' HEAD
23a1e1a Add F1 metric

 evalkit/bleu.py       | 2 ++
 evalkit/metrics.py    | 4 ++++
 tests/test_metrics.py | 9 +++++++++
 3 files changed, 15 insertions(+)
```
<!-- /snippet -->

The F1 commit now creates `evalkit/bleu.py`. Nothing warned you: an amend commits everything that is staged, and the skeleton was staged.

### Recovery

The reflog holds the commit as it was before the bad amend. A soft reset moves the branch back to it and keeps everything the bad commit contained staged, so you can unstage the skeleton and amend again:

```bash
git reflog -3
git reset --soft 'HEAD@{1}'
git status --short
git restore --staged evalkit/bleu.py
git commit --amend --no-edit
git show --stat --format='%h %s' HEAD
git status --short
```

<!-- snippet: ch06/lab-03-1-amend/06-recovery -->
```text
$ git reflog -3
23a1e1a HEAD@{0}: commit (amend): Add F1 metric
575b500 HEAD@{1}: commit (amend): Add F1 metric
f17f3d5 HEAD@{2}: commit: Add F1 metrc
$ git reset --soft 'HEAD@{1}'
$ git status --short
A  evalkit/bleu.py
M  tests/test_metrics.py
$ git restore --staged evalkit/bleu.py
$ git commit --amend --no-edit
[main 51a434a] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 2 files changed, 13 insertions(+)
 create mode 100644 tests/test_metrics.py
$ git show --stat --format='%h %s' HEAD
51a434a Add F1 metric

 evalkit/metrics.py    | 4 ++++
 tests/test_metrics.py | 9 +++++++++
 2 files changed, 13 insertions(+)
$ git status --short
?? evalkit/bleu.py
```
<!-- /snippet -->

After the reset, `evalkit/bleu.py` shows as `A` (staged, new) and `tests/test_metrics.py` as `M` (staged, modified) relative to the restored commit. Unstaging the skeleton leaves it in the working tree as an untracked file, which is where it belongs until its own commit.

### Verification

```bash
git log --oneline
git reflog
git fsck --no-reflogs
```

<!-- snippet: ch06/lab-03-1-amend/07-verify -->
```text
$ git log --oneline
51a434a Add F1 metric
d4c9fab Add exact-match metric
$ git reflog
51a434a HEAD@{0}: commit (amend): Add F1 metric
575b500 HEAD@{1}: reset: moving to HEAD@{1}
23a1e1a HEAD@{2}: commit (amend): Add F1 metric
575b500 HEAD@{3}: commit (amend): Add F1 metric
f17f3d5 HEAD@{4}: commit: Add F1 metrc
d4c9fab HEAD@{5}: commit (initial): Add exact-match metric
$ git fsck --no-reflogs
dangling commit 575b5005b689afaee9431a2fcd1b27c11c698b36
dangling commit 23a1e1a9e8f28debe567c8314424132e7def6571
dangling commit f17f3d52350ff961d4b0877f5488409e060d6d46
```
<!-- /snippet -->

Two commits on `main`; six reflog entries that tell the whole story; three dangling commits, which are the three versions of the F1 commit that `main` no longer points at. Your IDs differ from the book's except for `d4c9fab` and `f17f3d5`, which the setup script created.

### Questions

1. After the first amend, how many commit objects with the title "Add F1 metric" or "Add F1 metrc" exist in the repository, and which refs or reflog entries point at each?
2. The summary line of the amend printed `Date: Mon Sep 7 10:04:00 2026 +0530`, the time of the original commit, although you ran the amend later. Which field is this, and why did the amend keep it?
3. Why did `git fsck --no-reflogs` list the old commit, while a plain `git fsck` would not?
4. In the recovery, why `git reset --soft` and not `--mixed` or `--hard`? What would each of the other two have done to `evalkit/bleu.py`?
5. The verification shows three dangling commits. After `git reflog expire --expire=now --all` and `git gc --prune=now` they would be gone. What exactly does each of the two commands remove, and why would you never run them during an incident?

## Lab 3.2: Change only the committer date and watch the ID change

### Objective

Amend a commit without changing anything, and watch its ID change because the committer date moved. Pin the committer date and get a reproducible ID; restore the original date and get the original ID back. Then play out the incident in which a deployed commit is amended, and recover.

### Prerequisites

- Chapter 6, sections 6.4 and 6.5.
- Chapter 7, section 7.8, for `git merge-base --is-ancestor`.

### Setup

```bash
bash labs/ch06/setup-03-2-committer-date.sh
labs/shell m03-2
```

The script builds `evalkit` with two commits and a clean working tree. The tip is `1f9c5d8 Add F1 metric`.

### Commands

Step 1. Record the commit object, its ID, and its committer date in raw form.

```bash
cd evalkit
git cat-file -p HEAD
git rev-parse HEAD
orig=$(git log -1 --format=%cd --date=raw); echo "$orig"
```

Step 2. Amend with no change at all. Predict the ID before you look.

```bash
git commit --amend --no-edit
git rev-parse HEAD
```

Step 3. Find the one line that differs between the two objects, and prove that the content is identical.

```bash
diff <(git cat-file -p 'HEAD@{1}') <(git cat-file -p HEAD)
git rev-parse 'HEAD@{1}^{tree}' 'HEAD^{tree}'
git diff --stat 'HEAD@{1}' HEAD
```

Step 4. Pin the committer date and amend twice. Predict whether the two IDs are equal.

```bash
GIT_COMMITTER_DATE='2026-09-07T12:00:00+05:30' git commit --amend --no-edit
git rev-parse HEAD
GIT_COMMITTER_DATE='2026-09-07T12:00:00+05:30' git commit --amend --no-edit
git rev-parse HEAD
```

Step 5. Restore the original committer date.

```bash
GIT_COMMITTER_DATE="@$orig" git commit --amend --no-edit
git rev-parse HEAD
```

### Expected output

<!-- snippet: ch06/lab-03-2-committer-date/01-before -->
```text
$ git cat-file -p HEAD
tree 29b018434273c541b9fce4dfc1e29fb92a358447
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755640 +0530
committer Lab User <you@example.com> 1788755640 +0530

Add F1 metric
$ git rev-parse HEAD
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
$ orig=$(git log -1 --format=%cd --date=raw); echo "$orig"
1788755640 +0530
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-2-committer-date/02-amend-nothing -->
```text
$ git commit --amend --no-edit
[main 92602dd] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 4 insertions(+)
$ git rev-parse HEAD
92602dd3d49ae131b2fa1ca33885c108a99f749f
```
<!-- /snippet -->

Your ID after step 2 differs from `92602dd`: the committer date is the real time on your machine.

<!-- snippet: ch06/lab-03-2-committer-date/03-one-line-differs -->
```text
$ diff <(git cat-file -p 'HEAD@{1}') <(git cat-file -p HEAD)
4c4
< committer Lab User <you@example.com> 1788755640 +0530
---
> committer Lab User <you@example.com> 1788755880 +0530
$ git rev-parse 'HEAD@{1}^{tree}' 'HEAD^{tree}'
29b018434273c541b9fce4dfc1e29fb92a358447
29b018434273c541b9fce4dfc1e29fb92a358447
$ git diff --stat 'HEAD@{1}' HEAD
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-2-committer-date/04-pinned -->
```text
$ GIT_COMMITTER_DATE='2026-09-07T12:00:00+05:30' git commit --amend --no-edit
[main 5e292d6] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 4 insertions(+)
$ git rev-parse HEAD
5e292d62b5a2d02407d48103f40188fe1a1923a1
$ GIT_COMMITTER_DATE='2026-09-07T12:00:00+05:30' git commit --amend --no-edit
[main 5e292d6] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 4 insertions(+)
$ git rev-parse HEAD
5e292d62b5a2d02407d48103f40188fe1a1923a1
```
<!-- /snippet -->

From step 4 on, your IDs match the book exactly: the committer date is pinned, the author date was never changed, and the identity in the lab shell is the same `Lab User <you@example.com>`.

<!-- snippet: ch06/lab-03-2-committer-date/05-original-id -->
```text
$ GIT_COMMITTER_DATE="@$orig" git commit --amend --no-edit
[main 1f9c5d8] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 4 insertions(+)
$ git rev-parse HEAD
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
```
<!-- /snippet -->

### What happened internally

- Each amend wrote a new commit object with the same `tree`, `parent`, `author` line and message. In step 2 the only difference was the `committer` timestamp, and the ID is the SHA-1 of the whole object text, so it changed.
- In step 4 every input was identical both times, including the committer date, so Git computed the same ID twice. The second amend created no new object; it found the existing one.
- In step 5 the inputs were exactly those of the original commit, so the original ID came back. The reflog grew by one entry for every amend, so the same ID now appears more than once in it.

### Checkpoint

- `git rev-parse HEAD` prints `1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29`.
- `git reflog` shows the two pinned amends with the same ID, `5e292d6`.
- `git status --short` prints nothing.

### Failure scenario

The release pipeline recorded the ID of HEAD as "deployed". Afterwards someone amends the commit, perhaps to tidy the message. The deployed ID is no longer on the branch, although the content is identical:

```bash
deployed=$(git rev-parse HEAD); echo "$deployed"
git commit --amend --no-edit
git merge-base --is-ancestor "$deployed" HEAD; echo "exit status: $?"
git branch --contains "$deployed"
git diff --quiet "$deployed" HEAD; echo "exit status: $?"
```

<!-- snippet: ch06/lab-03-2-committer-date/06-failure -->
```text
$ deployed=$(git rev-parse HEAD); echo "$deployed"
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
$ git commit --amend --no-edit
[main bd563a1] Add F1 metric
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 4 insertions(+)
$ git merge-base --is-ancestor "$deployed" HEAD; echo "exit status: $?"
exit status: 1
$ git branch --contains "$deployed"
$ git diff --quiet "$deployed" HEAD; echo "exit status: $?"
exit status: 0
```
<!-- /snippet -->

`--is-ancestor` exits with 1: the deployed commit is not in the history of `main`. `git branch --contains` lists no branch. `git diff --quiet` exits with 0: the two trees are the same. This is the state in which an audit says "the deployed commit was never on `main`" and a diff says "nothing changed", and both are right.

### Recovery

Put the branch back on the deployed commit. Nothing was lost, so a soft reset is enough:

```bash
git reset --soft "$deployed"
git rev-parse HEAD
git merge-base --is-ancestor "$deployed" HEAD; echo "exit status: $?"
git status --short
```

<!-- snippet: ch06/lab-03-2-committer-date/07-recovery -->
```text
$ git reset --soft "$deployed"
$ git rev-parse HEAD
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
$ git merge-base --is-ancestor "$deployed" HEAD; echo "exit status: $?"
exit status: 0
$ git status --short
```
<!-- /snippet -->

### Verification

```bash
git log --oneline
git reflog
git fsck --no-reflogs
```

<!-- snippet: ch06/lab-03-2-committer-date/08-verify -->
```text
$ git log --oneline
1f9c5d8 Add F1 metric
d4c9fab Add exact-match metric
$ git reflog
1f9c5d8 HEAD@{0}: reset: moving to 1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
bd563a1 HEAD@{1}: commit (amend): Add F1 metric
1f9c5d8 HEAD@{2}: commit (amend): Add F1 metric
5e292d6 HEAD@{3}: commit (amend): Add F1 metric
5e292d6 HEAD@{4}: commit (amend): Add F1 metric
92602dd HEAD@{5}: commit (amend): Add F1 metric
1f9c5d8 HEAD@{6}: commit: Add F1 metric
d4c9fab HEAD@{7}: commit (initial): Add exact-match metric
$ git fsck --no-reflogs
dangling commit 5e292d62b5a2d02407d48103f40188fe1a1923a1
dangling commit bd563a11151e1c6a2ac52d6d5f8f446a5d9f21a6
dangling commit 92602dd3d49ae131b2fa1ca33885c108a99f749f
```
<!-- /snippet -->

`main` is back on `1f9c5d8`. The reflog lists every version, and the three dangling commits are the amended versions that no ref points at. In your reflog the two unpinned amends, from step 2 and from the failure scenario, show other IDs than `92602dd` and `bd563a1`; every other line matches.

### Questions

1. Which fields of a commit object does `git commit --amend --no-edit` keep, and which does it rewrite, when the index has not changed?
2. Why did the two pinned amends in step 4 produce the same ID, while the two unpinned amends in steps 2 and the failure scenario produced different IDs on your machine?
3. In step 5 the original ID came back. Does this mean the amend "undid" something? What does the reflog say happened?
4. `git diff --quiet "$deployed" HEAD` exited with 0 while `--is-ancestor` exited with 1. State in one sentence what each command compared.
5. A deploy pipeline wants to prove that a given commit is "the reviewed code". Which comparison should it make, by ID or by tree, and what does each choice protect against?

## Lab 3.3: Trailers

### Objective

Write a commit with `Signed-off-by`, `Co-authored-by` and a custom `Refs` trailer, read the trailers back with plumbing and with log formats, define a key alias, and build a report from trailers. Then write a trailer where Git does not recognise it, and repair the message.

### Prerequisites

- Chapter 6, sections 6.9 and 6.10.

### Setup

```bash
bash labs/ch06/setup-03-3-trailers.sh
labs/shell m03-3
```

The script builds `evalkit` with one commit and a new, untracked file `evalkit/judge.py`.

### Commands

Step 1. Commit with three trailers. `-s` adds `Signed-off-by` with your identity; each `--trailer` adds one line.

```bash
cd evalkit
git add evalkit/judge.py
git commit -s -m 'Retry judge calls on HTTP 429' \
    -m 'The judge endpoint rate-limits bursts. Retry with exponential backoff.' \
    --trailer 'Co-authored-by: Asha Rao <asha@example.com>' --trailer 'Refs: EVAL-212'
git log -1 --format=%B
```

Step 2. Read the trailers back.

```bash
git log -1 --format=%B | git interpret-trailers --parse
git log -1 --format='%(trailers:key=Co-authored-by,valueonly)'
```

Step 3. Define `ticket` as an alias for the key `Refs` and use it.

```bash
git config set trailer.ticket.key Refs
printf '\nJudge calls are retried on HTTP 429.\n' >> README.md
git commit -q -am 'Mention the retry policy in the README' --trailer 'ticket=EVAL-230'
git log -1 --format=%B
```

Step 4. Build a report: one line per commit with its ticket, and a count per ticket.

```bash
git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'
git shortlog -sn --group=trailer:refs HEAD
```

### Expected output

<!-- snippet: ch06/lab-03-3-trailers/01-commit -->
```text
$ git add evalkit/judge.py
$ git commit -s -m 'Retry judge calls on HTTP 429' \
    -m 'The judge endpoint rate-limits bursts. Retry with exponential backoff.' \
    --trailer 'Co-authored-by: Asha Rao <asha@example.com>' --trailer 'Refs: EVAL-212'
[main b74fe9a] Retry judge calls on HTTP 429
 1 file changed, 10 insertions(+)
 create mode 100644 evalkit/judge.py
$ git log -1 --format=%B
Retry judge calls on HTTP 429

The judge endpoint rate-limits bursts. Retry with exponential backoff.

Signed-off-by: Lab User <you@example.com>
Co-authored-by: Asha Rao <asha@example.com>
Refs: EVAL-212
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-3-trailers/02-read -->
```text
$ git log -1 --format=%B | git interpret-trailers --parse
Signed-off-by: Lab User <you@example.com>
Co-authored-by: Asha Rao <asha@example.com>
Refs: EVAL-212
$ git log -1 --format='%(trailers:key=Co-authored-by,valueonly)'
Asha Rao <asha@example.com>
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-3-trailers/03-alias -->
```text
$ git config set trailer.ticket.key Refs
$ printf '\nJudge calls are retried on HTTP 429.\n' >> README.md
$ git commit -q -am 'Mention the retry policy in the README' --trailer 'ticket=EVAL-230'
$ git log -1 --format=%B
Mention the retry policy in the README

Refs: EVAL-230
```
<!-- /snippet -->

<!-- snippet: ch06/lab-03-3-trailers/04-report -->
```text
$ git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'
e601dc3 | EVAL-230 | Mention the retry policy in the README
b74fe9a | EVAL-212 | Retry judge calls on HTTP 429
6eab4a9 |  | Add README
$ git shortlog -sn --group=trailer:refs HEAD
     1	EVAL-212
     1	EVAL-230
```
<!-- /snippet -->

Your commit IDs differ from the book's; the trailer lines are identical, because the lab shell uses the same identity.

### What happened internally

- The trailers are lines of the commit message. `git commit` placed them after the body, separated by an empty line, and `-s` used the committer identity for the `Signed-off-by` value. Nothing else in the object records them.
- `git interpret-trailers --parse` found the last paragraph, saw that every line in it has the form `Key: value`, and printed them. `%(trailers:key=...)` applies the same parser inside a log format.
- `trailer.ticket.key=Refs` is a repository-local configuration entry. `--trailer 'ticket=EVAL-230'` expanded the alias, so the message contains `Refs: EVAL-230`; the alias never appears in a commit.
- `git shortlog --group=trailer:refs` grouped commits by the value of that trailer, case-insensitively, and omitted the commit that has none.

### Checkpoint

- `git log -1 --format=%B | git interpret-trailers --parse` prints exactly `Refs: EVAL-230`.
- `git config get trailer.ticket.key` prints `Refs`.
- The report lists three commits, two with tickets.

### Failure scenario

A colleague writes the ticket line by hand, in the middle of the message, with a paragraph after it. Git does not treat it as a trailer, and the report loses the ticket:

```bash
printf '\nBackoff: 1, 2, 4, 8, 16 seconds.\n' >> README.md
git commit -q -am 'Document the backoff schedule

Refs: EVAL-240

Thanks to the platform team for the numbers.'
git log -1 --format=%B | git interpret-trailers --parse
git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'
```

<!-- snippet: ch06/lab-03-3-trailers/05-failure -->
```text
$ printf '\nBackoff: 1, 2, 4, 8, 16 seconds.\n' >> README.md
$ git commit -q -am 'Document the backoff schedule

Refs: EVAL-240

Thanks to the platform team for the numbers.'
$ git log -1 --format=%B | git interpret-trailers --parse
$ git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'
f76f5d3 |  | Document the backoff schedule
e601dc3 | EVAL-230 | Mention the retry policy in the README
b74fe9a | EVAL-212 | Retry judge calls on HTTP 429
6eab4a9 |  | Add README
```
<!-- /snippet -->

The parser printed nothing: the trailer block must be the last paragraph of the message, and here the last paragraph is prose.

### Recovery

Rewrite the message with the trailer where it belongs. `git interpret-trailers --in-place` adds a trailer to a message file at the correct position, and the commit is not yet published, so an amend is allowed:

```bash
printf 'Document the backoff schedule\n\nThanks to the platform team for the numbers.\n' > ../msg.txt
git interpret-trailers --in-place --trailer 'Refs: EVAL-240' ../msg.txt
cat ../msg.txt
git commit -q --amend -F ../msg.txt
```

<!-- snippet: ch06/lab-03-3-trailers/06-recovery -->
```text
$ printf 'Document the backoff schedule\n\nThanks to the platform team for the numbers.\n' > ../msg.txt
$ git interpret-trailers --in-place --trailer 'Refs: EVAL-240' ../msg.txt
$ cat ../msg.txt
Document the backoff schedule

Thanks to the platform team for the numbers.

Refs: EVAL-240
$ git commit -q --amend -F ../msg.txt
```
<!-- /snippet -->

### Verification

```bash
git log -1 --format=%B | git interpret-trailers --parse
git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'
git status --short
```

<!-- snippet: ch06/lab-03-3-trailers/07-verify -->
```text
$ git log -1 --format=%B | git interpret-trailers --parse
Refs: EVAL-240
$ git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'
8a99f6b | EVAL-240 | Document the backoff schedule
e601dc3 | EVAL-230 | Mention the retry policy in the README
b74fe9a | EVAL-212 | Retry judge calls on HTTP 429
6eab4a9 |  | Add README
$ git status --short
```
<!-- /snippet -->

All three tickets appear in the report, and the working tree is clean.

### Questions

1. `-s` wrote `Signed-off-by: Lab User <you@example.com>`. Where did Git take the name and address from, and what does the line certify by itself?
2. State the rule that made Git reject the trailer in the failure scenario, and give a second message layout that would also fail.
3. Why does the alias `ticket` not appear anywhere in the repository's history, and what happens when a colleague who has not configured it runs `git commit --trailer 'ticket=EVAL-250'`?
4. `git shortlog --group=trailer:refs` counted two commits. Which commit did it leave out and why?
5. On GitHub, what does a `Co-authored-by` trailer do that a mention of the person in the body does not, and what must be true of the address for it to work?

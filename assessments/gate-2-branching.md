# Gate 2: Branching

> **Baseline.** Git 2.55.0 on macOS. Every transcript in this file is real output of `labs/gates/g2-predict.sh`. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 7. **Covers** branches as refs, divergence, ancestry, upstream tracking, remote-tracking refs, fetch, pull and push: Chapters [7](../textbook/ch07-branches.md) and [12](../textbook/ch12-remote-operations.md).

**Pass rule.** 90 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 40 minutes, closed book |
| 2 Prediction | 20 | 14 | 20 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 45 minutes, lab shell |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences. Every answer must name the refs involved by their full names where it matters (`refs/heads/...`, `refs/remotes/...`) and say which repository holds each of them.

### C1 (5 points)

`git status` prints "Your branch is up to date with 'origin/main'." A colleague pushed to `main` ten minutes ago. Explain which two refs `git status` compared, in which repository each of them lives, what `origin/main` is a record of, and which events move it. Give two commands that tell you the truth about the server, and say which of them changes your repository.

### C2 (5 points)

A release engineer asks: "From which branch was `feature/streaming` created?" Explain why Git cannot answer that question from the repository's shared data, name the one local place where a trace may exist, and say what Git can compute for two named branches instead. Then give one situation in which that computed commit is not the commit at which the branch was created.

### C3 (5 points)

For each of `git fetch`, `git pull` and `git push`, state what it does to: your local branches, your remote-tracking branches, the server's branches, and your working tree. Then explain what the server checks before it accepts a push to an existing branch, in terms of ancestry, and whose commits that check protects.

### C4 (5 points)

Explain how the upstream of a branch is stored, and name three different commands or settings that cause it to be set. A developer runs `git switch -c fix/timeout origin/main`, commits, and runs `git push`. With the default `push.default`, what happens, and why does Git decide that way? What would `push.default=upstream` have done with the same command?

### C5 (5 points)

Two branches "have diverged". Define that in terms of the commit graph. Then define "A is fully merged into B" in the same terms, say what `git branch -d` actually compares the branch with before it deletes, and construct a case in which `git branch -d X` refuses although `X` is fully merged into `main`.

### C6 (5 points)

A branch is deleted on the server. Describe what changes, and when, in a colleague's clone that has both a remote-tracking branch and a local branch for it. What does `[gone]` in `git branch -vv` mean, and what does it not tell you? Then explain how the deletion of a server branch called `fix` can make `git fetch` report an error in every clone the following week.

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect, as literally as you can, and one sentence of mechanism for each prediction. Where an abbreviated commit ID would appear, write `<id>`. Lines that start with `#` are comments that describe hidden setup.

### P1 (5 points)

<!-- snippet: gates/g2-predict/p1-setup -->
```text
# you/ and asha/ are clones of the same server. main has two commits everywhere.
$ git commit -q --allow-empty -m "Cache the vocabulary"
$ git commit -q --allow-empty -m "Add cache eviction"
$ git -C ../asha commit -q --allow-empty -m "Fix unicode normalization"
$ git -C ../asha push -q origin main
$ git status -sb
## main...origin/main [ahead 2]
$ git fetch -q
```
<!-- /snippet -->

Predict, in `you/`:

1. The output of `git status -sb`.
2. The output of `git rev-list --left-right --count main...origin/main`.
3. The exit status of `git merge-base --is-ancestor origin/main main`.
4. The subjects listed by `git log --oneline main..origin/main`.

### P2 (5 points)

<!-- snippet: gates/g2-predict/p2-setup -->
```text
$ git init -q tokenizer
$ cd tokenizer
$ git commit -q --allow-empty -m "A"
$ git branch fix/bpe
$ git commit -q --allow-empty -m "B"
$ git branch feature/cache
$ git switch -q -c feature/stream
$ git commit -q --allow-empty -m "C"
$ git switch -q main
$ git commit -q --allow-empty -m "D"
```
<!-- /snippet -->

Predict:

1. The branches listed by `git branch --merged main` and by `git branch --no-merged main`.
2. The branches listed by `git branch --contains feature/cache`.
3. Draw the graph that `git log --oneline --graph --all` prints, with the subjects and the branch at each tip.
4. Whether `git branch -d feature/cache` deletes the branch, and its exit status.

### P3 (5 points)

<!-- snippet: gates/g2-predict/p3-setup -->
```text
# you/ and asha/ are clones of the same server. main has two commits everywhere.
# Neither pull.rebase nor pull.ff is set.
$ git commit -q --allow-empty -m "Cache the vocabulary"
$ git -C ../asha commit -q --allow-empty -m "Fix unicode normalization"
$ git -C ../asha push -q origin main
$ git log -1 --format=%s origin/main
Add vocabulary loader
$ git pull -q
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[exit status: 128]
```
<!-- /snippet -->

The pull failed. Predict, in `you/`, directly afterwards:

1. The output of `git log -1 --format=%s origin/main` and of `git log -1 --format=%s main`.
2. The output of `git status -sb`.
3. Whether `git pull --ff-only` succeeds now, and its exit status.

### P4 (5 points)

<!-- snippet: gates/g2-predict/p4-setup -->
```text
# you/ and asha/ are clones of the same server. main has two commits everywhere.
$ git switch -q -c feature/streaming
$ git commit -q --allow-empty -m "Stream tokens"
$ git push -q -u origin feature/streaming
$ git switch -q main
$ git -C ../asha push -q origin --delete feature/streaming
$ git fetch
```
<!-- /snippet -->

Predict, in `you/`:

1. The output of `git branch -r` (ignore any `origin/HEAD` line).
2. What `git branch -vv` shows in square brackets for `feature/streaming`.

Then one more command runs:

<!-- snippet: gates/g2-predict/p4-setup-b -->
```text
$ git fetch -q --prune
```
<!-- /snippet -->

Predict:

3. What `git branch -vv` shows in square brackets for `feature/streaming` now.
4. Whether `git branch -d feature/streaming` deletes the branch (you are on `main`), and why.
5. What `git push origin feature/streaming` does, and its exit status.

---

## Part 3: Hands-on diagnosis (30 points)

One generated sandbox with a server and two clones. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| Build it | `assessments/gen/gate-2-branching/variant-a/generate.sh` | `assessments/gen/gate-2-branching/variant-b/generate.sh` |
| What was reported | [`variant-a/SYMPTOMS.md`](gen/gate-2-branching/variant-a/SYMPTOMS.md) | [`variant-b/SYMPTOMS.md`](gen/gate-2-branching/variant-b/SYMPTOMS.md) |
| Check the end state | `assessments/gen/gate-2-branching/variant-a/check.sh` | `assessments/gen/gate-2-branching/variant-b/check.sh` |

Run the generator from the course root, open the lab shell at the path it prints, and read `SYMPTOMS.md`. Do not read `generate.sh` or `check.sh`. Keep a log of every command you type; the log is graded.

| Graded on | Points | What earns them |
|---|---|---|
| End state | 12 | `check.sh` ends with `PASS`. One point is lost for each failed line, down to zero |
| Safety of the path | 8 | Evidence before change; the server asked directly before any conclusion about it; nothing deleted before its reachability was proved; no forced push and no forced deletion |
| Explanation | 10 | The root causes that `SYMPTOMS.md` asks for, in the form of the root-cause box, each naming the refs by their full names, plus prevention |

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each, without a terminal. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

What is the difference between `HEAD`, a branch and a remote-tracking branch? *Follow-up:* what happens when you check out `origin/main` and commit?

### O2 (3 points)

How do you measure how far two branches have diverged? *Follow-up:* what do the two numbers in "ahead 3, behind 2" count, exactly, and against which ref?

### O3 (3 points)

What does `git pull` do, step by step? *Follow-up:* in current Git, with nothing configured, your branch and its upstream have diverged and you run `git pull`. What happens, and what has changed in your repository afterwards?

### O4 (3 points)

A push is rejected as "non-fast-forward". What did the server compare? *Follow-up:* a colleague says "use `--force`, it is your branch". What would you check first, and what does the plain rejection protect?

### O5 (4 points)

Your clone has two remotes, `origin` (your fork) and `upstream` (the project). For a branch of yours, what decides where `git pull` reads from and where `git push` writes to? *Follow-up:* how do you see both answers for the current branch without transferring anything?

### O6 (4 points)

Is `main` special to Git? *Follow-up:* what is `origin/HEAD`, who sets it, and what happens in existing clones when the default branch is changed on the server?

---

## Score sheet

| Item | Max | Score | | Item | Max | Score |
|---|---|---|---|---|---|---|
| C1 | 5 | | | P1 | 5 | |
| C2 | 5 | | | P2 | 5 | |
| C3 | 5 | | | P3 | 5 | |
| C4 | 5 | | | P4 | 5 | |
| C5 | 5 | | | **Prediction** | **20** | |
| C6 | 5 | | | H end state | 12 | |
| **Concepts** | **30** | | | H safety | 8 | |
| O1 to O4 | 12 | | | H explanation | 10 | |
| O5, O6 | 8 | | | **Hands-on** | **30** | |
| **Oral** | **20** | | | **Total** | **100** | |

Pass: total 90 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, redo the labs of that module, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 12, sections 12.2 and 12.4 | 7 |
| C2 | Chapter 7, sections 7.8 and 7.9 | 4 |
| C3 | Chapter 12, sections 12.4, 12.6 and 12.7 | 7 |
| C4 | Chapter 12, section 12.5 | 7 |
| C5 | Chapter 7, sections 7.5 and 7.8 | 4 |
| C6 | Chapter 12, section 12.11; Chapter 7, sections 7.12 and 7.13 | 4, 7 |
| P1 | Chapter 7, section 7.8; Chapter 12, section 12.4 | 4, 7 |
| P2 | Chapter 7, sections 7.5 and 7.8 | 4 |
| P3 | Chapter 12, section 12.6 | 7 |
| P4 | Chapter 12, section 12.11; Chapter 7, section 7.5 | 7 |
| Hands-on A | Chapter 7, sections 7.5, 7.11 and 7.12; Chapter 12, sections 12.5 and 12.11 | 4, 7 |
| Hands-on B | Chapter 7, sections 7.7 and 7.12; Chapter 12, sections 12.5 to 12.7 and 12.11 | 4, 7 |
| O1 | Chapter 7, sections 7.3, 7.7 and 7.10 | 4 |
| O2 | Chapter 7, section 7.8 | 4 |
| O3 | Chapter 12, section 12.6 | 7 |
| O4 | Chapter 12, sections 12.7 and 12.8 | 7 |
| O5 | Chapter 12, sections 12.5 and 12.10 | 7 |
| O6 | Chapter 7, section 7.2; Chapter 12, section 12.3 | 4, 7 |

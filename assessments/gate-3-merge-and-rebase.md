# Gate 3: Merge and rebase

> **Baseline.** Git 2.55.0 on macOS. Every transcript in this file is real output of `labs/gates/g3-predict.sh`. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 10. **Covers** the three-way merge, conflicts and index stages, the undo choices, rebase, cherry-pick and range notation: Chapters [8](../textbook/ch08-merge.md), [9](../textbook/ch09-rebase.md), [10](../textbook/ch10-cherry-pick.md), [11](../textbook/ch11-reset-revert-restore.md) and the range sections of [14A](../textbook/ch14a-history-investigation.md).

**Pass rule.** 90 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 50 minutes, lab shell |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences. Every answer must name the commits, index stages or files involved and say what reads or writes them.

### C1 (5 points)

Describe a three-way merge of one file: the three inputs, how Git finds the third one, and the rule Git applies to each region of the file. Then explain two things that follow from the rule: why two branches that changed different lines of a file can still conflict, and why a merge that reports no conflict can produce a program that does not run.

### C2 (5 points)

A merge has stopped with a conflict in one file. List what is now in the working tree, in the index and under `.git`, and say what `git add <file>` changes. Then state what "ours" and "theirs" mean during `git merge`, during `git rebase` and during `git cherry-pick`, and explain the one of the three that surprises people. What happens in a rebase if you resolve a conflict by taking "ours" for the whole file?

### C3 (5 points)

Explain why every commit of a rebased branch has a new ID even when no conflict occurred and no line changed. What happens to the old commits, and how long can you get back to them? A colleague had based work on your branch before you rebased and force-pushed it. Describe what their next `git pull` (merge) produces and why, and name the options of `git push` that should have been used for the forced update and what each of them checks.

### C4 (5 points)

For each situation choose one of `git restore`, `git reset`, `git revert`, `git commit --amend`, give the exact form, and justify the choice by what has been published: (a) a commit that broke production is on the shared `main`, with ten commits by other people on top of it; (b) your last commit, not pushed, contains a file that must not be in it; (c) a file is staged that should not be part of the next commit; (d) you want to throw away your uncommitted edits to one file. For (d), say what can and cannot be recovered afterwards.

### C5 (5 points)

A merge of `feature/reranker` into `main` was reverted with `git revert -m 1`. The team fixes the bug with one more commit on the branch and merges the branch again. Only the one new commit arrives; the rest of the feature is still missing. Explain this with the merge base. What did `-m 1` mean, what does the revert leave in the graph, and what are the two correct ways to bring the whole feature back?

### C6 (5 points)

State what `A..B` and `A...B` select in `git log`, and what the same two notations mean in `git diff`. They do not mean the same thing in the two commands. A reviewer runs `git diff main feature` and sees a setting being deleted that the feature never touched; explain the output and give the command the reviewer wanted. Finally, a script backports with `git cherry-pick A..B`: which commit is not picked?

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect, as literally as you can, and one sentence of mechanism for each prediction. Where an object ID would appear, write `<id>`.

### P1 (5 points)

<!-- snippet: gates/g3-predict/p1-setup -->
```text
$ git init -q sampler
$ cd sampler
$ printf 'temperature: 0.7\ntop_p: 0.9\ntop_k: 40\nmax_tokens: 512\nseed: 7\n' > sampling.yaml
$ git add . && git commit -q -m "Add sampling defaults"
$ git switch -q -c tune/top-k
$ sed -i.bak 's/top_k: 40/top_k: 20/' sampling.yaml && rm sampling.yaml.bak
$ git commit -q -am "Lower top_k"
$ git switch -q main
$ sed -i.bak 's/top_p: 0.9/top_p: 0.95/' sampling.yaml && rm sampling.yaml.bak
$ git commit -q -am "Raise top_p"
```
<!-- /snippet -->

Now `git merge tune/top-k` runs on `main`. Predict:

1. Whether the merge completes, and its exit status.
2. The output of `git status --short`.
3. How many lines `git ls-files -u` prints, and the stage number in each.
4. The content of `sampling.yaml` in the working tree, line by line.

### P2 (5 points)

<!-- snippet: gates/g3-predict/p2-setup -->
```text
$ git init -q sched
$ cd sched
$ printf 'warmup: 100\n' > lr.yaml
$ git add . && git commit -q -m "Add warmup"
$ printf 'warmup: 500\n' > lr.yaml
$ printf 'cosine\n' > decay.txt
$ git add . && git commit -q -m "Longer warmup, cosine decay"
$ printf 'warmup: 800\n' > lr.yaml
$ git reset -q HEAD~1
```
<!-- /snippet -->

Predict:

1. The output of `git status --short`, and the content of `lr.yaml`.

Then one more command runs:

<!-- snippet: gates/g3-predict/p2-setup-b -->
```text
$ git reset -q --soft ORIG_HEAD
```
<!-- /snippet -->

Predict:

2. How many commits `git log --oneline` lists now.
3. The complete output of `git status --short`. It has three lines.

### P3 (5 points)

<!-- snippet: gates/g3-predict/p3-setup -->
```text
$ git init -q stack
$ cd stack
$ git commit -q --allow-empty -m "A"
$ git commit -q --allow-empty -m "B"
$ git switch -q -c feature/parser
$ git commit -q --allow-empty -m "C"
$ git commit -q --allow-empty -m "D"
$ git switch -q -c feature/printer
$ git commit -q --allow-empty -m "F"
$ git commit -q --allow-empty -m "G"
$ git switch -q main
$ git commit -q --allow-empty -m "E"
$ git rebase -q --onto main feature/parser feature/printer
```
<!-- /snippet -->

Predict:

1. The graph that `git log --graph --all --format='%s%d'` prints: every commit by its subject, with the branch names at the tips.
2. The subjects listed by `git log --format=%s main..feature/printer`.
3. The subjects listed by `git log --format=%s feature/printer..feature/parser`.
4. The three subjects listed by `git log --format=%s ORIG_HEAD -3`.

### P4 (5 points)

<!-- snippet: gates/g3-predict/p4-setup -->
```text
$ git init -q ranges
$ cd ranges
$ printf 'base\n' > notes.txt && git add . && git commit -q -m 'Base'
$ git switch -q -c topic
$ printf 'p\n' > p.txt && git add . && git commit -q -m 'P'
$ git switch -q main
$ printf 'x\n' > x.txt && git add . && git commit -q -m 'X'
$ printf 'y\n' > y.txt && git add . && git commit -q -m 'Y'
$ git switch -q topic
$ git cherry-pick main~1 > /dev/null
$ printf 'q\n' > q.txt && git add . && git commit -q -m 'Q'
```
<!-- /snippet -->

`HEAD` is on `topic`. Predict:

1. The subjects listed by `git log --format=%s main..topic`.
2. The output of `git log --format="%m %s" --left-right main...topic` (`%m` prints `<` or `>`).
3. The same command with `--cherry-pick` added.
4. The files listed by `git diff --stat main...topic` and by `git diff --stat main..topic`, with `+` or `-` for each.

---

## Part 3: Hands-on diagnosis (30 points)

One generated sandbox in which an operation has stopped half-way. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| Build it | `assessments/gen/gate-3-merge-and-rebase/variant-a/generate.sh` | `assessments/gen/gate-3-merge-and-rebase/variant-b/generate.sh` |
| What was reported | [`variant-a/SYMPTOMS.md`](gen/gate-3-merge-and-rebase/variant-a/SYMPTOMS.md) | [`variant-b/SYMPTOMS.md`](gen/gate-3-merge-and-rebase/variant-b/SYMPTOMS.md) |
| Check the end state | `assessments/gen/gate-3-merge-and-rebase/variant-a/check.sh` | `assessments/gen/gate-3-merge-and-rebase/variant-b/check.sh` |

Run the generator from the course root, open the lab shell at the path it prints, and read `SYMPTOMS.md`. Do not read `generate.sh` or `check.sh`. Keep a log of every command you type; the log is graded.

| Graded on | Points | What earns them |
|---|---|---|
| End state | 12 | `check.sh` ends with `PASS`. One point is lost for each failed line, down to zero |
| Safety of the path | 8 | The stopped operation inspected before it is continued or left; the three stages read before the resolution; a way back before each rewrite; nothing pushed |
| Explanation | 10 | The written statements that the rules in `SYMPTOMS.md` ask for, each checked with a command whose output is in the log |

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each, without a terminal. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

What happens during a three-way merge? *Follow-up:* what does Git do when the two branches have two merge bases?

### O2 (3 points)

Why can Git merge two files in a way that is wrong from a human point of view? *Follow-up:* where in your process do you catch that?

### O3 (3 points)

Why does a cherry-pick create a new commit instead of reusing the old one? *Follow-up:* three months later, how do you find out whether a fix on `main` is already on a release branch?

### O4 (3 points)

When do you revert and when do you reset? *Follow-up:* what exactly does `git reset --hard` destroy that no Git command brings back?

### O5 (4 points)

A team squash-merges a long-lived branch into `main`, keeps working on the branch, and squash-merges it again a week later. The second merge conflicts on lines that the first one already delivered. Why? *Follow-up:* what do you change so that it cannot happen?

### O6 (4 points)

Rebase or merge: how do you decide for a feature branch that has to catch up with `main`? *Follow-up:* after a teammate's forced push to a shared branch you run `git pull --rebase`; it reports success and one of your own pushed commits is no longer in your branch. Explain.

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
| C1 | Chapter 8, sections 8.2, 8.4, 8.7 and 8.15 | 6 |
| C2 | Chapter 8, section 8.8; Chapter 9, section 9.11; Chapter 10, section 10.7 | 6, 9, 10 |
| C3 | Chapter 9, sections 9.3, 9.15, 9.16 and 9.17; Chapter 12, section 12.8 | 9, 7 |
| C4 | Chapter 11, sections 11.2 to 11.8 and 11.12 | 8 |
| C5 | Chapter 11, section 11.9 | 8 |
| C6 | Chapter 14A, sections 14A.2 and 14A.8; Chapter 10, section 10.5 | 10 |
| P1 | Chapter 8, sections 8.7 and 8.8 | 6 |
| P2 | Chapter 11, sections 11.4 and 11.7; Chapter 13, section 13.5 | 8 |
| P3 | Chapter 9, sections 9.5 and 9.9 | 9 |
| P4 | Chapter 14A, sections 14A.2, 14A.8 and 14A.14; Chapter 10, section 10.10 | 10 |
| Hands-on A | Chapter 9, sections 9.4, 9.7, 9.11, 9.14 and 9.16; Chapter 10, sections 10.4 and 10.9 | 9, 10 |
| Hands-on B | Chapter 10, sections 10.4 to 10.7 and 10.10; Chapter 14A, section 14A.8 | 10 |
| O1 | Chapter 8, sections 8.4 and 8.5 | 6 |
| O2 | Chapter 8, section 8.15 | 6 |
| O3 | Chapter 10, sections 10.3 and 10.10 | 10 |
| O4 | Chapter 11, sections 11.2, 11.5 and 11.8 | 8 |
| O5 | Chapter 8, section 8.12 | 6 |
| O6 | Chapter 9, sections 9.17 and 9.18 | 9 |

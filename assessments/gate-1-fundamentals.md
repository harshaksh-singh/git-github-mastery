# Gate 1: Fundamentals

> **Baseline.** Git 2.55.0 on macOS. Every transcript in this file is real output of `labs/gates/g1-predict.sh`. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 5. **Covers** the data model, the three trees, commits, refs, HEAD and configuration: Chapters [1](../textbook/ch01-fundamentals.md), [2](../textbook/ch02-mental-model.md), [4](../textbook/ch04-working-tree.md), [5](../textbook/ch05-index.md), [6](../textbook/ch06-commits.md), [7](../textbook/ch07-branches.md) and the configuration half of [14B](../textbook/ch14b-config-tags-signing.md).

**Pass rule.** 85 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 40 minutes, closed book |
| 2 Prediction | 20 | 14 | 20 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 45 minutes, lab shell |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences. A definition earns nothing by itself: every answer must name the objects, refs or files involved and say what reads or writes them.

### C1 (5 points)

A teammate says: "Git stores the changes between versions, so a repository with a long history must replay thousands of diffs to check out the newest commit." Correct this. Say what a commit object contains, what `git show <commit>` computes and from what, how an unchanged file is represented in the next commit, and where in Git deltas do exist.

### C2 (5 points)

You change one character in `docs/README.md`, three directories deep in a project of 4,000 files, and commit. Which objects are new, and which are reused? Then explain why two commits whose `git diff` is empty can still have different commit IDs, and what you would compare to prove that their content is equal.

### C3 (5 points)

For each of these four commands, name the tree it reads and the tree it writes (working tree, index, `HEAD`): `git add <path>`, `git commit`, `git restore --staged <path>`, `git restore <path>`. Then explain how `git diff` can print nothing while `git commit` still creates a commit that changes a file.

### C4 (5 points)

A settings file is listed in `.gitignore` on `main`. On the branch `release-1.0` the same path is a tracked file. A developer who keeps private values in that file switches to `release-1.0` and back. Describe what happens to the file on disk at each switch and why Git prints no warning. Contrast this with what Git does when the file in the way is untracked but not ignored. What is the prevention?

### C5 (5 points)

Describe, in order, everything that `git commit -m "..."` writes under `.git` when `HEAD` is attached to `main`, starting from the moment before `git add`. Name each object and each file. Then say what is different when `HEAD` is detached, and why the difference matters an hour later.

### C6 (5 points)

A developer runs `git config set --global user.email work@corp.example`, and the next commit in one particular repository still carries a different email. List every place the other value can come from, in the order in which Git gives them priority, and give the one command that tells you which place it is for a configuration value. Which source of an identity does that command not show?

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. For each item you get the commands that built the state. Write the output you expect, as literally as you can, and one sentence of mechanism for each prediction. Abbreviated object IDs cannot be predicted and are not asked for; where an ID would appear, write `<id>` and say which object it names.

### P1 (5 points)

<!-- snippet: gates/g1-predict/p1-setup -->
```text
$ git init -q regionconf
$ cd regionconf
$ mkdir eu us
$ printf 'timeout_s: 30\n' > default.yaml
$ cp default.yaml eu/service.yaml
$ cp default.yaml us/service.yaml
$ git add .
$ git commit -q -m "Add per-region configuration"
```
<!-- /snippet -->

Predict:

1. The number of objects that `git count-objects` reports.
2. The output of `git ls-tree HEAD`: the mode, type and name of each line, and which of the lines carry the same object ID as another line.
3. The type of each object in the repository.

### P2 (5 points)

<!-- snippet: gates/g1-predict/p2-setup -->
```text
$ git init -q ratelimit
$ cd ratelimit
$ printf 'ROUTES = 2\n' > router.py
$ printf 'LIMIT = 10\n' > limits.py
$ git add .
$ git commit -q -m "Add router and limits"
$ printf 'ROUTES = 3\n' > router.py
$ git add router.py
$ printf 'LIMIT = 20\n' > limits.py
$ printf 'ask Ravi about burst\n' > notes.txt
$ git commit -q -m "Raise the limit" limits.py
```
<!-- /snippet -->

Predict:

1. The file list of `git show --stat --format=%s HEAD`.
2. The complete output of `git status --short`.
3. The file list of `git diff --cached --stat`.

### P3 (5 points)

<!-- snippet: gates/g1-predict/p3-setup -->
```text
$ git init -q batcher
$ cd batcher
$ git commit -q --allow-empty -m "Add batcher"
$ git commit -q --allow-empty -m "Add padding"
$ git commit -q --allow-empty -m "Add truncation"
$ git switch -q --detach HEAD~1
$ git commit -q --allow-empty -m "Try dynamic padding"
```
<!-- /snippet -->

Predict, in this state:

1. The output and the exit status of `git symbolic-ref HEAD`.
2. The subjects that `git log --oneline --all` lists, in order.

Then one more command runs:

<!-- snippet: gates/g1-predict/p3-setup-b -->
```text
$ git switch -q main
```
<!-- /snippet -->

Predict:

3. The subjects that `git log --oneline --all` lists now.
4. The output of ``git cat-file -t 'HEAD@{1}'`` and of ``git branch --contains 'HEAD@{1}'``.

### P4 (5 points)

The shell has no `GIT_AUTHOR_*` or `GIT_COMMITTER_*` variable set when these commands start. `--global` writes to the lab's isolated global file.

<!-- snippet: gates/g1-predict/p4-setup -->
```text
$ git init -q whoami
$ cd whoami
$ git config set --global user.email global@example.com
$ git config set user.email local@example.com
$ export GIT_AUTHOR_EMAIL=env@example.com
$ git -c user.email=flag@example.com commit -q --allow-empty -m "Whose commit is this"
```
<!-- /snippet -->

Predict:

1. The author email and the committer email of the commit.
2. The output of `git config get --show-scope --show-origin user.email`.
3. The output of `git config get --all --show-scope user.email`, including the order of the lines.

---

## Part 3: Hands-on diagnosis (30 points)

One generated repository. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| Build it | `assessments/gen/gate-1-fundamentals/variant-a/generate.sh` | `assessments/gen/gate-1-fundamentals/variant-b/generate.sh` |
| What was reported | [`variant-a/SYMPTOMS.md`](gen/gate-1-fundamentals/variant-a/SYMPTOMS.md) | [`variant-b/SYMPTOMS.md`](gen/gate-1-fundamentals/variant-b/SYMPTOMS.md) |
| Check the end state | `assessments/gen/gate-1-fundamentals/variant-a/check.sh` | `assessments/gen/gate-1-fundamentals/variant-b/check.sh` |

Run the generator from the course root, open the lab shell at the path it prints, and read `SYMPTOMS.md`. Do not read `generate.sh` or `check.sh`: the first is the answer and the second lists the end state condition by condition. Keep a log of every command you type; the log is graded.

| Graded on | Points | What earns them |
|---|---|---|
| End state | 12 | `check.sh` ends with `PASS`. One point is lost for each failed line, down to zero |
| Safety of the path | 8 | Evidence before change; no command that could destroy uncommitted work without a preview; no history rewritten that did not need rewriting; each state-changing command explained by the tree or ref it changes |
| Explanation | 10 | Three root causes in the form of the root-cause box (Chapter 1, section 1.10), each naming the Git state and the mechanism, plus one sentence of prevention each |

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each, without a terminal. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

What exactly is a branch? *Follow-up:* then what does "the branch contains this commit" mean, given what you said a branch is?

### O2 (3 points)

What is `HEAD`? *Follow-up:* name two different things that file can contain and what `git commit` does in each case.

### O3 (3 points)

Why does changing the message of a commit give it a new ID? *Follow-up:* what happens to the IDs of the commits that came after it, and why?

### O4 (3 points)

A file is in `.gitignore` and Git keeps reporting it as modified. Explain. *Follow-up:* you fix it with one command and a commit. What happens on your teammate's machine at their next pull?

### O5 (4 points)

I run `git add report.py`, edit the file again, and commit. Which version is in the commit, where was it stored and when? *Follow-up:* I staged a file that contained a password for ten seconds and unstaged it again without committing. Is the password in the repository?

### O6 (4 points)

A script that works on your laptop fails on a colleague's laptop with a different Git behavior, same Git version, same repository contents. How do you find the difference? *Follow-up:* the setting is in neither their global nor their local file. Where else can it come from?

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

Pass: total 85 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, redo the labs of that module, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 2, sections 2.3 and 2.10 | 1 |
| C2 | Chapter 2, sections 2.4 and 2.5; Chapter 6, section 6.4 | 1, 3 |
| C3 | Chapter 2, section 2.9; Chapter 5, sections 5.3, 5.4 and 5.9; Chapter 4, section 4.7 | 2 |
| C4 | Chapter 4, sections 4.3 and 4.16 | 2 |
| C5 | Chapter 5, section 5.3; Chapter 6, section 6.3; Chapter 7, sections 7.4 and 7.7 | 3, 4 |
| C6 | Chapter 14B, sections 14B.2 to 14B.4; Chapter 6, section 6.5 | 5 |
| P1 | Chapter 2, sections 2.4 and 2.5 | 1 |
| P2 | Chapter 5, section 5.10 | 2 |
| P3 | Chapter 7, sections 7.3 and 7.7 | 4 |
| P4 | Chapter 6, section 6.5; Chapter 14B, section 14B.2 | 3, 5 |
| Hands-on A | Chapter 5, sections 5.3 and 5.4; Chapter 6, section 6.7; Chapter 4, sections 4.4 and 4.6; Chapter 14B, section 14B.3 | 2, 3, 5 |
| Hands-on B | Chapter 5, section 5.9; Chapter 4, section 4.10; Chapter 2, section 2.13; Chapter 6, section 6.7 | 1, 2 |
| O1 | Chapter 7, section 7.2; Chapter 2, section 2.7 | 4 |
| O2 | Chapter 7, sections 7.3 and 7.7 | 4 |
| O3 | Chapter 6, sections 6.4 and 6.7 | 3 |
| O4 | Chapter 4, section 4.6 | 2 |
| O5 | Chapter 5, section 5.3; Chapter 2, section 2.14 | 2 |
| O6 | Chapter 14B, sections 14B.2, 14B.3 and 14B.7 | 5 |

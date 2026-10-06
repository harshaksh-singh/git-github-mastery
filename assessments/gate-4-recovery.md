# Gate 4: Recovery

> **Baseline.** Git 2.55.0 on macOS. Every transcript in this file is real output of `labs/gates/g4-predict.sh`. The lab configuration sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never`; where a question is about retention, answer for Git's defaults. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 15. **Covers** history forensics, the reflog, `git fsck`, the disaster recoveries and what cannot be recovered: Chapters [13](../textbook/ch13-recovery.md) and [14A](../textbook/ch14a-history-investigation.md), with the stash sections of Chapter [11](../textbook/ch11-reset-revert-restore.md) and the reachability section of Chapter [3](../textbook/ch03-git-internals.md).

**Pass rule.** 90 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 60 minutes, lab shell |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences. Every answer must say what keeps an object alive, by name, and for how long.

### C1 (5 points)

A commit has been removed from its branch by `git reset --hard HEAD~1`. Name, in order, every layer that still protects the commit object from deletion, the default lifetime of each, and the tool that finds the commit at each layer. Then correct this summary and say what is wrong with it: "You have 30 days in the reflog and then two more weeks until garbage collection."

### C2 (5 points)

Explain what a reflog is: what one entry records, which refs have one, where it lives, and what happens to it on `git clone`, on `git push` and on `git branch -D`. A developer finds that `git reflog show main` begins with an entry that is not the commit `main` points at. Explain how that can be, and what it tells you about using a reflog as a backup.

### C3 (5 points)

For each of these five losses, say whether Git can bring the content back and give the reason in terms of which object was written and what names it: (a) a commit removed by an interactive rebase yesterday; (b) edits to a tracked file, never staged, overwritten by `git restore`; (c) a new file that was staged with `git add` and then removed by `git reset --hard` before any commit; (d) an untracked file deleted by `git clean -fd`; (e) the third-oldest stash entry after `git stash clear`. For each recoverable case, name the command that finds it.

### C4 (5 points)

`git fsck` printed one "dangling commit" line after a branch with five commits was deleted and the reflogs were expired. Explain why one line and not five, the difference between "dangling" and "unreachable", and why the same command printed nothing at all one minute earlier, before the reflogs were expired. Then say why a dangling blob has no file name, and how you would decide which of several dangling blobs is the one you want.

### C5 (5 points)

You have to answer "which commit broke this, and why was the line written". Compare `git blame`, `git log -S`, `git log -G`, `git log -L` and `git bisect`: the question each one answers and one way each one misleads. Then explain why `git log -- <path>` for a renamed file stops at the rename, and what `--follow` can and cannot do about it.

### C6 (5 points)

Which commands write `ORIG_HEAD`, and which common history-changing commands do not? A developer undoes a bad cherry-pick on a release branch with `git reset --hard ORIG_HEAD` and finds the branch showing the history of `main`. Explain. A second developer undoes a merge with `git reset --hard HEAD~1` and finds two of the three merged commits still on the branch. Explain that too, and give the method that is correct in both cases.

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect, as literally as you can, and one sentence of mechanism for each prediction. Where an object ID would appear, write `<id>` and say which object it names.

### P1 (5 points)

<!-- snippet: gates/g4-predict/p1-setup -->
```text
$ git init -q embedder
$ cd embedder
$ git commit -q --allow-empty -m "Add embedder"
$ git commit -q --allow-empty -m "Add batching"
$ git commit -q --allow-empty -m "Add retry"
$ git switch -q -c spike/async
$ git commit -q --allow-empty -m "Try asyncio"
$ git switch -q main
$ git reset -q --hard HEAD~2
$ git commit -q --allow-empty -m "Add caching"
```
<!-- /snippet -->

Predict:

1. The output of `git reflog --format='%gd %gs'`: one line per entry, the selector `HEAD@{n}` followed by the message Git recorded. Eight lines.
2. The output of the same command for `main` (`git reflog show main --format='%gd %gs'`).
3. The subject of `main@{3}`, of `HEAD@{3}`, and of `ORIG_HEAD`.

### P2 (5 points)

<!-- snippet: gates/g4-predict/p2-setup -->
```text
$ git init -q ranker
$ cd ranker
$ git commit -q --allow-empty -m "Add ranker"
$ git switch -q -c spike/listwise
$ git commit -q --allow-empty -m "Listwise loss"
$ git commit -q --allow-empty -m "Listwise sampler"
$ git switch -q main
$ git branch -q -D spike/listwise
```
<!-- /snippet -->

Predict:

1. What `git fsck` prints.
2. What `git fsck --no-reflogs` prints.

Then:

<!-- snippet: gates/g4-predict/p2-setup-b -->
```text
$ git reflog expire --expire=now --all
```
<!-- /snippet -->

Predict:

3. What `git fsck` prints now, and what `git fsck --unreachable` prints: how many lines, and which commits by subject.
4. What `git fsck --unreachable` prints after `git gc -q --prune=now`.

### P3 (5 points)

<!-- snippet: gates/g4-predict/p3-setup -->
```text
$ git init -q loader
$ cd loader
$ printf 'workers: 2\n' > loader.yaml
$ printf 'shuffle: true\n' > sampler.yaml
$ git add . && git commit -q -m "Add loader and sampler configuration"
$ printf 'workers: 8\n' > loader.yaml
$ git add loader.yaml
$ printf 'shuffle: false\n' > sampler.yaml
$ printf 'profile the loader\n' > todo.txt
$ git stash -q
```
<!-- /snippet -->

Predict:

1. The output of `git status --short`.
2. The number of parents of the commit `stash@{0}`.

Then:

<!-- snippet: gates/g4-predict/p3-setup-b -->
```text
$ git stash pop -q
```
<!-- /snippet -->

Predict:

3. The complete output of `git status --short`, with the exact two status characters of every line.
4. The output of `git stash list`.

### P4 (5 points)

<!-- snippet: gates/g4-predict/p4-setup -->
```text
$ git init -q client
$ cd client
$ printf 'retries = 3\ntimeout = 30\nbackoff = 2\nverify = true\n' > client.cfg
$ git add . && git commit -q -m "Add client settings"
$ printf 'timeout = 30\nbackoff = 2\nverify = true\nretries = 3\n' > client.cfg
$ git commit -q -am "Move retries to the end"
$ printf 'timeout = 30\nbackoff = 2\nverify = true\nretries = 5\n' > client.cfg
$ git commit -q -am "Retry five times"
```
<!-- /snippet -->

Predict the subjects each command lists, newest first:

1. `git log --format=%s -S'retries = 3'`
2. `git log --format=%s -G'retries = 3'`
3. `git log --format=%s -L4,4:client.cfg -s` (the history of line 4 of the current file)

---

## Part 3: Hands-on diagnosis (30 points)

One generated sandbox. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| Build it | `assessments/gen/gate-4-recovery/variant-a/generate.sh` | `assessments/gen/gate-4-recovery/variant-b/generate.sh` |
| What was reported | [`variant-a/SYMPTOMS.md`](gen/gate-4-recovery/variant-a/SYMPTOMS.md) | [`variant-b/SYMPTOMS.md`](gen/gate-4-recovery/variant-b/SYMPTOMS.md) |
| Check the end state | `assessments/gen/gate-4-recovery/variant-a/check.sh` | `assessments/gen/gate-4-recovery/variant-b/check.sh` |

Run the generator from the course root, open the lab shell at the path it prints, and read `SYMPTOMS.md`. Do not read `generate.sh` or `check.sh`. Keep a log of every command you type; the log is graded.

Two commands are forbidden in this part until `check.sh` passes, because each can destroy what you are looking for: `git gc` and `git prune`, in any form.

| Graded on | Points | What earns them |
|---|---|---|
| End state | 12 | `check.sh` ends with `PASS`. One point is lost for each failed line, down to zero |
| Safety of the path | 8 | Read-only search first; every candidate object inspected before a ref is created; found objects anchored with a ref before any other change; no collection, no pruning, no `git reset --hard` |
| Explanation | 10 | What each found object is and how it was identified; why the reflog did not help; and a correct, reasoned "this cannot be recovered" for the one item that cannot |

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each, without a terminal. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

Why does `git reset --hard` not necessarily delete commits permanently? *Follow-up:* then what does it delete permanently?

### O2 (3 points)

How does the reflog help you, and what are its limits? *Follow-up:* a colleague force-pushed over your branch on the server. Does a reflog help, and whose?

### O3 (3 points)

Why can a commit become unreachable, and what happens to it then? *Follow-up:* how do you recover a branch that was deleted a week ago?

### O4 (3 points)

How does `git bisect` find a commit, and what must be true of the bug for the result to be right? *Follow-up:* some commits in the range do not build. What do you do?

### O5 (4 points)

A developer says: "I lost a morning of work, and `git stash list` is empty." Walk me through your first five minutes at their machine. *Follow-up:* which answers from the developer would make you say "this is gone", and what do you tell them?

### O6 (4 points)

`git blame` names a commit for the broken line, and the author says they only ran the formatter. How do you find the commit that introduced the logic? *Follow-up:* the function was moved from another file in a later commit. What changes?

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
| C1 | Chapter 13, sections 13.2 and 13.4 | 12 |
| C2 | Chapter 13, sections 13.3 and 13.4 | 12 |
| C3 | Chapter 13, sections 13.8, 13.9 and 13.12 | 12 |
| C4 | Chapter 13, section 13.6; Chapter 3, section 3.8 | 12, 16 |
| C5 | Chapter 14A, sections 14A.10 to 14A.12, 14A.16 to 14A.20 | 11 |
| C6 | Chapter 13, sections 13.5 and 13.8 | 12 |
| P1 | Chapter 13, sections 13.3 and 13.5 | 12 |
| P2 | Chapter 13, section 13.6; Chapter 3, section 3.8 | 12 |
| P3 | Chapter 11, section 11.11 | 8 |
| P4 | Chapter 14A, sections 14A.11 and 14A.12 | 11 |
| Hands-on A | Chapter 13, sections 13.6, 13.7, 13.9 and 13.12; Chapter 11, section 11.11; Chapter 14B, section 14B.8 | 12, 13 |
| Hands-on B | Chapter 14A, sections 14A.10, 14A.19 to 14A.21; Chapter 13, sections 13.6, 13.8 and 13.12; Chapter 11, section 11.8 | 11, 12 |
| O1 | Chapter 13, section 13.2; Chapter 11, section 11.5 | 8, 12 |
| O2 | Chapter 13, sections 13.3, 13.4 and 13.10 | 12 |
| O3 | Chapter 13, sections 13.2 and 13.8 | 12 |
| O4 | Chapter 14A, sections 14A.20 to 14A.22 | 11 |
| O5 | Chapter 13, sections 13.7, 13.9 and 13.12 | 12 |
| O6 | Chapter 14A, sections 14A.16 to 14A.19 | 11 |

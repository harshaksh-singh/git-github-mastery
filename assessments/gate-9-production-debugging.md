# Gate 9: Production debugging

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, as the textbook cites them. Every transcript in this file is real output of `labs/gates/g9-predict.sh`. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 38. **Covers** the diagnosis method, the ten incidents, communication and postmortems: Chapters [29](../textbook/ch29-production-troubleshooting.md) and [30](../textbook/ch30-incident-response.md), on top of everything the earlier gates covered. Chapter [27](../textbook/ch27-open-source-team-workflows.md) supplies the release strategies that the hands-on part assumes.

**Pass rule.** 90 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 75 minutes, lab shell, including the written hand-in |
| 4 Oral interview | 20 | 14 | 25 minutes, spoken, no terminal |

**What this gate measures.** The earlier gates asked whether you know how Git and GitHub behave. This one asks whether you can use that under pressure and with bad information: evidence before action, the lowest-risk repair, proof that it worked, and four lines that a CTO can act on.

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences.

### C1 (5 points)

State the diagnosis method as three phases, with what you are allowed to do in each and what marks the boundary between them. Name the places whose state you must be able to describe before you may state a root cause, with one command for each. Why does the method ask for at least three hypotheses before the first test, and why is "the repository can be copied in seconds" an advantage that an accident investigator does not have?

### C2 (5 points)

A developer says: "It is pushed. GitHub must be caching." Name the three repositories or refs that hold "the branch", and the commands that read each one without changing anything. Give three different states of those three that produce the developer's sentence, each with the one command that tells it apart from the others.

### C3 (5 points)

State the questions by which you rank candidate repairs from lowest to highest risk. Apply them to this choice and say which you take and why: a merge that brought wrong content onto a shared, deployed branch three commits ago can be undone by (a) `git reset --hard` to the commit before it and a forced push, (b) `git revert -m 1`, (c) an interactive rebase that drops it and a forced push with lease. Then say what the chosen repair costs later, and what would change your choice.

### C4 (5 points)

Some questions about an incident cannot be answered from any clone. Give three such questions, the reason Git cannot answer each, and the GitHub-side source that can, with one limit of that source. Then give one question for which the best evidence is in a colleague's clone and nowhere else, and say what you ask that colleague not to do.

### C5 (5 points)

Classify these four events by severity and say who must be told and when: a developer's local `git reset --hard` destroyed an afternoon of uncommitted work; a live cloud credential was pushed to a public repository; a shared feature branch was rebased and force-pushed, and two colleagues cannot push; a clean merge silently dropped a fix that then went to production. Then give the four parts of the summary a CTO needs, in order, with the rule that governs each part.

### C6 (5 points)

"We told everyone to be more careful" is not a control. Explain why, and give the five strengths of control in order with one example each. For the root cause "the release branch accepted a merge of `main`", name the strongest control that is available and one weaker control that you would add anyway, and say how you will know that each works. What does "blameless" mean in a postmortem, and why is it a technical requirement and not a courtesy?

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect and one sentence of mechanism for each prediction. Where a commit ID would appear, write `<id>`.

### P1 (5 points)

<!-- snippet: gates/g9-predict/p1-setup -->
```text
$ git init -q hotfixes
$ cd hotfixes
$ printf 'limit: 10\n' > limits.yaml && git add . && git commit -q -m 'Add limits'
$ git switch -q -c fixes
$ printf 'retries: 3\n' > retry.yaml && git add . && git commit -q -m 'Fix A: add retries'
$ printf 'limit: 20\n' > limits.yaml && git commit -q -am 'Fix B: raise the limit'
$ printf 'timeout: 5\n' > timeout.yaml && git add . && git commit -q -m 'Fix C: add a timeout'
$ git switch -q main
$ printf 'limit: 15\n' > limits.yaml && git commit -q -am 'Tune the limit'
$ git cherry-pick main..fixes > /dev/null 2>&1; echo "exit status: $?"
exit status: 1
$ git status --short
UU limits.yaml
# The developer wants to get out of the conflict and types:
$ git reset -q --hard
```
<!-- /snippet -->

Predict:

1. What `git status` reports about an operation in progress, and whether it reports any change.
2. The three newest subjects on `main`.

Then:

<!-- snippet: gates/g9-predict/p1-setup-b -->
```text
# Seeing "cherry-pick in progress", the developer continues:
$ git cherry-pick --continue > /dev/null 2>&1; echo "exit status: $?"
exit status: 0
```
<!-- /snippet -->

Predict:

3. The four newest subjects on `main`, and the content of `limits.yaml`.
4. Which of the three fixes is not on `main`, and whether any command reported that.

### P2 (5 points)

<!-- snippet: gates/g9-predict/p2-setup -->
```text
$ git init -q billing
$ cd billing
$ printf 'a\n' > core.txt && git add . && git commit -q -m 'Add core'
$ git switch -q -c feature/invoices
$ printf 'i\n' > invoices.txt && git add . && git commit -q -m 'Add invoices'
$ git switch -q main
$ git merge -q --no-ff -m "Merge feature/invoices" feature/invoices
$ printf 'a\nb\n' > core.txt && git commit -q -am 'Extend core'
$ git revert -m 1 --no-edit HEAD~1 > /dev/null
```
<!-- /snippet -->

Predict:

1. The output of `git ls-files`.
2. The exit status of `git merge-base --is-ancestor feature/invoices main`, and the output of `git branch --merged main`.
3. The output of `git merge feature/invoices`, and of `git ls-files` afterwards.

### P3 (5 points)

<!-- snippet: gates/g9-predict/p3-setup -->
```text
# you/ and asha/ are clones of one server. feature/cache has one commit, "Add cache", pushed by you.
$ git -C ../asha switch -q feature/cache
$ git -C ../asha commit -q --allow-empty -m "Asha: add cache metrics"
$ git -C ../asha push -q origin feature/cache
$ git commit -q --amend --allow-empty -m "Add cache with eviction"
$ git fetch -q
$ git status -sb
## feature/cache...origin/feature/cache [ahead 1, behind 2]
```
<!-- /snippet -->

Predict:

1. Whether `git push --force-with-lease --force-if-includes origin feature/cache` is accepted, its exit status, and the subjects on the server's `feature/cache` afterwards.

Then the same push without the second option runs:

<!-- snippet: gates/g9-predict/p3-setup-b -->
```text
$ git push --force-with-lease origin feature/cache > push.log 2>&1; echo "exit status: $?" >> push.log
```
<!-- /snippet -->

2. Predict the exit status that the last line of `push.log` records, and the subjects on the server's `feature/cache` afterwards.
3. Say where Asha's commit can still be found, and by whom.

### P4 (5 points)

<!-- snippet: gates/g9-predict/p4-setup -->
```text
# you/ cloned the server when v1.4.0 named "Release candidate". Then, in ravi/:
$ git -C ../ravi commit -q --allow-empty -m "Late fix"
$ git -C ../ravi tag -f -a v1.4.0 -m "1.4.0" > /dev/null
$ git -C ../ravi push -q --force origin main v1.4.0
```
<!-- /snippet -->

Predict, in `you/`:

1. What `git fetch` updates, and the subject of the commit that the local tag `v1.4.0` names afterwards.
2. What `git fetch --tags` prints for the tag, its exit status, and the subject of the commit that the local tag names afterwards.
3. The subject of the commit that the server's `v1.4.0` names. Say what a build "of v1.4.0" contains, depending on where it is built.

---

## Part 3: Hands-on diagnosis (30 points)

One generated incident with a server and several clones, and statements from the people involved that are incomplete and partly wrong. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| Build it | `assessments/gen/gate-9-production-debugging/variant-a/generate.sh` | `assessments/gen/gate-9-production-debugging/variant-b/generate.sh` |
| What was reported | [`variant-a/SYMPTOMS.md`](gen/gate-9-production-debugging/variant-a/SYMPTOMS.md) | [`variant-b/SYMPTOMS.md`](gen/gate-9-production-debugging/variant-b/SYMPTOMS.md) |
| Check the end state | `assessments/gen/gate-9-production-debugging/variant-a/check.sh` | `assessments/gen/gate-9-production-debugging/variant-b/check.sh` |

Run the generator from the course root, open the lab shell at the path it prints, and read `SYMPTOMS.md`. Do not read `generate.sh` or `check.sh`. Keep a log of every command you type, with the three phases marked; the log is graded. `SYMPTOMS.md` lists what you hand in besides the repository.

| Graded on | Points | What earns them |
|---|---|---|
| End state | 10 | `check.sh` ends with `PASS`. One point is lost for each failed line, down to zero |
| Safety of the path | 8 | A read-only phase that asks the server directly; each statement of a colleague tested before it is used or dismissed; a preservation step before the first change; the repair previewed; no forced push, no moved tag, no reset of a shared branch |
| Diagnosis | 6 | The verdict on each statement with its deciding command; the root cause in the form of the root-cause box, with the layer |
| Communication and prevention | 6 | The four-part summary for the CTO, with severity; the control with its strength; and the item that `SYMPTOMS.md` asks for about what follows from the repair |

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

A colleague calls: "Git lost my work." What do you do in the first five minutes, and what do you ask them not to do? *Follow-up:* give me three hypotheses and the command that separates them.

### O2 (3 points)

How do you decide which repair to use when several would work? *Follow-up:* when is a forced push the right answer?

### O3 (3 points)

`main` was force-pushed at three in the morning. What can Git tell you, and what can only GitHub tell you? *Follow-up:* nobody has fetched since yesterday except one build server. Why does that matter?

### O4 (3 points)

How do you verify that a repair worked? *Follow-up:* give me an example in which the obvious check passes and the repair is wrong.

### O5 (4 points)

It is forty minutes into an incident and I, the CTO, ask: "Who did this?" Answer me. *Follow-up:* now give me the summary I need, for an incident of your choice from the ten.

### O6 (4 points)

The postmortem of a force push over `main` lists twelve action items. Which one matters, and how do you rank the rest? *Follow-up:* the strongest control is not available on our plan. What do you do?

---

## Score sheet

| Item | Max | Score | | Item | Max | Score |
|---|---|---|---|---|---|---|
| C1 | 5 | | | P1 | 5 | |
| C2 | 5 | | | P2 | 5 | |
| C3 | 5 | | | P3 | 5 | |
| C4 | 5 | | | P4 | 5 | |
| C5 | 5 | | | **Prediction** | **20** | |
| C6 | 5 | | | H end state | 10 | |
| **Concepts** | **30** | | | H safety | 8 | |
| O1 to O4 | 12 | | | H diagnosis | 6 | |
| O5, O6 | 8 | | | H communication | 6 | |
| **Oral** | **20** | | | **Hands-on** | **30** | |
| | | | | **Total** | **100** | |

Pass: total 90 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, run the incident drills of Modules 36 and 37 again from the symptoms, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 29, section 29.2; Chapter 1, sections 1.10 and 1.11 | 35 |
| C2 | Chapter 29, sections 29.3 and 29.4; Chapter 12, sections 12.4 and 12.14 | 35 |
| C3 | Chapter 29, section 29.9; Chapter 11, section 11.9 | 35 |
| C4 | Chapter 29, sections 29.7 and 29.8; Chapter 13, section 13.10 | 35, 38 |
| C5 | Chapter 30, sections 30.3 and 30.15 | 38 |
| C6 | Chapter 30, sections 30.19 and 30.20 | 38 |
| P1 | Chapter 29, section 29.6; Chapter 10, section 10.6 | 35 |
| P2 | Chapter 11, section 11.9; Chapter 30, section 30.13 | 36 |
| P3 | Chapter 12, section 12.8; Chapter 30, sections 30.6 and 30.8 | 37, 38 |
| P4 | Chapter 14B, sections 14B.10 and 14B.11 | 13 |
| Hands-on A | Chapter 29, sections 29.2, 29.7, 29.9 and 29.10; Chapter 11, sections 11.8 and 11.9; Chapter 27, sections 27.8 to 27.10; Chapter 30, sections 30.15 and 30.20 | 32, 35, 38 |
| Hands-on B | Chapter 29, sections 29.2, 29.9 and 29.10; Chapter 27, sections 27.9 and 27.10; Chapter 10, sections 10.9 and 10.10; Chapter 14B, sections 14B.8 and 14B.14; Chapter 30, sections 30.15 and 30.20 | 32, 35, 38 |
| O1 | Chapter 29, sections 29.2 and 29.7; Chapter 13, section 13.7 | 35 |
| O2 | Chapter 29, section 29.9 | 35 |
| O3 | Chapter 29, section 29.8; Chapter 13, sections 13.10 and 13.15 | 37 |
| O4 | Chapter 29, section 29.10 | 35 |
| O5 | Chapter 30, sections 30.15 and 30.19 | 38 |
| O6 | Chapter 30, section 30.20; Chapter 18, section 18.15 | 38 |

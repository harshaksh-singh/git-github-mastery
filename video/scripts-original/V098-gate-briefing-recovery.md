# V098: Gate briefing: Recovery

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15 (the Recovery gate follows Modules 11 to 15)
- **Planned minutes.** 10
- **Prerequisites.** V072, V079, V097
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), sections 13.6, 13.7 and 13.12; the gate rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch13/fsck-find.sh` (snippets `01-with-reflogs`, `02-no-reflogs`, `03-triage`, `05-anchor`)

## HOOK

**[ON SCREEN]** "A correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail this row."

That sentence is from the rules of the gates, about the hands-on part. Read it again. You can bring the lost work back, have every check print PASS, and still lose the points for safety.

In the Recovery gate you are handed a repository that has lost something, and a report about it that is incomplete and partly wrong. The candidates who fail are rarely the ones who do not know the reflog. They are the ones who type a destructive command in the first minute, before they have looked.

## INTRODUCTION

This is a briefing, not a lesson. It tells you what Gate 4 covers, how it is taken, and how to prepare. It does not show the gate. The gate file is not opened on screen, and you should not open it either before you take it: in the words of the rules, a gate that has been read is a gate that has been taken.

The warm-up is one replay you have seen, run this time as a drill: find, triage, anchor.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- state what Gate 4 covers and its threshold of 90;
- recite the recovery method and apply it before touching a broken repository;
- say for each kind of lost work whether an object can exist;
- prepare the oral part with the limits of each safety net.

## CONCEPT

**What the gate covers.** Gate 4, Recovery, is taken after Module 15. It covers forensics, the reflog, `git fsck`, the disaster recoveries, and what cannot be recovered. It passes at 90.

**[ON SCREEN]** The four parts, from the gate rules.

| Part | Points | Form | Conditions |
|---|---|---|---|
| 1 Concepts | 30 | Six written questions, 5 points each. Each requires a mechanism: which objects, refs, files or rules are involved and what reads or writes them | Closed book, no terminal |
| 2 Prediction | 20 | Four items, 5 points each. You get the commands that built a state and predict the output of further commands and the new state | No terminal. Object IDs are not asked for |
| 3 Hands-on diagnosis | 30 | A repository that a script builds in a broken state, with a report that is incomplete and partly wrong | Lab shell |
| 4 Oral interview | 20 | Six questions asked one at a time, each with a follow-up: four at 3 points, two at 4 points | Spoken, no terminal, no notes |

**The pass rule.** The threshold of the gate overall, and at least 70 percent in every part: 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in Hands-on, 14 of 20 in Oral. A total above the threshold with one part below 70 percent is a miss.

**How the hands-on part is scored.** Three ways. The end state: a check script inspects the sandbox with read-only commands and prints one line per condition. The safety of the path: your command log is read, for evidence before change, a way back before each rewrite, and no command that could destroy uncommitted or shared work where a safer one exists. And the explanation: root causes in the seven-line form of the root-cause box.

So keep a log of every command. And do not read the generator script, which is the answer to "what happened", or the check script, which lists the end state line by line.

**How to work in part 3.** The eight steps of the recovery method are the procedure, in this order: stop; record the symptom and the last commands; classify; find the ID; anchor it; inspect before you move anything; integrate with the lowest-risk move; verify, then clean up. Step three contains the question that decides everything else: was the work ever an object? Committed, stashed or staged: yes. Saved and never staged, or untracked: no.

**The honest answer.** The gate also asks for the answer a senior engineer must be able to give: this cannot be recovered, and here is exactly why. A "no" with a mechanism scores. A hopeful search of an hour does not.

**After a miss.** A miss leads to remediation and a different variant, not to the answers. You retake the whole gate after at least two days, with variant B for the hands-on part.

## MENTAL MODEL

Treat the gate's repository as you would a colleague's laptop during an incident. It is not yours to experiment on. Every command you type is either evidence, a way back, or a change, and you should be able to say which before you press return.

The method gives you the order: evidence first, a way back second, a change third. A candidate who reverses the order can still arrive at the right files and fail the row.

Where this model is stricter than real life: in the gate, a re-clone is never the answer. In production it is rarely the answer either, and the gate is where you prove you know why.

## DIAGRAM

**[DIAGRAM]** The decision flow of section 13.7, once more. Trace it with a finger for the incident you are given before you type anything.

```text
  Was the lost work ever committed, stashed, or staged with "git add"?
   |
   +-- no ----> Git has no object. Editor history, IDE local history, backups, Time Machine.   (13.12)
   |
   +-- staged only ----> git fsck --lost-found ; look in .git/lost-found/other                  (13.9)
   |
   +-- stashed, then dropped or cleared ----> git fsck --unreachable | ... git log --merges     (13.9)
   |
   +-- committed
        |
        +-- Do you have the ID (scrollback, CI log, pull request, chat)? -- yes --> git branch rescue <id>
        |
        +-- Did a branch move (reset, rebase, merge, amend, cherry-pick)?
        |      --> git reflog show <branch> ; take the entry below the bad operation            (13.8)
        |
        +-- Is the branch itself gone, or was the work done in detached HEAD?
        |      --> git reflog (HEAD) ; or git fsck --no-reflogs for the dangling tips           (13.8)
        |
        +-- Did the server lose it (force push, deleted remote branch)?
        |      --> git reflog show origin/<branch> ; a teammate's clone ; the host's tools      (13.10, 13.15)
        |
        +-- No reflog entry anywhere (pruned fetch, expired log, other machine)?
               --> git fsck --lost-found ; then another clone, a bundle, a backup               (13.6, 13.14)
```

**[DIAGRAM]** Beside it, what cannot be recovered, from section 13.12, in short form.

```text
  LOST FOR GOOD                                         THE ONE REASON BEHIND EACH LINE
  ----------------------------------------------------  ----------------------------------------------
  edits never staged, then overwritten                  no object was ever written
  untracked or ignored files removed or overwritten     Git never stored them
  the reflog of a deleted branch                        deleted with the branch
  the name and staging time of a dangling blob          names live in trees and index entries
  which changes were staged, after a corrupt index      that existed only in the index file
  a commit whose reflog entries expired and whose       nothing names it and the object is deleted
  objects were pruned; a stash entry likewise
  anything in a deleted clone that was never pushed     the only object database that held it is gone
  a server branch's value before a force push, with     bare repositories keep no reflog by default
  no clone that fetched it and no record at the host
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/fsck-find` as a drill. Say each step of the method aloud as you reach it. A branch with three commits has been deleted, and a staged file was thrown away by a reset.

Step one, stop. Step three, classify: committed work, branch gone. Step four, find the ID. Predict what plain `git fsck` reports.

```bash
git branch -D exp/hybrid
git fsck
```

<!-- snippet: ch13/fsck-find/01-with-reflogs -->
```text
$ git branch -D exp/hybrid
Deleted branch exp/hybrid (was 2ae0c97).
$ git fsck
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
```
<!-- /snippet -->

`git branch -D` is 🔴 DANGEROUS: it deletes a ref together with its reflog. It is on screen as the accident, not as part of the recovery. Notice that it printed the old tip, `2ae0c97`. In the gate, read the scrollback and the report for lines like that first.

Plain `git fsck` shows only a blob: the commits are still reachable from the HEAD reflog. Take the reflogs out of the roots.

```bash
git fsck --no-reflogs
git fsck --no-reflogs --unreachable
```

<!-- snippet: ch13/fsck-find/02-no-reflogs -->
```text
$ git fsck --no-reflogs
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
dangling commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
$ git fsck --no-reflogs --unreachable
unreachable blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
unreachable blob d101568e3177507ffec6dd9a56c478cce1751b2f
unreachable tree 918936da64f9772a5456d5940fb80ffa0d220346
unreachable tree 17b30d538538f6762ec168c66bcaeae783356477
unreachable commit 53c5b13f7e8f3f23e8a4363f15be846e93ff5862
unreachable blob 257d9cc0829b942c09bd1d17b1ec8490ec8bd2b1
unreachable commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
unreachable tree b08f744630034d54db33226cb5fff7e5a816fb87
unreachable blob 34ddd608dd3b612063f7806ca172b6ab36381925
unreachable commit b9975128858772d81064c041f60f4944ec3f428f
```
<!-- /snippet -->

One dangling commit. Now triage: which of possibly many dangling commits is the one you want?

```bash
git fsck --no-reflogs | awk '/dangling commit/ {print $3}' | xargs git log --no-walk --date=iso --format='%h  %cd  %an  %s'
git log --oneline 2ae0c97 --not --all
```

<!-- snippet: ch13/fsck-find/03-triage -->
```text
$ git fsck --no-reflogs | awk '/dangling commit/ {print $3}' | xargs git log --no-walk --date=iso --format='%h  %cd  %an  %s'
2ae0c97  2026-09-07 10:09:00 +0530  Lab User  Tune alpha to 0.6
$ git log --oneline 2ae0c97 --not --all
2ae0c97 Tune alpha to 0.6
53c5b13 Add hybrid weights
b997512 Add dense scorer
```
<!-- /snippet -->

Date, author, subject, and then the whole lost line. Step five, anchor. 🟢 SAFE: `git branch <name> <id>` adds one ref and changes nothing else.

```bash
git branch rescue/hybrid 2ae0c97
git fsck --no-reflogs
git log --oneline main..rescue/hybrid
```

<!-- snippet: ch13/fsck-find/05-anchor -->
```text
$ git branch rescue/hybrid 2ae0c97
$ git fsck --no-reflogs
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
$ git log --oneline main..rescue/hybrid
2ae0c97 Tune alpha to 0.6
53c5b13 Add hybrid weights
b997512 Add dense scorer
```
<!-- /snippet -->

Three commits on a rescue branch. Every command in this drill was read-only except one, and that one only added a ref. That is the shape of a safe path.

**[ON SCREEN]** How part 3 is started, from the gate rules. From the course root you run the generator of variant A, which prints the path of the sandbox; you open the lab shell there and read `SYMPTOMS.md`; when you think you are done, you run the check script. The generator runs with the fixed lab clock, so the commit IDs in your sandbox equal the IDs in the answer key; commits that you make in the lab shell use the real clock and get other IDs.

## COMMON MISTAKES

1. **Typing a destructive command in the first minute.** Root cause: the path is scored as well as the end state; evidence and a way back come before any change.
2. **Believing the report that comes with the repository.** Root cause: it is incomplete and partly wrong by design, like a real incident report; verify each claim with a read-only command.
3. **Repairing before anchoring.** Root cause: a found commit is still unreachable until a ref names it.
4. **Searching Git for work that was never an object.** Root cause: content that was never staged or committed has no object; the scoring answer is the mechanism, said plainly.
5. **Passing on the total and missing a part.** Root cause: each part needs at least 70 percent; a strong hands-on result does not offset a weak oral part.

## PRODUCTION EXAMPLE

The gate's hands-on part is modelled on the first ten minutes of a real incident: someone hands you a repository and a paragraph that begins "I think what happened is". The engineer who handles that well writes three things before typing a change: what the evidence commands showed, which commit IDs matter, in full, and which command will be the way back. Then she makes the smallest change that moves a ref to a commit that never stopped existing, and verifies it.

That written trail is the command log the gate asks for. If you produce it as a habit in the labs, the gate asks nothing new of you.

## PRACTICE EXERCISE

Redo Lab 12.1, "An accidental hard reset", to Lab 12.12, "Prove the point of no return", in [`lab-manual/m12-recovery.md`](../../lab-manual/m12-recovery.md) from symptoms only. This is the roadmap's second pass: do not read the lab text beyond the symptom.

For each lab, before any command, write the answers to the three questions: was it an object, does anything name it, has the clock run out. Keep a command log and mark every line as evidence, way back, or change.

The challenge is the gate itself: [`assessments/gate-4-recovery.md`](../../assessments/gate-4-recovery.md). Open it only when you sit down to take it.

## INTERVIEW QUESTION

**[ON SCREEN]** Q199: "Your CTO wants a short, defensible statement of what Git cannot recover, so that the team stops treating the reflog as a backup. What is on that list, and what single principle produces every line of it?"

You wrote this statement as homework three videos ago. Say it aloud now, without notes.

A strong answer is short enough to be read in a minute and is organised by cause, not by command. It finds the one principle that generates every line, in terms of objects and of names for them. It separates what was never stored from what was stored and has since lost every name and then the object. It corrects, in passing, the two losses people wrongly expect on the list. And it ends with what does count as a backup.

## RECAP

You should now be able to say:

- Gate 4 covers forensics, the reflog, `git fsck`, the disaster recoveries and what cannot be recovered; it passes at 90 with at least 70 percent in each of four parts.
- In the hands-on part the end state, the safety of the path and the explanation are all scored, so I log every command and look before I change.
- The method is stop, record, classify, find the ID, anchor, inspect, integrate with the lowest-risk move, verify.
- Work that was never staged or committed has no object, and I say so with the reason.
- I do not open the gate file, the generator or the check script before I take the gate.

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters [13](../../textbook/ch13-recovery.md), [14A](../../textbook/ch14a-history-investigation.md), [14B](../../textbook/ch14b-config-tags-signing.md), [14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), [22](../../textbook/ch22-git-lfs.md), [23](../../textbook/ch23-submodules.md) and [25](../../textbook/ch25-worktrees.md) aloud.

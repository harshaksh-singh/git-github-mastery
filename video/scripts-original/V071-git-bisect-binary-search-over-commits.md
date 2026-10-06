# V071: git bisect: binary search over commits

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 11, History investigation
- **Planned minutes.** 20
- **Prerequisites.** V024, V067
- **Textbook sections.** [Chapter 14A](../../textbook/ch14a-history-investigation.md), section 14A.20
- **Demo scripts.** `labs/ch14a/bisect-manual.sh`

## HOOK

**[ON SCREEN]** "The nightly evaluation scored 0.800 last Wednesday and 0.400 today, on the same model checkpoint. Which commit?"

In the previous video you answered this by reading: you guessed that the fault was in normalization, you blamed the function, you looked through the formatter. That worked because you had an idea of where to look.

Now remove the idea. The fault is in a file nobody suspects, or the diff between the last good release and today is four thousand commits by sixty people. Reading does not scale. What you do have is a test: one command that says yes or no. With a test and two endpoints, Git can find the commit in about twelve steps for four thousand commits, without you understanding the code at all.

## INTRODUCTION

This is step 6 of the method from the last video: search by behavior. The tool is `git bisect`. Today you run one bisection by hand, verdict by verdict, so that you see every piece of state it creates. In the next video you hand the verdicts to a script.

You need two things from earlier in the course. From the detached HEAD video: what it means that HEAD names a commit and no branch. From the `git log` video: the range `v0.1.0..main`, which had twenty commits. You were told to keep that number. Here is where it is spent.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- explain why a bisection over n commits needs about log2(n) tests, and what it assumes;
- run a manual bisection with a good and a bad commit;
- skip a commit that cannot be tested, and read what Git reports then;
- read the bisect state from its refs and its log, and end the session cleanly.

## CONCEPT

In one sentence: 🟡 CAUTION, `git bisect` finds the commit that changed a property by checking out a commit in the middle of the suspects, asking you for a verdict, and halving the suspects until one is left.

The label is CAUTION and not SAFE because bisect detaches HEAD and checks out other commits, and it writes refs and files into `.git`. It is recoverable with one command, `git bisect reset`.

Precisely. You give one commit that has the property, called "bad" or "new", and at least one ancestor that lacks it, called "good" or "old". The candidates are the commits reachable from the bad one and not from any good one. That is a range, the same two-dot range you already know. Git assumes there is a single first bad commit: in the manual's words, "all its descendants are 'bad' and all the other commits are 'good'". At each step it picks the candidate that splits the remaining candidates most evenly.

The arithmetic. Every verdict halves the candidates. So k verdicts can separate two to the power k candidates, and N candidates need about log2 of N verdicts.

**[ON SCREEN]** The table from section 14A.20.

| Candidates | Verdicts needed, about | A linear search, worst case |
|---|---|---|
| 20 | 4 or 5 | 20 |
| 1,000 | 10 | 1,000 |
| 1,000,000 | 20 | 1,000,000 |

Doubling the history adds one test. This is why "it worked in the last release" is enough of a starting point, however long ago that was.

Inside `.git`, a bisection is state, kept until you end it. Every verdict is a ref under `refs/bisect/`. A file `BISECT_START` holds where to return to, `BISECT_TERMS` holds the two words in use, and `BISECT_LOG` holds the session so far.

When to use it: when reading gives no suspect, or several. When not to: do not bisect what you can read. If the pickaxe or blame names one commit, and a test at that commit and its parent confirms it, you are done. And do not bisect before you have checked that the known-good commit is still good in today's environment. If the cause is a dependency that floated to a new version, or a data file outside Git, every commit may be bad and bisect will report whatever the noise selects.

One more requirement. Bisect needs commits that can be tested one by one. A history of small commits that each build gives an answer you can read in a minute. A history of large squashes gives an answer that is a two-thousand-line diff.

## MENTAL MODEL

The textbook's analogy is looking up a word in a printed dictionary. Open in the middle, see whether your word comes before or after, repeat with that half.

The analogy breaks in two places, and both are where bisections go wrong.

First, history is a graph, not a list. "The middle" has to be computed. With a merge in the range, the commit Git picks is not the one you would pick by counting lines of `git log`.

Second, a dictionary is sorted by construction. "Good before, bad after" is an assumption about your project, and bisect cannot verify it. If the bug was introduced, fixed and introduced again, there is more than one first bad commit. Bisect finds one transition and cannot tell you there are others.

**[PAUSE]** So every verdict you give is a statement of fact about one property. "The runner crashed" is not the same statement as "the score is wrong". Keep that distinction for the demonstration.

## DIAGRAM

**[DIAGRAM]** The picture from section 14A.20: the candidates in the order of the first-parent line, with the verdicts of the session you are about to watch. The two commits of the side branch are omitted. Do not show the verdict row yet; add each verdict as the demonstration reaches it.

```text
  v0.1.0   8e2cac1 ... 8657273  72134f3  8dc82cb  074d492  be9ad1b  d926d3c  9c8df98 ... d9d075d ... main
   good                          good(3)           skip(1)  good(5)  BAD(6)   bad(4)      bad(2)     bad
                                                                     ^ first bad commit
```

The numbers in brackets are the order in which Git asked. Step 1 lands near the middle and gets no verdict. Step 2 jumps to the right half. Step 3 jumps far left. After that, each step lands inside a range that is about half as long as the one before.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14a/bisect-manual`. `v0.1.0` scored the smoke set correctly; `main` does not.

**[ON SCREEN]** 🟡 CAUTION: `git bisect start`, `good`, `bad`, `skip`. Preview: `git status` must be clean, and `git rev-list --count <good>..<bad>` tells you the size of the search. Recovery: `git bisect reset`.

```bash
git rev-list --count v0.1.0..main
git bisect start
git bisect bad main
git bisect good v0.1.0
```

Predict: twenty candidates. Roughly how many steps will Git announce?

<!-- snippet: ch14a/bisect-manual/01-start -->
```text
$ git rev-list --count v0.1.0..main
20
$ git bisect start
status: waiting for both 'good' and 'bad' commits
$ git bisect bad main
status: waiting for 'good' commit(s), 'bad' commit known
$ git bisect good v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
```
<!-- /snippet -->

"9 revisions left to test after this (roughly 3 steps)". Git checked out `074d492`. That commit and its ancestors account for ten of the twenty candidates, so either verdict leaves ten suspects, one of which already has a verdict. The step count is an estimate computed from the number of candidates.

```bash
git status
```

<!-- snippet: ch14a/bisect-manual/02-status -->
```text
$ git status
HEAD detached at 074d492
You are currently bisecting, started from branch 'main'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

HEAD is detached at `074d492`, and `git status` tells you that you are bisecting and how to get back. Now run the test.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
```

**[PAUSE]** The output will be a `KeyError`. Before you see the next command, decide: is this commit good or bad?

```bash
git bisect skip
```

<!-- snippet: ch14a/bisect-manual/03-untestable -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
KeyError: '--limit'
$ git bisect skip
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
```
<!-- /snippet -->

Neither. The runner crashes for a reason that has nothing to do with scoring. Calling this "bad" would be a false statement about the property under investigation. `git bisect skip` says "no verdict", and Git picks another commit, `d9d075d`. Mark skip(1) on the diagram.

From here the test answers.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
git bisect bad
```

<!-- snippet: ch14a/bisect-manual/04-bad -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.400 token_f1=0.444 rouge_l=0.489
$ git bisect bad
Bisecting: 8 revisions left to test after this (roughly 3 steps)
[72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
```
<!-- /snippet -->

`exact_match=0.400`: bad. Git moves to `72134f3`, far to the left.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
git bisect good
```

<!-- snippet: ch14a/bisect-manual/05-good -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.800 token_f1=0.889
$ git bisect good
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
```
<!-- /snippet -->

`exact_match=0.800`: good. Three revisions left after this one. Two more verdicts.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
git bisect bad
python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
git bisect good
```

<!-- snippet: ch14a/bisect-manual/06-narrowing -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.400 token_f1=0.489
$ git bisect bad
Bisecting: 2 revisions left to test after this (roughly 1 step)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.800 token_f1=0.889
$ git bisect good
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

The formatter commit `9c8df98` is bad. `be9ad1b` is good. Git now says "0 revisions left to test after this" and has checked out `d926d3c`.

**[PAUSE]** Ask the audience: how many more verdicts are needed? Look at the diagram. A good commit on the left of `d926d3c`, a bad commit on its right, and nothing else between them.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
git bisect bad
```

<!-- snippet: ch14a/bisect-manual/07-found -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.400 token_f1=0.489
$ git bisect bad
d926d3c5a77b586297eb25335c33fed4aee6f053 is the first 'bad' commit
commit d926d3c5a77b586297eb25335c33fed4aee6f053
Author: Ravi Menon <ravi@example.com>
Date:   Thu Sep 10 13:36:00 2026 +0530

    Speed up normalize with a precompiled pattern
    
    str.translate built a table lookup per call. One compiled pattern is faster on the nightly set.

 scorekit/text.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

One. "`d926d3c5a77b586297eb25335c33fed4aee6f053` is the first 'bad' commit", and Git prints the commit. Five verdicts and one skip, and the same commit that blame and the pickaxe named. Bisect got there without knowing which file to look at.

Do not reset yet. Look at the state.

```bash
git for-each-ref --format="%(objectname:short) %(refname)" refs/bisect
ls .git | grep BISECT
```

<!-- snippet: ch14a/bisect-manual/08-state -->
```text
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/bisect
d926d3c refs/bisect/bad
682bc71 refs/bisect/good-682bc717015f0ab43b873d1df1ac9da0ba01c393
72134f3 refs/bisect/good-72134f33df03602df3b2fa85f5b7dfb0aa08c190
be9ad1b refs/bisect/good-be9ad1b4894348317c1e7ccb8276b8ad4760fb89
074d492 refs/bisect/skip-074d49249bcd54bc33537fe26519dd38e3c3ba85
$ ls .git | grep BISECT
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS
$ cat .git/BISECT_START .git/BISECT_TERMS
main
bad
good
$ git rev-parse --abbrev-ref HEAD
HEAD
```
<!-- /snippet -->

One ref named `refs/bisect/bad`, one ref per good commit with the full ID in its name, and one per skipped commit. And the `BISECT_` files in `.git`.

```bash
git bisect log
```

<!-- snippet: ch14a/bisect-manual/09-log -->
```text
$ git bisect log
git bisect start
# status: waiting for both 'good' and 'bad' commits
# bad: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
git bisect bad e376e5b709142415a87d49ca10af71977aaeabdc
# status: waiting for 'good' commit(s), 'bad' commit known
# good: [682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
git bisect good 682bc717015f0ab43b873d1df1ac9da0ba01c393
# skip: [074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
git bisect skip 074d49249bcd54bc33537fe26519dd38e3c3ba85
# bad: [d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
git bisect bad d9d075d63dcc94ce04c8e404e06b5cc3173180c2
# good: [72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
git bisect good 72134f33df03602df3b2fa85f5b7dfb0aa08c190
# bad: [9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
git bisect bad 9c8df98229e009115b3044edb1181d11075ecbbb
# good: [be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
git bisect good be9ad1b4894348317c1e7ccb8276b8ad4760fb89
# bad: [d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
git bisect bad d926d3c5a77b586297eb25335c33fed4aee6f053
# first 'bad' commit: [d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

`git bisect log` prints the session as commands that would reproduce it, with comments. This is evidence: paste it into the incident note. In the next video you replay it.

**[ON SCREEN]** 🟡 CAUTION: `git bisect reset`. It checks out the starting branch and deletes the bisect state. To keep the session, save `git bisect log` to a file first.

```bash
git bisect reset
git status --short --branch
git for-each-ref refs/bisect | wc -l
```

<!-- snippet: ch14a/bisect-manual/10-reset -->
```text
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
$ git status --short --branch
## main
$ git for-each-ref refs/bisect | wc -l
       0
```
<!-- /snippet -->

Back on `main`, no refs under `refs/bisect`.

**[ON SCREEN]** The state table of section 14A.20.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git bisect start [<bad> <good>...]` | once both ends are known: files of the chosen commit | matches that commit | detached at that commit | unchanged | `BISECT_START`, `BISECT_LOG`, `BISECT_TERMS` and others; `refs/bisect/bad`, `refs/bisect/good-<id>`; one HEAD reflog entry per checkout | unchanged | unchanged |
| `git bisect good`, `bad`, `skip` | files of the next commit | matches it | detached at the next commit | unchanged | one more ref under `refs/bisect/`; `BISECT_LOG` grows | unchanged | unchanged |
| `git bisect reset` | files of the starting branch | matches it | attached to the starting branch again | unchanged | every `BISECT_*` file and `refs/bisect/*` ref removed | unchanged | unchanged |

Read the fifth column of every row: the current branch ref never moves. A bisection is an inspection; your branch is where you left it.

## COMMON MISTAKES

1. **Marking a commit that crashes as "bad".** Root cause: a verdict is a statement about one property, and a crash for another reason is "no verdict"; the false statement sends the search into the wrong half.
2. **Starting a bisection with uncommitted changes.** Root cause: Git refuses to check out the next commit over uncommitted changes to files it has to replace.
3. **Trusting the result when the bug came and went.** Root cause: bisect assumes a single transition from good to bad and cannot detect that the property is not monotonic; test the reported commit and its parent yourself.
4. **Skipping commits next to the culprit and expecting one answer.** Root cause: the manual states that if you skip a commit adjacent to the one you are looking for, Git cannot tell which of them was the first bad one, and it ends with a list of candidates.
5. **Forgetting `git bisect reset`.** Root cause: until the reset, HEAD is detached, and commits made in that state belong to no branch.

## PRODUCTION EXAMPLE

A team that serves a retrieval model sees latency at the 95th percentile rise by a third between two weekly releases. About four hundred commits lie between the tags, from the service, the tokenizer wrapper and the batching code. Nobody has a suspect.

One engineer reduces the symptom to a single command: replay two hundred recorded requests against a local build and compare one number with a threshold. She first runs it on last week's tag, on today's machine, to confirm that last week's tag is still good. It is, so the cause is in the repository. Then she bisects. Four hundred candidates need about nine verdicts. Two commits do not build because a generated file is missing, and she skips them. The result is a commit that changed a default batch size. She tests that commit and its parent once more by hand, attaches the bisect log to the incident note, and only then opens the revert.

## PRACTICE EXERCISE

Do Lab 11.4, "A manual bisect", in [`lab-manual/m11-history-forensics.md`](../../lab-manual/m11-history-forensics.md).

Before you start, count the candidates and predict how many verdicts you will need. At every step, before you run the test, predict whether Git has moved left or right of the previous commit and why. The lab's failure scenario has you give a wrong verdict; predict where the search will end before you let it finish.

The challenge is Exercise 11.9, Level 4, "The regression among commits that cannot be tested", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q409: "A regression appeared somewhere in 4,000 commits. How many tests does a bisection need, what does it assume about the history, and how do you check that assumption when the result looks wrong?"

Pause and answer aloud.

A strong answer gives the number with its reasoning, not from memory: what one verdict does to the candidate set. It states the assumption in the manual's terms, a single first bad commit, and names at least two ways a real project violates it. It then describes a check that needs no new tool: what you test by hand, at which two commits, and what you read to audit the verdicts you gave. The best answers also ask a question back before they start: is the known-good commit still good today, in today's environment?

## RECAP

You should now be able to say:

- A bisection halves the candidates with every verdict, so N commits need about log2(N) tests.
- It assumes one transition from good to bad; it cannot verify that.
- A commit that cannot be tested is skipped, never called bad.
- The session is state: refs under `refs/bisect/` and `BISECT_` files, printed by `git bisect log` and removed by `git bisect reset`.
- The branch I started from does not move during a bisection.

## HOMEWORK

Read section 14A.20 of [Chapter 14A](../../textbook/ch14a-history-investigation.md).

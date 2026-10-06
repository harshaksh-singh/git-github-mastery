# V072: git bisect run, the exit-code protocol, custom terms, replay, --first-parent, and the pitfalls

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 11, History investigation
- **Planned minutes.** 22
- **Prerequisites.** V071
- **Textbook sections.** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.21, 14A.22 and 14A.25 to 14A.27
- **Demo scripts.** `labs/ch14a/bisect-run.sh`, `labs/ch14a/bisect-terms.sh`

## HOOK

**[ON SCREEN]** "Bisect names a commit that cannot be the cause."

An engineer automates a bisection overnight. In the morning the tool reports a first bad commit, with full confidence and a full commit ID. The commit adds a command-line option. It does not touch scoring at all.

The search was not broken. The test was. The script returned the runner's own exit status: 0 when the score passed, 1 when it did not. A crash also exits with 1. So the first commit that crashed for an unrelated reason was recorded as bad, Git searched among its ancestors, and it reported the commit that introduced the crash. The textbook's words for that answer are: precise, reproducible and wrong.

## INTRODUCTION

In the previous video you bisected by hand and gave five verdicts and one skip. Answering by hand is error-prone and does not scale past a handful of steps. Today the verdicts come from a program, and the contract between Git and that program is three numbers. You will also search for a fix instead of a bug, save and replay a session, and go through the pitfalls one by one.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- write a test script whose exit status follows the bisect protocol;
- automate a bisection with `git bisect run`;
- use custom terms for a search that is not about good and bad;
- save and replay a bisect log;
- explain what it means when bisect names a merge commit, and when `--first-parent` helps.

## CONCEPT

🟡 CAUTION: `git bisect run <cmd>` runs a command at every step and takes the verdict from its exit status. It carries the same label as the manual subcommands: it detaches HEAD, checks out other commits, and writes the bisect state.

The protocol has four rows. Exit status 0 means good, or old. Exit status 1 to 127, except 125, means bad, or new. Exit status 125 means this commit cannot be tested: skip it. Anything else, such as 128 and above, aborts the bisection.

Why three outcomes and not two? Because the question has three answers. A test for bisect must distinguish "has the property", "does not have it" and "cannot tell". That is the lesson of the hook, and it is the reason the number 125 exists.

Where the script lives matters. The manual advises keeping the test outside the repository, "to prevent interactions between the bisect, make and test processes and the scripts". A tracked script would be replaced by each commit's own version of it, or be absent in older commits.

**Terms.** "Good" and "bad" are awkward when you are looking for an improvement. `old` and `new` are built-in alternatives, and `--term-old` and `--term-new` let you choose your own words. The subcommands are then named after your words. For `git bisect run` the mapping stays positional: exit status 0 means the old state, whatever it is called.

**Log and replay.** The output of `git bisect log` is replayable. Save it, and a session can be repeated, handed to a colleague, or repaired. If you gave a wrong verdict: save the log, delete the wrong line and everything after it, run `git bisect reset`, and replay the edited file. You continue from the last correct verdict instead of starting over.

**More controls.** Paths after two dashes restrict the search to commits that touch those paths: fewer steps when you know the area. `--first-parent` follows only first parents, so a regression that arrived through a merge is attributed to the merge commit. `--no-checkout` does not touch the working tree and sets a ref named `BISECT_HEAD` for tests that read objects directly; that form is 🟢 SAFE. `git bisect skip` accepts a revision or a range, to mark commits untestable in advance. `git bisect visualize` shows the remaining candidates. And `git bisect reset <commit>` ends the session on that commit instead of the starting branch.

When to use `--first-parent`: when the commits inside merged branches are not required to work on their own.

When not to bisect at all, from section 14A.26. Do not bisect what you can read. Do not bisect before you have checked that the known-good commit is still good in today's environment. And one warning that belongs to security: `git bisect run` executes whatever the old commits contain, build scripts and test harnesses included. On an untrusted repository that is arbitrary code execution; do it in a sandbox.

## MENTAL MODEL

Keep the dictionary from the last video, and add a clerk. You no longer look at the page yourself. A clerk looks and holds up a card: green for "before", red for "after", and a third card that says "this page is torn, I cannot read it".

A clerk with only two cards has to lie about torn pages. That is the two-outcome test.

Where the model breaks: the clerk is your program running inside old checkouts of your own project. It is affected by what is installed, cached and compiled around the tracked files. The textbook's sentence is: a commit is only its tracked files; the environment around them is your responsibility.

## DIAGRAM

**[DIAGRAM]** The exit-status protocol of section 14A.21, as the table the presenter builds row by row.

```text
  exit status of the command          what git bisect run records
  ---------------------------------   ---------------------------------------
  0                                   good  (the OLD state, whatever it is called)
  1 to 127, except 125                bad   (the NEW state)
  125                                 skip: this commit cannot be tested
  anything else (128 and above)       no verdict: the bisection is aborted
```

Row one and row two are the two halves of the search. Row three is the torn page. Row four is the safety net: a status that no ordinary test returns stops the run instead of producing a verdict.

**[DIAGRAM]** Then the pitfall this video's interview question is about.

```text
        B---C            feature     B good, C good
       /     \
  A---D---E---M---F      main        E good, M BAD
              ^
              first bad commit is a merge: both parents good, the combination bad
```

When bisect names `M` and both `C` and `E` are good, neither side introduced the fault. The fault is in the combination.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14a/bisect-run`. First the script. Read the three exit statuses aloud.

```bash
cat ../check-em.sh
```

<!-- snippet: ch14a/bisect-run/01-script -->
```text
$ cat ../check-em.sh
#!/bin/sh
# Exit 0 if this commit scores the smoke set correctly, 1 if it does not,
# 125 if the runner cannot produce a score line at all (untestable: skip).
out=$(python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null)
case "$out" in
  *exact_match=0.800*) exit 0 ;;
  *exact_match=*)      exit 1 ;;
  *)                   exit 125 ;;
esac
$ ../check-em.sh; echo "exit status on main: $?"
exit status on main: 1
```
<!-- /snippet -->

Exit 0 if the score line shows `exact_match=0.800`. Exit 1 if there is a score line with another value. Exit 125 if the runner cannot produce a score line at all. Notice the path: one directory above the repository. The whole search is now two commands. Predict which commit it will name.

```bash
git bisect start main v0.1.0
git bisect run ../check-em.sh
```

<!-- snippet: ch14a/bisect-run/02-run -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ../check-em.sh
running '../check-em.sh'
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
running '../check-em.sh'
Bisecting: 8 revisions left to test after this (roughly 3 steps)
[72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
running '../check-em.sh'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
running '../check-em.sh'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
running '../check-em.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
running '../check-em.sh'
d926d3c5a77b586297eb25335c33fed4aee6f053 is the first 'bad' commit
commit d926d3c5a77b586297eb25335c33fed4aee6f053
Author: Ravi Menon <ravi@example.com>
Date:   Thu Sep 10 13:36:00 2026 +0530

    Speed up normalize with a precompiled pattern
    
    str.translate built a table lookup per call. One compiled pattern is faster on the nightly set.

 scorekit/text.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
bisect found first 'bad' commit
```
<!-- /snippet -->

The same sequence of commits as your manual session, without a human verdict. Now check what the 125 did.

```bash
git bisect log
```

<!-- snippet: ch14a/bisect-run/03-log -->
```text
$ git bisect log
# bad: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
# good: [682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
git bisect start 'main' 'v0.1.0'
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
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
```
<!-- /snippet -->

The line for `074d492` says skip. The crash was recorded as "no verdict", not as bad.

The same test fits on one line, with a weakness.

```bash
git bisect start main v0.2.0~4
git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null | grep -q exact_match=0.800'
git bisect reset
```

<!-- snippet: ch14a/bisect-run/04-one-liner -->
```text
# The same test without a script file. The exit status of grep is the verdict; a crash would count as bad.
$ git bisect start main v0.2.0~4
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[c0c9a304c3598a2f53abb36a10d5abe10e723be4] Add nightly evaluation set
$ git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null | grep -q exact_match=0.800'
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null | grep -q exact_match=0.800'
Bisecting: 1 revision left to test after this (roughly 1 step)
[9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null | grep -q exact_match=0.800'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null | grep -q exact_match=0.800'
d926d3c5a77b586297eb25335c33fed4aee6f053 is the first 'bad' commit
commit d926d3c5a77b586297eb25335c33fed4aee6f053
Author: Ravi Menon <ravi@example.com>
Date:   Thu Sep 10 13:36:00 2026 +0530

    Speed up normalize with a precompiled pattern
    
    str.translate built a table lookup per call. One compiled pattern is faster on the nightly set.

 scorekit/text.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
```
<!-- /snippet -->

The exit status of `grep` is the verdict. It works here because the range was chosen to contain no crashing commit; a crash would count as bad. Use the one-liner only when you know that.

Now two failures. Predict what an exit status of 200 does.

```bash
git bisect start main v0.1.0
git bisect run sh -c 'exit 200'
git bisect reset
```

<!-- snippet: ch14a/bisect-run/05-bad-exit-code -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run sh -c 'exit 200'
running 'sh' '-c' 'exit 200'
error: bisect run failed: exit code 200 from 'sh' '-c' 'exit 200' is < 0 or >= 128
[exit status: 56]
$ git bisect reset
Previous HEAD position was 074d492 Send warnings to stderr
Switched to branch 'main'
```
<!-- /snippet -->

"bisect run failed": the code is outside the protocol and the run stops. And a mistyped path. Shells return 127 for "command not found", which the protocol would read as bad.

```bash
git bisect start main v0.1.0
git bisect run ./check-em.sh
```

<!-- snippet: ch14a/bisect-run/06-missing-script -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ./check-em.sh
running './check-em.sh'
'./check-em.sh': ./check-em.sh: No such file or directory
[682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
running './check-em.sh'
'./check-em.sh': ./check-em.sh: No such file or directory
error: bogus exit code 127 for 'good' revision
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
[exit status: 1]
$ git bisect reset
Previous HEAD position was 074d492 Send warnings to stderr
Switched to branch 'main'
```
<!-- /snippet -->

Git 2.55 does not take 126 or 127 at face value on the first step. It runs the command on the known good commit as well, and stops when it gets the same code there: "bogus exit code 127 for 'good' revision".

One more failure from the same script: a dirty working tree.

```bash
git bisect start main v0.1.0
git bisect reset
```

<!-- snippet: ch14a/bisect-run/07-dirty-tree -->
```text
# An uncommitted edit in scorekit/config.py, a file that differs between the commits to visit:
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
error: Your local changes to the following files would be overwritten by checkout:
	scorekit/config.py
Please commit your changes or stash them before you switch branches.
Aborting
[exit status: 1]
$ git bisect reset
```
<!-- /snippet -->

An uncommitted edit in a file that differs between the commits to visit, and the checkout is refused. Start from a clean tree.

**[TERMINAL]** Replay `labs/run ch14a/bisect-terms`. A different question: since which commit does the runner work again without `--limit`? `8dc82cb` is known to crash.

```bash
git bisect start --term-old broken --term-new fixed
git bisect fixed main
git bisect broken 8dc82cb
git bisect terms
```

<!-- snippet: ch14a/bisect-terms/01-terms -->
```text
# Since which commit does the runner work again without --limit? 8dc82cb is known to crash.
$ git bisect start --term-old broken --term-new fixed
status: waiting for both 'broken' and 'fixed' commits
$ git bisect fixed main
status: waiting for 'broken' commit(s), 'fixed' commit known
$ git bisect broken 8dc82cb
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[78232321c82cb23d6fb732e4c8ee614c6f005919] Add ROUGE-L metric
$ git bisect terms
Your current terms are 'broken' for the old state
and 'fixed' for the new state.
```
<!-- /snippet -->

The subcommands are `broken` and `fixed` now. For the run, think positionally: exit 0 must mean the old state, which here is "broken". `grep -q KeyError` exits 0 when it finds the crash.

```bash
git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
```

<!-- snippet: ch14a/bisect-terms/02-run -->
```text
# For bisect run, exit status 0 means the OLD state. grep exits 0 when it finds the crash.
$ git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
be9ad1b4894348317c1e7ccb8276b8ad4760fb89 is the first 'fixed' commit
commit be9ad1b4894348317c1e7ccb8276b8ad4760fb89
Author: Lab User <you@example.com>
Date:   Thu Sep 10 12:31:00 2026 +0530

    Fix crash when --limit is not given
    
    Without the option the runner stopped with KeyError: '--limit'.

 scorekit/runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'fixed' commit
```
<!-- /snippet -->

"`be9ad1b4894348317c1e7ccb8276b8ad4760fb89` is the first 'fixed' commit". Save the session before you end it.

```bash
git bisect log > ../bisect.log
cat ../bisect.log
git bisect reset
```

<!-- snippet: ch14a/bisect-terms/03-save-log -->
```text
$ git bisect log > ../bisect.log
$ cat ../bisect.log
git bisect start '--term-old' 'broken' '--term-new' 'fixed'
# status: waiting for both 'broken' and 'fixed' commits
# fixed: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
git bisect fixed e376e5b709142415a87d49ca10af71977aaeabdc
# status: waiting for 'broken' commit(s), 'fixed' commit known
# broken: [8dc82cb2ce1f427dc306bce35c21a41f2e796b8d] Add --limit option to the runner
git bisect broken 8dc82cb2ce1f427dc306bce35c21a41f2e796b8d
# fixed: [78232321c82cb23d6fb732e4c8ee614c6f005919] Add ROUGE-L metric
git bisect fixed 78232321c82cb23d6fb732e4c8ee614c6f005919
# fixed: [be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
git bisect fixed be9ad1b4894348317c1e7ccb8276b8ad4760fb89
# broken: [074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
git bisect broken 074d49249bcd54bc33537fe26519dd38e3c3ba85
# first 'fixed' commit: [be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
$ git bisect reset
Previous HEAD position was 074d492 Send warnings to stderr
Switched to branch 'main'
```
<!-- /snippet -->

```bash
git bisect replay ../bisect.log
```

<!-- snippet: ch14a/bisect-terms/04-replay -->
```text
$ git bisect replay ../bisect.log
status: waiting for both 'broken' and 'fixed' commits
be9ad1b4894348317c1e7ccb8276b8ad4760fb89 is the first 'fixed' commit
commit be9ad1b4894348317c1e7ccb8276b8ad4760fb89
Author: Lab User <you@example.com>
Date:   Thu Sep 10 12:31:00 2026 +0530

    Fix crash when --limit is not given
    
    Without the option the runner stopped with KeyError: '--limit'.

 scorekit/runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git bisect reset
Already on 'main'
```
<!-- /snippet -->

The replay reaches the same commit without running one test. This file is what you hand to a colleague, and what you edit when one verdict was wrong.

Within one session the vocabulary is fixed.

```bash
git bisect start --term-old broken --term-new fixed
git bisect bad main 2>&1 | head -n 2
git bisect reset
```

<!-- snippet: ch14a/bisect-terms/05-good-bad-mixed -->
```text
$ git bisect start --term-old broken --term-new fixed
status: waiting for both 'broken' and 'fixed' commits
$ git bisect bad main 2>&1 | head -n 2
error: Invalid command: you're currently in a fixed/broken bisect
fatal: unknown command: 'bad'
$ git bisect reset
Already on 'main'
```
<!-- /snippet -->

Now `--first-parent`. Predict the candidate count.

```bash
git rev-list --count v0.1.0..main
git rev-list --count --first-parent v0.1.0..main
git bisect start --first-parent main v0.1.0
git bisect reset
```

<!-- snippet: ch14a/bisect-terms/06-first-parent -->
```text
$ git rev-list --count v0.1.0..main
20
$ git rev-list --count --first-parent v0.1.0..main
18
$ git bisect start --first-parent main v0.1.0
Bisecting: 8 revisions left to test after this (roughly 3 steps)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
$ git bisect reset
Previous HEAD position was be9ad1b Fix crash when --limit is not given
Switched to branch 'main'
```
<!-- /snippet -->

Eighteen candidates instead of twenty, and a different first commit to test, `be9ad1b`. `--first-parent` changes the candidate set, and with it the path of the search.

And the start that is the wrong way round.

```bash
git bisect start v0.1.0 main
git bisect reset
```

<!-- snippet: ch14a/bisect-terms/07-wrong-way-round -->
```text
$ git bisect start v0.1.0 main
Some 'good' revs are not ancestors of the 'bad' rev.
git bisect cannot work properly in this case.
Maybe you mistook 'good' and 'bad' revs?
[exit status: 1]
$ git bisect reset
```
<!-- /snippet -->

Git checks that every good commit is an ancestor of the bad one, and says so when it is not.

**[ON SCREEN]** The version note of section 14A.22. On Git 2.55 a finished bisection leaves you on the last tested commit until you run `git bisect reset`. Git 2.56 teaches `git bisect` an option `--reset-when-found`, which runs the reset automatically; that was not run here, and the textbook says its exact usage was not checked against the 2.56 manual. On 2.55, end every `git bisect run` in a script with an explicit `git bisect reset`.

## COMMON MISTAKES

1. **A two-outcome test.** Root cause: a crash and a wrong result both exit non-zero, so an untestable commit is recorded as bad; exit 125 for "cannot tell".
2. **A test script tracked in the repository.** Root cause: each checkout replaces it with that commit's version, or removes it in commits that predate it.
3. **A flaky or environment-dependent test.** Root cause: bisect accepts every verdict as fact and converges on an innocent commit without complaint; fix seeds, pin the data, compare against a threshold with a margin, and rebuild what is derived from the sources at every step.
4. **Custom terms with the exit statuses reversed.** Root cause: for `git bisect run` the mapping is positional; 0 is the old state whatever word you chose.
5. **Bisecting in a shallow clone.** Root cause: bisect can only visit commits that exist locally, and in a clone made with `--depth`, as CI checkouts often are, the good commit may not be present at all.

## PRODUCTION EXAMPLE

A team evaluating an LLM application sees answer quality on a regression set drop after a week of merges. The evaluation takes twenty minutes and its score varies slightly from run to run.

They apply the three rules of section 14A.21. They make the test as small as the symptom allows: twelve prompts that separated last week's build from today's, not the full suite. They make it deterministic: fixed seeds, pinned data, and a threshold with a margin between the good score and the bad one. And they rebuild what is derived from the sources at every step: installed packages, compiled extensions, caches. The script exits 125 when the package cannot be installed.

Bisect names a merge commit. Both parents pass. So nothing on either side is wrong by itself: one side renamed a prompt template field and the other added a caller of the old name. The merge was textually clean and semantically wrong. They look at the combined result of the merge, not at either branch.

## PRACTICE EXERCISE

Do Lab 11.5, "An automated `git bisect run`", in [`lab-manual/m11-history-forensics.md`](../../lab-manual/m11-history-forensics.md).

The lab runs the two-outcome test first. Before you run it, predict which commit it will name and why that commit is wrong. Then write the three-outcome script and predict which line of `git bisect log` will change.

The challenge is Exercise 11.11, Level 5, "Retrieval quality dropped on Friday", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q410: "Bisect reports a merge commit as the first bad commit, and both parents are good. What does that tell you, and what do you look at next?"

Pause and answer aloud.

A strong answer does not treat the result as a tool failure. It says what the result means about where the fault is, using the vocabulary of the merge videos: textually clean, semantically wrong. It says what to examine next and how, in terms of the merge's result against each parent. It separates this case from the one where `--first-parent` was used on purpose, in which a merge is the expected answer and stands for a whole branch. And it includes the check that applies to every surprising bisect result: confirm the verdicts at the reported commit and at its parents by hand.

## RECAP

You should now be able to say:

- `git bisect run` reads the exit status: 0 is the old state, 1 to 127 except 125 is the new state, 125 is skip, anything else aborts.
- The test script lives outside the tree being tested and must be deterministic.
- Custom terms rename the subcommands; they do not change which exit status means old.
- `git bisect log` is a replayable record: I can save it, edit it and replay it.
- A merge named as the culprit, with both parents good, means the fault is in the combination.

## HOMEWORK

Read sections 14A.21, 14A.22 and 14A.25 to 14A.27 of [Chapter 14A](../../textbook/ch14a-history-investigation.md). Then do the Practice section, 14A.29.

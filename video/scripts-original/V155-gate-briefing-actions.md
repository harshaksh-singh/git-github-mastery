# V155: Gate briefing: Actions

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 10
- **Prerequisites.** V154
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.8; [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), section 20B.11; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch20a/merge-ref.sh` (snippets `runner-checkout`, `what-is-checked-out`, `tests-on-the-merge`)

## HOOK

**[ON SCREEN]** One line: "The run was green. Which commit was tested?"

If you can answer that question for any run, from a workflow file and a description of the event, you are ready for Gate 7. If your first instinct is still to ask for the log, do the exercises at the end of this video first.

Gate 7 gives you workflow files, described runs and Git evidence. It gives you no GitHub, no run page and no log to scroll. Everything you need has to come from reading the file in order and knowing the defaults.

## INTRODUCTION

This is the briefing for the Actions gate. It tells you what the gate covers, how its hands-on part works, which two procedures to prepare with, and what form an answer should take. It does not open the gate file or the case files, and you should not open them before you sit the gate.

## LEARNING OBJECTIVES

After this video you can:

- state what Gate 7 covers and its threshold of 85;
- explain the paper format of the hands-on part and the rule never to copy or run its workflow files;
- prepare with the reading order for a workflow and the investigation order for a failure;
- answer every question with the commit, the ref, the event and the permissions.

## CONCEPT

**What the gate covers.** Gate 7 is taken after Module 28. It covers the workflow model, the first eleven workflows, runners, and CI debugging. It passes at 85. Security of workflows is not in this gate; that is Part 7 and Gate 8.

**The four parts** are the same as in every gate. Concepts: 30 points, six written questions, closed book, no terminal. Prediction: 20 points, four items. Hands-on diagnosis: 30 points. Oral interview: 20 points, six questions with follow-ups, spoken, without notes. The pass rule is the threshold overall and at least 70 percent in every part.

**The hands-on part is on paper.** Three cases, built from workflow files, described runs and real Git evidence.

**[ON SCREEN]** The rule for paper cases from `assessments/README.md`.

The rule says: these gates run nothing on GitHub; no GitHub output appears anywhere in them; and the only `gh` invocation you need is `gh` with a command and `--help`. Then two sentences that you must take literally. The workflow files in these directories are teaching material with faults on purpose. Never copy them into a repository, and never run them.

Why so strict? A file with a deliberate fault in its trigger, its permissions or its checkout is the kind of file Part 7 teaches you to fear. On paper it teaches. In a repository with a token, it acts.

**What a strong answer contains.** A strong answer names which commit was tested. More generally, every answer about a run states four things before it states a finding: the event, the ref and commit, the permissions of the token, and the runner. Then the finding.

## MENTAL MODEL

You prepare with two orders, and each answers a different question.

The reading order is for a file you have not run: trigger, permissions, job and runner, checkout, commands. It tells you when a run exists, with what authority, on what machine, with what code, and what the check is.

The investigation order is for a run that happened: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency.

They overlap on purpose. The first four steps of the investigation are the reading order applied to a concrete run. In a paper case you have no log at all, so everything you can conclude comes from the steps above the log. That is the gate's way of testing whether you have understood why the log is ninth.

Where this breaks down in the gate: you cannot observe. On your practice repository you could check a prediction by looking at a run. On paper, a claim such as "this job would be skipped" must be justified by a documented rule, stated in a sentence. "I think it would" earns nothing.

## DIAGRAM

**[DIAGRAM]** An answer frame of four lines and a finding. Fill it in for the case you will replay in a moment: a pull request whose tests pass on the author's machine and fail in the run.

```text
  event        : pull_request (synchronize), pull request 7
  ref, commit  : refs/pull/7/merge -> the test merge d04ef31, detached HEAD, one commit, no tags
                 (the author's commit is 80c9cfa; main is at 29b222b)
  permissions  : contents: read; every other permission none
  runner       : ubuntu-24.04, GitHub-hosted, fresh machine

  finding      : the run tested the merge of the head into the current base, not the head.
                 main changed behavior that the new code relies on; the merge is clean and wrong.
  next action  : merge the base into a detached copy of the branch to reproduce; fix; push.
  not proven   : anything about a base that has moved since this test merge was made.
```

**[DIAGRAM]** The last line is not decoration. Saying what a result does not prove is half of the interview question for this video.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up: Git evidence of the kind the paper cases contain. Replay with `labs/run ch20a/merge-ref`. You saw it in V145; now read it as a case. A bare repository stands in for GitHub; the IDs equal the book's.

**Step 1: the runner's checkout for a pull request.**

```bash
git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
git checkout --detach refs/remotes/pull/7/merge
```

`git fetch` is 🟢 SAFE. **[PAUSE]** Before the output: fill in line two of the answer frame from these two commands alone. Which ref, how many commits, what kind of HEAD?

<!-- snippet: ch20a/merge-ref/03-runner-checkout -->
```text
# The runner: fetch one commit, the one refs/pull/7/merge names, and detach HEAD on it.
$ git init --quiet runner && cd runner
$ git remote add origin "$HUB"
$ git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
From file://$LAB/ch20a/merge-ref/hub/inventory-api
 * [new ref]         refs/pull/7/merge -> pull/7/merge
$ git checkout --detach refs/remotes/pull/7/merge
HEAD is now at d04ef31 Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
```
<!-- /snippet -->

One ref, `refs/pull/7/merge`. HEAD is at `d04ef31`, and the subject of that commit names its two parents in full: your commit, merged into the tip of `main`.

**Step 2: what is checked out.**

```bash
git status --short --branch
git log -1 --format="GITHUB_SHA would be %H%n%an: %s"
git rev-list --count HEAD
git branch --show-current
```

<!-- snippet: ch20a/merge-ref/04-what-is-checked-out -->
```text
$ git status --short --branch
## HEAD (no branch)
$ git log -1 --format="GITHUB_SHA would be %H%n%an: %s"
GITHUB_SHA would be d04ef31e3ed5a74c9a89af11e2cbb441599e84c7
GitHub: Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
$ git rev-list --count HEAD
1
$ git branch --show-current
$ grep LOW_STOCK_THRESHOLD src/inventory_api/stock.py
LOW_STOCK_THRESHOLD = 10
def low_stock(stock, threshold=LOW_STOCK_THRESHOLD):
$ ls src/inventory_api
__init__.py
report.py
stock.py
```
<!-- /snippet -->

"HEAD (no branch)". The author of the commit is GitHub. One commit. No current branch. And the threshold in the source file is 10, the value from `main`. In a paper case, evidence like these lines is printed for you. Your job is to say what it means for the commands that follow.

**Step 3: the tests on the merge.**

<!-- snippet: ch20a/merge-ref/05-tests-on-the-merge -->
```text
# The merged code is what CI tests. main changed the threshold; the new test assumed 5.
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 1]
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
```
<!-- /snippet -->

Exit status 1, one failure. The author's branch passes; the merge fails. Both results are correct, and they tested different commits. That sentence, with the two commit IDs in it, is what a case answer needs.

## COMMON MISTAKES

1. **Describing a finding without saying which commit was tested.** Root cause: for `pull_request` the run is about the test merge, so a statement about "the commit" is ambiguous until you name it.
2. **Reasoning from a log you do not have.** Root cause: the paper cases contain files, descriptions and Git evidence; what you can conclude comes from the steps of the order that precede the log.
3. **Copying a case's workflow file to try it.** Root cause: those files have faults on purpose and would run with a real token.
4. **Reading the test command first.** Root cause: whether a run exists, and for which commit, is decided by the trigger and the event before any step runs.
5. **Claiming a behavior without the rule behind it.** Root cause: on paper nothing can be observed, so only a documented rule supports a prediction.

## PRODUCTION EXAMPLE

Picture an incident review at a company that serves models. A change reached production and broke a nightly job. The pull request had been green. The question in the review is the one from the hook: the run was green, so which commit was tested?

The engineer who answers uses the frame. Event: `pull_request`. Ref and commit: the test merge made on Tuesday afternoon. Permissions: read. Runner: hosted. Then the finding: three merges reached `main` between that test merge and the click on the merge button on Wednesday, and one of them changed a function the pull request calls. And then the control: the branch was not required to be up to date.

Nobody in the room needs the log. The review ends with a decision about a rule, which is what a review is for.

## PRACTICE EXERCISE

Redo four exercises in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md): Exercise 26.6, "Caches and artifacts"; Exercise 27.2, "A deployment with five flaws"; Exercise 28.5, "Green here, red in a fresh clone"; and Exercise 28.7, "Every pull request is waiting".

For each, write the four-line frame before anything else: event, ref and commit, permissions, runner. Predict in which line the fault will be found.

When you are ready, take Gate 7: [`assessments/gate-7-actions.md`](../../assessments/gate-7-actions.md). One sitting, parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q297: "A pull request's required checks went green yesterday afternoon. Since then `main` has received several merges, nothing was pushed to the pull request, and this morning an engineer re-ran the checks and they are green again. What exactly has been proven, and what closes the gap before merging?"

A strong answer separates the two green results and asks of each: which commit? Use what you know about what a re-run reuses. Then state precisely what has been proven and about which combination of head and base, and what has not. For the second half, name the controls that close the gap and what each costs. The follow-up adopts a merge queue to close that gap, and the queue then stalls with every entry waiting for a check; you met that in the last video.

## RECAP

You should now be able to say:

- Gate 7 covers the workflow model, the first eleven workflows, runners and CI debugging, and passes at 85 with at least 70 percent in every part.
- Its hands-on part is three cases on paper; the workflow files there have faults on purpose and are never copied or run.
- You prepare with the reading order for a file and the investigation order for a run.
- Every answer states the event, the ref and commit, the permissions and the runner, and then the finding, including what the result does not prove.

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 20A and 20B aloud.

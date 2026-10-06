# V191: CI works locally but fails on GitHub Actions, and senior standard 3: GitHub Actions suddenly fails

- **Part.** 9, Production debugging and incident response
- **Module.** 37, with Module 38
- **Planned minutes.** 22
- **Prerequisites.** V153, V154, V190
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.11 and 30.18
- **Demo scripts.** `labs/incidents/solve-07-ci-passes-locally.sh` (snippets `01-local` to `07-publish`)

## HOOK

**[ON SCREEN]** "It passes on my Mac. It must be a flaky runner. Can an admin merge it anyway? It is only a docstring."

A required check on `main` has been red for five days. One step fails on the runner with exit code 128. The script behind that step works on every laptop in the team. Re-runs fail identically. A developer with a harmless change is blocked, has a plausible culprit, and asks for the shortcut.

"Flaky" is a diagnosis, and it has a property you can test: a flaky failure does not repeat identically, and it does not start on one day and then fail on every run. This one does both. Today you refuse the word until the investigation order has been followed, and you rebuild the runner's view of the repository with Git alone.

## INTRODUCTION

**[PAUSE]** This is a debrief of Incident 7, [`incidents/07-ci-passes-locally`](../../incidents/07-ci-passes-locally/SYMPTOMS.md). You must have generated it, read its evidence directory, and attempted it. If you have not, stop the video here. The cause is named in the next section.

A word about the evidence. Incident 7 comes with a workflow file and a description of a failed run. Both were constructed for the exercise. Nothing was captured from GitHub, by the authors of the course or for this video, and no GitHub output appears on screen. The evidence that can be reproduced is on the Git side, and that is the point of the drill: for a large class of "passes locally, fails on Actions" problems, the difference is the repository the runner had.

From V153 you have the documented causes of that class. From V154, the debugging instruments. This incident is also the third scenario of the senior standard: "GitHub Actions suddenly fails".

## LEARNING OBJECTIVES

After this video you can:

1. Refuse "flaky runner" as a diagnosis until the investigation order has been followed.
2. Establish which commit the run tested and what the runner's repository contained.
3. Reproduce the runner's view locally with Git alone.
4. Fix the cause and predict what the next run will test.
5. Handle "nothing changed and CI fails" by listing what can change without a commit.

## CONCEPT

**"Suddenly" is a claim to test first.** Either something in the repository changed, a commit to the workflow, the lock file, the code; or something outside it did: a runner image, an action behind a moving tag, a secret, a cache. `git log --oneline -- .github/workflows` and the list of recent runs separate the two in a minute.

**[ON SCREEN]** The two commands of section 30.18, shown without output.

```bash
gh run list --workflow ci.yml --branch main --limit 20      # where does green turn red?
gh run view <run-id> --json event,headBranch,headSha,workflowName
```

The first answers "where does green turn red". The second answers "which commit did the run test, on which event".

**Then a fixed order.** The investigation goes from "did the right thing start" to "what did it say". An answer early in the list makes the later ones irrelevant.

**[ON SCREEN]** The table of section 30.18.

| # | Area | The question | Typical finding |
|---|---|---|---|
| 1 | Workflow | Which file, from which commit, defined the run? | `schedule` uses the file on the default branch; `workflow_dispatch` uses the file on the ref it was dispatched against, and can be started only if the file exists on the default branch |
| 2 | Event | What triggered it, and which commit was checked out? | `pull_request` builds the merge ref, not your head commit |
| 3 | Permissions | What could the token do? | Unlisted scopes are `none`; fork and Dependabot runs are read-only |
| 4 | Runner | Which image and size? | A `-latest` label moved; private repositories get smaller runners |
| 5 | Environment | Did the job reference one, and did its rules pass? | Waiting for approval; wrong branch for the environment |
| 6 | Dependencies | Were the same versions installed as locally? | No lock file, or not installed with `--locked` |
| 7 | Secrets | Were they present? | An unset or withheld secret is an empty string, not an error |
| 8 | Action versions | Which commit of each action ran? | An old major on a new Node runtime; a moved tag |
| 9 | Logs | What did the failed step print? | `gh run view <run-id> --log-failed` |
| 10 | Artifacts | Were the expected files produced and passed on? | Wrong name; expired |
| 11 | Cache | What was restored, under which key? | A broad `restore-keys` prefix restored a stale cache |
| 12 | Concurrency | Was the run cancelled or replaced? | Conclusion `cancelled`; a shared group name |

**Applied to Incident 7.** Areas 1 to 8 are answered from the workflow file and the run report without a log: one event, a read-only token, a fixed runner label, no environment, no secrets, both actions pinned by commit SHA. Area 9 gives one line, and it is a Git message: "fatal: No names found, cannot describe anything." That points at the repository the runner had, and Git can build the same one.

**The root cause.** `actions/checkout` fetches one commit and no tags by default; `git describe` needs history and tags. The README of the checkout action, version 7.0.1, says it fetches a single commit by default, with `fetch-tags` off, and that `fetch-depth: 0` fetches all history for all branches and tags. The step was added without changing the checkout it depends on. Layer: GitHub Actions, a documented default.

**Why both can be right.** "It passes on my machine" and "it fails on the runner" are both true, at the same commit, because the commit is not the whole input. A full clone has five commits and a tag. The runner's clone has one commit and no tag. Same commit ID, different repository around it.

**Two habits complete the standard.**

Look behind the first failure. The job never reached its tests. A second defect waits behind the first: a template tracked under one spelling while the code opens it under another, differing only in case, which works only on a filesystem that ignores case. A Mac's default filesystem does. The runner's does not.

And refuse the shortcut. A red required check is not overridden by an administrator because the change "is only a docstring". The answer to "merge it anyway" is no, with the reason.

**What "fixed" means here.** The honest status after the fix is pushed: "cause removed in the files; confirmed when the run on the fix branch is green." The files alone prove that the cause was removed, not that the job passes. Verification is a green run on the fix branch, observed on GitHub.

**Re-running.** Re-run with `gh run rerun <run-id> --failed --debug` only when the log is not enough. A re-run reuses the original commit and ref, so it cannot test a fix.

**Severity.** SEV 3: a team is blocked. The postmortem line is the uncomfortable one: five days of red on `main` hid a second, real defect.

## MENTAL MODEL

Think of the runner as a colleague who joined this morning, was handed a single printed page of the project, the latest one, and was asked to state the version number of the book. They cannot: the version is derived from a bookmark that sits many pages back, and they were not given those pages or the bookmark.

The colleague is not flaky. They will give the same answer every time. The mistake was in what they were handed, and it was a deliberate default: handing over one page is fast.

Where the picture breaks: a new colleague would ask for the rest of the book. A runner does what the workflow file says and reports exit code 128.

For "suddenly fails", sort every candidate cause into two columns: changes you can see with `git log`, and changes you cannot. The first column is short and is checked in a minute. If it is empty for the day the failure began, the cause is in the second.

## DIAGRAM

**[DIAGRAM]** A new list: "what changed?", in two columns, filled from section 30.18.

```text
  WHAT CHANGED?

  visible in git log                              not visible in git log
  ----------------------------------------------  ----------------------------------------------
  a commit to .github/workflows/                  the runner image (a -latest label moved)
  a commit to the lock file                       an action behind a moving tag
  a commit to the code or its tests               a secret (unset, rotated, withheld from forks)
  a commit to a script that a step runs           a cache (a broad restore key, a stale entry)
                                                  what the checkout fetched (depth, tags, merge ref)

  first:  git log --oneline -- .github/workflows      and      the list of recent runs:
          where does green turn red, and which commit was the first red one?
```

In Incident 7 the first red run coincides with a commit: the one that added the version step. So the cause is reachable from the left column, and "flaky" is excluded before the log is read. The last line of the right column is the bridge between the two: the commit is the same everywhere, and what surrounds it on the runner is not.

## LIVE TERMINAL DEMO

**[PAUSE]** From here on the screen shows the solution.

**[TERMINAL]** Replay `labs/run incidents/solve-07-ci-passes-locally`. Everything until the fix is 🟢 SAFE; the clone creates a new directory.

**It does pass locally.**

```bash
git log --oneline --decorate -5
cat scripts/version.sh
bash scripts/version.sh
```

<!-- snippet: incidents/solve-07-ci-passes-locally/01-local -->
```text
$ cd you
$ git log --oneline --decorate -5
367b8fb (HEAD -> main, origin/main) Move the template path into a constant
261eb76 Stamp reports with the version from git describe
5a1005a Add CI workflow
e18efbb (tag: v1.4.0) Add README
ef03c89 Add report renderer
$ cat scripts/version.sh
#!/usr/bin/env bash
# Prints the version of this checkout, derived from the newest release tag.
set -e
git describe --tags --match "v*"
$ bash scripts/version.sh
v1.4.0-3-g367b8fb
[exit status: 0]
```
<!-- /snippet -->

The script runs `git describe --tags --match "v*"` and prints a version built from the tag `v1.4.0`, three commits back. Exit status 0. The reporter is right about their machine.

**The workflow, and when it changed.**

```bash
grep -n -A1 'actions/checkout' .github/workflows/ci.yml
git log --oneline -- scripts/version.sh .github/workflows/ci.yml
```

<!-- snippet: incidents/solve-07-ci-passes-locally/02-workflow -->
```text
$ grep -n -A1 'actions/checkout' .github/workflows/ci.yml
18:      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
19-
$ git log --oneline -- scripts/version.sh .github/workflows/ci.yml
261eb76 Stamp reports with the version from git describe
5a1005a Add CI workflow
```
<!-- /snippet -->

The checkout step has no options: the line after it is empty. And the history of the two files: the workflow was added in one commit, the version step in a later one, `261eb76`. That is the left column of the diagram, answered: the first red run and this commit belong together.

**The runner's clone, made with Git.** Predict three things: how many commits, how many tags, and what the script prints.

```bash
git clone --quiet --depth 1 --no-tags "file://$PWD/../server.git" ../runner-checkout
cd ../runner-checkout
git rev-parse --is-shallow-repository
git rev-list --count HEAD
git tag --list
bash scripts/version.sh
```

<!-- snippet: incidents/solve-07-ci-passes-locally/03-runner-clone -->
```text
# What the checkout step does by default, reproduced with Git: depth 1 and no tags.
$ git clone --quiet --depth 1 --no-tags "file://$PWD/../server.git" ../runner-checkout
$ cd ../runner-checkout
$ git rev-parse --is-shallow-repository
true
$ git rev-list --count HEAD
1
$ git tag --list
$ bash scripts/version.sh
fatal: No names found, cannot describe anything.
[exit status: 128]
```
<!-- /snippet -->

**[PAUSE]** A shallow repository. One commit. No tags. And the script prints the same line as the run report, with exit status 128. The failure is reproduced on a Mac, with Git alone, with no runner involved. It is deterministic.

**Proof of the remedy.** What does `fetch-depth: 0` change? The same clone, with all history and the tags fetched.

```bash
git fetch --quiet --unshallow --tags
git rev-list --count HEAD
git tag --list
bash scripts/version.sh
```

<!-- snippet: incidents/solve-07-ci-passes-locally/04-remedy-proof -->
```text
# What "fetch-depth: 0" changes: all history and the tags.
$ git fetch --quiet --unshallow --tags
$ git rev-list --count HEAD
5
$ git tag --list
v1.4.0
$ bash scripts/version.sh
v1.4.0-3-g367b8fb
[exit status: 0]
```
<!-- /snippet -->

Five commits, one tag, and the script prints the version. The remedy is proven before the workflow is touched.

**Look behind the first failure.** Would the tests pass on Linux once the version step is fixed? Look at names as Git stores them.

```bash
git ls-files templates
grep -n 'tmpl' reports/render.py
git log --oneline -S'Summary.md.tmpl' -- reports/render.py
```

<!-- snippet: incidents/solve-07-ci-passes-locally/05-second-failure -->
```text
$ cd ../you
# Would the tests pass on Linux once the version step is fixed? Names as Git stores them:
$ git ls-files templates
templates/summary.md.tmpl
$ grep -n 'tmpl' reports/render.py
4:TEMPLATE = os.path.join(HERE, "templates", "Summary.md.tmpl")
$ git log --oneline -S'Summary.md.tmpl' -- reports/render.py
367b8fb Move the template path into a constant
```
<!-- /snippet -->

Git tracks `summary.md.tmpl` with a lower-case s. The code opens a name with a capital S. The pickaxe names the commit that introduced the spelling: `367b8fb`, made while `main` was already red. On a filesystem that ignores case this works. On the runner it would have failed as soon as the job got that far.

**The fix: one branch, one pull request.** 🟡 CAUTION: a commit and a push of a new branch.

<!-- snippet: incidents/solve-07-ci-passes-locally/06-fix -->
```text
$ git switch -c fix/ci-checkout
Switched to a new branch 'fix/ci-checkout'
# (edit .github/workflows/ci.yml: add "with: fetch-depth: 0" to the checkout step)
# (edit reports/render.py: spell the template name as it is tracked)
$ git diff
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index 683eadc..2df54cb 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -16,6 +16,8 @@ jobs:
     runs-on: ubuntu-24.04
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+        with:
+          fetch-depth: 0
 
       - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
         with:
diff --git a/reports/render.py b/reports/render.py
index 23a58f3..dca0003 100644
--- a/reports/render.py
+++ b/reports/render.py
@@ -1,7 +1,7 @@
 import os
 
 HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
-TEMPLATE = os.path.join(HERE, "templates", "Summary.md.tmpl")
+TEMPLATE = os.path.join(HERE, "templates", "summary.md.tmpl")
 
 def render(title, accuracy):
     with open(TEMPLATE) as f:
```
<!-- /snippet -->

Two changes in the diff. The checkout step gains `fetch-depth: 0`. The template name is spelled as it is tracked. Note what did not change: the action is still pinned to a full commit SHA.

<!-- snippet: incidents/solve-07-ci-passes-locally/07-publish -->
```text
$ git commit -a -m 'Fetch full history and tags in CI; fix template name case'
[fix/ci-checkout 194406a] Fetch full history and tags in CI; fix template name case
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git push -u origin fix/ci-checkout
To ../server.git
 * [new branch]      fix/ci-checkout -> fix/ci-checkout
branch 'fix/ci-checkout' set up to track 'origin/fix/ci-checkout'.
$ cd ..
$ incidents/07-ci-passes-locally/check.sh
Checking incident 07-ci-passes-locally
  ok    the server has the branch fix/ci-checkout
  ok    the branch is based on main
  ok    the checkout step fetches the full history and the tags (fetch-depth: 0)
  ok    actions/checkout is still pinned to a full commit SHA
  ok    the workflow still declares permissions
  ok    reports/render.py opens templates/summary.md.tmpl, which is tracked with exactly that spelling
  ok    the release tag v1.4.0 is still on the server
PASS: the recovery of incident 07-ci-passes-locally is complete.
[exit status: 0]
```
<!-- /snippet -->

The check passes. Read what it checks: the files. It cannot observe a run. So predict what the next run will test, which is objective four: a `pull_request` run for this branch checks out the merge ref, the head merged into the current base, with full history and tags; the version step finds the tag; the tests open the template under its tracked name. That is a prediction. The status to report is: cause removed in the files; confirmed when the run on the fix branch is green.

**The answer to the reporter.** No administrative merge. The failure is not flaky: it repeats, it began with a commit, and it can be reproduced on a laptop in six commands. The fix is in a pull request. And the docstring change is not held up by the runner; it is held up by a red default branch that should have been treated as an incident on its first day.

## COMMON MISTAKES

1. **Diagnosing "flaky" from "it passes locally".** Root cause: the local clone has full history and tags and the runner's checkout has one commit and no tags, so the same commit runs in different repositories.
2. **Re-running to test a theory.** Root cause: a re-run reuses the original commit and ref, so it repeats the same inputs.
3. **Stopping at the first failure.** Root cause: the job never reached its tests, so every defect behind the failing step stayed invisible.
4. **Overriding a red required check for a "harmless" change.** Root cause: the check is the control for the branch, and bypassing it makes red normal and hides real failures in it.
5. **Reporting "fixed" from the files.** Root cause: the files show that the cause was removed; only a green run on the fix branch shows that the job passes.

## PRODUCTION EXAMPLE

An evaluation-reporting service derives its version from the newest release tag and stamps it on every report. A week after that feature was added, a developer asks an administrator to bypass the red check for a documentation change, "because the runner has been flaky all week".

The administrator opens the list of runs first. Green turns red at one commit, and has been red on every run since. He reads the workflow file from the top: event, permissions, runner label, action versions. Nothing moves there. Then the one line the failed step printed, which is a message from Git. He makes a depth-one clone without tags on his own machine and gets the same line.

He does not bypass. He opens a pull request with the checkout option, and because the job has not reached its tests for a week, he also asks what else changed in that week. One commit moved a template path into a constant, with a capital letter that the tracked file does not have. Both fixes go in together. In the retrospective the team writes down the two rules from the textbook. A workflow change that adds a tool is reviewed with the inputs the tool reads. And a red default branch is an incident on its first day.

## PRACTICE EXERCISE

Do Lab 37.4, "CI works locally but fails on GitHub Actions (incident 7)", in [`lab-manual/m37-incident-drills-platform.md`](../../lab-manual/m37-incident-drills-platform.md), from a freshly generated sandbox.

Before you open the evidence, write the twelve areas of the investigation order down the side of a page. Answer each from the workflow file and the run description, and mark where the first informative answer appears. Before you build the runner's clone, predict its commit count, its tags and the script's output. After the fix, write the status sentence you would send, with what is proven and what is not yet.

The challenge is Lab 38.5, "Senior standard 3: GitHub Actions suddenly fails", in [`lab-manual/m38-communication-postmortems.md`](../../lab-manual/m38-communication-postmortems.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q282: "A pull request's CI fails and the author says "it passes on my machine, same commit". What do you check first, and why can both be right?"

Answer aloud. A strong answer starts with the second half, because it frames the first: say what else, besides the commit, is an input to a run, and give at least two examples that are about Git and at least one that is not. Then say what you check first and why that comes first: which commit the run tested, on which event, and what the runner's checkout contained. Name the read-only way to reproduce the runner's view locally. Finish with what you would not accept as a diagnosis without evidence, and what you would report as the status after pushing a fix.

## RECAP

- "Suddenly fails" is tested first: either a commit changed something, or something outside the repository did; the list of runs and `git log` on the workflow separate the two.
- The investigation follows a fixed order of twelve areas; an early answer makes later ones irrelevant.
- The default checkout is one commit without tags, so anything that needs history or tags behaves differently on the runner.
- The runner's view can be rebuilt with a depth-one clone without tags, and the remedy proven before the workflow is edited.
- Look behind the first failure, refuse the administrative merge, and report "cause removed in the files; confirmed when the run is green".

## HOMEWORK

Read sections 30.11 and 30.18. Then generate Incident 3, [`incidents/03-committed-secret`](../../incidents/03-committed-secret/SYMPTOMS.md), and attempt it before the next video. You met it as a challenge after V168; this time run it against the clock, with a command log, and write the message to the team before you watch the debrief.

# Exercises, Modules 32 to 34: Professional practice

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every transcript in this file is real output of a script in `labs/ex3/`. Nothing here was run against GitHub. Where an exercise describes what GitHub does, the description follows the textbook chapter named in the exercise.

## How to use these exercises

Do the labs of a module first. Write your answer before you open [the solutions](../solutions/exercises-m32-m34.md). This file contains no answers.

**Levels.** Level 1: instructions to follow. Level 2: a goal and limited hints. Level 3: a situation to diagnose on your own. Level 4: symptoms only, in a repository that a script builds for you. Level 5: a production incident with incomplete and partly misleading evidence.

**Kinds.** "Read and diagnose" and "design" tasks are done on paper; design tasks are marked against a rubric in the solution. "Local simulation" tasks run in the lab shell (`labs/shell`): Exercise 32.5 has a setup script, and the others ask for a prediction whose transcript is in the solution (`labs/run ex3/<name>` replays it). "Do it" tasks on GitHub run in your normal shell.

Most questions at this level have more than one defensible answer. What is marked is the reasoning: the context you name, the mechanism you cite, and the cost you admit.

---

## Module 32: Branching and release strategy

Chapter: [27, Open source and team workflows](../textbook/ch27-open-source-team-workflows.md), sections 27.5 to 27.14.

### Exercise 32.1 (Level 1, read and diagnose): Names and what gives them force

For each branch name, say what the name usually means, and what, if anything, makes Git or GitHub treat it differently from any other branch: `main`, `develop`, `feature/semantic-split`, `hotfix/empty-doc`, `release/2.3`, `asha/experiment`.

Then:

1. A repository has a branch named `release`. Can you create `release/2.3` in it? Why?
2. Name three kinds of tooling that select branches by name pattern, and so depend on a naming scheme.
3. What does unconfigured Git 2.55 call the first branch of a new repository, and what makes the labs use another name?

### Exercise 32.2 (Level 2, read and diagnose): Six teams, which model?

Use the two questions of section 27.14 (how many versions are live at once, how often do you release) and recommend a model for each. Name one thing each team must watch.

1. A hosted retrieval API, one live version, deployed several times a day by eight engineers with good tests.
2. An SDK for that API, with versions 2.x and 3.x both supported for customers.
3. A mobile app released every two weeks, with a three-day stabilization before each release.
4. An open-source evaluation library with forty occasional outside contributors.
5. A payments service where every production change needs approval by someone other than the author and a record of what shipped.
6. A research group whose "releases" are trained models that must be reproducible a year later.

### Exercise 32.3 (Level 2, read and diagnose): What does the patch release contain?

`chunker` 2.3.0 is tagged on `main`. Afterwards a large feature is merged to `main`. Then a production bug needs a fix, to be shipped as 2.3.1.

1. Under GitHub Flow with tags on `main`, what does 2.3.1 contain? Is that a defect of the model?
2. For which kind of consumer is it a broken promise, and which specification makes the promise?
3. The team has no release branch. Give the one command that creates the missing line after the fact, and say what must exist for it to work.
4. Under the release-branch model, how many commits does the fix become, and what links them?
5. What must be true of the unfinished feature for model 1 to be able to ship an urgent fix at all?

### Exercise 32.4 (Level 3, read and diagnose): Two directions, one repository

A team has `main` and `release/2.3`. Half the engineers commit fixes on the release branch and merge it upward into `main`. The other half commit on `main` and cherry-pick down with `-x`.

1. State each convention's check for "nothing was forgotten" as one command with a testable result.
2. Explain why, in this repository, neither check gives a trustworthy answer.
3. The upward merge also brought the commit "bump version to 2.3.1" into `main`. Why, and what does the merge-upward convention do about release-only commits?
4. Name the false alarm that the pick-down check raises even when everybody follows the rule, and the evidence that clears it.
5. Which sources prescribe which direction? What do you tell the team?

### Exercise 32.5 (Level 4, local simulation): Which fix is missing?

```bash
bash labs/ex3/setup-x32-5-missing-fix.sh
labs/shell x32-5/you/chunker
```

You are in your clone, on `main`. Version 2.3.1 was tagged on `release/2.3` last week. The team's written rule is "fix on `main` first, cherry-pick down with `-x`".

Symptoms:

- A customer who upgraded from 2.3.1 to a nightly build of `main` reports that a problem fixed in 2.3.1 is back. The report does not say which.
- The release manager says: "Impossible. Everything on the release branch came from `main`."

Find every commit on `release/2.3` that has no equivalent on `main`. Decide for each whether it is a real gap, a false alarm, or something that should not be on `main` at all, with the evidence for each verdict. Close the real gap in the way the team's rule implies, and show the check you would add as a release gate.

Self-check:

- [ ] You ran a patch-based comparison, not only an ancestry test, and you can say why ancestry is the wrong test under this team's rule.
- [ ] You can explain why the comparison lists a commit that a human did port.
- [ ] You proved the real gap from file content on `main`, not from commit subjects.
- [ ] The commit you added on `main` records where it came from.
- [ ] You did not move or re-create the tag `v2.3.1`, and you can say what gets released next.

### Exercise 32.6 (Level 3, design): Say it to a CTO

Your CTO read that "trunk-based development is proven to be best" and asks you to move four teams to it within a quarter. Write the half-page reply. It must say what the research measured and how, what it does not show, which variable the teams can act on whatever the model is called, what you would change first, and what you would measure. Do not quote any effect size.

The solution has a rubric.

### Exercise 32.7 (Level 5, production incident): The regression in 3.0

`ragbench` 3.0.0 shipped on Monday from `main`. On Wednesday a customer reports that 3.0.0 crashes on empty documents, a bug that was fixed in 2.9.2 two months ago. Evidence:

- `git branch --contains` for the fix commit lists only `release/2.9`. `git tag --contains` lists `v2.9.2` and `v2.9.3`.
- The engineer who fixed it says: "I merged that to `main` as well. I remember the pull request." There is a merged pull request titled "Fix crash on empty documents (#412)" whose base branch is `release/2.9`.
- Issue 380, "Crash on empty documents", was closed two months ago.
- CI on `main` was green for 3.0.0. The fix commit added a regression test.
- Someone proposes moving the tag `v3.0.0` to a commit that includes the fix, "so that customers get it without a new version".
- Someone else proposes merging `release/2.9` into `main`.

1. Where is the fix, and where is it not? Which piece of evidence settles it?
2. Reconcile the engineer's memory with the evidence.
3. Why was CI on `main` green, although a regression test exists?
4. Why did issue 380 close, or not close, when it did? What does that tell you about using issue state as evidence?
5. Evaluate both proposals. Then give the repair, the release, and the gate that prevents the next one.

---

## Module 33: AI/ML engineering workflows

Chapter: [28, AI/ML workflows](../textbook/ch28-ai-ml-workflows.md).

### Exercise 33.1 (Level 1, read and diagnose): In Git, or referenced from Git?

For each item say whether it belongs in the repository, and if not, what goes into the repository in its place.

1. `prompts/answer_v3.txt`
2. A 2 GB fine-tuned checkpoint
3. `uv.lock`
4. `mlruns/`
5. `notebooks/analysis.ipynb`, with charts in its outputs
6. `configs/eval.yaml`
7. `.env` with the provider key
8. A 40 MB evaluation set that changes monthly
9. `Dockerfile`
10. The resolved configuration of last night's run

Then state the test that decides the two borderline cases: why a lock file, which is generated, is committed, and build output, which is also generated, is not.

### Exercise 33.2 (Level 2, local simulation): Eight paths and one ignore file

A project has this ignore file, and three files are tracked:

<!-- snippet: ex3/x33-ignore-predict/01-rules -->
```text
$ cat .gitignore
# data is versioned by reference
/data/**
!/data/**/
!/data/**/*.ref

# weights and run output
*.safetensors
*.ckpt
runs/
outputs/

# local settings
.env
*.local.yaml
$ git ls-files
.gitignore
configs/eval.yaml
data/samples/smoke.csv
```
<!-- /snippet -->

Predict what `git check-ignore -v PATH` prints, and its exit status, for each of these paths, all of which exist in the working tree:

`data/raw/tickets.csv`, `data/raw/tickets.csv.ref`, `data/samples/smoke.csv`, `models/ranker.safetensors`, `src/runs/helper.py`, `.env`, `.env.example`, `configs/eval.local.yaml`

Then:

1. One of the eight is ignored by accident. Which rule does it, and how do you write the rule the author meant?
2. One of the eight is matched by a pattern and is still tracked. Which rule of ignore files explains it? What are the two things `git rm --cached` would and would not do about it?
3. Why does the ignore file need the line `!/data/**/` between the other two data lines?
4. For the pointer file, `check-ignore -v` exits with status 0 and prints a pattern. Is the file ignored?
5. Is this file a security control? Name two ways the key in `.env` still reaches history.

### Exercise 33.3 (Level 2, read and diagnose): The notebook that nobody edited

A team reports three things about `notebooks/analysis.ipynb`: it shows as modified after every run although no code changed; a merge of two branches left a file that Jupyter cannot open; and a scanner found a provider key in it that nobody typed.

1. Explain all three from one property of the file format.
2. The team installs a clean filter and commits `*.ipynb filter=nbstrip` in `.gitattributes`. A new colleague clones the repository, edits the notebook and commits it with all outputs. No error, no warning. Why?
3. What does `required = true` on the filter change, and why would it not have helped the new colleague?
4. Which check does travel with the repository, and where must it run to be a control?
5. After the filter is installed, a developer runs `git restore notebooks/analysis.ipynb`. What do they lose?
6. When is stripping outputs the wrong choice, and what are the two alternatives the chapter gives?

### Exercise 33.4 (Level 3, local simulation): Three runs, one commit ID

An experiment tracker shows three evaluation runs with three different scores, all labelled with the same commit. For each run, somebody captured the output of four commands just before it started: `git rev-parse --short HEAD`, `git describe --always --dirty --tags`, `git status --porcelain=v1` and `git diff HEAD --stat`.

<!-- snippet: ex3/x33-run-state/01-run-a -->
```text
# Run A
$ git rev-parse --short HEAD && git describe --always --dirty --tags && git status --porcelain=v1 && git diff HEAD --stat
3ec752b
v0.1.0-1-g3ec752b
```
<!-- /snippet -->

<!-- snippet: ex3/x33-run-state/02-run-b -->
```text
# Run B: someone tries top_k 8 without committing.
$ git rev-parse --short HEAD && git describe --always --dirty --tags && git status --porcelain=v1 && git diff HEAD --stat
3ec752b
v0.1.0-1-g3ec752b-dirty
 M configs/eval.yaml
 configs/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ mkdir -p runs/b && git diff HEAD --binary > runs/b/uncommitted.patch
```
<!-- /snippet -->

<!-- snippet: ex3/x33-run-state/03-run-c -->
```text
# Run C: a new module is on the import path, not yet added.
$ git rev-parse --short HEAD && git describe --always --dirty --tags && git status --porcelain=v1 && git diff HEAD --stat
3ec752b
v0.1.0-1-g3ec752b
?? src/ragbench/metrics_v2.py
```
<!-- /snippet -->

1. Which run can be reproduced from the commit ID alone?
2. For run B, what else is needed, and was it kept? Write the commands that rebuild its state.
3. Run C is the dangerous one. What does `git describe --dirty` say about it, and why is that answer misleading? Which of the four commands shows the problem?
4. A tracker that records only `git rev-parse HEAD` shows what for these three runs?
5. Write the two defensible policies for a team's evaluation script. Which one handles run C, and how?
6. Besides the code state, name four more things a run record needs, each with the mutable reference you must not record and the immutable identifier you record instead.

### Exercise 33.5 (Level 3, read and diagnose): The pointer and the file disagree

A team versions `data/raw/tickets.csv` by reference: the file is ignored, and a committed pointer `tickets.csv.ref` records its SHA-256 and size. The bytes live in a bucket.

1. An engineer appends 200 rows to the CSV and reruns the evaluation. `git status` is clean. Which commit, which data, and what does the run record say if it copies the hash from the pointer?
2. What should the run record instead, and how does that expose the mismatch?
3. `git switch` to last month's tag. Which of the two, pointer and data file, changed? What is the second step, and which tool hides it?
4. A fresh clone runs the evaluation and fails to find the data. Then the team discovers that a lifecycle rule deleted old objects from the bucket. What can the old pointers still do, and what can they not do?
5. Two branches each updated the data and the pointer. A line-by-line merge of the pointer file succeeds. Why is that a problem, and which attribute prevents it?

### Exercise 33.6 (Level 3, design): Evaluate prompts in CI

Design the CI for a public repository of an LLM application whose pull requests often change only files under `prompts/`. The evaluation calls a paid provider. Cover: what runs on every pull request, including those from forks; when the paid evaluation runs and on whose code; how its result is compared; where the key lives and how its damage is capped; what the run records; and how local hooks relate to CI checks. State which tempting design you rejected and why.

The solution has a rubric.

### Exercise 33.7 (Level 5, production incident): The number in the paper cannot be reproduced

A paper draft reports an accuracy of 0.91 for model version "ranker-prod". A reviewer asks for the code. The team checks out the commit that the tracker shows for that run, reruns the evaluation, and gets 0.86. Evidence:

- The tracker stored the commit ID, the branch name and the repository URL, and nothing else about the code.
- The run was started from a laptop. Its owner says she "had a small local change to the reranker threshold, probably".
- `uv.lock` is committed. The container was started from the tag `eval:latest`.
- The data pointer in that commit names a hash; the bucket has an object for it.
- The model was loaded by the registry alias `ranker-prod`, which was moved to a newer version three weeks after the run.
- A colleague says: "Git is the source of truth. If the commit does not reproduce it, the number was fabricated."

1. List every identifier that was recorded as a mutable reference, and for each say what it may have pointed to on the day.
2. Which single missing record makes the code state unrecoverable, and what would have saved it?
3. Answer the colleague. What does a commit ID prove about what ran?
4. What can the team honestly do now: what can be recovered, what can be bounded, what must be said in the paper?
5. Write the five-line policy that prevents the next one.

---

## Module 34: Practices, anti-patterns, and open-source etiquette

Chapter: [27](../textbook/ch27-open-source-team-workflows.md), sections 27.2 to 27.4 and 27.15 to 27.18.

### Exercise 34.1 (Level 1, read and diagnose): The reason behind the rule

Give the mechanism behind each practice in one sentence. "Because it is best practice" is not an answer.

1. One logical change per commit.
2. `--force-with-lease`, never bare `--force`.
3. Rebase only branches that nobody else has.
4. Run `git log A..B` before merging B into A.
5. A check that matters must be a *required* check.
6. No secrets in Git, not even in a private repository.
7. Release tags are signed or at least annotated, and never moved.
8. Lock files are committed; build output is not.

### Exercise 34.2 (Level 2, read and diagnose): Anti-patterns and the model behind them

For each anti-pattern, name the wrong mental model that produces it, what it costs, and the correction.

1. A commit of 2,400 lines named "updates".
2. "The push was rejected, so I forced it."
3. "It is on GitHub, so it is backed up."
4. `git reset --hard` as a general undo.
5. "CI is flaky; just merge."
6. A 300 MB file committed "so that the repository is complete".
7. A shared branch rebased "to tidy the history".
8. One classic token with full scope, shared by the team in a chat channel.

### Exercise 34.3 (Level 2, local simulation): Messages as data

A repository uses Conventional Commits and marks agent-written commits with a `Co-authored-by` trailer. Its history:

<!-- snippet: ex3/x34-messages/01-log -->
```text
$ git log --oneline
3e2de31 wip
7be0674 fix: reject k that is not positive
088cd3a fix: typo
fee8f77 docs: add README
568caba feat: add recall metric
63f2180 feat: add evaluation config
```
<!-- /snippet -->

Write one Git command, or one short pipeline, for each task, and predict its output:

- a. Count the commits per type prefix.
- b. List the commits whose subject does not follow the convention.
- c. List the commits that an agent co-authored.
- d. Print the value of the `Reviewed-by` trailer of the second-newest commit.
- e. For every `fix` commit, show which files it changed.

Then: one subject in this history is false. Which task above exposes it, what did the commit really do, and what does that tell you about a commit-message linter? Under Conventional Commits and Semantic Versioning, which release would a tool compute from this history, and would it be right?

### Exercise 34.4 (Level 3, read and diagnose): Review these four pull requests

You are the maintainer of an open-source evaluation library. Say what you do with each pull request, and what you write to its author.

1. A first-time contributor's pull request of 1,900 lines that restructures the package layout. No issue was opened first. The CI check that needs a provider key is red.
2. A pull request that was approved yesterday. Overnight the author force-pushed. The diff looks similar.
3. A two-line fix from a regular contributor, with a test. It also bumps a pinned action in `.github/workflows/ci.yml` "while I was there".
4. A pull request opened by a coding agent on behalf of a colleague: 14 files, a clear description, all checks green, already approved by an automated reviewer.

### Exercise 34.5 (Level 3, design): The design review

A company of forty engineers builds a hosted LLM product and an SDK. One monorepo, private, on the Team plan. Deploys of the service happen several times a day; the SDK ships monthly and the previous major version is supported. There are two contractors. CI takes fifteen minutes. Agents open about a third of the pull requests.

Design, on two pages: the branching model for the service and for the SDK, the direction of fixes, merge methods, the rulesets and CODEOWNERS, CI and required checks, the release mechanism and tags, credentials for automation, secret handling, and how agent-written changes are attributed and reviewed. For each decision give the mechanism it relies on and its cost. Then list the three objections you expect and your answers.

The solution has a rubric with the objections a reviewer will raise. Lab 34.1 is the oral version of this exercise.

### Exercise 34.6 (Level 5, production incident): The contributor who was never answered

Your open-source library's issue tracker has a public complaint with 200 reactions: "I reported a leaked credential in this repository six weeks ago and nobody answered." Evidence:

- Six weeks ago a pull request from a fork changed one line of documentation. Its description said, in the last paragraph, that `examples/demo_config.json` on `main` contains what looks like a live storage key.
- The pull request's checks were red: the evaluation job needs a secret and fork pull requests do not get one. A maintainer wrote "CI is failing, please fix" and nothing else. The author did not reply. A bot closed the pull request as stale after 30 days.
- The repository has no `SECURITY.md` and private vulnerability reporting is not enabled.
- The file was added eight months ago in a commit titled "docs: add demo".
- A maintainer now says: "That key is from a sandbox account. Probably."
- Another has already opened a pull request that deletes the file.

1. What is the first action, and what is wrong with "probably"?
2. Trace how the report was lost. Name three separate failures, at least one of them about etiquette on the maintainers' side.
3. Why was the red check not the contributor's bug, and what should the first reply have said?
4. What does the deletion pull request achieve, and what does it not?
5. Write the public reply to the complaint, in five sentences.
6. List the changes to the repository that make the next report arrive, and say which of them is a platform feature and which is a file.

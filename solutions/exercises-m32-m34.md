# Solutions, Modules 32 to 34: Professional practice

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every transcript is real output of a script in `labs/ex3/`. Nothing was run against GitHub; statements about the platform are taken from the textbook section cited beside them. Design solutions are one defensible answer with a rubric, not the only answer.

Questions are in [the exercise file](../exercises/m32-m34-practice.md). Each solution has four parts: the solution, the reasoning, the common mistakes, and the expert approach.

---

## Module 32

### Solution 32.1: Names and what gives them force

**Solution.**

| Name | Usual meaning | What gives it force |
|---|---|---|
| `main` | the integration branch; the default branch | the repository's default-branch setting; a ruleset |
| `develop` | Git Flow's integration branch | only the team's agreement |
| `feature/semantic-split` | work in progress on one change | nothing; often a naming rule |
| `hotfix/empty-doc` | an urgent fix to something released | nothing in Git; sometimes a faster review rule |
| `release/2.3` | the line from which a version and its patches are tagged | a ruleset; workflows that trigger on the pattern |
| `asha/experiment` | a private branch that may be rebased | only the convention that the name signals |

1. No. In the files backend the slash makes `release` a directory, so a branch `release` and a branch `release/2.3` cannot both exist.
2. Ruleset targets, workflow branch filters, and cleanup or listing commands such as `git branch --list 'release/*'`.
3. `master`. The lab configuration sets `init.defaultBranch=main`, and GitHub's default for new repositories is `main`. Neither name does anything the other does not.

**Reasoning.** To Git, a branch name is a ref name. Conventions earn their keep when rules are attached to them (Chapter 27, section 27.5; Chapter 7).

**Common mistakes.** Believing `hotfix/` branches merge faster or `release/` branches are protected by their name. Protecting `release/*` and then naming a branch `rel-2.3`.

**Expert approach.** Choose a scheme, write it in `CONTRIBUTING.md`, and enforce the parts that matter with a ruleset whose pattern you have tested. Reference: Chapter 18, section 18.3; Chapter 27, section 27.5.

### Solution 32.2: Six teams, which model?

**Solution.**

| Team | Model | Watch |
|---|---|---|
| 1 Hosted API, continuous | one long-lived branch: GitHub Flow or trunk-based development | branch lifetime; flags for unfinished work; fast rollback |
| 2 SDK, two supported majors | long-lived `release/2.x` and `release/3.x` lines (or `main` plus one release line) | the port check as a release gate; CI per supported line |
| 3 Mobile app, fortnightly, with stabilization | trunk plus a late-cut release branch per release | fix direction; retiring old release branches |
| 4 Open source, outside contributors | fork workflow, pull requests, maintainers merge | secrets and privileged triggers on fork pull requests |
| 5 Payments, approval and record | protected branches with required review by someone other than the author; signed tags; release branches where a release is an audited event | make bypasses visible; compliance comes from enforced, logged rules, not from the model's name |
| 6 Reproducible model releases | tags on the exact commit, with data and model versions recorded beside it | "which code produced this model" must have one answer |

**Reasoning.** No strategy is best. The choice follows from how many versions are live and how often you release; the rows combine when a company is in several contexts at once (Chapter 27, section 27.14).

**Common mistakes.** Git Flow as a default: its author restricts it to explicitly versioned software with several supported versions. Prescribing release branches to a team with one live version, for which there is nothing a release branch could hold.

**Expert approach.** Start with the simplest model that answers the two questions, and add a branch only when you can name the version or the audit requirement that needs it. Reference: Chapter 27, sections 27.6 to 27.8 and 27.14.

### Solution 32.3: What does the patch release contain?

**Solution.**

1. The fix and the large feature: everything merged to `main` since the previous tag. It is the model working as designed, because `main` is what you ship.
2. For a customer who pinned 2.3 and expects a patch release to contain only fixes. Semantic Versioning reserves the third number for backward-compatible bug fixes.
3. `git switch -c release/2.3 v2.3.0`. The tag must exist and name the released commit.
4. Two, one per line: the fix on `main` and its cherry-picked copy on the release branch. They are linked by patch ID and by the "(cherry picked from commit ...)" line that `-x` adds.
5. It must be switched off: merged behind a feature flag. A half-finished feature on `main` blocks an urgent release unless it is dark.

**Reasoning.** The difference between the two models is where the release tag lives (Chapter 27, sections 27.9 and 27.11).

**Common mistakes.** Calling 2.3.1 "a patch release" under model 1 without reading what it contains: `git log --oneline v2.3.0..v2.3.1` tells you. Creating the release branch from `main` instead of from the tag.

**Expert approach.** Before tagging, list the range since the last tag and ask whether the version number tells the truth about it. Reference: Chapter 27, sections 27.9 and 27.11.

### Solution 32.4: Two directions, one repository

**Solution.**

1. Merge upward: `git merge-base --is-ancestor release/2.3 main` must exit 0. Pick down: `git log --cherry-pick --right-only main...release/2.3` must print nothing.
2. Each check assumes its own convention. Pick-down commits make the release branch diverge from `main`, so the ancestry test fails until the next upward merge. And an upward merge makes the release branch's commits ancestors of `main`, where no patch comparison looks for them, while fixes that were picked down in between appear twice. A repository in which some engineers merge upward and others cherry-pick down satisfies neither check.
3. Merging the release branch upward brings everything on it, including version bumps and release-only changes, which then conflict or must be neutralized in the merge.
4. A cherry-pick that needed a conflict resolution has a different patch ID, so `--cherry-pick` reports it as missing although a human ported it. The `-x` line is the evidence.
5. The Git project's own workflow document prescribes merging upward from the oldest supported branch. The trunk-based development site, Microsoft's Release Flow and GitLab's rules prescribe fixing on `main` first. Tell the team to pick one direction, write it down, and make its check a release gate.

**Reasoning.** Nothing in Git propagates a fix between branches. Both conventions exist to prevent the fix that reaches one line and not the other (Chapter 27, section 27.10).

**Common mistakes.** Arguing about which direction is right instead of noticing that mixing them is what is wrong. Trusting an upward merge that was resolved by discarding the release branch's side: the ancestry test passes and the fix is absent.

**Expert approach.** One direction, one command, one gate. Reference: Chapter 27, section 27.10.

### Solution 32.5: Which fix is missing?

**Solution.** Replayed by `labs/run ex3/x32-missing-fix`.

<!-- snippet: ex3/x32-missing-fix/01-state -->
```text
$ git log --graph --oneline --decorate main release/2.3
* 598a14e (HEAD -> main, origin/main, origin/HEAD) docs: point to the 2.4 plan
* 3c9f555 fix: reject a chunk size that is not positive
* c296134 fix: strip whitespace before splitting
* 940f55b feat: add overlap parameter
| * 7061815 (tag: v2.3.1, origin/release/2.3, release/2.3) fix: cap the number of chunks per document
| * d2eed6e fix: reject a chunk size that is not positive
| * 2eeccc0 fix: strip whitespace before splitting
| * 39d3c69 chore: bump version to 2.3.1
|/  
* 6258ae5 (tag: v2.3.0) Add splitter test
* e636524 Add chunking config
* 81ee9da Add fixed-size splitter
* 94d97ae Add README
```
<!-- /snippet -->

<!-- snippet: ex3/x32-missing-fix/02-ancestry -->
```text
$ git merge-base --is-ancestor release/2.3 main
[exit status: 1]
$ git log --oneline main..release/2.3
7061815 fix: cap the number of chunks per document
d2eed6e fix: reject a chunk size that is not positive
2eeccc0 fix: strip whitespace before splitting
39d3c69 chore: bump version to 2.3.1
```
<!-- /snippet -->

Ancestry fails, as it must: under "pick down" the release branch is never merged back. Four commits are on the release branch only. The question is which of them have an equivalent *change* on `main`:

<!-- snippet: ex3/x32-missing-fix/03-patch-check -->
```text
$ git log --cherry-pick --right-only --oneline main...release/2.3
7061815 fix: cap the number of chunks per document
d2eed6e fix: reject a chunk size that is not positive
39d3c69 chore: bump version to 2.3.1
```
<!-- /snippet -->

Three candidates. `2eeccc0` is gone from the list because `main` has a commit with the same patch. Read the remaining ones:

<!-- snippet: ex3/x32-missing-fix/04-read-the-candidates -->
```text
$ git log --format='%h %s%n%b' main..release/2.3 | grep -E '^[0-9a-f]{7} |cherry picked'
7061815 fix: cap the number of chunks per document
d2eed6e fix: reject a chunk size that is not positive
(cherry picked from commit 3c9f555d46dac1f0a5cf03deeff0f00303f59525)
2eeccc0 fix: strip whitespace before splitting
(cherry picked from commit c29613455070987712a73fc36dae6bb3183feea5)
39d3c69 chore: bump version to 2.3.1
$ git grep -n 'size must be positive' main -- chunker/split.py
main:chunker/split.py:4:        raise ValueError("size must be positive")
[exit status: 0]
$ git grep -n 'max_chunks' main
[exit status: 1]
```
<!-- /snippet -->

| Commit | Verdict | Evidence |
|---|---|---|
| `39d3c69` bump version | release-only: it should not be on `main` | its subject and content |
| `d2eed6e` reject a chunk size | false alarm | it carries a "cherry picked from commit `3c9f555`" line, and `main` contains the check; the port needed a hand resolution, so its patch ID differs |
| `7061815` cap the number of chunks | the real gap | no `-x` line, and `git grep` finds no `max_chunks` on `main` |

The fix was made on the release branch and never taken to `main`. Port it, recording where it came from:

<!-- snippet: ex3/x32-missing-fix/05-port -->
```text
$ git cherry-pick -x 7061815
[main 34f61e1] fix: cap the number of chunks per document
 Date: Mon Sep 7 10:19:00 2026 +0530
 2 files changed, 5 insertions(+)
$ git log -1 --format='%h %s%n%n%b'
34f61e1 fix: cap the number of chunks per document

(cherry picked from commit 7061815b618d46ff4e5a3b8000aa97d2adc1e7b2)

$ git grep -n 'max_chunks' main
main:config/chunking.yaml:5:max_chunks: 10000
[exit status: 0]
$ git log --cherry-pick --right-only --oneline main...release/2.3
d2eed6e fix: reject a chunk size that is not positive
39d3c69 chore: bump version to 2.3.1
```
<!-- /snippet -->

The gate is the patch comparison, read by a person: after the port it lists the version bump and the hand-ported fix, and each needs a recorded reason. `v2.3.1` is not touched; the fix reaches users of `main` with the next release from `main`.

**Reasoning.** Two commits are "the same fix" to Git only if their patches are equal. A port with a conflict resolution, and a fix made on the wrong line, look alike to the patch check and are told apart by the `-x` line and by content (Chapter 27, section 27.10; Chapter 10).

**Common mistakes.** Stopping at `git branch --contains`. Merging `release/2.3` into `main`, which brings the version bump and contradicts the team's rule. Cherry-picking all three candidates. Believing the release manager's statement, which was true for two of four commits.

**Expert approach.** Run the patch check before every release from `main`, keep a short list of expected exceptions, and treat any new line as a blocker until someone has explained it. Reference: Chapter 10; Chapter 27, sections 27.9 and 27.10.

### Solution 32.6: Say it to a CTO

**Solution.** A model reply.

"The research does not show that trunk-based development is best. DORA's findings come from surveys: respondents describe their own practices and outcomes, and the analysis is correlational. What it reports, from research done in 2016 and 2017, is that higher delivery performance is associated with three or fewer active branches, merging to the trunk at least daily, and no code freezes. It is expressed in branch lifetime and batch size, not in named workflows, so a GitHub Flow team with one-day branches satisfies it and a nominally trunk-based team with week-long branches does not.

The variable we can act on is how long our branches live and how large our changes are. I propose we measure that first for the four teams: branch age at merge, pull request size, and time to first review. Then we shorten what is long: smaller pull requests, feature flags for unfinished work, an agreed time to first review. Teams that support several released versions keep their release branches; that is a different question from how long feature branches live. I will report the three measures monthly. I will not promise a percentage: the sources I have read give none that I can stand behind."

**Rubric** (2 points each, 12 in total): says survey-based and correlational; states what was measured in terms of branch lifetime and batch size; says what is not shown (no ranking of named workflows, no causation); names the actionable variable; proposes a first change and a measurement; quotes no effect size.

**Reasoning.** "Is associated with" and "predicts", in the statistical sense the authors use, not "causes" (Chapter 27, section 27.13). The chapter records that later DORA reports were not read for this course and that no numeric effect sizes were captured.

**Common mistakes.** Agreeing and mandating a model by name. Refusing and defending long branches. Quoting a number from memory.

**Expert approach.** Translate a claim about a named practice into the measurable property behind it, then measure your own teams. Reference: Chapter 27, sections 27.11, 27.13 and 27.14.

### Solution 32.7: The regression in 3.0

**Solution.**

1. The fix is on `release/2.9` and in the tags `v2.9.2` and `v2.9.3`. It is not on `main` and not in `v3.0.0`: `git branch --contains` settles it for the commit, and to exclude a ported copy with another ID, also run the patch comparison between `main` and `release/2.9`.
2. The engineer remembers a pull request, and there was one: into `release/2.9`. Its base branch is the evidence. A merged pull request says where the commits went, and this one did not go to `main`.
3. The regression test was added by the fix commit. `main` has neither the fix nor the test, so nothing on `main` could fail.
4. Closing keywords in a pull request description act only when the pull request targets the default branch, so this pull request did not close the issue; somebody closed it by hand when 2.9.2 shipped. An issue's state records a decision by a person, not which branches contain a commit.
5. Do not move `v3.0.0`: people already have it, and a moved tag means two different artifacts under one name. Do not merge `release/2.9` into `main` unless merge-upward is the team's convention: the merge brings everything on the release branch, version bumps included. The repair is to port the fix and its test to `main` with `git cherry-pick -x`, release 3.0.1, and tell 3.0.0 users. The gate: before a release from `main`, `git log --cherry-pick --right-only main...release/2.9` must be empty or explained.

**Reasoning.** This is the failure both fix-direction conventions exist to prevent, in the form of the chapter's root-cause box: the step that carries a fix to the other line was a human step that nobody took (Chapter 27, section 27.10; Chapter 15, section 15.8).

**Common mistakes.** Trusting memory, issue state or green CI as evidence of where a commit is. Moving a published tag to be helpful.

**Expert approach.** Ask the repository, not the people: which refs contain this commit, and which contain an equivalent patch? Then turn the answer into a gate. Reference: Chapter 14B, section 14B.11; Chapter 15, section 15.8; Chapter 27, section 27.10.

---

## Module 33

### Solution 33.1: In Git, or referenced from Git?

**Solution.**

| # | Item | In Git? | Instead |
|---|---|---|---|
| 1 | a prompt file | yes: a prompt is source code for an LLM application | |
| 2 | a 2 GB checkpoint | no | a pointer: a registry version, or a model ID with a pinned revision |
| 3 | `uv.lock` | yes | |
| 4 | `mlruns/` | no | nothing; the tracker's store is ignored |
| 5 | a notebook with outputs | the notebook yes, without outputs | a clean filter, verified in CI |
| 6 | evaluation configuration | yes | |
| 7 | `.env` | no, in any form | an `.env.example` without values |
| 8 | a 40 MB data set that changes monthly | no | a pointer file with a checksum and size; the bytes in a store |
| 9 | `Dockerfile` | yes | |
| 10 | the resolved configuration of a run | no: it is run output | recorded with the run, beside the metrics |

The test: can the file be regenerated identically from what is in Git? Build output can. A lock file cannot, because the package index changes, so it is an input to every later build and is committed.

**Reasoning.** Every clone carries the full history, objects cannot be recalled, and diff, merge and blame work on lines of text (Chapter 28, sections 28.2 and 28.8). The chapter labels this split an inference from GitHub's limits, not a published standard.

**Common mistakes.** Treating prompts as data to keep outside the repository. Committing a tracker directory because "it is the results". Leaving the lock file out because it is generated.

**Expert approach.** For anything large or generated, ask what small, immutable identifier Git can hold in its place. Reference: Chapter 28, sections 28.2, 28.6 and 28.8.

### Solution 33.2: Eight paths and one ignore file

**Solution.**

<!-- snippet: ex3/x33-ignore-predict/02-answers -->
```text
$ git check-ignore -v data/raw/tickets.csv
.gitignore:2:/data/**	data/raw/tickets.csv
[exit status: 0]
$ git check-ignore -v data/raw/tickets.csv.ref
.gitignore:4:!/data/**/*.ref	data/raw/tickets.csv.ref
[exit status: 0]
$ git check-ignore -v data/samples/smoke.csv
[exit status: 1]
$ git check-ignore -v models/ranker.safetensors
.gitignore:7:*.safetensors	models/ranker.safetensors
[exit status: 0]
$ git check-ignore -v src/runs/helper.py
.gitignore:9:runs/	src/runs/helper.py
[exit status: 0]
$ git check-ignore -v .env
.gitignore:13:.env	.env
[exit status: 0]
$ git check-ignore -v .env.example
[exit status: 1]
$ git check-ignore -v configs/eval.local.yaml
.gitignore:14:*.local.yaml	configs/eval.local.yaml
[exit status: 0]
```
<!-- /snippet -->

1. `src/runs/helper.py`. The pattern `runs/` has no leading slash, so it matches a directory of that name at any depth. The author meant `/runs/`.
2. `data/samples/smoke.csv` matches `/data/**` and is still tracked, which is why `check-ignore` prints nothing for it: ignore patterns never affect files that are already tracked. `git rm --cached` would stop tracking it from the next commit on, and delete it from the working tree of a colleague who pulls that commit; it would not remove the file from history.
3. Git does not look inside an ignored directory, so without re-including the directories no later rule could re-include a file in them.
4. No. With `-v`, `check-ignore` prints the matching pattern even when it is a negation, and exits 0; a pattern that starts with `!` means "not ignored".
5. No. `git add -f .env` adds it, and a key pasted into any tracked file is not covered at all.

<!-- snippet: ex3/x33-ignore-predict/03-status -->
```text
$ git status --short
?? .env.example
?? data/raw/
$ git status --short --ignored
?? .env.example
?? data/raw/
!! .env
!! configs/eval.local.yaml
!! data/raw/tickets.csv
!! models/
!! src/
```
<!-- /snippet -->

The last listing shows the accident from the other side: the whole `src/` directory appears as ignored, because the only file in it is under a directory called `runs`.

**Reasoning.** Ignore rules keep generated and large files from being added by accident; the index decides what is tracked (Chapter 28, section 28.9; Chapter 4).

**Common mistakes.** Reading exit status 0 as "ignored". Expecting a new rule to untrack a file. Unanchored directory patterns.

**Expert approach.** Ask Git which rule decides, with `git check-ignore -v`, and anchor patterns that mean one place. Reference: Chapter 28, section 28.9.

### Solution 33.3: The notebook that nobody edited

**Solution.**

1. An `.ipynb` file is one JSON document in which each code cell carries its source, the outputs of its last run and a counter. So a rerun changes the file; a line-based merge of two reruns writes conflict markers into JSON; and whatever a cell printed, a key included, is part of the file.
2. The attribute travelled, because `.gitattributes` is tracked. The driver did not: it is defined in each clone's configuration, and Git never copies configuration from a clone source. A missing driver definition "is not an error but makes the filter a no-op passthru".
3. With `required = true`, a filter that fails or is missing makes `git add` fail instead of staging the unfiltered file. It did not help because that setting is part of the same configuration that the new clone does not have.
4. A check that strips each committed notebook in memory and fails if anything would change (`nbstripout --verify` is the real tool's form), run in CI as a required check. The filter on each laptop is then a convenience.
5. The outputs in their working tree: the file is rewritten from the cleaned blob.
6. When the outputs are the deliverable and must be discussed: commit them on purpose and review them with a tool built for it. Or pair the notebook with a text file (jupytext) and review that. The durable fix is to move growing logic into the package and keep the notebook a thin caller.

**Reasoning.** One file mixes what a human wrote with what a program produced, and Git has no knowledge of file formats unless drivers are configured (Chapter 28, sections 28.3 to 28.5).

**Common mistakes.** Believing a committed `.gitattributes` protects every clone. Relying on GitHub's notebook rendering as a review process.

**Expert approach.** Decide per repository what a notebook is (exploration, reviewed logic, or a deliverable) and enforce the decision where nobody can skip it. Reference: Chapter 28, sections 28.3 to 28.5 and 28.10.

### Solution 33.4: Three runs, one commit ID

**Solution.**

1. Run A: clean tree, nothing untracked.
2. Run B needs the uncommitted change. It was kept: the transcript saves `git diff HEAD --binary` as a patch. To rebuild: check out the commit, apply the patch.

<!-- snippet: ex3/x33-run-state/04-reproduce-b -->
```text
# Reproducing run B from its record: the commit, then the saved patch.
$ git status --porcelain=v1
$ git apply --check runs/b/uncommitted.patch && git apply runs/b/uncommitted.patch
$ git diff HEAD --stat
 configs/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

3. `git describe --dirty` prints no `-dirty` for run C, and `git diff HEAD` is empty: no tracked file changed. But a new module was on the import path. Only `git status --porcelain` shows it, as `??`.
4. Three runs of "the same code" with three scores.
5. Refuse tracked runs unless the tree is clean, where clean includes no untracked files. Or allow dirty runs and record the status and the full diff as artifacts. Run C needs the first policy, or the second extended to save untracked files, because a diff does not contain them.
6. Dependencies: not the version ranges, but the committed lock file or its hash. Environment: not the image tag, but the image digest. Data: not a path or "latest", but the checksum of the data actually read. Model: not a name or alias, but a registry version or hub commit hash. Configuration: not defaults plus overrides, but the resolved configuration.

**Reasoning.** `git rev-parse HEAD` names the last commit; it says nothing about the index or the working tree, and the interpreter imported the files on disk (Chapter 28, sections 28.7 and 28.8).

**Common mistakes.** Treating "not dirty" as "equal to the commit". Recording the diff's hash without keeping the diff. Assuming the tracker captures uncommitted changes: the chapter records that the common ones do not by default.

**Expert approach.** Make the evaluation script record commit, status, diff and untracked files itself, and refuse to run when it cannot. Reference: Chapter 28, sections 28.7 and 28.8.

### Solution 33.5: The pointer and the file disagree

**Solution.**

1. The same commit, new data, and a record that names the *old* hash: Git does not watch an ignored file, so nothing warned anybody. The record is now wrong about what ran.
2. The checksum of the data actually read, computed at run time. Comparing it with the pointer exposes the mismatch, and a careful script refuses to run on it.
3. Only the pointer. The second step restores the data version that the pointer names (the chapter's tool has a restore command; DVC has `dvc checkout`). Git LFS hides that step inside a smudge filter, which is why a clone without the LFS client silently gets pointers.
4. They still identify the data exactly: a result can be checked against the right hash if a copy turns up. They cannot produce the data. The store is a dependency that needs backups, access control and a retention rule that never deletes an object some commit still points to.
5. A pointer combined line by line from two versions names a hash and a size that belong to different files, or to none. `merge=binary` on pointer files makes Git report a conflict instead.

**Reasoning.** Versioning by reference has one central weakness: the pointer and the file can disagree, and Git will not tell you (Chapter 28, sections 28.6 and 28.9).

**Common mistakes.** Trusting a clean `git status` as evidence about data. Lifecycle rules on the bucket that know nothing about Git history.

**Expert approach.** Verify data against its pointer at the start of every run, and record what was read. Reference: Chapter 22; Chapter 28, sections 28.6 to 28.9.

### Solution 33.6: Evaluate prompts in CI

**Solution.** One defensible design.

- **Every pull request, forks included,** on `pull_request` with a read-only token and no secrets: lint, unit tests, the repository's own checks (notebooks without outputs, no large or secret files), and the evaluation against recorded responses or a local stub.
- **The paid evaluation** runs after the merge, on `main`, with an alert or revert on regression; and on demand for a pull request, started by a maintainer who has read the diff, on a branch inside the repository. It is triggered only when `prompts/`, `configs/` or `evals/` changed, with a capped data set for pull requests and the full suite on a schedule.
- **Comparison** against a baseline with a tolerance or a threshold, never for equality, because the evaluation is non-deterministic.
- **The key** is dedicated to CI, with a spend cap, separate from production's, stored as an environment secret.
- **The record** of each run: commit, prompt version, model version, seed, data checksum, resolved configuration.
- **Hooks** give the author feedback in seconds; every hook that matters is also a required check, because hooks are not installed by cloning, are skipped with one flag, and do not run for commits made through the web interface, the API or an agent's client.
- **Rejected:** `pull_request_target` with a checkout of the contributor's code. It executes untrusted code with your key and your token. The "prompts are only data" variant is safe only if nothing from the pull request is executed, which includes test files, `conftest.py` and anything a template can make the harness import.

**Rubric** (2 points each, 14 in total): secret-free checks for forks; the paid evaluation only on trusted code; a human or post-merge trigger; tolerance-based comparison; a capped, dedicated key; a run record; hooks backed by required checks. Deduct for the privileged trigger, for path-filtered required checks without an aggregate job, and for equality assertions on model output.

**Reasoning.** LLM evaluations differ from unit tests in three ways: non-deterministic, paid per run, and in need of secrets, and the third collides with the fork model (Chapter 28, sections 28.10 and 28.11; Chapter 21A, sections 21A.4 and 21A.5).

**Common mistakes.** Making the paid evaluation a required check on every pull request. One shared provider key. Trusting local hooks.

**Expert approach.** Split by trust first, then by cost. Reference: Chapter 20B, section 20B.13; Chapter 21A, sections 21A.4 and 21A.5; Chapter 28, sections 28.7, 28.10 and 28.11.

### Solution 33.7: The number in the paper cannot be reproduced

**Solution.**

1. The branch name (it has moved since). The image tag `eval:latest` (the publisher can move it; the run may have used another image). The registry alias `ranker-prod` (moved three weeks after the run, so a rerun loads a different model). And the commit ID itself, which is immutable but describes only the last commit, not the working tree that ran.
2. The uncommitted change. The tracker recorded `HEAD` and not the difference between `HEAD` and what ran. A saved diff, or a refusal to track a run from a dirty tree, would have saved it.
3. A commit ID proves which snapshot was the last one taken before the run. It does not prove that the files on disk equalled that snapshot. "Does not reproduce" is therefore not evidence of fabrication; it is evidence of an incomplete record.
4. Recover what has an immutable trace: the data, by the pointer's hash, which the bucket still has; the dependencies, from the committed lock file; the model version that the alias named on that day, if the registry keeps an alias history. Bound the rest: rerun from the commit with the recovered model version and report that result. If the threshold change cannot be recovered, say so, and report the number that can be reproduced.
5. For example: tracked runs only from a clean tree, untracked files included, or with status and diff saved; record the image digest, not a tag; record the registry version, not an alias; record the checksum of the data read and the resolved configuration; tag the commit of every result that leaves the team.

**Reasoning.** A result is identified by the commit, the state of the working tree relative to it, the data and model versions, the resolved configuration and the environment; with classic tracking, two different code states can share one commit ID (Chapter 28, sections 28.7 and 28.8).

**Common mistakes.** Hunting for the lost change by trial and error and reporting the first rerun that happens to give 0.91. Blaming Git. Treating a tag or an alias as an identifier.

**Expert approach.** For every number that will be published, ask before it is published: from which five identifiers could a stranger rebuild it? Reference: Chapter 28, sections 28.6 to 28.8 and 28.16.

---

## Module 34

### Solution 34.1: The reason behind the rule

**Solution.**

1. A commit is the unit of `revert`, `cherry-pick`, `bisect` and review; a commit that does three things can only be undone, ported or blamed as three things.
2. A bare force sets the server's ref with no check; a lease makes the push conditional on the ref being where you last saw it.
3. Rebasing writes new commits with new IDs; on a branch nobody else has, nobody else can be holding the old ones.
4. A merge brings every commit reachable from the other side, not only the ones you had in mind.
5. A check that is not required is advice, and it must run on the merged result to say anything about the base branch.
6. History is copied to every clone and fork and cannot be recalled; deleting the file adds a commit and removes nothing. Privacy changes who can read today, not what was copied.
7. `git describe` and release tooling use annotated tags; a signature is evidence of who made the tag; and a published tag that moves gives two different artifacts one name.
8. A lock file cannot be regenerated identically from what is in Git, so it is an input; build output can, so it is not.

**Reasoning.** A practice you cannot justify is a superstition, and it will be dropped under pressure (Chapter 27, section 27.15).

**Common mistakes.** Reciting the rule and not the mechanism. For 2, believing the lease is always safe: a background fetch defeats it unless `--force-if-includes` is added.

**Expert approach.** For each rule your team follows, be able to name the incident it prevents. Reference: Chapter 12, section 12.8; Chapter 14B, section 14B.11; Chapter 27, section 27.15; Chapter 28, section 28.8.

### Solution 34.2: Anti-patterns and the model behind them

**Solution.**

| # | Wrong model | Cost | Correction |
|---|---|---|---|
| 1 | "a commit is a save point for my day" | review that cannot be done; a bisect that ends on 2,400 lines; reverts that take the good with the bad | stage by hunk; one logical change per commit |
| 2 | the rejection is an obstacle, not information | colleagues' commits removed from the server | read the rejection, fetch, `--force-with-lease --force-if-includes`; forbid force pushes on shared branches by rule |
| 3 | GitHub is Git, and a remote is a backup | surprise when a force push removes work, or when issues, reviews and settings are not in any clone | label the layer; know what a clone contains |
| 4 | "reset means undo" | uncommitted work destroyed, the one loss the reflog cannot repair | know the three trees; commit or stash first |
| 5 | red is normal | a real failure hides among the tolerated ones | make checks required; fix or delete flaky tests; learn why CI differs from your machine |
| 6 | "Git stores my project", without "every clone carries every version" | slow clones for everyone, for ever; server limits | pointers and external storage |
| 7 | "rebase tidies history", without "it creates new commits" | colleagues' branches hold both versions; duplicates after their next merge | rebase only what nobody else has |
| 8 | a token is a password for the team | a leak reaches everything its owner can reach, with nobody accountable | per-purpose, short-lived, narrow credentials; an app for automation |

**Reasoning.** An anti-pattern is rarely stupidity. It is the reasonable result of a wrong mental model, and the model is what you correct (Chapter 27, section 27.16).

**Common mistakes.** Correcting the behavior with a rule and leaving the model in place, so that it reappears in the next form.

**Expert approach.** When you see an anti-pattern in review, ask the author what they expected the command to do. Reference: Chapter 16, section 16.6; Chapter 27, section 27.16.

### Solution 34.3: Messages as data

**Solution.**

<!-- snippet: ex3/x34-messages/02-by-type -->
```text
$ git log --format=%s | sed -n 's/^\([a-z]*\): .*/\1/p' | sort | uniq -c
   1 docs
   2 feat
   2 fix
$ git log --oneline --invert-grep --grep='^[a-z]*: '
3e2de31 wip
```
<!-- /snippet -->

<!-- snippet: ex3/x34-messages/03-agent-commits -->
```text
$ git log --format='%h %s' --grep='Co-authored-by: eval-agent'
088cd3a fix: typo
568caba feat: add recall metric
$ git log -1 --format='%(trailers:key=Reviewed-by,valueonly)' HEAD~1
Asha Rao <asha@example.com>
```
<!-- /snippet -->

<!-- snippet: ex3/x34-messages/04-does-the-message-match -->
```text
$ git log --stat --format='%h %s' --grep='^fix'
7be0674 fix: reject k that is not positive

 src/ragbench/metrics.py | 2 ++
 1 file changed, 2 insertions(+)
088cd3a fix: typo

 configs/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -p --format='%h %s' -1 --grep='^fix: typo' | grep -E '^[-+][a-z]'
-rate_limit: 60
+rate_limit: 6000
```
<!-- /snippet -->

Task e exposes it. `088cd3a`, "fix: typo", changes `rate_limit` from 60 to 6000 in the evaluation configuration. That is a behavior change by a factor of a hundred, co-authored by an agent, under a subject that passes every commit-message linter. A convention makes messages queryable; it does not make them true.

From this history a release tool would compute a MINOR release: there are `feat` commits and no breaking-change marker. Whether that is right depends on what the rate limit change means to users, which the history's types do not say.

**Reasoning.** Git imposes one piece of structure, the subject line; prefixes and trailers are conventions that tools can read because they are regular (Chapter 27, section 27.18; Chapter 28, section 28.15 for attribution of agent-written commits).

**Common mistakes.** Treating a green message lint as a review. Searching trailers with a loose `--grep` that also matches body text; `%(trailers:key=...)` reads real trailers only.

**Expert approach.** Use conventions for what machines are good at (counting, grouping, computing a version) and review for what they are not: whether the subject describes the diff. Reference: Chapter 27, sections 27.17 and 27.18; Chapter 28, section 28.15.

### Solution 34.4: Review these four pull requests

**Solution.**

1. Do not review 1,900 lines. Thank the author, say that a restructuring needs an issue first so that it can be discussed against the roadmap, and offer to continue there. Say plainly that the red check needs a secret that fork pull requests do not receive, and is not their bug.
2. Do not rely on yesterday's approval. Compare the old and the new series with `git range-diff`, and re-approve the commit you read. Ask the author to add commits instead of rewriting once review has started; if a ruleset dismisses stale approvals, the platform has already withdrawn the approval.
3. Ask for two pull requests. The fix can merge today. A change to a pinned action under `.github/workflows/` changes what runs with the repository's token: it needs a code owner's review and a look at the diff between the two pins.
4. Review it as you would any pull request of that size, or ask for it to be split. An automated approval is a signal about the diff, not about the intent, and it should not be the approval that a rule counts. Check that the agent's commits are attributed as the project requires.

**Reasoning.** A maintainer's scarce resource is attention; a review is a claim about a specific diff at a specific commit (Chapter 17, section 17.17; Chapter 27, sections 27.4 and 27.17).

**Common mistakes.** "CI is failing, please fix" to a fork contributor. Approving a force-pushed branch from memory. Waving through a workflow change because the pull request is small.

**Expert approach.** Say what kind of comment each one is (blocking, question, preference), and spend human attention on what a machine cannot check. Reference: Chapter 17, sections 17.5 and 17.17; Chapter 21A, section 21A.19; Chapter 27, sections 27.4 and 27.17; Chapter 28, section 28.15.

### Solution 34.5: The design review

**Solution.** One defensible outline.

- **Service:** one long-lived branch, short branches, pull requests, squash merge, deploy from `main`; unfinished work behind flags. **SDK:** `main` plus `release/N.x` for the supported previous major; releases are annotated tags created by a release bot.
- **Fix direction:** on `main` first, `git cherry-pick -x` down; the patch comparison is a release gate.
- **Rulesets:** `main` by `~DEFAULT_BRANCH`: no deletion, no force push, pull request with one approval, stale approvals dismissed, code owner review, one required aggregate check. `release/**/*`: the same. A tag ruleset on `v*` with creation restricted to the release bot's app. A push ruleset for file sizes and weight formats. Bypass lists short, made of roles and apps, never `exempt`.
- **CODEOWNERS:** teams per component, `/.github/` last, owning teams with explicit Write.
- **CI:** one workflow that always starts; jobs decide by path what to run; `all-checks` is the only required check. With fifteen-minute CI and many merges a day, decide strict against loose explicitly; a merge queue is not available to a private repository on this plan.
- **Credentials:** job token and OIDC inside workflows; an app for the release bot; no classic tokens; contractors as outside collaborators with access to named repositories.
- **Secrets:** push protection, a scanner in pre-commit and in CI over history, environment secrets behind reviewers.
- **Agents:** a `Co-authored-by` trailer or a dedicated bot account; every hook that matters is also a required check; a human approval that an automated approval cannot replace; no agent runs automatically on untrusted contributions.

Expected objections: "Squash loses history" (the unit of history becomes the pull request; keep pull requests small and the number in the subject). "Dismissing stale approvals slows us down" (it is the control against approve-then-push; small pull requests make re-review cheap). "Why not one process for service and SDK?" (one live version against two; different questions).

**Rubric** (2 points each, 20 in total): separates the two products by how many versions are live; names a fix direction and its gate; chooses merge methods with their costs; protects tags as well as branches; a required check that cannot be skipped or pend for ever; plan gates respected; credentials that are not people; secrets handled at commit, push and history; agents attributed and not self-approving; three objections answered with mechanisms.

**Reasoning.** Each decision should be traceable to a mechanism taught earlier and to an incident it prevents (Chapter 27, sections 27.14 to 27.16).

**Common mistakes.** One model for both products. Features the plan does not have. A design with no costs in it.

**Expert approach.** Present the design as decisions with alternatives rejected, and invite the objections before the reviewer raises them. Reference: Chapters 17 to 19, 20B, 21A, 21B, 27 and 28; Lab 34.1.

### Solution 34.6: The contributor who was never answered

**Solution.**

1. Revoke the key at its issuer now. "Probably" is not an assessment: until somebody has looked the key up at the provider, treat it as live, and it has been public for eight months.
2. Three failures. A security report had no channel: no `SECURITY.md`, no private reporting, so it arrived as the last paragraph of a documentation pull request. A maintainer answered the red check and not the pull request: nobody read the description. And a stale bot closed the conversation without a human decision.
3. Workflows on a pull request from a fork run without the project's secrets, so a job that needs one fails for every outside contributor. The first reply should have said that the failing check is not theirs to fix, thanked them for the report, and moved the report to a private channel.
4. It removes the file from the tip. The key stays in eight months of history, in every clone and fork. It is cleanup after revocation, not a response.
5. For example: "You are right, and we are sorry: your report of six weeks ago was missed. The key was revoked today at 14:10 and we are reviewing the provider's logs for its use. The failing check on your pull request was ours, not yours; fork pull requests do not receive the secret that job needs. We have added a security policy and enabled private vulnerability reporting, so that the next report reaches a person. Thank you for reporting it and for following up."
6. A `SECURITY.md` (a file). Private vulnerability reporting (a platform feature that repository administrators enable). Secret scanning and push protection (platform features). A contribution guide that says which checks fail for forks and why (a file). A stale-bot rule that never closes a pull request that no maintainer has answered (configuration). An evaluation job that does not need a secret on pull requests (a workflow change).

**Reasoning.** The chapter's cases include a researcher who could not find a way to report a leak and went to the press. A reachable disclosure contact is part of incident response, and etiquette runs in both directions (Chapter 21B, sections 21B.13 to 21B.15; Chapter 27, section 27.4).

**Common mistakes.** Answering the complaint before revoking the key. Defending the stale bot. Deleting the file and calling it fixed.

**Expert approach.** Contain, then apologize precisely, then fix the channel. Reference: Chapter 15, section 15.13; Chapter 21A, section 21A.4; Chapter 21B, sections 21B.10 and 21B.13 to 21B.15; Chapter 27, section 27.4.

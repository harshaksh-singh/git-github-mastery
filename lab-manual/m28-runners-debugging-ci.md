# Module 28 labs: Runners, cost and debugging CI

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.8 to 20B.15, first. Answers to the questions are in [the solutions](../solutions/m28-lab-answers.md), and the diagnoses of the six broken workflows are in [a separate file](../solutions/m28-broken-workflows.md); write your own first. Every transcript in this file is real output of a replay script in `labs/ch20b/` and shows plain Git and one small Python check. Nothing in this file was run against GitHub: the workflow files were parse-checked and assembled from documented syntax, but the author did not execute them on GitHub. **This file contains no log of a GitHub Actions run.** Where a run is described, the description is constructed for the exercise and says so.

## How these labs work

Each lab has a local Part A in the lab shell and a Part B on GitHub.

> **Run Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub.

Part B uses the practice repository `YOUR-ORG/inventory-api` (the sample project of the Module 26 labs) with `uv.lock` committed. Set these once in your normal shell:

```bash
ORG=your-practice-org
COURSE=/path/to/this/course          # the directory that contains labs/ and workflows/
cd /path/to/your/clone/of/inventory-api
```

The six files in `workflows/broken/` are exercises. Each parses as YAML, each has a header that says what the workflow is meant to do, and none says what is wrong. Add them to the practice repository only for the reproduction, one at a time, and remove each when you are done. Never copy from them into a real repository.

In transcripts, a line `[exit status: N]` is added by the replay tool; in your shell, `echo $?` prints the same number.

## Lab 28.1: Six broken workflows

### Objective

For each of six workflows, state the root cause from the documentation, name the layer it belongs to (Git, GitHub, or GitHub Actions), give the smallest correct fix, and say what would have prevented it. Each has a different documented root cause.

### Prerequisites

Chapter 20B, sections 20B.5 and 20B.11 to 20B.14; Chapter 20A on `actions/checkout`, permissions, secrets and caching; Chapter 18, section 18.8.

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-28-1-broken-workflows.sh
labs/shell m28-1
cd warehouse-api
```

The sandbox repository has two release tags and two topic branches: `docs/rollback-steps` changes only documentation, `feature/safety-stock` changes code and `uv.lock`.

Open the six files in your editor from the course folder: `workflows/broken/01-version-stamp.yml` to `06-cached-environment.yml`.

**The six reports.** These are constructed descriptions of what a team would observe, written for this exercise from the documented behavior. They are not captured logs.

| # | File | What the team reports |
|---|---|---|
| 1 | `01-version-stamp.yml` | The step "Derive the version from the latest tag" fails with exit status 128 on every push to `main`. The same `git describe` command prints a version on every developer's machine. |
| 2 | `02-source-tests.yml` | A pull request that changes only `docs/` cannot be merged. The merge box waits for the required check `unit-tests`. No run of the workflow exists for that pull request. |
| 3 | `03-pr-summary-comment.yml` | The tests pass. The step "Comment on the pull request" fails for every pull request, including those from the repository's own branches; GitHub's API refuses the request with a 403. |
| 4 | `04-integration-tests.yml` | Green for every maintainer. Red for the first pull request from an outside contributor's fork: the step "Check the supplier sandbox" stops with the workflow's own message that `SUPPLIER_API_KEY` is empty. The secret exists. |
| 5 | `05-branch-ci.yml` | Runs on feature branches end as "cancelled" although nobody cancelled them. It happens when a colleague pushes to a different branch at about the same time. |
| 6 | `06-cached-environment.yml` | A pull request added a dependency and updated `uv.lock`. Its tests fail in the job because the new package cannot be imported. They pass locally. The step "Install the locked dependencies" shows as skipped. |

### Commands

**Part A (lab shell).** First write, for each file, your hypothesis and the line you suspect. Then collect the evidence Git can give.

```bash
# Workflow 1: what a default checkout contains
git clone --quiet --depth 1 --no-tags "file://$PWD" ../runner
git -C ../runner rev-list --count HEAD
git -C ../runner tag --list
git -C ../runner describe --tags --match 'v*'
git describe --tags --match 'v*'

# Workflow 2: the files a path filter is evaluated on, for two pull requests
git diff --name-only main...docs/rollback-steps
git diff --name-only main...feature/safety-stock

# Workflow 5: the refs that receive pushes
git for-each-ref --format="%(refname)" refs/heads

# Workflow 6: does the lock file differ between the two refs?
git rev-parse main:uv.lock feature/safety-stock:uv.lock
git diff --stat main feature/safety-stock -- uv.lock
```

Workflows 3 and 4 have no Git evidence: their causes are in the token and in the secrets, which are GitHub Actions objects. Find them by reading the file against the event that started the run.

**Part B (normal shell).** Reproduce at least workflows 1, 3 and 5; all six if you have the time. Add one file, observe, fix it yourself, observe again, remove it.

```bash
# Workflow 1. The repository needs a release tag that is an ancestor of main.
git switch main && git pull
git tag -a v0.2.0 -m "Release 0.2.0" && git push origin v0.2.0
cp "$COURSE/workflows/broken/01-version-stamp.yml" .github/workflows/
git add .github/workflows/01-version-stamp.yml && git commit -m "Add the version stamp workflow" && git push origin main
gh run list --workflow 01-version-stamp.yml --limit 1
gh run view RUN_ID --log-failed

# Workflow 2. Require the check, then open a documentation-only pull request.
cp "$COURSE/workflows/broken/02-source-tests.yml" .github/workflows/     # commit and push to main as above
gh api --method POST "repos/$ORG/inventory-api/rulesets" --input "$COURSE/labs/ch20b/rulesets/lab-28-1-unit-tests.json"
git switch -c lab-28-1-docs && printf '\nA note.\n' >> README.md
git commit -am "Add a note to the README" && git push -u origin lab-28-1-docs
gh pr create --base main --title "Add a note" --body "Documentation only"
gh pr checks
gh pr view --json mergeStateStatus,statusCheckRollup
# Remove the ruleset before you go on: while it is active it also blocks your direct pushes to main.
ID=$(gh api "repos/$ORG/inventory-api/rulesets" --jq '.[] | select(.name=="lab-28-1 required check") | .id')
gh api --method DELETE "repos/$ORG/inventory-api/rulesets/$ID"
git switch main

# Workflow 3. Any pull request from a branch of the repository.
cp "$COURSE/workflows/broken/03-pr-summary-comment.yml" .github/workflows/   # commit and push to main
git switch -c lab-28-1-comment main && printf '\n' >> README.md
git commit -am "Touch the README" && git push -u origin lab-28-1-comment
gh pr create --base main --title "Touch the README" --body "For Lab 28.1"
gh pr checks --watch
gh run view RUN_ID --log-failed

# Workflow 4. The secret exists (a dummy value). Compare a branch pull request with a fork pull request.
gh secret set SUPPLIER_API_KEY
cp "$COURSE/workflows/broken/04-integration-tests.yml" .github/workflows/    # commit and push to main
gh repo fork --remote --remote-name fork
git switch -c lab-28-1-fork main && printf '\n' >> README.md && git commit -am "Change from a fork"
git push fork lab-28-1-fork
gh pr create --repo "$ORG/inventory-api" --base main --head "YOUR-USER:lab-28-1-fork" --title "From a fork" --body "For Lab 28.1"
gh pr checks --watch

# Workflow 5. Two branches pushed in one command.
cp "$COURSE/workflows/broken/05-branch-ci.yml" .github/workflows/            # commit and push to main
git branch lab-28-1-a main && git branch lab-28-1-b main
git push origin lab-28-1-a lab-28-1-b
gh run list --workflow 05-branch-ci.yml --limit 5

# Workflow 6. One run on main fills the cache. Then a pull request adds a dependency.
cp "$COURSE/workflows/broken/06-cached-environment.yml" .github/workflows/   # commit and push to main; wait for the run
git switch -c lab-28-1-dependency main
uv add --dev pyyaml
printf 'import yaml\n\n\ndef test_yaml_is_installed():\n    assert yaml.safe_load("a: 1") == {"a": 1}\n' > tests/test_yaml_available.py
git add -A && git commit -m "Add pyyaml and a test that needs it" && git push -u origin lab-28-1-dependency
gh pr create --base main --title "Add pyyaml" --body "For Lab 28.1"
gh pr checks --watch
gh cache list --key Linux-inventory-api
```

For workflow 4, if the run of the fork pull request waits for approval, approve it on the pull request page; Chapter 21A explains that gate. `gh repo fork` creates the fork under your personal account.

### Expected output

**Part A.**

<!-- snippet: ch20b/lab-28-1-broken-workflows/01-shallow -->
```text
# Workflow 1. The job sees a clone like this one:
$ git clone --quiet --depth 1 --no-tags "file://$PWD" ../runner
$ git -C ../runner rev-list --count HEAD
1
$ git -C ../runner tag --list
$ git -C ../runner describe --tags --match 'v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

<!-- snippet: ch20b/lab-28-1-broken-workflows/02-paths -->
```text
# Workflow 2. For a pull request, a path filter is evaluated on the three-dot diff:
$ git diff --name-only main...docs/rollback-steps
docs/runbook.md
$ git diff --name-only main...feature/safety-stock
src/warehouse/rules.py
uv.lock
```
<!-- /snippet -->

<!-- snippet: ch20b/lab-28-1-broken-workflows/03-refs -->
```text
# Workflow 5. Each of these refs gets pushes; a concurrency group should tell them apart:
$ git for-each-ref --format="%(refname)" refs/heads
refs/heads/docs/rollback-steps
refs/heads/feature/safety-stock
refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch20b/lab-28-1-broken-workflows/04-cache-key -->
```text
# Workflow 6. A key built from the lock file changes exactly when the lock file does:
$ git rev-parse main:uv.lock feature/safety-stock:uv.lock
d4209093593c0ed4d1d0ef470f155c412e19b219
dfb559935055c75ba939582753a8735a0e1240ab
$ git diff --stat main feature/safety-stock -- uv.lock
 uv.lock | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

**Part B.** Nothing was captured. What the documentation leads you to expect is the report in the table under "Setup" for each workflow. If you observe something else, that is a finding: write down the run's event, ref and commit (`gh run view RUN_ID --json event,headBranch,headSha,conclusion`) before you theorise. For workflow 2, `gh pr checks` has no check from this workflow to show, and `gh pr checks` exits with status 8 while checks are pending.

### What happened internally

Use the transcripts as evidence for your diagnoses; the full reasoning is in the solutions file.

- The clone made with `--depth 1 --no-tags` has one commit and no tags. That is the documented default of `actions/checkout` (`fetch-depth: 1`, `fetch-tags: false`).
- The three-dot diff lists the files a pull request changes relative to the merge base. A `paths` filter on `pull_request` is evaluated on that list.
- Three branches are three refs. A concurrency group is a string; whether two runs share it depends on what the string contains.
- The two blob IDs of `uv.lock` differ. Any key derived from the file's content differs too; a key that does not mention the file cannot.

### Checkpoint

Before Part B you have six lines of this form, one per workflow: "Root cause: … Layer: … Line: … Fix: …". No two root causes are the same. If two of yours are the same, one is wrong.

### Failure scenario

The commonest wrong repair is one that makes the red step green without removing the cause. For workflow 1:

<!-- snippet: ch20b/lab-28-1-broken-workflows/05-failure -->
```text
# A tempting repair of workflow 1 that hides the fault instead of fixing it:
$ git -C ../runner describe --tags --match 'v*' --always
57c8425
```
<!-- /snippet -->

With `--always`, `git describe` falls back to the abbreviated commit ID. The step passes, and the build is now stamped with something that is not a version. Each of the six has such a repair: a broader filter, `permissions: write-all`, `pull_request_target`, removing the group, `restore-keys`. For each of your six fixes, write down the tempting wrong repair and what it would cost.

### Recovery

<!-- snippet: ch20b/lab-28-1-broken-workflows/06-recovery -->
```text
$ git -C ../runner fetch --quiet --unshallow --tags
$ git -C ../runner describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

With the history and the tags present, the original command works unchanged. On GitHub, apply your fix to each workflow you reproduced, push, and watch the run. Then clean up:

```bash
gh pr list --state open
gh pr close NUMBER --delete-branch
git push origin --delete lab-28-1-a lab-28-1-b
git switch main
git rm .github/workflows/01-version-stamp.yml .github/workflows/02-source-tests.yml .github/workflows/03-pr-summary-comment.yml \
       .github/workflows/04-integration-tests.yml .github/workflows/05-branch-ci.yml .github/workflows/06-cached-environment.yml
git commit -m "Remove the Lab 28.1 workflows" && git push origin main
gh secret delete SUPPLIER_API_KEY
gh cache delete --all
```

`git rm` reports an error for files you never added; remove those names from the command. Delete the fork in the browser when you no longer need it.

### Verification

- Part A: `git -C ../runner describe --tags --match 'v*'` prints the same string as in your own clone.
- Part B: for each workflow you reproduced, the run after your fix is green for the reason you predicted, and you can point at the log line that shows it (for workflow 1 the printed version; for workflow 6 the install step running after the lock file changed).
- `gh api "repos/$ORG/inventory-api/rulesets" --jq '.[].name'` no longer lists `lab-28-1 required check`.
- Compare your six diagnoses with `solutions/m28-broken-workflows.md`.

### Questions

1. Which of the six failures would a YAML parser or a workflow linter have caught? Why?
2. For workflow 2, two different changes make the documentation pull request mergeable: one in the workflow, one in the ruleset. Which do you choose, and what does the other one cost?
3. For workflow 4, why is "trigger on `pull_request_target` so the secret is available" the wrong fix?
4. For workflow 5, write the group expression you would use and explain each part.
5. For workflow 6, the cache step logs an exact hit. Why was that the problem and not the solution?
6. Which of the six belong to Git, which to GitHub, which to GitHub Actions?

## Lab 28.2: The investigation order, applied to a failing run

### Objective

Work through the twelve-step investigation order of section 20B.11 on a described failing run, rule steps in or out with evidence, find the root cause, reproduce it locally, and fix it at the right place.

### Prerequisites

Chapter 20B, sections 20B.11, 20B.12 and 20B.14; Chapter 17 on the test merge commit of a pull request.

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-28-2-merge-ref.sh
labs/shell m28-2
cd warehouse-api
```

You are on `feature/bulk-reorder`, your branch. Asha merged a change to `main` after you branched.

**The run.** This description is constructed for the exercise. It is not a captured log, and the run never existed. Its Git facts are those of the sandbox repository, so you can check every one of them.

| Fact | Value |
|---|---|
| Your message to the team | "My pull request is red. The checks pass on my machine. I re-ran the job twice and it fails the same way." |
| Workflow | a test workflow like `01-tests.yml`: one job that checks out the repository and runs `python3 tests/check_rules.py` and `python3 tests/check_bulk.py` |
| Workflow file changed in this pull request | no |
| Event | `pull_request` (`synchronize`) |
| Head branch and head commit | `feature/bulk-reorder` at `34f82ef` |
| Base branch | `main`, which is at `2230054` |
| Commit the job checked out | a commit ID that is in nobody's clone; the job reported a detached HEAD |
| `permissions` | `contents: read`; the job makes no API calls |
| Runner | `ubuntu-24.04`, public repository; the job ran 20 seconds |
| Environment | none |
| Dependencies | none beyond the standard library; no install step |
| Secrets | none used |
| Actions | `actions/checkout` and `actions/setup-python`, pins unchanged for a month |
| Failed step | the second check; it printed one line: `FAIL: TypeError: needs_reorder() missing 1 required positional argument: 'safety_stock'` |
| Artifacts and cache | none |
| Concurrency | the run completed; conclusion `failure`, not `cancelled` |
| Other pull requests | green |

### Commands

**Part A (lab shell).** First, on paper: go through the twelve steps in order. For each, write "ruled out by …" or "open". Only then type.

```bash
# What you ran
git status --short --branch
python3 tests/check_rules.py
python3 tests/check_bulk.py

# Step 2, event: which commit does a pull_request run build?
git log --oneline --graph --format="%h %an: %s" main feature/bulk-reorder -4
git merge-base main feature/bulk-reorder

# Build that commit yourself: the merge of your branch into the current base, detached
git merge-tree --write-tree main feature/bulk-reorder
git switch --quiet --detach main
git merge --quiet --no-ff -m "Merge feature/bulk-reorder into main (test merge)" feature/bulk-reorder
git status --short --branch
python3 tests/check_rules.py
python3 tests/check_bulk.py
```

**Part B (normal shell, optional).** Reproduce the shape on GitHub with two pull requests in the practice repository: one changes the signature of a function in `src/inventory_api/stock.py` and its tests; the other, branched before the first is merged, adds a caller of the old signature with its own test. Merge the first, then push an empty commit to the second (`git commit --allow-empty -m "Trigger CI" && git push`) and read `gh pr checks` and `gh run view RUN_ID --json event,headBranch,headSha`. Compare `headSha` with `git rev-parse HEAD`.

### Expected output

<!-- snippet: ch20b/lab-28-2-merge-ref/01-local -->
```text
$ git status --short --branch
## feature/bulk-reorder
$ python3 tests/check_rules.py
ok: 2 checks
$ python3 tests/check_bulk.py
ok: bulk reorder
```
<!-- /snippet -->

<!-- snippet: ch20b/lab-28-2-merge-ref/02-graph -->
```text
$ git log --oneline --graph --format="%h %an: %s" main feature/bulk-reorder -4
* 2230054 Asha Rao: Require a safety stock in the reorder rules
| * 34f82ef Lab User: Add bulk reorder
|/  
* 57c8425 Lab User: Add the lock file
* 197d992 Lab User: Document the release runbook
$ git merge-base main feature/bulk-reorder
57c8425908f43c74c14b2642edb59e0f99dac38c
```
<!-- /snippet -->

<!-- snippet: ch20b/lab-28-2-merge-ref/03-merge-commit -->
```text
# Build what the pull request run checks out: the merge of the branch into main, detached.
$ git merge-tree --write-tree main feature/bulk-reorder
fe5b8f225d8a79237933117a63958bbd7dd8a2c6
$ git switch --quiet --detach main
$ git merge --quiet --no-ff -m "Merge feature/bulk-reorder into main (test merge)" feature/bulk-reorder
$ git status --short --branch
## HEAD (no branch)
$ python3 tests/check_rules.py
ok: 2 checks
$ python3 tests/check_bulk.py
FAIL: TypeError: needs_reorder() missing 1 required positional argument: 'safety_stock'
[exit status: 1]
```
<!-- /snippet -->

### What happened internally

Your branch and `main` diverged at `57c8425`. On your branch, `bulk.py` calls `needs_reorder` with three arguments, and the function takes three. On `main`, Asha's commit `2230054` gave it a fourth. The two changes touch different files, so `git merge-tree --write-tree` printed a tree ID and nothing else: the merge is clean. Clean is a statement about text, not about behavior.

For a `pull_request` event GitHub Actions sets `GITHUB_REF` to `refs/pull/N/merge` and `GITHUB_SHA` to the test merge commit of the head into the current base, and `actions/checkout` checks that out in detached HEAD. That commit contains your caller and Asha's signature together. You reproduced it with `git switch --detach main` and `git merge --no-ff`, and the second check failed with the same message the run description gives. Your merge commit has another ID than GitHub's would (different committer and time), and the same tree.

In `.git`, the detached merge moved only HEAD and added one commit object; no branch moved. `git status --short --branch` shows `## HEAD (no branch)`, the same state the job reported.

### Checkpoint

Your paper list rules out steps 1 and 3 to 8 and 10 to 12 with one fact from the table each, and leaves step 2 open before you read any log. If you needed the log line to become suspicious, read the event row again: "a commit ID that is in nobody's clone" is the whole diagnosis.

### Failure scenario

The instinctive response is to test the branch again, and to re-run the job.

<!-- snippet: ch20b/lab-28-2-merge-ref/04-failure -->
```text
# Re-checking the branch alone reproduces nothing, however often it is repeated:
$ git switch --quiet feature/bulk-reorder
$ python3 tests/check_bulk.py
ok: bulk reorder
[exit status: 0]
```
<!-- /snippet -->

The branch alone passes, every time. A re-run on GitHub fails, every time, because a re-run reuses the original commit and ref. Neither repetition tests a new hypothesis. The second tempting move is to make the workflow check out `github.event.pull_request.head.sha`: the pull request turns green, and `main` breaks at the moment of merging.

### Recovery

<!-- snippet: ch20b/lab-28-2-merge-ref/05-recovery -->
```text
# Bring the base into the branch, then fix the call that the base change broke.
$ git merge --quiet -m "Merge main into feature/bulk-reorder" main
$ python3 tests/check_bulk.py
FAIL: TypeError: needs_reorder() missing 1 required positional argument: 'safety_stock'
[exit status: 1]
$ sed -i.bak 's/needs_reorder(stock, daily, lead_days)/needs_reorder(stock, daily, lead_days, 0)/' src/warehouse/bulk.py && rm src/warehouse/bulk.py.bak
$ python3 tests/check_bulk.py
ok: bulk reorder
[exit status: 0]
$ git commit -q -am "Pass the safety stock to needs_reorder"
$ git log --oneline --graph -4
* 2cb0b73 Pass the safety stock to needs_reorder
*   9c7cc7e Merge main into feature/bulk-reorder
|\  
| * 2230054 Require a safety stock in the reorder rules
* | 34f82ef Add bulk reorder
|/  
```
<!-- /snippet -->

Merging `main` into the branch brings the failure to your machine, where you can fix it: the check fails locally first, then passes after the call passes a safety stock. The fix is a commit on your branch. (A rebase onto `main` would serve as well; Chapter 9 compares the two.) After the push, the new run builds a new test merge, which now passes.

### Verification

Build the test merge again from the fixed branch:

<!-- snippet: ch20b/lab-28-2-merge-ref/06-verify -->
```text
$ git switch --quiet --detach main
$ git merge --quiet --no-ff -m "Test merge" feature/bulk-reorder
$ python3 tests/check_rules.py && python3 tests/check_bulk.py
ok: 2 checks
ok: bulk reorder
[exit status: 0]
$ git switch --quiet feature/bulk-reorder
$ git status --short --branch
## feature/bulk-reorder
```
<!-- /snippet -->

Both checks print `ok` on the merge, and you are back on your branch with a clean working tree.

### Questions

1. Which single row of the run description should have sent you to step 2, and why?
2. Why did re-running the job twice produce no new information?
3. `git merge-tree --write-tree` reported a clean merge. What does "clean" guarantee, and what does it not?
4. A ruleset option would have forced you to notice this before the run. Which one, and what does it cost a busy repository? Which platform feature removes that cost?
5. Write the three-sentence root-cause statement you would give a CTO: symptom, mechanism with its layer, prevention.
6. Go through the twelve steps for this different description: "A job fails on the first run after a two-week company shutdown, in the step right after the cache is restored, and passes on every later run." Which steps open first, and which documented fact do you check?

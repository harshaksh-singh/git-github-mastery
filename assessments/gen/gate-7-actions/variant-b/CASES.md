# Gate 7, hands-on, variant B: three cases to diagnose

Everything in this directory was constructed for the gate. The workflow files parse as YAML and contain faults on purpose; they are teaching material. The run descriptions are written for the cases: no log is quoted from a real run. The Git transcript in case 2 is real output of `labs/gates/g7-evidence.sh`.

Work on paper. You may use a lab shell and `python3` to test what Git, a shell or a YAML parser does; you may not use GitHub. For every statement about what GitHub Actions does, name the textbook section it rests on.

## Case 1 (12 points): the pull request workflow

**File:** [`pr.yml`](pr.yml). The ruleset of `main` requires the status check `all-green`. The repository is public and receives pull requests from forks. `REPORT_TOKEN` is a repository secret.

The team's complaints:

1. "A pull request with failing unit tests was merged. The `test` job was green."
2. "Another pull request was merged although `lint` had failed. The merge box showed `all-green` as skipped, and the button was enabled."
3. "The `publish-report` job fails with a message that `report.html` does not exist, on every run, although the `test` job builds that file one minute earlier."
4. "On pull requests from forks, `publish-report` gets as far as the upload and is rejected by the report server as unauthorized. On our own branches the same token works."
5. "When two people push to two different pull requests within a minute, one of the two runs ends as cancelled, and that pull request cannot be merged until someone pushes again."
6. "A job hung on Friday evening. We noticed on Saturday morning; it was still running when we looked at breakfast."

**Your task.** For each complaint: the line or lines that cause it, the mechanism, and the corrected lines. For complaint 2 write the corrected `all-green` job in full. For complaint 4 say what the job received in place of the secret, why, and why "make the secret available to forks" is the wrong repair.

## Case 2 (9 points): green on every Mac

A service is developed on macOS laptops and tested in CI on `ubuntu-24.04`. Since the first commit, the job that runs `python3 app.py` fails on the runner with a `FileNotFoundError` that names `prompts/system.txt`. The same command works on every developer's machine. The team's conclusion: "the runner image is missing something; we need a custom image".

The evidence, from a clone:

<!-- snippet: gates/g7-evidence/b2-evidence -->
```text
$ git ls-files
app.py
prompts/System.txt
$ grep -n open app.py
2:    with open("prompts/system.txt") as f:
$ git log --name-status --format='%h %s' -1
2246d2e Add system prompt and app

A	app.py
A	prompts/System.txt
```
<!-- /snippet -->

**Your task.** Name the root cause and the layer it belongs to: Git, the file system, Python, or the runner. Explain why the laptops do not show it. Give the repair as Git commands that work on a Mac, and say why renaming the file in the Finder or with `mv` may not be enough. Name one check that would report this class of problem on a Mac before the push. Then place this case in the investigation order of Chapter 20B: at which numbered question would you have found it, and which earlier questions does the evidence let you skip?

## Case 3 (9 points): the nightly evaluation

**File:** [`nightly.yml`](nightly.yml), as it is on the branch `feature/eval-v8`. On `main` the file exists in an older version that names the dataset `golden-v6`.

What the author reports:

1. "I changed the dataset to `golden-v7` on my branch on Monday. Tuesday's and Wednesday's nightly runs still used v6."
2. "So I started the workflow by hand from my branch. Now `prepare` prints `chosen: golden-v7`, and the `evaluate` job calls the evaluation with an empty dataset name."
3. "After I hard-coded the name in `evaluate`, the `compare` job says that `scores.json` does not exist."

**Your task.** One root cause per report: the mechanism and the corrected lines. For report 1, state which copy of a workflow file each of these events uses: `schedule`, `workflow_dispatch`, `push`, `pull_request`. For reports 2 and 3, state the three ways in which data can pass from one step or job to a later one, and which one each of the two situations needs.

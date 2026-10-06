# Gate 7, hands-on, variant A: three cases to diagnose

Everything in this directory was constructed for the gate. The workflow files parse as YAML and contain faults on purpose; they are teaching material. The run descriptions are written for the cases: no log is quoted from a real run. The Git transcript in case 2 is real output of `labs/gates/g7-evidence.sh`, in which plain Git plays the part of GitHub.

Work on paper. You may use a lab shell and `python3` to test what Git, a shell or a YAML parser does; you may not use GitHub. For every statement about what GitHub Actions does, name the textbook section it rests on.

## Case 1 (12 points): one workflow, six complaints

**File:** [`ci.yml`](ci.yml), the only workflow of the repository. The ruleset of `main` requires the status check `package`.

The team's complaints, collected over two weeks:

1. "One of the two matrix jobs fails in the Python setup step. It asks for a Python version that nobody wrote into the file."
2. "The `Version` step fails on the runner with a message about not being able to describe anything. `git describe --tags` prints `v2.3.0-4-g...` on every laptop."
3. "When we work around complaint 2, the `Test` step prints `testing version` followed by nothing."
4. "A pull request whose unit tests fail has a green `Test` step. We found out after the merge."
5. "We upgraded a dependency two weeks ago. The job still installs the old one."
6. "The required check `package` is green on every pull request, although nothing is ever packaged for a pull request. And a pull request that only changes `docs/` waits forever for the same check."

**Your task.** For each complaint: the line or lines of `ci.yml` that cause it, the mechanism, and the corrected lines. Complaint 6 has two different causes; give both. Then say which of the six would also have been caught by reading the file with a YAML parser before pushing, and which only by knowing how a runner executes a step.

## Case 2 (9 points): "on the same commit"

Pull request 31, `feature/bigger-batches` into `main`. Its author:

> CI is red on my pull request and green on my laptop, on the same commit. I re-ran the job three times. It is a flaky runner.

The author's laptop, in the clone, on the branch of the pull request:

<!-- snippet: gates/g7-evidence/a2-laptop -->
```text
$ git status -sb
## feature/bigger-batches...origin/feature/bigger-batches
$ git log --oneline -2
4687647 Batch 48 requests at a time
e950bf8 Add batch limit and its check
$ sh check.sh
check: ok (batch 48, limit 64)
```
<!-- /snippet -->

The failed run, as the author describes it: the event is `pull_request`; the checkout step's log mentions `refs/pull/31/merge`; the step that runs `sh check.sh` ends with exit status 1 and a message that contains the number 32.

**Your task.** Say which commit the laptop tested and which commit the runner tested, and why they differ although "the commit" is the same in the author's mind. Give the Git commands that reproduce the runner's result on the laptop. Name the root cause, the fix, and the two platform settings that prevent a pull request in this state from being merged. Explain why three re-runs could not help.

## Case 3 (9 points): the release that deployed something else

**File:** [`release.yml`](release.yml). **Configured by the administrator on GitHub:** an environment `staging` without rules, and an environment `production` with two required reviewers.

The incident report, Tuesday:

> Two pull requests were merged into `main` forty seconds apart.
>
> - The first run was in the middle of its production job, inside the database migration, when it stopped with the conclusion "cancelled". Nobody cancelled it.
> - The production job of the second run started without anyone approving it. The two reviewers were never asked.
> - The image that runs in production has a different digest from the image that was tested in the `build` job and from the image in staging, although all three carry the same tag.

**Your task.** One root cause per bullet: the lines of `release.yml`, the mechanism, and the correction. For the second bullet, say how you would verify the state on GitHub with one `gh` command (do not run it), and what the list of environments in the repository settings will show. For the third, describe the structure that makes "what was tested is what is deployed" true by construction.

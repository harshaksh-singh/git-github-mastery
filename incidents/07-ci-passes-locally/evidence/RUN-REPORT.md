# Incident 7: what the failed run reported

> **Constructed for the exercise.** Nothing on GitHub can be run from this course, so this is not a captured log. It is a description of what each step of the run reported, written so that it is consistent with the documented behavior of GitHub Actions and of `actions/checkout` v7.0.1 ([checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md)). The one Git message quoted below is the message Git 2.55.0 prints in that state; the replay script `labs/incidents/solve-07-ci-passes-locally.sh` reproduces it locally.

**Run:** workflow `CI`, event `pull_request`, pull request from `docs/render-docstring` into `main`. The same job also failed on the last `push` to `main`.

| Step | Result | What it reported |
|---|---|---|
| Set up job | succeeded | The job ran on a GitHub-hosted runner with the label `ubuntu-24.04`. The token permissions listed were `contents: read`. |
| `actions/checkout` | succeeded | It fetched one commit with depth 1 and checked it out in detached HEAD. For the `pull_request` event the ref was the merge ref of the pull request, not the tip of the head branch. No tags were fetched. |
| `actions/setup-python` | succeeded | Python 3.12 was put on the path. |
| Compute version | **failed**, exit code 128 | The only output was the Git message `fatal: No names found, cannot describe anything.` |
| Run tests | skipped | A step is skipped when an earlier step of the job failed. |
| Post steps | succeeded | Clean-up. |

Other facts the reporter collected:

- Re-running the failed job twice gave the same result.
- The "Compute version" step was added to the workflow five days before the report. The job has failed on every run since.
- The tag `v1.4.0` is visible on the repository's tags page.
- On the reporter's Mac, `bash scripts/version.sh` prints a version and `python3 -m unittest discover -s tests` passes.

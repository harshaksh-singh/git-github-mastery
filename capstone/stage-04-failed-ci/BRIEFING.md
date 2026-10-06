# Stage 4 briefing: a red check on a small pull request

**When:** Thursday 17 September 2026, 11:00 IST. **Where:** you work in `you/`; Tanvi's clone is `tanvi/`.

**Start the stage:** `capstone/stage-04-failed-ci/inject.sh` (needs a passed stage 3), or `capstone/setup.sh --stage 4`.

This stage is a diagnosis on paper. A workflow cannot run in the sandbox. The inject script writes two files into the sandbox root:

- `evidence/stage-04/ci.yml`: the workflow file, as the run used it;
- `evidence/stage-04/RUN-REPORT.md`: a description of the failed run, **constructed for this exercise**, with the real commit IDs of your sandbox. Nothing in it was captured from GitHub.

## What you are told

Tanvi:

> My batch pull request is tiny: one new file and one test. It passes on my machine, every time. On GitHub the test job is red. I re-ran it twice, red both times, same step. The runner has Python 3.13 and I have a newer one here, so my bet is the Python version, or the runner picked up something stale from a cache. Nothing in my branch touches CI.
>
> The product demo is at three. Nandini can merge over a red check as an administrator. Can you tell her it is safe? It is one file.

Nandini:

> I can bypass the rule. I will not do it on a guess. Tell me which commit that job tested and why it is red, and I want to see the same failure on a laptop before anyone changes anything.

## What you are asked for

1. From the two evidence files, answer the first questions of the fixed investigation order of [Chapter 30](../../textbook/ch30-incident-response.md), section 30.18: which workflow file, which event, which commit was checked out. Write the answers down before you touch a repository.
2. Reproduce the failure locally with plain Git: build the commit the job tested and run `bash scripts/test.sh` on it.
3. Name the root cause and its layer, and test Tanvi's two hypotheses against the evidence.
4. Repair the pull request so that the commit CI will test passes, and merge it through the pull request.
5. Answer the request for an administrator merge.

## Rules for this stage

- Section 6 of the capstone [`README.md`](../README.md) lists what the sandbox's server imitates of GitHub. Everything in that table is available to you.
- The branch is Tanvi's. You may push to it; tell her what you pushed and what she has to do in her clone.
- State honestly what a local reproduction proves about the run on GitHub and what it does not.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md). The evidence log for this stage contains the paper answers of item 1.

## Check

```bash
capstone/stage-04-failed-ci/check.sh
```

When it passes, apply the next stage with `capstone/stage-05-lost-work/inject.sh`.

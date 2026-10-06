# Stage 8 briefing: production errors, and main is not ready

**When:** Wednesday 23 September 2026, 10:20 IST. **Where:** you work in `you/`.

**Start the stage:** `capstone/stage-08-hotfix-and-backport/inject.sh` (needs a passed stage 7), or `capstone/setup.sh --stage 8`.

## What you are told

The alert (constructed for this exercise):

```text
[ALERT] intent-router: HTTP 500 on 2.1% of classify requests   since 09:42 IST
        version in production: v1.3.1
        sample: TypeError in router/classify.py, function classify
        sample input: candidates=[("billing_refund", 1.0, None)]
```

Kabir:

> The embedding provider has been timing out since about 09:40. When it does, the caller in the gateway passes `None` as the embedding score. That is by design on their side and they will not change it today.

Tanvi (on call):

> I have a fix. It is on `hotfix/embed-none` with a test, the pull request is open against `main`. Plan: merge it, tag `main` as v1.3.2, deploy. Fifteen minutes.

Leela Varma (CTO), in the incident channel:

> Two questions before anything ships. One: it worked yesterday on the same version, so what changed, and would rolling back to 1.3.0 be faster? Two: the tenant weights and the VIP escalation are not signed off. Acme's acceptance test for those is next week. I do not want them in production today. Tell me what exactly 1.3.2 will contain.

Nandini:

> Our rule is that a fix lands on `main` first and is then copied to the release line, so that the next release cannot lose it. We have no release branch for 1.3 yet. Make one where it belongs.

## What you are asked for

1. Answer the CTO's first question with evidence from the repository: is this a regression, and what would a rollback change?
2. Review Tanvi's fix. If it is right for `main`, merge it there through its pull request.
3. Create the maintenance line `release/1.3` at the commit production runs, and bring the fix to it the way the team's rule says, through a pull request whose base is `release/1.3` (`../pr open <branch> --base release/1.3`).
4. Make sure the fix works on the release line: it was written against `main`.
5. Release the result as the annotated tag `v1.3.2`, and answer the CTO's second question with a diff.
6. Show how someone can verify, next month, that the fix in 1.3.2 is also in `main`.

## Rules for this stage

- `v1.3.2` contains the fix and nothing else that `v1.3.1` did not contain.
- The copy on the release line records where it came from.
- "It applied" and "it works there" are different statements. Run the tests where the code will run.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md), and after this stage the final postmortem described there.

## Check

```bash
capstone/stage-08-hotfix-and-backport/check.sh
```

When it passes, the simulation is complete. Hand in your deliverables and read [`EVALUATION.md`](../EVALUATION.md).

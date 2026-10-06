# Stage 1 briefing: the billing queue is flooded

**When:** Monday 14 September 2026, 10:15 IST. **Where:** the capstone sandbox; you work in `you/`.

**Start the stage:** `capstone/setup.sh` builds the company repository and applies this stage. Then `labs/shell "<sandbox>/you"`.

## What you are told

The alert, from the queue monitor (constructed for this exercise):

```text
[ALERT] queue "billing" backlog 412 messages (normal: under 60)   since 09:05 IST
        intent-router version in production: v1.3.0 (deployed today 09:00 IST, previous: v1.2.0)
```

The lead of the billing desk, in the incident channel:

> We are drowning in junk. Hundreds of messages that repeat "refund refund refund" a dozen times, clearly written by a script. Until Friday that kind of thing went to the triage people, not to us.

One message from the production log, pasted by Tanvi (on call):

```text
tenant=default  candidate=billing_refund  keyword_hits=12  embed_score=0.10  routed_to=billing_refund
```

Tanvi:

> 1.3.0 went out at nine. The last thing that went into the release was Kabir's change of the embedding weight, #11. It changes every score, so that is the one. I have opened a pull request that reverts it. Approve it, I merge, we cut 1.3.1 and we are done in ten minutes.

Kabir:

> The weight change was evaluated on the full evaluation set before it was merged. Accuracy went up. I would be surprised.

Nandini (tech lead):

> I do not want a second bad release today. Find out which change did this and show me how you know. Then fix production with the smallest change that removes the fault, through a pull request, and tag it as 1.3.1. Nobody rewrites `main`.

## What you are asked for

1. Establish, with evidence, which change introduced the fault. A guess that turns out right does not count; show how the alternatives were ruled out.
2. Remove the fault from `main` through a pull request (`../pr open`, `../pr merge`). `main` must keep every other change of the release.
3. Release the result as the annotated tag `v1.3.1` and push the tag.
4. Decide what happens to the pull request that Tanvi opened, and say why.

## Rules for this stage

- The product code needs no new feature. If you find yourself writing more than a test, stop and reconsider.
- The 1.2.0 release was good, by everyone's account. Verify that before you rely on it.
- `python3` runs the project's code. `bash scripts/test.sh` runs its tests.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md) for this stage. The message to the CTO must say whether customers were affected, from when to when, and what "fixed" was verified against.

## Check

```bash
capstone/stage-01-bug-in-production/check.sh
```

The check sees Git state only. When it passes, apply the next stage with `capstone/stage-02-merge-conflict/inject.sh`.

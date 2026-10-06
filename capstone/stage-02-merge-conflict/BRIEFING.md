# Stage 2 briefing: your pull request and Kabir's

**When:** Tuesday 15 September 2026, 10:30 IST. **Where:** you work in `you/`.

**Start the stage:** `capstone/stage-02-merge-conflict/inject.sh` (needs a passed stage 1), or `capstone/setup.sh --stage 2`.

## What you are told

You have had pull request #12 open since Friday: `feature/low-confidence-penalty`, one commit, "Halve the score when keyword and embedding disagree". Kabir's pull request #13, per-tenant embedding weights, was open at the same time. Both change `router/scoring.py`.

Nandini, 09:50:

> I merged Kabir's #13 this morning. Yours is next; I need both in `main` before the Acme demo. GitHub said your branch had conflicts with `main`.

Kabir, 10:05:

> Sorted it for you. I merged `main` into your branch on my machine and pushed. There were conflicts in two files and I resolved them, the tests are green and #12 shows as mergeable again. You only have to press the button.

The CI status of #12, as GitHub would show it (constructed): all checks passed on the newest commit.

## What you are asked for

1. Before anything is merged, establish what pull request #12 would add to `main` now, and compare it with what it was meant to add.
2. Bring `main` to the state in which both changes work, alone and together: a tenant with its own weight gets that weight, and the disagreement penalty applies to the score computed with that weight.
3. Merge through the pull request. `main` is not rewritten.
4. Tell Kabir what you found, in words he can act on next time.

## Rules for this stage

- The branch is yours, and a teammate has pushed to it. Whatever you do to it, he has a copy.
- "The tests are green" is evidence about the tests. Ask what they cover.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md). In the root cause, name the layer: is this Git, GitHub, or a person's decision that Git carried out?

## Check

```bash
capstone/stage-02-merge-conflict/check.sh
```

When it passes, apply the next stage with `capstone/stage-03-leaked-secret/inject.sh`.

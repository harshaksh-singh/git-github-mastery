# Stage 7 briefing: the pull request with every commit twice

**When:** Tuesday 22 September 2026, 11:00 IST. **Where:** you work in `you/`; `nandini/` and `kabir/` are available again.

**Start the stage:** `capstone/stage-07-broken-pull-request/inject.sh` (needs a passed stage 6), or `capstone/setup.sh --stage 7`.

## What you are told

The branch `feature/vip-escalation` is shared. You started it and opened the pull request "Escalate VIP customers". Kabir added a commit. You added the tests and pushed. Nandini is the reviewer. This morning you made one more commit, which you have not pushed yet, and you have not fetched since your last push.

Nandini, in the pull request:

> What happened to this pull request? An hour ago it had three commits. Now the list shows the commits twice, plus a merge commit with my name on it. I only pulled, committed one paragraph for the README and pushed. Who is supposed to review this?

Kabir:

> `main` had moved, so I rebased the branch onto it this morning to keep the pull request mergeable. I fetched first and I pushed with `--force-with-lease`, not with `--force`, exactly as the handbook says. A lease cannot overwrite anybody's work, so whatever this is, it is not the rebase.

Tanvi:

> Files changed looks right to me, and CI is green. Squash-merge it and the commit list does not matter any more.

## What you are asked for

Work through the eleven steps of [Chapter 30](../../textbook/ch30-incident-response.md), section 30.16, and hand in a line for each:

1. Explain, from the reflogs of the clones involved, the exact sequence that produced the commit list. Each of the three statements above contains a claim; test each one.
2. Produce a branch that contains every change exactly once, on top of the current `main`, with no merge commit: the two original commits as rebased, your tests, your unpushed commit, and Nandini's README commit.
3. Prove before you publish that the repair changes history and no content.
4. Publish it without overwriting anything you have not examined, and bring the clones of Nandini and Kabir in line with the server.
5. Leave the pull request open for the reviewer. Answer Tanvi's suggestion: when is it acceptable, and what would it have cost here?

## Rules for this stage

- Do not run `git pull` on the branch until you can say what it would do.
- Nobody's commits are discarded. Nobody's rebase is undone.
- The forced push that this repair needs names the value it expects on the server.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md), with the eleven steps as the structure of the evidence log and the recovery. The prevention names one control per contributing condition.

## Check

```bash
capstone/stage-07-broken-pull-request/check.sh
```

When it passes, apply the last stage with `capstone/stage-08-hotfix-and-backport/inject.sh`.

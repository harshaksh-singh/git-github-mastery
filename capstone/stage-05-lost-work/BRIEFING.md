# Stage 5 briefing: Tanvi's Friday

**When:** Friday 18 September 2026, 10:45 IST. **Where:** the damage is in `tanvi/`. You sit at her machine, with her.

**Start the stage:** `capstone/stage-05-lost-work/inject.sh` (needs a passed stage 4), or `capstone/setup.sh --stage 5`.

## What you are told

Tanvi:

> I have lost the whole morning. I was working on the routing metrics on my metrics branch: three commits, counters, the per-tenant fallbacks, and the text output with a test. Kabir said `main` had moved, so I fetched to get the new `main`, and after that my three commits were not in the log any more. I think the fetch overwrote them, or the rebase did, I am not sure what I typed. I never pushed.
>
> I also had the alert rules for the deployment, a new file, which I had added but not committed. And a notes file with my to-do list, and a paragraph for the README that I was in the middle of.
>
> One more thing: on Wednesday you had us all expire our reflogs and run `git gc` because of the token. So I assume the reflog cannot help here.
>
> I have created `feature/routing-metrics` again so that I can start over. It is empty.

## What you are asked for

1. Find out what happened in her clone, from its own records, and compare that with her account. Change nothing until you have read them.
2. Recover everything that Git can recover. Put the commits on `feature/routing-metrics`, where she meant them to be. `main` in her clone must equal `main` on the server.
3. Push the branch, so that the work no longer exists on one laptop only.
4. Tell her precisely what could not be recovered, and why Git has no copy of it.
5. Answer her assumption about Wednesday's clean-up.

## Rules for this stage

- Name every state you may need before you move anything.
- Do not run `git gc`, `git prune` or `git reflog expire` in her clone during this stage.
- Her staged file must come back as a file in her working tree. Whether it is staged or committed afterwards is her decision.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md). This is one person's local work: say which severity that is and who needs to be told.

## Check

```bash
capstone/stage-05-lost-work/check.sh
```

When it passes, apply the next stage with `capstone/stage-06-deleted-branch/inject.sh`.

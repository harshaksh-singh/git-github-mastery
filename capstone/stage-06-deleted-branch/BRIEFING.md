# Stage 6 briefing: the branch for Thursday's demo

**When:** Tuesday 22 September 2026, 09:10 IST. **Where:** you work in `you/`. You administer `server.git`.

**Start the stage:** `capstone/stage-06-deleted-branch/inject.sh` (needs a passed stage 5), or `capstone/setup.sh --stage 6`.

The inject script writes two files into the sandbox root: `evidence/stage-06/cleanup-merged-branches.sh` and `evidence/stage-06/cleanup-output.txt`. They are what Tanvi pasted into the channel when asked what she had run this morning.

## What you are told

Nandini:

> Kabir's multilingual branch is gone. `feature/multilingual-intents` is not in the branch list, and his pull request, the one with the Hindi and Tamil keyword lists, shows as closed. I did not close it. I reviewed it last night in the browser: three commits, the last one picks the keyword lists by the detected language. I need that branch for the customer demo on Thursday.
>
> Kabir is on a flight to Singapore until tomorrow evening and his laptop is with him. I have never had the branch checked out.

Tanvi:

> I tidied up the branch list before stand-up, merged branches only. The script and its output are in the channel. It deleted one branch, and that one was merged: its pull request was merged yesterday with a merge commit, I checked. So it cannot have been my script.

You: you fetched yesterday evening, as you do before going home. You have not fetched since.

## What you are asked for

1. Establish what the server had on that branch when it was deleted, and which copies of it exist now, in which repository, at which commit.
2. Explain why a branch that was "merged" could still hold work that is not in `main`. Test the explanation; do not stop at a plausible story.
3. Restore the branch on the server at the right commit and reopen the pull request (`../pr reopen <number>`).
4. Say what Kabir has to do when he lands, and what Tanvi's script must do differently.

## Rules for this stage

- `kabir/` is switched off and on a plane. Do not use it in this stage, not even to read.
- A bare repository keeps no reflog unless it is configured to. Check before you count on one.
- Before you run any command that removes refs from your own clone, ask what that clone is currently the only holder of.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md). In the recovery, name the GitHub feature that does on GitHub what you did by hand here, and its limits.

## Check

```bash
capstone/stage-06-deleted-branch/check.sh
```

When it passes, apply the next stage with `capstone/stage-07-broken-pull-request/inject.sh`.

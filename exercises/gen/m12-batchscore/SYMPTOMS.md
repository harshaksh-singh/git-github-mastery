# Exercise 12.9: what was reported

**Project:** `batchscore`. **Sandbox:** `server.git` (the server), `you/` (your clone), `ravi/` (Ravi's clone, where you are asked to help). Generate it with `exercises/gen/m12-batchscore/generate.sh`.

Ravi, in a direct message:

> Something is wrong with my branch `feature/retry-budget`. It had three commits from last week. Now `git log` on it shows `main` and the one commit I made this morning, nothing else. The files from last week are not in the working tree either.
>
> I did not reset anything, I did not rebase, I did not delete the branch. All I did this morning was update `main` and switch back to my branch. The branch was never pushed. `git reflog` shows a pull and two checkouts, which is what I did.

What you are asked for: leave `feature/retry-budget` in Ravi's clone as it would look if the accident had not happened and he had then brought it up to date: his three commits from last week in their final form, then this morning's commit, on top of the current `main` of the server. Tell him which command did it, and where Git recorded it.

When you think you are done, run `exercises/gen/m12-batchscore/check.sh` from the course root.

# Exercise 4.9: what was reported

**Project:** `model-gateway`. **Sandbox:** `server.git` (the server; it refuses direct pushes to `main`, the part a GitHub ruleset plays in real life) and `you/` (your clone).

You, on Tuesday afternoon:

> The rate limiter is finished: three commits, tests green. `git push` answers with "main is protected: push a feature/<name> branch and open a pull request" and rejects the push. I was sure I had been on a feature branch all week.
>
> I also have a half-written edit in `gateway/limits.py` that is not committed yet. I do not want to lose it and it is not ready to be committed.

Ravi, who shares the review queue with you:

> While you are at it: your clone still lists branches from last quarter. Delete what is already in `main` on the server and keep what is not.

What you are asked for: the three commits must end up on a branch named `feature/rate-limit`, unchanged (the same commit IDs), and that branch must be on the server. Your local `main` must again be the commit that `main` has on the server. The uncommitted edit must still be in the working tree, uncommitted. Local branches whose commits are all in the server's `main` must be gone; a branch with work that exists nowhere else must stay.

When you think you are done, run `exercises/gen/m04-wrong-branch/check.sh` from the course root.

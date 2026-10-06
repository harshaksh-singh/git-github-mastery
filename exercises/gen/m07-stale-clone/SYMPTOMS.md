# Exercise 7.9: what was reported

**Project:** `embed-cache`. **Sandbox:** `server.git` (the server), `you/` (your clone, back from a week of leave), `asha/` (Asha's clone).

You, on your first morning back:

> Three things do not add up in my clone.
>
> 1. On `main` I committed the 24-hour TTL. `git status` had told me I was up to date before I started, and now `git push` is rejected.
> 2. On `feature/tokenizer`, `git status` says my branch is ahead of `origin/main` by three commits, which is not the branch I would compare it with. A plain `git push` there ends with a `fatal:` about the upstream branch, and `git pull` offers to bring all of `main` into my feature branch. Two of the three commits are on the server already, I pushed them before my leave. The third is not.
> 3. Asha says `feature/lru` was merged and deleted on the server last week. My `git branch -a` still lists it twice, locally and as `remotes/origin/feature/lru`.

The team keeps `main` linear: no merge commits on `main`, and no forced pushes anywhere.

What you are asked for: bring the clone and the server into agreement. Your TTL commit must be on the server's `main` on top of what is there, without a merge commit. `feature/tokenizer` must follow the branch of the same name on the server and all three of its commits must be there, with their IDs unchanged. Whatever names a branch that no longer exists on the server and whose work is already in `main` must be gone from your clone.

When you think you are done, run `exercises/gen/m07-stale-clone/check.sh` from the course root.

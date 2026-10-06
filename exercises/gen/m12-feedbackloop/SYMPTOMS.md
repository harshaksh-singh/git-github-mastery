# Exercise 12.11: the thread, Thursday afternoon

**Project:** `feedbackloop`. **Sandbox:** `server.git`, `you/` (your clone), `asha/` and `ravi/` (your teammates' clones). Generate it with `exercises/gen/m12-feedbackloop/generate.sh`.

`server.git` plays the hosting service. You may talk to it only the way a client can: `git fetch`, `git push`, `git ls-remote`. You may not run commands inside it, exactly as you could not on a hosted server.

**Ravi.**

> I have lost `feature/dedupe-feedback`, five commits, about three days of work.
>
> The pull request list showed "Dedupe feedback" as merged, so I deleted the branch, locally and on the server. It was Asha's old pull request with nearly the same title. Mine was never merged.
>
> It gets worse. My disk was almost full, and right after deleting I ran the cleanup from a blog post: `git reflog expire --expire=now --all` and `git gc --prune=now`. I know what that means now. `git reflog` is empty and `git fsck --lost-found` prints nothing.
>
> I pushed the branch once, early, with the first two commits I think. Everything after that existed only on my laptop.

**Asha.**

> I fetched his branch last week to read it, so I should have all of it. On Wednesday he also mailed me a patch for a quick look. I saved it in `inbox/` in my clone and never applied it.

**The platform team.**

> The server keeps no reflog. Once a branch is deleted there, we cannot give it back.

**You** fetched from the server on Wednesday morning to review something else, and you have not fetched since.

Not every statement above is accurate, and nobody is lying. Establish what each repository really holds before you change anything, and think about what each command you are about to run will change in the repository where you run it.

What you are asked for:

1. Recover as much of the branch as exists anywhere, as the original commits wherever the original objects still exist.
2. Leave `feature/dedupe-feedback` in Ravi's clone complete and in order, and push it to the server again.
3. Tell Ravi exactly what was recovered from where, what could not be recovered in its original form and why, and which two of his statements were wrong.

When you think you are done, run `exercises/gen/m12-feedbackloop/check.sh` from the course root.

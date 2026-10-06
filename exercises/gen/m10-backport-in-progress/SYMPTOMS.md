# Exercise 10.9: what was reported

**Project:** `vocab-service`. `release/3.2` is the maintained release line. **Sandbox:** one repository, `vocab-service/`, exactly as Ravi left it.

Ravi, in a hand-over note:

> The security review wants the three "Security:" commits of `main` in the 3.2 line by tonight. I started the backport on `release/3.2`, all three in one command and with the option that records where each one came from, as the release checklist demands. It stopped at a conflict and I ran out of time. I did not resolve or abort anything.
>
> Two things to keep in mind. Nothing else from `main` goes into 3.2: no streaming, no batch endpoint. And the 3.2 line has a lower input limit than `main` on purpose (some customers run it on small machines): that limit stays.

What you are asked for: finish the backport that is in progress. `release/3.2` must end with the three security fixes, in the order `main` has them, each recording the commit of `main` it was copied from; the release-only input limit must survive; no feature of `main` may arrive.

When you think you are done, run `exercises/gen/m10-backport-in-progress/check.sh` from the course root.

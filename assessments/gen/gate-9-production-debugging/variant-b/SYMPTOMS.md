# Gate 9, hands-on, variant B: the incident channel, Monday 09:15

**Project:** `cart-svc`. **Sandbox:** `server.git` (the server, the part GitHub plays), `you/` (your clone) and `ravi/` (Ravi's clone). You may read every clone. You change the server only by pushing from `you/`. A forced push to `main` or to a release branch is not available to you, and existing tags must not move.

**Context.** `v3.1.0` was tagged on `main` and deployed on Friday. Before that, production ran `v3.0.1`.

**Support, 08:40.**

> Since Friday, a cart line with a negative quantity (a return entered at the till) reduces the cart total. That is the bug we had three weeks ago. It was fixed then. Customers are being undercharged right now.

**The on-call engineer, 08:55.**

> Friday's release bumped `pricing-lib` from 4.1 to 4.2. That is the only pricing change in 3.1. I have a revert of the bump ready on the local branch `oncall/revert-pricing-lib` in the shared clone. Say the word and I push it to `main` and we tag 3.1.1 from there.

**Ravi, 09:05.**

> It cannot be my fix, my fix is in. `git log --all --oneline --grep 'Clamp negative'` shows it twice: once on the release branch, where I made it, and once ported to `main`. I ported it the same day and opened the pull request.

**The incident commander, 09:12, to you.**

> Two people are sure and they disagree. Find out which commit production is missing, if any, and prove it with ancestry, not with a search by title. Then I want production repaired with the smallest possible release: 3.1.0 plus the one fix, nothing else from `main`, as `v3.1.1`. And `main` must not ship this bug a third time. No forced pushes, no moved tags. Four lines for the CTO when you are done.

## The end state you are asked for

1. The server has a branch `release/3.1` that starts at `v3.1.0` and has exactly one more commit: the fix, in a commit that names the commit of 3.0.1 it was copied from.
2. An annotated tag `v3.1.1` on the tip of `release/3.1` is on the server.
3. `main` on the server contains the fix, was extended and not rewritten, and has lost nothing that 3.1 added.
4. The tags `v3.0.1` and `v3.1.0` have not moved. `git status` in `you/` is clean.

## What you hand in with the repository

- Your command log, with the read-only phase, the preservation step and the change phase marked.
- A verdict on the on-call engineer's and on Ravi's statement, each with the command that decides it, and an explanation of what Ravi's search did and did not show.
- The root cause in the form of the root-cause box of Chapter 1, section 1.10, with the layer named.
- The four-part summary for the CTO (Chapter 30, section 30.15) and the severity with its reason.
- One control, with its strength according to Chapter 30, section 30.20, that would have caught this before the 3.1.0 tag was pushed.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-9-production-debugging/variant-b/check.sh
```

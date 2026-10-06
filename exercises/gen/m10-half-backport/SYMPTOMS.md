# Exercise 10.10: what was reported

**Project:** `prompt-router`. Customers on the 2.x line get releases from `release/2.x`; `main` is the next major version. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

Support, forwarding a customer on 2.3.1:

> A prompt of exactly 8192 tokens is still sent to the small model and fails there. The changelog of 2.3.1 says ROUTE-231 is fixed. The same request works on a build of `main`.

Asha, who owns the ticket:

> The ticket names the fixing commit, "Fix model selection for prompts over the context window". I ran `git branch -r --contains` on that commit and the only branches it lists are `origin/HEAD` and `origin/main`. So the fix never reached `release/2.x`, the changelog of 2.3.1 is wrong, and the backport was skipped.

Ravi, who cut 2.3.1:

> The backport was not skipped. I cherry-picked the fix into `release/2.x` the day the ticket was closed, and `git log origin/release/2.x --grep=ROUTE-231` finds it. The release has the fix. The customer must be running an older build.

Both of them ran the commands they quote, and both outputs are what they say.

What you are asked for: say what each of the two commands really proves; establish exactly which changes that `main` made to the routing code are in `release/2.x` and which are not; get the 2.x line to route the customer's prompt correctly, recording where the change came from, and push it. Nothing else from `main` may go into the release line.

When you think you are done, run `exercises/gen/m10-half-backport/check.sh` from the course root.

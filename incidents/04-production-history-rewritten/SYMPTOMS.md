# Incident 4: what was reported

**Project:** `billing-api`. The branch `production` is what runs; every deployment is tagged `deploy-<date>`. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

The release job, in the alerts channel:

> Deployment of `production` refused: the commit currently running in production (tag `deploy-2026-09-07`) is not an ancestor of the branch tip. Refusing to compute a change list. No deployment was made.

Asha, a few minutes later:

> That is odd, I shipped the PDF footer to `production` an hour ago and it went in without complaints. Before that `git pull` told me my `production` had "diverged", which made no sense because I had no local commits. Ravi said to reset to the server, so I did, and then everything worked.

Ravi:

> I did tidy up the commit history on `production` this morning, it had a lot of tiny commits. But that was only cosmetic. Same code, fewer commits. I checked that the tests pass.

The finance team has also opened a ticket: a staging build made from the tip of `production` shows tax amounts with more than two decimals. Nobody has connected the ticket to anything yet.

What you are asked for: establish exactly what changed on `production`, restore a history that the deployment record can trust without losing work that was shipped since, bring every clone back in line, and say what would have stopped this.

When you think you are done, run `incidents/04-production-history-rewritten/check.sh` from the course root.

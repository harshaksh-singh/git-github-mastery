# Incident 2: what was reported

**Project:** `ingest-pipeline`. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

Ravi, in the team channel:

> Is `main` broken for anyone else? The nightly ingest job failed its tests, and when I look at `main` on the server the top commit says "WIP ... tests still red". My fix from this morning (rows without a timestamp) is not in the log any more. I definitely merged it, the pull request says merged.

Asha, two minutes later:

> That WIP commit is mine but I never touched `main`. I was on my own branch the whole time. I cleaned up my last commit and pushed my branch, that is all. It did say something about a forced update, which is normal after an amend. Somebody must have merged my branch by mistake.

Your own clone, as far as you can tell, looks fine: `git status` says you are up to date.

What you are asked for: find out what happened to `main` on the server, put it right without losing anybody's work (Asha's included), make sure it cannot happen the same way tomorrow, and tell the team what to do with their clones.

When you think you are done, run `incidents/02-force-push-wrong-branch/check.sh` from the course root.

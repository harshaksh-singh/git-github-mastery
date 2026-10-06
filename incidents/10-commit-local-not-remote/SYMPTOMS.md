# Incident 10: what was reported

**Project:** `eval-dashboard`. **Sandbox:** `server.git` (the team repository), `you/`, `asha/`, `ravi/`, and one more bare repository that you will come across.

Asha, who cuts the release:

> The NaN fix is not in the release candidate. Ravi says it is done and pushed, but I cannot find the commit in the repository: it is not in the commit list of `main` and the release job built without it. The nightly evaluation report still shows NaN for two runs.

Ravi:

> It is pushed. I am looking at it: `git log` shows "Guard against NaN in score aggregation" at the top, `git status` says my branch is up to date with `origin/main`, and the push printed `main -> main` with no error. If it is not on GitHub then GitHub has a caching problem. Try a hard refresh.

What you are asked for: find where the commit is and where it is not, explain why every command Ravi quoted is telling the truth, get the fix onto `main` of the team repository without disturbing the commit that landed there in the meantime, and leave Ravi's clone configured so that his next push goes where he believes it goes.

When you think you are done, run `incidents/10-commit-local-not-remote/check.sh` from the course root.

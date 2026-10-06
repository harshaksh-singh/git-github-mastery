# Incident 8: what was reported

**Project:** `prompt-registry`. **Sandbox:** `server.git` (the server), `you/`, `asha/` (where you are asked to help), `ravi/`.

Asha, first thing in the morning:

> My branch `feature/prompt-versioning` has disappeared. It is not in the branch list on GitHub and `git branch -a` on my laptop does not show it either. A week of work was on it. I looked at `git log` on `main` and none of my commits are there, I searched for the commit messages. Nobody on the team says they deleted anything.
>
> The part I need today is the variable validation, that was the last thing I committed, yesterday evening. I always push before I go home, so it should be on the server somewhere. Can GitHub Support restore a branch?

Ravi, when asked:

> I merged Asha's pull request yesterday afternoon with the green button, as usual. I did not delete anything.

What you are asked for: establish what happened to the branch on the server and in Asha's clone, say precisely which work is safe and where, recover what is recoverable, and publish the validation work as the branch `feature/prompt-validation` so that a new pull request for it shows that change and nothing else.

When you think you are done, run `incidents/08-branch-disappeared/check.sh` from the course root.

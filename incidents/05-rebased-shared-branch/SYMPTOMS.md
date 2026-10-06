# Incident 5: what was reported

**Project:** `feature-store`. The branch `feature/online-serving` is shared by you and Asha and has an open pull request into `main`. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

Asha, in the pull request and then in the channel:

> Who undid my rebase? Yesterday the pull request could not be merged cleanly because `main` had moved, so I rebased `feature/online-serving` onto `main` and pushed it with `--force-with-lease`, exactly as the handbook says. It showed three clean commits on top of `main`. This morning the pull request lists nine or ten commits. Every one of mine is in there twice and there is a merge commit from "the server into feature/online-serving" that I did not make. The reviewers are asking what they are supposed to review.

Ravi, who reviews the pull request:

> The "Files changed" tab looks the same as yesterday as far as I can tell, so maybe it is only a display problem on GitHub? I would wait for it to refresh.

You: yesterday evening you ran `git pull` on the branch, it finished without an error, and you pushed your two new commits. Nothing looked unusual.

What you are asked for: explain why the commits appear twice, produce a branch that contains every change exactly once on top of the current `main`, publish it without undoing anybody's work, and tell Asha what she has to do in her clone.

When you think you are done, run `incidents/05-rebased-shared-branch/check.sh` from the course root.

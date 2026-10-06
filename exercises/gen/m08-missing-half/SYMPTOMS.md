# Exercise 8.10: what was reported

**Project:** `evalflow`. `main` is deployed every night. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

The nightly evaluation, in the alerts channel:

> `ModuleNotFoundError: No module named 'runner.batch'`. The batch evaluation announced in `docs/batch-eval.md` cannot start.

Asha, who wrote the feature:

> Pull request #47 was merged yesterday, without a single conflict, and the checks were green. `git branch -r --merged origin/main` lists my branch, so Git itself says it is merged. But `runner/batch.py` and `runner/parallel.py` are not in `main`. They are on my branch, I am looking at them. Only my two newest commits arrived. Git lost half of my branch in a clean merge. Has the repository been damaged? Should I open a new pull request with the same branch?

Ravi, who pressed the merge button both times:

> I merged #41 three weeks ago and #47 yesterday, both with the button, no manual steps, no conflict resolution on my side. In between I fixed a flaky nightly once, that is all I ever committed to `main` myself. If something was resolved wrongly, it was not by hand.

You have already searched: no commit on `main` has "Revert" in its title.

What you are asked for: find the commit that removed the two files and prove what it is; explain why the second merge was clean, why it brought only two commits, and why merging the branch a third time would change nothing; then get the whole feature into `main` on the server. `main` is deployed and shared: its existing commits must stay.

When you think you are done, run `exercises/gen/m08-missing-half/check.sh` from the course root.

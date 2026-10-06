# Incident 9: what was reported

**Project:** `rate-limiter`. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

Asha, after the second overload in a week:

> The API fell over again last night with the same pattern as last week: buckets growing without limit. I fixed exactly that last week, two commits, reviewed and merged: a cap at `BURST` and a lower default rate. I looked at `limiter/bucket.py` on `main` a minute ago and neither change is in the file. But `git log main` shows both of my commits, nobody reverted them, there is no revert commit anywhere. And when I run `git log -- limiter/bucket.py` my commits are not even listed. Is the repository corrupt? Did GitHub lose part of a merge?

Ravi:

> I did have a conflict in that file when I brought `main` into my per-tenant branch before the pull request. I resolved it in the terminal and kept ours, meaning the version our team has, and the tests on my branch were green. The pull request was approved and merged normally.

What you are asked for: show where the two changes went and why no command Asha tried could see it, restore them on `main` without rewriting the history of `main`, keep Ravi's per-tenant feature working, and name the control that would have caught this before the merge. In the sandbox there is no review step: prepare the fix on a branch, then land it on `main` on the server.

When you think you are done, run `incidents/09-misunderstood-conflict/check.sh` from the course root.

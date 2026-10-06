# Exercise 9.10: what was reported

**Project:** `moderation-api`. The branch `feat/abuse-filter` is Ravi's; it has an open pull request into `main` that Asha and you review. It was deployed to staging from the branch this morning. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

The staging smoke test:

> `POST /moderate` with an empty message: HTTP 500, `ZeroDivisionError` in `filters/abuse.py`.

Asha:

> I approved this pull request last week and I remember reading a check for empty messages in it. It is the case the smoke test hit this morning. After Ravi's update on Friday my approval was dismissed, I looked at the description, "Rebased onto main, no functional change", skimmed the diff, and approved again. I cannot find the empty-message check in the pull request now. I have not fetched since last week, so I cannot say more.

Ravi:

> All I did on Friday was rebase the branch onto `main`, because the pull request had become unmergeable, and push it with `--force-with-lease` as the handbook says. A rebase replays every commit, it cannot lose one. There was a conflict in `api/moderate.py`, Git told me how to get past it and I did. If a check is missing now, look at what went into `main` last week: that commit edits the same function.

You fetched this morning and your fetch printed a `(forced update)` line for the branch.

What you are asked for: establish whether a commit was lost, which one, and by which command; say what each of the three people's clones still knows about the old state of the branch; bring the lost change back onto `feat/abuse-filter` on the server so that it works together with what `main` added; and do it without rewriting the branch a second time, because the pull request has review comments attached to its current commits.

When you think you are done, run `exercises/gen/m09-vanished-guard/check.sh` from the course root.

# Exercise 8.9: what was reported

**Project:** `grader`. `main` on the server is deployed automatically. **Sandbox:** `server.git` (the server) and `you/` (your clone).

Asha, who owns the evaluation reports:

> Since Thursday almost every submission passes. The pass mark in `main` is 0.5. Nobody approved that; it has to be 0.7 again today. `main` is deployed and three other people have pulled it, so whatever you do, the commits that are on the server stay on the server.

You, looking at your own clone:

> My last commit is not pushed yet, and it is a mess: it contains the timeout change for `configs/grader.yaml`, which has to ship today, together with my parser experiment in `grader/parser.py`, which is nowhere near ready. I want the timeout change in a commit of its own, titled "Raise the grader timeout to 60 seconds". The experiment must not be in any commit, and I want to keep working on it: it has to stay in my working tree as an uncommitted change.

What you are asked for: `main` on the server must have the pass mark 0.7 and the 60-second timeout, and must still contain every commit it has now. The mixed commit must not exist on any branch. The parser experiment must be an unstaged modification in your working tree and in no commit.

When you think you are done, run `exercises/gen/m08-undo-mix/check.sh` from the course root.

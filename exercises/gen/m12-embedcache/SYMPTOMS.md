# Exercise 12.10: what was reported

**Project:** `embedcache`. **Sandbox:** `server.git` (the server), `you/` (your clone), `asha/` (Asha's clone, where you are asked to help). Generate it with `exercises/gen/m12-embedcache/generate.sh`.

Asha, on a call:

> I was cleaning up `feature/lru-cache` before opening the pull request. I started an interactive rebase and stopped at my first commit, the key builder, to improve it: the key now starts with a version, `KEY_VERSION`. While I was there I also wrote a test file, `tests/test_key.py`, and committed it. Then I let the rebase continue and got a conflict in `embedcache/key.py` that I did not understand, so I aborted to think about it.
>
> Now the test file is gone. The version prefix is gone. `git status` is clean, `git stash list` is empty, `git log` shows my three old commits as if the last hour never happened. The branch was never pushed.

She also tells you what she wants the key to be in the end: the version prefix **and** the lower-cased model name, that is `KEY_VERSION + ":" + model.lower() + ":" + digest(text)`.

What you are asked for: bring the lost hour back and finish what she was doing. `feature/lru-cache` must end up on top of `main` with four commits, each subject once: the key builder in its improved form, the key test, the normalization commit, the LRU commit. Tell her where the work was all along and why `git log` and `git stash list` could not show it.

When you think you are done, run `exercises/gen/m12-embedcache/check.sh` from the course root.

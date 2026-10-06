# Final-test lab "rebase": five commits that should be three

**Sandbox.** `assessments/gen/final-rebase/generate.sh` builds `server.git` and your clone `you/` of the project `citecheck`, and prints the path. Work in `labs/shell "<that path>"`, inside `you`.

**The situation.** Your branch `feature/span-match` has five commits and has never been pushed. Before you open a pull request the history has to be reviewable. `origin/main` has moved since you branched: a colleague's commit was merged, and you have already fetched it.

**The task.** Rewrite `feature/span-match` so that it consists of exactly three commits on top of the current `origin/main`, with these subjects, oldest first:

1. `Add span matcher` (with the later spelling correction folded into it)
2. `Add overlap scoring` (the content of the commit that is now called `wip`, without the debug log)
3. `Add fuzzy threshold`

No commit of the rewritten branch may add, change or delete `debug.log`. The files at the tip must be exactly what the five commits and `origin/main` produce together. Do not push.

**Before you start,** make the rewrite undoable, and after it, prove with one command that the content is what it should be.

**Check.** `assessments/gen/final-rebase/check.sh` from the course root.

**Hand in** with the check result: the todo list as you saved it, and the command you used as proof.

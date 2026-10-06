# Exercise 17.9: what was reported

**Project:** `ingestd`. **Sandbox:** `server.git` (the server, a bare repository next to your clone) and `you/` (your clone). Generate it with `exercises/gen/m17-ingestd/generate.sh`.

Your own notes:

> The laptop's backup tool was copying my home directory file by file when the machine froze. After the restart:
>
> `fatal: not a git repository (or any of the parent directories): .git`
>
> in a directory that has a `.git` directory, with `objects`, `refs`, `logs` and everything else in it.
>
> I was on my feature branch, not on `main`. Two commits on it, the first one pushed. I had an edit to the README that I had not committed. Both branches tracked their counterparts on the server, `../server.git`.

A colleague suggests deleting the directory and cloning again.

What you are asked for:

1. Make the clone a working repository again, without cloning and without losing the unpushed commit or the uncommitted edit.
2. More than one file is damaged, and the first error message is about only one of them. Find all of them: after your repair `git status`, a command that writes the index, `git fetch` and `git branch -vv` must all behave as they did before the freeze.
3. Say for each damaged file where you found the information to rebuild it.

When you think you are done, run `exercises/gen/m17-ingestd/check.sh` from the course root.

# Exercise 12.12: what was reported

**Project:** `tracehub`. **Sandbox:** `server.git` (the server) and `you/` (your clone). Generate it with `exercises/gen/m12-tracehub/generate.sh`. `server.git` is reached only through `git fetch`, `git push` and `git ls-remote`.

Your own notes, written on your phone:

> The laptop lost power while I was committing on `feature/sampling`. The branch has two commits that were never pushed; the second one, "Sample traces by tenant", is the one I was creating when the screen went dark. I do not know whether it was completed. After the restart:

<!-- snippet: ex2/solve-m12-tracehub/01-symptoms -->
```text
$ git status
fatal: .git/index: index file smaller than expected
[exit status: 128]
$ git log --oneline -3
fatal: your current branch appears to be broken
[exit status: 128]
$ git branch -vv
fatal: failed to resolve HEAD as a valid ref
[exit status: 128]
```
<!-- /snippet -->

Advice arrived quickly.

**Ravi.**

> "Your current branch appears to be broken" means the branch is gone. Delete the directory and clone again, it takes ten seconds.

**Asha.**

> Do not clone. Run `git fsck`. Whatever it reports as dangling is the corruption: remove those objects with `git prune`, then `git gc`, and you are fine.

Both pieces of advice destroy something that you need. The evidence is incomplete: three commands failed with three different messages, and nothing says yet how many things are damaged, or whether your last commit exists.

What you are asked for:

1. Before you repair anything, make sure that no repair attempt can make things worse.
2. Find every damaged file, one error message at a time, and repair each from the best source that exists for it: your own repository, your working tree, or the server.
3. End state: `git fsck` exits with status 0 and reports no error, `feature/sampling` has both unpushed commits, the working tree is clean, and this is still the same clone.
4. Write down, for each damaged thing: what it was, where the information to rebuild it came from, and what each of the two pieces of advice would have cost.

When you think you are done, run `exercises/gen/m12-tracehub/check.sh` from the course root.

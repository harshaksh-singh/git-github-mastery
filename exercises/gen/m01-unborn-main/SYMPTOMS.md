# Exercise 1.9: what was reported

**Project:** `chunk-index`. **Sandbox:** one repository, `chunk-index/`.

Ravi, on Monday morning:

> Something is wrong with my `chunk-index` clone. On Friday it had three commits. Today `git log` refuses to print anything and `git status` claims that every file is new, as if I had never committed. The files themselves look fine. I did not delete anything. The only thing I ran on Friday evening was the platform team's branch-renaming script from the wiki, and it stopped with an error halfway, so I assumed it had done nothing.

The team has since decided that the default branch keeps the name `main`.

What you are asked for: find the three commits, explain in terms of objects, refs and HEAD why Git reports "no commits", and repair the repository so that `main` is the current branch and points at Friday's last commit. No new commit may be created and no other branch may be left behind.

When you think you are done, run `exercises/gen/m01-unborn-main/check.sh` from the course root.

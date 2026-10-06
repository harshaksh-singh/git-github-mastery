# Exercise 9.9: what was reported

**Project:** `policy-engine`. **Sandbox:** one repository, `policy-engine/`, in the state in which you left it this morning.

You:

> I did what I do every morning on my branch `feat/pii-redaction`: `git rebase main`. It stopped with a conflict in `rules/pii.py`. I have never edited that file. `git status` says it is on the first of five commits. I wrote two commits on this branch, not five.
>
> The only thing that changed yesterday: Asha's pull request with the PII rules, the one I had built my work on top of, was merged into `main` with "Squash and merge", and her branch was deleted afterwards. A reviewer had asked for one small change in her code before the merge.

What you are asked for: get out of the stopped rebase without losing anything, then put `feat/pii-redaction` on top of the current `main` so that it consists of your two commits and nothing else. Explain why Git wanted to replay five commits and why the first one conflicted.

When you think you are done, run `exercises/gen/m09-stacked-after-squash/check.sh` from the course root.

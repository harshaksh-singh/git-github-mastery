# Exercise 2.9: what was reported

**Project:** `annotator`. **Sandbox:** one repository, `annotator/`. It is Asha's clone and you are sitting at her machine.

Asha:

> I raised the agreement threshold to 0.90 in `configs/eval.yaml` and fixed the crash on an empty vote list in `annotator/agreement.py`. Both edits are on disk, I can see them with `cat`. But `git status` says there is nothing to commit, `git diff` prints nothing, and `git commit -am` refuses with "nothing to commit". The nightly evaluation still runs with 0.8 because nothing I do reaches a commit.
>
> I have not touched `.gitignore`. Is the index corrupt? Should I clone again and copy my files over?
>
> One more thing: `configs/local.yaml` holds the cache path of my own laptop. That one is supposed to stay different on every machine and must not be committed.

What you are asked for: find out why Git does not report the two edits, make Git see them, and commit them. The edit to `configs/local.yaml` must stay on disk and must not be committed. Leave no file in the state that caused the problem, with one exception that you must be able to justify: `configs/local.yaml`.

When you think you are done, run `exercises/gen/m02-invisible-edit/check.sh` from the course root.

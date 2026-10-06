# Exercise 11.10: what was reported

**Project:** `vecindex`. **Sandbox:** one repository, `vecindex/`, with `main`, the maintenance branch `release/2.3` and the tags `v2.3.0`, `v2.3.1`, `v2.4.0`. Generate it with `exercises/gen/m11-vecindex/generate.sh`.

A customer who runs **2.3.1** reports that batch search crashes on small indexes:

> `search_batch` fails with a `ValueError` from NumPy's `argpartition` on every tenant with fewer than ten documents.

Support answered within the hour:

> This is fixed. `git log release/2.3` shows "Clamp top_k to the index size". Please upgrade to the latest 2.3.

The customer replied that they are on the latest 2.3 release and that it still crashes. The 2.3 line is supported; moving the customer to 2.4 is not an option this quarter. NumPy is not installed in the sandbox, so you cannot run the code: this is a question about history, and Git can answer all of it.

What you are asked for:

1. Establish the facts: which commit is the real fix, which branches and which tags contain it, and what the commit with the same subject on `release/2.3` is. Mark the real fix with a lightweight tag named `answer/fix`.
2. Make `release/2.3` carry the complete fix, as a traceable backport, without merging `main` into it and without rewriting what is already on the branch.
3. Publish the result as an annotated tag `v2.3.2` on the release branch. Existing tags stay where they are.

When you think you are done, run `exercises/gen/m11-vecindex/check.sh` from the course root.

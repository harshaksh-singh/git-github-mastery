# Gate 2, hands-on, variant B: what was reported

**Project:** `ingestd`. **Sandbox:** `server.git` (the server), `you/` (your clone), `asha/` (Asha's clone). You work in `you/`. You may read Asha's clone. You talk to `server.git` only the way a client can: `git fetch`, `git push`, `git ls-remote`.

Your own notes, Thursday afternoon:

> 1. `git fetch` ends with an error since this morning: one branch is marked "unable to update local ref". Asha says she pushed a retry fix on a new branch; I cannot see it in `git branch -r`.
> 2. Asha and I share `feature/dedupe-window`. I checked out her branch on Tuesday and have committed twice since. `git push` refuses and talks about not being on a branch. `git branch` does not list `feature/dedupe-window` at all, which I do not understand, because I have been working on it for two days.
> 3. Asha says she pushed one more commit to `feature/dedupe-window` this morning, to the README. My two commits and hers have to end up on the server branch. She has already built on her commit, so it must stay as it is.
> 4. My `main` is behind; I have no work of my own on it.

## The end state you are asked for

1. `git fetch` in your clone works without an error, and your clone shows the server's branches as they are now: nothing that the server has deleted, everything that it has.
2. `HEAD` is on a local branch `feature/dedupe-window` whose upstream is the server branch of the same name.
3. The server's `feature/dedupe-window` equals yours. It contains Asha's commits unchanged, and each of your two commits exactly once.
4. Your `main` equals the server's `main`, and the server's `main` has not moved.
5. `git status` is clean and no operation is in progress.

## Rules

- Before your first state-changing command, give the commits you made on Tuesday a name that survives whatever you do next, and say why they need one.
- No forced push is needed. Using one costs safety points.
- Write the root cause of notes 1 and 2 in the form of the root-cause box of Chapter 1, section 1.10.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-2-branching/variant-b/check.sh
```

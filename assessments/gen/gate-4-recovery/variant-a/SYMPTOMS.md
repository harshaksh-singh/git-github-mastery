# Gate 4, hands-on, variant A: what was reported

**Project:** `modelcard-gen`. **Sandbox:** one repository, `modelcard-gen/`. It is Ravi's clone and you are sitting at his machine. The repository has no remote: nothing in it was ever pushed, and no colleague has a copy.

Ravi:

> I ran a "make Git fast again" snippet from an old wiki page. It deletes local branches and tags that have no counterpart on a server, drops all stashes and expires the reflogs. I did not think about the fact that this repository has no server at all. `git reflog` prints nothing now. `git stash list` prints nothing.
>
> What I need back, in this order:
>
> 1. **The 0.9 release.** A branch `release/0.9` with two commits on top of `main`, and the annotated tag `v0.9.0` on its tip. QA approved that tag. It has to be the same tag, with the original tagger, date and message, not a new tag with the same name: QA's approval is in the tag message.
> 2. **My stash.** I was on `feature/license-section` with a half-done license section in `cards/template.md` and a new file, `notes/eval-plan.md`, that I had never added. I stashed both together. I want them back the way they were before I stashed: uncommitted, on that branch. I rewrote the license section twice that morning; I need the last version, the one with the license URL.
> 3. **An edit to `gen/render.py`.** After stashing I started a rewrite of the renderer, saved the file, decided it was a bad idea and ran `git restore gen/render.py`. Now I think it was a good idea. If you are already recovering things, bring that back too.

## The end state you are asked for

1. `v0.9.0` is the original tag object and `release/0.9` names the commit it tags.
2. `HEAD` is on `feature/license-section`, which has no new commit. `cards/template.md` (the last version) and `notes/eval-plan.md` are in the working tree as uncommitted work.
3. `main` has not moved, and no other path in the working tree differs from `HEAD`.
4. For item 3 of Ravi's list: either the edit is back, or you tell Ravi in two sentences why it is not, in terms of what Git stored and when.

## Rules

- Start with read-only commands. List every candidate object you find and say, with the command that showed it, what each one is, before you create a single ref.
- More objects will turn up than Ravi asked for. For each one you do not restore, say what it is and why it is not wanted.
- State how long the objects you found would have survived if nobody had looked, and what decides it.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-4-recovery/variant-a/check.sh
```

# Gate 9, hands-on, variant A: the incident channel, Thursday 11:40

**Project:** `storefront-api`. **Sandbox:** `server.git` (the server, the part GitHub plays), `you/` (your clone), `asha/` and `ravi/` (your teammates' clones). You may read every clone. You change the server only by pushing from `you/`. A forced push to `release/2.2` or to `main` is not available to you: the ruleset blocks it for everyone, and the incident commander will not lift it.

**Context.** `main` carries unreleased work for 2.3. `release/2.2` is the maintenance line; `v2.2.1` is in production. The release candidate for 2.2.2 was built from `release/2.2` this morning. The 2.2.2 release is due today.

**QA, 11:05.**

> The 2.2.2 release candidate contains the wallet payment code. `checkout/wallet.py` is in the image, and the checkout total calls it. Wallet is a 2.3 feature. It is switched off by a flag, but the code path is there and it changes the signature of `total`. This cannot ship.

**Ravi, 11:12.**

> Then CI built the wrong branch. The job log says it checked out `release/2.2`, but the commit it printed has a parent that is on `main`. A release branch does not have parents on `main`. The runner must have fetched `main` by mistake. Re-run the build.

**Asha, 11:20.**

> I only brought the rounding fix over to the release branch on Tuesday, because 2.2.2 needs it. One commit, "Fix currency rounding for half cents". I did not touch wallet.

**The release manager, 11:31.**

> Simplest fix: reset `release/2.2` to `v2.2.1` and let Asha redo her one commit. Somebody please do that. I have asked for the force-push rule to be lifted for ten minutes.

**The incident commander, 11:38, to you.**

> Nobody resets anything. Find out what is on that branch and how it got there. I want `release/2.2` to contain what 2.2.2 is supposed to contain, everything that people legitimately put on it since `v2.2.1`, and the rounding fix, with a record of where it came from. No forced push. Then I need four lines for the CTO.

## The end state you are asked for

1. `release/2.2` on the server contains: the content of `v2.2.1`; every commit that was legitimately made for 2.2.2 since then; the rounding fix, in a commit that names the commit on `main` it was copied from; and nothing else from `main`.
2. The history of `release/2.2` on the server is extended, not rewritten: its current tip is an ancestor of the new tip. The commit that undoes the damage names what it undoes.
3. `main` and the tags have not moved.
4. Your local `release/2.2` equals the server's. `git status` in `you/` is clean.

## What you hand in with the repository

- Your command log, with the read-only phase, the preservation step and the change phase marked.
- A verdict on each of the four statements above (QA, Ravi, Asha, the release manager): right, wrong, or right about the fact and wrong about the cause, each with the command that decides it.
- The root cause in the form of the root-cause box of Chapter 1, section 1.10, with the layer named.
- The four-part summary for the CTO (Chapter 30, section 30.15) and the severity with its reason.
- One thing that will go wrong weeks from now because of the way this had to be repaired, and what must be written down today to prevent it.
- One control, with its strength according to Chapter 30, section 30.20.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-9-production-debugging/variant-a/check.sh
```

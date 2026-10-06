# Gate 3, hands-on, variant B: what was reported

**Project:** `quota-svc`. **Sandbox:** `server.git` (the server) and `asha/` (Asha's clone). You are sitting at Asha's machine and work in `asha/`.

Asha:

> Release 2.1 needs the three fixes that went into `main` this week: "Fix negative remaining quota", "Fix window rollover at midnight UTC" and "Fix rounding of the quota header". Nothing else. In particular 2.1 must not get the per-tenant burst setting; that is a 2.2 feature.
>
> The three fixes are the first and the last of the four new commits on `main`, plus one in between, so I backported them as a range, from the first fix to the last one, with `-x`. It stopped with a conflict in `quota/window.py`. I looked at `git log` on the release branch while it was stopped and I do not understand what I see: something is there that should not be, and something is missing. I have not touched anything since.
>
> About the conflict: 2.1 keeps its 60 second window. That is the whole point of the 2.1 line. The rollover fix itself is needed.

So `quota/window.py` on the release branch has to read:

```python
WINDOW_S = 60
DAY_S = 86400

def window_start(now):
    return min(now - (now % WINDOW_S), now - (now % DAY_S) + DAY_S - WINDOW_S)
```

## The end state you are asked for

1. No operation is in progress. `HEAD` is on `release/2.1`.
2. `release/2.1` is exactly three commits ahead of `origin/release/2.1`: the three fixes, in the order in which they were made on `main`. Each message names the commit on `main` it was copied from.
3. The burst setting is not on the release branch.
4. `quota/window.py` on the release branch is the file above.
5. Nothing is pushed. `main` is untouched. `git status` is clean.

## Rules

- Before you change anything, show with commands which commits the range selected and which commits Asha wanted, and explain the difference.
- Before you resolve the conflict, write down what stage 1, stage 2 and stage 3 of `quota/window.py` hold in this operation, and which of them is "ours". Check your statement with a command.
- Of the ways out of the stopped operation, say which one you choose and what each of the others would have left behind.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-3-merge-and-rebase/variant-b/check.sh
```

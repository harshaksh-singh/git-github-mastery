# Exercise 11.9: what was reported

**Project:** `judgekit`. **Sandbox:** one repository, `judgekit/`, on `main`. Generate it with `exercises/gen/m11-judgekit/generate.sh` and work in the lab shell it prints.

From the evaluation channel:

> The nightly judge-agreement number is wrong since the 1.1.0 release. On `v1.0.0` the check printed `agreement 0.90`, on `v1.1.0` it prints `agreement 0.70`. The golden set did not change. Nobody remembers touching the scoring.
>
> I tried `git bisect` with `python3 -B check_agreement.py` and it sent me in circles: on some commits the check does not even start.

The check is `python3 -B check_agreement.py`, run from the repository root. It always exits with status 0 when it runs to the end; the number is on standard output.

What you are asked for:

1. Name the one commit that lowered the agreement. Mark it with a lightweight tag named `answer/first-bad`.
2. Put `main` right again with the lowest-risk change, without rewriting any existing commit: the check must print at least `0.90` on `main`.
3. Leave the repository tidy: on `main`, clean working tree, no bisect session open.

When you think you are done, run `exercises/gen/m11-judgekit/check.sh` from the course root.

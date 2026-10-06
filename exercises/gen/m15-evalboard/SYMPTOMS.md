# Exercise 15.9: what was reported

**Project:** `evalboard`, which uses the library `metrickit` as a submodule at `vendor/metrickit`. **Sandbox:** `remotes/evalboard.git` and `remotes/metrickit.git` (the server side) and `you/` (your clone, on `main`, pushed). Generate it with `exercises/gen/m15-evalboard/generate.sh`.

The remotes are local paths. Every command that makes Git clone or fetch a submodule therefore needs `-c protocol.file.allow=always` in this sandbox (Chapter 23, section 23.4 explains why).

From the build channel:

> The 0.5.0 build fails on the build machine, which makes a fresh recursive clone: Python raises an `ImportError`, because `vendor.metrickit.metrickit` has no `rouge_l`.
>
> On your machine `python3 -B -c 'import board'` works. On Asha's it works. Nobody changed the dashboard code since the ROUGE-L column was added, and nobody remembers touching the library.

You have seen one line in your own `git status` for a few days and have been ignoring it.

What you are asked for:

1. Explain why the same commit behaves differently on your machine and on the build machine.
2. Find the commit that caused it and mark it with a lightweight tag named `answer/rollback`.
3. Fix `main` with a new commit and push it. The history on the server is public: no rewriting.
4. Leave your own clone consistent (the submodule checked out at what `main` records), and set the one configuration value in your clone that keeps the submodule's working tree in step with the superproject from now on.

When you think you are done, run `exercises/gen/m15-evalboard/check.sh` from the course root.

# Exercise 13.9: what was reported

**Project:** `modelcard`. **Sandbox:** `server.git` (the server), `you/` (your clone), `ci/` (the build machine's clone, made this morning). Generate it with `exercises/gen/m13-modelcard/generate.sh`. As in every exercise, `server.git` is reached only through `git fetch`, `git push` and `git ls-remote`.

From the release channel:

> The 1.4.0 package that we shipped on Monday and the 1.4.0 package that the build machine produced this morning have different checksums. Same tag, different bytes.
>
> Also, this morning's build does not stamp itself as 1.4.0 at all. `scripts/version.sh` on the build machine prints something that starts with `v1.3.0`. On Monday it printed `v1.4.0`.
>
> `git tag` lists `v1.4.0` on every machine we looked at. The release checklist says that Asha tagged 1.4.0 on Monday, with her sign-off in the tag message. Asha is on leave this week and her laptop is switched off.

What you are asked for:

1. Find out what `v1.4.0` was on Monday and what it is now, on the server, in `you/` and in `ci/`.
2. Put Monday's `v1.4.0` back, as the very object that was published, in all three places.
3. Release the commit that today's `v1.4.0` names as a proper `v1.4.1`, on the server too. Afterwards `scripts/version.sh` in `ci/` must print `v1.4.1`.
4. Say in two sentences what was done to the tag, and name one measure that would have stopped it.

When you think you are done, run `exercises/gen/m13-modelcard/check.sh` from the course root.

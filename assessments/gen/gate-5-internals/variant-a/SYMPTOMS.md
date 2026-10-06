# Gate 5, hands-on, variant A: what was reported

**Project:** `corpus-sync`. **Sandbox:** `server.git` (the server) and `ravi/` (Ravi's clone). You are sitting at Ravi's machine and work in `ravi/`. The server is healthy and you may fetch from it. You may not replace Ravi's clone by a new one: it holds work that exists nowhere else.

Ravi:

> My laptop lost power yesterday in the middle of a `git add`. This morning the repository is a wreck, and I do not know which of these things belong together.
>
> - Almost every command prints "Could not read" followed by an object ID, or "invalid sha1 pointer". `git log` prints an error.
> - `git commit` says it is unable to create a lock file because the file exists.
> - Before the power cut, `git log` in this clone showed only two commits, although the project has more. `git describe` has never worked here. So history was already being eaten before the crash.
>
> Two things I did after the crash, in case they matter: I rebooted, and I ran the disk cleaner that IT installed, the one that removes caches, thumbnails and "index files".
>
> What I must not lose: the commit I made yesterday, "Skip keys that already exist", which is not pushed, and `sync/manifest.py`, which I had just staged. The file is still in my working tree, I checked.

## The end state you are asked for

1. `git fsck` reports nothing and exits with status 0.
2. `main` still has Ravi's unpushed commit on top. `sync/manifest.py` is staged, as it was, and is the only thing `git status` reports.
3. `git log` shows the whole history of the project and `git describe` prints a description based on the release tag.
4. The server is unchanged. Nothing is pushed.

## Rules

- Sort Ravi's observations into separate faults before you repair anything, and for each fault say which file or files under `.git` are involved and whether they hold primary data or derived data.
- Repair in an order you can justify, and say why the order matters.
- One of the things Ravi lists is not damage. Say which one, what it is, and who caused it.
- Do not delete `.git/index` and do not re-clone.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-5-internals/variant-a/check.sh
```

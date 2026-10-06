# Gate 5, hands-on, variant B: what was reported

**Project:** `shardlog`. **Sandbox:** `server.git` (the server) and `asha/` (Asha's clone). You are sitting at Asha's machine and work in `asha/`. You may not replace Asha's clone by a new one: it holds work that exists nowhere else.

**The platform team, Friday.**

> The Git server is being reorganized this weekend. Repositories that had `-old` in their path lose the suffix. Update your remotes on Monday: `shardlog` is at `../server.git` from now on.

**Asha, Monday.**

> I have not got as far as the remote. My clone is broken.
>
> - Every command says "your current branch appears to be broken".
> - Before that started, I wanted to compare the current schema with the one from 1.0.0. `git show v1.0.0:shardlog/schema.py` failed with "does not appear to be a git repository" and "Could not read from remote repository". Why does showing an old version of a file need a remote at all? The tag is there, the commit is there, `git log` listed everything. I think half of my history is missing.
> - My projects folder is inside the directory that the company's file-sync client mirrors. It reported "2 conflicts resolved" for this repository on Saturday.
>
> What I must not lose: the commit I made on Friday, "Add shard id to the writer", which is not pushed, and an edit to `README.md` that I have not staged. I had nothing staged.

## The end state you are asked for

1. `HEAD` is on `main`, and `main` names Asha's unpushed commit.
2. The index is valid and equals `HEAD`. The README edit is in the working tree, unstaged, and is the only thing `git status` reports.
3. `origin` points at the server's new location. The clone is the same kind of clone it was before.
4. `git show v1.0.0:shardlog/schema.py` prints the file, and would print it again with the network unplugged.
5. `git fsck` reports nothing. The server is unchanged. Nothing is pushed.

## Rules

- Sort the observations into separate faults before you repair anything, and for each fault say which file or files under `.git` are involved and whether they hold primary data or derived data.
- Repair in an order you can justify. One wrong order makes Git treat every file of the project as new.
- One of the things Asha lists is not damage. Say which one, what kind of clone this is, and how you can tell.
- Say what a rebuilt index cannot bring back, and why that does not matter in this case.
- Do not re-clone.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-5-internals/variant-b/check.sh
```

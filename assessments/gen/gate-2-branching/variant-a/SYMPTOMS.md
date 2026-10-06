# Gate 2, hands-on, variant A: what was reported

**Project:** `rerank-api`. **Sandbox:** `server.git` (the server), `you/` (your clone), `asha/` (Asha's clone). You work in `you/`. You may read Asha's clone. You talk to `server.git` only the way a client can: `git fetch`, `git push`, `git ls-remote`.

Your own notes, Wednesday morning:

> 1. On `main`, `git status` tells me I am behind `origin/main`. `git merge origin/main` answers "Already up to date." There is a warning above it that I have been ignoring for a week or two. I do not want to create a merge commit on `main`; I have no work of my own there.
> 2. `feature/mmr-rerank` has my two commits. A plain `git push` is refused with a long message about names that do not match. One of the two commands it suggests would push to `main`, which is not what I want: the branch must go to the server under its own name, and from then on plain `git push` and `git pull` on it must work.
> 3. Asha wrote yesterday: "I merged the BM25 work and cleaned up the branches on the server." My `git branch -r` still lists `origin/feature/bm25-tuning` and `origin/spike/colbert`, and I have local branches for both.

Asha, when you ask her about the spike:

> The spike? I ran my delete-merged-branches one-liner. It should only have removed what is in `main`. I do not have the spike locally any more.

## The end state you are asked for

1. In your clone, `origin/main` means one thing: the remote-tracking branch. Your `main` equals `main` on the server, and `main` on the server is exactly where Asha left it.
2. `feature/mmr-rerank` exists on the server with your two commits, and its upstream in your clone is the branch of the same name.
3. Your clone no longer shows branches that the server does not have, unless they are published again as part of this repair.
4. Work that exists nowhere on the server is back on the server under its old name. Work that is in `main` does not get its branch back, and its local branch is removed.
5. `git status` is clean and no operation is in progress.

## Rules

- Before you delete any ref, prove with a command which commits would become unreachable from the remaining refs, and keep the output in your log.
- No forced push and no forced deletion (`-D`, `--force`, `+refspec`) is needed anywhere. Using one costs safety points.
- Write three root causes in the form of the root-cause box of Chapter 1, section 1.10, one per numbered note.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-2-branching/variant-a/check.sh
```

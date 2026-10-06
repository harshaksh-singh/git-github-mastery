# Exercise 11.11: the incident channel, Monday morning

**Project:** `ragbench`. **Sandbox:** `server.git` (the server) and `you/` (your clone, on `main`, in step with the server). Generate it with `exercises/gen/m11-ragbench/generate.sh`. Each deployment is an annotated tag: `deploy-2026-09-04` (healthy) and `deploy-2026-09-11` (the bad one).

**Monitoring.** Since Friday's deployment the answer-quality dashboard shows "no relevant document in context" on roughly three times as many conversations. The vector store, the embedding model and the documents did not change on Friday. The retrieval logs show that the service now asks the vector store for 5 candidates per query; last week it asked for 20.

**On-call notes (Sunday night).**

> Three changes went out on Friday: Asha's constants tuning, Ravi's reranker, Asha's formatter run.
> `git blame ragbench/retrieve.py` puts the `TOP_K` line on Asha's formatter commit. So the formatter commit changed more than formatting.
> `git log -S'TOP_K=5'` lists that same commit and nothing else.
> Proposal: revert the formatter commit first thing Monday.

**Asha.**

> My formatter commit is whitespace only. I checked the diff twice before pushing. And my tuning commit touched `MIN_SCORE` and added `MAX_AGE_DAYS`, nothing else.

**Ravi.**

> The reranker branch never touched `TOP_K`. You can see that in the branch's commits. It keeps the top 5 after reranking, which is a different constant.

Everybody quoted above is telling the truth as they see it. The evidence is incomplete: nobody posted a diff, and the feature branch has been deleted.

What you are asked for:

1. Find the commit that changed the value, and say precisely why blame and the pickaxe search of the on-call notes pointed elsewhere. Mark the commit with a lightweight tag named `answer/culprit`.
2. Decide what to do about the on-call proposal, then put `main` right with the lowest-risk change and push it. Nothing that is deployed and correct may be lost, and no published commit may be rewritten.
3. Prevention inside the repository: after your fix, a plain `git blame` configured the usual way must no longer stop at the formatter commit. Commit the file that makes this possible, under the conventional name.
4. Write four sentences for the channel: root cause, fix, verification, prevention.

When you think you are done, run `exercises/gen/m11-ragbench/check.sh` from the course root.

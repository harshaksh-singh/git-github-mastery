# Stage 3 briefing: a file that should not have been committed

**When:** Wednesday 16 September 2026, 10:40 IST. **Where:** all four clones and the server. You administer `server.git`.

**Start the stage:** `capstone/stage-03-leaked-secret/inject.sh` (needs a passed stage 2), or `capstone/setup.sh --stage 3`.

> The string in this exercise is a dummy made for the course. It unlocks nothing and has the format of no real credential. Treat it as if it were the token of Tessaly's embedding service in the staging environment.

## What you are told

Kabir, in a direct message:

> Small thing. When I started the embedding client this morning, the env file of the staging deployment went into my first commit. I saw it twenty minutes later, deleted the file in a new commit and pushed, so the branch is clean now. It is only on my feature branch and the repository is private. The token is for staging, not production. Pull request #16 is ready for review otherwise.

Tanvi, when you ask who else has touched the branch:

> I started my latency logging on top of his branch this morning, I do not remember whether that was before or after he removed the file. And I rolled his branch out to staging to try it; the deploy script marks what it deployed.

Nandini:

> If the file is gone from the tip, can we not squash-merge #16? A squash makes one new commit without the file, and the old commits never reach `main`.

## What you are asked for

1. Put the necessary actions in order, including the ones that are not Git commands, and say which one comes first and why.
2. Establish the scope: every ref in every repository that reaches the file, since when the server has had it, and whether it is in `main` or in a release.
3. Remove the file from every history that contains it, on the server and in the clones, without losing anybody's work. Kabir's three real changes and Tanvi's change must survive, each once.
4. Remove the objects themselves from the server and from every clone, and say what the equivalent of each step is on GitHub.
5. Answer Nandini's question with evidence.

## Rules for this stage

- No tool outside Git is installed. This history is small enough for Git's own commands.
- You may sit at every clone. Work in a teammate's clone the way you would with that teammate next to you.
- Kabir still needs a local environment file to run his client. It must not be tracked again.

## Hand in

The seven items of [`DELIVERABLES.md`](../DELIVERABLES.md). The message to the CTO states the exposure window with its source, who could read the file, what the credential could reach, and what is not yet verified.

## Check

```bash
capstone/stage-03-leaked-secret/check.sh
```

The check sees Git state only. It cannot see whether the credential was revoked, and that is the step that decides whether the incident is over. When it passes, apply the next stage with `capstone/stage-04-failed-ci/inject.sh`.

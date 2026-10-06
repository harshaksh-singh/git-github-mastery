# Gate 4, hands-on, variant B: what was reported

**Project:** `latency-probe`. **Sandbox:** `server.git` (the server) and `asha/` (Asha's clone). You are sitting at Asha's machine and work in `asha/`. `main` is published and other people have fetched it.

**Monitoring.** The probe waits ten times longer than it should before it reports a timeout. `sh tools/p95.sh`, run in the repository root, prints the effective timeout in milliseconds. On the release tag `v1.0.0` it printed 250. On `main` it prints 2500. The script itself has not changed since it was added, before the tag.

**Ravi, in the channel.**

> The timeout is `TIMEOUT_MS` in `probe/config.py`. `git log -- probe/config.py` lists two commits, a rename and the formatter run, and that is the whole history of the file. A rename changes no line, so it was the formatter. Revert the formatter commit.

**Asha.**

> Two more things while you are at my machine.
>
> Last week Ravi had a spike, `spike/histogram`, two commits, on his laptop only. I fetched it directly from his laptop into a local branch of the same name so that we would have a second copy. I never switched to it. Yesterday I deleted a handful of local branches with `-D` and that one was among them. Ravi's laptop was re-imaged on Monday. `git reflog` shows nothing with "histogram" in it.
>
> And on Monday I lowered the p95 alert threshold in `probe/alerts.py`, saved, then ran `git restore probe/alerts.py` because I wanted to think about it. If the old edit can be found, I would like it back.

## The end state you are asked for

1. A lightweight tag `culprit` names the commit that changed the effective timeout.
2. `main` is exactly one commit ahead of `origin/main`. The commit undoes the culprit in the way that is correct for a published branch, and its message names the commit it undoes. `sh tools/p95.sh` prints 250 again, and nothing else that happened after `v1.0.0` is undone.
3. `spike/histogram` exists again with Ravi's two commits.
4. Nothing is pushed. No operation is in progress. `git status` is clean.
5. For the alert threshold: either it is back, or you tell Asha in two sentences why it is not.

## Rules

- Test Ravi's statement about `probe/config.py` with a command before you accept or reject it, and say what his command did not show and why.
- Find the culprit by a search over behavior, not by reading diffs, and keep the search log.
- For the spike: explain why the reflog has no trace, and name every place in a repository where the ID of a deleted branch can still be found.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-4-recovery/variant-b/check.sh
```

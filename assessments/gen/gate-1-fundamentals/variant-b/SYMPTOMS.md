# Gate 1, hands-on, variant B: what was reported

**Project:** `shardmap`, a library that maps a key to a shard. **Sandbox:** one repository, `shardmap/`. It is Ravi's clone and you are sitting at his machine; the repository's own configuration carries his name and email. The repository has no remote: nothing has been published.

Ravi:

> I have three problems and no idea whether they are one problem.
>
> 1. My commit "Add shard weights" was meant to add `shardmap/weights.py` and nothing else. I had a half-done experiment in `shardmap/hashing.py` that I wanted to keep out of the commit, so I unstaged that file first. Now a fresh checkout of the commit cannot import `shardmap.hashing`. The experiment is not finished: it must stay on my disk and stay uncommitted.
> 2. I made `scripts/rebalance.sh` executable an hour ago. `git status` has nothing to say about it, and on the test host the script is still not executable after a checkout.
> 3. `git log main` prints a warning and then shows a single commit. `git log` without an argument shows all of them. At some point this morning I tried to point `main` back to the first commit and gave up; I thought that command had done nothing, because it printed nothing.

## The end state you are asked for

1. There is exactly one commit called "Add shard weights". Its author is Ravi, its parent is the commit it has now, and it contains `shardmap/weights.py` and `shardmap/hashing.py` as that file was committed before. The three older commits are untouched.
2. The half-done experiment is still in the working tree as an uncommitted, unstaged change.
3. In a later commit, `scripts/rebalance.sh` is recorded as executable.
4. The name `main` means the branch again, without a warning.
5. `HEAD` is on `main`. The experiment is the only thing `git status` reports.

## Rules

- Collect evidence with read-only commands before you change anything.
- For each of the three complaints, write the root cause in the form of the root-cause box of Chapter 1, section 1.10.
- Say for every state-changing command you run which of the working tree, the index, `HEAD` and the branch ref it changes.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-1-fundamentals/variant-b/check.sh
```

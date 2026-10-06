# Module 33 lab answers: AI/ML engineering workflows

> **Baseline.** Git 2.55.0 on macOS. These are answers to the "Questions" of each lab in the [Module 33 lab manual](../lab-manual/m33-ai-ml-workflows.md). Write your own answers first. Commit IDs quoted here are those of the replay scripts in `labs/ch28/`; commits that you made by hand have other IDs. Checksums of data files are the same on every machine.

## Lab 33.1: Build a professional AI project repository from an empty folder

1. **Why the ignore file is the first commit.** Every later step ends with `git add .`, which stages whatever is in the working tree and is not ignored. In step 5 you copied `data/` into the repository, including `data/raw/tickets.csv`; without rule 17 (`/data/**`) that `git add .` would have committed the data set, and it would then be in every clone for the life of the history. In step 7 the same holds for `models/embedder.bin`, and from step 6 on for the `runs/` directory that the evaluation wrote. In this project the hook of step 3 would have refused the `.bin` file as model weights, but not a CSV under 500 kB: the ignore rule is the first line of defence and the hook the second. A rule added afterwards protects only the future, because ignore rules do not affect files that are already tracked.

2. **The notebook one commit earlier.** The blob of that commit would contain the three outputs, including the printed key. Adding the filter in the next commit and running `git add --renormalize` would create a new, clean blob in a new commit. The old blob would stay reachable from the earlier commit, so `git grep sk-demo $(git rev-list HEAD)` would still find it and every clone would still receive it. In this project you would also have needed `--no-verify` to make that commit, because the hook installed in step 3 rejects a staged notebook that has outputs.

3. **What `git diff` compares.** The cleaned form of the working file with the index. Git runs the clean filter on the file before comparing, which is why a rerun shows no change and a changed cell source shows as a one-line diff. For a reviewer it means the pull request contains code changes only. A claim such as "the confusion matrix looks better now" cannot be checked from the diff: the chart was never committed. The evidence has to travel another way (a tracked report file, or a link to the recorded run).

4. **Why neither setting stopped the commit.** `.gitattributes` only names a driver. The driver is defined by `filter.nbstrip.clean` in `.git/config`, and Git never copies configuration from the repository being cloned, so that a clone cannot make your machine run somebody else's command. An attribute that names an undefined filter does nothing. `filter.nbstrip.required` is configuration too: it existed in the first clone and not in `docqa-laptop`, so there was nothing to be required. The hook was absent for the same reason (`core.hooksPath` is configuration).

5. **A problem that `--range` finds and `--tree` does not.** A branch with two commits: the first adds `evals/dump.json` (900 kB) or a private key, the second deletes it. The final snapshot is clean, so `--tree HEAD` passes. The history of the branch contains the file, so `--range` reports the commit that added it. If the branch is merged with a merge commit or by rebase, that commit becomes part of `main`'s history and of every clone. If it is squash-merged, the squashed commit does not contain the file, and the original commits remain on the server, reachable through the pull request's ref ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.2).

6. **If the commit had been pushed.** In this order. (a) Treat the key as compromised from the moment of the push: revoke or rotate it at the provider. That alone may be the whole remediation. (b) Establish what the key could reach and whether it was used: provider logs, spend. (c) Find out where the commit went: other clones, forks, CI logs and caches, open pull requests. (d) Only then decide whether to rewrite history. On a shared branch that means coordination with everyone who has the commits, a bypass of the rule that blocks force pushes, and the knowledge that GitHub can keep serving the old commit by ID and through pull request refs until Support removes it. (e) Fix the cause: make `ci/check.sh` a required check, enable push protection, and give new clones a setup script. An amend followed by a force push, without (a), repairs the history and leaves the incident open. Chapter 21B has the full procedure.

7. **Code owners.** The files whose change can silently switch a control off: `.gitignore` and `.gitattributes` (commit 1), `tools/checks.py`, `hooks/` and `ci/` (commit 3), `tools/nbstrip.py` (commit 4), `tools/dataref.py` and the `*.ref` pointers (commits 5 and 7), `requirements.lock` (commit 2) and the `Dockerfile` (commit 7). A pull request that deletes one line of `.gitattributes` disables output stripping for everybody; one that edits a pointer swaps the data set or the weights with a diff of two lines. Those are the changes that deserve a named reviewer. On GitHub add `.github/workflows/` and `CODEOWNERS` itself.

## Lab 33.2: Version a dataset by reference

1. **An empty `git status` after the data changed.** Neither a defect of Git nor of the rule. Git reports on tracked files and on untracked files that are not ignored; the CSV is ignored on purpose. If you un-ignored it, the next `git add .` would commit the data: its bytes would enter history permanently, be copied to every clone, and sooner or later hit the platform's size limits, and you would lose the ability to delete a version. The gap is real and is closed outside Git: `dataref.py verify` compares the file with the pointer, and section 28.6 of the chapter calls that disagreement the central weakness of the pattern.

2. **Checksum and size.** The SHA-256 identifies the data: it is computed from the content, so the same hash means the same bytes and a different hash means different bytes. The size is a convenience: a cheap first check, and a way to know how much you are about to download without downloading it (Git LFS pointers carry it for the same reason). A file name or a date is a label that somebody assigned and can assign again to different content. Only an identifier derived from the content cannot be reused for other content.

3. **Two commands or one.** Git LFS registers a smudge filter. On checkout Git pipes the pointer through it, and the filter writes the real content into the working tree, so the one `git switch` does both steps. `dataref.py`, like DVC, leaves Git alone and needs a second command. A failure only the filter design has: a clone or CI job without the LFS client gets pointer files where data should be, and a program may read three lines of text as if they were a model. A failure only the two-step design has: you run the first step and forget the second, and the working tree holds a pointer for one version and data from another, which is what you produced on purpose in step 4 before running `checkout`.

4. **Should the tree have been "dirty"?** No. In Git, a dirty tree is one where a tracked file differs from `HEAD` (or the index does). The CSV is not tracked, so `dirty: false` is correct, and making `runinfo.py` call it dirty would blur a precise word. The right change is in `run_eval.py`: before evaluating, compare the checksum of the data file with the pointer next to it, and refuse to run, or at least record `data_matches_pointer: false`, when they differ. The record already contained the evidence (the data checksum); the improvement is to act on it at run time instead of during the post-mortem.

5. **What `checkout` would have destroyed.** The corrected label: the only copy of the edited CSV. The file is not tracked, so there is no blob, no stash and no reflog entry for it, and the `sed` backup file was removed in the same command. It could have been recovered only from outside Git: an editor's local history, or a file-system backup. That is why the lab manual says to choose before running either command, and why `verify` comes first.

6. **What must be true about the bucket.** No lifecycle rule or cleanup job ever deletes an object that some commit's pointer names, which in practice means no expiry at all or an expiry computed from the pointers in the full history. Objects are immutable: a key derived from the hash is written once. The bucket is backed up or replicated, because it now holds the only copy. Whoever reproduces the result in two years, including CI, has read access. The location of the bucket and the layout of keys are recorded in the repository or its documentation. And the reader verifies the hash after download, so that corruption is detected.

7. **The same steps in DVC,** from its documentation, not run here:

   ```bash
   dvc add data/raw/tickets.csv
   git add data/raw/tickets.csv.dvc data/raw/.gitignore
   git commit -m "Version the ticket data set by reference"
   dvc remote add -d store <location>
   dvc push
   # change the data, then:
   dvc add data/raw/tickets.csv
   git commit -am "Add two labelled tickets to the data set"
   dvc push
   # back one version:
   git checkout HEAD~1
   dvc checkout
   # in a fresh clone:
   dvc pull
   ```

   `data/raw/tickets.csv.dvc` corresponds to `tickets.csv.ref`. One difference is visible in the first two lines: DVC writes the ignore entry for you, where this project ignores the whole directory up front.

## Lab 33.3: Reproduce a past result from its recorded identifiers

1. **The fields, and what would have made each differ.**

   | Field | Differs when |
   |---|---|
   | `code.commit` | you ran at another commit |
   | `code.describe` | the same commit is described differently: the tag `v0.1.0` is missing from your clone (a shallow or tagless fetch), so the name falls back to the abbreviated ID |
   | `code.dirty`, `code.changed`, `code.diff_sha256` | a tracked file differs from the commit, for example an edit left in the worktree |
   | `code.untracked` | a stray file that is not ignored |
   | `config_sha256`, `resolved_config` | the configuration read at run time differs; with the same clean commit this cannot happen here, because the configuration is one tracked file |
   | `data.sha256` | the data file is not the version the old pointer names: you skipped `dataref.py checkout`, or the store returned other bytes |
   | `lock_sha256` | the lock file differs, which again needs a dirty tree |
   | `metrics` | any of the above, or non-determinism in the evaluation itself |

   The record is redundant on purpose. With a clean tree, `commit` implies the configuration and lock hashes; they are recorded so that a record can be compared and read without the repository.

2. **A worktree, not `git switch --detach`.** In the main directory, a switch carries uncommitted changes to tracked files along or refuses if they conflict; it leaves the ignored data file as it is, so you would then run `dataref.py checkout` and overwrite today's data with the old version; and a job that is reading files in that directory sees them change under it. A second worktree has its own `HEAD`, index and files, including its own copy of the ignored data, so none of the three happens. The cost is disk space for one more checkout and one more copy of the data.

3. **Hash without patch.** You could still prove that the run was not made from the commit alone, and you could test any candidate change: apply it, hash `git diff HEAD --binary`, compare. You could not reconstruct the change from the hash. The result would be irreproducible in practice, and the honest label for it is "produced from an unrecorded modification of `aa18ad2`".

4. **When the patch would not apply.** `git apply` needs the context lines of each hunk to match the target file. Applied at another commit in which the same region of `configs/eval.json` has changed, it stops with an error; on `main` of this lab the neighbouring keyword line was edited in commit `babb70d`, so the context no longer matches there. It cannot fail in the `repro` worktree, because the patch is `git diff HEAD` taken at exactly the commit that is checked out, and the tree is clean.

5. **A timestamp in the record.** For: an audit asks when a result was produced, and ordering runs needs a time. Against: a timestamp makes every record unique, so two records of the same experiment can no longer be compared with `diff`, which is the property this lab used as proof. Keep both: put the time, the host and the user in the tracker's metadata or in a second file, and keep the file you compare free of anything that is not a function of code, data, environment and configuration.

6. **A run this record cannot reproduce.** One that imported an untracked file: a new module, or a local settings file, that was never added. It is not in `git diff HEAD`, so it is not in `uncommitted.patch`; the record lists its name under `untracked`, which tells you what is missing and does not give you its content. The same holds for ignored files that influence behavior (a `.env`), for environment variables, for an installed environment that did not match the lock file, and for a data version whose object has been deleted from the store.

7. **Identifiers for a model card.** Write: the full ID of the commit that now contains the change (`63dc7f5` in the replay, in full), with `dirty: false`; the SHA-256 of the data set from the pointer (`2226b23c455b...`), the hash of the lock file or the image digest, the configuration hash, and the metric together with the number of examples. Refuse to write: a branch name, a mutable tag or alias, "the latest data", an abbreviated ID as the only identifier, and above all the commit `aa18ad2` alone for the 0.9 result, which names code that produces 0.8.

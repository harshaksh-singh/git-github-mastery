# Final-test lab "recovery": after the cleanup

**Sandbox.** `assessments/gen/final-recovery/generate.sh` builds the repository `chunkstore` and prints its path. Work in `labs/shell "<that path>"`, inside `chunkstore`.

**The situation.** On Friday you "cleaned up" this repository from a list of commands found in a chat thread: the experiment branch `spike/semantic-overlap` was deleted, the one stash entry was dropped, and a last command was supposed to "free space". On Monday the experiment is wanted after all, and so is the configuration edit that was in the stash. `git reflog` is of no help. Nothing was ever pushed.

**The task.**

1. Find out what the last command did, from the state of the repository.
2. Bring back the branch `spike/semantic-overlap` with its three commits, at their original commit IDs.
3. Bring the stashed edit of `config/chunking.yaml` back into the working tree of `main`, as an unstaged modification. Do not commit it.

**The end state that is checked.**

- `spike/semantic-overlap` points at its original last commit.
- `main` has not moved and HEAD is on `main`.
- `git status --short` prints exactly one line: ` M config/chunking.yaml`, and the file has the stashed content.

**Check.** `assessments/gen/final-recovery/check.sh` from the course root.

**Hand in** with the check result: how you told the two lost items apart, and which single further command on Friday would have made this lab unsolvable.

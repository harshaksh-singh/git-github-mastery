# Final-test lab "undo": the commit you fixed after it was published

**Sandbox.** `assessments/gen/final-undo/generate.sh` builds `server.git` and the clones `you/` and `asha/` of the project `routeplan`, and prints the path. Work in `labs/shell "<that path>"`, inside `you`.

**The situation.** An hour ago you pushed "Add a toll penalty" to the shared `main`. Then you noticed a misspelled key in `weights.yaml` and corrected the commit in place. `git push` is rejected. Asha has pushed in the meantime.

**The task.** Get your correction onto the shared `main`.

- No force push. Every commit that is on the server now keeps its ID.
- The server's `main` gains exactly one new commit, on top of what is there. That commit contains your correction and nothing else.
- Asha's change is intact.

**Before you repair anything,** establish with read-only commands what your clone and the server each hold, and state the one-line difference that has to be published.

**The end state that is checked.**

- The parent of the server's `main` is Asha's commit.
- `weights.yaml` on the server has the corrected key and Asha's line; the new commit changes no other file.
- Your `main` and your `origin/main` equal the server's `main`, and your clone is clean.

**Check.** `assessments/gen/final-undo/check.sh` from the course root.

**Hand in** with the check result: why `git pull` followed by `git push` was not the fix you chose (or why it was), and which shortcut would have deleted Asha's line.

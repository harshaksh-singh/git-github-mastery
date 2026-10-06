# Module 14 lab answers: hooks, rerere, attributes, stash anatomy

Answers to the "Questions" of Labs 14.2 to 14.6 in [the Module 14 lab manual](../lab-manual/m14-hooks-rerere-attributes.md). Write your own answers before you read these. Lab 14.1 (worktrees) has its own answer file.

## Lab 14.2: A commit-msg hook

1. The hook reads the file whose name is its first argument, `.git/COMMIT_EDITMSG` for an ordinary commit and `.git/MERGE_MSG` for a merge. Git writes it: from `-m`, from the editor, or generated. The hook may edit the file in place, and Git then uses the edited text as the commit message. That is how hooks append ticket numbers or trailers.

2. `git commit -a` does not stage into the real index first. It builds a temporary index that contains the tracked modifications, runs the hooks, and makes that index the real one only if the commit succeeds. The hook refused, the temporary index was discarded, and the real index still had the old `metrics.py`. So the change is an unstaged modification: ` M`.

3. It tells you that the hook does not see every commit. On Git 2.55, `git revert`, `git cherry-pick` and the commits a rebase replays are made without `pre-commit` and `commit-msg`. Add `--no-verify`, clones without the hook, and commits created on the hosting service, and the honest statement is: "the hook checks commits made with `git commit` and `git merge` in clones that installed it". A policy for `main` needs a check where commits arrive: a server-side rule or a required CI job that inspects the subjects of a pull request.

4. The merge had been carried out: the index and the working tree held the merged content (`f1.py` staged), `.git/MERGE_HEAD` and `.git/MERGE_MSG` existed, and HEAD had not moved. No commit was made. Three exits: `git merge --abort` (back to the state before the merge), `git commit --no-edit --no-verify` (conclude it and skip the hook once), or fix the hook and run `git commit --no-edit`, which is what the lab does.

5. None. Hooks are not cloned, so their clone has only the sample files. Two ways to change that: track the hook in the repository and have each clone run `git config set core.hooksPath <dir>` once (cost: every pull can change what runs on the teammate's machine, so the directory must be reviewed like CI configuration, and the one-time step is still voluntary); or use a hook manager such as the pre-commit framework (cost: a tool to install, third-party hook code, and again a step per clone). Neither enforces anything; both make the convenient path the common one.

## Lab 14.3: A pre-push guard

1. One line with four fields: `refs/heads/main <ID of your main> refs/heads/main <ID of origin/main>`. In the book's sandbox the second field starts with `6378124` (the WIP commit at the tip of `main` after the fast-forward) and the fourth with `2a5508c` (what the server had). The hook's arguments, separately, were `origin` and the URL of the remote.

2. The hook looks at a line only when its remote ref is `refs/heads/main`. In step 2 the remote ref was `refs/heads/feature/limits`, so the line was skipped. The commit was the same; the destination differed. The rule is about what reaches `main`, not about which commits exist.

3. The remote commit must exist in your clone, because `git merge-base --is-ancestor` reads both commits from your object database. If someone else has pushed commits you have not fetched, the remote ID on standard input names an object you do not have: `git merge-base` prints `fatal: Not a valid commit name <id>`, the `elif` branch is not taken, and the hook reports a rewrite (tried on Git 2.55.0). Git would have rejected that push anyway with `(fetch first)`, so the verdict is right and the message is misleading. A more careful hook checks `git cat-file -e "$remote_oid^{commit}"` first and says "fetch first".

4. `pre-push` gets, per ref: local ref, local ID, remote ref, remote ID, plus the remote's name and URL as arguments, because the client is talking to one of possibly several remotes and has local names that differ from remote ones. `pre-receive` gets, per ref: old ID, new ID, ref name. The server is the remote; it needs no name for itself, and it has only one name per ref. Its output is sent to the client over the sideband channel of the connection, and the client prints each line with `remote:` in front so that you can tell which side is speaking.

5. For: it gives the same answer earlier and cheaper. The refusal comes before objects are uploaded, and with a message that can point to local remedies. Against: it is a second copy of a rule, and two copies drift. If you keep it, generate both from one script.

## Lab 14.4: A clean and smudge filter

1. `tools/ptr-clean` computed it, with `shasum -a 256`. Git started the program, during `git add`, because the path has `filter=ptr` and `filter.ptr.clean` is defined; it ran at the top of the working tree with the file content on standard input. The script moved the real bytes to `../ptr-store/<hash>` and printed the pointer line, and Git stored that line as the blob.

2. `git diff` compares the index with the cleaned form of the working file. Both are pointers. The numbers are in the store, where Git does not look. To see a content diff you would add a `textconv` diff driver that resolves the pointer.

3. `git check-attr` reads `.gitattributes`, which is a tracked file and arrived with the clone. `git config get` reads configuration, which did not. Git did not warn because the manual defines a filter without a definition as a no-op: that is correct behavior for convenience filters, where the project must remain usable without the driver. `filter.ptr.required` would turn failures into errors, and it is itself a configuration value that her clone lacks.

4. Defining the filter changed what "modified" means in her clone. Her working file held real weights, which now clean to a pointer; her index still held the raw blob from her own commit. Pointer and raw blob differ, so the file counts as locally modified, and the incoming commit changes that same file. Git refuses to overwrite local changes in a merge, fast-forward included. After `git add --renormalize .` her index held the pointer, identical to the incoming version, and the fast-forward had nothing to overwrite.

5. The clean filter would treat the pointer text as content: put the pointer line into the store and emit a pointer to the pointer. After a clone without the driver (working file is a pointer) followed by defining the driver and `git add --renormalize .`, the repository would hold a pointer whose content is another pointer, and the real bytes would be one level away or lost. Passing pointers through makes the filter idempotent: cleaning cleaned content changes nothing.

6. At least: transfer of the stored bytes between machines (upload on push, download on checkout or on demand), with authentication; a way to install the filter in every clone and to fail loudly when it is missing; locking or integrity checks for the store; pruning of unreferenced content; handling of very large files without reading them into a temporary copy twice; a `process` filter to avoid starting a program per file; and tooling to migrate history. Chapter 22 covers how Git LFS answers these.

## Lab 14.5: Rerere, resolve once

1. The record for `retrieval.yaml` was kept: it had a `preimage` and a `postimage`, because `git rebase --continue` had recorded your resolution. The record for `scoring.py` was removed: it had only a `preimage`, because you aborted before resolving. `git rebase --abort` runs `git rerere clear`, which discards the records of the operation in progress that have no resolution.

2. From the text of the conflict hunks after normalization: the two competing versions of the conflicting lines, with marker labels removed and the sides sorted. Not from commit IDs, branch names, the path or the rest of the file. It would have been a different conflict if either side's version of those lines had changed, for example if `main` had moved `top_k` to 30, or if a neighboring change had altered which lines fall inside the conflict hunk.

3. The state is the review point: the file holds a resolution that a machine chose, and Git waits for you to confirm it with `git add`. `rerere.autoUpdate=true` removes it by staging the replayed file.

4. At each stop. After the first `Staged 'retrieval.yaml' using previous resolution.` the rebase was waiting: `git diff --cached` (or `git show :retrieval.yaml`, or `cat retrieval.yaml`) showed `top_k: 20`. `git rerere diff` prints nothing at that point, because the path is no longer unmerged, which is one more reason to leave `autoUpdate` off. Running the tests before `--continue` would have caught it too.

5. Because the record is the cause. A corrected commit fixes this branch today. The record still maps that conflict to the wrong answer, so the next rebase or merge that meets the conflict replays the wrong value, and with `autoUpdate` stages it. `forget` deletes the record, and the correct resolution is recorded in its place when you continue.

6. The symptom is `fatal: Unable to create '.../.git/MERGE_RR.lock': File exists.` in the middle of a rebase, when the background `git rerere gc` started by automatic maintenance holds the lock at the moment rerere wants it. Recovery without the setting: the rebase is stopped at a conflict that rerere has not processed, so run `git rerere` by hand (it records the conflict or replays a resolution), then resolve, `git add` and `git rebase --continue` as usual.

## Lab 14.6: Stash anatomy

1. Because a commit is what the rest of Git can work with. As a parent of `W`, the index commit is reachable from `refs/stash`, so it is protected from pruning as long as the entry exists; it can be named (`stash@{0}^2`), diffed, and used as a source for `git restore`; and `git stash apply --index` can merge it like any commit. A bare tree would need special handling in every one of those places. Making it a child of the old HEAD also records what the index was based on.

2. `git diff 'stash@{0}^1' 'stash@{0}^2'` shows what was staged (HEAD against the index commit). `git diff 'stash@{0}^2' 'stash@{0}'` shows what was not staged (the index commit against the working-tree commit).

3. `stash@{0}` is the newest line of `.git/logs/refs/stash`, and its value is the ID in `.git/refs/stash`. After a second push, `refs/stash` holds the new entry and `stash@{1}` is the value before it: the "old value" column of the newest log line, which is the first entry.

4. A plain pop applies the difference between the old HEAD and `W` to the working tree, and `W`'s tree contains staged and unstaged changes alike. It does not read `I` unless `--index` is given, so nothing tells it which part had been staged. Exceptions: files that are new in the stash are added to the index, because an untracked file could not be told apart from an unrelated one, and when the pop stops on a conflict, the cleanly merged paths end up staged because a merge was in progress (Lab 8.6).

5. `--staged` without `--worktree` writes index entries only. The working files, including the unstaged edit in `config.yaml`, are not touched, and untracked files are never touched by `git restore`. The commit `<id>` is unreachable after the drop. It stays in the object database until unreachable objects are pruned: by default objects older than two weeks are removed when maintenance prunes, so you have days, not months. (The lab configuration changes reflog expiry, not this grace period.)

# V018: Reading the index: git ls-files, the two bits that are not an ignore mechanism, the stat cache, and the lock

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 24
- **Prerequisites.** V017
- **Textbook sections.** [Chapter 5: The Index](../../textbook/ch05-index.md), sections 5.11 to 5.18
- **Demo scripts.** `labs/ch05/ls-files-tour.sh`, `labs/ch05/assume-skip.sh`, `labs/ch05/conflict-stages.sh`, `labs/ch05/stat-cache.sh`, `labs/ch05/dirty-check-in-scripts.sh`, `labs/ch05/index-lock-and-rebuild.sh`

## HOOK

**[ON SCREEN]** "Half the team hides local configuration edits with `git update-index --assume-unchanged`."

Your CTO asks: "Half the team hides local configuration edits with `git update-index --assume-unchanged`. Last week a pull was refused on a clean working tree, and then somebody's settings were gone. Why is there no switch for 'ignore my local changes'?" Think about it, and say your answer.

**[PAUSE]**

Because Git has no such feature. The bit that the team uses is a promise that you will not edit the file. It's not a request to overlook edits.

That answer comes from reading the index entry by entry, which is what we do today. The index is Git's list of what goes into the next commit, one entry for each file. An entry has more in it than a path and a blob ID, the ID of the stored content: a stage number, flag bits, and cached data about the file on disk. Each of those fields explains a class of surprises. And the CTO's story, the refusal on a clean tree and the vanished settings? You'll watch both halves happen.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the last video on the index, and it's the one for the person who has to repair things.

We go through one index entry, field by field. `git ls-files`, the scripting view. The two flag bits that people mistake for an ignore mechanism. The stage number, as a short preview of merge conflicts. The cached stat data, which explains a "modified" file that hasn't changed. And the index as a file on disk: its lock, and how to rebuild it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. List index entries, untracked files and ignored files with `git ls-files`.
2. Explain why `--assume-unchanged` and `--skip-worktree` are not ways to ignore local changes.
3. Name the three stages an index entry has during a conflict.
4. Explain a false "modified" from the cached stat data, and repair it.
5. Diagnose a stale `index.lock`, and rebuild a corrupt index.

## CONCEPT

**`git ls-files`.** In one sentence: `git ls-files` is the plumbing view of the index. Plumbing means the low-level commands made for scripts, and porcelain means the everyday commands made for people. It lists entries and, with options, compares them with the working tree, the files on your disk, without the interpretation that `git status` adds. It is 🟢 SAFE.

**[ON SCREEN]** The option table of section 5.11.

No option, or `-c`: every path in the index. `-s`, `--stage`: mode, blob ID, stage number and path of every entry. `-m` and `-d`: tracked paths whose file differs from the entry, where a deleted file counts, and tracked paths whose file is missing.

`-o`, `--others`: paths with no entry. Ignore rules apply only with `--exclude-standard`. `-i`, `--ignored`: with `-o`, untracked paths that an ignore rule matches. With `-c`, tracked paths that one matches. `-v` adds a status tag, and `--error-unmatch`, `--format` and `-z` serve scripts.

**[ANIMATION]** trees: file=config/settings.yaml steps=setup,edit title=A_promise,_not_a_blindfold

**[ANIMATION]** step: setup

**Two bits that are not an ignore mechanism.** In one sentence: `git update-index --assume-unchanged` and `--skip-worktree` each set a flag on an index entry that tells Git not to examine the working-tree file, and neither is a way to keep private edits to a tracked file. Both are 🟡 CAUTION: a flag bit that hides later edits.

Both flags are documented for other jobs. In the picture, think of them as telling Git not to look at the left box.

**[ON SCREEN]** The comparison table of section 5.12.

`--assume-unchanged`: its documented purpose is speed on filesystems with a slow `lstat`, the call that asks the filesystem about a file without reading it. "The user promises not to change the file". Its tag in `git ls-files -v` is a lower-case letter, `h`. `git add` on the path does nothing, silently. A merge that changes the file is refused: local changes would be overwritten. And `git restore` on the path overwrites the edit without warning.

`--skip-worktree`: its documented purpose is sparse checkout, a working tree that holds only part of the project. "Avoid writing the file to the working directory when reasonably possible". Its tag is `S`. `git add` is refused with a sparse-checkout message. A merge that changes the file is refused in the same way. `git restore` is refused: the pathspec matches nothing.

The FAQ answers the underlying wish directly: "How do I ignore changes to a tracked file? Git doesn't provide a way to do this", and the two bits "don't work properly for this purpose and shouldn't be used this way".

Inside `.git`: one bit in one entry of your `.git/index`. No commit, ref or configuration file records it, so no clone has it, and rebuilding the index erases it.

**[ON SCREEN]** "Unverified", as a callout.

The textbook attaches a caveat, and I pass it on as it stands. Do not read "refused" in that table as a guarantee. Git decides whether a flagged file still matches its entry from the stat data cached in the index, size and timestamps, not by reading the file every time. Two exercise authors each saw, once, a merge or pull overwrite a hidden edit that had the same size as the committed file and was made within the same second. The run could not be reproduced on demand, so no transcript is shown. The refusal is a best effort that depends on the cached stat data, which is one more reason not to hide edits behind either bit.

**What works instead.** The arrangement the FAQ recommends: shared defaults in a tracked file, private overrides in an ignored file that no commit on any branch has ever tracked, and an application that reads both.

**[ANIMATION]** merge: three-way main=stage_2 feature=stage_3 base=stage_1 title=One_path,_three_versions captions=off steps=setup,merge-base

**[ANIMATION]** step: merge-base

**Stages.** In one sentence: when a merge can't decide the content of a path, the index holds up to three entries for it, at stages 1, 2 and 3, and resolving the conflict means replacing them with one entry at stage 0. A merge combines two branches, and a conflict is a spot where Git can't combine them alone. From the manual: "During a merge, stage 1 is the common ancestor, stage 2 is the target branch's version (typically the current branch), and stage 3 is the version from the branch which is being merged".

**[ANIMATION]** end

The notation `:<n>:<path>` names the blob at stage n. Take two facts into Part 2. An index with unmerged entries can't be written out as a tree, so `git commit` refuses until every path is back at stage 0. And `git add` doesn't judge a resolution: it stages the file as it is, conflict markers included if you left them in.

**The cached stat data.** In one sentence: each index entry remembers the size and timestamps that the file had when Git last saw it match the entry, so "has this file changed?" normally costs one `lstat` call instead of reading and hashing the file.

Matching data mean "unchanged". A mismatch means "possibly changed". Here plumbing and porcelain differ. Plumbing commands report the path as changed. Porcelain commands first refresh the index: they re-read the file and, when the content still equals the blob, store the new stat data. `git update-index --refresh` 🟢 SAFE does the same on request.

**The lock, and a rebuild.** In one sentence: every writer creates `.git/index.lock`, writes a complete new index into it, and renames it over `.git/index`. A leftover lock therefore blocks all writers, and a damaged index can be discarded and rebuilt from HEAD, the last commit, at the price of whatever was only staged.

A lock without a process means a crash, a `kill -9` or a power loss. A lock with a live process is normal: an editor, a hook, another terminal. Removing a lock is 🟡 CAUTION: it's unsafe while a Git process is writing, so check with `pgrep -fl git` first.

Rebuilding is 🔴 DANGEROUS: `rm .git/index`, then `git reset`. The five questions. What it changes: it discards the index and writes a new one from HEAD's tree. What it can destroy: the staging state, the flag bits and the conflict stages. That is, the record of what was staged and not committed, which no reflog holds.

How to preview: `git diff --cached`. And move the file aside instead of deleting it. How to recover: `git fsck` for blobs that were staged, or move the file back. When it is appropriate: only for a corrupt index. And never during a merge, because the conflict stages exist only in the index.

## MENTAL MODEL

The textbook's analogy for the stat cache: a librarian who checks whether a book was touched by looking at the dust on it instead of rereading it. Disturbed dust only means that the book must be reread. It breaks at one point: Git knows when dust can lie, namely an edit that keeps the size and lands in the same timestamp tick as the index write, and rereads then.

**[ANIMATION]** step: edit

Use the same picture for the two bits. Setting `--assume-unchanged` is telling the librarian "do not even look at the dust on this book; I promise I have not touched it". If you then write in the book, the catalogue is wrong, and every command that trusts the catalogue is wrong with it.

## DIAGRAM

Now one entry, with all its fields.

**[DIAGRAM]** One index entry, drawn as a record. Each field is highlighted when its segment begins.

```text
 +----------------------------------------------------------------------------+
 | path          config/settings.yaml                  -> the commit's tree   |
 | mode          100644                                -> the commit's tree   |
 | blob ID       the content that was last staged      -> the commit's tree   |
 | stage         0   (1, 2, 3 only during a conflict)     stays on your disk  |
 | flags         assume-unchanged, skip-worktree,         stays on your disk  |
 |               intent-to-add                                                |
 | cached stat   size, timestamps, inode, ...             stays on your disk  |
 +----------------------------------------------------------------------------+
```

Six fields. The first three are what the commit's tree receives. The last three never leave your machine. Every topic of this video lives in the bottom half.

**[DIAGRAM]** The root-cause box of section 5.12, one line at a time.

```text
Observed behavior : git status says "nothing to commit, working tree clean". git merge stops
                    with "Your local changes to the following files would be overwritten".
Git state         : The entry of config/settings.yaml has the assume-unchanged bit (git ls-files
                    -v prints "h"). The file on disk differs from the entry.
Mechanism         : Commands that list changes skip flagged entries. A command that must replace
                    the file checks the real file first, finds the edit and stops.
Root cause        : The bit was used to hide a local edit. It is a promise that there is none.
Why Git does this : It cannot know whether a local change is precious, so it "has to take the
                    safe route and always preserve them" (gitfaq).
Correct fix       : Clear the bit (--no-assume-unchanged, --no-skip-worktree), then commit,
                    stash or discard the edit in the open.
Prevention        : Private settings in a separate, ignored file. Find leftover bits with
                    git ls-files -v | grep -e '^[a-z]' -e '^S'
```

That's the CTO's story as a root-cause box. Read the line marked root cause: the bit is a promise that there is no edit.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch05/ls-files-tour.sh`.

```bash
labs/run ch05/ls-files-tour
```

The repository has a modified file, a deleted file, an untracked file, two ignored ones, and an `.env` that was committed before its ignore rule.

<!-- snippet: ch05/ls-files-tour/01-cached-and-stage -->
```text
# Default (-c, --cached): the paths in the index.
$ git ls-files
.env
.gitignore
config/settings.yaml
scripts/run_eval.sh
src/app.py
src/retriever.py
# -s, --stage: mode, blob ID and stage number for each entry.
$ git ls-files --stage
100644 5620d7c0158994dedf8a5ff7d48b68e5479f513c 0	.env
100644 458a0d0e4ed4456621938b79b4e341b06e69f3f1 0	.gitignore
100644 4da99e38a05a2a7b436aaea17b946e0288949413 0	config/settings.yaml
100755 08029a15a3e1b17a4e0bcb6c31cddc52ec34eec5 0	scripts/run_eval.sh
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/ls-files-tour/02-against-working-tree -->
```text
# -m: tracked paths whose working tree file differs from the index. A deleted file counts.
$ git ls-files --modified
config/settings.yaml
src/retriever.py
# -d: tracked paths whose working tree file is gone.
$ git ls-files --deleted
config/settings.yaml
```
<!-- /snippet -->

<!-- snippet: ch05/ls-files-tour/03-others -->
```text
# -o: paths with no index entry. Ignore rules apply only when you ask for them.
$ git ls-files --others
notes.md
server.log
src/__pycache__/app.cpython-314.pyc
$ git ls-files --others --exclude-standard
notes.md
# -o -i: untracked paths that an ignore rule matches.
$ git ls-files --others --ignored --exclude-standard
server.log
src/__pycache__/app.cpython-314.pyc
# -c -i: TRACKED paths that an ignore rule matches. This finds the already-tracked trap.
$ git ls-files --cached --ignored --exclude-standard
.env
```
<!-- /snippet -->

`--others` alone lists ignored files too, which is why `--exclude-standard` appears in nearly every real use. The last command of this snippet is the detector for the already-tracked trap of video 12.

<!-- snippet: ch05/ls-files-tour/04-ignored-needs-c-or-o -->
```text
$ git ls-files --ignored --exclude-standard
fatal: ls-files -i must be used with either -o or -c
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch05/ls-files-tour/05-tags -->
```text
# -t prefixes each path with a status tag: H cached, C changed, R removed, ? other.
$ git ls-files -t --cached --modified --deleted --others --exclude-standard
? notes.md
H .env
H .gitignore
H config/settings.yaml
R config/settings.yaml
C config/settings.yaml
H scripts/run_eval.sh
H src/app.py
H src/retriever.py
C src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/ls-files-tour/06-scripting -->
```text
# Is this path tracked? The exit status answers.
$ git ls-files --error-unmatch src/app.py
src/app.py
[exit status: 0]
$ git ls-files --error-unmatch notes.md
error: pathspec 'notes.md' did not match any file(s) known to git
Did you forget to 'git add'?
[exit status: 1]
# A custom format, one field at a time.
$ git ls-files --abbrev --format='%(objectmode) %(objectname) %(objectsize:padded) %(path)'
100644 5620d7c      28 .env
100644 458a0d0      24 .gitignore
100644 4da99e3      25 config/settings.yaml
100755 08029a1      20 scripts/run_eval.sh
100644 63df51b      38 src/app.py
100644 1e0b1ad      10 src/retriever.py
```
<!-- /snippet -->

Is this path tracked? The exit status of `--error-unmatch` answers.

**[TERMINAL]** Caption bar: `labs/ch05/assume-skip.sh`.

```bash
labs/run ch05/assume-skip
```

`git update-index --assume-unchanged` 🟡 CAUTION, and then a private edit that points the service at a local model server. Predict what `git status` says about that edit: modified, or clean? Say it out loud.

**[PAUSE]**

<!-- snippet: ch05/assume-skip/01-assume-unchanged -->
```text
$ git update-index --assume-unchanged config/settings.yaml
# ls-files -v shows the bit as a lower-case tag.
$ git ls-files -v
h config/settings.yaml
H src/app.py
# Point the service at a local model server. A private edit you do not want to commit.
$ cat config/settings.yaml
model: small-v1
api_base: http://localhost:8080
$ git status --short
$ git diff
```
<!-- /snippet -->

Clean. `git ls-files -v` shows the bit as a lower-case tag, and status prints nothing. Now a teammate's change to the same file arrives. Predict what `git merge` does. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch05/assume-skip/03-assume-unchanged-breaks -->
```text
# The teammate changed the same file. Git checks the real file before overwriting it.
$ git merge teammate
error: Your local changes to the following files would be overwritten by merge:
	config/settings.yaml
Please commit your changes or stash them before you merge.
Aborting
Updating b52b27b..0fac3ad
[exit status: 1]
$ git status
On branch main
nothing to commit, working tree clean
# A clean status and a refused merge at the same time. And restore silently discards the edit:
$ git restore config/settings.yaml
$ cat config/settings.yaml
model: small-v1
api_base: https://llm.internal.example
$ git update-index --no-assume-unchanged config/settings.yaml
```
<!-- /snippet -->

A refused merge and a clean status at the same time. That's the first half of the CTO's story. Then `git restore` on that path: 🔴 DANGEROUS, as always, and here worse, because it replaces the hidden edit with the index version, silently. That's the second half: the settings are gone. You can't preview it with `git diff` until you clear the bit.

**[DIAGRAM]** Show the root-cause box.

<!-- snippet: ch05/assume-skip/04-skip-worktree -->
```text
$ git update-index --skip-worktree config/settings.yaml
$ git ls-files -v
S config/settings.yaml
H src/app.py
# The same private edit again.
$ git status --short
$ git add config/settings.yaml
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
config/settings.yaml
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch05/assume-skip/05-skip-worktree-breaks -->
```text
$ git merge teammate
error: Your local changes to the following files would be overwritten by merge:
	config/settings.yaml
Please commit your changes or stash them before you merge.
Aborting
Updating b52b27b..0fac3ad
[exit status: 1]
$ git restore config/settings.yaml
error: pathspec 'config/settings.yaml' did not match any file(s) known to git
[exit status: 1]
$ git status --short
```
<!-- /snippet -->

`--skip-worktree` 🟡 CAUTION fails differently and no better.

<!-- snippet: ch05/assume-skip/06-find-and-clear -->
```text
# Find paths that carry either bit, then clear them.
$ git ls-files -v | grep -e '^[a-z]' -e '^S'
S config/settings.yaml
$ git update-index --no-skip-worktree config/settings.yaml
$ git status --short
 M config/settings.yaml
```
<!-- /snippet -->

Find paths that carry either bit, then clear them. The edit is visible again.

Try it now, thirty seconds. In a repository you work in, run `git ls-files -v`. It only reads. Look at the first letter of each line: a lower-case letter, or a capital S, means one of the two bits is set. Pause me, and note your answer.

**[PAUSE]**

<!-- snippet: ch05/assume-skip/07-the-arrangement-that-works -->
```text
# Keep the shared defaults tracked. Put private overrides in a file that no commit has ever tracked.
$ echo 'config/settings.local.yaml' >> .gitignore
$ git add .gitignore
$ git commit -m "Ignore the per-developer settings override"
[main ce22e5e] Ignore the per-developer settings override
 1 file changed, 1 insertion(+)
 create mode 100644 .gitignore
$ echo 'api_base: http://localhost:8080' > config/settings.local.yaml
$ git status --short --ignored
!! config/settings.local.yaml
# The teammate change to the tracked defaults now merges, and the private file is untouched.
$ git merge teammate
Merge made by the 'ort' strategy.
 config/settings.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat config/settings.yaml config/settings.local.yaml
model: small-v2
api_base: https://llm.internal.example
api_base: http://localhost:8080
```
<!-- /snippet -->

And the arrangement that works: shared defaults tracked, private overrides in a file that no commit has ever tracked.

**[TERMINAL]** Caption bar: `labs/ch05/conflict-stages.sh`.

```bash
labs/run ch05/conflict-stages
```

Two branches changed the same line.

<!-- snippet: ch05/conflict-stages/02-conflict -->
```text
$ git merge tune-retrieval
Auto-merging config/settings.yaml
CONFLICT (content): Merge conflict in config/settings.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU config/settings.yaml
$ git ls-files --stage
100644 4da99e38a05a2a7b436aaea17b946e0288949413 1	config/settings.yaml
100644 9b521fd0f699b5fd45c7618b4e7560d00cc24088 2	config/settings.yaml
100644 2e6bc1476312458dcdd5e7eacf04942211ccb27f 3	config/settings.yaml
```
<!-- /snippet -->

One path, three entries, three blob IDs. Quick quiz: which stage holds the version from your current branch? One, two or three? Say your answer.

**[PAUSE]**

<!-- snippet: ch05/conflict-stages/03-read-the-stages -->
```text
# Stage 1: the merge base. Stage 2: the current branch. Stage 3: the branch being merged.
$ git show :1:config/settings.yaml
model: small-v1
top_k: 5
$ git show :2:config/settings.yaml
model: small-v1
top_k: 3
$ git show :3:config/settings.yaml
model: small-v1
top_k: 8
$ cat config/settings.yaml
model: small-v1
<<<<<<< HEAD
top_k: 3
=======
top_k: 8
>>>>>>> tune-retrieval
```
<!-- /snippet -->

Stage 2. Stage 1 is the merge base, the common ancestor. Stage 2 is the current branch. Stage 3 is the branch being merged. Each can be read as a complete file. That's all for now. Part 2 lives here.

**[TERMINAL]** Caption bar: `labs/ch05/stat-cache.sh`.

```bash
labs/run ch05/stat-cache
```

<!-- snippet: ch05/stat-cache/01-entry -->
```text
# The stat fields are your machine and your clock, so this transcript masks their values with N.
$ git ls-files --debug src/app.py | sed -E '/time|dev|uid/s/[0-9]+/N/g'
src/app.py
  ctime: N:N
  mtime: N:N
  dev: N	ino: N
  uid: N	gid: N
  size: 38	flags: 0
# size is the length of the file on disk. Here it equals the size of the blob.
$ git cat-file -s :src/app.py
38
```
<!-- /snippet -->

The stat fields belong to your machine and your clock, so this transcript masks their values with N.

The script changes the modification time of a file. The content stays the same. Predict what plumbing says.

<!-- snippet: ch05/stat-cache/02-touch -->
```text
# Change the modification time of the file. The content stays the same.
$ touch -t 202001010000 src/app.py
# Plumbing compares stat data only, and reports the entry as possibly changed.
$ git diff-files
:100644 100644 63df51b788f2464137e0f30355056e42a320f705 0000000000000000000000000000000000000000 M	src/app.py
```
<!-- /snippet -->

`git diff-files` reports `M`. The all-zero ID on the right is its notation for a working-tree file that is out of sync with the index.

<!-- snippet: ch05/stat-cache/03-refresh -->
```text
# Porcelain re-reads the file, finds the same content, and stores the new stat data.
$ git status --short
$ git diff-files
```
<!-- /snippet -->

`git status` printed nothing: it re-read the file, found the same content, and wrote the new stat data back, so the second `git diff-files` is silent as well.

<!-- snippet: ch05/stat-cache/05-real-change -->
```text
# A real edit: refresh cannot make this entry match, and says so.
$ echo 'TOP_K = 10' > src/retriever.py
$ git update-index --refresh
src/retriever.py: needs update
[exit status: 1]
$ git diff-files
:100644 100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0000000000000000000000000000000000000000 M	src/retriever.py
```
<!-- /snippet -->

A real edit: refresh can't make this entry match, and says "needs update".

**[TERMINAL]** Caption bar: `labs/ch05/dirty-check-in-scripts.sh`.

```bash
labs/run ch05/dirty-check-in-scripts
```

<!-- snippet: ch05/dirty-check-in-scripts/01-false-positive -->
```text
# A release script asks plumbing: does anything differ from HEAD? Exit status 0 means no.
$ git diff-index --quiet HEAD
[exit status: 0]
# Copy the repository, as a build context or a restored CI cache does. No file content changes.
$ cp -R ../support-bot ../build-copy
$ cd ../build-copy
$ git diff-index --quiet HEAD
[exit status: 1]
$ git diff-files --name-status
M	config/settings.yaml
M	src/app.py
```
<!-- /snippet -->

A release script asks plumbing whether anything differs from HEAD. Then the repository is copied, as a build context or a restored CI cache does. No file content changes, and the copy is "dirty".

<!-- snippet: ch05/dirty-check-in-scripts/02-refresh-first -->
```text
# Refresh: re-read the files whose stat data differ, and store the new stat data when the content matches.
$ git update-index -q --refresh
$ git diff-index --quiet HEAD
[exit status: 0]
$ git diff-files --name-status
```
<!-- /snippet -->

Refresh first, and the check passes.

**[TERMINAL]** Caption bar: `labs/ch05/index-lock-and-rebuild.sh`.

```bash
labs/run ch05/index-lock-and-rebuild
```

<!-- snippet: ch05/index-lock-and-rebuild/01-lock -->
```text
# Imitate a Git process that died while it was writing the index.
$ touch .git/index.lock
$ echo 'TOP_K = 8' > src/retriever.py
$ git add src/retriever.py
fatal: Unable to create '$LAB/ch05/index-lock-and-rebuild/support-bot/.git/index.lock': File exists.

Another git process seems to be running in this repository, or the lock file may be stale
[exit status: 128]
# Reading still works. Only writers need the lock.
$ git status --short
 M src/retriever.py
# After checking that no Git process is running, remove the stale lock.
$ rm .git/index.lock
$ git add src/retriever.py
$ git status --short
M  src/retriever.py
```
<!-- /snippet -->

The script imitates a Git process that died while it was writing the index. Readers work, and writers fail.

<!-- snippet: ch05/index-lock-and-rebuild/02-corrupt -->
```text
# One staged change (retriever.py) and one unstaged change (settings.yaml) exist.
$ echo 'temperature: 0.2' >> config/settings.yaml
$ git status --short
 M config/settings.yaml
M  src/retriever.py
# Now the index file is damaged.
$ printf 'garbage' > .git/index
$ git status
fatal: .git/index: index file smaller than expected
[exit status: 128]
```
<!-- /snippet -->

One staged change and one unstaged change exist, and then the index file is damaged. The five questions for the rebuild were answered in the concept segment. Predict what `git status` shows when there's no index at all.

<!-- snippet: ch05/index-lock-and-rebuild/03-rebuild -->
```text
# Delete the damaged file. With no index, every path in HEAD looks deleted and every file looks new.
$ rm .git/index
$ git status --short
D  config/settings.yaml
D  src/app.py
D  src/retriever.py
?? config/
?? src/
# Rebuild the index from HEAD. A mixed reset writes the index and leaves the working tree alone.
$ git reset
Unstaged changes after reset:
M	config/settings.yaml
M	src/retriever.py
$ git status --short
 M config/settings.yaml
 M src/retriever.py
```
<!-- /snippet -->

Without an index, every path of HEAD looks like a staged deletion, and every file looks untracked. `git reset` 🟡 CAUTION wrote a new index from HEAD and left the files alone.

<!-- snippet: ch05/index-lock-and-rebuild/04-what-was-lost -->
```text
# The files are intact. What is gone is the knowledge of which change was staged.
$ git diff --stat
 config/settings.yaml | 1 +
 src/retriever.py     | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git fsck
dangling blob 5fac60c5a32ec062dcb2163acd05c4c1c20dda0c
```
<!-- /snippet -->

The files are intact. What's gone is the knowledge of which change was staged: both changes are unstaged now. The blob that was staged is still in the object database: `git fsck` lists it as dangling, an object that nothing points to.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Hiding a local edit with `--assume-unchanged` or `--skip-worktree`.** Root cause: the bit is a promise that there is no edit; commands that list changes skip the entry, and commands that must replace the file stop, or overwrite it.
2. **A script reports a dirty tree in a fresh copy.** Root cause: plumbing compares cached stat data only, and the copy has new timestamps; run `git update-index -q --refresh` first, or use `git status --porcelain`.
3. **Removing `index.lock` while a Git process is running.** Root cause: the lock was live, not stale; check with `pgrep -fl git`.
4. **Rebuilding the index during a merge.** Root cause: the conflict stages exist only in the index.
5. **Treating the index as storage.** Root cause: a blob that only the index refers to becomes unreachable the moment its entry changes, and is pruned after two weeks by default.

## PRODUCTION EXAMPLE

Now, out of the lab. A team's README tells every developer to run `--skip-worktree` on a configuration file. The textbook names what that creates: state that no clone and no CI image reproduces, and that fails at the next upstream change to that file. The replacement costs one commit: an ignored `settings.local.yaml` that no commit on any branch has ever tracked, and an application that reads the shared defaults first and the local overrides second.

And the release-build case: a build of an unchanged commit gets labelled dirty inside a container or after a cache restore, because the copy gave every file new stat data. The lock message in CI usually means two Git processes in one working tree. Background tools should run `git --no-optional-locks status`, or set `GIT_OPTIONAL_LOCKS=0`.

## PRACTICE EXERCISE

Your turn. Do Exercise 2.4, Level 2, "what does the commit contain?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Answer from `git ls-files --stage` and the three diffs, before you make the commit. Then make it and compare the tree with your prediction.

## INTERVIEW QUESTION

Q63: "Why are `--assume-unchanged` and `--skip-worktree` not ways to ignore local changes? What do you recommend to a team that needs per-developer settings?"

**[PAUSE]**

Answer out loud. A strong answer states what each bit is documented for, describes how each one fails when the file changes upstream, and quotes Git's own position on the underlying wish. The recommendation should be concrete enough to implement, and should say why the private file's name matters.

## RECAP

Let's land this. You should now be able to say, in your own words: `git ls-files` lists index entries and, with options, untracked and ignored paths, and scripts use it with `--exclude-standard` and `-z`. The assume-unchanged and skip-worktree bits are promises to Git, not an ignore mechanism. Private settings belong in a separate ignored file.

**[ANIMATION]** step: merge-base

During a conflict a path has entries at stages 1, 2 and 3: base, ours, theirs.

**[ANIMATION]** end

The index caches stat data, so plumbing can report an unchanged file as modified until the index is refreshed. A stale `index.lock` blocks writers. A corrupt index is rebuilt from HEAD with `git reset`, and what is lost is the staging.

## HOMEWORK

- Read sections 5.11 to 5.18 of [Chapter 5](../../textbook/ch05-index.md), and do the Practice section 5.20.
- Challenge: Exercise 2.9, Level 4, "Git does not see my edits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Today you read an index entry field by field, and that completes the index. Check one of your own repositories for leftover bits before the next video. Next time: what a commit is, how `git commit` creates it, and the commit ID. Until then, look at the state first and type second. See you in the next one.

# V103: Reachability, git fsck, and where Git checks its hashes

- **Part.** 4: Git internals
- **Module.** 16
- **Planned minutes.** 22
- **Prerequisites.** V073, V102
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), section 3.8
- **Demo scripts.** `labs/ch03/fsck-reachability.sh`, `labs/ch03/object-integrity.sh`, `labs/ch03/fsck-reflog-clock.sh`

## HOOK

**[ON SCREEN]** A terminal line: `dangling commit`, on the build server.

A scheduled job on the build server runs `git fsck`, Git's own checker, and mails the output. This morning the mail has one line in it: "dangling commit", followed by an ID. A colleague replies to the thread: the repository is damaged, somebody should run a cleanup.

Your CTO asks you two things. Is data at risk? And should somebody run a cleanup?

The answer, which you'll be able to defend at the end of this video: "dangling" describes where `git fsck` started looking, not what will be deleted. And the cleanup is the risky part. Keep that one-line mail in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video has three parts and three replays from `labs/ch03`. First, reachability: which objects Git can arrive at, from where, and what `git fsck` calls the rest. An object is one stored unit, such as a commit or a file's content. Second, integrity: an object ID is a checksum, and you'll see where Git recomputes it and where it doesn't. Third, a rule that entered `git fsck` in Git 2.53.0 about reflog entries dated in the future. A reflog is the local journal of the values a ref, a name such as a branch, has had. That rule is the reason the lab clock of this course sits in the past.

`git fsck` is 🟢 SAFE: it changes nothing. One command near the end is 🔴 DANGEROUS, `git gc --prune=now`, and I'll answer the five questions before running it.

## LEARNING OBJECTIVES

After this video you can:

- Define reachable as Git's maintenance uses it and list the roots.
- Tell a dangling object from an unreachable one in `git fsck` output.
- Decide whether a `dangling commit` line means anything is at risk.
- Explain why a corrupt object can pass local commands and fail a clone.
- Explain the `git fsck` rule about future-dated reflog entries and the Git version it came with.

## CONCEPT

Why this matters: garbage collection, Git's clean-up, deletes objects, and recovery finds them. Both are defined by one word, reachable. If you can say precisely what is reachable, you know what is safe and for how long.

In one sentence: an object is reachable if you can arrive at it from a starting point by following the IDs stored inside objects. `git fsck` verifies that everything reachable is present and well-formed, and lists what nothing reaches.

Now precisely, in the glossary's words: one object is reachable from another "if we can reach the one from the other by a chain that follows tags to whatever they tag, commits to their parents or trees, and trees to the trees or blobs that they contain".

Two more terms. An unreachable object is one that no starting point reaches. A dangling object is an unreachable object that no other unreachable object refers to: the tip of a lost line.

**[ANIMATION]** cards: question=Where_does_git_fsck_start? cards=the_index:the_staging_area|all_refs:branches,_tags_and_the_rest_of_refs/|all_reflogs:the_journals_of_past_values|HEAD:the_name_for_where_you_are numbered=on title=The_four_roots id=roots

**[ANIMATION]** step: 4

The starting points. The manual of `git fsck` lists them as "the index file, all SHA-1 references in the `refs` namespace, and all reflogs", and HEAD is added to that. Four roots, then: the index, which is the staging area, all refs, all reflogs, and HEAD, the name for where you are.

**[ANIMATION]** say: Garbage_collection_keeps_alive_what_these_four_reach

Garbage collection keeps the same set alive, and deletes an unreachable object only after a grace period: two weeks by default, the setting `gc.pruneExpire`.

**[ANIMATION]** end

Inside `.git`: `git fsck` changes nothing. `git gc` removes unreachable objects from `objects/` once they're past the grace period, and `git reflog expire` removes lines from `logs/`.

**[ANIMATION]** ladder: rungs=reachable_from_a_ref_or_the_index:kept|named_only_by_a_reflog_entry:kept_until_the_entry_expires,_90_or_30_days_by_default|unreachable:kept_for_the_grace_period,_two_weeks_by_default|pruned:another_clone_or_a_backup_only title=How_long_an_object_is_kept id=keep steps=1,2,3 pace=quick

The reflog is the root people forget. Reflog entries expire: 90 days by default, and 30 days when the commit is no longer reachable from the tip of the ref. The lab configuration switches both off. And a deleted branch loses its own reflog at once. So after you delete a branch, the entry that still protects its commits is in the reflog of HEAD.

**[ANIMATION]** hash: differs=byte steps=one,different,same left=the_object_Git_stored right=the_file_after_the_overwrite lines=blob_40,def_predict(text):,return_len(text) alt=return_999999999 ids=e2238784,bf8a76ba diff=git_fsck_hashes_what_it_finds:_it_no_longer_matches_the_name same=The_true_content_gives_the_true_ID_again title=An_object_ID_is_a_checksum

Now the second topic. An object ID is a checksum, and Git doesn't recompute it on every read. A file under `objects/` that is a well-formed object with the wrong content is served as it is.

**[ANIMATION]** step: different

Two operations do recompute IDs from content. `git fsck` hashes what it finds and compares the result with the name. And a transfer through Git's transport sends object content without IDs. The receiving side computes every ID itself, so an object can't arrive under a name that its content doesn't have. A clone from a local path skips the transport and copies or hard-links the files. The option `--no-local` forces the transport.

**[ANIMATION]** end

**[ANIMATION]** walk: columns=treat_it_as,the_line_begins_with rows=information:dangling|an_incident:missing|an_incident:error: marks=1.1:ok,2.1:bad,3.1:bad title=Reading_git_fsck_output id=lines

When should you not act? When `git fsck` prints `dangling`. That line is information. The lines that are an incident begin with `missing` or `error:`.

## MENTAL MODEL

The textbook's analogy is a library with a catalogue. A book is findable if a card names it or a findable book cites it. A book that nothing names is still on its shelf, complete, until the next clear-out.

**[ANIMATION]** graph: 0c2cf43 main; HEAD=main => 0c2cf43-728ac29 experiment/cache; 0c2cf43 main; HEAD=experiment/cache => 0c2cf43 main; HEAD=main; reflog:728ac29; note:728ac29:only_the_reflog_of_HEAD_names_it title=A_commit_only_names_what_came_before_it id=lost

**[ANIMATION]** step: state-2

The analogy breaks at direction. In Git, citations only run from newer to older: a commit names its parents, never its children.

**[ANIMATION]** step: state-3

So losing the card for the newest commit of a line makes the whole line unfindable at once. On screen, the branch from today's demo is deleted, and no branch names its commit any more.

Try it now, on paper, thirty seconds. Draw three commits in a line, with a branch name on the newest. Erase the name. Which one commit must you find to get all three back? I'll wait.

**[PAUSE]**

The newest. Carry two consequences from the model. One: "unfindable" is not "gone". The objects stay on the shelf until a clear-out that is weeks away by default. Two: find the newest commit of a lost line, the dangling one, and you have found everything behind it.

## DIAGRAM

**[ANIMATION]** stores: boxes=starting_points:where_git_fsck_begins|*objects:what_each_one_leads_to|verdict:for_these_objects rows=1:A:refs/heads/main|1:A:tags,_the_index,_HEAD|1:B:commit_0c2cf43|1:B:trees,_blobs,_parents|1:C:reachable@ok|2:A:reflog_entry_HEAD@{1}@hl|2:B:commit_728ac29@hl|2:B:tree_73c1ade@hl|2:B:blob_35376fb@hl|2:C:through_the_reflog_only@hl|3:A:nothing@dim|3:B:blob_e6773e7@ghost|3:C:dangling@bad arrows=1:A1>B1|2:A3>B3|2:B3>B4|2:B4>B5 title=Reachable_from_where? id=reach

**[ANIMATION]** step: 1

**[DIAGRAM]** Two columns: starting points on the left, objects on the right.

```text
  starting points                         objects
  refs/heads/main --------------------->  0c2cf43 ---> trees and blobs, parents ...   reachable
  refs/tags/..., index, HEAD
  reflog entry HEAD@{1} --------------->  728ac29 ---> 73c1ade ---> 35376fb           reachable
                                          (commit)     (tree)       (blob)            through the reflog only
  nothing ------------------------------  e6773e7                                     dangling
                                          (blob that was staged and unstaged)
```

First group: the branch `main` points at commit `0c2cf43`, and from there you reach its trees, its blobs and its parents. Tags, the index and HEAD are roots of the same kind.

**[ANIMATION]** step: 2

Second group: commit `728ac29`, its tree `73c1ade` and its blob `35376fb`. No branch names this commit any more. One reflog entry, `HEAD@{1}`, does. These three objects are reachable through the reflog only. One reflog entry stands between a deleted branch and the garbage collector.

**[ANIMATION]** step: 3

**[ANIMATION]** say: The_blob_that_was_staged_and_unstaged:_nothing_points_at_it

Third group: blob `e6773e7`. Nothing points at it. It's dangling.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch03/fsck-reachability
```

```bash
git fsck
```

<!-- snippet: ch03/fsck-reachability/01-healthy -->
```text
# A healthy repository: no output, exit status 0.
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

A healthy repository: no output, exit status 0. Silence is the good answer.

Stage a file, then change your mind.

```bash
printf 'api_token = "test-0000-not-a-real-token"\n' > secrets.toml
git add secrets.toml
git rm --cached --quiet secrets.toml
git status --short
git fsck
git cat-file -p e6773e7e
```

A quick quiz. The file was staged and unstaged, and `git status` shows it as untracked. What does `git fsck` print now: nothing, an error, or a line about a blob? Your answer?

**[PAUSE]**

<!-- snippet: ch03/fsck-reachability/02-dangling-blob -->
```text
# Stage a file, then change your mind and unstage it.
$ printf 'api_token = "test-0000-not-a-real-token"\n' > secrets.toml
$ git add secrets.toml
$ git rm --cached --quiet secrets.toml
$ git status --short
?? secrets.toml
# The index entry is gone. The blob that "git add" wrote is not:
$ git fsck
dangling blob e6773e7e30f399953039ee95529a70c172b7bf5e
$ git cat-file -p e6773e7e
api_token = "test-0000-not-a-real-token"
```
<!-- /snippet -->

A dangling blob. Unstaging removed an index entry, not the blob that `git add` had written. Anyone with access to this directory can still read the token. The same fact saves you on the day you lose a staged file.

**[ANIMATION]** graph: 0c2cf43 main; HEAD=main => 0c2cf43-728ac29 experiment/cache; 0c2cf43 main; HEAD=experiment/cache => 0c2cf43 main; HEAD=main; reflog:728ac29; note:728ac29:only_the_reflog_of_HEAD_names_it title=A_commit,_then_its_branch_is_deleted id=demo

Now a commit on a branch, and then the branch is deleted. Deleting a branch with `-D` was introduced with its risk label in the branches videos. Here it runs in a sandbox, and the point is what remains afterwards.

```bash
git switch --quiet -c experiment/cache
printf 'cache_ttl_s = 300\n' >> config.toml
git commit --quiet -am "Add cache TTL"
git switch --quiet main
git branch -D experiment/cache
git fsck --no-reflogs --unreachable
git fsck --no-reflogs
```

With the reflogs excluded as starting points: how many objects are unreachable, and how many of them are dangling? Say both numbers out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch03/fsck-reachability/03-unreachable -->
```text
# A commit on a branch, and then the branch is deleted.
$ git switch --quiet -c experiment/cache
$ printf 'cache_ttl_s = 300\n' >> config.toml
$ git commit --quiet -am "Add cache TTL"
$ git switch --quiet main
$ git branch -D experiment/cache
Deleted branch experiment/cache (was 728ac29).
# Starting from refs and the index only (--no-reflogs), four objects are unreachable:
# the commit, its tree, its new blob, and the blob that was unstaged earlier.
$ git fsck --no-reflogs --unreachable
unreachable blob e6773e7e30f399953039ee95529a70c172b7bf5e
unreachable commit 728ac2949c899feb5120ad1d50640f48e299c311
unreachable tree 73c1adebf83ff39f155fe1236171279e58109bc6
unreachable blob 35376fb465bd033dbe3a382c6a66467bef321292
# Only the objects that nothing at all points to are called dangling:
$ git fsck --no-reflogs
dangling blob e6773e7e30f399953039ee95529a70c172b7bf5e
dangling commit 728ac2949c899feb5120ad1d50640f48e299c311
```
<!-- /snippet -->

Four are unreachable: the commit, its tree, its new blob, and the blob from the previous step. Two are dangling. The tree `73c1ade` and the blob `35376fb` aren't dangling, because the unreachable commit refers to them. If you said four and four, that's the usual first answer.

```bash
git reflog -3
git log --oneline -1 "HEAD@{1}"
git fsck
```

<!-- snippet: ch03/fsck-reachability/04-reflog-still-holds-it -->
```text
# The HEAD reflog still records the commit, which is what keeps it safe for now:
$ git reflog -3
0c2cf43 HEAD@{0}: checkout: moving from experiment/cache to main
728ac29 HEAD@{1}: commit: Add cache TTL
0c2cf43 HEAD@{2}: checkout: moving from main to experiment/cache
$ git log --oneline -1 "HEAD@{1}"
728ac29 Add cache TTL
# With reflog entries as starting points again, only the blob is left over:
$ git fsck
dangling blob e6773e7e30f399953039ee95529a70c172b7bf5e
```
<!-- /snippet -->

The reflog of HEAD still records commit `728ac29`. With reflog entries as starting points again, plain `git fsck` reports only the blob. The commit was never at risk today.

**[TERMINAL]** Second replay: where the hash is checked.

```bash
labs/run ch03/object-integrity
```

```bash
git rev-parse HEAD:src/server.py
git cat-file -p HEAD:src/server.py
```

The script then overwrites that loose object file with a valid zlib stream: the same header, the same length, other content. This substitution is crafted. Random damage, such as a flipped bit, normally breaks the zlib stream and fails loudly on the first read.

```bash
git cat-file -p HEAD:src/server.py
git status --short
```

The content under that ID is now wrong. Will `git cat-file` complain? Will `git status`? Yes or no for each. Say it out loud.

**[PAUSE]**

<!-- snippet: ch03/object-integrity/01-tamper -->
```text
$ git rev-parse HEAD:src/server.py
e2238784c412f0a5151764c07c7a44e7b3a9c073
$ git cat-file -p HEAD:src/server.py
def predict(text):
    return len(text)
# Overwrite that loose object with a valid zlib stream: same header, same length, other content.
$ chmod u+w .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
$ python3 -c "import sys, zlib; open(sys.argv[1], 'wb').write(zlib.compress(b'blob 40\0def predict(text):\n    return 999999999\n'))" .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
# Ordinary commands read the object by its name and do not recompute the hash:
$ git cat-file -p HEAD:src/server.py
def predict(text):
    return 999999999
[exit status: 0]
$ git status --short
[exit status: 0]
```
<!-- /snippet -->

Neither does. Ordinary commands read the object by its name and don't recompute the hash.

```bash
git fsck
git clone --quiet --no-local . ../clone-over-transport
git clone --quiet . ../clone-by-file-copy
git -C ../clone-by-file-copy cat-file -p HEAD:src/server.py
```

<!-- snippet: ch03/object-integrity/02-detect -->
```text
# git fsck hashes what it finds and compares the result with the file name:
$ git fsck
error: bf8a76ba21df71f4f19002c42f44ea784df0f99d: hash-path mismatch, found at: .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
missing blob e2238784c412f0a5151764c07c7a44e7b3a9c073
[exit status: 3]
# A fetch-style transfer rebuilds every ID on the receiving side, so the bad object cannot travel:
$ git clone --quiet --no-local . ../clone-over-transport
fatal: did not receive expected object e2238784c412f0a5151764c07c7a44e7b3a9c073
fatal: fetch-pack: invalid index-pack output
[exit status: 128]
# A plain file copy has no such check:
$ git clone --quiet . ../clone-by-file-copy
[exit status: 0]
$ git -C ../clone-by-file-copy cat-file -p HEAD:src/server.py
def predict(text):
    return 999999999
```
<!-- /snippet -->

`git fsck` reports `hash-path mismatch` and `missing blob`, with exit status 3. The clone through the transport fails: "did not receive expected object". The clone by file copy succeeds and carries the bad object with it. That is the fourth objective: a corrupt object passes local commands and fails a clone, because only the transfer recomputes every ID.

The repair.

```bash
git hash-object src/server.py
rm -f .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
git hash-object -w src/server.py
git fsck
git cat-file -p HEAD:src/server.py
```

<!-- snippet: ch03/object-integrity/03-repair -->
```text
# The working tree still holds the true content, and content alone determines the ID.
$ git hash-object src/server.py
e2238784c412f0a5151764c07c7a44e7b3a9c073
# Git will not rewrite an object it believes it has, so remove the bad file first.
$ rm -f .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
$ git hash-object -w src/server.py
e2238784c412f0a5151764c07c7a44e7b3a9c073
$ git fsck
[exit status: 0]
$ git cat-file -p HEAD:src/server.py
def predict(text):
    return len(text)
```
<!-- /snippet -->

The working tree still holds the true content, and content alone determines the ID. Git won't rewrite an object it believes it has, so the bad file is removed first. Deleting a file under `objects/` by hand is damage in every other situation. Here it's the documented repair, for one file that `git fsck` named. `git hash-object -w` is 🟢: it adds one object.

**[ANIMATION]** step: same

True content in, true ID out: `e2238784`, as before.

**[ANIMATION]** end

**[TERMINAL]** Third replay: the clock rule.

```bash
labs/run ch03/fsck-reflog-clock
```

<!-- snippet: ch03/fsck-reflog-clock/01-script -->
```text
$ cat make-history.sh
#!/bin/sh
# make-history.sh <directory> <date>
# Two commits and a reset that drops the second one, all recorded at <date>.
export GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2"
git init --quiet "$1" && cd "$1" || exit 1
echo 'retry_limit = 3' > config.toml
git add config.toml && git commit --quiet -m 'Add configuration'
echo 'retry_limit = 5' > config.toml
git commit --quiet -am 'Raise retry limit'
git reset --quiet --hard HEAD~1
$ sh make-history.sh dated-2001 '2001-01-01T12:00:00+0530'
$ sh make-history.sh dated-2099 '2099-01-01T12:00:00+0530'
```
<!-- /snippet -->

A small script makes two commits and a reset that drops the second one, all recorded at a given date. It runs twice: once dated 2001, once dated 2099.

```bash
git -C dated-2001 reflog --date=short
git -C dated-2001 fsck
git -C dated-2099 reflog --date=short
git -C dated-2099 fsck
git -C dated-2099 log --oneline -1 "HEAD@{1}"
```

The two repositories have the same shape. Will `git fsck` say the same thing about both, or not? Your answer?

**[PAUSE]**

<!-- snippet: ch03/fsck-reflog-clock/02-fsck -->
```text
# Reflog entries in the past count as starting points. Nothing is dangling:
$ git -C dated-2001 reflog --date=short
2cc599e HEAD@{2001-01-01}: reset: moving to HEAD~1
778d03a HEAD@{2001-01-01}: commit: Raise retry limit
2cc599e HEAD@{2001-01-01}: commit (initial): Add configuration
$ git -C dated-2001 fsck
[exit status: 0]
# Reflog entries dated after "now" are skipped, so the dropped commit looks dangling:
$ git -C dated-2099 reflog --date=short
a3c4e27 HEAD@{2099-01-01}: reset: moving to HEAD~1
279be34 HEAD@{2099-01-01}: commit: Raise retry limit
a3c4e27 HEAD@{2099-01-01}: commit (initial): Add configuration
$ git -C dated-2099 fsck
dangling commit 279be34d74a15f6b04f2ec46f2113b8dc8291065
[exit status: 0]
# The commit is in the reflog either way, and the reflog is what you recover from:
$ git -C dated-2099 log --oneline -1 "HEAD@{1}"
279be34 Raise retry limit
```
<!-- /snippet -->

It does not. In the repository dated 2099, the dropped commit is reported as dangling, although the reflog lists it.

**[ON SCREEN]** The root-cause box of section 3.8.

```text
Observed behavior : git fsck reports "dangling commit" for a commit that git reflog still lists
Git state         : the only reference to the commit is a reflog entry dated later than the current time
Mechanism         : git fsck notes the time at which it starts and ignores reflog entries newer than that
Root cause        : the entry was written with a committer date in the future: a wrong system clock,
                    or a script that sets GIT_COMMITTER_DATE
Why Git does this : fsck must not be confused by commits that are created while it runs; skipping
                    newer reflog entries is the "coarse solution" its commit message describes
Correct fix       : none is needed; git gc does not apply the rule, and the commit is not deleted
Prevention        : read "dangling" as information; compare with git reflog before pruning anything
```

The version note: older Git treated every reflog entry as a starting point.

**[ANIMATION]** graph: [dated-2001] 2cc599e-778d03a; 2cc599e main; HEAD=main; reflog:778d03a; note:778d03a:git_fsck_prints_nothing || [dated-2099] a3c4e27-279be34; a3c4e27 main; HEAD=main; reflog:279be34; dangling:279be34 title=The_same_shape,_two_dates id=clock pace=quick say_state_1=Since_Git_2.53.0,_fsck_skips_reflog_entries_dated_after_it_starts

**[ANIMATION]** step: state-1

Since Git 2.53.0, entries dated after the moment fsck starts are skipped, and fsck reads the system clock for this. The textbook verified it locally: Git 2.55.0 applies the rule, Apple's Git 2.50.1 does not. So the two Gits on your Mac can disagree about one repository.

**[ANIMATION]** end

Last step, the 🔴 command: `git gc --prune=now`. The five answers. What it changes: it packs the repository and deletes unreachable objects at once, with no grace period. What it can destroy: every unreachable object, which is what recovery depends on. How to preview: `git fsck --unreachable`, and `git prune -n`. How to recover: from another clone or a backup only. When it's appropriate: after a deliberate history rewrite, in a repository you've copied first, never as routine maintenance. Here it runs on a throwaway sandbox to prove one point. Twig looks worried, and with a red label on screen, fairly so.

```bash
git -C dated-2099 gc --quiet --prune=now
git -C dated-2099 cat-file -t "HEAD@{1}"
git -C dated-2099 count-objects -v | grep -e count -e in-pack
git -C dated-2099 fsck
```

<!-- snippet: ch03/fsck-reflog-clock/03-gc-keeps-it -->
```text
# Garbage collection does not apply the clock rule. Even with no grace period, the commit stays:
$ git -C dated-2099 gc --quiet --prune=now
$ git -C dated-2099 cat-file -t "HEAD@{1}"
commit
$ git -C dated-2099 count-objects -v | grep -e count -e in-pack
count: 0
in-pack: 6
# fsck still calls it dangling. "Dangling" is a statement about fsck starting points, not a verdict:
$ git -C dated-2099 fsck
dangling commit 279be34d74a15f6b04f2ec46f2113b8dc8291065
[exit status: 0]
```
<!-- /snippet -->

Even with no grace period, the commit stays: garbage collection does not apply the clock rule. And fsck still calls it dangling. "Dangling" is a statement about fsck's starting points, not a verdict.

## COMMON MISTAKES

Five mistakes to watch for.

1. Running a prune because `git fsck` printed `dangling`. Root cause: dangling means no fsck starting point reaches the object; the prune is what destroys recoverable work.
2. Counting on the branch's reflog after deleting the branch. Root cause: a deleted branch loses its own reflog at once; the reflog of HEAD is what still holds the commit.
3. Assuming that unstaging a file removes its content. Root cause: `git add` wrote a blob, and removing the index entry does not remove the object.
4. Trusting a local-path clone as an integrity check. Root cause: it copies or hard-links object files and verifies nothing; `--no-local` forces the transport.
5. Two Git versions disagreeing about a repository. Root cause: the future-dated reflog rule exists only in Git 2.53.0 and later.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: lines.3

Now, out of the lab. An ML platform team keeps a mirror of its training-code repository on the build server and a backup on another host. They run `git fsck` on a schedule against both, and their runbook has two lines: treat `missing` and `error:` lines as an incident, and `dangling` lines as routine.

**[ANIMATION]** walk: columns=operation,recomputes_the_ID_from_the_content? rows=an_ordinary_read,_such_as_git_cat-file:no|git_fsck:yes|a_transfer_through_Git's_transport:yes,_on_the_receiving_side|a_clone_from_a_local_path:no:_it_copies_or_hard-links_the_files|git_clone_--no-local:yes:_it_forces_the_transport marks=1.2:bad,2.2:ok,3.2:ok,4.2:bad,5.2:ok title=Where_Git_checks_its_hashes id=checks

They take the backup through Git's transport, `git clone --mirror` from a URL or `--no-local` from a path, when they want every hash recomputed on the way, and as a file copy when they also need reflogs and hooks.

**[ANIMATION]** ladder: rungs=reachable_from_a_ref_or_the_index:kept|named_only_by_a_reflog_entry:kept_until_the_entry_expires,_90_or_30_days_by_default|unreachable:kept_for_the_grace_period,_two_weeks_by_default|pruned:another_clone_or_a_backup_only title=How_long_an_object_is_kept id=keep2 pace=quick

**[ANIMATION]** say: Off_every_branch_is_not_gone:_the_object_stays_in_every_clone_that_has_it

And the same reachability rule is the precise form of an uncomfortable fact about leaked secrets: removing a commit from every branch leaves it in the object database of every clone that has it.

## PRACTICE EXERCISE

Your turn. Do Exercise 16.7, "Which `git fsck` lines matter", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md). Before you look anything up, sort each line of the output into "information" or "incident" and write down the check you would make for each.

The challenge is Exercise 16.9, "Removed from history, and still there", in the same file.

## INTERVIEW QUESTION

Question 78 of the CTO question bank:

> "`git fsck` says `dangling commit`. Walk me through what you check before you decide whether anything is at risk."

A strong answer defines dangling against the starting points of `git fsck` before it does anything else. It then names the checks in order: what the reflog says, what the clock and the Git version could be doing to the result, what garbage collection would and would not delete and when. It finishes with the action that keeps the commit, and with what must not be run. Avoid answering with a cleanup command.

## RECAP

**[ANIMATION]** step: lost.state-3

Let's land this. That one-line mail was information, and the cleanup was the risk.

You should now be able to say:

- Reachable means arrived at from the index, a ref, a reflog entry or HEAD by following IDs inside objects.
- Unreachable objects are kept for a grace period; dangling ones are the tips of unreachable lines.
- A `dangling` line is information; `missing` and `error:` lines are an incident.
- Ordinary commands do not rehash what they read; `git fsck` and Git's transport do.
- Since Git 2.53.0, `git fsck` skips reflog entries dated in the future; `git gc` does not apply that rule.

## HOMEWORK

Read section 3.8 of [Chapter 3](../../textbook/ch03-git-internals.md). Do Exercise 16.5, "What `git gc` does with unreachable objects", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

Today you learned to read a `dangling` line calmly. Do the exercise before the next video: what makes a repository slow, and the two commands that tidy it. Until then, look at the state first and type second. See you in the next one.

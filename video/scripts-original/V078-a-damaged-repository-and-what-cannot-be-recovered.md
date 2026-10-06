# V078: A damaged repository, and what cannot be recovered

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 12, Recovery
- **Planned minutes.** 20
- **Prerequisites.** V077
- **Textbook sections.** [Chapter 13](../../textbook/ch13-recovery.md), sections 13.11 and 13.12
- **Demo scripts.** `labs/ch13/corruption.sh`

## HOOK

**[ON SCREEN]** `fatal: loose object 3a87d972... is corrupt`

A repository has worked for weeks. `git status` is clean. `git log --oneline` prints the history. Then one day somebody runs `git log --stat`, and Git stops with an error about a data stream and a corrupt object.

The engineer's first move is the one everyone would make: `git fetch`. It exits with status 0 and prints nothing. The error is still there. The second move is to delete the clone and start over, which is fine if everything was pushed, and a loss if it was not.

Your CTO's question is short: "Is the repository damaged, how badly, and can you fix it without losing what is only on that machine?" To answer, you need to know why a fetch does not help, and what does.

## INTRODUCTION

Every recovery so far was about a lost name. The object existed, and you had to find it and point a ref at it. Today is the other kind of problem: an object that is still needed cannot be read. A reachable commit, tree or blob is missing or corrupt.

The causes are outside Git: failing hardware, and tools that copy the repository file by file. The Git FAQ is direct about the second. It says not to use a cloud syncing service to sync any portion of a Git repository, "since this can cause corruption, such as missing objects, changed or added files, broken refs".

In the second half you do something a senior engineer must be able to do: list what cannot be recovered, with the reason for each.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- recognize object corruption from the messages of ordinary commands and of `git fsck`;
- explain why `git fetch` does not replace a corrupt object, and what does;
- repair a repository with one missing object from another clone;
- list what Git cannot recover and give the reason for each.

## CONCEPT

**The symptom.** Commands that need the object fail. Commands that do not need it keep working, which is why damage can go unnoticed for weeks. `git status` and `git log --oneline` read commits and the index. `git log --stat` needs trees and blobs.

**The diagnosis.** `git fsck` reports it with words that differ from the harmless reports of the earlier videos. `dangling` is information. Lines that begin with `missing`, `broken` or `error` describe a repository that needs repair. A file that is present but unreadable counts as missing.

**Why a fetch does not repair it.** A fetch negotiates by commits. Your repository says which commits it has, and the server sends what is not reachable from them. Your refs say you have everything. So the server sends nothing.

**What does repair it.** An object's ID is determined by its content. So the same object from any other repository is the object you lost. There are two routes.

The precise route: ask a healthy clone for a pack that contains the object, and unpack it in the damaged repository. `git pack-objects` reads IDs on standard input and writes a pack. `git unpack-objects` stores the objects of a pack as loose files. One detail decides whether it works: `git unpack-objects` does not write objects that already exist in the repository, and a damaged file with that name exists. Move it out first. Move it, do not delete it: the official how-to on this subject asks you to keep it, since a corrupt object can only be analysed next to its intact twin.

The blunt route: `git fetch --refetch`, which in the manual's words "fetches all objects as a fresh clone would". The release notes of Git 2.36, which added it, describe it as useful "when you cannot trust what you have in the local object store".

**The limit.** `--refetch` can only bring back what the server has. Commits that exist only in your clone and lost an object are repaired from your own working tree if the file is still there, with `git hash-object -w`, and otherwise they are lost from that point of history on.

**A corrupt index** is the mild case. Every command that looks at the working tree fails with "bad signature" and "index file corrupt"; history commands still work. The index is derived data, except for one thing: the record of what you had staged. Move the file away, and `git reset` builds a new index from HEAD without touching the working tree. Your edits are still in the files. What is gone is the distinction between staged and unstaged.

When not to repair in place: when the repair is doubtful. Section 13.17 says to copy the whole repository directory first, while no Git command runs, and work on the copy. And keep repositories out of file-syncing folders; that is the prevention.

## MENTAL MODEL

In the vault, every earlier accident was a misplaced index card. Today a box itself is damaged: the card still points at it, the ledger still mentions it, and when you open it there is garbage inside.

The auditor, `git fsck`, reports that differently. An unmentioned box is "dangling". A mentioned box that cannot be read is "missing".

Why does the other branch office not send a replacement when you visit? Because your visit, the fetch, begins with you reading out your cards. Every card you hold is fine. The other office concludes you need nothing.

The useful property is the one that makes Git what it is: a box number is computed from the contents. A box with the same number from any office holds the same contents, byte for byte. The model breaks only at the door of the vault: a box that no other office ever received cannot be replaced by anyone.

## DIAGRAM

**[DIAGRAM]** First, the difference between the two kinds of `git fsck` line, with the IDs of the transcript.

```text
  refs/heads/main --> 98a37af --> 688c9f2 --> 87fda00
                         |           |
                       tree        tree 3a87d97   <-- file overwritten with garbage
                                                      fsck: "missing tree 3a87d97..."   DAMAGE: a ref reaches it

  (no ref, no reflog) --> some old commit             fsck: "dangling commit ..."       information only
```

**[DIAGRAM]** Then the table of section 13.12 as a two-column slide. Reveal one row at a time and ask the audience for the reason before showing it.

```text
  LOST FOR GOOD                                         WHY GIT NEVER HAD IT, OR NO LONGER HAS IT
  ----------------------------------------------------  -----------------------------------------------------
  edits never staged, overwritten by reset --hard,      no object was ever written for that content
  restore, or checkout -- <path>
  untracked or ignored files removed by git clean,      Git never stored them
  or overwritten by a checkout
  the reflog of a deleted branch                        deleted with the branch; the commits survive, the
                                                        branch's own history of movements does not
  the file name and staging time of a dangling blob     names live in trees and index entries; the entry is gone
  which changes were staged, after a corrupt index      that distinction existed only in the index file
  a commit whose reflog entries expired and whose       nothing names it and the object is deleted
  objects were pruned
  a stash entry after its commits were pruned           the same
  anything in a clone you deleted, never pushed         the only object database that held it is gone
  the value a server branch had before a force push,    bare repositories keep no reflog by default
  when no clone fetched it and the host kept no record
```

Two losses that people expect in this table are not in it. A commit removed by a rebase, an amend or a reset is recoverable for weeks. And a deleted branch is recoverable for as long as you can find its tip.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch13/corruption`. The script damages one object on purpose, in a sandbox. Never do this to a repository you care about.

```bash
git rev-parse 'HEAD~1^{tree}'
chmod u+w .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
printf 'garbage' > .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
```

<!-- snippet: ch13/corruption/01-damage -->
```text
$ git rev-parse 'HEAD~1^{tree}'
3a87d97273a9e9f1038d516277e2fbe853c4fccf
# Simulate a bad disk block: overwrite the file of that tree object with seven bytes.
$ chmod u+w .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
$ printf 'garbage' > .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
```
<!-- /snippet -->

The tree of the second-newest commit, `3a87d97`, is now a file of seven bytes: a simulated bad disk block. Predict which of the next three commands still work.

```bash
git status -sb
git log --oneline -3
git log --oneline --stat -2
```

<!-- snippet: ch13/corruption/02-symptoms -->
```text
$ git status -sb
## main...origin/main
$ git log --oneline -3
98a37af Raise top_k to 10
688c9f2 Add embedding client
87fda00 Add retriever config
$ git log --oneline --stat -2
error: inflate: data stream error (incorrect header check)
error: unable to unpack 3a87d97273a9e9f1038d516277e2fbe853c4fccf header
fatal: loose object 3a87d97273a9e9f1038d516277e2fbe853c4fccf (stored in .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf) is corrupt
[exit status: 128]
```
<!-- /snippet -->

Status and the one-line log work; they read commits and the index. `git log --stat` needs the tree of the second commit and stops. Read the last line: it names the object and the file it is stored in.

```bash
git fsck
```

<!-- snippet: ch13/corruption/03-fsck -->
```text
$ git fsck
error: inflate: data stream error (incorrect header check)
error: unable to unpack header of .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
error: 3a87d97273a9e9f1038d516277e2fbe853c4fccf: object corrupt or missing: .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
[exit status: 3]
```
<!-- /snippet -->

Exit status 3, and the line that matters: "missing tree". That is the diagnosis. Now the reflex. Predict the output of the fetch.

```bash
git fetch origin
git fsck 2>&1 | tail -1
```

<!-- snippet: ch13/corruption/04-fetch-does-not-help -->
```text
$ git fetch origin
[exit status: 0]
$ git fsck 2>&1 | tail -1
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
```
<!-- /snippet -->

Exit status 0, nothing transferred, and the tree is still missing. The negotiation was by commits, and your refs say you have every commit.

Now the precise repair. A colleague's clone, in the directory `asha`, has the object.

**[PAUSE]** Watch this in two attempts. The first one fails, and the reason is the lesson.

```bash
echo 3a87d97273a9e9f1038d516277e2fbe853c4fccf | git -C ../asha pack-objects --stdout -q | git unpack-objects -q
git fsck 2>&1 | tail -1
mv .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf ../damaged-tree.saved
echo 3a87d97273a9e9f1038d516277e2fbe853c4fccf | git -C ../asha pack-objects --stdout -q | git unpack-objects -q
git fsck
git log --oneline --stat -2
```

<!-- snippet: ch13/corruption/05-repair-one-object -->
```text
# Ask a clone that has the object for a pack with that one object, and unpack it here:
$ echo 3a87d97273a9e9f1038d516277e2fbe853c4fccf | git -C ../asha pack-objects --stdout -q | git unpack-objects -q
$ git fsck 2>&1 | tail -1
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
# Nothing changed: a file with that name exists, so the object was not written.
# Move the damaged file out of the object database (keep it as evidence), then repeat.
$ mv .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf ../damaged-tree.saved
$ echo 3a87d97273a9e9f1038d516277e2fbe853c4fccf | git -C ../asha pack-objects --stdout -q | git unpack-objects -q
$ git fsck
[exit status: 0]
$ git log --oneline --stat -2
98a37af Raise top_k to 10
 retriever.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
688c9f2 Add embedding client
 embed.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

After the first attempt nothing changed: a file with that name exists, so the object was not written. The damaged file is moved out of the object database and kept as evidence. The second attempt writes the object, `git fsck` exits with 0, and `git log --stat` works again.

Moving a file out of `.git/objects` by hand is outside Git's own commands. The safety table of the chapter gives the rule for such manual steps: move the file aside instead of deleting it, so that recovery is to move it back.

The blunt repair, for when many objects are affected or you cannot reach a teammate's disk. The script removes two objects, then downloads everything again.

```bash
git fsck
git fetch --refetch origin
git fsck
```

<!-- snippet: ch13/corruption/06-refetch -->
```text
# The blunt repair: lose two objects, then download everything again from the server.
$ rm -f .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf .git/objects/$(git rev-parse HEAD:embed.py | sed 's/../&\//')
$ git fsck
broken link from  commit 688c9f2046a2fb925cc202a4387cf9b7631c5f84
              to    tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
missing blob 5501ef2431a0a61c1dde82cf50840bbfc7072980
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
[exit status: 2]
$ git fetch --refetch origin
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

Before: a "broken link" from commit `688c9f2` to the tree, a missing blob and a missing tree. After `--refetch`: clean. Remember the limit: it brings back only what the server has.

## COMMON MISTAKES

1. **Running `git fetch` and expecting it to heal the repository.** Root cause: a fetch negotiates by commits, and the refs say every commit is present, so nothing is requested.
2. **Unpacking a good copy over the damaged file.** Root cause: `git unpack-objects` does not write an object that already exists in the repository, and the damaged file has that name.
3. **Deleting the clone as the first step.** Root cause: the clone may hold commits, stashes and reflogs that exist nowhere else; a fresh clone has only what the server has.
4. **Treating `dangling` lines as corruption.** Root cause: dangling means unreachable and unreferenced; only `missing`, `broken` and `error` lines describe damage.
5. **Keeping a repository in a file-syncing folder.** Root cause: such tools copy files one by one without Git's locking, which the Git FAQ names as a cause of missing objects and broken refs.

## PRODUCTION EXAMPLE

An ML engineer keeps a training repository inside a cloud-synced folder so that a notebook server and a laptop "share" it. After a crash of the sync client, `git diff` against last week fails with a corrupt loose object. `git status` still works, which is why nobody noticed for days.

The lead's procedure follows the chapter. Copy the whole directory first, with no Git command running, and work on the copy. Run `git fsck` and read only the `missing` and `broken` lines: two blobs and a tree. All three belong to commits that were pushed, so `git fetch --refetch` from the server repairs them, and `git fsck` is clean afterwards. One more commit existed only locally; its files are still in the working tree, so nothing of it was lost. The repository then moves out of the synced folder, and the two machines share work the way Git intends: through pushes and fetches.

The statement to the CTO is exact: what was damaged, what repaired it, what existed only on that machine, and what was changed so that it does not happen again.

## PRACTICE EXERCISE

Do Exercise 12.8, Level 3, "The backup that will not clone", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before you run anything, predict which commands will still succeed on the damaged repository and which will fail, and say for each which objects it has to read. Then decide which of the two repairs applies, and predict the output of `git fsck` after each step.

The challenge is Exercise 12.12, Level 5, "Power loss in the middle of a commit", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q196: "`git fsck` reports `missing tree`. Why does `git fetch` not repair it, and what does?"

Pause and answer aloud.

A strong answer explains the fetch negotiation in one or two sentences: what the client tells the server, and why the server concludes there is nothing to send. It then uses content addressing to justify taking the object from somewhere else, and gives two repairs with the trade-off between them. It mentions the detail that makes the precise repair fail the first time. And it states the limit: what happens to history that exists only in the damaged clone.

## RECAP

You should now be able to say:

- Damage is an object that a ref still reaches and that cannot be read; `git fsck` calls it missing or broken, never dangling.
- A fetch does not repair it, because the negotiation is by commits and my refs say I have them all.
- The same object from any repository is the same bytes; I can unpack it from a healthy clone after moving the damaged file aside, or refetch everything.
- A corrupt index is rebuilt with `git reset`; only the record of what was staged is lost.
- I can list what Git cannot recover, and for each item say that no object was written or that the object and its names are gone.

## HOMEWORK

Read sections 13.11 and 13.12 of [Chapter 13](../../textbook/ch13-recovery.md). Then write the CTO statement that Q199 of the [question bank](../../interview/cto-question-bank.md) asks for.
